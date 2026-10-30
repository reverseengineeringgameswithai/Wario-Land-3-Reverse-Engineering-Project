---
type: research
status: active
updated: 2026-10-01
tags: [research, movement, collision, validation]
---
# Wario movement

**Question:** how does Wario move frame by frame (walking, turning, jumping,
falling, landing), and can a native port reproduce it exactly?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/wario_states_1.asm`,
`collisions.asm`, `block_functions.asm`, `src/home/wario_mechanics1.asm`,
`wario_mechanics2.asm`, `move_wario.asm`, `sprite.asm`,
`floor_transition.asm`); the [emulator oracle](emulator-oracle.md) (PyBoy
2.7.0); the owner's Out of the Woods recording (`ootw-gray-key`, 8363
frames). Task: WL3-012. Decision: [ADR-0003](../03-architecture/adr-0003-wario-port-by-translation.md).

## Verified observations

1. **Tables.** `make extract` decodes `WalkVelTable` (`00:196f`, `$1c`
   entries), the five jump tables (`00:18a7` to `00:1947`, `$28` signed
   entries each, consecutive in bank 0), and twelve Wario framesets
   (`05:4252` to `05:5fa1`) into `local/content/wl3-original/wario_movement.json`
   (`tools/wl3pc/extract/wario_movement.py`). Every table and frameset lands
   on its label; framesets are (frame, duration) pairs ending in `$ff`.
2. **Walking** (`HandleInput_Walking`, `ApplyWalkVelocity`). Each frame
   with a direction held: the front check, then the step
   `WalkVelTable[wWalkVelIndex]`, then the index advances. On the ground,
   an index of `$10` goes back to `$0c`, so walking settles at the 2 px
   steps of indices 12–15. `ApplyWalkVelocity` itself would cycle `$18`–`$1b`
   (4 px), and in the air `Func_1762` caps the index to 12–15 while rising
   and 4–7 (1 px) while falling. A slope caps it at index 7.
3. **Jumping** (`StartJump_FromInput`, `HandleInput_Airborne`). The index
   starts at 0 (a fall starts at `FALLING_JUMP_VEL_INDEX`, `$18`); a negative
   step moves up, any other moves down, and the index stops at
   `MAX_JUMP_VEL_INDEX` (`$27`). Releasing A before `$18` jumps the index to
   `$18` unless `wDoFullJump` is set. `HandleInput_Airborne` knows only three
   tables: any `wJumpVelTable` other than 1 or 2 uses the high-jump table.
4. **Landing.** `CheckAirborneCollision` probes the centre (`UNK1`) and both
   corners (`UNK6`). A landing below index `$27`, or with a direction held,
   goes straight to walking or idling (`DoSoftLand`); at `$27` with no
   direction it enters `WST_LANDING` until its frameset ends (`DoHardLand`).
   The owner's movie never lands hard.
5. **Collision.** Every check is a fixed point relative to Wario's
   position and collision box (`-27`, `-1`, `-9`, `9` while standing),
   probed through `GetBlockPtr` and `ProcessBlock` with one of eight probe
   kinds. Handlers decide per probe kind; `BlockFunc_Solid` returns 1 and
   snaps `hYPos` to the block top, and `update_pos_y` then copies `hYPos`
   into Wario's position, which is how he stands on floors. The front check
   also tests the block above an empty corner and, when it is solid,
   steps Wario 2 px into the gap and crouches.
6. **Frame timing in the oracle.** The game loop reads the joypad, runs the
   level, then waits for V-Blank. After a slow frame (an attack loads Wario's
   graphics), the next frame's `UpdateJoypad` ran before PyBoy's frame
   boundary, so a per-frame sample held the next frame's input. Wario
   traces therefore record each update exactly through execution hooks: on
   entry to `UpdateWarioStates` (`07:4000`) and to `UpdateObjects`
   (`18:5348`), which `UpdateLevel` calls next on all three of its paths.
7. **Parity.** The port (`game/scripts/sim/wario/`) runs one update from the
   oracle's variables before it and is compared on 39 variables with the
   variables after it (`make wario-parity`):
   - Owner's movie: 5676 Wario updates; **2022 compared, all identical**
     (idling 433, walking 796, turning 51, airborne 742). Updates in other
     states, or reaching an unported routine (attacking 21, crouching 2,
     doors 2, ladders 1, a room transition 1), are counted, not compared.
   - Walk capture (`walk-right-300`): the port alone, fed only the input,
     reproduces all 300 updates (`MODE=run`), including the x sequence and
     the stop at x = 88.
   - The first, frame-boundary version of the check had 13 differences: 11
     were object interactions later in the same frame (bounces, stings,
     transformations) and 2 were the joypad timing in item 6. With hooked
     updates, none remain.

8. **Level start** (`StartRoom_FromLevelStart`, `SetWarioPositionToSpawn`).
   The port's `start_level` clears what the original clears, takes the
   room's camera configuration, places Wario on the spawn point (56, 752 for
   level 0, from the object map), updates the floor in transition rooms,
   faces right, and calls `SetState_Idling`. Against the oracle's variables
   before its first Wario update (frame 184 of the owner's movie; no Wario
   update runs while the level fades in), all compared variables are
   identical (`make wario-parity` checks this).
9. **In the window** (WL3-033). `LevelRunner` builds the joypad byte as
   `UpdateJoypad` does (pressed = newly held), runs one update, and steps the
   frame counter after it, as `.GameLoop` does. From level 0's own start,
   the walk input reproduces all 300 oracle positions (`make smoke-level`,
   also run by the exported binary outside the checkout). The camera is
   ported too ([level camera](level-camera.md)).
10. **Attacking and bumping** (WL3-034, `SetState_Attacking`,
    `UpdateState_Attacking`, `UpdateState_AttackingAirborne`,
    `SetState_Bumping`, `UpdateState_Bumping`, `HandleBumpMovement`,
    `ApplyJumpVelocity`).
    - The charge runs `MAX_ATTACK_COUNTER` (`$30`) frames; while the
      counter is at `CHARGE_ATTACK_COUNTER` (`$2b`) or above it does not
      move, then it moves by `WalkVelTable` with the index cycling
      `$10`–`$13`. Holding the other way turns; A starts an airborne attack;
      a blocked front corner bumps Wario 2 px back.
    - A bump turns Wario away, uses `JUMP_VEL_KNOCK_BACK` as its table but
      moves along `JumpVelTable_Normal` from index 10 (or falls, if
      airborne), 1 px a frame back; from index 28 a held direction ends it
      in a fall.
    - `Frameset_15216` and `Frameset_15219` serve the airborne attack and
      the bump the opposite way round (15216 is the airborne attack facing
      left and the bump facing right); the first port had the bump's
      reversed, and the parity check showed it in 9 updates.
    - Breaking blocks is now reached for real: `BreakBlock`'s coin roll reads
      `rDIV`, so for those updates `wCoinCooldown` alone is left out of the
      comparison.
    - On the owner's movie: 337 attacking, 114 attacking-airborne, and 206
      bumping updates, all identical (2700 of 2700 compared updates in all;
      6 broke a block). Run alone over whole frames, the port now matches
      164 frames from the level start, through the first charges, and stops
      at frame 348, where an enemy knocks Wario back (object code, not
      ported).
11. **Crouching, sliding, and rolling** (`CrouchOrSlide`, the crouch
    states, `UpdateState_CrouchSliding`, `UpdateState_Sliding`,
    `UpdateState_Rolling`, `UpdateState_RollingAirborne`).
    - Crouching shrinks the box top to -15; standing up, jumping, and
      attacking from a crouch each first check the full height (-27) above.
      Crouch walking cycles the walk index 0–3.
    - The crouch slide (Down during a charge) moves 2 px a frame up to
      frame `$14`, 1 px to `$24`, then 1 px on odd `wGlobalCounter` frames,
      and ends at `$28` (`$1e`/`$36`/`$3c` with Garlic); on a slope it
      becomes a slide.
    - A slide moves down the slope with the walk index capped at 4–7 and
      becomes a roll when its animation ends; a roll cycles the index
      `$14`–`$17`, bumps when it meets a slope rising against it, and
      jumps or falls along `JumpVelTable_HighJump` regardless of
      `wJumpVelTable`.
    - The front check can call `CrouchOrSlide` and then return 0, so the
      walk that called it still takes its step that frame; the port keeps
      that order.
    - On the owner's movie: 40 crouch-sliding, 7 crouch-walking, 70
      sliding, 153 rolling, and 45 rolling-airborne updates, all identical
      on the first run (3018 of 3018 compared updates in all).
12. **Stung and ladders** (`UpdateState_Stung`, `UpdateState_StungRecovery`,
    the ladder states in `wario_states_2.asm`, `HandleLadderInput`,
    `Func_1b480`).
    - Stung: knocked 1 px a frame (2 while rising) along
      `JumpVelTable_Normal`; each landing counts `wJumpVelTable` up and
      bounces from index 10, then 14, then recovers; on the ground (table 0)
      it slides until the index reaches `$27`. A ceiling turns the rise into
      a fall within the same frame. After `$14` frames of recovery Wario
      turns back, gets `wInvincibleCounter` `$10`, and stands or crouches.
      The palette flicker (`Func_1f6c2`) is presentation.
    - Ladders: grabbing centres Wario on the ladder's column; Up and Down
      climb 1 px a frame (with floor transitions); B with a direction gets
      off if that side is clear; B with Down slides 2 px a frame; after
      `$200` idle frames Wario scratches.
    - On the owner's movie: 112 stung, 40 recovery, and 98 ladder-climbing
      updates, all identical on the first run (3269 of 3269 in all). The
      other ladder states are translated but not in the movie.

13. **Electric** (`UpdateState_ElectricStart`, `UpdateState_Electric`,
    `UpdateState_ElectricDizzy`, `RecoverFromTransformation`), entered from
    `ObjInteraction_Electric` ([objects](objects.md), item 12).
    - Struck (`$7f`) runs its frameset, then Wario is knocked back as when
      stung (the same motion, `knock_back_motion` in the port; crouched
      without headroom, along the ground) in `$80`, then turns round, dizzy
      (`$81`), until its animation ends. Recovery clears the
      transformation's values, gives `wInvincibleCounter` `$10` and the
      default palette, and stands or falls. Water ends it early, and a room
      transition still triggers.
    - Graphics: `WarioElectricGfx` (`09:6800`), `OAM_1790e`, and
      `WarioElectricPal`.
    - On the owner's movie: 5 + 73 + 53 updates, all identical (3438 of
      3438 compared updates in all, with `wTransformation` and the touch
      states now compared).

14. **Ball o' String** (`$70`-`$75`, `wario_states_3.asm`), entered from
    `ObjInteraction_Silky` (`Func_2126a`: a crouching Wario without
    headroom is only touched).
    - Getting wrapped runs its frameset; then Wario rolls by himself (the
      walk index cycling `$14`-`$17`, as rolling), turning at walls and
      slopes against him; the fifth turn (`wWarioStateCounter`) knocks the
      string loose: a hop back of 2 px a frame along the normal jump table
      from index `$0a` (`Func_2b1cc`, undone against a wall), then, landed
      and turned round, unwrapping, then dizzy and intangible
      (`WarioDizzyGfx`, `OAM_17bbc`) until `RecoverFromTransformation`.
      Without a floor the ball falls along the high jump's table.
    - Graphics: `WarioStringGfx` (`09:5800`), `OAM_171c0`,
      `WarioStringPal`.
    - On the owner's movie: all 679 updates identical, on the first run
      (4119 of 4119 compared updates in all).

15. **On Fire** (`$60`-`$64`), entered from `ObjInteraction_Fire`
    (`TRANSFORMATION_HOT_WARIO` for `HOT_WARIO_DURATION`, 600 frames, in
    `wTransformationDuration`, now traced).
    - On fire, Wario runs by himself (walk index `$10`-`$13`), A jumps
      (normal table; with no floor he falls along the high jump's), and a
      wall turns him 2 px back (3 in the air); still against one on the
      floor, he is hot at once (`SetState_Hot_ResetDuration`). With 300
      frames left he is hot: a pixel a frame where the joypad says,
      cooling by palette at 224, 164, and 60 frames left, touching objects
      makes them vanish, and at 1 he is burnt until the animation ends and
      he recovers. Off a floor, hot, he is centred on his block's column
      and falls, the joypad ignored for 8 frames. Water would put the fire
      out (`Func_2ade4`: a dive, not ported).
    - Landing on an object while transformed (`StepOnObject.Transformed`):
      hot, it vanishes; Fat Wario attacks it; otherwise it wobbles.
    - Graphics: `WarioHotGfx`, `WarioBurntGfx`, `OAM_1673c`, `OAM_16b6c`,
      and four palettes.
    - On the owner's movie: 300 + 58 + 299 + 88 updates (on fire, its
      airborne state, hot, burnt), all identical on the first run (4864 of
      4864 compared updates in all).

16. **The treasure scene** (`$40`-`$4a`, `wario_states_2.asm`), from
    `GetTreasure` ([objects](objects.md), item 17).
    - Wario lands if he was in the air, stands, walks 24 px, turns to the
      front and laughs, turns back and holds up the treasure, turns and
      walks 32 px (no longer moving by himself, so the chest opens), turns
      to the front, and looks out while the treasure's glow shows; after
      180 frames (A cuts them short) and the end of a glow loop, bit 7 of
      `wLevelEndScreen` clears and the level ends.
    - These states call `UpdateWarioAnimation` from "Wario OAM 2" (bank
      `$7f`): its framesets are extracted with their bank (`"7f:446a"`),
      and the port reads them through `update_wario_animation_2`.
      Graphics: `WarioClearGfx`, `OAM_1fc000`, `OAM_1fc31b`.
    - On the owner's movie: all 812 updates identical on the first run;
      with them every one of the movie's 5676 Wario updates matches.

17. **Water** (`$0a`-`$11`, `wario_states_1.asm`; WL3-034).
    - The water blocks (`BlockFunc_Water`, the four currents, the surface,
      non-submersible water) set `wWaterInteraction` for Wario's presence
      probe (UNK7) and `wIsInWaterOrSand` for objects; a current sets
      `wWaterCurrent`. Eight states that met water now dive
      (`DiveFromSurface`: a splash at the surface's top).
    - Diving sinks 2 px a frame for 10 frames, then 1 px for 4. Without the
      Swimming Flippers (a new game's), or in non-submersible water, Wario
      floats up a pixel every other frame to the surface, where he bobs (6
      px down and up every fourth frame), swims at the walk's speed (index
      0-3), jumps out with A, or only tries to submerge with Down. With
      the flippers he swims a pixel at a time with the pad (across on odd
      frames, up or down on even) and thrusts with B or A for up to 40
      frames along `SwimStraightVelTable`, `Data_1f894`, and
      `SwimDiagonalVelTable` (bank `$07`, extracted); a wall across knocks
      him back.
    - Currents push 2 px a frame unless Wario swims with them (or, with
      Prince Froggy's Gloves, against them); when the current changes, the
      last lingers 15 frames at 1 px (`wLastWaterCurrent`).
    - Water also puts Hot Wario's fire out (`Func_2ade4`).
    - `SetState_WaterStung` (from a water spike) leaves Wario intangible
      and invincible from 1, with the bump's frameset; touching an object
      while swimming (`Func_20899`) makes it wobble away and dives him.
    - On the coverage sweep's nine levels with water (scripted Right with
      jumps from each level's start; `make level-movie`): every water
      update identical on the first run, e.g. 152 diving, 362 submerged,
      10 surface idling, and 291 surface moving in The Tidal Coast; every
      compared Wario update of all nine levels matches (1105-1200 each).
18. **Enemy bumping** (`WST_ENEMY_BUMPING`, `$19`; `UpdateState_EnemyBumping`
    in `wario_states_1.asm`, WL3-041), entered from `SetState_EnemyBumping`
    (`object_interactions.asm`) at jump index `$0e` of the knock-back table.
    - It shares `HandleBumpMovement` with wall bumping: Wario moves a pixel
      a frame along `wDirection` (set away from the object) and along the
      normal jump's steps; Left or Right from index 28 ends it in a fall.
    - Rising, a ceiling sends him to the falling index; on landing he turns
      round (`wDirection` xor 1) to face the object and soft-lands. Room
      transitions, water (`DiveFromSurface`), and the floor transition are
      checked as in the other airborne states; sand is noted as unported.
    - On the coverage sweep's six levels with bumps (00, 08, 10, 20, 38,
      b0; `make level-movie` from each start): every bumping update
      identical on the first run (15, 15, 14, 29, 15, and 14), and three of
      them compare all 1200 updates.
19. **Sand** (`$35`-`$39`, `wario_states_2.asm`; WL3-045). `BlockFunc_Sand`
    is free, sets `wIsInWaterOrSand` for objects, and `wIsInSand` for
    Wario's presence probe (UNK7). The airborne states (and the others
    that check it) then call `SetState_SandFalling`.
    - Falling, Wario sinks 1 px a frame (2 with Down) until the centre
      probe (`CheckCentreCollision`) finds ground under him, and moves with
      the pad at the walk's speed (index kept below 4); A starts a jump.
    - Jumping in sand rises along the knock-back table while A is held and
      nothing is above; leaving the sand is a jump (`StartJump_FromSand`:
      the knock-back table, the normal one with High Jump Boots and Up).
    - Idling and walking follow the pad; walking sinks again where the
      centre probe finds nothing. Sand turning is ported but unreachable,
      as the disassembly notes: the idle state's input has already turned
      him.
    - On the sweep's level 30 (scripted Right with jumps): all 1058 sand
      updates match on the first run (412 falling, 292 jumping, 12 idling,
      342 walking), and the level's 1200 Wario updates all match.
20. **Fat Wario** (`$76`-`$7e`, `wario_states_3.asm`; WL3-045), from
    `ObjInteraction_Food` (`$1a`): unless crouching or already
    transformed (then only `OBJACTION_0D`), the food is eaten
    (`OBJACTION_07`) and Wario is fat for 420 frames, eating first.
    - Fat, his touches attack (`TOUCH_ATTACK`); an attack bumps him
      (`SetState_FatBumping`). He walks with `WalkIfPossible` (the index
      kept between 4 and 7), jumps along the knock-back table, and falls
      smashing; the time runs while walking and on landing (kept from
      running out in the air), and at its end he recovers (`TOUCH_BUMP`)
      and returns to normal (`RecoverFromTransformation`).
    - Landing from the air shakes the ground for `$20` frames; the landing
      lasts while it shakes. In water he sinks a pixel a frame with bubbles
      every 16 frames and comes back to normal on the bottom, submerged
      (`Func_2ad6a`).
    - Graphics: `WarioFatGfx` (`$09:6000`) and `OAM_1742d`, extracted with
      18 framesets.
    - On the sweep's level 08 (the Doughnuteer's food): all 585 fat updates
      match on the first run (167 walking, 136 airborne, 127 eating, 100
      landing, 41 recovering, 10 bumping, 4 idling), and with the ground
      shake (item 21) all 1200 of the level's Wario updates (597 before).
21. **The ground shake** (`HandleGroundShake`, `wario_states_1.asm`). While
    `wGroundShakeCounter` runs, the screen shakes 2 px while its bit 1 is
    set (`wSCYShake`). With `$10` or more left, a Wario on the ground (not
    shaking it himself, transformed, in water, intangible, on an object,
    or getting off a ladder) is stunned instead that frame: on a ladder he
    slides off (`SetState_LadderShakeStunned`), elsewhere he is knocked up
    from index 10 of the knock-back table (`WST_GROUND_SHAKE_STUNNED`,
    `$2b`), moving the way he faces, and stands, crouches, or falls when
    the shaking stops. The port had cleared `wIsWarioGroundShaking` even
    with `wLevelEndScreen` set, where the original returns first; fixed.
    Level a8's 24 stunned updates and level 08's shakes match.
22. **Picked up** (`$2a`; `UpdateState_PickedUp`, `wario_states_1.asm`),
    from `ObjInteraction_Omodonmeka` (`$18`): on the ground and not
    transformed, Wario is held (`wAutoMoveState` 1, the object moves him;
    in the air he only touches it, and Flat Wario's stretching is not
    ported). Pressing A, B, or the way he faces away turns him; six such
    wiggles, each within 32 frames of the last
    (`wPickedUpFrameCounter`), free him in a fall; 32 frames without one
    start the count again (`wPickedUpWiggleCounter`, both now traced). On
    the sweep's level a8, all 513 picked-up updates match, and the level
    compares all 1119 of its Wario updates (606 before).
23. **Ice Skatin'** (`$b0`-`$b3`, `wario_states_4.asm`), from
    `ObjInteraction_Ice` (`$27`, Brrr Bear's snowflakes): unless
    invincible, already in a lasting transformation, or crouching under a
    ceiling, Wario is frozen (`TRANSFORMATION_ICE_SKATIN`, touches attack)
    facing the way the object faced (`wObjDirection`).
    - He skates the way he faces whatever the pad, faster along the walk's
      table (its index kept between `$10` and `$13` once past `$14`), falls
      off edges skating, and lands skating from index `$10`.
    - A wall ahead (or water while airborne) crashes him: back 3 px,
      turned round; when the crash's animation ends, the ice breaks
      (`PARTICLE_ICE`) and he recovers.
    - Graphics: `WarioBubbleGfx` (`$0b:6800`), `OAM_1fdb6d` and six
      framesets in "Wario OAM 2" (`$7f`), `WarioIceSkatinPal`.
    - On the sweep's level b0: all 281 Ice Skatin' updates match (96
      starting, 38 skating, 147 crashing) and the 11 interaction runs with
      an effect; the level compares all 1200 Wario updates (919 before).
24. **Hanging from a rail** (`$c0`; `UpdateState_HangingRail`), from
    `ObjInteraction_Rail` (`$29`): Wario hangs from a zip line
    (`TRANSFORMATION_RAIL`; touches bump, stings hurt), carried by it
    (`wAutoMoveState`). B lets go without invincibility
    (`RecoverFromTransformation_WithoutInvincibility`), A jumps off, and
    when the line stops he drops rolling. Graphics: `WarioHangGfx`
    (`$0b:7800`), `OAM_1fee05`, two framesets in "Wario OAM 2". Level 90's
    28 hanging updates match, which leaves no Wario update of the sweep
    uncompared: 29,826 of 29,826, all identical.
25. **Flat Wario** (`$65`-`$6f`, `wario_states_3.asm`; WL3-044), from
    `ObjInteraction_Omodon` (a falling Omodon, item 37 of
    [objects](objects.md)). `SetState_FlatAirborne` centres him 8 px left
    of the object's `OBJ_X_POS` (Count Richtertoffen's without the 8, and
    then not squished), takes `TRANSFORMATION_FLAT_WARIO` (touches bump),
    and drops him 2 px a frame; on the ground he gets flat (intangible)
    and lies squished under the object until `Func_2168b`, the object
    lifted off him, raises him 50 px (`$6f`) and lets him fall. Flat, A
    jumps (the knock-back jump, or the normal one with Up) and the pad
    walks, the walk index kept below 4. `Func_2b10a` and `Func_2b11b` are
    *called*, so after a state they start their caller still checks the
    ground. Falling, he floats down like a sheet: by `wWalkVelIndex`,
    `Data_2b664` (down) and `Data_2b68c` (across), both extracted
    (`flat_fall_tables`, movement extractor version 15), swinging 40
    steps and turning at the end unless the pad holds his way; a wall
    turns him back 3 px. In water he sinks a pixel every other frame with
    bubbles and stretches back to normal on the bottom (`Func_2ad6a`).
    `SetState_FlatStretching` (Omodonmeka catching him flat) and
    `Func_2028a` (bumped in the air: a fall facing away) are ported too.
    Eleven framesets in "Wario OAM 1" and `OAM_16e9d`. Level a8's
    `right-attack` movie reaches getting flat, idling, walking, jumping,
    falling, squished, and lifting: all its 1200 Wario updates match on
    the first run, and whole frames run to the end. Stretching and the
    underwater states are translated and covered by unit tests only;
    `ReleaseOwl` (flattened as Owl Wario) is named as unported.
26. **Zombie Wario** (`$87`-`$8f`, `wario_states_3.asm`; WL3-044), from
    `ObjInteraction_ZombieHead` (`$1f`; invincible or in another lasting
    transformation, the head only reacts). His touches make objects
    vanish (`TOUCH_VANISH`), and touching an object that way knocks him
    back (`SetState_ZombieKnockBack`, not while landing or slipping). He
    walks slowly (the walk index kept below 4), turns, and jumps with A
    held on the knock-back jump table, steered after `wWarioStateCycles`
    frames (`Func_2b3dd`); idle for 512 frames (`wWarioStateCounter` and
    `wWarioStateCycles` as one 16-bit count) he writhes until a button
    is held. Landing touches bump; `Func_19a77` sets `wc1ca` when both
    bottom corners stand on one-way floors (or are both free), and then
    he slips through them (`BlockFunc_Floor` is free in the landing and
    slipping states). Water ends the transformation; a light source
    (`BlockFunc_LightSource`, through a hook) starts the recovery, which
    steps every fourth frame through the zombie palette and the seven
    after it (labelled unused in the disassembly, reached by offset): up
    to the seventh, back three, then `RecoverFromTransformation`. The
    framesets are in "Wario OAM 2" (22, extracted with movement
    extractor 16); `WarioZombieGfx`, `OAM_1fc48b`, and the eight palettes
    with sprites extractor 11. Level a0's `wander` movie reaches idling,
    walking, turning, the air, and the recovery: all 1200 Wario updates
    match on the first run, whole frames run to the end, and
    `make sprite-check` matches all 487,482 of Wario's pixels there.
    Landing, slipping, the knock-back, and writhing are covered by unit
    tests only.
27. **Blind Wario** (`$dc`-`$df`, `wario_states_4.asm`; WL3-044), from
    `ObjInteraction_Teruteru` (`$38`, only from below; touches bump,
    stings find him vulnerable). His own graphics, palette, and framesets;
    the dark screen (BG palettes 0-3 and OBJ palettes 3-4 zeroed by the
    interaction, restored by `ClearTransformationValues`) is presentation
    and not drawn natively yet. He walks (the walk index kept below `$10`,
    back to `$0c`), turns (A jumps from the turn at once), jumps, and
    falls on the high jump's table; walking or jumping into a wall, or
    water, gives him his sight back (`RecoverFromTransformation`), and he
    cannot pause (`check_end_screen` already allowed for it). The port's
    `ClearTransformationValues` now also clears `wSwimmingDirectionInput`
    as the original does. Level 10's `wander` movie matches all 1200
    Wario updates on the first run, runs whole frames to the end, and
    `make sprite-check` there matches all 473,525 of Wario's pixels.
28. **Bouncy Wario** (`$90`-`$96`, `wario_states_3.asm`; WL3-044), from
    `ObjInteraction_Bouncy` (`$20`, met head on; `Func_2160a`) for 900
    frames. A taller box (top -29), his own graphics and palette; he
    falls carried on the way he faces (`HandleWalk`), then bounces: the
    floor's squash, then the bouncy jump, or the high one with A held
    (`Func_2a0b2`, which `StepOnObject` also calls, so landing on an
    object bounces him too), its first animation leaving a particle after
    a high one. The pad steers in the air (the walk index kept below 8,
    back to 4); a ceiling squashes him. Under 360 frames left the palette
    alternates with the red one every 16th frame, under 120 every 4th
    (`Func_2ae5c`, `Func_2ae3b`). Time up on the floor, or in the air via
    falling upside down and landing so, he makes a last normal bounce,
    touches passing through, and lands as Wario; water ends it at once.
    Seven framesets in "Wario OAM 2" (movement extractor 17);
    `WarioBouncyGfx`, `OAM_1fc95e`, and the two palettes (sprites
    extractor 12). Level 20's `wander` movie matches all 1200 Wario
    updates on the first run, runs whole frames to the end, and
    `make sprite-check` matches all 590,472 of Wario's pixels there.
29. **Slipping** (`$30`, `$31`, `wario_states_2.asm`; WL3-044). On
    slippery ground (`IsOnSlipperyGround`, item 6 of [block
    handlers](block-handlers.md)) letting go of the pad while walking, or
    an attack's end, slips instead of idling; Down while walking crouch-
    slips. Sliding the way he faced, 2 px a frame for 7 frames, 1 px for
    7, then 1 px every other frame until the count's 21st (crouching: 5,
    4, and 4 frames); a wall or the end of the slippery ground stops it
    sooner. `wWarioStateCycles` keeps the slide's direction; the pad
    against it turns him (the turn, then walking frames, still sliding),
    and he stops facing that way. A jumps (crouch-jumps), Down from a slip
    crouch-slips on with the same count, nothing under him is a fall.
    Level 98's `wander` movie matches all 1200 Wario updates on the first
    run and runs whole frames to the end.
30. **The smash attack** (`UpdateState_Airborne`, `$1a`; WL3-046). With
    the Lead Overalls or better, Down while falling starts it
    (`wIsSmashAttacking` 1; its frames, or the Super Jump Slam Overalls'
    own); letting go of Down ends it, and turning in the air keeps its
    frames. Landing (soft or hard alike) pounds the ground
    (`DoGroundPound`), or with the Super Jump Slam Overalls shakes it for
    32 frames as Wario's own shake (`DoWarioGroundShake`, unless it
    already shakes); both set the airborne graphics and only the OAM
    pointer, then `SetState_SmashAttacking` (`wIsSmashAttacking` `$81`)
    holds 27 frames before idling. Six framesets (movement extractor 18).
    Level 08's `wander` movie with every power-up (`POWER_UP=9`) matches
    all 1200 Wario updates on the first run and runs whole frames to the
    end.
31. **Grabbing and throwing** (`$1e`-`$26`, `$3f`; WL3-046). With the
    Grab Glove, `Func_20b6b` picks up an object Wario walks into facing
    it (a heavy one needs the Super Grab Gloves, else he steps on it):
    `wGrabState` takes `GRAB_PICK_UP` (and `GRAB_HEAVY`), the object
    `OBJACTION_PICK_UP`; in the air he falls holding it, on the ground he
    lifts it (at once facing up a slope). Holding it he stands, walks
    the way he faces (the other way stands him still; slower climbing a
    slope or with a heavy object), jumps (the high jump with the High
    Jump Boots and Up), falls, smash-attacks and pounds or shakes the
    ground as without it, and slips; Down crouches (dropping it is the
    object's side). B held charges a throw: 30 frames (60 heavy) to
    full charge, held there; B let go throws it (`GRAB_THROW`, with
    `GRAB_FULL_CHARGE` once charged), A drops it and jumps. In the air B
    throws at once, Wario hanging until the throw's frames end. The
    port's `GRAB_IDLE` was 1; it is 3 (`GRAB_NONE`, `GRAB_PICK_UP`,
    `GRAB_UNK_02`, `GRAB_IDLE`, ...), which the earlier code's two checks
    now use. 30 framesets (movement extractor 19); `WarioThrowGfx` and
    `OAM_1606a` (sprites extractor 13). The power-up `wander` sweep then
    compares all 29,804 of its Wario updates, every one identical on the
    first run; what the objects do when picked up, carried, and thrown
    (`Func_61f54`, `Func_620a6`, `HandleGrabbedObjectCollisions`, the
    thrown states) is item 40 of [objects](objects.md).
32. **Crazy Wario** (`$97`-`$9b`, `wario_states_3.asm`; WL3-046), from
    `ObjInteraction_OrangeBird` (`$24`, met head on; touches attack). He
    spins the way the bird faced for 128 frames (falling to the ground
    first if in the air), is dizzy for an animation, then staggers on by
    himself (`Func_2b42b` by `wWalkVelIndex`: 2 px for 5 frames, a dust
    puff, a pause, 2 px again, dust, then slowing to a pixel every other
    frame), turning at a wall at his bottom corner or at the animation's
    end unless the pad holds his way; A jumps (the normal table, carried
    on the way he faces); water ends it. Touches bump while crazy and
    stings find him vulnerable. `WarioCrazyGfx`, `OAM_1fccd5`, six
    framesets (movement extractor 20, sprites extractor 14). Level 60's
    power-up `right-attack` movie matches all 1169 Wario updates on the
    first run and runs whole frames to the end.
33. **Pipes** (`$17`, `$18`; WL3-047). `BlockFunc_DownPipe_Left` and
    `_Right` are solid; Wario idling on one (or idling holding something)
    with Down held is centred on the pipe (from its left half's block
    `x & $f0 + $18`, carrying into the high byte; from its right half's
    `x & $f0 + $08`) and goes down it (`EnterPipeDown`: the pipe
    transition, `ROOMTRANSITION_PIPE` with the reload and delay flags,
    the state's counters, grab, attack, jump, crouch, and smash attack
    cleared, `WarioIdleGfx`, `OAM_14a82`, `Frameset_14cf6`). The up-pipes
    take an airborne Wario (or airborne holding something) under them
    with Up held (`COLLISION_UNK5`) the same way. `UpdateState_PipeGoing*`
    keep him intangible, moving a pixel a frame; at 32 frames the
    transformations are cleared and the transition goes ahead
    (`TriggerRoomTransition`, which also clears the water currents and
    `wIsBossBattle`, now as the port does too); he comes out in the new
    room until 64, then steps 8 px back left and idles (coming up, on the
    floor he is now on). The later variants' sweeps met it; with it
    every one of their Wario updates is compared and matches.
34. **Puffy Wario** (`$83`-`$86`, `wario_states_3.asm`; WL3-047), from
    `ObjInteraction_YellowBellyArrow` (`$37`) and `ObjInteraction_Pneumo`
    (`$1e`) from below, unless invincible, puffy, or in a lasting
    transformation (Owl Wario would let go of the owl first: `ReleaseOwl`,
    not ported). Vulnerable to stings, bumped by touches, the tall box.
    He inflates, then rises half a pixel a frame (on even frames), the
    pad moving him a pixel sideways unless a wall is at his bottom corner
    (probed with the break flag) or turning him; a ceiling deflates him
    (intangible, two animations) into `RecoverFromTransformation`. His
    animations run in the OAM table's own bank (`$77`,
    `UpdateWarioAnimation` called in `wWarioOAMBank`):
    `update_wario_animation_oam_bank`. `WarioPuffyGfx`, `OAM_1dc93f`, ten
    framesets (movement extractor 22, sprites extractor 15). The day-1
    room starts compare every Puffy update, all identical.
35. **Split by a beam** (`$d0`-`$d3`, `wario_states_4.asm`; WL3-047),
    from `ObjInteraction_Beam` (`$35`) unless invincible or in a lasting
    transformation (`TRANSFORMATION_SPLIT`, touches and stings pass
    through). Facing the way the beam came, he is knocked up (table 1
    from index `$0e`) and carried the way he faces (`HandleWalk`,
    `Func_1762`) until he lands, splits for an animation (falling if
    nothing is under him), and at its end comes back together facing the
    other way (`RecoverFromTransformation`). `WarioSnowballGfx`,
    `OAM_1ffa12`, `WarioSplitPal`, six framesets in "Wario OAM 2"
    (movement extractor 23, sprites extractor 16). The day-1 room starts
    compare every update, all identical.
36. **Vampire Wario and the bat** (`$9c`-`$a4`, `wario_states_3.asm`;
    WL3-047), from `ObjInteraction_Vampire` (`$25`, Kobatto) unless
    invincible or in a lasting transformation, and unless the presence
    probe above him (`Func_19b25`, run with the transformation already
    set) ends it at once (a light). Touches and stings make objects
    vanish. He walks, turns, and jumps on the knock-back table; B (held
    while walking) turns him into a bat (box top -15), which flaps up
    along the swim's straight table while A is held (`Func_2b63b`),
    falls on the high jump's table, and turns back into the vampire with
    B where his box fits. Water ends it; a light source
    (`BlockFunc_LightSource`) and `BlockFunc_18868` were already ported.
    `WarioVampireGfx`, `WarioBatGfx`, `OAM_1fd498`, `OAM_1fd031`,
    `WarioVampirePal`, twelve framesets in "Wario OAM 2".
37. **In a bubble** (`$a5`; WL3-047), from `ObjInteraction_Bubble`
    (`$26`): touches and stings bump; the bubble rises a pixel on odd
    frames (a ceiling bursts it) and on even frames drifts the way it
    came along `Data_2b6b4` (47 steps, extracted), turning back at a
    wall or the table's end, or the pad pushes it a pixel. Out of the
    water it bursts (`PARTICLE_BUBBLE_BURST`) into
    `RecoverFromTransformation`.
38. **Owl Wario** (`$b8`-`$bc`; WL3-047), from `ObjInteraction_Owl`
    (`$28`) from below: hanging from the owl he flies a pixel a frame the
    way he goes, turning back at walls, floors, and ceilings, or 2 px a
    frame the way the pad holds; B or water lets go (`ReleaseOwl`: the
    owl flies off as `PARTICLE_OWL` $18 px above him), and he falls on
    table 2 into `RecoverFromTransformation`. `ReleaseOwl` also runs
    where a sting (`Func_206eb`), a Yellow Belly arrow, or flattening
    ends Owl Wario. `OAM_1fddb4`, eight framesets.
    With items 36-38 every sweep (3,258 movies) compares 3,822,793 of
    3,833,825 Wario updates, all identical (movement extractor 26,
    sprites extractor 19).
39. **Snowman Wario and the snowball** (`$c4`-`$cd`; WL3-047), from
    `ObjInteraction_Snow` (`$2d`; invincible or in a lasting
    transformation the object only reacts, `OBJACTION_0D`): touches and
    stings attack. He walks (the walk index below 8), turns, jumps on
    table 1 and smashes from the top of the arc, and landing shakes the
    ground ($20 frames, the landing lasting while it shakes); attacking
    an object bumps him. On a slope he rolls down it as a snowball
    (`TurnIntoSmallSnowball`, the way being the slope's low nibble less
    1), which grows with the pixels rolled (medium from $70, big from
    $e0), falls on the high jump's table, and crashes at a wall (2 px
    back, `PARTICLE_SNOW`) into `RecoverFromTransformation`. Water ends
    it. `WarioSnowmanGfx`, `WarioSnowballGfx`, `OAM_1feec7`,
    `OAM_1ff64a`, `WarioSnowmanPal`, 21 framesets (movement extractor
    27, sprites extractor 20). Every sweep then compares 3,826,733 of
    3,833,825 Wario updates, all identical.
40. **Fan Wario** (`$d4`-`$d8`; WL3-047), from `BlockFunc_AirCurrent`:
    Wario's presence in an air current (not invincible) sets
    `wIsInAirCurrent`, and untransformed he becomes Fan Wario (bumped by
    touches, vulnerable to stings). He lifts a pixel a frame while the
    current is 12 px above him (`Func_19acd`), spins at its top, and the
    pad moves him a pixel sideways or turns him; out of the current he
    recovers (`RecoverFromTransformation_WithoutInvincibility`). His
    animations are in "Wario OAM 3" (bank `$77`). `WarioFanGfx`,
    `OAM_1dc000`, nine framesets (movement extractor 28, sprites
    extractor 21). Every sweep then compares 3,829,627 of 3,833,825 Wario
    updates, all identical.
41. **Turning invisible, teleports, and Magic Wario** (WL3-047).
    `ObjInteraction_InvisibilityPotion` (`$1d`): the potion is taken
    (`Func_20a63`) and, unless invincible, invisible, or in a lasting
    transformation, Wario turns invisible (`$82`: intangible, touches and
    stings neutral, the dizzy graphics) into Invisible Wario idling.
    `ObjInteraction_Jamano` (`$44`) stings him out of any transformation
    (`Func_206eb`) and sets a delayed teleport (`$33`):
    `ObjInteraction_WaterTeleporting` (`$40`), and `ObjInteraction_Scowler`
    (`$41`) from below, the same in water (`$34`, after
    `SetState_WaterStung`); after $b4 intangible frames he is stung (in
    water, water stung), invincible, and the teleport goes ahead.
    `ObjInteraction_MagicalSpiral` (`$4b`): Magic Wario (`$e4`-`$e6`; the
    spiral's two particles, touches and stings pass through) rises a
    pixel a frame until a ceiling (`PARTICLE_MAGIC_STOP`), waits $20
    frames, and recovers. `OAM_17cf7`, `WarioMagicGfx`, `OAM_1dcd60`,
    `WarioMagicPal`, three framesets (movement extractor 30, sprites
    extractor 23). Every sweep then compares 3,831,341 of 3,833,825 Wario
    updates, all identical.
42. **Wario as a ball** (`$e8`-`$ee`; WL3-047), the Shoot minigame:
    `ObjInteraction_Shoot` (`$4d`) from below makes him a ball (touches
    and stings pass through) that bounces on the knock-back table the way
    it faces, turning with the pad. The shooter or the goalkeeper
    (`$4d`, `$4e`) shoots it (`SetState_BallShot`: intangible, its
    phases driven by `wAutoMoveState`, which the minigame's objects set);
    thrown left on the high jump's table, it lands stung out of the ball
    (`Func_206eb`), or, with three goals (`wShootGoals`), is sent up to a
    ceiling and then lands the same way. `wShootGoals` lives in WRAM bank
    1 (`$d144`), so traced variables may now name a bank (`BB:AAAA`;
    the oracle reads them in that bank). `WarioBallGfx`, `OAM_1dcff1`,
    `WarioBallPal`, `WarioBallShotPal`, 13 framesets (movement extractor
    31, sprites extractor 24). Every sweep then compares 3,833,346 of
    3,833,825 Wario updates, all identical.
43. **Launched** (`$e1`, `$e2`; WL3-049), by the Big Octohon
    (`OBJ_INTERACTION_49`, `Func_21dac`) when Wario touches the side it
    faces while it charges: unless he is invincible (in a lasting
    transformation only touched), `SetState_Launched` makes him a lasting
    transformation (`TRANSFORMATION_LAUNCHED`, `$54`) that vanishes
    touches and stings. He gets a box -15 to -1 by -9..9, the default
    palette, and `WarioLaunchGfx` with `OAM_1dc449`. He flies 2 px a frame
    the way the octohon faced until a wall in front (`CheckFrontCollision`)
    crashes him (`$e2`), and the crash's end puts him back to normal
    under water (`Func_2ad6a`). Four framesets (movement extractor 32,
    sprites extractor 25). The 14 later-variant room starts that meet it
    compare all their Wario updates, all identical, and `make
    sprite-check` on level 52's room 3 matches all 712,320 of Wario's
    pixels.
44. **Dragged down, and a ladder slide's smash landing** (WL3-048, the
    owner's movies). `ObjInteraction_Hand` (`$3f`), unless Wario is
    invincible or transformed: `SetState_DraggedDown` (`$32`). Wario
    becomes the hand's to move (`wAutoMoveState` 1), with the airborne
    graphics and a box -27 to -1. The hand object (already ported) lets
    go by clearing `wAutoMoveState`, and he falls (`StartFall`); in The
    Temple (`$c8`) it is game over instead (`wLevelEndScreen`
    `LVLEND_GAME_OVER`). Sliding down a ladder with the Lead Overalls
    (`wIsSmashAttacking`) lands with `DoGroundPound`, or with the Super
    Jump Slam Overalls `DoWarioGroundShake`; both were ported, only this
    caller was not. `game-005` and `game-009` match in every Wario
    update.

## Interpretation

- The core movement is deterministic integer code over a handful of
  tables; translated routine by routine, it matches the original exactly
  wherever it has been exercised.
- Materials (`empty`, `solid`, `platform`) cannot express the per-probe
  rules (slopes move `hYPos`, floors catch only near their top, breakables
  depend on attack state), so the port implements block handlers by ID.

## Hypotheses

- Handlers that matched updates ran, by probe kind: free, solid, floor
  (all eight), left slope (ground, 13 updates), the block above a left
  slope, ladder and ladder top (presence), door and transition 4 (not
  entered), and cracked and non-cracked blocks (as solid). Right slopes,
  breaking, colour-coin and bonfire blocks, entering a door, and starting
  a transition are translated but unexercised; their behaviour is a
  hypothesis until a trace covers them.

## Unknowns

- Behaviour of every state not yet ported. Wario's updates in the movie
  use 40 states; 4 of them are ported (the fifth ported state, landing,
  does not occur). Attacking, bumping, rolling, and transformations are
  the most frequent of the rest.
- `BreakBlock` rolls a coin with `rDIV`; a native random source is not
  designed yet, so updates that break a block are not compared.
- Hard landing (`WST_LANDING`) has no oracle example yet.

## Tests

- `tests/test_wario_movement.py`: the table and frameset decoder on a
  synthetic ROM (signs, terminators, bank bounds, layout constants).
- `game/tests/unit/test_wario_sim.gd`: the port on invented tables and a
  synthetic level (walk indices and cap, wall stop, turning time, jumps,
  release, ceiling, soft and hard landing, one-way floor, invincibility,
  unported routines named).
- `tests/test_oracle.py`: Wario trace recording with a fake machine, the
  schema, and variable addresses against the reference symbols.
- `tests/test_rom_integration.py`: tables and level collision on the real
  ROM and labels, and the native run over the walk capture.

## Next experiment

Port `SetState_Attacking` and `UpdateState_Attacking` (339 updates in the
movie), then bumping and rolling, checking each with `make wario-parity`.
