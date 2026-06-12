FROM archlinux:latest

# System update + build toolchain
RUN pacman -Syu --noconfirm \
    base-devel \
    devtools \
    git \
    gnupg \
    python \
    python-yaml \
    && pacman -Sc --noconfirm

# Install aurutils from AUR (bootstrap via makepkg as build user)
RUN useradd -m -G wheel builder \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Install Trivy for vulnerability scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# Install aurutils
RUN su - builder -c ' \
    git clone https://aur.archlinux.org/aurutils.git /tmp/aurutils \
    && cd /tmp/aurutils \
    && makepkg -si --noconfirm \
    && rm -rf /tmp/aurutils'

COPY aur-build-all /usr/local/bin/aur-build-all
RUN chmod 755 /usr/local/bin/aur-build-all

USER builder
WORKDIR /build
