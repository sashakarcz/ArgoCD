# First-party claude-code + zoom recipes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `claude-code` and `zoom` under first-party supply-chain control on the AUR mirror — recipes we own that auto-track latest upstream and cryptographically verify each artifact against the vendor's own integrity data.

**Architecture:** Two first-party git repos (`usenix17/claude-code`, `usenix17/zoom`) referenced from `allowlist.yaml` via `source:`, same `pkgname`s. `claude-code` verifies the binary against Anthropic's `manifest.json` sha256; `zoom` GPG-verifies the official signed `.rpm` against a fingerprint-pinned key. A new `track: latest` allowlist flag makes `aur-build-all` always rebuild them (their recipe commit is static, but upstream moves).

**Tech Stack:** bash PKGBUILDs (makepkg), python3 (`aur-build-all`), `rpm-tools`/`gpg` for verification, the `registry.starnix.net/library/aur-builder` image for test builds, ArgoCD/k8s for deploy.

---

## File Structure

- `~/git/aur-claude-code/PKGBUILD` — new claude-code recipe (pushed to `usenix17/claude-code`)
- `~/git/aur-zoom/PKGBUILD` + `~/git/aur-zoom/zoom-pubkey.asc` — new zoom recipe + pinned key (pushed to `usenix17/zoom`)
- `~/ArgoCD/applications/aur-mirror/aur-build-all` — add `should_skip_build()` honoring `track: latest`
- `~/ArgoCD/applications/aur-mirror/tests/test_should_skip_build.py` — new unit test
- `~/ArgoCD/applications/aur-mirror/allowlist.yaml` — point `claude-code`/`zoom` at the repos + `track: latest`
- `~/ArgoCD/applications/aur-mirror/{builder,builder-hook}.yaml`, `~/pac/internal/config/config.go` — repinned image digest

Use `IMG=registry.starnix.net/library/aur-builder:latest` in shell steps below.

---

## Task 1: claude-code first-party recipe

**Files:**
- Create: `~/git/aur-claude-code/PKGBUILD`

- [ ] **Step 1: Write the PKGBUILD**

```bash
mkdir -p ~/git/aur-claude-code && cat > ~/git/aur-claude-code/PKGBUILD <<'PKGB'
# First-party recipe for the starnix aur-mirror. Auto-tracks the claude-code
# `stable` channel and verifies the binary against Anthropic's official
# manifest.json checksum -- never a maintainer-asserted sum.
pkgname=claude-code
pkgver=0
pkgrel=1
pkgdesc="An agentic coding tool that lives in your terminal (first-party, manifest-verified)"
arch=('x86_64' 'aarch64')
url="https://github.com/anthropics/claude-code"
license=('LicenseRef-claude-code')
depends=('bash')
optdepends=('git: git integration' 'ripgrep: faster search' 'github-cli: GitHub' 'tmux: split panes')
options=('!strip')
_base="https://downloads.claude.ai/claude-code-releases"

pkgver() {
  curl -fsSL "${_base}/stable" | tr -d '[:space:]'
}

build() {
  local ver slug want
  ver="$(curl -fsSL "${_base}/stable" | tr -d '[:space:]')"
  case "$CARCH" in
    x86_64)  slug="linux-x64" ;;
    aarch64) slug="linux-arm64" ;;
    *) echo "unsupported CARCH $CARCH" >&2; return 1 ;;
  esac
  # Authoritative checksum from Anthropic's own manifest.
  want="$(curl -fsSL "${_base}/${ver}/manifest.json" \
    | python -c "import sys,json;print(json.load(sys.stdin)['platforms']['${slug}']['checksum'])")"
  [ -n "${want}" ] || { echo "no checksum in manifest for ${slug}" >&2; return 1; }
  curl -fsSL -o claude "${_base}/${ver}/${slug}/claude"
  echo "${want}  claude" | sha256sum -c -    # fails the build (errexit) on mismatch
  curl -fsSL -o LICENSE "https://code.claude.com/docs/en/legal-and-compliance.md"
}

package() {
  install -Dm755 "${srcdir}/claude" "${pkgdir}/opt/claude-code/bin/claude"
  install -dm755 "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/claude" <<'WRAP'
#!/bin/sh
export DISABLE_UPDATES=1
export DISABLE_INSTALLATION_CHECKS=1
exec /opt/claude-code/bin/claude "$@"
WRAP
  chmod 755 "${pkgdir}/usr/bin/claude"
  install -Dm644 "${srcdir}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
PKGB
```

- [ ] **Step 2: Positive build test in the builder image**

Run:
```bash
docker run --rm -v ~/git/aur-claude-code:/pkg:ro $IMG bash -c '
  sudo pacman -Syu --noconfirm >/dev/null
  cp -r /pkg /tmp/b && cd /tmp/b && makepkg -sf --noconfirm --noprogressbar &&
  bsdtar tf claude-code-*.pkg.tar.zst | grep -E "opt/claude-code/bin/claude|usr/bin/claude"'
```
Expected: builds; the two paths listed. Note the resolved `pkgver` in the output filename matches the `stable` pointer (`curl -fsSL https://downloads.claude.ai/claude-code-releases/stable`).

- [ ] **Step 3: Negative test — checksum mismatch fails closed**

Run (inject a wrong expected checksum, confirm build aborts):
```bash
docker run --rm -v ~/git/aur-claude-code:/pkg:ro $IMG bash -c '
  sudo pacman -Syu --noconfirm >/dev/null
  cp -r /pkg /tmp/b && cd /tmp/b
  sed -i "s/\${want}  claude/deadbeef  claude/" PKGBUILD   # force a checksum mismatch
  makepkg -sf --noconfirm 2>&1 | tail -3
  echo "exit=$?"'
```
Expected: `sha256sum -c` reports FAILED and makepkg exits non-zero (the package is NOT built). Confirms fail-closed.

- [ ] **Step 4: Generate .SRCINFO, init repo, push**

```bash
cd ~/git/aur-claude-code
docker run --rm -v "$PWD":/pkg $IMG bash -c 'cd /pkg && makepkg --printsrcinfo' > .SRCINFO
git init -q && git add -A && git commit -q -m "claude-code: first-party manifest-verified recipe"
gh repo create usenix17/claude-code --private --source=. --push
```
Expected: repo exists at `github.com/usenix17/claude-code`, HEAD pushed.

---

## Task 2: zoom first-party recipe

**Files:**
- Create: `~/git/aur-zoom/PKGBUILD`, `~/git/aur-zoom/zoom-pubkey.asc`

- [ ] **Step 1: Fetch + pin Zoom's signing key**

```bash
mkdir -p ~/git/aur-zoom && cd ~/git/aur-zoom
curl -fsSL "https://zoom.us/linux/download/pubkey" -o zoom-pubkey.asc
# Confirm the fingerprint is the pinned one BEFORE trusting it:
gpg --show-keys --with-colons zoom-pubkey.asc | awk -F: '/^fpr:/{print $10; exit}'
# MUST print: 84C365D6CC9A4886CA926BCC4F2197399706AC24
KEYSHA=$(sha256sum zoom-pubkey.asc | cut -d' ' -f1); echo "$KEYSHA"
```
Expected: fingerprint equals `84C365D6CC9A4886CA926BCC4F2197399706AC24`. If it differs, STOP — the upstream key rotated; re-verify against Zoom before continuing. Keep `$KEYSHA` for Step 2.

- [ ] **Step 2: Write the PKGBUILD** (substitute `$KEYSHA` into `sha256sums`)

```bash
cat > ~/git/aur-zoom/PKGBUILD <<PKGB
# First-party recipe for the starnix aur-mirror. Auto-tracks Zoom's latest
# release and GPG-verifies the OFFICIAL SIGNED rpm against Zoom's
# fingerprint-pinned signing key (the AUR recipe used the UNSIGNED tarball).
pkgname=zoom
pkgver=0
pkgrel=1
pkgdesc="Zoom video conferencing (first-party, GPG-verified official rpm)"
arch=('x86_64')
url="https://zoom.us/"
license=('LicenseRef-zoom')
depends=('fontconfig' 'glib2' 'libpulse' 'libsm' 'ttf-font' 'libx11' 'libxtst' 'libxcb'
  'libxcomposite' 'libxfixes' 'libxi' 'libxcursor' 'libxkbcommon-x11' 'libxrandr'
  'libxrender' 'libxshmfence' 'libxslt' 'mesa' 'nss' 'xcb-util-image'
  'xcb-util-keysyms' 'xcb-util-cursor' 'dbus' 'libdrm' 'gtk3' 'xcb-util-wm')
makedepends=('rpm-tools')
optdepends=('pulseaudio-alsa: audio via PulseAudio' 'ibus: remote control'
  'noto-fonts-emoji: emojis')
options=('!strip')
# Zoom's signing key fingerprint (pin). A recipe edit cannot swap the key
# without changing this reviewed value. From https://zoom.us/linux/download/pubkey.
_zoom_fpr="84C365D6CC9A4886CA926BCC4F2197399706AC24"
source=('zoom-pubkey.asc')
sha256sums=('${KEYSHA}')

pkgver() {
  curl -fsSI "https://zoom.us/client/latest/zoom_x86_64.rpm" \\
    | tr -d '\\r' | sed -nE 's#^[Ll]ocation:.*/prod/([0-9.]+)/zoom_x86_64\\.rpm.*#\\1#p' \\
    | head -n1 | tr -d '[:space:]'
}

build() {
  local ver rpmdb
  ver="\$(pkgver)"
  [ -n "\$ver" ] || { echo "could not resolve Zoom version" >&2; return 1; }

  # 1. The committed key must be the pinned fingerprint (show-only, no import).
  gpg --with-colons --import-options show-only --import "\${srcdir}/zoom-pubkey.asc" \\
    | awk -F: '/^fpr:/{print \$10}' | grep -qx "\${_zoom_fpr}" \\
    || { echo "committed key fingerprint != pinned \${_zoom_fpr}" >&2; return 1; }

  # 2. Import the pinned key into an isolated rpm keyring.
  rpmdb="\${srcdir}/rpmdb"; mkdir -p "\$rpmdb"
  rpmkeys --dbpath "\$rpmdb" --import "\${srcdir}/zoom-pubkey.asc"

  # 3. Download the official signed rpm and verify its GPG signature (fail closed).
  curl -fsSL -o zoom.rpm "https://cdn.zoom.us/prod/\${ver}/zoom_x86_64.rpm"
  rpmkeys --dbpath "\$rpmdb" -Kv zoom.rpm | grep -qiE 'Signature, key ID.*: OK' \\
    || { echo "rpm GPG signature verification FAILED" >&2; return 1; }

  # 4. Extract the payload (bsdtar reads rpm directly).
  mkdir -p extracted && bsdtar -C extracted -xf zoom.rpm
}

package() {
  cp -dpr --no-preserve=ownership "\${srcdir}/extracted/opt" "\${srcdir}/extracted/usr" "\${pkgdir}/"
}
PKGB
```

- [ ] **Step 3: Positive build test in the builder image**

Run:
```bash
docker run --rm -v ~/git/aur-zoom:/pkg:ro $IMG bash -c '
  sudo pacman -Syu --noconfirm >/dev/null
  cp -r /pkg /tmp/z && cd /tmp/z && makepkg -sf --noconfirm --noprogressbar 2>&1 | tail -8 &&
  bsdtar tf zoom-*.pkg.tar.zst | grep -E "^opt/zoom|^usr/bin/zoom"'
```
Expected: the `Signature, key ID ...: OK` line prints, makepkg succeeds, and `opt/zoom` + `usr/bin/zoom` appear. (First run downloads ~300 MB rpm; be patient.)

- [ ] **Step 4: Negative test — wrong pinned fingerprint fails closed**

Run:
```bash
docker run --rm -v ~/git/aur-zoom:/pkg:ro $IMG bash -c '
  sudo pacman -Syu --noconfirm >/dev/null
  cp -r /pkg /tmp/z && cd /tmp/z
  sed -i "s/_zoom_fpr=\"[0-9A-F]*\"/_zoom_fpr=\"DEADBEEF\"/" PKGBUILD
  makepkg -sf --noconfirm 2>&1 | tail -3; echo "exit=$?"'
```
Expected: "committed key fingerprint != pinned DEADBEEF" and non-zero exit — no package built.

- [ ] **Step 5: .SRCINFO, init repo, push**

```bash
cd ~/git/aur-zoom
docker run --rm -v "$PWD":/pkg $IMG bash -c 'cd /pkg && makepkg --printsrcinfo' > .SRCINFO
git init -q && git add -A && git commit -q -m "zoom: first-party GPG-verified rpm recipe"
gh repo create usenix17/zoom --private --source=. --push
```

---

## Task 3: mirror `track: latest` flag (TDD)

**Files:**
- Modify: `~/ArgoCD/applications/aur-mirror/aur-build-all` (extract skip decision + honor `track`)
- Test: `~/ArgoCD/applications/aur-mirror/tests/test_should_skip_build.py`

- [ ] **Step 1: Write the failing test**

```bash
mkdir -p ~/ArgoCD/applications/aur-mirror/tests
cat > ~/ArgoCD/applications/aur-mirror/tests/test_should_skip_build.py <<'PY'
import os, importlib.util, pathlib
os.environ.setdefault("REPO_DIR", "/tmp")
_p = pathlib.Path(__file__).resolve().parent.parent / "aur-build-all"
_spec = importlib.util.spec_from_file_location("aurbuildall", _p)
m = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(m)

def test_track_latest_never_skips():
    assert m.should_skip_build({"name": "x", "track": "latest"}, "abc", "abc", False) is False

def test_skips_when_commit_matches_and_not_tracking():
    assert m.should_skip_build({"name": "x"}, "abc", "abc", False) is True

def test_rebuilds_on_new_commit():
    assert m.should_skip_build({"name": "x"}, "old", "new", False) is False

def test_py_stale_forces_rebuild():
    assert m.should_skip_build({"name": "x"}, "abc", "abc", True) is False
PY
```

- [ ] **Step 2: Run the test, verify it fails**

Run: `cd ~/ArgoCD/applications/aur-mirror && python -m pytest tests/test_should_skip_build.py -q`
Expected: FAIL — `AttributeError: module ... has no attribute 'should_skip_build'`.

- [ ] **Step 3: Add `should_skip_build()` and use it**

In `aur-build-all`, add this function just above `def run_build_phase()`:
```python
def should_skip_build(entry: dict, built_commit, scanned_commit: str, py_stale: bool) -> bool:
    """Whether to skip rebuilding a package this run.

    A `track: latest` package (recipe commit is static but upstream moves) is
    NEVER skipped -- it rebuilds every run so its pkgver() picks up new releases.
    Otherwise skip only when the scanned commit is already built and no python
    bump forces a rebuild.
    """
    if entry.get("track") == "latest":
        return False
    return built_commit == scanned_commit and not py_stale
```
Then in `run_build_phase`, replace the skip block:
```python
            if built_commits.get(pkg) == scanned_commit and not py_stale:
                log.info("Up to date (commit %s), skipping.", scanned_commit[:12])
                skipped += 1
                continue
```
with:
```python
            if should_skip_build(entry, built_commits.get(pkg), scanned_commit, py_stale):
                log.info("Up to date (commit %s), skipping.", scanned_commit[:12])
                skipped += 1
                continue
```

- [ ] **Step 4: Run the test, verify it passes**

Run: `cd ~/ArgoCD/applications/aur-mirror && python -m pytest tests/test_should_skip_build.py -q`
Expected: 4 passed. Also `python -m py_compile aur-build-all` → no output.

- [ ] **Step 5: Commit**

```bash
cd ~/ArgoCD && git add applications/aur-mirror/aur-build-all applications/aur-mirror/tests/test_should_skip_build.py
git commit -q -m "feat(aur-mirror): track: latest flag forces rebuild for auto-tracking recipes"
```

---

## Task 4: allowlist + image repin + deploy

**Files:**
- Modify: `~/ArgoCD/applications/aur-mirror/allowlist.yaml`
- Modify (via pin-image.sh): `builder.yaml`, `builder-hook.yaml`, `~/pac/internal/config/config.go`

- [ ] **Step 1: Point the allowlist entries at the repos + track**

In `allowlist.yaml`, replace the `claude-code` and `zoom` entries with:
```yaml
  - name: claude-code
    approved: true
    note: explicit -- first-party recipe; auto-tracks stable, verifies Anthropic manifest checksum
    source: https://github.com/usenix17/claude-code.git
    track: latest
  - name: zoom
    approved: true
    note: explicit -- first-party recipe; auto-tracks latest, GPG-verifies Zoom's signed rpm
    source: https://github.com/usenix17/zoom.git
    track: latest
```

- [ ] **Step 2: Rebuild + push + repin the builder image** (aur-build-all changed)

```bash
cd ~/ArgoCD
docker build -t $IMG applications/aur-mirror
docker push $IMG
applications/aur-mirror/pin-image.sh
```
Expected: pin-image.sh reports the new `@sha256:` in builder.yaml, builder-hook.yaml, and pac config.go.

- [ ] **Step 3: Commit both repos**

```bash
cd ~/ArgoCD && git add applications/aur-mirror/allowlist.yaml applications/aur-mirror/builder.yaml applications/aur-mirror/builder-hook.yaml
git commit -q -m "feat(aur-mirror): first-party claude-code + zoom (auto-track, verified); repin image"
git -C ~/pac add internal/config/config.go && git -C ~/pac commit -q -m "chore: repin default aur-builder image digest"
```

- [ ] **Step 4: Push (pac first, then ArgoCD)**

```bash
git -C ~/pac push origin master
git -C ~/ArgoCD push origin main
```

---

## Task 5: verify the rollout

- [ ] **Step 1: Wait for the on-add hook to build + publish**

Run (poll until both appear, signed):
```bash
for i in $(seq 1 30); do
  db=$(curl -fsSL https://aur.starnix.net/aur-mirror.db 2>/dev/null | tar tzf - 2>/dev/null)
  cc=$(echo "$db" | grep -c '^claude-code/'); zm=$(echo "$db" | grep -c '^zoom/')
  echo "claude-code=$cc zoom=$zm"; [ "$cc" = 1 ] && [ "$zm" = 1 ] && break; sleep 20
done
```
Expected: both `= 1`. If either holds, check the `AURPackageHeld` metric / Grafana "AUR Mirror -- Pipeline" dashboard for the reason.

- [ ] **Step 2: Confirm they're first-party + signed, and selene upgrades**

```bash
ssh selene 'sudo pacman -Syu && pacman -Si aur-mirror/claude-code aur-mirror/zoom | grep -E "Version|Validated By"'
```
Expected: both show a version and `Validated By: Signature`. Versions match upstream `stable`/`latest`.

---

## Notes for the executor

- `gh` must be authed for `usenix17`. If a repo already exists, drop `--source/--push` from `gh repo create` and `git push -u origin HEAD` instead.
- Zoom's first build downloads a ~300 MB rpm; the mirror build has network egress (public) so this works in-cluster.
- If Zoom's key rotates, Task 2 Step 1's fingerprint check will fail loudly — re-verify against Zoom and update `_zoom_fpr` + `zoom-pubkey.asc` + `$KEYSHA` together.
- `track: latest` means these two rebuild every nightly/on-sync run; that's intended and cheap (binary installs, no compile).
