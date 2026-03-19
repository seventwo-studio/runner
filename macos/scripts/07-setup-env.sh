#!/bin/bash
set -euo pipefail

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
RUNNER_HOME="${RUNNER_HOME:-$HOME}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"

echo "Configuring environment..."

# ── macOS version for ImageOS ───────────────────────────────────────
MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"

# ── Create work directories ────────────────────────────────────────
mkdir -p "$RUNNER_HOME/work/_temp"
mkdir -p "$RUNNER_HOME/work/_actions"

# ── Create cache directories ───────────────────────────────────────
CACHE_DIRS=(
  "$RUNNER_HOME/.cache"
  "$RUNNER_HOME/.cache/mise"
  "$RUNNER_HOME/.cache/mise/data"
  "$RUNNER_HOME/.cache/bun"
  "$RUNNER_HOME/.cache/npm"
  "$RUNNER_HOME/.cache/pnpm-store"
  "$RUNNER_HOME/.cache/cargo"
  "$RUNNER_HOME/.cache/rustup"
  "$RUNNER_HOME/.cache/cocoapods"
)
for dir in "${CACHE_DIRS[@]}"; do
  mkdir -p "$dir"
done

# ── Runner .env file ───────────────────────────────────────────────
cat > "$RUNNER_DIR/.env" <<EOF
RUNNER_TOOL_CACHE=/opt/hostedtoolcache
AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUNNER_WORKSPACE=$RUNNER_HOME/work
RUNNER_TEMP=$RUNNER_HOME/work/_temp
RUNNER_OS=macOS
ImageOS=macos${MACOS_MAJOR}
XDG_CACHE_HOME=$RUNNER_HOME/.cache
MISE_CACHE_DIR=$RUNNER_HOME/.cache/mise
MISE_DATA_DIR=$RUNNER_HOME/.cache/mise/data
BUN_INSTALL_CACHE_DIR=$RUNNER_HOME/.cache/bun
npm_config_cache=$RUNNER_HOME/.cache/npm
npm_config_store_dir=$RUNNER_HOME/.cache/pnpm-store
CARGO_HOME=$RUNNER_HOME/.cache/cargo
RUSTUP_HOME=$RUNNER_HOME/.cache/rustup
CP_HOME_DIR=$RUNNER_HOME/.cache/cocoapods
EOF
echo "  Created $RUNNER_DIR/.env"

# ── Runner .path file ──────────────────────────────────────────────
cat > "$RUNNER_DIR/.path" <<EOF
/opt/hostedtoolcache
$RUNNER_HOME/.local/share/mise/shims
$RUNNER_HOME/.local/bin
$HOMEBREW_PREFIX/bin
$HOMEBREW_PREFIX/sbin
EOF
echo "  Created $RUNNER_DIR/.path"

# ── Shell config (.zprofile — sourced by login zsh) ────────────────
ZPROFILE="$RUNNER_HOME/.zprofile"
MARKER="# --- managed by runner provisioning ---"

# Only add if not already present
if ! grep -qF "$MARKER" "$ZPROFILE" 2>/dev/null; then
  cat >> "$ZPROFILE" <<EOF

$MARKER
eval "\$($HOMEBREW_PREFIX/bin/brew shellenv)"

# mise
export PATH="\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH"
if command -v mise &>/dev/null; then
  eval "\$(mise activate zsh)"
fi

# Cache directories (matching Linux runner pattern)
export XDG_CACHE_HOME="\$HOME/.cache"
export MISE_CACHE_DIR="\$HOME/.cache/mise"
export MISE_DATA_DIR="\$HOME/.cache/mise/data"
export BUN_INSTALL_CACHE_DIR="\$HOME/.cache/bun"
export npm_config_cache="\$HOME/.cache/npm"
export npm_config_store_dir="\$HOME/.cache/pnpm-store"
export CARGO_HOME="\$HOME/.cache/cargo"
export RUSTUP_HOME="\$HOME/.cache/rustup"
export CP_HOME_DIR="\$HOME/.cache/cocoapods"

# Runner
export RUNNER_TOOL_CACHE=/opt/hostedtoolcache
export AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
$MARKER
EOF
  echo "  Updated $ZPROFILE"
else
  echo "  $ZPROFILE already configured"
fi

# ── Install mise + bun via Homebrew ────────────────────────────────
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
brew install mise
brew install oven-sh/bun/bun

# Trust all config paths for mise
mise settings set trusted_config_paths "/"
echo "  mise: trusted_config_paths set to /"

echo "Environment configured"
