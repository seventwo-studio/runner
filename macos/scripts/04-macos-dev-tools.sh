#!/bin/bash
set -euo pipefail

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

echo "Installing macOS development tools..."

brew install cocoapods
brew install swiftlint
brew install xcbeautify

echo "macOS dev tools installed"
