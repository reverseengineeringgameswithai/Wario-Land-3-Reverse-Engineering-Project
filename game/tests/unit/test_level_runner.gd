extends TestCase
## LevelRunner: one game frame of input and update, and the start from a level's data.


func _level() -> LevelCollision:
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		row.fill(1 if y == 10 else 0)
		rows.append(row.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	return LevelCollision.from_document({
		"block_rows": rows,
		"rooms": [{"level_room_id": 0, "handlers": handlers, "fields": {"camera_config": 0x18}}],
		"start": {"level_room_id": 0, "wario_x": 40, "wario_y": 160},
	})


func _tables() -> WarioTables:
	var walk: Array = []
	var jump: Array = []
	for i: int in 0x1C:
		walk.append(1)
	for i: int in 0x28:
		jump.append(-1 if i < 0x18 else 1)
	return WarioTables.from_document({
		"walk_vel_table": {"steps": walk},
		"jump_vel_tables": [{"id": 2, "steps": jump}],
		"framesets": {"4252": {"pairs": [[0, 9]]}, "425f": {"pairs": [[0, 9]]},
				"49b4": {"pairs": [[0, 3]]}, "49c5": {"pairs": [[0, 3]]},
				"5f94": {"pairs": [[0, 3]]}, "5f97": {"pairs": [[0, 3]]}},
	})


func test_input_bits_become_the_game_boy_joypad_byte() -> void:
	assert_eq(InputBits.to_joypad(InputBits.A), 0x01)
	assert_eq(InputBits.to_joypad(InputBits.B | InputBits.START), 0x0A)
	assert_eq(InputBits.to_joypad(InputBits.RIGHT | InputBits.LEFT | InputBits.UP | InputBits.DOWN), 0xF0)
	assert_eq(InputBits.to_joypad(InputBits.SELECT), 0x04)


func test_the_start_uses_the_level_data_and_faces_right() -> void:
	var sim: WarioSim = LevelRunner.start(_tables(), _level())
	assert_eq([sim.wWarioXPos, sim.wWarioYPos, sim.wDirection], [40, 160, WarioRam.DIRECTION_RIGHT], "spawn")
	assert_eq([sim.wWarioState, sim.wCameraConfigFlags], [WarioRam.WST_IDLING, 0x18], "idling in the room's camera mode")
	# CAM_TRANSITIONS is set, so SetWarioPositionToSpawn updates the floor: y = $a0 is floor 5 ($80-$ff).
	assert_eq(sim.wFloor, 5, "floor")


func test_pressed_holds_only_the_buttons_that_became_held_this_frame() -> void:
	var sim: WarioSim = LevelRunner.start(_tables(), _level())
	LevelRunner.frame(sim, InputBits.RIGHT)
	assert_eq([sim.wJoypadDown, sim.wJoypadPressed], [0x10, 0x10], "first frame")
	LevelRunner.frame(sim, InputBits.RIGHT | InputBits.A)
	assert_eq([sim.wJoypadDown, sim.wJoypadPressed], [0x11, 0x01], "A added")
	LevelRunner.frame(sim, InputBits.RIGHT | InputBits.A)
	assert_eq(sim.wJoypadPressed, 0, "nothing new")
	assert_eq(sim.wGlobalCounter, 3, "the frame counter steps once a frame")
	assert_eq(sim.wWarioState, WarioRam.WST_AIRBORNE, "the A press jumped")
