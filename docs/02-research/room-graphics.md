---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, content, validation]
---
# Room graphics

**Question:** what does each block of a room look like, and does a background
built from the decoded data match the original's screen?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/load_room_gfx.asm`,
`src/home/load_room.asm`, `src/engine/level/block_queue.asm`,
`src/level.asm`, `src/data/levels/palettes.asm`) and its byte-identical
reference build; the [room records](room-records.md) decoder for the sources;
oracle screens of the owner's movie and the walk capture. Task: WL3-018.

## Verified observations

1. **Sources and destinations** (`LoadRoomGfx` and the home loaders): block
   tiles (`$200` bytes, four tile numbers per block) to `wRoomBlockTiles`;
   block attributes (`Decompress`, `$200` bytes) to `wRoomBlockAttributes`
   (what the room record calls the "tile map"); main tiles (`$800`) to
   `$9000` in VRAM bank 0; special tiles (`$800`) to `$9000` in VRAM bank 1;
   8 palettes (64 bytes, little-endian BGR555) to `wTempPals1`.
2. **Block layout.** The block queue writes a block's four tiles to the BG
   map top-left, top-right, bottom-left, bottom-right, and its four
   attribute bytes to the same cells in VRAM bank 1 (palette bits 0–2, bank
   bit 3, flips bits 5–6, priority bit 7).
3. **Decoded** (`make extract`, `tools/wl3pc/extract/room_gfx.py`): the four
   room records Out of the Woods uses (1, 5, 6, 10) to
   `local/content/wl3-original/rooms/` as JSON plus a block sheet and a tile
   sheet in PNG. No block of these rooms uses a tile number of 128 or more,
   so all their tiles come from the room's own two sets.
4. **Against the reference build:** `ROOM_001`'s main and special tiles equal
   `gfx/levels/main_tiles0.2bpp` and `special_tiles0.2bpp` byte for byte
   (the `INCBIN`s of `LevelMainTiles0` and `SpecialTiles0`), and its palettes
   equal `Pals_cc000`'s `rgb` lines in `palettes.asm`.
5. **Against the screen** (`make screen-check MOVIE=… TICKS=…`,
   `tools/wl3pc/oracle_screen.py`): every room the owner's movie visits uses
   record 1. At 14 frames spread over the movie, 300,216 of 300,216 compared
   background pixels equal the composition from the level block map in
   SRAM and the decoded blocks; the walk adds 88,976 of 88,976. Two timing
   details had to be respected: the scroll each scanline was drawn with
   comes from PyBoy's per-line positions (the registers after the frame can
   already hold the next scroll), and sprites from the previous frame's OAM
   are left out too.
6. **VRAM over time.** At every sampled frame, VRAM bank 0 `$9000`–`$97ff`
   equals the decoded main tiles; in bank 1, tiles 112–119 differ from the
   decoded special tiles (the room's animated tiles, written by
   `UpdateRoomAnimatedTiles`). No compared frame showed a block using them.
7. **The game window** (`make run LEVEL=0`) draws each block from the block
   sheet at the scroll the original shows (`displayed_camera_x/y`, the full
   value behind `wSCX`/`wSCY`). Screenshots it saved after 20, 24, and 100
   ticks of the walk equal the oracle's screen after the same ticks on every
   compared pixel (5-bit colour; the overlay label, Wario's stand-in box, and
   sprites left out). After 10 ticks, 4 pixels at the box's edge differ.
   Since WL3-038 the window draws Wario's sprite, then the pixels of
   priority tiles over him (`room-NNN-priority.png`), and `make window-check`
   finds every pixel equal but other sprites'
   ([Wario's sprites](wario-sprites.md)).

8. **Animation (WL3-037).** A level room's header names an animated-tiles
   group and a palette cycle (`InitRoomAnimatedTiles`/`Pals` at each room
   load). The groups (`AnimatedTilesGroups`, 29: a frame duration and a
   graphics index) pick a `$200`-byte block of `AnimatedTilesGfx` (bank
   `$34`: four frames of eight tiles), equal to the reference build's
   `animated_tilesN.2bpp`; every duration loops `UpdateRoomAnimatedTiles`
   copies the next frame to VRAM bank 1's tiles `$70`-`$77`. The cycles
   (`RoomPalCycles`, 20: eight `RoomPals` entries and a duration; the
   counter starts half way) copy the next entry's eight palettes (bank
   `$33`) as the BG palettes. Until the first step after a room load, VRAM
   and the palettes hold the room's own. Both run at the end of every game
   loop while enabled (`InitLevel` enables the tiles, every `UpdateLevel`
   the palettes, a room transition or the pause stops them), and both skip
   a loop that reaches them late in the frame (`rLY` at least 124, or 136):
   CPU timing, which the trace records at every call (`animation_calls`;
   none of the owner's movie was late) and parity runs replay. Out of the
   Woods uses groups 1-3 and, in its torch rooms, cycle 1.
   - The whole movie's run now also compares the animation variables at
     every frame: all 5802 frames equal, and the level ends on the
     original's frame (`UpdateLevel.check_end_screen`, which stops the
     animations and goes to the clear screen).
   - `make screen-check` composes the background as the animation leaves
     it (VRAM's animated tiles must be the frame the RAM names or the
     room's own): 128,458 of 128,458 pixels at six frames of the movie
     showing animated blocks, over all four frames; the frames differ from
     the room's own tiles on 164-256 of a block's 256 pixels. The window
     draws its blocks from the decoded graphics in the same way
     (`RoomSheets`).

## Interpretation

- Static room graphics are fully determined by the room record and the
  level block map; the port's background is the original's.

## Hypotheses

- None open for the animation; see Unknowns.

## Unknowns

- Palette cycling is ported and checked in the screen check's logic, but no
  recorded frame shows a cycling room yet (Out of the Woods' torch rooms
  are not in the owner's movie).
- Tiles at `$8800`–`$8fff` (numbers 128 and above) for rooms that use them,
  and objects' sprite graphics.

## Tests

- `tests/test_room_gfx.py`: 2bpp decoding, palette words, block layout,
  flips and banks, unknown tiles, and the PNG writer (invented data).
- `tests/test_rom_integration.py`: `ROOM_001` against the reference build and
  the palette source, and the screen check on the walk capture.

## Next experiment

A recording through a room with a palette cycle (Out of the Woods' torch
rooms, room-list entries 14, 27, and 29).
