#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="zmkfirmware/zmk-dev-arm:stable"

echo "Pulling ZMK devcontainer image..."
docker pull "$DOCKER_IMAGE"

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

    echo 'Building Corne left...'
    west build -s zmk/app -d .build/corne_left -b nice_nano//zmk -- \
        -DZMK_CONFIG=\$(pwd)/config \
        -DSHIELD=corne_left
    mkdir -p firmware
    if [ -f .build/corne_left/zephyr/zmk.uf2 ]; then
        cp .build/corne_left/zephyr/zmk.uf2 firmware/corne_left.uf2
        echo 'Built firmware/corne_left.uf2'
    elif [ -f .build/corne_left/zephyr/zmk.bin ]; then
        cp .build/corne_left/zephyr/zmk.bin firmware/corne_left.bin
        echo 'Built firmware/corne_left.bin'
    else
        echo 'ERROR: No firmware output for left side'
        exit 1
    fi

    echo 'Building Corne right...'
    west build -s zmk/app -d .build/corne_right -b nice_nano//zmk -- \
        -DZMK_CONFIG=\$(pwd)/config \
        -DSHIELD=corne_right
    if [ -f .build/corne_right/zephyr/zmk.uf2 ]; then
        cp .build/corne_right/zephyr/zmk.uf2 firmware/corne_right.uf2
        echo 'Built firmware/corne_right.uf2'
    elif [ -f .build/corne_right/zephyr/zmk.bin ]; then
        cp .build/corne_right/zephyr/zmk.bin firmware/corne_right.bin
        echo 'Built firmware/corne_right.bin'
    else
        echo 'ERROR: No firmware output for right side'
        exit 1
    fi

    echo 'Build complete!'
  "

echo "Firmware files are in: $SCRIPT_DIR/firmware/"
ls -la "$SCRIPT_DIR/firmware/" 2>/dev/null || echo "No firmware directory found"
