extends TestCase
## Prototype movement and collision. These pin the scaffolding's own rules; they are
## not evidence about Wario Land 3 behaviour.

const LEGEND: Dictionary = {".": "empty", "#": "solid", "=": "platform"}


func _params() -> MovementParams:
	var p := MovementParams.new()
	p.subpixels_per_pixel = 16
	p.walk_accel = 2
	p.walk_decel = 4
	p.walk_max = 16
	p.gravity = 4
	p.jump_velocity = -72
	p.max_fall = 64
	p.body_width_px = 12
	p.body_height_px = 24
	return p


func _grid(rows: Array) -> CollisionGrid:
	return CollisionGrid.from_rows(PackedStringArray(rows), LEGEND, 16)


func _state(x_px: int, y_px: int) -> PlayerState:
	var s := PlayerState.new()
	s.x = x_px * 16
	s.y = y_px * 16
	return s


## A spawned body is not `on_ground` until one tick has resolved the floor contact.
func _settled(x_px: int, y_px: int, grid: CollisionGrid, p: MovementParams) -> PlayerState:
	var s := _state(x_px, y_px)
	PlayerSim.step(s, 0, grid, p)
	return s


func _run(state: PlayerState, grid: CollisionGrid, p: MovementParams, held: int, ticks: int) -> void:
	for i: int in ticks:
		PlayerSim.step(state, held, grid, p)


func test_floor_div_rounds_down() -> void:
	assert_eq(PlayerSim.floor_div(15, 16), 0)
	assert_eq(PlayerSim.floor_div(-1, 16), -1)
	assert_eq(PlayerSim.floor_div(-16, 16), -1)
	assert_eq(PlayerSim.floor_div(-17, 16), -2)


func test_standing_on_floor_is_stable() -> void:
	var grid := _grid(["....", "....", "....", "####"])
	var s := _state(16, 24)
	_run(s, grid, _params(), 0, 30)
	assert_eq(s.y, 24 * 16, "y")
	assert_eq(s.vy, 0, "vy")
	assert_true(s.on_ground, "on ground")
	assert_eq(s.tick, 30, "tick")


func test_walk_reaches_max_speed_then_stops_at_wall() -> void:
	var grid := _grid(["#......#", "#......#", "#......#", "########"])
	var p := _params()
	var s := _state(16, 24)
	_run(s, grid, p, InputBits.RIGHT, 8)
	assert_eq(s.vx, 16, "vx after 8 ticks")
	_run(s, grid, p, InputBits.RIGHT, 200)
	assert_eq(s.x, (7 * 16 - 12) * 16, "x flush with wall")
	assert_eq(s.vx, 0, "vx when blocked")


func test_release_decelerates_to_rest() -> void:
	var grid := _grid(["................", "................", "................", "################"])
	var p := _params()
	var s := _state(16, 24)
	_run(s, grid, p, InputBits.RIGHT, 20)
	_run(s, grid, p, 0, 4)
	assert_eq(s.vx, 0, "vx after 4 ticks of decel")
	var x_at_rest: int = s.x
	_run(s, grid, p, 0, 10)
	assert_eq(s.x, x_at_rest, "no drift")


func test_jump_apex_landing_and_edge_trigger() -> void:
	var rows: Array = []
	for i: int in 9:
		rows.append("........")
	rows.append("########")
	var grid := _grid(rows)
	var p := _params()
	var s := _settled(40, 144 - 24, grid, p)
	var start_y: int = s.y
	var min_y: int = s.y
	var landed_tick: int = -1
	for t: int in 60:
		PlayerSim.step(s, InputBits.A, grid, p)  # A held throughout: only the first tick is a press
		min_y = mini(min_y, s.y)
		if t > 0 and s.on_ground and landed_tick < 0:
			landed_tick = t
	# Rise = sum of (72 - 4k) for k = 1..17 = 612 subpixels.
	assert_eq(start_y - min_y, 612, "apex rise")
	assert_true(landed_tick > 0 and landed_tick < 40, "landed within 40 ticks (got %d)" % landed_tick)
	assert_eq(s.y, start_y, "back on the floor")
	assert_true(s.on_ground, "no re-jump while A stays held")


func test_head_bumps_solid_ceiling() -> void:
	var grid := _grid(["########", "........", "........", "........", "########"])
	var s := _settled(40, 64 - 24, grid, _params())
	var min_y: int = s.y
	for t: int in 40:
		PlayerSim.step(s, InputBits.A if t == 0 else 0, grid, _params())
		min_y = mini(min_y, s.y)
	assert_eq(min_y, 16 * 16, "top stops at ceiling bottom")
	assert_true(s.on_ground, "falls back down")


func test_one_way_platform_passes_from_below_and_holds_from_above() -> void:
	var grid := _grid(["........", "........", "........", "..====..", "........", "########"])
	var s := _settled(40, 80 - 24, grid, _params())
	for t: int in 60:
		PlayerSim.step(s, InputBits.A if t == 0 else 0, grid, _params())
	assert_eq(s.y, (48 - 24) * 16, "standing on the platform")
	assert_true(s.on_ground, "on ground")


func test_out_of_room_is_solid() -> void:
	var grid := _grid(["....", "....", "...."])
	assert_eq(grid.material_at(-1, 0), CollisionGrid.TileMaterial.SOLID)
	assert_eq(grid.material_at(0, 3), CollisionGrid.TileMaterial.SOLID)
	assert_eq(grid.material_at(0, 0), CollisionGrid.TileMaterial.EMPTY)


func test_determinism_and_snapshot_resume() -> void:
	var grid := _grid(["#..........#", "#..........#", "#....##....#", "#..........#", "############"])
	var p := _params()
	var inputs: Array[int] = []
	for t: int in 120:
		inputs.append(InputBits.RIGHT | (InputBits.A if t % 37 == 0 else 0) if t < 80 else InputBits.LEFT)
	var a := _state(24, 40)
	var b := _state(24, 40)
	var snaps_a: Array = []
	var snaps_b: Array = []
	for held: int in inputs:
		PlayerSim.step(a, held, grid, p)
		snaps_a.append(a.snapshot())
	for held: int in inputs:
		PlayerSim.step(b, held, grid, p)
		snaps_b.append(b.snapshot())
	assert_eq(snaps_a, snaps_b, "identical runs")
	var resumed := PlayerState.from_snapshot(snaps_a[59])
	for i: int in range(60, inputs.size()):
		PlayerSim.step(resumed, inputs[i], grid, p)
	assert_eq(resumed.snapshot(), snaps_a[-1], "resume from snapshot")


func test_clock_runs_at_lcd_rate_not_60hz() -> void:
	var clock := SimClock.new()
	var ticks: int = 0
	for frame: int in 6000:  # 100 seconds of 60 Hz rendering
		ticks += clock.advance(1.0 / 60.0)
	assert_true(ticks >= 5972 and ticks <= 5973, "expected ~5972.75 ticks in 100 s, got %d" % ticks)
	assert_eq(SimClock.new().advance(10.0), SimClock.MAX_TICKS_PER_FRAME, "catch-up is bounded")
