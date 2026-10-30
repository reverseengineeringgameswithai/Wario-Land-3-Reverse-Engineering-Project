---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, collision]
---
# Block handlers for the first room

**Question:** what does each block handler used by `ROOM_001` (Out of the
Woods, day 1, first room; block function table `$00`) do, and how should the
runtime classify it?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys/warioland3 @ `560fce6` (byte-identical build),
`src/engine/level/block_functions.asm` and `collisions.asm`; symbols from the
local reference build. Task: WL3-011. The tables are described in the
[first investigation](first-investigation.md), and the first room in
[level headers](level-headers.md).

## Verified observations

1. **Probes.** Every call to `ProcessBlock` sets `wCollisionPoints` to one
   bit that names the probe. For Wario, the callers are:

   | Probe | Wrapper | Caller and position |
   | --- | --- | --- |
   | `COLLISION_DOWN` | `Func_19b51` | `Func_198c7` from `CheckCentreCollision`: feet, centre (standing) |
   | `COLLISION_UNK2` | `Func_19b8b` | `CheckCentreCollision`: feet, left and right corners (box edge − 3) |
   | `COLLISION_UNK1` | `Func_19b7b` | `CheckAirborneCollision`: feet, centre (falling) |
   | `COLLISION_UNK6` | `Func_19bfb` | `CheckAirborneCollision`: feet, corners (falling) |
   | `COLLISION_UNK5` | `Func_19beb` | `Func_19942`: 2 px above the box, centre (ceiling) |
   | `COLLISION_UNK3` | `Func_19b9b` | `CheckUpCollision`: 2 px above the box, corners |
   | `COLLISION_UNK4` | `Func_19bc3` | `CheckBottomRightCollision`/`CheckBottomLeftCollision`: side wall |
   | `COLLISION_UNK7` | `Func_19c0b` | `Func_19b3a`: presence probes (centre, top) after clearing water, ladder, transition, sand, fence, and air-current state |

   `wBlockFuncWarioFlag` is TRUE while `UpdateLevel` runs
   `UpdateWarioStates` (`src/engine/level/update_level.asm`) and inside
   `Func_19706`, `Func_19713`, and `Func_19720`, which some objects call
   (cart, zip line, Muddee, `update_objects.asm`). It is FALSE during the
   object update, when objects probe through the same wrappers
   (`src/home/object_mechanics.asm`).
2. **Return value.** Handlers return `a`: `$00` for free, `$01` for solid,
   and `$10` for slopes (`Func_18064`). `CheckCentreCollision`,
   `CheckUpCollision`, and `CheckAirborneCollision` return on any non-zero
   `a`. The wall checks mask `a` with `$0f`, so a slope's `$10` counts as no
   wall there and branches to `Func_19832`.
3. **Breaking.** Callers set `wBlockFuncBreakFlag` before a probe:
   `CheckFrontCollision` (walls), `Func_19942` and `CheckUpCollision`
   (ceiling, unless Wario is `TRANSFORMATION_PUFFY_WARIO`), and
   `CheckAirborneCollision` (landing, only while `wIsSmashAttacking`). Every
   exit through `BlockFunc_Free`, `BlockFunc_Solid`, `Func_18064`, or
   `Func_1808c` clears the flag and `wBlockFuncSpecialCollision`, so a request
   lasts one probe.
4. **Table `$00` uses 31 distinct handlers.** Each was read. The mapping
   rows in `tools/wl3pc/data/block_handler_materials.v1.json` cite the branch
   conditions; in summary:

   | Handlers | Behaviour |
   | --- | --- |
   | `BlockFunc_Free` `06:4020` | Free for every probe. |
   | `BlockFunc_Solid` `06:4032` | `hYPosLo &= $f0`, `a = $01`. A Wario wall probe while `wWarioSlopeInteraction` is set returns `$00` instead. |
   | `BlockFunc_Floor` `06:4208` | Sets `wc1ca`. Solid to DOWN and UNK2; free to UNK3, UNK4, UNK5, UNK7; solid to UNK1 and UNK6 only when `hYPosLo & $0f < 5`. Free to Wario in `WST_ZOMBIE_LANDING` or `WST_ZOMBIE_SLIPPING_THROUGH_FLOOR`. |
   | `BlockFunc_RightSlope` `06:40d9`, `BlockFunc_LeftSlope` `06:4163` | DOWN and UNK1 only. UNK1 is free above the diagonal (right: `x + y < $10`; left: `x >= y`, with `x` and `y` the low nibbles). Then `hYPosLo` becomes the block top plus `$10 − x` (right) or `x + 2` (left), the slope interaction is set for Wario or the object, and `a = $10`. |
   | `BlockFunc_1809f` `06:409f`, `BlockFunc_18129` `06:4129` | DOWN only: move the probe one block down (`+$10`), then right or left slope collision. |
   | `BlockFunc_180b5` `06:40b5`, `BlockFunc_1813f` `06:413f` | Solid to Wario in `WST_ATTACKING_AIRBORNE`. DOWN and UNK1: move the probe one block up (`−$10`), then right or left slope collision. Otherwise free. |
   | `BlockFunc_Ladder` `06:42c3` | Free. Wario's UNK7 probe sets `wLadderInteraction = LADDER_COLLISION`. |
   | `BlockFunc_LadderTop` `06:42e5` | Wario's UNK7 probe sets `LADDER_UNDERNEATH` and is free; every other probe acts as `BlockFunc_Floor`. |
   | `BlockFunc_182fe` `06:42fe` | Free. Wario's UNK7 probe sets `LADDER_COLLISION` and `wRoomTransitionParam = $45` (`ROOMTRANSITION_5 \| ROOMTRANSITIONF_RELOAD_OBJECTS`). |
   | `BlockFunc_187b0` `06:47b0` | Free. Wario's UNK7 probe sets `wRoomTransitionParam = $44` (`ROOMTRANSITION_4 \| ROOMTRANSITIONF_RELOAD_OBJECTS`). |
   | `BlockFunc_Door` `06:45cb` | Free. Wario's UNK7 probe with Up pressed in `WST_IDLING`, `WST_SLIPPING`, or `WST_GRAB_IDLING` sets `wRoomTransitionParam = $e2` and runs `EnterDoor`, which centres Wario on the block (`x & $f0 + 8`) and starts `WST_ENTERING_DOOR`. |
   | `BlockFunc_TreasureDoor` `06:477e` | Free. With Up pressed, no transformation, and the same three states, it clears `wGrabState` and sets `wLevelEndScreen = LVLEND_NO_TREASURE`. It does **not** read `wCollisionPoints`, so any Wario probe can trigger it. |
   | `BlockFunc_CrackedBlock_78`–`_7e` (7 handlers) | Robo-mouse special collisions break or pass the block. Otherwise solid unless the break flag is set and one of these holds: a wall probe while attacking or rolling; a ceiling probe with `HEAD_SMASH_HELMET` or better while jumping or swimming; a landing probe. Breaking writes `(block & $80) \| $78…$7e` into the block map, calls `Func_e31` and `BreakBlock`, and then returns free if rolling or `TRANSFORMATION_FAT_WARIO`. When smash-attacking it is free with `SUPER_JUMP_SLAM_OVERALLS` or better, otherwise free with `GARLIC` or better; in every other case it is solid. |
   | `BlockFunc_CrackedBlockWithColourCoin_78`, `_7e` | As cracked blocks, but without the robo-mouse checks, and they call `BreakBlockWithColourCoin`. |
   | `BlockFunc_NonCrackedBlock_78`, `_7b`–`_7e` (5 handlers) | Robo-mouse checks as cracked blocks. Breaking needs the break flag and `GARLIC` or better (Fat Wario: landing probes only). Conditions: a wall probe while attacking or rolling, a ceiling probe while jumping or swimming, or a landing probe with `SUPER_JUMP_SLAM_OVERALLS`. Solid afterwards unless rolling. |
   | `BlockFunc_EnemyBlock_79` `06:53ff` | Solid; breaks only when `wBlockFuncSpecialCollision` is `COLLISION_THROWN_OBJ`. |
   | `BlockFunc_BonfireBlock_7e` `06:5463` | Solid; breaks for Wario as `TRANSFORMATION_HOT_WARIO` with `wTransformationProgress >= 2`. |

   Power-up levels, in order: `NO_POWER_UP` 0, `LEAD_OVERALLS` 1,
   `SWIMMING_FLIPPERS` 2, `HEAD_SMASH_HELMET` 3, `GRAB_GLOVE` 4, `GARLIC` 5,
   `SUPER_JUMP_SLAM_OVERALLS` 6, and up (`src/constants/wario_constants.asm`).
5. **Applied to the ROM** (`make extract`, `tools/wl3pc/extract/block_materials.py`):
   - All 31 mapping rows name handlers present in the decoded tables, and
     each row's `symbol` equals the reference `.sym` label at its address.
   - Table `$00` has no `unknown` block. Tables `$01` and `$2c` are also
     fully covered by the same 31 handlers.
   - 9599 of the 11392 blocks in the 89 tables are mapped. The 1793
     `unknown` blocks use the 107 handlers not yet read.
   - The output `local/content/wl3-original/block_materials.json` is
     deterministic, SHA-256 `fe706b93…c82e`, and valid against
     `schemas/block-materials.v1.schema.json`.
6. **Handlers the coverage sweep met (WL3-045).** Ported by translation
   in `WarioBlocks.run_handler` (beside the water, sand, and breakable
   handlers): `BlockFunc_SlipperySolid` and `_SlipperyFloor` (solid or a
   floor; `wIsOnSlipperyGround` under Wario's feet, which
   `IsOnSlipperyGround` reads), `BlockFunc_CloudPlatform1` (a floor while
   the room's palette cycle index is below 4 or at 7) and `2` (from index
   3), `BlockFunc_188ba` (solid to objects, free to Wario),
   `BlockFunc_Fence` (`wIsNearFence` for the presence probe),
   `BlockFunc_LightSource` (free; turning Zombie or Vampire Wario back is
   named as unported), and `BlockFunc_MinigameDoor` (a door into the golf
   minigame's room). With them, every Wario update of levels 88, 98, a0,
   and c0 in the sweep is compared, all identical, and level 98's objects
   are compared too (1891 slot updates). Then `BlockFunc_WaterSpike`
   (water that stings Wario, `SetState_WaterStung`, unless invincible or
   already stung) and `BlockFunc_UnderwaterDoor` (deep water for the
   presence probe of an untransformed or invisible Wario, a room
   transition with Up, the block itself free), met by Haridama's probes
   in level 40. Last, `BlockFunc_SmallGap` (free to objects and to Flat
   Wario, solid to Wario otherwise), met by an Omodon's fall in level a8,
   and beside it `BlockFunc_189f1` (free to objects, a floor to Wario),
   which the sweep does not meet (a unit test only). The `wander` movies
   met `BlockFunc_Fire` (level 58): free to objects and to Wario's ground
   probes, otherwise it sets him on fire as `ObjInteraction_Fire` does,
   and that path returns through `hCallFunc`, whose `pop af` leaves the
   caller's ROM bank (`$06`) in `a`, with `BlockFunc_Free`'s clearing
   skipped; all 176 updates there match with it. The bonfire blocks
   `_78`-`_7d` share `BonfireBlockCollision` with `_7e`, ported before.
7. **Multi-block breakables (WL3-044).** 47 handlers in five kinds, each
   in four directions: snowballs (`Func_18aa8`-`_18b71`, Snowman Wario
   rolled into one) and big snowballs (`Func_18bb5`-`_18c7e`), cracked
   (`Func_18e2c`, `_18ec0`, `_18f7d`, `_19011`, as `CrackedBlockCollision`),
   non-cracked (`Func_190fe`, `_191b3`, `_19291`, `_19346`, as
   `NonCrackedBlockCollision`; only `Func_190fe`'s needs the overalls for
   a roll), and string blocks (`Func_19522`, `_19560`, `_1959b`,
   `YarnBlockCollision`, a ball of string). The four directions of each
   kind were checked to be the same code but for the direction, with
   each local label compared by its position. Broken, a block records
   its position (`wcedb`, `wcedc`) and sets `wMultiBlockParam` to the
   direction it passes the break on (1 right, 2 left, 3 a row up, 4 a
   row down; the disassembly's up/down labels are the other way round
   for the rows); the cracked and non-cracked ones also set
   `wIsFloorTransition`. `UpdateLevel.check_end_screen` then sends the
   next frame to `SST_LEVEL_MULTI_BLOCK`: `ProcessMultiBlock` breaks the
   chain in one frame, each multi-block it reaches breaking and passing
   on (bit 4 set), until a block that is not one, clears both variables,
   restores the sub-state, and only updates the particles and draws:
   Wario and the objects stand still that frame. `wMultiBlockParam`
   (`$ceda`) is now traced: in step mode the port had kept a direction
   from its own break into later updates, where the original's next
   frame had cleared it, which made 52 of level b8's updates differ until
   the trace carried it. Level b8's and 58's `wander` movies, re-traced,
   match every Wario update and run whole frames to the end, the chain's
   frames included.
8. **Handlers the room starts met (WL3-047).** `DoughnutBlockCollision`
   (`BlockFunc_DoughnutBlock_78`-`7b`): solid; Fat Wario's feet (UNK1,
   UNK6) break it (`BreakBlock`) and it stays solid that probe.
   `BlockFunc_18262`: free to Wario; to objects a floor solid only in
   its top 5 px (solid below and for UNK2, free for UNK3-5 and 7; it sets
   `wc1ca`). `BlockFunc_NonSolidSpike`: free; it turns and stings Wario
   unless invincible, stung, or passing through (`wca94` 2):
   `SetState_Stung`, or with `wca94` 1 `Func_206eb` (the transformation
   cleared first). `BlockFunc_18727`: the underwater door without
   reloading objects. `BlockFunc_187de`: water, Wario's presence is room
   transition 4. `BlockFunc_WalkthroughPipe`: free; Invisible Wario is
   himself again. `BlockFunc_18868`: free, but solid to Vampire Wario,
   whose presence in it puts him beside it. `BlockFunc_Switch`: solid;
   Wario's head (UNK3, UNK5) flips it (`$08`), keeps it as it was in
   `wSwitchState`, toggles `wSwitchStateUpdated`, and shakes the ground
   (16 frames, if still); the next room start (`UpdateSwitchableBlocks`)
   turns every block `$60`-`$67` of the map's 48 rows into its
   `$68`-`$6f` twin, or back when `wSwitchState` is `$68` (both traced
   now). The air current is Fan Wario's (wario movement item 40). `wca94` is now traced:
   it decides between the two stings, and the Wario-only step had kept a
   stale value.
   `BlockFunc_182dc` (met by objects): solid to objects; to Wario, a
   ladder's top (`Func_182ec`: his presence probe finds the ladder
   underneath, otherwise a floor).
   **Past the map's edge** (WL3-047): `GetBlockPtr` keeps the column's
   byte, and each row is a 256-byte SRAM page: the block map (`$00`-`$9f`),
   16 bytes the decompressors never write (`$a0`-`$af`), and the object map
   (`$b0`-`$ff`). A probe left of x 0 (column `$ff`) or past the right edge
   reads on in the page; the port now reads the object map there as the
   original does (8 room-start runs had stopped at it). The 16 unwritten
   bytes hold whatever SRAM held. Traces now record them at the start
   (`block_gap_rows`; nothing is known to write them), and the port reads
   them from there. In a trace without them, a probe there is still named
   as unported. The one run that probes them (level 00's room `$17`) was
   traced again: all 64 rows hold zeros, and it runs to the end.
   **Above the map, and below the traced rows** (WL3-048): `GetBlockPtr`
   adds `$a0` to the row in a byte, so a row above 0 (255) is page `$9f`,
   VRAM's second tile map, and rows 64-95 are SRAM bank 3, past that ROM
   or VRAM. The traces now record such reads (emulator oracle item 18), and
   the port replays them in a parity run (`_block_address`,
   `replay_outside_read`); outside one it still names them as unported.
9. **Handlers the left-facing movies met (WL3-049).** The 408 day-1 room
   starts with `left-jump` met one handler no right-facing movie had:
   `BlockFunc_SolidSpike` (`06:439c`), the non-solid spike's sting (the
   same conditions, Wario turned round) on a solid block (4 Wario and 116
   object updates there).

## Interpretation

- A single "material" per block is a lossy summary. The original's answer
  depends on the probe, on whether the prober is Wario, and on Wario's state,
  power-up, and transformation. The mapping's `material` gives the default
  collision shape, and `flags` name the extra behaviour. A faithful runtime
  will need per-probe handler logic, at least for slopes, platforms, and
  breakables.
- In table `$00`, the slope helpers sit 8 block IDs above and below their
  slopes (`$1b`/`$23`/`$2b` and `$1c`/`$24`/`$2c`), which fits the "upper"
  and "lower" reading of the probe shifts if blocksets are laid out eight
  per row. The layout is not verified.

## Hypotheses

- The two slopes are not mirror images. The right surface is
  `top + $10 − x` (rows 16 down to 1), whose mirror would be `top + x + 1`,
  but the left surface is `top + x + 2` (rows 2 to 17), one pixel lower.
  Whether this is visible in play is unknown. An oracle capture of Wario
  walking each slope (WL3-014) would show it.
- `wc1ca`, which `BlockFunc_Floor` sets and `Func_19a77` clears, marks
  "probed a platform this frame". Its readers are not yet traced.

## Unknowns

- The 107 handlers not used by table `$00`.
- What `Func_e31` does beyond queueing a redraw. (`Func_19423`, an object
  breaking a block, is ported: [objects](objects.md), item 43; the
  robo-mouse's cracked and non-cracked block paths use it too, but the
  robo-mouse itself is not ported.)
- What room transitions 4 and 5 do (`wRoomTransitionParam` consumers).

## Runtime contract

The runtime loader accepts only `empty`, `solid`, and `platform`. Every other
material, including `unknown`, is rejected when a room uses it. The shared
fixture `tests/fixtures/content/invalid-packs/unknown-material` checks this
in both the Python validator and the Godot loader. Slopes, ladders, doors,
and breakables therefore fail explicitly until they are implemented.

## Tests

- Synthetic: `tests/test_block_materials.py` checks that the tracked mapping
  passes its schema and rules. It also checks that broken rows (undefined
  material or flag, duplicate, a reserved `unknown`, missing or stray
  `room_transition` or `replacement_block`, no evidence, malformed ID) are
  rejected, that unmapped handlers become `unknown` and never `empty`, that
  unused rows are reported, and covers exploratory extraction, determinism,
  read-only output, and schema validity.
- Real ROM (optional, `make test-rom`): table `$00` is fully mapped, no row
  is missing from the ROM, and every row's symbol matches.

## Next experiment

WL3-013 needs the level block map for Out of the Woods to place these
materials. Decode `LevelBlockAndObjectMaps` (`src/data/levels/level_maps.asm`)
and `LoadLevelBlockMapAndObjects` next (WL3-025).
