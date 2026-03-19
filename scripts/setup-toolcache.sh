#!/bin/bash
# Setup /opt/hostedtoolcache directory and pre-seed with common runtimes
# This makes actions/setup-node and actions/setup-python find cached versions
# instead of downloading from scratch on every workflow run.

set -e

echo "Setting up tool cache directory..."

# Determine architecture suffix used by actions/tool-cache
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "amd64" ]; then
    TC_ARCH="x64"
else
    TC_ARCH="arm64"
fi

TOOLCACHE=/opt/hostedtoolcache
mkdir -p "$TOOLCACHE"

# --- Pre-seed Node.js 20 ---
echo "Pre-seeding Node.js 20 into tool cache..."
NODE_VERSION=$(mise latest node@20)
echo "  Resolved Node.js version: ${NODE_VERSION}"

mise install "node@${NODE_VERSION}"
NODE_DIR=$(mise where "node@${NODE_VERSION}")

DEST="${TOOLCACHE}/node/${NODE_VERSION}/${TC_ARCH}"
mkdir -p "$DEST"
cp -a "${NODE_DIR}/." "$DEST/"
touch "${DEST}/.complete"
echo "  Cached at: ${DEST}"

mise uninstall "node@${NODE_VERSION}"

# --- Pre-seed Python 3.12 ---
echo "Pre-seeding Python 3.12 into tool cache..."
PYTHON_VERSION=$(mise latest python@3.12)
echo "  Resolved Python version: ${PYTHON_VERSION}"

mise install "python@${PYTHON_VERSION}"
PYTHON_DIR=$(mise where "python@${PYTHON_VERSION}")

DEST="${TOOLCACHE}/Python/${PYTHON_VERSION}/${TC_ARCH}"
mkdir -p "$DEST"
cp -a "${PYTHON_DIR}/." "$DEST/"
touch "${DEST}/.complete"
echo "  Cached at: ${DEST}"

mise uninstall "python@${PYTHON_VERSION}"

# Set permissions - the directory must be writable by runner user and any actions
chown -R 1001:1001 "$TOOLCACHE"
chmod -R 777 "$TOOLCACHE"

echo "Tool cache setup completed successfully!"
echo "  Node.js ${NODE_VERSION} -> ${TOOLCACHE}/node/${NODE_VERSION}/${TC_ARCH}/"
echo "  Python ${PYTHON_VERSION} -> ${TOOLCACHE}/Python/${PYTHON_VERSION}/${TC_ARCH}/"
