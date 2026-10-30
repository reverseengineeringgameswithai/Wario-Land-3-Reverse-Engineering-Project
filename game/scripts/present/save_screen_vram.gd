class_name SaveScreenVram
extends ScreenVram
## What the pause menu's state table puts in VRAM (WL3-052), from pause_menu.json's graphics: the
## pause menu (InitPauseMenu_SkipBackupVRAM: BG map 0 cleared, its tiles, a transformation's over
## their start, Func_1f403f's maps on BG map 1 with Time Attack's times, the musical coins and the
## coins), the map's save screen (InitSaveScreenAndBackupVRAM: BG map 1's tiles cleared, the box's
## tiles with Wario asleep over their start, the "saving" box's maps on BG map 0) and the level's
## (InitSaveScreen: the same but BG map 1, which the menu left), the bar's tiles as its V-Blank function
## writes them, and the "complete" box. Its palettes are the temporary sets the fades in end on.

const PAUSE_MENU_GFX: String = "7d:4202"
## Func_1f403f's maps [tiles, attributes], without and with Time Attack.
const PAUSE_MENU_MAPS: Array = ["7d:5de1", "7d:5f49"]
const TIME_ATTACK_PAUSE_MENU_MAPS: Array = ["7d:603a", "7d:6194"]
## LoadPauseMenuGfx's $20 tiles for a transformation: ActionHelpOwlGfx, ActionHelpRailGfx,
## ActionHelpVampireGfx.
const TRANSFORMATION_TILES: Dictionary = {WarioRam.TRANSFORMATION_OWL_WARIO: "7d:57e1",
		WarioRam.TRANSFORMATION_RAIL: "7d:59e1", WarioRam.TRANSFORMATION_VAMPIRE_WARIO: "7d:5be1"}
const W_LEVEL_TIME: int = 0xC0E2
const W_NUM_COINS: int = 0xCA04
const W_NUM_MUSICAL_COINS: int = 0xCA5C
## The digits' tiles: digit d's top at $a0 + 2d, its bottom the next.
const DIGIT_TILES: int = 0xA0
## The fades in after which the screen shows its temporary palettes: the pause menu's, and the save
## screens' (the level's, the map's, and the map's again after the Perfect screen, SST_PAUSE_28 on)
## before the bar and before the "complete" box.
const FADED_IN: Array = [0x03, 0x0B, 0x0F, 0x1B, 0x1F, 0x2B, 0x2F]


func _init(document: Dictionary = {}) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)


## One loop: the screens it loaded, its V-Blank function's writes, and the palettes a fade in ended
## on (wTempPals1 and wTempPals2, as DarkenBGToPal leaves them).
func update(pause: PauseMenuSim, sim: LevelSim) -> void:
	for load: Array in pause.screen_loads:
		match String(load[0]):
			"pause_menu":
				load_pause_menu(pause)
			"level_save_in_progress":
				load_save_in_progress(false)
			"save_in_progress":
				load_save_in_progress()
			"save_complete":
				_box("7d:6a2e", "7d:6ac2")
	for entry: Array in pause.vblank_writes:
		write_byte(int(entry[0]), int(entry[1]), int(entry[2]))
	if sim.wPalFadeCounter == 0 and sim.wSubState in FADED_IN:
		bg_palettes = pause.wram[0].slice(0, 0x40)
		obj_palettes = pause.wram[0].slice(0x40, 0x80)


## InitPauseMenu_SkipBackupVRAM's drawing: ClearBGMap0 ($ff), LoadPauseMenuGfx (PauseMenuGfx from
## $8000, a transformation's $20 tiles over its start), Func_1f403f (its maps on BG map 1; in Time
## Attack the level's best time, w3d511, at (4, 2) and wLevelTime at (11, 2)), PrintNumberMusicCoins
## at (7, 15), and PrintNumberCoins at (14, 15), from `pause`'s RAM as the loop left it.
func load_pause_menu(pause: PauseMenuSim) -> void:
	screen = "pause_menu"
	fill_bg_map_0(0xFF)
	write(0, 0x8000, _bytes("compressed", PAUSE_MENU_GFX))
	var transformation: int = pause.r0(PauseMenuSim.W_TRANSFORMATION)
	if TRANSFORMATION_TILES.has(transformation):
		write(0, 0x8000, _bytes("raw", TRANSFORMATION_TILES[transformation]))
	var time_attack: bool = (pause.r0(PauseMenuSim.W_GAME_MODE_FLAGS) & PauseMenuSim.MODE_TIME_ATTACK) != 0
	var maps: Array = TIME_ATTACK_PAUSE_MENU_MAPS if time_attack else PAUSE_MENU_MAPS
	write(1, BG_MAP_1, _bytes("compressed", maps[1]))
	write(0, BG_MAP_1, _bytes("compressed", maps[0]))
	if time_attack:
		_time(4, 2, pause.r3(PauseMenuSim.W3D511), pause.r3(PauseMenuSim.W3D511 + 1))
		_time(11, 2, pause.r0(W_LEVEL_TIME), pause.r0(W_LEVEL_TIME + 1))
	_digit(7, 15, pause.r0(W_NUM_MUSICAL_COINS))
	var coins: int = pause.r0(W_NUM_COINS + 1)
	for index: int in 3:
		var digit: int = [pause.r0(W_NUM_COINS) & 0x0F, coins >> 4, coins & 0x0F][index]
		_digit(14 + index, 15, digit)


## A digit's two tiles at (`x`, `y`) and below it on BG map 1 (the counts' and times' digits:
## `value` * 2 + $a0, wrapping as the original's byte does).
func _digit(x: int, y: int, value: int) -> void:
	var tile: int = (value * 2 + DIGIT_TILES) & 0xFF
	write_byte(0, map_address(BG_MAP_1, x, y), tile)
	write_byte(0, map_address(BG_MAP_1, x, y + 1), (tile + 1) & 0xFF)


## A time's two BCD bytes from (`x`, `y`): their four digits, a column left out between the bytes.
func _time(x: int, y: int, high: int, low: int) -> void:
	_digit(x, y, high >> 4)
	_digit(x + 1, y, high & 0x0F)
	_digit(x + 3, y, low >> 4)
	_digit(x + 4, y, low & 0x0F)


## InitSaveScreenAndBackupVRAM's drawing (InitSaveScreen's without `clear_bg_map_1`): ClearBGMap1
## (bank 0's tiles $ff), LoadSaveScreenGfx (SaveBoxGfx from $8000, WarioSleepGfx's $800 bytes over
## its start), and the "saving" box.
func load_save_in_progress(clear_bg_map_1: bool = true) -> void:
	screen = "save"
	if clear_bg_map_1:
		var fill := PackedByteArray()
		fill.resize(0x400)
		fill.fill(0xFF)
		write(0, BG_MAP_1, fill)
	write(0, 0x8000, _bytes("compressed", "7d:62cc"))
	write(0, 0x8000, _bytes("raw", "76:6800"))
	_box("7d:6949", "7d:69f9")


## A box's tile map and attribute map on BG map 0.
func _box(tilemap: String, attrmap: String) -> void:
	write(1, BG_MAP_0, _bytes("compressed", attrmap))
	write(0, BG_MAP_0, _bytes("compressed", tilemap))
