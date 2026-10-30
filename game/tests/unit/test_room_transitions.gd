extends TestCase
## Room transitions in LevelSim on a synthetic level (no ROM data): a transition block starts one,
## the fades take the original's frame counts, and the next room is the room-list entry of Wario's
## section, entered at its spawn.

const FLOOR_ROW: int = 10


func _tables() -> WarioTables:
	var walk: Array = []
	var jump: Array = []
	for i: int in 0x1C:
		walk.append(2)
	for i: int in 0x28:
		jump.append(-2 if i < 0x18 else 2)
	return WarioTables.from_document({
		"walk_vel_table": {"steps": walk},
		"jump_vel_tables": [{"id": 2, "steps": jump}],
		"framesets": {"4252": {"pairs": [[0, 9]]}, "425f": {"pairs": [[0, 9]]},
				"49b4": {"pairs": [[0, 3]]}, "49c5": {"pairs": [[0, 3]]}},
	})


## Room-list entry 0 (section 0, 0) and entry 1 (section 1, 0); entry 1's spawn is block (3, 9).
## The transition block's handler is `transition` (BlockFunc_187b0 by default: kind 4).
func _level(transition: String = "h06_47b0") -> LevelCollision:
	var rows: Array = []
	var objects: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		row.fill(1 if y == FLOOR_ROW else 0)
		if y == FLOOR_ROW - 1:
			row[17] = 2  # a transition block at x 272-287
		rows.append(row.hex_encode())
		var object_row := PackedByteArray()
		object_row.resize(80)
		if y == FLOOR_ROW - 1:
			object_row[1] = 0x0F  # the spawn nibble of block 3
		objects.append(object_row.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	handlers[2] = transition
	var fields: Dictionary = {"camera_config": 0x18, "left_x_limit": 0, "right_x_limit": 2, "upper_y_limit": 0,
			"lower_y_limit": 1, "spawn_x": 0, "spawn_y": 0, "room": 1}
	return LevelCollision.from_document({"block_rows": rows, "object_rows": objects,
			"rooms": [{"level_room_id": 0, "handlers": handlers, "fields": fields},
					{"level_room_id": 1, "handlers": handlers, "fields": fields}],
			"start": {"level_room_id": 0, "wario_x": 250, "wario_y": 160}})


func test_the_spawn_search_finds_the_first_spawn_nibble_below_the_section() -> void:
	assert_eq(_level().find_spawn(0, 0), [3, 9])
	assert_eq(_level().find_spawn(1, 0), [], "no spawn in section 1's columns")


func test_walking_into_a_transition_block_moves_to_the_next_rooms_spawn() -> void:
	_walk_through(_level(), WarioRam.ROOMTRANSITION_4 | WarioRam.ROOMTRANSITIONF_RELOAD_OBJECTS)


func test_a_ladder_transition_block_takes_the_same_way() -> void:
	# BlockFunc_182fe: a ladder that also starts room transition 5.
	_walk_through(_level("h06_42fe"), WarioRam.ROOMTRANSITION_5 | WarioRam.ROOMTRANSITIONF_RELOAD_OBJECTS)


func _walk_through(level: LevelCollision, param: int) -> void:
	var sim: LevelSim = LevelRunner.start(_tables(), level)
	var frames: int = 0
	while sim.wSubState == LevelSim.SST_UPDATE_LEVEL and frames < 40:
		LevelRunner.frame(sim, InputBits.RIGHT)
		frames += 1
	assert_eq(sim.wSubState, LevelSim.SST_FAST_FADE_TO_WHITE, "the presence probe met the transition block")
	assert_eq([sim.wRoomTransitionParam, sim.wIsIntangible], [param, 1])
	assert_true(sim.wWarioXPos >= 272, "inside section 1 (x %d)" % sim.wWarioXPos)
	var loops: int = 0
	while sim.wSubState != LevelSim.SST_UPDATE_LEVEL and loops < 200:
		LevelRunner.frame(sim, InputBits.RIGHT)
		loops += 1
	assert_eq(loops, 33 + 1 + 33, "fade out, the room start, fade in")
	assert_eq([sim.wLevelRoomID, sim.wWarioXPos, sim.wWarioYPos], [1, 56, 160], "room-list entry 1, at its spawn")
	assert_eq([sim.wRoomTransitionParam, sim.wIsIntangible], [0, 0])
	assert_true(sim.unported.is_empty(), "nothing unported: %s" % sim.unported)
