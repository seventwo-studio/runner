# Runner Image Test Fixtures

This directory contains integration tests for the runner Docker image.

## Test Components

### 1. Mise Tool Management Test
- Verifies mise can be installed and used to manage runtimes
- Tests Node.js and Python installation via mise
- Confirms mise-managed tools are accessible

### 2. Playwright Browser Test
- Verifies `PLAYWRIGHT_BROWSERS_PATH` and `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD` environment variables
- Confirms pre-installed browsers (Chromium, Firefox, WebKit) are available
- Tests browser launch and basic functionality
- Validates JavaScript execution within browsers

### 3. Docker Availability Test
- Confirms Docker CLI is available
- Verifies Docker Buildx plugin is installed

### 4. Development Tools Test
- Checks for essential development tools (git, curl, wget, jq, make, gcc)

## Running Tests

### In CI (GitHub Actions)
Tests run automatically after the runner image is published:
```yaml
docker run --rm \
  -v ${{ github.workspace }}/.github/test-fixtures/runner:/workspace \
  -w /workspace \
  -e CI=true \
  ghcr.io/seventwo-studio/runner:latest \
  bash -c "chmod +x ./test-runner.sh && ./test-runner.sh"
```

### Locally
```bash
# Build the runner image first
cd images/runner
docker build -t test-runner .

# Run the tests
cd ../../
docker run --rm \
  -v $(pwd)/.github/test-fixtures/runner:/workspace \
  -w /workspace \
  -e CI=true \
  test-runner \
  bash -c "chmod +x ./test-runner.sh && ./test-runner.sh"
```

## Test Files

- `test-runner.sh` - Main test script that orchestrates all tests
- `package.json` - Node.js dependencies for Playwright tests
- `playwright.config.ts` - Playwright configuration
- `tests/browser.spec.ts` - Playwright browser launch and functionality tests
- `.mise.toml` - Mise configuration for test runtime requirements
