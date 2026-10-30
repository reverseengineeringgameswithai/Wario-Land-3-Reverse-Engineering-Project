extends TestCase
## Block handlers on a synthetic level (no ROM bytes): what a probe of each one returns and sets,
## for Wario (wBlockFuncWarioFlag) and for objects.

const BLOCK: int = 1


func _sim(handler: String) -> WarioSim:
	var rows: Array = []
	for row: int in LevelCollision.HEIGHT:
		var data := PackedByteArray()
		data.resize(LevelCollision.WIDTH)
		rows.append(data.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[BLOCK] = handler
	var sim := WarioSim.new()
	sim.tables = WarioTables.from_document({"walk_vel_table": {"steps": [1]},
			"jump_vel_tables": [{"id": 1, "steps": [1]}, {"id": 2, "steps": [1]}],
			"framesets": {"5f70": {"pairs": [[0, 2]]}, "5f7f": {"pairs": [[0, 2]]}}})
	sim.level = LevelCollision.from_document({"block_rows": rows, "rooms": [{"level_room_id": 0, "handlers": handlers}]})
	sim.level.set_block(5, 5, BLOCK)
	return sim


## ProcessBlock on the block at (row 5, column 5) with `points`, as Wario or as an object.
func _probe(sim: WarioSim, points: int, wario: bool) -> int:
	sim.wBlockFuncWarioFlag = 1 if wario else 0
	sim.hYPos = 5 * 16 + 4
	sim.hXPos = 5 * 16 + 8
	return sim.probe(points)


func test_slippery_blocks_are_solid_or_a_floor_and_slippery_under_wario_only() -> void:
	var sim: WarioSim = _sim("h06_4997")
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "solid")
	assert_eq(sim.wIsOnSlipperyGround, 1)
	sim.wIsOnSlipperyGround = 0
	_probe(sim, WarioRam.COLLISION_DOWN, false)
	assert_eq(sim.wIsOnSlipperyGround, 0, "not for objects")
	sim = _sim("h06_49ae")
	_probe(sim, WarioRam.COLLISION_UNK4, true)
	assert_eq(sim.wIsOnSlipperyGround, 0, "only under his feet")
	_probe(sim, WarioRam.COLLISION_DOWN, true)
	assert_eq(sim.wIsOnSlipperyGround, 1)


func test_cloud_platforms_follow_the_room_palette_cycle() -> void:
	var floors: Array = []
	for handler: String in ["h06_49c5", "h06_49d4"]:
		var sim: WarioSim = _sim(handler)
		var row: Array = []
		for index: int in 8:
			sim.wRoomPalCycleIndex = index
			row.append(1 if _probe(sim, WarioRam.COLLISION_DOWN, true) != 0 else 0)
		floors.append(row)
	assert_eq(floors, [[1, 1, 1, 1, 0, 0, 0, 1], [0, 0, 0, 1, 1, 1, 1, 1]])


func test_block_188ba_stops_objects_but_not_wario_and_a_fence_is_found_by_the_presence_probe() -> void:
	var sim: WarioSim = _sim("h06_48ba")
	assert_eq([_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, _probe(sim, WarioRam.COLLISION_DOWN, false) != 0], [false, true])
	sim = _sim("h06_4934")
	_probe(sim, WarioRam.COLLISION_DOWN, true)
	assert_eq(sim.wIsNearFence, 0)
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK7, true), 0, "free")
	assert_eq(sim.wIsNearFence, 1)


func test_a_water_spike_stings_wario_once_and_an_underwater_door_takes_up() -> void:
	var sim: WarioSim = _sim("h06_4402")
	_probe(sim, WarioRam.COLLISION_UNK7, true)
	assert_eq([sim.wWarioState, sim.wIsInWaterOrSand, sim.wIsIntangible], [WarioRam.WST_WATER_STUNG, 1, 1])
	sim.wInvincibleCounter = 0
	sim.wWarioStateCounter = 5
	_probe(sim, WarioRam.COLLISION_UNK7, true)
	assert_eq(sim.wWarioStateCounter, 5, "already stung: not again")
	sim = _sim("h06_46f9")
	_probe(sim, WarioRam.COLLISION_UNK7, true)
	assert_eq([sim.wWaterInteraction, sim.wRoomTransitionParam], [WarioRam.SUBMERSIBLE_WATER, 0])
	sim.wJoypadPressed = WarioRam.PAD_UP
	_probe(sim, WarioRam.COLLISION_UNK7, true)
	assert_eq(sim.wRoomTransitionParam & WarioRam.ROOMTRANSITION_MASK, WarioRam.ROOMTRANSITION_UNDERWATER_DOOR)



func test_a_solid_spike_stings_wario_and_stays_solid() -> void:
	var sim: WarioSim = _sim("h06_439c")
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, false) != 0, "solid to objects, no sting")
	assert_eq(sim.wWarioState, 0)
	sim.wDirection = WarioRam.DIRECTION_RIGHT
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "solid to Wario too")
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_STUNG, WarioRam.DIRECTION_LEFT], "stung, turned round")

func test_an_enemy_block_is_solid_except_to_a_thrown_object() -> void:
	var sim: WarioSim = _sim("h06_53fb")
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, false) != 0, "solid")
	sim.wBlockFuncSpecialCollision = WarioBlocks.COLLISION_THROWN_OBJ
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "a thrown object goes through")
	assert_eq(sim.level.block_at(5, 5), 0x78, "breaking it (off screen: no debris or coin)")
	assert_true(sim.unported.is_empty())


func test_down_on_a_pipe_takes_wario_through_it_and_into_the_next_room() -> void:
	var sim: WarioSim = _sim("h06_442a")
	sim.tables = WarioTables.from_document({"walk_vel_table": {"steps": [1]},
			"jump_vel_tables": [{"id": 1, "steps": [1]}, {"id": 2, "steps": [1]}],
			"framesets": {"5f70": {"pairs": [[0, 2]]}, "5f7f": {"pairs": [[0, 2]]}, "4cf6": {"pairs": [[0, 2]]},
			"4252": {"pairs": [[0, 2]]}}})
	sim.wWarioXPos = 0x01F3
	sim.wWarioYPos = 0x0100
	sim.wSubState = 3
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "solid")
	assert_eq(sim.wWarioState, WarioRam.WST_IDLING, "without Down, nothing")
	sim.wJoypadDown = WarioRam.PAD_DOWN
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "solid")
	assert_eq([sim.wWarioState, sim.wWarioXPos], [WarioRam.WST_PIPE_GOING_DOWN, 0x0208],
			"on the pipe's middle: $f0 + $18 carries")
	assert_eq(sim.wRoomTransitionParam, WarioRam.ROOMTRANSITION_PIPE | WarioRam.ROOMTRANSITIONF_RELOAD_OBJECTS
			| WarioRam.ROOMTRANSITIONF_DELAY)
	for i: int in 31:
		sim.update_state_pipe(true)
	assert_eq([sim.wWarioYPos, sim.wSubState, sim.wIsIntangible], [0x011F, 3, 1], "31 px down, intangible")
	sim.update_state_pipe(true)
	assert_eq([sim.wSubState, sim.wRoomTransitionParam & WarioRam.ROOMTRANSITIONF_DELAY], [5, 0],
			"at 32, the transition (FastFadeToWhite)")
	for i: int in 32:
		sim.update_state_pipe(true)
	assert_eq([sim.wWarioState, sim.wWarioXPos, sim.wIsIntangible], [WarioRam.WST_IDLING, 0x0200, 0],
			"out at 64: idling, 8 px back left")
	assert_true(sim.unported.is_empty(), "nothing unported: %s" % sim.unported)


func test_the_robo_mouse_breaks_a_cracked_block_or_passes_it() -> void:
	var sim: WarioSim = _sim("h06_4cb8")
	sim.wBlockFuncSpecialCollision = WarioRam.COLLISION_ROBO_MOUSE_FREE
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "free, unbroken")
	assert_eq(sim.level.block_at(5, 5), 1)
	sim.wBlockFuncSpecialCollision = WarioRam.COLLISION_ROBO_MOUSE_BREAK
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "free")
	assert_eq(sim.level.block_at(5, 5), 0x79, "broken (Func_19423)")
	assert_true(sim.unported.is_empty())


func test_a_small_gap_lets_objects_and_flat_wario_through_and_block_189f1_is_a_floor_to_wario() -> void:
	var sim: WarioSim = _sim("h06_49df")
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "solid to Wario")
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "free to objects")
	sim.wTransformation = WarioRam.TRANSFORMATION_FLAT_WARIO
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, true), 0, "free to Flat Wario")
	sim = _sim("h06_49f1")
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "a floor under Wario")
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK4, true), 0, "but not a wall")
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "free to objects")


func test_a_fire_block_sets_wario_on_fire_from_the_side_and_is_free_from_above() -> void:
	var sim: WarioSim = _sim("h06_48e0")
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, true), 0, "his ground probe: free")
	assert_eq(_probe(sim, WarioRam.COLLISION_DOWN, false), 0, "free to objects")
	assert_eq(sim.wTransformation, 0)
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK4, true), 0x06, "hCallFunc's restored bank")
	assert_eq([sim.wTransformation, sim.wTransformationProgress, sim.wWarioState, sim.wTransformationDuration],
			[WarioRam.TRANSFORMATION_HOT_WARIO, 1, WarioRam.WST_ON_FIRE, WarioRam.HOT_WARIO_DURATION])


func test_every_bonfire_block_breaks_only_under_a_fully_hot_wario() -> void:
	for handler: String in ["h06_544b", "h06_5453", "h06_545f"]:
		var sim: WarioSim = _sim(handler)
		assert_true(_probe(sim, WarioRam.COLLISION_UNK4, true) != 0, "solid")
		sim.wTransformation = WarioRam.TRANSFORMATION_HOT_WARIO
		sim.wTransformationProgress = 2
		assert_eq(_probe(sim, WarioRam.COLLISION_UNK4, true), 0, "broken")
		assert_eq(sim.level.block_at(5, 5) & 0x7F, WarioBlocks.BREAKABLE[handler][1], handler)


func test_a_light_source_starts_zombie_wario_recovering_and_is_free() -> void:
	var sim: WarioSim = _sim("h06_4821")
	sim.wTransformation = WarioRam.TRANSFORMATION_ZOMBIE_WARIO
	sim.wWarioState = WarioRam.WST_ZOMBIE_WALKING
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK7, true), 0, "free")
	assert_eq([sim.wWarioState, sim.wWarioStateCounter], [WarioRam.WST_ZOMBIE_RECOVERING, 0])
	assert_true(sim.unported.is_empty(), "nothing unported")


## A 2x2 multi-block at rows 5-6, columns 5-6, each passing the break on round it: right (1), down
## (4), left (2), up (3).
func _multi_block_sim() -> WarioSim:
	var sim: WarioSim = _sim("h06_4020")
	var handlers: PackedStringArray = sim.level.room_handlers[0]
	handlers[0x10] = "h06_4e2a"  # Func_18e2c, right
	handlers[0x11] = "h06_500f"  # Func_19011, down
	handlers[0x12] = "h06_4f7b"  # Func_18f7d, left
	handlers[0x13] = "h06_4ebe"  # Func_18ec0, up
	sim.level.room_handlers[0] = handlers
	sim.level.set_block(5, 5, 0x10)
	sim.level.set_block(5, 6, 0x11)
	sim.level.set_block(6, 6, 0x12)
	sim.level.set_block(6, 5, 0x13)
	return sim


func test_a_charge_breaks_a_multi_block_and_the_next_frame_breaks_the_rest_round_it() -> void:
	var sim: WarioSim = _multi_block_sim()
	sim.wBlockFuncBreakFlag = 1
	sim.wAttackCounter = 5
	sim.wPowerUpLevel = WarioRam.GARLIC
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK4, true), 0, "broken: free with the Garlic")
	assert_eq([sim.level.block_at(5, 5), sim.wMultiBlockParam, sim.multi_block_row, sim.multi_block_column, sim.wIsFloorTransition],
			[0x78, 1, 5, 5, 1], "passed on to the right")
	assert_eq(sim.level.block_at(5, 6), 0x11, "the rest waits for the next frame")
	sim.wBlockFuncWarioFlag = 0
	sim.process_multi_blocks()
	assert_eq([sim.level.block_at(5, 6), sim.level.block_at(6, 6), sim.level.block_at(6, 5)], [0x78, 0x78, 0x78],
			"right, down, left, then up to the broken block, which ends it")
	assert_eq([sim.wMultiBlockParam, sim.wIsFloorTransition], [0, 0])


func test_a_multi_block_is_free_while_a_direction_is_set_and_otherwise_solid_without_a_break() -> void:
	var sim: WarioSim = _multi_block_sim()
	assert_true(_probe(sim, WarioRam.COLLISION_UNK4, true) != 0, "no break flag: solid")
	sim.wMultiBlockParam = 2
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK4, true), 0, "a direction pending: free")
	assert_eq(sim.level.block_at(5, 5), 0x10, "and not broken")


func test_block_182dc_is_solid_to_objects_and_a_ladders_top_to_wario() -> void:
	var sim: WarioSim = _sim("h06_42dc")
	assert_true(_probe(sim, WarioRam.COLLISION_UNK4, false) != 0, "solid to an object from the side")
	assert_eq(sim.wLadderInteraction, 0)
	assert_eq(_probe(sim, WarioRam.COLLISION_UNK7, true), 0, "Wario's presence probe: the ladder underneath")
	assert_eq(sim.wLadderInteraction, WarioRam.LADDER_UNDERNEATH)
	assert_true(_probe(sim, WarioRam.COLLISION_DOWN, true) != 0, "otherwise a floor under him")


func test_a_probe_past_the_maps_edge_reads_on_in_the_rows_sram_page() -> void:
	var sim: WarioSim = _sim("h06_4020")
	for row: int in 8:
		var objects := PackedByteArray()
		objects.resize(80)
		sim.level.object_rows.append(objects)
	sim.level.object_rows[5][79] = 0x81
	assert_eq(sim.level.block_at(5, 0xFF), 0x81, "column $ff (x left of 0): the object map's last byte")
	assert_eq(sim.level.block_at(5, 0xB0), 0x00, "the object map from $b0")
	assert_eq(sim.level.block_at(5, 0xA0), -1, "$a0-$af: never written, not known")
	assert_eq(sim.level.block_at(9, 0xFF), -1, "past the decoded object map")
	sim.level.set_block(5, 0xB1, 0x22)
	assert_eq(sim.level.object_rows[5][1], 0x22)
	var gaps: Array = []
	for row: int in LevelCollision.HEIGHT:
		gaps.append("00".repeat(LevelCollision.GAP_WIDTH))
	gaps[5] = "77" + "00".repeat(LevelCollision.GAP_WIDTH - 2) + "0d"
	sim.level.set_gap_rows(gaps)
	assert_eq([sim.level.block_at(5, 0xA0), sim.level.block_at(5, 0xAF), sim.level.block_at(6, 0xA0)], [0x77, 0x0D, 0],
			"as a trace recorded them")
	sim.level.set_block(5, 0xA1, 0x05)
	assert_eq(sim.level.copy().block_at(5, 0xA1), 0x05, "written and copied")
