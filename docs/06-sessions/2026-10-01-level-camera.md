---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Level camera ported (WL3-036)

## Outcomes

- WL3-036 is done: the level camera is ported by translation into
  `LevelSim` (`game/scripts/sim/wario/level_sim.gd`), from `camera.asm`,
  `UpdateLevel`'s camera code, `SetInitialCameraScroll`,
  `ApplyInitialCameraScroll`, and `LoadRoom`'s camera variables
  ([level camera](../02-research/level-camera.md)).
- Wario traces gained 22 camera variables and every camera run through
  hooks (on entry to `ClearUnusedVirtualOAM`, which precedes the camera on
  all three paths, and at `UpdateLevel.asm_8229`).
- Two couplings to the frame loop are modelled: `LoadWarioGfx` raises
  `wIsDMATransferPending` (a floor transition waits for it) and V-Blank
  clears it; `Func_8ed9` clears one horizontal and one vertical edge flag a
  frame.
- Results: 5802 of 5802 camera runs of the owner's movie identical in four
  camera modes; the native level start equals the oracle on 54 variables;
  whole frames run alone match the walk capture (300) and the movie up to
  the first attack; `make smoke-level` matches Wario and the camera on all
  300 frames from level 0's own start. The window draws from the camera.
- Two bugs in my first harness were caught and fixed: the between-frames
  check used a mid-frame snapshot, and the native frame cleared edge flags
  before the comparison point.

## Tests

Observed passing on the host: `make test` (Python and Godot: 42 passed),
`make smoke-level`, `make wario-parity` (step and run on both traces), and
`make export-linux`. `make docs-check` and `make repo-check` passed before
the commit.

## Blockers and gaps

- The Hidden Figure camera and the ground-shake offset are not ported.
- A floor transition has not yet been compared in a whole-frame run.

## Next action

WL3-018: decode `ROOM_001`'s tiles and CGB palettes and draw them at this
camera.
