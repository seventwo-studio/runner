#!/bin/bash
# Validation tests for macOS runner provisioning.
# Mirrors .github/test-fixtures/toolchain/test.sh structure.
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

check_env_set() {
  local var="$1"
  if [ -n "${!var:-}" ]; then
    pass "$var=${!var}"
  else
    fail "$var not set"
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

RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"

# ── Core CLI tools ──────────────────────────────────────────────────
section "Core CLI tools"
for cmd in git curl wget jq yq make cmake gh bun mise ripgrep fd tree shellcheck; do
  check_cmd "$cmd"
done

# ── macOS dev tools ─────────────────────────────────────────────────
section "macOS dev tools"
check_cmd pod
check_cmd swiftlint
check_cmd xcbeautify

# ── Xcode ───────────────────────────────────────────────────────────
section "Xcode"
if xcodebuild -version &>/dev/null; then
  pass "xcodebuild ($(xcodebuild -version 2>&1 | head -1))"
else
  fail "xcodebuild"
fi

if xcode-select -p &>/dev/null; then
  pass "xcode-select -p ($(xcode-select -p))"
else
  fail "xcode-select -p"
fi

if swift --version &>/dev/null; then
  pass "swift ($(swift --version 2>&1 | head -1))"
else
  fail "swift"
fi

if xcrun simctl list runtimes 2>/dev/null | grep -q "iOS"; then
  pass "iOS simulator runtime"
else
  fail "iOS simulator runtime not found"
fi

# ── Git LFS ─────────────────────────────────────────────────────────
section "Git LFS"
check_cmd git-lfs

# ── Mise tool management ───────────────────────────────────────────
section "Mise tool management"
MISE_TEST_DIR=$(mktemp -d)
echo -e '[tools]\nnode = "20"' > "$MISE_TEST_DIR/.mise.toml"
if (cd "$MISE_TEST_DIR" && mise install -q 2>/dev/null && mise exec -- node --version &>/dev/null); then
  pass "mise install + exec node ($(cd "$MISE_TEST_DIR" && mise exec -- node --version))"
else
  fail "mise install + exec node"
fi
rm -rf "$MISE_TEST_DIR"

# ── Runner environment variables ────────────────────────────────────
section "Runner environment variables"
check_env RUNNER_OS "macOS"
check_env ImageOS "macos${MACOS_MAJOR}"
check_env_set RUNNER_WORKSPACE
check_env_set RUNNER_TEMP
check_env RUNNER_TOOL_CACHE "/opt/hostedtoolcache"
check_env AGENT_TOOLSDIRECTORY "/opt/hostedtoolcache"

# ── Cache directory env vars ────────────────────────────────────────
section "Cache directory env vars"
check_env_set XDG_CACHE_HOME
check_env_set MISE_CACHE_DIR
check_env_set MISE_DATA_DIR
check_env_set BUN_INSTALL_CACHE_DIR
check_env_set npm_config_cache
check_env_set npm_config_store_dir
check_env_set CARGO_HOME
check_env_set RUSTUP_HOME
check_env_set CP_HOME_DIR

# ── Directories and files ───────────────────────────────────────────
section "Directories and files"
check_dir /opt/hostedtoolcache
check_writable /opt/hostedtoolcache
check_dir "$HOME/work/_temp"
check_file "$RUNNER_DIR/.env"
check_file "$RUNNER_DIR/.path"

# ── Tool cache pre-seeded runtimes ──────────────────────────────────
section "Tool cache pre-seeded runtimes"
if ls /opt/hostedtoolcache/node/*/arm64/.complete 1>/dev/null 2>&1 || \
   ls /opt/hostedtoolcache/node/*/x64/.complete 1>/dev/null 2>&1; then
  pass "Node.js in tool cache"
else
  fail "Node.js not in tool cache"
fi
if ls /opt/hostedtoolcache/Python/*/arm64/.complete 1>/dev/null 2>&1 || \
   ls /opt/hostedtoolcache/Python/*/x64/.complete 1>/dev/null 2>&1; then
  pass "Python in tool cache"
else
  fail "Python not in tool cache"
fi

# ── .env file contents ─────────────────────────────────────────────
section ".env file contents"
for key in RUNNER_TOOL_CACHE RUNNER_OS XDG_CACHE_HOME MISE_CACHE_DIR BUN_INSTALL_CACHE_DIR npm_config_cache CARGO_HOME CP_HOME_DIR; do
  if grep -q "^${key}=" "$RUNNER_DIR/.env" 2>/dev/null; then
    pass "$key in .env"
  else
    fail "$key missing from .env"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  $PASSED passed, $FAILED failed"
echo "=========================================="

if [ "$FAILED" -gt 0 ]; then exit 1; fi
