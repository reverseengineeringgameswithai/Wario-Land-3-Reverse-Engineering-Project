extends TestCase
## The North side's scene after the hidden figure's fight (OverworldNorthEpilogue, WL3-052) on invented
## data (no ROM bytes): Func_b71fc's hard shake, a Func_15868e riser's spawn and path, and
## NOWFunc_Prologue's first and last steps and its sound's repeat. The scene itself is checked against
## an invented save's movie (make wario-parity).

const EMPTY_BANK_SIZE: int = 0x4000


## The map with bank $56 of zeros but for `bank_56` bytes at addresses.
func _map(bank_56: Dictionary = {}) -> OverworldSim:
	var map := OverworldSim.new(LevelSim.new())
	var bytes := PackedByteArray()
	bytes.resize(EMPTY_BANK_SIZE)
	for address: int in bank_56:
		bytes[address - 0x4000] = int(bank_56[address])
	map.load_data({"banks": {"56": bytes.hex_encode()}})
	return map


func test_the_hard_shake_starts_on_the_soft_ones_frame_1_and_ends_on_its_own_frame_11() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W_OW_UI_OBJ_1_Y_COORD, 0x04)  # .Func_b723f
	map.w2(OverworldSim.W_OW_UI_OBJ_1_FRAME, 0x10)  # .Func_b72e8: back to frame 1 this loop
	var scrolls: Array = []
	var loops: int = 0
	while map.r2(OverworldSim.W_OW_UI_OBJ_1_Y_COORD) != 0 and loops < 20:
		map.func_b71fc()
		scrolls.append(map.sim.wSCY)
		loops += 1
	assert_eq(scrolls, [0, 0xFC, 0xFC, 0xFC, 0xFC, 0, 0, 0, 0], "4 up, 3 loops, 4 down, 3 loops")
	assert_eq([map.r2(OverworldSim.W_OW_UI_OBJ_1_FRAME), map.r2(OverworldSim.W_OW_UI_OBJ_1_ATTRIBUTES)], [0, 0])
	assert_eq(Array(map.unported), [])


func test_a_soft_shake_moves_wscy_a_pixel_every_other_loop_round_16_frames() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W_OW_UI_OBJ_1_Y_COORD, 0x01)  # .Func_b721f
	var scrolls: Array = []
	for loop: int in 18:
		map.func_b71fc()
		scrolls.append(map.sim.wSCY)
	assert_eq(scrolls, [0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF])
	assert_eq([map.r2(OverworldSim.W_OW_UI_OBJ_1_Y_COORD), map.r2(OverworldSim.W_OW_UI_OBJ_1_X_COORD)], [2, 17],
			".Func_b721e: the step held, its counter counting from the start's 0")


func test_a_mirrored_riser_spawns_by_rdiv_then_follows_its_path_to_the_next_step() -> void:
	# Data_158897 (RISE_WIDE) invented as two steps: (0, 0), (-2, -1), then $80.
	var map: OverworldSim = _map({0x4897: 0x00, 0x4898: 0x00, 0x4899: 0xFE, 0x489A: 0xFF, 0x489B: 0x80})
	var obj: int = map.scene_obj(3)
	map.sim.div_replay = true
	map.sim.div_queue = [[OverworldSim.DIV_FUNC_15868E, 0x03]]
	map.w2(0xD151, 0x01)  # w2d151: scene object 3, to the right
	map.func_15868e()
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_Y), map.rd(obj + OverworldSim.SCENE_OBJ_X),
			map.rd(obj + OverworldSim.SCENE_OBJ_STATE), map.r2(0xD151), map.sim.div_queue], [0x2E, 0x52, 0x2A, 2, []],
			".Func_158882: state $29 plus rDIV's bit 0")
	map.func_15868e()
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_Y), map.r2(0xD151)], [0x2E, 2], "a step of (0, 0), not the end")
	map.func_15868e()
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_Y), map.rd(obj + OverworldSim.SCENE_OBJ_X),
			map.rd(obj + OverworldSim.W_SCENE_OBJ_UNK7), map.r2(0xD151)], [0x2C, 0x53, 0, 3],
			"mirrored: the x step taken off; at $80 the next step")
	map.w2(0xD151, 0x07)
	map.func_15868e()
	assert_eq([map.r2(0xD151), map.sim.div_mismatches], [1, PackedStringArray()], "round again")


func test_the_scene_starts_the_shake_at_loop_60_and_its_last_step_ends_the_function() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W_OW_SCENE_ACTION_PARAM, 0x12)
	map.w2(OverworldSim.W2D062, 0x01)
	map.w2(OverworldSim.W_OW_FUNC_COUNTER, 59)
	map.nowfunc_prologue()
	assert_eq(map.r2(OverworldSim.W2D062), 1, "before loop 60")
	map.w2(OverworldSim.W_OW_FUNC_COUNTER, 60)
	map.nowfunc_prologue()
	assert_eq([map.r2(OverworldSim.W_OW_UI_OBJ_1_Y_COORD), map.r2(OverworldSim.W2D049), map.r2(OverworldSim.W2D03E),
			map.r2(OverworldSim.W2D062), map.r2(OverworldSim.W_OW_FUNC_COUNTER)], [1, 1, 3, 2, 0])
	map.w2(OverworldSim.W2D062, 14)  # .Func_b59de
	map.w2(OverworldSim.W_OW_UI_OBJ_2_ATTRIBUTES, 0x01)
	map.nowfunc_prologue()
	assert_eq([map.r2(OverworldSim.W_OW_UI_OBJ_2_ATTRIBUTES), map.r2(OverworldSim.W_OW_SCENE_ACTION_PARAM),
			map.r2(OverworldSim.W2D062)], [0, 0, 0])


func test_the_scenes_sound_repeats_every_48_loops() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W_OW_UI_OBJ_2_ATTRIBUTES, 0x01)
	var timers: Array = []
	for loop: int in 49:
		map._func_b59e5()
		timers.append(map.r2(OverworldSim.W_OW_UI_OBJ_2_DURATION))
	assert_eq([timers[0], timers[46], timers[47], timers[48]], [1, 0x2F, 0, 1])
