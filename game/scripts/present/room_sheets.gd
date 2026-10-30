class_name RoomSheets
extends RefCounted
## A room's block sheets built from its decoded graphics (rooms/room-NNN.gfx.json, from
## tools/wl3pc/extract/room_gfx.py) as the room's animation leaves VRAM and the BG palettes: VRAM
## bank 1's tiles $70-$77 from an animated-tiles frame, the palettes from a RoomPals entry
## (rooms/animation.json). The layout is room-NNN-blocks.png's: 128 blocks of 16 x 16, 16 a row.
## The priority sheet keeps only the pixels drawn over sprites. Presentation only.

const BLOCKS: int = 0x80
const TILE_BYTES: int = 16
const TILES_PER_SET: int = 0x80
const ANIMATED_TILES_FIRST: int = 0x70
const ANIMATED_TILES: int = 8
const TILE_POSITIONS: Array = [[0, 0], [1, 0], [0, 1], [1, 1]]
const MISSING := Color8(255, 0, 255)

var _block_tiles: PackedByteArray
var _attributes: PackedByteArray
var _main: PackedByteArray
var _special: PackedByteArray
var _palettes: Array  # 8 palettes of 4 Colors
var _animation: Dictionary
var _cache: Dictionary = {}


static func load_file(path: String, animation: Dictionary) -> RoomSheets:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return null
	return from_document(parsed, animation)


static func from_document(document: Dictionary, animation: Dictionary) -> RoomSheets:
	var sheets := RoomSheets.new()
	sheets._block_tiles = String(document["block_tiles"]).hex_decode()
	sheets._attributes = String(document["block_attributes"]).hex_decode()
	sheets._main = String(document["main_tiles"]).hex_decode()
	sheets._special = String(document["special_tiles"]).hex_decode()
	sheets._palettes = _colours(document["palettes"])
	sheets._animation = animation
	return sheets


static func _colours(palettes: Array) -> Array:
	var out: Array = []
	for palette: Array in palettes:
		var row: Array = []
		for rgb: Array in palette:
			row.append(Color8((int(rgb[0]) << 3) | (int(rgb[0]) >> 2), (int(rgb[1]) << 3) | (int(rgb[1]) >> 2),
					(int(rgb[2]) << 3) | (int(rgb[2]) >> 2)))
		out.append(row)
	return out


## The blocks (or, with `priority`, only their pixels over sprites) with animated-tiles graphics
## `gfx` at `frame` in tiles $70-$77 (-1: the room's own special tiles) and RoomPals entry
## `room_pals` as the palettes (-1: the room's own).
func sheet(gfx: int, frame: int, room_pals: int, priority: bool) -> Image:
	var key: String = "%d/%d/%d/%s" % [gfx, frame if gfx >= 0 else 0, room_pals, priority]
	if _cache.has(key):
		return _cache[key]
	var special: PackedByteArray = _special
	var frames: Dictionary = _animation.get("animated_tiles_gfx", {})
	if gfx >= 0 and frames.has(str(gfx)):
		special = _special.duplicate()
		var data: PackedByteArray = String(frames[str(gfx)]).hex_decode()
		var size: int = ANIMATED_TILES * TILE_BYTES
		for i: int in size:
			special[ANIMATED_TILES_FIRST * TILE_BYTES + i] = data[frame * size + i]
	var palettes: Array = _palettes
	var room_pal_table: Dictionary = _animation.get("room_pals", {})
	if room_pals >= 0 and room_pal_table.has(str(room_pals)):
		palettes = _colours(room_pal_table[str(room_pals)])
	var image := Image.create_empty(16 * 16, 8 * 16, false, Image.FORMAT_RGBA8)
	for block: int in BLOCKS:
		var bx: int = (block % 16) * 16
		var by: int = (block / 16) * 16
		for k: int in 4:
			var number: int = _block_tiles[4 * block + k]
			var attribute: int = _attributes[4 * block + k]
			var ox: int = bx + int(TILE_POSITIONS[k][0]) * 8
			var oy: int = by + int(TILE_POSITIONS[k][1]) * 8
			if number >= TILES_PER_SET:
				if not priority:
					image.fill_rect(Rect2i(ox, oy, 8, 8), MISSING)
				continue
			if priority and (attribute & 0x80) == 0:
				continue
			var tiles: PackedByteArray = special if ((attribute >> 3) & 1) != 0 else _main
			var palette: Array = palettes[attribute & 7]
			for y: int in 8:
				var sy: int = 7 - y if (attribute & 0x40) != 0 else y
				var low: int = tiles[number * TILE_BYTES + sy * 2]
				var high: int = tiles[number * TILE_BYTES + sy * 2 + 1]
				for x: int in 8:
					var sx: int = 7 - x if (attribute & 0x20) != 0 else x
					var index: int = ((high >> (7 - sx)) & 1) << 1 | ((low >> (7 - sx)) & 1)
					if priority and index == 0:
						continue
					image.set_pixel(ox + x, oy + y, palette[index])
	_cache[key] = image
	return image
