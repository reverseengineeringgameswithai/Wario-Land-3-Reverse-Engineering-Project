class_name CollisionGrid
extends RefCounted
## Tile materials for one room in engine coordinates (x right, y down).
## Runtime material IDs are stable names, never original ROM handler pointers.

enum TileMaterial { EMPTY, SOLID, PLATFORM }

const MATERIAL_IDS: Dictionary = {"empty": TileMaterial.EMPTY, "solid": TileMaterial.SOLID, "platform": TileMaterial.PLATFORM}

var width: int = 0
var height: int = 0
var tile_size_px: int = 16
var _tiles: PackedByteArray = PackedByteArray()


static func from_rows(rows: PackedStringArray, legend: Dictionary, tile_px: int) -> CollisionGrid:
	var grid := CollisionGrid.new()
	grid.height = rows.size()
	grid.width = rows[0].length() if rows.size() > 0 else 0
	grid.tile_size_px = tile_px
	grid._tiles.resize(grid.width * grid.height)
	for y: int in grid.height:
		var row: String = rows[y]
		for x: int in grid.width:
			grid._tiles[y * grid.width + x] = int(MATERIAL_IDS[legend[row[x]]])
	return grid


## Out-of-room tiles are solid so the body cannot leave the room (provisional rule).
func material_at(tx: int, ty: int) -> int:
	if tx < 0 or ty < 0 or tx >= width or ty >= height:
		return TileMaterial.SOLID
	return _tiles[ty * width + tx]
