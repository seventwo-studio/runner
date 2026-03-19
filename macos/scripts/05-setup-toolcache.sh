#!/bin/bash
set -euo pipefail

RUNNER_ARCH="${RUNNER_ARCH:-arm64}"
TOOLCACHE="/opt/hostedtoolcache"

echo "Setting up tool cache at $TOOLCACHE..."

if [ ! -d "$TOOLCACHE" ]; then
  sudo mkdir -p "$TOOLCACHE"
  sudo chown "$(whoami):staff" "$TOOLCACHE"
  sudo chmod 755 "$TOOLCACHE"
fi

# Map runner arch to toolcache arch convention
if [ "$RUNNER_ARCH" = "x64" ]; then
  TC_ARCH="x64"
else
  TC_ARCH="arm64"
fi

# ── Pre-seed Node.js 20 ────────────────────────────────────────────
echo "Pre-seeding Node.js 20..."
NODE_VERSION=$(mise latest node@20)
echo "  Resolved: Node.js $NODE_VERSION"

mise install "node@$NODE_VERSION" --quiet
NODE_DIR=$(mise where "node@$NODE_VERSION")

DEST="$TOOLCACHE/node/$NODE_VERSION/$TC_ARCH"
mkdir -p "$DEST"
cp -a "$NODE_DIR/." "$DEST/"
touch "$DEST/.complete"
echo "  Cached at: $DEST"

mise uninstall "node@$NODE_VERSION" --quiet

# ── Pre-seed Python 3.12 ───────────────────────────────────────────
echo "Pre-seeding Python 3.12..."
PYTHON_VERSION=$(mise latest python@3.12)
echo "  Resolved: Python $PYTHON_VERSION"

mise install "python@$PYTHON_VERSION" --quiet
PYTHON_DIR=$(mise where "python@$PYTHON_VERSION")

DEST="$TOOLCACHE/Python/$PYTHON_VERSION/$TC_ARCH"
mkdir -p "$DEST"
cp -a "$PYTHON_DIR/." "$DEST/"
touch "$DEST/.complete"
echo "  Cached at: $DEST"

mise uninstall "python@$PYTHON_VERSION" --quiet

echo "Tool cache setup complete"
