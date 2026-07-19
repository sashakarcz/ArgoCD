# AUR-mirror redesign: scan-gated HEAD tracking (drop commit-pinning)

## Goal / decisions (locked)
- **Drop commit-pinning + git lockfile + `pending/` human review.** Packages track AUR HEAD
  and auto-update as long as they pass.
- **Gate = Claude PKGBUILD scan + Trivy + successful build.** Scan runs on HEAD every run.
- **State lives on a Longhorn PV, not git.** No repo-write credential in the cluster.
- **Fail-closed:** scan/Trivy/build failure -> HOLD the package, keep serving the last-good
  published build, and alert.
- **Key isolation preserved:** `ANTHROPIC_API_KEY` only in the scan container, which never runs
  `makepkg`. Keep the container split: **scan -> build -> gpg-init -> signer**.

## Security tradeoff being accepted (explicit)
Removing pin + `pending/` review means the automated scan is the *sole* gate against a
malicious upstream commit; we lose "freeze substantive diffs for a human." Chosen deliberately
for homelab scale. Still far better than blind-HEAD building.

## Files & changes

### 1. `aur-build-all` (python3) -- the core edit
- Add `run_scan_phase()` + `BUILD_PHASE=="scan"` branch in `main()` (dispatch ~L628-635).
- **Move in from `aur-lock`:** `claude_scan`, `_VERDICT_TOOL`, `_SYSTEM_PROMPT`, `fetch_recipe`,
  `git_head`. Collapse the duplicated `recipe_sha256` to ONE definition (scan<->build contract;
  must stay byte-identical).
- Scan phase (key mounted, NO makepkg): read allowlist (bare reader, L424-427); per approved pkg:
  `fetch_recipe` -> `git_head` -> `recipe_sha256` -> `claude_scan` ->
  write `{pkg: {commit, recipe_sha256, verdict: pass|fail, risk, summary, ts}}` to the PV state
  file (JSON). Optional cache: skip the Claude call if state already has this exact commit as pass.
- Build phase: **replace** `load_lock` (L100-105) + call (L430) with `load_verdicts()` PV reader.
  **Replace** the pin block (L476-481) with: `st = verdicts.get(pkg); if not st or st["verdict"]!="pass": _hold("scan", st.summary, st.risk); continue`.
  `resolved_commit = st["commit"]`. Keep `fetch_pkgbuild(..., resolved_commit)` (unchanged body).
  Keep the `recipe_sha256` re-verify (L505-510) against `st["recipe_sha256"]` (race/tamper guard).
  Keep skip-if-up-to-date (L486-489), comparing `built_commits[pkg] == st["commit"]`.
- **Delete:** `classify_diff`, `write_lock`, ConfigMap-wrapped readers, `pending/`, `--commit`
  git path (all in `aur-lock`), and the `/config-lock` lock mount usage.
- **Keep as-is:** `build_fetched`, `trivy_scan` + `TRIVY_FAIL_SEVERITY`, `stage_artifacts`,
  `sign_and_publish`, `prune_repo`, `push_metrics`, `_hold`, python-minor-bump helpers,
  `BUILT_COMMITS` skip machinery.

### 2. `aur-lock` -- retire
- Its scan funcs move into `aur-build-all`. Delete the file (and the `COPY aur-lock` line in
  `Dockerfile`), or reduce to a thin re-export. Remove `aur-lock.configmap.yaml` from git once the
  PV state is live.

### 3. Manifests
- **New PVC** (Longhorn, small e.g. 1Gi) for scan state -> add to `storage.yaml`.
- `builder.yaml` CronJob: prepend a **`scan` initContainer** (image same digest) BEFORE `build`.
  It alone gets `ANTHROPIC_API_KEY` (from `aur-api-key` secret, key `ANTHROPIC_API_KEY`), mounts
  the state PVC + `allowlist` CM; NO repo write, NO GPG. Build/gpg-init/signer unchanged except
  they mount the state PVC read-only and drop the `aur-lock` CM mount.
- `builder-hook.yaml` (PostSync on-add job): same scan-first change so newly-approved packages get
  scanned + built immediately (this is what will pick up tabby).
- `networkpolicy.yaml`: ensure the scan step's egress to `api.anthropic.com` (443) + AUR is allowed.

### 4. Image rebuild (required -- logic is baked in)
`docker build -t registry.starnix.net/library/aur-builder:latest applications/aur-mirror`
`docker push ...` ; `applications/aur-mirror/pin-image.sh` (repins digests) ; commit.

### 5. Alerting (mostly exists)
- `aur_mirror_package_held{reason="scan"|...}` already emitted by `push_metrics`. Verify/extend
  `applications/monitoring/aur-mirror-alerts.yaml` to alert on held packages (Alertmanager ->
  existing Discord route). No new webhook code unless we want an immediate push.

### 6. Docs / cleanup
- Rewrite `PINNING.md` -> `SCANNING.md` (new model). Remove `pending/`. Update `allowlist.yaml`
  header note ("approve = scanned + auto-updated, no pin").

## Resilience: one failed package must NOT break the pipeline (HARD REQUIREMENT)
This is the meshtasticd failure mode. Guarantees:
- **Per-package `try/except` in BOTH the scan loop and the build loop.** Any exception (fetch
  error, weird recipe, makepkg failure, Trivy error, API error) -> `_hold(reason, summary, risk)`
  + `continue`. One package can never abort the batch.
- **Scan phase ALWAYS exits 0.** Per-package scan failures / fetch errors / Anthropic outage ->
  `fail` verdict (fail-closed: that package holds), but the phase returns 0 so it can NEVER block
  the downstream build container. Only fatal infra (unreadable allowlist, unwritable PV) is non-zero.
- **Build phase exits 0 on per-package failures** (already true, L562) -- preserve.
- **CHANGE: sign phase / job exits 0 when packages are merely HELD.** Today `run_sign_phase`
  returns 1 if `failed` is non-empty (L622) -> job `Failed` -> `OnFailure` retry churn (this is
  what made the meshtasticd run perpetually red). New: held/failed packages are surfaced via
  `aur_mirror_package_held` + alert; the JOB stays green. Reserve non-zero exit for genuine infra
  failure (registry/PV/GPG unavailable). Alert on `aur_mirror_package_held > 0`, not on job failure.
- **Per-package build timeout** (`subprocess` timeout around `build_fetched`/`makepkg`) so one
  hanging build can't consume `activeDeadlineSeconds` and kill the whole batch -> timeout = hold.
- Keep `concurrencyPolicy: Forbid` + the build `flock` (no concurrent runs).

Net: every run publishes everything that passed, stuck packages keep their last-good build and
raise an alert, and the job is green as long as the pipeline itself ran.

## Bootstrap
- No seed needed: first `scan` run populates the PV state for all approved packages (~60 haiku
  calls, cheap). tabby + anything added since 2026-07-06 get scanned on that first run.

## Rollout order
1. Edit `aur-build-all` (scan phase + verdict gate); retire `aur-lock`.
2. Rebuild + push image; `pin-image.sh`.
3. Add PVC; edit `builder.yaml` + `builder-hook.yaml` + `networkpolicy.yaml`; drop git-lock mount.
4. Update alerts + docs.
5. Commit + push -> ArgoCD syncs -> on-add/nightly scan run populates state -> build -> publish.
6. Verify `tabby-bin` lands in `aur-mirror.db`.

## Open / verify during impl
- Longhorn PVC access mode: scan + build share one pod (initContainers) so RWO is fine.
- Confirm `aur-api-key` secret key name is exactly `ANTHROPIC_API_KEY` (it is).
- Confirm networkpolicy currently blocks/allows Anthropic egress.
