extends TestCase
## Torches, embers, birds, chests, and treasures on invented data (no ROM bytes), each run as its
## update function in wCurObj.

## Invented params without offsets (19 bytes): ID, interaction, box (4), OAM pointer, frameset,
## state duration, vars 1-3, substate, state, update function, flags.
const EMBER: String = "06" + "0e" + "f4fdfb03" + "0048" + "0043" + "00" + "000000" + "00" + "00" + "3f4c" + "80"
## Invented params with offsets (21 bytes), for the treasure.
const TREASURE: String = "e800" + "40" + "01" + "00000000" + "00c0" + "da40" + "07" + "000000" + "00" + "00" + "7049" + "80"


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")  # free
	handlers[1] = "h06_4032"  # solid
	sim.level.room_handlers[0] = handlers
	var params: Dictionary = {}
	for key: String in ["4e80", "4e93", "4ea6", "4eb9"]:
		params[key] = EMBER
	params["4a40"] = TREASURE
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {}, "object_params": params}})
	return sim


## wCurObj as an object at (x, y), active and on screen.
func _cur(sim: LevelSim, x: int, y: int) -> void:
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, y)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, x)


func test_a_torch_drops_a_fast_pair_then_a_slow_pair_of_embers_every_128_frames() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.torch_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.TORCH_FUNC_UPDATE & 0xFFFF)
	sim.wGlobalCounter = 0x7F
	sim.torch_update()
	assert_eq(sim.wram1[ObjectSim.OBJ_FLAGS], 0, "not on a multiple of 128")
	var made: Array = []
	for counter: int in [0x80, 0x81, 0x82, 0x100, 0x101]:
		sim.wGlobalCounter = counter & 0xFF
		sim.torch_update()
		made.append(sim.cur(ObjectSim.OBJ_STATE_DURATION))
	assert_eq(made, [1, 2, 2, 3, 0], "left, then right the next frame; the slow pair waits for 128")
	assert_eq([sim.wram1[ObjectSim.OBJ_ID], sim.wram1[ObjectSim.OBJ_Y_POS], sim.wram1[ObjectSim.OBJ_X_POS]],
			[0x06, 0x80, 0x00], "an ember at the torch")
	var count: int = 0
	for slot: int in ObjectSim.NUM_OBJECTS:
		if (sim.slot_flags(slot) & ObjectSim.OBJFLAG_ACTIVE) != 0:
			count += 1
	assert_eq(count, 4)


func test_an_ember_drifts_and_falls_and_burns_out_where_it_lands() -> void:
	var sim: LevelSim = _sim()
	sim.load_object_data({"movement_data": {"location": "18:4000", "bytes": _movement().hex_encode()},
			"object_groups": {"groups": [], "object_data": {}, "object_params": {}}})
	sim.level.set_block(9, 16, 0x01)  # solid under (y $90, x $108)
	_cur(sim, 0x108, 0x8E)
	sim.torch_ember_left_1()
	assert_eq([sim.cur_word(ObjectSim.OBJ_X_POS), sim.cur_word(ObjectSim.OBJ_Y_POS)], [0x107, 0x8F], "1 px left, 1 down")
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), 0)
	sim.torch_ember_left_1()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.TORCH_EMBER_COMMON_FUNC_DESTROY & 0xFFFF,
			"landed in the solid block")
	assert_eq(sim.cur(ObjectSim.OBJ_STATE_DURATION), 24)
	for frame: int in 24:
		sim._torch_ember_destroy()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0)


## Movement data with Data_60320 ($4320) a steady 1 px fall.
func _movement() -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(0x400)
	data[0x320] = 1
	data[0x321] = 0x80
	return data


func test_a_bird_ahead_of_wario_and_near_takes_off_towards_him() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 60)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 100
	sim.wWarioScreenYPos = 104
	sim.bird_func()
	sim.bird_init()
	assert_true(sim.hdir(), "Wario is to its right")
	sim.bird_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2F, 0x23])
	for frame: int in 0x23:
		sim.bird_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_X_POS), 0x100, "the wind-up")
	sim.bird_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_X_POS), 0x102, "then 2 px a frame")


func test_a_bird_with_wario_behind_turns_round() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 60)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 100
	sim.wWarioScreenYPos = 100
	sim.bird_init()
	sim.wWarioScreenXPos = 20
	sim.bird_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0, 0x0C])
	for frame: int in 0x0C:
		sim.bird_update()
	assert_true(not sim.hdir(), "turned to face him")


func test_a_hit_bird_leaves_stars_and_flies_off_and_a_second_hit_knocks_it_away() -> void:
	var sim: LevelSim = _sim()
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {}, "object_params": {"49c2": TREASURE}}})
	_cur(sim, 0x100, 0x80)
	sim.set_cur(ObjectSim.OBJ_ID, 0x0E)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0B)
	sim.bird_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.BIRD_FUNC_FLY_OFF & 0xFFFF)
	assert_eq(sim.wram1[ObjectSim.OBJ_ID], 0x40, "stars from the params")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0B)
	sim.bird_update()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_VAR_2)],
			[ObjectFunctions.FUNC_3407, 2], "knocked right (it faces left), Garlic or not")


func test_a_chest_opens_once_wario_stands_still_and_its_treasure_rises() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.set_cur(ObjectSim.OBJ_INTERACTION_TYPE, ObjectFunctions.OBJ_INTERACTION_GREY_TREASURE)
	sim.grey_chest_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.CHEST_FUNC_UPDATE & 0xFFFF)
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectSim.OBJSTATE_18)
	sim.wAutoMoveState = 1
	sim.chest_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.CHEST_FUNC_UPDATE & 0xFFFF, "still moving")
	sim.wAutoMoveState = 0
	sim.chest_update()
	for frame: int in 85:
		sim.chest_open()
	assert_eq(sim.wram1[ObjectSim.OBJ_FLAGS], 0, "86 frames opening")
	sim.chest_open()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.CHEST_FUNC_RET & 0xFFFF)
	assert_eq([sim.wram1[ObjectSim.OBJ_ID], sim.wram1[ObjectSim.OBJ_Y_POS]], [0x40, 0x80 - 24], "24 px above")


func test_a_chest_whose_treasure_was_taken_is_gone() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.wKeyAndTreasureFlags = ObjectFunctions.GREY_TREASURE << 1
	sim.red_chest_func()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0)


func test_a_treasure_takes_its_frameset_when_its_duration_runs_out() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x100, 0x80)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 2)
	sim.green_treasure_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR), 0)
	sim.green_treasure_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR), ObjectFunctions.FRAMESET_681BE + 10)
	assert_eq(sim.cur(ObjectSim.OBJ_ACTION), 0x81, "no actions")


func test_silky_walks_half_a_pixel_a_frame_and_winds_up_when_wario_is_ahead() -> void:
	var sim: LevelSim = _sim()
	sim.level.set_block(9, 16, 0x01)
	sim.level.set_block(9, 17, 0x01)
	_cur(sim, 0x110, 0x90)  # on the solid row 9's top
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 60)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 120
	sim.wWarioScreenYPos = 40  # not level with it
	sim.silky_init()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_FALL, ".Default")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x01)
	sim.silky_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x31)
	sim.wGlobalCounter = 0
	sim.silky_update()
	sim.wGlobalCounter = 1
	sim.silky_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_X_POS), 0x111, "half a pixel a frame")
	sim.wWarioScreenYPos = 104
	sim.silky_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2D, 0x23])
	for frame: int in 0x23:
		sim.silky_update()
	assert_eq(sim.cur(ObjectSim.OBJ_INTERACTION_TYPE), ObjectFunctions.OBJ_INTERACTION_SILKY, "then the string")


func test_silky_with_wario_behind_turns_round() -> void:
	var sim: LevelSim = _sim()
	_cur(sim, 0x110, 0x90)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 60)
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 100)
	sim.wWarioScreenXPos = 120
	sim.wWarioScreenYPos = 100
	sim.silky_init()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x31)
	sim.wWarioScreenXPos = 20
	sim.silky_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x13)
	sim.silky_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x43, 0x23])
