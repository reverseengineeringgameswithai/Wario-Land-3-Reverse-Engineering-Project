---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Level block maps (WL3-025)

## Outcomes

- WL3-025 is done. `tools/wl3pc/extract/level_maps.py` decodes
  `LevelBlockAndObjectMaps` and expands all 35 distinct block maps the way
  `DecompressLevelBlockMap` does, reusing the `Decompress` model
  ([level block maps](../02-research/level-block-maps.md)).
- Every map is 48 rows of 160 blocks. Every stream ends exactly at the next
  reference label. `TheWestCraterBlockMap` is one block short, and the
  decoder reports this instead of filling the cell.
- `ROOM_001`'s region uses only `empty`, `solid`, and `platform`, plus
  breakable and room-transition blocks. This assumes the header limits are
  section ranges. So the collision half of WL3-013 needs no new runtime
  material, only a labelled approximation for breakables and transitions.
- `make extract` now also writes `level_block_maps.json` (SHA-256
  `c588a414…d070`, unchanged on re-run) with a new schema,
  `schemas/level-block-maps.v1.schema.json`.
- Found by a failing test and fixed before committing: my synthetic fixture
  overlapped the pointer table. Fixing it showed that a data bank of `$00`
  gave a misleading error; it is now refused explicitly (MBC5 could map bank
  0 there, and no level does).

## Tests

Observed passing on the host: `make test` (119 Python passed, 12 ROM tests
deselected; Godot import OK, 19 passed), `make test-rom` (12 passed),
`make extract` (re-run unchanged), `make docs-check`, `make repo-check`
before the commit, and schema validation of the real output. A mutation that
takes the data bank from the pointer table instead of the record failed 7
tests and was reverted, with bytecode caches cleared. Before this task,
`make verify-clean` passed on `33334db`: 105 Python tests, content, docs,
and repo checks, 19 Godot tests, and the smoke run in a clone with no ROM,
`external/`, or `local/`. `make export-linux` was skipped: the runtime did
not change. The ROM's SHA-256 was `b625ed03…7406` before and after.

## Blockers and gaps

- WL3-013 needs a decision on how an `original-extracted` pack labels
  approximations. The `room.v1` format maps a character to a material and
  has no field for "breakable, treated as solid" or "transition, not
  implemented".
- The object map is not decoded.

## Next action

WL3-013: decide how the room format records labelled approximations, then
build `ROOM_001`'s collision rows from `level_block_maps.json` and
`block_materials.json`.
