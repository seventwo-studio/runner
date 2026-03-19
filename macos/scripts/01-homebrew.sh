#!/bin/bash
set -euo pipefail

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

if command -v brew &>/dev/null; then
  echo "Homebrew already installed, updating..."
  brew update --quiet
else
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for the rest of provisioning
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

brew analytics off

echo "Homebrew $(brew --version | head -1) ready"
