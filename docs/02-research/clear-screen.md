---
type: research
status: active
updated: 2026-10-05
tags: [research, content, validation]
---
# The level's clear screen

**Question:** what happens between a level's treasure scene and the map,
game loop by game loop, and what does it record of the game's progress?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/clear/`: `state_table.asm`,
`treasure_clear.asm`, `time_attack_clear.asm`, `musical_coins.asm`,
`musical_coin_flags.asm`, `pencil.asm`, `treasure_transition.asm`,
`treasure_count.asm`, `add_sprite.asm`, `vblank.asm`, `bank78.asm`;
`src/home/object_animation.asm`, `src/home/overworld.asm`
`IsTreasureCollected`, `src/home/fade.asm`, `src/engine/title/start_menu.asm`
`Func_4628`); oracle traces of the owner's 17 movies. Task: WL3-043.

## Verified observations

1. **States.** After `UpdateLevel.check_end_screen` sets `ST_CLEAR` (3),
   `_ClearScreenStateTable` (35:4000) runs once a game loop by `wSubState`:
   a fade to white (0), the treasure screen (`InitClearScreen` 1, a fade in
   2, `UpdateClearScreen` 3), Time Attack's screen (4-7), the musical coin
   screen (a fast fade out 8, `InitMusicalCoinScreen` 9, a fast fade in 10,
   the count 11, the pencil's way to the level's flag 12, its scribble 13),
   and the way out (`ExitClearScreen` 14). A on the treasure screen goes on
   to the coins; the coins then wait for A or two wraps of `wTimer`'s low
   byte. The fades come at three speeds: 33, 18, or 10 loops by
   `wFadeSpeed` (`SlowFadeBGToWhite` and `DarkenBGToPal_Fast` are the fast
   ones), and a fade's first loop sets the screen's V-Blank function aside
   (`VBlank_88d` keeps its first bytes) and its last puts it back.
2. **Progress.** `InitClearScreen` sets `wResetDisabled`, finds the level's
   treasure (`SetTreasureTransitionParam`: `LevelTreasureIDs_WithoutTemple`,
   four a level, by `wLevelEndScreen`; `TRANSITION_RETURN_TO_MAP` without
   one), marks it in `wTreasuresCollected` (WRAMX bank 2, a bit each:
   treasure `t` is bit `t & 7` of byte `t >> 3`), counts the music boxes
   (the highest of treasures 1-5 held) and all treasures 100 down to 1 in
   BCD (`wNumCollectedTreasures`). A power-up treasure sets its power-up
   with `ACTION_HELP_LEVEL_CLEAR` in `wPowerUpLevel`, and the way out then
   opens Action Help (`ST_ACTION_HELP`) instead of the map. With all eight
   musical coins, `SetMusicalCoinFlag` marks the level in
   `wMusicalCoinFlags` (bit `level & 7` of byte `level >> 3`) and the pencil
   colours its flag; already marked, it does nothing. The way to the map
   (`Func_4628`) stops the animated tiles, clears `w3d50d`, sets
   `wDayNight`'s bit 7, and starts `ST_OVERWORLD`.
3. **Objects.** The screen's objects are WRAMX bank 3's menu objects (y, x,
   frame, attributes, frameset offset, duration, frameset pointer high byte
   first). `UpdateObjAnim` counts the duration down, then takes the next
   (frame, duration) of the frameset in the ROM bank mapped (the clear
   screen's $35, or $7c through `farcall $7c`); at `$ff` it resets the
   offset and duration and sets `wObjAnimWasReset`, keeping the frame. Clear
   Wario takes his second animation (celebrating, or not without a
   treasure) when his first first resets. Sprites come from four OAM
   tables (`LoadClearScreenSprite` and Wario's less `wSCY`, the pencil's,
   the pause menu's without it); the pause menu's table points one frame
   at `EmptyOAMFrame` in home bank 0.
4. **V-Blank.** The musical coin screen's V-Blank function writes the BG
   entry queued in `wBGMapTileVRAM0Queue` (two coin digit tiles, or the
   flag's palette attribute) and clears `wcee4`'s bit 7; the treasure
   screen's turns a tile's rows (drawing only).
5. **The trace.** The screens' tracing is shared with golf: at each
   `_ClearScreenStateTable` call, the variables it shares with the game,
   its RAM (the musical coin flags, the tile queue, the level time,
   `wcee4` and `wTimer`'s two bytes, `w3d50d` to the last menu object, the
   treasures to `wOWLevel`), and the virtual OAM (`clear_updates`), with
   VRAM and the screen every 32 loops. A level visit now includes its clear
   screen; the loop that leaves it is recorded in the tick whose frame first
   shows it left, so a screen's loops keep the window's end frame.
6. **Parity** (`make wario-parity`). From each traced loop the port
   (`ClearSim`, one a visit so that the V-Blank function the loops leave
   carries over) runs one loop and the room animation after it, and is
   compared with the next on its variables, RAM, and OAM; the last loop is
   compared with the first frame after the screen on what the way out sets.
   All 4,098 compared loops of the 17 movies are identical, and all 17 ways
   out (to the map, or to Action Help after the lead overalls and the
   swimming flippers).

7. **Drawing.** `InitClearScreen` clears BG map 0 (`FillBGMap0`: the tiles
   `$ff`, the attributes 0; the port first wrote `$ff` to both, unseen as
   the attribute maps cover it all), takes the screen's palettes with the
   treasure's in OBJ palette 7 (by the level's `wLevelTreasurePals`), its
   tiles (bank 1 from `$8000`, bank 0 from `$8800`, Clear Wario at
   `$8000`), the level's four treasures' tiles at `$8900` (`LoadTreasureTiles`: `TreasureGfx`, four tiles each, by
   `wOWLevel`'s `LevelTreasureIDs`, the blue's copied twice), its maps, the
   coins (`PrintNumberCoins` at (6, 16): two tiles a digit, `$a0` plus
   twice it), and a mark under each treasure found. The coin screen takes
   golf's menu graphics, colours each level with all eight coins (five a
   row from (8, 9); the 25th takes the 24th's palette, as `Func_d47f1`'s
   index is not advanced), and its counter's digits come from the queue.
   Its V-Blank functions turn the sixteen rows of tiles `$170`-`$171`
   down one row a frame (the treasure screen's), or write the queued
   entry (the coin screen's). The coin screen's background is the room
   animation's tile set 15 in bank 1's `$9700`, which
   `UpdateRoomAnimatedTiles` copies while the frame is drawn, 8 bytes an
   H-Blank: lines drawn before a chunk's H-Blank show the old tiles (the
   tracer now records each chunk's line, `animation_copies`). The port
   follows it (`ClearVram`, on a `ScreenVram` base shared with golf) and
   draws it with golf's renderer (`CgbScreen`, which applies writes made
   while a frame is drawn from the line after them): all 119 VRAM
   snapshots of the 17 movies match on every byte the screens wrote, and
   all 73 compared screens are identical to the original's, pixel for
   pixel. Before the chunk lines, three screens of `game-016` differed
   from a few lines down: their frames carried a copy half done.

## Interpretation

- The clear screen is where a level's result becomes the game's progress;
  the port keeps it in the same RAM so that a save, the map, and Action
  Help can take it from there.

## Hypotheses

- Time Attack's screen and the pencil (a level's eight musical coins) are
  translated and unit-tested but have not met the oracle: no movie plays
  Time Attack or collects all eight coins yet.

## Unknowns

- The game window's drawing has not been compared with the original's
  window (only its renderer with the original's screens). The fades are
  drawn as white over the screens.
- The map, where the way out goes, is not ported; Action Help is
  ([Action Help](action-help.md)).

## Tests

- `tests/test_clear.py`: the extractor on a synthetic ROM, and every
  address against the reference build's symbols.
- `game/tests/unit/test_clear.gd`: menu objects' animation, the treasure
  and counts, a power-up, the coins' count and flag, the pencil, the way
  out.
- `make wario-parity` on the owner's movies (step: `clear screen`, its
  drawing and way out).
