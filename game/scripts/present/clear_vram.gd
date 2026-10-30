class_name ClearVram
extends ScreenVram
## What the level's clear screens put in VRAM (WL3-043): InitClearScreen's treasure screen
## (LoadClearScreenGfx, LoadLevelTreasureData's treasure tiles, the maps, the coins, the treasures
## found), InitTimeAttackClearScreen's (the best and the level's times), InitMusicalCoinScreen's coin
## chart (the levels with all eight coins coloured, Func_d47f1), and after each loop its V-Blank
## function's writes (the treasure screen's turning tile rows, the coin screen's queued entry) and
## the room animation's tiles (the coin screen's set 15), from clear.json's graphics, golf RAM's
## like clear RAM, and the room animation's tile sets.

var tables: Dictionary = {}


func _init(document: Dictionary = {}, animation: Dictionary = {}) -> void:
	super(document)
	tables = document.get("tables", {})
	animated_tiles = animation.get("animated_tiles_gfx", {})


## One loop: the screens its init loaded, its V-Blank function's writes, and the room animation's
## frame if one was written.
func update(clear: ClearSim, sim: LevelSim) -> void:
	for load: Array in clear.screen_loads:
		match String(load[0]):
			"treasure":
				load_treasure(clear, sim)
			"time_attack":
				load_time_attack(clear, sim)
			"musical_coins":
				load_musical_coins(clear)
	vblank(clear)
	room_animation(sim)


func _raw(key: String) -> PackedByteArray:
	return _bytes("raw", key)


## Clear Wario's tiles, the treasure screen's (bank 1 from $8000, bank 0 from $8800).
func _load_clear_screen_gfx() -> void:
	write(1, 0x8000, _bytes("compressed", "78:51e8"))
	write(0, 0x8800, _bytes("compressed", "78:4478"))
	write(0, 0x8000, _raw("0b:7000"))


## The level's four treasures (LevelTreasureIDs by wOWLevel, the Temple's first).
func _level_treasures(clear: ClearSim) -> Array[int]:
	var ids: PackedByteArray = _raw("00:198b")
	var level: int = clear.rx(2, 0xD00F)  # wOWLevel
	var found: Array[int] = []
	for index: int in 4:
		var at: int = level * 4 + index
		found.append(ids[at] if at < ids.size() else 0)
	return found


## InitClearScreen's drawing: the BG map cleared, the screen's palettes with the treasure's in OBJ
## palette 7, its tiles, the level's treasures' tiles at $8900 (LoadTreasureTiles: four tiles each,
## the blue's twice), its maps, the coins, and a mark under each treasure found.
func load_treasure(clear: ClearSim, sim: LevelSim) -> void:
	screen = "treasure"
	fill_bg_map_0(0xFF)
	bg_palettes = _bytes("palettes", "78:4378")
	obj_palettes = _bytes("palettes", "78:43b8")
	var treasures: Array[int] = _level_treasures(clear)
	var end: int = (sim.wLevelEndScreen & 0x7F) - 1
	if end >= 0 and end < 4:
		var palette_index: int = _raw("26:6bf7")[treasures[end]] if treasures[end] < 0x65 else 4
		var palette: PackedByteArray = _raw("26:6d65").slice((palette_index - 4) * 8, (palette_index - 4) * 8 + 8)
		for offset: int in palette.size():
			obj_palettes[56 + offset] = palette[offset]
	_load_clear_screen_gfx()
	var tiles := PackedByteArray()
	var gfx_bytes: PackedByteArray = _raw("26:4000")
	for treasure: int in treasures + [treasures[3]]:
		tiles.append_array(gfx_bytes.slice(treasure * 0x40, treasure * 0x40 + 0x40))
	write(0, 0x8900, tiles.slice(0, 0x100))
	write(1, BG_MAP_0, _bytes("compressed", "78:5962"))
	write(0, BG_MAP_0, _bytes("compressed", "78:57fa"))
	_print_digits(map_address(BG_MAP_0, 6, 16), [sim.wNumCoins >> 8 & 0x0F, (sim.wNumCoins >> 4) & 0x0F, sim.wNumCoins & 0x0F])
	var marks: Array = [[3, 0x54], [7, 0x54], [11, 0x5C], [15, 0x5C]]
	for colour: int in 4:
		if (sim.wKeyAndTreasureFlags & (0x10 << colour)) != 0:
			write_byte(0, map_address(BG_MAP_0, marks[colour][0], 8), marks[colour][1])
			write_byte(0, map_address(BG_MAP_0, marks[colour][0] + 1, 8), marks[colour][1] + 1)


## Digits as the clear screens print them: two tiles each, one above the other ($a0 + 2 * digit).
func _print_digits(address: int, digits: Array) -> void:
	for index: int in digits.size():
		write_byte(0, address + index, digits[index] * 2 + 0xA0)
		write_byte(0, address + index + MAP_WIDTH, digits[index] * 2 + 0xA1)


## InitTimeAttackClearScreen's drawing: the BG map cleared, its palettes, the treasure screen's
## tiles, Time Attack's maps (the attribute map through bank 1's BG map 0), the level's best time,
## and the time just made when the keys were all found.
func load_time_attack(clear: ClearSim, sim: LevelSim) -> void:
	screen = "time_attack"
	fill_bg_map_0(0xFF)
	bg_palettes = _bytes("palettes", "78:43f8")
	obj_palettes = _bytes("palettes", "78:4438")
	_load_clear_screen_gfx()
	write(1, BG_MAP_0, _bytes("compressed", "78:5c5b"))
	write(0, BG_MAP_0, _bytes("compressed", "78:5ae5"))
	_print_time(map_address(BG_MAP_0, 10, 7), clear.r3(ClearSim.W3D511), clear.r3(ClearSim.W3D511 + 1))
	if clear.wTimeAttackResult != 0:
		_print_time(map_address(BG_MAP_0, 10, 10), clear.r0(ClearSim.W_LEVEL_TIME), clear.r0(ClearSim.W_LEVEL_TIME + 1))


func _print_time(address: int, minutes: int, seconds: int) -> void:
	_print_digits(address, [minutes >> 4, minutes & 0x0F])
	_print_digits(address + 3, [seconds >> 4, seconds & 0x0F])


## InitMusicalCoinScreen's drawing: the BG map cleared, its palettes, the coin chart's tiles and
## maps (golf's menu graphics), and each level with all eight coins coloured (Func_d47f1: five a
## row from (8, 9); the 25th takes the 24th's palette, as the original's index is not advanced).
func load_musical_coins(clear: ClearSim) -> void:
	screen = "musical_coins"
	fill_bg_map_0(0xFF)
	bg_palettes = _bytes("palettes", "35:50a4")
	obj_palettes = _bytes("palettes", "35:50e4")
	write(0, 0x8000, _bytes("compressed", "35:5124"))
	write(1, BG_MAP_0, _bytes("compressed", "35:6502"))
	write(0, BG_MAP_0, _bytes("compressed", "35:63fd"))
	var palettes: PackedByteArray = String(tables.get("musical_coin_level_bg_pals", {}).get("bytes", "")).hex_decode()
	for level: int in ClearSim.NUM_LEVELS:
		var flags: int = clear.r0(ClearSim.W_MUSICAL_COIN_FLAGS + (level >> 3))
		if (flags & (1 << (level & 7))) == 0:
			continue
		var index: int = mini(level, 23)
		write_byte(1, map_address(BG_MAP_0, 8 + level % 5, 9 + level / 5), palettes[index] if index < palettes.size() else 0)


## The V-Blank function's VRAM writes: the treasure screen's (VBlank_ClearScreen: the low and then
## the high bytes of tiles $170-$171's sixteen rows each move down a row, the last to the top), and
## the coin screen's queued entry.
func vblank(clear: ClearSim) -> void:
	if clear.vblank_func == ClearSim.VBlankFunc.TILES:
		for plane: int in 2:
			var last: int = read_byte(0, 0x9700 + 30 + plane)
			for row: int in range(15, 0, -1):
				write_byte(0, 0x9700 + row * 2 + plane, read_byte(0, 0x9700 + (row - 1) * 2 + plane))
			write_byte(0, 0x9700 + plane, last)
	for entry: Array in clear.vblank_writes:
		write_byte(int(entry[0]), int(entry[1]), int(entry[2]))
