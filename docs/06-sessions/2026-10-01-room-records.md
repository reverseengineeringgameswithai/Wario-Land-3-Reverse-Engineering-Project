---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Room records (WL3-010)

## Outcomes

- WL3-010 is done. `tools/wl3pc/extract/rooms.py` decodes all `NUM_ROOMS`
  entries of `RoomBlockAndGfxData`: 154 records plus the `ROOM_000` reset
  sentinel. It resolves each room's function table and its five graphics
  sources by the bank rules in `LoadRoomGfx` and the home loaders
  ([room records](../02-research/room-records.md)).
- The `index / 6` hypothesis from the
  [first investigation](../02-research/first-investigation.md) is confirmed
  from the code. `wc0d0` carries the function-table bank into
  `LoadRoomTileMap`, so the function-table byte selects the bank for both the
  block tiles and the tile map.
- `tools/wl3pc/extract/rle.py` models `Decompress`, including its 256-byte
  literal quirk (unused by this ROM). Every tile map decompresses to `$200`
  bytes.
- `make extract` now also writes `local/content/wl3-original/room_records.json`
  (SHA-256 `f4a98d51…223a`, unchanged on re-run) with a new schema,
  `schemas/room-records.v1.schema.json`.
- New task WL3-024 (level and room headers), because WL3-011 needs to know
  which room a level loads first.

## Tests

Observed passing on the host: `make doctor`, `make test` (74 Python passed,
5 ROM tests deselected; Godot import OK, 19 passed), `make test-rom` (5
passed), `make extract` (re-run unchanged), `make smoke`, `make docs-check`
(26 files, 0 errors), `make repo-check` before each commit, and a one-off
schema validation of the real output. `make export-linux` and
`make verify-clean` were skipped: the runtime did not change. Two deliberate mutations failed the new tests and were then
reverted: taking the tile-map bank from the wrong byte, and dropping the
`$80` literal quirk. The ROM's SHA-256 was `b625ed03…7406` before and after.

## Blockers and gaps

- The meaning of the decompressed tile-map bytes is a hypothesis (WL3-018).
- No GUI, controller, or oracle work this session (WL3-014 and WL3-021 are
  unchanged).

## Next action

WL3-024: decode the per-level lists that `LoadRoom` reads after
`LevelHeaders` (`30:4319`), starting with `LevelHeaders_c0d1f`
(Out of the Woods, day 1).
