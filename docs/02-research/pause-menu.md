---
type: research
status: active
updated: 2026-10-28
tags: [research, validation]
---
# The pause menu

**Question:** what does the in-level pause menu do, game loop by game loop,
including the save from it, and does a port of it equal the original on
the owner's movies? Task: WL3-052.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/pause/state_table.asm`,
`pause_menu_1.asm`, `pause_menu_2.asm`, `bank7d.asm`, `save/save.asm`,
`save/checksum.asm`, `src/home/backup_vram.asm`, `src/engine/print_counts.asm`,
`src/home/clear_memory.asm`); the oracle trace of `game-016`, the only
owner's movie that pauses in a level, and of three power-on movies from
`game-017`'s save that pause in Out of the Woods: `title-continue-level-game-017`
(To Map), `title-save-level-game-017` (Save), and `title-pause-return-game-017`
(B: back to the level). The map's save
screen, which runs in the same state table from `SST_PAUSE_18`, is in
[the map](overworld.md), item 6.

## Verified observations

1. **States.** `_PauseMenuStateTable` (7c:4000) runs the pause menu at
   sub-states 0-7: `SlowFadeBGToWhite`, `InitPauseMenu`,
   `DarkenBGToPal_Fast`, `UpdatePauseMenu`, then on Return a fade,
   `ExitPauseMenu`, a fade, and `ReturnToPendingLevelState`. Save from the
   menu is `SST_PAUSE_MENU_SAVE` (8-$10): `InitSaveScreen`, the bar,
   `SaveLevel`, the complete box, and `ResetAfterPauseMenuSave`, which
   jumps to `Init` (the power-on start).
2. **The menu.** `InitPauseMenu` backs up the screen (`SaveBackupVRAM`) and
   the room's animated tiles, loads the menu's palettes
   (`Pals_1f4182`, `Pals_1f41c2`), and sets up menu objects 2-11 (the
   cursor, Wario, the keys and treasures the level has given) with their
   framesets (`Frameset_1f1c4a` to `Frameset_1f1d4c`) and sprites
   (`LoadPauseMenuSprite`, `OAM_1f156c`). `HandlePauseMenuInput` moves the
   cursor with left and right over Return, Save (not in Time Attack),
   Action Help, and To the map. A chooses and B returns; Start is not
   read. To the map goes through `ReturnToMapFromLevel`, which sets
   `wDayNight`'s bit 7.
3. **The level's save.** `SaveLevel` writes the level's state four times
   into SRAM bank 0 (`"WAR3"` copies: the progress and level WRAM, the
   treasures, and WRAMX bank 1's objects, each with its checksum), and
   backs up the level's map in SRAM (`Func_1f14c6`: bank 2's first half to
   its second, bank 1 to bank 3). `CalculateChecksumLong` jumps into
   `CalculateChecksum` instead of looping (`checksum.asm`), so a copy's
   checksum covers only two of the objects' `$14a` bytes.
4. **Data.** `wl3pc.extract.pause_menu` (format 3) adds the 21 framesets,
   the OAM table, the two palette sets, `PauseMenuGfx`, the three
   transformations' tiles, and the menu's two pairs of maps, each on its
   label (`tests/test_pause_menu.py`).
5. **Ported and checked.** `PauseMenuSim` translates sub-states 0-$10 and
   keeps the map's save screen as before. Results are in
   [results](#results).
6. **The menu's screen.** `InitPauseMenu_SkipBackupVRAM` clears BG map 0
   (`$ff`), decompresses `PauseMenuGfx` (`$1800` bytes: all of VRAM 0's
   tiles) to `$8000` with Owl Wario's, the rail's, or Vampire Wario's
   `$20` tiles over its start, puts `Func_1f403f`'s maps on BG map 1 (in
   Time Attack its own, with the level's best time from
   `wLevelTimeAttackScores` at (4, 2) and `wLevelTime` at (11, 2), four
   digits each with a column between the bytes), and prints the musical
   coins at (7, 15) and the coins at (14, 15): each digit two tiles, `$a0`
   plus twice it, and the one below. The LCD shows BG map 1 with 8×16
   sprites. The level's save screen (`InitSaveScreen`) is the map's but
   leaves BG map 1 as the menu left it.
7. **Back to the level.** `ExitPauseMenu` clears the virtual OAM and draws
   the level's objects and Wario into it (`DrawLevelObjectsAfterLevelReturn`;
   `DrawWario` leaves `wTempBank` on Wario's OAM bank), puts the level's VRAM back (`LoadBackupVRAM`), and restores the room's
   animated tiles; after the fade in, `ReturnToPendingLevelState` returns
   to `wPendingSubState`. On `title-pause-return-game-017` the menu opens at
   tick 1701 and the level's next update is at 1890.
8. **Action Help from the menu.** A on Action Help jumps to
   `OpenActionHelp` (`ST_ACTION_HELP`, sub-state 0); Action Help's way back
   (`_ReturnToPauseMenuFromActionHelp`) sets the menu's state at
   `SST_PAUSE_INIT_MENU` and runs `InitPauseMenu_SkipBackupVRAM` in the same
   loop: the menu comes back without a second backup of the level's VRAM,
   so `ExitPauseMenu` restores the one made on pausing.
9. **The save after the Perfect screen** (`SST_PAUSE_28` to `$31`, from
   the Perfect screen's button with Time Attack closed): the map's save
   screen's steps again (`SlowFadeBGToWhite`,
   `InitSaveScreenAndBackupVRAM`, `DarkenBGToPal_Fast`,
   `FillSaveScreenBar`, `Save`, `HandleSaveCompleteBox`), then
   `ResetAfterSave` (`jp Init`). `map-perfect-after-clear-invented`: all
   983 save loops, 29 VRAM snapshots, and 28 screens match ([the Perfect
   screen](perfect.md)). The drawing shows the temporary palettes once
   each fade in ends, at `$2b` and `$2f` as at `$1b` and `$1f`
   (`SaveScreenVram.FADED_IN`; until 2026-10-28 it left them black there).

## Results

`make wario-parity` on the 17 movies (step): the pause menu's state table
now compares 2,897 loops, all identical: the map's save screens' 2,494 and
`game-016`'s 403 in the menu and the level's save (by sub-state 0:20, 1:2,
2:20, 3:221, 8:10, 9:1, $0a:10, $0b:40, $0c:10, $0d:1, $0e:10, $0f:59),
with `SaveLevel`'s SRAM writes. All 20 ways out match (`game-016`'s way to
the map is in two visits' windows, so it counts twice); the only loop not
compared is the reset after the level's save. The save screen's drawing is
unchanged (71 VRAM snapshots, 44 screens).

Run mode: `game-016`'s first visit plays the menu natively to the end of
its window (151 loops, out to the map); the second plays 184 loops of the
menu and the level's save natively and stops at `SaveLevel`'s copy of the
level map's SRAM (see [unknowns](#unknowns)).

The drawing (2026-10-18, `SaveScreenVram`): the step check now draws a
visit from a level too, and compares the menu's screens (sub-state 3) and
the level's save screens (`$0b`, `$0f`) with the map's. On the 17 movies
82 of 82 VRAM snapshots and 52 of 52 screens are identical (`game-016`'s
visits from the level add 11 and 8); on `title-continue-level-game-017` 23
and 22, on `title-save-level-game-017` 20 and 19, on
`title-pause-return-game-017` 5 and 4. The window shows them in place of
the stand-in; after 1,800 and 1,900 ticks of `title-continue-level-game-017`
by its input by tick it differs from the nearest original frames only in
the turning musical coin and its sparkle (rows 100-139, columns 16-47): the
input by tick drifts from the original's lag frames, so the menu opens a
few loops apart.

The way back (`title-pause-return-game-017`): step, 172 of 172 compared
loops and the way out; the virtual OAM after `ExitPauseMenu` (sub-states
6 and 7) is not compared, as the port keeps the level's sprites as
`LevelSim.drawn_objects`. Run from power-on: 2,128 whole level frames,
with the menu's 173 loops natively between two of them (the run's gap
between level updates now runs a screen's traced loops as after a level,
`_run_level_gap`; seeded at its first loop, as after a level: 134 bytes,
the OAM, and `wTempBank`), all identical.

Action Help from the menu (`title-pause-action-help-game-017`): the pause
menu's 443 of 443 compared loops and 12 of 12 screens, Action Help's 417
and 12 ([Action Help](action-help.md)); run within the level, 445 and 418
loops, then the level. On the way: after Action Help, `ExitPauseMenu`'s
`wTempBank` (5, Wario's OAM bank) differed until the port set it as
`DrawWario` does (the earlier movies had left 5 there already); the step
check now gives the menu's visit after Action Help the screen Action
Help's last loop loaded (spec `visit_load`) and the pause loop Wario's
variables `DrawWario` reads; and a run from power-on forgets the level's
pending DMA after it (`LEVEL_RAM_NOT_KEPT`), which Action Help's first loop
then seeds.

## Interpretation

- The pause menu and the level's save are a faithful port as far as the
  movies reach them, the way back to the level included, and drawn as the
  original draws them.

## Unknowns

- A native run from a level's or the map's start cannot reproduce
  `SaveLevel`'s copy of the level map's SRAM: it copies whole SRAM pages,
  and the bytes between the map's rows hold what earlier play left there.
  The run stops there ("the level map's SRAM not known whole"); the step
  check takes those bytes from the trace. A run from power-on knows them
  (`InitLevel` keeps the load's) and goes on through `SaveLevel` and the
  reset after it, `ResetAfterPauseMenuSave`'s `Init` ([the resets](resets.md),
  WL3-057), which the step check leaves to runs: it keeps no SRAM banks
  1-3.
- `wBossState` (`$cac3`) is not kept in the screens' RAM; `SaveLevel`
  copies it. It is 0 in the movie.
- Action Help from the menu is ported and checked on one movie
  (`title-pause-action-help-game-017`, [Action Help](action-help.md)); the
  Time Attack menu (no Save) and a transformation's menu are not met.
- The window draws the fades in as white (the palettes are modelled once
  a fade ends, [ADR-0002](../03-architecture/adr-0002-labelled-approximations.md)).
  Without `pause_menu.json` the level keeps its stand-in (it stands still
  until Start or Select).

## Tests

- `game/tests/unit/test_pause_menu_level.gd`: the menu, its input, the
  level's save and its checksums, the way out, and the menu's drawing (the
  counts, a transformation's tiles, Time Attack's maps and times, the
  palettes after the fade in), on invented data.
- `game/tests/unit/test_pause_menu.gd`: the routing with the menu's data.
- `tests/test_pause_menu.py`: the extractor on a synthetic ROM, its places
  and the port's framesets and RAM constants against the reference
  build's symbols.
- `make wario-parity` on `game-016` (step and run) and the other 16
  movies.
