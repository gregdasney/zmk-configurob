# TrackPoint on the Corne (right half)

Adds a PS/2 TrackPoint (e.g. from an old ThinkPad keyboard) to the **right half**
of a split Corne, using [badjeff's PS/2 TrackPoint driver](https://github.com/badjeff/kb_zmk_ps2_mouse_trackpoint_driver).

The TrackPoint is wired only to the right half (the **peripheral**). The left half
(the **central**) receives the pointer events over the split link and feeds them
into ZMK's pointing/mouse listeners.

```
[TrackPoint] --PS/2--> [right half / peripheral]      [left half / central]
                        driver: zmk,input-mouse-ps2     built-in listeners
                        zmk,input-split  ----BLE---->   (mmv/msc/hid)
```

---

## Pin mapping

| TrackPoint signal | nice!nano header pin | nRF52840 pin | Notes |
|-------------------|:--------------------:|:------------:|-------|
| **SCL** (clock)   | 16                   | **P0.10**    | NFC2 pin — NFC must be freed (see below) |
| **SDA** (data)    | 10                   | **P0.09**    | NFC1 pin — NFC must be freed (see below) |
| **RST** (reset)   | 9                    | **P1.06**    | plain GPIO |

Internal UART pins used by the driver (not exposed to the TrackPoint):

| Purpose | nRF52840 pin |
|---------|:------------:|
| UART TX (parked) | P0.27 |
| UART RX (parked) | P0.28 |

### Why these pins
The Corne right-half key matrix uses:

- **rows:** header pins 4, 5, 6, 7
- **cols:** header pins 14, 15, 18, 19, 20, 21

So header pins **9, 10, 16** are unused by the matrix and free for the TrackPoint.

### Header → nRF pin resolution (from the built DTS `gpio-map`)

```
0x9  → &gpio1 0x6   (P1.06)   → RST   → rst-gpios
0xa  → &gpio0 0x9   (P0.09)   → SDA   → sda-gpios
0x10 → &gpio0 0xa   (P0.10)   → SCL   → scl-gpios
```

---

## The NFC / UICR caveat (important)

SCL and SDA land on **P0.09 and P0.10, which are the nRF52840 NFC antenna pins**.
Out of the box those pins are in **NFC mode**, where GPIO does not work. The
firmware must clear the NFC protection in the chip's **UICR** (User Information
Configuration Registers):

```dts
&uicr { nfct-pins-as-gpios; };
```

- This is the currently supported mechanism. The old
  `CONFIG_NFCT_PINS_AS_GPIOS` Kconfig is **deprecated** in Zephyr.
- The write is **one-time and permanent**: on first boot the firmware clears the
  NFC bit in UICR, and that value survives reboots and reflashing. It is only
  reverted by a full UICR/chip erase (e.g. `nrfjprog --eraseuicr`).
- Harmless on a keyboard (no NFC antenna is used) and a **no-op** if the pins are
  already in GPIO mode.
- This is a one-line change that only affects the **right** MCU.

> The left half also uses P0.10 (as a matrix column) without this property and
> works today, meaning its UICR is already cleared. It is intentionally left
> untouched. If the left column ever misbehaves after a chip swap, add the same
> one-liner to `config/corne_left.overlay`.

---

## Files

| File | Purpose |
|------|---------|
| `config/west.yml` | Adds the `badjeff` remote and pins the driver module (`kb_zmk_ps2_mouse_trackpoint_driver` @ `7ab7846a`). |
| `config/tp_split.dtsi` | Shared `zmk,input-split` node (`tpoint0_split`) included by both halves. |
| `config/corne_left.overlay` | Includes `tp_split.dtsi` only (central proxy; no device). |
| `config/corne_right.overlay` | PS/2 pins, UART, pinctrl, `uart_ps2`, `tpoint0`, IRQ priority overrides, `&uicr { nfct-pins-as-gpios; }`, and `device = <&tpoint0>`. |
| `config/corne_right.conf` | `CONFIG_UART_INTERRUPT_DRIVEN=y`, `CONFIG_PS2_UART_WRITE_MODE_BLOCKING=y`. |
| `config/mouse.dtsi` | Adds `tpoint0_input_listener` bound to `&tpoint0_split`; pointing/scroll tuning. |

---

## How the split wiring works

The nRF52 UART **cannot** generate PS/2 framing, so the driver bit-bangs the PS/2
protocol. During normal operation the UART RX line is muxed onto the SDA pin to
receive; for writes, pinctrl moves **both** UART pins onto unexposed pads
(P0.27/P0.28) so the SCL/SDA GPIOs are free to drive.

Node chain (verified in `firmware/zephyr_right.dts`):

```
uart_ps2  (uart-ps2, scl=&pro_micro 16, sda=&pro_micro 10)
   └── tpoint0  (zmk,input-mouse-ps2, ps2-device=<&uart_ps2>, rst=&pro_micro 9)
          └── tpoint0_split  (zmk,input-split, device=<&tpoint0>)   [peripheral side]
```

Central side (`firmware/zephyr_left.dts`):

```
tpoint0_split  (zmk,input-split, no device)                        [proxy]
   └── tpoint0_input_listener  (zmk,input-listener, device=<&tpoint0_split>)
```

IRQ priorities are overridden on the right half so PS/2 events are serviced
within the 30–50 µs window (gpiote raised to priority 0; everything else demoted
to 3).

---

## Build & flash

```bash
./build-in-docker.sh
```

Produces:

- `firmware/corne_left.uf2`  (central)
- `firmware/corne_right.uf2` (peripheral, has the TrackPoint)
- `firmware/zephyr_left.dts`, `firmware/zephyr_right.dts`

Flash both halves as usual (double-tap reset → drag the `.uf2`). The **first**
boot of `corne_right.uf2` performs the one-time UICR write.

## Configuration notes

- `CONFIG_ZMK_MOUSE` is **deprecated**; the real symbol is `CONFIG_ZMK_POINTING`.
  Seeing `# CONFIG_ZMK_MOUSE is not set` on the left is expected and benign.
- Pointer behavior (speed, scroll, layer-scoped warp/precision) is tuned in
  `config/mouse.dtsi` for a 3840×2160 display.

## Verification status

Confirmed from the built artifacts:

- Right `.config`: `ZMK_INPUT_MOUSE_PS2=y`, `PS2_UART=y`,
  `PS2_UART_WRITE_MODE_BLOCKING=y`, `UART_INTERRUPT_DRIVEN=y`, `ZMK_POINTING=y`,
  `ZMK_INPUT_SPLIT=y`.
- Left `.config`: `ZMK_INPUT_LISTENER=y`, `ZMK_INPUT_SPLIT=y`, `ZMK_POINTING=y`.
- `nfct-pins-as-gpios;` present in `firmware/zephyr_right.dts`.
- Full node chain present on both halves (see above).

**Not verified:** on-hardware behavior — first flash is the real test.
