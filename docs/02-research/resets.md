---
type: research
status: active
updated: 2026-10-28
tags: [research, validation]
---
# The resets

**Question:** where does the game jump back to `Init`, what does a reset
keep, and can the port reset the way the original does, so that native play
goes on from the title as it would after power-on? Task: WL3-057.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/home/start.asm` `Init`,
`InitWithoutDemoPowerUpReset`, `.GameLoop`; `src/home/clear_save.asm`;
`src/home/clear_ram.asm`; `src/engine/title/start_menu.asm`;
`src/engine/action_help/core.asm` and `power_ups/*.asm`;
`src/engine/pause/save/save.asm` `ResetAfterPauseMenuSave`;
`src/home/decompress_level_data.asm`; `src/engine/level/switch.asm`
`UpdateSwitchableBlocks`; `src/engine/game_over/core.asm` `GameOverReset`); oracle traces
of four power-on movies from `game-017`'s map save (`f695f6cd…`, recorded
with `make continue-movie`): `title-demo-game-017` (the start menu left
alone, 6,500 ticks), `title-clear-data-game-017` (Clear Data's Yes),
`title-reset-map-game-017` (Continue, then A, B, Select and Start held on
the map, then Continue again), and `title-save-level-game-017` (Continue,
into Out of the Woods, the pause menu's Save, the reset after it, Continue
into the level it resumes); and `title-demos-all-game-017`, the start menu
left alone for 43,000 ticks: all 13 demos, each ending in a reset. And
two resets after a level played and not saved, from invented saves
(labelled): `map-temple-game-over-invented` (the hidden figure's fight
lost, the map's save, the game over screen, `GameOverReset`) and
`map-perfect-after-clear-invented` (the first level left by the pause
menu's To Map, the map's save, the Perfect screen, its save,
`ResetAfterSave`), with each load's RAM and SRAM captured by
`wl3pc.oracle_save` (at `ValidateSaveData` and `InitGameState`); and
`title-reset-level-game-017` (`make continue-movie` from `game-017`'s save,
`PRESSES=200:a,400:a,600-1600:right,700:a,900:a,1100:a,1300:a,1500:a,1700-1710:a+b+select+start,2100:a`,
3,000 ticks: into Out of the Woods, A, B, Select and Start held in the
level, then Continue).

## Verified observations

1. **The ways in.** `.GameLoop` resets after `UpdateJoypad` when
   `wResetDisabled` is clear and A, B, Select and Start are all held: that
   loop runs no state. The title's Clear Data, Yes, jumps to `ClearSaveData`,
   which clears 8 bytes at `sCheckVals`, `sBackupCheckVals`, `s0a000`,
   `s0a800`, `s0a400` and `s0ac00` (every slot's start), then `Init`.
   Action Help opened from the title (`ACTION_HELP_TITLE_SCREEN`) jumps to
   `InitWithoutDemoPowerUpReset` at a demo's end and on closing.
   `ResetAfterPauseMenuSave` (the pause menu's sub-state `$10`, after the
   level's save's complete box) jumps to `Init`. `DebugReset` (the state
   tables' empty entries) is not met.
2. **What `Init` does.** It clears the stack, both VRAM banks, WRAM0 but the
   stack, WRAMX banks 1-7, OAM, and HRAM but `hDemoPowerUp`, `hUnused_fffd`
   and `hCGB` (`Init` itself clears `hDemoPowerUp` first;
   `InitWithoutDemoPowerUpReset` skips that), fills BG map 0 with `$7f`,
   clears BG map 1, runs `ValidateSaveData` on SRAM as it is now and
   `InitGameState` (the title, sub-state 0), then enters `.GameLoop`. The
   loop that jumped never ends (no V-Blank wait, counter step, or room
   animation); the next is counted 0, and its `UpdateJoypad` sees every
   held button as pressed (`wJoypadDown` was cleared).
3. **It takes frames.** In `title-demo-game-017` Action Help's last loop
   (counter 77) is traced at tick 3282; the frames keep counter 77 to tick
   3284, show the WRAM clear from 3285 (the sample there has `wState` 0 but
   `wPowerUpLevel` still `$42`: half cleared), and the title's first loop
   (counter 0) is traced at 3301. A frame sample inside `Init` is no
   reset's result.
4. **The demos.** Left on the start menu with a save, the title opens
   Action Help (its first loop at tick 2278) with its title-screen flag;
   the demo's power-up is Wario's moved on by `hDemoPowerUp`, which it
   moves on (0 to 1). Its end resets the game keeping it: the start menu is
   back at tick 3375 with `hDemoPowerUp` 1, the next demo starts at 5491
   (1 to 2), and the start menu is back at 6187.
5. **The four-button reset is not a screen's loop.** In
   `title-reset-map-game-017` the map's last traced loop is counter 208 at
   tick 600; the frames at 601-603 show counter 209 with `wJoypadDown`
   `$0f`, and the WRAM cleared from 604. Only the frames record that loop's
   joypad.
6. **The SRAM a reset loads.** After the level's save, `Init` loads the save
   just made: SRAM bank 0 as `SaveLevel` wrote it, banks 1 and 2 the level
   map as played (`SaveLevel`'s backup copied rows 32-47 over rows 48-63),
   bank 3 the backup. The bytes `DecompressLevelBlockMap` never writes (each
   row's `$a0`-`$af`) are what the SRAM held before the level: rows 0-47 as
   the last load left them.
7. **What a level writes to SRAM.** `DecompressLevelBlockMap` and
   `DecompressLevelObjectMap` write the map's 48 rows (blocks `$00`-`$9f`,
   object map `$b0`-`$ff`); `UpdateSwitchableBlocks` scans rows 0-47
   only (bank 2 to `$b000`). Between power-on and the reset in the two
   movies above, the original's SRAM changed in bank 0 (24 and 22 bytes,
   the map's save) and in rows 0-47's blocks and object map only (6,409
   and 7 bytes); the unwritten bytes, rows 48-63 (bank 2's second half:
   `SaveLevel`'s backup in `game-017`'s save, 2,573 non-zero bytes), and
   bank 3 were as the load left them. `ValidateSaveData` at those resets
   changed one byte (`$aff8`) and left banks 1-3 as they were.

## Ported and checked

`LevelSim.init_game` runs `Init` in place: a `LevelSim` made as power-on
makes one (the screens' data loaded again from their documents,
`LevelRunner.load_power_on_ram` on the SRAM as it now is), whose state the
running one takes, but the extracted data and what a parity run feeds it
(`KEPT_BY_INIT`); `hDemoPowerUp` is kept for the demos. A state's loop asks
for it (`request_init`: `ClearSaveData`, the demos' ends, Action Help's close
on the title, `ResetAfterPauseMenuSave`) and it runs once the loop is done,
with no room animation; `update_level` checks the four buttons first.
`hDemoPowerUp` is now the `LevelSim`'s (HRAM, which the title and Action
Help share). `LevelSim.loaded_sram` keeps all four SRAM banks the last load
left, and `level_map_sram` whether a level was played since (`InitLevel`)
or saved (`SaveLevel`): `current_sram` gives the SRAM as it now is, the
level map as played or as saved from the `LevelCollision`, or nothing when
a byte of the map is not known (no load before the level; then `Init` is
noted, not run). `InitLevel` gives a level without them the SRAM's bytes
it never writes, from the load: each row's unwritten bytes and rows
48-63's blocks (`_keep_sram_unwritten_bytes`; an extracted level has them
zero), so `SaveLevel`, the reset after it, and a reset after a level not
saved run natively from power-on.
`LevelRunner.frame` takes pressed from `wJoypadDown`, as `UpdateJoypad`
does, so a reset's cleared joypad counts. The window forgets the screens'
VRAM on a reset (`LevelView`).

The parity check follows: a visit's last loop that resets is compared with
the title's first loop after `Init` (its variables, its RAM ranges, byte for
byte), the step check loading the movie's power-on save (it keeps no SRAM
of its own; right while no save was made before); a loop no screen recorded
whose frames show the four buttons takes that joypad (`_reset_joypad`);
level visits keep a reset's title with the visit it left, so a run compares
what the reset loaded; and the pause menu's and the game over screen's
resets are left to runs, which know the SRAM. A run from power-on also
compares each load it makes (power-on's, then each reset's) with the
original's when `wl3pc.oracle_save` captured the movie's loads
(`local/captures/save-load/NAME-loadN.json`): SRAM banks 0-3 after
`ValidateSaveData`, byte for byte (`_check_loads`).

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| The demos, step (`title-demo-game-017`) | 4,747 of 4,747 title and 1,595 of 1,595 Action Help loops (two demos), both resets' ways out, 196 VRAM snapshots, 186 screens | 0 |
| The demos, run from power-on | 6,347 screen loops through two resets (4,750 title, 1,597 Action Help) | 0, nothing seeded |
| All 13 demos, step (`title-demos-all-game-017`) | 29,341 of 29,341 title and 13,149 of 13,149 Action Help loops, 26 ways out (13 resets), 1,320 VRAM snapshots, 1,263 screens | 0 |
| All 13 demos, run from power-on | 42,517 screen loops through 13 resets (29,355 title, 13,162 Action Help) | 0, nothing seeded |
| Clear Data's Yes, step and run (`title-clear-data-game-017`) | 3,081 title loops and the way out, 95 VRAM snapshots, 89 screens; run: 3,083 title loops, the reset, the intro without the save, the start menu | 0 |
| Four buttons on the map, step and run (`title-reset-map-game-017`) | 910 map and 550 title loops, 3 ways out, 44 VRAM snapshots, 38 screens; run: 1,464 screen loops through the reset | 0 |
| The level's save and its reset, step (`title-save-level-game-017`) | 1,217 and 1,888 Wario updates, 659 of 660 pause loops (the reset left to runs), 156 map and 348 title loops, 3 ways out | 0 |
| The same, run from power-on | the title, the map, 67 loops into the level, 1,217 whole frames, 660 pause loops (`SaveLevel`, the reset), 208 title loops after it (Continue); then the second visit's 1,888 frames from its first update | 0 (after the level the pause menu's 134 bytes, OAM, and `wTempBank` seeded, as in every run) |
| The SRAM at that reset | the port's (`current_sram`) and the original's at its `ValidateSaveData` (the save-load capture of the movie) | 0 of 32,768 bytes |
| The window, `--save` with the movies' joypad by loop (not run on the 43,000-tick movie: the window plays in real time) | the demos after 2,300, 2,900, 3,276, 3,376, 5,470, and 6,246 loops; the map's reset after 397, 572, 772, 963, 1,363; Clear Data's after 406, 2,382, 2,982 | 0 pixels each (at F−2 or F−1) |
| | Clear Data's after 582 and 1,382 loops (the intro without the save) | 144 and 116 pixels, rows 13-26: the intro's moving sprites, as in [the title](title.md#unknowns) |
| The owner's movies, step and run | 34 checks | as before (`game-016`'s reset after its save named as left to runs) |
| After a lost fight, run from power-on (`map-temple-game-over-invented`) | 142 title and 8,585 map loops, the fight's 1,165 whole frames, then 34 map, 101 save screen and 440 game over loops, `GameOverReset`'s `Init`, 3,378 title and 13,753 map loops (Continue) to the trace's end | 0 (seeded after the level as in every run) |
| After a level left by To Map, run from power-on (`map-perfect-after-clear-invented`) | 142 title and 157 map loops, 518 level frames, then 34 map, 1,072 Perfect, and 985 save screen loops (both saves), `ResetAfterSave`'s `Init`, 2,184 title and 669 Action Help loops (a demo) to the trace's end | 0 (the same) |
| Four buttons in a level, step (`title-reset-level-game-017`) | 1,216 Wario, object, interaction, and camera updates; 1,011 map and 550 title loops, 3 ways out, 46 VRAM snapshots, 40 screens | 0 |
| The same, run from power-on | 142 title and 157 map loops, 67 into the level, 1,216 whole frames, the reset (`Init` from the level's frame, tick 1,709), then 410 title and 856 map loops (Continue) to the trace's end | 0, nothing seeded |
| The SRAM those runs load | power-on's and each reset's, against the original's after `ValidateSaveData` | 0 of 32,768 bytes, each of the 6 loads |

## Interpretation

- The resets are ported: the title's demos, Clear Data, the four buttons,
  and the level's save go back to the title as the original does, and the
  game goes on natively from what `Init` loaded.
- So do resets after a level played and not saved (the game over's, the
  save's after the Perfect screen, the four buttons within a level): the
  level map the port keeps (blocks, unwritten bytes, object map) is SRAM's
  banks 1 and 2 as played, once `InitLevel` takes the bytes it never
  writes from the load.

## Unknowns

- A level writing rows 48-63 (a block broken or an object's nibble below
  the map): not seen; the port would keep it in its map as the original
  keeps it in SRAM (provisional).
- `DebugReset` is not met. The music and sound effects (`Init`'s
  `InitAudio`, the four-button reset's `TurnMusicOff`) are not ported.
- A run that does not start at power-on does not know the SRAM: its resets
  would stop it, and `game-016`'s stops before, at its `SaveLevel` (the
  level map's unwritten bytes, [the pause menu](pause-menu.md)).

## Tests

- `game/tests/unit/test_init.gd`: Clear Data's Yes (the save gone, the
  title from its start, the counter), the demos' reset keeping
  `hDemoPowerUp` and `Init` clearing it, the four buttons with resets
  allowed and not (the joypad cleared after), the SRAM after a level's
  play (and not known without its unwritten bytes) and after its save,
  and what a level from a load takes from SRAM, on invented data.
- `game/tests/unit/test_title.gd`, `test_pause_menu_level.gd`: the jumps to
  `Init`; `tests/test_level_visits.py`: a reset's title kept with its visit.
- `tests/test_title.py`: a run's captured loads, in order.
- `make wario-parity` on the four movies, step and `MODE=run`; on
  `map-temple-game-over-invented`, `map-perfect-after-clear-invented`, and
  `title-reset-level-game-017` after `python -m wl3pc.oracle_save` with
  their names (the captures).

## Next experiment

None for the resets; Time Attack's description is done too (WL3-058,
[the title](title.md)).
