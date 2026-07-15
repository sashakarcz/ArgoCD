# Recipe scanning for the AUR mirror

The June 2026 AUR campaign compromised 1600+ packages by pushing malicious
commits to recipes the world was building straight from HEAD. This mirror does
not build a recipe until Claude has scanned its PKGBUILD (and everything else
the maintainer committed) for supply-chain threats, and the built artifact has
passed a Trivy scan. Packages track AUR HEAD and auto-update as long as they
keep passing -- there is no lockfile to hand-maintain and no per-bump review
queue.

## The pieces

| File / object | Role | Written by |
|---|---|---|
| `allowlist.yaml` | what you *want* mirrored (names + `approved`) | you (or `pac mirror`) |
| `verdicts.json` (state PV) | scan verdicts: `name -> {commit, recipe_sha256, verdict, risk, summary}` | the scan phase (machine) |
| `aur-build-all` | all three phases: scan, build, sign | -- |

State lives on the `aur-mirror-state-pvc` (NFS PV), **not** git -- so nothing in
this pipeline needs a repo-write credential in the cluster.

## How a package flows (three phases, three containers)

1. **scan** -- resolves each approved package's AUR HEAD, runs the Claude
   PKGBUILD scan, and writes a `pass`/`fail` verdict + the resolved commit +
   recipe hash to `verdicts.json`. This is the **only** container with
   `ANTHROPIC_API_KEY`, and it **never runs makepkg**, so the key is never next
   to untrusted build code. It always exits 0 (a scan failure is a fail-closed
   `fail` verdict, never a blocker).
2. **build** -- checks out exactly the scanned commit, re-verifies the recipe
   hash against what the scan saw, `makepkg`, then Trivy-scans the artifact. No
   GPG key, no API key here. A package with no `pass` verdict is **held**.
3. **sign** -- re-verifies each staged artifact's SHA256, GPG-signs, `repo-add`s,
   prunes de-allowlisted packages, pushes metrics.

## Auto-update, and what "held" means

- Because the scan phase resolves a **moving HEAD** every run, a package
  auto-updates the moment upstream advances *and* the new commit passes the
  scan. No pin to bump, no diff to review.
- **Held = fail-closed.** If the scan flags the recipe (HIGH/CRITICAL), Trivy
  finds a CVE/secret, or the build fails, the package is held: it keeps serving
  its **last-good published build** and raises the `AURPackageHeld` alert. It is
  **never** an unreviewed build, and it **never fails the job** -- a single bad
  package cannot wedge the mirror or block the other packages.

## Security posture (read before you rely on it)

The Claude scan + Trivy are the *sole* gate. Unlike the old commit-pin model,
there is no human review of substantive upstream diffs -- a malicious commit
that the scan fails to catch would auto-publish. This is a deliberate tradeoff
for homelab scale (far better than blind-HEAD building, less friction than
per-bump review). If you ever want a specific high-risk package frozen, the
honest move is to `approved: false` it and vendor a reviewed copy via a
first-party `source:` git URL (see `wazuh-agent`).

## Builder image digest pin

The build manifests and the `pac` default are pinned to an immutable
`@sha256:` digest (not `:latest`), so push access to Harbor cannot swap the
signer's code. Refresh it whenever you change `aur-build-all` (the image bakes
it in, so a rebuild is required for any change to take effect):

```sh
docker build -t registry.starnix.net/library/aur-builder:latest applications/aur-mirror
docker push  registry.starnix.net/library/aur-builder:latest
applications/aur-mirror/pin-image.sh    # resolves HEAD digest, rewrites all image refs
git add -A && git commit -m "chore(aur-mirror): repin builder image"
```

## Still on you (outside these repos)

- **Client `SigLevel`.** Ensure `selene`'s `/etc/pacman.conf` has the
  `[aur-mirror]` repo at `SigLevel = Required DatabaseRequired`.
- **State dir on mimir.** `mkdir -p /mnt/Store/aur-mirror/state` before the
  first run (backs `aur-mirror-state-pvc`).
