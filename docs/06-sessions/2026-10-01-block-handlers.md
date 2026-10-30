---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Block handlers for the first room (WL3-011)

## Outcomes

- WL3-011 is done for the first room. All 31 handlers in block function
  table `$00`, the table `ROOM_001` uses, were read in
  `src/engine/level/block_functions.asm`. That includes how they respond to
  each of the eight collision probes and to Wario's state, power-ups, and
  transformations ([block handlers](../02-research/block-handlers.md)).
- New tracked mapping `tools/wl3pc/data/block_handler_materials.v1.json`
  (schema `block-handler-materials.v1`): handler ID → material + flags +
  evidence. It is project-original and contains no ROM bytes.
- New step `tools/wl3pc/extract/block_materials.py` (in `make extract`)
  writes `local/content/wl3-original/block_materials.json` (SHA-256
  `fe706b93…c82e`, unchanged on re-run). Table `$00` is fully mapped; the
  other 107 handlers map to `unknown`.
- New shared fixture `invalid-packs/unknown-material`: both loaders reject a
  room that uses `unknown`. A control copy using `platform` loads in Python,
  so the rejection is for the material and nothing else.
- New task WL3-025 (level block maps), which WL3-013 needs to place the
  materials.
- Two corrections to my own draft notes, made before committing:
  `wBlockFuncWarioFlag` is also set around `UpdateWarioStates` (not only in
  three wrappers), and the two slope surfaces are not mirror images.

## Tests

Observed passing on the host: `make test` (105 Python passed, 9 ROM tests
deselected; Godot import OK, 19 passed), `make test-rom` (9 passed),
`make extract` (re-run unchanged), `make docs-check` (0 errors, 0 warnings),
`make repo-check` before the commit, and schema validation of the tracked
mapping and the real output. A mutation that maps unmapped handlers to
`empty` failed the tests. While checking it, a stale `.pyc` (the mutant and
the original had the same size and modification second) briefly made the
restored code look broken; clearing `__pycache__` fixed it, and the full
suite was re-run from fresh bytecode. `make export-linux` and
`make verify-clean` were skipped: the runtime code did not change. The ROM's
SHA-256 was `b625ed03…7406` before and after.

## Blockers and gaps

- The runtime cannot yet use slopes, ladders, doors, or breakables, so
  `ROOM_001` cannot load as a playable room until those materials are
  implemented (WL3-013).
- The units of `hYPosLo` and the block size (16 px) remain hypotheses until
  WL3-012 or WL3-014.

## Next action

WL3-025: read `DecompressLevelBlockMap` (`src/home/load_level.asm`) and
decode `OutOfTheWoodsBlockMap` (`38:4000`).
