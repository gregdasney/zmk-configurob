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
| **SDA** (data)    | 1 (**D1**)           | **P0.06**    | high-frequency pin — ideal for PS/2 |
| **SCL** (clock)   | 0 (**D0**)           | **P0.08**    | high-frequency pin — ideal for PS/2 |
| **RST** (reset)   | 9 (**D9**)           | **P1.06**    | plain GPIO |

Internal UART pins used by the driver (not exposed to the TrackPoint):

| Purpose | nRF52840 pin |
|---------|:------------:|
| UART TX (parked) | P0.27 |
| UART RX (parked) | P0.28 |

### Why these pins
The Corne right-half key matrix uses:

- **rows:** header pins 4, 5, 6, 7
- **cols:** header pins 14, 15, 18, 19, 20, 21

So header pins **0, 1, 9** are unused by the matrix and free for the TrackPoint.
D0 and D1 are additionally the nice!nano's high-frequency pins, which the driver
recommends for the clock/data lines. D9 is one of the driver's recommended reset
pins (the others being D8, D10, D16).

> Note: the driver's example ships an "alt pins" config that uses **D1 = SCL,
> D0 = SDA** (the opposite of this build). This config follows the physical
> wiring here: **SDA = D1, SCL = D0**.

### Header → nRF pin resolution (from the built DTS `gpio-map`)

```
0x0 → &gpio0 0x8   (P0.08)   → SCL   → scl-gpios
0x1 → &gpio0 0x6   (P0.06)   → SDA   → sda-gpios
0x9 → &gpio1 0x6   (P1.06)   → RST   → rst-gpios
```

---

## Power / voltage

The TrackPoint's clock/data lines are **open-drain, pulled up to the module's
VCC**, so the idle signal level equals its supply voltage. The nice!nano is a
**3.3 V** part and its GPIOs are **not 5 V-tolerant**, so:

- Power the TrackPoint **VCC from the nice!nano 3.3 V (VCC) pin**, and pull the
  data/clock lines up to **3.3 V**.
- **Do not** run the TrackPoint (or its pull-ups) off 5 V/VBUS — that would push
  SCL/SDA to ~5 V and can damage the nRF52840.

Classic IBM/Lenovo TrackPoint modules are widely run at 3.3 V and work fine there.

---

## Files

| File | Purpose |
|------|---------|
| `config/west.yml` | Adds the `badjeff` remote and pins the driver module (`kb_zmk_ps2_mouse_trackpoint_driver` @ `7ab7846a`). |
| `config/tp_split.dtsi` | Shared `zmk,input-split` node (`tpoint0_split`) included by both halves. |
| `config/corne_left.overlay` | Includes `tp_split.dtsi` only (central proxy; no device). |
| `config/corne_right.overlay` | PS/2 pins, UART, pinctrl, `uart_ps2`, `tpoint0`, IRQ priority overrides, and `device = <&tpoint0>`. |
| `config/corne_right.conf` | `CONFIG_UART_INTERRUPT_DRIVEN=y`, `CONFIG_PS2_UART_WRITE_MODE_BLOCKING=y`. |
| `config/mouse.dtsi` | Adds `tpoint0_input_listener` bound to `&tpoint0_split`; pointing/scroll tuning. |

---

## How the split wiring works

The nRF52 UART **cannot** generate PS/2 framing, so the driver bit-bangs the PS/2
protocol. During normal operation the UART RX line is muxed onto the SDA pin to
receive; for writes, pinctrl moves **both** UART pins onto unexposed pads
(P0.27/P0.28) so the SCL/SDA GPIOs are free to drive. ("Parking" the UART = moving
its pins to unused pads so it can't interfere with the bit-banged lines.)

Node chain (verified in `firmware/zephyr_right.dts`):

```
uart_ps2  (uart-ps2, sda=&pro_micro 1 / P0.06, scl=&pro_micro 0 / P0.08)
   └── tpoint0  (zmk,input-mouse-ps2, ps2-device=<&uart_ps2>, rst=&pro_micro 9 / P1.06)
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

Flash both halves as usual (double-tap reset → drag the `.uf2`).

## Configuration notes

- `CONFIG_ZMK_MOUSE` is **deprecated**; the real symbol is `CONFIG_ZMK_POINTING`.
  Seeing `# CONFIG_ZMK_MOUSE is not set` on the left is expected and benign.
- Pointer behavior (speed, scroll, layer-scoped warp/precision) is tuned in
  `config/mouse.dtsi` for a 3840×2160 display.
- No special UICR/NFC handling is needed: the pins used here (P0.06, P0.08,
  P1.06) are not the nRF52840 NFC pins.

## Verification status

Confirmed from the built artifacts:

- Right `.config`: `ZMK_INPUT_MOUSE_PS2=y`, `PS2_UART=y`,
  `PS2_UART_WRITE_MODE_BLOCKING=y`, `UART_INTERRUPT_DRIVEN=y`, `ZMK_POINTING=y`,
  `ZMK_INPUT_SPLIT=y`.
- Left `.config`: `ZMK_INPUT_LISTENER=y`, `ZMK_INPUT_SPLIT=y`, `ZMK_POINTING=y`.
- Right `zephyr_right.dts`: `scl-gpios` → P0.08, `sda-gpios` → P0.06, `rst-gpios`
  → P1.06, UART RX pinctrl → P0.06.
- Full node chain present on both halves (see above).

**Not verified:** on-hardware behavior — first flash is the real test.
