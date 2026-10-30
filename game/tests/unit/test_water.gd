extends TestCase
## Water on invented tables and a synthetic level (no ROM bytes): a pool below a floor, its
## surface, a current, and Wario diving, floating up, bobbing, and swimming with the flippers.

const FREE: int = 0
const SOLID: int = 1
const WATER: int = 2
const RIGHT_CURRENT: int = 3
const POOL_TOP: int = 8  # water rows 8-13, floor at row 14


func _tables() -> WarioTables:
	var walk: Array = []
	for i: int in 0x1C:
		walk.append(1)
	var normal: Array = []
	for i: int in 0x28:
		normal.append(-3 if i < 12 else 2)
	var swim: Array = []
	for i: int in 40:
		swim.append(2 if i < 20 else 1)
	var framesets: Dictionary = {}
	for key: String in ["55a0", "55a3", "5569", "5573", "5576", "558b", "5554", "555b", "5562", "556c", "55be", "55c5",
			"55b0", "55b7", "425f", "4252", "5900", "58fd"]:
		framesets[key] = {"pairs": [[0, 3]]}
	return WarioTables.from_document({"walk_vel_table": {"steps": walk},
			"jump_vel_tables": [{"id": 1, "steps": normal}, {"id": 2, "steps": normal}],
			"swim_vel_tables": {"straight": {"steps": swim}, "vertical": {"steps": swim}, "diagonal": {"steps": swim}},
			"framesets": framesets})


func _sim(x: int, y: int, extra: Array = []) -> WarioSim:
	var rows: Array = []
	for row: int in LevelCollision.HEIGHT:
		var block: int = SOLID if row == 14 else (WATER if row >= POOL_TOP else FREE)
		var data := PackedByteArray()
		data.resize(LevelCollision.WIDTH)
		data.fill(block)
		rows.append(data.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[SOLID] = "h06_4032"
	handlers[WATER] = "h06_41ac"
	handlers[RIGHT_CURRENT] = "h06_41c8"
	var sim := WarioSim.new()
	sim.tables = _tables()
	sim.level = LevelCollision.from_document({"block_rows": rows, "rooms": [{"level_room_id": 0, "handlers": handlers}]})
	for cell: Array in extra:
		sim.level.set_block(cell[0], cell[1], cell[2])
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


func test_falling_into_water_dives_then_floats_up_to_the_surface_without_flippers() -> void:
	var sim: WarioSim = _sim(80, POOL_TOP * 16 + 8)
	sim.start_fall()
	var states: Array = []
	for frame: int in 160:
		_frame(sim, 0)
		if states.is_empty() or states[-1] != sim.wWarioState:
			states.append(sim.wWarioState)
	assert_eq(states.slice(0, 4), [WarioRam.WST_DIVING, WarioRam.WST_SUBMERGED, WarioRam.WST_WATER_SURFACE_IDLING],
			"no flippers: Wario floats back up")
	assert_eq(sim.wWaterInteraction, WarioRam.SUBMERSIBLE_WATER)


func test_at_the_surface_he_bobs_and_down_only_tries_to_submerge() -> void:
	var sim: WarioSim = _sim(80, POOL_TOP * 16 + 4)
	sim.wWaterInteraction = WarioRam.SUBMERSIBLE_WATER
	sim.set_state_water_surface_idling()
	var ys: Array = []
	for frame: int in 48:
		_frame(sim, 0)
		ys.append(sim.wWarioYPos)
	assert_eq([ys.min(), ys.max()], [POOL_TOP * 16 + 4, POOL_TOP * 16 + 4 + 6], "six pixels down, then back up")
	_frame(sim, WarioRam.PAD_DOWN)
	assert_eq(sim.wWarioState, WarioRam.WST_TRYING_SUBMERGE)
	_frame(sim, 0, WarioRam.PAD_DOWN)
	assert_eq(sim.wWarioState, WarioRam.WST_WATER_SURFACE_IDLING)


func test_with_the_flippers_b_thrusts_along_the_speed_table_until_released() -> void:
	var sim: WarioSim = _sim(80, (POOL_TOP + 3) * 16)
	sim.wPowerUpLevel = WarioRam.SWIMMING_FLIPPERS
	sim.wWaterInteraction = WarioRam.SUBMERSIBLE_WATER
	sim.set_state_submerged()
	assert_eq(sim.wCollisionBoxTop, WarioRam.byte(-15), "a swimmer's box")
	_frame(sim, WarioRam.PAD_B)
	assert_eq(sim.wWarioState, WarioRam.WST_UNDERWATER_THRUSTING)
	var x: int = sim.wWarioXPos
	for frame: int in 5:
		_frame(sim, WarioRam.PAD_B, WarioRam.PAD_B)
	assert_eq(sim.wWarioXPos - x, 2 * 5, "2 px a frame early in the thrust")
	_frame(sim, 0, WarioRam.PAD_B)
	assert_eq(sim.wWarioState, WarioRam.WST_SUBMERGED)


func test_a_current_pushes_2_px_a_frame_and_lingers_after() -> void:
	var sim: WarioSim = _sim(80, (POOL_TOP + 3) * 16, [[POOL_TOP + 2, 5, RIGHT_CURRENT]])
	sim.wWaterInteraction = WarioRam.SUBMERSIBLE_WATER
	sim.wWaterCurrent = WarioRam.CURRENT_RIGHT
	sim.apply_water_current_movement()
	assert_eq([sim.wWarioXPos, sim.wCurWaterCurrent], [82, WarioRam.CURRENT_RIGHT])
	sim.apply_water_current_movement()
	assert_eq([sim.wLastWaterCurrent, sim.wCurWaterCurrent], [(15 << 4) | WarioRam.CURRENT_RIGHT, 0],
			"no current this frame: the last lingers 15 frames")
	var x: int = sim.wWarioXPos
	sim.apply_water_current_movement()
	assert_eq([sim.wWarioXPos - x, sim.wLastWaterCurrent >> 4], [1, 14])
