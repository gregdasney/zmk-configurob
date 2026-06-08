#!/bin/bash
set -euo pipefail;

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="zmk-configurob-baked"  

docker build -f Dockerfile.firmware . -t zmkthing && docker run --rm -v ./:/firmware zmkthing cp -r firmware /firmware



# echo "Building dedicated Docker image for Corne SVG keymap..."
# docker build -f Dockerfile -t zmk-all .

# echo "Generating Corne keymap SVG with container..."
# docker run --rm -v "$SCRIPT_DIR/drawings:/workspace/drawings" corne-draw

# echo "Keymap image is in: $SCRIPT_DIR/drawings/corne.svg"
# ls -la "$SCRIPT_DIR/drawings/"
