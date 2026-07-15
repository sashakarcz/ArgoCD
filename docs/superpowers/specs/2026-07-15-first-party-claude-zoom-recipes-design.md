# Design: first-party, self-verifying PKGBUILDs for claude-code and zoom

Date: 2026-07-15
Status: approved (pending spec review)

## Goal

Bring `claude-code` and `zoom` -- two tools sasha runs daily -- under first-party
supply-chain control on the AUR mirror, the same way `wazuh-agent` already is.
Neither is currently held by the scan; both AUR recipes are clean. The point is
**control + cryptographic verification**, so a hijacked AUR maintainer commit can
never touch either tool: the mirror builds *our* reviewed recipe, and each build
verifies the downloaded artifact against the **vendor's own** integrity data.

Non-goal: manual version pinning. Both recipes **auto-track the latest upstream
release** -- the safety comes from verification, not from gatekeeping versions.

## Architecture

- Two first-party git repos: **`github.com/usenix17/claude-code`** and
  **`github.com/usenix17/zoom`**, each holding a `PKGBUILD` (+ any helper files).
- `allowlist.yaml` points each package's entry at its repo via `source:` (same
  mechanism as `wazuh-agent`). `pkgname` stays `claude-code` / `zoom`, so
  selene's installs are unchanged.
- Each recipe **auto-tracks latest** via a `pkgver()` that resolves the current
  version from the vendor, and **verifies** the artifact at build time.
- A new mirror flag, **`track: latest`**, on those two allowlist entries makes
  `aur-build-all` skip its "already built this commit" check and rebuild them
  every run (their recipe commit is static, but upstream moves). Builds are cheap
  (binary installs, no compile).

## claude-code recipe

- **Version:** `pkgver()` curls `https://downloads.claude.ai/claude-code-releases/stable`
  (returns e.g. `2.1.202`) and emits it. No hardcoded version.
- **Integrity:** fetch `https://downloads.claude.ai/claude-code-releases/<ver>/manifest.json`,
  extract the official `platforms["linux-x64"].checksum` (sha256), download the
  binary from `.../<ver>/linux-x64/claude`, and verify it against that checksum.
  The checksum comes from Anthropic's own manifest, not a maintainer-asserted
  value -- a recipe edit can't substitute a bad hash. (Confirmed: the manifest's
  linux-x64 checksum matches what the AUR recipe carries.) Same for `linux-arm64`.
- **Install:** binary -> `/opt/claude-code/bin/claude`; a `/usr/bin/claude`
  wrapper exporting `DISABLE_UPDATES=1` and `DISABLE_INSTALLATION_CHECKS=1`
  (no self-update path). License doc installed.
- Verification failure (checksum mismatch, manifest unreachable) -> build fails
  -> package held, last-good retained.

## zoom recipe

- **Version:** `pkgver()` does `curl -sI https://zoom.us/client/latest/zoom_x86_64.rpm`
  and parses the version out of the `Location:` redirect
  (`.../prod/7.1.0.3715/zoom_x86_64.rpm`). No hardcoded version.
- **Integrity (upgrade over AUR):** the AUR recipe uses the *unsigned*
  `.pkg.tar.xz`. We switch to the **GPG-signed `zoom_x86_64.rpm`**. Zoom's signing
  public key is committed in the repo and **pinned by fingerprint**; the build
  imports it, verifies the fingerprint matches the pin, and GPG-verifies the rpm
  signature (fail closed). A recipe edit can't swap the key without changing the
  pinned fingerprint (which is reviewed).
- **Install:** extract the rpm payload with `bsdtar` and package `opt/usr` as the
  AUR recipe does.
- Verification failure (bad/absent signature, key fingerprint mismatch) -> build
  fails -> package held.

## Implementation note: dynamic version + makepkg ordering

makepkg fetches `source=()` **before** `pkgver()` runs, so a URL that depends on
the resolved version cannot live in `source=()` (and `sha256sums` can't be
static). For both recipes the **versioned artifact is fetched and verified inside
the recipe body** (a `prepare()`/`build()` step: resolve version -> download ->
verify), not via `source=()`/`sha256sums`. `source=()` holds only static files
(license, the pinned Zoom key). This is the standard pattern for auto-tracking
`-bin` packages and keeps verification explicit and fail-closed.

## Mirror change: `track: latest`

- `allowlist.yaml` entries gain an optional `track: latest`.
- `aur-build-all` build phase: when a package has `track: latest`, do **not**
  apply the `built_commits[pkg] == scanned_commit` skip -- always rebuild. The
  scan phase is unchanged (recipe commit is static -> cached pass verdict; only
  the fetched artifact changes, and that's covered by the recipe's own manifest/
  GPG verification + the existing Trivy scan of the built artifact).
- This is the only code change; requires an image rebuild + `pin-image.sh` repin
  (builder.yaml, builder-hook.yaml, pac config.go), same as any `aur-build-all`
  change.

## Allowlist integration

`claude-code` and `zoom` entries change from bare AUR to:
```yaml
- name: claude-code
  approved: true
  note: explicit -- first-party recipe, auto-tracks stable, verifies Anthropic manifest checksum
  source: https://github.com/usenix17/claude-code.git
  track: latest
- name: zoom
  approved: true
  note: explicit -- first-party recipe, auto-tracks latest, GPG-verifies Zoom's signed rpm
  source: https://github.com/usenix17/zoom.git
  track: latest
```

## Error handling / fail-closed

Every verification path fails the build (not silently continues), so an
unverifiable artifact -> the package is **held** with its last-good build
retained + `AURPackageHeld` alert -- consistent with the mirror's model. Network
flakiness on `stable`/`latest`/`manifest` -> build error -> held (transient,
clears next run).

## Testing

- Build each recipe locally in the builder image
  (`docker run ... aur-builder bash -c 'cd /tmp && git clone <repo> && cd <pkg> && makepkg -s'`,
  `sudo pacman -Syu` first). Confirm it resolves the current version and installs.
- **Negative tests:** tamper the expected checksum (claude-code) and the pinned
  key fingerprint (zoom) and confirm the build *fails closed*.
- Deploy: push both repos, update allowlist + the `track: latest` mirror change,
  rebuild image, let the mirror build + publish. Confirm `claude-code`/`zoom`
  land signed in `aur-mirror.db` under the same names and selene upgrades cleanly.

## Success criteria

1. Both recipes live in `usenix17/{claude-code,zoom}`, build clean, pass the scan.
2. Each build verifies vendor integrity (Anthropic manifest checksum / Zoom GPG
   signature) and fails closed on tampering.
3. New upstream releases are picked up automatically (via `track: latest`) with no
   manual bump.
4. Published under the existing `pkgname`s; selene keeps using `[aur-mirror]`.
