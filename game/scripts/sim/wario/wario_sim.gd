class_name WarioSim
extends WarioBlocks
## Wario's per-frame state update, ported from UpdateWarioStates
## (src/engine/level/wario_states_1.asm) and the helpers it calls in home/
## (ElectroDeoxys/warioland3 @560fce6). Ported states: idling, walking, turning, airborne,
## landing, attacking, attacking airborne, bumping, crouching, crouch walking, crouch airborne,
## crouch sliding, sliding, rolling, rolling airborne, stung, stung recovery, and the ladder states.
## Any other state, and any path into a routine
## that is not ported yet, is
## recorded in `unported` by name; the variables are then incomplete for that frame.
##
## One call to update() is one game frame of UpdateLevel's Wario part: wBlockFuncWarioFlag
## is TRUE while UpdateWarioStates runs (src/engine/level/update_level.asm).
## Research note: docs/02-research/wario-movement.md.

const PORTED_STATES: PackedInt32Array = [WST_IDLING, WST_WALKING, WST_TURNING, WST_AIRBORNE, WST_LANDING,
		WST_ATTACKING, WST_ATTACKING_AIRBORNE, WST_BUMPING, WST_CROUCHING, WST_CROUCH_WALKING,
		WST_CROUCH_AIRBORNE, WST_CROUCH_SLIDING, WST_SLIDING, WST_ROLLING, WST_ROLLING_AIRBORNE,
		WST_STUNG, WST_STUNG_RECOVERY, WST_LADDER_CLIMBING, WST_LADDER_IDLING, WST_LADDER_SHAKE_SLIDING,
		WST_GETTING_OFF_LADDER, WST_LADDER_SLIDING, WST_LADDER_SCRATCHING, WST_ENTERING_DOOR,
		WST_PIPE_GOING_DOWN, WST_PIPE_GOING_UP,
		WST_TELEPORTING, WST_WATER_TELEPORTING, WST_TURNING_INVISIBLE, WST_PUFFY_INFLATING, WST_PUFFY_RISING, WST_PUFFY_TURNING, WST_PUFFY_DEFLATING,
		WST_SPLIT_HIT, WST_SPLIT_KNOCKED_BACK, WST_SPLITTING, WST_SPLITTING_AIRBORNE,
		WST_VAMPIRE_IDLING, WST_VAMPIRE_WALKING, WST_VAMPIRE_TURNING, WST_VAMPIRE_AIRBORNE, WST_BAT_TRANSFORMING,
		WST_BAT_IDLING, WST_VAMPIRE_TRANSFORMING, WST_BAT_FLYING, WST_BAT_FALLING, WST_IN_BUBBLE,
		WST_GRABBING_OWL, WST_OWL_SLOW, WST_OWL_FAST, WST_RELEASING_OWL, WST_FALLING_FROM_OWL,
		WST_SNOWMAN_START, WST_SNOWMAN_IDLE, WST_SNOWMAN_WALKING, WST_SNOWMAN_TURNING, WST_SNOWMAN_AIRBORNE,
		WST_SNOWMAN_LANDING, WST_SNOWMAN_BUMPED, WST_SNOWBALL_ROLLING, WST_SNOWBALL_AIRBORNE, WST_SNOWBALL_CRASH,
		WST_FAN_START, WST_FAN_LIFTING, WST_FAN_TURNING, WST_FAN_SPINNING, WST_FAN_RECOVERING,
		WST_MAGIC_RISING, WST_MAGIC_STOPPING, WST_MAGIC_RECOVERING, WST_FENCE_SHAKE_SLIDING,
		WST_BALL_START, WST_BALL_BOUNCING, WST_BALL_AIRBORNE, WST_BALL_SHOT, WST_BALL_THROWN, WST_BALL_SENT_UPWARDS,
		WST_BALL_TURNING, WST_LAUNCHED, WST_LAUCH_CRASH, WST_DRAGGED_DOWN,
		WST_FAT_BUMPING, WST_FAT_EATING, WST_FAT_IDLING, WST_FAT_WALKING, WST_FAT_TURNING, WST_FAT_AIRBORNE,
		WST_FAT_LANDING, WST_FAT_SINKING, WST_FAT_RECOVERING,
		WST_HANGING_RAIL, WST_ICE_SKATIN_START, WST_ICE_SKATIN, WST_ICE_SKATIN_AIRBORNE, WST_ICE_SKATIN_CRASH,
		WST_PICKED_UP, WST_GROUND_SHAKE_STUNNED, WST_ENEMY_BUMPING, WST_SAND_FALLING, WST_SAND_JUMPING, WST_SAND_IDLING, WST_SAND_WALKING, WST_SAND_TURNING,
		WST_DIVING, WST_SUBMERGED, WST_WATER_SURFACE_IDLING, WST_WATER_SURFACE_MOVING, WST_UNDERWATER_THRUSTING,
		WST_SWIM_KNOCK_BACK, WST_WATER_STUNG, WST_TRYING_SUBMERGE,
		WST_ON_FIRE, WST_ON_FIRE_AIRBORNE, WST_HOT, WST_HOT_AIRBORNE, WST_BURNT,
		WST_GET_TREASURE_START, WST_GET_TREASURE_WALK_1, WST_GET_TREASURE_TURN_FRONT_1, WST_GET_TREASURE_LAUGH,
		WST_GET_TREASURE_TURN_BACK, WST_GET_TREASURE_OPEN, WST_GET_TREASURE_TURN_WALK, WST_GET_TREASURE_WALK_2,
		WST_GET_TREASURE_TURN_FRONT_2, WST_GET_TREASURE_LOOK_FRONT, WST_GET_TREASURE_CLEAR,
		WST_ELECTRIC_START, WST_ELECTRIC, WST_ELECTRIC_DIZZY, WST_GETTING_WRAPPED_IN_STRING, WST_BALL_O_STRING,
		WST_BALL_O_STRING_AIRBORNE, WST_BALL_O_STRING_KNOCK_BACK, WST_GETTING_UNWRAPPED_IN_STRING,
		WST_BALL_O_STRING_DIZZY, WST_SMASH_ATTACKING, WST_SLIPPING, WST_PICKING_UP, WST_GRAB_IDLING,
		WST_GRAB_WALKING, WST_GRAB_AIRBORNE, WST_THROW_CHARGING, WST_THROW_FULLY_CHARGED, WST_THROWING,
		WST_THROWING_AIRBORNE, WST_GRAB_SMASH_ATTACKING, WST_GRAB_SLIPPING, WST_CROUCH_SLIPPING, WST_GETTING_FLAT_AIRBORNE, WST_GETTING_FLAT, WST_FLAT_IDLING, WST_FLAT_WALKING,
		WST_FLAT_JUMPING, WST_FLAT_FALLING, WST_FLAT_STRETCHING, WST_FLAT_SINKING, WST_FLAT_STRETCHING_UNDERWATER,
		WST_FLAT_SQUISHED, WST_FLAT_SQUISHED_LIFTING, WST_ZOMBIE_IDLING, WST_ZOMBIE_WALKING, WST_ZOMBIE_TURNING,
		WST_ZOMBIE_AIRBORNE, WST_ZOMBIE_LANDING, WST_ZOMBIE_SLIPPING_THROUGH_FLOOR, WST_ZOMBIE_RECOVERING,
		WST_ZOMBIE_KNOCK_BACK, WST_ZOMBIE_WRITHING, WST_BLIND_IDLING, WST_BLIND_WALKING, WST_BLIND_TURNING,
		WST_BLIND_AIRBORNE, WST_CRAZY_SPINNING, WST_CRAZY_DIZZY, WST_CRAZY, WST_CRAZY_TURNING, WST_CRAZY_AIRBORNE,
		WST_BOUNCY_START, WST_BOUNCY_FLOOR, WST_BOUNCY_AIRBORNE, WST_BOUNCY_CEILING,
		WST_BOUNCY_UPSIDE_DOWN, WST_BOUNCY_UPSIDE_DOWN_LANDING, WST_BOUNCY_LAST_BOUNCE]

var tables: WarioTables = null


## Wario's part of StartRoom_FromLevelStart (src/engine/level/start_room.asm): the variables it
## clears (with ClearTransformationValues; the level's time and two unused bytes are not
## simulated), the room's camera configuration (LoadRoom), the spawn point and floor
## (SetWarioPositionToSpawn, UpdateFloor), then facing right, SetState_Idling, and WarioDefaultPal.
## Anything else keeps the value it had, as in the original. Objects and the camera are not part
## of this.
func start_level(level_room_id: int, x: int, y: int, camera_config: int) -> void:
	unported.clear()
	handlers_run.clear()
	wIsBossBattle = 0
	wLevelRoomID = level_room_id
	wLevelEndScreen = 0
	wNumMusicalCoins = 0
	wFloorTransitionDir = 0
	wFloorTransitionTimer = 0
	wCameraYDelta = 0
	wCameraXDelta = 0
	wScrollUpEdge = 0
	wScrollDownEdge = 0
	wIsIntangible = 0
	wInvincibleCounter = 0
	wIsMinigameCleared = 0
	wIsRolling = 0
	wIsGettingOffLadder = 0
	wWarioAttributes = 0
	wSwitchStateUpdated = 0
	wBossState = 0
	wSwimVelIndex = 0
	wWaterSurfaceFloatingCounter = 0
	clear_transformation_values()
	wInvisibleFrame = 0
	wCameraRoomYScrollLimit = 0
	wIsOnSteppableObject = 0
	wGroundShakeCounter = 0
	wSCYShake = 0
	wSwimmingDirectionInput = 0
	wAnimatedTilesFrameDuration = 0
	wRoomPalCycleDuration = 0
	wRoomAnimatedTilesEnabled = 0
	wRoomAnimatedPalsEnabled = 0
	wWaterCurrent = 0
	wLastWaterCurrent = 0
	wCurWaterCurrent = 0
	wCameraConfigFlags = camera_config
	wWarioXPos = word(x)
	wWarioYPos = word(y)
	hXPos = wWarioXPos
	hYPos = wWarioYPos
	# UpdateFloor only with floor transitions (and, in the original, wceef's bits 2-5 clear: they mark
	# a level resumed from a save, which this start, from the map, never is); otherwise wFloor keeps
	# the value it had.
	if _transitions_enabled():
		wFloor = get_floor_for_y_pos()
	wDirection = DIRECTION_RIGHT
	# Outside UpdateLevel, so wBlockFuncWarioFlag is clear while SetState_Idling checks above.
	wBlockFuncWarioFlag = 0
	set_state_idling()
	set_wario_pal(WARIO_DEFAULT_PAL)


## UpdateLevel's call of UpdateWarioStates (skipped during a floor transition).
func update() -> void:
	unported.clear()
	handlers_run.clear()
	if wFloorTransitionDir != 0:
		return
	wBlockFuncWarioFlag = 1
	update_wario_states()
	wBlockFuncWarioFlag = 0


## UpdateWarioStates
func update_wario_states() -> void:
	if wCoinCooldown != 0:
		wCoinCooldown -= 1
	handle_ground_shake()
	handle_invincibility()
	match wWarioState:
		WST_IDLING:
			update_state_idling()
		WST_WALKING:
			update_state_walking()
		WST_TURNING:
			update_state_turning()
		WST_AIRBORNE:
			update_state_airborne()
		WST_LANDING:
			update_state_landing()
		WST_ATTACKING:
			update_state_attacking()
		WST_ATTACKING_AIRBORNE:
			update_state_attacking_airborne()
		WST_BUMPING:
			update_state_bumping()
		WST_CROUCHING:
			update_state_crouching()
		WST_CROUCH_WALKING:
			update_state_crouch_walking()
		WST_CROUCH_AIRBORNE:
			update_state_crouch_airborne()
		WST_CROUCH_SLIDING:
			update_state_crouch_sliding()
		WST_SLIDING:
			update_state_sliding()
		WST_ROLLING:
			update_state_rolling()
		WST_ROLLING_AIRBORNE:
			update_state_rolling_airborne()
		WST_STUNG:
			update_state_stung()
		WST_STUNG_RECOVERY:
			update_state_stung_recovery()
		WST_LADDER_CLIMBING:
			update_state_ladder_climbing()
		WST_LADDER_IDLING:
			update_state_ladder_idling()
		WST_LADDER_SHAKE_SLIDING:
			update_state_ladder_shake_sliding()
		WST_GETTING_OFF_LADDER:
			update_state_getting_off_ladder()
		WST_LADDER_SLIDING:
			update_state_ladder_sliding()
		WST_LADDER_SCRATCHING:
			update_state_ladder_scratching()
		WST_ENTERING_DOOR:
			update_state_entering_door()
		WST_VAMPIRE_IDLING:
			update_state_vampire_idling()
		WST_VAMPIRE_WALKING:
			update_state_vampire_walking()
		WST_VAMPIRE_TURNING:
			update_state_vampire_turning()
		WST_VAMPIRE_AIRBORNE:
			update_state_vampire_airborne()
		WST_BAT_TRANSFORMING:
			update_state_bat_transforming()
		WST_BAT_IDLING:
			update_state_bat_idling()
		WST_VAMPIRE_TRANSFORMING:
			update_state_vampire_transforming()
		WST_BAT_FLYING:
			update_state_bat_flying()
		WST_BAT_FALLING:
			update_state_bat_falling()
		WST_IN_BUBBLE:
			update_state_in_bubble()
		WST_BALL_START:
			apply_jump_velocity()
			if check_airborne_collision() != 0:
				update_pos_y()
				_ball_land(false)
		WST_BALL_BOUNCING:
			update_wario_animation_3()
			if wWarioAnimationEnded != 0:
				set_state_ball_airborne()
		WST_BALL_AIRBORNE:
			update_state_ball_airborne()
		WST_BALL_SHOT:
			update_state_ball_shot()
		WST_BALL_THROWN:
			update_state_ball_thrown()
		WST_BALL_SENT_UPWARDS:
			update_state_ball_sent_upwards()
		WST_BALL_TURNING:
			update_wario_animation_3()
			if wWarioAnimationEnded != 0:
				set_state_ball_airborne()
		WST_LAUNCHED:
			update_state_launched()
		WST_DRAGGED_DOWN:
			update_state_dragged_down()
		WST_FENCE_SHAKE_SLIDING:
			update_state_fence_shake_sliding()
		WST_LAUCH_CRASH:
			update_wario_animation_3()
			if wWarioAnimationEnded != 0:
				recover_submerged()  # UpdateState_LaunchCrash: Func_2ad6a
		WST_MAGIC_RISING:
			update_state_magic_rising()
		WST_MAGIC_STOPPING:
			wWarioStateCounter = byte(wWarioStateCounter + 1)
			if wWarioStateCounter >= 0x20:
				recover_from_transformation()
		WST_MAGIC_RECOVERING:
			recover_from_transformation()
		WST_FAN_START:
			update_state_fan_start()
		WST_FAN_LIFTING:
			update_state_fan_lifting()
		WST_FAN_TURNING:
			update_state_fan_turning()
		WST_FAN_SPINNING:
			update_state_fan_spinning()
		WST_FAN_RECOVERING:
			update_wario_animation_3()
			if wWarioAnimationEnded != 0:
				recover_from_transformation_without_invincibility()
		WST_SNOWMAN_START:
			update_state_snowman_start()
		WST_SNOWMAN_IDLE:
			update_state_snowman_idle()
		WST_SNOWMAN_WALKING:
			update_state_snowman_walking()
		WST_SNOWMAN_TURNING:
			update_state_snowman_turning()
		WST_SNOWMAN_AIRBORNE:
			update_state_snowman_airborne()
		WST_SNOWMAN_LANDING:
			update_wario_animation_2()
			if wGroundShakeCounter == 0:
				set_state_snowman_idle()
		WST_SNOWMAN_BUMPED:
			update_wario_animation_2()
			if wWarioAnimationEnded != 0:
				set_state_snowman_idle()
		WST_SNOWBALL_ROLLING:
			update_state_snowball_rolling()
		WST_SNOWBALL_AIRBORNE:
			update_state_snowball_airborne()
		WST_SNOWBALL_CRASH:
			update_wario_animation_2()
			if wWarioAnimationEnded != 0:
				get_pos()
				create_particle(PARTICLE_SNOW)
				recover_from_transformation()
		WST_GRABBING_OWL:
			update_state_grabbing_owl()
		WST_OWL_SLOW:
			update_state_owl_slow()
		WST_OWL_FAST:
			update_state_owl_fast()
		WST_RELEASING_OWL:
			update_state_releasing_owl()
		WST_FALLING_FROM_OWL:
			update_state_falling_from_owl()
		WST_SPLIT_HIT:
			update_state_split_hit()
		WST_SPLIT_KNOCKED_BACK:
			update_state_split_knocked_back()
		WST_SPLITTING:
			update_state_splitting()
		WST_SPLITTING_AIRBORNE:
			update_state_splitting_airborne()
		WST_TELEPORTING:
			update_state_teleporting(false)
		WST_WATER_TELEPORTING:
			update_state_teleporting(true)
		WST_TURNING_INVISIBLE:
			update_wario_animation()
			if wWarioAnimationEnded != 0:
				wIsIntangible = 0
				wTransformation = TRANSFORMATION_INVISIBLE_WARIO
				set_state_idling()
		WST_PUFFY_INFLATING:
			update_state_puffy_inflating()
		WST_PUFFY_RISING:
			update_state_puffy_rising()
		WST_PUFFY_TURNING:
			update_state_puffy_turning()
		WST_PUFFY_DEFLATING:
			update_state_puffy_deflating()
		WST_PIPE_GOING_DOWN:
			update_state_pipe(true)
		WST_PIPE_GOING_UP:
			update_state_pipe(false)
		WST_ELECTRIC_START:
			update_state_electric_start()
		WST_ELECTRIC:
			update_state_electric()
		WST_ELECTRIC_DIZZY:
			update_state_electric_dizzy()
		WST_ENEMY_BUMPING:
			update_state_enemy_bumping()
		WST_HANGING_RAIL:
			update_state_hanging_rail()
		WST_ICE_SKATIN_START:
			update_state_ice_skatin_start()
		WST_ICE_SKATIN:
			update_state_ice_skatin()
		WST_ICE_SKATIN_AIRBORNE:
			update_state_ice_skatin_airborne()
		WST_ICE_SKATIN_CRASH:
			update_state_ice_skatin_crash()
		WST_PICKED_UP:
			update_state_picked_up()
		WST_GROUND_SHAKE_STUNNED:
			update_state_ground_shake_stunned()
		WST_FAT_BUMPING:
			update_state_fat_bumping()
		WST_FAT_EATING:
			update_state_fat_eating()
		WST_FAT_IDLING:
			update_state_fat_idling()
		WST_FAT_WALKING:
			update_state_fat_walking()
		WST_FAT_TURNING:
			update_state_fat_turning()
		WST_FAT_AIRBORNE:
			update_state_fat_airborne()
		WST_FAT_LANDING:
			update_state_fat_landing()
		WST_FAT_SINKING:
			update_state_fat_sinking()
		WST_FAT_RECOVERING:
			update_state_fat_recovering()
		WST_SAND_FALLING:
			update_state_sand_falling()
		WST_SAND_JUMPING:
			update_state_sand_jumping()
		WST_SAND_IDLING:
			update_state_sand_idling()
		WST_SAND_WALKING:
			update_state_sand_walking()
		WST_SAND_TURNING:
			update_state_sand_turning()
		WST_DIVING:
			update_state_diving()
		WST_SUBMERGED:
			update_state_submerged()
		WST_WATER_SURFACE_IDLING:
			update_state_water_surface_idling()
		WST_WATER_SURFACE_MOVING:
			update_state_water_surface_moving()
		WST_UNDERWATER_THRUSTING:
			update_state_underwater_thrusting()
		WST_SWIM_KNOCK_BACK:
			update_state_swim_knock_back()
		WST_WATER_STUNG:
			update_state_water_stung()
		WST_TRYING_SUBMERGE:
			update_state_trying_submerge()
		WST_GET_TREASURE_START:
			update_state_get_treasure_start()
		WST_GET_TREASURE_WALK_1, WST_GET_TREASURE_WALK_2:
			update_state_get_treasure_walk()
		WST_GET_TREASURE_TURN_FRONT_1, WST_GET_TREASURE_TURN_FRONT_2:
			update_state_get_treasure_turn_front()
		WST_GET_TREASURE_LAUGH:
			update_state_get_treasure_laugh()
		WST_GET_TREASURE_TURN_BACK:
			update_state_get_treasure_turn_back()
		WST_GET_TREASURE_OPEN:
			update_state_get_treasure_open()
		WST_GET_TREASURE_TURN_WALK:
			update_state_get_treasure_turn_walk()
		WST_GET_TREASURE_LOOK_FRONT:
			update_state_get_treasure_look_front()
		WST_GET_TREASURE_CLEAR:
			update_state_get_treasure_clear()
		WST_ON_FIRE:
			update_state_on_fire()
		WST_ON_FIRE_AIRBORNE:
			update_state_on_fire_airborne()
		WST_HOT:
			update_state_hot()
		WST_HOT_AIRBORNE:
			update_state_hot_airborne()
		WST_BURNT:
			update_state_burnt()
		WST_SMASH_ATTACKING:
			update_state_smash_attacking()
		WST_PICKING_UP:
			update_state_picking_up()
		WST_GRAB_IDLING:
			update_state_grab_idling()
		WST_GRAB_WALKING:
			update_state_grab_walking()
		WST_GRAB_AIRBORNE:
			update_state_grab_airborne()
		WST_THROW_CHARGING:
			update_state_throw_charging()
		WST_THROW_FULLY_CHARGED:
			update_state_throw_fully_charged()
		WST_THROWING:
			update_state_throwing()
		WST_THROWING_AIRBORNE:
			update_state_throwing_airborne()
		WST_GRAB_SMASH_ATTACKING:
			update_state_grab_smash_attacking()
		WST_GRAB_SLIPPING:
			update_state_grab_slipping()
		WST_SLIPPING:
			update_state_slipping()
		WST_CROUCH_SLIPPING:
			update_state_crouch_slipping()
		WST_GETTING_FLAT_AIRBORNE:
			update_state_getting_flat_airborne()
		WST_GETTING_FLAT:
			update_state_getting_flat()
		WST_FLAT_IDLING:
			update_state_flat_idling()
		WST_FLAT_WALKING:
			update_state_flat_walking()
		WST_FLAT_JUMPING:
			update_state_flat_jumping()
		WST_FLAT_FALLING:
			update_state_flat_falling()
		WST_FLAT_STRETCHING:
			update_state_flat_stretching()
		WST_FLAT_SINKING:
			update_state_flat_sinking()
		WST_FLAT_STRETCHING_UNDERWATER:
			update_state_flat_stretching_underwater()
		WST_FLAT_SQUISHED:
			pass  # UpdateState_FlatSquished: nothing
		WST_FLAT_SQUISHED_LIFTING:
			update_state_flat_squished_lifting()
		WST_ZOMBIE_IDLING:
			update_state_zombie_idling()
		WST_ZOMBIE_WALKING:
			update_state_zombie_walking()
		WST_ZOMBIE_TURNING:
			update_state_zombie_turning()
		WST_ZOMBIE_AIRBORNE:
			update_state_zombie_airborne()
		WST_ZOMBIE_LANDING:
			update_state_zombie_landing()
		WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
			update_state_zombie_slipping_through_floor()
		WST_ZOMBIE_RECOVERING:
			update_state_zombie_recovering()
		WST_ZOMBIE_KNOCK_BACK:
			update_state_zombie_knock_back()
		WST_ZOMBIE_WRITHING:
			update_state_zombie_writhing()
		WST_CRAZY_SPINNING:
			update_state_crazy_spinning()
		WST_CRAZY_DIZZY:
			update_state_crazy_dizzy()
		WST_CRAZY:
			update_state_crazy()
		WST_CRAZY_TURNING:
			update_state_crazy_turning()
		WST_CRAZY_AIRBORNE:
			update_state_crazy_airborne()
		WST_BOUNCY_START:
			update_state_bouncy_start()
		WST_BOUNCY_FLOOR:
			update_state_bouncy_floor()
		WST_BOUNCY_AIRBORNE:
			update_state_bouncy_airborne()
		WST_BOUNCY_CEILING:
			update_state_bouncy_ceiling()
		WST_BOUNCY_UPSIDE_DOWN:
			update_state_bouncy_upside_down()
		WST_BOUNCY_UPSIDE_DOWN_LANDING:
			update_state_bouncy_upside_down_landing()
		WST_BOUNCY_LAST_BOUNCE:
			update_state_bouncy_last_bounce()
		WST_BLIND_IDLING:
			update_state_blind_idling()
		WST_BLIND_WALKING:
			update_state_blind_walking()
		WST_BLIND_TURNING:
			update_state_blind_turning()
		WST_BLIND_AIRBORNE:
			update_state_blind_airborne()
		WST_GETTING_WRAPPED_IN_STRING:
			update_state_getting_wrapped_in_string()
		WST_BALL_O_STRING:
			update_state_ball_o_string()
		WST_BALL_O_STRING_AIRBORNE:
			update_state_ball_o_string_airborne()
		WST_BALL_O_STRING_KNOCK_BACK:
			update_state_ball_o_string_knock_back()
		WST_GETTING_UNWRAPPED_IN_STRING:
			update_state_getting_unwrapped_in_string()
		WST_BALL_O_STRING_DIZZY:
			update_state_ball_o_string_dizzy()
		_:
			note_unported("UpdateWarioStates state $%02x" % wWarioState)


## HandleGroundShake: while the ground shakes (wGroundShakeCounter), the screen shakes 2 px in
## alternate pairs of frames (wSCYShake). With $10 or more left, Wario standing (not shaking it
## himself, transformed, in water, intangible, on an object, or getting off a ladder) is stunned
## instead that frame: on a ladder he slides off, elsewhere he is knocked up.
func handle_ground_shake() -> void:
	if wLevelEndScreen != 0:
		return
	if wGroundShakeCounter == 0:
		wIsWarioGroundShaking = 0
		return
	if wGroundShakeCounter >= 0x10 and wIsGettingOffLadder == 0 and wIsWarioGroundShaking == 0 \
			and wJumpVelTable == 0 and wWaterInteraction == 0 and wTransformation == 0 \
			and wRoomTransitionParam == 0 and wIsIntangible == 0 and wIsOnSteppableObject == 0 \
			and wWarioState != WST_GROUND_SHAKE_STUNNED:
		_ground_shake_stun()
		return
	wGroundShakeCounter -= 1
	wSCYShake = 2 if (wGroundShakeCounter & 0b10) != 0 else 0


## HandleGroundShake.wario_shake_stun
func _ground_shake_stun() -> void:
	if wWarioState in [WST_LADDER_CLIMBING, WST_LADDER_IDLING, WST_LADDER_SCRATCHING]:
		_set_state_ladder_shake_stunned()
		return
	wWarioState = WST_GROUND_SHAKE_STUNNED
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wAttackCounter = 0
	wIsRolling = 0
	wGrabState = 0
	wCollisionBoxTop = byte(-15)
	if wIsCrouching == 0:
		wCollisionBoxTop = byte(-27)
		wJumpVelIndex = 10
		wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = 0x5F7F if wDirection != DIRECTION_LEFT else 0x5F70
	update_wario_animation()


## SetState_LadderShakeStunned: sliding off the ladder (SFX_SLIDE not simulated).
func _set_state_ladder_shake_stunned() -> void:
	wWarioState = WST_LADDER_SHAKE_SLIDING
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsGettingOffLadder = 0
	wJumpVelTable = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5948
	update_wario_animation()


## UpdateState_PickedUp: held by an object (wAutoMoveState); pressing A, B, or the way he faces
## away from wiggles him round, and 6 wiggles, each within 32 frames of the last, free him (a
## fall). The counters start again after 32 frames without one.
func update_state_picked_up() -> void:
	var away: int = PAD_RIGHT if wDirection == DIRECTION_LEFT else PAD_LEFT
	if (wJoypadPressed & (PAD_A | PAD_B | away)) == 0:
		update_wario_animation()
		wPickedUpFrameCounter = byte(wPickedUpFrameCounter - 1)
		if wPickedUpFrameCounter != 0:
			return
		wPickedUpFrameCounter = MAX_PICKED_UP_FRAME_COUNTER
		wPickedUpWiggleCounter = NUM_WIGGLES_TO_ESCAPE
		return
	wPickedUpFrameCounter = MAX_PICKED_UP_FRAME_COUNTER
	wDirection ^= 1
	wWarioFramesetPtr = 0x5F7F if wDirection != DIRECTION_LEFT else 0x5F70
	wFrameDuration = 0
	wAnimationFrame = 0
	update_wario_animation()
	wPickedUpFrameCounter = MAX_PICKED_UP_FRAME_COUNTER
	wPickedUpWiggleCounter = byte(wPickedUpWiggleCounter - 1)
	if wPickedUpWiggleCounter != 0:
		return
	wAutoMoveState = 0
	start_fall()


## UpdateState_GroundShakeStunned: knocked up (moving the way he faces) until he lands; when the
## shaking stops, crouching without headroom, falling with nothing under him, or idling.
func update_state_ground_shake_stunned() -> void:
	update_wario_animation()
	if wGroundShakeCounter == 0:
		wCollisionBoxTop = byte(-27)
		if check_up_collision() != 0:
			crouch_or_slide()
			return
		if check_centre_collision() == 0:
			start_fall()
			return
		set_state_idling()
		return
	if wJumpVelTable == 0:
		return
	apply_jump_velocity()
	if wDirection == DIRECTION_LEFT:  # HandleWalk
		walk_left()
	else:
		walk_right()
	cap_airborne_walk_velocity()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() != 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_centre_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	wJumpVelTable = 0
	wJumpVelIndex = 0


## HandleInvincibility: the counter steps every 4th frame from $10 and every 2nd from $16, and ends
## at $28; each step toggles wInvisibleFrame, which makes DrawWario skip Wario (the flicker).
func handle_invincibility() -> void:
	if wInvincibleCounter == 0:
		return
	if wInvincibleCounter >= 0x16:
		if (wGlobalCounter & 0b01) != 0:
			return
		wInvincibleCounter += 1
		if wInvincibleCounter < 0x28:
			wInvisibleFrame ^= 1
			return
		wInvincibleCounter = 0
		wInvisibleFrame = 0
		if (wJoypadDown & (PAD_RIGHT | PAD_LEFT | PAD_DOWN)) != 0:
			return
		check_up_collision()
		return
	if wInvincibleCounter >= 0x10:
		if (wGlobalCounter & 0b11) != 0:
			return
		wInvincibleCounter += 1
		wInvisibleFrame ^= 1
		return
	if wWarioState == WST_STUNG or wWarioState == WST_STUNG_RECOVERY:
		return
	wInvincibleCounter = 0x10
	if wWarioPalsPtr == WARIO_INVISIBLE_PAL:
		set_wario_pal(WARIO_DEFAULT_PAL)


## Func_1f6c2: while stung, Wario's palettes alternate every 4 frames.
func flicker_stung_pal() -> void:
	match wGlobalCounter & 0b111:
		0:
			set_wario_pal(WARIO_INVISIBLE_PAL)
		3:
			set_wario_pal(WARIO_DEFAULT_PAL)


# --- Graphics (home/load_wario_gfx.asm, home/sprite.asm) -------------------------------------

## LoadWarioGfx with the source its caller wrote to wDMASourceBank:wDMASourcePtr (bank << 16 |
## pointer): the tile set is transferred at the next V-Blank. To gameplay only the pending flag
## matters: a floor transition does not step while a transfer is pending (UpdateLevel).
func load_wario_gfx(source: int) -> void:
	wDMASourceBank = source >> 16
	wDMASourcePtr = source & 0xFFFF
	wIsDMATransferPending = 1


## The OAM table DrawWario reads wWarioFrame from (wWarioOAMBank:wWarioOAMPtr, bank << 16 | pointer).
func set_wario_oam(table: int) -> void:
	wWarioOAMBank = table >> 16
	wWarioOAMPtr = table & 0xFFFF


## SetWarioPal: wWarioPalsPtr names Wario's two OBJ palettes (bank "Wario Palettes").
func set_wario_pal(palettes: int) -> void:
	wWarioPalsPtr = palettes


## UpdateWarioAnimation
func update_wario_animation() -> void:
	_update_wario_animation(wWarioFramesetPtr)


## UpdateWarioAnimation called from "Wario OAM 2": the frameset is read from that bank.
func update_wario_animation_2() -> void:
	_update_wario_animation(WARIO_OAM_2 | wWarioFramesetPtr)


func update_wario_animation_3() -> void:
	_update_wario_animation(WARIO_OAM_3 | wWarioFramesetPtr)


## UpdateWarioAnimation called in wWarioOAMBank (`ld a, [wWarioOAMBank]; ldh [hCallFuncBank], a`):
## the frameset in the OAM table's own bank.
func update_wario_animation_oam_bank() -> void:
	_update_wario_animation((wWarioOAMBank << 16) | wWarioFramesetPtr)


func _update_wario_animation(frameset: int) -> void:
	wWarioAnimationEnded = 0
	var duration: int = wFrameDuration - 1
	wFrameDuration = byte(duration)
	if duration >= 0:
		return
	if not tables.framesets.has(frameset):
		note_unported("frameset %04x" % frameset if frameset <= 0xFFFF else "frameset %02x:%04x" % [frameset >> 16, frameset & 0xFFFF])
		return
	var pairs: Array = tables.framesets[frameset]
	var index: int = wAnimationFrame / 2
	if index >= pairs.size():
		wAnimationFrame = 0
		wFrameDuration = 0
		wWarioAnimationEnded = 1
		return
	wWarioFrame = pairs[index][0]
	wAnimationFrame = byte(wAnimationFrame + 2)
	wFrameDuration = pairs[index][1]


# --- Velocities (home/wario_mechanics1.asm, wario_mechanics2.asm) ------------------------------

## ApplyWalkVelocity: the step at wWalkVelIndex; the index advances and cycles $18-$1b at the end.
func apply_walk_velocity() -> int:
	var b: int = tables.walk_steps[wWalkVelIndex]
	if wWalkVelIndex == 0x1B:
		wWalkVelIndex = wWalkVelIndex & 0xFC
	else:
		wWalkVelIndex += 1
	return b


## ApplySlopedWalkVelocity: on a slope the step never exceeds index 7.
func apply_sloped_walk_velocity() -> int:
	if wWalkVelIndex >= 0x08:
		wWalkVelIndex = 0x04
	return apply_walk_velocity()


## ApplyWalkVelocity_Right
func apply_walk_velocity_right() -> int:
	if wDirection == DIRECTION_LEFT:
		wWalkVelIndex = 0
		return apply_walk_velocity()
	if (wWarioSlopeInteraction & RIGHT_SLOPE) != 0:
		return apply_sloped_walk_velocity()
	return apply_walk_velocity()


## ApplyWalkVelocity_Left
func apply_walk_velocity_left() -> int:
	if wDirection != DIRECTION_LEFT:
		wWalkVelIndex = 0
		return apply_walk_velocity()
	if (wWarioSlopeInteraction & LEFT_SLOPE) != 0:
		return apply_sloped_walk_velocity()
	return apply_walk_velocity()


## Func_1762: caps the walk index in the air (2 px rising, 1 px falling).
func cap_airborne_walk_velocity() -> void:
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if wWalkVelIndex >= 0x10:
			wWalkVelIndex = 0x0C
	elif wWalkVelIndex >= 0x08:
		wWalkVelIndex = 0x04


# --- Floor transitions (home/floor_transition.asm, wario_mechanics1.asm) ----------------------

## GetFloorForYPos: 6 (top) to 1 (bottom), by half-section of wWarioYPos.
func get_floor_for_y_pos() -> int:
	var c: int
	match hi(wWarioYPos):
		1:
			c = 3
		2:
			c = 1
		_:
			c = 5
	if lo(wWarioYPos) < 0x80:
		c += 1
	return c


func _transitions_enabled() -> bool:
	return (wCameraConfigFlags & CAM_SCROLLING_MASK) >= CAM_TRANSITIONS


## TriggerDownwardsFloorTransition
func trigger_downwards_floor_transition() -> void:
	if not _transitions_enabled():
		return
	var c: int = get_floor_for_y_pos()
	if wFloor > c:
		start_downwards_floor_transition(c)


## TriggerFloorTransition_SkipUpdateYPos
func trigger_floor_transition_skip_update_y_pos() -> void:
	if not _transitions_enabled():
		return
	var c: int = get_floor_for_y_pos()
	if wFloor > c:
		start_downwards_floor_transition(c)
	elif wFloor < c:
		start_upwards_floor_transition(c)


## HandleDownwardsFloorTransition: where floor transitions are on, a floor below starts one.
func handle_downwards_floor_transition() -> void:
	if not _transitions_enabled():
		return
	var c: int = get_floor_for_y_pos()
	if wFloor > c:
		start_downwards_floor_transition(c)


## HandleUpwardsFloorTransition: where floor transitions are on, a floor above starts one.
func handle_upwards_floor_transition() -> void:
	if not _transitions_enabled():
		return
	var c: int = get_floor_for_y_pos()
	if wFloor < c:
		start_upwards_floor_transition(c)


## StartDownwardsFloorTransition
func start_downwards_floor_transition(c: int) -> void:
	wFloor = c
	wFloorTransitionTimer = 0x68 if c == 5 else 0x80
	wFloorTransitionDir = FLOOR_TRANSITION_UP
	wIsFloorTransition = 1
	wCameraRoomYScrollLimit = 0


## StartUpwardsFloorTransition
func start_upwards_floor_transition(c: int) -> void:
	wFloor = c
	wFloorTransitionDir = FLOOR_TRANSITION_DOWN
	wIsFloorTransition = 1
	wFloorTransitionTimer = 0x80
	wCameraRoomYScrollLimit = 0


## update_pos_y (macros/pos.asm)
func update_pos_y() -> void:
	wWarioYPos = hYPos


# --- Idling ---------------------------------------------------------------------------------

## UpdateState_Idling
func update_state_idling() -> void:
	var b: int = check_centre_collision()
	if wWarioState != WST_IDLING:
		return
	if b == 0:
		start_fall()
		return
	update_pos_y()
	if wWarioState != WST_IDLING:
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		probe_presence_centre()
		if wWarioState != WST_IDLING:
			return
		if wLadderInteraction == LADDER_UNDERNEATH:
			set_state_ladder_climbing()
		else:
			crouch_or_slide()
		return
	update_wario_animation()
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wLadderInteraction != 0 and (wJoypadDown & PAD_UP) != 0:
		set_state_ladder_climbing()
		return
	if wIsNearFence != 0 and (wJoypadDown & PAD_UP) != 0:
		note_unported("SetState_FenceMovingVertical")
		return
	if wWarioState != WST_IDLING:
		return
	handle_input_idling()
	if wWarioState != WST_IDLING:
		return
	if wIsOnSteppableObject != 0:
		return
	var counter: int = wWarioStateCounter + 1
	wWarioStateCounter = byte(counter)
	wWarioStateCycles = byte(wWarioStateCycles + (counter >> 8))
	if wWarioStateCycles >= NUM_SLEEPING_IDLE_CYCLES:
		note_unported("SetState_Sleeping")


## HandleInput_Idling
func handle_input_idling() -> void:
	if (wJoypadPressed & PAD_B) != 0:
		set_state_attacking()
		return
	if (wJoypadPressed & PAD_A) != 0:
		start_jump_from_input()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection != DIRECTION_LEFT:
			set_state_walking_reset_walk_vel()
		else:
			set_state_turning()
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection == DIRECTION_LEFT:
			set_state_walking_reset_walk_vel()
		else:
			set_state_turning()


## SetState_Idling
func set_state_idling() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_IDLING
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wIsCrouching = 0
	wAttackCounter = 0
	wGrabState = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wCollisionBoxTop = byte(-27)
	var b: int = check_up_collision()
	if wWarioState != WST_IDLING:
		return
	if b != 0:
		crouch_or_slide()
		return
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14000)
	wWarioFramesetPtr = FRAMESET_IDLE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_IDLE_LEFT
	update_wario_animation()


# --- Walking and turning --------------------------------------------------------------------

## UpdateState_Walking
func update_state_walking() -> void:
	var sfx: int = wSFXLoopCounter - 1
	wSFXLoopCounter = 36 if sfx < 0 else sfx
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		get_pos()
		create_particle(PARTICLE_DUST)
	handle_input_walking()
	if wWarioState != WST_WALKING:
		return
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_WALKING:
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_WALKING:
		return
	if b == 0:
		start_fall()
		return
	update_pos_y()


## HandleInput_Walking
func handle_input_walking() -> void:
	if wJumpingUpwards == 0 and (wJoypadDown & PAD_A) != 0:
		start_jump_from_input()
		return
	if (wJoypadPressed & PAD_B) != 0:
		set_state_attacking()
		return
	if (wJoypadPressed & PAD_A) != 0:
		start_jump_from_input()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		if is_on_slippery_ground() == 0:
			crouch_or_slide()
		else:
			set_state_crouch_slipping()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			set_state_turning()
			return
		wDirection = DIRECTION_RIGHT
		if check_front_collision() != 0:
			return
		move_wario_right(apply_walk_velocity_right())
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			set_state_turning()
			return
		wDirection = DIRECTION_LEFT
		if check_front_collision() != 0:
			return
		move_wario_left(apply_walk_velocity_left())
	else:
		if is_on_slippery_ground() == 0:
			set_state_idling()
		else:
			set_state_slipping()
		return
	# Walking speed: from index $10 back to $0c (2 px a frame).
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C


## SetState_Walking_ResetWalkVel
func set_state_walking_reset_walk_vel() -> void:
	wWalkVelIndex = 0
	set_state_walking()


## SetState_Walking and Func_1e6ea
func set_state_walking() -> void:
	wWarioState = WST_WALKING
	if (wJoypadDown & PAD_RIGHT) != 0:
		wDirection = DIRECTION_RIGHT
	elif (wJoypadDown & PAD_LEFT) != 0:
		wDirection = DIRECTION_LEFT
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_WALK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_WALK_LEFT
	update_wario_animation()


## UpdateState_Turning
func update_state_turning() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		start_jump_from_input()
		return
	if (wJoypadPressed & PAD_B) != 0:
		set_state_attacking()
		return
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_walking_reset_walk_vel()
	else:
		set_state_idling()


## SetState_Turning
func set_state_turning() -> void:
	wWarioState = WST_TURNING
	wAttackCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wDirection ^= 1
	wWarioFramesetPtr = FRAMESET_TURN_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TURN_LEFT
	update_wario_animation()


# --- Jumping, falling, and landing -----------------------------------------------------------

## StartJump_FromInput
func start_jump_from_input() -> void:
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wJumpingUpwards = 1
	start_jump()


## StartFall
func start_fall() -> void:
	wJumpingUpwards = 0
	start_fall_skip_reset_jump_upwards()


## StartFall_SkipResetJumpUpwards
func start_fall_skip_reset_jump_upwards() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	start_jump()


## StartJump: the high-jump table needs High Jump Boots and Up held.
func start_jump() -> void:
	wJumpVelTable = JUMP_VEL_NORMAL
	if wPowerUpLevel >= HIGH_JUMP_BOOTS and (wJoypadDown & PAD_UP) != 0:
		wJumpVelTable = JUMP_VEL_HIGH_JUMP
	set_state_airborne()


## SetState_Airborne
func set_state_airborne() -> void:
	wWarioSlopeInteraction = 0
	wWarioState = WST_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsCrouching = 0
	wAttackCounter = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = FRAMESET_AIRBORNE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_AIRBORNE_LEFT
	update_wario_animation()
	if wIsOnSteppableObject != 0:
		move_wario_up(2)


## UpdateState_Airborne
func update_state_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wJumpVelIndex >= FALLING_JUMP_VEL_INDEX:
		if wWaterInteraction != 0:
			dive_from_surface()
			return
		if wIsInSand != 0:
			set_state_sand_falling()
			return
		if wLadderInteraction != 0 and (wJoypadDown & PAD_UP) != 0:
			set_state_ladder_climbing()
			return
		if wWarioState != WST_AIRBORNE:
			return
		probe_presence_18()
		if wIsNearFence != 0 and (wJoypadDown & PAD_UP) != 0:
			note_unported("SetState_FenceMovingVertical")
			return
	if wWarioState != WST_AIRBORNE:
		return
	handle_input_airborne()
	if wWarioState != WST_AIRBORNE:
		return
	# With the overalls, Down while falling starts a smash attack; letting go of Down ends it.
	var smash: bool = false
	var plain: bool = false
	if wPowerUpLevel >= LEAD_OVERALLS and wIsSmashAttacking != 0:
		if (wJoypadDown & PAD_DOWN) == 0:
			wIsSmashAttacking = 0
			plain = true
	elif wPowerUpLevel >= LEAD_OVERALLS and wJumpVelIndex >= FALLING_JUMP_VEL_INDEX \
			and (wJoypadDown & PAD_DOWN) != 0:
		wIsSmashAttacking = 1
		smash = true
	if not smash and not plain and wIsTurning != 0:
		if wIsSmashAttacking != 0:
			smash = true
		else:
			plain = true
	if smash:
		wFrameDuration = 0
		wAnimationFrame = 0
		var overalls: bool = wPowerUpLevel >= SUPER_JUMP_SLAM_OVERALLS
		if wDirection != DIRECTION_LEFT:
			wWarioFramesetPtr = 0x6055 if overalls else 0x5F91
		else:
			wWarioFramesetPtr = 0x604E if overalls else 0x5F8E
	elif plain:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_AIRBORNE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_AIRBORNE_LEFT
	update_wario_animation()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		var up: int = check_up_collision()
		if up == 0 or wWarioState != WST_AIRBORNE:
			return
		if wJumpCollision != 0:
			start_fall_skip_reset_jump_upwards()
			return
		# Hit a ceiling corner: centre on the block column.
		wWarioXPos = (wWarioXPos & 0xFF00) | byte((lo(wWarioXPos) & 0xF0) + 0x08)
		return
	var b: int = check_airborne_collision()
	if wWarioState != WST_AIRBORNE:
		return
	if b == 0:
		trigger_downwards_floor_transition()
		return
	update_pos_y()
	get_pos()
	create_particle(PARTICLE_DUST)
	if wJumpVelIndex < MAX_JUMP_VEL_INDEX or (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		do_soft_land()
	else:
		do_hard_land()


## HandleInput_Airborne
func handle_input_airborne() -> void:
	if (wJoypadDown & PAD_A) == 0:
		wJumpingUpwards = 0
		if wJumpVelIndex < FALLING_JUMP_VEL_INDEX and wDoFullJump == 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	# Only three tables here: knock-back, normal, and high jump for every other value.
	var table: int = JUMP_VEL_HIGH_JUMP
	if wJumpVelTable == JUMP_VEL_KNOCK_BACK or wJumpVelTable == JUMP_VEL_NORMAL:
		table = wJumpVelTable
	var step: int = tables.jump_steps[table][wJumpVelIndex]
	if step < 0:
		move_wario_up(-step)
		wJumpVelIndex += 1
	else:
		wDoFullJump = 0
		move_wario_down(step)
		wJumpVelIndex += 1
		if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
			wJumpVelIndex = MAX_JUMP_VEL_INDEX
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
		cap_airborne_walk_velocity()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
		cap_airborne_walk_velocity()


## WalkRight and WalkIfPossible_Right
func walk_right() -> void:
	wIsTurning = 0
	if wDirection == DIRECTION_LEFT:
		wDirection = DIRECTION_RIGHT
		wIsTurning = 1
	if (check_front_collision() & 0x0F) != 0:
		return
	move_wario_right(apply_walk_velocity_right())


## WalkLeft and WalkIfPossible_Left
func walk_left() -> void:
	wIsTurning = 0
	if wDirection != DIRECTION_LEFT:
		wDirection = DIRECTION_LEFT
		wIsTurning = 1
	if (check_front_collision() & 0x0F) != 0:
		return
	move_wario_left(apply_walk_velocity_left())


## DoSoftLand
func do_soft_land() -> void:
	trigger_floor_transition_skip_update_y_pos()
	wJumpVelIndex = 0
	wJumpVelTable = 0
	if wIsSmashAttacking != 0:
		_smash_attack_land()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()
		return
	wCollisionBoxTop = byte(-27)
	if check_up_collision() != 0:
		crouch_or_slide()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_walking()
	else:
		set_state_idling()


## DoHardLand
func do_hard_land() -> void:
	trigger_floor_transition_skip_update_y_pos()
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWalkVelIndex = 0
	if wIsSmashAttacking != 0:
		_smash_attack_land()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()
		return
	wWarioState = WST_LANDING
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = FRAMESET_LAND_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_LAND_LEFT
	update_wario_animation()


## A smash attack's landing: a ground pound, or with the Super Jump Slam Overalls a ground shake.
func _smash_attack_land() -> void:
	if wPowerUpLevel < SUPER_JUMP_SLAM_OVERALLS:
		do_ground_pound()
	else:
		do_wario_ground_shake()


## DoWarioGroundShake: the ground shakes for 32 frames, unless it already does (Wario's own shake,
## wIsWarioGroundShaking; SFX_GROUND_SHAKE not simulated), then the smash attack's landing.
func do_wario_ground_shake() -> void:
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 32
		wIsWarioGroundShaking = 1
	_smash_landing_frameset(0x5FB8, 0x5FC5)


## DoGroundPound (SFX_GROUND_POUND not simulated).
func do_ground_pound() -> void:
	_smash_landing_frameset(0x5FF2, 0x6009)


## The two landings' frames: the airborne graphics, OAM_15955's pointer (its bank kept).
func _smash_landing_frameset(left: int, right: int) -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	wWarioOAMPtr = OAM_15955 & 0xFFFF
	wWarioFramesetPtr = right if wDirection != DIRECTION_LEFT else left
	update_wario_animation()
	set_state_smash_attacking()


## SetState_SmashAttacking: landed from a smash attack (wIsSmashAttacking $81), standing.
func set_state_smash_attacking() -> void:
	wIsSmashAttacking = 0x81
	wWarioState = WST_SMASH_ATTACKING
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9


## UpdateState_SmashAttacking: 27 frames, then idling.
func update_state_smash_attacking() -> void:
	update_wario_animation()
	wWarioStateCounter += 1
	if wWarioStateCounter < 0x1B:
		return
	wIsSmashAttacking = 0
	set_state_idling()


## UpdateState_Landing
func update_state_landing() -> void:
	if (wJoypadPressed & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_walking_reset_walk_vel()
		return
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	var jump: bool = false
	if wJumpingUpwards == 0 and (wJoypadDown & PAD_A) != 0:
		jump = true
	elif (wJoypadPressed & PAD_A) != 0:
		jump = true
	if jump:
		start_jump_from_input()
		if wPowerUpLevel >= HIGH_JUMP_BOOTS:
			wJumpVelTable = JUMP_VEL_HIGH_JUMP
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()
		return
	set_state_idling()


# --- Attacking (wario_states_1.asm) -----------------------------------------------------------

## SetState_Attacking: the shoulder charge, MAX_ATTACK_COUNTER frames long.
func set_state_attacking() -> void:
	wAttackCounter = MAX_ATTACK_COUNTER
	wSFXLoopCounter = 0
	wWarioState = WST_ATTACKING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	load_wario_gfx(WARIO_ATTACK_GFX)
	set_wario_oam(OAM_14D1B)
	if wPowerUpLevel >= GARLIC:
		wWarioFramesetPtr = FRAMESET_GARLIC_ATTACK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_GARLIC_ATTACK_LEFT
	else:
		wWarioFramesetPtr = FRAMESET_ATTACK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ATTACK_LEFT
	update_wario_animation()


## UpdateState_Attacking
func update_state_attacking() -> void:
	_sfx_loop(6)
	update_wario_animation()
	handle_input_attacking()
	if wWarioState != WST_ATTACKING:
		return
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_ATTACKING:
		return
	var front: int = check_front_collision()
	if wWarioState != WST_ATTACKING:
		return
	if (front & 0x0F) != 0:
		do_bump_with_small_back_offset()
		return
	if check_centre_collision() == 0:
		start_falling_airborne_attack()
		return
	if wWarioState != WST_ATTACKING:
		return
	if wAttackCounter < CHARGE_ATTACK_COUNTER:
		# The charge moves once its wind-up is over; the walk index cycles $10-$13.
		if wDirection == DIRECTION_LEFT:
			move_wario_left(apply_walk_velocity_left())
		else:
			move_wario_right(apply_walk_velocity_right())
		if wWalkVelIndex >= 0x14:
			wWalkVelIndex = 0x10
	check_centre_collision()
	update_pos_y()
	if wWarioState != WST_ATTACKING:
		return
	wAttackCounter = byte(wAttackCounter - 1)
	if wAttackCounter != 0:
		return
	if is_on_slippery_ground() != 0:
		set_state_slipping()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_walking_reset_walk_vel()
	else:
		set_state_idling()


## HandleInput_Attacking: holding the other way turns; A jumps into an airborne attack.
func handle_input_attacking() -> void:
	var back: int = PAD_LEFT if wDirection != DIRECTION_LEFT else PAD_RIGHT
	if (wJoypadDown & back) != 0:
		set_state_turning()
		return
	if (wJoypadPressed & PAD_A) != 0:
		start_jumping_airborne_attack()
		return
	if (wJoypadPressed & PAD_DOWN) != 0:
		set_state_crouch_sliding()


## The sound loop counters the attack states keep (the sound itself is not ported).
func _sfx_loop(period: int) -> void:
	var counter: int = wSFXLoopCounter - 1
	wSFXLoopCounter = period if counter < 0 else counter


# --- Bumping ------------------------------------------------------------------------------------

## DoBumpWithBigBackOffset
func do_bump_with_big_back_offset() -> void:
	if wDirection == DIRECTION_LEFT:
		move_wario_right(3)
	else:
		move_wario_left(3)
	do_bump_or_jumping_bump()


## DoBumpWithSmallBackOffset
func do_bump_with_small_back_offset() -> void:
	if wDirection == DIRECTION_LEFT:
		move_wario_right(2)
	else:
		move_wario_left(2)
	do_bump_or_jumping_bump()


## DoBumpOrJumpingBump: a bump on the ground hops (index 10); one in the air falls.
func do_bump_or_jumping_bump() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX if wJumpVelTable != 0 else 10
	set_state_bumping()


## DoJumpingBump and DoJumpingBump_NoSFX
func do_jumping_bump() -> void:
	wJumpVelIndex = 10
	set_state_bumping()


## SetState_Bumping: Wario turns away from what he hit and is knocked back.
func set_state_bumping() -> void:
	wWarioState = WST_BUMPING
	wDirection ^= 1
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wAttackCounter = 0
	if wIsRolling != 0:
		# Bumped out of a roll: upright again, falling at once if there is no headroom.
		wIsRolling = 0
		load_wario_gfx(WARIO_AIRBORNE_GFX)
		set_wario_oam(OAM_15955)
		wWarioFramesetPtr = FRAMESET_ROLL_BUMP_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ROLL_BUMP_LEFT
		update_wario_animation()
		wCollisionBoxTop = byte(-27)
		if check_up_collision() != 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	wWarioFramesetPtr = FRAMESET_15216 if wDirection != DIRECTION_LEFT else FRAMESET_15219
	update_wario_animation()


## UpdateState_Bumping
func update_state_bumping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	if wWarioState != WST_BUMPING:
		return
	handle_bump_movement()
	if wWarioState != WST_BUMPING:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		var up: int = check_up_collision()
		if wWarioState != WST_BUMPING:
			return
		if up != 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	update_pos_y()
	wDirection ^= 1
	if wWarioState != WST_BUMPING:
		return
	do_soft_land()


## UpdateState_EnemyBumping: bumping into an enemy (SetState_EnemyBumping): as bumping, with the
## animation running; landing, he turns round.
func update_state_enemy_bumping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	if wWarioState != WST_ENEMY_BUMPING:
		return
	update_wario_animation()
	handle_bump_movement()
	if wWarioState != WST_ENEMY_BUMPING:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() != 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	wDirection ^= 1
	wWarioYPos = hYPos
	do_soft_land()


## HandleBumpMovement: 1 px a frame back, along JumpVelTable_Normal (whatever wJumpVelTable says);
## late in the bump a held direction ends it in a fall.
func handle_bump_movement() -> void:
	if wJumpVelIndex >= 28 and (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		if (wJoypadDown & PAD_RIGHT) != 0:
			wDirection = DIRECTION_RIGHT
			if check_bottom_left_breaking() == 0:
				move_wario_left(1)
		else:
			wDirection = DIRECTION_LEFT
			if check_bottom_right_breaking() == 0:
				move_wario_right(1)
		wWalkVelIndex = 0
		start_fall()
		return
	if wDirection == DIRECTION_RIGHT:
		move_wario_right(1)
		if check_bottom_right_breaking() != 0:
			move_wario_left(1)
	else:
		move_wario_left(1)
		if check_bottom_left_breaking() != 0:
			move_wario_right(1)
	var step: int = tables.jump_steps[JUMP_VEL_NORMAL][wJumpVelIndex]
	if step < 0:
		move_wario_up(-step)
		wJumpVelIndex += 1
	else:
		move_wario_down(step)
		wJumpVelIndex += 1
		if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
			wJumpVelIndex = MAX_JUMP_VEL_INDEX


## Func_19741: CheckBottomRightCollision with the break flag set.
func check_bottom_right_breaking() -> int:
	wBlockFuncBreakFlag = 1
	return check_bottom_right_collision()


## Func_197b1: CheckBottomLeftCollision with the break flag set.
func check_bottom_left_breaking() -> int:
	wBlockFuncBreakFlag = 1
	return check_bottom_left_collision()


# --- Attacking airborne ---------------------------------------------------------------------------

## StartFallingAirborneAttack
func start_falling_airborne_attack() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_attacking_airborne()


## StartJumpingAirborneAttack
func start_jumping_airborne_attack() -> void:
	wJumpVelIndex = 0
	wJumpingUpwards = 1
	set_state_attacking_airborne()


## SetState_AttackingAirborne
func set_state_attacking_airborne() -> void:
	wWarioSlopeInteraction = 0
	wWarioState = WST_ATTACKING_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelTable = JUMP_VEL_HIGH_JUMP if wPowerUpLevel >= HIGH_JUMP_BOOTS else JUMP_VEL_NORMAL
	if wPowerUpLevel >= GARLIC:
		wWarioFramesetPtr = (FRAMESET_GARLIC_AIR_ATTACK_RIGHT if wDirection != DIRECTION_LEFT
				else FRAMESET_GARLIC_AIR_ATTACK_LEFT)
	else:
		wWarioFramesetPtr = FRAMESET_15219 if wDirection != DIRECTION_LEFT else FRAMESET_15216
	update_wario_animation()
	if wIsOnSteppableObject != 0:
		update_state_attacking_airborne()


## UpdateState_AttackingAirborne
func update_state_attacking_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	if wWarioState != WST_ATTACKING_AIRBORNE:
		return
	_sfx_loop(6)
	update_wario_animation()
	handle_attacking_airborne_movement()
	if wWarioState != WST_ATTACKING_AIRBORNE:
		return
	var front: int = check_front_collision()
	if wWarioState != WST_ATTACKING_AIRBORNE:
		return
	if (front & 0x0F) != 0:
		do_bump_with_small_back_offset()
		return
	var counter: int = byte(wAttackCounter - 1)
	if counter != 0:
		wAttackCounter = counter
	var back: int = PAD_RIGHT if wDirection == DIRECTION_LEFT else PAD_LEFT
	if (wJoypadPressed & back) != 0:
		wAttackCounter = 0
		start_fall()
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_ATTACKING_AIRBORNE:
			return
		if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_ATTACKING_AIRBORNE:
		return
	set_state_idling()


## HandleAttackingAirborneMovement: the jump table, then a walk step the way Wario faces.
func handle_attacking_airborne_movement() -> void:
	apply_jump_velocity()
	if wDirection == DIRECTION_LEFT:
		walk_left()
	else:
		walk_right()
	if wWalkVelIndex >= 0x14:
		wWalkVelIndex = 0x10


## ApplyJumpVelocity (home/wario_mechanics1.asm): any of the five tables; none for other values.
func apply_jump_velocity() -> void:
	if not tables.jump_steps.has(wJumpVelTable):
		if wJumpVelTable >= 1 and wJumpVelTable <= 5:
			note_unported("jump table %d not extracted" % wJumpVelTable)
		return
	var step: int = tables.jump_steps[wJumpVelTable][wJumpVelIndex]
	if step < 0:
		move_wario_up(-step)
		wJumpVelIndex += 1
		return
	wDoFullJump = 0
	move_wario_down(step)
	wJumpVelIndex += 1
	if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
		wJumpVelIndex = MAX_JUMP_VEL_INDEX


## TriggerFloorTransition: update_pos_y, then a floor transition if the floor changed.
func trigger_floor_transition() -> void:
	update_pos_y()
	trigger_floor_transition_skip_update_y_pos()


# --- Crouching (wario_states_1.asm) ----------------------------------------------------------

## CrouchOrSlide: on a slope Wario slides; otherwise he crouches (and crouch-walks if a
## direction is held).
func crouch_or_slide() -> void:
	if wWarioSlopeInteraction != 0:
		set_state_sliding()
		return
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioState = WST_CROUCHING
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wWalkVelIndex = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsCrouching = 1
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_crouch_walking()
		return
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_CROUCH_RIGHT if wDirection == DIRECTION_RIGHT else FRAMESET_CROUCH_LEFT
	update_wario_animation()


## UpdateState_Crouching
func update_state_crouching() -> void:
	probe_presence_top()
	if wWarioState != WST_CROUCHING:
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	handle_input_crouching()
	if wWarioState != WST_CROUCHING:
		return
	if check_centre_collision() == 0:
		start_crouch_fall()


## Func_1eb46: A jumps (with headroom), B attacks (with headroom), releasing Down stands up if
## there is room, and a direction crouch-walks.
func handle_input_crouching() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		crouch_jump_if_room()
		return
	if (wJoypadPressed & PAD_B) != 0:
		crouch_attack_if_room()
		return
	if (wJoypadDown & PAD_DOWN) == 0:
		wCollisionBoxTop = byte(-27)
		var b: int = check_up_collision()
		if wWarioState != WST_CROUCHING:
			return
		if b == 0:
			set_state_idling()
			return
	wCollisionBoxTop = byte(-15)
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) == 0:
		return
	wDirection = DIRECTION_RIGHT if (wJoypadDown & PAD_RIGHT) != 0 else DIRECTION_LEFT
	set_state_crouch_walking()


## SetState_CrouchWalking
func set_state_crouch_walking() -> void:
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioState = WST_CROUCH_WALKING
	wIsCrouching = 1
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wAttackCounter = 0
	wGrabState = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_CROUCH_WALK_RIGHT if wDirection == DIRECTION_RIGHT else FRAMESET_CROUCH_WALK_LEFT
	update_wario_animation()


## Func_1ec19: a crouched jump if the full height fits, else stay crouched.
func crouch_jump_if_room() -> void:
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wCollisionBoxTop = byte(-27)
	var b: int = check_up_collision()
	if wWarioState != WST_CROUCHING and wWarioState != WST_CROUCH_WALKING:
		return
	if b == 0:
		start_crouch_jump()
		return
	wJumpVelTable = 0
	wCollisionBoxTop = byte(-15)


## Func_1ec4b: an attack if the full height fits.
func crouch_attack_if_room() -> void:
	wCollisionBoxTop = byte(-27)
	if check_up_collision() == 0:
		set_state_attacking()
		return
	wCollisionBoxTop = byte(-15)


## UpdateState_CrouchWalking
func update_state_crouch_walking() -> void:
	_sfx_loop(21)
	update_wario_animation()
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_CROUCH_WALKING:
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	handle_input_crouch_walking()
	if wWarioState != WST_CROUCH_WALKING:
		return
	if check_centre_collision() == 0:
		start_crouch_fall()
		return
	update_pos_y()
	if wWarioSlopeInteraction != 0:
		set_state_sliding()


## Func_1ec6c: like Func_1eb46, but walking: the walk index cycles 0-3 (steps 0, 1, 0, 1).
func handle_input_crouch_walking() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		crouch_jump_if_room()
		return
	if (wJoypadPressed & PAD_B) != 0:
		crouch_attack_if_room()
		return
	if (wJoypadDown & PAD_DOWN) == 0:
		wCollisionBoxTop = byte(-27)
		var b: int = check_up_collision()
		if wWarioState != WST_CROUCH_WALKING:
			return
		if b == 0:
			set_state_idling()
			return
	wCollisionBoxTop = byte(-15)
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			wDirection = DIRECTION_RIGHT
			wFrameDuration = 0
			wAnimationFrame = 0
			wWarioFramesetPtr = FRAMESET_CROUCH_WALK_RIGHT
		if (check_front_collision() & 0x0F) != 0:
			return
		move_wario_right(apply_walk_velocity_right())
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			wDirection = DIRECTION_LEFT
			wFrameDuration = 0
			wAnimationFrame = 0
			wWarioFramesetPtr = FRAMESET_CROUCH_WALK_LEFT
		if (check_front_collision() & 0x0F) != 0:
			return
		move_wario_left(apply_walk_velocity_left())
	else:
		crouch_or_slide()
		return
	if wWalkVelIndex >= 0x04:
		wWalkVelIndex = 0


## StartCrouchFall
func start_crouch_fall() -> void:
	wWalkVelIndex = 0
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_crouch_airborne()


## StartCrouchJump
func start_crouch_jump() -> void:
	wJumpVelIndex = 0
	set_state_crouch_airborne()


## SetState_CrouchAirborne
func set_state_crouch_airborne() -> void:
	wWarioState = WST_CROUCH_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wJumpVelTable = JUMP_VEL_NORMAL
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_CROUCH_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_CROUCH_LEFT
	update_wario_animation()
	if wIsOnSteppableObject != 0:
		move_wario_up(2)


## UpdateState_CrouchAirborne: without Down held and with room, it becomes a normal jump.
func update_state_crouch_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	if wWarioState != WST_CROUCH_AIRBORNE:
		return
	if (wJoypadDown & PAD_DOWN) == 0:
		wCollisionBoxTop = byte(-27)
		var room: int = check_up_collision()
		if wWarioState != WST_CROUCH_AIRBORNE:
			return
		if room == 0:
			start_jump()
			return
	wCollisionBoxTop = byte(-15)
	handle_input_airborne()
	if wWarioState != WST_CROUCH_AIRBORNE:
		return
	if wIsTurning != 0:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_CROUCH_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_CROUCH_LEFT
		update_wario_animation()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_CROUCH_AIRBORNE:
			return
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		if wWarioState != WST_CROUCH_AIRBORNE:
			return
		trigger_downwards_floor_transition()
		return
	update_pos_y()
	if wWarioState != WST_CROUCH_AIRBORNE:
		return
	do_soft_land()
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()


## SetState_CrouchSliding: Down during a charge.
func set_state_crouch_sliding() -> void:
	wSFXLoopCounter = 0
	wAttackCounter = 0
	wWarioState = WST_CROUCH_SLIDING
	wIsCrouching = 1
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_CROUCH_RIGHT if wDirection == DIRECTION_RIGHT else FRAMESET_CROUCH_LEFT
	update_wario_animation()


## UpdateState_CrouchSliding: 2 px a frame, then 1, then 1 every other frame; it ends at frame
## $28 ($3c with Garlic), or on a slope by sliding.
func update_state_crouch_sliding() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_CROUCH_SLIDING:
		return
	if (wJoypadPressed & PAD_A) != 0:
		wCollisionBoxTop = byte(-27)
		var b: int = check_up_collision()
		if wWarioState != WST_CROUCH_SLIDING:
			return
		wCollisionBoxTop = byte(-15)
		if b == 0:
			start_crouch_jump()
		return
	var ground: int = check_centre_collision()
	if wWarioState != WST_CROUCH_SLIDING:
		return
	if ground == 0:
		start_crouch_fall()
		return
	if wWarioSlopeInteraction != 0:
		update_pos_y()
		set_state_sliding()
		return
	var front: int = check_front_collision()
	if wWarioState != WST_CROUCH_SLIDING:
		return
	if front != 0:
		_end_crouch_slide()
		return
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	var limits: Array = [0x1E, 0x36, 0x3C] if wPowerUpLevel >= GARLIC else [0x14, 0x24, 0x28]
	var step: int
	if wWarioStateCounter < limits[0]:
		step = 2
	elif wWarioStateCounter < limits[1]:
		step = 1
	elif wWarioStateCounter < limits[2]:
		if (wGlobalCounter & 1) == 0:
			return
		step = 1
	else:
		if wWarioStateCounter == limits[2]:
			_end_crouch_slide()
		return
	if wDirection != DIRECTION_LEFT:
		move_wario_right(step)
	else:
		move_wario_left(step)


func _end_crouch_slide() -> void:
	if (wJoypadDown & PAD_DOWN) == 0:
		wCollisionBoxTop = byte(-27)
		var b: int = check_up_collision()
		if wWarioState != WST_CROUCH_SLIDING:
			return
		if b == 0:
			set_state_idling()
			return
	wCollisionBoxTop = byte(-15)
	crouch_or_slide()


# --- Sliding and rolling -----------------------------------------------------------------------

## SetState_Sliding: down a slope, facing down it.
func set_state_sliding() -> void:
	wWarioState = WST_SLIDING
	wSFXLoopCounter = 0
	wIsCrouching = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWalkVelIndex = 0
	wGrabState = 0
	wIsRolling = 1
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	load_wario_gfx(WARIO_SLIDE_GFX)
	set_wario_oam(OAM_1644A)
	if (wWarioSlopeInteraction & LEFT_SLOPE) == 0:
		hXPos = word(wWarioXPos + 0x0C)
		hYPos = word(wWarioYPos - 0x0C)
		create_particle(PARTICLE_SLIDE_DUST_LEFT)
		wDirection = DIRECTION_LEFT
		wWarioFramesetPtr = FRAMESET_SLIDE_LEFT
	else:
		hXPos = word(wWarioXPos - 0x0C)
		hYPos = word(wWarioYPos - 0x0C)
		create_particle(PARTICLE_SLIDE_DUST_RIGHT)
		wDirection = DIRECTION_RIGHT
		wWarioFramesetPtr = FRAMESET_SLIDE_RIGHT
	update_wario_animation()


## UpdateState_Sliding: becomes a roll when its animation ends.
func update_state_sliding() -> void:
	_sfx_loop(12)
	update_wario_animation()
	handle_input_sliding()
	if wWarioState != WST_SLIDING:
		return
	if _centre_ground() == 0:
		start_rolling_fall()
		return
	wWarioYPos = hYPos  # update_pos
	wWarioXPos = hXPos
	if (check_front_collision() & 0x0F) != 0:
		do_bump_with_small_back_offset()
		return
	if wWarioAnimationEnded == 0:
		return
	set_state_rolling()


## Func_1f825: A jumps out of the slide, the other direction stops it, else 1 px a frame down it.
func handle_input_sliding() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		wIsRolling = 0
		start_jump_from_input()
		return
	var back: int = PAD_RIGHT if wDirection == DIRECTION_LEFT else PAD_LEFT
	if (wJoypadPressed & back) != 0:
		wIsRolling = 0
		set_state_idling()
		return
	if wDirection == DIRECTION_LEFT:
		walk_if_possible_left()
	else:
		walk_if_possible_right()
	if wWalkVelIndex >= 0x08:
		wWalkVelIndex = 0x04


## WalkIfPossible_Right
func walk_if_possible_right() -> void:
	if (check_front_collision() & 0x0F) != 0:
		return
	move_wario_right(apply_walk_velocity_right())


## WalkIfPossible_Left
func walk_if_possible_left() -> void:
	if (check_front_collision() & 0x0F) != 0:
		return
	move_wario_left(apply_walk_velocity_left())


## SetState_Rolling
func set_state_rolling() -> void:
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioState = WST_ROLLING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-14)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wIsRolling = 2
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_ROLL_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ROLL_LEFT
	update_wario_animation()


## UpdateState_Rolling: the walk index cycles $14-$17; a slope rising the other way bumps.
func update_state_rolling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(12)
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		check_centre_collision()
		update_pos_y()
		if wWarioSlopeInteraction != 0 and _against_slope():
			do_bump_with_small_back_offset()
			return
		start_rolling_jump()
		return
	if wDirection == DIRECTION_LEFT:
		move_wario_left(apply_walk_velocity_left())
	else:
		move_wario_right(apply_walk_velocity_right())
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if (check_front_collision() & 0x0F) != 0:
		do_bump_with_big_back_offset()
		return
	if check_centre_collision() == 0:
		start_rolling_fall()
		return
	update_pos_y()
	if wWarioSlopeInteraction != 0 and _against_slope():
		do_bump_with_small_back_offset()


## `and $0f / dec a / xor wDirection`: a right slope (1) suits facing left (0), a left slope (2)
## facing right (1); anything else is rolling against it.
func _against_slope() -> bool:
	return byte(((wWarioSlopeInteraction & 0x0F) - 1) ^ wDirection) != 0


## Func_1e174
func start_rolling_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_rolling_airborne()


## Func_1e1e3
func start_rolling_jump() -> void:
	wJumpVelIndex = 0
	set_state_rolling_airborne()


## SetState_RollingAirborne
func set_state_rolling_airborne() -> void:
	wWarioSlopeInteraction = 0
	wGrabState = 0
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wWarioState = WST_ROLLING_AIRBORNE
	wIsRolling = 2
	load_wario_gfx(WARIO_SLIDE_GFX)
	set_wario_oam(OAM_1644A)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_ROLL_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ROLL_LEFT
	update_wario_animation()


## UpdateState_RollingAirborne: along JumpVelTable_HighJump whatever wJumpVelTable says.
func update_state_rolling_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	update_wario_animation()
	if wDirection == DIRECTION_LEFT:
		move_wario_left(apply_walk_velocity_left())
	else:
		move_wario_right(apply_walk_velocity_right())
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if (check_front_collision() & 0x0F) != 0:
		do_bump_with_big_back_offset()
		return
	var step: int = tables.jump_steps[JUMP_VEL_HIGH_JUMP][wJumpVelIndex]
	if step < 0:
		move_wario_up(-step)
		wJumpVelIndex += 1
	else:
		move_wario_down(step)
		wJumpVelIndex += 1
		if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
			wJumpVelIndex = MAX_JUMP_VEL_INDEX
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() != 0:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	set_state_rolling()


# --- Stung (wario_states_1.asm) --------------------------------------------------------------

## UpdateState_Stung: knocked back along JumpVelTable_Normal, bouncing up to twice (index 10,
## then 14) before recovering; on the ground first (wJumpVelTable 0) it slides back until the
## index runs out. Func_1f6c2's palette flicker is presentation and not ported.
func update_state_stung() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	flicker_stung_pal()
	update_wario_animation()
	if knock_back_motion():
		_stung_recover()


## The knock-back UpdateState_Stung and UpdateState_Electric share: away from what hit him (back a
## pixel at a wall), along the normal jump table, bouncing on the ground twice (indices $0a, $0e).
## True when it is over (on the ground after the bounces, or sliding without a table to the end).
func knock_back_motion() -> bool:
	if check_front_collision() != 0:
		if wDirection == DIRECTION_LEFT:
			move_wario_right(1)
		else:
			move_wario_left(1)
	else:
		var b: int = 1 if wJumpVelIndex >= FALLING_JUMP_VEL_INDEX else 2
		if wDirection == DIRECTION_LEFT:
			move_wario_left(b)
		else:
			move_wario_right(b)
	if wJumpVelTable == 0:
		wJumpVelIndex = byte(wJumpVelIndex + 1)
		if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
			return true
		if (check_centre_collision() & 0x0F) != 0:
			return false
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		wJumpVelTable = JUMP_VEL_KNOCK_BACK
		return false
	while true:
		var step: int = tables.jump_steps[JUMP_VEL_NORMAL][wJumpVelIndex]
		if step < 0:
			move_wario_up(-step)
			wJumpVelIndex += 1
			if check_up_collision() == 0:
				return false
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
			continue  # the same frame goes on with the fall
		move_wario_down(step)
		wJumpVelIndex += 1
		if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
			wJumpVelIndex = MAX_JUMP_VEL_INDEX
		break
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return false
	trigger_floor_transition()
	wJumpVelTable = byte(wJumpVelTable + 1)
	if wJumpVelTable == 2:
		wJumpVelIndex = 0x0A
	elif wJumpVelTable == 3:
		wJumpVelIndex = 0x0E
	else:
		return true
	return false


# --- Electric (wario_states_3.asm) ----------------------------------------------------------

## UpdateState_ElectricStart: the shock's animation, then thrown back as when stung (from index 6),
## invincible.
func update_state_electric_start() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	wInvincibleCounter = 1
	wWarioState = WST_ELECTRIC
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelIndex = 6
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	var saved_y: int = hYPos
	var saved_x: int = hXPos
	var headroom: bool = true
	if wIsCrouching != 0:
		wCollisionBoxTop = byte(-27)
		var b: int = check_up_collision()
		if wWarioState != WST_ELECTRIC:
			return
		headroom = b == 0
		if headroom:
			wIsCrouching = 0
	hYPos = saved_y
	hXPos = saved_x
	if headroom:
		wCollisionBoxTop = byte(-27)
		wJumpVelTable = JUMP_VEL_KNOCK_BACK
	else:
		wCollisionBoxTop = byte(-15)
		wJumpVelTable = 0
	wWarioFramesetPtr = FRAMESET_ELECTRIC_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ELECTRIC_LEFT
	update_wario_animation()


## UpdateState_Electric: the knock-back; at its end Wario turns round, dizzy.
func update_state_electric() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation()
	if not knock_back_motion():
		return
	# A puff of smoke at his head, 8 px ahead.
	hXPos = word(wWarioXPos + (8 if wDirection != DIRECTION_LEFT else -8))
	hYPos = word(wWarioYPos - 0x20)
	create_particle(PARTICLE_SMOKE_SMALL)
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wDirection ^= 1
	wWarioState = WST_ELECTRIC_DIZZY
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_ELECTRIC_DIZZY_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ELECTRIC_DIZZY_LEFT
	update_wario_animation()


## UpdateState_ElectricDizzy: when the animation ends, Wario recovers.
func update_state_electric_dizzy() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		recover_from_transformation()


# --- Water (wario_states_1.asm) -------------------------------------------------------------

## DiveFromSurface: into the water, with a splash at the surface (hPos on its block's top).
func dive_from_surface() -> void:
	wGrabState = 0
	get_pos()
	hYPos = (hYPos & 0xFF00) | (lo(hYPos) & 0xF0)
	create_particle(PARTICLE_SPLASH)
	dive_from_surface_skip_splash()


## DiveFromSurface_SkipSplash
func dive_from_surface_skip_splash() -> void:
	wCollisionBoxTop = byte(-27)
	set_wario_oam(OAM_15254)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_SWIM_SINK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_SINK_LEFT
	update_wario_animation()
	set_state_diving()


## StartDive
func start_dive() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_SWIM_DIVE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_DIVE_LEFT
	update_wario_animation()
	set_state_diving()


## SetState_Diving (the box's top is kept).
func set_state_diving() -> void:
	wWarioState = WST_DIVING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wAttackCounter = 0
	wIsRolling = 0
	wSwimVelIndex = 0
	wIsCrouching = 0
	wc0e0 = 0
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_SWIM_GFX)


## UpdateState_Diving: down 2 px a frame for 10 frames, then 1 px for 4, then submerged; a floor
## ends it sooner.
func update_state_diving() -> void:
	var b: int = check_centre_collision()
	if wWarioState != WST_DIVING:
		return
	if b != 0:
		update_pos_y()
		set_state_submerged()
		return
	handle_diving_horizontal_movement()
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter >= 14:
		set_state_submerged()
		return
	move_wario_down(2 if wWarioStateCounter < 10 else 1)
	if check_centre_collision() != 0:
		update_pos_y()
		set_state_submerged()


## SetState_Submerged: swimming with the Swimming Flippers (in water that allows it); otherwise
## floating up.
func set_state_submerged() -> void:
	wWarioState = WST_SUBMERGED
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wSwimVelIndex = 0
	wc0e0 = 0
	wSwimmingDirectionInput = 0
	load_wario_gfx(WARIO_SWIM_GFX)
	set_wario_oam(OAM_15254)
	wFrameDuration = 0
	wAnimationFrame = 0
	if wPowerUpLevel >= SWIMMING_FLIPPERS and wWaterInteraction != NON_SUBMERSIBLE_WATER:
		wCollisionBoxBottom = byte(-1)
		wCollisionBoxTop = byte(-15)
		wCollisionBoxLeft = byte(-9)
		wCollisionBoxRight = 9
		wWarioFramesetPtr = FRAMESET_SWIM_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_LEFT
	else:
		wWarioFramesetPtr = FRAMESET_SWIM_SINK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_SINK_LEFT
	update_wario_animation()


## UpdateState_Submerged
func update_state_submerged() -> void:
	wc0e1 = 0
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_SUBMERGED:
		return
	apply_water_current_movement()
	_submerged_input()


## Func_1f1a9: with the flippers, B thrusts, A thrusts up, and the pad swims; otherwise (or
## without input) Wario floats up a pixel every other frame until the surface.
func _submerged_input() -> void:
	if wWaterInteraction != NON_SUBMERSIBLE_WATER and wPowerUpLevel >= SWIMMING_FLIPPERS:
		if (wJoypadPressed & PAD_B) != 0:
			start_underwater_thrusting()
			return
		if (wJoypadPressed & PAD_A) != 0:
			start_upwards_underwater_thrusting()
			return
		if (wJoypadDown & PAD_CTRL_PAD) != 0:
			_swim_with_pad()
			return
		if wWarioStateCycles == 0:
			wFrameDuration = 0
			wAnimationFrame = 0
			wWarioFramesetPtr = FRAMESET_SWIM_DIVE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_DIVE_LEFT
	update_wario_animation()
	wWarioStateCycles = 1
	if check_up_collision() != 0:
		wc0e1 = PAD_UP
		return
	probe_presence_12()
	if wWaterInteraction == 0:
		surface_from_underwater()
		return
	if (wGlobalCounter & 1) != 0 or ((wCurWaterCurrent | wLastWaterCurrent) & (CURRENT_UP | CURRENT_DOWN)) != 0:
		return
	move_wario_up(1)


## Func_1f24c: swimming with the pad, a pixel at a time: across on odd frames, up or down on even.
func _swim_with_pad() -> void:
	_sfx_loop(37)
	if wWarioStateCycles != 0:
		wWarioStateCycles = 0
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_SWIM_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_LEFT
	update_wario_animation()
	if (wGlobalCounter & 1) == 0:
		if (wJoypadDown & PAD_UP) != 0:
			_swim_up()
		elif (wJoypadDown & PAD_DOWN) != 0:
			_swim_down()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		_swim_across(true)
	elif (wJoypadDown & PAD_LEFT) != 0:
		_swim_across(false)


## .asm_1f2c0 and Func_1f357: settled on a floor, then turning or (Func_1f310) swimming on.
func _swim_across(right: bool) -> void:
	if check_centre_collision() != 0:
		update_pos_y()
	if wWarioState == WST_WATER_STUNG:
		return
	if (wDirection != DIRECTION_LEFT) == right:
		_swim_forward()
		return
	wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_SWIM_RIGHT if right else FRAMESET_SWIM_LEFT
	update_wario_animation()


## Func_1f310: a pixel the way he faces, unless a current across carries him; a wall stops him.
func _swim_forward() -> void:
	if check_front_collision() != 0:
		wc0e1 = PAD_RIGHT if wDirection != DIRECTION_LEFT else PAD_LEFT
		return
	if ((wCurWaterCurrent | wLastWaterCurrent) & (CURRENT_RIGHT | CURRENT_LEFT)) != 0:
		return
	if wDirection != DIRECTION_LEFT:
		move_wario_right(1)
	else:
		move_wario_left(1)


## Func_1f3a7
func _swim_down() -> void:
	if check_centre_collision() != 0:
		update_pos_y()
		wc0e1 = PAD_DOWN
		return
	if ((wCurWaterCurrent | wLastWaterCurrent) & (CURRENT_UP | CURRENT_DOWN)) != 0:
		return
	move_wario_down(1)


## Func_1f3d9: up, surfacing where the water ends.
func _swim_up() -> void:
	if check_up_collision() != 0:
		return
	probe_presence_12()
	if wWaterInteraction == 0:
		surface_from_underwater()
		return
	if ((wCurWaterCurrent | wLastWaterCurrent) & (CURRENT_UP | CURRENT_DOWN)) != 0:
		return
	move_wario_up(1)


## SurfaceFromUnderwater
func surface_from_underwater() -> void:
	wSFXLoopCounter = 0
	wWaterSurfaceFloatingCounter = 0
	load_wario_gfx(WARIO_SWIM_GFX)
	set_wario_oam(OAM_15254)
	set_state_water_surface_idling()


## SetState_WaterSurfaceIdling
func set_state_water_surface_idling() -> void:
	wWarioState = WST_WATER_SURFACE_IDLING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wSwimVelIndex = 0
	wc0e0 = 0
	wSwimmingDirectionInput = 0
	if wWaterInteraction == 0:
		wWaterInteraction = SUBMERSIBLE_WATER
	wWarioFramesetPtr = FRAMESET_WATER_SURFACE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_WATER_SURFACE_LEFT
	update_wario_animation()


## UpdateState_WaterSurfaceIdling: bobbing at the surface; a direction swims.
func update_state_water_surface_idling() -> void:
	wc0e1 = 0
	probe_presence_top()
	if wWarioState != WST_WATER_SURFACE_IDLING:
		return
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(28)
	update_wario_animation()
	handle_water_surface_floating_movement()
	handle_water_surface_input()
	if wWarioState != WST_WATER_SURFACE_IDLING:
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_water_surface_moving()
		return
	apply_water_current_movement()


## SetState_WaterSurfaceMoving
func set_state_water_surface_moving() -> void:
	wWarioState = WST_WATER_SURFACE_MOVING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wSwimVelIndex = 0
	wWarioFramesetPtr = FRAMESET_WATER_SURFACE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_WATER_SURFACE_LEFT
	update_wario_animation()


## UpdateState_WaterSurfaceMoving
func update_state_water_surface_moving() -> void:
	wc0e1 = 0
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(28)
	update_wario_animation()
	handle_water_surface_floating_movement()
	apply_water_current_movement()
	_water_surface_directional_input()
	handle_water_surface_input()


## UpdateState_WaterSurfaceMoving.HandleDirectionalInput: turning, then swimming at the walk's
## speed (index 0-3) unless a current across carries him; no direction stops.
func _water_surface_directional_input() -> void:
	var right: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		right = true
	elif (wJoypadDown & PAD_LEFT) != 0:
		right = false
	else:
		set_state_water_surface_idling()
		return
	if (wDirection != DIRECTION_LEFT) != right:
		wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_WATER_SURFACE_RIGHT if right else FRAMESET_WATER_SURFACE_LEFT
		update_wario_animation()
		return
	if check_front_collision() != 0:
		return
	if ((wCurWaterCurrent | wLastWaterCurrent) & (CURRENT_RIGHT | CURRENT_LEFT)) != 0:
		return
	if right:
		move_wario_right(apply_walk_velocity_right())
	else:
		move_wario_left(apply_walk_velocity_left())
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0


## HandleWaterSurfaceFloatingMovement: every fourth frame, down for 6 steps, then up for 6.
func handle_water_surface_floating_movement() -> void:
	if (wGlobalCounter & 0b11) != 0:
		return
	wWaterSurfaceFloatingCounter = byte(wWaterSurfaceFloatingCounter + 1)
	if wWaterSurfaceFloatingCounter < 7:
		move_wario_down_without_camera_offset(1)
		return
	if wWaterSurfaceFloatingCounter >= 12:
		wWaterSurfaceFloatingCounter = 0
	move_wario_up_without_camera_offset(1)


## HandleWaterSurfaceInput: A jumps out; with the flippers, B thrusts down into it (Down holds him
## at the surface); Down dives, or only tries to without the flippers or where it is too shallow.
func handle_water_surface_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		start_jump_from_water_surface()
		return
	if (wJoypadPressed & PAD_B) != 0 and wPowerUpLevel >= SWIMMING_FLIPPERS:
		if (wJoypadDown & PAD_UP) != 0:
			return
		probe_presence_centre()
		if wWaterInteraction == NON_SUBMERSIBLE_WATER:
			set_state_trying_submerge()
			return
		move_wario_down(3)
		start_underwater_thrusting()
		return
	if (wJoypadDown & PAD_DOWN) == 0:
		return
	if wPowerUpLevel < SWIMMING_FLIPPERS:
		set_state_trying_submerge()
		return
	probe_presence_centre()
	if wWaterInteraction == NON_SUBMERSIBLE_WATER:
		set_state_trying_submerge()
		return
	set_state_submerged()


## StartJump_FromWaterSurface: a full jump from index 1.
func start_jump_from_water_surface() -> void:
	wJumpVelIndex = 1
	wJumpingUpwards = 1
	wDoFullJump = 1
	start_jump()


## StartJump_FromSand: out of the sand, with the knock-back table (the normal one with High Jump
## Boots and Up held).
func start_jump_from_sand() -> void:
	wJumpVelIndex = 0
	wJumpingUpwards = 1
	wDoFullJump = 1
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	if wPowerUpLevel >= HIGH_JUMP_BOOTS and (wJoypadDown & PAD_UP) != 0:
		wJumpVelTable = JUMP_VEL_NORMAL
	set_state_airborne()


## StartUpwardsUnderwaterThrusting
func start_upwards_underwater_thrusting() -> void:
	wSwimmingDirectionInput = PAD_UP
	set_state_underwater_thrusting()


## StartUnderwaterThrusting: the way the pad points.
func start_underwater_thrusting() -> void:
	wSwimmingDirectionInput = wJoypadDown & PAD_CTRL_PAD
	set_state_underwater_thrusting()


## SetState_UnderwaterThrusting: without a direction, the way he faces.
func set_state_underwater_thrusting() -> void:
	wWarioState = WST_UNDERWATER_THRUSTING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wSFXLoopCounter = 0
	wSwimVelIndex = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	var right: bool
	if wSwimmingDirectionInput == 0:
		right = wDirection == DIRECTION_RIGHT
		wSwimmingDirectionInput = PAD_RIGHT if right else PAD_LEFT
	elif (wSwimmingDirectionInput & PAD_LEFT) != 0:
		right = false
	elif (wSwimmingDirectionInput & PAD_RIGHT) != 0:
		right = true
	else:
		right = wDirection != DIRECTION_LEFT
	wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
	if wPowerUpLevel >= PRINCE_FROGS_GLOVES:
		wWarioFramesetPtr = FRAMESET_THRUST_GLOVES_RIGHT if right else FRAMESET_THRUST_GLOVES_LEFT
	else:
		wWarioFramesetPtr = FRAMESET_THRUST_RIGHT if right else FRAMESET_THRUST_LEFT
	update_wario_animation()


## UpdateState_UnderwaterThrusting
func update_state_underwater_thrusting() -> void:
	wc0e1 = 0
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_UNDERWATER_THRUSTING:
		return
	_sfx_loop(15)
	update_wario_animation()
	handle_underwater_thrusting_input()
	if wWarioState != WST_UNDERWATER_THRUSTING:
		return
	apply_water_current_movement()


## HandleUnderwaterThrustingInput: for 40 frames while A or B is held, along the speed tables;
## a wall across knocks him back, the surface ends it, a ceiling above turns it into a dive.
func handle_underwater_thrusting_input() -> void:
	wSwimVelIndex = byte(wSwimVelIndex + 1)
	if wSwimVelIndex >= 40:
		wSwimVelIndex = 0
		set_state_submerged()
		return
	if (wJoypadDown & (PAD_A | PAD_B)) == 0:
		set_state_submerged()
		return
	var input: int = wSwimmingDirectionInput
	if (input & PAD_RIGHT) != 0:
		_thrust_across(true)
	elif (input & PAD_LEFT) != 0:
		_thrust_across(false)
	elif (input & PAD_UP) != 0:
		_thrust_up()
	elif (input & PAD_DOWN) != 0:
		_thrust_down()


func _thrust_across(right: bool) -> void:
	if check_centre_collision() != 0:
		update_pos_y()
	if wWarioState == WST_WATER_STUNG:
		return
	if (check_bottom_right_breaking() if right else check_bottom_left_breaking()) != 0:
		set_state_swim_knock_back_switch_direction()
		return
	var input: int = wSwimmingDirectionInput
	var table: String = "diagonal" if (input & (PAD_UP | PAD_DOWN)) != 0 else "straight"
	var b: int = tables.swim_steps[table][wSwimVelIndex]
	if right:
		move_wario_right(b)
	else:
		move_wario_left(b)
	if (input & PAD_UP) != 0:
		_thrust_up()
		return
	if (input & PAD_DOWN) != 0:
		_thrust_down()
		return
	# .handle_diagonal_movement: the pad may steer it a pixel up or down.
	var vertical: int = wJoypadDown & (PAD_UP | PAD_DOWN)
	if vertical == 0:
		return
	if (vertical & PAD_DOWN) != 0:
		if check_centre_collision() == 0:
			move_wario_down(1)
			return
		update_pos_y()
		wc0e1 |= PAD_DOWN
		return
	if check_up_collision() != 0:
		wc0e1 |= PAD_UP
		return
	probe_presence_12()
	if wWaterInteraction == 0:
		surface_from_underwater()
		return
	move_wario_up(1)


## HandleUnderwaterThrustingInput.down
func _thrust_down() -> void:
	if check_centre_collision() != 0:
		update_pos_y()
		wc0e1 |= PAD_DOWN
		return
	var table: String = "vertical" if (wSwimmingDirectionInput & (PAD_RIGHT | PAD_LEFT)) != 0 else "straight"
	move_wario_down(tables.swim_steps[table][wSwimVelIndex])


## HandleUnderwaterThrustingInput.up
func _thrust_up() -> void:
	if check_up_collision() != 0:
		wc0e1 |= PAD_UP
		start_dive()
		return
	probe_presence_12()
	if wWaterInteraction == 0:
		surface_from_underwater()
		return
	var table: String = "vertical" if (wSwimmingDirectionInput & (PAD_RIGHT | PAD_LEFT)) != 0 else "straight"
	move_wario_up(tables.swim_steps[table][wSwimVelIndex])


## SetState_SwimKnockBack_SwitchDirection
func set_state_swim_knock_back_switch_direction() -> void:
	wDirection ^= 1
	set_state_swim_knock_back()


## SetState_SwimKnockBack
func set_state_swim_knock_back() -> void:
	wWarioState = WST_SWIM_KNOCK_BACK
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wSwimVelIndex = 0
	wSwimmingDirectionInput = 0
	wc0e0 = 0
	load_wario_gfx(WARIO_SWIM_GFX)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_SWIM_DIVE_LEFT if wDirection != DIRECTION_LEFT else FRAMESET_SWIM_DIVE_RIGHT
	update_wario_animation()


## UpdateState_SwimKnockBack: 2 px a frame for 3 frames, then 1 px for 4, the way he faces; then
## (or at a wall) turned round, submerged.
func update_state_swim_knock_back() -> void:
	if check_front_collision() == 0:
		wWarioStateCounter = byte(wWarioStateCounter + 1)
		if wWarioStateCounter < 8:
			var b: int = 2 if wWarioStateCounter < 4 else 1
			if wDirection == DIRECTION_LEFT:
				move_wario_left(b)
			else:
				move_wario_right(b)
			return
	wDirection ^= 1
	set_state_submerged()


## SetState_WaterStung (object_interactions.asm): stung in water, intangible, invincible from now
## (SFX_STING not simulated).
func set_state_water_stung() -> void:
	wInvincibleCounter = 1
	wWarioState = WST_WATER_STUNG
	wSwimVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsIntangible = 1
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5F7F if wDirection != DIRECTION_LEFT else 0x5F70
	update_wario_animation()


## UpdateState_WaterStung: floating up a pixel every other frame (a current stops), intangible,
## for $78 frames; then invincible, submerged or at the surface.
func update_state_water_stung() -> void:
	update_wario_animation()
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if check_up_collision() != 0:
		if wWarioStateCounter < 0x78:
			return
		wc0e1 = PAD_UP
		_water_stung_recover()
		return
	probe_presence_12()
	if wWaterInteraction == 0:
		if wWarioStateCounter < 0x78:
			return
		wIsIntangible = 0
		wInvincibleCounter = 0x10
		surface_from_underwater()
		return
	if wWarioStateCounter >= 0x78:
		_water_stung_recover()
		return
	if (wGlobalCounter & 1) != 0:
		return
	move_wario_up(1)
	if wWaterCurrent == 0:
		return
	wWaterCurrent = 0
	_water_stung_recover()


func _water_stung_recover() -> void:
	wIsIntangible = 0
	wInvincibleCounter = 0x10
	set_state_submerged()


## SetState_TryingSubmerge
func set_state_trying_submerge() -> void:
	wWarioState = WST_TRYING_SUBMERGE
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_TRYING_SUBMERGE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TRYING_SUBMERGE_LEFT
	update_wario_animation()


## UpdateState_TryingSubmerge: for as long as Down is held.
func update_state_trying_submerge() -> void:
	if (wJoypadDown & PAD_DOWN) == 0:
		set_state_water_surface_idling()
		return
	update_wario_animation()


## HandleDivingHorizontalMovement: with the flippers, a pixel a frame the held way.
func handle_diving_horizontal_movement() -> void:
	if wPowerUpLevel < SWIMMING_FLIPPERS:
		return
	var right: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		right = true
	elif (wJoypadDown & PAD_LEFT) != 0:
		right = false
	else:
		return
	wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
	if check_front_collision() != 0:
		return
	if right:
		move_wario_right(1)
	else:
		move_wario_left(1)


## ApplyWaterCurrentMovement: this frame's current (each probe found it) pushes 2 px unless Wario
## swims with or (with Prince Froggy's Gloves) against it, or something stops him; a change of
## current leaves the last one lingering for 15 frames (ApplyLastWaterCurrentMovement, 1 px).
func apply_water_current_movement() -> void:
	_apply_last_water_current_movement()
	var current: int = wWaterCurrent
	var bit: int = -1
	for candidate: int in [CURRENT_RIGHT, CURRENT_LEFT, CURRENT_UP, CURRENT_DOWN]:
		if (current & candidate) != 0:
			bit = candidate
			break
	if bit < 0:
		if wCurWaterCurrent != 0:
			_change_current_direction()
		wCurWaterCurrent = 0
		return
	if (wCurWaterCurrent & (CURRENT_RIGHT | CURRENT_LEFT | CURRENT_UP | CURRENT_DOWN) & ~bit) != 0:
		_change_current_direction()
	wCurWaterCurrent = wWaterCurrent
	wWaterCurrent &= ~bit
	_push_by_current(bit, 2)


## The push both current routines share; true when something stopped it (blocked or held there).
func _push_by_current(bit: int, b: int) -> bool:
	var along: int = {CURRENT_RIGHT: PAD_RIGHT, CURRENT_LEFT: PAD_LEFT, CURRENT_UP: PAD_UP, CURRENT_DOWN: PAD_DOWN}[bit]
	var against: int = {CURRENT_RIGHT: PAD_LEFT, CURRENT_LEFT: PAD_RIGHT, CURRENT_UP: PAD_DOWN, CURRENT_DOWN: PAD_UP}[bit]
	if (wc0e1 & along) != 0:
		return true
	var blocked: int
	match bit:
		CURRENT_RIGHT:
			blocked = check_bottom_right_breaking()
		CURRENT_LEFT:
			blocked = check_bottom_left_breaking()
		CURRENT_UP:
			blocked = check_up_collision()
		_:
			blocked = check_centre_collision()
	if blocked != 0:
		return true
	if (wSwimmingDirectionInput & along) != 0:
		return false
	if (wSwimmingDirectionInput & against) != 0 and wPowerUpLevel >= PRINCE_FROGS_GLOVES:
		return false
	match bit:
		CURRENT_RIGHT:
			move_wario_right(b)
		CURRENT_LEFT:
			move_wario_left(b)
		CURRENT_UP:
			move_wario_up(b)
		_:
			move_wario_down(b)
	return false


## ApplyWaterCurrentMovement.ChangeCurrentDirection
func _change_current_direction() -> void:
	if wLastWaterCurrent != 0:
		return
	wLastWaterCurrent = byte(wCurWaterCurrent + (15 << 4))


## ApplyLastWaterCurrentMovement: the lingering current, 1 px a frame until its count runs out (or
## something stops it).
func _apply_last_water_current_movement() -> void:
	var last: int = wLastWaterCurrent
	if last == 0:
		return
	var bit: int = -1
	for candidate: int in [CURRENT_RIGHT, CURRENT_LEFT, CURRENT_UP, CURRENT_DOWN]:
		if (last & candidate) != 0:
			bit = candidate
			break
	if bit < 0:
		return
	if _push_by_current(bit, 1):
		wLastWaterCurrent = 0
		return
	wLastWaterCurrent = byte(wLastWaterCurrent - (1 << 4))
	if (wLastWaterCurrent & 0xF0) == 0:
		wLastWaterCurrent = 0


# --- The treasure (wario_states_2.asm) -----------------------------------------------------

## UpdateState_GetTreasureStart: landing first if in the air, then standing for 24 frames more
## (wWarioStateCounter from 24 to 48) before walking 24 frames the way he faces.
func update_state_get_treasure_start() -> void:
	update_wario_animation()
	if wJumpVelTable != 0:
		apply_jump_velocity()
		if check_airborne_collision() == 0:
			return
		wWarioYPos = hYPos
		wJumpVelTable = 0
		wJumpVelIndex = 0
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter < 48:
		return
	wWarioStateCounter = 24
	_set_next_get_treasure_state()


## SetNextGetTreasureState: the next state, walking (Func_1e6ea).
func _set_next_get_treasure_state() -> void:
	wWarioState += 1
	wWarioStateCycles = 0
	_walk_animation()


## Func_1e6ea: the walk's graphics and frameset.
func _walk_animation() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_WALK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_WALK_LEFT
	update_wario_animation()


## UpdateState_GetTreasureWalk: a pixel a frame for wWarioStateCounter frames, then turning to the
## front (the treasure scene's framesets, in "Wario OAM 2").
func update_state_get_treasure_walk() -> void:
	update_wario_animation()
	if wDirection == DIRECTION_LEFT:
		move_wario_left(1)
	else:
		move_wario_right(1)
	wWarioStateCounter = byte(wWarioStateCounter - 1)
	if wWarioStateCounter != 0:
		return
	wWarioState += 1
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCycles = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_1FC31B)
	wWarioFramesetPtr = FRAMESET_TREASURE_TURN_FRONT_RIGHT if wDirection != DIRECTION_LEFT \
			else FRAMESET_TREASURE_TURN_FRONT_LEFT
	update_wario_animation_2()


## Resets the animation and the state's counters for the next treasure state.
func _next_treasure_state(state: int, gfx: int, oam: int, frameset: int) -> void:
	wWarioState = state
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	load_wario_gfx(gfx)
	set_wario_oam(oam)
	wWarioFramesetPtr = frameset
	update_wario_animation_2()


## UpdateState_GetTreasureTurnFront: the first time he laughs; the second he looks to the front.
func update_state_get_treasure_turn_front() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	if wWarioState == WST_GET_TREASURE_TURN_FRONT_2:
		_next_treasure_state(WST_GET_TREASURE_LOOK_FRONT, WARIO_CLEAR_GFX, OAM_1FC000, FRAMESET_TREASURE_LOOK_FRONT)
		return
	_next_treasure_state(WST_GET_TREASURE_LAUGH, WARIO_CLEAR_GFX, OAM_1FC000, FRAMESET_TREASURE_LAUGH)


## UpdateState_GetTreasureLaugh: then turning back to the chest.
func update_state_get_treasure_laugh() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	_next_treasure_state(WST_GET_TREASURE_TURN_BACK, WARIO_IDLE_GFX, OAM_1FC31B,
			FRAMESET_TREASURE_TURN_BACK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TREASURE_TURN_BACK_LEFT)


## UpdateState_GetTreasureTurnBack: then holding the treasure up.
func update_state_get_treasure_turn_back() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wSFXLoopCounter = 0
	_next_treasure_state(WST_GET_TREASURE_OPEN, WARIO_CLEAR_GFX, OAM_1FC000, FRAMESET_TREASURE_OPEN)


## UpdateState_GetTreasureOpen: then turning away to walk (LoadCollectedTreasurePal_Level's palette
## is presentation).
func update_state_get_treasure_open() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wDirection ^= 1
	_next_treasure_state(WST_GET_TREASURE_TURN_WALK, WARIO_IDLE_GFX, OAM_1FC31B,
			FRAMESET_TREASURE_TURN_WALK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TREASURE_TURN_WALK_LEFT)


## UpdateState_GetTreasureTurnWalk: then 32 frames' walk; Wario is no longer moving by himself.
func update_state_get_treasure_turn_walk() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wWarioStateCounter = 32
	wAutoMoveState = 0
	_set_next_get_treasure_state()


## UpdateState_GetTreasureLookFront: then the clear, with the treasure's glow at Wario.
func update_state_get_treasure_look_front() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wWarioState = WST_GET_TREASURE_CLEAR
	hYPos = wWarioYPos
	hXPos = wWarioXPos
	create_particle(PARTICLE_TREASURE_GLOW)
	wWarioStateCounter = 0
	wWarioStateCycles = 0


## UpdateState_GetTreasureClear: 180 frames (A cuts them short), then, once the last particle's
## animation has ended, the level's end screen may begin (wLevelEndScreen bit 7 cleared).
func update_state_get_treasure_clear() -> void:
	if (wJoypadDown & PAD_A) == 0:
		wWarioStateCounter = byte(wWarioStateCounter + 1)
		if wWarioStateCounter < 180:
			return
	if wCurParticleAnimEnded == 0:
		return
	wWarioStateCounter = 0
	wLevelEndScreen &= ~0x80


# --- On Fire (wario_states_3.asm, object_interactions.asm) -------------------------------

## SetState_OnFire: on fire, running by himself. The graphics, palette, and starting frameset are
## set only when wWarioStateCounter is 0 (the first time; a landing keeps them).
func set_state_on_fire() -> void:
	wWarioState = WST_ON_FIRE
	wInvisibleFrame = 0
	wSFXLoopCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	if wWarioStateCounter != 0:
		return
	set_wario_pal(WARIO_ON_FIRE_PAL)
	load_wario_gfx(WARIO_HOT_GFX)
	set_wario_oam(OAM_1673C)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_SET_ON_FIRE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_SET_ON_FIRE_LEFT
	update_wario_animation()


## After the first animation, the running frameset (wWarioStateCounter 1 from then on).
func _on_fire_frameset() -> void:
	if wWarioStateCounter != 0 or wWarioAnimationEnded == 0:
		return
	wWarioStateCounter = 1
	wWarioFramesetPtr = FRAMESET_ON_FIRE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ON_FIRE_LEFT


## DecrementTransformationDuration
func decrement_transformation_duration() -> void:
	wTransformationDuration = word(wTransformationDuration - 1)


## UpdateState_OnFire: running until 300 frames are left, then hot.
func update_state_on_fire() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(14)
	_on_fire_frameset()
	update_wario_animation()
	decrement_transformation_duration()
	if wTransformationDuration == HOT_WARIO_TRANSITION_DURATION:
		set_state_hot()
		return
	_on_fire_run()
	if wWarioState != WST_ON_FIRE:
		return
	if check_centre_collision() == 0:
		_on_fire_fall()
		return
	update_pos_y()


## Func_2ae8a: A jumps when there is room; otherwise he runs (walk index $10-$13), and a wall
## turns him round (2 px back); still against one, on the floor, he is hot at once.
func _on_fire_run() -> void:
	if (wJoypadPressed & PAD_A) != 0 and check_up_collision() == 0:
		_on_fire_jump()
		return
	if check_front_collision() == 0:
		if wDirection == DIRECTION_LEFT:
			move_wario_left(apply_walk_velocity_left())
		else:
			move_wario_right(apply_walk_velocity_right())
		if wWalkVelIndex >= 0x14:
			wWalkVelIndex = 0x10
		return
	if wDirection == DIRECTION_LEFT:
		move_wario_right(2)
		wDirection = DIRECTION_RIGHT
		wWarioFramesetPtr = FRAMESET_SET_ON_FIRE_RIGHT if wWarioStateCounter == 0 else FRAMESET_ON_FIRE_RIGHT
	else:
		move_wario_left(2)
		wDirection = DIRECTION_LEFT
		wWarioFramesetPtr = FRAMESET_SET_ON_FIRE_LEFT if wWarioStateCounter == 0 else FRAMESET_ON_FIRE_LEFT
	update_wario_animation()
	if check_centre_collision() == 0:
		return
	if check_front_collision() != 0:
		set_state_hot_reset_duration()


## Func_2af75: falling along the high jump's table.
func _on_fire_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_HIGH_JUMP
	_set_state_on_fire_airborne()


## Func_2af81: a jump along the normal table.
func _on_fire_jump() -> void:
	wJumpVelIndex = 0
	wJumpVelTable = JUMP_VEL_NORMAL
	_set_state_on_fire_airborne()


## SetState_OnFireAirborne
func _set_state_on_fire_airborne() -> void:
	wWarioStateCycles = 0
	wWarioState = WST_ON_FIRE_AIRBORNE


## UpdateState_OnFireAirborne: running through the air; a ceiling makes him fall, landing he runs
## on. Water puts the fire out (Func_2ade4, which dives: not ported).
func update_state_on_fire_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		_fire_out_in_water()
		return
	_on_fire_frameset()
	update_wario_animation()
	_on_fire_airborne_move()
	if wWarioState != WST_ON_FIRE_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0 or wWarioState != WST_ON_FIRE_AIRBORNE:
			return
		_on_fire_fall()
		return
	if check_airborne_collision() == 0:
		if wWarioState == WST_ON_FIRE_AIRBORNE:
			trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_ON_FIRE_AIRBORNE:
		return
	set_state_on_fire()


## Func_2af9c: the jump and the run; a wall makes him fall, turned round 3 px back (Func_2afc5).
func _on_fire_airborne_move() -> void:
	apply_jump_velocity()
	if wDirection == DIRECTION_LEFT:  # HandleWalk
		walk_left()
	else:
		walk_right()
	if wWalkVelIndex >= 0x14:
		wWalkVelIndex = 0x10
	if check_front_collision() == 0:
		return
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	on_fire_turn()


## Func_2afc5: turned round, 3 px back.
func on_fire_turn() -> void:
	wDirection ^= 1
	if wDirection == DIRECTION_LEFT:
		move_wario_left(3)
		wWarioFramesetPtr = FRAMESET_SET_ON_FIRE_LEFT if wWarioStateCounter == 0 else FRAMESET_ON_FIRE_LEFT
	else:
		move_wario_right(3)
		wWarioFramesetPtr = FRAMESET_SET_ON_FIRE_RIGHT if wWarioStateCounter == 0 else FRAMESET_ON_FIRE_RIGHT
	update_wario_animation()


## Func_2ade4: water puts the fire out (invincible from $10), in a puff of smoke at the surface.
func _fire_out_in_water() -> void:
	clear_transformation_values()
	wInvincibleCounter = 0x10
	get_pos()
	hYPos = (hYPos & 0xFF00) | (lo(hYPos) & 0xF0)
	create_particle(PARTICLE_SMOKE_LARGE)
	dive_from_surface_skip_splash()


## SetState_Hot_ResetDuration
func set_state_hot_reset_duration() -> void:
	wTransformationDuration = HOT_WARIO_TRANSITION_DURATION
	set_state_hot()


## SetState_Hot: hot, walking slowly where the joypad says; touching objects makes them vanish.
func set_state_hot() -> void:
	wTransformationProgress = 2
	wWarioState = WST_HOT
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wStingTouchState = TOUCH_VANISH
	wTouchState = TOUCH_VANISH
	wca94 = 2
	wFrameDuration = 0
	wAnimationFrame = 0
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		wDirection = DIRECTION_RIGHT if (wJoypadDown & PAD_RIGHT) != 0 else DIRECTION_LEFT
	_hot_frameset()


func _hot_frameset() -> void:
	wWarioFramesetPtr = FRAMESET_HOT_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_HOT_LEFT
	update_wario_animation()


## UpdateState_Hot: the palette cools at 224, 164, and 60 frames left; at 1, burnt.
func update_state_hot() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(16)
	update_wario_animation()
	decrement_transformation_duration()
	if hi(wTransformationDuration) == 0:
		match lo(wTransformationDuration):
			224:
				set_wario_pal(WARIO_HOT_1_PAL)
			164:
				set_wario_pal(WARIO_HOT_2_PAL)
			60:
				set_wario_pal(WARIO_HOT_3_PAL)
			1:
				_set_state_burnt()
				return
	_handle_hot_wario_input()
	if wWarioState != WST_HOT:
		return
	if check_centre_collision() == 0:
		_hot_fall_centred()
		return
	update_pos_y()


func _set_state_burnt() -> void:
	wWarioState = WST_BURNT
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	set_wario_pal(WARIO_ON_FIRE_PAL)
	load_wario_gfx(WARIO_BURNT_GFX)
	set_wario_oam(OAM_16B6C)
	wWarioFramesetPtr = FRAMESET_BURNT_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_BURNT_LEFT
	update_wario_animation()


## HandleHotWarioInput: a pixel a frame the held way, turning first.
func _handle_hot_wario_input() -> void:
	var held: int = wJoypadDown & (PAD_RIGHT | PAD_LEFT)
	if held == 0:
		return
	var right: bool = (held & PAD_RIGHT) != 0
	if right != (wDirection != DIRECTION_LEFT):
		wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
		wFrameDuration = 0
		wAnimationFrame = 0
		_hot_frameset()
	if check_front_collision() != 0:
		return
	if right:
		move_wario_right(1)
	else:
		move_wario_left(1)


## Func_28380: off the floor, centred on his block's column, then falling (Func_2838a).
func _hot_fall_centred() -> void:
	wWarioXPos = (wWarioXPos & 0xFF00) | ((lo(wWarioXPos) & 0xF0) + 0x08)
	_hot_fall()


## Func_2838a: falling along the normal table, the joypad ignored for 8 frames.
func _hot_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_NORMAL
	wWarioState = WST_HOT_AIRBORNE
	wWarioStateCounter = 8


## UpdateState_HotAirborne
func update_state_hot_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		_fire_out_in_water()
		return
	update_wario_animation()
	_hot_airborne_move()
	if wWarioState != WST_HOT_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0 or wWarioState != WST_HOT_AIRBORNE:
			return
		_hot_fall()
		return
	if check_airborne_collision() == 0:
		if wWarioState == WST_HOT_AIRBORNE:
			trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_HOT_AIRBORNE:
		return
	set_state_hot()


## Func_2b027: the fall; after wWarioStateCounter frames the joypad walks him (walk index $04-$07),
## and a turn restarts the frameset.
func _hot_airborne_move() -> void:
	apply_jump_velocity()
	if wWarioStateCounter != 0:
		wWarioStateCounter -= 1
		return
	if (wJoypadDown & PAD_RIGHT) != 0:  # Func_2b17a
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	if wWalkVelIndex >= 0x08:
		wWalkVelIndex = 0x04
	if wIsTurning == 0:
		return
	wFrameDuration = 0
	wAnimationFrame = 0
	_hot_frameset()


## UpdateState_Burnt: when the animation ends, Wario recovers.
func update_state_burnt() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		recover_from_transformation()


# --- Ball o' String (wario_states_3.asm) ---------------------------------------------------

## UpdateState_GettingWrappedInString: wrapped until the animation ends; then rolling on the floor,
## or falling without one.
func update_state_getting_wrapped_in_string() -> void:
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	if check_centre_collision() == 0:
		_ball_o_string_fall()
		return
	set_state_ball_o_string()


## SetState_BallOString
func set_state_ball_o_string() -> void:
	wWarioState = WST_BALL_O_STRING
	wTransformationProgress = 1
	wSFXLoopCounter = 0
	wWalkVelIndex = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-24)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	_ball_o_string_frameset()


func _ball_o_string_frameset() -> void:
	wWarioFramesetPtr = FRAMESET_BALL_O_STRING_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_BALL_O_STRING_LEFT
	update_wario_animation()


## UpdateState_BallOString: rolling by itself (the walk index cycling $14-$17); a wall or a slope
## rising against it turns it, and the fifth turn knocks the string loose.
func update_state_ball_o_string() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(12)
	update_wario_animation()
	if wDirection == DIRECTION_LEFT:
		move_wario_left(apply_walk_velocity_left())
	else:
		move_wario_right(apply_walk_velocity_right())
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if (check_front_collision() & 0x0F) != 0:
		_ball_o_string_turn()
		return
	if check_centre_collision() == 0:
		_ball_o_string_fall()
		return
	update_pos_y()
	if wWarioSlopeInteraction != 0 and _against_slope():
		_ball_o_string_turn()


## Func_28bd5
func _ball_o_string_turn() -> void:
	wDirection ^= 1
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter >= 5:
		set_state_ball_o_string_knock_back()
		return
	_ball_o_string_frameset()


## Func_28c15: falling along the high jump's table.
func _ball_o_string_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_HIGH_JUMP
	wWarioState = WST_BALL_O_STRING_AIRBORNE


## UpdateState_BallOStringAirborne: rolling on through the air; water undoes the string.
func update_state_ball_o_string_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation()
	if (check_front_collision() & 0x0F) != 0:
		_ball_o_string_turn()
		return
	apply_jump_velocity()
	if wDirection == DIRECTION_LEFT:  # HandleWalk
		walk_left()
	else:
		walk_right()
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	set_state_ball_o_string()


## SetState_BallOStringKnockBack
func set_state_ball_o_string_knock_back() -> void:
	wTransformationProgress = 0
	wWarioState = WST_BALL_O_STRING_KNOCK_BACK
	wJumpVelIndex = 0x0A
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_BALL_O_STRING_KNOCK_BACK
	update_wario_animation()


## UpdateState_BallOStringKnockBack: a hop back (Func_2b1cc); landing, he turns round and the
## string comes off.
func update_state_ball_o_string_knock_back() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation()
	_hop_back()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	wDirection ^= 1
	trigger_floor_transition()
	wWarioState = WST_GETTING_UNWRAPPED_IN_STRING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_GETTING_UNWRAPPED
	update_wario_animation()


## Func_2b1cc: 2 px the way he faces (undone against a wall, Func_197b1/Func_19741), along
## JumpVelTable_Normal.
func _hop_back() -> void:
	if wDirection == DIRECTION_LEFT:
		move_wario_left(2)
		if check_bottom_left_breaking() != 0:
			move_wario_right(2)
	else:
		move_wario_right(2)
		if check_bottom_right_breaking() != 0:
			move_wario_left(2)
	var step: int = tables.jump_steps[JUMP_VEL_NORMAL][wJumpVelIndex]
	if step < 0:
		move_wario_up(-step)
		wJumpVelIndex += 1
		return
	move_wario_down(step)
	wJumpVelIndex += 1
	if wJumpVelIndex >= MAX_JUMP_VEL_INDEX:
		wJumpVelIndex = MAX_JUMP_VEL_INDEX


## UpdateState_GettingUnwrappedInString: then dizzy and intangible.
func update_state_getting_unwrapped_in_string() -> void:
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	wWarioState = WST_BALL_O_STRING_DIZZY
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsIntangible = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_DIZZY_GFX)
	set_wario_oam(OAM_17BBC)
	wWarioFramesetPtr = FRAMESET_DIZZY
	update_wario_animation()


## UpdateState_BallOStringDizzy: when the animation ends, Wario recovers.
func update_state_ball_o_string_dizzy() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		recover_from_transformation()


## ClearTransformationValues (home/clear_transformation.asm), as far as the port's variables go.
func clear_transformation_values() -> void:
	wInvincibleCounter = 0
	wTransformation = 0
	wTransformationProgress = 0
	wStingTouchState = 0
	wTouchState = 0
	wca94 = 0
	wIsIntangible = 0
	wTransformationDuration = 0
	wAutoMoveState = 0
	wInvisibleFrame = 0
	wSwimmingDirectionInput = 0


## RecoverFromTransformation: back to normal (invincible from $10), standing or falling.
func recover_from_transformation() -> void:
	clear_transformation_values()
	wInvincibleCounter = 0x10
	set_wario_pal(WARIO_DEFAULT_PAL)
	if wJumpVelTable != 0:
		start_fall()
	else:
		set_state_idling()


## RecoverFromTransformation_WithoutInvincibility (the music and the recovery sound are not
## simulated).
func recover_from_transformation_without_invincibility() -> void:
	clear_transformation_values()
	set_wario_pal(WARIO_DEFAULT_PAL)
	if wJumpVelTable != 0:
		start_fall()
	else:
		set_state_idling()


func _stung_recover() -> void:
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_STUNG_RECOVERY


## UpdateState_StungRecovery: $14 frames, then Wario turns back, is invincible for a while, and
## stands (or crouches, without room or with Down held).
func update_state_stung_recovery() -> void:
	flicker_stung_pal()
	update_wario_animation()
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter < 0x14:
		return
	wDirection ^= 1
	wInvincibleCounter = 0x10
	set_wario_pal(WARIO_DEFAULT_PAL)
	wCollisionBoxTop = byte(-27)
	var b: int = check_up_collision()
	if wWarioState != WST_STUNG_RECOVERY:
		return
	if b == 0 and (wJoypadDown & PAD_DOWN) == 0:
		set_state_idling()
		return
	wCollisionBoxTop = byte(-15)
	crouch_or_slide()


# --- Ladders (wario_states_2.asm) --------------------------------------------------------------

## SetState_LadderClimbing: centred on the ladder's column.
func set_state_ladder_climbing() -> void:
	wWarioState = WST_LADDER_CLIMBING
	wWarioXPos = (wWarioXPos & 0xFF00) | byte((lo(wWarioXPos) & 0xF0) + 0x08)
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsGettingOffLadder = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wCollisionBoxTop = byte(-27)
	load_wario_gfx(WARIO_LADDER_GFX)
	set_wario_oam(OAM_155CC)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_LADDER_CLIMB
	update_wario_animation()


## UpdateState_LadderClimbing
func update_state_ladder_climbing() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(32)
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		get_pos()
		create_particle(PARTICLE_DUST)
	handle_ladder_input()


## HandleLadderInput: B+Down slides, Up and Down climb 1 px a frame, nothing held idles.
func handle_ladder_input() -> void:
	if (wJoypadDown & (PAD_B | PAD_DOWN)) == (PAD_B | PAD_DOWN):
		set_state_ladder_sliding()
		return
	if (wJoypadDown & PAD_UP) != 0:
		check_up_collision()
		if wJumpCollision != 0:
			return
		move_wario_up(1)
		if _transitions_enabled():
			var c: int = get_floor_for_y_pos()
			if wFloor < c:
				start_upwards_floor_transition(c)
				return
		if wLadderInteraction != 0:
			return
		probe_presence_centre()
		if wLadderInteraction != 0:
			return
		set_state_idling()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		move_wario_down(1)
		if _transitions_enabled():
			var c: int = get_floor_for_y_pos()
			if wFloor > c:
				start_downwards_floor_transition(c)
				return
		probe_presence_centre()
		if wLadderInteraction != 0:
			if check_centre_collision() == 0:
				return
			wWarioXPos = (wWarioXPos & 0xFF00) | byte((lo(wWarioXPos) & 0xF0) + 0x08)
			return
		if check_centre_collision() != 0:
			set_state_idling()
			return
		start_fall()
		return
	set_state_ladder_idling()


## SetState_LadderIdling
func set_state_ladder_idling() -> void:
	wWarioState = WST_LADDER_IDLING
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wIsGettingOffLadder = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wCollisionBoxTop = byte(-27)
	load_wario_gfx(WARIO_LADDER_GFX)
	set_wario_oam(OAM_155CC)
	wWarioFramesetPtr = FRAMESET_LADDER_IDLE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_LADDER_IDLE_LEFT
	update_wario_animation()


## UpdateState_LadderIdling
func update_state_ladder_idling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wLadderInteraction == 0:
		start_fall()
		return
	update_wario_animation()
	handle_input_ladder_idling()


## Func_1b480: B with a direction gets off the ladder if the side is clear; Up or Down climbs;
## otherwise after $200 frames Wario scratches.
func handle_input_ladder_idling() -> void:
	if (wJoypadDown & PAD_B) != 0 and (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		var blocked: int
		if (wJoypadDown & PAD_RIGHT) != 0:
			wCollisionBoxRight = 16
			blocked = check_bottom_right_breaking()
		else:
			wCollisionBoxLeft = byte(-16)
			blocked = check_bottom_left_breaking()
		wCollisionBoxLeft = byte(-9)
		wCollisionBoxRight = 9
		if blocked == 0:
			set_state_getting_off_ladder()
		return
	if (wJoypadDown & (PAD_UP | PAD_DOWN)) != 0:
		set_state_ladder_climbing()
		return
	var counter: int = wWarioStateCounter + 1
	wWarioStateCounter = byte(counter)
	wWarioStateCycles = byte(wWarioStateCycles + (counter >> 8))
	if wWarioStateCycles >= 0x02:
		set_state_ladder_scratching()


## UpdateState_LadderShakeSlipping: shaken off, 2 px a frame down until the ground or $40 frames.
func update_state_ladder_shake_sliding() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wLadderInteraction == 0:
		start_fall()
		return
	update_wario_animation()
	move_wario_down(2)
	if _transitions_enabled():
		var c: int = get_floor_for_y_pos()
		if wFloor > c:
			start_downwards_floor_transition(c)
	if check_airborne_collision() != 0:
		update_pos_y()
		set_state_idling()
		return
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter < 0x40:
		return
	wWarioStateCounter = 0
	set_state_ladder_idling()


## SetState_GettingOffLadder
func set_state_getting_off_ladder() -> void:
	wWarioState = WST_GETTING_OFF_LADDER
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsGettingOffLadder = 1
	wIsIntangible = 1
	wDirection = DIRECTION_RIGHT if (wJoypadDown & PAD_RIGHT) != 0 else DIRECTION_LEFT


## UpdateState_GettingOffLadder: 1 px a frame sideways until the ladder is left, then a fall.
func update_state_getting_off_ladder() -> void:
	_sfx_loop(32)
	if wDirection == DIRECTION_LEFT:
		move_wario_left(1)
	else:
		move_wario_right(1)
	probe_presence_top()
	if wLadderInteraction != 0:
		return
	wIsGettingOffLadder = 0
	wIsIntangible = 0
	start_fall()


## SetState_LadderSliding
func set_state_ladder_sliding() -> void:
	wWarioState = WST_LADDER_SLIDING
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsGettingOffLadder = 0
	wJumpVelTable = 1
	if wPowerUpLevel >= LEAD_OVERALLS:
		wIsSmashAttacking = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_LADDER_SLIDE
	update_wario_animation()


## UpdateState_LadderSliding: 2 px a frame down; Up grabs on again.
func update_state_ladder_sliding() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wLadderInteraction == 0:
		wIsSmashAttacking = 0
		start_fall()
		return
	update_wario_animation()
	if (wJoypadDown & PAD_UP) != 0:
		set_state_ladder_climbing()
		return
	move_wario_down(2)
	if _transitions_enabled():
		var c: int = get_floor_for_y_pos()
		if wFloor > c:
			start_downwards_floor_transition(c)
	if check_airborne_collision() == 0:
		return
	update_pos_y()
	if wIsSmashAttacking != 0:  # landing from a smash attack down the ladder
		if wPowerUpLevel < SUPER_JUMP_SLAM_OVERALLS:
			do_ground_pound()
		else:
			do_wario_ground_shake()
		return
	set_state_idling()


## SetState_LadderScratching
func set_state_ladder_scratching() -> void:
	wWarioState = WST_LADDER_SCRATCHING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsGettingOffLadder = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_LADDER_SCRATCH_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_LADDER_SCRATCH_LEFT
	update_wario_animation()


## UpdateState_LadderScratching: until its animation ends or any button is held.
func update_state_ladder_scratching() -> void:
	update_wario_animation()
	if wJoypadDown == 0 and wWarioAnimationEnded == 0:
		return
	set_state_ladder_idling()


# --- Room transitions and doors -----------------------------------------------------------------

## TriggerRoomTransition (home/room_transition.asm): Wario is intangible from now; unless delayed (a
## door's animation first), the level moves on: +1 sub-state for a door (DoorTransition), +2 for
## anything else (FastFadeToWhite). The room changes in LevelSim.start_room_from_transition.
func trigger_room_transition() -> void:
	wBossState = 0
	wGrabState = 0
	wRoomPalCycleDuration = 0
	wRoomAnimatedPalsEnabled = 0
	wWaterCurrent = 0
	wLastWaterCurrent = 0
	wCurWaterCurrent = 0
	wIsBossBattle = 0
	wIsIntangible = 1
	if (wRoomTransitionParam & (1 << ROOMTRANSITIONF_DELAY_F)) != 0:
		return
	if (wRoomTransitionParam & ROOMTRANSITIONF_DOOR) != 0:
		wSubState = byte(wSubState + 1)
	else:
		wSubState = byte(wSubState + 2)


## Func_206eb: a sting ends a vulnerable transformation (ClearTransformationValues; the music not
## simulated), then SetState_Stung. Owl Wario lets go of the owl first (ReleaseOwl).
func sting_out_of_transformation() -> void:
	if wTransformation == TRANSFORMATION_OWL_WARIO:
		release_owl()
	clear_transformation_values()
	set_state_stung()


## SetState_Stung (a sting, BlockFunc_NonSolidSpike): invincible from now (counter 1), thrown back on the knock-back table unless
## there is no headroom while crouching.
func set_state_stung() -> void:
	wInvincibleCounter = 1
	wWarioState = WST_STUNG
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelIndex = 6
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	var saved_y: int = hYPos
	var saved_x: int = hXPos
	var headroom: bool = true
	if wIsCrouching != 0:
		wCollisionBoxTop = byte(-27)
		headroom = check_up_collision() == 0
		if headroom:
			wIsCrouching = 0
	hYPos = saved_y
	hXPos = saved_x
	if headroom:
		wCollisionBoxTop = byte(-27)
		wJumpVelTable = JUMP_VEL_KNOCK_BACK
	else:
		wCollisionBoxTop = byte(-15)
		wJumpVelTable = 0
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_ROLL_BUMP_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ROLL_BUMP_LEFT
	update_wario_animation()


## EnterPipeDown and EnterPipeUp (block_functions.asm): the pipe's room transition, delayed until
## Wario is through (UpdateState_PipeGoingDown and _Up).
func enter_pipe(down: bool) -> void:
	wRoomTransitionParam = ROOMTRANSITION_PIPE | ROOMTRANSITIONF_RELOAD_OBJECTS | ROOMTRANSITIONF_DELAY
	wWarioState = WST_PIPE_GOING_DOWN if down else WST_PIPE_GOING_UP
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	if down:
		wIsSmashAttacking = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wWarioFramesetPtr = FRAMESET_PIPE
	update_wario_animation()


## UpdateState_PipeGoingDown and _PipeGoingUp: intangible, a pixel a frame through the pipe; at 32
## frames the transition (transformations cleared), and in the new room on out of the pipe until
## 64, then 8 px back left and idling (coming up, on the floor it is now on).
func update_state_pipe(down: bool) -> void:
	wIsIntangible = 1
	update_wario_animation()
	if down:
		move_wario_down(1)
	else:
		move_wario_up(1)
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter == 0x20:
		clear_transformation_values()
		wRoomTransitionParam &= ~ROOMTRANSITIONF_DELAY
		trigger_room_transition()
		return
	if wWarioStateCounter < 0x40:  # $21: SFX_PIPE_EXIT
		return
	wWarioXPos = (wWarioXPos & 0xFF00) | byte(lo(wWarioXPos) - 8)
	wIsIntangible = 0
	if not down:
		wFloor = get_floor_for_y_pos()
	set_state_idling()


## EnterDoor (block_functions.asm): centred on the door, facing into it.
func enter_door() -> void:
	wWarioXPos = (wWarioXPos & 0xFF00) | byte((lo(wWarioXPos) & 0xF0) + 0x08)
	wWarioState = WST_ENTERING_DOOR
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wWarioFramesetPtr = FRAMESET_DOOR_ENTER_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_DOOR_ENTER_LEFT
	update_wario_animation()


## UpdateState_EnteringDoor: two animations into the door, the transition (counter 1 -> 2), one
## frame in the new room, then out of the door to walking or idling.
func update_state_entering_door() -> void:
	_sfx_loop(36)
	update_wario_animation()
	match wWarioStateCounter:
		1:
			if wWarioAnimationEnded == 0:
				return
			wWarioStateCounter += 1
			wRoomTransitionParam &= ~(1 << ROOMTRANSITIONF_DELAY_F)
			trigger_room_transition()
		2:
			wWarioStateCounter += 1
		3:
			if wWarioAnimationEnded == 0:
				return
			if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
				set_state_walking_reset_walk_vel()
			else:
				set_state_idling()
		_:
			if wWarioAnimationEnded == 0:
				return
			wFrameDuration = 0
			wAnimationFrame = 0
			wWarioFramesetPtr = FRAMESET_DOOR_THROUGH
			update_wario_animation()
			wWarioStateCounter += 1


# --- Sand (wario_states_2.asm) ------------------------------------------------------------

## SetState_SandFalling: sinking in sand, Wario's normal box, the default palette.
func set_state_sand_falling() -> void:
	wGrabState = 0
	wWarioState = WST_SAND_FALLING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wAttackCounter = 0
	wIsRolling = 0
	wSwimVelIndex = 0
	wIsCrouching = 0
	wc0e0 = 0
	set_wario_pal(WARIO_DEFAULT_PAL)
	_sand_airborne_gfx()


## Func_1a12a: the airborne graphics, then Func_1a14b.
func _sand_airborne_gfx() -> void:
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	_sand_airborne_frameset()


## Func_1a14b: the airborne frameset the way he faces.
func _sand_airborne_frameset() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_AIRBORNE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_AIRBORNE_LEFT
	update_wario_animation()


## UpdateState_SandFalling: Func_1b2c0, then standing in the sand where the centre probe finds it.
func update_state_sand_falling() -> void:
	_sand_fall_step()
	if wWarioState != WST_SAND_FALLING:
		return
	if check_centre_collision() == 0:
		return
	wWarioYPos = hYPos
	set_state_sand_idling()


## Func_1b2c0: A jumps; otherwise he sinks (Func_1b302) and, with no wall in front, moves with
## the pad at the walk's speed (Func_2b17a, its index kept below 4).
func _sand_fall_step() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		set_state_sand_jumping()
		return
	_sand_sink()
	if check_front_collision() != 0:
		return
	_sand_walk_with_pad()


## Func_2b17a and the index cap after it; a turn restarts the airborne frameset (Func_1a14b).
func _sand_walk_with_pad() -> void:
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0
	if wIsTurning != 0:
		_sand_airborne_frameset()


## Func_1b302: unless the centre probe finds something, down 1 px (2 with Down held).
func _sand_sink() -> void:
	if check_centre_collision() != 0:
		return
	move_wario_down(2 if (wJoypadDown & PAD_DOWN) != 0 else 1)


## SetState_SandJumping: rising along the knock-back table (SFX_JUMP not simulated).
func set_state_sand_jumping() -> void:
	wWarioState = WST_SAND_JUMPING
	wJumpVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	_sand_airborne_gfx()


## UpdateState_SandJumping: out of the sand, a jump (StartJump_FromSand); in it, rising while A is
## held and nothing is above, moving with the pad; otherwise sinking again.
func update_state_sand_jumping() -> void:
	probe_presence_top()
	if wIsInSand == 0:
		start_jump_from_sand()
		return
	apply_jump_velocity()
	_sand_walk_with_pad()
	if (wJoypadDown & PAD_A) == 0 or wJumpVelIndex >= FALLING_JUMP_VEL_INDEX:
		set_state_sand_falling()
		return
	if check_up_collision() != 0:
		set_state_sand_falling()


## SetState_SandIdling: standing in the sand.
func set_state_sand_idling() -> void:
	wWarioState = WST_SAND_IDLING
	wJumpVelIndex = 0
	wJumpVelTable = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14000)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_IDLE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_IDLE_LEFT
	update_wario_animation()


## UpdateState_SandIdling (Func_1b322): A jumps, Left or Right walks.
func update_state_sand_idling() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		set_state_sand_jumping()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_sand_walking()


## SetState_SandWalking: facing the way held, the walk's graphics (Func_1e6ea).
func set_state_sand_walking() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_SAND_WALKING
	if (wJoypadDown & PAD_RIGHT) != 0:
		wDirection = DIRECTION_RIGHT
	elif (wJoypadDown & PAD_LEFT) != 0:
		wDirection = DIRECTION_LEFT
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = FRAMESET_WALK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_WALK_LEFT
	update_wario_animation()


## UpdateState_SandWalking: the walk sound's counter (36 frames; the sound is not simulated), the
## animation, Func_1b333; then a room transition, or sinking where the centre finds nothing.
func update_state_sand_walking() -> void:
	var sfx: int = wSFXLoopCounter - 1
	wSFXLoopCounter = 0x24 if sfx < 0 else sfx
	update_wario_animation()
	_sand_walk_step()
	if wWarioState != WST_SAND_WALKING:
		return
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if check_centre_collision() == 0:
		set_state_sand_falling()


## Func_1b333: A jumps; the pad walks (facing the other way turns: unreachable, as the original's
## comment notes, since the idle state has already turned him); no pad, idling.
func _sand_walk_step() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		set_state_sand_jumping()
		return
	var right: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		right = true
	elif (wJoypadDown & PAD_LEFT) != 0:
		right = false
	else:
		set_state_sand_idling()
		return
	if (wDirection != DIRECTION_LEFT) != right:
		set_state_sand_turning()
		return
	wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
	if check_front_collision() != 0:
		return
	if right:
		move_wario_right(apply_walk_velocity_right())
	else:
		move_wario_left(apply_walk_velocity_left())
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0


## SetState_SandTurning
func set_state_sand_turning() -> void:
	wWarioState = WST_SAND_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wDirection ^= 1
	wWarioFramesetPtr = FRAMESET_TURN_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TURN_LEFT
	update_wario_animation()


## UpdateState_SandTurning: A jumps; when the animation ends, walking or idling.
func update_state_sand_turning() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		set_state_sand_jumping()
		return
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_sand_walking()
	else:
		set_state_sand_idling()


# --- Fat Wario (wario_states_3.asm) -------------------------------------------------------

## The state's frameset the way Wario faces, from the animation's start.
func _fat_frameset(left: int, right: int) -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = right if wDirection != DIRECTION_LEFT else left
	update_wario_animation()


## SetState_FatEating's tail (ObjInteraction_Food): eating, Wario's normal box, the fat graphics.
func set_state_fat_eating() -> void:
	wWarioState = WST_FAT_EATING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	load_wario_gfx(WARIO_FAT_GFX)
	set_wario_oam(OAM_1742D)
	_fat_frameset(0x789C, 0x78C3)


## SetState_FatBumping: bumped (by attacking an object while fat).
func set_state_fat_bumping() -> void:
	wWarioState = WST_FAT_BUMPING
	wJumpVelIndex = 0
	wJumpVelTable = 0
	_fat_frameset(0x78FC, 0x7905)


## UpdateState_FatBumping: idling when the animation ends.
func update_state_fat_bumping() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		set_state_fat_idling()


## UpdateState_FatEating: a room transition, water (Func_2926a), or falling to the floor while
## eating; when the animation ends, idling.
func update_state_fat_eating() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		set_state_fat_sinking()
		return
	if wJumpVelTable != 0:
		apply_jump_velocity()
		if check_airborne_collision() == 0:
			trigger_downwards_floor_transition()
			return
		trigger_floor_transition()
		wJumpVelTable = 0
		wJumpVelIndex = 0
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	set_state_fat_idling()


## SetState_FatIdling: Wario's touches attack.
func set_state_fat_idling() -> void:
	wWarioState = WST_FAT_IDLING
	wTouchState = TOUCH_ATTACK
	wStingTouchState = TOUCH_ATTACK
	wca94 = 1
	wJumpVelIndex = 0
	wJumpVelTable = 0
	_fat_frameset(0x781C, 0x781F)


## UpdateState_FatIdling: A jumps, the pad walks; nothing under him, a fall (Func_290d6).
func update_state_fat_idling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if (wJoypadPressed & PAD_A) != 0:
		_fat_jump()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_fat_walking()
		return
	if check_centre_collision() == 0:
		_fat_fall()


## SetState_FatWalking
func set_state_fat_walking() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_FAT_WALKING
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	_fat_frameset(0x7822, 0x782B)


## UpdateState_FatWalking: the sound's counter (28 frames; SFX_FAT_WALK not simulated), the
## animation, and the transformation's time (recovering when it runs out or under); then
## Func_2b239, and a fall where nothing is under him.
func update_state_fat_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	var sfx: int = wSFXLoopCounter - 1
	wSFXLoopCounter = 28 if sfx < 0 else sfx
	update_wario_animation()
	decrement_transformation_duration()
	if (wTransformationDuration >> 8) >= (FAT_WARIO_DURATION >> 8) + 1 or wTransformationDuration == 0:
		set_state_fat_recovering()
		return
	_fat_walk_step()
	if wWarioState != WST_FAT_WALKING:
		return
	if check_centre_collision() == 0:
		_fat_fall()
		return
	wWarioYPos = hYPos


## Func_2b239: A jumps; the pad walks the way he faces (WalkIfPossible, the index between 4 and
## 7 once past 8) or turns him; no pad, idling.
func _fat_walk_step() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		_fat_jump()
		return
	var right: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		right = true
	elif (wJoypadDown & PAD_LEFT) != 0:
		right = false
	else:
		set_state_fat_idling()
		return
	if (wDirection != DIRECTION_LEFT) != right:
		wDirection = DIRECTION_RIGHT if right else DIRECTION_LEFT
		set_state_fat_turning()
		return
	if right:
		walk_if_possible_right()
	else:
		walk_if_possible_left()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4


## SetState_FatTurning: the turn's frameset for the way he now faces.
func set_state_fat_turning() -> void:
	wWarioState = WST_FAT_TURNING
	_fat_frameset(0x78F3, 0x78EA)


## UpdateState_FatTurning: A jumps; then walking.
func update_state_fat_turning() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		_fat_jump()
		return
	if wWarioAnimationEnded != 0:
		set_state_fat_walking()


## Func_290a1: a jump along the knock-back table (SFX_JUMP not simulated).
func _fat_jump() -> void:
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wWarioFramesetPtr = 0x7839 if wDirection != DIRECTION_LEFT else 0x7834
	_set_state_fat_airborne()


## Func_290d6: a fall that smashes when it lands.
func _fat_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wIsSmashAttacking = 1
	wWarioStateCounter = 1
	wJumpVelTable = JUMP_VEL_NORMAL
	wWarioFramesetPtr = 0x7841 if wDirection != DIRECTION_LEFT else 0x783E
	_set_state_fat_airborne()


## SetState_FatAirborne: with the frameset its caller chose.
func _set_state_fat_airborne() -> void:
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	update_wario_animation()
	wWarioState = WST_FAT_AIRBORNE


## UpdateState_FatAirborne: the transformation's time runs (kept from running out in the air);
## after the jump's animation, the fall's; Func_2b2a4 moves him; rising, a ceiling turns it into
## a fall; landing shakes the ground ($20 frames) and lands.
func update_state_fat_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		set_state_fat_sinking()
		return
	decrement_transformation_duration()
	if wTransformationDuration == 0:
		wTransformationDuration = 1
	update_wario_animation()
	if wWarioStateCounter == 0 and wWarioAnimationEnded != 0:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioStateCounter = 1
		wWarioFramesetPtr = 0x7841 if wDirection != DIRECTION_LEFT else 0x783E
		update_wario_animation()
	_fat_airborne_move()
	if wWarioState != WST_FAT_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0 or wWarioState != WST_FAT_AIRBORNE:
			return
		_fat_fall()
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 0x20
		wIsWarioGroundShaking = 1
	set_state_fat_landing()


## Func_2b2a4: the jump's velocity and the pad's walk (the index between 4 and 7 once past 8);
## falling, he smashes.
func _fat_airborne_move() -> void:
	apply_jump_velocity()
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if wJumpVelIndex == FALLING_JUMP_VEL_INDEX:
		wIsSmashAttacking = 1


## SetState_FatLanding (SFX_024 not simulated).
func set_state_fat_landing() -> void:
	wWarioState = WST_FAT_LANDING
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	_fat_frameset(0x7872, 0x7887)


## UpdateState_FatLanding: recovering when the time is out (or under); idling when the ground has
## stopped shaking.
func update_state_fat_landing() -> void:
	decrement_transformation_duration()
	if (wTransformationDuration >> 8) >= 2 or wTransformationDuration == 0:
		set_state_fat_recovering()
		return
	update_wario_animation()
	if wGroundShakeCounter == 0:
		set_state_fat_idling()


## Func_2926a: into water, a splash at the surface, then sinking, intangible.
func set_state_fat_sinking() -> void:
	get_pos()
	hYPos = (hYPos & 0xFF00) | (lo(hYPos) & 0xF0)
	create_particle(PARTICLE_SPLASH)
	wWarioState = WST_FAT_SINKING
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsIntangible = 1
	_fat_frameset(0x7872, 0x7887)


## UpdateState_FatSinking: bubbles every 16 frames (Func_29317), down a pixel a frame; on the
## bottom, the transformation ends under water (Func_2ad6a).
func update_state_fat_sinking() -> void:
	update_wario_animation()
	if (wGlobalCounter & 0x0F) == 0:
		hYPos = word(wWarioYPos - 0x10)
		hXPos = word(wWarioXPos + (4 if wDirection != DIRECTION_LEFT else -4))
		create_particle(PARTICLE_BUBBLES)
	move_wario_down(1)
	if check_centre_collision() == 0:
		return
	recover_submerged()


## Func_2ad6a: back to normal, invincible for a while, submerged with the swimming graphics.
func recover_submerged() -> void:
	clear_transformation_values()
	wInvincibleCounter = 0x10
	set_state_submerged()
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCycles = 1
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_SWIM_GFX)
	set_wario_oam(OAM_15254)
	wWarioFramesetPtr = FRAMESET_SUBMERGED_RIGHT_2 if wDirection != DIRECTION_LEFT else FRAMESET_SUBMERGED_LEFT_2
	update_wario_animation()


## SetState_FatRecovering: touches bump again.
func set_state_fat_recovering() -> void:
	wWarioState = WST_FAT_RECOVERING
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	_fat_frameset(0x7844, 0x785B)


## UpdateState_FatRecovering: back to normal when the animation ends.
func update_state_fat_recovering() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		recover_from_transformation()


# --- Grabbing and throwing (wario_states_1.asm, wario_states_2.asm) -----------------------

func _grab_box() -> void:
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9


## wGrabState's flags kept, its state set.
func _set_grab(state: int) -> void:
	wGrabState = byte((wGrabState & GRAB_FLAGS_MASK) + state)


## UpdateState_PickingUp: A drops it and jumps (Func_1dd78); the object lifted (its state 2) or the
## animation's end, holding it.
func update_state_picking_up() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		grab_drop_jump()
		return
	if wGrabState == 0:
		set_state_idling()
		return
	if (wGrabState & 0x0F) == GRAB_UNK_02:
		set_state_grab_idling()
		return
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		set_state_grab_idling()


## SetState_GrabIdling: holding it, standing (nothing held: idling).
func set_state_grab_idling() -> void:
	if wGrabState == 0:
		set_state_idling()
		return
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsSmashAttacking = 0
	wIsCrouching = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	_set_grab(GRAB_IDLE)
	wWarioState = WST_GRAB_IDLING
	_grab_box()
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wWarioFramesetPtr = 0x4A23 if wDirection != DIRECTION_LEFT else 0x4A20
	update_wario_animation()


func update_state_grab_idling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_GRAB_IDLING:
		return
	if wGrabState == 0:
		set_state_idling()
		return
	_grab_idle_input()
	if wWarioState != WST_GRAB_IDLING:
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_GRAB_IDLING:
		return
	if b == 0:
		grab_fall()
		return
	update_pos_y()


## Func_1ee88: A jumps holding it; B held charges a throw; Down crouches (CrouchOrSlide); the pad
## walks holding it.
func _grab_idle_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		grab_jump()
		return
	if (wJoypadDown & PAD_B) != 0:
		set_state_throw_charging()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) == 0:
		return
	wWarioState = WST_GRAB_WALKING
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	_grab_box()
	if (wJoypadDown & PAD_RIGHT) != 0:
		wDirection = DIRECTION_RIGHT
		wWarioFramesetPtr = 0x4A0F
	else:
		wDirection = DIRECTION_LEFT
		wWarioFramesetPtr = 0x49FE
	update_wario_animation()


## UpdateState_GrabWalking (SFX_WALK every 37 frames not simulated, its counter kept).
func update_state_grab_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_GRAB_WALKING:
		return
	if wGrabState == 0:
		set_state_walking_reset_walk_vel()
		return
	wSFXLoopCounter = 36 if wSFXLoopCounter == 0 else wSFXLoopCounter - 1
	update_wario_animation()
	_grab_walk_input()
	if wWarioState != WST_GRAB_WALKING:
		return
	if check_centre_collision() == 0:
		grab_fall()
		return
	update_pos_y()


## Func_1eefc: B throws, A jumps, Down crouches (or crouch-slips on slippery ground); the pad walks
## the way he faces (the other way, he stands holding it), slower on a slope he climbs and with a
## heavy object; no direction, standing (or slipping).
func _grab_walk_input() -> void:
	if (wJoypadPressed & PAD_B) != 0:
		set_state_throw_charging()
		return
	if (wJoypadPressed & PAD_A) != 0:
		grab_jump()
		return
	if (wJoypadPressed & PAD_DOWN) != 0:
		if is_on_slippery_ground() == 0:
			crouch_or_slide()
		else:
			set_state_crouch_slipping()
		return
	var climbing: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			set_state_grab_idling()
			return
		if (check_front_collision() & 0x0F) != 0:
			return
		move_wario_right(apply_walk_velocity_right())
		climbing = wWarioSlopeInteraction != 0 and (wWarioSlopeInteraction & RIGHT_SLOPE) != 0
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			set_state_grab_idling()
			return
		if (check_front_collision() & 0x0F) != 0:
			return
		move_wario_left(apply_walk_velocity_left())
		climbing = wWarioSlopeInteraction != 0 and (wWarioSlopeInteraction & RIGHT_SLOPE) == 0
	else:
		if is_on_slippery_ground() != 0:
			set_state_grab_slipping()
		else:
			set_state_grab_idling()
		return
	var heavy: bool = (wGrabState & GRAB_HEAVY) != 0
	if climbing:
		if heavy:
			if wWalkVelIndex >= 0x04:
				wWalkVelIndex = 0
		elif wWalkVelIndex >= 0x08:
			wWalkVelIndex = 0x04
	elif heavy:
		if wWalkVelIndex >= 0x08:
			wWalkVelIndex = 0x04
	elif wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C


## Func_1edd3: off the ground holding it: falling on the high jump's table.
func grab_fall() -> void:
	_set_grab(GRAB_IDLE)
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_HIGH_JUMP
	set_state_grab_airborne()


## Func_1ede9: a jump holding it (SFX_JUMP not simulated), the high one with the High Jump Boots and
## Up.
func grab_jump() -> void:
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	var high: bool = wPowerUpLevel >= HIGH_JUMP_BOOTS and (wJoypadDown & PAD_UP) != 0
	wJumpVelTable = JUMP_VEL_HIGH_JUMP if high else JUMP_VEL_NORMAL
	set_state_grab_airborne()


## SetState_GrabAirborne: standing on an object, its first update at once.
func set_state_grab_airborne() -> void:
	wWarioState = WST_GRAB_AIRBORNE
	_grab_box()
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = 0x5FAB if wDirection != DIRECTION_LEFT else 0x5FA8
	update_wario_animation()
	if wIsOnSteppableObject != 0:
		update_state_grab_airborne()


## UpdateState_GrabAirborne: as UpdateState_Airborne holding it (B throws it), its smash attack
## included; landing, holding it again, or a smash attack's pound or shake.
func update_state_grab_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_GRAB_AIRBORNE:
		return
	if wWaterInteraction != 0:
		dive_from_surface()
		return
	if wGrabState == 0:
		start_fall()
		return
	if wIsInSand != 0:
		set_state_sand_falling()
		return
	if (wJoypadPressed & PAD_B) != 0:
		set_state_throwing_airborne()
		return
	handle_input_airborne()
	if wWarioState != WST_GRAB_AIRBORNE:
		return
	var smash: bool = false
	var plain: bool = false
	if wPowerUpLevel >= LEAD_OVERALLS and wIsSmashAttacking != 0:
		if (wJoypadDown & PAD_DOWN) == 0:
			wIsSmashAttacking = 0
			plain = true
	elif wPowerUpLevel >= LEAD_OVERALLS and wJumpVelIndex >= FALLING_JUMP_VEL_INDEX \
			and (wJoypadDown & PAD_DOWN) != 0:
		wIsSmashAttacking = 1
		smash = true
	if not smash and not plain and wIsTurning != 0:
		if wIsSmashAttacking != 0:
			smash = true
		else:
			plain = true
	if smash:
		wFrameDuration = 0
		wAnimationFrame = 0
		var overalls: bool = wPowerUpLevel >= SUPER_JUMP_SLAM_OVERALLS
		if wDirection != DIRECTION_LEFT:
			wWarioFramesetPtr = 0x6063 if overalls else 0x5FEF
		else:
			wWarioFramesetPtr = 0x605C if overalls else 0x5FEC
	elif plain:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = 0x5FAB if wDirection != DIRECTION_LEFT else 0x5FA8
	update_wario_animation()
	if (wGrabState & GRAB_HEAVY) != 0 and wWalkVelIndex >= 0x08:
		wWalkVelIndex = 0x04
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	var b: int = check_airborne_collision()
	if wWarioState != WST_GRAB_AIRBORNE:
		return
	if b == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWalkVelIndex = 0
	if wIsSmashAttacking == 0:
		set_state_grab_idling()
		return
	wFrameDuration = 0
	wAnimationFrame = 0
	if wPowerUpLevel < SUPER_JUMP_SLAM_OVERALLS:
		wWarioFramesetPtr = 0x6037 if wDirection != DIRECTION_LEFT else 0x6020
	else:
		if wGroundShakeCounter == 0:
			wGroundShakeCounter = 0x20
			wIsWarioGroundShaking = 1
		wWarioFramesetPtr = 0x5FDF if wDirection != DIRECTION_LEFT else 0x5FD2
	update_wario_animation()
	wIsSmashAttacking = 0x81
	wWarioState = WST_GRAB_SMASH_ATTACKING
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	_grab_box()


## UpdateState_GrabSmashAttacking: 27 frames, then holding it again.
func update_state_grab_smash_attacking() -> void:
	if wGrabState == 0:
		set_state_idling()
		return
	update_wario_animation()
	wWarioStateCounter += 1
	if wWarioStateCounter < 0x1B:
		return
	wIsSmashAttacking = 0
	set_state_grab_idling()


## SetState_ThrowCharging (SFX_02C not simulated): the throw graphics.
func set_state_throw_charging() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_THROW_CHARGING
	_set_grab(GRAB_CHARGE_THROW)
	load_wario_gfx(WARIO_THROW_GFX)
	set_wario_oam(OAM_1606A)
	wWarioFramesetPtr = 0x642F if wDirection != DIRECTION_LEFT else 0x642C
	update_wario_animation()


## UpdateState_ThrowCharging: B let go throws (Func_1de3f); A drops it and jumps; Down crouches; 30
## frames held (60 for a heavy object), fully charged.
func update_state_throw_charging() -> void:
	if wGrabState == 0:
		set_state_idling()
		return
	if (wJoypadDown & PAD_B) == 0:
		_throw()
		return
	if (wJoypadDown & PAD_A) != 0:
		grab_drop_jump()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		crouch_or_slide()
		return
	var frames: int = THROW_CHARGE_FRAMES_HEAVY if (wGrabState & GRAB_HEAVY) != 0 else THROW_CHARGE_FRAMES_LIGHT
	wWarioStateCounter += 1
	if wWarioStateCounter < frames:
		return
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_THROW_FULLY_CHARGED
	_set_grab(GRAB_THROW_FULLY_CHARGED)
	wWarioFramesetPtr = 0x6435 if wDirection != DIRECTION_LEFT else 0x6432
	update_wario_animation()


## Func_1dd78: the object let go, a jump.
func grab_drop_jump() -> void:
	wGrabState = 0
	start_jump_from_input()


## UpdateState_ThrowFullyCharged (SFX_FULLY_CHARGED_THROW every 31 frames not simulated, its counter
## kept): its animation once, then holding the charge; B let go throws it fully charged.
func update_state_throw_fully_charged() -> void:
	wSFXLoopCounter = 30 if wSFXLoopCounter == 0 else wSFXLoopCounter - 1
	if wGrabState == 0:
		set_state_idling()
		return
	if (wGrabState & GRAB_STATE_MASK) != GRAB_HOLD_FULL_CHARGE and wWarioStateCounter == 0 \
			and wWarioAnimationEnded != 0:
		_set_grab(GRAB_HOLD_FULL_CHARGE)
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioStateCounter = 1
		wWarioFramesetPtr = 0x6441 if wDirection != DIRECTION_LEFT else 0x6438
	update_wario_animation()
	if (wJoypadDown & PAD_B) != 0:
		if (wJoypadDown & PAD_A) != 0:
			grab_drop_jump()
		elif (wJoypadDown & PAD_DOWN) != 0:
			crouch_or_slide()
		return
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x6423 if wDirection != DIRECTION_LEFT else 0x6403
	update_wario_animation()
	_set_grab(GRAB_THROW | GRAB_FULL_CHARGE)
	set_state_throwing()


## Func_1de3f: the throw.
func _throw() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x641E if wDirection != DIRECTION_LEFT else 0x63FE
	update_wario_animation()
	_set_grab(GRAB_THROW)
	set_state_throwing()


func set_state_throwing() -> void:
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_THROWING


## UpdateState_Throwing: then idling, the object gone.
func update_state_throwing() -> void:
	if wGrabState == 0:
		set_state_idling()
		return
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		wGrabState = 0
		set_state_idling()


## SetState_ThrowingAirborne: a throw in the air (he hangs until it ends, then falls).
func set_state_throwing_airborne() -> void:
	wWarioState = WST_THROWING_AIRBORNE
	wGrabState = (wGrabState & GRAB_FLAGS_MASK) | GRAB_THROW
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioFramesetPtr = 0x5FB3 if wDirection != DIRECTION_LEFT else 0x5FAE
	update_wario_animation()


func update_state_throwing_airborne() -> void:
	if wGrabState == 0:
		start_fall()
		return
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		wGrabState = 0
		start_fall()


## SetState_GrabSlipping: slipping holding it.
func set_state_grab_slipping() -> void:
	wWarioState = WST_GRAB_SLIPPING
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wAttackCounter = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x4A23 if wDirection != DIRECTION_LEFT else 0x4A20
	update_wario_animation()


## UpdateState_GrabSlipping: as slipping (without its height following the ground), A jumps
## holding it, the end stands holding it.
func update_state_grab_slipping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wGrabState == 0:
		set_state_idling()
		return
	if (wJoypadPressed & PAD_A) != 0:
		grab_jump()
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_GRAB_SLIPPING:
		return
	if b == 0:
		grab_fall()
		return
	b = check_front_collision()
	if wWarioState != WST_GRAB_SLIPPING:
		return
	if b != 0 or is_on_slippery_ground() == 0:
		set_state_grab_idling()
		return
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	var step: int
	if wWarioStateCounter < 0x08:
		step = 2
	elif wWarioStateCounter < 0x0F:
		step = 1
	elif wWarioStateCounter < 0x15:
		if (wGlobalCounter & 1) == 0:
			return
		step = 1
	elif wWarioStateCounter == 0x15:
		set_state_grab_idling()
		return
	else:
		return
	if wDirection == DIRECTION_LEFT:
		move_wario_left(step)
	else:
		move_wario_right(step)


# --- Slipping (wario_states_2.asm) --------------------------------------------------------

## SetState_Slipping: stopping on slippery ground, standing; wWarioStateCycles keeps the direction
## he slides (0 left, 1 right; 2 and 3 once he turns to walk left or right, 4 and 5 walking).
func set_state_slipping() -> void:
	wWarioState = WST_SLIPPING
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wAttackCounter = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14000)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCycles = wDirection
	wWarioFramesetPtr = FRAMESET_IDLE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_IDLE_LEFT
	update_wario_animation()


## UpdateState_Slipping: the pad against the slide turns him (then walking frames, still sliding);
## A jumps, Down crouches into a crouch slip; nothing under him is a fall; otherwise he slides on,
## 2 px a frame for 7 frames, 1 px for 7, 1 px every other frame for 6, and stops (also at a wall
## or off slippery ground), facing the way he last turned.
func update_state_slipping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	var cycles: int = wWarioStateCycles
	if cycles < 2:
		var pad: int = wJoypadDown & (PAD_RIGHT | PAD_LEFT)
		# rlca x3 and $01: Left's bit; it must match the slide's direction (Left against a right slide)
		if pad != 0 and (1 if (pad & PAD_LEFT) != 0 else 0) == cycles:
			wWarioStateCycles = (cycles ^ 1) + 2
			load_wario_gfx(WARIO_IDLE_GFX)
			set_wario_oam(OAM_14A82)
			wWarioFramesetPtr = FRAMESET_TURN_RIGHT if (wWarioStateCycles & 1) != 0 else FRAMESET_TURN_LEFT
			wFrameDuration = 0
			wAnimationFrame = 0
	elif cycles < 4 and wWarioAnimationEnded != 0:
		wWarioStateCycles = cycles + 2
		load_wario_gfx(WARIO_WALK_GFX)
		set_wario_oam(OAM_1426C)
		wWarioFramesetPtr = FRAMESET_WALK_RIGHT if (wWarioStateCycles & 1) != 0 else FRAMESET_WALK_LEFT
		wFrameDuration = 0
		wAnimationFrame = 0
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		start_jump_from_input()
		return
	if (wJoypadDown & PAD_DOWN) != 0:
		_crouch_slipping()
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_SLIPPING:
		return
	if b == 0:
		start_fall()
		return
	update_pos_y()
	b = check_front_collision()
	if wWarioState != WST_SLIPPING:
		return
	if b != 0 or is_on_slippery_ground() == 0:
		_slipping_stop()
		return
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	var step: int
	if wWarioStateCounter < 0x08:
		step = 2
	elif wWarioStateCounter < 0x0F:
		step = 1
	elif wWarioStateCounter < 0x15:
		if (wGlobalCounter & 1) == 0:
			return
		step = 1
	elif wWarioStateCounter == 0x15:
		_slipping_stop()
		return
	else:
		return
	if wDirection == DIRECTION_LEFT:
		move_wario_left(step)
	else:
		move_wario_right(step)


func _slipping_stop() -> void:
	wDirection = wWarioStateCycles & 1
	set_state_idling()


## SetState_CrouchSlipping: crouching on slippery ground, sliding the way he faced.
func set_state_crouch_slipping() -> void:
	wWarioStateCounter = 0
	wWarioStateCycles = wDirection
	_crouch_slipping()


## Func_19e89 (also from slipping with Down, keeping the slide's count).
func _crouch_slipping() -> void:
	wWarioState = WST_CROUCH_SLIPPING
	wSFXLoopCounter = 0
	wAttackCounter = 0
	wGrabState = 0
	wIsCrouching = 1
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = FRAMESET_CROUCH_RIGHT if wWarioStateCycles == 1 else FRAMESET_CROUCH_LEFT
	update_wario_animation()


## UpdateState_CrouchSlipping: A crouch-jumps; nothing under him, a crouch fall; otherwise he slides
## on (2 px for 5 frames, 1 px for 4, 1 px every other frame for 4) and then crouches or slides
## (CrouchOrSlide), as at a wall or off slippery ground.
func update_state_crouch_slipping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if (wJoypadPressed & PAD_A) != 0:
		start_crouch_jump()
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_CROUCH_SLIPPING:
		return
	if b == 0:
		start_crouch_fall()
		return
	update_pos_y()
	b = check_front_collision()
	if wWarioState != WST_CROUCH_SLIPPING:
		return
	if b != 0 or is_on_slippery_ground() == 0:
		_crouch_slipping_stop()
		return
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	var step: int
	if wWarioStateCounter < 0x06:
		step = 2
	elif wWarioStateCounter < 0x0A:
		step = 1
	elif wWarioStateCounter < 0x0E:
		if (wGlobalCounter & 1) == 0:
			return
		step = 1
	else:
		_crouch_slipping_stop()
		return
	if wDirection == DIRECTION_LEFT:
		move_wario_left(step)
	else:
		move_wario_right(step)


func _crouch_slipping_stop() -> void:
	wDirection = wWarioStateCycles & 1
	crouch_or_slide()


# --- Flat Wario (wario_states_3.asm) ------------------------------------------------------

## The box every Flat Wario state sets.
func _flat_box() -> void:
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-8)
	wCollisionBoxLeft = byte(-11)
	wCollisionBoxRight = 11


func _flat_frameset(pointer: int) -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = pointer
	update_wario_animation()


## SetState_FlatAirborne: unless in a lasting transformation, flattened by the object, centred on
## its OBJ_X_POS less 8 (`object_x`; Count Richtertoffen's, `richtertoffen`, without the 8 and
## then not squished), falling 2 px a frame (Owl Wario lets go of the owl first; SFX_01B and the
## music not simulated).
func set_state_flat_airborne(object_x: int, richtertoffen: bool) -> void:
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		return
	if wTransformation == TRANSFORMATION_OWL_WARIO:
		release_owl()
	wWarioStateCounter = 0 if richtertoffen else 1
	wWarioXPos = word(object_x - (0 if richtertoffen else 8))
	wTransformation = TRANSFORMATION_FLAT_WARIO
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wAutoMoveState = 1
	wJumpVelTable = 1
	wWarioState = WST_GETTING_FLAT_AIRBORNE
	_flat_box()
	load_wario_gfx(WARIO_SLIDE_GFX)
	set_wario_oam(OAM_16E9D)
	_flat_frameset(0x71BD)


## UpdateState_GettingFlatAirborne: down 2 px a frame; on the ground, getting flat (intangible).
func update_state_getting_flat_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		set_state_flat_sinking()
		return
	move_wario_down(2)
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	wWarioState = WST_GETTING_FLAT
	wWalkVelIndex = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wAutoMoveState = 0
	wIsIntangible = 1
	_flat_box()
	_flat_frameset(0x715F)


## UpdateState_GettingFlat: when the animation ends, squished (under an object) or idling.
func update_state_getting_flat() -> void:
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	wIsIntangible = 0
	if wWarioStateCounter != 0:
		set_state_flat_squished()
		return
	set_state_flat_idling()


func set_state_flat_idling() -> void:
	wWarioState = WST_FLAT_IDLING
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	_flat_box()
	_flat_frameset(0x718B)


## UpdateState_FlatIdling: Func_2b10a (A jumps, the pad walks), and then, whatever it started,
## nothing under him is a fall.
func update_state_flat_idling() -> void:
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		set_state_flat_jumping()
	elif (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_flat_walking()
	if check_centre_collision() == 0:
		set_state_flat_falling()


## SetState_FlatWalking: facing the way the pad points (SFX_FLAT_WALK every 11 frames not
## simulated, its counter kept).
func set_state_flat_walking() -> void:
	wWarioState = WST_FLAT_WALKING
	wSFXLoopCounter = 0
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	_flat_frameset(0x7175)
	wDirection = DIRECTION_RIGHT if (wJoypadDown & PAD_RIGHT) != 0 else DIRECTION_LEFT


## UpdateState_FlatWalking: Func_2b11b, and then, whatever it started, nothing under him is a
## fall; otherwise his height follows the ground (update_pos_y).
func update_state_flat_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	wSFXLoopCounter = 10 if wSFXLoopCounter == 0 else wSFXLoopCounter - 1
	update_wario_animation()
	_flat_walk_input()
	if check_centre_collision() == 0:
		set_state_flat_falling()
		return
	update_pos_y()


## Func_2b11b: A jumps; the pad walks (unless a wall is in front), the walk index kept below 4;
## no direction, idling.
func _flat_walk_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		set_state_flat_jumping()
		return
	if (wJoypadDown & PAD_LEFT) != 0:
		wDirection = DIRECTION_LEFT
		if check_front_collision() != 0:
			return
		move_wario_left(apply_walk_velocity_left())
	elif (wJoypadDown & PAD_RIGHT) != 0:
		wDirection = DIRECTION_RIGHT
		if check_front_collision() != 0:
			return
		move_wario_right(apply_walk_velocity_right())
	else:
		set_state_flat_idling()
		return
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0


## SetState_FlatJumping: the knock-back jump, or the normal one with Up (SFX_01D not simulated);
## standing on an object, the jump's first update at once.
func set_state_flat_jumping() -> void:
	wWarioState = WST_FLAT_JUMPING
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = JUMP_VEL_NORMAL if (wJoypadDown & PAD_UP) != 0 else JUMP_VEL_KNOCK_BACK
	_flat_frameset(0x7190)
	if wIsOnSteppableObject != 0:
		update_state_flat_jumping()


## UpdateState_FlatJumping: the jump, steered by the pad (Func_2b17a, WalkRight/WalkLeft); falling
## past its peak or under a ceiling.
func update_state_flat_jumping() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	apply_jump_velocity()
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	cap_airborne_walk_velocity()
	if wJumpVelIndex >= FALLING_JUMP_VEL_INDEX:
		set_state_flat_falling()
		return
	if check_up_collision() == 0:
		return
	set_state_flat_falling()


func set_state_flat_falling() -> void:
	wWarioState = WST_FLAT_FALLING
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioSlopeInteraction = 0
	wJumpVelIndex = 1
	wJumpVelTable = 1
	_flat_frameset(0x7186 if wDirection != DIRECTION_LEFT else 0x71B8)


## UpdateState_FlatFalling: floating down like a sheet, swinging across (Data_2b68c) and down
## (Data_2b664) by wWalkVelIndex. Its first animation once played, the jumping frameset holds. A
## wall turns him back 3 px; at the swing's end (index $28) he turns unless the pad holds the way
## he faces. On the ground, idling (SFX_020 not simulated).
func update_state_flat_falling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		set_state_flat_sinking()
		return
	if wWarioAnimationEnded == 0:
		update_wario_animation()
		if wWarioAnimationEnded != 0:
			_flat_frameset(0x7190)
			wWarioAnimationEnded = 1
	var e: int = wWalkVelIndex
	wWalkVelIndex = byte(wWalkVelIndex + 1)
	if wDirection == DIRECTION_LEFT:
		move_wario_left(_flat_fall_step("across", e))
	else:
		move_wario_right(_flat_fall_step("across", e))
	if wWalkVelIndex < 0x28:
		if check_front_collision() != 0:
			wDirection ^= 1
			if wDirection == DIRECTION_LEFT:
				move_wario_left(3)
			else:
				move_wario_right(3)
			wWalkVelIndex = 0
			return
		move_wario_down(_flat_fall_step("down", e))
		if check_airborne_collision() == 0:
			trigger_downwards_floor_transition()
			return
		trigger_floor_transition()
		set_state_flat_idling()
		return
	var held: int = PAD_LEFT if wDirection == DIRECTION_LEFT else PAD_RIGHT
	if (wJoypadDown & held) == 0:
		wWarioAnimationEnded = 0
		wDirection ^= 1
		_flat_frameset(0x7186 if wDirection != DIRECTION_LEFT else 0x71B8)
	wWalkVelIndex = 0


func _flat_fall_step(table: String, index: int) -> int:
	var steps: PackedInt32Array = tables.flat_fall_steps.get(table, PackedInt32Array())
	if index >= steps.size():
		note_unported("flat fall table %s" % table)
		return 0
	return steps[index]


## SetState_FlatStretching (ObjInteraction_Omodonmeka): stretched back by the object holding him.
func set_state_flat_stretching() -> void:
	wAutoMoveState = 1
	wWarioState = WST_FLAT_STRETCHING
	_flat_box()
	wPickedUpWiggleCounter = NUM_WIGGLES_TO_ESCAPE
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	_flat_frameset(0x7193)


## UpdateState_FlatStretching: back to normal when the animation ends.
func update_state_flat_stretching() -> void:
	update_wario_animation()
	if wWarioAnimationEnded == 0:
		return
	wAutoMoveState = 0
	recover_from_transformation()


## SetState_FlatSinking: in water, sinking (intangible).
func set_state_flat_sinking() -> void:
	wWarioState = WST_FLAT_SINKING
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsIntangible = 1
	_flat_box()
	_flat_frameset(0x719A)


## Bubbles 8 px above him, 4 px behind his position (Func_2899a, Func_289c5).
func _flat_bubbles() -> void:
	hXPos = word(wWarioXPos - 4)
	hYPos = word(wWarioYPos - 8)
	create_particle(PARTICLE_BUBBLES)


## UpdateState_FlatSinking: bubbles every 16 frames, down a pixel every other frame; on the bottom,
## bubbles and stretching underwater (Func_289c5).
func update_state_flat_sinking() -> void:
	update_wario_animation()
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if (wGlobalCounter & 0x0F) == 0:
		_flat_bubbles()
	if (wGlobalCounter & 1) != 0:
		return
	move_wario_down(1)
	if check_centre_collision() == 0:
		return
	_flat_bubbles()
	wWarioState = WST_FLAT_STRETCHING_UNDERWATER
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	_flat_box()
	_flat_frameset(0x71A3)


## UpdateState_FlatStretchingUnderwater: back to normal, submerged (Func_2ad6a).
func update_state_flat_stretching_underwater() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		recover_submerged()


## SetState_FlatSquished: under the object that flattened him, waiting.
func set_state_flat_squished() -> void:
	wWarioState = WST_FLAT_SQUISHED
	wWarioStateCounter = 0


## SetState_FlatSquishedLifting (Func_2168b, Wario under a lifted object): intangible, rising.
func set_state_flat_squished_lifting() -> void:
	wIsIntangible = 1
	wWarioState = WST_FLAT_SQUISHED_LIFTING
	wWarioStateCounter = 0
	_flat_frameset(0x716C)


## UpdateState_FlatSquishedLifting: up a pixel a frame for 50 frames, then falling.
func update_state_flat_squished_lifting() -> void:
	update_wario_animation()
	move_wario_up(1)
	wWarioStateCounter += 1
	if wWarioStateCounter < 0x32:
		return
	wIsIntangible = 0
	set_state_flat_falling()


# --- Zombie Wario (wario_states_3.asm) ----------------------------------------------------

## Zombie Wario's framesets are in "Wario OAM 2", by direction.
func _zombie_frameset(left: int, right: int) -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = right if wDirection != DIRECTION_LEFT else left
	update_wario_animation_2()


## SetState_ZombieIdling: Wario's box, touches that make objects vanish, the zombie graphics and
## palette (the music not simulated).
func set_state_zombie_idling() -> void:
	wWarioState = WST_ZOMBIE_IDLING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wTouchState = TOUCH_VANISH
	wStingTouchState = TOUCH_VANISH
	wca94 = 2
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wInvisibleFrame = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	set_wario_pal(WARIO_ZOMBIE_PAL)
	load_wario_gfx(WARIO_ZOMBIE_GFX)
	set_wario_oam(OAM_1FC48B)
	_zombie_frameset(0x48B6, 0x48B9)


## UpdateState_ZombieIdling: a light source may end it (the probes); off the ground, falling;
## otherwise his height follows the ground and Func_2b34e reads the pad.
func update_state_zombie_idling() -> void:
	probe_presence_top()
	if wWarioState != WST_ZOMBIE_IDLING:
		return
	var b: int = check_centre_collision()
	if wWarioState != WST_ZOMBIE_IDLING:
		return
	if b == 0:
		_zombie_fall()
		return
	update_pos_y()
	update_wario_animation_2()
	_zombie_idle_input()


## Func_2b34e: A (held) jumps, the pad walks; off the ground, falling; idle for 512 frames
## (wWarioStateCounter and wWarioStateCycles as one 16-bit count), writhing.
func _zombie_idle_input() -> void:
	if (wJoypadDown & PAD_A) != 0:
		_zombie_jump()
		return
	if (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_zombie_walking()
		return
	if check_centre_collision() == 0:
		_zombie_fall()
		return
	wWarioStateCounter += 1
	if wWarioStateCounter > 0xFF:
		wWarioStateCounter = 0
		wWarioStateCycles = byte(wWarioStateCycles + 1)
	if wWarioStateCycles >= 2:
		set_state_zombie_writhing()


func set_state_zombie_walking() -> void:
	wSFXLoopCounter = 0
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_ZOMBIE_WALKING
	_zombie_frameset(0x4870, 0x4879)


## UpdateState_ZombieWalking (SFX_ZOMBIE_WALK every 37 frames not simulated, its counter kept).
func update_state_zombie_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	wSFXLoopCounter = 36 if wSFXLoopCounter == 0 else wSFXLoopCounter - 1
	update_wario_animation_2()
	_zombie_walk_input()
	if wWarioState != WST_ZOMBIE_WALKING:
		return
	if check_centre_collision() == 0:
		_zombie_fall()
		return
	update_pos_y()


## Func_2b381: A jumps; the pad walks the way he faces (WalkIfPossible, the walk index kept below
## 4) or turns him; no direction, idling.
func _zombie_walk_input() -> void:
	if (wJoypadDown & PAD_A) != 0:
		_zombie_jump()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			wDirection = DIRECTION_RIGHT
			set_state_zombie_turning()
			return
		walk_if_possible_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			wDirection = DIRECTION_LEFT
			set_state_zombie_turning()
			return
		walk_if_possible_left()
	else:
		set_state_zombie_idling()
		return
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0


func set_state_zombie_turning() -> void:
	wWarioState = WST_ZOMBIE_TURNING
	_zombie_frameset(0x489D, 0x4894)


func update_state_zombie_turning() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_zombie_walking()


## Func_29bb9: falling (the falling frameset at once).
func _zombie_fall() -> void:
	wWarioFramesetPtr = 0x48B3 if wDirection != DIRECTION_LEFT else 0x48B0
	wWarioStateCounter = 1
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_zombie_airborne()


## Func_29be1: jumping (the falling frameset once the rising one has played).
func _zombie_jump() -> void:
	wWarioFramesetPtr = 0x48AB if wDirection != DIRECTION_LEFT else 0x48A6
	wWarioStateCounter = 0
	wJumpVelIndex = 0
	set_state_zombie_airborne()


## SetState_ZombieAirborne: the knock-back jump table, with the frameset its caller chose.
func set_state_zombie_airborne() -> void:
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wWarioStateCycles = 0
	wWarioState = WST_ZOMBIE_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	update_wario_animation_2()


## UpdateState_ZombieAirborne: water ends the transformation; the jump, steered (Func_2b3dd); a
## ceiling makes it a fall; on the ground, landing.
func update_state_zombie_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioState != WST_ZOMBIE_AIRBORNE:
		return
	_zombie_air_move()
	if wWarioState != WST_ZOMBIE_AIRBORNE:
		return
	if wWarioStateCounter == 0 and wWarioAnimationEnded != 0:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioStateCounter = 1
		wWarioFramesetPtr = 0x48B3 if wDirection != DIRECTION_LEFT else 0x48B0
	update_wario_animation_2()
	if wWarioState != WST_ZOMBIE_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_ZOMBIE_AIRBORNE:
			return
		_zombie_fall()
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_ZOMBIE_AIRBORNE:
		return
	set_state_zombie_landing()


## Func_2b3dd: the jump's velocity; after wWarioStateCycles frames the pad steers (Func_2b17a),
## the walk index kept below 4.
func _zombie_air_move() -> void:
	apply_jump_velocity()
	if wWarioStateCycles != 0:
		wWarioStateCycles -= 1
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	if wWalkVelIndex >= 4:
		wWalkVelIndex = 0


## SetState_ZombieLanding: touches bump while landing (SFX_02A not simulated); with both bottom
## corners on one-way floors (or free; Func_19a77's wc1ca), about to slip through.
func set_state_zombie_landing() -> void:
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioState = WST_ZOMBIE_LANDING
	wWarioStateCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	_check_corners_on_floors()
	if wc1ca != 0:
		wWarioStateCounter = 1
		wWarioFramesetPtr = 0x48D5 if wDirection != DIRECTION_LEFT else 0x48BC
	else:
		wWarioFramesetPtr = 0x4953 if wDirection != DIRECTION_LEFT else 0x4948
	update_wario_animation_2()


## Func_19a77: wc1ca set when Wario's bottom corners (3 px in from his box) are both on one-way
## floors (BlockFunc_Floor sets it) or both free.
func _check_corners_on_floors() -> void:
	wc1ca = 0
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 3))
	hYPos = wWarioYPos
	if probe_presence() != 0 and wc1ca == 0:
		return
	wc1ca = 0
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 3))
	hYPos = wWarioYPos
	if probe_presence() != 0:
		return
	wc1ca = 1


## UpdateState_ZombieLanding: then idling, or (wWarioStateCounter 1) slipping through the floor.
func update_state_zombie_landing() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	if wWarioStateCounter != 1:
		set_state_zombie_idling()
		return
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_NORMAL
	wWarioStateCycles = 6
	wWarioState = WST_ZOMBIE_SLIPPING_THROUGH_FLOOR
	_zombie_frameset(0x4928, 0x492B)


## UpdateState_ZombieSlippingThroughFloor: falling through the floors (BlockFunc_Floor is free in
## this state); landed, its own landing frames (wWarioStateCounter 2).
func update_state_zombie_slipping_through_floor() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioState != WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
		return
	_zombie_air_move()
	update_wario_animation_2()
	if wWarioState != WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
		return
	if check_airborne_collision() == 0:
		if wWarioState != WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
			return
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
		return
	set_state_zombie_landing()
	wWarioFramesetPtr = 0x490B if wDirection != DIRECTION_LEFT else 0x48EE
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioAnimationEnded = 0
	wWarioStateCounter = 2
	update_wario_animation_2()


## SetState_ZombieRecovering (BlockFunc_LightSource): fading back.
func set_state_zombie_recovering() -> void:
	wWarioState = WST_ZOMBIE_RECOVERING
	wWarioStateCounter = 0
	wWarioStateCycles = 0


## UpdateState_ZombieRecovering: every fourth frame the next of the eight zombie palettes, up to
## the seventh, then back three; at the eleventh step, back to normal.
func update_state_zombie_recovering() -> void:
	if (wGlobalCounter & 0b11) != 0:
		return
	wWarioStateCounter += 1
	var index: int
	if wWarioStateCounter < 8:
		wWarioStateCycles = wWarioStateCounter
		index = wWarioStateCounter
	elif wWarioStateCounter == 0x0B:
		recover_from_transformation()
		return
	else:
		wWarioStateCycles -= 1
		index = wWarioStateCycles
	set_wario_pal(WARIO_ZOMBIE_PAL + index * 0x10)


## SetState_ZombieKnockBack (VanishObjectAndKnockBackIfZombie): not while landing or slipping.
func set_state_zombie_knock_back() -> void:
	if wWarioState == WST_ZOMBIE_KNOCK_BACK or wWarioState == WST_ZOMBIE_SLIPPING_THROUGH_FLOOR \
			or wWarioState == WST_ZOMBIE_LANDING:
		return
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioState = WST_ZOMBIE_KNOCK_BACK
	_zombie_frameset(0x492E, 0x493B)


func update_state_zombie_knock_back() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_zombie_idling()


func set_state_zombie_writhing() -> void:
	wWarioState = WST_ZOMBIE_WRITHING
	_zombie_frameset(0x4882, 0x488B)


## UpdateState_ZombieWrithing: any button held, idling again.
func update_state_zombie_writhing() -> void:
	update_wario_animation_2()
	if wJoypadDown != 0:
		set_state_zombie_idling()


# --- Crazy Wario (wario_states_3.asm) -----------------------------------------------------

## SetState_CrazySpinning (SFX_042 not simulated): spinning the way the object faced, landing if
## in the air (the music not simulated).
func set_state_crazy_spinning() -> void:
	wWarioState = WST_CRAZY_SPINNING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	if wJumpVelTable != 0:
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wDirection = wObjDirection
	wWarioFramesetPtr = 0x4CE1 if wDirection != DIRECTION_LEFT else 0x4CCC
	update_wario_animation()


## UpdateState_CrazySpinning: water ends it; falling to the ground; after 128 frames, dizzy
## (SFX_043 not simulated).
func update_state_crazy_spinning() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wJumpVelTable != 0:
		apply_jump_velocity()
		if check_airborne_collision() == 0:
			trigger_downwards_floor_transition()
			return
		trigger_floor_transition()
		wJumpVelTable = 0
		wJumpVelIndex = 0
	update_wario_animation()
	wWarioStateCounter += 1
	if wWarioStateCounter < 0x80:
		return
	wWarioStateCounter = 0
	wWarioState = WST_CRAZY_DIZZY
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_DIZZY_GFX)
	set_wario_oam(OAM_17BBC)
	wWarioFramesetPtr = 0x7CE2
	update_wario_animation()


## UpdateState_CrazyDizzy: then crazy.
func update_state_crazy_dizzy() -> void:
	update_wario_animation()
	if wWarioAnimationEnded != 0:
		set_state_crazy()


## SetState_Crazy (SFX_043 not simulated): touches bump, stings find him vulnerable; his own
## graphics, in "Wario OAM 2".
func set_state_crazy() -> void:
	wWarioState = WST_CRAZY
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_VULNERABLE
	wca94 = 1
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_CRAZY_GFX)
	set_wario_oam(OAM_1FCCD5)
	wWarioFramesetPtr = 0x4F6E if wDirection != DIRECTION_LEFT else 0x4F9F
	update_wario_animation_2()


## UpdateState_Crazy: Func_2b3f9; nothing under him, a fall.
func update_state_crazy() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	update_wario_animation_2()
	_crazy_input()
	if wWarioState != WST_CRAZY:
		return
	if check_centre_collision() == 0:
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		set_state_crazy_airborne()


## Func_2b3f9: A jumps; he staggers on by himself (Func_2b42b); at the animation's end he turns
## unless the pad holds the way he faces.
func _crazy_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		wJumpVelIndex = 0
		set_state_crazy_airborne()
		return
	_crazy_stagger()
	if wWarioState != WST_CRAZY:
		return
	if wWarioAnimationEnded == 0:
		return
	var held: int = PAD_LEFT if wDirection == DIRECTION_LEFT else PAD_RIGHT
	if (wJoypadDown & held) == 0:
		set_state_crazy_turning()
		return
	wWalkVelIndex = 0


## Func_2b42b: the stagger, by wWalkVelIndex: 2 px for 5 frames, dust; 2 px again from 9 to 17,
## dust; from 21, 2 px to 23 and 1 px to 33, dust; from 37 to 43 a pixel every other frame. A wall at
## his bottom corner (Func_197b1, Func_19741) turns him.
func _crazy_stagger() -> void:
	wWalkVelIndex = byte(wWalkVelIndex + 1)
	var a: int = wWalkVelIndex
	var step: int
	if a < 0x06:
		step = 2
	elif a == 0x06:
		_crazy_dust()
		return
	elif a < 0x09:
		return
	elif a < 0x12:
		step = 2
	elif a == 0x12:
		_crazy_dust()
		return
	elif a < 0x15:
		return
	elif a < 0x18:
		step = 2
	elif a < 0x22:
		step = 1
	elif a == 0x22:
		_crazy_dust()
		return
	elif a < 0x25:
		return
	elif a < 0x2C:
		if (wGlobalCounter & 1) == 0:
			return
		step = 1
	else:
		return
	if wDirection == DIRECTION_LEFT:
		if check_bottom_left_breaking() != 0:
			set_state_crazy_turning()
			return
		move_wario_left(step)
	else:
		if check_bottom_right_breaking() != 0:
			set_state_crazy_turning()
			return
		move_wario_right(step)


## Func_2b4d0: dust at his feet.
func _crazy_dust() -> void:
	get_pos()
	create_particle(PARTICLE_DUST)


## SetState_CrazyTurning: he turns round.
func set_state_crazy_turning() -> void:
	wWarioState = WST_CRAZY_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wDirection ^= 1
	wWarioFramesetPtr = 0x4FD7 if wDirection != DIRECTION_LEFT else 0x4FD0
	update_wario_animation_2()


## UpdateState_CrazyTurning: A jumps at once; then crazy.
func update_state_crazy_turning() -> void:
	update_wario_animation_2()
	if (wJoypadPressed & PAD_A) != 0:
		wJumpVelIndex = 0
		set_state_crazy_airborne()
		return
	if wWarioAnimationEnded != 0:
		set_state_crazy()


## SetState_CrazyAirborne: the normal jump's table, from the index its caller set.
func set_state_crazy_airborne() -> void:
	wWarioState = WST_CRAZY_AIRBORNE
	wJumpVelTable = JUMP_VEL_NORMAL
	wWalkVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x4F6E if wDirection != DIRECTION_LEFT else 0x4F9F
	update_wario_animation_2()


## UpdateState_CrazyAirborne: water ends it; the jump, carried on the way he faces (HandleWalk, the
## walk index kept below $10); a ceiling makes it a fall; on the ground, crazy.
func update_state_crazy_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation_2()
	apply_jump_velocity()
	_walk_ahead()
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	set_state_crazy()


# --- Bouncy Wario (wario_states_3.asm) ----------------------------------------------------

func _bouncy_frameset(pointer: int) -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = pointer
	update_wario_animation_2()


## HandleWalk: a step the way he faces.
func _walk_ahead() -> void:
	if wDirection == DIRECTION_LEFT:
		walk_left()
	else:
		walk_right()


## The walk index of Bouncy Wario's states, kept below 8 (back to 4).
func _cap_bouncy_walk() -> void:
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4


## SetState_BouncyStart: falling on the normal jump's table, a taller box, the bouncy graphics and
## palette (the music not simulated); with a wall at his bottom left (Func_197b1), 2 px right.
func set_state_bouncy_start() -> void:
	wWarioState = WST_BOUNCY_START
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_NORMAL
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-29)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wInvisibleFrame = 0
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	set_wario_pal(WARIO_BOUNCY_PAL)
	load_wario_gfx(WARIO_BOUNCY_GFX)
	set_wario_oam(OAM_1FC95E)
	_bouncy_frameset(0x4C6C)
	if check_bottom_left_breaking() != 0:
		move_wario_right(2)


## UpdateState_BouncyStart: falling (HandleWalk carries him on); on the ground, the first bounce.
func update_state_bouncy_start() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	apply_jump_velocity()
	_walk_ahead()
	_cap_bouncy_walk()
	if wWarioState != WST_BOUNCY_START:
		return
	if check_airborne_collision() == 0:
		if wWarioState != WST_BOUNCY_START:
			return
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_BOUNCY_START:
		return
	set_state_bouncy_floor()


func set_state_bouncy_floor() -> void:
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wWarioStateCounter = 0
	wWalkVelIndex = 0
	wWarioState = WST_BOUNCY_FLOOR
	_bouncy_frameset(0x4C5F)


## UpdateState_BouncyFloor: the time runs (out: the last bounce, Func_2a2e7); the palette flickers
## near the end; after the squash, bouncing again (Func_2a0b2).
func update_state_bouncy_floor() -> void:
	decrement_transformation_duration()
	if wTransformationDuration == 0:
		_bouncy_last_bounce_start()
		return
	_bouncy_flicker()
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	bouncy_bounce()


## Func_2a0b2 (also from StepOnObject): a bounce, high with A held.
func bouncy_bounce() -> void:
	wJumpVelTable = JUMP_VEL_BOUNCY_HIGH_JUMP if (wJoypadDown & PAD_A) != 0 else JUMP_VEL_BOUNCY_JUMP
	wJumpVelIndex = 0
	set_state_bouncy_airborne()


## SetState_BouncyAirborne (SFX_02B not simulated).
func set_state_bouncy_airborne() -> void:
	wWarioState = WST_BOUNCY_AIRBORNE
	_bouncy_frameset(0x4C6C)


## UpdateState_BouncyAirborne: its animation once (a high bounce then leaves a particle at him);
## the time runs (out: upside down); the bounce, steered by the pad; a ceiling stops it, and the
## ground bounces him again.
func update_state_bouncy_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioAnimationEnded == 0:
		update_wario_animation_2()
		if wJumpVelTable == JUMP_VEL_BOUNCY_HIGH_JUMP and wWarioAnimationEnded != 0:
			get_pos()
			create_particle(PARTICLE_BOUNCY_JUMP)
	decrement_transformation_duration()
	if wTransformationDuration == 0:
		set_state_bouncy_upside_down()
		return
	_bouncy_flicker()
	apply_jump_velocity()
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	_cap_bouncy_walk()
	if wWarioState != WST_BOUNCY_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_BOUNCY_AIRBORNE:
			return
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		wWarioState = WST_BOUNCY_CEILING
		_bouncy_frameset(0x4C75)
		return
	if check_airborne_collision() == 0:
		if wWarioState != WST_BOUNCY_AIRBORNE:
			return
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_BOUNCY_AIRBORNE:
		return
	set_state_bouncy_floor()


## UpdateState_BouncyCeiling: squashed against it, then falling.
func update_state_bouncy_ceiling() -> void:
	decrement_transformation_duration()
	if wTransformationDuration == 0:
		set_state_bouncy_upside_down()
		return
	_bouncy_flicker()
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_bouncy_airborne()


## SetState_BouncyUpsideDown: time up in the air: falling upside down, touches passing through.
func set_state_bouncy_upside_down() -> void:
	wWarioState = WST_BOUNCY_UPSIDE_DOWN
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_NORMAL
	wWarioStateCycles = 0
	wTouchState = TOUCH_PASS_THROUGH
	wStingTouchState = TOUCH_PASS_THROUGH
	wca94 = 2
	set_wario_pal(WARIO_BOUNCY_PAL)
	_bouncy_frameset(0x4C82)


func update_state_bouncy_upside_down() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	apply_jump_velocity()
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_BOUNCY_UPSIDE_DOWN:
		return
	wWarioState = WST_BOUNCY_UPSIDE_DOWN_LANDING
	wJumpVelIndex = 0
	wJumpVelTable = 0
	_bouncy_frameset(0x4C85)


## UpdateState_BouncyUpsideLanding: then the last bounce.
func update_state_bouncy_upside_down_landing() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		_bouncy_last_bounce_start()


## Func_2a2e7 and SetState_BouncyLastBounce: touches passing through, one last normal jump.
func _bouncy_last_bounce_start() -> void:
	wTouchState = TOUCH_PASS_THROUGH
	wStingTouchState = TOUCH_PASS_THROUGH
	wca94 = 2
	set_wario_pal(WARIO_BOUNCY_PAL)
	wWarioFramesetPtr = 0x4CB2 if wDirection != DIRECTION_LEFT else 0x4CBF
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioState = WST_BOUNCY_LAST_BOUNCE
	wJumpVelIndex = 0
	wJumpVelTable = JUMP_VEL_NORMAL
	update_wario_animation_2()


## UpdateState_BouncyLastBounce: its animation once; the jump (HandleWalk carries him on); on the
## ground, Wario again.
func update_state_bouncy_last_bounce() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioAnimationEnded == 0:
		update_wario_animation_2()
	apply_jump_velocity()
	_walk_ahead()
	_cap_bouncy_walk()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_BOUNCY_LAST_BOUNCE:
			return
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_BOUNCY_LAST_BOUNCE:
		return
	recover_from_transformation()


## Func_2ae3b: near the end (Func_2ae5c: under 360 frames left, every 16th frame; under 120, every
## 4th) the palette alternates between the bouncy one and the red one (wWarioStateCycles).
func _bouncy_flicker() -> void:
	var high: int = wTransformationDuration >> 8
	var low: int = wTransformationDuration & 0xFF
	var flick: bool
	if high >= 2:
		flick = false
	elif high == 0 and low < 0x78:
		flick = (wGlobalCounter & 0b11) == 0
	elif high == 1 and low >= 0x68:
		flick = false
	else:
		flick = (wGlobalCounter & 0x0F) == 0
	if not flick:
		return
	wWarioStateCycles ^= 1
	set_wario_pal(WARIO_BOUNCY_RED_PAL if wWarioStateCycles != 0 else WARIO_BOUNCY_PAL)


# --- Blind Wario (wario_states_4.asm) -----------------------------------------------------

## SetState_BlindIdling: Wario's own graphics and palette (the screen is dark, presentation).
func set_state_blind_idling() -> void:
	wWarioState = WST_BLIND_IDLING
	wSFXLoopCounter = 0
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wInvisibleFrame = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14000)
	wWarioFramesetPtr = FRAMESET_IDLE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_IDLE_LEFT
	update_wario_animation()


## UpdateState_BlindIdling: Func_1edf93 (A jumps, the pad walks); still idling, nothing under him
## is a fall.
func update_state_blind_idling() -> void:
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		_blind_jump()
	elif (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_blind_walking()
	if wWarioState != WST_BLIND_IDLING:
		return
	if check_centre_collision() == 0:
		_blind_fall()


## SetState_BlindWalking: the frameset by the pad (Left, then Right), else by his direction, which
## it leaves as it is.
func set_state_blind_walking() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_BLIND_WALKING
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	var right: bool = (wJoypadDown & PAD_LEFT) == 0 and ((wJoypadDown & PAD_RIGHT) != 0 or wDirection != DIRECTION_LEFT)
	wWarioFramesetPtr = FRAMESET_WALK_RIGHT if right else FRAMESET_WALK_LEFT
	update_wario_animation()


## UpdateState_BlindWalking: walking into a wall gives him his sight back; Func_1edfa4; off the
## ground, falling; otherwise his height follows it.
func update_state_blind_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	update_wario_animation()
	var b: int = check_front_collision()
	if wWarioState != WST_BLIND_WALKING:
		return
	if b != 0:
		recover_from_transformation()
		return
	_blind_walk_input()
	if wWarioState != WST_BLIND_WALKING:
		return
	if check_centre_collision() == 0:
		_blind_fall()
		return
	update_pos_y()


## Func_1edfa4: A jumps; the pad walks the way he faces (the walk index kept below $10, back to
## $0c) or turns him; no direction, idling.
func _blind_walk_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		_blind_jump()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			wDirection = DIRECTION_RIGHT
			set_state_blind_turning()
			return
		walk_if_possible_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			wDirection = DIRECTION_LEFT
			set_state_blind_turning()
			return
		walk_if_possible_left()
	else:
		set_state_blind_idling()
		return
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C


func set_state_blind_turning() -> void:
	wWarioState = WST_BLIND_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wWarioFramesetPtr = FRAMESET_TURN_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_TURN_LEFT
	update_wario_animation()


## UpdateState_BlindTurning: A jumps at once; then walking.
func update_state_blind_turning() -> void:
	update_wario_animation()
	if (wJoypadPressed & PAD_A) != 0:
		_blind_jump()
		return
	if wWarioAnimationEnded != 0:
		set_state_blind_walking()


## Func_1ed548: falling, on the high jump's table.
func _blind_fall() -> void:
	wJumpingUpwards = 0
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_HIGH_JUMP
	set_state_blind_airborne()


## Func_1ed558: jumping (SFX_JUMP not simulated).
func _blind_jump() -> void:
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wJumpingUpwards = 1
	wJumpVelTable = JUMP_VEL_NORMAL
	set_state_blind_airborne()


## SetState_BlindAirborne: standing on an object, its first update at once.
func set_state_blind_airborne() -> void:
	wWarioSlopeInteraction = 0
	wWarioState = WST_BLIND_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsCrouching = 0
	wAttackCounter = 0
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = FRAMESET_AIRBORNE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_AIRBORNE_LEFT
	update_wario_animation()
	if wIsOnSteppableObject != 0:
		update_state_blind_airborne()


## UpdateState_BlindAirborne: water or a wall in front gives him his sight back; the jump, steered
## (Func_1ee00f); a ceiling makes it a fall; on the ground, idling.
func update_state_blind_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	var b: int = check_front_collision()
	if wWarioState != WST_BLIND_AIRBORNE:
		return
	if b != 0:
		recover_from_transformation()
		return
	apply_jump_velocity()
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C
	if wWarioState != WST_BLIND_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() == 0:
			return
		if wWarioState != WST_BLIND_AIRBORNE:
			return
		_blind_fall()
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	set_state_blind_idling()


# --- Ice Skatin' (wario_states_4.asm) -----------------------------------------------------

## SetState_IceSkatinStart: frozen into skates, facing the way the object faced (wObjDirection);
## the music change is not simulated.
func set_state_ice_skatin_start() -> void:
	wWarioState = WST_ICE_SKATIN_START
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wInvisibleFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_ICE_SKATIN_PAL)
	load_wario_gfx(WARIO_BUBBLE_GFX)
	set_wario_oam(OAM_1FDB6D)
	wDirection = wObjDirection
	wWarioFramesetPtr = 0x5D82 if wDirection != DIRECTION_LEFT else 0x5D8B
	update_wario_animation_2()


## UpdateState_IceSkatinStart: then skating from a standstill.
func update_state_ice_skatin_start() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wWalkVelIndex = 0
	set_state_ice_skatin()


## SetState_IceSkatin
func set_state_ice_skatin() -> void:
	wWarioState = WST_ICE_SKATIN
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5D94 if wDirection != DIRECTION_LEFT else 0x5D97
	update_wario_animation_2()


## UpdateState_IceSkatin: skating the way he faces, faster along the walk's table (its index kept
## between $10 and $13 once past $14), whatever the pad; a wall ahead crashes him; nothing under
## him, a fall. The sound's counter runs every 12 frames (SFX_ZIP_LINE_SLIDE not simulated).
func update_state_ice_skatin() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if check_front_collision() != 0:
		_ice_skatin_hit_wall()
		return
	var sfx: int = wSFXLoopCounter - 1
	wSFXLoopCounter = 0x0C if sfx < 0 else sfx
	update_wario_animation_2()
	if wDirection == DIRECTION_LEFT:
		move_wario_left(apply_walk_velocity_left())
	else:
		move_wario_right(apply_walk_velocity_right())
	if wWalkVelIndex >= 0x14:
		wWalkVelIndex = 0x10
	if check_centre_collision() == 0:
		wWarioState = WST_ICE_SKATIN_AIRBORNE
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
		wJumpVelTable = JUMP_VEL_NORMAL
		return
	wWarioYPos = hYPos


## Func_1ec215: back 3 px from the wall, and the crash.
func _ice_skatin_hit_wall() -> void:
	if wDirection == DIRECTION_LEFT:
		move_wario_right(3)
	else:
		move_wario_left(3)
	set_state_ice_skatin_crash()


## UpdateState_IceSkatinAirborne: falling on, skating in the air; water or a wall crashes him;
## landing, skating again from index $10.
func update_state_ice_skatin_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		set_state_ice_skatin_crash()
		return
	if check_front_collision() != 0:
		_ice_skatin_hit_wall()
		return
	update_wario_animation_2()
	apply_jump_velocity()
	if wDirection == DIRECTION_LEFT:  # HandleWalk
		walk_left()
	else:
		walk_right()
	if wWalkVelIndex >= 0x14:
		wWalkVelIndex = 0x10
	if wWarioState != WST_ICE_SKATIN_AIRBORNE:
		return
	if check_airborne_collision() == 0:
		if wWarioState != WST_ICE_SKATIN_AIRBORNE:
			return
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState != WST_ICE_SKATIN_AIRBORNE:
		return
	wWalkVelIndex = 0x10
	set_state_ice_skatin()


## SetState_IceSkatinCrash: turned round (SFX_02E not simulated).
func set_state_ice_skatin_crash() -> void:
	wWarioState = WST_ICE_SKATIN_CRASH
	wFrameDuration = 0
	wAnimationFrame = 0
	wDirection ^= 1
	wWarioFramesetPtr = 0x5D9A if wDirection != DIRECTION_LEFT else 0x5DA7
	update_wario_animation_2()


## UpdateState_IceSkatinCrash: when the animation ends, the ice breaks (PARTICLE_ICE) and he is
## himself again.
func update_state_ice_skatin_crash() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	get_pos()
	create_particle(PARTICLE_ICE)
	recover_from_transformation()


# --- Hanging from a rail (wario_states_4.asm) ---------------------------------------------

## SetState_HangingRail's part of ObjInteraction_Rail: hanging, carried by the object
## (wAutoMoveState), facing the way it faces.
func set_state_hanging_rail() -> void:
	wWarioState = WST_HANGING_RAIL
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wAutoMoveState = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_HANG_GFX)
	set_wario_oam(OAM_1FEE05)
	wDirection = wObjDirection
	wWarioFramesetPtr = 0x6EC4
	update_wario_animation_2()


## UpdateState_HangingRail: after the grab, the hanging animation; B lets go, A jumps off
## (Func_1ede4d); when the line stops carrying him, he drops rolling (Func_1ede69).
func update_state_hanging_rail() -> void:
	if wWarioStateCounter == 0 and wWarioAnimationEnded != 0:
		wWarioStateCounter = 1
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = 0x6EB4
	update_wario_animation_2()
	if (wJoypadPressed & PAD_B) != 0:
		recover_from_transformation_without_invincibility()
		return
	if (wJoypadPressed & PAD_A) != 0:
		clear_transformation_values()
		set_wario_pal(WARIO_DEFAULT_PAL)
		start_jump_from_input()
		return
	if wAutoMoveState == 0:
		clear_transformation_values()
		set_wario_pal(WARIO_DEFAULT_PAL)
		start_rolling_fall()


# --- Teleporting (wario_states_2.asm) ----------------------------------------------------------------

## UpdateState_Teleporting and _WaterTeleporting (ObjInteraction_Jamano, _WaterTeleporting):
## intangible for $b4 frames (SFX_082 at frame 1, in water at $11), then stung (in water, water
## stung), invincible, and the delayed teleport goes ahead.
func update_state_teleporting(water: bool) -> void:
	wIsIntangible = 1
	update_wario_animation()
	wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wWarioStateCounter == (0x11 if water else 0x01) or wWarioStateCounter < 0xB4:
		return
	wWarioStateCounter = 0
	wWarioState = WST_WATER_STUNG if water else WST_STUNG
	wInvincibleCounter = 1
	wRoomTransitionParam &= ~ROOMTRANSITIONF_DELAY
	trigger_room_transition()


# --- Turning invisible (wario_states_3.asm) ------------------------------------------------------

## SetState_TurningInvisible (ObjInteraction_InvisibilityPotion): intangible while he turns, touches
## and stings neutral, the tall box, the default palette, the dizzy graphics (SFX_03F); at the
## animation's end (UpdateState_TurningInvisible) Invisible Wario, idling (the music not simulated).
func set_state_turning_invisible() -> void:
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wIsIntangible = 1
	wWarioState = WST_TURNING_INVISIBLE
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wTouchState = 0
	wStingTouchState = 0
	wca94 = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_DIZZY_GFX)
	set_wario_oam(OAM_17CF7)
	wWarioFramesetPtr = 0x7E3A if wDirection != DIRECTION_LEFT else 0x7E1B
	update_wario_animation()


# --- Puffy Wario (wario_states_3.asm) -----------------------------------------------------------

## SetState_PuffyInflating (ObjInteraction_Pneumo from below, ObjInteraction_YellowBellyArrow):
## Puffy Wario, vulnerable to stings and bumped by touches, the tall box, everything else cleared
## (the music not simulated).
func set_state_puffy_inflating() -> void:
	wTransformation = TRANSFORMATION_PUFFY_WARIO
	wStingTouchState = TOUCH_VULNERABLE
	wTouchState = TOUCH_BUMP
	wca94 = 1
	wWarioState = WST_PUFFY_INFLATING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wSwimVelIndex = 0
	wWaterSurfaceFloatingCounter = 0
	wWaterCurrent = 0
	wLastWaterCurrent = 0
	wCurWaterCurrent = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_PUFFY_GFX)
	set_wario_oam(OAM_1DC93F)
	wWarioFramesetPtr = 0x4CC9 if wDirection != DIRECTION_LEFT else 0x4CC0
	update_wario_animation_oam_bank()


## UpdateState_PuffyInflating: the animation, then rising.
func update_state_puffy_inflating() -> void:
	update_wario_animation_oam_bank()
	if wWarioAnimationEnded != 0:
		set_state_puffy_rising()


## SetState_PuffyRising: wJumpVelTable 1 (he is in the air), the default palette.
func set_state_puffy_rising() -> void:
	wWarioState = WST_PUFFY_RISING
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelTable = 1
	set_wario_pal(WARIO_DEFAULT_PAL)
	wWarioFramesetPtr = 0x4D57 if wDirection != DIRECTION_LEFT else 0x4D4E
	update_wario_animation_oam_bank()


## UpdateState_PuffyRising: a room transition first; then up half a pixel a frame (Func_2b2c2).
func update_state_puffy_rising() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(32)  # SFX_PUFF_RAISE
	update_wario_animation_oam_bank()
	_puffy_rise()


## Func_2b2c2: up (Func_2b342); a ceiling deflates him; a floor above starts a floor transition;
## the pad's other way turns him, its way moves him a pixel unless a wall (broken where it can be)
## is at his bottom corner.
func _puffy_rise() -> void:
	_puffy_float_up()
	var b: int = check_up_collision()
	if wWarioState != WST_PUFFY_RISING:
		return
	if b != 0:
		set_state_puffy_deflating()
		return
	handle_upwards_floor_transition()
	if wDirection == DIRECTION_LEFT:
		if (wJoypadDown & PAD_RIGHT) != 0:
			set_state_puffy_turning()
		elif (wJoypadDown & PAD_LEFT) != 0 and check_bottom_left_breaking() == 0:
			move_wario_left(1)
	else:
		if (wJoypadDown & PAD_LEFT) != 0:
			set_state_puffy_turning()
		elif (wJoypadDown & PAD_RIGHT) != 0 and check_bottom_right_breaking() == 0:
			move_wario_right(1)


## Func_2b342: a pixel up on even frames.
func _puffy_float_up() -> void:
	if (wGlobalCounter & 1) == 0:
		move_wario_up(1)


## SetState_PuffyTurning: facing the other way.
func set_state_puffy_turning() -> void:
	wDirection ^= 1
	wWarioState = WST_PUFFY_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x4CD8 if wDirection != DIRECTION_LEFT else 0x4CE3
	update_wario_animation_oam_bank()


## UpdateState_PuffyTurning: rising as he turns; a ceiling deflates him, the animation's end
## has him rise again.
func update_state_puffy_turning() -> void:
	update_wario_animation_oam_bank()
	_puffy_float_up()
	var b: int = check_up_collision()
	if wWarioState != WST_PUFFY_TURNING:
		return
	if b != 0:
		set_state_puffy_deflating()
	elif wWarioAnimationEnded != 0:
		set_state_puffy_rising()


## SetState_PuffyDeflating: intangible while the air goes out (SFX_027).
func set_state_puffy_deflating() -> void:
	wWarioState = WST_PUFFY_DEFLATING
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wIsIntangible = 1
	wWarioFramesetPtr = 0x4D1E if wDirection != DIRECTION_LEFT else 0x4CEE
	update_wario_animation_oam_bank()


## UpdateState_PuffyDeflating: two animations, then RecoverFromTransformation.
func update_state_puffy_deflating() -> void:
	if wWarioStateCounter == 0:
		update_wario_animation_oam_bank()
		if wWarioAnimationEnded == 0:
			return
		wWarioStateCounter = 1
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = 0x4D31 if wDirection != DIRECTION_LEFT else 0x4D01
	update_wario_animation_oam_bank()
	if wWarioAnimationEnded != 0:
		recover_from_transformation()


# --- Split by a beam (wario_states_4.asm) ---------------------------------------------------------

## SetState_SplitHit (ObjInteraction_Beam): facing the way the beam came, knocked up on table 1 from
## index $0e, the tall box, the snowball graphics and the split palette (the music not simulated).
func set_state_split_hit() -> void:
	wWarioState = WST_SPLIT_HIT
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 1
	wJumpVelIndex = 0x0E
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_SPLIT_PAL)
	load_wario_gfx(WARIO_SNOWBALL_GFX)
	set_wario_oam(OAM_1FFA12)
	wDirection = wObjDirection
	wWarioFramesetPtr = 0x7D10 if wDirection != DIRECTION_LEFT else 0x7D16
	update_wario_animation_2()


## UpdateState_SplitHit: the animation, then knocked back.
func update_state_split_hit() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wWarioState = WST_SPLIT_KNOCKED_BACK
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x7D13 if wDirection != DIRECTION_LEFT else 0x7D19
	update_wario_animation_2()


## UpdateState_SplitKnockedBack: a transition or water first; along the jump, carried the way he
## faces (HandleWalk, Func_1762), until he lands: then splitting (SFX_044).
func update_state_split_knocked_back() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	apply_jump_velocity()
	if check_airborne_collision() == 0:
		_walk_ahead()
		cap_airborne_walk_velocity()
		trigger_downwards_floor_transition()
		return
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x7C8E if wDirection != DIRECTION_LEFT else 0x7CCF
	update_wario_animation_2()
	set_state_splitting()


## SetState_Splitting: on the ground.
func set_state_splitting() -> void:
	trigger_floor_transition()
	wWarioState = WST_SPLITTING
	wJumpVelTable = 0
	wJumpVelIndex = 0


## UpdateState_Splitting: at the animation's end back together, facing the other way; nothing
## under him, falling.
func update_state_splitting() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		_split_recover()
		return
	if check_centre_collision() != 0:
		return
	wWarioState = WST_SPLITTING_AIRBORNE
	wJumpVelTable = JUMP_VEL_NORMAL
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX


## UpdateState_SplittingAirborne: falling while the animation runs.
func update_state_splitting_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		_split_recover()
		return
	apply_jump_velocity()
	if check_airborne_collision() != 0:
		set_state_splitting()
		return
	trigger_downwards_floor_transition()


## Func_1ed09b: facing the other way, RecoverFromTransformation.
func _split_recover() -> void:
	wDirection ^= 1
	recover_from_transformation()


# --- Vampire Wario and the bat (wario_states_3.asm) -----------------------------------------------

## SetState_VampireTransforming (ObjInteraction_Vampire, and the bat turning back): touches and
## stings make objects vanish, the tall box, the vampire palette, the bat's graphics and OAM table
## (the music not simulated).
func set_state_vampire_transforming() -> void:
	wWarioState = WST_VAMPIRE_TRANSFORMING
	wTouchState = TOUCH_VANISH
	wStingTouchState = TOUCH_VANISH
	wca94 = 2
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_VAMPIRE_PAL)
	load_wario_gfx(WARIO_BAT_GFX)
	set_wario_oam(OAM_1FD031)
	wWarioFramesetPtr = 0x5439
	update_wario_animation_2()


## UpdateState_VampireTransforming: the animation, then idling.
func update_state_vampire_transforming() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_vampire_idling()


## SetState_VampireIdling: the vampire's graphics and OAM table (in the same bank as the bat's).
func set_state_vampire_idling() -> void:
	wWarioState = WST_VAMPIRE_IDLING
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_VAMPIRE_GFX)
	wWarioOAMPtr = OAM_1FD498 & 0xFFFF
	wWarioFramesetPtr = 0x581C
	update_wario_animation_2()


## UpdateState_VampireIdling: nothing under him, a fall; otherwise the pad (Func_2b4f3).
func update_state_vampire_idling() -> void:
	var b: int = check_centre_collision()
	if wWarioState != WST_VAMPIRE_IDLING:
		return
	if b == 0:
		_vampire_fall()
		return
	update_wario_animation_2()
	if (wJoypadPressed & PAD_B) != 0:
		set_state_bat_transforming()
	elif (wJoypadPressed & PAD_A) != 0:
		_vampire_jump()
	elif (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_vampire_walking()


## SetState_VampireWalking: the way the pad holds (left first), else the way he faces.
func set_state_vampire_walking() -> void:
	wWarioState = WST_VAMPIRE_WALKING
	wWalkVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	var left: bool = (wJoypadDown & PAD_LEFT) != 0 \
			or ((wJoypadDown & PAD_RIGHT) == 0 and wDirection == DIRECTION_LEFT)
	wDirection = DIRECTION_LEFT if left else DIRECTION_RIGHT
	wWarioFramesetPtr = 0x5825 if left else 0x582E
	update_wario_animation_2()


## UpdateState_VampireWalking: a transition first; the pad (Func_2b509); nothing under him, a fall.
func update_state_vampire_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWarioState != WST_VAMPIRE_WALKING:
		return
	update_wario_animation_2()
	_vampire_walk_input()
	if wWarioState != WST_VAMPIRE_WALKING:
		return
	var b: int = check_centre_collision()
	if wWarioState == WST_VAMPIRE_WALKING and b == 0:
		_vampire_fall()


## Func_2b509: B held a bat, A held a jump; the pad walks him (turning first if he faces the other
## way, the walk index below $10), else he idles.
func _vampire_walk_input() -> void:
	if (wJoypadDown & PAD_B) != 0:
		set_state_bat_transforming()
		return
	if (wJoypadDown & PAD_A) != 0:
		_vampire_jump()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			set_state_vampire_turning()
			return
		walk_if_possible_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			set_state_vampire_turning()
			return
		walk_if_possible_left()
	else:
		set_state_vampire_idling()
		return
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C


## SetState_VampireTurning: facing the other way.
func set_state_vampire_turning() -> void:
	wWarioState = WST_VAMPIRE_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wDirection ^= 1
	wWarioFramesetPtr = 0x583A if wDirection != DIRECTION_LEFT else 0x5841
	update_wario_animation_2()


## UpdateState_VampireTurning: the animation, then walking.
func update_state_vampire_turning() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_vampire_walking()


## Func_2a8a7: falling.
func _vampire_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_state_vampire_airborne()


## Func_2a8ae: a jump (SFX_01D).
func _vampire_jump() -> void:
	wJumpVelIndex = 0
	set_state_vampire_airborne()


## SetState_VampireAirborne: on the knock-back table.
func set_state_vampire_airborne() -> void:
	wWarioState = WST_VAMPIRE_AIRBORNE
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0


## UpdateState_VampireAirborne: a transition, or water (back to himself), first; the jump, the pad
## steering (Func_2b55c); rising, a ceiling makes him fall; falling, the ground lands him idling.
func update_state_vampire_airborne() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioState != WST_VAMPIRE_AIRBORNE:
		return
	update_wario_animation_2()
	apply_jump_velocity()
	_walk_by_pad()
	if wWalkVelIndex >= 0x10:
		wWalkVelIndex = 0x0C
	if wWarioState != WST_VAMPIRE_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		var b: int = check_up_collision()
		if wWarioState == WST_VAMPIRE_AIRBORNE and b != 0:
			_vampire_fall()
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	if wWarioState == WST_VAMPIRE_AIRBORNE:
		set_state_vampire_idling()


## Func_2b17a: the pad walks him (WalkRight, WalkLeft), turning him if need be.
func _walk_by_pad() -> void:
	if (wJoypadDown & PAD_RIGHT) != 0:
		walk_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		walk_left()


## SetState_BatTransforming (SFX_046): the bat's short box (top -15) and graphics.
func set_state_bat_transforming() -> void:
	wWarioState = WST_BAT_TRANSFORMING
	wCollisionBoxTop = byte(-15)
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_BAT_GFX)
	wWarioOAMPtr = OAM_1FD031 & 0xFFFF
	wWarioFramesetPtr = 0x5479 if wDirection != DIRECTION_LEFT else 0x540A
	update_wario_animation_2()


## UpdateState_BatTransforming: the animation, then idling.
func update_state_bat_transforming() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_bat_idling()


## SetState_BatIdling
func set_state_bat_idling() -> void:
	wWarioState = WST_BAT_IDLING
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x546C if wDirection != DIRECTION_LEFT else 0x545F
	update_wario_animation_2()


## UpdateState_BatIdling: nothing under it, falling; B turns it back into the vampire where there
## is room above for his box (otherwise the bat's box again, SFX_0E5); A flies.
func update_state_bat_idling() -> void:
	var b: int = check_centre_collision()
	if wWarioState != WST_BAT_IDLING:
		return
	if b == 0:
		set_state_bat_falling()
		return
	_sfx_loop(0x20)  # SFX_FLAP
	update_wario_animation_2()
	if (wJoypadPressed & PAD_B) != 0:
		wCollisionBoxTop = byte(-27)
		b = check_up_collision()
		if wWarioState != WST_BAT_IDLING:
			return
		if b == 0:
			set_state_vampire_transforming()
		else:
			wCollisionBoxTop = byte(-15)
	elif (wJoypadPressed & PAD_A) != 0:
		set_state_bat_flying()


## SetState_BatFlying
func set_state_bat_flying() -> void:
	wWarioState = WST_BAT_FLYING
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 1
	_bat_flying_frameset()


## UpdateState_BatFlying: a transition, or water, first; a ceiling makes it fall; otherwise it flaps
## up (Func_2b63b) and the pad steers it (the walk index below 8), turning it.
func update_state_bat_flying() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioState != WST_BAT_FLYING:
		return
	_sfx_loop(0x10)  # SFX_FLAP
	update_wario_animation_2()
	var b: int = check_up_collision()
	if wWarioState != WST_BAT_FLYING:
		return
	if b != 0:
		set_state_bat_falling()
		return
	_bat_flap()
	if wWarioState != WST_BAT_FLYING:
		return
	_walk_by_pad()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if wIsTurning != 0:
		_bat_flying_frameset()


## Func_2abc1: the flying frameset, by direction.
func _bat_flying_frameset() -> void:
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5434 if wDirection != DIRECTION_LEFT else 0x542C
	update_wario_animation_2()


## Func_2b63b: while A is held, up along the swim's straight table by wJumpVelIndex (Func_1f863);
## A let go, or past the table's end, falling.
func _bat_flap() -> void:
	if (wJoypadDown & PAD_A) == 0:
		set_state_bat_falling()
		return
	wJumpVelIndex = byte(wJumpVelIndex + 1)
	if wJumpVelIndex > MAX_JUMP_VEL_INDEX:
		set_state_bat_falling()
		return
	move_wario_up(tables.swim_steps["straight"][wJumpVelIndex])


## SetState_BatFalling: on the high jump's table, falling.
func set_state_bat_falling() -> void:
	wWarioState = WST_BAT_FALLING
	wJumpVelTable = JUMP_VEL_HIGH_JUMP
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX


## UpdateState_BatFalling: a transition, or water, first; A flies again; the fall, the pad steering;
## the ground (its height taken) lands it idling.
func update_state_bat_falling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	if wWarioState != WST_BAT_FALLING:
		return
	update_wario_animation_2()
	if (wJoypadPressed & PAD_A) != 0:
		set_state_bat_flying()
		return
	apply_jump_velocity()
	_walk_by_pad()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if wIsTurning != 0:
		_bat_flying_frameset()
	var b: int = check_airborne_collision()
	if wWarioState != WST_BAT_FALLING or b == 0:
		return
	update_pos_y()
	set_state_bat_idling()


# --- In a bubble (wario_states_3.asm) ---------------------------------------------------------------

## Func_2ac7d (ObjInteraction_Bubble): in a bubble drifting the way it came (wWarioStateCounter keeps
## that way), the tall box, the bubble's palette and graphics (the music not simulated).
func set_state_in_bubble() -> void:
	wWarioState = WST_IN_BUBBLE
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wSFXLoopCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_BUBBLE_PAL)
	load_wario_gfx(WARIO_BUBBLE_GFX)
	set_wario_oam(OAM_1FD87C)
	wDirection = wObjDirection
	wWarioStateCounter = wObjDirection
	wWarioFramesetPtr = 0x5B2C
	update_wario_animation_2()


## UpdateState_InBubble: out of the water the bubble bursts; in it, the bubble rises and drifts
## (Func_2b56f).
func update_state_in_bubble() -> void:
	probe_presence_top()
	if wWaterInteraction == 0:
		_burst_bubble()
		return
	_sfx_loop(0x0E)  # SFX_023
	update_wario_animation_2()
	_bubble_drift()


## The bubble bursts (PARTICLE_BUBBLE_BURST at Wario), and he is himself again.
func _burst_bubble() -> void:
	get_pos()
	create_particle(PARTICLE_BUBBLE_BURST)
	recover_from_transformation()


## Func_2b56f: on odd frames a pixel up, a ceiling bursting it; on even frames the pad pushes it a
## pixel (a wall turns it back), or it drifts along Data_2b6b4 the way it goes, turning back at a
## wall or at the table's end.
func _bubble_drift() -> void:
	if (wGlobalCounter & 1) != 0:
		move_wario_up(1)
		if check_up_collision() != 0:
			_burst_bubble()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if check_bottom_right_breaking() != 0:
			_bubble_turn_back()
			return
		move_wario_right(1)
		wJumpVelIndex = 0
		return
	if (wJoypadDown & PAD_LEFT) != 0:
		if check_bottom_left_breaking() != 0:
			_bubble_turn_back()
			return
		move_wario_left(1)
		wJumpVelIndex = 0
		return
	wDirection = wWarioStateCounter
	if check_front_collision() != 0:
		_bubble_turn_back()
		return
	var b: int = tables.bubble_drift_steps[wJumpVelIndex]
	if wWarioStateCounter == 0:
		move_wario_left(b)
	else:
		move_wario_right(b)
	wJumpVelIndex = byte(wJumpVelIndex + 1)
	if wJumpVelIndex >= 0x2F:
		_bubble_turn_back()


## .asm_2b5f7: the drift the other way, from the table's start.
func _bubble_turn_back() -> void:
	wWarioStateCounter ^= 1
	wDirection = wWarioStateCounter
	wJumpVelIndex = 0


# --- Owl Wario (wario_states_4.asm) ---------------------------------------------------------------

## ObjInteraction_Owl from below: hanging from the owl, facing the way it flies (bumped by touches,
## vulnerable to stings), the tall box, the hanging graphics (the music not simulated).
func set_state_grabbing_owl() -> void:
	wWarioState = WST_GRABBING_OWL
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_HANG_GFX)
	set_wario_oam(OAM_1FDDB4)
	wDirection = wObjDirection
	wWarioFramesetPtr = 0x6D53
	update_wario_animation_2()


## UpdateState_GrabbingOwl: the animation, then flying (fast if the pad is held).
func update_state_grabbing_owl() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	if (wJoypadDown & PAD_CTRL_PAD) != 0:
		handle_owl_input()
	else:
		_update_owl_direction()


## UpdateWarioOwlDirection: flying the way he faces.
func _update_owl_direction() -> void:
	wSwimmingDirectionInput = PAD_LEFT if wDirection == DIRECTION_LEFT else PAD_RIGHT
	set_state_owl_wario()


## SetState_OwlWario: flying slowly along wSwimmingDirectionInput.
func set_state_owl_wario() -> void:
	wWarioState = WST_OWL_SLOW
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	if (wSwimmingDirectionInput & (PAD_UP | PAD_DOWN)) != 0:
		wWarioFramesetPtr = 0x6DD0
	else:
		wWarioFramesetPtr = 0x6D91 if wDirection != DIRECTION_LEFT else 0x6D7C
	update_wario_animation_2()


## UpdateState_OwlSlow: B or water lets go; a transition first; the pad flies fast; otherwise a
## pixel a frame along the way it goes, turning back at a wall, floor, or ceiling.
func update_state_owl_slow() -> void:
	if (wJoypadPressed & PAD_B) != 0:
		_let_go_of_owl()
		return
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		_let_go_of_owl()
		return
	if wWarioState != WST_OWL_SLOW:
		return
	if (wJoypadDown & PAD_CTRL_PAD) != 0:
		handle_owl_input()
		return
	_sfx_loop(0x20)  # SFX_FLAP
	update_wario_animation_2()
	var b: int
	if (wSwimmingDirectionInput & PAD_RIGHT) != 0:
		b = check_bottom_right_breaking()
		if wWarioState != WST_OWL_SLOW:
			return
		if b != 0:
			wDirection = DIRECTION_LEFT
			_update_owl_direction()
		else:
			move_wario_right(1)
	elif (wSwimmingDirectionInput & PAD_UP) != 0:
		b = check_up_collision()
		if wWarioState != WST_OWL_SLOW:
			return
		if b != 0:
			wSwimmingDirectionInput = PAD_DOWN
			set_state_owl_wario()
		else:
			move_wario_up(1)
	elif (wSwimmingDirectionInput & PAD_DOWN) != 0:
		b = check_centre_collision()
		if wWarioState != WST_OWL_SLOW:
			return
		if b != 0:
			wSwimmingDirectionInput = PAD_UP
			set_state_owl_wario()
		else:
			move_wario_down(1)
	else:
		b = check_bottom_left_breaking()
		if wWarioState != WST_OWL_SLOW:
			return
		if b != 0:
			wDirection = DIRECTION_RIGHT
			_update_owl_direction()
		else:
			move_wario_left(1)


## HandleWarioOwlInput: flying fast the way the pad holds (up, then down, then right, else left).
func handle_owl_input() -> void:
	wWarioState = WST_OWL_FAST
	wSFXLoopCounter = 0
	if (wJoypadDown & PAD_UP) != 0:
		wSwimmingDirectionInput = PAD_UP
	elif (wJoypadDown & PAD_DOWN) != 0:
		wSwimmingDirectionInput = PAD_DOWN
	elif (wJoypadDown & PAD_RIGHT) != 0:
		wDirection = DIRECTION_RIGHT
		wSwimmingDirectionInput = PAD_RIGHT
	else:
		wDirection = DIRECTION_LEFT
		wSwimmingDirectionInput = PAD_LEFT
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	if (wSwimmingDirectionInput & (PAD_UP | PAD_DOWN)) != 0:
		wWarioFramesetPtr = 0x6DE5
	else:
		wWarioFramesetPtr = 0x6DBB if wDirection != DIRECTION_LEFT else 0x6DA6
	update_wario_animation_2()


## UpdateState_OwlFast: B or water lets go; a transition first; the pad let go, slow again; the pad
## held another way, that way; otherwise 2 px a frame unless something is in the way (going down,
## the ground's height taken).
func update_state_owl_fast() -> void:
	if (wJoypadPressed & PAD_B) != 0:
		_let_go_of_owl()
		return
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		_let_go_of_owl()
		return
	if wWarioState != WST_OWL_FAST:
		return
	if (wJoypadDown & PAD_CTRL_PAD) == 0:
		set_state_owl_wario()
		return
	_sfx_loop(0x10)  # SFX_FLAP
	update_wario_animation_2()
	var b: int
	if (wSwimmingDirectionInput & PAD_RIGHT) != 0:
		if (wJoypadDown & PAD_RIGHT) == 0:
			handle_owl_input()
			return
		b = check_bottom_right_breaking()
		if wWarioState == WST_OWL_FAST and b == 0:
			move_wario_right(2)
	elif (wSwimmingDirectionInput & PAD_UP) != 0:
		if (wJoypadDown & PAD_UP) == 0:
			handle_owl_input()
			return
		b = check_up_collision()
		if wWarioState == WST_OWL_FAST and b == 0:
			move_wario_up(2)
	elif (wSwimmingDirectionInput & PAD_DOWN) != 0:
		if (wJoypadDown & PAD_DOWN) == 0:
			handle_owl_input()
			return
		b = check_centre_collision()
		if wWarioState != WST_OWL_FAST:
			return
		if b != 0:
			update_pos_y()
		else:
			move_wario_down(2)
	else:
		if (wJoypadDown & PAD_LEFT) == 0:
			handle_owl_input()
			return
		b = check_bottom_left_breaking()
		if wWarioState == WST_OWL_FAST and b == 0:
			move_wario_left(2)


## Func_1ec64d: letting go (ReleaseOwl).
func _let_go_of_owl() -> void:
	wWarioState = WST_RELEASING_OWL
	release_owl()
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x6DFE
	update_wario_animation_2()


## ReleaseOwl: the owl flies off (PARTICLE_OWL, $18 px above Wario).
func release_owl() -> void:
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - 0x18)
	create_particle(PARTICLE_OWL)


## UpdateState_ReleasingOwl: the animation, then falling on table 2.
func update_state_releasing_owl() -> void:
	update_wario_animation_2()
	if wWarioAnimationEnded == 0:
		return
	wWarioState = WST_FALLING_FROM_OWL
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 2
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX


## UpdateState_FallingFromOwl: a transition, or water, first; the fall, the pad steering (the walk
## index below 8); the ground (its height taken) ends the transformation.
func update_state_falling_from_owl() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wWaterInteraction != 0:
		recover_from_transformation()
		return
	apply_jump_velocity()
	_walk_by_pad()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if check_airborne_collision() == 0:
		return
	update_pos_y()
	recover_from_transformation()


# --- Snowman Wario and the snowball (wario_states_4.asm) -----------------------------------------

## SetState_TurningIntoSnowman (ObjInteraction_Snow): the tall box; in the air, falling; the snowman's
## palette and graphics (SFX_047 and the music not simulated).
func set_state_turning_into_snowman() -> void:
	wWarioState = WST_SNOWMAN_START
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelIndex = 0
	if wJumpVelTable != 0:
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_SNOWMAN_PAL)
	load_wario_gfx(WARIO_SNOWMAN_GFX)
	set_wario_oam(OAM_1FEEC7)
	wWarioFramesetPtr = 0x75A3 if wDirection != DIRECTION_LEFT else 0x7560
	update_wario_animation_2()


## A transition, or water (back to himself), ends a snowman state first; true when one did.
func _snowman_left() -> bool:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return true
	if wWaterInteraction != 0:
		recover_from_transformation()
		return true
	return false


## UpdateState_SnowmanStart: falling to the ground if in the air, then at the animation's end idle.
func update_state_snowman_start() -> void:
	if _snowman_left():
		return
	if wJumpVelTable != 0:
		apply_jump_velocity()
		if check_airborne_collision() == 0:
			trigger_downwards_floor_transition()
			return
		trigger_floor_transition()
		wJumpVelTable = 0
		wJumpVelIndex = 0
	update_wario_animation_2()
	if wWarioAnimationEnded != 0:
		set_state_snowman_idle()


## SetState_SnowmanIdle
func set_state_snowman_idle() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_SNOWMAN_IDLE
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x75FB if wDirection != DIRECTION_LEFT else 0x75F8
	update_wario_animation_2()


## UpdateState_SnowmanIdle: A jumps, the pad walks (HandleSnowmanInput); nothing under him, a fall.
func update_state_snowman_idle() -> void:
	if _snowman_left():
		return
	if (wJoypadPressed & PAD_A) != 0:
		_snowman_jump()
	elif (wJoypadDown & (PAD_RIGHT | PAD_LEFT)) != 0:
		set_state_snowman_walking()
	if wWarioState == WST_SNOWMAN_IDLE and check_centre_collision() == 0:
		_snowman_fall()


## SetState_SnowmanWalking: the way the pad holds (left first), else the way he faces.
func set_state_snowman_walking() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_SNOWMAN_WALKING
	wSFXLoopCounter = 0
	wJumpVelIndex = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	var left: bool = (wJoypadDown & PAD_LEFT) != 0 \
			or ((wJoypadDown & PAD_RIGHT) == 0 and wDirection == DIRECTION_LEFT)
	wWarioFramesetPtr = 0x75E6 if left else 0x75EF
	update_wario_animation_2()


## UpdateState_SnowmanWalking: a transition first; the pad (Func_1ede96); nothing under him, a fall;
## on a slope, he rolls down it as a snowball.
func update_state_snowman_walking() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(0x1C)  # SFX_FAT_WALK
	update_wario_animation_2()
	_snowman_walk_input()
	if wWarioState != WST_SNOWMAN_WALKING:
		return
	if check_centre_collision() == 0:
		_snowman_fall()
		return
	if wWarioSlopeInteraction == 0:
		return
	update_pos_y()
	turn_into_small_snowball()


## Func_1ede96: A jumps; the pad walks him (turning first, the walk index below 8); else idle.
func _snowman_walk_input() -> void:
	if (wJoypadPressed & PAD_A) != 0:
		_snowman_jump()
		return
	if (wJoypadDown & PAD_RIGHT) != 0:
		if wDirection == DIRECTION_LEFT:
			wDirection = DIRECTION_RIGHT
			set_state_snowman_turning()
			return
		walk_if_possible_right()
	elif (wJoypadDown & PAD_LEFT) != 0:
		if wDirection != DIRECTION_LEFT:
			wDirection = DIRECTION_LEFT
			set_state_snowman_turning()
			return
		walk_if_possible_left()
	else:
		set_state_snowman_idle()
		return
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4


## SetState_SnowmanTurning (the direction already the new one)
func set_state_snowman_turning() -> void:
	wWarioState = WST_SNOWMAN_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x75FE if wDirection != DIRECTION_LEFT else 0x7605
	update_wario_animation_2()


## UpdateState_SnowmanTurning: A jumps; at the animation's end, walking.
func update_state_snowman_turning() -> void:
	if _snowman_left():
		return
	update_wario_animation_2()
	if (wJoypadPressed & PAD_A) != 0:
		_snowman_jump()
	elif wWarioAnimationEnded != 0:
		set_state_snowman_walking()


## SetState_SnowmanAirborne_Jump (SFX_JUMP): table 1 from its start.
func _snowman_jump() -> void:
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wJumpVelTable = 1
	wWarioFramesetPtr = 0x7617 if wDirection != DIRECTION_LEFT else 0x760C
	_snowman_airborne()


## SetState_SnowmanAirborne_Fall: falling on table 2, smashing.
func _snowman_fall() -> void:
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wIsSmashAttacking = 1
	wWarioStateCounter = 1
	wJumpVelTable = 2
	wWarioFramesetPtr = 0x7625 if wDirection != DIRECTION_LEFT else 0x7622
	_snowman_airborne()


## SetState_SnowmanAirborne
func _snowman_airborne() -> void:
	wWarioState = WST_SNOWMAN_AIRBORNE
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	update_wario_animation_2()


## UpdateState_SnowmanAirborne: the jump's animation into the fall's; the jump, the pad steering
## (Func_1edf01, smashing from the top of the arc); rising, a ceiling drops him; landing on a slope
## rolls him as a snowball, otherwise the ground shakes and he lands.
func update_state_snowman_airborne() -> void:
	if _snowman_left():
		return
	update_wario_animation_2()
	if wWarioStateCounter == 0 and wWarioAnimationEnded != 0:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioStateCounter = 1
		wWarioFramesetPtr = 0x7625 if wDirection != DIRECTION_LEFT else 0x7622
		update_wario_animation_2()
	apply_jump_velocity()
	_walk_by_pad()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if wJumpVelIndex == FALLING_JUMP_VEL_INDEX:
		wIsSmashAttacking = 1
	if wWarioState != WST_SNOWMAN_AIRBORNE:
		return
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		if check_up_collision() != 0 and wWarioState == WST_SNOWMAN_AIRBORNE:
			_snowman_fall()
		return
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	check_centre_collision()
	if wWarioSlopeInteraction != 0:
		turn_into_small_snowball()
		return
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 0x20
		wIsWarioGroundShaking = 1
	wWarioState = WST_SNOWMAN_LANDING  # SFX_024 unless a floor transition is under way
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wWarioStateCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x7617 if wDirection != DIRECTION_LEFT else 0x760C
	update_wario_animation_2()


## SetState_SnowmanBumped (attacking an object as a snowman)
func set_state_snowman_bumped() -> void:
	wWarioState = WST_SNOWMAN_BUMPED
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x7639 if wDirection != DIRECTION_LEFT else 0x7628
	update_wario_animation_2()


## TurnIntoSmallSnowball: down the slope (wWarioSlopeInteraction's low nibble less 1 is the way), a
## small snowball (wTransformationProgress 1).
func turn_into_small_snowball() -> void:
	wTransformationProgress = 1
	wWarioStateCounter = 0
	load_wario_gfx(WARIO_SNOWBALL_GFX)
	set_wario_oam(OAM_1FF64A)
	wFrameDuration = 0
	wAnimationFrame = 0
	wDirection = byte((wWarioSlopeInteraction & 0x0F) - 1)
	wWarioFramesetPtr = 0x792B if wDirection != DIRECTION_LEFT else 0x7956
	update_wario_animation_2()
	set_state_snowball_rolling()


## SetState_SnowballRolling
func set_state_snowball_rolling() -> void:
	wWarioState = WST_SNOWBALL_ROLLING
	wSFXLoopCounter = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0


## UpdateState_SnowballRolling: it grows with the distance rolled (wWarioStateCounter, by the pixels
## moved: medium from $70, big from $e0, the animation's frame kept on at the big one); rolling on
## the walk velocity (below $18); a wall crashes it; without ground it falls on table 3.
func update_state_snowball_rolling() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	if wTransformationProgress == 2:
		if wWarioStateCounter >= 0xE0:
			wTransformationProgress = 3
			wFrameDuration = 0
			wAnimationFrame = byte(wAnimationFrame + 2)
			wWarioFramesetPtr = 0x7945 if wDirection != DIRECTION_LEFT else 0x7970
	elif wTransformationProgress != 3 and wWarioStateCounter >= 0x70:
		wTransformationProgress = 2
		wFrameDuration = 0
		wWarioFramesetPtr = 0x7938 if wDirection != DIRECTION_LEFT else 0x7963
	_sfx_loop(0x0C)  # SFX_ROLL
	update_wario_animation_2()
	var b: int
	if wDirection == DIRECTION_LEFT:
		b = apply_walk_velocity_left()
		move_wario_left(b)
	else:
		b = apply_walk_velocity_right()
		move_wario_right(b)
	if wTransformationProgress < 3 and wWarioStateCounter < 0xF8:
		wWarioStateCounter = byte(wWarioStateCounter + b)
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if (check_front_collision() & 0x0F) != 0:
		set_state_snowball_crash()
		return
	if check_centre_collision() != 0:
		update_pos_y()
		return
	wWarioState = WST_SNOWBALL_AIRBORNE
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wJumpVelTable = JUMP_VEL_HIGH_JUMP


## UpdateState_SnowballAirborne: a transition, or water, first; a wall crashes it; the fall, rolling
## on (HandleWalk, below $18); on the ground, rolling again.
func update_state_snowball_airborne() -> void:
	if _snowman_left():
		return
	update_wario_animation_2()
	if (check_front_collision() & 0x0F) != 0:
		set_state_snowball_crash()
		return
	apply_jump_velocity()
	_walk_ahead()
	if wWalkVelIndex >= 0x18:
		wWalkVelIndex = 0x14
	if check_airborne_collision() == 0:
		trigger_downwards_floor_transition()
		return
	trigger_floor_transition()
	set_state_snowball_rolling()


## SetState_SnowballCrash: 2 px back, facing the other way; at the animation's end the snow flies
## (PARTICLE_SNOW) and he is himself again.
func set_state_snowball_crash() -> void:
	wTransformationProgress = 0
	wWarioState = WST_SNOWBALL_CRASH
	wDirection ^= 1
	if wDirection == DIRECTION_LEFT:
		move_wario_left(2)
	else:
		move_wario_right(2)
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x7981
	update_wario_animation_2()


# --- Fan Wario (wario_states_4.asm) -----------------------------------------------------------------

## SetState_FanStart (BlockFunc_AirCurrent): the tall box, in the air (table 1), the fan's graphics
## (the music not simulated).
func set_state_fan_start() -> void:
	wWarioState = WST_FAN_START
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelIndex = 0
	wJumpVelTable = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	load_wario_gfx(WARIO_FAN_GFX)
	set_wario_oam(OAM_1DC000)
	wWarioFramesetPtr = 0x43C3 if wDirection != DIRECTION_LEFT else 0x437F
	update_wario_animation_3()


## UpdateState_FanStart: the animation, then lifting.
func update_state_fan_start() -> void:
	probe_presence_top()
	_sfx_loop(0x0C)  # SFX_07D
	update_wario_animation_3()
	if wWarioAnimationEnded != 0:
		set_state_fan_lifting()


## SetState_FanLifting
func set_state_fan_lifting() -> void:
	wWalkVelIndex = 0
	wWarioState = WST_FAN_LIFTING
	wSFXLoopCounter = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x43B8 if wDirection != DIRECTION_LEFT else 0x4374
	update_wario_animation_3()


## UpdateStart_FanLifting: out of the current, recovering; in it, up a pixel (Func_1edf2b) and the
## pad steering (Func_1edf47).
func update_state_fan_lifting() -> void:
	probe_presence_top()
	if wIsInAirCurrent == 0:
		set_state_fan_recovering()
		return
	_sfx_loop(0x0C)
	update_wario_animation_3()
	_fan_lift()
	if wWarioState == WST_FAN_LIFTING:
		_fan_steer()


## Func_1edf2b: the current's presence 12 px above him; out of it, spinning; in it, a pixel up.
func _fan_lift() -> void:
	probe_presence_12()
	if wIsInAirCurrent == 0:
		set_state_fan_spinning()
	else:
		move_wario_up(1)


## Func_1edf47: the pad's other way turns him; its way moves him a pixel unless a wall is at his
## bottom corner (probed with the break flag).
func _fan_steer() -> void:
	if wDirection == DIRECTION_LEFT:
		if (wJoypadDown & PAD_RIGHT) != 0:
			set_state_fan_turning()
		elif (wJoypadDown & PAD_LEFT) != 0 and check_bottom_left_breaking() == 0:
			move_wario_left(1)
	else:
		if (wJoypadDown & PAD_LEFT) != 0:
			set_state_fan_turning()
		elif (wJoypadDown & PAD_RIGHT) != 0 and check_bottom_right_breaking() == 0:
			move_wario_right(1)


## SetState_FanTurning: facing the other way.
func set_state_fan_turning() -> void:
	wDirection ^= 1
	wWarioState = WST_FAN_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x4389 if wDirection != DIRECTION_LEFT else 0x438E
	update_wario_animation_3()


## UpdateStart_FanTurning: lifting as he turns; at the animation's end, lifting.
func update_state_fan_turning() -> void:
	_fan_lift()
	if wWarioState != WST_FAN_TURNING:
		return
	_sfx_loop(0x0C)
	update_wario_animation_3()
	if wWarioAnimationEnded != 0:
		set_state_fan_lifting()


## SetState_FanSpinning: at the current's top.
func set_state_fan_spinning() -> void:
	wWarioState = WST_FAN_SPINNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x4393
	update_wario_animation_3()


## UpdateState_FanSpinning: out of the current, recovering; in it, the pad steering.
func update_state_fan_spinning() -> void:
	probe_presence_top()
	if wIsInAirCurrent == 0:
		set_state_fan_recovering()
		return
	_sfx_loop(0x0C)
	update_wario_animation_3()
	_fan_steer()


## SetState_FanRecovering: the animation, then RecoverFromTransformation_WithoutInvincibility.
func set_state_fan_recovering() -> void:
	wWarioState = WST_FAN_RECOVERING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x43C8 if wDirection != DIRECTION_LEFT else 0x4384
	update_wario_animation_3()


# --- Magic Wario (wario_states_4.asm) ---------------------------------------------------------------

## SetState_MagicRising (ObjInteraction_MagicalSpiral): the spiral's two particles at Wario, the tall
## box, in the air (table 1), the magic palette and graphics (the music not simulated).
func set_state_magic_rising() -> void:
	get_pos()
	create_particle(PARTICLE_MAGIC_1)
	get_pos()
	create_particle(PARTICLE_MAGIC_2)
	wWarioState = WST_MAGIC_RISING
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelIndex = 0
	wJumpVelTable = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_MAGIC_PAL)
	load_wario_gfx(WARIO_MAGIC_GFX)
	set_wario_oam(OAM_1DCD60)
	wWarioFramesetPtr = 0x4FB0
	update_wario_animation_3()


## UpdateState_MagicRising: a pixel up a frame (a floor above starting a floor transition) until a
## ceiling stops him (PARTICLE_MAGIC_STOP; UpdateState_MagicStopping then waits $20 frames).
func update_state_magic_rising() -> void:
	probe_presence_top()
	if check_up_collision() != 0:
		get_pos()
		create_particle(PARTICLE_MAGIC_STOP)
		wWarioState = WST_MAGIC_STOPPING
		wWarioStateCounter = 0
		wFrameDuration = 0
		wAnimationFrame = 0
		update_wario_animation_3()
		return
	_sfx_loop(0x0C)  # SFX_07D
	update_wario_animation_3()
	move_wario_up(1)
	handle_upwards_floor_transition()


# --- Dragged down (wario_states_2.asm; the hand) ---------------------------------------------------

## SetState_DraggedDown (ObjInteraction_Hand): held by the hand (wAutoMoveState 1; the hand moves
## him), the airborne graphics, a box -27 to -1 by -9..9 (Frameset_15f70 left, _15f7f right).
func set_state_dragged_down() -> void:
	wWarioState = WST_DRAGGED_DOWN
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wAttackCounter = 0
	wGrabState = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wIsSmashAttacking = 0
	wIsCrouching = 0
	wIsRolling = 0
	wAutoMoveState = 1
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wCollisionBoxTop = byte(-27)
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5F7F if wDirection != DIRECTION_LEFT else 0x5F70
	update_wario_animation()


## UpdateState_DraggedDown: held until the hand lets go (wAutoMoveState 0); then falling
## (StartFall), or in The Temple ($c8) the game is over (wLevelEndScreen LVLEND_GAME_OVER).
func update_state_dragged_down() -> void:
	update_wario_animation()
	if wAutoMoveState != 0:
		return
	if wLevel == 0xC8:  # THE_TEMPLE
		wLevelEndScreen = LVLEND_GAME_OVER
		return
	start_fall()


# --- The hidden figure's defeat (wario_states_2.asm) ----------------------------------------------

## SetState_FenceShakeSliding (UpdateLevel in the Temple at wAutoMoveState 2: the hidden figure
## defeated): drawn idle (WarioIdleGfx, OAM_14a82), wAutoMoveState 3, Frameset_14d0b facing left,
## _14d10 facing right.
func set_state_fence_shake_sliding() -> void:
	wWarioState = WST_FENCE_SHAKE_SLIDING
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wAutoMoveState = 3
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14A82)
	wWarioFramesetPtr = FRAMESET_DOOR_ENTER_LEFT if wDirection == DIRECTION_LEFT else FRAMESET_DOOR_ENTER_RIGHT
	update_wario_animation()


## UpdateState_FenceShakeSliding: the animation; when it first ends, Frameset_14d15 from its start (the
## state's counter set); while in the air (wJumpVelTable) he falls until he lands.
func update_state_fence_shake_sliding() -> void:
	update_wario_animation()
	if wWarioStateCounter == 0 and wWarioAnimationEnded != 0:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_DOOR_THROUGH
		update_wario_animation()
		wWarioStateCounter = byte(wWarioStateCounter + 1)
	if wJumpVelTable == 0:
		return
	apply_jump_velocity()
	if check_airborne_collision() == 0:
		return
	update_pos_y()
	wJumpVelTable = 0
	wJumpVelIndex = 0


# --- Launched (wario_states_4.asm; the Big Octohon) ------------------------------------------------

## SetState_Launched (OBJ_INTERACTION_49): launched the way he faces, tangible, a lasting
## transformation that vanishes touches and stings ($02 in wca94), a box -15 to -1 by -9..9, the
## default palette and WarioLaunchGfx (Frameset_1dc904 left, _1dc8fb right).
func set_state_launched() -> void:
	wIsIntangible = 0
	wTransformation = TRANSFORMATION_LAUNCHED
	wTouchState = TOUCH_VANISH
	wStingTouchState = TOUCH_VANISH
	wca94 = 2
	wWarioState = WST_LAUNCHED
	wSFXLoopCounter = 0
	wWalkVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-15)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_LAUNCH_GFX)
	set_wario_oam(OAM_1DC449)
	wWarioFramesetPtr = 0x48FB if wDirection != DIRECTION_LEFT else 0x4904
	update_wario_animation_3()


## UpdateState_Launched: his presence on top first (Func_19b25; a room transition goes); the SFX
## loop ($86; SFX_04C not simulated); 2 px a frame his way until a wall in front
## (CheckFrontCollision) crashes him (WST_LAUCH_CRASH, Frameset_1dc926 left, _1dc90d right;
## SFX_048 not simulated). The crash's end puts him back to normal under water (Func_2ad6a).
func update_state_launched() -> void:
	probe_presence_top()
	if wRoomTransitionParam != 0:
		trigger_room_transition()
		return
	_sfx_loop(0x86)
	update_wario_animation_3()
	if check_front_collision() == 0:
		if wDirection == DIRECTION_LEFT:
			move_wario_left(2)
		else:
			move_wario_right(2)
		return
	wWarioState = WST_LAUCH_CRASH
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x490D if wDirection != DIRECTION_LEFT else 0x4926
	update_wario_animation_3()


# --- Wario as a ball (wario_states_4.asm; the Shoot minigame) -------------------------------------

## SetState_BallStart (ObjInteraction_Shoot from below): a ball (box top -20), its palette and
## graphics; in the air it first falls (UpdateState_BallStart), on the ground it bounces at once
## (the music not simulated).
func set_state_ball_start() -> void:
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-20)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wGrabState = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	set_wario_pal(WARIO_BALL_PAL)
	load_wario_gfx(WARIO_BALL_GFX)
	set_wario_oam(OAM_1DCFF1)
	if wJumpVelTable == 0:
		_ball_land(false)
		return
	wWarioState = WST_BALL_START
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x5313
	update_wario_animation_3()


## Func_1edaca (`bounce` false) and Func_1edaf8 (true, after a bounce): the pad's other way turns
## the ball; otherwise it bounces (Func_1edd24).
func _ball_land(bounce: bool) -> void:
	if wDirection == DIRECTION_LEFT:
		if (wJoypadDown & PAD_RIGHT) != 0:
			set_state_ball_turning()
			return
		wWarioFramesetPtr = 0x5230 if bounce else 0x5316
	else:
		if (wJoypadDown & PAD_LEFT) != 0:
			set_state_ball_turning()
			return
		wWarioFramesetPtr = 0x5295 if bounce else 0x5323
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wWarioState = WST_BALL_BOUNCING
	wFrameDuration = 0
	wAnimationFrame = 0
	update_wario_animation_3()


## SetState_BallAirborne (SFX_066): up on the knock-back table.
func set_state_ball_airborne() -> void:
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wWarioState = WST_BALL_AIRBORNE
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x52F6 if wDirection != DIRECTION_LEFT else 0x52F3
	update_wario_animation_3()


## UpdateState_BallAirborne: along the jump the way it faces (Func_1ee02e, the walk index below 8);
## falling onto the ground, another bounce.
func update_state_ball_airborne() -> void:
	update_wario_animation_3()
	apply_jump_velocity()
	_walk_ahead()
	if wWalkVelIndex >= 8:
		wWalkVelIndex = 4
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX or check_airborne_collision() == 0:
		return
	update_pos_y()
	_ball_land(true)


## SetState_BallTurning: the other way, then up again.
func set_state_ball_turning() -> void:
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wWarioState = WST_BALL_TURNING
	wFrameDuration = 0
	wAnimationFrame = 0
	wDirection ^= 1
	wWarioFramesetPtr = 0x5287 if wDirection != DIRECTION_LEFT else 0x528E
	update_wario_animation_3()


## SetState_BallShot (the ball meets the shooter or the goalkeeper): intangible, its moves driven
## by wAutoMoveState (set by the minigame's objects).
func set_state_ball_shot() -> void:
	wWarioState = WST_BALL_SHOT
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelTable = 0
	wJumpVelIndex = 0
	wAutoMoveState = 1
	wIsIntangible = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x526C
	update_wario_animation_3()


## UpdateState_BallShot: wAutoMoveState 0 throws the ball (left, the high jump's table from 6);
## with bit 7 set, a new phase: 1 still (the ball's palette), 2 its frameset Frameset_1dd2d1, 3 shot
## (WarioBallShotPal); phase 2's animation end asks for phase 3.
func update_state_ball_shot() -> void:
	var a: int = wAutoMoveState
	if a == 0:
		wDirection = DIRECTION_LEFT
		wWarioState = WST_BALL_THROWN
		wSFXLoopCounter = 0
		wWarioStateCounter = 0
		wWarioStateCycles = 0
		wJumpVelIndex = 6
		wJumpVelTable = JUMP_VEL_HIGH_JUMP
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = 0x52EE
		update_wario_animation_3()
		return
	if (a & 0x80) != 0:
		a &= 0x7F
		wAutoMoveState = a
		match a:
			1:
				set_wario_pal(WARIO_BALL_PAL)
				wWarioFramesetPtr = 0x526C
			2:
				wWarioFramesetPtr = 0x52D1
			3:
				set_wario_pal(WARIO_BALL_SHOT_PAL)
				wWarioFramesetPtr = 0x527A
			_:
				return
		wFrameDuration = 0
		wAnimationFrame = 0
	update_wario_animation_3()
	if wAutoMoveState == 2 and wWarioAnimationEnded != 0:
		wAutoMoveState = 0x83


## UpdateState_BallThrown: left, 3 px a frame rising and 2 falling; landing ends it, stung out of
## the ball (Func_206eb), unless three goals are scored: then sent up (SFX_066).
func update_state_ball_thrown() -> void:
	update_wario_animation_3()
	apply_jump_velocity()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		move_wario_left(3)
		return
	move_wario_left(2)
	if check_airborne_collision() == 0:
		return
	update_pos_y()
	wIsIntangible = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	if wShootGoals != 3:
		sting_out_of_transformation()
		return
	wWarioState = WST_BALL_SENT_UPWARDS
	wSFXLoopCounter = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wJumpVelIndex = 0
	wIsIntangible = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioFramesetPtr = 0x52EE
	update_wario_animation_3()


## UpdateState_BallSentUpwards: 3 px up a frame to a ceiling (a floor above starting a floor
## transition), then falling on the normal table; landing ends it as a sting does (Func_206eb).
func update_state_ball_sent_upwards() -> void:
	update_wario_animation_3()
	if wJumpVelIndex < FALLING_JUMP_VEL_INDEX:
		move_wario_up(3)
		if check_up_collision() == 0:
			handle_upwards_floor_transition()
		else:
			wJumpVelIndex = FALLING_JUMP_VEL_INDEX
			wJumpVelTable = JUMP_VEL_NORMAL
		return
	apply_jump_velocity()
	if check_airborne_collision() == 0:
		return
	update_pos_y()
	wIsIntangible = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	sting_out_of_transformation()
