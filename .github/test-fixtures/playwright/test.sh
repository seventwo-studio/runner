#!/bin/bash
set -euo pipefail

echo "--- Playwright browser tests ---"
echo ""

echo "Installing dependencies..."
mise exec -- npm install --no-audit --no-fund 2>&1

echo ""
echo "Running Playwright tests (chromium, firefox, webkit)..."
mise exec -- npx playwright test 2>&1

echo ""
echo "Playwright tests passed."
