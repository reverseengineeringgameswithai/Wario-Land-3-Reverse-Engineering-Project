extends TestCase
## The bosses (BossFunctions) on invented data (no ROM bytes), for the paths the sweeps do not
## reach: Wormwould's defeat, a magic spiral's last bounce, a launched Kuri leaving the screen,
## Jamano's dark, knocked skulls, and hat, the Shoot minigame past Shoot's jumps, and the palm
## trees.


## A level of free blocks, an empty object map, and zero movement data.
func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	for y: int in 48:
		var objects := PackedByteArray()
		objects.resize(80)
		sim.level.object_rows.append(objects)
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")  # free
	sim.level.room_handlers[0] = handlers
	var movement := PackedByteArray()
	movement.resize(0x11CB)
	sim.load_object_data({"framesets": {"by_pointer": {}}, "movement_data": {"bytes": movement.hex_encode()}})
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN)
	return sim


func test_wormwould_burrowed_home_with_no_hits_left_is_defeated() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_UNK_01, 6)  # its cell in the maps: row 2, column 6
	sim.set_cur(ObjectSim.OBJ_UNK_02, 0xA2)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0130)
	sim.set_cur(ObjectSim.OBJ_VAR_1, 0x30)  # home: y $0130
	sim.set_cur(ObjectSim.OBJ_VAR_2, 0x01)
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, 1)  # no hits left
	sim.set_cur(ObjectSim.OBJ_STATE, 0x5C)
	sim.wormwould_main()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_VAR_3)],
			[BossFunctions.WORMWOULD_DEFEATED_RAISE & 0xFFFF, 0x21], "rising, defeated")
	assert_eq(sim.level.object_rows[2][3], 0x50, "its object-map nibble 5 (an even column's is the high one)")
	assert_eq([sim.level.block_at(2, 6) & 0x80, "object data 0000" in sim.object_unported], [0, true],
			"bit 7 back, then the cell's new object spawned at once (Func_ba42; no object data here)")
	sim.set_cur(ObjectSim.OBJ_VAR_3, 1)
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_HDIR)
	sim.wormwould_defeated_raise()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE_DURATION), sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION)],
			[30, BossFunctions.WORMWOULD_DEFEATED_WAIT & 0xFFFF], "then 30 frames' wait")


func test_a_magic_spiral_vanishes_at_its_last_bounce_and_still_moves_across() -> void:
	var sim: LevelSim = _sim()
	sim.wram1[BossFunctions.W_WOLFENBOSS_REMAINING_HITS] = 4
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_HDIR | 1)  # rising, right, one bounce left
	sim.set_cur(ObjectSim.OBJ_SCREEN_Y_POS, 20)  # above row 24: turns down
	sim.set_cur(ObjectSim.OBJ_SCREEN_X_POS, 80)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0100)
	sim.magic_spiral_move()
	assert_eq((sim.cur(ObjectSim.OBJ_SUBSTATE) & ObjectSim.OBJSUBFLAG_VDIR) != 0, true, "turned down")
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_STATE_DURATION)],
			[BossFunctions.MAGIC_SPIRAL_DISAPPEAR & 0xFFFF, 27], "its last bounce: vanishing")
	assert_eq(sim.cur_x(), 0x0101, "the same frame still a pixel across")


func test_a_magic_spiral_is_gone_once_the_wolf_is_down_to_its_last_hit() -> void:
	var sim: LevelSim = _sim()
	sim.wram1[BossFunctions.W_WOLFENBOSS_REMAINING_HITS] = 1
	sim.magic_spiral_move()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0)


func test_a_launched_kuri_off_screen_is_gone_and_counted_out() -> void:
	var sim: LevelSim = _sim()
	sim.wram1[BossFunctions.W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE] = 1
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0080)
	sim.kuri_launched()
	assert_eq([sim.cur(ObjectSim.OBJ_FLAGS), sim.wram1[BossFunctions.W_WOLFENBOSS_IGAGURI_OR_KURI_ACTIVE], sim.cur_y()],
			[0, 0, 0x007E], "2 px up, then gone")


func test_the_dark_follows_the_skulls_at_the_edges_a_step_at_a_time() -> void:
	var sim: LevelSim = _sim()
	var jamano: int = ObjectSim.W_OBJECTS + 3 * ObjectSim.OBJ_STRUCT_LENGTH
	sim.wram1[jamano + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
	sim.wram1[jamano + ObjectSim.OBJ_ID] = BossFunctions.JAMANO
	sim.wram1[jamano + ObjectSim.OBJ_SUBSTATE] = ObjectSim.OBJSUBFLAG_HDIR
	sim.wram1[BossFunctions.W_JAMANO_ACTIVE_SKULLS] = 0x0F  # none to bring back
	sim.wram1[BossFunctions.W_JAMANO_DARKNESS] = 1
	sim.wram1[BossFunctions.W_JAMANO_SKULLS_OUT] = 2
	sim.skull_spawner_update()
	assert_eq([sim.wram1[BossFunctions.W_JAMANO_DARKNESS], sim.wram1[jamano + ObjectSim.OBJ_FRAMESET_PTR],
			sim.wram1[jamano + ObjectSim.OBJ_FRAMESET_PTR + 1]], [2, 0xB3, 0x5C], "darker, its frameset by level and side")
	sim.wram1[BossFunctions.W_JAMANO_SKULLS_OUT] = 0
	sim.skull_spawner_update()
	assert_eq(sim.wram1[BossFunctions.W_JAMANO_DARKNESS], 2, "down only from one fewer")
	sim.wram1[BossFunctions.W_JAMANO_SKULLS_OUT] = 1
	sim.skull_spawner_update()
	sim.wram1[BossFunctions.W_JAMANO_SKULLS_OUT] = 0
	sim.skull_spawner_update()
	assert_eq([sim.wram1[BossFunctions.W_JAMANO_DARKNESS], sim.wram1[jamano + ObjectSim.OBJ_FRAMESET_PTR]],
			[0, 0xBC], "no dark: the last step leaves its level-1 frameset")
	sim.skull_spawner_update()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), 0, "past the intro with no dark the spawner is gone")


func test_a_skull_knocked_off_screen_is_gone_after_its_frames() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)  # off screen
	sim.set_cur(ObjectSim.OBJ_ID, BossFunctions.SKULL3)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 2)
	sim.wram1[BossFunctions.W_JAMANO_ACTIVE_SKULLS] = 0x0F
	sim.skull_knocked_right()
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS), ObjectSim.OBJFLAG_ACTIVE, "a frame left")
	sim.skull_knocked_right()
	assert_eq([sim.cur(ObjectSim.OBJ_FLAGS), sim.wram1[BossFunctions.W_JAMANO_ACTIVE_SKULLS]], [0, 0x0B], "gone, its bit off")


func test_jamanos_hat_off_screen_ends_the_battle() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_FLAGS, ObjectSim.OBJFLAG_ACTIVE)
	sim.set_cur(ObjectSim.OBJ_UNK_01, 6)
	sim.set_cur(ObjectSim.OBJ_UNK_02, 0xA2)
	sim.set_cur(ObjectSim.OBJ_STATE_DURATION, 1)
	sim.wIsBossBattle = 1
	sim.jamano_hat_rise()
	assert_eq([sim.cur(ObjectSim.OBJ_FLAGS), sim.wBossState, sim.wIsBossBattle], [0, BossFunctions.BOSS_DEFEATED, 0])
	assert_eq(sim.level.object_rows[2][3], 0x60, "its object-map nibble 6")


func test_shoot_stepped_on_curls_into_a_knocked_ball() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectSim.OBJSTATE_WOBBLE_LEFT_START)
	sim.set_cur(ObjectSim.OBJ_INTERACTION_TYPE, BossFunctions.OBJ_INTERACTION_SHOOT | ObjectSim.HEAVY_OBJ)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0080)
	sim.shoot_main()
	assert_eq([sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), sim.cur(ObjectSim.OBJ_INTERACTION_TYPE), sim.cur(ObjectSim.OBJ_STATE)],
			[BossFunctions.SHOOT_BALL_FORM & 0xFFFF, ObjectStates.OBJ_INTERACTION_01, 0x38], "a harmful ball, knocked")
	assert_eq([sim.cur(ObjectSim.OBJ_ACTION), sim.cur(ObjectSim.OBJ_STATE_DURATION), sim.cur(ObjectSim.OBJ_VAR_2)],
			[(1 << ObjectSim.NO_ACTIONS_F) | 15, 4, 2])
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_GRABBED, ObjectSim.OBJFLAG_GRABBED, "grabbable left of x 219")


func test_shoot_catching_warios_ball_holds_him_16_px_under_it() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, ObjectSim.OBJSTATE_SPECIAL_3)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x01C0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0080)
	sim.wWarioYPos = 0x0150
	sim.wWarioXPos = 0x0234
	sim.shoot_main()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.cur(ObjectSim.OBJ_VAR_2), sim.cur_y()],
			[BossFunctions.SHOOTPHASE_PREKICK_JUMP, 1, 0x01B0], "16 px up, the pre-kick jump")
	assert_eq([sim.wWarioYPos, sim.wWarioXPos], [0x01C0, 0x0280], "his low bytes from its own")
	assert_eq(sim.cur(ObjectSim.OBJ_SUBSTATE) & 0xC0, 0xC0, "facing and heading right")


func test_shoots_third_goal_wins() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_VAR_1, BossFunctions.SHOOTPHASE_SCORE_GOAL)
	sim.wram1[BossFunctions.W_SHOOT_BALL_STATE] = BossFunctions.SHOOTBALL_WARIO_GOAL
	sim.wram1[ObjectSim.W_SHOOT_GOALS] = 2
	sim.shoot_main()
	assert_eq([sim.wram1[ObjectSim.W_SHOOT_GOALS], sim.wShootGoals, sim.wAutoMoveState, sim.cur(ObjectSim.OBJ_VAR_1)],
			[3, 3, 0x81, BossFunctions.SHOOTPHASE_WON])


func test_shoots_ball_bounced_into_the_net_is_warios_goal() -> void:
	var sim: LevelSim = _sim()
	sim.set_cur(ObjectSim.OBJ_STATE, 0x34)
	sim.set_cur(ObjectSim.OBJ_SUBSTATE, ObjectSim.OBJSUBFLAG_VDIR)
	sim.set_cur(ObjectSim.OBJ_VAR_2, 2)
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x00F0)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x00E0)
	sim.wram1[BossFunctions.W_SHOOT_BALL_STATE] = 1
	sim.shoot_ball_form()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur_x(), sim.cur_word(ObjectSim.OBJ_FRAMESET_PTR)],
			[0x2D, 0x00E2, BossFunctions.FRAMESET_69F9A], "into the net (below y 208 on to x 243)")
	assert_eq([sim.wram1[BossFunctions.W_SHOOT_BALL_STATE], sim.wram1[ObjectSim.W_WARIO_GOALS]], [2, 1])


func test_gk_tortoise_throws_shoot_back_and_the_third_goal_defeats_it() -> void:
	var sim: LevelSim = _sim()
	var shoot: int = ObjectSim.W_OBJECTS + 2 * ObjectSim.OBJ_STRUCT_LENGTH
	sim.wram1[shoot + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
	sim.wram1[shoot + ObjectSim.OBJ_ID] = BossFunctions.SHOOT
	sim.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0100)
	sim.set_cur_word(ObjectSim.OBJ_X_POS, 0x0080)
	sim.set_cur(ObjectSim.OBJ_VAR_1, 1)
	sim.wram1[BossFunctions.W_SHOOT_BALL_STATE] = 2
	sim.gk_tortoise_main()
	assert_eq([sim.cur(ObjectSim.OBJ_VAR_1), sim.wram1[BossFunctions.W_SHOOT_BALL_STATE]], [4, 3], "after Wario's goal")
	sim.set_cur(ObjectSim.OBJ_FRAMESET_OFFSET, 0x08)
	sim.gk_tortoise_main()
	assert_eq([sim.wram1[shoot + ObjectSim.OBJ_Y_POS], sim.wram1[shoot + ObjectSim.OBJ_Y_POS + 1],
			sim.wram1[shoot + ObjectSim.OBJ_X_POS]], [0xEA, 0x00, 0x80], "Shoot held 22 px above it")
	sim.set_cur(ObjectSim.OBJ_FRAMESET_OFFSET, 0x10)
	sim.gk_tortoise_main()
	assert_eq(sim.wram1[BossFunctions.W_SHOOT_BALL_STATE], 4, "thrown")
	# Shoot's ball, waiting in the net, is thrown left; landing at Wario's third goal, defeated.
	var ball: LevelSim = _sim()
	ball.wram1[BossFunctions.W_SHOOT_BALL_STATE] = 4
	ball.wram1[ObjectSim.W_WARIO_GOALS] = 3
	ball.set_cur(ObjectSim.OBJ_STATE, 0x2D)
	ball.set_cur_word(ObjectSim.OBJ_X_POS, 0x00F0)
	ball.shoot_ball_form()
	assert_eq([ball.cur(ObjectSim.OBJ_STATE), ball.cur(ObjectSim.OBJ_VAR_2), ball.cur(ObjectSim.OBJ_SUBSTATE) & ObjectSim.OBJSUBFLAG_VDIR],
			[0x35, 1, 0], "thrown left, slowly")
	ball.set_cur(ObjectSim.OBJ_UNK_01, 6)
	ball.set_cur(ObjectSim.OBJ_UNK_02, 0xA2)
	ball.set_cur_word(ObjectSim.OBJ_Y_POS, 0x00F0)
	ball.shoot_ball_form()
	assert_eq([ball.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), ball.cur(ObjectSim.OBJ_STATE), ball.cur_x()],
			[BossFunctions.SHOOT_DEFEAT_RISE & 0xFFFF, 0x48, 0x00EF], "a pixel left, then defeated")
	assert_eq(ball.level.object_rows[2][3], 0x90, "its object-map nibble 9")


func test_the_palm_trees_come_short_medium_tall_and_each_rises_then_opens() -> void:
	var sim: LevelSim = _sim()
	sim.palm_tree_spawner_func()
	var created: Array = []
	for frame: int in 240:
		var before: int = sim.unported.size()
		sim.palm_tree_spawner_spawn_trees()
		if sim.unported.size() > before:  # no object params loaded: each creation is noted
			created.append([frame, sim.unported[-1]])
	assert_eq(created, [[119, "object params 4c23"], [179, "object params 4c38"], [239, "object params 4c4d"]],
			"short at 120 frames left, medium at 60, tall at the end")
	assert_eq(sim.cur_word(ObjectSim.OBJ_UPDATE_FUNCTION), BossFunctions.PALM_TREE_SPAWNER_WAIT & 0xFFFF)
	var tree: LevelSim = _sim()
	tree.set_cur_word(ObjectSim.OBJ_Y_POS, 0x0100)
	tree.set_cur(ObjectSim.OBJ_VAR_1, 2)
	tree.set_cur(ObjectSim.OBJ_VAR_2, 1)
	tree.palm_tree_func()
	for frame: int in 4:
		tree.palm_tree_update()
	assert_eq([tree.cur_y(), tree.cur(ObjectSim.OBJ_VAR_1), tree.cur(ObjectSim.OBJ_VAR_2), tree.cur(ObjectSim.OBJ_FRAME_DURATION)],
			[0x00FE, 0, 0, 10], "2 px up, opened, its frame held")
