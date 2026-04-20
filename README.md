# GitHub Actions Runner Image

A specialized container image for running GitHub Actions workflows, built on top of the base image with GitHub Actions runner capabilities and Docker support.

## Overview

This image provides a self-hosted GitHub Actions runner with:
- GitHub Actions runner (latest version)
- Docker CLI and Docker Buildx plugin
- Container hooks for Kubernetes deployments
- Playwright with multi-browser support (Chromium, Firefox, WebKit)
- Bun runtime for fast TypeScript/JavaScript execution
- Java 17 JRE (headless) for tooling that requires a JVM
- Maestro CLI for mobile/web E2E testing
- Security sandbox support (inherited from base)
- All development tools from the base image

## Architecture

```
runner:latest
    └── base:latest
        └── Ubuntu 22.04
```

## Features

### GitHub Actions Runner
- **Latest Runner**: Automatically fetches and installs the latest GitHub Actions runner
- **Multi-Architecture**: Supports both AMD64 and ARM64 architectures
- **Container Hooks**: Includes runner container hooks for Kubernetes deployments
- **Signal Handling**: Proper signal handling for graceful shutdown

### Docker Integration
- **Docker CLI**: Full Docker command-line interface
- **Docker Buildx**: Advanced build capabilities with multi-platform support
- **Docker Group**: Runner user is added to docker group for container access

### Buildah (Container Image Builds)
- **Buildah 1.39.4**: Compiled from source with commit pinning for supply chain security
- **Cross-compiled with CGO**: Builds natively on any host arch (no QEMU), cross-compiles for target
- **VFS Storage**: System-wide `/etc/containers/storage.conf` configured for VFS (works in unprivileged pods)
- **Chroot Isolation**: Runs inside Kubernetes pods without mount namespace access

### Security Features
- **Sandbox Support**: Can initialize security sandbox if available
- **Non-root User**: Runs as `runner` user (UID 1001) with sudo access
- **Secure Defaults**: Proper permissions and group membership

## Bill of Materials

### Base Components
- All components from the base image
- GitHub Actions runner (latest version, auto-detected)
- Docker CLI (v29.3.0)
- Docker Buildx plugin (v0.32.1)
- Docker Compose (v5.1.0)
- Runner container hooks (v0.8.1)
- Buildah (v1.39.4, compiled from source)
- crane (v0.21.5)
- Node.js (v20 LTS via mise)
- Playwright (v1.59.1)
- Bun (latest version)
- Java 17 JRE (headless)
- Maestro CLI (v2.3.0)
- GitHub CLI (gh)
- yq (v4.52.4)

### Playwright Browsers
- Chromium (latest stable)
- Firefox (latest stable)
- WebKit (latest stable)

### System Users
- `runner` user (UID 1001) with sudo access
- `docker` group (GID 123) for Docker access

### Environment Variables
- `RUNNER_MANUALLY_TRAP_SIG=1` - Manual signal trapping
- `ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1` - Log output to stdout
- `ImageOS=ubuntu22` - OS identification for Actions
- `PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/ms-playwright` - Browser cache location (system browsers, writable for fallback installs)

## Usage

### Building the Image

```bash
# Build for current platform
docker build -t runner:latest .

# Build for specific platform
docker build --platform linux/amd64 -t runner:amd64 .
docker build --platform linux/arm64 -t runner:arm64 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t runner:latest .

# Optimized build with layer caching (recommended for CI)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=ghcr.io/seventwo-studio/runner:buildcache \
  --cache-to type=registry,ref=ghcr.io/seventwo-studio/runner:buildcache,mode=max \
  -t runner:latest \
  .

# Build with custom Playwright version
docker build --build-arg PLAYWRIGHT_VERSION=1.45.0 -t runner:latest .
```

**Build Optimization Notes:**
- The Dockerfile uses multi-stage builds to separate Playwright installation for optimal caching
- BuildKit mount caches are used for apt packages to speed up dependency installation
- Playwright browsers are installed in a dedicated stage that caches independently
- Node.js and browser binaries are copied from the playwright stage to the final image
- Use `--cache-from` and `--cache-to` flags in CI for persistent layer caching

### Running as Self-Hosted Runner

#### Basic Setup

```bash
# Run with GitHub token and repository
docker run -it \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  -v /var/run/docker.sock:/var/run/docker.sock \
  runner:latest
```

#### With Docker-in-Docker

```bash
# Run with privileged mode for full Docker support
docker run -it --privileged \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  runner:latest
```

#### With Security Sandbox

```bash
# Run with sandbox enabled
docker run -it \
  --cap-add=NET_ADMIN \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  -e SANDBOX_ENABLED=true \
  -e SANDBOX_ALLOWED_DOMAINS="api.github.com,github.com" \
  runner:latest
```

### Kubernetes Deployment

#### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
      - name: runner
        image: ghcr.io/seventwo-studio/runner:latest
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-secrets
              key: token
        - name: REPO_URL
          value: "https://github.com/owner/repo"
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
```

#### With Security Sandbox

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-github-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-github-runner
  template:
    metadata:
      labels:
        app: secure-github-runner
    spec:
      containers:
      - name: runner
        image: ghcr.io/seventwo-studio/runner:latest
        securityContext:
          capabilities:
            add:
              - NET_ADMIN
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-secrets
              key: token
        - name: REPO_URL
          value: "https://github.com/owner/repo"
        - name: SANDBOX_ENABLED
          value: "true"
        - name: SANDBOX_ALLOWED_DOMAINS
          value: "api.github.com,github.com,registry.npmjs.org"
```

### Docker Compose

```yaml
version: '3.8'

services:
  github-runner:
    image: ghcr.io/seventwo-studio/runner:latest
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - REPO_URL=${REPO_URL}
      - SANDBOX_ENABLED=true
      - SANDBOX_ALLOWED_DOMAINS=api.github.com,github.com
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

## Configuration Options

### Environment Variables

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `GITHUB_TOKEN` | - | GitHub PAT or registration token | `ghp_xxx` |
| `REPO_URL` | - | Repository URL | `https://github.com/owner/repo` |
| `RUNNER_NAME` | Auto-generated | Custom runner name | `my-runner` |
| `RUNNER_LABELS` | - | Additional labels | `docker,linux,x64` |
| `RUNNER_GROUP` | `default` | Runner group | `production` |
| `SANDBOX_ENABLED` | `false` | Enable security sandbox | `true` |
| `SANDBOX_ALLOWED_DOMAINS` | - | Allowed domains | `api.github.com,npm.org` |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `PLAYWRIGHT_VERSION` | `1.59.1` | Playwright version |
| `BUILDAH_VERSION` | `1.39.4` | Buildah version (compiled from source) |
| `BUILDAH_COMMIT` | *(pinned)* | Expected commit SHA for tag verification |
| `RUNNER_CONTAINER_HOOKS_VERSION` | `0.8.1` | Container hooks version |
| `DOCKER_VERSION` | `29.3.0` | Docker CLI version |
| `BUILDX_VERSION` | `0.32.1` | Docker Buildx version |
| `COMPOSE_VERSION` | `5.1.0` | Docker Compose version |
| `MAESTRO_VERSION` | `2.3.0` | Maestro CLI version |
| `YQ_VERSION` | `4.52.4` | yq YAML processor version |
| `CRANE_VERSION` | `0.21.5` | crane registry tool version |

### Volume Mounts

| Container Path | Description | Recommended Host Mount |
|----------------|-------------|------------------------|
| `/var/run/docker.sock` | Docker socket | `/var/run/docker.sock` |
| `/tmp` | Temporary files | `tmpfs` |
| `/home/runner/_work` | GitHub Actions workspace | Named volume |

### Required Capabilities

| Capability | Required For | Description |
|------------|--------------|-------------|
| `SYS_ADMIN` | Buildah | Mount/unshare within chroot isolation |
| `SYS_CHROOT` | Buildah | Chroot isolation for RUN steps |
| `SETUID` | Buildah | UID mapping (newuidmap) |
| `SETGID` | Buildah | GID mapping (newgidmap) |
| `CHOWN` | Buildah | File ownership in build layers |
| `DAC_OVERRIDE` | Buildah | Access files during layer extraction |
| `FOWNER` | Buildah | Set ownership on extracted files |
| `NET_ADMIN` | Security sandbox | Network filtering (optional) |

## GitHub Actions Workflow Examples

### Basic CI/CD Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install dependencies
      run: npm install
    
    - name: Run tests
      run: npm test
    
    - name: Build application
      run: npm run build

  docker-build:
    runs-on: self-hosted
    needs: test
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Docker image
      run: docker build -t myapp:latest .
    
    - name: Run container tests
      run: docker run --rm myapp:latest npm test
```

### Multi-Platform Build

```yaml
name: Multi-Platform Build

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Build and push multi-platform image
      run: |
        docker buildx build \
          --platform linux/amd64,linux/arm64 \
          --push \
          -t myregistry/myapp:${{ github.ref_name }} \
          .
```

### Playwright End-to-End Testing

The runner image includes pre-installed Playwright browsers, eliminating the need to download them during workflow runs. This significantly speeds up test execution.

#### Basic E2E Test Workflow

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  playwright-tests:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4

    - name: Install dependencies
      run: npm ci
      # Note: Browsers are NOT downloaded during npm ci
      # PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 is set by default
      # This makes npm ci much faster (no 500MB+ download)

    - name: Run Playwright tests (Chromium)
      run: npx playwright test --project=chromium

    - name: Run Playwright tests (Firefox)
      run: npx playwright test --project=firefox

    - name: Run Playwright tests (WebKit)
      run: npx playwright test --project=webkit

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: playwright-report
        path: playwright-report/
```

#### Parallel Multi-Browser Testing

```yaml
name: E2E Tests (Parallel)

on:
  push:
    branches: [main]

jobs:
  playwright-tests:
    runs-on: self-hosted
    strategy:
      fail-fast: false
      matrix:
        browser: [chromium, firefox, webkit, msedge]
    steps:
    - uses: actions/checkout@v4

    - name: Install dependencies (fast - no browser download)
      run: npm ci

    - name: Run Playwright tests on ${{ matrix.browser }}
      run: npx playwright test --project=${{ matrix.browser }}

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: playwright-report-${{ matrix.browser }}
        path: playwright-report/
```

#### Installation Time Comparison

| Step | With Pre-installed Browsers | Without Pre-installed Browsers |
|------|---------------------------|-------------------------------|
| `npm ci` | ~30 seconds | ~3-5 minutes |
| Browser download | **0 seconds (skipped)** | ~2-4 minutes |
| System deps install | **0 seconds (pre-installed)** | ~1-2 minutes |
| **Total setup time** | **~30 seconds** | **~6-11 minutes** |

**Key Optimization Details:**

1. **No Browser Downloads**: `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` is set globally
   - When you run `npm ci`, Playwright detects this environment variable
   - It skips downloading ~500MB+ of browser binaries
   - Installation completes in seconds instead of minutes

2. **System Browsers Used**: `PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright`
   - Your project's Playwright automatically finds the pre-installed browsers
   - All browsers (Chromium, Firefox, WebKit, Edge) are available immediately
   - Works with any Playwright version (browsers are version-compatible)

3. **Fast Iteration**:
   - Re-running tests after code changes takes seconds
   - No waiting for downloads or dependency installation
   - Perfect for rapid test development

**Important Notes:**
- For Chromium-based browsers, ensure you run the container with `--ipc=host` flag to avoid out-of-memory issues
- Browsers run in headless mode by default - perfect for CI/CD
- All system dependencies are pre-installed, ensuring fast test startup
- Works with both `@playwright/test` and `playwright` npm packages

**Docker run example with Playwright:**
```bash
docker run -it --ipc=host \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  -v /var/run/docker.sock:/var/run/docker.sock \
  runner:latest
```

## Building Container Images with Buildah

The runner includes Buildah 1.39.4 for building OCI container images without a Docker daemon. This is designed for Kubernetes-hosted runners where Docker-in-Docker is not available.

### Required Pod Security Context

```yaml
securityContext:
  runAsUser: 1001
  runAsGroup: 1001
  allowPrivilegeEscalation: true
  seccompProfile:
    type: Unconfined
  appArmorProfile:
    type: Unconfined
  capabilities:
    drop: [ALL]
    add: [SYS_ADMIN, SYS_CHROOT, SETUID, SETGID, CHOWN, DAC_OVERRIDE, FOWNER]
```

### Workflow Usage

```yaml
- name: Build container image
  run: |
    sudo buildah bud \
      --isolation chroot \
      --ulimit nofile=$(ulimit -Hn):$(ulimit -Hn) \
      --ulimit nproc=$(ulimit -Hu):$(ulimit -Hu) \
      --cap-drop all \
      -t myimage:latest \
      -f ./Dockerfile .

- name: Push to registry
  run: |
    echo "${{ secrets.GITHUB_TOKEN }}" | sudo buildah login -u ${{ github.actor }} --password-stdin ghcr.io
    sudo buildah push myimage:latest ghcr.io/org/myimage:latest
```

### Flag Explanation

| Flag | Purpose |
|------|---------|
| `--isolation chroot` | Uses chroot instead of mount namespaces (blocked in pods) |
| `--ulimit nofile=...` | Caps file descriptor limit to pod's hard limit (buildah tries to raise it) |
| `--ulimit nproc=...` | Caps process limit to pod's hard limit |
| `--cap-drop all` | Prevents buildah from setting capabilities on RUN child processes |

### Storage Configuration

The image ships with `/etc/containers/storage.conf` pre-configured for VFS storage. No workflow-level storage configuration is needed. VFS is slower than overlay (full file copies vs copy-on-write) but works without fuse-overlayfs permissions.

## Security Considerations

### Sandbox Configuration

The runner supports the same security sandbox as the base image:

```bash
# Enable sandbox with specific domains
docker run -it \
  --cap-add=NET_ADMIN \
  -e SANDBOX_ENABLED=true \
  -e SANDBOX_ALLOWED_DOMAINS="api.github.com,github.com,registry.npmjs.org" \
  runner:latest
```

### Best Practices

1. **Use Secrets**: Store sensitive information in GitHub Secrets
2. **Enable Sandbox**: Use security sandbox for untrusted code
3. **Limit Network Access**: Configure allowed domains appropriately
4. **Regular Updates**: Keep runner image updated
5. **Monitor Resources**: Set resource limits in production

## Troubleshooting

### Runner Registration Issues

1. **Invalid Token**
   ```bash
   # Check token validity
   curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/user
   ```

2. **Repository Access**
   ```bash
   # Verify repository access
   curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/owner/repo
   ```

### Docker Issues

1. **Docker Socket Permission**
   ```bash
   # Fix docker socket permissions
   sudo chmod 666 /var/run/docker.sock
   ```

2. **Docker Daemon Not Running**
   ```bash
   # Start Docker daemon
   sudo systemctl start docker
   ```

### Sandbox Issues

1. **Network Connectivity**
   ```bash
   # Check firewall rules
   sudo iptables -L OUTPUT -n
   
   # Test connectivity
   curl -v https://api.github.com
   ```

2. **Missing Capabilities**
   ```bash
   # Check capabilities
   capsh --print | grep NET_ADMIN
   ```

### Performance Issues

1. **Resource Limits**
   ```bash
   # Monitor resource usage
   docker stats
   ```

2. **Disk Space**
   ```bash
   # Clean up Docker images
   docker system prune -a
   ```

### Playwright Issues

1. **Chromium Out-of-Memory Errors**
   ```bash
   # Ensure container is running with --ipc=host
   docker run -it --ipc=host runner:latest

   # Or in docker-compose.yml
   ipc: host
   ```

2. **Browser Not Found After npm ci**
   ```bash
   # Check if environment variables are set correctly
   echo $PLAYWRIGHT_BROWSERS_PATH
   # Should output: /root/.cache/ms-playwright

   echo $PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD
   # Should output: 1

   # Verify system browsers exist
   ls -la /root/.cache/ms-playwright

   # Test browser availability
   npx playwright install --dry-run
   ```

3. **Accidentally Downloaded Browsers During npm ci**
   ```bash
   # If you see Playwright downloading browsers, check:
   # 1. Environment variable is set
   env | grep PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD

   # 2. If running in a different user context, set it explicitly
   export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
   npm ci
   ```

4. **Version Mismatch Warnings**
   ```bash
   # System browsers work with any Playwright version
   # If you see version warnings, they're usually safe to ignore
   # But you can force using system browsers:
   PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright npx playwright test
   ```

5. **Test Timeouts**
   ```bash
   # Increase timeout in playwright.config.js
   # timeout: 30000 (default) -> 60000

   # Or set via environment variable
   PLAYWRIGHT_TIMEOUT=60000 npx playwright test
   ```

6. **Display Issues in Headless Mode**
   ```bash
   # Xvfb is pre-installed for virtual display support
   # Tests should run headless by default
   xvfb-run npx playwright test

   # Or explicitly set headless in playwright.config.js
   use: { headless: true }
   ```

7. **Permission Denied on Browser Binaries**
   ```bash
   # Check browser cache permissions
   ls -la /root/.cache/ms-playwright

   # Fix permissions if needed
   sudo chmod -R 755 /root/.cache/ms-playwright
   ```

8. **Want to Use Project-Specific Browsers**
   ```bash
   # Temporarily allow browser downloads for this run
   PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0 npm ci

   # Or unset the variable
   unset PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD
   npm ci
   npx playwright install --with-deps

   # Note: This will download ~500MB and take several minutes
   ```

## Advanced Configuration

### Custom Runner Scripts

```bash
# Create custom runner configuration
cat > runner-config.sh << 'EOF'
#!/bin/bash
./config.sh \
  --url "$REPO_URL" \
  --token "$GITHUB_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace

./run.sh
EOF

chmod +x runner-config.sh
```

### Health Checks

```yaml
# Docker Compose with health check
version: '3.8'

services:
  github-runner:
    image: ghcr.io/seventwo-studio/runner:latest
    healthcheck:
      test: ["CMD", "pgrep", "-f", "Runner.Listener"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Monitoring

```bash
# Check runner status
docker exec runner-container ps aux | grep Runner.Listener

# View runner logs
docker logs runner-container

# Monitor resource usage
docker stats runner-container
```

## Notes

- The image inherits all features from the base image
- Docker socket access is required for container operations
- Security sandbox requires NET_ADMIN capability
- Runner automatically updates to the latest version on build
- Container hooks are included for Kubernetes deployments
- Proper signal handling ensures graceful shutdown
- Playwright browsers (Chromium, Firefox, WebKit, Edge) are pre-installed for fast test startup
- Use `--ipc=host` flag when running Chromium-based tests to avoid memory issues
- Node.js 20 LTS is included for Playwright and other JavaScript tooling