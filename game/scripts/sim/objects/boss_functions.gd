class_name BossFunctions
extends DeviceFunctions
## The bosses, by translation from src/engine/level/objects/*.asm: Wormwould and its rolling rocks;
## Wolfenboss with its magic spirals, the Igaguri, and the Kuri; Doll Boy with its barrels, hammers,
## and hammer platforms; Yellow Belly with its head, arrows, pump, and platform; Anonster with its
## silk, silk platforms, and waves; Scowler with its tentacles, ink, and floating rings; Muddee
## with its stingers and turtles; Jamano with its skulls, hat, and the hat platform; Shoot, GK
## Tortoise, and its platform; and Wormwould's palm trees. Paths into code not ported are named
## in `unported`; palettes are presentation and not simulated.
## Research note: docs/02-research/objects.md.

const BOSS_NONE: int = 0  # wBossState
const BOSS_REGULAR: int = 2
const BOSS_DEFEATED: int = 3
const WORMWOULD_FUNC: int = 0x15_4020  # WormwouldFunc
const WORMWOULD_INIT: int = 0x15_4044  # .Init
const WORMWOULD_DO_NOTHING: int = 0x15_4103  # .DoNothing
const WORMWOULD_MAIN: int = 0x15_41B5  # .Main
const WORMWOULD_UNDERGROUND: int = 0x15_4335  # .Underground
const WORMWOULD_DEFEATED_RAISE: int = 0x15_435F
const WORMWOULD_DEFEATED_WAIT: int = 0x15_4387
const WORMWOULD_DEFEATED_FALL: int = 0x15_43D4
const ROLLING_ROCK_FUNC_LEFT: int = 0x15_43E9  # RollingRockFunc_Left
const ROLLING_ROCK_MOVE_LEFT: int = 0x15_43FC  # .MoveLeft
const ROLLING_ROCK_FUNC_RIGHT: int = 0x15_4401
const ROLLING_ROCK_MOVE_RIGHT: int = 0x15_4414
const ROLLING_ROCK_HIT: int = 0x15_4441  # RollingRockFunc.Hit
const PALM_TREE_SPAWNER_FUNC: int = 0x15_4456  # PalmTreeSpawnerFunc
const PALM_TREE_SPAWNER_SPAWN_TREES: int = 0x15_446C  # .SpawnTrees
const PALM_TREE_SPAWNER_WAIT: int = 0x15_4497  # .Wait
const PALM_TREE_FUNC: int = 0x15_44A2  # PalmTreeFunc
const PALM_TREE_UPDATE: int = 0x15_44B8  # .Update
const OBJ_PARAMS_PALM_TREE_SHORT: int = 0x4C23  # bank $19
const OBJ_PARAMS_PALM_TREE_MEDIUM: int = 0x4C38
const OBJ_PARAMS_PALM_TREE_TALL: int = 0x4C4D
const WORMWOULD_NUM_HITS: int = 3
const WORMWOULD_IDLE_DURATION: int = 43  # between rocks when above ground
const WORMWOULD_SHOOT_ROCK_DURATION: int = 69
const WORMWOULD_SHOOT_ROCK_DELAY: int = 48  # from the shot's start to the rock
const WORMWOULD_BURROW_DELAY: int = 26
const WORMWOULD_UNDERGROUND_DURATION: int = 30
const WORMWOULD_HURT_DURATION: int = 50
const OBJ_INTERACTION_WORMWOULD: int = 0x34
const WOLFENBOSS_FUNC: int = 0x15_5E4E  # WolfenbossFunc
const WOLFENBOSS_WHISP_WAITING: int = 0x15_5E8D
const WOLFENBOSS_WHISP_RISING: int = 0x15_5EC4
const WOLFENBOSS_SMOKE_ENTRANCE: int = 0x15_5EEA
const WOLFENBOSS_EMERGE_FROM_SMOKE: int = 0x15_5F20
const WOLFENBOSS_START_WAIT: int = 0x15_5F41
const WOLFENBOSS_SMOKE_EXIT: int = 0x15_5F5F
const WOLFENBOSS_DISAPPEAR: int = 0x15_5F6E
const WOLFENBOSS_MAIN: int = 0x15_5FB3
const WOLFENBOSS_DEFEAT_FALL: int = 0x15_61A9
const MAGIC_SPIRAL_FUNC: int = 0x15_6201  # MagicSpiralFunc
const MAGIC_SPIRAL_GROW: int = 0x15_6216
const MAGIC_SPIRAL_MOVE: int = 0x15_6241
const MAGIC_SPIRAL_DISAPPEAR: int = 0x15_62B9
const IGAGURI_FUNC: int = 0x15_633F  # IgaguriFunc
const IGAGURI_FALL: int = 0x15_63A2
const IGAGURI_BOUNCE: int = 0x15_6430
const IGAGURI_HATCH: int = 0x15_6488
const KURI_FUNC: int = 0x15_64EA  # KuriFunc
const KURI_LANDED: int = 0x15_653C
const KURI_LAUNCHED: int = 0x15_65CA
const WOLFENBOSS_NUM_HITS: int = 3
const WOLFENBOSS_PLATFORM: int = 0x5A  # its ID
# The battle's variables in the object WRAM ($d146-$d149).
const W_WOLFENBOSS_NEXT_ATTACK: int = 0x146  # 0 a spiral, 1 an Igaguri
const W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE: int = 0x147
const W_WOLFENBOSS_REMAINING_HITS: int = 0x148
const W_WOLFENBOSS_CONSECUTIVE_SPIRALS: int = 0x149
const OBJ_PARAMS_MAGIC_SPIRAL_LEFT: int = 0x4D73  # bank $19
const OBJ_PARAMS_MAGIC_SPIRAL_RIGHT: int = 0x4D88
const OBJ_PARAMS_IGAGURI_LEFT: int = 0x4D9D
const OBJ_PARAMS_IGAGURI_RIGHT: int = 0x4DB2
const OBJ_PARAMS_KURI: int = 0x4F9D
const DATA_60DA0: int = 0x4DA0  # its defeated fall
const DATA_60D80: int = 0x4D80  # an Igaguri thrown up
const DATA_60E00: int = 0x4E00  # its bounce
const DATA_60D60: int = 0x4D60  # a Kuri's drop
const FRAMESET_69DCB: int = 0x5DCB
const FRAMESET_69DD5: int = 0x5DD5  # turning right
const FRAMESET_69DDE: int = 0x5DDE  # turning left
const FRAMESET_69DE7: int = 0x5DE7  # moving right
const FRAMESET_69DEC: int = 0x5DEC  # moving left
const FRAMESET_69DF1: int = 0x5DF1  # attacking left
const FRAMESET_69DF6: int = 0x5DF6  # attacking right
const FRAMESET_69DFB: int = 0x5DFB  # after an attack, left
const FRAMESET_69E00: int = 0x5E00
const FRAMESET_69E05: int = 0x5E05  # defeated
const FRAMESET_69E0E: int = 0x5E0E  # smoke, left
const FRAMESET_69E1F: int = 0x5E1F  # right
const FRAMESET_69E39: int = 0x5E39  # a spiral growing
const FRAMESET_69E42: int = 0x5E42
const FRAMESET_69E4B: int = 0x5E4B  # an Igaguri
const FRAMESET_69E59: int = 0x5E59  # hatching
const FRAMESET_69E60: int = 0x5E60  # a Kuri launched
const FRAMESET_69E80: int = 0x5E80
const FRAMESET_69E85: int = 0x5E85  # Wolfenboss hurt, left
const FRAMESET_69E8E: int = 0x5E8E
const FRAMESET_69E97: int = 0x5E97  # the whisp
const FRAMESET_69EA0: int = 0x5EA0  # rising
const FRAMESET_69EA9: int = 0x5EA9  # smoke
const FRAMESET_69EB2: int = 0x5EB2  # a spiral vanishing
const DOLL_BOY_FUNC: int = 0x14_4AC4  # DollBoyFunc
const DOLL_BOY_INIT: int = 0x14_4AF8
const DOLL_BOY_BARREL_PHASE: int = 0x14_4B29
const DOLL_BOY_INIT_WALKING_PHASE: int = 0x14_4C6F
const DOLL_BOY_WALKING_PHASE: int = 0x14_4D88
const DOLL_BOY_HIT_WARIO: int = 0x14_4F49
const DOLL_BOY_WAIT_THEN_DO_NOTHING: int = 0x14_4F8E
const DOLL_BOY_DO_NOTHING: int = 0x14_4FAD
const DOLL_BOY_DEFEATED: int = 0x14_4FB3
const DOLL_BOY_BARREL_1_FUNC: int = 0x14_5006  # DollBoyBarrel1Func (the top barrel)
const DOLL_BOY_BARREL_2_FUNC: int = 0x14_500A
const DOLL_BOY_BARREL_3_FUNC: int = 0x14_500E
const DOLL_BOY_BARREL_START_DELAY: int = 0x14_503C  # DollBoyBarrelFunc.StartDelay
const DOLL_BOY_BARREL_MAIN: int = 0x14_5050
const DOLL_BOY_HAMMER_FUNC: int = 0x14_51C7  # DollBoyHammerFunc
const DOLL_BOY_HAMMER_INIT: int = 0x14_51D5
const DOLL_BOY_HAMMER_UPDATE: int = 0x14_51F1
const DOLL_BOY_HAMMER_HIT_LEFT: int = 0x14_5259
const DOLL_BOY_HAMMER_HIT_RIGHT: int = 0x14_525E
const HAMMER_PLATFORM_SPAWNER_FUNC: int = 0x14_526C  # HammerPlatformSpawnerFunc
const HAMMER_PLATFORM_SPAWNER_SPAWN: int = 0x14_5282
const HAMMER_PLATFORM_SPAWNER_DO_NOTHING: int = 0x14_5296
const HAMMER_PLATFORM_FUNC: int = 0x14_52A1  # HammerPlatformFunc
const HAMMER_PLATFORM_MOVE_DOWN: int = 0x14_52B4
const HAMMER_PLATFORM_MOVE_UP: int = 0x14_52E9
const DIV_DOLL_BOY: int = 0x14_4C48  # .not_bouncy's rDIV read
const DIV_DOLL_BOY_BARREL: int = 0x14_50F3  # .set_flashing's
const DOLL_BOY_BARREL1: int = 0x41  # the barrels' IDs
const DOLL_BOY_BARREL2: int = 0x42
# wDollBoyActiveBarrels and wDollBoyRemainingParts bits
const DOLLBOY_BARREL1: int = 1 << 0  # the top barrel
const DOLLBOY_BARREL2: int = 1 << 1
const DOLLBOY_BARREL3: int = 1 << 2
const DOLLBOY_DOLL: int = 1 << 3
const HAMMER_LONG: int = 4
const DOLLBOY_THROW_HAMMER_ODDS: int = 250  # rDIV at least this throws a hammer
# Doll Boy's battle in the object WRAM ($d141, $d142, $d146-$d148).
const W_DOLL_BOY_NO_FLASHING_BARREL: int = 0x141
const W_DOLL_BOY_REMAINING_PARTS: int = 0x142
const W_DOLL_BOY_ACTIVE_BARRELS: int = 0x146
const W_DOLL_BOY_FALL_IMMEDIATELY_MIDDLE_BARREL: int = 0x147
const W_DOLL_BOY_HAMMER_RANGE: int = 0x148
const OBJ_PARAMS_DOLL_BOY_HAMMER: int = 0x4BA5  # bank $19
const OBJ_PARAMS_DOLL_BOY_HAMMER_STARS_LEFT: int = 0x4E30
const OBJ_PARAMS_DOLL_BOY_HAMMER_STARS_RIGHT: int = 0x4E45
const OBJ_PARAMS_STARS_CENTRE: int = 0x4FB0
const OBJ_PARAMS_HAMMER_PLATFORM: int = 0x4BBA
const DATA_60860: int = 0x4860  # a hammer's arc (bank $18)
const DATA_60880: int = 0x4880  # falling a barrel's height
const DATA_60890: int = 0x4890  # a jump to the platform below
const DATA_608A0: int = 0x48A0  # above
const DATA_60AE0: int = 0x4AE0  # a hammer's ranges: short
const DATA_60B00: int = 0x4B00
const DATA_60B30: int = 0x4B30
const DATA_60B60: int = 0x4B60  # long
const DATA_60B80: int = 0x4B80  # falling after one barrel
const DATA_60BA0: int = 0x4BA0  # after two
const DATA_60BD0: int = 0x4BD0  # defeated
const DATA_60C00: int = 0x4C00  # turning's hop
const FRAMESET_69632: int = 0x5632
const FRAMESET_6963B: int = 0x563B  # throwing
const FRAMESET_69646: int = 0x5646  # landing
const FRAMESET_6964D: int = 0x564D  # walking right
const FRAMESET_69656: int = 0x5656  # walking left
const FRAMESET_6965F: int = 0x565F  # turning left
const FRAMESET_6966A: int = 0x566A  # turning right
const FRAMESET_69675: int = 0x5675  # stunned
const FRAMESET_6967A: int = 0x567A
const FRAMESET_6967F: int = 0x567F  # defeated
const FRAMESET_69695: int = 0x5695
const FRAMESET_6969A: int = 0x569A
const FRAMESET_6969F: int = 0x569F  # a barrel
const FRAMESET_696A8: int = 0x56A8  # flashing
const FRAMESET_696B6: int = 0x56B6
const FRAMESET_696B9: int = 0x56B9
const YELLOW_BELLY_BODY_FUNC: int = 0x14_5356  # YellowBellyBodyFunc
const YELLOW_BELLY_FLASH_1: int = 0x14_539D  # .Func_5139d
const YELLOW_BELLY_FLASH_2: int = 0x14_53BF
const YELLOW_BELLY_FLASH_3: int = 0x14_53D9
const YELLOW_BELLY_WAIT: int = 0x14_53FB  # .Func_513fb
const YELLOW_BELLY_RISE: int = 0x14_5419  # .Func_51419
const YELLOW_BELLY_SHOOT: int = 0x14_54A4  # .Func_514a4
const YELLOW_BELLY_INFLATE: int = 0x14_5572  # .Func_51572
const YELLOW_BELLY_CHASE_PUMP: int = 0x14_55DD  # .Func_515dd
const YELLOW_BELLY_SWIM: int = 0x14_5652  # .Func_51652
const YELLOW_BELLY_SINK: int = 0x14_578C  # .Func_5178c
const YELLOW_BELLY_HURT: int = 0x14_57EE  # .Func_517ee
const YELLOW_BELLY_DEFEATED: int = 0x14_584A  # .Func_5184a
const PUMP_FUNC: int = 0x14_58B7  # PumpFunc
const PUMP_FALL: int = 0x14_58C6  # .Func_518c6
const PUMP_UPDATE: int = 0x14_5947  # .Func_51947
const YELLOW_BELLY_ARROW_LEFT: int = 0x14_5A65  # YellowBellyArrowFunc.Left
const YELLOW_BELLY_ARROW_LEFT_FLY: int = 0x14_5A7D
const YELLOW_BELLY_ARROW_LEFT_KNOCKED: int = 0x14_5AAA
const YELLOW_BELLY_ARROW_RIGHT: int = 0x14_5AC1
const YELLOW_BELLY_ARROW_RIGHT_FLY: int = 0x14_5AD9
const YELLOW_BELLY_ARROW_HIT: int = 0x14_5B16  # .Func_51b16
const YELLOW_BELLY_ARROW_RIGHT_KNOCKED: int = 0x14_5B34
const YELLOW_BELLY_HEAD_FUNC: int = 0x14_5B6E  # YellowBellyHeadFunc
const YELLOW_BELLY_HEAD_UPDATE: int = 0x14_5B7B
const YELLOW_BELLY_PLATFORM_FUNC: int = 0x14_5C18  # YellowBellyPlatformFunc
const YELLOW_BELLY_PLATFORM_WAIT: int = 0x14_5C3F
const FUNC_51C77: int = 0x14_5C77  # the platform opening
const DIV_YELLOW_BELLY_RISE: int = 0x14_5429  # .Func_51419's rDIV read
const DIV_YELLOW_BELLY_SWIM: int = 0x14_5504  # .asm_514eb's
const YELLOW_BELLY_BODY: int = 0x4B  # IDs
const YELLOW_BELLY_ARROW: int = 0x4D
const PUMP: int = 0x4E
const YELLOW_BELLY_PLATFORM: int = 0x4F
# The battle's variables in the object WRAM ($d146-$d148, Doll Boy's there).
const W_YELLOW_BELLY_PAUSED: int = 0x146  # its head hit: the body still 30 frames
const W_YELLOW_BELLY_HIT: int = 0x147  # the pump hit it
const W_YELLOW_BELLY_PUMPING: int = 0x148  # inflated: chasing its pump
const OBJ_PARAMS_YELLOW_BELLY_HEAD: int = 0x4F18  # bank $19
const OBJ_PARAMS_PUMP: int = 0x4F2B
const OBJ_PARAMS_YELLOW_BELLY_ARROW_LEFT: int = 0x4C62
const OBJ_PARAMS_YELLOW_BELLY_ARROW_RIGHT: int = 0x4C77
const DATA_60950: int = 0x4950  # its swimming bob (bank $18)
const DATA_609E0: int = 0x49E0  # the pump falling
const DATA_60A00: int = 0x4A00  # the pump knocked left
const DATA_60A10: int = 0x4A10  # right
const OAM_191940: int = 0x5940  # its OAM after the first hit (bank $64)
const OAM_191F04: int = 0x5F04  # after the second
const FRAMESET_69780: int = 0x5780  # inflated, left
const FRAMESET_69789: int = 0x5789
const FRAMESET_69792: int = 0x5792  # shooting, left
const FRAMESET_697A1: int = 0x57A1
const FRAMESET_697B0: int = 0x57B0  # turning
const FRAMESET_697BB: int = 0x57BB
const FRAMESET_697C6: int = 0x57C6  # inflating
const FRAMESET_697D5: int = 0x57D5  # hurt
const FRAMESET_697E6: int = 0x57E6  # swimming, left
const FRAMESET_697EB: int = 0x57EB
const FRAMESET_69845: int = 0x5845  # defeated
const FRAMESET_6987F: int = 0x587F  # the pump
const FRAMESET_69882: int = 0x5882
const FRAMESET_69893: int = 0x5893  # the platform
const FRAMESET_69896: int = 0x5896
const ANONSTER_FUNC: int = 0x14_4000  # AnonsterFunc
const ANONSTER_WAIT: int = 0x14_4024  # .Func_50024
const ANONSTER_APPEAR: int = 0x14_405E  # .Func_5005e
const ANONSTER_SWIM: int = 0x14_407F  # .Func_5007f
const ANONSTER_SILK_WAIT: int = 0x14_416F  # .Func_5016f
const ANONSTER_SILK_1: int = 0x14_41C4
const ANONSTER_SILK_2: int = 0x14_4200
const ANONSTER_SILK_3: int = 0x14_423D
const ANONSTER_KNOCKED: int = 0x14_4282  # .Func_50282
const ANONSTER_RISE: int = 0x14_4293  # .Func_50293
const ANONSTER_CHASE: int = 0x14_42D1  # .Func_502d1
const ANONSTER_DROP: int = 0x14_434C  # .Func_5034c
const ANONSTER_LANDED: int = 0x14_4397  # .Func_50397
const ANONSTER_GROUND: int = 0x14_441D  # .Func_5041d
const ANONSTER_HURT: int = 0x14_45BE  # .Func_505be
const ANONSTER_CROUCH: int = 0x14_45F4  # .Func_505f4
const ANONSTER_LEAP: int = 0x14_4610  # .Func_50610
const ANONSTER_FLY_UP: int = 0x14_4635  # .Func_50635
const ANONSTER_JUMP: int = 0x14_4650  # .Func_50650
const ANONSTER_JUMP_2: int = 0x14_466C  # .Func_5066c
const ANONSTER_DEFEATED: int = 0x14_4689  # .Func_50689
const ANONSTER_DEFEAT_FALL: int = 0x14_4705  # .Func_50705
const SILK_PLATFORMS_FUNC: int = 0x14_471A  # SilkPlatformsFunc
const SILK_PLATFORMS_CREATE_3: int = 0x14_4730
const SILK_PLATFORMS_CREATE_2: int = 0x14_4738
const SILK_PLATFORMS_CREATE_1: int = 0x14_4740
const SILK_PLATFORMS_WAIT: int = 0x14_4761
const SILK_PLATFORM_FUNC: int = 0x14_476C  # SilkPlatformFunc
const ANONSTER_SILK_FLOAT_LEFT: int = 0x14_4779  # AnonsterSilkFunc.FloatLeft
const ANONSTER_SILK_FLOAT_RIGHT: int = 0x14_47B8
const ANONSTER_SILK_BURST: int = 0x14_48BE  # .Func_508be
const ANONSTER_SILK_LANDED: int = 0x14_48CD  # .Func_508cd
const ANONSTER_WAVE_LEFT: int = 0x14_4A86  # AnonsteWaveLFunc_Left
const ANONSTER_WAVE_RIGHT: int = 0x14_4A8B
const DIV_ANONSTER_SILK: int = 0x14_484B  # .asm_50849's rDIV read
const OBJ_INTERACTION_48: int = 0x48  # Anonster's on the ground
const OBJ_PARAMS_ANONSTER_SILK: Array = [[0x4A94, 0x4AA9], [0x4ABE, 0x4AD3], [0x4AE8, 0x4AFD]]  # bank $19: left, right
const OBJ_PARAMS_ANONSTER_WAVE_LEFT: int = 0x4B12
const OBJ_PARAMS_ANONSTER_WAVE_RIGHT: int = 0x4B27
const OBJ_PARAMS_SILK_PLATFORM: Array = [0x4B3C, 0x4B51, 0x4B66]
const DATA_60790: int = 0x4790  # its swimming bob (bank $18)
const DATA_607E0: int = 0x47E0  # flying up
const DATA_607F0: int = 0x47F0  # dropping
const DATA_60800: int = 0x4800  # a silk's sway, right
const DATA_60830: int = 0x4830  # left
const FRAMESET_693C4: int = 0x53C4  # swimming, left
const FRAMESET_693D5: int = 0x53D5
const FRAMESET_693E6: int = 0x53E6  # spinning silk
const FRAMESET_693F9: int = 0x53F9
const FRAMESET_69402: int = 0x5402
const FRAMESET_69411: int = 0x5411
const FRAMESET_69424: int = 0x5424
const FRAMESET_6942D: int = 0x542D
const FRAMESET_6943C: int = 0x543C  # knocked down
const FRAMESET_69441: int = 0x5441
const FRAMESET_69446: int = 0x5446  # turning
const FRAMESET_6944D: int = 0x544D  # dropping
const FRAMESET_69450: int = 0x5450  # landed
const FRAMESET_69463: int = 0x5463  # making a wave
const FRAMESET_69474: int = 0x5474
const FRAMESET_69485: int = 0x5485  # walking left
const FRAMESET_69496: int = 0x5496
const FRAMESET_694A7: int = 0x54A7  # hit
const FRAMESET_694B8: int = 0x54B8
const FRAMESET_694C9: int = 0x54C9
const FRAMESET_694D0: int = 0x54D0
const FRAMESET_694D7: int = 0x54D7  # defeated
const FRAMESET_694DC: int = 0x54DC
const FRAMESET_694E1: int = 0x54E1
const FRAMESET_694F5: int = 0x54F5  # a silk landed
const FRAMESET_69512: int = 0x5512
const FRAMESET_69519: int = 0x5519
const FRAMESET_6951E: int = 0x551E
const FRAMESET_6953C: int = 0x553C
const FRAMESET_69543: int = 0x5543
const FRAMESET_6954D: int = 0x554D
const FRAMESET_69554: int = 0x5554
const FRAMESET_6955B: int = 0x555B  # a silk bursting
const FRAMESET_69568: int = 0x5568
const FRAMESET_69573: int = 0x5573
const SCOWLER_FUNC: int = 0x15_44E5  # ScowlerFunc
const SCOWLER_START: int = 0x15_4520  # .Func_54520
const SCOWLER_SWALLOW: int = 0x15_4542  # .Func_54542
const SCOWLER_MAIN: int = 0x15_458A  # .Func_5458a
const SCOWLER_STUNNED: int = 0x15_46E0  # .Func_546e0
const SCOWLER_CHASE: int = 0x15_4770  # .Func_54770
const SCOWLER_HURT: int = 0x15_4806  # .Func_54806
const SCOWLER_RISE: int = 0x15_4853  # .Func_54853
const SCOWLER_CLOSE: int = 0x15_487D  # .Func_5487d
const SCOWLER_DEFEATED: int = 0x15_48C5  # .Func_548c5
const SCOWLER_SINK: int = 0x15_490B  # .Func_5490b
const SCOWLER_GONE: int = 0x15_4931  # .Func_54931
const FLOATING_RING_SPAWNER_FUNC: int = 0x15_4981  # FloatingRingSpawnerFunc
const FLOATING_RING_SPAWNER_WAIT: int = 0x15_4997
const FLOATING_RING_SPAWNER_IDLE: int = 0x15_49AB
const FLOATING_RING_FUNC: int = 0x15_49B6  # FloatingRingFunc
const FLOATING_RING_RISE: int = 0x15_49C7
const FLOATING_RING_WAIT: int = 0x15_49EE
const FLOATING_RING_UP: int = 0x15_4A02
const FLOATING_RING_DOWN: int = 0x15_4A2D
const SCROWLER_TENTACLE_FUNC: int = 0x15_4A70  # ScrowlerTentacleFunc
const SCROWLER_TENTACLE_UPDATE: int = 0x15_4A97
const INK_FUNC_LEFT: int = 0x15_4B86  # InkFunc.Left
const INK_FUNC_RIGHT: int = 0x15_4B93
const INK_SPLASH: int = 0x15_4BF8  # .Func_54bf8
const SCOWLER: int = 0x50  # IDs
const SCROWLER_TENTACLE_RIGHT: int = 0x51
const OBJ_INTERACTION_07: int = 0x07
const OBJ_INTERACTION_WATER_TELEPORTING: int = 0x40
const OBJ_INTERACTION_SCOWLER: int = 0x41
const OBJ_INTERACTION_43: int = 0x43
# The battle's variables in the object WRAM ($d146, $d147: Doll Boy's bytes).
const W_SCOWLER_BLACKOUT: int = 0x146  # the ink's blackout, counting down
const W_SCOWLER_INK: int = 0x147  # Wario inked, counting up
const OBJ_PARAMS_SCROWLER_TENTACLE_RIGHT: int = 0x4F51  # bank $19
const OBJ_PARAMS_SCROWLER_TENTACLE_LEFT: int = 0x4F64
const OBJ_PARAMS_INK_LEFT: int = 0x4CCB
const OBJ_PARAMS_INK_RIGHT: int = 0x4CE0
const OBJ_PARAMS_FLOATING_RING: int = 0x4CF5
const DATA_60A60: int = 0x4A60  # stunned, sinking (bank $18)
const DATA_60A70: int = 0x4A70  # rising
const DATA_60A80: int = 0x4A80  # defeated, swaying
const DATA_60A90: int = 0x4A90  # sinking away
const FRAMESET_69A5F: int = 0x5A5F  # swimming left
const FRAMESET_69A68: int = 0x5A68  # right
const FRAMESET_69A71: int = 0x5A71  # turning
const FRAMESET_69A7A: int = 0x5A7A  # shooting ink
const FRAMESET_69A95: int = 0x5A95  # stunned
const FRAMESET_69AA8: int = 0x5AA8  # closing
const FRAMESET_69AB3: int = 0x5AB3  # mouth open
const FRAMESET_69ABC: int = 0x5ABC  # hurt
const FRAMESET_69AC3: int = 0x5AC3  # defeated
const FRAMESET_69AF5: int = 0x5AF5  # the ink's splash
const FRAMESET_69B03: int = 0x5B03  # Wario swallowed
const FRAMESET_69B08: int = 0x5B08
const MUDDEE_FUNC: int = 0x15_5611  # MuddeeFunc
const MUDDEE_AMBUSH: int = 0x15_564E  # .Func_5564e
const MUDDEE_WAIT: int = 0x15_5676
const MUDDEE_LURK: int = 0x15_5696
const MUDDEE_RISE: int = 0x15_56F0
const MUDDEE_MAIN: int = 0x15_5711  # .Func_55711
const MUDDEE_DEFEATED: int = 0x15_5BA7  # .Func_55ba7
const MUDDEE_STINGER_FUNC: int = 0x13_4A16  # MuddeeStingerFunc
const MUDDEE_STINGER_UPDATE: int = 0x13_4A2A
const TURTLE_1_FUNC: int = 0x15_5C4A  # Turtle1Func
const TURTLE_1_WAIT: int = 0x15_5C7D
const TURTLE_1_CARRY: int = 0x15_5C91
const TURTLE_1_STOP: int = 0x15_5CDD
const TURTLE_1_SINK: int = 0x15_5CF9
const TURTLE_1_HIDDEN: int = 0x15_5D18
const TURTLE_1_RETURN: int = 0x15_5D4C
const TURTLE_COMMON_FUNC: int = 0x15_5D7C  # TurtleCommonFunc
const TURTLE_COMMON_CARRY: int = 0x15_5D90
const TURTLE_COMMON_STOPPED: int = 0x15_5DE0
const TURTLE_2_FUNC: int = 0x15_5DE4  # Turtle2Func
const MUDDEE: int = 0x5A  # IDs (Wolfenboss's platform's too, in another group)
const TURTLE1: int = 0x5B
const MUDDEE_STINGER2: int = 0x35
# The battle's variables in the object WRAM ($d146, $d147).
const W_MUDDEE_AMBUSH_STATE: int = 0x146  # 1 the turtle stopped, 2 Muddee defeated
const W_MUDDEE_HIT: int = 0x147  # 1 its stinger touched, 2 hurt
const OBJ_PARAMS_MUDDEE_STINGER_1: int = 0x4F77  # bank $19
const OBJ_PARAMS_MUDDEE_STINGER_2: int = 0x4F8A
const DATA_4CAED: int = 0x4AED  # the stingers' offsets by Muddee's frame (bank $13)
const DATA_4CB0D: int = 0x4B0D
const DATA_60D30: int = 0x4D30  # out of the water (bank $18)
const DATA_60D40: int = 0x4D40  # sinking hurt
const FRAMESET_69CF2: int = 0x5CF2
const FRAMESET_69CFB: int = 0x5CFB
const FRAMESET_69D04: int = 0x5D04
const FRAMESET_69D0D: int = 0x5D0D
const FRAMESET_69D16: int = 0x5D16
const FRAMESET_69D2F: int = 0x5D2F
const FRAMESET_69D48: int = 0x5D48  # hurt
const FRAMESET_69D4D: int = 0x5D4D
const FRAMESET_69D52: int = 0x5D52
const FRAMESET_69D57: int = 0x5D57
const FRAMESET_69D5C: int = 0x5D5C  # a turtle
const FRAMESET_69D65: int = 0x5D65
const FRAMESET_69D6A: int = 0x5D6A  # defeated
const FRAMESET_69D73: int = 0x5D73
const FRAMESET_69D85: int = 0x5D85
const FRAMESET_69D8E: int = 0x5D8E  # roaming
const FRAMESET_69DA7: int = 0x5DA7
const FRAMESET_69DC0: int = 0x5DC0  # diving
const JAMANO_FUNC: int = 0x15_4D37  # JamanoFunc
const JAMANO_REVEAL: int = 0x15_4D7D  # .Func_54d7d
const JAMANO_INTRO: int = 0x15_4DAA  # .Func_54daa
const JAMANO_DO_NOTHING: int = 0x15_4E0A  # .Func_54e0a
const JAMANO_MAIN: int = 0x15_4E10  # .Func_54e10
const JAMANO_EXPOSED: int = 0x15_4F9D  # .Func_54f9d
const JAMANO_HAT_OFF_1: int = 0x15_507B  # .Func_5507b
const JAMANO_HAT_OFF_2: int = 0x15_5097
const JAMANO_HAT_OFF_3: int = 0x15_50B3
const JAMANO_DEFEATED: int = 0x15_50DB  # .Func_550db
const JAMANO_FALL: int = 0x15_50FF
const JAMANO_HAT_FUNC: int = 0x15_510A  # JamanoHatFunc
const JAMANO_HAT_RISE: int = 0x15_5125
const HAT_PLATFORM_FUNC: int = 0x15_515B  # HatPlatformFunc
const HAT_PLATFORM_UPDATE: int = 0x15_5194
const SKULL_SPAWNER_FUNC: int = 0x15_51E5  # SkullSpawnerFunc
const SKULL_SPAWNER_UPDATE: int = 0x15_522C
const SKULL_FUNC: int = 0x15_528D  # SkullFunc
const SKULL_WAIT: int = 0x15_529F  # .Func_5529f
const SKULL_DELAY: int = 0x15_52BA
const SKULL_FLY: int = 0x15_52D4
const SKULL_AT_EDGE: int = 0x15_531C
const SKULL_OUT: int = 0x15_5347
const SKULL_KNOCKED_LEFT: int = 0x15_5396
const SKULL_KNOCKED_RIGHT: int = 0x15_53A0
const JAMANO: int = 0x56  # IDs (the skulls' in another group)
const SKULL1: int = 0x50
const SKULL3: int = 0x52
# The battle's variables in the object WRAM ($d146-$d149). The background palettes darken a step at
# each level of the dark (Pals_55511 to _555d1), black at 4 (BlackOutBGPals).
const W_JAMANO_ACTIVE_SKULLS: int = 0x146  # wJamanoActiveSkulls: skulls 1-4 out (bits 0-3)
const W_JAMANO_SKULLS_OUT: int = 0x147  # w1d147: skulls waiting at the screen's edges
const W_JAMANO_DARKNESS: int = 0x148  # wDollBoyHammerRange: the dark's level, 0-4
const W_JAMANO_INTRO: int = 0x149  # w1d149: set by the skull spawner, cleared as the battle starts
const OBJ_PARAMS_SKULLS: Array[int] = [0x4D0A, 0x4D1F, 0x4D34, 0x4D49]  # ObjParams_Skull1-4 (bank $19)
const OBJ_PARAMS_JAMANO_HAT: int = 0x4D5E
const DATA_60C20: int = 0x4C20  # down or right (bank $18)
const DATA_60C80: int = 0x4C80  # up or left
const DATA_60CE0: int = 0x4CE0  # a skull's bobbing (1 and 3)
const DATA_60D00: int = 0x4D00  # (2 and 4)
const DATA_60D20: int = 0x4D20  # Jamano's fall
# Func_554bc: Jamano's framesets by the dark's level 1-4, facing left and right.
const JAMANO_FRAMESETS_LEFT: Array[int] = [0x5C37, 0x5C2E, 0x5C25, 0x5C1C]
const JAMANO_FRAMESETS_RIGHT: Array[int] = [0x5CBC, 0x5CB3, 0x5CAA, 0x5CA1]
const FRAMESET_69C1C: int = 0x5C1C
const FRAMESET_69C40: int = 0x5C40  # losing its hat
const FRAMESET_69C45: int = 0x5C45
const FRAMESET_69C4A: int = 0x5C4A
const FRAMESET_69C4F: int = 0x5C4F
const FRAMESET_69C7A: int = 0x5C7A  # turning left
const FRAMESET_69C92: int = 0x5C92  # turning right
const FRAMESET_69CA1: int = 0x5CA1
const FRAMESET_69CD6: int = 0x5CD6  # a skull at the edge
const FRAMESET_69CDB: int = 0x5CDB
const FRAMESET_69CE0: int = 0x5CE0  # exposed
const FRAMESET_69CE9: int = 0x5CE9
const FRAMESET_69CEC: int = 0x5CEC  # a skull knocked away
const FRAMESET_69CEF: int = 0x5CEF  # the hat platform
const SHOOT_FUNC: int = 0x15_6611  # ShootFunc
const SHOOT_START_WAIT: int = 0x15_6666  # .StartWait
const SHOOT_TAUNT: int = 0x15_6675
const SHOOT_MAIN: int = 0x15_6717
const SHOOT_BALL_FORM: int = 0x15_6A1C
const SHOOT_DEFEAT_RISE: int = 0x15_6D88
const SHOOT_DEFEAT_SUSPEND_AND_FALL: int = 0x15_6DAF
const GK_TORTOISE_PLATFORM_FUNC: int = 0x15_6DCC  # GKTortoisePlatformFunc
const GK_TORTOISE_PLATFORM_MOVE_LEFT: int = 0x15_6E01
const GK_TORTOISE_PLATFORM_MOVE_UP_AND_DOWN: int = 0x15_6E24
const GK_TORTOISE_FUNC: int = 0x15_6E6A  # GKTortoiseFunc
const GK_TORTOISE_MAIN: int = 0x15_6EAC
const SHOOT: int = 0x50  # its ID
const OBJ_INTERACTION_SHOOT: int = 0x4D
const NUM_SHOOT_GOALS_NEEDED: int = 3
const NUM_WARIO_GOALS_NEEDED: int = 3
const SHOOT_JUMP_X_SPEED: int = 1
const SHOOT_PRESHOOT_X_SPEED: int = 1
const SHOOT_OUT_OF_BALL_X_SPEED: int = 2
const SHOOT_TAUNT_DURATION: int = 80
const SHOOT_JUMP_DELAY_LONG: int = 25  # Wario without a goal
const SHOOT_JUMP_DELAY_SHORT: int = 2
const SHOOT_IDLE_DURATION: int = 27
const SHOOT_JUMP_UP_DURATION: int = 22
const SHOOT_TURN_AROUND_DURATION: int = 42
const SHOOT_LAST_GOAL_BALL_DURATION: int = 160  # Wario at 2 goals (otherwise 256)
const SHOOT_DEFEAT_RISE_DURATION: int = 28
const SHOOT_DEFEAT_SUSPENDED_DURATION: int = 70
const SHOOTPHASE_STANDING: int = 0  # OBJ_VAR_1 outside the ball
const SHOOTPHASE_JUMPING_UP: int = 1
const SHOOTPHASE_JUMPING_DOWN: int = 2
const SHOOTPHASE_BETWEEN_JUMPS: int = 3
const SHOOTPHASE_TURNING: int = 4
const SHOOTPHASE_PREKICK_JUMP: int = 5
const SHOOTPHASE_PREKICK_ANIMATION: int = 6
const SHOOTPHASE_KICKING: int = 7
const SHOOTPHASE_SCORE_GOAL: int = 8
const SHOOTPHASE_WON: int = 9
const GKTORTOISEPHASE_DUCKING: int = 7
const SHOOTBALL_WARIO_KICKED: int = 5  # wShootBallState
const SHOOTBALL_WARIO_GOAL: int = 6
# The game's variables in the object WRAM ($d146, $d147; wShootGoals and wWarioGoals are ObjectSim's).
const W_SHOOT_CAN_TURN_AROUND: int = 0x146
const W_SHOOT_BALL_STATE: int = 0x147
# The ball form's own entries by OBJ_STATE (.BallForm's table); these run the shared routines.
const SHOOT_BALL_SHARED_STATES: Array[int] = [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x30, 0x32,
		0x33, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x44, 0x45, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57]
const DATA_54000: int = 0x4000  # Shoot's pre-kick jump (bank $15)
const DATA_54010: int = 0x4010  # the kicked ball's rise
const DATA_60E20: int = 0x4E20  # the ball's bounce (bank $18)
const DATA_60E40: int = 0x4E40  # the ball's hop
const DATA_60E70: int = 0x4E70  # the ball's high bounce
const DATA_60E90: int = 0x4E90  # defeated, rising
const DATA_60EA0: int = 0x4EA0  # falling
const FRAMESET_69F35: int = 0x5F35  # turning left
const FRAMESET_69F40: int = 0x5F40  # turning right
const FRAMESET_69F54: int = 0x5F54  # kicking
const FRAMESET_69F5D: int = 0x5F5D  # a ball
const FRAMESET_69F66: int = 0x5F66
const FRAMESET_69F6F: int = 0x5F6F
const FRAMESET_69F7C: int = 0x5F7C  # taunting
const FRAMESET_69F8A: int = 0x5F8A  # defeated
const FRAMESET_69F93: int = 0x5F93
const FRAMESET_69F9A: int = 0x5F9A  # a goal for Wario
const FRAMESET_69F9F: int = 0x5F9F
const FRAMESET_69FA4: int = 0x5FA4
const FRAMESET_69FA9: int = 0x5FA9  # GK Tortoise
const FRAMESET_69FBA: int = 0x5FBA
const FRAMESET_69FCF: int = 0x5FCF
const FRAMESET_69FDC: int = 0x5FDC  # its platform
const FRAMESET_69FED: int = 0x5FED
const FRAMESET_69FF2: int = 0x5FF2
const FRAMESET_69FFD: int = 0x5FFD  # Shoot with Wario's ball
const FRAMESET_6A000: int = 0x6000
const FRAMESET_6A00B: int = 0x600B
const FRAMESET_6A00E: int = 0x600E
const FRAMESET_6A017: int = 0x6017  # ducking
const FRAMESET_6A022: int = 0x6022  # standing left (its second pair on: 6024)
const FRAMESET_6A02B: int = 0x602B  # jumping left
const FRAMESET_6A02E: int = 0x602E  # 48 px up, left
const FRAMESET_6A031: int = 0x6031
const FRAMESET_6A034: int = 0x6034
const FRAMESET_6A037: int = 0x6037  # landed, left
const FRAMESET_6A03A: int = 0x603A  # standing right
const FRAMESET_6A043: int = 0x6043
const FRAMESET_6A046: int = 0x6046
const FRAMESET_6A049: int = 0x6049
const FRAMESET_6A04C: int = 0x604C
const FRAMESET_6A04F: int = 0x604F
const OBJ_PARAMS_HIGH_ROLLING_ROCK_LEFT: int = 0x4BCF  # bank $19
const OBJ_PARAMS_HIGH_ROLLING_ROCK_RIGHT: int = 0x4BE4
const OBJ_PARAMS_LOW_ROLLING_ROCK_LEFT: int = 0x4BF9
const OBJ_PARAMS_LOW_ROLLING_ROCK_RIGHT: int = 0x4C0E
const DATA_608B0: int = 0x48B0  # a high rock's bounce (bank $18)
const DATA_60900: int = 0x4900  # a low rock's
const DATA_60DD0: int = 0x4DD0  # Wormwould hurt
const FRAMESET_696BC: int = 0x56BC  # shooting low, facing left
const FRAMESET_696C5: int = 0x56C5
const FRAMESET_696CE: int = 0x56CE  # facing right
const FRAMESET_696D7: int = 0x56D7  # shooting high, facing right
const FRAMESET_696E0: int = 0x56E0  # attacked, facing right
const FRAMESET_696E5: int = 0x56E5  # smashed
const FRAMESET_696EA: int = 0x56EA  # hurt
const FRAMESET_696F3: int = 0x56F3  # defeated
const FRAMESET_69701: int = 0x5701  # burrowing, facing right
const FRAMESET_6970A: int = 0x570A  # facing left
const FRAMESET_69713: int = 0x5713  # shooting high, facing left
const FRAMESET_6971C: int = 0x571C  # attacked, facing left
const FRAMESET_69721: int = 0x5721
const FRAMESET_69726: int = 0x5726
const FRAMESET_6972F: int = 0x572F
const FRAMESET_69734: int = 0x5734  # burrowing, facing left


func object_functions() -> Dictionary:
	var functions: Dictionary = super()
	functions.merge({
		WORMWOULD_FUNC: wormwould_func,
		WORMWOULD_INIT: wormwould_init,
		WORMWOULD_DO_NOTHING: _no_actions,
		WORMWOULD_MAIN: wormwould_main,
		WORMWOULD_UNDERGROUND: wormwould_underground,
		WORMWOULD_DEFEATED_RAISE: wormwould_defeated_raise,
		WORMWOULD_DEFEATED_WAIT: wormwould_defeated_wait,
		WORMWOULD_DEFEATED_FALL: wormwould_defeated_fall,
		ROLLING_ROCK_FUNC_LEFT: rolling_rock_func_left,
		ROLLING_ROCK_MOVE_LEFT: rolling_rock_move_left,
		ROLLING_ROCK_FUNC_RIGHT: rolling_rock_func_right,
		ROLLING_ROCK_MOVE_RIGHT: rolling_rock_move_right,
		ROLLING_ROCK_HIT: rolling_rock_hit,
		PALM_TREE_SPAWNER_FUNC: palm_tree_spawner_func,
		PALM_TREE_SPAWNER_SPAWN_TREES: palm_tree_spawner_spawn_trees,
		PALM_TREE_SPAWNER_WAIT: palm_tree_spawner_wait,
		PALM_TREE_FUNC: palm_tree_func,
		PALM_TREE_UPDATE: palm_tree_update,
		WOLFENBOSS_FUNC: wolfenboss_func,
		WOLFENBOSS_WHISP_WAITING: wolfenboss_whisp_waiting,
		WOLFENBOSS_WHISP_RISING: wolfenboss_whisp_rising,
		WOLFENBOSS_SMOKE_ENTRANCE: wolfenboss_smoke_entrance,
		WOLFENBOSS_EMERGE_FROM_SMOKE: wolfenboss_emerge_from_smoke,
		WOLFENBOSS_START_WAIT: wolfenboss_start_wait,
		WOLFENBOSS_SMOKE_EXIT: wolfenboss_smoke_exit,
		WOLFENBOSS_DISAPPEAR: wolfenboss_disappear,
		WOLFENBOSS_MAIN: wolfenboss_main,
		WOLFENBOSS_DEFEAT_FALL: wolfenboss_defeat_fall,
		MAGIC_SPIRAL_FUNC: magic_spiral_func,
		MAGIC_SPIRAL_GROW: magic_spiral_grow,
		MAGIC_SPIRAL_MOVE: magic_spiral_move,
		MAGIC_SPIRAL_DISAPPEAR: magic_spiral_disappear,
		IGAGURI_FUNC: igaguri_func,
		IGAGURI_FALL: igaguri_fall,
		IGAGURI_BOUNCE: igaguri_bounce,
		IGAGURI_HATCH: igaguri_hatch,
		KURI_FUNC: kuri_func,
		KURI_LANDED: kuri_landed,
		KURI_LAUNCHED: kuri_launched,
		DOLL_BOY_FUNC: doll_boy_func,
		DOLL_BOY_INIT: doll_boy_init,
		DOLL_BOY_BARREL_PHASE: doll_boy_barrel_phase,
		DOLL_BOY_INIT_WALKING_PHASE: doll_boy_init_walking_phase,
		DOLL_BOY_WALKING_PHASE: doll_boy_walking_phase,
		DOLL_BOY_HIT_WARIO: doll_boy_hit_wario,
		DOLL_BOY_WAIT_THEN_DO_NOTHING: doll_boy_wait_then_do_nothing,
		DOLL_BOY_DO_NOTHING: _no_actions,
		DOLL_BOY_DEFEATED: doll_boy_defeated,
		DOLL_BOY_BARREL_1_FUNC: doll_boy_barrel_1_func,
		DOLL_BOY_BARREL_2_FUNC: doll_boy_barrel_2_func,
		DOLL_BOY_BARREL_3_FUNC: doll_boy_barrel_3_func,
		DOLL_BOY_BARREL_START_DELAY: doll_boy_barrel_start_delay,
		DOLL_BOY_BARREL_MAIN: doll_boy_barrel_main,
		DOLL_BOY_HAMMER_FUNC: doll_boy_hammer_func,
		DOLL_BOY_HAMMER_INIT: doll_boy_hammer_init,
		DOLL_BOY_HAMMER_UPDATE: doll_boy_hammer_update,
		DOLL_BOY_HAMMER_HIT_LEFT: doll_boy_hammer_hit_left,
		DOLL_BOY_HAMMER_HIT_RIGHT: doll_boy_hammer_hit_right,
		HAMMER_PLATFORM_SPAWNER_FUNC: hammer_platform_spawner_func,
		HAMMER_PLATFORM_SPAWNER_SPAWN: hammer_platform_spawner_spawn,
		HAMMER_PLATFORM_SPAWNER_DO_NOTHING: hammer_platform_spawner_do_nothing,
		HAMMER_PLATFORM_FUNC: hammer_platform_func,
		HAMMER_PLATFORM_MOVE_DOWN: hammer_platform_move_down,
		HAMMER_PLATFORM_MOVE_UP: hammer_platform_move_up,
		YELLOW_BELLY_BODY_FUNC: yellow_belly_body_func,
		YELLOW_BELLY_FLASH_1: yellow_belly_flash_1,
		YELLOW_BELLY_FLASH_2: yellow_belly_flash_2,
		YELLOW_BELLY_FLASH_3: yellow_belly_flash_3,
		YELLOW_BELLY_WAIT: yellow_belly_wait,
		YELLOW_BELLY_RISE: yellow_belly_rise,
		YELLOW_BELLY_SHOOT: yellow_belly_shoot,
		YELLOW_BELLY_INFLATE: yellow_belly_inflate,
		YELLOW_BELLY_CHASE_PUMP: yellow_belly_chase_pump,
		YELLOW_BELLY_SWIM: yellow_belly_swim,
		YELLOW_BELLY_SINK: yellow_belly_sink,
		YELLOW_BELLY_HURT: yellow_belly_hurt,
		YELLOW_BELLY_DEFEATED: yellow_belly_defeated,
		PUMP_FUNC: pump_func,
		PUMP_FALL: pump_fall,
		PUMP_UPDATE: pump_update,
		YELLOW_BELLY_ARROW_LEFT: yellow_belly_arrow_left,
		YELLOW_BELLY_ARROW_LEFT_FLY: yellow_belly_arrow_left_fly,
		YELLOW_BELLY_ARROW_LEFT_KNOCKED: yellow_belly_arrow_left_knocked,
		YELLOW_BELLY_ARROW_RIGHT: yellow_belly_arrow_right,
		YELLOW_BELLY_ARROW_RIGHT_FLY: yellow_belly_arrow_right_fly,
		YELLOW_BELLY_ARROW_HIT: yellow_belly_arrow_hit,
		YELLOW_BELLY_ARROW_RIGHT_KNOCKED: yellow_belly_arrow_right_knocked,
		YELLOW_BELLY_HEAD_FUNC: yellow_belly_head_func,
		YELLOW_BELLY_HEAD_UPDATE: yellow_belly_head_update,
		YELLOW_BELLY_PLATFORM_FUNC: yellow_belly_platform_func,
		YELLOW_BELLY_PLATFORM_WAIT: yellow_belly_platform_wait,
		FUNC_51C77: func_51c77,
		ANONSTER_FUNC: anonster_func,
		ANONSTER_WAIT: anonster_wait,
		ANONSTER_APPEAR: anonster_appear,
		ANONSTER_SWIM: anonster_swim,
		ANONSTER_SILK_WAIT: anonster_silk_wait,
		ANONSTER_SILK_1: anonster_silk_1,
		ANONSTER_SILK_2: anonster_silk_2,
		ANONSTER_SILK_3: anonster_silk_3,
		ANONSTER_KNOCKED: anonster_knocked,
		ANONSTER_RISE: anonster_rise,
		ANONSTER_CHASE: anonster_chase,
		ANONSTER_DROP: anonster_drop,
		ANONSTER_LANDED: anonster_landed,
		ANONSTER_GROUND: anonster_ground,
		ANONSTER_HURT: anonster_hurt,
		ANONSTER_CROUCH: anonster_crouch,
		ANONSTER_LEAP: anonster_leap,
		ANONSTER_FLY_UP: anonster_fly_up,
		ANONSTER_JUMP: anonster_jump,
		ANONSTER_JUMP_2: anonster_jump_2,
		ANONSTER_DEFEATED: anonster_defeated,
		ANONSTER_DEFEAT_FALL: anonster_defeat_fall,
		SILK_PLATFORMS_FUNC: silk_platforms_func,
		SILK_PLATFORMS_CREATE_1: silk_platforms_create_1,
		SILK_PLATFORMS_CREATE_2: silk_platforms_create_2,
		SILK_PLATFORMS_CREATE_3: silk_platforms_create_3,
		SILK_PLATFORMS_WAIT: silk_platforms_wait,
		SILK_PLATFORM_FUNC: silk_platform_func,
		ANONSTER_SILK_FLOAT_LEFT: anonster_silk_float_left,
		ANONSTER_SILK_FLOAT_RIGHT: anonster_silk_float_right,
		ANONSTER_SILK_BURST: anonster_silk_burst,
		ANONSTER_SILK_LANDED: anonster_silk_landed,
		ANONSTER_WAVE_LEFT: anonster_wave_left,
		ANONSTER_WAVE_RIGHT: anonster_wave_right,
		SCOWLER_FUNC: scowler_func,
		SCOWLER_START: scowler_start,
		SCOWLER_SWALLOW: scowler_swallow,
		SCOWLER_MAIN: scowler_main,
		SCOWLER_STUNNED: scowler_stunned,
		SCOWLER_CHASE: scowler_chase,
		SCOWLER_HURT: scowler_hurt,
		SCOWLER_RISE: scowler_rise,
		SCOWLER_CLOSE: scowler_close,
		SCOWLER_DEFEATED: scowler_defeated,
		SCOWLER_SINK: scowler_sink,
		SCOWLER_GONE: scowler_gone,
		FLOATING_RING_SPAWNER_FUNC: floating_ring_spawner_func,
		FLOATING_RING_SPAWNER_WAIT: floating_ring_spawner_wait,
		FLOATING_RING_SPAWNER_IDLE: floating_ring_spawner_idle,
		FLOATING_RING_FUNC: floating_ring_func,
		FLOATING_RING_RISE: floating_ring_rise,
		FLOATING_RING_WAIT: floating_ring_wait,
		FLOATING_RING_UP: floating_ring_up,
		FLOATING_RING_DOWN: floating_ring_down,
		SCROWLER_TENTACLE_FUNC: scrowler_tentacle_func,
		SCROWLER_TENTACLE_UPDATE: scrowler_tentacle_update,
		INK_FUNC_LEFT: ink_func_left,
		INK_FUNC_RIGHT: ink_func_right,
		INK_SPLASH: ink_splash,
		MUDDEE_FUNC: muddee_func,
		MUDDEE_AMBUSH: muddee_ambush,
		MUDDEE_WAIT: muddee_wait,
		MUDDEE_LURK: muddee_lurk,
		MUDDEE_RISE: muddee_rise,
		MUDDEE_MAIN: muddee_main,
		MUDDEE_DEFEATED: muddee_defeated,
		MUDDEE_STINGER_FUNC: muddee_stinger_func,
		MUDDEE_STINGER_UPDATE: muddee_stinger_update,
		TURTLE_1_FUNC: turtle_1_func,
		TURTLE_1_WAIT: turtle_1_wait,
		TURTLE_1_CARRY: turtle_1_carry,
		TURTLE_1_STOP: turtle_1_stop,
		TURTLE_1_SINK: turtle_1_sink,
		TURTLE_1_HIDDEN: turtle_1_hidden,
		TURTLE_1_RETURN: turtle_1_return,
		TURTLE_COMMON_FUNC: turtle_common_func,
		TURTLE_COMMON_CARRY: turtle_common_carry,
		TURTLE_COMMON_STOPPED: set_one_way_platform_action,
		TURTLE_2_FUNC: turtle_2_func,
		JAMANO_FUNC: jamano_func,
		JAMANO_REVEAL: jamano_reveal,
		JAMANO_INTRO: jamano_intro,
		JAMANO_DO_NOTHING: _no_actions,
		JAMANO_MAIN: jamano_main,
		JAMANO_EXPOSED: jamano_exposed,
		JAMANO_HAT_OFF_1: jamano_hat_off_1,
		JAMANO_HAT_OFF_2: jamano_hat_off_2,
		JAMANO_HAT_OFF_3: jamano_hat_off_3,
		JAMANO_DEFEATED: jamano_defeated,
		JAMANO_FALL: jamano_fall,
		JAMANO_HAT_FUNC: jamano_hat_func,
		JAMANO_HAT_RISE: jamano_hat_rise,
		HAT_PLATFORM_FUNC: hat_platform_func,
		HAT_PLATFORM_UPDATE: hat_platform_update,
		SKULL_SPAWNER_FUNC: skull_spawner_func,
		SKULL_SPAWNER_UPDATE: skull_spawner_update,
		SKULL_FUNC: skull_func,
		SKULL_WAIT: skull_wait,
		SKULL_DELAY: skull_delay,
		SKULL_FLY: skull_fly,
		SKULL_AT_EDGE: skull_at_edge,
		SKULL_OUT: skull_out,
		SKULL_KNOCKED_LEFT: skull_knocked_left,
		SKULL_KNOCKED_RIGHT: skull_knocked_right,
		SHOOT_FUNC: shoot_func,
		SHOOT_START_WAIT: shoot_start_wait,
		SHOOT_TAUNT: shoot_taunt,
		SHOOT_MAIN: shoot_main,
		SHOOT_BALL_FORM: shoot_ball_form,
		SHOOT_DEFEAT_RISE: shoot_defeat_rise,
		SHOOT_DEFEAT_SUSPEND_AND_FALL: shoot_defeat_suspend_and_fall,
		GK_TORTOISE_PLATFORM_FUNC: gk_tortoise_platform_func,
		GK_TORTOISE_PLATFORM_MOVE_LEFT: gk_tortoise_platform_move_left,
		GK_TORTOISE_PLATFORM_MOVE_UP_AND_DOWN: gk_tortoise_platform_move_up_and_down,
		GK_TORTOISE_FUNC: gk_tortoise_func,
		GK_TORTOISE_MAIN: gk_tortoise_main,
	})
	return functions


# --- Wormwould (objects/wormwould.asm) --------------------------------------------------------------

## WormwouldFunc: its hits left plus one in the substate's low bits, kept from despawning
## (OBJSUBFLAG_UNK_4), facing right; a box -8..7 (bottom 30).
func wormwould_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_INIT & 0xFFFF)
	var substate: int = cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & OBJSUBFLAGS_MASK
	set_cur(OBJ_SUBSTATE, substate | (WORMWOULD_NUM_HITS + 1) | OBJSUBFLAG_UNK_4 | OBJSUBFLAG_HDIR)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 30)
	set_object_frameset_ptr(FRAMESET_696CE)


## .Init: no actions until its y's low byte is Wario's (the high bytes go uncompared: the second
## `ret nz` sees the first compare's flags); then 32 px lower, the boss battle on (wBossState
## BOSS_REGULAR, wIsBossBattle; the music not simulated), and its side chosen.
func wormwould_init() -> void:
	_no_actions()
	if lo(cur_y()) != lo(wWarioYPos):
		return
	set_cur(OBJ_VAR_2, 0x20)
	set_cur_word(OBJ_Y_POS, cur_y() + cur(OBJ_VAR_2))
	wBossState = BOSS_REGULAR
	wIsBossBattle = 1
	_wormwould_check_change_side()


## .check_change_side: on screen with Wario less than $38 px in front of it (or behind it), it moves
## $70 px to the other side and faces back; then visible, its y kept in OBJ_VAR_1 and _2, OBJ_VAR_3
## $41, OBJSTATE_SPECIAL_1, its own interaction, and .Main (SFX_11A not simulated).
func _wormwould_check_change_side() -> void:
	var on_screen: bool = (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0
	var frameset: int
	if hdir():
		if on_screen and byte(wWarioScreenXPos + 0x2A) - byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < 0x38:
			set_hdir(false)
			frameset = FRAMESET_6970A
			set_cur_word(OBJ_X_POS, cur_x() + 0x70)
		else:
			frameset = FRAMESET_696CE
	else:
		if on_screen and byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A) < 0x38:
			set_hdir(true)
			frameset = FRAMESET_696CE
			set_cur_word(OBJ_X_POS, cur_x() - 0x70)
		else:
			frameset = FRAMESET_6970A
	set_object_frameset_ptr(frameset)
	set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_MAIN & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_VAR_1, lo(cur_y()))
	set_cur(OBJ_VAR_2, hi(cur_y()))
	set_cur(OBJ_VAR_3, 0x41)
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_1)
	set_interaction(OBJ_INTERACTION_WORMWOULD)


## The hits left: the substate's low bits, one more than the hits.
func _wormwould_hits_left() -> int:
	return (cur(OBJ_SUBSTATE) & 0x0F) - 1


## .Main, by OBJ_STATE: idle (0; gone when it is just above the screen's top, the battle off),
## shooting a high rock ($5a) or a low one ($5b, while one hit is left), rising out ($2d), burrowing
## ($5c), attacked ($04, $05: burrowing after 26 frames, $34), shaken ($08, $09: burrowing at once),
## smashed ($0a, $0b: a hit, hurt $3a). Any other state is cleared.
func wormwould_main() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0:
			_wormwould_idle()
		0x34:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)  # SFX_0A6 at 16 not simulated
			if cur(OBJ_STATE_DURATION) == 0:
				_wormwould_burrow()
		0x5A:
			_wormwould_shoot_high()
		OBJSTATE_SPECIAL_1:
			_wormwould_raise()
		0x5B:
			_wormwould_shoot_low()
		0x5C:
			_wormwould_burrowing()
		_:
			match state & 0xFE:
				OBJSTATE_ATTACKED_LEFT_START:
					set_cur(OBJ_STATE, 0x34)
					set_object_frameset_ptr(FRAMESET_696E0 if hdir() else FRAMESET_6971C)
					set_cur(OBJ_STATE_DURATION, WORMWOULD_BURROW_DELAY)
				0x08:
					set_cur(OBJ_STATE_DURATION, 1)
					_wormwould_burrow()
				OBJSTATE_VANISH_TOUCH:
					_wormwould_smashed()
				0x3A:
					_wormwould_hurt()
				_:
					set_cur(OBJ_STATE, 0)


## .asm_541e9: just above the screen's top (screen y -32 to -1) it stops for good (.DoNothing, the
## battle off: wBossState NONE; the music not simulated); otherwise its idle frames, then a high
## rock (.asm_54209).
func _wormwould_idle() -> void:
	if byte(cur(OBJ_SCREEN_Y_POS) + 0x20) < 0x20:
		set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_DO_NOTHING & 0xFFFF)
		wBossState = BOSS_NONE
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_wormwould_shoot_high_start()


## .asm_54209: shooting a high rock ($5a, 69 frames).
func _wormwould_shoot_high_start() -> void:
	set_object_frameset_ptr(FRAMESET_696D7 if hdir() else FRAMESET_69713)
	set_cur(OBJ_STATE_DURATION, WORMWOULD_SHOOT_ROCK_DURATION)
	set_cur(OBJ_STATE, 0x5A)


## .shoot_rock_high: the rock 48 frames in (ObjParams_HighRollingRockLeft or _Right; SFX_TEMPLE_ROCK
## not simulated); at the end idle (.set_idle, 43 frames).
func _wormwould_shoot_high() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == WORMWOULD_SHOOT_ROCK_DURATION - WORMWOULD_SHOOT_ROCK_DELAY:
		create_object_at_relative_pos(OBJ_PARAMS_HIGH_ROLLING_ROCK_RIGHT if hdir() else OBJ_PARAMS_HIGH_ROLLING_ROCK_LEFT)
		return
	if left != 0:
		return
	set_object_frameset_ptr(FRAMESET_696CE if hdir() else FRAMESET_6970A)
	_wormwould_set_idle()


func _wormwould_set_idle() -> void:
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_STATE_DURATION, WORMWOULD_IDLE_DURATION)


## .raising: a pixel up a frame for OBJ_VAR_3 frames, at its $1e-th with one hit left shooting a low
## rock instead (.asm_54131, $5b, 34 frames); risen, a high rock with fewer than three hits left,
## otherwise idle.
func _wormwould_raise() -> void:
	if _wormwould_hits_left() < 2 and cur(OBJ_VAR_3) == 0x1E:
		set_object_frameset_ptr(FRAMESET_696C5 if hdir() else FRAMESET_696BC)
		set_cur(OBJ_STATE_DURATION, 34)
		set_cur(OBJ_STATE, 0x5B)
		return
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) - 1)
	if cur(OBJ_VAR_3) != 0:
		move_object_up()
		return
	if _wormwould_hits_left() < WORMWOULD_NUM_HITS:
		_wormwould_shoot_high_start()
	else:
		_wormwould_set_idle()


## .shoot_rock_low: the rock with 10 frames left (ObjParams_LowRollingRockLeft or _Right); at the end
## burrowing.
func _wormwould_shoot_low() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0x0A:
		create_object_at_relative_pos(OBJ_PARAMS_LOW_ROLLING_ROCK_RIGHT if hdir() else OBJ_PARAMS_LOW_ROLLING_ROCK_LEFT)
		return
	if left != 0:
		return
	set_cur(OBJ_STATE_DURATION, 1)
	_wormwould_burrow()


## .set_burrowing: burrowing ($5c).
func _wormwould_burrow() -> void:
	set_cur(OBJ_STATE, 0x5C)
	set_object_frameset_ptr(FRAMESET_69701 if hdir() else FRAMESET_69734)


## .burrowing: down a pixel a frame to its home (OBJ_VAR_1 and _2: y), on even frames only while
## unhurt and OBJ_STATE_DURATION is 0; home, it waits underground 30 frames (.Underground, invisible),
## or with its last hit taken is defeated (rising $21 frames; its object-map nibble 5).
func _wormwould_burrowing() -> void:
	if _wormwould_hits_left() >= WORMWOULD_NUM_HITS and cur(OBJ_STATE_DURATION) == 0 and (wGlobalCounter & 1) == 0:
		return
	if lo(cur_y()) != cur(OBJ_VAR_1) or hi(cur_y()) != cur(OBJ_VAR_2):
		move_object_down()
		return
	if _wormwould_hits_left() == 0:
		set_cur(OBJ_VAR_3, 0x21)
		set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_DEFEATED_RAISE & 0xFFFF)
		set_cur_object_map_nibble(0x05)  # Func_ba42; SFX_0A7 not simulated
		return
	set_cur(OBJ_STATE_DURATION, WORMWOULD_UNDERGROUND_DURATION)
	set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_UNDERGROUND & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)


## .smash_attacked: hurt ($3a, 50 frames), harmless (OBJ_INTERACTION_0B), its box top -16, a hit
## taken (DecrementRemainingBossHits, never the last one's count below 1), OBJ_VAR_3 cleared
## (SFX_VANISH not simulated).
func _wormwould_smashed() -> void:
	set_cur(OBJ_STATE, 0x3A)
	set_object_frameset_ptr(FRAMESET_696E5 if hdir() else FRAMESET_69721)
	set_cur(OBJ_STATE_DURATION, WORMWOULD_HURT_DURATION)
	set_interaction(OBJ_INTERACTION_0B)
	set_cur(OBJ_COLLBOX_TOP, -16)
	decrement_remaining_boss_hits()
	set_cur(OBJ_VAR_3, 0)


## DecrementRemainingBossHits: the substate's low bits down by one, not below 1.
func decrement_remaining_boss_hits() -> void:
	if (cur(OBJ_SUBSTATE) & 0x0F) - 1 != 0:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) - 1)


## .hurt: along Data_60dd0 (SFX_0A7 at 30 not simulated); then burrowing, its box top -26 and the
## hurt frameset unless no hits are left (the music's stop not simulated).
func _wormwould_hurt() -> void:
	apply_obj_y_movement(DATA_60DD0)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE, 0x5C)
	if _wormwould_hits_left() == 0:
		return
	set_cur(OBJ_COLLBOX_TOP, -26)
	set_object_frameset_ptr(FRAMESET_696EA if hdir() else FRAMESET_69726)


## .Underground: no actions; gone for good once it is above screen row $3a (.DoNothing, the battle
## off); otherwise its 30 frames, then visible and out on a side (.check_change_side).
func wormwould_underground() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) < 0x3A:
		set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_DO_NOTHING & 0xFFFF)
		wBossState = BOSS_NONE
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	_wormwould_check_change_side()


## .DefeatedRaise: 2 px up a frame for $21 frames, then 30 frames waiting.
func wormwould_defeated_raise() -> void:
	_no_actions()
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) - 1)
	if cur(OBJ_VAR_3) != 0:
		set_cur_word(OBJ_Y_POS, cur_y() - 2)  # MoveObjectUp_Fast
		return
	set_object_frameset_ptr(FRAMESET_696F3 if hdir() else FRAMESET_6972F)
	set_cur(OBJ_STATE_DURATION, 30)
	set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_DEFEATED_WAIT & 0xFFFF)


## .DefeatedWait: after its 30 frames, facing Wario, its substate only HDIR, PRIORITY, and the boss
## defeated (wBossState BOSS_DEFEATED, wIsBossBattle off; the music not simulated); the next frame
## falling (SFX_0A3 not simulated).
func wormwould_defeated_wait() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, WORMWOULD_DEFEATED_FALL & 0xFFFF)
		wormwould_defeated_fall()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAG_HDIR)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0


## .DefeatedFall: along Data_60180, a pixel a frame away from the way it faces.
func wormwould_defeated_fall() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60180)
	if hdir():
		move_object_left()
	else:
		move_object_right()


# --- The rolling rocks (objects/wormwould.asm) ------------------------------------------------------

## RollingRockFunc_Left and _Right: no actions for its first OBJ_STATE_DURATION frames; 2 px a frame
## its way.
func rolling_rock_func_left() -> void:
	_rolling_rock_start(ROLLING_ROCK_MOVE_LEFT)
	rolling_rock_move_left()


func rolling_rock_func_right() -> void:
	_rolling_rock_start(ROLLING_ROCK_MOVE_RIGHT)
	rolling_rock_move_right()


func _rolling_rock_start(move: int) -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, move & 0xFFFF)


func rolling_rock_move_left() -> void:
	set_cur_word(OBJ_X_POS, cur_x() - 2)  # MoveObjectLeft_Fast
	_rolling_rock()


func rolling_rock_move_right() -> void:
	set_cur_word(OBJ_X_POS, cur_x() + 2)  # MoveObjectRight_Fast
	_rolling_rock()


## RollingRockFunc: bouncing along Data_608b0 (high, OBJ_VAR_1 0) or Data_60900 (low); given a state,
## knocked off (.Hit; SFX_016 not simulated).
func _rolling_rock() -> void:
	if cur(OBJ_STATE) == 0:
		apply_obj_y_movement(DATA_608B0 if cur(OBJ_VAR_1) == 0 else DATA_60900)
		return
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, ROLLING_ROCK_HIT & 0xFFFF)


## RollingRockFunc.Hit: no actions, along Data_60180, 2 px a frame back the way it faces.
func rolling_rock_hit() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60180)
	set_cur_word(OBJ_X_POS, cur_x() + (2 if hdir() else -2))


# --- The palm trees (objects/wormwould.asm) ---------------------------------------------------------

## PalmTreeSpawnerFunc: kept (OBJSUBFLAG_UNK_4), 240 frames to its trees.
func palm_tree_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, PALM_TREE_SPAWNER_SPAWN_TREES & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur(OBJ_STATE_DURATION, 240)
	palm_tree_spawner_wait()


## .SpawnTrees: counting down, a short palm tree at 120 frames left (ObjParams_PalmTreeShort), a
## medium one at 60, a tall one at the end (then only waiting).
func palm_tree_spawner_spawn_trees() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, PALM_TREE_SPAWNER_WAIT & 0xFFFF)
		create_object_at_relative_pos(OBJ_PARAMS_PALM_TREE_TALL)
	elif left == 60:
		create_object_at_relative_pos(OBJ_PARAMS_PALM_TREE_MEDIUM)
	elif left == 120:
		create_object_at_relative_pos(OBJ_PARAMS_PALM_TREE_SHORT)
	palm_tree_spawner_wait()


## .Wait: its frame held, no actions.
func palm_tree_spawner_wait() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()


## PalmTreeFunc: growing (.Update; its palette is presentation).
func palm_tree_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, PALM_TREE_UPDATE & 0xFFFF)


## .Update: a one-way platform rising a pixel a frame for OBJ_VAR_1 frames (no actions, its frame
## held at 10), then opening for OBJ_VAR_2 frames (no actions), then its frame held at 10.
func palm_tree_update() -> void:
	set_one_way_platform_action()
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		move_object_up()
		_no_actions()
		set_cur(OBJ_FRAME_DURATION, 10)
		return
	if cur(OBJ_VAR_2) == 0:
		set_cur(OBJ_FRAME_DURATION, 10)
		return
	set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
	_no_actions()


# --- Wolfenboss (objects/wolfenboss.asm) ------------------------------------------------------------

## WolfenbossFunc: visible, its hits (3, plus one) in the substate, a whisp's box -3..2 (bottom 1),
## 20 frames' wait; the battle's variables: a spiral next, no Igaguri or Kuri out, 4 hits, two
## spirals first.
func wolfenboss_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_WHISP_WAITING & 0xFFFF)
	var substate: int = cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & OBJSUBFLAGS_MASK
	set_cur(OBJ_SUBSTATE, substate | (WOLFENBOSS_NUM_HITS + 1))
	set_collbox_x(-3, 2)
	set_cur(OBJ_COLLBOX_BOTTOM, 1)
	set_object_frameset_ptr(FRAMESET_69E97)
	set_cur(OBJ_STATE_DURATION, 20)
	set_cur(OBJ_VAR_2, 0)
	wram1[W_WOLFENBOSS_NEXT_ATTACK] = 0
	wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] = 0
	wram1[W_WOLFENBOSS_REMAINING_HITS] = WOLFENBOSS_NUM_HITS + 1
	wram1[W_WOLFENBOSS_CONSECUTIVE_SPIRALS] = 2


## .WhispWaiting: no actions; on screen, swaying (Data_60650, looping) for its frames, then rising
## (64 frames), the battle on (wIsBossBattle; the music's stop not simulated).
func wolfenboss_whisp_waiting() -> void:
	_no_actions()
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		apply_obj_x_movement_loop(DATA_60650)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_WHISP_RISING & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69EA0)
	set_cur(OBJ_STATE_DURATION, 64)
	wIsBossBattle = 1


## .WhispRising: a pixel up a frame, then smoke (19 frames; SFX_0AA not simulated).
func wolfenboss_whisp_rising() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up()
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_SMOKE_ENTRANCE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69EA9)
	set_cur(OBJ_STATE_DURATION, 19)


## .SmokeEntrance: then emerging (Frameset_69e0e from its second pair), its box -8..7 (top -8,
## bottom 12), wBossState BOSS_REGULAR (the music not simulated).
func wolfenboss_smoke_entrance() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_EMERGE_FROM_SMOKE & 0xFFFF)
	set_cur_word(OBJ_FRAMESET_PTR, FRAMESET_69E0E)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 2)
	set_cur(OBJ_COLLBOX_TOP, -8)
	set_cur(OBJ_COLLBOX_BOTTOM, 12)
	set_collbox_x(-8, 7)
	wBossState = BOSS_REGULAR


## .EmergeFromSmoke: half a pixel up a frame while its frame is not 0; then 40 frames' wait.
func wolfenboss_emerge_from_smoke() -> void:
	_no_actions()
	if cur(OBJ_FRAME) != 0:
		move_object_up_slow()
		return
	set_object_frameset_ptr(FRAMESET_69DCB)
	set_cur(OBJ_STATE_DURATION, 40)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_START_WAIT & 0xFFFF)


## .StartWait: then the battle (.Main), moving left (OBJ_VAR_1 and _3 cleared, as the stores land).
func wolfenboss_start_wait() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_MAIN & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69DEC)


## .SmokeExit: its frames, then gone.
func wolfenboss_smoke_exit() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


## .Disappear: its frames, then smoke (14 frames; SFX_0AA not simulated) and .SmokeExit.
func wolfenboss_disappear() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69EA9)
	set_cur(OBJ_STATE_DURATION, 14)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_SMOKE_EXIT & 0xFFFF)


## .start_disappear: Wario transformed (hit), it leaves the field in 70 frames, wBossState NONE.
func _wolfenboss_start_disappear() -> void:
	set_object_frameset_ptr(FRAMESET_69E1F if hdir() else FRAMESET_69E0E)
	set_cur(OBJ_STATE_DURATION, 70)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_DISAPPEAR & 0xFFFF)
	wBossState = BOSS_NONE


## .Main: no actions. Wario transformed, it leaves. Hit by a launched Kuri (OBJSTATE $08, $09): hurt
## ($38, 60 frames), a hit taken (substate and wWolfenbossRemainingHits, never the last one's count
## below 1); hurt, it sinks half a pixel a frame below 41 frames, then (collisions back) rises (OBJ_VAR_1
## 4). Any other state is cleared; then by OBJ_VAR_1: moving (0), attacking (1), waiting (2), turning
## (3), rising after the hurt (4).
func wolfenboss_main() -> void:
	_no_actions()
	if wTransformation != 0:
		_wolfenboss_start_disappear()
		return
	var kind: int = cur(OBJ_STATE) & 0xFE
	if kind == 0x08:
		set_cur(OBJ_STATE, 0x38)
		set_object_frameset_ptr(FRAMESET_69E8E if hdir() else FRAMESET_69E85)
		set_cur(OBJ_STATE_DURATION, 60)
		if (cur(OBJ_SUBSTATE) & 0x0F) - 1 == 0:
			return
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) - 1)
		wram1[W_WOLFENBOSS_REMAINING_HITS] = byte(wram1[W_WOLFENBOSS_REMAINING_HITS] - 1)
		return
	if kind == 0x38:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		var left: int = cur(OBJ_STATE_DURATION)
		if left == 0:
			set_cur(OBJ_STATE_DURATION, 40)
			set_cur(OBJ_VAR_1, 4)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
			set_cur(OBJ_STATE, 0)
			set_object_frameset_ptr(FRAMESET_69E1F if hdir() else FRAMESET_69E0E)
		elif left < 41:
			move_object_down_slow()
		return  # SFX_0A9 at 41 not simulated
	set_cur(OBJ_STATE, 0)
	match cur(OBJ_VAR_1):
		0:
			_wolfenboss_move()
		1:
			_wolfenboss_attack()
		2:
			_wolfenboss_wait_then_move()
		3:
			_wolfenboss_turning()
		4:
			move_object_up_slow()
			if cur(OBJ_FRAMESET_OFFSET) == 4 and cur(OBJ_FRAME_DURATION) == 0 and (cur(OBJ_SUBSTATE) & 0x0F) == 1:
				_wolfenboss_defeated()
				return
			_wolfenboss_wait_then_move()


func _wolfenboss_wait_then_move() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_wolfenboss_start_movement()


## .start_movement: moving (OBJ_VAR_1 0) the way it faces.
func _wolfenboss_start_movement() -> void:
	set_cur(OBJ_VAR_1, 0)
	set_object_frameset_ptr(FRAMESET_69DE7 if hdir() else FRAMESET_69DEC)


## .do_attack: the spiral 16 frames into its 103 (or the Igaguri into its 72; ObjParams_MagicSpiral*,
## _Igaguri*, by wWolfenbossNextAttack and the way it faces); at the end 19 frames' wait (OBJ_VAR_1 2).
func _wolfenboss_attack() -> void:
	var igaguri: bool = wram1[W_WOLFENBOSS_NEXT_ATTACK] != 0
	var spawn_at: int = 72 - 16 if igaguri else 103 - 16
	var left: int = cur(OBJ_STATE_DURATION)
	if left == spawn_at:
		set_cur(OBJ_STATE_DURATION, left - 1)
		if hdir():
			create_object_at_relative_pos(OBJ_PARAMS_IGAGURI_RIGHT if wram1[W_WOLFENBOSS_NEXT_ATTACK] == 1
					else OBJ_PARAMS_MAGIC_SPIRAL_RIGHT)
		else:
			create_object_at_relative_pos(OBJ_PARAMS_IGAGURI_LEFT if wram1[W_WOLFENBOSS_NEXT_ATTACK] == 1
					else OBJ_PARAMS_MAGIC_SPIRAL_LEFT)
		return
	set_cur(OBJ_STATE_DURATION, left - 1)
	if left - 1 != 0:
		return
	set_cur(OBJ_STATE_DURATION, 19)
	set_cur(OBJ_VAR_1, 2)
	set_object_frameset_ptr(FRAMESET_69E00 if hdir() else FRAMESET_69DFB)


## .turning: hovering (Data_604c0, looping) through the turn's frames; turned, an attack if Wario was
## behind it (OBJ_VAR_2), otherwise moving.
func _wolfenboss_turning() -> void:
	apply_obj_y_movement_loop(DATA_604C0)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_hdir(not hdir())
	if cur(OBJ_VAR_2) == 0:
		_wolfenboss_start_movement()
		return
	set_cur(OBJ_VAR_2, 0)
	_wolfenboss_start_attack(FRAMESET_69DF6 if hdir() else FRAMESET_69DF1)


## .do_movement: hovering (Data_604c0, looping; SFX_0C3 not simulated) half a pixel a frame across
## the screen, turning at x $18 and $98; when wGlobalCounter comes round to 0 it attacks Wario in
## front, or turns to him (OBJ_VAR_2 1).
func _wolfenboss_move() -> void:
	apply_obj_y_movement_loop(DATA_604C0)
	var x: int = cur(OBJ_SCREEN_X_POS)
	if hdir():
		if wGlobalCounter != 0:
			if x != 0x98:
				move_object_right_slow()
				return
		elif wWarioScreenXPos >= x:
			_wolfenboss_start_attack(FRAMESET_69DF6)
			return
		else:
			set_cur(OBJ_VAR_2, 1)
		_wolfenboss_start_turning(FRAMESET_69DDE)
	else:
		if wGlobalCounter != 0:
			if x != 0x18:
				move_object_left_slow()
				return
		elif x >= wWarioScreenXPos:
			_wolfenboss_start_attack(FRAMESET_69DF1)
			return
		else:
			set_cur(OBJ_VAR_2, 1)
		_wolfenboss_start_turning(FRAMESET_69DD5)


func _wolfenboss_start_turning(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 27)
	set_cur(OBJ_VAR_1, 3)


## .start_attack: a spiral while wWolfenbossConsecutiveSpirals lasts or an Igaguri or Kuri is out;
## otherwise an Igaguri (marked out).
func _wolfenboss_start_attack(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	var igaguri: bool = false
	if wram1[W_WOLFENBOSS_CONSECUTIVE_SPIRALS] != 0:
		wram1[W_WOLFENBOSS_CONSECUTIVE_SPIRALS] -= 1
	elif wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] == 0:
		wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] = 1
		igaguri = true
	set_cur(OBJ_STATE_DURATION, 72 if igaguri else 103)
	set_cur(OBJ_VAR_1, 1)
	wram1[W_WOLFENBOSS_NEXT_ATTACK] = 1 if igaguri else 0


## .defeated: falling (.DefeatFall), its substate only HDIR, OBJ_VAR_3 cleared, PRIORITY (the music's
## stop not simulated).
func _wolfenboss_defeated() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_DEFEAT_FALL & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAG_HDIR)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_object_frameset_ptr(FRAMESET_69E05)


## .DefeatFall: along Data_60da0 (SFX_0A3 not simulated) until it is $c0 down the screen; then the
## boss defeated (wBossState, wIsBossBattle off; the music not simulated), gone for good (Func_56326),
## and its platform (the first active WOLFENBOSS_PLATFORM) given state $2f to open.
func wolfenboss_defeat_fall() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) < 0xC0:
		apply_obj_y_movement(DATA_60DA0)
		return
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0
	func_56326()
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if wram1[base + OBJ_ID] == WOLFENBOSS_PLATFORM and (wram1[base + OBJ_FLAGS] & OBJFLAG_ACTIVE) != 0:
			wram1[base + OBJ_STATE] = 0x2F
			return


# --- The magic spiral (objects/wolfenboss.asm) ----------------------------------------------------

## MagicSpiralFunc: no collision with objects (SFX_0C2 not simulated), growing.
func magic_spiral_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, MAGIC_SPIRAL_GROW & 0xFFFF)
	magic_spiral_grow()


## .Grow: no actions, growing (framesets at 69 and 38 frames left); then moving (8 frames).
func magic_spiral_grow() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		set_cur(OBJ_STATE_DURATION, 8)
		set_cur_word(OBJ_UPDATE_FUNCTION, MAGIC_SPIRAL_MOVE & 0xFFFF)
	elif left == 69:
		set_object_frameset_ptr(FRAMESET_69E39)
	elif left == 38:
		set_object_frameset_ptr(FRAMESET_69E42)


## .Move: (SFX_07C as its 8 frames run out not simulated) Wario transformed, it vanishes; at the
## battle's last hit it is gone. A pixel a frame up or down (turning below screen row 24 and from
## row 144) and across (turning at x 16 and 160), each turn counting down its substate's low bits;
## at 0 it vanishes.
func magic_spiral_move() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if wTransformation != 0:
		_magic_spiral_vanish()
		return
	if wram1[W_WOLFENBOSS_REMAINING_HITS] - 1 == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	var y: int = cur(OBJ_SCREEN_Y_POS)
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0:
		if y < SCREEN_HEIGHT_PX:
			move_object_down()
		else:
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_VDIR)
			_magic_spiral_reflect()
	elif y >= 24:
		move_object_up()
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_VDIR)
		_magic_spiral_reflect()
	var x: int = cur(OBJ_SCREEN_X_POS)
	if hdir():
		if x < SCREEN_WIDTH_PX:
			move_object_right()
			return
		set_hdir(false)
	else:
		if x >= 16:
			move_object_left()
			return
		set_hdir(true)
	_magic_spiral_reflect()


## .reflect: one bounce fewer (the whole substate decremented); none left, it vanishes.
func _magic_spiral_reflect() -> void:
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) - 1)
	if (cur(OBJ_SUBSTATE) & 0x0F) == 0:
		_magic_spiral_vanish()


## .disappear: its vanishing frameset, 27 frames, no actions.
func _magic_spiral_vanish() -> void:
	set_object_frameset_ptr(FRAMESET_69EB2)
	set_cur(OBJ_STATE_DURATION, 27)
	set_cur_word(OBJ_UPDATE_FUNCTION, MAGIC_SPIRAL_DISAPPEAR & 0xFFFF)
	_no_actions()


## .Disappear: then gone.
func magic_spiral_disappear() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- The Igaguri and the Kuri (objects/wolfenboss.asm) ----------------------------------------------

## IgaguriFunc: no actions while it grows (SFX_06B every 8 frames not simulated; framesets at 43 and
## 24 frames left); then falling (40 frames, three bounces, speed 2, or 1 thrown up at the last hit;
## SFX_101 or SFX_067 not simulated).
func igaguri_func() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 43:
		set_object_frameset_ptr(FRAMESET_69E80)
		return
	if left == 24:
		set_object_frameset_ptr(FRAMESET_69E4B)
		return
	if left != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, IGAGURI_FALL & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69E4B)
	set_cur(OBJ_STATE_DURATION, 40)
	set_cur(OBJ_VAR_1, 3)
	set_cur(OBJ_VAR_2, 2 if wram1[W_WOLFENBOSS_REMAINING_HITS] >= 3 else 1)
	set_cur(OBJ_VAR_3, 0)


## .Fall: (no actions while Wario is transformed) its frame held; 4 px a frame down (thrown up along
## Data_60d80 at the last hit) to a floor (Func_352b), drifting across; landed, the ground shakes
## (24; SFX_061 not simulated) and it hatches, or at the last hit bounces toward Wario.
func igaguri_fall() -> void:
	if wTransformation != 0:
		_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	var last_hit: bool = wram1[W_WOLFENBOSS_REMAINING_HITS] < 3
	if last_hit:
		apply_obj_y_movement(DATA_60D80)
	else:
		set_cur_word(OBJ_Y_POS, cur_y() + 4)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		_igaguri_drift()
		return
	store_object_y_from_hpos()
	_igaguri_ground_shake()
	if not last_hit:
		_igaguri_hatch_start()
		return
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, IGAGURI_BOUNCE & 0xFFFF)


## .do_horizontal_movement: OBJ_VAR_2 across, turning at x 16 and 160 (that frame without moving).
func _igaguri_drift() -> void:
	var x: int = cur(OBJ_SCREEN_X_POS)
	if hdir():
		if x < SCREEN_WIDTH_PX:
			move_object_right_by_var2()
		else:
			set_hdir(false)
	elif x >= 0x10:
		move_object_left_by_var2()
	else:
		set_hdir(true)


## .ground_shake: DoGroundShake 24.
func _igaguri_ground_shake() -> void:
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 24
		wIsWarioGroundShaking = 0


## .skip_bounce: hatching.
func _igaguri_hatch_start() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, IGAGURI_HATCH & 0xFFFF)
	set_cur(OBJ_VAR_1, 0)


## .Bounce: its frame held, along Data_60e00, drifting; at each landing the ground shakes, and after
## its bounces it hatches.
func igaguri_bounce() -> void:
	if wTransformation != 0:
		_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	apply_obj_y_movement(DATA_60E00)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		_igaguri_drift()
		return
	store_object_y_from_hpos()
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) == 0:
		_igaguri_hatch_start()
		return
	set_cur(OBJ_VAR_3, 0)
	_igaguri_ground_shake()


## .Hatch, by OBJ_VAR_1: its frame held out OBJ_STATE_DURATION (0), shaking 60 frames (1; SFX_0C5 not
## simulated), opening 14 frames (2: the Kuri at 5 left, ObjParams_Kuri; SFX_0C4 not simulated),
## then gone.
func igaguri_hatch() -> void:
	if wTransformation != 0:
		_no_actions()
	match cur(OBJ_VAR_1):
		0:
			set_cur(OBJ_FRAME_DURATION, 2)
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE_DURATION, 60)
				set_cur(OBJ_VAR_1, 1)
		1:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE_DURATION, 14)
				set_cur(OBJ_VAR_1, 2)
				set_object_frameset_ptr(FRAMESET_69E59)
		2:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_FLAGS, 0)
			elif cur(OBJ_STATE_DURATION) == 5:
				create_object_from_cur_obj_pos(OBJ_PARAMS_KURI)


## KuriFunc: no actions, dropping along Data_60d60 to a floor (Func_352b); landed, walking away from
## Wario.
func kuri_func() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60D60)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	store_object_y_from_hpos()
	set_cur_word(OBJ_UPDATE_FUNCTION, KURI_LANDED & 0xFFFF)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A))


## .Landed: (no actions while Wario is transformed) by OBJ_STATE: bumped from behind it turns, from
## the front walks on; touched it vanishes (one Igaguri or Kuri fewer); attacked it is launched; any
## other state turns it. Walking: a pixel a frame, turning at x 16 and 160; off screen it is gone
## (SFX_06A not simulated).
func kuri_landed() -> void:
	if wTransformation != 0:
		_no_actions()
	var state: int = cur(OBJ_STATE)
	if state != 0:
		match state:
			OBJSTATE_BUMP_LEFT_START, OBJSTATE_BUMP_RIGHT_START:
				if hdir() == (state == OBJSTATE_BUMP_RIGHT_START):
					set_hdir(not hdir())
			OBJSTATE_VANISH_TOUCH:
				_kuri_vanish()
				return
			OBJSTATE_ATTACKED_LEFT_START, OBJSTATE_ATTACKED_RIGHT_START:
				set_hdir(state == OBJSTATE_ATTACKED_LEFT_START)
				set_cur(OBJ_STATE, 0)
				set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)
				set_cur(OBJ_VAR_2, 3)
				set_cur_word(OBJ_UPDATE_FUNCTION, KURI_LAUNCHED & 0xFFFF)
				set_object_frameset_ptr(FRAMESET_69E60)
				return
			_:
				set_hdir(not hdir())
		set_cur(OBJ_STATE, 0)
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	var x: int = cur(OBJ_SCREEN_X_POS)
	if hdir():
		if x < SCREEN_WIDTH_PX:
			move_object_right()
		else:
			set_hdir(false)
	elif x >= 0x10:
		move_object_left()
	else:
		set_hdir(true)


## .vanish: one Igaguri or Kuri fewer (wWolfenbossIgaguriOrKuriActive), VanishObject2.
func _kuri_vanish() -> void:
	wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] = byte(wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] - 1)
	vanish_object()


## .Launched: no actions; knocked ($28, $29) it vanishes; 2 px up a frame and OBJ_VAR_2 across,
## turning at x 16 and 160 (SFX_01A not simulated); off screen it is gone (one fewer out).
func kuri_launched() -> void:
	_no_actions()
	if (cur(OBJ_STATE) & 0xFE) == 0x28:
		_kuri_vanish()
		return
	set_cur_word(OBJ_Y_POS, cur_y() - 2)  # MoveObjectUp_Fast
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		set_cur(OBJ_FLAGS, 0)
		wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] = byte(wram1[W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] - 1)
		return
	var x: int = cur(OBJ_SCREEN_X_POS)
	if hdir():
		if x < SCREEN_WIDTH_PX:
			move_object_right_by_var2()
			return
		set_hdir(false)
	elif x >= 0x10:
		move_object_left_by_var2()
		return
	else:
		set_hdir(true)


# --- Doll Boy (objects/doll_boy.asm) ----------------------------------------------------------------

## DollBoyFunc: the battle on (wIsBossBattle), visible, its parts (5, the doll and three barrels
## plus one) in the substate, facing right, a box -12..11 (top -28, bottom 0), 40 frames' wait.
func doll_boy_func() -> void:
	wIsBossBattle = 1
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	var substate: int = cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & OBJSUBFLAGS_MASK
	set_cur(OBJ_SUBSTATE, substate | 5 | OBJSUBFLAG_HDIR)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_INIT & 0xFFFF)
	set_collbox_x(-12, 11)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_cur(OBJ_COLLBOX_TOP, -28)
	set_object_frameset_ptr(FRAMESET_69632)
	set_cur(OBJ_STATE_DURATION, 40)


## .Init: on screen, after its frames: the barrel phase, no barrel flashing yet, all three barrels
## up, wBossState BOSS_REGULAR (the music not simulated).
func doll_boy_init() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_BARREL_PHASE & 0xFFFF)
	wram1[W_DOLL_BOY_NO_FLASHING_BARREL] = 1
	set_cur(OBJ_VAR_1, 0)
	wram1[W_DOLL_BOY_FALL_IMMEDIATELY_MIDDLE_BARREL] = 0
	wram1[W_DOLL_BOY_HAMMER_RANGE] = 0
	wram1[W_DOLL_BOY_ACTIVE_BARRELS] = DOLLBOY_BARREL1 | DOLLBOY_BARREL2 | DOLLBOY_BARREL3
	wBossState = BOSS_REGULAR


## .BarrelPhase, by OBJ_VAR_1: waiting (0), throwing a hammer (1), a barrel under it knocked out (8,
## then falling: 9).
func doll_boy_barrel_phase() -> void:
	match cur(OBJ_VAR_1):
		0:
			_doll_boy_barrel_wait()
		1:
			_doll_boy_throw_hammer()
		8:
			set_object_frameset_ptr(FRAMESET_69632)
			set_cur(OBJ_VAR_1, 9)
			set_cur(OBJ_VAR_3, 0)
			_doll_boy_fall()
		9:
			_doll_boy_fall()


## .fall: down to the next barrel (or the floor), along a table by how far: one barrel's height
## (Data_60880), two (Data_60b80, after a wait) or three (Data_60ba0, a longer one); landing (its
## frameset) and the ground shaking (DollBoyGroundShake) at set frames, then still.
func _doll_boy_fall() -> void:
	var parts: int = cur(OBJ_SUBSTATE) & 0x0F
	var barrels: int = wram1[W_DOLL_BOY_ACTIVE_BARRELS]
	var table: int = DATA_60880
	var land: int = 2
	if parts == 4 and barrels == DOLLBOY_BARREL1 | DOLLBOY_BARREL2:
		wram1[W_DOLL_BOY_FALL_IMMEDIATELY_MIDDLE_BARREL] = 1
		table = DATA_60BA0
		land = 34
	elif (parts == 4 and barrels == DOLLBOY_BARREL1 | DOLLBOY_BARREL3) \
			or (parts == 3 and barrels == DOLLBOY_BARREL1) \
			or (parts == 3 and barrels != DOLLBOY_BARREL3 and wram1[W_DOLL_BOY_FALL_IMMEDIATELY_MIDDLE_BARREL] == 0):
		table = DATA_60B80
		land = 18
	var step: int = cur(OBJ_VAR_3)
	if step == land:
		set_object_frameset_ptr(FRAMESET_69646)
	elif step == land + 8:
		doll_boy_ground_shake()
	elif step == land + 12:
		set_object_frameset_ptr(FRAMESET_69632)
		set_cur(OBJ_VAR_1, 0)
		return
	apply_obj_y_movement(table)


## DollBoyGroundShake: DoGroundShake 24 (SFX_061 not simulated).
func doll_boy_ground_shake() -> void:
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 24
		wIsWarioGroundShaking = 0


## .throw_hammer: (its parts updated first) at $13 frames left a hammer of the next range
## (ObjParams_DollBoyHammer; ranges 1-4 in turn; SFX_0A2 not simulated); at the end waiting again.
func _doll_boy_throw_hammer() -> void:
	update_doll_boy_remaining_parts()
	if cur(OBJ_VAR_1) == 8:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		set_object_frameset_ptr(FRAMESET_69632)
		set_cur(OBJ_VAR_1, 0)
		return
	if left != 0x13:
		return
	if wram1[W_DOLL_BOY_HAMMER_RANGE] == HAMMER_LONG:
		wram1[W_DOLL_BOY_HAMMER_RANGE] = 0
	wram1[W_DOLL_BOY_HAMMER_RANGE] += 1
	create_object_at_relative_pos(OBJ_PARAMS_DOLL_BOY_HAMMER)


## .check_if_wario_is_bouncy: Bouncy Wario ends it (.DoNothing, wBossState NONE). Down to the doll
## (substate 2 and HDIR exactly), the walking phase after 80 frames, harmless till then
## (OBJ_INTERACTION_0B). Otherwise (its parts updated) a hammer when rDIV is 250 or more (56
## frames).
func _doll_boy_barrel_wait() -> void:
	if wTransformation == TRANSFORMATION_BOUNCY_WARIO:
		set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_DO_NOTHING & 0xFFFF)
		wBossState = BOSS_NONE
		return
	if cur(OBJ_SUBSTATE) == 2 | OBJSUBFLAG_HDIR:
		set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_INIT_WALKING_PHASE & 0xFFFF)
		set_interaction(OBJ_INTERACTION_0B)
		set_cur(OBJ_STATE_DURATION, 80)
		return
	update_doll_boy_remaining_parts()
	if cur(OBJ_VAR_1) == 8:
		return
	if read_div(DIV_DOLL_BOY) < DOLLBOY_THROW_HAMMER_ODDS:
		return
	set_object_frameset_ptr(FRAMESET_6963B)
	set_cur(OBJ_STATE_DURATION, 56)
	set_cur(OBJ_VAR_1, 1)


## UpdateDollBoyRemainingParts: unless its substate is 1, a part (its ID's low nibble) gone from
## wDollBoyRemainingParts is taken off: OBJ_VAR_1 8 (falling) and one fewer in the substate.
func update_doll_boy_remaining_parts() -> void:
	if cur(OBJ_SUBSTATE) == 1:
		return
	var part: int = cur(OBJ_ID) & 0x0F
	var parts: int = wram1[W_DOLL_BOY_REMAINING_PARTS]
	if (parts & part) == 0:
		return
	wram1[W_DOLL_BOY_REMAINING_PARTS] = parts & ~part & 0xFF
	set_cur(OBJ_VAR_1, 8)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) - 1)


## .InitWalkingPhase: then walking (state and OBJ_VAR_1 cleared; the green palettes are presentation).
func doll_boy_init_walking_phase() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_6964D)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_WALKING_PHASE & 0xFFFF)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_VAR_1, 0)


## .WalkingPhase: harmful (OBJ_INTERACTION_01); by OBJ_STATE: walking (0), jumping to the platform
## below or above ($5a, $5b), stunned ($5c), bumped ($02, $03, then $32, $33), hitting Wario with
## its hammer ($0b, $0c: stars, the battle over). Hit (OBJSTATE $08, $09) or anything while not
## stunned stuns it (120 frames); attacked while stunned ($04, $05) it is defeated.
func doll_boy_walking_phase() -> void:
	set_interaction(OBJ_INTERACTION_01)
	var state: int = cur(OBJ_STATE)
	match state:
		0:
			_doll_boy_walk()
		0x5A, 0x5B:
			_doll_boy_jump(DATA_60890 if state == 0x5A else DATA_608A0)
		0x5C:
			_doll_boy_stunned()
		0x02, 0x03:
			set_cur(OBJ_STATE, 0x30 + state)
			set_cur(OBJ_STATE_DURATION, 12)
			set_cur(OBJ_VAR_2, 2)
		0x32:
			obj_state_bump_left()
		0x33:
			obj_state_bump_right()
		0x0B, 0x0C:
			_doll_boy_hit_wario_start(state == 0x0B)
		_:
			match state & 0xFE:
				0x08:
					_doll_boy_stun()
				0x04:
					if cur(OBJ_VAR_1) != 0xFF:
						_doll_boy_stun()
					else:
						_doll_boy_defeat()
				_:
					if cur(OBJ_VAR_1) == 0xFF:
						_doll_boy_stun()
					else:
						set_cur(OBJ_STATE_DURATION, 1)
						_doll_boy_stunned()


## .show_stars_left/_right: its hammer hit Wario: stars (ObjParams_DollBoyHammerStars*), the battle
## over (wBossState NONE; the sound's stop not simulated), and .HitWario.
func _doll_boy_hit_wario_start(left: bool) -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_HIT_WARIO & 0xFFFF)
	set_cur(OBJ_VAR_3, 0)
	wBossState = BOSS_NONE
	set_object_frameset_ptr(FRAMESET_696B9 if left else FRAMESET_696B6)
	set_cur(OBJ_STATE_DURATION, 1)
	create_object_at_relative_pos(OBJ_PARAMS_DOLL_BOY_HAMMER_STARS_LEFT if left else OBJ_PARAMS_DOLL_BOY_HAMMER_STARS_RIGHT)


## .set_stunned: stunned ($5c, 120 frames; OBJ_VAR_1 $ff; SFX_0A4 and the red palettes not simulated).
func _doll_boy_stun() -> void:
	set_cur(OBJ_STATE, 0x5C)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_69675 if hdir() else FRAMESET_6967A)
	set_cur(OBJ_STATE_DURATION, 120)
	set_cur(OBJ_VAR_1, 0xFF)


## .update_stunned: falling (FallingYVel_Light) to a floor (Func_352b); there its frames, then walking
## on, toward Wario (turning first, 32 frames, if he is behind it).
func _doll_boy_stunned() -> void:
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		apply_obj_y_movement(FALLING_Y_VEL_LIGHT)
		return
	store_object_y_from_hpos()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return  # the green palettes at 10 are presentation
	set_cur(OBJ_STATE, 0)
	var wario_right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	var frameset: int
	var turn: int
	if hdir():
		frameset = FRAMESET_6964D if wario_right else FRAMESET_6965F
		turn = 0 if wario_right else 32
	else:
		frameset = FRAMESET_6966A if wario_right else FRAMESET_69656
		turn = 32 if wario_right else 0
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, turn)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_3, 0)


## .asm_50de0: attacked while stunned: defeated ($48, 43 frames, its routine bits cleared,
## PRIORITY, its object-map nibble 5; the music's stop not simulated).
func _doll_boy_defeat() -> void:
	set_cur(OBJ_STATE, 0x48)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE_DURATION, 43)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_DEFEATED & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur_object_map_nibble(0x05)
	set_object_frameset_ptr(FRAMESET_6967F)


## .jump_platform_below/_above: after OBJ_STATE_DURATION frames, along `table`, the ground shaking
## at its 10th step; OBJ_VAR_1 frames on, walking again ($3c frames before the next jump).
func _doll_boy_jump(table: int) -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	apply_obj_y_movement(table)
	if cur(OBJ_VAR_3) == 0x0A:
		doll_boy_ground_shake()
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	set_cur(OBJ_VAR_1, 0x3C)
	set_cur(OBJ_STATE, 0)


## .switch_direction (OBJSTATE 0): turning (OBJ_STATE_DURATION frames: a hop along Data_60c00, turned
## at its $17th step with the ground shaking, then its walking frameset); otherwise, OBJ_VAR_1
## frames after a jump, a jump to Wario's platform below or above (from x $18-$77, Wario below
## screen row $28 and it above $a0, at least 32 rows apart); otherwise walking.
func _doll_boy_walk() -> void:
	var turning: int = cur(OBJ_STATE_DURATION)
	if turning != 0:
		set_cur(OBJ_STATE_DURATION, turning - 1)
		if turning - 1 == 0:
			set_object_frameset_ptr(FRAMESET_6964D if hdir() else FRAMESET_69656)
			return
		if cur(OBJ_VAR_3) == 0x17:
			set_hdir(not hdir())
			doll_boy_ground_shake()
		apply_obj_y_movement(DATA_60C00)
		return
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		_doll_boy_walk_step()
		return
	var x: int = cur(OBJ_SCREEN_X_POS)
	var y: int = cur(OBJ_SCREEN_Y_POS)
	if x >= 0x78 or x < 0x18 or wWarioScreenYPos < 0x28 or y >= 0xA0:
		_doll_boy_walk_step()
		return
	var jump: int
	if y >= wWarioScreenYPos:
		if y - wWarioScreenYPos < 0x20:
			_doll_boy_walk_step()
			return
		jump = 0x5B
	else:
		if byte(y - wWarioScreenYPos) >= byte(-0x1F):
			_doll_boy_walk_step()
			return
		jump = 0x5A
	set_cur(OBJ_STATE, jump)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_1, 0x1E)
	set_cur(OBJ_STATE_DURATION, 20)


## .handle_walk_movement: a wall 4 px up ahead (11 px right, 12 left; Func_3513) turns it (32
## frames); otherwise from its frameset's third pair on it steps a pixel, bouncy to Wario
## (OBJ_INTERACTION_BOUNCY; SFX_0A2 not simulated).
func _doll_boy_walk_step() -> void:
	var right: bool = hdir()
	set_hpos_from_object(-4, 11 if right else -12)
	if object_probe(COLLISION_UNK4) != 0:
		set_object_frameset_ptr(FRAMESET_6965F if right else FRAMESET_6966A)
		set_cur(OBJ_STATE_DURATION, 32)
		set_cur(OBJ_VAR_3, 0)
		return
	if cur(OBJ_FRAMESET_OFFSET) < 6:
		return
	set_interaction(OBJ_INTERACTION_BOUNCY)
	if right:
		move_object_right()
	else:
		move_object_left()


## .HitWario: no actions; falling (FallingYVel_Light) to a floor, then 60 frames' wait (SFX_049 not
## simulated).
func doll_boy_hit_wario() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		apply_obj_y_movement(FALLING_Y_VEL_LIGHT)
		return
	store_object_y_from_hpos()
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_WAIT_THEN_DO_NOTHING & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 60)


## .WaitThenDoNothing: then still for good.
func doll_boy_wait_then_do_nothing() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_DO_NOTHING & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69695 if hdir() else FRAMESET_6969A)


## .Defeated: no actions; along Data_60bd0 until screen row $d0 (the red palettes at 27 and the
## sounds not simulated); then gone, the boss defeated (wBossState, wIsBossBattle off), the ground
## shaking.
func doll_boy_defeated() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) >= 0xD0:
		set_cur(OBJ_FLAGS, 0)
		wBossState = BOSS_DEFEATED
		wIsBossBattle = 0
		doll_boy_ground_shake()
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	apply_obj_y_movement(DATA_60BD0)


# --- Doll Boy's barrels (objects/doll_boy.asm) -----------------------------------------------------

## DollBoyBarrel1Func to _3Func: the substate set to 3, 2, or 1 (the whole byte), visible, kept
## (OBJSUBFLAG_UNK_4), its frameset, a box -8..7 (bottom 0); waiting to start.
func doll_boy_barrel_1_func() -> void:
	_doll_boy_barrel(3)


func doll_boy_barrel_2_func() -> void:
	_doll_boy_barrel(2)


func doll_boy_barrel_3_func() -> void:
	_doll_boy_barrel(1)


func _doll_boy_barrel(substate: int) -> void:
	set_cur(OBJ_SUBSTATE, substate)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_BARREL_START_DELAY & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_6969F)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_cur(OBJ_VAR_1, 0)


## .StartDelay: its frame held until a barrel may flash (wDollBoyNoFlashingBarrel), then .Main.
func doll_boy_barrel_start_delay() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	if wram1[W_DOLL_BOY_NO_FLASHING_BARREL] == 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_BARREL_MAIN & 0xFFFF)


## .Main, by OBJ_VAR_1: still (0), about to flash (1), flashing (2), a barrel under it knocked out
## (8, then falling: 9).
func doll_boy_barrel_main() -> void:
	match cur(OBJ_VAR_1):
		0:
			_doll_boy_barrel_still()
		1:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				return
			set_object_frameset_ptr(FRAMESET_696A8)
			set_cur(OBJ_STATE_DURATION, 240)
			set_cur(OBJ_VAR_1, 2)
			set_cur(OBJ_STATE, 0)
		2:
			_doll_boy_barrel_flashing()
		8:
			set_cur(OBJ_VAR_1, 9)
			set_cur(OBJ_VAR_3, 0)
			_doll_boy_barrel_fall()
		9:
			_doll_boy_barrel_fall()


## .fall: down a barrel's height (Data_60880), or the top barrel with the bottom one gone after a
## wait (Data_60b80); the ground shaking at a set step, then still.
func _doll_boy_barrel_fall() -> void:
	var delayed: bool = cur(OBJ_ID) == DOLL_BOY_BARREL1 \
			and wram1[W_DOLL_BOY_ACTIVE_BARRELS] == DOLLBOY_BARREL1 | DOLLBOY_BARREL2
	var step: int = cur(OBJ_VAR_3)
	if step == (0x1A if delayed else 0x0A):
		doll_boy_ground_shake()
	elif step == (0x1E if delayed else 0x0E):
		set_cur(OBJ_VAR_1, 0)
		return
	apply_obj_y_movement(DATA_60B80 if delayed else DATA_60880)


## .not_flashing: (its part updated) on its quarter of the frames, while no barrel flashes: the last
## barrel, or one off Wario's level by 8 rows or more, starts flashing after 70-73 frames (rDIV).
func _doll_boy_barrel_still() -> void:
	update_doll_boy_remaining_parts()
	if cur(OBJ_VAR_1) == 8:
		return
	if (wGlobalCounter & 3) != (cur(OBJ_ID) & 3):
		return
	if wram1[W_DOLL_BOY_NO_FLASHING_BARREL] == 0:
		return
	var barrels: int = wram1[W_DOLL_BOY_ACTIVE_BARRELS]
	if barrels != DOLLBOY_BARREL1 and barrels != DOLLBOY_BARREL2 and barrels != DOLLBOY_BARREL3:
		var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
		if dy < 8 or dy >= 0xF8:
			return
	wram1[W_DOLL_BOY_NO_FLASHING_BARREL] = 0
	set_cur(OBJ_STATE_DURATION, 70 + (read_div(DIV_DOLL_BOY_BARREL) & 3))
	set_cur(OBJ_VAR_1, 1)


## .flashing: Bouncy Wario stops it; attacked from the left ($05) it is knocked out (Func_3317, its
## part gone from wDollBoyActiveBarrels and the parts left set for the others; SFX_017 not
## simulated); otherwise after its 240 frames it is still again (SFX_06A not simulated).
func _doll_boy_barrel_flashing() -> void:
	if wTransformation == TRANSFORMATION_BOUNCY_WARIO:
		set_cur(OBJ_STATE_DURATION, 0)
	elif cur(OBJ_STATE) == 0x05:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
		set_cur(OBJ_VAR_3, 0)
		set_cur(OBJ_VAR_2, 1)
		set_object_frameset_ptr(FRAMESET_6969F)
		set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_3317)
		var id: int = cur(OBJ_ID)
		var barrels: int = wram1[W_DOLL_BOY_ACTIVE_BARRELS]
		if id == DOLL_BOY_BARREL1:
			wram1[W_DOLL_BOY_ACTIVE_BARRELS] = barrels & ~DOLLBOY_BARREL1
			wram1[W_DOLL_BOY_REMAINING_PARTS] = DOLLBOY_DOLL
		elif id == DOLL_BOY_BARREL2:
			wram1[W_DOLL_BOY_ACTIVE_BARRELS] = barrels & ~DOLLBOY_BARREL2
			wram1[W_DOLL_BOY_REMAINING_PARTS] = DOLLBOY_BARREL1 | DOLLBOY_DOLL
		else:
			wram1[W_DOLL_BOY_ACTIVE_BARRELS] = barrels & ~DOLLBOY_BARREL3
			wram1[W_DOLL_BOY_REMAINING_PARTS] = DOLLBOY_BARREL1 | DOLLBOY_BARREL2 | DOLLBOY_DOLL
		wram1[W_DOLL_BOY_NO_FLASHING_BARREL] = 1
		return
	else:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			return
	set_cur(OBJ_VAR_1, 0)
	set_object_frameset_ptr(FRAMESET_6969F)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_BARREL_MAIN & 0xFFFF)
	wram1[W_DOLL_BOY_NO_FLASHING_BARREL] = 1


# --- Doll Boy's hammers and the hammer platforms (objects/doll_boy.asm) -----------------------------

## DollBoyHammerFunc: no collision with objects; .Init next.
func doll_boy_hammer_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_HAMMER_INIT & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .Init: .Update; thrown from up to 20 rows above Wario's level (or below it) it flies straight
## right (OBJ_VAR_1).
func doll_boy_hammer_init() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, DOLL_BOY_HAMMER_UPDATE & 0xFFFF)
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy >= 0xEC:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)


## .Update: given a state, it is hit (stars, ObjParams_StarsCentre; knocked away from Wario; SFX_049
## not simulated). Otherwise 2 px a frame right, or along its arc (Data_60860) and its range's
## table (Data_60ae0, _60b00, _60b30, _60b60 by wDollBoyHammerRange).
func doll_boy_hammer_update() -> void:
	if cur(OBJ_STATE) != 0:
		var left: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
		set_cur_word(OBJ_UPDATE_FUNCTION, (DOLL_BOY_HAMMER_HIT_LEFT if left else DOLL_BOY_HAMMER_HIT_RIGHT) & 0xFFFF)
		set_cur(OBJ_VAR_3, 0)
		create_object_from_cur_obj_pos(OBJ_PARAMS_STARS_CENTRE)
		return
	if cur(OBJ_VAR_1) != 0:
		set_cur_word(OBJ_X_POS, cur_x() + 2)  # MoveObjectRight_Fast
		return
	apply_obj_y_movement(DATA_60860)
	match wram1[W_DOLL_BOY_HAMMER_RANGE]:
		1:
			apply_obj_x_movement(DATA_60AE0)
		2:
			apply_obj_x_movement(DATA_60B00)
		3:
			apply_obj_x_movement(DATA_60B30)
		_:
			apply_obj_x_movement(DATA_60B60)


## .HitLeft and .HitRight: a pixel a frame that way, falling along Data_60040, no actions.
func doll_boy_hammer_hit_left() -> void:
	move_object_left()
	_doll_boy_hammer_hit_fall()


func doll_boy_hammer_hit_right() -> void:
	move_object_right()
	_doll_boy_hammer_hit_fall()


func _doll_boy_hammer_hit_fall() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60040)


## HammerPlatformSpawnerFunc: kept (OBJSUBFLAG_UNK_4); after 150 frames a hammer platform
## (ObjParams_HammerPlatform), then nothing.
func hammer_platform_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_PLATFORM_SPAWNER_SPAWN & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur(OBJ_STATE_DURATION, 150)
	hammer_platform_spawner_do_nothing()


func hammer_platform_spawner_spawn() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_PLATFORM_SPAWNER_DO_NOTHING & 0xFFFF)
		create_object_at_relative_pos(OBJ_PARAMS_HAMMER_PLATFORM)
	hammer_platform_spawner_do_nothing()


## .DoNothing: its frame held, no actions.
func hammer_platform_spawner_do_nothing() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()


## HammerPlatformFunc: its start (OBJ_VAR_2 and _3: y) kept; going down.
func hammer_platform_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_PLATFORM_MOVE_DOWN & 0xFFFF)
	set_cur(OBJ_VAR_2, lo(cur_y()))
	set_cur(OBJ_VAR_3, hi(cur_y()))
	hammer_platform_move_down()


## .MoveDown: a one-way platform going down half a pixel a frame (stood on, a pixel every other frame
## with Wario); a state or its frames' end sends it up.
func hammer_platform_move_down() -> void:
	set_one_way_platform_action()
	if cur(OBJ_STATE) == 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
				move_object_down_slow()
				return
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
			if (wGlobalCounter & 1) == 0:
				return
			move_wario_down(1)
			handle_downwards_floor_transition()
			move_object_down()
			return
	set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_PLATFORM_MOVE_UP & 0xFFFF)
	set_cur(OBJ_STATE, 0)


## .MoveUp: back up the same way to its start, then down again for 140 frames.
func hammer_platform_move_up() -> void:
	set_one_way_platform_action()
	if lo(cur_y()) == cur(OBJ_VAR_2) and hi(cur_y()) == cur(OBJ_VAR_3):
		set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_PLATFORM_MOVE_DOWN & 0xFFFF)
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_STATE_DURATION, 140)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		move_object_up_slow()
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	if (wGlobalCounter & 1) == 0:
		return
	move_wario_up(1)
	handle_upwards_floor_transition()
	move_object_up()


# --- Yellow Belly (objects/yellow_belly.asm) ---------------------------------------------------------

## The first active slot whose ID is `id`, or -1.
func _active_slot_with_id(id: int) -> int:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if wram1[base + OBJ_ID] == id and (wram1[base + OBJ_FLAGS] & OBJFLAG_ACTIVE) != 0:
			return base
	return -1


func _slot_word(base: int, field: int) -> int:
	return wram1[base + field] | (wram1[base + field + 1] << 8)


## YellowBellyBodyFunc: visible, 60 frames' wait, its hits (3, plus one) in the substate, a box
## -8..7 (bottom 10), the battle's variables cleared and the battle on (the music's stop not
## simulated).
func yellow_belly_body_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_FLASH_1 & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69780)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	var substate: int = cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & 0xF0
	set_cur(OBJ_SUBSTATE, substate | 4)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 0x0A)
	wram1[W_YELLOW_BELLY_PAUSED] = 0
	wram1[W_YELLOW_BELLY_HIT] = 0
	wram1[W_YELLOW_BELLY_PUMPING] = 0
	wIsBossBattle = 1


## .Func_5139d, _513bf, _513d9: no actions; three flashes of 30 frames (palettes and SFX_0CA not
## simulated), then .Func_513fb.
func yellow_belly_flash_1() -> void:
	_yellow_belly_flash(YELLOW_BELLY_FLASH_2)


func yellow_belly_flash_2() -> void:
	_yellow_belly_flash(YELLOW_BELLY_FLASH_3)


func yellow_belly_flash_3() -> void:
	_yellow_belly_flash(YELLOW_BELLY_WAIT)


func _yellow_belly_flash(next: int) -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x1E)
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)


## .Func_513fb: then 32 frames, wBossState BOSS_REGULAR (the music not simulated).
func yellow_belly_wait() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x20)
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_RISE & 0xFFFF)
	wBossState = BOSS_REGULAR


## .Func_51419: rising half a pixel a frame; then swimming (3 or 4 laps by rDIV, speed 1), its head
## (ObjParams_YellowBellyHead).
func yellow_belly_rise() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up_slow()
		return
	set_cur(OBJ_STATE_DURATION, 3 + (read_div(DIV_YELLOW_BELLY_RISE) & 1))
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 1)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_SWIM & 0xFFFF)
	create_object_from_cur_obj_pos(OBJ_PARAMS_YELLOW_BELLY_HEAD)


func _yellow_belly_vdir() -> bool:
	return (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0


## .asm_51442: shooting next (.Func_514a4): inflated it shoots at once; otherwise it shoots facing
## Wario (OBJ_VAR_1 0, 98 frames), or turns to him first (OBJ_VAR_1 $44, VDIR and HDIR flipped).
func _yellow_belly_aim() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_SHOOT & 0xFFFF)
	if wram1[W_YELLOW_BELLY_PUMPING] != 0:
		set_cur(OBJ_VAR_1, 0)
		_yellow_belly_shoot_start()
		return
	var wario_right: bool = wWarioXPos >= cur_x()
	if wario_right == _yellow_belly_vdir():
		_yellow_belly_shoot_start()
		return
	set_object_frameset_ptr(FRAMESET_697B0 if wario_right else FRAMESET_697BB)
	set_cur(OBJ_VAR_1, 0x44)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ (OBJSUBFLAG_VDIR | OBJSUBFLAG_HDIR))


func _yellow_belly_shoot_start() -> void:
	set_object_frameset_ptr(FRAMESET_697A1 if _yellow_belly_vdir() else FRAMESET_69792)
	set_cur(OBJ_STATE_DURATION, 0x62)


## .Func_514a4: hit, it is hurt; turning, its frames then the shot; shooting, an arrow at $2f frames
## left (ObjParams_YellowBellyArrowLeft/_Right by VDIR; SFX_07C not simulated), then swimming again
## (.asm_514eb).
func yellow_belly_shoot() -> void:
	if wram1[W_YELLOW_BELLY_HIT] != 0:
		_yellow_belly_hit()
		return
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) == 0:
			_yellow_belly_shoot_start()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		_yellow_belly_swim_start()
	elif left == 0x2F:
		create_object_at_relative_pos(OBJ_PARAMS_YELLOW_BELLY_ARROW_RIGHT if _yellow_belly_vdir()
				else OBJ_PARAMS_YELLOW_BELLY_ARROW_LEFT)


## .asm_514eb: inflated, chasing its pump (.Func_515dd: 3 frames, speed 2); otherwise swimming
## (.Func_51652, PRIORITY, 3 or 4 laps by rDIV, speed 1, OBJ_VAR_3 1).
func _yellow_belly_swim_start() -> void:
	if wram1[W_YELLOW_BELLY_PUMPING] != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_CHASE_PUMP & 0xFFFF)
		set_cur(OBJ_STATE_DURATION, 3)
		set_cur(OBJ_VAR_2, 2)
		set_cur(OBJ_VAR_3, 2)
		set_cur(OBJ_STATE, 0)
		set_object_frameset_ptr(FRAMESET_69789 if _yellow_belly_vdir() else FRAMESET_69780)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_SWIM & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur(OBJ_STATE_DURATION, 3 + (read_div(DIV_YELLOW_BELLY_SWIM) & 1))
	set_cur(OBJ_VAR_2, 1)
	set_cur(OBJ_VAR_3, 1)
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_697EB if _yellow_belly_vdir() else FRAMESET_697E6)


## .asm_5154e: touched by Puffy Wario, it inflates (wYellowBellyPumping, $a6 frames; the sound's
## stop not simulated).
func _yellow_belly_inflate_start() -> void:
	wram1[W_YELLOW_BELLY_PUMPING] = 1
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_INFLATE & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_PRIORITY)
	set_cur(OBJ_VAR_1, 0xA6)
	set_object_frameset_ptr(FRAMESET_697C6)


## .Func_51572: no actions; at $25 frames left its pump comes out (ObjParams_Pump); below $92 it
## rises a pixel a frame while it is below screen row $39; at the end it swims (chasing the pump).
## Palettes and sounds are not simulated.
func yellow_belly_inflate() -> void:
	_no_actions()
	var left: int = cur(OBJ_VAR_1)
	if left == 0x25:
		create_object_from_cur_obj_pos(OBJ_PARAMS_PUMP)
	if left < 0x92 and cur(OBJ_SCREEN_Y_POS) >= 0x39:
		move_object_up()
	set_cur(OBJ_VAR_1, left - 1)
	if left - 1 == 0:
		_yellow_belly_swim_start()


## .Func_515dd: Puffy Wario stops the chase; hit, it is hurt; level with its pump ($38 px from it,
## the low bits of x even) it shoots; otherwise speed 2 on (.asm_5168e).
func yellow_belly_chase_pump() -> void:
	if wTransformation == TRANSFORMATION_PUFFY_WARIO:
		wram1[W_YELLOW_BELLY_PUMPING] = 0
		_yellow_belly_swim_start()
		return
	if wram1[W_YELLOW_BELLY_HIT] != 0:
		_yellow_belly_hit()
		return
	if wram1[W_YELLOW_BELLY_PUMPING] == 0:
		_yellow_belly_swim_start()
		return
	var pump: int = _active_slot_with_id(PUMP)
	if pump < 0:
		return
	var pump_x: int = _slot_word(pump, OBJ_X_POS) & 0xFFFE
	var x: int = cur_x() & 0xFFFE
	if pump_x == word(x + 0x38 if hdir() else x - 0x38):
		_yellow_belly_aim()
		return
	set_cur(OBJ_VAR_2, 2)
	_yellow_belly_swim_on()


## .Func_51652: while its head is hit it stands still (no actions, state cleared); hit, it is hurt.
## Its last lap done above Wario, it sinks to him (.Func_5178c); otherwise it bobs (Data_60950,
## looping) and swims on.
func yellow_belly_swim() -> void:
	if wram1[W_YELLOW_BELLY_PAUSED] != 0:
		_no_actions()
		set_cur(OBJ_STATE, 0)
		return
	if wram1[W_YELLOW_BELLY_HIT] != 0:
		_yellow_belly_hit()
		return
	if cur(OBJ_VAR_1) == 0 and cur(OBJ_VAR_3) == 1 and cur(OBJ_SCREEN_Y_POS) >= wWarioScreenYPos:
		set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_SINK & 0xFFFF)
		return
	apply_obj_y_movement_loop(DATA_60950)
	_yellow_belly_swim_on()


## .asm_5168e: a state: Puffy Wario's touch ($0a) inflates it; any other turns it away from Wario
## (speed 2). Turning (OBJ_VAR_1), its frames, then (on even frames, one lap fewer down to 1)
## swimming or, inflated, its frameset. Swimming: with Wario below on its last laps (OBJ_VAR_3 1,
## not Puffy) a lap ends (SFX_0A8 not simulated), the last one aiming; a wall 4 px up and $18 px
## ahead turns it (both ways at once unless VDIR says otherwise), speed 1; otherwise OBJ_VAR_2
## across.
func _yellow_belly_swim_on() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if state == OBJSTATE_VANISH_TOUCH:
			_yellow_belly_inflate_start()
			return
		set_cur(OBJ_STATE, 0)
		var wario: int = byte(wWarioScreenXPos + 0x2A)
		var me: int = byte(cur(OBJ_SCREEN_X_POS) + 0x2A)
		if (me >= wario) if not hdir() else (wario >= me):
			set_hdir(not hdir())
		set_cur(OBJ_VAR_2, 2)
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) != 0:
			return
		if (wGlobalCounter & 1) == 0 and cur(OBJ_STATE_DURATION) >= 2:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)  # `dec l` from OBJ_VAR_1
		if wram1[W_YELLOW_BELLY_PUMPING] == 1:
			set_object_frameset_ptr(FRAMESET_69789 if _yellow_belly_vdir() else FRAMESET_69780)
		else:
			set_object_frameset_ptr(FRAMESET_697EB if _yellow_belly_vdir() else FRAMESET_697E6)
		return
	if cur(OBJ_VAR_3) == 1 and wTransformation != TRANSFORMATION_PUFFY_WARIO \
			and cur(OBJ_SCREEN_Y_POS) < wWarioScreenYPos:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			_yellow_belly_aim()
			return
	var right: bool = hdir()
	set_hpos_from_object(-4, 0x18 if right else -0x18)
	if object_probe(COLLISION_UNK4) == 0:
		if right:
			move_object_right_by_var2()
		else:
			move_object_left_by_var2()
		return
	if _yellow_belly_vdir() == right:
		set_object_frameset_ptr(FRAMESET_697BB if right else FRAMESET_697B0)
		set_cur(OBJ_VAR_1, 0x44)
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ (OBJSUBFLAG_VDIR | OBJSUBFLAG_HDIR))
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)
	set_cur(OBJ_VAR_2, 1)


## .Func_5178c: no actions; a pixel a frame down while its screen x is below $c8.
func yellow_belly_sink() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_X_POS) < 0xC8:
		move_object_down()


## .asm_5179a: the pump hit it: a hit taken (DecrementRemainingBossHits); hurt 100 frames, or with
## no hits left defeated (101 frames, OBJ_VAR_1 $ff, harmless; sounds and the music's stop not
## simulated).
func _yellow_belly_hit() -> void:
	wram1[W_YELLOW_BELLY_HIT] = 0
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_HURT & 0xFFFF)
	decrement_remaining_boss_hits()
	if (cur(OBJ_SUBSTATE) & 0x0F) - 1 != 0:
		set_object_frameset_ptr(FRAMESET_697D5)
		set_cur(OBJ_STATE_DURATION, 0x64)
		set_cur(OBJ_VAR_1, 1)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_DEFEATED & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69845)
	set_cur(OBJ_STATE_DURATION, 0x65)
	set_cur(OBJ_VAR_1, 0xFF)
	set_interaction(OBJ_INTERACTION_0B)


## .Func_517ee: no actions; its frames (palettes and SFX_0B9 not simulated); then, at its frameset's
## $10 offset as a frame begins, swimming again with the OAM of its hits left (OAM_191940 at two,
## OAM_191f04 at one).
func yellow_belly_hurt() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if cur(OBJ_FRAMESET_OFFSET) != 0x10 or cur(OBJ_FRAME_DURATION) != 0:
		return
	set_cur(OBJ_VAR_1, 0)
	_yellow_belly_swim_start()
	match cur(OBJ_SUBSTATE) & 0x0F:
		3:
			set_cur_word(OBJ_OAM_PTR, OAM_191940)
		2:
			set_cur_word(OBJ_OAM_PTR, OAM_191F04)


## .Func_5184a: its frames (palettes and sounds not simulated); at its frameset's $20 offset as a frame
## begins it is gone, its platform (the first active YELLOW_BELLY_PLATFORM) given state $2f, and its
## object-map nibble 7 (Func_51c62).
func yellow_belly_defeated() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if cur(OBJ_FRAMESET_OFFSET) != 0x20 or cur(OBJ_FRAME_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, 0)
	var platform: int = _active_slot_with_id(YELLOW_BELLY_PLATFORM)
	if platform < 0:
		return
	wram1[platform + OBJ_STATE] = 0x2F
	set_cur_object_map_nibble(0x07)  # Func_51c62


## PumpFunc: its side by wGlobalCounter's bit 0 (OBJ_VAR_1); falling.
func pump_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, PUMP_FALL & 0xFFFF)
	set_cur(OBJ_VAR_1, wGlobalCounter)
	pump_fall()


## .Func_518c6: no actions; along Data_609e0, half a pixel a frame its way (a wall 4 px up, 5 px
## right or 6 left, stops that); after OBJ_STATE_DURATION frames, landing on a floor (Func_352b).
func pump_fall() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_609E0)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	else:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) != 0:
			store_object_y_from_hpos()
			set_object_frameset_ptr(FRAMESET_6987F)
			set_cur_word(OBJ_UPDATE_FUNCTION, PUMP_UPDATE & 0xFFFF)
			set_cur(OBJ_STATE, 0)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_PRIORITY)
			return
	var right: bool = (cur(OBJ_VAR_1) & 1) != 0
	set_hpos_from_object(-4, 5 if right else -6)
	if object_probe(COLLISION_UNK4) != 0:
		return
	if right:
		move_object_right_slow()
	else:
		move_object_left_slow()


## .Func_51947, by OBJ_STATE: knocked ($31: 60 frames across, Data_60a00 left or _60a10 right,
## turning at walls); touched ($0a: Wario pumps it into Yellow Belly: wYellowBellyHit, the pumping
## over, $3a); hurt ($3a: 29 frames, then falling along Data_60040); thrown ($28, $29: $58, following
## an arrow, gone once above screen row $48). Any other state but 0 knocks it away from Wario
## (collisions on).
func pump_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		OBJSTATE_WALK:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, 0)
				return
			_pump_knocked()
		OBJSTATE_VANISH_TOUCH:
			set_cur(OBJ_STATE, 0x3A)
			wram1[W_YELLOW_BELLY_HIT] = 0x3A
			wram1[W_YELLOW_BELLY_PUMPING] = 0
			set_object_frameset_ptr(FRAMESET_69882)
			set_cur(OBJ_STATE_DURATION, 0x1D)
			set_cur(OBJ_VAR_3, 0)
		0x3A:
			_no_actions()
			if cur(OBJ_STATE_DURATION) != 0:
				set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
				return
			apply_obj_y_movement(DATA_60040)
		0x58:
			_pump_follow_arrow()
		_:
			if (state & 0xFE) == 0:
				return
			if (state & 0xFE) == 0x28:
				set_cur(OBJ_STATE, 0x58)
				wram1[W_YELLOW_BELLY_PUMPING] = 0
				_pump_follow_arrow()
				return
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A))
			set_cur(OBJ_VAR_2, 0)
			set_cur(OBJ_STATE_DURATION, 0x3C)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


## .asm_5198b's slide: a wall 4 px up ahead (5 px right, 6 left) turns it.
func _pump_knocked() -> void:
	var right: bool = hdir()
	set_hpos_from_object(-4, 5 if right else -6)
	var wall: bool = object_probe(COLLISION_UNK4) != 0
	if right == wall:
		if wall:
			set_hdir(false)
		apply_obj_x_movement(DATA_60A00)
	else:
		if wall:
			set_hdir(true)
		apply_obj_x_movement(DATA_60A10)


## .asm_51a1d: no actions; gone above screen row $48; otherwise 8 px under the first arrow out.
func _pump_follow_arrow() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) < 0x48:
		set_cur(OBJ_FLAGS, 0)
		return
	var arrow: int = _active_slot_with_id(YELLOW_BELLY_ARROW)
	if arrow < 0:
		return
	set_cur_word(OBJ_Y_POS, _slot_word(arrow, OBJ_Y_POS) + 8)
	set_cur_word(OBJ_X_POS, _slot_word(arrow, OBJ_X_POS))


## YellowBellyArrowFunc.Left and .Right: shot while it is inflated, the arrow is grabbed (it carries
## the pump) and flies at speed 2.
func yellow_belly_arrow_left() -> void:
	_yellow_belly_arrow_start(YELLOW_BELLY_ARROW_LEFT_FLY)
	yellow_belly_arrow_left_fly()


func yellow_belly_arrow_right() -> void:
	_yellow_belly_arrow_start(YELLOW_BELLY_ARROW_RIGHT_FLY)
	yellow_belly_arrow_right_fly()


func _yellow_belly_arrow_start(fly: int) -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, fly & 0xFFFF)
	if wram1[W_YELLOW_BELLY_PUMPING] != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)
		set_cur(OBJ_VAR_2, 2)


func yellow_belly_arrow_left_fly() -> void:
	_yellow_belly_arrow_fly(false)


func yellow_belly_arrow_right_fly() -> void:
	_yellow_belly_arrow_fly(true)


## .Func_51a7d and .Func_51ad9: (no actions past Wario: .Func_51b4b) knocked ($28, $29) it flies off
## (speed 4); any other state ends it (it hit Wario: 30 frames, the battle over; the music's stop not
## simulated); otherwise OBJ_VAR_2 down and across (a pixel across while inflated).
func _yellow_belly_arrow_fly(right: bool) -> void:
	_yellow_belly_arrow_check()
	var state: int = cur(OBJ_STATE)
	if state == 0x28 or state == 0x29:
		set_cur_word(OBJ_UPDATE_FUNCTION, (YELLOW_BELLY_ARROW_RIGHT_KNOCKED if right else YELLOW_BELLY_ARROW_LEFT_KNOCKED) & 0xFFFF)
		set_cur(OBJ_VAR_2, 4)
		return
	if state != 0:
		set_cur(OBJ_STATE_DURATION, 0x1E)
		set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_ARROW_HIT & 0xFFFF)
		wBossState = BOSS_NONE
		return
	set_cur_word(OBJ_Y_POS, cur_y() + cur(OBJ_VAR_2))  # MoveObjectDownByVar2
	if wram1[W_YELLOW_BELLY_PUMPING] == 0:
		if right:
			move_object_right_by_var2()
		else:
			move_object_left_by_var2()
	elif right:
		move_object_right()
	else:
		move_object_left()


## .Func_51b4b: no actions once at or below Wario's row, or past him the way its HDIR says.
func _yellow_belly_arrow_check() -> void:
	var y: int = cur(OBJ_SCREEN_Y_POS)
	var x: int = cur(OBJ_SCREEN_X_POS)
	if y >= wWarioScreenYPos or (x >= wWarioScreenXPos if hdir() else x < wWarioScreenXPos):
		_no_actions()


## .Func_51b16: then gone.
func yellow_belly_arrow_hit() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


## .Func_51aaa and .Func_51b34: no actions; flying off up OBJ_VAR_2 and 2 px a frame across (right
## from the left arrow, left from the right one), gone above screen row $40.
func yellow_belly_arrow_left_knocked() -> void:
	_yellow_belly_arrow_knocked(2)


func yellow_belly_arrow_right_knocked() -> void:
	_yellow_belly_arrow_knocked(-2)


func _yellow_belly_arrow_knocked(dx: int) -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) < 0x40:
		set_cur(OBJ_FLAGS, 0)
		return
	set_cur_word(OBJ_Y_POS, cur_y() - cur(OBJ_VAR_2))  # MoveObjectUpByVar2
	set_cur_word(OBJ_X_POS, cur_x() + dx)


## YellowBellyHeadFunc: invisible; .Func_51b7b.
func yellow_belly_head_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_HEAD_UPDATE & 0xFFFF)
	yellow_belly_head_update()


## .Func_51b7b: (no actions while Wario is Puffy) a state means Wario hit it: the body still for 30
## frames (wYellowBellyPaused), the battle over (the music's stop not simulated). It sits 16 px
## under the body and 8 px to its front (by the body's VDIR); hurt (OBJ_VAR_1 not 0) without actions,
## gone with the defeated body ($ff).
func yellow_belly_head_update() -> void:
	if wTransformation == TRANSFORMATION_PUFFY_WARIO:
		_no_actions()
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_STATE_DURATION, 0x1E)
		wram1[W_YELLOW_BELLY_PAUSED] = 1
		wBossState = BOSS_NONE
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			wram1[W_YELLOW_BELLY_PAUSED] = 0
	var body: int = _active_slot_with_id(YELLOW_BELLY_BODY)
	if body < 0:
		return
	set_cur_word(OBJ_Y_POS, _slot_word(body, OBJ_Y_POS) + 0x10)
	var body_x: int = _slot_word(body, OBJ_X_POS)
	var hurt: int = wram1[body + OBJ_VAR_1]
	if hurt == 0xFF:
		set_cur(OBJ_FLAGS, 0)
		return
	if hurt != 0:
		_no_actions()
	var front: bool = (wram1[body + OBJ_SUBSTATE] & OBJSUBFLAG_VDIR) != 0
	set_cur_word(OBJ_X_POS, body_x + 8 if front else body_x - 8)


## YellowBellyPlatformFunc: visible, no collision with objects, kept (OBJSUBFLAG_UNK_4), a box -8..7
## (bottom -10); waiting.
func yellow_belly_platform_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, YELLOW_BELLY_PLATFORM_WAIT & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69893)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -10)


## .Func_51c3f: given state $2f (the boss defeated), it opens (90 frames, Func_51c77), the battle over
## (wBossState BOSS_DEFEATED, wIsBossBattle off; the music not simulated), its object-map nibble 7
## (Func_51c62).
func yellow_belly_platform_wait() -> void:
	if cur(OBJ_STATE) != 0x2F:
		return
	set_object_frameset_ptr(FRAMESET_69896)
	set_cur(OBJ_STATE_DURATION, 0x5A)
	set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_51C77 & 0xFFFF)
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0
	set_cur_object_map_nibble(0x07)


## Func_51c77: then gone.
func func_51c77() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)

# --- Anonster (objects/anonster.asm) ------------------------------------------------------------------

## AnonsterFunc: the battle on (wIsBossBattle), 27 px up, its hits (3, plus one) in the substate,
## 40 frames' wait.
func anonster_func() -> void:
	wIsBossBattle = 1
	set_cur(OBJ_VAR_2, 27)
	set_cur_word(OBJ_Y_POS, cur_y() - 27)  # MoveObjectUpByVar2
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & 0xF0) | 4)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_WAIT & 0xFFFF)
	anonster_wait()


## .Func_50024: then wBossState BOSS_REGULAR (the music not simulated) and .asm_50031.
func anonster_wait() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	wBossState = BOSS_REGULAR
	_anonster_enter()


## .asm_50031: its swimming frameset, 80 frames out of sight, a box -9..8 (top -29, bottom -4), not
## heavy.
func _anonster_enter() -> void:
	set_object_frameset_ptr(FRAMESET_693D5 if hdir() else FRAMESET_693C4)
	set_cur(OBJ_STATE_DURATION, 0x50)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_APPEAR & 0xFFFF)
	set_collbox_x(-9, 8)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)
	set_cur(OBJ_COLLBOX_TOP, -29)
	set_cur(OBJ_INTERACTION_TYPE, cur(OBJ_INTERACTION_TYPE) & ~HEAVY_OBJ)


## .Func_5005e: no actions; then visible and swimming (state, OBJ_VAR_2 and _3, and its frames
## cleared).
func anonster_appear() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SWIM & 0xFFFF)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 0)
	set_cur(OBJ_STATE_DURATION, 0)


## .Func_5007f: no actions. Knocked ($28, $29) it falls stunned (.Func_50282). Otherwise collisions
## on, bobbing (Data_60790, looping); turning out its frames; at the bob's $4f step, every second
## time with no transient object out, it spins silk (.Func_5016f, facing Wario); otherwise a pixel a
## frame ahead, a wall 4 px up ($11 px left, $10 right) turning it (10 frames; SFX_0B0 not simulated).
func anonster_swim() -> void:
	_no_actions()
	if (cur(OBJ_STATE) & 0xFE) == 0x28:
		set_object_frameset_ptr(FRAMESET_69441 if hdir() else FRAMESET_6943C)
		set_cur(OBJ_STATE_DURATION, 0)
		set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_KNOCKED & 0xFFFF)
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	apply_obj_y_movement_loop(DATA_60790)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(FRAMESET_693D5 if hdir() else FRAMESET_693C4)
		return
	if cur(OBJ_VAR_3) == 0x4F:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) + 1)
		if cur(OBJ_VAR_2) >= 2 and count_active_transient_objects() == 0:
			set_cur(OBJ_VAR_2, 0)
			set_cur(OBJ_VAR_3, 0)
			set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SILK_WAIT & 0xFFFF)
			var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			set_hdir(right)
			set_object_frameset_ptr(FRAMESET_69411 if right else FRAMESET_693E6)
			return
	var ahead_right: bool = hdir()
	set_hpos_from_object(-4, 0x10 if ahead_right else -0x11)
	if object_probe(COLLISION_UNK4) == 0:
		if ahead_right:
			move_object_right()
		else:
			move_object_left()
		return
	set_object_frameset_ptr(FRAMESET_69512 if ahead_right else FRAMESET_69446)
	set_cur(OBJ_STATE_DURATION, 0x0A)
	set_hdir(not ahead_right)


## .Func_5016f: no actions; bobbing (Data_60790, looping); at the bob's $1f step it spins its first
## silk (.Func_501c4), at its $4f step it swims on.
func anonster_silk_wait() -> void:
	_no_actions()
	match cur(OBJ_VAR_3):
		0x1F:
			set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SILK_1 & 0xFFFF)
			_anonster_spin()
		0x4F:
			set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SWIM & 0xFFFF)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_693D5 if hdir() else FRAMESET_693C4)
			set_cur(OBJ_STATE_DURATION, 0)
		_:
			apply_obj_y_movement_loop(DATA_60790)


## .asm_5018e: a spin, 32 frames.
func _anonster_spin() -> void:
	set_object_frameset_ptr(FRAMESET_69424 if hdir() else FRAMESET_693F9)
	set_cur(OBJ_STATE_DURATION, 0x20)


func anonster_silk_1() -> void:
	_anonster_silk(0, 4, ANONSTER_SILK_2)


func anonster_silk_2() -> void:
	_anonster_silk(1, 3, ANONSTER_SILK_3)


func anonster_silk_3() -> void:
	_anonster_silk(2, -1, 0)


## .Func_501c4, .Func_50200, .Func_5023d: no actions; a silk 8 frames into the 32-frame spin
## (ObjParams_AnonsterSilk1-3, left or right; SFX_07E not simulated); then the next spin, or with
## `stop_at` hits left (and after the third) back to bobbing (.asm_50266).
func _anonster_silk(index: int, stop_at: int, next: int) -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0x18:
		create_object_at_relative_pos(OBJ_PARAMS_ANONSTER_SILK[index][1 if hdir() else 0])
		return
	if left != 0:
		return
	if next == 0 or (cur(OBJ_SUBSTATE) & 0x0F) == stop_at:
		set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SILK_WAIT & 0xFFFF)
		set_object_frameset_ptr(FRAMESET_6942D if hdir() else FRAMESET_69402)
		apply_obj_y_movement_loop(DATA_60790)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	_anonster_spin()


## .Func_50282: (SFX_0B1 not simulated) .Func_50293.
func anonster_knocked() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_RISE & 0xFFFF)
	anonster_rise()


## .Func_50293: no actions; half a pixel a frame up to screen row 8, then facing Wario for 60
## frames; then chasing him (OBJ_VAR_1 3 turns).
func anonster_rise() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur(OBJ_VAR_1, 3)
			set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_CHASE & 0xFFFF)
		return
	if cur(OBJ_SCREEN_Y_POS) >= 8:
		move_object_up_slow()
		return
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))


## .Func_502d1: 2 px a frame over Wario (a wall turning it, each turn one of OBJ_VAR_1's); above him
## (x's low bits even) or out of turns, it drops (.asm_50321): collisions on, heavy
## OBJ_INTERACTION_48, a box -12..11 (top -24, bottom -8).
func anonster_chase() -> void:
	if (wWarioScreenXPos & 0xFE) != (cur(OBJ_SCREEN_X_POS) & 0xFE):
		var right: bool = hdir()
		set_hpos_from_object(-4, 0x10 if right else -0x11)
		if object_probe(COLLISION_UNK4) == 0:
			set_cur_word(OBJ_X_POS, cur_x() + (2 if right else -2))  # MoveObjectRight_Fast, _Left_Fast
			return
		set_hdir(not right)
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) != 0:
			return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_DROP & 0xFFFF)
	set_cur(OBJ_INTERACTION_TYPE, (cur(OBJ_INTERACTION_TYPE) & HEAVY_OBJ) | OBJ_INTERACTION_48 | HEAVY_OBJ)
	set_cur(OBJ_COLLBOX_TOP, -24)
	set_cur(OBJ_COLLBOX_BOTTOM, -8)
	set_collbox_x(-12, 11)
	set_object_frameset_ptr(FRAMESET_6944D)


## .Func_5034c: down along Data_607f0 to a floor (Func_352b, below screen row $50); landed, 32
## frames, its ground box (.asm_50388).
func anonster_drop() -> void:
	if cur(OBJ_SCREEN_Y_POS) >= 0x50:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) != 0:
			store_object_y_from_hpos()
			set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_LANDED & 0xFFFF)
			set_object_frameset_ptr(FRAMESET_69450)
			set_cur(OBJ_STATE_DURATION, 0x20)
			_anonster_ground_box()
			return
	apply_obj_y_movement(DATA_607F0)


## .asm_50388: a box -16..15 (top -16, bottom 0).
func _anonster_ground_box() -> void:
	set_cur(OBJ_COLLBOX_TOP, -16)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_collbox_x(-16, 15)


## .Func_50397: its frames, the ground shaking at $18 left (DoGroundShake 24; SFX_061 not simulated);
## then on the ground ($5a, facing Wario, 7 frames, OBJ_VAR_1 2).
func anonster_landed() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0x18:
		if wGroundShakeCounter == 0:
			wGroundShakeCounter = 24
			wIsWarioGroundShaking = 0
		return
	if left != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_GROUND & 0xFFFF)
	set_cur(OBJ_STATE, 0x5A)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_694C9 if right else FRAMESET_694D0)
	set_cur(OBJ_STATE_DURATION, 7)
	set_cur(OBJ_VAR_1, 2)


## .Func_5041d, by OBJ_STATE: walking (0), making waves ($5b), after them ($5c), landing ($5a, its
## frames), hit ($0a); anything else resets it to walking (.asm_5043b).
func anonster_ground() -> void:
	match cur(OBJ_STATE):
		0:
			_anonster_walk_turning()
		0x5B:
			_anonster_wave()
		0x5C:
			if wTransformation == TRANSFORMATION_BALL_O_STRING_WARIO:
				_anonster_jump_start()
				return
			_anonster_after_wave()
		0x5A:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				_anonster_reset()
		OBJSTATE_VANISH_TOUCH:
			_anonster_touched()
		_:
			_anonster_reset()


## .asm_5043b: walking (state 0, its frames 0), heavy-less OBJ_INTERACTION_48, its walking box by
## direction (-8..16 left, -17..7 right; top -16, bottom 0).
func _anonster_reset() -> void:
	var right: bool = hdir()
	if right:
		set_collbox_x(-17, 7)
	else:
		set_collbox_x(-8, 0x10)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_cur(OBJ_COLLBOX_TOP, -16)
	set_interaction(OBJ_INTERACTION_48)
	set_object_frameset_ptr(FRAMESET_69496 if right else FRAMESET_69485)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_STATE, 0)


## .asm_5046b: turning out its frames (turned at 7 left, reset at 0); otherwise on even frames,
## facing Wario it makes waves ($5b, $5d frames), else walks.
func _anonster_walk_turning() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			_anonster_reset()
		elif cur(OBJ_STATE_DURATION) == 7:
			set_hdir(not hdir())
		return
	if (wGlobalCounter & 1) != 0:
		return
	var wario_ahead: bool = (cur(OBJ_SCREEN_X_POS) < wWarioScreenXPos) if hdir() \
			else (cur(OBJ_SCREEN_X_POS) >= wWarioScreenXPos)
	if not wario_ahead:
		_anonster_walk()
		return
	set_object_frameset_ptr(FRAMESET_69474 if hdir() else FRAMESET_69463)
	set_cur(OBJ_STATE_DURATION, 0x5D)
	set_cur(OBJ_STATE, 0x5B)


## .asm_503e0: a wave at $2b frames left (ObjParams_AnonsterWaveLeft or _Right; SFX_07E not
## simulated); at the end, after the waves ($5c), or (OBJ_VAR_1 counted down to 0) jumping off.
func _anonster_wave() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0x2B:
		create_object_at_relative_pos(OBJ_PARAMS_ANONSTER_WAVE_RIGHT if hdir() else OBJ_PARAMS_ANONSTER_WAVE_LEFT)
		return
	if left != 0:
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) == 0:
		_anonster_jump_start()
		return
	set_cur(OBJ_STATE, 0x5C)
	set_object_frameset_ptr(FRAMESET_69496 if hdir() else FRAMESET_69485)


## .asm_504d0: turning out its frames as when walking; otherwise walking quicker (its frames cut by
## 3; SFX_0AF not simulated).
func _anonster_after_wave() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			_anonster_reset()
		elif cur(OBJ_STATE_DURATION) == 7:
			set_hdir(not hdir())
		return
	if cur(OBJ_FRAME_DURATION) >= 3:
		set_cur(OBJ_FRAME_DURATION, cur(OBJ_FRAME_DURATION) - 3)
	_anonster_walk()


## .asm_504fe: a pixel a frame ahead: left while no wall 4 px up and $14 px ahead (Func_3513), right
## while a floor is under $17 px ahead (Func_3543); otherwise turning (14 frames).
func _anonster_walk() -> void:
	if hdir():
		set_hpos_from_object(0, 0x17)
		if object_probe(COLLISION_DOWN) != 0:
			move_object_right()
			return
		set_object_frameset_ptr(FRAMESET_69568)
	else:
		set_hpos_from_object(-4, -0x14)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_left()
			return
		set_object_frameset_ptr(FRAMESET_69573)
	set_cur(OBJ_STATE_DURATION, 0x0E)


## .asm_504b1: jumping off (7 frames, .Func_50650), its air box.
func _anonster_jump_start() -> void:
	set_object_frameset_ptr(FRAMESET_6954D if hdir() else FRAMESET_69554)
	set_cur(OBJ_STATE_DURATION, 7)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_JUMP & 0xFFFF)
	_anonster_ground_box()


## .asm_5054b: touched from behind it is hit (harmless, a hit taken; SFX_VANISH and the palettes
## not simulated): hurt ($56 frames), or with no hits left defeated ($ac frames, its substate only
## HDIR; the music's stop not simulated). From the front it resets.
func _anonster_touched() -> void:
	var me_left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	if me_left_of_wario == hdir():
		_anonster_reset()
		return
	set_interaction(OBJ_INTERACTION_0B)
	decrement_remaining_boss_hits()
	set_object_frameset_ptr(FRAMESET_694B8 if hdir() else FRAMESET_694A7)
	if (cur(OBJ_SUBSTATE) & 0x0F) - 1 != 0:
		set_cur(OBJ_STATE_DURATION, 0x56)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
		set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_HURT & 0xFFFF)
		return
	set_cur(OBJ_STATE_DURATION, 0xAC)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAG_HDIR)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_DEFEATED & 0xFFFF)


## .Func_505be: no actions; then crouching (14 frames), its air box (SFX_0B1 not simulated).
func anonster_hurt() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69543 if hdir() else FRAMESET_6953C)
	set_cur(OBJ_STATE_DURATION, 0x0E)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_CROUCH & 0xFFFF)
	_anonster_ground_box()


## .Func_505f4: then $33 frames.
func anonster_crouch() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_6951E)
	set_cur(OBJ_STATE_DURATION, 0x33)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_LEAP & 0xFFFF)


## .Func_50610: then flying up (SFX_0B2 not simulated).
func anonster_leap() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69519)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_FLY_UP & 0xFFFF)


## .Func_50635: no actions; up along Data_607e0 to screen row $10; there, unless Wario is a ball of
## string, it swims again (.asm_50031).
func anonster_fly_up() -> void:
	_no_actions()
	if cur(OBJ_SCREEN_Y_POS) >= 0x10:
		apply_obj_y_movement(DATA_607E0)
		return
	if wTransformation != TRANSFORMATION_BALL_O_STRING_WARIO:
		_anonster_enter()


## .Func_50650: no actions; then $2d frames.
func anonster_jump() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_694E1)
	set_cur(OBJ_STATE_DURATION, 0x2D)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_JUMP_2 & 0xFFFF)


## .Func_5066c: then flying up.
func anonster_jump_2() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_6944D)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_FLY_UP & 0xFFFF)


## .Func_50689: no actions; after its frames, its object-map nibble 5, the boss defeated (wBossState,
## wIsBossBattle off; the music not simulated), facing Wario, $48, PRIORITY; the next frame falling
## (.Func_50705; SFX_0A3 not simulated).
func anonster_defeated() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_DEFEAT_FALL & 0xFFFF)
		anonster_defeat_fall()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_object_map_nibble(0x05)
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0
	set_object_frameset_ptr(FRAMESET_694DC if hdir() else FRAMESET_694D7)
	set_cur(OBJ_STATE, 0x48)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)


## .Func_50705: no actions, along Data_60180, a pixel a frame away from its facing.
func anonster_defeat_fall() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60180)
	if hdir():
		move_object_left()
	else:
		move_object_right()


# --- Anonster's silk platforms, silk, and waves (objects/anonster.asm) --------------------------------

## SilkPlatformsFunc: kept (OBJSUBFLAG_UNK_4); 40 frames, then the three platforms 50 frames apart.
func silk_platforms_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SILK_PLATFORMS_CREATE_1 & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur(OBJ_STATE_DURATION, 0x28)
	_silk_platforms_create(-1, 0)


func silk_platforms_create_1() -> void:
	_silk_platforms_create(OBJ_PARAMS_SILK_PLATFORM[0], SILK_PLATFORMS_CREATE_2)


func silk_platforms_create_2() -> void:
	_silk_platforms_create(OBJ_PARAMS_SILK_PLATFORM[1], SILK_PLATFORMS_CREATE_3)


func silk_platforms_create_3() -> void:
	_silk_platforms_create(OBJ_PARAMS_SILK_PLATFORM[2], SILK_PLATFORMS_WAIT)


## .asm_50746: no actions, its frame held; after its frames, the platform (ObjParams_SilkPlatform*)
## and 50 frames to the next.
func _silk_platforms_create(params: int, next: int) -> void:
	silk_platforms_wait()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x32)
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	create_object_at_relative_pos(params)


## .Wait: no actions, its frame held.
func silk_platforms_wait() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)


## SilkPlatformFunc: a one-way platform sinking half a pixel a frame for its frames.
func silk_platform_func() -> void:
	set_one_way_platform_action()
	if cur(OBJ_STATE_DURATION) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	move_object_down_slow()


func anonster_silk_float_left() -> void:
	_anonster_silk_float(false)


func anonster_silk_float_right() -> void:
	_anonster_silk_float(true)


## AnonsterSilkFunc.FloatLeft and .FloatRight: for its frames 2 px a frame its way, a wall 4 px up
## (5 px left, 4 right) bouncing it back; the last of them turns it by rDIV. Then swaying down
## (.asm_507f7).
func _anonster_silk_float(right: bool) -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		_anonster_silk_sway()
		return
	set_cur_word(OBJ_X_POS, cur_x() + (2 if right else -2))
	set_hpos_from_object(-4, 4 if right else -5)
	if object_probe(COLLISION_UNK4) != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, (ANONSTER_SILK_FLOAT_LEFT if right else ANONSTER_SILK_FLOAT_RIGHT) & 0xFFFF)
		set_hdir(not right)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_anonster_silk_turn_by_div()
	_anonster_silk_state()


## .asm_507f7: gone below screen row $b0; otherwise swaying (Data_60800 right, _60830 left, looping)
## and turned by a wall 4 px up (5 px left, 4 right) or, at the sway's $2e step, by rDIV.
func _anonster_silk_sway() -> void:
	if cur(OBJ_SCREEN_Y_POS) >= 0xB0:
		set_cur(OBJ_FLAGS, 0)
		return
	hYPos = word(cur_y() - 4)
	if hdir():
		apply_obj_x_movement_loop(DATA_60800)
		hXPos = word(cur_x() - 5)
	else:
		apply_obj_x_movement_loop(DATA_60830)
		hXPos = word(cur_x() + 4)
	if object_probe(COLLISION_UNK4) != 0:
		set_hdir(not hdir())
	elif cur(OBJ_VAR_2) == 0x2E:
		_anonster_silk_turn_by_div()
	_anonster_silk_state()


## .asm_50849: bit 0 of rDIV clear turns it.
func _anonster_silk_turn_by_div() -> void:
	if (read_div(DIV_ANONSTER_SILK) & 1) == 0:
		set_hdir(not hdir())


## .asm_50855: a state below $0b bursts it, $0b and on ends it; otherwise every fourth frame a pixel
## down to a floor (Func_352b), where it lands (100 frames, harmless: .Func_508cd).
func _anonster_silk_state() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if state < 0x0B:
			_anonster_silk_burst_start()
		else:
			set_cur(OBJ_FLAGS, 0)
		return
	if (wGlobalCounter & 3) != 0:
		return
	move_object_down()
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	set_object_frameset_ptr(FRAMESET_694F5)
	set_cur(OBJ_STATE_DURATION, 0x64)
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SILK_LANDED & 0xFFFF)
	set_interaction(OBJ_INTERACTION_00)


## .Func_50898: bursting (29 frames, no actions, ungrabbed, no collision with objects; SFX_0A1 not
## simulated).
func _anonster_silk_burst_start() -> void:
	_no_actions()
	set_cur_word(OBJ_UPDATE_FUNCTION, ANONSTER_SILK_BURST & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_6955B)
	set_cur(OBJ_STATE_DURATION, 0x1D)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)


## .Func_508be: then gone.
func anonster_silk_burst() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


## .Func_508cd: visible; between screen rows $b0 and $c0 it bursts. Otherwise its table, by OBJ_STATE
## (to $59): lying (0, $0f: $3f, 120 frames, blinking its last 60), knocked (with speed 2, $28 and
## $29 vanishing above screen row $50), picked up, held, and thrown by the shared routines; touched
## it vanishes; most other states burst it.
func anonster_silk_landed() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	var y: int = cur(OBJ_SCREEN_Y_POS)
	if y >= 0xB0 and y < 0xC0:
		_anonster_silk_burst_start()
		return
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			set_cur(OBJ_STATE_DURATION, 0x78)
		0x04, 0x05:
			_anonster_silk_knocked(state + 0x30)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		OBJSTATE_VANISH_TOUCH:
			vanish_object()  # VanishObject2
		OBJSTATE_12:
			set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 31)
			set_cur(OBJ_STATE, 0x42)
			set_cur(OBJ_VAR_3, 0)
		OBJSTATE_14, OBJSTATE_15:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
		0x18, 0x19, 0x48, 0x49:
			carried_object_held(state, -1)
		0x28, 0x29:
			if cur(OBJ_SCREEN_Y_POS) < 0x50:
				vanish_object()  # VanishObject2
				return
			_anonster_silk_knocked(state + 0x30)
		OBJSTATE_3F:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_FLAGS, 0)
				return
			if cur(OBJ_STATE_DURATION) < 0x3C:
				if (wGlobalCounter & 7) < 4:
					set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
				else:
					set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
			func_628ea()  # Func_32ea
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x26, 0x27, 0x30, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x42, 0x44, 0x45, 0x4A, 0x4B, 0x4E, 0x4F, \
				0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59:
			common_enemy_state(state)
		_:
			if state > 0x59:
				note_unported("AnonsterSilkFunc state %02x" % state)
				return
			_anonster_silk_burst_start()


## .asm_50a13: knocked (`state`), OBJ_VAR_3 0, speed 2, no actions for a frame.
func _anonster_silk_knocked(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	_no_actions()


## AnonsteWaveLFunc_Left, AnonsterWaveFunc_Right: 2 px a frame its way; given a state, gone.
func anonster_wave_left() -> void:
	set_cur_word(OBJ_X_POS, cur_x() - 2)
	_anonster_wave_end()


func anonster_wave_right() -> void:
	set_cur_word(OBJ_X_POS, cur_x() + 2)
	_anonster_wave_end()


func _anonster_wave_end() -> void:
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_FLAGS, 0)

# --- Scowler (objects/scowler.asm) --------------------------------------------------------------------

## The countdown to Scowler's next ink shot: its hits left (substate) times 32, plus $48.
func _scowler_ink_delay() -> int:
	return byte(((cur(OBJ_SUBSTATE) & 0x0F) << 5) + 0x48)


## ScowlerFunc: visible, its hits (3, plus one) in the substate and its ink delay, a box -9..8
## (bottom -8), its counters and the ink blackout cleared.
func scowler_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_START & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED & 0xF0) | 4)
	set_cur(OBJ_VAR_3, _scowler_ink_delay())
	set_collbox_x(-9, 8)
	set_cur(OBJ_COLLBOX_BOTTOM, -8)
	set_object_frameset_ptr(FRAMESET_69A5F)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 0)
	wram1[W_SCOWLER_BLACKOUT] = 0
	wram1[W_SCOWLER_INK] = 0


## .Func_54520: the battle on (wIsBossBattle, wBossState BOSS_REGULAR; the music not simulated), its
## two tentacles (ObjParams_ScrowlerTentacleRight, _Left).
func scowler_start() -> void:
	wIsBossBattle = 1
	wBossState = BOSS_REGULAR
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_MAIN & 0xFFFF)
	create_object_from_cur_obj_pos(OBJ_PARAMS_SCROWLER_TENTACLE_RIGHT)
	create_object_from_cur_obj_pos(OBJ_PARAMS_SCROWLER_TENTACLE_LEFT)


## Func_54c07: Wario inked (wScowlerInk counting up): the screen blacks out at $3c for $ff frames
## (wScowlerBlackout counting down, the count held meanwhile) and comes back at $78. The palettes
## and sounds are presentation.
func scowler_ink_blackout() -> void:
	var ink: int = wram1[W_SCOWLER_INK]
	if ink == 0:
		return
	if wram1[W_SCOWLER_BLACKOUT] != 0:
		wram1[W_SCOWLER_BLACKOUT] -= 1
		return
	wram1[W_SCOWLER_INK] = byte(ink + 1)
	if ink == 0x3C:
		wram1[W_SCOWLER_BLACKOUT] = 0xFF
	elif ink == 0x78:
		wram1[W_SCOWLER_INK] = 0


## .Func_5458a: (the blackout counted) flattened ($2a: $5a; the music's stop not simulated); a room
## transition swallows Wario into it (.Func_54542, 30 frames). By OBJ_STATE: swimming (0), shooting
## ink ($2f), hit ($08, $09: stunned, .Func_546e0).
func scowler_main() -> void:
	scowler_ink_blackout()
	var state: int = cur(OBJ_STATE)
	if state == 0x2A:
		set_cur(OBJ_STATE, 0x5A)
		return
	if wRoomTransitionParam != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_SWALLOW & 0xFFFF)
		set_cur(OBJ_STATE_DURATION, 0x1E)
		return
	if state == 0:
		_scowler_swim()
	elif state == 0x2F:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		var left: int = cur(OBJ_STATE_DURATION)
		if left == 0:
			_scowler_reset()
		elif left == 0x20:
			create_object_at_relative_pos(OBJ_PARAMS_INK_RIGHT if hdir() else OBJ_PARAMS_INK_LEFT)
	elif (state & 0xFE) == 0x08:
		set_object_frameset_ptr(FRAMESET_69A95)
		set_cur(OBJ_STATE_DURATION, 0x44)
		set_cur(OBJ_VAR_1, 0xFD)
		set_cur(OBJ_VAR_3, 0)
		set_interaction(OBJ_INTERACTION_07)
		set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_STUNNED & 0xFFFF)


## .Func_54542: after its frames Wario is put at it (wWarioYPos, wWarioXPos).
func scowler_swallow() -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69B03)
	wWarioYPos = cur_y()
	wWarioXPos = cur_x()


## .asm_545f8: following Wario up and down (OBJ_VAR_1 frames, then its swimming frameset); otherwise,
## its ink delay run out (and no ink out) with Wario level or above, shooting ink ($2f, 72 frames);
## else a pixel a frame across, a wall 4 px up ($11 px left, $10 right) turning it ($2b frames).
func _scowler_swim() -> void:
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) != 0:
			_scowler_follow()
			return
		set_object_frameset_ptr(FRAMESET_69A68 if hdir() else FRAMESET_69A5F)
		return
	if wram1[W_SCOWLER_INK] == 0:
		set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) - 1)
		if cur(OBJ_VAR_3) == 0:
			set_cur(OBJ_VAR_3, _scowler_ink_delay())
			if cur(OBJ_SCREEN_Y_POS) >= wWarioScreenYPos:
				set_cur(OBJ_STATE, 0x2F)
				set_object_frameset_ptr(FRAMESET_69A7A)
				set_cur(OBJ_STATE_DURATION, 0x48)
				set_cur(OBJ_VAR_1, 0xFE)
				return
	if not _scowler_across():
		set_object_frameset_ptr(FRAMESET_69A71)
		set_cur(OBJ_VAR_1, 0x2B)
		set_hdir(not hdir())


## A pixel across its way unless a wall 4 px up ($11 px left, $10 right; Func_3513); false at a wall.
func _scowler_across() -> bool:
	var right: bool = hdir()
	set_hpos_from_object(-4, 0x10 if right else -0x11)
	if object_probe(COLLISION_UNK4) != 0:
		return false
	if right:
		move_object_right()
	else:
		move_object_left()
	return true


## .asm_5468e: up or down toward Wario's row (the low bits even).
func _scowler_follow() -> void:
	var wario_y: int = wWarioScreenYPos & 0xFE
	var y: int = cur(OBJ_SCREEN_Y_POS) & 0xFE
	if y == wario_y:
		return
	if y >= wario_y:
		_scowler_up()
	else:
		_scowler_down()


## .Func_5469d: a pixel down unless a floor 5 px below (Func_352b) turns it up (VDIR off).
func _scowler_down() -> void:
	set_hpos_from_object(5)
	if object_probe(COLLISION_UNK1) == 0:
		move_object_down()
		return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_VDIR)


## .Func_546bd: a pixel up while there is water 44 px up (Func_358b); otherwise turned down.
func _scowler_up() -> void:
	set_hpos_from_object(-0x2C)
	object_probe(COLLISION_UNK3)
	if wIsInWaterOrSand != 0:
		move_object_up()
		return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_VDIR)


## .Func_546e0: stunned: sinking along Data_60a60 while no floor is 5 px under it; after its frames,
## mouth open ($ff frames, OBJ_VAR_1 $fc, two rounds; OBJ_INTERACTION_06), chasing Wario (.Func_54770,
## VDIR off: `set 6` and `res 6` both run).
func scowler_stunned() -> void:
	scowler_ink_blackout()
	set_hpos_from_object(5)
	if object_probe(COLLISION_UNK1) == 0:
		apply_obj_y_movement(DATA_60A60)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69AB3)
	set_cur(OBJ_STATE_DURATION, 0xFF)
	set_cur(OBJ_VAR_1, 0xFC)
	set_cur(OBJ_VAR_2, 2)
	set_interaction(OBJ_INTERACTION_06)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_CHASE & 0xFFFF)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_VDIR)


## .Func_54770: mouth open: hit ($08, $09) from below Wario it is hurt (a hit taken, 30 frames;
## SFX_0B4 not simulated), from above it turns down for two more rounds; any other state is cleared.
## It swims up and down (by VDIR) and across; after its rounds it closes (.asm_547e9).
func scowler_chase() -> void:
	scowler_ink_blackout()
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if (state & 0xFE) == 0x08:
			if cur(OBJ_SCREEN_Y_POS) < wWarioScreenYPos:
				set_object_frameset_ptr(FRAMESET_69ABC)
				set_cur(OBJ_STATE_DURATION, 0x1E)
				set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_HURT & 0xFFFF)
				set_interaction(OBJ_INTERACTION_07)
				decrement_remaining_boss_hits()
				return
			set_cur(OBJ_STATE, 0)
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_VDIR)
			set_cur(OBJ_VAR_2, 2)
		else:
			set_cur(OBJ_STATE, 0)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
		if cur(OBJ_VAR_2) == 0:
			_scowler_close()
			return
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0:
		_scowler_down()
	else:
		_scowler_up()
	if not _scowler_across():
		set_hdir(not hdir())


## .asm_547e9: closing (40 frames, OBJ_VAR_1 $fe, OBJ_INTERACTION_07), then its own interaction.
func _scowler_close() -> void:
	set_object_frameset_ptr(FRAMESET_69AA8)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur(OBJ_VAR_1, 0xFE)
	set_interaction(OBJ_INTERACTION_07)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_CLOSE & 0xFFFF)


## .Func_54806: hurt; after its frames, rising (120 frames, .Func_54853), or with no hits left
## defeated (its substate only HDIR, 20 px up, OBJ_VAR_1 $ff; the music's stop not simulated).
func scowler_hurt() -> void:
	scowler_ink_blackout()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_3, 0)
	if (cur(OBJ_SUBSTATE) & 0x0F) - 1 != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_RISE & 0xFFFF)
		set_object_frameset_ptr(FRAMESET_69B08)
		set_cur(OBJ_STATE_DURATION, 0x78)
		return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAG_HDIR)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_DEFEATED & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69AC3)
	set_cur(OBJ_VAR_1, 0xFF)
	set_cur(OBJ_VAR_2, 0x14)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x14)  # MoveObjectUpByVar2


## .Func_54853: rising along Data_60a70 while water is 44 px up; after its frames, closing.
func scowler_rise() -> void:
	scowler_ink_blackout()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_scowler_close()
		return
	set_hpos_from_object(-0x2C)
	object_probe(COLLISION_UNK3)
	if wIsInWaterOrSand != 0:
		apply_obj_y_movement(DATA_60A70)


## .Func_5487d: after its frames, swimming again (its own interaction, .asm_54895).
func scowler_close() -> void:
	scowler_ink_blackout()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_interaction(OBJ_INTERACTION_SCOWLER)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_MAIN & 0xFFFF)
	_scowler_reset()


## .asm_54895: its ink delay, state and OBJ_VAR_1 cleared, facing Wario.
func _scowler_reset() -> void:
	set_cur(OBJ_VAR_3, _scowler_ink_delay())
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_STATE, 0)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_69A68 if right else FRAMESET_69A5F)


## .Func_548c5: defeated: no actions; rising along Data_60a70 while water is 24 px up; then 15 frames
## (PRIORITY; SFX_0AC not simulated).
func scowler_defeated() -> void:
	_no_actions()
	scowler_ink_blackout()
	set_hpos_from_object(-0x18)
	object_probe(COLLISION_UNK3)
	if wIsInWaterOrSand != 0:
		apply_obj_y_movement(DATA_60A70)
		return
	set_cur(OBJ_STATE_DURATION, 0x0F)
	set_cur(OBJ_VAR_2, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_SINK & 0xFFFF)


## .Func_5490b: no actions; half a pixel a frame down along Data_60a80; then $b4 frames.
func scowler_sink() -> void:
	_no_actions()
	scowler_ink_blackout()
	move_object_down_slow()
	apply_obj_x_movement(DATA_60A80)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0xB4)
	set_cur(OBJ_VAR_2, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCOWLER_GONE & 0xFFFF)


## .Func_54931: no actions; sinking and swaying (Data_60a90, looping); at the end of its frames its
## object-map nibble 5, the boss defeated (wBossState, wIsBossBattle off), the ink cleared (the
## palettes and music not simulated).
func scowler_gone() -> void:
	_no_actions()
	scowler_ink_blackout()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur_object_map_nibble(0x05)
			wBossState = BOSS_DEFEATED
			wIsBossBattle = 0
			wram1[W_SCOWLER_INK] = 0
	move_object_down_slow()
	apply_obj_x_movement_loop(DATA_60A90)


# --- Scowler's floating rings, tentacles, and ink (objects/scowler.asm) -------------------------------

## FloatingRingSpawnerFunc: kept (OBJSUBFLAG_UNK_4); after 64 frames a ring (ObjParams_FloatingRing).
func floating_ring_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_SPAWNER_WAIT & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur(OBJ_STATE_DURATION, 0x40)
	floating_ring_spawner_idle()


func floating_ring_spawner_wait() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_SPAWNER_IDLE & 0xFFFF)
		create_object_at_relative_pos(OBJ_PARAMS_FLOATING_RING)
	floating_ring_spawner_idle()


## .Func_549ab: its frame held, no actions.
func floating_ring_spawner_idle() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()


## FloatingRingFunc: OBJ_VAR_2 left at once; then rising.
func floating_ring_func() -> void:
	_no_actions()
	set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_RISE & 0xFFFF)
	move_object_left_by_var2()


## .Func_549c7: no actions; a pixel up every other frame for its frames; then a platform (its height
## kept in OBJ_VAR_2 and _3), waiting to be stood on.
func floating_ring_rise() -> void:
	_no_actions()
	if (wGlobalCounter & 1) != 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up()
		return
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_WAIT & 0xFFFF)
	set_cur(OBJ_VAR_2, lo(cur_y()))
	set_cur(OBJ_VAR_3, hi(cur_y()))


## .Func_549ee: a one-way platform until stood on; then rising.
func floating_ring_wait() -> void:
	set_one_way_platform_action()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_UP & 0xFFFF)


## .Func_54a02: rising a pixel every other frame (with Wario standing on it) for its frames; then
## sinking back.
func floating_ring_up() -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_DOWN & 0xFFFF)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		move_wario_up(1)
		handle_upwards_floor_transition()
	move_object_up()


## .Func_54a2d: sinking to its height (half a pixel a frame, or a pixel every other frame with Wario
## on it); there, stood on, it rises again (60 frames).
func floating_ring_down() -> void:
	set_one_way_platform_action()
	if lo(cur_y()) == cur(OBJ_VAR_2) and hi(cur_y()) == cur(OBJ_VAR_3):
		if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
			return
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		set_cur_word(OBJ_UPDATE_FUNCTION, FLOATING_RING_UP & 0xFFFF)
		set_cur(OBJ_STATE_DURATION, 0x3C)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		move_object_down_slow()
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	if (wGlobalCounter & 1) == 0:
		return
	move_wario_down(1)
	handle_downwards_floor_transition()
	move_object_down()


## ScrowlerTentacleFunc: invisible; .Func_54a97.
func scrowler_tentacle_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SCROWLER_TENTACLE_UPDATE & 0xFFFF)


## .Func_54a97: flattened ($2a: $5a); during a room transition still; its state cleared, it sits at
## Scowler (the first active one) by its OBJ_VAR_1: harmful at its sides when stunned ($fd:
## OBJ_INTERACTION_43, a box top -3, bottom 2), swallowing when closing ($fe: water teleporting,
## top -10, bottom -2), gone when defeated ($ff); otherwise placed by its side and facing.
func scrowler_tentacle_update() -> void:
	if cur(OBJ_STATE) == 0x2A:
		set_cur(OBJ_STATE, 0x5A)
		return
	if wRoomTransitionParam != 0:
		return
	set_cur(OBJ_STATE, 0)
	var scowler: int = _active_slot_with_id(SCOWLER)
	if scowler < 0:
		return
	var y: int = _slot_word(scowler, OBJ_Y_POS)
	var x: int = _slot_word(scowler, OBJ_X_POS)
	var right_tentacle: bool = cur(OBJ_ID) == SCROWLER_TENTACLE_RIGHT
	var near: bool
	match wram1[scowler + OBJ_VAR_1]:
		0:
			near = (wram1[scowler + OBJ_SUBSTATE] & OBJSUBFLAG_HDIR) != 0
		0xFD:
			_no_actions()
			set_interaction(OBJ_INTERACTION_43)
			set_cur(OBJ_COLLBOX_TOP, -3)
			set_cur(OBJ_COLLBOX_BOTTOM, 2)
			return
		0xFE:
			_no_actions()
			set_interaction(OBJ_INTERACTION_WATER_TELEPORTING)
			set_cur(OBJ_COLLBOX_TOP, -10)
			set_cur(OBJ_COLLBOX_BOTTOM, -2)
			return
		0xFF:
			set_cur(OBJ_FLAGS, 0)
			return
		_:
			near = right_tentacle
	if near:  # .asm_54b5a
		if right_tentacle:
			set_cur_word(OBJ_Y_POS, y - 0x0B)
			set_cur_word(OBJ_X_POS, x - 0x10)
		else:
			set_cur_word(OBJ_Y_POS, y - 4)
			set_cur_word(OBJ_X_POS, x + 0x16)
	elif right_tentacle:  # .asm_54b2e
		set_cur_word(OBJ_Y_POS, y - 4)
		set_cur_word(OBJ_X_POS, x - 0x17)
	else:
		set_cur_word(OBJ_Y_POS, y - 0x0B)
		set_cur_word(OBJ_X_POS, x + 0x0F)


## InkFunc.Left and .Right: half a pixel a frame its way for its frames, then toward Wario. Given a
## state it inks him (wScowlerInk 1) and splashes; out of the water (none 16 px up) it splashes;
## otherwise it rises a pixel every fourth frame. The splash: 25 frames, then gone.
func ink_func_left() -> void:
	_ink(false)


func ink_func_right() -> void:
	_ink(true)


func _ink(right: bool) -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	else:
		right = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	if right:
		move_object_right_slow()
	else:
		move_object_left_slow()
	if cur(OBJ_STATE) != 0:
		wram1[W_SCOWLER_INK] = 1
	else:
		set_hpos_from_object(-0x10)
		object_probe(COLLISION_UNK3)
		if wIsInWaterOrSand != 0:
			if (wGlobalCounter & 3) == 0:
				move_object_up()
			return
	set_object_frameset_ptr(FRAMESET_69AF5)
	set_cur(OBJ_STATE_DURATION, 0x19)
	set_cur_word(OBJ_UPDATE_FUNCTION, INK_SPLASH & 0xFFFF)


## .Func_54bf8: no actions, then gone.
func ink_splash() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)

# --- Muddee (objects/muddee.asm, muddee_stinger.asm) ----------------------------------------------

## MuddeeFunc: visible, kept (OBJSUBFLAG_UNK_4), its hits (4, plus one), a box -8..7 (bottom 7),
## $70 px right and 4 up, waiting 60 frames.
func muddee_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_AMBUSH & 0xFFFF)
	var substate: int = (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4
	set_cur(OBJ_SUBSTATE, (substate & OBJSUBFLAGS_MASK) | 5)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 7)
	set_object_frameset_ptr(FRAMESET_69D73)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur(OBJ_VAR_2, 0x70)
	move_object_right_by_var2()
	set_cur(OBJ_VAR_2, 4)
	set_cur_word(OBJ_Y_POS, cur_y() - 4)  # MoveObjectUpByVar2


## .Func_55c3a: invisible one frame in four.
func _muddee_blink() -> void:
	if (wGlobalCounter & 3) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)


## .Func_5564e: no actions, blinking, until the turtle has carried Wario over (wMuddeeAmbushState
## 1): the battle on (the palettes not simulated).
func muddee_ambush() -> void:
	_no_actions()
	_muddee_blink()
	if wram1[W_MUDDEE_AMBUSH_STATE] != 1:
		return
	wIsBossBattle = 1
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_WAIT & 0xFFFF)


## .Func_55676: its frames, then lurking (.Func_55696).
func muddee_wait() -> void:
	_no_actions()
	_muddee_blink()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_LURK & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69D85)
	set_cur(OBJ_VAR_3, 0)


## .Func_55696: blinking until Wario is far enough left (x's high byte below 9, or its low byte below
## $40) and $48 to $95 rows above it; then out (visible, wBossState BOSS_REGULAR, the stingers out).
func muddee_lurk() -> void:
	_no_actions()
	_muddee_blink()
	if hi(wWarioXPos) >= 9 and lo(wWarioXPos) >= 0x40:
		return
	var dy: int = byte(cur(OBJ_SCREEN_Y_POS) - wWarioScreenYPos)
	if dy < 0x48 or dy >= 0x96:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_RISE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69CF2)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	wBossState = BOSS_REGULAR
	wram1[W_MUDDEE_HIT] = 0
	_muddee_stingers()


## .asm_556dc: its two stingers (ObjParams_MuddeeStinger1, 2; SFX_0B2 not simulated).
func _muddee_stingers() -> void:
	create_object_from_cur_obj_pos(OBJ_PARAMS_MUDDEE_STINGER_1)
	create_object_from_cur_obj_pos(OBJ_PARAMS_MUDDEE_STINGER_2)


## .Func_556f0: no actions; out along Data_60d30 to its $0e step, then the battle (OBJ_VAR_1 1).
func muddee_rise() -> void:
	_no_actions()
	if cur(OBJ_VAR_3) != 0x0E:
		apply_obj_y_movement(DATA_60D30)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_MAIN & 0xFFFF)
	set_cur(OBJ_VAR_1, 1)


## .Func_55711: no actions; its interaction by its frame (and its side: frames 3-5 face right, 9-11
## left); hit by its stinger's touch (wMuddeeHit 1) it is hurt, hurt (2) it sinks; otherwise by
## OBJ_VAR_1.
func muddee_main() -> void:
	_no_actions()
	var frame: int = cur(OBJ_FRAME)
	if frame < 0x10:
		var kind: int
		if frame >= 0x0C:
			kind = OBJ_INTERACTION_0B
		elif frame >= 0x09:
			set_hdir(false)
			kind = 0x46
		elif frame >= 0x06:
			kind = 0x47
		elif frame >= 0x03:
			set_hdir(true)
			kind = 0x46
		else:
			kind = OBJ_INTERACTION_48
		set_interaction(kind)
	match wram1[W_MUDDEE_HIT]:
		0:
			_muddee_phase()
		2:
			_muddee_hurt()
		_:
			_muddee_hit()


## .asm_55774: hurt (wMuddeeHit 2, 60 frames, a hit taken), its frameset by its interaction (the whole
## byte: $48, $47) or side (SFX_VANISH not simulated).
func _muddee_hit() -> void:
	wram1[W_MUDDEE_HIT] = 2
	var kind: int = cur(OBJ_INTERACTION_TYPE)
	if kind == 0x48:
		set_object_frameset_ptr(FRAMESET_69D48)
	elif kind == 0x47:
		set_object_frameset_ptr(FRAMESET_69D4D)
	else:
		set_object_frameset_ptr(FRAMESET_69D52 if hdir() else FRAMESET_69D57)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur(OBJ_VAR_3, 0)
	decrement_remaining_boss_hits()


## .asm_557b1: its frames (at the last hit, then defeated); then sinking along Data_60d40 into the
## water, where it dives (wMuddeeHit 0, 44 frames, OBJ_VAR_1 4; SFX_083 not simulated).
func _muddee_hurt() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0 or (cur(OBJ_SUBSTATE) & 0x0F) != 2:
			return
		_muddee_defeat()
		return
	set_hpos_from_object()
	object_probe(COLLISION_UNK1)
	if wIsInWaterOrSand == 0:
		apply_obj_y_movement(DATA_60D40)
		return
	wram1[W_MUDDEE_HIT] = 0
	set_object_frameset_ptr(FRAMESET_69DC0)
	set_cur(OBJ_STATE_DURATION, 0x2C)
	set_cur(OBJ_VAR_1, 4)


## .asm_55806: defeated: falling (.Func_55ba7: 40 frames, $14 of them falling), its substate only
## HDIR, facing away from Wario, PRIORITY, its object-map nibble 7, wMuddeeAmbushState 2 (the
## music's stop not simulated).
func _muddee_defeat() -> void:
	set_object_frameset_ptr(FRAMESET_69D6A)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur(OBJ_VAR_1, 0x14)
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_DEFEATED & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0x80)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A))
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur_object_map_nibble(0x07)
	wram1[W_MUDDEE_AMBUSH_STATE] = 2


## Func_55c11: its frameset from `offset` (the frame duration 0) and OBJ_STATE_DURATION `duration`.
func _muddee_frameset_at(frameset: int, offset: int, duration: int) -> void:
	set_cur_word(OBJ_FRAMESET_PTR, frameset)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, offset)
	set_cur(OBJ_STATE_DURATION, duration)


## Func_55c2b: its row (low bits cleared) the same as 16 rows above Wario's.
func _muddee_level_above_wario() -> bool:
	return (cur(OBJ_SCREEN_Y_POS) & 0xF8) == (byte(wWarioScreenYPos - 0x10) & 0xF8)


## Func_55c1e's carry: above Wario on the screen.
func _muddee_above_wario() -> bool:
	return byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) < byte(wWarioScreenYPos + 0x2A)


func _muddee_step(up: bool, down: bool, left: bool, right: bool) -> void:
	var slow: bool = (cur(OBJ_SUBSTATE) & 0x0F) == 5  # SFX_085 by Func_55be7 not simulated
	if up:
		if slow:
			move_object_up_slow()
		else:
			move_object_up()
	elif down:
		if slow:
			move_object_down_slow()
		else:
			move_object_down()
	elif left:
		if slow:
			move_object_left_slow()
		else:
			move_object_left()
	elif right:
		if slow:
			move_object_right_slow()
		else:
			move_object_right()


## The battle by OBJ_VAR_1: up (0) or down (1) to 16 rows above Wario, then left (2) or right (3) to a
## wall, turning by Wario (each phase begins at its frameset's offset after its OBJ_STATE_DURATION
## frames); diving (4-5), rising toward Wario (6-7), roaming (8). At full hits it moves a pixel a
## frame, after a hit half.
func _muddee_phase() -> void:
	match cur(OBJ_VAR_1):
		0, 1:
			var up: bool = cur(OBJ_VAR_1) == 0
			if cur(OBJ_STATE_DURATION) != 0:
				set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
				if cur(OBJ_STATE_DURATION) == 0:
					set_object_frameset_ptr(FRAMESET_69D04 if up else FRAMESET_69CF2)
				return
			var blocked: bool
			if up:
				set_hpos_from_object(-0x1C)
				blocked = object_probe(COLLISION_UNK3) != 0
			else:
				set_hpos_from_object(0x30)
				object_probe(COLLISION_UNK1)
				blocked = wIsInWaterOrSand != 0
			if not blocked and not _muddee_level_above_wario():
				_muddee_step(up, not up, false, false)
				return
			var wario_right: bool = wWarioXPos >= cur_x()
			set_cur(OBJ_VAR_1, 3 if wario_right else 2)
			if up:
				_muddee_frameset_at(FRAMESET_69D2F if wario_right else FRAMESET_69D16, 0x0E, 0x7D)
			else:
				_muddee_frameset_at(FRAMESET_69D16 if wario_right else FRAMESET_69D2F, 0x02, 0x7D)
		2, 3:
			var right: bool = cur(OBJ_VAR_1) == 3
			if cur(OBJ_STATE_DURATION) != 0:
				set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
				if cur(OBJ_STATE_DURATION) == 0:
					set_object_frameset_ptr(FRAMESET_69CFB if right else FRAMESET_69D0D)
				return
			set_hpos_from_object(0, 0x18 if right else -0x18)
			if object_probe(COLLISION_UNK4) == 0:
				_muddee_step(false, false, not right, right)
				return
			if _muddee_above_wario():
				set_cur(OBJ_VAR_1, 1)
				_muddee_frameset_at(FRAMESET_69D2F if right else FRAMESET_69D16, 0x14, 0x7D)
			else:
				set_cur(OBJ_VAR_1, 0)
				_muddee_frameset_at(FRAMESET_69D16 if right else FRAMESET_69D2F, 0x08, 0x7D)
		4:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				return
			set_object_frameset_ptr(FRAMESET_69D85)
			set_cur(OBJ_VAR_1, 5)
			set_cur(OBJ_VAR_2, 8)
			set_cur_word(OBJ_Y_POS, cur_y() + 8)  # MoveObjectDownByVar2
		5:
			set_hpos_from_object(0x12)
			if object_probe(COLLISION_UNK1) == 0:
				move_object_down()
				return
			set_cur(OBJ_VAR_1, 6)
		6:
			_muddee_under_wario()
		7:
			if cur(OBJ_VAR_3) != 0x0E:
				apply_obj_y_movement(DATA_60D30)
				return
			if (cur(OBJ_SUBSTATE) & 0x0F) != 3:
				set_cur(OBJ_VAR_1, 0)
				return
			set_cur(OBJ_STATE_DURATION, 0)
			set_cur(OBJ_VAR_1, 8)
			_muddee_roam_start()
		8:
			_muddee_roam()


## .Func_55a2b: under the water, half a pixel a frame toward Wario's x (a wall 64 px up and 8 px ahead
## stops it); under him it comes out (OBJ_VAR_1 7, its stingers out).
func _muddee_under_wario() -> void:
	var x: int = cur_x()
	hYPos = word(cur_y() - 0x40)
	if wWarioXPos == x:
		set_object_frameset_ptr(FRAMESET_69D04)
		set_cur(OBJ_VAR_1, 7)
		set_cur(OBJ_VAR_3, 0)
		_muddee_stingers()
		return
	var right: bool = wWarioXPos > x
	hXPos = word(x + 8 if right else x - 8)
	if object_probe(COLLISION_UNK4) != 0:
		return
	if right:
		move_object_right_slow()
	else:
		move_object_left_slow()


## .asm_55aa3: roaming toward Wario (OBJ_VAR_2 1 right), down if it is above him (VDIR).
func _muddee_roam_start() -> void:
	var right: bool = wWarioXPos >= cur_x()
	set_cur(OBJ_VAR_2, 1 if right else 0)
	set_cur(OBJ_VAR_3, 0)
	if _muddee_above_wario():
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_VDIR)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_VDIR)
	set_object_frameset_ptr(FRAMESET_69DA7 if right else FRAMESET_69D8E)


## .Func_55ad9: its frameset's third loop (at offset $18 as a frame begins) makes it pause (60
## frames, OBJ_VAR_3 $ff) and then aim again; turning out OBJ_STATE_DURATION; otherwise roaming half
## a pixel a frame across (a wall $18 px ahead turning it) and up or down (a ceiling 28 px up or the
## water's surface 48 px down turning it; SFX_0C1 not simulated).
func _muddee_roam() -> void:
	if cur(OBJ_VAR_3) != 0xFF and cur(OBJ_FRAME_DURATION) == 0 and cur(OBJ_FRAMESET_OFFSET) == 0x18:
		set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) + 1)
		if cur(OBJ_VAR_3) == 3:
			set_cur(OBJ_VAR_3, 0xFF)
			set_object_frameset_ptr(FRAMESET_69CF2)
			set_cur(OBJ_STATE_DURATION, 0x3C)
			return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0 or cur(OBJ_VAR_3) != 0xFF:
			return
		set_cur(OBJ_VAR_3, 0)
		_muddee_roam_start()
		return
	var right: bool = (cur(OBJ_VAR_2) & 1) != 0
	set_hpos_from_object(0, 0x18 if right else -0x18)
	if object_probe(COLLISION_UNK4) != 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) ^ 1)
		set_cur(OBJ_STATE_DURATION, 0x28)
	elif right:
		move_object_right_slow()
	else:
		move_object_left_slow()
	var turn: bool
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) == 0:
		set_hpos_from_object(-0x1C)
		turn = object_probe(COLLISION_UNK3) != 0
		if not turn:
			move_object_up_slow()
			return
	else:
		set_hpos_from_object(0x30)
		object_probe(COLLISION_UNK1)
		turn = wIsInWaterOrSand != 0
		if not turn:
			move_object_down_slow()
			return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_VDIR)
	set_cur(OBJ_STATE_DURATION, 0x28)


## .Func_55ba7: no actions; falling along Data_60180 away from its facing for OBJ_VAR_1 frames, then
## still for its OBJ_STATE_DURATION (SFX_0A3 not simulated), then falling on.
func muddee_defeated() -> void:
	_no_actions()
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	elif cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	apply_obj_y_movement(DATA_60180)
	if hdir():
		move_object_left()
	else:
		move_object_right()


## MuddeeStingerFunc: invisible, no collision with objects, kept (OBJSUBFLAG_UNK_4).
func muddee_stinger_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_UNK_4)
	set_cur_word(OBJ_UPDATE_FUNCTION, MUDDEE_STINGER_UPDATE & 0xFFFF)


## .Func_4ca2a: its frame held; touched ($0a) it marks Muddee hit (wMuddeeHit 1), and while Muddee is
## hit it is gone. Otherwise it sits on Muddee (the first active MUDDEE) at the offset of Muddee's
## frame (Data_4caed for the first stinger, Data_4cb0d for the second; frame $10 on, Muddee itself,
## no actions).
func muddee_stinger_update() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	if cur(OBJ_STATE) == OBJSTATE_VANISH_TOUCH:
		wram1[W_MUDDEE_HIT] = 1
	if wram1[W_MUDDEE_HIT] != 0:
		set_cur(OBJ_FLAGS, 0)
		return
	var muddee: int = _active_slot_with_id(MUDDEE)
	if muddee < 0:
		return
	var y: int = _slot_word(muddee, OBJ_Y_POS)
	var x: int = _slot_word(muddee, OBJ_X_POS)
	var frame: int = wram1[muddee + OBJ_FRAME]
	if frame >= 0x10:
		set_cur_word(OBJ_Y_POS, y)
		set_cur_word(OBJ_X_POS, x)
		_no_actions()
		return
	var table: int = DATA_4CB0D if cur(OBJ_ID) == MUDDEE_STINGER2 else DATA_4CAED
	var dy: int = bank_byte(0x13, table + 2 * frame)
	var dx: int = bank_byte(0x13, table + 2 * frame + 1)
	set_cur_word(OBJ_Y_POS, y + (dy - 0x100 if dy >= 0x80 else dy))
	set_cur_word(OBJ_X_POS, x + (dx - 0x100 if dx >= 0x80 else dx))


# --- Muddee's turtles (objects/muddee.asm) ----------------------------------------------------------

## Turtle1Func: the ambush reset (wMuddeeAmbushState 0), visible, kept, a box -11..10 (bottom 4),
## 16 px up, 160 frames; a one-way platform waiting to be stood on.
func turtle_1_func() -> void:
	wram1[W_MUDDEE_AMBUSH_STATE] = 0
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_1_WAIT & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	_turtle_box()
	set_cur(OBJ_STATE_DURATION, 0xA0)
	set_cur(OBJ_VAR_2, 0x10)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x10)  # MoveObjectUpByVar2


func _turtle_box() -> void:
	set_collbox_x(-11, 0x0A)
	set_cur(OBJ_COLLBOX_BOTTOM, 4)
	set_object_frameset_ptr(FRAMESET_69D5C)


## .Func_55c7d and TurtleCommonFunc: a one-way platform until stood on, then carrying (`next`).
func turtle_1_wait() -> void:
	_turtle_wait(TURTLE_1_CARRY)


func turtle_common_func() -> void:
	_turtle_wait(TURTLE_COMMON_CARRY)


func _turtle_wait(next: int) -> void:
	set_one_way_platform_action()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)


## A pixel right on odd frames, carrying a standing Wario unless his side probe (Func_19706) meets a
## wall (SFX_084 not simulated).
func _turtle_carry_right() -> void:
	move_object_right()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	wBlockFuncWarioFlag = 1
	var b: int = check_bottom_right_breaking()
	wBlockFuncWarioFlag = 0
	if b == 0:
		move_wario_right(1)


## .Func_55c91: carrying Wario right for its frames; then stopping (60 frames; SFX_0CA not simulated).
func turtle_1_carry() -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		_turtle_carry_right()
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_1_STOP & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69D65)
	set_cur(OBJ_STATE_DURATION, 0x3C)


## .Func_55cdd: then sinking (40 frames' wait, 64 px), the ambush on (wMuddeeAmbushState 1).
func turtle_1_stop() -> void:
	set_one_way_platform_action()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur(OBJ_VAR_1, 0x40)
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_1_SINK & 0xFFFF)
	wram1[W_MUDDEE_AMBUSH_STATE] = 1


## .Func_55cf9: after its wait, no actions, a pixel down a frame for OBJ_VAR_1 frames; then hidden.
func turtle_1_sink() -> void:
	set_one_way_platform_action()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	_no_actions()
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		move_object_down()
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_1_HIDDEN & 0xFFFF)


## .Func_55d18: no actions until Muddee is defeated (wMuddeeAmbushState 2); then rising (its
## object-map nibble 6).
func turtle_1_hidden() -> void:
	_no_actions()
	if wram1[W_MUDDEE_AMBUSH_STATE] != 2:
		return
	set_object_frameset_ptr(FRAMESET_69D5C)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur(OBJ_VAR_1, 0x40)
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_1_RETURN & 0xFFFF)
	set_cur_object_map_nibble(0x06)


## .Func_55d4c: on odd frames: its wait, ending the battle (wBossState BOSS_DEFEATED, wIsBossBattle
## off; the music not simulated); then up a pixel a frame for OBJ_VAR_1 frames; then a carrying
## turtle again (TurtleCommonFunc, the stepped flag cleared).
func turtle_1_return() -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) == 0:
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			wBossState = BOSS_DEFEATED
			wIsBossBattle = 0
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		move_object_up()
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_COMMON_FUNC & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)


## TurtleCommonFunc.Func_55d90: carrying Wario right on odd frames until a wall 48 px ahead
## (Func_3513); then only a platform (.Func_55de0).
func turtle_common_carry() -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) == 0:
		return
	set_hpos_from_object(0, 0x30)
	if object_probe(COLLISION_UNK4) != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_COMMON_STOPPED & 0xFFFF)
		return
	_turtle_carry_right()


## Turtle2Func: visible, a carrying turtle, its box, 16 px up; gone while the first turtle is out.
func turtle_2_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, TURTLE_COMMON_FUNC & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_turtle_box()
	set_cur(OBJ_VAR_2, 0x10)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x10)  # MoveObjectUpByVar2
	if _active_slot_with_id(TURTLE1) >= 0:
		set_cur(OBJ_FLAGS, 0)


# --- Jamano (objects/jamano.asm) -------------------------------------------------------------------

## JamanoFunc: the battle on (the music's stop not simulated), visible, a box -4..3 (bottom 6), 255
## frames' entrance, 8 px left and 4 up.
func jamano_func() -> void:
	wIsBossBattle = 1
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_REVEAL & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-4, 3)
	set_cur(OBJ_COLLBOX_BOTTOM, 6)
	set_object_frameset_ptr(FRAMESET_69CE9)
	set_cur(OBJ_STATE_DURATION, 0xFF)
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()
	set_cur(OBJ_VAR_2, 4)
	set_cur_word(OBJ_Y_POS, cur_y() - 4)  # MoveObjectUpByVar2


## .Func_54d7d: no actions for its frames (the music at $c0 not simulated); then 255 more
## (Frameset_69cdb, .Func_54daa).
func jamano_reveal() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_69CDB)
	set_cur(OBJ_STATE_DURATION, 0xFF)
	set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_INTRO & 0xFFFF)


## .Func_54daa: no actions for its frames (the music's stop at $30 not simulated); then the battle
## (wBossState BOSS_REGULAR; the music not simulated): in front (PRIORITY), its counters and the intro
## flag (w1d149) cleared, heading toward Wario's side ($5b right with Frameset_69ca1, otherwise $5a
## left with 69c1c).
func jamano_intro() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	wBossState = BOSS_REGULAR
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_MAIN & 0xFFFF)
	for field: int in [OBJ_STATE_DURATION, OBJ_VAR_1, OBJ_VAR_2, OBJ_VAR_3]:
		set_cur(field, 0)
	wram1[W_JAMANO_INTRO] = 0
	var right: bool = _jamano_left_of_wario()
	set_hdir(right)
	set_cur(OBJ_STATE, 0x5B if right else 0x5A)
	set_object_frameset_ptr(FRAMESET_69CA1 if right else FRAMESET_69C1C)


## Jamano's screen x left of Wario's (both $2a on, in a byte).
func _jamano_left_of_wario() -> bool:
	return byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)


## .Func_54e10: on even frames visible and nothing more; on odd ones invisible, then: the dark gone
## (level 0) exposed (.Func_54f9d: visible, 160 frames of Frameset_69ce0; the music's stop not
## simulated); otherwise by OBJ_STATE: roaming left ($5a) or right ($5b), anything else (from an
## action) its frameset by side and then nothing (.Func_54e0a; the music's stop not simulated).
func jamano_main() -> void:
	if (wGlobalCounter & 1) == 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	if wram1[W_JAMANO_DARKNESS] == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_EXPOSED & 0xFFFF)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
		set_object_frameset_ptr(FRAMESET_69CE0)
		set_cur(OBJ_STATE_DURATION, 0xA0)
		return
	match cur(OBJ_STATE):
		0x5A:
			_jamano_roam(false)
		0x5B:
			_jamano_roam(true)
		_:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
			set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_DO_NOTHING & 0xFFFF)
			set_object_frameset_ptr(FRAMESET_69C7A if hdir() else FRAMESET_69C92)


## .asm_54e78 and .asm_54eae: turning toward Wario first (.Func_54f55); at its X table's start
## (OBJ_VAR_2 1) facing the other way, or at a wall 8 px ahead (Func_3513), it turns ($5b and $5a)
## without moving; otherwise across along Data_60c80 (left) or Data_60c20 (right), looping. Then
## up or down.
func _jamano_roam(right: bool) -> void:
	_jamano_face_wario()
	if (cur(OBJ_VAR_2) == 1 and hdir() != right) or _jamano_wall(right):
		set_cur(OBJ_STATE, 0x5A if right else 0x5B)
	else:
		apply_obj_x_movement_loop(DATA_60C20 if right else DATA_60C80)
	_jamano_bob()


## A wall 8 px ahead (Func_3513).
func _jamano_wall(right: bool) -> bool:
	set_hpos_from_object(0, 8 if right else -8)
	return object_probe(COLLISION_UNK4) != 0


## .asm_54efb: at its Y table's start (OBJ_VAR_3 1) heading for Wario's row (.Func_54ee4: down if
## above it). Rising, above screen row $28 it turns down; falling, at row $98, or at rows $7c-$7f with
## a floor 10 px under it (Func_352b), it turns up (a turn restarts the table); along Data_60c80 up or
## Data_60c20 down, looping.
func _jamano_bob() -> void:
	if cur(OBJ_VAR_3) == 1:
		_set_vdir(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) < byte(wWarioScreenYPos + 0x2A))
	var y: int = cur(OBJ_SCREEN_Y_POS)
	var down: bool = (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0
	if not down:
		if y < 0x28:
			_set_vdir(true)
			set_cur(OBJ_VAR_3, 0)
			down = true
	elif y >= 0x98:
		down = false
	elif y >= 0x7C and y < 0x80:
		set_hpos_from_object(10)
		down = object_probe(COLLISION_UNK1) == 0
	if not down and (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0:
		_set_vdir(false)
		set_cur(OBJ_VAR_3, 0)
	apply_obj_y_movement_loop(DATA_60C20 if down else DATA_60C80)


func _set_vdir(down: bool) -> void:
	if down:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_VDIR)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_VDIR)


## .Func_54f55: turning: its frames counted down, and at the end its frameset by the dark's level
## and its side (Func_554bc; unchanged outside levels 1-4) from the start. Otherwise, on the wrong
## side of Wario, turning (20 frames of Frameset_69c7a left or 69c92 right; SFX_0BC not simulated).
func _jamano_face_wario() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			return
		var frameset: int = _jamano_frameset(cur(OBJ_SUBSTATE))
		if frameset >= 0:
			set_cur_word(OBJ_FRAMESET_PTR, frameset)
		set_cur(OBJ_FRAME_DURATION, 0)
		set_cur(OBJ_FRAMESET_OFFSET, 0)
		return
	var right: bool = _jamano_left_of_wario()
	if right == hdir():
		return
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_69C92 if right else FRAMESET_69C7A)
	set_cur(OBJ_STATE_DURATION, 0x14)


## Func_554bc: Jamano's frameset by the dark's level (1-4) and its side, or -1.
func _jamano_frameset(substate: int) -> int:
	var level: int = wram1[W_JAMANO_DARKNESS]
	if level < 1 or level > 4:
		return -1
	var framesets: Array[int] = JAMANO_FRAMESETS_RIGHT if (substate & OBJSUBFLAG_HDIR) != 0 else JAMANO_FRAMESETS_LEFT
	return framesets[level - 1]


## .Func_54f9d: no actions; after its frames, at screen x $58 losing its hat (.Func_5507b: 40 frames
## of Frameset_69c40; SFX_0BD not simulated). Otherwise bouncing about a pixel a frame: across by
## OBJ_STATE ($5a left, $5b right; a wall 8 px ahead, Func_3513, turns it without moving; SFX_BUMP
## not simulated), and up to screen row $30, then down to row $7c and on to a floor 10 px under it
## (Func_352b).
func jamano_exposed() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	elif cur(OBJ_SCREEN_X_POS) == 0x58:
		set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_HAT_OFF_1 & 0xFFFF)
		set_object_frameset_ptr(FRAMESET_69C40)
		set_cur(OBJ_STATE_DURATION, 0x28)
		return
	var state: int = cur(OBJ_STATE)
	if state != 0x5A and state != 0x5B:
		return
	var right: bool = state == 0x5B
	if _jamano_wall(right):
		set_cur(OBJ_STATE, 0x5A if right else 0x5B)
	elif right:
		move_object_right()
	else:
		move_object_left()
	var y: int = cur(OBJ_SCREEN_Y_POS)
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) == 0:
		if y >= 0x30:
			move_object_up()
			return
		_set_vdir(true)
		move_object_down()
		return
	if y < 0x7C:
		move_object_down()
		return
	set_hpos_from_object(10)
	if object_probe(COLLISION_UNK1) == 0:
		move_object_down()
		return
	_set_vdir(false)
	move_object_up()


## .Func_5507b and .Func_55097: no actions; after 40 frames the next frameset (Frameset_69c45, 69c4a)
## for 40 more.
func jamano_hat_off_1() -> void:
	_jamano_hat_off_step(JAMANO_HAT_OFF_2, FRAMESET_69C45)


func jamano_hat_off_2() -> void:
	_jamano_hat_off_step(JAMANO_HAT_OFF_3, FRAMESET_69C4A)


func _jamano_hat_off_step(next: int, frameset: int) -> bool:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return false
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 0x28)
	return true


## .Func_550b3: likewise (Frameset_69c4f, .Func_550db), and 15 px up its hat flies off
## (ObjParams_JamanoHat).
func jamano_hat_off_3() -> void:
	if not _jamano_hat_off_step(JAMANO_DEFEATED, FRAMESET_69C4F):
		return
	set_cur(OBJ_VAR_2, 0x0F)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x0F)  # MoveObjectUpByVar2
	create_object_at_relative_pos(OBJ_PARAMS_JAMANO_HAT)


## .Func_550db: no actions; after its frames falling (.Func_550ff), the substate's low bits and
## OBJ_VAR_2 and _3 cleared (SFX_0A3 not simulated).
func jamano_defeated() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_FALL & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 0)


## .Func_550ff: no actions, falling along Data_60d20.
func jamano_fall() -> void:
	_no_actions()
	apply_obj_y_movement(DATA_60D20)


## JamanoHatFunc: no actions; after its frames rising 3 px a frame (.Func_55125, 60 frames).
func jamano_hat_func() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur(OBJ_VAR_2, 3)
	set_cur_word(OBJ_UPDATE_FUNCTION, JAMANO_HAT_RISE & 0xFFFF)


## .Func_55125: no actions; rising while on screen; off it, after its frames, gone (its object-map
## nibble 6, Func_ba42) and the boss defeated (wBossState BOSS_DEFEATED, wIsBossBattle off; the
## music not simulated).
func jamano_hat_rise() -> void:
	_no_actions()
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		set_cur_word(OBJ_Y_POS, cur_y() - cur(OBJ_VAR_2))  # MoveObjectUpByVar2
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, 0)
	set_cur_object_map_nibble(0x06)
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0


## HatPlatformFunc: visible, a box -6..5 (bottom 0), Frameset_69cef, going down (OBJ_VAR_1 1, its
## frames and state cleared), 8 px left and $5a up.
func hat_platform_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur_word(OBJ_UPDATE_FUNCTION, HAT_PLATFORM_UPDATE & 0xFFFF)
	set_collbox_x(-6, 5)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_object_frameset_ptr(FRAMESET_69CEF)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_VAR_1, 1)
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()
	set_cur(OBJ_VAR_2, 0x5A)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x5A)  # MoveObjectUpByVar2


## .Func_55194: a one-way platform moving a pixel on odd frames, carrying a Wario standing on it:
## down $30 px (OBJ_VAR_1 set; a state stops it early, and is cleared), then up as many.
func hat_platform_update() -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) == 0:
		return
	var stepped: bool = (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0
	if cur(OBJ_VAR_1) == 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur(OBJ_VAR_1, 1)
			return
		if stepped:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
			move_wario_up(1)
			handle_upwards_floor_transition()
		move_object_up()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) + 1)
	if cur(OBJ_STATE_DURATION) == 0x30 or cur(OBJ_STATE) != 0:
		set_cur(OBJ_VAR_1, 0)
		set_cur(OBJ_STATE, 0)
		return
	if stepped:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		move_wario_down(1)
		handle_downwards_floor_transition()
	move_object_down()


# --- Jamano's skulls (objects/jamano.asm) ----------------------------------------------------------

## SkullSpawnerFunc: 8 px left and $14 up, its four skulls (ObjParams_Skull1-4) all out, none at
## the edges, no dark, and the intro on (w1d149).
func skull_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_SPAWNER_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()
	set_cur(OBJ_VAR_2, 0x14)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x14)  # MoveObjectUpByVar2
	for params: int in OBJ_PARAMS_SKULLS:
		create_object_at_relative_pos(params)
	wram1[W_JAMANO_ACTIVE_SKULLS] = 0x0F
	wram1[W_JAMANO_SKULLS_OUT] = 0
	wram1[W_JAMANO_DARKNESS] = 0
	wram1[W_JAMANO_INTRO] = 1


## .Func_5522c: no actions, its frame held; past the intro with no dark left, gone (its object-map
## nibble 7, Func_ba42). Otherwise the dark's level updated (Func_55407) and the first skull missing
## from wJamanoActiveSkulls brought back.
func skull_spawner_update() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	if wram1[W_JAMANO_INTRO] == 0 and wram1[W_JAMANO_DARKNESS] == 0:
		set_cur(OBJ_FLAGS, 0)
		set_cur_object_map_nibble(0x07)
		return
	_jamano_update_darkness()
	var active: int = wram1[W_JAMANO_ACTIVE_SKULLS]
	for i: int in 4:
		if (active & (1 << i)) == 0:
			wram1[W_JAMANO_ACTIVE_SKULLS] = active | (1 << i)
			create_object_at_relative_pos(OBJ_PARAMS_SKULLS[i])
			return


## Func_55407: the dark's level follows the skulls at the edges (w1d147) a step at a time: up from
## level n (below 4) when n + 1 are there, down when n - 1 are (from 4 or more, when 3 are). Each
## step but the one to 0 also sets Jamano's frameset (.Func_5548b; the palettes are presentation).
func _jamano_update_darkness() -> void:
	var out: int = wram1[W_JAMANO_SKULLS_OUT]
	var level: int = wram1[W_JAMANO_DARKNESS]
	var next: int
	match level:
		0:
			if out != 1:
				return
			next = 1
		1, 2, 3:
			if out == level + 1:
				next = level + 1
			elif out == level - 1:
				next = level - 1
			else:
				return
		_:
			if out != 3:
				return
			next = level - 1
	wram1[W_JAMANO_DARKNESS] = next
	if next != 0:
		_jamano_set_frameset()


## .Func_5548b: past the intro, the first active Jamano's frameset pointer (only) by the dark's level
## and its side (Func_554bc), unless it is turning (OBJ_STATE_DURATION).
func _jamano_set_frameset() -> void:
	if wram1[W_JAMANO_INTRO] != 0:
		return
	var base: int = _active_slot_with_id(JAMANO)
	if base < 0 or wram1[base + OBJ_STATE_DURATION] != 0:
		return
	var frameset: int = _jamano_frameset(wram1[base + OBJ_SUBSTATE])
	if frameset < 0:
		return
	wram1[base + OBJ_FRAMESET_PTR] = lo(frameset)
	wram1[base + OBJ_FRAMESET_PTR + 1] = hi(frameset)


## .Func_553e8: during the intro or while dark, blinking (invisible on even frames); otherwise gone
## (the caller still runs on).
func _skull_blink() -> void:
	if wram1[W_JAMANO_INTRO] == 0 and wram1[W_JAMANO_DARKNESS] == 0:
		set_cur(OBJ_FLAGS, 0)
	elif (wGlobalCounter & 1) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)


## SkullFunc: blinking, no actions, then waiting (.Func_5529f).
func skull_func() -> void:
	_skull_blink()
	_no_actions()
	set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_WAIT & 0xFFFF)


## .Func_5529f: blinking, no actions, its frame held; after its frames (60) its delay (.Func_552ba).
func skull_wait() -> void:
	_skull_blink()
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_DELAY & 0xFFFF)


## .Func_552ba: blinking, no actions; after OBJ_VAR_1 frames (100 to 160 by skull) flying out in
## front (.Func_552d4, PRIORITY).
func skull_delay() -> void:
	_skull_blink()
	_no_actions()
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_FLY & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)


## .Func_552d4: blinking, no actions; skulls 1 and 2 a pixel left a frame to screen x $10, 3 and 4
## right to SCREEN_WIDTH_PX, bobbing (Data_60ce0 for 1 and 3, Data_60d00 for 2 and 4); there, one
## more at the edges (w1d147) and 39 frames' wait (.Func_5531c).
func skull_fly() -> void:
	_skull_blink()
	_no_actions()
	var id: int = cur(OBJ_ID)
	var right: bool = id >= SKULL3
	if cur(OBJ_SCREEN_X_POS) == (SCREEN_WIDTH_PX if right else 0x10):
		set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_AT_EDGE & 0xFFFF)
		set_cur(OBJ_STATE_DURATION, 0x27)
		wram1[W_JAMANO_SKULLS_OUT] = byte(wram1[W_JAMANO_SKULLS_OUT] + 1)
		return
	if right:
		move_object_right()
	else:
		move_object_left()
	apply_obj_y_movement(DATA_60D00 if (id & 1) != 0 else DATA_60CE0)


## .Func_5531c: blinking, no actions; after its frames, at its frameset's third frame, visible and
## behind (PRIORITY off), waiting at the edge (.Func_55347, Frameset_69cd6).
func skull_at_edge() -> void:
	_skull_blink()
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if cur(OBJ_FRAMESET_OFFSET) != 2:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~(OBJFLAG_PRIORITY | OBJFLAG_INVISIBLE))
	set_cur_word(OBJ_UPDATE_FUNCTION, SKULL_OUT & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69CD6)


## .Func_55347: during the intro, no actions and blinking. After it, visible; attacked (OBJ_STATE
## $04, $05) knocked away (.Func_553a0 right, .Func_55396 left; OBJ_VAR_2 1, OBJ_VAR_3 cleared, 255
## frames of Frameset_69cec, no actions; SFX_017 not simulated): one fewer at the edges.
func skull_out() -> void:
	if wram1[W_JAMANO_INTRO] != 0:
		_no_actions()
		_skull_blink()
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	var state: int = cur(OBJ_STATE)
	if state != 0x04 and state != 0x05:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, (SKULL_KNOCKED_RIGHT if state == 0x04 else SKULL_KNOCKED_LEFT) & 0xFFFF)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 1)
	set_object_frameset_ptr(FRAMESET_69CEC)
	set_cur(OBJ_STATE_DURATION, 0xFF)
	_no_actions()
	wram1[W_JAMANO_SKULLS_OUT] = byte(wram1[W_JAMANO_SKULLS_OUT] - 1)


## .Func_55396 and .Func_553a0: knocked left (Func_3317) or right (Func_3326) while on screen; off
## it, no actions, and after its frames gone, its bit off wJamanoActiveSkulls (SFX_0BF at $f7 not
## simulated).
func skull_knocked_left() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		func_62898()
		return
	_skull_gone_after_frames()


func skull_knocked_right() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		func_62840()
		return
	_skull_gone_after_frames()


func _skull_gone_after_frames() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, 0)
	var index: int = cur(OBJ_ID) - SKULL1
	if index < 0 or index > 2:
		index = 3
	wram1[W_JAMANO_ACTIVE_SKULLS] = wram1[W_JAMANO_ACTIVE_SKULLS] & ~(1 << index) & 0xFF


# --- Shoot (objects/shoot.asm) ---------------------------------------------------------------------

## ShootFunc: the battle on (the music's stop not simulated), wShootCanTurnAround and wShootBallState
## cleared, visible, kept (OBJSUBFLAG_UNK_4) with 5 in the substate's low bits, a box -8..7 (bottom
## -8), 80 frames' taunt (Frameset_69f7c) once on screen (.StartWait), 32 px up and 96 right.
func shoot_func() -> void:
	wIsBossBattle = 1
	wram1[W_SHOOT_CAN_TURN_AROUND] = 0
	wram1[W_SHOOT_BALL_STATE] = 0
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_START_WAIT & 0xFFFF)
	var substate: int = (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4
	set_cur(OBJ_SUBSTATE, (substate & OBJSUBFLAGS_MASK) | 5)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -8)
	set_object_frameset_ptr(FRAMESET_69F7C)
	set_cur(OBJ_STATE_DURATION, SHOOT_TAUNT_DURATION)
	set_cur(OBJ_VAR_2, 32)
	set_cur_word(OBJ_Y_POS, cur_y() - 32)  # MoveObjectUpByVar2
	set_cur(OBJ_VAR_2, 96)
	move_object_right_by_var2()


## .StartWait: on screen, taunting.
func shoot_start_wait() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_TAUNT & 0xFFFF)


## .Taunt: (SFX_0C6 every 16 frames not simulated) after its frames the game: OBJ_INTERACTION_SHOOT
## (its weight kept), wShootBallState 1, wBossState BOSS_REGULAR (the music not simulated), standing.
func shoot_taunt() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_MAIN & 0xFFFF)
	set_interaction(OBJ_INTERACTION_SHOOT)
	wram1[W_SHOOT_BALL_STATE] = 1
	wBossState = BOSS_REGULAR
	_shoot_set_standing()


## .Main, by OBJ_STATE: none, its phase (OBJ_VAR_1); $0e (SFX_0C9 not simulated) out of the ball
## toward its back, $04 to the right, $05 to the left; OBJSTATE_SPECIAL_3, Wario's ball caught; a
## wobble or a touch's vanish, stepped on into a ball; anything else cleared.
func shoot_main() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_shoot_phase()
	elif state == 0x0E:
		_shoot_jump_out_of_ball(not hdir())
	elif state == 0x04:
		_shoot_jump_out_of_ball(true)
	elif state == 0x05:
		_shoot_jump_out_of_ball(false)
	elif state == OBJSTATE_SPECIAL_3:
		_shoot_catch_ball_wario()
	elif (state & 0xFE) == OBJSTATE_WOBBLE_LEFT_START or (state & 0xFE) == OBJSTATE_VANISH_TOUCH:
		_shoot_stepped_on()
	else:
		set_cur(OBJ_STATE, 0)


## .jump_out_of_ball: its state cleared, heading right (VDIR) or left, jumping up 2 px a frame across
## (Frameset_6a022 or _6a03a by its facing, from their second pair).
func _shoot_jump_out_of_ball(right: bool) -> void:
	set_cur(OBJ_STATE, 0)
	_set_vdir(right)
	var frameset: int = (FRAMESET_6A03A if hdir() else FRAMESET_6A022) + 2
	set_cur(OBJ_VAR_2, SHOOT_OUT_OF_BALL_X_SPEED)
	_shoot_set_jumping_up(frameset)


## .interacted_with_ball_wario: its state and OBJ_VAR_3 cleared, 16 px up, the pre-kick jump
## (Frameset_69ffd) a pixel a frame across; Wario's ball 16 px under it (the low bytes: his y's high
## byte only takes the carry, his x's stays; SFX_FAT_WALK not simulated); facing right, heading right
## (the check against x 123 sees the SFX's low byte, $3b, so it always heads right).
func _shoot_catch_ball_wario() -> void:
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 16)
	set_cur_word(OBJ_Y_POS, cur_y() - 16)  # MoveObjectUpByVar2
	set_object_frameset_ptr(FRAMESET_69FFD)
	set_cur(OBJ_VAR_1, SHOOTPHASE_PREKICK_JUMP)
	set_cur(OBJ_VAR_2, SHOOT_PRESHOOT_X_SPEED)
	var y: int = lo(cur_y()) + 16
	wWarioYPos = word(((hi(wWarioYPos) + (y >> 8)) << 8) | (y & 0xFF))
	wWarioXPos = (wWarioXPos & 0xFF00) | lo(cur_x())
	set_hdir(true)
	_set_vdir(true)


## .HandleNormalState: by OBJ_VAR_1.
func _shoot_phase() -> void:
	match cur(OBJ_VAR_1):
		SHOOTPHASE_STANDING:
			_shoot_count_down_then(_shoot_jump)
		SHOOTPHASE_JUMPING_UP:
			_shoot_jumping_up()
		SHOOTPHASE_JUMPING_DOWN:
			_shoot_jumping_down()
		SHOOTPHASE_BETWEEN_JUMPS:
			_shoot_count_down_then(_shoot_set_standing)
		SHOOTPHASE_TURNING:
			_shoot_turning()
		SHOOTPHASE_PREKICK_JUMP:
			_shoot_prekick_jump()
		SHOOTPHASE_PREKICK_ANIMATION:
			_shoot_prekick_animation()
		SHOOTPHASE_KICKING:
			_shoot_kicking()
		SHOOTPHASE_SCORE_GOAL:
			_shoot_score_goal()
		SHOOTPHASE_WON:
			_no_actions()
		_:
			note_unported("ShootFunc phase %02x" % cur(OBJ_VAR_1))


## OBJ_STATE_DURATION counted down, then `then`.
func _shoot_count_down_then(then: Callable) -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		then.call()


## .set_standing: heading the way it faces (VDIR), standing 27 frames (Frameset_6a022 left, _6a03a
## right), to jump a pixel a frame across.
func _shoot_set_standing() -> void:
	var right: bool = hdir()
	_set_vdir(right)
	set_object_frameset_ptr(FRAMESET_6A03A if right else FRAMESET_6A022)
	set_cur(OBJ_STATE_DURATION, SHOOT_IDLE_DURATION)
	set_cur(OBJ_VAR_1, SHOOTPHASE_STANDING)
	set_cur(OBJ_VAR_2, SHOOT_JUMP_X_SPEED)


## .Standing's end: jumping up (Frameset_6a02b left, _6a043 right).
func _shoot_jump() -> void:
	_shoot_set_jumping_up(FRAMESET_6A043 if hdir() else FRAMESET_6A02B)


## .set_jumping_up: 22 frames up (SFX_0C8 not simulated).
func _shoot_set_jumping_up(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, SHOOT_JUMP_UP_DURATION)
	set_cur(OBJ_VAR_1, SHOOTPHASE_JUMPING_UP)
	set_cur(OBJ_VAR_3, 0)


## .JumpingUp: along Data_603d0 and across for its frames; then falling.
func _shoot_jumping_up() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_VAR_1, SHOOTPHASE_JUMPING_DOWN)
		set_cur(OBJ_VAR_3, 0)
		return
	apply_obj_y_movement(DATA_603D0)
	_shoot_move_left_or_right()


## .JumpingDown: along Data_603e0 and across. A floor at it (Func_352b) lands it there (hYPos as the
## probe leaves it); one 16, 32 or 48 px under it (hXPos kept) sets that height's falling frameset
## afresh (Frameset_6a034, _6a031, _6a02e left; _6a04c, _6a049, _6a046 right).
func _shoot_jumping_down() -> void:
	apply_obj_y_movement(DATA_603E0)
	_shoot_move_left_or_right()
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) != 0:
		store_object_y_from_hpos()
		_shoot_land()
		return
	var left: Array[int] = [FRAMESET_6A034, FRAMESET_6A031, FRAMESET_6A02E]
	var right: Array[int] = [FRAMESET_6A04C, FRAMESET_6A049, FRAMESET_6A046]
	for i: int in 3:
		hYPos = word(cur_y() + 16 * (i + 1))
		if object_probe(COLLISION_UNK1) != 0:
			set_object_frameset_ptr(right[i] if hdir() else left[i])
			return


## .still_more_goals_needed: Wario (his x's low byte under 192) on its other side (the low bytes
## compared), or wShootCanTurnAround, turns it (42 frames of Frameset_69f35 left or _69f40 right, the
## flag cleared); otherwise it lands (Frameset_6a037 or _6a04f) and waits before the next jump (25
## frames, 2 once Wario has a goal).
func _shoot_land() -> void:
	var turn: bool = false
	var wario_x: int = lo(wWarioXPos)
	if wario_x < 192:
		turn = (lo(cur_x()) < wario_x) != hdir()
	if turn or wram1[W_SHOOT_CAN_TURN_AROUND] != 0:
		set_object_frameset_ptr(FRAMESET_69F40 if hdir() else FRAMESET_69F35)
		set_cur(OBJ_STATE_DURATION, SHOOT_TURN_AROUND_DURATION)
		set_cur(OBJ_VAR_1, SHOOTPHASE_TURNING)
		wram1[W_SHOOT_CAN_TURN_AROUND] = 0
		return
	set_object_frameset_ptr(FRAMESET_6A04F if hdir() else FRAMESET_6A037)
	set_cur(OBJ_STATE_DURATION, SHOOT_JUMP_DELAY_SHORT if wram1[W_WARIO_GOALS] != 0 else SHOOT_JUMP_DELAY_LONG)
	set_cur(OBJ_VAR_1, SHOOTPHASE_BETWEEN_JUMPS)


## .Turning: halfway through its frames facing the other way; at the end standing.
func _shoot_turning() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_shoot_set_standing()
	elif cur(OBJ_STATE_DURATION) == SHOOT_TURN_AROUND_DURATION >> 1:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)


## .MoveLeftOrRight: OBJ_VAR_2 px across the way it heads (VDIR right) between x's low byte 27 and 219;
## there heading back (SFX_08D not simulated), free to turn (wShootCanTurnAround) if it faced that
## edge.
func _shoot_move_left_or_right() -> void:
	var x: int = lo(cur_x())
	var faced: bool
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) == 0:
		if x >= 27:
			move_object_left_by_var2()
			return
		_set_vdir(true)
		faced = not hdir()
	else:
		if x < 219:
			move_object_right_by_var2()
			return
		_set_vdir(false)
		faced = hdir()
	if faced:
		wram1[W_SHOOT_CAN_TURN_AROUND] = 1


## .PreKickJump: across with Wario (.DoPreKickingXMovement), up and down with him along Data_54000;
## its y's low byte at 224 or more, the kick's run-up (Frameset_6a000): 16 px down, then it and Wario
## at y's low byte 240 (his high byte its own) and his x's low byte its own plus 8.
func _shoot_prekick_jump() -> void:
	var b: int = cur(OBJ_VAR_2)
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) != 0:
		move_object_right_by_var2()
		move_wario_right(b)
	else:
		move_object_left_by_var2()
		move_wario_left(b)
	do_prekicking_jump_y_movement(DATA_54000)
	if lo(cur_y()) < 224:
		return
	set_object_frameset_ptr(FRAMESET_6A000)
	set_cur(OBJ_VAR_1, SHOOTPHASE_PREKICK_ANIMATION)
	set_cur(OBJ_VAR_2, 16)
	set_cur_word(OBJ_Y_POS, cur_y() + 16)  # MoveObjectDownByVar2
	set_cur(OBJ_Y_POS, 240)
	wWarioYPos = (hi(cur_y()) << 8) | 240
	wWarioXPos = (wWarioXPos & 0xFF00) | byte(lo(cur_x()) + 8)


## The next entry of a bank-$15 table at OBJ_VAR_3 (at the $80 end the last again, the index kept).
func _bank_15_step(table: int) -> int:
	var c: int = byte(lo(table) + cur(OBJ_VAR_3))
	var a: int = bank_byte(0x15, (table & 0xFF00) | c)
	if a == 0x80:
		return bank_byte(0x15, (table & 0xFF00) | byte(c - 1))
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) + 1)
	return a


## DoPreKickingJumpYMovement: the next entry moves it and Wario together, down
## (HandleDownwardsFloorTransition) or up (HandleUpwardsFloorTransition).
func do_prekicking_jump_y_movement(table: int) -> void:
	var b: int = _bank_15_step(table)
	add_y_signed(b)
	if b < 0x80:
		move_wario_down(b)
		handle_downwards_floor_transition()
	else:
		move_wario_up(byte(-b))
		handle_upwards_floor_transition()


## ApplyYOffsetOnKickedWarioBall: the next entry moves Wario down, unsigned (MoveWarioDown's add with
## carry), then HandleDownwardsFloorTransition.
func apply_y_offset_on_kicked_wario_ball(table: int) -> void:
	move_wario_down(_bank_15_step(table))
	handle_downwards_floor_transition()


## .PreKickAnimation: at the end of a frame: at offset 6 Wario 8 px right (his x's low byte;
## SFX_HANG_GRAB not simulated), at 10 kicking (Frameset_69f54).
func _shoot_prekick_animation() -> void:
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	var offset: int = cur(OBJ_FRAMESET_OFFSET)
	if offset == 6:
		wWarioXPos = (wWarioXPos & 0xFF00) | byte(lo(wWarioXPos) + 8)
	elif offset == 10:
		set_cur(OBJ_VAR_1, SHOOTPHASE_KICKING)
		set_object_frameset_ptr(FRAMESET_69F54)


## .Kicking: a kicked ball moved on; at the end of a frame: at offset 4 the kick (SHOOTBALL_WARIO_KICKED,
## OBJ_VAR_3 cleared, wAutoMoveState $82; SFX_034 not simulated), at 8 waiting for the goal
## (Frameset_6a00b).
func _shoot_kicking() -> void:
	if wram1[W_SHOOT_BALL_STATE] == SHOOTBALL_WARIO_KICKED:
		_shoot_move_wario_ball_after_kick()
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	var offset: int = cur(OBJ_FRAMESET_OFFSET)
	if offset == 4:
		wram1[W_SHOOT_BALL_STATE] = SHOOTBALL_WARIO_KICKED
		set_cur(OBJ_VAR_3, 0)
		wAutoMoveState = 0x82
	elif offset == 8:
		set_cur(OBJ_VAR_1, SHOOTPHASE_SCORE_GOAL)
		set_object_frameset_ptr(FRAMESET_6A00B)


## .ScoreGoal: the ball moved on until it is in the net (SHOOTBALL_WARIO_GOAL); then Shoot's goal
## (wShootGoals; at 3 already `b` would be stale, not ported), wAutoMoveState $81 (SFX_0C7 not
## simulated), free to turn, heading left; at 3 goals won, otherwise as on landing.
func _shoot_score_goal() -> void:
	if wram1[W_SHOOT_BALL_STATE] != SHOOTBALL_WARIO_GOAL:
		_shoot_move_wario_ball_after_kick()
		return
	var goals: int = wram1[W_SHOOT_GOALS]
	if goals == NUM_SHOOT_GOALS_NEEDED:
		note_unported("ShootFunc.ScoreGoal with %d goals" % goals)
		return
	goals += 1
	wram1[W_SHOOT_GOALS] = goals
	wShootGoals = goals
	wAutoMoveState = 0x81
	wram1[W_SHOOT_CAN_TURN_AROUND] = 1
	_set_vdir(false)
	if goals != NUM_SHOOT_GOALS_NEEDED:
		_shoot_land()
		return
	set_cur(OBJ_VAR_1, SHOOTPHASE_WON)


## .MoveWarioBallAfterKick: Wario's ball (his x's low byte under 237) 3 px right, rising along
## Data_54010; in the net down 3 px a frame to his y's low byte 240, then SHOOTBALL_WARIO_GOAL.
func _shoot_move_wario_ball_after_kick() -> void:
	if lo(wWarioXPos) < 237:
		apply_y_offset_on_kicked_wario_ball(DATA_54010)
		move_wario_right(3)
	elif lo(wWarioYPos) < 240:
		move_wario_down(3)
	else:
		wram1[W_SHOOT_BALL_STATE] = SHOOTBALL_WARIO_GOAL


## .stepped_on: a ball (Frameset_69f5d, .BallForm) that harms Wario (OBJ_INTERACTION_01, the whole
## byte), a box top -18 and bottom 0.
func _shoot_stepped_on() -> void:
	set_object_frameset_ptr(FRAMESET_69F5D)
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_BALL_FORM & 0xFFFF)
	set_cur(OBJ_INTERACTION_TYPE, OBJ_INTERACTION_01)
	set_cur(OBJ_COLLBOX_TOP, -18)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	shoot_ball_form()


## .BallForm: grabbable (OBJFLAG_GRABBED) while its x's low byte is under 219; by OBJ_STATE, its own
## entries or the shared routines; the rest falling ($30, OBJ_VAR_3 cleared).
func shoot_ball_form() -> void:
	if lo(cur_x()) < 219:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	var state: int = cur(OBJ_STATE)
	match state:
		0x01:
			_shoot_ball_start()
		0x02, 0x08, 0x0B:
			_shoot_ball_knocked(0x38)
		0x03, 0x09, 0x0C:
			_shoot_ball_knocked(0x39)
		0x04:
			_set_vdir(true)
			_shoot_ball_kicked(0x34, FRAMESET_69F9F)
		0x05:
			_set_vdir(false)
			_shoot_ball_kicked(0x35, FRAMESET_69FA4)
		0x0A:
			# .Func_56b96 (SFX_014 not simulated): away from Wario's side.
			var right_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A)
			_shoot_ball_knocked(0x38 if right_of_wario else 0x39)
		0x11, 0x12:
			set_cur(OBJ_STATE, 0x41)
			set_cur(OBJ_VAR_3, 0)
		0x14, 0x15:
			set_cur(OBJ_STATE, 0x30 + state)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
		0x16, 0x17:
			set_cur(OBJ_STATE, 0x30 + state)
		0x28, 0x29:
			set_cur(OBJ_STATE, 0x2D)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			set_object_frameset_ptr(FRAMESET_69F5D)
		0x2D:
			_shoot_ball_wait()
		0x31:
			_shoot_ball_hop()
		0x34, 0x35:
			_shoot_ball_bounce()
		0x46:
			if cur(OBJ_VAR_2) != 0:
				func_62ae5()  # Func_32ae
			else:
				set_cur(OBJ_STATE, 0x0F)
		0x47:
			if cur(OBJ_VAR_2) != 0:
				func_62bce()  # Func_32bd
			else:
				set_cur(OBJ_STATE, 0x0F)
		_:
			if state in SHOOT_BALL_SHARED_STATES:
				common_enemy_state(state)
			elif state < 0x60:
				set_cur(OBJ_STATE, 0x30)  # .Func_56b20
				set_cur(OBJ_VAR_3, 0)
			else:
				note_unported("ShootFunc.BallForm state %02x" % state)


## .return_to_regular_form: not grabbable, back to .Main with OBJ_STATE $05 (out of the ball to the
## left), facing left, OBJ_INTERACTION_SHOOT (heavy), a box top -32 and bottom -8.
func _shoot_return_to_regular_form() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_MAIN & 0xFFFF)
	set_cur(OBJ_STATE, 0x05)
	set_hdir(false)
	set_cur(OBJ_INTERACTION_TYPE, OBJ_INTERACTION_SHOOT | HEAVY_OBJ)
	set_cur(OBJ_COLLBOX_TOP, -32)
	set_cur(OBJ_COLLBOX_BOTTOM, -8)


## .Func_56b2a (OBJ_STATE 1): hopping ($31) for 256 frames (160 once Wario has 2 goals), then .Func_56b47.
func _shoot_ball_start() -> void:
	set_cur(OBJ_STATE, 0x31)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_1, SHOOT_LAST_GOAL_BALL_DURATION if wram1[W_WARIO_GOALS] >= 2 else 0)
	set_object_frameset_ptr(FRAMESET_69F5D)
	_shoot_ball_hop()


## .Func_56b47 ($31): hopping along Data_60e40, looping (SFX not simulated), OBJ_VAR_1 counting down:
## Frameset_69f66 at 100 left, _69f93 at 18; at the end back to its regular form.
func _shoot_ball_hop() -> void:
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	var left: int = cur(OBJ_VAR_1)
	if left == 0:
		_shoot_return_to_regular_form()
		return
	if left == 0x12:
		set_object_frameset_ptr(FRAMESET_69F93)
	elif left == 0x64:
		set_object_frameset_ptr(FRAMESET_69F66)
	apply_obj_y_movement_loop(DATA_60E40)


## .Func_56bae and .Func_56bb8: knocked ($38 or $39): 15 frames without actions, Frameset_69f5d,
## 4 frames, 2 px a frame, OBJ_VAR_3 cleared.
func _shoot_ball_knocked(state: int) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 15)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_69F5D)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)


## .Func_56c1b and .Func_56c3d: kicked ($34 right, $35 left), OBJ_VAR_3 cleared, 2 px a frame
## across with its y's low byte at 216 or more, otherwise 4.
func _shoot_ball_kicked(state: int, frameset: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2 if lo(cur_y()) >= 216 else 4)
	set_object_frameset_ptr(frameset)


## .Func_56c49 ($34, $35): no actions (after a turn, Frameset_69f5d and the flag cleared); across
## (.Func_56cdb) and bouncing along Data_60e70 (at 4 px a frame) or Data_60e20, down to y's low byte
## 240. There, after GK Tortoise threw it back (wShootBallState 4): Wario's third goal defeats Shoot,
## otherwise back to its regular form (wShootBallState 1). Otherwise heading left $09; right, with
## x's low byte under 219, $08; past that in the net ($2d): Wario's goal (wShootBallState 2, up to 3;
## SFX_0C7 and at the third the music's stop not simulated), Frameset_69f9a.
func _shoot_ball_bounce() -> void:
	_no_actions()
	if wram1[W_SHOOT_CAN_TURN_AROUND] != 0:
		wram1[W_SHOOT_CAN_TURN_AROUND] = 0
		set_object_frameset_ptr(FRAMESET_69F5D)
	_shoot_ball_across()
	apply_obj_y_movement(DATA_60E70 if cur(OBJ_VAR_2) == 4 else DATA_60E20)
	if lo(cur_y()) < 240:
		return
	set_cur(OBJ_Y_POS, 240)
	if wram1[W_SHOOT_BALL_STATE] == 4:
		if wram1[W_WARIO_GOALS] == NUM_WARIO_GOALS_NEEDED:
			_shoot_set_defeated()
			return
		wram1[W_SHOOT_BALL_STATE] = 1
		_shoot_return_to_regular_form()
		return
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) == 0:
		set_cur(OBJ_STATE, 0x09)
		return
	if lo(cur_x()) < 219:
		set_cur(OBJ_STATE, 0x08)
		return
	set_cur(OBJ_STATE, 0x2D)
	wram1[W_SHOOT_BALL_STATE] = 2
	if wram1[W_WARIO_GOALS] != NUM_WARIO_GOALS_NEEDED:
		wram1[W_WARIO_GOALS] += 1
	set_object_frameset_ptr(FRAMESET_69F9A)


## .Func_56cdb: OBJ_VAR_2 px left to x's low byte 27, or right to 219 (below y's low byte 208: to 243,
## into the net); at an edge heading back, free to turn (SFX_01A not simulated).
func _shoot_ball_across() -> void:
	var x: int = lo(cur_x())
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_VDIR) == 0:
		if x >= 27:
			move_object_left_by_var2()
			return
		_set_vdir(true)
	else:
		if lo(cur_y()) >= 208:
			if x < 243:
				move_object_right_by_var2()
			return
		if x < 219:
			move_object_right_by_var2()
			return
		_set_vdir(false)
	wram1[W_SHOOT_CAN_TURN_AROUND] = 1


## .Func_56d1c ($2d): no actions, not grabbable; once GK Tortoise throws it (wShootBallState 4)
## kicked left ($35, Frameset_69fa4; 1 px a frame at Wario's third goal, otherwise 3).
func _shoot_ball_wait() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	if wram1[W_SHOOT_BALL_STATE] != 4:
		return
	set_object_frameset_ptr(FRAMESET_69FA4)
	set_cur(OBJ_STATE, 0x35)
	_set_vdir(false)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 1 if wram1[W_WARIO_GOALS] == NUM_WARIO_GOALS_NEEDED else 3)


## .set_defeated: 28 frames rising (Frameset_69f8a, .DefeatRise), OBJ_STATE $48, the substate's low
## bits and OBJSUBFLAG_UNK_4 cleared, OBJ_VAR_3 cleared, in front, its object-map nibble 9
## (Func_ba42; SFX_0A9 not simulated).
func _shoot_set_defeated() -> void:
	set_object_frameset_ptr(FRAMESET_69F8A)
	set_cur(OBJ_STATE_DURATION, SHOOT_DEFEAT_RISE_DURATION)
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_DEFEAT_RISE & 0xFFFF)
	set_cur(OBJ_STATE, 0x48)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & (OBJSUBFLAG_UNINITIALISED | OBJSUBFLAG_VDIR | OBJSUBFLAG_HDIR))
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_cur_object_map_nibble(0x09)


## .DefeatRise: no actions, along Data_60e90 for its frames; then 70 frames still (Frameset_69f6f).
func shoot_defeat_rise() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		apply_obj_y_movement(DATA_60E90)
		return
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_69F6F)
	set_cur(OBJ_STATE_DURATION, SHOOT_DEFEAT_SUSPENDED_DURATION)
	set_cur_word(OBJ_UPDATE_FUNCTION, SHOOT_DEFEAT_SUSPEND_AND_FALL & 0xFFFF)


## .DefeatSuspendAndFall: no actions; still for its frames (SFX_0A3 at the end not simulated), then
## falling along Data_60ea0.
func shoot_defeat_suspend_and_fall() -> void:
	_no_actions()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	apply_obj_y_movement(DATA_60EA0)


# --- GK Tortoise and its platform (objects/shoot.asm) ---------------------------------------------

## GKTortoisePlatformFunc: visible, kept (OBJSUBFLAG_UNK_4), a box -6..5, Frameset_69fdc, moving left
## 32 frames after a 60-frame wait (OBJ_VAR_1), 64 px right and 16 down.
func gk_tortoise_platform_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, GK_TORTOISE_PLATFORM_MOVE_LEFT & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_collbox_x(-6, 5)
	set_object_frameset_ptr(FRAMESET_69FDC)
	set_cur(OBJ_STATE_DURATION, 32)
	set_cur(OBJ_VAR_1, 60)
	set_cur(OBJ_VAR_2, 64)
	move_object_right_by_var2()
	set_cur(OBJ_VAR_2, 16)
	set_cur_word(OBJ_Y_POS, cur_y() + 16)  # MoveObjectDownByVar2


## .MoveLeft: a one-way platform: a pixel left a frame (no actions) for its frames; then after
## OBJ_VAR_1 frames up and down (176 frames).
func gk_tortoise_platform_move_left() -> void:
	set_one_way_platform_action()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		_no_actions()
		move_object_left()
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 176)
	set_cur_word(OBJ_UPDATE_FUNCTION, GK_TORTOISE_PLATFORM_MOVE_UP_AND_DOWN & 0xFFFF)


## .MoveUpAndDown: a one-way platform a pixel a frame, carrying a Wario standing on it: up while
## OBJ_VAR_1 is clear (to OBJ_STATE_DURATION 0), then down to 176 (its state cleared there).
func gk_tortoise_platform_move_up_and_down() -> void:
	set_one_way_platform_action()
	var stepped: bool = (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0
	if cur(OBJ_VAR_1) == 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur(OBJ_VAR_1, 1)
			return
		if stepped:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
			move_wario_up(1)
			handle_upwards_floor_transition()
		move_object_up()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) + 1)
	if cur(OBJ_STATE_DURATION) == 176:
		set_cur(OBJ_VAR_1, 0)
		set_cur(OBJ_STATE, 0)
		return
	if stepped:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		move_wario_down(1)
		handle_downwards_floor_transition()
	move_object_down()


## GKTortoiseFunc: visible, kept, a box -6..5, Frameset_69fed, phase 0, 64 px right and 16 down.
func gk_tortoise_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, GK_TORTOISE_MAIN & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_collbox_x(-6, 5)
	set_object_frameset_ptr(FRAMESET_69FED)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 64)
	move_object_right_by_var2()
	set_cur(OBJ_VAR_2, 16)
	set_cur_word(OBJ_Y_POS, cur_y() + 16)  # MoveObjectDownByVar2


## .Main: no actions while Wario is transformed; a kicked ball (SHOOTBALL_WARIO_KICKED) makes it duck
## (Frameset_6a017, box top -10); otherwise by its phase (OBJ_VAR_1).
func gk_tortoise_main() -> void:
	if wTransformation != 0:
		_no_actions()
	if wram1[W_SHOOT_BALL_STATE] == SHOOTBALL_WARIO_KICKED and cur(OBJ_VAR_1) != GKTORTOISEPHASE_DUCKING:
		set_object_frameset_ptr(FRAMESET_6A017)
		set_cur(OBJ_VAR_1, GKTORTOISEPHASE_DUCKING)
		set_cur(OBJ_COLLBOX_TOP, -10)
		return
	match cur(OBJ_VAR_1):
		0:
			if wram1[W_SHOOT_BALL_STATE] != 0:
				_gk_stand()
			else:
				_gk_guard()
		1:
			_gk_guard()
		2:
			_gk_hit()
		3:
			_gk_recover()
		4:
			_gk_throw_shoot()
		5:
			_gk_throw_wario()
		6:
			_gk_throw_wario_back()
		GKTORTOISEPHASE_DUCKING:
			_gk_ducking()
		8:
			_gk_defeated()
		9:
			_gk_catch_shoot()
		_:
			note_unported("GKTortoiseFunc phase %02x" % cur(OBJ_VAR_1))


## .asm_57009: standing guard (Frameset_69fa9, phase 1, its state cleared, a box top -20, colliding).
func _gk_stand() -> void:
	set_object_frameset_ptr(FRAMESET_69FA9)
	set_cur(OBJ_VAR_1, 1)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_COLLBOX_TOP, -20)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


## .Func_56f2e (phase 1): Wario's goal (wShootBallState 2) and it throws the ball back (phase 4,
## Frameset_69fba, wShootBallState 3). Otherwise its actions cleared, and by its state: none, nothing;
## OBJSTATE_SPECIAL_3, Wario's ball caught (phase 5, Frameset_69ff2; SFX_FAT_WALK not simulated) and
## Wario set 16 px above it and 11 left; $08 or $09, Shoot's ball caught (phase 9, Frameset_69ff2,
## wShootBallState 3, Shoot without actions for 8 frames) and set there; anything else knocks it
## down (.asm_56f7d).
func _gk_guard() -> void:
	if wram1[W_SHOOT_BALL_STATE] == 2:
		wram1[W_SHOOT_BALL_STATE] = 3
		set_object_frameset_ptr(FRAMESET_69FBA)
		set_cur(OBJ_VAR_1, 4)
		return
	set_cur(OBJ_ACTION, 0)
	var state: int = cur(OBJ_STATE)
	if state == 0:
		return
	if state == OBJSTATE_SPECIAL_3:
		set_cur(OBJ_STATE, 0)
		set_object_frameset_ptr(FRAMESET_69FF2)
		set_cur(OBJ_VAR_1, 5)
		_gk_set_wario_pos(-16, -11)
		return
	if (state & 0xFE) != 0x08:
		_gk_knocked()
		return
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_69FF2)
	set_cur(OBJ_VAR_1, 9)
	wram1[W_SHOOT_BALL_STATE] = 3
	var shoot: int = _active_slot_with_id(SHOOT)
	if shoot >= 0:
		wram1[shoot + OBJ_ACTION] = (1 << NO_ACTIONS_F) | 8  # .Func_57170
	_gk_set_shoot_pos(-16, -11)


## .asm_56f7d: knocked down (its state cleared, Frameset_69fcf, phase 2, a box top -10, no collision).
func _gk_knocked() -> void:
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_69FCF)
	set_cur(OBJ_VAR_1, 2)
	set_cur(OBJ_COLLBOX_TOP, -10)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .Func_56fef (phase 2): unless Wario has scored (wShootBallState 2), a state ($02 or more) knocks it
## down again; at the end of its frameset's sixth frame (offset $0c) it stands guard.
func _gk_hit() -> void:
	if wram1[W_SHOOT_BALL_STATE] != 2 and (cur(OBJ_STATE) & 0xFE) != 0:
		_gk_knocked()
		return
	if cur(OBJ_FRAMESET_OFFSET) == 0x0C and cur(OBJ_FRAME_DURATION) == 0:
		_gk_stand()


## .Func_57021 (phase 3): colliding; a state knocks it down; at the end of offset 6 it stands guard.
func _gk_recover() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	if (cur(OBJ_STATE) & 0xFE) != 0:
		_gk_knocked()
		return
	if cur(OBJ_FRAMESET_OFFSET) == 6 and cur(OBJ_FRAME_DURATION) == 0:
		_gk_stand()


## .Func_57039 (phase 5), at the end of a frame by its offset: Wario 22 px above it (2), 16 above and
## 11 left (4); at 6 he is let go (wAutoMoveState 0; it without actions 15 frames; SFX_067 not
## simulated); at 10 it stands guard.
func _gk_throw_wario() -> void:
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	match cur(OBJ_FRAMESET_OFFSET):
		2:
			_gk_set_wario_pos(-22, 0)
		4:
			_gk_set_wario_pos(-16, -11)
		6:
			wAutoMoveState = 0
			set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 15)
		10:
			_gk_stand()


## .Func_5707b (phase 4): no collision; at the end of a frame by its offset: Shoot 12 px right of it
## (6; SFX_FAT_WALK not simulated), 22 px above (8), 16 above and 11 left ($0e); at $10 Shoot's ball
## thrown (wShootBallState 4; SFX_067 not simulated); at $14 standing guard, or at Wario's third
## goal defeated (180 frames of Frameset_6a00e, phase 8, a box top -10).
func _gk_throw_shoot() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	match cur(OBJ_FRAMESET_OFFSET):
		0x06:
			_gk_set_shoot_pos(0, 12)
		0x08:
			_gk_set_shoot_pos(-22, 0)
		0x0E:
			_gk_set_shoot_pos(-16, -11)
		0x10:
			wram1[W_SHOOT_BALL_STATE] = 4
		0x14:
			if wram1[W_WARIO_GOALS] != NUM_WARIO_GOALS_NEEDED:
				_gk_stand()
				return
			set_object_frameset_ptr(FRAMESET_6A00E)
			set_cur(OBJ_STATE_DURATION, 180)
			set_cur(OBJ_VAR_1, 8)
			set_cur(OBJ_COLLBOX_TOP, -10)


## .Func_5710f (phase 9), at the end of a frame by its offset: Shoot 22 px above it (2), 16 above
## and 11 left (4); at 6 Shoot's ball thrown (wShootBallState 4; SFX_067 not simulated); at 10
## standing guard.
func _gk_catch_shoot() -> void:
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	match cur(OBJ_FRAMESET_OFFSET):
		2:
			_gk_set_shoot_pos(-22, 0)
		4:
			_gk_set_shoot_pos(-16, -11)
		6:
			wram1[W_SHOOT_BALL_STATE] = 4
		10:
			_gk_stand()


## .Func_57198 (phase 6), at the end of a frame by its offset: Wario 12 px right of it (6), 22 px
## above (8), 16 above and 11 left ($0e); at $10 let go (wShootBallState 1, wAutoMoveState 0;
## SFX_067 not simulated); at $14 standing guard.
func _gk_throw_wario_back() -> void:
	if cur(OBJ_FRAME_DURATION) != 0:
		return
	match cur(OBJ_FRAMESET_OFFSET):
		0x06:
			_gk_set_wario_pos(0, 12)
		0x08:
			_gk_set_wario_pos(-22, 0)
		0x0E:
			_gk_set_wario_pos(-16, -11)
		0x10:
			wram1[W_SHOOT_BALL_STATE] = 1
			wAutoMoveState = 0
		0x14:
			_gk_stand()


## .Ducking: from offset 6 its frames held at 16 until the ball is in the net (SHOOTBALL_WARIO_GOAL);
## at the end of offset 10 it throws Wario back (.asm_56fd2: wShootBallState 7, Frameset_69fba, phase
## 6, a box top -20; SFX_FAT_WALK not simulated).
func _gk_ducking() -> void:
	var offset: int = cur(OBJ_FRAMESET_OFFSET)
	if offset == 10:
		if cur(OBJ_FRAME_DURATION) != 0:
			return
		wram1[W_SHOOT_BALL_STATE] = 7
		set_object_frameset_ptr(FRAMESET_69FBA)
		set_cur(OBJ_VAR_1, 6)
		set_cur(OBJ_COLLBOX_TOP, -20)
		return
	if offset < 6 or wram1[W_SHOOT_BALL_STATE] == SHOOTBALL_WARIO_GOAL:
		return
	set_cur(OBJ_FRAME_DURATION, 16)


## .Func_56edd (phase 8): no actions; after its frames gone (its object-map nibble 8, Func_ba42) and
## the battle won (wBossState BOSS_DEFEATED, wIsBossBattle off; the music not simulated).
func _gk_defeated() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, 0)
	set_cur_object_map_nibble(0x08)
	wBossState = BOSS_DEFEATED
	wIsBossBattle = 0


## Wario's y and x set from its own plus `dy` and `dx` (16-bit).
func _gk_set_wario_pos(dy: int, dx: int) -> void:
	wWarioYPos = word(cur_y() + dy)
	wWarioXPos = word(cur_x() + dx)


## .GetShootPosPtr: Shoot's y and x (the first active Shoot's slot) set from its own plus `dy` and
## `dx` (16-bit). With no Shoot the four bytes go where the search stopped in the last slot: from
## OBJ_ID, or past OBJ_FLAGS when that slot is an inactive Shoot.
func _gk_set_shoot_pos(dy: int, dx: int) -> void:
	var base: int = _active_slot_with_id(SHOOT)
	var at: int = base + OBJ_Y_POS
	if base < 0:
		var last: int = W_OBJECTS + (NUM_OBJECTS - 1) * OBJ_STRUCT_LENGTH
		at = last + (OBJ_FLAGS + 1 if wram1[last + OBJ_ID] == SHOOT else OBJ_ID)
	var y: int = word(cur_y() + dy)
	var x: int = word(cur_x() + dx)
	wram1[at] = lo(y)
	wram1[at + 1] = hi(y)
	wram1[at + 2] = lo(x)
	wram1[at + 3] = hi(x)
