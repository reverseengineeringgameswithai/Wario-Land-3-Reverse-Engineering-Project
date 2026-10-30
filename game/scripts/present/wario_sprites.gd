class_name WarioSprites
extends RefCounted
## Wario's decoded sprite graphics (wario_sprites.json from tools/wl3pc/extract/wario_sprites.py):
## tile sets, OAM tables, and palettes, keyed "BB:AAAA" as the game names them. Builds the images
## LevelView draws: a tile set's 64 8x16 tile pairs in one palette, flipped as OAM attributes ask.
## Presentation only.

const TILE_BYTES: int = 16
const PAIRS_PER_ROW: int = 16
const OBJ_PALETTES: int = 2  # StartRoom and SetWarioPal load OBJ palettes 0 and 1
const ATTR_X_FLIP: int = 0x20
const ATTR_Y_FLIP: int = 0x40
const ATTR_PRIORITY: int = 0x80

var tile_sets: Dictionary = {}  # key -> PackedByteArray of 128 tiles
var oam_tables: Dictionary = {}  # key -> Array of frames, each an Array of [y, x, tile, attributes]
var palettes: Dictionary = {}  # key -> Array of 2 palettes of 4 Colors
var _sheets: Dictionary = {}


static func load_file(path: String) -> WarioSprites:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("WarioSprites: cannot read %s" % path)
		return null
	return from_document(parsed)


static func from_document(document: Dictionary) -> WarioSprites:
	var sprites := WarioSprites.new()
	for key: String in document.get("tile_sets", {}):
		sprites.tile_sets[key] = String(document["tile_sets"][key]["tiles"]).hex_decode()
	for key: String in document.get("oam_tables", {}):
		sprites.oam_tables[key] = document["oam_tables"][key]["frames"]
	for key: String in document.get("palettes", {}):
		var colours: Array = []
		for palette: Array in document["palettes"][key]["colours"]:
			var row: Array[Color] = []
			for rgb: Array in palette:
				row.append(Color8(_to_8bit(int(rgb[0])), _to_8bit(int(rgb[1])), _to_8bit(int(rgb[2]))))
			colours.append(row)
		sprites.palettes[key] = colours
	return sprites


## Whether the frame DrawWario recorded (LevelSim.drawn_wario) can be drawn from this data.
func can_draw(drawn: Dictionary) -> bool:
	return (tile_sets.has(drawn.get("tile_set", "")) and palettes.has(drawn.get("palettes", ""))
			and oam_tables.has(drawn.get("oam_table", ""))
			and int(drawn.get("frame", 0)) < (oam_tables[drawn["oam_table"]] as Array).size())


## The OAM entries LoadSprite writes for a recorded frame, in OAM order: [OAM y, OAM x, tile,
## attributes], positions wrapped to a byte as the hardware holds them.
func entries(drawn: Dictionary) -> Array:
	var out: Array = []
	for entry: Array in oam_tables[drawn["oam_table"]][int(drawn["frame"])]:
		out.append([(int(entry[0]) + int(drawn["screen_y"])) & 0xFF, (int(entry[1]) + int(drawn["screen_x"])) & 0xFF,
				int(entry[2]), int(entry[3]) ^ int(drawn["attributes"])])
	return out


## The 64 tile pairs of a tile set (8x16 sprites: the even tile on top), PAIRS_PER_ROW a row, in
## OBJ palette `obj_palette` of `palette_key`, each pair flipped in place by the flip bits of
## `attributes`. Colour 0 is transparent.
func pair_sheet(tile_set: String, palette_key: String, obj_palette: int, attributes: int) -> Image:
	var flips: int = attributes & (ATTR_X_FLIP | ATTR_Y_FLIP)
	var key: String = "%s/%s/%d/%d" % [tile_set, palette_key, obj_palette, flips]
	if _sheets.has(key):
		return _sheets[key]
	var tiles: PackedByteArray = tile_sets[tile_set]
	var colours: Array = palettes[palette_key][obj_palette]
	var pairs: int = tiles.size() / (2 * TILE_BYTES)
	var image := Image.create_empty(PAIRS_PER_ROW * 8, ceili(float(pairs) / PAIRS_PER_ROW) * 16, false, Image.FORMAT_RGBA8)
	for pair: int in pairs:
		var ox: int = (pair % PAIRS_PER_ROW) * 8
		var oy: int = (pair / PAIRS_PER_ROW) * 16
		for y: int in 16:
			var sy: int = 15 - y if (flips & ATTR_Y_FLIP) != 0 else y
			var row: int = (2 * pair + sy / 8) * TILE_BYTES + (sy % 8) * 2
			var low: int = tiles[row]
			var high: int = tiles[row + 1]
			for x: int in 8:
				var sx: int = 7 - x if (flips & ATTR_X_FLIP) != 0 else x
				var index: int = ((high >> (7 - sx)) & 1) << 1 | ((low >> (7 - sx)) & 1)
				if index != 0:
					image.set_pixel(ox + x, oy + y, colours[index])
	_sheets[key] = image
	return image


## Where a tile pair sits in pair_sheet's image.
static func pair_rect(tile: int) -> Rect2i:
	var pair: int = tile >> 1
	return Rect2i((pair % PAIRS_PER_ROW) * 8, (pair / PAIRS_PER_ROW) * 16, 8, 16)


static func _to_8bit(c: int) -> int:
	return (c << 3) | (c >> 2)
