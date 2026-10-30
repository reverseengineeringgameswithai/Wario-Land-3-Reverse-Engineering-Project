extends TestCase
## Coins on invented data (no ROM bytes): the coin a broken block leaves by its rDIV roll, the
## colour-coin block's, and CoinFunc's start, turn, and blinking end.

## Invented params: ID, interaction, box (4), OAM pointer, the turn's two counters, state duration,
## vars 1-3, substate, state (.Init), update function, flags.
const PARAMS: String = "9141" + "f000f804" + "0041" + "0108" + "06" + "000300" + "21" + "19" + "0050" + "80"


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	var colour := PARAMS.hex_decode()
	colour[1] = 0x4A
	colour[16] = 0x94  # CoinFunc.ColourCoin
	sim.load_object_groups({"object_groups": {"groups": [], "object_data": {},
			"object_params": {"4e5a": PARAMS, "4e6d": colour.hex_encode()}}})
	sim.block_row = 3
	sim.block_column = 6
	sim.level.set_block(3, 6, 0x85)
	sim.wram1[ObjectSim.W_CUR_OBJ + ObjectSim.OBJ_UNK_01] = 0x55  # whatever object ran last
	return sim


func test_a_broken_block_leaves_a_coin_when_rdiv_and_3_is_0_and_the_cooldown_is_clear() -> void:
	var sim: LevelSim = _sim()
	sim.div_replay = true
	sim.div_queue = [[WarioBlocks.DIV_BREAK_BLOCK, 0x14]]
	sim.break_block(0x78)
	assert_eq(sim.level.block_at(3, 6), 0xF8, "the replacement keeps bit 7")
	assert_eq([sim.wram1[ObjectSim.OBJ_ID], sim.wram1[ObjectSim.OBJ_INTERACTION_TYPE], sim.wram1[ObjectSim.OBJ_UNK_01]],
			[0x91, 0x41, 0])
	assert_eq([sim.wram1[ObjectSim.OBJ_Y_POS], sim.wram1[ObjectSim.OBJ_X_POS]], [3 * 16 + 16, 6 * 16 + 8],
			"at the block's bottom middle")
	assert_eq(sim.wram1[ObjectSim.OBJ_FLAGS], 0x80 | ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_TRANSIENT)
	assert_eq(sim.wCoinCooldown, WarioBlocks.COIN_COOLDOWN)
	assert_eq(sim.wram1[ObjectSim.W_CUR_OBJ + ObjectSim.OBJ_UNK_01], 0x55, "wCurObj is restored")
	assert_true(sim.div_queue.is_empty() and sim.div_mismatches.is_empty())


func test_a_thrown_object_on_screen_breaks_an_enemy_block_as_breakblock_does() -> void:
	var sim: LevelSim = _sim()
	sim.div_replay = true
	sim.div_queue = [[WarioBlocks.DIV_BREAK_BLOCK, 0x14]]
	sim.wBlockFuncSpecialCollision = WarioBlocks.COLLISION_THROWN_OBJ
	sim.wram1[ObjectSim.W_CUR_OBJ + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN
	sim.enemy_block_collision(0x79)
	assert_eq(sim.level.block_at(3, 6), 0xF9, "the replacement keeps bit 7")
	assert_eq(sim.wram1[ObjectSim.OBJ_ID], 0x91, "and the roll leaves a coin")
	assert_true(sim.div_queue.is_empty() and sim.div_mismatches.is_empty())
	sim.level.set_block(3, 6, 0x85)
	sim.wCoinCooldown = 0
	sim.wBlockFuncSpecialCollision = WarioBlocks.COLLISION_THROWN_OBJ  # each probe sets it; Free clears it
	sim.wram1[ObjectSim.W_CUR_OBJ + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
	sim.enemy_block_collision(0x79)
	assert_eq(sim.level.block_at(3, 6), 0xF9, "off screen it breaks too")
	assert_eq(sim.wram1[ObjectSim.OBJ_STRUCT_LENGTH + ObjectSim.OBJ_FLAGS], 0, "but leaves no coin")
	assert_true(sim.div_mismatches.is_empty(), "and rolls nothing")


func test_no_coin_on_another_roll_or_during_the_cooldown() -> void:
	var sim: LevelSim = _sim()
	sim.div_replay = true
	sim.div_queue = [[WarioBlocks.DIV_BREAK_BLOCK, 0x15]]
	sim.break_block(0x78)
	assert_eq(sim.wram1[ObjectSim.OBJ_FLAGS], 0)
	sim.wCoinCooldown = 1
	sim.div_queue = [[WarioBlocks.DIV_BREAK_BLOCK, 0x14]]
	sim.break_block(0x78)
	assert_eq([sim.wram1[ObjectSim.OBJ_FLAGS], sim.wCoinCooldown], [0, 1])


func test_a_replayed_read_at_another_site_is_reported() -> void:
	var sim: LevelSim = _sim()
	sim.div_replay = true
	sim.div_queue = [[0x10_42B3, 0x14]]
	sim.break_block(0x78)
	assert_eq(sim.div_mismatches.size(), 1)
	sim.break_block(0x78)
	assert_eq(sim.div_mismatches.size(), 2, "and one beyond the original's")


func test_the_colour_coin_block_always_leaves_a_colour_coin() -> void:
	var sim: LevelSim = _sim()
	sim.div_replay = true
	sim.wCoinCooldown = 50
	sim.break_block(0x78, true)
	assert_eq([sim.wram1[ObjectSim.OBJ_INTERACTION_TYPE], sim.wCoinCooldown], [0x4A, 50])
	assert_true(sim.div_mismatches.is_empty(), "no roll")


## A coin in slot 0 as BreakBlock leaves it, loaded into wCurObj.
func _coin(sim: LevelSim) -> void:
	sim.div_replay = true
	sim.div_queue = [[WarioBlocks.DIV_BREAK_BLOCK, 0]]
	sim.break_block(0x78)
	for i: int in ObjectSim.OBJ_STRUCT_LENGTH:
		sim.wram1[ObjectSim.W_CUR_OBJ + i] = sim.wram1[i]


func test_a_coin_starts_turning_and_moves_away_from_wario() -> void:
	var sim: LevelSim = _sim()
	_coin(sim)
	sim.wGlobalCounter = 2  # not 1 in 64: a regular coin
	sim.wWarioScreenXPos = 100
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 60)
	sim.coin_func()
	assert_eq([sim.cur(ObjectSim.OBJ_FRAME), sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_ACTION)],
			[1, 0x1A, 0x8F], "the turn's first step, then .Init: no actions for 15 frames")
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ObjectFunctions.COIN_FUNC_UPDATE & 0xFFFF)
	sim.coin_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x06, "left of Wario: the bounce left")
	sim.set_cur(ObjectSim.OBJ_STATE, 0x1A)
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 140)
	sim.coin_update()
	assert_eq(sim.cur(ObjectSim.OBJ_STATE), 0x07)


func test_one_coin_in_64_becomes_a_colour_coin() -> void:
	var sim: LevelSim = _sim()
	_coin(sim)
	sim.wGlobalCounter = 0x41
	sim.coin_func()
	assert_eq([sim.cur(ObjectSim.OBJ_INTERACTION_TYPE), sim.cur(ObjectSim.OBJ_FRAME)], [0x4A, 9],
			"from frame 8, one step into the turn")


func test_the_turn_counts_down_frames_and_restarts_after_eight() -> void:
	var sim: LevelSim = _sim()
	_coin(sim)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x18 + 1)  # .Init: no movement
	sim.set_cur(ObjectSim.OBJ_FRAME, 7)
	sim.set_cur(ObjectSim.OBJ_FRAMESET_PTR, 1)
	sim.set_cur(ObjectSim.OBJ_FRAMESET_PTR + 1, 1)
	sim.coin_update()
	assert_eq([sim.cur(ObjectSim.OBJ_FRAME), sim.cur(ObjectSim.OBJ_FRAMESET_PTR), sim.cur(ObjectSim.OBJ_FRAMESET_PTR + 1)],
			[0, 1, 8], "the last frame of eight: back to the first")
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_FRAME_DURATION)], [1, 2])


func test_a_resting_coin_blinks_out() -> void:
	var sim: LevelSim = _sim()
	_coin(sim)
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	sim.set_cur(ObjectSim.OBJ_STATE, 0x17)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 5)
	sim.coin_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE, ObjectSim.OBJFLAG_INVISIBLE, "4: hidden")
	sim.coin_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_INVISIBLE, 0)
	for frame: int in 4:
		sim.coin_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "gone")
