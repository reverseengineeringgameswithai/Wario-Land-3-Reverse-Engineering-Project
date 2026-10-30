extends TestCase
## The credits (CreditsSim, WL3-052) on invented data (no ROM bytes): InitCredits' set-up, ShowCredits'
## wait for the music, its scroll by page, a line of text with its palettes and VBlank_160439's two
## writes of it, the music box's moves and plays to the close-up, the close-up's palettes and window,
## the fade in and the key's rise, the wait (a perfect game's way to the Perfect screen), LevelSim's
## routing with DebugReset's Init, and the drawing (CreditsVram).

const OAM_MAIN: String = "58:57e8"
const OAM_CLOSE_UP: String = "57:644a"


func _credits(sim: LevelSim = LevelSim.new()) -> CreditsSim:
	var credits := CreditsSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["58:5caf", "58:5cc4", "58:5ce5", "58:5ce8", "58:5ceb", "58:5cee", "57:67ed"]:
		framesets[key] = [[1, 2], [2, 2]]
	var frames: Array = []  # one entry a frame: (-16, -8), tile = frame
	for index: int in 53:
		frames.append([[-16, -8, index, 0]])
	# Three lines: "AB", an empty one, "C"; each line's palettes 1 to 13 plus the line's number.
	var text: String = "41427f" + "7f" + "437f"
	var pals := PackedByteArray()
	for line: int in 3:
		for letter: int in CreditsSim.CREDITS_TEXT_LENGTH:
			pals.append(line * 0x10 + letter + 1)
	credits.load_data({"framesets": framesets, "oam_tables": {OAM_MAIN: frames.slice(0, 29), OAM_CLOSE_UP: frames},
		"tables": {"CreditsText": {"location": "58:5d0f", "bytes": text},
			"CreditsPalsMap": {"location": "58:60e5", "bytes": pals.hex_encode()}},
		"gfx": {"palettes": {"58:44cc": "01".repeat(0x40), "58:450c": "02".repeat(0x40), "58:454c": "03".repeat(0x40),
			"58:458c": "04".repeat(0x40), "58:45cc": "05".repeat(0x40), "58:460c": "06".repeat(0x40)},
			"compressed": {"2c:5780": "11".repeat(0x800), "58:464c": "12".repeat(0x1800), "58:4af9": "13".repeat(0x1000),
				"58:5744": "14".repeat(0x400), "58:579c": "05".repeat(0x400)},
			"raw": {"2c:4000": "15".repeat(0x300)}}})
	return credits


func _loop(credits: CreditsSim, loops: int = 1) -> void:
	for loop: int in loops:
		credits.update()
		credits.sim.wGlobalCounter = (credits.sim.wGlobalCounter + 1) & 0xFF


func test_init_credits_sets_up_the_screen_the_pointers_and_the_music_box() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	sim.wSubState = 1
	credits.update()
	assert_eq([sim.wSubState, sim.wSCX, sim.wSCY, credits.r0(CreditsSim.W_CREDITS_PAGE), credits.r0(CreditsSim.W_TIMER),
			credits.vblank_func, credits.screen_loads], [2, 4, 0, 0, 120, CreditsSim.VBLANK_CREDITS, [["credits"]]])
	assert_eq([credits.r0(CreditsSim.W_CREDITS_BG_MAP_PTR), credits.r0(CreditsSim.W_CREDITS_BG_MAP_PTR + 1),
			credits.r0(CreditsSim.W_CREDITS_TEXT_PTR), credits.r0(CreditsSim.W_CREDITS_TEXT_PTR + 1),
			credits.r0(CreditsSim.W_CREDITS_PALS_MAP_PTR), credits.r0(CreditsSim.W_CREDITS_PALS_MAP_PTR + 1)],
			[0x9A, 0xE7, 0x5D, 0x0F, 0x60, 0xE5], "the pointers, high byte first")
	var box: int = CreditsSim.W_CREDITS_MUSIC_BOX
	assert_eq([credits.r3(box), credits.r3(box + 1), credits.r3(box + MenuScreenSim.OBJ_FRAME),
			credits.r3(box + MenuScreenSim.OBJ_DURATION), credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_PTR),
			credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_BANK), credits.r3(CreditsSim.W_MENU_OBJ_1 + 1)],
			[0x5B, 0x18, 1, 2, 0x57, 0x58, 0x18], "the music box and its key, animated")
	assert_eq([credits.r0(CreditsSim.W_TEMP_PALS_1), credits.r0(CreditsSim.W_TEMP_PALS_2), credits.wVirtualOAMByteSize,
			credits.wVirtualOAM.slice(0, 8)], [0x01, 0x02, 0, PackedByteArray([0x5B, 0x18, 1, 0, 0x5B, 0x18, 1, 0])],
			"LoadCreditsPals; both drawn with OAM_1617e8 (no scroll)")


func test_show_credits_waits_for_the_music_then_scrolls_by_page() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	sim.wSubState = 1
	credits.update()
	sim.wSubState = 3
	_loop(credits, 120)
	assert_eq([credits.r0(CreditsSim.W_TIMER), sim.wSCY, credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX + MenuScreenSim.OBJ_DURATION)],
			[0, 0, 2], "120 loops' wait, nothing animated")
	_loop(credits, 4)
	assert_eq(sim.wSCY, 4, "page 0: a line a loop")
	sim.wSCY = 0xFF
	sim.wGlobalCounter = 0
	_loop(credits)
	assert_eq([sim.wSCY, credits.r0(CreditsSim.W_CREDITS_PAGE), credits.r0(CreditsSim.W_CEE4)], [0, 1, 0x81],
			"the wrap counts a page, and at 0 a line is written (its palettes at this V-Blank)")
	_loop(credits, 4)
	assert_eq(sim.wSCY, 2, "pages 1 to 8: every other loop")
	credits.w0(CreditsSim.W_CREDITS_PAGE, CreditsSim.NUM_CREDITS_PAGES)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR, 5)
	credits.update()
	assert_eq([sim.wSubState, credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR)], [4, 0], "page 10: the music box's turn")


func test_a_line_goes_to_the_buffer_and_v_blank_writes_its_palettes_then_its_text() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	sim.wSubState = 1
	credits.update()
	sim.wSubState = 3
	credits.w0(CreditsSim.W_TIMER, 0)
	credits.w0(CreditsSim.W_CREDITS_PAGE, 1)
	credits.w0(CreditsSim.W_CREDITS_BG_MAP_PTR, 0x9B)
	credits.w0(CreditsSim.W_CREDITS_BG_MAP_PTR + 1, 0xE7)
	sim.wSCY = 7
	sim.wGlobalCounter = 2
	credits.update()
	assert_eq([credits.r0(CreditsSim.W_CREDITS_TEXT_BUFFER), credits.r0(CreditsSim.W_CREDITS_TEXT_BUFFER + 2),
			credits.r0(CreditsSim.W_CREDITS_TEXT_PALS), credits.r0(CreditsSim.W_CREDITS_TEXT_PALS + 12),
			credits.r0(CreditsSim.W_CREDITS_TEXT_PTR + 1), credits.r0(CreditsSim.W_CREDITS_PALS_MAP_PTR + 1),
			credits.r0(CreditsSim.W_CREDITS_BG_MAP_PTR), credits.r0(CreditsSim.W_CREDITS_BG_MAP_PTR + 1)],
			[0x41, 0x7F, 0x01, 0x0D, 0x12, 0xF2, 0x98, 0x07], "the line to its $7f, its palettes, a row on from $9c to $98")
	assert_eq([credits.r0(CreditsSim.W_CEE4), credits.vblank_writes.size(), credits.vblank_writes[0],
			credits.vblank_writes[13]], [0x81, 26, [1, 0x9807, 0x01], [0, 0x9807, CreditsSim.BLANK_TILE]],
			"first the palettes and blanks")
	sim.wGlobalCounter = 3
	credits.update()
	assert_eq([credits.r0(CreditsSim.W_CEE4), credits.vblank_writes], [0x01, [[0, 0x9807, 0x41], [0, 0x9808, 0x42]]],
			"then the text, bit 7 cleared")


func test_the_music_box_moves_right_plays_twice_and_starts_the_close_up() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	var box: int = CreditsSim.W_CREDITS_MUSIC_BOX
	credits.set_up_obj(box, 0x5B, 0x37, CreditsSim.FRAMESET_161CC4)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_BANK, CreditsSim.CREDITS_BANK)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_PTR, 0x57)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_PTR + 1, 0xE8)
	credits.set_up_obj(CreditsSim.W_MENU_OBJ_1, 0x5B, 0x37, CreditsSim.FRAMESET_161CAF)
	sim.wSubState = 4
	sim.wGlobalCounter = 0
	_loop(credits)
	assert_eq([credits.r3(box + 1), credits.r3(CreditsSim.W_MENU_OBJ_1 + 1), credits.wTempBank], [0x38, 0x38, 0x58],
			"to $38 a pixel a loop")
	_loop(credits)
	assert_eq(credits.r3(box + 1), 0x38, "then only on even loops: an odd one moves and animates nothing")
	credits.w3(box + 1, 0x50)
	sim.wGlobalCounter = 0
	_loop(credits)
	assert_eq(credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR), 1, "stopped at $50")
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR, 2)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_ANIMATION_ENDED, 1)
	sim.wGlobalCounter = 2
	_loop(credits)
	assert_eq([credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR), credits.r3(box + MenuScreenSim.OBJ_FRAMESET_PTR + 1)],
			[3, 0xEE], "the third end: it plays again (Frameset_161cee)")
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_ANIMATION_ENDED, 1)
	sim.wGlobalCounter = 4
	_loop(credits)
	assert_eq([sim.wSubState, credits.r0(CreditsSim.W_TIMER), credits.r3(box), credits.r3(box + 1),
			credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_VAR), credits.r3(CreditsSim.W_MENU_OBJ_1),
			credits.r3(box + MenuScreenSim.OBJ_FRAMESET_PTR + 1)], [5, 16, 0x5B, 0x50, 0, 0xE0, 0xE8],
			"the fourth: the close-up's set-up")


func test_the_close_up_takes_its_oam_its_palettes_and_the_window() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	var vram := CreditsVram.new(credits.document)
	sim.wSubState = 1
	credits.update()
	vram.update(credits)
	assert_eq([vram.lcdc, vram.wx, vram.wy], [0x87, 7, 0])
	sim.wSubState = 5
	credits.w0(CreditsSim.W_TIMER, 7)
	credits.update()
	assert_eq(credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX + MenuScreenSim.OBJ_FRAMESET_PTR + 1), 0xEB, "at 6, Frameset_161ceb")
	credits.w0(CreditsSim.W_TIMER, 1)
	credits.update()
	vram.update(credits)
	assert_eq([sim.wSubState, credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_BANK), credits.r3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_PTR),
			credits.wTempBank, credits.r0(CreditsSim.W_CEE4), credits.wVirtualOAM[2]], [6, 0x57, 0x64, 0x57, 0x02, 1],
			"OAM_15e44a in bank $57, frame 1 of the invented frameset")
	assert_eq([vram.bg_palettes[0], vram.obj_palettes[0], vram.lcdc], [0x03, 0x04, 0xE7], "applied, the window on")
	credits.update()
	assert_eq([sim.wSubState, credits.r0(CreditsSim.W_TEMP_PALS_1), credits.r0(CreditsSim.W_TEMP_PALS_2)], [7, 0x05, 0x06],
			"Func_1603cb: the fade's target")


func test_the_fade_in_steps_every_16_loops_and_the_key_rises() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	credits.set_up_obj(CreditsSim.W_MENU_OBJ_1, 0xE0, 0x4E, CreditsSim.FRAMESET_161CE5)
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_BANK, CreditsSim.CREDITS_BANK)
	credits.vblank_func = CreditsSim.VBLANK_CREDITS
	sim.wSubState = 7
	sim.wGlobalCounter = 0
	var loops: int = 0
	while sim.wSubState == 7 and loops < 1000:
		_loop(credits)
		loops += 1
	assert_eq([loops, credits.r3(CreditsSim.W_MENU_OBJ_1), credits.r0(CreditsSim.W_TIMER), credits.vblank_func],
			[32 * 16 + 1, 0x80, 180, CreditsSim.VBLANK_CREDITS], "33 calls a 16 loops apart; the key up to $80")
	assert_eq([sim.wPalFadeCounter, sim.wFadeSpeed], [0, 0])


func test_the_wait_goes_to_the_perfect_screen_only_after_a_perfect_game() -> void:
	var credits: CreditsSim = _credits()
	var sim: LevelSim = credits.sim
	credits.w3(CreditsSim.W_CREDITS_MUSIC_BOX_OAM_BANK, CreditsSim.CREDITS_BANK)
	credits.set_up_obj(CreditsSim.W_MENU_OBJ_1, 0x82, 0x4E, CreditsSim.FRAMESET_161CE5)
	sim.wSubState = 8
	sim.wState = LevelSim.ST_CREDITS
	credits.wTransitionParam = 0xF1  # TRANSITION_EPILOGUE_NOT_PERFECT
	sim.wJoypadPressed = WarioRam.PAD_A
	credits.w0(CreditsSim.W_TIMER, 1)
	_loop(credits, 3)
	assert_eq([sim.wState, credits.r3(CreditsSim.W_MENU_OBJ_1)], [LevelSim.ST_CREDITS, 0x80], "it stays; the key a line a loop")
	credits.wTransitionParam = CreditsSim.TRANSITION_EPILOGUE_PERFECT
	credits.update()
	assert_eq([sim.wState, sim.wSubState], [CreditsSim.ST_PERFECT, 0], "a button")
	sim.wState = LevelSim.ST_CREDITS
	sim.wSubState = 8
	sim.wJoypadPressed = 0
	credits.w0(CreditsSim.W_TIMER, 2)
	credits.update()
	assert_eq(sim.wState, LevelSim.ST_CREDITS)
	credits.update()
	assert_eq(sim.wState, CreditsSim.ST_PERFECT, "or wTimer's end")


func test_level_sim_runs_the_credits_in_their_state_and_debug_reset_jumps_to_init() -> void:
	var sim := LevelSim.new()
	var credits: CreditsSim = _credits(null)
	sim.wState = LevelSim.ST_CREDITS
	sim.update_level()
	assert_eq(Array(sim.unported), ["wState $09"], "not loaded: named")
	sim.credits = credits
	sim.wSubState = 1
	sim.update_level()
	assert_eq([sim.wSubState, credits.loops, sim.wSCX, Array(sim.unported)], [2, 1, 4, []])
	sim.wSubState = 9
	sim.update_level()
	assert_true(sim.unported.size() == 1 and "Init" in sim.unported[0], "DebugReset: Init (here without a save's SRAM)")


func test_the_credits_are_drawn_from_their_graphics_and_their_lines() -> void:
	var credits: CreditsSim = _credits()
	var vram := CreditsVram.new(credits.document)
	credits.sim.wSubState = 1
	credits.update()
	vram.update(credits)
	assert_eq([vram.read_byte(1, 0x8000), vram.read_byte(1, 0x8800), vram.read_byte(1, 0x8B00), vram.read_byte(0, 0x8FFF),
			vram.read_byte(0, 0x9000), vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800), vram.read_byte(0, 0x9C00),
			vram.read_byte(1, 0x9C00), vram.screen], [0x11, 0x15, 0, 0x13, 0x12, 0x7F, 0, 0x14, 0x05, "credits"],
			"the music box's tiles over the font's first $1000 bytes; BG map 0 blank, BG map 1 the close-up")
	credits.vblank_writes = [[1, 0x9807, 0x03], [0, 0x9807, 0x41]]
	credits.screen_loads = []
	vram.update(credits)
	assert_eq([vram.read_byte(1, 0x9807), vram.read_byte(0, 0x9807)], [0x03, 0x41])
	var copied: ScreenVram = vram.copy()
	assert_true(copied is CreditsVram and (copied as CreditsVram).lcdc == 0x87, "a copy keeps the registers")
