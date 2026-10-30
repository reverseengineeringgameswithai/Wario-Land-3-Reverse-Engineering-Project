extends TestCase
## The object framework on invented data (no ROM bytes): animation, the on-screen window and
## despawning, actions, the update's copy back, and the musical coin.


func _sim() -> ObjectFunctions:
	var sim := ObjectFunctions.new()
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	for y: int in LevelCollision.HEIGHT:
		var objects := PackedByteArray()
		objects.resize(80)
		sim.level.object_rows.append(objects)
	sim.load_object_framesets({"framesets": {"by_pointer": {"4036": [[4, 10], [5, 9]], "4100": [[1, 2]]}}})
	sim.wCameraSCY = 0x0100
	sim.wCameraSCX = 0x0200
	sim.wSCY = 0x00
	sim.wSCX = 0x00
	return sim


## A slot at (x, y) whose map cell is (row, column): active, initialised, frameset $4036.
func _place(sim: ObjectFunctions, slot: int, x: int, y: int, row: int, column: int) -> int:
	var base: int = slot * ObjectSim.OBJ_STRUCT_LENGTH
	sim.wram1[base + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE
	sim.wram1[base + ObjectSim.OBJ_UNK_01] = column
	sim.wram1[base + ObjectSim.OBJ_UNK_02] = 0xA0 + row
	sim.wram1[base + ObjectSim.OBJ_Y_POS] = y & 0xFF
	sim.wram1[base + ObjectSim.OBJ_Y_POS + 1] = y >> 8
	sim.wram1[base + ObjectSim.OBJ_X_POS] = x & 0xFF
	sim.wram1[base + ObjectSim.OBJ_X_POS + 1] = x >> 8
	sim.wram1[base + ObjectSim.OBJ_ID] = 0x33
	sim.wram1[base + ObjectSim.OBJ_FRAMESET_PTR] = 0x36
	sim.wram1[base + ObjectSim.OBJ_FRAMESET_PTR + 1] = 0x40
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] = 0x01
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = 0xF9  # MusicalCoinFunc.Update
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION + 1] = 0x49
	return base


func test_animation_steps_through_the_frameset_and_starts_again_at_its_end() -> void:
	var sim: ObjectFunctions = _sim()
	sim.set_object_frameset_ptr(0x4036)
	sim.update_object_animation()
	assert_eq([sim.cur(ObjectSim.OBJ_FRAME), sim.cur(ObjectSim.OBJ_FRAME_DURATION), sim.cur(ObjectSim.OBJ_FRAMESET_OFFSET)],
			[4, 10, 2], "a new frameset starts at once")
	for i: int in 11:
		sim.update_object_animation()
	assert_eq([sim.cur(ObjectSim.OBJ_FRAME), sim.cur(ObjectSim.OBJ_FRAME_DURATION)], [5, 9], "after 10 more frames, the next pair")
	for i: int in 10:
		sim.update_object_animation()
	assert_eq([sim.cur(ObjectSim.OBJ_FRAME), sim.cur(ObjectSim.OBJ_FRAME_DURATION), sim.cur(ObjectSim.OBJ_FRAMESET_OFFSET)],
			[4, 10, 2], "at $ff, the first pair again")


func test_an_object_in_view_is_flagged_on_screen_and_one_far_away_despawns() -> void:
	var sim: ObjectFunctions = _sim()
	var near: int = _place(sim, 0, 0x0250, 0x0150, 3, 7)
	var far: int = _place(sim, 1, 0x0500, 0x0150, 3, 9)
	sim.level.set_block(3, 9, 0x05)
	sim.update_objects()
	assert_eq(sim.wram1[near] & ObjectSim.OBJFLAG_ON_SCREEN, ObjectSim.OBJFLAG_ON_SCREEN)
	assert_eq([sim.wram1[near + ObjectSim.OBJ_SCREEN_Y_POS], sim.wram1[near + ObjectSim.OBJ_SCREEN_X_POS]],
			[0x60, 0x58], "screen position from the scroll shadows' low bytes")
	assert_eq(sim.wram1[far], 0, "despawned")
	assert_eq(sim.level.block_at(3, 9), 0x85, "its map byte gets bit 7 back, to spawn again")


func test_an_attack_action_turns_the_object_away_from_the_hit_and_waits() -> void:
	var sim: ObjectFunctions = _sim()
	sim.set_cur(ObjectSim.OBJ_ACTION, 2)  # OBJACTION_ATTACK
	sim.set_cur(ObjectSim.OBJ_UNK_1D, ObjectSim.INTERACTION_RIGHT)
	sim.do_object_action()
	assert_eq([sim.cur(ObjectSim.OBJ_STATE), sim.cur(ObjectSim.OBJ_ACTION)],
			[ObjectSim.OBJSTATE_ATTACKED_LEFT_START, 0x8F])
	assert_eq(sim.cur(ObjectSim.OBJ_FLAGS) & ObjectSim.OBJFLAG_NO_COLLISION, ObjectSim.OBJFLAG_NO_COLLISION)
	sim.set_cur(ObjectSim.OBJ_ACTION, 0x81)
	sim.do_object_action()
	assert_eq(sim.cur(ObjectSim.OBJ_ACTION), 0, "the wait counts down to none")


func test_the_copy_back_keeps_the_slots_own_unk_bytes() -> void:
	var sim: ObjectFunctions = _sim()
	var base: int = _place(sim, 2, 0x0250, 0x0150, 3, 7)
	sim.wram1[base + ObjectSim.OBJ_UNK_1D] = 0x40
	sim.wram1[base + ObjectSim.OBJ_FLAGS] |= ObjectSim.OBJFLAG_STEPPED
	sim.update_objects()
	assert_eq([sim.wram1[base + ObjectSim.OBJ_UNK_01], sim.wram1[base + ObjectSim.OBJ_UNK_02], sim.wram1[base + ObjectSim.OBJ_UNK_1D]],
			[7, 0xA3, 0x40])
	assert_eq(sim.wram1[base] & ObjectSim.OBJFLAG_STEPPED, 0, "OBJFLAG_STEPPED lasts one frame")


func test_the_musical_coin_starts_visible_and_leaves_the_map_when_taken() -> void:
	var sim: ObjectFunctions = _sim()
	var base: int = _place(sim, 0, 0x0250, 0x0150, 3, 6)
	sim.wram1[base + ObjectSim.OBJ_FLAGS] |= ObjectSim.OBJFLAG_INVISIBLE
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] |= ObjectSim.OBJSUBFLAG_UNINITIALISED
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = 0xD4  # MusicalCoinFunc
	sim.level.object_rows[3][3] = 0x9A  # column 6 (high nibble) holds 9, column 7 holds A
	sim.update_objects()
	assert_eq(sim.wram1[base] & (ObjectSim.OBJFLAG_INVISIBLE | ObjectSim.OBJFLAG_NO_COLLISION), ObjectSim.OBJFLAG_NO_COLLISION)
	assert_eq([sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION], sim.wram1[base + ObjectSim.OBJ_COLLBOX_LEFT]], [0xF9, 0xEF])
	sim.wram1[base + ObjectSim.OBJ_STATE] = ObjectSim.OBJSTATE_18
	sim.update_objects()
	# CheckObjectOnScreen still runs after the function cleared the flags, as in the original.
	assert_eq(sim.wram1[base], ObjectSim.OBJFLAG_ON_SCREEN, "taken: no longer active")
	assert_eq(sim.level.object_rows[3][3], 0x0A, "only its own nibble is cleared")


func test_during_a_floor_transition_only_uninitialised_objects_run_their_function() -> void:
	var sim: ObjectFunctions = _sim()
	sim.wIsFloorTransition = 1
	var base: int = _place(sim, 0, 0x0250, 0x0150, 3, 6)
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = 0x34  # not ported: not called while initialised
	sim.update_objects()
	assert_true(sim.unported.is_empty(), "nothing called: %s" % sim.unported)
	assert_eq(sim.wram1[base + ObjectSim.OBJ_SCREEN_Y_POS], 0x60, "the screen position still follows")


## A floor along row 10 (solid), a wall at column 8 (row 9), invented framesets and fall speeds.
func _spearhead_sim() -> ObjectFunctions:
	var sim: ObjectFunctions = _sim()
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	handlers[1] = "h06_4032"
	sim.level.room_handlers[0] = handlers
	for column: int in LevelCollision.WIDTH:
		sim.level.set_block(10, column, 1)
	sim.level.set_block(9, 8, 1)
	var framesets: Dictionary = {}
	for pointer: String in ["4036", "41d2", "41db", "421e", "4229", "424f", "425a", "41e4", "41ed", "4234", "427c",
			"4287"]:
		framesets[pointer] = [[0, 4]]
	var movement := PackedByteArray()
	movement.resize(0x400)
	for i: int in 0x10:
		movement[0x280 + i] = 1 if i < 15 else 0x80  # FallingYVel_Light: 1 px a frame
	sim.load_object_data({"framesets": {"by_pointer": framesets}, "movement_data": {"bytes": movement.hex_encode()}})
	sim.wCameraSCY = 0x0040
	sim.wCameraSCX = 0x0000
	return sim


func _spearhead(sim: ObjectFunctions, x: int, state: int, facing_right: bool) -> int:
	var base: int = _place(sim, 0, x, 0xA0, 10, 0)
	sim.wram1[base + ObjectSim.OBJ_ID] = 0x00
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION] = 0x69  # SpearheadFunc.Update
	sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION + 1] = 0x40
	sim.wram1[base + ObjectSim.OBJ_STATE] = state
	sim.wram1[base + ObjectSim.OBJ_SUBSTATE] = ObjectSim.OBJSUBFLAG_HDIR if facing_right else 0
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_LEFT] = 0xF9
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_RIGHT] = 9
	return base


func test_a_spearhead_walks_half_a_pixel_a_frame_and_turns_at_a_wall() -> void:
	var sim: ObjectFunctions = _spearhead_sim()
	var base: int = _spearhead(sim, 0x60, ObjectStates.OBJSTATE_WALK, true)
	for frame: int in 8:
		sim.wGlobalCounter = frame
		sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_X_POS], 0x64, "4 pixels in 8 frames")
	var turned_at: int = -1
	for frame: int in range(8, 120):
		sim.wGlobalCounter = frame
		sim.update_objects()
		if sim.wram1[base + ObjectSim.OBJ_STATE] == ObjectStates.OBJSTATE_TURN_AROUND:
			turned_at = sim.wram1[base + ObjectSim.OBJ_X_POS]
			break
	assert_eq(turned_at, 0x77, "the probe 9 px ahead and 4 up meets the wall at x $80")
	assert_true(sim.unported.is_empty(), "nothing unported: %s" % sim.unported)


func test_a_spearhead_off_the_ground_falls_and_lands_walking() -> void:
	var sim: ObjectFunctions = _spearhead_sim()
	var base: int = _spearhead(sim, 0x30, ObjectStates.OBJSTATE_FALL, false)
	sim.wram1[base + ObjectSim.OBJ_Y_POS] = 0x90  # 16 px above the floor
	for frame: int in 17:
		sim.wGlobalCounter = frame
		sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_Y_POS], 0xA0, "on the floor's top")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE], ObjectStates.OBJSTATE_WALK, "landed (OBJSTATE_LAND) and walking")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE_DURATION], 10, "the frame after landing: the sting is back in 10")


func test_a_sleeping_spearhead_wakes_when_wario_comes_near_and_turns_to_him() -> void:
	var sim: ObjectFunctions = _spearhead_sim()
	sim.wSCX = 0x00
	sim.wSCY = 0x40
	var base: int = _spearhead(sim, 0x60, ObjectStates.OBJSTATE_SPECIAL_1, true)
	sim.wram1[base + ObjectSim.OBJ_SCREEN_X_POS] = 0x68  # x + 8 - wSCX
	sim.wram1[base + ObjectSim.OBJ_SCREEN_Y_POS] = 0x70  # y + 16 - wSCY
	sim.wWarioScreenYPos = 0x70
	sim.wWarioScreenXPos = 0x68 + 33
	sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE], ObjectStates.OBJSTATE_SPECIAL_1, "33 px away it sleeps on")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_SUBSTATE] & ObjectSim.OBJSUBFLAG_HDIR, 0, "facing away from him")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_Y_POS], 0xA0, "on the floor")
	sim.wWarioScreenXPos = 0x68 + 32
	sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE], ObjectSim.OBJSTATE_SPECIAL_3, "32 px away it wakes")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE_DURATION], 32)
	assert_eq(sim.wram1[base + ObjectSim.OBJ_FRAMESET_PTR], 0x7C, "Frameset_6827c, facing left")
	for frame: int in 32:
		sim.update_objects()
	assert_eq(sim.wram1[base + ObjectSim.OBJ_STATE], ObjectStates.OBJSTATE_TURN_AROUND, "turning to him")
	assert_true(sim.unported.is_empty(), "nothing unported: %s" % sim.unported)


func test_an_object_creates_another_at_a_signed_offset() -> void:
	var sim: ObjectFunctions = _sim()
	var params := PackedByteArray([5, 0xF8, 0x03, 0x1C, 0xF9, 0xFD, 0xFC, 3, 0x42, 0x42, 0xC8, 0x42, 0, 0, 0, 0, 0, 0,
			0xB1, 0x4A, 0x00])
	sim.object_params[0x47A0] = params
	_place(sim, 0, 0x0250, 0x0100, 3, 7)
	for i: int in 32:
		sim.wram1[ObjectSim.W_CUR_OBJ + i] = sim.wram1[i]
	sim.wram1[32 + ObjectSim.OBJ_SCREEN_X_POS] = 0x77  # left over in the free slot
	sim.create_object_at_relative_pos(0x47A0)
	var base: int = 32
	assert_eq(sim.wram1[base], ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_TRANSIENT)
	assert_eq([sim.wram1[base + ObjectSim.OBJ_Y_POS], sim.wram1[base + ObjectSim.OBJ_Y_POS + 1],
			sim.wram1[base + ObjectSim.OBJ_X_POS], sim.wram1[base + ObjectSim.OBJ_X_POS + 1]], [0x05, 0x01, 0x48, 0x02],
			"y + 5 and x - 8")
	assert_eq([sim.wram1[base + ObjectSim.OBJ_ID], sim.wram1[base + ObjectSim.OBJ_COLLBOX_RIGHT],
			sim.wram1[base + ObjectSim.OBJ_UPDATE_FUNCTION]], [0x03, 3, 0xB1])
	assert_eq(sim.wram1[base + ObjectSim.OBJ_SCREEN_X_POS], 0x77, "the screen position is not written")
	assert_eq(sim.wram1[base + ObjectSim.OBJ_UNK_02], 0xA3, "tied to the creator's map cell")


## An on-screen object in `slot` at screen (x, y) with a 16x16 box, in `state`.
func _on_screen(sim: ObjectFunctions, slot: int, x: int, y: int, state: int) -> int:
	var base: int = slot * ObjectSim.OBJ_STRUCT_LENGTH
	sim.wram1[base + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN
	sim.wram1[base + ObjectSim.OBJ_SCREEN_Y_POS] = y
	sim.wram1[base + ObjectSim.OBJ_SCREEN_X_POS] = x
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_TOP] = 0xF0
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_BOTTOM] = 0
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_LEFT] = 0xF8
	sim.wram1[base + ObjectSim.OBJ_COLLBOX_RIGHT] = 8
	sim.wram1[base + ObjectSim.OBJ_STATE] = state
	return base


func test_a_thrown_object_knocks_the_first_it_meets_away_and_is_let_go() -> void:
	var sim: ObjectFunctions = _sim()
	var thrown: int = _on_screen(sim, 0, 80, 100, ObjectSim.OBJSTATE_4E)  # thrown left
	sim.wram1[thrown + ObjectSim.OBJ_FLAGS] |= ObjectSim.OBJFLAG_GRABBED
	var far: int = _on_screen(sim, 1, 140, 100, 0)
	var met: int = _on_screen(sim, 2, 72, 104, 0)
	sim.wGrabState = WarioRam.GRAB_THROW
	sim.handle_grabbed_object_collisions()
	assert_eq([sim.wram1[thrown + ObjectSim.OBJ_STATE], sim.wram1[met + ObjectSim.OBJ_STATE], sim.wram1[far + ObjectSim.OBJ_STATE]],
			[ObjectSim.OBJSTATE_29, ObjectSim.OBJSTATE_28, 0], "both knocked away, the far one untouched")
	assert_eq([sim.wram1[thrown + ObjectSim.OBJ_FLAGS] & ObjectSim.OBJFLAG_GRABBED,
			sim.wram1[met + ObjectSim.OBJ_FLAGS] & ObjectSim.OBJFLAG_NO_COLLISION], [0, ObjectSim.OBJFLAG_NO_COLLISION])
	assert_eq(sim.wGrabState, WarioRam.GRAB_THROW, "it met nothing held")


func test_a_held_object_meeting_another_ends_the_grab_both_wobbling_apart() -> void:
	var sim: ObjectFunctions = _sim()
	var held: int = _on_screen(sim, 0, 80, 100, ObjectSim.OBJSTATE_48)
	sim.wram1[held + ObjectSim.OBJ_FLAGS] |= ObjectSim.OBJFLAG_GRABBED
	var met: int = _on_screen(sim, 3, 86, 100, 0)
	sim.wGrabState = WarioRam.GRAB_IDLE
	sim.handle_grabbed_object_collisions()
	assert_eq([sim.wram1[held + ObjectSim.OBJ_STATE], sim.wram1[met + ObjectSim.OBJ_STATE], sim.wGrabState],
			[ObjectSim.OBJSTATE_WOBBLE_LEFT_START, ObjectSim.OBJSTATE_WOBBLE_RIGHT_START, 0])

