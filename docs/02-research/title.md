---
type: research
status: active
updated: 2026-10-18
tags: [research, validation]
---
# The title

**Question:** what does the title do from power-on to the start menu's
Continue or New Game, game loop by game loop, with a save and without,
and can the port play from power-on with a battery save, through the
title, into the map and the levels, equal to the original without taking
anything from a trace? Tasks: WL3-055, steps 2-4; WL3-056; WL3-058 (Time
Attack's description).

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/title/state_table.asm`,
`intro.asm`, `start_menu.asm`, `start_menu_selection.asm`, `load_gfx.asm`,
`load_oam.asm`, `vblank.asm`, `intro_animation.asm`, `plane_sfx.asm`,
`src/engine/language_selection/`, `src/engine/load_font.asm`,
`src/home/start.asm`, `fade.asm`,
`object_animation.asm`, `clear_memory.asm`, `clear_ram.asm`,
`src/ram/wram.asm`, and for a level's save `src/engine/level/init.asm`,
`start_room.asm`, `src/home/load_level.asm`, `decompress_level_data.asm`);
oracle traces of two power-on movies from `game-017`'s save
(`title-continue-game-017`, `title-continue-level-game-017`), one from
`game-016`'s level save (`title-continue-level-save-game-016`), and one
with no save (`title-new-game`).
The save's load before the title is in [the save's load](save-load.md).

## Verified observations

1. **States.** After `Init` (the RAM cleared, the save's load,
   `InitGameState`: `wState` and `wSubState` 0), `TitleStateTable`
   (01:402b) runs by `wSubState`: `FastFadeToWhite`, `InitIntroSequence`,
   `SlowFadeFromWhite`, the intro's three phases and `EndIntroSequence`
   (3-6), `StartMenu` (7, `SST_START_MENU`), then for Time Attack
   `SlowFadeBGToWhite`, `InitTimeAttackDescription`, and
   `TimeAttackDescription` (8-$0a); the rest are `DebugReset`. The tracer
   records each loop at `TitleStateTable.jump` (01:4039), as it does the
   other screens' tables (`tests/test_rom_integration.py`).
2. **With a save** (`wceef` not 0), `InitIntroSequence` loads the save's
   palettes (`Pals_5002`, `Pals_5042`), sets the plane's Wario at rest
   (108, 128) without animating him, gives the menu's rows BG priority and
   draws the box under them, and sets up the menu (`Frameset_6ce9`, or
   `Frameset_6d1e` in Time Attack) with Continue chosen.
   `IntroSequencePhase1` then goes straight to `StartTitleScreen`: the
   start menu, with Action Help's timer at 2,116 loops. On the movies the
   way takes 33 loops of fade, one of set-up, 33 of fade in, and one more:
   160 ticks after power-on with PyBoy's boot ROM.
3. **The counter.** `InitIntroSequence` clears `wGlobalCounter`, so the
   loop after it counts 1. A run counting loops by the counter must follow
   the counter each loop leaves.
4. **The start menu.** A starts the highlight's blink (`UpdateAnim2`: its
   palette steps 3, 0, 1, 0 every other loop, $10 steps), then the choice:
   Continue goes to the map (`StartOverworldState`, transition 0), or with
   a level's save (`wceef` bits 2-5) to `ST_LEVEL`. Down from Continue and
   up from Clear Data scroll the highlight a line a loop. Clear Data asks
   with No highlighted; left moves to Yes, right back to No. Yes is
   `ClearSaveData` (the check values cleared, then `Init`); No returns to
   Continue and asks `VBlank_Title` to redraw the box (`wcee4` bit 7).
   Start is not read. Left on New Game or Continue, the timer runs out and
   Action Help's demos open (`wPowerUpLevel` | `ACTION_HELP_TITLE_SCREEN`).
5. **Data.** `wl3pc.extract.title` decodes the 21 framesets, the two OAM
   tables (`OAM_6b5f`, `OAM_6d21`), the four palette sets, the compressed
   tiles and maps (`TitleScreenGfx`, `PlaneGfx`, `TitleScreenTilemap`,
   `TitleScreenAttrmap`), and `TitleScreenBoxTilemap`'s two rows of 12,
   each on its label (`tests/test_title.py`).
6. **A level's save.** `game-016` saves in its level and resets; the
   cartridge RAM at that reset, kept from the save load's capture, is
   stored as a save (`9e689797…`). Powered on with it, the title goes to
   the start menu as with a map's save, and Continue goes to `ST_LEVEL`.
   `InitLevel` then starts the level as the save left it
   (`StartRoom_FromLevelStart` with `wceef` bits 2-5): nothing reset and
   no objects set up (the save's WRAMX bank 1), the room
   `wTempLevelRoomID` names, Wario where and as he was (only his tiles
   reloaded, `LoadWarioGfx`), `LoadRoom`, the initial camera without its
   Y part in a room with transitions (`.check_if_saved_level`: the camera's
   Y keeps what RAM holds, which the save does not), no room objects
   spawned (`Func_896f`), and one `UpdateObjects` with
   `wIsFloorTransition` set. `DecompressLevelBlockMap` and
   `DecompressLevelObjectMap` return at once, so the level map is what
   SRAM banks 1 and 2 hold after the load. In this movie Wario resumes on
   a vine in level `$41`.
7. **Without a save** the intro plays. Phase 1 (sub-state 3): after 180
   loops Wario's plane flies in from the right to x 48, hovers 48 loops,
   bobs between y 64 and 70 three times, and flies off right; at x 192 it is set far away above. Phase 2 (4): after 28
   loops it drifts to the centre, hovers 48 loops, wobbles 224 loops, and
   explodes. Phase 3 (5): when the explosion's animation ends it nosedives
   (frameset changes at y 16, 48, 112), then follows the near layer until
   the layers align; when its last animation ends Wario rests and the
   title's palettes are loaded. Meanwhile the logo's parts drift right
   (`Func_4d45`) and three background layers scroll at different speeds
   (`ScrollIntroBackgroundLayers`, then `FinishIntroBackgroundScroll`);
   `PanIntroBackgroundLayers` writes rSCX mid-frame for them, in the
   H-Blanks after lines $5b, $63, $73, and $83. `EndIntroSequence` (6)
   waits 120 loops, then runs `SlowFadeInScreen` every 4 loops: 33 steps
   that take all 64 colours (`wTempBGPals` and `wTempOBPals`) a component
   at a time toward `wTempPals1` and 2. On the movie the phases take 792,
   568, 224, and 251 loops; the start menu follows at loop 1,902 with New
   Game chosen; A on it goes to the language selection
   (`ST_LANGUAGE_SELECTION`, `$0e`). The plane's sound repeats on
   `wSFXTimer` (12 loops, `play_sfx_rept`).
8. **The language selection** (`LanguageSelectionStateTable`, 01:4831,
   bank 1 with the title's RAM): `FastFadeToWhite`,
   `InitLanguageSelection` (the font's palettes in both sets, its tiles,
   the two text maps, English, the cursor at (70, 24), the scroll
   cleared), `SlowFadeFromWhite`, then `LanguageSelection`: down from
   English moves the cursor to Japanese (y 86), up back (y 70), and
   `VBlank_LanguageSelection` highlights the chosen row (palette 6 on 13
   entries of row 7 or 9, 7 on the other) when `wcee4`'s bit 7 asks; a
   move that cannot be made ends the loop before the cursor's animation.
   A goes to the map as a new game (`wTransitionParam` `$ff`), whose
   prologue (`InitPrologue`, `PrologueFunc`) is not ported.
9. **Time Attack's description** (WL3-058; a perfect game sets
   `MODE_TIME_ATTACK`, `src/engine/perfect/core.asm`, and no recorded save
   has it). Continue with it fades out (8), then
   `InitTimeAttackDescription` (9) clears the virtual OAM, loads `Pals_71b0`
   into `wTempPals1` and the BG palettes, the font to VRAM 1's `$8000`, $80
   tiles of the prologue's background (`2c:4f80`, uncompressed) to VRAM 0's
   `$9000`, and the text's two maps by `wLanguage` (English `01:73e6` and
   `01:74e8`, Japanese `01:71f0` and `01:7316`: the disassembly's labels
   for them are swapped against its file names), sets
   `VBlank_TimeAttackDescription` (the scroll and the OAM), and clears the
   scroll and `wTimer`'s first byte. `TimeAttackDescription` (`$0a`) waits
   for A, then the map (`StartOverworldState`); in Japanese each loop
   first moves the text's rows down mid-frame
   (`AdjustJapaneseTimeAttackDescriptionWindow`: rSCY plus 7 in the H-Blank
   after lines `$2f`, `$38`, `$41`, `$5a`, `$63`, and `$6c`). The evidence
   is two invented saves: `game-017`'s with `wGameModeFlags`' bit 1 set in
   both map saves (and, for the second, `wLanguage` 0), each checksum and
   echo moved by the same amount (`oracle_save --invent-time-attack`); the
   original loads them as Time Attack saves.
10. **Ported and checked.** `TitleSim` translates sub-states 0-$0a, and the
   language selection in its state,
   (with the intro branch of `InitIntroSequence`, which no movie reaches
   yet); `TitleVram` draws it. The run mode of the parity check starts at
   power-on when the movie does (`_power_on`): the save's load
   (`SaveLoad`) on the movie's battery save, the screens' RAM one with the
   level's and every byte known, and nothing seeded. `LevelRunner.power_on`
   does the same for the window (`make run SAVE=…`). `LevelSim` resumes a
   level from the SRAM the load left (`resume_level_with_camera`,
   `loaded_sram`). `TitleVram` draws the intro's layers from the
   lines its mid-frame writes reach (`CgbScreen.render`'s `scx_lines`) and
   steps the palettes with the fade at its end. A game state the port has
   no table for (the language selection, the credits) is named as not
   ported rather than run as a level. Results below.

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| Title loops, step (`title-continue-game-017`) | 141 of 142 loops, the way out | 0 |
| Its drawing | 4 VRAM snapshots (Init's VRAM among them), 2 screens | 0 |
| From power-on, run (`title-continue-game-017`) | 142 title and 556 map loops, nothing seeded | 0 |
| From power-on into a level and back, run (`title-continue-level-game-017`) | 142 title and 157 map loops, 67 loops into level `$70`, 1,217 whole level frames, then 796 pause menu (To Map, the save screen) and 368 map loops | 0 |
| The window from power-on (`--save`, `--screenshot`) | the title at loops 97 and 129 | 0 pixels of 23,040 each |
| A level's save, step (`title-continue-level-save-game-016`) | 141 title loops and the way out, 1,632 Wario updates, 1,688 camera runs and object updates | 0 (the resumed start is checked in the run) |
| A level's save from power-on, run | 142 title loops, 67 loops into level `$41` (resumed), 1,688 whole level frames | 0 |
| Its window (`--save`, `--trace` shifted to the title's first loop) | after 400, 1,350, and 1,500 ticks: Wario climbing down, walking, and jumping | 0 pixels of 23,040 each |
| No save, step (`title-new-game`) | 1,991 of 1,992 title loops (the intro, the start menu, New Game), the way out; 62 VRAM snapshots, 60 screens (the intro's layers and its fade) | 0 |
| No save from power-on, run | 1,992 title, 212 language selection, and 35 map loops from an empty cartridge RAM, to the prologue (not ported) | 0 |
| The language selection, step (`title-new-game`) | 211 of 212 loops (down, up, A), the way out to the map with `wLanguage`; 6 VRAM snapshots, 4 screens | 0 |
| Its window (the trace's joypad by loop) | after 2,100, 2,135, 2,150, and 2,180 loops | 0 pixels each |
| Its window (an all-zero save, as PyBoy's empty one) | after 500, 1,500, and 1,800 loops (aligned by the trace's loops: the original has lag frames) | 0 pixels; at 990, 998, 1,100, 1,200, and 1,300 loops 8 to 217 pixels, all in rows 12-26 (the moving sprites') |
| Time Attack's description, step (`title-time-attack-invented`, English; `title-time-attack-japanese-invented`) | 400 of 401 title loops each (the description's 250), the way out to the map; 12 VRAM snapshots and 10 screens each (the description's 8); the map after it in Time Attack, 887 and 387 loops | 0 |
| The same with the Japanese rows' scroll left out of the drawing | the Japanese movie's screens | 8 of 10 differ: the scroll is what makes them equal |
| From power-on, run | 401 title and 888 (English) or 388 (Japanese) map loops | 0, nothing seeded |
| Their window | after 199, 350, and 588 loops (the description twice, the map) | 0 pixels each (the Japanese at F−1) |

The second movie (`make continue-movie … PRESSES=…`) takes Continue,
enters the level the map's cursor is on, walks and jumps right, pauses,
and goes to the map, which saves. Its only seeds come after the level:
the pause menu's first loop takes the level's palettes, `wTempBank`, the
tile queue, and the virtual OAM, which the level's port does not keep
(`LEVEL_RAM_NOT_KEPT`, [ADR-0004](../03-architecture/adr-0004-one-ram-across-screens.md)).

## Interpretation

- The title's Continue path with a map's save or a level's save is a
  faithful port, and with the save's load ([the save's load](save-load.md))
  the game plays natively from power-on, a resumed level included: no part
  of the run up to the first level takes RAM from a trace.
- The step check cannot compare a resumed level's start: the save's
  objects and level map are not in the trace before it. The run from
  power-on compares it (Wario, the camera, the room's animation, and the
  object slots entering the first `UpdateObjects`).
- Two traces from one save are a narrow sample. Clear Data's question, the
  scrolling, and Action Help's timer are unit-tested on invented data
  only.

## Unknowns

- The prologue after the language selection (the map's cutscene,
  `src/engine/overworld/bank2b_2.asm` and around) is not ported.
- The window's intro differs from the original's frames at some loops in
  the moving sprites' rows only, while the traced screens (every 32nd
  loop, drawn by the step check from the same model) all match. A guess
  not yet checked: the window draws a loop's sprites with the layers'
  scroll of the loop before.
- Time Attack's description is checked on invented saves only: no real
  Time Attack save exists here. `ClearSaveData`'s reset and Action Help's
  demos from the title are ported ([the resets](resets.md), WL3-057).
- The music and sound effects are not ported.

## Tests

- `game/tests/unit/test_shared_ram.gd`: a level resumed from a save
  (Wario kept, the map from SRAM, the camera's Y kept), on invented data.
- `game/tests/unit/test_title.gd`: the way to the start menu with and
  without a save, the intro (the plane, the layers and their lines, the
  logo's parts, the fade's step), New Game and the language selection
  (its moves, its drawing, the new game), a state with no port named, Continue into the map or a level's save's level, the
  scrolling, Clear Data's Yes and No with the box redrawn, Action Help's
  timer, `LevelSim`'s routing, the drawing, `LevelRunner.power_on`, and
  Time Attack's description in English and Japanese (its load, its wait
  for A, its rows' scroll), on invented data.
- `tests/test_title.py`: the extractor on a synthetic ROM and against the
  reference build's labels, the port's framesets and RAM constants, the
  continue movie's presses, the power-on save a run takes, and the
  invented Time Attack save's sums.
- `tests/test_oracle.py`, `test_rom_integration.py`: the title's trace
  layout and hook.
- `make wario-parity` on the title's movies, step and `MODE=run`.

## Next experiment

Done: the prologue ([the prologue](prologue.md)), the resets
([the resets](resets.md)), and Time Attack's description. Next: the map
and the levels in Time Attack, when a movie plays them (the map's
Time Attack parts match on the two movies above; the levels' clock,
`TickLevelTime`, is not ported).
