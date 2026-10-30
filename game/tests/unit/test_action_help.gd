extends TestCase
## Action Help (ActionHelpSim) on invented data (no ROM bytes): the power-up it shows, the d-pad's
## repeat, browsing the power-ups, closing it, a demo's end after a level's clear, the RAM it shares
## with the clear screen, and its drawing.

func _help(sim: LevelSim = LevelSim.new()) -> ActionHelpSim:
	var help := ActionHelpSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["79:6b6d", "79:6b70", "79:6b73", "79:6b76", "79:6b7c", "79:6b82", "79:6b8e"]:
		framesets[key] = [[3, 1], [4, 1]]
	var oam: Dictionary = {ActionHelpSim.OAM_ACTION_HELP: [[[0, 0, 2, 0]], [], [], [[0, 0, 4, 1]], [[0, 0, 6, 0]]]}
	help.load_data({"framesets": framesets, "oam_tables": oam,
		"tables": {"power_up_ob_pals": {"bytes": "05070606050405070604"},
			"jump_vel_table_normal": {"bytes": "fc".repeat(0x100)}},
		"gfx": {"palettes": {"79:4eef": "11".repeat(0x40), "79:4f2f": "22".repeat(0x40), "79:4f6f": "33".repeat(0x10),
			"79:4f7f": "44".repeat(0x40), "79:4fbf": "55".repeat(0x10)},
			"wario": {"04:4000": "66".repeat(0x800)}}})
	return help


func test_init_shows_warios_power_up_or_a_transformations_with_the_cursor_under_it() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.wSubState = 1
	sim.wPowerUpLevel = 0x83
	help.update()
	assert_eq([help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), help.sim.hDemoPowerUp, sim.wSubState, sim.wSCY],
			[3, 1, 2, 4])
	assert_eq([help.r3(ActionHelpSim.W_MENU_OBJ_1 + ActionHelpSim.OBJ_Y),
			help.r3(ActionHelpSim.W_MENU_OBJ_1 + ActionHelpSim.OBJ_X)], [144, 0x38], "swap 3, plus 8")
	assert_eq([help.r0(ActionHelpSim.W_TEMP_PALS_1), help.r0(ActionHelpSim.W_TEMP_PALS_2)], [0x11, 0x22])
	assert_eq([help.vblank_func, help.screen_loads], [ActionHelpSim.VBlankFunc.ACTION_HELP, [["action_help"]]])
	var owl: ActionHelpSim = _help()
	owl.sim.wSubState = 1
	owl.sim.wTransformation = ActionHelpSim.TRANSFORMATION_OWL_WARIO
	owl.sim.hDemoPowerUp = 12
	owl.update()
	assert_eq([owl.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), owl.sim.hDemoPowerUp, owl.r0(ActionHelpSim.W_TEMP_PALS_2)],
			[ActionHelpSim.POWER_UP_OWL, 0, 0x44], "the next demo wraps; the special power-ups' palettes")


func test_the_title_screens_demo_moves_the_power_up_on() -> void:
	var help: ActionHelpSim = _help()
	help.sim.wSubState = 1
	help.sim.wPowerUpLevel = ActionHelpSim.ACTION_HELP_TITLE_SCREEN | 9
	help.sim.hDemoPowerUp = 6
	help.update()
	assert_eq(help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), 2, "9 + 6 - 13")


func test_a_held_direction_repeats_after_16_loops_then_every_8() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	var pressed_at: Array = []
	for loop: int in 40:
		sim.wJoypadDown = WarioRam.PAD_RIGHT
		sim.wJoypadPressed = WarioRam.PAD_RIGHT if loop == 0 else 0
		help.process_dpad_repeat()
		if sim.wJoypadPressed != 0:
			pressed_at.append(loop)
	assert_eq(pressed_at, [0, 16, 24, 32])


func test_right_and_left_browse_the_main_power_ups_and_colour_the_cursors_entry() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.wPowerUpLevel = 4
	help.set_up_obj(ActionHelpSim.W_MENU_OBJ_1, 144, 0x38, 0x6B8E)
	help.w3(ActionHelpSim.W_ACTION_HELP_POWER_UP, 3)
	help.w3(ActionHelpSim.W_ACTION_HELP_STATE, 7)
	sim.wJoypadPressed = WarioRam.PAD_RIGHT
	help.switch_power_up()
	assert_eq([help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), help.r3(ActionHelpSim.W_ACTION_HELP_STATE),
			help.r3(ActionHelpSim.W_MENU_OBJ_1 + ActionHelpSim.OBJ_X), help.r3(ActionHelpSim.W_ACTION_HELP_BLACKED_OUT)],
			[4, 0, 0x48, 1])
	assert_eq(help.vram_writes.slice(0, 2), [[1, 0x9E06, 0x03], [1, 0x9E07, 0x03]], "power-up 3 back to plain")
	assert_eq(help.vram_writes[4], [1, 0x9E08, 0x05], "power-up 4 in PowerUpOBPals' colour")
	help.vram_writes.clear()
	sim.wJoypadPressed = WarioRam.PAD_RIGHT
	help.switch_power_up()
	assert_eq([help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), help.vram_writes.size()], [5, 4],
			"power-up 5, which Wario lacks, keeps its entry")
	help.w3(ActionHelpSim.W_ACTION_HELP_POWER_UP, 0)
	sim.wJoypadPressed = WarioRam.PAD_LEFT
	help.switch_power_up()
	assert_eq(help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP), 0, "no power-up before the first")


func test_a_closes_it_from_the_pause_menu_but_not_after_a_levels_clear() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.wSubState = 3
	sim.wPowerUpLevel = 2
	sim.wJoypadPressed = WarioRam.PAD_A
	sim.wAnimatedTilesGfx = 2
	help.w3(ActionHelpSim.W3D50D, 1)
	help.update()
	assert_eq([sim.wSubState, sim.wAnimatedTilesGfx, help.r3(ActionHelpSim.W3D50D)], [4, 0, 0])
	var cleared: ActionHelpSim = _help()
	cleared.sim.wSubState = 3
	cleared.sim.wPowerUpLevel = 0x82
	cleared.sim.wJoypadPressed = WarioRam.PAD_A
	cleared.w3(ActionHelpSim.W_ACTION_HELP_POWER_UP, 2)
	cleared.update()
	assert_eq([cleared.sim.wSubState, cleared.r3(ActionHelpSim.W_ACTION_HELP_COUNTER)], [3, 1], "the demo runs on")


func test_a_demos_end_after_a_levels_clear_leads_to_the_map() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.wState = ClearSim.ST_ACTION_HELP
	sim.wPowerUpLevel = 0x81
	sim.wAnimatedTilesFrameDuration = 6
	help.end_demo(func() -> void: help.next_state())
	assert_eq([sim.wPowerUpLevel, sim.wState, sim.wSubState, sim.wDayNight & 0x80, sim.wAnimatedTilesFrameDuration],
			[1, ActionHelpSim.ST_OVERWORLD, 0, 0x80, 0])
	var looped: ActionHelpSim = _help()
	looped.sim.wPowerUpLevel = 1
	looped.w3(ActionHelpSim.W_ACTION_HELP_STATE, 30)
	looped.end_demo(func() -> void: looped.next_state())
	assert_eq(looped.r3(ActionHelpSim.W_ACTION_HELP_STATE), 2, "from the pause menu it starts over")


func test_the_clear_screen_and_action_help_share_their_menu_objects() -> void:
	var sim := LevelSim.new()
	sim.load_clear_data({})
	sim.load_action_help_data({})
	sim.clear.w3(ClearSim.W_MENU_OBJ_3, 0x7D)
	sim.action_help.w0(ActionHelpSim.W_TIMER, 9)
	assert_eq([sim.action_help.r3(ActionHelpSim.W_MENU_OBJ_3), sim.clear.r0(ClearSim.W_TIMER)], [0x7D, 9])


func test_the_drawing_marks_the_power_ups_wario_has_and_takes_warios_tiles_by_dma() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.wSubState = 1
	sim.wPowerUpLevel = 3
	help.update()
	var vram := ActionHelpVram.new(help.document)
	vram.update(help, sim)
	assert_eq([vram.screen, vram.read_byte(1, 0x9E04), vram.read_byte(1, 0x9E08), vram.read_byte(0, 0x9E08),
			vram.read_byte(0, 0x9E12), vram.read_byte(1, 0x9E33)], ["action_help", 0x03, 0x07, 0x64, 0x64, 0x07],
			"the entries before level 3's plain, 4-9 unknown")
	help.show_wario_idle()
	sim.wSubState = 6  # DebugReset (a note): no fade sets the V-Blank function aside
	help.update()  # the V-Blank's DMA
	vram.update(help, sim)
	assert_eq([help.r0(ActionHelpSim.W_IS_DMA_TRANSFER_PENDING), vram.read_byte(0, 0x8000), vram.read_byte(0, 0x87FF)],
			[0, 0x66, 0x66])


func test_the_view_draws_action_help_from_its_fade_in() -> void:
	var help: ActionHelpSim = _help()
	var sim: LevelSim = help.sim
	sim.action_help = help
	var view := LevelView.new()
	view._sim = sim
	sim.wState = ClearSim.ST_ACTION_HELP
	sim.wSubState = 1
	help.update()
	help.sim = sim
	view.after_loop()
	assert_eq([view._action_help_vram.screen, view._action_help_loops], ["action_help", 1])
	sim.action_help = null
	help.sim = null
	view.free()
