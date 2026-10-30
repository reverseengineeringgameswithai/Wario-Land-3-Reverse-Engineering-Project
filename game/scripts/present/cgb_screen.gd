class_name CgbScreen
extends RefCounted
## A screen drawn as the CGB's LCD draws it (golf, WL3-050; the level's clear screen, WL3-043), from
## a ScreenVram (tiles, BG maps, palettes), the OAM, and the registers: the BG map and the window by
## LCDC, BG attributes (palette, VRAM bank, flips, priority), 8x16 sprites from $8000 in OAM order
## with ten a line, and BG-over-OBJ priority. Colours are the palettes' 5-bit channels, as PyBoy
## draws them (c << 3). A line is built from tile rows, each kept as RGB and colour indices by its two
## bytes, palette, and flip. Writes made while the frame is drawn ([line, bank, address, bytes], in an
## H-Blank) show from the next line; with bank BG_PALETTE or OBJ_PALETTE they are a palette's 8 bytes
## (address: the palette).

const WIDTH: int = 160
const HEIGHT: int = 144
const BG_PALETTE: int = -1
const OBJ_PALETTE: int = -2

var _rows: Dictionary = {}  # key -> [RGB (24 bytes), colour indices (8 bytes)]
var _palettes: PackedByteArray = PackedByteArray()


static func colour(palettes: PackedByteArray, palette: int, index: int) -> int:
	var at: int = palette * 8 + index * 2
	if at + 1 >= palettes.size():
		return 0
	return palettes[at] | (palettes[at + 1] << 8)


## A BG tile row's RGB and indices.
func _bg_row(vram: ScreenVram, bank: int, address: int, row: int, palette: int, flip_x: bool) -> Array:
	var at: int = address - ScreenVram.VRAM_START + row * 2
	var low: int = vram.vram[bank][at]
	var high: int = vram.vram[bank][at + 1]
	var key: int = low | (high << 8) | (palette << 16) | ((1 if flip_x else 0) << 19)
	if _rows.has(key):
		return _rows[key]
	var rgb := PackedByteArray()
	rgb.resize(24)
	var indices := PackedByteArray()
	indices.resize(8)
	for column: int in 8:
		var bit: int = column if flip_x else 7 - column
		var index: int = (((high >> bit) & 1) << 1) | ((low >> bit) & 1)
		var value: int = colour(_palettes, palette, index)
		rgb[column * 3] = (value & 0x1F) << 3
		rgb[column * 3 + 1] = ((value >> 5) & 0x1F) << 3
		rgb[column * 3 + 2] = ((value >> 10) & 0x1F) << 3
		indices[column] = index
	_rows[key] = [rgb, indices]
	return _rows[key]


## One line of a BG map from map pixel (x, y), `width` pixels: RGB, and per pixel its colour index
## with the tile's priority as bit 2.
func _map_line(vram: ScreenVram, lcdc: int, map: int, x: int, y: int, width: int) -> Array:
	var rgb := PackedByteArray()
	var indices := PackedByteArray()
	var first: int = x >> 3
	for tile_column: int in (((x & 7) + width + 7) >> 3):
		var entry: int = map - ScreenVram.VRAM_START + ((y >> 3) & 31) * 32 + ((first + tile_column) & 31)
		var tile: int = vram.vram[0][entry]
		var attributes: int = vram.vram[1][entry]
		var address: int = 0x8000 + tile * 16 if (lcdc & 0x10) != 0 else 0x9000 + (tile - 256 if tile >= 128 else tile) * 16
		var row: int = 7 - (y & 7) if (attributes & 0x40) != 0 else y & 7
		var cached: Array = _bg_row(vram, (attributes >> 3) & 1, address, row, attributes & 7, (attributes & 0x20) != 0)
		rgb.append_array(cached[0])
		var tile_indices: PackedByteArray = cached[1]
		if (attributes & 0x80) != 0:
			tile_indices = tile_indices.duplicate()
			for column: int in 8:
				tile_indices[column] |= 4
		indices.append_array(tile_indices)
	var skip: int = x & 7
	return [rgb.slice(skip * 3, (skip + width) * 3), indices.slice(skip, skip + width)]


## RGB bytes (160x144) of one frame; `line_writes` are applied to `vram` as the lines pass, and
## `scx_lines` and `scy_lines` ([first line, scroll], in order) change the horizontal or vertical
## scroll from their lines on (rSCX or rSCY written mid-frame).
func render(vram: ScreenVram, oam: PackedByteArray, lcdc: int, scx: int, scy: int, wx: int, wy: int,
		line_writes: Array = [], scx_lines: Array = [], scy_lines: Array = []) -> PackedByteArray:
	if _palettes != vram.bg_palettes:
		_palettes = vram.bg_palettes.duplicate()  # packed arrays are shared: a copy to compare with
		_rows.clear()
	var pixels := PackedByteArray()
	var tall: bool = (lcdc & 0x04) != 0
	var height: int = 16 if tall else 8
	var window_x: int = wx - 7
	var bg_map: int = ScreenVram.BG_MAP_1 if (lcdc & 0x08) != 0 else ScreenVram.BG_MAP_0
	var window_map: int = ScreenVram.BG_MAP_1 if (lcdc & 0x40) != 0 else ScreenVram.BG_MAP_0
	var next_write: int = 0
	var next_scx: int = 0
	var next_scy: int = 0
	for y: int in HEIGHT:
		while next_scx < scx_lines.size() and int(scx_lines[next_scx][0]) <= y:
			scx = int(scx_lines[next_scx][1])
			next_scx += 1
		while next_scy < scy_lines.size() and int(scy_lines[next_scy][0]) <= y:
			scy = int(scy_lines[next_scy][1])
			next_scy += 1
		while next_write < line_writes.size() and int(line_writes[next_write][0]) < y:
			var change: Array = line_writes[next_write]
			match int(change[1]):
				BG_PALETTE:
					_write_palette(vram.bg_palettes, int(change[2]), change[3])
					_palettes = vram.bg_palettes.duplicate()
					_rows.clear()
				OBJ_PALETTE:
					_write_palette(vram.obj_palettes, int(change[2]), change[3])
				_:
					vram.write(int(change[1]), int(change[2]), change[3])
			next_write += 1
		var window: bool = (lcdc & 0x20) != 0 and y >= wy and window_x < WIDTH
		var bg_width: int = clampi(window_x, 0, WIDTH) if window else WIDTH
		var line: PackedByteArray = PackedByteArray()
		var indices: PackedByteArray = PackedByteArray()
		if bg_width > 0:
			var part: Array = _map_line(vram, lcdc, bg_map, scx & 0xFF, (y + scy) & 0xFF, bg_width)
			line = part[0]
			indices = part[1]
		if window:
			var part: Array = _map_line(vram, lcdc, window_map, bg_width - window_x, y - wy, WIDTH - bg_width)
			line.append_array(part[0])
			indices.append_array(part[1])
		_draw_sprites(vram, oam, lcdc, y, height, tall, line, indices)
		pixels.append_array(line)
	return pixels


static func _write_palette(palettes: PackedByteArray, palette: int, bytes: PackedByteArray) -> void:
	for at: int in bytes.size():
		palettes[palette * 8 + at] = bytes[at]


## The line's sprites: the first ten in OAM order that cover it, the earliest drawn on top; behind
## BG colours 1-3 when the BG tile or the sprite asks for it (LCDC bit 0 set).
func _draw_sprites(vram: ScreenVram, oam: PackedByteArray, lcdc: int, y: int, height: int, tall: bool,
		line: PackedByteArray, indices: PackedByteArray) -> void:
	var on_line: Array[int] = []
	for sprite: int in 40:
		var top: int = oam[sprite * 4] - 16
		if y >= top and y < top + height:
			on_line.append(sprite)
			if on_line.size() == 10:
				break
	if on_line.is_empty():
		return
	var drawn := PackedByteArray()
	drawn.resize(WIDTH)
	for sprite: int in on_line:
		var top: int = oam[sprite * 4] - 16
		var left: int = oam[sprite * 4 + 1] - 8
		var tile: int = oam[sprite * 4 + 2]
		var attributes: int = oam[sprite * 4 + 3]
		if tall:
			tile &= 0xFE
		var row: int = y - top
		if (attributes & 0x40) != 0:
			row = height - 1 - row
		var at: int = tile * 16 + row * 2
		var bank: PackedByteArray = vram.vram[(attributes >> 3) & 1]
		var low: int = bank[at]
		var high: int = bank[at + 1]
		for column: int in 8:
			var x: int = left + column
			if x < 0 or x >= WIDTH or drawn[x] != 0:
				continue
			var bit: int = column if (attributes & 0x20) != 0 else 7 - column
			var index: int = (((high >> bit) & 1) << 1) | ((low >> bit) & 1)
			if index == 0:
				continue
			drawn[x] = 1
			if (lcdc & 0x01) != 0 and (indices[x] & 3) != 0 and ((indices[x] & 4) != 0 or (attributes & 0x80) != 0):
				continue
			var value: int = colour(vram.obj_palettes, attributes & 7, index)
			line[x * 3] = (value & 0x1F) << 3
			line[x * 3 + 1] = ((value >> 5) & 0x1F) << 3
			line[x * 3 + 2] = ((value >> 10) & 0x1F) << 3
