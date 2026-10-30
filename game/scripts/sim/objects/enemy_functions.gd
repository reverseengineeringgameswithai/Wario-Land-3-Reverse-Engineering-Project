class_name EnemyFunctions
extends ObjectFunctions
## The standard enemies after Silky, by translation from src/engine/level/objects/*.asm, most
## frequent on the coverage sweep first: Para-Goom, Brrr Bear (and its snowflakes), Haridama, the
## hand, Spear Bot and Fire Bot, Hammer Bot, Hebarii, the owl, the tadpoles, Teruteru, the zombie,
## the Doughnuteer, Pneumo, Omodonmeka (and the one carrying an Omodon). The standard ones share the standard enemies' state table
## layout (`common_enemy_state`) and differ in their own entries. Paths into code not ported are
## named in `unported`.
## Research note: docs/02-research/objects.md.

const OBJ_INTERACTION_TOP_STING: int = 0x04
const COLLBOX_TOP_TALL: int = 0xEF  # -17: Para-Goom with OBJ_INTERACTION_TOP_STING
const COLLBOX_TOP_SHORT: int = 0xF4  # -12, its object data's

const PARA_GOOM_FUNC: int = 0x10_5357  # ParaGoomFunc
const PARA_GOOM_FUNC_INIT: int = 0x10_5361
const PARA_GOOM_FUNC_UPDATE: int = 0x10_5375
# ParaGoomFunc's rDIV reads, by the instruction after each.
const DIV_PARA_GOOM_WAIT: int = 0x10_5520  # .Func_41517
const DIV_PARA_GOOM_WAIT_TALL: int = 0x10_5538  # .Func_4152f
const DIV_PARA_GOOM_WALK: int = 0x10_55A1  # .Func_41598
const DIV_PARA_GOOM_LANDED: int = 0x10_5878  # .Func_4186f
const DIV_PARA_GOOM_TURN: int = 0x10_58CD  # .Func_418c4
const DATA_60530: int = 0x4530  # bank $18: getting up's rise
const FRAMESET_68439: int = 0x4439
const FRAMESET_68442: int = 0x4442
const FRAMESET_6844B: int = 0x444B
const FRAMESET_68454: int = 0x4454
const FRAMESET_6845D: int = 0x445D
const FRAMESET_6846E: int = 0x446E
const FRAMESET_6847F: int = 0x447F
const FRAMESET_68490: int = 0x4490
const FRAMESET_684AA: int = 0x44AA
const FRAMESET_684AF: int = 0x44AF
const FRAMESET_684A1: int = 0x44A1  # Para-Goom's full throw
const FRAMESET_684B4: int = 0x44B4
const FRAMESET_684B7: int = 0x44B7
const FRAMESET_684BA: int = 0x44BA
const FRAMESET_684CB: int = 0x44CB
const FRAMESET_684D2: int = 0x44D2
const FRAMESET_684D9: int = 0x44D9
const FRAMESET_684E0: int = 0x44E0
const FRAMESET_684E7: int = 0x44E7
const FRAMESET_6850A: int = 0x450A
const FRAMESET_6852D: int = 0x452D
const FRAMESET_68546: int = 0x4546
const FRAMESET_6855F: int = 0x455F

const BRRR_BEAR_FUNC: int = 0x12_4000  # BrrrBearFunc
const BRRR_BEAR_FUNC_INIT: int = 0x12_400A
const BRRR_BEAR_FUNC_UPDATE: int = 0x12_4029
# BrrrBearFunc's rDIV reads, by the instruction after each.
const DIV_BRRR_BEAR_BLOW: int = 0x12_4178  # .Func_4816f
const DIV_BRRR_BEAR_WALK: int = 0x12_41D3  # .Func_481ca
const DIV_BRRR_BEAR_TURN: int = 0x12_43CE  # .Func_483c5
const OBJ_PARAMS_SNOWFLAKE_LEFT: int = 0x49EC  # bank $19
const OBJ_PARAMS_SNOWFLAKE_RIGHT: int = 0x4A01
const SNOWFLAKE_FUNC_LEFT: int = 0x12_4508  # SnowflakeFunc_Left
const SNOWFLAKE_FUNC_RIGHT: int = 0x12_450D
const SNOWFLAKE_FUNC_UPDATE: int = 0x12_452C
const FRAMESET_69115: int = 0x5115
const FRAMESET_69126: int = 0x5126
const FRAMESET_69137: int = 0x5137
const FRAMESET_6913A: int = 0x513A
const FRAMESET_6913D: int = 0x513D
const FRAMESET_6914C: int = 0x514C
const FRAMESET_6915B: int = 0x515B
const FRAMESET_69164: int = 0x5164
const FRAMESET_6916E: int = 0x516E
const FRAMESET_69175: int = 0x5175
const FRAMESET_6917C: int = 0x517C
const FRAMESET_69183: int = 0x5183
const FRAMESET_6918E: int = 0x518E
const HARIDAMA_FUNC: int = 0x12_4EE2  # HaridamaFunc
const HARIDAMA_FUNC_INIT: int = 0x12_4EEC
const HARIDAMA_FUNC_UPDATE: int = 0x12_4FCF
const HARIDAMA_FUNC_OUT: int = 0x12_50E8  # .Func_490e8
const OBJ_INTERACTION_06: int = 0x06
const OBJ_INTERACTION_HARIDAMA: int = 0x2A
const FRAMESET_6927F: int = 0x527F
const FRAMESET_69290: int = 0x5290
const FRAMESET_692A1: int = 0x52A1
const FRAMESET_692AA: int = 0x52AA
const FRAMESET_692B3: int = 0x52B3
const FRAMESET_692B8: int = 0x52B8
const FRAMESET_692BD: int = 0x52BD
const FRAMESET_692C2: int = 0x52C2
const FRAMESET_692C7: int = 0x52C7
const FRAMESET_692CE: int = 0x52CE
const FRAMESET_692D5: int = 0x52D5
const FRAMESET_692DE: int = 0x52DE
const HAND_FUNC: int = 0x11_774F  # HandFunc
const HAND_FUNC_UPDATE: int = 0x11_7773
const OBJSTATE_HAND_HOLDING: int = 0x2E  # set from $2f, which OBJACTION_13 (ObjInteraction_Hand) leaves
## The hand's rising and sinking framesets (bank $1a), by step: Frameset_690ab, then each 3 bytes on.
const HAND_FRAMESETS: Array = [0x50AB, 0x50B4, 0x50B7, 0x50BA, 0x50BD, 0x50C0, 0x50C3, 0x50C6, 0x50C9,
		0x50DC, 0x50DF, 0x50E2, 0x50E5, 0x50E8, 0x50EB]
## Wario's offset above the hand while it holds him, after each sinking step (ApplyOffsetToWario).
const HAND_HOLD_OFFSETS: Dictionary = {10: 8, 11: 6, 12: 8, 13: 0}
const GREY_PRINCE_FROGGY_FUNC: int = 0x11_4080  # GreyPrinceFroggyFunc
const RED_PRINCE_FROGGY_FUNC: int = 0x11_40A1  # RedPrinceFroggyFunc
const PRINCE_FROGGY_STUCK: int = 0x11_40F4  # PrinceFroggyFunc.Update_Stuck
const PRINCE_FROGGY_SITTING: int = 0x11_41A5  # .Update_Sitting
const PRINCE_FROGGY_LEAVING: int = 0x11_4220  # .Func_44220
const OBJ_INTERACTION_PRINCE_FROGGY: int = 0x3E
const TOGEBA_FUNC: int = 0x12_4D8A  # TogebaFunc
const TOGEBA_WAIT: int = 0x12_4DB7  # .Func_48db7
const TOGEBA_SHAKEN: int = 0x12_4E02  # .Func_48e02
const TOGEBA_LANDED: int = 0x12_4E3E  # .Func_48e3e
const TOGEBA_PLATFORM: int = 0x12_4E46  # .Func_48e46
const TOGEBA_RISING: int = 0x12_4ECC  # .Func_48ecc
const DATA_60760: int = 0x4760  # Togeba shaken off its ceiling (bank $18)
const KUSHIMUSHI_VERTICAL_FUNC: int = 0x10_69C4  # KushimushiVerticalFunc
const KUSHIMUSHI_VERTICAL_UPDATE: int = 0x10_69ED
const KUSHIMUSHI_HORIZONTAL_UPDATE: int = 0x10_6ACF  # KushimushiVerticalFunc.Func_42acf
const KUSHIMUSHI_HORIZONTAL_FUNC: int = 0x10_6B7D  # KushimushiHorizontalFunc
## Kushimushi's patrol, by OBJ_VAR_1: [frameset, interaction, wait] on finishing each phase
## (vertical: down, turn, up, turn; horizontal: right, turn left, left, turn right).
const KUSHIMUSHI_VERTICAL_PHASES: Array = [[0x463F, 0x01, 22], [0x4616, 0x04, 96], [0x4634, 0x01, 22],
		[0x461B, 0x4C, 96]]
const KUSHIMUSHI_HORIZONTAL_PHASES: Array = [[0x4655, 0x01, 22], [0x460C, 0x02, 96], [0x464A, 0x01, 22],
		[0x4611, 0x02, 96]]
const BEAM_BOT_FUNC: int = 0x11_65B5  # BeamBotFunc
const BEAM_BOT_FUNC_INIT: int = 0x11_65BF
const BEAM_BOT_FUNC_UPDATE: int = 0x11_65D3
const BEAM_FUNC_LEFT: int = 0x11_6B00  # BeamFunc_Left
const BEAM_FUNC_LEFT_UPDATE: int = 0x11_6B15
const BEAM_FUNC_RIGHT: int = 0x11_6B2A  # BeamFunc_Right
const BEAM_FUNC_RIGHT_UPDATE: int = 0x11_6B3F
const OBJ_PARAMS_BEAM_LEFT: int = 0x491A  # bank $19
const OBJ_PARAMS_BEAM_RIGHT: int = 0x492F
const DATA_60610: int = 0x4610  # a beam's flight left (bank $18)
const DATA_60630: int = 0x4630  # right
## Beam Bot's rDIV reads (the ground shake): .Func_466e7, .Func_4672c, .Func_46769, .Func_469b2.
const DIV_BEAM_BOT: Array = [0x11_66F0, 0x11_6735, 0x11_6772, 0x11_69BB]
## Beam Bot's framesets, [HDIR clear, HDIR set].
const BEAM_BOT_FRAMESETS: Dictionary = {
	"walk": [0x4E77, 0x4E80], "wind_up": [0x4E89, 0x4E96], "fire": [0x4EA3, 0x4EAA],
	"bump": [0x4EB1, 0x4EB4], "hit": [0x4EB7, 0x4EC0], "knocked": [0x4EC9, 0x4ECE], "turn": [0x4ED3, 0x4EDA],
}
const FRAMESET_68EF3: int = 0x4EF3  # the beam left, full length
const FRAMESET_68EF8: int = 0x4EF8  # right
const SPEAR_BOT_FUNC: int = 0x11_5EE3  # SpearBotFunc
const SPEAR_BOT_FUNC_INIT: int = 0x11_5EED
const SPEAR_BOT_FUNC_UPDATE: int = 0x11_5F01
const FIRE_BOT_FUNC: int = 0x11_6B66  # FireBotFunc
const FIRE_BOT_FUNC_INIT: int = 0x11_6B70
const FIRE_BOT_FUNC_UPDATE: int = 0x11_6B84
const OBJ_INTERACTION_FIRE_BOT: int = 0x21
## Spear Bot's and Fire Bot's parameters: their framesets by role (left, right; bank $1a), their
## wind-up and stop, the thrust's interaction, and their rDIV reads by the instruction after each
## (wind-up, thrust, stop, turning back, walk, turn).
const SPEAR_BOT: Dictionary = {
	"name": "SpearBotFunc", "init": SPEAR_BOT_FUNC_INIT & 0xFFFF, "update": SPEAR_BOT_FUNC_UPDATE & 0xFFFF,
	"wind_up": 20, "stop": 38, "thrust_interaction": OBJ_INTERACTION_FRONT_STING, "ignores_hot_wario": false,
	"div": [0x11_6068, 0x11_60AF, 0x11_6179, 0x11_6195, 0x11_6204, 0x11_642A],
	"framesets": {"walk": [0x4DDF, 0x4DE8], "wind_up": [0x4DF1, 0x4DF8], "stop": [0x4DFF, 0x4E08],
		"bump": [0x4E11, 0x4E14], "hit": [0x4E17, 0x4E20], "knocked": [0x4E29, 0x4E2E], "turn": [0x4E33, 0x4E3A],
		"turn_back": [0x4E41, 0x4E4C], "thrust": [0x4E57, 0x4E60], "retract": [0x4E69, 0x4E70]},
}
const FIRE_BOT: Dictionary = {
	"name": "FireBotFunc", "init": FIRE_BOT_FUNC_INIT & 0xFFFF, "update": FIRE_BOT_FUNC_UPDATE & 0xFFFF,
	"wind_up": 23, "stop": 61, "thrust_interaction": OBJ_INTERACTION_FIRE_BOT, "ignores_hot_wario": true,
	"div": [0x11_6CED, 0x11_6D41, 0x11_6E0B, 0x11_6E27, 0x11_6E96, 0x11_70C3],
	"framesets": {"walk": [0x493D, 0x4946], "wind_up": [0x494F, 0x495C], "stop": [0x4969, 0x4976],
		"bump": [0x4983, 0x4986], "hit": [0x4989, 0x4992], "knocked": [0x499B, 0x49A0], "turn": [0x49A5, 0x49AC],
		"turn_back": [0x49B3, 0x49BE], "thrust": [0x49C9, 0x49D2], "retract": [0x49DB, 0x49E2]},
}
const HAMMER_BOT_FUNC: int = 0x11_423B  # HammerBotFunc
const HAMMER_BOT_FUNC_INIT: int = 0x11_4245
const HAMMER_BOT_FUNC_UPDATE: int = 0x11_4259
const OBJ_INTERACTION_BOUNCY: int = 0x20
const OBJ_PARAMS_STARS_LEFT: int = 0x48F0  # bank $19
const OBJ_PARAMS_STARS_RIGHT: int = 0x4905
const FRAMESET_68B12: int = 0x4B12
const FRAMESET_68B17: int = 0x4B17
const FRAMESET_68B1C: int = 0x4B1C
const FRAMESET_68B25: int = 0x4B25
const FRAMESET_68B2E: int = 0x4B2E
const FRAMESET_68B37: int = 0x4B37
const FRAMESET_68B40: int = 0x4B40
const FRAMESET_68B45: int = 0x4B45
const FRAMESET_68B4A: int = 0x4B4A
const FRAMESET_68B51: int = 0x4B51
const FRAMESET_68B58: int = 0x4B58
const FRAMESET_68B5B: int = 0x4B5B
const FRAMESET_68B5E: int = 0x4B5E
const FRAMESET_68B61: int = 0x4B61
const HEBARII_FUNC: int = 0x12_5FC4  # HebariiFunc
const HEBARII_FUNC_INIT: int = 0x12_5FCE
const HEBARII_FUNC_ATTACHED: int = 0x12_6037  # .AttachedUpdate
const HEBARII_FUNC_DETACHED: int = 0x12_611B  # .DetachedUpdate
const HEBARII_PROJECTILE_FUNC: int = 0x12_63C2  # HebariiProjectileFunc
const HEBARII_PROJECTILE_FUNC_LATERAL: int = 0x12_6401  # .MoveWithLateral
const HEBARII_PROJECTILE_FUNC_DOWN: int = 0x12_640F  # .MoveWithoutLateral
const HEBARII_PROJECTILE_FUNC_DESTROY: int = 0x12_644E  # .Destroy
const DIV_HEBARII_WAIT: int = 0x12_622D  # HebariiFunc's rDIV read (.Func_4a224)
const OBJ_PARAMS_HEBARII_PROJECTILE: int = 0x478B  # bank $19
const FRAMESET_683E4: int = 0x43E4
const FRAMESET_683ED: int = 0x43ED
const FRAMESET_683F8: int = 0x43F8
const FRAMESET_683FB: int = 0x43FB
const FRAMESET_6840D: int = 0x440D
const FRAMESET_68418: int = 0x4418
const FRAMESET_68421: int = 0x4421
const FRAMESET_6842A: int = 0x442A
const FRAMESET_6842D: int = 0x442D
const FRAMESET_68430: int = 0x4430
const OWL_FUNC: int = 0x12_51D3  # OwlFunc
const OWL_FUNC_SLEEP: int = 0x12_520F
const OWL_FUNC_WAKE_UP: int = 0x12_5239
const OWL_FUNC_FLY_UPWARDS: int = 0x12_5265
const OWL_FUNC_FLY: int = 0x12_52B4  # .Func_492b4
const OBJ_INTERACTION_0B: int = 0x0B
const OBJ_INTERACTION_OWL: int = 0x28
const FRAMESET_692E7: int = 0x52E7
const FRAMESET_69318: int = 0x5318
const FRAMESET_69335: int = 0x5335
const FRAMESET_6936C: int = 0x536C
const FRAMESET_69377: int = 0x5377
const TADPOLE_SPAWNER_FUNC: int = 0x12_5E34  # TadpoleSpawnerFunc
const TADPOLE_SPAWNER_FUNC_WAIT: int = 0x12_5E4B  # .Func_49e4b
const TADPOLE_SPAWNER_FUNC_SPENT: int = 0x12_5E7F  # .Func_49e7f
const TADPOLE_FUNC: int = 0x12_5EA0  # TadpoleFunc
const TADPOLE_FUNC_HIDDEN: int = 0x12_5EB3  # .Func_49eb3
const TADPOLE_FUNC_READY: int = 0x12_5ECE  # .Func_49ece
const TADPOLE_FUNC_LEAP: int = 0x12_5F34  # .Func_49f34
const TADPOLE_FUNC_SPLASH: int = 0x12_5FB5  # .Func_49fb5
const OBJ_PARAMS_TADPOLE: int = 0x4CB6  # bank $19
const DATA_60A20: int = 0x4A20  # bank $18: the leap's rise
const DATA_60A40: int = 0x4A40  # and its fall
const FRAMESET_69A1A: int = 0x5A1A
const FRAMESET_69A1D: int = 0x5A1D
const FRAMESET_69A26: int = 0x5A26
const FRAMESET_69A30: int = 0x5A30
const FRAMESET_69A33: int = 0x5A33
const FRAMESET_69A3D: int = 0x5A3D
const TERUTERU_FUNC: int = 0x11_48D7  # TeruteruFunc
const TERUTERU_FUNC_INIT: int = 0x11_48E1
const TERUTERU_FUNC_UPDATE: int = 0x11_4903
const OBJ_INTERACTION_TERUTERU: int = 0x38
const DATA_604C0: int = 0x44C0  # bank $18: its bob
const FRAMESET_68B64: int = 0x4B64
const FRAMESET_68B6D: int = 0x4B6D
const FRAMESET_68B76: int = 0x4B76
const FRAMESET_68B7D: int = 0x4B7D
const FRAMESET_68B84: int = 0x4B84
const FRAMESET_68B8B: int = 0x4B8B
const FRAMESET_68B90: int = 0x4B90
const FRAMESET_68B99: int = 0x4B99
const FRAMESET_68BA2: int = 0x4BA2
const FRAMESET_68BA5: int = 0x4BA5
const FRAMESET_68BAE: int = 0x4BAE
const ZOMBIE_FUNC: int = 0x11_5AB4  # ZombieFunc
const ZOMBIE_FUNC_INIT: int = 0x11_5AD3
const ZOMBIE_FUNC_UNDERGROUND: int = 0x11_5B03
const ZOMBIE_FUNC_START_RISE: int = 0x11_5BDB
const ZOMBIE_FUNC_RISING: int = 0x11_5C23
const ZOMBIE_FUNC_ON_SURFACE: int = 0x11_5C5D
const ZOMBIE_FUNC_HEADLESS: int = 0x11_5E25
const ZOMBIE_HEAD_FUNC_LEFT: int = 0x11_5E54  # ZombieHeadFunc_Left
const ZOMBIE_HEAD_FUNC_RIGHT: int = 0x11_5E78
const ZOMBIE_HEAD_FUNC_FLICKER: int = 0x11_5EC8  # ZombieHeadFunc.Flicker
const OBJ_PARAMS_ZOMBIE_HEAD_LEFT: int = 0x48C6  # bank $19
const OBJ_PARAMS_ZOMBIE_HEAD_RIGHT: int = 0x48DB
const DATA_60560: int = 0x4560  # bank $18: the head's flight right
const DATA_605A0: int = 0x45A0  # and left
const FRAMESET_68D1A: int = 0x4D1A
const FRAMESET_68D1F: int = 0x4D1F
const FRAMESET_68D24: int = 0x4D24
const FRAMESET_68D2B: int = 0x4D2B
const FRAMESET_68D81: int = 0x4D81
const FRAMESET_68D8A: int = 0x4D8A
const FRAMESET_68D93: int = 0x4D93
const FRAMESET_68D9C: int = 0x4D9C
const FRAMESET_68DA5: int = 0x4DA5
const FRAMESET_68DAC: int = 0x4DAC
const FRAMESET_68DD5: int = 0x4DD5
const FRAMESET_68DDA: int = 0x4DDA
const DOUGHNUTEER_FUNC: int = 0x10_5A7C  # DoughnuteerFunc
const DOUGHNUTEER_FUNC_INIT: int = 0x10_5A86
const DOUGHNUTEER_FUNC_UPDATE: int = 0x10_5A9A
const DOUGHNUT_FUNC_LEFT: int = 0x10_60F8  # DoughnutFunc_Left
const DOUGHNUT_FUNC_RIGHT: int = 0x10_60FD
const DOUGHNUT_FUNC_UP: int = 0x10_6115
const DOUGHNUT_FUNC_UP_UPDATE: int = 0x10_6126
const DOUGHNUT_FUNC_UPDATE_LEFT: int = 0x10_615D  # DoughnutFunc.Update_Left
const DOUGHNUT_FUNC_UPDATE_RIGHT: int = 0x10_6162
const OBJ_PARAMS_DOUGHNUT_LEFT: int = 0x481E  # bank $19
const OBJ_PARAMS_DOUGHNUT_RIGHT: int = 0x4833
const OBJ_PARAMS_DOUGHNUT_UP_LEFT: int = 0x4848
const OBJ_PARAMS_DOUGHNUT_UP_RIGHT: int = 0x485D
const DATA_60510: int = 0x4510  # bank $18: a thrown doughnut's arc
const DATA_60540: int = 0x4540  # a doughnut tossed up
const FRAMESET_68562: int = 0x4562
const FRAMESET_6856B: int = 0x456B
const FRAMESET_68574: int = 0x4574
const FRAMESET_6857D: int = 0x457D
const FRAMESET_68586: int = 0x4586
const FRAMESET_68597: int = 0x4597
const FRAMESET_685A8: int = 0x45A8
const FRAMESET_685AD: int = 0x45AD
const FRAMESET_685B2: int = 0x45B2
const FRAMESET_685BB: int = 0x45BB
const FRAMESET_685C4: int = 0x45C4
const FRAMESET_685D7: int = 0x45D7
const FRAMESET_685F0: int = 0x45F0
const FRAMESET_685F7: int = 0x45F7
const FRAMESET_685FE: int = 0x45FE
const FRAMESET_68605: int = 0x4605
const PNEUMO_FUNC: int = 0x11_564A  # PneumoFunc
const PNEUMO_FUNC_UPDATE: int = 0x11_568B
const DATA_60600: int = 0x4600  # bank $18: Pneumo stunned
const H_X_POS_LO_BACKUP: int = 0xFFB0  # an HRAM address Pneumo adds to Wario's Y (.Func_45934)
const FRAMESET_68C5C: int = 0x4C5C
const FRAMESET_68C7F: int = 0x4C7F
const FRAMESET_68C84: int = 0x4C84
const FRAMESET_68C89: int = 0x4C89
const FRAMESET_68C8E: int = 0x4C8E
const OMODONMEKA_FUNC: int = 0x10_6170  # OmodonmekaFunc
const OMODONMEKA_FUNC_UPDATE: int = 0x10_6218  # .Func_42218
const OBJ_INTERACTION_OMODONMEKA: int = 0x18
const DATA_604E0: int = 0x44E0  # bank $18: Omodonmeka flying off, up
const DATA_60500: int = 0x4500  # dropping
const DATA_60650: int = 0x4650  # flying off, across (looped)
const FRAMESET_68F0B: int = 0x4F0B
const FRAMESET_68F14: int = 0x4F14
const FRAMESET_68F1D: int = 0x4F1D
const FRAMESET_68F2B: int = 0x4F2B
const FRAMESET_68F34: int = 0x4F34
const FRAMESET_68F3D: int = 0x4F3D
const OMODONMEKA_WITH_OMODON_1_FUNC: int = 0x10_6478  # OmodonmekaWithOmodon1Func
const OMODONMEKA_WITH_OMODON_2_FUNC: int = 0x10_64B1
const OMODONMEKA_WITH_OMODON_FUNC: int = 0x10_64EA
const OMODONMEKA_WITH_OMODON_FUNC_FLY_OFF: int = 0x10_6714  # .Func_42714
const OMODON_FUNC: int = 0x10_679C  # Func_4279c (the Omodon)
const OMODON_FUNC_UPDATE: int = 0x10_67A9  # .Func_427a9
const OBJ_PARAMS_OMODON_1: int = 0x4E1B  # bank $19
const OBJ_PARAMS_OMODON_2: int = 0x4E06
const OBJ_INTERACTION_SOLID: int = 0x22
const OBJ_INTERACTION_OMODON: int = 0x23
const DATA_605E0: int = 0x45E0  # bank $18: the Omodon falling
const FRAMESET_68F26: int = 0x4F26
const FRAMESET_68F42: int = 0x4F42
const FRAMESET_68F45: int = 0x4F45
const FRAMESET_68F50: int = 0x4F50
const GARLIC_OR_BETTER: int = 0x05  # wEffectivePowerUp from which an attack knocks Brrr Bear away
const COUNT_RICHTERTOFFEN_FUNC: int = 0x10_4E12  # CountRichtertoffenFunc
const COUNT_RICHTERTOFFEN_UPDATE: int = 0x10_4E31
const OBJ_INTERACTION_RICHTERTOFFEN: int = 0x0F
const FRAMESET_683BC: int = 0x43BC  # walking
const FRAMESET_683C1: int = 0x43C1  # jumping left
const FRAMESET_683C4: int = 0x43C4  # jumping right
const FRAMESET_683C7: int = 0x43C7  # falling
const FRAMESET_683CA: int = 0x43CA  # knocked
const FRAMESET_683D4: int = 0x43D4  # landing, flattened
const FRAMESET_683D9: int = 0x43D9  # stunned, held
const FRAMESET_683DE: int = 0x43DE
const FRAMESET_683E1: int = 0x43E1
const MAD_SCIENSTEIN_FUNC: int = 0x11_4D3C  # MadSciensteinFunc
const MAD_SCIENSTEIN_INIT: int = 0x11_4D46
const MAD_SCIENSTEIN_UPDATE: int = 0x11_4D5A
const OBJ_PARAMS_INVISIBILITY_POTION_LEFT: int = 0x4872  # bank $19, thrown
const OBJ_PARAMS_INVISIBILITY_POTION_RIGHT: int = 0x4887
const OBJ_PARAMS_INVISIBILITY_POTION_DROP_LEFT: int = 0x489C  # dropped when bumped
const OBJ_PARAMS_INVISIBILITY_POTION_DROP_RIGHT: int = 0x48B1
const FRAMESET_68BB5: int = 0x4BB5  # walking left
const FRAMESET_68BBE: int = 0x4BBE  # walking right
const FRAMESET_68BC7: int = 0x4BC7  # bumped
const FRAMESET_68BCC: int = 0x4BCC
const FRAMESET_68BD1: int = 0x4BD1  # hurrying
const FRAMESET_68BDA: int = 0x4BDA
const FRAMESET_68BE3: int = 0x4BE3  # stunned, wobbling, held
const FRAMESET_68BE8: int = 0x4BE8
const FRAMESET_68BED: int = 0x4BED  # throwing a potion
const FRAMESET_68BF6: int = 0x4BF6
const FRAMESET_68BFF: int = 0x4BFF  # stopping
const FRAMESET_68C08: int = 0x4C08
const FRAMESET_68C11: int = 0x4C11  # knocked
const FRAMESET_68C14: int = 0x4C14
const FRAMESET_68C17: int = 0x4C17  # turning
const FRAMESET_68C1E: int = 0x4C1E
const FRAMESET_68C25: int = 0x4C25  # turning to hurry back
const FRAMESET_68C2C: int = 0x4C2C
const SUN_FUNC: int = 0x11_724E  # SunFunc
const SUN_CHECK_DIRECTION: int = 0x11_7272  # .CheckDirection
const SUN_UPDATE: int = 0x11_72A6  # .Func_472a6
const SUN_FLAME_FUNC_LEFT: int = 0x11_7538  # SunFlameFunc_Left
const SUN_FLAME_FUNC_RIGHT: int = 0x11_753D
const SUN_FLAME_UPDATE: int = 0x11_7560  # SunFlameFunc.Update
const OBJ_PARAMS_SUN_FLAME_LEFT: int = 0x496E  # bank $19
const OBJ_PARAMS_SUN_FLAME_RIGHT: int = 0x4983
const MOON_FUNC: int = 0x11_756F  # MoonFunc
const MOON_CHECK_DIRECTION: int = 0x11_7593  # .CheckDirection
const MOON_UPDATE: int = 0x11_75C7  # .Func_475c7
const MOON_STAR_FUNC_LEFT: int = 0x11_76E1  # MoonStarFunc_Left
const MOON_STAR_FUNC_RIGHT: int = 0x11_76E6
const MOON_STAR_UPDATE: int = 0x11_7709  # MoonStarFunc.Update
const OBJ_PARAMS_MOON_STAR_LEFT: int = 0x4998  # bank $19
const OBJ_PARAMS_MOON_STAR_RIGHT: int = 0x49AD
const MIZUUO_FUNC: int = 0x12_4730  # MizuuoFunc
const MIZUUO_UPDATE_1: int = 0x12_4753  # .Update1
const MIZUUO_UPDATE_2: int = 0x12_47BF
const MIZUUO_UPDATE_3: int = 0x12_47E6
const MIZUUO_UPDATE_4: int = 0x12_482F
const MIZZOU_PROJECTILE_FUNC_LEFT: int = 0x12_4853  # MizzouProjectileFunc_Left
const MIZZOU_PROJECTILE_FUNC_RIGHT: int = 0x12_4858
const MIZZOU_PROJECTILE_UPDATE: int = 0x12_48CD  # MizzouProjectileFunc.Update
const OBJ_PARAMS_MIZZOU_PROJECTILE_LEFT: int = 0x4A16  # bank $19
const OBJ_PARAMS_MIZZOU_PROJECTILE_RIGHT: int = 0x4A2B
const DATA_60700: int = 0x4700  # the projectile's flight (bank $18)
const DATA_60740: int = 0x4740  # its drop
const FRAMESET_686A4: int = 0x46A4  # Mizuuo spitting, left
const FRAMESET_686B9: int = 0x46B9  # right
const FRAMESET_686D8: int = 0x46D8  # the projectile dropping, left
const FRAMESET_686DB: int = 0x46DB  # right
const FRAMESET_686DE: int = 0x46DE  # its burst
const FRAMESET_686E5: int = 0x46E5  # Mizuuo walking left
const FRAMESET_686EA: int = 0x46EA  # right
const FRAMESET_686EF: int = 0x46EF  # about to spit, left
const FRAMESET_686F8: int = 0x46F8  # right
const FRAMESET_68701: int = 0x4701  # after spitting, left
const FRAMESET_6870A: int = 0x470A  # right
const FRAMESET_68713: int = 0x4713  # turning, left
const FRAMESET_6871E: int = 0x471E  # right
const BIG_OCTOHON_FUNC: int = 0x12_669A  # BigOctohonFunc
const BIG_OCTOHON_FACE: int = 0x12_66B9  # .Func_4a6b9
const BIG_OCTOHON_UPDATE: int = 0x12_6729  # .Func_4a729
const OBJ_INTERACTION_49: int = 0x49
const DATA_60D50: int = 0x4D50  # the Big Octohon knocked back (bank $18)
const FRAMESET_69B57: int = 0x5B57  # swimming left
const FRAMESET_69B60: int = 0x5B60  # right
const FRAMESET_69B69: int = 0x5B69  # bonked, or turning, left
const FRAMESET_69B74: int = 0x5B74  # right
const FRAMESET_69B7F: int = 0x5B7F  # hit, left
const FRAMESET_69B88: int = 0x5B88  # right
const FRAMESET_69BC3: int = 0x5BC3  # charging, left
const FRAMESET_69BCE: int = 0x5BCE  # right
const DATA_60690: int = 0x4690  # the Sun's bob while it attacks (bank $18)
const DATA_606E0: int = 0x46E0  # its flame flying left
const DATA_606F0: int = 0x46F0  # right
const FRAMESET_68F6B: int = 0x4F6B  # facing right
const FRAMESET_68F74: int = 0x4F74  # facing left
const FRAMESET_68F8F: int = 0x4F8F  # attacking, right
const FRAMESET_68F9E: int = 0x4F9E  # left
const FRAMESET_68FB7: int = 0x4FB7  # turning left
const FRAMESET_68FC0: int = 0x4FC0  # turning right
const FRAMESET_68FC9: int = 0x4FC9  # the flame's end
const FRAMESET_68FD0: int = 0x4FD0  # the Moon facing right
const FRAMESET_68FD9: int = 0x4FD9  # left
const FRAMESET_68FF4: int = 0x4FF4  # attacking, right
const FRAMESET_69003: int = 0x5003  # left
const FRAMESET_69024: int = 0x5024  # the star's end
const FRAMESET_6902B: int = 0x502B  # turning left
const FRAMESET_69036: int = 0x5036  # turning right
# The Sun's and the Moon's looks: facing right, left; turning right, left; attacking right, left.
const SUN_LOOKS: Array[int] = [FRAMESET_68F6B, FRAMESET_68F74, FRAMESET_68FC0, FRAMESET_68FB7, FRAMESET_68F8F,
		FRAMESET_68F9E]
const MOON_LOOKS: Array[int] = [FRAMESET_68FD0, FRAMESET_68FD9, FRAMESET_69036, FRAMESET_6902B, FRAMESET_68FF4,
		FRAMESET_69003]
const ROBO_MOUSE_FUNC: int = 0x12_48DC  # RoboMouseFunc
const ROBO_MOUSE_FUNC_FACE: int = 0x12_48F7  # .Func_488f7
const ROBO_MOUSE_FUNC_UPDATE: int = 0x12_492A  # .Func_4892a
const OBJ_INTERACTION_ROBO_MOUSE: int = 0x30
const OBJ_PARAMS_STARS_ABOVE: int = 0x4F05  # bank $19
const FRAMESET_691DE: int = 0x51DE  # walking right
const FRAMESET_691E5: int = 0x51E5
const FRAMESET_691F2: int = 0x51F2
const FRAMESET_691FB: int = 0x51FB
const FRAMESET_69200: int = 0x5200
const FRAMESET_69205: int = 0x5205
const FRAMESET_6920C: int = 0x520C
const FRAMESET_69213: int = 0x5213
const FRAMESET_69220: int = 0x5220  # walking left
const FRAMESET_69227: int = 0x5227
const SMALL_OCTOHON_FUNC: int = 0x12_64B5  # SmallOctohonFunc
const SMALL_OCTOHON_FUNC_FACE: int = 0x12_64D4  # .Func_4a4d4
const SMALL_OCTOHON_FUNC_SWIM: int = 0x12_650F  # .Func_4a50f
const DIV_SMALL_OCTOHON: int = 0x12_6503  # .asm_4a4f7's rDIV read
const DATA_4A5A9: int = 0x65A9  # the sway, in bank $12
const FRAMESET_69B2F: int = 0x5B2F
const FRAMESET_69B38: int = 0x5B38
const FRAMESET_69B41: int = 0x5B41
const FRAMESET_69B4C: int = 0x5B4C


func object_functions() -> Dictionary:
	var functions: Dictionary = super()
	functions.merge({
		PARA_GOOM_FUNC: para_goom_func,
		PARA_GOOM_FUNC_INIT: para_goom_init,
		PARA_GOOM_FUNC_UPDATE: para_goom_update,
		BRRR_BEAR_FUNC: brrr_bear_func,
		BRRR_BEAR_FUNC_INIT: brrr_bear_init,
		BRRR_BEAR_FUNC_UPDATE: brrr_bear_update,
		SNOWFLAKE_FUNC_LEFT: snowflake_func_left,
		SNOWFLAKE_FUNC_RIGHT: snowflake_func_right,
		SNOWFLAKE_FUNC_UPDATE: snowflake_update,
		HARIDAMA_FUNC: haridama_func,
		HARIDAMA_FUNC_INIT: haridama_init,
		HARIDAMA_FUNC_UPDATE: haridama_update,
		HARIDAMA_FUNC_OUT: haridama_out,
		HAND_FUNC: hand_func,
		HAND_FUNC_UPDATE: hand_update,
		COUNT_RICHTERTOFFEN_FUNC: count_richtertoffen_func,
		COUNT_RICHTERTOFFEN_UPDATE: count_richtertoffen_update,
		MAD_SCIENSTEIN_FUNC: mad_scienstein_func,
		MAD_SCIENSTEIN_INIT: mad_scienstein_init,
		MAD_SCIENSTEIN_UPDATE: mad_scienstein_update,
		SUN_FUNC: sun_func,
		SUN_CHECK_DIRECTION: sun_check_direction,
		SUN_UPDATE: sun_update,
		SUN_FLAME_FUNC_LEFT: sun_flame_func_left,
		SUN_FLAME_FUNC_RIGHT: sun_flame_func_right,
		SUN_FLAME_UPDATE: sun_flame_update,
		MOON_FUNC: moon_func,
		MOON_CHECK_DIRECTION: moon_check_direction,
		MOON_UPDATE: moon_update,
		MOON_STAR_FUNC_LEFT: moon_star_func_left,
		MOON_STAR_FUNC_RIGHT: moon_star_func_right,
		MOON_STAR_UPDATE: sun_flame_update,  # the same code
		MIZUUO_FUNC: mizuuo_func,
		MIZUUO_UPDATE_1: mizuuo_update_1,
		MIZUUO_UPDATE_2: mizuuo_update_2,
		MIZUUO_UPDATE_3: mizuuo_update_3,
		MIZUUO_UPDATE_4: mizuuo_update_4,
		MIZZOU_PROJECTILE_FUNC_LEFT: mizzou_projectile_func_left,
		MIZZOU_PROJECTILE_FUNC_RIGHT: mizzou_projectile_func_right,
		MIZZOU_PROJECTILE_UPDATE: sun_flame_update,  # the same code: no actions, then gone
		BIG_OCTOHON_FUNC: big_octohon_func,
		BIG_OCTOHON_FACE: big_octohon_face,
		BIG_OCTOHON_UPDATE: big_octohon_update,
		ROBO_MOUSE_FUNC: robo_mouse_func,
		ROBO_MOUSE_FUNC_FACE: robo_mouse_face,
		ROBO_MOUSE_FUNC_UPDATE: robo_mouse_update,
		SMALL_OCTOHON_FUNC: small_octohon_func,
		SMALL_OCTOHON_FUNC_FACE: small_octohon_face,
		SMALL_OCTOHON_FUNC_SWIM: small_octohon_swim,
		GREY_PRINCE_FROGGY_FUNC: grey_prince_froggy_func,
		RED_PRINCE_FROGGY_FUNC: red_prince_froggy_func,
		PRINCE_FROGGY_STUCK: prince_froggy_stuck,
		PRINCE_FROGGY_SITTING: prince_froggy_sitting,
		PRINCE_FROGGY_LEAVING: prince_froggy_leaving,
		TOGEBA_FUNC: togeba_func,
		TOGEBA_WAIT: togeba_wait,
		TOGEBA_SHAKEN: togeba_shaken,
		TOGEBA_LANDED: togeba_landed,
		TOGEBA_PLATFORM: togeba_platform,
		TOGEBA_RISING: togeba_rising,
		KUSHIMUSHI_VERTICAL_FUNC: kushimushi_vertical_func,
		KUSHIMUSHI_VERTICAL_UPDATE: kushimushi_vertical_update,
		KUSHIMUSHI_HORIZONTAL_FUNC: kushimushi_horizontal_func,
		KUSHIMUSHI_HORIZONTAL_UPDATE: kushimushi_horizontal_update,
		BEAM_BOT_FUNC: beam_bot_func,
		BEAM_BOT_FUNC_INIT: beam_bot_init,
		BEAM_BOT_FUNC_UPDATE: beam_bot_update,
		BEAM_FUNC_LEFT: beam_func_left,
		BEAM_FUNC_LEFT_UPDATE: beam_update_left,
		BEAM_FUNC_RIGHT: beam_func_right,
		BEAM_FUNC_RIGHT_UPDATE: beam_update_right,
		SPEAR_BOT_FUNC: spear_bot_func,
		SPEAR_BOT_FUNC_INIT: spear_bot_init,
		SPEAR_BOT_FUNC_UPDATE: spear_bot_update,
		FIRE_BOT_FUNC: fire_bot_func,
		FIRE_BOT_FUNC_INIT: fire_bot_init,
		FIRE_BOT_FUNC_UPDATE: fire_bot_update,
		HAMMER_BOT_FUNC: hammer_bot_func,
		HAMMER_BOT_FUNC_INIT: hammer_bot_init,
		HAMMER_BOT_FUNC_UPDATE: hammer_bot_update,
		HEBARII_FUNC: hebarii_func,
		HEBARII_FUNC_INIT: hebarii_init,
		HEBARII_FUNC_ATTACHED: hebarii_attached,
		HEBARII_FUNC_DETACHED: hebarii_detached,
		HEBARII_PROJECTILE_FUNC: hebarii_projectile_func,
		HEBARII_PROJECTILE_FUNC_LATERAL: hebarii_projectile_lateral,
		HEBARII_PROJECTILE_FUNC_DOWN: hebarii_projectile_down,
		HEBARII_PROJECTILE_FUNC_DESTROY: hebarii_projectile_destroy,
		OWL_FUNC: owl_func,
		OWL_FUNC_SLEEP: owl_sleep,
		OWL_FUNC_WAKE_UP: owl_wake_up,
		OWL_FUNC_FLY_UPWARDS: owl_fly_upwards,
		OWL_FUNC_FLY: owl_fly,
		TADPOLE_SPAWNER_FUNC: tadpole_spawner_func,
		TADPOLE_SPAWNER_FUNC_WAIT: tadpole_spawner_wait,
		TADPOLE_SPAWNER_FUNC_SPENT: tadpole_spawner_spent,
		TADPOLE_FUNC: tadpole_func,
		TADPOLE_FUNC_HIDDEN: tadpole_hidden,
		TADPOLE_FUNC_READY: tadpole_ready,
		TADPOLE_FUNC_LEAP: tadpole_leap,
		TADPOLE_FUNC_SPLASH: tadpole_splash,
		TERUTERU_FUNC: teruteru_func,
		TERUTERU_FUNC_INIT: teruteru_init,
		TERUTERU_FUNC_UPDATE: teruteru_update,
		ZOMBIE_FUNC: zombie_func,
		ZOMBIE_FUNC_INIT: zombie_init,
		ZOMBIE_FUNC_UNDERGROUND: zombie_underground,
		ZOMBIE_FUNC_START_RISE: zombie_start_rise,
		ZOMBIE_FUNC_RISING: zombie_rising,
		ZOMBIE_FUNC_ON_SURFACE: zombie_on_surface,
		ZOMBIE_FUNC_HEADLESS: zombie_headless,
		ZOMBIE_HEAD_FUNC_LEFT: zombie_head_func_left,
		ZOMBIE_HEAD_FUNC_RIGHT: zombie_head_func_right,
		ZOMBIE_HEAD_FUNC_FLICKER: zombie_head_flicker,
		DOUGHNUTEER_FUNC: doughnuteer_func,
		DOUGHNUTEER_FUNC_INIT: doughnuteer_init,
		DOUGHNUTEER_FUNC_UPDATE: doughnuteer_update,
		DOUGHNUT_FUNC_LEFT: doughnut_func_left,
		DOUGHNUT_FUNC_RIGHT: doughnut_func_right,
		DOUGHNUT_FUNC_UP: doughnut_func_up,
		DOUGHNUT_FUNC_UP_UPDATE: doughnut_up_update,
		DOUGHNUT_FUNC_UPDATE_LEFT: doughnut_update_left,
		DOUGHNUT_FUNC_UPDATE_RIGHT: doughnut_update_right,
		PNEUMO_FUNC: pneumo_func,
		PNEUMO_FUNC_UPDATE: pneumo_update,
		OMODONMEKA_FUNC: omodonmeka_func,
		OMODONMEKA_FUNC_UPDATE: omodonmeka_update,
		OMODONMEKA_WITH_OMODON_1_FUNC: omodonmeka_with_omodon_1_func,
		OMODONMEKA_WITH_OMODON_2_FUNC: omodonmeka_with_omodon_2_func,
		OMODONMEKA_WITH_OMODON_FUNC: omodonmeka_with_omodon_update,
		OMODONMEKA_WITH_OMODON_FUNC_FLY_OFF: _carrier_fly_off,
		OMODON_FUNC: omodon_func,
		OMODON_FUNC_UPDATE: omodon_update,
	})
	return functions


## A walking step half a pixel a frame along the floor, looking `left` px left of the object or
## `right` px right of it, as the standard enemies' walks do: no floor under it (Func_3543) and
## it falls ($11); a wall ahead (Func_3513, UNK4) or the floor's end turns it ($13).
func enemy_step(left: int, right: int) -> void:
	if enemy_on_floor():
		enemy_side_step(left, right)


## The step's floor: the object stands on what Func_3543 (DOWN) finds; nothing, and it falls
## ($11, false).
func enemy_on_floor() -> bool:
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return false
	store_object_y_from_hpos()
	return true


## The step along the floor just probed (`slow`: half a pixel a frame, else one), or a turn ($13).
func enemy_side_step(left: int, right: int, slow: bool = true) -> void:
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if fine_x + right >= 0x10 and (process_block_on_right() & 0x0F) == 0:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
			return
		set_hpos_from_object(-4, right)
		if object_probe(COLLISION_UNK4) == 0:
			if slow:
				move_object_right_slow()
			else:
				move_object_x(1)
			return
	else:
		if fine_x < left and (process_block_on_left() & 0x0F) == 0:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
			return
		set_hpos_from_object(-4, -left)
		if object_probe(COLLISION_UNK4) == 0:
			if slow:
				move_object_left_slow()
			else:
				move_object_x(-1)
			return
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


# --- Para-Goom (objects/para_goom.asm) ----------------------------------------------------

## ParaGoomFunc: .Init on the next update.
func para_goom_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, PARA_GOOM_FUNC_INIT & 0xFFFF)


## ParaGoomFunc.Init: visible, then .Default.
func para_goom_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, PARA_GOOM_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_para_goom_default()


## ParaGoomFunc.Update's table, by OBJ_STATE: Para-Goom's own entries, then the shared ones.
## Para-Goom is tall (OBJ_COLLBOX_TOP $ef, stinging on top) or short ($f4); several entries
## choose their framesets by that.
func para_goom_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3D, 0x3E, 0x5D:
			_para_goom_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			_para_goom_walk_start()
		0x02, 0x03:
			_para_goom_bump_start(state + 0x30)
		0x04, 0x05, 0x28, 0x29:
			_para_goom_knocked_start(state + 0x30)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			_para_goom_wobble_start(state + 0x30)
		0x0B, 0x0C:
			enemy_stun_start(state + 0x30)
		0x0D:
			var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			_para_goom_wobble_start(OBJSTATE_WOBBLE_RIGHT if left_of_wario else OBJSTATE_WOBBLE_LEFT)
		0x0F:
			_para_goom_lie_start()
		0x10:
			_para_goom_get_up_start()
		0x11:
			_para_goom_standing_fall_start()
		0x12:
			_para_goom_12()
		0x13:
			_para_goom_turn_start()
		0x14, 0x15:
			_para_goom_tumble_start(state + 0x30)
		0x16, 0x17:
			_para_goom_slide_start(state + 0x30)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, FRAMESET_684AA, FRAMESET_684AF)
		0x2D:
			_para_goom_wait(true)
		0x2E:
			_para_goom_wait(false)
		0x31:
			_para_goom_walk()
		0x3B:
			enemy_stunned(true)
		0x3C:
			enemy_stunned(false)
		0x3F:
			enemy_lie()
		0x40:
			_para_goom_get_up()
		0x41:
			_para_goom_standing_fall()
		0x43:
			_para_goom_turn()
		0x46:
			enemy_slide(true)
		0x47:
			enemy_slide(false)
		0x4C, 0x4D:
			enemy_full_throw_start(state == 0x4C, FRAMESET_684A1, FRAMESET_684A1)
		0x5A:
			_para_goom_landing()
		0x5B:
			_para_goom_float_down()
		0x5C:
			_para_goom_landed()
		_:
			if not common_enemy_state(state):
				note_unported("ParaGoomFunc state %02x" % state)


func _para_goom_tall() -> bool:
	return cur(OBJ_COLLBOX_TOP) == COLLBOX_TOP_TALL


## .Default: short and harmless (OBJ_INTERACTION_01), falling ($30), facing Wario. With nothing
## under it (Func_352b, UNK1), it floats instead ($41 at once: .asm_41505).
func _para_goom_default() -> void:
	set_cur(OBJ_VAR_1, 0)
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	if right:
		set_object_frameset_ptr(FRAMESET_68442)
		set_collbox_x(-7, 9)
	else:
		set_object_frameset_ptr(FRAMESET_68439)
		set_collbox_x(-10, 6)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) != 0:
		return
	set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
	set_cur(OBJ_STATE_DURATION, 0)
	_para_goom_grow_tall()


## .asm_41505: tall, stinging on top.
func _para_goom_grow_tall() -> void:
	set_object_frameset_ptr(FRAMESET_684BA)
	set_interaction(OBJ_INTERACTION_TOP_STING)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_TALL)


## .Func_414c0 (OBJSTATE $11): the floor gone, a pause ($41: $38 frames short, $29 tall).
func _para_goom_standing_fall_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
	set_cur(OBJ_VAR_3, 0)
	if _para_goom_tall():
		set_object_frameset_ptr(FRAMESET_68546 if hdir() else FRAMESET_6852D)
		set_cur(OBJ_STATE_DURATION, 0x29)
	else:
		set_object_frameset_ptr(FRAMESET_6850A if hdir() else FRAMESET_684E7)
		set_cur(OBJ_STATE_DURATION, 0x38)


## .Func_414fb (OBJSTATE $41): the pause, then tall; with no pause left, floating down.
func _para_goom_standing_fall() -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		_para_goom_float_down()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_para_goom_grow_tall()


## .Func_41830 (OBJSTATE $5b): down half a pixel a frame until something is under it (Func_352b,
## UNK1), then landed ($5c, 10 frames); in water or sand it vanishes ($0a).
func _para_goom_float_down() -> void:
	move_object_down_slow()
	set_hpos_from_object()
	wObjSlopeInteraction = 0
	if object_probe(COLLISION_UNK1) == 0:
		if wIsInWaterOrSand != 0:
			set_cur(OBJ_STATE, 0x0A)
		return
	store_object_y_from_hpos()
	set_cur(OBJ_STATE, 0x5C)
	set_object_frameset_ptr(FRAMESET_6855F)
	set_cur(OBJ_STATE_DURATION, 0x0A)


## .Func_4186f (OBJSTATE $5c): landed; then .Default.
func _para_goom_landed() -> void:
	if ground_shake_wobble(DIV_PARA_GOOM_LANDED):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, 0x00)


## .asm_41570: walking ($31) short, after 10 frames' grace (.Func_41598).
func _para_goom_walk_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	if hdir():
		set_collbox_x(-7, 9)
		set_object_frameset_ptr(FRAMESET_68442)
	else:
		set_collbox_x(-10, 6)
		set_object_frameset_ptr(FRAMESET_68439)
	set_cur(OBJ_STATE_DURATION, 0x0A)


## .asm_41545: walking ($31) tall.
func _para_goom_walk_start_tall() -> void:
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_object_frameset_ptr(FRAMESET_68454 if hdir() else FRAMESET_6844B)
	set_cur(OBJ_STATE_DURATION, 0)
	set_interaction(OBJ_INTERACTION_TOP_STING)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_TALL)


## .Func_41598 (OBJSTATE $31): the grace counts down, ending stinging in front; then every 256
## frames (OBJ_VAR_1) a change for $a3 frames: tall to short ($2e) or short to tall ($2d).
## Otherwise a step.
func _para_goom_walk() -> void:
	if ground_shake_wobble(DIV_PARA_GOOM_WALK):
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_interaction(OBJ_INTERACTION_FRONT_STING)
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)
	if cur(OBJ_VAR_1) != 0:
		enemy_step(byte(-cur(OBJ_COLLBOX_LEFT)), cur(OBJ_COLLBOX_RIGHT))  # .asm_41611: by its box
		return
	if _para_goom_tall():
		set_cur(OBJ_STATE, OBJSTATE_SPECIAL_2)
		set_object_frameset_ptr(FRAMESET_68490 if hdir() else FRAMESET_6846E)
		set_cur(OBJ_STATE_DURATION, 0xA3)
		set_interaction(OBJ_INTERACTION_01)
		set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)
	else:
		set_cur(OBJ_STATE, 0x2D)
		set_object_frameset_ptr(FRAMESET_6847F if hdir() else FRAMESET_6845D)
		set_cur(OBJ_STATE_DURATION, 0xA3)
		set_interaction(OBJ_INTERACTION_01)
		set_collbox_x(-6, 5)


## .Func_4152f ($2d, then walking tall) and .Func_41517 ($2e, then walking short).
func _para_goom_wait(to_tall: bool) -> void:
	if ground_shake_wobble(DIV_PARA_GOOM_WAIT_TALL if to_tall else DIV_PARA_GOOM_WAIT):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	if to_tall:
		_para_goom_walk_start_tall()
	else:
		_para_goom_walk_start()


## .Func_416b0/.Func_416b8 (OBJSTATE_02/03): bumped ($32, $33), harmless.
func _para_goom_bump_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	if _para_goom_tall():
		set_object_frameset_ptr(FRAMESET_68454 if hdir() else FRAMESET_6844B)
	else:
		set_object_frameset_ptr(FRAMESET_68442 if hdir() else FRAMESET_68439)
	set_cur(OBJ_STATE_DURATION, 0x0C)
	set_cur(OBJ_VAR_2, 2)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_01)


## .Func_419a6 to .Func_41992: knocked away (`state`), OBJ_SUBSTATE's low nibble cleared.
func _para_goom_knocked_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_object_frameset_ptr(FRAMESET_684AF if hdir() else FRAMESET_684AA)


## .Func_41912/.Func_4191c (and OBJSTATE_0D toward Wario): a wobble ($38 left, $39 right), short.
func _para_goom_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_684AF if hdir() else FRAMESET_684AA)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)


## .Func_417a2 (OBJSTATE_0F): lying for 100 frames ($3f, `enemy_lie`).
func _para_goom_lie_start() -> void:
	set_cur(OBJ_STATE, 0x3F)
	set_cur(OBJ_STATE_DURATION, 0x64)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	enemy_lie()


## .Func_417cb (OBJSTATE_10): getting up tall, rising for 8 frames ($40).
func _para_goom_get_up_start() -> void:
	set_cur(OBJ_STATE, 0x40)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_684B4)
	set_cur(OBJ_STATE_DURATION, 8)
	set_interaction(OBJ_INTERACTION_TOP_STING)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_TALL)
	_para_goom_get_up()


## .Func_417e8: rising along Data_60530 until the time is up or a ceiling (Func_358b, UNK3) is 8
## px above; then 4 frames ($5a) before floating down.
func _para_goom_get_up() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		set_hpos_from_object(-8, 0)
		if (object_probe(COLLISION_UNK3) & 0x0F) == 0:
			apply_obj_y_movement(DATA_60530)
			return
	set_cur(OBJ_STATE, 0x5A)
	set_object_frameset_ptr(FRAMESET_684B7)
	set_cur(OBJ_STATE_DURATION, 4)


## .Func_4181c (OBJSTATE $5a): then floating down ($5b).
func _para_goom_landing() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE, 0x5B)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_684BA)


## .Func_41a64 (OBJSTATE_12): $42 (Func_3371), short and harmless.
func _para_goom_12() -> void:
	set_cur(OBJ_ACTION, 0x9F)
	set_cur(OBJ_STATE, 0x42)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)


## .Func_4188b (OBJSTATE $13): turning for $44 frames ($43).
func _para_goom_turn_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
	if _para_goom_tall():
		set_object_frameset_ptr(FRAMESET_684E0 if hdir() else FRAMESET_684D9)
	else:
		set_object_frameset_ptr(FRAMESET_684D2 if hdir() else FRAMESET_684CB)
	set_cur(OBJ_STATE_DURATION, 0x44)


## .Func_418c4: halfway (at $27 left) harmless and turned round; meanwhile Func_62908 (it falls if
## the floor goes); at the end walking, tall (.asm_41545) or short (state $01, .Func_41567).
func _para_goom_turn() -> void:
	if ground_shake_wobble(DIV_PARA_GOOM_TURN):
		return
	if cur(OBJ_STATE_DURATION) == 0x27:
		set_cur(OBJ_STATE_DURATION, 0x26)
		set_interaction(OBJ_INTERACTION_01)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	if _para_goom_tall():
		_para_goom_walk_start_tall()
		return
	set_cur(OBJ_STATE, 0x01)


## .Func_41767/.Func_4176f (OBJSTATE_14/15): tumbling ($44, $45), short.
func _para_goom_tumble_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_684AF if hdir() else FRAMESET_684AA)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)


## .Func_416fb/.Func_41731 (OBJSTATE_16/17): sliding ($46, $47), short; the slide at once.
func _para_goom_slide_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_684AF if hdir() else FRAMESET_684AA)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_COLLBOX_TOP, COLLBOX_TOP_SHORT)
	enemy_slide(state == OBJSTATE_STUN_LEFT)


# --- Brrr Bear (objects/brrr_bear.asm) ----------------------------------------------------

## BrrrBearFunc: .Init on the next update.
func brrr_bear_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BRRR_BEAR_FUNC_INIT & 0xFFFF)


## BrrrBearFunc.Init: visible, its box, then .Default.
func brrr_bear_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, BRRR_BEAR_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-9, 8)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	_brrr_bear_default()


## BrrrBearFunc.Update's table, by OBJ_STATE (93 entries, to $5c): its own entries, then the
## shared ones.
func brrr_bear_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0B, 0x0C, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2E, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, \
				0x5A, 0x5B, 0x5C:
			_brrr_bear_default()
		0x01:
			_brrr_bear_walk_start()
		0x02, 0x03:
			_brrr_bear_bump_start(state + 0x30)
		0x04, 0x05:
			_brrr_bear_attacked(state)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			_brrr_bear_wobble_start(state + 0x30)
		0x0A:
			_brrr_bear_0a()
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		0x10:
			_brrr_bear_get_up_start()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_69126 if hdir() else FRAMESET_69115)
		0x12:
			set_cur(OBJ_ACTION, 0x9F)
			set_cur(OBJ_STATE, 0x42)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		0x13:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(FRAMESET_6917C if hdir() else FRAMESET_69175)
			set_cur(OBJ_STATE_DURATION, 0x16)
			set_interaction(OBJ_INTERACTION_01)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_6915B)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_6915B)
			set_interaction(OBJ_INTERACTION_00)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			carried_object_held(state, FRAMESET_6915B)
		0x28, 0x29:
			_brrr_bear_knocked_start(state + 0x30, 2)
		0x2D:
			_brrr_bear_blow()
		0x31:
			_brrr_bear_walk()
		0x3F:
			enemy_lie()
		0x40:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, 0x01)
		0x43:
			_brrr_bear_turn()
		0x46:
			enemy_slide(true)
		0x47:
			enemy_slide(false)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("BrrrBearFunc state %02x" % state)


## .Func_4811f (.Default): harmless (OBJ_INTERACTION_01), falling ($30), facing Wario.
func _brrr_bear_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_69126 if right else FRAMESET_69115)


## .Func_481aa (OBJSTATE_LAND): walking ($31).
func _brrr_bear_walk_start() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_object_frameset_ptr(FRAMESET_69126 if hdir() else FRAMESET_69115)


## .Func_481ca (OBJSTATE $31): with Wario level with it (within $18 rows) and within $48 px
## ahead, it blows ($2d, $39 frames); with him that near behind, it turns ($13); otherwise a step
## (8 px left, 7 right).
func _brrr_bear_walk() -> void:
	if ground_shake_wobble(DIV_BRRR_BEAR_WALK):
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy < 0x18 or dy >= 0xE8:
		var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
		if dx >= 0xB8 or dx < 0x48:
			var wario_right: bool = dx >= 0xB8
			if hdir() != wario_right:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
			set_cur(OBJ_STATE, 0x2D)
			set_object_frameset_ptr(FRAMESET_6914C if wario_right else FRAMESET_6913D)
			set_cur(OBJ_STATE_DURATION, 0x39)
			return
	enemy_step(8, 7)


## .Func_4816f (OBJSTATE $2d): blowing; with $22 frames left a snowflake the way it faces; at
## the end a turn ($13). The sound (SFX_07E) is not simulated.
func _brrr_bear_blow() -> void:
	if ground_shake_wobble(DIV_BRRR_BEAR_BLOW):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
		return
	if cur(OBJ_STATE_DURATION) != 0x22:
		return
	create_object_at_relative_pos(OBJ_PARAMS_SNOWFLAKE_RIGHT if hdir() else OBJ_PARAMS_SNOWFLAKE_LEFT)


## .Func_482b2/.Func_482ba (OBJSTATE_02/03): bumped ($32, $33), harmless.
func _brrr_bear_bump_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_6913A if hdir() else FRAMESET_69137)
	set_cur(OBJ_STATE_DURATION, 0x0C)
	set_cur(OBJ_VAR_2, 2)
	set_interaction(OBJ_INTERACTION_01)


## .Func_48434/.Func_48458 (OBJSTATE_04/05): attacked; unless Wario is transformed or has
## the garlic or better, or it is harmless, it only wobbles (OBJSTATE_08/09); otherwise knocked
## away ($34, $35).
func _brrr_bear_attacked(state: int) -> void:
	if wTransformation == 0 and wram1[W_EFFECTIVE_POWER_UP] < GARLIC_OR_BETTER \
			and (cur(OBJ_INTERACTION_TYPE) & 0x7F) != 0:
		set_cur(OBJ_STATE, state + 0x04)
		return
	_brrr_bear_knocked_start(state + 0x30, 1)


## .asm_4847a: knocked away (`state`), OBJ_VAR_2 `var_2`, OBJ_SUBSTATE's low nibble cleared.
func _brrr_bear_knocked_start(state: int, var_2: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, var_2)
	set_object_frameset_ptr(FRAMESET_69164)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


## .Func_483f5/.Func_483ff (OBJSTATE_08/09): a wobble ($38 left, $39 right).
func _brrr_bear_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_6915B)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)


## .Func_480e7 (OBJSTATE_0A): vanishing (VanishObject2) unless it has an action
## left, Wario is untransformed without the garlic's successor, and it is not harmless; then
## a wobble away from Wario (SFX_014 not simulated).
func _brrr_bear_0a() -> void:
	if cur(OBJ_ACTION) == 0 or wTransformation != 0 or wram1[W_EFFECTIVE_POWER_UP] >= 0x06 \
			or (cur(OBJ_INTERACTION_TYPE) & 0x7F) == 0:
		vanish_object()  # VanishObject2
		return
	var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	_brrr_bear_wobble_start(OBJSTATE_WOBBLE_RIGHT if left_of_wario else OBJSTATE_WOBBLE_LEFT)


## .Func_4836a (OBJSTATE_10): getting up facing Wario, $28 frames ($40), then walking.
func _brrr_bear_get_up_start() -> void:
	set_cur(OBJ_STATE, 0x40)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_6918E if right else FRAMESET_69183)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_interaction(OBJ_INTERACTION_01)


## .Func_483c5 (OBJSTATE $43): turned round with 6 frames left; meanwhile Func_62908; then
## walking (OBJSTATE_LAND's entry, .Func_481aa).
func _brrr_bear_turn() -> void:
	if ground_shake_wobble(DIV_BRRR_BEAR_TURN):
		return
	if cur(OBJ_STATE_DURATION) == 0x06:
		set_cur(OBJ_STATE_DURATION, 0x05)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x01)


# --- Snowflakes (objects/brrr_bear.asm) ---------------------------------------------------

## SnowflakeFunc_Left/_Right: 2 px a frame (MoveObjectLeft_Fast, MoveObjectRight_Fast), then
## SnowflakeFunc.
func snowflake_func_left() -> void:
	move_object_x(-2)
	_snowflake_func()


func snowflake_func_right() -> void:
	move_object_x(2)
	_snowflake_func()


## SnowflakeFunc: no collision with other objects; once its state is set, the burst
## (Frameset_6916e) for 12 frames (.Update).
func _snowflake_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_STATE) == 0:
		return
	set_object_frameset_ptr(FRAMESET_6916E)
	set_cur(OBJ_STATE_DURATION, 0x0C)
	set_cur_word(OBJ_UPDATE_FUNCTION, SNOWFLAKE_FUNC_UPDATE & 0xFFFF)


## SnowflakeFunc.Update: no actions; cleared when the time is up.
func snowflake_update() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Haridama (objects/haridama.asm) ------------------------------------------------------

## HaridamaFunc: .Init on the next update.
func haridama_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HARIDAMA_FUNC_INIT & 0xFFFF)


## HaridamaFunc.Init: no collision with other objects, its box, facing Wario.
func haridama_init() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, HARIDAMA_FUNC_UPDATE & 0xFFFF)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -3)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_69290 if right else FRAMESET_6927F)


## HaridamaFunc.Update, by OBJ_STATE.
func haridama_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_haridama_swim()
	elif state == 0x5A:
		_haridama_turning()
	elif state == 0x5B:
		_haridama_alerted()
	elif state == 0x02:
		_haridama_hit(true)
	elif state == 0x03:
		_haridama_hit(false)
	elif (state & 0xFE) == 0x08:
		_haridama_08()
	elif (state & 0xFE) == 0x32:
		_haridama_charge()
	elif (state & 0xFE) == 0x38:
		_haridama_rise()
	else:
		_haridama_turn_start(FRAMESET_692AA if hdir() else FRAMESET_692A1)


## .Func_48f28 (state 0): with Wario level with it (within 8 rows above, $18 below) and within
## $40 px ahead, alerted ($5b); otherwise half a pixel a frame along, turning at a wall.
func _haridama_swim() -> void:
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	var level: bool = dy < 0x08 or dy >= 0xE8
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	if not hdir():
		if level and dx < 0x40:
			_haridama_alert(FRAMESET_692C7)
		elif _haridama_wall_left() == 0:
			move_object_left_slow()
		else:
			_haridama_turn_start(FRAMESET_692A1)
	else:
		if level and dx >= 0xC0:
			_haridama_alert(FRAMESET_692CE)
		elif _haridama_wall_right() == 0:
			move_object_right_slow()
		else:
			_haridama_turn_start(FRAMESET_692AA)


## .asm_48f8e: turning ($5a, $1b frames), its spikes in (OBJ_INTERACTION_06).
func _haridama_turn_start(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 0x1B)
	set_cur(OBJ_STATE, 0x5A)
	set_interaction(OBJ_INTERACTION_06)


## .asm_48fa2: alerted ($5b, $12 frames).
func _haridama_alert(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 0x12)
	set_cur(OBJ_STATE, 0x5B)


## .Func_48fae (state $5b): then charging ($32) with its spikes out (OBJ_INTERACTION_HARIDAMA).
func _haridama_alerted() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_interaction(OBJ_INTERACTION_HARIDAMA)
	set_cur(OBJ_STATE, 0x32)
	set_object_frameset_ptr(FRAMESET_692C2 if hdir() else FRAMESET_692BD)


## .asm_49020 (states $32, $33): 2 px a frame until a wall, then a turn.
func _haridama_charge() -> void:
	if not hdir():
		if _haridama_wall_left() == 0:
			move_object_x(-2)
		else:
			_haridama_turn_start(FRAMESET_692A1)
	elif _haridama_wall_right() == 0:
		move_object_x(2)
	else:
		_haridama_turn_start(FRAMESET_692AA)


## .asm_4903e (state $5a): turned round with $0d frames left, then swimming (.asm_49054).
func _haridama_turning() -> void:
	if cur(OBJ_STATE_DURATION) == 0x0D:
		set_cur(OBJ_STATE_DURATION, 0x0C)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_haridama_swim_start()


## .asm_49054
func _haridama_swim_start() -> void:
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_69290 if hdir() else FRAMESET_6927F)


## .asm_49013 (state 2, `facing_right` passed by the caller's branch) and .asm_49006 (state 3):
## charging ($32), the frameset for being hit from behind, or a turn when hit from the front.
func _haridama_hit(state_2: bool) -> void:
	set_cur(OBJ_STATE, 0x32)
	if hdir() == state_2:
		set_object_frameset_ptr(FRAMESET_692B8 if state_2 else FRAMESET_692B3)
		return
	_haridama_turn_start(FRAMESET_692AA if hdir() else FRAMESET_692A1)


## .asm_49069 (states 8, 9): hit from below (OBJ_UNK_1D bit 7), it surfaces ($38, spikes in);
## otherwise as state 2 or 3 by its direction.
func _haridama_08() -> void:
	if (cur(OBJ_UNK_1D) & 0x80) == 0:
		_haridama_hit(hdir())
		return
	set_interaction(OBJ_INTERACTION_06)
	set_cur(OBJ_STATE, 0x38)
	set_object_frameset_ptr(FRAMESET_692DE if hdir() else FRAMESET_692D5)


## .Func_49094 (states $38, $39): up half a pixel a frame while water is above both its corners
## (Func_358b, UNK3, 17 px up); then out of the water (.Func_490e8) for 100 frames.
func _haridama_rise() -> void:
	set_hpos_from_object(-0x11, -8)
	if object_probe(COLLISION_UNK3) == 0 and wIsInWaterOrSand != 0:
		set_hpos_from_object(-0x11, 7)
		if object_probe(COLLISION_UNK3) == 0:
			move_object_up_slow()
			return
	set_cur_word(OBJ_UPDATE_FUNCTION, HARIDAMA_FUNC_OUT & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 0x64)
	set_cur(OBJ_STATE, 0)


## .Func_490e8: out of the water. State 0 drifts a pixel every fourth frame, turning at walls,
## for 100 frames, then swims again (by its frame, the right way round); a hit (any other
## state) sends it away from Wario for 60 frames ($32 left, $33 right).
func haridama_out() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_haridama_drift()
	elif state == 0x32:
		_haridama_flee(false)
	elif state == 0x33:
		_haridama_flee(true)
	else:
		var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
		set_cur(OBJ_STATE, 0x32 if left_of_wario else 0x33)
		set_hdir(not left_of_wario)
		set_cur(OBJ_VAR_1, 0x3C)


## .asm_49118
func _haridama_drift() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur_word(OBJ_UPDATE_FUNCTION, HARIDAMA_FUNC_UPDATE & 0xFFFF)
		var frame: int = cur(OBJ_FRAME)
		if hdir():
			if frame >= 0x1A:
				_haridama_swim_start()
				return
			set_hdir(false)
			_haridama_turn_start(FRAMESET_692A1)
		else:
			if frame < 0x1A:
				_haridama_swim_start()
				return
			set_hdir(true)
			_haridama_turn_start(FRAMESET_692AA)
		return
	if (wGlobalCounter & 0b11) != 0:
		return
	if hdir():
		if _haridama_wall_right() == 0:
			move_object_x(1)
			return
	elif _haridama_wall_left() == 0:
		move_object_x(-1)
		return
	set_hdir(not hdir())


## .asm_4916a ($32) and .Func_49184 ($33): a pixel a frame for 60 frames, the other way at a wall.
func _haridama_flee(right: bool) -> void:
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) == 0:
		set_cur(OBJ_STATE, 0)
		return
	if right:
		if _haridama_wall_right() == 0:
			move_object_x(1)
			return
		set_cur(OBJ_STATE, 0x32)
		set_hdir(false)
	else:
		if _haridama_wall_left() == 0:
			move_object_x(-1)
			return
		set_cur(OBJ_STATE, 0x33)
		set_hdir(true)


## .Func_49199: a wall 9 px left (Func_3513, UNK4, 8 px up).
func _haridama_wall_left() -> int:
	set_hpos_from_object(-8, -9)
	return object_probe(COLLISION_UNK4) & 0x0F


## .Func_491b6: a wall 8 px right.
func _haridama_wall_right() -> int:
	set_hpos_from_object(-8, 8)
	return object_probe(COLLISION_UNK4) & 0x0F


# --- The hand (objects/hand.asm) ----------------------------------------------------------

## HandFunc: no collision with other objects, its box, 50 frames before it rises (OBJ_VAR_1 0).
func hand_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, HAND_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_BOTTOM, -12)
	set_collbox_x(-6, 5)
	set_cur(OBJ_STATE_DURATION, 50)
	set_cur(OBJ_VAR_1, 0)


## HandFunc.Update: state $2f (Wario caught) becomes $2e (holding), and Wario is put 11 px above
## its position; any other state but 0 is cleared. Then the step OBJ_VAR_1 names.
func hand_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == OBJSTATE_HAND_HOLDING + 1:
		set_cur(OBJ_STATE, OBJSTATE_HAND_HOLDING)
		_hand_hold_wario(11)
	elif state != 0 and state != OBJSTATE_HAND_HOLDING:
		set_cur(OBJ_STATE, 0)
	var step: int = cur(OBJ_VAR_1)
	if step == 9:
		_hand_wait_up()
		return
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	if step == 0 and wIsInSand != 0:
		set_cur(OBJ_STATE_DURATION, 50)  # .Func_477b2: not while Wario is in sand
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	if step == 15:  # .Invisible: hidden for 50 frames, then the first step again
		set_cur(OBJ_STATE_DURATION, 50)
		set_cur(OBJ_VAR_1, 0)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
		return
	_hand_next_step(step)


## The steps' common end: the next frameset and duration, OBJ_VAR_1 on; steps 2-7 rise 4 px
## (.Func_477f3 sets OBJ_VAR_2), 10-12 sink by OBJ_VAR_2; while holding Wario, he goes with it.
func _hand_next_step(step: int) -> void:
	if step == 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)  # SFX_081 not simulated
	set_object_frameset_ptr(HAND_FRAMESETS[step])
	var durations: Dictionary = {0: 41, 8: 56, 14: 41}
	set_cur(OBJ_STATE_DURATION, durations.get(step, 2 if step >= 9 else 1))
	set_cur(OBJ_VAR_1, step + 1)
	if step == 2:
		set_cur(OBJ_VAR_2, 4)
	if step >= 2 and step <= 7:
		set_cur_word(OBJ_Y_POS, cur_y() - cur(OBJ_VAR_2))
	elif step >= 10 and step <= 12:
		set_cur_word(OBJ_Y_POS, cur_y() + cur(OBJ_VAR_2))
	if cur(OBJ_STATE) != OBJSTATE_HAND_HOLDING:
		return
	if step == 14:  # .Func_47966: lets him go
		wAutoMoveState = 0
		set_cur(OBJ_STATE, 0)
	elif HAND_HOLD_OFFSETS.has(step):
		_hand_hold_wario(HAND_HOLD_OFFSETS[step])


## .Func_47896 (step 9): up for 56 frames; between 48 and 26 frames left it waits, without
## actions set (so it can catch him), while Wario is more than 4 px above it; holding him below
## 26, Wario 7 px above. Then it sinks 6 px (OBJ_VAR_2), Wario 9 px above if held.
func _hand_wait_up() -> void:
	var duration: int = cur(OBJ_STATE_DURATION)
	if duration < 49:
		if duration >= 26:
			if wWarioScreenYPos < byte(cur(OBJ_SCREEN_Y_POS) - 4):
				set_cur(OBJ_STATE_DURATION, duration - 1)
				return
		elif cur(OBJ_STATE) == OBJSTATE_HAND_HOLDING:
			_hand_hold_wario(7)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(HAND_FRAMESETS[9])
	set_cur(OBJ_STATE_DURATION, 2)
	set_cur(OBJ_VAR_1, 10)
	set_cur(OBJ_VAR_2, 6)
	set_cur_word(OBJ_Y_POS, cur_y() + 6)
	if cur(OBJ_STATE) == OBJSTATE_HAND_HOLDING:
		_hand_hold_wario(9)


## .ApplyOffsetToWario: Wario `above` px above the hand's position, at its x.
func _hand_hold_wario(above: int) -> void:
	wWarioYPos = word(cur_y() - above)
	wWarioXPos = cur_x()


# --- Spear Bot (objects/spear_bot.asm) ----------------------------------------------------

## The bot's parameters (SPEAR_BOT or FIRE_BOT) for the update running.
var _bot: Dictionary = SPEAR_BOT


func _bot_frameset(role: String, right: bool) -> int:
	return _bot["framesets"][role][1 if right else 0]


## SpearBotFunc: .Init on the next update.
func spear_bot_func() -> void:
	_bot = SPEAR_BOT
	set_cur_word(OBJ_UPDATE_FUNCTION, _bot["init"])


## SpearBotFunc.Init: visible, then .Default.
func spear_bot_init() -> void:
	_bot = SPEAR_BOT
	_bot_init()


func spear_bot_update() -> void:
	_bot = SPEAR_BOT
	_bot_update()


## FireBotFunc: Spear Bot's code with fire for a spear (FIRE_BOT's parameters).
func fire_bot_func() -> void:
	_bot = FIRE_BOT
	set_cur_word(OBJ_UPDATE_FUNCTION, _bot["init"])


func fire_bot_init() -> void:
	_bot = FIRE_BOT
	_bot_init()


func fire_bot_update() -> void:
	_bot = FIRE_BOT
	_bot_update()


func _bot_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, _bot["update"])
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_spear_bot_default()


## SpearBotFunc.Update's table (FireBotFunc's is the same), by OBJ_STATE (93 entries, to $5c):
## its own entries, then the shared ones. Its spear (or fire) is out in front (the box reaching
## 10 px left or 9 right) while it thrusts.
func _bot_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3D, 0x3E, 0x5C:
			_spear_bot_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(_bot_frameset("walk", hdir()))
		0x02, 0x03:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_bot_frameset("bump", hdir()))
			set_cur(OBJ_STATE_DURATION, 12)
			set_cur(OBJ_VAR_2, 2)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_01)
		0x04, 0x05, 0x28, 0x29:
			_spear_bot_knocked_start(state + 0x30)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			set_cur(OBJ_ACTION, 0x8F)
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_bot_frameset("hit", hdir()))
			set_cur(OBJ_STATE_DURATION, 4)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			_spear_bot_short_harmless()
		0x0B, 0x0C:
			enemy_stun_start(state + 0x30)
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		0x10:
			set_cur(OBJ_STATE, 0x40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		0x11:
			_spear_bot_standing_fall_start()
		0x12:
			enemy_12()
		0x13:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(_bot_frameset("turn", hdir()))
			set_cur(OBJ_STATE_DURATION, 26)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_01)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_bot_frameset("hit", hdir()))
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			_spear_bot_short_harmless()
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_bot_frameset("hit", hdir()))
			_spear_bot_short_harmless()
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, _bot_frameset("hit", false), _bot_frameset("hit", true))
		0x2D:
			_spear_bot_wind_up()
		0x2E:
			_spear_bot_thrust()
		0x31:
			_spear_bot_walk()
		0x3B, 0x3C:
			_spear_bot_stunned(state == 0x3B)
		0x3F:
			enemy_lie()
		0x40:
			enemy_get_up()
		0x41:
			_spear_bot_standing_fall()
		0x43:
			_spear_bot_turn()
		0x46:
			enemy_slide(true)
		0x47:
			enemy_slide(false)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft and _Right, no frameset of its own
		0x5A:
			_spear_bot_turn_back()
		0x5B:
			if ground_shake_wobble(_bot["div"][2]):
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("%s state %02x" % [_bot["name"], state])


## The spear in, harmless: OBJ_INTERACTION_00 with the short box.
func _spear_bot_short_harmless() -> void:
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .Func_45fbf (.Default): harmless, the short box, falling ($30), facing Wario.
func _spear_bot_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_collbox_x(-6, 5)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(_bot_frameset("walk", right))


## .Func_45ffb (OBJSTATE $11): the floor gone. With the spear out it is drawn in first (the short
## box, 14 frames' pause); then falling standing ($41).
func _spear_bot_standing_fall_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
	set_cur(OBJ_VAR_3, 0)
	if hdir():
		if cur(OBJ_COLLBOX_RIGHT) == 9:
			set_cur(OBJ_COLLBOX_RIGHT, 5)
			set_object_frameset_ptr(_bot_frameset("retract", true))
			set_cur(OBJ_STATE_DURATION, 14)
		else:
			set_object_frameset_ptr(_bot_frameset("walk", true))
			set_cur(OBJ_STATE_DURATION, 0)
	elif cur(OBJ_COLLBOX_LEFT) == 0xF6:
		set_cur(OBJ_COLLBOX_LEFT, 0xFA)
		set_object_frameset_ptr(_bot_frameset("retract", false))
		set_cur(OBJ_STATE_DURATION, 14)
	else:
		set_object_frameset_ptr(_bot_frameset("walk", false))
		set_cur(OBJ_STATE_DURATION, 0)


## .Func_46043 (OBJSTATE $41): the pause, then the walking frameset; with none left, falling.
func _spear_bot_standing_fall() -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		obj_state_standing_fall()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_object_frameset_ptr(_bot_frameset("walk", hdir()))


## .Func_461fb (OBJSTATE $31): with Wario level with it (within $18 rows) and within $40 px
## ahead, the wind-up ($2d, 20 frames); that near behind, a turn ($13); otherwise a step (6 px
## left, 5 right).
func _spear_bot_walk() -> void:
	if ground_shake_wobble(_bot["div"][4]):
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	var ignored: bool = _bot["ignores_hot_wario"] and wTransformation == TRANSFORMATION_HOT_WARIO
	if not ignored and (dy < 0x18 or dy >= 0xE8):
		var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
		if dx >= 0xC0 or dx < 0x40:
			var wario_right: bool = dx >= 0xC0
			if hdir() != wario_right:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
			set_cur(OBJ_STATE, 0x2D)
			set_object_frameset_ptr(_bot_frameset("wind_up", wario_right))
			set_cur(OBJ_STATE_DURATION, _bot["wind_up"])
			return
	enemy_step(6, 5)


## .Func_4605f (OBJSTATE $2d): the wind-up, then the thrust ($2e): the spear out in front
## (stinging), two thrusts' worth (OBJ_VAR_1).
func _spear_bot_wind_up() -> void:
	if ground_shake_wobble(_bot["div"][0]):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE, 0x2E)
	_spear_bot_spear_out()
	set_cur(OBJ_VAR_1, 2)
	set_interaction(_bot["thrust_interaction"])  # Fire Bot's SFX_073 not simulated


## The spear out the way it faces: the long box and the thrust's frameset.
func _spear_bot_spear_out() -> void:
	if hdir():
		set_collbox_x(-6, 9)
		set_object_frameset_ptr(_bot_frameset("thrust", true))
	else:
		set_collbox_x(-10, 5)
		set_object_frameset_ptr(_bot_frameset("thrust", false))


## .Func_460a6 (OBJSTATE $2e): a pixel a frame along the floor (6 px left, 5 right); no floor and
## it falls ($11). At a wall or the floor's end, with a thrust left (OBJ_VAR_1) it turns back
## ($5a, 36 frames, using one); otherwise it stops ($5b, 38 frames).
func _spear_bot_thrust() -> void:
	if ground_shake_wobble(_bot["div"][1]):
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return
	store_object_y_from_hpos()
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	var right: bool = hdir()
	var blocked: bool
	if right:
		blocked = fine_x + 5 >= 0x10 and (process_block_on_right() & 0x0F) == 0
		if not blocked:
			set_hpos_from_object(-4, 5)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(1)
				return
	else:
		blocked = fine_x < 6 and (process_block_on_left() & 0x0F) == 0
		if not blocked:
			set_hpos_from_object(-4, -6)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(-1)
				return
	if cur(OBJ_VAR_1) != 0:
		set_object_frameset_ptr(_bot_frameset("turn_back", right))
		set_cur(OBJ_STATE_DURATION, 36)
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		set_cur(OBJ_STATE, 0x5A)
		return
	set_object_frameset_ptr(_bot_frameset("stop", right))
	set_cur(OBJ_STATE_DURATION, _bot["stop"])
	set_cur(OBJ_STATE, 0x5B)


## .Func_4618c (OBJSTATE $5a): turned round with 15 frames left (the spear's box with it);
## meanwhile Func_62908; then thrusting again ($2e).
func _spear_bot_turn_back() -> void:
	if ground_shake_wobble(_bot["div"][3]):
		return
	if cur(OBJ_STATE_DURATION) == 0x0F:
		set_cur(OBJ_STATE_DURATION, 0x0E)
		set_hdir(not hdir())
		if hdir():
			set_collbox_x(-6, 9)
		else:
			set_collbox_x(-10, 5)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x2E)
	set_object_frameset_ptr(_bot_frameset("thrust", hdir()))


## .Func_46421 (OBJSTATE $43): turned round with 9 frames left; meanwhile Func_62908; then
## walking (OBJSTATE_LAND's entry).
func _spear_bot_turn() -> void:
	if ground_shake_wobble(_bot["div"][5]):
		return
	if cur(OBJ_STATE_DURATION) == 0x09:
		set_cur(OBJ_STATE_DURATION, 0x08)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x01)


## .Func_464a5/.Func_464b7 ($3b, $3c): pushed while OBJ_VAR_2 lasts (Func_62bce, Func_62ae5),
## the animation held; then stopped ($5b, 38 frames).
func _spear_bot_stunned(left: bool) -> void:
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	if cur(OBJ_VAR_2) != 0:
		if left:
			func_62bce()
		else:
			func_62ae5()
		return
	set_object_frameset_ptr(_bot_frameset("stop", not (left)))
	set_cur(OBJ_STATE_DURATION, _bot["stop"])
	set_cur(OBJ_STATE, 0x5B)


## .asm_464f9: knocked away (`state`), OBJ_SUBSTATE's low nibble cleared.
func _spear_bot_knocked_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_object_frameset_ptr(_bot_frameset("knocked", hdir()))


# --- Hammer Bot (objects/hammer_bot.asm) --------------------------------------------------

## HammerBotFunc: .Init on the next update.
func hammer_bot_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_BOT_FUNC_INIT & 0xFFFF)


## HammerBotFunc.Init: visible, then .Default.
func hammer_bot_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, HAMMER_BOT_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_hammer_bot_default()


## HammerBotFunc.Update's table, by OBJ_STATE (93 entries, to $5c). A ground shake sends it to
## the shared state $1a (Func_6303f), not to a wobble.
func hammer_bot_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3D, 0x3E, 0x5A, 0x5B, 0x5C:
			_hammer_bot_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(FRAMESET_68B17 if hdir() else FRAMESET_68B12)
		0x02, 0x03:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68B5B if hdir() else FRAMESET_68B58)
			set_cur(OBJ_STATE_DURATION, 12)
			set_cur(OBJ_VAR_2, 2)
			set_collbox_x(-8, 7)
			set_interaction(OBJ_INTERACTION_01)
		0x04, 0x05:
			if wTransformation == 0 and wram1[W_EFFECTIVE_POWER_UP] < GARLIC \
					and (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) != 0:
				set_cur(OBJ_STATE, state + 0x04)
			else:
				_hammer_bot_knocked_start(state + 0x30, 1)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			_hammer_bot_wobble_start(state + 0x30)
		0x0A:
			if cur(OBJ_ACTION) == 0 or wTransformation != 0 or wram1[W_EFFECTIVE_POWER_UP] >= SUPER_JUMP_SLAM_OVERALLS \
					or (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) == 0:
				vanish_object()  # VanishObject2
				return
			var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			_hammer_bot_wobble_start(OBJSTATE_WOBBLE_RIGHT if left_of_wario else OBJSTATE_WOBBLE_LEFT)
		0x0B, 0x0C:
			_hammer_bot_stun_start(state == 0x0B)
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		0x10:
			set_cur(OBJ_STATE, 0x40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_68B17 if hdir() else FRAMESET_68B12)
		0x12:
			enemy_12()
		0x13:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(FRAMESET_68B51 if hdir() else FRAMESET_68B4A)
			set_cur(OBJ_STATE_DURATION, 26)
			set_collbox_x(-8, 7)
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68B37 if hdir() else FRAMESET_68B2E)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_collbox_x(-8, 7)
			set_interaction(OBJ_INTERACTION_00)
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68B37 if hdir() else FRAMESET_68B2E)
			set_collbox_x(-8, 7)
			set_interaction(OBJ_INTERACTION_00)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, FRAMESET_68B2E, FRAMESET_68B37, [-8, 7])
		0x28, 0x29:
			_hammer_bot_knocked_start(state + 0x30, 2)
		0x2D:
			if _hammer_bot_shaken():
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, 0x2E)
		0x2E:
			if _hammer_bot_shaken() or not enemy_on_floor():  # SFX_107 every 16 frames not simulated
				return
			enemy_side_step(16, 15, false)
		0x31:
			_hammer_bot_walk()
		0x3B, 0x3C:
			if cur(OBJ_VAR_2) != 0:
				if state == 0x3B:
					func_62bce()
				else:
					func_62ae5()
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
		0x3F:
			enemy_lie()
		0x40:
			enemy_get_up()
		0x43:
			_hammer_bot_turn()
		0x46:
			enemy_slide(true)
		0x47:
			enemy_slide(false)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("HammerBotFunc state %02x" % state)


## The ground shake: the shared state $1a (no rDIV read).
func _hammer_bot_shaken() -> bool:
	if wGroundShakeCounter < 0x10:
		return false
	set_cur(OBJ_STATE, 0x1A)
	return true


## .Func_4434f (.Default): harmless, its box, falling ($30), facing Wario.
func _hammer_bot_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_collbox_x(-8, 7)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68B17 if right else FRAMESET_68B12)


## .Func_4448c (OBJSTATE $31): on the floor, with Wario level (within $18 rows) and within $40 px
## ahead, the hammer up ($2d, 20 frames; the box reaching 16 px that way, OBJ_INTERACTION_BOUNCY);
## otherwise a step (8 px left, 7 right). It never turns for Wario behind it. SFX_107 every 32
## frames on screen is not simulated.
func _hammer_bot_walk() -> void:
	if _hammer_bot_shaken() or not enemy_on_floor():
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	var level: bool = dy < 0x18 or dy >= 0xE8
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	if level and not hdir() and dx < 0x40:
		_hammer_bot_hammer(FRAMESET_68B1C, -16, 7)
	elif level and hdir() and dx >= 0xC0:
		_hammer_bot_hammer(FRAMESET_68B25, -8, 15)
	else:
		enemy_side_step(8, 7)


func _hammer_bot_hammer(frameset: int, left: int, right: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 20)
	set_collbox_x(left, right)
	set_interaction(OBJ_INTERACTION_BOUNCY)
	set_cur(OBJ_STATE, 0x2D)


## .Func_4472f/.Func_44739: a wobble ($38 left, $39 right).
func _hammer_bot_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68B37 if hdir() else FRAMESET_68B2E)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-8, 7)
	set_interaction(OBJ_INTERACTION_00)


## .Func_4476b/.Func_44778 (OBJSTATE_0B/0C): stunned ($3b, $3c) for 20 frames, seeing stars
## (ObjParams_StarsLeft/Right; SFX_049 not simulated).
func _hammer_bot_stun_start(left: bool) -> void:
	set_cur(OBJ_STATE, 0x3B if left else 0x3C)
	set_object_frameset_ptr(FRAMESET_68B5E if left else FRAMESET_68B61)
	set_cur(OBJ_STATE_DURATION, 20)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_PRIORITY)
	create_object_at_relative_pos(OBJ_PARAMS_STARS_LEFT if left else OBJ_PARAMS_STARS_RIGHT)


## .Func_44703 (OBJSTATE $43): turned round with 9 frames left; meanwhile Func_62908; then
## walking.
func _hammer_bot_turn() -> void:
	if _hammer_bot_shaken():
		return
	if cur(OBJ_STATE_DURATION) == 0x09:
		set_cur(OBJ_STATE_DURATION, 0x08)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x01)


## .asm_4481b: knocked away (`state`), OBJ_VAR_2 `var_2`, OBJ_SUBSTATE's low nibble cleared.
func _hammer_bot_knocked_start(state: int, var_2: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, var_2)
	set_object_frameset_ptr(FRAMESET_68B45 if hdir() else FRAMESET_68B40)


# --- Hebarii (objects/hebarii.asm) ----------------------------------------------------------

## HebariiFunc: .Init on the next update.
func hebarii_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_FUNC_INIT & 0xFFFF)


## HebariiFunc.Init: on the ceiling, crawling for 20 frames, facing Wario.
func hebarii_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 5)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -12)
	set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_FUNC_ATTACHED & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_683E4)
	set_cur(OBJ_STATE_DURATION, 20)
	set_cur(OBJ_VAR_1, 0)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))


## .AttachedUpdate: a ground shake drops it (OBJSTATE_SPECIAL_1). Attacked, it is knocked off
## (the shared knock-back as its update function); state $0a vanishes it (not ported); any other
## state is cleared and it collides again. Then it crawls (OBJ_VAR_1 0) or shoots (1).
func hebarii_attached() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_FUNC_DETACHED & 0xFFFF)
		set_object_frameset_ptr(FRAMESET_683F8)
		set_cur(OBJ_COLLBOX_RIGHT, 5)
		set_cur(OBJ_COLLBOX_LEFT, -6)
		set_cur(OBJ_COLLBOX_BOTTOM, -1)
		set_cur(OBJ_COLLBOX_TOP, -14)
		set_interaction(OBJ_INTERACTION_01)
		set_cur(OBJ_STATE, 0x2D)
		set_cur(OBJ_VAR_3, 0)
		return
	var state: int = cur(OBJ_STATE)
	if state != 0:
		match state:
			OBJSTATE_ATTACKED_LEFT_START, OBJSTATE_ATTACKED_RIGHT_START, 0x28, 0x29:
				set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_FUNC_DETACHED & 0xFFFF)
				_hebarii_knocked_start(state)
				return
			0x0A:
				vanish_object()  # VanishObject2
				return
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	if cur(OBJ_VAR_1) == 1:
		_hebarii_shoot()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_object_frameset_ptr(FRAMESET_683ED)
		set_cur(OBJ_STATE_DURATION, 41)
		set_cur(OBJ_VAR_1, 1)
		return
	_hebarii_crawl()


## .asm_4a0a3: every fourth frame a pixel along the ceiling, turning where it ends (no block 18 px up
## and 11 px left or 9 right, Func_3513) or at a wall (8 px up).
func _hebarii_crawl() -> void:
	if (wGlobalCounter & 0b11) != 0:
		return
	set_hpos_from_object(-18, 9 if hdir() else -11)
	if object_probe(COLLISION_UNK4) != 0:
		hYPos = word(cur_y() - 8)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_x(1 if hdir() else -1)
			return
	set_hdir(not hdir())


## .asm_4a0fd: with 30 frames left a projectile, if it is on screen; at the end, crawling again
## for 126 frames.
func _hebarii_shoot() -> void:
	if cur(OBJ_STATE_DURATION) == 30:
		set_cur(OBJ_STATE_DURATION, 29)
		if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
			create_object_at_relative_pos(OBJ_PARAMS_HEBARII_PROJECTILE)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 126)
	set_cur(OBJ_VAR_1, 0)
	set_object_frameset_ptr(FRAMESET_683E4)


## .DetachedUpdate's table, by OBJ_STATE (named in the disassembly). Most entries vanish it
## (VanishObject2).
func hebarii_detached() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x02, 0x08:
			_hebarii_wobble_start(OBJSTATE_WOBBLE_LEFT)
		0x03, 0x09:
			_hebarii_wobble_start(OBJSTATE_WOBBLE_RIGHT)
		OBJSTATE_ATTACKED_LEFT_START, OBJSTATE_ATTACKED_RIGHT_START, 0x28, 0x29:
			_hebarii_knocked_start(state)
		0x06, 0x07:
			set_object_frameset_ptr(FRAMESET_683FB)
			enemy_picked_up_start(state == 0x06)
		0x0F:
			_hebarii_fade_start()
		0x12:
			set_cur(OBJ_ACTION, 0x9F)
			set_cur(OBJ_STATE, 0x42)
			set_cur(OBJ_VAR_3, 0)
		0x13, OBJSTATE_WALK:
			_hebarii_lie()
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_683FB)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			carried_object_held(state, FRAMESET_683FB)
		0x2D:
			_hebarii_fall()
		0x3F:
			_hebarii_fade()
		0x46, 0x47:
			enemy_slide(state == 0x46)
		0x4C, 0x4D:
			set_cur(OBJ_STATE, state + 0x12)
			set_object_frameset_ptr(FRAMESET_68421 if state == 0x4C else FRAMESET_68418)
			full_throw_flight(state == 0x4C)  # .FullThrowLeftStart, .FullThrowRightStart
		0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x32, 0x33, 0x36, 0x37, 0x38, 0x39, 0x42, 0x44, 0x45, \
				0x4A, 0x4B, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x5E, 0x5F:
			common_enemy_state(state)
		_:
			vanish_object()  # VanishObject2


## .FallFromCeiling (OBJSTATE_SPECIAL_1): falling (FallingYVel_Light) until it lands (Func_352b),
## then lying ($31, 160 frames) and harmless; in water or sand it vanishes.
func _hebarii_fall() -> void:
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		if wIsInWaterOrSand != 0:
			vanish_object()  # VanishObject2
			return
		apply_obj_y_movement(FALLING_Y_VEL_LIGHT)
		return
	store_object_y_from_hpos()
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_object_frameset_ptr(FRAMESET_683FB)
	set_cur(OBJ_STATE_DURATION, 160)
	set_interaction(OBJ_INTERACTION_00)


## .Func_4a224 (OBJSTATE_WALK, OBJSTATE_TURN_AROUND_START): lying until the time is up, a ground
## shake wobbling it; then fading.
func _hebarii_lie() -> void:
	if ground_shake_wobble(DIV_HEBARII_WAIT):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_hebarii_fade_start()


## .State0f: fading for 35 frames ($3f), then despawned.
func _hebarii_fade_start() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE, 0x3F)
	set_object_frameset_ptr(FRAMESET_68430)
	set_cur(OBJ_STATE_DURATION, 35)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	_hebarii_fade()


## .State3f
func _hebarii_fade() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		despawn_cur_object()


## .Func_4a26d/.Func_4a277: a wobble.
func _hebarii_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_683FB)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)


## .AttackedLeftStart to .State29 (.asm_4a3af): knocked away by the shared routine, which becomes
## its update function (Func_3326, Func_3317, Func_33f8, Func_3407).
func _hebarii_knocked_start(state: int) -> void:
	var by_state: Dictionary = {OBJSTATE_ATTACKED_LEFT_START: [FRAMESET_6842A, FUNC_3326],
			OBJSTATE_ATTACKED_RIGHT_START: [FRAMESET_6842D, FUNC_3317], 0x28: [FRAMESET_6842D, FUNC_33F8],
			0x29: [FRAMESET_6842A, FUNC_3407]}
	set_object_frameset_ptr(by_state[state][0])
	set_cur_word(OBJ_UPDATE_FUNCTION, by_state[state][1])
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


## HebariiProjectileFunc: after its first 2 frames (and every 100 after), straight down with
## Wario within $18 px either side, otherwise drifting toward him.
func hebarii_projectile_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 100)
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	if dx < 0x18 or dx >= 0xE8:
		set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_PROJECTILE_FUNC_DOWN & 0xFFFF)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_PROJECTILE_FUNC_LATERAL & 0xFFFF)
	set_hdir(dx >= 0x80)


## .MoveWithLateral: half a pixel a frame toward Wario, then .MoveWithoutLateral.
func hebarii_projectile_lateral() -> void:
	if hdir():
		move_object_right_slow()
	else:
		move_object_left_slow()
	hebarii_projectile_down()


## .MoveWithoutLateral: half a pixel a frame down for 100 frames, until it hits something (its
## state set) or lands (Func_352b): then it bursts (24 frames).
func hebarii_projectile_down() -> void:
	move_object_down_slow()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0 and cur(OBJ_STATE) == 0:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0:
			return
		store_object_y_from_hpos()
	set_cur_word(OBJ_UPDATE_FUNCTION, HEBARII_PROJECTILE_FUNC_DESTROY & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_6840D)
	set_cur(OBJ_STATE_DURATION, 0x18)


## .Destroy
func hebarii_projectile_destroy() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- The owl (objects/owl.asm) ------------------------------------------------------------

## OwlFunc: no collision with other objects, its box; asleep by day, flying up at once by night
## (OBJ_INTERACTION_0B; the hoot not simulated).
func owl_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -2)
	if (wDayNight & 1) != 0:
		set_interaction(OBJ_INTERACTION_0B)
		_owl_fly_upwards_start()
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, OWL_FUNC_SLEEP & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_692E7)


## .Sleep: woken when its state is set: 40 frames waking (.WakeUp).
func owl_sleep() -> void:
	if cur(OBJ_STATE) == 0:
		return
	set_cur(OBJ_STATE, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, OWL_FUNC_WAKE_UP & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69318)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_interaction(OBJ_INTERACTION_0B)


## .WakeUp (the flaps' sound not simulated)
func owl_wake_up() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_owl_fly_upwards_start()


## .set_fly_upwards: up a pixel a frame for 54 frames.
func _owl_fly_upwards_start() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, OWL_FUNC_FLY_UPWARDS & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69335)
	set_cur(OBJ_STATE_DURATION, 54)


## .FlyUpwards: then flying toward Wario (OBJ_INTERACTION_OWL, grabbable from below) for 30
## frames.
func owl_fly_upwards() -> void:
	move_object_up()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 30)
	set_cur_word(OBJ_UPDATE_FUNCTION, OWL_FUNC_FLY & 0xFFFF)
	set_interaction(OBJ_INTERACTION_OWL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_69377 if right else FRAMESET_6936C)


## .Func_492b4: a pixel a frame, turning every 60 frames (the first leg 30); state $18 (grabbed by
## Wario) despawns it.
func owl_fly() -> void:
	if cur(OBJ_STATE) == OBJSTATE_18:
		set_cur(OBJ_FLAGS, 0)
		despawn_cur_object()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_x(1 if hdir() else -1)
		return
	set_cur(OBJ_STATE_DURATION, 60)
	set_hdir(not hdir())
	set_object_frameset_ptr(FRAMESET_69377 if hdir() else FRAMESET_6936C)


# --- Tadpoles (objects/tadpole.asm) -------------------------------------------------------

## TadpoleSpawnerFunc: invisible, no collision with other objects; spent after 180 frames once it
## has sent its tadpole.
func tadpole_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_SPAWNER_FUNC_WAIT & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_STATE_DURATION, 180)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .Func_49e4b: with Wario left of it and 40-79 px above, a tadpole (ObjParams_Tadpole).
func tadpole_spawner_wait() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_FRAME_DURATION, 2)
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		return
	var dy: int = byte(cur(OBJ_SCREEN_Y_POS) - wWarioScreenYPos)
	if dy >= 0x50 or dy < 0x28:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_SPAWNER_FUNC_SPENT & 0xFFFF)
	create_object_at_relative_pos(OBJ_PARAMS_TADPOLE)


## .Func_49e7f: then despawned after its 180 frames.
func tadpole_spawner_spent() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		despawn_cur_object()


## TadpoleFunc: hidden until on screen.
func tadpole_func() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_FUNC_HIDDEN & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)


## .Func_49eb3
func tadpole_hidden() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_FUNC_READY & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69A33)


## .Func_49ece: its params' 28 frames, then a frame crouched, then the leap (32 frames rising;
## SFX_07F not simulated).
func tadpole_ready() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(FRAMESET_69A3D)
		return
	set_object_frameset_ptr(FRAMESET_69A1A)
	set_cur(OBJ_STATE_DURATION, 0x20)
	set_cur(OBJ_VAR_1, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_FUNC_LEAP & 0xFFFF)


## .Func_49f34: hit, knocked away by the shared routine as its update function; state $0a,
## Func_3173 (Func_62e57) at once; any other state is cleared. The leap: 2 px a frame left along
## Data_60a20 rising, then Data_60a40 falling until it splashes into water (9 frames, then gone).
func tadpole_leap() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00:
			pass
		0x0B:
			set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_3407)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 1)
			return
		0x08, 0x29, 0x04:
			_tadpole_knocked(FUNC_3407)
			return
		0x09, 0x28, 0x05:
			_tadpole_knocked(FUNC_33F8)
			return
		0x0A:
			func_62e57()
			return
		_:
			set_cur(OBJ_STATE, 0)
	if cur(OBJ_VAR_1) == 0:
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_1, 1)
			set_object_frameset_ptr(FRAMESET_69A1D)
			return
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		apply_obj_y_movement(DATA_60A20)
		move_object_x(-2)
		return
	set_hpos_from_object()
	object_probe(COLLISION_UNK1)
	if wIsInWaterOrSand == 0:
		apply_obj_y_movement(DATA_60A40)
		move_object_x(-2)
		return
	set_object_frameset_ptr(FRAMESET_69A26)
	set_cur(OBJ_STATE_DURATION, 9)
	set_cur_word(OBJ_UPDATE_FUNCTION, TADPOLE_FUNC_SPLASH & 0xFFFF)


## .asm_49f1c: knocked away (the shared routine `function` as its update function).
func _tadpole_knocked(function: int) -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, function)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_ACTION, 0x81)
	set_object_frameset_ptr(FRAMESET_69A30)


## .Func_49fb5
func tadpole_splash() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Teruteru (objects/teruteru.asm) ------------------------------------------------------

## TeruteruFunc: .Init on the next update.
func teruteru_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, TERUTERU_FUNC_INIT & 0xFFFF)


## TeruteruFunc.Init: shown unless Wario is blind; 8 hits in OBJ_SUBSTATE's low nibble; then
## .Default.
func teruteru_init() -> void:
	if wTransformation != TRANSFORMATION_BLIND:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, TERUTERU_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, ((cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) & 0xF0) | 8)
	_teruteru_default()


## TeruteruFunc.Update: hidden while Wario is blind; then its table, by OBJ_STATE (93 entries).
func teruteru_update() -> void:
	if wTransformation == TRANSFORMATION_BLIND:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0B, 0x0C, 0x0D, 0x11, 0x13, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x43, 0x5C:
			_teruteru_default()
		0x01:
			_teruteru_fly_start()
		0x02, 0x08:
			_teruteru_wobble_start(OBJSTATE_WOBBLE_LEFT)
		0x03, 0x09:
			_teruteru_wobble_start(OBJSTATE_WOBBLE_RIGHT)
		0x04, 0x05, 0x28, 0x29:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
			set_object_frameset_ptr(FRAMESET_68BA2)
			set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x0A:
			vanish_object()  # VanishObject2
		0x0E:
			set_cur(OBJ_STATE, 0x5B)
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 8)
			enemy_lie()
		0x10:
			set_cur(OBJ_STATE, 0x40)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_68B99)
			set_cur(OBJ_STATE_DURATION, 80)
			_teruteru_harmless_box()
			_teruteru_rise()
		0x12:
			enemy_12()
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68BA5)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			_teruteru_hit_box()
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			if not _teruteru_count_hit():
				return
			set_object_frameset_ptr(FRAMESET_68BA5)
			set_interaction(OBJ_INTERACTION_00)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			held_turning(state, _teruteru_grab)
		0x2D:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, 0x2E)
				set_object_frameset_ptr(FRAMESET_68B8B)
				set_cur(OBJ_STATE_DURATION, 40)
				set_interaction(OBJ_INTERACTION_TERUTERU)
		0x2E:
			_teruteru_dive()
		0x2F:
			if cur(OBJ_STATE_DURATION) == 0x3C:
				set_object_frameset_ptr(FRAMESET_68B90)
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				move_object_up()
				return
			_teruteru_fly_on()
		0x31:
			_teruteru_fly()
		0x3F:
			enemy_lie()
		0x40:
			_teruteru_rise()
		0x46, 0x47:
			enemy_slide(state == 0x46)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x5A:
			_teruteru_turn()
		0x5B:
			_teruteru_on_wario()
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("TeruteruFunc state %02x" % state)


## .Func_44cd0 and .Func_44cff's grab: its frameset, a box top of -7 and bottom of -1, grabbed, and
## its substate's routine bits 8.
func _teruteru_grab(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68BA5)
	set_cur(OBJ_COLLBOX_TOP, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 0x08)


## .Func_44a72 (.Default): its flying box, facing Wario, then flying (.Func_44a97).
func _teruteru_default() -> void:
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -15)
	set_cur(OBJ_COLLBOX_TOP, -20)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))
	_teruteru_fly_start()


## .Func_44a97: flying ($31), $32 px of its 100 px beat.
func _teruteru_fly_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68B6D if hdir() else FRAMESET_68B64)
	set_cur(OBJ_VAR_1, 0x32)
	_teruteru_harmless_box()


## Harmless, its flying box's height.
func _teruteru_harmless_box() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_COLLBOX_TOP, -20)
	set_cur(OBJ_COLLBOX_BOTTOM, -15)


## Harmless, the box when hit.
func _teruteru_hit_box() -> void:
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_COLLBOX_TOP, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)


## .Func_44ac1 (OBJSTATE $31): with Wario 24-127 px below and within $18 px across (and not
## blind), a dive ($2d, 20 frames); otherwise bobbing (Data_604c0) back and forth a pixel a frame
## over 100 px (OBJ_VAR_1), turning at each end ($5a, 26 frames).
func _teruteru_fly() -> void:
	if wTransformation != TRANSFORMATION_BLIND:
		var dy: int = byte(byte(wWarioScreenYPos + 0x2A) - byte(cur(OBJ_SCREEN_Y_POS) + 0x2A))
		if dy >= 0x18 and dy < 0x80:
			var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
			if dx >= 0xE8 or dx < 0x18:
				set_cur(OBJ_STATE, 0x2D)
				set_object_frameset_ptr(FRAMESET_68B84)
				set_cur(OBJ_STATE_DURATION, 20)
				return
	apply_obj_y_movement_loop(DATA_604C0)
	if hdir():
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)
		if cur(OBJ_VAR_1) != 0x64:
			move_object_x(1)
			return
		set_object_frameset_ptr(FRAMESET_68B7D)
	else:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) != 0:
			move_object_x(-1)
			return
		set_object_frameset_ptr(FRAMESET_68B76)
	set_cur(OBJ_STATE_DURATION, 26)
	set_cur(OBJ_STATE, 0x5A)


## .Func_44b2d (OBJSTATE $5a): bobbing, turned round with 9 frames left; then flying on.
func _teruteru_turn() -> void:
	apply_obj_y_movement_loop(DATA_604C0)
	if cur(OBJ_STATE_DURATION) == 0x09:
		set_cur(OBJ_STATE_DURATION, 0x08)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_teruteru_fly_on()


## .asm_44b4c: flying ($31) the way it faces.
func _teruteru_fly_on() -> void:
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_object_frameset_ptr(FRAMESET_68B6D if hdir() else FRAMESET_68B64)


## .Func_44a25 (OBJSTATE $2e): 40 frames diving 2 px a frame, a pixel toward Wario across, able
## to blind him (OBJ_INTERACTION_TERUTERU); then rising ($2f) a pixel a frame for 80, harmless.
func _teruteru_dive() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, 0x2F)
		set_object_frameset_ptr(FRAMESET_68BAE)
		set_cur(OBJ_STATE_DURATION, 80)
		set_interaction(OBJ_INTERACTION_01)
		return
	var obj_x: int = byte(cur(OBJ_SCREEN_X_POS) + 0x2A)
	var wario_x: int = byte(wWarioScreenXPos + 0x2A)
	if obj_x > wario_x:
		move_object_x(-1)
	elif obj_x < wario_x:
		move_object_x(1)
	set_cur_word(OBJ_Y_POS, cur_y() + 2)


## .Func_44c32 (OBJSTATE $40): rising a pixel a frame; then .Default.
func _teruteru_rise() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up()
		return
	set_cur(OBJ_STATE, 0)


## .Func_449d7 (OBJSTATE $5b): on Wario's head while he is blind (12 px above him); then a wobble
## off the way he faces.
func _teruteru_on_wario() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	if wTransformation == TRANSFORMATION_BLIND:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
		set_cur_word(OBJ_Y_POS, word(wWarioYPos - 0x0C))
		set_cur_word(OBJ_X_POS, wWarioXPos)
		return
	_teruteru_wobble_start(OBJSTATE_WOBBLE_LEFT if wDirection == DIRECTION_LEFT else OBJSTATE_WOBBLE_RIGHT)


## .Func_44c3f/.Func_44c49: a wobble.
func _teruteru_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68BA5)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	_teruteru_hit_box()


## DecrementRemainingBossHits, then at the last hit VanishObject2: false then.
func _teruteru_count_hit() -> bool:
	if (cur(OBJ_SUBSTATE) & 0x0F) != 1:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) - 1)
	if (cur(OBJ_SUBSTATE) & 0x0F) == 1:
		vanish_object()  # VanishObject2
		return false
	return true


# --- The zombie (objects/zombie.asm) ------------------------------------------------------

## ZombieFunc: hidden underground, no collision with other objects, its box.
func zombie_func() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_INIT & 0xFFFF)
	set_collbox_x(-4, 3)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, 0)


## ZombieFunc.Init: facing Wario (its frame set directly).
func zombie_init() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_UNDERGROUND & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_FRAME, 0x18 if right else 0x17)


## .OnUnderground: a pixel a frame under the floor (turning where it ends, 4 px left or 3 right,
## or at a wall); with no floor it is gone. After its wait (OBJ_STATE_DURATION), with Wario level
## and 32-63 px away either side, it rises (20 frames).
func zombie_underground() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_FRAME_DURATION, 2)
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if fine_x + 3 >= 16 and (process_block_on_right() & 0x0F) == 0:
			set_hdir(false)
			return
		set_hpos_from_object(-4, 3)
		if object_probe(COLLISION_UNK4) != 0:
			set_hdir(false)
			return
		move_object_x(1)
	else:
		if fine_x < 4 and (process_block_on_left() & 0x0F) == 0:
			set_hdir(true)
			return
		set_hpos_from_object(-4, -4)
		if object_probe(COLLISION_UNK4) != 0:
			set_hdir(true)
			return
		move_object_x(-1)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy >= 24 and dy < 0xE8:
		return
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	if dx >= 0xE0 or dx < 32:
		return
	if dx < 0xC0 and dx >= 64:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_START_RISE & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 20)


## .StartRise: then out of the ground facing Wario, shown and colliding (SFX_074 not simulated).
func zombie_start_rise() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_68D9C if right else FRAMESET_68D93)
	set_cur(OBJ_STATE_DURATION, 20)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~(OBJFLAG_INVISIBLE | OBJFLAG_NO_COLLISION))
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_RISING & 0xFFFF)


## .Rising: its box grows (-12, -18, -24) over 20 frames; Zombie Wario cannot touch it meanwhile.
## Then walking on the surface.
func zombie_rising() -> void:
	if wTransformation == TRANSFORMATION_ZOMBIE_WARIO:
		set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	match cur(OBJ_STATE_DURATION):
		12:
			set_cur(OBJ_COLLBOX_TOP, -12)
		6:
			set_cur(OBJ_COLLBOX_TOP, -18)
		0:
			set_cur(OBJ_COLLBOX_TOP, -24)
			set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_ON_SURFACE & 0xFFFF)
			set_cur(OBJ_STATE, 0)
			_zombie_walk_start()


## .asm_45cca: walking (substate 1).
func _zombie_walk_start() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 1)
	set_object_frameset_ptr(FRAMESET_68D8A if hdir() else FRAMESET_68D81)


## .OnSurface: hit (any state), knocked away by the shared routine as its update function (Zombie
## Wario only by state $0a; otherwise $0a is Func_3173). Then by its substate's low nibble:
## walking (0, 1), turning (2), throwing its head (3).
func zombie_on_surface() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if wTransformation == TRANSFORMATION_ZOMBIE_WARIO and state != 0x0A:
			set_cur(OBJ_STATE, 0)
		elif wTransformation != TRANSFORMATION_ZOMBIE_WARIO and state == 0x0A:
			func_62e57()
			return
		else:
			set_object_frameset_ptr(FRAMESET_68D1F if (cur(OBJ_SUBSTATE) & 0x0F) == 3 else FRAMESET_68D1A)
			zombie_knocked()
			return
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_zombie_walk()
		2:
			_zombie_turn()
		3:
			_zombie_throw_head()
		_:
			note_unported("ZombieFunc.OnSurface substate %d" % (cur(OBJ_SUBSTATE) & 0x0F))


## .asm_45c83: knocked away from Wario by Func_3407 or Func_33f8 as its update function (the head
## too; SFX_017 not simulated).
func zombie_knocked() -> void:
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_33F8 if left_of_wario else FUNC_3407)


## .Func_45ce2: with Wario level (within 32 rows) and within 48 px ahead, the head throw
## (substate 3, 50 frames; SFX_064 not simulated); that near behind, a turn; otherwise 2 px a
## frame along the floor (4 px left, 3 right), turning at its end or a wall. No floor: headless.
func _zombie_walk() -> void:
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy < 32 or dy >= 0xE0:
		var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
		if dx >= 0xD0 or dx < 48:
			var wario_right: bool = dx >= 0xD0
			if hdir() != wario_right:
				_zombie_turn_start(FRAMESET_68D2B if hdir() else FRAMESET_68D24)
				return
			set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 3)
			set_object_frameset_ptr(FRAMESET_68DAC if wario_right else FRAMESET_68DA5)
			set_cur(OBJ_STATE_DURATION, 50)
			return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE_DURATION, 0x30)
		set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_HEADLESS & 0xFFFF)
		return
	store_object_y_from_hpos()
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if not (fine_x + 3 >= 16 and (process_block_on_right() & 0x0F) == 0):
			set_hpos_from_object(-4, 3)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(2)
				return
		_zombie_turn_start(FRAMESET_68D2B)
	else:
		if not (fine_x < 4 and (process_block_on_left() & 0x0F) == 0):
			set_hpos_from_object(-4, -4)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(-2)
				return
		_zombie_turn_start(FRAMESET_68D24)


## .asm_45dcc: turning (substate 2, 32 frames).
func _zombie_turn_start(frameset: int) -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 2)
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 32)


## .Func_45ddc: turned round with 20 frames left; meanwhile Func_62908; then walking.
func _zombie_turn() -> void:
	if cur(OBJ_STATE_DURATION) == 20:
		set_cur(OBJ_STATE_DURATION, 19)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	_zombie_walk_start()


## .ThrowHead: with 16 frames left its head flies (ObjParams_ZombieHeadLeft/Right); at the end,
## headless for 48 frames, no collision with other objects.
func _zombie_throw_head() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 16:
		create_object_at_relative_pos(OBJ_PARAMS_ZOMBIE_HEAD_RIGHT if hdir() else OBJ_PARAMS_ZOMBIE_HEAD_LEFT)
		return
	if left != 0:
		return
	set_cur(OBJ_STATE_DURATION, 48)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_HEADLESS & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .Headless: flickering (every other frame); then back underground for 100 frames, hidden.
func zombie_headless() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		if (wGlobalCounter & 1) == 0:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) ^ OBJFLAG_INVISIBLE)
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_STATE_DURATION, 100)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_FUNC_UNDERGROUND & 0xFFFF)


## ZombieHeadFunc_Left/_Right: its params' 48 frames out, then turned back (once); off screen once
## that has run out, gone. Flying along Data_605a0 (left) or Data_60560 (right), ZombieHeadFunc.
func zombie_head_func_left() -> void:
	_zombie_head(FRAMESET_68DDA, DATA_605A0)


func zombie_head_func_right() -> void:
	_zombie_head(FRAMESET_68DD5, DATA_60560)


func _zombie_head(back_frameset: int, table: int) -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
			set_cur(OBJ_FLAGS, 0)
			return
	else:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_hdir(not hdir())
			set_object_frameset_ptr(back_frameset)
	_zombie_head_fly(table)


## ZombieHeadFunc: hit by a state from $0b to $0e it flickers away (40 frames); by any other,
## knocked away as the zombie is.
func _zombie_head_fly(table: int) -> void:
	apply_obj_x_movement(table)
	var state: int = cur(OBJ_STATE)
	if state == 0:
		return
	if state < 0x0B or state >= 0x0F:
		zombie_knocked()
		return
	set_object_frameset_ptr(FRAMESET_68DDA if hdir() else FRAMESET_68DD5)
	set_cur(OBJ_STATE_DURATION, 40)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZOMBIE_HEAD_FUNC_FLICKER & 0xFFFF)


## ZombieHeadFunc.Flicker: then gone.
func zombie_head_flicker() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	if (wGlobalCounter & 1) == 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) ^ OBJFLAG_INVISIBLE)


# --- The Doughnuteer and its doughnuts (objects/doughnuteer.asm) --------------------------

## DoughnuteerFunc: .Init on the next update.
func doughnuteer_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, DOUGHNUTEER_FUNC_INIT & 0xFFFF)


## DoughnuteerFunc.Init: visible, then .Default.
func doughnuteer_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, DOUGHNUTEER_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_doughnuteer_default()


## DoughnuteerFunc.Update's table, by OBJ_STATE (93 entries, to $5c). A ground shake sends it to
## the shared $1a or $1c (no rDIV read). It throws doughnuts ($5a), then walks off a pixel a
## frame ($5b) to a wall, and pauses ($2c, $5c).
func doughnuteer_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0B, 0x0C, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2D, 0x2E, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E:
			_doughnuteer_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(FRAMESET_6856B if hdir() else FRAMESET_68562)
		0x02, 0x03:
			_doughnuteer_bump_start(state == 0x03)
		0x04, 0x05, 0x28, 0x29:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
			set_object_frameset_ptr(FRAMESET_685BB if hdir() else FRAMESET_685B2)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			set_cur(OBJ_ACTION, 0x8F)
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_685BB if hdir() else FRAMESET_685B2)
			set_cur(OBJ_STATE_DURATION, 4)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		0x0A:
			vanish_object()  # VanishObject2
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		0x10:
			set_cur(OBJ_STATE, 0x40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_6856B if hdir() else FRAMESET_68562)
		0x12:
			enemy_12()
		0x13:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(FRAMESET_685F7 if hdir() else FRAMESET_685F0)
			set_cur(OBJ_STATE_DURATION, 0x1A)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_685BB if hdir() else FRAMESET_685B2)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_685BB if hdir() else FRAMESET_685B2)
			set_interaction(OBJ_INTERACTION_00)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, FRAMESET_685B2, FRAMESET_685BB, [])
		0x2B:
			_doughnuteer_turn(0x5B, -1)
		0x2C:
			_doughnuteer_turn(0x5C, 0x37)
		0x31:
			_doughnuteer_walk()
		0x32, 0x33:
			_doughnuteer_bumped(state == 0x33)
		0x3F:
			enemy_lie()
		0x40:
			enemy_get_up()
		0x43:
			if _doughnuteer_shaken(0x1A):
				return
			if cur(OBJ_STATE_DURATION) == 0x08:
				set_cur(OBJ_STATE_DURATION, 0x07)
				set_hdir(not hdir())
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				func_62908()
				return
			set_cur(OBJ_STATE, 0x01)
		0x46, 0x47:
			enemy_slide(state == 0x46)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x5A:
			_doughnuteer_throw()
		0x5B:
			_doughnuteer_walk_off()
		0x5C:
			if _doughnuteer_shaken(0x1C):
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				func_62908()
				return
			set_cur(OBJ_STATE, 0x01)
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("DoughnuteerFunc state %02x" % state)


## The ground shake: the shared state `state` ($1a or $1c).
func _doughnuteer_shaken(state: int) -> bool:
	if wGroundShakeCounter < 0x10:
		return false
	set_cur(OBJ_STATE, state)
	return true


## .Func_41cdb (.Default): harmless, its box, falling ($30), facing Wario.
func _doughnuteer_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_COLLBOX_RIGHT, 5)
	set_cur(OBJ_COLLBOX_LEFT, -6)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_6856B if right else FRAMESET_68562)


## .Func_41d56 (OBJSTATE $31): with Wario level (within $20 rows) and within $40 px ahead, a
## throw ($5a, 51 frames); that near behind, a turn; otherwise a step (6 px left, 5 right).
func _doughnuteer_walk() -> void:
	if _doughnuteer_shaken(0x1A):
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy < 0x20 or dy >= 0xE0:
		var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
		if dx >= 0xC0 or dx < 0x40:
			var wario_right: bool = dx >= 0xC0
			if hdir() != wario_right:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
			set_cur(OBJ_STATE, 0x5A)
			set_object_frameset_ptr(FRAMESET_68597 if wario_right else FRAMESET_68586)
			set_cur(OBJ_STATE_DURATION, 0x33)
			return
	enemy_step(6, 5)


## .Func_41b58 (OBJSTATE $5a): with $1a frames left a doughnut (ObjParams_DoughnutLeft/Right;
## SFX_067 not simulated); meanwhile Func_62908; then turning ($2b, $1a frames).
func _doughnuteer_throw() -> void:
	if _doughnuteer_shaken(0x1A):
		return
	if cur(OBJ_STATE_DURATION) == 0x1A:
		set_cur(OBJ_STATE_DURATION, 0x19)
		create_object_at_relative_pos(OBJ_PARAMS_DOUGHNUT_RIGHT if hdir() else OBJ_PARAMS_DOUGHNUT_LEFT)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x2B)
	set_object_frameset_ptr(FRAMESET_68605 if hdir() else FRAMESET_685FE)
	set_cur(OBJ_STATE_DURATION, 0x1A)


## .Func_41bae ($2b, then walking off: $5b) and .Func_41c8b ($2c, then pausing: $5c for $37):
## turned round with 8 frames left; meanwhile Func_62908. `duration` -1 keeps the count.
func _doughnuteer_turn(next: int, duration: int) -> void:
	if cur(OBJ_STATE_DURATION) == 0x08:
		set_cur(OBJ_STATE_DURATION, 0x07)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, next)
	if next == 0x5B:
		set_object_frameset_ptr(FRAMESET_6857D if hdir() else FRAMESET_68574)
	else:
		set_object_frameset_ptr(FRAMESET_685D7 if hdir() else FRAMESET_685C4)
		set_cur(OBJ_STATE_DURATION, duration)


## .Func_41bdc (OBJSTATE $5b): a pixel a frame along the floor (6 px left, 5 right) to a wall or
## the floor's end, then turning ($2c, $1a frames).
func _doughnuteer_walk_off() -> void:
	if _doughnuteer_shaken(0x1C) or not enemy_on_floor():
		return
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if not (fine_x + 5 >= 0x10 and (process_block_on_right() & 0x0F) == 0):
			set_hpos_from_object(-4, 5)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(1)
				return
		set_object_frameset_ptr(FRAMESET_68605)
	else:
		if not (fine_x < 6 and (process_block_on_left() & 0x0F) == 0):
			set_hpos_from_object(-4, -6)
			if object_probe(COLLISION_UNK4) == 0:
				move_object_x(-1)
				return
		set_object_frameset_ptr(FRAMESET_685FE)
	set_cur(OBJ_STATE, 0x2C)
	set_cur(OBJ_STATE_DURATION, 0x1A)


## .Func_41e3a/.Func_41e7c (OBJSTATE_02/03): bumped ($32, $33); at the frames from $24 on or below
## 6 it tosses a doughnut up (ObjParams_DoughnutUpLeft/Right).
func _doughnuteer_bump_start(right: bool) -> void:
	var frame: int = cur(OBJ_FRAME)
	if frame >= 0x24 or frame < 0x06:
		create_object_at_relative_pos(OBJ_PARAMS_DOUGHNUT_UP_RIGHT if right else OBJ_PARAMS_DOUGHNUT_UP_LEFT)
	set_cur(OBJ_STATE, 0x33 if right else 0x32)
	set_object_frameset_ptr(FRAMESET_685AD if hdir() else FRAMESET_685A8)
	set_cur(OBJ_STATE_DURATION, 0x0C)
	set_cur(OBJ_VAR_2, 2)


## .Func_41e53/.Func_41eae ($32, $33): the shared bump while OBJ_VAR_2 lasts; then, when its time
## is up, turning to throw again ($2b) if it faces the way it was bumped, otherwise walking off
## ($5b).
func _doughnuteer_bumped(right: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		if right:
			obj_state_bump_right()
		else:
			obj_state_bump_left()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	if hdir() == right:
		set_cur(OBJ_STATE, 0x2B)
		set_object_frameset_ptr(FRAMESET_68605 if right else FRAMESET_685FE)
		set_cur(OBJ_STATE_DURATION, 0x1A)
	else:
		set_cur(OBJ_STATE, 0x5B)
		set_object_frameset_ptr(FRAMESET_6857D if hdir() else FRAMESET_68574)


## DoughnutFunc_Left/_Right: 2 px a frame along an arc (Data_60510), no collision with other
## objects; state $18 (eaten) destroys it, $19 (hit) sends it flying (DoughnutFunc).
func doughnut_func_left() -> void:
	move_object_x(-2)
	_doughnut_thrown()


func doughnut_func_right() -> void:
	move_object_x(2)
	_doughnut_thrown()


func _doughnut_thrown() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if _doughnut_struck():
		return
	apply_obj_y_movement(DATA_60510)


## DoughnutFunc_Up: tossed up (Data_60540), no actions for 15 frames.
func doughnut_func_up() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, DOUGHNUT_FUNC_UP_UPDATE & 0xFFFF)
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	doughnut_up_update()


## DoughnutFunc_Up.Update
func doughnut_up_update() -> void:
	if _doughnut_struck():
		return
	apply_obj_y_movement(DATA_60540)


## DoughnutFunc_Destroy for $18; DoughnutFunc for $19: away from Wario a pixel a frame, falling
## (Data_60040).
func _doughnut_struck() -> bool:
	var state: int = cur(OBJ_STATE)
	if state == 0x18:
		set_cur(OBJ_FLAGS, 0)
		return true
	if state != 0x19:
		return false
	var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_cur_word(OBJ_UPDATE_FUNCTION, (DOUGHNUT_FUNC_UPDATE_LEFT if left_of_wario else DOUGHNUT_FUNC_UPDATE_RIGHT) & 0xFFFF)
	set_cur(OBJ_VAR_3, 0)
	return true


## DoughnutFunc.Update_Left/_Right
func doughnut_update_left() -> void:
	move_object_x(-1)
	_doughnut_fall()


func doughnut_update_right() -> void:
	move_object_x(1)
	_doughnut_fall()


func _doughnut_fall() -> void:
	set_cur(OBJ_ACTION, 0x81)
	apply_obj_y_movement(DATA_60040)


# --- Pneumo (objects/pneumo.asm) ----------------------------------------------------------

## PneumoFunc: visible, hovering; its box.
func pneumo_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, PNEUMO_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68C5C)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_COLLBOX_RIGHT, 7)
	set_cur(OBJ_COLLBOX_LEFT, -8)
	set_cur(OBJ_COLLBOX_BOTTOM, 2)


## PneumoFunc.Update: hit from below ($0e), or touched (1-3) unless hovering untouched, it is
## stunned; $0a is Func_3173; other states knock it away by the shared routines as its update
## function. Then its substate's low nibble picks what it does.
func pneumo_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_pneumo_substate()
		return
	if state == 0x0E:
		set_cur(OBJ_STATE, 0)
		_pneumo_stunned_start()
		return
	if state == 0x0A:
		func_62e57()
		return
	if state < 0x04:
		set_cur(OBJ_STATE, 0)
		if wTransformation == TRANSFORMATION_PUFFY_WARIO or (cur(OBJ_SUBSTATE) & 0x0F) == 1:
			_pneumo_stunned_start()
			return
		_pneumo_substate()
		return
	var function: int
	match state:
		0x28:
			function = FUNC_33F8
		0x29:
			function = FUNC_3407
		0x04:
			function = FUNC_3326
		0x05:
			function = FUNC_3317
		_:
			function = FUNC_3407 if (state & 1) == 0 else FUNC_33F8
	set_cur_word(OBJ_UPDATE_FUNCTION, function)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_object_frameset_ptr(FRAMESET_68C89)
	set_cur(OBJ_ACTION, 0x81)


func _pneumo_substate() -> void:
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_pneumo_hover()
		2:
			_pneumo_stunned()
		3:
			_pneumo_dive()
		4:
			_pneumo_rise()
		5:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				_pneumo_side_move()
			else:
				_pneumo_hover_start()
		6:
			_pneumo_rise_to_wario()
		_:
			note_unported("PneumoFunc substate %d (past its table)" % (cur(OBJ_SUBSTATE) & 0x0F))


## .Func_456fe: hovering (substate 1), its bob from the start.
func _pneumo_hover_start() -> void:
	set_object_frameset_ptr(FRAMESET_68C5C)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 1)
	set_cur(OBJ_VAR_3, 0)


## .Func_4570f: every 64 frames with Wario not above it and near the screen's top, rising to him
## (substate 6); otherwise bobbing (Data_44000), and at the bob's end, with Wario 20-79 px below
## and 16-95 px across, a dive at him (substate 3).
func _pneumo_hover() -> void:
	var wario_y: int = byte(wWarioScreenYPos + 0x2A)
	if wario_y >= byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) and wario_y < 0x61 \
			and wTransformation != TRANSFORMATION_PUFFY_WARIO and (wGlobalCounter & 0x3F) == 0:
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 6)
		return
	var step: int = pneumo_bob[cur(OBJ_VAR_3) & 0xFF] if (cur(OBJ_VAR_3) & 0xFF) < pneumo_bob.size() else 0x80
	if step == 0x80:
		if _pneumo_dive_start():
			return
		set_cur(OBJ_VAR_3, 0)
		step = pneumo_bob[0]
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) + 1)
	add_y_signed(step)


## The bob's end (.asm_4573f): the dive at Wario, OBJ_VAR_2 its speed (0 within 16 px across).
func _pneumo_dive_start() -> bool:
	if wTransformation == TRANSFORMATION_PUFFY_WARIO:
		return false
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy < 0xB0 or dy >= 0xEC:
		return false
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	var speed: int
	if dx < 0x60:
		speed = 1 if dx >= 0x10 else 0
		set_hdir(false)
		set_object_frameset_ptr(FRAMESET_68C7F)
	elif dx < 0xA0:
		return false
	else:
		speed = 1 if dx < 0xF0 else 0
		set_hdir(true)
		set_object_frameset_ptr(FRAMESET_68C84)
	set_cur(OBJ_VAR_2, speed)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 3)
	set_cur(OBJ_STATE_DURATION, 1)
	return true


## .Func_457bd (substate 3): down 2 px a frame (counted in OBJ_VAR_1) and across, until it meets
## a floor (wc1ca), water, or Wario's level; then rising (substate 4, 255 frames).
func _pneumo_dive() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	wc1ca = 0
	set_hpos_from_object()
	var stop: bool
	if object_probe(COLLISION_UNK1) != 0:
		stop = wc1ca == 0
	else:
		stop = wIsInWaterOrSand != 0
	if not stop:
		var dy: int = byte(byte(wWarioScreenYPos + 0x2A) - byte(cur(OBJ_SCREEN_Y_POS) + 0x2A))
		stop = dy < 0x14 or dy >= 0x80
	if stop:
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 4)
		set_cur(OBJ_STATE_DURATION, 255)
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)
	set_cur_word(OBJ_Y_POS, cur_y() + 2)
	_pneumo_side_move()


## .asm_4581d: across by OBJ_VAR_2, turning at a wall (8 px left, 7 right, 4 up).
func _pneumo_side_move() -> void:
	if hdir():
		set_hpos_from_object(-4, 7)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_right_by_var2()
			return
	else:
		set_hpos_from_object(-4, -8)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_left_by_var2()
			return
	set_hdir(not hdir())


## .Func_4585c (substate 4): back up 2 px a frame as far as it dived, unless a ceiling (16 px up,
## Func_358b) stops it, moving across; then hovering.
func _pneumo_rise() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_pneumo_hover_start()
		return
	set_hpos_from_object(-16, 0)
	if object_probe(COLLISION_UNK3) == 0:
		if cur(OBJ_VAR_1) == 0:
			_pneumo_hover_start()
			return
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		set_cur_word(OBJ_Y_POS, cur_y() - 2)
	_pneumo_side_move()


## .Func_4589d: stunned (substate 2, 27 frames), turned away from Wario.
func _pneumo_stunned_start() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 2)
	set_hdir(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A))
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68C8E)
	set_cur(OBJ_STATE_DURATION, 27)


## .Func_458c7 (substate 2): falling (Data_60600) unless a ceiling is 16 px up (Func_358b), 2 px a
## frame across, turning at a wall; then hovering.
func _pneumo_stunned() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_VAR_1, 0)
		_pneumo_hover_start()
		return
	set_hpos_from_object(-16, 0)
	if object_probe(COLLISION_UNK3) == 0:
		apply_obj_y_movement(DATA_60600)
	if hdir():
		set_hpos_from_object(-4, 7)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_x(2)
		else:
			set_hdir(false)
	else:
		set_hpos_from_object(-4, -8)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_x(-2)
		else:
			set_hdir(true)


## .Func_45934 (substate 6): to Wario's Y (to 4 px) plus hXPosLoBackup's address ($ffb0: 80 px
## above him): up a pixel a frame (a ceiling stuns it), down a pixel (half on a floor, wc1ca);
## there, or in water or on solid ground, hovering.
func _pneumo_rise_to_wario() -> void:
	if wTransformation == TRANSFORMATION_PUFFY_WARIO:
		_pneumo_hover_start()
		return
	var target: int = word((wWarioYPos & 0xFFFC) + H_X_POS_LO_BACKUP)
	var y: int = cur_y()
	var obj_hi: int = y >> 8
	var obj_lo: int = (y & 0xFF) & 0xFC
	var up: bool
	if obj_hi == target >> 8:
		if obj_lo == (target & 0xFF):
			_pneumo_hover_start()
			return
		up = obj_lo > (target & 0xFF)
	else:
		up = obj_hi > target >> 8
	if up:
		set_hpos_from_object(-16, 0)
		if object_probe(COLLISION_UNK3) != 0:
			_pneumo_stunned_start()
			return
		move_object_up()
		return
	wc1ca = 0
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) != 0:
		if wc1ca != 0:
			move_object_down_slow()
		else:
			_pneumo_hover_start()
		return
	if wIsInWaterOrSand == 0:
		move_object_down()
	else:
		_pneumo_hover_start()


# --- Omodonmeka (objects/omodonmeka.asm) --------------------------------------------------

## OmodonmekaFunc: its box; its home height kept in OBJ_VAR_1 and OBJ_VAR_2; then hovering.
func omodonmeka_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, OMODONMEKA_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, -3)
	set_cur(OBJ_COLLBOX_LEFT, -13)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	set_cur(OBJ_VAR_1, cur(OBJ_Y_POS))
	set_cur(OBJ_VAR_2, cur(OBJ_Y_POS + 1))
	_omodonmeka_hover_start()


## .Func_42432: hovering (substate 1), able to pick Wario up (OBJ_INTERACTION_OMODONMEKA).
func _omodonmeka_hover_start() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 1)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68F0B)
	set_interaction(OBJ_INTERACTION_OMODONMEKA)


## .Func_42218: it has caught Wario ($2a, OBJACTION_0C); attacked, knocked away by the shared
## routines as its update function ($3a); $0a is Func_3173; any other state sends it flying off
## (substate 4; its home's high byte is cleared with it, as the original does). Then its substate.
func omodonmeka_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		match state:
			OBJSTATE_ACTIVATE:
				_omodonmeka_catch()
				return
			0x04, 0x05, 0x28, 0x29:
				_omodonmeka_knocked({0x04: FUNC_3326, 0x05: FUNC_3317, 0x28: FUNC_33F8, 0x29: FUNC_3407}[state])
				return
			0x0A:
				func_62e57()
				return
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 4)
		set_cur(OBJ_VAR_3, 0)
		set_cur(OBJ_VAR_2, 0)
		set_object_frameset_ptr(FRAMESET_68F34)
	_omodonmeka_substate()


func _omodonmeka_substate() -> void:
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_omodonmeka_hover()
		2:
			_omodonmeka_drop()
		3:
			_omodonmeka_return()
		4:
			_omodonmeka_fly_off()
		5:
			_omodonmeka_lift()
		6:
			_omodonmeka_hold()
		7:
			_omodonmeka_hold_flat()
		8:
			_omodonmeka_alert()
		_:
			note_unported("OmodonmekaFunc substate %d (past its table)" % (cur(OBJ_SUBSTATE) & 0x0F))


## .asm_421ec and the others: knocked away by `function` as its update function ($3a).
func _omodonmeka_knocked(function: int) -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, function)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_object_frameset_ptr(FRAMESET_68F3D)
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE, 0x3A)


## .Func_42199 (state $2a): Wario caught: held 26 px below it (Flat Wario 7, for 24 frames), its x
## 8 px ahead of him: lifting (substate 5) or holding him flat (7).
func _omodonmeka_catch() -> void:
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_68F14)
	var substate: int = 5
	var below: int = 0x1A
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		set_cur(OBJ_STATE_DURATION, 0x18)
		substate = 7
		below = 7
	set_cur_word(OBJ_Y_POS, word(wWarioYPos - below))
	wWarioXPos = word(cur_x() - 8)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | substate)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	_omodonmeka_substate()


## .Func_42321: bobbing (Data_604c0); on screen, with Wario below it within its reach across (and
## not Puffy), alert (substate 8).
func _omodonmeka_hover() -> void:
	apply_obj_y_movement_loop(DATA_604C0)
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0 or wTransformation == TRANSFORMATION_PUFFY_WARIO:
		return
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x22) - byte(wWarioScreenXPos + 0x2A))
	if dx >= 0x28 and dx < 0xD8:
		return
	if byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) >= byte(wWarioScreenYPos + 0x2A):
		return
	set_object_frameset_ptr(FRAMESET_68F1D)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 8)


## .Func_42369 (substate 8): bobbing; with Wario right under it (within 16 px across), dropping on
## him (substate 2, its box's bottom at 0); out of reach or not below, hovering again. The sounds
## are not simulated.
func _omodonmeka_alert() -> void:
	apply_obj_y_movement_loop(DATA_604C0)
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x22) - byte(wWarioScreenXPos + 0x2A))
	var below: bool = byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) < byte(wWarioScreenYPos + 0x2A)
	if dx < 0x10 or dx >= 0xF0:
		if not below:
			return
		set_object_frameset_ptr(FRAMESET_68F2B)
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 2)
		set_cur(OBJ_VAR_3, 0)
		set_cur(OBJ_COLLBOX_BOTTOM, 0)
		return
	if (dx < 0x28 or dx >= 0xD8) and below:
		return
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 1)
	set_object_frameset_ptr(FRAMESET_68F0B)


## .Func_423e1 (substate 2): dropping (Data_60500) until it lands (Func_352b); then harmless,
## going back up (substate 3).
func _omodonmeka_drop() -> void:
	apply_obj_y_movement(DATA_60500)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	store_object_y_from_hpos()
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	set_object_frameset_ptr(FRAMESET_68F14)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 3)


## The home height (OBJ_VAR_1, OBJ_VAR_2).
func _omodonmeka_home() -> int:
	return cur(OBJ_VAR_1) | (cur(OBJ_VAR_2) << 8)


## .Func_42420 (substate 3): up a pixel a frame to its home, then hovering.
func _omodonmeka_return() -> void:
	if cur_y() != _omodonmeka_home():
		move_object_up()
		return
	_omodonmeka_hover_start()


## .Func_4244c (substate 4): flying off (Data_604e0 up, Data_60650 across, looped), without
## actions; with Flat Wario, back to hovering where it reaches its home height.
func _omodonmeka_fly_off() -> void:
	set_cur(OBJ_ACTION, 0x81)
	apply_obj_y_movement(DATA_604E0)
	apply_obj_x_movement_loop(DATA_60650)
	if wTransformation != TRANSFORMATION_FLAT_WARIO or cur_y() != _omodonmeka_home():
		return
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	_omodonmeka_hover_start()


## .Func_42291 (substate 5): lifting Wario a pixel a frame (his floor transitions with him) to
## 64 px above its home or a ceiling (29 px up); then holding him (substate 6). If he has escaped
## (wAutoMoveState clear), state 1 (it flies off next).
func _omodonmeka_lift() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if wAutoMoveState == 0:
		set_cur(OBJ_STATE, 1)
		return
	set_hpos_from_object(-0x1D, 0)
	if (object_probe(COLLISION_UNK3) & 0x0F) == 0 and cur_y() != word(_omodonmeka_home() - 0x40):
		move_wario_up(1)  # SFX_087 every 8 frames not simulated
		handle_upwards_floor_transition()
		move_object_up()
		return
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 6)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68F14)


## .Func_422fc (substate 6): bobbing with Wario 26 px below it until he escapes.
func _omodonmeka_hold() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if wAutoMoveState == 0:
		set_cur(OBJ_STATE, 1)
		return
	apply_obj_y_movement_loop(DATA_604C0)
	wWarioYPos = word(cur_y() + 0x1A)


## .Func_42261 (substate 7): on Flat Wario, pressing him (14 px above at 16 frames left, 22 at 7).
func _omodonmeka_hold_flat() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if wAutoMoveState == 0:
		set_cur(OBJ_STATE, 1)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	var above: int
	match cur(OBJ_STATE_DURATION):
		0x10:
			above = 0x0E
		0x07:
			above = 0x16
		_:
			return
	set_cur_word(OBJ_Y_POS, word(wWarioYPos - above))


# --- Omodonmeka carrying an Omodon, and the Omodon (objects/omodonmeka.asm) ----------------

## The first slot (by index) whose flags masked with `mask` equal `want` and whose map cell
## (OBJ_UNK_01, OBJ_UNK_02) is wCurObj's: the carrier and its Omodon find each other so. -1 if
## none.
func _slot_at_my_cell(mask: int, want: int) -> int:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if (wram1[base + OBJ_FLAGS] & mask) == want and wram1[base + OBJ_UNK_01] == cur(OBJ_UNK_01) \
				and wram1[base + OBJ_UNK_02] == cur(OBJ_UNK_02):
			return slot
	return -1


## OmodonmekaWithOmodon1Func/2Func: its box; its Omodon (ObjParams_Omodon1/2) unless one from its
## cell is already out (Func_3444 counts them), which it then goes to lift (.Func_42559).
func omodonmeka_with_omodon_1_func() -> void:
	_carrier_init(OBJ_PARAMS_OMODON_1)


func omodonmeka_with_omodon_2_func() -> void:
	_carrier_init(OBJ_PARAMS_OMODON_2)


func _carrier_init(params: int) -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, OMODONMEKA_WITH_OMODON_FUNC & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, -3)
	set_cur(OBJ_COLLBOX_LEFT, -13)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)
	var transient: int = OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT
	if _slot_at_my_cell(transient, transient) >= 0:
		_carrier_lower_start()
		return
	create_object_at_relative_pos(params)
	set_object_frameset_ptr(FRAMESET_68F14)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_VAR_3, 0)
	_carrier_wait_start()


## OmodonmekaWithOmodonFunc: attacked, knocked away as Omodonmeka is; $0a is Func_3173; any other
## state sends it flying off for good (.Func_42714). Then its substate.
func omodonmeka_with_omodon_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		match state:
			0x04, 0x05, 0x28, 0x29:
				_omodonmeka_knocked({0x04: FUNC_3326, 0x05: FUNC_3317, 0x28: FUNC_33F8, 0x29: FUNC_3407}[state])
				return
			0x0A:
				func_62e57()
				return
		set_cur(OBJ_STATE, 0x3A)
		set_cur(OBJ_VAR_3, 0)
		set_cur(OBJ_VAR_2, 0)
		set_object_frameset_ptr(FRAMESET_68F34)
		set_cur(OBJ_STATE_DURATION, 2)
		set_cur_word(OBJ_UPDATE_FUNCTION, OMODONMEKA_WITH_OMODON_FUNC_FLY_OFF & 0xFFFF)
		_carrier_fly_off()
		return
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_carrier_wait_start()
		2:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				_carrier_lower_start()
		3:
			_carrier_lower()
		4:
			_carrier_lift()
		_:
			note_unported("OmodonmekaWithOmodonFunc substate %d (past its table)" % (cur(OBJ_SUBSTATE) & 0x0F))


## .Func_42535: under Flat Wario, bobbing (Func_42725); otherwise waiting 60 frames (substate 2).
func _carrier_wait_start() -> void:
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		_carrier_flat_bob()
		return
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 2)
	set_object_frameset_ptr(FRAMESET_68F26)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)


## .Func_42559: lowering itself to its Omodon (substate 3, 40 frames).
func _carrier_lower_start() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 3)
	set_object_frameset_ptr(FRAMESET_68F2B)
	set_cur(OBJ_STATE_DURATION, 0x28)


## .Func_4256c (substate 3): with 40 frames left, down a pixel a frame to 15-16 px above its Omodon
## (on screen); then the time runs; at its end it picks the Omodon up: the Omodon rises with it
## ($2d, $33 frames), its box grown, and the carrier lifts (substate 4, 50 frames).
func _carrier_lower() -> void:
	if cur(OBJ_STATE_DURATION) == 0x28:
		var omodon: int = _slot_at_my_cell(OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT, OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT)
		if omodon < 0:
			return
		var screen_y: int = wram1[W_OBJECTS + omodon * OBJ_STRUCT_LENGTH + OBJ_SCREEN_Y_POS]
		if byte(screen_y - 0x10) != cur(OBJ_SCREEN_Y_POS) and byte(screen_y - 0x0F) != cur(OBJ_SCREEN_Y_POS):
			move_object_down()
			return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 4)
	set_object_frameset_ptr(FRAMESET_68F14)
	set_cur(OBJ_STATE_DURATION, 0x32)
	var found: int = _slot_at_my_cell(OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT, OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT)
	if found < 0:
		return
	var base: int = W_OBJECTS + found * OBJ_STRUCT_LENGTH
	wram1[base + OBJ_STATE] = 0x2D
	wram1[base + OBJ_STATE_DURATION] = 0x33
	wram1[base + OBJ_FRAMESET_OFFSET] = 0
	wram1[base + OBJ_FRAME_DURATION] = 0
	wram1[base + OBJ_FRAMESET_PTR + 1] = FRAMESET_68F42 >> 8
	wram1[base + OBJ_FRAMESET_PTR] = FRAMESET_68F42 & 0xFF
	wram1[base + OBJ_COLLBOX_BOTTOM] = 0x10
	wram1[base + OBJ_COLLBOX_LEFT] = byte(wram1[base + OBJ_COLLBOX_LEFT] - 1)
	wram1[base + OBJ_COLLBOX_RIGHT] = byte(wram1[base + OBJ_COLLBOX_RIGHT] + 1)


## .Func_426ee (substate 4): up a pixel a frame for 50 frames (with Wario standing on the Omodon,
## half a pixel, lifting him: his floor transitions with him); then waiting again (substate 1).
func _carrier_lift() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		if (wGlobalCounter & 1) != 0:
			return
		move_wario_up(1)
		handle_upwards_floor_transition()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up()
		return
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 1)
	set_cur(OBJ_VAR_3, 0)


## .Func_42714: flying off for good (Data_604e0 up, Data_60650 across), without actions.
func _carrier_fly_off() -> void:
	set_cur(OBJ_ACTION, 0x81)
	apply_obj_y_movement(DATA_604E0)
	apply_obj_x_movement_loop(DATA_60650)


## Func_42725: bobbing along Data_40000 (bank $10), skipping zero steps; at its $80 end, back to
## the second entry with the first step taken, and OBJ_STATE_DURATION counts a round.
func _carrier_flat_bob() -> void:
	var index: int = cur(OBJ_VAR_3)
	var step: int = omodon_bob[index] if index < omodon_bob.size() else 0x80
	if step == 0x80:
		step = omodon_bob[byte(index - 0x3F)] if byte(index - 0x3F) < omodon_bob.size() else 0
		set_cur(OBJ_VAR_3, 1)
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	else:
		set_cur(OBJ_VAR_3, index + 1)
	if step != 0:
		add_y_signed(step)


## Func_4279c: the Omodon, no collision with other objects.
func omodon_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, OMODON_FUNC_UPDATE & 0xFFFF)
	omodon_update()


## .Func_427a9: kept from despawning while its carrier is out (.Func_42935, OBJSUBFLAG_UNK_4);
## then by OBJ_STATE: 0 (Func_42767), lifted ($2d), falling ($2e), landed ($2f), on Wario ($2a,
## $5a); any other state is cleared.
func omodon_update() -> void:
	set_cur(OBJ_SUBSTATE, OBJSUBFLAG_UNK_4 if _slot_at_my_cell(OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT, OBJFLAG_ACTIVE) >= 0 else 0)
	match cur(OBJ_STATE):
		0x00:
			_omodon_idle()
		0x2D:
			_omodon_lifted()
		0x2E:
			_omodon_fall()
		0x2F:
			_omodon_landed()
		OBJSTATE_ACTIVATE:
			set_object_frameset_ptr(FRAMESET_68F45)
			set_cur(OBJ_STATE_DURATION, 0x14)
			set_cur(OBJ_STATE, 0x5A)
			set_cur_word(OBJ_Y_POS, word(wWarioYPos - 0x18))
		0x5A:
			_omodon_on_wario()
		_:
			set_cur(OBJ_STATE, 0)
			_omodon_idle()


## Func_42767: with Flat Wario, bobbing as the carrier does (and passing its stepped flag on);
## otherwise falling ($2e) as an Omodon (OBJ_INTERACTION_OMODON), its box a pixel narrower.
func _omodon_idle() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		_carrier_flat_bob()
		_omodon_pass_stepped()
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		return
	_omodon_fall_start()


## Func_42767.asm_4277f
func _omodon_fall_start() -> void:
	set_cur(OBJ_STATE, 0x2E)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68F42)
	set_interaction(OBJ_INTERACTION_OMODON)
	set_cur(OBJ_COLLBOX_LEFT, cur(OBJ_COLLBOX_LEFT) + 1)
	set_cur(OBJ_COLLBOX_RIGHT, cur(OBJ_COLLBOX_RIGHT) - 1)


## .Func_42894: its carrier on screen gets the Omodon's OBJFLAG_STEPPED as its own (the rotates
## in the original copy that one bit); a carrier knocked away ($3a) drops it ($2e).
func _omodon_pass_stepped() -> void:
	var carrier: int = _slot_at_my_cell(OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN | OBJFLAG_TRANSIENT,
			OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN)
	if carrier < 0:
		return
	var base: int = W_OBJECTS + carrier * OBJ_STRUCT_LENGTH
	wram1[base + OBJ_FLAGS] = (wram1[base + OBJ_FLAGS] & ~OBJFLAG_STEPPED) | (cur(OBJ_FLAGS) & OBJFLAG_STEPPED)
	if wram1[base + OBJ_STATE] == 0x3A:
		_omodon_fall_start()


## .asm_427cd ($2d): carried up with its carrier ($33 frames; half speed while Wario stands on
## it); then hanging (state 0), its box's bottom at 11.
func _omodon_lifted() -> void:
	_omodon_pass_stepped()
	if cur(OBJ_STATE_DURATION) == 0x33:
		set_cur(OBJ_STATE_DURATION, 0x32)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0 and (wGlobalCounter & 1) != 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		move_object_up()
		return
	set_object_frameset_ptr(FRAMESET_68F50)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_COLLBOX_BOTTOM, 0x0B)


## .asm_427fe ($2e): falling (Data_605e0) until something 15 px below its position stops it
## (Func_352b); then the ground shakes ($18 frames, DoGroundShake; SFX_063 not simulated) and it
## lies solid ($2f, 28 frames).
func _omodon_fall() -> void:
	apply_obj_y_movement(DATA_605E0)
	set_hpos_from_object(0x0F, 0)
	if object_probe(COLLISION_UNK1) == 0:
		return
	set_cur_word(OBJ_Y_POS, word(hYPos - 0x0F))
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 0x18
		wIsWarioGroundShaking = 0
	set_object_frameset_ptr(FRAMESET_68F45)
	_omodon_land()


## .asm_4283c: solid (OBJ_INTERACTION_SOLID), landed ($2f) for 28 frames.
func _omodon_land() -> void:
	set_cur(OBJ_STATE_DURATION, 0x1C)
	set_interaction(OBJ_INTERACTION_SOLID)
	set_cur(OBJ_STATE, 0x2F)


## Func_42754 ($2f): then its resting frameset.
func _omodon_landed() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	if cur(OBJ_STATE_DURATION) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_object_frameset_ptr(FRAMESET_68F50)


## .Func_4286b ($5a): on Wario's head (24 px above him); while he is carried it slides off 2 px a
## frame; then, no actions for 31 frames, solid and landed.
func _omodon_on_wario() -> void:
	if cur(OBJ_STATE_DURATION) == 0x14:
		if wAutoMoveState != 0:
			set_cur_word(OBJ_Y_POS, cur_y() + 2)
			return
		set_cur_word(OBJ_Y_POS, word(wWarioYPos - 0x18))
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_ACTION, 0x9F)
	_omodon_land()


# --- Beam Bot and its beams (objects/beam_bot.asm) -------------------------------------------------

func _beam_bot_frameset(role: String, right: bool) -> int:
	return BEAM_BOT_FRAMESETS[role][1 if right else 0]


## BeamBotFunc: .Init on the next update.
func beam_bot_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BEAM_BOT_FUNC_INIT & 0xFFFF)


## BeamBotFunc.Init: visible, then .Func_46691.
func beam_bot_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, BEAM_BOT_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_beam_bot_default()


## BeamBotFunc.Update: the state's handler. Its table is Spear Bot's slot for slot, with its own
## routines for the walk, the beam, the turn, and the falls, and the shared ones elsewhere.
func beam_bot_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0B, 0x0C, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, \
				0x5A, 0x5B, 0x5C:
			_beam_bot_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(_beam_bot_frameset("walk", hdir()))
			set_cur(OBJ_STATE_DURATION, 100)
		0x02, 0x03:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_beam_bot_frameset("bump", hdir()))
			set_cur(OBJ_STATE_DURATION, 12)
			set_cur(OBJ_VAR_2, 2)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_01)
		0x04, 0x05, 0x28, 0x29:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
			set_object_frameset_ptr(_beam_bot_frameset("knocked", hdir()))
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			set_cur(OBJ_ACTION, 0x8F)
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_beam_bot_frameset("hit", hdir()))
			set_cur(OBJ_STATE_DURATION, 4)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_00)
		0x0F:
			set_cur(OBJ_STATE, 0x3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		0x10:
			set_cur(OBJ_STATE, 0x40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(_beam_bot_frameset("walk", hdir()))
		0x12:
			enemy_12()
		0x13:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(_beam_bot_frameset("turn", hdir()))
			set_cur(OBJ_STATE_DURATION, 17)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_01)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_beam_bot_frameset("hit", hdir()))
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_00)
		0x16, 0x17:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(_beam_bot_frameset("hit", hdir()))
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_00)
			enemy_slide(state == 0x16)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, _beam_bot_frameset("hit", false), _beam_bot_frameset("hit", true))
		0x2D:
			_beam_bot_charge()
		0x2E:
			if ground_shake_wobble(DIV_BEAM_BOT[1]):
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
		0x31:
			_beam_bot_walk()
		0x3F:
			enemy_lie()
		0x40:
			enemy_get_up()
		0x43:
			_beam_bot_turn()
		0x46, 0x47:
			enemy_slide(state == 0x46)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft and _Right, no frameset of its own
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("BeamBotFunc state %02x" % state)


## .Func_46691: walking off again: falling ($30), harmless, the short box, facing Wario.
func _beam_bot_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_collbox_x(-6, 5)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(_beam_bot_frameset("walk", right))


## .Func_46769 ($31): with Wario level with it (within $1c rows) and within $48 px ahead (not split,
## and the bot on screen), the wind-up ($2d, 41 frames); that near behind, a turn ($13); otherwise a
## step half a pixel a frame (6 px left, 5 right) that waits at the floor's end (its animation
## slowed) until OBJ_STATE_DURATION runs out, then turns.
func _beam_bot_walk() -> void:
	if ground_shake_wobble(DIV_BEAM_BOT[2]):
		return
	if wTransformation != TRANSFORMATION_SPLIT and (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		var dy: int = byte(cur(OBJ_SCREEN_Y_POS) - wWarioScreenYPos)
		if dy < 0x1C or dy >= 0xE4:
			var dx: int = byte(cur(OBJ_SCREEN_X_POS) - wWarioScreenXPos)
			if dx >= 0xB8 or dx < 0x48:
				var wario_right: bool = dx >= 0xB8
				if hdir() != wario_right:
					set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
					return
				set_cur(OBJ_STATE, 0x2D)
				set_object_frameset_ptr(_beam_bot_frameset("wind_up", wario_right))
				set_cur(OBJ_STATE_DURATION, 41)
				return
	if not enemy_on_floor():
		return
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if fine_x + 5 >= 0x10 and (process_block_on_right() & 0x0F) == 0:
			_beam_bot_wait_at_edge()
			return
		set_hpos_from_object(-4, 5)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_right_slow()
			return
	else:
		if fine_x < 6 and (process_block_on_left() & 0x0F) == 0:
			_beam_bot_wait_at_edge()
			return
		set_hpos_from_object(-4, -6)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_left_slow()
			return
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


## .asm_4685f: at the floor's end its animation holds on even frames; when OBJ_STATE_DURATION runs
## out, it turns.
func _beam_bot_wait_at_edge() -> void:
	if (wGlobalCounter & 1) == 0:
		set_cur(OBJ_FRAME_DURATION, cur(OBJ_FRAME_DURATION) + 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


## .Func_466e7 ($2d): the beam fires $19 frames before the wind-up ends (ObjParams_BeamLeft or
## _Right); then the firing frameset for 50 frames ($2e), and a turn.
func _beam_bot_charge() -> void:
	if ground_shake_wobble(DIV_BEAM_BOT[0]):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, 0x2E)
		set_object_frameset_ptr(_beam_bot_frameset("fire", hdir()))
		set_cur(OBJ_STATE_DURATION, 50)
		return
	if cur(OBJ_STATE_DURATION) == 0x19:
		create_object_at_relative_pos(OBJ_PARAMS_BEAM_RIGHT if hdir() else OBJ_PARAMS_BEAM_LEFT)


## .Func_469b2 ($43): turned round with 6 frames left; meanwhile Func_62908; then walking ($01).
func _beam_bot_turn() -> void:
	if ground_shake_wobble(DIV_BEAM_BOT[3]):
		return
	if cur(OBJ_STATE_DURATION) == 0x06:
		set_cur(OBJ_STATE_DURATION, 0x05)
		set_hdir(not hdir())
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x01)


## BeamFunc_Left and _Right: no collision with objects (SFX_07C); then .Update.
func beam_func_left() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BEAM_FUNC_LEFT_UPDATE & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	beam_update_left()


func beam_func_right() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BEAM_FUNC_RIGHT_UPDATE & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	beam_update_right()


## .Update: its full-length frameset when OBJ_STATE_DURATION runs out; along Data_60610 or
## Data_60630 (BeamFunc: any state is cleared, SFX_07D).
func beam_update_left() -> void:
	_beam_fly(FRAMESET_68EF3, DATA_60610)


func beam_update_right() -> void:
	_beam_fly(FRAMESET_68EF8, DATA_60630)


func _beam_fly(frameset: int, table: int) -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(frameset)
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_STATE, 0)
	apply_obj_x_movement(table)


# --- Kushimushi (objects/kushimushi.asm) ----------------------------------------------------------

## KushimushiVerticalFunc: down first ($60 frames), a box -4..3 (bottom -3).
func kushimushi_vertical_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, KUSHIMUSHI_VERTICAL_UPDATE & 0xFFFF)
	_kushimushi_start(0x461B)
	set_collbox_x(-4, 3)
	set_cur(OBJ_COLLBOX_BOTTOM, -3)


## KushimushiHorizontalFunc: right first ($60 frames), facing right, a box -5..4 (bottom -4).
func kushimushi_horizontal_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, KUSHIMUSHI_HORIZONTAL_UPDATE & 0xFFFF)
	_kushimushi_start(0x4611)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
	set_collbox_x(-5, 4)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)


func _kushimushi_start(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 0x60)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 0)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)


## .Update (vertical) and .Func_42acf (horizontal): state 0 patrols; a bounce off it ($0d/$0e
## vertical, $0b/$0c horizontal) stops it $3c frames; $0a vanishes; otherwise knocked away.
func kushimushi_vertical_update() -> void:
	_kushimushi_update(false)


func kushimushi_horizontal_update() -> void:
	_kushimushi_update(true)


func _kushimushi_update(horizontal: bool) -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_kushimushi_patrol(horizontal)
		return
	if state == (0x0B if horizontal else 0x0D) or state == (0x0C if horizontal else 0x0E):
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_VAR_2, 0x3C)
		if horizontal:
			set_object_frameset_ptr(0x4620 if cur(OBJ_VAR_1) != 0 else 0x4625)
		else:
			set_object_frameset_ptr(0x462A if cur(OBJ_VAR_1) != 0 else 0x462F)
		return
	match state:
		OBJSTATE_VANISH_TOUCH:
			vanish_object()
		0x28:
			_kushimushi_knocked(FUNC_33F8)
		0x29:
			_kushimushi_knocked(FUNC_3407)
		0x04:
			_kushimushi_knocked(FUNC_3326)
		0x05:
			_kushimushi_knocked(FUNC_3317)
		_:
			_kushimushi_knocked(FUNC_33F8 if (state & 1) != 0 else FUNC_3407)


## .asm_42a4b: knocked away by a shared routine, no collision with objects.
func _kushimushi_knocked(routine: int) -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, routine)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_object_frameset_ptr(0x4698)


## .asm_42a68 / .asm_42b15: stopped while OBJ_VAR_2 lasts (vertically, its animation held); then on
## even frames the phase by OBJ_VAR_1: a pixel a frame along its line until OBJ_STATE_DURATION runs
## out, or a turn's wait; each phase sets the next's frameset, interaction, and wait (the
## horizontal one's turns flip it).
func _kushimushi_patrol(horizontal: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
		if not horizontal:
			set_cur(OBJ_FRAME_DURATION, 2)
		return
	if (wGlobalCounter & 1) != 0:
		return
	var phase: int = cur(OBJ_VAR_1)
	if phase > 3:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		match phase:
			0:
				if horizontal:
					move_object_right()
				else:
					move_object_down()
			2:
				if horizontal:
					move_object_left()
				else:
					move_object_up()
		return
	var entry: Array = (KUSHIMUSHI_HORIZONTAL_PHASES if horizontal else KUSHIMUSHI_VERTICAL_PHASES)[phase]
	if horizontal and (phase & 1) != 0:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)
	set_cur(OBJ_STATE_DURATION, entry[2])
	set_cur(OBJ_VAR_1, (phase + 1) & 3)
	set_interaction(entry[1])
	set_object_frameset_ptr(entry[0])


# --- Togeba (objects/togeba.asm) -------------------------------------------------------------------

## TogebaFunc: a box -12..11; then spiky and waiting (.Func_48d9b).
func togeba_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-12, 11)
	_togeba_reset()


## .Func_48d9b: spiky (a full sting), waiting.
func _togeba_reset() -> void:
	set_object_frameset_ptr(0x5230)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_STATE, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_WAIT & 0xFFFF)
	set_interaction(OBJ_INTERACTION_FULL_STING)


## .Func_48db7: a ground shake knocks it off ($30 frames along Data_60760, bounced off); any state
## (a hit) makes it flinch for $16 frames (colliding again), then still.
func togeba_wait() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_SHAKEN & 0xFFFF)
		set_object_frameset_ptr(0x5256)
		set_cur(OBJ_STATE_DURATION, 0x30)
		set_interaction(OBJ_INTERACTION_0B)
		set_cur(OBJ_VAR_3, 0)
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(0x5230)
		return
	if cur(OBJ_STATE) == 0:
		return
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(0x524B)
	set_cur(OBJ_STATE_DURATION, 0x16)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


## .Func_48e02: then a walkable platform (.Func_48e46).
func togeba_shaken() -> void:
	apply_obj_y_movement(DATA_60760)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_PLATFORM & 0xFFFF)
	set_object_frameset_ptr(0x5263)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE, 0)
	set_interaction(0x0C)  # OBJ_INTERACTION_WALKABLE


## .Func_48e46: sinking half a pixel a frame (stood on, carrying Wario and his floor), until a floor
## under either edge (12 left, 11 right) lands it (.Func_48e2b); bounced off ($0a) it flinches $1b
## frames; any other hit, $0a frames, and with OBJ_UNK_1D bit 7 it rises.
func togeba_platform() -> void:
	hYPos = cur_y()
	hXPos = word(cur_x() - 0x0C)
	if object_probe(COLLISION_UNK1) != 0:
		_togeba_land()
		return
	hXPos = word(cur_x() + 0x0B)
	if object_probe(COLLISION_UNK1) != 0:
		_togeba_land()
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(0x5263)
	var state: int = cur(OBJ_STATE)
	if state == OBJSTATE_VANISH_TOUCH:
		set_cur(OBJ_STATE, 0)
		set_object_frameset_ptr(0x526C)
		set_cur(OBJ_STATE_DURATION, 0x1B)
	elif state != 0:
		set_cur(OBJ_STATE, 0)
		set_object_frameset_ptr(0x527C)
		set_cur(OBJ_STATE_DURATION, 0x0A)
		if (cur(OBJ_UNK_1D) & 0x80) != 0:
			set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_RISING & 0xFFFF)
			return
	if (wGlobalCounter & 1) == 0:
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		move_object_down()
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	move_wario_down(1)
	handle_downwards_floor_transition()
	move_object_down()


## .Func_48e2b: landed for $10 frames (.Func_48e3e), then spiky again.
func _togeba_land() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_LANDED & 0xFFFF)
	set_object_frameset_ptr(0x5275)
	set_cur(OBJ_STATE_DURATION, 0x10)


func togeba_landed() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_togeba_reset()


## .Func_48ecc: 2 px up a frame for OBJ_STATE_DURATION frames, then the platform again.
func togeba_rising() -> void:
	set_cur_word(OBJ_Y_POS, cur_y() - 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, TOGEBA_PLATFORM & 0xFFFF)
	set_object_frameset_ptr(0x5263)


# --- Prince Froggy (objects/prince_froggy.asm) ------------------------------------------------------

## GreyPrinceFroggyFunc: sitting, a box -20..3 (bottom 0), starting up (.Func_441dc).
func grey_prince_froggy_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, PRINCE_FROGGY_SITTING & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-20, 3)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	_prince_froggy_start()


## RedPrinceFroggyFunc: stuck in the ground, the same box.
func red_prince_froggy_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, PRINCE_FROGGY_STUCK & 0xFFFF)
	set_object_frameset_ptr(0x4AC6)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-20, 3)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)


## .Update_Stuck: stood on, it struggles ($5a, 111 frames, while stood on); hit, it flinches ($3b,
## 40 frames); a turn ($13) frees it to sit; knocked, shaken, falling, vanishing as below.
func prince_froggy_stuck() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0:
			if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
				_prince_froggy_shaken()
				return
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
			set_cur(OBJ_STATE, 0x5A)
			set_object_frameset_ptr(0x4ADD)
			set_cur(OBJ_STATE_DURATION, 111)
		0x1B:
			func_63050()  # Func_3272
		0x41:
			obj_state_standing_fall()
		0x13:
			set_cur_word(OBJ_UPDATE_FUNCTION, PRINCE_FROGGY_SITTING & 0xFFFF)
			_prince_froggy_start()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
		0x5A:
			if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
				set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
				return
			_prince_froggy_unstick()
		0x3B:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				_prince_froggy_shaken()
				return
			_prince_froggy_unstick()
		0x28, 0x29, 0x04, 0x05:
			_prince_froggy_knocked(state)
		OBJSTATE_VANISH_TOUCH:
			_prince_froggy_leave()
		_:
			set_cur(OBJ_STATE, 0x3B)
			set_object_frameset_ptr(0x4AF2)
			set_cur(OBJ_STATE_DURATION, 40)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


## .asm_44166: stuck still.
func _prince_froggy_unstick() -> void:
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(0x4AC6)
	_prince_froggy_shaken()


## .Update_Sitting: by state: still (0), the start's wait ($43, then still), the turn ($13) starting
## again; knocked, shaken, falling, vanishing; any other state is cleared and it starts again.
func prince_froggy_sitting() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0:
			_prince_froggy_shaken()
		0x11:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
		0x1B:
			func_63050()  # Func_3272
		0x41:
			obj_state_standing_fall()
		0x28, 0x29, 0x04, 0x05:
			_prince_froggy_knocked(state)
		0x13:
			_prince_froggy_start()
		0x43:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_cur(OBJ_STATE, 0)
				set_object_frameset_ptr(0x4AE9)
			_prince_froggy_shaken()
		OBJSTATE_VANISH_TOUCH:
			_prince_froggy_leave()
		_:
			set_cur(OBJ_STATE, 0)
			_prince_froggy_start()


## .Func_441dc: $43 for 73 frames, colliding, its own interaction, its box top -26.
func _prince_froggy_start() -> void:
	set_cur(OBJ_STATE, 0x43)
	set_object_frameset_ptr(0x4B01)
	set_cur(OBJ_STATE_DURATION, 73)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	set_interaction(OBJ_INTERACTION_PRINCE_FROGGY)
	set_cur(OBJ_COLLBOX_TOP, 0xE6)


## .asm_44185: a ground shake knocks it ($1b, 13 frames, bounced off).
func _prince_froggy_shaken() -> void:
	if wGroundShakeCounter < 0x10:
		return
	set_cur(OBJ_STATE, 0x1B)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(0x4AE6)
	set_cur(OBJ_STATE_DURATION, 13)
	set_interaction(OBJ_INTERACTION_0B)


## .Func_440c4-.Func_440d6: knocked away by a shared routine at speed 1.
func _prince_froggy_knocked(state: int) -> void:
	var routine: int = {0x28: FUNC_33F8, 0x29: FUNC_3407, 0x04: FUNC_3326, 0x05: FUNC_3317}[state]
	set_cur_word(OBJ_UPDATE_FUNCTION, routine)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 1)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_object_frameset_ptr(0x4AE6)


## .asm_4420a: leaving (.Func_44220, 16 frames along Data_60040), then 8 px left and gone
## (VanishObject2).
func _prince_froggy_leave() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, PRINCE_FROGGY_LEAVING & 0xFFFF)
	set_object_frameset_ptr(0x4AE6)
	set_cur(OBJ_STATE_DURATION, 16)
	set_cur(OBJ_VAR_3, 0)


func prince_froggy_leaving() -> void:
	_no_actions_for_one()
	apply_obj_y_movement(DATA_60040)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()
	vanish_object()


func _no_actions_for_one() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


# --- The small Octohon (objects/octohon.asm) --------------------------------------------------------

## SmallOctohonFunc: visible, no collision with objects, no box.
func small_octohon_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_OCTOHON_FUNC_FACE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 0)
	set_cur(OBJ_COLLBOX_LEFT, 0)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)


## .Func_4a4d4: swimming toward Wario (by the screen positions, $2a on).
func small_octohon_face() -> void:
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_OCTOHON_FUNC_SWIM & 0xFFFF)
	_small_octohon_swim_start(right)


## .asm_4a4f7: $ac frames one way (OBJ_VAR_1 1 right, 0 left), the sway from its start, in front
## of or behind the background by bit 0 of rDIV (OBJFLAG_PRIORITY flipped).
func _small_octohon_swim_start(right: bool) -> void:
	set_cur(OBJ_STATE_DURATION, 0xAC)
	set_cur(OBJ_VAR_1, 1 if right else 0)
	set_cur(OBJ_VAR_2, 0)
	if (read_div(DIV_SMALL_OCTOHON) & 1) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) ^ OBJFLAG_PRIORITY)
	set_object_frameset_ptr(FRAMESET_69B38 if right else FRAMESET_69B2F)


## .Func_4a50f: no actions; when the $ac frames run out, turning (Frameset_69b4c, _69b41), and
## at the sway's $ee-th step swimming back. Each frame the sway's next step (Data_4a5a9 to its $80,
## then again) moves it along, except that past the first step a solid block where it is
## (Func_3513) skips the step without moving.
func small_octohon_swim() -> void:
	_no_actions_for_one()
	if cur(OBJ_VAR_1) > 1:
		set_cur(OBJ_VAR_1, 0)
	var right: bool = cur(OBJ_VAR_1) == 1
	var duration: int = cur(OBJ_STATE_DURATION)
	if duration != 0:
		set_cur(OBJ_STATE_DURATION, duration - 1)
		if duration == 1:
			set_object_frameset_ptr(FRAMESET_69B4C if right else FRAMESET_69B41)
	elif cur(OBJ_VAR_2) == 0xEE:
		_small_octohon_swim_start(not right)
		return
	if cur(OBJ_VAR_2) != 0:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK4) != 0:
			set_cur(OBJ_VAR_2, byte(cur(OBJ_VAR_2) + 1))
			return
	var step: int = bank_byte(0x12, DATA_4A5A9 + cur(OBJ_VAR_2))
	if step == 0x80:
		set_cur(OBJ_VAR_2, 0)
		step = bank_byte(0x12, DATA_4A5A9)
	set_cur(OBJ_VAR_2, byte(cur(OBJ_VAR_2) + 1))
	set_cur_word(OBJ_X_POS, cur_x() + step if right else cur_x() - step)


# --- The Robo Mouse (objects/robo_mouse.asm) --------------------------------------------------------

## RoboMouseFunc: its box (and bit 4 of OBJ_SUBSTATE: `set OBJFLAG_INVISIBLE_F` with hl still at the
## substate); facing Wario on the next update.
func robo_mouse_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, ROBO_MOUSE_FUNC_FACE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJFLAG_INVISIBLE)
	set_cur(OBJ_COLLBOX_RIGHT, 0x0B)
	set_cur(OBJ_COLLBOX_LEFT, -12)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)


## .Func_488f7: visible, facing Wario (by the screen positions, $2a on), OBJ_VAR_3 cleared.
func robo_mouse_face() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, ROBO_MOUSE_FUNC_UPDATE & 0xFFFF)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_691DE if right else FRAMESET_69220)


## .Func_4892a, by OBJ_STATE: walking ($31; $01 starts it); hit ($0a); stopped ($13, $16, $17,
## then $43) and turning to Wario ($2d, $2e); knocked away by the shared routines, the blocks
## ahead of it broken first ($22-$27, $52-$57); falling ($11, $30, $41), sinking ($3a). Any other
## state makes it fall ($30) with collisions back.
func robo_mouse_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x01:
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			_robo_mouse_walk()
		OBJSTATE_WALK:
			_robo_mouse_walk()
		0x0A:
			_robo_mouse_hit()
		0x11:
			set_cur(OBJ_STATE, 0x41)
			set_cur(OBJ_VAR_3, 0)
		0x13, 0x16, 0x17:
			set_cur(OBJ_STATE, 0x43)
			set_cur(OBJ_STATE_DURATION, 0x0A if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0 else 1)
			_robo_mouse_stopped()
		0x14:
			func_62c9f()  # Func_3245
		0x15:
			func_62d7d()  # Func_3254
		0x20:
			func_62e8f()  # Func_3191
		0x21:
			func_62f76()  # Func_31af
		0x22, 0x24, 0x26, 0x52, 0x54, 0x56:
			_robo_mouse_break_ahead(false, 0x0E)  # .Func_48cec
			match state:
				0x22:
					func_62eaa()  # Func_31cd
				0x24:
					func_62e74()  # Func_3209
				0x26:
					func_62c9f()  # Func_3245
				0x52:
					func_62ec3(DATA_602E0)  # Func_31dc
				0x54:
					func_62ec3(DATA_60300)  # Func_3218
				_:
					func_62ca8()  # Func_32cc
		0x23, 0x25, 0x27, 0x53, 0x55, 0x57:
			_robo_mouse_break_ahead(true, 0x0D)  # .asm_48d3d
			match state:
				0x23:
					func_62f91()  # Func_31eb
				0x25:
					func_62f5b()  # Func_3227
				0x27:
					func_62d7d()  # Func_3254
				0x53:
					func_62faa(DATA_602E0)  # Func_31fa
				0x55:
					func_62faa(DATA_60300)  # Func_3236
				_:
					func_62d86()  # Func_32db
		0x2A:
			set_cur(OBJ_STATE, 0x5A)
			set_object_frameset_ptr(FRAMESET_691FB if hdir() else FRAMESET_69200)
		0x2D:
			_robo_mouse_turning(FRAMESET_691DE)
		0x2E:
			_robo_mouse_turning(FRAMESET_69220)
		0x30:
			obj_state_fall()
		0x3A:
			_robo_mouse_sink()
		0x41:
			obj_state_standing_fall()
		0x43:
			_robo_mouse_stopped()
		0x50:
			func_62ec3(DATA_602C0)  # Func_31a0
		0x51:
			func_62faa(DATA_602C0)  # Func_31be
		0x5A:
			pass
		_:
			set_cur(OBJ_STATE, 0x30)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


## .Func_48b30: a pixel a frame ahead, held to the floor under it (Func_3543; none, it falls: $11).
## Off a slope's top it checks 8 px ahead (7 right): open there, a drop ($22 or $23); otherwise the
## blocks ahead break (12 px back, 11 right) and a block solid to it 4 px up and 20 px ahead (19
## right) makes it climb 6 px ($24 or $25). Both by the shared routines at OBJ_VAR_2 2.
func _robo_mouse_walk() -> void:
	var right: bool = hdir()
	if right:
		move_object_right()
	else:
		move_object_left()
	set_hpos_from_object()
	var b: int = object_probe(COLLISION_DOWN)
	if b == 0:
		set_cur(OBJ_STATE, 0x11)
		set_object_frameset_ptr(FRAMESET_691DE if right else FRAMESET_69220)
		return
	store_object_y_from_hpos()
	if b == 0x10:
		return
	hXPos = word(cur_x() + 7 if right else cur_x() - 8)
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, 0x23 if right else 0x22)
	else:
		_robo_mouse_break_ahead(right, 0x0B if right else 0x0C)
		hYPos = word(cur_y() - 4)
		hXPos = word(cur_x() + 0x13 if right else cur_x() - 0x14)
		wBlockFuncSpecialCollision = COLLISION_ROBO_MOUSE_FREE
		if (object_probe(COLLISION_UNK4) & 0x0F) == 0:
			return
		set_cur_word(OBJ_Y_POS, cur_y() - 6)
		set_cur(OBJ_STATE, 0x25 if right else 0x24)
	set_cur(OBJ_VAR_2, 2)
	var frameset: int = FRAMESET_691E5 if right else FRAMESET_69213
	if cur(OBJ_FRAMESET_PTR) != (frameset & 0xFF):
		set_object_frameset_ptr(frameset)


## .Func_48cec and .asm_48ce8 (`dx` back), .asm_48d3d and .asm_48d39 (`dx` ahead, right): the
## blocks at 4, 20, and 36 px up there break for it (COLLISION_ROBO_MOUSE_BREAK).
func _robo_mouse_break_ahead(right: bool, dx: int) -> void:
	hXPos = word(cur_x() + dx if right else cur_x() - dx)
	for dy: int in [4, 0x14, 0x24]:
		hYPos = word(cur_y() - dy)
		wBlockFuncSpecialCollision = COLLISION_ROBO_MOUSE_BREAK
		object_probe(COLLISION_UNK4)


## .Func_48a47 (OBJSTATE $0a): with collisions off (cleared, PRIORITY too) it is stunned: its
## frameset for 60 frames, OBJ_INTERACTION_0B, stars over Wario (ObjParams_StarsAbove; SFX_VANISH
## not simulated), and knocked away ($24 left of Wario, $25 otherwise, the blocks there broken).
## Otherwise it sinks ($3a; its walking frameset unless stunned), splashing when on screen
## (PARTICLE_SPLASH at it; SFX_083 not simulated).
func _robo_mouse_hit() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_NO_COLLISION) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~(OBJFLAG_NO_COLLISION | OBJFLAG_PRIORITY))
		set_object_frameset_ptr(FRAMESET_69205 if hdir() else FRAMESET_6920C)
		set_cur(OBJ_STATE_DURATION, 0x3C)
		set_interaction(OBJ_INTERACTION_0B)
		create_object_from_cur_obj_pos(OBJ_PARAMS_STARS_ABOVE)
		if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
			_robo_mouse_break_ahead(false, 0x0E)
			func_62e74()  # Func_3209
		else:
			_robo_mouse_break_ahead(true, 0x0D)
			func_62f5b()  # Func_3227
		return
	set_cur(OBJ_STATE, 0x3A)
	if (cur(OBJ_INTERACTION_TYPE) & 0x7F) != OBJ_INTERACTION_0B:
		set_object_frameset_ptr(FRAMESET_691DE if hdir() else FRAMESET_69220)
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	set_hpos_from_object()
	create_particle(PARTICLE_SPLASH)


## .Func_48ae9 ($3a): sinking half a pixel a frame to a floor (Func_352b), then stopped ($13) if
## stunned, otherwise walking ($31).
func _robo_mouse_sink() -> void:
	move_object_down_slow()
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	set_cur(OBJ_STATE, 0x13 if (cur(OBJ_INTERACTION_TYPE) & 0x7F) == OBJ_INTERACTION_0B else OBJSTATE_WALK)


## .Func_48c60 ($43): standing (Func_3308) out its frames; then, Wario behind it, turning ($2d to
## the right, $2e left; 49 frames), otherwise walking on ($31; a stunned one with its walking
## frameset and PRIORITY). Its interaction is OBJ_INTERACTION_ROBO_MOUSE again.
func _robo_mouse_stopped() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()  # Func_3308
		return
	var wario_right: bool = wWarioXPos >= cur_x()
	if wario_right != hdir():
		set_cur(OBJ_STATE, 0x2D if wario_right else 0x2E)
		set_hdir(wario_right)
		set_object_frameset_ptr(FRAMESET_69227 if wario_right else FRAMESET_691F2)
		set_cur(OBJ_STATE_DURATION, 0x31)
	else:
		set_cur(OBJ_STATE, OBJSTATE_WALK)
		if (cur(OBJ_INTERACTION_TYPE) & 0x7F) == OBJ_INTERACTION_0B:
			set_object_frameset_ptr(FRAMESET_691DE if hdir() else FRAMESET_69220)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_interaction(OBJ_INTERACTION_ROBO_MOUSE)


## .Func_48cc6 ($2d) and .Func_48cd7 ($2e): the turn's frames, then walking ($31).
func _robo_mouse_turning(frameset: int) -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE, OBJSTATE_WALK)


# --- Count Richtertoffen (objects/count_richtertoffen.asm) -----------------------------------------

## CountRichtertoffenFunc: visible, its box -8..7 (bottom -4), then .Default.
func count_richtertoffen_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur_word(OBJ_UPDATE_FUNCTION, COUNT_RICHTERTOFFEN_UPDATE & 0xFFFF)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)
	_richtertoffen_default()


## CountRichtertoffenFunc.Update's table, by OBJ_STATE (to $5c): it walks 44 frames, leaps (22
## frames up along Data_603d0, a ceiling turning it back), falls along Data_603e0 (water vanishes
## it), and lands with a ground shake (24) and a bounce (Data_604b0), turning at walls. Stunned,
## knocked, picked up, held, and thrown by the shared routines; flattened by Wario ($2a).
func count_richtertoffen_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2B, 0x2C, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x5B, 0x5C:
			_richtertoffen_default()
		OBJSTATE_LAND:
			if (cur(OBJ_FLAGS) & (OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN)) != OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN:
				return
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(FRAMESET_683BC)
			set_cur(OBJ_STATE_DURATION, 44)
		0x02, 0x03:
			# .Bump: leaping away from Wario.
			set_cur(OBJ_STATE, OBJSTATE_SPECIAL_1)
			_richtertoffen_leap(byte(wWarioScreenXPos + 0x2A) < byte(cur(OBJ_SCREEN_X_POS) + 0x2A))
		0x04, 0x05:
			if wTransformation == 0 and wram1[W_EFFECTIVE_POWER_UP] < GARLIC \
					and (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) != 0:
				set_cur(OBJ_STATE, state + 0x04)
			else:
				_richtertoffen_knocked(state + 0x30, 1)
		0x06, 0x07:
			set_cur(OBJ_STATE, state + 0x30)
			var table: int = DATA_601D0 if state == 0x06 else DATA_601F0
			set_cur(OBJ_VAR_3, table >> 8)
			set_cur(OBJ_VAR_2, table & 0xFF)
			set_cur(OBJ_VAR_1, 1)
			picked_up(state == 0x06)  # Func_3335, Func_3344
		0x08, 0x09:
			_richtertoffen_wobble_start(state + 0x30)
		OBJSTATE_VANISH_TOUCH:
			if cur(OBJ_ACTION) == 0 or wTransformation != 0 or wram1[W_EFFECTIVE_POWER_UP] >= SUPER_JUMP_SLAM_OVERALLS \
					or (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) == 0:
				vanish_object()  # VanishObject2
				return
			# SFX_014 not simulated
			var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			_richtertoffen_wobble_start(OBJSTATE_WOBBLE_RIGHT if left_of_wario else OBJSTATE_WOBBLE_LEFT)
		0x0B, 0x0C:
			set_hdir(state == 0x0B)
			_richtertoffen_fall_start()
		OBJSTATE_0F:
			set_cur(OBJ_STATE, OBJSTATE_3F)
			set_cur(OBJ_STATE_DURATION, 100)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			_richtertoffen_lie()
		OBJSTATE_10:
			set_cur(OBJ_STATE, OBJSTATE_40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		OBJSTATE_STANDING_FALL_START:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_683DE)
		OBJSTATE_12:
			enemy_12()
		OBJSTATE_TURN_AROUND_START:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(FRAMESET_683E1)
			set_cur(OBJ_STATE_DURATION, 48)
		OBJSTATE_14, OBJSTATE_15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_683D9)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		OBJSTATE_STUN_LEFT_START, OBJSTATE_STUN_RIGHT_START:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_683D9)
			set_interaction(OBJ_INTERACTION_00)
			_richtertoffen_stunned(state == OBJSTATE_STUN_LEFT_START)
		0x18, 0x19, 0x48, 0x49:
			carried_object_held(state, FRAMESET_683D9)
		0x28, 0x29:
			_richtertoffen_knocked(state + 0x30, 2)
		0x2A:
			# .Flatten: squashed 8 px above Wario's feet for 20 frames ($5a).
			set_object_frameset_ptr(FRAMESET_683D4)
			set_cur(OBJ_STATE_DURATION, 20)
			set_cur(OBJ_STATE, 0x5A)
			set_cur_word(OBJ_Y_POS, wWarioYPos - 8)
		OBJSTATE_SPECIAL_1:
			_richtertoffen_rise()
		OBJSTATE_SPECIAL_2:
			_richtertoffen_fall()
		OBJSTATE_SPECIAL_3:
			_richtertoffen_bounce()
		OBJSTATE_WALK:
			_richtertoffen_walk()
		OBJSTATE_3F:
			_richtertoffen_lie()
		OBJSTATE_40:
			enemy_get_up()
		OBJSTATE_TURN_AROUND:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				func_62908()  # Func_3308
				return
			set_cur(OBJ_STATE, OBJ_INTERACTION_01)  # the source's constant: OBJSTATE_LAND
		OBJSTATE_STUN_LEFT, OBJSTATE_STUN_RIGHT:
			_richtertoffen_stunned(state == OBJSTATE_STUN_LEFT)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x5A:
			_richtertoffen_flattened()
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("CountRichtertoffenFunc state %02x" % state)


## .Default: its own interaction, falling ($30).
func _richtertoffen_default() -> void:
	set_interaction(OBJ_INTERACTION_RICHTERTOFFEN)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_683E1)


## .Walk: 44 frames on the floor (Func_3543; none, it falls: OBJSTATE_STANDING_FALL_START), then a
## leap.
func _richtertoffen_walk() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_richtertoffen_leap_toward_wario()
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return
	store_object_y_from_hpos()


## .asm_40fe9: leaping ($2d) toward Wario (by the screen positions), or, Wario flat, the other way
## from its own.
func _richtertoffen_leap_toward_wario() -> void:
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_1)
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		_richtertoffen_leap(not hdir())
	else:
		_richtertoffen_leap(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))


## .asm_41006: the leap's way and frameset, 22 frames of rise (SFX_066 not simulated).
func _richtertoffen_leap(right: bool) -> void:
	set_hdir(right)
	set_object_frameset_ptr(FRAMESET_683C4 if right else FRAMESET_683C1)
	set_cur(OBJ_STATE_DURATION, 22)
	set_cur(OBJ_VAR_3, 0)


## .JumpRise: along Data_603d0 for its frames, a ceiling 18 px up ending it at once (OBJ_VAR_2 1,
## turned); then falling.
func _richtertoffen_rise() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_richtertoffen_fall_start()
		return
	set_hpos_from_object(-18)
	if (object_probe(COLLISION_UNK3) & 0x0F) != 0:
		set_cur(OBJ_VAR_2, 1)
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)
		_richtertoffen_fall_start()
		return
	apply_obj_y_movement(DATA_603D0)
	_richtertoffen_drift()


## .asm_41044: falling ($2e).
func _richtertoffen_fall_start() -> void:
	set_object_frameset_ptr(FRAMESET_683C7)
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_2)
	set_cur(OBJ_VAR_3, 0)


## The leap's sideways step: a pixel ahead unless a wall 10 px up (8 px left, 7 right) turns it.
func _richtertoffen_drift() -> void:
	var right: bool = hdir()
	set_hpos_from_object(-10, 7 if right else -8)
	if (object_probe(COLLISION_UNK4) & 0x0F) == 0:
		if right:
			move_object_right()
		else:
			move_object_left()
		return
	set_object_frameset_ptr(FRAMESET_683C1 if right else FRAMESET_683C4)
	set_hdir(not right)


## .JumpFall: along Data_603e0 to a floor (Func_352b; water or sand vanishes it), drifting; landed,
## it bounces ($2f, 24 frames; SFX_075 not simulated) and shakes the ground (DoGroundShake 24).
func _richtertoffen_fall() -> void:
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		if wIsInWaterOrSand != 0:
			vanish_object()  # VanishObject2
			return
		apply_obj_y_movement(DATA_603E0)
		_richtertoffen_drift()
		return
	store_object_y_from_hpos()
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_3)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_683D4)
	set_cur(OBJ_STATE_DURATION, 24)
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 24
		wIsWarioGroundShaking = 0


## .FallBounce: along Data_604b0 (its 14th step back to Frameset_683e1); at its end the frames run
## out, then landed (OBJSTATE_LAND).
func _richtertoffen_bounce() -> void:
	if cur(OBJ_VAR_3) == 15:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_cur(OBJ_STATE, OBJSTATE_LAND)
		return
	if cur(OBJ_VAR_3) == 14:
		set_object_frameset_ptr(FRAMESET_683E1)
	apply_obj_y_movement(DATA_604B0)


## .asm_412a4: knocked away (no actions for a frame, the routine bits cleared, OBJ_VAR_2 the
## speed).
func _richtertoffen_knocked(state: int, speed: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, speed)
	set_object_frameset_ptr(FRAMESET_683CA)


## .WobbleLeftStart, .WobbleRightStart: no actions for 15 frames, wobbling ($38, $39).
func _richtertoffen_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 15)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_683D9)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)


## .StunLeft, .StunRight: Func_32ae or Func_32bd while OBJ_VAR_2 lasts, then $0f (the source
## writes OBJ_INTERACTION_RICHTERTOFFEN, $0f, to the state).
func _richtertoffen_stunned(left: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		if left:
			func_62ae5()  # Func_32ae
		else:
			func_62bce()  # Func_32bd
		return
	set_cur(OBJ_STATE, OBJ_INTERACTION_RICHTERTOFFEN)


## .State3f: lying (Func_32ea) for its frames, then getting up ($10).
func _richtertoffen_lie() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_628ea()  # Func_32ea
		return
	set_cur(OBJ_STATE, OBJSTATE_10)


## .State5a: flattened, kept 8 px above Wario's feet on its first frame (pushed 2 px down instead
## while he moves on his own); after 20 frames, no actions for 31 and a leap.
func _richtertoffen_flattened() -> void:
	if cur(OBJ_STATE_DURATION) == 20:
		if wAutoMoveState != 0:
			set_cur_word(OBJ_Y_POS, cur_y() + 2)  # MoveObjectDown_Fast
			return
		set_cur_word(OBJ_Y_POS, wWarioYPos - 8)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 31)
	_richtertoffen_leap_toward_wario()


# --- Mad Scienstein (objects/mad_scienstein.asm) ----------------------------------------------------

## MadSciensteinFunc: .Init on the next update.
func mad_scienstein_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, MAD_SCIENSTEIN_INIT & 0xFFFF)


## .Init: visible, then .Func_44fd9.
func mad_scienstein_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, MAD_SCIENSTEIN_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_mad_scienstein_default()


## .Update's table, by OBJ_STATE (to $5c). It walks half a pixel a frame and, with Wario level and
## within 64 px in front, throws an invisibility potion at him ($5a), turns to hurry back ($2b),
## hurries a pixel a frame ($5b) to a wall or the floor's end, turns ($2c), and stops ($5c);
## Wario behind it turns it ($13). Bumped, it drops a potion on some frames. Knocked, stunned,
## picked up, held, and thrown by the shared routines.
func mad_scienstein_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0B, 0x0C, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2D, 0x2E, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E:
			_mad_scienstein_default()
		0x01:
			set_interaction(OBJ_INTERACTION_01)
			set_cur(OBJ_STATE, OBJSTATE_WALK)
			set_object_frameset_ptr(FRAMESET_68BBE if hdir() else FRAMESET_68BB5)
		0x02, 0x03:
			_mad_scienstein_bumped_start(state == 0x02)
		0x04, 0x05:
			if wTransformation == 0 and wram1[W_EFFECTIVE_POWER_UP] < GARLIC \
					and (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) != 0:
				set_cur(OBJ_STATE, state + 0x04)
			else:
				_mad_scienstein_knocked(state + 0x30, 1)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x08, 0x09:
			_mad_scienstein_wobble_start(state + 0x30)
		OBJSTATE_VANISH_TOUCH:
			if cur(OBJ_ACTION) == 0 or wTransformation != 0 or wram1[W_EFFECTIVE_POWER_UP] >= SUPER_JUMP_SLAM_OVERALLS \
					or (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) == 0:
				vanish_object()  # VanishObject2
				return
			# SFX_014 not simulated
			var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			_mad_scienstein_wobble_start(OBJSTATE_WOBBLE_RIGHT if left_of_wario else OBJSTATE_WOBBLE_LEFT)
		OBJSTATE_0F:
			set_cur(OBJ_STATE, OBJSTATE_3F)
			set_cur(OBJ_STATE_DURATION, 0x64)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			enemy_lie()
		OBJSTATE_10:
			set_cur(OBJ_STATE, OBJSTATE_40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			enemy_get_up()
		OBJSTATE_STANDING_FALL_START:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_68BBE if hdir() else FRAMESET_68BB5)
		OBJSTATE_12:
			enemy_12()
		OBJSTATE_TURN_AROUND_START:
			set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
			set_object_frameset_ptr(FRAMESET_68C1E if hdir() else FRAMESET_68C17)
			set_cur(OBJ_STATE_DURATION, 0x1C)
		OBJSTATE_14, OBJSTATE_15:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68BE8 if hdir() else FRAMESET_68BE3)
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		OBJSTATE_STUN_LEFT_START, OBJSTATE_STUN_RIGHT_START:
			set_cur(OBJ_STATE, state + 0x30)
			set_object_frameset_ptr(FRAMESET_68BE8 if hdir() else FRAMESET_68BE3)
			set_interaction(OBJ_INTERACTION_00)
			_mad_scienstein_stunned(state == OBJSTATE_STUN_LEFT_START)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, FRAMESET_68BE3, FRAMESET_68BE8, [])
		0x28, 0x29:
			_mad_scienstein_knocked(state + 0x30, 2)
		0x2B:
			_mad_scienstein_turning(0x5B, FRAMESET_68BD1, FRAMESET_68BDA, -1)
		0x2C:
			_mad_scienstein_turning(0x5C, FRAMESET_68BFF, FRAMESET_68C08, 63)
		OBJSTATE_WALK:
			_mad_scienstein_walk()
		0x32, 0x33:
			_mad_scienstein_bumped(state == 0x32)
		OBJSTATE_3F:
			enemy_lie()
		OBJSTATE_40:
			enemy_get_up()
		OBJSTATE_TURN_AROUND:
			_mad_scienstein_turn_around()
		OBJSTATE_STUN_LEFT, OBJSTATE_STUN_RIGHT:
			_mad_scienstein_stunned(state == OBJSTATE_STUN_LEFT)
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x5A:
			_mad_scienstein_throw()
		0x5B:
			_mad_scienstein_hurry()
		0x5C:
			if wGroundShakeCounter >= 0x10:
				set_cur(OBJ_STATE, OBJSTATE_1C)
				return
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				func_62908()  # Func_3308
				return
			set_cur(OBJ_STATE, OBJSTATE_LAND)
		_:
			if state > 0x5C or not common_enemy_state(state):
				note_unported("MadSciensteinFunc state %02x" % state)


## .Func_44fd9: harmful again (OBJ_INTERACTION_01), a box -7..6 (bottom -1), falling ($30),
## facing Wario.
func _mad_scienstein_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_collbox_x(-7, 6)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_68BBE if right else FRAMESET_68BB5)


## .Func_45054 (OBJSTATE_WALK): a ground shake pauses it ($1a). Wario level with it (screen rows
## within 32) and within 64 px in front: a potion throw ($5a, 63 frames); behind: a turn ($13).
## Otherwise half a pixel a frame along the floor (none, it falls: $11); a wall 4 px up ahead (7
## px left, 6 right; Func_3513) or the floor's end turns it ($13).
func _mad_scienstein_walk() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, 0x1A)
		return
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy < 0x20 or dy >= 0xE0:
		var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
		if dx >= 0xC0 or dx < 0x40:
			var wario_right: bool = dx >= 0xC0
			if wario_right != hdir():
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
			set_cur(OBJ_STATE, 0x5A)
			set_object_frameset_ptr(FRAMESET_68BF6 if wario_right else FRAMESET_68BED)
			set_cur(OBJ_STATE_DURATION, 63)
			return
	if not _mad_scienstein_step(true):
		set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


## The floor under it held (none: OBJSTATE_STANDING_FALL_START) and a step ahead, half a pixel a
## frame (`slow`) or a pixel; false when the floor's end or a wall stops it.
func _mad_scienstein_step(slow: bool) -> bool:
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return true
	store_object_y_from_hpos()
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if fine_x + 6 >= 0x10 and (process_block_on_right() & 0x0F) == 0:
			return false
		set_hpos_from_object(-4, 6)
		if object_probe(COLLISION_UNK4) != 0:
			return false
		if slow:
			move_object_right_slow()
		else:
			move_object_right()
	else:
		if fine_x < 7 and (process_block_on_left() & 0x0F) == 0:
			return false
		set_hpos_from_object(-4, -7)
		if object_probe(COLLISION_UNK4) != 0:
			return false
		if slow:
			move_object_left_slow()
		else:
			move_object_left()
	return true


## .Func_44e50 ($5a): a ground shake knocks it ($1c). Standing (Func_3308) through the throw: at
## $18 frames left the potion (ObjParams_InvisibilityPotionLeft or _Right; SFX_067 not simulated);
## at the end, turning to hurry back ($2b, 28 frames).
func _mad_scienstein_throw() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, OBJSTATE_1C)
		return
	var duration: int = cur(OBJ_STATE_DURATION)
	if duration == 0x18:
		set_cur(OBJ_STATE_DURATION, duration - 1)
		create_object_at_relative_pos(OBJ_PARAMS_INVISIBILITY_POTION_RIGHT if hdir() else OBJ_PARAMS_INVISIBILITY_POTION_LEFT)
		return
	set_cur(OBJ_STATE_DURATION, duration - 1)
	if duration - 1 != 0:
		func_62908()  # Func_3308
		return
	set_cur(OBJ_STATE, 0x2B)
	set_object_frameset_ptr(FRAMESET_68C2C if hdir() else FRAMESET_68C25)
	set_cur(OBJ_STATE_DURATION, 28)


## .Func_44eaa ($2b) and .Func_44f89 ($2c): standing (Func_3308), turned round with 8 frames left;
## then `state` with its frameset by direction (and `duration`, if not -1).
func _mad_scienstein_turning(state: int, frameset: int, frameset_hdir: int, duration: int) -> void:
	var left: int = cur(OBJ_STATE_DURATION)
	set_cur(OBJ_STATE_DURATION, left - 1)
	if left == 8:
		set_hdir(not hdir())
		return
	if left - 1 != 0:
		func_62908()  # Func_3308
		return
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(frameset_hdir if hdir() else frameset)
	if duration >= 0:
		set_cur(OBJ_STATE_DURATION, duration)


## .Func_44eda ($5b): a ground shake knocks it ($1c); a pixel a frame back to a wall or the floor's
## end, then turning ($2c, 28 frames).
func _mad_scienstein_hurry() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, OBJSTATE_1C)
		return
	if _mad_scienstein_step(false):
		return
	set_cur(OBJ_STATE, 0x2C)
	set_object_frameset_ptr(FRAMESET_68C2C if hdir() else FRAMESET_68C25)
	set_cur(OBJ_STATE_DURATION, 28)


## .Func_45140 and .Func_45186 (OBJSTATE_02, _03): a potion dropped (ObjParams_InvisibilityPotionDrop*)
## unless its frame is 6 to $13 or $19 on; bumped ($32, $33) for 12 frames at speed 2.
func _mad_scienstein_bumped_start(left: bool) -> void:
	var frame: int = cur(OBJ_FRAME)
	if frame < 0x06 or (frame >= 0x14 and frame < 0x19):
		create_object_at_relative_pos(OBJ_PARAMS_INVISIBILITY_POTION_DROP_LEFT if left
				else OBJ_PARAMS_INVISIBILITY_POTION_DROP_RIGHT)
	set_cur(OBJ_STATE, 0x32 if left else 0x33)
	set_object_frameset_ptr(FRAMESET_68BCC if hdir() else FRAMESET_68BC7)
	set_cur(OBJ_STATE_DURATION, 0x0C)
	set_cur(OBJ_VAR_2, 2)


## .Func_4515d and .Func_451bc ($32, $33): bumped (ObjState_BumpLeft, _Right) while OBJ_VAR_2
## lasts; then its frames, and hurrying away the way it faces from the bump ($5b) or turning first
## ($2b, 28 frames).
func _mad_scienstein_bumped(left: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		if left:
			obj_state_bump_left()
		else:
			obj_state_bump_right()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	if hdir() == left:
		set_cur(OBJ_STATE, 0x5B)
		set_object_frameset_ptr(FRAMESET_68BDA if left else FRAMESET_68BD1)
	else:
		set_cur(OBJ_STATE, 0x2B)
		set_object_frameset_ptr(FRAMESET_68C25 if left else FRAMESET_68C2C)
		set_cur(OBJ_STATE_DURATION, 28)


## .Func_452cb (OBJSTATE_TURN_AROUND): a ground shake pauses it ($1a); standing (Func_3308), turned
## with 8 frames left; then walking (OBJSTATE_LAND).
func _mad_scienstein_turn_around() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, 0x1A)
		return
	var left: int = cur(OBJ_STATE_DURATION)
	set_cur(OBJ_STATE_DURATION, left - 1)
	if left == 8:
		set_hdir(not hdir())
		return
	if left - 1 != 0:
		func_62908()  # Func_3308
		return
	set_cur(OBJ_STATE, OBJSTATE_LAND)


## .asm_45388: knocked away (no actions for a frame, the routine bits cleared, OBJ_VAR_2 the
## speed), its frameset by direction.
func _mad_scienstein_knocked(state: int, speed: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, speed)
	set_object_frameset_ptr(FRAMESET_68C14 if hdir() else FRAMESET_68C11)


## .Func_452f7, .Func_45301: no actions for 15 frames, wobbling ($38, $39).
func _mad_scienstein_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 15)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68BE8 if hdir() else FRAMESET_68BE3)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)


## .Func_45202, .Func_4522d: Func_32ae or Func_32bd while OBJ_VAR_2 lasts, then lying ($0f).
func _mad_scienstein_stunned(left: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		if left:
			func_62ae5()  # Func_32ae
		else:
			func_62bce()  # Func_32bd
		return
	set_cur(OBJ_STATE, OBJSTATE_0F)


# --- The Sun and the Moon (objects/sun_moon.asm) -----------------------------------------------------

## SunFunc and MoonFunc (the same code but for their framesets, the Moon's 40-frame turns, and its
## stars for the Sun's flames): kept from despawning (OBJSUBFLAG_UNK_4), no collision with objects,
## a box -8..7 (bottom -4); facing Wario on the next update.
func sun_func() -> void:
	_sun_moon_func(SUN_LOOKS, SUN_CHECK_DIRECTION)


func moon_func() -> void:
	_sun_moon_func(MOON_LOOKS, MOON_CHECK_DIRECTION)


func _sun_moon_func(looks: Array[int], next: int) -> void:
	set_object_frameset_ptr(looks[0])
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .CheckDirection: visible, facing Wario (by the screen positions, $2a on), 50 frames' wait,
## OBJ_VAR_1 0 (following), speed 1.
func sun_check_direction() -> void:
	_sun_moon_check_direction(SUN_LOOKS, SUN_UPDATE)


func moon_check_direction() -> void:
	_sun_moon_check_direction(MOON_LOOKS, MOON_UPDATE)


func _sun_moon_check_direction(looks: Array[int], next: int) -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_object_frameset_ptr(looks[0] if right else looks[1])
	set_cur(OBJ_STATE_DURATION, 50)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 1)


## .Func_472a6 (the Moon's .Func_475c7), by OBJ_VAR_1: following Wario (0), turning right (1, then 3)
## or left (2, then 4) for 35 frames (the Moon's 40), and attacking (5). No actions.
func sun_update() -> void:
	_sun_moon_update(SUN_LOOKS, 35, OBJ_PARAMS_SUN_FLAME_LEFT, OBJ_PARAMS_SUN_FLAME_RIGHT)


func moon_update() -> void:
	_sun_moon_update(MOON_LOOKS, 40, OBJ_PARAMS_MOON_STAR_LEFT, OBJ_PARAMS_MOON_STAR_RIGHT)


func _sun_moon_update(looks: Array[int], turn: int, shot_left: int, shot_right: int) -> void:
	_no_actions_for_one()
	var routine: int = cur(OBJ_VAR_1)  # SunMoon_GeneralMovement may change it; the table entry stands
	match routine:
		0:
			_sun_follow(looks)
		1, 2:
			_sun_moon_general_movement()
			set_object_frameset_ptr(looks[2] if routine == 1 else looks[3])
			set_cur(OBJ_STATE_DURATION, turn)
			set_cur(OBJ_VAR_1, 3 if routine == 1 else 4)
		3, 4:
			_sun_moon_general_movement()
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				return
			set_object_frameset_ptr(looks[0] if routine == 3 else looks[1])
			set_cur(OBJ_STATE_DURATION, 50)
			set_cur(OBJ_VAR_1, 0)
		5:
			_sun_attack(looks, shot_left, shot_right)
		_:
			note_unported("Sun or Moon table entry %d" % routine)


## .Func_4731e: following Wario (SunMoon_GeneralMovement) with a 50-frame wait that a button press
## (not Select or Start) starts again; after it, with Wario within 64 px across and less than 43 below
## (on screen), attacking (OBJ_VAR_1 5, 82 frames).
func _sun_follow(looks: Array[int]) -> void:
	_sun_moon_general_movement()
	if (wJoypadPressed & ~(PAD_SELECT | PAD_START) & 0xFF) != 0:
		set_cur(OBJ_STATE_DURATION, 50)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
	if dx >= 64 and dx < 0xC0:
		return
	if byte(byte(wWarioScreenYPos + 0x2A) - byte(cur(OBJ_SCREEN_Y_POS) + 0x2A)) >= 43:
		return
	set_cur(OBJ_STATE_DURATION, 82)
	set_cur(OBJ_VAR_1, 5)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(looks[4] if hdir() else looks[5])


## .Func_472bb: across toward Wario (SunMoon_XMovement), bobbing along Data_60690 unless a floor is
## under it (Func_352b, not a wc1ca one); a flame (the Moon's star) at 52 frames left
## (ObjParams_SunFlameLeft or _Right; SFX_068 and SFX_06E not simulated); at the end following again.
func _sun_attack(looks: Array[int], shot_left: int, shot_right: int) -> void:
	_sun_moon_x_movement()
	set_hpos_from_object()
	wc1ca = 0
	if object_probe(COLLISION_UNK1) == 0 or wc1ca != 0:
		apply_obj_y_movement(DATA_60690)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE_DURATION, 50)
		set_cur(OBJ_VAR_1, 0)
		set_object_frameset_ptr(looks[0] if hdir() else looks[1])
		return
	if cur(OBJ_STATE_DURATION) == 52:
		create_object_at_relative_pos(shot_right if hdir() else shot_left)


## SunMoon_GeneralMovement: speed 2 off screen (1 once Wario is within 32 px across); across toward
## him while he is more than 32 px away, turning to face him (OBJ_VAR_1 1 or 2); and up or down to
## $2a px above his feet.
func _sun_moon_general_movement() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		set_cur(OBJ_VAR_2, 2)
	var x: int = cur_x()
	if wWarioXPos >= x:
		if wWarioXPos < word(x + 32):
			set_cur(OBJ_VAR_2, 1)
		else:
			_sun_moon_move(true)
		if not hdir():
			set_hdir(true)
			set_cur(OBJ_VAR_1, 1)
	else:
		if wWarioXPos < word(x - 32):
			_sun_moon_move(false)
		else:
			set_cur(OBJ_VAR_2, 1)
		if hdir():
			set_hdir(false)
			set_cur(OBJ_VAR_1, 2)
	var target: int = word(cur_y() + 0x2A)
	if wWarioYPos < target:
		_sun_moon_move_up()
	elif wWarioYPos > target:
		_sun_moon_move_down()


## SunMoon_XMovement: speed 1 on screen, 2 off it; across toward Wario while he is 32 px away or more.
func _sun_moon_x_movement() -> void:
	set_cur(OBJ_VAR_2, 1 if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0 else 2)
	var x: int = cur_x()
	if wWarioXPos >= x:
		if wWarioXPos >= word(x + 32):
			_sun_moon_move(true)
	elif wWarioXPos < word(x - 32):
		_sun_moon_move(false)


## SunMoon_MoveRight and _MoveLeft: OBJ_VAR_2 across unless a wall 12 px ahead, 6 or 20 px up
## (Func_3513), stops it.
func _sun_moon_move(right: bool) -> void:
	set_hpos_from_object(-6, 12 if right else -12)
	if object_probe(COLLISION_UNK4) != 0:
		return
	hYPos = word(cur_y() - 20)
	if object_probe(COLLISION_UNK4) != 0:
		return
	if right:
		move_object_right_by_var2()
	else:
		move_object_left_by_var2()


## SunMoon_MoveDown: OBJ_VAR_2 down unless a floor is under it (Func_352b, not a wc1ca one).
func _sun_moon_move_down() -> void:
	set_hpos_from_object()
	wc1ca = 0
	if object_probe(COLLISION_UNK1) != 0 and wc1ca == 0:
		return
	set_cur_word(OBJ_Y_POS, cur_y() + cur(OBJ_VAR_2))


## SunMoon_MoveUp: OBJ_VAR_2 up unless a ceiling 24 px up (Func_358b) stops it.
func _sun_moon_move_up() -> void:
	set_hpos_from_object(-24)
	if object_probe(COLLISION_UNK3) != 0:
		return
	set_cur_word(OBJ_Y_POS, cur_y() - cur(OBJ_VAR_2))


## SunFlameFunc_Left and _Right: along Data_606e0 or Data_606f0 (ApplyObjXMovement), no collision
## with objects; given a state, it goes out (14 frames).
func sun_flame_func_left() -> void:
	_sun_flame(DATA_606E0, SUN_FLAME_UPDATE, FRAMESET_68FC9)


func sun_flame_func_right() -> void:
	_sun_flame(DATA_606F0, SUN_FLAME_UPDATE, FRAMESET_68FC9)


## MoonStarFunc_Left and _Right: the same with the star's end (Frameset_69024).
func moon_star_func_left() -> void:
	_sun_flame(DATA_606E0, MOON_STAR_UPDATE, FRAMESET_69024)


func moon_star_func_right() -> void:
	_sun_flame(DATA_606F0, MOON_STAR_UPDATE, FRAMESET_69024)


func _sun_flame(table: int, next: int, end_frameset: int) -> void:
	apply_obj_x_movement(table)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_STATE) == 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, next & 0xFFFF)
	set_object_frameset_ptr(end_frameset)
	set_cur(OBJ_STATE_DURATION, 14)


## SunFlameFunc.Update: no actions, then gone.
func sun_flame_update() -> void:
	_no_actions_for_one()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Mizuuo (objects/mizuuo.asm) -------------------------------------------------------------------

## MizuuoFunc: visible, no collision with objects, walking (Frameset_686e5) $30 frames, 8 px left.
func mizuuo_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, MIZUUO_UPDATE_1 & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(FRAMESET_686E5)
	set_cur(OBJ_VAR_1, 0x30)
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()


## .Update1: no actions. A turn's frames counted down, then facing the other way (Frameset_686e5
## left, _686ea right). Otherwise walking a pixel a frame (OBJ_VAR_1 counting down): at its end
## turning ($22 frames of Frameset_68713 or _6871e, OBJ_VAR_1 $60); at $5f, after the turn's first
## step, about to spit ($19 frames of Frameset_686ef or _686f8, .Update2).
func mizuuo_update_1() -> void:
	_no_actions_for_one()
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			return
		set_hdir(not hdir())
		set_object_frameset_ptr(FRAMESET_686EA if hdir() else FRAMESET_686E5)
		return
	if cur(OBJ_VAR_1) == 0x5F:
		set_cur(OBJ_VAR_1, 0x5E)
		set_cur_word(OBJ_UPDATE_FUNCTION, MIZUUO_UPDATE_2 & 0xFFFF)
		set_object_frameset_ptr(FRAMESET_686F8 if hdir() else FRAMESET_686EF)
		set_cur(OBJ_STATE_DURATION, 0x19)
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) == 0:
		set_object_frameset_ptr(FRAMESET_6871E if hdir() else FRAMESET_68713)
		set_cur(OBJ_STATE_DURATION, 0x22)
		set_cur(OBJ_VAR_1, 0x60)
		return
	if hdir():
		move_object_right()
	else:
		move_object_left()


## .Update2: no actions; after its frames spitting ($5d frames of Frameset_686a4 or _686b9, .Update3).
func mizuuo_update_2() -> void:
	_no_actions_for_one()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, MIZUUO_UPDATE_3 & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_686B9 if hdir() else FRAMESET_686A4)
	set_cur(OBJ_STATE_DURATION, 0x5D)


## .Update3 (actions allowed): at $24 frames left its projectile (ObjParams_MizzouProjectileLeft or
## _Right; SFX_07F not simulated); at the end, or given a state (cleared), recovering ($19 frames of
## Frameset_68701 or _6870a, .Update4).
func mizuuo_update_3() -> void:
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_STATE, 0)
	else:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			if cur(OBJ_STATE_DURATION) == 0x24:
				create_object_at_relative_pos(OBJ_PARAMS_MIZZOU_PROJECTILE_RIGHT if hdir() else OBJ_PARAMS_MIZZOU_PROJECTILE_LEFT)
			return
	set_object_frameset_ptr(FRAMESET_6870A if hdir() else FRAMESET_68701)
	set_cur(OBJ_STATE_DURATION, 0x19)
	set_cur_word(OBJ_UPDATE_FUNCTION, MIZUUO_UPDATE_4 & 0xFFFF)


## .Update4: no actions; after its frames walking again (.Update1, Frameset_686e5 or _686ea).
func mizuuo_update_4() -> void:
	_no_actions_for_one()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, MIZUUO_UPDATE_1 & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_686EA if hdir() else FRAMESET_686E5)


## MizzouProjectileFunc_Left and _Right: 2 px a frame across, no collision with objects; a wall at
## it (Func_3513) bursts it. Flying (OBJ_VAR_1 0) along Data_60700; after OBJ_STATE_DURATION frames
## dropping (OBJ_VAR_1 1, Frameset_686d8 or _686db) along Data_60740 until a floor (Func_3543)
## bursts it or water (wIsInWaterOrSand) ends it at once. A state bursts it too: $17 frames of
## Frameset_686de (.Update), then gone.
func mizzou_projectile_func_left() -> void:
	set_cur_word(OBJ_X_POS, cur_x() - 2)  # MoveObjectLeft_Fast
	_mizzou_projectile()


func mizzou_projectile_func_right() -> void:
	set_cur_word(OBJ_X_POS, cur_x() + 2)  # MoveObjectRight_Fast
	_mizzou_projectile()


func _mizzou_projectile() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK4) != 0:
		_mizzou_projectile_burst()
		return
	var table: int = DATA_60700
	if cur(OBJ_VAR_1) != 0:
		if object_probe(COLLISION_DOWN) != 0:
			_mizzou_projectile_burst()
			return
		if wIsInWaterOrSand != 0:
			set_cur(OBJ_FLAGS, 0)
			return
		table = DATA_60740
	apply_obj_y_movement(table)
	if cur(OBJ_STATE) != 0:
		_mizzou_projectile_burst()
		return
	if cur(OBJ_STATE_DURATION) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_1, 1)
	set_object_frameset_ptr(FRAMESET_686DB if hdir() else FRAMESET_686D8)


func _mizzou_projectile_burst() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, MIZZOU_PROJECTILE_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_686DE)
	set_cur(OBJ_STATE_DURATION, 0x17)


# --- The Big Octohon (objects/octohon.asm) ---------------------------------------------------------

## BigOctohonFunc: visible, no collision with objects, a box -9..8 (bottom 8); facing Wario next.
func big_octohon_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_OCTOHON_FACE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-9, 8)
	set_cur(OBJ_COLLBOX_BOTTOM, 8)


## .Func_4a6b9: facing Wario (screen positions, $2a on), then swimming (.Func_4a729).
func big_octohon_face() -> void:
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_OCTOHON_UPDATE & 0xFFFF)
	_big_octohon_swim_start(FRAMESET_69B60 if right else FRAMESET_69B57)


## .asm_4a6df: swimming $ac frames, OBJ_VAR_1 and _2 cleared.
func _big_octohon_swim_start(frameset: int) -> void:
	set_cur(OBJ_STATE_DURATION, 0xAC)
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_VAR_2, 0)
	set_object_frameset_ptr(frameset)


## .Func_4a729: a state $0b or $0c bonks it (as a wall does), $0a is Func_3173, any other hits it
## (.asm_4a711: $3c frames of Frameset_69b7f or _69b88, OBJ_VAR_1 3). Otherwise by OBJ_VAR_1:
## swimming (0), charging (1), recovering (2), hit (3), bonked (4).
func big_octohon_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if state == 0x0B:
			_big_octohon_bonk(FRAMESET_69B69, true)
		elif state == 0x0C:
			_big_octohon_bonk(FRAMESET_69B74, true)
		elif state == 0x0A:
			func_62e57()  # Func_3173
		else:
			set_cur(OBJ_STATE, 0)
			set_object_frameset_ptr(FRAMESET_69B88 if hdir() else FRAMESET_69B7F)
			set_cur(OBJ_STATE_DURATION, 0x3C)
			set_cur(OBJ_VAR_1, 3)
		return
	match cur(OBJ_VAR_1):
		0:
			_big_octohon_swim()
		1:
			if cur(OBJ_STATE_DURATION) != 0:
				set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
				return
			set_cur(OBJ_FRAME_DURATION, 2)
			_big_octohon_charge()
		2:
			_big_octohon_recover()
		3:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) != 0:
				_big_octohon_charge()
				return
			_big_octohon_swim_start(FRAMESET_69B60 if hdir() else FRAMESET_69B57)
		4:
			apply_obj_x_movement(DATA_60D50)
			_big_octohon_recover()


## .asm_4a774: no actions; after its frames turning round (.asm_4a860).
func _big_octohon_recover() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_big_octohon_turn()


## .asm_4a860: facing the other way, swimming again.
func _big_octohon_turn() -> void:
	set_hdir(not hdir())
	_big_octohon_swim_start(FRAMESET_69B60 if hdir() else FRAMESET_69B57)


## .asm_4a78b: 2 px a frame ahead unless a wall 6 px ahead (Func_3513) bonks it.
func _big_octohon_charge() -> void:
	var right: bool = hdir()
	set_hpos_from_object(0, 6 if right else -6)
	if object_probe(COLLISION_UNK4) == 0:
		set_cur_word(OBJ_X_POS, cur_x() + (2 if right else -2))  # MoveObjectRight_Fast, _Left_Fast
		return
	_big_octohon_bonk(FRAMESET_69B74 if right else FRAMESET_69B69, false)


## .asm_4a6eb, .asm_4a6f0: bonked ($43 frames, OBJ_VAR_1 4, OBJ_VAR_2 cleared), harmless again
## (OBJ_INTERACTION_06; SFX_08D not simulated). From a state, `ld [hl], a` clears the state; after a
## wall's probe hl is what ProcessBlock left, for a solid block its handler's ROM address: the write
## only selects a cartridge RAM bank there (assumed for every handler; provisional).
func _big_octohon_bonk(frameset: int, clear_state: bool) -> void:
	if clear_state:
		set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, 0x43)
	set_cur(OBJ_VAR_1, 4)
	set_cur(OBJ_VAR_2, 0)
	set_interaction(OBJ_INTERACTION_06)


## .asm_4a7c2: swimming. With frames left, at their end the turning frameset (Frameset_69b69 or
## _69b74); while they last, Wario within 20 rows and up to 64 px ahead makes it charge ($24 frames of
## Frameset_69bc3 or _69bce, OBJ_VAR_1 1, OBJ_INTERACTION_49). Out of frames, at the sway's $ee-th
## step turning round. Each frame (unless charging) the sway's next step (Data_4a5a9) ahead, or a
## wall 6 px ahead (Func_3513) only counts the step.
func _big_octohon_swim() -> void:
	var duration: int = cur(OBJ_STATE_DURATION)
	if duration == 0:
		if cur(OBJ_VAR_2) == 0xEE:
			_big_octohon_turn()
			return
	else:
		set_cur(OBJ_STATE_DURATION, duration - 1)
		if duration == 1:
			set_object_frameset_ptr(FRAMESET_69B74 if hdir() else FRAMESET_69B69)
		else:
			var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
			if dy < 0x14 or dy >= 0xEC:
				var dx: int = byte(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))
				var ahead: bool = dx >= 0xC0 if hdir() else dx < 0x40
				if ahead:
					set_object_frameset_ptr(FRAMESET_69BCE if hdir() else FRAMESET_69BC3)
					set_cur(OBJ_STATE_DURATION, 0x24)
					set_cur(OBJ_VAR_1, 1)
					set_interaction(OBJ_INTERACTION_49)
					return
	var right: bool = hdir()
	set_hpos_from_object(0, 6 if right else -6)
	if object_probe(COLLISION_UNK4) != 0:
		set_cur(OBJ_VAR_2, byte(cur(OBJ_VAR_2) + 1))
		return
	var step: int = bank_byte(0x12, DATA_4A5A9 + cur(OBJ_VAR_2))
	if step == 0x80:
		set_cur(OBJ_VAR_2, 0)
		step = bank_byte(0x12, DATA_4A5A9)
	set_cur(OBJ_VAR_2, byte(cur(OBJ_VAR_2) + 1))
	set_cur_word(OBJ_X_POS, cur_x() + step if right else cur_x() - step)
