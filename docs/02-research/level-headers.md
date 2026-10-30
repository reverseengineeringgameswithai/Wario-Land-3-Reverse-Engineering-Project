---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, content]
---
# Level headers and room headers

**Question:** which room does each level start in, and what does a room
header set before the room's graphics load?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build); symbols from the
local reference build. Task: WL3-024. Room records are described in
[room records](room-records.md).

## Verified observations

1. **Level table.** `LoadRoom` (`00:285c`, offset `0x285C`,
   `src/home/load_room.asm`) maps `BANK(LevelHeaders)` = `$30`, doubles
   `wLevel`, and reads `LevelHeaders` (`30:4319`, offset `0xC0319`). It
   resets via `debug_assert_not $ff` when the pointer's high byte is `$ff`.
   Levels run from `OUT_OF_THE_WOODS_DAY_1` (`$00`, eight per level: days 1–4
   and nights 1–4) to `THE_TEMPLE` (`$c8`), so the table has `$c9` entries
   (`src/constants/level_constants.asm`); 13 `dw NULL` follow.
2. **Bank groups.** `LoadRoom` then maps bank `$30` when `wLevel` is below
   `THE_GRASSLANDS_NIGHT_1` (`$64`) and bank `$31` otherwise, and reads the
   list from that bank. In the ROM, level `$63` uses `30:7c17` and level
   `$64` uses `31:4000` (offset `0xC4000`), the first list in bank `$31`.
   All 119 list labels are named after their file offsets
   (`LevelHeaders_c0d1f` is at offset `0xC0D1F`), which confirms the rule.
3. **Lists.** `LoadRoom` adds `wLevelRoomID * 2` to the list pointer, reads
   a header pointer, and resets again on a `$ff` high byte. Every list in
   the disassembly has 30 entries. No constant states this, but in the ROM
   every list's lowest header pointer is exactly the list start plus 60
   bytes, which is consistent with 30 two-byte entries followed directly by
   the headers. Lists have 1 to 26 non-NULL entries.
4. **Room header format.** Eight bytes, read in order by `LoadRoom` and
   packed by the `room_header` macro (`src/macros/data.asm`, `dn` = high
   nibble first):

   | Byte | Stored in | Notes |
   | --- | --- | --- |
   | 0 | `wWarioSpawnPos` | `SetWarioPositionToSpawn` (`02:4a41`) uses the high nibble as `hYPosHi` and the low nibble as `hXPosHi` |
   | 1 | `wRoomUpperYLimit` (high nibble), `wRoomLowerYLimit` (low nibble) | |
   | 2 | `wRoomLeftXLimit` (high nibble), `wRoomRightXLimit` (low nibble) | |
   | 3 | `wCameraConfigFlags` | flag names `CAM_*` in `level_constants.asm` |
   | 4 | `wObjectGroup` | `LoadObjectGroupData`; `< NUM_OBJECT_GROUPS` (`$92`) or the hidden-figure group `$f0` |
   | 5 | `wAnimatedTilesGroup` | `InitRoomAnimatedTiles`; 29 groups |
   | 6 | `wRoomPalCycle` | `InitRoomAnimatedPals`; 20 cycle pointers |
   | 7 | `wRoom` | then `farcall LoadRoomGfx` |

5. **First room.** `StartRoom_FromLevelStart` (`02:4747`,
   `src/engine/level/start_room.asm`) writes 0 to `wLevelRoomID` before it
   calls `LoadRoom`, unless `wceef & %00111100` is non-zero. The disassembly
   comments that case as "from saved level", which then uses
   `wTempLevelRoomID`. On a fresh start, the room a level starts in is
   therefore list entry 0.
6. **Transitions.** `StartRoom_FromTransition` computes `wLevelRoomID` with
   `GetNextLevelRoomID` (`02:4ec2`, `src/engine/level/scroll.asm`) as
   `XPosHi + 10 * YPosHi` of `wWarioPos`, after subtracting `$10` from the
   Y position. A teleport transition first sets the Y high byte to 1 and the
   X high byte to 0. Only then does it call `LoadRoom` and, afterwards,
   `SetWarioPositionToSpawn`.
7. **Decoded from the ROM** (`make extract`, decoder
   `tools/wl3pc/extract/level_headers.py`):
   - All `$c9` levels decode; none is a reset sentinel. They share 119
     distinct lists (59 in bank `$30`, 60 in `$31`), which reach 2010
     distinct headers.
   - **Out of the Woods, day 1 (level `$00`) starts in `ROOM_001`.** Its
     list is `30:4d1f` (`LevelHeaders_c0d1f`) and entry 0 is header `30:4d5b`
     (offset `0xC0D5B`): spawn y 2, x 0; Y limits 2–3; X limits 0–2; camera
     config `$18` (`CAM_TRANSITIONS | CAM_BORDER_RIGHT`); object group `$0a`;
     animated-tiles group 1; palette cycle 0. From the
     [room records](room-records.md), `ROOM_001` uses block function table
     `$00` at `32:40c4`.
   - No level's entry 0 is NULL, and no header names `ROOM_000`. Every
     header's other indices are inside their tables. 89 distinct start rooms
     are used across the 201 levels.
   - Rooms `$3f`, `$40`, and `$41` (63–65) are decoded room records that no
     header references.
   - Every list and header lands on a reference label. Each header lands on
     `<list>.room_NN`, where NN is the first entry that points at it. 43
     headers are shared by several entries of the same list (76 extra
     references), and none is shared between lists.
   - For all 2010 headers, the upper Y limit is below the lower one, the left
     X limit is below the right one, and the spawn lies inside both ranges
     (`upper ≤ y < lower`, `left ≤ x < right`). Spawn y is 0–2 and x 0–9; the
     limit ends reach 3 and 10.
   - The output `local/content/wl3-original/level_headers.json` is
     deterministic, SHA-256 `902096cc…47ac` when labelled with the local
     `.sym`, and valid against `schemas/level-headers.v1.schema.json`.

## Interpretation

- A level is a grid of 10 × 3 sections. With `LEVEL_WIDTH` = 160 blocks,
  one section is 16 blocks, i.e. one high byte of a pixel position if a block
  is 16 pixels. The spawn and limit nibbles are in section units, and the
  limits are half-open ranges `[upper, lower)` and `[left, right)`. The
  invariant over all 2010 headers supports this. That a block is 16 pixels
  is still a hypothesis (see the [first investigation](first-investigation.md)).
- For entries other than 0, the list index appears to be the section where a
  transition **starts**, and the header describes the **destination** room:
  the index is computed before `SetWarioPositionToSpawn` moves Wario. Only
  87 of the 1967 non-start entries lie inside their own header's limits,
  which fits this reading and rules out "the index is the room's own
  section".

- *Confirmed (WL3-027, [room transitions](room-transitions.md)):* Wario's
  position is still the source position when `StartRoom_FromTransition`
  runs. It moves him up 16 px, takes the entry `XPosHi + 10 * YPosHi`, then
  loads that header and moves him to its spawn. The oracle shows it (room 0
  to entry 21 from (497, 720)), and the port reproduces all five
  transitions of the owner's movie.
- *Confirmed (WL3-036, [level camera](level-camera.md)):* the limits bound
  the camera: `ScrollCamera*` clamp at `wRoom*Limit` in section units.

## Hypotheses

- `LoadRoom` also turns the limits into `wc0c4`–`wc0c7`:
  `limit * 16 + $a0` for the Y limits and `limit * 8 + $b0` for the X
  limits, modulo 256. For the lower Y limit (`wc0c4`) and the right X limit
  (`wc0c7`) only, a result of `$00` becomes `$ff`. A right limit of 10, which
  occurs in the ROM, wraps to `$00` and so becomes `$ff`. The units of these
  results are not yet known.

## Unknowns

- What uses rooms 63–65, if anything. Unreferenced data is not evidence of
  behaviour.
- The meaning of each camera configuration value beyond the `CAM_*` flag
  names.
- The "from saved level" path (`wceef`), which this decoder does not model.

## Tests

- Synthetic: `tests/test_level_headers.py` covers both bank groups, a
  high-byte-only `$ff00` NULL entry, shared lists and headers, a NULL start
  entry, nibble order, out-of-ROM and bank-crossing pointers, a header inside
  its list, rooms that are reset sentinels or out of range, out-of-range
  object, animated-tile, and palette-cycle indices, unknown-ROM refusal,
  exploratory marking, determinism, read-only output, and schema validity.
- Real ROM (optional, `make test-rom`): counts, the first room, list
  contiguity, the spawn invariant, and every list and header label, in
  `tests/test_rom_integration.py`.

## Next experiment

WL3-011: read the handlers used by block function table `$00` (`32:40c4`),
which `ROOM_001` loads, starting with the most frequent block IDs once the
level's block map is decoded.
