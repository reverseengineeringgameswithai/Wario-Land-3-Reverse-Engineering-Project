class_name GolfSim
extends ScreenSim
## The golf minigame (src/engine/golf/, src/home/load_golf_sprite.asm), ported by translation
## (WL3-050): _GolfStateTable's lobby, holes, and clear cutscene, and _GolfBuildingStateTable's course
## menu and courses (the golf building). Its RAM is WRAMX bank 1 from $d800 (`ram`), byte for byte as
## the original holds it (positions little-endian, wGolfOAMPtr and wGolfWarioTilesPtr high byte
## first), so a parity check compares it whole. The WRAM0 variables it shares with the level (the
## sub-state, the joypad, the scroll, the coins, the treasures, the language, the fade) are the
## LevelSim's (`sim`); the WRAM0 bytes only golf and the screens use (the temporary palettes,
## wTransitionParam, the musical coin flags, the golf building's best scores) are in the screens'
## shared WRAM0 (`wram`, MenuScreenSim's). The virtual OAM its sprites are built in and the fades are
## ScreenSim's. Tiles, the music, and the sound effects are not part of the state.

const RAM_START: int = 0xD800
const RAM_SIZE: int = 0x800
const GOLF_CODE_BANK: int = 0x72  # the ROM bank golf's own OAM tables are read in

# Golf RAM (src/ram/wram.asm, "Golf RAM"; addresses from the reference build's symbols).
const W1D800: int = 0xD800  # 2 in a level's golf, 1 in the golf building, 0 once left
const W_GOLF_MENU_OPTION: int = 0xD801
const W_PREDETERMINED_GOLF_HOLE: int = 0xD802
const W_GOLF_COURSE_HOLE: int = 0xD803
const W_GOLF_COURSE: int = 0xD804
const W_GOLF_COURSE_SCORE: int = 0xD805
const W_GOLF_HOLE_RAM_START: int = 0xD900
const W_GOLF_COURSE_TILE_MAP: int = 0xD900  # the menu's course attributes (7 rows), over wGolfPinFlagTiles
const W_GOLF_PIN_FLAG_TILES: int = 0xD900
const PIN_FLAG_GFX: String = "72:5d8d"  # GolfPinFlagGfx: four frames of 4 tiles
const W_GOLD_BUILDING_COURSE_ATTR_MAP: int = 0xDA00
const W1DB00: int = 0xDB00  # the menu's course palettes (8)
const W_HAS_ALL_MUSICAL_COIN_FLAGS: int = 0xDC03
const W_GOLF_MENU_SCROLLING_DIR: int = 0xDC27
const W_GOLF_MENU_TARGET_SCX: int = 0xDC2E
const WDC11: int = 0xDC11  # the menu's HDMA destination (high byte less $80, then low), over wGolfWarioTilesPtr
const W1DC13: int = 0xDC13  # and its length
const W_GOLF_HOLE_DATA: int = 0xDB40  # wGolfTerrainBlocks (65), wGolfPar, w1db82 (2), the water spawns
const W_GOLF_TERRAIN_BLOCKS: int = 0xDB40
const W_GOLF_PAR: int = 0xDB81
const W1DB82: int = 0xDB82
const W_GOLF_WATER_SPAWN_1: int = 0xDB84
const W_GOLF_WATER_SPAWN_2: int = 0xDB85
const W1DB90: int = 0xDB90  # the stroke number's 4 tiles
const W1DC00: int = 0xDC00  # the golf building menu's state
const W_GOLF_LOBBY_STATE: int = 0xDC00
const W_GOLF_HOLE_STATE: int = 0xDC00
const W1DC01: int = 0xDC01
const W_GOLF_VBLANK_MODE: int = 0xDC02
const W_GOLF_ANIM_LAST_FRAME: int = 0xDC09
const W_GOLF_COUNTER: int = 0xDC0A
const W1DC0B: int = 0xDC0B
const W_GOLF_LCD_CONFIG: int = 0xDC0C
const W_GOLF_WARIO_TILES_BANK: int = 0xDC0D
const W_GOLF_HOLE_TIER: int = 0xDC0E
const W_GOLF_PRICE: int = 0xDC0F
const W_GOLF_WARIO_TILES_PTR: int = 0xDC11
const W_GOLF_OAM_PTR: int = 0xDC17
const W_GOLF_NUM_COINS: int = 0xDC19
const W1DC20: int = 0xDC20
const W1DC21: int = 0xDC21
const W_GOLF_STROKE: int = 0xDC22
const W_GOLF_MAX_STROKES: int = 0xDC23
const W_GOLF_RESULT: int = 0xDC24
const W_GOLF_WX: int = 0xDC25
const W_GOLF_DISPLAY_MODE: int = 0xDC26
const W_GOLF_HOLE_SCROLLING_DIR: int = 0xDC27
const W_GOLF_HOLE_DIRECTION: int = 0xDC28
const W_SHOT_DIRECTION: int = 0xDC29
const W_HAS_GOLF_WARIO_ANIMATION_FINISHED: int = 0xDC2A
const W_GOLF_X_SCROLL: int = 0xDC2C
const W_TEMP_GOLF_X_SCROLL: int = 0xDC2E
const W_GOLF_WARIO_Y_POS: int = 0xDC30
const W_GOLF_WARIO_X_POS: int = 0xDC32
const W_GOLF_PARA_GOOM_Y_POS: int = 0xDC34
const W_GOLF_PARA_GOOM_X_POS: int = 0xDC36
const W_GOLF_HOLE_HOLE_X_POS: int = 0xDC38
const W_LAST_GOLF_PARA_GOOM_Y_POS: int = 0xDC3A
const W_LAST_GOLF_PARA_GOOM_X_POS: int = 0xDC3C
const W1DC3E: int = 0xDC3E
const W_GOLF_WARIO_TARGET_X_POS: int = 0xDC40
const W_GOLF_WARIO_DIR: int = 0xDC42
const W_GROUND_LEVEL_Y_POS: int = 0xDC44
const W_GOLF_TERRAIN: int = 0xDC45
const W_SHOT_TERRAIN_MODIFIER: int = 0xDC46
const W1DC47: int = 0xDC47
const W_STROKE_GOLF_TERRAIN: int = 0xDC48
const W_IS_POWER_GAUGE_FALLING: int = 0xDC49
const W_SHOT_POWER_GAUGE_CURSOR: int = 0xDC4A
const W_SHOT_POWER_LEVEL: int = 0xDC4B
const W_SELECTED_SHOT_POWER_GAUGE: int = 0xDC4C
const W_SHOT_SPIN: int = 0xDC4D
const W_GOLF_WARIO_Y_VEL: int = 0xDC4E
const W_SHOT_Y_VEL: int = 0xDC4E
const W1DC4F: int = 0xDC4F
const W_SHOT_X_VEL: int = 0xDC50
const W1DC51: int = 0xDC51
const W1DC53: int = 0xDC53
# golf_obj_struct (src/macros/wram.asm): state, duration, frameset offset, current frame, then the
# sprite's y, x, frame, and attributes.
const OBJ_STATE: int = 0
const OBJ_DURATION: int = 1
const OBJ_FRAMESET_OFFSET: int = 2
const OBJ_CURRENT_FRAME: int = 3
const OBJ_Y_COORD: int = 4
const OBJ_X_COORD: int = 5
const OBJ_FRAME: int = 6
const W_GOLF_OBJ_1: int = 0xDC54
const W_GOLF_OBJ_2: int = 0xDC5C
const W_GOLF_OBJ_3: int = 0xDC64
const W_GOLF_OBJ_4: int = 0xDC6C
const W_GOLF_OBJ_5: int = 0xDC74
const W_GOLF_PARA_GOOM: int = 0xDC7C
const W_GOLF_WARIO: int = 0xDC84
const W_GOLF_OVERLAY_TEXT: int = 0xDC8C
const W_GOLF_PARA_GOOM_GHOST: int = 0xDC94

# src/constants/golf_constants.asm
const GOLF_PRICE_TIER_1: int = 0x10
const GOLF_PRICE_TIER_2: int = 0x30
const GOLF_PRICE_TIER_3: int = 0x50
const GOLF_TREASURES_TIER_2: int = 0x25
const GOLF_TREASURES_TIER_3: int = 0x50
const COININFO_NOT_ENOUGH_COINS: int = 1
const COININFO_SHOW_MESSAGE: int = 2
const NUM_GOLF_COURSE_HOLES: int = 4
const NUM_GOLF_COURSES: int = 4
const GOLF_COURSE_3: int = 2
const GOLF_COURSE_4: int = 3
const GOLF_BUILDING_PRICE: int = 0x50
const MAX_GOLF_COURSE_STROKES: int = 19
const GOLF_BASE_SCORE: int = MAX_GOLF_COURSE_STROKES + 1
const GOLF_HOLE_TIER_1: int = 5
const GOLF_HOLE_TIER_2: int = 10
const GOLF_HOLE_TIER_3: int = 15
const GOLFRESULT_PAR: int = 1
const GOLFRESULT_OVER_PAR: int = 2
const GOLFRESULT_COURSE_UNDER_PAR: int = 3
const GOLFRESULT_COURSE_OVER_PAR: int = 4
const GOLF_TERRAIN_PLAIN: int = 1
const SPECIAL_GOLF_TERRAIN: int = 2
const GOLF_TERRAIN_HOLE: int = 2
const GOLF_TERRAIN_ROUGH: int = 3
const GOLF_TERRAIN_BUNKER: int = 4
const GOLF_TERRAIN_WATER: int = 5
const GOLF_TERRAIN_OB: int = 6
const GOLF_TERRAIN_TEE_OB: int = 7
const GOLF_TERRAIN_END: int = 8
const GOLF_TERRAIN_EDGE_RIGHT_F: int = 4
const GOLF_TERRAIN_EDGE_LEFT_F: int = 5
const GOLF_TERRAIN_2ND_WATER: int = 0x80
const GOLF_TERRAIN_MASK: int = 0x0F
const GOLF_TERRAIN_FLAGS_MASK: int = 0xF0
const BASE_SHOT_POWER: int = 8
const MAX_SHOT_POWER: int = 76
const SHOT_MISS: int = 0
const SHOT_BACKSPIN: int = 1
const SHOT_NORMAL: int = 2
const SHOT_TOPSPIN: int = 3
const SHOT_MODIFIER_NONE: int = 0
const SHOT_MODIFIER_ROUGH: int = 1
const SHOT_MODIFIER_BUNKER: int = 2
const GOLF_DISPLAY_BGMAP0: int = 0
const GOLF_DISPLAY_SPLIT: int = 1
const GOLF_DISPLAY_BGMAP1: int = 2
const MAX_GOLF_X_SCROLL: int = 0x160
const PARAGOOM_GROUND_LEVEL: int = 0x180
const PARAGOOM_TEE_BOX_LEVEL: int = PARAGOOM_GROUND_LEVEL - 0x20
const GOLF_WARIO_IDLING: int = 0
const GOLF_WARIO_WALKING: int = 1
const GOLF_WARIO_CHARGING: int = 2
const GOLF_WARIO_ATTACKING_1: int = 3
const GOLF_WARIO_ATTACKING_2: int = 4
const GOLF_WARIO_MISSING: int = 5
const GOLF_WARIO_CLEARED: int = 6
const GOLF_WARIO_LOST: int = 7
const GOLF_WARIO_WAITING: int = 8
const GOLF_WARIO_ENTERING_DOOR: int = 9
const GOLF_WARIO_GOING_IN_PIPE: int = 10
const GOLF_WARIO_TURNING: int = 11
const NUM_GOLF_WARIO_STATES: int = 12
const GOLF_PARAGOOM_1: int = 1
const GOLF_PARAGOOM_2: int = 2
const GOLF_PARAGOOM_3: int = 3
const GOLF_PARAGOOM_4: int = 4
const GOLF_PARAGOOM_5: int = 5
const GOLF_PARAGOOM_6: int = 6
const GOLF_PARAGOOM_8: int = 8
const GOLFLOBBYSTATE_WAIT_INPUT: int = 0
const GOLFLOBBYSTATE_WALK_RIGHT: int = 1
const GOLFLOBBYSTATE_WALK_LEFT: int = 2
const GOLFLOBBYSTATE_ENTER_PIPE: int = 3
const GOLFLOBBYSTATE_ENTER_DOOR: int = 4
const GOLFLOBBYSTATE_EXIT_PIPE: int = 5
const GOLFHOLESTATE_WAIT_INPUT: int = 0
const GOLFHOLESTATE_SCROLL: int = 1
const GOLFHOLESTATE_SELECT_SHOT_POWER: int = 2
const GOLFHOLESTATE_SELECT_SHOT_SPIN: int = 3
const GOLFHOLESTATE_START_SHOT: int = 4
const GOLFHOLESTATE_SHOT: int = 5
const GOLFHOLESTATE_BOUNCE: int = 6
const GOLFHOLESTATE_SPECIAL_TERRAIN: int = 7
const GOLFHOLESTATE_WALK: int = 8
const GOLFHOLESTATE_BETWEEN_SHOTS: int = 9
const GOLFHOLESTATE_CLEARED: int = 10
const GOLFHOLESTATE_GAME_OVER: int = 11
const GOLFHOLESTATE_PAUSE: int = 12
const GOLFHOLESTATE_RESULT: int = 13
# src/constants/state_constants.asm: _GolfStateTable's sub-states.
const SST_GOLF_HOLE: int = 4
const SST_GOLF_EXIT: int = 8
const SST_GOLF_CLEAR: int = 10
# _GolfBuildingStateTable's way out (ReturnToMap), and StartOverworldState's state.
const SST_GOLF_BUILDING_EXIT: int = 8
const ST_OVERWORLD: int = 0x01
const TRANSITION_RETURN_TO_MAP: int = 0xF0
const SCREEN_HEIGHT_PX: int = 144
const WX_OFS: int = 7
const LCDC_DEFAULT: int = 0x87  # BG, OBJ, 8x16 OBJ, on
const LCDC_SPLIT: int = 0xE7  # LCDC_DEFAULT with the window on, from $9c00
const LCDC_BGMAP1: int = 0x8F  # LCDC_DEFAULT with the BG from $9c00
const RDIV_PICK_GOLF_HOLE: int = (0x72 << 16) | 0x4A3A  # PickAndLoadGolfHole's rDIV read

# The OAM tables golf objects are drawn with (values of wGolfOAMPtr).
const OAM_1CB2D3: int = 0x72D3  # the lobby
const OAM_1CB3E0: int = 0x73E0  # the clear cutscene and the golf building's menu
const OAM_1CA6CF: int = 0x66CF  # the holes
# UpdateGolfWarioAnimation's tables by Golf Wario's state: OAM table (and its bank), frameset facing
# right and facing left ("BB:AAAA" keys of golf.json's framesets).
const WARIO_OAM_BANKS: Array[int] = [0x05, 0x05, 0x05, 0x05, 0x05, 0x72, 0x35, 0x35, 0x35, 0x35, 0x05, 0x7F]
const WARIO_OAM: Array[int] = [0x4000, 0x426C, 0x4D1B, 0x4D1B, 0x4D1B, 0x70DD, 0x49CC, 0x49CC, 0x49CC,
		0x49CC, 0x4A82, 0x431B]
const WARIO_FRAMESETS_RIGHT: Array[String] = ["05:425f", "05:49c5", "05:51fd", "00:2da4", "00:2da7",
		"72:7285", "35:4d1b", "35:4d5f", "00:2db0", "00:2db5", "05:4cf6", "7f:447c"]
const WARIO_FRAMESETS_LEFT: Array[String] = ["05:4252", "05:49b4", "05:51e4", "00:2daa", "00:2dad",
		"72:72ac", "35:4d1b", "35:4d5f", "00:2db0", "00:2db5", "05:4cf6", "7f:4473"]
# LoadGolfWarioStateGfx: the bank and address of Golf Wario's tiles by state.
const WARIO_GFX_BANKS: Array[int] = [0x04, 0x04, 0x04, 0x04, 0x04, 0x71, 0x0B, 0x0B, 0x0B, 0x0B, 0x04, 0x04]
const WARIO_GFX: Array[int] = [0x4000, 0x4800, 0x5800, 0x5800, 0x5800, 0x4000, 0x7000, 0x7000, 0x7000,
		0x7000, 0x4000, 0x4000]
# UpdateGolfParaGoom's framesets by its state; 6 reads past the table (golf.json's 72:4e23).
const PARA_GOOM_FRAMESETS: Array[String] = ["72:6fb1", "72:6fb6", "72:6fc7", "72:6fe8", "72:7005",
		"72:6fb1", "72:4e23"]
# ShowGolfResultOverlayText's framesets by wGolfResult.
const RESULT_FRAMESETS: Array[String] = ["72:70c2", "72:7089", "72:70a9", "72:5b87", "72:5b8a"]
# GolfHoleState_SelectShotPower.data and GolfHoleState_Shot's bounce tables: (y, x) velocities by
# shot power level.
const SHOT_VELS: Array[int] = [4, 4, 6, 6, 8, 8, 10, 10, 12, 11, 16, 12, 18, 13, 20, 14, 22, 15, 24, 16]
const NORMAL_BOUNCE_VELS: Array[int] = [1, 1, 2, 1, 3, 2, 4, 2, 5, 3, 6, 3, 7, 3, 8, 4, 9, 4, 10, 4]
const TOPSPIN_BOUNCE_VELS: Array[int] = [1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 6, 7, 7, 8, 7, 9, 8, 10, 8]
# GolfHoleState_SpecialTerrain.Hole: the Para-Goom's way into the hole, a step a loop.
const HOLE_X_SIGNS: Array[int] = [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]
const HOLE_X_OFFSETS: Array[int] = [2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 0, 0, 0, 0, 0, 0]
const HOLE_Y_OFFSETS: Array[int] = [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, -2, -2, 2, 2, -1, -1, 2, 2, 0, 0]

## The V-Blank function the last loop installed (wVBlankFunc), which runs once after the loop: the
## fades' and the cutscene's (OTHER, ScreenSim.VBLANK_NONE), the lobby's coins (VBlank_1c9f36) or Golf Wario's tiles
## (VBlank_1c9f7a), and a hole's pin flag (VBlank_1c9d1d), BG attribute (VBlank_1c9e8d), Golf Wario's
## tiles (VBlank_1c9eb3), or stroke number (VBlank_1c9ef1). All but the coins, the pin flag, and OTHER
## clear wGolfVBlankMode; the rest of what they do is drawing.
## In the golf building's menu (Func_1c9fae): the scroll and the OAM (VBlank_1c9fe1), the course's
## scrolling attributes (VBlank_1c9ffa), its palettes (VBlank_1ca033), or its attributes
## (VBlank_1ca056); all but the first clear the mode.
enum VBlankFunc { OTHER, LOBBY_COINS, LOBBY_WARIO, PIN_FLAG, HOLE_ATTR, HOLE_WARIO, STROKE, MENU, MENU_SCROLLING_ATTRS,
		MENU_PALS, MENU_COURSE_ATTRS }
const CLEARS_MODE: Array[int] = [VBlankFunc.LOBBY_WARIO, VBlankFunc.HOLE_ATTR, VBlankFunc.HOLE_WARIO, VBlankFunc.STROKE,
		VBlankFunc.MENU_SCROLLING_ATTRS, VBlankFunc.MENU_PALS, VBlankFunc.MENU_COURSE_ATTRS]

var ram: PackedByteArray = PackedByteArray()
var framesets: Dictionary = {}  # "BB:AAAA" -> PackedByteArray of (frame, duration) pairs and $ff
var holes: Array = []  # each hole's 70 bytes of data
var stroke_numbers: PackedByteArray = PackedByteArray()
## For drawing: the screens loads are ["lobby"], ["hole", hole, palette option], ["clear"]; the hole
## picked, and the pin flag frame VBlank_1c9d1d took (0-3).
var hole_index: int = 0
var pin_flag_frame: int = 0
## WRAM0 as bank 0, shared with the screens given the same Dictionary (MenuScreenSim.wram; with its
## "known" bytes, LevelSim.track_known_ram).
var wram: Dictionary = {}
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
const W_MUSICAL_COIN_FLAGS: int = 0xCA3E
const W_GOLF_BEST_SCORES: int = 0xCA42
const W_TRANSITION_PARAM: int = 0xCEE3
const W_TEMP_BANK: int = 0xC0AC
const GOLF_GFX_1: int = 0x70  # BANK("Golf Gfx 1")
const GOLF_GFX_2: int = 0x71  # BANK("Golf Gfx 2")
## The golf building's best scores (wGolfBestScores, NUM_GOLF_COURSES bytes, as one value high byte
## first), the musical coin flags (the first 4 bytes, read by CheckHasAllMusicalCoinFlags), and
## wTransitionParam, in WRAM0.
var wGolfBestScores: int:
	get:
		return _r0_value(W_GOLF_BEST_SCORES, NUM_GOLF_COURSES)
	set(value):
		_w0_value(W_GOLF_BEST_SCORES, NUM_GOLF_COURSES, value)
var wMusicalCoinFlags: int:
	get:
		return _r0_value(W_MUSICAL_COIN_FLAGS, 4)
	set(value):
		_w0_value(W_MUSICAL_COIN_FLAGS, 4, value)
var wTransitionParam: int:
	get:
		return r0(W_TRANSITION_PARAM)
	set(value):
		w0(W_TRANSITION_PARAM, value)
## The bank of golf's last banked load or OAM table (the screens' loads, PickAndLoadGolfHole,
## Func_1c87db, UpdateGolfWarioAnimation), in WRAM0.
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)


func _init(level_sim: LevelSim = null, shared_wram: Variant = null) -> void:
	super(level_sim)
	ram.resize(RAM_SIZE)
	wram = shared_wram if shared_wram is Dictionary else {}
	if not wram.has(0):
		var bytes := PackedByteArray()
		bytes.resize(0x1000)
		wram[0] = bytes


## golf.json (wl3pc.extract.golf): framesets, holes, and the stroke digits.
func load_data(golf_document: Dictionary) -> void:
	document = golf_document
	framesets.clear()
	for key: String in document.get("framesets", {}):
		var bytes := PackedByteArray()
		for pair: Array in document["framesets"][key]:
			bytes.append(int(pair[0]))
			bytes.append(int(pair[1]))
		bytes.append(0xFF)
		framesets[key] = bytes
	holes.clear()
	for hole: Dictionary in document.get("holes", []):
		holes.append(String(hole["data"]).hex_decode())
	stroke_numbers = String(document.get("stroke_numbers", {}).get("bytes", "")).hex_decode()
	oam_tables = document.get("oam_tables", {})


func loaded() -> bool:
	return not framesets.is_empty() and not holes.is_empty()


# --- RAM access ---

func rb(address: int) -> int:
	return ram[address - RAM_START]


func wb(address: int, value: int) -> void:
	ram[address - RAM_START] = value & 0xFF


func rw(address: int) -> int:
	return ram[address - RAM_START] | (ram[address - RAM_START + 1] << 8)


func ww(address: int, value: int) -> void:
	ram[address - RAM_START] = value & 0xFF
	ram[address - RAM_START + 1] = (value >> 8) & 0xFF


func r0(address: int) -> int:
	return wram[0][address - 0xC000]


func w0(address: int, value: int) -> void:
	wram[0][address - 0xC000] = value & 0xFF
	if wram.has("known"):
		wram["known"][0][address - 0xC000] = 1


func _r0_value(address: int, size: int) -> int:
	var value: int = 0
	for offset: int in size:
		value = (value << 8) | r0(address + offset)
	return value


func _w0_value(address: int, size: int, value: int) -> void:
	for offset: int in size:
		w0(address + offset, value >> (8 * (size - 1 - offset)))


## A byte by bank and address as the traces give it: WRAM0 from $c000, golf RAM (WRAMX bank 1) from
## $d000.
func ram_read(_bank: int, address: int) -> int:
	return r0(address) if address < 0xD000 else rb(address)


func ram_write(_bank: int, address: int, value: int) -> void:
	if address < 0xD000:
		w0(address, value)
	else:
		wb(address, value)


## Whether the byte was written since the known bytes were tracked: WRAM0's as the screens mark them;
## golf RAM is golf's own, written whole by its inits.
func ram_known(_bank: int, address: int) -> bool:
	if address >= 0xD000 or not wram.has("known"):
		return true
	return wram["known"][0][address - 0xC000] != 0


func inc(address: int) -> void:
	wb(address, rb(address) + 1)


func _clear(from: int, to: int) -> void:
	for address: int in range(from, to):
		wb(address, 0)


# --- _GolfStateTable ---

## One game loop of golf: _GolfStateTable by wSubState, then what the V-Blank function it left
## writes before the next loop.
func update() -> void:
	loops += 1
	screen_loads.clear()
	match sim.wSubState:
		0, SST_GOLF_HOLE, SST_GOLF_EXIT, SST_GOLF_CLEAR:  # FastFadeToWhite
			fade(0)
		1:
			init_golf_lobby()
		2, 6, 12:  # SlowFadeFromWhite
			fade(0)
		3:
			handle_golf_lobby()
		5:
			init_golf_hole()
		7:
			handle_golf_hole()
		9:
			sim.return_to_level_from_golf()
			return
		11:
			init_golf_clear_cutscene()
		13:
			update_golf_clear_cutscene()
		_:
			_note("_GolfStateTable sub-state %d" % sim.wSubState)
	if vblank_func in CLEARS_MODE:
		wb(W_GOLF_VBLANK_MODE, 0)


# --- _GolfBuildingStateTable (src/engine/golf/building/state_table.asm) ---

## One game loop of the golf building (ST_GOLF_BUILDING): _GolfBuildingStateTable by wSubState, then
## what the V-Blank function it left writes before the next loop.
func update_building() -> void:
	loops += 1
	screen_loads.clear()
	match sim.wSubState:
		0, SST_GOLF_HOLE:  # FastFadeToWhite
			fade(0)
		1:
			func_1c8586()
		2, 6:  # SlowFadeFromWhite
			fade(0)
		3:
			func_1c86dd()
		5:
			init_golf_hole()
		7:
			handle_golf_hole()
		SST_GOLF_BUILDING_EXIT:
			return_to_map()
			return
		_:
			_note("_GolfBuildingStateTable sub-state %d" % sim.wSubState)
	if vblank_func in CLEARS_MODE:
		wb(W_GOLF_VBLANK_MODE, 0)


## ReturnToMap (src/home/return_level.asm): wTransitionParam TRANSITION_RETURN_TO_MAP, then
## StartOverworldState: the map's state from its first sub-state.
func return_to_map() -> void:
	wTransitionParam = TRANSITION_RETURN_TO_MAP
	sim.wState = ST_OVERWORLD
	sim.wSubState = 0


# --- objects and Golf Wario's animation (src/home/load_golf_sprite.asm) ---

## UpdateGolfObjectAnimation: the object at `obj` (its duration first) counts down its duration,
## then takes the next (frame, duration) of `frameset`; at the end it restarts with the first pair,
## keeping the last frame in wGolfAnimLastFrame. Whether it restarted.
func update_animation(obj: int, frameset: String) -> bool:
	var duration: int = rb(obj + OBJ_DURATION)
	wb(obj + OBJ_DURATION, duration - 1)
	if duration != 0:
		return false
	if not framesets.has(frameset):
		_note("golf frameset %s not extracted" % frameset)
		return false
	var bytes: PackedByteArray = framesets[frameset]
	var offset: int = rb(obj + OBJ_FRAMESET_OFFSET)
	if offset + 1 >= bytes.size() or bytes[offset] == 0xFF:
		wb(W_GOLF_ANIM_LAST_FRAME, rb(obj + OBJ_CURRENT_FRAME))
		wb(obj + OBJ_CURRENT_FRAME, bytes[0])
		wb(obj + OBJ_FRAMESET_OFFSET, 2)
		wb(obj + OBJ_DURATION, bytes[1])
		return true
	wb(obj + OBJ_CURRENT_FRAME, bytes[offset])
	wb(obj + OBJ_FRAMESET_OFFSET, offset + 2)
	wb(obj + OBJ_DURATION, bytes[offset + 1])
	return false


## An object's animation, its frame shown, and its sprite (LoadGolfSprite).
func _animate(obj: int, frameset: String) -> bool:
	var finished: bool = update_animation(obj, frameset)
	wb(obj + OBJ_FRAME, rb(obj + OBJ_CURRENT_FRAME))
	load_golf_sprite(obj)
	return finished


## LoadGolfSprite: the object's sprite (its y, x, frame, and attributes) from the OAM table in
## wGolfOAMPtr, read in `bank`.
func load_golf_sprite(obj: int, bank: int = GOLF_CODE_BANK) -> void:
	load_sprite("%02x:%04x" % [bank, (rb(W_GOLF_OAM_PTR) << 8) | rb(W_GOLF_OAM_PTR + 1)], rb(obj + OBJ_FRAME),
			rb(obj + OBJ_Y_COORD), rb(obj + OBJ_X_COORD), rb(obj + OBJ_FRAME + 1))


func _set_oam_ptr(pointer: int) -> void:
	wb(W_GOLF_OAM_PTR, pointer >> 8)
	wb(W_GOLF_OAM_PTR + 1, pointer)


## UpdateGolfWarioAnimation: Golf Wario's OAM table and frameset by state and direction; a finished
## animation holds its last frame in some states (HoldGolfWarioLastFrame).
func update_golf_wario_animation() -> void:
	var state: int = rb(W_GOLF_WARIO + OBJ_STATE)
	if state >= NUM_GOLF_WARIO_STATES:
		_note("UpdateGolfWarioAnimation state %d" % state)
		return
	wTempBank = WARIO_OAM_BANKS[state]
	_set_oam_ptr(WARIO_OAM[state])
	var frameset: String = WARIO_FRAMESETS_LEFT[state] if rb(W_GOLF_WARIO_DIR) != 0 else WARIO_FRAMESETS_RIGHT[state]
	var finished: bool = update_animation(W_GOLF_WARIO, frameset)
	wb(W_HAS_GOLF_WARIO_ANIMATION_FINISHED, 1 if finished else 0)
	if finished:
		hold_golf_wario_last_frame()
	wb(W_GOLF_WARIO + OBJ_FRAME, rb(W_GOLF_WARIO + OBJ_CURRENT_FRAME))
	load_golf_sprite(W_GOLF_WARIO, WARIO_OAM_BANKS[state])


## HoldGolfWarioLastFrame: charging, attacking, missing, and turning end on their last frame and
## count up wGolfCounter.
func hold_golf_wario_last_frame() -> void:
	var state: int = rb(W_GOLF_WARIO + OBJ_STATE)
	if state not in [GOLF_WARIO_CHARGING, GOLF_WARIO_ATTACKING_1, GOLF_WARIO_MISSING, GOLF_WARIO_TURNING]:
		return
	inc(W_GOLF_COUNTER)
	wb(W_GOLF_WARIO + OBJ_CURRENT_FRAME, rb(W_GOLF_ANIM_LAST_FRAME))


## LoadGolfWarioStateGfx: the bank and pointer of Golf Wario's tiles, for V-Blank to load.
func load_golf_wario_state_gfx() -> void:
	var state: int = rb(W_GOLF_WARIO + OBJ_STATE)
	if state >= NUM_GOLF_WARIO_STATES:
		_note("LoadGolfWarioStateGfx state %d" % state)
		return
	wb(W_GOLF_WARIO_TILES_BANK, WARIO_GFX_BANKS[state])
	wb(W_GOLF_WARIO_TILES_PTR, WARIO_GFX[state] >> 8)
	wb(W_GOLF_WARIO_TILES_PTR + 1, WARIO_GFX[state])


func _reset_wario_animation() -> void:
	wb(W_GOLF_WARIO + OBJ_DURATION, 0)
	wb(W_GOLF_WARIO + OBJ_FRAMESET_OFFSET, 0)


# --- the lobby (src/engine/golf/lobby.asm) ---

## InitGolfLobby: from the level (w1d800 0) SaveBackupVRAM, then the golf RAM after the menu's three
## bytes cleared, the price by the treasures, Golf Wario at the door (or out of the pipe after a
## hole), the coins shown, and whether they are enough.
func init_golf_lobby() -> void:
	clear_virtual_oam()
	if rb(W1D800) == 0:
		sim.save_backup_vram()  # from the level: its scroll and palettes
	wb(W1D800, 2)
	sim.wRoomAnimatedTilesEnabled = 0
	_clear(W_PREDETERMINED_GOLF_HOLE, RAM_START + RAM_SIZE)
	load_temp_pals(_gfx_bytes("palettes", "72:61cf"), _gfx_bytes("palettes", "72:620f"))
	wTempBank = GOLF_GFX_2  # .LoadGolfLobby
	var high: int = sim.wNumCollectedTreasures >> 8
	var low: int = sim.wNumCollectedTreasures & 0xFF
	if high != 0 or low >= GOLF_TREASURES_TIER_3:
		wb(W_GOLF_PRICE, GOLF_PRICE_TIER_3)
	elif low >= GOLF_TREASURES_TIER_2:
		wb(W_GOLF_PRICE, GOLF_PRICE_TIER_2)
	else:
		wb(W_GOLF_PRICE, GOLF_PRICE_TIER_1)
	if rb(W_GOLF_MENU_OPTION) == 0:
		wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_WAITING)
		wb(W_GOLF_WARIO_Y_POS, SCREEN_HEIGHT_PX)
		wb(W_GOLF_WARIO_X_POS, 0x38)
	else:
		wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_GOING_IN_PIPE)
		wb(W_GOLF_WARIO_Y_POS, 0xA0)
		wb(W_GOLF_WARIO_X_POS, 0x80)
		wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_EXIT_PIPE)
	handle_golf_lobby_wario_sprite()
	wb(W_GOLF_MENU_OPTION, 0)
	wb(W_GOLF_NUM_COINS, sim.wNumCoins >> 8)
	wb(W_GOLF_NUM_COINS + 1, sim.wNumCoins)
	if (sim.wNumCoins >> 8) == 0 and (sim.wNumCoins & 0xFF) < rb(W_GOLF_PRICE):
		wb(W_GOLF_OBJ_4 + OBJ_STATE, COININFO_NOT_ENOUGH_COINS)
	wb(W_GOLF_VBLANK_MODE, 1)
	golf_lobby_vblank()
	sim.wSCY = 0
	sim.wSCX = 0
	screen_loads.append(["lobby"])
	sim.wSubState = byte(sim.wSubState + 1)


## HandleGolfLobby
func handle_golf_lobby() -> void:
	handle_golf_lobby_states()
	update_golf_lobby_animations()
	handle_golf_lobby_wario_sprite()
	clear_unused_virtual_oam()
	golf_lobby_vblank()


func update_golf_lobby_animations() -> void:
	_set_oam_ptr(OAM_1CB2D3)
	wb(W_GOLF_OBJ_1 + OBJ_Y_COORD, 0x28)
	wb(W_GOLF_OBJ_1 + OBJ_X_COORD, 0x24)
	_animate(W_GOLF_OBJ_1, "72:73b3")
	wb(W_GOLF_OBJ_3 + OBJ_Y_COORD, 0x2D)
	wb(W_GOLF_OBJ_3 + OBJ_X_COORD, 0x8C)
	_animate(W_GOLF_OBJ_3, "72:73c4")
	wb(W_GOLF_OBJ_5 + OBJ_Y_COORD, 0x60)
	wb(W_GOLF_OBJ_5 + OBJ_X_COORD, 0x28)
	_animate(W_GOLF_OBJ_5, "72:73d7")
	if rb(W_GOLF_OBJ_4 + OBJ_STATE) != COININFO_SHOW_MESSAGE:
		return
	wb(W_GOLF_OBJ_4 + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_OBJ_4 + OBJ_X_COORD, 0x38)
	if update_animation(W_GOLF_OBJ_4, "72:73d1" if sim.wLanguage != 0 else "72:73d4"):
		wb(W_GOLF_OBJ_4 + OBJ_STATE, COININFO_NOT_ENOUGH_COINS)
		return
	wb(W_GOLF_OBJ_4 + OBJ_FRAME, rb(W_GOLF_OBJ_4 + OBJ_CURRENT_FRAME))
	load_golf_sprite(W_GOLF_OBJ_4)


func handle_golf_lobby_wario_sprite() -> void:
	wb(W_GOLF_WARIO + OBJ_Y_COORD, rb(W_GOLF_WARIO_Y_POS))
	wb(W_GOLF_WARIO + OBJ_X_COORD, rb(W_GOLF_WARIO_X_POS))
	update_golf_wario_animation()
	load_golf_wario_state_gfx()


## GolfLobbyVBlank: VBlank_1c9f36 (the coins) or VBlank_1c9f7a (Golf Wario's tiles, which clears
## the mode).
func golf_lobby_vblank() -> void:
	match rb(W_GOLF_VBLANK_MODE):
		0:
			vblank_func = VBlankFunc.LOBBY_COINS
		1:
			vblank_func = VBlankFunc.LOBBY_WARIO
		_:
			_note("GolfLobbyVBlank mode %d" % rb(W_GOLF_VBLANK_MODE))


func _start_wario(state: int, mode: int) -> void:
	_reset_wario_animation()
	wb(W_GOLF_WARIO + OBJ_STATE, state)
	wb(W_GOLF_VBLANK_MODE, mode)


func handle_golf_lobby_states() -> void:
	match rb(W_GOLF_LOBBY_STATE):
		GOLFLOBBYSTATE_WAIT_INPUT:
			_lobby_waiting_input()
		GOLFLOBBYSTATE_WALK_RIGHT:
			_lobby_walking_right()
		GOLFLOBBYSTATE_WALK_LEFT:
			_lobby_walking_left()
		GOLFLOBBYSTATE_ENTER_PIPE:
			_lobby_entering_pipe()
		GOLFLOBBYSTATE_ENTER_DOOR:
			_lobby_entering_door()
		GOLFLOBBYSTATE_EXIT_PIPE:
			_lobby_exiting_pipe()
		_:
			_note("HandleGolfLobbyStates state %d" % rb(W_GOLF_LOBBY_STATE))


func _lobby_waiting_input() -> void:
	var pressed: int = sim.wJoypadPressed
	var x: int = rb(W_GOLF_WARIO + OBJ_X_COORD)
	if (pressed & WarioRam.PAD_DOWN) != 0:
		if x != 0x78:
			return
		if rb(W_GOLF_OBJ_4 + OBJ_STATE) != 0:
			wb(W_GOLF_OBJ_4 + OBJ_STATE, COININFO_SHOW_MESSAGE)
			wb(W_GOLF_OBJ_4 + OBJ_DURATION, 0)
			wb(W_GOLF_OBJ_4 + OBJ_FRAMESET_OFFSET, 0)
			return
		sim.wNumCoins = _bcd_sub_word(sim.wNumCoins, rb(W_GOLF_PRICE))
		wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_GOING_IN_PIPE)
		wb(W_GOLF_VBLANK_MODE, 1)
		wb(W_GOLF_WARIO_X_POS, 0x80)
		wb(W_GOLF_COUNTER, 0)
		_reset_wario_animation()
		wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_ENTER_PIPE)
	elif (pressed & WarioRam.PAD_UP) != 0:
		if x != 0x38:
			return
		wb(W_GOLF_WARIO_DIR, 0)
		_start_wario(GOLF_WARIO_TURNING, 1)
		wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_ENTER_DOOR)
	elif (pressed & WarioRam.PAD_RIGHT) != 0:
		if x >= 0x78:
			return
		wb(W_GOLF_WARIO_DIR, 0)
		_start_wario(GOLF_WARIO_TURNING, 1)
		wb(W_GOLF_WARIO_Y_VEL, 4)
		wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_WALK_RIGHT)
	elif (pressed & WarioRam.PAD_LEFT) != 0:
		if x < 0x78:
			return
		_start_wario(GOLF_WARIO_TURNING, 1)
		wb(W_GOLF_WARIO_DIR, 1)
		wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_WALK_LEFT)


## The price off the coins as `sub c; daa` and `sbc 0` do it in BCD.
static func _bcd_sub_word(coins: int, price: int) -> int:
	var low: int = coins & 0xFF
	var result: int = low - price
	var carry: bool = result < 0
	var half: bool = (low & 0x0F) < (price & 0x0F)
	result &= 0xFF
	if half:
		result = (result - 0x06) & 0xFF
	if carry:
		result = (result - 0x60) & 0xFF
	var high: int = ((coins >> 8) - (1 if carry else 0)) & 0xFF
	return (high << 8) | result


func _lobby_walk_turned(right: bool) -> bool:
	var counter: int = rb(W_GOLF_COUNTER)
	if counter == 0:
		return true
	if counter >= 2:
		return false
	inc(W_GOLF_COUNTER)
	if right:
		wb(W_GOLF_WARIO_DIR, 0)
	_start_wario(GOLF_WARIO_WALKING, 1)
	return true


func _lobby_walking_right() -> void:
	if _lobby_walk_turned(true):
		return
	if rb(W_GOLF_WARIO_X_POS) >= 0x58:
		# .DoJumpRight
		var vel: int = rb(W_GOLF_WARIO_Y_VEL)
		inc(W_GOLF_COUNTER)
		if (rb(W_GOLF_COUNTER) & 1) == 0:
			wb(W_GOLF_WARIO_Y_VEL, vel - 1)
		wb(W_GOLF_WARIO_Y_POS, rb(W_GOLF_WARIO_Y_POS) - vel)
		if vel >= 0xF0 and rb(W_GOLF_WARIO_Y_POS) >= 0x80:
			wb(W_GOLF_WARIO_Y_POS, 0x80)
	if rb(W_GOLF_WARIO_X_POS) < 0x78:
		inc(W_GOLF_WARIO_X_POS)
		return
	wb(W_GOLF_WARIO_Y_POS, 0x80)
	wb(W_GOLF_WARIO_X_POS, 0x78)
	_lobby_waiting_again()


func _lobby_waiting_again() -> void:
	wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_WAITING)
	wb(W_GOLF_VBLANK_MODE, 1)
	wb(W_GOLF_COUNTER, 0)
	_reset_wario_animation()
	wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_WAIT_INPUT)


func _lobby_walking_left() -> void:
	if _lobby_walk_turned(false):
		return
	if rb(W_GOLF_WARIO_Y_POS) < SCREEN_HEIGHT_PX and rb(W_GOLF_WARIO_X_POS) < 0x64:
		wb(W_GOLF_WARIO_Y_POS, rb(W_GOLF_WARIO_Y_POS) + 2)  # .DoJumpLeft
	if rb(W_GOLF_WARIO_X_POS) != 0x38:
		wb(W_GOLF_WARIO_X_POS, rb(W_GOLF_WARIO_X_POS) - 1)
		return
	wb(W_GOLF_WARIO_Y_POS, SCREEN_HEIGHT_PX)
	wb(W_GOLF_WARIO_X_POS, 0x38)
	_lobby_waiting_again()


func _lobby_entering_pipe() -> void:
	if rb(W_GOLF_COUNTER) == 0:
		inc(W_GOLF_COUNTER)
		wb(W_GOLF_NUM_COINS + 1, sim.wNumCoins)
		wb(W_GOLF_NUM_COINS, sim.wNumCoins >> 8)
	if rb(W_GOLF_WARIO_Y_POS) < 0xB0:
		inc(W_GOLF_WARIO_Y_POS)
		return
	sim.wSubState = SST_GOLF_HOLE


func _lobby_entering_door() -> void:
	var counter: int = rb(W_GOLF_COUNTER)
	if counter == 0:
		return
	if counter == 1:
		inc(W_GOLF_COUNTER)
		_start_wario(GOLF_WARIO_ENTERING_DOOR, 1)
		return
	if counter < 28:
		inc(W_GOLF_COUNTER)
		return
	wb(W1D800, 0)
	wb(W_GOLF_MENU_OPTION, 0)
	sim.wSubState = SST_GOLF_EXIT


func _lobby_exiting_pipe() -> void:
	if rb(W_GOLF_WARIO_Y_POS) != 0x80:
		wb(W_GOLF_WARIO_Y_POS, rb(W_GOLF_WARIO_Y_POS) - 1)
		return
	wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_WAITING)
	wb(W_GOLF_WARIO_X_POS, 0x78)
	wb(W_GOLF_VBLANK_MODE, 1)
	wb(W_GOLF_COUNTER, 0)
	_reset_wario_animation()
	wb(W_GOLF_LOBBY_STATE, GOLFLOBBYSTATE_WAIT_INPUT)


# --- the clear cutscene (lobby.asm) ---

## InitGolfClearCutscene: all golf RAM cleared, the clear's object below its place.
func init_golf_clear_cutscene() -> void:
	clear_virtual_oam()
	_clear(RAM_START, RAM_START + RAM_SIZE)
	load_temp_pals(_gfx_bytes("palettes", "72:624f"), _gfx_bytes("palettes", "72:634f"))
	wTempBank = GOLF_GFX_2  # .LoadCutsceneGfx's last
	wb(W_GOLF_OBJ_1 + OBJ_Y_COORD, 0x70)
	update_golf_clear_cutscene_animation()
	vblank_func = VBlankFunc.OTHER  # VBlank_1c84e0
	sim.wSCY = 0
	sim.wSCX = 0
	screen_loads.append(["clear"])
	sim.wSubState = byte(sim.wSubState + 1)


func update_golf_clear_cutscene() -> void:
	if rb(W_GOLF_OBJ_1 + OBJ_STATE) == 0:
		if rb(W_GOLF_OBJ_1 + OBJ_Y_COORD) == 0x50:
			wb(W_GOLF_COUNTER, 0)
			wb(W_GOLF_OBJ_1 + OBJ_FRAMESET_OFFSET, 0)
			wb(W_GOLF_OBJ_1 + OBJ_STATE, 1)
		else:
			inc(W_GOLF_COUNTER)
			if (rb(W_GOLF_COUNTER) & 3) == 0:
				wb(W_GOLF_OBJ_1 + OBJ_Y_COORD, rb(W_GOLF_OBJ_1 + OBJ_Y_COORD) - 1)
	elif rb(W_GOLF_COUNTER) < 0x40:
		inc(W_GOLF_COUNTER)
	else:
		sim.wSubState = SST_GOLF_EXIT
		return
	update_golf_clear_cutscene_animation()


func update_golf_clear_cutscene_animation() -> void:
	_set_oam_ptr(OAM_1CB3E0)
	update_animation(W_GOLF_OBJ_1, "72:75cc" if rb(W_GOLF_OBJ_1 + OBJ_STATE) != 0 else "72:75cf")
	wb(W_GOLF_OBJ_1 + OBJ_FRAME, rb(W_GOLF_OBJ_1 + OBJ_CURRENT_FRAME))
	wb(W_GOLF_OBJ_1 + OBJ_X_COORD, 0x58)
	load_golf_sprite(W_GOLF_OBJ_1)
	clear_unused_virtual_oam()


# --- the golf building's menu (src/engine/golf/building/building.asm) ---

# Func_1c87db.data: each course's attributes for the menu's middle rows (labelled
# GolfBuildingCourse1Tilemap and on, bank $71) and palettes (bank $72).
const COURSE_ATTRS: Array[String] = ["71:48e0", "71:49c0", "71:4aa0", "71:4b80"]
const COURSE_PALS: Array[String] = ["72:624f", "72:628f", "72:62cf", "72:630f"]
const COURSE_SCROLLING_ATTRS: String = "71:4800"  # GolfBuildingCourseScrollingAttrmap
const MENU_OBJ_PALS: String = "72:634f"  # Pals_1ca34f
const COURSE_ROWS_SIZE: int = 7 * 32
# GetGolfCourseTargetSCX.scroll_x and Func_1c8911.first_golf_holes (GOLF_HOLE_00 + 1 and on), by course.
const COURSE_TARGET_SCX: Array[int] = [0xCC, 0x0C, 0x4C, 0x8C]
const COURSE_FIRST_HOLES: Array[int] = [0x01, 0x06, 0x0B, 0x10]
# Func_1c86f8.framesets: Golf Wario by course.
const MENU_WARIO_FRAMESETS: Array[String] = ["72:75d8", "72:75db", "72:75de", "72:75e1"]
# The menu's HDMA (Func_2c30) to VRAM bank 1's BG map 0 from row 6, 7 rows (13: 14 blocks of 16 bytes).
const MENU_HDMA_DEST_HIGH: int = 0x18
const MENU_HDMA_DEST_LOW: int = 0xC0
const MENU_HDMA_LENGTH: int = 0x0D


## Func_1c8586: the menu's set-up. The room animation's tiles (set $0f) start; from the map (w1d800 0)
## SaveBackupVRAM; on the first course (wGolfMenuOption 0) w1d800 is 1; golf RAM after the menu's two
## bytes cleared; whether every musical coin is got; the screen (Func_1c8604), its palettes to the
## temporary ones, the coins shown, the sprites, and the V-Blank function; the scroll at the course.
func func_1c8586() -> void:
	clear_virtual_oam()
	sim.wAnimatedTilesFrameDuration = 0x08
	sim.wAnimatedTilesGfx = 0x0F
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	sim.wRoomAnimatedTilesEnabled = 1
	if rb(W1D800) == 0:
		sim.save_backup_vram()
	if rb(W_GOLF_MENU_OPTION) == 0:
		wb(W1D800, 1)
	_clear(W_PREDETERMINED_GOLF_HOLE, RAM_START + RAM_SIZE)
	wb(W_HAS_ALL_MUSICAL_COIN_FLAGS, 1 if has_all_musical_coin_flags() else 0)
	func_1c8604()
	load_temp_pals(ram.slice(W1DB00 - RAM_START, W1DB00 - RAM_START + 0x40), _gfx_bytes("palettes", MENU_OBJ_PALS))
	wb(W_GOLF_NUM_COINS, sim.wNumCoins >> 8)
	wb(W_GOLF_NUM_COINS + 1, sim.wNumCoins)
	func_1c86f8()
	func_1c9fae()
	sim.wSCY = 0
	sim.wSCX = rb(W_GOLF_MENU_TARGET_SCX)
	screen_loads.append(["menu"])
	sim.wSubState = byte(sim.wSubState + 1)


## CheckHasAllMusicalCoinFlags (src/home/musical_coin.asm): the first 25 bits of wMusicalCoinFlags.
func has_all_musical_coin_flags() -> bool:
	for bit: int in 25:
		if (r0(W_MUSICAL_COIN_FLAGS + (bit >> 3)) & (1 << (bit & 7))) == 0:
			return false
	return true


## Func_1c8604: what it keeps in RAM: the course (wGolfMenuOption), its attributes and palettes
## (Func_1c87db), and its scroll (GetGolfCourseTargetSCX); the tiles, the maps, and the best scores'
## digits are VRAM (GolfVram.load_menu).
func func_1c8604() -> void:
	wb(W_GOLF_COURSE, rb(W_GOLF_MENU_OPTION))
	func_1c87db()
	get_golf_course_target_scx()


## Func_1c87db: the course's attributes (7 rows) into wGolfCourseTileMap and its palettes into w1db00.
func func_1c87db() -> void:
	wTempBank = GOLF_GFX_2
	var course: int = rb(W_GOLF_COURSE) & 3
	_copy_gfx("raw", COURSE_ATTRS[course], W_GOLF_COURSE_TILE_MAP, COURSE_ROWS_SIZE)
	_copy_gfx("palettes", COURSE_PALS[course], W1DB00, 0x40)


func get_golf_course_target_scx() -> void:
	wb(W_GOLF_MENU_TARGET_SCX, COURSE_TARGET_SCX[rb(W_GOLF_COURSE) & 3])


## LoadPalsToTempPals1 and LoadPalsToTempPals2 (src/home/load_pals.asm): 8 palettes each into WRAM0's
## wTempPals1 and wTempPals2, which the fades take the screen to.
func load_temp_pals(pals_1: PackedByteArray, pals_2: PackedByteArray) -> void:
	if pals_1.size() < 0x40 or pals_2.size() < 0x40:
		_note("golf palettes not extracted")
		return
	for offset: int in 0x40:
		w0(W_TEMP_PALS_1 + offset, pals_1[offset])
		w0(W_TEMP_PALS_2 + offset, pals_2[offset])


func _gfx_bytes(kind: String, key: String) -> PackedByteArray:
	return String(document.get("gfx", {}).get(kind, {}).get(key, "")).hex_decode()


func _copy_gfx(kind: String, key: String, to: int, size: int) -> void:
	_copy_gfx_from(kind, key, 0, to, size)


func _copy_gfx_from(kind: String, key: String, from: int, to: int, size: int) -> void:
	var bytes: PackedByteArray = _gfx_bytes(kind, key)
	if bytes.size() < from + size:
		_note("golf %s %s not extracted" % [kind, key])
		return
	for offset: int in size:
		wb(to + offset, bytes[from + offset])


## Func_1c86dd: the menu's loop: its state (Func_1c882b), the sprites, and on the way out (B: sub-state
## 8) w1d800 and the course cleared; then the coins' digits and the V-Blank function.
func func_1c86dd() -> void:
	func_1c882b()
	func_1c86f8()
	clear_unused_virtual_oam()
	if sim.wSubState == SST_GOLF_BUILDING_EXIT:
		wb(W1D800, 0)
		wb(W_GOLF_MENU_OPTION, 0)
	func_1c9fae()


## Func_1c86f8: the menu's sprites from OAM_1cb3e0: the title, the coins, the price; while it waits
## for input (w1dc00 0) the course's frame, Golf Wario by course (his animation restarted each loop),
## and the Para-Goom.
func func_1c86f8() -> void:
	_set_oam_ptr(OAM_1CB3E0)
	wb(W_GOLF_OBJ_1 + OBJ_Y_COORD, 0x42)
	wb(W_GOLF_OBJ_1 + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OBJ_1, "72:759b")
	wb(W_GOLF_OBJ_3 + OBJ_Y_COORD, 0x2A)
	wb(W_GOLF_OBJ_3 + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OBJ_3, "72:7598")
	wb(W_GOLF_OBJ_4 + OBJ_Y_COORD, 0xA0)  # SCREEN_WIDTH_PX
	wb(W_GOLF_OBJ_4 + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OBJ_4, "72:759e")
	if rb(W1DC00) != 0:
		return
	wb(W_GOLF_OBJ_5 + OBJ_Y_COORD, 0x76)
	wb(W_GOLF_OBJ_5 + OBJ_X_COORD, 0x6C)
	_animate(W_GOLF_OBJ_5, "72:75a1")
	_reset_wario_animation()
	wb(W_GOLF_WARIO + OBJ_Y_COORD, 0x76)
	wb(W_GOLF_WARIO + OBJ_X_COORD, 0x6C)
	_animate(W_GOLF_WARIO, MENU_WARIO_FRAMESETS[rb(W_GOLF_MENU_OPTION) & 3])
	wb(W_GOLF_PARA_GOOM + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_PARA_GOOM + OBJ_X_COORD, 0x55)
	_animate(W_GOLF_PARA_GOOM, "72:75c3")


## Func_1c882b: the menu's state (w1dc00): waiting for input, scrolling, the scroll's end, paying.
func func_1c882b() -> void:
	match rb(W1DC00):
		0:
			_menu_wait_input()
		1:
			_menu_scroll()
		2:  # Func_1c8907
			wb(W1DC00, 0)
			wb(W_GOLF_VBLANK_MODE, 3)
		3:
			_menu_pay()
		_:
			_note("Func_1c882b state %d" % rb(W1DC00))


## Func_1c8837: A pays the course's price if the coins are enough (a sound otherwise), B leaves (sub-state
## 8), right and left scroll to the next course (the fourth only with every musical coin, else they
## wrap from the third).
func _menu_wait_input() -> void:
	var pressed: int = sim.wJoypadPressed
	if (pressed & WarioRam.PAD_A) != 0:
		if (sim.wNumCoins >> 8) == 0 and (sim.wNumCoins & 0xFF) < GOLF_BUILDING_PRICE:
			return
		sim.wNumCoins = _bcd_sub_word(sim.wNumCoins, GOLF_BUILDING_PRICE)
		wb(W1DC00, 3)
		return
	if (pressed & WarioRam.PAD_B) != 0:
		sim.wSubState = SST_GOLF_BUILDING_EXIT
		return
	var option: int = rb(W_GOLF_MENU_OPTION)
	var all_coins: bool = rb(W_HAS_ALL_MUSICAL_COIN_FLAGS) != 0
	if (pressed & WarioRam.PAD_RIGHT) != 0:
		wb(W_GOLF_MENU_SCROLLING_DIR, 0)
		if option == GOLF_COURSE_4 or (option == GOLF_COURSE_3 and not all_coins):
			wb(W_GOLF_MENU_OPTION, 0)
		else:
			wb(W_GOLF_MENU_OPTION, option + 1)
	elif (pressed & WarioRam.PAD_LEFT) != 0:
		wb(W_GOLF_MENU_SCROLLING_DIR, 1)
		if option != 0:
			wb(W_GOLF_MENU_OPTION, option - 1)
		else:
			wb(W_GOLF_MENU_OPTION, GOLF_COURSE_4 if all_coins else GOLF_COURSE_3)
	else:
		return
	# .scrolling
	wb(W1DC00, 1)
	wb(W_GOLF_VBLANK_MODE, 1)
	wb(W_GOLF_COURSE, rb(W_GOLF_MENU_OPTION))
	func_1c87db()
	_copy_gfx("raw", COURSE_SCROLLING_ATTRS, W_GOLD_BUILDING_COURSE_ATTR_MAP, COURSE_ROWS_SIZE)
	get_golf_course_target_scx()


## Func_1c88dc: wSCX 4 pixels a loop toward the course's, then the scroll's end (state 2, the palettes'
## V-Blank function).
func _menu_scroll() -> void:
	var target: int = rb(W_GOLF_MENU_TARGET_SCX)
	if sim.wSCX == target:
		wb(W1DC00, 2)
		wb(W_GOLF_VBLANK_MODE, 2)
		return
	sim.wSCX = byte(sim.wSCX + (4 if rb(W_GOLF_MENU_SCROLLING_DIR) == 0 else -4))


## Func_1c8911: the coins shown count down one a loop for $32 loops (BCD), then the course's first hole
## and the way to it (sub-state 4).
func _menu_pay() -> void:
	if rb(W_GOLF_COUNTER) >= 0x32:
		wb(W_PREDETERMINED_GOLF_HOLE, COURSE_FIRST_HOLES[rb(W_GOLF_MENU_OPTION) & 3])
		sim.wSubState = SST_GOLF_HOLE
		return
	inc(W_GOLF_COUNTER)
	var coins: int = _bcd_sub_word((rb(W_GOLF_NUM_COINS) << 8) | rb(W_GOLF_NUM_COINS + 1), 1)
	wb(W_GOLF_NUM_COINS, coins >> 8)
	wb(W_GOLF_NUM_COINS + 1, coins)


## Func_1c9fae: the coins' three digits as the first three sprites' frames (Func_1c9fbd), then the
## V-Blank function by wGolfVBlankMode; the attributes' two set the HDMA they run (wdc11, w1dc13).
func func_1c9fae() -> void:
	wVirtualOAM[2] = byte(rb(W_GOLF_NUM_COINS) * 2 + 0xA0)
	wVirtualOAM[6] = byte((rb(W_GOLF_NUM_COINS + 1) >> 4) * 2 + 0xA0)
	wVirtualOAM[10] = byte((rb(W_GOLF_NUM_COINS + 1) & 0x0F) * 2 + 0xA0)
	match rb(W_GOLF_VBLANK_MODE):
		0:
			vblank_func = VBlankFunc.MENU
		1, 3:
			wb(WDC11, MENU_HDMA_DEST_HIGH)
			wb(WDC11 + 1, MENU_HDMA_DEST_LOW)
			wb(W1DC13, MENU_HDMA_LENGTH)
			vblank_func = VBlankFunc.MENU_SCROLLING_ATTRS if rb(W_GOLF_VBLANK_MODE) == 1 else VBlankFunc.MENU_COURSE_ATTRS
		2:
			vblank_func = VBlankFunc.MENU_PALS
		_:
			_note("Func_1c9fae V-Blank mode %d" % rb(W_GOLF_VBLANK_MODE))


# --- a hole (src/engine/golf/hole.asm) ---

## InitGolfHole: the hole RAM cleared, the window placed, the hole picked and loaded, Golf Wario
## and the Para-Goom on the tee.
func init_golf_hole() -> void:
	clear_virtual_oam()
	sim.wRoomAnimatedTilesEnabled = 0
	_clear(W_GOLF_HOLE_RAM_START, RAM_START + RAM_SIZE)
	load_temp_pals(_gfx_bytes("palettes", "%02x:%04x" % [GOLF_CODE_BANK, 0x608F + 0x40 * (rb(W_GOLF_MENU_OPTION) & 3)]),
			_gfx_bytes("palettes", "72:618f"))
	sim.wSCY = 0
	sim.wSCX = 0
	wb(W_GOLF_WX, 159 + WX_OFS)
	pick_and_load_golf_hole()
	show_golf_hole_flag_and_par()
	set_up_golf_hole_objects()
	func_1c9cf9()
	screen_loads.append(["hole", hole_index, rb(W_GOLF_MENU_OPTION)])
	sim.wSubState = byte(sim.wSubState + 1)


## PickAndLoadGolfHole: the predetermined hole, or rDIV modulo the tier's count of holes (the tier
## by the treasures), its 70 bytes into wGolfHoleData, and the hole's x position.
func pick_and_load_golf_hole() -> void:
	wTempBank = GOLF_GFX_1
	var hole: int
	if rb(W_PREDETERMINED_GOLF_HOLE) != 0:
		hole = rb(W_PREDETERMINED_GOLF_HOLE) - 1
	else:
		var high: int = sim.wNumCollectedTreasures >> 8
		var low: int = sim.wNumCollectedTreasures & 0xFF
		var tier: int = GOLF_HOLE_TIER_1
		if high != 0 or low >= GOLF_TREASURES_TIER_3:
			tier = GOLF_HOLE_TIER_3
		elif low >= GOLF_TREASURES_TIER_2:
			tier = GOLF_HOLE_TIER_2
		wb(W_GOLF_HOLE_TIER, tier)
		hole = sim.read_div(RDIV_PICK_GOLF_HOLE) % tier
	if hole >= holes.size():
		_note("golf hole %d not extracted" % hole)
		return
	hole_index = hole
	var data: PackedByteArray = holes[hole]
	for index: int in data.size():
		wb(W_GOLF_HOLE_DATA + index, data[index])
	wb(W_GOLF_HOLE_HOLE_X_POS, rb(W1DB82))
	wb(W_GOLF_HOLE_HOLE_X_POS + 1, rb(W1DB82 + 1))


## ShowGolfHoleFlagAndPar: the most strokes allowed (the par in a level, 19 over it in the golf
## building), and the stroke number; the rest is tiles.
func show_golf_hole_flag_and_par() -> void:
	if rb(W1D800) == 2:
		wb(W_GOLF_MAX_STROKES, rb(W_GOLF_PAR))
	else:
		wb(W_GOLF_MAX_STROKES, rb(W_GOLF_PAR) + MAX_GOLF_COURSE_STROKES)
	print_golf_stroke_number()


## PrintGolfStrokeNumber: the stroke's two digits' tiles (two tiles each) into w1db90.
func print_golf_stroke_number() -> void:
	var stroke: int = rb(W_GOLF_STROKE)
	var tens: int = 0
	var ones: int = stroke
	while ones >= 10:
		ones -= 10
		tens += 1
	for index: int in 32:
		wb(W1DB90 + index, _stroke_digit_byte(tens * 32 + index))
		wb(W1DB90 + 32 + index, _stroke_digit_byte(ones * 32 + index))


func _stroke_digit_byte(offset: int) -> int:
	if offset >= stroke_numbers.size():
		_note("golf stroke digit past the extracted tiles")
		return 0
	return stroke_numbers[offset]


func set_up_golf_hole_objects() -> void:
	_set_oam_ptr(OAM_1CA6CF)
	wb(W_SHOT_POWER_GAUGE_CURSOR, BASE_SHOT_POWER)
	ww(W_GOLF_WARIO_Y_POS, 0x58)
	ww(W_GOLF_WARIO_X_POS, 0x40)
	ww(W_GOLF_PARA_GOOM_Y_POS, PARAGOOM_TEE_BOX_LEVEL)
	ww(W_GOLF_PARA_GOOM_X_POS, 0x80)
	update_golf_hole_ui()
	update_golf_para_goom()
	update_golf_wario()
	clear_unused_virtual_oam()


## HandleGolfHole
func handle_golf_hole() -> void:
	_set_oam_ptr(OAM_1CA6CF)
	golf_hole_state_table()
	update_golf_hole_ui()
	update_golf_para_goom()
	update_golf_wario()
	clear_unused_virtual_oam()
	load_golf_wario_state_gfx()
	func_1c9cf9()


## UpdateGolfHoleUI: the interface's objects (the gauge's cursors only while they are used).
func update_golf_hole_ui() -> void:
	wb(W_GOLF_OBJ_1 + OBJ_Y_COORD, 0x30)
	wb(W_GOLF_OBJ_1 + OBJ_X_COORD, 0x0C)
	_animate(W_GOLF_OBJ_1, "72:6f6f")
	wb(W_GOLF_OBJ_2 + OBJ_Y_COORD, 0x30)
	wb(W_GOLF_OBJ_2 + OBJ_X_COORD, 0x08)
	_animate(W_GOLF_OBJ_2, "72:6f81")
	if rb(W_GOLF_HOLE_STATE) == GOLFHOLESTATE_PAUSE:
		return
	wb(W_GOLF_OBJ_3 + OBJ_Y_COORD, SCREEN_HEIGHT_PX)
	wb(W_GOLF_OBJ_3 + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OBJ_3, "72:6f8a")
	if rb(W_GOLF_OBJ_4 + OBJ_STATE) != 0:
		return
	wb(W_GOLF_OBJ_4 + OBJ_Y_COORD, SCREEN_HEIGHT_PX)
	wb(W_GOLF_OBJ_4 + OBJ_X_COORD, rb(W_SHOT_POWER_GAUGE_CURSOR) + 0x32)
	_animate(W_GOLF_OBJ_4, "72:6f84")
	if rb(W_GOLF_OBJ_5 + OBJ_STATE) == 0:
		return
	wb(W_GOLF_OBJ_5 + OBJ_Y_COORD, SCREEN_HEIGHT_PX)
	wb(W_GOLF_OBJ_5 + OBJ_X_COORD, rb(W_SELECTED_SHOT_POWER_GAUGE) + 0x32)
	_animate(W_GOLF_OBJ_5, "72:6f87")


## Func_1c8f56: whether the position `x` (in pixels) is within view of wGolfXScroll ($e0 to its
## left, $b0 to its right).
func _in_view(x: int) -> bool:
	var difference: int = (x - rw(W_GOLF_X_SCROLL)) & 0xFFFF
	var high: int = difference >> 8
	if high == 0:
		return (difference & 0xFF) < 0xB0
	if high == 0xFF:
		return (difference & 0xFF) >= 0xE0
	return false


## UpdateGolfParaGoom: placed on screen and animated while in view; a finished animation in the
## water or out of bounds respawns it.
func update_golf_para_goom() -> void:
	if rb(W1DC20) != 0:
		return
	var state: int = rb(W_GOLF_PARA_GOOM + OBJ_STATE)
	if state >= GOLF_PARAGOOM_8:
		return
	var x: int = rw(W_GOLF_PARA_GOOM_X_POS) >> 2
	if not _in_view(x):
		return
	wb(W_GOLF_PARA_GOOM + OBJ_X_COORD, x + OAM_X_OFS - sim.wSCX)
	var y_offset: int = 0x13 if state == GOLF_PARAGOOM_5 else 0x12
	wb(W_GOLF_PARA_GOOM + OBJ_Y_COORD, (rw(W_GOLF_PARA_GOOM_Y_POS) >> 2) + y_offset)
	if state >= PARA_GOOM_FRAMESETS.size():
		_note("UpdateGolfParaGoom state %d (its frameset reads home code)" % state)
		return
	var finished: bool = update_animation(W_GOLF_PARA_GOOM, PARA_GOOM_FRAMESETS[state])
	if finished and handle_golf_para_goom_respawn():
		return
	wb(W_GOLF_PARA_GOOM + OBJ_FRAME, rb(W_GOLF_PARA_GOOM + OBJ_CURRENT_FRAME))
	load_golf_sprite(W_GOLF_PARA_GOOM)


## HandleGolfParaGoomRespawn: after the water (state 2), at the hole's water spawn; after out of
## bounds (state 3), where it was shot from. Whether it respawned.
func handle_golf_para_goom_respawn() -> bool:
	match rb(W_GOLF_PARA_GOOM + OBJ_STATE):
		GOLF_PARAGOOM_2:
			ww(W_LAST_GOLF_PARA_GOOM_Y_POS, PARAGOOM_GROUND_LEVEL)
			ww(W_GOLF_PARA_GOOM_Y_POS, 0)
			var spawn: int = rb(W_GOLF_WATER_SPAWN_2) if (rb(W_GOLF_TERRAIN) & GOLF_TERRAIN_2ND_WATER) != 0 \
					else rb(W_GOLF_WATER_SPAWN_1)
			ww(W_GOLF_PARA_GOOM_X_POS, spawn << 5)
			align_golf_x_scroll_with_para_goom()
			update_golf_display_mode()
			wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_4)
			set_golf_para_goom_respawn_y_pos_if_enough_strokes()
			return true
		GOLF_PARAGOOM_3:
			ww(W_GOLF_PARA_GOOM_Y_POS, 0)
			ww(W_GOLF_PARA_GOOM_X_POS, rw(W_LAST_GOLF_PARA_GOOM_X_POS))
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_8)
			set_golf_para_goom_respawn_y_pos_if_enough_strokes()
			return true
	return false


func set_golf_para_goom_respawn_y_pos_if_enough_strokes() -> void:
	if rb(W_GOLF_STROKE) < rb(W_GOLF_MAX_STROKES):
		return
	ww(W_GOLF_PARA_GOOM_Y_POS, PARAGOOM_GROUND_LEVEL)
	wb(W1DC20, 1)


## UpdateGolfWario: on screen and animated while in view; out of view, after a shot (w1dc21), he is
## placed just off the screen's side he faces.
func update_golf_wario() -> void:
	var x: int = rw(W_GOLF_WARIO_X_POS) >> 2
	if not _in_view(x):
		if rb(W1DC21) == 0:
			return
		wb(W1DC21, 0)
		var scroll: int = rw(W_GOLF_X_SCROLL) << 2
		ww(W_GOLF_WARIO_X_POS, scroll - 40 if rb(W_GOLF_WARIO_DIR) == 0 else scroll + 680)
		return
	wb(W1DC21, 0)
	wb(W_GOLF_WARIO + OBJ_X_COORD, x + OAM_X_OFS - sim.wSCX)
	wb(W_GOLF_WARIO + OBJ_Y_COORD, rb(W_GOLF_WARIO_Y_POS) + 0x11)
	update_golf_wario_animation()


## Func_1c9cf9: the LCD configuration by the display mode, and the V-Blank function by
## wGolfVBlankMode (the pin flag's animation steps in the first).
func func_1c9cf9() -> void:
	match rb(W_GOLF_DISPLAY_MODE):
		GOLF_DISPLAY_SPLIT:
			wb(W_GOLF_LCD_CONFIG, LCDC_SPLIT)
		GOLF_DISPLAY_BGMAP1:
			wb(W_GOLF_LCD_CONFIG, LCDC_BGMAP1)
		_:
			wb(W_GOLF_LCD_CONFIG, LCDC_DEFAULT)
	match rb(W_GOLF_VBLANK_MODE):
		0:
			# VBlank_1c9d1d.UpdatePinFlagTiles: a frame of the flag every 8 loops, its 4 tiles
			# (GolfPinFlagGfx) to wGolfPinFlagTiles, then VRAM
			pin_flag_frame = mini(rb(W1DC0B) >> 3, 3)
			_copy_gfx_from("raw", PIN_FLAG_GFX, pin_flag_frame * 0x40, W_GOLF_PIN_FLAG_TILES, 0x40)
			wb(W1DC0B, (rb(W1DC0B) + 1) & 0x1F)
			vblank_func = VBlankFunc.PIN_FLAG
		1:
			vblank_func = VBlankFunc.HOLE_ATTR
		2:
			vblank_func = VBlankFunc.HOLE_WARIO
		3:
			vblank_func = VBlankFunc.STROKE
		_:
			_note("Func_1c9cf9 V-Blank mode %d" % rb(W_GOLF_VBLANK_MODE))


## GolfHoleStateTable
func golf_hole_state_table() -> void:
	match rb(W_GOLF_HOLE_STATE):
		GOLFHOLESTATE_WAIT_INPUT:
			_hole_wait_input()
		GOLFHOLESTATE_SCROLL:
			_hole_scroll()
		GOLFHOLESTATE_SELECT_SHOT_POWER:
			_hole_select_shot_power()
		GOLFHOLESTATE_SELECT_SHOT_SPIN:
			_hole_select_shot_spin()
		GOLFHOLESTATE_START_SHOT:
			_hole_start_shot()
		GOLFHOLESTATE_SHOT:
			_hole_shot()
		GOLFHOLESTATE_BOUNCE:
			_hole_bounce()
		GOLFHOLESTATE_SPECIAL_TERRAIN:
			_hole_special_terrain()
		GOLFHOLESTATE_WALK:
			_hole_walk()
		GOLFHOLESTATE_BETWEEN_SHOTS:
			_hole_between_shots()
		GOLFHOLESTATE_CLEARED:
			_hole_cleared()
		GOLFHOLESTATE_GAME_OVER:
			_hole_game_over()
		GOLFHOLESTATE_PAUSE:
			_hole_pause()
		GOLFHOLESTATE_RESULT:
			_hole_result()
		_:
			_note("GolfHoleStateTable state %d" % rb(W_GOLF_HOLE_STATE))


func _hole_wait_input() -> void:
	var scroll: int = rw(W_GOLF_X_SCROLL)
	var pressed: int = sim.wJoypadPressed
	if (pressed & WarioRam.PAD_SELECT) != 0:
		wb(W_GOLF_OBJ_3 + OBJ_DURATION, 0)
		wb(W_GOLF_OBJ_3 + OBJ_FRAMESET_OFFSET, 0)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_PAUSE)
	elif (pressed & WarioRam.PAD_A) != 0:
		_clear(W_GOLF_OVERLAY_TEXT, W_GOLF_OVERLAY_TEXT + 8)
		wb(W_GOLF_RESULT, 0)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SELECT_SHOT_POWER)
		wb(W_STROKE_GOLF_TERRAIN, rb(W_GOLF_TERRAIN))
		wb(W1DC53, rb(W1DC47))
		for index: int in 4:
			wb(W_LAST_GOLF_PARA_GOOM_Y_POS + index, rb(W_GOLF_PARA_GOOM_Y_POS + index))
	elif (pressed & WarioRam.PAD_RIGHT) != 0:
		if (scroll >> 8) != 0 and (scroll & 0xFF) >= (MAX_GOLF_X_SCROLL & 0xFF):
			return
		_hole_begin_scroll(0)
	elif (pressed & WarioRam.PAD_LEFT) != 0:
		if scroll == 0:
			return
		_hole_begin_scroll(1)


func _hole_begin_scroll(direction: int) -> void:
	wb(W_GOLF_HOLE_SCROLLING_DIR, direction)
	ww(W_TEMP_GOLF_X_SCROLL, rw(W_GOLF_X_SCROLL))
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SCROLL)


func _hole_scroll() -> void:
	_hole_scroll_input()
	# the Para-Goom's ghost, where a full shot from this terrain would land
	var x: int = rw(W_GOLF_PARA_GOOM_X_POS) >> 2
	var reach: int = 0xA0
	if rb(W_GOLF_TERRAIN) == GOLF_TERRAIN_ROUGH:
		reach = 0x80
	elif rb(W_GOLF_TERRAIN) == GOLF_TERRAIN_BUNKER:
		reach = 0x50
	x = (x - reach if rb(W_GOLF_HOLE_DIRECTION) != 0 else x + reach) & 0xFFFF
	if not _in_view(x):
		return
	wb(W_GOLF_PARA_GOOM_GHOST + OBJ_X_COORD, x + OAM_X_OFS - sim.wSCX)
	wb(W_GOLF_PARA_GOOM_GHOST + OBJ_Y_COORD, 0x72)
	_animate(W_GOLF_PARA_GOOM_GHOST, "72:70a4")


func _hole_scroll_input() -> void:
	var pressed: int = sim.wJoypadPressed
	if (pressed & (WarioRam.PAD_A | WarioRam.PAD_B)) != 0:
		ww(W_GOLF_X_SCROLL, rw(W_TEMP_GOLF_X_SCROLL))
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_WAIT_INPUT)
		update_golf_display_mode()
		return
	var scroll: int = rw(W_GOLF_X_SCROLL)
	var left: bool = rb(W_GOLF_HOLE_SCROLLING_DIR) != 0
	var held: int = WarioRam.PAD_LEFT if left else WarioRam.PAD_RIGHT
	if (sim.wJoypadDown & held) != 0:
		if left:
			if scroll == 0:
				return
			scroll -= 1
		else:
			if (scroll >> 8) != 0 and (scroll & 0xFF) >= (MAX_GOLF_X_SCROLL & 0xFF):
				return
			scroll += 1
		ww(W_GOLF_X_SCROLL, scroll)
		update_golf_display_mode()
		return
	# back to where the scroll started
	scroll = (scroll + 1 if left else scroll - 1) & 0xFFFF
	ww(W_GOLF_X_SCROLL, scroll)
	if scroll == rw(W_TEMP_GOLF_X_SCROLL):
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_WAIT_INPUT)
	update_golf_display_mode()


## UpdateGolfDisplayMode: wSCX from wGolfXScroll, and which tile map shows it (both halves split
## by the window between them).
func update_golf_display_mode() -> void:
	var scroll: int = rw(W_GOLF_X_SCROLL)
	sim.wSCX = scroll & 0xFF
	if (scroll >> 8) != 0:
		wb(W_GOLF_DISPLAY_MODE, GOLF_DISPLAY_BGMAP1)
	elif (scroll & 0xFF) >= (MAX_GOLF_X_SCROLL & 0xFF):
		wb(W_GOLF_WX, 167 - (scroll & 0xFF) + 89 + WX_OFS)
		wb(W_GOLF_DISPLAY_MODE, GOLF_DISPLAY_SPLIT)
	else:
		wb(W_GOLF_DISPLAY_MODE, GOLF_DISPLAY_BGMAP0)


## The gauge's cursor rising (1, from 16 on 2) to the top, then falling by 2.
func _gauge_step(cursor_address: int) -> bool:
	if rb(W_IS_POWER_GAUGE_FALLING) == 0:
		var cursor: int = rb(cursor_address)
		cursor = (cursor + (1 if cursor < 16 else 2)) & 0xFF
		wb(cursor_address, cursor)
		if cursor >= MAX_SHOT_POWER:
			wb(W_IS_POWER_GAUGE_FALLING, 1)
		return true
	var cursor: int = rb(cursor_address) - 2
	wb(cursor_address, cursor)
	return cursor >= 0


func _hole_select_shot_power() -> void:
	if not _gauge_step(W_SHOT_POWER_GAUGE_CURSOR):
		# the cursor let fall to 0
		wb(W_GOLF_COUNTER, 0)
		wb(W_SHOT_POWER_GAUGE_CURSOR, 0)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_START_SHOT)
		return
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	_reset_wario_animation()
	wb(W_GOLF_OBJ_5 + OBJ_STATE, 1)
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SELECT_SHOT_SPIN)
	var cursor: int = rb(W_SHOT_POWER_GAUGE_CURSOR)
	wb(W_SELECTED_SHOT_POWER_GAUGE, cursor)
	var level: int = 9
	for limit: int in [16, 24, 32, 40, 48, 56, 64, 70, 74]:
		if cursor < limit:
			level = [16, 24, 32, 40, 48, 56, 64, 70, 74].find(limit)
			break
	wb(W_SHOT_POWER_LEVEL, level)
	_set_shot_vels(SHOT_VELS, level)
	match rb(W_GOLF_TERRAIN):
		GOLF_TERRAIN_ROUGH:
			wb(W_SHOT_Y_VEL, (rb(W_SHOT_Y_VEL) * 3 + 3) >> 2)
			wb(W_SHOT_TERRAIN_MODIFIER, SHOT_MODIFIER_ROUGH)
		GOLF_TERRAIN_BUNKER:
			wb(W_SHOT_Y_VEL, ((rb(W_SHOT_Y_VEL) + 1) >> 1) - 1)
			wb(W_SHOT_TERRAIN_MODIFIER, SHOT_MODIFIER_BUNKER)
		_:
			wb(W_SHOT_TERRAIN_MODIFIER, SHOT_MODIFIER_NONE)


func _set_shot_vels(table: Array[int], level: int) -> void:
	wb(W_SHOT_Y_VEL, table[level * 2])
	wb(W1DC4F, 0)
	wb(W_SHOT_X_VEL, table[level * 2 + 1])


func _hole_select_shot_spin() -> void:
	if not _gauge_step(W_SELECTED_SHOT_POWER_GAUGE):
		wb(W_SELECTED_SHOT_POWER_GAUGE, 0)
	elif (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	wb(W_GOLF_COUNTER, 0)
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_START_SHOT)
	var gauge: int = rb(W_SELECTED_SHOT_POWER_GAUGE)
	if gauge < 2:
		wb(W_SHOT_SPIN, SHOT_MISS)
	elif gauge < 5:
		wb(W_SHOT_SPIN, SHOT_BACKSPIN)
	elif gauge < 11:
		wb(W_SHOT_SPIN, SHOT_NORMAL)
	elif gauge < 14:
		wb(W_SHOT_SPIN, SHOT_TOPSPIN)
	else:
		wb(W_SHOT_SPIN, SHOT_MISS)


func _hole_start_shot() -> void:
	var counter: int = rb(W_GOLF_COUNTER)
	if counter == 0:
		inc(W_GOLF_COUNTER)
		inc(W_GOLF_STROKE)
		wb(W_GOLF_VBLANK_MODE, 3)
		print_golf_stroke_number()
	elif counter == 1:
		inc(W_GOLF_COUNTER)
		_start_wario(GOLF_WARIO_CHARGING, 2)
	elif counter == 3:
		inc(W_GOLF_COUNTER)
		_reset_wario_animation()
		if rb(W_SHOT_POWER_GAUGE_CURSOR) == 0 or rb(W_SHOT_SPIN) == SHOT_MISS:
			wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_MISSING)
			wb(W_GOLF_VBLANK_MODE, 2)
		else:
			wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_ATTACKING_1)
	elif counter >= 5:
		wb(W_GOLF_COUNTER, 0)
		_reset_wario_animation()
		if rb(W_GOLF_WARIO + OBJ_STATE) == GOLF_WARIO_MISSING:
			wb(W_GOLF_VBLANK_MODE, 2)
			wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_IDLING)
			wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_BETWEEN_SHOTS)
			return
		wb(W_SHOT_DIRECTION, rb(W_GOLF_HOLE_DIRECTION))
		wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
		wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_1)
		wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_ATTACKING_2)
		wb(W1DC01, GOLFHOLESTATE_BOUNCE)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SHOT)


func _hole_shot() -> void:
	update_golf_para_goom_x_pos()
	update_golf_para_goom_y_pos()
	align_golf_x_scroll_with_para_goom()
	update_golf_display_mode()
	if rb(W_GOLF_HOLE_STATE) == GOLFHOLESTATE_SHOT:
		return
	# it bounced
	wb(W1DC01, GOLFHOLESTATE_WALK)
	var spin: int = rb(W_SHOT_SPIN)
	if spin != SHOT_NORMAL and spin != SHOT_TOPSPIN:
		wb(W_SHOT_DIRECTION, rb(W_SHOT_DIRECTION) ^ 1)  # backspin
	_set_shot_vels(TOPSPIN_BOUNCE_VELS if spin == SHOT_TOPSPIN else NORMAL_BOUNCE_VELS, rb(W_SHOT_POWER_LEVEL))
	match rb(W_SHOT_TERRAIN_MODIFIER):
		SHOT_MODIFIER_ROUGH:
			wb(W_SHOT_Y_VEL, (rb(W_SHOT_Y_VEL) * 3 + 3) >> 2)
		SHOT_MODIFIER_BUNKER:
			wb(W_SHOT_Y_VEL, (rb(W_SHOT_Y_VEL) + 1) >> 1)


func _hole_bounce() -> void:
	update_golf_para_goom_x_pos()
	update_golf_para_goom_y_pos()
	align_golf_x_scroll_with_para_goom()
	update_golf_display_mode()


## UpdateGolfParaGoomXPos: the x velocity falls by 1 every 8 loops; the terrain block below (32 px
## each) sets the ground level, a tee box's with a flag after leaving it counting as out of bounds,
## and the hole's ends end the shot out of bounds.
func update_golf_para_goom_x_pos() -> void:
	inc(W1DC51)
	if (rb(W1DC51) & 0b111) == 0:
		wb(W_SHOT_X_VEL, rb(W_SHOT_X_VEL) - 1)
	var x: int = rw(W_GOLF_PARA_GOOM_X_POS)
	if rb(W_SHOT_DIRECTION) == 0:
		x = (x + rb(W_SHOT_X_VEL)) & 0xFFFF
		ww(W_GOLF_PARA_GOOM_X_POS, x)
	else:
		x = (x - rb(W_SHOT_X_VEL)) & 0xFFFF
		ww(W_GOLF_PARA_GOOM_X_POS, x)
		if (x >> 8) == 0xFF:
			wb(W_GOLF_PARA_GOOM_X_POS + 1, 0)
			wb(W_GOLF_TERRAIN, GOLF_TERRAIN_END)
			_para_goom_out_of_bounds()
			return
	var block: int = x >> 5
	ww(W1DC3E, block)
	var terrain: int = rb(W_GOLF_TERRAIN_BLOCKS + block) if W_GOLF_TERRAIN_BLOCKS + block < RAM_START + RAM_SIZE else 0
	wb(W_GOLF_TERRAIN, terrain)
	var kind: int = terrain & GOLF_TERRAIN_MASK
	if kind == GOLF_TERRAIN_END:
		_para_goom_out_of_bounds()
		return
	if kind == 0:  # the tee box
		if rb(W1DC47) == 0:
			wb(W_GROUND_LEVEL_Y_POS, PARAGOOM_TEE_BOX_LEVEL & 0xFF)
			return
		if (terrain & GOLF_TERRAIN_FLAGS_MASK) != 0:
			wb(W_GOLF_TERRAIN, GOLF_TERRAIN_TEE_OB)
	wb(W_GROUND_LEVEL_Y_POS, PARAGOOM_GROUND_LEVEL & 0xFF)


func _para_goom_out_of_bounds() -> void:
	wb(W_GOLF_PARA_GOOM + OBJ_DURATION, 0)
	wb(W_GOLF_WARIO + OBJ_DURATION, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_WARIO + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_8)
	wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_IDLING)
	wb(W_GOLF_VBLANK_MODE, 2)
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SPECIAL_TERRAIN)
	inc(W_GOLF_STROKE)


## UpdateGolfParaGoomYPos: gravity on the y velocity (16-bit), then on the position; on reaching the
## ground the shot bounces (tee box, plain) or ends on the terrain it met.
func update_golf_para_goom_y_pos() -> void:
	var vel: int = (rw(W_SHOT_Y_VEL) - 1) & 0xFFFF
	ww(W_SHOT_Y_VEL, vel)
	var y: int = (rw(W_GOLF_PARA_GOOM_Y_POS) - vel) & 0xFFFF
	ww(W_GOLF_PARA_GOOM_Y_POS, y)
	if (y >> 8) != (PARAGOOM_GROUND_LEVEL >> 8):
		return
	var ground: int = rb(W_GROUND_LEVEL_Y_POS)
	if ground >= (y & 0xFF):
		return
	ww(W_GOLF_PARA_GOOM_Y_POS, (PARAGOOM_GROUND_LEVEL & 0xFF00) | ground)
	var terrain: int = rb(W_GOLF_TERRAIN)
	var kind: int = terrain & GOLF_TERRAIN_MASK
	if kind != 0 and kind < GOLF_TERRAIN_OB:
		wb(W1DC47, kind)
	wb(W1DC51, 0)
	if kind < SPECIAL_GOLF_TERRAIN:
		wb(W_GOLF_HOLE_STATE, rb(W1DC01))
		if rb(W1DC01) == GOLFHOLESTATE_BOUNCE:
			return
		wb(W1DC01, GOLFHOLESTATE_BETWEEN_SHOTS)
		update_golf_hole_direction()
		_stop_para_goom_and_wario()
		return
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_SPECIAL_TERRAIN)
	_stop_para_goom_and_wario()
	match kind:
		GOLF_TERRAIN_HOLE:
			_check_edges(terrain)
		GOLF_TERRAIN_WATER:
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_6)
			inc(W_GOLF_STROKE)
			_check_edges(terrain)
		GOLF_TERRAIN_OB:
			wb(W1DC47, rb(W1DC53))
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_6)
			inc(W_GOLF_STROKE)
			_check_edges(terrain)
		GOLF_TERRAIN_TEE_OB:
			inc(W_GOLF_STROKE)
		GOLF_TERRAIN_BUNKER:
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_5)


func _stop_para_goom_and_wario() -> void:
	wb(W_GOLF_PARA_GOOM + OBJ_DURATION, 0)
	wb(W_GOLF_WARIO + OBJ_DURATION, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_WARIO + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_STATE, 0)
	wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_IDLING)
	wb(W_GOLF_VBLANK_MODE, 2)


## .check_edges: a block with an edge flag snaps the Para-Goom to its edge (the next block's start
## for a left edge).
func _check_edges(terrain: int) -> void:
	var block: int = rw(W1DC3E)
	if (terrain & (1 << GOLF_TERRAIN_EDGE_RIGHT_F)) != 0:
		ww(W_GOLF_PARA_GOOM_X_POS, ((block & 0xFF00) | (block & 0xFF)) << 5)
	elif (terrain & (1 << GOLF_TERRAIN_EDGE_LEFT_F)) != 0:
		ww(W_GOLF_PARA_GOOM_X_POS, ((block & 0xFF00) | ((block + 1) & 0xFF)) << 5)


## AlignGolfXScrollWithParaGoom: the scroll $50 px behind the Para-Goom, within 0 to $160.
func align_golf_x_scroll_with_para_goom() -> void:
	var x: int = rw(W_GOLF_PARA_GOOM_X_POS) >> 2
	var high: int = x >> 8
	var low: int = x & 0xFF
	if high >= 2 or (high == 1 and low >= 0xB0):
		ww(W_GOLF_X_SCROLL, 0x160)
	elif high == 0:
		ww(W_GOLF_X_SCROLL, low - 0x50 if low >= 0x50 else 0)
	else:
		ww(W_GOLF_X_SCROLL, x - 0x50)


func _hole_special_terrain() -> void:
	wb(W_GOLF_OVERLAY_TEXT + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_X_COORD, 0x58)
	wb(W_GOLF_OBJ_4 + OBJ_STATE, 0x58)
	wb(W1DC01, GOLFHOLESTATE_BETWEEN_SHOTS)
	match rb(W_GOLF_TERRAIN) & GOLF_TERRAIN_MASK:
		GOLF_TERRAIN_HOLE:
			_special_hole()
		GOLF_TERRAIN_ROUGH:
			_special_overlay("72:7035")
		GOLF_TERRAIN_BUNKER:
			_special_overlay("72:7068")
		GOLF_TERRAIN_WATER:
			_special_water()
		GOLF_TERRAIN_OB:
			_special_ob()
		_:
			# a tee box out of bounds, or past the hole's end
			if rb(W_GOLF_PARA_GOOM + OBJ_STATE) == GOLF_PARAGOOM_4:
				_special_drop_back()
				return
			if not _overlay_finished("72:7016"):
				return
			ww(W_GOLF_PARA_GOOM_Y_POS, 0)
			ww(W_GOLF_PARA_GOOM_X_POS, rw(W_LAST_GOLF_PARA_GOOM_X_POS))
			align_golf_x_scroll_with_para_goom()
			update_golf_display_mode()
			update_golf_hole_direction()
			wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_4)
			set_golf_para_goom_respawn_y_pos_if_enough_strokes()


## The overlay text's animation; its frame is shown only while it goes on.
func _overlay_finished(frameset: String) -> bool:
	if update_animation(W_GOLF_OVERLAY_TEXT, frameset):
		return true
	wb(W_GOLF_OVERLAY_TEXT + OBJ_FRAME, rb(W_GOLF_OVERLAY_TEXT + OBJ_CURRENT_FRAME))
	load_golf_sprite(W_GOLF_OVERLAY_TEXT)
	return false


## The rough's and the bunker's overlay text, then the walk.
func _special_overlay(frameset: String) -> void:
	if _overlay_finished(frameset):
		_special_walk()


func _special_water() -> void:
	match rb(W_GOLF_PARA_GOOM + OBJ_STATE):
		GOLF_PARAGOOM_4:
			_special_drop_back()
		GOLF_PARAGOOM_6:
			var y: int = rb(W_GOLF_PARA_GOOM_Y_POS)
			if y < 0xC0:
				wb(W_GOLF_PARA_GOOM_Y_POS, y + 4)  # sinking
				return
			wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_2)
			wb(W_STROKE_GOLF_TERRAIN, GOLF_TERRAIN_PLAIN)


## .asm_1c9743: the respawned Para-Goom drops 2 a loop to where it was shot from, then the walk.
func _special_drop_back() -> void:
	var y: int = (rw(W_GOLF_PARA_GOOM_Y_POS) + 2) & 0xFFFF
	ww(W_GOLF_PARA_GOOM_Y_POS, y)
	var last: int = rw(W_LAST_GOLF_PARA_GOOM_Y_POS)
	if last > y:  # Compare16Bit(last, y) is 2
		return
	wb(W_GOLF_TERRAIN, rb(W_STROKE_GOLF_TERRAIN))
	_special_walk()


## .asm_1c976f: the shot's end; Golf Wario walks to the Para-Goom.
func _special_walk() -> void:
	if rb(W_GOLF_PARA_GOOM + OBJ_STATE) != GOLF_PARAGOOM_5:
		wb(W_GOLF_PARA_GOOM + OBJ_STATE, 0)
	wb(W_GOLF_COUNTER, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_DURATION, 0)
	wb(W_GOLF_WARIO + OBJ_DURATION, 0)
	wb(W_GOLF_PARA_GOOM + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_WARIO + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_FRAMESET_OFFSET, 0)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_STATE, 0)
	update_golf_hole_direction()
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_WALK)


func _special_ob() -> void:
	var state: int = rb(W_GOLF_PARA_GOOM + OBJ_STATE)
	if state == GOLF_PARAGOOM_4:
		_special_drop_back()
		return
	if state == GOLF_PARAGOOM_6:
		var y: int = rb(W_GOLF_PARA_GOOM_Y_POS)
		if y < 0xA0:
			wb(W_GOLF_PARA_GOOM_Y_POS, y + 4)
			return
		wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_3)
	if not _overlay_finished("72:7016"):
		return
	wb(W_GOLF_PARA_GOOM + OBJ_STATE, GOLF_PARAGOOM_4)
	align_golf_x_scroll_with_para_goom()
	update_golf_display_mode()
	update_golf_hole_direction()


func _special_hole() -> void:
	var counter: int = rb(W_GOLF_COUNTER)
	if counter < 0x18:
		inc(W_GOLF_COUNTER)
		var x: int = rw(W_GOLF_PARA_GOOM_X_POS)
		x = x - HOLE_X_OFFSETS[counter] if HOLE_X_SIGNS[counter] != 0 else x + HOLE_X_OFFSETS[counter]
		ww(W_GOLF_PARA_GOOM_X_POS, x & 0xFFFF)
		wb(W_GOLF_PARA_GOOM_Y_POS, rb(W_GOLF_PARA_GOOM_Y_POS) + HOLE_Y_OFFSETS[counter])
		return
	if counter < 0x30:
		inc(W_GOLF_COUNTER)
		return
	var par: int = rb(W_GOLF_PAR)
	var stroke: int = rb(W_GOLF_STROKE)
	if stroke > par:
		wb(W_GOLF_RESULT, GOLFRESULT_OVER_PAR)
		if rb(W1D800) != 1:
			wb(W1DC01, GOLFHOLESTATE_GAME_OVER)
			_special_walk()
			return
	elif stroke == par:
		wb(W_GOLF_RESULT, GOLFRESULT_PAR)
	wb(W1DC01, GOLFHOLESTATE_CLEARED)
	_special_walk()


func _hole_walk() -> void:
	var counter: int = rb(W_GOLF_COUNTER)
	if counter < 0x18:
		inc(W_GOLF_COUNTER)
		if counter != 0:
			return
		wb(W_GOLF_VBLANK_MODE, 3)
		wb(W1DC21, 3)
		print_golf_stroke_number()
		return
	if counter == 0x18:
		_walk_start()
		return
	# .walk, 4 px a loop to the target
	var x: int = rw(W_GOLF_WARIO_X_POS)
	var target: int = rw(W_GOLF_WARIO_TARGET_X_POS)
	var next: int
	var reached: bool
	if rb(W_GOLF_WARIO_DIR) == 0:
		next = (x + 4) & 0xFFFF
		reached = next >= target  # Compare16Bit is not 0 (less than)
	else:
		next = (x - 4) & 0xFFFF
		reached = next <= target  # Compare16Bit is not 2 (greater than)
	if not reached:
		ww(W_GOLF_WARIO_X_POS, next)
		return
	ww(W_GOLF_WARIO_X_POS, target)
	wb(W_GOLF_WARIO_DIR, rb(W_GOLF_HOLE_DIRECTION))
	wb(W_GOLF_COUNTER, 0)
	_reset_wario_animation()
	var next_state: int = rb(W1DC01)
	var wario_state: int = GOLF_WARIO_IDLING
	if next_state == GOLFHOLESTATE_CLEARED:
		wario_state = GOLF_WARIO_CLEARED if rb(W_GOLF_RESULT) < GOLFRESULT_OVER_PAR else GOLF_WARIO_LOST
	elif next_state == GOLFHOLESTATE_GAME_OVER:
		wario_state = GOLF_WARIO_LOST
	wb(W_GOLF_WARIO + OBJ_STATE, wario_state)
	wb(W_GOLF_VBLANK_MODE, 2)
	wb(W_GOLF_HOLE_STATE, next_state)


## .asm_1c98e1: off a tee box he steps down to the Para-Goom's level first; then he walks unless he
## is already at the target.
func _walk_start() -> void:
	if rb(W1DC47) != 0 and rb(W_GOLF_WARIO_Y_POS) < 0x60:
		var para_goom_y: int = rw(W_GOLF_PARA_GOOM_Y_POS) >> 2
		if rb(W_GOLF_WARIO_Y_POS) < (para_goom_y & 0xFF):
			wb(W_GOLF_WARIO_Y_POS, rb(W_GOLF_WARIO_Y_POS) + 2)
			if rb(W_GOLF_WARIO_Y_POS) >= 0x60:
				wb(W_GOLF_VBLANK_MODE, 1)
			return
	if rw(W_GOLF_WARIO_X_POS) == rw(W_GOLF_WARIO_TARGET_X_POS):
		wb(W_GOLF_COUNTER, 0)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_BETWEEN_SHOTS)
		return
	inc(W_GOLF_COUNTER)
	_start_wario(GOLF_WARIO_WALKING, 2)


## UpdateGolfHoleDirection: which side of the Para-Goom the hole is, and Golf Wario's target $40
## behind it.
func update_golf_hole_direction() -> void:
	var x: int = rw(W_GOLF_PARA_GOOM_X_POS)
	if x > rw(W_GOLF_HOLE_HOLE_X_POS):
		wb(W_GOLF_HOLE_DIRECTION, 1)
		ww(W_GOLF_WARIO_TARGET_X_POS, x + 0x40)
	else:
		wb(W_GOLF_HOLE_DIRECTION, 0)
		ww(W_GOLF_WARIO_TARGET_X_POS, x - 0x40)


func _hole_between_shots() -> void:
	inc(W_GOLF_COUNTER)
	var counter: int = rb(W_GOLF_COUNTER)
	if counter == 0x08:
		if rb(W_GOLF_STROKE) < rb(W_GOLF_MAX_STROKES):
			return
		wb(W_GOLF_COUNTER, 0)
		_reset_wario_animation()
		wb(W_GOLF_OVERLAY_TEXT + OBJ_DURATION, 0)
		wb(W_GOLF_OVERLAY_TEXT + OBJ_FRAMESET_OFFSET, 0)
		wb(W_GOLF_OBJ_4 + OBJ_STATE, 1)
		wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_LOST)
		wb(W_GOLF_VBLANK_MODE, 2)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_GAME_OVER)
		return
	if counter < 0x20:
		return
	wb(W_SHOT_POWER_GAUGE_CURSOR, BASE_SHOT_POWER)
	wb(W_GOLF_COUNTER, 0)
	wb(W1DC51, 0)
	wb(W_IS_POWER_GAUGE_FALLING, 0)
	wb(W_GOLF_OBJ_4 + OBJ_STATE, 0)
	wb(W_GOLF_OBJ_5 + OBJ_STATE, 0)
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_WAIT_INPUT)


func _hole_cleared() -> void:
	if rb(W1D800) == 1:
		_course_hole_cleared()
		return
	wb(W_GOLF_OVERLAY_TEXT + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OVERLAY_TEXT, "72:6f8d")
	if rb(W_GOLF_COUNTER) < 0x50:
		inc(W_GOLF_COUNTER)
		return
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	wb(W1D800, 0)
	wb(W_GOLF_MENU_OPTION, 0)
	if sim.wIsMinigameCleared != 0:
		sim.wSubState = SST_GOLF_EXIT
		return
	sim.wIsMinigameCleared = 1
	sim.wSubState = SST_GOLF_CLEAR


## GolfHoleState_Cleared in the golf building (a course of 4 holes).
func _course_hole_cleared() -> void:
	show_golf_result_overlay_text()
	show_golf_score()
	var wait: int = 0x50 if rb(W_GOLF_WARIO + OBJ_STATE) == GOLF_WARIO_CLEARED else 0x70
	if rb(W_GOLF_COUNTER) < wait:
		inc(W_GOLF_COUNTER)
		return
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	wb(W_GOLF_COURSE_SCORE, rb(W_GOLF_COURSE_SCORE) + rb(W_GOLF_STROKE))
	if rb(W_GOLF_COURSE_HOLE) != NUM_GOLF_COURSE_HOLES:
		inc(W_GOLF_COURSE_HOLE)
		inc(W_PREDETERMINED_GOLF_HOLE)
		sim.wSubState = SST_GOLF_HOLE
		return
	wb(W_GOLF_COUNTER, 0)
	_reset_wario_animation()
	for obj: int in [W_GOLF_OVERLAY_TEXT, W_GOLF_PARA_GOOM_GHOST]:
		wb(obj + OBJ_DURATION, 0)
		wb(obj + OBJ_FRAMESET_OFFSET, 0)
	var score: int = rb(W_GOLF_COURSE_SCORE)
	wb(W_GOLF_RESULT, GOLFRESULT_COURSE_UNDER_PAR if score < GOLF_BASE_SCORE + 1 else GOLFRESULT_COURSE_OVER_PAR)
	var best: int = r0(W_GOLF_BEST_SCORES + (rb(W_GOLF_COURSE) & 3))
	wb(W_GOLF_WARIO + OBJ_STATE, GOLF_WARIO_CLEARED if score < best else GOLF_WARIO_LOST)
	wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_RESULT)


func show_golf_result_overlay_text() -> void:
	wb(W_GOLF_OVERLAY_TEXT + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_X_COORD, 0x58)
	var result: int = rb(W_GOLF_RESULT)
	if result >= RESULT_FRAMESETS.size():
		_note("ShowGolfResultOverlayText result %d" % result)
		return
	_animate(W_GOLF_OVERLAY_TEXT, RESULT_FRAMESETS[result])


## ShowGolfScore: the strokes under or over par on the overlay text's second and third sprites.
func show_golf_score() -> void:
	var result: int = rb(W_GOLF_RESULT)
	if result == GOLFRESULT_PAR:
		return
	var ones: int
	if result == GOLFRESULT_OVER_PAR:
		ones = (rb(W_GOLF_STROKE) - rb(W_GOLF_PAR)) & 0xFF
		if ones >= 10:
			wVirtualOAM[6] = 0x82
			ones -= 10
	else:
		ones = (rb(W_GOLF_PAR) - rb(W_GOLF_STROKE)) & 0xFF
	wVirtualOAM[10] = (ones * 2 + 0x80) & 0xFF


func _hole_game_over() -> void:
	wb(W_GOLF_OVERLAY_TEXT + OBJ_Y_COORD, 0x50)
	wb(W_GOLF_OVERLAY_TEXT + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OVERLAY_TEXT, "72:6fa0")
	if rb(W_GOLF_COUNTER) < 0x50:
		inc(W_GOLF_COUNTER)
		return
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	if rb(W1D800) == 2:
		wb(W_GOLF_MENU_OPTION, 1)
	sim.wSubState = 0


func _hole_pause() -> void:
	wb(W_GOLF_OBJ_3 + OBJ_Y_COORD, 0x9C)
	wb(W_GOLF_OBJ_3 + OBJ_X_COORD, 0x58)
	_animate(W_GOLF_OBJ_3, "72:70da")
	if (sim.wJoypadPressed & WarioRam.PAD_A) != 0:
		if rb(W1D800) != 1:
			wb(W_GOLF_MENU_OPTION, 1)
		sim.wSubState = 0
	elif (sim.wJoypadPressed & WarioRam.PAD_B) != 0:
		wb(W_GOLF_OBJ_3 + OBJ_DURATION, 0)
		wb(W_GOLF_OBJ_3 + OBJ_FRAMESET_OFFSET, 0)
		wb(W_GOLF_HOLE_STATE, GOLFHOLESTATE_WAIT_INPUT)


func _hole_result() -> void:
	show_golf_result_overlay_text()
	_set_overlay_text_score()
	wb(W_GOLF_PARA_GOOM_GHOST + OBJ_Y_COORD, 0x3C)
	wb(W_GOLF_PARA_GOOM_GHOST + OBJ_X_COORD, 0x50)
	_animate(W_GOLF_PARA_GOOM_GHOST, "72:70d7")
	if rb(W_GOLF_COUNTER) < 0x20:
		inc(W_GOLF_COUNTER)
		return
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	var course: int = rb(W_GOLF_COURSE) & 3
	if rb(W_GOLF_COURSE_SCORE) < r0(W_GOLF_BEST_SCORES + course):
		w0(W_GOLF_BEST_SCORES + course, rb(W_GOLF_COURSE_SCORE))
	sim.wSubState = 0


## GolfHoleState_Result.SetOverlayTextScore: the course score against 20 on the overlay's sprites
## (the first sprite raised, and at exactly 20 raised again with tile $fe).
func _set_overlay_text_score() -> void:
	wVirtualOAM[0] = (wVirtualOAM[0] - 1) & 0xFF
	var score: int = rb(W_GOLF_COURSE_SCORE)
	var value: int
	if score >= GOLF_BASE_SCORE + 1:
		value = score - GOLF_BASE_SCORE
	else:
		if score >= GOLF_BASE_SCORE:
			wVirtualOAM[0] = (wVirtualOAM[0] - 1) & 0xFF
			wVirtualOAM[2] = 0xFE
		value = (GOLF_BASE_SCORE - score) & 0xFF
	var tens: int = 0
	while value >= 10:
		value -= 10
		tens += 1
	if tens != 0:
		wVirtualOAM[6] = (tens * 2 + 0x80) & 0xFF
	wVirtualOAM[10] = (value * 2 + 0x80) & 0xFF


static func byte(value: int) -> int:
	return value & 0xFF
