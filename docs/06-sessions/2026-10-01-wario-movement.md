---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Wario's movement ported and checked update by update (WL3-012)

## Outcomes

- The owner asked to take the project forward with their Out of the Woods
  movie as ground truth. A state at the movie's end (the map after the
  clear) was stored first: `7b2e6ea4…`, rebuilt from power-on.
- **Tables:** `tools/wl3pc/extract/wario_movement.py` decodes
  `WalkVelTable`, the five jump tables, and twelve Wario framesets
  (`make extract`); `level_collision.py` writes level 0's block map and each
  room's 128 handler IDs.
- **Oracle Wario traces** (`make wario-trace`): 65 variables a frame, the
  live block map, and every Wario update through hooks on
  `UpdateWarioStates` and `UpdateObjects`. Hooks were needed: after an
  attack frame, the next frame's `UpdateJoypad` ran before PyBoy's frame
  boundary, so per-frame samples can hold the next frame's input.
- **The port** (`game/scripts/sim/wario/`,
  [ADR-0003](../03-architecture/adr-0003-wario-port-by-translation.md)):
  `UpdateWarioStates` for idling, walking, turning, airborne, and landing,
  the four collision checks, `ProcessBlock`, and the handlers OotW uses,
  translated with the original variable names. Unported paths are
  reported by routine name.
- **Parity** (`make wario-parity`): on the owner's movie, 2022 of 5676 Wario
  updates are in ported states and reach no unported routine, and all 2022
  match on 38 variables. The port alone reproduces the 300-update walk
  capture. The first frame-based check showed 13 differences, all explained
  (11 object interactions, 2 joypad timing); none remain with hooked updates
  ([wario movement](../02-research/wario-movement.md)).

## Tests

Observed passing on the host: `make test` (182 Python passed, 23 ROM tests
deselected; Godot import OK, 32 passed), `make test-rom` (23 passed,
including the native walk run), `make wario-parity` on the owner's movie
and `MODE=run` on the walk capture, and `make extract`. `make docs-check`
and `make repo-check` passed before the commit.

## Blockers and gaps

- The game window still runs the prototype `PlayerSim` (WL3-033).
- 40 Wario states occur in the movie; 4 are ported and observed. Hard
  landing is ported but has no oracle example yet.
- Right slopes, breaking, entering doors, and starting transitions are
  translated but not yet exercised by a matched update.
- `BreakBlock`'s coin roll reads `rDIV`; no native random source yet.

## Next action

WL3-033 (run an extracted level in the window with `WarioSim`) or
WL3-034 (port attacking, 339 updates in the movie), checked with
`make wario-parity`.
