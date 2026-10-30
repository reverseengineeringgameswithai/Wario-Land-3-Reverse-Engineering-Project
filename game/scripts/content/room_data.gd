class_name RoomData
extends RefCounted
## A validated room (schemas/room.v1.schema.json). `rows` may be patched by mods;
## the loader copies base data before applying them.

var id: String = ""
var tile_size_px: int = 16
var legend: Dictionary = {}
var rows: PackedStringArray = PackedStringArray()


func width() -> int:
	return rows[0].length()


func height() -> int:
	return rows.size()


func build_grid() -> CollisionGrid:
	return CollisionGrid.from_rows(rows, legend, tile_size_px)


func to_dict() -> Dictionary:
	return {"id": id, "tile_size_px": tile_size_px, "legend": legend, "rows": Array(rows)}
