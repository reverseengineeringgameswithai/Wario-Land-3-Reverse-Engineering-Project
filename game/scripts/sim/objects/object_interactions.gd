class_name ObjectInteractions
extends HiddenFigureFunctions
## ProcessInteractions and the interactions the port implements, by translation from
## src/engine/level/object_interactions.asm: Wario's collision box against each visible object's
## on screen, the side they meet on, and the object's interaction type deciding what happens to
## both (bumps, attacks, stepping on, stings, collecting). The first object that meets Wario ends
## the pass unless its handler continues it, as in the original's `jumptable`. Types not ported
## are named in `unported`. Sound effects and particles (the attack's stars) are not game state
## here and are left out.
## Research note: docs/02-research/objects.md.

const OBJACTION_BUMP: int = 1
const OBJACTION_ATTACK: int = 2
const OBJACTION_WOBBLE: int = 4
const OBJACTION_VANISH_TOUCH: int = 5
const OBJACTION_06: int = 6
const OBJACTION_07: int = 7
const OBJACTION_0E: int = 0x0E
const OBJACTION_TELEPORT: int = 0x10
const OBJACTION_13: int = 0x13
const OBJACTION_NONE: int = 0x00
const OBJACTION_12: int = 0x12
const OBJACTION_0C: int = 0x0C
const OBJACTION_0D: int = 0x0D
const OBJACTION_0A: int = 0x0A
const OBJACTION_PICK_UP: int = 3
const OBJACTION_FLATTEN: int = 0x0B
const OBJACTION_SMASH_ATTACK_WALKABLE: int = 0x0F
const GREY_TREASURE_FLAG: int = 1 << 4  # GREY_TREASURE_F in wKeyAndTreasureFlags
const LVLEND_GREY_TREASURE: int = 0x01
const LVLEND_NO_TREASURE: int = 0x05
const OBJACTION_VANISH_TREASURE: int = 8
const ST_LEVEL: int = 0x02
const ST_COLLECT_KEY: int = 0x08
const NUM_LEVEL_MUSICAL_COINS: int = 8
const FRAMESET_ENEMY_BUMP_LEFT: int = 0x4A71  # Frameset_14a71
const FRAMESET_ENEMY_BUMP_RIGHT: int = 0x4A6C  # Frameset_14a6c
const FRAMESET_STEP_BOUNCE_LEFT: int = 0x4A79  # Frameset_14a79
const FRAMESET_STEP_BOUNCE_RIGHT: int = 0x4A76  # Frameset_14a76

# Interaction scratch (WRAM0 $c1b6-$c1c6).
var wObjPtr: int = 0  # the slot being checked
var wUnused_c1b8: int = 0
var wObjInteractionType: int = 0
var wObjCollBoxTop: int = 0
var wObjCollBoxBottom: int = 0
var wObjCollBoxLeft: int = 0
var wObjCollBoxRight: int = 0
var wObjScreenYPos: int = 0
var wObjScreenXPos: int = 0
var wInteractionSide: int = 0
var wc1c1: int = 0
var wc1c2: int = 0
var wc1c3: int = 0
var wc1c4: int = 0
## Set by a handler that continues the pass (`jp ProcessInteractions.next_obj`).
var _next_object: bool = false


## ProcessInteractions: nothing while Wario is intangible, a floor transition runs, or he moves on
## his own; otherwise the first active, on-screen object without a pending action whose box meets
## his gets its interaction.
func process_interactions() -> void:
	if wIsIntangible != 0 or wIsFloorTransition != 0 or wAutoMoveState != 0:
		return
	wIsOnSteppableObject = 0
	for slot: int in NUM_OBJECTS:
		wObjPtr = slot
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if (wram1[base + OBJ_FLAGS] & (OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN)) != (OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN):
			continue
		wUnused_c1b8 = wram1[base + OBJ_UNK_1D]
		if wram1[base + OBJ_ACTION] != 0:
			continue
		wObjInteractionType = wram1[base + OBJ_INTERACTION_TYPE]
		wObjCollBoxTop = wram1[base + OBJ_COLLBOX_TOP]
		wObjCollBoxBottom = wram1[base + OBJ_COLLBOX_BOTTOM]
		wObjCollBoxLeft = wram1[base + OBJ_COLLBOX_LEFT]
		wObjCollBoxRight = wram1[base + OBJ_COLLBOX_RIGHT]
		wObjScreenYPos = wram1[base + OBJ_SCREEN_Y_POS]
		wObjScreenXPos = wram1[base + OBJ_SCREEN_X_POS]
		wObjDirection = DIRECTION_RIGHT if (wram1[base + OBJ_SUBSTATE] & OBJSUBFLAG_HDIR) != 0 else DIRECTION_LEFT
		wInteractionSide = 0
		wc1c1 = 0xFF
		wc1c2 = 0xFF
		wc1c3 = 0xFF
		wc1c4 = 0xFF
		if not _overlap():
			continue
		_set_interaction_side()
		_next_object = false
		run_interaction(wObjInteractionType & INTERACTION_MASK)
		if not _next_object:
			return


## The boxes' overlap in screen coordinates (offset by $d0 so the bytes don't wrap), keeping the
## depth on each side in wc1c1-wc1c4. False when they do not meet.
func _overlap() -> bool:
	var e: int = 0xD0
	var b: int = byte(wObjScreenYPos + wObjCollBoxTop - e)
	var a: int = byte(wWarioScreenYPos + wCollisionBoxBottom - e)
	if a < b:
		return false
	var c: int = a - b
	b = byte(wWarioScreenYPos + wCollisionBoxTop - e)
	a = byte(wObjScreenYPos + wObjCollBoxBottom - e)
	if a < b:
		return false
	var d: int = a - b
	if d < c:
		wc1c2 = d
	elif d == c:
		wc1c1 = c
		wc1c2 = d
	else:
		wc1c1 = c
	b = byte(wObjScreenXPos + wObjCollBoxLeft - e)
	a = byte(wWarioScreenXPos + wCollisionBoxRight - e)
	if a < b:
		return false
	c = a - b
	b = byte(wWarioScreenXPos + wCollisionBoxLeft - e)
	a = byte(wObjScreenXPos + wObjCollBoxRight - e)
	if a < b:
		return false
	d = a - b
	if d < c:
		wc1c4 = d
	elif d == c:
		wc1c3 = c
		wc1c4 = d
	else:
		wc1c3 = c
	return true


## The side with the shallowest overlap: horizontal (LEFT/RIGHT) or vertical (UP/DOWN), and which.
func _set_interaction_side() -> void:
	var side: int = INTERACTION_LEFT | INTERACTION_RIGHT | INTERACTION_UP | INTERACTION_DOWN
	var b: int = wc1c4
	var c: int = wc1c3
	if c != b:
		if c < b:
			side &= ~INTERACTION_LEFT
			b = c
		else:
			side &= ~INTERACTION_RIGHT
	var d: int = wc1c2
	var e: int = wc1c1
	if e != d:
		if e < d:
			side &= ~INTERACTION_DOWN
			d = e
		else:
			side &= ~INTERACTION_UP
	if b != d:
		if b < d:
			side &= ~(INTERACTION_UP | INTERACTION_DOWN)
		else:
			side &= ~(INTERACTION_LEFT | INTERACTION_RIGHT)
	wInteractionSide = side & 0xFF


## The interaction table (`.table`): the ported handlers, the rest named.
func run_interaction(kind: int) -> void:
	match kind:
		0x00:
			_interaction_00()
		0x01:
			_touch_object()
		0x02:  # OBJ_INTERACTION_FRONT_STING
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif _sting_side_hit(INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT):
				sting_wario()
			else:
				_touch_object()
		0x03:  # OBJ_INTERACTION_BACK_STING
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif _sting_side_hit(INTERACTION_RIGHT if wObjDirection == DIRECTION_RIGHT else INTERACTION_LEFT):
				sting_wario()
			else:
				_touch_object()
		0x04:  # OBJ_INTERACTION_TOP_STING
			if (wInteractionSide & INTERACTION_UP) != 0:
				sting_wario()
			elif (wInteractionSide & INTERACTION_DOWN) != 0:
				step_on_object()
			else:
				_touch_object()
		0x05:  # OBJ_INTERACTION_FULL_STING
			sting_wario()
		0x06:  # OBJ_INTERACTION_06 (Func_20d81): from above or below Func_20899, otherwise Func_208f2
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				_touch_object_swimming()
			else:
				_bump_object_swimming()
		0x0A:  # OBJ_INTERACTION_0A (Func_20e60)
			_bounce_off_object()
		0x0B:  # OBJ_INTERACTION_0B
			_bounce_off_object_0b()
		0x0C:  # OBJ_INTERACTION_WALKABLE
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_or_smash_object()
			elif wAttackCounter != 0:
				attack_object()
			else:
				_bounce_off_object()
		0x20:  # OBJ_INTERACTION_BOUNCY: stepped on from above or below; met head on, Bouncy Wario
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif (wInteractionSide & (INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT)) != 0:
				_make_wario_bouncy()
			else:
				_touch_object()
		0x21:  # OBJ_INTERACTION_FIRE_BOT: stepped on from above or below; met head on, fire
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif (wInteractionSide & (INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT)) != 0:
				_set_wario_on_fire()
			else:
				_touch_object()
		0x1F:  # OBJ_INTERACTION_ZOMBIE_HEAD
			_zombie_head_interaction()
		0x24:  # OBJ_INTERACTION_ORANGE_BIRD: stepped on from above or below; met head on, Crazy Wario
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif (wInteractionSide & (INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT)) != 0:
				_make_wario_crazy()
			else:
				_touch_object()
		0x28:  # OBJ_INTERACTION_OWL: from below Wario grabs it (Owl Wario); otherwise he bounces off
			# (Func_20939)
			if (wInteractionSide & INTERACTION_DOWN) == 0:
				_bounce_off_object()
			elif (wTransformation & TRANSFORMATIONF_PERSISTENT) == 0 and wTransformation != TRANSFORMATION_OWL_WARIO:
				set_obj_action(OBJACTION_07)  # Func_20a63 (SFX_HANG_GRAB)
				wTransformation = TRANSFORMATION_OWL_WARIO
				wTouchState = TOUCH_BUMP
				wStingTouchState = TOUCH_VULNERABLE
				wca94 = 1
				set_state_grabbing_owl()
		0x3D:  # OBJ_INTERACTION_HEBARII: bounced off (Func_20e6a), or attacked from the side
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) == 0 and wAttackCounter != 0:
				attack_object()
			else:
				_bounce_off_object_0b()
		0x22:  # OBJ_INTERACTION_SOLID
			_solid_interaction(false)
		0x23:  # OBJ_INTERACTION_OMODON
			_solid_interaction(true)
		0x2F:  # OBJ_INTERACTION_STOVE
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_or_smash_object()
			elif (wInteractionSide & INTERACTION_DOWN) != 0:
				_hit_object_from_below()
			else:
				if wAttackCounter != 0:
					set_obj_action(OBJACTION_ATTACK)
				_push_out_of_object()
		0x3B:  # OBJ_INTERACTION_3B (Func_21c56): from above as on a walkable object, otherwise $00
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_or_smash_object()
			else:
				_interaction_00()
		0x38:  # OBJ_INTERACTION_TERUTERU
			_teruteru_interaction()
		0x1E:  # OBJ_INTERACTION_PNEUMO: from below as Yellow Belly's arrow, otherwise touched
			if (wInteractionSide & INTERACTION_DOWN) != 0:
				_puffy_interaction()
			else:
				_touch_object()
		0x37:  # OBJ_INTERACTION_YELLOW_BELLY_ARROW
			_puffy_interaction()
		0x35:  # OBJ_INTERACTION_BEAM
			_beam_interaction()
		0x25:  # OBJ_INTERACTION_VAMPIRE
			_vampire_interaction()
		0x26:  # OBJ_INTERACTION_BUBBLE
			_bubble_interaction()
		0x2D:  # OBJ_INTERACTION_SNOW
			_snow_interaction()
		0x4D:  # OBJ_INTERACTION_SHOOT
			_shoot_interaction()
		0x0F:  # OBJ_INTERACTION_RICHTERTOFFEN
			_richtertoffen_interaction()
		0x2A:  # OBJ_INTERACTION_HARIDAMA: from below as swimming; from above, or from in front of
			# it, Func_207ed; otherwise Func_208f2
			if (wInteractionSide & INTERACTION_DOWN) != 0:
				_touch_object_swimming()
			elif (wInteractionSide & INTERACTION_UP) != 0 \
					or (wInteractionSide & (INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT)) != 0:
				_haridama_sting()
			else:
				_bump_object_swimming()
		0x31:  # OBJ_INTERACTION_31 (Func_21af1): from above Wario stands on it, from below steps
			# on it; from the side an attack bumps him back, otherwise he is pushed out
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_object()
			elif (wInteractionSide & INTERACTION_DOWN) != 0:
				step_on_object()
			elif wAttackCounter != 0:
				do_jumping_bump()
			else:
				_push_out_of_object()
		0x32:  # OBJ_INTERACTION_DOLL_BOY_HAMMER: Bouncy Wario (Func_2160a)
			_make_wario_bouncy()
		0x33:  # OBJ_INTERACTION_ROLLING_ROCK
			_rolling_rock_interaction()
		0x34:  # OBJ_INTERACTION_WORMWOULD: stepped on from above or below; attacked; otherwise
			# bounced off (Func_21b3a)
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				step_on_object()
			elif wAttackCounter != 0:
				attack_object()
			else:
				_bounce_off_object_none()
		0x36:  # OBJ_INTERACTION_36 (Func_21b78): a smash attack from above; otherwise bounced off
			if (wInteractionSide & INTERACTION_UP) != 0 and wIsSmashAttacking != 0:
				_smash_attack_object()
			else:
				_bounce_off_object()
		0x39:  # OBJ_INTERACTION_WATER_DROP: it reacts; a transformation ends
			set_obj_action(OBJACTION_06)
			if wTransformation == 0:
				_next_object = true
			else:
				recover_from_transformation()
		0x2E:  # OBJ_INTERACTION_UNLIT_TORCH: Hot Wario lights it (OBJACTION_0E)
			if wTransformation == TRANSFORMATION_HOT_WARIO:
				set_obj_action(OBJACTION_0E)
		0x3F:  # OBJ_INTERACTION_HAND: unless invincible or transformed, dragged down
			# (SetState_DraggedDown; SFX_FAT_WALK not simulated), the hand taking OBJACTION_13 (Func_21cc9)
			if wInvincibleCounter == 0 and wTransformation == 0:
				set_state_dragged_down()
				set_obj_action(OBJACTION_13)
		0x3E:  # OBJ_INTERACTION_PRINCE_FROGGY: from above Wario stands on it; from below hits it
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_object()
			elif (wInteractionSide & INTERACTION_DOWN) != 0:
				_hit_object_from_below()
			else:
				_prince_froggy_side()
		0x42:  # OBJ_INTERACTION_INK
			set_obj_action(OBJACTION_06)
		0x45:  # OBJ_INTERACTION_TURTLE: from above Wario stands on it; untransformed, in water he
			# dives, otherwise bounces off (Func_21b3a)
			if (wInteractionSide & INTERACTION_UP) != 0:
				_stand_on_object()
			elif wTransformation == 0:
				if wWaterInteraction == 0:
					_bounce_off_object_none()
				else:
					start_dive()
		0x4C:  # OBJ_INTERACTION_BOTTOM_STING: stung from below, stepped on from above, else touched
			if (wInteractionSide & INTERACTION_DOWN) != 0:
				sting_wario()
			elif (wInteractionSide & INTERACTION_UP) != 0:
				step_on_object()
			else:
				_touch_object()
		0x4E:  # OBJ_INTERACTION_GK_TORTOISE (Func_21e9c): the ball is shot; otherwise bounced off
			if wTransformation == TRANSFORMATION_BALL:
				_ball_shot()
			else:
				_bounce_off_object()
		0x4B:  # OBJ_INTERACTION_MAGICAL_SPIRAL: unless invincible, Magic Wario (touches and stings
			# pass through); in a lasting transformation only touched
			if wInvincibleCounter == 0:
				if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
					_touch_object()
				else:
					set_obj_action(OBJACTION_06)
					wTransformation = TRANSFORMATION_MAGIC
					wTouchState = TOUCH_PASS_THROUGH
					wStingTouchState = TOUCH_PASS_THROUGH
					wca94 = 2
					set_state_magic_rising()
		0x44:  # OBJ_INTERACTION_JAMANO: stung out of any transformation (Func_206eb) and teleported
			wRoomTransitionParam = (ROOMTRANSITION_TELEPORT | ROOMTRANSITIONF_DOOR | ROOMTRANSITIONF_RELOAD_OBJECTS
					| ROOMTRANSITIONF_DELAY)
			sting_out_of_transformation()
			wWarioState = WST_TELEPORTING
			set_obj_action(OBJACTION_TELEPORT)
		0x40:  # OBJ_INTERACTION_WATER_TELEPORTING
			_water_teleport()
		0x49:  # OBJ_INTERACTION_49 (Func_21d88): from above or below Func_20899; on the side it faces
			# (right when it faces left) Func_21dac, launching him; otherwise Func_208f2
			if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
				_touch_object_swimming()
			elif (wInteractionSide & (INTERACTION_RIGHT if wObjDirection == DIRECTION_LEFT else INTERACTION_LEFT)) != 0:
				_launched_by_object()
			else:
				_bump_object_swimming()
		0x41:  # OBJ_INTERACTION_SCOWLER: from above Func_20899, from below a water teleport,
			# otherwise Func_208f2
			if (wInteractionSide & INTERACTION_UP) != 0:
				_touch_object_swimming()
			elif (wInteractionSide & INTERACTION_DOWN) != 0:
				_water_teleport()
			else:
				_bump_object_swimming()
		0x1D:  # OBJ_INTERACTION_INVISIBILITY_POTION: taken (Func_20a63); unless invincible, already
			# invisible, or in a lasting transformation, Wario turns invisible
			set_obj_action(OBJACTION_07)
			if wInvincibleCounter == 0 and (wTransformation & TRANSFORMATIONF_PERSISTENT) == 0 \
					and wTransformation != TRANSFORMATION_INVISIBLE_WARIO:
				set_state_turning_invisible()
		0x30, 0x3C:  # OBJ_INTERACTION_ROBO_MOUSE, OBJ_INTERACTION_TADPOLE
			_tadpole_interaction()
		0x0D:  # OBJ_INTERACTION_MUSICAL_COIN
			_collect_musical_coin()
		0x0E:  # OBJ_INTERACTION_FIRE
			_set_wario_on_fire()
		0x10, 0x11, 0x12, 0x13:  # OBJ_INTERACTION_GREY_KEY, RED, GREEN, BLUE
			_collect_key(kind - 0x10)
		0x14, 0x15, 0x16, 0x17:  # OBJ_INTERACTION_GREY_TREASURE, RED, GREEN, BLUE
			_treasure_interaction(kind - 0x14)
		0x18:  # OBJ_INTERACTION_OMODONMEKA
			_omodonmeka_interaction()
		0x19:  # OBJ_INTERACTION_SILKY
			_silky_interaction()
		0x1A:  # OBJ_INTERACTION_FOOD
			_eat_food()
		0x1B:  # OBJ_INTERACTION_REGULAR_COIN
			_collect_coin()
		0x4A:  # OBJ_INTERACTION_COLOUR_COIN
			_collect_ten_coins()
		0x1C:  # OBJ_INTERACTION_ELECTRIC
			_electrify_wario()
		0x29:  # OBJ_INTERACTION_RAIL
			_grab_rail()
		0x27:  # OBJ_INTERACTION_ICE
			_freeze_wario()
		0x4F:  # OBJ_INTERACTION_4F (Func_21ea6, the hidden figure's hands): met on the side it faces,
			# Wario turns from it and is pushed out (Func_20a6f); otherwise bounced off (Func_21b3a)
			if _met_on_facing_side():
				wDirection = wObjDirection ^ 1
				_push_out_of_object()
			else:
				_bounce_off_object_none()
		0x50:  # OBJ_INTERACTION_50 (Func_21ecd): met on the side it faces, dragged down
			# (SetState_DraggedDown; SFX_FAT_WALK not simulated), it taking OBJACTION_13 (Func_21cc9);
			# otherwise bounced off (Func_20e6a)
			if _met_on_facing_side():
				set_state_dragged_down()
				set_obj_action(OBJACTION_13)
			else:
				_bounce_off_object_0b()
		0x52:  # OBJ_INTERACTION_52 (Func_21f28): from above a smash attack (Func_20602) or a bounce
			# (Func_21d6f.asm_21d7e); from below a bounce; on the side it faces a sting (Func_20670)
			if (wInteractionSide & INTERACTION_UP) != 0:
				if wIsSmashAttacking != 0:
					_smash_attack_object()
				else:
					_bounce_off_object_0b()
			elif (wInteractionSide & INTERACTION_DOWN) == 0 and _met_on_facing_side():
				sting_wario()
			else:
				_bounce_off_object_0b()
		0x53, 0x54, 0x55, 0x56, 0x57, 0x58:  # ObjInteraction_None
			pass
		_:
			note_unported("ObjInteraction $%02x" % kind)


func _sting_side_hit(side: int) -> bool:
	return (wInteractionSide & side) != 0


## Whether Wario met the object on the side it faces: its right facing left, its left facing right.
func _met_on_facing_side() -> bool:
	return _sting_side_hit(INTERACTION_RIGHT if wObjDirection == DIRECTION_LEFT else INTERACTION_LEFT)


## Func_20899: touched while swimming. With a sting-touch state other than a bump, only a
## vanishing touch does anything; otherwise, in water, the object wobbles away and an
## untransformed Wario, unless it was from above, dives (SFX_014 not simulated).
func _touch_object_swimming() -> void:
	if wStingTouchState != 0 and wStingTouchState != TOUCH_BUMP:
		if wStingTouchState == TOUCH_VANISH:
			set_obj_action(OBJACTION_VANISH_TOUCH)
		return
	if wWaterInteraction == 0:
		return
	wInteractionSide |= INTERACTION_LEFT if wObjScreenXPos < wWarioScreenXPos else INTERACTION_RIGHT
	set_obj_action(OBJACTION_WOBBLE)
	if wTransformation != 0 or (wInteractionSide & INTERACTION_UP) != 0:
		return
	start_dive()


## Func_2160a: unless invincible, the object reacts; in a lasting transformation or bouncy already,
## Wario is only touched; otherwise Bouncy Wario for 900 frames (SetState_BouncyStart).
func _make_wario_bouncy() -> void:
	if wInvincibleCounter != 0:
		return
	set_obj_action(OBJACTION_06)
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_BOUNCY_WARIO:
		_touch_object()
		return
	wTransformation = TRANSFORMATION_BOUNCY_WARIO
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 1
	wTransformationDuration = BOUNCY_WARIO_DURATION
	set_state_bouncy_start()


## ObjInteraction_OrangeBird's head-on part: unless invincible; in a lasting transformation or crazy
## already, only touched; otherwise Crazy Wario (touches attack), spinning.
func _make_wario_crazy() -> void:
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_CRAZY_WARIO:
		_touch_object()
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_CRAZY_WARIO
	wTouchState = TOUCH_ATTACK
	wStingTouchState = TOUCH_ATTACK
	wca94 = 1
	set_state_crazy_spinning()


## ObjInteraction_ZombieHead: invincible or in another lasting transformation, it only reacts
## (Func_20a69, OBJACTION_0D); Zombie Wario makes it vanish; otherwise Wario becomes Zombie Wario
## (his touches make objects vanish; SFX_028 not simulated).
func _zombie_head_interaction() -> void:
	if wInvincibleCounter != 0:
		set_obj_action(OBJACTION_0D)
		return
	if wTransformation == TRANSFORMATION_ZOMBIE_WARIO:
		_vanish_object_and_knock_back_if_zombie()
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		set_obj_action(OBJACTION_0D)
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_ZOMBIE_WARIO
	wTouchState = TOUCH_VANISH
	wStingTouchState = TOUCH_VANISH
	wca94 = 2
	set_state_zombie_idling()


## ObjInteraction_Teruteru: only from below (otherwise Func_2022c), unless invincible; in another
## lasting transformation he is only touched; otherwise Blind Wario (bumping touches, vulnerable
## to stings). Blacking out BG palettes 0-3 and OBJ palettes 3-4 is presentation, not simulated.
func _teruteru_interaction() -> void:
	if (wInteractionSide & INTERACTION_DOWN) == 0:
		_touch_object()
		return
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		_touch_object()
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_BLIND
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_VULNERABLE
	wca94 = 1
	set_state_blind_idling()


## ObjInteraction_WaterTeleporting: water stung, then teleported once that has run.
func _water_teleport() -> void:
	wRoomTransitionParam = (ROOMTRANSITION_TELEPORT | ROOMTRANSITIONF_DOOR | ROOMTRANSITIONF_RELOAD_OBJECTS
			| ROOMTRANSITIONF_DELAY)
	set_state_water_stung()
	wWarioState = WST_WATER_TELEPORTING
	set_obj_action(OBJACTION_TELEPORT)


## ObjInteraction_Richtertoffen: from above a smash attack (Func_20602) or a step; from below,
## unless invincible (in a lasting transformation only touched), it flattens Wario where his
## widened box (-11 to 11) fits between walls and no ladder is under him, otherwise he steps on it;
## from the side an attack (Func_20932) or a bounce.
func _richtertoffen_interaction() -> void:
	if (wInteractionSide & INTERACTION_UP) != 0:
		if wIsSmashAttacking == 1:
			_smash_attack_object()
		else:
			step_on_object()
	elif (wInteractionSide & INTERACTION_DOWN) != 0:
		if wInvincibleCounter != 0:
			return
		if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
			_touch_object()
			return
		wCollisionBoxLeft = byte(-11)
		wCollisionBoxRight = 11
		if wLadderInteraction != LADDER_UNDERNEATH and check_bottom_left_breaking() == 0 \
				and check_bottom_right_breaking() == 0:
			set_obj_action(OBJACTION_FLATTEN)
			var base: int = W_OBJECTS + wObjPtr * OBJ_STRUCT_LENGTH
			set_state_flat_airborne(wram1[base + OBJ_X_POS] | (wram1[base + OBJ_X_POS + 1] << 8), true)
			return
		wCollisionBoxLeft = byte(-9)
		wCollisionBoxRight = 9
		step_on_object()
	elif wAttackCounter != 0:
		attack_object()
	else:
		_bounce_off_object()


## Func_207ed: in water, unless invincible: with no sting-touch state the object reacts and Wario is
## water stung; a bump is Func_208f2's; a vanishing touch makes it vanish.
func _haridama_sting() -> void:
	if wInvincibleCounter != 0 or wWaterInteraction == 0:
		return
	match wStingTouchState:
		0:
			set_obj_action(OBJACTION_06)
			set_state_water_stung()
		TOUCH_BUMP:
			_bump_object_swimming()
		TOUCH_VANISH:
			set_obj_action(OBJACTION_VANISH_TOUCH)


## Func_20b41: by the touch state: none, a bounce and OBJACTION_12; an attack; a vanishing touch;
## otherwise pushed out (Func_20a6f).
func _prince_froggy_side() -> void:
	match wTouchState:
		0:
			_bounce_off_object()
			if _next_object:
				note_unported("Func_20b41 after ProcessInteractions.next_obj")
				return
			set_obj_action(OBJACTION_12)
		TOUCH_ATTACK:
			attack_object()
		TOUCH_VANISH:
			_vanish_object_and_knock_back_if_zombie()
		_:
			_push_out_of_object()


## Func_21b3a: a bounce (Func_20939), then OBJACTION_NONE.
func _bounce_off_object_none() -> void:
	_bounce_off_object()
	if _next_object:
		note_unported("Func_21b3a after ProcessInteractions.next_obj")
		return
	set_obj_action(OBJACTION_NONE)


## ObjInteraction_Shoot: the ball is shot (Func_21e8a); from below, unless invincible (in a lasting
## transformation only touched), Wario becomes the ball (touches and stings pass through); from
## above he steps on it; otherwise attacked or bounced off (Func_20e63).
func _shoot_interaction() -> void:
	if wTransformation == TRANSFORMATION_BALL:
		_ball_shot()
	elif (wInteractionSide & INTERACTION_DOWN) != 0:
		if wInvincibleCounter != 0:
			return
		if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
			_touch_object()
			return
		set_obj_action(OBJACTION_06)
		wTransformation = TRANSFORMATION_BALL
		wTouchState = TOUCH_PASS_THROUGH
		wStingTouchState = TOUCH_PASS_THROUGH
		wca94 = 2
		set_state_ball_start()
	elif (wInteractionSide & INTERACTION_UP) != 0:
		step_on_object()
	elif wAttackCounter != 0:
		attack_object()
	else:
		_bounce_off_object_0b()


## Func_21e8a: SetState_BallShot, the object taking OBJACTION_13 (Func_21cc9).
func _ball_shot() -> void:
	set_state_ball_shot()
	set_obj_action(OBJACTION_13)


## ObjInteraction_Snow: invincible or in a lasting transformation, it only reacts (Func_20a69);
## otherwise Snowman Wario (touches and stings attack; the object takes OBJACTION_07).
func _snow_interaction() -> void:
	if wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		set_obj_action(OBJACTION_0D)  # Func_20a69
		return
	set_obj_action(OBJACTION_07)
	wTransformation = TRANSFORMATION_SNOWMAN_WARIO
	wTransformationProgress = 0
	wTouchState = TOUCH_ATTACK
	wStingTouchState = TOUCH_ATTACK
	wca94 = 2
	set_state_turning_into_snowman()


## ObjInteraction_Bubble: unless invincible or in a lasting transformation, Wario in a bubble
## (touches and stings bump; the bubble object takes OBJACTION_07).
func _bubble_interaction() -> void:
	if wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		return
	set_obj_action(OBJACTION_07)
	wTransformation = TRANSFORMATION_BUBBLE
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 1
	set_state_in_bubble()


## ObjInteraction_Vampire: unless invincible or in a lasting transformation, Vampire Wario, unless
## the presence probe above him (Func_19b25) has already ended it (a light).
func _vampire_interaction() -> void:
	if wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_VAMPIRE_WARIO
	probe_presence_top()
	if wTransformation == TRANSFORMATION_VAMPIRE_WARIO:
		set_state_vampire_transforming()


## ObjInteraction_Beam: unless invincible, split (passing through touches and stings); in a
## lasting transformation he is only touched.
func _beam_interaction() -> void:
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		_touch_object()
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_SPLIT
	wTouchState = TOUCH_PASS_THROUGH
	wStingTouchState = TOUCH_PASS_THROUGH
	wca94 = 2
	set_state_split_hit()


## ObjInteraction_YellowBellyArrow: unless invincible, Puffy Wario; in a lasting transformation or
## already puffy he is only touched (Owl Wario lets go of the owl first: ReleaseOwl).
func _puffy_interaction() -> void:
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_PUFFY_WARIO:
		_touch_object()
		return
	if wTransformation == TRANSFORMATION_OWL_WARIO:
		release_owl()
	set_obj_action(OBJACTION_06)
	set_state_puffy_inflating()


## Func_208f2: as Func_20899 without the side: a vanishing sting-touch makes it vanish, any other
## than a bump does nothing; in water the object is bumped and an untransformed Wario dives.
func _bump_object_swimming() -> void:
	if wStingTouchState != 0 and wStingTouchState != TOUCH_BUMP:
		if wStingTouchState == TOUCH_VANISH:
			set_obj_action(OBJACTION_VANISH_TOUCH)
		return
	if wWaterInteraction == 0:
		return
	set_obj_action(OBJACTION_BUMP)
	if wInvincibleCounter == 1 or wTransformation != 0:
		return
	start_dive()


## SetObjAction: the action on the object being checked, and the side Wario met it on in the upper
## nibble of OBJ_UNK_1D.
func set_obj_action(action: int) -> void:
	var base: int = W_OBJECTS + wObjPtr * OBJ_STRUCT_LENGTH
	wram1[base + OBJ_ACTION] = action
	wram1[base + OBJ_UNK_1D] = (wram1[base + OBJ_UNK_1D] & 0x0F) | wInteractionSide


## Func_21dac: unless invincible, launched its way (SetState_Launched; the object gets
## OBJACTION_06); in a lasting transformation only touched (Func_2022c).
func _launched_by_object() -> void:
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		_touch_object()
		return
	wDirection = wObjDirection
	set_state_launched()
	set_obj_action(OBJACTION_06)


## Func_2022c: rolling attacks; from above or below Wario steps on it; otherwise Func_2023b.
func _touch_object() -> void:
	if wIsRolling != 0:
		attack_object()
		return
	if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
		step_on_object()
		return
	_bump_into_object()


## Func_2023b: an attack hits it; otherwise both bump, Wario away from it (SetState_EnemyBumping).
func _bump_into_object() -> void:
	if wTouchState != 0 and wTouchState != TOUCH_BUMP:
		match wTouchState:
			TOUCH_VULNERABLE:
				# Func_20939 jumps straight back here with the touch state unchanged: the original
				# never returns.
				note_unported("Func_2023b with TOUCH_VULNERABLE (a loop in the original)")
			TOUCH_ATTACK:
				attack_object()
			TOUCH_VANISH:
				_vanish_object_and_knock_back_if_zombie()
			_:
				_next_object = true
		return
	if wAttackCounter != 0:
		attack_object()
		return
	set_obj_action(OBJACTION_BUMP)
	if wInvincibleCounter == 1:
		return
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		_flat_bumped()
		return
	if wTransformation != 0:
		return
	wDirection = DIRECTION_RIGHT if wObjScreenXPos < wWarioScreenXPos else DIRECTION_LEFT
	set_state_enemy_bumping()


## SetState_EnemyBumping: knocked back on the knock-back jump table from index $0e.
func set_state_enemy_bumping() -> void:
	wJumpVelIndex = 0x0E
	wJumpVelTable = JUMP_VEL_KNOCK_BACK
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wGrabState = 0
	wWarioState = WST_ENEMY_BUMPING
	load_wario_gfx(WARIO_WALK_GFX)
	set_wario_oam(OAM_1426C)
	if wIsCrouching != 0:
		# Frameset_14a3b facing left, Frameset_14a38 facing right (the crouch framesets crossed over).
		wWarioFramesetPtr = FRAMESET_CROUCH_LEFT if wDirection != DIRECTION_LEFT else FRAMESET_CROUCH_RIGHT
	else:
		wWarioFramesetPtr = FRAMESET_ENEMY_BUMP_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ENEMY_BUMP_LEFT
	update_wario_animation()


## AttackObject: the object is knocked away from Wario; he stops (or keeps falling), or bounces off
## a heavy object.
func attack_object() -> void:
	if wObjScreenXPos >= wWarioScreenXPos:
		wInteractionSide = INTERACTION_RIGHT
		hXPos = word(wWarioXPos + 8)
	else:
		wInteractionSide = INTERACTION_LEFT
		hXPos = word(wWarioXPos - 8)
	hYPos = word(wWarioYPos - 8)
	create_particle(PARTICLE_STARS)
	set_obj_action(OBJACTION_ATTACK)
	if wTransformation == TRANSFORMATION_FAT_WARIO:
		set_state_fat_bumping()
		return
	if wTransformation == TRANSFORMATION_SNOWMAN_WARIO:
		if wTransformationProgress == 0:
			set_state_snowman_bumped()
		return
	if wTransformation != 0:
		return
	var heavy: bool = (wObjInteractionType & HEAVY_OBJ) != 0
	if wIsRolling != 0:
		if heavy and wPowerUpLevel < GARLIC:
			do_jumping_bump()
		return
	if heavy:
		do_jumping_bump()
	elif wJumpVelTable == 0:
		set_state_idling()
	else:
		start_fall()


## StepOnObject: from above, Wario bounces off it (a jump, higher with A and the High Jump Boots);
## from below he stops or falls; either way the object wobbles.
func step_on_object() -> void:
	if wInvincibleCounter == 1:
		return
	if wIsSmashAttacking == 1:
		if wTransformation == TRANSFORMATION_FAT_WARIO:
			_vanish_object_and_knock_back_if_zombie()
		else:
			_smash_attack_object()
		return
	if wTransformation != 0:
		_step_on_object_transformed()
		return
	wAttackCounter = 0
	if wIsRolling != 0:
		attack_object()
		return
	wInteractionSide |= INTERACTION_LEFT if wObjScreenXPos < wWarioScreenXPos else INTERACTION_RIGHT
	if (wInteractionSide & INTERACTION_DOWN) == 0 and wObjScreenYPos >= wWarioScreenYPos:
		if (wGrabState & GRAB_STATE_MASK) == GRAB_IDLE:
			grab_jump()
		else:
			wGrabState = 0
			if wIsCrouching != 0:
				start_crouch_jump()
			elif wJoypadDown == 0:
				_bounce_off_object()
				set_obj_action(OBJACTION_WOBBLE)
				return
			else:
				start_jump_from_input()
		wDoFullJump = 1
		wJumpVelIndex = 0x0A
		if (wJoypadDown & PAD_A) != 0 and wPowerUpLevel >= HIGH_JUMP_BOOTS:
			wJumpVelIndex = 0
		set_obj_action(OBJACTION_WOBBLE)
		return
	if wInvincibleCounter == 1:
		return
	if wIsCrouching != 0:
		if wJumpVelTable != 0:
			start_crouch_fall()
	elif (wGrabState & GRAB_STATE_MASK) == GRAB_IDLE:
		if wJumpVelTable != 0:
			grab_fall()
	else:
		wGrabState = 0
		if wJumpVelTable == 0:
			set_state_idling()
		else:
			start_fall()
	set_obj_action(OBJACTION_WOBBLE)


## Func_20602: a smash attack from above. Transformed (but invisible), the object vanishes (a
## zombie Wario is knocked back); otherwise Wario jumps off it (higher with A and the High Jump
## Boots) and it vanishes.
func _smash_attack_object() -> void:
	if wTransformation != TRANSFORMATION_INVISIBLE_WARIO and wTransformation != 0:
		_vanish_object_and_knock_back_if_zombie()
		return
	if (wGrabState & GRAB_STATE_MASK) == GRAB_IDLE:
		grab_jump()
	else:
		wGrabState = 0
		start_jump_from_input()
	wDoFullJump = 1
	wJumpVelIndex = 0x0A
	if (wJoypadDown & PAD_A) != 0 and wPowerUpLevel >= HIGH_JUMP_BOOTS:
		wJumpVelIndex = 0
	set_obj_action(OBJACTION_VANISH_TOUCH)


## Func_21aac: from above, a smash attack (Func_20602, then OBJACTION_SMASH_ATTACK_WALKABLE);
## otherwise Wario stands on it (Func_209ca).
func _stand_on_or_smash_object() -> void:
	if wIsSmashAttacking != 1:
		_stand_on_object()
		return
	_smash_attack_object()
	set_obj_action(OBJACTION_SMASH_ATTACK_WALKABLE)


## Func_20e6a: Wario bounces off it (Func_20939); with no touch state, OBJACTION_0A. When Func_20939
## goes on to the next object (Func_2023b's `jp ProcessInteractions.next_obj`), the original keeps
## this call's return address on the stack and returns here only when the pass ends: not ported.
func _bounce_off_object_0b() -> void:
	_bounce_off_object()
	if _next_object:
		note_unported("Func_20e6a after ProcessInteractions.next_obj")
		return
	if wTouchState == 0:
		set_obj_action(OBJACTION_0A)


## ObjInteraction_Solid (`omodon` false) and ObjInteraction_Omodon: from above Wario stands on it;
## from below a solid object pushes him down (Func_2168b) and a falling Omodon flattens him; from
## the side an attack bumps him back (Func_217a9) and otherwise he is pushed out (Func_20a6f).
func _solid_interaction(omodon: bool) -> void:
	if (wInteractionSide & INTERACTION_UP) != 0:
		_stand_on_object()
	elif (wInteractionSide & INTERACTION_DOWN) != 0:
		if not omodon:
			_hit_object_from_below()
			return
		if wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
			return
		set_obj_action(OBJACTION_FLATTEN)
		var base: int = W_OBJECTS + wObjPtr * OBJ_STRUCT_LENGTH
		set_state_flat_airborne(wram1[base + OBJ_X_POS] | (wram1[base + OBJ_X_POS + 1] << 8),
				(wObjInteractionType & INTERACTION_MASK) == OBJ_INTERACTION_RICHTERTOFFEN)
	elif wAttackCounter != 0:
		do_jumping_bump()
	else:
		_push_out_of_object()


## Func_2028a: Flat Wario in the air, bumped, falls facing away from the object.
func _flat_bumped() -> void:
	if wJumpVelTable == 0:
		return
	wDirection = DIRECTION_RIGHT if wObjScreenXPos < wWarioScreenXPos else DIRECTION_LEFT
	set_state_flat_falling()


## Func_2168b: Wario under the object is pushed down by the overlap (12 px at most from 16); in
## water he dives; on ground (CheckCentreCollision) he stands there, otherwise he falls. A
## squished Flat Wario is lifted out instead.
func _hit_object_from_below() -> void:
	if wWarioState == WST_FLAT_SQUISHED:
		set_state_flat_squished_lifting()
		return
	move_wario_down(wc1c2 if wc1c2 < 0x10 else 0x0C)
	probe_presence_top()
	if wWaterInteraction != 0:
		dive_from_surface_skip_splash()
		return
	if check_centre_collision() != 0:
		wWarioYPos = hYPos
		if wInvincibleCounter == 1:
			return
		if wTransformation == TRANSFORMATION_FLAT_WARIO:
			if wWarioState != WST_FLAT_SQUISHED:
				set_state_flat_idling()
			return
		if wTransformation != 0:
			return
		wGrabState = 0
		set_state_idling()
		return
	if wInvincibleCounter == 1:
		return
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		set_state_flat_falling()
		return
	if wTransformation != 0:
		return
	if wIsCrouching != 0:
		start_crouch_fall()
		return
	wGrabState = 0
	start_fall()


## ObjInteraction_Tadpole (and the Robo-Mouse): from above or below Wario steps on it; met head
## on (the side it faces) it rolls him (ObjInteraction_RollingRock); from behind he bounces off
## (Func_20e6a).
func _tadpole_interaction() -> void:
	if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
		step_on_object()
		return
	var head_on: int = INTERACTION_RIGHT if wObjDirection == DIRECTION_LEFT else INTERACTION_LEFT
	if (wInteractionSide & head_on) != 0:
		_rolling_rock_interaction()
	else:
		_bounce_off_object_0b()


## ObjInteraction_RollingRock: the object reacts; unless rolling, Wario rolls the way it goes
## (Func_1e174).
func _rolling_rock_interaction() -> void:
	set_obj_action(OBJACTION_06)
	if wIsRolling != 0:
		return
	wDirection = wObjDirection
	start_rolling_fall()


## Func_209ca: Wario stands on the object: lifted onto it (up to 2 px a frame), the object stepped
## on, and a fall ends there; the pass goes on.
func _stand_on_object() -> void:
	if wWarioState == WST_ATTACKING_AIRBORNE:
		wAttackCounter = 0
	if wWaterInteraction != 0 or wWarioState == WST_DIVING:
		return
	wIsOnSteppableObject = 1
	if wc1c1 != 0:
		move_wario_up(2 if wc1c1 >= 3 else wc1c1)
	set_obj_action(9)  # OBJACTION_STEP_ON
	_next_object = true
	if wJumpVelTable == 0 or wAttackCounter != 0 or wIsRolling != 0:
		return
	trigger_floor_transition_skip_update_y_pos()
	if wInvincibleCounter == 1:
		return
	if wTransformation != 0:
		_next_object = false
		return
	if wGrabState != 0:
		set_state_grab_idling()
		return
	wWaterInteraction = 0
	if wIsCrouching != 0:
		crouch_or_slide()
	else:
		set_state_idling()


## Func_20939: Wario bounces back off the object (DoJumpingBump), facing it.
func _bounce_off_object() -> void:
	if wTouchState != 0:
		_bump_into_object()
		return
	set_obj_action(OBJACTION_06)
	if wInvincibleCounter == 1:
		return
	do_jumping_bump()
	load_wario_gfx(WARIO_WALK_GFX)
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_oam(OAM_1426C)
	wGrabState = 0
	if wObjScreenXPos >= wWarioScreenXPos:
		wInteractionSide = INTERACTION_RIGHT
		wDirection = DIRECTION_LEFT
		wWarioFramesetPtr = FRAMESET_STEP_BOUNCE_LEFT
	else:
		wInteractionSide = INTERACTION_LEFT
		wDirection = DIRECTION_RIGHT
		wWarioFramesetPtr = FRAMESET_STEP_BOUNCE_RIGHT
	update_wario_animation()


func _vanish_object_and_knock_back_if_zombie() -> void:
	set_obj_action(OBJACTION_VANISH_TOUCH)
	if wTransformation == TRANSFORMATION_ZOMBIE_WARIO:
		set_state_zombie_knock_back()


## Func_20670: the sting. While invincible Wario only bounces off; rolling attacks (unless the
## object is heavy and Wario has no Garlic); otherwise he is stung, facing it.
func sting_wario() -> void:
	if wInvincibleCounter != 0:
		_bounce_off_object()
		return
	var heavy_without_garlic: bool = wPowerUpLevel < GARLIC and (wObjInteractionType & HEAVY_OBJ) != 0
	if not heavy_without_garlic and wIsRolling != 0:
		attack_object()
		return
	if wStingTouchState != 0 and wStingTouchState != TOUCH_VULNERABLE:
		match wStingTouchState:
			TOUCH_BUMP:
				_bump_into_object()
			TOUCH_ATTACK:
				attack_object()
			TOUCH_VANISH:
				_vanish_object_and_knock_back_if_zombie()
			_:
				_next_object = true
		return
	wInteractionSide |= INTERACTION_LEFT if wObjScreenXPos < wWarioScreenXPos else INTERACTION_RIGHT
	wDirection = DIRECTION_LEFT if (wInteractionSide & INTERACTION_RIGHT) != 0 else DIRECTION_RIGHT
	set_obj_action(OBJACTION_06)
	if wInvincibleCounter == 1:
		return
	if wStingTouchState == TOUCH_VULNERABLE:
		sting_out_of_transformation()
		return
	set_state_stung()


## ObjInteraction_GreyKey to _BlueKey and CollectKey: the key's flag (GREY_KEY_F + colour), the
## object takes OBJACTION_07 (Func_20a63), and the game pauses in ST_COLLECT_KEY. The pass ends.
func _collect_key(colour: int) -> void:
	wKeyAndTreasureFlags |= 1 << colour
	set_obj_action(OBJACTION_07)
	wState = ST_COLLECT_KEY
	wTimer = 0


## StepOnObject.Transformed: Hot Wario (once hot) burns it away and Fat Wario attacks it; otherwise
## the object only wobbles, Flat Wario falls away from it (Func_2028a), and Bouncy Wario bounces off
## it (Func_2a0b2).
func _step_on_object_transformed() -> void:
	if wTransformation == TRANSFORMATION_HOT_WARIO and wTransformationProgress >= 2:
		_vanish_object_and_knock_back_if_zombie()
		return
	if wTransformation == TRANSFORMATION_FAT_WARIO:
		attack_object()
		return
	wInteractionSide |= INTERACTION_LEFT if wObjScreenXPos < wWarioScreenXPos else INTERACTION_RIGHT
	set_obj_action(OBJACTION_WOBBLE)
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		_flat_bumped()
	elif wTransformation == TRANSFORMATION_BOUNCY_WARIO and wTouchState != TOUCH_PASS_THROUGH:
		bouncy_bounce()


## ObjInteraction_GreyTreasure to _BlueTreasure: landed on, a chest is stood on; walked into with
## its key (and untransformed), the treasure is Wario's (GetTreasure); otherwise he is pushed back.
func _treasure_interaction(colour: int) -> void:
	if (wInteractionSide & INTERACTION_UP) != 0:
		_stand_on_object()
		return
	if wTransformation != 0 or (wKeyAndTreasureFlags & (1 << colour)) == 0:
		_push_out_of_object()
		return
	wKeyAndTreasureFlags |= GREY_TREASURE_FLAG << colour
	wLevelEndScreen = LVLEND_GREY_TREASURE + colour
	_get_treasure()


## GetTreasure: the chest opens (OBJACTION_07), every other object vanishes, and the treasure scene
## starts: Wario intangible and moving by himself, out of the chest, facing it. The pass ends.
func _get_treasure() -> void:
	set_obj_action(OBJACTION_07)
	_treasure_clear_objects()
	if wLevelEndScreen == LVLEND_NO_TREASURE:
		return
	wLevelEndScreen |= 0x80
	wResetDisabled = 1
	wWalkVelIndex = 0
	wWarioState = WST_GET_TREASURE_START
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelIndex = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wIsSmashAttacking = 0
	wIsCrouching = 0
	wAttackCounter = 0
	wIsIntangible = 1
	wAutoMoveState = 1
	if wJumpVelTable != 0:
		wJumpVelIndex = FALLING_JUMP_VEL_INDEX
	set_wario_pal(WARIO_DEFAULT_PAL)
	load_wario_gfx(WARIO_IDLE_GFX)
	set_wario_oam(OAM_14000)
	if (wInteractionSide & INTERACTION_LEFT) == 0:
		move_wario_left(wc1c3)
		wDirection = DIRECTION_RIGHT
		wWarioFramesetPtr = FRAMESET_IDLE_RIGHT
	else:
		move_wario_right(wc1c4)
		wDirection = DIRECTION_LEFT
		wWarioFramesetPtr = FRAMESET_IDLE_LEFT
	update_wario_animation()


## TreasureClearObjects: every active object but this one vanishes (OBJACTION_VANISH_TREASURE).
func _treasure_clear_objects() -> void:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if (wram1[base + OBJ_FLAGS] & OBJFLAG_ACTIVE) != 0 and slot != wObjPtr:
			wram1[base + OBJ_ACTION] = OBJACTION_VANISH_TREASURE


## Func_20a6f: Wario is pushed out of the object the way he came (by the overlap, unless a wall
## stops him), then: a ball of string or a burning Wario turns round; rolling or attacking bumps;
## otherwise the pass goes on.
func _push_out_of_object() -> void:
	var right_side: bool = wObjScreenXPos >= wWarioScreenXPos
	var pushed: bool = false
	for attempt: int in 2:
		if right_side:
			if wDirection == DIRECTION_LEFT:
				_next_object = true
				return
			wInteractionSide = INTERACTION_RIGHT
			if check_bottom_left_breaking() != 0:
				pushed = true
				break
			if wc1c3 == 0xFF:
				right_side = false
				continue
			move_wario_left(wc1c3)
			pushed = true
			break
		if wDirection != DIRECTION_LEFT:
			_next_object = true
			return
		wInteractionSide = INTERACTION_LEFT
		if check_bottom_right_breaking() != 0:
			pushed = true
			break
		if wc1c4 == 0xFF:
			right_side = true
			continue
		move_wario_right(wc1c4)
		pushed = true
		break
	if not pushed:
		_next_object = true
		return
	match wTransformation:
		TRANSFORMATION_BALL_O_STRING_WARIO:
			if wTransformationProgress == 1:
				_ball_o_string_turn()
		TRANSFORMATION_HOT_WARIO:
			if wTransformationProgress == 1:
				on_fire_turn()
		TRANSFORMATION_ICE_SKATIN:
			note_unported("Func_20a6f ice skatin (Func_1ec215)")
		_:
			wWalkVelIndex = 0
			if wIsRolling != 0 or wAttackCounter != 0:
				do_jumping_bump()
			else:
				_next_object = true


## ObjInteraction_Fire: the object reacts; unless invincible, Wario catches fire (already
## transformed, he is only touched): Hot Wario for 600 frames, from SetState_OnFire. The pass ends.
func _set_wario_on_fire() -> void:
	set_obj_action(OBJACTION_06)
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		_touch_object()
		return
	wTransformation = TRANSFORMATION_HOT_WARIO
	wTransformationProgress = 1
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wTransformationDuration = HOT_WARIO_DURATION
	wWarioStateCounter = 0
	set_state_on_fire()


## ObjInteraction_Rail: unless in a lasting transformation or already hanging, Wario grabs the
## line (OBJACTION_06; SFX_HANG_GRAB and the music not simulated): his touches bump, stings hurt.
func _grab_rail() -> void:
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_RAIL:
		return
	set_obj_action(OBJACTION_06)
	wTransformation = TRANSFORMATION_RAIL
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_VULNERABLE
	wca94 = 1
	set_state_hanging_rail()


## ObjInteraction_Ice: unless invincible or already in a lasting transformation, Wario is frozen
## into Ice Skatin' Wario (the object takes OBJACTION_07; SFX_028 not simulated); crouching under a
## ceiling, it misses him.
func _freeze_wario() -> void:
	if wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		return
	if wIsCrouching != 0:
		wCollisionBoxTop = byte(-27)
		if check_up_collision() != 0:
			wCollisionBoxTop = byte(-15)
			return
	set_obj_action(OBJACTION_07)
	wTransformation = TRANSFORMATION_ICE_SKATIN
	wTouchState = TOUCH_ATTACK
	wStingTouchState = TOUCH_ATTACK
	wca94 = 2
	set_state_ice_skatin_start()


## ObjInteraction_Omodonmeka: in the air, only a touch; otherwise the object takes OBJACTION_0C
## and picks Wario up (an object moves him, wAutoMoveState) unless he is transformed (Flat Wario
## stretches, not ported; others only touch it).
func _omodonmeka_interaction() -> void:
	if wJumpVelTable != 0:
		_touch_object()
		return
	set_obj_action(OBJACTION_0C)
	if wTransformation == TRANSFORMATION_FLAT_WARIO:
		set_state_flat_stretching()
		return
	if wTransformation != 0:
		_touch_object()
		return
	wAutoMoveState = 1
	wWarioState = WST_PICKED_UP
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wIsSmashAttacking = 0
	wAttackCounter = 0
	wIsCrouching = 0
	wGrabState = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wFrameDuration = 0
	wAnimationFrame = 0
	wJumpVelTable = 1
	wPickedUpWiggleCounter = NUM_WIGGLES_TO_ESCAPE
	load_wario_gfx(WARIO_AIRBORNE_GFX)
	set_wario_oam(OAM_15955)
	wWarioFramesetPtr = 0x5F7F if wDirection != DIRECTION_LEFT else 0x5F70
	update_wario_animation()


## ObjInteraction_Food: crouching, or already transformed (persistent or fat), Wario only
## touches it (OBJACTION_0D); invincible, nothing; otherwise it is eaten (OBJACTION_07) and Wario
## becomes Fat Wario for 420 frames, eating (falling first if airborne; SFX_03A and the music not
## simulated).
func _eat_food() -> void:
	if wIsCrouching != 0:
		set_obj_action(OBJACTION_0D)
		return
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_FAT_WARIO:
		set_obj_action(OBJACTION_0D)
		return
	set_obj_action(OBJACTION_07)
	wTransformation = TRANSFORMATION_FAT_WARIO
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wTransformationDuration = FAT_WARIO_DURATION
	wInvisibleFrame = 0
	wSFXLoopCounter = 0
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
	set_state_fat_eating()


## ObjInteraction_Silky: stepped on from above or below; met on the side it faces, Wario is wrapped
## in string (Func_2126a); otherwise a touch (Func_2022c).
func _silky_interaction() -> void:
	if (wInteractionSide & (INTERACTION_UP | INTERACTION_DOWN)) != 0:
		step_on_object()
		return
	if _sting_side_hit(INTERACTION_LEFT if wObjDirection == DIRECTION_RIGHT else INTERACTION_RIGHT):
		_wrap_wario_in_string()
		return
	_touch_object()


## Func_2126a: a crouching Wario without headroom is only touched; otherwise the object reacts and,
## unless he is invincible or already transformed, Wario becomes a ball of string, turned away
## from it.
func _wrap_wario_in_string() -> void:
	if wIsCrouching != 0:
		wCollisionBoxTop = byte(-27)
		if check_up_collision() != 0:
			wCollisionBoxTop = byte(-15)
			_touch_object()
			return
	set_obj_action(OBJACTION_06)
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		_bump_into_object()
		return
	wDirection = DIRECTION_RIGHT if wObjScreenXPos < wWarioScreenXPos else DIRECTION_LEFT
	wTransformation = TRANSFORMATION_BALL_O_STRING_WARIO
	wTransformationProgress = 0
	wTouchState = TOUCH_ATTACK
	wStingTouchState = TOUCH_ATTACK
	wca94 = 1
	wWarioState = WST_GETTING_WRAPPED_IN_STRING
	wWarioStateCounter = 0
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
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_STRING_PAL)
	load_wario_gfx(WARIO_STRING_GFX)
	set_wario_oam(OAM_171C0)
	wWarioFramesetPtr = FRAMESET_GETTING_WRAPPED
	update_wario_animation()


## ObjInteraction_Electric: the object reacts (OBJACTION_06); unless invincible or already
## transformed, Wario is shocked: TRANSFORMATION_ELECTRIC (touching objects now makes them vanish),
## facing the object, in WST_ELECTRIC_START.
func _electrify_wario() -> void:
	wInteractionSide |= INTERACTION_LEFT if wObjScreenXPos < wWarioScreenXPos else INTERACTION_RIGHT
	set_obj_action(OBJACTION_06)
	if wInvincibleCounter != 0:
		return
	if (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0 or wTransformation == TRANSFORMATION_ELECTRIC:
		return
	wDirection = DIRECTION_LEFT if (wInteractionSide & INTERACTION_RIGHT) != 0 else DIRECTION_RIGHT
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wGrabState = 0
	wAttackCounter = 0
	wJumpVelIndex = 0
	wJumpVelTable = 0
	wIsCrouching = 0
	wIsRolling = 0
	wIsSmashAttacking = 0
	wInvisibleFrame = 0
	wWarioState = WST_ELECTRIC_START
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	wTransformation = TRANSFORMATION_ELECTRIC
	wTouchState = TOUCH_VANISH
	wStingTouchState = TOUCH_VANISH
	wca94 = 1
	wFrameDuration = 0
	wAnimationFrame = 0
	set_wario_pal(WARIO_ELECTRIC_PAL)
	load_wario_gfx(WARIO_ELECTRIC_GFX)
	set_wario_oam(OAM_1790E)
	wWarioFramesetPtr = FRAMESET_ELECTRIC_STRUCK_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ELECTRIC_STRUCK_LEFT
	update_wario_animation()


## Func_20b6b (OBJ_INTERACTION_00): from above, stepped on; an attack hits it; picking it up needs
## the Grab Glove and Wario facing it off a ladder, so otherwise he steps on it too.
func _interaction_00() -> void:
	if (wInteractionSide & INTERACTION_UP) != 0:
		step_on_object()
		return
	if wTouchState != 0:
		match wTouchState:
			TOUCH_ATTACK:
				attack_object()
			TOUCH_VANISH:
				_vanish_object_and_knock_back_if_zombie()
			TOUCH_PASS_THROUGH:
				_next_object = true
			_:
				step_on_object()
		return
	if wWarioState >= WST_DIVING and wWarioState <= WST_TRYING_SUBMERGE:
		_touch_object_swimming()
		return
	if (wIsRolling | wAttackCounter) != 0:
		attack_object()
		return
	if (wIsCrouching | wGrabState) != 0 or wPowerUpLevel < GRAB_GLOVE or wWarioState == WST_LADDER_SCRATCHING \
			or (wWarioState >= WST_LADDER_CLIMBING and wWarioState <= WST_LADDER_SLIDING):
		step_on_object()
		return
	var object_right: bool = wObjScreenXPos >= wWarioScreenXPos
	wInteractionSide = INTERACTION_RIGHT if object_right else INTERACTION_LEFT
	if (wDirection != DIRECTION_LEFT) != object_right:
		step_on_object()
		return
	if wInvincibleCounter == 1:
		return
	_pick_up_object()


## Func_20b6b's pick-up (the Grab Glove; a heavy object needs the Super Grab Gloves, or Wario steps
## on it): the object is picked up (OBJACTION_PICK_UP); in the air he falls holding it (a heavy one
## he steps on, its pick-up already set), on the ground he lifts it (SFX_GRAB not simulated), at
## once if he faces up a slope.
func _pick_up_object() -> void:
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - 8)
	var heavy: bool = (wObjInteractionType & HEAVY_OBJ) != 0
	if not heavy:
		wGrabState = GRAB_PICK_UP
	else:
		if wPowerUpLevel < SUPER_GRAB_GLOVES:
			step_on_object()
			return
		wGrabState = GRAB_PICK_UP | GRAB_HEAVY
	set_obj_action(OBJACTION_PICK_UP)
	if wJumpVelTable != 0:
		if heavy:
			step_on_object()
			return
		grab_fall()
		return
	wFrameDuration = 0
	wAnimationFrame = 0
	wWarioStateCounter = 0
	wWarioStateCycles = 0
	wWarioState = WST_PICKING_UP
	wCollisionBoxBottom = byte(-1)
	wCollisionBoxTop = byte(-27)
	wCollisionBoxLeft = byte(-9)
	wCollisionBoxRight = 9
	load_wario_gfx(WARIO_THROW_GFX)
	set_wario_oam(OAM_1606A)
	if wDirection == DIRECTION_LEFT:
		if (wWarioSlopeInteraction & LEFT_SLOPE) != 0:
			set_state_grab_idling()
			return
		wWarioFramesetPtr = 0x63F5 if (wGrabState & GRAB_HEAVY) != 0 else 0x63EC
	else:
		if (wWarioSlopeInteraction & RIGHT_SLOPE) != 0:
			set_state_grab_idling()
			return
		wWarioFramesetPtr = 0x6415 if (wGrabState & GRAB_HEAVY) != 0 else 0x640C
	update_wario_animation()


## ObjInteraction_MusicalCoin: counted (up to 8), 10 coins ($10 on the low BCD byte, to 999 at
## most), and the pass continues (CollectMusicalCoin).
func _collect_musical_coin() -> void:
	if wNumMusicalCoins >= NUM_LEVEL_MUSICAL_COINS:
		_next_object = true
		return
	wNumMusicalCoins += 1
	_collect_ten_coins()


## CollectMusicalCoin (ObjInteraction_ColourCoin falls into it): ten coins, capped at 999 (BCD),
## and the object takes OBJACTION_07; the pass goes on.
func _collect_ten_coins() -> void:
	_add_coins(0x10)
	set_obj_action(OBJACTION_07)
	_next_object = true


## ObjInteraction_RegularCoin: one coin; the pass ends (`jp Func_20a63`).
func _collect_coin() -> void:
	_add_coins(0x01)
	set_obj_action(OBJACTION_07)


## wNumCoins (big-endian BCD) plus `amount`, at most MAX_NUM_COINS ($999).
func _add_coins(amount: int) -> void:
	var low: int = _bcd_add(wNumCoins & 0xFF, amount, 0)
	var high: int = _bcd_add(wNumCoins >> 8, 0, low >> 8)
	wNumCoins = ((high & 0xFF) << 8) | (low & 0xFF)
	if (high & 0xF0) != 0:
		wNumCoins = 0x0999


## `add`/`adc` then `daa` on two BCD bytes: the BCD sum in the low byte, the carry in bit 8.
static func _bcd_add(a: int, b: int, carry: int) -> int:
	var low: int = (a & 0x0F) + (b & 0x0F) + carry
	var high: int = (a >> 4) + (b >> 4)
	if low > 9:
		low -= 10
		high += 1
	var out_carry: int = 0
	if high > 9:
		high -= 10
		out_carry = 1
	return (out_carry << 8) | ((high & 0x0F) << 4) | (low & 0x0F)
