extends TestCase
## The game over screen (GameOverSim, WL3-052) on invented data (no ROM bytes): InitGameOverScreen's
## set-up, the first update drawing after the init's sprites, the wait, the screen's drop and bounce
## (every 4th loop, the others drawing nothing), A waking Wario, Func_db3e4's wait for his animation's
## end, the fade and GameOverReset's Init, LevelSim's routing with DebugReset, and the drawing
## (GameOverVram).

const OAM_WARIO: String = "2a:6b5c"
const OAM_TEXT: String = "36:7bd2"


func _game_over(sim: LevelSim = LevelSim.new()) -> GameOverSim:
	var game_over := GameOverSim.new(sim)
	var framesets: Dictionary = {}
	for key: String in ["2a:6ccb", "2a:6ce2", "36:7bf5"]:
		framesets[key] = [[1, 2], [2, 2]]
	var frames: Array = []  # one entry a frame: (-16, -8), tile = frame
	for index: int in 9:
		frames.append([[-16, -8, index, 0]])
	game_over.load_data({"framesets": framesets, "oam_tables": {OAM_WARIO: frames, OAM_TEXT: frames.slice(0, 3)},
		"gfx": {"palettes": {"36:7509": "01".repeat(0x40), "36:7549": "02".repeat(0x40), "21:6ad5": "03".repeat(8)},
			"compressed": {"36:7589": "11".repeat(0x1800), "36:7aee": "14".repeat(0x200), "36:7b8f": "05".repeat(0x200)},
			"raw": {"76:6800": "15".repeat(0x800)}}})
	return game_over


func _loop(game_over: GameOverSim, loops: int = 1) -> void:
	for loop: int in loops:
		game_over.update()
		game_over.sim.wGlobalCounter = (game_over.sim.wGlobalCounter + 1) & 0xFF


func _init_screen(game_over: GameOverSim) -> void:
	game_over.sim.wSubState = 1
	game_over.update()


func test_init_sets_up_the_screen_wario_and_the_text_and_keeps_their_sprites() -> void:
	var game_over: GameOverSim = _game_over()
	var sim: LevelSim = game_over.sim
	game_over.w3(GameOverSim.W_GAME_OVER_WARIO_VAR, 3)
	game_over.w3(GameOverSim.W_SFX_TIMER, 9)
	_init_screen(game_over)
	assert_eq([sim.wSubState, sim.wSCX, sim.wSCY, game_over.r0(GameOverSim.W_TIMER), game_over.vblank_func,
			game_over.screen_loads], [2, 0, 0x60, 64, GameOverSim.VBLANK_GAME_OVER, [["game_over"]]])
	var wario: int = GameOverSim.W_GAME_OVER_WARIO
	assert_eq([game_over.r3(wario), game_over.r3(wario + 1), game_over.r3(wario + MenuScreenSim.OBJ_FRAME),
			game_over.r3(wario + MenuScreenSim.OBJ_DURATION), game_over.r3(wario + MenuScreenSim.OBJ_FRAMESET_PTR),
			game_over.r3(GameOverSim.W_GAME_OVER_WARIO_VAR), game_over.r3(GameOverSim.W_SFX_TIMER)],
			[0x80, 0x50, 1, 2, 0x6C, 0, 0], "Wario on Frameset_aaccb, animated; his state and wSFXTimer cleared")
	var text: int = GameOverSim.W_MENU_OBJ_1
	assert_eq([game_over.r3(text), game_over.r3(text + 1), game_over.r3(text + MenuScreenSim.OBJ_FRAME),
			game_over.r3(text + MenuScreenSim.OBJ_FRAMESET_PTR + 1)], [0x18, 0x18, 1, 0xF5], "the text on Frameset_dbbf5")
	assert_eq([game_over.r0(GameOverSim.W_TEMP_PALS_1), game_over.r0(GameOverSim.W_TEMP_PALS_2 + 7),
			game_over.r0(GameOverSim.W_TEMP_PALS_2 + 8)], [0x01, 0x03, 0x02], "Pals_86ad5 over wTempPals2's first palette")
	assert_eq([game_over.wVirtualOAMByteSize, game_over.wVirtualOAM.slice(0, 8)],
			[8, PackedByteArray([0x80, 0x50, 1, 0, 0xB8, 0x18, 1, 0])],
			"Wario unscrolled, the text $60 lines up with the screen; the OAM's size kept (no ClearUnusedVirtualOAM)")


func test_the_first_update_draws_after_the_inits_sprites() -> void:
	var game_over: GameOverSim = _game_over()
	var sim: LevelSim = game_over.sim
	_init_screen(game_over)
	sim.wSubState = 3
	game_over.update()
	assert_eq([game_over.wVirtualOAMByteSize, game_over.wVirtualOAM.slice(0, 16)],
			[0, PackedByteArray([0x80, 0x50, 1, 0, 0xB8, 0x18, 1, 0, 0x80, 0x50, 1, 0, 0xB8, 0x18, 1, 0])])
	game_over.update()
	assert_eq(game_over.wVirtualOAM.slice(8, 16), PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]),
			"then each loop from the start")


func test_the_screen_waits_drops_in_and_bounces() -> void:
	var game_over: GameOverSim = _game_over()
	var sim: LevelSim = game_over.sim
	_init_screen(game_over)
	sim.wSubState = 3
	sim.wGlobalCounter = 0
	_loop(game_over, 63)
	assert_eq([game_over.r3(GameOverSim.W_GAME_OVER_WARIO_VAR), game_over.r0(GameOverSim.W_TIMER), sim.wSCY], [0, 1, 0x60])
	_loop(game_over)
	assert_eq(game_over.r3(GameOverSim.W_GAME_OVER_WARIO_VAR), 1, "64 loops' wait")
	_loop(game_over, 31)
	assert_eq([sim.wSCY, game_over.wVirtualOAM[4]], [3, 0x18 - 3], "3 lines a loop, the text with the screen")
	_loop(game_over)
	assert_eq([sim.wSCY, game_over.r3(GameOverSim.W_GAME_OVER_WARIO_VAR), game_over.r0(GameOverSim.W_TIMER)], [0, 2, 6])
	var counts: Array = []
	var scroll: Array = []
	while game_over.r3(GameOverSim.W_GAME_OVER_WARIO_VAR) == 2 and counts.size() < 100:
		var duration: int = game_over.r3(GameOverSim.W_GAME_OVER_WARIO + MenuScreenSim.OBJ_DURATION)
		var counter: int = sim.wGlobalCounter
		_loop(game_over)
		if (counter & 0b11) != 0:
			assert_eq(game_over.r3(GameOverSim.W_GAME_OVER_WARIO + MenuScreenSim.OBJ_DURATION), duration,
					"off the 4th loops: nothing animated")
		else:
			scroll.append(sim.wSCY)
		counts.append(counter)
	assert_eq([scroll, counts.size(), game_over.r0(GameOverSim.W_TIMER)], [[2, 0, 2, 0, 2, 0], 21, 0],
			"6 moves of 2 lines, down on odd counts")


func test_a_wakes_wario_and_his_animations_end_leads_to_the_fade_and_init() -> void:
	var game_over: GameOverSim = _game_over()
	var sim: LevelSim = game_over.sim
	_init_screen(game_over)
	sim.wSubState = 3
	game_over.w3(GameOverSim.W_GAME_OVER_WARIO_VAR, 3)
	sim.wJoypadPressed = WarioRam.PAD_B
	game_over.update()
	assert_eq(sim.wSubState, 3, "only A")
	sim.wJoypadPressed = WarioRam.PAD_A
	game_over.update()
	var wario: int = GameOverSim.W_GAME_OVER_WARIO
	assert_eq([sim.wSubState, game_over.r3(wario + MenuScreenSim.OBJ_FRAMESET_PTR + 1),
			game_over.r3(wario + MenuScreenSim.OBJ_FRAME), game_over.r3(wario + MenuScreenSim.OBJ_DURATION)],
			[4, 0xE2, 1, 2], "Frameset_aace2 from its start, animated in the same loop")
	var loops: int = 0
	while sim.wSubState == 4 and loops < 100:
		_loop(game_over)
		loops += 1
	assert_eq([loops, game_over.r3(GameOverSim.W_GAME_OVER_WARIO_ANIMATION_ENDED)], [6, 1], "Func_db3e4: to its end")
	loops = 0
	while sim.wSubState == 5 and loops < 100:
		_loop(game_over)
		loops += 1
	assert_eq([loops, game_over.vblank_func], [LevelSim.FADE_STEPS, GameOverSim.VBLANK_GAME_OVER], "FastFadeToWhite")


func test_level_sim_runs_the_screen_in_its_state_and_its_resets_jump_to_init() -> void:
	var sim := LevelSim.new()
	var game_over: GameOverSim = _game_over(null)
	sim.wState = LevelSim.ST_GAME_OVER
	sim.update_level()
	assert_eq(Array(sim.unported), ["wState $0c"], "not loaded: named")
	sim.game_over = game_over
	sim.wSubState = 1
	sim.update_level()
	assert_eq([sim.wSubState, game_over.loops, sim.wSCY, Array(sim.unported)], [2, 1, 0x60, []])
	for substate: int in [6, 0x0F]:
		sim.unported.clear()
		sim.wSubState = substate
		sim.update_level()
		assert_true(sim.unported.size() == 1 and "Init" in sim.unported[0],
				"GameOverReset and DebugReset: Init (here without a save's SRAM)")
	sim.unported.clear()
	sim.wSubState = 0x10
	sim.update_level()
	assert_eq(Array(sim.unported), ["_GameOverStateTable sub-state 16 (past the table)"])


func test_the_screen_is_drawn_from_its_graphics() -> void:
	var game_over: GameOverSim = _game_over()
	var vram := GameOverVram.new(game_over.document)
	_init_screen(game_over)
	vram.update(game_over)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(0, 0x87FF), vram.read_byte(0, 0x8800), vram.read_byte(0, 0x97FF),
			vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800), vram.read_byte(0, 0x9A00), vram.read_byte(1, 0x9A00),
			vram.screen], [0x15, 0x15, 0x11, 0x11, 0x14, 0x05, 0x7F, 0, "game_over"],
			"WarioSleepGfx over GameOverGfx's start; the maps over FillBGMap0_With7f")
	assert_eq([vram.bg_palettes[0], vram.obj_palettes[0], vram.obj_palettes[8]], [0x01, 0x03, 0x02])
	game_over.screen_loads = []
	vram.write_byte(0, 0x9800, 0x20)
	vram.update(game_over)
	assert_eq(vram.read_byte(0, 0x9800), 0x20, "only the init loads")
