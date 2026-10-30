extends TestCase
## The Perfect screen (PerfectSim, WL3-052) on invented data (no ROM bytes): InitPerfectScreen's set-up,
## the fades with wUnused_c186, the first update drawing after the init's sprites, SlowFadeInScreen every
## 8th loop and the palette cycle (its wait, its sets, its wrap), the way to the pause menu outside Time
## Attack, LevelSim's routing with DebugReset, and the drawing (PerfectVram).

const OAM_PERFECT: String = "37:5710"


func _perfect(sim: LevelSim = LevelSim.new()) -> PerfectSim:
	var perfect := PerfectSim.new(sim)
	var frames: Array = []  # one entry a frame: (-16, -8), tile = frame
	for index: int in 9:
		frames.append([[-16, -8, index, 0]])
	perfect.load_data({"framesets": {"37:5848": [[1, 2], [2, 2]]}, "oam_tables": {OAM_PERFECT: frames},
		"gfx": {"palettes": {"37:4173": "01".repeat(0x28) + "0a".repeat(0x18), "37:41b3": "0b".repeat(0x18),
			"37:41cb": "0c".repeat(0x18), "37:41e3": "0d".repeat(0x18), "37:41fb": "02".repeat(0x40)},
			"compressed": {"37:423b": "11".repeat(0x1800), "37:5417": "14".repeat(0x200), "37:55b5": "05".repeat(0x200)}}})
	return perfect


func _loop(perfect: PerfectSim, loops: int = 1) -> void:
	for loop: int in loops:
		perfect.update()
		perfect.sim.wGlobalCounter = (perfect.sim.wGlobalCounter + 1) & 0xFF


func _init_screen(perfect: PerfectSim) -> void:
	perfect.sim.wSubState = 1
	perfect.update()


## Palette 5's first byte in wTempPals1 (the cycle's sets: $0a, $0b, $0c, $0d).
func _cycled(perfect: PerfectSim) -> int:
	return perfect.r0(PerfectSim.W_TEMP_PALS_1 + PerfectSim.CYCLED_PALS)


func test_init_sets_up_the_screen_and_the_object_and_keeps_its_sprites() -> void:
	var perfect: PerfectSim = _perfect()
	var sim: LevelSim = perfect.sim
	sim.wSCX = 4
	perfect.w0(PerfectSim.W_TIMER, 9)
	perfect.w3(PerfectSim.W_GAME_OVER_WARIO_VAR, 3)
	_init_screen(perfect)
	assert_eq([sim.wSubState, sim.wSCX, sim.wSCY, perfect.r0(PerfectSim.W_TIMER), perfect.r3(PerfectSim.W_GAME_OVER_WARIO_VAR),
			perfect.vblank_func, perfect.screen_loads], [2, 0, 0, 0, 0, PerfectSim.VBLANK_PERFECT, [["perfect"]]])
	var obj: int = PerfectSim.W_MENU_OBJ_1
	assert_eq([perfect.r3(obj), perfect.r3(obj + 1), perfect.r3(obj + MenuScreenSim.OBJ_FRAME),
			perfect.r3(obj + MenuScreenSim.OBJ_FRAMESET_PTR + 1)], [0x23, 0x2B, 1, 0x48], "Frameset_dd848, animated")
	assert_eq([perfect.r0(PerfectSim.W_TEMP_PALS_1), perfect.r0(PerfectSim.W_TEMP_PALS_1 + 0x3F),
			perfect.r0(PerfectSim.W_TEMP_PALS_2)], [0x01, 0x0A, 0x02], "LoadPerfectPals")
	assert_eq([perfect.wVirtualOAMByteSize, perfect.wVirtualOAM.slice(0, 4)], [4, PackedByteArray([0x23, 0x2B, 1, 0])],
			"no ClearUnusedVirtualOAM after")


func test_the_fades_are_fast_and_keep_w_unused_c186() -> void:
	var perfect: PerfectSim = _perfect()
	var sim: LevelSim = perfect.sim
	for substate: int in [0, 2]:
		sim.wSubState = substate
		_loop(perfect)
		assert_eq([perfect.r0(PerfectSim.W_UNUSED_C186), sim.wFadeSpeed, sim.wPalFadeCounter], [1, 2, 1], "set up")
		var loops: int = 1
		while sim.wSubState == substate and loops < 100:
			_loop(perfect)
			loops += 1
		assert_eq([loops, perfect.r0(PerfectSim.W_UNUSED_C186), sim.wFadeSpeed], [10, 0, 0], "FADE_SPEED_FAST, cleared")


func test_the_first_update_draws_after_the_inits_sprites() -> void:
	var perfect: PerfectSim = _perfect()
	var sim: LevelSim = perfect.sim
	_init_screen(perfect)
	sim.wSubState = 3
	sim.wGlobalCounter = 1
	perfect.update()
	assert_eq([perfect.wVirtualOAMByteSize, perfect.wVirtualOAM.slice(0, 8)],
			[0, PackedByteArray([0x23, 0x2B, 1, 0, 0x23, 0x2B, 1, 0])])


func test_the_screen_fades_in_every_8th_loop_and_cycles_its_palettes() -> void:
	var perfect: PerfectSim = _perfect()
	var sim: LevelSim = perfect.sim
	_init_screen(perfect)
	sim.wSubState = 3
	sim.wGlobalCounter = 0
	_loop(perfect)
	assert_eq([sim.wPalFadeCounter, perfect.r0(PerfectSim.W_UNUSED_C186)], [1, 1], "SlowFadeInScreen's set-up")
	_loop(perfect, 7)
	assert_eq(sim.wPalFadeCounter, 1, "only every 8th loop")
	_loop(perfect, 248)
	assert_eq([sim.wPalFadeCounter, _cycled(perfect)], [32, 0x0A])
	_loop(perfect)
	assert_eq([sim.wSubState, sim.wPalFadeCounter, perfect.r0(PerfectSim.W_UNUSED_C186),
			perfect.r3(PerfectSim.W_GAME_OVER_WARIO_VAR), perfect.r0(PerfectSim.W_TIMER), _cycled(perfect)],
			[3, 0, 0, 1, 240, 0x0B], "the 33rd step ends it: the sub-state put back, the cycle's first set and its wait")
	var step: Array = perfect.screen_loads[-1]
	assert_eq([step[0], step[1][PerfectSim.CYCLED_PALS]], ["fade_in_step", 0x0A], "that step toward the set it saw")
	_loop(perfect, 239)
	assert_eq([perfect.r0(PerfectSim.W_TIMER), sim.wPalFadeCounter], [1, 0], "the wait")
	_loop(perfect)
	assert_eq([perfect.r0(PerfectSim.W_TIMER), sim.wPalFadeCounter], [0, 1], "its last loop starts the next fade")
	var sets: Array = []
	var loops: int = 0
	while sets.size() < 5 and loops < 3000:
		var cycle: int = perfect.r3(PerfectSim.W_GAME_OVER_WARIO_VAR)
		_loop(perfect)
		loops += 1
		if perfect.r3(PerfectSim.W_GAME_OVER_WARIO_VAR) != cycle:
			sets.append([perfect.r3(PerfectSim.W_GAME_OVER_WARIO_VAR), _cycled(perfect)])
	assert_eq(sets, [[2, 0x0C], [3, 0x0D], [4, 0x0C], [5, 0x0B], [0, 0x0A]], "then Pals_dc173's own, from 0")


func test_a_button_outside_time_attack_takes_the_pause_menu() -> void:
	var perfect: PerfectSim = _perfect()
	var sim: LevelSim = perfect.sim
	_init_screen(perfect)
	sim.wSubState = 3
	sim.wGlobalCounter = 0
	sim.wState = LevelSim.ST_PERFECT
	perfect.w0(PerfectSim.W_GAME_MODE_FLAGS, PerfectSim.MODE_TIME_ATTACK | 0x01)
	sim.wJoypadPressed = WarioRam.PAD_START
	_loop(perfect)
	assert_eq([sim.wState, sim.wSubState, sim.wPalFadeCounter], [LevelSim.ST_PERFECT, 3, 1], "in Time Attack: ignored")
	perfect.w0(PerfectSim.W_GAME_MODE_FLAGS, 0x01)
	sim.wJoypadPressed = 0
	_loop(perfect)
	assert_eq(sim.wSubState, 3, "no button")
	sim.wJoypadPressed = WarioRam.PAD_B
	_loop(perfect)
	assert_eq([sim.wState, sim.wSubState, sim.wPalFadeCounter, sim.wFadeSpeed, perfect.r0(PerfectSim.W_UNUSED_C186),
			perfect.r0(PerfectSim.W_GAME_MODE_FLAGS)], [LevelSim.ST_PAUSE_MENU, PerfectSim.SST_PAUSE_28, 0, 0, 0, 0x03],
			"Time Attack opened")


func test_level_sim_runs_the_screen_in_its_state_and_debug_reset_jumps_to_init() -> void:
	var sim := LevelSim.new()
	var perfect: PerfectSim = _perfect(null)
	sim.wState = LevelSim.ST_PERFECT
	sim.update_level()
	assert_eq(Array(sim.unported), ["wState $0d"], "not loaded: named")
	sim.perfect = perfect
	sim.wSubState = 1
	sim.update_level()
	assert_eq([sim.wSubState, perfect.loops, Array(sim.unported)], [2, 1, []])
	for substate: int in [4, 0x0C]:
		sim.unported.clear()
		sim.wSubState = substate
		sim.update_level()
		assert_true(sim.unported.size() == 1 and "Init" in sim.unported[0], "DebugReset: Init (here without a save's SRAM)")
	sim.unported.clear()
	sim.wSubState = 0x0D
	sim.update_level()
	assert_eq(Array(sim.unported), ["_PerfectStateTable sub-state 13 (past the table)"])


func test_the_screen_is_drawn_from_its_graphics_and_its_fades_in_step() -> void:
	var perfect: PerfectSim = _perfect()
	var vram := PerfectVram.new(perfect.document)
	_init_screen(perfect)
	vram.update(perfect)
	assert_eq([vram.read_byte(0, 0x8000), vram.read_byte(0, 0x97FF), vram.read_byte(0, 0x9800), vram.read_byte(1, 0x9800),
			vram.read_byte(0, 0x9A00), vram.read_byte(1, 0x9A00), vram.screen], [0x11, 0x11, 0x14, 0x05, 0x7F, 0, "perfect"],
			"PerfectGfx; the maps over FillBGMap0_With7f")
	assert_eq([vram.bg_palettes[0], vram.bg_palettes[0x28], vram.obj_palettes[0]], [0x01, 0x0A, 0x02])
	var before: PackedByteArray = vram.bg_palettes.duplicate()
	var target: PackedByteArray = perfect.wram[0].slice(0, 0x80)
	target[0x28] = 0x05
	perfect.screen_loads = [["fade_in_step", target]]
	perfect.w0(PerfectSim.W_TEMP_PALS_1 + 0x28, 0x0D)
	vram.update(perfect)
	assert_eq(vram.bg_palettes, ScreenVram.fade_in_step(before, target.slice(0, 0x40)),
			"a step toward the target the step saw, not the one after")
	assert_true(vram.bg_palettes != ScreenVram.fade_in_step(before, perfect.wram[0].slice(0, 0x40)))
