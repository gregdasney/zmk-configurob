#!/bin/bash
set -euo pipefail;

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="zmk-configurob-baked"

echo "Building Docker image and copying firmware out..."
docker build . -t zmkthing && docker run --rm -v ./:/firmware zmkthing cp -r firmware /firmware
echo "Firmware files are in: $SCRIPT_DIR/firmware/"
ls -la "$SCRIPT_DIR/firmware/"
