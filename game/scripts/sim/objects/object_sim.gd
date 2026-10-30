class_name ObjectSim
extends WarioSim
## The level's objects, ported by translation from UpdateObjects and its helpers
## (src/engine/level/update_objects.asm, src/home/object_mechanics.asm) and each object's
## functions (src/engine/level/objects/*.asm). WRAM bank 1's object region ($d000-$d15f: the 8
## slots, wCurObj, wObjDataPointers, and the objects' globals) is kept as bytes in `wram1`, so a
## slot compares with the original byte for byte; multi-byte object fields are little-endian.
## An object function that is not ported is named in `unported`, and its slot is then incomplete.
## Research note: docs/02-research/objects.md.

const NUM_OBJECTS: int = 8
const OBJ_STRUCT_LENGTH: int = 0x20
# Object struct (src/constants/object_constants.asm).
const OBJ_FLAGS: int = 0x00
const OBJ_UNK_01: int = 0x01
const OBJ_UNK_02: int = 0x02
const OBJ_Y_POS: int = 0x03
const OBJ_X_POS: int = 0x05
const OBJ_ID: int = 0x07
const OBJ_INTERACTION_TYPE: int = 0x08
const OBJ_COLLBOX_TOP: int = 0x09
const OBJ_COLLBOX_BOTTOM: int = 0x0A
const OBJ_COLLBOX_LEFT: int = 0x0B
const OBJ_COLLBOX_RIGHT: int = 0x0C
const OBJ_SCREEN_Y_POS: int = 0x0D
const OBJ_SCREEN_X_POS: int = 0x0E
const OBJ_FRAME: int = 0x0F
const OBJ_OAM_PTR: int = 0x10
const OBJ_FRAMESET_PTR: int = 0x12
const OBJ_FRAME_DURATION: int = 0x14
const OBJ_FRAMESET_OFFSET: int = 0x15
const OBJ_STATE_DURATION: int = 0x16
const OBJ_VAR_1: int = 0x17
const OBJ_VAR_2: int = 0x18
const OBJ_VAR_3: int = 0x19
const OBJ_SUBSTATE: int = 0x1A
const OBJ_STATE: int = 0x1B
const OBJ_ACTION: int = 0x1C
const OBJ_UNK_1D: int = 0x1D
const OBJ_UPDATE_FUNCTION: int = 0x1E
const OBJFLAG_ACTIVE: int = 1 << 0
const OBJFLAG_ON_SCREEN: int = 1 << 1
const OBJFLAG_GRABBED: int = 1 << 2
const OBJFLAG_NO_COLLISION: int = 1 << 3
const OBJFLAG_INVISIBLE: int = 1 << 4
const OBJFLAG_STEPPED: int = 1 << 5
const OBJFLAG_TRANSIENT: int = 1 << 6
const OBJFLAG_PRIORITY: int = 1 << 7
const OBJSUBFLAG_UNK_4: int = 1 << 4
const OBJSUBFLAG_UNINITIALISED: int = 1 << 5
const OBJSUBFLAG_VDIR: int = 1 << 6
const OBJSUBFLAG_HDIR: int = 1 << 7
const OBJSUBFLAGS_MASK: int = 0xF0
const NO_ACTIONS_F: int = 7
const HEAVY_OBJ: int = 1 << 7
const INTERACTION_MASK: int = 0xFF ^ HEAVY_OBJ
const INTERACTION_LEFT: int = 1 << 4
const INTERACTION_RIGHT: int = 1 << 5
const INTERACTION_UP: int = 1 << 6
const INTERACTION_DOWN: int = 1 << 7
# Object states (OBJSTATE_*) the ported code names.
const OBJSTATE_00: int = 0x00
const OBJSTATE_BUMP_LEFT_START: int = 0x02
const OBJSTATE_BUMP_RIGHT_START: int = 0x03
const OBJSTATE_ATTACKED_LEFT_START: int = 0x04
const OBJSTATE_ATTACKED_RIGHT_START: int = 0x05
const OBJSTATE_PICKED_UP_LEFT_START: int = 0x06
const OBJSTATE_PICKED_UP_RIGHT_START: int = 0x07
const OBJSTATE_WOBBLE_LEFT_START: int = 0x08
const OBJSTATE_WOBBLE_RIGHT_START: int = 0x09
const OBJSTATE_VANISH_TOUCH: int = 0x0A
const OBJSTATE_0B: int = 0x0B
const OBJSTATE_0C: int = 0x0C
const OBJSTATE_0D: int = 0x0D
const OBJSTATE_0E: int = 0x0E
const OBJSTATE_18: int = 0x18
const OBJSTATE_19: int = 0x19
const OBJSTATE_ACTIVATE: int = 0x2A
const OBJSTATE_SPECIAL_3: int = 0x2F
const OBJSTATE_48: int = 0x48
const OBJSTATE_28: int = 0x28
const OBJSTATE_29: int = 0x29
const OBJSTATE_PICKED_UP_LEFT: int = 0x36
const OBJSTATE_PICKED_UP_RIGHT: int = 0x37
const OBJSTATE_49: int = 0x49
const OBJSTATE_4A: int = 0x4A
const OBJSTATE_4B: int = 0x4B
const OBJSTATE_FULL_THROW_LEFT_START: int = 0x4C
const OBJSTATE_FULL_THROW_RIGHT_START: int = 0x4D
const OBJSTATE_4E: int = 0x4E
const OBJSTATE_4F: int = 0x4F
const OBJSTATE_FULL_THROW_LEFT: int = 0x5E
const OBJSTATE_FULL_THROW_RIGHT: int = 0x5F
const THE_TEMPLE: int = 0xC8
const OBJECT_GROUP_HIDDEN_FIGURE: int = 0xF0
const OBJECT_FUNCTIONS_1_BANK: int = 0x10  # BANK("Object Functions 1"); an object's ID picks bank + (ID >> 4)
const OBJECT_FUNCTIONS_4_BANK: int = 0x13  # BANK("Object Functions 4"): the Temple's objects, whatever the ID

const STARS_FUNC: int = 0x13_48A2  # StarsFunc
const FUNC_4C860: int = 0x13_4860  # Func_4c860: stars that despawn
const OAM_18C000: int = 0x4000  # OAM_18c000 (bank $63)
const FRAMESET_680C5: int = 0x40C5

# WRAM bank 1 from wObjects ($d000), as wram1 offsets.
const W_OBJECTS: int = 0x000
const W_CUR_OBJ: int = 0x100
const W_OBJ_DATA_POINTERS: int = 0x120
const W_EFFECTIVE_POWER_UP: int = 0x14A
const W_FLAME_BLOCK_CLEARED: int = 0x140  # wFlameBlockCleared ($d140)
const W_NUM_LIT_TORCHES: int = 0x143  # wNumLitTorches ($d143)
const W_SHOOT_GOALS: int = 0x144  # wShootGoals ($d144; WarioSim's traced wShootGoals too)
const W_WARIO_GOALS: int = 0x145  # wWarioGoals ($d145)
const WRAM1_SIZE: int = 0x163  # to the hidden figure's w1d162


var wram1: PackedByteArray = _zeroes(WRAM1_SIZE)
## Object framesets ("Object Framesets" bank), pointer -> the bytes from it: (frame, duration) pairs, $ff.
var object_framesets: Dictionary = {}
## Each object group's wObjDataPointers (16 pointers), and the 8-byte object data entries by pointer,
## from objects.json; the Temple's group ($f0, LoadHiddenFigureData's) apart.
var object_group_pointers: Array = []
var hidden_figure_group_pointers: Array = []
var object_data: Dictionary = {}
## Object params (bank $19) by pointer: what CreateObjectAtRelativePos creates from.
var object_params: Dictionary = {}
var _object_functions: Dictionary = {}
## Slots whose update this frame reached something not ported (their bytes are then incomplete).
var unported_slots: Array[int] = []
## What UpdateObjects reached that is not ported, kept apart from `unported` (Wario's and the
## level's): an incomplete object does not make Wario's frame incomplete.
var object_unported: Array[String] = []
var _slot_incomplete: bool = false
var _in_objects: bool = false


static func _zeroes(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	return bytes


## The object groups and their data from objects.json (tools/wl3pc/extract/objects.py).
func load_object_groups(document: Dictionary) -> void:
	object_group_pointers.clear()
	object_data.clear()
	var groups: Dictionary = document.get("object_groups", {})
	for group: Dictionary in groups.get("groups", []):
		var pointers: Array = []
		for value: String in group["obj_data_pointers"]:
			pointers.append(value.hex_to_int())
		object_group_pointers.append(pointers)
	hidden_figure_group_pointers.clear()
	for value: String in groups.get("hidden_figure_group", []):
		hidden_figure_group_pointers.append(value.hex_to_int())
	var entries: Dictionary = groups.get("object_data", {})
	for key: String in entries:
		object_data[key.hex_to_int()] = String(entries[key]).hex_decode()
	var params: Dictionary = groups.get("object_params", {})
	for key: String in params:
		object_params[key.hex_to_int()] = String(params[key]).hex_decode()


## The frameset bank from objects.json (tools/wl3pc/extract/objects.py).
func load_object_framesets(document: Dictionary) -> void:
	object_framesets.clear()
	var by_pointer: Dictionary = document.get("framesets", {}).get("by_pointer", {})
	for key: String in by_pointer:
		var data := PackedByteArray()
		for pair: Array in by_pointer[key]:
			data.append(int(pair[0]))
			data.append(int(pair[1]))
		data.append(0xFF)
		object_framesets[key.hex_to_int()] = data


# --- Loading, spawning, and despawning (load_objects.asm) ------------------------------------

## InitObjectVars_FromLevelStart (`level_start`) and _FromTransition: ClearObjects and
## ClearObjDataPointers (every slot and data pointer zeroed), then wDollBoyNoFlashingBarrel,
## wDollBoyRemainingParts, wNumLitTorches, wShootGoals, and wWarioGoals, and from a level start
## wFlameBlockCleared.
func clear_objects(level_start: bool) -> void:
	for i: int in range(W_OBJECTS, W_OBJECTS + NUM_OBJECTS * OBJ_STRUCT_LENGTH):
		wram1[i] = 0
	for i: int in range(W_OBJ_DATA_POINTERS, W_OBJ_DATA_POINTERS + 2 * 16):
		wram1[i] = 0
	for i: int in range(W_FLAME_BLOCK_CLEARED if level_start else W_FLAME_BLOCK_CLEARED + 1, W_WARIO_GOALS + 1):
		wram1[i] = 0
	wShootGoals = 0


## LoadObjectGroupData's pointers: wObjDataPointers for the room's object group (the Temple's by
## LoadHiddenFigureData).
func load_object_group(group: int) -> void:
	var pointers: Array = hidden_figure_group_pointers if group == OBJECT_GROUP_HIDDEN_FIGURE else []
	if group < object_group_pointers.size():
		pointers = object_group_pointers[group]
	if pointers.is_empty():
		note_object_unported("object group %02x" % group)
		return
	for i: int in pointers.size():
		wram1[W_OBJ_DATA_POINTERS + 2 * i] = int(pointers[i]) & 0xFF
		wram1[W_OBJ_DATA_POINTERS + 2 * i + 1] = int(pointers[i]) >> 8


## SpawnObject: the first free slot takes object `kind` (its map nibble) at hPos, if its map cell
## still has bit 7 (not yet spawned), which is cleared. Only these fields are written; the rest of
## the slot keeps what the last object there left.
func spawn_object(row: int, column: int, kind: int) -> void:
	if hi(hXPos) >= 0x0A:
		return
	var slot: int = -1
	for i: int in NUM_OBJECTS:
		if (slot_flags(i) & OBJFLAG_ACTIVE) == 0:
			slot = i
			break
	if slot < 0:
		return
	var value: int = level.block_at(row, column)
	if value < 0 or (value & 0x80) == 0:
		return
	level.set_block(row, column, value & 0x7F)
	var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
	var pointer: int = wram1[W_OBJ_DATA_POINTERS + 2 * (kind - 1)] | (wram1[W_OBJ_DATA_POINTERS + 2 * (kind - 1) + 1] << 8)
	if not object_data.has(pointer):
		note_object_unported("object data %04x" % pointer)
		return
	var data: PackedByteArray = object_data[pointer]
	wram1[base + OBJ_UNK_01] = column
	wram1[base + OBJ_UNK_02] = byte((wccec - 1) * 32 + 0xA0 + (row - (wccec - 1) * 32))
	wram1[base + OBJ_Y_POS] = lo(hYPos)
	wram1[base + OBJ_Y_POS + 1] = hi(hYPos)
	wram1[base + OBJ_X_POS] = lo(hXPos)
	wram1[base + OBJ_X_POS + 1] = hi(hXPos)
	wram1[base + OBJ_ID] = data[0]
	wram1[base + OBJ_INTERACTION_TYPE] = data[1]
	wram1[base + OBJ_COLLBOX_TOP] = data[2]
	wram1[base + OBJ_COLLBOX_BOTTOM] = 0
	wram1[base + OBJ_FRAME] = 0
	wram1[base + OBJ_OAM_PTR] = data[3]
	wram1[base + OBJ_OAM_PTR + 1] = data[4]
	wram1[base + OBJ_FRAME_DURATION] = 0x7F
	wram1[base + OBJ_SUBSTATE] = 0x01 | OBJSUBFLAG_UNINITIALISED
	wram1[base + OBJ_STATE] = OBJSTATE_00
	wram1[base + OBJ_ACTION] = 2 | (1 << NO_ACTIONS_F)
	wram1[base + OBJ_UPDATE_FUNCTION] = data[5]
	wram1[base + OBJ_UPDATE_FUNCTION + 1] = data[6]
	wram1[base + OBJ_FLAGS] = data[7] | OBJFLAG_ACTIVE | OBJFLAG_INVISIBLE


## _CreateObjectAtRelativePos: the first free slot becomes the object `params` describe, offset from
## wCurObj by the params' signed y and x, transient, and tied to wCurObj's map cell. The screen
## position and frame keep what the slot held.
func create_object_at_relative_pos(params_pointer: int) -> void:
	if not object_params.has(params_pointer):
		note_unported("object params %04x" % params_pointer)
		return
	var params: PackedByteArray = object_params[params_pointer]
	var dy: int = params[0] - 0x100 if params[0] >= 0x80 else params[0]
	var dx: int = params[1] - 0x100 if params[1] >= 0x80 else params[1]
	_create_object(params.slice(2), word(cur_word(OBJ_Y_POS) + dy), word(cur_word(OBJ_X_POS) + dx))


## _CreateObjectFromCurObjPos: as _CreateObjectAtRelativePos, at wCurObj's own position (its
## params have no offsets).
func create_object_from_cur_obj_pos(params_pointer: int) -> void:
	if not object_params.has(params_pointer):
		note_unported("object params %04x" % params_pointer)
		return
	_create_object(object_params[params_pointer], cur_word(OBJ_Y_POS), cur_word(OBJ_X_POS))


## CreateObject_GotPos and what precedes it: `fields` from the params' ID on.
func _create_object(fields: PackedByteArray, y: int, x: int) -> void:
	var slot: int = -1
	for i: int in NUM_OBJECTS:
		if (slot_flags(i) & OBJFLAG_ACTIVE) == 0:
			slot = i
			break
	if slot < 0:
		return
	var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
	wram1[base + OBJ_UNK_01] = cur(OBJ_UNK_01)
	wram1[base + OBJ_UNK_02] = cur(OBJ_UNK_02)
	wram1[base + OBJ_Y_POS] = y & 0xFF
	wram1[base + OBJ_Y_POS + 1] = y >> 8
	wram1[base + OBJ_X_POS] = x & 0xFF
	wram1[base + OBJ_X_POS + 1] = x >> 8
	for i: int in 6:  # ID, interaction type, the box's four sides
		wram1[base + OBJ_ID + i] = fields[i]
	wram1[base + OBJ_OAM_PTR] = fields[6]
	wram1[base + OBJ_OAM_PTR + 1] = fields[7]
	wram1[base + OBJ_FRAMESET_PTR] = fields[8]
	wram1[base + OBJ_FRAMESET_PTR + 1] = fields[9]
	wram1[base + OBJ_FRAME_DURATION] = 0
	wram1[base + OBJ_FRAMESET_OFFSET] = 0
	for i: int in 6:  # state duration, vars 1-3, substate, state
		wram1[base + OBJ_STATE_DURATION + i] = fields[10 + i]
	wram1[base + OBJ_ACTION] = 0
	wram1[base + OBJ_UPDATE_FUNCTION] = fields[16]
	wram1[base + OBJ_UPDATE_FUNCTION + 1] = fields[17]
	wram1[base + OBJ_FLAGS] = fields[18] | OBJFLAG_ACTIVE | OBJFLAG_TRANSIENT


func cur_object_on_screen() -> bool:
	return (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) != 0


## BreakBlock's and BreakBlockWithColourCoin's coin: wCurObj's map cell is cleared and its position
## set to the block's for _CreateObjectFromCurObjPos, then restored from hCurObjBackup.
func create_block_coin(params: int, y: int, x: int) -> void:
	var backup: PackedByteArray = wram1.slice(W_CUR_OBJ + OBJ_UNK_01, W_CUR_OBJ + OBJ_ID)
	set_cur(OBJ_UNK_01, 0)
	set_cur(OBJ_UNK_02, 0)
	set_cur_word(OBJ_Y_POS, y)
	set_cur_word(OBJ_X_POS, x)
	create_object_from_cur_obj_pos(params)
	for i: int in backup.size():
		wram1[W_CUR_OBJ + OBJ_UNK_01 + i] = backup[i]


## DespawnAllObjects: transient objects are cleared; the rest give their map cell bit 7 back.
func despawn_all_objects() -> void:
	for slot: int in NUM_OBJECTS:
		var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		if (wram1[base] & OBJFLAG_ACTIVE) == 0:
			continue
		if (wram1[base] & OBJFLAG_TRANSIENT) != 0:
			wram1[base] = 0
			continue
		var row: int = wram1[base + OBJ_UNK_02] - 0xA0
		var column: int = wram1[base + OBJ_UNK_01]
		wram1[base] = 0
		if level != null and row >= 0 and level.block_at(row, column) >= 0:
			level.set_block(row, column, level.block_at(row, column) | 0x80)


# --- wCurObj ---------------------------------------------------------------------------------

func cur(field: int) -> int:
	return wram1[W_CUR_OBJ + field]


func set_cur(field: int, value: int) -> void:
	wram1[W_CUR_OBJ + field] = value & 0xFF


func cur_word(field: int) -> int:
	return wram1[W_CUR_OBJ + field] | (wram1[W_CUR_OBJ + field + 1] << 8)


func set_cur_word(field: int, value: int) -> void:
	wram1[W_CUR_OBJ + field] = value & 0xFF
	wram1[W_CUR_OBJ + field + 1] = (value >> 8) & 0xFF


func slot_flags(slot: int) -> int:
	return wram1[W_OBJECTS + slot * OBJ_STRUCT_LENGTH + OBJ_FLAGS]


# --- UpdateObjects (update_objects.asm) ----------------------------------------------------

## UpdateObjects (UpdateObjects_Temple in the Temple): wEffectivePowerUp, then every active slot in order (a slot an earlier object
## activates is updated in the same pass, as in the original).
func update_objects() -> void:
	_in_objects = true
	_update_objects()
	_in_objects = false


func _update_objects() -> void:
	var e: int = wPowerUpLevel
	if (wTransformation & 0x80) != 0:  # TRANSFORMATIONF_SUPER_SMASH
		e = SUPER_JUMP_SLAM_OVERALLS
	wram1[W_EFFECTIVE_POWER_UP] = e
	unported_slots.clear()
	# UpdateObjects_Temple: in the Temple no floor transition is looked at.
	var temple: bool = wLevel == THE_TEMPLE
	var floor_transition: bool = wIsFloorTransition != 0 and not temple
	# HandleGrabbedObjectCollisions can change any slot: unported, it leaves them all unjudged.
	_slot_incomplete = false
	if not floor_transition:
		handle_grabbed_object_collisions()
	var all_incomplete: bool = _slot_incomplete
	for slot: int in NUM_OBJECTS:
		if (slot_flags(slot) & OBJFLAG_ACTIVE) != 0:
			_slot_incomplete = false
			if floor_transition:
				update_object_during_floor_transition(slot)
			elif temple:
				update_object_temple(slot)
			else:
				update_object(slot)
			if _slot_incomplete or all_incomplete:
				unported_slots.append(slot)


## An object routine that is not ported, outside UpdateObjects (spawning, loading).
func note_object_unported(routine: String) -> void:
	if not routine in object_unported:
		object_unported.append(routine)


func note_unported(routine: String) -> void:
	_slot_incomplete = true
	if _in_objects:
		if not routine in object_unported:
			object_unported.append(routine)
		return
	super.note_unported(routine)


## HRAM the collision keeps between frames: a thrown object in OBJSTATE_48-_4B sets only the light
## states, so a heavy one it meets takes the heavy states a full throw last set.
var _collided_state_light: int = 0
var _thrown_state_light: int = 0
var _collided_state_heavy: int = 0
var _thrown_state_heavy: int = 0


## HandleGrabbedObjectCollisions: the first active grabbed (thrown or held) object against every
## other active, on-screen, collidable, visible one, by their boxes in screen space ($2a on so the
## bytes do not wrap). The first it meets: it is let go; both take new states (knocked away, or
## wobbling where a heavy one is concerned); the one met loses its collision, and a grab it was in
## (picked up or held) ends. SFX_016 is not simulated.
func handle_grabbed_object_collisions() -> void:
	var thrown: int = -1
	for slot: int in NUM_OBJECTS:
		if (slot_flags(slot) & (OBJFLAG_ACTIVE | OBJFLAG_GRABBED)) == (OBJFLAG_ACTIVE | OBJFLAG_GRABBED):
			thrown = slot
			break
	if thrown < 0:
		return
	var base: int = W_OBJECTS + thrown * OBJ_STRUCT_LENGTH
	var heavy: bool = (wram1[base + OBJ_INTERACTION_TYPE] & HEAVY_OBJ) != 0
	var screen_y: int = byte(wram1[base + OBJ_SCREEN_Y_POS] + 0x2A)
	var screen_x: int = byte(wram1[base + OBJ_SCREEN_X_POS] + 0x2A)
	var top: int = byte(screen_y + wram1[base + OBJ_COLLBOX_TOP])
	var bottom: int = byte(screen_y + wram1[base + OBJ_COLLBOX_BOTTOM])
	var left: int = byte(screen_x + wram1[base + OBJ_COLLBOX_LEFT])
	var right: int = byte(screen_x + wram1[base + OBJ_COLLBOX_RIGHT])
	var state: int = wram1[base + OBJ_STATE]
	if state >= OBJSTATE_FULL_THROW_LEFT_START or state < OBJSTATE_48:
		if (state & 1) == 0:  # thrown left
			_collided_state_light = OBJSTATE_28
			_thrown_state_light = OBJSTATE_WOBBLE_LEFT_START if heavy else OBJSTATE_29
			_collided_state_heavy = OBJSTATE_28 if heavy else OBJSTATE_WOBBLE_RIGHT_START
			_thrown_state_heavy = OBJSTATE_29
		else:
			_collided_state_light = OBJSTATE_29
			_thrown_state_light = OBJSTATE_WOBBLE_RIGHT_START if heavy else OBJSTATE_28
			_collided_state_heavy = OBJSTATE_29 if heavy else OBJSTATE_WOBBLE_LEFT_START
			_thrown_state_heavy = OBJSTATE_28
	elif (state & 1) == 0:
		_collided_state_light = OBJSTATE_WOBBLE_RIGHT_START
		_thrown_state_light = OBJSTATE_WOBBLE_LEFT_START
	else:
		_collided_state_light = OBJSTATE_WOBBLE_LEFT_START
		_thrown_state_light = OBJSTATE_WOBBLE_RIGHT_START
	var wanted: int = OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN
	for slot: int in NUM_OBJECTS:
		var other: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
		var flags: int = wram1[other + OBJ_FLAGS]
		if (flags & (wanted | OBJFLAG_GRABBED | OBJFLAG_NO_COLLISION | OBJFLAG_INVISIBLE)) != wanted:
			continue
		var y: int = byte(wram1[other + OBJ_SCREEN_Y_POS] + 0x2A)
		var x: int = byte(wram1[other + OBJ_SCREEN_X_POS] + 0x2A)
		if byte(wram1[other + OBJ_COLLBOX_BOTTOM] + y) < top or byte(wram1[other + OBJ_COLLBOX_TOP] + y) >= bottom:
			continue
		if byte(wram1[other + OBJ_COLLBOX_RIGHT] + x) < left or byte(wram1[other + OBJ_COLLBOX_LEFT] + x) >= right:
			continue
		wram1[base + OBJ_FLAGS] &= ~OBJFLAG_GRABBED
		var thrown_state: int = wram1[base + OBJ_STATE] & 0xFE
		var collided_state: int
		if thrown_state == OBJSTATE_4A or thrown_state == OBJSTATE_48:
			wGrabState = 0
			wram1[base + OBJ_STATE] = _thrown_state_light
			collided_state = _collided_state_light
		else:
			var other_heavy: bool = (wram1[other + OBJ_INTERACTION_TYPE] & HEAVY_OBJ) != 0
			wram1[base + OBJ_STATE] = _thrown_state_heavy if other_heavy else _thrown_state_light
			var held: int = wram1[other + OBJ_STATE] & 0xFE
			if held == OBJSTATE_PICKED_UP_LEFT or held == OBJSTATE_48:
				wGrabState = 0
			collided_state = _collided_state_heavy if other_heavy else _collided_state_light
		wram1[other + OBJ_STATE] = collided_state
		wram1[other + OBJ_FLAGS] |= OBJFLAG_NO_COLLISION
		return


## UpdateObject: copy the slot to wCurObj, its action, its function, its animation, whether it is on
## screen, its screen position, then copy back all but OBJ_UNK_01, OBJ_UNK_02, and OBJ_UNK_1D.
func update_object(slot: int) -> void:
	var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
	for i: int in OBJ_STRUCT_LENGTH:
		wram1[W_CUR_OBJ + i] = wram1[base + i]
	do_object_action()
	call_object_function()
	update_object_animation()
	check_object_on_screen()
	_finish_object_update(base)


## UpdateObject_Temple: UpdateObject with the update function in bank "Object Functions 4" whatever
## the ID (the hidden figure's), and after the screen position the fight's scroll put back (wSCY its
## shake plus wSCYShake, wSCX wc08b), whatever the object's function did to them.
func update_object_temple(slot: int) -> void:
	var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
	for i: int in OBJ_STRUCT_LENGTH:
		wram1[W_CUR_OBJ + i] = wram1[base + i]
	do_object_action()
	call_object_function(OBJECT_FUNCTIONS_4_BANK)
	update_object_animation()
	check_object_on_screen()
	_finish_object_update(base)
	wSCY = byte(wHiddenFigureSCYShake + wSCYShake)
	wSCX = wc08b


## UpdateObjectDuringFloorTransition: only an object still uninitialised runs its function, there is
## no action, and the frame is refreshed without advancing; the copy back is UpdateObject's.
func update_object_during_floor_transition(slot: int) -> void:
	var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
	for i: int in OBJ_STRUCT_LENGTH:
		wram1[W_CUR_OBJ + i] = wram1[base + i]
	if (cur(OBJ_SUBSTATE) & OBJSUBFLAG_UNINITIALISED) != 0:
		call_object_function()
	update_object_frame()
	check_object_on_screen()
	_finish_object_update(base)


## The end of UpdateObject and UpdateObjectDuringFloorTransition: the screen position, then wCurObj
## back into the slot, all but OBJ_UNK_01, OBJ_UNK_02, and OBJ_UNK_1D, with OBJFLAG_STEPPED cleared.
func _finish_object_update(base: int) -> void:
	set_cur(OBJ_SCREEN_Y_POS, cur(OBJ_Y_POS) + OAM_Y_OFS - wSCY)
	set_cur(OBJ_SCREEN_X_POS, cur(OBJ_X_POS) + OAM_X_OFS - wSCX)
	wram1[base + OBJ_FLAGS] = cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED & 0xFF
	for i: int in range(OBJ_Y_POS, OBJ_ACTION + 1):
		wram1[base + i] = wram1[W_CUR_OBJ + i]
	wram1[base + OBJ_UPDATE_FUNCTION] = cur(OBJ_UPDATE_FUNCTION)
	wram1[base + OBJ_UPDATE_FUNCTION + 1] = cur(OBJ_UPDATE_FUNCTION + 1)


## The object's update function: bank "Object Functions 1" + (ID >> 4), or `bank` (the Temple's),
## pointer OBJ_UPDATE_FUNCTION.
func call_object_function(bank: int = -1) -> void:
	if _object_functions.is_empty():
		_object_functions = object_functions()
	var pointer: int = cur_word(OBJ_UPDATE_FUNCTION)
	if bank < 0:
		bank = OBJECT_FUNCTIONS_1_BANK | (cur(OBJ_ID) >> 4)
	# A pointer below $4000 is home-bank code, the same whatever bank the ID selects.
	var key: int = pointer if pointer < 0x4000 else (bank << 16) | pointer
	if _object_functions.has(key):
		(_object_functions[key] as Callable).call()
	else:
		note_unported("object function %02x:%04x" % [key >> 16, key & 0xFFFF])


## Ported object functions by bank << 16 | pointer (ObjectFunctions fills it).
func object_functions() -> Dictionary:
	return {}


## DoObjectAction: an action an interaction left in OBJ_ACTION becomes the object's next state; with
## NO_ACTIONS set it is a countdown instead.
func do_object_action() -> void:
	var a: int = cur(OBJ_ACTION)
	if a == 0:
		return
	if (a & (1 << NO_ACTIONS_F)) != 0:
		a -= 1
		if a == (1 << NO_ACTIONS_F):  # no_actions_for 0
			a = 0
		set_cur(OBJ_ACTION, a)
		return
	match a:
		1:  # OBJACTION_BUMP
			if (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) == 0:
				_action_directed(OBJSTATE_WOBBLE_LEFT_START, OBJSTATE_WOBBLE_RIGHT_START, true)
			else:
				_action_directed(OBJSTATE_BUMP_LEFT_START, OBJSTATE_BUMP_RIGHT_START, false)
		2:  # OBJACTION_ATTACK
			set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)
			_action_directed(OBJSTATE_ATTACKED_LEFT_START, OBJSTATE_ATTACKED_RIGHT_START, false)
		3:  # OBJACTION_PICK_UP
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			set_cur(OBJ_ACTION, 15 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_PICKED_UP_RIGHT_START if wDirection == DIRECTION_LEFT
					else OBJSTATE_PICKED_UP_LEFT_START)
		4:  # OBJACTION_WOBBLE
			_action_directed(OBJSTATE_WOBBLE_LEFT_START, OBJSTATE_WOBBLE_RIGHT_START, true)
		5:  # OBJACTION_VANISH_TOUCH
			set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)
			set_cur(OBJ_ACTION, 15 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)
		6, 0x12:  # OBJACTION_06, OBJACTION_12
			set_cur(OBJ_ACTION, (15 if a == 6 else 7) | (1 << 7))
			var direction: int = cur(OBJ_UNK_1D)
			if (direction & INTERACTION_DOWN) != 0:
				set_cur(OBJ_STATE, OBJSTATE_0E)
			elif (direction & INTERACTION_UP) != 0:
				set_cur(OBJ_STATE, OBJSTATE_0D)
			elif (direction & INTERACTION_RIGHT) != 0:
				set_cur(OBJ_STATE, OBJSTATE_0B)
			else:
				set_cur(OBJ_STATE, OBJSTATE_0C)
		7:  # OBJACTION_07
			set_cur(OBJ_ACTION, 0)
			set_cur(OBJ_STATE, OBJSTATE_18)
		8:  # OBJACTION_VANISH_TREASURE
			vanish_object()
		9:  # OBJACTION_STEP_ON
			set_cur(OBJ_ACTION, 0)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_STEPPED)
		0x0A:
			set_cur(OBJ_ACTION, 15 | (1 << 7))
		0x0B, 0x0C, 0x0E, 0x10, 0x11:  # FLATTEN, 0C, 0E, TELEPORT, 11
			set_cur(OBJ_ACTION, 15 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_ACTIVATE)
		0x0D:
			set_cur(OBJ_ACTION, 15 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_19)
		0x0F:  # OBJACTION_SMASH_ATTACK_WALKABLE
			set_cur(OBJ_ACTION, 2 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_VANISH_TOUCH)
		0x13:
			set_cur(OBJ_ACTION, 15 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_SPECIAL_3)
		_:
			note_unported("DoObjectAction %02x" % a)


## The bump, attack, and wobble actions: OBJ_ACTION waits 15 frames, and the state's direction comes
## from OBJ_UNK_1D's INTERACTION_RIGHT (set: the left variant). Wobble also releases a grab.
func _action_directed(left_state: int, right_state: int, release: bool) -> void:
	if release:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	set_cur(OBJ_ACTION, 15 | (1 << 7))
	set_cur(OBJ_STATE, left_state if (cur(OBJ_UNK_1D) & INTERACTION_RIGHT) != 0 else right_state)


## _VanishObject and VanishObject_NoSFX (the sound is not part of the state): the object becomes
## stars (StarsFunc, ID $30) for 33 frames, 8 pixels higher, without collision.
func vanish_object() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, STARS_FUNC & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	_vanish_object_fields()


## Func_618b4: the vanished look (ID $30, the stars' OAM table and frameset, 33 frames), 8 px higher.
func _vanish_object_fields() -> void:
	set_cur(OBJ_ID, ((STARS_FUNC >> 16) - OBJECT_FUNCTIONS_1_BANK) << 4)
	set_cur_word(OBJ_OAM_PTR, OAM_18C000)
	set_cur_word(OBJ_FRAMESET_PTR, FRAMESET_680C5)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	set_cur(OBJ_STATE_DURATION, 33)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur_word(OBJ_Y_POS, cur_word(OBJ_Y_POS) - 8)


# --- Object mechanics (home/object_mechanics.asm) -------------------------------------------

## SetObjectFramesetPtr: a new frameset, started at its first frame on the next animation step.
func set_object_frameset_ptr(frameset: int) -> void:
	set_cur_word(OBJ_FRAMESET_PTR, frameset)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)


## UpdateObjectAnimation: when the duration runs out, the next (frame, duration) pair; at the $ff
## end, the first pair again.
func update_object_animation() -> void:
	var duration: int = cur(OBJ_FRAME_DURATION) - 1
	set_cur(OBJ_FRAME_DURATION, duration)
	if duration >= 0:
		return
	var pointer: int = cur_word(OBJ_FRAMESET_PTR)
	if not object_framesets.has(pointer):
		note_unported("object frameset %04x" % pointer)
		return
	var data: PackedByteArray = object_framesets[pointer]
	var offset: int = cur(OBJ_FRAMESET_OFFSET)
	if offset >= data.size() or data[offset] == 0xFF:
		set_cur(OBJ_FRAMESET_OFFSET, 2)
		set_cur(OBJ_FRAME, data[0])
		set_cur(OBJ_FRAME_DURATION, data[1])
		return
	set_cur(OBJ_FRAME, data[offset])
	set_cur(OBJ_FRAMESET_OFFSET, offset + 2)
	set_cur(OBJ_FRAME_DURATION, data[offset + 1])


## UpdateObjectFrame: OBJ_FRAME from the frameset when the duration is 0, without advancing it.
func update_object_frame() -> void:
	if cur(OBJ_FRAME_DURATION) >= 1:
		return
	var pointer: int = cur_word(OBJ_FRAMESET_PTR)
	if not object_framesets.has(pointer):
		note_unported("object frameset %04x" % pointer)
		return
	var data: PackedByteArray = object_framesets[pointer]
	var offset: int = cur(OBJ_FRAMESET_OFFSET)
	var frame: int = data[offset] if offset < data.size() else 0xFF
	set_cur(OBJ_FRAME, data[0] if frame == 0xFF else frame)


## CheckObjectOnScreen: OBJFLAG_ON_SCREEN from a window around the camera; an object far outside a
## larger window is despawned (or just cleared), unless OBJSUBFLAG_UNK_4 keeps it. Translated
## register by register: b:c is the Y position, d:e the X position, h:l a camera coordinate.
func check_object_on_screen() -> void:
	var y: int = cur_word(OBJ_Y_POS)
	var x: int = cur_word(OBJ_X_POS)
	var on_screen: int = _object_screen_window(y, x)
	if on_screen == 1:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_ON_SCREEN)
	elif on_screen == 0 or (cur(OBJ_STATE) & 0xFE) != OBJSTATE_48:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_ON_SCREEN)
	if _object_far_outside(y, x):
		var sub: int = cur(OBJ_SUBSTATE) & (0x0F | OBJSUBFLAG_UNK_4)
		if sub >= OBJSUBFLAG_UNK_4:
			return
		if sub != 0:
			despawn_cur_object()
		else:
			set_cur(OBJ_FLAGS, 0)


## 1 on screen, 0 outside, -1 above or left of the window in Y (the original then keeps the flag
## for OBJSTATE_48 and its pair).
func _object_screen_window(y: int, x: int) -> int:
	var cam_y: int = wCameraSCY
	var y_ok: bool = false
	var b: int = y >> 8
	var c: int = (y & 0xFF) + 24
	var go_second: bool = false
	if c > 0xFF:
		c &= 0xFF
		b = (b + 1) & 0xFF
		if b == 0:
			go_second = true
	if not go_second:
		var y1: int = (b << 8) | c
		if y1 < cam_y:
			return -1
		if y1 == cam_y:
			y_ok = true
		else:
			go_second = true
	if go_second:
		var cam2: int = (cam_y + SCREEN_HEIGHT_PX) & 0xFFFF
		var y1b: int = (b << 8) | c
		if y1b < 56:
			y_ok = true
		elif ((y1b - 56) & 0xFFFF) < cam2:
			y_ok = true
		else:
			return -1
	var cam_x: int = wCameraSCX
	var d: int = x >> 8
	var e: int = (x & 0xFF) + 24
	if e > 0xFF:
		e &= 0xFF
		d = (d + 1) & 0xFF
		if d == 0:
			return 1
	var x1: int = (d << 8) | e
	if x1 < cam_x:
		return 0
	if x1 == cam_x:
		return 1
	var cam_x2: int = (cam_x + SCREEN_WIDTH_PX) & 0xFFFF
	if x1 < 0x30:
		return 1
	return 1 if ((x1 - 0x30) & 0xFFFF) < cam_x2 else 0


## The despawn window: true when the object is beyond it (or its position's high bit is set).
func _object_far_outside(y: int, x: int) -> bool:
	if (x & 0x8000) != 0 or (y & 0x8000) != 0:
		return true
	var cam_y: int = wCameraSCY
	var b: int = y >> 8
	var c: int = (y & 0xFF) + 92
	var x_check: bool = false
	if c > 0xFF:
		c &= 0xFF
		b = (b + 1) & 0xFF
		if b == 0:
			x_check = true
	if not x_check:
		var y1: int = (b << 8) | c
		if y1 < cam_y:
			return true
		if y1 == cam_y:
			x_check = true
		else:
			var cam2: int = (cam_y + 0x90) & 0xFFFF
			if y1 < 0xCB:
				x_check = true
			elif ((y1 - 0xCB) & 0xFFFF) < cam2:
				x_check = true
			else:
				return true
	var cam_x: int = wCameraSCX
	var d: int = x >> 8
	var e: int = (x & 0xFF) + 0x6F
	if e > 0xFF:
		e &= 0xFF
		d = (d + 1) & 0xFF
		if d == 0:
			return false
	var x1: int = (d << 8) | e
	if x1 < cam_x:
		return true
	if x1 == cam_x:
		return false
	var cam_x2: int = (cam_x + SCREEN_WIDTH_PX) & 0xFFFF
	if x1 < 0xDE:
		return false
	return ((x1 - 0xDE) & 0xFFFF) >= cam_x2


## DespawnObject (block_queue.asm) for wCurObj: its map byte gets bit 7 back, so it spawns again when
## next streamed in, and the object is cleared. OBJ_UNK_02 holds the map row as an SRAM page
## ($a0 + row, plus $20 per bank after the first) and OBJ_UNK_01 the column.
func despawn_cur_object() -> void:
	var row: int = cur(OBJ_UNK_02) - 0xA0
	var column: int = cur(OBJ_UNK_01)
	set_cur(OBJ_FLAGS, 0)
	if level != null and row >= 0:
		level.set_block(row, column, level.block_at(row, column) | 0x80)


## Func_ba42 (block_queue.asm) for wCurObj: the object's nibble in the object map becomes `value`,
## its map byte gets bit 7 back (as DespawnObject), and the cell's new object spawns at once
## (Func_d3e's position, the cell's middle bottom, then SpawnObject: the first free slot, if any).
func set_cur_object_map_nibble(value: int) -> void:
	var row: int = cur(OBJ_UNK_02) - 0xA0
	var column: int = cur(OBJ_UNK_01)
	if level == null or row < 0 or row >= level.object_rows.size():
		return
	var byte_index: int = column >> 1
	var old: int = level.object_rows[row][byte_index]
	level.object_rows[row][byte_index] = ((old & 0x0F) | (value << 4)) if (column & 1) == 0 else ((old & 0xF0) | value)
	level.set_block(row, column, level.block_at(row, column) | 0x80)
	hYPos = row * 16 + 16
	hXPos = column * 16 + 8
	spawn_object(row, column, value)


## Func_bb2d (block_queue.asm) for wCurObj: the object's nibble in the object map is cleared, so it
## never spawns again (collected).
func clear_cur_object_from_map() -> void:
	var row: int = cur(OBJ_UNK_02) - 0xA0
	var column: int = cur(OBJ_UNK_01)
	if level == null or row < 0 or row >= level.object_rows.size():
		return
	var byte_index: int = column >> 1
	var value: int = level.object_rows[row][byte_index]
	level.object_rows[row][byte_index] = (value & 0x0F) if (column & 1) == 0 else (value & 0xF0)
