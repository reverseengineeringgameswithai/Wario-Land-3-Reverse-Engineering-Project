extends TestCase
## The prologue (OverworldPrologue, WL3-056) on invented banks (no ROM bytes): the cutscene's dispatch, the
## text printer and its pages, a plane part's fall, PrologueFade, and VBlank_PrologueEpilogue. The
## prologue itself is checked against a power-on movie (make wario-parity).

const EMPTY_BANK_SIZE: int = 0x4000


## The map with banks of zeros ($2b with `bank_2b` bytes at addresses) and the prologue's event.
func _map(bank_2b: Dictionary = {}) -> OverworldSim:
	var map := OverworldSim.new(LevelSim.new())
	var banks: Dictionary = {}
	for bank: int in [0x01, 0x21, 0x2A, 0x2B, 0x2C, 0x36, 0x57, 0x7C]:
		var bytes := PackedByteArray()
		bytes.resize(EMPTY_BANK_SIZE)
		if bank == 0x2B:
			for address: int in bank_2b:
				bytes[address - 0x4000] = int(bank_2b[address])
		banks["%02x" % bank] = bytes.hex_encode()
	map.load_data({"banks": banks})
	map.w2(OverworldSim.W_EVENT_WITH_CUTSCENE, OverworldSim.EVENT_PROLOGUE)
	map.w2(OverworldSim.W_CUR_EVENT, OverworldSim.EVENT_PROLOGUE)
	return map


func test_the_prologue_is_set_up_and_played_by_the_cutscene() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	map.wr(OverworldSim.W_TEMP_PALS_1, 0x55)
	sim.wSubState = 0x11
	map.update()
	assert_eq([Array(map.unported), sim.wSubState, map.vblank_func, map.r0(OverworldSim.W_TEMP_PALS_1),
			map.r2(OverworldSim.W_SCENE_WARIO), map.r2(OverworldSim.W_CLEARED_TEXT_BUFFER)],
			[[], 0x12, OverworldSim.VBLANK_PROLOGUE, 0, 96, OverworldSim.CHAR_NONE],
			"_InitPrologue: no note, its V-Blank, black palettes, Wario at 96, the cleared text")
	sim.wSubState = 0x13
	map.update()  # step 0: Prologue_Next
	map.update()  # step 1: .Wait60 counts
	assert_eq([map.r2(OverworldSim.W2D013), map.r2(OverworldSim.W2D014), Array(map.unported)], [1, 1, []])


func test_the_text_prints_a_character_at_a_time_after_its_delay() -> void:
	var map: OverworldSim = _map()
	var sim: LevelSim = map.sim
	map.wr(OverworldSim.W_TEXT_BUFFER, 0x10)  # the header's line: one character, then none ('@')
	for offset: int in range(1, OverworldSim.TEXT_LINE_LENGTH):
		map.wr(OverworldSim.W_TEXT_BUFFER + offset, OverworldSim.CHAR_NONE)
	map.w2(OverworldSim.W2D013, 0x1B)
	map._play_prologue()  # InitTextPrinting
	assert_eq([map.r2(OverworldSim.W2D013), map.r2(OverworldSim.W_TEXT), map.r2(OverworldSim.W_TEXT + 0x10)],
			[0x1C, 0x10, OverworldSim.CHAR_NONE])
	var loops: int = 0
	while map.r2(OverworldSim.W_PENDING_CHAR_DEST) == 0 and loops < 30:
		map._play_prologue()  # Func_aca9e: 10 loops' wait, then 4 more for the character
		loops += 1
	assert_eq([loops, map.r2(OverworldSim.W_PENDING_CHAR_TILE), map.r2(OverworldSim.W_PENDING_CHAR_DEST),
			map.r2(OverworldSim.W_PENDING_CHAR_DEST + 1), map.r2(OverworldSim.W_PENDING_CHAR_ATTR)],
			[14, 0x10, 0xC1, 0x99, 0x09], "the first line a tile left of (2, 14)")
	map.vram_writes.clear()
	map.vblank_prologue_epilogue()
	assert_eq([map.vram_writes.size(), map.vram_writes[0][2], map.r2(OverworldSim.W_PENDING_CHAR_DEST)],
			[2, 0x99C1, 0], "the tile and its attributes, then no character pending")
	sim.wJoypadDown = OverworldSim.PAD_A  # A held halves the delay
	loops = 0
	while map.r2(OverworldSim.W_CUR_TEXT_LINE) == 1 and loops < 30:
		map._play_prologue()
		loops += 1
	assert_eq([loops, map.r2(OverworldSim.W_PENDING_CHAR_DEST)], [2, 0], "the rest of the line is no characters")


func test_a_page_not_starting_with_its_end_mark_goes_three_steps_back() -> void:
	var map: OverworldSim = _map()
	map.wr(OverworldSim.W_TEXT_BUFFER + 2 * 0x40, OverworldSim.CHAR_PAGE_END)
	map.w2(OverworldSim.W2D013, 0x21)
	map._play_prologue()  # page 0 to 1: not the end
	assert_eq([map.r2(OverworldSim.W_CUR_TEXT_BUFFER_PAGE), map.r2(OverworldSim.W2D013),
			map.rd(OverworldSim.scene_obj(1) + OverworldSim.SCENE_OBJ_STATE)], [1, 0x1E, 0x01], "the arrow shown")
	map.w2(OverworldSim.W2D013, 0x21)
	map._play_prologue()  # page 2: its end mark
	assert_eq([map.r2(OverworldSim.W_CUR_TEXT_BUFFER_PAGE), map.r2(OverworldSim.W2D013),
			map.r2(OverworldSim.W_SCENE_WARIO_STATE)], [2, 0x22, OverworldSim.SCENEWARIO_LOOK_AROUND],
			"on, and on the third page Wario looks around")


func test_a_plane_part_is_placed_falls_with_its_follower_and_waits() -> void:
	# Data_aed6d: (1, 0) then (-1, 0), then $80 (bank $2b).
	var map: OverworldSim = _map({0x6D6D: 0x01, 0x6D6F: 0xFF, 0x6D71: 0x80})
	map.w2(OverworldSim.W2D8A1, 0x07)
	map._func_ae8bb()  # the 8th loop starts part 1
	assert_eq([map.r2(OverworldSim.W_PLANE_PART_1_ACTION), map.r2(OverworldSim.W2D8A0)], [1, 1])
	map.w2(OverworldSim.W_PLANE_PART_1_ACTION + 2, 1)  # part 2: placed (obj 4), obj 1 cleared
	map._func_ae8bb()
	var obj_4: int = OverworldSim.scene_obj(4)
	assert_eq([map.rd(obj_4), map.rd(obj_4 + 1), map.rd(obj_4 + OverworldSim.SCENE_OBJ_STATE),
			map.r2(OverworldSim.W_PLANE_PART_1_ACTION + 2)], [62, 240, 0x02, 2])
	map.wr(obj_4, OverworldSim.PLANE_PART_GROUND_Y - 1)
	map._func_ae8bb()  # falls a line onto the ground: its follower (obj 1) on it, state $10
	var obj_1: int = OverworldSim.scene_obj(1)
	assert_eq([map.rd(obj_4), map.rd(obj_1), map.rd(obj_1 + 1), map.rd(obj_1 + OverworldSim.SCENE_OBJ_STATE),
			map.r2(OverworldSim.W_PLANE_PART_1_ACTION + 2)], [OverworldSim.PLANE_PART_GROUND_Y,
			OverworldSim.PLANE_PART_GROUND_Y, 240, 0x10, 3])
	map._func_ae8bb()  # (-1, 0), then the table's end: landed
	assert_eq([map.rd(obj_4), map.r2(OverworldSim.W_PLANE_PART_1_ACTION + 2),
			map.r2(OverworldSim.W_PLANE_PART_1_ACTION + 3)], [OverworldSim.PLANE_PART_GROUND_Y - 1, 4, 0])


func test_prologue_fade_sets_up_by_w2d880_then_fades_32_steps() -> void:
	var map: OverworldSim = _map()
	map.wr(OverworldSim.W_TEMP_PALS_1, 0x1F)  # red 31, faded to black (fade 0)
	map.w2(OverworldSim.W2D013, 0x03)
	map.w2(OverworldSim.W2D880, 0)
	map.prologue_fade()
	assert_eq([map.r0(OverworldSim.W_TEMP_BG_PALS), map.r0(OverworldSim.W_TEMP_PALS_1),
			map.r2(OverworldSim.W_PAL_CONFIG_1_TOTAL_STEPS), map.r2(OverworldSim.W_PAL_CONFIG_1_NUMBER)],
			[0x1F, 0, 1, 8], "the colours shown kept, the target black, the configs set")
	var loops: int = 0
	while map.r2(OverworldSim.W2D013) == 0x03 and loops < 100:
		map.prologue_fade()
		loops += 1
	assert_eq([loops, map.r0(OverworldSim.W_TEMP_BG_PALS), map.r2(OverworldSim.W_PAL_CONFIG_1_TOTAL_STEPS)],
			[31, 0, 0], "a step a loop from the first, then the next step")
