#!/bin/bash
# Provision a macOS machine as a GitHub Actions self-hosted runner.
# Idempotent — safe to re-run.
#
# Usage:
#   ./provision.sh [--skip-xcode] [--xcode-version 16.4]
#
# Environment variables for Xcode download (required unless --skip-xcode):
#   XCODES_USERNAME   Apple ID email
#   XCODES_PASSWORD   Apple ID password

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ────────────────────────────────────────────────────────
SKIP_XCODE=false
XCODE_VERSION="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-xcode)   SKIP_XCODE=true; shift ;;
    --xcode-version) XCODE_VERSION="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

export SKIP_XCODE XCODE_VERSION

# ── Architecture ────────────────────────────────────────────────────
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
  export RUNNER_ARCH="x64"
  export HOMEBREW_PREFIX="/usr/local"
else
  export RUNNER_ARCH="arm64"
  export HOMEBREW_PREFIX="/opt/homebrew"
fi

# ── Runner directory ────────────────────────────────────────────────
export RUNNER_HOME="$HOME"
export RUNNER_DIR="$HOME/actions-runner"

echo "============================================"
echo "  macOS Runner Provisioning"
echo "  arch=$ARCH  runner_arch=$RUNNER_ARCH"
echo "  skip_xcode=$SKIP_XCODE"
echo "============================================"

# ── Run scripts in order ────────────────────────────────────────────
for script in "$SCRIPT_DIR"/scripts/[0-9][0-9]-*.sh; do
  name="$(basename "$script")"

  # Skip Xcode script if requested
  if [ "$SKIP_XCODE" = "true" ] && [[ "$name" == "02-"* ]]; then
    echo ""
    echo "--- Skipping $name (--skip-xcode) ---"
    continue
  fi

  echo ""
  echo "--- $name ---"
  bash "$script"
done

echo ""
echo "============================================"
echo "  Provisioning complete"
echo ""
echo "  Next steps:"
echo "    cd $RUNNER_DIR"
echo "    ./config.sh --url <repo-or-org-url> --token <reg-token>"
echo "    ./run.sh"
echo "============================================"
