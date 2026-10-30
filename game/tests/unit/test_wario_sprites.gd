extends TestCase
## Wario's sprite on invented data (no ROM bytes): tile pairs, flips, palettes, OAM placement,
## DrawWario's visibility, and the graphics each state names.


## Tile 0: colour 1 in its top-left pixel; tile 1: colour 3 in its bottom-right pixel; the rest 0.
func _document() -> Dictionary:
	var tiles := PackedByteArray()
	tiles.resize(128 * WarioSprites.TILE_BYTES)
	tiles[0] = 0x80  # tile 0, row 0, low plane: leftmost pixel
	tiles[16 + 14] = 0x01  # tile 1, row 7: rightmost pixel in both planes
	tiles[16 + 15] = 0x01
	return {
		"tile_sets": {"04:4000": {"tiles": tiles.hex_encode()}},
		"oam_tables": {"05:4000": {"frames": [[[-16, -8, 0, 0], [-16, 0, 0, 0x20]], [[-31, -12, 2, 1]]]}},
		"palettes": {"03:4800": {"colours": [[[0, 0, 0], [31, 0, 0], [0, 31, 0], [0, 0, 31]],
				[[0, 0, 0], [1, 1, 1], [2, 2, 2], [3, 3, 3]]]}},
	}


func test_a_pair_is_the_even_tile_over_the_odd_one_and_colour_0_is_clear() -> void:
	var image: Image = WarioSprites.from_document(_document()).pair_sheet("04:4000", "03:4800", 0, 0)
	assert_eq(image.get_pixel(0, 0), Color8(255, 0, 0), "tile 0's pixel, colour 1")
	assert_eq(image.get_pixel(7, 15), Color8(0, 0, 255), "tile 1's pixel, colour 3, in the bottom half")
	assert_eq(image.get_pixel(1, 0).a, 0.0, "colour 0 is transparent")
	assert_eq(WarioSprites.pair_rect(3), Rect2i(8, 0, 8, 16), "tiles 2 and 3 are the second pair")


func test_flips_mirror_the_whole_pair() -> void:
	var sprites: WarioSprites = WarioSprites.from_document(_document())
	assert_eq(sprites.pair_sheet("04:4000", "03:4800", 0, WarioSprites.ATTR_X_FLIP).get_pixel(7, 0), Color8(255, 0, 0))
	var y_flipped: Image = sprites.pair_sheet("04:4000", "03:4800", 0, WarioSprites.ATTR_Y_FLIP)
	assert_eq(y_flipped.get_pixel(0, 15), Color8(255, 0, 0), "tile 0 moves to the bottom")
	assert_eq(y_flipped.get_pixel(7, 0), Color8(0, 0, 255), "tile 1 moves to the top")
	assert_eq(sprites.pair_sheet("04:4000", "03:4800", 1, 0).get_pixel(0, 0), Color8(8, 8, 8), "OBJ palette 1")


func test_entries_add_the_screen_position_as_bytes_and_xor_the_attributes() -> void:
	var sprites: WarioSprites = WarioSprites.from_document(_document())
	var drawn: Dictionary = {"screen_x": 4, "screen_y": 100, "frame": 0, "attributes": 0x20,
			"oam_table": "05:4000", "tile_set": "04:4000", "palettes": "03:4800"}
	assert_true(sprites.can_draw(drawn))
	assert_eq(sprites.entries(drawn), [[84, 252, 0, 0x20], [84, 4, 0, 0]], "x 4 - 8 wraps to 252, off the screen")
	drawn["frame"] = 2
	assert_true(not sprites.can_draw(drawn), "no frame 2 in the table")


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.wWarioScreenXPos = 88
	sim.wWarioScreenYPos = 120
	sim.wWarioOAMBank = 0x05
	sim.wWarioOAMPtr = 0x4000
	sim.wDMASourceBank = 0x04
	sim.wDMASourcePtr = 0x4000
	sim.wWarioPalsPtr = WarioRam.WARIO_DEFAULT_PAL
	return sim


func test_draw_wario_records_the_frame_unless_invisible_frame_is_set() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioFrame = 1
	sim.draw_wario()
	assert_eq(sim.drawn_wario, {"screen_x": 88, "screen_y": 120, "frame": 1, "attributes": 0,
			"oam_table": "05:4000", "tile_set": "04:4000", "palettes": "03:4800"})
	sim.wInvisibleFrame = 1
	sim.draw_wario()
	assert_eq(sim.drawn_wario, {}, "the invincibility flicker's hidden frames")


func test_invisible_wario_shows_in_a_few_frames_of_sixteen() -> void:
	var sim: LevelSim = _sim()
	sim.wTransformation = WarioRam.TRANSFORMATION_INVISIBLE_WARIO
	sim.wInvisibleFrame = 0xEF
	var shown: Array = []
	for i: int in 16:
		sim.draw_wario()
		if not sim.drawn_wario.is_empty():
			shown.append(sim.wInvisibleFrame)
	assert_eq(shown, [0xF0, 0xF1, 0xF4, 0xF5, 0xF8, 0xF9, 0xFC, 0xFD], "upper 4 bits set and bit 2 clear")


## A flat synthetic level (floor at row 10) started by LevelRunner, Wario idling on it.
func _level_sim() -> LevelSim:
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		row.fill(1 if y == 10 else 0)
		rows.append(row.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	var level: LevelCollision = LevelCollision.from_document({
		"block_rows": rows,
		"rooms": [{"level_room_id": 0, "handlers": handlers, "fields": {"camera_config": 0x18}}],
		"start": {"level_room_id": 0, "wario_x": 40, "wario_y": 160},
	})
	var tables: WarioTables = WarioTables.from_document({
		"walk_vel_table": {"steps": []}, "jump_vel_tables": [],
		"framesets": {"4252": {"pairs": [[7, 9]]}, "425f": {"pairs": [[3, 9]]}},
	})
	return LevelRunner.start(tables, level)


func test_states_name_their_tile_set_oam_table_and_frame() -> void:
	var sim: LevelSim = _level_sim()
	assert_eq([sim.wDMASourceBank, sim.wDMASourcePtr, sim.wWarioOAMBank, sim.wWarioOAMPtr, sim.wWarioFrame],
			[0x04, 0x4000, 0x05, 0x4000, 3], "WarioIdleGfx, OAM_14000, Frameset_1425f's first frame")
	assert_eq([sim.wWarioPalsPtr, sim.wIsDMATransferPending], [WarioRam.WARIO_DEFAULT_PAL, 1])
	assert_eq(sim.drawn_wario.get("oam_table"), "05:4000", "the level start draws Wario")


func test_invincibility_toggles_the_invisible_frame_and_restores_the_palette() -> void:
	var sim: LevelSim = _level_sim()
	sim.wInvincibleCounter = 1
	sim.wWarioPalsPtr = WarioRam.WARIO_INVISIBLE_PAL
	sim.handle_invincibility()
	assert_eq([sim.wInvincibleCounter, sim.wWarioPalsPtr], [0x10, WarioRam.WARIO_DEFAULT_PAL])
	sim.wGlobalCounter = 4
	sim.handle_invincibility()
	assert_eq([sim.wInvincibleCounter, sim.wInvisibleFrame], [0x11, 1], "every 4th frame from $10")
	sim.wInvincibleCounter = 0x27
	sim.wGlobalCounter = 2
	sim.handle_invincibility()
	assert_eq([sim.wInvincibleCounter, sim.wInvisibleFrame], [0, 0], "the end clears it")
