---
type: session
status: done
updated: 2026-10-12
tags: [session]
---
# 2026-10-02: Wario's next states, room transitions, and sprites (WL3-034, WL3-027, WL3-038)

The owner is away and asked for work to continue on M3.

## Outcomes

- **Attacking, attacking airborne, and bumping** are ported
  ([wario movement](../02-research/wario-movement.md), item 10). Ten more
  framesets are extracted. All 2700 compared updates of the owner's movie
  match; the first port had the bump's two framesets the wrong way round,
  which the check showed in 9 updates.
- Block breaking is now reached in compared updates; `BreakBlock`'s coin roll
  reads the hardware timer (`rDIV`), so `wCoinCooldown` alone is left out
  for those 6 updates.
- Whole-frame runs now split each frame where the original runs objects, so
  a run that stops because an enemy changed Wario says so: the movie runs
  164 frames alone and stops at frame 348 for that reason.

- **Crouching, sliding, and rolling** (the crouch states, crouch sliding,
  sliding, rolling, rolling airborne) are ported with eight more framesets;
  all 3018 compared updates match, the new states on the first run
  ([wario movement](../02-research/wario-movement.md), item 11).

- **Stung and ladders** are ported with six more framesets and two more
  traced variables (`wIsIntangible`, `wIsGettingOffLadder`); all 3269
  compared updates match, the new states on the first run (item 12).

- **Room transitions and doors (WL3-027)** are ported: the trigger, door
  entry, the level sub-states (door effect 34 loops, fades 33 each, room
  start 1), and the next room's start with its spawn and camera. All five
  transitions of the movie match in game loops and state, with no variable
  left out ([room transitions](../02-research/room-transitions.md)); the
  level-headers hypothesis about room-list entries is confirmed.

- **Wario's sprites (WL3-038)**: his tile sets, OAM tables, and palettes for
  the ported states are decoded (`make extract`) and equal the reference
  build. The states now set the eight graphics variables as the original
  (traced and compared: all 3309 updates still match). A new oracle check
  (`make sprite-check`) follows every V-Blank transfer and frame of the
  movie: Wario's OAM entries, his VRAM tiles, and 1,514,112 of his pixels
  all equal the decoded sprite. The window draws him from them and lays the
  priority tiles over him; `make window-check` finds its screenshots equal
  to the original's screen except under other sprites. Timing finding: the
  screen during tick *t* shows the loop that ended in tick *t − 1*, but
  `SetWarioPal` changes the palette mid-frame
  ([Wario's sprites](../02-research/wario-sprites.md)).

- **Objects (WL3-035), first part**: the trace records Wario's variables and
  WRAM bank 1's object region at four points per frame (`object_checkpoints`)
  plus five object globals; the object framesets are extracted (938, on the
  reference labels); `ObjectSim` ports the `UpdateObjects` framework and the
  musical coin. The objects check in `make wario-parity` reruns every
  `UpdateObjects` of the movie: 725 of 725 fully ported slot updates match.
  Two fixes on the way: the floor-transition update copies back the whole
  slot, and `INTERACTION_RIGHT` is `$20`.
- **The Spearhead** and the shared object states it uses are ported, with
  the object movement tables extracted and the slopes' object branch
  (`wObjSlopeInteraction`) added: 3142 Spearhead updates of the movie match
  on the first run (3827 of 3827 slot updates in all).
- **Interactions**: `ProcessInteractions` is ported with the types the first
  room needs and the trace records four more variables (touch states, coin
  counts). 5763 of 5763 runs without an unported type match, 21 with an
  effect; two transformation constants written from memory were wrong and
  are now taken from `wario_constants.asm`.
- **Spawning**: object groups extracted (146; equal to the traced pointers),
  `SpawnObject`, the room start's window, the edges' rows and columns,
  despawning, and the map reload. The trace records the object map; every
  spawn check of the movie is identical (level start, 5 transitions, 5796
  frames of edges).
- **Whole frames with objects**: the native frame runs objects and
  interactions in UpdateLevel's order; the movie runs 675 whole frames alone
  (every checkpoint identical) through the first room and its transition,
  the walk all 300; the window and `make smoke-level` load the objects.
  WL3-035 is done; drawing objects, more objects, and Wario's object states
  are WL3-039 to WL3-041.
- **Drawing objects (WL3-039, done)**: object OAM tables, each group's enemy
  graphics and palettes, and the common graphics extracted; the window
  draws objects in OAM order. `make sprite-check` now also checks every
  drawn object (10,547 of 10,547) and each group's VRAM; `make window-check`
  compares objects too, after the window plays the route's 60 loops (a first
  attempt differed only because the route's state is 60 loops into the
  level, which a native search pinned down).
- **Room 21's objects (WL3-040)**: the small leaf, Futamogu, Webber and its
  projectile (object creation from params, home-bank update functions), and
  the walkable interaction; all their updates in the movie match (6238 slot
  updates in all), and whole frames run 937 frames alone.
- **Electric shocks, keys, coins, and randomness (WL3-034, WL3-040)**: the
  electric transformation (131 updates) and its interaction; the keys and
  `CollectKeyDelay`'s 100-loop pause (`wState` and `wTimer` now run
  natively); the coin a broken block leaves, `CoinFunc`, and the coin and
  colour-coin interactions. The colour-coin blocks had been given
  `BreakBlock`'s roll; they always leave a colour coin. `rDIV`, the game's
  only randomness, is now recorded at all 48 reads (found by labelling them
  in a rebuilt copy of the disassembly; the ROM was unchanged) and replayed
  in parity checks, so no variable is left out for it any more. Whole frames
  run 2417 frames alone, to the first torch (frame 2863).
- **Torches, birds, and chests (WL3-040)**: all their updates match on the
  first run (12703 slot updates in all); whole frames run 2721 frames, to
  Silky in the chest's room (frame 3282).
- **Silky and Ball o' String (WL3-040, WL3-034)**: Silky's 24 reached
  states (1640 updates) and the six Ball o' String states (679 updates)
  match on the first run; whole frames run 3343 frames, to fire (frame
  3985).
- **Fire and On Fire**: the fire interaction, the five On Fire states (745
  updates, with `wTransformationDuration` now traced), and stepping on
  objects while transformed match on the first run; whole frames run 4989
  frames, to the chest (frame 5746).
- **The treasure and particles**: the treasure interaction, the treasure
  scene's eleven states (812 updates; their framesets in "Wario OAM 2"),
  and the particle system (the clear waits on the glow's animation), with
  the particle region now traced at every checkpoint. Every Wario update
  of the movie matches (5676), every interaction run (5802), and the whole
  movie's 5802 level frames run natively from its input alone. The sprite
  check now leaves out frames after the level ends, which it had compared
  against the level's palette during the clear screen's fade.
- **Particles drawn (WL3-042, done)**: the window draws them from their
  decoded graphics; `make sprite-check` checks all 1537 drawn particles'
  OAM entries, and `make window-check` compares their pixels too.
- **Room animation (WL3-037, done)**: animated tiles and palette cycles
  ported, with the loops' late-frame skips (CPU timing) recorded and
  replayed; the level's end check (`check_end_screen`) and a labelled pause
  stand-in. The whole movie still runs natively, now with the animation
  variables compared; `make screen-check` matches every background pixel
  at frames with animated blocks.

## Tests

- **Other levels**: oracle starts at any level (`make level-movie`) and a
  coverage sweep of all 25 levels' starts: every compared Wario update
  matched everywhere; what they meet unported is ranked
  ([emulator oracle](../02-research/emulator-oracle.md), item 17).
- **Water (WL3-034)**: the water blocks and Wario's eight water states,
  with currents and the swim speed tables; every water update of the
  sweep's nine water levels matches on the first run.
- **Enemy bumping (WL3-041, done)**: `UpdateState_EnemyBumping`; all 102
  bumping updates of the six levels with bumps match on the first run.
- **Para-Goom (WL3-044)**: ported in a new `EnemyFunctions` class; all
  5342 of its slot updates on the sweep's four Para-Goom levels match on
  the first run. Unported enemy states now leave their slot unjudged (they
  had used the loading-time note); the sweep's 25 levels show no Wario or
  object mismatch.
- **Brrr Bear and its snowflakes (WL3-044)**: all 2189 Brrr Bear and 281
  snowflake updates on its four levels match on the first run; the
  snowflakes' params are extracted (objects extractor version 12).
- **Sand (WL3-045)**: the sand block and Wario's five sand states; all
  1058 sand updates of level 30 match on the first run, and that level's
  Wario updates are now all compared (1200, from 136). The sweep's 25
  levels show no Wario or object mismatch.
- **Fat Wario and the ground shake (WL3-045)**: the food interaction, the
  nine fat states, `HandleGroundShake` with both stuns; all 585 fat and 24
  stunned updates match on the first run, and level 08 compares all 1200
  Wario updates (597 before). Two test expectations were wrong at first
  (the stun's first step comes the same frame; the shake's phase), not the
  port. `HandleGroundShake` now returns first at the level's end screen,
  as the original.
- **Picked up (WL3-045)**: `ObjInteraction_Omodonmeka` and
  `UpdateState_PickedUp`, with the two wiggle counters added to the trace
  (level a8 re-traced); all 513 updates match, and the sweep compares
  29,255 of its 29,826 Wario updates, all identical.
- **Ice Skatin' (WL3-045)**: `ObjInteraction_Ice` and the four states;
  all 281 updates and the 11 interaction runs with an effect match on the
  first run; the sweep compares 29,536 of 29,826 Wario updates.
- **Block handlers (WL3-045)**: slippery blocks, cloud platforms, fences,
  light sources, `BlockFunc_188ba`, and the minigame door; levels 88, 98,
  a0, and c0 now compare every Wario update. The sweep compares 29,798 of
  29,826 Wario updates and 33,928 object slot updates, all identical.
- **Zip lines and hanging (WL3-044, WL3-045 done)**: `ZipLineFunc` in a
  new `DeviceFunctions` class, `ObjInteraction_Rail`, and the hanging
  state; all 3679 zip-line slot updates and 28 hanging updates match on
  the first run. Every one of the sweep's 29,826 Wario updates is now
  compared and identical, with 37,607 object slot updates.
- **Pillar platforms and Haridama (WL3-044)**: with the water spike, the
  underwater door, `SetState_WaterStung`, and `Func_20899`; 2867 pillar
  and 1999 Haridama slot updates match, and level 40 compares all its
  objects. The sweep: 42,441 object slot updates, all identical.
- **The hand (WL3-044)**: its 16 steps, and its null frameset (ROM0
  from `$0000`, now extracted); all 2301 slot updates of level 30 match.
- **Spear Bot (WL3-044)**: all 1725 compared slot updates on levels 18
  and 20 match on the first run; one test expectation was off by a pixel
  (the wall probe's reach), not the port.
- **Hammer Bot (WL3-044)**: all 1067 slot updates of level 20 match;
  level 20 compares all its objects.
- **A test gap, fixed**: `make test-rom` failed at commits `7c13ad9` (the
  hand) and `e6e8564` (Hammer Bot): its frameset check compared every
  extracted frameset with the reference build's bank `$1a` labels, and the
  new null frameset (`0000`) is not one. It was not run before those two
  commits. The test now checks the null frameset against ROM0's bytes
  and the rest against the labels; `make test-rom` passes (31).
- **The flame block and its torches (WL3-044)**: all 967 torch slot
  updates of level 70 match (none lit there), and level 70 compares all
  its objects.
- **Hebarii (WL3-044)**: with its projectile and `DummyObjectFunc`; 1927
  and 462 slot updates on levels 28 and 60 match on the first run.
- **The owl, the tadpoles, and the barrel (WL3-044)**: 332, 709, and 550
  slot updates match; level 68 compares all its objects.
- **Teruteru (WL3-044)**: with `_ApplyObjYMovement_Loop`; all 597 slot
  updates of level 10 match, and level 10 compares all its objects.
- **The zombie (WL3-044)**: with its head, `_ApplyObjXMovement`, and the
  enemy blocks' solid path; 340 and 55 slot updates of level a0 match,
  and level a0 compares all its objects.
- **Fire Bot (WL3-044)**: Spear Bot's code with its own parameters (a
  normalised diff of the sources); 2400 slot updates of level 78 match,
  and Spear Bot's levels are unchanged. 23 of 25 sweep levels now
  compare all their objects.
- **The Doughnuteer (WL3-044)**: with its doughnuts and the shared
  ground-shake states `$1a`-`$1c`; one condition was inverted in the
  first draft (the bump's exit) and caught on rereading the source before
  any run. All 2439 and 210 slot updates of level 08 match; 24 of 25
  levels compare all their objects (58,538 slot updates, all identical).
- **The clear gate and Pneumo (WL3-044)**: 69 and 92 slot updates of level
  a8 match; `wIsMinigameCleared` is traced and Pneumo's bob extracted.
- **Omodonmeka (WL3-044)**: 627 slot updates of level a8 match on the
  first run, including Wario's catch, lift, and hold.
- **The Omodon and its carrier (WL3-044)**: 334 and 348 slot updates of
  level a8 match once `BlockFunc_SmallGap` (met by the Omodon's fall) is
  ported; `BlockFunc_189f1` beside it is ported but not met. A temporary
  print, removed before committing, showed which paths a8 reaches: the
  wait, lowering, lift, fall, and landing. One unit-test expectation of
  mine was wrong (the landing height: the probe leaves `hYPos` at the
  floor's top, and the Omodon takes it less 15). The sweep: 25 levels,
  29,826 of 29,826 Wario updates and 60,008 of 60,008 object slot
  updates, none unported. Run mode: 21 levels run all 1200 frames; 40,
  68, a0, and a8 stop at interactions `$2f`, `$3c`, `$0b`, and `$0a`.
- **Interactions (WL3-044)**: those four, the Omodon's `$22` and `$23`,
  and `Func_20602` (objects item 37). A temporary print, removed before
  committing, showed the movies reach the `$0a`/`$0b` bounces, the stove
  from the side, and a tadpole head on. `Func_2023b` with
  `TOUCH_VULNERABLE` would have recursed without end in the port (the
  original loops there too) and is now noted as unported instead. One
  unit-test expectation of mine was off by a pixel (an overlap of 5, not
  6). All 25 levels now run whole frames alone to the end; the step
  sweep compares 29,919 interaction runs, all identical.
- **New scripts and the attack sweep (WL3-044)**: `right-attack`,
  `right-crouch`, and `wander` level movies; `right-attack` recorded on
  all 25 levels. It met the water spark (level 18), `VanishObject2`
  (level 20), and interaction `$3b` (level 68), now ported, with
  `Func_20b6b`'s ladder and facing checks. Every compared update
  matches (Wario 28,804, objects 62,394, interactions 29,998); Flat
  Wario on level a8 (1103 updates) is next.
- **Flat Wario (WL3-044)**: the states `$65`-`$6f`, the fall tables and
  framesets (movement extractor 15), `OAM_16e9d` (sprites extractor 10),
  and the interactions' flat branches. Level a8's attack movie matches
  all 1200 Wario updates on the first run and runs to the end; its
  sprite-check matches every pixel of Wario. One unit-test expectation
  of mine was off by one (the flat jump's 24 updates to its peak). Both
  sweeps now match every update and run every level to the end.
- **Crouch and wander movies (WL3-044)**: recorded on the 25 levels;
  `BlockFunc_Fire` (its `hCallFunc` return of `$06` included), the
  bonfire variants, and interactions `$06` and `$21` ported. The crouch
  sweep matches every update; the wander sweep compares 29,495 of
  29,874 Wario updates, all identical, and names what is left.
- **Zombie Wario (WL3-044)**: the states `$87`-`$8f`, the zombie head,
  the knock-back, and the light source's recovery; framesets (movement
  extractor 16), graphics, OAM, and the eight palettes the recovery
  steps through (sprites extractor 11). Level a0's wander movie matches
  all 1200 Wario updates on the first run and every pixel of Wario. One
  unit-test expectation of mine was wrong (the palette after recovery is
  the default one).
- **Blind Wario (WL3-044)**: the states `$dc`-`$df` and Teruteru's
  interaction; `ClearTransformationValues` now clears
  `wSwimmingDirectionInput` too, as the original does (found while
  reading it). Level 10's wander movie matches all 1200 updates on the
  first run. One unit-test expectation of mine assumed 1 px walk steps
  (the fixture's are 2 px by then).
- **Enemy graphics check (sprite-check)**: level 20's movies reported
  VRAM bank 1 differing for object group `$12`. A diff showed 16 tiles
  (`$30`-`$3f`) the game leaves from earlier screens because the group's
  first slot is only `$300` bytes; the extraction now records each slot's
  written span (objects extractor 21) and the check compares only those.
  Both movies of level 20 then pass.
- **Bouncy Wario (WL3-044)**: the states `$90`-`$96`, the bouncy
  interaction, `Func_2a0b2` from `StepOnObject`, and the red flicker;
  framesets (movement extractor 17), graphics, OAM, and palettes
  (sprites extractor 12). Level 20's wander movie matches all 1200
  updates on the first run. A duplicate constant (`WST_BOUNCY_AIRBORNE`
  was already declared) broke the parse once; one test expectation of
  mine forgot the time already run.
- **Slipping (WL3-044)**: the states `$30` and `$31` and their three
  entries. Level 98's wander movie matches all 1200 updates on the first
  run. The test fixture's handler table is a `PackedStringArray`, copied
  on assignment, which my first test edit missed; one expectation of
  mine assumed a stop leads straight to walking (it idles first).
- **Multi-block breakables (WL3-044, done)**: all 47 handlers of the five
  kinds, `ProcessMultiBlock`, and `SST_LEVEL_MULTI_BLOCK`. Level b8 first
  showed 52 mismatched updates: step mode kept the port's own
  `wMultiBlockParam` into later updates, where the original clears it the
  next frame; it is now traced (`$ceda`), and b8's and 58's wander movies
  were re-traced. Comparing the four directions of each kind with labels
  as names hid a difference (a roll into `Func_190fe`'s needs the
  overalls); comparing them by label position found it. All four sweeps
  now match every update (119,514 Wario, 238,440 object slot updates) and
  all 100 movies run whole frames to the end. All of them start with no
  power-ups (WL3-046 next).
- **Power-up starts (WL3-046)**: `make level-movie POWER_UP=N` sets
  `wPowerUpLevel` once the level has settled, recorded in the origin and
  replayed by `make state-check` (level 08's start with all power-ups
  rebuilt OK).
- **Power-up sweeps (WL3-046)**: `wander` and `right-attack` with every
  power-up on the 25 levels. No Wario update differs; the smash attack
  leaves the most uncompared (7130 and 6359 updates). Two Spearhead slot
  updates on level 00 first showed as mismatched: an unported
  `HandleGrabbedObjectCollisions` had moved them, but its note was
  attributed to no slot; such a frame now leaves every slot unjudged.
- **The smash attack (WL3-046)**: the airborne smash attack, the ground
  pound and ground shake landings, and `WST_SMASH_ATTACKING`. Level 08's
  power-up wander movie matches all 1200 updates on the first run; the
  power-up sweeps compare 29,666 and 29,343 Wario updates, all
  identical, and the four base sweeps stay as they were.
- **Grabbing and throwing, Wario's side (WL3-046)**: the pick-up, the
  states `$1e`-`$26` and `$3f`, and the interactions' grab branches. The
  port's `GRAB_IDLE` was 1 where the original's is 3 (found reading the
  constants). The power-up wander sweep compares all 29,804 Wario
  updates, every one identical on the first run; a duplicate constant
  broke the parse once.
- **Grabbing, the objects' side (WL3-046)**: picked up, held, charged,
  thrown, full throws, and `HandleGrabbedObjectCollisions` (with its
  HRAM states kept between frames), for the Spearhead and Para-Goom.
  Every Wario and object update of levels 00, 38, and 48's power-up
  movies matches on the first run; both power-up sweeps leave no object
  update unported.
- **Crazy Wario and the last interactions (WL3-046, done)**: the states
  `$97`-`$9b` from the orange bird, and interactions `$3d` and `$28`
  (its owl grab from below named as unported, not met). All six sweeps
  (150 movies) now compare every update: 179,063 Wario updates, 350,391
  object slot updates, 179,653 interaction runs, all identical, and
  every movie runs whole frames to the end. One test expectation of mine
  held the pad his own way.
- **Night starts and `make sweep` (WL3-047)**: a tracked sweep tool
  replaces the scratch scripts. The first night sweep poked only
  `wLevel`, so it ran night maps in daytime (`wDayNight` 0) and met
  nothing new; the poke now sets `wDayNight`'s bit 0 for a night level
  as `SelectLevel` implies, and the night `wander` sweep, re-recorded,
  compares all 29,843 Wario updates and 47,751 object slot updates,
  identical, leaving the Spearhead's sleep (`$2d`) unported.
- **The Spearhead asleep (WL3-047)**: `.SleepStart`, `.Sleep`, and the
  wake are ported (objects item 42); the night `wander` sweep compares
  52,255 object updates, all identical, nothing unported, and runs all
  25 levels to the end in run mode.
- **Night sweeps, all six scripts (WL3-047)**: the other five scripts'
  night movies (125, recorded in parallel) met one difference: a thrown
  Spearhead breaking an enemy block on level 04 (`Func_19423`, ported,
  objects item 43). It hid behind the trace's once-a-frame block
  sampling, so block changes now carry the checkpoint they were seen at
  and the object and interaction steps compare the map too (emulator
  oracle item 16); all 302 traces were re-recorded. The twelve sweeps
  (six scripts, day 1 and night 1) then compare 358,037 Wario, 683,783
  object, and 359,217 interaction updates, all identical, nothing
  unported, and all 300 movies run whole frames to the end.

- **Later variants (WL3-047)**: 85 later
  day/night variants with their own room list or map, six scripts each
  (510 movies), compare every Wario, object, and interaction update
  identically in step mode (run mode not yet run). They met pipes
  (`BlockFunc_DownPipe_*`, `_UpPipe_*`, `UpdateState_PipeGoing*`), the
  Snake and its fire, and Fire Bot's grab entries. Pipes and the Snake
  are ported (wario movement item 33, objects item 44), and the bots'
  grab entries (objects item 45). Re-swept: 608,483 Wario, 1,099,806
  object, and 610,843 interaction updates, all identical, nothing
  unported, all 510 movies to the end in run mode. `make level-movie
  ROOM=n` and `make sweep ROOMS=1` start levels in other rooms (408 on
  day 1).
- **Room starts (WL3-047)**: the 408 day-1 room starts for all six
  scripts, with day 1, night 1, and the later variants: 24 sweeps,
  3,258 movies. They met most of the remaining Wario states (Vampire,
  Owl, Snowman, Split, Fan, Magic, ball, bubble, teleports), the block
  handlers below the map and in its switches, and some 60 more object
  kinds, ported one by one (wario movement items 33-42, block handlers
  item 8, objects items 42-65): every one of 3,833,825 Wario updates,
  7,535,481 object updates, and 3,845,136 interaction runs is identical
  in step mode. In run mode 60 room starts first stopped at a
  difference that no step showed: the start's particles updated twice,
  the bubble object's `_bubble_drift` silently replacing Wario's in
  every `LevelSim` (a new test fails on any unlisted method a subclass
  redefines), and the owl particle unported with its note cleared
  (emulator oracle item 17). Now 3,135 of the 3,258 run whole frames to
  the end and the rest stop at code not ported (bosses, the Shoot
  minigame, a few objects); none at a difference. The object step also
  leaves slots unjudged after unported code that wrote past the slots.
  Still unported, by step updates: Mad Scienstein (34k), Wolfenboss,
  the Skull spawner, GK Tortoise, the Yellow Belly and Doll Boy parts,
  Anonster, the Shoot minigame's ball and keeper, Wormwould's battle,
  Jamano, the Sun, the Scowler, Muddee, and a few more.

- **The bosses, the Shoot minigame, and the last stops (WL3-047, done;
  into 2026-10-03)**: Mad Scienstein, the Sun, Wormwould with its rocks,
  Wolfenboss with its spirals, the Igaguri, and the Kuri, Doll Boy, Yellow
  Belly, Anonster, Scowler, Muddee with the turtles, Jamano with the
  skulls, Shoot and GK Tortoise, the variable cart, and Wormwould's palm
  trees, each in its own commit, in a new `BossFunctions` class (objects
  items 66-78). Two run-mode stops needed the oracle: the variable cart
  reads one treasure byte (now traced as `wTreasuresCollected7`), and a
  probe past the map's right edge reads SRAM bytes the level never writes
  (now traced as `block_gap_rows`; block handlers item 8). Seven movies
  were traced again for them. Shoot enters two framesets at their second
  pair, which the extractor now decodes too. Every one of 3,833,825
  Wario, 7,721,186 object, and 3,845,136 interaction updates is identical
  in step mode, nothing is unported, and all 3,258 movies run whole
  frames to the end. The scripted movies reach only the battles' starts:
  Muddee never leaves the water, no skull is knocked, nobody plays the
  minigame. The rest is translated and unit-tested on invented data but
  has not met the oracle (WL3-048).

- **Longer boss-room movies (WL3-048)**: `TICKS=n` (named `-tN`),
  `left-attack`, and seeded wanders (`wander-sN`); 176 movies of 3600
  ticks in the 11 boss rooms compare 627,556 Wario, 1,473,388 object, and
  631,546 interaction updates, all identical, and reach Shoot's ball
  form, Scowler's swallow, Yellow Belly's arrow hit, and Wolfenboss's
  Igaguri and Kuri (objects item 79). The defeats and the harder phases
  still need inputs that fight. `make test` (215 Python; Godot 242) for
  both tooling commits.

- **Left-facing and more room starts (WL3-049)**: `left-jump` and
  `left-attack` on the 408 day-1 room starts, `wander` and `right-attack`
  on the 408 night room starts, and `wander` on the 1,344 room starts of
  the later variants with their own data. They met `BlockFunc_SolidSpike`,
  the Moon (the Sun's code with its own looks), Mizuuo, the big leaves,
  the Big Octohon, and Wario launched by it (`$e1`, `$e2`, with their
  graphics). All are ported, each with its sweeps, and `make
  sprite-check` matched the launch's pixels. Now 29 sweeps (6,234
  movies) compare 7,302,729 Wario, 14,799,775 object, and 7,323,217
  interaction updates, all identical, nothing unported, and every movie
  runs whole frames to the end. `make test` (215 Python; Godot up to 244)
  and `make test-rom` (31) after each extraction change.

- **More room starts and a search (WL3-049, WL3-048)**: `right-attack`
  and `right-jump` on the later variants' room starts, `left-jump` on the
  night room starts, and `wander` with every power-up on both met nothing
  new. 34 sweeps (11,082 movies) compare 12,965,952 Wario, 26,744,689
  object, and 13,003,290 interaction updates, all identical, every movie
  to the end. A coverage-guided input search (`search-sN`) explores the
  boss rooms but reaches no new object function in 44 movies of 7200
  ticks; the battles need goals per boss or the owner's movies.

- **The owner's game movies (WL3-048, 2026-10-03)**: the owner recorded
  the game as a chain of 17 movies (`ootw-gray-key`, `game-002` to
  `game-017`; [owner's movies](../04-development/owner-movies.md)), renamed
  by level and key as they were finished (`game-013` cut to 8859 frames at
  the owner's request). Each was traced and checked in step and run mode.
  They brought the level start clearing what the original's does, the hand
  dragging Wario down, a ladder slide's ground pound, `Func_ba42`'s spawn,
  the unlit torch (objects items 83-84), block reads above the map
  (replayed from the trace), checking a movie a level visit at a time
  (`game-016` enters three), and golf: the level's side ported, the
  minigame replayed by its traced loop count and outcome (room
  transitions item 5). Every compared update of all 17 matches, and all
  run whole frames to the end. A level resumed from a save is not
  modelled; its start is reported as not checked. Before the torch,
  above-map, and visit commits, all 34 sweeps ran in step and run mode,
  unchanged (11,082 movies, all identical, all to the end). For the golf
  commit, `make test` (220 Python; Godot 246) and `make test-rom` (33)
  passed, and the four golf movies were checked in both modes. Its sweeps
  were stopped for a restart after 28 of 34 step sweeps and rerun whole
  after it (2026-10-05): all 34 in step and run mode unchanged (11,082
  movies, every update identical, every movie to the end).

- **The golf minigame (WL3-050, 2026-10-05)**: translated whole
  (`GolfSim`: the lobby, the 14 hole states, the Para-Goom's flight and
  terrain, the clear cutscene, the V-Blank functions' writes), with its
  framesets, holes, and stroke digits extracted (`wl3pc.extract.golf`) and
  every golf loop traced (`golf_updates`; [golf](../02-research/golf.md)).
  The first run differed only at the fades' last loops, because the trace
  lacked the fade counter; traced again with it, all 9,297 compared loops
  of the four golf movies are identical. Parity runs now play golf
  natively on each loop's traced joypad: the transitions through golf and
  the whole-frame runs match to the end, and all 17 movies pass. Then the
  drawing: the tracer also records golf's virtual OAM every loop, and both
  VRAM banks and the screen every 32 loops (rendering golf's ticks). The
  port builds the same virtual OAM in every loop, its VRAM model
  (`GolfVram`) equals all 289 snapshots on every byte golf wrote, and its
  renderer (`CgbScreen`) equals all 256 compared screens pixel for pixel
  (five first differed in their cloud rows: the screens were taken a few
  lines into the next frame; taken at the tick's end, all match). The game
  window now draws golf from it (about 5 ms a frame). All 34 sweeps in step
  and run mode were unchanged with the port in place (11,082 movies, every
  update identical, all to the end); the drawing touches only golf.
  `make test` (224 Python; Godot 256) and `make test-rom` (33).

- **The level's clear screen (WL3-043, 2026-10-05)**: the screens' tracing
  is now shared (`ScreenTrace`: golf and the clear screen), and so is the
  port's base (`ScreenSim`: the virtual OAM, the fades at three speeds with
  the V-Blank function they set aside and put back); golf, moved onto it,
  is unchanged in all four movies. `ClearSim` translates
  `_ClearScreenStateTable` ([clear screen](../02-research/clear-screen.md)),
  with its framesets, OAM tables, and tables extracted
  (`wl3pc.extract.clear`). A level visit now includes its clear screen.
  All 4,098 compared loops of the 17 movies are identical on the first
  run, and so are all 17 ways out once the loop that leaves was kept in its
  visit's window. All 34 sweeps in step and run mode are unchanged (the run
  pass rerun after the session went down); `make test` (228 Python; Godot
  262) and `make test-rom` (34).
  Then the drawing: golf's VRAM model and renderer became shared
  (`ScreenVram`, `CgbScreen`), and `ClearVram` follows the clear screens'
  loads and V-Blank writes. All 119 VRAM snapshots of the 17 movies match,
  and all 73 compared screens are identical to the original's pixel for
  pixel, once the tracer recorded the line of each animated tile chunk the
  coin screen's background is copied with during the frame (three screens
  of `game-016` caught a copy half done). The game window draws both
  screens. `make test` (228 Python; Godot 263), `make test-rom` (34), the
  smoke tests, and all 17 movies. All 34 sweeps in step and run mode were
  unchanged after the drawing (11,082 movies, every update identical, all
  to the end).

- **Action Help (WL3-051, 2026-10-05)**: the owner asked for Action Help
  next, after the clear screen. `ActionHelpSim` translates
  `_ActionHelpStateTable` and all thirteen demos
  ([Action Help](../02-research/action-help.md)), on a `MenuScreenSim`
  base it shares with the clear screen (their menu objects are the same
  WRAMX bank 3 RAM, now shared in the port too). Lead overalls and the
  swimming flippers were translated first and matched both movies that
  reach Action Help on the first run (`game-006`, `game-017`: 1,995
  loops). For the other eleven, a new oracle command branches `game-006`
  at Action Help's start with the power-up poked (`make
  action-help-movie`); four subagents translated them in parallel, each
  in its own copy of the game, against those branches. All 23,605
  compared loops of the 15 branches are identical, with 12 ways out (to
  the map, or the pause menu's state when browsing). The drawing
  (`ActionHelpVram`) first left the demo's area black: the renderer's
  cached palette was the same packed array the VRAM model changed in
  place; then the special demos' objects were black: the fade in sets the
  OBJ palettes too. With both fixed, every VRAM snapshot (792) and screen
  (790) matches. `FillBGMap0` clears the attributes rather than filling
  them (unseen until now). The 17 movies pass in step and run mode with
  Action Help inside a level visit. `make test` (232 Python; Godot 272),
  `make test-rom` (34), the smoke test, the docs check, and `make
  state-check` on two branch starts. All 34 sweeps in step and run mode
  were unchanged after it (11,082 movies, every update identical, all to
  the end).

- **The map's trace (WL3-052, 2026-10-05)**: every movie starts on the map
  and ends there after a save (the owner's note). The tracer now records
  the map's loops too (`OverworldStateTable`) and those of the pause
  menu's state table (`_PauseMenuStateTable`), which runs the map's save
  screen without showing a menu, with WRAMX bank 2 and SRAM bank 0, a RAM
  range's address telling which memory it is
  ([the map](../02-research/overworld.md)). The 17 movies, traced again,
  show 19,531 map loops (the map side, the scenes, nine unlock cutscenes,
  five visits to the golf building) and 2,917 loops in that table: every
  movie's save screen writes its SRAM in one loop (`Save`), and only
  `game-016` opens the pause menu itself (The Pool of Rain), saving from it
  in the level. Not ported yet. The owner pointed out that the movies have
  no pause menu but that one; the notes first called the save screen the
  pause menu's save.

- **The save screen (WL3-052, 2026-10-05)**: while the sweeps ran,
  `PauseMenuSim` translated the map's save screen (the backup, the bar,
  `Save` into SRAM bank 0 with its checksums, the complete box, the way
  back), on a `MenuScreenSim` that now keeps SRAM bank 0
  ([the map](../02-research/overworld.md), item 6). The trace records
  `wPendingSubState` as a variable (the LevelSim's). The harness's Action
  Help check became a check for any menu screen, used by both. All 2,494
  compared loops of the 17 movies match on the first run, and all 18 ways
  back to the map; drawn (`SaveScreenVram`), all 71 VRAM snapshots and 44
  screens match. The pause menu itself (`game-016`) is counted as not
  ported, and VRAM snapshots are now taken only of ported loops. All 34
  sweeps in step and run mode were unchanged after it (11,082 movies, every
  update identical, all to the end).

- **The map (WL3-052, 2026-10-05)**: the map is ported as far as the
  movies reach it ([the map](../02-research/overworld.md), item 7). Its data
  is the ROM banks it reads, kept whole, so the port follows the original's
  pointers. Subagents translated it in five parts in their own copies, each
  checked against the 17 movies before the next (InitMapSide's 28 loops
  first, then the map side's loop, then the scenes and the cutscenes in
  parallel, then the golf building); I reviewed and merged each, moved one
  rule that only the check needs from the sim into the harness, and in the
  merge of the parallel parts kept one copy of the routines both had
  translated (one tested a flag's bit number for its mask). All 19,478
  compared map loops and 36 ways out match. Not drawn, and not loaded in
  the game yet (a level entered from the map needs its own start). `make
  test` (238 Python; Godot 284), `make test-rom` (34), the docs check, and
  all 17 movies in step and run mode. All 34 sweeps in step and run mode
  were unchanged after it (11,082 movies, every update identical, all to
  the end).
  `make test-python` (233) and `make test-rom` (34).

For the last commits (`9727a24` to `56e82fb`): `make test` (212 to 215
Python; Godot 222 to 226) and, where extraction changed, `make test-rom`
(31), with all 24 sweeps in step mode for each, and in run mode at
`8b77cca`, `e0c9bff` (with `3b678f9`'s ports), and `56e82fb`.

For the bosses' commits (`7845f88` to the palm trees): all 24 sweeps in
step and run mode for each (each message gives its totals), `make test`
(215 Python; Godot up to 242), and `make test-rom` (31) after each
extraction change. The gap-bytes commit changed no extraction, so `make
test-rom` was skipped for it. For the Shoot commit, `make test-rom` first
failed: its frameset test expected only labelled framesets. The test now
checks the two mid-frameset entries against their labels.

Observed passing: `make test` (203 Python; Godot 174), `make test-rom`
(31), `make smoke-level`, `make wario-parity` (step and run, movie and
walk), `make sprite-check` (movie and walk), `make window-check` (the
window opened briefly for each of 5 ticks). `make docs-check` and
`make repo-check` passed before each commit. For the Omodon commit:
`make test` (203 Python; Godot 179), `make test-rom` (31), `make
wario-parity` on the movie (step and run), and the sweep (step and run).
For the interactions commit: `make test` (203 Python; Godot 184), `make
test-rom` (31), the movie (step and run), and the sweep (step and run).
For the attack-sweep commit: `make test` (204 Python; Godot 186), the
movie (step and run), and both sweeps (step and run); `make test-rom`
skipped (no extraction change). For the Flat Wario commit: `make test`
(204 Python; Godot 189), `make test-rom` (31), `make sprite-check` (the
movie and level a8's attack movie), the movie (step and run), and both
sweeps (step and run).
For the fire-block commit: `make test` (204 Python; Godot 192), the
movie (step and run), and the right-jump, wander, and crouch sweeps
(step); `make test-rom` skipped (no extraction change). For the Zombie
Wario commit: `make test` (204 Python; Godot 197), `make test-rom` (31),
`make sprite-check` (the movie, level a0's wander movie), the movie
(step and run), all four scripts' sweeps (step), and the right-jump and
wander sweeps (run). For the Blind Wario commit: `make test` (204
Python; Godot 200), the movie (step and run), all four sweeps (step),
the wander sweep (run), and `make sprite-check` on level 10's wander
movie; `make test-rom` skipped (no extraction change). For the Bouncy
Wario and sprite-check commits: `make test` (204 Python; Godot 204),
`make test-rom` (31), `make sprite-check` (the movie, level 20's two
movies), the movie (step and run), all four sweeps (step), and the
wander sweep (run). For the slipping commit: `make test` (204 Python;
Godot 206), the movie (step and run), all four sweeps (step), and the
wander sweep (run); `make test-rom` skipped (no extraction change).
For the multi-block commit: `make test` (204 Python; Godot 208), `make
test-rom` (31), `make sprite-check` (the movie, level b8's wander
movie), the movie (step and run), and all four sweeps (step and run).
For the smash attack commit: `make test` (205 Python; Godot 211), `make
test-rom` (31), `make sprite-check` (the movie, level 08's power-up
wander movie), the movie (step and run), and the four base sweeps and
both power-up sweeps (step and run).
For the grabbing commit: `make test` (205 Python; Godot 214), `make
test-rom` (31), `make sprite-check` (the movie, level 38's power-up
wander movie), the movie (step and run), and all six sweeps (step and
run). For the objects' grabbing commit: `make test` (205 Python; Godot
216), the movie (step and run), and all six sweeps (step and run);
`make test-rom` skipped (no extraction change). For the Crazy Wario
commit: `make test` (205 Python; Godot 218), `make test-rom` (31), `make
sprite-check` (the movie, level 60's power-up attack movie), the movie
(step and run), and all six sweeps (step and run).

## Next action

Resumed and closed on 2026-10-12: the map's drawing below was checked and
merged; see [2026-10-12 map drawing](2026-10-12-map-drawing.md).

Paused for a restart (2026-10-05). Everything checked is committed and
swept. In progress, not committed: the map's drawing, in the ignored copy
`build/agent/mapdraw` (a full copy of `game/`). A subagent had written an
`OverworldVram` model, recording in the map's sims, the window's drawing,
and the start of its unit tests when it was stopped; none of it is checked
yet. Resume by checking that copy against the movies'
`overworld_vram`/`overworld_screens` (`build/agent/screen_check.py MOVIE
COPY overworld`), finishing it there, and merging it like the other
screens; or start the drawing again from `game/` if the copy is not worth
keeping. Notes from the session: `build/agent/map-plan.md`,
`build/agent/mapdraw-scratch/`.

Then WL3-052: entering a level from the map in the game (the level's
sub-states 0-2, `InitLevel` loading the chosen level's data by `wLevel`;
the 140 extracted level variants), so play goes on from a level through
the clear screen, Action Help, the map, and the save, into the next level.
WL3-048: movies that fight the bosses and play the Shoot minigame.
