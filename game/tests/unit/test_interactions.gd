extends TestCase
## ProcessInteractions on invented data (no ROM bytes): the overlap test, the side, and what a
## sting, an attack, a step from above, coins, a key, and an electric object do to Wario and the
## object.


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	var framesets: Dictionary = {}
	for key: String in ["5f70", "5f7f", "4252", "425f", "5f94", "5f97", "5216", "5219", "4a6c", "4a71", "7b76", "7b79",
			"7414", "6b38", "6b49", "71bd", "640c", "63ec"]:
		framesets[key] = {"pairs": [[2, 4]]}
	sim.tables = WarioTables.from_document({"walk_vel_table": {"steps": []}, "jump_vel_tables": [], "framesets": framesets})
	sim.level = LevelCollision.new()
	var rows: Array = []
	for y: int in LevelCollision.HEIGHT:
		var row := PackedByteArray()
		row.resize(LevelCollision.WIDTH)
		rows.append(row.hex_encode())
	sim.level.set_rows(rows)
	var handlers: Array = []
	for i: int in 0x80:
		handlers.append("h06_4020")
	sim.level.room_handlers[0] = handlers
	# Wario standing at screen (80, 120): his box is -27..-1 by -9..9.
	sim.wWarioScreenXPos = 80
	sim.wWarioScreenYPos = 120
	sim.wWarioXPos = 0x0150
	sim.wWarioYPos = 0x0100
	sim.wCollisionBoxTop = byte(-27)
	sim.wCollisionBoxBottom = byte(-1)
	sim.wCollisionBoxLeft = byte(-9)
	sim.wCollisionBoxRight = 9
	sim.wWarioState = WarioRam.WST_WALKING
	sim.wDirection = WarioRam.DIRECTION_RIGHT
	return sim


## An active, on-screen object in slot 0 at screen (x, y) with a 16x16 box (-15..0 by -8..7).
func _object(sim: LevelSim, x: int, y: int, kind: int, facing_right: bool = false) -> int:
	sim.wram1[ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN
	sim.wram1[ObjectSim.OBJ_INTERACTION_TYPE] = kind
	sim.wram1[ObjectSim.OBJ_COLLBOX_TOP] = byte(-15)
	sim.wram1[ObjectSim.OBJ_COLLBOX_BOTTOM] = 0
	sim.wram1[ObjectSim.OBJ_COLLBOX_LEFT] = byte(-8)
	sim.wram1[ObjectSim.OBJ_COLLBOX_RIGHT] = 7
	sim.wram1[ObjectSim.OBJ_SCREEN_Y_POS] = y
	sim.wram1[ObjectSim.OBJ_SCREEN_X_POS] = x
	sim.wram1[ObjectSim.OBJ_SUBSTATE] = ObjectSim.OBJSUBFLAG_HDIR if facing_right else 0
	return 0


static func byte(value: int) -> int:
	return value & 0xFF


func test_boxes_apart_do_nothing() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 120, 120, ObjectStates.OBJ_INTERACTION_FRONT_STING)
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wram1[ObjectSim.OBJ_ACTION]], [WarioRam.WST_WALKING, 0])


func test_walking_into_a_sting_facing_wario_stings_him() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, ObjectStates.OBJ_INTERACTION_FRONT_STING, false)  # to his right, facing left
	sim.process_interactions()
	assert_eq(sim.wInteractionSide, ObjectSim.INTERACTION_RIGHT, "met on Wario's right")
	assert_eq([sim.wWarioState, sim.wInvincibleCounter, sim.wDirection, sim.wJumpVelTable],
			[WarioRam.WST_STUNG, 1, WarioRam.DIRECTION_LEFT, WarioRam.JUMP_VEL_KNOCK_BACK])
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wram1[ObjectSim.OBJ_UNK_1D]], [6, ObjectSim.INTERACTION_RIGHT])


func test_the_sting_behind_is_only_a_bump() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, ObjectStates.OBJ_INTERACTION_FRONT_STING, true)  # facing away from Wario
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wram1[ObjectSim.OBJ_ACTION]], [WarioRam.WST_ENEMY_BUMPING, 1])
	assert_eq(sim.wDirection, WarioRam.DIRECTION_LEFT, "knocked back away from it")


func test_an_attack_knocks_the_object_away_and_wario_stops() -> void:
	var sim: LevelSim = _sim()
	sim.wAttackCounter = 5
	_object(sim, 92, 120, ObjectStates.OBJ_INTERACTION_01)
	sim.process_interactions()
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], 2, "OBJACTION_ATTACK")
	assert_eq(sim.wWarioState, WarioRam.WST_IDLING, "on the ground, he idles")
	assert_eq(sim.wInteractionSide, ObjectSim.INTERACTION_RIGHT, "AttackObject sets the side the object is on")


func test_landing_on_top_bounces_wario_and_wobbles_the_object() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioState = WarioRam.WST_AIRBORNE
	sim.wJumpVelTable = WarioRam.JUMP_VEL_NORMAL
	sim.wJoypadDown = WarioRam.PAD_A
	_object(sim, 80, 132, ObjectStates.OBJ_INTERACTION_01)  # just below his feet
	sim.process_interactions()
	# His feet in its top: the shallow overlap is vertical, UP (the object's top), then the side he is on.
	assert_eq(sim.wInteractionSide & (ObjectSim.INTERACTION_UP | ObjectSim.INTERACTION_DOWN), ObjectSim.INTERACTION_UP)
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], 4, "OBJACTION_WOBBLE")
	assert_eq([sim.wDoFullJump, sim.wJumpVelIndex], [1, 0x0A], "a full jump from index $0a")


func test_a_musical_coin_counts_and_adds_ten_coins_and_the_pass_goes_on() -> void:
	var sim: LevelSim = _sim()
	sim.wNumCoins = 0x0095
	_object(sim, 80, 120, 0x0D)
	sim.process_interactions()
	assert_eq([sim.wNumMusicalCoins, sim.wNumCoins, sim.wram1[ObjectSim.OBJ_ACTION]], [1, 0x0105, 7])
	sim.wram1[ObjectSim.OBJ_ACTION] = 0
	sim.wNumCoins = 0x0995
	sim.process_interactions()
	assert_eq(sim.wNumCoins, 0x0999, "capped at 999")


func test_landing_on_a_walkable_object_stands_wario_on_it_and_the_pass_goes_on() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioState = WarioRam.WST_AIRBORNE
	sim.wJumpVelTable = WarioRam.JUMP_VEL_NORMAL
	sim.wJumpVelIndex = 0x20
	var y_before: int = sim.wWarioYPos
	_object(sim, 80, 133, 0x0C)  # its top at 118, his feet at 119: 1 px of overlap
	sim.wram1[32] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN  # a second object to reach
	sim.wram1[32 + ObjectSim.OBJ_INTERACTION_TYPE] = 0x0D
	sim.wram1[32 + ObjectSim.OBJ_COLLBOX_TOP] = byte(-15)
	sim.wram1[32 + ObjectSim.OBJ_COLLBOX_LEFT] = byte(-8)
	sim.wram1[32 + ObjectSim.OBJ_COLLBOX_RIGHT] = 7
	sim.wram1[32 + ObjectSim.OBJ_SCREEN_Y_POS] = 120
	sim.wram1[32 + ObjectSim.OBJ_SCREEN_X_POS] = 80
	sim.process_interactions()
	assert_eq([sim.wIsOnSteppableObject, sim.wram1[ObjectSim.OBJ_ACTION]], [1, 9], "stepped on (OBJACTION_STEP_ON)")
	assert_eq(sim.wWarioYPos, y_before - 1, "lifted onto its top by the overlap")
	assert_eq(sim.wWarioState, WarioRam.WST_IDLING, "the fall ends on it")
	assert_eq(sim.wNumMusicalCoins, 1, "the pass went on to the next object")


func test_an_electric_object_shocks_wario_who_faces_away_from_it_and_the_pass_ends() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 88, 120, 0x1C)  # OBJ_INTERACTION_ELECTRIC, right of Wario
	sim.wram1[32 + ObjectSim.OBJ_FLAGS] = ObjectSim.OBJFLAG_ACTIVE | ObjectSim.OBJFLAG_ON_SCREEN
	sim.wram1[32 + ObjectSim.OBJ_INTERACTION_TYPE] = 0x1B  # a coin in the next slot, not reached
	for offset: int in [ObjectSim.OBJ_COLLBOX_TOP, ObjectSim.OBJ_COLLBOX_LEFT, ObjectSim.OBJ_COLLBOX_RIGHT,
			ObjectSim.OBJ_SCREEN_Y_POS, ObjectSim.OBJ_SCREEN_X_POS]:
		sim.wram1[32 + offset] = sim.wram1[offset]
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wDirection],
			[WarioRam.WST_ELECTRIC_START, WarioRam.TRANSFORMATION_ELECTRIC, WarioRam.DIRECTION_LEFT])
	assert_eq([sim.wTouchState, sim.wStingTouchState, sim.wca94], [4, 4, 1], "touching objects makes them vanish")
	assert_eq([sim.wWarioFramesetPtr, sim.wWarioPalsPtr, sim.wWarioOAMPtr],
			[WarioRam.FRAMESET_ELECTRIC_STRUCK_LEFT, WarioRam.WARIO_ELECTRIC_PAL, WarioRam.OAM_1790E & 0xFFFF])
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], ObjectInteractions.OBJACTION_06)
	assert_eq([sim.wNumCoins, sim.wram1[32 + ObjectSim.OBJ_ACTION]], [0, 0], "the pass ended at the shock")


func test_an_invincible_wario_is_not_shocked_but_the_object_still_reacts() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 72, 120, 0x1C)
	sim.wInvincibleCounter = 5
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wTransformation], [WarioRam.WST_WALKING, 0])
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], ObjectInteractions.OBJACTION_06)


func test_a_key_sets_its_flag_and_pauses_the_game_for_100_loops() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 80, 120, 0x12)  # OBJ_INTERACTION_GREEN_KEY
	sim.process_interactions()
	assert_eq([sim.wKeyAndTreasureFlags, sim.wState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[1 << 2, ObjectInteractions.ST_COLLECT_KEY, ObjectInteractions.OBJACTION_07])
	var position: int = sim.wWarioXPos
	for loop: int in 99:
		sim.update_level()
	assert_eq([sim.wState, sim.wTimer], [ObjectInteractions.ST_COLLECT_KEY, 99])
	sim.update_level()
	assert_eq([sim.wState, sim.wTimer, sim.wWarioXPos], [ObjectInteractions.ST_LEVEL, 0, position],
			"the level goes on where it stopped")


func test_a_coin_counts_one_and_ends_the_pass_and_a_colour_coin_ten_and_goes_on() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 80, 120, 0x1B)
	sim.wNumCoins = 0x0099
	sim.process_interactions()
	assert_eq([sim.wNumCoins, sim.wram1[ObjectSim.OBJ_ACTION]], [0x0100, ObjectInteractions.OBJACTION_07], "BCD")
	sim = _sim()
	_object(sim, 80, 120, 0x4A)
	sim.wNumCoins = 0x0995
	sim.process_interactions()
	assert_eq(sim.wNumCoins, 0x0999, "capped at 999")


func test_silky_facing_wario_wraps_him_in_string_and_from_behind_only_bumps() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x19, false)  # OBJ_INTERACTION_SILKY, to his right, facing left
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wDirection],
			[WarioRam.WST_GETTING_WRAPPED_IN_STRING, WarioRam.TRANSFORMATION_BALL_O_STRING_WARIO, WarioRam.DIRECTION_LEFT])
	assert_eq([sim.wTouchState, sim.wWarioFramesetPtr, sim.wWarioPalsPtr],
			[WarioRam.TOUCH_ATTACK, WarioRam.FRAMESET_GETTING_WRAPPED, WarioRam.WARIO_STRING_PAL])
	sim = _sim()
	_object(sim, 92, 120, 0x19, true)  # facing away
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wTransformation], [WarioRam.WST_ENEMY_BUMPING, 0])


func test_fire_sets_wario_on_fire_for_600_frames() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 88, 120, 0x0E)  # OBJ_INTERACTION_FIRE
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wTransformationDuration, sim.wTouchState],
			[WarioRam.WST_ON_FIRE, WarioRam.TRANSFORMATION_HOT_WARIO, WarioRam.HOT_WARIO_DURATION, WarioRam.TOUCH_BUMP])
	assert_eq([sim.wWarioFramesetPtr, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.FRAMESET_SET_ON_FIRE_RIGHT, ObjectInteractions.OBJACTION_06])


func test_hot_wario_landing_on_an_object_burns_it_away() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 80, 134, ObjectStates.OBJ_INTERACTION_01)  # under his feet
	sim.wTransformation = WarioRam.TRANSFORMATION_HOT_WARIO
	sim.wTransformationProgress = 2
	sim.wWarioState = WarioRam.WST_HOT_AIRBORNE
	sim.process_interactions()
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], ObjectInteractions.OBJACTION_VANISH_TOUCH)


func test_food_makes_wario_fat_and_crouching_he_only_touches_it() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x1A, true)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wTransformationDuration, sim.wWarioState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.TRANSFORMATION_FAT_WARIO, WarioRam.FAT_WARIO_DURATION, WarioRam.WST_FAT_EATING, ObjectInteractions.OBJACTION_07])
	sim = _sim()
	sim.wIsCrouching = 1
	_object(sim, 92, 120, 0x1A, true)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wram1[ObjectSim.OBJ_ACTION] & 0x0F], [0, ObjectInteractions.OBJACTION_0D])


func test_omodonmeka_picks_up_wario_on_the_ground_and_is_only_touched_in_the_air() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x18, true)
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wAutoMoveState, sim.wJumpVelTable, sim.wPickedUpWiggleCounter, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.WST_PICKED_UP, 1, 1, WarioRam.NUM_WIGGLES_TO_ESCAPE, ObjectInteractions.OBJACTION_0C])
	sim = _sim()
	sim.wJumpVelTable = WarioRam.JUMP_VEL_NORMAL
	_object(sim, 92, 120, 0x18, true)
	sim.process_interactions()
	assert_true(sim.wWarioState != WarioRam.WST_PICKED_UP, "in the air: a touch")


func test_ice_freezes_wario_into_skates_unless_he_crouches_under_a_ceiling() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x27, true)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wTouchState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.TRANSFORMATION_ICE_SKATIN, WarioRam.WST_ICE_SKATIN_START, WarioRam.TOUCH_ATTACK, ObjectInteractions.OBJACTION_07])
	sim.process_interactions()
	assert_eq(sim.wWarioState, WarioRam.WST_ICE_SKATIN_START, "already frozen: nothing more")


func test_a_rail_is_grabbed_once() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x29, true)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wAutoMoveState, sim.wStingTouchState],
			[WarioRam.TRANSFORMATION_RAIL, WarioRam.WST_HANGING_RAIL, 1, WarioRam.TOUCH_VULNERABLE])


func test_a_tadpole_head_on_rolls_wario_and_from_behind_he_bounces_off_it() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x3C, false)  # to his right, facing him
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wWarioState, sim.wIsRolling, sim.wDirection],
			[ObjectInteractions.OBJACTION_06, WarioRam.WST_ROLLING_AIRBORNE, 2, WarioRam.DIRECTION_LEFT],
			"rolled the way it goes (ObjInteraction_RollingRock)")
	sim = _sim()
	_object(sim, 92, 120, 0x3C, true)  # facing away
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wDirection], [ObjectInteractions.OBJACTION_0A, WarioRam.DIRECTION_LEFT],
			"bounced off, facing it (Func_20e6a)")


func test_interaction_0a_only_bounces_wario_and_a_vulnerable_touch_state_is_the_originals_loop() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x0A)
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wDirection], [ObjectInteractions.OBJACTION_06, WarioRam.DIRECTION_LEFT])
	sim = _sim()
	sim.wTouchState = WarioRam.TOUCH_VULNERABLE
	_object(sim, 92, 120, 0x0A)
	sim.process_interactions()
	assert_true("Func_2023b with TOUCH_VULNERABLE (a loop in the original)" in sim.unported, "noted, not recursed")


func test_a_solid_object_pushes_wario_out_from_the_side_and_down_from_below() -> void:
	var sim: LevelSim = _sim()
	var x: int = sim.wWarioXPos
	_object(sim, 92, 120, 0x22)  # his right edge 89, its left 84
	sim.process_interactions()
	assert_eq([sim.wInteractionSide, sim.wc1c3, sim.wWarioXPos], [ObjectSim.INTERACTION_RIGHT, 5, x - 5], "pushed back by the overlap (89 - 84)")
	sim = _sim()
	sim.wWarioState = WarioRam.WST_AIRBORNE
	sim.wJumpVelTable = WarioRam.JUMP_VEL_NORMAL
	var y: int = sim.wWarioYPos
	_object(sim, 80, 95, 0x22)  # its bottom at 95, his top at 93
	sim.process_interactions()
	assert_eq(sim.wInteractionSide & (ObjectSim.INTERACTION_UP | ObjectSim.INTERACTION_DOWN), ObjectSim.INTERACTION_DOWN)
	assert_eq([sim.wWarioYPos, sim.wWarioState], [y + sim.wc1c2, WarioRam.WST_AIRBORNE], "pushed down by the overlap, falling (Func_2168b)")


func test_a_falling_omodon_on_wario_flattens_him_8_px_left_of_it() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 80, 95, 0x23)
	sim.wram1[ObjectSim.OBJ_X_POS] = 0x58
	sim.wram1[ObjectSim.OBJ_X_POS + 1] = 0x01
	sim.process_interactions()
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], ObjectInteractions.OBJACTION_FLATTEN)
	assert_eq([sim.wWarioState, sim.wTransformation, sim.wWarioXPos, sim.wWarioStateCounter, sim.wAutoMoveState],
			[WarioRam.WST_GETTING_FLAT_AIRBORNE, WarioRam.TRANSFORMATION_FLAT_WARIO, 0x0150, 1, 1], "SetState_FlatAirborne")
	assert_eq([sim.wCollisionBoxTop, sim.wCollisionBoxLeft, sim.wCollisionBoxRight], [byte(-8), byte(-11), 11])


func test_a_smash_attack_on_a_stove_vanishes_it_and_an_attack_from_the_side_knocks_it_back() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioState = WarioRam.WST_AIRBORNE
	sim.wJumpVelTable = WarioRam.JUMP_VEL_NORMAL
	sim.wIsSmashAttacking = 1
	_object(sim, 80, 133, 0x2F)  # just below his feet
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wDoFullJump, sim.wJumpVelIndex],
			[ObjectInteractions.OBJACTION_SMASH_ATTACK_WALKABLE, 1, 0x0A], "Wario jumps off it (Func_20602)")
	sim = _sim()
	sim.wAttackCounter = 5
	var x: int = sim.wWarioXPos
	_object(sim, 92, 120, 0x2F)
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wWarioXPos], [ObjectInteractions.OBJACTION_ATTACK, x - 5], "attacked, and he is pushed out")


func test_with_the_grab_glove_wario_steps_on_an_object_facing_away_and_picks_it_up_facing_it() -> void:
	var sim: LevelSim = _sim()
	sim.wPowerUpLevel = ObjectInteractions.GRAB_GLOVE
	sim.wDirection = WarioRam.DIRECTION_LEFT
	_object(sim, 92, 120, ObjectStates.OBJ_INTERACTION_00)  # to his right, behind him
	sim.process_interactions()
	assert_eq(sim.wram1[ObjectSim.OBJ_ACTION], ObjectInteractions.OBJACTION_WOBBLE, "stepped on")
	assert_true(not "Func_20b6b pick up" in sim.unported)
	sim = _sim()
	sim.wPowerUpLevel = ObjectInteractions.GRAB_GLOVE
	_object(sim, 92, 120, 0x3B)  # interaction $3b from the side is $00's
	sim.process_interactions()
	assert_eq([sim.wWarioState, sim.wGrabState, sim.wram1[ObjectSim.OBJ_ACTION], sim.wWarioFramesetPtr],
			[WarioRam.WST_PICKING_UP, WarioRam.GRAB_PICK_UP, ObjectInteractions.OBJACTION_PICK_UP, 0x640C], "facing it: picked up")


func test_fire_bot_facing_wario_sets_him_on_fire_and_from_behind_is_only_touched() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x21, false)  # to his right, facing him
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState], [WarioRam.TRANSFORMATION_HOT_WARIO, WarioRam.WST_ON_FIRE])
	sim = _sim()
	_object(sim, 92, 120, 0x21, true)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[0, WarioRam.WST_ENEMY_BUMPING, ObjectInteractions.OBJACTION_BUMP], "bumped")


func test_a_zombie_head_makes_wario_a_zombie_and_a_zombie_touching_one_vanishes_it_and_is_knocked_back() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x1F)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wTouchState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.TRANSFORMATION_ZOMBIE_WARIO, WarioRam.WST_ZOMBIE_IDLING, WarioRam.TOUCH_VANISH, ObjectInteractions.OBJACTION_06])
	sim.wram1[ObjectSim.OBJ_ACTION] = 0
	sim.process_interactions()
	assert_eq([sim.wram1[ObjectSim.OBJ_ACTION], sim.wWarioState], [ObjectInteractions.OBJACTION_VANISH_TOUCH, WarioRam.WST_ZOMBIE_KNOCK_BACK])
	sim = _sim()
	sim.wInvincibleCounter = 5
	_object(sim, 92, 120, 0x1F)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wram1[ObjectSim.OBJ_ACTION]], [0, ObjectInteractions.OBJACTION_0D], "invincible: it only reacts")


func test_teruteru_from_below_blinds_wario_and_from_the_side_is_only_touched() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 80, 95, 0x38)  # its bottom at his head
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wTouchState, sim.wStingTouchState, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.TRANSFORMATION_BLIND, WarioRam.WST_BLIND_IDLING, WarioRam.TOUCH_BUMP, WarioRam.TOUCH_VULNERABLE,
			ObjectInteractions.OBJACTION_06])
	sim = _sim()
	_object(sim, 92, 120, 0x38)
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState], [0, WarioRam.WST_ENEMY_BUMPING], "bumped")


func test_a_bouncy_object_met_head_on_makes_wario_bouncy_for_900_frames() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x20, false)  # to his right, facing him
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wTransformationDuration, sim.wram1[ObjectSim.OBJ_ACTION]],
			[WarioRam.TRANSFORMATION_BOUNCY_WARIO, WarioRam.WST_BOUNCY_START, WarioRam.BOUNCY_WARIO_DURATION,
			ObjectInteractions.OBJACTION_06])


func test_the_orange_bird_met_head_on_makes_wario_crazy() -> void:
	var sim: LevelSim = _sim()
	_object(sim, 92, 120, 0x24, false)  # to his right, facing him
	sim.process_interactions()
	assert_eq([sim.wTransformation, sim.wWarioState, sim.wTouchState, sim.wDirection],
			[WarioRam.TRANSFORMATION_CRAZY_WARIO, WarioRam.WST_CRAZY_SPINNING, WarioRam.TOUCH_ATTACK, WarioRam.DIRECTION_LEFT],
			"spinning the way it faces")
