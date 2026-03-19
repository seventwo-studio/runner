#!/bin/bash
set -euo pipefail

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

XCODE_VERSION="${XCODE_VERSION:-latest}"

# ── Command Line Tools ──────────────────────────────────────────────
if xcode-select -p &>/dev/null; then
  echo "Xcode Command Line Tools already installed"
else
  echo "Installing Xcode Command Line Tools..."
  # Touch the sentinel file to trigger CLT install without GUI prompt
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  CLT_PACKAGE=$(softwareupdate -l 2>/dev/null | grep -B 1 "Command Line Tools" | grep -o "Command Line Tools.*" | head -1)
  if [ -n "$CLT_PACKAGE" ]; then
    softwareupdate -i "$CLT_PACKAGE" --agree-to-license
  else
    echo "WARNING: Could not find CLT package via softwareupdate"
    xcode-select --install 2>/dev/null || true
    echo "  Accept the dialog to install, then re-run this script"
    exit 1
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

# ── xcodes CLI ──────────────────────────────────────────────────────
if ! command -v xcodes &>/dev/null; then
  echo "Installing xcodes CLI..."
  brew install xcodesorg/made/xcodes
fi

# aria2 for fast parallel Xcode downloads
if ! command -v aria2c &>/dev/null; then
  brew install aria2
fi

# ── Install Xcode ──────────────────────────────────────────────────
if [ "$XCODE_VERSION" = "latest" ]; then
  # Get the latest non-beta release
  XCODE_VERSION=$(xcodes list 2>/dev/null | grep -v Beta | grep -v Release | tail -1 | awk '{print $1}')
  echo "Resolved latest Xcode version: $XCODE_VERSION"
fi

if xcodes installed | grep -q "$XCODE_VERSION"; then
  echo "Xcode $XCODE_VERSION already installed"
else
  echo "Installing Xcode $XCODE_VERSION..."
  if [ -z "${XCODES_USERNAME:-}" ] || [ -z "${XCODES_PASSWORD:-}" ]; then
    echo "ERROR: Set XCODES_USERNAME and XCODES_PASSWORD to download Xcode"
    echo "  export XCODES_USERNAME='your@apple.id'"
    echo "  export XCODES_PASSWORD='your-password'"
    exit 1
  fi
  xcodes install "$XCODE_VERSION" --experimental-unxip
fi

# ── Select and configure ────────────────────────────────────────────
echo "Selecting Xcode $XCODE_VERSION as default..."
sudo xcodes select "$XCODE_VERSION"

echo "Accepting Xcode license..."
sudo xcodebuild -license accept

# ── iOS Simulator ───────────────────────────────────────────────────
echo "Checking iOS simulators..."
if xcrun simctl list runtimes 2>/dev/null | grep -q "iOS"; then
  echo "iOS simulator runtime already installed"
else
  echo "Downloading iOS simulator runtime..."
  xcodebuild -downloadPlatform iOS
fi

echo "Xcode $(xcodebuild -version | head -1) ready"
echo "  Path: $(xcode-select -p)"
echo "  Simulators: $(xcrun simctl list runtimes 2>/dev/null | grep -c iOS) iOS runtime(s)"
