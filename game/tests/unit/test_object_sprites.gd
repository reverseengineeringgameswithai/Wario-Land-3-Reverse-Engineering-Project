extends TestCase
## Objects' sprites on invented data (no ROM bytes): the draw order DrawObjects keeps, entries at the
## screen position, palettes by OBJ palette, and tiles from VRAM bank 1 or the common graphics.


func _document() -> Dictionary:
	var vram1 := PackedByteArray()
	vram1.resize(0x1000)
	vram1[2 * 16] = 0x80  # tile 2 (pair 1, top): colour 1 in its top-left pixel
	var common := PackedByteArray()
	common.resize(0x800)
	common[1] = 0x80  # tile $80 (bank 0, pair $40, top): colour 2 in its top-left pixel
	var palette: Array = [[0, 0, 0], [31, 0, 0], [0, 31, 0], [0, 0, 31]]
	return {"object_groups": {
		"oam_tables": {"62:4000": [[[-16, -8, 2, 0x0C], [-16, 0, 0x80, 0x03]]]},
		"groups": [{"enemy_vram": vram1.hex_encode(), "palettes": [palette, palette, palette, palette],
				"common_palette": palette}],
		"common_gfx": common.hex_encode(),
	}}


func test_entries_add_the_screen_position_and_palettes_follow_the_attributes() -> void:
	var sprites: ObjectSprites = ObjectSprites.from_document(_document())
	var drawn: Dictionary = {"oam_table": "62:4000", "frame": 0, "screen_y": 100, "screen_x": 50}
	assert_true(sprites.can_draw(drawn))
	assert_eq(sprites.entries(drawn), [[84, 42, 2, 0x0C], [84, 50, 0x80, 0x03]])
	assert_eq(sprites.palette(0, 4).size(), 4, "OBJ palette 4: the group's first")
	assert_eq(sprites.palette(0, 1), [], "Wario's palettes are not the objects' to draw")
	var bank1: Image = sprites.pair_sheet(0, 1, sprites.palette(0, 4), 4, 0)
	assert_eq(bank1.get_pixel(8, 0), Color8(255, 0, 0), "tile 2 is the top of pair 1")
	var bank0: Image = sprites.pair_sheet(0, 0, sprites.palette(0, 3), 3, 0)
	assert_eq(bank0.get_pixel(0, 4 * 16), Color8(0, 255, 0), "tile $80 is common graphics, pair $40")


func test_draw_objects_lists_priority_objects_first_and_skips_invisible_ones() -> void:
	var sim := LevelSim.new()
	for slot: int in 3:
		var base: int = slot * 32
		sim.wram1[base] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN
		sim.wram1[base + ObjectSim.OBJ_ID] = 0x10 * slot
		sim.wram1[base + ObjectSim.OBJ_OAM_PTR + 1] = 0x40
	sim.wram1[32] |= ObjectSim.OBJFLAG_PRIORITY
	sim.wram1[64] |= ObjectSim.OBJFLAG_INVISIBLE
	sim.wObjectGroup = 7
	sim.draw_objects()
	assert_eq(sim.drawn_objects.map(func(item: Dictionary) -> String: return item["oam_table"]), ["61:4000", "60:4000"])
	assert_eq([sim.drawn_objects[0]["over_wario"], sim.drawn_objects[1]["over_wario"], sim.drawn_object_group], [true, false, 7])


func test_particles_draw_from_bank_0_with_warios_tiles_below_80() -> void:
	var document: Dictionary = _document()
	document["particles"] = {"bank": "03", "oam_tables": {"520e": [[[-8, -4, 0x80, 0x02]]]},
			"palette": [[0, 0, 0], [31, 31, 31], [0, 0, 31], [0, 0, 0]]}
	var sprites: ObjectSprites = ObjectSprites.from_document(document)
	var drawn: Dictionary = {"oam_table": "03:520e", "frame": 0, "screen_y": 40, "screen_x": 30}
	assert_eq(sprites.entries(drawn), [[32, 26, 0x80, 0x02]])
	var wario := PackedByteArray()
	wario.resize(0x800)
	wario[0] = 0x80  # tile 0: colour 1 in its top-left pixel
	var sheet: Image = sprites.bank0_sheet("04:4000", wario, sprites.particle_palette, "particles", 0)
	assert_eq(sheet.get_pixel(0, 0), Color8(255, 255, 255), "tile 0 is Wario's")
	assert_eq(sheet.get_pixel(0, 4 * 16), Color8(0, 0, 255), "tile $80 is the common graphics'")


func test_a_particle_is_drawn_at_its_position_less_the_scroll() -> void:
	var sim := LevelSim.new()
	sim.load_particle_framesets({"particles": {"framesets": {"54c5": [[5, 3]]}}})
	sim.wSCY = 0x10
	sim.wSCX = 0x20
	sim.hYPos = 0x0150
	sim.hXPos = 0x0260
	sim.create_particle(WarioParticles.PARTICLE_DUST)
	sim.update_particles()
	assert_eq(sim.drawn_particles, [{"oam_table": "03:520e", "frame": 5, "screen_y": 0x50 + 16 - 0x10,
			"screen_x": 0x60 + 8 - 0x20}])
