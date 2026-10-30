extends TestCase
## Sand on invented tables and a synthetic level (no ROM bytes): a pit of sand above a floor, and
## Wario sinking, standing, walking, and jumping out.

const FREE: int = 0
const SOLID: int = 1
const SAND: int = 2
const PIT_TOP: int = 8  # sand rows 8-13, floor at row 14
const FLOOR_Y: int = 14 * 16


func _tables() -> WarioTables:
	var walk: Array = []
	for i: int in 0x1C:
		walk.append(1)
	var normal: Array = []
	for i: int in 0x28:
		normal.append(-3 if i < 12 else 2)
	var framesets: Dictionary = {}
	for key: String in ["4252", "425f", "49b4", "49c5", "4cbe", "4cc5", "5f94", "5f97"]:
		framesets[key] = {"pairs": [[0, 3]]}
	return WarioTables.from_document({"walk_vel_table": {"steps": walk},
			"jump_vel_tables": [{"id": 1, "steps": normal}, {"id": 2, "steps": normal}], "framesets": framesets})


func _sim(x: int, y: int) -> WarioSim:
	var rows: Array = []
	for row: int in LevelCollision.HEIGHT:
		var block: int = SOLID if row == 14 else (SAND if row >= PIT_TOP and row < 14 else FREE)
		var data := PackedByteArray()
		data.resize(LevelCollision.WIDTH)
		data.fill(block)
		rows.append(data.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[SOLID] = "h06_4032"
	handlers[SAND] = "h06_484c"
	var sim := WarioSim.new()
	sim.tables = _tables()
	sim.level = LevelCollision.from_document({"block_rows": rows, "rooms": [{"level_room_id": 0, "handlers": handlers}]})
	sim.wWarioXPos = x
	sim.wWarioYPos = y
	sim.wDirection = WarioRam.DIRECTION_RIGHT
	sim.wCollisionBoxTop = WarioRam.byte(-27)
	sim.wCollisionBoxBottom = WarioRam.byte(-1)
	sim.wCollisionBoxLeft = WarioRam.byte(-9)
	sim.wCollisionBoxRight = 9
	return sim


func _frame(sim: WarioSim, down: int, previous: int = 0) -> void:
	sim.wJoypadDown = down
	sim.wJoypadPressed = down & ~previous
	sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
	sim.update()


func test_falling_into_sand_sinks_a_pixel_a_frame_two_with_down_and_stands_on_the_floor() -> void:
	var sim: WarioSim = _sim(80, PIT_TOP * 16 + 8)
	sim.start_fall()
	_frame(sim, 0)
	assert_eq([sim.wWarioState, sim.wIsInSand], [WarioRam.WST_SAND_FALLING, 1])
	var y: int = sim.wWarioYPos
	_frame(sim, 0)
	assert_eq(sim.wWarioYPos, y + 1, "1 px a frame")
	_frame(sim, WarioRam.PAD_DOWN)
	assert_eq(sim.wWarioYPos, y + 3, "2 with Down")
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_SAND_FALLING and frames < 200:
		_frame(sim, WarioRam.PAD_DOWN, WarioRam.PAD_DOWN)
		frames += 1
	assert_eq([sim.wWarioState, sim.wWarioYPos], [WarioRam.WST_SAND_IDLING, FLOOR_Y], "standing on the floor")


func test_in_sand_a_rises_while_held_and_letting_go_sinks_again() -> void:
	var sim: WarioSim = _sim(80, FLOOR_Y)
	sim.set_state_sand_idling()
	_frame(sim, WarioRam.PAD_A)
	assert_eq([sim.wWarioState, sim.wJumpVelTable], [WarioRam.WST_SAND_JUMPING, WarioRam.JUMP_VEL_KNOCK_BACK])
	for frame: int in 3:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
	assert_eq([sim.wWarioState, sim.wWarioYPos], [WarioRam.WST_SAND_JUMPING, FLOOR_Y - 9], "3 px a frame up")
	_frame(sim, 0, WarioRam.PAD_A)
	assert_eq(sim.wWarioState, WarioRam.WST_SAND_FALLING, "A released")


func test_rising_out_of_the_sand_is_a_jump_and_walking_in_it_follows_the_pad() -> void:
	var sim: WarioSim = _sim(80, PIT_TOP * 16 + 2)
	sim.set_state_sand_idling()
	_frame(sim, WarioRam.PAD_A)
	var frames: int = 0
	while sim.wWarioState == WarioRam.WST_SAND_JUMPING and frames < 20:
		_frame(sim, WarioRam.PAD_A, WarioRam.PAD_A)
		frames += 1
	assert_eq([sim.wWarioState, sim.wJumpVelTable, sim.wIsInSand], [WarioRam.WST_AIRBORNE, WarioRam.JUMP_VEL_KNOCK_BACK, 0],
			"out of the sand: StartJump_FromSand")

	sim = _sim(80, FLOOR_Y)
	sim.set_state_sand_idling()
	_frame(sim, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioState, WarioRam.WST_SAND_WALKING)
	var x: int = sim.wWarioXPos
	for frame: int in 4:
		_frame(sim, WarioRam.PAD_RIGHT, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioXPos, x + 4, "the walk's speed")
	_frame(sim, 0, WarioRam.PAD_RIGHT)
	assert_eq(sim.wWarioState, WarioRam.WST_SAND_IDLING)
