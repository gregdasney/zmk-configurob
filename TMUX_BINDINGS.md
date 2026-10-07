# Tmux Bindings (Z-held MACRO layer)

Holding `Z` (left pinky home-row key) activates the `MACRO` layer silently — it emits
nothing by itself. Tapping one of the action keys below while `Z` is held fires a macro
that taps `Ctrl-b` (tmux's default prefix), releases it, then taps the follow-up key —
`Ctrl-b` is never left "armed" on its own.

These macros send real keystrokes, so they work in any terminal/OS tmux runs in (macOS,
Linux, SSH) using tmux's own default bindings. The only required `tmux.conf` addition is
`bind S new-session` (tmux has no default single-key binding for creating a new session).

## Full table

| You press | Result |
|---|---|
| Z + W | Dropdown terminal (unchanged, unrelated to tmux — sends F20) |
| Z + E | Pane up |
| Z + S | Pane left |
| Z + D | Pane down |
| Z + F | Pane right |
| Z + R | Split side-by-side (`Ctrl-b %`) |
| Z + T | Split stacked, horizontal divider (`Ctrl-b "`) |
| Z + I | Resize pane up (`Ctrl-b Alt+Up`) |
| Z + J | Resize pane left (`Ctrl-b Alt+Left`) |
| Z + K | Resize pane down (`Ctrl-b Alt+Down`) |
| Z + L | Resize pane right (`Ctrl-b Alt+Right`) |
| Z + M | New window (`Ctrl-b c`) |
| Z + , | Previous window (`Ctrl-b p`) |
| Z + . | Next window (`Ctrl-b n`) |
| Z + / | Window picker (`Ctrl-b w`) |
| Z + Y | New session (`Ctrl-b Shift+S` — requires `tmux.conf`: `bind S new-session`) |
| Z + U | Previous session (`Ctrl-b (`) |
| Z + O | Next session (`Ctrl-b )`) |
| Z + P | Session picker (`Ctrl-b s`) |
| Z + ; | Rename window (`Ctrl-b ,`) |
| Z + ' | Rename session (`Ctrl-b $`) |
| Z + Del | Kill pane (`Ctrl-b x` — tmux's own y/n confirmation still applies) |
| Z + H | Hyper+2 (pre-existing, unrelated to tmux) |
| Z + N | Hyper+Q (pre-existing, unrelated to tmux) |
| Z + X, C, V, \ | Free / unassigned |

## Notes

- Resize uses `Alt+Arrow`, not `Ctrl+Arrow` — macOS intercepts `Ctrl+Arrow` system-wide for
  Mission Control/Spaces before it ever reaches the terminal.
- Physical key position is independent of the character a macro actually sends — e.g. the
  physical `,` / `.` / `/` keys send `p` / `n` / `w`, not their own literal characters.
- Pane titles are hidden by default in tmux; `tmux.conf` also sets:
  ```tmux
  set -g pane-border-status top
  set -g pane-border-format "#{pane_index}: #{pane_title}"
  ```
