extends TestCase
## The level's devices (DeviceFunctions) on invented data (no ROM bytes): zip lines, Wario
## hanging from one, torches, barrels, a clear gate, and the variable cart.


## Free blocks, with a solid block at (row, column) for each of `walls`.
func _sim(walls: Array = []) -> LevelSim:
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
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	sim.level.room_handlers[0] = handlers
	for wall: Array in walls:
		sim.level.set_block(wall[0], wall[1], 1)
	sim.load_object_data({"framesets": {"by_pointer": {}}, "movement_data": {"bytes": PackedByteArray([0]).hex_encode()}})
	return sim


## wCurObj as zip line `id` at (x, y), set up by ZipLineFunc.
func _zip_line(sim: LevelSim, id: int, x: int, y: int) -> void:
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_ID, id)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, y)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, x)
	sim.zip_line_func()


func test_a_zip_line_waits_for_wario_below_it_then_carries_him_up_the_slope() -> void:
	var sim: LevelSim = _sim()
	_zip_line(sim, 0x25, 0x100, 0x80)  # line 2: right and up, 1 px a frame
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 60)
	sim.wWarioScreenYPos = 60 + 0x20
	sim.zip_line_wait()
	assert_eq(sim.cur(ObjectSim.OBJ_ACTION), 0x81, "Wario too far below: no grab")
	sim.wWarioScreenYPos = 60 + 0x12
	sim.zip_line_wait()
	assert_eq(sim.cur(ObjectSim.OBJ_ACTION), 0, "16-23 px below: it can be grabbed")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0E)  # as OBJACTION_06 leaves it
	sim.zip_line_wait()
	assert_eq([sim.wWarioYPos, sim.wWarioXPos, sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[0x80 + 0x1B, 0x104, DeviceFunctions.ZIP_LINE_FUNC_RIDDEN & 0xFFFF], "hanging below it")
	sim.wTransformation = WarioRam.TRANSFORMATION_RAIL
	sim.zip_line_ridden()
	assert_eq([sim.cur_x(), sim.cur_y(), sim.wWarioXPos, sim.wWarioYPos], [0x101, 0x7F, 0x105, 0x80 + 0x1A],
			"along and up, carrying him")
	sim.wTransformation = 0
	sim.zip_line_ridden()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [2, 0x0A], "let go: it waits")
	for frame: int in 10:
		sim.zip_line_let_go()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE)],
			[DeviceFunctions.ZIP_LINE_FUNC_WAIT & 0xFFFF, 0], "then for him again, where it stopped")


func test_short_lines_turn_at_a_wall_and_long_ones_stop_for_good_dropping_wario() -> void:
	var sim: LevelSim = _sim([[7, 0x11]])  # a wall 16 px up and 7 ahead of x $10a
	_zip_line(sim, 0x24, 0x10A, 0x80)  # line 1: level
	sim.set_cur(ObjectSim.OBJ_VAR_1, 2)  # moving, not ridden
	sim.zip_line_let_go()
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 5)
	sim._zip_line_move()
	assert_eq([sim.hdir(), sim.cur_x()], [false, 0x10A], "turned, not moved")
	sim = _sim([[7, 0x11]])
	_zip_line(sim, 0x28, 0x10A, 0x80)  # line 5: right, 3 px a frame
	sim.set_cur(ObjectSim.OBJ_VAR_1, 1)
	sim.wAutoMoveState = 1
	sim.wTransformation = WarioRam.TRANSFORMATION_RAIL
	sim.zip_line_ridden()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.wAutoMoveState, sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[3, 0, DeviceFunctions.ZIP_LINE_FUNC_STOPPED & 0xFFFF], "the end: Wario released")


func test_hanging_wario_drops_rolling_when_the_line_stops_and_b_lets_go() -> void:
	var sim: LevelSim = _sim()
	var framesets: Dictionary = {}
	for key: String in ["7f:6ec4", "7f:6eb4", "66e6", "66f7", "4252", "425f"]:
		framesets[key] = {"pairs": [[0, 2]]}
	sim.tables = WarioTables.from_document({"walk_vel_table": {"steps": [1]},
			"jump_vel_tables": [{"id": 1, "steps": [1]}, {"id": 2, "steps": [1]}], "framesets": framesets})
	sim.wObjDirection = WarioRam.DIRECTION_LEFT
	sim.wTransformation = WarioRam.TRANSFORMATION_RAIL
	sim.set_state_hanging_rail()
	assert_eq([sim.wWarioState, sim.wAutoMoveState, sim.wDirection], [WarioRam.WST_HANGING_RAIL, 1, WarioRam.DIRECTION_LEFT])
	sim.wAutoMoveState = 0
	sim.update_state_hanging_rail()
	assert_eq([sim.wWarioState, sim.wTransformation], [WarioRam.WST_ROLLING_AIRBORNE, 0], "the line stopped: a rolling drop")
	sim.wTransformation = WarioRam.TRANSFORMATION_RAIL
	sim.set_state_hanging_rail()
	sim.wJoypadPressed = WarioRam.PAD_B
	sim.update_state_hanging_rail()
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wInvincibleCounter], [WarioRam.WST_IDLING, 0, 0], "B: let go, not invincible")


func test_a_pounded_pillar_sinks_a_step_and_raises_the_pillars_three_columns_either_side() -> void:
	var sim: LevelSim = _sim()
	for slot: int in 3:
		var base: int = slot * ObjectSim.OBJ_STRUCT_LENGTH
		sim.wram1[base + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
		sim.wram1[base + ObjectSim.OBJ_ID] = DeviceFunctions.PILLAR_PLATFORM
		sim.wram1[base + ObjectSim.OBJ_UNK_01] = [7, 10, 13][slot]
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_STEPPED)
	sim.set_cur(ObjectSim.OBJ_UNK_01, 10)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x80)
	sim.pillar_platform_1_func()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0A)
	sim.pillar_platform_idle()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[0, DeviceFunctions.PILLAR_PLATFORM_FUNC_SINK & 0xFFFF], "height 1 to 0")
	var states: Array = []
	for slot: int in 3:
		states.append(sim.wram1[slot * ObjectSim.OBJ_STRUCT_LENGTH + ObjectSim.OBJ_STATE])
	assert_eq(states, [DeviceFunctions.OBJSTATE_PILLAR_RISE, 0, DeviceFunctions.OBJSTATE_PILLAR_RISE], "its neighbours rise")
	for frame: int in 9:
		sim.pillar_platform_sink()
	assert_eq([sim.cur_y(), sim.cur(ObjectSim.OBJ_STATE)], [0x80 + 16, 0], "16 px down in 8 frames, then idle")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0A)
	sim.pillar_platform_idle()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0, "already at the bottom")


func test_three_lit_torches_clear_the_flame_block_for_good_and_an_unlit_one_goes_out_after_512_frames() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.flame_block_torch_func()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0E)  # touched by Hot Wario
	sim.flame_block_torch_update()
	assert_eq([sim.wram1[ObjectSim.W_NUM_LIT_TORCHES], sim.cur(ObjectSim.OBJ_INTERACTION_TYPE),
			sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)], [1, DeviceFunctions.OBJ_INTERACTION_FIRE,
			DeviceFunctions.FLAME_BLOCK_TORCH_UPDATE_LIT & 0xFFFF], "lit: burning, counted")
	sim.set_cur(ObjectSim.OBJ_UNK_02, 0xA0 + 3)
	for frame: int in 511:
		sim.flame_block_torch_lit()
	assert_true(sim.cur(ObjectSim.OBJ_FLAGS) != 0, "511 frames: still lit")
	sim.flame_block_torch_lit()
	assert_eq([sim.cur(ObjectSim.OBJ_FLAGS), sim.wram1[ObjectSim.W_NUM_LIT_TORCHES]], [0, 0], "512: out, despawned")

	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.flame_block_func()
	sim.wram1[ObjectSim.W_NUM_LIT_TORCHES] = 2
	sim.flame_block_update()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), DeviceFunctions.FLAME_BLOCK_FUNC_UPDATE & 0xFFFF, "two lit: still there")
	sim.wram1[ObjectSim.W_NUM_LIT_TORCHES] = 3
	sim.flame_block_update()
	assert_eq(sim.wram1[ObjectSim.W_FLAME_BLOCK_CLEARED], 3)
	for frame: int in 159:
		sim.flame_block_destroy()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "burnt away")
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.flame_block_func()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "cleared for good: not set up again")


func test_a_barrel_stands_until_hit_and_breaks_in_14_frames() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.set_cur(ObjectSim.OBJ_UNK_02, 0xA0 + 3)
	sim.barrel_2_func()
	sim.barrel_2_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), ObjectStates.OBJSTATE_WALK, "standing")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x0B)
	sim.barrel_2_update()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [0x2F, 13], "breaking")
	for frame: int in 13:
		sim.barrel_2_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "gone")


func test_a_clear_gate_stands_and_is_raised_32_px_once_the_minigame_is_cleared() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_INVISIBLE)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x90)
	sim.clear_gate_2_func()
	assert_eq([sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR), sim.cur_y(), sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE],
			[0x58AB, 0x90, 0])
	sim.wIsMinigameCleared = 1
	sim.clear_gate_1_func()
	assert_eq([sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR), sim.cur_y()], [0x58A8, 0x90 - 32])


func test_the_variable_cart_rolls_only_with_the_truck_wheel() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_ID, DeviceFunctions.CART_RIGHT)
	sim.cart_variable_func()
	assert_eq(sim.unported.size(), 1, "an untraced treasure byte is unknown")
	sim.unported.clear()
	sim.wTreasuresCollected7 = 0xDF  # every treasure in the byte but TRUCK_WHEEL ($3d: bit 5)
	sim.cart_variable_func()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[DeviceFunctions.CART_STOPPED_FUNC & 0xFFFF, DeviceFunctions.FRAMESET_691A7], "no wheel: it stays")
	sim.wTreasuresCollected7 = 0x20
	sim.cart_variable_func()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[DeviceFunctions.CART_VARIABLE_WAITING & 0xFFFF, DeviceFunctions.FRAMESET_691BF], "the wheel: waiting")
	sim.set_cur(ObjectSim.OBJ_FLAGS, sim.cur(ObjectSim.OBJ_FLAGS) | ObjectSim.OBJFLAG_STEPPED)
	sim.cart_variable_waiting()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[DeviceFunctions.CART_VARIABLE_MOVING & 0xFFFF, DeviceFunctions.FRAMESET_691AA], "stood on: rolling right")
	assert_eq(sim.unported.size(), 0)
