extends TestCase
## The golf minigame (GolfSim) on invented data (no ROM bytes): animation stepping, the lobby's
## price and walk, the shot's gauge, gravity and the landing, the scroll, the V-Blank's clearing
## of the mode, and the golf building's menu, its price, its way out, and its best scores' drawing.

func _golf() -> GolfSim:
	var sim := LevelSim.new()
	var golf := GolfSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["72:73b3", "72:73c4", "72:73d7", "72:73d1", "72:73d4", "72:6f6f", "72:6f81",
			"72:6f8a", "72:6f84", "72:6f87", "72:6fb1", "72:6fb6"]:
		framesets[key] = [[1, 2], [2, 2]]
	for key: String in GolfSim.WARIO_FRAMESETS_RIGHT + GolfSim.WARIO_FRAMESETS_LEFT + GolfSim.MENU_WARIO_FRAMESETS \
			+ ["72:7598", "72:759b", "72:759e", "72:75a1", "72:75c3"]:
		framesets[key] = [[7, 3]]
	var terrain: String = "00".repeat(4) + "01".repeat(60) + "08"  # tee box, plain, the end
	# The building's course attributes and palettes: each byte its course's number plus one.
	var raw: Dictionary = {GolfSim.COURSE_SCROLLING_ATTRS: "ee".repeat(GolfSim.COURSE_ROWS_SIZE)}
	var palettes: Dictionary = {GolfSim.MENU_OBJ_PALS: "99".repeat(0x40), "72:618f": "88".repeat(0x40)}
	for course: int in 4:
		raw[GolfSim.COURSE_ATTRS[course]] = ("%02x" % (course + 1)).repeat(GolfSim.COURSE_ROWS_SIZE)
		palettes[GolfSim.COURSE_PALS[course]] = ("%02x" % (0x11 * (course + 1))).repeat(0x40)
	golf.load_data({"framesets": framesets, "holes": [{"data": terrain + "03" + "c003" + "0506"}],
			"stroke_numbers": {"bytes": "".join(PackedStringArray(range(320).map(func(i: int) -> String: return "%02x" % (i & 0xFF))))},
			"gfx": {"raw": raw, "palettes": palettes}})
	return golf


func test_an_animation_counts_down_then_steps_and_restarts_at_the_end() -> void:
	var golf: GolfSim = _golf()
	var obj: int = GolfSim.W_GOLF_OBJ_1
	var seen: Array = []
	for loop: int in 8:
		var restarted: bool = golf.update_animation(obj, "72:73b3")
		seen.append([golf.rb(obj + GolfSim.OBJ_CURRENT_FRAME), golf.rb(obj + GolfSim.OBJ_DURATION), restarted])
	assert_eq(seen, [[1, 2, false], [1, 1, false], [1, 0, false], [2, 2, false], [2, 1, false], [2, 0, false],
			[1, 2, true], [1, 1, false]])
	assert_eq(golf.rb(GolfSim.W_GOLF_ANIM_LAST_FRAME), 2, "the frame it ended on")


func test_the_price_comes_off_the_coins_in_bcd() -> void:
	assert_eq(GolfSim._bcd_sub_word(0x0087, 0x30), 0x0057)
	assert_eq(GolfSim._bcd_sub_word(0x0105, 0x10), 0x0095)
	assert_eq(GolfSim._bcd_sub_word(0x0057, 0x09), 0x0048)


func test_the_lobby_prices_by_treasures_and_finds_too_few_coins() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wSubState = 1
	golf.sim.wNumCoins = 0x0029
	golf.sim.wNumCollectedTreasures = 0x0025
	golf.update()
	assert_eq([golf.rb(GolfSim.W1D800), golf.rb(GolfSim.W_GOLF_PRICE), golf.rb(GolfSim.W_GOLF_OBJ_4),
			golf.rb(GolfSim.W_GOLF_NUM_COINS + 1), golf.sim.wSubState], [2, 0x30, 1, 0x29, 2])
	assert_eq([golf.rb(GolfSim.W_GOLF_WARIO), golf.rb(GolfSim.W_GOLF_WARIO_X_POS)], [GolfSim.GOLF_WARIO_WAITING, 0x38])
	assert_eq(golf.rb(GolfSim.W_GOLF_VBLANK_MODE), 0, "VBlank_1c9f7a clears the mode")


func test_down_at_the_pipe_pays_and_goes_down_to_the_hole() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wSubState = 3
	golf.sim.wNumCoins = 0x0087
	golf.wb(GolfSim.W_GOLF_PRICE, 0x30)
	golf.wb(GolfSim.W_GOLF_WARIO + GolfSim.OBJ_X_COORD, 0x78)
	golf.wb(GolfSim.W_GOLF_WARIO_X_POS, 0x78)
	golf.wb(GolfSim.W_GOLF_WARIO_Y_POS, 0x80)
	golf.sim.wJoypadPressed = WarioRam.PAD_DOWN
	golf.update()
	assert_eq([golf.sim.wNumCoins, golf.rb(GolfSim.W_GOLF_LOBBY_STATE)], [0x0057, GolfSim.GOLFLOBBYSTATE_ENTER_PIPE])
	golf.sim.wJoypadPressed = 0
	var loops: int = 0
	while golf.sim.wSubState == 3 and loops < 100:
		golf.update()
		loops += 1
	assert_eq([loops, golf.sim.wSubState, golf.rb(GolfSim.W_GOLF_NUM_COINS + 1)], [0x31, GolfSim.SST_GOLF_HOLE, 0x57])


func test_a_hole_starts_on_the_tee_with_its_data_and_the_rdiv_pick() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wSubState = 5
	golf.wb(GolfSim.W1D800, 2)
	golf.sim.div_replay = true
	golf.sim.div_queue = [[GolfSim.RDIV_PICK_GOLF_HOLE, 10]]
	golf.update()
	assert_eq(golf.sim.div_queue, [], "the hole's rDIV read made")
	assert_eq([golf.rb(GolfSim.W_GOLF_HOLE_TIER), golf.rb(GolfSim.W_GOLF_PAR), golf.rw(GolfSim.W_GOLF_HOLE_HOLE_X_POS),
			golf.rb(GolfSim.W_GOLF_MAX_STROKES)], [5, 3, 0x03C0, 3])
	assert_eq([golf.rw(GolfSim.W_GOLF_PARA_GOOM_Y_POS), golf.rw(GolfSim.W_GOLF_PARA_GOOM_X_POS),
			golf.rb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR), golf.sim.wSubState], [0x160, 0x80, 8, 6])
	assert_eq(golf.rb(GolfSim.W1DB90 + 33), 1, "the ones digit 0's tiles from the stroke digits")


func test_the_gauge_rises_by_one_then_two_and_falls_to_a_missed_start() -> void:
	var golf: GolfSim = _golf()
	golf.wb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR, 14)
	var cursors: Array = []
	for loop: int in 3:
		golf._hole_select_shot_power()
		cursors.append(golf.rb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR))
	assert_eq(cursors, [15, 16, 18])
	golf.wb(GolfSim.W_IS_POWER_GAUGE_FALLING, 1)
	golf.wb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR, 1)
	golf._hole_select_shot_power()
	assert_eq([golf.rb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR), golf.rb(GolfSim.W_GOLF_HOLE_STATE)],
			[0, GolfSim.GOLFHOLESTATE_START_SHOT])


func test_a_pressed_power_picks_its_level_and_velocities() -> void:
	var golf: GolfSim = _golf()
	golf.wb(GolfSim.W_SHOT_POWER_GAUGE_CURSOR, 68)
	golf.sim.wJoypadPressed = WarioRam.PAD_A
	golf._hole_select_shot_power()
	assert_eq([golf.rb(GolfSim.W_SELECTED_SHOT_POWER_GAUGE), golf.rb(GolfSim.W_SHOT_POWER_LEVEL),
			golf.rb(GolfSim.W_SHOT_Y_VEL), golf.rb(GolfSim.W_SHOT_X_VEL), golf.rb(GolfSim.W_GOLF_HOLE_STATE)],
			[70, 8, 22, 15, GolfSim.GOLFHOLESTATE_SELECT_SHOT_SPIN])


func test_gravity_brings_the_para_goom_down_and_plain_ground_bounces_it() -> void:
	var golf: GolfSim = _golf()
	golf.wb(GolfSim.W_PREDETERMINED_GOLF_HOLE, 1)
	golf.pick_and_load_golf_hole()
	golf.ww(GolfSim.W_GOLF_PARA_GOOM_X_POS, 0x200)
	golf.ww(GolfSim.W_GOLF_PARA_GOOM_Y_POS, 0x170)
	golf.ww(GolfSim.W_SHOT_Y_VEL, 2)
	golf.wb(GolfSim.W_SHOT_X_VEL, 4)
	golf.wb(GolfSim.W1DC01, GolfSim.GOLFHOLESTATE_BOUNCE)
	golf.wb(GolfSim.W_GOLF_HOLE_STATE, GolfSim.GOLFHOLESTATE_SHOT)
	var ys: Array = []
	for loop: int in 8:
		golf._hole_bounce()
		ys.append(golf.rw(GolfSim.W_GOLF_PARA_GOOM_Y_POS))
		if golf.rb(GolfSim.W_GOLF_HOLE_STATE) != GolfSim.GOLFHOLESTATE_SHOT:
			break
	assert_eq(ys, [0x16F, 0x16F, 0x170, 0x172, 0x175, 0x179, 0x17E, 0x180])
	assert_eq([golf.rb(GolfSim.W_GOLF_TERRAIN), golf.rb(GolfSim.W1DC47), golf.rb(GolfSim.W_GOLF_HOLE_STATE)],
			[GolfSim.GOLF_TERRAIN_PLAIN, 1, GolfSim.GOLFHOLESTATE_BOUNCE])


func test_the_scroll_follows_the_para_goom_and_splits_past_0x60() -> void:
	var golf: GolfSim = _golf()
	for case: Array in [[0x100, 0, GolfSim.GOLF_DISPLAY_BGMAP0], [0x200, 0x30, GolfSim.GOLF_DISPLAY_BGMAP0],
			[0x400, 0xB0, GolfSim.GOLF_DISPLAY_SPLIT], [0x600, 0x130, GolfSim.GOLF_DISPLAY_BGMAP1],
			[0x800, 0x160, GolfSim.GOLF_DISPLAY_BGMAP1]]:
		golf.ww(GolfSim.W_GOLF_PARA_GOOM_X_POS, case[0])
		golf.align_golf_x_scroll_with_para_goom()
		golf.update_golf_display_mode()
		assert_eq([golf.rw(GolfSim.W_GOLF_X_SCROLL), golf.sim.wSCX, golf.rb(GolfSim.W_GOLF_DISPLAY_MODE)],
				[case[1], case[1] & 0xFF, case[2]], "x %x" % case[0])
	golf.ww(GolfSim.W_GOLF_X_SCROLL, 0x70)
	golf.update_golf_display_mode()
	assert_eq(golf.rb(GolfSim.W_GOLF_WX), (167 - 0x70 + 89 + 7) & 0xFF)


func test_the_view_takes_each_golf_loop_and_shows_golf_from_the_lobby_on() -> void:
	var golf: GolfSim = _golf()
	var sim: LevelSim = golf.sim
	sim.golf = golf
	var view := LevelView.new()
	view._sim = sim
	sim.wState = LevelSim.ST_GOLF
	sim.wSubState = 1
	sim.golf.sim = sim
	golf.update()  # InitGolfLobby
	view.after_loop()
	assert_eq([view._golf_vram.screen, view._golf_loops, view._golf_shown()], ["lobby", 1, true])
	assert_eq(view._golf_vram.vram[0][GolfVram.map_address(GolfVram.BG_MAP_0, 6, 8) - GolfVram.VRAM_START], 0,
			"the coins are drawn by the lobby's V-Blank only from its second loop")
	view.after_loop()
	assert_eq(view._golf_loops, 1, "no golf loop since")
	sim.wSubState = 0
	assert_true(not view._golf_shown(), "the level's fade out")
	sim.golf = null
	golf.sim = null
	view.free()


func test_the_building_menu_sets_up_the_first_course_from_the_map() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wState = LevelSim.ST_GOLF_BUILDING
	golf.sim.wSubState = 1
	golf.sim.wNumCoins = 0x0066
	golf.wMusicalCoinFlags = 0xFFFFFF01
	golf.update_building()
	assert_eq([golf.rb(GolfSim.W1D800), golf.rb(GolfSim.W_GOLF_COURSE), golf.rb(GolfSim.W_HAS_ALL_MUSICAL_COIN_FLAGS),
			golf.rb(GolfSim.W_GOLF_NUM_COINS + 1), golf.sim.wSCX, golf.sim.wSubState], [1, 0, 1, 0x66, 0xCC, 2])
	assert_eq([golf.rb(GolfSim.W_GOLF_COURSE_TILE_MAP), golf.rb(GolfSim.W1DB00), golf.r0(GolfSim.W_TEMP_PALS_1),
			golf.r0(GolfSim.W_TEMP_PALS_2), golf.wTempBank], [1, 0x11, 0x11, 0x99, GolfSim.GOLF_GFX_2])
	assert_eq([golf.sim.wRoomAnimatedTilesEnabled, golf.sim.wAnimatedTilesGfx, golf.sim.wAnimatedTilesFrameDuration],
			[1, 0x0F, 8], "the menu's animated tiles")
	assert_eq([golf.wVirtualOAM[2], golf.wVirtualOAM[6], golf.wVirtualOAM[10]], [0xA0, 0xAC, 0xAC], "0, 6, 6 coins")
	golf.wMusicalCoinFlags = 0xFFFFFF00
	golf.sim.wSubState = 1
	golf.update_building()
	assert_eq(golf.rb(GolfSim.W_HAS_ALL_MUSICAL_COIN_FLAGS), 0, "the 25th coin missing")


func test_the_building_menu_wraps_past_the_third_course_without_every_musical_coin() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wSubState = 3
	golf.wb(GolfSim.W_GOLF_MENU_OPTION, GolfSim.GOLF_COURSE_3)
	golf.sim.wSCX = 0x4C
	golf.sim.wJoypadPressed = WarioRam.PAD_RIGHT
	golf.update_building()
	assert_eq([golf.rb(GolfSim.W_GOLF_MENU_OPTION), golf.rb(GolfSim.W1DC00), golf.rb(GolfSim.W_GOLF_MENU_TARGET_SCX),
			golf.rb(GolfSim.W_GOLD_BUILDING_COURSE_ATTR_MAP), golf.rb(GolfSim.W_GOLF_COURSE_TILE_MAP)], [0, 1, 0xCC, 0xEE, 1])
	assert_eq([golf.rb(GolfSim.W1DC13), golf.vblank_func, golf.rb(GolfSim.W_GOLF_VBLANK_MODE)],
			[0x0D, GolfSim.VBlankFunc.MENU_SCROLLING_ATTRS, 0], "the scrolling attributes' HDMA, which clears the mode")
	golf.sim.wJoypadPressed = 0
	var loops: int = 0
	while golf.rb(GolfSim.W1DC00) == 1 and loops < 100:
		golf.update_building()
		loops += 1
	assert_eq([loops, golf.sim.wSCX, golf.vblank_func], [33, 0xCC, GolfSim.VBlankFunc.MENU_PALS], "4 pixels a loop")
	golf.update_building()
	assert_eq([golf.rb(GolfSim.W1DC00), golf.vblank_func], [0, GolfSim.VBlankFunc.MENU_COURSE_ATTRS])
	golf.sim.wJoypadPressed = WarioRam.PAD_LEFT
	golf.update_building()
	assert_eq(golf.rb(GolfSim.W_GOLF_MENU_OPTION), GolfSim.GOLF_COURSE_3, "left from the first to the third")


func test_the_building_takes_its_price_counts_the_coins_down_and_starts_the_course() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wSubState = 3
	golf.sim.wNumCoins = 0x0049
	golf.sim.wJoypadPressed = WarioRam.PAD_A
	golf.update_building()
	assert_eq([golf.sim.wNumCoins, golf.rb(GolfSim.W1DC00)], [0x0049, 0], "too few coins")
	golf.sim.wNumCoins = 0x0066
	golf.wb(GolfSim.W_GOLF_NUM_COINS + 1, 0x66)
	golf.wb(GolfSim.W_GOLF_MENU_OPTION, 1)
	golf.update_building()
	assert_eq([golf.sim.wNumCoins, golf.rb(GolfSim.W1DC00)], [0x0016, 3])
	golf.sim.wJoypadPressed = 0
	var loops: int = 0
	while golf.sim.wSubState == 3 and loops < 100:
		golf.update_building()
		loops += 1
	assert_eq([loops, golf.rb(GolfSim.W_GOLF_NUM_COINS + 1), golf.rb(GolfSim.W_PREDETERMINED_GOLF_HOLE), golf.sim.wSubState],
			[0x33, 0x16, 0x06, GolfSim.SST_GOLF_HOLE])


func test_b_leaves_the_building_for_the_map() -> void:
	var golf: GolfSim = _golf()
	golf.sim.wState = LevelSim.ST_GOLF_BUILDING
	golf.sim.wSubState = 3
	golf.wb(GolfSim.W1D800, 1)
	golf.wb(GolfSim.W_GOLF_MENU_OPTION, 2)
	golf.sim.wJoypadPressed = WarioRam.PAD_B
	golf.update_building()
	assert_eq([golf.sim.wSubState, golf.rb(GolfSim.W1D800), golf.rb(GolfSim.W_GOLF_MENU_OPTION)], [8, 0, 0])
	golf.update_building()
	assert_eq([golf.sim.wState, golf.sim.wSubState, golf.wTransitionParam], [GolfSim.ST_OVERWORLD, 0, 0xF0])


func test_the_course_result_keeps_a_better_score() -> void:
	var golf: GolfSim = _golf()
	golf.wb(GolfSim.W_GOLF_COURSE, 2)
	golf.wb(GolfSim.W_GOLF_COURSE_SCORE, 15)
	golf.wGolfBestScores = 0xAAAAAAAA
	golf.wb(GolfSim.W_GOLF_COUNTER, 0x20)
	golf.sim.wJoypadPressed = WarioRam.PAD_A
	golf._hole_result()
	assert_eq([golf.wGolfBestScores, golf.sim.wSubState], [0xAAAA0FAA, 0])
	golf.wb(GolfSim.W_GOLF_COURSE_SCORE, 18)
	golf._hole_result()
	assert_eq(golf.r0(GolfSim.W_GOLF_BEST_SCORES + 2), 15, "not a worse one")


func test_the_menu_draws_each_best_score_as_a_sign_and_two_digits() -> void:
	var golf: GolfSim = _golf()
	golf.wGolfBestScores = 0x0F141E78  # 5 under, par, 10 over, none (120 and up)
	var vram := GolfVram.new()
	vram.load_menu(golf)
	var rows: Array = []
	for course: int in 4:
		var row: Array = []
		for column: int in 3:
			for y: int in [13, 14]:
				row.append(vram.read_byte(0, GolfVram.map_address(GolfVram.BG_MAP_0, 2 + course * 8 + column, y)))
		rows.append(row)
	assert_eq(rows, [[0xD4, 0xD5, 0xA0, 0xA1, 0xAA, 0xAB], [0xBE, 0xBF, 0xA0, 0xA1, 0xA0, 0xA1],
			[0xD2, 0xD3, 0xA2, 0xA3, 0xA0, 0xA1], [0, 0, 0xB4, 0xB5, 0xB4, 0xB5]])


func test_the_view_shows_the_map_fading_into_the_building_and_the_menu_fading_out() -> void:
	var golf: GolfSim = _golf()
	var sim: LevelSim = golf.sim
	sim.golf = golf
	var view := LevelView.new()
	view._sim = sim
	sim.wState = LevelSim.ST_OVERWORLD
	view.after_loop()
	sim.wState = LevelSim.ST_GOLF_BUILDING
	sim.wSubState = 0
	view.after_loop()
	assert_true(view._into_golf_building and not view._golf_shown(), "the map's fade into it")
	sim.wSubState = 1
	golf.update_building()
	view.after_loop()
	assert_eq([view._golf_vram.screen, view._into_golf_building, view._golf_shown()], ["menu", false, true])
	sim.wSubState = 0  # a course's end, back to the menu
	view.after_loop()
	assert_true(view._golf_shown(), "the course fading out, not the map")
	sim.wState = LevelSim.ST_OVERWORLD
	view.after_loop()
	assert_true(view._golf_shown(), "the map's fade out of the building")
	sim.wSubState = 1
	view.after_loop()
	assert_true(not view._golf_shown())
	sim.golf = null
	golf.sim = null
	view.free()
