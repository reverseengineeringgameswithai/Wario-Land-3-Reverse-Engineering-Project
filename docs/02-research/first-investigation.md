---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, collision]
---
# First investigation: block function tables

**Question:** how does the original game map a room's block IDs to collision
behaviour, and can that mapping be extracted with bounds and provenance?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build); symbols from the
local reference build.

## Verified observations

1. **Consumer.** `ProcessBlock` (`06:4000`,
   `src/engine/level/block_functions.asm`) reads the block ID at
   `wBlockPtrBank:wBlockPtr`, doubles it, indexes the WRAM table
   `wBlockFunctionTable`, and jumps to the 16-bit handler with `jp hl`. It is
   reached by `call` from `src/engine/level/collisions.asm`, so handlers
   execute in bank `06`; a pointer below `$4000` would resolve to ROM0.
2. **Table size.** `wBlockFunctionTable` is `ds 2 * $80` (`src/ram/wram.asm`).
   `LoadBlockFunctionTable` copies with `CopyHLToDE` and `b = $00`, which loops
   256 times: 128 block IDs × 2-byte pointers.
3. **Selection.** `LoadRoomGfx` (`30:4000`) stores the room's table index in
   `wRoomBlockFunctionTable`. `LoadBlockFunctionTable` (`00:2800`,
   `src/home/load_room.asm`) reads `BlockFunctionTablePointers[index]`
   (`32:4000`, 98 entries = `NUM_BLOCK_FUNCTION_TABLES` `$62`).
4. **Two banks.** Indices below `$3F` copy from bank `$32`; indices `$3F` and
   up copy from bank `$50`, the section `Block Function Tables 2`. The code
   compares with `NUM_BLOCK_FUNCTION_TABLES_GROUP_1 - 1`, where the constant
   is `$40`, so the split is at `$3F`. This is consistent with the symbols:
   `BlockFunctionTable62` is at `32:7ec4` and `BlockFunctionTable63` at `50:4000`.
5. **Reset sentinel.** If the pointer's high byte is `$FF`,
   `LoadBlockFunctionTable` jumps to `Init` (a soft reset). Entries
   `$59`–`$61` are `dw NULL`, with `NULL EQU $ffff` (`src/constants/misc_constants.asm`).
6. **Decoded from the ROM** (`make extract`, decoder
   `tools/wl3pc/extract/block_functions.py`):
   - 89 tables decoded, 9 reset sentinels (`$59`–`$61`).
   - Group 1 tables sit at `32:40c4 + $100 × i`; group 2 starts at `50:4000`.
   - 138 distinct handler pointers, all in bank `06`.
   - **All 138 land exactly on global labels** in the reference `.sym`, which
     confirms the structure and the bank rule independently of the decoder's
     assumptions.
   - Output `local/content/wl3-original/block_function_tables.json` is
     deterministic: a re-run is byte-identical. Its SHA-256 is `69df329a…d719`
     when it is labelled with the local `.sym` and the editor's
     `tileEffects.txt`.
7. **Two handlers read so far.** `BlockFunc_Free` (`06:4020`) clears
   `wBlockFuncBreakFlag`, `wBlockFuncSpecialCollision`, and `wUnused_c18d`,
   and returns `a = 0`. `BlockFunc_Solid` (`06:4032`) clears the same flags. It
   then, unless the Wario, slope-interaction, and collision-point bit 4
   conditions are all set, masks `hYPosLo` with `$F0` (snapping the probe's
   Y to a 16-pixel boundary) and returns with `wUnused_c18d = 1`.

## Interpretation

- A room's collision behaviour is a two-step lookup: room record → table
  index → 128-entry handler table. The runtime should consume a **material
  per block ID per table** produced by a mapping step (WL3-011), never raw
  handler pointers. The extracted file keeps handler IDs (`h06_4032`) for
  provenance only.
- `BlockFunc_Solid`'s `$F0` mask suggests that collision probes work in a
  16-pixel block grid with a subpixel or low-byte position. This is a
  hypothesis that WL3-012 and WL3-014 will test.

## Unknowns

- What 136 of the 138 handlers do.
- *Resolved by WL3-010 ([room records](room-records.md)):* which table each
  room uses, and why `LoadRoomGfx` computes `index / 6`. The function-table
  byte selects bank `$38 + index / 6`, which holds both the room's block
  tiles and its compressed tile map; `wc0d0` carries that bank into
  `LoadRoomTileMap`. All 89 tables are used by at least one room.

## Tests

- Synthetic: `tests/test_block_functions.py` (group split, sentinel,
  ROM0 handler, out-of-range handler, cross-bank table, truncated ROM, unknown
  ROM refusal, exploratory marking, determinism, read-only output).
- Real ROM (optional): `tests/test_rom_integration.py`, run with `make test-rom`.

## Next experiment

WL3-011: classify the handlers used by the first room's table, once WL3-024
has identified that room.
