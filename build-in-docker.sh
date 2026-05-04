#!/bin/bash
set -euo pipefail;

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="zmk-configurob-baked"

echo "Building firmware in Docker container..."
docker run --rm \
  -v "$SCRIPT_DIR":/workspace \
  -w /workspace \
  "$DOCKER_IMAGE" \
  bash -c "
    set -euo pipefail
    git config --global --add safe.directory '*'
    
    # Clean everything for a fresh start
    echo 'Cleaning workspace for fresh build...'
    rm -rf .west zmk zephyr modules .build
    
    echo 'Initializing west workspace...'
    west init -l config
    west update --fetch-opt=--filter=blob:none
    west zephyr-export
    
    # Run build script
    bash dockerScripts/build-firmware.sh
  "
echo "Firmware files are in: $SCRIPT_DIR/firmware/"
ls -la "$SCRIPT_DIR/firmware/"
