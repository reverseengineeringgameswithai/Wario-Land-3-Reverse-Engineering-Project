extends TestCase
## The hidden figure (HiddenFigureFunctions) on invented data (no ROM bytes): its tables' steps,
## the swipe's end, the hands' quirks (the right hand's cleared substate, the knocked hand's table
## and its way home), and Wario caught by a clap.


func _sim() -> HiddenFigureFunctions:
	var sim := HiddenFigureFunctions.new()
	var page := PackedByteArray()
	page.resize(0x100)
	page[0x00] = 0x02  # Data_4c000: +2, -2, then the end
	page[0x01] = 0xFE
	page[0x02] = 0x80
	page[0x80] = 0x03  # Data_4c080: +3, then the end
	page[0x81] = 0x80
	sim.bank_data[(0x13 << 16) | 0x4000] = page
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	return sim


func test_a_table_step_repeats_its_last_entry_at_the_end() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.wHiddenFigureSCYShake = 0x10
	for i: int in 4:
		sim._hidden_figure_shake_y(HiddenFigureFunctions.DATA_4C000)
	assert_eq([sim.wHiddenFigureSCYShake, sim.cur(ObjectSim.OBJ_VAR_3)], [0x0C, 2],
			"+2, -2, then -2 twice more with the index kept at the $80")


func test_a_swipe_whose_hand_was_knocked_loose_orders_the_other_hands_slam() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.set_cur(ObjectSim.OBJ_VAR_1, 3)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 1)
	sim.wram1[HiddenFigureFunctions.W_1D14B] = 1
	sim.wram1[HiddenFigureFunctions.W_1D14C] = 1
	sim.hidden_figure_main()
	assert_eq([sim.wHiddenFigureSCYShake, sim.wc08b], [2, 3], "shaken both ways")
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_STATE_DURATION),
			sim.wram1[HiddenFigureFunctions.W_1D14B]], [9, 4, 4], "the right hand's slam next")


func test_the_right_hand_clears_its_substate_where_the_left_clears_its_state() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.wram1[HiddenFigureFunctions.W_1D14B] = 7  # a clap
	for left_hand: bool in [true, false]:
		sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_HDIR)
		sim.set_cur(ObjectSim.OBJ_STATE, 0x2F)
		sim._hidden_figure_hand_wait(left_hand)
		var clap: int = HiddenFigureFunctions.HIDDEN_FIGURE_LEFT_HAND_CLAP if left_hand \
				else HiddenFigureFunctions.HIDDEN_FIGURE_RIGHT_HAND_CLAP
		assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE)],
				[clap & 0xFFFF, HiddenFigureFunctions.OBJ_INTERACTION_4F])
		assert_eq([sim.cur(ObjectSim.OBJ_SUBSTATE), sim.cur(ObjectSim.OBJ_STATE)],
				[ObjectSim.OBJSUBFLAG_HDIR, 0] if left_hand else [0, 0x2F],
				"the left hand: state; the right hand: substate (.asm_4d455)")


func test_a_knocked_hand_on_its_way_home_only_rises_and_flickers() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.set_cur(ObjectSim.OBJ_ID, HiddenFigureFunctions.HIDDEN_FIGURE_RIGHT_HAND)
	for i: int in 4:  # home: y $0120, x $0310
		sim.wram1[HiddenFigureFunctions.W_1D156 + i] = [0x20, 0x01, 0x10, 0x03][i]
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0110)  # above its home
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0320)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x2D)
	sim.wGlobalCounter = 4
	sim.hidden_figure_hand_knocked()
	assert_eq([sim.cur_y(), sim.cur_x()], [0x010F, 0x031F], "up even when above, and towards the home's x")
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE, ObjectSim.OBJFLAG_INVISIBLE,
			"invisible on every 4th frame")
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0120)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0310)
	sim.wram1[HiddenFigureFunctions.W_1D14D] = 1
	sim.hidden_figure_hand_knocked()
	assert_eq([sim.wram1[HiddenFigureFunctions.W_1D14D], sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION),
			sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE],
			[0, HiddenFigureFunctions.HIDDEN_FIGURE_RIGHT_HAND_WAIT & 0xFFFF, 0], "home: waiting again, visible")


func test_the_knocked_hands_table_ignores_bit_7_and_falls_by_default() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x8D)  # $0d once JumpTable doubles it in a byte
	sim.set_cur(ObjectSim.OBJ_VAR_3, 5)
	sim.wc08a = 0x10
	sim.wSCYShake = 2
	sim.wc08c = 0x30
	sim.hidden_figure_hand_knocked()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_VAR_3), sim.wSCY, sim.wSCX], [0x30, 0, 0x12, 0x30])


func test_wario_caught_by_the_left_hands_clap_pauses_the_figure_and_both_hands() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x2F)
	sim._hidden_figure_hand_clap(true)
	assert_eq([sim.wram1[HiddenFigureFunctions.W_1D14E], sim.wram1[HiddenFigureFunctions.W_1D14F],
			sim.wram1[HiddenFigureFunctions.W_1D150], sim.cur(ObjectSim.OBJ_STATE)], [0x80, 0x80, 0x80, 0])
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0140)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x02FE)
	sim._hidden_figure_hand_clap(true)
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.wWarioYPos, sim.wWarioXPos],
			[HiddenFigureFunctions.HIDDEN_FIGURE_LEFT_HAND_HOLD & 0xFFFF, 0x013F, 0x0304], "it holds him")
	sim.set_cur(ObjectSim.OBJ_VAR_1, 7)
	sim.hidden_figure_main()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_STATE_DURATION)], [8, 0xA0], "the figure waits")
	sim.hidden_figure_face_func()
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), HiddenFigureFunctions.HIDDEN_FIGURE_FACE_LAUGH & 0xFFFF,
			"the face laughs 60 frames on")


func test_the_figures_bg_palettes_flash_every_8_frames_and_follow_the_hits_left() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.wram1[HiddenFigureFunctions.W_1D15A] = 2
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 0x3C)
	var seen: Array = []
	for counter: int in [0x10, 0x11, 0x18, 0x20]:
		sim.wGlobalCounter = counter
		sim.hidden_figure_face_hurt()
		seen.append(sim.hidden_figure_bg_pals)
	assert_eq(seen, [HiddenFigureFunctions.PALS_4D07B, HiddenFigureFunctions.PALS_4D07B, HiddenFigureFunctions.PALS_4D04B,
			HiddenFigureFunctions.PALS_4D07B], "Func_4cfe0: its own on & 15 = 0 (two hits left), the flash on 8")
	assert_eq(sim.hidden_figure_bg_pal_writes, 3, "no write on other frames")
	sim.wram1[HiddenFigureFunctions.W_1D15A] = 1
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 1)
	sim.wGlobalCounter = 0x18
	sim.hidden_figure_face_hurt()
	assert_eq([sim.hidden_figure_bg_pals, sim.hidden_figure_bg_pal_writes], [HiddenFigureFunctions.PALS_4D01B, 4],
			"the hurt's end: Func_4d005 (one hit left), whatever the counter")


func test_the_collapse_flashes_and_ends_with_the_figures_palettes() -> void:
	var sim: HiddenFigureFunctions = _sim()
	sim.wram1[HiddenFigureFunctions.W_1D15A] = 0
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 2)
	sim.wGlobalCounter = 0x08
	sim.hidden_figure_collapse()
	assert_eq(sim.hidden_figure_bg_pals, HiddenFigureFunctions.PALS_4D04B, "the flash while it counts down")
	sim.wGlobalCounter = 0x09
	sim.hidden_figure_collapse()
	assert_eq([sim.hidden_figure_bg_pals, sim.hidden_figure_bg_pal_writes, sim.wLevelEndScreen],
			[HiddenFigureFunctions.PALS_4D01B, 2, WarioRam.LVLEND_EPILOGUE], "at 0: the epilogue and Func_4d005")
