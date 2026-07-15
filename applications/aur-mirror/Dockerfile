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
    && pacman -Sc --noconfirm

# Install aurutils from AUR (bootstrap via makepkg as build user)
RUN useradd -m -G wheel builder \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Install Trivy for vulnerability scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# Install Anthropic SDK for Claude PKGBUILD scanning
RUN python -m pip install anthropic --break-system-packages

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
