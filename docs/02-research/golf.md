---
type: research
status: active
updated: 2026-10-23
tags: [research, content, validation]
---
# The golf minigame

**Question:** what does the golf minigame do, game loop by game loop, and
what does it leave for the level?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/golf/state_table.asm`, `lobby.asm`,
`hole.asm`, `src/home/load_golf_sprite.asm`, `src/home/return_level.asm`,
`src/home/fade.asm`, `src/constants/golf_constants.asm`, the "Golf RAM"
section of `src/ram/wram.asm`, `src/engine/golf/building/`); oracle traces
of the owner's four golf movies (`game-007`, `-008`, `-013`, `-014`) and of
`golf-building-invented` (from an invented save, item 10). Task: WL3-050.
The level's side (the door, the way back) is
[room transitions](room-transitions.md) item 5; the map's side of the golf
building is [the map](overworld.md).

## Verified observations

1. **States.** `_GolfStateTable` (72:4000) runs once a game loop while
   `wState` is `ST_GOLF` (5), by `wSubState`: a fade to white (0), the
   lobby (`InitGolfLobby` 1, a fade in 2, `HandleGolfLobby` 3), a hole (fade
   4, `InitGolfHole` 5, fade in 6, `HandleGolfHole` 7), the exit (fade 8,
   `ReturnToLevelFromGolf` 9), and the first clear's cutscene (fade 10,
   init 11, fade in 12, update 13). The fades are the level's
   (`FastFadeToWhite`, `SlowFadeFromWhite`: 33 loops each, `wFadeSpeed` 0).
   A hole has 14 states (`GolfHoleStateTable`: waiting, scrolling the view,
   the power gauge, the spin gauge, the swing, the shot, the bounce, special
   terrain, the walk, between shots, cleared, game over, pause, the course
   result); the lobby has 6 (waiting, walking right or left, the pipe, the
   door, out of the pipe).
2. **State in RAM.** Golf keeps its state in WRAMX bank 1 from `$d800`: the
   menu bytes (`w1d800` to `wGolfCourseScore`), and from `$db40` the hole's
   data (65 terrain blocks of 32 px, the par, the hole's x, two water
   spawns), the stroke number's tiles (`w1db90`), the counters and states,
   positions (little-endian; the Para-Goom's in quarter pixels), and nine
   8-byte objects (state, duration, frameset offset, frame, then the
   sprite's y, x, frame, attributes). `wGolfOAMPtr` and
   `wGolfWarioTilesPtr` are kept high byte first. Outside it golf reads or
   writes the sub-state, the joypad, `wSCX`/`wSCY`, the coins (`wNumCoins`,
   BCD), the treasure count (`wNumCollectedTreasures`, BCD: the price $10,
   $30, or $50 and the hole tier), the language (the coin message),
   `wIsMinigameCleared` (set at the first clear, which sends the cutscene),
   and the golf building's best scores; the rest is drawing (OAM, tiles,
   palettes) and sound.
3. **ROM data.** Animations step through (frame, duration) framesets
   (`UpdateGolfObjectAnimation`: the duration counts down from the stored
   value through 0, then the next pair; at `$ff` the first pair again, the
   last frame kept in `wGolfAnimLastFrame`): 49 named in the golf code, in
   banks $72, $05, $35, $7f, and home. `UpdateGolfParaGoom`'s table has six
   entries, so state 6 (sinking) reads the next two bytes as its pointer:
   `$4e23`, inside `Frameset_1c8e21`, a frameset of one pair (32, 4). A
   hole is picked from `GolfHoles` (72:4ac3) as `rDIV` modulo the tier's
   count (5, 10, or 15 holes by the treasures; `PickAndLoadGolfHole`), or
   the golf building's next hole, and its 70 bytes are copied from bank $70.
   `PrintGolfStrokeNumber` copies two tiles a digit from 72:640f into
   golf RAM. Extracted by `wl3pc.extract.golf` (`golf.json`).
4. **V-Blank.** Each loop installs a V-Blank function (`Func_1c9cf9` and
   `GolfLobbyVBlank` by `wGolfVBlankMode`, the fades their own), which runs
   once at the V-Blank after the loop. Those that load Golf Wario's tiles or
   the stroke number (modes 1-3) clear `wGolfVBlankMode` there; mode 0 in a
   hole steps the pin flag's animation counter (`w1dc0b`) when installed.
5. **The trace.** The tracer hooks `_GolfStateTable` and records, at every
   golf loop, the variables in item 2, the golf RAM's live part
   (`$d800`-`$d805`, `$db40`-`$dc9b`), and the virtual OAM (`wVirtualOAM`
   and its fill) as `golf_updates`, and counts each visit's loops
   (`golf_loops`). The frames alone cannot count them: the short loop that
   enters golf may run before or after its frame is sampled. Every 32nd
   loop of a visit it also takes both VRAM banks (`golf_vram`) and, at the
   end of that tick, the screen (`golf_screens`, gzipped RGB); the oracle
   renders only golf's ticks. Taken at the next loop's start instead, the
   screen's top rows were already the next frame's (five screens of 97 had
   their clouds shifted).
6. **Parity** (`make wario-parity`). From each traced golf loop the port
   runs one loop (and the V-Blank after it) and is compared with the next:
   all 9,297 compared loops of the four movies are identical (1728, 3463,
   2033, 2073; lobby, holes, water and out of bounds, the clear, the
   cutscene). With golf played natively on each loop's traced joypad, the
   transitions through golf take the original's game loops (1,729 to 3,464
   golf loops each) and match, and whole-frame runs go through every golf
   visit to the end of the four movies.

7. **Sprites.** `LoadGolfSprite` appends an object's frame from the OAM
   table in `wGolfOAMPtr` (golf's in bank $72, Golf Wario's in his state's
   bank) to the virtual OAM, its attributes xored by the object's;
   `ClearVirtualOAM` starts each screen, `ClearUnusedVirtualOAM` ends each
   loop's sprites (the lobby's init leaves Golf Wario's in place for the
   next loop). The port builds the same virtual OAM: equal in every
   compared loop of the four movies. (`ShowGolfScore` and the course
   result write digits into it; golf building only.)
8. **VRAM and the screen.** Each screen's init writes its tiles and maps
   (the lobby's tiles at `$8800` and map; a hole's flag tiles in bank 1,
   course tiles at `$8800`, Golf Wario idle at `$8000`, each BG map's hole
   rows from row 7 under its background rows, the flag's number, the par's
   digit at tiles `$2b`, `$4b`, `$6b`, `$8b`, the stroke number at `$f0`;
   the cutscene's tiles and map), and the lobby's price tiles. Then each
   loop's V-Blank function writes the coins' digits, Golf Wario's tiles
   (128 by DMA), the pin flag's frame (bank 1, `$9740`), the stroke number,
   or one BG attribute. The port follows them (`GolfVram`, from golf.json's
   graphics and golf RAM): all 289 VRAM snapshots of the four movies equal
   it on every byte golf wrote. Drawn as the CGB draws (`CgbScreen`: BG
   and window by LCDC, BG attributes, 8x16 sprites in OAM order with ten a
   line, BG-over-OBJ priority, 5-bit colours as PyBoy shows them), all 256
   screens compared (outside the fades and the inits) are identical to the
   original's, pixel for pixel: the lobby, the holes (scrolled, split by the
   window), the cutscene.

9. **The golf building.** With all seven crayons (`wCrayonFlags`
   `ALL_CRAYONS`, from treasures `$5e`-`$64`), the map's walk between
   North and West stops at the course (`Func_adbfe`), where A or up takes
   `LEVEL_GOLF_BUILDING`; `HandleOverworld` turns its `wLevel`
   (`GOLF_BUILDING`) into `ST_GOLF_BUILDING` (`$0a`).
   `_GolfBuildingStateTable` (72:4570) runs once a game loop by
   `wSubState`: a fade to white (0), the menu's set-up (`Func_1c8586`, 1),
   a fade in (2), the menu (`Func_1c86dd`, 3), a course's hole as in a
   level's golf (fade 4, `InitGolfHole` 5, fade in 6, `HandleGolfHole` 7),
   and `ReturnToMap` (8, after B in the menu, with no fade of its own: the
   map's first sub-state fades). The set-up starts the room animation's
   tiles (set `$0f`, a frame every 8 loops), saves the map's scroll and
   palettes (`SaveBackupVRAM`) when entered from the map (`w1d800` 0), sets
   `w1d800` to 1, clears golf RAM after the menu's two bytes, and notes
   whether all 25 musical coins are got (`CheckHasAllMusicalCoinFlags`),
   which opens the fourth course. In the menu (`w1dc00`), left and right
   scroll to the next course 4 pixels a loop (from the first to the third
   and back without the coins); the course's 7 attribute rows (labelled
   `GolfBuildingCourse1Tilemap` and on) and palettes go to golf RAM, then
   by HDMA and palette writes at V-Blank (three V-Blank functions, each
   clearing `wGolfVBlankMode`). A pays 50 coins (`GOLF_BUILDING_PRICE`,
   BCD) when there are enough (else only a sound), and the coins shown
   count down one a loop for `$32` loops before the course's first hole
   (`wPredeterminedGolfHole` 1, 6, 11, or 16). A course has five holes:
   `wGolfCourseHole` counts 0 to `NUM_GOLF_COURSE_HOLES` (4) before the
   last, although the constant's comment says four. Each hole allows 19
   strokes over its par; each cleared hole adds its strokes to
   `wGolfCourseScore`, and after the last `GolfHoleState_Result` shows the
   score against 20 (`GOLF_BASE_SCORE`) and keeps it in `wGolfBestScores`
   when lower; the menu's set-up then draws each best score as a sign and
   two digits (blank from 120 on, the value a save without scores holds).
10. **An invented save and a scripted movie.** No recorded save has every
    crayon, so `oracle_save --invent-crayons` stores `game-017`'s save with
    the seven crayon treasures set in both map saves, each checksum and
    echo moved by the same amount, labelled invented in the store
    (`cdf11db5…`); the original loads it as a save. From it
    `golf-building-invented` (8,800 ticks, `make continue-movie`) takes
    Continue, walks from the South side over the West side to the building
    (left three times on the South side, which leads to the West side's
    fourth level; down, left, and left to its first; left again), enters, scrolls
    right, left, left (the wrap to the third course), and right (the wrap
    back), pays for the first course with 66 coins, plays its five holes in
    15 strokes, sees the result (5 under), the menu with its best score,
    A with too few coins (16), and B out; the map saves, and Wario walks on
    to North. Each shot's presses were chosen by trying the power and spin
    timings on emulator save states (a planner in the session's scratch
    space); the movie keeps them in its description. A second invented
    save (`oracle_save --invent-musical-coins`, from the first: the 25
    musical coin flags and 999 coins, `8585f27d…`) opens the fourth
    course: `golf-building-courses-invented` (7,700 ticks) wraps left from
    the first course to the fourth, scrolls right around all four, plays
    the fourth's five holes (11 strokes), then pays for the first, pauses
    in its first hole (B back to play, then the pause again and A to quit,
    which goes back to the menu), and leaves with B.
11. **Traced and checked.** The tracer's `golf_building` layout hooks
    `_GolfBuildingStateTable` and records golf's variables with `wState`,
    `wTransitionParam`, the musical coin flags, and the animated tiles',
    the temporary palettes, and golf RAM from `$d800` (6 bytes) and from
    `wGolfHoleRAMStart` to the objects' end (the menu's course rows and
    palettes before the hole's data). `GolfSim.update_building` ports the
    table, on the screens' shared WRAM0 (the temporary palettes,
    `wTransitionParam`, `wTempBank`, the musical coin flags, the best
    scores). All 6,291 compared loops of the movie are identical (RAM,
    variables, OAM), and its way out; drawn (`GolfVram.load_menu`, the
    menu's V-Blank writes, and the room animation's tiles), all 196 VRAM
    snapshots and 177 screens (the menu and the holes) equal the
    original's. Natively from power-on (`MODE=run`), the title, the map,
    the building's 6,292 loops, the map, its save screen, and the map
    again equal the original at every loop (8,607 loops), nothing seeded.
    The checks met three things level golf never compared: the temporary
    palettes each screen's set-up loads (`LoadPalsToTempPals1` and `2`),
    the pin flag's frame copied into golf RAM (`UpdatePinFlagTiles`, to
    `wGolfPinFlagTiles`), and `wTempBank` (golf's last banked load, or
    Golf Wario's OAM table's bank), which the map reads after the
    building; all three are ported for level golf too. The second movie:
    all 5,260 compared loops and its way out, 164 VRAM snapshots, and 144
    screens identical; from power-on, 7,495 loops natively to the end.

## Interpretation

- Golf is self-contained: the level sees only the coins paid, the clear
  flag, and the time it took. Porting it whole lets the native game play
  it, drawn from its own VRAM model; the fades are drawn as white over it
  (approximations, as the level's).

## Hypotheses

- Translated but not met by a movie: the second and third courses' holes,
  a building course lost (`GolfHoleState_GameOver`), and over par
  (`GOLFRESULT_COURSE_OVER_PAR`). They are as unverified as the code says.

## Unknowns

- Para-Goom state 7 would read its frameset pointer from home code; no path
  sets it, and the port reports it as unported.
- The game window's drawing of a level's golf has not been compared with
  the original's (no movie starts at a golf level's own start); the
  renderer it uses has. The golf building's has (item 11, the window's
  screenshots). Golf's sound effects and music are not ported.

## Tests

- `tests/test_golf.py`: the extractor on a synthetic ROM, and every
  address against the reference build's symbols.
- `game/tests/unit/test_golf.gd`: animation stepping, the price, the walk to
  the pipe, a hole's start, the gauges, gravity and a bounce, the scroll;
  the golf building's set-up, its menu's scroll and wrap, its price and
  count down, B to the map, a kept best score, the best scores' drawing,
  and the window's fades into and out of the building.
- `tests/test_golf.py` also checks the building's data places and golf's
  WRAM0 constants against the reference build's symbols;
  `tests/test_title.py` the invented crayon save's bits and sums.
- `make wario-parity` on the four golf movies (step: `golf`, its VRAM and
  screens, the transitions; run: through each visit), and on
  `golf-building-invented` and `golf-building-courses-invented` (step:
  `golf_building`, its VRAM and screens, the way out; run: from power-on to
  the end).
