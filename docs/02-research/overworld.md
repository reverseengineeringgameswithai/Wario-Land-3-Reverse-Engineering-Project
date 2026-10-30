---
type: research
status: active
updated: 2026-10-23
tags: [research, validation]
---
# The map

**Question:** what do the owner's movies do on the map and in the pause
menu's save, game loop by game loop, and what must a port of them cover?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/overworld/`, about 37,200 lines:
`state_table.asm`, `init.asm`, `bank20.asm` to `bank2d.asm`, the cutscenes,
the treasure collection, the best times, the temple; `src/engine/pause/`
with `save/`, about 3,200 lines; `src/constants/state_constants.asm`);
oracle traces of the owner's 17 movies. Task: WL3-052.

## Verified observations

1. **States.** The map is `ST_OVERWORLD` (1): `OverworldStateTable`
   (20:4392) runs once a game loop by `wSubState`: the fade and
   `InitOverworld` (0-1), which picks what follows the level (the map side,
   an unlock's cutscene, a scene), `InitOWScene` and its scene (5-7, with a
   fade between scenes at 4), the map side (`InitMapSide` 9, its loop
   `Func_805d7` $b, fades 8 and $a), the treasure collection ($c-$10), the
   cutscenes ($11-$15), the best times ($16-$19), the temple ($1a-$1d),
   `Func_80e33` ($1e: B held goes back to the map side, otherwise on), the
   golf building ($1f-$22), and the epilogue ($23-). Its RAM is WRAMX bank
   2, all of it (471 labels, with the treasures and `wOWLevel`).
2. **The movies' map.** Each movie starts on the map side (`$b`) and walks
   to its level; after the level, `InitOverworld` leads to the map side
   (`9`-`$b`) directly, or first through an unlock's cutscene (`$11`-`$15`,
   nine movies) and scenes (`5`-`7`, up to four; twelve movies). Five
   movies visit the golf building from the map side (`$1e`-`$22`). Over the
   17 movies the map runs 19,531 loops: the map side's loop 5,689, the
   scenes' 7,384, `UpdateCutscene` 3,117.
3. **What the movies reach** (from the traced WRAMX bank 2). On the map
   side, `Func_80e89`'s own state (`w2d013`) runs 0 to 9 of its 11; the top
   and bottom bars are never opened (`wOWBarsState` 0 in all 5,689 loops),
   and the east side never shows (north, west, and south do). The events
   after the levels are `$02`-`$0b` (the tree cut, the north gate, the
   tornado, the lead overalls, the rainstorm, the elevator, the yellow
   music box, the seeds, the tower, the swimming flippers), `$26` (the blue
   crayon), and `$27` (the cart wheels): nine with a cutscene
   (`DoCutsceneFunc`: `Cutscene02Func` and the others, bank `$27`), and
   scenes with the actions `UNLOCK_LEVEL`, `DO_OW_FUNC`,
   `HIGHLIGHT_LEVEL`, and `SPECIAL_ACTION`.
4. **The save.** Every movie ends on the map after a save. The map's save
   screen has no menu: the game runs it in the pause menu's state table
   (`wState` 4, `ST_PAUSE_MENU`) at `SST_PAUSE_18` ($18-$21:
   `InitSaveScreenAndBackupVRAM`, `FillSaveScreenBar`, `Save` at $1d,
   `HandleSaveCompleteBox`, `TransitionAfterSave`) and goes back to the map
   side (`8`-`$b`). `Save` writes SRAM bank 0 in one loop: 14 to 30 bytes
   in these movies (the save counter, the progress, the checksums and
   their echoes). Only `game-016` opens the pause menu itself, in The Pool
   of Rain (sub-states 0-3), and saves from it there
   (`SST_PAUSE_MENU_SAVE`, $8-$10: `SaveLevel` writes 1,176 bytes, then the
   reset).
5. **The trace.** The tracer records each `OverworldStateTable` and
   `_PauseMenuStateTable` (7c:4000) call like the other screens': the
   variables they share with the game, their RAM (the map: the temporary
   palettes, the progress WRAM from `wSaveCounter` to `wcaa1`'s palettes,
   WRAMX bank 2 whole, `w3d500`; the pause menu's table, with the save
   screens: the same progress, the
   level time, the tile queue, the checksums, the treasures, `w3d280`'s
   palettes, the menu objects, and SRAM bank 0 whole), the virtual OAM, and
   VRAM and the screen every 32 loops. A RAM range's address says which
   memory it is (SRAM from `$a000`, WRAM0 from `$c000`, WRAMX from `$d000`).

6. **The save screen, ported.** `PauseMenuSim` translates the save
   screen's sub-states ($18-$21): the fades, the backup of the map's
   scroll and palettes into WRAMX bank 3 (`SaveBackupVRAM`), the bar (a
   tile every 4 loops, nine, drawn by the V-Blank function from the queue),
   `Save` (the save counter; into SRAM bank 0 `"war3"`, the progress WRAM,
   the treasures, and their 16-bit sum with two echoes, then all again as
   the backup; the markers it steps through left at 0), the complete box (A
   or 512 loops), and `TransitionAfterSave` back to the map at
   `wPendingSubState`. On a `MenuScreenSim` that now keeps SRAM bank 0, it
   is checked like the other screens: all 2,494 compared loops of the 17
   movies are identical (variables, RAM, SRAM, OAM), and all 18 ways back
   to the map. Drawn (`SaveScreenVram`: the box, Wario asleep, the bar,
   the palettes the fades in end on): all 71 VRAM snapshots and 44 compared
   screens match. The pause menu itself and the level's save from it are
   ported too ([the pause menu](pause-menu.md)).
7. **The map, ported.** `OverworldSim` translates every map sub-state the
   movies reach: what follows a level (`InitOverworld`), the nine unlock
   cutscenes, the scenes' actions and the OW functions they run, the map
   side (`InitMapSide`, and its loop with the walk along the paths, the
   level names, the day/night transitions, the animations, the scene
   objects, the bottom bar, the arrows, and entering a level), and the golf
   building's entry, with what the V-Blank functions write to RAM. Its data
   is the ROM banks it reads, kept whole (`wl3pc.extract.overworld`, 23
   banks): its tables are followed through their pointers as the original
   follows them, and its maps decompressed with the same RLE. All 19,478
   compared map loops of the 17 movies are identical (WRAMX bank 2 whole,
   the progress, the palettes, the OAM), and all 36 ways out (into the
   levels, the save screen, golf); the other 53 are those ways out and each
   movie's last loop. Subagents translated it in parts (the map side's set
   up, its loop, the scenes, the cutscenes, the golf building), each part
   checked against the movies before the next; the merge of two parts
   found one copy of `SaveGameOrEnterPerfectScreen` testing a flag's bit
   number for its mask, and kept the other.
8. **The map, drawn.** `OverworldSim` records, reading its RAM only, what
   each loop and its V-Blank function write to the hardware: the set-ups'
   decompressions and copies from the kept banks (the side's, common,
   arrow, and cutscene tiles, the bars' and cutscenes' maps, the golf
   building's `PrologueBackgroundGfx`, the cart wheels' level tiles),
   `WriteBGMapFromWRAM` and `FillBGMap0_With7f`,
   the V-Blank functions' copies (`Func_1d8c2c`'s clouds, sea, and cliffs,
   the level's name, `wHDMA`), `DrawCoinCount`'s digits from `NumbersGfx`,
   the palettes their `pal_config_struct`s and the transitions write, and
   rLCDC and the window. `OverworldVram` (`game/scripts/present/`) applies
   them in order and steps the fades' palettes as `FadeBGToWhite` and
   `DarkenBGToPal` do (`src/home/fade.asm`, with `VBlank_88d` storing the
   palettes and `VBlank_8bf` loading them back after every loop but the
   last). `DarkenBGToPal` decrements a channel with `dec [hl]` and stops
   only at zero, so a channel already at 0 wraps to `$ff` and stays above
   its target; the model does the same. Checked like the other screens on
   the 17 movies: all 586 VRAM snapshots match on the bytes the model
   wrote, and all 460 compared screens are identical pixel for pixel.
   Screens are compared on visits entered from a level, which set up all
   they show, and on returns from the save screen, whose `LoadBackupVRAM`
   puts VRAM back as the map left it, with the palettes white after its
   last fade. A movie's first visit starts on the map with VRAM the movie
   never shows being set up, so it is checked on the written bytes only.
   A sub-state's first loop and the level's fade out (sub-state 0, whose
   palettes are the level's) are not compared. The window draws the map
   and its save screen from the same models (`LevelView`), and `main.gd`
   loads `overworld.json` with the other screens' data.

9. **Played natively.** From each movie's first map loop, the map, the
   way into the level, the level, and the screens after it run natively
   from the movie's input and equal the original at every traced loop
   ([native play](native-play.md)).

10. **The top bar and the treasure collection.** Select at a level opens
    the top bar (`UpdateTopBar`, `wOWBarsState`): the bottom bar closes
    (1, 2), the buttons are set up (the collection selected; their tiles
    and attributes in `wAttrmap`'s rows 19 to 22, sent to BG map 0's row
    30 by the two DMA configs at V-Blank; the selected button and the
    NEXT MAP sign are `wOWUIObj1` and `wOWUIObj2`, sprites of `OAM_a9fe2`),
    and the BG scrolls up 2 lines a loop to `$ec` (3). Then (4) left and
    right pick a selectable button (right past the last is swallowed, left
    past the previous map is not), A presses it, and B or Select closes
    the bar (5). A pressed button waits 30 loops or A (6 to 8): the last
    event's cutscene again (`wStoredTransitionParam`, through the map's
    first sub-state and its scenes), the treasure collection, or the next
    or previous map side (with `UpdateTopBar.Indices`' level). The
    collection (`_InitTreasureCollection`, `_TreasureCollection`, bank
    `$26`; sub-states `$0c` to `$0f`) shows five pages of 20 cells on BG
    map 1: each treasure got in its palette (`TreasureOBPals`), the others
    as a box; the d-pad moves the cursor (a page on at the sides; a page
    turn fades out and sets up again), A held with right or left turns
    the pages, B goes back to the map side with the bar still open
    (`InitMapSide` then sets the bar's buttons up again); a cursor left 20
    loops on a cell shows the cells linked to it (`CollectionLinkTable`)
    as scene objects 2 to 8. `map-collection-game-017` (from `game-017`'s
    save) browses the bar, goes to the previous map side, opens the
    collection, moves, turns pages three ways, leaves, and plays the last
    cutscene again from the bar: all 3,396 compared map loops identical,
    106 VRAM snapshots and 97 screens equal the original's, and from
    power-on 3,539 loops natively to the end. The Day/Night Spell's button
    (`DoDayNightSpell`, states 9 to `$0b`) needs the spell (treasure `$4d`,
    which `game-017`'s save lacks): `map-day-night-spell-invented`, from
    that save with the spell set (`oracle_save --invent-treasures`,
    labelled), casts it twice, night and back to day, through the map's
    day and night transition: all 1,555 compared loops, 48 VRAM
    snapshots, and 47 screens equal the original's, and 1,698 loops
    natively from power-on. Its first translation ran `VBlank_Overworld`'s
    effect where the code calls it, which installs the map's V-Blank
    function again; the second cast's DMA showed it.

11. **Time Attack's best times.** In Time Attack, Start on the map side
    (`Func_80de0`) opens the list of the levels' times (sub-states `$16`
    to `$19`: `_InitBestTimeList`, `_BestTimeList`, bank `$56`): each
    level's time from `wLevelTimeAttackScores` as five tiles (built in
    `w2df00`) written to BG map 0 by `PrintBestTimes`, the scroll at the
    half with the current side's levels (the code reads `wObj1SubState`'s
    address, which in WRAM bank 2 is `wCurMapSide`). Up and down scroll it
    a line a loop between 0 and `$70`; after 256 loops without the d-pad
    it scrolls by itself (down, a wait of `$b4` loops, up, a wait, and
    over) until a press stops it; B or Start leaves to the map side.
    `map-best-times-invented` (the invented Time Attack save,
    [the title](title.md)) opens it on the South side, lets it scroll by
    itself through every phase, stops it, scrolls by hand both ways, and
    leaves: all 1,974 compared map loops, 61 VRAM snapshots, and 55
    screens equal the original's, and from power-on 2,376 loops natively
    to the end.

12. **The Temple's scene.** A at the Temple (North's level 0) runs
    sub-states `$1a` to `$1d` (`_InitTempleScene`, `_UpdateTempleScene`,
    bank `$2b`): the Temple's palettes, the font, its tiles and BG maps
    (copied, not compressed), the hidden figure's text (by the language)
    with the next objective's lines (`LoadNextObjectiveText`: by
    `GetMapSideAndLevelForNextTreasure`'s side and level, in English the
    name after the text's second line, in Japanese before it); Wario walks
    in from x `$e8` to `$50`, turns his back, nods, and the text prints as
    the prologue's (`PrintTextWithHeader`, through `VBlank_PrologueEpilogue`;
    nothing when the next objective is the Temple itself); B or left
    clears the text box and sends him out, B leaving at once while he
    walks. Scene Wario's place is written through `w1d140` and
    `wDollBoyNoFlashingBarrel`, bank 1 labels whose addresses in WRAM bank
    2 are his. With the gold music box the hidden figure's reveal is set
    up instead (not ported, named as such). `map-temple-game-017`
    (`game-017`'s save: the next objective The Pool of Rain) walks to the
    Temple, enters, presses A while the text prints, leaves with B, and
    presses up at the Temple (the map's own hint, state `$0a`): all 3,319
    compared map loops, 103 VRAM snapshots, and 100 screens equal the
    original's, and from power-on 3,462 loops natively to the end.

13. **The East side.** It opens with `EVENT_BLOW_MIST` (the Ornamental
    Fan, treasure `$21`). `map-east-invented` (`game-017`'s save with the
    fan, `oracle_save --invent-treasures`, labelled) walks right off the
    South side onto the East side, opens and closes the top bar there, and
    enters E1, The Stagnant Swamp: all 797 compared map loops, 24 VRAM
    snapshots, and 23 screens equal the original's, its way into the
    level too, and from power-on the map and 866 whole level frames run
    natively, with nothing changed in the port (its East side code had been
    translated without a movie).
14. **The hidden figure's reveal.** With the five music boxes (`$01` to
    `$05`; `map-temple-reveal-invented`, labelled) the Temple plays the
    reveal (`HiddenFigureRevealScene`'s 41 steps, bank `$2b`): Wario walks
    in, the music boxes rise and hover, the screen shakes and rocks fall
    (`_HandleTempleShakeAndRocks`, bank `$56`), Wario panics, the figure's
    hands and mouth move through two text pages, A closes the last
    (step `$28`), and the fight starts (`SetFightAgainstAHiddenFigure`,
    step `$29`). Ported in `OverworldTempleRocks` and `OverworldTemple`:
    `map-temple-reveal-invented` ends waiting at step `$28` (its last A
    is at tick 7,500); all its 7,528 compared map loops, 235 VRAM
    snapshots, and 229 screens equal the original's, and from power-on
    7,671 loops natively to the end. `map-temple-fight-invented` (the same
    with A at 7,600) runs steps `$28` and `$29` into the fight (level `$c8`
    from frame 7,603), and after it the map and the save: all 7,364
    compared map loops and both ways out match, and from power-on the run
    goes natively through the fight and back to the map and the save
    ([objects](objects.md) item 85). What the port had wrong on the way:
    - Scene Wario's walks (`ApplySceneWarioMovementRight`/`Left`) return
      x with its low bit off; the caller's `cp x; ret nz; ld [hl], a`
      writes that back, so an odd x is set even on arrival (the regular
      scene's walk in too).
    - `SetTempleRockSize_WithLarge`/`_WithoutLarge`: after `ld a, $9`,
      `ld b, a` keeps 9, not the size, so a medium or large rock is state
      `$09` plus rDIV's low bits (`$09` to `$0b`, frameset by state), not
      the size plus them.
    - The rocks read rDIV (16 sites, the macros' three reads expanded;
      `DIV_READS` in the tracer). The trace's screen loops now record how
      many reads came before each, so the step check feeds each map loop
      exactly its own.
    Translated but not reached: B skipping the reveal once a hidden figure
    has been fought (`MODE_FOUGHT_A_HIDDEN_FIGURE`, a unit test only).

15. **The ending: the North side's scene and the epilogue** (WL3-052,
    translated by two delegated agents from the win's movie and checked
    here). After the fight is won the map plays the North side's scene
    (`NOWFunc_Prologue`, OW function `$12`, `OverworldNorthEpilogue`): the
    screen shakes (`Func_b71fc`), scene object 1 changes, and six scene
    objects rise away (`Func_15868e`, bank `$56`, with its rDIV read).
    Then sub-states `$23` to `$27` (`OverworldEpilogue`): a fade,
    `_InitEpilogue`, a fade in, and `Func_af13c`'s 32 steps: a Spearhead,
    a Doughnuteer, and a Hammer-bot each turned into another form under a
    falling star (`Func_15848a`), the crowd and clouds, the old man
    walking in and talking a page at a time on A, carried up and off, and
    Wario in the forest picking him up and walking off; then the map's
    save (`Func_803e6`). The map extractor (version 4) keeps banks `$60`,
    `$61` (the creatures' OAM tables), `$68`, and `$69` (their
    graphics). `map-temple-win-invented` stops at the second page's A;
    `map-temple-ending-invented` (the same with A every 40 ticks from
    12,960 to 16,480) plays the epilogue to its end, the save screen, and
    the credits (`ST_CREDITS`, from tick 17,227, not traced or ported).
    All 13,557 compared map loops, 423 VRAM snapshots, 396 screens (the
    epilogue's among them), and 604 save-screen loops equal the original's; from power-on the run
    goes natively through the fight, the epilogue, and the save to the
    credits. Kept quirks: `.Func_af353` advances `wSubState` but leaves
    `w2d013`; `Func_aca25` whitens all 8 palettes of `wTempPals2` (its
    count is in 2-byte steps); `_InitEpilogue` reads the font's tiles back
    from VRAM into `wAttrmap` and later copies them back with the old
    man's bank set; `.Func_b72f8` falls into `.Func_b7300`; the risers
    start in the order `wd153`, `wd152`, `wd155`, `wd154`, `w2d151`.

## Interpretation

- The map's movies-reached part is a faithful port; the rest (the other
  events' cutscenes and OW functions) is either translated but unchecked
  (noted in each file) or noted as not ported.

## Hypotheses

- Translated but no movie reaches them: the East side's other levels and
  paths (only E1 is open with that progress), Time Attack's map beyond the
  best times, the Day/Night Spell on the East side (the Sun
  Medallion), the full crayon set's golf building paths other than the
  one `golf-building-invented` takes (from West: Wario stops at the course,
  A takes the building, he comes back in front of it, left sends him on to
  North; [golf](golf.md) item 10), the music boxes' other cutscenes, B
  skipping the hidden figure's reveal once one was fought; they are as
  unverified as the code says.

## Unknowns

- The window's drawing of the map is checked only through the parity
  script's renders, not on the desktop. Native play started with
  `make run` begins in a level with no save's progress, so the map it
  reaches is not the original's (WL3-055).

## Tests

- `tests/test_overworld.py`: the banks kept whole on a synthetic ROM, and
  the map port's RAM constants (over 200) against the reference build's
  symbols.
- `game/tests/unit/test_overworld.gd`: the ROM view and its RLE, the fades,
  the hand-over to the save screen, the level's routing, the top bar's
  d-pad and scroll, the collection's cursor and page turns, its boxes
  for the treasures not got, and the best times' scrolling.
- `game/tests/unit/test_overworld_drawing.gd`: on invented data, a set-up's
  decompression and the coins, `VBlank_Overworld`'s copies and palette
  config, the fades' palettes (with `DarkenBGToPal`'s wrap), the LCD's
  registers, a rendered tile, and the view's hand-over to and from the save
  screen.
- `make wario-parity` on the 17 movies (step: the map's every loop, its
  ways out, and its drawing).
- `tests/test_pause_menu.py`: the save screens' extractor on a synthetic
  ROM, and their data and the port's RAM and SRAM constants against the
  reference build's symbols.
- `game/tests/unit/test_pause_menu.gd`: the backup, the bar, the save and
  its checksums, the complete box, the way back, the routing, the drawing.
- `make wario-parity` on the 17 movies (step: the save screen, its way out
  and drawing).
- `tests/test_oracle.py`: the layouts' variables and ranges against the
  reference build's symbols, and the range reader's memory.
- `tests/test_rom_integration.py`: each layout's hook is its state table's
  dispatch.
