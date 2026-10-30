extends TestCase
## The map (OverworldSim) on invented data (no ROM bytes): its ROM view and RLE, the fades, the way to
## the save screen after a level, the level's routing to it, the top bar's buttons and scroll, and the
## treasure collection's cursor, pages, and boxes. The map itself is checked against the owner's movies
## and power-on movies (make wario-parity).

func _map(banks: Dictionary = {}) -> OverworldSim:
	var map := OverworldSim.new(LevelSim.new())
	var document: Dictionary = {"banks": {}}
	for bank: int in banks:
		document["banks"]["%02x" % bank] = banks[bank]
	map.load_data(document)
	return map


func test_the_rom_view_reads_banks_from_their_start_and_notes_a_missing_one() -> void:
	var map: OverworldSim = _map({0x00: "11".repeat(0x10), 0x20: "2233"})
	assert_eq([map.rb(0x00, 0x0003), map.rb(0x20, 0x4000), map.rw(0x20, 0x4000)], [0x11, 0x22, 0x3322])
	assert_eq([map.rb(0x21, 0x4000), Array(map.unported)], [0, ["ROM bank 21 not extracted (4000)"]])


func test_decompress_repeats_a_byte_or_copies_literals_until_a_zero() -> void:
	# $03 $aa: three $aa; $82 $01 $02: two literals; $80 then 256 literals ($00 to $ff); $00: the end.
	var stream: String = "03aa820102" + "80" + "".join(PackedStringArray(range(256).map(func(i: int) -> String:
		return "%02x" % i))) + "00"
	var map: OverworldSim = _map({0x22: stream})
	var output: PackedByteArray = map.decompress(0x22, 0x4000)
	assert_eq([output.size(), output.slice(0, 5), output[5], output[260]],
			[3 + 2 + 256, PackedByteArray([0xAA, 0xAA, 0xAA, 1, 2]), 0, 0xFF])


func test_the_map_sides_fades_run_at_the_normal_speed() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	sim.wSubState = 0x08  # FadeBGToWhite_Normal
	var loops: int = 0
	while sim.wSubState == 0x08 and loops < 50:
		map.update()
		loops += 1
	assert_eq([loops, sim.wSubState], [18, 0x09])


func test_after_a_level_the_map_hands_over_to_the_save_screen() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	sim.wSubState = 0x09
	map.wTransitionParam = 0x0C  # a treasure
	map.w2(OverworldSim.W_MAP_SIDE_LEVEL_ID, 3)
	map.func_803e6()
	assert_eq([sim.wState, sim.wSubState, sim.wPendingSubState], [LevelSim.ST_PAUSE_MENU, PauseMenuSim.SST_PAUSE_18, 0x09])
	var exit: OverworldSim = _map()
	exit.sim.wState = LevelSim.ST_OVERWORLD
	exit.wTransitionParam = 0x0C
	exit.w2(OverworldSim.W_MAP_SIDE_LEVEL_ID, OverworldSim.OW_EXITS)
	exit.func_803e6()
	assert_eq(exit.sim.wState, LevelSim.ST_OVERWORLD, "not at a map exit")


func test_the_level_routes_the_map_or_notes_it_missing() -> void:
	var sim := LevelSim.new()
	sim.wState = LevelSim.ST_OVERWORLD
	sim.wSubState = 0x03  # Func_804ec: not ported
	sim.update_level()
	assert_eq(Array(sim.unported), ["the map (overworld.json not loaded)"])
	sim.load_overworld_data({"banks": {}})
	sim.update_level()
	assert_eq(Array(sim.unported), ["OverworldStateTable sub-state 3 (not ported)"])


## Bank `bank` (from $4000) of `size` zero bytes with `patches` ({address: hex}) written in.
func _bank(size: int, patches: Dictionary) -> String:
	var bytes := PackedByteArray()
	bytes.resize(size)
	for address: int in patches:
		var data: PackedByteArray = String(patches[address]).hex_decode()
		for offset: int in data.size():
			bytes[address - 0x4000 + offset] = data[offset]
	return bytes.hex_encode()


func _top_bar_map() -> OverworldSim:
	# The buttons' x and state (all states 0: no animation), and an OAM table of no entries.
	var oam: int = OverworldSim.OAM_A9FE2
	return _map({0x20: _bank(0x2600, {OverworldSim.TOP_BAR_BUTTON_DATA: "100020003000400050006000"}),
			0x2A: _bank(0x2100, {oam: "%02x%02x" % [(oam + 2) & 0xFF, (oam + 2) >> 8], oam + 2: "80"})})


func test_the_top_bars_d_pad_skips_buttons_not_selectable() -> void:
	var map: OverworldSim = _top_bar_map()
	map.w2(OverworldSim.W_TOP_BAR_SELECTABLE_BUTTONS, OverworldSim.TOPBAR_CUTSCENE | OverworldSim.TOPBAR_COLLECTION
			| OverworldSim.TOPBAR_PREV_MAP)
	map.w2(OverworldSim.W_TOP_BAR_SELECTION, OverworldSim.TOPBAR_COLLECTION)
	var seen: Array = []
	for pad: int in [OverworldSim.PAD_RIGHT, OverworldSim.PAD_RIGHT, OverworldSim.PAD_LEFT, OverworldSim.PAD_LEFT,
			OverworldSim.PAD_LEFT]:
		map.sim.wJoypadPressed = pad
		var taken: bool = map.handle_top_bar_dpad()
		seen.append([map.r2(OverworldSim.W_TOP_BAR_SELECTION), taken])
	assert_eq(seen, [[0x02, true], [0x02, true], [0x04, true], [0x10, true], [0x10, false]],
			"right past the last button is taken, left past the previous map is not")
	assert_eq([map.r2(OverworldSim.W_HDMA), map.r2(OverworldSim.W_HDMA + 1), map.r2(OverworldSim.W2D0B5 + 1)],
			[0xD4, 0xA0, 0x60], "the button rows' DMAs from wAttrmap's rows 21 and 19")


func test_the_top_bar_opens_two_lines_a_loop_and_closes_with_b() -> void:
	var map: OverworldSim = _top_bar_map()
	var sim: LevelSim = map.sim
	sim.wSCY = 0x04
	map.w2(OverworldSim.W_OW_BARS_STATE, OverworldSim.OWBARS_OPEN_TOP)
	var loops: int = 0
	while map.r2(OverworldSim.W_OW_BARS_STATE) == OverworldSim.OWBARS_OPEN_TOP and loops < 50:
		map.update_top_bar()
		loops += 1
	assert_eq([loops, sim.wSCY], [12, 0xEC])
	sim.wJoypadPressed = OverworldSim.PAD_B
	map.update_top_bar()
	sim.wJoypadPressed = 0
	while map.r2(OverworldSim.W_OW_BARS_STATE) == OverworldSim.OWBARS_CLOSE_TOP and loops < 100:
		map.update_top_bar()
		loops += 1
	assert_eq([loops, sim.wSCY, map.r2(OverworldSim.W_OW_BARS_STATE), map.r2(OverworldSim.W_PAL_CONFIG_1)],
			[24, 0x04, OverworldSim.OWBARS_NONE, OverworldSim.LOW_R_OBPI])


func test_the_collections_cursor_turns_the_page_at_its_sides_and_b_leaves() -> void:
	var map: OverworldSim = _map({0x26: _bank(0x2800, {OverworldSim.COLLECTION_CELL_Y_COORDS: "304860782038506880"})})
	var sim: LevelSim = map.sim
	sim.wSubState = 0x0F
	map.w2(OverworldSim.W_COLLECTION_CELL, 3)
	map.get_collection_cell_row_and_column(3, OverworldSim.W_COLLECTION_ROW)
	sim.wJoypadPressed = OverworldSim.PAD_RIGHT
	map.handle_treasure_collection_input()
	assert_eq([map.r2(OverworldSim.W_COLLECTION_CELL), map.r2(OverworldSim.W_COLLECTION_COL), sim.wSubState,
			map.rd(OverworldSim.scene_obj(1) + OverworldSim.SCENE_OBJ_X)], [4, 4, 0x0F, 0x80])
	map.handle_treasure_collection_input()
	assert_eq([map.r2(OverworldSim.W_COLLECTION_CELL), map.r2(OverworldSim.W_COLLECTION_COL),
			map.r2(OverworldSim.W_COLLECTION_PAGE), sim.wSubState], [0, 0, 1, OverworldSim.SST_OVERWORLD_COLLECTION])
	sim.wSubState = 0x0F
	sim.wJoypadPressed = OverworldSim.PAD_UP
	map.handle_treasure_collection_input()
	assert_eq(map.r2(OverworldSim.W_COLLECTION_ROW), 0, "not past the top row")
	sim.wJoypadPressed = OverworldSim.PAD_B
	map.handle_treasure_collection_input()
	assert_eq(sim.wSubState, 0x08)


func test_the_collection_boxes_the_treasures_not_got() -> void:
	# Cells 0 and 5 of page 0: treasure 1 got (its palette 3), treasure 6 not.
	var map: OverworldSim = _map({0x26: _bank(0x2C00, {OverworldSim.COLLECTION_CELL_LO_MAP_ADDRESSES: "a3a6a9acaf03",
			OverworldSim.TREASURE_OB_PALS: "0003"})})
	map.w2(OverworldSim.W_TREASURES_COLLECTED, 0x02)  # treasure 1
	map.apply_page_treasures_pals()
	var tilemap: int = OverworldSim.W_TILEMAP
	assert_eq([map.r2(tilemap + 0xA3 - 0x300), map.r2(tilemap + 0xC4 - 0x300), map.r2(tilemap + 0xA3)], [3, 3, 0],
			"got: its palette, its tiles kept")
	assert_eq([map.r2(tilemap + 0x103), map.r2(tilemap + 0x123), map.r2(tilemap + 0x104), map.r2(tilemap + 0x124),
			map.r2(tilemap + 0x103 - 0x300)], [0xFC, 0xFD, 0xFE, 0xFF, 0x04], "not got: the box in palette 4")
	assert_eq([map.r2(OverworldSim.W2DFFE), map.r2(OverworldSim.W2DFFF)], [20, 21])


func test_the_best_times_scroll_by_hand_then_by_themselves_after_256_idle_loops() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	sim.wSubState = 0x19
	sim.wSCY = 0x6F
	sim.wJoypadDown = OverworldSim.PAD_DOWN
	map.best_time_list()
	map.best_time_list()
	assert_eq(sim.wSCY, 0x70, "by hand, not past $70")
	sim.wJoypadDown = 0
	for loop: int in 255:
		map.best_time_list()
	assert_eq(map.r2(OverworldSim.W_COLLECTION_ROW), 0)
	map.best_time_list()
	assert_eq(map.r2(OverworldSim.W_COLLECTION_ROW), 1, "256 loops without the d-pad")
	var phases: Array = []
	var loops: int = 0
	while loops < 2000 and phases.size() < 5:
		map.best_time_list()
		loops += 1
		var phase: int = map.r2(OverworldSim.W_COLOUR_FADE_DIFF)
		if phases.is_empty() or phases[-1][0] != phase:
			phases.append([phase, loops, sim.wSCY])
	assert_eq(phases, [[1, 1, 0x70], [2, 181, 0x70], [3, 294, 0x00], [0, 474, 0x00], [1, 587, 0x70]],
			"at $70 a wait, up to 0, a wait, down to $70")
	sim.wJoypadPressed = OverworldSim.PAD_START
	map.best_time_list()
	assert_eq([map.r2(OverworldSim.W_COLLECTION_ROW), sim.wSubState], [0, 0x19], "a press stops it")
	map.best_time_list()
	assert_eq(sim.wSubState, 0x08, "and by hand Start leaves")


func test_the_temples_objective_text_puts_the_level_name_by_language() -> void:
	var map: OverworldSim = _map()
	for at: int in 0x400:  # each wTextBuffer byte its offset's high byte plus one, its row's
		map.w2(OverworldSim.W_TEXT_BUFFER + at, (at >> 4) & 0xFF)
	map.w2(OverworldSim.W_NEXT_TREASURE, OverworldSim.TREASURES_END)  # none: North's level 0, the Temple
	map.w0(OverworldSim.W_LANGUAGE, 1)
	map.load_next_objective_text()
	assert_eq([map.r2(OverworldSim.W_TEXT), map.r2(OverworldSim.W_TEXT_LINE_2), map.r2(OverworldSim.W_TEXT_LINE_3),
			map.r2(OverworldSim.W_TEXT_LINE_4), map.r2(OverworldSim.W_IS_NEXT_OBJECTIVE_THE_TEMPLE)], [0, 1, 2, 3, 1],
			"English: the header, the second line, then the name (wTextBuffer + $20); the Temple's flag")
	map.w0(OverworldSim.W_LANGUAGE, OverworldSim.LANGUAGE_JAPANESE)
	map.load_next_objective_text()
	assert_eq([map.r2(OverworldSim.W_TEXT_LINE_2), map.r2(OverworldSim.W_TEXT_LINE_3),
			map.r2(OverworldSim.W_TEXT_LINE_4)], [2, 1, OverworldSim.CHAR_NONE],
			"Japanese: the name, then the second line, an empty fourth")


func test_a_temple_rock_spawns_by_rdiv_large_in_states_9_to_b_small_in_9() -> void:
	var map: OverworldSim = _map()
	var rock: int = OverworldSim.W_TEMPLE_ROCKS  # wTempleRock1: scene object 12, x 32 or 48, may be large
	var obj: int = map.scene_obj(12)
	map.sim.div_replay = true
	map.w2(rock + OverworldSim.TEMPLE_ROCK_ACTION, 1)
	map.w2(rock + OverworldSim.TEMPLE_ROCK_SIZE, OverworldSim.TEMPLE_ROCK_SIZE_LARGE)
	map.sim.div_queue = [[0x564123, 0x0B]]  # bit 3: the right x; the low bits 3, taken as 2
	map.handle_temple_shake_and_rocks()
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_Y), map.rd(obj + OverworldSim.SCENE_OBJ_X),
			map.rd(obj + OverworldSim.SCENE_OBJ_STATE), map.r2(rock + OverworldSim.TEMPLE_ROCK_ACTION),
			map.r2(rock + OverworldSim.TEMPLE_ROCK_COUNTER), map.sim.div_queue], [0, 48, 0x0B, 2, 0, []],
			"at the top, state 9 plus 2 (not the size plus 2), falling next")
	map.w2(rock + OverworldSim.TEMPLE_ROCK_ACTION, 1)
	map.w2(rock + OverworldSim.TEMPLE_ROCK_SIZE, 1)
	map.sim.div_queue = [[0x564123, 0x03]]
	map.handle_temple_shake_and_rocks()
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_X), map.rd(obj + OverworldSim.SCENE_OBJ_STATE)], [32, 0x09],
			"small: the left x, state 9 whatever rDIV's low bits")


func test_the_temples_slow_shake_moves_a_pixel_every_two_loops_then_repeats() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W2D896, 3)  # .SlowScrollLeftWithSFX
	var scrolls: Array = []
	for loop: int in 16:
		map.handle_temple_screen_shake()
		if loop % 2 == 1:
			scrolls.append(map.sim.wSCX)
	assert_eq(scrolls, [0xFF, 0, 0xFF, 0, 0xFF, 0, 0xFF, 0])
	assert_eq([map.r2(OverworldSim.W2D896), map.r2(OverworldSim.W2D897)], [3, 0], "back 7 steps to the round's start")


func test_scene_wario_walking_to_a_place_is_set_on_it_from_an_odd_x() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W_SCENE_WARIO_X_COORD, 0x4F)
	map.sim.wGlobalCounter = 1  # an odd loop: two pixels, to $51
	assert_true(map._walk_scene_wario_to(0x50, true))
	assert_eq(map.r2(OverworldSim.W_SCENE_WARIO_X_COORD), 0x50, "the caller's ld [hl], a: x & $fe")
	map.w2(OverworldSim.W_SCENE_WARIO_X_COORD, 0x24)
	map.sim.wGlobalCounter = 0  # an even loop: a pixel, to $23
	assert_true(not map._walk_scene_wario_to(0x20, false))
	assert_eq(map.r2(OverworldSim.W_SCENE_WARIO_X_COORD), 0x23, "not there: x as moved")


func test_once_a_hidden_figure_was_fought_b_skips_the_reveal_to_the_fight() -> void:
	var map: OverworldSim = _map()
	map.sim.wState = LevelSim.ST_OVERWORLD
	map.sim.wSubState = 0x1D
	map.w2(OverworldSim.W2D013, 0x02)
	map.w0(OverworldSim.W_GAME_MODE_FLAGS, OverworldSim.MODE_FOUGHT_A_HIDDEN_FIGURE)
	map.sim.wJoypadPressed = OverworldSim.PAD_B
	map.hidden_figure_reveal_scene()
	assert_eq([map.sim.wState, map.sim.wSubState], [LevelSim.ST_OVERWORLD + 1, 0], "the level's state")
