#!/bin/bash
set -euo pipefail

if [ ! -d /workspace/.west ]; then
    echo 'Copying pre-built ZMK workspace...'
    cp -r /build-context/. /workspace/ 2>/dev/null || true
    cp -r /build-context/.build /workspace/ 2>/dev/null || true
    cp -r /build-context/zmk /workspace/ 2>/dev/null || true
    cp -r /build-context/zephyr /workspace/ 2>/dev/null || true
    cp -r /build-context/modules /workspace/ 2>/dev/null || true
fi

cd /workspace && /usr/local/bin/build-firmware.sh
