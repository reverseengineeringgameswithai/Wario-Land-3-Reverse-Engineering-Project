extends TestCase
## The title (TitleSim, WL3-055, WL3-056) on invented data (no ROM bytes): InitIntroSequence with and
## without a save, the intro, the way to the start menu, the menu's input (Continue, scrolling to Clear
## Data, its Yes and No, New Game), Continue into the map or a level save's level, Action Help's timer,
## LevelSim's routing, the drawing (TitleVram), and a power-on start (LevelRunner.power_on).

const PALS_SAVED: String = "01:5002"


func _title(sim: LevelSim = LevelSim.new()) -> TitleSim:
	var title := TitleSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["01:6ce6", "01:6ce9", "01:6cec", "01:6cef", "01:6d18", "01:6d1b", "01:6d1e", "01:712c",
			"01:713d", "01:7144", "01:7165", "01:7172", "01:717b", "01:7184", "01:718d", "01:7198", "01:71a1",
			"01:71a4", "01:71a7", "01:76b5"]:
		framesets[key] = [[0, 4], [1, 4]]
	framesets["01:6cf2"] = [[4, 1]]  # Clear Data's No: a short animation
	var frames: Array = []  # one entry a frame
	for index: int in 16:
		frames.append([[-8, -4, 2, 0]])
	title.load_data({"framesets": framesets, "oam_tables": {"01:6b5f": frames, "01:6d21": frames, "01:75c3": frames},
		"gfx": {"palettes": {"01:4f82": "01".repeat(0x40), "01:4fc2": "02".repeat(0x40), PALS_SAVED: "11".repeat(0x40),
			"01:5042": "12".repeat(0x40), "7c:7610": "31".repeat(0x40), "01:71b0": "51".repeat(0x40)},
			"compressed": {"01:5082": "21".repeat(0x1800), "01:635c": "22".repeat(0x1800), "01:697a": "23".repeat(0x400),
				"01:6ae7": "04".repeat(0x400), "7c:5d5d": "41".repeat(0x800), "7c:7650": "42".repeat(0x400),
				"7c:767f": "05".repeat(0x400), "01:73e6": "61".repeat(0x400), "01:74e8": "02".repeat(0x400),
				"01:71f0": "62".repeat(0x400), "01:7316": "03".repeat(0x400)},
			"raw": {"01:6b47": "7c".repeat(12) + "10".repeat(12), "2c:4f80": "71".repeat(0x800)}}})
	return title


func _to_start_menu(title: TitleSim) -> void:
	var sim: LevelSim = title.sim
	var loops: int = 0
	while sim.wSubState != TitleSim.SST_START_MENU and loops < 200:
		title.update()
		sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
		loops += 1


func test_with_a_save_the_title_fades_loads_and_goes_straight_to_the_start_menu() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w0(TitleSim.WCEEF, 0x03)
	var by_substate: Dictionary = {}
	var loops: int = 0
	while sim.wSubState != TitleSim.SST_START_MENU and loops < 200:
		by_substate[sim.wSubState] = int(by_substate.get(sim.wSubState, 0)) + 1
		if sim.wSubState == 1:
			title.update()
			assert_eq([sim.wSCY, sim.wSCX, sim.wGlobalCounter, title.r0(TitleSim.W_TEMP_PALS_1), title.r0(0xC040)],
					[4, 0, 0, 0x11, 0x12], "the scroll, the counter cleared, the save's palettes")
			assert_eq([title.r3(TitleSim.W_START_MENU_SELECTION), title.r3(TitleSim.W_PLANE_WARIO),
					title.r3(TitleSim.W_PLANE_WARIO + 1), title.r3(TitleSim.W_PLANE_WARIO + MenuScreenSim.OBJ_DURATION),
					title.r3(TitleSim.W_MENU_OBJ_1), title.r3(TitleSim.W_MENU_OBJ_2 + 1),
					title.r3(TitleSim.W_MENU_OBJ_3 + MenuScreenSim.OBJ_DURATION)],
					[TitleSim.STARTMENU_CONTINUE, 108, 128, 0, 0x82, 0x44, 4], "the plane at rest, not animated")
			assert_eq([title.screen_loads, title.vblank_func], [[["title", true]], TitleSim.VBLANK_TITLE])
		else:
			title.update()
		sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
		loops += 1
	assert_eq(by_substate, {0: 33, 1: 1, 2: 33, 3: 1}, "the fades, the init, then StartTitleScreen")
	assert_eq([title.r0(TitleSim.W_TIMER), title.r0(TitleSim.W_TIMER + 1)], [0x44, 0x08], "Action Help's timer")


func test_without_a_save_the_intro_is_set_up() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	sim.wSubState = 1
	title.update()
	assert_eq([title.r3(TitleSim.W_START_MENU_SELECTION), title.r3(TitleSim.W_PLANE_WARIO + 1),
			title.r3(TitleSim.W_PLANE_WARIO + MenuScreenSim.OBJ_DURATION), title.r3(TitleSim.W_MENU_OBJ_4),
			title.r3(TitleSim.W_MENU_OBJ_5 + 1), title.wVirtualOAMByteSize, title.r0(TitleSim.W_TEMP_PALS_1)],
			[TitleSim.STARTMENU_NEW_GAME, 208, 4, 16, 32, 8, 0x01], "the intro's objects, two drawn")


func test_a_takes_continue_after_its_highlight_blinks_into_the_map() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w0(TitleSim.WCEEF, 0x03)
	_to_start_menu(title)
	sim.wJoypadPressed = WarioRam.PAD_START
	title.update()
	assert_eq(title.r3(TitleSim.W_START_MENU_SELECTION), TitleSim.STARTMENU_CONTINUE, "Start does nothing")
	sim.wJoypadPressed = WarioRam.PAD_A
	title.update()
	sim.wJoypadPressed = 0
	assert_eq(title.r3(TitleSim.W_START_MENU_SELECTION), TitleSim.STARTMENU_CONTINUE | TitleSim.STARTMENUF_ANIM2)
	var attributes: Array = []
	var loops: int = 0
	while sim.wState == LevelSim.ST_TITLE and loops < 100:
		sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
		title.update()
		if sim.wGlobalCounter & 1 == 0 and attributes.size() < 4:
			attributes.append(title.r3(TitleSim.W_MENU_OBJ_1 + MenuScreenSim.OBJ_ATTRIBUTES))
		loops += 1
	assert_eq(attributes, [3, 0, 1, 0], "the highlight's palettes")
	assert_eq([loops, sim.wState, sim.wSubState], [33, TitleSim.ST_OVERWORLD, 0],
			"16 steps every other loop, the 17th chooses, then the map")


func test_continue_with_a_level_save_resumes_the_level() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w0(TitleSim.WCEEF, 0x14)
	sim.wSubState = TitleSim.SST_START_MENU
	title.w3(TitleSim.W_START_MENU_SELECTION, TitleSim.STARTMENU_CONTINUE | TitleSim.STARTMENUF_SELECT)
	title.update()
	assert_eq([sim.wState, sim.wSubState], [TitleSim.ST_LEVEL, 0])


func test_down_scrolls_to_clear_data_and_its_no_scrolls_back_with_the_box_redrawn() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w0(TitleSim.WCEEF, 0x03)
	_to_start_menu(title)
	sim.wJoypadPressed = WarioRam.PAD_DOWN
	title.update()
	sim.wJoypadPressed = 0
	var loops: int = 0
	while title.r3(TitleSim.W_START_MENU_SELECTION) != TitleSim.STARTMENU_CLEAR_DATA and loops < 50:
		title.update()
		loops += 1
	assert_eq([loops, title.r3(TitleSim.W_MENU_OBJ_1), title.r3(TitleSim.W_MENU_OBJ_2)], [14, 116, 118],
			"a line a loop from 130 to 116")
	assert_eq([title.r0(TitleSim.W_TIMER), title.r0(TitleSim.W_TIMER + 1)], [0x44, 0x08], "the timer held")
	# A: Clear Data's question, No highlighted; left: Yes; right: No; A: No's animation, then Continue.
	title.w3(TitleSim.W_START_MENU_SELECTION, TitleSim.STARTMENU_CLEAR_DATA | TitleSim.STARTMENUF_SELECT)
	title.update()
	assert_eq([title.r3(TitleSim.W_START_MENU_SELECTION), title.r0(TitleSim.W_CEE4), title.r3(TitleSim.W_MENU_OBJ_2),
			title.r3(TitleSim.W_MENU_OBJ_1)], [TitleSim.STARTMENU_CLEAR_DATA_NO, 0x01, 144, 120],
			"$81, its bit 7 cleared by VBlank_Title once it redrew the box")
	sim.wJoypadPressed = WarioRam.PAD_LEFT
	title.update()
	assert_eq(title.r3(TitleSim.W_START_MENU_SELECTION), TitleSim.STARTMENU_CLEAR_DATA_YES)
	sim.wJoypadPressed = WarioRam.PAD_RIGHT
	title.update()
	assert_eq(title.r3(TitleSim.W_START_MENU_SELECTION), TitleSim.STARTMENU_CLEAR_DATA_NO)
	sim.wJoypadPressed = WarioRam.PAD_A
	title.update()
	sim.wJoypadPressed = 0
	assert_eq(title.r3(TitleSim.W_START_MENU_SELECTION), 0x23, "No's animation")
	loops = 0
	while title.r3(TitleSim.W_START_MENU_SELECTION) != TitleSim.STARTMENU_CONTINUE and loops < 20:
		title.update()
		loops += 1
	assert_eq([title.r3(TitleSim.W_MENU_OBJ_1), title.r3(TitleSim.W_MENU_OBJ_2), sim.wState], [130, 134, LevelSim.ST_TITLE])
	assert_eq([title.vblank_writes, title.r0(TitleSim.W_CEE4)], [[["box"]], 0], "VBlank_Title redraws the box")


func test_clear_datas_yes_jumps_to_clear_save_data() -> void:
	var title: TitleSim = _title()
	title.w0(TitleSim.WCEEF, 0x03)
	_to_start_menu(title)
	title.w3(TitleSim.W_START_MENU_SELECTION, TitleSim.STARTMENU_CLEAR_DATA_YES | TitleSim.STARTMENUF_SELECT)
	title.update()
	assert_eq([Array(title.unported), title.sim._init_request], [[], LevelSim.INIT_CLEAR_SAVE_DATA],
			"Init follows the loop (LevelSim.init_game)")


func test_left_alone_the_start_menu_opens_action_helps_demos() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w0(TitleSim.WCEEF, 0x03)
	title.w0(TitleSim.W_POWER_UP_LEVEL, 0x05)
	_to_start_menu(title)
	var loops: int = 0
	while sim.wState == LevelSim.ST_TITLE and loops < 3000:
		title.update()
		loops += 1
	assert_eq([loops, sim.wState, sim.wSubState, title.r0(TitleSim.W_POWER_UP_LEVEL), title.r0(TitleSim.W_TIMER)],
			[TitleSim.ACTION_HELP_TIMER, TitleSim.ST_ACTION_HELP, 0, 0x45, 0])


func test_level_sim_runs_the_title_in_its_state_only_with_the_title_loaded() -> void:
	var sim := LevelSim.new()
	var title: TitleSim = _title(null)
	sim.title = title
	title.w0(TitleSim.WCEEF, 0x03)
	sim.wSubState = 1
	sim.update_level()
	assert_eq([sim.wSubState, title.loops, sim.wSCY], [2, 1, 4])
	var level := LevelSim.new()
	level.wSubState = 1  # with no title, wState 0 is the level's (its checks start it there): InitLevel
	level.update_level()
	assert_true(level.unported.size() == 1 and "InitLevel" in level.unported[0])


func test_the_title_is_drawn_from_its_graphics_with_the_menu_behind_the_scenery() -> void:
	var title: TitleSim = _title()
	var vram := TitleVram.new(title.document)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800),
			vram.read_byte(0, 0x9C00)], [0, 0x7F, 0, 0xFF], "Init's VRAM")
	title.w0(TitleSim.WCEEF, 0x03)
	title.sim.wSubState = 1
	title.update()
	vram.update(title)
	var row_12: int = ScreenVram.map_address(ScreenVram.BG_MAP_0, 4, 12)
	var row_14: int = ScreenVram.map_address(ScreenVram.BG_MAP_0, 4, 14)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(1, 0x8000), vram.read_byte(1, row_12),
			vram.read_byte(1, row_12 + 11), vram.read_byte(1, ScreenVram.map_address(ScreenVram.BG_MAP_0, 4, 14)),
			vram.read_byte(1, ScreenVram.map_address(ScreenVram.BG_MAP_0, 4, 17))], [0x21, 0x22, 0x84, 0x04, 0x04, 0x84],
			"the tiles, and rows 12, 13, 16 and 17 behind the scenery from column 4 for 11")
	assert_eq([vram.read_byte(0, row_14), vram.read_byte(0, row_14 + 32), vram.read_byte(0, row_14 + 12),
			vram.bg_palettes[0], vram.obj_palettes[0]], [0x7C, 0x10, 0x23, 0x11, 0x12], "the box, and the palettes")


func test_power_on_loads_the_save_and_starts_the_title() -> void:
	var objects: Dictionary = {"title": _title().document, "overworld": {}}
	var save := PackedByteArray()
	save.resize(4 * SaveLoad.SRAM_SIZE)
	var sim: LevelSim = LevelRunner.power_on(null, save, objects, Callable())
	assert_true(sim != null and sim.title != null and sim.overworld != null)
	assert_eq([sim.wState, sim.wSubState, sim.wceef, sim.title.r0(0xCA42)], [LevelSim.ST_TITLE, 0, 0, 0xAA],
			"no save: the golf best scores' defaults")
	for tick: int in 67:
		LevelRunner.frame(sim, 0)
	assert_eq([sim.wSubState, sim.title.loops, sim.wGlobalCounter], [3, 67, 34], "the counter cleared at the init")
	assert_eq(LevelRunner.power_on(null, save, {"title": {}}, Callable()), null, "the map is needed")


func test_without_a_save_the_intro_flies_the_plane_and_ends_on_the_start_menu() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	var by_substate: Dictionary = {}
	var loops: int = 0
	var plane_x: Array = []
	while sim.wSubState != TitleSim.SST_START_MENU and loops < 3000:
		by_substate[sim.wSubState] = int(by_substate.get(sim.wSubState, 0)) + 1
		title.update()
		sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
		if sim.wSubState == 3 and title.r3(TitleSim.W_PLANE_WARIO_VAR) == 2 and plane_x.is_empty():
			plane_x.append(title.r3(TitleSim.W_PLANE_WARIO + MenuScreenSim.OBJ_X))
		loops += 1
	assert_eq(plane_x, [48], "phase 1 flies the plane in to x 48")
	assert_true(by_substate.has(3) and by_substate.has(4) and by_substate.has(5) and by_substate.has(6), "every phase")
	assert_true(by_substate[6] >= 120 + 129 and by_substate[6] <= 120 + 132,
			"EndIntroSequence: 120 loops, then the fade's 33 steps every 4 loops")
	assert_eq([title.r3(TitleSim.W_START_MENU_SELECTION), title.r0(TitleSim.W_TIMER), title.r0(TitleSim.W_TIMER + 1),
			title.r0(TitleSim.W_TEMP_PALS_1)], [TitleSim.STARTMENU_NEW_GAME, 0x44, 0x08, 0x11], "New Game, the timer, the title's palettes")
	assert_eq([sim.wPalFadeCounter, sim.wFadeSpeed], [0, 0])


func test_the_intro_s_layers_scroll_and_are_drawn_from_their_lines() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	sim.wSubState = 3
	sim.wGlobalCounter = 4
	title.update()
	assert_eq([title.wIntroBGXOffsetFar, title.wIntroBGXOffsetCentre, title.wIntroBGXOffsetNear], [0xFF, 0xFF, 0xFE],
			"far every 4 loops, centre 1, near 2")
	assert_eq(title.scx_lines(0), [[0x5C, 0xFF], [0x64, 0xFF], [0x74, 0xFE], [0x84, 0]], "a line after the lines it waits for")
	title.w0(TitleSim.WCEEF, 1)
	sim.wSubState = 3
	title.update()
	assert_eq(title.scx_lines(0), [], "with a save there is no intro")


func test_the_logo_parts_drift_until_x_176_then_only_before_phase_2_flies() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	title.w3(TitleSim.W_MENU_OBJ_4 + MenuScreenSim.OBJ_X, 176)
	title.w3(TitleSim.W_MENU_OBJ_5 + MenuScreenSim.OBJ_X, 10)
	sim.wSubState = 4
	sim.wGlobalCounter = 2  # even: wMenuObj5 waits
	title.w3(TitleSim.W_PLANE_WARIO_VAR, 1)
	title.func_4d45()
	assert_eq([title.r3(TitleSim.W_MENU_OBJ_4 + MenuScreenSim.OBJ_X), title.r3(TitleSim.W_MENU_OBJ_5 + MenuScreenSim.OBJ_X)],
			[176, 10])
	title.w3(TitleSim.W_PLANE_WARIO_VAR, 0)
	sim.wGlobalCounter = 3
	title.func_4d45()
	assert_eq([title.r3(TitleSim.W_MENU_OBJ_4 + MenuScreenSim.OBJ_X), title.r3(TitleSim.W_MENU_OBJ_5 + MenuScreenSim.OBJ_X)],
			[177, 11])


func test_the_fade_after_the_intro_steps_the_palettes_toward_the_title_s() -> void:
	var title: TitleSim = _title()
	var vram := TitleVram.new(title.document)
	vram.bg_palettes.fill(0)
	vram.obj_palettes.fill(0xFF)
	title.w0(TitleSim.W_TEMP_PALS_1, 0x23)  # red 3, green 1
	title.w0(TitleSim.W_TEMP_PALS_1 + 0x40, 0x00)
	title.screen_loads = [["fade_in_step"]]
	vram.update(title)
	assert_eq([vram.bg_palettes[0], vram.bg_palettes[1], vram.obj_palettes[0], vram.obj_palettes[1]], [0x21, 0x00, 0xDE, 0x7B],
			"each component a step: red and green up, the OBJ colour's down (bit 15 dropped)")


func test_new_game_goes_to_the_language_selection_and_a_state_with_no_port_is_named() -> void:
	var sim := LevelSim.new()
	var title: TitleSim = _title(null)
	sim.title = title
	sim.wSubState = TitleSim.SST_START_MENU
	title.w3(TitleSim.W_START_MENU_SELECTION, TitleSim.STARTMENU_NEW_GAME | TitleSim.STARTMENUF_SELECT)
	sim.update_level()
	assert_eq([sim.wState, sim.wSubState], [TitleSim.ST_LANGUAGE_SELECTION, 0])
	sim.update_level()
	assert_eq([Array(sim.unported), title.loops], [[], 2], "the title runs the language selection")
	sim.wState = 0x09  # ST_CREDITS
	sim.update_level()
	assert_eq(Array(sim.unported), ["wState $09"], "named, not run as the level")


func test_the_language_selection_sets_up_english_moves_and_starts_a_new_game() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	sim.wState = TitleSim.ST_LANGUAGE_SELECTION
	sim.wSubState = 1
	sim.wSCY = 4
	title.update()
	assert_eq([sim.wSubState, sim.wSCY, title.r0(TitleSim.W_LANGUAGE), title.r3(TitleSim.W_MENU_OBJ_1),
			title.r3(TitleSim.W_MENU_OBJ_1 + 1), title.r0(TitleSim.W_TEMP_PALS_1), title.r0(0xC040), title.wVirtualOAM[2]],
			[2, 0, TitleSim.ENGLISH, 70, 24, 0x31, 0x31, 2], "English, the cursor drawn on it, the font's palettes")
	sim.wSubState = 3
	sim.wJoypadPressed = WarioRam.PAD_UP
	title.update()
	assert_eq([title.r3(TitleSim.W_MENU_OBJ_1), title.loops], [70, 2], "up from English: nothing")
	sim.wJoypadPressed = WarioRam.PAD_DOWN
	title.update()
	assert_eq([title.r0(TitleSim.W_LANGUAGE), title.r3(TitleSim.W_MENU_OBJ_1), title.vblank_writes, title.r0(TitleSim.W_CEE4)],
			[0, 86, [["language", 0]], 0], "Japanese, its row highlighted at the V-Blank")
	sim.wJoypadPressed = WarioRam.PAD_A
	title.update()
	assert_eq([sim.wState, sim.wSubState, title.r0(TitleSim.W_TRANSITION_PARAM)],
			[TitleSim.ST_OVERWORLD, 0, TitleSim.TRANSITION_NEW_GAME], "the map, as a new game")


func test_the_language_selection_is_drawn_over_what_the_title_left() -> void:
	var title: TitleSim = _title()
	var vram := TitleVram.new(title.document, false)
	title.sim.wState = TitleSim.ST_LANGUAGE_SELECTION
	title.sim.wSubState = 1
	title.update()
	vram.update(title)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800), vram.written[1][0],
			vram.bg_palettes[0]], [0x41, 0x42, 0x05, 0, 0x31], "the font's tiles and the text; the plane's tiles untouched")
	title.screen_loads.clear()
	title.vblank_writes = [["language", TitleSim.ENGLISH]]
	vram.update(title)
	assert_eq([vram.read_byte(1, ScreenVram.map_address(ScreenVram.BG_MAP_0, 5, 7)),
			vram.read_byte(1, ScreenVram.map_address(ScreenVram.BG_MAP_0, 17, 9)),
			vram.read_byte(1, ScreenVram.map_address(ScreenVram.BG_MAP_0, 18, 9))], [0x06, 0x07, 0x05],
			"English's row in palette 6, Japanese's in 7, 13 entries from column 5")


func test_time_attacks_description_loads_waits_for_a_and_goes_to_the_map() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	var vram := TitleVram.new(title.document, false)
	title.w0(TitleSim.W_LANGUAGE, TitleSim.ENGLISH)
	title.w0(TitleSim.W_TIMER, 0x33)
	sim.wSCX = 9
	sim.wSubState = 0x09
	title.update()
	vram.update(title)
	assert_eq([sim.wSubState, title.vblank_func, title.r0(TitleSim.W_TEMP_PALS_1), title.r0(TitleSim.W_TIMER), sim.wSCX],
			[0x0A, TitleSim.VBLANK_TIME_ATTACK_DESCRIPTION, 0x51, 0, 0], "InitTimeAttackDescription")
	assert_eq([vram.read_byte(1, 0x8000), vram.read_byte(0, 0x9000), vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800),
			vram.bg_palettes[0]], [0x41, 0x71, 0x61, 0x02, 0x51], "the font, the prologue's tiles, the English text")
	title.update()
	assert_eq([sim.wState, sim.wSubState, title.scy_lines(0)], [LevelSim.ST_TITLE, 0x0A, []], "waiting; English: no rows moved")
	sim.wJoypadPressed = WarioRam.PAD_A
	title.update()
	assert_eq([sim.wState, sim.wSubState, title.screen_loads], [TitleSim.ST_OVERWORLD, 0, [["white"]]], "A: the map")


func test_the_japanese_description_loads_its_text_and_moves_its_rows_mid_frame() -> void:
	var title: TitleSim = _title()
	var sim: LevelSim = title.sim
	var vram := TitleVram.new(title.document, false)
	title.w0(TitleSim.W_LANGUAGE, 0)
	sim.wSubState = 0x09
	title.update()
	vram.update(title)
	assert_eq([vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800)], [0x62, 0x03], "the Japanese text")
	title.update()
	assert_eq(title.scy_lines(0), [[0x30, 7], [0x39, 14], [0x42, 21], [0x5B, 28], [0x64, 35], [0x6D, 42]],
			"7 lines further down after each of six lines")
