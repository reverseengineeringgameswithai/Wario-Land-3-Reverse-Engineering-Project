extends TestCase
## The hidden figure's fight drawn (TempleVram, CgbScreen's palette writes) on invented data (no ROM
## bytes): LoadHiddenFigureGfx's tiles and maps, Wario's tile set over the figure's first tiles, the
## palettes the figure writes, the OAM in UpdateLevel's order, and the scroll with the shake twice.


func _document() -> Dictionary:
	return {"gfx": {
		"raw": {"36:4000": "11".repeat(0x1800), "36:5800": "22".repeat(0x1800)},
		"compressed": {"36:7068": "33".repeat(0x400), "36:7193": "44".repeat(0x400), "36:723b": "55".repeat(52),
				"36:7268": "66".repeat(52)},
		"palettes": {"36:7000": "01".repeat(0x40), "36:7040": "02".repeat(0x28), "13:504b": "09".repeat(0x30)},
	}}


func _vram() -> TempleVram:
	var wario := WarioSprites.from_document({
		"tile_sets": {"04:4000": {"tiles": "77".repeat(0x800)}, "04:4800": {"tiles": "78".repeat(0x800)}},
		"oam_tables": {"05:4000": {"frames": [[[-16, -8, 0, 0], [-16, 0, 2, 0]]]}},
		"palettes": {"03:4800": {"colours": [[[1, 0, 0], [2, 0, 0], [3, 0, 0], [4, 0, 0]],
				[[0, 1, 0], [0, 2, 0], [0, 3, 0], [0, 31, 0]]]}},
	})
	var objects := ObjectSprites.from_document({
		"object_groups": {"oam_tables": {"63:488a": [[[0, 0, 4, 0x0B]]]}},
		"particles": {"bank": "03", "oam_tables": {"4100": [[[0, 0, 6, 0x02]]]},
				"palette": [[0, 0, 1], [0, 0, 2], [0, 0, 3], [0, 0, 4]]},
	})
	return TempleVram.new(_document(), {}, wario, objects)


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.wLevel = LevelSim.THE_TEMPLE
	sim.hidden_figure_gfx_loads = 1
	sim.wDMASourceBank = 0x04
	sim.wDMASourcePtr = 0x4000
	sim.wWarioPalsPtr = 0x4800
	return sim


func test_the_figure_loads_with_warios_tiles_over_its_first() -> void:
	var vram: TempleVram = _vram()
	var sim: LevelSim = _sim()
	vram.update(sim)
	assert_eq([vram.screen, vram.read_byte(0, 0x8000), vram.read_byte(0, 0x87FF), vram.read_byte(0, 0x8800),
			vram.read_byte(1, 0x8000), vram.read_byte(1, 0x97FF)], ["temple", 0x77, 0x77, 0x11, 0x22, 0x22],
			"HiddenFigure1Gfx and 2Gfx, Wario's tile set over bank 0's first $80 tiles")
	assert_eq([vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9BFF), vram.read_byte(0, 0x9C33), vram.read_byte(1, 0x9C33)],
			[0x33, 0x44, 0x55, 0x66], "the figure on BG map 0, the window's 52 entries on BG map 1")
	assert_eq(vram.written[0][0x9C34 - 0x8000], 0, "BG map 1 past them as it was")
	sim.wDMASourcePtr = 0x4800
	vram.update(sim)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(0, 0x8800)], [0x78, 0x11], "a new tile set copied")
	sim.hidden_figure_gfx_loads = 2
	vram.update(sim)
	assert_eq(vram.read_byte(0, 0x8000), 0x78, "loaded again (a second fight): Wario's tiles copied again")


func test_the_palettes_are_the_figures_with_warios_and_the_particles() -> void:
	var vram: TempleVram = _vram()
	var sim: LevelSim = _sim()
	vram.update(sim)
	assert_eq([vram.bg_palettes[0], vram.bg_palettes[0x3F]], [0x01, 0x01], "Pals_db000")
	sim.hidden_figure_bg_pals = HiddenFigureFunctions.PALS_4D04B
	vram.update(sim)
	assert_eq([vram.bg_palettes[0], vram.bg_palettes[0x2F], vram.bg_palettes[0x30]], [0x09, 0x09, 0x01],
			"SetBGPals: palettes 0-5 from the flash, 6-7 Pals_db000's")
	assert_eq([vram.obj_palettes[0], vram.obj_palettes[6], vram.obj_palettes[8 + 6], vram.obj_palettes[8 + 7]],
			[1, 4, 0xE0, 0x03], "Wario's two palettes (green 31 is $03e0)")
	assert_eq([vram.obj_palettes[16 + 2], vram.obj_palettes[16 + 3], vram.obj_palettes[24], vram.obj_palettes[0x3F]],
			[0x00, 0x08, 0x02, 0x02], "the particles' (blue 2 is $0800), then Pals_db040")


func test_the_oam_is_particles_front_objects_wario_then_the_rest() -> void:
	var vram: TempleVram = _vram()
	var sim: LevelSim = _sim()
	sim.drawn_particles = [{"oam_table": "03:4100", "frame": 0, "screen_y": 0x10, "screen_x": 0x20}]
	sim.drawn_objects = [
		{"oam_table": "63:488a", "frame": 0, "screen_y": 0x30, "screen_x": 0x40, "over_wario": true},
		{"oam_table": "63:488a", "frame": 0, "screen_y": 0x50, "screen_x": 0x60, "over_wario": false},
	]
	sim.drawn_wario = {"screen_x": 0x48, "screen_y": 0x70, "frame": 0, "attributes": 0x20, "oam_table": "05:4000",
			"tile_set": "04:4000", "palettes": "03:4800"}
	vram.update(sim)
	assert_eq(Array(vram.oam.slice(0, 24)), [0x10, 0x20, 6, 0x02, 0x30, 0x40, 4, 0x0B, 0x60, 0x40, 0, 0x20,
			0x60, 0x48, 2, 0x20, 0x50, 0x60, 4, 0x0B, 0, 0, 0, 0], "Wario's attributes flip his entries; the rest cleared")
	var many: Array = []
	for i: int in 45:
		many.append({"oam_table": "63:488a", "frame": 0, "screen_y": i, "screen_x": 8, "over_wario": false})
	sim.drawn_objects = many
	vram.update(sim)
	assert_eq([vram.oam[0x9C], vram.oam.size()], [36, 0xA0], "LoadSprite stops at the 40th entry (a particle, Wario, 37 objects)")


func test_the_scroll_shows_the_shake_twice_and_the_window_takes_rwy() -> void:
	var vram: TempleVram = _vram()
	var sim: LevelSim = _sim()
	sim.wCameraConfigFlags = LevelSim.HIDDEN_FIGURE_CAMCONFIG
	sim.wHiddenFigureSCYShake = 0x68
	sim.wSCYShake = 2
	sim.wc08b = 0x30
	sim.wc08d = 0x88
	sim.wSCY = byte(sim.wHiddenFigureSCYShake + sim.wSCYShake)
	sim.wSCX = sim.wc08b
	sim.rWY = byte(sim.wc08d + sim.wSCYShake)
	vram.update(sim)
	assert_eq([vram.scx, vram.scy, vram.wy], [0x30, 0x6C, 0x8A], "LevelVBlankFunc adds wSCYShake to wSCY again")


func test_a_palette_written_while_the_frame_is_drawn_shows_from_the_next_line() -> void:
	var vram := ScreenVram.new()
	vram.bg_palettes.resize(0x40)
	vram.obj_palettes.resize(0x40)
	var fill := PackedByteArray()
	fill.resize(0x400)
	vram.write(0, ScreenVram.BG_MAP_0, fill)
	vram.write(1, ScreenVram.BG_MAP_0, fill)
	var red := PackedByteArray([0x1F, 0, 0x1F, 0, 0x1F, 0, 0x1F, 0])
	var oam := PackedByteArray()
	oam.resize(0xA0)
	var pixels: PackedByteArray = CgbScreen.new().render(vram, oam, 0x91, 0, 0, 0, 0, [[9, CgbScreen.BG_PALETTE, 0, red]])
	assert_eq([pixels[9 * 160 * 3], pixels[10 * 160 * 3], pixels[143 * 160 * 3]], [0, 0xF8, 0xF8],
			"written in line 9's H-Blank: line 10 on in the new colour")


func byte(value: int) -> int:
	return value & 0xFF
