class_name OverworldInit
extends OverworldMapSide
## A map side's set-up (src/engine/overworld/init.asm), translated (WL3-052): InitMapSide
## (SST_OVERWORLD_09) and its sides' routines, Func_8065e (the side's scenes, the top and bottom bars,
## OW Wario, the scene objects, the clouds), and what they call from other banks: _LoadMapSidePals
## (bank $21), _LoadCloudAndSeaGfx (bank $76), and VBlank_Overworld, whose RAM writes run after each
## loop; what they write to VRAM, the palettes, and the LCD is recorded for drawing.

const MAP_PALS_BANK: int = 0x21
const PALS_84000: int = 0x4000
const PALS_84500: int = 0x4500
const PALS_84640: int = 0x4640
const PALS_84900: int = 0x4900
const DATA_8561F: int = 0x561F
# The side's maps (bank $21): tilemap, attrmap by map side.
const OVERWORLD_MAPS: Array = [[0x5BEF, 0x5D79], [0x5F07, 0x60FF], [0x6292, 0x6417], [0x6546, 0x6700]]
const OVERWORLD_TOP_BAR_TILEMAP: int = 0x5B91
const OVERWORLD_TOP_BAR_ATTRMAP: int = 0x5BC4
const OVERWORLD_BOTTOM_BAR_TIME_ATTACK_TILEMAP: int = 0x68F5
const OVERWORLD_BOTTOM_BAR_TIME_ATTACK_ATTRMAP: int = 0x6929
# The side's tiles (decompressed to v0Tiles0): Overworld1Gfx, Overworld2Gfx, Overworld5Gfx,
# Overworld6Gfx by map side.
const OVERWORLD_GFX: Array = [[0x22, 0x4000], [0x22, 0x4D13], [0x23, 0x4000], [0x23, 0x5363]]
const CLOUDS_BANK: int = 0x76
const OVERWORLD_CLOUDS_1_GFX: int = 0x4000
const OVERWORLD_SEA_GFX: int = 0x4400
# The common tiles (bank $22): OverworldCommonGfx (v1Tiles0), OverworldNumbersGfx (v1Tiles0 tile $60),
# OverworldArrowsGfx (v0Tiles1).
const OVERWORLD_COMMON_GFX: int = 0x615C
const OVERWORLD_NUMBERS_GFX: int = 0x77F2
const OVERWORLD_ARROWS_GFX: int = 0x7614
const ALL_CRAYONS: int = 0x7F
const EVENT_REVEAL_CASTLE: int = 0x19
const EVENT_SUMMON_SUN: int = 0x1B
const KEY_CARD_RED: int = 0x33
const KEY_CARD_BLUE: int = 0x34
const MODE_GAME_CLEARED: int = 0x01
const OWBARS_INPUT_TOP: int = 0x04


## InitMapSide (SST_OVERWORLD_09): the LCD off, BG map 0 cleared, the virtual OAM cleared, the
## V-Blank function set, the OW WRAM cleared, the next treasure, day or night (wDayNight's bit 7: the
## spell was just cast, bit 4 switched; from the map's own fade (transition 0) the other way), then
## the side wNextMapSide's set-up.
func init_map_side() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()
	vblank_func = VBLANK_OVERWORLD
	clear_ow_wram()
	get_next_treasure_to_collect()
	var day_night: int = r0(W_DAY_NIGHT)
	if (day_night & 0x80) == 0:
		w2(W2D011, day_night >> 4)
		w0(W_DAY_NIGHT, (day_night & 0xFE) | ((day_night >> 4) & 1))  # bit 0 := bit 4
	else:
		w0(W_DAY_NIGHT, day_night ^ 0x10)  # SwitchDayNight
		w2(W2D011, day_night & ~0x90)
		if wTransitionParam == 0:
			w2(W2D011, r2(W2D011) ^ 1)
			w0(W_DAY_NIGHT, ((r0(W_DAY_NIGHT) & 0xFE) | (r2(W2D011) & 1)) & ~0x80)
	w2(W2D07C, r2(W2D011))
	w2(W2D07D, 0)
	w2(W_CUR_MAP_SIDE, r2(W_NEXT_MAP_SIDE))
	screen_loads.append(["map_side", r2(W_CUR_MAP_SIDE)])
	match r2(W_CUR_MAP_SIDE):
		NORTH, WEST, SOUTH:
			_init_map_side(r2(W_CUR_MAP_SIDE))
		EAST:
			_init_east_map_side()
		_:
			_note("InitMapSide map side %d (past its table)" % r2(W_CUR_MAP_SIDE))


## InitNorthMapSide, InitWestMapSide (Func_80ae7), InitSouthMapSide (Func_80af5), and InitEastMapSide's
## end (Func_80b1b): the palettes, the side's and the common tiles and arrows (VRAM), the side's maps
## to wAttrmap and wTilemap (South: the castle's patch once revealed), then Func_8065e.
func _init_map_side(side: int) -> void:
	load_map_side_pals()
	_load_gfx(OVERWORLD_GFX[side][0], OVERWORLD_GFX[side][1])
	load_overworld_common_gfx()
	_load_gfx(0x22, OVERWORLD_ARROWS_GFX, 0, 0x8800)  # LoadOverworldArrowsGfx: v0Tiles1
	load_bg_maps_to_wram(0x21, OVERWORLD_MAPS[side][0], 0x21, OVERWORLD_MAPS[side][1])
	if side == SOUTH and func_819c6(EVENT_REVEAL_CASTLE) != 0:
		func_854ee(DATA_8561F)
	func_8065e()


## InitEastMapSide: without the Sun Medallion (EVENT_SUMMON_SUN) always night; from the Blue Key
## Card's level without the Red one, no cutscene to play again.
func _init_east_map_side() -> void:
	w2(W_GOT_SUN_MEDALLION, func_819c6(EVENT_SUMMON_SUN))
	if r2(W_GOT_SUN_MEDALLION) == 0:
		w2(W2D011, 0x01)
		w0(W_DAY_NIGHT, (r0(W_DAY_NIGHT) | 0x01) & ~0x80)
	if wTransitionParam == KEY_CARD_BLUE and is_treasure_collected(KEY_CARD_RED) == 0:
		if r2(W_OW_BARS_STATE) == 0:  # SetStoredTransitionParamAsReturnToMap
			w2(W_STORED_TRANSITION_PARAM, TRANSITION_RETURN_TO_MAP)
	_init_map_side(EAST)


## LoadOverworldCommonGfx: OverworldCommonGfx to v1Tiles0, OverworldNumbersGfx to its tile $60.
func load_overworld_common_gfx() -> void:
	_load_gfx(0x22, OVERWORLD_COMMON_GFX, 1, 0x8000)
	_load_gfx(0x22, OVERWORLD_NUMBERS_GFX, 1, 0x8000 + 0x60 * 0x10)


## ClearOWWRAM: the OW WRAM ($d060 to wTilemap's end) cleared.
func clear_ow_wram() -> void:
	fill(OW_WRAM, OW_WRAM_END - OW_WRAM, 0)


## LoadBGMapsToWRAM: the attrmap at (e, hl) decompressed to wAttrmap, then the tilemap at (d, bc) to
## w3d500, which with WRAMX bank 2 switched in is wTilemap (w2dfff keeps d meanwhile).
func load_bg_maps_to_wram(tilemap_bank: int, tilemap: int, attrmap_bank: int, attrmap: int) -> void:
	w2(W2DFFF, tilemap_bank)
	decompress_to_wram(attrmap_bank, attrmap, W_ATTRMAP)
	decompress_to_wram(r2(W2DFFF), tilemap, W_TILEMAP)


## LoadMapSidePals, _LoadMapSidePals (bank $21): the side's BG palettes (Pals_84000, 40 per side; the
## Golf Building's with all crayons on North and West; night's 24 on) to wTempPals1, its OB palettes
## (Pals_84900, 8 per side) to wTempPals2.
func load_map_side_pals() -> void:
	var side: int = r2(W_CUR_MAP_SIDE)
	var at: int = PALS_84000 + side * 40 * 8
	if (r2(W_CRAYON_FLAGS) & ALL_CRAYONS) == ALL_CRAYONS:
		if side == NORTH:
			at = PALS_84500
		elif side == WEST:
			at = PALS_84640
	if r2(W2D011) != 0:
		at += 24 * 8
	copy_rom(MAP_PALS_BANK, at & 0xFFFF, W_TEMP_PALS_1, 8 * 8)
	copy_rom(MAP_PALS_BANK, (PALS_84900 + side * 8 * 8) & 0xFFFF, W_TEMP_PALS_2, 8 * 8)


## Func_80b54: the clouds' and sea's animations: speeds (big clouds $1e, $04, $24, $24 or South's $04;
## the sea $0e; small clouds $14; the cliffs $10), counters and frames cleared, wCloudType 1 on West
## and East.
func func_80b54() -> void:
	var south: bool = r2(W_CUR_MAP_SIDE) == SOUTH
	for pair: Array in [[W2D032, 0x1E], [W2D035, 0x04], [W2D038, 0x24], [W2D03B, 0x04 if south else 0x24],
			[W2D03E, 0x0E], [W2D041, 0x14]]:
		w2(pair[0], pair[1])
		w2(int(pair[0]) + 1, 0)
		w2(int(pair[0]) + 2, 0)
	w2(W2D031, 0)
	w2(W_CLOUD_TYPE, 1 if r2(W_CUR_MAP_SIDE) in [WEST, EAST] else 0)
	w2(W2D049, 0)
	w2(W2D046, 0x10)
	w2(W2D044, 0)
	w2(W2D047, 0)
	w2(W2D048, 0)


## Func_8065e: the side's set-up after its maps: missing treasures' indicators (game cleared, not Time
## Attack), the clouds, the top bar (BG map 0 row 29), the scroll (above the top bar when a bar is
## open), the side's scenes (Func_81dce), the BG priorities, Wario at the level, the scene objects and
## Wario drawn, the clouds' tiles, the bottom bar (BG map 1) and window, the top bar's buttons, the
## top bar's rows kept in wAttrmap, the level's name (or for an exit, the name palette's colours
## cleared), the coins, the compass, the bottom bar's sprites, the LCD on, then the next sub-state.
func func_8065e() -> void:
	var flags: int = r0(W_GAME_MODE_FLAGS)
	w2(W_MISSING_TREASURE_INDICATORS_ENABLED, 0 if (flags & MODE_TIME_ATTACK) != 0 else flags & MODE_GAME_CLEARED)
	func_80b54()
	decompress_to_vram(0x21, OVERWORLD_TOP_BAR_TILEMAP, 0, 0x9800 + 29 * TILEMAP_WIDTH)
	decompress_to_vram(0x21, OVERWORLD_TOP_BAR_ATTRMAP, 1, 0x9800 + 29 * TILEMAP_WIDTH)
	sim.wSCY = 0xEC if r2(W_OW_BARS_STATE) != 0 else 0x04
	sim.wSCX = 0
	wVirtualOAMByteSize = 0
	func_81dce()
	show_missing_treasure_indicators()
	func_80bd9()
	write_bg_map_from_wram()
	func_8212c()
	w2(W_LEVEL_2, r2(W_MAP_SIDE_LEVEL_ID))
	w2(W2D068, r2(W_MAP_SIDE_LEVEL_ID))
	w2(W_LEVEL_ARROW_DIRECTIONS_1, 0)
	set_ow_wario_oam(OWWARIO_DOWN)
	func_b4a3d()
	func_82041()
	func_b4aa9()
	load_cloud_and_sea_gfx()
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) == 0:
		decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TREASURES_TILEMAP, 0, 0x9C00)
		decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TREASURES_ATTRMAP, 1, 0x9C00)
	else:
		decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TIME_ATTACK_TILEMAP, 0, 0x9C00)
		decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TIME_ATTACK_ATTRMAP, 1, 0x9C00)
	w2(W_WX, 0)
	w2(W_WY, SCREEN_HEIGHT_PX)
	set_window(0, SCREEN_HEIGHT_PX)
	w2(W_BOTTOM_BAR_ACTION, 0)  # BOTBAR_CLOSED
	w2(W_HAS_MAGNIFYING_GLASS, is_treasure_collected(MAGNIFYING_GLASS))
	w2(W_TOP_BAR_SELECTABLE_BUTTONS, TOPBAR_COLLECTION)  # the collection is always selectable
	set_day_night_spell_selectable()
	set_cutscene_button_selectable()
	set_next_prev_map_buttons_selectable()
	update_next_prev_map_buttons_selectable()
	copy_top_bar_rows_to_wram()
	if r2(W_OW_BARS_STATE) == OWBARS_INPUT_TOP:
		init_top_bar_buttons()
		# the top bar's rows back to BG map 0's rows 30 and 31: the tiles, then the attributes
		record_wram_to_vram(0, 0x9800 + 30 * TILEMAP_WIDTH, W_ATTRMAP + 21 * TILEMAP_WIDTH, 2 * TILEMAP_WIDTH)
		record_wram_to_vram(1, 0x9800 + 30 * TILEMAP_WIDTH, W_ATTRMAP + 19 * TILEMAP_WIDTH, 2 * TILEMAP_WIDTH)
		wTransitionParam = r2(W2D02C)  # (the music, not ported)
	load_level_name_if_valid()
	var name_shown: int = 1
	if r2(W_MAP_SIDE_LEVEL_ID) >= OW_EXITS:
		fill(W_TEMP_PALS_1 + 7 * 8 + 1 * 2, 6, 0)  # wTempPals1 palette 7 colours 1 to 3
		name_shown = 0
	w2(W2D0E0, name_shown)
	draw_coin_count()
	set_compass_sprite()
	if r2(W_OW_BARS_STATE) == 0:
		draw_bottom_bar()
	w2(W_LEVEL_ARROW_DIRECTIONS_1, 0)
	w2(W_OW_PAL_TRANSITION_STATE, 0)
	w2(W2D013, 0)
	set_lcdc(LCDC_MAP_SIDE)
	sim.wSubState = byte(sim.wSubState + 1)


## LoadCloudAndSeaGfx, _LoadCloudAndSeaGfx (bank $76): the clouds' tiles by wCloudType (8 tiles) and the
## sea's (4) to VRAM 1's v1Tiles2 tile $70 and to wTilemap tile $24 on (where the clouds' and sea's
## animations are built for the V-Blank's DMA).
func load_cloud_and_sea_gfx() -> void:
	var clouds: int = (OVERWORLD_CLOUDS_1_GFX + (((r2(W_CLOUD_TYPE) * 2) & 0xFF) << 8)) & 0xFFFF
	vram_writes.append(["rom", 1, 0x9700, CLOUDS_BANK, clouds, 8 * 0x10])
	vram_writes.append(["rom", 1, 0x9780, CLOUDS_BANK, OVERWORLD_SEA_GFX, 4 * 0x10])
	copy_rom(CLOUDS_BANK, clouds, W_TILEMAP + 0x24 * 0x10, 8 * 0x10)
	copy_rom(CLOUDS_BANK, OVERWORLD_SEA_GFX, W_TILEMAP + 0x2C * 0x10, 4 * 0x10)


## VBlank_Overworld's function, run after the loop (V-Blank): the scroll and the window (wWX + 7,
## wWY), Func_1d8c2c's DMAs, wPalConfig1 applied, wHDMA's DMA to VRAM 0 and w2d0b5's to VRAM 1 (from the
## ROM in wHDMABank, or WRAM), the OAM; its RAM writes: wPalConfig1's, wHDMA's, and w2d0b5's first bytes
## cleared once applied.
func vblank_overworld() -> void:
	set_window(r2(W_WX) + 7, r2(W_WY))
	record_func_1d8c2c()
	if r2(W_PAL_CONFIG_1) != 0:
		record_pal_config(W_PAL_CONFIG_1)
		w2(W_PAL_CONFIG_1, 0)
	if r2(W_HDMA) != 0:
		record_gdma(0, W_HDMA, r2(W_HDMA_BANK))
		w2(W_HDMA, 0)
	if r2(W2D0B5) != 0:
		record_gdma(1, W2D0B5, r2(W_HDMA_BANK))
		w2(W2D0B5, 0)
