---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, content]
---
# Room records

**Question:** what does each room record select, and from which banks does
the original load each selected item?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build); symbols from the
local reference build. Task: WL3-010. The block function tables that records
point at are described in the [first investigation](first-investigation.md).

## Verified observations

1. **Consumer.** `LoadRoomGfx` (`30:4000`, file offset `0xC0000`,
   `src/engine/level/load_room_gfx.asm`) doubles `wRoom`, indexes
   `RoomBlockAndGfxData` (`30:44c5`, offset `0xC04C5`,
   `src/data/levels/rooms1.asm`), and follows the 16-bit pointer in bank `30`.
   It is reached only by `farcall` from `LoadRoom` (`src/home/load_room.asm`),
   so bank `30` is mapped throughout.
2. **Reset sentinel.** `ld a, h / debug_assert_not $ff` jumps to `Init` when
   the pointer's **high byte** is `$ff` (`src/macros/code.asm`). `ROOM_000` is
   `dw NULL`. The test is on the high byte only, so the decoder treats any
   `$ffxx` pointer as a reset.
3. **Record format.** Five bytes, read with `ld a, [hli]` in this order and
   stored into `wRoomBlockFunctionTable`, `wRoomTileMap`, `wRoomMainTiles`,
   `wRoomSpecialTiles`, and `wRoomPalettes`. The `room` macro has the same
   order. The decoder names the fields after these WRAM variables.
4. **Table length.** `NUM_ROOMS` is `$9b` (`src/constants/room_constants.asm`),
   and `RoomBlockAndGfxData` has `assert_table_length NUM_ROOMS` followed by
   eight `dw NULL` entries that the decoder does not read.
5. **Bank and source rules.** Each home loader below runs with bank `30`
   mapped, reads its pointer table from bank `30`, and switches only for the
   data:

   | Source | Loader | Pointer table | Indexed by | Data bank | Read |
   | --- | --- | --- | --- | --- | --- |
   | Block tiles | `Func_298d` (`00:298d`) | `RoomBlockTilesPointers` `30:490d` (`$59` entries, `NUM_BLOCKSETS`) | function-table byte | `$38 + fn / 6` (`wRoomBlockFunctionTableBank`) | `$200` bytes to `wRoomBlockTiles` |
   | Tile map | `LoadRoomTileMap` (`00:29bf`) | `RoomBlockAttributePointers` `30:49d1` (`$59`) | tile-map byte | `wc0d0`, which equals `$38 + fn / 6` | `Decompress` into `wRoomBlockAttributes` (`ds $4 * $80`) |
   | Main tiles | `LoadRoomMainTiles` | `LevelMainTilesPointers` `30:4a95` (40 before NULLs) | main-tiles byte | `$51 + index / 8` | `$800` bytes |
   | Special tiles | `LoadRoomSpecialTiles` | `SpecialTilesPointers` `30:4af7` (9 before NULLs) | special-tiles byte | `$4e + index / 8` | `$800` bytes to VRAM bank 1 |
   | Palettes | `LoadRoomPalettes` | `RoomPals` `30:4b1b` (146 before `ds $12, $ff`) | palettes byte | `$33` (`BANK("Level Palettes")`) | 64 bytes (8 palettes) |

   File offsets of the pointer tables: `0xC090D`, `0xC09D1`, `0xC0A95`,
   `0xC0AF7`, `0xC0B1B`. Bank bases come from `src/layout.link`: Level Data 1
   is `$38`, Room Main Tiles 1 is `$51`, Room Special Tiles 1 is `$4e`, and
   Level Palettes is `$33`.
6. **The `index / 6` rule.** `LoadRoomGfx` divides the function-table byte by
   6 with a `sub $6` loop, adds `BANK("Level Data 1")`, stores the result in
   `wRoomBlockFunctionTableBank`, and copies it to `wc0d0` just before
   `LoadRoomTileMap`. `LoadRoomTileMap` passes `wc0d0` as `hCallFuncBank`,
   and `hCallFunc` (`src/home/hcall.asm`) switches to that bank before
   calling `Decompress`. So the **function-table byte selects the bank** for
   both the block tiles and the tile map, while the **tile-map byte indexes**
   the tile-map pointer table. This confirms the hypothesis in the first
   investigation. The rule only works if both bytes fall in the same group of
   six. In this ROM they are always equal.
7. **Decompress.** `Decompress` (`00:0909`, `src/home/decompress.asm`) reads
   a control byte: `$00` ends the stream, bit 7 clear means repeat the next
   byte `control` times, and bit 7 set means copy `control & $7f` literal
   bytes. Because the literal loop is `dec d / jr nz`, control `$80` copies
   256 bytes. The decoder models this quirk and tests it on synthetic data. No
   stream in this ROM uses `$80`.
8. **Decoded from the ROM** (`make extract`, decoder
   `tools/wl3pc/extract/rooms.py`):
   - 155 entries (`NUM_ROOMS`): 154 records and one reset sentinel (`ROOM_000`).
   - Records are contiguous 5-byte blocks from `30:460b` (offset `0xC060B`)
     to `30:4908` (offset `0xC0908`), and each one lands on its
     `RoomBlockAndGfxData.room_data_NNN` label. The 154 decoded records
     match the 154 such labels in the `.sym`.
   - Every function-table byte is below `$59`; none selects a reset sentinel.
     All 89 decoded tables are used, by 1 to 6 rooms each.
   - The tile-map byte equals the function-table byte in all 154 rooms.
   - Every resolved source lands on the expected global label:
     `BlocksetTilesNN` and `BlocksetAttributesNN` (NN = the record byte),
     `LevelMainTilesN`, `SpecialTilesN`, and a `Pals_*` label. All 40
     main-tile sets and all 9 special-tile sets are used; 102 of the 146
     palette entries are used, with indices up to `$75`.
   - All 154 tile-map streams decompress to exactly `$200` bytes, the size
     of `wRoomBlockAttributes`, from 70 to 326 compressed bytes. Each of the
     89 distinct streams ends exactly at the next label in its bank, except
     the last stream in each of the 15 banks `$38`–`$46`, which has no later
     label in its bank.
   - The output `local/content/wl3-original/room_records.json` is
     deterministic: a re-run is byte-identical. Its SHA-256 is
     `f4a98d51…223a` when it is labelled with the local `.sym`. It is valid
     against `schemas/room-records.v1.schema.json`.

## Interpretation

- Bytes 1 and 2 behave as one key, a "blockset" (the disassembly's own
  constants for byte 2 are `BLOCKSET_NN`). It selects the collision table,
  the per-block tile indices, and the compressed per-block data. The
  pipeline should still keep them as separate fields, because the code reads
  them separately.
- `wRoomBlockTiles` is `4 * NUM_ROOM_BLOCK_TYPES` bytes. With 128 block
  types, this suggests four 8×8 tiles per block, i.e. 16×16-pixel blocks.
  That fits the `$F0` Y snap in `BlockFunc_Solid`. This is unverified until
  the consumer that draws blocks is read.

## Hypotheses

- The decompressed "tile map" (`wRoomBlockAttributes`, 4 bytes × 128 block
  types) holds CGB BG attributes (palette, VRAM bank, flips) for the four
  tiles of each block. The disassembly's names disagree (`wRoomTileMap`
  versus `RoomBlockAttributePointers`). To test it, read the code that
  writes the BG map from `wRoomBlockTiles` and `wRoomBlockAttributes`
  (WL3-018).
- *Resolved by WL3-024 ([level headers](level-headers.md)):* `wRoom` is
  the last byte of the room header that `LoadRoom` reads, and Out of the
  Woods, day 1 starts in `ROOM_001`.

## Unknowns

- What the decompressed per-block bytes mean (WL3-018).
- Why 44 palette entries and the eight NULL-padded room slots exist but are
  unused by any record. Unused data is not evidence of any behaviour.
- Whether any other code path writes the `wRoom*` graphics variables. A
  search of the disassembly for `wRoom`, the six record and bank variables,
  `wc0d0`, and their raw addresses (`$c0c9`–`$c0d0`) found uses only in
  `load_room_gfx.asm` and `home/load_room.asm`. Indirect access through a
  computed pointer would not show up in such a search, so this is a lead,
  not proof.

## Tests

- Synthetic: `tests/test_rooms.py` covers reset sentinels including a
  high-byte-only `$ff12`, the group split for function tables, the
  bank-from-function-table rule, NULL and out-of-ROM pointers, records and
  copies that cross a bank end, out-of-table indices, a reset-sentinel
  function table, overflowing tile maps, a truncated ROM, unknown-ROM
  refusal, exploratory marking, determinism, read-only output, and schema
  validity. `tests/test_rle.py` covers the `Decompress` model.
- Real ROM (optional, `make test-rom`): the counts against `NUM_ROOMS`, the
  record and source labels, and the stream ends, in
  `tests/test_rom_integration.py`.

## Next experiment

Done in WL3-024 ([level headers](level-headers.md)). Next for room
graphics: WL3-018.
