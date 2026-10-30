extends TestCase
## The room's animation on invented data (no ROM bytes): InitRoomAnimatedTiles/Pals from a room
## header, the loops' counting, late loops replayed, transitions stopping the palettes, the level's
## end, the pause stand-in, golf's way out and back, and RoomSheets swapping tiles $70-$77 and the
## palettes.

func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.room_animation = {
		"animated_tiles_groups": [[0, 0], [3, 1]],
		"pal_cycles": [{"duration": 0, "palettes": [0, 0, 0, 0, 0, 0, 0, 0]},
				{"duration": 4, "palettes": [5, 6, 7, 8, 9, 10, 11, 12]}],
	}
	sim.load_room_camera({"animated_tiles_group": 1, "pal_cycle": 1})
	sim.wRoomAnimatedTilesEnabled = 1
	sim.wRoomAnimatedPalsEnabled = 1
	return sim


func test_animated_tiles_step_every_duration_loops_through_four_frames() -> void:
	var sim: LevelSim = _sim()
	assert_eq([sim.wAnimatedTilesFrameDuration, sim.wAnimatedTilesGfx], [3, 1])
	assert_eq(sim.shown_animated_tiles(), [-1, 0], "the room's own tiles until the first step")
	var frames: Array = []
	for loop: int in 12:
		sim.update_room_animations()
		frames.append(sim.wAnimatedTilesFrame)
	assert_eq(frames, [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 0])
	assert_eq(sim.shown_animated_tiles(), [1, 0])


func test_the_palette_cycle_starts_half_way_and_shows_its_entries() -> void:
	var sim: LevelSim = _sim()
	assert_eq([sim.wRoomPalCycleDuration, sim.wRoomPalCycleCounter, sim.shown_room_pals()], [4, 2, -1])
	sim.update_room_animated_pals()
	assert_eq(sim.shown_room_pals(), -1)
	sim.update_room_animated_pals()
	assert_eq([sim.wRoomPalCycleIndex, sim.shown_room_pals()], [1, 6], "two loops in: the second entry")


func test_late_loops_skip_the_animation_and_count_nothing() -> void:
	var sim: LevelSim = _sim()
	sim.animation_replay = true
	sim.animation_queue = [[0, 130], [1, 140], [0, 10], [1, 10]]
	sim.update_room_animations()
	assert_eq([sim.wAnimatedTilesFrameCount, sim.wRoomPalCycleCounter], [0, 2], "LY 130 and 140: too late")
	sim.update_room_animations()
	assert_eq([sim.wAnimatedTilesFrameCount, sim.wRoomPalCycleCounter], [1, 3])
	sim.update_room_animations()
	assert_eq(sim.animation_mismatches.size(), 2, "calls the original did not make")


func test_a_room_transition_stops_the_palette_cycle() -> void:
	var sim: LevelSim = _sim()
	sim.wRoomTransitionParam = 0x04
	sim.trigger_room_transition()
	assert_eq([sim.wRoomPalCycleDuration, sim.wRoomAnimatedPalsEnabled], [0, 0])


func test_the_level_ends_once_the_end_screen_is_named_and_the_scene_is_over() -> void:
	var sim: LevelSim = _sim()
	sim.wState = ObjectInteractions.ST_LEVEL
	sim.wLevelEndScreen = 0x81
	sim.check_end_screen()
	assert_eq(sim.wState, ObjectInteractions.ST_LEVEL, "bit 7: the treasure scene goes on")
	sim.wLevelEndScreen = 0x01
	sim.check_end_screen()
	assert_eq([sim.wState, sim.wSubState, sim.wRoomAnimatedTilesEnabled, sim.wRoomAnimatedPalsEnabled],
			[LevelSim.ST_CLEAR, 0, 0, 0])


func test_start_pauses_and_start_again_goes_on() -> void:
	var sim: LevelSim = _sim()
	sim.wState = ObjectInteractions.ST_LEVEL
	sim.wSubState = LevelSim.SST_UPDATE_LEVEL
	sim.wJoypadPressed = WarioRam.PAD_START
	sim.check_end_screen()
	assert_eq([sim.wState, sim.wRoomAnimatedPalsEnabled], [LevelSim.ST_PAUSE_MENU, 0])
	sim.wJoypadPressed = 0
	sim.update_level()
	assert_eq(sim.wState, LevelSim.ST_PAUSE_MENU)
	sim.wJoypadPressed = WarioRam.PAD_START
	sim.update_level()
	assert_eq([sim.wState, sim.wSubState], [ObjectInteractions.ST_LEVEL, LevelSim.SST_UPDATE_LEVEL])


func _enter_golf(sim: LevelSim) -> void:
	sim.wState = ObjectInteractions.ST_LEVEL
	sim.wSubState = LevelSim.SST_START_ROOM_FROM_TRANSITION
	sim.wRoomTransitionParam = 0x63  # golf, through a door, the objects reloaded
	sim.wNumCoins = 0x57
	sim.update_level()


func _golf_loops(sim: LevelSim) -> int:
	var loops: int = 0
	while sim.wState == LevelSim.ST_GOLF and loops < 1000:
		sim.update_level()
		loops += 1
	return loops


func test_golf_keeps_the_rooms_tiles_and_comes_back_through_the_door() -> void:
	var sim: LevelSim = _sim()
	_enter_golf(sim)
	assert_eq([sim.wState, sim.wSubState, sim.wPendingSubState],
			[LevelSim.ST_GOLF, 0, LevelSim.SST_START_ROOM_FROM_TRANSITION])
	for loop: int in 34:
		sim.update_level()
	assert_eq([sim.wSubState, sim.wRoomAnimatedTilesEnabled], [LevelSim.SST_GOLF_LOBBY, 0],
			"the fade to white, then InitGolfLobby stops the room's tiles")
	sim.wAnimatedTilesFrameDuration = 9
	sim.wAnimatedTilesFrame = 2
	assert_eq(_golf_loops(sim), 1 + 33 + 1, "natively Wario leaves the lobby at once")
	assert_eq([sim.wState, sim.wSubState, sim.wRoomTransitionParam, sim.wNumCoins, sim.wIsMinigameCleared],
			[ObjectInteractions.ST_LEVEL, LevelSim.SST_START_ROOM_FROM_TRANSITION, 0x62, 0x57, 0])
	assert_eq([sim.wAnimatedTilesFrameDuration, sim.wAnimatedTilesGfx, sim.wAnimatedTilesFrame,
			sim.wAnimatedTilesFrameCount, sim.wRoomAnimatedTilesEnabled], [3, 1, 0, 1, 1],
			"the room's tiles from their first frame (and this loop's step)")


func test_a_replayed_golf_visit_lasts_its_loops_and_leaves_its_outcome() -> void:
	var sim: LevelSim = _sim()
	sim.golf_replay = true
	sim.golf_queue = [[100, 0x37, 1]]
	_enter_golf(sim)
	assert_eq(_golf_loops(sim), 100)
	assert_eq([sim.wState, sim.wNumCoins, sim.wIsMinigameCleared, sim.golf_queue],
			[ObjectInteractions.ST_LEVEL, 0x37, 1, []])
	_enter_golf(sim)
	assert_eq(sim.unported, PackedStringArray(["the Golf minigame (not ported) without a count of its loops to replay"]))


func test_room_sheets_swap_the_animated_tiles_and_the_palettes() -> void:
	var tiles := PackedByteArray()
	tiles.resize(0x200)
	tiles.fill(0)
	tiles[0] = 0x70  # block 0, top-left tile: $70
	var attributes := PackedByteArray()
	attributes.resize(0x200)
	attributes[0] = 0x08  # VRAM bank 1, palette 0
	var special := PackedByteArray()
	special.resize(0x800)
	var gfx := PackedByteArray()
	gfx.resize(0x200)
	gfx[0x80] = 0x80  # frame 1, tile $70: colour 1 in its top-left pixel
	var palettes: Array = []
	for p: int in 8:
		palettes.append([[0, 0, 0], [31, 0, 0], [0, 31, 0], [0, 0, 31]])
	var green: Array = []
	for p: int in 8:
		green.append([[0, 0, 0], [0, 31, 0], [0, 31, 0], [0, 31, 0]])
	var sheets: RoomSheets = RoomSheets.from_document({"block_tiles": tiles.hex_encode(),
			"block_attributes": attributes.hex_encode(), "main_tiles": special.hex_encode(),
			"special_tiles": special.hex_encode(), "palettes": palettes},
			{"animated_tiles_gfx": {"0": gfx.hex_encode()}, "room_pals": {"4": green}})
	assert_eq(sheets.sheet(-1, 0, -1, false).get_pixel(0, 0), Color8(0, 0, 0), "the room's own tile")
	assert_eq(sheets.sheet(0, 1, -1, false).get_pixel(0, 0), Color8(255, 0, 0), "frame 1's")
	assert_eq(sheets.sheet(0, 1, 4, false).get_pixel(0, 0), Color8(0, 255, 0), "in RoomPals entry 4")
