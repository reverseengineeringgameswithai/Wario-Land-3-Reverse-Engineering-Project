class_name DeviceFunctions
extends EnemyFunctions
## The level's devices, by translation from src/engine/level/objects/*.asm, most frequent on the
## coverage sweep first: the zip line, the pillar platform, the flame block and its torches, the
## barrel, the clear gate. Paths into code not ported are named in `unported`.
## Research note: docs/02-research/objects.md.

const ZIP_LINE_FUNC: int = 0x12_5326  # ZipLineFunc
const ZIP_LINE_FUNC_WAIT: int = 0x12_5369  # .Func_49369
const ZIP_LINE_FUNC_RIDDEN: int = 0x12_53DC  # .Func_493dc
const ZIP_LINE_FUNC_LET_GO: int = 0x12_5405  # .Func_49405
const ZIP_LINE_FUNC_STOPPED: int = 0x12_5412  # .Func_49412
const ZIP_LINE1: int = 0x24  # level along, there and back
const ZIP_LINE4: int = 0x27  # from here on, one way, 3 px a frame
const FRAMESET_691C4: int = 0x51C4
const FRAMESET_691C9: int = 0x51C9
const FRAMESET_691D2: int = 0x51D2
const FRAMESET_691DB: int = 0x51DB
const PILLAR_PLATFORM_2_FUNC: int = 0x12_5C70  # PillarPlatform2Func
const PILLAR_PLATFORM_3_FUNC: int = 0x12_5C7E
const PILLAR_PLATFORM_1_FUNC: int = 0x12_5C8C
const PILLAR_PLATFORM_FUNC_RISE: int = 0x12_5CC2  # PillarPlatformFunc.Func_49cc2
const PILLAR_PLATFORM_FUNC_SINK: int = 0x12_5CCE  # .Func_49cce
const PILLAR_PLATFORM_FUNC_IDLE: int = 0x12_5CE5  # .Func_49ce5
const PILLAR_PLATFORM: int = 0x20  # all three variants' ID
const OBJSTATE_PILLAR_RISE: int = 0x2B  # what a pound or a neighbour leaves
const FRAMESET_6975B: int = 0x575B
const FRAMESET_6975E: int = 0x575E
const FLAME_BLOCK_TORCH_UPDATE: int = 0x10_4B14  # FlameBlockTorchUpdate
const FLAME_BLOCK_TORCH_UPDATE_LIT: int = 0x10_4B52  # FlameBlockTorchUpdate.Update
const FLAME_BLOCK_TORCH_FUNC: int = 0x10_4B8C  # FlameBlockTorchFunc
const FLAME_BLOCK_FUNC: int = 0x12_56BD  # FlameBlockFunc
const FLAME_BLOCK_FUNC_UPDATE: int = 0x12_56ED
const FLAME_BLOCK_FUNC_DESTROY: int = 0x12_5708  # FlameBlockFunc.Detroy
const NUM_FLAME_BLOCK_TORCHES: int = 3
const DUMMY_OBJECT_FUNC: int = 0x18_737E  # DummyObjectFunc (ID $80)
const BARREL_1_FUNC: int = 0x10_7451  # Barrel1Func
const BARREL_1_UPDATE_1: int = 0x10_7479
const BARREL_1_UPDATE_2: int = 0x10_74A2
const DATA_60A50: int = 0x4A50  # Barrel 1 sinking (bank $18)
const BARREL_2_FUNC: int = 0x10_74BA  # Barrel2Func
const BARREL_2_FUNC_UPDATE: int = 0x10_74E2
const FRAMESET_68A66: int = 0x4A66
const FRAMESET_68A6F: int = 0x4A6F
const FRAMESET_68A78: int = 0x4A78
const FRAMESET_68A8B: int = 0x4A8B
const WOLFENBOSS_PLATFORM_FUNC: int = 0x15_62C8  # WolfenbossPlatformFunc
const WOLFENBOSS_PLATFORM_WAIT_OPEN: int = 0x15_62EF
const WOLFENBOSS_PLATFORM_OPEN: int = 0x15_6309
const WOLFENBOSS_PLATFORM_DISAPPEAR: int = 0x15_631E
const FRAMESET_69E72: int = 0x5E72
const SHOOT_GOAL_COUNTER_FUNC: int = 0x15_7264  # ShootGoalCounterFunc
const SHOOT_GOAL_COUNTER_UPDATE: int = 0x15_7284  # .UpdateScore
const WARIO_GOAL_COUNTER_FUNC: int = 0x15_72B4  # WarioGoalCounterFunc
const WARIO_GOAL_COUNTER_UPDATE: int = 0x15_72D4  # .UpdateScore
const CART_FUNC: int = 0x12_453B  # CartFunc
const CART_WAITING: int = 0x12_4560  # .Waiting
const CART_MOVING: int = 0x12_457A  # .Moving
const CART_STOPPED_FUNC: int = 0x12_4622  # CartStoppedFunc
const CART_RIGHT: int = 0x23  # its ID's low byte (CART_LEFT $22)
const CART_VARIABLE_FUNC: int = 0x12_4625  # CartVariableFunc (its IDs are the cart's)
const CART_VARIABLE_WAITING: int = 0x12_4662  # .Waiting
const CART_VARIABLE_MOVING: int = 0x12_4688  # .Moving
const TRUCK_WHEEL: int = 0x3D  # a treasure
const FRAMESET_691A7: int = 0x51A7  # the variable cart without the truck wheel
const FRAMESET_691AA: int = 0x51AA  # rolling right
const FRAMESET_691B3: int = 0x51B3  # rolling left
const FRAMESET_691BF: int = 0x51BF  # waiting, and stopped at a wall
const BIG_LEAF_SPAWNER_FUNC: int = 0x10_6BA8  # BigLeafSpawnerFunc
const BIG_LEAF_SPAWNER_SPAWN_SET_1: int = 0x10_6BBF  # .SpawnSet1
const BIG_LEAF_SPAWNER_SPAWN_SET_2: int = 0x10_6C03
const BIG_LEAF_1_FUNC: int = 0x10_6C25  # BigLeaf1Func
const BIG_LEAF_2_FUNC: int = 0x10_6C4C  # BigLeaf2Func, BigLeafFunc
const BIG_LEAF_UPDATE: int = 0x10_6C6E  # BigLeaf2Func.Update
const BIG_LEAF_SINK: int = 0x10_6D0E  # .Func_42d0e
const OBJ_PARAMS_BIG_LEAF_1: int = 0x47DF  # bank $19
const OBJ_PARAMS_BIG_LEAF_2: int = 0x47F4
const OBJ_PARAMS_BIG_LEAF_3: int = 0x4809
const FRAMESET_68729: int = 0x4729  # a big leaf drifting
const FRAMESET_68732: int = 0x4732  # appearing
const FRAMESET_6873B: int = 0x473B  # sinking
const FRAMESET_69199: int = 0x5199  # standing
const FRAMESET_6919E: int = 0x519E  # rolling
const ROCK_FUNC: int = 0x12_6902  # RockFunc
const ROCK_FUNC_UPDATE: int = 0x12_692A
const FRAMESET_69BFE: int = 0x5BFE
const FRAMESET_69C01: int = 0x5C01
const CLEAR_GATE_3_FUNC: int = 0x10_779B  # ClearGate3Func
const CLEAR_GATE_2_FUNC: int = 0x10_77A0
const CLEAR_GATE_1_FUNC: int = 0x10_77A5
const CLEAR_GATE_FUNC_UPDATE: int = 0x10_77D6  # ClearGateFunc.Update
const OBJ_INTERACTION_FIRE: int = 0x0E
const FRAMESET_68369: int = 0x4369
const FRAMESET_695DE: int = 0x55DE
const FRAMESET_695E7: int = 0x55E7
const WATER_SPARK_FUNC: int = 0x12_645D  # WaterSparkFunc
const WATER_SPARK_FUNC_WAIT: int = 0x12_6482  # .Func_4a482
const WATER_SPARK_FUNC_SPARK: int = 0x12_649D  # .Func_4a49d
const FRAMESET_69B12: int = 0x5B12
const FRAMESET_69B1E: int = 0x5B1E
const BUBBLE_HOLE_FUNC: int = 0x11_7BE6  # BubbleHoleFunc
const BUBBLE_HOLE_FUNC_UPDATE: int = 0x11_7BF9
const BUBBLE_FUNC: int = 0x11_7C36  # BubbleFunc
const BUBBLE_FUNC_UPDATE: int = 0x11_7C55
const BUBBLE_FUNC_BURST: int = 0x11_7C79
const OBJ_PARAMS_BUBBLE: int = 0x4EDF  # ObjParams_Bubble (bank $19)
const FRAMESET_690F4: int = 0x50F4  # a bubble
const FRAMESET_6910C: int = 0x510C  # bursting
const NOBIIRU_FUNC: int = 0x10_77D7  # NobiiruFunc
const NOBIIRU_FUNC_UPDATE: int = 0x10_780E  # .Func_4380e
const NOBIIRU_LEFT: int = 0x0A
const FRAMESET_698FF: int = 0x58FF  # Nobiiru in
## Nobiiru's phases 0-5 (out) and 8-12 (back): [frameset, box left, box right] with HDIR clear,
## the same with it set, and the wait (phase 0's left edge as the source has it, though unused).
const NOBIIRU_PHASES: Dictionary = {
	0: [0x58D8, 0xFF, 0x02, 0x58B1, 0xFD, 0x00, 2], 1: [0x58DB, 0xFC, 0x07, 0x58B4, 0xF8, 0x03, 2],
	2: [0x58DE, 0xF8, 0x0B, 0x58B7, 0xF4, 0x07, 2], 3: [0x58E1, 0xF4, 0x0F, 0x58BA, 0xF0, 0x0B, 2],
	4: [0x58E4, 0xF0, 0x13, 0x58BD, 0xEC, 0x0F, 2], 5: [0x58E7, 0xEC, 0x17, 0x58C0, 0xE8, 0x13, 0x14],
	8: [0x58F0, 0xF0, 0x13, 0x58C9, 0xEC, 0x0F, 2], 9: [0x58F3, 0xF4, 0x0F, 0x58CC, 0xF0, 0x0B, 2],
	10: [0x58F6, 0xF8, 0x0B, 0x58CF, 0xF4, 0x07, 2], 11: [0x58F9, 0xFC, 0x07, 0x58D2, 0xF8, 0x03, 2],
	12: [0x58FC, 0xFF, 0x02, 0x58D5, 0xFD, 0x00, 2],
}
const KOBATTO_FUNC: int = 0x11_7718  # KobattoFunc
const KOBATTO_FUNC_UPDATE: int = 0x11_7748
const FRAMESET_69041: int = 0x5041  # Kobatto
const DATA_60EC9: int = 0x4EC9  # Kobatto's flight (bank $18)
const STOVE_FUNC: int = 0x12_571C  # StoveFunc
const STOVE_FUNC_UPDATE: int = 0x12_578B
const FRAMESET_69615: int = 0x5615  # the stove
const FRAMESET_69618: int = 0x5618  # pushed
const FRAMESET_69625: int = 0x5625  # touched
const APPLEBY_FUNC: int = 0x11_79B8  # ApplebyFunc
const APPLEBY_FUNC_UPDATE: int = 0x11_7A01
const APPLE_FUNC_LEFT: int = 0x11_7B0F  # AppleFunc_Left
const APPLE_FUNC_RIGHT: int = 0x11_7B15
const APPLE_UPDATE1_LEFT: int = 0x11_7B2B  # AppleFunc.Update1_Left
const APPLE_UPDATE1_RIGHT: int = 0x11_7B4D
const APPLE_UPDATE2_LEFT: int = 0x11_7B6F
const APPLE_UPDATE2_RIGHT: int = 0x11_7B86
const APPLE_ROLL_LEFT: int = 0x11_7BD3  # .Func_47bd3
const APPLE_ROLL_RIGHT: int = 0x11_7BD8  # .Func_47bd8
const OBJ_PARAMS_APPLE_LEFT: int = 0x4944  # bank $19
const OBJ_PARAMS_APPLE_RIGHT: int = 0x4959
const DATA_60670: int = 0x4670  # an apple's fall (bank $18)
const FRAMESET_689E9: int = 0x49E9  # Appleby: waiting
const FRAMESET_68A00: int = 0x4A00  # coming out
const FRAMESET_68A12: int = 0x4A12  # watching
const FRAMESET_68A1F: int = 0x4A1F  # throwing left
const FRAMESET_68A3A: int = 0x4A3A  # throwing right
const FRAMESET_68A09: int = 0x4A09  # going back in
const FRAMESET_68A63: int = 0x4A63  # knocked away
const SPARK_FUNC: int = 0x12_68A2  # SparkFunc
const SPARK_FUNC_UPDATE: int = 0x12_68CD
const SPARK_HORIZONTAL: int = 0x22
const FIRE_FUNC: int = 0x12_6AF9  # FireFunc
const FIRE_FUNC_UPDATE: int = 0x12_6B1D
const WALL_CRACK_CLOSED_FUNC: int = 0x13_4B2D  # WallCrackClosedFunc
const WALL_CRACK_OPEN_FUNC: int = 0x13_4B32
const WALL_CRACK_FUNC_UPDATE: int = 0x13_4B4B
const WATER_DROP_FUNC: int = 0x12_5D64  # WaterDropFunc
const WATER_DROP_FUNC_UPDATE: int = 0x12_5D83  # .Func_49d83
const ELECTRIC_LAMP_FUNC: int = 0x11_59A9  # ElectricLampFunc
const ELECTRIC_LAMP_DISCHARGED: int = 0x11_59C3
const ELECTRIC_LAMP_CHARGING: int = 0x11_59DF
const ELECTRIC_LAMP_SPARK_FUNC: int = 0x11_5A12  # ElectricLampSparkFunc
const ELECTRIC_LAMP_SPARK_LEFT: int = 0x11_5A6C  # .GoLeft
const ELECTRIC_LAMP_SPARK_RIGHT: int = 0x11_5A78  # .GoRight
const OBJ_PARAMS_ELECTRIC_LAMP_SPARK: int = 0x4ECC  # bank $19
const SEEING_EYE_DOOR_FUNC: int = 0x11_54A0  # SeeingEyeDoorFunc
const SEEING_EYE_DOOR_CHECK: int = 0x11_54CB  # .CheckWarioDistance
const SEEING_EYE_DOOR_CLOSED: int = 0x11_54F6  # the unlabelled code after .asm_454ee
const SEEING_EYE_DOOR_LOOK_AROUND: int = 0x11_5540  # .LookAround
const SEEING_EYE_DOOR_DEFAULT: int = 0x11_5554  # .Default
const INVISIBILITY_POTION_LEFT: int = 0x11_543A  # InvisibilityPotionFunc_Left
const INVISIBILITY_POTION_RIGHT: int = 0x11_543F
const INVISIBILITY_POTION_DROP: int = 0x11_5480  # InvisibilityPotionFunc_Drop
const INVISIBILITY_POTION_DROP_UPDATE: int = 0x11_5491
const FALLING_SNOW_SPAWNER_FUNC: int = 0x12_552D  # FallingSnowSpawnerFunc
const FALLING_SNOW_SPAWNER_WAIT: int = 0x12_5544  # .Func_49544
const FALLING_SNOW_SPAWNER_SHAKE: int = 0x12_5566  # .Func_49566
const FALLING_SNOW_SPAWNER_SHOWN: int = 0x12_559D  # .Func_4959d
const FALLING_SNOW_FUNC: int = 0x12_55C2  # FallingSnowFunc
const FALLING_SNOW_LOOSE: int = 0x12_55EF  # .Func_495ef
const FALLING_SNOW_FALL: int = 0x12_5610  # .Func_49610
const FALLING_SNOW_TAKEN: int = 0x12_5675  # .Func_49675
const FALLING_SNOW_GONE: int = 0x12_56AE  # .Func_496ae
const OBJ_PARAMS_FALLING_SNOW: int = 0x4EF2  # bank $19
const DIV_FALLING_SNOW_SPAWNER: int = 0x12_5595
const SNAKE_FUNC: int = 0x12_589E  # SnakeFunc
const SNAKE_FUNC_INIT: int = 0x12_58B2  # SnakeFunc.Init
const SNAKE_FUNC_UPDATE: int = 0x12_58F1  # SnakeFunc.Update
const SNAKE_FIRE_FUNC: int = 0x12_5B90  # SnakeFireFunc
const SNAKE_FIRE_FUNC_UPDATE: int = 0x12_5BA3  # SnakeFireFunc.Update
const SNAKE: int = 0x2D
const OBJ_PARAMS_SNAKE_FIRE_LEFT: int = 0x4B7B  # ObjParams_SnakeFireLeft (bank $19)
const OBJ_PARAMS_SNAKE_FIRE_RIGHT: int = 0x4B90
const FRAMESET_68804: int = 0x4804  # the snake: still, facing left and right
const FRAMESET_6881D: int = 0x481D
const FRAMESET_68836: int = 0x4836  # turning right, then left
const FRAMESET_6883D: int = 0x483D
const FRAMESET_68844: int = 0x4844  # turning, mouth open
const FRAMESET_6884B: int = 0x484B
const FRAMESET_68852: int = 0x4852  # opening its mouth
const FRAMESET_688C6: int = 0x48C6
const FRAMESET_6886F: int = 0x486F  # about to breathe fire
const FRAMESET_688E3: int = 0x48E3
const FRAMESET_6888C: int = 0x488C  # breathing fire
const FRAMESET_68900: int = 0x4900
const FRAMESET_688A9: int = 0x48A9  # closing its mouth
const FRAMESET_6891D: int = 0x491D


func object_functions() -> Dictionary:
	var functions: Dictionary = super()
	functions.merge({
		ZIP_LINE_FUNC: zip_line_func,
		ZIP_LINE_FUNC_WAIT: zip_line_wait,
		ZIP_LINE_FUNC_RIDDEN: zip_line_ridden,
		ZIP_LINE_FUNC_LET_GO: zip_line_let_go,
		ZIP_LINE_FUNC_STOPPED: _no_actions,
		PILLAR_PLATFORM_1_FUNC: pillar_platform_1_func,
		PILLAR_PLATFORM_2_FUNC: pillar_platform_2_func,
		PILLAR_PLATFORM_3_FUNC: pillar_platform_3_func,
		PILLAR_PLATFORM_FUNC_IDLE: pillar_platform_idle,
		PILLAR_PLATFORM_FUNC_RISE: pillar_platform_rise,
		PILLAR_PLATFORM_FUNC_SINK: pillar_platform_sink,
		FLAME_BLOCK_TORCH_FUNC: flame_block_torch_func,
		FLAME_BLOCK_TORCH_UPDATE: flame_block_torch_update,
		FLAME_BLOCK_TORCH_UPDATE_LIT: flame_block_torch_lit,
		FLAME_BLOCK_FUNC: flame_block_func,
		FLAME_BLOCK_FUNC_UPDATE: flame_block_update,
		FLAME_BLOCK_FUNC_DESTROY: flame_block_destroy,
		DUMMY_OBJECT_FUNC: dummy_object_func,
		BARREL_1_FUNC: barrel_1_func,
		BARREL_1_UPDATE_1: barrel_1_update_1,
		BARREL_1_UPDATE_2: barrel_1_update_2,
		BARREL_2_FUNC: barrel_2_func,
		BARREL_2_FUNC_UPDATE: barrel_2_update,
		WOLFENBOSS_PLATFORM_FUNC: wolfenboss_platform_func,
		WOLFENBOSS_PLATFORM_WAIT_OPEN: wolfenboss_platform_wait_open,
		WOLFENBOSS_PLATFORM_OPEN: wolfenboss_platform_open,
		WOLFENBOSS_PLATFORM_DISAPPEAR: wolfenboss_platform_disappear,
		SHOOT_GOAL_COUNTER_FUNC: shoot_goal_counter_func,
		SHOOT_GOAL_COUNTER_UPDATE: shoot_goal_counter_update,
		WARIO_GOAL_COUNTER_FUNC: wario_goal_counter_func,
		WARIO_GOAL_COUNTER_UPDATE: wario_goal_counter_update,
		CART_FUNC: cart_func,
		CART_WAITING: cart_waiting,
		CART_MOVING: cart_moving,
		CART_STOPPED_FUNC: set_one_way_platform_action,
		CART_VARIABLE_FUNC: cart_variable_func,
		CART_VARIABLE_WAITING: cart_variable_waiting,
		CART_VARIABLE_MOVING: cart_variable_moving,
		BIG_LEAF_SPAWNER_FUNC: big_leaf_spawner_func,
		BIG_LEAF_SPAWNER_SPAWN_SET_1: big_leaf_spawner_spawn_set_1,
		BIG_LEAF_SPAWNER_SPAWN_SET_2: big_leaf_spawner_spawn_set_2,
		BIG_LEAF_1_FUNC: big_leaf_1_func,
		BIG_LEAF_2_FUNC: big_leaf_2_func,
		BIG_LEAF_UPDATE: big_leaf_update,
		BIG_LEAF_SINK: big_leaf_sink,
		ROCK_FUNC: rock_func,
		ROCK_FUNC_UPDATE: rock_update,
		CLEAR_GATE_1_FUNC: clear_gate_1_func,
		CLEAR_GATE_2_FUNC: clear_gate_2_func,
		CLEAR_GATE_3_FUNC: clear_gate_3_func,
		CLEAR_GATE_FUNC_UPDATE: _clear_gate_update,
		WATER_SPARK_FUNC: water_spark_func,
		WATER_SPARK_FUNC_WAIT: water_spark_wait,
		WATER_SPARK_FUNC_SPARK: water_spark_spark,
		BUBBLE_HOLE_FUNC: bubble_hole_func,
		BUBBLE_HOLE_FUNC_UPDATE: bubble_hole_update,
		BUBBLE_FUNC: bubble_func,
		BUBBLE_FUNC_UPDATE: bubble_update,
		BUBBLE_FUNC_BURST: bubble_burst,
		NOBIIRU_FUNC: nobiiru_func,
		NOBIIRU_FUNC_UPDATE: nobiiru_update,
		KOBATTO_FUNC: kobatto_func,
		KOBATTO_FUNC_UPDATE: kobatto_update,
		STOVE_FUNC: stove_func,
		STOVE_FUNC_UPDATE: stove_update,
		APPLEBY_FUNC: appleby_func,
		APPLEBY_FUNC_UPDATE: appleby_update,
		APPLE_FUNC_LEFT: apple_func_left,
		APPLE_FUNC_RIGHT: apple_func_right,
		APPLE_UPDATE1_LEFT: apple_update1_left,
		APPLE_UPDATE1_RIGHT: apple_update1_right,
		APPLE_UPDATE2_LEFT: apple_update2_left,
		APPLE_UPDATE2_RIGHT: apple_update2_right,
		APPLE_ROLL_LEFT: apple_roll_left,
		APPLE_ROLL_RIGHT: apple_roll_right,
		SPARK_FUNC: spark_func,
		SPARK_FUNC_UPDATE: spark_update,
		FIRE_FUNC: fire_func,
		FIRE_FUNC_UPDATE: _object_does_nothing,
		WALL_CRACK_CLOSED_FUNC: wall_crack_closed_func,
		WALL_CRACK_OPEN_FUNC: wall_crack_open_func,
		WALL_CRACK_FUNC_UPDATE: _no_actions,
		WATER_DROP_FUNC: water_drop_func,
		WATER_DROP_FUNC_UPDATE: water_drop_update,
		ELECTRIC_LAMP_FUNC: electric_lamp_func,
		ELECTRIC_LAMP_DISCHARGED: electric_lamp_discharged,
		ELECTRIC_LAMP_CHARGING: electric_lamp_charging,
		ELECTRIC_LAMP_SPARK_FUNC: electric_lamp_spark_func,
		ELECTRIC_LAMP_SPARK_LEFT: electric_lamp_spark_left,
		ELECTRIC_LAMP_SPARK_RIGHT: electric_lamp_spark_right,
		SEEING_EYE_DOOR_FUNC: seeing_eye_door_func,
		SEEING_EYE_DOOR_CHECK: seeing_eye_door_check,
		SEEING_EYE_DOOR_CLOSED: seeing_eye_door_closed,
		SEEING_EYE_DOOR_LOOK_AROUND: seeing_eye_door_look_around,
		SEEING_EYE_DOOR_DEFAULT: seeing_eye_door_default,
		INVISIBILITY_POTION_LEFT: invisibility_potion_left,
		INVISIBILITY_POTION_RIGHT: invisibility_potion_right,
		INVISIBILITY_POTION_DROP: invisibility_potion_drop,
		INVISIBILITY_POTION_DROP_UPDATE: invisibility_potion_drop_update,
		FALLING_SNOW_SPAWNER_FUNC: falling_snow_spawner_func,
		FALLING_SNOW_SPAWNER_WAIT: falling_snow_spawner_wait,
		FALLING_SNOW_SPAWNER_SHAKE: falling_snow_spawner_shake,
		FALLING_SNOW_SPAWNER_SHOWN: falling_snow_spawner_shown,
		FALLING_SNOW_FUNC: falling_snow_func,
		FALLING_SNOW_LOOSE: falling_snow_loose,
		FALLING_SNOW_FALL: falling_snow_fall,
		FALLING_SNOW_TAKEN: falling_snow_taken,
		FALLING_SNOW_GONE: falling_snow_gone,
		SNAKE_FUNC: snake_func,
		SNAKE_FUNC_INIT: snake_init,
		SNAKE_FUNC_UPDATE: snake_update,
		SNAKE_FIRE_FUNC: snake_fire_func,
		SNAKE_FIRE_FUNC_UPDATE: snake_fire_update,
	})
	return functions


## DummyObjectFunc (objects/dummy.asm): the slot is cleared.
func dummy_object_func() -> void:
	set_cur(OBJ_FLAGS, 0)


func _no_actions() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


# --- Zip lines (objects/zip_line.asm) -------------------------------------------------------

## ZipLineFunc: lines 1-3 run right at 1 px a frame; line 4 left and line 5 right at 3. No
## collision with other objects; then waiting (.Func_49356).
func zip_line_func() -> void:
	var id: int = cur(OBJ_ID)
	set_hdir(id != ZIP_LINE4)
	set_cur(OBJ_VAR_2, 1 if id < ZIP_LINE4 else 3)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_collbox_x(-4, 3)
	set_cur(OBJ_COLLBOX_BOTTOM, -2)
	set_cur(OBJ_VAR_1, 0)
	_zip_line_wait_start()


## .Func_49356
func _zip_line_wait_start() -> void:
	set_object_frameset_ptr(FRAMESET_691C4)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZIP_LINE_FUNC_WAIT & 0xFFFF)
	set_cur(OBJ_STATE, 0)


## .Func_49369: no actions, except with Wario 16-23 px below it, when it can be grabbed
## (ObjInteraction_Rail's OBJACTION_06 sets its state). Grabbed, Wario hangs 27 px below it,
## 4 px along, and it rides (VAR_1 1). Moving (.Func_49418) may already have stopped it.
func zip_line_wait() -> void:
	_no_actions()
	_zip_line_move()
	if cur(OBJ_VAR_1) == 3:
		_zip_line_stop()
		return
	if cur(OBJ_STATE) == 0:
		# The original adds an unset register c to both positions; it cancels in the difference.
		var dy: int = byte(wWarioScreenYPos - cur(OBJ_SCREEN_Y_POS))
		if dy >= 0x10 and dy < 0x18:
			set_cur(OBJ_ACTION, 0)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, ZIP_LINE_FUNC_RIDDEN & 0xFFFF)
	set_cur(OBJ_VAR_1, 1)
	wWarioYPos = word(cur_y() + 0x1B)
	wWarioXPos = word(cur_x() + 4)
	set_object_frameset_ptr(FRAMESET_691D2 if hdir() else FRAMESET_691C9)


## .asm_493cd: at its end for good.
func _zip_line_stop() -> void:
	set_object_frameset_ptr(FRAMESET_691DB)
	set_cur_word(OBJ_UPDATE_FUNCTION, ZIP_LINE_FUNC_STOPPED & 0xFFFF)


## .Func_493dc: ridden while Wario hangs on (TRANSFORMATION_RAIL); let go, it waits 10 frames
## (VAR_1 2), then waits for him again.
func zip_line_ridden() -> void:
	_no_actions()
	_zip_line_move()
	if cur(OBJ_VAR_1) == 3:
		_zip_line_stop()
		return
	if wTransformation == TRANSFORMATION_RAIL:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, ZIP_LINE_FUNC_LET_GO & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 0x0A)
	set_cur(OBJ_VAR_1, 2)


## .Func_49405
func zip_line_let_go() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_zip_line_wait_start()


## .Func_49418: once grabbed, along the wire by OBJ_VAR_2 a frame, carrying Wario while ridden
## (with his side probe, Func_19706/Func_19713, which may break blocks), and up or down by the
## same on sloped lines (by the ID's bit 0 and the direction). Against a wall (Func_3513, UNK4 at
## 16 px up and 7 px ahead, 8 behind) lines 1-3 turn; lines 4 and 5 stop for good (VAR_1 3),
## releasing Wario (wAutoMoveState) if he rides. Sounds (SFX_08C, SFX_ZIP_LINE_SLIDE, SFX_129)
## are not simulated.
func _zip_line_move() -> void:
	if cur(OBJ_VAR_1) == 0:
		return
	var right: bool = hdir()
	set_hpos_from_object(-0x10, 7 if right else -8)
	if object_probe(COLLISION_UNK4) != 0:
		_zip_line_hit_end()
		return
	var speed: int = cur(OBJ_VAR_2)
	var riding: bool = cur(OBJ_VAR_1) == 1
	move_object_x(speed if right else -speed)
	if riding:
		wBlockFuncWarioFlag = 1
		if right:
			move_wario_right(speed)
			check_bottom_right_breaking()
		else:
			move_wario_left(speed)
			check_bottom_left_breaking()
		wBlockFuncWarioFlag = 0
	var id: int = cur(OBJ_ID)
	if id == ZIP_LINE1:
		return
	var up: bool = ((id & 1) != 0) == right
	if up:
		set_cur_word(OBJ_Y_POS, cur_y() - speed)
		if riding:
			move_wario_up(speed)
			handle_upwards_floor_transition()
	else:
		set_cur_word(OBJ_Y_POS, cur_y() + speed)
		if riding:
			move_wario_down(speed)
			handle_downwards_floor_transition()


## .asm_4947b
func _zip_line_hit_end() -> void:
	if cur(OBJ_ID) < ZIP_LINE4:
		set_hdir(not hdir())
		set_object_frameset_ptr(FRAMESET_691D2 if hdir() else FRAMESET_691C9)
		return
	if cur(OBJ_VAR_1) == 1:
		wAutoMoveState = 0
	set_cur(OBJ_VAR_1, 3)


# --- Pillar platforms (objects/pillar_platform.asm) -----------------------------------------

## PillarPlatform1Func: a pillar at height 1 of 0-2 (OBJ_VAR_1); 2 starts 16 px higher, 3 (at 0)
## 16 px lower.
func pillar_platform_1_func() -> void:
	_pillar_platform_func(1)


func pillar_platform_2_func() -> void:
	set_cur_word(OBJ_Y_POS, cur_y() - 0x10)
	_pillar_platform_func(2)


func pillar_platform_3_func() -> void:
	set_cur_word(OBJ_Y_POS, cur_y() + 0x10)
	_pillar_platform_func(0)


## PillarPlatformFunc: visible, no collision with other objects, its box; the day's or the night's
## frameset (wDayNight).
func _pillar_platform_func(height: int) -> void:
	set_cur(OBJ_VAR_1, height)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, PILLAR_PLATFORM_FUNC_IDLE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-7, 0)
	set_cur(OBJ_COLLBOX_BOTTOM, -12)
	set_object_frameset_ptr(FRAMESET_6975E if (wDayNight & 1) != 0 else FRAMESET_6975B)


## .Func_49ce5: a one-way platform. State $2b raises it a step (to height 2); $0a (stepped on
## or pounded) lowers it a step and raises the pillars 3 map columns either side
## (.Func_49d43); any other state is cleared.
func pillar_platform_idle() -> void:
	set_one_way_platform_action()
	var state: int = cur(OBJ_STATE)
	if state == 0:
		return
	if state == OBJSTATE_PILLAR_RISE:
		if cur(OBJ_VAR_1) >= 2:
			set_cur(OBJ_STATE, 0)
			return
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)
		set_cur(OBJ_STATE_DURATION, 9)
		set_cur_word(OBJ_UPDATE_FUNCTION, PILLAR_PLATFORM_FUNC_RISE & 0xFFFF)
		return
	if state != 0x0A:
		set_cur(OBJ_STATE, 0)
		return
	if cur(OBJ_VAR_1) == 0:
		set_cur(OBJ_STATE, 0)
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	set_cur(OBJ_STATE_DURATION, 9)
	set_cur_word(OBJ_UPDATE_FUNCTION, PILLAR_PLATFORM_FUNC_SINK & 0xFFFF)
	_raise_pillars(byte(cur(OBJ_UNK_01) + 3))
	_raise_pillars(byte(cur(OBJ_UNK_01) - 3))


## .Func_49d43: every slot whose map column (OBJ_UNK_01) is `column` and whose ID is a pillar's
## takes state $2b, in the slots themselves.
func _raise_pillars(column: int) -> void:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if wram1[base + OBJ_UNK_01] == column and wram1[base + OBJ_ID] == PILLAR_PLATFORM:
			wram1[base + OBJ_STATE] = OBJSTATE_PILLAR_RISE


## .Func_49cc2: up 2 px a frame for 8 frames (MoveObjectUp_Fast), then idle.
func pillar_platform_rise() -> void:
	_pillar_platform_step(-2)


## .Func_49cce: down 2 px a frame for 8 frames (MoveObjectDown_Fast), then idle.
func pillar_platform_sink() -> void:
	_pillar_platform_step(2)


func _pillar_platform_step(dy: int) -> void:
	set_one_way_platform_action()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur_word(OBJ_Y_POS, cur_y() + dy)
		return
	set_cur(OBJ_STATE, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, PILLAR_PLATFORM_FUNC_IDLE & 0xFFFF)


# --- Flame blocks and their torches (objects/torch.asm, objects/flame_block.asm) ------------

## FlameBlockTorchFunc: an unlit torch, set up as TorchFunc's (.got_frameset).
func flame_block_torch_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, FLAME_BLOCK_TORCH_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68369)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -3)


## FlameBlockTorchUpdate: lit when its state is set (by Hot Wario's touch): it burns (fire) for
## 512 frames, kept from despawning (OBJSUBFLAG_UNK_4), and counts as lit (wNumLitTorches). The
## sounds (SFX_073, and SFX_0FA for the last torch) are not simulated.
func flame_block_torch_update() -> void:
	if cur(OBJ_STATE) == 0:
		return
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_UNK_4)
	set_cur_word(OBJ_UPDATE_FUNCTION, FLAME_BLOCK_TORCH_UPDATE_LIT & 0xFFFF)
	set_interaction(OBJ_INTERACTION_FIRE)
	set_object_frameset_ptr(FRAMESET_68360)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_VAR_1, 2)
	wram1[W_NUM_LIT_TORCHES] = byte(wram1[W_NUM_LIT_TORCHES] + 1)


## FlameBlockTorchUpdate.Update: once all the torches are lit, it stays lit; a touch again
## relights it for 512 frames; when they run out, it is despawned (unlit when it next spawns).
func flame_block_torch_lit() -> void:
	if wram1[W_NUM_LIT_TORCHES] == NUM_FLAME_BLOCK_TORCHES:
		return
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_STATE_DURATION, 0)
		set_cur(OBJ_VAR_1, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	despawn_cur_object()
	wram1[W_NUM_LIT_TORCHES] = byte(wram1[W_NUM_LIT_TORCHES] - 1)


## FlameBlockFunc: gone for good once cleared (wFlameBlockCleared); otherwise no collision with
## other objects, its box.
func flame_block_func() -> void:
	if wram1[W_FLAME_BLOCK_CLEARED] != 0:
		set_cur(OBJ_FLAGS, 0)
		return
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, FLAME_BLOCK_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_695DE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 13)
	set_cur(OBJ_COLLBOX_LEFT, -14)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)


## FlameBlockFunc.Update: with every torch lit, cleared (for good) and burning away for 159
## frames.
func flame_block_update() -> void:
	if wram1[W_NUM_LIT_TORCHES] != NUM_FLAME_BLOCK_TORCHES:
		return
	wram1[W_FLAME_BLOCK_CLEARED] = NUM_FLAME_BLOCK_TORCHES
	set_object_frameset_ptr(FRAMESET_695E7)
	set_cur(OBJ_STATE_DURATION, 159)
	set_cur_word(OBJ_UPDATE_FUNCTION, FLAME_BLOCK_FUNC_DESTROY & 0xFFFF)


## FlameBlockFunc.Detroy: no actions in its last 25 frames, then gone.
func flame_block_destroy() -> void:
	if cur(OBJ_STATE_DURATION) < 25:
		_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Barrels (objects/barrel.asm) -----------------------------------------------------------

## Barrel2Func: standing ($31), its box.
func barrel_2_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, BARREL_2_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68A78)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_cur(OBJ_STATE, OBJSTATE_WALK)


## Barrel2Func.Update: its framesets by state ($ff for the picked-up, held, and broken ones).
func barrel_2_update() -> void:
	_carried_object_update(2, {0x04: FRAMESET_68A66, 0x05: FRAMESET_68A6F, 0x28: FRAMESET_68A6F,
			0x29: FRAMESET_68A66, 0x4C: FRAMESET_68A6F, 0x4D: FRAMESET_68A66, 0xFF: FRAMESET_68A78},
			FRAMESET_68A8B, 0x0E)


## The carried objects' state table (Barrel2Func.Update, RockFunc.Update), by OBJ_STATE: standing
## ($31, $13) does nothing; bumped (`bump` in OBJ_VAR_2), knocked, picked up, held, and thrown as
## the standard objects are, `framesets` (by the state, if there) set on the way; most other states
## break it ($2f) with `break_frameset` for `break_duration` frames.
func _carried_object_update(bump: int, framesets: Dictionary, break_frameset: int, break_duration: int) -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x13, OBJSTATE_WALK:
			pass
		0x02, 0x03, 0x08, 0x09:
			set_cur(OBJ_STATE, 0x32 if (state & 1) == 0 else 0x33)
			set_cur(OBJ_STATE_DURATION, 0x0C)
			set_cur(OBJ_VAR_2, bump)
		0x04, 0x05, 0x28, 0x29:
			if framesets.has(state):
				set_object_frameset_ptr(framesets[state])
			var function: Dictionary = {0x04: FUNC_3326, 0x05: FUNC_3317, 0x28: FUNC_33F8, 0x29: FUNC_3407}
			set_cur_word(OBJ_UPDATE_FUNCTION, function[state])
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
			_no_actions()
		0x06, 0x07:
			if framesets.has(0xFF):
				set_object_frameset_ptr(framesets[0xFF])
			enemy_picked_up_start(state == 0x06)  # Func_3335, Func_3344
		0x0A:
			func_62e57()  # Func_3173
		0x12:
			set_cur(OBJ_ACTION, 0x9F)
			set_cur(OBJ_STATE, 0x42)
			set_cur(OBJ_VAR_3, 0)
		0x14, 0x15:
			set_cur(OBJ_STATE, state + 0x30)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_VAR_2, 2)
		0x18, 0x19, 0x48, 0x49:
			carried_object_held(state, framesets.get(0xFF, -1))
		0x2F:
			_carried_object_breaking()
		0x4C, 0x4D:
			set_cur(OBJ_STATE, state + 0x12)
			if framesets.has(state):
				set_object_frameset_ptr(framesets[state])
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right
		0x32, 0x33, 0x36, 0x37, 0x42, 0x44, 0x45, 0x4A, 0x4B, 0x4E, 0x4F, 0x5E, 0x5F:
			common_enemy_state(state)
		_:
			_carried_object_break(break_frameset, break_duration)


## Barrel2Func's .Func_435a6, RockFunc.Destroy: breaking ($2f), no collision (SFX_TEMPLE_ROCK not
## simulated).
func _carried_object_break(frameset: int, duration: int) -> void:
	set_cur(OBJ_STATE, 0x2F)
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, duration)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)
	_carried_object_breaking()


## .Func_435c2, .Func_4aa0a: then despawned.
func _carried_object_breaking() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		despawn_cur_object()


# --- The rock (objects/rock.asm) ----------------------------------------------------------------

## RockFunc: visible, its box; standing ($31).
func rock_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, ROCK_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69BFE)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	set_cur(OBJ_STATE, OBJSTATE_WALK)


## RockFunc.Update: Barrel 2's table without its framesets, a bump's OBJ_VAR_2 1, and 25 frames
## breaking.
func rock_update() -> void:
	_carried_object_update(1, {}, FRAMESET_69C01, 0x19)


# --- Clear gates (objects/clear_gate.asm) ---------------------------------------------------

## ClearGate1Func to ClearGate3Func: their framesets (Frameset_698a8, _698ab, _698ae), then
## ClearGateFunc.
func clear_gate_1_func() -> void:
	_clear_gate(0x58A8)


func clear_gate_2_func() -> void:
	_clear_gate(0x58AB)


func clear_gate_3_func() -> void:
	_clear_gate(0x58AE)


## ClearGateFunc: a wall to Wario (its data's OBJ_INTERACTION_SOLID), no collision with other
## objects, its box; raised 32 px once the minigame is cleared (wIsMinigameCleared).
func _clear_gate(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, CLEAR_GATE_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 5)
	set_cur(OBJ_COLLBOX_LEFT, -22)
	set_cur(OBJ_COLLBOX_BOTTOM, -2)
	if wIsMinigameCleared != 0:
		set_cur(OBJ_VAR_2, 32)
		set_cur_word(OBJ_Y_POS, cur_y() - 32)


## ClearGateFunc.Update: nothing.
func _clear_gate_update() -> void:
	pass


# --- The water spark (objects/water_spark.asm) --------------------------------------------

## WaterSparkFunc: visible, no collision with other objects, its box; waiting.
func water_spark_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, WATER_SPARK_FUNC_WAIT & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69B1E)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -3)


## .Func_4a482: until an action gives it a state; then (the state cleared) sparking for 100 frames
## (SetObjectFramesetPtr leaves hl at OBJ_STATE_DURATION).
func water_spark_wait() -> void:
	if cur(OBJ_STATE) == 0:
		return
	set_cur(OBJ_STATE, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, WATER_SPARK_FUNC_SPARK & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69B12)
	set_cur(OBJ_STATE_DURATION, 100)


## .Func_4a49d: sparking, without actions, then waiting again.
func water_spark_spark() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, WATER_SPARK_FUNC_WAIT & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69B1E)


# --- The snake and its fire (objects/snake.asm) ---------------------------------------------

## SnakeFunc: its home height kept in OBJ_VAR_2 and _3 (y low, high), then .Init.
func snake_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SNAKE_FUNC_INIT & 0xFFFF)
	set_cur(OBJ_VAR_2, cur(OBJ_Y_POS))
	set_cur(OBJ_VAR_3, cur(OBJ_Y_POS + 1))


## .Init: facing Wario (HDIR set while he is to the right), waiting $78 frames; a one-way platform
## 15 px wide, left of its x.
func snake_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SNAKE_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_6881D)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_68804)
	set_cur(OBJ_STATE_DURATION, 0x78)
	set_cur(OBJ_VAR_1, 0)
	set_collbox_x(-15, -1)
	set_cur(OBJ_COLLBOX_BOTTOM, 15)


## .Update: a one-way platform that turns to Wario (.Func_49af0). Touched to vanish ($0a),
## attacked ($04, $05), or hit by a thrown object ($28, $29), it sinks home at once (.Func_49a85);
## otherwise its cycle by the substate: wait, rise, look, open its mouth, breathe fire, close it,
## sink home.
func snake_update() -> void:
	set_one_way_platform_action()
	set_cur(OBJ_COLLBOX_BOTTOM, 15)
	_snake_turn()
	var state: int = cur(OBJ_STATE)
	if state != 0:
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
		if state == OBJSTATE_VANISH_TOUCH or (state & 0xFE) == OBJSTATE_ATTACKED_LEFT_START or (state & 0xFE) == 0x28:
			_snake_sink_start()
			return
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_snake_wait()
		2:
			_snake_rise()
		3:
			_snake_look()
		4:
			_snake_open()
		5:
			_snake_breathe()
		6:
			_snake_fire()
		7:
			_snake_close()
		8:
			_snake_sink()
		_:
			note_unported("SnakeFunc substate %d (past its table)" % (cur(OBJ_SUBSTATE) & 0x0F))


## .Func_49943: waiting, then $3e frames more and the next substate.
func _snake_wait() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x3E)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)


## .Func_49957: rising, then $53 frames looking.
func _snake_rise() -> void:
	_snake_screen_state()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE_DURATION, 0x53)
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)
		return
	_snake_move(true)


## Half a pixel a frame (MoveObjectUp_Slow, _Down_Slow); stood on, a pixel on odd frames, carrying
## Wario (and his floor) with it, the stand cleared and the box bottom 0 for this frame.
func _snake_move(up: bool) -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		if up:
			move_object_up_slow()
		else:
			move_object_down_slow()
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)
	if (wGlobalCounter & 1) == 0:
		return
	if up:
		move_wario_up(1)
		handle_upwards_floor_transition()
		move_object_up()
	else:
		move_wario_down(1)
		handle_downwards_floor_transition()
		move_object_down()


## .Func_49984: looking; then (unless turning) when the animation reaches its frame, opening its
## mouth for $31 frames.
func _snake_look() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)
		set_cur(OBJ_STATE_DURATION, 0x31)
		return
	if cur(OBJ_FRAME) != (0x0E if hdir() else 0x05):
		return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)
	set_object_frameset_ptr(FRAMESET_688C6 if hdir() else FRAMESET_68852)
	set_cur(OBJ_STATE_DURATION, 0x31)


## .Func_499b8: its mouth open; then (unless turning) at its frame, about to breathe fire.
func _snake_open() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	if cur(OBJ_VAR_1) != 0:
		return
	if cur(OBJ_FRAME) != (0x45 if hdir() else 0x22):
		return
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)
	set_object_frameset_ptr(FRAMESET_688E3 if hdir() else FRAMESET_6886F)
	set_cur(OBJ_STATE_DURATION, 0x31)
	set_cur(OBJ_VAR_1, 2)


## .Func_499f8: then, with a free slot, the fire ahead of it for $93 frames; without, closing.
func _snake_breathe() -> void:
	set_cur(OBJ_VAR_1, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	var free: bool = false
	for slot: int in NUM_OBJECTS:
		if (slot_flags(slot) & OBJFLAG_ACTIVE) == 0:
			free = true
			break
	if not free:
		_snake_close_start()
		return
	set_cur(OBJ_STATE_DURATION, 0x93)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) + 1)
	if hdir():
		set_object_frameset_ptr(FRAMESET_68900)
		create_object_at_relative_pos(OBJ_PARAMS_SNAKE_FIRE_RIGHT)
	else:
		set_object_frameset_ptr(FRAMESET_6888C)
		create_object_at_relative_pos(OBJ_PARAMS_SNAKE_FIRE_LEFT)


## .Func_49a57: breathing fire, then closing.
func _snake_fire() -> void:
	set_cur(OBJ_VAR_1, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_snake_close_start()


## .asm_49a5f: closing its mouth for $31 frames (substate 7).
func _snake_close_start() -> void:
	set_cur(OBJ_STATE_DURATION, 0x31)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 7)
	set_object_frameset_ptr(FRAMESET_6891D if hdir() else FRAMESET_688A9)


## .Func_49a7c: then sinking.
func _snake_close() -> void:
	set_cur(OBJ_VAR_1, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_snake_sink_start()


## .Func_49a85: sinking home (substate 8).
func _snake_sink_start() -> void:
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 8)
	set_object_frameset_ptr(FRAMESET_6881D if hdir() else FRAMESET_68804)
	set_cur(OBJ_STATE_DURATION, 1)


## .Func_49aa1: down to its home height, then waiting $78 frames (substate 1).
func _snake_sink() -> void:
	_snake_screen_state()
	if cur(OBJ_Y_POS) == cur(OBJ_VAR_2) and cur(OBJ_Y_POS + 1) == cur(OBJ_VAR_3):
		set_cur(OBJ_STATE_DURATION, 0x78)
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & 0xF0) | 1)
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)  # SFX_08B
	_snake_move(false)


## .Func_49af0: after a turn (OBJ_VAR_1 counting down), the still or mouth-open frameset; else,
## with Wario within $28 px above or below on screen, turning to him (OBJ_VAR_1 = $14).
func _snake_turn() -> void:
	var open: bool = (cur(OBJ_SUBSTATE) & 0x0F) == 4
	if cur(OBJ_VAR_1) != 0:
		set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
		if cur(OBJ_VAR_1) != 0:
			return
		if hdir():
			set_object_frameset_ptr(FRAMESET_688C6 if open else FRAMESET_6881D)
		else:
			set_object_frameset_ptr(FRAMESET_68852 if open else FRAMESET_68804)
		return
	var dy: int = byte(cur(OBJ_SCREEN_Y_POS) - wWarioScreenYPos)
	if dy >= 0x28 and dy < 0xE8:
		return
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		if hdir():
			return
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_68844 if open else FRAMESET_68836)
	else:
		if not hdir():
			return
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_6884B if open else FRAMESET_6883D)
	set_cur(OBJ_VAR_1, 0x14)


## .Func_49b76: OBJSTATE_48 while it is off the screen's middle rows (screen y below $10 or from
## $a0 to $bf), else 0.
func _snake_screen_state() -> void:
	var y: int = cur(OBJ_SCREEN_Y_POS)
	set_cur(OBJ_STATE, 0 if y >= 0xC0 or (y >= 0x10 and y < 0xA0) else OBJSTATE_48)


## SnakeFireFunc: no actions for a frame, invisible (the snake's frames draw the fire).
func snake_fire_func() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SNAKE_FIRE_FUNC_UPDATE & 0xFFFF)


## SnakeFireFunc.Update: it lasts while the snake it came from (the active, non-transient SNAKE
## with its map cell) is breathing fire (substate 6), and is cleared otherwise.
func snake_fire_update() -> void:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if wram1[base + OBJ_UNK_02] != cur(OBJ_UNK_02) or wram1[base + OBJ_UNK_01] != cur(OBJ_UNK_01):
			continue
		if (wram1[base + OBJ_FLAGS] & (OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT)) != OBJFLAG_ACTIVE:
			continue
		if wram1[base + OBJ_ID] != SNAKE:
			continue
		if (wram1[base + OBJ_SUBSTATE] & 0x0F) == 6:
			return
		break
	set_cur(OBJ_FLAGS, 0)


# --- Bubble holes and their bubbles (objects/bubble.asm) -----------------------------------------

## BubbleHoleFunc: no collision; a bubble at once if there is room.
func bubble_hole_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BUBBLE_HOLE_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	_bubble_hole_blow()


## .Update: its frame held; when its wait runs out, another bubble (.asm_47c08).
func bubble_hole_update() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_bubble_hole_blow()


## .asm_47c08: a bubble (SFX_069), the next in 208 frames, while fewer than two transient objects
## are active (fewer than one with Wario in a bubble); otherwise it tries again next frame.
func _bubble_hole_blow() -> void:
	if count_active_transient_objects() >= (1 if wTransformation == TRANSFORMATION_BUBBLE else 2):
		set_cur(OBJ_STATE_DURATION, 1)
		return
	set_cur(OBJ_STATE_DURATION, 208)
	create_object_from_cur_obj_pos(OBJ_PARAMS_BUBBLE)


## BubbleFunc: no collision; rising (.Func_47c88) until its first wait runs out, then its frameset.
func bubble_func() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		_bubble_move()
		return
	set_object_frameset_ptr(FRAMESET_690F4)
	set_cur_word(OBJ_UPDATE_FUNCTION, BUBBLE_FUNC_UPDATE & 0xFFFF)


## .Update: any state (Wario taking it, OBJACTION_07) clears it; otherwise it moves on.
func bubble_update() -> void:
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_FLAGS, 0)
		return
	_bubble_move()


## .set_burst (SFX_072): bursting for 16 frames.
func _bubble_set_burst() -> void:
	set_object_frameset_ptr(FRAMESET_6910C)
	set_cur(OBJ_STATE_DURATION, 16)
	set_cur_word(OBJ_UPDATE_FUNCTION, BUBBLE_FUNC_BURST & 0xFFFF)


## .Burst: then cleared.
func bubble_burst() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


## .Func_47c88: on screen, every odd frame it drifts; otherwise a pixel up, bursting at a ceiling $18
## above or once neither $18 nor $0c above it is water.
func _bubble_move() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0 and (wGlobalCounter & 1) != 0:
		_bubble_object_drift()
		return
	set_cur_word(OBJ_Y_POS, cur_y() - 1)
	set_hpos_from_object(-0x18)
	if object_probe(COLLISION_UNK3) != 0:
		_bubble_set_burst()
		return
	var water_above: int = wIsInWaterOrSand
	set_hpos_from_object(-0x0C)
	object_probe(COLLISION_UNK3)
	if wIsInWaterOrSand == 0 and water_above == 0:
		_bubble_set_burst()


## .asm_47ce0: every $30 drifts it turns; a wall ahead ($0c left or $0b right, $18 and 7 above it)
## turns it at once; otherwise it drifts along Data_44020 (left) or Data_44050 (right) by OBJ_VAR_2.
func _bubble_object_drift() -> void:
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) == 0:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)
		set_cur(OBJ_VAR_1, 0x30)
		set_cur(OBJ_VAR_2, 0)
		return
	var right: bool = hdir()
	set_hpos_from_object(-0x18, 0x0B if right else -0x0C)
	var wall: bool = (object_probe(COLLISION_UNK4) & 0x0F) != 0
	if not wall:
		hYPos = word(cur_y() - 7)
		wall = (object_probe(COLLISION_UNK4) & 0x0F) != 0
	if wall:
		set_hdir(not right)
		set_cur(OBJ_VAR_1, 0x30)
		set_cur(OBJ_VAR_2, 0)
		return
	var c: int = byte((0x50 if right else 0x20) + cur(OBJ_VAR_2))
	var a: int = bank_byte(0x11, 0x4000 | c)
	if a == 0x80:
		a = bank_byte(0x11, 0x4000 | byte(c - 1))
	else:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) + 1)
	if a != 0:
		set_cur_word(OBJ_X_POS, word(cur_x() + (a - 0x100 if a >= 0x80 else a)))


# --- Nobiiru (objects/nobiiru.asm) ----------------------------------------------------------------

## NobiiruFunc: no collision with objects; NOBIIRU_LEFT grows from HDIR clear (to the left), the other
## from HDIR set; then in, waiting 60 frames (.asm_437f7).
func nobiiru_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, NOBIIRU_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_hdir(cur(OBJ_ID) != NOBIIRU_LEFT)
	_nobiiru_in()


## .asm_437f7: in (box bottom -4, -3 to 2), 60 frames, phase 0.
func _nobiiru_in() -> void:
	set_cur(OBJ_COLLBOX_BOTTOM, 0xFC)
	set_collbox_x(-3, 2)
	set_object_frameset_ptr(FRAMESET_698FF)
	set_cur(OBJ_STATE_DURATION, 60)
	set_cur(OBJ_VAR_1, 0)


## .Func_4380e: by phase (OBJ_VAR_1), when its wait runs out: out in six steps (12 px, then 4 px
## each, the box growing; a full sting from the first), out for 8 frames (then bounced off,
## OBJ_INTERACTION_0B) and $14 more, back in five steps, and in again.
func nobiiru_update() -> void:
	var phase: int = cur(OBJ_VAR_1)
	if phase == 0:
		_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	var right: bool = hdir()
	match phase:
		0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12:
			if phase == 0:
				set_cur(OBJ_VAR_2, 0x0C)
			elif phase == 1:
				set_cur(OBJ_VAR_2, 0x04)
			var out: bool = phase <= 5
			if out != right:
				move_object_left_by_var2()
			else:
				move_object_right_by_var2()
			var entry: Array = NOBIIRU_PHASES[phase]
			var i: int = 3 if right else 0
			set_cur(OBJ_COLLBOX_LEFT, entry[i + 1])
			if phase == 0:
				# The sting's write reuses `a`, so the box's left edge is the interaction byte, not
				# the table's ($ff or $fd).
				set_interaction(OBJ_INTERACTION_FULL_STING)
				set_cur(OBJ_COLLBOX_LEFT, cur(OBJ_INTERACTION_TYPE))
			set_cur(OBJ_COLLBOX_RIGHT, entry[i + 2])
			_nobiiru_next(entry[i], entry[6])
		6:
			set_interaction(OBJ_INTERACTION_0B)
			_nobiiru_next(0x58C3 if right else 0x58EA, 8)
		7:
			_nobiiru_next(0x58C6 if right else 0x58ED, 0x14)
		13:
			set_cur(OBJ_VAR_2, 0x0C)
			if right:
				move_object_left_by_var2()
			else:
				move_object_right_by_var2()
			_nobiiru_in()
		_:
			note_unported("NobiiruFunc phase %d (past its table)" % phase)


## .SetFrameset: the frameset, the wait, the next phase.
func _nobiiru_next(frameset: int, wait: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_STATE_DURATION, wait)
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)


# --- Kobatto (objects/kobatto.asm) ----------------------------------------------------------------

## KobattoFunc: no collision with objects, a box -7..6 (bottom -4), flying along Data_60ec9 from its
## start (.Update: ApplyObjSetMovement).
func kobatto_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, KOBATTO_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69041)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-7, 6)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)
	set_cur(OBJ_VAR_1, 1)
	set_cur(OBJ_VAR_2, DATA_60EC9 & 0xFF)
	set_cur(OBJ_VAR_3, DATA_60EC9 >> 8)


# --- The stove (objects/stove.asm) ----------------------------------------------------------------

## StoveFunc: no collision with objects, a box -9..10 (bottom -9).
func stove_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur_word(OBJ_UPDATE_FUNCTION, STOVE_FUNC_UPDATE & 0xFFFF)
	set_collbox_x(-9, 10)
	set_cur(OBJ_COLLBOX_BOTTOM, -9)
	set_object_frameset_ptr(FRAMESET_69615)
	set_cur(OBJ_VAR_1, 0)


## .Update: by state. Falling (Data_605e0) onto a floor it lands (once it has stood, shaking the
## ground for 24 frames, SFX_063); landed it settles onto the floor and, with floor under both its
## corners, stands (state 0, OBJ_VAR_1 1); state 0 starts a fall. Attacked it slides away 2 px a
## frame, then 1 (OBJ_VAR_2 down every 8 frames) until a wall; touched (OBJSTATE_VANISH_TOUCH) it
## vanishes for a transformed Wario (Func_3173), otherwise flickers 44 frames ($3a). Any other state
## starts a fall.
func stove_update() -> void:
	match cur(OBJ_STATE):
		OBJSTATE_FALL:
			apply_obj_y_movement(DATA_605E0)
			set_hpos_from_object()
			if object_probe(COLLISION_UNK1) == 0:
				return
			store_object_y_from_hpos()
			set_cur(OBJ_STATE, OBJSTATE_LAND)
			if cur(OBJ_VAR_1) != 0 and wGroundShakeCounter == 0:
				wGroundShakeCounter = 24
				wIsWarioGroundShaking = 0
		OBJSTATE_LAND:
			set_hpos_from_object()
			var b: int = object_probe(COLLISION_DOWN)
			store_object_y_from_hpos()
			if b == 0x10:
				return
			hXPos = word(cur_x() - 7)
			if object_probe(COLLISION_UNK2) != 0:
				return
			hXPos = word(cur_x() + 8)
			if object_probe(COLLISION_UNK2) != 0:
				return
			set_cur(OBJ_STATE, 0)
			set_cur(OBJ_VAR_1, 1)
		OBJSTATE_ATTACKED_LEFT_START, OBJSTATE_ATTACKED_RIGHT_START:
			set_cur(OBJ_STATE, OBJSTATE_ATTACKED_LEFT if cur(OBJ_STATE) == OBJSTATE_ATTACKED_LEFT_START
					else OBJSTATE_ATTACKED_RIGHT)
			set_cur(OBJ_VAR_2, 2)
			set_object_frameset_ptr(FRAMESET_69618)
		OBJSTATE_ATTACKED_LEFT, OBJSTATE_ATTACKED_RIGHT:
			_stove_slide(cur(OBJ_STATE) == OBJSTATE_ATTACKED_LEFT)
		OBJSTATE_VANISH_TOUCH:
			if wTransformation != 0:
				func_62e57()
				return
			set_cur(OBJ_STATE, OBJSTATE_3A)
			set_object_frameset_ptr(FRAMESET_69625)
			set_cur(OBJ_STATE_DURATION, 44)
		OBJSTATE_3A:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				_stove_set_land()
		_:
			set_cur(OBJ_STATE, OBJSTATE_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_69615)


## .State34 (attacked from the left: away to the right) and the other way: every 8 frames OBJ_VAR_2
## (the speed) drops (SFX_078), at 0 landing; a wall ahead (10 right, or 9 left, 4 up) lands it.
func _stove_slide(right: bool) -> void:
	if (wGlobalCounter & 0b111) == 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
		if cur(OBJ_VAR_2) == 0:
			_stove_set_land()
			return
	set_hpos_from_object(-4, 10 if right else -9)
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		_stove_set_land()
	elif right:
		move_object_right_by_var2()
	else:
		move_object_left_by_var2()


## .set_land
func _stove_set_land() -> void:
	set_cur(OBJ_STATE, OBJSTATE_LAND)
	set_object_frameset_ptr(FRAMESET_69615)


## KobattoFunc.Update
func kobatto_update() -> void:
	apply_obj_set_movement(DATA_60EC9)


# --- Appleby and its apples (objects/appleby.asm) ------------------------------------------------

## ApplebyFunc: no collision with objects while in its hole, a box -8..7 (bottom -1), out in 5 frames.
func appleby_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, APPLEBY_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_689E9)
	set_cur(OBJ_STATE_DURATION, 5)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)


## .Update: by state. 0 waits in its hole (on screen); $5a comes out ($1d frames, colliding); $5b
## watches until Wario is 4 to $45 px below it and within $40 px either side, then $5c turns to him
## and throws an apple at $46 of $7a frames; $2d goes back in ($1d) and waits 60. Touched to vanish
## it vanishes; attacked or thrown at it is knocked away by the shared routines; any other hit
## sends it back in.
func appleby_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_no_actions()
		if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
			return
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			return
		set_object_frameset_ptr(FRAMESET_68A00)
		set_cur(OBJ_STATE_DURATION, 29)
		set_cur(OBJ_STATE, 0x5A)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	elif state < 0x2A:
		match state:
			OBJSTATE_VANISH_TOUCH:
				vanish_object()
			0x04:
				_appleby_knocked(FUNC_3326)
			0x05:
				_appleby_knocked(FUNC_3317)
			0x28:
				_appleby_knocked(FUNC_33F8)
			0x29:
				_appleby_knocked(FUNC_3407)
			_:
				_appleby_go_in()
	elif state == 0x5A:
		_no_actions()
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(FRAMESET_68A12)
			set_cur(OBJ_STATE, 0x5B)
	elif state == 0x5B:
		if cur(OBJ_STATE_DURATION) != 0:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			return
		var dy: int = byte(wWarioScreenYPos - cur(OBJ_SCREEN_Y_POS))
		if dy < 0x04 or dy >= 0x46:
			return
		var dx: int = byte(cur(OBJ_SCREEN_X_POS) - wWarioScreenXPos)
		if dx < 0x40:
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
			set_object_frameset_ptr(FRAMESET_68A1F)
		elif dx >= 0xC0:
			set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
			set_object_frameset_ptr(FRAMESET_68A3A)
		else:
			return
		set_cur(OBJ_STATE_DURATION, 122)
		set_cur(OBJ_STATE, 0x5C)
	elif state == 0x5C:
		if cur(OBJ_STATE_DURATION) == 0x46:
			create_object_at_relative_pos(OBJ_PARAMS_APPLE_RIGHT if hdir() else OBJ_PARAMS_APPLE_LEFT)
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			_appleby_go_in()
	elif state == 0x2D:
		_no_actions()
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_object_frameset_ptr(FRAMESET_689E9)
			set_cur(OBJ_STATE_DURATION, 60)
			set_cur(OBJ_STATE, 0)


## .asm_47ac4: back into its hole ($2d, $1d frames, no collision).
func _appleby_go_in() -> void:
	set_cur(OBJ_STATE, 0x2D)
	set_object_frameset_ptr(FRAMESET_68A09)
	set_cur(OBJ_STATE_DURATION, 29)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .asm_47af6: knocked away by a shared routine (`routine`) as its update function, at speed 2.
func _appleby_knocked(routine: int) -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, routine)
	set_object_frameset_ptr(FRAMESET_68A63)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	_no_actions()


## AppleFunc_Left and _Right: no collision with objects (SFX_067).
func apple_func_left() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, APPLE_UPDATE1_LEFT & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


func apple_func_right() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, APPLE_UPDATE1_RIGHT & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .Update1_Left and _Right: thrown at Wario $10 px or more away (the way it goes), it flies at 2 px
## a frame (OBJ_VAR_1 1, OBJ_VAR_2 2); otherwise as its params set them.
func apple_update1_left() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, APPLE_UPDATE2_LEFT & 0xFFFF)
	_apple_aim(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) - byte(wWarioScreenXPos + 0x2A))


func apple_update1_right() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, APPLE_UPDATE2_RIGHT & 0xFFFF)
	_apple_aim(byte(wWarioScreenXPos + 0x2A) - byte(cur(OBJ_SCREEN_X_POS) + 0x2A))


func _apple_aim(distance: int) -> void:
	if distance < 0x10:
		return
	set_cur(OBJ_VAR_1, 1)
	set_cur(OBJ_VAR_2, 2)


## .Update2_Left: OBJ_VAR_2 px left a frame. (Its `jr nz` follows a load, so it tests the flags the
## object dispatcher left: never zero after `or BANK("Object Functions 1")`, so it always moves.)
func apple_update2_left() -> void:
	set_cur_word(OBJ_X_POS, word(cur_x() - cur(OBJ_VAR_2)))
	_apple_fly()


## .Update2_Right: OBJ_VAR_2 px right a frame; with OBJ_VAR_1 0 only on odd frames.
func apple_update2_right() -> void:
	if cur(OBJ_VAR_1) != 0 or (wGlobalCounter & 1) != 0:
		set_cur_word(OBJ_X_POS, word(cur_x() + cur(OBJ_VAR_2)))
	_apple_fly()


## .asm_47b9c: state $18 (taken) clears it; $19 (hit) sends it bouncing off away from Wario;
## otherwise it falls along Data_60670.
func _apple_fly() -> void:
	match cur(OBJ_STATE):
		0x18:
			set_cur(OBJ_FLAGS, 0)
		0x19:
			var left: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			set_cur_word(OBJ_UPDATE_FUNCTION, (APPLE_ROLL_LEFT if left else APPLE_ROLL_RIGHT) & 0xFFFF)
			set_cur(OBJ_VAR_3, 0)
		_:
			apply_obj_y_movement(DATA_60670)


## .Func_47bd3 and .Func_47bd8: a pixel a frame along Data_60040.
func apple_roll_left() -> void:
	move_object_left()
	_no_actions()
	apply_obj_y_movement(DATA_60040)


func apple_roll_right() -> void:
	move_object_right()
	_no_actions()
	apply_obj_y_movement(DATA_60040)


# --- Sparks, fires, wall cracks (objects/spark.asm, fire.asm, wall_crack.asm) ----------------------

## SparkFunc: no collision with objects, a box -4..2 (bottom -5), first $28 frames one way.
func spark_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, SPARK_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(0x5BD9)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur(OBJ_VAR_1, 1)
	set_collbox_x(-4, 2)
	set_cur(OBJ_COLLBOX_BOTTOM, -5)


## .Update: on even frames a pixel along its line (SPARK_HORIZONTAL right then left, the other up
## then down), $50 frames each way.
func spark_update() -> void:
	if (wGlobalCounter & 1) != 0:
		return
	var forward: bool = cur(OBJ_VAR_1) != 0
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE_DURATION, 0x50)
		set_cur(OBJ_VAR_1, 0 if forward else 1)
		return
	var horizontal: bool = cur(OBJ_ID) == SPARK_HORIZONTAL
	if forward:
		if horizontal:
			move_object_right()
		else:
			move_object_up()
	elif horizontal:
		move_object_left()
	else:
		move_object_down()


## FireFunc: no collision with objects, a box -8..7 (bottom 0); its update does nothing.
func fire_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, FIRE_FUNC_UPDATE & 0xFFFF)
	set_object_frameset_ptr(0x5C0A)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 0)


func _object_does_nothing() -> void:
	pass


## WallCrackClosedFunc and WallCrackOpenFunc: no collision with objects; .Update keeps it from
## acting.
func wall_crack_closed_func() -> void:
	_wall_crack(0x6052)


func wall_crack_open_func() -> void:
	_wall_crack(0x605F)


func _wall_crack(frameset: int) -> void:
	set_object_frameset_ptr(frameset)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, WALL_CRACK_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_no_actions()


# --- Water drops (objects/water_drop.asm) ----------------------------------------------------------

## WaterDropFunc: no collision with objects, a box -6..4 (bottom -1); hanging (.asm_49ddd).
func water_drop_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, WATER_DROP_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-6, 4)
	set_cur(OBJ_COLLBOX_BOTTOM, -1)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	_water_drop_hang()


## .asm_49ddd: hanging at its home height (kept in OBJ_VAR_1 and _2) for $41 frames, visible.
func _water_drop_hang() -> void:
	set_object_frameset_ptr(0x5761)
	set_cur(OBJ_STATE_DURATION, 0x41)
	set_cur(OBJ_VAR_1, cur(OBJ_Y_POS))
	set_cur(OBJ_VAR_2, cur(OBJ_Y_POS + 1))
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)


## .Func_49d83: state 0 hangs, then falls (FallingYVel_Light) until a floor or water; landed or
## touched it splashes ($5a, $18 frames), then invisibly ($5b, at least $3c frames) rises a pixel a
## frame back home and hangs again.
func water_drop_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		if cur(OBJ_STATE_DURATION) != 0:
			set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
			if cur(OBJ_STATE_DURATION) == 0:
				set_object_frameset_ptr(0x5772)
			return
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0 and wIsInWaterOrSand == 0:
			apply_obj_y_movement(FALLING_Y_VEL_LIGHT)
			return
		store_object_y_from_hpos()
		_water_drop_splash()
		return
	if state == 0x5A:
		_water_drop_splashing()
		return
	if state == 0x5B:
		_water_drop_return()
		return
	_water_drop_splash()


## .asm_49d92: splashing for $18 frames (SFX_0A1).
func _water_drop_splash() -> void:
	set_cur(OBJ_STATE, 0x5A)
	set_object_frameset_ptr(0x5775)
	set_cur(OBJ_STATE_DURATION, 0x18)
	_water_drop_splashing()


## .asm_49da6
func _water_drop_splashing() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur(OBJ_STATE, 0x5B)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	_water_drop_return()


## .asm_49dbd
func _water_drop_return() -> void:
	_no_actions()
	var wait: int = cur(OBJ_STATE_DURATION)
	if wait != 0:
		set_cur(OBJ_STATE_DURATION, wait - 1)
	if cur(OBJ_Y_POS) != cur(OBJ_VAR_1) or cur(OBJ_Y_POS + 1) != cur(OBJ_VAR_2):
		move_object_up()
		return
	if wait == 0:
		_water_drop_hang()


# --- Electric lamps and their sparks (objects/electric_lamp.asm) --------------------------------

## ElectricLampFunc: no collision with objects, discharged.
func electric_lamp_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, ELECTRIC_LAMP_DISCHARGED & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(0x4CC4)


## .Discharged: when wGlobalCounter comes round to 0, charging for 30 frames.
func electric_lamp_discharged() -> void:
	_no_actions()
	if wGlobalCounter != 0:
		return
	set_object_frameset_ptr(0x4CCD)
	set_cur(OBJ_STATE_DURATION, 30)
	set_cur_word(OBJ_UPDATE_FUNCTION, ELECTRIC_LAMP_CHARGING & 0xFFFF)


## .Charging: then a spark drops from it (ObjParams_ElectricLampSpark) and it is discharged again.
func electric_lamp_charging() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(0x4CC4)
	set_cur_word(OBJ_UPDATE_FUNCTION, ELECTRIC_LAMP_DISCHARGED & 0xFFFF)
	create_object_from_cur_obj_pos(OBJ_PARAMS_ELECTRIC_LAMP_SPARK)


## ElectricLampSparkFunc: falling along Data_60040 to a floor (UNK1), then a box -6..5 tall, running
## 2 px a frame towards Wario (SFX_06C).
func electric_lamp_spark_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	apply_obj_y_movement(DATA_60040)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	store_object_y_from_hpos()
	set_cur(OBJ_COLLBOX_TOP, -6)
	set_cur(OBJ_COLLBOX_BOTTOM, 5)
	set_object_frameset_ptr(0x4CA0)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_cur_word(OBJ_UPDATE_FUNCTION, (ELECTRIC_LAMP_SPARK_RIGHT if right else ELECTRIC_LAMP_SPARK_LEFT) & 0xFFFF)


## .GoLeft and .GoRight: 2 px a frame; any state, the floor's end, or a wall ahead (4 px up) clears it.
func electric_lamp_spark_left() -> void:
	set_cur_word(OBJ_X_POS, word(cur_x() - 2))
	_electric_lamp_spark_check()


func electric_lamp_spark_right() -> void:
	set_cur_word(OBJ_X_POS, word(cur_x() + 2))
	_electric_lamp_spark_check()


func _electric_lamp_spark_check() -> void:
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_FLAGS, 0)
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	hYPos = word(cur_y() - 4)
	if object_probe(COLLISION_UNK4) != 0:
		set_cur(OBJ_FLAGS, 0)


# --- The Seeing Eye door (objects/seeing_eye_door.asm) ---------------------------------------------

## SeeingEyeDoorFunc: 24 px down (MoveObjectDownByVar2), a box -3..2 (bottom $17).
func seeing_eye_door_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SEEING_EYE_DOOR_CHECK & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_VAR_2, 24)
	set_cur_word(OBJ_Y_POS, cur_y() + 24)
	set_object_frameset_ptr(0x4C47)
	set_collbox_x(-3, 2)
	set_cur(OBJ_COLLBOX_BOTTOM, 0x17)


## .CheckWarioDistance: the eye looks far right ($2e) or far left ($5a) by Wario's side; then
## .Default.
func seeing_eye_door_check() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SEEING_EYE_DOOR_DEFAULT & 0xFFFF)
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		set_cur(OBJ_VAR_1, 0x2E)
		set_object_frameset_ptr(0x4C59)
	else:
		set_cur(OBJ_VAR_1, 0x5A)
		set_object_frameset_ptr(0x4C47)
	seeing_eye_door_default()


## Closed (its update after .asm_45545): until a visible Wario comes within $36 rows below its eye
## line, then it opens (.CheckWarioDistance).
func seeing_eye_door_closed() -> void:
	_no_actions()
	if wTransformation == TRANSFORMATION_INVISIBLE_WARIO or not _seeing_eye_door_sees():
		return
	seeing_eye_door_check()


## Wario's screen y less the eye line (the door's less $19) is below $36.
func _seeing_eye_door_sees() -> bool:
	return byte(wWarioScreenYPos - byte(cur(OBJ_SCREEN_Y_POS) - 0x19)) < 0x36


## .set_look_around: looking far one way it closes at once; otherwise it looks about (8 frames)
## first.
func _seeing_eye_door_look_around() -> void:
	var eye: int = cur(OBJ_VAR_1)
	if eye == 0x2E or eye == 0x5A:
		_seeing_eye_door_close()
		return
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_object_frameset_ptr(0x4C56 if right else 0x4C4A)
	set_cur(OBJ_STATE_DURATION, 8)
	set_cur_word(OBJ_UPDATE_FUNCTION, SEEING_EYE_DOOR_LOOK_AROUND & 0xFFFF)


func seeing_eye_door_look_around() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_seeing_eye_door_close()


## .asm_45545
func _seeing_eye_door_close() -> void:
	set_object_frameset_ptr(0x4C36)
	set_cur_word(OBJ_UPDATE_FUNCTION, SEEING_EYE_DOOR_CLOSED & 0xFFFF)


## .Default: an invisible Wario, or one out of sight, it stops looking for; any state is cleared
## (colliding again). The eye (OBJ_VAR_1: $5a far left, $5b left, $5c middle, $2d right, $2e far
## right) follows Wario's screen x (d) against its own (e), a step at a time.
func seeing_eye_door_default() -> void:
	if wTransformation == TRANSFORMATION_INVISIBLE_WARIO or not _seeing_eye_door_sees():
		_seeing_eye_door_look_around()
		return
	var d: int = wWarioScreenXPos
	var e: int = cur(OBJ_SCREEN_X_POS)
	if cur(OBJ_STATE) != 0:
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	match cur(OBJ_VAR_1):
		0x5C:
			if byte(e + 0x17) < d:
				_seeing_eye_door_look(0x2D, 0x4C56)
			elif byte(e - 0x18) >= d:
				_seeing_eye_door_look(0x5B, 0x4C4A)
		0x2D:
			if byte(e + 0x46) < d:
				_seeing_eye_door_look(0x2E, 0x4C59)
			elif byte(e + 0x17) >= d:
				_seeing_eye_door_look(0x5C, 0x4C50)
		0x2E:
			_no_actions()
			if byte(e + 0x46) >= d:
				_seeing_eye_door_look(0x2D, 0x4C56)
		0x5B:
			if byte(e - 0x18) < d:
				_seeing_eye_door_look(0x5C, 0x4C50)
			elif byte(e - 0x47) >= d:
				_seeing_eye_door_look(0x5A, 0x4C47)
		0x5A:
			_no_actions()
			if byte(e - 0x47) < d:
				_seeing_eye_door_look(0x5B, 0x4C4A)


func _seeing_eye_door_look(eye: int, frameset: int) -> void:
	set_cur(OBJ_VAR_1, eye)
	set_object_frameset_ptr(frameset)


# --- Invisibility potions (objects/mad_scienstein.asm) ---------------------------------------------

## InvisibilityPotionFunc_Left and _Right: thrown, 2 px a frame sideways along Data_60510; taken
## (state $18) it vanishes without a sound (VanishObject_NoSFX).
func invisibility_potion_left() -> void:
	set_cur_word(OBJ_X_POS, word(cur_x() - 2))
	_invisibility_potion_fly()


func invisibility_potion_right() -> void:
	set_cur_word(OBJ_X_POS, word(cur_x() + 2))
	_invisibility_potion_fly()


func _invisibility_potion_fly() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_STATE) == 0x18:
		vanish_object()  # VanishObject_NoSFX
		return
	apply_obj_y_movement(DATA_60510)


## InvisibilityPotionFunc_Drop: dropped (no actions for 15 frames); .Update falls along Data_60540
## and vanishes on a floor (Func_45453) or taken.
func invisibility_potion_drop() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, INVISIBILITY_POTION_DROP_UPDATE & 0xFFFF)
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	invisibility_potion_drop_update()


func invisibility_potion_drop_update() -> void:
	if cur(OBJ_STATE) == 0x18:
		vanish_object()  # VanishObject_NoSFX
		return
	apply_obj_y_movement(DATA_60540)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	store_object_y_from_hpos()
	vanish_object()  # VanishObject_NoSFX


# --- Barrel 1 (objects/barrel.asm) -----------------------------------------------------------------

## Barrel1Func: no collision with objects, a box -7..6 (bottom -9).
func barrel_1_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, BARREL_1_UPDATE_1 & 0xFFFF)
	set_object_frameset_ptr(0x4A7B)
	set_cur(OBJ_STATE_DURATION, 0x0A)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-7, 6)
	set_cur(OBJ_COLLBOX_BOTTOM, -9)


## .Update1: stood on for 10 frames running, it gives (.Update2 after $11 frames).
func barrel_1_update_1() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		set_cur(OBJ_STATE_DURATION, 0x0A)
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(0x4A7E)
	set_cur(OBJ_STATE_DURATION, 0x11)
	set_cur_word(OBJ_UPDATE_FUNCTION, BARREL_1_UPDATE_2 & 0xFFFF)
	set_cur(OBJ_VAR_3, 0)


## .Update2: after its wait (SFX_086), it sinks along Data_60a50 carrying Wario (Func_34fc).
func barrel_1_update_2() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	func_63209(DATA_60A50)


# --- Falling snow (objects/falling_snow.asm) -------------------------------------------------------

## FallingSnowSpawnerFunc: no collision with objects, $1e frames to its first snow.
func falling_snow_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_SPAWNER_WAIT & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, 0x1E)


## .Func_49544: its frame held; then a snow (ObjParams_FallingSnow) and $56 frames.
func falling_snow_spawner_wait() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x56)
	set_cur(OBJ_VAR_1, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_SPAWNER_SHAKE & 0xFFFF)
	create_object_from_cur_obj_pos(OBJ_PARAMS_FALLING_SNOW)


## .Func_49566: then shown $0a px up (and, by bit 0 of rDIV, $0a px left, OBJ_VAR_1 1) for $1d
## frames.
func falling_snow_spawner_shake() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_2, 0x0A)
	set_cur_word(OBJ_Y_POS, cur_y() - 0x0A)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_SPAWNER_SHOWN & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_object_frameset_ptr(0x55C0)
	set_cur(OBJ_STATE_DURATION, 0x1D)
	if (read_div(DIV_FALLING_SNOW_SPAWNER) & 1) == 0:
		return
	set_cur(OBJ_VAR_1, 1)
	move_object_left_by_var2()


## .Func_4959d: then back where it was, invisible, $3c frames to the next snow.
func falling_snow_spawner_shown() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x3C)
	if cur(OBJ_VAR_1) != 0:
		move_object_right_by_var2()
	set_cur_word(OBJ_Y_POS, cur_y() + cur(OBJ_VAR_2))
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_SPAWNER_WAIT & 0xFFFF)


## FallingSnowFunc: no collision with objects; after its wait, loose for $20 frames (SFX_080).
func falling_snow_func() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(0x558F)
	set_cur(OBJ_STATE_DURATION, 0x20)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_LOOSE & 0xFFFF)


## .Func_495ef: then falling, 8 px lower.
func falling_snow_loose() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(0x55A6)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_FALL & 0xFFFF)
	set_cur_word(OBJ_Y_POS, cur_y() + 8)


## .Func_49610: along Data_603e0 to a floor (lands, $2d frames); taken ($18) it falls on as
## .Func_49675; any other state bursts it ($11 frames); then gone (.Func_496ae; SFX_0A1).
func falling_snow_fall() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0x18:
		set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_TAKEN & 0xFFFF)
		set_object_frameset_ptr(0x55D6)
		return
	if state != 0:
		set_object_frameset_ptr(0x55CB)
		set_cur(OBJ_STATE_DURATION, 0x11)
	else:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0:
			apply_obj_y_movement(DATA_603E0)
			return
		store_object_y_from_hpos()
		set_object_frameset_ptr(0x55AF)
		set_cur(OBJ_STATE_DURATION, 0x2D)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_GONE & 0xFFFF)


## .Func_49675: falling to a floor, then 7 frames and gone.
func falling_snow_taken() -> void:
	_no_actions()
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		apply_obj_y_movement(DATA_603E0)
		return
	store_object_y_from_hpos()
	set_object_frameset_ptr(0x55D9)
	set_cur(OBJ_STATE_DURATION, 7)
	set_cur_word(OBJ_UPDATE_FUNCTION, FALLING_SNOW_GONE & 0xFFFF)


## .Func_496ae
func falling_snow_gone() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Wolfenboss's platform (objects/wolfenboss.asm) ------------------------------------------------

## WolfenbossPlatformFunc: visible, no collision with objects, bit 4 of its substate, a box -8..7
## (bottom 8); waiting.
func wolfenboss_platform_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_PLATFORM_WAIT_OPEN & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69E72)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_collbox_x(-8, 7)
	set_cur(OBJ_COLLBOX_BOTTOM, 8)


## .WaitOpen: its frame held until a state $2f, then 80 frames open.
func wolfenboss_platform_wait_open() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	if cur(OBJ_STATE) != 0x2F:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_PLATFORM_OPEN & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 80)


## .Open: then knocked away (OBJ_VAR_2 2).
func wolfenboss_platform_open() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, WOLFENBOSS_PLATFORM_DISAPPEAR & 0xFFFF)


## .Disappear: Func_3326 while on screen; then gone for good (Func_56326).
func wolfenboss_platform_disappear() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0:
		func_62840()  # Func_3326
		return
	func_56326()


## Func_56326: gone for good, its object-map nibble 7 (Func_ba42).
func func_56326() -> void:
	set_cur(OBJ_FLAGS, 0)
	set_cur_object_map_nibble(0x07)


# --- The Shoot minigame's goal counters (objects/shoot.asm) -----------------------------------------

func shoot_goal_counter_func() -> void:
	_goal_counter_start(SHOOT_GOAL_COUNTER_UPDATE)


func wario_goal_counter_func() -> void:
	_goal_counter_start(WARIO_GOAL_COUNTER_UPDATE)


## ShootGoalCounterFunc and WarioGoalCounterFunc: kept from despawning (OBJSUBFLAG_UNK_4), no
## collision with objects, frame $3c, $58 px up (MoveObjectUpByVar2).
func _goal_counter_start(update: int) -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, update & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_FRAME, 0x3C)
	set_cur(OBJ_VAR_2, 0x58)
	set_cur_word(OBJ_Y_POS, cur_y() - cur(OBJ_VAR_2))


## ShootGoalCounterFunc.UpdateScore: its goals (wShootGoals) shown; the third also clears wBossState.
func shoot_goal_counter_update() -> void:
	if _goal_counter_update(wram1[W_SHOOT_GOALS]) == 3:
		wBossState = 0


func wario_goal_counter_update() -> void:
	_goal_counter_update(wram1[W_WARIO_GOALS])


## .UpdateScore: no actions, its frame held; the first goal shows it, the second and third set
## frames $3d and $3e. The goals.
func _goal_counter_update(goals: int) -> int:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 0x7F)
	match goals:
		1:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
		2:
			set_cur(OBJ_FRAME, 0x3D)
		3:
			set_cur(OBJ_FRAME, 0x3E)
	return goals


# --- The cart (objects/cart.asm) --------------------------------------------------------------------

## CartFunc: visible, no collision with objects, a box -15..14 (bottom -12); waiting.
func cart_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, CART_WAITING & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_69199)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-15, 14)
	set_cur(OBJ_COLLBOX_BOTTOM, -12)


## .Waiting: a one-way platform (SetOneWayPlatformAction) until stood on; then rolling.
func cart_waiting() -> void:
	set_one_way_platform_action()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur_word(OBJ_UPDATE_FUNCTION, CART_MOVING & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_6919E)


## .Moving: on even frames a pixel its way (CART_RIGHT right, otherwise left), Wario standing on it
## carried too unless his side probe (Func_19706, Func_19713: may break blocks) meets a wall; a block
## 4 px up and 14 px ahead (15 left; Func_3513) stops it for good (CartStoppedFunc). SFX_06D every
## 64 frames is not simulated.
func cart_moving() -> void:
	_cart_roll(FRAMESET_69199)


## The cart's roll, stopped at a wall with `stopped` (CartFunc's Frameset_69199, the variable cart's
## Frameset_691bf).
func _cart_roll(stopped: int) -> void:
	set_one_way_platform_action()
	if (wGlobalCounter & 1) != 0:
		return
	var right: bool = cur(OBJ_ID) == CART_RIGHT
	set_hpos_from_object(-4, 0x0E if right else -0x0F)
	if object_probe(COLLISION_UNK4) != 0:
		set_object_frameset_ptr(stopped)
		set_cur_word(OBJ_UPDATE_FUNCTION, CART_STOPPED_FUNC & 0xFFFF)
		return
	if right:
		move_object_right()
	else:
		move_object_left()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	wBlockFuncWarioFlag = 1
	var b: int = check_bottom_right_breaking() if right else check_bottom_left_breaking()
	wBlockFuncWarioFlag = 0
	if b != 0:
		return
	if right:
		move_wario_right(1)
	else:
		move_wario_left(1)


## IsTreasureCollected (WRAMX bank 2): a treasure's bit, `treasure` / 8 bytes into
## wTreasuresCollected (bit 2 picking the high nibble, its low 2 bits the bit in it). Only the byte
## holding TRUCK_WHEEL is traced; any other, or an untraced trace, is unknown (false, noted).
func is_treasure_collected(treasure: int) -> bool:
	if treasure >> 3 != 7 or wTreasuresCollected7 < 0:
		note_unported("treasure %02x unknown (wTreasuresCollected + %d not traced)" % [treasure, treasure >> 3])
		return false
	var bit: int = (0x10 if (treasure & 4) != 0 else 0x01) << (treasure & 3)
	return (wTreasuresCollected7 & bit) != 0


## CartVariableFunc: with the truck wheel a cart waiting to roll (Frameset_691bf, .Waiting), without
## it one that stays (Frameset_691a7, CartStoppedFunc); visible, no collision, a box -15..14 (bottom
## -12).
func cart_variable_func() -> void:
	var wheel: bool = is_treasure_collected(TRUCK_WHEEL)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, (CART_VARIABLE_WAITING if wheel else CART_STOPPED_FUNC) & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_collbox_x(-15, 14)
	set_cur(OBJ_COLLBOX_BOTTOM, -12)
	set_object_frameset_ptr(FRAMESET_691BF if wheel else FRAMESET_691A7)


## .Waiting: a one-way platform until stood on; then rolling (Frameset_691aa right, _691b3 left).
func cart_variable_waiting() -> void:
	set_one_way_platform_action()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_cur_word(OBJ_UPDATE_FUNCTION, CART_VARIABLE_MOVING & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_691AA if cur(OBJ_ID) == CART_RIGHT else FRAMESET_691B3)


## .Moving: as the cart's, stopped at a wall with Frameset_691bf.
func cart_variable_moving() -> void:
	_cart_roll(FRAMESET_691BF)


# --- The big leaves (objects/big_leaf.asm) ---------------------------------------------------------

## BigLeafSpawnerFunc: no collision with objects; 20 frames, once Wario is left of it, to its first
## leaves.
func big_leaf_spawner_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_SPAWNER_SPAWN_SET_1 & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_STATE_DURATION, 20)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)


## .SpawnSet1: no actions, its frame held; while Wario is left of 22 px right of it, its frames
## counted down, then two leaves (ObjParams_BigLeaf1, _3) and 160 frames to the next (.SpawnSet2).
func big_leaf_spawner_spawn_set_1() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	if wWarioXPos >= word(cur_x() + 22):
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_SPAWNER_SPAWN_SET_2 & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 160)
	create_object_at_relative_pos(OBJ_PARAMS_BIG_LEAF_1)
	create_object_at_relative_pos(OBJ_PARAMS_BIG_LEAF_3)


## .SpawnSet2: no actions, its frame held; after its frames one leaf (ObjParams_BigLeaf2) and 80
## frames back in .SpawnSet1.
func big_leaf_spawner_spawn_set_2() -> void:
	_no_actions()
	set_cur(OBJ_FRAME_DURATION, 2)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_SPAWNER_SPAWN_SET_1 & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 80)
	create_object_at_relative_pos(OBJ_PARAMS_BIG_LEAF_2)


## BigLeaf1Func: no actions, invisible and without collision for its frames; then appearing
## (Frameset_68732) for 18 more as BigLeafFunc.
func big_leaf_1_func() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 18)
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_2_FUNC & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_object_frameset_ptr(FRAMESET_68732)


## BigLeafFunc (BigLeaf2Func): no actions, no collision with objects; after its frames drifting
## (Frameset_68729, .Update).
func big_leaf_2_func() -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_UPDATE & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68729)


## .Update: a one-way platform. A state: $0a vanishes it (VanishObject2), $01-$09 end it, $0b and on
## (cleared) set it drifting a pixel a frame away from Wario's side (OBJ_STATE_DURATION 1 right, 2
## left). On odd frames it sinks a pixel, carrying a Wario standing on it; in water (Func_352b's
## wIsInWaterOrSand) it sinks away ($14 frames of Frameset_6873b; SFX_08F not simulated).
func big_leaf_update() -> void:
	set_one_way_platform_action()
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if state == 0x0A:
			vanish_object()  # VanishObject2
			return
		if state < 0x0B:
			set_cur(OBJ_FLAGS, 0)
			return
		var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) >= byte(wWarioScreenXPos + 0x2A)
		set_cur(OBJ_STATE_DURATION, 1 if right else 2)
		set_cur(OBJ_STATE, 0)
	var drift: int = cur(OBJ_STATE_DURATION)
	if drift == 1:
		move_object_right()
	elif drift != 0:
		move_object_left()
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		if (wGlobalCounter & 1) == 0:
			return
		move_wario_down(1)
		handle_downwards_floor_transition()
		move_object_down()
	else:
		if (wGlobalCounter & 1) == 0:
			return
		move_object_down()
	set_hpos_from_object()
	object_probe(COLLISION_UNK1)
	if wIsInWaterOrSand == 0:
		return
	_no_actions()
	set_cur_word(OBJ_UPDATE_FUNCTION, BIG_LEAF_SINK & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_6873B)
	set_cur(OBJ_STATE_DURATION, 0x14)


## .Func_42d0e: no actions; after its frames gone.
func big_leaf_sink() -> void:
	_no_actions()
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)
