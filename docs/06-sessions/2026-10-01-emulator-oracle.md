---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Emulator oracle (WL3-014, WL3-015)

## Outcomes

- The owner asked whether PyBoy 2.7 allows deterministic, TAS-style input,
  and to start WL3-014. Answer: per-frame input between `tick()` calls, full
  save states, and deterministic for a fixed version, start, and input. The
  `pyboy` command and its `--record-input` plugin are unsuitable here: given
  a ROM path they write `.ram`, `.state`, and `.replay` files next to the
  ROM. This is documented in the [emulator oracle](../02-research/emulator-oracle.md)
  note.
- `tools/wl3pc/oracle.py` passes the ROM as bytes and never writes next to
  it. It provides:
  - a tracked route from power-on to Out of the Woods, day 1, built from a
    documented input policy, holding no ROM bytes, and replayed by
    `make oracle-check` to the same end state and full-memory digest;
  - captures of any `input-trace.v1` from the route (`make oracle-verify`
    runs two emulators and requires identical results);
  - an interactive recorder with pause and frame advance, and replay with
    checkpoint digests.
- WL3-014 acceptance is met: 300 frames of walking right, identical across
  two separate emulators, sample for sample and digest for digest.
- The running game confirms two static results: the decoded spawn point
  (56, 752) and the wall at column 6 of the extracted `ROOM_001`. It also
  gives the first walk ground truth for WL3-012.
- WL3-015 is done: `wGlobalCounter` advances once per frame during normal
  play. This covers that capture only.
- Found along the way: PyBoy 2.7.0 rejects banked slices that end at the
  region boundary (worked around), and the walk index cycles 12–15 in normal
  walking. The backlog's `$18`–`$1b` cycle is the table's own cap, and the
  WL3-012 task now says so.
- New task WL3-028 (second emulator for timing-sensitive checks).

## Tests

Observed passing on the host: `make test` (147 Python passed, 17 ROM tests
deselected; Godot import OK, 21 passed), `make test-rom` (17 passed,
including the 2 oracle tests through `/usr/bin/python3`), `make oracle-check`,
`make oracle-verify` (a re-run wrote a byte-identical capture), `make doctor`
(reports PyBoy 2.7.0), `make docs-check`, and `make repo-check` before the
commit. The recorder was run under SDL's dummy video driver: 150 ticks, then
replays from power-on and from the route matched every checkpoint, and a
tampered recording was rejected. A mutation that applies input after the
tick instead of before it failed the tests and was reverted. After every run,
`Original_ROM/` held only the ROM, with SHA-256 `b625ed03…7406`.

## Blockers and gaps

- The recorder's real keyboard input and window were not exercised: no
  window was opened on the owner's desktop.
- PyBoy is not cycle-exact; timing-sensitive behaviour needs WL3-028.

## Next action

WL3-012: find the walking state's index cap, then make the native walk
reproduce `local/captures/ootw-day1-start--walk-right-300.capture.json`
tick for tick.
