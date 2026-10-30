class_name ObjectStates
extends ObjectSim
## The object state routines objects share, ported by translation from src/engine/level/
## update_objects.asm (falling, landing, bumps, stuns, being attacked, wobbling) and the probes and
## moves in src/home/object_mechanics.asm. Objects probe the level through ProcessBlock like Wario,
## with wBlockFuncWarioFlag clear (src/engine/level/collisions.asm). Velocity tables come from the
## extracted object movement data (bank $18), indexed within their 256-byte page as the game does.
## Research note: docs/02-research/objects.md.

# Object interaction types (OBJ_INTERACTION_*).
const OBJ_INTERACTION_00: int = 0x00
const OBJ_INTERACTION_01: int = 0x01
const OBJ_INTERACTION_FRONT_STING: int = 0x02
const OBJ_INTERACTION_FULL_STING: int = 0x05
# Object states beyond ObjectSim's.
const OBJSTATE_LAND: int = 0x01
const OBJSTATE_0F: int = 0x0F
const OBJSTATE_10: int = 0x10
const OBJSTATE_STANDING_FALL_START: int = 0x11
const OBJSTATE_12: int = 0x12
const OBJSTATE_TURN_AROUND_START: int = 0x13
const OBJSTATE_14: int = 0x14
const OBJSTATE_15: int = 0x15
const OBJSTATE_STUN_LEFT_START: int = 0x16
const OBJSTATE_STUN_RIGHT_START: int = 0x17
const OBJSTATE_1C: int = 0x1C
const OBJSTATE_20: int = 0x20
const OBJSTATE_21: int = 0x21
const OBJSTATE_22: int = 0x22
const OBJSTATE_23: int = 0x23
const OBJSTATE_24: int = 0x24
const OBJSTATE_25: int = 0x25
const OBJSTATE_26: int = 0x26
const OBJSTATE_27: int = 0x27
const OBJSTATE_SPECIAL_1: int = 0x2D
const OBJSTATE_SPECIAL_2: int = 0x2E
const OBJSTATE_FALL: int = 0x30
const OBJSTATE_WALK: int = 0x31
const OBJSTATE_BUMP_LEFT: int = 0x32
const OBJSTATE_BUMP_RIGHT: int = 0x33
const OBJSTATE_ATTACKED_LEFT: int = 0x34
const OBJSTATE_ATTACKED_RIGHT: int = 0x35
const OBJSTATE_WOBBLE_LEFT: int = 0x38
const OBJSTATE_WOBBLE_RIGHT: int = 0x39
const OBJSTATE_3B: int = 0x3B
const OBJSTATE_3C: int = 0x3C
const OBJSTATE_3F: int = 0x3F
const OBJSTATE_40: int = 0x40
const OBJSTATE_STANDING_FALL: int = 0x41
const OBJSTATE_42: int = 0x42
const OBJSTATE_TURN_AROUND: int = 0x43
const OBJSTATE_44: int = 0x44
const OBJSTATE_45: int = 0x45
const OBJSTATE_STUN_LEFT: int = 0x46
const OBJSTATE_STUN_RIGHT: int = 0x47
const OBJSTATE_50: int = 0x50
const OBJSTATE_51: int = 0x51
const OBJSTATE_52: int = 0x52
const OBJSTATE_53: int = 0x53
const OBJSTATE_54: int = 0x54
const OBJSTATE_55: int = 0x55
const OBJSTATE_56: int = 0x56
const OBJSTATE_57: int = 0x57
const OBJSTATE_58: int = 0x58
const OBJSTATE_59: int = 0x59
# Velocity tables in bank $18 (src/data/object_movements.asm), by address.
const STANDING_FALL_Y_VEL_LIGHT: int = 0x4000  # Heavy at + $20
const DATA_60040: int = 0x4040  # Data_60060 (heavy) at + $20
const DATA_60180: int = 0x4180  # Data_601a0 (heavy) at + $20
const DATA_601C0: int = 0x41C0  # a picked-up object's rise in front of Wario facing right (Func_61f54)
const DATA_601E0: int = 0x41E0  # facing left (Func_620a6)
const DATA_60080: int = 0x4080  # a throw's arc (Data_600a0, heavy, at + $20)
const DATA_60100: int = 0x4100  # thrown with Up
const DATA_600C0: int = 0x40C0  # a full throw's arc
const DATA_60140: int = 0x4140  # thrown fully charged with Up
const FALLING_Y_VEL_LIGHT: int = 0x4280  # Heavy at + $10
const DATA_602A0: int = 0x42A0  # Data_602b0 (heavy) at + $10
const DATA_602C0: int = 0x42C0
const DATA_601D0: int = 0x41D0  # Count Richtertoffen picked up, facing right (Func_61f54)
const DATA_601F0: int = 0x41F0  # facing left (Func_620a6)
const DATA_603D0: int = 0x43D0  # Count Richtertoffen's jump
const DATA_603E0: int = 0x43E0  # falling snow, Count Richtertoffen's fall
const DATA_604B0: int = 0x44B0  # Count Richtertoffen's bounce
const DATA_602E0: int = 0x42E0
const DATA_60320: int = 0x4320
const DATA_60300: int = 0x4300
const DATA_603F0: int = 0x43F0
const DATA_60490: int = 0x4490
const DATA_604A0: int = 0x44A0
const MOVEMENT_DATA_START: int = 0x4000

## Object movement data (bank $18 from $4000), from objects.json.
var movement_data: PackedByteArray = PackedByteArray()
## hffa0: the last vertical velocity a table gave (HRAM scratch the landing code reads).
var hffa0: int = 0
## The b register after the last probe: ProcessBlockOnLeft/Right return it unchanged at the map's edge.
var _probe_b: int = 0


## Framesets and movement data from objects.json (tools/wl3pc/extract/objects.py).
## Pneumo's bob (Data_44000, bank $11): signed Y steps to $80.
var pneumo_bob: PackedByteArray = PackedByteArray()
## The Omodon carrier's bob (Data_40000, bank $10).
var omodon_bob: PackedByteArray = PackedByteArray()


func load_object_data(document: Dictionary) -> void:
	load_object_framesets(document)
	load_object_groups(document)
	load_particle_framesets(document)
	movement_data = String(document.get("movement_data", {}).get("bytes", "")).hex_decode()
	pneumo_bob = String(document.get("pneumo_bob", {}).get("bytes", "")).hex_decode()
	omodon_bob = String(document.get("omodon_bob", {}).get("bytes", "")).hex_decode()
	bank_data.clear()
	for key: String in document.get("bank_data", {}):
		var location: PackedStringArray = key.split(":")
		bank_data[(location[0].hex_to_int() << 16) | location[1].hex_to_int()] = String(document["bank_data"][key]).hex_decode()


# --- Positions, probes, and moves ----------------------------------------------------------

## The data the "Object Functions" banks hold, by where it starts (bank << 16 | address).
var bank_data: Dictionary = {}


## `ld a, [bc]` at `address` with `bank` mapped (an object's own function bank).
func bank_byte(bank: int, address: int) -> int:
	for start: int in bank_data:
		var data: PackedByteArray = bank_data[start]
		var index: int = address - (start & 0xFFFF)
		if start >> 16 == bank and index >= 0 and index < data.size():
			return data[index]
	note_unported("object bank data %02x:%04x" % [bank, address])
	return 0


## _CountActiveTransientObjects: the active transient slots.
func count_active_transient_objects() -> int:
	var e: int = 0
	for slot: int in NUM_OBJECTS:
		if (slot_flags(slot) & (OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT)) == (OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT):
			e += 1
	return e


func cur_y() -> int:
	return cur_word(OBJ_Y_POS)


func cur_x() -> int:
	return cur_word(OBJ_X_POS)


## hPos from the object's position, offset (16-bit, as `sub`/`sbc 0` and `add`/`adc 0` do).
func set_hpos_from_object(dy: int = 0, dx: int = 0) -> void:
	hYPos = word(cur_y() + dy)
	hXPos = word(cur_x() + dx)


## `ld a, [wCurObjCollBoxLeft]; cpl; inc a; ld b, a` then x - b: the left edge.
func left_edge_x() -> int:
	return word(cur_x() - byte(-cur(OBJ_COLLBOX_LEFT)))


## x + OBJ_COLLBOX_RIGHT (unsigned): the right edge.
func right_edge_x() -> int:
	return word(cur_x() + cur(OBJ_COLLBOX_RIGHT))


func store_object_y_from_hpos() -> void:
	set_cur_word(OBJ_Y_POS, hYPos)


## The object probes (Func_3543 DOWN, Func_352b UNK1, Func_35a3 UNK2, Func_358b UNK3, Func_3513
## UNK4): ProcessBlock at hPos, returning its result (`ld a, b`).
func object_probe(points: int) -> int:
	_probe_b = probe(points)
	return _probe_b


## ProcessBlockOnLeft: the block left of the last probe's; at the map's left edge, b is unchanged.
func process_block_on_left() -> int:
	block_column = (block_column - 1) & 0xFF
	if block_column == 0xFF:
		return _probe_b
	_probe_b = process_block()
	return _probe_b


## ProcessBlockOnRight: the block right of the last probe's; past the page's end, b is unchanged.
func process_block_on_right() -> int:
	block_column = (block_column + 1) & 0xFF
	if block_column == 0:
		return _probe_b
	_probe_b = process_block()
	return _probe_b


## MoveObjectLeft and MoveObjectRight: one pixel.
func move_object_left() -> void:
	set_cur_word(OBJ_X_POS, cur_x() - 1)


func move_object_right() -> void:
	set_cur_word(OBJ_X_POS, cur_x() + 1)


## MoveObjectUp: one pixel up.
func move_object_up() -> void:
	set_cur_word(OBJ_Y_POS, cur_y() - 1)


## MoveObjectDown: one pixel down.
func move_object_down() -> void:
	set_cur_word(OBJ_Y_POS, cur_y() + 1)


## _ApplyObjXMovement: as apply_obj_y_movement, along X with OBJ_VAR_2 as the index.
func apply_obj_x_movement(table: int) -> void:
	var page: int = table & 0xFF00
	var c: int = byte((table & 0xFF) + cur(OBJ_VAR_2))
	var a: int = movement_byte(page, c)
	if a == 0x80:
		a = movement_byte(page, byte(c - 1))
	else:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) + 1)
	move_object_x(a - 0x100 if a >= 0x80 else a)


## _ApplyObjXMovement_Loop: as apply_obj_x_movement, but at the $80 end the table starts again.
func apply_obj_x_movement_loop(table: int) -> void:
	var page: int = table & 0xFF00
	var a: int = movement_byte(page, byte((table & 0xFF) + cur(OBJ_VAR_2)))
	if a == 0x80:
		set_cur(OBJ_VAR_2, 0)
		a = movement_byte(page, table & 0xFF)
	set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) + 1)
	move_object_x(a - 0x100 if a >= 0x80 else a)


## _ApplyObjYMovement_Loop: as apply_obj_y_movement, but at the $80 end the table starts again.
func apply_obj_y_movement_loop(table: int) -> void:
	var page: int = table & 0xFF00
	var a: int = movement_byte(page, byte((table & 0xFF) + cur(OBJ_VAR_3)))
	if a == 0x80:
		set_cur(OBJ_VAR_3, 0)
		a = movement_byte(page, table & 0xFF)
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) + 1)
	add_y_signed(a)


## MoveObjectUp_Slow: one pixel up on odd frames.
func move_object_up_slow() -> void:
	if (wGlobalCounter & 1) != 0:
		move_object_up()


## MoveObjectDown_Slow: one pixel down on even frames.
func move_object_down_slow() -> void:
	if (wGlobalCounter & 1) == 0:
		move_object_down()


## Func_63209 (Func_34fc): ApplyObjYMovement's step, and a standing Wario carried with it by the
## same (unsigned) amount, his floor then settled (Func_19720).
func func_63209(table: int) -> void:
	var b: int = table_step(table, 0, false)
	add_y_signed(b)
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	move_wario_down(b)
	func_19720()


## Func_19720: CheckAirborneCollision as Wario's; landed, TriggerFloorTransition, otherwise
## TriggerDownwardsFloorTransition.
func func_19720() -> void:
	wBlockFuncWarioFlag = 1
	var b: int = check_airborne_collision()
	wBlockFuncWarioFlag = 0
	if b != 0:
		trigger_floor_transition()
	else:
		trigger_downwards_floor_transition()


## _ApplyObjYMovement: the next entry of `table` (OBJ_VAR_3 within its page, the last repeating at
## $80) added to Y as a signed velocity.
func apply_obj_y_movement(table: int) -> void:
	add_y_signed(table_step(table, 0, false))


func move_object_x(dx: int) -> void:
	set_cur_word(OBJ_X_POS, cur_x() + dx)


## MoveObjectLeft_Slow: one pixel on odd frames.
func move_object_left_slow() -> void:
	if (wGlobalCounter & 1) != 0:
		move_object_x(-1)


## MoveObjectRight_Slow: one pixel on even frames.
func move_object_right_slow() -> void:
	if (wGlobalCounter & 1) == 0:
		move_object_x(1)


func move_object_left_by_var2() -> void:
	move_object_x(-cur(OBJ_VAR_2))


func move_object_right_by_var2() -> void:
	move_object_x(cur(OBJ_VAR_2))


## (OBJ_SCREEN_X_POS + $28) past the screen's left (`cp $f0`, no carry) or right (`cp $10`, carry)
## releases a grab.
func release_grab_off_left() -> void:
	if byte(cur(OBJ_SCREEN_X_POS) + 0x28) >= 0xF0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)


func release_grab_off_right() -> void:
	if byte(cur(OBJ_SCREEN_X_POS) + 0x28) < 0x10:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)


func is_heavy() -> bool:
	return (cur(OBJ_INTERACTION_TYPE) & HEAVY_OBJ) != 0


## OBJ_INTERACTION_TYPE keeps HEAVY_OBJ and takes `kind`.
func set_interaction(kind: int) -> void:
	set_cur(OBJ_INTERACTION_TYPE, (cur(OBJ_INTERACTION_TYPE) & HEAVY_OBJ) | kind)


func set_collbox_x(left: int, right: int) -> void:
	set_cur(OBJ_COLLBOX_RIGHT, right)
	set_cur(OBJ_COLLBOX_LEFT, left)


func hdir() -> bool:
	return (cur(OBJ_SUBSTATE) & OBJSUBFLAG_HDIR) != 0


# --- Velocity tables -----------------------------------------------------------------------

## A table entry within its page: `ld b, HIGH(t); add LOW(t)` with no carry into b.
func movement_byte(table: int, offset: int) -> int:
	var address: int = (table & 0xFF00) | ((table + offset) & 0xFF)
	var index: int = address - MOVEMENT_DATA_START
	if index < 0 or index >= movement_data.size():
		note_unported("object movement data %04x" % address)
		return 0
	return movement_data[index]


## The common step: entry OBJ_VAR_3 of `table` (or of the heavy table `heavy_offset` on), OBJ_VAR_3
## advancing until the $80 end, where the last entry repeats. Sets hffa0 when `keep` is set.
func table_step(table: int, heavy_offset: int, keep: bool = true) -> int:
	var c: int = byte((table & 0xFF) + cur(OBJ_VAR_3))
	if is_heavy():
		c = byte(c + heavy_offset)
	var page: int = table & 0xFF00
	var a: int = movement_byte(page, c)
	if a == 0x80:
		a = movement_byte(page, byte(c - 1))
	else:
		set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) + 1)
	if keep:
		hffa0 = a
	return a


## Y plus a signed velocity (`cp $80` chooses add with carry or with borrow).
func add_y_signed(a: int) -> void:
	set_cur_word(OBJ_Y_POS, cur_y() + (a - 0x100 if a >= 0x80 else a))


## Y plus a downward velocity: `add c; jr nc; inc [hl]`.
func add_y_down(a: int) -> void:
	set_cur_word(OBJ_Y_POS, cur_y() + a)


## Y plus an upward velocity: `add c; jr c; dec [hl]` (the high byte drops without a carry).
func add_y_up(a: int) -> void:
	var low: int = cur(OBJ_Y_POS) + a
	set_cur(OBJ_Y_POS, low)
	if low <= 0xFF:
		set_cur(OBJ_Y_POS + 1, cur(OBJ_Y_POS + 1) - 1)


# --- Falling and landing ------------------------------------------------------------------

## The landing probe falls share: hPos at the object, wObjSlopeInteraction cleared, UNK1. On no
## block, water or sand makes it vanish; on a block it lands at hYPos and `landed` decides.
func _fall_probe(clear_c1ca: bool = false) -> int:
	set_hpos_from_object()
	wObjSlopeInteraction = 0
	if clear_c1ca:
		wc1ca = 0
	return object_probe(COLLISION_UNK1)


func _vanish_if_in_water() -> void:
	if wIsInWaterOrSand != 0:
		set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)


## After a landing on a slope: OBJ_VAR_2 = 2, then Func_62d57 or Func_62e31 by the slope's side.
func _land_on_slope() -> void:
	set_cur(OBJ_VAR_2, 2)
	if (wObjSlopeInteraction & 0x0F) == RIGHT_SLOPE:
		func_62d57()
	else:
		func_62e31()


## _ObjState_Fall: gravity from FallingYVel; on landing OBJSTATE_LAND (or a slope's tumble).
func obj_state_fall() -> void:
	add_y_down(table_step(FALLING_Y_VEL_LIGHT, 0x10))
	if _fall_probe() == 0:
		_vanish_if_in_water()
		return
	store_object_y_from_hpos()
	if wObjSlopeInteraction == 0:
		set_cur(OBJ_STATE, OBJSTATE_LAND)
		return
	_land_on_slope()


## _ObjState_StandingFall: the animation three times faster, StandingFallYVel; on landing, turn.
func obj_state_standing_fall() -> void:
	if cur(OBJ_FRAME_DURATION) >= 3:
		set_cur(OBJ_FRAME_DURATION, cur(OBJ_FRAME_DURATION) - 3)
	add_y_signed(table_step(STANDING_FALL_Y_VEL_LIGHT, 0x20))
	if _fall_probe() == 0:
		_vanish_if_in_water()
		return
	store_object_y_from_hpos()
	if wObjSlopeInteraction == 0:
		set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
		return
	_land_on_slope()


## Func_62d57: the state a landing leftwards leads to, by the fall's speed (hffa0).
func func_62d57() -> void:
	if hffa0 < 2:
		set_cur(OBJ_STATE, OBJSTATE_STUN_LEFT_START)
	elif hffa0 < 3:
		set_cur(OBJ_STATE, OBJSTATE_20)
	elif hffa0 < 4:
		set_cur(OBJ_STATE, OBJSTATE_22)
	else:
		set_cur(OBJ_STATE, OBJSTATE_24)


## Func_62e31: the same rightwards.
func func_62e31() -> void:
	if hffa0 < 2:
		set_cur(OBJ_STATE, OBJSTATE_STUN_RIGHT_START)
	elif hffa0 < 3:
		set_cur(OBJ_STATE, OBJSTATE_21)
	elif hffa0 < 4:
		set_cur(OBJ_STATE, OBJSTATE_23)
	else:
		set_cur(OBJ_STATE, OBJSTATE_25)


## Func_628ea: no ground below -> OBJSTATE_12.
func func_628ea() -> void:
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_12)


## Func_62908: no ground below -> OBJSTATE_STANDING_FALL_START.
func func_62908() -> void:
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)


## Func_62926 (OBJSTATE_42): Data_60040's arc; on landing OBJSTATE_0F (or a slope's tumble).
func func_62926() -> void:
	add_y_signed(table_step(DATA_60040, 0x20))
	if _fall_probe() == 0:
		_vanish_if_in_water()
		return
	store_object_y_from_hpos()
	if wObjSlopeInteraction == 0:
		set_cur(OBJ_STATE, OBJSTATE_0F)
		return
	_land_on_slope()


## Func_629a6: Data_602a0, rising (`add c; jr c; dec [hl]`).
func func_629a6() -> void:
	add_y_up(table_step(DATA_602A0, 0x10))


# --- Bumps and stuns -----------------------------------------------------------------------

## _ObjState_BumpRight: pushed while OBJ_VAR_2 lasts (Func_62ae5), then wait and turn around.
func obj_state_bump_right() -> void:
	if cur(OBJ_VAR_2) != 0:
		func_62ae5()
		return
	_count_down_then(OBJSTATE_TURN_AROUND_START)


## _ObjState_BumpLeft: the same, pushed the other way (Func_62bce).
func obj_state_bump_left() -> void:
	if cur(OBJ_VAR_2) != 0:
		func_62bce()
		return
	_count_down_then(OBJSTATE_TURN_AROUND_START)


## OBJ_STATE_DURATION counts down; at 0 the state becomes `state`.
func _count_down_then(state: int) -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, state)


## Func_62ae5: slide left by OBJ_VAR_2 unless a wall is there (then stunned, facing right), keep
## to the ground, and drop off a ledge into OBJSTATE_14; OBJ_VAR_2 decays.
func func_62ae5() -> void:
	set_hpos_from_object(-4)
	hXPos = left_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, OBJSTATE_STUN_RIGHT_START)
		_decay_var2()
		return
	move_object_left_by_var2()
	release_grab_off_left()
	set_hpos_from_object()
	wObjSlopeInteraction = 0
	var on_slope: bool = object_probe(COLLISION_DOWN) == 0x10
	store_object_y_from_hpos()
	if on_slope:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
		if (wObjSlopeInteraction & 1) == 0:
			set_cur(OBJ_STATE, OBJSTATE_STUN_RIGHT_START)
		elif cur(OBJ_STATE) != OBJSTATE_STUN_LEFT:
			set_cur(OBJ_STATE, OBJSTATE_14)
		return
	hXPos = left_edge_x()
	if object_probe(COLLISION_UNK2) == 0:
		hXPos = right_edge_x()
		if object_probe(COLLISION_UNK2) == 0:
			set_cur(OBJ_STATE, OBJSTATE_14)
	_decay_var2()


## Func_62bce: the mirror of Func_62ae5, sliding right.
func func_62bce() -> void:
	set_hpos_from_object(-4)
	hXPos = right_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, OBJSTATE_STUN_LEFT_START)
		_decay_var2()
		return
	move_object_right_by_var2()
	release_grab_off_right()
	set_hpos_from_object()
	wObjSlopeInteraction = 0
	var on_slope: bool = object_probe(COLLISION_DOWN) == 0x10
	store_object_y_from_hpos()
	if on_slope:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
		if (wObjSlopeInteraction & 1) != 0:
			set_cur(OBJ_STATE, OBJSTATE_STUN_LEFT_START)
		elif cur(OBJ_STATE) != OBJSTATE_STUN_RIGHT:
			set_cur(OBJ_STATE, OBJSTATE_15)
		return
	hXPos = right_edge_x()
	if object_probe(COLLISION_UNK2) == 0:
		hXPos = left_edge_x()
		if object_probe(COLLISION_UNK2) == 0:
			set_cur(OBJ_STATE, OBJSTATE_15)
	_decay_var2()


## OBJ_VAR_2 drops by 1 every 8 frames (every 4 for heavy objects).
func _decay_var2() -> void:
	var mask: int = 0b11 if is_heavy() else 0b111
	if (wGlobalCounter & mask) == 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)


# --- Being attacked ----------------------------------------------------------------------

## Func_62840: knocked right by OBJ_VAR_2 (four times as far with Garlic), along Data_60180's arc.
func func_62840() -> void:
	var b: int = cur(OBJ_VAR_2)
	if wram1[W_EFFECTIVE_POWER_UP] >= GARLIC:
		b = byte(b << 2)
	move_object_x(b)
	_attacked_arc()


## Func_62898: knocked left.
func func_62898() -> void:
	var b: int = cur(OBJ_VAR_2)
	if wram1[W_EFFECTIVE_POWER_UP] >= GARLIC:
		b = byte(b << 2)
	move_object_x(-b)
	_attacked_arc()


## Func_6283a: knocked right, OBJ_VAR_2 whatever Wario's power.
func func_6283a() -> void:
	move_object_x(cur(OBJ_VAR_2))
	_attacked_arc()


## Func_62892: knocked left, OBJ_VAR_2 whatever Wario's power.
func func_62892() -> void:
	move_object_x(-cur(OBJ_VAR_2))
	_attacked_arc()


func _attacked_arc() -> void:
	add_y_signed(table_step(DATA_60180, 0x20))
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


# --- Wobbling and tumbling ---------------------------------------------------------------

## Func_62c9f (OBJSTATE_26): tumble left from the start.
func func_62c9f() -> void:
	set_cur(OBJ_STATE, OBJSTATE_56)
	set_cur(OBJ_VAR_3, 0)
	func_62ca8()


## Func_62ca8: drift left by OBJ_VAR_2 while falling; landing goes through Func_62d34, a wall to
## OBJSTATE_15.
func func_62ca8() -> void:
	move_object_left_by_var2()
	release_grab_off_left()
	add_y_down(table_step(FALLING_Y_VEL_LIGHT, 0x10))
	if _fall_probe(true) != 0:
		_land_drifting_left()
		return
	if wIsInWaterOrSand != 0:
		set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)
		return
	set_hpos_from_object(-4)
	hXPos = left_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, OBJSTATE_15)


## Func_62d34: land, OBJ_VAR_2 adjusted by the slope, then Func_62d57.
func _land_drifting_left() -> void:
	store_object_y_from_hpos()
	var slope: int = wObjSlopeInteraction & 0x0F
	if slope != RIGHT_SLOPE:
		if slope == 2:
			set_cur(OBJ_VAR_2, 1)
		elif cur(OBJ_VAR_2) != 0:
			set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
	func_62d57()


## Func_62d7d (OBJSTATE_27): tumble right from the start.
func func_62d7d() -> void:
	set_cur(OBJ_STATE, OBJSTATE_57)
	set_cur(OBJ_VAR_3, 0)
	func_62d86()


## Func_62d86: the mirror of Func_62ca8, drifting right; a wall leads to OBJSTATE_14.
func func_62d86() -> void:
	move_object_right_by_var2()
	release_grab_off_right()
	add_y_down(table_step(FALLING_Y_VEL_LIGHT, 0x10))
	if _fall_probe(true) != 0:
		_land_drifting_right()
		return
	if wIsInWaterOrSand != 0:
		set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)
		return
	set_hpos_from_object(-4)
	hXPos = right_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, OBJSTATE_14)


## Func_62e0f: land, OBJ_VAR_2 adjusted by the slope, then Func_62e31.
func _land_drifting_right() -> void:
	store_object_y_from_hpos()
	var slope: int = wObjSlopeInteraction & 0x0F
	if slope != LEFT_SLOPE:
		if slope == 1:
			set_cur(OBJ_VAR_2, 1)
		elif cur(OBJ_VAR_2) != 0:
			set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
	func_62e31()


## The hop starts (Func_62e8f, Func_62eaa, Func_62e74 leftwards; Func_62f76, Func_62f91,
## Func_62f5b rightwards): a state, OBJ_VAR_3 cleared, and a duration (shorter when heavy).
func _start_hop(state: int, light: int, heavy: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE_DURATION, heavy if is_heavy() else light)


func func_62e8f() -> void:
	_start_hop(OBJSTATE_50, 4, 1)
	func_62ec3(DATA_602C0)


func func_62eaa() -> void:
	_start_hop(OBJSTATE_52, 5, 2)
	func_62ec3(DATA_602E0)


func func_62e74() -> void:
	_start_hop(OBJSTATE_54, 6, 2)
	func_62ec3(DATA_60300)


func func_62f76() -> void:
	_start_hop(OBJSTATE_51, 4, 1)
	func_62faa(DATA_602C0)


func func_62f91() -> void:
	_start_hop(OBJSTATE_53, 5, 2)
	func_62faa(DATA_602E0)


func func_62f5b() -> void:
	_start_hop(OBJSTATE_55, 6, 2)
	func_62faa(DATA_60300)


## Func_62ec3: a hop leftwards along `table`; a block above or ahead ends it in OBJSTATE_27, the
## duration's end in OBJSTATE_26; either way collisions are back on.
func func_62ec3(table: int) -> void:
	_hop_rise(table)
	move_object_left_by_var2()
	release_grab_off_left()
	set_hpos_from_object(-byte(-cur(OBJ_COLLBOX_TOP)))
	if (object_probe(COLLISION_UNK3) & 0x0F) != 0:
		_end_hop(OBJSTATE_27)
		return
	set_hpos_from_object(-8)
	hXPos = left_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		_end_hop(OBJSTATE_27)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_end_hop(OBJSTATE_26)


## Func_62faa: the same rightwards, with the two outcomes the other way round.
func func_62faa(table: int) -> void:
	_hop_rise(table)
	move_object_right_by_var2()
	release_grab_off_right()
	set_hpos_from_object(-byte(-cur(OBJ_COLLBOX_TOP)))
	if (object_probe(COLLISION_UNK3) & 0x0F) != 0:
		_end_hop(OBJSTATE_26)
		return
	set_hpos_from_object(-8)
	hXPos = right_edge_x()
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		_end_hop(OBJSTATE_26)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_end_hop(OBJSTATE_27)


## The hop's table step (no hffa0) and its rise when the entry is not 0.
func _hop_rise(table: int) -> void:
	var a: int = table_step(table, 0x10, false)
	if a != 0:
		add_y_up(a)


func _end_hop(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)


# --- Platforms and vanishing ---------------------------------------------------------------

## SetOneWayPlatformAction: unless already stepped on, an object Wario is not above waits a frame
## (no_actions_for 1), so he cannot land on it from below.
func set_one_way_platform_action() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		return
	var b: int = byte(cur(OBJ_COLLBOX_TOP) + byte(cur(OBJ_SCREEN_Y_POS) + 0x2A + 3))
	if byte(wWarioScreenYPos + 0x2A) < b:
		return
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


## Func_62e57 (Func_3173): the object vanishes into stars that despawn it, so it spawns again later
## (Func_4c860).
func func_62e57() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_4C860 & 0xFFFF)
	_vanish_object_fields()


## Func_4c860: the stars of Func_62e57; at the end the object is despawned (its cell gets bit 7 back).
func func_4c860() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		despawn_cur_object()


# --- Grabbed objects (update_objects.asm: Func_61f54 to Func_627f0) ------------------------
# `plus`: the object at Wario's x + 7 (Func_61f54, Func_621fb, Func_6247b), else x - 7.

## A held object's height above Wario: 30 px, 26 while he smash-attacks (`add a; add a` of
## wIsSmashAttacking, $81 too giving 4).
func _held_height() -> int:
	return byte(30 - byte(wIsSmashAttacking * 4))


## _ApplyObjSetMovement: every OBJ_VAR_1 frames the next [duration, dy, dx] entry from OBJ_VAR_2/3
## (a pointer into the movement data), a 0 duration starting `table` again; the step is signed.
func apply_obj_set_movement(table: int) -> void:
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	var pointer: int = cur(OBJ_VAR_2) | (cur(OBJ_VAR_3) << 8)
	var duration: int = _movement_at(pointer)
	if duration == 0:
		pointer = table
		duration = _movement_at(pointer)
	set_cur(OBJ_VAR_1, duration)
	var dy: int = _movement_at(pointer + 1)
	var dx: int = _movement_at(pointer + 2)
	pointer += 3
	set_cur(OBJ_VAR_2, pointer & 0xFF)
	set_cur(OBJ_VAR_3, pointer >> 8)
	set_cur_word(OBJ_Y_POS, word(cur_y() + (dy - 0x100 if dy >= 0x80 else dy)))
	set_cur_word(OBJ_X_POS, word(cur_x() + (dx - 0x100 if dx >= 0x80 else dx)))


func _movement_at(address: int) -> int:
	var index: int = address - MOVEMENT_DATA_START
	if index < 0 or index >= movement_data.size():
		note_unported("object movement data %04x" % address)
		return 0
	return movement_data[index]


## The drop (Func_61f54's .drop_obj, Func_621fb's .asm_6229c): the grab ends, the object tumbles
## off (OBJSTATE_14 or 15) without actions for 31 frames (SFX_01A not simulated).
func _drop_held(state: int) -> void:
	wGrabState = 0
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_ACTION, 31 | (1 << NO_ACTIONS_F))
	set_cur(OBJ_STATE, state)


## Func_61f54 and Func_620a6 (OBJSTATE_PICKED_UP_LEFT, _RIGHT): picked up. Rising
## (GRAB_PICK_UP) along its table of (frames, dy, dx) from Wario, stopped by a wall ahead or a
## ceiling (a heavy object is dropped, a light one held at once: GRAB_UNK_02 tells Wario); held
## (GRAB_IDLE), 30 px above him, dropped 16 px lower where it meets something solid; otherwise
## OBJSTATE_12.
func picked_up(plus: bool) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	var grab: int = wGrabState & GRAB_STATE_MASK
	if grab == GRAB_PICK_UP:
		_picked_up_rise(plus)
		return
	if grab != GRAB_IDLE:
		set_cur(OBJ_STATE, OBJSTATE_12)
		return
	set_cur_word(OBJ_Y_POS, word(wWarioYPos - _held_height()))
	set_cur_word(OBJ_X_POS, word(wWarioXPos + (7 if plus else -7)))
	set_hpos_from_object()
	wc1ca = 0
	if object_probe(COLLISION_UNK1) != 0 and wc1ca == 0:
		set_cur_word(OBJ_Y_POS, word(cur_y() + 16))
		_drop_held(OBJSTATE_14 if plus else OBJSTATE_15)
		return
	set_cur(OBJ_STATE, OBJSTATE_19 if plus else OBJSTATE_18)


func _picked_up_rise(plus: bool) -> void:
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		return
	var pointer: int = cur(OBJ_VAR_2) | (cur(OBJ_VAR_3) << 8)
	var frames: int = _movement_at(pointer)
	if frames == 0:
		pointer = word(pointer - 3)  # the last entry again
		frames = _movement_at(pointer)
	set_cur(OBJ_VAR_1, frames)
	var dy: int = _movement_at(word(pointer + 1))
	var dx: int = _movement_at(word(pointer + 2))
	pointer = word(pointer + 3)
	set_cur(OBJ_VAR_2, pointer & 0xFF)
	set_cur(OBJ_VAR_3, pointer >> 8)
	var y: int = word(wWarioYPos + (dy - 0x100 if dy >= 0x80 else dy))
	var x: int = word(wWarioXPos + (dx - 0x100 if dx >= 0x80 else dx))
	hYPos = word(y - 4)
	hXPos = word(x + cur(OBJ_COLLBOX_RIGHT)) if plus else word(x - byte(-cur(OBJ_COLLBOX_LEFT)))
	var blocked: bool = (object_probe(COLLISION_UNK4) & 0x0F) != 0
	if not blocked:
		hYPos = word(y - byte(-cur(OBJ_COLLBOX_TOP)))
		hXPos = x
		blocked = (object_probe(COLLISION_UNK3) & 0x0F) != 0
	if not blocked:
		set_cur_word(OBJ_Y_POS, y)
		set_cur_word(OBJ_X_POS, x)
		return
	if is_heavy():
		_drop_held(OBJSTATE_14 if plus else OBJSTATE_15)
		return
	wGrabState = GRAB_UNK_02
	set_cur(OBJ_STATE, OBJSTATE_19 if plus else OBJSTATE_18)


## Func_621fb and Func_622bd (behind each object's OBJSTATE_49 and _48): held above Wario, dropped
## at a ceiling or a wall (Func_621fb masks the ceiling probe and takes the wall's whole, Func_622bd
## the other way round); a charge (OBJSTATE_4B or _4A) or a throw follows Wario's; let go, it falls
## (OBJSTATE_12), or is set down beside him crouching (OBJSTATE_15 or _14).
func held(plus: bool) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	var grab: int = wGrabState
	match grab & 0x0F:
		GRAB_IDLE:
			_held_idle(plus)
		GRAB_CHARGE_THROW:
			set_cur(OBJ_STATE, OBJSTATE_4B if plus else OBJSTATE_4A)
		GRAB_THROW:
			throw_object(plus, grab)
		_:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			if wIsCrouching != 0:
				set_cur(OBJ_VAR_2, 1)
				set_cur(OBJ_STATE, OBJSTATE_15 if plus else OBJSTATE_14)
			else:
				set_cur(OBJ_STATE, OBJSTATE_12)


func _held_idle(plus: bool) -> void:
	set_cur_word(OBJ_Y_POS, word(wWarioYPos - _held_height()))
	set_cur_word(OBJ_X_POS, word(wWarioXPos + (7 if plus else -7)))
	hYPos = word(cur_y() - byte(-cur(OBJ_COLLBOX_TOP)))
	hXPos = cur_x()
	var ceiling: int = object_probe(COLLISION_UNK3)
	if (ceiling & 0x0F if plus else ceiling) == 0:
		hYPos = word(cur_y() - 8)
		hXPos = right_edge_x() if plus else left_edge_x()
		var wall: int = object_probe(COLLISION_UNK4)
		if (wall if plus else wall & 0x0F) == 0:
			return
	_drop_held(OBJSTATE_14 if plus else OBJSTATE_15)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)


## Func_62382 (OBJSTATE_4A, x - 7) and Func_6247b (OBJSTATE_4B): carried while the throw charges,
## 5 px the other side and 30 px up while a full charge is held (dropped against a wall); then the
## throw; otherwise let go, falling (OBJSTATE_12).
func charge_held(plus: bool) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	var grab: int = wGrabState
	match grab & 0x0F:
		GRAB_CHARGE_THROW, GRAB_THROW_FULLY_CHARGED:
			set_cur_word(OBJ_Y_POS, word(wWarioYPos - _held_height()))
			set_cur_word(OBJ_X_POS, word(wWarioXPos + (7 if plus else -7)))
			return
		GRAB_HOLD_FULL_CHARGE:
			var y: int = word(wWarioYPos - 30)
			var x: int = word(wWarioXPos + (-5 if plus else 5))
			hYPos = word(y - 4)
			hXPos = x
			if (object_probe(COLLISION_UNK4) & 0x0F) == 0:
				set_cur_word(OBJ_Y_POS, y)
				set_cur_word(OBJ_X_POS, x)
				return
			wGrabState = 0
		GRAB_THROW:
			throw_object(plus, grab)
			return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	set_cur(OBJ_STATE, OBJSTATE_12)


## ThrowObject_Right (`right`) and ThrowObject_Left (SFX_THROW not simulated): harmless, still
## grabbed (HandleGrabbedObjectCollisions follows it), no actions for 31 frames; thrown at 3 px a
## frame (2 if heavy, 1 straight up with Up) on OBJSTATE_4F or _4E, or with `grab`'s full charge at
## 4 px (1 with Up) on a full throw.
func throw_object(right: bool, grab: int) -> void:
	set_interaction(OBJ_INTERACTION_00)
	set_cur(OBJ_STATE_DURATION, 0)
	var full: bool = (grab & GRAB_FULL_CHARGE) != 0
	var speed: int = 4 if full else (2 if is_heavy() else 3)
	if (wJoypadDown & PAD_UP) != 0:
		speed = 1
	set_cur(OBJ_VAR_2, speed)
	set_cur(OBJ_VAR_3, 0)
	if full:
		set_cur(OBJ_STATE, OBJSTATE_FULL_THROW_RIGHT_START if right else OBJSTATE_FULL_THROW_LEFT_START)
	else:
		set_cur(OBJ_STATE, OBJSTATE_4F if right else OBJSTATE_4E)
	set_cur(OBJ_ACTION, 31 | (1 << NO_ACTIONS_F))


## The thrown object's probes (Func_62574 and Func_62605; `full`: Func_626da, Func_62768): falling
## (OBJ_STATE_DURATION set), a landing (Func_62d34, Func_62e0f) or water and sand (it vanishes);
## a ceiling or the wall ahead stops it (OBJSTATE_14 or _15; a full throw vanishes). All as a
## thrown object (COLLISION_THROWN_OBJ). True when it flies on.
func _thrown_probes(left: bool, full: bool) -> bool:
	hXPos = cur_x()
	if cur(OBJ_STATE_DURATION) != 0:
		hYPos = cur_y()
		wc1ca = 0
		wBlockFuncSpecialCollision = COLLISION_THROWN_OBJ
		var ground: int = object_probe(COLLISION_UNK1)
		hffa0 = 3
		if ground != 0:
			if left:
				_land_drifting_left()
			else:
				_land_drifting_right()
			return false
		if wIsInWaterOrSand != 0:
			set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)
			return false
	hYPos = word(cur_y() - byte(-cur(OBJ_COLLBOX_TOP)))
	wBlockFuncSpecialCollision = COLLISION_THROWN_OBJ
	if object_probe(COLLISION_UNK3) != 0:
		set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH if full else (OBJSTATE_14 if left else OBJSTATE_15))
		return false
	hYPos = word(cur_y() - 8)
	hXPos = left_edge_x() if left else right_edge_x()
	wBlockFuncSpecialCollision = COLLISION_THROWN_OBJ
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH if full else (OBJSTATE_15 if left else OBJSTATE_14))
		return false
	return true


## Func_62574 (OBJSTATE_4E, thrown left) and Func_62605 (_4F): the throw's flight (Func_62690).
func thrown_flight(left: bool) -> void:
	if not _thrown_probes(left, false):
		return
	if left:
		move_object_left_by_var2()
	else:
		move_object_right_by_var2()
	_throw_arc(DATA_60100 if cur(OBJ_VAR_2) == 1 else DATA_60080)


## ObjState_FullThrowLeft (Func_626da) and _Right (Func_62768): a full throw's flight, the grab let
## go once off the screen's side (Func_627f0).
func full_throw_flight(left: bool) -> void:
	if not _thrown_probes(left, true):
		return
	if left:
		move_object_left_by_var2()
		release_grab_off_left()
	else:
		move_object_right_by_var2()
		release_grab_off_right()
	_throw_arc(DATA_60140 if cur(OBJ_VAR_2) == 1 else DATA_600C0)


## Func_62690 and Func_627f0: the arc's step (Up's table for OBJ_VAR_2 1, the heavy one $20 on);
## OBJ_STATE_DURATION marks it falling (a step down) or rising.
func _throw_arc(table: int) -> void:
	var a: int = table_step(table, 0x20)
	if a == 0:
		return
	add_y_signed(a)
	set_cur(OBJ_STATE_DURATION, 1 if a < 0x80 else 0)
