---
type: research
status: active
updated: 2026-10-18
tags: [research, content, validation]
---
# Action Help

**Question:** what does Action Help do, game loop by game loop, when the
clear screen opens it after a power-up's treasure, and how does it draw?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/action_help/`: `state_table.asm`,
`core.asm`, `common1.asm`, `common2.asm`, `main_power_ups.asm`,
`special_power_ups.asm`, the thirteen `power_ups/*.asm`;
`src/home/dpad_repeat.asm`, `src/home/fade.asm`, `src/home/clear_memory.asm`,
`src/engine/title/start_menu.asm` `Func_4628`,
`src/engine/pause/pause_menu_1.asm`); oracle traces of the owner's movies
`game-006` (lead overalls) and `game-017` (swimming flippers), and of 15
branches of `game-006` made at Action Help's start. Task: WL3-051.

## Verified observations

1. **States.** `OpenActionHelp` sets `ST_ACTION_HELP` (7);
   `_ActionHelpStateTable` (7e:4000) runs once a game loop by `wSubState`: a
   fast fade to white (0), `InitActionHelp` (1, seven frames with the LCD
   off), a fast fade in (2), `UpdateActionHelp` (3), a fast fade to white
   (4) and the way back to the pause menu (5). Both fades take 10 loops.
2. **The power-up shown.** `InitActionHelp` takes Owl Wario's, the rail's,
   or Vampire Wario's demo when `wTransformation` is one of them, otherwise
   `wPowerUpLevel`'s power-up; with `ACTION_HELP_TITLE_SCREEN` (bit 6) it
   adds `hDemoPowerUp` (modulo 13), which every visit moves on, the title's
   or not. With `ACTION_HELP_LEVEL_CLEAR` (bit 7, set by the clear screen)
   input is ignored, the demo plays once, and its end clears the flag and
   goes to the map (`Func_4628`: the animated tiles stopped, `w3d50d`
   cleared, `wDayNight`'s bit 7, `ST_OVERWORLD`). Without it, A, B, or Start
   closes it (sub-state 4), left and right move the cursor between the
   main power-ups (blacking the demo out and restarting it), the d-pad
   repeats after 16 loops held and then every 8 (`ProcessDPadRepeat`), and
   a demo's end starts it over. The special power-ups' demos never leave on
   the flag: their ends check only the title screen's.
3. **The demos.** Each power-up has a state table by `wActionHelpState`
   (13 to 37 states) driving Wario (`wActionHelpWario`, his framesets in bank
   $05 or $7f and his tiles by DMA at V-Blank), up to four more objects (an
   enemy, blocks, debris, a pillar: menu objects 4-7 with their OAM table and
   bank), and the d-pad's and buttons' inputs (objects 2 and 3), with the
   cursor (object 1) under the power-up. Jumps step `JumpVelTable_Normal` or
   `_HighJump` by a byte index; some states hold or wrap it. An input
   flashes seven times while the demo is frozen. The objects live in WRAMX
   bank 3 with the clear screen's: `wActionHelpCounter` is never set and
   carries on from the last visit.
4. **The trace.** The tracer records each `_ActionHelpStateTable` call:
   the variables it shares with the game (with `hDemoPowerUp` and
   `wTempBank`), `wTempPals1` and 2, the pending DMA, `wTimer`'s byte,
   `w3d500` to `wMenuObj7AnimationEnded`, and the virtual OAM, with VRAM and
   the screen every 32 loops. A level visit now includes Action Help.
   `make action-help-movie`'s oracle command branches a movie at the first
   tick ending in `ST_ACTION_HELP` (before `InitActionHelp`) with
   `wPowerUpLevel` and `wTransformation` poked, as a stored state that
   rebuilds from its origin; a branch of `game-006` with its own power-up
   reproduces its 998 loops.
5. **Parity** (`make wario-parity`, and the branches). The port
   (`ActionHelpSim`, on `MenuScreenSim` with the clear screen) runs each
   traced loop and is compared with the next on its variables, RAM, and
   virtual OAM; a visit's last loop with the first frame after it. All 997
   and 998 compared loops of `game-006` and `game-017` are identical, and
   both ways out to the map. The branches show every demo after a level's
   clear (each to its end and the map; the special ones for 2,394 loops,
   through several restarts), and two browse the power-ups from the pause
   menu's side (cursor moves, the d-pad's repeat, the power-ups Wario
   lacks, the demos starting over, A closing it, the fade, the pause menu's
   state): all 23,605 compared loops of the 15 are identical, and all 12
   ways out (ten to the map, two to the pause menu's state).
   From the pause menu itself (WL3-052, `title-pause-action-help-game-017`:
   a power-on movie from `game-017`'s save that pauses in Out of the Woods,
   opens Action Help, moves to another power-up, closes it with B, and goes
   back to the level): `OpenActionHelp` from the menu, and
   `ReturnToPauseMenuFromActionHelp`, which sets the pause menu's state and
   runs its `InitPauseMenu_SkipBackupVRAM` in the same loop (the port runs
   the pause menu's init after Action Help's loop, on the same RAM). Step:
   417 of 417 compared loops and the way out, 13 VRAM snapshots and 12
   screens identical; the pause menu around it 443 of 443 and its 12
   screens (the menu Action Help's last loop loaded counted in the pause
   visit after it). Run from power-on: within the level, 445 pause menu
   and 418 Action Help loops natively, then the level's 2,128 whole frames,
   all identical (Action Help's first loop seeded the level's pending DMA,
   7 bytes the level's port does not keep). The window, by the movie's
   input by tick, equals the original's frames after 2,050 and 2,250 ticks
   (the demos), 2,450 (the menu after it), and 3,300 (the level), 0 pixels
   each at the frame its lag frames shift it to (19 to 68 ticks back).
6. **Drawing.** `InitActionHelp` clears BG map 0 (`FillBGMap0`: the tiles
   `$ff`, the attributes 0), decompresses the objects' tiles (bank 1, the
   special power-ups' own set) and the HUD's (bank 0) from `$8000`, and BG
   map 1's maps; on the power-up row it gives the power-ups Wario has the
   plain attribute and draws the unknown power-up's tiles over those he has
   yet to find (all ten for a special one). Its BG palettes are written to
   the hardware (blacked out, then with or without the water) and so are the
   main power-ups' OBJ palettes; the fade in darkens all 64 colours to
   `wTempPals1` and `wTempPals2`, which is all the special demos' objects
   get. Wario's tiles come by DMA, the swimming demo's water by the room
   animation (tile set 2 at bank 1's `$9700`). The port follows it
   (`ActionHelpVram`) and draws with `CgbScreen` (LCDC `$8f`: BG map 1, 8x16
   sprites): all 62 VRAM snapshots of the two movies and 730 of the
   branches match on the bytes it wrote, and all 62 and 728 compared screens
   are identical pixel for pixel. The first comparisons differed in the
   demo's area: the renderer kept its palette in the same packed array the
   VRAM model changed in place, so it never saw the change (it now keeps a
   copy); and the special demos' objects were black until the fade's end set
   the OBJ palettes too.

## Interpretation

- Action Help is a self-contained screen; after a level's clear it only
  shows the power-up and hands over to the map, so the port can go on from
  it to the map's port when there is one.

- The title screen's demos (`ACTION_HELP_TITLE_SCREEN` with
  `hDemoPowerUp`, now the `LevelSim`'s) match, all 13 of them in
  `title-demos-all-game-017` (13,149 compared loops, 404 screens), each
  ended by the reset that keeps `hDemoPowerUp`
  (`InitWithoutDemoPowerUpReset`), step and from power-on
  ([the resets](resets.md), WL3-057).

## Hypotheses

- Closing a title screen demo early (`.CloseActionHelp`'s reset) is
  translated but no trace plays it.

## Unknowns

- The fades are drawn as white over the screen; palette writes made while a
  frame is drawn (`LoadActionHelpBGPals` waits for each H-Blank) are drawn
  from the next frame.

## Tests

- `tests/test_action_help.py`: the extractor on a synthetic ROM, every
  address against the reference build's symbols, and the branches' input.
- `game/tests/unit/test_action_help.gd`: the power-up shown, the d-pad's
  repeat, browsing, closing, a demo's end, the RAM shared with the clear
  screen, the drawing.
- `make wario-parity` on `game-006` and `game-017` (step: Action Help, its
  way out and drawing); the branches with the parity script.
