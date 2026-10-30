class_name PlayerSim
extends RefCounted
## PROTOTYPE movement: walk, gravity, jump, and axis-separated tile collision.
##
## This is scaffolding that proves the deterministic tick/collision pipeline.
## It is NOT Wario Land 3 behaviour: the original uses per-frame velocity tables
## (WalkVelTable, JumpVelTable_*) whose decoding is task WL3-012. All arithmetic
## is integer so a given input trace always yields identical state.


static func floor_div(a: int, b: int) -> int:
	var q: int = a / b
	if a % b != 0 and ((a < 0) != (b < 0)):
		q -= 1
	return q


static func step(state: PlayerState, held: int, grid: CollisionGrid, p: MovementParams) -> void:
	var pressed: int = held & ~state.prev_held
	var direction: int = 0
	if (held & InputBits.RIGHT) != 0:
		direction += 1
	if (held & InputBits.LEFT) != 0:
		direction -= 1
	if direction != 0:
		state.facing = direction
		state.vx = clampi(state.vx + direction * p.walk_accel, -p.walk_max, p.walk_max)
	elif state.vx > 0:
		state.vx = maxi(0, state.vx - p.walk_decel)
	elif state.vx < 0:
		state.vx = mini(0, state.vx + p.walk_decel)

	if (pressed & InputBits.A) != 0 and state.on_ground:
		state.vy = p.jump_velocity
		state.on_ground = false
	state.vy = mini(state.vy + p.gravity, p.max_fall)

	_move_x(state, grid, p)
	_move_y(state, grid, p)
	state.prev_held = held
	state.tick += 1


static func _tile_sub(grid: CollisionGrid, p: MovementParams) -> int:
	return grid.tile_size_px * p.subpixels_per_pixel


static func _move_x(s: PlayerState, grid: CollisionGrid, p: MovementParams) -> void:
	var tile: int = _tile_sub(grid, p)
	var w: int = p.body_width_px * p.subpixels_per_pixel
	var h: int = p.body_height_px * p.subpixels_per_pixel
	var limit: int = maxi(1, tile / 2)  # sub-steps prevent tunnelling through one tile
	var remaining: int = s.vx
	while remaining != 0:
		var delta: int = clampi(remaining, -limit, limit)
		remaining -= delta
		var nx: int = s.x + delta
		var top: int = floor_div(s.y, tile)
		var bottom: int = floor_div(s.y + h - 1, tile)
		var column: int = floor_div(nx + w - 1, tile) if delta > 0 else floor_div(nx, tile)
		if _column_solid(grid, column, top, bottom):
			s.x = column * tile - w if delta > 0 else (column + 1) * tile
			s.vx = 0
			return
		s.x = nx


static func _move_y(s: PlayerState, grid: CollisionGrid, p: MovementParams) -> void:
	var tile: int = _tile_sub(grid, p)
	var w: int = p.body_width_px * p.subpixels_per_pixel
	var h: int = p.body_height_px * p.subpixels_per_pixel
	var limit: int = maxi(1, tile / 2)
	var remaining: int = s.vy
	var landed: bool = false
	while remaining != 0:
		var delta: int = clampi(remaining, -limit, limit)
		remaining -= delta
		var ny: int = s.y + delta
		var left: int = floor_div(s.x, tile)
		var right: int = floor_div(s.x + w - 1, tile)
		if delta > 0:
			var row: int = floor_div(ny + h - 1, tile)
			var row_top: int = row * tile
			# One-way platforms only catch a body whose feet were at or above the tile top.
			if _row_blocks_down(grid, row, left, right, s.y + h <= row_top):
				s.y = row_top - h
				s.vy = 0
				landed = true
				break
		else:
			var row_up: int = floor_div(ny, tile)
			if _row_solid(grid, row_up, left, right):
				s.y = (row_up + 1) * tile
				s.vy = 0
				break
		s.y = ny
	s.on_ground = landed


static func _column_solid(grid: CollisionGrid, column: int, top: int, bottom: int) -> bool:
	for ty: int in range(top, bottom + 1):
		if grid.material_at(column, ty) == CollisionGrid.TileMaterial.SOLID:
			return true
	return false


static func _row_solid(grid: CollisionGrid, row: int, left: int, right: int) -> bool:
	for tx: int in range(left, right + 1):
		if grid.material_at(tx, row) == CollisionGrid.TileMaterial.SOLID:
			return true
	return false


static func _row_blocks_down(grid: CollisionGrid, row: int, left: int, right: int, allow_platform: bool) -> bool:
	for tx: int in range(left, right + 1):
		var material: int = grid.material_at(tx, row)
		if material == CollisionGrid.TileMaterial.SOLID:
			return true
		if allow_platform and material == CollisionGrid.TileMaterial.PLATFORM:
			return true
	return false
