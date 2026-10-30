extends TestCase
## The epilogue after the hidden figure's fight (OverworldEpilogue, WL3-052) on invented banks (no ROM
## bytes): _InitEpilogue's set-up and the font's tiles it keeps in wAttrmap, Func_aca25's white, the
## old man's mouth by page and line, a falling star's sparkles, his pick-up following Wario's frames,
## the clouds' drift, and the thanks waiting for A. The epilogue itself is checked against an invented
## save's movie (make wario-parity).

const EMPTY_BANK_SIZE: int = 0x4000


## The map with banks of zeros, `patches` ({bank: {address: bytes as hex}}) written in.
func _map(patches: Dictionary = {}) -> OverworldSim:
	var map := OverworldSim.new(LevelSim.new())
	var banks: Dictionary = {}
	for bank: int in [0x01, 0x1A, 0x21, 0x2B, 0x2C, 0x56, 0x57, 0x7C]:
		var bytes := PackedByteArray()
		bytes.resize(EMPTY_BANK_SIZE)
		for address: int in patches.get(bank, {}):
			var data: PackedByteArray = String(patches[bank][address]).hex_decode()
			for offset: int in data.size():
				bytes[address - 0x4000 + offset] = data[offset]
		banks["%02x" % bank] = bytes.hex_encode()
	map.load_data({"banks": banks})
	return map


func test_init_keeps_the_fonts_tiles_from_80_in_wattrmap_and_sets_the_prologues_vblank() -> void:
	# FontGfx invented: $800 zero bytes (16 runs of $7f and one of $10), then $11 $22 $33, then the end.
	var font: String = "7f00".repeat(16) + "1000" + "83112233" + "00"
	var map: OverworldSim = _map({0x7C: {int(OverworldSim.FONT_GFX[1]): font}})
	var sim: LevelSim = map.sim
	map.w2(OverworldSim.W2D013, 0x09)
	map.w2(OverworldSim.W_LCDC_FLAGS_TO_FLIP, 0x08)  # cleared with the scene RAM before it is read
	sim.wSubState = 0x24
	map.update()
	assert_eq([Array(map.unported), sim.wSubState, map.vblank_func, map.r2(OverworldSim.W2D013),
			map.r2(OverworldSim.W_ATTRMAP), map.r2(OverworldSim.W_ATTRMAP + 2), map.wTempBank],
			[[], 0x25, OverworldSim.VBLANK_PROLOGUE, 0, 0x11, 0x33, OverworldSim.EPILOGUE_BANK])
	assert_true(map.register_writes.has(["lcdc", OverworldSim.LCDC_TEMPLE]), "the LCD on, no bits flipped")


func test_func_aca25_whitens_all_eight_object_palettes_from_its_count_of_four() -> void:
	var map: OverworldSim = _map()
	map._func_aca25()
	assert_eq([map.r0(OverworldSim.W_TEMP_PALS_2), map.r0(OverworldSim.W_TEMP_PALS_2 + 1),
			map.r0(OverworldSim.W_TEMP_PALS_2 + 8 * 8 - 1), map.r0(OverworldSim.W_TEMP_PALS_2 + 8 * 8)],
			[0xFF, 0x7F, 0x7F, 0], "4 palettes counted as 32 colours: $40 bytes")


func test_the_old_mans_mouth_follows_the_page_and_the_line_with_the_first_lines_fallback() -> void:
	var map: OverworldSim = _map()
	var mouth := func(page: int, line: int) -> int:
		map.set_scene_obj_state(9, 0x0A)
		map.w2(OverworldSim.W_PENDING_CHAR_DEST, 0xC2)
		map.w2(OverworldSim.W_CUR_TEXT_LINE_POS, 1)
		map.w2(OverworldSim.W_CUR_TEXT_BUFFER_PAGE, page)
		map.w2(OverworldSim.W_CUR_TEXT_BUFFER_LINE, line)
		map._func_af376()
		return map.rd(map.scene_obj(9) + OverworldSim.SCENE_OBJ_STATE)
	map.w0(OverworldSim.W_LANGUAGE, 1)  # English
	assert_eq([mouth.call(8, 2), mouth.call(8, 1), mouth.call(1, 1), mouth.call(1, 2), mouth.call(2, 1)],
			[0x0E, 0x0B, 0x10, 0x0A, 0x0B], ".asm_af3e8 falls back on line 1; .asm_af3d0 does not")
	map.w0(OverworldSim.W_LANGUAGE, OverworldSim.LANGUAGE_JAPANESE)
	assert_eq([mouth.call(0x0B, 3), mouth.call(0x0B, 2), mouth.call(5, 2)], [0x0C, 0x0A, 0x0D])


func test_a_star_drops_sparkles_that_fall_and_one_spawns_again_while_it_is_shown() -> void:
	# .data_1 invented, read by the counter from 1: steps -1, -2, -1, then $80.
	var map: OverworldSim = _map({0x56: {OverworldSim.DATA_158659: "fffffeff80"}})
	map.set_scene_obj_state(1, 0x16)  # the star shown at (40, 80)
	map.wr(map.scene_obj(1) + OverworldSim.SCENE_OBJ_Y, 40)
	map.wr(map.scene_obj(1) + OverworldSim.SCENE_OBJ_X, 80)
	var sparkle: Array = OverworldSim.EPILOGUE_SPARKLES[1]  # .Func_158529: wSceneObj6
	var obj: int = map.scene_obj(6)
	var ys: Array = []
	for loop: int in 16:
		map._epilogue_sparkle(sparkle)
		ys.append(map.rd(obj + OverworldSim.SCENE_OBJ_Y))
	assert_eq(ys.slice(10, 16), [0, 32, 31, 29, 28, 28], "spawned 8 up after $0a loops, then down the table")
	assert_eq([map.rd(obj + OverworldSim.SCENE_OBJ_X), map.rd(obj + OverworldSim.SCENE_OBJ_STATE),
			map.r2(OverworldSim.W_TEMPLE_MUSIC_BOX_2_COUNTER)], [83, 0, 0x04], "hidden at the $80")
	map._epilogue_sparkle(sparkle)
	assert_eq(map.r2(OverworldSim.W_TEMPLE_MUSIC_BOX_2_COUNTER), 0x02, ".Func_158580: spawning again, the star still shown")


func test_the_old_man_picked_up_follows_wario_frames_0_1_2_once_each() -> void:
	var map: OverworldSim = _map()
	var obj: int = map.scene_obj(9)
	map.w2(OverworldSim.W_SCENE_WARIO, 0x60)
	map.w2(OverworldSim.W_SCENE_WARIO_X_COORD, 0x80)
	map.w2(OverworldSim.W_SCENE_WARIO_STATE, OverworldSim.SCENEWARIO_PICKUP)
	var places: Array = []
	for frame: int in [1, 0, 0, 1, 2, 2]:
		map.w2(OverworldSim.W_SCENE_WARIO_FRAME, frame)
		map._func_ac1c3(obj)
		places.append([map.rd(obj + OverworldSim.SCENE_OBJ_Y), map.rd(obj + OverworldSim.SCENE_OBJ_X),
				map.rd(obj + OverworldSim.W_SCENE_OBJ_UNK7)])
	assert_eq(places, [[0, 0, 0], [0x5C, 0x6A, 1], [0x5C, 0x6A, 1], [0x50, 0x6C, 2], [0x3E, 0x79, 0x80],
			[0x3E, 0x79, 0x80]])


func test_the_clouds_drift_right_every_4_and_8_loops_while_the_first_is_in_state_1b() -> void:
	var map: OverworldSim = _map()
	map._set_obj(10, 0x30, 0x00, 0x1B)
	map._set_obj(11, 0x35, 0x20, 0x1C)
	for counter: int in 16:
		map.sim.wGlobalCounter = counter
		map._func_af8bc()
	assert_eq([map.rd(map.scene_obj(10) + OverworldSim.SCENE_OBJ_X), map.rd(map.scene_obj(11) + OverworldSim.SCENE_OBJ_X)],
			[4, 0x22])
	map.wr(map.scene_obj(10) + OverworldSim.SCENE_OBJ_STATE, 0)
	map._func_af8bc()  # wGlobalCounter 15 again, but none move without the first's state
	map.sim.wGlobalCounter = 0
	map._func_af8bc()
	assert_eq(map.rd(map.scene_obj(11) + OverworldSim.SCENE_OBJ_X), 0x22)


func test_the_thanks_waits_for_a_then_clears_the_text_box_and_the_old_man_rises() -> void:
	var map: OverworldSim = _map()
	map.w2(OverworldSim.W2D013, 0x16)
	map.w2(OverworldSim.W2D890, 0x01)  # .Func_af69a
	map.set_scene_obj_state(1, 0x01)
	map._epilogue_step()
	assert_eq([map.r2(OverworldSim.W2D890), map.rd(map.scene_obj(1) + OverworldSim.SCENE_OBJ_STATE)], [1, 1])
	map.sim.wJoypadPressed = OverworldSim.PAD_A
	map._epilogue_step()
	assert_eq([map.r2(OverworldSim.W2D890), map.r2(OverworldSim.W2D891),
			map.rd(map.scene_obj(1) + OverworldSim.SCENE_OBJ_STATE), map.rd(map.scene_obj(9) + OverworldSim.SCENE_OBJ_STATE),
			map.r2(OverworldSim.W_HDMA_BANK)],
			[2, 0, 0, 0x0F, OverworldSim.PROLOGUE_BANK], "ClearTextbox by wHDMA")
	assert_eq(Array(map.unported), [])
