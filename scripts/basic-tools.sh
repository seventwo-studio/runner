#!/bin/bash
# Install basic development and CI/CD tools for GitHub Actions runner

set -e

echo "Installing basic development tools..."

export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update -y

# Install all basic tools
apt-get install -y \
    acl \
    aria2 \
    autoconf \
    automake \
    binutils \
    bison \
    brotli \
    bzip2 \
    cmake \
    coreutils \
    curl \
    dbus \
    dnsutils \
    dpkg-dev \
    fakeroot \
    file \
    findutils \
    flex \
    fonts-noto-color-emoji \
    ftp \
    g++ \
    gcc \
    gnupg2 \
    haveged \
    iproute2 \
    iputils-ping \
    jq \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libyaml-dev \
    locales \
    lz4 \
    m4 \
    make \
    mediainfo \
    mercurial \
    net-tools \
    netcat-openbsd \
    openssh-client \
    p7zip-full \
    p7zip-rar \
    parallel \
    patchelf \
    pigz \
    pkg-config \
    pollinate \
    python-is-python3 \
    python3-pip \
    python3-venv \
    rpm \
    rsync \
    shellcheck \
    sphinxsearch \
    sqlite3 \
    ssh \
    sshpass \
    sudo \
    swig \
    systemd-coredump \
    tar \
    telnet \
    texinfo \
    time \
    tk \
    tree \
    tzdata \
    unzip \
    upx \
    wget \
    xvfb \
    xz-utils \
    zip \
    zsync \
    zstd

# Image processing libraries (sharp/libvips support and broad format coverage)
# libvips-dev pulls in: libpng, libjpeg, libtiff, libgif, libwebp, fftw3, lcms2, exif, etc.
apt-get install -y \
    libvips-dev \
    libvips-tools \
    libheif-dev \
    librsvg2-dev \
    libopenjp2-7-dev \
    libpoppler-glib-dev \
    libraw-dev \
    libcgif-dev \
    libimagequant-dev \
    imagemagick \
    graphicsmagick \
    libmagic-dev \
    git-lfs

# Initialize git-lfs
git lfs install --system

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Basic development tools installation completed successfully!"
