#!/bin/bash
# Install apt-fast for parallel package downloads
set -e

echo "Installing package manager optimizations..."

# Create necessary directories
mkdir -p /etc/bash_completion.d

# Download and install apt-fast for parallel package downloads
wget -O /usr/local/sbin/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/apt-fast"
chmod +x /usr/local/sbin/apt-fast
wget -O /etc/bash_completion.d/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/bash/apt-fast"

# Configure apt-fast with optimized settings for faster downloads
cat > /etc/apt-fast.conf << 'EOF'
# apt-fast configuration for parallel downloads
_APTMGR=apt-get
DOWNLOADBEFORE=true
_MAXNUM=10
_MAXCONPERSRV=16
_SPLITCON=16
_MINSPLITSZ=1M
_PIECEALGO=inorder
DLLIST='/tmp/apt-fast.list'
_DOWNLOADER='aria2c --no-conf -c -j ${_MAXNUM} -x ${_MAXCONPERSRV} -s ${_SPLITCON} -i ${DLLIST} --min-split-size=${_MINSPLITSZ} --stream-piece-selector=${_PIECEALGO} --connect-timeout=30 --timeout=300 --max-connection-per-server=32 --disk-cache=32M --file-allocation=none --retry-wait=1 --max-tries=3'
APTCACHE=/var/cache/apt/apt-fast
EOF

# Install aria2 (required for apt-fast parallel downloads)
apt-get install -y aria2

# Add fast mirrors for better download speeds
CODENAME=$(lsb_release -cs)
if [ -f /etc/debian_version ]; then
    cat >> /etc/apt/sources.list << EOF

# Additional fast mirrors for improved download speeds
deb http://deb.debian.org/debian ${CODENAME} main contrib non-free
deb http://security.debian.org/debian-security ${CODENAME}-security main contrib non-free
deb http://deb.debian.org/debian ${CODENAME}-updates main contrib non-free
deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free
EOF
fi

# Update package lists with new mirrors
apt-get update -qq

echo "apt-fast installed successfully with optimized mirrors."
