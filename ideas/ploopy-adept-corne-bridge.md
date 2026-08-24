# Ploopy Adept ↔ Corne — RP2040 UART bridge + nice_nano

## Goal
Add a nice_nano "daughter board" to a Ploopy Adept trackball so it works
as a second ZMK split peripheral for the Corne (left half = central),
fully wireless on a LiPo.

## Topology
- Adept stock RP2040 runs modified QMK: streams mouse report (buttons,
  x/y, wheel) over one-way UART TX (1 Mbps) using the two spare switch
  footprints (COSW5/COSW7, unpopulated D2LS-21 pads).
- nice_nano runs ZMK as split peripheral #2: UART RX → ZMK input pipeline.
- Corne left = central, bumped to 2 peripherals (right half + Adept).

## Decisions
- Power: LiPo, single 3V3 rail from nice_nano; isolate Madromys 5V→3.3V
  regulator. Adept USB port dead in normal use.
- UART: TX-only one-way stream. No RX.
- Spare-pad GPIOs: wire first, verify after (multimeter/schematic).

## Phase 1 — Physical wiring (wire-first)
- Spare switch pad (GPIO side) → nice_nano RX
- Switch pad GND side → nice_nano GND
- nice_nano 3V3 → Madromys 3V3 rail; isolate PCB regulator
- Then continuity-test spare pads → RP2040 GPIOs (candidates from QMK
  UNUSABLE_PINS: GP8/10/12/13/14/16/18/20/22)

## Phase 2 — Adept QMK patch
- Init RP2040 UART on identified GPIO(s), 1 Mbps, 3.3V
- pointing_device_task_user streams framed report each poll
  (POINTING_DEVICE_TASK_THROTTLE_MS=1):
  STX, buttons, dx, dy, wheel, hwheel, chksum (~9 B @ 1 kHz)
- Keep VIA, DPI cycle, dragscroll, bootloader. Flash via USB drag-drop.
- Risk: QMK RP2040 UART shim may need ChibiOS/pico-SDK glue; fallback
  460800 baud.

## Phase 3 — nice_nano ZMK module (this repo)
- New module zmk-adept-bridge (pattern: tadakado/zmk-ch559-spi, UART):
  parse frames → INPUT_EV_REL + INPUT_EV_KEY → zmk,input-listener →
  pointing + key positions; keymap binds &mkp MB1–5 / drag-scroll.
  Frame-sync/checksum + bad-frame watchdog.
- Shield adept_nn: UART RX node, input-listener,
  CONFIG_ZMK_SPLIT_ROLE_CENTRAL=n, battery reporting.
- config/west.yml: add module
- config/corne.conf: ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=2,
  BT_MAX_CONN/BT_MAX_PAIRED 5→7
- dockerScripts/build-firmware.sh: third build → firmware/adept_nn.uf2

## Phase 4 — Flash, pair, validate
- Flash left, right, Adept-nice_nano; power together → auto-pair
- Validate: direction/CPI, wheel, 6-button mapping, 1 kHz stream
  integrity, latency, sleep/wake, battery level

## Risks
- Spare-pad GPIO identity unknown until verified
- QMK RP2040 UART shim is the main firmware unknown
- RP2040 stays powered (small extra drain); duplicate pointer if Adept
  USB is also plugged into the PC
