extends TestCase
## The map's save screen (PauseMenuSim) on invented data (no ROM bytes): the bar, the save into SRAM
## with its checksums, the complete box, the way back to the map, LevelSim's routing, and the drawing.
## The pause menu itself and the level's save: test_pause_menu_level.gd.

func _pause(sim: LevelSim = LevelSim.new()) -> PauseMenuSim:
	var pause := PauseMenuSim.new(sim)
	pause.load_data({"gfx": {"palettes": {PauseMenuSim.SAVE_SCREEN_PALS: "11".repeat(0x40)},
		"compressed": {"7d:62cc": "22".repeat(0x1800), "7d:6949": "33".repeat(0x400), "7d:69f9": "44".repeat(0x400),
			"7d:6a2e": "55".repeat(0x400), "7d:6ac2": "66".repeat(0x400)},
		"raw": {"76:6800": "77".repeat(0x800)}}})
	return pause


func test_the_save_screen_backs_up_the_map_and_queues_the_bars_first_tile() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 0x19
	sim.wSCY = 0x12
	sim.wSCX = 0x34
	pause.w0(PauseMenuSim.W_TEMP_PALS_1 + 0x7F, 0x99)
	pause.update()
	assert_eq([pause.r3(PauseMenuSim.W3D500), pause.r3(PauseMenuSim.W3D501), pause.r3(PauseMenuSim.W3D280 + 0x7F)],
			[0x12, 0x34, 0x99], "the scroll and palettes backed up")
	assert_eq([sim.wSCY, sim.wSCX, sim.wResetDisabled, sim.wSubState, pause.wTempBank], [0, 0, 1, 0x1A, 0x76])
	assert_eq([pause.r0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE), pause.r0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE + 1),
			pause.r0(PauseMenuSim.W_TEMP_PALS_1 + 0x7F)], [0x99, 0x64, 0x11])


func test_the_bar_fills_a_tile_every_four_loops_and_v_blank_draws_it() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	pause.vblank_func = PauseMenuSim.VBlankFunc.SAVE_SCREEN
	pause.w0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE, 0x99)
	pause.w0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE + 1, 0x64)
	sim.wSubState = 0x1B
	var drawn: Array = []
	var loops: int = 0
	while sim.wSubState == 0x1B and loops < 100:
		pause.update()
		loops += 1
		for entry: Array in pause.vblank_writes:
			if int(entry[0]) == 0:
				drawn.append(int(entry[1]))
	assert_eq([loops, drawn.size(), drawn[0], drawn[8], pause.r0(PauseMenuSim.W_CEE4)], [40, 9, 0x9965, 0x996D, 0])


func test_save_writes_the_progress_twice_with_its_checksum_and_echoes() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 0x1D
	pause.w0(PauseMenuSim.W_SAVE_COUNTER + 3, 0xFF)  # the counter carries into its third byte
	pause.w0(PauseMenuSim.W_SAVE_COUNTER + 0x10, 0xF0)
	pause.wx(2, PauseMenuSim.W_TREASURES_COLLECTED + 0x10, 0x20)
	pause.update()
	assert_eq([pause.r0(PauseMenuSim.W_SAVE_COUNTER + 2), pause.r0(PauseMenuSim.W_SAVE_COUNTER + 3)], [1, 0])
	var checksum: int = 1 + 0xF0 + 0x20
	for at: int in [PauseMenuSim.S_CHECK_VALS, PauseMenuSim.S_BACKUP_CHECK_VALS]:
		assert_eq([pause.rs(0, at), pause.rs(0, at + 3), pause.rs(0, at + 4 + 2), pause.rs(0, at + 4 + 0x10),
				pause.rs(0, at + 4 + 0x5B + 0x10)], [0x77, 0x33, 1, 0xF0, 0x20], "check values, counter, data, treasures")
	for at: int in [PauseMenuSim.S_GAME_DATA_CHECKSUM, PauseMenuSim.S_GAME_DATA_CHECKSUM_ECHO2,
			PauseMenuSim.S_BACKUP_GAME_DATA_CHECKSUM_ECHO1]:
		assert_eq((pause.rs(0, at) << 8) | pause.rs(0, at + 1), checksum)
	assert_eq([pause.r0(PauseMenuSim.W_CHECKSUM + 1), pause.rs(0, PauseMenuSim.S0A790), pause.r0(PauseMenuSim.W_TIMER + 1),
			sim.wSubState, pause.vblank_func], [checksum & 0xFF, 0, 2, 0x1E, PauseMenuSim.VBlankFunc.SAVING])


func test_the_complete_box_closes_with_a_or_after_512_loops() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 0x1F
	pause.w0(PauseMenuSim.W_TIMER + 1, 2)
	var loops: int = 0
	while sim.wSubState == 0x1F and loops < 1000:
		pause.update()
		loops += 1
	assert_eq(loops, 512)
	var pressed: PauseMenuSim = _pause()
	pressed.sim.wSubState = 0x1F
	pressed.w0(PauseMenuSim.W_TIMER + 1, 2)
	pressed.sim.wJoypadPressed = WarioRam.PAD_A
	pressed.update()
	assert_eq([pressed.sim.wSubState, pressed.r0(PauseMenuSim.W_TIMER + 1)], [0x20, 0])


func test_after_the_save_the_map_comes_back_where_it_was() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 0x21
	sim.wPendingSubState = 8
	sim.wResetDisabled = 1
	pause.w3(PauseMenuSim.W3D500, 0x10)
	pause.w3(PauseMenuSim.W3D280, 0xAB)
	pause.update()
	assert_eq([sim.wState, sim.wSubState, sim.wSCY, sim.wResetDisabled, pause.r0(PauseMenuSim.W_TEMP_PALS_1)],
			[PauseMenuSim.ST_OVERWORLD, 8, 0x10, 0, 0xAB])
	var over: PauseMenuSim = _pause()
	over.sim.wSubState = 0x21
	over.w0(PauseMenuSim.W_TRANSITION_PARAM, PauseMenuSim.TRANSITION_GAME_OVER)
	over.update()
	assert_eq([over.sim.wState, over.sim.wSubState], [PauseMenuSim.ST_GAME_OVER, 0])


func test_the_level_routes_the_save_screen_and_its_stand_in_without_pause_menu_json() -> void:
	var sim := LevelSim.new()
	sim.load_pause_menu_data({})
	sim.wState = LevelSim.ST_PAUSE_MENU
	sim.wSubState = 0x1F
	sim.pause_menu_screen.w0(PauseMenuSim.W_TIMER, 5)
	sim.update_level()
	assert_eq(sim.pause_menu_screen.r0(PauseMenuSim.W_TIMER), 4, "the save screen's loop")
	var without := LevelSim.new()
	without.wState = LevelSim.ST_PAUSE_MENU
	without.wSubState = 3
	without.wJoypadPressed = WarioRam.PAD_START
	without.wPendingSubState = 2
	without.update_level()
	assert_eq([without.wState, without.wSubState], [LevelSim.ST_LEVEL, 2], "without pause_menu.json, the stand-in")


func test_the_drawing_takes_the_box_wario_asleep_and_the_bar() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 0x19
	pause.update()
	var vram := SaveScreenVram.new(pause.document)
	vram.update(pause, sim)
	assert_eq([vram.screen, vram.read_byte(0, 0x8000), vram.read_byte(0, 0x8800), vram.read_byte(0, 0x9C00),
			vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800)], ["save", 0x77, 0x22, 0xFF, 0x33, 0x44])
	pause.vblank_writes = [[1, 0x9965, 5], [0, 0x9965, 2]]
	pause.screen_loads.clear()
	vram.update(pause, sim)
	assert_eq([vram.read_byte(0, 0x9965), vram.read_byte(1, 0x9965)], [2, 5])


func test_the_save_screens_show_their_palettes_once_faded_in_after_the_perfect_screen_too() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	for offset: int in 0x80:
		pause.wram[0][offset] = 0x40 + offset
	var vram := SaveScreenVram.new(pause.document)
	sim.wPalFadeCounter = 0
	for substate: int in [0x2A, 0x2B, 0x2F]:
		sim.wSubState = substate
		vram.bg_palettes.fill(0)
		vram.update(pause, sim)
		assert_eq(vram.bg_palettes[1], 0 if substate == 0x2A else 0x41, "sub-state $%02x" % substate)
	assert_eq(vram.obj_palettes[0], 0x80, "the OBJ palettes from wTempPals2")
