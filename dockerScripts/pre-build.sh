#!/bin/bash
# Pre-build script: Copy overlay files to ZMK shield directory
# This fixes reversed diodes on the Corne keyboard

set -e

ZMK_APP_DIR="/workspace/zmk/app"
CORNE_SHIELD_DIR="${ZMK_APP_DIR}/boards/shields/corne"
OVERLAYS_DIR="/workspace/dockerScripts/overlays"

echo "=== Running pre-build script ==="

# Check if overlay files exist in overlays directory
if [ -f "${OVERLAYS_DIR}/corne_left.overlay" ]; then
    echo "Copying corne_left.overlay to ${CORNE_SHIELD_DIR}/"
    cp "${OVERLAYS_DIR}/corne_left.overlay" "${CORNE_SHIELD_DIR}/"
else
    echo "Warning: corne_left.overlay not found in ${OVERLAYS_DIR}/"
fi

if [ -f "${OVERLAYS_DIR}/corne_right.overlay" ]; then
    echo "Copying corne_right.overlay to ${CORNE_SHIELD_DIR}/"
    cp "${OVERLAYS_DIR}/corne_right.overlay" "${CORNE_SHIELD_DIR}/"
else
    echo "Warning: corne_right.overlay not found in ${OVERLAYS_DIR}/"
fi

echo "=== Pre-build script complete ==="
