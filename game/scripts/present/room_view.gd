class_name RoomView
extends Node2D
## Draws the collision grid and player box with flat colours. Presentation only:
## it reads simulation state and never changes it.

const SKY: Color = Color("#9cc8e8")
const SOLID: Color = Color("#5a4632")
const PLATFORM: Color = Color("#c8a050")
const PLAYER: Color = Color("#e8d020")
const OUTLINE: Color = Color("#202020")

var _grid: CollisionGrid
var _player: Rect2i = Rect2i()
var _facing: int = 1

@onready var _camera: Camera2D = $Camera


func show_room(grid: CollisionGrid) -> void:
	_grid = grid
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = grid.width * grid.tile_size_px
	_camera.limit_bottom = grid.height * grid.tile_size_px
	queue_redraw()


func show_player(state: PlayerState, params: MovementParams) -> void:
	var spp: int = params.subpixels_per_pixel
	_player = Rect2i(PlayerSim.floor_div(state.x, spp), PlayerSim.floor_div(state.y, spp),
			params.body_width_px, params.body_height_px)
	_facing = state.facing
	_camera.position = Vector2(_player.get_center())
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var size: int = _grid.tile_size_px
	draw_rect(Rect2(0, 0, _grid.width * size, _grid.height * size), SKY)
	for ty: int in _grid.height:
		for tx: int in _grid.width:
			match _grid.material_at(tx, ty):
				CollisionGrid.TileMaterial.SOLID:
					draw_rect(Rect2(tx * size, ty * size, size, size), SOLID)
				CollisionGrid.TileMaterial.PLATFORM:
					draw_rect(Rect2(tx * size, ty * size, size, 4), PLATFORM)
	draw_rect(Rect2(_player), PLAYER)
	draw_rect(Rect2(_player), OUTLINE, false, 1.0)
	var eye_x: int = _player.position.x + (_player.size.x - 4 if _facing > 0 else 2)
	draw_rect(Rect2(eye_x, _player.position.y + 4, 2, 2), OUTLINE)
