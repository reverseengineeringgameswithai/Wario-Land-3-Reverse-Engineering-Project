---
type: research
status: active
updated: 2026-10-28
tags: [research, validation]
---
# The hidden figure's fight drawn

**Question:** what does the original show during the hidden figure's
fight (the Temple, level `$c8`), and can the port draw it equal to the
original at every compared frame? Task: WL3-052 (the fight itself:
WL3-048, [objects](objects.md) item 85).

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/init.asm` `.final_battle`,
`src/engine/game_over/load_gfx.asm` `LoadHiddenFigureGfx`,
`src/engine/level/update_level.asm` `.shake_override`,
`src/home/level_vblank.asm` `LevelVBlankFunc`,
`src/engine/level/objects/hidden_figure.asm` `Func_4cfe0`, `Func_4d005`,
`src/home/object_mechanics.asm` `SetBGPals`, `UpdateObjSprite`,
`src/home/bg_ob_pals.asm` `SetWarioPal`, `src/home/sprite.asm`
`LoadSprite`, `src/home/clear_memory.asm` `ClearUnusedVirtualOAM`,
`src/engine/level/update_objects.asm` `DrawObjects_NoPriority`,
`DrawObjects_WithPriority`); the oracle traces of the ten movies that
reach the fight (the invented saves' `map-temple-*` movies), re-traced
with the Temple's VRAM, screens, and palette writes.

## Verified observations

1. **The load.** InitLevel's `.final_battle` takes the place of
   `LCDC_DEFAULT` and farcalls `LoadHiddenFigureGfx` (36:741e):
   `Pals_db000` into `wTempPals1`, `Pals_db040` (5 palettes) into
   `wTempPals2` from palette 3; `$180` tiles of `HiddenFigure2Gfx` to
   VRAM 1's `$8000` and of `HiddenFigure1Gfx` to VRAM 0's (not
   compressed); `HiddenFigure2Map` and `HiddenFigure4Map` decompressed to
   VRAM 1's BG maps 0 and 1, `HiddenFigure1Map` and `HiddenFigure3Map` to
   VRAM 0's. Then `wc08d` and `rWY` `$88`, `rWX` 7, and LCDC `$e7` (BG
   tiles from `$8800`, the window from `$9c00`, 8x16 sprites). The figure
   is BG map 0; the window, from line 136, is the floor. Its two maps are
   52 bytes each (its first row and 20 entries of the second); BG map 1
   past them keeps what it held.
2. **What VRAM changes during the fight** (`map-temple-win-invented`, each
   tick's VRAM against the last, while UpdateLevel runs): only VRAM 0's
   `$8000`-`$87ff`, Wario's tile set as the V-Blank's DMA copies it (97
   times; the BG cannot use those tiles, its own come from `$8800`), and
   VRAM 1's `$9700`-`$977f`, the room's animated tiles (group 3, 424
   times). Wario's first copy comes in the V-Blank after the load.
3. **The scroll.** `.shake_override` sets `wSCY` to
   `wHiddenFigureSCYShake` plus `wSCYShake`, `wSCX` to `wc08b`, and writes
   `rWY` as `wc08d` plus `wSCYShake` while the frame is drawn.
   `LevelVBlankFunc` writes `rSCY` as `wSCY` plus `wSCYShake` on both its
   paths, so the fight's shake shows twice: 6 of the won fight's 79
   compared screens were 2 lines off until the port added it.
4. **The palettes.** After `SlowFadeFromWhite`, the BG palettes are
   `Pals_db000`, the OBJ palettes Wario's (0-1), the particles' (2), and
   `Pals_db040` (3-7). The figure writes BG palettes 0-5 with `SetBGPals`
   straight to the hardware, one palette an H-Blank (`wait_not_hblank`,
   `wait_hblank`, then 8 bytes): `Func_4cfe0` (while the figure is
   defeated or collapsing, and while the face is hurt) on
   `wGlobalCounter & 15` 0 the fight's own set and on 8 `Pals_4d04b` (the
   flash); `Func_4d005` (the hurt's end, the collapse's end) the fight's
   own: `Pals_4d07b` while `w1d15a` (the hits left) is 2 or more, else
   `Pals_4d01b`. `SetWarioPal` writes OBJ palettes 0-1 the same way
   (Wario's flicker). The won fight has 70 `SetBGPals` calls (420 palette
   writes, first at lines 4 to 72) and 22 `SetWarioPal` calls.
5. **The OAM.** `LoadSprite` and `UpdateObjSprite` write their tables'
   entries in order while the virtual OAM has room (40 entries), those
   off the screen too; Wario's attributes are XORed with
   `wWarioAttributes`. The order is `UpdateParticles`,
   `DrawObjects_NoPriority` (the objects with `OBJFLAG_PRIORITY`),
   `DrawWario`, `DrawObjects_WithPriority`, then
   `ClearUnusedVirtualOAM`. The fight's four objects all use `OAM_18c88a`
   (63:488a), with tiles from the figure's graphics in VRAM 1 and OBJ
   palettes 3-7.

## Ported

- `wl3pc.extract.temple` writes `temple.json`: the two tile sets, the four
  maps, and the five palette sets.
- The sim records what the drawing needs and nothing more:
  `hidden_figure_gfx_loads` (InitLevel's load), `rWY`, and
  `hidden_figure_bg_pals` with `hidden_figure_bg_pal_writes`
  (`Func_4cfe0` and `Func_4d005` at their four call sites).
- `TempleVram` (a `ScreenVram`): the load, Wario's tile set when it
  changes, the room's animated tiles, the palettes, the OAM, and
  `rSCX`, `rSCY`, `rWY`; `CgbScreen` draws it, and can now write a
  palette from a line while a frame is drawn. `LevelView` shows it from
  the fade in through the fight, the pause menu over it, and
  `ST_EPILOGUE`'s fade, the fades as white over it.
- The window draws the frame after each loop, so what the next loop
  writes while that frame is drawn shows a frame late there: the floor's
  `rWY` while the shake moves it, Wario's flicker, and the figure's flash
  on the lines below the write. The parity check replays those writes at
  the trace's lines.

## Results

`MODE=run`, each from power-on natively through the title, the map, the
reveal, and the fight; the drawing compared at every 32nd fight update.

| Movie | Fight updates | VRAM snapshots | Screens | Frames with `SetBGPals` |
| --- | --- | --- | --- | --- |
| `map-temple-fight-invented` (lost) | 442 | 13 of 13 | 13 of 13 | 0 |
| `map-temple-all-treasures-invented` (lost) | 442 | 13 of 13 | 13 of 13 | 0 |
| `map-temple-knock-invented` | 592 | 18 of 18 | 18 of 18 | 0 |
| `map-temple-hit-invented` | 611 | 19 of 19 | 19 of 19 | 8 of 8 |
| `map-temple-two-hits-invented` | 1,111 | 34 of 34 | 34 of 34 | 16 of 16 |
| `map-temple-game-over-invented` (lost) | 1,165 | 36 of 36 | 36 of 36 | 16 of 16 |
| `map-temple-perfect-game-invented` (won) | 2,450 | 76 of 76 | 76 of 76 | 70 of 70 |
| `map-temple-win-invented` (won) | 2,545 | 79 of 79 | 79 of 79 | 70 of 70 |
| `map-temple-ending-invented` (won) | 2,545 | 79 of 79 | 79 of 79 | 70 of 70 |
| `map-temple-credits-invented` (won) | 2,545 | 79 of 79 | 79 of 79 | 70 of 70 |
| All | 14,448 | 446 of 446 | 446 of 446 | 320 of 320 |

A `SetBGPals` frame matches when the port makes as many calls as the
original from the same palette set. Step mode is unchanged for all ten.
The window from power-on (`map-temple-win-invented`'s inputs by loop)
equals the original at two compared frames but for the one-frame lags
above: the floor's 8 lines at a shake's end, Wario's colours at a
flicker.

## Interpretation

- The fight is drawn as the original draws it, from its own graphics,
  at every compared frame of the ten movies, the palette flashes and
  the shake included.
- `wSCYShake` is added twice in the fight only because the fight's own
  `wSCY` holds it already; in other levels `LevelVBlankFunc` adds it once,
  which the level window does not draw ([level camera](level-camera.md)).

## Hypotheses

- None open for the paths the movies reach.

## Unknowns

- `SetBGPals` with a first palette other than 0 is not met: the parity
  check numbers a call's palettes from 0.
- The level's fade in and `ST_EPILOGUE`'s fade are drawn as white over
  the fight, as the other levels' fades are (approximations).

## Tests

- `tests/test_temple.py`: the extractor on a synthetic ROM, its places,
  and the port's constants against the reference build's symbols.
- `test_rom_integration.py`: the tracer's palette hooks follow their
  H-Blank waits.
- `game/tests/unit/test_hidden_figure.gd`: `Func_4cfe0`'s flash and
  `Func_4d005` while hurt and collapsing.
- `game/tests/unit/test_temple_drawing.gd`: `TempleVram` (the load, Wario's
  tiles, the palettes, the OAM's order and limit, the shake twice) and
  `CgbScreen`'s palette written from a line.
- `make wario-parity MOVIE=local/recordings/map-temple-win-invented.recording.json MODE=run`
  and the other nine.

## Next experiment

None for the fight's drawing.
