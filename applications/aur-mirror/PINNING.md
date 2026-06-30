# Commit pinning for the AUR mirror

The June 2026 AUR campaign compromised 1600+ packages by pushing malicious
commits to recipes the world was building straight from HEAD. This mirror no
longer builds HEAD. It builds only commits that have been pinned and reviewed,
using a lockfile model so the steady-state maintenance cost stays near zero.

## The pieces

| File | Role | Edited by |
|------|------|-----------|
| `allowlist.yaml` | what you *want* mirrored (names + `approved`) | you (or `pac mirror`) |
| `aur-lock.configmap.yaml` | the lock: `name -> {commit, recipe_sha256}` | `aur-lock` (machine) |
| `pending/<pkg>.diff` | a substantive upstream change held for review | `aur-lock` (machine) |
| `aur-build-all` | build phase: builds ONLY pinned commits | -- |
| `aur-lock` | review phase: pins, classifies, auto-bumps | runs in CI |

## How a package flows

1. You approve a package in `allowlist.yaml` (a PR, same as before).
2. `aur-lock` (in CI) fetches its AUR recipe and, the first time it sees it,
   runs the Claude recipe scan once (trust-on-first-use) and pins the current
   commit + recipe hash into the lock.
3. The build pod checks out exactly that commit, re-verifies the recipe hash,
   builds, Trivy-scans, and the signer re-verifies each artifact's SHA256
   before signing. A package with no lock entry is **held, never built**.

## Why it isn't "review hundreds of PKGBUILDs"

`aur-lock` runs nightly (in CI) and, for each approved package:

- **HEAD == locked commit** -> nothing (the common case).
- **version-only diff** (only `pkgver`/`pkgrel`/`epoch`/`*sums` changed) ->
  auto-bumps the lock to HEAD. No human action.
- **substantive diff** (touches `build()`/`package()`/`prepare()`/`pkgver()`,
  `.install` hooks, `source=()` URLs, or adds/removes files) -> freezes the
  lock and writes `pending/<pkg>.diff`. You review **only that diff**.

A source-URL change is treated as substantive on purpose: a redirected download
host is exactly how an attacker would stage a payload, so it always gets a look.

## Reviewing a held change

1. Read `pending/<pkg>.diff`.
2. **Approve:** update that package's entry in `aur-lock.configmap.yaml` to the
   `proposed: commit=... recipe_sha256=...` line at the top of the diff, delete
   the pending file, commit. The next build picks up the new commit.
3. **Reject:** leave the lock as-is (delete the pending file). The mirror keeps
   building the old, known-good commit.

## Running aur-lock (CI, not in-cluster)

`aur-lock` needs git push + `ANTHROPIC_API_KEY`; it deliberately does **not**
run in the cluster, so no GitHub token lives next to the build. Run it from
Semaphore (or any CI / a maintainer laptop) using the builder image:

```sh
docker run --rm \
  -e ANTHROPIC_API_KEY \
  -v "$PWD/applications/aur-mirror:/work" -w /work \
  registry.starnix.net/library/aur-builder@sha256:c88d9b7415ab82c7a19b179f716a92a9a82583916302e9096e28078ac550825c \
  aur-lock --commit
```

`--commit` git-commits the lock + pending changes; push the branch and open the
PR as usual. `--dry-run` writes nothing; `--only <pkg>` scopes to one package.
A non-zero exit means something needs a human (held diffs or fetch errors).

## First-time rollout (one-time)

1. Merge this change. The lock ships empty, so the build phase will **hold
   every package** until it's bootstrapped -- this is fail-safe (no unreviewed
   builds), but the mirror won't update until step 2.
2. Run `aur-lock --commit` once with `ANTHROPIC_API_KEY` set. It scans + pins
   all approved packages at their current HEAD and commits the populated lock
   (plus any `pending/` for recipes the scan flags).
3. Review anything in `pending/`, merge. Builds resume against pinned commits.

## Builder image digest pin

The build manifests, the `pac` default, and the `aur-lock` invocation above are
pinned to an immutable `@sha256:` digest (not `:latest`), so push access to
Harbor cannot swap the signer's code. This pin must be refreshed whenever you
rebuild the image -- the image bakes in `aur-build-all` + `aur-lock`, so a
rebuild is required for any change to them to take effect:

```sh
docker build -t registry.starnix.net/library/aur-builder:latest applications/aur-mirror
docker push  registry.starnix.net/library/aur-builder:latest
applications/aur-mirror/pin-image.sh    # resolves HEAD digest, rewrites all refs
git add -A && git commit -m "chore(aur-mirror): repin builder image"
```

> The digest currently committed is the image as it existed **before** these
> pipeline changes. Rebuild + `pin-image.sh` once so the pods actually run the
> new `aur-build-all` (commit-pin enforcement) and ship `aur-lock`.

## Still on you (outside these repos)

- **Client `SigLevel`.** Ensure `selene`'s `/etc/pacman.conf` has the
  `[aur-mirror]` repo at `SigLevel = Required DatabaseRequired`. `pac` now warns
  at install/update time if it isn't, but the enforcement is pacman's.
- **authentik `groups` claim.** The ArgoCD RBAC change scopes admin to the
  `admins` group; the authentik argocd provider must emit a `groups` scope/claim
  for that to take effect (otherwise everyone is read-only).
