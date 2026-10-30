extends TestCase
## The map's drawing (OverworldSim's records, OverworldVram) on invented data (no ROM bytes): its
## set-ups' decompressions and copies, VBlank_Overworld's DMAs and palette config, the fades' palettes,
## the LCD's registers, a rendered tile, and the view. The drawing itself is checked against the
## owner's movies (make wario-parity: the map's VRAM snapshots and screens).

func _map(banks: Dictionary = {}) -> OverworldSim:
	var map := OverworldSim.new(LevelSim.new())
	var document: Dictionary = {"banks": {}}
	for bank: int in banks:
		document["banks"]["%02x" % bank] = banks[bank]
	map.load_data(document)
	return map


func test_a_set_ups_decompression_and_the_coins_land_in_vram() -> void:
	# NumbersGfx (bank $26 from $5980): digit d's two tiles all $10 + d.
	var numbers: String = "00".repeat(0x1980)
	for digit: int in 10:
		numbers += ("%02x" % (0x10 + digit)).repeat(0x20)
	var map: OverworldSim = _map({0x22: "03aa82010200", 0x26: numbers})
	map.w0(OverworldSim.W_NUM_COINS, 0x01)
	map.w0(OverworldSim.W_NUM_COINS + 1, 0x23)
	map.decompress_to_vram(0x22, 0x4000, 1, 0x8200)  # three $aa, then $01 $02
	map.draw_coin_count()
	var vram := OverworldVram.new(map.document)
	vram.update(map)
	assert_eq([vram.read_byte(1, 0x8200), vram.read_byte(1, 0x8203), vram.read_byte(1, 0x8204), vram.written[1][0x205]],
			[0xAA, 0x01, 0x02, 0], "the RLE's bytes, nothing after them")
	assert_eq([vram.read_byte(0, 0x88A0), vram.read_byte(0, 0x88C0), vram.read_byte(0, 0x88FF)], [0x11, 0x12, 0x13],
			"wNumCoins' digits 1, 2, 3 from v0Tiles1 tile $0a")


func test_vblank_overworld_copies_the_clouds_dmas_and_applies_the_palette_config() -> void:
	var map: OverworldSim = _map({0x76: "77".repeat(0x800), 0x25: "55".repeat(0x4000)})
	for offset: int in 12 * 0x10:  # the clouds' and sea's tiles in wTilemap from tile $24
		map.w2(OverworldSim.W_TILEMAP + 0x24 * 0x10 + offset, 0x99)
	map.w2(OverworldSim.W2D044, 0x46)  # the cliffs' source: bank $76's $4640
	map.w2(OverworldSim.W2D044 + 1, 0x40)
	map.w2(OverworldSim.W_WY, 0x78)
	for offset: int in 8:  # wTempBGPals palette 7, one palette to BGPI palette 7
		map.w0(OverworldSim.W_TEMP_BG_PALS + 7 * 8 + offset, 0x1F)
	for pair: Array in [[0, 0x68], [1, 0xB8], [2, 1], [3, 0xC1], [4, 0x38]]:
		map.w2(OverworldSim.W_PAL_CONFIG_1 + int(pair[0]), pair[1])
	map.w0(OverworldSim.W_LANGUAGE, 1)
	map.load_level_name(0, 2)  # w2d0b5: bank $25's $4400, 32 tiles to VRAM 1's $9500
	map.fill(OverworldSim.W_TILE_BUFFER, 0x100, 0x44)
	for pair: Array in [[0, 0xDC], [1, 0x00], [2, 0x09], [3, 0x00], [4, 0x0F]]:  # wHDMA: 16 tiles to $8900
		map.w2(OverworldSim.W_HDMA + int(pair[0]), pair[1])
	map.vblank_overworld()
	var vram := OverworldVram.new(map.document)
	vram.update(map)
	assert_eq([vram.read_byte(1, 0x9700), vram.read_byte(1, 0x97BF), vram.written[1][0x17C0]], [0x99, 0x99, 0],
			"12 tiles from wTilemap tile $24")
	assert_eq([vram.read_byte(1, 0x8EC0), vram.read_byte(1, 0x8FFF), vram.read_byte(1, 0x9500),
			vram.read_byte(1, 0x96FF), vram.read_byte(0, 0x8900), vram.read_byte(0, 0x89FF)],
			[0x77, 0x77, 0x55, 0x55, 0x44, 0x44], "the cliffs, the level's name, wTileBuffer")
	assert_eq([vram.bg_palettes[7 * 8], vram.bg_palettes[7 * 8 + 7], vram.bg_palettes[6 * 8 + 7]], [0x1F, 0x1F, 0])
	assert_eq([vram.wx, vram.wy], [7, 0x78])
	assert_eq([map.r2(OverworldSim.W_PAL_CONFIG_1), map.r2(OverworldSim.W_HDMA), map.r2(OverworldSim.W2D0B5)],
			[0, 0, 0], "each applied, its first byte cleared")


func test_a_fade_stores_the_palettes_then_steps_them_until_its_last_loop() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	var vram := OverworldVram.new(map.document)
	for offset: int in 0x40:  # every colour rgb(16, 16, 16): $4210
		vram.bg_palettes[offset] = 0x10 if (offset & 1) == 0 else 0x42
		vram.obj_palettes[offset] = 0x10 if (offset & 1) == 0 else 0x42
	sim.wSubState = 0x08  # FadeBGToWhite_Normal
	var shown: Array = []
	while sim.wSubState == 0x08:
		map.update()
		vram.update(map)
		shown.append(vram.bg_palettes[0] | (vram.obj_palettes[1] << 8))
	assert_eq([shown.size(), shown[0], shown[1], shown[2], shown[15], shown[17]],
			[18, 0x4210, 0x4A52, 0x5294, 0x7FFF, 0x7FFF], "stored, then 2 a step on each channel to white")
	for offset: int in 0x80:  # the targets: rgb(3, 5, 7) everywhere
		map.w0(OverworldSim.W_TEMP_PALS_1 + offset, 0xA3 if (offset & 1) == 0 else 0x1C)
	sim.wSubState = 0x0A  # DarkenBGToPal_Normal
	while sim.wSubState == 0x0A:
		map.update()
		vram.update(map)
	assert_eq([vram.bg_palettes[0], vram.bg_palettes[1], vram.obj_palettes[0x3E], vram.obj_palettes[0x3F]],
			[0xA3, 0x1C, 0xA3, 0x1C], "down to wTempPals1 and wTempPals2")


func test_darkening_a_channel_already_at_zero_wraps_it_as_the_original_does() -> void:
	var vram := OverworldVram.new()
	var black := PackedByteArray()
	black.resize(0x80)
	vram.fade(false, 0, 1, black)  # FADE_SPEED_SLOW, black toward black
	assert_eq([vram.fade_pals[0], vram.fade_pals[1], vram.bg_palettes[0], vram.bg_palettes[1]],
			[0xFF, 0xFF, 0xFF, 0xFF], "dec [hl] from 0 is $ff, not zero: kept above the target")


func test_the_lcd_follows_the_set_ups_and_vblank_cutscene_flips_it() -> void:
	var map: OverworldSim = _map()
	var vram := OverworldVram.new(map.document)
	map.disable_lcd()
	map.set_lcdc(OverworldSim.LCDC_CUTSCENE)
	vram.update(map)
	assert_eq(vram.lcdc, 0xC7)
	map.register_writes.clear()
	map.w2(OverworldSim.W_LCDC_FLAGS_TO_FLIP, OverworldSim.LCDC_BG_MAP)
	map.w2(OverworldSim.W_CUTSCENE_WY, 0x10)
	map.w2(OverworldSim.W_CUTSCENE_WX, 0x20)
	map.vblank_cutscene()
	vram.update(map)
	assert_eq([vram.lcdc, vram.wx, vram.wy, map.r2(OverworldSim.W_LCDC_FLAGS_TO_FLIP)], [0xCF, 0x20, 0x10, 0])
	map.register_writes.clear()
	map.disable_lcd()
	vram.update(map)
	assert_eq(vram.lcdc, 0x4F, "DisableLCD clears bit 7 only")


func test_a_tile_written_through_the_records_renders_with_its_palette() -> void:
	var map: OverworldSim = _map()
	var row := PackedByteArray([0xFF, 0x00])  # colour 1 across
	var tile := PackedByteArray()
	for line: int in 8:
		tile.append_array(row)
	map.vram_writes.append(["bytes", 0, 0x9000, tile])  # tile 0 with LCDC_DEFAULT's $8800 addressing
	map.vram_writes.append(["bytes", 0, 0x9800, PackedByteArray([0])])
	map.vram_writes.append(["bytes", 1, 0x9800, PackedByteArray([0])])
	map.palette_writes.append(["palettes", false, 0x82, PackedByteArray([0x1F, 0x00])])  # palette 0 colour 1: red
	map.set_lcdc(OverworldSim.LCDC_DEFAULT)
	var vram := OverworldVram.new(map.document)
	vram.update(map)
	var oam := PackedByteArray()
	oam.resize(0xA0)
	var pixels: PackedByteArray = CgbScreen.new().render(vram, oam, vram.lcdc, 0, 0, vram.wx, vram.wy)
	assert_eq(pixels.slice(0, 3), PackedByteArray([248, 0, 0]))


func test_the_view_draws_the_map_once_set_up_and_whitens_it_after_the_save_screen() -> void:
	var sim := LevelSim.new()
	sim.load_overworld_data({"banks": {}})
	sim.load_pause_menu_data({})
	var view := LevelView.new()
	view._sim = sim
	sim.wState = LevelSim.ST_OVERWORLD
	sim.wSubState = 0x0A
	var map: OverworldSim = sim.overworld
	map.loops += 1  # a loop that set up a map side (InitMapSide's records)
	map.screen_loads.append(["map_side", 0])
	map.set_lcdc(OverworldSim.LCDC_MAP_SIDE)
	view.after_loop()
	assert_eq([view._overworld_vram.screen, view._overworld_vram.lcdc, view._overworld_shown()],
			["map_side", 0xE7, true])
	sim.wState = LevelSim.ST_PAUSE_MENU
	sim.wSubState = 0x21  # back to the map
	sim.wPendingSubState = 0x09
	sim.update_level()
	view.after_loop()
	assert_eq([sim.wState, view._overworld_vram.bg_palettes[0], view._overworld_vram.obj_palettes[0x3F]],
			[LevelSim.ST_OVERWORLD, 0xFF, 0x7F])
	view.free()
