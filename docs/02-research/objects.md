---
type: research
status: active
updated: 2026-10-28
tags: [research, movement, validation]
---
# Objects

**Question:** how do the level's objects (enemies, coins, keys, chests) live
from frame to frame, and can the port run them as the original does?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/update_objects.asm`,
`load_objects.asm`, `spawn_edge.asm`, `block_queue.asm` `DespawnObject`,
`src/home/object_mechanics.asm`, `src/engine/level/objects/*.asm`,
`src/constants/object_constants.asm`, `src/ram/wram.asm`); oracle traces of
the owner's movie. Task: WL3-035.

## Verified observations

1. **Slots.** Eight 32-byte object structs at `wObjects` (WRAM bank 1,
   `$d000`), then `wCurObj`, then `wObjDataPointers` (the level's object types:
   chest, key, musical coin, and up to 13 more). Positions are little-endian;
   `OBJ_UNK_01`/`OBJ_UNK_02` remember the object's map cell (column, and
   `$a0` + row as an SRAM page).
2. **Update.** `UpdateObjects` sets `wEffectivePowerUp`, then for each active
   slot in order: copies it to `wCurObj`, runs `DoObjectAction` (an action an
   interaction left becomes a state, or counts down), calls the object's
   function (bank `$10` + ID's high nibble, pointer `OBJ_UPDATE_FUNCTION`),
   advances its animation, checks the on-screen window (and despawns it far
   outside, giving its map byte bit 7 back), sets its screen position, and
   copies all but `OBJ_UNK_01`, `OBJ_UNK_02`, and `OBJ_UNK_1D` back. During a
   floor transition only uninitialised objects run their function, and the
   frame is refreshed without advancing.
3. **Animation data.** The "Object Framesets" bank (`$1a`) holds 938
   framesets back to back; decoded in order (`make extract`,
   `tools/wl3pc/extract/objects.py`) they land exactly on the reference
   build's labels.
4. **What the movie meets.** Out of the Woods uses object group `$14`. The
   first room holds a Spearhead (ID `$00`, `SpearheadFunc`) and a musical
   coin (`$33`); later rooms add Webber (`$02`) and its projectile, Silky
   (`$0c`), torches and embers, leaves, a bird, the key, the chest, and coins
   (`$81`). The Spearhead goes through about 30 of its states, mostly
   walking (`$31`) and turning (`$43`).
5. **Parity** (`make wario-parity`, objects part): the trace now records the
   slots and Wario's variables at four points per frame (entering
   `UpdateObjects`, `SetWarioScreenPos`, `ProcessInteractions`, and
   `DrawObjects_NoPriority`). Every `UpdateObjects` of the movie is rerun
   natively from its start, and every slot whose update is fully ported is
   compared byte for byte: 3827 of 3827 match. That covers the framework for
   every object type during floor transitions, all 480 musical-coin updates,
   3142 Spearhead updates (spawn, init, and about 30 states: walking,
   turning, landing, falling, bumped, stunned, knocked away, tumbling,
   hopping back up), and 97 of the stars a vanished object becomes. Slots
   that reach an unported object function (and slots such code may have
   written) are counted, not judged. `HandleGrabbedObjectCollisions`, run
   before the slots while any active object is grabbed, can change any
   slot, so a frame it runs in leaves every slot unjudged while it is
   unported: before this, its note was attributed to no slot, and the
   first power-up sweep judged two Spearheads it had sent flying (level
   00, frame 353) as mismatched.
6. **Shared states and probes.** Objects probe the level through
   `ProcessBlock` with `wBlockFuncWarioFlag` clear and their own collision
   points (`Func_3543` DOWN, `Func_352b` UNK1, `Func_35a3` UNK2,
   `Func_358b` UNK3, `Func_3513` UNK4); the slope handlers then set
   `wObjSlopeInteraction`. The shared states step through velocity tables in
   bank `$18` (`src/data/object_movements.asm`, `$4000`–`$51ca`, extracted
   whole) within each table's 256-byte page, with heavy objects using a
   second table.

7. **Interactions** (`ProcessInteractions`): nothing while Wario is
   intangible, in a floor transition, or moving on his own. Otherwise the
   first active, on-screen object with no pending action whose box meets
   Wario's (in screen coordinates offset by `$d0`) is handled by its
   interaction type, and that ends the pass unless the handler continues it.
   The side with the shallowest overlap (`wInteractionSide`) decides bump,
   step, or sting: `UP` is Wario's feet in the object's top. Ported: types
   `$00`–`$05` (bumping, attacking, stepping on, the stings) and the musical
   coin (`$0d`: counted, 10 coins in BCD), with `SetState_Stung`,
   `SetState_EnemyBumping`, `AttackObject`, `StepOnObject`, and the bounce
   (`Func_20939`). Over the movie, all 5763 `ProcessInteractions` runs that
   reach no unported type match the original (Wario's 41 compared variables,
   the coin counts, and every slot), 21 of them with an effect. The
   unported types it meets are named: Futamogu's walkable top (`$0c`, 23),
   fire (`$0e`), the key and the chest, Silky, coins, a projectile (`$1c`),
   and a colour coin.

8. **Spawning.** A map cell with bit 7 and an object nibble spawns that
   object (`SpawnObject`): the first free slot takes its data entry from
   `wObjDataPointers` (nibble 1 the chest, 2 the key, 3 the musical coin,
   4 on the room's object group; extracted for all 146 groups, equal to the
   trace's pointers in every room the movie visits) at the cell's bottom
   centre. Only some fields are written; the rest keep the previous
   occupant's bytes. Spawning happens when a room starts (`Func_896f`: a
   16 x 16 window from `wBlockPos`, inside the room's limits `wc0c4`–`wc0c7`)
   and when the camera opens an edge (`SpawnRowEdgeObjects`: 12 rows;
   `SpawnColEdgeObjects`: 13 columns). Rooms start by despawning (non-transient
   objects give their cell bit 7 back), clearing the slots, reloading the
   map's bit 7 when the transition asks (`ReloadLevelObjects`), spawning,
   and updating the objects twice. Over the movie: the level start's and all
   five transitions' spawns (17 objects) equal the original's slots, and
   after every one of 5796 frames the native edge streaming leaves the same
   slots (30 frames spawned something); two coins a broken block made in the
   next frame are told apart (transient). The trace now records the object
   map too (`object_rows`, `object_changes`): a collected musical coin's
   nibble is cleared, so it does not spawn again.

9. **Whole frames.** The native frame now runs UpdateLevel's order (Wario,
   `UpdateObjects`, `SetWarioScreenPos`, `ProcessInteractions`, `DrawWario`,
   the camera, the edges). `make wario-parity MODE=run` plays the owner's
   movie alone from the level start: 675 whole frames match at every
   checkpoint (Wario after his update, the slots entering and leaving
   `UpdateObjects`, Wario and the slots after the interactions, the camera)
   through the first room, its Spearhead and musical coin, and the
   transition, and stop at room 21's first unported object. The walk runs
   all 300 frames this way, and the window plays with the objects.

10. **Drawing.** `DrawObjects_NoPriority` puts objects with
    `OBJFLAG_PRIORITY` into OAM before Wario (drawn over him),
    `DrawObjects_WithPriority` the rest after him, each through
    `UpdateObjSprite`: the frame's entries from its OAM table (bank `$60` +
    bits 4-6 of its ID; 68 tables decoded, laid out as Wario's) plus its
    screen position, attributes unchanged. Their tiles are the group's four
    enemy graphics, decompressed into VRAM bank 1 (`$8000`-`$8fff`), or the
    common graphics at `$8800` of bank 0; palettes 3 (common) and 4-7 (the
    group's). Over the owner's movie (`make sprite-check`), all 10,547 drawn
    objects' OAM entries equal their decoded frames, and VRAM bank 1 equals
    the decoded image in all four groups it visits; bank 0 from `$8800`
    equals the common graphics but for tiles `$90`-`$9f` (the level's
    treasures). The window draws objects in that order with the room's
    priority pixels over them, and `make window-check` finds every compared
    pixel of the walk equal, the Spearhead's included, once the window
    plays the 60 loops the route runs before the walk (from
    `wGlobalCounter` 246). Particles are left out. A slot's graphics can
    be shorter than its 1 KiB: object group `$12`'s first slot decompresses
    to `$300` bytes, so VRAM bank 1's tiles `$30`-`$3f` keep what the
    screens before left there (no code loads them). The extraction now
    records the span each slot writes (`enemy_vram_written`, objects
    extractor 21), and `make sprite-check` compares only those; level 20's
    movies, which reported group `$12` as differing, then match.

11. **More objects (WL3-040).** Room 21's objects are ported: the small
    leaf (a one-way platform that sinks when stepped on, vanishes, and comes
    back: `SetOneWayPlatformAction`, `Func_62e57`), Futamogu (climbs back to
    its start carrying Wario: `MoveWarioUp`, `HandleUpwardsFloorTransition`),
    and Webber with its projectile (created through
    `_CreateObjectAtRelativePos` from object params in bank `$19`; Webber's
    knock-back runs home-bank update functions, `Func_3326`/`Func_3317`),
    with the walkable interaction (`$0c`: standing on an object, `Func_209ca`,
    which lets the pass go on). Every update of all of them in the movie
    matches (6238 slot updates in all), and whole frames now run alone for
    937 frames, to where Webber's projectile turns Wario electric (an
    unported transformation).

12. **Electric shocks, keys, and coins (WL3-040).**
    - Webber's projectile is `OBJ_INTERACTION_ELECTRIC` (`$1c`): the object
      reacts (`OBJACTION_06`), and unless Wario is invincible or already
      transformed he turns away from it and becomes
      `TRANSFORMATION_ELECTRIC` (`$85`; touching objects now makes them
      vanish) in `WST_ELECTRIC_START`
      ([wario movement](wario-movement.md), item 13). The pass ends.
    - The keys (`$10`-`$13`) set their flag in `wKeyAndTreasureFlags`, the
      key takes `OBJACTION_07`, and `wState` becomes `ST_COLLECT_KEY`:
      `CollectKeyDelay` holds the game for 100 loops (`wGlobalCounter`
      still counts), then the level goes on in `ST_LEVEL`. `KeyFunc` is the
      musical coin's code with its own frameset and box.
    - Breaking a block (`BreakBlock`) leaves a coin when `rDIV & 3` is 0
      and `wCoinCooldown` is clear (it becomes 100): `ObjParams_Coin`
      through `_CreateObjectFromCurObjPos`, at the block's bottom middle
      (`Func_ce3e`: row × 16 + 16, column × 16 + 8), with `wCurObj` saved
      and restored around it. The colour-coin blocks call
      `BreakBlockWithColourCoin`, which always leaves a colour coin and
      rolls nothing; the port had given them the roll before.
    - `CoinFunc` turns the coin through frames 0-7 (8-15 for a colour
      coin) with the frameset pointer's two bytes as counters, slower as
      `OBJ_VAR_1` counts to 150; it bounces away from Wario along three
      tables, falls, slides to rest, and blinks out after 100 frames (50 in
      water, where it moves on even frames only). One coin in 64 (by
      `wGlobalCounter`) is a colour coin. In `CoinFunc.Update` the byte
      after `OBJ_FRAME_DURATION` is `OBJ_FRAMESET_OFFSET` (the in-water
      flag), not the state duration the disassembly's comment names.
    - A coin is one coin (BCD) and ends the pass; a colour coin is ten and
      the pass goes on, as a musical coin's (`CollectMusicalCoin`).

13. **Randomness.** `rDIV`, the hardware timer, is the game's only
    chance: 48 reads (`ldh a, [rDIV]`), in `BreakBlock`, the Spearhead's
    shake, other enemies, the overworld, and golf. The trace records every
    read's value (`div_reads`), hooked at the instruction after it, where
    register A holds it. The sites were found by labelling each read in a
    copy of the pinned disassembly with local labels (which emit no bytes)
    and rebuilding it: the ROM was unchanged (SHA-256 equal), and
    `tests/test_rom_integration.py` checks that every hook follows an
    `ldh a, [rDIV]`. Parity checks replay the reads in order and report a
    read at another site, beyond the original's, or not made. The owner's
    movie makes 13, all in `BreakBlock`. Native play draws from a seeded
    generator instead (provisional: the original's values follow the CPU's
    timing since power-on). With them the Spearhead's shake wobble
    (`OBJSTATE_WOBBLE_LEFT_START` + bit 0) is ported too.

    Whole frames (`make wario-parity MODE=run`) now run alone for 2417
    frames, from the level start (frame 184) through the shock, the key's
    pause, and four rooms, to frame 2863, where a torch (`TorchFunc`) is
    the next unported object. The objects check matches 7130 of 7130 slot
    updates; the interactions check 5792 of 5792 runs, 50 with an effect.

14. **Torches, birds, and chests (WL3-040).**
    - `TorchFunc` drops a pair of embers every 128 frames (`wGlobalCounter`
      & `$7f`), left then right on the next frame, alternating a fast pair
      (1 px a frame) and a slow one (every other frame), through
      `CreateObjectFromCurObjPos`; `OBJ_STATE_DURATION` counts which comes
      next. An ember falls along `Data_60320` and burns out (24 frames)
      where it lands (UNK1) or when an action sets its state.
      `TorchNoEmbersFunc` is the torch alone.
    - `BirdFunc` faces Wario, turns round when he is behind it, and with
      him within `$18` rows and near ahead (`$70` to the right, `$90` to
      the left, as screen bytes) takes off towards him after `$23` frames
      at 2 px a frame. Hit (`OBJSTATE_0B`/`0C`) it leaves stars
      (`ObjParams_BirdStars*`, `StarsFunc_SetFlags`) and flies off; the
      blue bird is stunned instead. Knocked, it runs a home-bank update:
      `Func_3407`/`Func_33f8` (`Func_6283a`/`Func_62892`, knocked without
      Garlic's multiplier) or `Func_3326`/`Func_3317`.
    - The chests (`GreyChestFunc` and the others) are gone once their
      treasure is taken; otherwise `ChestFunc` waits for `OBJSTATE_18`
      (the treasure interaction's action) and for `wAutoMoveState` to
      clear, opens for 86 frames, and creates its colour's treasure 24 px
      above (`ObjParams_GreyTreasure` and the others; any interaction type
      but grey, red, or green gives blue). `TreasureFunc` takes its own
      frameset when its duration runs out.

    All their updates in the movie match on the first run (12703 of 12703
    slot updates in all; 1753 torch, 866 ember, 463 bird, 1328 chest).
    Whole frames run 2721 frames alone, to the chest room's start at frame
    3282, where Silky (`SilkyFunc`) is the next unported object.

15. **Silky (WL3-040).** `SilkyFunc`'s table has 96 states; most of the
    shared ones are home-bank entries jumping to ported routines
    (`Func_31a0` → `Func_62ea5`, that is `Func_62ec3` on `Data_602c0`, and so
    on). The movie reaches 24 states, all ported: Silky walks half a pixel a
    frame, turns at walls, floor ends, or with Wario behind it, and with
    him level (within 15 rows) and ahead winds up for `$23` frames, then
    becomes `OBJ_INTERACTION_SILKY`. Its own three `rDIV` reads (the ground
    shake's wobble) are ported but not reached. States into code not ported
    (grabbing, throwing, `VanishObject2`, `Func_6303f` and its pair) are
    named. All 1640 of its updates in the movie match on the first run. Its
    interaction (`$19`, met on the side it faces, not from above) wraps
    Wario in string ([wario movement](wario-movement.md), item 14).
    Whole frames now run 3343 frames alone, to frame 3985, where fire
    (interaction `$0e`) is next.

16. **Fire (WL3-040).** `ObjInteraction_Fire` (`$0e`, the torches and
    their embers) sets Wario on fire ([wario movement](wario-movement.md),
    item 15). With it and `StepOnObject`'s transformed branch, the
    interactions check matches 5801 of 5801 runs (59 with an effect); the
    only unported interaction left in the movie is the treasure (`$14`).
    Whole frames run 4989 frames alone, from the level start to frame 5746,
    where Wario opens the chest.

17. **The treasure (WL3-040).** `ObjInteraction_GreyTreasure` and the
    others: landed on, a chest is stood on (`Func_209ca`); walked into
    untransformed with its key, `GetTreasure` opens it (`OBJACTION_07`,
    which `ChestFunc` waits for), makes every other object vanish
    (`TreasureClearObjects`), and starts the treasure scene
    ([wario movement](wario-movement.md), item 16) with Wario pushed out by
    the overlap (`wc1c3`/`wc1c4`); otherwise `Func_20a6f` pushes him back
    (and turns a ball of string or a burning Wario). With it the
    interactions check matches all 5802 runs of the movie, none unported.

18. **Particles.** Four 16-byte slots at `wParticles`, taken in turn
    (`wCurParticleIndex`), each with a position and an animation over a
    bank `$03` frameset (pairs lasting their duration and one frame more).
    Most free their slot when the animation ends; slide dust follows Wario
    while he slides; the treasure's glow stays; the owl's (WL3-047) rises
    2 px a frame until its sprite is `$c0` or more down the screen
    (`wCurSpriteYCoord`), and the magic ones follow Wario (through hPos)
    until he stops (`WST_MAGIC_STOPPING`). `UpdateParticles` runs
    first in `UpdateLevel`, and `UpdateParticleAnimation` leaves
    `wCurParticleAnimEnded` for the last particle updated, which
    `UpdateState_GetTreasureClear` waits on: that is how the treasure scene
    ends. The ported code creates them where the original does (walking,
    landing, and ladder dust, slide dust, the electric smoke, the attack's
    stars, a broken block's debris, the glow); the trace records the
    particle region at every object checkpoint, and the run compares it.
    Each is drawn through `LoadParticleSprite` from one OAM table of bank
    `$03`, at its low position bytes less `wSCY`/`wSCX` (the camera's own
    for one configuration), first in OAM, from VRAM bank 0: dust, debris,
    stars, and smoke from the common graphics (`$c0`-`$fe`), the glow from
    Wario's tile set; OBJ palette 2 is `Pals_d1fe`, which every room start
    copies. `make sprite-check` checks every drawn particle's OAM entries
    (1537 of 1537 over the movie), and `make window-check` now compares
    their pixels (the walk's dust at tick 72: all equal).

    **Whole movie.** `make wario-parity MODE=run` now runs all 5802 level
    frames of the owner's movie alone, from the level start (frame 184)
    through five rooms, the key, the transformations, and the treasure
    scene, to where the game leaves the level (frame 6558): every
    checkpoint of every frame (Wario after his update, the particles and
    slots entering `UpdateObjects`, the slots after it, Wario and the slots
    after the interactions, the camera) equals the original's.
19. **Para-Goom (WL3-044).** `ParaGoomFunc` (`para_goom.asm`, bank `$10`)
    has Silky's 96-state layout; 45 entries are its own. It is tall
    (`OBJ_COLLBOX_TOP` `$ef`, `OBJ_INTERACTION_TOP_STING`) or short (`$f4`),
    and several entries choose framesets by that. With nothing under it
    (`Func_352b`) it grows tall and floats down half a pixel a frame
    (`$41`, `$5b`), lands (`$5c`, 10 frames), and starts again. Walking, it
    is harmless for 10 frames, then stings in front; every 256 walking
    frames (`OBJ_VAR_1`) it changes for `$a3` frames, short to tall or tall
    to short. Getting up, it rises along `Data_60530` for 8 frames, then
    floats down. Its five `rDIV` reads are the ground shake's wobble.
    Silky's stun, lying, and slide code is the same bytes, so the port
    shares it (`enemy_stunned`, `enemy_lie`, `enemy_slide`).
    - On the sweep's four levels with Para-Goom (08, 10, 48, b0): all 5342
      of its compared slot updates match on the first run, over 44 states
      reached (walking 1797, turning 981, lying 925, floating 502).
    - Fixed alongside: the shared table named unported paths with the
      loading-time note, which does not mark the slot, so one update into
      `Func_6305f` (the ground shake knocking a lying enemy) was judged and
      differed. Updates now use `note_unported`, which leaves the slot
      unjudged. A unit test covers it.
20. **Brrr Bear and its snowflakes (WL3-044).** `BrrrBearFunc`
    (`brrr_bear.asm`, bank `$12`) has a 93-state table in the same layout
    (to `$5c`). It walks like Silky (8 px left, 7 right) until Wario is
    within `$18` rows and `$48` px: ahead, it blows for `$39` frames
    (`$2d`), throwing a snowflake (`ObjParams_SnowflakeLeft`/`Right`,
    bank `$19`, now extracted) with `$22` frames left, then turns; behind,
    it turns at once (`$16` frames, turned round with 6 left). An attack
    only rocks it (`$08`/`$09`) unless Wario is transformed or has the
    garlic or better (`wEffectivePowerUp` 5), and state `$0a` vanishes it
    on the same rule plus its action. A snowflake flies 2 px a frame
    (`MoveObjectLeft_Fast`/`Right_Fast`), and once its state is set bursts
    for 12 frames. Its interaction is `OBJ_INTERACTION_ICE` (`$27`), not
    ported.
    - On the sweep's four levels with Brrr Bear (48, 98, a0, b0): all 2189
      of its compared slot updates and all 281 snowflake updates match on
      the first run, over 21 states reached (walking 2673, turning 762,
      blowing 456). Unjudged: updates whose probes meet unported block
      handlers (`BlockFunc_SlipperyFloor` in 98, the enemy blocks `$78`
      and `$79` in a0), and 16 interaction runs with a snowflake (ice).
21. **Zip lines (WL3-044).** `ZipLineFunc` (`zip_line.asm`, bank `$12`,
    the new `DeviceFunctions`): lines 1-3 (IDs `$24`-`$26`) run right at
    1 px a frame, line 4 left and line 5 right at 3; lines 2-5 slope (up
    or down by the ID's bit 0 and the direction). A line has no actions
    until Wario is 16-23 px below it, when `ObjInteraction_Rail` (`$29`)
    can grab it; ridden, it carries him 27 px below (his own side probe,
    which may break blocks, and the floor transitions). Against a wall
    (UNK4, 16 px up) lines 1-3 turn and lines 4-5 stop for good,
    releasing him. Let go, a line waits 10 frames, then waits for him
    again. The original adds an unset register `c` to both screen
    positions in the wait's check; it cancels in the difference, so the
    port leaves it out.
    - On the sweep's level 90: all 3679 zip-line slot updates match on the
      first run, with the grab's interaction run; with Wario's hanging
      state ([wario movement](wario-movement.md), item 24), every Wario
      update of the level matches.
22. **Pillar platforms (WL3-044).** `PillarPlatform1Func`-`3Func` (ID
    `$20`, bank `$12`, `DeviceFunctions`) start at heights 1, 2, and 0
    (`OBJ_VAR_1`; 16 px apart) and are one-way platforms. State `$2b`
    raises one a step (to height 2), `$0a` (from Wario) lowers it a step
    and writes `$2b` into every slot whose map column (`OBJ_UNK_01`) is 3
    either side and whose ID is `$20`; each step is 2 px a frame for 8
    frames. On level 40's movie all 2867 pillar slot updates match, but
    only the idle path is reached; the steps and the neighbours are
    translated and covered by a unit test only.
23. **Haridama (WL3-044).** `HaridamaFunc` (bank `$12`, `EnemyFunctions`):
    it swims half a pixel a frame, turning at walls (with its spikes in,
    `OBJ_INTERACTION_06`, for `$1b` frames, turned round with `$0d` left).
    With Wario within 8 rows above or `$18` below and `$40` px ahead it is
    alerted (`$12` frames), then charges at 2 px a frame with its spikes
    out (`OBJ_INTERACTION_HARIDAMA`, `$2a`). Hit from below it surfaces
    while water is above both corners, then drifts out of the water for
    100 frames (a pixel every fourth frame) and fleeing from a hit for 60.
    On levels 40 and 50 all 1999 of its compared slot updates match on
    the first run; level 40's remaining 64 were in probes of the water
    spike and the underwater door, now ported ([block handlers](block-handlers.md),
    item 6), after which level 40's objects are all compared.
24. **The hand (WL3-044).** `HandFunc` (bank `$11`, `EnemyFunctions`) runs
    16 steps by `OBJ_VAR_1`: hidden for 50 frames (held while Wario is in
    sand), shown, six rises of 4 px a frame apart, 56 frames up (during
    which, from 48 to 26 frames left, it waits without actions while
    Wario is more than 4 px above it, so it can catch him), four sinks of
    6 px, and hidden again. Caught (state `$2f`, from `ObjInteraction_Hand`
    through `OBJACTION_13`; neither reached in the sweep), Wario rides it
    at set offsets and is let go at the end.
    - Until it first rises, its frameset pointer is 0, so
      `UpdateObjectAnimation` reads ROM0 from `$0000` (the reset vector and
      zeros) up to the first `$ff` at a pair boundary (offset `$6c`): 54
      pairs, now extracted as frameset `0000` (objects extractor version 13).
    - On level 30 all 2301 hand slot updates match, and the level's
      objects are all compared.
25. **Spear Bot (WL3-044).** `SpearBotFunc` (bank `$11`, `EnemyFunctions`)
    has the standard 93-state layout. It walks like the others (6 px left,
    5 right) until Wario is within `$18` rows and `$40` px: ahead, a
    20-frame wind-up, then a thrust with its spear out (the box reaching
    10 px left or 9 right, `OBJ_INTERACTION_FRONT_STING`), a pixel a frame
    along the floor. At a wall or the floor's end it turns back once
    (`OBJ_VAR_1` holds two thrusts; 36 frames, turned with 15 left), then
    stops for 38 frames and turns. Stunned, it ends in that stop rather
    than a turn. Silky's get-up and state `$12` code is the same bytes
    (`enemy_get_up`, `enemy_12`). On levels 18 and 20 all 1725 of its
    compared slot updates match on the first run, over 10 states, with the
    38 interaction runs that changed something.
26. **Hammer Bot (WL3-044).** `HammerBotFunc` (bank `$11`) has the same
    layout; a ground shake sends it to the shared state `$1a`
    (`Func_6303f`, not ported) instead of a wobble, with no `rDIV` read.
    It walks (8 px left, 7 right; it never turns for Wario behind it) and,
    with him within `$18` rows and `$40` px ahead, raises its hammer for
    20 frames (`OBJ_INTERACTION_BOUNCY`, the box reaching 16 px that way),
    then walks with it a pixel a frame until a wall or the floor's end.
    Stunned, it sees stars (`ObjParams_StarsLeft`/`Right`, now extracted;
    objects extractor version 14) for 20 frames. The step is now split
    (`enemy_on_floor`, `enemy_side_step`), as its walk probes the floor
    before looking for Wario. On level 20 all 1067 of its slot updates
    match over 28 states; the hammer itself is not reached there, and a
    unit test covers it.
27. **The flame block and its torches (WL3-044).** `FlameBlockTorchFunc`
    (bank `$10`) is an unlit torch until its state is set (a touch by
    Hot Wario); lit, it burns (`OBJ_INTERACTION_FIRE`) for 512 frames,
    kept from despawning (`OBJSUBFLAG_UNK_4`), and counts in
    `wNumLitTorches` (`$d143`); when they run out, it despawns and the
    count drops. Once all three are lit, the torches stay lit, and
    `FlameBlockFunc` (bank `$12`) sets `wFlameBlockCleared` (`$d140`) and
    burns away in 159 frames (no actions in its last 25), never to be set
    up again. Both globals lie in the WRAM bank 1 region every object
    checkpoint records, so no new trace variable was needed. On level 70
    all 967 torch slot updates match, but no torch is lit there; a unit
    test covers lighting and the block.
28. **Hebarii and its projectiles (WL3-044).** `HebariiFunc` (bank
    `$12`) clings to the ceiling: it crawls a pixel every fourth frame
    (turning where the ceiling ends, 18 px up, or at a wall, 8 px up), and
    for 41 frames in every 167 shoots, dropping a projectile
    (`ObjParams_HebariiProjectile`, now extracted; objects extractor
    version 15) with 30 frames left if it is on screen. Attacked there,
    its update function becomes the shared knock-back routine itself
    (`Func_3326` and its kin). A ground shake drops it: it falls, lies for
    160 frames, fades for 35, and despawns; its detached table vanishes it
    for most states (`VanishObject2`, not ported). A projectile falls half
    a pixel a frame for 100 frames, drifting toward Wario unless he is
    within `$18` px, and bursts (24 frames) when it lands or hits.
    `DummyObjectFunc` (which clears its slot) is ported too. On levels 28
    and 60 all 1927 Hebarii and 462 projectile slot updates match on the
    first run.
29. **The owl, the tadpoles, and the barrel (WL3-044).** `OwlFunc` (bank
    `$12`) sleeps by day (flies at once by night), wakes when touched,
    rises 54 px, then patrols at a pixel a frame, turning every 60 frames,
    grabbable (`OBJ_INTERACTION_OWL`). `TadpoleSpawnerFunc` sends one
    tadpole (`ObjParams_Tadpole`, now extracted; objects extractor version
    16) when Wario is left of it and 40-79 px above; `TadpoleFunc` waits
    hidden until on screen, then leaps 2 px a frame left along
    `Data_60a20` and `Data_60a40` until it splashes into water; hit, its
    update function becomes the shared knock-back routine. `Barrel2Func`
    stands until something breaks it (most states: 14 frames, then
    despawned). On level 68 the barrel's 550 and the tadpoles' 709 slot
    updates match, and the level compares all its objects; on level a8
    all 332 owl slot updates match.
30. **Teruteru (WL3-044).** `TeruteruFunc` (bank `$11`) flies back and
    forth over 100 px (`OBJ_VAR_1`) a pixel a frame, bobbing along
    `Data_604c0` with the new looped movement
    (`_ApplyObjYMovement_Loop`), turning at each end (26 frames). With
    Wario 24-127 px below and within `$18` px across, it dives for 40
    frames (2 px a frame down, a pixel toward him), able to blind him
    (`OBJ_INTERACTION_TERUTERU`, not ported), then rises for 80. It is
    hidden while Wario is blind and sits on his head then. Its low
    substate nibble counts 8 hits (`DecrementRemainingBossHits`); the last
    vanishes it (not ported). On level 10 all 597 of its slot updates
    match, over the flight, the dive, and the turns, and the level
    compares all its objects.
31. **The zombie and its head (WL3-044).** `ZombieFunc` (bank `$11`)
    creeps a pixel a frame under the floor, hidden, and rises (20 frames,
    its box growing) when Wario is level and 32-63 px away. On the surface
    it walks 2 px a frame and, with him within 48 px ahead, throws its
    head (`ObjParams_ZombieHeadLeft`/`Right`, now extracted; objects
    extractor version 17), flickers headless for 48 frames, and sinks for
    100. The head flies along `Data_605a0` or `Data_60560` (the new
    `_ApplyObjXMovement`), turns back after 48 frames, and is gone off
    screen. Hit, both are knocked away by the shared routine as their
    update function. On level a0 all 340 zombie and 55 head slot updates
    match on the first run; with the enemy blocks (`BlockFunc_EnemyBlock_78`
    to `7f`: solid, broken only by a thrown object, item 43), level a0
    compares all its objects.
32. **Fire Bot (WL3-044).** `FireBotFunc` (bank `$11`) is Spear Bot's code
    with fire for a spear: the same table and logic, its own framesets,
    a 23-frame wind-up and 61-frame stop (20 and 38 for Spear Bot), the
    thrust as `OBJ_INTERACTION_FIRE_BOT`, and a walk that ignores a Hot
    Wario (a diff of the two sources with labels and frameset names
    normalised shows only these). The port now runs both from one routine
    with per-bot parameters (`SPEAR_BOT`, `FIRE_BOT`). On level 78 all
    2400 Fire Bot slot updates match on the first run, and Spear Bot's
    levels are unchanged.
33. **The Doughnuteer and its doughnuts (WL3-044).** `DoughnuteerFunc`
    (bank `$10`) walks like the others (6 px left, 5 right) and, with Wario
    level and within `$40` px ahead, throws a doughnut
    (`ObjParams_DoughnutLeft`/`Right`, now extracted with the two tossed
    up; objects extractor version 18) with `$1a` frames of its 51 left,
    turns, walks off a pixel a frame to a wall, turns again, and pauses.
    Bumped, it may toss a doughnut up (by its frame), then turns to throw
    again or walks off by the way it faces. Doughnuts fly 2 px a frame
    along `Data_60510` (tossed: `Data_60540`); eaten ($18) they are gone,
    hit ($19) they fall away from Wario. A ground shake sends it to the
    shared states `$1a`/`$1c`, which are now ported for every standard
    enemy: `Func_6303f` (a 7-frame pause, `Func_629a6`, then a fall) and
    `Func_6305f` (a wobble by `rDIV`'s bit 0, a new site at `18:7061`). On
    level 08 all 2439 Doughnuteer and 210 doughnut slot updates match, and
    the level compares all its objects (4375).
34. **The clear gate and Pneumo (WL3-044).** `ClearGate1Func` to
    `ClearGate3Func` each set their frameset and fall into `ClearGateFunc`:
    a wall raised 32 px once the minigame is cleared (`wIsMinigameCleared`,
    `$cac1`, now traced; level a8 re-traced). `PneumoFunc` (bank `$11`)
    hovers on a bob read from the start of its own bank (`Data_44000`,
    now extracted; objects extractor version 19), dives at Wario 20-79 px
    below and 16-95 px across at the bob's end, rises back as far as it
    dove, and every 64 frames with Wario near the screen's top rises to
    80 px above him: its target adds the address of `hXPosLoBackup`
    (`$ffb0`) to his Y, which the port keeps as such. On level a8 all 69
    gate and 92 Pneumo slot updates match; only hovering is reached there,
    and a unit test covers the dive.
35. **Omodonmeka (WL3-044).** `OmodonmekaFunc` (bank `$10`) keeps its home
    height (`OBJ_VAR_1`, `OBJ_VAR_2`) and hovers on `Data_604c0`; with
    Wario below it and within reach across it is alert, and right over
    him it drops (`Data_60500`) and climbs back home. Its interaction
    (`$18`, item 22 of [wario movement](wario-movement.md)) catches him:
    OBJACTION_0C gives it state `$2a`, and it lifts him a pixel a frame to
    64 px above its home or a ceiling, holds him bobbing 26 px below, and
    presses Flat Wario instead; when he wiggles free it flies off
    (`Data_604e0`, `Data_60650` with the new `_ApplyObjXMovement_Loop`).
    Hit by any other state, it also flies off, and the original clears its
    home's high byte then (kept as is). On level a8 all 627 of its slot
    updates match, through the alert, the drop, the lift, and the hold.
    The variant carrying an Omodon is item 36.
36. **The Omodon and its carrier (WL3-044).** `OmodonmekaWithOmodon1Func`
    and `2Func` make their Omodon (`ObjParams_Omodon1`/`2`, bank `$19`)
    unless one from their map cell is already out: carrier and Omodon find
    each other's slots by `OBJ_UNK_01` and `OBJ_UNK_02`, the Omodon being
    the one with `OBJFLAG_TRANSIENT`. `OmodonmekaWithOmodonFunc` waits 60
    frames, lowers itself a pixel a frame until it is 15 or 16 px above
    the Omodon on screen, lets 40 frames run out, and picks it up. It
    writes the Omodon's state (`$2d`), duration, frameset, and a box a
    pixel wider each side, and both rise for 50 frames (on even frames
    only while Wario stands on the Omodon, lifting him with it). Knocked
    about, it is thrown as Omodonmeka is; any other state sends it flying
    off for good. `Func_4279c` (the Omodon) hangs until its carrier lets
    go, then falls (`Data_605e0`) until `Func_352b` finds something 15 px
    below it. It then takes the probe's `hYPos` less 15 as its height,
    shakes the ground (`DoGroundShake`, 24 frames; `SFX_063` not
    simulated), and lies solid (`OBJ_INTERACTION_SOLID`, `$22`, after
    `OBJ_INTERACTION_OMODON`, `$23`, while it fell). Under Flat Wario both bob
    along `Data_40000` (bank `$10`, 64 bytes, extracted as `omodon_bob`),
    the Omodon passing its stepped flag to its carrier; landing on
    Wario's head (`$5a`), it sits 24 px above him for 20 frames (sliding
    down 2 px a frame while he is carried) and then lies solid. Its fall
    met `BlockFunc_SmallGap`, ported with its neighbour `BlockFunc_189f1`
    ([block handlers](block-handlers.md), item 6). On level a8 all 334
    carrier and 348 Omodon slot updates match, through the wait, the
    lowering, the lift, the fall, and the landing; the bob, the ride on
    Wario's head, and a struck carrier are translated and covered by unit
    tests but not reached. With them, every object the sweep meets is
    ported: its 25 levels compare 60,008 object slot updates, all
    identical.
37. **Interactions the whole-frame sweep met (WL3-044).** Run alone
    (`MODE=run`), four sweep levels stopped where Wario touches an
    interaction not yet ported; translated now in `ObjectInteractions`:
    `Func_20e60` (`$0a`: Wario bounces off, `Func_20939`), `Func_20e6a`
    (`$0b`: the same, then `OBJACTION_0A` with no touch state),
    `ObjInteraction_Stove` (`$2f`), and `ObjInteraction_Tadpole` (`$3c`,
    shared with the Robo-Mouse, `$30`: stepped on from above or below;
    met head on it rolls Wario the way it faces through
    `ObjInteraction_RollingRock` and `Func_1e174`; from behind,
    `Func_20e6a`). With them the Omodon's `ObjInteraction_Solid` (`$22`)
    and `ObjInteraction_Omodon` (`$23`), which share the stove's sides:
    from above Wario stands on it (`Func_209ca`, or a smash attack,
    `Func_20602`, ported now for walkable objects and `StepOnObject`
    too); from below `Func_2168b` pushes him down by the overlap (12 px
    at most) and he dives, stands, or falls, while a falling Omodon
    flattens him (`OBJACTION_FLATTEN`; `SetState_FlatAirborne` and the
    other Flat Wario states named as unported); from the side an attack
    bumps him back and otherwise he is pushed out (`Func_20a6f`). The
    movies reach `$0a` and `$0b` bounces, the stove from the side, and a
    tadpole head on; the rest is covered by unit tests. Two paths of the
    original are named as unported rather than copied:
    `Func_2023b` with `TOUCH_VULNERABLE` jumps to `Func_20939`, which
    jumps straight back (the disassembly notes the infinite loop), and
    `Func_20e6a` *calls* `Func_20939`, so when that goes on to
    `ProcessInteractions.next_obj` the original keeps the call's return
    address and comes back to its tail only at the pass's end.
38. **What the attack movies met (WL3-044).** The `right-attack` script
    (B for 4 of every 40 ticks besides the jumps; [emulator
    oracle](emulator-oracle.md), item 17) on the 25 sweep levels.
    `WaterSparkFunc` (bank `$12`, level 18) waits for an action to give
    it a state, then sparks for 100 frames without actions
    (`SetObjectFramesetPtr` leaves `hl` at `OBJ_STATE_DURATION`, where
    the 100 goes). `VanishObject2` is `_VanishObject` behind a home-bank
    trampoline, so the eight places that named it as unported now
    vanish the object (the enemies' state `$0a` and the rest of their
    tables, Hebarii sinking into water or sand, Teruteru's last hit).
    Interaction `$3b` (`Func_21c56`) is a walkable object's top
    (`Func_21aac`) and `$00` (`Func_20b6b`) otherwise; `Func_20b6b` now
    also steps on the object, rather than naming the pick-up as unported,
    on a ladder or with Wario facing away from it. The sweep compares
    62,394 object slot updates, all identical, none unported, and 29,998
    interaction runs; 24 of the 25 levels run whole frames alone to the
    end. Level a8 stops where an Omodon flattens Wario (item 37): Flat
    Wario's 1103 updates there are not compared yet.
39. **The crouch and wander movies (WL3-044).** `right-crouch` (Down
    for 30 of every 90 ticks) and `wander` (24-tick segments of 12 button
    sets) on the 25 levels. They met interaction `$21`
    (`ObjInteraction_FireBot`: stepped on from above or below, met head on
    it sets Wario on fire, otherwise `Func_2022c`) and `$06`
    (`Func_20d81`: `Func_20899` from above or below, otherwise
    `Func_208f2`, which bumps the object in water and dives an
    untransformed Wario), now ported. The crouch sweep then compares all
    29,907 Wario updates and 30,000 interaction runs, all identical. The
    wander sweep compares 29,495 of its 29,874 Wario updates, all
    identical; it still meets Zombie Wario (`$1f`, level a0), Blind Wario
    (Teruteru's `$38`, level 10), Bouncy Wario (`$20`, level 58),
    slipping (level 98), and the multi-block breakables (58, b8).
40. **Picked up, held, and thrown (WL3-046).** The objects' side of
    grabbing ([wario movement](wario-movement.md), item 31), in the shared
    routines of bank `$18`: `Func_61f54` and `Func_620a6` rise along
    `Data_601c0`/`Data_601e0` ((frames, dy, dx) from Wario, the last
    entry repeating; a wall ahead or a ceiling drops a heavy object or
    tells Wario a light one is up, `GRAB_UNK_02`), then hold it 30 px
    above him (26 while he smash-attacks) and 7 px ahead, dropping it
    16 px lower onto something solid. Each enemy's `$18`/`$19` and
    `$48`/`$49` keep it held (its frameset, a 5 and 6 px box,
    `OBJFLAG_GRABBED`), following Wario's side (`Func_621fb`,
    `Func_622bd`, whose ceiling and wall probes are masked the opposite
    ways round); `Func_62382`/`Func_6247b` carry it while the throw
    charges, 5 px the other side while a full charge is held.
    `ThrowObject_Left`/`_Right` make it harmless and send it on
    `$4e`/`$4f` at 3 px a frame (2 heavy, 1 with Up; arcs `Data_60080`,
    `Data_60100`, heavy `$20` on) or, fully charged, a full throw at 4
    (`Data_600c0`, `Data_60140`) that vanishes against a ceiling or wall
    and is let go off the screen's side; both land through
    `Func_62d34`/`Func_62e0f`. `HandleGrabbedObjectCollisions` runs the
    first grabbed object against the others' boxes in screen space and
    knocks both away (or wobbles them, for heavy ones), ending a grab the
    one met was in; it keeps four states in HRAM between frames, and a
    held object (`$48`-`$4b`) sets only the light ones, so a heavy object
    it meets takes the heavy ones an earlier full throw set. Ported for
    the Spearhead and Para-Goom (the two the power-up sweeps pick up);
    the Spearhead's table also gained `$1a`-`$1c`, `$58`, and `$59` (the
    shared routines). On the six movies of levels 00, 38, and 48 with
    every power-up, every Wario and object update matches on the first
    run. The other enemies' own `$06`/`$07`, `$18`/`$19`, `$48`/`$49`,
    and `$4c`/`$4d` entries are still named as unported.
41. **The last interactions of the power-up sweeps (WL3-046).** `$24`
    (the orange bird, Crazy Wario: [wario movement](wario-movement.md),
    item 32), `$3d` (`ObjInteraction_Hebarii`: bounced off as `$0b`, or
    attacked from the side), and `$28` (`ObjInteraction_Owl`: bounced off
    from the side; grabbed from below it makes Owl Wario, named as
    unported and not met).
42. **The Spearhead asleep (WL3-047).** At night (`wDayNight` bit 0) the
    Spearhead's `.Init` goes to `.SleepStart`: sting in
    (`OBJ_INTERACTION_01`), `OBJSTATE_SPECIAL_1` (`$2d`), `Frameset_68234`,
    box -6..5. `.Sleep` faces away from Wario (HDIR clear while he is to
    the right, the opposite of `.Default`) and wakes when his screen
    position is within 32 px right or below and 31 px left or above
    (`(obj - wario) mod 256` below 32 or from `$e0`, on both axes):
    `OBJSTATE_SPECIAL_3`, `Frameset_6827c` (or `Frameset_68287` and box
    -7..9 facing right) for 32 frames, then `.TurnAroundStart` (`.WakeUp`,
    already ported). Asleep, a ground shake wobbles it (the `rDIV` read
    at `10:41c8`), and without ground below it falls. On the night
    `wander` sweep, all 52,255 compared object updates match, step mode,
    and all 25 levels run whole frames to the end.
43. **A thrown object breaks an enemy block (WL3-047).**
    `EnemyBlockCollision` with `COLLISION_THROWN_OBJ` goes to
    `Func_19423`: the block becomes its replacement (`$78`-`$7f`, bit 7
    kept), `Func_e2b` queues the redraw when the object is on screen,
    and on screen `BreakBlock` follows (debris, the `rDIV` roll at
    `06:562c`, maybe a coin in the first free slot); off screen there is
    only the sound. Either way the probe sees `BlockFunc_Free`. The
    night `right-attack` sweep at power-up 9 met it on level 04 (a thrown
    Spearhead through a 2×2 enemy block, a coin at the first break); the
    port's stub had already returned free, so only the coin and the four
    rolls differed, once the trace's block changes were placed in their
    phase ([emulator oracle](emulator-oracle.md), item 16).
44. **The snake and its fire (WL3-047).** `SnakeFunc` (ID `$2d`, bank
    `$12`) keeps its home height (`OBJ_VAR_2`, `_3`) and is a one-way
    platform 15 px wide left of its x. By the substate it waits ($78
    frames, then $3e), rises half a pixel a frame (stood on, a pixel on
    odd frames carrying Wario and his floor) for $3e frames, looks ($53),
    opens its mouth when its animation reaches the frame, and then, with
    a free slot, breathes fire for $93 frames (`ObjParams_SnakeFireLeft`
    or `_Right`, objects extractor 22), closes it, and sinks home. While
    rising or sinking its state is `$48` off the screen's middle rows.
    It turns to face Wario when he is within $28 px above or below on
    screen (`OBJ_VAR_1` = $14, the turn's frameset). Touched to vanish,
    attacked, or hit by a thrown object it sinks at once. `SnakeFireFunc`
    is invisible and lasts while the snake with its map cell breathes
    fire. On the later variants' sweeps every update of both matches.
45. **The bots picked up and thrown (WL3-047).** Spear Bot's and Fire
    Bot's `$06`/`$07` are the standard picked-up starts, `$18`/`$19` and
    `$48`/`$49` the standard held states with their own "hit" frameset,
    and `$4c`/`$4d` go straight to `ObjState_FullThrowLeft`/`_Right`
    (no frameset of their own). Level 5f's power-up `wander` movie
    picks up a Fire Bot; it matches. Hammer Bot, Hebarii, Teruteru,
    Doughnuteer, and Brrr Bear have their own variations (boxes,
    framesets, branches) and stay named as unported.
46. **The last interactions (WL3-047).** With the room starts every
    interaction the sweeps meet is ported: `ObjInteraction_Richtertoffen`
    (`$0f`: from below it flattens Wario where his widened box, -11 to
    11, fits between walls and no ladder is under him), `_Haridama`
    (`$2a`, `Func_207ed`: in water a sting with no sting-touch state
    water-stings him), `Func_21af1` (`$31`), `_DollBoyHammer` (`$32`,
    Bouncy Wario), `_RollingRock` (`$33`), `_Wormwould` (`$34`),
    `Func_21b78` (`$36`), `_WaterDrop` (`$39`: a transformation ends),
    `_PrinceFroggy` (`$3e`, `Func_20b41` from the side by the touch
    state), `_Ink` (`$42`), `_Turtle` (`$45`: in water he dives), and
    `_BottomSting` (`$4c`), with the transformations' own (wario
    movement items 34-42). Every sweep (3,258 movies) then compares all
    3,845,136 interaction runs, all identical, none unported.
47. **Bubble holes, Nobiiru, Kobatto, the stove (WL3-047).** The room
    starts' most frequent objects. `BubbleHoleFunc` blows a bubble
    (`ObjParams_Bubble`) every 208 frames while fewer than two transient
    objects are active (one with Wario in a bubble;
    `_CountActiveTransientObjects`); `BubbleFunc` rises a pixel a frame,
    bursts at a ceiling or out of water, and on screen drifts on odd
    frames along `Data_44020`/`Data_44050`, data at the start of its own
    function bank (`$11`), now extracted as `bank_data` with bank `$10`'s
    (objects extractor 23). `NobiiruFunc` grows out in six steps, stings,
    and goes back in: its first step's box edge is the interaction byte
    (the source reuses `a`). `KobattoFunc` flies along `Data_60ec9`
    (`ApplyObjSetMovement`, now ported). `StoveFunc` falls, settles,
    slides when attacked, and shakes the ground when it lands after
    standing. Every sweep then compares 6,846,958 object slot updates,
    all identical.
48. **Appleby and its apples (WL3-047).** `ApplebyFunc` waits in its
    hole while on screen, comes out (colliding), watches until Wario is
    4 to $45 px below and within $40 px either side, turns to him and
    throws an apple ($46 frames into a $7a-frame throw), and goes back
    in; touched it vanishes, attacked or thrown at it is knocked away by
    the shared routines (as its update function, at speed 2), any other
    hit sends it back in. `AppleFunc_Left`/`_Right` fly 2 px a frame at
    a Wario $10 px or more away and fall along `Data_60670`; taken
    (`$18`) they vanish, hit (`$19`) they bounce off away from him along
    `Data_60040`. `.Update2_Left` tests `jr nz` after a load, so it reads
    the flags the object dispatcher left (`or BANK("Object Functions
    1")`, never zero): the left apple always moves. Its rooms (six on
    day 1) compare every update, all identical (objects extractor 24:
    the apples' params).
49. **Beam Bot and its beams (WL3-047).** `BeamBotFunc`'s state table is
    Spear Bot's slot for slot (only `$41`, the standing fall, is the
    shared one), with its own walk, beam, and turn: within $1c rows and
    $48 px ahead of a Wario who is not split (and the bot on screen) it
    winds up for 41 frames, the beam (`ObjParams_BeamLeft`/`_Right`)
    leaving $19 frames before the end, then stays firing 50 frames and
    turns (turned round with 6 frames left); at a floor's end it waits,
    its animation slowed on even frames, before turning. Its four `rDIV`
    reads are the ground-shake wobbles. `BeamFunc_Left`/`_Right` fly
    along `Data_60610`/`Data_60630`, clearing any state they are given.
    Its eight day-1 rooms compare every update, all identical (objects
    extractor 25: the beams' params).
50. **Kushimushi (WL3-047).** `KushimushiVerticalFunc` and
    `KushimushiHorizontalFunc` patrol in four phases on even frames: a
    pixel a frame along their line for $60 frames then 22 more, a 96-frame
    turn (the vertical one's sting moving from bottom to top and back, the
    horizontal one's front sting turning it round), and so on; a bounce
    off one ($0d/$0e vertical, $0b/$0c horizontal) stops it $3c frames;
    `$0a` vanishes; any other hit knocks it away by the shared routines
    (odd states left, even right). Its six day-1 rooms compare every
    update, all identical.
51. **Togeba (WL3-047).** `TogebaFunc` waits spiky (a full sting) on its
    ceiling; a hit makes it flinch $16 frames. A ground shake knocks it
    off ($30 frames along `Data_60760`, bounced off) into a walkable
    platform that sinks half a pixel a frame (stood on, carrying Wario
    and his floor) until a floor under either edge lands it ($10 frames,
    then spiky again); hit, it flinches, and with `OBJ_UNK_1D` bit 7 it
    rises 2 px a frame first. Its seven day-1 rooms compare every update,
    all identical.
52. **Sparks, fires, wall cracks, water drops, electric lamps
    (WL3-047).** `SparkFunc` moves a pixel on even frames along its line
    (`SPARK_HORIZONTAL` right and left, the other up and down), $50
    frames each way; `FireFunc` stands still; `WallCrackClosedFunc` and
    `_OpenFunc` only keep themselves from acting. `WaterDropFunc` hangs
    $41 frames, falls (`FallingYVel_Light`) to a floor or water, splashes
    ($18 frames; touched, it splashes too), and invisibly rises back home
    (at least $3c frames). `ElectricLampFunc` charges for 30 frames each
    time `wGlobalCounter` comes round to 0 and drops a spark
    (`ObjParams_ElectricLampSpark`, objects extractor 26), which falls
    along `Data_60040` and runs 2 px a frame towards Wario until a state,
    a wall, or the floor's end clears it. Their 17 day-1 rooms compare
    every update, all identical.
53. **The Seeing Eye door and the invisibility potions (WL3-047).**
    `SeeingEyeDoorFunc` sits 24 px lower than its spawn; closed (its
    update after `.asm_45545`, at `11:54f6`, an unlabelled entry) it
    waits for a visible Wario within $36 rows below its eye line, then
    opens looking far left or right by his side, and its eye
    (`OBJ_VAR_1`: `$5a`, `$5b`, `$5c`, `$2d`, `$2e`) follows his screen
    x a step at a time; out of sight or invisible, it looks about 8
    frames (or at once from the far ends) and closes. Any state is
    cleared. `InvisibilityPotionFunc_Left`/`_Right` fly 2 px a frame
    along `Data_60510` and vanish when taken (`$18`; `VanishObject_NoSFX`);
    `_Drop` falls along `Data_60540` to a floor. Their day-1 rooms
    compare every update, all identical.
54. **Prince Froggy (WL3-047).** `RedPrinceFroggyFunc` starts stuck in
    the ground (stood on it struggles while stood on; hit it flinches 40
    frames); a turn (`$13`) frees it to sit. `GreyPrinceFroggyFunc`
    starts sitting: 73 frames waiting with its own interaction (`$3e`)
    and a box top of -26, then still. A ground shake bounces it ($1b, 13
    frames); knocked, it goes by the shared routines at speed 1; touched
    to vanish, it leaves along `Data_60040` for 16 frames, 8 px left, and
    is gone. Its nine day-1 rooms compare every update, all identical.
55. **Barrel 1, and Barrel 2 carried (WL3-047).** `Barrel1Func` stands
    without object collisions until stood on for 10 frames running, then
    waits $11 frames and sinks along `Data_60a50`, carrying a standing
    Wario down by the same amount and settling his floor (`Func_34fc`:
    `Func_63209`, then `Func_19720`). `Barrel2Func`'s pick-up, hold, and
    full-throw states now run the shared grab routines (items 40 and 45);
    the Rock shares its table (item 57). In all sweeps: Barrel 1's
    68,164 updates in 24 movies and Barrel 2's 63,790 in 76, all
    identical.
56. **Falling snow (WL3-047).** `FallingSnowSpawnerFunc` waits $1e
    frames, drops a snow (`ObjParams_FallingSnow`, objects extractor
    27), shakes $56 frames, shows itself $0a px higher (and $0a px left
    by bit 0 of `rDIV`, its one read) for $1d frames, and hides again
    for $3c. `FallingSnowFunc` waits, loosens ($20 frames), and falls
    along `Data_603e0` to a floor (lands, $2d frames) or is taken
    (`$18`: it falls on, then 7 frames); any other state bursts it ($11
    frames). 26,952 updates in 12 movies, all identical.
57. **The Rock (WL3-047).** `RockFunc` is Barrel 2's table with no
    frameset changes, a bump's `OBJ_VAR_2` of 1, and 25 frames of
    breaking (`Frameset_69c01`); the port shares one table
    (`_carried_object_update`). 11,151 updates in 16 movies, all
    identical.
58. **The small Octohon (WL3-047).** `SmallOctohonFunc` (no box) swims
    toward Wario: $ac frames one way, then its turning frameset, and at
    step $ee of its sway (`Data_4a5a9`, a table inside bank $12's code:
    the extractor's bank data now takes any range, version 28) back the
    other way, in front of or behind the background by bit 0 of
    `rDIV`. Each frame the sway's step moves it, except that past the
    first step a solid block where it is (`Func_3513`) skips the step.
    54,341 updates in 31 movies, all identical.
59. **The Robo Mouse (WL3-047).** `RoboMouseFunc` faces Wario and walks
    a pixel a frame, held to the floor; at a drop 8 px ahead it is
    knocked down by the shared routines, and otherwise the blocks 12 px
    ahead at three heights break for it (`COLLISION_ROBO_MOUSE_BREAK`)
    and a block solid to it (`_FREE`) 20 px ahead makes it climb 6 px.
    Its `$0a` with collisions off stuns it (stars over Wario,
    `ObjParams_StarsAbove` and `StarsFunc_WithYOffset`, objects extractor
    29) and knocks it away; otherwise it sinks, splashing. Stopped, it
    turns to Wario if he is behind it. Its init sets bit 4 of the
    substate with `set OBJFLAG_INVISIBLE_F` (hl still at the substate),
    kept as the source has it. 8,028 updates in 12 movies, all identical
    (the stunned branch not reached).
60. **Count Richtertoffen (WL3-047).** `CountRichtertoffenFunc` walks 44
    frames, then leaps toward Wario (away from him when bumped, the other
    way from its own when he is flat) 22 frames along `Data_603d0` (a
    ceiling 18 px up ends the rise), falls along `Data_603e0` (water
    vanishes it), and lands with a ground shake (24) and a bounce
    (`Data_604b0`); walls 10 px up turn it in the air. Flattened (`$2a`)
    it sits 8 px above Wario's feet for 20 frames and leaps. Its stun
    ends by writing `OBJ_INTERACTION_RICHTERTOFFEN` (`$0f`) to the state,
    and its turn by writing `OBJ_INTERACTION_01`: the source's constants,
    kept. The held states are Barrel 2's (`carried_object_held`, now in
    `ObjectFunctions`). 15,923 updates in 14 movies, all identical.
61. **Wolfenboss's platform (WL3-047).** `WolfenbossPlatformFunc` holds
    its frame until a state `$2f`, stays 80 frames, is knocked away
    (`Func_3326`) while on screen, and then is gone for good:
    `Func_56326` writes 7 to its object-map nibble and gives its map byte
    bit 7 back (`Func_ba42`). 14,400 updates in 12 movies, all identical.
62. **The enemies picked up and held (WL3-047).** Silky, Brrr Bear,
    Hammer Bot, Hebarii, Teruteru, and the Doughnuteer had their
    pick-up, hold, and full-throw states named as unported; the run
    sweeps reached them. Each picks up as the standard enemies do
    (`Data_601c0`/`_601e0`, Hebarii with its frameset first), throws by
    `ObjState_FullThrowLeft`/`_Right` (Silky and Hebarii set the state
    and a frameset first; the others keep the state), and holds through
    one routine, `held_turning`, differing only in its grab: Silky's
    frameset by direction and a -6..5 box, Hammer Bot's with -8..7, the
    Doughnuteer's with its box kept, Brrr Bear's and Hebarii's one
    frameset, Teruteru's with a box top of -7, bottom -1, and its
    substate's routine bits 8.
63. **The Shoot minigame's goal counters (WL3-047).**
    `ShootGoalCounterFunc` and `WarioGoalCounterFunc` start $58 px up
    with frame `$3c`, kept from despawning, and show their goals
    (`wShootGoals`, `wWarioGoals` at `$d144`/`$d145`, inside the object
    WRAM the port mirrors): visible at one, frames `$3d` and `$3e` at two
    and three; the Shoot counter's third clears `wBossState` (now a
    variable, also cleared by `TriggerRoomTransition`; nothing ported reads
    it yet). `InitObjectVars_FromLevelStart` and `_FromTransition` now also
    clear `wDollBoyNoFlashingBarrel` to `wWarioGoals` (and the level start
    `wFlameBlockCleared`), as the source does. The ball that scores is not
    ported, so in the object step a counter after it in the same pass is
    left unjudged when the bytes past the slots end up different (see
    [emulator oracle](emulator-oracle.md), item 17). 14,332 updates in 6
    movies, all identical; 68 unjudged.
64. **The cart (WL3-047).** `CartFunc` is a one-way platform
    (`SetOneWayPlatformAction`) until stood on, then rolls a pixel every
    other frame (`CART_RIGHT` right, otherwise left), carrying a standing
    Wario unless his side probe (`Func_19706`, `Func_19713`) meets a wall,
    until a block 4 px up and 14 px ahead (15 to the left) stops it for
    good (`CartStoppedFunc`). `CartVariableFunc` reads whether the Truck
    Wheel is collected (`IsTreasureCollected`), which the port does not
    model: still named as unported (until item 77). 9,490 updates in 18
    movies, all identical.
65. **Wormwould's start (WL3-047).** The first boss port, in a new
    `BossFunctions` class between `DeviceFunctions` and
    `ObjectInteractions`. `WormwouldFunc` keeps its hits (3, plus one) in
    the substate; `.Init` waits, without actions, until its y's low byte
    is Wario's (the high bytes are never compared: the second `ret nz`
    sees the first compare's flags), then moves 32 px down, starts the
    battle (`wBossState` `BOSS_REGULAR`, `wIsBossBattle`; the music not
    simulated), takes the side away from Wario ($70 px over if he is
    within $38 px in front), and goes on to `.Main`, which is not ported
    yet. `.DoNothing` (what `.Main` leaves when the worm is less than 32 px
    above the screen's top, the battle off) is ported. 13,080
    updates in 12 movies, all identical.
66. **Mad Scienstein (WL3-047).** `MadSciensteinFunc`, a standard enemy
    with its own table: it walks half a pixel a frame and, with Wario
    within 32 screen rows and 64 px in front, throws an invisibility
    potion at him ($18 frames into its 63-frame throw:
    `ObjParams_InvisibilityPotionLeft`/`_Right`, objects extractor 30),
    turns ($2b, round at 8 frames left), hurries back a pixel a frame
    ($5b) to a wall or the floor's end, turns ($2c), and stops ($5c);
    Wario behind it turns it ($13). A bump drops a potion when its frame
    is below 6 or `$14` to `$18` (`_DropLeft`/`_DropRight`), and it hurries
    off afterwards. A ground shake pauses it in a walk or turn ($1a) and
    knocks it in a throw, hurry, or stop ($1c). The shared states,
    pick-up, and hold are the standard enemies'. 34,113 updates in 35
    movies, all identical.
67. **The Sun (WL3-047).** `SunFunc` follows Wario
    (`SunMoon_GeneralMovement`: across while he is more than 32 px away,
    at speed 2 off screen, turning to face him through a turning frameset,
    and up or down to $2a px above his feet, walls and floors stopping
    it). Each button press (not Select or Start) restarts its 50-frame
    wait; after it, with Wario within 64 px across and less than 43 below,
    it attacks for 82 frames: across toward him, bobbing along
    `Data_60690` unless on a floor (`wc1ca` aside), and at 52 frames left a
    flame (`ObjParams_SunFlameLeft`/`_Right`, objects extractor 31) flies
    along `Data_606e0`/`_606f0` until given a state (14 frames out). 3,576
    updates in 12 movies, all identical.
68. **Wormwould (WL3-047).** The rest of the boss after its start (item
    65): idle 43 frames, it shoots a high rolling rock 48 frames into a
    69-frame shot (`ObjParams_HighRollingRockLeft`/`_Right`, objects
    extractor 32); attacked it burrows after 26 frames, shaken at once;
    smashed (`$0a`) it is hurt 50 frames along `Data_60dd0` (a hit taken:
    `DecrementRemainingBossHits`, never below the substate's 1) and
    burrows, down a pixel a frame (on even frames while unhurt) to its
    home, waits 30 frames underground (invisible), and rises on a side
    again; with one hit left it rises only to $1e and shoots a low rock
    instead. Above the screen's top it stops for good (`.DoNothing`, the
    battle off). With no hits left it rises $21 frames (object-map nibble
    5), waits, faces Wario, ends the battle (`wBossState`
    `BOSS_DEFEATED`), and falls along `Data_60180`. The rocks roll 2 px a
    frame bouncing along `Data_608b0` or `_60900` and, given a state, are
    knocked off along `Data_60180`. The palm trees after the battle are not
    ported (their palettes are presentation).
    In the sweeps: 14,400 updates of Wormwould (waiting, the battle, under
    ground, stopped) in 12 movies and 620 of its rocks in 4, all
    identical; its smash, hurt, and defeat are covered by
    `test_bosses.gd`.
69. **Wolfenboss (WL3-047).** The whisp sways (`Data_60650`) until on
    screen for its 20 frames, rises 64, turns to smoke and emerges (the
    battle on), and after 40 frames hovers (`Data_604c0`) half a pixel a
    frame across the screen, turning at x `$18` and `$98`. When
    `wGlobalCounter` comes round to 0 it attacks Wario in front (or turns
    to him first): a magic spiral (two first, then whenever an Igaguri or
    Kuri is out) or an Igaguri, 16 frames into the attack. A spiral grows,
    then bounces a pixel a frame off the screen's edges, counting its
    bounces down in the substate, and vanishes at the last one, when
    Wario is transformed, or at the wolf's last hit. An Igaguri falls 4 px
    a frame (thrown up along `Data_60d80` at the last hit, then bouncing
    toward Wario along `Data_60e00`), shakes the ground at each landing,
    and hatches a Kuri (`ObjParams_Kuri`), which walks away from Wario;
    attacked, it is launched 2 px a frame up and 3 across, grabbed, and
    hitting the wolf (`$08`) hurts it 60 frames (a hit taken in the
    substate and `wWolfenbossRemainingHits`). Wario transformed, the
    wolf leaves in smoke; with no hits left it falls along `Data_60da0`
    off the screen, the battle ends, and its platform (item 61) opens.
    Spirals, the Igaguri, and the Kuri are objects extractor 33. In the
    sweeps: 9,772 updates of the wolf (whisp to battle and leaving) in 10
    movies and 884 of its spirals in 4, all identical; the Igaguri, the
    Kuri, and the defeat are not reached (`test_bosses.gd` covers a
    spiral's last bounce and a Kuri leaving).
70. **Doll Boy (WL3-047).** `DollBoyFunc` stands on three barrels
    (`DollBoyBarrel1Func`-`3Func`, its parts and theirs counted in the
    substate and `wDollBoyRemainingParts`); on screen after 40 frames the
    battle starts. Each frame `rDIV` of 250 or more (its first read, at
    `14:4c48`) throws a hammer 19 frames into a 56-frame throw, the four
    ranges in turn (`Data_60ae0`-`_60b60` across `Data_60860`, or straight
    right from near Wario's level). A barrel flashes (70-73 frames off
    `rDIV`, the second read, then 240) when it is the last or off Wario's
    level; attacked while flashing it is knocked out (`Func_3317`), and
    the barrels and Doll Boy above it fall (`Data_60880`, or after a wait
    `Data_60b80`/`_60ba0`). On the doll alone it walks (bouncy to Wario),
    turns at walls with a hop, jumps to Wario's platform above or below,
    and is stunned by a hit; attacked while stunned it is defeated. Its
    hammer hitting Wario (`$0b`, `$0c`) or Bouncy Wario ends the battle.
    The hammer platforms rise and sink carrying Wario. Its palettes are
    presentation and not simulated. Objects extractor 34. In the sweeps
    31,145 updates (the barrel phase, its hammers thrown and hit, its
    stop) in 6 movies, all identical; the walking phase is not reached.
71. **Yellow Belly (WL3-047).** `YellowBellyBodyFunc` flashes three
    times (palettes not simulated), rises, puts out its head
    (`YellowBellyHeadFunc`, 16 px under it and 8 to its front), and swims
    3 or 4 laps (`rDIV` at `14:5429`) bobbing along `Data_60950`; with
    Wario below on its last lap it shoots an arrow at him
    (`YellowBellyArrowFunc`, after turning to him if need be), then swims
    again (laps by `rDIV` at `14:5504`). Puffy Wario's touch inflates it:
    it puts out its pump (`PumpFunc`) and chases it; Wario pumping it
    (the pump touched, `$0a`) hurts it (`wYellowBellyHit`, a hit taken),
    and an arrow shot while inflated carries the pump off. After its hurt
    its OAM changes with the hits left (`OAM_191940`, `OAM_191f04`); with
    none it is defeated and its platform opens. Hitting its head stops
    it 30 frames and ends the battle; an arrow hitting Wario ends it too.
    Its variables share Doll Boy's bytes (`$d146`-`$d148`). Objects
    extractor 35. In the sweeps 21,086 updates (to its swimming, shots,
    and arrows; Puffy Wario's pump not reached) in 6 movies, all
    identical.
72. **Anonster (WL3-047).** `AnonsterFunc` swims bobbing along
    `Data_60790` (its loop index in `OBJ_VAR_3` times its actions), turning
    at walls; every second time round, with no transient object out, it
    spins three silks (`ObjParams_AnonsterSilk1`-`3`, fewer as hits are
    taken). Knocked down (`$28`) it rises to the top, chases above Wario,
    drops (`Data_607f0`) shaking the ground, and walks on the floor
    making waves (`ObjParams_AnonsterWave*`) at Wario ahead; touched from
    behind it is hit (`DecrementRemainingBossHits`), crouches, and flies
    back up (`Data_607e0`), or with no hits left falls defeated. A silk
    floats 2 px a frame bouncing off walls, then sways down
    (`Data_60800`/`_60830`, turned by `rDIV` at `14:484b` and walls) to a
    floor, where it is a grabbable object with the standard shared states
    for 120 frames. `SilkPlatformsFunc` puts out three sinking platforms.
    Its palette is presentation. Objects extractor 36. In the sweeps
    11,940 updates (swimming and its silk) in 6 movies, all identical.
73. **Scowler (WL3-047).** `ScowlerFunc` swims across with its two
    tentacles (`ScrowlerTentacleFunc`, placed at its sides by its facing),
    and with Wario level or above it shoots ink every so often (its hits
    left times 32, plus `$48`, frames: `ObjParams_InkLeft`/`_Right`). The
    ink follows Wario and, touching him, blacks out the screen for a
    while (`Func_54c07`: counters in `$d146`-`$d147`; the palettes are
    presentation). Hit (`$08`) it is stunned, then opens its mouth and
    chases Wario up and down; hit then from below Wario it is hurt (a hit
    taken), rises, and swims again; with no hits left it sinks away. While
    its mouth is open its tentacles harm Wario (`OBJ_INTERACTION_43`) and
    then swallow him (water teleporting), and a room transition puts
    Wario at it. The floating rings rise as platforms. Objects extractor
    37. In the sweeps 8,437 updates (swimming, ink, stunned, mouth open)
    in 3 movies, all identical.
74. **Muddee (WL3-047).** A turtle (`Turtle1Func`) carries Wario right a
    pixel every other frame and sinks, starting the ambush
    (`wMuddeeAmbushState` 1): `MuddeeFunc` blinks, waits for Wario far
    enough left and above, and comes out with two stingers
    (`MuddeeStingerFunc`, placed on it by its frame from
    `Data_4caed`/`_4cb0d`, read from bank `$13` like the Octohon's sway:
    objects extractor 38). It goes up and down to 16 rows above Wario,
    left and right to the walls, dives, comes out under Wario, and at its
    last hits roams; its interaction follows its frame. Touching a stinger
    hurts it (`wMuddeeHit`): it sinks to the water and dives; at the last
    hit it is defeated, and the turtle rises to end the battle and carry
    Wario on (`TurtleCommonFunc`; `Turtle2Func` gives way to the first).
    In the sweeps 6,292 updates (the turtle's carry and sinking, Muddee's
    blinking wait and lurking) in 6 movies, all identical. No movie gets
    Muddee out of the water, so the battle itself (rising, the stingers,
    hits) is translated but unverified.
75. **Jamano (WL3-047).** `SkullSpawnerFunc` puts out four skulls
    (`ObjParams_Skull1`-`4`) and starts the intro (`w1d149`). Each skull
    blinks, waits (60 frames, then 100 to 160), and flies to a screen
    edge, where it waits; `w1d147` counts the skulls there. The dark's
    level (`wDollBoyHammerRange`, `$d148`, reused) follows that count a
    step at a time. Each step changes the background palettes (`Pals_55511`
    to `_555d1` get darker; `BlackOutBGPals` at 4; presentation) and
    Jamano's frameset (`Func_554bc`). `JamanoFunc` waits through its
    entrance (twice 255 frames), then on odd frames roams toward Wario
    (`Data_60c80`/`_60c20`, looping), turning to face him and bobbing
    between screen rows `$28` and `$98`. Past the intro, a skull at an
    edge that Wario attacks is knocked away (`Func_3317`/`_3326`). Off
    screen it is gone after its frames, and the spawner puts it out
    again. With no dark left, the spawner and the skulls are gone and
    Jamano is exposed. It bounces about until it reaches screen x `$58`,
    loses its hat (`ObjParams_JamanoHat`), and falls. The hat rises off
    the screen and ends the battle. Touching Jamano teleports Wario out
    (`ObjInteraction_Jamano`). Objects extractor 39. In the sweeps 43,200
    updates (the entrance, roaming in the dark, the spawner, and the
    skulls up to waiting at the edges) in 6 movies, all identical. No
    movie knocks a skull away, so that path, the exposed Jamano, its hat,
    and the hat platform are translated but unverified; unit tests cover
    the dark's steps, a knocked skull's end, and the hat ending the battle.
76. **Shoot and GK Tortoise (WL3-047).** `ShootFunc` taunts, then jumps
    across the pitch (`Data_603d0`/`_603e0`), turning toward Wario
    between jumps; its falling frameset follows the height of the floor
    under it. Catching Wario's ball (`OBJSTATE_SPECIAL_3`) it jumps with
    him (`DoPreKickingJumpYMovement`, `Data_54000`) and kicks him at the
    net (`wAutoMoveState` `$82`; the ball rises along `Data_54010`,
    `ApplyYOffsetOnKickedWarioBall`, through `MoveWarioDown`'s unsigned
    add). GK Tortoise ducks, and a ball in the net is Shoot's goal. Stepped
    on, Shoot is a ball (`.BallForm`, its own state table over the shared
    routines) that Wario can kick (`$34`/`$35`) into the net for his goal.
    GK Tortoise then throws the ball back out; at Wario's third goal Shoot
    is defeated, and GK Tortoise, after 180 frames, ends the battle. GK
    Tortoise also catches Shoot's ball and throws Wario's back, setting
    their positions from its own (`.GetShootPosPtr`). With no Shoot
    present, the search leaves its pointer in the last slot, and the
    port writes there too. `.ScoreGoal` at 3 goals already would use a
    stale `b`, so that path stays unported. Jumping out of the ball enters
    two framesets at their second pair (`Frameset_6a022 + 2`, `_6a03a +
    2`), extracted as their own; `Data_54000`/`_54010` come from bank
    `$15`. Objects extractor 40. In the sweeps 14,400 updates (Shoot's
    wait, taunt, and jumps; GK Tortoise on guard) in 6 movies, all
    identical. No movie plays the game itself, so the kicks, the ball
    form, the goals, and both defeats are translated but unverified; unit
    tests run the stepped-on ball, the catch of Wario's ball, Shoot's
    winning goal, Wario's goal, and GK Tortoise's throw back to the defeat.
77. **The variable cart (WL3-047).** `CartVariableFunc` (item 64 left it
    unported) asks `IsTreasureCollected` for the Truck Wheel (`$3d`: bit 5
    of `wTreasuresCollected + 7`, WRAM bank 2). That is the only treasure
    a level reads, so the oracle now traces just that byte
    (`wTreasuresCollected7`, `02:d007`). The port treats it as unknown
    (named as unported) in a trace without it, and the six movies that
    meet the cart were traced again. With the wheel the cart waits and
    rolls like `CartFunc` (its own framesets, `Frameset_691bf` once
    stopped); without it, it stays (`Frameset_691a7`, `CartStoppedFunc`).
    Every recorded movie starts without the wheel, so only that branch
    meets the oracle; a unit test runs the other.
78. **Wormwould's palm trees (WL3-047).** `PalmTreeSpawnerFunc` counts
    240 frames down and puts out a short palm tree at 120 left
    (`ObjParams_PalmTreeShort`), a medium one at 60, and a tall one at the
    end. Each tree (`PalmTreeFunc`) is a one-way platform that rises a
    pixel a frame for `OBJ_VAR_1` frames, then opens for `OBJ_VAR_2`
    frames; its palette is presentation. Objects extractor 41. No movie
    reaches them (none was named as unported either); a unit test runs
    them.
79. **Longer movies in the boss rooms (WL3-048).** 3600-tick movies in
    the 11 boss rooms (00r06, 28r0d, 30r0f, 38r1a, 40r09, 40r13, 48r1b,
    60r04, 60r0d, 90r0e, 90r17), with 16 scripts (wander and its seeds 2-9,
    the right and left attacks, right-jump, left-jump, right-crouch, and
    two with every power-up): 176 movies, 627,556 Wario, 1,473,388 object,
    and 631,546 interaction updates, all identical, nothing unported. They
    reach what no 1200-tick movie does: Shoot's ball form (3,298 updates in
    7 movies), Scowler swallowing Wario and closing its mouth (2,149) and
    its left ink (194), Yellow Belly's arrow hitting (120), a rolling rock
    to the right (138), and in one Wolfenboss movie a magic spiral's start,
    the Igaguri's fall and hatching, and the Kuri landing (376). The
    bosses' later phases and defeats, Muddee's battle, Jamano's knocked
    skulls, and the Shoot game's kicks and goals are still not reached:
    scripted input does not fight.
80. **The Moon and Mizuuo (WL3-049).** The night room starts (`wander`,
    408 movies) met two objects no other sweep had. `MoonFunc` is
    `SunFunc`'s code with its own framesets (`Frameset_68fd0`-`_69036`),
    40-frame turns instead of 35, and stars (`MoonStarFunc`,
    `ObjParams_MoonStarLeft`/`_Right`) instead of flames; the port shares
    one routine for both. `MizuuoFunc` walks $30 frames a pixel a frame,
    turns ($22 frames), then spits: about $19 frames, spitting $5d (its
    projectile at $24 left; a state cuts it short), and $19 more before it
    walks again. The projectile (`MizzouProjectileFunc`) flies 2 px a frame
    along `Data_60700`, then drops along `Data_60740`. A wall, a floor
    under the drop, or a state bursts it ($17 frames); water ends it at
    once. Objects extractor 42. 915 updates of the Moon and its star and
    1,423 of Mizuuo and its projectile, in 3 movies, all identical.
81. **The big leaves (WL3-049).** The later variants' room starts met
    them in level 0's room `$12`. `BigLeafSpawnerFunc`, once Wario is
    left of 22 px right of it and 20 frames have passed, puts out two
    leaves (`ObjParams_BigLeaf1`, `_3`), then one more (`_2`) 160 frames
    later, and again after 80. A leaf waits its frames (the first
    invisible), then drifts down as a one-way platform a pixel on odd
    frames, carrying Wario. A state `$0a` vanishes it, `$01`-`$09` end
    it, and later ones set it drifting away from his side a pixel a
    frame. In water it sinks away. Objects extractor 43. 19,320 updates in
    4 movies, all identical.
82. **The Big Octohon (WL3-049).** Later variants' levels `$52`-`$57`
    (rooms 3, `$c`, `$e`) and `$23`/`$27` (room `$1c`). `BigOctohonFunc`
    faces Wario and swims along the small Octohon's sway (`Data_4a5a9`,
    walls only counting the steps), turning at the sway's `$ee`-th step.
    With Wario within 20 rows and up to 64 px ahead it charges after `$24`
    frames, harmful (`OBJ_INTERACTION_49`: touched on the side it faces,
    Wario is launched, wario movement item 43). It goes 2 px a frame until
    a wall bonks it (`$43` frames, knocked back along `Data_60d50`,
    `OBJ_INTERACTION_06`). A state `$0b`/`$0c` bonks it too; another hits
    it (`$3c` frames, still charging). After a wall's probe the bonk's
    `ld [hl], a` writes where `ProcessBlock` left `hl`: for a solid block
    its handler's ROM address, which only selects a cartridge RAM bank.
    The port assumes that for every handler (provisional). All updates of
    the 14 movies that meet it are identical.
83. **`Func_ba42` spawns the cell's new object** (WL3-048, the owner's
    `game-006`, Doll Boy defeated). The port's `set_cur_object_map_nibble`
    wrote the cell's new object kind and bit 7, as `Func_ba42` begins. The
    original then places the object at the cell (`Func_d3e`: y = row ×
    16 + 16, x = column × 16 + 8) and calls `SpawnObject` with the new
    kind, so it spawns at once into the first free slot and, in a later
    slot, runs in the same pass. Doll Boy's defeat (kind 5, the hammer
    platform spawner) showed it. Every user of `Func_ba42` (the bosses'
    defeats, Jamano's hat, Shoot, GK Tortoise, the skull spawner) does
    the same now. All 34 step sweeps are unchanged.
84. **The unlit torch's interaction** (WL3-048, the owner's `game-017`).
    `ObjInteraction_UnlitTorch` (`$2e`): only Hot Wario lights the torch
    (`OBJACTION_0E`, which the torch already handled). `game-017` matches in
    every update and runs to the end.
85. **The Temple: the hidden figure's fight** (WL3-048,
    `map-temple-fight-invented`, labelled invented: the reveal's movie
    with A at tick 7,600 to close its last text). The fight is level `$c8`
    (`THE_TEMPLE`, one room; its collision extracts like any level's).
    With no input after the reveal the left hand's clap catches Wario
    (interaction `$50`: dragged down, state `$32` for 163 updates), the
    game is over, and after about 440 frames the game goes to
    `ST_EPILOGUE` (6) for 132 frames, then to the map and its save.
    Ported:
    - `LoadHiddenFigureData` (object group `$f0`): only `HiddenFigureData`
      from `wObjDataPtr01` (its list ends at `NULL`, `$ffff`); no
      graphics or palettes (the objects extractor, version 45).
    - `UpdateObjects_Temple` and `UpdateObject_Temple`: no floor transition
      looked at, the functions in bank `$13` whatever the ID, and the
      fight's scroll put back after each object.
    - `hidden_figure.asm` (`HiddenFigureFunctions`, translated by a
      delegated agent and checked here): the figure (`$3a`), its face
      (`$3b`), and its hands (`$3c`, `$3d`), 28 update functions; their
      variables `w1d14b` to `w1d162` (the object WRAM model and the
      tracer's range now reach `$d162`); their object params (19:4dc7,
      4ddc, 4df1) and the hands' paths in bank `$13` from `$4000` to
      `$485f` (extracted).
    - Interactions `$4f` (the hands: pushed out on the side they face,
      else a bounce), `$50` (the left hand's clap: dragged down), `$52`
      (from above a smash attack or a bounce, from the side it faces a
      sting).
    - `UpdateState_DraggedDown`'s game over, `check_end_screen`'s game
      over and epilogue (`wTransitionParam`, `wGameModeFlags`), and
      `ST_EPILOGUE` (a fade every fourth loop, then the map). The level's
      end also clears the water current and `wSwimmingDirectionInput`, and
      a Time Attack clear goes to `SST_CLEAR_TIME_ATTACK`, which the port
      had left out.
    `make wario-parity`: Wario 442 of 442 updates, objects 1,768 of 1,768
    slot updates (12 function addresses), interactions 442 of 442 (32
    with an effect), camera 442 of 442, the level start and its objects
    identical; `MODE=run` from power-on through the map, 67 loops into the
    level, 442 whole frames, and the map and the save after it to the end.
    That run seeds, when first seen, the map's `wTempPals` (128 bytes), its
    virtual OAM, and `wTempBank`, and 6 bytes of the save screen: the
    fight's palettes (`Func_4cfe0`, `Func_4d005`, `LoadHiddenFigureGfx`)
    are presentation and not simulated, so nothing native writes them.
    Two more movies, from inputs a planner found on emulator save states
    (scratch scripts: random walk, jump, and smash timings, then random
    button sequences, each kept once it reaches its goal):
    `map-temple-knock-invented` smashes the right hand mid-swipe (its
    interaction `$52` from above), which is knocked loose, falls, hops,
    tumbles, recovers, and floats home; the left hand slams. A knocked
    hand is heavy (`$80`): only the Super Grab Gloves (power-up level 9)
    pick it up, and the music-box save has level 2, so `oracle_save
    --invent-power-ups` stores one with every power-up treasure, level 9,
    and the treasure count recounted (`1127a6d6…`, labelled invented).
    `map-temple-hit-invented` from it knocks the hand, picks it up, and
    throws it at the face, which takes a hit (`w1d15a` 4 to 3; its hurt
    function). Both match in every Wario, object, interaction, and camera
    update (592 and 611 updates, 2,368 and 2,444 slot updates) with no
    change to the port. The planner, repeated (a swipe to wait for, a
    knock, a grab, a hit; only a swipe can be knocked, and after a knock
    the other hand slams), wins the fight: `map-temple-win-invented` hits
    the face four times; the figure and its face are defeated, Wario's
    fence shake slide (`SetState_FenceShakeSliding`, state `$4d`, ported
    with it: `UpdateLevel` sets it at `wAutoMoveState` 2) plays, and the
    level ends with `LVLEND_EPILOGUE` (tick 10,234). All 2,545 Wario
    updates, 10,180 slot updates, 2,545 interactions (50 with an effect),
    and camera runs match; from power-on the run plays the title, the
    map, the reveal, the whole fight, `ST_EPILOGUE`, and the map's
    epilogue natively ([the map](overworld.md) item 15).
    Not reached: the left hand's swipe met as an attack, the figure's
    collapse as a separate function (13:4e01), and the right hand sinking. The asm's quirks the translation keeps
    (pinned in `test_hidden_figure.gd`): the right hand clears its
    substate where the left clears its state; a knocked hand going home
    only rises; the knocked hands' table ignores bit 7 of the state; only
    the left hand's clap catches Wario. The fight is drawn since
    2026-10-28, equal to the original at every compared frame of the ten
    movies ([the fight drawn](hidden-figure-drawing.md)).

## Interpretation

- The framework is common to all objects, so each further object is its own
  functions plus the shared state routines (`Func_62xxx`, `ObjState_*`) it
  uses. The Spearhead's shared states (falls, bumps, stuns, knock-backs,
  tumbles, hops) are now ported for every object that uses them.

## Hypotheses

- None open for the ported paths; see Unknowns.

## Unknowns

- The other interaction types, `HandleGrabbedObjectCollisions`, and
  particles are not ported, nor are the Flat Wario
  states a falling Omodon starts (item 37). Wario's enemy-bumping
  state (`$19`) is entered but not yet updated.
- Edge spawning past the map's last column (column 160 and up reads the
  page's other bytes in the original) is treated as no object.
- The Spearhead's shake wobble is ported but not yet met by a movie
  (asleep or awake).

## Tests

- `tests/test_objects.py`: frameset decoding (invented data).
- `game/tests/unit/test_objects.gd`: animation, the on-screen window and
  despawning, actions, the copy back, the musical coin, floor transitions,
  a Spearhead walking to a wall and falling onto a floor, and a sleeping
  Spearhead waking at 32 px and turning to Wario.
- `game/tests/unit/test_interactions.gd`: no overlap, a sting, a sting from
  behind, an attack, landing on top, the musical coin, coins and colour
  coins, a key and its pause, and an electric shock (and none while
  invincible).
- `game/tests/unit/test_level_objects.gd`: a torch's ember pairs, an
  ember's fall and burning out, a bird taking off, turning, and being hit
  twice, a chest opening and its treasure, a taken chest, a treasure's
  frameset, and Silky walking, winding up, and turning.
- `game/tests/unit/test_particles.gd`: slots in turn, an animation freeing
  its slot, `wCurParticleAnimEnded`, slide dust following Wario, the glow,
  and the treasure clear waiting on it; `tests/test_rom_integration.py`:
  the particle framesets and tables on their labels.
- `game/tests/unit/test_coins.gd`: a broken block's coin by its replayed
  `rDIV` roll and the cooldown, a read at the wrong site, the colour-coin
  block, and `CoinFunc`'s start, colour coins, turn, and blinking.
- `game/tests/unit/test_spawning.gd`: a spawned slot, an edge's spawns, and
  the room start's limits; `tests/test_objects.py`: the group tables.
- `game/tests/unit/test_object_sprites.gd`: entries, palettes, tile sources,
  and the draw order; `tests/test_wario_sprites.py`: the check's OAM
  prediction.
- `tests/test_rom_integration.py`: the framesets and the movement data's
  extent against the reference labels, and every `rDIV` hook after an
  `ldh a, [rDIV]` (48, as many as the source has).
