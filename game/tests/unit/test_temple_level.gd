extends TestCase
## The way out of the hidden figure's fight (LevelSim, the Temple) on invented values (no ROM bytes):
## UpdateLevel.check_end_screen's game over and epilogue (the transition the map takes and
## wGameModeFlags), a level cleared in Time Attack, and EpilogueStateTable's fade and way to the map.
## The fight itself is checked against map-temple-fight-invented (make wario-parity).


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	for bank: int in [0, 3]:
		var bytes := PackedByteArray()
		bytes.resize(0x1000)
		sim.screen_wram[bank] = bytes
	sim.wState = LevelSim.ST_LEVEL
	return sim


func _end(sim: LevelSim) -> Array:
	sim.check_end_screen()
	return [sim.wState, sim.wSubState, sim.read_level_ram(LevelSim.W_TRANSITION_PARAM),
			sim.read_level_ram(LevelSim.W_GAME_MODE_FLAGS)]


func test_the_fight_lost_sets_the_game_over_transition_and_fought() -> void:
	var sim: LevelSim = _sim()
	sim.wLevelEndScreen = LevelSim.LVLEND_GAME_OVER
	sim.wWaterCurrent = 3
	sim.wSwimmingDirectionInput = 1
	assert_eq(_end(sim), [LevelSim.ST_EPILOGUE, 0, LevelSim.TRANSITION_GAME_OVER, LevelSim.MODE_FOUGHT_A_HIDDEN_FIGURE])
	assert_eq([sim.wWaterCurrent, sim.wSwimmingDirectionInput, sim.wResetDisabled], [0, 0, 1], "cleared as any level's end")


func test_the_fight_won_clears_the_game_and_with_every_treasure_opens_time_attack() -> void:
	var sim: LevelSim = _sim()
	sim.wLevelEndScreen = LevelSim.LVLEND_EPILOGUE
	sim.wNumCollectedTreasures = 0x0100  # BCD: all 100
	assert_eq(_end(sim), [LevelSim.ST_EPILOGUE, 0, LevelSim.TRANSITION_EPILOGUE_PERFECT,
			LevelSim.MODE_GAME_CLEARED | LevelSim.MODE_TIME_ATTACK | LevelSim.MODE_FOUGHT_A_HIDDEN_FIGURE])
	sim = _sim()
	sim.wLevelEndScreen = LevelSim.LVLEND_EPILOGUE
	sim.wNumCollectedTreasures = 0x0099
	assert_eq(_end(sim), [LevelSim.ST_EPILOGUE, 0, LevelSim.TRANSITION_EPILOGUE_NOT_PERFECT,
			LevelSim.MODE_GAME_CLEARED | LevelSim.MODE_FOUGHT_A_HIDDEN_FIGURE])


func test_a_level_cleared_in_time_attack_goes_to_its_clear_screen() -> void:
	var sim: LevelSim = _sim()
	sim.wLevelEndScreen = 1  # LVLEND_GREY_TREASURE
	sim.write_level_ram(LevelSim.W_GAME_MODE_FLAGS, LevelSim.MODE_TIME_ATTACK)
	assert_eq(_end(sim).slice(0, 2), [LevelSim.ST_CLEAR, LevelSim.SST_CLEAR_TIME_ATTACK])


func test_the_epilogue_state_fades_every_fourth_loop_then_starts_the_map() -> void:
	var sim: LevelSim = _sim()
	sim.wState = LevelSim.ST_EPILOGUE
	sim.wSubState = 0
	sim.wDayNight = 0x01
	sim.wAnimatedTilesFrameCount = 5
	sim.screen_wram[3][LevelSim.W3D50D - 0xD000] = 9
	for loop: int in 131:
		sim.wGlobalCounter = (loop + 1) & 0xFF
		sim.epilogue_state()
	assert_eq(sim.wSubState, 0, "32 fade steps on loops 4 to 128")
	sim.wGlobalCounter = 132
	sim.epilogue_state()
	assert_eq(sim.wSubState, 1, "the 33rd ends the fade")
	sim.epilogue_state()
	assert_eq([sim.wState, sim.wSubState, sim.wDayNight, sim.wAnimatedTilesFrameCount,
			sim.screen_wram[3][LevelSim.W3D50D - 0xD000]], [LevelSim.ST_OVERWORLD, 0, 0x81, 0, 0])
