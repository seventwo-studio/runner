FROM ghcr.io/seventwo-studio/base:latest AS build

ARG TARGETOS
ARG TARGETARCH
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.8.1
ARG DOCKER_VERSION=29.3.0
ARG BUILDX_VERSION=0.32.1
ARG COMPOSE_VERSION=5.1.0

USER root

WORKDIR /actions-runner

# Fetch the latest runner version
COPY scripts/update-runner.sh /actions-runner/update-runner.sh
RUN chmod +x /actions-runner/update-runner.sh && /actions-runner/update-runner.sh

RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export RUNNER_ARCH=x64 ; fi \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v$(cat /actions-runner/latest-runner-version)/actions-runner-${TARGETOS}-${RUNNER_ARCH}-$(cat /actions-runner/latest-runner-version).tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz

RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export DOCKER_ARCH=x86_64 ; fi \
    && if [ "$RUNNER_ARCH" = "arm64" ]; then export DOCKER_ARCH=aarch64 ; fi \
    && curl -fLo docker.tgz https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && rm -rf docker.tgz \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fLo /usr/local/lib/docker/cli-plugins/docker-buildx \
        "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx \
    && curl -fLo /usr/local/lib/docker/cli-plugins/docker-compose \
        "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${DOCKER_ARCH}" \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Playwright build stage - separate for optimal caching
FROM ghcr.io/seventwo-studio/base:latest AS playwright

ARG PLAYWRIGHT_VERSION=latest
ARG USERNAME=zero
ARG NODE_VERSION=20

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Install mise for runtime management
# The mise installer runs as the current user (root) and installs to its home directory
RUN curl https://mise.run | sh && \
    mv $HOME/.local/bin/mise /usr/local/bin/mise

# Switch to zero user and install Node.js via mise
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Configure mise and install Node.js
RUN bash -c 'mise use -g node@${NODE_VERSION} && \
    eval "$(mise activate bash)" && \
    mise install'

# Set Playwright cache directory for the user
ENV PLAYWRIGHT_BROWSERS_PATH=/home/${USERNAME}/.cache/ms-playwright

# Install Playwright temporarily to download browsers, then remove it
# Projects will install their own Playwright version but use these pre-installed browsers
RUN bash -c 'eval "$(mise activate bash)" && \
    npm install -g playwright@${PLAYWRIGHT_VERSION} && \
    mkdir -p /home/${USERNAME}/.cache/ms-playwright && \
    playwright install chromium firefox webkit && \
    npm uninstall -g playwright'

# Switch back to root for system dependencies
USER root
# Install system dependencies for all browsers
# We need to temporarily reinstall playwright to run install-deps, then remove it again
RUN bash -c 'eval "$(mise activate bash)" && \
    npm install -g playwright@${PLAYWRIGHT_VERSION} && \
    playwright install-deps && \
    npm uninstall -g playwright'

FROM ghcr.io/seventwo-studio/base:latest AS main

ARG USERNAME=zero

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV RUNNER_WORKSPACE=/home/runner/work
ENV RUNNER_TEMP=/home/runner/work/_temp
ENV RUNNER_OS=Linux

# Cache directories — XDG base and tool-specific overrides
# These point tools at /home/runner/.cache which can be backed by
# a persistent volume (hostPath on ARC) or used as ephemeral cache
ENV XDG_CACHE_HOME=/home/runner/.cache
ENV MISE_CACHE_DIR=/home/runner/.cache/mise
ENV MISE_DATA_DIR=/home/runner/.cache/mise/data
ENV BUN_INSTALL_CACHE_DIR=/home/runner/.cache/bun
ENV npm_config_cache=/home/runner/.cache/npm
ENV npm_config_store_dir=/home/runner/.cache/pnpm-store
ENV CARGO_HOME=/home/runner/.cache/cargo
ENV RUSTUP_HOME=/home/runner/.cache/rustup
ENV GRADLE_USER_HOME=/home/runner/.cache/gradle
ENV CP_HOME_DIR=/home/runner/.cache/cocoapods

# Playwright configuration
# Set the browsers path to a location that's readable by all users
# Pre-installed browsers will be copied here, and the directory is made writable
# so projects can install additional browsers if there's a version mismatch
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/ms-playwright

# Install basic development tools for CI/CD
COPY scripts/basic-tools.sh /tmp/basic-tools.sh
RUN chmod +x /tmp/basic-tools.sh && /tmp/basic-tools.sh && rm /tmp/basic-tools.sh

# Install Java 17 (required for Maestro CLI)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openjdk-17-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Install Maestro CLI
ARG MAESTRO_VERSION=2.3.0
RUN mkdir -p /opt/maestro && \
    curl -fsSL -o /tmp/maestro.zip "https://github.com/mobile-dev-inc/maestro/releases/download/cli-${MAESTRO_VERSION}/maestro.zip" && \
    unzip -q /tmp/maestro.zip -d /opt/ && \
    rm /tmp/maestro.zip

# Install GitHub CLI (gh) from official repository
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install yq (YAML processor) via binary download
ARG YQ_VERSION=4.52.4
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install mise for runtime management
RUN curl https://mise.run | sh && \
    mv $HOME/.local/bin/mise /usr/local/bin/mise

# Setup tool cache directory and pre-seed with Node.js and Python
# This enables actions/setup-node and actions/setup-python to use cached versions
COPY scripts/setup-toolcache.sh /tmp/setup-toolcache.sh
RUN chmod +x /tmp/setup-toolcache.sh && /tmp/setup-toolcache.sh && rm /tmp/setup-toolcache.sh

# Install Bun runtime
RUN curl -fsSL https://bun.sh/install | bash && \
    mv $HOME/.bun/bin/bun /usr/local/bin/ && \
    chmod +x /usr/local/bin/bun && \
    bun --version

# Copy only Playwright browsers from playwright stage to system-wide location
# This makes them available to all users (runner, zero, root)
# Projects will install their own Playwright version and use these pre-installed browsers
# Directory is made world-writable so projects can install additional browsers if needed
RUN mkdir -p /usr/local/share/ms-playwright
COPY --from=playwright /home/${USERNAME}/.cache/ms-playwright /usr/local/share/ms-playwright
RUN chmod -R 777 /usr/local/share/ms-playwright

# Install Playwright system dependencies
# We temporarily install playwright just to run install-deps, then remove it
# The browsers are already copied above and will be reused
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -y && \
    apt-get install -y --no-install-recommends nodejs npm && \
    npx --yes playwright@latest install-deps && \
    apt-get remove -y nodejs npm && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && groupadd docker --gid 123 \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers \
    && mkdir -p /home/runner/.local/bin \
    && mkdir -p /home/runner/.cache \
    && mkdir -p /home/runner/.local/share \
    && mkdir -p /home/runner/.config \
    && if [ -d /home/zero/.local/bin ] && [ "$(ls -A /home/zero/.local/bin)" ]; then cp -r /home/zero/.local/bin/* /home/runner/.local/bin/; fi \
    && if [ -d /home/zero/.local/share ] && [ "$(ls -A /home/zero/.local/share)" ]; then cp -r /home/zero/.local/share/* /home/runner/.local/share/; fi \
    && if [ -d /home/zero/.cache ] && [ "$(ls -A /home/zero/.cache)" ]; then cp -r /home/zero/.cache/* /home/runner/.cache/; fi \
    && if [ -f /home/zero/.config/starship.toml ]; then cp /home/zero/.config/starship.toml /home/runner/.config/starship.toml; fi \
    && chown -R runner:runner /home/runner \
    && chmod -R 777 /home/zero \
    && mkdir -p /home/zero/.cache/mise /home/zero/.local/state/mise /home/zero/.local/share/mise \
    && chown -R ${USERNAME}:${USERNAME} /home/zero/.cache /home/zero/.local \
    && chmod -R 777 /home/zero/.cache /home/zero/.local

# Create GitHub Actions working directories
RUN mkdir -p /home/runner/work/_temp \
    && mkdir -p /home/runner/work/_actions \
    && chown -R runner:runner /home/runner/work

# Create runner .env and .path files (read by runner application on startup)
RUN echo "RUNNER_TOOL_CACHE=/opt/hostedtoolcache" > /home/runner/.env \
    && echo "AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache" >> /home/runner/.env \
    && echo "RUNNER_WORKSPACE=/home/runner/work" >> /home/runner/.env \
    && echo "RUNNER_TEMP=/home/runner/work/_temp" >> /home/runner/.env \
    && echo "RUNNER_OS=Linux" >> /home/runner/.env \
    && echo "PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/ms-playwright" >> /home/runner/.env \
    && echo "ImageOS=ubuntu22" >> /home/runner/.env \
    && echo "XDG_CACHE_HOME=/home/runner/.cache" >> /home/runner/.env \
    && echo "MISE_CACHE_DIR=/home/runner/.cache/mise" >> /home/runner/.env \
    && echo "MISE_DATA_DIR=/home/runner/.cache/mise/data" >> /home/runner/.env \
    && echo "BUN_INSTALL_CACHE_DIR=/home/runner/.cache/bun" >> /home/runner/.env \
    && echo "npm_config_cache=/home/runner/.cache/npm" >> /home/runner/.env \
    && echo "npm_config_store_dir=/home/runner/.cache/pnpm-store" >> /home/runner/.env \
    && echo "CARGO_HOME=/home/runner/.cache/cargo" >> /home/runner/.env \
    && echo "RUSTUP_HOME=/home/runner/.cache/rustup" >> /home/runner/.env \
    && echo "GRADLE_USER_HOME=/home/runner/.cache/gradle" >> /home/runner/.env \
    && echo "CP_HOME_DIR=/home/runner/.cache/cocoapods" >> /home/runner/.env \
    && echo "/opt/hostedtoolcache" > /home/runner/.path \
    && echo "/opt/maestro/bin" >> /home/runner/.path \
    && echo "/home/runner/.local/share/mise/shims" >> /home/runner/.path \
    && echo "/home/runner/.local/bin" >> /home/runner/.path \
    && chown runner:runner /home/runner/.env /home/runner/.path

# Setup shell configurations for runner user (required for mise integration)
COPY scripts/setup-runner-shell.sh /tmp/setup-runner-shell.sh
RUN chmod +x /tmp/setup-runner-shell.sh && \
    /tmp/setup-runner-shell.sh && \
    rm /tmp/setup-runner-shell.sh

WORKDIR /home/runner

USER runner
ENV HOME=/home/runner
# Set PATH to include mise shims and local bin for non-interactive shells (like GitHub Actions)
ENV PATH=/opt/maestro/bin:/home/runner/.local/share/mise/shims:/home/runner/.local/bin:/home/runner/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --chown=runner:docker --from=build /actions-runner .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

USER root
RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker

# Apply binary patch to allow custom ACTIONS_RESULTS_URL for cache server
# This patches Runner.Worker.dll to change ACTIONS_RESULTS_URL to ACTIONS_RESULTS_ORL
# allowing us to set CUSTOM_ACTIONS_RESULTS_URL environment variable
RUN sed -i 's/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x52\x00\x45\x00\x53\x00\x55\x00\x4C\x00\x54\x00\x53\x00\x5F\x00\x55\x00\x52\x00\x4C\x00/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x52\x00\x45\x00\x53\x00\x55\x00\x4C\x00\x54\x00\x53\x00\x5F\x00\x4F\x00\x52\x00\x4C\x00/g' /home/runner/bin/Runner.Worker.dll

# Create an entrypoint that sets arch-dependent env vars and initializes sandbox
RUN echo '#!/bin/bash' > /usr/local/bin/runner-entrypoint && \
    echo '# Set architecture-dependent env vars' >> /usr/local/bin/runner-entrypoint && \
    echo 'if [ "$(uname -m)" = "x86_64" ]; then' >> /usr/local/bin/runner-entrypoint && \
    echo '    export RUNNER_ARCH=X64' >> /usr/local/bin/runner-entrypoint && \
    echo 'else' >> /usr/local/bin/runner-entrypoint && \
    echo '    export RUNNER_ARCH=ARM64' >> /usr/local/bin/runner-entrypoint && \
    echo 'fi' >> /usr/local/bin/runner-entrypoint && \
    echo '' >> /usr/local/bin/runner-entrypoint && \
    echo '# Initialize sandbox if available' >> /usr/local/bin/runner-entrypoint && \
    echo 'if [ -x "/usr/local/bin/init-sandbox" ]; then' >> /usr/local/bin/runner-entrypoint && \
    echo '    /usr/local/bin/init-sandbox' >> /usr/local/bin/runner-entrypoint && \
    echo 'fi' >> /usr/local/bin/runner-entrypoint && \
    echo '' >> /usr/local/bin/runner-entrypoint && \
    echo '# Execute the command or run the runner' >> /usr/local/bin/runner-entrypoint && \
    echo 'exec "$@"' >> /usr/local/bin/runner-entrypoint && \
    chmod +x /usr/local/bin/runner-entrypoint

USER runner

# Clean final stage (inherits from main)
FROM main AS final
ENTRYPOINT ["/usr/local/bin/runner-entrypoint"]
