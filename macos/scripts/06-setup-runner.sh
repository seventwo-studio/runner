#!/bin/bash
set -euo pipefail

RUNNER_ARCH="${RUNNER_ARCH:-arm64}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"

echo "Setting up GitHub Actions runner..."

# Fetch latest runner version
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep -o '"tag_name": "v[^"]*"' | head -1 | cut -d'"' -f4 | cut -c2-)
echo "  Latest runner version: $LATEST_VERSION"

# Check if already installed at the right version
if [ -f "$RUNNER_DIR/.runner_version" ]; then
  CURRENT_VERSION=$(cat "$RUNNER_DIR/.runner_version")
  if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "  Runner $LATEST_VERSION already installed"
    exit 0
  fi
  echo "  Upgrading from $CURRENT_VERSION to $LATEST_VERSION"
fi

# Download
TARBALL="actions-runner-osx-${RUNNER_ARCH}-${LATEST_VERSION}.tar.gz"
URL="https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/${TARBALL}"

echo "  Downloading $TARBALL..."
mkdir -p "$RUNNER_DIR"
curl -fL -o "/tmp/$TARBALL" "$URL"

# Extract
echo "  Extracting to $RUNNER_DIR..."
tar xzf "/tmp/$TARBALL" -C "$RUNNER_DIR"
rm "/tmp/$TARBALL"

# Track installed version
echo "$LATEST_VERSION" > "$RUNNER_DIR/.runner_version"

echo "  Runner installed at $RUNNER_DIR"
echo "  Version: $LATEST_VERSION ($RUNNER_ARCH)"
