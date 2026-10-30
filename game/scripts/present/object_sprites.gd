class_name ObjectSprites
extends RefCounted
## The objects' decoded sprite graphics (objects.json's object_groups, from
## tools/wl3pc/extract/objects.py): their OAM tables, each object group's VRAM bank 1 image and OBJ
## palettes 4-7, the common objects' palette (3), and the common graphics at $8800 in VRAM bank 0.
## Builds the 8x16 tile-pair images LevelView draws objects from. Presentation only.

const TILE_BYTES: int = 16
const PAIRS_PER_ROW: int = 16

var oam_tables: Dictionary = {}  # "BB:AAAA" -> Array of frames, each an Array of [y, x, tile, attributes]
var groups: Array = []  # {"vram1": PackedByteArray, "palettes": Array of 4 palettes, "common_palette": palette}
var common_gfx: PackedByteArray = PackedByteArray()  # tiles $80-$ff of VRAM bank 0
var particle_palette: Array = []  # OBJ palette 2
var _sheets: Dictionary = {}


static func from_document(document: Dictionary) -> ObjectSprites:
	var sprites := ObjectSprites.new()
	var source: Dictionary = document.get("object_groups", {})
	for key: String in source.get("oam_tables", {}):
		var table: Variant = source["oam_tables"][key]
		if table is Array:
			sprites.oam_tables[key] = table
	for group: Dictionary in source.get("groups", []):
		var palettes: Array = []
		for palette: Array in group.get("palettes", []):
			palettes.append(_colours(palette))
		sprites.groups.append({"vram1": String(group.get("enemy_vram", "")).hex_decode(), "palettes": palettes,
				"common_palette": _colours(group.get("common_palette", []))})
	sprites.common_gfx = String(source.get("common_gfx", "")).hex_decode()
	var particles: Dictionary = document.get("particles", {})
	for key: String in particles.get("oam_tables", {}):
		sprites.oam_tables["%s:%s" % [particles.get("bank", "03"), key]] = particles["oam_tables"][key]
	sprites.particle_palette = _colours(particles.get("palette", []))
	return sprites


static func _colours(palette: Array) -> Array:
	var row: Array = []
	for rgb: Array in palette:
		row.append(Color8((int(rgb[0]) << 3) | (int(rgb[0]) >> 2), (int(rgb[1]) << 3) | (int(rgb[1]) >> 2),
				(int(rgb[2]) << 3) | (int(rgb[2]) >> 2)))
	return row


func can_draw(drawn: Dictionary) -> bool:
	return (oam_tables.has(drawn.get("oam_table", ""))
			and int(drawn.get("frame", 0)) < (oam_tables[drawn["oam_table"]] as Array).size())


## UpdateObjSprite's OAM entries: the frame's (y, x, tile, attributes) plus the screen position, as bytes.
func entries(drawn: Dictionary) -> Array:
	var out: Array = []
	for entry: Array in oam_tables[drawn["oam_table"]][int(drawn["frame"])]:
		out.append([(int(entry[0]) + int(drawn["screen_y"])) & 0xFF, (int(entry[1]) + int(drawn["screen_x"])) & 0xFF,
				int(entry[2]), int(entry[3])])
	return out


## The colours of OBJ palette `obj_palette` for an object group, or [] where this data has none
## (0-1 are Wario's, 2 the particles').
func palette(group: int, obj_palette: int) -> Array:
	if group >= groups.size():
		return []
	if obj_palette == 3:
		return groups[group]["common_palette"]
	if obj_palette >= 4:
		return groups[group]["palettes"][obj_palette - 4]
	return []


## The tile pairs a VRAM bank holds for an object group, in `colours`, flipped by `attributes`:
## bank 1 is the group's enemy graphics; bank 0's tiles from $80 are the common graphics.
func pair_sheet(group: int, vram_bank: int, colours: Array, obj_palette: int, attributes: int) -> Image:
	var flips: int = attributes & 0x60
	var key: String = "%d/%d/%d/%d" % [group, vram_bank, obj_palette, flips]
	if _sheets.has(key):
		return _sheets[key]
	var tiles := PackedByteArray()
	if vram_bank == 1:
		tiles = groups[group]["vram1"]
	else:
		tiles.resize(0x80 * TILE_BYTES)  # tiles $00-$7f are Wario's, not drawn from here
		tiles.append_array(common_gfx)
	_sheets[key] = _pairs_image(tiles, colours, flips)
	return _sheets[key]


## VRAM bank 0 as particles see it: Wario's tile set (`wario_tiles`, named `tile_set`) in tiles
## $00-$7f and the common graphics from $80.
func bank0_sheet(tile_set: String, wario_tiles: PackedByteArray, colours: Array, palette_key: String,
		attributes: int) -> Image:
	var flips: int = attributes & 0x60
	var key: String = "bank0/%s/%s/%d" % [tile_set, palette_key, flips]
	if _sheets.has(key):
		return _sheets[key]
	var tiles: PackedByteArray = wario_tiles.duplicate()
	tiles.resize(0x80 * TILE_BYTES)
	tiles.append_array(common_gfx)
	_sheets[key] = _pairs_image(tiles, colours, flips)
	return _sheets[key]


func _pairs_image(tiles: PackedByteArray, colours: Array, flips: int) -> Image:
	var pairs: int = tiles.size() / (2 * TILE_BYTES)
	var image := Image.create_empty(PAIRS_PER_ROW * 8, ceili(float(pairs) / PAIRS_PER_ROW) * 16, false, Image.FORMAT_RGBA8)
	for pair: int in pairs:
		var ox: int = (pair % PAIRS_PER_ROW) * 8
		var oy: int = (pair / PAIRS_PER_ROW) * 16
		for y: int in 16:
			var sy: int = 15 - y if (flips & 0x40) != 0 else y
			var row: int = (2 * pair + sy / 8) * TILE_BYTES + (sy % 8) * 2
			var low: int = tiles[row]
			var high: int = tiles[row + 1]
			for x: int in 8:
				var sx: int = 7 - x if (flips & 0x20) != 0 else x
				var index: int = ((high >> (7 - sx)) & 1) << 1 | ((low >> (7 - sx)) & 1)
				if index != 0:
					image.set_pixel(ox + x, oy + y, colours[index])
	return image
