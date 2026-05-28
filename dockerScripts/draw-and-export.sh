#!/bin/bash
set -e
set -x

# ---- KEYMAP-DRAWER OFFICIAL USAGE (2026-05) ----
# To parse ZMK DTS to YAML:
#   keymap parse -z <input.dts> -o <output.yaml>
# To draw SVG from keymap YAML:
#   keymap draw -c <config.yaml> <input.yaml> -o <output.svg>
# (Passing -c before subcommand is valid since keymap-drawer 0.23)
# See: https://github.com/caksoylar/keymap-drawer/blob/main/README.md
# -----------------------------------------------

# Convert hex to decimal in DTS files
# Wait for up to 5 seconds for zephyr_left.dts to appear
for i in {1..10}; do
  if [ -f firmware/zephyr_left.dts ]; then
    break
  fi
  echo "Waiting for firmware/zephyr_left.dts ... ($i)"
  sleep 0.5
done
if [ ! -f firmware/zephyr_left.dts ]; then
  echo "ERROR: firmware/zephyr_left.dts not found after waiting. Exiting."
  exit 1
fi

python3 dockerScripts/convert_hex_layer.py firmware/zephyr_left.dts zephyr_left_fixed.dts
# python3 dockerScripts/convert_hex_layer.py zephyr_right.dts zephyr_right_fixed.dts

grep -n '0x' zephyr_left_fixed.dts || echo 'No hex left in left'
# grep -n '0x' zephyr_right_fixed.dts || echo 'No hex left in right'

head -100 zephyr_left_fixed.dts
# head -100 zephyr_right_fixed.dts

# Generate YAML keymaps
keymap parse -z zephyr_left_fixed.dts -o drawings/corne_left.yaml
# keymap parse -z zephyr_right_fixed.dts -o corne_right.yaml

# Draw SVGs
keymap draw draw/config.yaml drawings/corne_left.yaml -o drawings/corne_left.svg
# keymap draw draw/config.yaml corne_right.yaml -o drawings/corne_right.svg

echo "Drawings generated: drawings/corne_left.svg drawings/corne_right.svg"

