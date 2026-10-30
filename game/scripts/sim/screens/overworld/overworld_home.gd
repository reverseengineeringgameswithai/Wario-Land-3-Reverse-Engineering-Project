class_name OverworldHome
extends OverworldCommon
## The map's RAM labels (src/ram/wram.asm: WRAMX bank 2 from wTreasuresCollected, its OW WRAM, and
## the progress WRAM it reads) and the shared routines its code calls, translated (WL3-052): the home
## bank's (src/home/overworld.asm: IsTreasureCollected, GetOWCoordInTilemap, LoadLevelName,
## UpdateOWAnimation, LoadOWSprite*; sprite.asm: LoadSprite; copy.asm), the RLE decompressions with
## the wTempBank their macros set, BG map 0 as far as the map reads it back, and the map patches the
## scenes' set-ups apply (Func_854ee, Func_80bd9). The map runs with WRAMX bank 2 switched in, so a
## WRAMX address is bank 2's. For drawing, what each loop and its V-Blank write to VRAM, the palettes,
## and the LCD's registers is recorded (vram_writes, palette_writes, register_writes) by reading RAM
## only; OverworldVram (scripts/present) applies it.

# --- WRAM0 ---
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
const W_TEMP_BG_PALS: int = 0xC100
const W_NUM_COINS: int = 0xCA04
const W_DAY_NIGHT: int = 0xCA3B
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_LANGUAGE: int = 0xCA46
const W_KEY_AND_TREASURE_FLAGS: int = 0xCA5B

# --- WRAMX bank 2: "WRAM2" ---
const W_TREASURES_COLLECTED: int = 0xD000
const W_STORED_TRANSITION_PARAM: int = 0xD00D
const W_NEXT_TREASURE: int = 0xD00E
const W_OW_LEVEL: int = 0xD00F
const W2D011: int = 0xD011  # night (non-zero) on this map side
const W_NEXT_MAP_SIDE: int = 0xD012
const W2D013: int = 0xD013
const W_OW_SCENE_MAP_SIDE: int = 0xD016
const W_OW_SCENE_ACTION_PARAM: int = 0xD017
const W_TEMP_UNLOCKABLE_CONNECTION_ID: int = 0xD019
const W_CUR_MAP_SIDE: int = 0xD01A
const W_LAST_TRANSITION_PARAM: int = 0xD01B
const W_MAP_SIDE_LEVEL_ID: int = 0xD01D
const W_MISSING_TREASURE_INDICATORS_ENABLED: int = 0xD01F
const W_GOT_SUN_MEDALLION: int = 0xD020
const W_OW_ANIMATION_FINISHED: int = 0xD024
const W_CUR_EVENT: int = 0xD025
const W_OW_SCENE_PARAMS_PTR: int = 0xD026  # little-endian
const W_OW_SCENE_ACTION: int = 0xD028
const W_TEMP_OW_SCENE_ACTION: int = 0xD029
const W2D02C: int = 0xD02C
const W_CLOUD_TYPE: int = 0xD030
const W2D031: int = 0xD031
# The clouds' and sea's animations, 3 bytes each (speed, counter, frame; UpdateCommonOWAnimations).
const W2D032: int = 0xD032
const W2D035: int = 0xD035
const W2D038: int = 0xD038
const W2D03B: int = 0xD03B
const W2D03E: int = 0xD03E
const W2D041: int = 0xD041
const W2D044: int = 0xD044  # 2 bytes
const W2D046: int = 0xD046
const W2D047: int = 0xD047
const W2D048: int = 0xD048
const W2D049: int = 0xD049
const W_OW_BARS_STATE: int = 0xD050
const W_TOP_BAR_SELECTION: int = 0xD053
const W_TOP_BAR_SELECTABLE_BUTTONS: int = 0xD054
const W_OW_PAL_TRANSITION_STATE: int = 0xD055
const W_CRAYON_FLAGS: int = 0xD057

# --- WRAMX bank 2: "OW WRAM" ($d060-$d7ff, ClearOWWRAM) ---
const OW_WRAM: int = 0xD060
const OW_WRAM_END: int = 0xD800
const W_UNLOCKED_LEVEL_ARROWS_PTR: int = 0xD063  # little-endian
const W2D065: int = 0xD065  # the event being set up: TRUE unlocked, $80 unlocked by the treasure just got
const W_LEVEL_1: int = 0xD066
const W_LEVEL_2: int = 0xD067
const W2D068: int = 0xD068
const W2D069: int = 0xD069
const W2D06A: int = 0xD06A
const W_OW_Y_COORD_1: int = 0xD06B  # wOWCoords1
const W_OW_X_COORD_1: int = 0xD06C
const W_OW_Y_COORD_2: int = 0xD06D  # wOWCoords2
const W_OW_X_COORD_2: int = 0xD06E
const W_OW_PATH_SHAPE: int = 0xD071
const W2D072: int = 0xD072
const W_LEVEL_ARROW_DIRECTIONS_1: int = 0xD073
const W2D074: int = 0xD074
const W_LEVEL_ARROW_DIRECTIONS_2: int = 0xD075
const W2D076: int = 0xD076
const W_TEMP_EVENT: int = 0xD077
const W2D078: int = 0xD078
const W_HDMA_BANK: int = 0xD079
const W_ACCESSIBLE_MAP_SIDES: int = 0xD07A
const W2D07C: int = 0xD07C
const W2D07D: int = 0xD07D
const W2D07F: int = 0xD07F
const W_TILE_TO_PLACE_IN_OW: int = 0xD080
const W_ATTR_TO_PLACE_IN_OW: int = 0xD081
const W_OW_TILEMAP_PTR: int = 0xD082  # little-endian
const W_TEMP_OW_TILEMAP_PTR: int = 0xD086  # little-endian
const W_HAS_MAGNIFYING_GLASS: int = 0xD090
const W_BOTTOM_BAR_ACTION: int = 0xD091
const W_WY: int = 0xD094
const W_WX: int = 0xD095
const W_HDMA: int = 0xD0B0  # hdma_config_struct
const W2D0B5: int = 0xD0B5  # hdma_config_struct: source (high, low), destination (high, low), mode
const W_PAL_CONFIG_1: int = 0xD0D0  # pal_config_struct, its register first
const W_PAL_CONFIG_2: int = 0xD0D6  # pal_config_struct, its register first
const W2D0E0: int = 0xD0E0
const W2D0EE: int = 0xD0EE
const W2D0EF: int = 0xD0EF
const W_LEVEL_GREY_TREASURE_PAL: int = 0xD0F4  # then red, green, blue
const W_BOTTOM_BAR_FLAGS: int = 0xD0FA
# OW Wario: w2d100 (y), w2d101 (x), w2d102 (frame), w2d103 (attributes), w2d104 (duration), w2d105
# (frameset offset), w2d106 (OWWARIO_* direction), w2d107 (his OAM table), w2d109 (his frameset).
const W2D100: int = 0xD100
const W2D101: int = 0xD101
const W2D104: int = 0xD104
const W2D106: int = 0xD106
const W2D107: int = 0xD107  # little-endian
const W2D109: int = 0xD109  # little-endian
const W2D10C: int = 0xD10C
const W2D10D: int = 0xD10D
const W2D10E: int = 0xD10E
const W_COMPASS_OBJ: int = 0xD110  # scene_obj_struct
const W_CUR_SCENE_OBJ_PTR: int = 0xD11E  # little-endian
const W2D12C: int = 0xD12C
const W2D12E: int = 0xD12E
const W_CUR_SCENE_OBJ: int = 0xD180
const W_SCENE_OBJ_1: int = 0xD188  # wSceneObj1 to wSceneObj15, 8 bytes each
const W_ATTRMAP: int = 0xD200  # $300 bytes, 24 rows of TILEMAP_WIDTH
const W_TILEMAP: int = 0xD500
const W2DFFD: int = 0xDFFD
const W2DFFE: int = 0xDFFE
const W2DFFF: int = 0xDFFF  # also wOWExitUnlocked

# scene_obj_struct (src/macros/wram.asm): y, x, frame, attributes, duration, frameset offset, state.
const SCENE_OBJ_Y: int = 0
const SCENE_OBJ_X: int = 1
const SCENE_OBJ_FRAME: int = 2
const SCENE_OBJ_ATTRIBUTES: int = 3
const SCENE_OBJ_DURATION: int = 4
const SCENE_OBJ_FRAMESET_OFFSET: int = 5
const SCENE_OBJ_STATE: int = 6
const SCENE_OBJ_SIZE: int = 8

const TILEMAP_WIDTH: int = 32
const SCREEN_WIDTH_PX: int = 160
const SCREEN_HEIGHT_PX: int = 144
const FALSE: int = 0
const TRUE: int = 1
const B_BG_PRIO: int = 7
const BG_PALMASK: int = 0x07
const BG_BANK1: int = 0x08
const PAD_RIGHT: int = 0x10
const PAD_LEFT: int = 0x20
const PAD_UP: int = 0x40
const PAD_DOWN: int = 0x80

# Map sides (NORTH...), and OW_* level indices (src/constants/overworld_constants.asm).
const NORTH: int = 0
const WEST: int = 1
const SOUTH: int = 2
const EAST: int = 3
const OWNORTH_SEA_TURTLE_ROCKS: int = 0x06
const OWNORTH_JUNCTION: int = 0x07
const OW_EXITS: int = 0x0E
const OW_EXIT_RIGHT: int = 0x0E
const OW_EXIT_LEFT: int = 0x0F

# The ROM the home routines read: LevelTreasureIDs (home bank), LevelNamesJPGfx (its HDMA source).
const LEVEL_TREASURE_IDS: int = 0x198B
const NUM_LEVEL_TREASURES: int = 4
const LEVEL_NAMES_JP_GFX_BANK: int = 0x24
const LEVEL_NAMES_JP_GFX: int = 0x4000
## NumbersGfx (bank $26, DrawCoinCount's digits, two tiles each).
const NUMBERS_GFX_BANK: int = 0x26
const NUMBERS_GFX: int = 0x5980
## The cliffs' tiles' bank (OverworldCliffs1Gfx, the source in w2d044 that Func_1d8c2c copies from).
const CLIFFS_GFX_BANK: int = 0x76
## The palettes' index registers as the pal_config_structs name them (LOW(rBGPI), LOW(rOBPI)).
const LOW_R_BGPI: int = 0x68
const LOW_R_OBPI: int = 0x6A
## The LCDC values the map's set-ups write (LCDC_ON | LCDC_WIN_9C00 | LCDC_WIN_ON | LCDC_OBJ_16 |
## LCDC_OBJ_ON | LCDC_BG_ON on the map side, LCDC_DEFAULT elsewhere).
const LCDC_MAP_SIDE: int = 0xE7
const LCDC_DEFAULT: int = 0x87

## The V-Blank function the map sets (VBlank_Overworld): its RAM writes run after each loop.
const VBLANK_OVERWORLD: int = 1

## The current sprite LoadSprite draws (wCurSprite, WRAM0 $c096 to $c099; not traced).
var wCurSpriteYCoord: int = 0
var wCurSpriteXCoord: int = 0
var wCurSpriteFrame: int = 0
var wCurSpriteAttributes: int = 0
## BG map 0 by VRAM bank ($9800-$9bff, $400 bytes each), kept only because the map reads rows of it
## back into wAttrmap (Func_8065e, Func_b4247 copy rows 30 and 31, the top bar's): what
## FillBGMap0_With7f, the top bars' decompressions, and WriteBGMapFromWRAM leave there (VRAM as a
## whole is the drawing's: the records below).
var bg_map_0: Array = [PackedByteArray(), PackedByteArray()]
## For drawing (WL3-052), what this loop and the V-Blank after it wrote, in order, cleared each loop:
## `vram_writes` ["decompress", VRAM bank, address, ROM bank, ROM address] (Decompress from the ROM),
## ["rom", VRAM bank, address, ROM bank, ROM address, count] (a copy or DMA from the ROM), ["bytes",
## VRAM bank, address, bytes] (a copy or DMA from WRAM, or a fill); `palette_writes` ["palettes", OBJ,
## the BGPI or OBPI value, bytes] (to BGPD or OBPD), ["fade", to white, speed, wPalFadeCounter before
## the loop, wTempPals1 and wTempPals2] (a loop of FadeBGToWhite or DarkenBGToPal, whose V-Blank
## functions move the palettes); `register_writes` ["lcdc", value], ["lcdc_off"] (DisableLCD),
## ["lcdc_flip", bits], ["window", rWX, rWY].
var vram_writes: Array = []
var palette_writes: Array = []
var register_writes: Array = []


# --- RAM ---

## A byte at a WRAM address as the map sees it: WRAM0 below $d000, WRAMX bank 2 from it.
func rd(address: int) -> int:
	return r0(address) if address < 0xD000 else r2(address)


func wr(address: int, value: int) -> void:
	if address < 0xD000:
		w0(address, value)
	else:
		w2(address, value)


## A little-endian word in WRAM (a pointer the map keeps low byte first).
func rd_word(address: int) -> int:
	return rd(address) | (rd(address + 1) << 8)


func wr_word(address: int, value: int) -> void:
	wr(address, value & 0xFF)
	wr(address + 1, (value >> 8) & 0xFF)


## WriteAToHL_BCTimes (src/home/copy.asm).
func fill(address: int, count: int, value: int) -> void:
	for offset: int in count:
		wr(address + offset, value)


## CopyFarBytes and the CopyHLToDE copies from ROM (src/home/copy.asm): `count` bytes from
## (bank, source) to a WRAM address.
func copy_rom(bank: int, source: int, destination: int, count: int) -> void:
	for offset: int in count:
		wr(destination + offset, rb(bank, source + offset))


## wSceneObj1 to wSceneObj15 by number.
static func scene_obj(number: int) -> int:
	return W_SCENE_OBJ_1 + (number - 1) * SCENE_OBJ_SIZE


static func swap(value: int) -> int:
	return ((value << 4) | (value >> 4)) & 0xFF


# --- ROM tables (src/home/overworld.asm) ---

## AddOffsetInPointerTable: `table` + `index` * 2 (the doubled byte's carry kept).
static func table_entry(table: int, index: int) -> int:
	return (table + (index & 0xFF) * 2) & 0xFFFF


## GetPointerFromTableHL: the word at `table`'s `index`th entry, in `bank`.
func pointer_from_table(bank: int, table: int, index: int) -> int:
	return rw(bank, table_entry(table, index))


## GetCthWordFromAthTable: the `c`th word's address in the table the `a`th pointer of `table` points to.
func cth_word_from_ath_table(bank: int, table: int, a: int, c: int) -> int:
	return table_entry(pointer_from_table(bank, table, a), c)


# --- treasures and the map's BG ---

## IsTreasureCollected: TRUE if `treasure`'s bit in wTreasuresCollected (byte treasure / 8, bit
## treasure % 8) is set, else FALSE. Any byte is looked up so, TREASURES_END's ($ed: wMapSideLevelID's
## bit 5) included.
func is_treasure_collected(treasure: int) -> int:
	var mask: int = (0x10 if (treasure & 0x04) != 0 else 0x01) << (treasure & 0x03)
	return TRUE if (r2(W_TREASURES_COLLECTED + ((treasure & 0xFF) >> 3)) & mask) != 0 else FALSE


## GetOWCoordInTilemap: the wTilemap address of the tile at the pixel coordinates (y, x) at
## `coords` (y & $f8 rotated into the row, x / 8 the column), also kept in wOWTilemapPtr.
func get_ow_coord_in_tilemap(coords: int) -> int:
	var address: int = W_TILEMAP + ((rd(coords) & 0xF8) << 2) + (rd(coords + 1) >> 3)
	wr_word(W_OW_TILEMAP_PTR, address)
	return address


## LoadLevelName: the HDMA (w2d0b5) of map side `side`'s level `level`'s name tiles from
## LevelNamesJPGfx (bank by wLanguage) to v1Tiles2 tile $50, 32 tiles; wHDMA cleared.
func load_level_name(side: int, level: int) -> void:
	w2(W_HDMA_BANK, LEVEL_NAMES_JP_GFX_BANK + r0(W_LANGUAGE))
	w2(W_HDMA, 0)
	var source: int = (LEVEL_NAMES_JP_GFX + (swap(side) << 8) + (((level * 2) & 0xFF) << 8)) & 0xFFFF
	w2(W2D0B5, source >> 8)
	w2(W2D0B5 + 1, source & 0xFF)
	w2(W2D0B5 + 2, 0x15)
	w2(W2D0B5 + 3, 0x00)
	w2(W2D0B5 + 4, 32 - 1)  # 32 dma_tiles


## Func_80bd9 (src/engine/overworld/init.asm): BG priority cleared in wAttrmap at (0, 14) and in the
## 3x4 rectangle from (0, 15).
func func_80bd9() -> void:
	var at: int = W_ATTRMAP + 14 * TILEMAP_WIDTH
	wr(at, rd(at) & ~(1 << B_BG_PRIO))
	for row: int in range(15, 19):
		for column: int in 3:
			at = W_ATTRMAP + row * TILEMAP_WIDTH + column
			wr(at, rd(at) & ~(1 << B_BG_PRIO))


## Func_854ee (src/engine/overworld/bank21.asm): patches of wTilemap and wAttrmap from bank $21 at
## `address`: each a destination (little-endian; 0 ends the list), tiles up to $70, then the same
## count of attributes ($300 bytes before, in wAttrmap) up to $70.
func func_854ee(address: int) -> void:
	var at: int = address
	while true:
		var low: int = rb(0x21, at)
		at += 1
		if low == 0:
			return
		var destination: int = low | (rb(0x21, at) << 8)
		at += 1
		var tiles: int = destination
		while rb(0x21, at) != 0x70:
			wr(tiles, rb(0x21, at))
			tiles += 1
			at += 1
		at += 1
		var attributes: int = (destination - 0x300) & 0xFFFF
		while rb(0x21, at) != 0x70:
			wr(attributes, rb(0x21, at))
			attributes += 1
			at += 1
		at += 1


## SetBGMapBytesPriority (bank $2d): BG priority set on `count` bytes from `address`.
func set_bg_map_bytes_priority(address: int, count: int) -> void:
	for offset: int in count:
		wr(address + offset, rd(address + offset) | (1 << B_BG_PRIO))


# --- decompressions (the decompress_* macros, src/macros/gfx.asm: wTempBank is the data's bank) ---

## A decompress_* into WRAM: (bank, address) through Decompress to `destination`.
func decompress_to_wram(bank: int, address: int, destination: int) -> void:
	wTempBank = bank
	var bytes: PackedByteArray = decompress(bank, address)
	for offset: int in bytes.size():
		wr(destination + offset, bytes[offset])


## A decompress_tiles0/1, decompress_tilemap/attrmap into VRAM bank `vram_bank` from `destination`:
## wTempBank, the decompression recorded for drawing, and the bytes that land in BG map 0 kept for the
## rows the map reads back.
func decompress_to_vram(bank: int, address: int, vram_bank: int, destination: int) -> void:
	wTempBank = bank
	vram_writes.append(["decompress", vram_bank, destination, bank, address])
	if destination < 0x9800 or destination >= 0x9C00:
		return  # tiles, BG map 1: not read back
	var bytes: PackedByteArray = decompress(bank, address)
	var map: PackedByteArray = _bg_map_0(vram_bank)
	for offset: int in bytes.size():
		if destination - 0x9800 + offset < map.size():
			map[destination - 0x9800 + offset] = bytes[offset]


## FillBGMap0_With7f (src/home/clear_memory.asm): v1BGMap0 cleared, v0BGMap0 filled with $7f.
func fill_bg_map_0_with_7f() -> void:
	_bg_map_0(1).fill(0x00)
	_bg_map_0(0).fill(0x7F)
	vram_writes.append(["bytes", 1, 0x9800, _bg_map_0(1).duplicate()])
	vram_writes.append(["bytes", 0, 0x9800, _bg_map_0(0).duplicate()])


## WriteBGMapFromWRAM (init.asm): wTilemap's and wAttrmap's first 19 rows to BG map 0.
func write_bg_map_from_wram() -> void:
	for offset: int in 19 * TILEMAP_WIDTH:
		_bg_map_0(0)[offset] = rd(W_TILEMAP + offset)
		_bg_map_0(1)[offset] = rd(W_ATTRMAP + offset)
	record_wram_to_vram(0, 0x9800, W_TILEMAP, 19 * TILEMAP_WIDTH)
	record_wram_to_vram(1, 0x9800, W_ATTRMAP, 19 * TILEMAP_WIDTH)


## The top bar's rows 30 and 31 of BG map 0 copied into wAttrmap (Func_8065e, Func_b4247): the tiles
## to its row 21, the attributes to its row 19, 2 rows each (they are put back from there when the
## top bar opens).
func copy_top_bar_rows_to_wram() -> void:
	for offset: int in 2 * TILEMAP_WIDTH:
		wr(W_ATTRMAP + 21 * TILEMAP_WIDTH + offset, _bg_map_0(0)[30 * TILEMAP_WIDTH + offset])
		wr(W_ATTRMAP + 19 * TILEMAP_WIDTH + offset, _bg_map_0(1)[30 * TILEMAP_WIDTH + offset])


func _bg_map_0(vram_bank: int) -> PackedByteArray:
	if bg_map_0[vram_bank].size() != 0x400:
		bg_map_0[vram_bank] = PackedByteArray()
		bg_map_0[vram_bank].resize(0x400)
	return bg_map_0[vram_bank]


# --- drawing: what goes to VRAM, the palettes, and the LCD (recorded, RAM only read) ---

## `count` bytes of WRAM from `source` (the map's view: WRAMX bank 2 from $d000) to VRAM bank
## `vram_bank` at `address`; those that land in BG map 0 kept for the rows the map reads back.
func record_wram_to_vram(vram_bank: int, address: int, source: int, count: int) -> void:
	var bytes := PackedByteArray()
	bytes.resize(count)
	for offset: int in count:
		bytes[offset] = rd(source + offset)
		if address + offset >= 0x9800 and address + offset < 0x9C00:
			_bg_map_0(vram_bank)[address + offset - 0x9800] = bytes[offset]
	vram_writes.append(["bytes", vram_bank, address, bytes])


## Bytes the CPU writes to VRAM bank `vram_bank` at `address` (the LCD off); those that land in BG map
## 0 kept for the rows the map reads back.
func record_bytes_to_vram(vram_bank: int, address: int, bytes: PackedByteArray) -> void:
	for offset: int in bytes.size():
		if address + offset >= 0x9800 and address + offset < 0x9C00:
			_bg_map_0(vram_bank)[address + offset - 0x9800] = bytes[offset]
	vram_writes.append(["bytes", vram_bank, address, bytes])


## A copy or DMA of `count` bytes from `source` on the bus (the ROM with `rom_bank` in $4000-$7fff, or
## WRAM with bank 2 in) to VRAM bank `vram_bank` at `address`.
func record_copy_to_vram(vram_bank: int, address: int, source: int, count: int, rom_bank: int) -> void:
	if source < 0x8000:
		vram_writes.append(["rom", vram_bank, address, 0 if source < 0x4000 else rom_bank, source, count])
	elif source >= 0xC000 and source + count <= 0xE000:
		record_wram_to_vram(vram_bank, address, source, count)
	else:
		_note("a copy to VRAM from $%04x (not RAM or ROM)" % source)


## A general-purpose DMA (rVDMA_SRC_HIGH to rVDMA_LEN: source high and low, destination high and low,
## length in $10-byte blocks less one) from the 5 bytes at `config`, to VRAM bank `vram_bank`, with
## `rom_bank` switched in. The map's lengths never set bit 7 (an H-Blank DMA).
func record_gdma(vram_bank: int, config: int, rom_bank: int) -> void:
	var source: int = ((rd(config) << 8) | rd(config + 1)) & 0xFFF0
	var destination: int = 0x8000 | (((rd(config + 2) << 8) | rd(config + 3)) & 0x1FF0)
	if (rd(config + 4) & 0x80) != 0:
		_note("an H-Blank DMA from $%04x (not modelled)" % source)
		return
	record_copy_to_vram(vram_bank, destination, source, ((rd(config + 4) & 0x7F) + 1) * 0x10, rom_bank)


## Func_1d8c2c (bank $76, in the map's V-Blank functions): the clouds' and sea's 12 tiles from
## wTilemap tile $24 to VRAM 1's v1Tiles2 tile $70 ($9700), then with a source in w2d044 (high byte
## first) the cliffs' 20 tiles from bank $76 to $8ec0.
func record_func_1d8c2c() -> void:
	record_copy_to_vram(1, 0x9700, W_TILEMAP + 0x24 * 0x10, 12 * 0x10, CLIFFS_GFX_BANK)
	if r2(W2D044) != 0:
		record_copy_to_vram(1, 0x8EC0, ((r2(W2D044) << 8) | r2(W2D044 + 1)) & 0xFFF0, 20 * 0x10, CLIFFS_GFX_BANK)


## ApplyPalConfig1, ApplyPalConfig2 (and VBlank_Overworld's copy of them): the pal_config_struct at
## `config`: its index to its register (rBGPI or rOBPI), then its number of palettes (0: 256) from
## its source (high byte first) to the data register.
func record_pal_config(config: int) -> void:
	var number: int = r2(config + 2)
	var source: int = (r2(config + 3) << 8) | r2(config + 4)
	var bytes := PackedByteArray()
	bytes.resize((number if number != 0 else 0x100) * 8)
	for offset: int in bytes.size():
		bytes[offset] = rd(source + offset)
	palette_writes.append(["palettes", r2(config) == LOW_R_OBPI, r2(config + 1), bytes])


## DrawCoinCount (bank $26): wNumCoins' three digits (hundreds, tens, ones), two tiles each from
## NumbersGfx, to VRAM 0 from v0Tiles1 tile $0a ($88a0).
func draw_coin_count() -> void:
	var digits: Array = [r0(W_NUM_COINS) & 0x0F, r0(W_NUM_COINS + 1) >> 4, r0(W_NUM_COINS + 1) & 0x0F]
	for index: int in digits.size():
		vram_writes.append(["rom", 0, 0x88A0 + index * 0x20, NUMBERS_GFX_BANK, NUMBERS_GFX + int(digits[index]) * 0x20,
				0x20])


## DisableLCD: the LCD off (once the frame is drawn).
func disable_lcd() -> void:
	register_writes.append(["lcdc_off"])


## rLCDC set.
func set_lcdc(value: int) -> void:
	register_writes.append(["lcdc", value])


## rWX and rWY set.
func set_window(wx: int, wy: int) -> void:
	register_writes.append(["window", wx & 0xFF, wy & 0xFF])


# --- animation and sprites ---

## UpdateOWAnimation: the duration at `duration` (then the frameset offset) counts down; at its end
## the next (frame, duration) of the frameset at (bank, `frameset`) is taken (the frame two bytes
## before the duration), or at the frameset's $ff its start again with wOWAnimationFinished set to
## $ff. Returns the object's address (the duration's, 8-aligned).
func update_ow_animation(duration: int, frameset: int, bank: int) -> int:
	w2(W_OW_ANIMATION_FINISHED, 0)
	var left: int = rd(duration) - 1
	wr(duration, left)
	if left >= 0:
		return duration & 0xFFF8
	var offset: int = rd(duration + 1)
	var pointer: int = (frameset + offset) & 0xFFFF
	var frame: int = rb(bank, pointer)
	if frame == 0xFF:
		w2(W_OW_ANIMATION_FINISHED, 0xFF)
		pointer = frameset
		frame = rb(bank, frameset)
		offset = 0
	wr(duration + 1, offset + 2)
	wr(duration, rb(bank, pointer + 1) - 1)
	wr(duration - 2, frame)
	return duration & 0xFFF8


## LoadOWSpriteWithScroll: the object at `obj` (y, x, frame, attributes) drawn on screen (the scroll
## taken off, the OAM offsets added) with the OAM table at (bank, `table`).
func load_ow_sprite_with_scroll(obj: int, table: int, bank: int) -> void:
	wCurSpriteYCoord = byte(rd(obj) - sim.wSCY + 0x10)
	wCurSpriteXCoord = byte(rd(obj + 1) - sim.wSCX + 0x08)
	wCurSpriteFrame = rd(obj + 2)
	wCurSpriteAttributes = rd(obj + 3)
	load_ow_sprite_got_params(table, bank)


## LoadOWSprite: the same without the scroll.
func load_ow_sprite(obj: int, table: int, bank: int) -> void:
	wCurSpriteYCoord = byte(rd(obj) + 0x10)
	wCurSpriteXCoord = byte(rd(obj + 1) + 0x08)
	wCurSpriteFrame = rd(obj + 2)
	wCurSpriteAttributes = rd(obj + 3)
	load_ow_sprite_got_params(table, bank)


## LoadOWSpriteWithScroll_GotParams, LoadSprite (src/home/sprite.asm): frame wCurSpriteFrame of the
## OAM table at (bank, `table`) appended to the virtual OAM at wCurSpriteYCoord and wCurSpriteXCoord,
## its entries' attributes xored with wCurSpriteAttributes, until $80 or the OAM is full.
func load_ow_sprite_got_params(table: int, bank: int) -> void:
	var at: int = rw(bank, (table + ((wCurSpriteFrame * 2) & 0xFF)) & 0xFFFF)
	while wVirtualOAMByteSize < OAM_SIZE:
		var y: int = rb(bank, at)
		if y == 0x80:
			return
		wVirtualOAM[wVirtualOAMByteSize] = byte(y + wCurSpriteYCoord)
		wVirtualOAM[wVirtualOAMByteSize + 1] = byte(rb(bank, at + 1) + wCurSpriteXCoord)
		wVirtualOAM[wVirtualOAMByteSize + 2] = rb(bank, at + 2)
		wVirtualOAM[wVirtualOAMByteSize + 3] = rb(bank, at + 3) ^ wCurSpriteAttributes
		wVirtualOAMByteSize += 4
		at += 4
