#!/bin/bash
set -e

echo "=========================================="
echo "Runner Image Integration Tests"
echo "=========================================="
echo ""

# Test 1: Mise Installation and Tool Management
echo "Test 1: Testing mise installation and tool management"
echo "--------------------------------------------------"

# Check if mise is available (should be from base image)
if command -v mise &> /dev/null; then
    echo "✓ mise is available"
    mise --version
else
    echo "✗ mise not found - this is expected as it's not in the runner image"
    echo "  Installing mise for testing..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install tools using mise
echo ""
echo "Installing Node.js and Python via mise..."
mise install

# Verify tools are installed
echo ""
echo "Verifying mise-installed tools:"
mise exec -- node --version
mise exec -- npm --version
mise exec -- python --version

echo "✓ mise successfully installed and managed tools"
echo ""

# Test 2: Playwright Browser Testing
echo "Test 2: Testing Playwright with pre-installed browsers"
echo "-------------------------------------------------------"

# Verify environment variables
echo "Checking Playwright environment variables:"
echo "  PLAYWRIGHT_BROWSERS_PATH=$PLAYWRIGHT_BROWSERS_PATH"

if [ "$PLAYWRIGHT_BROWSERS_PATH" != "/usr/local/share/ms-playwright" ]; then
    echo "✗ PLAYWRIGHT_BROWSERS_PATH not set correctly"
    exit 1
fi

echo "✓ Playwright environment variables are correct"
echo ""

# Verify browsers are available
echo "Checking for pre-installed browsers:"
if [ -d "/usr/local/share/ms-playwright" ]; then
    echo "✓ Browser directory exists"
    ls -la /usr/local/share/ms-playwright/

    # Check for specific browsers
    for browser in chromium firefox webkit; do
        if ls /usr/local/share/ms-playwright/${browser}* 1> /dev/null 2>&1; then
            echo "  ✓ $browser found"
        else
            echo "  ✗ $browser not found"
            exit 1
        fi
    done
else
    echo "✗ Browser directory not found"
    exit 1
fi

echo ""
echo "Installing Playwright npm package..."
mise exec -- npm install --no-save

echo ""
echo "Running Playwright tests..."
mise exec -- npm test

echo ""
echo "✓ Playwright tests completed successfully"
echo ""

# Test 3: Docker Availability
echo "Test 3: Testing Docker availability"
echo "------------------------------------"

if command -v docker &> /dev/null; then
    echo "✓ docker is available"
    docker --version

    # Check for buildx
    if docker buildx version &> /dev/null; then
        echo "✓ docker buildx is available"
        docker buildx version
    else
        echo "✗ docker buildx not found"
        exit 1
    fi
else
    echo "✗ docker not found"
    exit 1
fi

echo ""

# Test 4: Bun Runtime
echo "Test 4: Testing Bun runtime"
echo "---------------------------"

if command -v bun &> /dev/null; then
    echo "✓ bun is available"
    bun --version
else
    echo "✗ bun not found"
    exit 1
fi

echo ""

# Test 5: Basic Development Tools
echo "Test 5: Testing basic development tools"
echo "----------------------------------------"

tools=("git" "curl" "wget" "jq" "make" "gcc")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "  ✓ $tool is available"
    else
        echo "  ✗ $tool not found"
        exit 1
    fi
done

echo ""

# Test 6: Image Processing Libraries
echo "Test 6: Testing image processing libraries"
echo "-------------------------------------------"

# Check vips (sharp dependency)
if command -v vips &> /dev/null; then
    echo "  ✓ vips is available ($(vips --version 2>&1 | head -1))"
else
    echo "  ✗ vips not found"
    exit 1
fi

# Check ImageMagick
if command -v convert &> /dev/null; then
    echo "  ✓ imagemagick is available"
else
    echo "  ✗ imagemagick not found"
    exit 1
fi

# Check git-lfs
if command -v git-lfs &> /dev/null; then
    echo "  ✓ git-lfs is available ($(git-lfs --version))"
else
    echo "  ✗ git-lfs not found"
    exit 1
fi

# Check libvips shared library is linkable
if pkg-config --exists vips 2>/dev/null; then
    echo "  ✓ libvips pkg-config: $(pkg-config --modversion vips)"
else
    echo "  ✗ libvips pkg-config not found"
    exit 1
fi

echo ""

# Test 7: Tool Cache Directory
echo "Test 7: Testing tool cache directory"
echo "-------------------------------------"

if [ -d "/opt/hostedtoolcache" ]; then
    echo "  ✓ /opt/hostedtoolcache exists"
else
    echo "  ✗ /opt/hostedtoolcache not found"
    exit 1
fi

if [ -w "/opt/hostedtoolcache" ]; then
    echo "  ✓ /opt/hostedtoolcache is writable"
else
    echo "  ✗ /opt/hostedtoolcache is not writable"
    exit 1
fi

if [ "${RUNNER_TOOL_CACHE}" = "/opt/hostedtoolcache" ]; then
    echo "  ✓ RUNNER_TOOL_CACHE is set correctly"
else
    echo "  ✗ RUNNER_TOOL_CACHE not set (got: ${RUNNER_TOOL_CACHE})"
    exit 1
fi

# Check pre-seeded Node.js
if ls /opt/hostedtoolcache/node/*/x64/.complete 1> /dev/null 2>&1 || \
   ls /opt/hostedtoolcache/node/*/arm64/.complete 1> /dev/null 2>&1; then
    echo "  ✓ Node.js pre-seeded in tool cache"
else
    echo "  ✗ Node.js not found in tool cache"
    exit 1
fi

# Check pre-seeded Python
if ls /opt/hostedtoolcache/Python/*/x64/.complete 1> /dev/null 2>&1 || \
   ls /opt/hostedtoolcache/Python/*/arm64/.complete 1> /dev/null 2>&1; then
    echo "  ✓ Python pre-seeded in tool cache"
else
    echo "  ✗ Python not found in tool cache"
    exit 1
fi

echo ""

# Test 8: Docker Compose
echo "Test 8: Testing Docker Compose v2"
echo "-----------------------------------"

if docker compose version &> /dev/null; then
    echo "  ✓ docker compose is available"
    docker compose version
else
    echo "  ✗ docker compose not found"
    exit 1
fi

echo ""

# Test 9: GitHub Runner Environment Variables
echo "Test 9: Testing GitHub runner environment"
echo "-------------------------------------------"

env_vars=("RUNNER_OS" "RUNNER_WORKSPACE" "RUNNER_TEMP" "RUNNER_TOOL_CACHE" "AGENT_TOOLSDIRECTORY")
for var in "${env_vars[@]}"; do
    if [ -n "${!var}" ]; then
        echo "  ✓ $var=${!var}"
    else
        echo "  ✗ $var not set"
        exit 1
    fi
done

if [ -d "/home/runner/work/_temp" ]; then
    echo "  ✓ /home/runner/work/_temp exists"
else
    echo "  ✗ /home/runner/work/_temp not found"
    exit 1
fi

if [ -f "/home/runner/.env" ] && [ -f "/home/runner/.path" ]; then
    echo "  ✓ .env and .path config files exist"
else
    echo "  ✗ .env or .path config files missing"
    exit 1
fi

echo ""

# Test 10: cmake
echo "Test 10: Testing cmake"
echo "-----------------------"

if command -v cmake &> /dev/null; then
    echo "  ✓ cmake is available"
    cmake --version | head -1
else
    echo "  ✗ cmake not found"
    exit 1
fi

echo ""

# Test 11: System Python with pip
echo "Test 11: Testing system Python with pip"
echo "-----------------------------------------"

if command -v python3 &> /dev/null; then
    echo "  ✓ python3 is available ($(python3 --version))"
else
    echo "  ✗ python3 not found"
    exit 1
fi

if command -v pip3 &> /dev/null; then
    echo "  ✓ pip3 is available ($(pip3 --version 2>&1 | head -1))"
else
    echo "  ✗ pip3 not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "All tests passed successfully! ✓"
echo "=========================================="
