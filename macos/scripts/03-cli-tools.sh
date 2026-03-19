#!/bin/bash
set -euo pipefail

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"

echo "Installing CLI tools via Homebrew..."

FORMULAE=(
  git
  git-lfs
  curl
  wget
  jq
  yq
  make
  cmake
  gh
  ripgrep
  fd
  tree
  shellcheck
  zstd
  p7zip
)

brew install "${FORMULAE[@]}"

# Initialize git-lfs
git lfs install --system

echo "CLI tools installed"
