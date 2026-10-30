---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, content, collision]
---
# First room as an extracted pack

**Question:** can Out of the Woods, day 1's first room be assembled from
decoded original data into a pack that the native runtime and the Linux
export load, with every difference from the original stated?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build). Task: WL3-013.
Decision: [ADR-0002](../03-architecture/adr-0002-labelled-approximations.md).
Inputs: [level headers](level-headers.md), [room records](room-records.md),
[block handlers](block-handlers.md), [level block maps](level-block-maps.md).

## Verified observations

1. **Object map.** `DecompressLevelObjectMap` (`src/home/decompress_level_data.asm`)
   uses the same control bytes as the block map. It writes
   `LEVEL_WIDTH / 2` = 80 bytes per row from offset `$b0` of each 256-byte
   SRAM row page, checking for the row end before each increment. `Func_cc0`
   (`src/home/object_pos.asm`) addresses the object byte of block `x` as
   `$b0 + x / 2` and returns `b = 1` for an even block ("object parity"). The
   spawn search below reads the high nibble first, so the high nibble is the
   even block. All 35 object maps decode to 48 rows. 32 streams end at the
   next label; the other 3 are the last in their banks and are followed only
   by `$ff` padding.
2. **Spawn.** `SetWarioPositionToSpawn` (`02:4a41`,
   `src/engine/level/start_room.asm`) starts at the top-left block of the
   header's spawn section. `Func_cc0` gives the row as `y >> 4` and the
   object byte as `x >> 5`, which confirms 16-pixel blocks. It reads 8 object
   bytes (16 blocks) per row, high nibble first, row by row downward, until a
   nibble is `$f`. `Func_cf8` then sets `wWarioPos` to the block's centre
   column (`x × 16 + 8`) and bottom edge (`y × 16 + 16`). If the camera mode
   is `CAM_TRANSITIONS` or higher, and the start is not from a saved level,
   it calls `UpdateFloor`.
3. **Spawn check over the ROM.** For every non-NULL entry in every level's
   room list, 3641 in all, the search from the header's spawn section was
   compared with the header's limits. 3617 find a marker in the spawn
   section itself and inside the limits. The other 24 all come from Beneath
   the Waves (levels `$50`–`$57`, lists `30:716f`–`30:760b`, entry 2) and The
   Colossal Hole (`$a8`–`$af`, lists `31:5ca0`–`31:5ed4`, entries 6 and 23):
   8 find the marker in a lower section, 8 outside the limits, and 8 find
   none.
4. **Out of the Woods, day 1.** The start header (`30:4d5b`) gives `ROOM_001`,
   spawn section (0, 2), and limits of sections x 0–1, y 2. The spawn marker
   is block (3, 46), so `wWarioPos` = (56, 752) px. In the room, that block
   (3, 14) is empty and the block below it is solid, so the spawn point is
   exactly on the floor. This supports both the section-range reading of the
   limits and the spawn decoding.
5. **The pack** (`make room-pack`, `tools/wl3pc/extract/room_pack.py`) is
   `local/content/packs/wl3-level-00-room-001/`. It is a 32 × 16 block room
   from block map rows 32–47 and columns 0–31, through table `$00`. Its
   legend has 12 characters: `.`, `#`, and 10 labelled stand-ins. The pack
   lists 12 approximations: 1 platform that Zombie Wario passes through; 1
   room-transition block (`$44`) as empty; 8 breakable kinds (cracked,
   non-cracked, and enemy blocks, each with its replacement block) as solid;
   the start; and the movement. Its files are read-only. The license text
   and `provenance.json` carry the ROM-derived marker, and it is valid against
   `content-pack.v2`.
6. **Runtime and export.** `make smoke-extracted` runs the Godot selftest
   through `--content-dir`. The runtime reports `origin`
   `original-extracted` and exactly the pack's 12 approximation subjects.
   `make export-linux` runs the exported binary from a temporary directory
   outside the checkout against the same pack, with the same result. The
   exported `.pck` holds no ROM-derived marker, ROM image, or ROM fragment.

## Interpretation

- The collision layout of the first room now comes from the original data.
  The **physics does not**: walking, jumping, and collision resolution are
  still the provisional prototype, so a run in this room says nothing about
  parity.
- The start box is a translation: the prototype's 12 × 24 body box is placed
  with its bottom centre on `wWarioPos`. Whether `wWarioPos` is Wario's feet
  centre is a hypothesis (collision boxes are offsets from it), so the pack
  labels the start.

## Unknowns

- What `UpdateFloor` changes after the spawn.
- How the 24 exceptional entries place Wario. They may use other transition
  types, such as pipes, that position him differently.
- What object nibbles other than `$f` mean (the room's object group,
  WL3-018 and later object work).

## Tests

- Synthetic: `tests/test_room_pack.py` covers exact and labelled cells, bit 7
  ignored, a refused unimplemented material, a refused unmapped handler, a
  refused spawn outside the room, shared characters, start conversion, the
  read-only, valid, deterministic output, and unknown-ROM refusal.
  `tests/test_level_maps.py` covers the object maps and the scan order of
  the spawn search.
- Shared content fixtures: `valid-packs/approximations` and six invalid
  v2 packs, accepted or rejected identically by Python and Godot.
- Real ROM: object maps, the stream ends, the first spawn, and the pack
  (`tests/test_rom_integration.py`).

## Next experiment

WL3-012: replace the synthetic movement with the decoded walking and
jumping tables, so that a run in this room starts to mean something.
