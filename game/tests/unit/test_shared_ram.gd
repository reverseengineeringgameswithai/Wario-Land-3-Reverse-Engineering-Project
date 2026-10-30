extends TestCase
## The level and the screens as one RAM (WL3-052): the LevelSim's shared variables kept in step with the
## screens' WRAM around a screen loop, the screens' own WRAM0 variables as bytes, the virtual OAM handed
## from screen to screen, the level entered from the map (FastFadeToWhite, InitLevel, SlowFadeFromWhite)
## with its room animation set up (or resumed from a save, WL3-056), and the level bytes the port keeps
## only in that RAM. Invented data.

const FLOOR_ROW: int = 10


func _tables() -> WarioTables:
	var walk: Array = []
	var jump: Array = []
	for i: int in 0x1C:
		walk.append(1)
	for i: int in 0x28:
		jump.append(-1 if i < 0x18 else 1)
	return WarioTables.from_document({
		"walk_vel_table": {"steps": walk},
		"jump_vel_tables": [{"id": 2, "steps": jump}],
		"framesets": {"4252": {"pairs": [[0, 9]]}, "425f": {"pairs": [[0, 9]]},
				"49b4": {"pairs": [[0, 3]]}, "49c5": {"pairs": [[0, 3]]}},
	})


## One room (animated tiles group 1); Wario starts at (40, 160) on the floor.
func _level() -> LevelCollision:
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		row.fill(1 if y == FLOOR_ROW else 0)
		rows.append(row.hex_encode())
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	return LevelCollision.from_document({
		"block_rows": rows,
		"rooms": [{"level_room_id": 0, "handlers": handlers,
				"fields": {"camera_config": 0x18, "animated_tiles_group": 1, "pal_cycle": 1}}],
		"start": {"level_room_id": 0, "wario_x": 40, "wario_y": 160},
	})


## A LevelSim in a level with the clear screen, the map, and its save screen loaded (no data).
func _sim(loader: Callable = Callable()) -> LevelSim:
	var sim: LevelSim = LevelRunner.start(_tables(), _level(), {}, loader)
	sim.room_animation = {"animated_tiles_groups": [[0, 0], [2, 0]], "pal_cycles": [{"duration": 0}, {"duration": 6}]}
	sim.load_clear_data({})
	sim.load_overworld_data({"banks": {}})
	sim.load_pause_menu_data({})
	return sim


func test_the_level_s_variables_and_the_screens_ram_stay_in_step() -> void:
	var sim: LevelSim = _sim()
	sim.wNumCoins = 0x0123
	sim.wLevel = 0x0D
	sim.screen_wram_in(sim.overworld)
	assert_eq([sim.overworld.r0(0xCA04), sim.overworld.r0(0xCA05), sim.overworld.r0(0xCA06)], [0x01, 0x23, 0x0D],
			"the level's values as the map's bytes, big-endian")
	sim.overworld.w0(0xCA06, 0x15)  # the map selects a level (SelectLevel writes wLevel)
	sim.wDayNight = 1  # a screen through the LevelSim
	sim.screen_wram_out()
	assert_eq([sim.wLevel, sim.overworld.r0(0xCA3B)], [0x15, 1], "each change reaches the other side")
	sim.wNumCoins = 0x0124
	sim.screen_wram_in(sim.clear)
	assert_eq(sim.clear.r0(0xCA05), 0x24, "only what changed is written again")


func test_the_screens_share_their_wram0_variables_and_the_virtual_oam() -> void:
	var sim: LevelSim = _sim()
	sim.clear.wTransitionParam = 0xFF
	sim.clear.wGameModeFlags = 0x80
	assert_eq([sim.overworld.wTransitionParam, sim.pause_menu_screen.r0(0xCA3D)], [0xFF, 0x80])
	sim.pause_menu_screen.wTempBank = 0x21
	assert_eq(sim.overworld.wTempBank, 0x21, "wTempBank is one byte")
	sim.hand_over_oam(sim.clear)
	sim.clear.wVirtualOAM[0] = 0x50
	sim.clear.wVirtualOAMByteSize = 4
	sim.hand_over_oam(sim.overworld)
	assert_eq([sim.overworld.wVirtualOAM[0], sim.overworld.wVirtualOAMByteSize], [0x50, 4], "the map draws on")


func test_without_the_sync_the_level_writes_nothing() -> void:
	var sim: LevelSim = _sim()
	sim.sync_screen_wram = false
	sim.wLevel = 0x0D
	sim.screen_wram_in(sim.overworld)
	assert_eq(sim.overworld.r0(0xCA06), 0, "parity checks that load each loop from a trace keep it off")


func test_the_level_start_sets_up_the_room_animation_after_its_clears() -> void:
	var sim: LevelSim = _sim()
	sim.start_level_with_camera(0, 40, 160, _level().room_fields[0])
	assert_eq([sim.wAnimatedTilesGroup, sim.wAnimatedTilesFrameDuration, sim.wRoomPalCycleDuration], [1, 2, 6],
			"StartRoom_FromLevelStart clears them, then LoadRoom sets them up")


func test_entering_a_level_from_the_map_fades_inits_it_and_fades_in() -> void:
	var asked: Array = []
	var sim: LevelSim = _sim(func(level: int) -> LevelCollision:
		asked.append(level)
		return _level())
	sim.wWarioXPos = 0x200
	for address: int in [0xA000, 0xA003, 0xA800, 0xA803, 0xA004]:
		sim.pause_menu_screen.ws(0, address, 0x11)
	sim.write_level_ram(LevelSim.W_TEMP_LEVEL_ROOM_ID, 3)
	sim.wState = LevelSim.ST_LEVEL
	sim.wSubState = LevelSim.SST_FADE_INTO_LEVEL
	sim.wLevel = 0x2D
	var loops: Array = [0, 0, 0]
	while sim.wSubState != LevelSim.SST_UPDATE_LEVEL and loops[0] + loops[1] + loops[2] < 200:
		loops[sim.wSubState] += 1
		sim.update_level()
	assert_eq(loops, [33, 1, 33], "FastFadeToWhite, InitLevel, SlowFadeFromWhite (slow fades)")
	assert_eq(asked, [0x2D], "the level wLevel names")
	assert_eq([sim.wWarioXPos, sim.wWarioYPos, sim.wRoomAnimatedTilesEnabled], [40, 160, 1])
	assert_eq([sim.pause_menu_screen.rs(0, 0xA000), sim.pause_menu_screen.rs(0, 0xA803),
			sim.pause_menu_screen.rs(0, 0xA004)], [0, 0, 0x11], "four bytes at $a000 and $a800 cleared")
	assert_eq(sim.overworld.r0(LevelSim.W_TEMP_LEVEL_ROOM_ID), 0, "a level started, not resumed")


func test_a_level_not_extracted_or_resumed_from_a_save_is_not_entered() -> void:
	var sim: LevelSim = _sim(func(_level: int) -> LevelCollision: return null)
	sim.wState = LevelSim.ST_LEVEL
	sim.wSubState = LevelSim.SST_INIT_LEVEL
	sim.update_level()
	assert_eq([sim.wSubState, Array(sim.unported)], [LevelSim.SST_INIT_LEVEL, ["InitLevel: level $00 not loaded"]])
	sim = _sim(func(_level: int) -> LevelCollision: return _level())
	sim.wState = LevelSim.ST_LEVEL
	sim.wSubState = LevelSim.SST_INIT_LEVEL
	sim.wceef = 0x04
	sim.update_level()
	assert_eq(Array(sim.unported), ["InitLevel: a level resumed from a save (the save's SRAM not given)"])


func test_a_level_resumed_from_a_save_starts_as_the_save_left_it() -> void:
	var sim: LevelSim = _sim(func(_level: int) -> LevelCollision: return _level())
	var banks: Array = []  # the save's SRAM: banks 1 and 2 the level map, the floor two rows lower
	for bank: int in 4:
		var bytes := PackedByteArray()
		bytes.resize(0x2000)
		banks.append(bytes)
	for column: int in LevelCollision.WIDTH:
		banks[1][(FLOOR_ROW + 2) * 0x100 + column] = 1
	banks[1][(FLOOR_ROW + 2) * 0x100 + 0xA0] = 0x55  # a byte the decompressors never write
	banks[1][3 * 0x100 + 0xB0] = 0x10  # an object's nibble
	banks[2][(40 - 32) * 0x100 + 7] = 0x22  # row 40, in bank 2
	sim.loaded_sram = banks
	sim.write_level_ram(LevelSim.W_TEMP_LEVEL_ROOM_ID, 0)
	sim.wWarioXPos = 0x0150
	sim.wWarioYPos = 0x00C0
	sim.wDirection = WarioRam.DIRECTION_LEFT
	sim.wCameraSCY = 0x0134  # in a room with transitions the resumed camera keeps its Y and its limit
	sim.wCameraRoomYScrollLimit = 0
	sim.wState = LevelSim.ST_LEVEL
	sim.wSubState = LevelSim.SST_INIT_LEVEL
	sim.wceef = 0x14
	sim.update_level()
	var level_notes: Array = Array(sim.unported).filter(func(note: String) -> bool: return not note.begins_with("ROM bank"))
	assert_eq([level_notes, sim.wSubState, sim.wceef], [[], LevelSim.SST_SLOW_FADE_FROM_WHITE, 0],
			"entered (the map's treasure data is not given here)")
	assert_eq([sim.wWarioXPos, sim.wWarioYPos, sim.wDirection], [0x0150, 0x00C0, WarioRam.DIRECTION_LEFT],
			"Wario where the save left him, not at the level's start")
	assert_eq([sim.level.block_at(FLOOR_ROW + 2, 5), sim.level.block_at(FLOOR_ROW, 5), sim.level.block_at(FLOOR_ROW + 2, 0xA0),
			sim.level.block_at(3, 0xB0), sim.level.block_at(40, 7)], [1, 0, 0x55, 0x10, 0x22], "the save's map from SRAM")
	assert_eq([sim.wCameraSCY, sim.wSCY, sim.wIsDMATransferPending, sim.wRoomAnimatedTilesEnabled, sim.wAnimatedTilesGroup],
			[0x0134, 0x34, 1, 1, 1], "the camera's Y kept, Wario's tiles reloaded, the room's animation")
