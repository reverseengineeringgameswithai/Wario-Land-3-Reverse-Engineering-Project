extends TestCase
## The standard enemies after Silky (EnemyFunctions) on invented data (no ROM bytes): Para-Goom,
## and the Sun and the Moon.

const PARA_GOOM_ID: int = 0x09  # its functions are in bank $10 (Object Functions 1 + the ID's high nibble)


## Free blocks with a solid floor along row 10 ($a0), invented framesets.
func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	for y: int in LevelCollision.HEIGHT:
		var objects := PackedByteArray()
		objects.resize(80)
		sim.level.object_rows.append(objects)
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")  # free
	handlers[1] = "h06_4032"  # solid
	sim.level.room_handlers[0] = handlers
	for column: int in LevelCollision.WIDTH:
		sim.level.set_block(10, column, 1)
	var framesets: Dictionary = {}
	for pointer: int in [EnemyFunctions.FRAMESET_68439, EnemyFunctions.FRAMESET_68442, EnemyFunctions.FRAMESET_684BA,
			EnemyFunctions.FRAMESET_6855F, EnemyFunctions.FRAMESET_6845D, EnemyFunctions.FRAMESET_6844B]:
		framesets["%04x" % pointer] = [[0, 4]]
	var movement := PackedByteArray()
	movement.resize(0x600)
	sim.load_object_data({"framesets": {"by_pointer": framesets}, "movement_data": {"bytes": movement.hex_encode()}})
	sim.wCameraSCY = 0x0040
	sim.wCameraSCX = 0x0000
	return sim


## Slot 0 as a Para-Goom at (x, y), its update function ParaGoomFunc (not yet initialised).
func _para_goom(sim: LevelSim, x: int, y: int) -> int:
	var base: int = 0
	sim.wram1[base + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
	sim.wram1[base + ObjectSim.OBJ_UNK_02] = 0xA0
	sim.wram1[base + ObjectSim.OBJ_Y_POS] = y & 0xFF
	sim.wram1[base + ObjectSim.OBJ_Y_POS + 1] = y >> 8
	sim.wram1[base + ObjectSim.OBJ_X_POS] = x & 0xFF
	sim.wram1[base + ObjectSim.OBJ_X_POS + 1] = x >> 8
	sim.wram1[base + ObjectSim.OBJ_ID] = PARA_GOOM_ID
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_TOP] = EnemyFunctions.COLLBOX_TOP_SHORT
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] = ObjectSim.OBJSUBFLAG_UNINITIALISED
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = EnemyFunctions.PARA_GOOM_FUNC & 0xFF
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION + 1] = (EnemyFunctions.PARA_GOOM_FUNC >> 8) & 0xFF
	return base


func test_a_para_goom_in_the_air_grows_tall_floats_down_half_a_pixel_a_frame_and_lands() -> void:
	var sim: LevelSim = _sim()
	var base: int = _para_goom(sim, 0x60, 0x80)  # 32 px above the floor
	sim.wGlobalCounter = 0
	sim.update_objects()  # ParaGoomFunc
	sim.update_objects()  # .Init: .Default finds nothing under it
	assert_true(sim.unported_slots.is_empty(), "all ported: %s" % [sim.object_unported])
	assert_eq([sim.wram1[base + ObjectSim.OBJ_STATE], sim.wram1[base + ObjectSim.OBJ_COLLBOX_TOP],
			sim.wram1[base + ObjectSim.OBJ_INTERACTION_TYPE]],
			[ObjectStates.OBJSTATE_STANDING_FALL, EnemyFunctions.COLLBOX_TOP_TALL, EnemyFunctions.OBJ_INTERACTION_TOP_STING])
	var frames: int = 0
	while sim.wram1[base + ObjectSim.OBJ_STATE] == ObjectStates.OBJSTATE_STANDING_FALL and frames < 100:
		sim.wGlobalCounter = frames & 0xFF
		sim.update_objects()
		frames += 1
	assert_eq([frames, sim.wram1[base + ObjectSim.OBJ_Y_POS], sim.wram1[base + ObjectSim.OBJ_STATE]], [63, 0xA0, 0x5C],
			"32 px at half a pixel a frame, then landed")
	for frame: int in 10:
		sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE], 0x00, "10 frames later, .Default")


func test_a_walking_para_goom_stings_in_front_after_its_grace_and_grows_tall_every_256_frames() -> void:
	var sim: LevelSim = _sim()
	var base: int = _para_goom(sim, 0x60, 0xA0)
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] = 0
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = EnemyFunctions.PARA_GOOM_FUNC_UPDATE & 0xFF
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION + 1] = (EnemyFunctions.PARA_GOOM_FUNC_UPDATE >> 8) & 0xFF
	sim.wram1[base + ObjectSim.OBJ_STATE] = 0x01
	sim.update_objects()
	assert_eq([sim.wram1[base + ObjectSim.OBJ_STATE], sim.wram1[base + ObjectSim.OBJ_STATE_DURATION],
			sim.wram1[base + ObjectSim.OBJ_INTERACTION_TYPE]], [ObjectStates.OBJSTATE_WALK, 0x0A, ObjectStates.OBJ_INTERACTION_01])
	for frame: int in 10:
		sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_INTERACTION_TYPE], ObjectStates.OBJ_INTERACTION_FRONT_STING, "after 10 frames")
	sim.wram1[base + ObjectSim.OBJ_VAR_1] = 0xFF
	sim.update_objects()
	assert_eq([sim.wram1[base + ObjectSim.OBJ_STATE], sim.wram1[base + ObjectSim.OBJ_STATE_DURATION]], [0x2D, 0xA3],
			"the 256th frame: a change")
	for frame: int in 0xA3:
		sim.update_objects()
	assert_eq([sim.wram1[base + ObjectSim.OBJ_STATE], sim.wram1[base + ObjectSim.OBJ_COLLBOX_TOP],
			sim.wram1[base + ObjectSim.OBJ_INTERACTION_TYPE]],
			[ObjectStates.OBJSTATE_WALK, EnemyFunctions.COLLBOX_TOP_TALL, EnemyFunctions.OBJ_INTERACTION_TOP_STING], "walking tall")


func test_an_enemy_state_into_unported_code_leaves_its_slot_unjudged() -> void:
	var sim: LevelSim = _sim()
	var base: int = _para_goom(sim, 0x60, 0xA0)
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] = 0
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = EnemyFunctions.PARA_GOOM_FUNC_UPDATE & 0xFF
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION + 1] = (EnemyFunctions.PARA_GOOM_FUNC_UPDATE >> 8) & 0xFF
	sim.wram1[base + ObjectSim.OBJ_FRAMESET_PTR] = EnemyFunctions.FRAMESET_68439 & 0xFF
	sim.wram1[base + ObjectSim.OBJ_FRAMESET_PTR + 1] = EnemyFunctions.FRAMESET_68439 >> 8
	sim.wram1[base + ObjectSim.OBJ_STATE] = 0x60  # past its table
	sim.update_objects()
	assert_eq(sim.unported_slots, [0] as Array[int])
	assert_eq(sim.object_unported, ["ParaGoomFunc state 60"], "named, and nothing else")


## Invented snowflake params (21 bytes, with offsets): y and x -8, an ID in bank $12, SnowflakeFunc_Left.
const SNOWFLAKE: String = "f8f8" + "21" + "27" + "f4fbfa04" + "0000" + "6e51" + "00" + "000000" + "00" + "00" + "0845" + "80"


## wCurObj as a Brrr Bear at (x, y), walking, on screen at (screen_x, 100).
func _brrr_bear(sim: LevelSim, x: int, y: int, screen_x: int, facing_right: bool) -> void:
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {},
			"object_params": {"%04x" % EnemyFunctions.OBJ_PARAMS_SNOWFLAKE_LEFT: SNOWFLAKE,
				"%04x" % EnemyFunctions.OBJ_PARAMS_SNOWFLAKE_RIGHT: SNOWFLAKE}}})
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, y)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, x)
	sim.set_cur(ObjectSim.OBJ_ID, 0x20)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, screen_x)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_HDIR if facing_right else 0)
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_WALK)
	sim.set_cur(ObjectSim.OBJ_INTERACTION_TYPE, ObjectStates.OBJ_INTERACTION_01)


func test_brrr_bear_blows_a_snowflake_at_wario_ahead_and_level_then_turns() -> void:
	var sim: LevelSim = _sim()
	_brrr_bear(sim, 0x100, 0xA0, 100, false)
	sim.wWarioScreenYPos = 104  # within $18 rows
	sim.wWarioScreenXPos = 70  # 30 px ahead (left), within $48
	sim.brrr_bear_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[0x2D, 0x39, EnemyFunctions.FRAMESET_6913D])
	for frame: int in 0x39 - 0x22:
		sim.brrr_bear_update()
	assert_eq([sim.wram1[ObjectSim.OBJ_FLAGS] & ObjectSim.OBJFLAG_ACTIVE, sim.wram1[ObjectSim.OBJ_ID]], [ObjectSim.OBJFLAG_ACTIVE, 0x21],
			"with $22 frames left, a snowflake")
	assert_eq([sim.wram1[ObjectSim.OBJ_Y_POS], sim.wram1[ObjectSim.OBJ_X_POS]], [0x98, 0xF8], "8 px up and left")
	for frame: int in 0x22:
		sim.brrr_bear_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_TURN_AROUND_START, "then a turn")


func test_brrr_bear_with_wario_near_behind_turns_and_far_away_walks() -> void:
	var sim: LevelSim = _sim()
	_brrr_bear(sim, 0x100, 0xA0, 100, true)  # facing right
	sim.wWarioScreenYPos = 100
	sim.wWarioScreenXPos = 70  # behind it
	sim.brrr_bear_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_TURN_AROUND_START)
	_brrr_bear(sim, 0x100, 0xA0, 100, true)
	sim.wWarioScreenXPos = 200  # $64 px ahead: too far
	sim.wGlobalCounter = 0
	sim.brrr_bear_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_word(ObjectSim.OBJ_X_POS)], [ObjectStates.OBJSTATE_WALK, 0x101], "a step")


func test_an_attack_only_rocks_brrr_bear_until_wario_has_the_garlic_or_better() -> void:
	var sim: LevelSim = _sim()
	_brrr_bear(sim, 0x100, 0xA0, 100, false)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x04)
	sim.brrr_bear_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x08, "a wobble")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x04)
	sim.wram1[ObjectSim.W_EFFECTIVE_POWER_UP] = EnemyFunctions.GARLIC_OR_BETTER
	sim.brrr_bear_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_VAR_2)], [ObjectStates.OBJSTATE_ATTACKED_LEFT, 1], "knocked away")


func test_a_snowflake_flies_2_px_a_frame_and_bursts_for_12_frames_once_its_state_is_set() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x100)
	sim.snowflake_func_left()
	assert_eq([sim.cur_word(ObjectSim.OBJ_X_POS), sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_NO_COLLISION],
			[0xFE, ObjectSim.OBJFLAG_NO_COLLISION])
	sim.set_cur(ObjectSim.OBJ_STATE, 1)
	sim.snowflake_func_left()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[EnemyFunctions.SNOWFLAKE_FUNC_UPDATE & 0xFFFF, 0x0C])
	for frame: int in 11:
		sim.snowflake_update()
	assert_true(sim.cur(ObjectSim.OBJ_FLAGS) != 0, "11 frames: still there")
	sim.snowflake_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "cleared at 12")


func test_haridama_charges_wario_ahead_and_level_and_turns_at_a_wall() -> void:
	var sim: LevelSim = _sim()
	sim.level.set_block(9, 3, 1)  # a wall at x $30-$3f, row 9
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x60)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 70  # 30 px left: ahead
	sim.wWarioScreenYPos = 100
	sim.haridama_init()
	assert_true(not sim.hdir(), "facing Wario")
	sim.haridama_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x5B, 0x12], "alerted")
	for frame: int in 0x12:
		sim.haridama_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)], [0x32, EnemyFunctions.OBJ_INTERACTION_HARIDAMA],
			"charging, spikes out")
	sim.haridama_update()
	assert_eq(sim.cur_x(), 0x5E, "2 px a frame")
	var frames: int = 0
	while sim.cur(ObjectSim.OBJ_STATE) == 0x32 and frames < 20:
		sim.haridama_update()
		frames += 1
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_x(), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)],
			[0x5A, 0x48, EnemyFunctions.OBJ_INTERACTION_06], "a wall 9 px ahead: turning, spikes in")


func test_the_hand_waits_out_of_the_sand_rises_24_px_waits_and_sinks_back() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_INVISIBLE)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.hand_func()
	sim.wIsInSand = 1
	for frame: int in 60:
		sim.hand_update()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0, 50], "not while Wario is in sand")
	sim.wIsInSand = 0
	for frame: int in 50:
		sim.hand_update()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE], [1, 0], "shown")
	for frame: int in 41 + 8:
		sim.hand_update()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur_y()], [9, 0xA0 - 24], "6 steps of 4 px up")
	sim.wWarioScreenYPos = 200  # below it: it does not wait
	for frame: int in 56:
		sim.hand_update()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur_y()], [10, 0xA0 - 18], "then 6 px down")
	for frame: int in 2 * 3:
		sim.hand_update()
	assert_eq(sim.cur_y(), 0xA0, "and back")


func test_spear_bot_winds_up_at_wario_ahead_thrusts_with_its_spear_out_and_turns_back_at_a_wall() -> void:
	var sim: LevelSim = _sim()
	sim.level.set_block(9, 3, 1)  # a wall at x $30-$3f, row 9
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x50)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 70  # 30 px left: ahead
	sim.wWarioScreenYPos = 100
	sim.spear_bot_init()
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_WALK)
	sim.spear_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2D, 20], "the wind-up")
	for frame: int in 20:
		sim.spear_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_COLLBOX_LEFT), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE),
			sim.cur(ObjectSim.OBJ_VAR_1)], [0x2E, 0xF6, ObjectStates.OBJ_INTERACTION_FRONT_STING, 2], "the spear out, stinging")
	var frames: int = 0
	while sim.cur(ObjectSim.OBJ_STATE) == 0x2E and frames < 40:
		sim.spear_bot_update()
		frames += 1
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_x(), sim.cur(ObjectSim.OBJ_VAR_1)], [0x5A, 0x45, 1],
			"a pixel a frame until 6 px ahead is wall ($3f), then turning back with a thrust used")


func test_hammer_bot_raises_its_bouncy_hammer_at_wario_ahead_and_walks_with_it_a_pixel_a_frame() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 140  # 40 px right: behind it as it faces left
	sim.wWarioScreenYPos = 100
	sim.hammer_bot_init()
	sim.set_hdir(false)
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_WALK)
	sim.hammer_bot_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_WALK, "Wario behind: it walks on")
	sim.wWarioScreenXPos = 70  # 30 px ahead
	sim.hammer_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_COLLBOX_LEFT), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)],
			[0x2D, 0xF0, EnemyFunctions.OBJ_INTERACTION_BOUNCY], "the hammer up: 16 px ahead, bouncy")
	for frame: int in 20:
		sim.hammer_bot_update()
	var x: int = sim.cur_x()
	sim.hammer_bot_update()
	sim.hammer_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), x - sim.cur_x()], [0x2E, 2], "then a pixel a frame")
	sim.wGroundShakeCounter = 0x10
	sim.hammer_bot_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x1A, "a ground shake: the shared state $1a")


func test_hebarii_crawls_the_ceiling_drops_a_projectile_and_falls_off_when_the_ground_shakes() -> void:
	var sim: LevelSim = _sim()
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {},
			"object_params": {"%04x" % EnemyFunctions.OBJ_PARAMS_HEBARII_PROJECTILE: SNOWFLAKE}}})
	for column: int in LevelCollision.WIDTH:
		sim.level.set_block(4, column, 1)  # a ceiling along row 4 ($40-$4f)
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x5C)  # 18 px below it reaches the ceiling
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.wWarioScreenXPos = 140
	sim.hebarii_init()
	assert_true(sim.hdir(), "facing Wario")
	for frame: int in 19:
		sim.wGlobalCounter = frame
		sim.hebarii_attached()
	assert_eq(sim.cur_x(), 0x80 + 5, "a pixel every fourth frame (0, 4, ... 16)")
	sim.hebarii_attached()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [1, 41], "then shooting")
	for frame: int in 12:
		sim.hebarii_attached()
	assert_eq([sim.wram1[ObjectSim.OBJ_FLAGS] & ObjectSim.OBJFLAG_ACTIVE, sim.wram1[ObjectSim.OBJ_ID]], [ObjectSim.OBJFLAG_ACTIVE, 0x21],
			"at 30 frames left (the twelfth frame), a projectile")
	sim.wGroundShakeCounter = 0x10
	sim.hebarii_attached()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[0x2D, EnemyFunctions.HEBARII_FUNC_DETACHED & 0xFFFF], "shaken off: falling")


func test_an_owl_woken_flies_up_54_px_then_patrols_turning_every_60_frames() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x90)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.owl_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), EnemyFunctions.OWL_FUNC_SLEEP & 0xFFFF, "asleep by day")
	sim.owl_sleep()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), EnemyFunctions.OWL_FUNC_SLEEP & 0xFFFF, "until touched")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0E)
	sim.owl_sleep()
	for frame: int in 0x28:
		sim.owl_wake_up()
	for frame: int in 54:
		sim.owl_fly_upwards()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)], [0x90 - 54, EnemyFunctions.OBJ_INTERACTION_OWL])
	var right: bool = sim.hdir()
	for frame: int in 30:
		sim.owl_fly()
	assert_eq([sim.hdir(), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [not right, 60], "turned after the first 30")


func test_a_tadpole_leaps_left_2_px_a_frame_and_splashes_into_water() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x90)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 2)
	sim.tadpole_func()
	sim.tadpole_hidden()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE, 0, "shown on screen")
	for frame: int in 3:
		sim.tadpole_ready()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[EnemyFunctions.TADPOLE_FUNC_LEAP & 0xFFFF, 0x20], "the leap")
	sim.tadpole_leap()
	assert_eq(sim.cur_x(), 0x7E, "2 px left a frame")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x08)
	sim.tadpole_leap()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.FUNC_3407, "hit: the shared knock-back routine")


func test_teruteru_counts_eight_hits_and_hides_while_wario_is_blind() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_INVISIBLE)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x60)
	sim.teruteru_init()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE)], [8, ObjectStates.OBJSTATE_WALK], "8 hits, flying")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x16)
	sim.teruteru_update()
	assert_eq(sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, 7, "a slide counts one")
	sim.wTransformation = WarioRam.TRANSFORMATION_BLIND
	sim.teruteru_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE, ObjectSim.OBJFLAG_INVISIBLE, "hidden from a blind Wario")
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, (sim.cur(ObjectSim.OBJ_SUBSTATE) & 0xF0) | 2)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x17)
	sim.teruteru_update()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[ObjectFunctions.STARS_FUNC & 0xFFFF, 33], "the last hit vanishes it (VanishObject2)")


func test_a_zombie_rises_when_wario_is_32_to_63_px_away_and_throws_its_head_at_him_close() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenYPos = 100
	sim.wWarioScreenXPos = 120  # 20 px: too close
	sim.zombie_func()
	sim.zombie_init()
	sim.zombie_underground()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), EnemyFunctions.ZOMBIE_FUNC_UNDERGROUND & 0xFFFF, "too close: it waits")
	sim.wWarioScreenXPos = 150  # 50 px
	sim.zombie_underground()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[EnemyFunctions.ZOMBIE_FUNC_START_RISE & 0xFFFF, 20], "32-63 px: it rises")
	for frame: int in 20:
		sim.zombie_start_rise()
	for frame: int in 20:
		sim.zombie_rising()
	assert_eq([sim.cur(ObjectSim.OBJ_COLLBOX_TOP), sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F], [0xE8, 1], "risen: walking")
	sim.wWarioScreenXPos = 130  # 30 px ahead (it faces him)
	sim.zombie_on_surface()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE_DURATION)], [3, 50], "the head throw")


func test_fire_bot_is_spear_bot_with_fire_and_ignores_a_hot_wario() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 70  # 30 px ahead
	sim.wWarioScreenYPos = 100
	sim.fire_bot_init()
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_WALK)
	sim.wTransformation = WarioRam.TRANSFORMATION_HOT_WARIO
	sim.fire_bot_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_WALK, "a Hot Wario is ignored")
	sim.wTransformation = 0
	sim.fire_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2D, 23], "a longer wind-up")
	for frame: int in 23:
		sim.fire_bot_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)], [0x2E, EnemyFunctions.OBJ_INTERACTION_FIRE_BOT])


const DOUGHNUT: String = "eef7" + "0b" + "1a" + "f8fcfc04" + "0000" + "5246" + "00" + "000000" + "00" + "00" + "f860" + "00"


func test_the_doughnuteer_throws_a_doughnut_at_wario_ahead_then_turns_away() -> void:
	var sim: LevelSim = _sim()
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {},
			"object_params": {"%04x" % EnemyFunctions.OBJ_PARAMS_DOUGHNUT_LEFT: DOUGHNUT}}})
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0xA0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 70
	sim.wWarioScreenYPos = 100
	sim.doughnuteer_init()
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_WALK)
	sim.doughnuteer_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x5A, 0x33], "the throw")
	for frame: int in 0x33 - 0x1A + 1:
		sim.doughnuteer_update()
	assert_eq(sim.wram1[ObjectSim.OBJ_ID], 0x0B, "with $1a frames left, a doughnut")
	for frame: int in 0x19:
		sim.doughnuteer_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2B, 0x1A], "then turning")


func test_a_ground_shake_pauses_an_enemy_or_wobbles_a_lying_one_by_rdiv() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x1A)
	sim.common_enemy_state(0x1A)
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x1B, 7])
	for frame: int in 7:
		sim.common_enemy_state(sim.cur(ObjectSim.OBJ_STATE))
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_STANDING_FALL_START, "then a fall")
	sim.div_replay = true
	sim.div_queue.append([ObjectFunctions.DIV_FUNC_6305F, 0x41])
	sim.common_enemy_state(0x1C)
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_VAR_2), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[ObjectStates.OBJSTATE_WOBBLE_LEFT, 1, 4], "rDIV's bit 0 set: a wobble left")


func test_pneumo_bobs_then_dives_at_wario_below_and_rises_back() -> void:
	var sim: LevelSim = _sim()
	sim.pneumo_bob = PackedByteArray([1, 0xFF, 0x80])
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x60)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 100)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 60)
	sim.wWarioScreenXPos = 70  # 30 px left
	sim.wWarioScreenYPos = 120  # 60 px below
	sim.wGlobalCounter = 1
	sim.pneumo_func()
	sim.pneumo_update()
	sim.pneumo_update()
	assert_eq(sim.cur_y(), 0x60, "down 1, up 1")
	sim.pneumo_update()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_VAR_2), sim.hdir()], [3, 1, false],
			"the bob's end: a dive at Wario")
	sim.pneumo_update()  # its one-frame wait
	sim.pneumo_update()
	assert_eq([sim.cur_y(), sim.cur_x(), sim.cur(ObjectSim.OBJ_VAR_1)], [0x62, 0x7F, 1], "2 px down, 1 across")
	sim.wWarioScreenYPos = 70  # level with it now
	sim.pneumo_update()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE_DURATION)], [4, 255], "then rising back")
	sim.pneumo_update()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_VAR_1)], [0x60, 0])


func test_omodonmeka_catches_wario_and_lifts_him_64_px_above_its_home() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x90)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.omodonmeka_func()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)], [0x90, EnemyFunctions.OBJ_INTERACTION_OMODONMEKA])
	sim.wWarioYPos = 0xA0
	sim.wAutoMoveState = 1
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_ACTIVATE)
	sim.omodonmeka_update()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.wWarioXPos], [5, 0x78], "caught: lifting him, 8 px ahead of him")
	var frames: int = 0
	while (sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F) == 5 and frames < 200:
		sim.omodonmeka_update()
		frames += 1
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F], [0x90 - 0x40, 6], "64 px above its home, holding him")
	sim.wAutoMoveState = 0
	sim.omodonmeka_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 1, "he got away")


## An Omodon (slot 1, out of its carrier's map cell) and its carrier in wCurObj at (0x40, 0x80).
func _omodon_pair(sim: LevelSim) -> int:
	var base: int = ObjectSim.W_OBJECTS + ObjectSim.OBJ_STRUCT_LENGTH
	sim.wram1[base + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_TRANSIENT
	sim.wram1[base + ObjectSim.OBJ_UNK_01] = 8
	sim.wram1[base + ObjectSim.OBJ_UNK_02] = 0xA3
	sim.wram1[base + ObjectSim.OBJ_SCREEN_Y_POS] = 0x50
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_LEFT] = WarioRam.byte(-6)
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_RIGHT] = 6
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_UNK_01, 8)
	sim.set_cur(ObjectSim.OBJ_UNK_02, 0xA3)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x40)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 0x30)
	return base


func test_an_omodonmeka_lowers_itself_to_its_omodon_picks_it_up_and_lifts_it_50_frames() -> void:
	var sim: LevelSim = _sim()
	var omodon: int = _omodon_pair(sim)
	sim.omodonmeka_with_omodon_1_func()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE_DURATION)], [3, 0x28],
			"its Omodon is out: lowering itself to it")
	sim.omodonmeka_with_omodon_update()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x41, 0x28], "down a pixel, not yet 16 px above it")
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 0x40)
	for frame: int in 39:
		sim.omodonmeka_with_omodon_update()
	assert_eq(sim.wram1[omodon + ObjectSim.OBJ_STATE], 0, "39 frames of 40")
	sim.omodonmeka_with_omodon_update()
	assert_eq([sim.wram1[omodon + ObjectSim.OBJ_STATE], sim.wram1[omodon + ObjectSim.OBJ_STATE_DURATION],
			sim.wram1[omodon + ObjectSim.OBJ_COLLBOX_BOTTOM], sim.wram1[omodon + ObjectSim.OBJ_COLLBOX_LEFT],
			sim.wram1[omodon + ObjectSim.OBJ_COLLBOX_RIGHT]], [0x2D, 0x33, 0x10, WarioRam.byte(-7), 7], "picked up, its box grown")
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE_DURATION)], [4, 0x32])
	for frame: int in 50:
		sim.omodonmeka_with_omodon_update()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F], [0x41 - 49, 1], "up 49 px, then waiting")
	sim.omodonmeka_with_omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F, sim.cur(ObjectSim.OBJ_STATE_DURATION)], [2, 0x3C], "for 60 frames")


func test_an_omodonmeka_without_its_omodon_out_makes_one_and_one_struck_flies_off() -> void:
	var sim: LevelSim = _sim()
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {},
			"object_params": {"%04x" % EnemyFunctions.OBJ_PARAMS_OMODON_1: SNOWFLAKE}}})
	var omodon: int = _omodon_pair(sim)
	sim.wram1[omodon + ObjectSim.OBJ_FLAGS] = 0
	sim.omodonmeka_with_omodon_1_func()
	assert_eq([sim.wram1[ObjectSim.OBJ_FLAGS] & ObjectSim.OBJFLAG_ACTIVE, sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F,
			sim.cur(ObjectSim.OBJ_STATE_DURATION)], [ObjectSim.OBJFLAG_ACTIVE, 2, 0x3C], "an Omodon made; waiting 60 frames")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x10)
	sim.omodonmeka_with_omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_ACTION), sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[0x3A, 0x81, EnemyFunctions.OMODONMEKA_WITH_OMODON_FUNC_FLY_OFF & 0xFFFF], "flying off for good")


func test_an_omodon_rises_with_its_carrier_falls_shakes_the_ground_and_lies_solid() -> void:
	var sim: LevelSim = _sim()
	sim.movement_data[EnemyFunctions.DATA_605E0 - ObjectStates.MOVEMENT_DATA_START] = 4
	sim.movement_data[EnemyFunctions.DATA_605E0 - ObjectStates.MOVEMENT_DATA_START + 1] = 0x80
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_TRANSIENT)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x60)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x80)
	sim.set_cur(ObjectSim.OBJ_COLLBOX_LEFT, WarioRam.byte(-7))
	sim.set_cur(ObjectSim.OBJ_COLLBOX_RIGHT, 7)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x2D)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 0x33)
	sim.omodon_func()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x60, 0x32], "a frame's pause")
	sim.set_cur(ObjectSim.OBJ_FLAGS, sim.cur(ObjectSim.OBJ_FLAGS) | ObjectSim.OBJFLAG_STEPPED)
	sim.wGlobalCounter = 1
	sim.omodon_update()
	assert_eq(sim.cur_y(), 0x60, "Wario on it: only on even frames")
	sim.set_cur(ObjectSim.OBJ_FLAGS, sim.cur(ObjectSim.OBJ_FLAGS) & ~ObjectSim.OBJFLAG_STEPPED)
	for frame: int in 50:
		sim.omodon_update()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_COLLBOX_BOTTOM)], [0x60 - 49, 0, 0x0B], "hanging")
	sim.omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE), sim.cur(ObjectSim.OBJ_COLLBOX_LEFT),
			sim.cur(ObjectSim.OBJ_COLLBOX_RIGHT)], [0x2E, EnemyFunctions.OBJ_INTERACTION_OMODON, WarioRam.byte(-6), 6],
			"let go: falling, a pixel narrower")
	var frames: int = 0
	while sim.cur(ObjectSim.OBJ_STATE) == 0x2E and frames < 100:
		sim.omodon_update()
		frames += 1
	assert_eq([sim.cur_y(), frames], [0xA0 - 0x0F, 25], "4 px a frame until 15 px below it is the floor; set 15 px above its top")
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE), sim.wGroundShakeCounter],
			[0x2F, EnemyFunctions.OBJ_INTERACTION_SOLID, 0x18], "the ground shakes; it lies solid")


func test_an_omodon_on_flat_wario_bobs_and_one_that_lands_on_wario_sits_on_his_head() -> void:
	var sim: LevelSim = _sim()
	sim.omodon_bob = PackedByteArray([0, 1, 0x80])
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_TRANSIENT)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x60)
	sim.wTransformation = WarioRam.TRANSFORMATION_FLAT_WARIO
	sim.omodon_func()
	sim.omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_y()], [0, 0x61], "bobbing (a zero step skipped)")
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectStates.OBJSTATE_ACTIVATE)
	sim.wWarioYPos = 0xA0
	sim.omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_y()], [0x5A, 0x88], "24 px above Wario")
	sim.wAutoMoveState = 1
	sim.omodon_update()
	assert_eq(sim.cur_y(), 0x8A, "he is carried: it slides 2 px")
	sim.wAutoMoveState = 0
	for frame: int in 20:
		sim.omodon_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_ACTION), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)],
			[0x2F, 0x9F, EnemyFunctions.OBJ_INTERACTION_SOLID], "20 frames on him, then solid")


func test_a_water_spark_given_a_state_sparks_100_frames_without_actions_then_waits() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_INVISIBLE)
	sim.water_spark_func()
	assert_eq([sim.cur(ObjectSim.OBJ_FLAGS) & (ObjectSim.OBJFLAG_INVISIBLE | ObjectSim.OBJFLAG_NO_COLLISION),
			sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)], [ObjectSim.OBJFLAG_NO_COLLISION, DeviceFunctions.FRAMESET_69B1E])
	sim.water_spark_wait()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), DeviceFunctions.WATER_SPARK_FUNC_WAIT & 0xFFFF, "no state: waiting")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0B)
	sim.water_spark_wait()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[0, 100, DeviceFunctions.FRAMESET_69B12], "sparking")
	for frame: int in 99:
		sim.water_spark_spark()
	assert_eq([sim.cur(ObjectSim.OBJ_ACTION), sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[0x81, DeviceFunctions.WATER_SPARK_FUNC_SPARK & 0xFFFF])
	sim.water_spark_spark()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[DeviceFunctions.WATER_SPARK_FUNC_WAIT & 0xFFFF, DeviceFunctions.FRAMESET_69B1E], "waiting again")


func test_a_held_enemy_wario_turned_from_takes_the_other_side_with_its_own_grab() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_HDIR | 0x03)
	sim.wWarioYPos = 0x60
	sim.wWarioXPos = 0x80
	sim.wGrabState = WarioRam.GRAB_IDLE
	sim.wDirection = WarioRam.DIRECTION_LEFT
	sim.held_turning(ObjectSim.OBJSTATE_19, sim._teruteru_grab)  # grabbed facing right, Wario facing left
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.hdir(), sim.cur(ObjectSim.OBJ_SUBSTATE) & 0x0F],
			[ObjectSim.OBJSTATE_48, false, 8], "the left side, turned, Teruteru's routine bits")
	assert_eq([sim.cur(ObjectSim.OBJ_COLLBOX_TOP), sim.cur(ObjectSim.OBJ_COLLBOX_BOTTOM),
			(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_GRABBED) != 0], [0xF9, 0xFF, true], "its box, grabbed")
	assert_eq([sim.cur_x(), sim.cur_y()], [0x80 - 7, 0x60 - 30], "held by Func_622bd")


func test_a_picked_up_enemy_rises_along_its_table_is_held_above_wario_and_thrown_on_its_arc() -> void:
	var sim: LevelSim = _sim()
	for i: int in 7:  # Data_601c0, invented: (1 frame, -8, +4), (2 frames, -16, +7), the end
		sim.movement_data[0x1C0 + i] = [1, 0xF8, 4, 2, 0xF0, 7, 0][i]
	for i: int in 4:  # Data_60080, invented: up 2, up 2, down 1, the end
		sim.movement_data[0x080 + i] = [0xFE, 0xFE, 1, 0x80][i]
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_COLLBOX_TOP, 0xF4)
	sim.set_cur(ObjectSim.OBJ_COLLBOX_LEFT, 0xFA)
	sim.set_cur(ObjectSim.OBJ_COLLBOX_RIGHT, 5)
	sim.wWarioYPos = 0x60
	sim.wWarioXPos = 0x80
	sim.wGrabState = WarioRam.GRAB_PICK_UP
	sim.enemy_picked_up_start(true)
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_y(), sim.cur_x(), sim.cur(ObjectSim.OBJ_VAR_1)],
			[ObjectSim.OBJSTATE_PICKED_UP_LEFT, 0x58, 0x84, 1], "the first entry at once")
	sim.picked_up(true)
	assert_eq([sim.cur_y(), sim.cur_x(), sim.cur(ObjectSim.OBJ_VAR_1)], [0x50, 0x87, 2], "the second")
	sim.picked_up(true)
	sim.picked_up(true)
	assert_eq([sim.cur_y(), sim.cur_x()], [0x50, 0x87], "the end repeats the last entry")
	sim.wGrabState = WarioRam.GRAB_IDLE
	sim.picked_up(true)
	assert_eq([sim.cur_y(), sim.cur_x(), sim.cur(ObjectSim.OBJ_STATE)], [0x60 - 30, 0x87, ObjectSim.OBJSTATE_19], "held 30 px up")
	sim.wGrabState = WarioRam.GRAB_THROW
	sim.held(true)
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_VAR_2), sim.cur(ObjectSim.OBJ_ACTION)],
			[ObjectSim.OBJSTATE_4F, 3, 0x9F], "thrown right at 3 px a frame")
	var y: int = sim.cur_y()
	sim.thrown_flight(false)
	assert_eq([sim.cur_x(), sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x87 + 3, y - 2, 0], "rising")
	sim.thrown_flight(false)
	sim.thrown_flight(false)
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [y - 3, 1], "then falling")


func test_the_moon_is_the_suns_code_with_its_own_looks_turns_and_stars() -> void:
	for moon: bool in [false, true]:
		var sim: LevelSim = _sim()
		sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
		sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0060)
		sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0080)
		sim.set_cur(ObjectSim.OBJ_VAR_1, 1)  # turning right
		if moon:
			sim.moon_update()
		else:
			sim.sun_update()
		assert_eq([sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR), sim.cur(ObjectSim.OBJ_STATE_DURATION), sim.cur(ObjectSim.OBJ_VAR_1)],
				[EnemyFunctions.FRAMESET_69036 if moon else EnemyFunctions.FRAMESET_68FC0, 40 if moon else 35, 3])
		sim.set_cur(ObjectSim.OBJ_SUBSTATE, 0)  # facing left
		sim.set_cur(ObjectSim.OBJ_VAR_1, 5)  # attacking
		sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 53)
		if moon:
			sim.moon_update()
		else:
			sim.sun_update()
		var shot: String = "object params %04x" % (EnemyFunctions.OBJ_PARAMS_MOON_STAR_LEFT if moon
				else EnemyFunctions.OBJ_PARAMS_SUN_FLAME_LEFT)
		assert_true(shot in sim.unported, "its shot at 52 frames left (no params loaded here)")
