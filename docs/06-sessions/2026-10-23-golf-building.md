---
type: session
status: done
updated: 2026-10-23
tags: [session, validation]
---
# 2026-10-23: The golf building and the map's menus and Temple (WL3-050, WL3-052)

The owner asked the agent to continue where the last session stopped and
to keep Git and the vault clean. No new owner's movies had been recorded,
so the session took the other pointer: golf's building.

## Outcomes

- No recorded save has every crayon, which the golf building needs, so
  `oracle_save --invent-crayons` stores an invented one: `game-017`'s save
  with the seven crayon treasures (`$5e`-`$64`) set in both map saves,
  each checksum and echo moved by the same amount, labelled invented in
  the store (`cdf11db5…`). The original loads it as a save.
- `golf-building-invented` (`make continue-movie`, 8,800 ticks from
  power-on) takes Continue, walks from the South side over the West side
  to the building, enters, scrolls the menu both ways and wraps, pays for
  the first course, plays its five holes in 15 strokes, sees the result
  and its best score on the menu, presses A with too few coins, leaves
  with B, saves on the map, and walks on to North. The holes' presses
  were chosen by a planner in the scratch space that tried each shot's
  power and spin timings on emulator save states; the movie's description
  keeps every press.
- The tracer's `golf_building` layout hooks `_GolfBuildingStateTable`
  (72:4570); the trace schema has its keys.
- `GolfSim.update_building` ports the table: the menu's set-up
  (`Func_1c8586`, `Func_1c8604`, `Func_1c87db`), its loop (`Func_1c86dd`,
  `Func_1c882b`, `Func_1c86f8`, `Func_1c9fae`), and `ReturnToMap`; the
  courses' code was translated before and now meets the oracle. Golf keeps
  its WRAM0 bytes in the screens' shared RAM (the temporary palettes,
  `wTransitionParam`, `wTempBank`, the musical coin flags, the best
  scores). `LevelSim` runs it in `ST_GOLF_BUILDING`; the golf extractor
  (version 4) adds the menu's maps, the courses' attribute rows, and the
  menu's framesets; `GolfVram` draws the menu with the room animation's
  tiles; the window draws the building and the fades into and out of it.
- The step check found what level golf's checks never compared, all
  ported for level golf too: the temporary palettes each golf screen's
  set-up loads, the pin flag's frame copied into golf RAM, and then, in
  the run, `wTempBank` at the map's first loop after the building.
- The run harness found one gap in itself, not the port: two menu loops
  ran in one frame, and a loop's room animation calls were taken by frame,
  so the first got none and the second both. A loop that shares its frame
  with the next now takes the frame's first call of each kind
  (`_run_untraced`).
- `_menu_screen_step` and the run's seeding take any `ScreenSim`
  (`ram_known` on the base class), so the building reuses them.

- After the commit: a second invented save (`oracle_save
  --invent-musical-coins`: every musical coin and 999 coins) opens the
  fourth course. `golf-building-courses-invented` wraps to it, scrolls
  around all four, plays it, then pays for the first and quits it from its
  pause. It matched at once in every loop and natively; the step check's
  way out did not: its last loop shared a tick with the loop before, so
  the first frame sampled out of the building showed that loop before its
  room animation. `_menu_screen_exit` now takes the next frame then, whose
  counter is the next loop's.

- Then the map's top bar and the treasure collection (WL3-052), which no
  movie had opened: `map-collection-game-017` (from `game-017`'s save,
  `make continue-movie`) opens the bar with Select, browses it, takes the
  previous map side, opens the collection, moves, turns pages three ways
  (the left edge, A with right, the right edge), leaves, and plays the
  last event's cutscene again from the bar. The step check named
  `UpdateTopBar`'s states and sub-states `$0c` to `$0f` as not ported.
  `UpdateTopBar` and its helpers are translated (`OverworldLoop`, the
  buttons and objects in `OverworldMapSide`), and the collection in a new
  `OverworldCollection`; `record_wram_to_vram` now keeps the BG map 0
  model in step, as `decompress_to_vram` does, since `InitMapSide` reads
  the bar's rows back from VRAM. Both matched at once.
- Then Time Attack's best times (WL3-052): `map-best-times-invented` from
  the invented Time Attack save opens the list with Start, lets it scroll
  by itself, scrolls by hand, and leaves. `_InitBestTimeList`,
  `_BestTimeList`, and `PrintBestTimes` are translated (in
  `OverworldCollection`); it matched at once. The list's first scroll
  reads `wObj1SubState`'s address, which in the map's WRAM bank is
  `wCurMapSide`.
- Then the top bar's Day/Night Spell: `oracle_save --invent-treasures`
  (general; the crayons' option now uses it) stores `game-017`'s save
  with the spell (`$4d`, labelled invented); `map-day-night-spell-invented`
  casts it twice. The step check found one translation error: the bar's
  last day/night state ran `VBlank_Overworld`'s effect where the code
  calls `VBlank_Overworld`, which installs the map's V-Blank function
  again (the second cast's DMA config was left set). Fixed.
- Then the Temple's scene: `map-temple-game-017` walks from South over
  West and the golf building to North, enters the Temple, and leaves.
  `OverworldTemple` translates `_InitTempleScene` (its regular scene),
  `_UpdateTempleScene`, and `LoadNextObjectiveText` on the prologue's text
  printer; it matched at once (after one slip of operator precedence in
  the name's address, caught before the first check).

- Then, the owner asking to go on without recording unless needed: the
  East side, opened by an invented save with the Ornamental Fan
  (`map-east-invented`), matched with no change; and the hidden figure's
  reveal was reached with an invented save with the five music boxes
  (`map-temple-reveal-invented`), sized (about 2,600 lines with the shake
  and rocks).
- Then the reveal itself: `HiddenFigureRevealScene` and its sub-scenes
  (the music boxes, Wario's panic, the shake scene, the figure's mouth) in
  `OverworldTemple`, and `_HandleTempleShakeAndRocks` in a new
  `OverworldTempleRocks` (written by a forked agent from bank `$56`,
  reviewed and wired here). The tracer hooks the rocks' 13 further rDIV
  sites (the macros' three reads expanded to 16). The step check found
  three things: scene Wario's walks miss the callers' `ld [hl], a`, which
  sets an odd x even on arrival (the regular scene too, which no movie had
  shown); the map's step check fed no rDIV reads at all, and a frame
  cannot say which of two loops in it made a read, so each screen loop in
  a trace now records how many reads came before it, and each map loop
  takes exactly its own; and `SetTempleRockSize` keeps 9 in `b`, not the
  size (`ld a, $9` before `ld b, a`), so a big rock's state is `$09` to
  `$0b`. With those all 7,528 map loops matched. The window can now
  replay a trace's reads (`--div-reads`), for checks of what rDIV decides.
- The notes had said the reveal's movie starts the fight at tick 7,602:
  that was an earlier emulator exploration with one more press. The
  movie ends waiting at step `$28` for A. `map-temple-fight-invented`
  adds A at 7,600 and reaches the fight (level `$c8`, extracted with
  `wl3pc.extract.level_collision --level 0xc8`). The step check showed
  the hidden figure's slots as differing, not as unported:
  `UpdateObjects_Temple` returned before the unported slots were set;
  now they count as not ported.
- Then the fight itself. A delegated agent translated `hidden_figure.asm`
  into `HiddenFigureFunctions` (a stub wired into the chain first, so the
  two of us edited different files); it named what its file needed
  outside it (the object WRAM to `$d162`, three object params, the hands'
  paths in bank `$13`), all checked against the symbols and added. Here:
  the Temple's object group, `UpdateObject(s)_Temple`, the Hidden Figure
  camera (scroll, Wario's screen position), interactions `$4f`, `$50`,
  `$52`, `check_end_screen`'s game over and epilogue (with the water
  current's clears and Time Attack's clear screen, which it had left
  out), and `ST_EPILOGUE`. The tracer traces the fight's five WRAM0
  values and ends a Hidden Figure frame's camera run at `.asm_8227`
  (without it the run found no level). The step check's level start took
  `wLevel` from the frame before the level, which the map's last loop
  changes in the tick it enters it; it now takes the level's own. All
  matched with no change to the agent's translation.

## Tests

- `golf-building-invented`, `make wario-parity`: golf building 6,291 of
  6,291 compared loops and its way out, 196 of 196 VRAM snapshots, 177 of
  177 screens identical; title 141, map 2,025, pause menu (the map's save)
  144 compared loops, all identical, with their drawing. `MODE=run`: from
  power-on 8,607 screen loops (title 142, map 2,028, golf building 6,292,
  pause menu 145) to the end of the trace, all identical, nothing seeded.
- The window from power-on with the invented save, the movie's joypad by
  loop: after 1,662 and 1,854 loops (the menu), 2,750 (a hole), 7,806 and
  7,838 (the menu with the new best score), and 8,101 (the map after the
  building's save), 0 of 23,040 pixels differ from the original's screens
  at the same loops. Windows the Wayland desktop stopped drawing stalled
  (the window's clock takes at most 4 ticks a drawn frame); run with
  Godot's `--display-driver x11 --disable-vsync` they finish in real time,
  with the same images.
- The owner's four golf movies, step and `MODE=run`: as before (9,297 golf
  loops, 289 VRAM snapshots, 256 screens; runs to the end). `make smoke`
  and `make smoke-level` OK.
- Godot 358 passed (7 for the building); Python 268 passed (the invented
  save, the layout's ranges, the building's data places, golf's WRAM0
  constants); `make test-rom` 34 passed.

- After `9c892b8`: the owner's 17 movies, the 13 power-on title movies,
  `new-game-ootw`, and `golf-building-invented`, step and `MODE=run`: all
  32 pass, as before.
- `golf-building-courses-invented`, step: 5,260 of 5,260 golf building
  loops and its way out, 164 of 164 VRAM snapshots, 144 of 144 screens;
  `MODE=run`: 7,495 loops from power-on to the end of the trace. The
  window after 1,950 (the fourth course chosen), 3,614 (its hole), 6,366
  (the menu after it), 6,590 (the pause), and 6,814 loops (the menu after
  the quit): 0 pixels differ each.

- `make sweeps` on `9c892b8` (the golf building): all 34 sweeps
  unchanged, every update identical, all 11,082 movies to the end.
- `map-collection-game-017`, step: 3,396 of 3,396 map loops, 106 of 106
  VRAM snapshots, 97 of 97 screens identical (the bar, the collection, its
  links and pages, the scenes of the cutscene played again); `MODE=run`:
  3,539 loops from power-on to the end. The window after 365 (the bar),
  1,005 and 1,805 (the collection, links shown, a page turned), and 2,541
  loops (the map with the bar after it): 0 pixels differ; after 2,189,
  144 pixels of the cursor's corners, and after 2,188 none: two loops had
  shared a tick just before, so the original's screen there is a loop
  behind its count.
- Godot 362 passed (4 for the bar and the collection); Python 269 passed.
- `map-best-times-invented`, step: 1,974 of 1,974 map loops, 61 of 61 VRAM
  snapshots, 55 of 55 screens identical; `MODE=run`: 2,376 loops from
  power-on to the end. The window after 976, 1,360, 1,744, 2,128, and
  2,320 loops (the list idle, scrolling by itself, by hand, and the map
  after it): 0 pixels differ each. Godot 363 passed (1 for the list).
- `map-day-night-spell-invented`, step: 1,555 of 1,555 map loops, 48 of 48
  VRAM snapshots, 47 of 47 screens identical; `MODE=run`: 1,698 loops from
  power-on to the end. The window after 589, 717, and 1,069 loops (the
  spell cast, night, the second cast): 0 pixels differ each. Python 270
  passed (the invented treasures).
- `map-temple-game-017`, step: 3,319 of 3,319 map loops, 103 of 103 VRAM
  snapshots, 100 of 100 screens identical; `MODE=run`: 3,462 loops from
  power-on to the end. The window after 2,125, 2,317, 2,509, and 2,605
  loops (Wario walking in, the text printing and printed, leaving): 0
  pixels differ each. Godot 364 passed (1 for the objective text).
- With the bar and the collection: the owner's 17 movies, the 13 power-on
  title movies, `new-game-ootw`, both golf building movies, and
  `map-collection-game-017`, step and `MODE=run`: all 34 pass.
- `make sweeps` on `a76dab0` (the bar and the collection): all 34 sweeps
  unchanged, every update identical, all 11,082 movies to the end.
- `make sweeps` on `281ab1f` (the best times and the spell): all 34 sweeps
  unchanged, every update identical, all 11,082 movies to the end.
- With the Temple: all 37 movies (the 35 above, the spell's, and the
  Temple's), step and `MODE=run`: all pass.
- `make sweeps` on `e56820b` (the Temple): all 34 sweeps unchanged, every
  update identical, all 11,082 movies to the end.
- `map-east-invented`, step: 866 of 866 Wario updates, 1,813 object slot
  updates, 866 interaction runs, 797 of 797 map loops and the way out, 24
  VRAM snapshots, 23 screens; `MODE=run`: from power-on 940 screen loops,
  the way into E1, and 866 whole frames, all identical.
- `map-temple-reveal-invented`, step: 1,922 of 1,922 map loops before the
  reveal; the reveal's 5,605 loops named as not ported.
- With the reveal ported, retraced (the screen loops' rDIV counts),
  step: 7,528 of 7,528 map loops, 235 of 235 VRAM snapshots, 229 of 229
  screens identical; `MODE=run`: 7,671 loops from power-on to the end.
  The window after 3,085 loops (the music boxes): 0 pixels differ. After
  4,813, 6,157, and 7,501 (rocks falling, the panic, the figure's text)
  with rDIV random, 4,228, 719, and 1,039 differ (the rocks, and the later
  steps behind: they wait until every rock has stopped, whose respawn
  times rDIV sets); with the trace's reads replayed
  (`--div-reads`), 0 each. Godot 368 passed (4 for the rocks, the shake,
  the walk's arrival, and B's skip); Python 270 and `make test-rom` 34
  passed (the rDIV sites' count); `make smoke` OK.
- With the reveal: all 39 movies (the owner's 17, the 13 power-on title
  movies, `new-game-ootw`, both golf building movies, and the six map
  movies), step and `MODE=run`: all pass; the older traces, without the
  rDIV counts, are checked as before.
- With the best times: the 34 movies above and `map-best-times-invented`,
  step and `MODE=run`: all 35 pass (the spell's fix, in a bar state none
  of them reaches, came during it; its own movie is checked above).

- `map-temple-fight-invented`, step: map 7,364 of 7,364 loops and 2 of 2
  ways out, 230 VRAM snapshots and 223 screens; the save 92 of 92 loops;
  title 141; Wario 442 of 442 level updates; the Temple's objects
  (1,768 slot updates), interactions `$4f`, `$50`, `$52`, and the
  objects' level-start spawn named as not ported. `MODE=run`: from
  power-on 7,474 screen loops to frame 7,603, where the Hidden Figure
  camera is not ported. Godot 368 passed.

- `make sweeps` on `38478fe` (the reveal): all 34 sweeps unchanged,
  every update identical, all 11,082 movies to the end.
- With the fight, `map-temple-fight-invented` (retraced), step: Wario
  442 of 442, objects 1,768 of 1,768 slot updates, interactions 442 of
  442 (32 with an effect), camera 442 of 442, the level start and its
  objects identical, map 7,364 and save 92 loops; `MODE=run`: from
  power-on 7,474 screen loops, 67 into the level, 442 whole frames, then
  127 screen loops (map 34, save 93) to the end, seeding the map's
  `wTempPals`, OAM, and `wTempBank` and 6 save-screen bytes, which the
  fight's unsimulated palettes and graphics write. Godot 378 passed (6
  for the hidden figure, 4 for the fight's way out), Python 270,
  `make test-rom` 35 (the camera hook), `make smoke` OK.
- With the fight: all 40 movies (the 39 above and the fight's), step and
  `MODE=run`: all pass.
- `make sweeps` on `8f5a166` (the fight, with the level end's clears):
  all 34 sweeps unchanged, every update identical, all 11,082 movies to
  the end.
- Then the fight's other paths, statically: a planner in the scratch space
  (random timings on save states) found a smash attack that knocks a hand
  loose (`map-temple-knock-invented`); no grab of it followed in 1,500
  random tries, because a knocked hand is heavy and the save's power-up
  level is 2. `oracle_save --invent-power-ups` (every power-up treasure,
  level 9, the count recounted) gave a save where the planner's first try
  grabbed it and its 254th threw it into the face
  (`map-temple-hit-invented`). Both matched in every update, step check,
  and from power-on natively (592 and 611 whole fight frames), with
  nothing changed in the port. Python 271 passed (the inventor).
- Then the whole fight: the planner (`fight_plan3.py` in the scratch
  space) waits for a swipe, knocks, grabs, and throws, four times; its
  first knock goal took a hand still flagged from the last knock, and
  after a knock the other hand slams, so it now waits for a swipe and
  looks for a hand newly knocked. `map-temple-win-invented` wins; its
  step check met Wario's state `$4d` (the fence shake slide, ported
  then) and the run its setter, which the run harness calls between its
  checkpoints too. Step: Wario 2,545 of 2,545 updates (20 states), slot
  updates 10,180 of 10,180, interactions 2,545 of 2,545, camera 2,545;
  map 7,406 loops, with the epilogue's scene and sub-states `$23`-`$26`
  named as not ported. `MODE=run`: 2,545 whole fight frames natively,
  then 72 map loops to `NOWFunc_Prologue`. Godot 378 passed.
- Then the epilogue, by two delegated agents at once on stub classes wired
  first (`OverworldNorthEpilogue` before `OverworldOWFunctions`,
  `OverworldEpilogue` after `OverworldTemple`), each checking its own loops
  with the map's step check, which loads each loop's RAM from the trace.
  Here: the map extractor's four more banks, the OW functions' shared steps
  moved into the earlier class (the agent had kept copies), and the
  constants renamed after their labels (`test_the_maps_ram_constants_are_
  the_labels_they_name`). A 44-movie recheck run while the agents edited
  failed on parse errors of their files mid-edit; it is rerun below.
  `map-temple-ending-invented` adds A presses through the text and reaches
  the save screen and the credits. Step: map 13,557 of 13,557 loops, 423
  VRAM snapshots, 396 screens (with the epilogue's sub-states $25 and $26
  now compared); save 604 loops, 18 snapshots, 9 screens;
  `MODE=run`: natively from power-on to the credits (6,832 screen loops
  after the level), seeding the map's `wTempPals`, OAM, and `wTempBank`
  after the fight as before. Godot 390 passed (12 for the two scenes),
  Python 271. All 45 movies (the 40 above, the knock, the hit, the two
  hits, the win, and the ending), step and `MODE=run`: all pass.
- The tracer's `credits` layout (`_CreditsStateTable`, bank $58: the
  temporary palettes, the page, the text buffer and its pointers, the
  timers, w3d500 to wMenuObj1's end) records them:
  `map-temple-credits-invented` (the ending to tick 30,000) has 12,767
  credits loops: `ShowCredits` from 17,300 to 22,029, sub-states 4-7 to
  23,960, and `Func_160365` (8) to the end. Not ported yet.
- `make sweeps` on `54a29ba` (the slide, the epilogue, the credits'
  layout): all 34 sweeps unchanged, every update identical, all 11,082
  movies to the end.
- Then the credits, by one delegated agent end to end (extractor,
  `CreditsSim`, `CreditsVram`, `LevelSim`'s state, the harness's
  `_credits_step` and run, the report line, unit tests, the research
  note), checked here. The run's first credits loop found 66 bytes the
  level leaves in the RAM the credits share (the BG tile and address
  queues, `wBGPtr`): the port does not keep them, so the run harness's
  `LEVEL_RAM_NOT_KEPT` now covers them and seeds them when first seen
  (105 bytes at the credits' first loop). The title's fade in
  (`SlowFadeInScreen`) moved to the screens' base classes to be shared.
  `map-temple-credits-invented`, step: credits 12,766 of 12,766 loops,
  398 VRAM snapshots, 331 screens; `MODE=run`: 2,545 fight frames and
  19,599 screen loops after it natively (credits 12,767) to the end.
  Godot 399 passed, Python 276, `make test-rom` 35. All 46 movies (the
  45 above and the credits'), step and `MODE=run`: all pass.
- `make sweeps` on `8147821` (the credits, the harness's seeding): all 34
  sweeps unchanged, every update identical, all 11,082 movies to the end.
- Then a perfect game, statically. A save with all 100 treasures
  (`--invent-treasures` with 1 to 100, then `--invent-power-ups` to
  recount them: `4dd1761d…`) has every crayon, so the golf course stops
  Wario between West and North; a route search on save states
  (`route_plan*.py` in the scratch space) found North's way to the Temple
  from there (left, up, right, A), and the planner won the fight again
  (its last two hits needed whole cycles retried; and a press a failed
  cycle had left in its output, held past the resumed planner's start,
  made the first recording lose: the planner now cuts prefix presses at
  its start). `map-temple-all-treasures-invented` loses the fight there
  (then the save and the game over screen); `map-temple-game-over-invented`
  loses it and presses A through the game over screen to its reset;
  `map-temple-perfect-game-invented` wins, plays the perfect epilogue, the
  credits (6,900 loops), and `Func_160365`'s 180 loops to `ST_PERFECT`.
  All their compared map, save, credits, and fight updates match.
- The tracer's `game_over` and `perfect` layouts record those screens. The
  game over screen, by a delegated agent: 328 and 439 loops, 23 VRAM
  snapshots, 17 screens; the run stops at `GameOverReset`'s `Init` after
  the unsaved level (SRAM not kept whole, as `resets.md` says). Godot 405,
  Python 281.
- Then the Perfect screen, by the same agent: `map-temple-perfect-game-invented`
  matches in all 2,703 loops, 84 VRAM snapshots, and 84 screens, and runs
  natively from power-on to its end (credits 6,901, Perfect 2,704 loops
  after the fight). `wUnused_c186`, which the fades set and clear, is kept
  by `PerfectSim` only (no other screen's trace records it). Godot 412,
  Python 286, `make test-rom` 35. The route search's six scratch movies
  were deleted. All 49 movies (the owner's 17, the 13 title movies,
  `new-game-ootw`, both golf building movies, and 16 map movies), step
  and `MODE=run`: all pass (`map-temple-game-over-invented`'s run stops
  at its reset's `Init`, as described).
- Then the Perfect screen's other way in and out: `oracle_save
  --invent-game-cleared` (`MODE_GAME_CLEARED` and the fought flag) on the
  perfect game's save (`d87e3e67…`); `map-perfect-after-clear-invented`
  enters the first level, takes To Map (Start, three rights: the menu is
  horizontal; two-tick presses, as a one-tick Start was lost), and the
  map's save goes to the Perfect screen; A there takes the pause menu's
  `SST_PAUSE_28`, the save again, and `ResetAfterSave`. Sub-states
  `$28`-`$31` are now ported (the save screen's steps, then `Init`): 983
  of 983 save loops, 29 VRAM snapshots; their screens differ from the
  original's over 6,000 to 7,000 pixels (a layer the model's fixed
  registers do not show), so they are left uncompared. Godot 413, Python
  287.
- Not done: a window check of the credits. The scratch window script
  builds its per-loop input from the screens' traced loops only, which
  drifts once a movie plays a level; the run harness's per-loop input
  would have to be handed to the window first.

## Next action

WL3-048 as the owner records more. Otherwise the fight's unreached paths
(a planner that fights, or the owner's play), its drawing, or golf's
fades.
