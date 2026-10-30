extends TestCase
## The level's clear screen (ClearSim) on invented data (no ROM bytes): menu objects' animation, the
## treasure and the counts, the musical coins' count and flag, the pencil's place, and the way out.

func _clear() -> ClearSim:
	var sim := LevelSim.new()
	var clear := ClearSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["35:4d18", "35:4d1b", "35:4d58", "35:4d5f", "35:5045", "35:504a", "35:504f", "35:5054",
			"35:5059", "35:505c", "35:505f", "35:5062", "35:5065", "35:5068", "35:506b", "35:65f0", "7c:5cd4"]:
		framesets[key] = [[3, 1], [4, 1]]
	var oam: Dictionary = {}
	for key: String in [ClearSim.OAM_CLEAR, ClearSim.OAM_CLEAR_WARIO, ClearSim.OAM_PENCIL, ClearSim.OAM_PAUSE_MENU]:
		oam[key] = [[[-8, -4, 2, 0]], [[0, 0, 4, 1]], [[0, 0, 6, 0]], [[0, 0, 8, 0]], [[0, 0, 10, 0]]]
	var treasures: String = "".join(PackedStringArray(range(100).map(func(i: int) -> String: return "%02x" % (i + 10))))
	clear.load_data({"framesets": framesets, "oam_tables": oam, "tables": {
		"level_treasure_ids": {"bytes": treasures},
		"pencil_x_offsets": {"bytes": "01ff".repeat(26)}, "pencil_y_offsets": {"bytes": "ff01".repeat(26)},
		"musical_coin_level_bg_pals": {"bytes": "".join(PackedStringArray(range(25).map(func(i: int) -> String: return "%02x" % i)))},
	}})
	return clear


func test_an_object_steps_its_frameset_and_restarts_keeping_its_frame() -> void:
	var clear: ClearSim = _clear()
	clear.set_up_obj(ClearSim.W_MENU_OBJ_2, 0x28, 0x30, 0x5059)
	var seen: Array = []
	for loop: int in 6:
		clear.update_obj_anim(ClearSim.W_MENU_OBJ_2, ClearSim.CLEAR_BANK)
		seen.append([clear.r3(ClearSim.W_MENU_OBJ_2 + ClearSim.OBJ_FRAME), clear.r3(ClearSim.W_OBJ_ANIM_WAS_RESET)])
	assert_eq(seen, [[3, 0], [3, 0], [4, 0], [4, 0], [4, 1], [3, 0]])


func test_the_treasure_is_collected_and_the_boxes_and_treasures_counted() -> void:
	var clear: ClearSim = _clear()
	var sim: LevelSim = clear.sim
	sim.wSubState = 1
	sim.wLevel = 0x10  # the third level: its treasures are the table's 8th to 11th
	sim.wLevelEndScreen = 2  # red
	clear.wx(2, ClearSim.W_TREASURES_COLLECTED, 0b0000_1110)  # music boxes 1-3
	clear.update()
	assert_eq(clear.wTransitionParam, 19, "LevelTreasureIDs_WithoutTemple[2 * 4 + 1]")
	assert_true(clear.is_treasure_collected(19))
	assert_eq([clear.wNumMusicBoxes, sim.wNumCollectedTreasures, sim.wResetDisabled, sim.wSCY, sim.wSubState],
			[3, 0x04, 1, 4, 2])
	assert_eq([clear.r3(ClearSim.W_MENU_OBJ_1 + ClearSim.OBJ_X), clear.r3(ClearSim.W_MENU_OBJ_5 + ClearSim.OBJ_Y),
			clear.r3(ClearSim.W_MENU_OBJ_4 + ClearSim.OBJ_Y)], [0x40, 0x8C, 0], "the red treasure; boxes 5-7 only")
	assert_eq(clear.wVirtualOAMByteSize, 4 * 6, "Clear Wario, the treasure, object 2, three boxes")


func test_a_power_up_treasure_sets_its_power_up_for_action_help() -> void:
	var clear: ClearSim = _clear()
	clear.sim.wLevel = 0
	clear.sim.wLevelEndScreen = 1
	clear.tables["level_treasure_ids"][0] = 0x0C  # lead overalls
	clear.set_treasure_transition_param()
	assert_eq(clear.sim.wPowerUpLevel, 0x81)


func test_the_coins_count_up_after_a_second_and_the_eighth_marks_the_level() -> void:
	var clear: ClearSim = _clear()
	var sim: LevelSim = clear.sim
	sim.wSubState = 9
	sim.wLevel = 0x48  # level 9
	sim.wNumMusicalCoins = 8
	clear.update()
	assert_eq([clear.wAllMusicalCoinsLevel, clear.r0(ClearSim.W_MUSICAL_COIN_FLAGS + 1), clear.r0(ClearSim.W_TIMER)],
			[9, 0b10, 60])
	sim.wSubState = 11  # past the fade in
	var counts: Array = []
	for loop: int in 70:
		sim.wGlobalCounter = loop
		clear.update()
		counts.append(clear.wMusicalCoinVisualCounter)
	assert_eq([counts[59], counts[60], counts[63], counts[64]], [0, 1, 1, 2], "after 60 loops, one every 4")
	assert_eq(clear.r0(ClearSim.W_CEE4), 0, "V-Blank wrote the queued tiles and cleared bit 7")
	assert_eq(clear.r0(ClearSim.W_BG_MAP_TILE_VRAM0_QUEUE + 2), 0xA6, "the third coin's tile")
	var again: ClearSim = _clear()
	again.sim.wLevel = 0x48
	again.w0(ClearSim.W_MUSICAL_COIN_FLAGS + 1, 0b10)
	again.set_musical_coin_flag()
	assert_eq(again.wAllMusicalCoinsLevel, 0xFF, "already marked: nothing for the pencil")


func test_the_pencil_goes_down_to_the_levels_row_then_left_to_its_column() -> void:
	var clear: ClearSim = _clear()
	for case: Array in [[0, [0, 0]], [4, [0, 4]], [5, [1, 0]], [13, [2, 3]], [24, [4, 4]]]:
		clear.wAllMusicalCoinsLevel = case[0]
		assert_eq(clear._chart_place(), case[1], "level %d" % case[0])
	clear.wAllMusicalCoinsLevel = 13
	clear.set_up_obj(ClearSim.W_MENU_OBJ_1, 0x56, 0x5A, 0x65F0)
	clear.sim.wSubState = 12
	for loop: int in 5:
		clear.update()
	assert_eq([clear.r3(ClearSim.W_MENU_OBJ_1 + ClearSim.OBJ_Y), clear.r3(ClearSim.W_MENU_OBJ_1 + ClearSim.OBJ_X),
			clear.sim.wSubState], [0x58, 0x58, 13], "two loops down, two left, one to see it there")


func test_the_way_out_goes_to_the_map_or_to_action_help() -> void:
	var clear: ClearSim = _clear()
	var sim: LevelSim = clear.sim
	sim.wSubState = ClearSim.SST_CLEAR_EXIT
	clear.w0(ClearSim.W_TIMER, 1)
	clear.w0(ClearSim.W_TIMER + 1, 2)
	clear.update()
	assert_eq([sim.wSubState, clear.r0(ClearSim.W_TIMER + 1)], [ClearSim.SST_CLEAR_EXIT, 1], "the low byte wrapped")
	sim.wJoypadPressed = WarioRam.PAD_A
	sim.wAnimatedTilesFrameDuration = 8
	clear.update()
	assert_eq([sim.wState, sim.wSubState, sim.wDayNight & 0x80, sim.wAnimatedTilesFrameDuration], [1, 0, 0x80, 0])
	var helped: ClearSim = _clear()
	helped.sim.wSubState = ClearSim.SST_CLEAR_EXIT
	helped.sim.wPowerUpLevel = 0x81
	helped.sim.wJoypadPressed = WarioRam.PAD_A
	helped.update()
	assert_eq([helped.sim.wState, helped.sim.wSubState], [ClearSim.ST_ACTION_HELP, 0])


func test_the_view_takes_each_clear_loop_and_shows_the_clear_screen_from_its_start() -> void:
	var clear: ClearSim = _clear()
	var sim: LevelSim = clear.sim
	sim.clear = clear
	var view := LevelView.new()
	view._sim = sim
	sim.wState = LevelSim.ST_CLEAR
	sim.wSubState = 1
	sim.wLevelEndScreen = 5
	sim.wNumCoins = 0x0123
	clear.update()  # InitClearScreen
	clear.sim = sim
	view.after_loop()
	assert_eq([view._clear_vram.screen, view._clear_loops, view._clear_shown()], ["treasure", 1, true])
	assert_eq(view._clear_vram.read_byte(0, ScreenVram.map_address(ScreenVram.BG_MAP_0, 6, 16)), 0xA2,
			"the coins' hundreds digit")
	sim.wSubState = 0
	assert_true(not view._clear_shown(), "the level's fade out")
	sim.clear = null
	clear.sim = null
	view.free()
