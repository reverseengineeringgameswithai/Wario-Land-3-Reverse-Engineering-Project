extends TestCase
## The pause menu and the level's save from it (PauseMenuSim, sub-states 0-$10) on invented data (no
## ROM bytes): InitPauseMenu's backup, palettes, objects, and sprites, the highlight moved and chosen,
## the choices once its frameset ends (Return, Save, To Map, Action Help), ExitPauseMenu and the
## way back to the level, InitSaveScreen, SaveLevel's four copies and checksums (CalculateChecksumLong's
## two bytes among them) and the map's backup, the reset's jump to Init, and LevelSim's routing.

## Every frameset the menu names: two frames of 2 loops, its address's low six bits and the next.
const FRAMESETS: Array = [0x5C4A, 0x5C4D, 0x5C50, 0x5C69, 0x5C74, 0x5C77, 0x5C9C, 0x5C9F, 0x5CB8, 0x5CBB,
	0x5CD4, 0x5CED, 0x5CF0, 0x5CF3, 0x5CF6, 0x5CF9, 0x5D0A, 0x5D1B, 0x5D20, 0x5D41, 0x5D4C]


func _pause(sim: LevelSim = LevelSim.new()) -> PauseMenuSim:
	var framesets: Dictionary = {}
	for address: int in FRAMESETS:
		framesets["7c:%04x" % address] = [[address & 0x3F, 2], [(address + 1) & 0x3F, 2]]
	var frames: Array = []
	for frame: int in 64:
		frames.append([[0, 0, frame, 0x01]])  # one entry a frame, its tile the frame
	var pause := PauseMenuSim.new(sim)
	pause.load_data({"framesets": framesets, "oam_tables": {PauseMenuSim.OAM_PAUSE_MENU: frames},
		"gfx": {"palettes": {PauseMenuSim.PAUSE_MENU_PALS_1: "a1".repeat(0x40),
			PauseMenuSim.PAUSE_MENU_PALS_2: "b2".repeat(0x40), PauseMenuSim.SAVE_SCREEN_PALS: "11".repeat(0x40)},
			"compressed": {SaveScreenVram.PAUSE_MENU_GFX: "c3".repeat(0x1800), "7d:5de1": "d4".repeat(0x400),
				"7d:5f49": "05".repeat(0x400), "7d:603a": "e6".repeat(0x400), "7d:6194": "07".repeat(0x400)},
			"raw": {"7d:57e1": "f8".repeat(0x200), "7d:59e1": "f9".repeat(0x200), "7d:5be1": "fa".repeat(0x200)}}})
	return pause


## The highlight's (wMenuObj2) y, x, frame, frameset offset, duration, and frameset.
func _highlight(pause: PauseMenuSim) -> Array:
	var obj: int = PauseMenuSim.W_MENU_OBJ_2
	return [pause.r3(obj), pause.r3(obj + 1), pause.r3(obj + MenuScreenSim.OBJ_FRAME),
		pause.r3(obj + MenuScreenSim.OBJ_FRAMESET_OFFSET), pause.r3(obj + MenuScreenSim.OBJ_DURATION),
		(pause.r3(obj + MenuScreenSim.OBJ_FRAMESET_PTR) << 8) | pause.r3(obj + MenuScreenSim.OBJ_FRAMESET_PTR + 1)]


func test_init_pause_menu_backs_up_the_level_and_sets_up_the_menu() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 1
	sim.wSCY = 0x12
	sim.wSCX = 0x34
	sim.wAnimatedTilesFrameDuration = 6
	sim.wAnimatedTilesGfx = 2
	sim.wRoomAnimatedTilesEnabled = 1
	pause.w0(PauseMenuSim.W_TEMP_PALS_1 + 0x7F, 0x99)
	pause.w0(PauseMenuSim.W_KEY_AND_TREASURE_FLAGS, PauseMenuSim.RED_KEY | PauseMenuSim.GREY_TREASURE)
	pause.update()
	assert_eq([pause.r3(PauseMenuSim.W3D500), pause.r3(PauseMenuSim.W3D501), pause.r3(PauseMenuSim.W3D280 + 0x7F),
			pause.r3(PauseMenuSim.W_TEMP_ANIMATED_TILES_FRAME_DURATION), pause.r3(PauseMenuSim.W_TEMP_ANIMATED_TILES_GROUP)],
			[0x12, 0x34, 0x99, 6, 2], "the scroll, the palettes, and the animated tiles kept")
	assert_eq([sim.wSCY, sim.wSCX, sim.wRoomAnimatedTilesEnabled, sim.wSubState, pause.vblank_func,
			pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION), pause.r0(PauseMenuSim.W_TEMP_PALS_1),
			pause.r0(PauseMenuSim.W_TEMP_PALS_1 + 0x7F)], [0, 0, 0, 2, PauseMenuSim.VBlankFunc.PAUSE_MENU, 0, 0xA1, 0xB2])
	assert_eq(_highlight(pause), [0x38, 0x20, 0x5CB8 & 0x3F, 2, 2, 0x5CB8], "over Return, animated once")
	assert_eq([pause.r3(PauseMenuSim.W_MENU_OBJ_4), pause.r3(PauseMenuSim.W_MENU_OBJ_5),
			pause.r3(PauseMenuSim.W_MENU_OBJ_5 + MenuScreenSim.OBJ_ATTRIBUTES),
			pause.r3(PauseMenuSim.W_MENU_OBJ_8 + MenuScreenSim.OBJ_FRAMESET_PTR + 1),
			pause.r3(PauseMenuSim.W_MENU_OBJ_9 + MenuScreenSim.OBJ_FRAMESET_PTR + 1)],
			[0, 0x54, 0x03, 0xF0, 0xF3], "the red key alone; the grey treasure collected, the red not")
	# The highlight, Wario, the red key, and the four treasures, at their places plus the OAM offsets.
	assert_eq(pause.wVirtualOAMByteSize, 7 * 4)
	assert_eq(Array(pause.wVirtualOAM.slice(0, 4)), [0x38 + 16, 0x20 + 8, 0x5CB8 & 0x3F, 0x01])
	assert_eq(Array(pause.wVirtualOAM.slice(8, 12)), [0x54 + 16, 0x48 + 8, 0x5C4D & 0x3F, 0x01 ^ 0x03])


func test_in_time_attack_the_menu_keeps_the_levels_best_time() -> void:
	var pause: PauseMenuSim = _pause()
	pause.sim.wSubState = 1
	pause.w0(PauseMenuSim.W_GAME_MODE_FLAGS, PauseMenuSim.MODE_TIME_ATTACK)
	pause.w0(PauseMenuSim.W_LEVEL, 0x19)  # (wLevel >> 3) * 2: the scores' seventh byte
	pause.w0(PauseMenuSim.W_LEVEL_TIME_ATTACK_SCORES + 6, 0x12)
	pause.w0(PauseMenuSim.W_LEVEL_TIME_ATTACK_SCORES + 7, 0x34)
	pause.update()
	assert_eq([pause.r3(PauseMenuSim.W3D511), pause.r3(PauseMenuSim.W3D511 + 1)], [0x12, 0x34])


func test_the_highlight_moves_between_the_buttons_and_b_chooses_return() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wJoypadPressed = WarioRam.PAD_RIGHT
	pause.handle_pause_menu_input()
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENU_SAVE, 0x40, 0x40, 0, 0, 0, 0x5C9C])
	pause.w0(PauseMenuSim.W_TRANSFORMATION, WarioRam.TRANSFORMATION_OWL_WARIO)
	pause.handle_pause_menu_input()
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENU_ACTION_HELP, 0x38, 0x60, 0, 0, 0, 0x5CF9], "Owl Wario's Action Help")
	pause.handle_pause_menu_input()
	pause.handle_pause_menu_input()  # nothing right of To Map
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENU_TO_MAP, 0x40, 0x80, 0, 0, 0, 0x5C74])
	sim.wJoypadPressed = WarioRam.PAD_LEFT
	pause.handle_pause_menu_input()
	pause.w0(PauseMenuSim.W_GAME_MODE_FLAGS, PauseMenuSim.MODE_TIME_ATTACK)
	pause.handle_pause_menu_input()
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENU_RETURN, 0x38, 0x20, 0, 0, 0, 0x5CB8], "Time Attack has no Save")
	sim.wJoypadPressed = WarioRam.PAD_B
	pause.handle_pause_menu_input()
	sim.wJoypadPressed = WarioRam.PAD_RIGHT
	pause.handle_pause_menu_input()
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENUF_B_PAD_SELECT, 0x38, 0x20, 0, 0, 0, 0x5CBB], "chosen, then no more input")


func test_a_chooses_the_button_restarting_its_frameset_in_place() -> void:
	var pause: PauseMenuSim = _pause()
	pause.w3(PauseMenuSim.W_PAUSE_MENU_SELECTION, PauseMenuSim.PAUSEMENU_SAVE)
	pause.set_up_obj(PauseMenuSim.W_MENU_OBJ_2, 0x40, 0x40, 0x5C9C)
	pause.w3(PauseMenuSim.W_MENU_OBJ_2 + MenuScreenSim.OBJ_FRAME, 7)
	pause.w3(PauseMenuSim.W_MENU_OBJ_2 + MenuScreenSim.OBJ_FRAMESET_OFFSET, 4)
	pause.w3(PauseMenuSim.W_MENU_OBJ_2 + MenuScreenSim.OBJ_DURATION, 3)
	pause.sim.wJoypadPressed = WarioRam.PAD_A
	pause.handle_pause_menu_input()
	assert_eq([pause.r3(PauseMenuSim.W_PAUSE_MENU_SELECTION)] + _highlight(pause),
			[PauseMenuSim.PAUSEMENU_SAVE | PauseMenuSim.PAUSEMENUF_B_PAD_SELECT, 0x40, 0x40, 7, 0, 0, 0x5C9F])


## UpdatePauseMenu's loops (`loops`) from `selection` chosen with its frameset started, until the
## choice.
func _choose(selection: int, frameset: int) -> PauseMenuSim:
	var pause: PauseMenuSim = _pause()
	var state: int = pause.sim.wState
	pause.sim.wSubState = 3
	pause.w3(PauseMenuSim.W_PAUSE_MENU_SELECTION, selection | PauseMenuSim.PAUSEMENUF_B_PAD_SELECT)
	pause.set_up_obj(PauseMenuSim.W_MENU_OBJ_2, 0x38, 0x20, frameset)
	pause.set_up_obj(PauseMenuSim.W_MENU_OBJ_3, 0x8C, 0x20, 0x5CD4)
	while pause.sim.wSubState == 3 and pause.sim.wState == state and pause.unported.is_empty() and pause.loops < 20:
		pause.update()
	return pause


func test_the_choice_waits_for_the_highlights_frameset_to_end() -> void:
	var save: PauseMenuSim = _choose(PauseMenuSim.PAUSEMENU_SAVE, 0x5C9F)
	assert_eq([save.loops, save.sim.wSubState, save.sim.wResetDisabled], [7, PauseMenuSim.SST_PAUSE_MENU_SAVE, 1],
			"two frames of 2 loops, then the end")
	var back: PauseMenuSim = _choose(PauseMenuSim.PAUSEMENU_RETURN, 0x5CBB)
	assert_eq([back.loops, back.sim.wSubState], [7, 4], "Return: ExitPauseMenu's fade")
	var to_map: PauseMenuSim = _choose(PauseMenuSim.PAUSEMENU_TO_MAP, 0x5C77)
	assert_eq([to_map.sim.wState, to_map.sim.wSubState, to_map.r0(PauseMenuSim.W_DAY_NIGHT),
			to_map.r0(PauseMenuSim.W_TRANSITION_PARAM)], [PauseMenuSim.ST_OVERWORLD, 0, 0x80, 0xF0],
			"ReturnToMapFromLevel")
	var help: PauseMenuSim = _choose(PauseMenuSim.PAUSEMENU_ACTION_HELP, 0x5C69)
	assert_eq([help.sim.wState, help.sim.wSubState, help.unported.size()], [PauseMenuSim.ST_ACTION_HELP, 0, 0],
			"OpenActionHelp")


func test_exit_pause_menu_restores_the_level_and_returns_to_it() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 5
	pause.w3(PauseMenuSim.W3D500, 0x21)
	pause.w3(PauseMenuSim.W3D501, 0x43)
	pause.w3(PauseMenuSim.W3D280, 0x55)
	pause.w3(PauseMenuSim.W_TEMP_ANIMATED_TILES_FRAME_DURATION, 6)
	pause.w3(PauseMenuSim.W_TEMP_ANIMATED_TILES_GROUP, 2)
	pause.w0(PauseMenuSim.W_UNUSED_IS_PAUSED, 1)
	sim.wAnimatedTilesFrameCount = 3
	sim.wAnimatedTilesFrame = 2
	pause.wVirtualOAM[0] = 0x10
	pause.update()
	assert_eq([sim.wSCY, sim.wSCX, pause.r0(PauseMenuSim.W_TEMP_PALS_1), pause.r0(PauseMenuSim.W_UNUSED_IS_PAUSED),
			sim.wAnimatedTilesFrameDuration, sim.wAnimatedTilesGfx, sim.wAnimatedTilesFrameCount, sim.wAnimatedTilesFrame,
			sim.wRoomAnimatedTilesEnabled, sim.wSubState, pause.wVirtualOAM[0]], [0x21, 0x43, 0x55, 0, 6, 2, 0, 0, 1, 6, 0])
	sim.wSubState = 7
	sim.wPendingSubState = 3
	pause.update()
	assert_eq([sim.wState, sim.wSubState], [PauseMenuSim.ST_LEVEL, 3])


func test_init_save_screen_keeps_the_pause_menus_backup() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.wSubState = 9
	sim.wSCY = 5
	pause.w3(PauseMenuSim.W3D500, 0x77)
	pause.update()
	assert_eq([pause.r3(PauseMenuSim.W3D500), sim.wSCY, sim.wResetDisabled, pause.wTempBank,
			pause.r0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE), pause.r0(PauseMenuSim.W_BG_MAP_TILE_VRAM0_QUEUE + 1),
			sim.wSubState, pause.vblank_func], [0x77, 0, 1, 0x76, 0x99, 0x64, 0x0A, PauseMenuSim.VBlankFunc.SAVE_SCREEN])


## A level map whose 48 rows are known whole (blocks, the unwritten bytes, objects), all 0 but three.
func _map(with_gaps: bool = true) -> LevelCollision:
	var level := LevelCollision.new()
	level.set_rows([])
	if with_gaps:
		var gaps: Array = []
		for row: int in LevelCollision.HEIGHT:
			gaps.append("00".repeat(LevelCollision.GAP_WIDTH))
		level.set_gap_rows(gaps)
	for row: int in 48:
		var objects := PackedByteArray()
		objects.resize(0x50)
		level.object_rows.append(objects)
	level.set_block(0, 0, 0x05)
	level.set_block(47, 0xAF, 0x03)
	level.set_block(47, 0xFF, 0x02)
	return level


func test_save_level_writes_the_level_four_times_with_its_checksums_and_backs_up_the_map() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	sim.level = _map()
	sim.wram1[0] = 0x10
	sim.wram1[1] = 0x20
	sim.wram1[2] = 0x40  # copied, not summed (CalculateChecksumLong)
	sim.wram1[0x149] = 0x08
	pause.w0(PauseMenuSim.W_SAVE_COUNTER + 3, 0xFF)
	pause.w0(0xCAC9, 0x03)  # the level WRAM's last byte
	pause.wx(2, PauseMenuSim.W_TREASURES_COLLECTED + 0x10, 0x20)
	pause.w3(PauseMenuSim.W3D280 + 0x60, 0x44)  # palette 12, to wcaa1
	pause.ws(0, PauseMenuSim.S0A790, 0x31)
	sim.wResetDisabled = 1
	sim.wSubState = 0x0D
	pause.update()
	var checksum: int = 1 + 0x44 + 0x03 + 0x20 + 0x10 + 0x20
	var objects: int = 4 + 0xCA + 0x11
	for at: int in [PauseMenuSim.S0A000, PauseMenuSim.S0A800, PauseMenuSim.S0A400, PauseMenuSim.S0AC00]:
		assert_eq([pause.rs(0, at), pause.rs(0, at + 3), pause.rs(0, at + 4 + 2), pause.rs(0, at + 4 + 0xA1),
				pause.rs(0, at + 4 + 0xC9), pause.rs(0, at + 4 + 0xCA + 0x10), pause.rs(0, at + objects),
				pause.rs(0, at + objects + 2), pause.rs(0, at + objects + 0x149)],
				[0x57, 0x33, 1, 0x44, 0x03, 0x20, 0x10, 0x40, 0x08], "copy at $%04x" % at)
	for at: int in [PauseMenuSim.S_WRAM_CHECKSUM, PauseMenuSim.S_BACKUP2_WRAM_CHECKSUM_ECHO1,
			PauseMenuSim.S_BACKUP3_WRAM_CHECKSUM_ECHO2]:
		assert_eq((pause.rs(0, at) << 8) | pause.rs(0, at + 1), checksum)
	for at: int in [PauseMenuSim.S0A79D, PauseMenuSim.S0AFAD, PauseMenuSim.S0A79F, PauseMenuSim.S0A7EF]:
		assert_eq((pause.rs(0, at) << 8) | pause.rs(0, at + 1), 5 + 3 + 2, "the map's checksums")
	assert_eq([pause.rs(3, 0xA000), pause.rs(2, 0xBFAF), pause.rs(2, 0xBFFF), sim.level.block_at(63, 0xAF),
			sim.level.block_at(63, 0xFF)], [5, 3, 2, 3, -1], "the map's backup, rows 48-63 as the level keeps them")
	assert_eq([pause.r0(PauseMenuSim.W_CHECKSUM + 1), pause.rs(0, PauseMenuSim.S0A790), sim.wResetDisabled,
			pause.r0(PauseMenuSim.W_TIMER + 1), sim.wSubState, pause.vblank_func, sim.level_map_sram],
			[checksum, 0, 0, 2, 0x0E, PauseMenuSim.VBlankFunc.SAVING, LevelSim.LevelMapSram.SAVED],
			"the level's map in SRAM is the one saved")


func test_save_level_waits_for_the_map_known_whole_and_the_reset_jumps_to_init() -> void:
	var pause: PauseMenuSim = _pause()
	pause.sim.level = _map(false)
	pause.sim.wSubState = 0x0D
	pause.update()
	assert_eq([pause.sim.wSubState, pause.r0(PauseMenuSim.W_SAVE_COUNTER + 3), pause.unported.size()], [0x0D, 0, 1])
	var reset: PauseMenuSim = _pause()
	reset.sim.wSubState = PauseMenuSim.SST_RESET_AFTER_PAUSE_MENU_SAVE
	reset.update()
	assert_eq([reset.sim.wSubState, reset.unported.size(), reset.sim._init_request],
			[PauseMenuSim.SST_RESET_AFTER_PAUSE_MENU_SAVE, 0, 0], "Init follows the loop (LevelSim.init_game)")


func test_the_level_pauses_into_the_pause_menu_when_it_is_loaded() -> void:
	var sim := LevelSim.new()
	sim.load_pause_menu_data({})
	sim.wState = LevelSim.ST_LEVEL
	sim.wSubState = LevelSim.SST_UPDATE_LEVEL
	sim.wJoypadPressed = WarioRam.PAD_START
	sim.check_end_screen()
	assert_eq([sim.wState, sim.wSubState, sim.wPendingSubState, sim.pause_menu_screen.r0(PauseMenuSim.W_UNUSED_IS_PAUSED)],
			[LevelSim.ST_PAUSE_MENU, 0, LevelSim.SST_UPDATE_LEVEL, 1])
	sim.wSubState = 3
	sim.update_level()
	assert_eq([sim.wState, sim.wSubState], [LevelSim.ST_PAUSE_MENU, 3], "UpdatePauseMenu, not the stand-in")


func test_the_menu_is_drawn_with_its_counts_a_transformations_tiles_and_time_attacks_times() -> void:
	var pause: PauseMenuSim = _pause()
	var sim: LevelSim = pause.sim
	pause.w0(SaveScreenVram.W_NUM_COINS, 0x01)  # 123 coins, BCD
	pause.w0(SaveScreenVram.W_NUM_COINS + 1, 0x23)
	pause.w0(SaveScreenVram.W_NUM_MUSICAL_COINS, 4)
	pause.w0(PauseMenuSim.W_TRANSFORMATION, WarioRam.TRANSFORMATION_RAIL)
	sim.wSubState = 1
	pause.update()
	var vram := SaveScreenVram.new(pause.document)
	vram.update(pause, sim)
	assert_eq([vram.screen, vram.read_byte(0, 0x8000), vram.read_byte(0, 0x8200), vram.read_byte(0, 0x9800),
			vram.read_byte(1, 0x9C00), _at(vram, 0, 0)], ["pause_menu", 0xF9, 0xC3, 0xFF, 0x05, 0xD4],
			"the rail's tiles over the menu's start; BG map 0 cleared; the maps on BG map 1")
	assert_eq([_at(vram, 7, 15), _at(vram, 7, 16), _at(vram, 14, 15), _at(vram, 15, 16), _at(vram, 16, 15)],
			[0xA8, 0xA9, 0xA2, 0xA5, 0xA6], "4 musical coins; the coins' 1, 2, and 3, each two tiles")
	var time_attack: PauseMenuSim = _pause()
	time_attack.w0(PauseMenuSim.W_GAME_MODE_FLAGS, PauseMenuSim.MODE_TIME_ATTACK)
	time_attack.w0(PauseMenuSim.W_LEVEL, 0x10)  # the level's best time: the scores' third pair
	time_attack.w0(PauseMenuSim.W_LEVEL_TIME_ATTACK_SCORES + 4, 0x12)
	time_attack.w0(PauseMenuSim.W_LEVEL_TIME_ATTACK_SCORES + 5, 0x34)
	time_attack.w0(SaveScreenVram.W_LEVEL_TIME, 0x05)
	time_attack.w0(SaveScreenVram.W_LEVEL_TIME + 1, 0x67)
	time_attack.sim.wSubState = 1
	time_attack.update()
	vram = SaveScreenVram.new(time_attack.document)
	vram.update(time_attack, time_attack.sim)
	assert_eq([vram.read_byte(1, 0x9C00), _at(vram, 0, 0), _at(vram, 4, 2), _at(vram, 5, 2), _at(vram, 6, 2), _at(vram, 7, 3),
			_at(vram, 8, 2), _at(vram, 11, 2), _at(vram, 15, 2)], [0x07, 0xE6, 0xA2, 0xA4, 0xE6, 0xA7, 0xA8, 0xA0, 0xAE],
			"Time Attack's maps; 12:34 at (4, 2), a column left between; 05:67 at (11, 2)")
	sim.wSubState = 3
	sim.wPalFadeCounter = 0
	vram.update(pause, sim)
	assert_eq([vram.bg_palettes[0], vram.obj_palettes[0]], [0xA1, 0xB2], "the menu's palettes once it has faded in")


## BG map 1's tile at (`x`, `y`).
func _at(vram: ScreenVram, x: int, y: int) -> int:
	return vram.read_byte(0, ScreenVram.map_address(ScreenVram.BG_MAP_1, x, y))


func test_action_helps_way_back_ends_with_the_menus_init_on_the_same_ram() -> void:
	var sim := LevelSim.new()
	sim.load_action_help_data({})
	var pause: PauseMenuSim = _pause(sim)
	sim.pause_menu_screen = pause
	pause.wram = sim.screen_wram  # the LevelSim's screens share one RAM
	sim.wState = ClearSim.ST_ACTION_HELP
	sim.wSubState = 5  # ReturnToPauseMenuFromActionHelp
	sim.wSCX = 4
	sim.update_level()
	assert_eq([Array(sim.unported), sim.wState, sim.wSubState, sim.wSCX, pause.loops, pause.screen_loads[0],
			pause.r0(PauseMenuSim.W_TEMP_PALS_1)], [[], LevelSim.ST_PAUSE_MENU, 2, 0, 1, ["pause_menu"], 0xA1],
			"the pause menu's state, its init run (InitPauseMenu_SkipBackupVRAM), its palettes in the shared RAM")


func test_the_save_after_the_perfect_screen_runs_the_save_screens_steps_then_resets() -> void:
	var pause: PauseMenuSim = _pause()
	pause.sim.wSubState = PauseMenuSim.SST_PAUSE_28 + 3  # FillSaveScreenBar, as at $1b
	pause.w0(PauseMenuSim.W_CEE4, 0)
	pause.update()
	var bar: PauseMenuSim = _pause()
	bar.sim.wSubState = 0x1B
	bar.w0(PauseMenuSim.W_CEE4, 0)
	bar.update()
	assert_eq([pause.sim.wSubState - PauseMenuSim.SST_PAUSE_28, pause.unported.size()],
			[bar.sim.wSubState - 0x18, 0], "the same step as the map's save")
	var reset: PauseMenuSim = _pause()
	reset.sim.wSubState = PauseMenuSim.SST_RESET_AFTER_SAVE
	reset.update()
	assert_eq([reset.sim.wSubState, reset.unported.size(), reset.sim._init_request],
			[PauseMenuSim.SST_RESET_AFTER_SAVE, 0, 0], "ResetAfterSave: Init follows the loop")
