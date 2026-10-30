---
type: project
status: active
updated: 2026-10-28
tags: [project]
---
# Tasks

The single backlog. IDs are stable and never reused. Priority: P1 (next),
P2 (this milestone), P3 (later). Status: todo, active, blocked, done.
Milestones are in the [roadmap](roadmap.md).

Evidence references use the ElectroDeoxys disassembly at commit `560fce6`,
which is byte-identical to the identified ROM
([ROM identity](../02-research/rom-identity.md)). Banked addresses (`BB:AAAA`)
come from the local reference-build symbol file.

## Open

### WL3-043 The level's end (P2, in progress)

- **Depends on:** WL3-040 (done)
- **Evidence:** after the treasure scene the game leaves the level
  (`wState` 3, the clear screen, then the overworld at frame 6799 of the
  owner's movie); `UpdateLevel.check_end_screen` is ported up to the
  state change, and the clear screen is named as unported. The pause menu
  was a stand-in (drawn since 2026-10-18, WL3-052), and the treasure's palette
  (`LoadCollectedTreasurePal_Level`) is not ported.
- **Acceptance:** the native run goes on from the treasure scene to the
  level-clear screen as the original, or the scope boundary is recorded in
  an ADR.
- **Progress:** the clear screen is translated (`ClearSim`;
  [clear screen](../02-research/clear-screen.md)): the treasure screen, the
  musical coin screen with its pencil, Time Attack's screen, and the way
  out to the map or Action Help, recording the treasure, the counts, the
  power-up, and the musical coin flags. The tracer records its every loop;
  all 4,098 compared loops of the owner's 17 movies are identical, and all
  17 ways out. It is drawn (`ClearVram`, `CgbScreen`): all 119 VRAM
  snapshots and 73 compared screens equal the original's. Action Help after
  it is ported (WL3-051); the map is not.

### WL3-048 The battles in the oracle (P1, todo)

- **Depends on:** WL3-047 (done)
- **Evidence:** the bosses, the Shoot minigame, and some devices are
  translated, but the scripted movies reach only their starts. The
  sweeps never reach these paths: Muddee out of the water; Jamano's
  knocked skulls, the exposed Jamano, and his hat; Shoot's ball form,
  kicks, and goals and both defeats; the variable cart with the Truck
  Wheel; Wormwould's palm trees; and the parts objects items 65-73 name
  as not reached ([objects](../02-research/objects.md), items 65-78).
  Unit tests on invented data cover some of them; none has met the
  oracle.
- **Acceptance:** movies (longer or targeted scripts, or movies the
  owner records with the TAS editor) that fight each boss and play the
  minigame, traced and swept, with every update they reach compared and
  identical, or each remaining gap named in the research note.
- **Progress:** longer movies (`TICKS=n`, named `-tN`), `left-attack`,
  and seeded wanders (`wander-sN`): 176 movies of 3600 ticks in the 11
  boss rooms, every update identical, reach Shoot's ball form, Scowler's
  swallow, Yellow Belly's arrow hit, and Wolfenboss's Igaguri and Kuri
  (objects item 79). Not reached: the later phases and defeats, Muddee's
  battle, Jamano's knocked skulls, and the Shoot game's kicks and goals.
  These need inputs that actually fight: targeted scripts per room, or
  movies the owner records. The traces take about 60 MB each (11 GB so
  far; the disk is 96% full). A coverage-guided search (`search-sN`,
  emulator oracle item 17) explores the rooms in 44 movies of 7200
  ticks, every update identical, but reaches no new object function, even
  rewarding new values of the battle variables.
  Next: the owner records the game as a chain of movies, one per level
  visit ([owner's movies](../04-development/owner-movies.md): how they are
  recorded, named, renamed, and checked).
  Seventeen so far (`ootw-gray-key`, `game-002` to `game-017`): with the
  level start, the hand, the ladder slide's ground pound, `Func_ba42`'s
  spawn, the unlit torch, reads above the map, and a visit at a time for
  movies that enter several levels, every compared update of every movie
  matches, and with golf ported (room transitions item 5, WL3-050), all 17
  run whole frames to the end. What remains: drawing golf, and a level
  resumed from a save (its start is not checked; emulator oracle item 18).
  The hidden figure's fight (the Temple, level `$c8`) is ported
  (2026-10-23): `map-temple-fight-invented` loses it with no input, and
  every Wario, object, interaction, and camera update matches, natively
  too, with the map and the save after it. Inputs a planner found (from
  an invented save with every power-up) knock a hand loose, throw it
  into the face, and win the fight: all match, and the run goes natively
  from power-on through the win, the map's epilogue, and its save to the
  credits, which are not ported ([objects](../02-research/objects.md)
  item 85, [the map](../02-research/overworld.md) item 15).

### WL3-049 Left-facing coverage (P1, in progress)

- **Depends on:** WL3-047 (done)
- **Evidence:** every sweep script but `wander` holds Right, so code met
  only going left (blocks, objects approached from the right) is not
  reached.
- **Acceptance:** left-facing sweeps (`left-jump`, `left-attack`) of the
  room starts and the level variants, with what they meet ported and
  parity numbers.
- **Progress:** `left-jump` on the 408 day-1 room starts met one handler
  not yet ported, `BlockFunc_SolidSpike` (block handlers item 9).
  `left-attack` on them met nothing new. The night room starts
  (`wander`, 408) met the Moon and Mizuuo (objects item 80), now ported.
  `right-attack` on the night room starts met nothing new. The 1,344 room
  starts of the later variants with their own data (`wander`) met the big
  leaves, the Big Octohon, and Wario launched (objects items 81-82, wario
  movement item 43), now ported.
  With them, 29 sweeps (6,234 movies) compare 7,302,729 Wario,
  14,799,775 object, and 7,323,217 interaction updates, all identical,
  nothing unported, and every movie runs whole frames to the end.
  `right-attack` and `right-jump` on the later variants' room starts and
  `left-jump` on the night room starts (3,096 movies) met nothing new;
  with them, 32 sweeps (9,330 movies) compare 10,938,940 Wario,
  22,560,459 object, and 10,970,353 interaction updates, all identical,
  every movie to the end. `wander` with every power-up on the night and
  later variants' room starts (1,752 movies) met nothing new either: 34
  sweeps (11,082 movies) compare 12,965,952 Wario, 26,744,689 object, and
  13,003,290 interaction updates, all identical, every movie to the end.
  Scripted coverage has saturated.

### WL3-050 The golf minigame (P2, in progress)

- **Depends on:** WL3-048 (golf's level side, room transitions item 5)
- **Evidence:** golf doors lead from levels to the minigame
  (`src/engine/golf/`: the lobby, 20 holes, the clear cutscene; about
  4,000 lines with its data). Four of the owner's movies play it.
- **Acceptance:** the lobby and the holes translated and drawn, with a
  golf trace (its WRAM bank, `wGolf*`) checked against the owner's golf
  visits, or the scope recorded in an ADR.
- **Progress:** translated (`GolfSim`; [golf](../02-research/golf.md)) with
  its data and graphics extracted (`wl3pc.extract.golf`); the tracer
  records every golf loop, its OAM, and VRAM and the screen every 32 loops.
  All 9,297 compared golf loops of the four movies are identical (RAM,
  variables, OAM), parity runs play golf natively through each visit to
  the end, all 289 VRAM snapshots match the port's VRAM model, and all 256
  compared screens equal the port's drawing pixel for pixel. The game now
  plays and draws golf. The golf building (`ST_GOLF_BUILDING`) is ported
  and drawn (2026-10-23): from an invented save with every crayon
  (`oracle_save --invent-crayons`, labelled), `golf-building-invented`
  enters it from the map, scrolls its menu, plays the first course's five
  holes, and leaves; all 6,291 compared loops, the way out, 196 VRAM
  snapshots, and 177 screens equal the original's, the run from power-on
  equals it at every loop through the building and back to the map, and
  the window's frames equal the original's. A second invented save (every
  musical coin) and movie add the fourth course and a course quit from its
  pause, all identical. Open: the second and third courses and a course
  lost (not reached), the fades' palettes (drawn as white), sound, and the
  window's drawing of a level's golf.

### WL3-051 Action Help (P2, in progress)

- **Depends on:** WL3-043 (the clear screen opens it)
- **Evidence:** after a power-up's treasure the clear screen opens Action
  Help (`ST_ACTION_HELP`, `src/engine/action_help/`: thirteen demos, about
  10,700 lines), which shows the power-up and leads to the map; two of the
  owner's movies (`game-006`, `game-017`) go through it.
- **Acceptance:** `_ActionHelpStateTable` and every demo translated and
  drawn, checked against the oracle loop by loop, or the scope recorded in
  an ADR.
- **Progress:** translated (`ActionHelpSim`;
  [Action Help](../02-research/action-help.md)) with its data extracted
  (`wl3pc.extract.action_help`) and every loop traced. Both movies' 1,995
  compared loops are identical, and their ways out; branches of `game-006`
  (`make action-help-movie`) show every other demo and browsing from the
  pause menu's side: 23,605 compared loops identical, 12 ways out. Drawn:
  all 792 VRAM snapshots and 790 compared screens equal the original's.
  The title screen's demos are traced and match, all 13 with their resets
  (WL3-057), and Action Help from the pause menu and back to it
  (2026-10-18). Open: nothing the movies reach.

### WL3-052 The map and the save (P2, in progress)

- **Depends on:** WL3-043, WL3-051 (the way out of a level)
- **Evidence:** every owner's movie starts on the map and ends there after
  a save (`src/engine/overworld/`, about 37,200 lines; the save screen
  runs in the pause menu's state table, about 3,200 with the menu);
  [the map](../02-research/overworld.md).
- **Acceptance:** what the movies reach of the map (the map side,
  `InitOverworld`, the scenes, the unlock cutscenes, the golf building's
  entry) and the map's save screen translated and drawn, checked
  against the movies' traces loop by loop, or the scope recorded in an ADR.
- **Progress:** traced: every `OverworldStateTable` and
  `_PauseMenuStateTable` loop of the 17 movies (19,531 and 2,917 loops)
  with WRAMX bank 2 and SRAM bank 0. The save screen is ported and drawn
  (`PauseMenuSim`, `SaveScreenVram`): all 2,494 compared loops, 18 ways
  back to the map, 71 VRAM snapshots, and 44 screens match. The map is
  ported (`OverworldSim`) as far as the movies reach it: all 19,478
  compared map loops and 36 ways out match. It is drawn (`OverworldVram`):
  all 586 VRAM snapshots and 460 compared screens match. Native play
  crosses the screens ([native play](../02-research/native-play.md),
  [ADR-0004](../03-architecture/adr-0004-one-ram-across-screens.md)): the
  level and the screens keep one RAM, and the way into a level
  (`InitLevel`) is ported; every movie's run goes natively from its first
  map loop through the level, its screens, the map, and the save to its
  end, with no difference. The pause menu and the level's save from it are
  ported ([the pause menu](../02-research/pause-menu.md)): all 403 of
  `game-016`'s loops match. The reset after the level's save is ported
  (WL3-057). The pause menu is drawn (2026-10-18): its screens and the
  level's save screens equal the original's (52 of 52 on the owner's
  movies with the map's), and the way back to the level matches step and
  natively; so does Action Help from the menu and back (2026-10-18). The
  golf building's entry with every crayon, the building, and the map after
  it are checked (2026-10-23, WL3-050). The top bar and the treasure
  collection are ported and drawn (2026-10-23): `map-collection-game-017`
  matches in all 3,396 compared map loops, its drawing, and from power-on;
  so does Time Attack's best times list (`map-best-times-invented`) and
  the top bar's Day/Night Spell (`map-day-night-spell-invented`) and the
  Temple's regular scene (`map-temple-game-017`), and the East side
  (`map-east-invented`, unchanged). The hidden figure's reveal is ported
  and drawn (`map-temple-reveal-invented`: all 7,528 map loops), and so is
  the epilogue after the fight (`map-temple-ending-invented`: all 13,557
  map loops). The credits after it are ported and drawn
  (`map-temple-credits-invented`: all 12,766 loops; [the
  credits](../02-research/credits.md)); so is the game over screen after a
  lost fight ([game over](../02-research/game-over.md)), and the Perfect
  screen after a perfect game ([the Perfect screen](../02-research/perfect.md)).
  The hidden figure's fight is drawn (2026-10-28): all 446 compared
  screens of the ten movies that reach it equal the original's
  ([the fight drawn](../02-research/hidden-figure-drawing.md)).
  Open:
  the map's paths no movie reaches ([the map](../02-research/overworld.md),
  hypotheses).

### WL3-056 The title without a save, and a level resumed from a save (P1, done)

- **Depends on:** WL3-055 (power-on with a save, the title's Continue).
- **Evidence:** without a save the title plays its intro
  (`IntroSequencePhase1` to `EndIntroSequence`, sub-states 3-6,
  `src/engine/title/intro.asm` and `intro_animation.asm`), and New Game
  goes to the language selection (`ST_LANGUAGE_SELECTION`) and the
  prologue. Continue with a level's save (`wceef` bits 2-5) goes to
  `ST_LEVEL`, whose `InitLevel` resumes the level from the save (not
  ported: `LevelSim.init_level` names it). The title's resets
  (`ClearSaveData`, and closing Action Help's demos:
  `InitWithoutDemoPowerUpReset`) run `Init` again
  ([the title](../02-research/title.md)).
- **Plan:** record a power-on movie with no save through the intro and
  New Game, and one from `game-016`'s level save (captured at its reset)
  through Continue; trace, port, and run them from power-on as the
  Continue movies are.
- **Progress:** the level's resume is ported (2026-10-18):
  `title-continue-level-save-game-016`, from `game-016`'s level save,
  runs from power-on through the title into its resumed level, 1,688
  whole frames equal to the original. The intro is ported and drawn:
  `title-new-game`, with no save, matches in all 1,991 compared title
  loops through New Game, 62 VRAM snapshots and 60 screens, and runs
  from power-on. The language selection after New Game is ported and
  drawn (211 of 211 loops, 4 screens). The prologue is ported and drawn
  ([the prologue](../02-research/prologue.md)): `new-game-ootw` (the route
  `ootw-day1-start` and play in Out of the Woods) runs from power-on with
  no save through the title, the language selection, the prologue, the
  map, and its save into the level, equal at every loop, nothing seeded.
  `make run SAVE=none` plays it in the window, whose frames equal the
  original's through the prologue. WL3-056 is done; the title's resets
  and Time Attack's description are WL3-057.
- **Next (scoped 2026-10-18):** the prologue is `OverworldStateTable`'s
  event cutscene for `EVENT_PROLOGUE` (`OverworldSim` names it:
  `InitPrologue`, `PrologueFunc`). `_InitPrologue`
  (`src/engine/overworld/cutscene/prologue/init.asm`) loads the
  prologue's and the music box's maps and tiles and the text buffer;
  `Prologue` (`bank2b_2.asm`, 3,621 lines in all) plays 39
  steps (Wario falling from the plane, the cave, the music box, the
  temple, the hidden figure's text) with `UpdatePrologueSceneObjects`
  and `PrologueFade` (`bank2b_1.asm`), `_PrologueFade` (`bank21.asm`),
  and text printing (`InitTextPrinting`, `LoadCurTextPageBufferPage`,
  `Func_aca9e`, `Func_acacd`, `Func_acae7`: nothing of it is ported yet).
  `UpdateSceneWario` is ported for the map's scenes. Extend
  `title-new-game` past the prologue to the first level, trace, and port it step by step against the trace.
- **Acceptance:** both movies match loop by loop from power-on in the
  parity run mode with nothing seeded before the first level, and
  `make run SAVE=…` plays them.

### WL3-057 The game's resets (P2, done)

- **Depends on:** WL3-055, WL3-056 (the title).
- **Evidence:** the start menu's Clear Data Yes (`ClearSaveData`: the
  save's check values cleared, then `Init`) and the end of Action Help's
  demos from the title (`InitWithoutDemoPowerUpReset`) both run `Init`
  again; so do A, B, Select and Start held (`.GameLoop`) and the reset
  after the level's save (`ResetAfterPauseMenuSave`)
  ([the resets](../02-research/resets.md)).
- **Plan:** record a movie for each (left alone on the start menu for
  the demos; Clear Data's Yes), trace, port the resets as a native `Init`
  (the save's load again, `hDemoPowerUp` kept by the demos' reset).
- **Acceptance:** each movie matches loop by loop from power-on through
  its reset in the parity run mode.
- **Done (2026-10-18):** `LevelSim.init_game` rebuilds the game in place
  from the SRAM as it is. Four power-on movies from `game-017`'s save (the
  demos, Clear Data's Yes, the four buttons on the map, the level's save
  and its reset), and a fifth through all 13 demos, match loop by loop,
  step and from power-on, through every reset; the port's SRAM at the level save's reset equals the
  original's, all 32 KiB; the window draws them. Time Attack's
  description moved to WL3-058.
- **Extended (2026-10-28):** a reset after a level played and not saved
  (`GameOverReset` after the lost fight, `ResetAfterSave` after the
  Perfect screen, the four buttons within a level): `current_sram` gives
  the level map as played, and `InitLevel` takes the bytes it never
  writes from the load; three runs go on natively to their traces' ends,
  and each load's SRAM equals the original's byte for byte.

### WL3-058 Time Attack's description (P3, done)

- **Depends on:** WL3-055 (the title).
- **Evidence:** Continue with `wGameModeFlags`' `MODE_TIME_ATTACK` fades
  to the description (`InitTimeAttackDescription`,
  `TimeAttackDescription`, the title's sub-states 9 and `$0a`; the fade,
  sub-state 8, is ported). A perfect game sets the flag
  (`src/engine/perfect/core.asm`); no save has it, and the mode reaches
  the map, the levels' clock (`TickLevelTime`), the pause menu, and the
  clear screen too.
- **Plan:** a save with Time Attack (one the owner makes, or a stored save
  with the flag set and its checksums recomputed by the save's own sums,
  labelled as invented); a movie through Continue; trace, port, check.
- **Acceptance:** the description matches loop by loop and in the window.
- **Done (2026-10-18):** two invented saves (`oracle_save
  --invent-time-attack`, labelled in the store: `game-017`'s with Time
  Attack on, and in Japanese) make the original show the description;
  `TitleSim` ports sub-states 9 and `$0a` and `TitleVram` draws it, the
  Japanese rows' mid-frame scroll included (`CgbScreen`'s `scy_lines`).
  Both movies match every loop, screen, and way out, step and from
  power-on, and the window's frames equal the original's
  ([the title](../02-research/title.md)). The map and the levels in Time
  Attack are not traced beyond the map's first 887 loops.

### WL3-026 Breakable blocks in the runtime (P2, todo)

- **Depends on:** WL3-034 (a breaking rule needs the attack states). The
  handlers, their map writes, and `BreakBlock`'s coin are ported; native
  play rolls `rDIV` from a seeded generator.
- **Evidence:** `CrackedBlockCollision`, `NonCrackedBlockCollision`,
  `CrackedBlockWithColourCoinCollision`, `EnemyBlockCollision`, and
  `BonfireBlockCollision` ([block handlers](../02-research/block-handlers.md)):
  per-probe break conditions, the replacement block (bit 7 kept), and the
  return value after breaking. `ROOM_001` has 8 breakable kinds, labelled as
  `solid` stand-ins in the extracted pack.
- **Acceptance:** a runtime material (or per-probe rule) for breakable
  blocks with tests per break condition; the pack builder stops labelling the
  kinds it implements; the parity matrix row is updated.

### WL3-028 Second emulator for timing-sensitive checks (P3, todo)

- **Depends on:** WL3-014 (done)
- **Evidence:** PyBoy is deterministic but not cycle-exact
  ([emulator oracle](../02-research/emulator-oracle.md)).
- **Acceptance:** before any raster, sound, or `rLY`-gated behaviour is called
  validated, the same route and capture are reproduced in a second, more
  accurate emulator (e.g. SameBoy), or the difference is documented.

### WL3-032 Import BizHawk .bk2/.tasproj input logs as draft movies (P3, blocked: needs a sample file)

- **Evidence:** the game draws randomness from the DIV timer (`BreakBlock`,
  several enemies), and BizHawk's cores and boot ROM time differently from
  PyBoy, so an imported movie will desync where a random roll differs
  ([emulator oracle](../02-research/emulator-oracle.md), item 12).
- **Acceptance:** with a real `.bk2` or `.tasproj` from the owner, parse its
  input log by its `LogKey`, write an oracle recording, and report the first
  frame where the game diverges (for example, by comparing Wario's position
  with the BizHawk movie's own RAM watch export, if available).

### WL3-016 Choose the project license (P2, blocked: owner decision)

- **Acceptance:** `LICENSES.md` names the license for project-original code,
  docs, and synthetic data, and answers or explicitly defers open question 2.

### WL3-017 Optional froggestspirit comparison build (P3, todo)

- **Acceptance:** build with RGBDS v0.4.1 in an ignored workspace against an
  ignored `baserom.gbc` copy, and record the result. Low priority, because the
  ElectroDeoxys build is already byte-identical.

### WL3-019 Text decoding (P3, todo)

- **Lead:** the editor's `textTable.txt` and `textLocations.txt`; the
  disassembly's `src/charmaps.asm`. Verify mappings against the ROM text consumers.

### WL3-020 Audio approach (P3, todo)

- **Acceptance:** an ADR on sound-driver modelling, kept separate from CPU and
  gameplay execution.

### WL3-021 Desktop session checks (P3, todo)

- **Acceptance:** on the Fedora desktop (Wayland and X11 where available),
  record observed keyboard input, controller input, window resizing with
  integer scaling, and exported-binary launch, including failures.

### WL3-022 Save and settings format (P3, todo)

- Versioned save files under the per-user data directory (`user://` is
  configured as `~/.local/share/wl3pc`). Belongs to M4.

### WL3-023 Packaging (P3, todo)

- RPM or Flatpak only after a standalone build of real content works.

## Done

| ID | Task | Evidence |
| --- | --- | --- |
| WL3-055 | Native play from a save: the save's load at power-on (`SaveLoad`, equal to `ValidateSaveData` on 19 captured loads), the title's Continue path ported and drawn (`TitleSim`, `TitleVram`), and power-on runs with a battery save in the parity run mode and the window (`make run SAVE=…`); from `game-017`'s save, 142 title loops, the map, the way into a level, 1,217 level frames, the pause menu's To Map, and the map's save all match natively with nothing seeded before the level; the rest of the title is WL3-056 | [the save's load](../02-research/save-load.md), [the title](../02-research/title.md), [session](../06-sessions/2026-10-18-title.md) |
| WL3-047 | Coverage of the night variants, the later variants, and room starts: 24 sweeps of 3,258 movies (six scripts; day 1, night 1, the 85 later variants with their own data, and the 408 day-1 room starts) met the remaining Wario states, block handlers, and the object kinds they reach, among them the bosses (Mad Scienstein, Wormwould, Wolfenboss, Doll Boy, Yellow Belly, Anonster, Scowler, Muddee, Jamano), the Shoot minigame, and the variable cart (its treasure byte traced), all ported; 3,833,825 Wario, 7,721,186 object, and 3,845,136 interaction updates identical, nothing unported, and all 3,258 movies run whole frames to the end; the battles past their starts are left to WL3-048 | [objects](../02-research/objects.md), items 42-78; [wario movement](../02-research/wario-movement.md), items 33-42; [block handlers](../02-research/block-handlers.md), item 8; [emulator oracle](../02-research/emulator-oracle.md), item 17 |
| WL3-046 | Coverage with power-ups: `make level-movie POWER_UP=N`; with every power-up, the `wander` and `right-attack` sweeps met the smash attack, grabbing and throwing (Wario's side and the objects', `HandleGrabbedObjectCollisions`), Crazy Wario, and interactions `$24`, `$28`, `$3d`, all ported; the six sweeps (150 movies) compare 179,063 Wario updates, 350,391 object slot updates, and 179,653 interaction runs, all identical, and every movie runs whole frames to the end | [wario movement](../02-research/wario-movement.md), items 30-32; [objects](../02-research/objects.md), items 40-41; [emulator oracle](../02-research/emulator-oracle.md), item 17 |
| WL3-044 | Objects of the other levels: every object, interaction, block handler, and Wario state that four scripted sweeps of all 25 levels (`right-jump`, `right-attack`, `right-crouch`, `wander`) meet, among them Flat, Zombie, Blind, and Bouncy Wario, slipping, and the multi-block breakables; 119,514 Wario updates, 238,440 object slot updates, and 119,918 interaction runs compared, all identical, and all 100 movies run whole frames to the end | [objects](../02-research/objects.md), items 19-39; [wario movement](../02-research/wario-movement.md), items 25-29; [block handlers](../02-research/block-handlers.md), items 6-7 |
| WL3-045 | Wario's states on the other levels: sand, Fat Wario and the ground shake, being picked up, Ice Skatin', hanging from a rail, and the block handlers they meet; every one of the coverage sweep's 29,826 Wario updates is compared and identical | [wario movement](../02-research/wario-movement.md), items 19-24 |
| WL3-041 | Wario's states entered from objects: `UpdateState_EnemyBumping`, 102 of 102 bumping updates identical on the six sweep levels that reach it | [wario movement](../02-research/wario-movement.md) |
| WL3-001 | Record input hashes, preserve inputs | [ROM identity](../02-research/rom-identity.md) |
| WL3-002 | Repository, ignore rules, safety checker | [workflow](../04-development/workflow.md) |
| WL3-003 | Read-only ROM inspector with synthetic tests | `tools/wl3pc/rom_info.py`, `tests/test_rom.py` |
| WL3-004 | Pin and audit reference sources | [sources](../02-research/sources.md) |
| WL3-005 | Pin Godot 4.7.2 and RGBDS v1.0.0 | `toolchain.lock.json` |
| WL3-006 | Byte-identical reference build | [ROM identity](../02-research/rom-identity.md) |
| WL3-007 | Vault | this vault |
| WL3-008 | Synthetic scene, headless tests, Linux export | [architecture](../03-architecture/overview.md) |
| WL3-009 | Decode block function tables (M1) | [first investigation](../02-research/first-investigation.md) |
| WL3-010 | Decode per-room records | [room records](../02-research/room-records.md) |
| WL3-024 | Decode level headers and room headers | [level headers](../02-research/level-headers.md) |
| WL3-011 | Map table `$00`'s 31 handlers to runtime materials | [block handlers](../02-research/block-handlers.md) |
| WL3-025 | Decode level block maps | [level block maps](../02-research/level-block-maps.md) |
| WL3-013 | First room as an original-extracted collision pack, loaded by the runtime and the export | [first room pack](../02-research/first-room-pack.md), [ADR-0002](../03-architecture/adr-0002-labelled-approximations.md) |
| WL3-014 | Emulator oracle: deterministic route, reproducible capture, recorder | [emulator oracle](../02-research/emulator-oracle.md) |
| WL3-015 | Gameplay cadence: one update per frame during normal play | [emulator oracle](../02-research/emulator-oracle.md) |
| WL3-029 | TAS editor for the oracle (screen, piano roll, greenzone, RAM watch), requested by the owner | [emulator oracle](../02-research/emulator-oracle.md) |
| WL3-030 | Oracle starts: boot ROM recorded (PyBoy's stub or the user's dump), battery saves, save states with origins, branches | [emulator oracle](../02-research/emulator-oracle.md) |
| WL3-031 | PyBoy deep dive: collision-probe traces through hooks, live map check, movie review, TAStudio-style editing | [emulator oracle](../02-research/emulator-oracle.md) |
| WL3-012 | Movement tables decoded; Wario's idling, walking, turning, airborne, and landing states ported by translation; every compared oracle update identical, and the walk capture reproduced alone | [wario movement](../02-research/wario-movement.md), [ADR-0003](../03-architecture/adr-0003-wario-port-by-translation.md) |
| WL3-033 | Extracted level 0 playable with the ported Wario in the window and the export (`make run LEVEL=0`); native level start identical to the oracle's; walk input matches all 300 oracle positions (`make smoke-level`) | [wario movement](../02-research/wario-movement.md) |
| WL3-036 | Level camera ported (`LevelSim`): all 5802 camera runs of the owner's movie identical, the level start's camera identical, whole frames of the walk matched alone; the window draws from it | [level camera](../02-research/level-camera.md) |
| WL3-018 | Room tiles, block layouts, attributes, and palettes decoded; equal to the reference build and the palette source; 389,192 background pixels of the owner's movie and the walk equal the original's screen; the window draws them | [room graphics](../02-research/room-graphics.md) |
| WL3-037 | Room animation: animated tiles and palette cycles ported (with the late-loop skips replayed from the trace), drawn in the window from the decoded graphics, and composed by `make screen-check`: 128,458 of 128,458 background pixels at frames of the movie showing animated blocks; the whole movie's 5802 frames compare the animation variables too | [room graphics](../02-research/room-graphics.md) |
| WL3-042 | Particles drawn: their OAM tables and palette (`Pals_d1fe`) decoded, drawn over every other sprite from VRAM bank 0 (Wario's tiles below `$80`, the common graphics above); all 1537 drawn particles of the movie equal their decoded frames (`make sprite-check`), and the window's dust equals the original's screen (`make window-check`) | [objects](../02-research/objects.md) |
| WL3-034 | Wario's states in the owner's movie: attacking, bumping, crouching, sliding, rolling, stung, ladders, doors, and the electric, Ball o' String, and On Fire transformations, and the treasure scene; all 5676 of the movie's Wario updates match the oracle | [wario movement](../02-research/wario-movement.md) |
| WL3-040 | The movie's objects and interactions: leaves, Futamogu, Webber, coins and colour coins, keys and their pause, torches and embers, birds, chests and treasures, Silky, every interaction type it meets, `rDIV` replayed, and the particles; the whole movie's 5802 level frames run natively from its input and match at every checkpoint | [objects](../02-research/objects.md) |
| WL3-039 | Objects drawn: their OAM tables, enemy and common graphics, and palettes decoded; all 10,547 drawn objects of the movie equal their decoded frames, VRAM bank 1 equals the decoded groups, and the window equals the original's screen with objects (walk) | [objects](../02-research/objects.md) |
| WL3-035 | Objects: the slot model and `UpdateObjects` framework, the shared object states, the Spearhead and the musical coin, `ProcessInteractions` for their types, and spawning; every check over the movie identical, and 675 whole frames (Wario, objects, interactions, camera) run alone through the first room and its transition | [objects](../02-research/objects.md) |
| WL3-038 | Wario's sprites: the tile sets, OAM tables, and palettes of the ported states decoded and equal to the reference build; the states set the graphics variables as the original (parity on all 3309 updates); 1,514,112 of 1,514,112 of Wario's pixels on the original's screen match the decoded sprite (`make sprite-check`), and the window equals the original's screen apart from other sprites (`make window-check`) | [Wario's sprites](../02-research/wario-sprites.md) |
| WL3-027 | Room transitions and doors: the trigger, door entry, the level sub-states' timing, and the next room's start; all five transitions of the owner's movie match the oracle in game loops and state; kind 5 by a synthetic test | [room transitions](../02-research/room-transitions.md) |
