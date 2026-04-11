#!/usr/bin/env bash
set -euo pipefail

# Build the runner image locally and push buildx cache to the registry.
# CI pulls from this cache, so a local warm-up makes CI builds much faster.
#
# Usage:
#   ./build.sh              # build + push cache for local arch
#   ./build.sh --push       # also push the image itself
#   ./build.sh --multi      # build + push cache for amd64 AND arm64

IMAGE_NAME="ghcr.io/seventwo-studio/runner"
CACHE_REF="${IMAGE_NAME}:buildcache"
VERSION=$(tr -d '[:space:]' < version.txt)

PUSH_IMAGE=false
MULTI_ARCH=false

for arg in "$@"; do
  case "$arg" in
    --push) PUSH_IMAGE=true ;;
    --multi) MULTI_ARCH=true ;;
  esac
done

# Ensure buildx builder with docker-container driver (needed for cache export)
if ! docker buildx inspect runner-builder &>/dev/null; then
  docker buildx create --name runner-builder --use
else
  docker buildx use runner-builder
fi

if [ "$MULTI_ARCH" = true ]; then
  PLATFORMS="linux/amd64,linux/arm64"
else
  PLATFORMS="linux/$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')"
fi

BUILD_ARGS=(
  --platform "$PLATFORMS"
  --cache-from "type=registry,ref=${CACHE_REF}"
  --cache-to "type=registry,ref=${CACHE_REF},mode=max"
  --tag "${IMAGE_NAME}:latest"
  --tag "${IMAGE_NAME}:${VERSION}"
)

if [ "$PUSH_IMAGE" = true ]; then
  BUILD_ARGS+=(--push)
elif [ "$MULTI_ARCH" = false ]; then
  BUILD_ARGS+=(--load)
fi

echo "Building ${IMAGE_NAME}:${VERSION} (${PLATFORMS})"
echo "Cache: ${CACHE_REF}"

docker buildx build "${BUILD_ARGS[@]}" .
