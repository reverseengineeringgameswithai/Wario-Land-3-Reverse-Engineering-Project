---
type: project
status: active
updated: 2026-10-28
tags: [project, session]
---
# Current state

Concise handoff. Update at the end of every session.

## Latest session (2026-10-28)

Where to pick up: the owner asked (2026-10-23) to go on without new
recordings unless a path needs one. Next: a window check of the late
screens (the credits, the game over and Perfect screens, the saves
after them), or golf's fades.
The agent's scratch scripts (the fight and route planners, the recheck
loop, the window check) are in `local/agent-scratch/` (ignored; the
recheck loop writes to a scratch path to adjust). `build/agent/` and
`build/snapshots/` (ignored) hold scratch copies and sweep snapshots; they
can be deleted.

- The hidden figure's fight is drawn (WL3-052): `TempleVram` from the
  figure's own graphics (`temple.json`), Wario's tile set, the room's
  animated tiles, the figure's palette flashes, the OAM, and the shake
  (which `LevelVBlankFunc` adds twice there). The tracer now records the
  Temple's VRAM and screens and each palette write's line; all 446
  compared screens of the ten movies that reach the fight equal the
  original's in `MODE=run` from power-on, and the window shows it
  ([the fight drawn](../02-research/hidden-figure-drawing.md),
  [session](../06-sessions/2026-10-28-hidden-figure-drawing.md)).

## Earlier session (2026-10-28)

- The reset after a level played and not saved is ported (WL3-057):
  `current_sram` gives SRAM from the level map the port keeps, and
  `InitLevel` takes the bytes it never writes (each row's `$a0`-`$af`,
  rows 48-63) from the load. `map-temple-game-over-invented` and
  `map-perfect-after-clear-invented` now run natively from power-on
  through `GameOverReset` and `ResetAfterSave` to their traces' ends (the
  title, Continue and the map; the title and a demo), and a run compares
  each load's SRAM with the oracle's capture of it: all equal. A new
  scripted movie, `title-reset-level-game-017` (the four buttons held
  within a level), runs the same way ([the resets](../02-research/resets.md) item 7,
  [session](../06-sessions/2026-10-28-reset-after-unsaved-level.md)).
- The save after the Perfect screen is drawn and compared: its 28 screens
  equal the original's. What differed was the save screen's palettes,
  which the drawing did not take at `$2b` and `$2f` (not a layer, as
  first thought; [the pause menu](../02-research/pause-menu.md) item 9).

## Earlier session (2026-10-23)

- The golf building is ported and drawn (WL3-050, WL3-052): no save has
  every crayon, so `oracle_save --invent-crayons` stores `game-017`'s with
  them (labelled invented); `golf-building-invented` enters the building
  from the map, scrolls its menu, plays the first course's five holes,
  sees its result, and leaves. All 6,291 compared loops, the way out, 196
  VRAM snapshots, and 177 screens equal the original's; from power-on the
  title, the map, the building, the map's save, and the map again run
  natively, equal at every loop (8,607); the window's frames equal the
  original's. A second invented save (every musical coin) adds the fourth
  course and a course quit from its pause, all identical
  ([golf](../02-research/golf.md) items 9-11,
  [session](../06-sessions/2026-10-23-golf-building.md)).
- The map's top bar and the treasure collection are ported and drawn
  (WL3-052): `map-collection-game-017` (`game-017`'s save) browses the
  bar, changes map side, browses the collection's pages and links, and
  plays the last cutscene again: every compared loop and screen equals
  the original's, from power-on too ([the map](../02-research/overworld.md)
  item 10). So do Time Attack's best times list, from the invented Time
  Attack save (item 11), the bar's Day/Night Spell, from a save
  invented with the spell, the Temple's scene (item 12), and the East
  side, which matched with no change (item 13).
- The hidden figure's reveal is ported and drawn (WL3-052):
  `map-temple-reveal-invented` (an invented save with the five music
  boxes) plays it to the fight's start; all 7,528 map loops, 235 VRAM
  snapshots, and 229 screens equal the original's, and from power-on to
  the end. Each screen loop in a trace now records the rDIV reads before
  it, so the rocks' reads are fed loop by loop
  ([the map](../02-research/overworld.md) item 14). That movie ends
  waiting at its last step; `map-temple-fight-invented` adds the A that
  closes it and reaches the fight.
- The hidden figure's fight is ported (WL3-048): its objects (translated
  by a delegated agent, checked here), `UpdateObjects_Temple`, the
  Hidden Figure camera, its three interactions, the game over, and
  `ST_EPILOGUE`. With no input the hands win; with inputs a planner found
  on emulator save states (and an invented save with every power-up),
  Wario knocks the hands loose, throws them into the face four times, and
  wins. Every Wario, object, interaction, and camera update matches, and
  from power-on the run goes natively through the whole fight to the
  epilogue's first scene ([objects](../02-research/objects.md) item 85).
  Not drawn yet.
- The epilogue after the fight is ported and drawn (WL3-052): the North
  side's scene and `OverworldStateTable`'s `$23`-`$27`, translated by two
  delegated agents in parallel and checked here; `map-temple-ending-invented`
  matches in all 13,557 map loops and its save, natively from power-on to
  the credits ([the map](../02-research/overworld.md) item 15).
- The credits are ported and drawn (WL3-052, by a delegated agent, checked
  here): the tracer's new layout records them, and
  `map-temple-credits-invented` matches in all 12,766 credits loops, 398
  VRAM snapshots, and 331 screens; from power-on the run goes natively
  through the title, the map, the reveal, the fight, the epilogue, its
  save, and the credits to the trace's end at tick 30,000
  ([the credits](../02-research/credits.md)).
- The game over screen is ported and drawn (WL3-052, by a delegated
  agent): after a lost fight and the map's save, `map-temple-all-treasures-invented`
  and `map-temple-game-over-invented` match in all 328 and 439 loops
  ([game over](../02-research/game-over.md)).
- A perfect game, statically: a save invented with all 100 treasures
  (`4dd1761d…`) changes the map's route (every crayon: the golf course
  stops Wario between West and North), found by a route search on save
  states, and the fight's timing; the planner won it again, and
  `map-temple-perfect-game-invented` plays the perfect epilogue, the
  credits, and the Perfect screen, which is ported and drawn too (by a
  delegated agent): all 2,703 loops, 84 VRAM snapshots, and 84 screens,
  and from power-on natively to the end ([the Perfect
  screen](../02-research/perfect.md)).

## Earlier session (2026-10-18)

- The title is ported and drawn, and native play starts at power-on
  (WL3-055, done): the tracer records the title's loops; `TitleSim` and
  `TitleVram` match all 141 compared loops, 4 VRAM snapshots, and 2 screens
  of the Continue movie. A run from power-on loads the movie's battery save
  with the ported load and plays the title, the map, the way into a level,
  the level, the pause menu's To Map, and the map's save natively, equal
  at every loop, with nothing seeded before the level. `make run SAVE=…`
  starts the window the same way; its title equals the original's
  ([the title](../02-research/title.md),
  [session](../06-sessions/2026-10-18-title.md)).
- A level resumed from a save is ported (WL3-056, in part):
  `game-016`'s level save, through Continue, resumes level `$41` and runs
  from power-on equal to the original for 1,688 whole frames. So is the
  intro with no save, and drawn (its parallax and its fade): all 1,991
  compared loops and 60 screens of `title-new-game` match; and New Game's
  language selection (211 loops, 4 screens). The prologue is ported and
  drawn ([the prologue](../02-research/prologue.md)): `new-game-ootw` runs
  from power-on with no save through the title, the language selection,
  the prologue, the map, and its save into Out of the Woods, equal at
  every loop with nothing seeded (WL3-056, done).
- The game's resets are ported (WL3-057, done): `LevelSim.init_game`
  runs `Init` in place on the SRAM as it is (`hDemoPowerUp` kept by the
  demos'). Four power-on movies (the title's demos, Clear Data's Yes,
  A+B+Select+Start on the map, the level's save and the reset after it)
  match loop by loop, step and natively from power-on, through their
  resets; the port's SRAM at the level save's reset equals the original's
  byte for byte, and the window draws them
  ([the resets](../02-research/resets.md)).
- Time Attack's description is ported and drawn (WL3-058), checked on two
  invented saves (`game-017`'s with Time Attack on, English and Japanese,
  made with `oracle_save --invent-time-attack` and labelled as invented):
  every loop and screen matches, the Japanese rows' mid-frame scroll
  included ([the title](../02-research/title.md)).
- The pause menu is drawn (WL3-052): its screens and the level's save
  screens equal the original's in every compared screen (52 of 52 on the
  owner's movies with the map's save screens; 45 on three new power-on
  movies), and the window shows them instead of the stand-in. A new movie
  pausing and going back to the level matches step and natively within
  the level's run ([the pause menu](../02-research/pause-menu.md)), and
  so does Action Help from the menu and back to it.

## Earlier session (2026-10-12)

- The map is drawn (WL3-052): `OverworldVram` applies what `OverworldSim`
  records each loop. All 586 VRAM snapshots and 460 compared screens of the
  17 movies equal the original's
  ([session](../06-sessions/2026-10-12-map-drawing.md)).
- Native play crosses the screens (WL3-052,
  [ADR-0004](../03-architecture/adr-0004-one-ram-across-screens.md)): the
  level and the screens keep one RAM, and the way into a level is ported.
  Every owner's movie now runs natively from its first map loop, seeded
  there, through the level, its screens, the map, and the save, to its
  end: 3,767 map and 503 save loops, 18 levels entered, 82,794 level
  frames, and 23,885 screen loops, all identical. A level-start bug was
  fixed on the way: each level began with its first room's animation off
  ([native play](../02-research/native-play.md),
  [session](../06-sessions/2026-10-12-native-chain.md)).
- The pause menu from a level and the level's save are ported (WL3-052):
  all 2,897 compared loops of the pause menu's table match, `game-016`'s
  403 new ones among them; the window shows a labelled stand-in for the
  menu ([the pause menu](../02-research/pause-menu.md),
  [session](../06-sessions/2026-10-12-pause-menu.md)).
- The save's load at power-on is ported (WL3-055, step 1): `SaveLoad`
  equals `ValidateSaveData` on all 19 loads the oracle captured, byte for
  byte ([the save's load](../02-research/save-load.md)).
- The regression sweeps run from one pool, several movies a Godot process
  (`make sweeps`, `SNAPSHOT=1` to keep working meanwhile)
  ([faster sweeps](../06-sessions/2026-10-12-faster-sweeps.md)).

## Where things stand (2026-10-03)

- **ROM:** identified as Wario Land 3 (World) (En,Ja), SHA-256
  `b625ed03…7406`. The hash was checked before and after the session and is
  unchanged ([ROM identity](../02-research/rom-identity.md)).
- **Reference build:** ElectroDeoxys `560fce6` + RGBDS v1.0.0 →
  byte-identical (`make refbuild`).
- **M1 extraction:** block function tables decoded and validated: 89 tables,
  9 reset sentinels, 138 distinct handlers, each on a disassembly label
  ([first investigation](../02-research/first-investigation.md)). The handlers'
  semantics are mostly unknown.
- **Room records (WL3-010, done):** 154 records plus the `ROOM_000` reset
  sentinel (`NUM_ROOMS` = `$9b`). Each room's function table, block tiles,
  compressed tile map, main and special tiles, and palettes are resolved to
  banked sources that land on their disassembly labels. The `index / 6` bank
  rule is confirmed from the code
  ([room records](../02-research/room-records.md)). What the decompressed
  tile-map bytes mean is a hypothesis (WL3-018).
- **Level and room headers (WL3-024, done):** all 201 levels, 119 room lists,
  and 2010 room headers decode and land on their labels. **Out of the Woods,
  day 1 starts in `ROOM_001`**, which uses block function table `$00`
  ([level headers](../02-research/level-headers.md)). Spawn and limit
  nibbles appear to be in 16-block sections, and list entries other than 0
  appear to be keyed by a transition's source section. Both are
  interpretations, not yet verified.
- **Block handlers (WL3-011, done for table `$00`):** all 31 handlers used by
  `ROOM_001` were read, with per-probe behaviour
  ([block handlers](../02-research/block-handlers.md)). A tracked, versioned
  mapping gives each handler a material (`empty`, `solid`, `platform`, six
  slope kinds) and flags (ladder, door, transitions, breakables). The other
  107 handlers map to `unknown`. The runtime still implements only `empty`,
  `solid`, and `platform` and refuses everything else, which a shared fixture
  checks in both loaders.
- **Level block maps (WL3-025, done):** all 35 maps decode to 48 rows of
  160 blocks ([level block maps](../02-research/level-block-maps.md)). If the
  header limits are section ranges, `ROOM_001` is block rows 32–47 and
  columns 0–31, and uses only `empty`, `solid`, and `platform`, plus
  breakable and room-transition blocks. `TheWestCraterBlockMap` leaves its
  last cell unwritten.
- **First real room (WL3-013, done, collision only):** `make room-pack`
  builds `ROOM_001` from the original data into
  `local/content/packs/wl3-level-00-room-001`, a content-pack v2 with 12
  labelled approximations ([ADR-0002](../03-architecture/adr-0002-labelled-approximations.md),
  [first room pack](../02-research/first-room-pack.md)). The spawn comes from
  the object map and lands exactly on the floor. The Godot runtime
  (`make smoke-extracted`) and the exported binary, run outside the checkout,
  load it and report its labels. **The physics is still the provisional
  prototype**, and there are no original graphics yet.
- **Emulator oracle (WL3-014, WL3-015, done):** PyBoy 2.7.0 drives the ROM
  deterministically from per-frame input
  ([emulator oracle](../02-research/emulator-oracle.md)). The ROM is given as
  bytes, so nothing is ever written next to it. A tracked route reaches Out
  of the Woods, day 1 from power-on and reproduces a full-memory digest. A
  300-frame walk capture is identical across separate emulators. The running
  game confirms the decoded spawn point and the wall in `ROOM_001`, and shows
  one gameplay update per frame.
- **TAS editor (WL3-029):** `make tas NAME=… START=ootw-day1-start` opens a
  window with the live screen, a piano roll (click to seek, click or drag to
  set buttons, greenzone and lag rows), a RAM watch, recording,
  frame advance and back, speeds, insert/delete, and undo. Movies save as
  oracle recordings. Seeking and editing match straight replays bit for bit
  (`make tas-check`). A new movie opens running and recording; a red or
  blue banner and screen border show recording or read-only (Q, Ctrl+R,
  the Mode button, or a click on the banner switch). The window was driven
  by a scripted test on the desktop, but real key events have not been
  confirmed yet.
- **Oracle starts (WL3-030):** a movie can start at power-on (PyBoy's boot
  ROM, which is a 256-byte stub, or your own dump via `BOOTROM=`; empty
  cartridge RAM or your own 32 KiB save via `SAVE=`), at a tracked route, or
  at a save state (`STATE=`, stored or an outside PyBoy file). The editor
  saves states, branches new movies from any frame, and exports battery
  saves. Every start kind matches straight replays (`make starts-check`).
  User files are kept by SHA-256 in `local/oracle/`.
- **Oracle review (WL3-031):** PyBoy execution hooks trace every collision
  probe (`ProcessBlock`, its inputs, and the handler's result) without
  changing the run. `make review MOVIE=…` gives a timeline, contact sheets,
  the probe trace, and a check of every probed block against the decoded
  level map. The walk's probes agree with the WL3-011 mapping and the
  WL3-025 map. The editor has BizHawk-style hotkeys, markers, and copy and
  paste. BizHawk movies cannot be expected to sync, because the game's
  randomness reads the DIV timer (WL3-032).
- **Owner recording reviewed:** `local/recordings/ootw-gray-key.recording.json`
  (8363 frames from the level-select map state `8b5fd0d5…`, through the
  clear and back to the map) replays exactly. It takes the gray key at
  frame 2040, opens the gray chest at frame 5745, and the treasure is
  counted at frame 6596 ([emulator oracle](../02-research/emulator-oracle.md),
  item 15). The review and RAM watch now read BCD counters correctly. Map
  bit 7 is now known to mean "object not spawned"
  ([level block maps](../02-research/level-block-maps.md), finding 7). A
  state at the movie's end, on the map after the clear, is stored as
  `7b2e6ea4…` and rebuilds from power-on (`make state-check`).
- **Wario movement (WL3-012, done):** `make extract` decodes the walk and
  jump tables, Wario's framesets, and level 0's collision (block map plus
  each room's handlers). Idling, walking, turning, airborne, and landing are
  ported by translation (`game/scripts/sim/wario/`,
  [ADR-0003](../03-architecture/adr-0003-wario-port-by-translation.md)).
  `make wario-trace` records every Wario update of a movie through hooks,
  and `make wario-parity` reruns them natively: on the owner's movie, all
  2022 compared updates match on 39 variables, and the port alone
  reproduces the walk capture
  ([wario movement](../02-research/wario-movement.md)).
- **Playable level (WL3-033, done):** `make run LEVEL=0` plays Out of the
  Woods, day 1 from the extracted level with the ported Wario (now drawn
  from the original's graphics; unported moves are named on screen and in
  the log). The native level start equals the oracle's on 54 variables, and
  from it the walk input reproduces all 300 oracle positions
  (`make smoke-level`, also in `make export-linux`). Keys match the TAS
  editor: arrows, X = A, Z = B.
- **Level camera (WL3-036, done):** ported by translation (`LevelSim`):
  all 5802 camera runs of the owner's movie and the level start's camera
  match the oracle, and whole frames of the walk match alone
  ([level camera](../02-research/level-camera.md)). The window draws from
  it.
- **Room graphics (WL3-018, done):** tiles, block layouts, attributes, and
  palettes decoded for level 0's rooms (`make extract`), equal to the
  reference build and the palette source; `make screen-check` finds every
  compared background pixel of the owner's movie and the walk equal to the
  original's screen, and the window's own screenshots match it too
  ([room graphics](../02-research/room-graphics.md)). Animated tiles and
  palette cycles are not ported (WL3-037).
- **Wario's sprites (WL3-038, done):** decoded tile sets, OAM tables, and
  palettes for the ported states; the states set the graphics variables as
  the original, Wario's pixels on the original's screen equal the decoded
  sprite over the whole movie (`make sprite-check`), and the window equals
  the original's screen on every compared pixel (`make window-check`;
  only other sprites left out) ([Wario's sprites](../02-research/wario-sprites.md)).
- **Milestones:** M2's exit criteria are met; M3 is active.
- **Wario's states (WL3-034, in progress):** the shoulder charge, the
  airborne attack, bumping, crouching, sliding, rolling, getting stung,
  ladders, the electric, Ball o' String, and On Fire transformations, and
  the treasure scene are ported (WL3-034, done for the movie): all 5676
  Wario updates of the owner's movie match. Water and enemy bumping
  (WL3-041) match on every level of the coverage sweep that reaches them.
- **Room transitions (WL3-027, done):** transition blocks and doors, the
  fades' and door effect's frame counts, and the next room's start; all five
  transitions of the owner's movie match the oracle in game loops (67, or
  101 through a door) and state ([room transitions](../02-research/room-transitions.md)).
  The window can now leave the first room.
- **Objects (WL3-035, done):** the slot model, the `UpdateObjects`
  framework, the shared object states, the musical coin, and the Spearhead
  are ported, and so is `ProcessInteractions` for bumps, attacks, stepping
  on, stings, and the musical coin; the trace records the slots around
  objects and interactions, and all 3827 fully ported slot updates and 5763
  interaction runs of the movie match; objects spawn from the map at room
  starts and streamed edges exactly as in the original; whole frames run
  alone for 675 frames of the movie, through the first room
  ([objects](../02-research/objects.md)). The window draws the objects from
  their original graphics (WL3-039, done). Room 21's objects (leaves,
  Futamogu, Webber) are ported too (WL3-040, in progress), and so are the
  electric shock, the keys with the game's 100-loop pause, coins from
  broken blocks, torches, birds, the chests, Silky, fire, the treasure,
  and the particles (WL3-040, done): the whole movie's 5802 level frames
  run natively from its input alone and equal the original at every
  checkpoint, from the level start to where the level ends.
- **Other levels:** `make level-movie` starts the oracle at any level; a
  sweep of all 25 levels' starts finds every compared Wario update equal
  and ranks what is unported. Water (Wario's eight water states) is now
  ported and matches in all nine water levels of the sweep. Para-Goom
  and Brrr Bear with its snowflakes (WL3-044) are ported: all their slot
  updates in the sweep match (5342, 2189, and 281). Sand, Fat Wario, the
  ground shake, being picked up, Ice Skatin', hanging from a rail, and
  the block handlers it met (WL3-045, done) are ported, with the zip
  lines, and (WL3-044) every object the sweep meets: it compares all
  29,826 of its Wario updates and 60,008 object slot updates, every one
  identical, and whole frames run alone to the end of all 25 of its
  movies (the last four once interactions `$0a`, `$0b`, the stove, and
  the tadpole were ported). A second sweep with attacks (`right-attack`)
  met the water spark, `VanishObject2`, interaction `$3b`, and Flat
  Wario, all now ported: 29,907 of 29,907 Wario updates and 62,394
  object slot updates identical, every level to the end in run mode.
  With the crouch and wander sweeps (WL3-044, done), four scripts on all
  25 levels, and two more with every power-up (WL3-046, done: the smash
  attack, grabbing and throwing, Crazy Wario): 150 movies, 179,063 Wario
  updates and 350,391 object slot updates, all identical, every movie
  running whole frames to the end. WL3-047 (in progress) adds night 1
  (the Spearhead asleep, a thrown object breaking a block) and the 85
  later variants with their own level data (pipes, the snake, the bots
  picked up): 810 movies in all, every Wario, object, and interaction
  update identical, nothing unported, every movie to the end. The 408
  day-1 room starts (six scripts) bring it to 3,258 movies. With the
  bosses (Mad Scienstein, Wormwould, Wolfenboss, Doll Boy, Yellow Belly,
  Anonster, Scowler, Muddee, Jamano), the Shoot minigame, and the
  variable cart ported (WL3-047, done), every one of 3,833,825 Wario,
  7,721,186 object, and 3,845,136 interaction updates is identical in
  step mode with nothing unported, and all 3,258 movies run whole frames
  to the end. The movies reach only the battles' starts; the rest is
  translated and unit-tested but has not met the oracle (WL3-048).
  Left-facing and more room starts followed (WL3-049): `left-jump` and
  `left-attack` on the day-1 room starts, `wander` and `right-attack` on
  the night room starts, and `wander` on the later variants' 1,344 room
  starts met the solid spike, the Moon, Mizuuo, the big leaves, the Big
  Octohon, and Wario launched, all ported. More scripts and power-ups
  on those room starts met nothing new: 34 sweeps (11,082 movies) compare
  12,965,952 Wario, 26,744,689 object, and 13,003,290 interaction updates,
  all identical, nothing unported, and every movie runs whole frames to
  the end. A coverage-guided input search (`search-sN`) does not reach
  the battles (WL3-048). The owner's game movies (WL3-048) do: 17 so
  far (`ootw-gray-key`, `game-002` to `game-017`), checked a level visit
  at a time, match in every compared update and run whole frames to the
  end. The golf minigame is ported and drawn (WL3-050): every one of its
  9,297 traced game loops in four movies is identical, the runs play it
  natively, and its 256 compared screens equal the original's pixel for
  pixel. The level's clear screen is ported too (WL3-043): all 4,098 of its
  traced loops in the 17 movies are identical, with the treasure recorded,
  the counts, and the way out, and its 73 compared screens equal the
  original's pixel for pixel. So is Action Help after a power-up's
  treasure (WL3-051): all thirteen demos, checked on the two movies that
  reach it and on branches of one that show the rest (25,600 compared
  loops identical, every VRAM snapshot and screen as the original's), and
  the map's save screen every movie ends with (WL3-052: 2,494 loops, its
  SRAM and checksums, all identical), and the map as far as the movies
  reach it (19,478 loops identical), drawn too (586 VRAM snapshots and
  460 screens as the original's), and played natively from each movie's
  first map loop to its end ([native play](../02-research/native-play.md)).
  Block
  changes in traces now carry the phase of the frame they happened in,
  and the block map is compared after every object update and
  interaction. Levels can also start in any room (`ROOMS=1`).
- **Randomness:** the game's only random source, the hardware timer
  `rDIV`, is recorded at all 48 reads in the trace and replayed in parity
  checks; native play uses a seeded generator (provisional).
- **Runtime:** Godot 4.7.2 (standard), synthetic testbed room, prototype
  movement with integer subpixels, data-only mods, content-pack v1 and v2
  (labelled approximations), headless tests, and a Linux export verified
  outside the checkout. All movement constants are **provisional**.
- **Not done:** the level window was checked only through screenshots it
  saves itself (`--screenshot`, `make window-check`), with scripted input; no keyboard,
  controller, audio, or resize check of the game window on the desktop
  session (WL3-021). The owner used the TAS editor's keyboard input to
  record. No project license decision (WL3-016).

## How to resume

```sh
make doctor && make test && make smoke
make run                      # synthetic prototype window
make extract                  # needs the local ROM; writes block tables and materials, rooms, level headers, block maps
make room-pack                # needs the local ROM; builds and validates the first-room pack
make smoke-extracted          # headless run of that pack (SKIPPED without it)
make run CONTENT=local/content/packs/wl3-level-00-room-001   # window on that pack
make run LEVEL=0              # play extracted level 0 with the ported Wario; make smoke-level checks it headless
make oracle-check oracle-verify   # needs the ROM and PyBoy 2.7.0 (ORACLE_PY, default /usr/bin/python3)
make tas NAME=my-run START=ootw-day1-start   # TAS editor; make oracle-replay FILE=… checks a saved movie
make tas NAME=… SAVE=file.sav | STATE=sha-or-file | BOOTROM=file   # other starts
make review MOVIE=local/recordings/NAME.recording.json   # timeline, sheets, probes, map check
make test-rom                 # optional real-ROM checks (31 tests)
make wario-trace MOVIE=local/recordings/NAME.recording.json && make wario-parity MOVIE=local/recordings/NAME.recording.json
make sweeps SNAPSHOT=1        # the 34 regression sweeps (step and run) on a copy of game/, after every change
make sweep SCRIPT=wander [POWER_UP=9] [VARIANT=4|1,2,3 DISTINCT=1] [ROOMS=1] [MODE=run] [RECORD=1]   # one sweep
make action-help-movie MOVIE=local/recordings/NAME.recording.json POWER_UP_LEVEL=0x85 [TRANSFORMATION=owl] [SCRIPT=browse]   # a demo branched at Action Help's start
make screen-check MOVIE=local/recordings/NAME.recording.json TICKS=300,700   # background vs decoded room graphics
make sprite-check MOVIE=local/recordings/NAME.recording.json   # Wario's OAM, tiles, and pixels vs his decoded sprites
make window-check             # the game window vs the original's screen on the walk (opens windows briefly)
make save-load-check          # the save's load at power-on, captured from the movies' saves and checked
make continue-movie SAVE=sha NAME=… [PRESSES=200:a,600-1600:right TICKS=n]   # a power-on movie from a stored save (Continue, or scripted presses)
make run SAVE=sha-or-file.sav   # play from power-on with a battery save: the title, Continue, the map, the levels
```

## Next three tasks

1. WL3-048: the owner's game movies (a chain, one per level visit; see
   [owner's movies](../04-development/owner-movies.md)): trace, check, and
   port what they reach as the owner records more (17 so far, all
   matching).
2. WL3-052 and WL3-050: the map's paths no movie reaches, golf's fades
   and sound.
3. WL3-021: a desktop check by the owner.

Details and acceptance criteria are in [tasks](tasks.md).
