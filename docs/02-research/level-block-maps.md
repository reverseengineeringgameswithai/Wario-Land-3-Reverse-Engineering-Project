---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, content]
---
# Level block maps

**Question:** which block occupies each 16×16 cell of a level, and how is
the map stored and expanded?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build); symbols from the
local reference build. Task: WL3-025. Related:
[level headers](level-headers.md), [block handlers](block-handlers.md).

## Verified observations

1. **Table.** `LoadLevelBlockMapAndObjects` (`00:0e8a`, offset `0xE8A`,
   `src/home/load_level.asm`) maps `BANK(LevelBlockAndObjectMaps)` = `$30`
   and reads `LevelBlockAndObjectMaps[wLevel]` (`30:40be`, offset
   `0xC00BE`, `src/data/levels/level_maps.asm`). It jumps to
   `InvalidLevelData` (`jp Init`) when the pointer's high byte is `$ff`
   (`inc a / jr z`). The table has an entry for each level `$00`–`$c8`,
   followed by 13 `dw NULL`.
2. **Record.** Five bytes: `dab` block map (2-byte pointer, then bank), then
   `dw` object map. The loader stores the block-map pointer bytes swapped in
   `wCompressedLevelBlockMapPtr`, and `DecompressLevelBlockMap` reads them
   back swapped, so the record itself is little-endian. It reads the bank
   byte twice, once per map, so both maps live in the same bank.
3. **Expansion.** `DecompressLevelBlockMap` (`00:0ab5`,
   `src/home/decompress_level_data.asm`) returns at once when
   `wceef & $3c` is set (the same "from saved level" test as
   `StartRoom_FromLevelStart`). Otherwise it maps `BANK("SRAM1")` and writes
   from `sLevelBlockObjectMap` (`01:a000`). The control bytes match
   `Decompress` (`$00` ends; bit 7 clear repeats the next byte; bit 7 set
   copies `control & $7f` literal bytes, and `$80` copies 256). After each
   byte, when the low address byte reaches `LEVEL_WIDTH` (160) it moves to
   the start of the next 256-byte page. When it leaves `$bfff` it wraps to
   `$a000` in the next SRAM bank. So each row holds 160 block bytes, rows sit
   256 bytes apart, and an 8 KiB SRAM bank holds 32 rows. The cartridge has
   32 KiB of RAM (header code `$03`, 4 banks), so at most 96 rows fit from
   bank 1.
4. **Block IDs.** `ProcessBlock` turns the map byte into a table offset
   with `add a` and keeps only the low byte, so bit 7 never reaches the
   table index. The block function table index is `byte & $7f`. Breaking
   handlers keep bit 7 when they replace a block ([block handlers](block-handlers.md)).
5. **Decoded from the ROM** (`make extract`, decoder
   `tools/wl3pc/extract/level_maps.py`):
   - All `$c9` levels decode. They share 35 distinct block maps; all eight
     Out of the Woods versions (`$00`–`$07`) use `OutOfTheWoodsBlockMap`
     (`38:4000`, offset `0xE0000`).
   - Every map is 48 rows of 160 blocks (a 2560 × 768-pixel level if a
     block is 16 px), from 202 to 6877 compressed bytes. Every stream ends
     exactly where the next reference label starts. Every map and object
     map lands on a `…BlockMap` and `…ObjectMap` label.
   - **One map is a block short.** `TheWestCraterBlockMap` (`3d:5533`,
     offset `0xF5533`; levels `$58`–`$5f`) expands to 7679 bytes, so the
     last cell of row 47 is never written and keeps whatever SRAM held
     before. The decoder reports `incomplete_final_row` instead of guessing a
     value.
   - 1933 map bytes have bit 7 set, 76 of them in Out of the Woods.
   - The output `local/content/wl3-original/level_block_maps.json` is
     deterministic and valid against `schemas/level-block-maps.v2.schema.json`.
     Its SHA-256 was `c588a414…d070` in format 1 (block maps only) and is
     `2c4c2562…ffa0` in format 2, which adds the object maps
     ([first room pack](first-room-pack.md)).
6. **The first room's blocks.** If the header limits are section ranges (an
   interpretation, see [level headers](level-headers.md)), `ROOM_001` covers
   block rows 32–47 and columns 0–31: 512 cells and 53 distinct block IDs.
   Through table `$00` they are 355 `empty`, 151 `solid`, and 6 `platform`
   cells, with flags on 18 cracked, 9 non-cracked, and 4 enemy breakable
   blocks, 2 `room-transition` blocks, and the 6 zombie-passable platforms.
   There are no slopes, ladders, or doors. 6 of the 512 bytes have bit 7
   set.
7. **Bit 7 means "this block's object is not spawned".**
   - *Code* (ElectroDeoxys `560fce6`): `SpawnObject`
     (`src/engine/level/load_objects.asm`, commented "bit 7 set means it's
     not spawned in") returns if bit 7 is clear, and otherwise clears it
     (`and $7f`) and creates the object. `DespawnObject`
     (`src/engine/level/block_queue.asm`) sets it again (`or $80`).
     `SpawnRowEdgeObjects` and `SpawnColEdgeObjects`
     (`src/engine/level/spawn_edge.asm`) test bit 7 before reading the
     block's object nibble.
   - *Static, all 35 maps:* every one of the 1933 bit-7 bytes has an
     object nibble `$1`–`$b`, and every non-zero nibble other than the 584
     spawn markers (`$f`) has bit 7 set.
   - *Live (the owner's Out of the Woods recording, PyBoy, every frame):*
     89 changes of bit 7 alone, all on the decoded bit-7 blocks. A bit is
     cleared on room entry for objects in view, and otherwise when its
     block reaches a fixed distance just outside a screen edge (about
     175 px right of the camera's left edge, 30 px left of it, or 28 px
     above its top). It is set again when the object despawns, including
     at every room change. Breaking blocks changed 14 bytes in their low 7
     bits (`$60` → `$78` 10 times), with bit 7 clear.
   - So a live map differs from the decoded one in bit 7 while objects are
     on screen; `make review` reports those cells separately from changed
     blocks ([emulator oracle](emulator-oracle.md), item 15).

## Interpretation

- A level is a 160 × 48 block grid, i.e. 10 × 3 sections of 16 × 16
  blocks, which matches the section grid read from the room headers.
- The first room needs only the three materials the runtime already has,
  plus breakable blocks and transitions. For WL3-013, breakables can be
  "solid, breaking not implemented" as an explicit, labelled approximation
  rather than a silent one.

## Hypotheses

- *Confirmed (finding 7):* bit 7 marks a block whose object is not spawned,
  rather than a drawing state.
- *Confirmed in WL3-013 ([first room pack](first-room-pack.md)):* the
  object map takes 80 of the spare bytes of each row (offset `$b0`), one
  nibble per block, and nibble `$f` marks the spawn block.

## Unknowns

- What the stale cell in The West Crater holds in practice: zero after a
  fresh boot, or the previous level's byte. Only an oracle run (WL3-014)
  can say.
- Which object each nibble `$1`–`$b` selects. `SpawnObject` receives it in
  `c`; the level's object group (`LoadObjectGroupData`) is the next code to
  read.

## Tests

- Synthetic: `tests/test_level_maps.py` covers shared maps, a reset
  sentinel, row splitting, an unfinished final row, bit 7 counting, the data
  bank taken from the record, out-of-ROM and bank-crossing pointers,
  overflow past the SRAM capacity, an unterminated stream, one map paired
  with two object maps, a refused data bank `$00`, unknown-ROM refusal,
  exploratory marking, determinism, read-only output, and schema validity.
- Real ROM (optional, `make test-rom`): counts, the Out of the Woods map,
  the short West Crater map, every stream ending at the next label, and the
  first room's materials.

## Next experiment

WL3-013: assemble `ROOM_001` from the level header, this block map, and
table `$00`'s materials into an `original-extracted` pack in
`local/content/`, with breakables labelled as a provisional `solid`.
