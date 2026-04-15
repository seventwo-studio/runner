#!/bin/bash
set -euo pipefail

PASSED=0
FAILED=0

pass() { echo "  ok  $1"; PASSED=$((PASSED + 1)); }
fail() { echo "  FAIL  $1"; FAILED=$((FAILED + 1)); }

section() { echo "" && echo "--- $1 ---"; }

check_cmd() {
  if command -v "$1" &>/dev/null; then pass "$1"; else fail "$1 not found"; fi
}

check_env() {
  local var="$1" expected="$2"
  local actual="${!var:-}"
  if [ "$actual" = "$expected" ]; then
    pass "$var=$expected"
  else
    fail "$var expected '$expected', got '$actual'"
  fi
}

check_dir() {
  if [ -d "$1" ]; then pass "$1 exists"; else fail "$1 missing"; fi
}

check_writable() {
  if [ -w "$1" ]; then pass "$1 writable"; else fail "$1 not writable"; fi
}

check_file() {
  if [ -f "$1" ]; then pass "$1 exists"; else fail "$1 missing"; fi
}

# ── Core CLI tools ──────────────────────────────────────────────────
section "Core CLI tools"
for cmd in git curl wget jq yq make gcc g++ cmake node-gyp bun mise gh java docker maestro crane buildah; do
  check_cmd "$cmd"
done

# ── Docker plugins ──────────────────────────────────────────────────
section "Docker plugins"
if docker buildx version &>/dev/null; then pass "docker buildx"; else fail "docker buildx"; fi
if docker compose version &>/dev/null; then pass "docker compose"; else fail "docker compose"; fi

# ── Crane (registry operations) ────────────────────────────────────
section "Crane"
if crane version &>/dev/null; then pass "crane version"; else fail "crane version"; fi

# ── Buildah (daemonless OCI builds) ────────────────────────────────
section "Buildah"
if buildah --version &>/dev/null; then pass "buildah version"; else fail "buildah version"; fi

# ── Image processing libraries ──────────────────────────────────────
section "Image processing libraries"
check_cmd vips
check_cmd convert  # ImageMagick
check_cmd git-lfs
if pkg-config --exists vips 2>/dev/null; then
  pass "libvips pkg-config ($(pkg-config --modversion vips))"
else
  fail "libvips pkg-config"
fi

# ── Mise tool management ────────────────────────────────────────────
section "Mise tool management"
# Verify mise can install and run tools from a .mise.toml
MISE_TEST_DIR=$(mktemp -d)
echo -e '[tools]\nnode = "20"' > "$MISE_TEST_DIR/.mise.toml"
if (cd "$MISE_TEST_DIR" && mise install -q 2>/dev/null && mise exec -- node --version &>/dev/null); then
  pass "mise install + exec node ($(cd "$MISE_TEST_DIR" && mise exec -- node --version))"
else
  fail "mise install + exec node"
fi
rm -rf "$MISE_TEST_DIR"

# ── System Python ───────────────────────────────────────────────────
section "System Python"
check_cmd python3
check_cmd pip3

# ── Runner environment variables ────────────────────────────────────
section "Runner environment variables"
check_env RUNNER_OS "Linux"
check_env RUNNER_WORKSPACE "/home/runner/work"
check_env RUNNER_TEMP "/home/runner/work/_temp"
check_env RUNNER_TOOL_CACHE "/opt/hostedtoolcache"
check_env AGENT_TOOLSDIRECTORY "/opt/hostedtoolcache"
check_env ImageOS "ubuntu22"

# ── Cache directory env vars (issue #3) ─────────────────────────────
section "Cache directory env vars"
check_env XDG_CACHE_HOME "/home/runner/.cache"
check_env MISE_CACHE_DIR "/home/runner/.cache/mise"
check_env MISE_DATA_DIR "/home/runner/.cache/mise/data"
check_env BUN_INSTALL_CACHE_DIR "/home/runner/.cache/bun"
check_env npm_config_cache "/home/runner/.cache/npm"
check_env npm_config_store_dir "/home/runner/.cache/pnpm-store"
check_env CARGO_HOME "/home/runner/.cache/cargo"
check_env RUSTUP_HOME "/home/runner/.cache/rustup"
check_env GRADLE_USER_HOME "/home/runner/.cache/gradle"
check_env CP_HOME_DIR "/home/runner/.cache/cocoapods"
check_env PLAYWRIGHT_BROWSERS_PATH "/usr/local/share/ms-playwright"

# ── Directories & files ─────────────────────────────────────────────
section "Directories and files"
check_dir /opt/hostedtoolcache
check_writable /opt/hostedtoolcache
check_dir /home/runner/work/_temp
check_dir /usr/local/share/ms-playwright
check_writable /usr/local/share/ms-playwright
check_file /home/runner/.env
check_file /home/runner/.path

# ── Tool cache pre-seeded runtimes ──────────────────────────────────
section "Tool cache pre-seeded runtimes"
if ls /opt/hostedtoolcache/node/*/x64/.complete 1>/dev/null 2>&1 || \
   ls /opt/hostedtoolcache/node/*/arm64/.complete 1>/dev/null 2>&1; then
  pass "Node.js in tool cache"
else
  fail "Node.js not in tool cache"
fi
if ls /opt/hostedtoolcache/Python/*/x64/.complete 1>/dev/null 2>&1 || \
   ls /opt/hostedtoolcache/Python/*/arm64/.complete 1>/dev/null 2>&1; then
  pass "Python in tool cache"
else
  fail "Python not in tool cache"
fi

# ── Pre-installed Playwright browsers ───────────────────────────────
section "Pre-installed Playwright browsers"
for browser in chromium firefox webkit; do
  if ls /usr/local/share/ms-playwright/${browser}* 1>/dev/null 2>&1; then
    pass "$browser"
  else
    fail "$browser not found"
  fi
done

# ── .env file contains cache vars ──────────────────────────────────
section ".env file cache vars"
while IFS='=' read -r key value; do
  if grep -q "^${key}=" /home/runner/.env 2>/dev/null; then
    pass "$key in .env"
  else
    fail "$key missing from .env"
  fi
done <<'VARS'
XDG_CACHE_HOME=/home/runner/.cache
MISE_CACHE_DIR=/home/runner/.cache/mise
BUN_INSTALL_CACHE_DIR=/home/runner/.cache/bun
npm_config_cache=/home/runner/.cache/npm
CARGO_HOME=/home/runner/.cache/cargo
PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/ms-playwright
VARS

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  $PASSED passed, $FAILED failed"
echo "=========================================="

if [ "$FAILED" -gt 0 ]; then exit 1; fi
