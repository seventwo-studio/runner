#!/bin/bash

# Ensure jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install -y jq
fi

# Fetch the latest runner version from GitHub releases
latest_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | cut -c 2-)

# Validate the version format (should be semantic version like 2.314.1)
if [[ ! $latest_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format: $latest_version"
    echo "Using fallback version 2.314.1"
    latest_version="2.314.1"
fi

# Save the fetched version to a file for use in the Dockerfile
echo "$latest_version" > /actions-runner/latest-runner-version
echo "Using GitHub Actions runner version: $latest_version"
