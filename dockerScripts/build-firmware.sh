#!/bin/bash
set -euo pipefail

echo "Building firmware...";

# Run pre-build script to copy overlay files
if [ -f "dockerScripts/pre-build.sh" ]; then
    bash dockerScripts/pre-build.sh
fi;

# Build Corne left
west build -s zmk/app -d .build/corne_left -b nice_nano//zmk -- \
    -DZMK_CONFIG=$(pwd)/config \
    -DSHIELD=corne_left

mkdir -p firmware
if [ -f .build/corne_left/zephyr/zmk.uf2 ]; then
    cp .build/corne_left/zephyr/zmk.uf2 firmware/corne_left.uf2
    echo "Built firmware/corne_left.uf2"
elif [ -f .build/corne_left/zephyr/zmk.bin ]; then
    cp .build/corne_left/zephyr/zmk.bin firmware/corne_left.bin
    echo "Built firmware/corne_left.bin"
fi;

# Build Corne right
west build -s zmk/app -d .build/corne_right -b nice_nano//zmk -- \
    -DZMK_CONFIG=$(pwd)/config \
    -DSHIELD=corne_right

if [ -f .build/corne_right/zephyr/zmk.uf2 ]; then
    cp .build/corne_right/zephyr/zmk.uf2 firmware/corne_right.uf2
    echo "Built firmware/corne_right.uf2"
elif [ -f .build/corne_right/zephyr/zmk.bin ]; then
    cp .build/corne_right/zephyr/zmk.bin firmware/corne_right.bin
    echo "Built firmware/corne_right.bin"
fi;

echo "Build complete! Firmware files are in /workspace/firmware/"
ls -la firmware/
