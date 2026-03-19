#!/bin/bash
set -euo pipefail

echo "Running preflight checks..."

# Verify macOS
if [ "$(uname)" != "Darwin" ]; then
  echo "ERROR: This script must run on macOS"
  exit 1
fi

# Verify macOS version (require 14.0+ / Sonoma)
MACOS_VERSION="$(sw_vers -productVersion)"
MACOS_MAJOR="$(echo "$MACOS_VERSION" | cut -d. -f1)"
if [ "$MACOS_MAJOR" -lt 14 ]; then
  echo "ERROR: macOS 14 (Sonoma) or later required, got $MACOS_VERSION"
  exit 1
fi
echo "  macOS $MACOS_VERSION"

# Verify architecture
ARCH="$(uname -m)"
echo "  Architecture: $ARCH"

# Verify admin privileges (needed for Xcode, /opt, etc.)
if ! groups | grep -qw admin; then
  echo "ERROR: Must run as an admin user"
  exit 1
fi
echo "  Admin privileges: ok"

# Check disk space (need at least 30 GB free for Xcode + tools)
FREE_GB=$(df -g / | tail -1 | awk '{print $4}')
if [ "$FREE_GB" -lt 30 ]; then
  echo "WARNING: Only ${FREE_GB} GB free — Xcode alone needs ~35 GB"
fi
echo "  Free disk space: ${FREE_GB} GB"

echo "Preflight checks passed"
