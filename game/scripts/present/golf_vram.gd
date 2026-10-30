class_name GolfVram
extends ScreenVram
## What the golf screens put in VRAM (WL3-050): the original's screen loads (InitGolfLobby.LoadGolfLobby,
## InitGolfHole with PickAndLoadGolfHole and ShowGolfHoleFlagAndPar, InitGolfClearCutscene.LoadCutsceneGfx,
## the golf building's Func_1c8604) and V-Blank functions, from golf.json's graphics and the golf RAM,
## and the room animation's tiles (the golf building menu's set 15). The rest of VRAM still holds the
## level's (or the map's). With the LCD registers the last V-Blank set: the hole's from golf RAM, the
## other screens' LCDC_DEFAULT.

var holes: Array = []
var lcdc: int = GolfSim.LCDC_DEFAULT
var wx: int = 0


func _init(document: Dictionary = {}, animation: Dictionary = {}) -> void:
	super(document)
	holes = document.get("holes", [])
	animated_tiles = animation.get("animated_tiles_gfx", {})


## One loop: the screen its init loaded, then what the V-Blank function after it wrote, and with the
## LevelSim the room animation's frame if one was written.
func update(golf: GolfSim, sim: LevelSim = null) -> void:
	for load: Array in golf.screen_loads:
		match String(load[0]):
			"lobby":
				load_lobby(golf)
			"hole":
				load_hole(golf, int(load[1]), int(load[2]))
			"clear":
				load_clear()
			"menu":
				load_menu(golf)
	vblank(golf)
	if sim != null:
		room_animation(sim)
	var hole: bool = screen == "hole"
	lcdc = golf.rb(GolfSim.W_GOLF_LCD_CONFIG) if hole else GolfSim.LCDC_DEFAULT
	wx = golf.rb(GolfSim.W_GOLF_WX) if hole else 0


## A copy with the registers, for drawing a frame that changes as it is drawn.
func copy() -> ScreenVram:
	var other := GolfVram.new()
	other.gfx = gfx
	other.screen = screen
	other.bg_palettes = bg_palettes.duplicate()
	other.obj_palettes = obj_palettes.duplicate()
	other.lcdc = lcdc
	other.wx = wx
	for bank: int in 2:
		other.vram[bank] = vram[bank].duplicate()
		other.written[bank] = written[bank].duplicate()
	return other


## InitGolfLobby: the lobby's tiles and maps, and the price's four tiles for the second and third
## tiers.
func load_lobby(golf: GolfSim) -> void:
	screen = "lobby"
	write(0, 0x8800, _bytes("compressed", "71:4f0d"))
	write(1, BG_MAP_0, _bytes("compressed", "71:5cbe"))
	write(0, BG_MAP_0, _bytes("compressed", "71:5b4e"))
	var price: int = golf.rb(GolfSim.W_GOLF_PRICE)
	if price != GolfSim.GOLF_PRICE_TIER_1:
		var first: int = 0xF8 if price == GolfSim.GOLF_PRICE_TIER_2 else 0xFC
		write_byte(0, map_address(BG_MAP_0, 11, 8), first)
		write_byte(0, map_address(BG_MAP_0, 11, 9), first + 1)
		write_byte(0, map_address(BG_MAP_0, 12, 8), first + 2)
		write_byte(0, map_address(BG_MAP_0, 12, 9), first + 3)
	bg_palettes = _bytes("palettes", "72:61cf")
	obj_palettes = _bytes("palettes", "72:620f")


## InitGolfHole: the flag tiles (bank 1), the course tiles and Golf Wario idle (bank 0), each map's
## hole rows from row 7 and its background above, then the flag's number, the par's digit four
## times, and the stroke number (bank 1).
func load_hole(golf: GolfSim, hole: int, option: int) -> void:
	screen = "hole"
	write(1, 0x8000, _bytes("compressed", "70:4c5f"))
	write(0, 0x8800, _bytes("compressed", "70:4000"))
	write(0, 0x8000, _bytes("wario_tiles", "04:4000"))
	if hole < holes.size():
		# GolfHoles entry: data, _2 tile map, _1 tile map, _2 attribute map, _1 attribute map
		var maps: Array = holes[hole]["maps"]
		write(1, map_address(BG_MAP_0, 0, 7), _bytes("compressed", "70:" + String(maps[3])))
		write(1, BG_MAP_0, _bytes("compressed", "70:5651"))
		write(1, map_address(BG_MAP_1, 0, 7), _bytes("compressed", "70:" + String(maps[2])))
		write(1, BG_MAP_1, _bytes("compressed", "70:5716"))
		write(0, map_address(BG_MAP_0, 0, 7), _bytes("compressed", "70:" + String(maps[1])))
		write(0, BG_MAP_0, _bytes("compressed", "70:55c5"))
		write(0, map_address(BG_MAP_1, 0, 7), _bytes("compressed", "70:" + String(maps[0])))
		write(0, BG_MAP_1, _bytes("compressed", "70:568a"))
	var par: int = golf.rb(GolfSim.W_GOLF_PAR)
	var flag_number: int = (par - 1) if golf.rb(GolfSim.W1D800) == 2 else golf.rb(GolfSim.W_GOLF_COURSE_HOLE)
	var flag_digits: PackedByteArray = _bytes("raw", "72:638f")
	write(1, 0x8000 + 0x01 * 16, _tile(flag_digits, flag_number * 16))
	var par_digit: PackedByteArray = _tile(_bytes("raw", "72:63df"), (par - 3) * 16)
	for tile: int in [0x2B, 0x4B, 0x6B, 0x8B]:
		write(1, 0x8000 + tile * 16, par_digit)
	if golf.rb(GolfSim.W1D800) != 2:
		var flag: PackedByteArray = _bytes("raw", "72:654f")
		for index: int in 3:
			write(1, 0x8000 + [0x20, 0x40, 0x60][index] * 16, flag.slice(index * 96, index * 96 + 96))
		write(1, 0x8800, flag.slice(3 * 96, 4 * 96))  # rVBK is still 1
	write(1, 0x8000 + 0xF0 * 16, golf.ram.slice(GolfSim.W1DB90 - GolfSim.RAM_START, GolfSim.W1DB90 - GolfSim.RAM_START + 64))
	bg_palettes = _bytes("palettes", "%02x:%04x" % [0x72, 0x608F + 0x40 * (option & 3)])
	obj_palettes = _bytes("palettes", "72:618f")


## The golf building's menu (Func_1c8604): its tiles (GolfMenuGfx, the clear cutscene's), the
## courses' attributes with the course's in rows 6-12 (wGolfCourseTileMap), the courses' tile map
## (the fourth locked without every musical coin), and each course's best score in rows 13 and 14
## from column 2, 8 columns apart: a sign (+, -, or 0's tiles) and two digits ($a0 on, two tiles each),
## blank at 100 or more. The palettes are the course's (w1db00) and Pals_1ca34f.
func load_menu(golf: GolfSim) -> void:
	screen = "menu"
	write(0, 0x8000, _bytes("compressed", "35:5124"))
	write(1, BG_MAP_0, _bytes("compressed", "71:4ea8"))
	write(1, map_address(BG_MAP_0, 0, 6), _golf_ram(golf, GolfSim.W_GOLF_COURSE_TILE_MAP, GolfSim.COURSE_ROWS_SIZE))
	var all_coins: bool = golf.rb(GolfSim.W_HAS_ALL_MUSICAL_COIN_FLAGS) != 0
	write(0, BG_MAP_0, _bytes("compressed", "71:4d83" if all_coins else "71:4c60"))
	for course: int in GolfSim.NUM_GOLF_COURSES:
		var score: int = golf.r0(GolfSim.W_GOLF_BEST_SCORES + course)
		var column: int = 2 + course * 8
		var sign: Array[int] = [0, 0]
		var tens: int = 10
		var ones: int = 10
		if score < GolfSim.GOLF_BASE_SCORE + 100:
			var value: int = 0
			if score > GolfSim.GOLF_BASE_SCORE:
				sign = [0xD2, 0xD3]
				value = score - GolfSim.GOLF_BASE_SCORE
			elif score == GolfSim.GOLF_BASE_SCORE:
				sign = [0xBE, 0xBF]
			else:
				sign = [0xD4, 0xD5]
				value = GolfSim.GOLF_BASE_SCORE - score
			tens = value / 10
			ones = value % 10
		write_byte(0, map_address(BG_MAP_0, column, 13), sign[0])
		write_byte(0, map_address(BG_MAP_0, column, 14), sign[1])
		for digit: int in 2:
			var value: int = tens if digit == 0 else ones
			write_byte(0, map_address(BG_MAP_0, column + 1 + digit, 13), value * 2 + 0xA0)
			write_byte(0, map_address(BG_MAP_0, column + 1 + digit, 14), value * 2 + 0xA1)
	bg_palettes = _golf_ram(golf, GolfSim.W1DB00, 0x40)
	obj_palettes = _bytes("palettes", GolfSim.MENU_OBJ_PALS)


func _golf_ram(golf: GolfSim, address: int, size: int) -> PackedByteArray:
	return golf.ram.slice(address - GolfSim.RAM_START, address - GolfSim.RAM_START + size)


func _tile(data: PackedByteArray, offset: int) -> PackedByteArray:
	if offset < 0 or offset + 16 > data.size():
		return PackedByteArray()
	return data.slice(offset, offset + 16)


## InitGolfClearCutscene: its tiles and maps.
func load_clear() -> void:
	screen = "clear"
	write(0, 0x8000, _bytes("compressed", "35:5124"))
	write(1, BG_MAP_0, _bytes("compressed", "71:5dc6"))
	write(0, BG_MAP_0, _bytes("compressed", "71:5d6c"))
	bg_palettes = _bytes("palettes", "72:624f")
	obj_palettes = _bytes("palettes", "72:634f")


## What the V-Blank function the loop left writes to VRAM.
func vblank(golf: GolfSim) -> void:
	match golf.vblank_func:
		GolfSim.VBlankFunc.LOBBY_COINS:  # VBlank_1c9f36: the coins' three digits, two tiles each
			var digits: Array[int] = [golf.rb(GolfSim.W_GOLF_NUM_COINS),
					golf.rb(GolfSim.W_GOLF_NUM_COINS + 1) >> 4, golf.rb(GolfSim.W_GOLF_NUM_COINS + 1) & 0x0F]
			for index: int in 3:
				write_byte(0, map_address(BG_MAP_0, 6 + index, 8), digits[index] * 2 + 0xE0)
				write_byte(0, map_address(BG_MAP_0, 6 + index, 9), digits[index] * 2 + 0xE1)
		GolfSim.VBlankFunc.LOBBY_WARIO, GolfSim.VBlankFunc.HOLE_WARIO:  # Golf Wario's tiles by DMA
			var key: String = "%02x:%04x" % [golf.rb(GolfSim.W_GOLF_WARIO_TILES_BANK),
					(golf.rb(GolfSim.W_GOLF_WARIO_TILES_PTR) << 8) | golf.rb(GolfSim.W_GOLF_WARIO_TILES_PTR + 1)]
			write(0, 0x8000, _bytes("wario_tiles", key))
		GolfSim.VBlankFunc.PIN_FLAG:  # VBlank_1c9d1d: the pin flag's frame, 4 tiles
			var frames: PackedByteArray = _bytes("raw", "72:5d8d")
			write(1, 0x9740, frames.slice(golf.pin_flag_frame * 64, golf.pin_flag_frame * 64 + 64))
		GolfSim.VBlankFunc.HOLE_ATTR:  # VBlank_1c9e8d
			write_byte(1, map_address(BG_MAP_0, 5, 10), 0x03)
		GolfSim.VBlankFunc.STROKE:  # VBlank_1c9ef1: the stroke number's 4 tiles
			write(1, 0x8000 + 0xF0 * 16, golf.ram.slice(GolfSim.W1DB90 - GolfSim.RAM_START, GolfSim.W1DB90 - GolfSim.RAM_START + 64))
		GolfSim.VBlankFunc.MENU_SCROLLING_ATTRS:  # VBlank_1c9ffa: by HDMA to BG map 0's rows 6-12 (bank 1)
			write(1, map_address(BG_MAP_0, 0, 6), _golf_ram(golf, GolfSim.W_GOLD_BUILDING_COURSE_ATTR_MAP,
					GolfSim.COURSE_ROWS_SIZE))
		GolfSim.VBlankFunc.MENU_PALS:  # VBlank_1ca033: w1db00 to the BG palettes
			bg_palettes = _golf_ram(golf, GolfSim.W1DB00, 0x40)
		GolfSim.VBlankFunc.MENU_COURSE_ATTRS:  # VBlank_1ca056: wGolfCourseTileMap, as VBlank_1c9ffa
			write(1, map_address(BG_MAP_0, 0, 6), _golf_ram(golf, GolfSim.W_GOLF_COURSE_TILE_MAP,
					GolfSim.COURSE_ROWS_SIZE))
