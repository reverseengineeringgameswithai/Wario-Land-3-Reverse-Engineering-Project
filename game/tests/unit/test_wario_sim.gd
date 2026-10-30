extends TestCase
## The ported Wario state machine on invented tables and a synthetic level, without ROM data.
## These pin the ported rules (velocity indices, caps, probes, animation timing); agreement
## with the original game is checked separately against oracle traces (make wario-parity).

const FREE: int = 0
const SOLID: int = 1
const FLOOR: int = 2
const LADDER: int = 3
const FLOOR_ROW: int = 10  # the ground: Wario stands at y = 160


## Invented tables: walk steps 1, 2, 3, 4 by quarter; jumps rise 12 frames by 3, hang 12, fall by 2.
func _tables() -> WarioTables:
	var walk: Array = []
	for i: int in 0x1C:
		walk.append(1 + i / 8)
	var normal: Array = []
	var knock: Array = []
	for i: int in 0x28:
		normal.append(-3 if i < 12 else (0 if i < 24 else 2))
		knock.append(-1 if i < 20 else 1)
	var tables := WarioTables.from_document({
		"walk_vel_table": {"steps": walk},
		"jump_vel_tables": [{"id": 1, "steps": knock}, {"id": 2, "steps": normal}, {"id": 3, "steps": normal},
				{"id": 4, "steps": normal}, {"id": 5, "steps": normal}],
		"framesets": {
			"4252": {"pairs": [[0, 9]]}, "425f": {"pairs": [[0, 9]]},
			"49b4": {"pairs": [[0, 1], [1, 1]]}, "49c5": {"pairs": [[0, 1], [1, 1]]},
			"4cbe": {"pairs": [[0, 1]]}, "4cc5": {"pairs": [[0, 1]]},
			"5f94": {"pairs": [[0, 3]]}, "5f97": {"pairs": [[0, 3]]},
			"5f9a": {"pairs": [[0, 0]]}, "5fa1": {"pairs": [[0, 0]]},
			"51e4": {"pairs": [[0, 1], [1, 1]]}, "51fd": {"pairs": [[0, 1], [1, 1]]},
			"5216": {"pairs": [[2, 4]]}, "5219": {"pairs": [[10, 1]]},
			"4a26": {"pairs": [[0, 5]]}, "4a2f": {"pairs": [[0, 5]]},
			"4a38": {"pairs": [[0, 4]]}, "4a3b": {"pairs": [[0, 4]]},
			"58d6": {"pairs": [[0, 3]]}, "5900": {"pairs": [[0, 9]]}, "58fd": {"pairs": [[0, 9]]},
			"5f7f": {"pairs": [[0, 2]]},
			"7414": {"pairs": [[0, 2]]}, "741f": {"pairs": [[0, 4]]}, "73fe": {"pairs": [[0, 4]]},
			"742a": {"pairs": [[0, 4]]}, "7409": {"pairs": [[0, 3]]}, "7ce2": {"pairs": [[0, 5]]},
			"6b38": {"pairs": [[0, 3]]}, "6b49": {"pairs": [[0, 3]]}, "6b14": {"pairs": [[0, 4]]},
			"6b1d": {"pairs": [[0, 4]]}, "6b26": {"pairs": [[0, 4]]}, "6b2f": {"pairs": [[0, 4]]},
			"6e47": {"pairs": [[0, 6]]}, "6e72": {"pairs": [[0, 6]]},
			"4a6c": {"pairs": [[0, 4]]}, "4a71": {"pairs": [[0, 4]]},
			"5f70": {"pairs": [[0, 2]]},
			"781c": {"pairs": [[0, 9]]}, "781f": {"pairs": [[0, 9]]}, "7822": {"pairs": [[0, 2]]},
			"782b": {"pairs": [[0, 2]]}, "78f3": {"pairs": [[0, 2]]}, "78ea": {"pairs": [[0, 2]]},
			"7834": {"pairs": [[0, 2]]}, "7839": {"pairs": [[0, 2]]}, "783e": {"pairs": [[0, 9]]},
			"7841": {"pairs": [[0, 9]]}, "7872": {"pairs": [[0, 9]]}, "7887": {"pairs": [[0, 9]]},
			"7844": {"pairs": [[0, 3]]}, "785b": {"pairs": [[0, 3]]}, "789c": {"pairs": [[0, 5]]},
			"78c3": {"pairs": [[0, 5]]}, "78fc": {"pairs": [[0, 2]]}, "7905": {"pairs": [[0, 2]]},
			"7f:5d8b": {"pairs": [[0, 2]]}, "7f:5d82": {"pairs": [[0, 2]]}, "7f:5d97": {"pairs": [[0, 4]]},
			"7f:5d94": {"pairs": [[0, 4]]}, "7f:5da7": {"pairs": [[0, 3]]}, "7f:5d9a": {"pairs": [[0, 3]]},
			"71bd": {"pairs": [[0, 9]]}, "715f": {"pairs": [[0, 2]]}, "718b": {"pairs": [[0, 9]]},
			"7175": {"pairs": [[0, 2]]}, "7190": {"pairs": [[0, 9]]}, "71b8": {"pairs": [[0, 2]]},
			"7186": {"pairs": [[0, 2]]}, "7193": {"pairs": [[0, 3]]}, "716c": {"pairs": [[0, 9]]},
			"7f:48b6": {"pairs": [[0, 2]]}, "7f:48b9": {"pairs": [[0, 2]]}, "7f:4870": {"pairs": [[0, 2]]}, "7f:4879": {"pairs": [[0, 2]]},
			"7f:489d": {"pairs": [[0, 2]]}, "7f:4894": {"pairs": [[0, 2]]}, "7f:48a6": {"pairs": [[0, 2]]}, "7f:48ab": {"pairs": [[0, 2]]},
			"7f:48b0": {"pairs": [[0, 2]]}, "7f:48b3": {"pairs": [[0, 2]]}, "7f:4948": {"pairs": [[0, 2]]}, "7f:4953": {"pairs": [[0, 2]]},
			"7f:48bc": {"pairs": [[0, 2]]}, "7f:48d5": {"pairs": [[0, 2]]}, "7f:4928": {"pairs": [[0, 2]]}, "7f:492b": {"pairs": [[0, 2]]},
			"7f:48ee": {"pairs": [[0, 2]]}, "7f:490b": {"pairs": [[0, 2]]}, "7f:492e": {"pairs": [[0, 2]]}, "7f:493b": {"pairs": [[0, 2]]},
			"7f:4882": {"pairs": [[0, 2]]}, "7f:488b": {"pairs": [[0, 2]]},
		},
		"flat_fall_tables": {"down": {"steps": FLAT_DOWN}, "across": {"steps": FLAT_ACROSS}},
	})
	for key: String in ["4c6c", "4c5f", "4c75", "4c82", "4c85", "4cbf", "4cb2"]:
		tables.framesets[WarioRam.WARIO_OAM_2 | key.hex_to_int()] = [[0, 2]]
	for key: String in ["5f8e", "5f91", "604e", "6055", "5ff2", "6009", "5fb8", "5fc5", "63ec", "640c", "63f5",
			"6415", "4a20", "4a23", "49fe", "4a0f", "5fa8", "5fab", "642c", "642f", "6432", "6435", "6438", "6441",
			"63fe", "641e", "6403", "6423", "5fae", "5fb3", "4ccc", "4ce1"]:
		tables.framesets[key.hex_to_int()] = [[0, 3]]
	for key: String in ["4f9f", "4f6e", "4fd0", "4fd7"]:
		tables.framesets[WarioRam.WARIO_OAM_2 | key.hex_to_int()] = [[0, 8]]
	return tables


## Invented Flat Wario fall steps: 2 px down and 1 px across every frame of the swing.
const FLAT_DOWN: Array = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
const FLAT_ACROSS: Array = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]


## A level of free blocks with a solid floor row, and `extra` cells as [row, column, block].
func _level(extra: Array = []) -> LevelCollision:
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var block: int = SOLID if y == FLOOR_ROW else FREE
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		row.fill(block)
		rows.append(row.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[SOLID] = "h06_4032"
	handlers[FLOOR] = "h06_4208"
	handlers[LADDER] = "h06_42c3"
	var level := LevelCollision.from_document({"block_rows": rows, "rooms": [{"level_room_id": 0, "handlers": handlers}]})
	for cell: Array in extra:
		level.set_block(cell[0], cell[1], cell[2])
	return level


func _sim(x: int, direction: int, extra: Array = []) -> WarioSim:
	var sim := WarioSim.new()
	sim.tables = _tables()
	sim.level = _level(extra)
	sim.wWarioXPos = x
	sim.wWarioYPos = FLOOR_ROW * 16
	sim.wDirection = direction
	sim.wWarioState = WarioRam.WST_IDLING
	sim.wCollisionBoxTop = WarioRam.byte(-27)
	sim.wCollisionBoxBottom = WarioRam.byte(-1)
	sim.wCollisionBoxLeft = WarioRam.byte(-9)
	sim.wCollisionBoxRight = 9
	sim.wWarioFramesetPtr = WarioRam.FRAMESET_IDLE_RIGHT
	return sim


## One frame with `down` held; `pressed` is what became held this frame.
func _frame(sim: WarioSim, down: int, previous: int) -> void:
	sim.wJoypadDown = down
	sim.wJoypadPressed = down & ~previous
	sim.update()


func test_block_pointer_drops_the_high_nibble_of_each_coordinate() -> void:
	var sim := _sim(0, 1)
	sim.hYPos = 0x1A57
	sim.hXPos = 0x2C3F
	sim.get_block_ptr()
	assert_eq([sim.block_row, sim.block_column], [0xA5, 0xC3])


func test_idling_on_the_floor_keeps_y_and_counts_idle_frames() -> void:
	var sim := _sim(40, 1)
	for i: int in 5:
		_frame(sim, 0, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_IDLING, "state")
	assert_eq(sim.wWarioYPos, 160, "y")
	assert_eq(sim.wWarioStateCounter, 5, "idle counter")
	assert_true(sim.unported.is_empty(), "nothing unported")


func test_walking_steps_through_the_table_and_cycles_indices_12_to_15() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_RIGHT, 0)  # idle -> walking, no step yet
	assert_eq(sim.wWarioState, WarioRam.WST_WALKING, "walking")
	var expected_x: int = 40
	var index: int = 0
	for frame: int in 30:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		expected_x += 1 + index / 8
		index += 1
		if index >= 0x10:
			index = 0x0C  # HandleInput_Walking caps the index at $10 back to $0c
		assert_eq(sim.wWarioXPos, expected_x, "x after walking frame %d" % frame)
		assert_eq(sim.wWalkVelIndex, index, "index after walking frame %d" % frame)
	assert_eq(sim.wWarioYPos, 160, "y")


func test_a_wall_stops_the_walk_where_the_front_corner_reaches_it() -> void:
	var sim := _sim(40, 1, [[8, 6, SOLID], [9, 6, SOLID]])  # a wall at x 96-111
	var previous: int = 0
	for frame: int in 60:
		_frame(sim, WarioRam.PAD_RIGHT, previous)
		previous = WarioRam.PAD_RIGHT
	# The front corner is x + 8; walking stops at the first x where it would enter the wall.
	assert_eq(sim.wWarioXPos, 88, "x at the wall")
	assert_eq(sim.wWarioState, WarioRam.WST_WALKING, "still walking")


func test_turning_lasts_until_its_animation_ends() -> void:
	var sim := _sim(40, WarioRam.DIRECTION_LEFT)
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_TURNING, WarioRam.DIRECTION_RIGHT], "turning")
	assert_eq(sim.wWarioFramesetPtr, WarioRam.FRAMESET_TURN_RIGHT, "frameset")
	_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioState, WarioRam.WST_TURNING, "still turning while the frame's duration lasts")
	_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioState, WarioRam.WST_WALKING, "walking once the animation ends")
	assert_eq(sim.wWalkVelIndex, 0, "walk index reset")


func test_a_held_jump_rises_hangs_falls_and_lands_hard_at_full_speed() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wJumpingUpwards], [WarioRam.WST_AIRBORNE, 2, 1], "jump starts")
	for frame: int in 12:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq(sim.wWarioYPos, 160 - 12 * 3, "top of the rise")
	for frame: int in 12:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq([sim.wWarioYPos, sim.wJumpVelIndex], [124, WarioRam.FALLING_JUMP_VEL_INDEX], "hanging ends")
	for frame: int in 17:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wJumpVelIndex], [WarioRam.WST_AIRBORNE, 158,
			WarioRam.MAX_JUMP_VEL_INDEX], "one frame above the floor at the capped index")
	_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	# At MAX_JUMP_VEL_INDEX with no direction held: DoHardLand, the landing state.
	assert_eq([sim.wWarioState, sim.wWarioYPos], [WarioRam.WST_LANDING, 160], "landed hard")
	assert_eq([sim.wJumpVelIndex, sim.wJumpVelTable, sim.wWalkVelIndex], [0, 0, 0], "jump cleared")
	_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq(sim.wWarioState, WarioRam.WST_IDLING, "idle when the landing animation ends")


func test_releasing_a_ends_the_rise_unless_the_jump_is_full() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_A, 0)
	_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	_frame(sim, 0, WarioRam.PAD_A)
	# Released: the index jumps to FALLING_JUMP_VEL_INDEX and this frame already falls 2 px.
	assert_eq([sim.wWarioYPos, sim.wJumpVelIndex, sim.wJumpingUpwards], [159, 0x19, 0], "released")
	_frame(sim, 0, 0)
	# Below MAX_JUMP_VEL_INDEX the landing is soft: straight back to idling, snapped onto the floor.
	assert_eq([sim.wWarioState, sim.wWarioYPos], [WarioRam.WST_IDLING, 160], "landed softly")
	var full := _sim(40, 1)
	_frame(full, WarioRam.PAD_A, 0)
	full.wDoFullJump = 1
	_frame(full, 0, WarioRam.PAD_A)
	assert_eq([full.wWarioYPos, full.wJumpVelIndex], [157, 1], "a full jump keeps rising")


func test_a_ceiling_ends_the_rise() -> void:
	var sim := _sim(40, 1, [[7, 2, SOLID]])  # the block above Wario's head: y 112-127
	_frame(sim, WarioRam.PAD_A, 0)
	var frames: int = 0
	while sim.wJumpVelIndex < WarioRam.FALLING_JUMP_VEL_INDEX and frames < 20:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
		frames += 1
	# The centre probe 2 px above the box (y - 29) meets the block at y 127, so the rise stops at 154.
	assert_eq([sim.wWarioYPos, sim.wJumpingUpwards], [154, 1], "fall starts below the ceiling")


func test_a_floor_block_is_a_one_way_platform() -> void:
	var sim := _sim(40, 1)
	sim.wBlockFuncWarioFlag = 1
	sim.hYPos = 0x0083
	for points: int in [WarioRam.COLLISION_UNK3, WarioRam.COLLISION_UNK4, WarioRam.COLLISION_UNK5, WarioRam.COLLISION_UNK7]:
		sim.wCollisionPoints = points
		assert_eq(sim.block_floor(), 0, "free from below and the sides (points %d)" % points)
	sim.wCollisionPoints = WarioRam.COLLISION_UNK1
	assert_eq(sim.block_floor(), 1, "landing near the top")
	sim.hYPos = 0x0088
	assert_eq(sim.block_floor(), 0, "landing too deep")
	sim.wCollisionPoints = WarioRam.COLLISION_DOWN
	assert_eq(sim.block_floor(), 1, "standing")
	assert_eq(sim.hYPos, 0x0080, "standing snaps to the block top")


func test_unported_routines_are_named_not_guessed() -> void:
	var other := _sim(40, 1)
	other.wWarioState = 0xFE  # past the state table
	other.update()
	assert_eq(other.unported, PackedStringArray(["UpdateWarioStates state $fe"]))


func test_invincibility_counts_every_fourth_frame_then_every_second() -> void:
	var sim := _sim(40, 1)
	sim.wInvincibleCounter = 0x10
	var steps: Array = []
	for counter: int in range(1, 9):
		sim.wGlobalCounter = counter
		sim.handle_invincibility()
		steps.append(sim.wInvincibleCounter)
	assert_eq(steps, [0x10, 0x10, 0x10, 0x11, 0x11, 0x11, 0x11, 0x12])
	sim.wInvincibleCounter = 0x27
	sim.wGlobalCounter = 2
	sim.handle_invincibility()
	assert_eq(sim.wInvincibleCounter, 0, "ends at $28")


func test_a_charge_winds_up_then_runs_and_ends_in_idling() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_B, 0)
	assert_eq([sim.wWarioState, sim.wAttackCounter], [WarioRam.WST_ATTACKING, WarioRam.MAX_ATTACK_COUNTER], "charge")
	for frame: int in 6:
		_frame(sim, 0, WarioRam.PAD_B)
	assert_eq([sim.wWarioXPos, sim.wAttackCounter], [40, WarioRam.CHARGE_ATTACK_COUNTER - 1], "wind-up: no movement")
	for frame: int in 41:
		_frame(sim, 0, 0)
	# Walk steps 1 (indices 0-7), 2 (8-15), then 3 while the index cycles $10-$13: 8 + 16 + 25 * 3.
	assert_eq([sim.wWarioXPos, sim.wWarioState], [40 + 8 + 16 + 25 * 3, WarioRam.WST_ATTACKING], "running")
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioXPos, sim.wWarioState, sim.wAttackCounter], [40 + 102, WarioRam.WST_IDLING, 0], "ended")


func test_a_charge_into_a_wall_bumps_back_and_turns_around() -> void:
	var sim := _sim(40, 1, [[8, 6, SOLID], [9, 6, SOLID]])  # the wall at x 96-111
	_frame(sim, WarioRam.PAD_B, 0)
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_ATTACKING and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	# The front corner is x + 8: the charge stops at x = 88, and the bump moves Wario back 2.
	assert_eq([sim.wWarioState, sim.wWarioXPos, sim.wDirection], [WarioRam.WST_BUMPING, 86, WarioRam.DIRECTION_LEFT])
	assert_eq([sim.wJumpVelTable, sim.wJumpVelIndex], [WarioRam.JUMP_VEL_KNOCK_BACK, 10], "a hop from index 10")
	assert_eq(sim.wWarioFramesetPtr, WarioRam.FRAMESET_15219, "bumping facing left")
	_frame(sim, 0, 0)
	# Knocked back 1 px a frame, rising by JumpVelTable_Normal[10] (invented: -3).
	assert_eq([sim.wWarioXPos, sim.wWarioYPos, sim.wJumpVelIndex], [85, 157, 11], "knocked back")


func test_a_during_a_charge_jumps_into_an_airborne_attack() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_B, 0)
	_frame(sim, WarioRam.PAD_A, WarioRam.PAD_B)
	assert_eq([sim.wWarioState, sim.wJumpVelIndex, sim.wJumpingUpwards, sim.wJumpVelTable],
			[WarioRam.WST_ATTACKING_AIRBORNE, 0, 1, WarioRam.JUMP_VEL_NORMAL])
	assert_eq(sim.wWarioFramesetPtr, WarioRam.FRAMESET_15219, "attacking airborne facing right")


func test_down_crouches_and_releasing_it_stands_up_when_there_is_room() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_DOWN, 0)
	assert_eq([sim.wWarioState, sim.wIsCrouching, sim.wCollisionBoxTop], [WarioRam.WST_CROUCHING, 1, WarioRam.byte(-15)])
	_frame(sim, 0, WarioRam.PAD_DOWN)
	assert_eq([sim.wWarioState, sim.wCollisionBoxTop], [WarioRam.WST_IDLING, WarioRam.byte(-27)], "stood up")
	var low := _sim(40, 1, [[8, 2, SOLID]])  # a block 17-32 px above the floor at Wario's column
	_frame(low, WarioRam.PAD_DOWN, 0)
	_frame(low, 0, WarioRam.PAD_DOWN)
	assert_eq(low.wWarioState, WarioRam.WST_CROUCHING, "no room to stand")


func test_crouch_walking_cycles_the_walk_index_through_0_to_3() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_DOWN, 0)
	_frame(sim, WarioRam.PAD_DOWN | WarioRam.PAD_RIGHT, WarioRam.PAD_DOWN)
	assert_eq(sim.wWarioState, WarioRam.WST_CROUCH_WALKING, "crouch walking")
	var indices: Array = []
	for frame: int in 6:
		_frame(sim, WarioRam.PAD_DOWN | WarioRam.PAD_RIGHT, WarioRam.PAD_DOWN | WarioRam.PAD_RIGHT)
		indices.append(sim.wWalkVelIndex)
	assert_eq(indices, [1, 2, 3, 0, 1, 2])
	assert_eq(sim.wWarioXPos, 46, "invented steps of 1 px")


func test_a_crouch_slide_runs_2_then_1_px_and_ends_standing() -> void:
	var sim := _sim(40, 1)
	_frame(sim, WarioRam.PAD_B, 0)
	_frame(sim, WarioRam.PAD_DOWN, WarioRam.PAD_B)
	assert_eq(sim.wWarioState, WarioRam.WST_CROUCH_SLIDING, "Down during a charge")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_CROUCH_SLIDING and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	# 19 frames of 2 px, 16 of 1 px, then 4 frames moving only on odd wGlobalCounter (held at 0 here).
	assert_eq([sim.wWarioXPos, sim.wWarioState, frames], [40 + 38 + 16, WarioRam.WST_IDLING, 40])


func test_up_on_a_ladder_climbs_one_pixel_a_frame_on_its_column() -> void:
	var sim := _sim(37, 1, [[7, 2, LADDER], [8, 2, LADDER], [9, 2, LADDER]])  # a ladder over x 32-47
	_frame(sim, WarioRam.PAD_UP, 0)
	assert_eq([sim.wWarioState, sim.wWarioXPos], [WarioRam.WST_LADDER_CLIMBING, 40], "grabbed, centred on x = 40")
	for frame: int in 5:
		_frame(sim, WarioRam.PAD_UP, WarioRam.PAD_UP)
	assert_eq(sim.wWarioYPos, 155, "1 px a frame")
	_frame(sim, 0, WarioRam.PAD_UP)
	assert_eq(sim.wWarioState, WarioRam.WST_LADDER_IDLING, "nothing held: idling on the ladder")


func test_stung_on_the_ground_slides_back_then_recovers_invincible() -> void:
	var sim := _sim(40, 1)
	sim.wWarioState = WarioRam.WST_STUNG
	sim.wWarioFramesetPtr = 0x5F7F
	sim.wJumpVelTable = 0
	sim.wJumpVelIndex = 30
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_STUNG and frames < 20:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([frames, sim.wWarioXPos, sim.wWarioState], [9, 49, WarioRam.WST_STUNG_RECOVERY], "1 px a frame until index $27")
	for frame: int in 0x14:
		_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wDirection, sim.wInvincibleCounter], [WarioRam.WST_IDLING, WarioRam.DIRECTION_LEFT, 0x10])


func test_a_ball_of_string_rolls_by_itself_and_turns_at_a_wall() -> void:
	var sim := _sim(40, WarioRam.DIRECTION_RIGHT, [[FLOOR_ROW - 1, 5, SOLID]])  # a wall from x 80
	sim.wTransformation = WarioRam.TRANSFORMATION_BALL_O_STRING_WARIO
	sim.set_state_ball_o_string()
	assert_eq([sim.wCollisionBoxTop, sim.wWarioFramesetPtr], [WarioRam.byte(-24), WarioRam.FRAMESET_BALL_O_STRING_RIGHT])
	var frames: int = 0
	while sim.wDirection == WarioRam.DIRECTION_RIGHT and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioStateCounter, sim.wWarioFramesetPtr],
			[WarioRam.WST_BALL_O_STRING, 1, WarioRam.FRAMESET_BALL_O_STRING_LEFT], "no input needed")
	assert_true(sim.wWarioXPos < 80, "turned at the wall (without being pushed back)")


func test_the_fifth_turn_knocks_the_string_loose_and_wario_recovers_dizzy() -> void:
	var sim := _sim(40, WarioRam.DIRECTION_RIGHT, [[FLOOR_ROW - 1, 5, SOLID]])
	sim.wTransformation = WarioRam.TRANSFORMATION_BALL_O_STRING_WARIO
	sim.set_state_ball_o_string()
	sim.wWarioStateCounter = 4
	var states: Array = []
	for frame: int in 120:
		_frame(sim, 0, 0)
		if states.is_empty() or states[-1] != sim.wWarioState:
			states.append(sim.wWarioState)
		if sim.wWarioState == WarioRam.WST_IDLING:
			break
	assert_eq(states, [WarioRam.WST_BALL_O_STRING, WarioRam.WST_BALL_O_STRING_KNOCK_BACK,
			WarioRam.WST_GETTING_UNWRAPPED_IN_STRING, WarioRam.WST_BALL_O_STRING_DIZZY, WarioRam.WST_IDLING])
	assert_eq([sim.wTransformation, sim.wInvincibleCounter, sim.wIsIntangible], [0, 0x10, 0])
	assert_eq(sim.wDirection, WarioRam.DIRECTION_RIGHT, "turned at the wall, then round again on landing")


func test_on_fire_wario_runs_by_himself_turns_at_a_wall_and_is_hot_at_300_frames_left() -> void:
	var sim := _sim(40, WarioRam.DIRECTION_RIGHT, [[FLOOR_ROW - 1, 5, SOLID]])
	sim.wTransformation = WarioRam.TRANSFORMATION_HOT_WARIO
	sim.wTransformationDuration = WarioRam.HOT_WARIO_DURATION
	sim.wWarioStateCounter = 0
	sim.set_state_on_fire()
	assert_eq([sim.wWarioPalsPtr, sim.wWarioOAMPtr, sim.wWarioFramesetPtr],
			[WarioRam.WARIO_ON_FIRE_PAL, WarioRam.OAM_1673C & 0xFFFF, WarioRam.FRAMESET_SET_ON_FIRE_RIGHT])
	var turned: bool = false
	for frame: int in 40:
		_frame(sim, 0, 0)
		turned = turned or sim.wDirection == WarioRam.DIRECTION_LEFT
	assert_true(turned, "no input: he runs, and the wall turns him")
	assert_eq([sim.wWarioState, sim.wWarioStateCounter, sim.wTransformationDuration],
			[WarioRam.WST_ON_FIRE, 1, WarioRam.HOT_WARIO_DURATION - 40])
	sim.wTransformationDuration = WarioRam.HOT_WARIO_TRANSITION_DURATION + 1
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wTransformationProgress, sim.wTouchState],
			[WarioRam.WST_HOT, 2, WarioRam.TOUCH_VANISH])


func test_hot_wario_walks_where_held_cools_and_ends_burnt() -> void:
	var sim := _sim(40, WarioRam.DIRECTION_RIGHT)
	sim.wTransformation = WarioRam.TRANSFORMATION_HOT_WARIO
	sim.wJoypadDown = WarioRam.PAD_LEFT
	sim.set_state_hot()
	assert_eq(sim.wDirection, WarioRam.DIRECTION_LEFT, "the held direction")
	sim.wTransformationDuration = 225
	_frame(sim, WarioRam.PAD_LEFT, WarioRam.PAD_LEFT)
	assert_eq([sim.wWarioPalsPtr, sim.wWarioXPos], [WarioRam.WARIO_HOT_1_PAL, 39], "a pixel a frame")
	sim.wTransformationDuration = 61
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioPalsPtr, sim.wWarioXPos], [WarioRam.WARIO_HOT_3_PAL, 39])
	sim.wTransformationDuration = 2
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wWarioOAMPtr], [WarioRam.WST_BURNT, WarioRam.OAM_16B6C & 0xFFFF])
	for frame: int in 10:
		_frame(sim, 0, 0)
		if sim.wWarioState != WarioRam.WST_BURNT:
			break
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wTransformationDuration, sim.wInvincibleCounter],
			[WarioRam.WST_IDLING, 0, 0, 0x10], "recovered when the animation ends")


func test_bumping_into_an_enemy_knocks_wario_back_and_he_lands_turned_round() -> void:
	# Knocked to the right (the enemy is on his left): he lands facing it again.
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wWarioState = WarioRam.WST_ENEMY_BUMPING
	sim.wJumpVelTable = WarioRam.JUMP_VEL_KNOCK_BACK
	sim.wJumpVelIndex = 0x0E  # as SetState_EnemyBumping sets it
	sim.wWarioFramesetPtr = 0x4A6C
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_ENEMY_BUMPING and frames < 80:
		_frame(sim, 0, 0)
		frames += 1
	assert_true(sim.wWarioState != WarioRam.WST_ENEMY_BUMPING, "it ends on landing")
	assert_eq([sim.wDirection, sim.wWarioYPos], [WarioRam.DIRECTION_LEFT, FLOOR_ROW * 16], "turned round, on the floor")
	assert_true(sim.wWarioXPos > 80, "knocked back along wDirection, away from the enemy")


## Fat Wario as ObjInteraction_Food leaves him: eating, 420 frames to go.
func _fat(x: int) -> WarioSim:
	var sim := _sim(x, WarioRam.DIRECTION_RIGHT)
	sim.wTransformation = WarioRam.TRANSFORMATION_FAT_WARIO
	sim.wTransformationDuration = WarioRam.FAT_WARIO_DURATION
	sim.set_state_fat_eating()
	return sim


func test_fat_wario_eats_then_walks_slowly_until_his_time_runs_out_and_he_recovers() -> void:
	var sim: WarioSim = _fat(80)
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_FAT_EATING and frames < 20:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wTouchState], [WarioRam.WST_FAT_IDLING, WarioRam.TOUCH_ATTACK], "eaten: his touches attack")
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_FAT_WALKING)
	var x: int = sim.wWarioXPos
	sim.wTransformationDuration = 3
	_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_true(sim.wWarioXPos > x, "walking")
	_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_eq([sim.wWarioState, sim.wTouchState], [WarioRam.WST_FAT_RECOVERING, WarioRam.TOUCH_BUMP], "time up")
	for frame: int in 5:
		_frame(sim, 0, WarioRam.PAD_RIGHT)
	assert_eq([sim.wWarioState, sim.wTransformation], [WarioRam.WST_IDLING, 0], "back to normal")


func test_fat_wario_landing_from_a_jump_shakes_the_ground_but_is_not_stunned_by_it() -> void:
	var sim: WarioSim = _fat(80)
	sim.set_state_fat_idling()
	_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_FAT_AIRBORNE, WarioRam.JUMP_VEL_KNOCK_BACK])
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_FAT_AIRBORNE and frames < 80:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
		frames += 1
	assert_eq([sim.wWarioState, sim.wGroundShakeCounter, sim.wIsWarioGroundShaking], [WarioRam.WST_FAT_LANDING, 0x20, 1])
	frames = 0
	while sim.wWarioState == WarioRam.WST_FAT_LANDING and frames < 40:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, frames], [WarioRam.WST_FAT_IDLING, 0x20], "until the shaking stops")


func test_the_ground_shake_knocks_a_standing_wario_up_and_he_stands_again_when_it_stops() -> void:
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wGroundShakeCounter = 0x20
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelIndex, sim.wJumpVelTable, sim.wGroundShakeCounter],
			[WarioRam.WST_GROUND_SHAKE_STUNNED, 11, WarioRam.JUMP_VEL_KNOCK_BACK, 0x20],
			"stunned from index 10 and its first step the same frame; the counter waits")
	var shakes: Array = []
	for frame: int in 4:
		_frame(sim, 0, 0)
		shakes.append(sim.wSCYShake)
	assert_eq(shakes, [2, 2, 0, 0], "from $1f down, 2 px while bit 1 is set")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_GROUND_SHAKE_STUNNED and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wGroundShakeCounter, sim.wWarioYPos], [WarioRam.WST_IDLING, 0, FLOOR_ROW * 16])


func test_picked_up_wario_wiggles_free_with_six_quick_presses_and_slow_ones_start_the_count_again() -> void:
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wWarioState = WarioRam.WST_PICKED_UP
	sim.wAutoMoveState = 1
	sim.wJumpVelTable = 1
	sim.wPickedUpWiggleCounter = WarioRam.NUM_WIGGLES_TO_ESCAPE
	sim.wPickedUpFrameCounter = 1
	_frame(sim, WarioRam.PAD_LEFT, 0)
	assert_eq([sim.wDirection, sim.wPickedUpWiggleCounter, sim.wPickedUpFrameCounter],
			[WarioRam.DIRECTION_LEFT, 5, WarioRam.MAX_PICKED_UP_FRAME_COUNTER], "a wiggle turns him")
	for frame: int in WarioRam.MAX_PICKED_UP_FRAME_COUNTER:
		_frame(sim, 0, 0)
	assert_eq(sim.wPickedUpWiggleCounter, WarioRam.NUM_WIGGLES_TO_ESCAPE, "32 frames without one: the count starts again")
	for wiggle: int in WarioRam.NUM_WIGGLES_TO_ESCAPE:
		if wiggle > 0:
			_frame(sim, 0, WarioRam.PAD_A)
		_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wAutoMoveState], [WarioRam.WST_AIRBORNE, 0], "free at the sixth: a fall")


func test_ice_skatin_wario_skates_faster_and_faster_crashes_into_a_wall_and_thaws() -> void:
	var sim := _sim(80, WarioRam.DIRECTION_LEFT, [[FLOOR_ROW - 1, 12, SOLID]])  # a wall at x 192
	sim.wTransformation = WarioRam.TRANSFORMATION_ICE_SKATIN
	sim.wObjDirection = WarioRam.DIRECTION_RIGHT
	sim.set_state_ice_skatin_start()
	assert_eq([sim.wDirection, sim.wWarioPalsPtr], [WarioRam.DIRECTION_RIGHT, WarioRam.WARIO_ICE_SKATIN_PAL], "the object's way")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_ICE_SKATIN_START and frames < 10:
		_frame(sim, WarioRam.PAD_LEFT, 0)
		frames += 1
	assert_eq(sim.wWarioState, WarioRam.WST_ICE_SKATIN)
	var steps: Array = []
	var x: int = sim.wWarioXPos
	while sim.wWarioState == WarioRam.WST_ICE_SKATIN and frames < 200:
		_frame(sim, WarioRam.PAD_LEFT, WarioRam.PAD_LEFT)
		steps.append(sim.wWarioXPos - x)
		x = sim.wWarioXPos
		frames += 1
	assert_eq([steps[0], steps[8]], [1, 2], "right whatever the pad, faster along the walk's table")
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_ICE_SKATIN_CRASH, WarioRam.DIRECTION_LEFT], "the wall: turned round")
	for frame: int in 4:
		_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wParticles[WarioParticles.PARTICLE_STRUCT_ID]],
			[WarioRam.WST_IDLING, 0, WarioParticles.PARTICLE_ICE], "the ice breaks")


## Flattened by an object at x + 8, `height` px above the floor.
func _flattened(x: int, height: int) -> WarioSim:
	var sim := _sim(0, WarioRam.DIRECTION_RIGHT)
	sim.wWarioYPos = FLOOR_ROW * 16 - height
	sim.set_state_flat_airborne(x + 8, false)
	return sim


func test_flattened_wario_drops_2_px_a_frame_lies_squished_until_lifted_then_floats_down_flat() -> void:
	var sim: WarioSim = _flattened(80, 6)
	assert_eq([sim.wWarioState, sim.wWarioXPos, sim.wTransformation, sim.wCollisionBoxTop, sim.wAutoMoveState],
			[WarioRam.WST_GETTING_FLAT_AIRBORNE, 80, WarioRam.TRANSFORMATION_FLAT_WARIO, WarioRam.byte(-8), 1])
	for frame: int in 3:
		_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wIsIntangible, sim.wAutoMoveState],
			[WarioRam.WST_GETTING_FLAT, FLOOR_ROW * 16, 1, 0], "2 px a frame to the floor")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_GETTING_FLAT and frames < 20:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wIsIntangible], [WarioRam.WST_FLAT_SQUISHED, 0], "under the object")
	sim.set_state_flat_squished_lifting()
	for frame: int in 50:
		_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wIsIntangible], [WarioRam.WST_FLAT_FALLING, FLOOR_ROW * 16 - 50, 0],
			"lifted 50 px, then falling")
	frames = 0
	while sim.wWarioState == WarioRam.WST_FLAT_FALLING and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wWarioXPos, frames], [WarioRam.WST_FLAT_IDLING, FLOOR_ROW * 16, 80 + 25, 25],
			"2 px down and 1 across a frame, landing flat")


func test_flat_wario_walks_with_the_pad_and_a_jumps_then_he_floats_down() -> void:
	var sim: WarioSim = _sim(80, WarioRam.DIRECTION_LEFT)
	sim.wTransformation = WarioRam.TRANSFORMATION_FLAT_WARIO
	sim.set_state_flat_idling()
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_FLAT_WALKING, WarioRam.DIRECTION_RIGHT])
	for frame: int in 10:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		assert_true(sim.wWalkVelIndex < 4, "the walk index kept below 4")
	assert_true(sim.wWarioXPos > 80, "walking right")
	_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_FLAT_JUMPING, WarioRam.JUMP_VEL_KNOCK_BACK])
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_FLAT_JUMPING and frames < 40:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
		frames += 1
	assert_eq([sim.wWarioState, frames], [WarioRam.WST_FLAT_FALLING, 0x18], "past the jump's peak (index $18)")


func test_floating_flat_wario_turns_at_the_swings_end_unless_held_and_a_wall_turns_him_back() -> void:
	var sim: WarioSim = _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.tables.flat_fall_steps["down"] = PackedInt32Array(Array(FLAT_DOWN).map(func(_s: int) -> int: return 0))
	sim.wWarioYPos = FLOOR_ROW * 16 - 64
	sim.wTransformation = WarioRam.TRANSFORMATION_FLAT_WARIO
	sim.set_state_flat_falling()
	for frame: int in 0x28:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_eq([sim.wDirection, sim.wWalkVelIndex, sim.wWarioXPos], [WarioRam.DIRECTION_RIGHT, 0, 80 + 0x28], "held: on")
	for frame: int in 0x28:
		_frame(sim, 0, 0)
	assert_eq([sim.wDirection, sim.wWarioFramesetPtr], [WarioRam.DIRECTION_LEFT, 0x71B8], "let go: turned at the end")
	sim = _sim(80, WarioRam.DIRECTION_RIGHT, [[FLOOR_ROW - 3, 6, SOLID]])
	sim.wWarioYPos = FLOOR_ROW * 16 - 40
	sim.wTransformation = WarioRam.TRANSFORMATION_FLAT_WARIO
	sim.set_state_flat_falling()
	var frames: int = 0
	while sim.wDirection == WarioRam.DIRECTION_RIGHT and frames < 40:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq(sim.wWalkVelIndex, 0, "a wall: turned back 3 px, the swing restarted")


func _zombie(x: int, extra: Array = []) -> WarioSim:
	var sim := _sim(x, WarioRam.DIRECTION_RIGHT, extra)
	sim.wTransformation = WarioRam.TRANSFORMATION_ZOMBIE_WARIO
	sim.set_state_zombie_idling()
	return sim


func test_zombie_wario_walks_turns_back_and_writhes_after_512_idle_frames() -> void:
	var sim: WarioSim = _zombie(80)
	assert_eq([sim.wTouchState, sim.wWarioPalsPtr, sim.wCollisionBoxTop], [WarioRam.TOUCH_VANISH, WarioRam.WARIO_ZOMBIE_PAL, WarioRam.byte(-27)])
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_ZOMBIE_WALKING)
	for frame: int in 6:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		assert_true(sim.wWalkVelIndex < 4, "the walk index kept below 4")
	assert_true(sim.wWarioXPos > 80, "walking right")
	_frame(sim, WarioRam.PAD_LEFT, WarioRam.PAD_RIGHT)
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_ZOMBIE_TURNING, WarioRam.DIRECTION_LEFT])
	sim.set_state_zombie_idling()
	for frame: int in 511:
		_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wWarioStateCycles, sim.wWarioStateCounter], [WarioRam.WST_ZOMBIE_IDLING, 1, 0xFF])
	_frame(sim, 0, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_ZOMBIE_WRITHING, "the 512th idle frame")
	_frame(sim, WarioRam.PAD_B, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_ZOMBIE_IDLING, "any button")


func test_zombie_wario_landing_on_a_one_way_floor_slips_through_it_to_the_floor_below() -> void:
	var extra: Array = []
	for column: int in 10:
		extra.append([FLOOR_ROW - 4, column, FLOOR])
	var sim: WarioSim = _zombie(80, extra)
	sim.wWarioYPos = (FLOOR_ROW - 4) * 16
	sim.set_state_zombie_landing()
	assert_eq([sim.wc1ca, sim.wWarioStateCounter, sim.wTouchState], [1, 1, WarioRam.TOUCH_BUMP], "both corners on a floor")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_ZOMBIE_LANDING and frames < 10:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wWarioStateCycles],
			[WarioRam.WST_ZOMBIE_SLIPPING_THROUGH_FLOOR, WarioRam.JUMP_VEL_NORMAL, 6])
	frames = 0
	while sim.wWarioState == WarioRam.WST_ZOMBIE_SLIPPING_THROUGH_FLOOR and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wWarioStateCounter], [WarioRam.WST_ZOMBIE_LANDING, FLOOR_ROW * 16, 2],
			"through the floor to the solid one")
	frames = 0
	while sim.wWarioState == WarioRam.WST_ZOMBIE_LANDING and frames < 10:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq(sim.wWarioState, WarioRam.WST_ZOMBIE_IDLING)


func test_a_recovering_zombie_steps_through_the_zombie_palettes_and_is_wario_again() -> void:
	var sim: WarioSim = _zombie(80)
	sim.set_state_zombie_recovering()
	var palettes: Array = []
	sim.wGlobalCounter = 1
	sim.update_state_zombie_recovering()
	assert_eq(sim.wWarioStateCounter, 0, "every fourth frame only")
	sim.wGlobalCounter = 0
	while sim.wTransformation != 0 and palettes.size() < 12:
		sim.update_state_zombie_recovering()
		palettes.append((sim.wWarioPalsPtr - WarioRam.WARIO_ZOMBIE_PAL) / 0x10)
	assert_eq(palettes.slice(0, 10), [1, 2, 3, 4, 5, 6, 7, 6, 5, 4], "up to the seventh, then back three")
	assert_eq([sim.wWarioState, sim.wWarioPalsPtr], [WarioRam.WST_IDLING, WarioRam.WARIO_DEFAULT_PAL], "then Wario again")


func test_blind_wario_walks_until_a_wall_gives_him_his_sight_back() -> void:
	var sim: WarioSim = _sim(80, WarioRam.DIRECTION_RIGHT, [[FLOOR_ROW - 1, 8, SOLID], [FLOOR_ROW - 2, 8, SOLID]])
	sim.wTransformation = WarioRam.TRANSFORMATION_BLIND
	sim.set_state_blind_idling()
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_BLIND_WALKING)
	var frames: int = 0
	while sim.wTransformation == WarioRam.TRANSFORMATION_BLIND and frames < 60:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		assert_true(sim.wWalkVelIndex < 0x10, "the walk index kept below $10")
		frames += 1
	assert_eq([sim.wTransformation, (sim.wWarioXPos + 9) / 16], [0, 8], "his front in the wall's column: Wario again")


func test_blind_wario_falls_on_the_high_jump_table_and_lands_blind() -> void:
	var sim: WarioSim = _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wTransformation = WarioRam.TRANSFORMATION_BLIND
	sim.wWarioYPos = FLOOR_ROW * 16 - 20
	sim.set_state_blind_idling()
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wJumpVelIndex],
			[WarioRam.WST_BLIND_AIRBORNE, WarioRam.JUMP_VEL_HIGH_JUMP, WarioRam.FALLING_JUMP_VEL_INDEX], "nothing under him")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_BLIND_AIRBORNE and frames < 30:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wTransformation],
			[WarioRam.WST_BLIND_IDLING, FLOOR_ROW * 16, WarioRam.TRANSFORMATION_BLIND])
	_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wJumpingUpwards], [WarioRam.WST_BLIND_AIRBORNE, WarioRam.JUMP_VEL_NORMAL, 1])


func _bouncy(height: int) -> WarioSim:
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wTransformation = WarioRam.TRANSFORMATION_BOUNCY_WARIO
	sim.wTransformationDuration = WarioRam.BOUNCY_WARIO_DURATION
	sim.wWarioYPos = FLOOR_ROW * 16 - height
	sim.set_state_bouncy_start()
	return sim


func test_bouncy_wario_falls_to_the_floor_and_bounces_high_with_a_held() -> void:
	var sim: WarioSim = _bouncy(20)
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wCollisionBoxTop, sim.wWarioPalsPtr],
			[WarioRam.WST_BOUNCY_START, WarioRam.JUMP_VEL_NORMAL, WarioRam.byte(-29), WarioRam.WARIO_BOUNCY_PAL])
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_BOUNCY_START and frames < 30:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos], [WarioRam.WST_BOUNCY_FLOOR, FLOOR_ROW * 16])
	assert_true(sim.wWarioXPos > 80, "carried on the way he faces")
	frames = 0
	while sim.wWarioState == WarioRam.WST_BOUNCY_FLOOR and frames < 10:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_BOUNCY_AIRBORNE, WarioRam.JUMP_VEL_BOUNCY_JUMP])
	sim.set_state_bouncy_floor()
	var duration: int = sim.wTransformationDuration
	for frame: int in 3:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_BOUNCY_AIRBORNE, WarioRam.JUMP_VEL_BOUNCY_HIGH_JUMP], "high")
	assert_eq(sim.wTransformationDuration, duration - 3, "the time runs on the floor and in the air")


func test_time_up_in_the_air_turns_bouncy_wario_upside_down_then_a_last_bounce_and_wario_again() -> void:
	var sim: WarioSim = _bouncy(40)
	sim.set_state_bouncy_airborne()
	sim.wJumpVelIndex = WarioRam.FALLING_JUMP_VEL_INDEX
	sim.wJumpVelTable = WarioRam.JUMP_VEL_BOUNCY_JUMP
	sim.wTransformationDuration = 1
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wTouchState, sim.wJumpVelTable],
			[WarioRam.WST_BOUNCY_UPSIDE_DOWN, WarioRam.TOUCH_PASS_THROUGH, WarioRam.JUMP_VEL_NORMAL], "time up")
	var frames: int = 0
	while sim.wWarioState != WarioRam.WST_BOUNCY_LAST_BOUNCE and frames < 40:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wJumpVelIndex, sim.wJumpVelTable], [WarioRam.WST_BOUNCY_LAST_BOUNCE, 0, WarioRam.JUMP_VEL_NORMAL],
			"landed upside down, then the last bounce")
	frames = 0
	while sim.wTransformation != 0 and frames < 60:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wTransformation, sim.wWarioYPos], [0, FLOOR_ROW * 16], "Wario again on the ground")


func test_bouncy_wario_flickers_red_every_fourth_frame_under_120_frames_left() -> void:
	var sim: WarioSim = _bouncy(0)
	sim.wTransformationDuration = 0x77
	sim.wGlobalCounter = 1
	sim._bouncy_flicker()
	assert_eq(sim.wWarioPalsPtr, WarioRam.WARIO_BOUNCY_PAL, "not on this frame")
	sim.wGlobalCounter = 4
	sim._bouncy_flicker()
	assert_eq(sim.wWarioPalsPtr, WarioRam.WARIO_BOUNCY_RED_PAL)
	sim._bouncy_flicker()
	assert_eq(sim.wWarioPalsPtr, WarioRam.WARIO_BOUNCY_PAL)
	sim.wTransformationDuration = 0x200
	sim._bouncy_flicker()
	assert_eq(sim.wWarioPalsPtr, WarioRam.WARIO_BOUNCY_PAL, "not with 512 frames left")


## Wario walking right on a slippery floor (BlockFunc_SlipperySolid in place of the solid floor).
func _slippery(x: int) -> WarioSim:
	var sim := _sim(x, WarioRam.DIRECTION_RIGHT)
	var handlers: PackedStringArray = sim.level.room_handlers[0]
	handlers[SOLID] = "h06_4997"
	sim.level.room_handlers[0] = handlers
	sim.set_state_walking()
	return sim


func _counted_frame(sim: WarioSim, down: int, previous: int) -> void:
	sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
	_frame(sim, down, previous)


func test_letting_go_on_slippery_ground_slides_wario_20_frames_slower_and_slower() -> void:
	var sim: WarioSim = _slippery(80)
	_counted_frame(sim, WarioRam.PAD_RIGHT, 0)
	_counted_frame(sim, 0, WarioRam.PAD_RIGHT)
	assert_eq([sim.wWarioState, sim.wWarioStateCycles], [WarioRam.WST_SLIPPING, 1], "sliding right")
	var x: int = sim.wWarioXPos
	var steps: Array = []
	while sim.wWarioState == WarioRam.WST_SLIPPING and steps.size() < 30:
		_counted_frame(sim, 0, 0)
		steps.append(sim.wWarioXPos - x)
		x = sim.wWarioXPos
	assert_eq(steps.slice(0, 14), [2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1], "2 px for 7 frames, then 1 px for 7")
	assert_eq([steps.size(), sim.wWarioState, sim.wDirection], [21, WarioRam.WST_IDLING, WarioRam.DIRECTION_RIGHT],
			"then every other frame, stopping at the count's 21st")


func test_the_pad_against_the_slide_turns_wario_and_down_makes_it_a_crouch_slip() -> void:
	var sim: WarioSim = _slippery(80)
	_counted_frame(sim, WarioRam.PAD_RIGHT, 0)
	_counted_frame(sim, 0, WarioRam.PAD_RIGHT)
	_counted_frame(sim, WarioRam.PAD_LEFT, 0)
	assert_eq([sim.wWarioStateCycles, sim.wWarioFramesetPtr, sim.wDirection],
			[2, WarioRam.FRAMESET_TURN_LEFT, WarioRam.DIRECTION_RIGHT], "turning to the left, still sliding right")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_SLIPPING and frames < 30:
		_counted_frame(sim, WarioRam.PAD_LEFT, WarioRam.PAD_LEFT)
		frames += 1
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_IDLING, WarioRam.DIRECTION_LEFT], "stopped, facing left")
	sim = _slippery(80)
	_counted_frame(sim, WarioRam.PAD_RIGHT, 0)
	_counted_frame(sim, WarioRam.PAD_RIGHT | WarioRam.PAD_DOWN, WarioRam.PAD_RIGHT)
	assert_eq([sim.wWarioState, sim.wIsCrouching], [WarioRam.WST_CROUCH_SLIPPING, 1])
	var x: int = sim.wWarioXPos
	frames = 0
	while sim.wWarioState == WarioRam.WST_CROUCH_SLIPPING and frames < 30:
		_counted_frame(sim, WarioRam.PAD_DOWN, WarioRam.PAD_DOWN)
		frames += 1
	assert_eq([sim.wWarioXPos - x, frames], [5 * 2 + 4 + 2, 14], "2 px for 5 frames, 1 px for 4, then every other frame")


## Falling from `height` px with the given power-up level.
func _falling(height: int, power_up: int) -> WarioSim:
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wPowerUpLevel = power_up
	sim.wWarioYPos = FLOOR_ROW * 16 - height
	sim.start_fall()
	return sim


func test_down_while_falling_with_the_overalls_smash_attacks_and_the_landing_pounds_for_27_frames() -> void:
	var sim: WarioSim = _falling(30, WarioRam.LEAD_OVERALLS)
	_frame(sim, WarioRam.PAD_DOWN, 0)
	assert_eq([sim.wIsSmashAttacking, sim.wWarioFramesetPtr], [1, 0x5F91], "smash attacking")
	_frame(sim, 0, WarioRam.PAD_DOWN)
	assert_eq([sim.wIsSmashAttacking, sim.wWarioFramesetPtr], [0, WarioRam.FRAMESET_AIRBORNE_RIGHT], "let go: a fall again")
	_frame(sim, WarioRam.PAD_DOWN, 0)
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_AIRBORNE and frames < 40:
		_frame(sim, WarioRam.PAD_DOWN, WarioRam.PAD_DOWN)
		frames += 1
	assert_eq([sim.wWarioState, sim.wIsSmashAttacking, sim.wWarioFramesetPtr, sim.wGroundShakeCounter],
			[WarioRam.WST_SMASH_ATTACKING, 0x81, 0x6009, 0], "a ground pound")
	for frame: int in 26:
		_frame(sim, 0, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_SMASH_ATTACKING)
	_frame(sim, 0, 0)
	assert_eq([sim.wWarioState, sim.wIsSmashAttacking], [WarioRam.WST_IDLING, 0], "the 27th frame")


func test_with_the_super_jump_slam_overalls_a_smash_attack_landing_shakes_the_ground() -> void:
	var sim: WarioSim = _falling(30, WarioRam.SUPER_JUMP_SLAM_OVERALLS)
	_frame(sim, WarioRam.PAD_DOWN, 0)
	assert_eq(sim.wWarioFramesetPtr, 0x6055)
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_AIRBORNE and frames < 40:
		_frame(sim, WarioRam.PAD_DOWN, WarioRam.PAD_DOWN)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioFramesetPtr, sim.wGroundShakeCounter, sim.wIsWarioGroundShaking],
			[WarioRam.WST_SMASH_ATTACKING, 0x5FC5, 32, 1], "32 frames of shaking, Wario's own")


## Wario holding an object, standing.
func _holding(power_up: int = WarioRam.GRAB_GLOVE) -> WarioSim:
	var sim := _sim(80, WarioRam.DIRECTION_RIGHT)
	sim.wPowerUpLevel = power_up
	sim.wGrabState = WarioRam.GRAB_PICK_UP
	sim.set_state_grab_idling()
	return sim


func test_holding_an_object_wario_walks_jumps_and_lands_holding_it() -> void:
	var sim: WarioSim = _holding()
	assert_eq([sim.wWarioState, sim.wGrabState, sim.wWarioFramesetPtr], [WarioRam.WST_GRAB_IDLING, WarioRam.GRAB_IDLE, 0x4A23])
	_frame(sim, WarioRam.PAD_RIGHT, 0)
	assert_eq([sim.wWarioState, sim.wWarioFramesetPtr], [WarioRam.WST_GRAB_WALKING, 0x4A0F])
	for frame: int in 30:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		assert_true(sim.wWalkVelIndex < 0x10, "below $10, back to $0c")
	_frame(sim, WarioRam.PAD_LEFT, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioState, WarioRam.WST_GRAB_IDLING, "the other way: standing, still facing right")
	_frame(sim, WarioRam.PAD_A, 0)
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_GRAB_AIRBORNE, WarioRam.JUMP_VEL_NORMAL], "a jump holding it")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_GRAB_AIRBORNE and frames < 60:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos, sim.wGrabState], [WarioRam.WST_GRAB_IDLING, FLOOR_ROW * 16, WarioRam.GRAB_IDLE])


func test_b_held_charges_a_throw_30_frames_and_letting_go_throws_it_fully_charged() -> void:
	var sim: WarioSim = _holding()
	_frame(sim, WarioRam.PAD_B, 0)
	assert_eq([sim.wWarioState, sim.wGrabState & WarioRam.GRAB_STATE_MASK], [WarioRam.WST_THROW_CHARGING, WarioRam.GRAB_CHARGE_THROW])
	for frame: int in 29:
		_frame(sim, WarioRam.PAD_B, WarioRam.PAD_B)
	assert_eq(sim.wWarioState, WarioRam.WST_THROW_CHARGING, "29 frames")
	_frame(sim, WarioRam.PAD_B, WarioRam.PAD_B)
	assert_eq([sim.wWarioState, sim.wGrabState], [WarioRam.WST_THROW_FULLY_CHARGED, WarioRam.GRAB_THROW_FULLY_CHARGED], "the 30th")
	_frame(sim, 0, WarioRam.PAD_B)
	assert_eq([sim.wWarioState, sim.wGrabState], [WarioRam.WST_THROWING, WarioRam.GRAB_THROW | WarioRam.GRAB_FULL_CHARGE])
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_THROWING and frames < 10:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wGrabState], [WarioRam.WST_IDLING, 0], "thrown")


func test_a_heavy_object_takes_60_frames_to_charge_and_a_while_charging_drops_it_and_jumps() -> void:
	var sim: WarioSim = _holding(WarioRam.SUPER_GRAB_GLOVES)
	sim.wGrabState |= WarioRam.GRAB_HEAVY
	_frame(sim, WarioRam.PAD_B, 0)
	for frame: int in 59:
		_frame(sim, WarioRam.PAD_B, WarioRam.PAD_B)
	assert_eq(sim.wWarioState, WarioRam.WST_THROW_CHARGING, "59 frames: still charging")
	_frame(sim, WarioRam.PAD_B | WarioRam.PAD_A, WarioRam.PAD_B)
	assert_eq([sim.wWarioState, sim.wGrabState], [WarioRam.WST_AIRBORNE, 0], "dropped, a jump")


func test_crazy_wario_spins_128_frames_gets_dizzy_then_staggers_on_by_himself() -> void:
	var sim: WarioSim = _sim(80, WarioRam.DIRECTION_LEFT)
	sim.wTransformation = WarioRam.TRANSFORMATION_CRAZY_WARIO
	sim.wObjDirection = WarioRam.DIRECTION_RIGHT
	sim.set_state_crazy_spinning()
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_CRAZY_SPINNING, WarioRam.DIRECTION_RIGHT], "the object's way")
	for frame: int in 127:
		_frame(sim, 0, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_CRAZY_SPINNING)
	_frame(sim, 0, 0)
	assert_eq(sim.wWarioState, WarioRam.WST_CRAZY_DIZZY, "128 frames")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_CRAZY_DIZZY and frames < 20:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wTouchState, sim.wStingTouchState],
			[WarioRam.WST_CRAZY, WarioRam.TOUCH_BUMP, WarioRam.TOUCH_VULNERABLE])
	var x: int = sim.wWarioXPos
	var steps: Array = []
	for frame: int in 8:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
		steps.append(sim.wWarioXPos - x)
		x = sim.wWarioXPos
	assert_eq(steps, [2, 2, 2, 2, 2, 0, 0, 0], "2 px for 5 frames, then a pause")
	assert_eq(sim.wWarioState, WarioRam.WST_CRAZY, "the pad holds his way")
	frames = 0
	while sim.wWarioState == WarioRam.WST_CRAZY and frames < 20:
		_frame(sim, 0, 0)
		frames += 1
	assert_eq([sim.wWarioState, sim.wDirection], [WarioRam.WST_CRAZY_TURNING, WarioRam.DIRECTION_LEFT],
			"without it, the animation's end turns him")
