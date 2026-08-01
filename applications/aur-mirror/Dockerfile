FROM archlinux:latest

# System update + build toolchain
RUN pacman -Syu --noconfirm \
    base-devel \
    devtools \
    git \
    gnupg \
    python \
    python-pip \
    python-yaml \
    python-pytest \
    && pacman -Sc --noconfirm

# Install aurutils from AUR (bootstrap via makepkg as build user)
RUN useradd -m -G wheel builder \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Install Trivy for vulnerability scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# Install the Anthropic SDK for Claude PKGBUILD scanning in an ISOLATED venv.
# Installing it into the system site-packages (pip --break-system-packages) drags
# in certifi/idna/urllib3/charset-normalizer as files pacman does not own, which
# then collide with python-certifi/python-idna when building any package that
# needs python-requests ("failed to commit transaction (conflicting files)").
# The venv keeps those files out of /usr/lib/pythonX.Y/site-packages; only the
# scan phase runs under /opt/scan-venv/bin/python3 (see builder*.yaml). The build
# phase keeps the system python so python package install-paths resolve to /usr.
RUN python -m venv --system-site-packages /opt/scan-venv \
    && /opt/scan-venv/bin/pip install --no-cache-dir anthropic

# Install aurutils
RUN su - builder -c ' \
    git clone https://aur.archlinux.org/aurutils.git /tmp/aurutils \
    && cd /tmp/aurutils \
    && makepkg -si --noconfirm \
    && rm -rf /tmp/aurutils'

# aur-build-all runs all three phases (scan / build / sign). The scan phase
# does the Claude PKGBUILD scan, which is why the anthropic SDK is installed
# above; the key is mounted only in the scan container.
COPY aur-build-all /usr/local/bin/aur-build-all
RUN chmod 755 /usr/local/bin/aur-build-all

USER builder
WORKDIR /build
