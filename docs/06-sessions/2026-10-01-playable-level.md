---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Extracted level playable with the ported Wario (WL3-033)

## Outcomes

- The owner asked to continue with M2. WL3-033 is done:
  `make run LEVEL=0` plays Out of the Woods, day 1 from the extracted level
  with the ported Wario, drawn as boxes by handler kind.
- **Level start ported** (`WarioSim.start_level`, from
  `StartRoom_FromLevelStart` and `SetWarioPositionToSpawn`); the level
  collision file now carries the start (spawn block (3, 46), Wario at
  (56, 752)). Against the oracle's variables before the first Wario update
  of the owner's movie, all 38 compared variables are identical
  ([wario movement](../02-research/wario-movement.md), item 8).
- **Frame loop** (`LevelRunner`): the joypad byte and pressed bits as
  `UpdateJoypad` builds them, then the update, then the frame counter.
  `make smoke-level` runs the walk input from level 0's own start and
  matches all 300 oracle positions; the exported binary does the same
  outside the checkout.
- **Camera:** a stand-in that follows Wario inside the room's limits,
  announced as an approximation when the window starts; porting the real
  one is WL3-036.
- **Keys** now match the TAS editor (X = A, Z = B).
- `--screenshot` lets the window save its own view after scripted input;
  three views were saved and looked at (the trunk, the floor, and the
  breakable stair, with Wario stopping at the first block).

## Tests

Observed passing on the host: `make test` (182 Python passed; Godot import
OK, 35 passed), `make smoke`, `make smoke-extracted`, `make smoke-level`,
`make wario-parity` (2022 of 2022, level start identical), and
`make export-linux` (including level 0 outside the checkout).
`make docs-check` and `make repo-check` passed before the commit.

## Blockers and gaps

- No desktop check of keyboard, controller, or resizing in the game window
  (WL3-021); only scripted input and saved screenshots so far.
- The camera, room graphics, objects, transitions, and Wario's other
  states are not ported; reaching an unported routine shows its name.

## Next action

WL3-036: port the level camera and check `wCameraSCX`/`wCameraSCY` against
the owner's movie.
