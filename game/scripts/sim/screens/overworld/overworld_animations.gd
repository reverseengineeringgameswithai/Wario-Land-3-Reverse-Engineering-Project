class_name OverworldAnimations
extends OverworldInit
## The map side's animations each loop, translated (WL3-052): UpdateMapSideOWAnimations (bank $2d:
## the scene objects whose states change by themselves: the falling leaves, the tornado, the elevator,
## the snakes, the full moon...) and UpdateCommonOWAnimations (bank $76: the clouds' and sea's tiles
## built in wTilemap from tile $24 for the V-Blank's DMA, and the cliffs' DMA source in w2d044).

const W_SCENE_OBJ_UNK7: int = 7  # scene_obj_struct's last byte
const W2D124: int = 0xD124
const W2D125: int = 0xD125
const W2D12A: int = 0xD12A
const W2D12B: int = 0xD12B
const W2D12D: int = 0xD12D
const W2D12F: int = 0xD12F
const DATA_B6337: int = 0x6337  # bank $2d: the tornado's movement
const OVERWORLD_CLIFFS_1_GFX: int = 0x4600  # bank $76


## SetSceneObjState (src/home/overworld.asm): the object's state, its animation restarted.
func set_scene_obj_state(number: int, state: int) -> void:
	var obj: int = scene_obj(number)
	wr(obj + SCENE_OBJ_STATE, state)
	wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
	wr(obj + SCENE_OBJ_DURATION, 0)


## ApplyOWMovement (src/home/overworld.asm): the object at `obj` moved by the (y, x) step its unk7
## counts to in the table at (`bank`, the caller's: $2d on the map side, `table`); at the table's $80 the
## count starts again. True when it starts again.
func apply_ow_movement(obj: int, table: int, bank: int = 0x2D, mirrored: bool = false) -> bool:
	var count: int = rd(obj + W_SCENE_OBJ_UNK7)
	wr(obj + W_SCENE_OBJ_UNK7, count + 1)
	var at: int = (table + count * 2) & 0xFFFF
	wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) + rb(bank, at))
	# ApplyOWMovement_Mirrored takes the x step off
	wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) + (-rb(bank, at + 1) if mirrored else rb(bank, at + 1)))
	if rb(bank, at + 2) != 0x80:
		return false
	wr(obj + W_SCENE_OBJ_UNK7, 0)
	return true


# --- UpdateMapSideOWAnimations (bank $2d) ---

## UpdateMapSideOWAnimations: by map side, the objects whose states lead somewhere by themselves.
func update_map_side_ow_animations() -> void:
	match r2(W_CUR_MAP_SIDE) & 3:
		NORTH:
			for number: int in [2, 3, 6, 7, 14, 15]:
				_func_b7984(rd(scene_obj(number) + SCENE_OBJ_STATE))
		WEST:
			for number: int in [1, 7, 8, 5]:
				_func_b7a6d(rd(scene_obj(number) + SCENE_OBJ_STATE))
		SOUTH:
			for number: int in [7, 14, 15]:
				_func_b7c18(rd(scene_obj(number) + SCENE_OBJ_STATE))
		EAST:
			for number: int in [5, 7]:
				_func_b7b61(rd(scene_obj(number) + SCENE_OBJ_STATE))


## Func_b7984 (North) by the object's state.
func _func_b7984(state: int) -> void:
	match state:
		0x05:  # the garlic: gone once Wario reaches Sea Turtle Rocks
			if r2(W_CUR_EVENT) == 0 and r2(W_LEVEL_2) == 0x06:
				set_scene_obj_state(3, 0x06)  # (a sound, not ported)
		0x0E:  # the snake
			_func_b7a32()
		0x10, 0x11, 0x12, 0x13:
			_func_b542e()
		0x18:
			if r2(W2D011) == 0:
				set_scene_obj_state(15, 0x17)
		0x19:
			if r2(W2D011) != 0:
				set_scene_obj_state(15, 0x16)
		0x1A:
			if r2(W2D011) == 0:
				set_scene_obj_state(14, 0x1B)
		0x1B:
			if r2(W2D011) != 0:
				set_scene_obj_state(14, 0x1A)
		_:
			if state >= 0x2C:
				_note("Func_b7984 state $%02x (past its table)" % state)


## Func_b7984.Func_b7a32: the North snake's appearances: w2d125 counts 120 loops while it may appear,
## then wSceneObj2 shows ($0d, w2d124 set) or hides ($1d).
func _func_b7a32() -> void:
	if _func_b7a5a():
		w2(W2D125, r2(W2D125) + 1)
		if r2(W2D125) < 0x78:
			return
	w2(W2D125, 0)
	w2(W2D124, 0)
	if _func_b7a5a():
		set_scene_obj_state(2, 0x1D)
	else:
		w2(W2D124, 0x01)
		set_scene_obj_state(2, 0x0D)


## .Func_b7a5a: nz (true) unless a scene plays, w2d124 is set, or Wario is at level 2 or 7.
func _func_b7a5a() -> bool:
	if r2(W_CUR_EVENT) != 0 or r2(W2D124) != 0:
		return true
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	return level != 0x02 and level != 0x07


## Func_b542e: the falling leaves (wSceneObj6 by w2d12c and its counter w2d12d, wSceneObj7 by
## w2d12e and w2d12f).
func _func_b542e() -> void:
	_falling_leaf(6, W2D12C)
	_falling_leaf(7, W2D12E)


## Func_b542e.Func_b5435 and .Func_b54ba: a leaf's steps (its step and counter at `step`, `step` + 1).
func _falling_leaf(number: int, step: int) -> void:
	var leaf_step: int = r2(step)
	if leaf_step == 0:
		return
	w2(step + 1, r2(step + 1) + 1)
	var counter: int = r2(step + 1)
	var obj: int = scene_obj(number)
	match leaf_step - 1:
		0:
			if counter < 0x78:
				return
			set_scene_obj_state(number, 0x12)
		1:
			if counter < 0x5A:
				return
			set_scene_obj_state(number, 0x13)
		2:
			if counter < 0x28:
				return
			set_scene_obj_state(number, 0x10)
			wr(obj + SCENE_OBJ_Y, 0x38)
		3:
			if counter < 0x5A:
				return
		4:
			if (counter & 0x0F) != 0:
				return
			wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) + 1)
			if rd(obj + SCENE_OBJ_Y) != 0x48:
				return
		5:
			if rd(obj + SCENE_OBJ_FRAME) != 0x46 or rd(obj + SCENE_OBJ_Y) == 0:
				return
			set_scene_obj_state(number, 0x11)
			w2(step, 0x01)
			w2(step + 1, 0)
			return
		_:
			_note("Func_b542e step %d (past its table)" % leaf_step)
			return
	w2(step, r2(step) + 1)
	w2(step + 1, 0)


## Func_b7a6d (West) by the object's state.
func _func_b7a6d(state: int) -> void:
	match state:
		0x02:  # Func_b7ab7: the tornado
			if r2(W_CUR_EVENT) != 0x04:
				apply_ow_movement(scene_obj(1), DATA_B6337)  # UpdateOWTornado (its sound not ported)
		0x06:  # Func_b7ac0: the elevator going up, by day or night
			_func_b7ac0()
		0x08:  # Func_b7afb
			_func_b7afb()
		0x11:  # Func_b7b26: the West snake
			_func_b7b26()
		_:
			if state >= 0x24:
				_note("Func_b7a6d state $%02x (past its table)" % state)


func _func_b7ac0() -> void:
	if r2(W_CUR_EVENT) != 0:
		return
	var unk7: int = scene_obj(8) + W_SCENE_OBJ_UNK7
	if rd(unk7) == 0:
		if rd(scene_obj(7) + SCENE_OBJ_STATE) != 0 or r2(W_OW_PAL_TRANSITION_STATE) != 0:
			return
		wr(unk7, rd(unk7) + 1)
	if r2(W2D011) != 0:  # at night the elevator (wSceneObj8) goes down at once, wSceneObj7 stopped
		wr(scene_obj(8) + SCENE_OBJ_STATE, 0x08)
		wr(scene_obj(8) + SCENE_OBJ_DURATION, 0)
		set_scene_obj_state(7, 0x00)
	elif r2(W_OW_PAL_TRANSITION_STATE) != 0x02:
		return
	else:
		set_scene_obj_state(7, 0x07)
	wr(unk7, 0)


func _func_b7afb() -> void:
	if r2(W_CUR_EVENT) != 0:
		return
	var unk7: int = scene_obj(8) + W_SCENE_OBJ_UNK7
	if rd(unk7) == 0:
		if r2(W_OW_PAL_TRANSITION_STATE) != 0:
			return
		wr(unk7, rd(unk7) + 1)
	if r2(W2D011) != 0 and r2(W_OW_PAL_TRANSITION_STATE) != 0x02:
		return
	wr(scene_obj(8) + SCENE_OBJ_STATE, 0x06)
	wr(scene_obj(8) + SCENE_OBJ_DURATION, 0)
	wr(unk7, 0)


## Func_b7b26: the West snake's appearances (w2d12b counting, w2d12a; wSceneObj5 $10 or $13).
func _func_b7b26() -> void:
	if _func_b7b4e():
		w2(W2D12B, r2(W2D12B) + 1)
		if r2(W2D12B) < 0x78:
			return
	w2(W2D12B, 0)
	w2(W2D12A, 0)
	if _func_b7b4e():
		set_scene_obj_state(5, 0x13)
	else:
		w2(W2D12A, 0x01)
		set_scene_obj_state(5, 0x10)


func _func_b7b4e() -> bool:
	if r2(W_CUR_EVENT) != 0 or r2(W2D12A) != 0:
		return true
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	return level != 0x01 and level != 0x02


## Func_b7b61 (East) by the object's state.
func _func_b7b61(state: int) -> void:
	match state:
		0x12:  # Func_b7ba9
			if _func_b7be9():
				return
			if r2(W2D011) != 0:
				if r2(W_OW_PAL_TRANSITION_STATE) == 0x02:
					set_scene_obj_state(7, 0x13)
			elif r2(W_OW_PAL_TRANSITION_STATE) == 0:
				set_scene_obj_state(7, 0x13)
		0x13:  # Func_b7bc9
			if _func_b7be9():
				return
			if r2(W2D011) == 0:
				if r2(W_OW_PAL_TRANSITION_STATE) == 0x02:
					set_scene_obj_state(7, 0x12)
			elif r2(W_OW_PAL_TRANSITION_STATE) == 0:
				set_scene_obj_state(7, 0x12)
		0x19:  # Func_b7c05
			if r2(W_CUR_EVENT) == 0:
				w2(W2D12B, r2(W2D12B) + 1)
				if r2(W2D12B) == 0:
					set_scene_obj_state(5, 0x1A)
		_:
			if state >= 0x23:
				_note("Func_b7b61 state $%02x (past its table)" % state)


## Func_b7be9: nz (true) in an UNLOCK_LEVEL or HIGHLIGHT_LEVEL scene (wSceneObj7 stopped), or while a
## scene plays.
func _func_b7be9() -> bool:
	var action: int = r2(W_OW_SCENE_ACTION)
	if action == UNLOCK_LEVEL or action == HIGHLIGHT_LEVEL:
		set_scene_obj_state(7, 0)
		return true
	return r2(W_CUR_EVENT) != 0


## Func_b7c18 (South) by the object's state.
func _func_b7c18(state: int) -> void:
	match state:
		0x15:  # Func_b7c5c: the South snake
			_func_b7c5c()
		0x1E:  # Func_b7c97
			if r2(W2D011) == 0:
				set_scene_obj_state(15, 0x1F)
		0x1F:  # Func_b7ca5
			if r2(W2D011) != 0:
				set_scene_obj_state(15, 0x1E)
		0x20:  # Func_b7cb3: the full moon rising
			_func_b7cb3()
		_:
			if state >= 0x21:
				_note("Func_b7c18 state $%02x (past its table)" % state)


func _func_b7c5c() -> void:
	if _func_b7c84():
		w2(W2D12F, r2(W2D12F) + 1)
		if r2(W2D12F) < 0x78:
			return
	w2(W2D12F, 0)
	w2(W2D12E, 0)
	if _func_b7c84():
		set_scene_obj_state(7, 0x1D)
	else:
		w2(W2D12E, 0x01)
		set_scene_obj_state(7, 0x14)


func _func_b7c84() -> bool:
	if r2(W_CUR_EVENT) != 0 or r2(W2D12E) != 0:
		return true
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	return level != 0x00 and level != 0x01


## Func_b7cb3: the moon (wSceneObj14) rises up and right every 4 loops (wGlobalCounter): at night
## from ($25, $70) until x $80; by day from where it is until x $70 (or back to ($25, $70) at x $88).
func _func_b7cb3() -> void:
	if r2(W_CUR_EVENT) != 0:
		return
	var moon: int = scene_obj(14)
	if r2(W2D07C) != 0:
		if rd(moon + SCENE_OBJ_X) == 0x80:
			return
		if r2(W2D07D) == 0:
			w2(W2D07D, r2(W2D07D) + 1)
			wr(moon + SCENE_OBJ_Y, 0x25)
			wr(moon + SCENE_OBJ_X, 0x70)
		if (sim.wGlobalCounter & 0x03) != 0:
			return
		wr(moon + SCENE_OBJ_Y, rd(moon + SCENE_OBJ_Y) - 1)
		wr(moon + SCENE_OBJ_X, rd(moon + SCENE_OBJ_X) + 1)
		return
	if rd(moon + SCENE_OBJ_X) == 0x70:
		return
	if r2(W2D07D) == 0:
		w2(W2D07D, r2(W2D07D) + 1)
	if (sim.wGlobalCounter & 0x03) != 0:
		return
	wr(moon + SCENE_OBJ_Y, rd(moon + SCENE_OBJ_Y) - 1)
	wr(moon + SCENE_OBJ_X, rd(moon + SCENE_OBJ_X) + 1)
	if rd(moon + SCENE_OBJ_X) != 0x88:
		return
	wr(moon + SCENE_OBJ_Y, 0x25)
	wr(moon + SCENE_OBJ_X, 0x70)


# --- UpdateCommonOWAnimations (bank $76) ---

## UpdateCommonOWAnimations: the four big clouds' and the small clouds' and sea's frames (each a
## speed, a counter, a frame) copied into wTilemap from tile $24 (w2d031 bits 0 and 1 say which), then
## the cliffs' frame (w2d046 to w2d048) as the DMA source in w2d044.
func update_common_ow_animations() -> void:
	w2(W2D031, 0)
	_update_big_clouds(W2D032, 0x00)
	_update_big_clouds(W2D035, 0x20)
	_update_big_clouds(W2D038, 0x40)
	_update_big_clouds(W2D03B, 0x60)
	_update_sea(W2D03E, 0x00)
	_update_small_clouds(W2D041, 0x20)
	w2(W2D044, 0)
	var speed: int = r2(W2D046)
	if speed == 0:
		return
	w2(W2D047, r2(W2D047) + 1)
	if speed - 1 >= r2(W2D047):
		return
	w2(W2D047, 0)
	var frame: int = r2(W2D048) + 1
	if frame == 0x04:
		frame = 0
	w2(W2D048, frame)
	w2(W2D044, frame + (OVERWORLD_CLIFFS_1_GFX >> 8))
	w2(W2D044 + 1, ((frame << 6) | (frame >> 2)) & 0xFF)  # rrca twice


## The counting the animations share: false until the counter after `speed` passes speed - 1, then
## the counter is cleared.
func _animation_due(speed_at: int) -> bool:
	var speed: int = r2(speed_at)
	if speed == 0:
		return false
	w2(speed_at + 1, r2(speed_at + 1) + 1)
	if speed - 1 >= r2(speed_at + 1):
		return false
	w2(speed_at + 1, 0)
	return true


## .UpdateBigClouds: the next of 4 frames (2 tiles each, by wCloudType) into wTilemap tile $24 + c.
func _update_big_clouds(speed_at: int, c: int) -> void:
	if not _animation_due(speed_at):
		return
	var frame: int = (r2(speed_at + 2) + 1) & 0x03
	w2(speed_at + 2, frame)
	var offset: int = (((frame >> 1) + ((r2(W_CLOUD_TYPE) << 1) & 0xFF)) << 8) | ((frame & 1) << 7)
	copy_rom(CLOUDS_BANK, (OVERWORLD_CLOUDS_1_GFX + offset + c) & 0xFFFF, W_TILEMAP + 0x24 * 0x10 + c, 0x20)
	w2(W2D031, r2(W2D031) | 0x01)


## .UpdateSmallClouds: the next of 4 frames from OverworldSeaGfx (by w2d049) into tile $2c + c.
func _update_small_clouds(speed_at: int, c: int) -> void:
	if not _animation_due(speed_at):
		return
	var frame: int = (r2(speed_at + 2) + 1) & 0x03
	w2(speed_at + 2, frame)
	var offset: int = (r2(W2D049) << 8) | swap((frame << 2) & 0xFF)
	copy_rom(CLOUDS_BANK, (OVERWORLD_SEA_GFX + offset + c) & 0xFFFF, W_TILEMAP + 0x2C * 0x10 + c, 0x20)
	w2(W2D031, r2(W2D031) | 0x02)


## .UpdateSea: the sea's 6 frames (tiles 0, 1, 2, 3, 2, 1 of OverworldSeaGfx) into tile $2c + c.
func _update_sea(speed_at: int, c: int) -> void:
	if not _animation_due(speed_at):
		return
	var frame: int = r2(speed_at + 2) + 1
	if frame == 0x06:
		frame = 0
	w2(speed_at + 2, frame)
	var rotated: int = frame
	if frame == 0x04:
		rotated = (frame << 1) & 0xFF
	elif frame != 0x05:
		rotated = (frame << 2) & 0xFF
	var offset: int = (r2(W2D049) << 8) | swap(rotated & 0x0C)
	copy_rom(CLOUDS_BANK, (OVERWORLD_SEA_GFX + offset + c) & 0xFFFF, W_TILEMAP + 0x2C * 0x10 + c, 0x20)
	w2(W2D031, r2(W2D031) | 0x02)
