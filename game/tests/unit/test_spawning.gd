extends TestCase
## Spawning on invented data (no ROM bytes): SpawnObject's fields, edge streaming's spawns, and the
## room start's window inside the room's limits.


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
	var pointers: Array = []
	for i: int in 16:
		pointers.append("43c3")
	pointers[3] = "4413"  # nibble 4
	sim.load_object_groups({"object_groups": {"groups": [{"obj_data_pointers": pointers}],
			"object_data": {"4413": "0c01f2401a4069c0", "43c3": "0000000000000000"}}})
	sim.load_object_group(0)
	return sim


## An object (nibble 4) at map cell (row, column), not yet spawned (bit 7).
func _place(sim: LevelSim, row: int, column: int) -> void:
	sim.level.set_block(row, column, 0x80 | 0x05)
	var index: int = column >> 1
	var value: int = sim.level.object_rows[row][index]
	sim.level.object_rows[row][index] = (value & 0x0F) | 0x40 if (column & 1) == 0 else (value & 0xF0) | 0x04


func test_spawn_object_takes_the_first_free_slot_and_clears_the_cells_bit_7() -> void:
	var sim: LevelSim = _sim()
	_place(sim, 3, 6)
	sim.wram1[0] = ObjectSim.OBJFLAG_ACTIVE
	sim.wram1[32 + ObjectSim.OBJ_VAR_1] = 0x55  # left over from an earlier object
	sim.wccec = 1
	sim.hYPos = 3 * 16 + 16
	sim.hXPos = 6 * 16 + 8
	sim.spawn_object(3, 6, 4)
	var base: int = 32
	assert_eq(sim.wram1[base], 0xC0 | ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_INVISIBLE, "the data's flags")
	assert_eq([sim.wram1[base + ObjectSim.OBJ_UNK_01], sim.wram1[base + ObjectSim.OBJ_UNK_02]], [6, 0xA3], "its map cell")
	assert_eq([sim.wram1[base + ObjectSim.OBJ_Y_POS], sim.wram1[base + ObjectSim.OBJ_X_POS]], [0x40, 0x68])
	assert_eq([sim.wram1[base + ObjectSim.OBJ_ID], sim.wram1[base + ObjectSim.OBJ_INTERACTION_TYPE],
			sim.wram1[base + ObjectSim.OBJ_COLLBOX_TOP]], [0x0C, 0x01, 0xF2])
	assert_eq([sim.wram1[base + ObjectSim.OBJ_SUBSTATE], sim.wram1[base + ObjectSim.OBJ_ACTION]], [0x21, 0x82])
	assert_eq(sim.wram1[base + ObjectSim.OBJ_VAR_1], 0x55, "fields SpawnObject does not write keep their bytes")
	assert_eq(sim.level.block_at(3, 6), 0x05, "spawned: bit 7 cleared")
	sim.spawn_object(3, 6, 4)
	assert_eq(sim.wram1[64], 0, "a cell already spawned spawns nothing")


func test_a_right_edge_spawns_the_objects_of_its_column() -> void:
	var sim: LevelSim = _sim()
	sim.wCameraSCY = 0x0040
	sim.wCameraSCX = 0x0100
	# The right edge's column: (($100 & ~7) + $b0) >> 4 = column 27; rows from (($40 - $10) >> 4) = 3.
	_place(sim, 5, 27)
	_place(sim, 20, 27)  # beyond the 12 rows
	sim.wLevelEdgeUpdateFlags = WarioRam.LEVEL_EDGE_UPDATE_RIGHT
	sim.stream_level_edges()
	assert_eq(sim.wLevelEdgeUpdateFlags, 0)
	assert_eq([sim.wram1[0] & ObjectSim.OBJFLAG_ACTIVE, sim.wram1[ObjectSim.OBJ_UNK_01], sim.wram1[ObjectSim.OBJ_UNK_02]],
			[1, 27, 0xA5])
	assert_eq(sim.wram1[32], 0, "row 20 is outside the edge")


func test_the_room_start_spawns_only_inside_the_rooms_limits() -> void:
	var sim: LevelSim = _sim()
	sim.load_room_camera({"upper_y_limit": 0, "lower_y_limit": 1, "left_x_limit": 0, "right_x_limit": 1,
			"camera_config": 0, "object_group": 0})
	sim.wBlockYPos = 0
	sim.wBlockXPos = 0
	_place(sim, 4, 6)
	_place(sim, 4, 17)  # right of the right limit (section 1 starts at column 16)
	sim.spawn_room_objects()
	assert_eq([sim.wram1[0] & ObjectSim.OBJFLAG_ACTIVE, sim.wram1[ObjectSim.OBJ_UNK_01]], [1, 6])
	assert_eq(sim.wram1[32], 0, "column 17 is beyond wc0c7")
	assert_eq(sim.level.block_at(4, 17), 0x85, "and keeps bit 7 for later")
