extends TestCase
## The game's resets (LevelSim.init_game, Init: WL3-057) on invented data (no ROM bytes): Clear Data's
## Yes (ClearSaveData, then the title without the save), Action Help's demos (hDemoPowerUp kept) and
## Init (cleared), A+B+Select+Start (with resets allowed, wJoypadDown cleared after), and the SRAM Init
## loads: a level's map as played (not known without its unwritten bytes) or as SaveLevel saved it;
## and what a level from a load takes from SRAM (its unwritten bytes, the rows below its map).

const MAP_SAVE_CHECKSUMS: Array = [SaveLoad.S_GAME_DATA_CHECKSUM, SaveLoad.S_GAME_DATA_CHECKSUM_ECHO1,
	SaveLoad.S_GAME_DATA_CHECKSUM_ECHO2]


## A battery save with a map save ("war3", ValidateSaveData's main slot): its counter 5, the rest of
## the progress WRAM `fill`, the treasures 0, and its sum as the checksum and both echoes.
func _save(fill: int = 0x01) -> PackedByteArray:
	var banks: Array = []
	for _bank: int in 4:
		var bytes := PackedByteArray()
		bytes.resize(SaveLoad.SRAM_SIZE)
		banks.append(bytes)
	var data := PackedByteArray([0, 0, 0, 5])
	for _i: int in SaveLoad.PROGRESS_WRAM_SIZE - 4:
		data.append(fill)
	for _i: int in SaveLoad.TREASURES_SIZE:
		data.append(0)
	var bytes := PackedByteArray(SaveLoad.CHECKVAL1)
	bytes.append_array(data)
	for offset: int in bytes.size():
		banks[0][SaveLoad.S_CHECK_VALS - 0xA000 + offset] = bytes[offset]
	var sum: int = 0
	for value: int in data:
		sum = (sum + value) & 0xFFFF
	for at: int in MAP_SAVE_CHECKSUMS:
		banks[0][at - 0xA000] = sum >> 8
		banks[0][at - 0xA000 + 1] = sum & 0xFF
	return SaveLoad.save_bytes(banks)


## The game at power-on with `save`: the title (test_title's invented data) and an empty map.
func _power_on(save: PackedByteArray) -> LevelSim:
	var title: TitleSim = load("res://tests/unit/test_title.gd").new()._title()
	return LevelRunner.power_on(null, save, {"title": title.document, "overworld": {}}, Callable())


func test_clear_datas_yes_clears_the_save_and_init_starts_the_title_without_it() -> void:
	var sim: LevelSim = _power_on(_save())
	assert_eq([sim.wceef, sim.wState, sim.resets], [0x01, LevelSim.ST_TITLE, 0], "the map save loaded")
	var before: TitleSim = sim.title
	for loop: int in 200:  # with a save, the title goes straight to its start menu
		if sim.wSubState == TitleSim.SST_START_MENU:
			break
		LevelRunner.frame(sim, 0)
	sim.title.w3(TitleSim.W_START_MENU_SELECTION, TitleSim.STARTMENU_CLEAR_DATA_YES | TitleSim.STARTMENUF_SELECT)
	LevelRunner.frame(sim, 0)
	assert_eq([Array(sim.unported), sim.resets, sim.wState, sim.wSubState, sim.wceef, sim.wGlobalCounter],
			[[], 1, LevelSim.ST_TITLE, 0, 0, 0], "no save loads; the next loop is counted 0")
	assert_eq(Array(sim.loaded_sram[0].slice(SaveLoad.S_CHECK_VALS - 0xA000, SaveLoad.S_CHECK_VALS - 0xA000 + 8)),
			[0, 0, 0, 0, 0, 0, 0, 0], "ClearSaveData's eight bytes")
	assert_true(sim.title != before and sim.title.loops == 0, "the screens start over")
	LevelRunner.frame(sim, 0)
	assert_eq([sim.title.loops, sim.resets], [1, 1])


func test_the_demos_end_keeps_hdemopowerup_and_init_clears_it() -> void:
	var sim: LevelSim = _power_on(_save())
	sim.hDemoPowerUp = 4
	sim.request_init(LevelSim.INIT_KEEP_DEMO_POWER_UP)
	LevelRunner.frame(sim, 0)
	assert_eq([sim.resets, sim.hDemoPowerUp, sim.wceef], [1, 4, 0x01], "InitWithoutDemoPowerUpReset")
	sim.request_init()
	LevelRunner.frame(sim, 0)
	assert_eq([sim.resets, sim.hDemoPowerUp], [2, 0], "Init")


func test_all_four_buttons_reset_while_resets_are_allowed() -> void:
	var sim: LevelSim = _power_on(_save())
	var all: int = InputBits.A | InputBits.B | InputBits.SELECT | InputBits.START
	sim.wResetDisabled = 1
	LevelRunner.frame(sim, all)
	assert_eq([sim.resets, sim.title.loops], [0, 1], "resets disabled: the title's loop")
	sim.wResetDisabled = 0
	LevelRunner.frame(sim, all)
	assert_eq([sim.resets, sim.title.loops, sim.wJoypadDown, sim.wGlobalCounter], [1, 0, 0, 0],
			"Init instead of the loop, the joypad cleared")
	LevelRunner.frame(sim, InputBits.A)
	assert_eq([sim.wJoypadPressed, sim.title.loops], [WarioRam.PAD_A, 1], "A pressed anew after Init")


## An invented level map: row r's first block r, every unwritten byte $ee, row 3's object map $3f.
func _played_level(with_gaps: bool = true) -> LevelCollision:
	var level := LevelCollision.new()
	var rows: Array = []
	var gaps: Array = []
	for row: int in LevelCollision.HEIGHT:
		rows.append("%02x" % row + "00".repeat(LevelCollision.WIDTH - 1))
		gaps.append("ee".repeat(LevelCollision.GAP_WIDTH))
		if row < LevelSim.LEVEL_MAP_SRAM_ROWS:
			var objects := PackedByteArray()
			objects.resize(0x100 - LevelCollision.OBJECT_MAP_OFFSET)
			if row == 3:
				objects[0] = 0x3F
			level.object_rows.append(objects)
	level.set_rows(rows)
	if with_gaps:
		level.set_gap_rows(gaps)
	return level


func test_init_after_a_levels_play_loads_its_map_as_played_and_without_its_unwritten_bytes_is_not_ported() -> void:
	var sim: LevelSim = _power_on(_save())
	sim.loaded_sram[2][(50 - 32) * 0x100 + LevelCollision.OBJECT_MAP_OFFSET] = 0x5A
	sim.level = _played_level(false)
	sim.level_map_sram = LevelSim.LevelMapSram.PLAYED
	sim.request_init()
	LevelRunner.frame(sim, 0)
	assert_eq([sim.resets, sim.current_sram()], [0, []], "a map without its unwritten bytes")
	assert_true(Array(sim.unported).any(func(note: String) -> bool: return note.begins_with("Init: SRAM")))
	sim.unported.clear()
	sim.level = _played_level()
	var banks: Array = sim.current_sram()
	assert_eq([banks[1][3 * 0x100], banks[1][3 * 0x100 + LevelCollision.WIDTH],
			banks[1][3 * 0x100 + LevelCollision.OBJECT_MAP_OFFSET], banks[2][(40 - 32) * 0x100]],
			[3, 0xEE, 0x3F, 40], "rows 3 and 40 as played, a row's unwritten bytes, its object map")
	var row_50: int = (50 - 32) * 0x100
	assert_eq([banks[2][row_50], banks[2][row_50 + LevelCollision.WIDTH], banks[2][row_50 + LevelCollision.OBJECT_MAP_OFFSET]],
			[50, 0xEE, 0x5A], "row 50: the level's blocks and unwritten bytes, SRAM's object-map bytes")
	sim.request_init()
	LevelRunner.frame(sim, 0)
	assert_eq([sim.resets, sim.loaded_sram[1][3 * 0x100], sim.loaded_sram[2][row_50 + LevelCollision.OBJECT_MAP_OFFSET]],
			[1, 3, 0x5A], "Init loads the map as played")


func test_init_after_a_levels_save_loads_the_saved_map() -> void:
	var sim: LevelSim = _power_on(_save())
	sim.level = _played_level()
	sim.level_map_sram = LevelSim.LevelMapSram.SAVED
	var banks: Array = sim.current_sram()
	assert_eq([banks[1][3 * 0x100], banks[1][3 * 0x100 + LevelCollision.WIDTH], banks[2][(40 - 32) * 0x100]],
			[3, 0xEE, 40], "rows 3 and 40, a row's unwritten bytes")
	assert_eq(banks[2].slice(0x1000 + LevelCollision.OBJECT_MAP_OFFSET, 0x1100),
			sim.loaded_sram[2].slice(0x1000 + LevelCollision.OBJECT_MAP_OFFSET, 0x1100),
			"row 48's object-map bytes as the pause menu has them")


func test_a_level_from_a_load_takes_sram_below_its_map_and_its_unwritten_bytes() -> void:
	var sim: LevelSim = _power_on(_save())
	sim.loaded_sram[1][5 * 0x100 + LevelCollision.WIDTH] = 0x77
	sim.loaded_sram[2][(60 - 32) * 0x100 + 2] = 0x61
	sim.level = _played_level(false)
	sim._keep_sram_unwritten_bytes()
	assert_eq([sim.level.block_at(5, LevelCollision.WIDTH), sim.level.block_at(60, 2), sim.level.block_at(47, 0)],
			[0x77, 0x61, 47], "row 5's unwritten byte, row 60's block from SRAM, row 47 decompressed")
