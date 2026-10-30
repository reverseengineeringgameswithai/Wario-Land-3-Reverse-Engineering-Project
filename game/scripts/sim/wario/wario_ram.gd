class_name WarioRam
extends RefCounted
## The game variables Wario's movement reads and writes, named exactly as in the
## disassembly (ElectroDeoxys/warioland3 @560fce6, src/ram/wram.asm and hram.asm) so the
## port can be read side by side with it and checked against oracle traces
## (tools/wl3pc/oracle_wario.py). Bytes hold 0-255 and words 0-65535; signed bytes (the
## collision box) are stored as the CPU stores them.
##
## Research note: docs/02-research/wario-movement.md.

# --- Constants (src/constants/*.asm) ------------------------------------------------------

const PAD_A: int = 1 << 0
const PAD_B: int = 1 << 1
const PAD_SELECT: int = 1 << 2
const PAD_START: int = 1 << 3
const PAD_RIGHT: int = 1 << 4
const PAD_LEFT: int = 1 << 5
const PAD_UP: int = 1 << 6
const PAD_DOWN: int = 1 << 7
const PAD_CTRL_PAD: int = 0xF0

const DIRECTION_LEFT: int = 0
const DIRECTION_RIGHT: int = 1
const LVLEND_GAME_OVER: int = 0x06  # wLevelEndScreen: the hidden figure's fight lost
const LVLEND_EPILOGUE: int = 0x07  # and won

const WST_IDLING: int = 0x00
const WST_WALKING: int = 0x01
const WST_TURNING: int = 0x02
const WST_AIRBORNE: int = 0x04
const WST_LANDING: int = 0x05
const WST_CROUCH_SLIDING: int = 0x06
const WST_ATTACKING: int = 0x07
const WST_ATTACKING_AIRBORNE: int = 0x08
const WST_BUMPING: int = 0x09
const WST_DIVING: int = 0x0A
const WST_SUBMERGED: int = 0x0B
const WST_WATER_SURFACE_IDLING: int = 0x0C
const WST_WATER_SURFACE_MOVING: int = 0x0D
const WST_UNDERWATER_THRUSTING: int = 0x0E
const WST_SWIM_KNOCK_BACK: int = 0x0F
const WST_WATER_STUNG: int = 0x10
const WST_TRYING_SUBMERGE: int = 0x11
const WST_CROUCHING: int = 0x12
const WST_CROUCH_WALKING: int = 0x13
const WST_CROUCH_AIRBORNE: int = 0x14
const WST_STUNG: int = 0x15
const WST_STUNG_RECOVERY: int = 0x16
const WST_PIPE_GOING_DOWN: int = 0x17
const WST_PIPE_GOING_UP: int = 0x18
const WST_ENEMY_BUMPING: int = 0x19
const WST_SLIDING: int = 0x27
const WST_DRAGGED_DOWN: int = 0x32
const WST_FENCE_SHAKE_SLIDING: int = 0x4D
const WST_TELEPORTING: int = 0x33
const WST_WATER_TELEPORTING: int = 0x34
const WST_SAND_FALLING: int = 0x35
const WST_SAND_JUMPING: int = 0x36
const WST_SAND_IDLING: int = 0x37
const WST_SAND_WALKING: int = 0x38
const WST_SAND_TURNING: int = 0x39
const WST_ROLLING: int = 0x28
const WST_ROLLING_AIRBORNE: int = 0x29
const WST_ENTERING_DOOR: int = 0x2C
const WST_VAMPIRE_IDLING: int = 0x9C
const WST_VAMPIRE_WALKING: int = 0x9D
const WST_VAMPIRE_TURNING: int = 0x9E
const WST_VAMPIRE_AIRBORNE: int = 0x9F
const WST_BAT_TRANSFORMING: int = 0xA0
const WST_BAT_IDLING: int = 0xA1
const WST_VAMPIRE_TRANSFORMING: int = 0xA2
const WST_BAT_FLYING: int = 0xA3
const WST_BAT_FALLING: int = 0xA4
const WST_IN_BUBBLE: int = 0xA5
const WST_GRABBING_OWL: int = 0xB8
const WST_OWL_SLOW: int = 0xB9
const WST_OWL_FAST: int = 0xBA
const WST_RELEASING_OWL: int = 0xBB
const WST_FALLING_FROM_OWL: int = 0xBC
const WST_SNOWMAN_START: int = 0xC4
const WST_SNOWMAN_IDLE: int = 0xC5
const WST_SNOWMAN_WALKING: int = 0xC6
const WST_SNOWMAN_TURNING: int = 0xC7
const WST_SNOWMAN_AIRBORNE: int = 0xC8
const WST_SNOWMAN_LANDING: int = 0xC9
const WST_SNOWMAN_BUMPED: int = 0xCA
const WST_SNOWBALL_ROLLING: int = 0xCB
const WST_SNOWBALL_AIRBORNE: int = 0xCC
const WST_SNOWBALL_CRASH: int = 0xCD
const WST_FAN_START: int = 0xD4
const WST_FAN_LIFTING: int = 0xD5
const WST_FAN_TURNING: int = 0xD6
const WST_FAN_SPINNING: int = 0xD7
const WST_FAN_RECOVERING: int = 0xD8
const WST_BALL_START: int = 0xE8
const WST_BALL_BOUNCING: int = 0xE9
const WST_BALL_AIRBORNE: int = 0xEA
const WST_BALL_SHOT: int = 0xEB
const WST_BALL_THROWN: int = 0xEC
const WST_BALL_SENT_UPWARDS: int = 0xED
const WST_BALL_TURNING: int = 0xEE
const WST_LAUNCHED: int = 0xE1
const WST_LAUCH_CRASH: int = 0xE2  # (sic)
const WST_MAGIC_RISING: int = 0xE4
const WST_MAGIC_STOPPING: int = 0xE5
const WST_MAGIC_RECOVERING: int = 0xE6
const WST_SPLIT_HIT: int = 0xD0
const WST_SPLIT_KNOCKED_BACK: int = 0xD1
const WST_SPLITTING: int = 0xD2
const WST_SPLITTING_AIRBORNE: int = 0xD3
const WST_TURNING_INVISIBLE: int = 0x82
const WST_PUFFY_INFLATING: int = 0x83
const WST_PUFFY_RISING: int = 0x84
const WST_PUFFY_TURNING: int = 0x85
const WST_PUFFY_DEFLATING: int = 0x86
const WST_ELECTRIC_START: int = 0x7F
const WST_ELECTRIC: int = 0x80
const WST_ELECTRIC_DIZZY: int = 0x81
const PARTICLE_TREASURE_GLOW: int = 0x0D
const WST_BOUNCY_AIRBORNE: int = 0x92
const WST_GET_TREASURE_START: int = 0x40
const WST_GET_TREASURE_WALK_1: int = 0x41
const WST_GET_TREASURE_TURN_FRONT_1: int = 0x42
const WST_GET_TREASURE_LAUGH: int = 0x43
const WST_GET_TREASURE_TURN_BACK: int = 0x44
const WST_GET_TREASURE_OPEN: int = 0x45
const WST_GET_TREASURE_TURN_WALK: int = 0x46
const WST_GET_TREASURE_WALK_2: int = 0x47
const WST_GET_TREASURE_TURN_FRONT_2: int = 0x48
const WST_GET_TREASURE_LOOK_FRONT: int = 0x49
const WST_GET_TREASURE_CLEAR: int = 0x4A
const WST_FAT_BUMPING: int = 0x76
const WST_FAT_EATING: int = 0x77
const WST_FAT_IDLING: int = 0x78
const WST_FAT_WALKING: int = 0x79
const WST_FAT_TURNING: int = 0x7A
const WST_FAT_AIRBORNE: int = 0x7B
const WST_FAT_LANDING: int = 0x7C
const WST_FAT_SINKING: int = 0x7D
const WST_FAT_RECOVERING: int = 0x7E
const FAT_WARIO_DURATION: int = 420
const WARIO_FAT_GFX: int = 0x09_6000  # WarioFatGfx
const OAM_1742D: int = 0x05_742D
const FRAMESET_SUBMERGED_LEFT_2: int = 0x55A6  # Frameset_155a6 (Func_2ad6a)
const FRAMESET_SUBMERGED_RIGHT_2: int = 0x55AB
const WST_HANGING_RAIL: int = 0xC0
const WARIO_HANG_GFX: int = 0x0B_7800  # WarioHangGfx
const OAM_1FEE05: int = 0x7F_6E05
const WST_ICE_SKATIN_START: int = 0xB0
const WST_ICE_SKATIN: int = 0xB1
const WST_ICE_SKATIN_AIRBORNE: int = 0xB2
const WST_ICE_SKATIN_CRASH: int = 0xB3
const WARIO_BUBBLE_GFX: int = 0x0B_6800  # WarioBubbleGfx
const OAM_1FDB6D: int = 0x7F_5B6D
const WARIO_ICE_SKATIN_PAL: int = 0x4990  # WarioIceSkatinPal
const WST_ON_FIRE: int = 0x60
const WST_ON_FIRE_AIRBORNE: int = 0x61
const WST_HOT: int = 0x62
const WST_HOT_AIRBORNE: int = 0x63
const WST_BURNT: int = 0x64
const WST_GETTING_FLAT_AIRBORNE: int = 0x65
const WST_GETTING_FLAT: int = 0x66
const WST_FLAT_IDLING: int = 0x67
const WST_FLAT_WALKING: int = 0x68
const WST_FLAT_JUMPING: int = 0x69
const WST_FLAT_FALLING: int = 0x6A
const WST_FLAT_STRETCHING: int = 0x6B
const WST_FLAT_SINKING: int = 0x6C
const WST_FLAT_STRETCHING_UNDERWATER: int = 0x6D
const WST_FLAT_SQUISHED: int = 0x6E
const WST_FLAT_SQUISHED_LIFTING: int = 0x6F
## wTouchState and wStingTouchState: what touching an object does while transformed.
const TOUCH_VULNERABLE: int = 1
const TOUCH_BUMP: int = 2
const TOUCH_ATTACK: int = 3
const TOUCH_VANISH: int = 4
const TOUCH_PASS_THROUGH: int = 5
const HOT_WARIO_DURATION: int = 600
const HOT_WARIO_TRANSITION_DURATION: int = 300
const WST_GETTING_WRAPPED_IN_STRING: int = 0x70
const WST_BALL_O_STRING: int = 0x71
const WST_BALL_O_STRING_AIRBORNE: int = 0x72
const WST_BALL_O_STRING_KNOCK_BACK: int = 0x73
const WST_GETTING_UNWRAPPED_IN_STRING: int = 0x74
const WST_BALL_O_STRING_DIZZY: int = 0x75
const WST_LADDER_CLIMBING: int = 0x3A
const WST_LADDER_IDLING: int = 0x3B
const WST_LADDER_SHAKE_SLIDING: int = 0x3C
const WST_GROUND_SHAKE_STUNNED: int = 0x2B
const WST_GRAB_IDLING: int = 0x1F
const WST_PICKED_UP: int = 0x2A
const NUM_WIGGLES_TO_ESCAPE: int = 6
const MAX_PICKED_UP_FRAME_COUNTER: int = 32  # MAX_PICKEB_PAD_UPRAME_COUNTER in the disassembly
const WST_GETTING_OFF_LADDER: int = 0x3D
const WST_LADDER_SLIDING: int = 0x3E
const WST_LADDER_SCRATCHING: int = 0x4C
const WST_ZOMBIE_IDLING: int = 0x87
const WST_ZOMBIE_WALKING: int = 0x88
const WST_ZOMBIE_TURNING: int = 0x89
const WST_ZOMBIE_AIRBORNE: int = 0x8A
const WST_ZOMBIE_LANDING: int = 0x8B
const WST_ZOMBIE_SLIPPING_THROUGH_FLOOR: int = 0x8C
const WST_ZOMBIE_RECOVERING: int = 0x8D
const WST_ZOMBIE_KNOCK_BACK: int = 0x8E
const WST_ZOMBIE_WRITHING: int = 0x8F
const WST_SMASH_ATTACKING: int = 0x1A
const WST_PICKING_UP: int = 0x1E
const WST_GRAB_WALKING: int = 0x20
const WST_GRAB_AIRBORNE: int = 0x21
const WST_THROW_CHARGING: int = 0x22
const WST_THROW_FULLY_CHARGED: int = 0x23
const WST_THROWING: int = 0x24
const WST_THROWING_AIRBORNE: int = 0x25
const WST_GRAB_SMASH_ATTACKING: int = 0x26
const WST_GRAB_SLIPPING: int = 0x3F
## wGrabState: the state in bits 0-3, the flags above.
const GRAB_PICK_UP: int = 0x1
const GRAB_UNK_02: int = 0x2
const GRAB_IDLE: int = 0x3
const GRAB_CHARGE_THROW: int = 0x4
const GRAB_THROW_FULLY_CHARGED: int = 0x5
const GRAB_HOLD_FULL_CHARGE: int = 0x6
const GRAB_THROW: int = 0x7
const GRAB_FULL_CHARGE: int = 1 << 6
const GRAB_HEAVY: int = 1 << 7
const GRAB_FLAGS_MASK: int = 0xF0
const GRAB_STATE_MASK: int = 0x0F
const THROW_CHARGE_FRAMES_LIGHT: int = 0x1E
const THROW_CHARGE_FRAMES_HEAVY: int = 0x3C
const GRAB_GLOVE: int = 4
const SUPER_GRAB_GLOVES: int = 9
const WST_SLIPPING: int = 0x30
const WST_CROUCH_SLIPPING: int = 0x31
const WST_BOUNCY_START: int = 0x90
const WST_BOUNCY_FLOOR: int = 0x91
const WST_BOUNCY_CEILING: int = 0x93
const WST_BOUNCY_UPSIDE_DOWN: int = 0x94
const WST_BOUNCY_UPSIDE_DOWN_LANDING: int = 0x95
const WST_BOUNCY_LAST_BOUNCE: int = 0x96
const WST_CRAZY_SPINNING: int = 0x97
const WST_CRAZY_DIZZY: int = 0x98
const WST_CRAZY: int = 0x99
const WST_CRAZY_TURNING: int = 0x9A
const WST_CRAZY_AIRBORNE: int = 0x9B
const WST_BLIND_IDLING: int = 0xDC
const WST_BLIND_WALKING: int = 0xDD
const WST_BLIND_TURNING: int = 0xDE
const WST_BLIND_AIRBORNE: int = 0xDF

const JUMP_VEL_KNOCK_BACK: int = 1
const JUMP_VEL_NORMAL: int = 2
const JUMP_VEL_HIGH_JUMP: int = 3
const JUMP_VEL_BOUNCY_JUMP: int = 4
const JUMP_VEL_BOUNCY_HIGH_JUMP: int = 5
const BOUNCY_WARIO_DURATION: int = 900
const MAX_JUMP_VEL_INDEX: int = 0x27
const FALLING_JUMP_VEL_INDEX: int = 0x18
const NUM_SLEEPING_IDLE_CYCLES: int = 7
const MAX_ATTACK_COUNTER: int = 0x30
const CHARGE_ATTACK_COUNTER: int = 0x2B  # below it the charge moves

const LEAD_OVERALLS: int = 1
const HEAD_SMASH_HELMET: int = 3
const GARLIC: int = 5
const SUPER_JUMP_SLAM_OVERALLS: int = 6
const HIGH_JUMP_BOOTS: int = 7
const SWIMMING_FLIPPERS: int = 2
const PRINCE_FROGS_GLOVES: int = 8
## wWaterInteraction
const SUBMERSIBLE_WATER: int = 1
const NON_SUBMERSIBLE_WATER: int = 2
## wWaterCurrent, wCurWaterCurrent, and wLastWaterCurrent's low nibble (its high one counts down)
const CURRENT_RIGHT: int = 1 << 0
const CURRENT_LEFT: int = 1 << 1
const CURRENT_UP: int = 1 << 2
const CURRENT_DOWN: int = 1 << 3

const TRANSFORMATION_HOT_WARIO: int = 0xC1
const TRANSFORMATION_FLAT_WARIO: int = 0x42
const TRANSFORMATION_ICE_SKATIN: int = 0x4D  # ID $0d | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_RAIL: int = 0x0F
const TRANSFORMATION_BLIND: int = 0x53  # TRANSFORMATION_BLIND_ID $13 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_ZOMBIE_WARIO: int = 0x48  # ID $08 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_OWL_WARIO: int = 0x0E
const TRANSFORMATION_CRAZY_WARIO: int = 0x0A
const TRANSFORMATION_SNOWMAN_WARIO: int = 0x50  # ID $10 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATIONF_PERSISTENT: int = 1 << 6
const TRANSFORMATION_VAMPIRE_WARIO: int = 0x4B  # ID $0b | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_BALL_O_STRING_WARIO: int = 0xC3
const TRANSFORMATION_BOUNCY_WARIO: int = 0x09
const TRANSFORMATION_FAT_WARIO: int = 0x84
const TRANSFORMATION_PUFFY_WARIO: int = 0x07
const TRANSFORMATION_SPLIT: int = 0x51  # ID $11 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_BUBBLE: int = 0x4C  # ID $0c | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_FAN: int = 0x12  # TRANSFORMATION_FAN_ID, no flags
const TRANSFORMATION_MAGIC: int = 0x55  # ID $15 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_BALL: int = 0x56  # ID $16 | TRANSFORMATIONF_PERSISTENT
const TRANSFORMATION_LAUNCHED: int = 0x54  # ID $14 | TRANSFORMATIONF_PERSISTENT

const COLLISION_DOWN: int = 1 << 0
const COLLISION_UNK1: int = 1 << 1
const COLLISION_UNK2: int = 1 << 2
const COLLISION_UNK3: int = 1 << 3
const COLLISION_UNK4: int = 1 << 4
const COLLISION_UNK5: int = 1 << 5
const COLLISION_UNK6: int = 1 << 6
const COLLISION_UNK7: int = 1 << 7
const COLLISION_ROBO_MOUSE_BREAK: int = 2
const COLLISION_ROBO_MOUSE_FREE: int = 3

const RIGHT_SLOPE: int = 1 << 0
const LEFT_SLOPE: int = 1 << 1
const ON_SLOPE: int = 0x10
const LADDER_COLLISION: int = 1
const LADDER_UNDERNEATH: int = 2

const ROOMTRANSITION_PIPE: int = 1
const ROOMTRANSITION_DOOR: int = 2
const ROOMTRANSITION_4: int = 4
const ROOMTRANSITION_5: int = 5
const ROOMTRANSITION_UNDERWATER_DOOR: int = 6
const ROOMTRANSITIONF_DOOR: int = 1 << 5
const ROOMTRANSITIONF_RELOAD_OBJECTS: int = 1 << 6
const ROOMTRANSITIONF_DELAY: int = 1 << 7

const CAM_SCROLLING_MASK: int = 0x0F  # CAM_YSCROLL | CAM_FREE | CAM_XSCROLL1 | CAM_XSCROLL2 | CAM_TRANSITIONS
const CAM_YSCROLL: int = 0
const CAM_FREE: int = 1 << 0
const CAM_XSCROLL2: int = 1 << 2
const CAM_TRANSITIONS: int = 1 << 3
const CAM_BORDER_RIGHT: int = 1 << 4
const CAM_BORDER_LEFT: int = 1 << 5
const CAM_BORDER_UP: int = 1 << 6
const CAM_BORDER_DOWN: int = 1 << 7
const HIDDEN_FIGURE_CAMCONFIG: int = CAM_XSCROLL2 | CAM_TRANSITIONS | CAM_BORDER_RIGHT | CAM_BORDER_LEFT
const CAMERA_BORDER_W: int = 0x20  # CAMERA_BORDER_RIGHT_W, _LEFT_W, _UPPER_H, _LOWER_H
const LEVEL_EDGE_UPDATE_RIGHT: int = 1 << 0
const LEVEL_EDGE_UPDATE_LEFT: int = 1 << 1
const LEVEL_EDGE_UPDATE_UP: int = 1 << 2
const LEVEL_EDGE_UPDATE_DOWN: int = 1 << 3
const SCREEN_WIDTH_PX: int = 160  # src/constants/hardware.inc
const SCREEN_HEIGHT_PX: int = 144
const TILEMAP_WIDTH_PX: int = 256
const TILEMAP_HEIGHT_PX: int = 256
const OAM_X_OFS: int = 8
const OAM_Y_OFS: int = 16
const FLOOR_TRANSITION_DOWN: int = 1 << 2
const FLOOR_TRANSITION_UP: int = 1 << 3

# Framesets the ported states write to wWarioFramesetPtr (bank "Wario OAM 1").
const FRAMESET_IDLE_LEFT: int = 0x4252  # Frameset_14252
const FRAMESET_IDLE_RIGHT: int = 0x425F  # Frameset_1425f
const FRAMESET_WALK_LEFT: int = 0x49B4  # Frameset_149b4
const FRAMESET_WALK_RIGHT: int = 0x49C5  # Frameset_149c5
const FRAMESET_TURN_LEFT: int = 0x4CBE  # Frameset_14cbe
const FRAMESET_TURN_RIGHT: int = 0x4CC5  # Frameset_14cc5
const FRAMESET_SMASH_LEFT: int = 0x5F8E  # Frameset_15f8e
const FRAMESET_SMASH_RIGHT: int = 0x5F91  # Frameset_15f91
const FRAMESET_AIRBORNE_LEFT: int = 0x5F94  # Frameset_15f94
const FRAMESET_AIRBORNE_RIGHT: int = 0x5F97  # Frameset_15f97
const FRAMESET_LAND_LEFT: int = 0x5F9A  # Frameset_15f9a
const FRAMESET_LAND_RIGHT: int = 0x5FA1  # Frameset_15fa1
const FRAMESET_ATTACK_LEFT: int = 0x51E4  # Frameset_151e4
const FRAMESET_ATTACK_RIGHT: int = 0x51FD  # Frameset_151fd
const FRAMESET_GARLIC_ATTACK_LEFT: int = 0x521C  # Frameset_1521c
const FRAMESET_GARLIC_ATTACK_RIGHT: int = 0x522D  # Frameset_1522d
# Frameset_15216 and Frameset_15219 serve two states the opposite way round: attacking airborne
# uses 15216 facing left and 15219 facing right; bumping uses 15216 facing right and 15219 left.
const FRAMESET_15216: int = 0x5216
const FRAMESET_15219: int = 0x5219
const FRAMESET_GARLIC_AIR_ATTACK_LEFT: int = 0x523E  # Frameset_1523e
const FRAMESET_GARLIC_AIR_ATTACK_RIGHT: int = 0x5249  # Frameset_15249
const FRAMESET_ROLL_BUMP_LEFT: int = 0x5F7F  # Frameset_15f7f
const FRAMESET_ROLL_BUMP_RIGHT: int = 0x5F70  # Frameset_15f70
const FRAMESET_CROUCH_WALK_LEFT: int = 0x4A26  # Frameset_14a26
const FRAMESET_CROUCH_WALK_RIGHT: int = 0x4A2F  # Frameset_14a2f
const FRAMESET_CROUCH_LEFT: int = 0x4A38  # Frameset_14a38
const FRAMESET_CROUCH_RIGHT: int = 0x4A3B  # Frameset_14a3b
const FRAMESET_SLIDE_LEFT: int = 0x6708  # Frameset_16708
const FRAMESET_SLIDE_RIGHT: int = 0x671D  # Frameset_1671d
const FRAMESET_ROLL_LEFT: int = 0x66E6  # Frameset_166e6
const FRAMESET_ROLL_RIGHT: int = 0x66F7  # Frameset_166f7
const FRAMESET_LADDER_CLIMB: int = 0x58D6  # Frameset_158d6
const FRAMESET_LADDER_IDLE_LEFT: int = 0x5900  # Frameset_15900
const FRAMESET_LADDER_IDLE_RIGHT: int = 0x58FD  # Frameset_158fd
const FRAMESET_LADDER_SCRATCH_LEFT: int = 0x5903  # Frameset_15903
const FRAMESET_LADDER_SCRATCH_RIGHT: int = 0x5924  # Frameset_15924
const FRAMESET_LADDER_SLIDE: int = 0x5945  # Frameset_15945
const FRAMESET_DOOR_ENTER_LEFT: int = 0x4D0B  # Frameset_14d0b
const FRAMESET_DOOR_ENTER_RIGHT: int = 0x4D10  # Frameset_14d10
const FRAMESET_DOOR_THROUGH: int = 0x4D15  # Frameset_14d15
const FRAMESET_DOOR_OUT: int = 0x4D18  # Frameset_14d18
const FRAMESET_PIPE: int = 0x4CF6  # Frameset_14cf6, going through a pipe
# Wario's graphics the ported states name, as bank << 16 | pointer: the tile sets they write to
# wDMASourceBank:wDMASourcePtr, the OAM tables to wWarioOAMBank:wWarioOAMPtr ("Wario OAM 1"), and the
# palettes ("Wario Palettes", bank 3) to wWarioPalsPtr. Decoded by tools/wl3pc/extract/wario_sprites.py.
const WARIO_IDLE_GFX: int = 0x04_4000  # WarioIdleGfx
const WARIO_WALK_GFX: int = 0x04_4800  # WarioWalkGfx
const WARIO_ATTACK_GFX: int = 0x04_5800  # WarioAttackGfx
const WARIO_LADDER_GFX: int = 0x04_6800  # WarioLadderGfx
const WARIO_AIRBORNE_GFX: int = 0x04_7800  # WarioAirborneGfx
const WARIO_SWIM_GFX: int = 0x04_6000  # WarioSwimGfx
const OAM_15254: int = 0x05_5254
const FRAMESET_SWIM_SINK_LEFT: int = 0x55A0  # Frameset_155a0
const FRAMESET_SWIM_SINK_RIGHT: int = 0x55A3  # Frameset_155a3
const FRAMESET_SWIM_DIVE_LEFT: int = 0x5569  # Frameset_15569
const FRAMESET_SWIM_DIVE_RIGHT: int = 0x5573  # Frameset_15573
const FRAMESET_SWIM_LEFT: int = 0x5576  # Frameset_15576
const FRAMESET_SWIM_RIGHT: int = 0x558B  # Frameset_1558b
const FRAMESET_WATER_SURFACE_LEFT: int = 0x5554  # Frameset_15554
const FRAMESET_WATER_SURFACE_RIGHT: int = 0x555B  # Frameset_1555b
const FRAMESET_THRUST_GLOVES_LEFT: int = 0x5562  # Frameset_15562
const FRAMESET_THRUST_GLOVES_RIGHT: int = 0x556C  # Frameset_1556c
const FRAMESET_THRUST_LEFT: int = 0x55BE  # Frameset_155be
const FRAMESET_THRUST_RIGHT: int = 0x55C5  # Frameset_155c5
const FRAMESET_TRYING_SUBMERGE_LEFT: int = 0x55B0  # Frameset_155b0
const FRAMESET_TRYING_SUBMERGE_RIGHT: int = 0x55B7  # Frameset_155b7
const WARIO_SLIDE_GFX: int = 0x09_5000  # WarioSlideGfx
const OAM_14000: int = 0x05_4000
const OAM_1426C: int = 0x05_426C
const OAM_14A82: int = 0x05_4A82
const OAM_14D1B: int = 0x05_4D1B
const OAM_155CC: int = 0x05_55CC
const OAM_15955: int = 0x05_5955
const OAM_1644A: int = 0x05_644A
const OAM_16E9D: int = 0x05_6E9D  # Flat Wario (SetState_FlatAirborne)
const OAM_1606A: int = 0x05_606A  # picking up, throwing
const WARIO_CRAZY_GFX: int = 0x0B_5000  # WarioCrazyGfx
const WARIO_PUFFY_GFX: int = 0x09_7000  # WarioPuffyGfx
const WARIO_SNOWBALL_GFX: int = 0x7A_4800  # WarioSnowballGfx (split Wario too)
const WARIO_SNOWMAN_GFX: int = 0x7A_4000  # WarioSnowmanGfx
const WARIO_FAN_GFX: int = 0x7A_5000  # WarioFanGfx
const WARIO_MAGIC_GFX: int = 0x7A_6000  # WarioMagicGfx
const WARIO_BALL_GFX: int = 0x7A_6800  # WarioBallGfx
const WARIO_LAUNCH_GFX: int = 0x7A_5800  # WarioLaunchGfx
const WARIO_BAT_GFX: int = 0x0B_5800  # WarioBatGfx
const WARIO_VAMPIRE_GFX: int = 0x0B_6000  # WarioVampireGfx
const OAM_1FCCD5: int = 0x7F_4CD5  # Crazy Wario
const OAM_1DC93F: int = 0x77_493F  # Puffy Wario (its framesets in the same bank)
const OAM_1FFA12: int = 0x7F_7A12  # split Wario
const OAM_1FD031: int = 0x7F_5031  # the bat (and the vampire turning into one)
const OAM_1FD498: int = 0x7F_5498  # Vampire Wario
const OAM_1FD87C: int = 0x7F_587C  # Wario in a bubble
const OAM_1FDDB4: int = 0x7F_5DB4  # Owl Wario
const OAM_1FEEC7: int = 0x7F_6EC7  # Snowman Wario
const OAM_1FF64A: int = 0x7F_764A  # the snowball
const OAM_1DC000: int = 0x77_4000  # Fan Wario ("Wario OAM 3")
const OAM_1DCD60: int = 0x77_4D60  # Magic Wario
const OAM_1DCFF1: int = 0x77_4FF1  # Wario as a ball
const OAM_1DC449: int = 0x77_4449  # launched
const WARIO_THROW_GFX: int = 0x04_7000  # WarioThrowGfx
const WARIO_PALETTES_BANK: int = 0x03
const WARIO_DEFAULT_PAL: int = 0x4800  # WarioDefaultPal
const WARIO_INVISIBLE_PAL: int = 0x4810  # WarioInvisiblePal
const TRANSFORMATION_INVISIBLE_WARIO: int = 0x06  # TRANSFORMATION_INVISIBLE_WARIO_ID, no flags
const TRANSFORMATION_ELECTRIC: int = 0x85  # TRANSFORMATION_ELECTRIC_ID | TRANSFORMATIONF_SUPER_SMASH
const WARIO_ELECTRIC_GFX: int = 0x09_6800  # WarioElectricGfx
const OAM_1790E: int = 0x05_790E
const WARIO_ELECTRIC_PAL: int = 0x4870  # WarioElectricPal
const FRAMESET_ELECTRIC_STRUCK_LEFT: int = 0x7B79  # Frameset_17b79
const FRAMESET_ELECTRIC_STRUCK_RIGHT: int = 0x7B76  # Frameset_17b76
const FRAMESET_ELECTRIC_LEFT: int = 0x7B8D  # Frameset_17b8d
const FRAMESET_ELECTRIC_RIGHT: int = 0x7B7C  # Frameset_17b7c
const FRAMESET_ELECTRIC_DIZZY_LEFT: int = 0x7B9E  # Frameset_17b9e
const FRAMESET_ELECTRIC_DIZZY_RIGHT: int = 0x7BAD  # Frameset_17bad
const WARIO_CLEAR_GFX: int = 0x0B_7000  # WarioClearGfx
const OAM_1FC000: int = 0x7F_4000
const OAM_1FC31B: int = 0x7F_431B
const WARIO_OAM_2: int = 0x7F_0000  # "Wario OAM 2": framesets keyed WARIO_OAM_2 | pointer
const WARIO_OAM_3: int = 0x77_0000  # "Wario OAM 3"
const WARIO_ZOMBIE_GFX: int = 0x0B_4000  # WarioZombieGfx
const OAM_1FC48B: int = 0x7F_448B  # Zombie Wario
const WARIO_ZOMBIE_PAL: int = 0x4890  # WarioZombiePal, and seven more after it (ZombieRecovering)
const WARIO_BOUNCY_GFX: int = 0x0B_4800  # WarioBouncyGfx
const OAM_1FC95E: int = 0x7F_495E  # Bouncy Wario
const WARIO_BOUNCY_PAL: int = 0x4910  # WarioBouncyPal
const WARIO_BOUNCY_RED_PAL: int = 0x4920  # WarioBouncyRedPal
const WARIO_SPLIT_PAL: int = 0x49E0  # WarioSplitPal
const WARIO_VAMPIRE_PAL: int = 0x4950  # WarioVampirePal
const WARIO_BUBBLE_PAL: int = 0x4980  # WarioBubblePal
const WARIO_SNOWMAN_PAL: int = 0x49A0  # WarioSnowmanPal
const WARIO_MAGIC_PAL: int = 0x49B0  # WarioMagicPal
const WARIO_BALL_PAL: int = 0x49C0  # WarioBallPal
const WARIO_BALL_SHOT_PAL: int = 0x49D0  # WarioBallShotPal
const FRAMESET_TREASURE_TURN_FRONT_LEFT: int = 0x446A  # Frameset_1fc46a
const FRAMESET_TREASURE_TURN_FRONT_RIGHT: int = 0x4461  # Frameset_1fc461
const FRAMESET_TREASURE_LAUGH: int = 0x42AB  # Frameset_1fc2ab
const FRAMESET_TREASURE_TURN_BACK_LEFT: int = 0x4446  # Frameset_1fc446
const FRAMESET_TREASURE_TURN_BACK_RIGHT: int = 0x4439  # Frameset_1fc439
const FRAMESET_TREASURE_OPEN: int = 0x42C4  # Frameset_1fc2c4
const FRAMESET_TREASURE_TURN_WALK_LEFT: int = 0x445A  # Frameset_1fc45a
const FRAMESET_TREASURE_TURN_WALK_RIGHT: int = 0x4453  # Frameset_1fc453
const FRAMESET_TREASURE_LOOK_FRONT: int = 0x430D  # Frameset_1fc30d
const WARIO_HOT_GFX: int = 0x09_4000  # WarioHotGfx
const WARIO_BURNT_GFX: int = 0x09_4800  # WarioBurntGfx
const OAM_1673C: int = 0x05_673C
const OAM_16B6C: int = 0x05_6B6C
const WARIO_ON_FIRE_PAL: int = 0x4820  # WarioOnFirePal
const WARIO_HOT_1_PAL: int = 0x4830
const WARIO_HOT_2_PAL: int = 0x4840
const WARIO_HOT_3_PAL: int = 0x4850
const FRAMESET_SET_ON_FIRE_LEFT: int = 0x6B38  # Frameset_16b38
const FRAMESET_SET_ON_FIRE_RIGHT: int = 0x6B49  # Frameset_16b49
const FRAMESET_ON_FIRE_LEFT: int = 0x6B14  # Frameset_16b14
const FRAMESET_ON_FIRE_RIGHT: int = 0x6B1D  # Frameset_16b1d
const FRAMESET_HOT_LEFT: int = 0x6B26  # Frameset_16b26
const FRAMESET_HOT_RIGHT: int = 0x6B2F  # Frameset_16b2f
const FRAMESET_BURNT_LEFT: int = 0x6E47  # Frameset_16e47
const FRAMESET_BURNT_RIGHT: int = 0x6E72  # Frameset_16e72
const WARIO_STRING_GFX: int = 0x09_5800  # WarioStringGfx
const WARIO_DIZZY_GFX: int = 0x04_5000  # WarioDizzyGfx
const OAM_171C0: int = 0x05_71C0
const OAM_17BBC: int = 0x05_7BBC
const WARIO_STRING_PAL: int = 0x4860  # WarioStringPal
const FRAMESET_GETTING_WRAPPED: int = 0x7414  # Frameset_17414
const FRAMESET_BALL_O_STRING_LEFT: int = 0x741F  # Frameset_1741f
const FRAMESET_BALL_O_STRING_RIGHT: int = 0x73FE  # Frameset_173fe
const FRAMESET_BALL_O_STRING_KNOCK_BACK: int = 0x742A  # Frameset_1742a
const FRAMESET_GETTING_UNWRAPPED: int = 0x7409  # Frameset_17409
const FRAMESET_DIZZY: int = 0x7CE2  # Frameset_17ce2
const OAM_17CF7: int = 0x05_7CF7  # turning invisible
const ROOMTRANSITION_MASK: int = 0x0F
const ROOMTRANSITION_FLAGS_MASK: int = 0x10 | ROOMTRANSITIONF_DOOR | ROOMTRANSITIONF_RELOAD_OBJECTS | ROOMTRANSITIONF_DELAY
const ROOMTRANSITION_GOLF: int = 3
const ROOMTRANSITION_TELEPORT: int = 7
const ROOMTRANSITIONF_DELAY_F: int = 7

# --- Variables recorded by oracle Wario traces --------------------------------------------

var wGlobalCounter: int = 0
var wJoypadDown: int = 0
var wJoypadPressed: int = 0
var wState: int = 0
var wSubState: int = 0
var wLevelRoomID: int = 0
var wRoom: int = 0
var wCameraConfigFlags: int = 0
var wCameraYDelta: int = 0
var wCameraXDelta: int = 0
var wCollisionPoints: int = 0
var wRoomTransitionParam: int = 0
var wWaterInteraction: int = 0
var wc0dc: int = 0
var wIsOnSlipperyGround: int = 0
var wWarioSlopeInteraction: int = 0
var wUnused_c18d: int = 0
var wWarioAnimationEnded: int = 0
var wFloorTransitionTimer: int = 0
var wFloorTransitionDir: int = 0
var wLadderInteraction: int = 0
var wIsNearFence: int = 0
var wIsInAirCurrent: int = 0
var wc1ca: int = 0
var wLevel: int = 0
var wPowerUpLevel: int = 0
var wWarioYPos: int = 0
var wWarioXPos: int = 0
var wFrameDuration: int = 0
var wAnimationFrame: int = 0
var wDirection: int = 0
var wCollisionBoxTop: int = 0
var wCollisionBoxBottom: int = 0
var wCollisionBoxLeft: int = 0
var wCollisionBoxRight: int = 0
var wIsFloorTransition: int = 0
## wMultiBlockParam: the direction a multi-block breakable passes its break on (1 right, 2 left,
## 3 up a row, 4 down a row) in bits 0-2; bit 4 while ProcessMultiBlock runs the chain.
var wMultiBlockParam: int = 0
var wJumpVelTable: int = 0
var wJumpVelIndex: int = 0
var wDoFullJump: int = 0
var wJumpingUpwards: int = 0
var wFloor: int = 0
var wWarioFramesetPtr: int = 0
var wWarioFrame: int = 0
var wWarioAttributes: int = 0
var wWarioPalsPtr: int = 0
var wDMASourceBank: int = 0
var wDMASourcePtr: int = 0
var wWarioOAMBank: int = 0
var wWarioOAMPtr: int = 0
var wInvisibleFrame: int = 0
var wDayNight: int = 0
var wccec: int = 0
var wLevelEndScreen: int = 0
var wObjectGroup: int = 0
var wAutoMoveState: int = 0
var wShootGoals: int = 0  # in "Level Objects WRAM" ($d144), traced
var wBossState: int = 0  # cleared by a room transition and the Shoot goal counter; read by bosses (not ported)
var wSwitchState: int = 0  # the switch block as it was when last hit
var wSwitchStateUpdated: int = 0  # the switchable blocks change at the next room start
## The direction of the object being checked (ProcessInteractions; SetState_IceSkatinStart reads it).
var wObjDirection: int = 0
var wPickedUpWiggleCounter: int = 0
var wPickedUpFrameCounter: int = 0
var wIsMinigameCleared: int = 0
var wTouchState: int = 0
var wStingTouchState: int = 0
var wNumCoins: int = 0
var wNumMusicalCoins: int = 0
var wKeyAndTreasureFlags: int = 0
var wTreasuresCollected7: int = -1  # wTreasuresCollected + 7 (WRAMX bank 2), traced; -1 untraced
var wceef: int = 0  # bits 2-5: the level is resumed from a save (traced; StartRoom_FromLevelStart)
var wNumCollectedTreasures: int = 0  # BCD, big-endian as traced (golf's price and holes)
var wLanguage: int = 0  # 0 Japanese (golf's coin message)
var wTimer: int = 0
var wResetDisabled: int = 0
var wTransformationDuration: int = 0  # big-endian, as the game keeps it
## Water (WL3-034): the surface's bobbing, the thrust's direction, which way a wall or the surface
## stopped the swim (wc0e1, by joypad bit), and the currents: this frame's, the one being followed,
## and the last one, lingering (its high nibble counts down).
var wWaterSurfaceFloatingCounter: int = 0
var wSwimmingDirectionInput: int = 0
var wc0e0: int = 0
var wc0e1: int = 0
var wIsBossBattle: int = 0
var wWaterCurrent: int = 0
var wLastWaterCurrent: int = 0
var wCurWaterCurrent: int = 0
## The room's animated tiles and palette cycle (LevelSim runs them; WL3-037).
var wAnimatedTilesGroup: int = 0
var wAnimatedTilesFrameDuration: int = 0
var wAnimatedTilesGfx: int = 0
var wAnimatedTilesFrame: int = 0
var wAnimatedTilesFrameCount: int = 0
var wRoomPalCycle: int = 0
var wRoomPalCycleDuration: int = 0
var wRoomPalCycleCounter: int = 0
var wRoomPalCycleIndex: int = 0
var wRoomAnimatedTilesEnabled: int = 0
var wRoomAnimatedPalsEnabled: int = 0
## The particle UpdateParticles updated last finished its animation (UpdateParticleAnimation).
var wCurParticleAnimEnded: int = 0
var wWarioState: int = 0
var wWarioStateCounter: int = 0
var wWarioStateCycles: int = 0
var wWalkVelIndex: int = 0
var wAttackCounter: int = 0
var wIsIntangible: int = 0
var wIsCrouching: int = 0
var wInvincibleCounter: int = 0
var wTransformation: int = 0
var wTransformationProgress: int = 0
var wIsTurning: int = 0
var wIsSmashAttacking: int = 0
var wGroundShakeCounter: int = 0
var wIsGettingOffLadder: int = 0
var wGrabState: int = 0
var wIsRolling: int = 0
var wIsInSand: int = 0
var wCoinCooldown: int = 0
var wCameraSCY: int = 0
var wCameraSCX: int = 0
var wIsOnSteppableObject: int = 0
var wJumpCollision: int = 0
var wSFXLoopCounter: int = 0
var hYPos: int = 0
var hXPos: int = 0
var wSCY: int = 0
var wSCX: int = 0
var wCameraRoomXScrollLimit: int = 0
var wRoomLowerYLimit: int = 0
var wRoomUpperYLimit: int = 0
var wRoomLeftXLimit: int = 0
var wRoomRightXLimit: int = 0
var wLevelEdgeUpdateFlags: int = 0
var wSCYShake: int = 0
## The hidden figure's fight (the Temple): its own shake added to wSCY, the scroll it keeps (wc08b
## is wSCX there), and the window's y (wc08d).
var wHiddenFigureSCYShake: int = 0
var wc08a: int = 0
var wc08b: int = 0
var wc08c: int = 0
var wc08d: int = 0
var wScrollDownEdge: int = 0
var wScrollUpEdge: int = 0
var wScrollLeftEdge: int = 0
var wScrollRightEdge: int = 0
var wc0d4: int = 0
var wc0d5: int = 0
var wIsDMATransferPending: int = 0
var wPrevWarioScreenYPos: int = 0
var wCamRightSpacing: int = 0
var wCamLeftSpacing: int = 0
var wWarioScreenYPos: int = 0
var wWarioScreenXPos: int = 0
var wCameraRoomYScrollLimit: int = 0

# --- Working variables not in traces ---------------------------------------------------------

var wBlockFuncBreakFlag: int = 0
var wBlockFuncSpecialCollision: int = 0
var wBlockFuncWarioFlag: int = 0
var wIsInWaterOrSand: int = 0
var wIsWarioGroundShaking: int = 0
var wSwimVelIndex: int = 0
## wca94: set while a transformation's music plays (UpdateLevelMusic; audio is not ported).
var wca94: int = 0
## Set by the slope handlers when an object (not Wario) probes a slope (block_functions.asm).
var wObjSlopeInteraction: int = 0
## wBlockPtrBank:wBlockPtr as a map row (0-255, before banking) and column.
var block_row: int = 0
var block_column: int = 0

## Names of variables that traces record and that a parity check may load or compare.
const TRACED: PackedStringArray = [
	"wGlobalCounter", "wJoypadDown", "wJoypadPressed", "wState", "wSubState", "wLevelRoomID", "wRoom",
	"wCameraConfigFlags", "wCameraYDelta", "wCameraXDelta", "wCollisionPoints", "wRoomTransitionParam",
	"wWaterInteraction", "wc0dc", "wIsOnSlipperyGround", "wWarioSlopeInteraction", "wUnused_c18d",
	"wWarioAnimationEnded", "wFloorTransitionTimer", "wFloorTransitionDir", "wLadderInteraction",
	"wIsNearFence", "wIsInAirCurrent", "wc1ca", "wLevel", "wPowerUpLevel", "wWarioYPos", "wWarioXPos",
	"wFrameDuration", "wAnimationFrame", "wDirection", "wCollisionBoxTop", "wCollisionBoxBottom",
	"wCollisionBoxLeft", "wCollisionBoxRight", "wIsFloorTransition", "wJumpVelTable", "wJumpVelIndex",
	"wDoFullJump", "wJumpingUpwards", "wFloor", "wWarioFramesetPtr", "wWarioFrame", "wWarioAttributes",
	"wWarioPalsPtr", "wDMASourceBank", "wDMASourcePtr", "wWarioOAMBank", "wWarioOAMPtr", "wInvisibleFrame",
	"wWarioState", "wWarioStateCounter",
	"wWarioStateCycles", "wWalkVelIndex", "wAttackCounter", "wIsIntangible", "wIsCrouching", "wInvincibleCounter",
	"wTransformation", "wTransformationProgress", "wIsTurning", "wIsSmashAttacking", "wGroundShakeCounter",
	"wIsGettingOffLadder", "wGrabState", "wIsRolling",
	"wIsInSand", "wCoinCooldown", "wCameraSCY", "wCameraSCX", "wIsOnSteppableObject", "wJumpCollision",
	"wSFXLoopCounter", "hYPos", "hXPos", "wSCY", "wSCX", "wCameraRoomXScrollLimit", "wRoomLowerYLimit",
	"wRoomUpperYLimit", "wRoomLeftXLimit", "wRoomRightXLimit", "wLevelEdgeUpdateFlags", "wSCYShake",
	"wScrollDownEdge", "wScrollUpEdge", "wScrollLeftEdge", "wScrollRightEdge", "wc0d4", "wc0d5",
	"wIsDMATransferPending", "wPrevWarioScreenYPos", "wCamRightSpacing", "wCamLeftSpacing",
	"wWarioScreenYPos", "wWarioScreenXPos", "wCameraRoomYScrollLimit",
	"wDayNight", "wccec", "wLevelEndScreen", "wObjectGroup", "wAutoMoveState", "wShootGoals", "wSwitchState", "wSwitchStateUpdated", "wPickedUpWiggleCounter",
	"wPickedUpFrameCounter", "wIsMinigameCleared", "wMultiBlockParam",
	"wTouchState", "wStingTouchState", "wca94", "wNumCoins", "wNumMusicalCoins",
	"wKeyAndTreasureFlags", "wTreasuresCollected7", "wceef", "wNumCollectedTreasures", "wLanguage", "wTimer", "wResetDisabled", "wTransformationDuration", "wCurParticleAnimEnded",
	"wAnimatedTilesGroup", "wAnimatedTilesFrameDuration", "wAnimatedTilesGfx", "wAnimatedTilesFrame",
	"wAnimatedTilesFrameCount", "wRoomPalCycle", "wRoomPalCycleDuration", "wRoomPalCycleIndex", "wRoomPalCycleCounter",
	"wRoomAnimatedTilesEnabled", "wRoomAnimatedPalsEnabled",
	"wSwimVelIndex", "wWaterSurfaceFloatingCounter", "wSwimmingDirectionInput", "wc0e0", "wc0e1", "wIsInWaterOrSand",
	"wWaterCurrent", "wLastWaterCurrent", "wCurWaterCurrent",
	"wHiddenFigureSCYShake", "wc08a", "wc08b", "wc08c", "wc08d",
]


## Routines a path reached that are not ported, by name (the update's result is then unknown).
var unported: PackedStringArray = PackedStringArray()


func note_unported(routine: String) -> void:
	if not routine in unported:
		unported.append(routine)


## rDIV, the hardware timer, is the game's only randomness: 61 read sites, each named by its site (the
## bank and address of the instruction after it, as tools/wl3pc/oracle_wario.py DIV_READS hooks
## them). A parity run replays the oracle's reads in order (`div_replay`), noting any read at
## another site or beyond them in `div_mismatches`. Otherwise the port draws from its own seeded
## generator: provisional, since the original's values follow the CPU's timing since power-on.
var div_replay: bool = false
var div_queue: Array = []  # [site, value]
var div_mismatches: PackedStringArray = PackedStringArray()
var div_generator := RandomNumberGenerator.new()


## ProcessBlock's read of a block byte outside the map rows a trace records, at `address` (as
## GetBlockPtr forms it): in a parity run the oracle's recorded byte, the next in the replay queue
## (site OUTSIDE_BLOCK_SITE); otherwise, or if the next recorded read is elsewhere, -1.
const OUTSIDE_BLOCK_SITE: int = 0xFF


func replay_outside_read(address: int) -> int:
	if not div_replay or div_queue.is_empty() or int(div_queue[0][0]) != ((OUTSIDE_BLOCK_SITE << 16) | address):
		return -1
	return int(div_queue.pop_front()[1])


func read_div(site: int) -> int:
	if not div_replay:
		return div_generator.randi() & 0xFF
	if div_queue.is_empty():
		div_mismatches.append("an rDIV read at %02x:%04x the original did not make" % [site >> 16, site & 0xFFFF])
		return 0
	var entry: Array = div_queue.pop_front()
	if int(entry[0]) != site:
		div_mismatches.append("an rDIV read at %02x:%04x where the original read at %02x:%04x"
				% [site >> 16, site & 0xFFFF, int(entry[0]) >> 16, int(entry[0]) & 0xFFFF])
	return int(entry[1])


## Copy named values into the variables this class declares; unknown names are ignored.
func load_values(names: PackedStringArray, values: Array) -> void:
	for i: int in names.size():
		if names[i] in TRACED:
			set(names[i], int(values[i]))


func value_of(name: String) -> int:
	return int(get(name))


static func byte(value: int) -> int:
	return value & 0xFF


static func word(value: int) -> int:
	return value & 0xFFFF


## The low byte of a word (`[w + 1]`) and the high byte (`[w + 0]`).
static func lo(value: int) -> int:
	return value & 0xFF


static func hi(value: int) -> int:
	return (value >> 8) & 0xFF
