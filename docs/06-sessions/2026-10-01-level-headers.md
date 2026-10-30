---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Level headers (WL3-024)

## Outcomes

- WL3-024 is done. `tools/wl3pc/extract/level_headers.py` decodes all `$c9`
  levels, 119 room lists, and 2010 room headers by the rules in `LoadRoom`,
  with bounds checks on every index a header passes on
  ([level headers](../02-research/level-headers.md)).
- **Out of the Woods, day 1 starts in `ROOM_001`**, which uses block
  function table `$00`. This answers the WL3-011 and WL3-013 question of
  which room is "first".
- The bank-group rule (`$30` below `THE_GRASSLANDS_NIGHT_1`, `$31` from it)
  is confirmed independently: every list label is named after its file
  offset.
- `make extract` now also writes `level_headers.json` (SHA-256
  `902096cc…47ac`, unchanged on re-run) with a new schema,
  `schemas/level-headers.v1.schema.json`. `load_sym` gained an optional
  `include_local` flag for the local `.room_NN` labels.
- A note correction made during the work: the `LoadRoom` limit arithmetic
  maps a wrapped `$00` result (not a zero limit) to `$ff`, and only for the
  lower Y and right X limits.

## Tests

Observed passing on the host: `make test` (90 Python passed, 7 ROM tests
deselected; Godot import OK, 19 passed), `make test-rom` (7 passed),
`make extract` (re-run unchanged), `make docs-check` (0 errors, 0 warnings),
`make repo-check` before the commit, and a one-off schema validation of the
real output. Three deliberate mutations failed the new tests and were then
reverted: using one bank for both groups, swapping the nibble order, and
removing the header-inside-list guard. `make export-linux` and
`make verify-clean` were skipped: the runtime did not change. The ROM's
SHA-256 was `b625ed03…7406` before and after.

## Blockers and gaps

- That list entries other than 0 are keyed by a transition's source section
  is an interpretation. It needs the door-transition code or an oracle
  capture (WL3-014).
- The units of the camera limits derived in `LoadRoom` are unknown.

## Next action

WL3-011: list the distinct handlers in block function table `$00` and read
each one in `src/engine/level/block_functions.asm`.
