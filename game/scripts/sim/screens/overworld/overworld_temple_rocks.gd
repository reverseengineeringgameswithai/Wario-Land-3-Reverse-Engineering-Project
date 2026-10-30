class_name OverworldTempleRocks
extends OverworldPrologue
## The Temple's shake and falling rocks in the hidden figure's reveal (_HandleTempleShakeAndRocks,
## src/engine/overworld/bank56.asm), translated (WL3-052): the screen shaken left and right by wSCX (a
## slow then a fast round, again and again while w2d896 is set), six rocks falling from the top (scene
## objects 12, 13, 14, 15, 1, 2) and four bouncing in from the bottom (8, 9, 10, 11), each a
## temple_rock_struct (its action, counter, size, and respawn time) that the reveal starts by its size.
## Where a rock spawns and how long it waits read rDIV. The sounds are not ported.

const TEMPLE_ROCKS_BANK: int = 0x56
const W2D896: int = 0xD896  # the shake's step (0: none), then its counter
const W2D897: int = 0xD897
const W_TEMPLE_ROCKS: int = 0xD8B0  # wTempleRock1 to wTempleRock10, temple_rock_struct each
const TEMPLE_ROCK_STRUCT_LENGTH: int = 4
const TEMPLE_ROCK_ACTION: int = 0
const TEMPLE_ROCK_COUNTER: int = 1
const TEMPLE_ROCK_SIZE: int = 2
const TEMPLE_ROCK_RESPAWN_TIME: int = 3
const TEMPLE_ROCK_SIZE_LARGE: int = 2
const GET_ROCK_Y_VEL_TABLE: int = 0x432C  # GetRockYVel.y_vel_table, by the rock's counter (to $2b)
const DATA_158897: int = 0x4897  # a slow bounce's steps (ApplyOWMovement)
const DATA_1588DE: int = 0x48DE  # a fast bounce's steps
## temple_rock_fall's rocks, in _HandleTempleShakeAndRocks's order: [rock number, scene object, may be
## large, x left, x right, the y it stops at, its .Spawn's and .Update's rDIV reads (the instruction
## after each)].
const FALLING_ROCKS: Array = [
	[1, 12, true, 32, 48, 96, 0x4123, 0x4159],
	[2, 13, true, 112, 128, 96, 0x4228, 0x425E],
	[3, 14, false, 40, 56, 96, 0x417A, 0x41B0],
	[4, 15, false, 104, 120, 96, 0x427F, 0x42B5],
	[5, 1, false, 16, 64, 160, 0x41D1, 0x4207],
	[6, 2, false, 96, 144, 160, 0x42D6, 0x430C],
]
## temple_rock_bounce's rocks: [rock number, scene object, fast, to the right (mirrored), x left, x
## right, its .Spawn's rDIV read].
const BOUNCING_ROCKS: Array = [
	[7, 8, false, false, 32, 40, 0x4366],
	[8, 9, false, true, 120, 128, 0x43AD],
	[9, 10, true, false, 24, 32, 0x43F4],
	[10, 11, true, true, 128, 136, 0x4440],
]


## _HandleTempleShakeAndRocks: the shake, rocks 1 to 6 falling, rocks 7 to 10 bouncing.
func handle_temple_shake_and_rocks() -> void:
	handle_temple_screen_shake()
	for rock: Array in FALLING_ROCKS:
		_handle_temple_rock_fall(rock)
	for rock: Array in BOUNCING_ROCKS:
		_handle_temple_rock_bounce(rock)


## HandleTempleScreenShake: with w2d896 set, its counter (w2d897) counts and by w2d896: set up (1: the
## scroll and the shake cleared), the next step (2, 11), a slow round (3 to 10: a pixel left or right
## every 2 loops, a sound at its start; its last step goes back 7), a fast round (12 to 20: two pixels,
## a sound at its start; its last step goes back 7).
func handle_temple_screen_shake() -> void:
	var step: int = r2(W2D896)
	if step == 0:
		return
	w2(W2D897, r2(W2D897) + 1)
	match step - 1:
		0:  # .Init
			w2(W2D897, 0)
			w2(W2D896, 0)
			sim.wSCX = 0
			sim.wSCY = 0
		1, 10:  # .Next
			_next_shake_step()
		2, 4, 6, 8, 11:  # .SlowScrollLeft (2 .SlowScrollLeftWithSFX: a sound, not ported)
			_shake(-1, false)
		3, 5, 7:  # .SlowScrollRight
			_shake(1, false)
		9:  # .SlowScrollRightAndReset
			_shake(1, true)
		12, 14, 16, 18:  # .FastScrollRight (12 .FastScrollRightWithSFX: a sound, not ported)
			_shake(2, false)
		13, 15, 17:  # .FastScrollLeft
			_shake(-2, false)
		19:  # .FastScrollLeftAndReset
			_shake(-2, true)
		var past:
			_note("HandleTempleScreenShake step %d (past its table)" % (past + 1))


## .Next: the counter cleared, the next step.
func _next_shake_step() -> void:
	w2(W2D897, 0)
	w2(W2D896, r2(W2D896) + 1)


## A scroll step: from the counter's second loop on, wSCX moved by `pixels`; then the next step, or
## (`reset`) the counter cleared and the steps 7 back.
func _shake(pixels: int, reset: bool) -> void:
	if r2(W2D897) < 2:
		return
	sim.wSCX = byte(sim.wSCX + pixels)
	if not reset:
		_next_shake_step()
		return
	w2(W2D897, 0)
	w2(W2D896, r2(W2D896) - 0x07)


## temple_rock_fall: the rock's counter counts; by its action: none (0), spawned at the top (1: its x
## by rDIV's bit 3, its scene object's state by its size), falling (2: its y by GetRockYVel, until the
## bottom: hidden, its respawn time from rDIV, a sound), waiting to respawn (3, Func_1580c8).
func _handle_temple_rock_fall(rock: Array) -> void:
	var at: int = _temple_rock(int(rock[0]))
	var obj: int = scene_obj(int(rock[1]))
	w2(at + TEMPLE_ROCK_COUNTER, r2(at + TEMPLE_ROCK_COUNTER) + 1)
	match r2(at + TEMPLE_ROCK_ACTION):
		0:  # StubTempleRockFunc
			pass
		1:  # .Spawn
			var random: int = sim.read_div((TEMPLE_ROCKS_BANK << 16) | int(rock[6]))
			_spawn_rock(obj, 0x00, int(rock[3]), int(rock[4]), random)  # SpawnRock_Top
			if bool(rock[2]):
				_set_temple_rock_size_with_large(int(rock[1]), r2(at + TEMPLE_ROCK_SIZE), random)
			else:
				_set_temple_rock_size_without_large(int(rock[1]), r2(at + TEMPLE_ROCK_SIZE), random)
			_next_temple_rock_action(at)
		2:  # .Update
			var y: int = byte(rd(obj + SCENE_OBJ_Y) + _get_rock_y_vel(at))
			wr(obj + SCENE_OBJ_Y, y)
			if y < int(rock[5]):
				return
			wr(obj + SCENE_OBJ_STATE, 0)
			var mask: int = 0x1F if r2(at + TEMPLE_ROCK_SIZE) == TEMPLE_ROCK_SIZE_LARGE else 0x3F
			w2(at + TEMPLE_ROCK_RESPAWN_TIME, sim.read_div((TEMPLE_ROCKS_BANK << 16) | int(rock[7])) & mask)
			_next_temple_rock_action(at)  # (PlayFallingRockSFX: a sound, not ported)
		3:  # .Reset
			_func_1580c8(at)
		var action:
			_note("temple_rock_fall rock %d action %d (past its table)" % [int(rock[0]), action])


## temple_rock_bounce (its counter does not count by itself): by its action: none (0), spawned at the
## bottom (1: y $60, its x by rDIV's bit 3, a small or medium rock, a sound), bouncing (2: a slow bounce
## through Data_158897, or a fast one through Data_1588de twice a loop, to the right mirrored), reset
## (3: to spawn again with a size set, else none; hidden).
func _handle_temple_rock_bounce(rock: Array) -> void:
	var at: int = _temple_rock(int(rock[0]))
	var obj: int = scene_obj(int(rock[1]))
	var mirrored: bool = bool(rock[3])
	match r2(at + TEMPLE_ROCK_ACTION):
		0:  # StubTempleRockFunc
			pass
		1:  # .Spawn
			var random: int = sim.read_div((TEMPLE_ROCKS_BANK << 16) | int(rock[6]))
			_spawn_rock(obj, 0x60, int(rock[4]), int(rock[5]), random)  # SpawnRock_Bottom
			_set_temple_rock_size_without_large(int(rock[1]), r2(at + TEMPLE_ROCK_SIZE), random)
			_next_temple_rock_action(at)  # (PlayFallingRockSFX: a sound, not ported)
		2:  # .Update
			if bool(rock[2]):
				for _repeat: int in 2:  # BounceTempleRockLeft, BounceTempleRockRight
					if _apply_rock_movement(obj, DATA_1588DE, mirrored):
						_next_temple_rock_action(at)
						return
				return
			if _apply_rock_movement(obj, DATA_158897, mirrored):
				_next_temple_rock_action(at)
		3:  # .Reset
			w2(at + TEMPLE_ROCK_ACTION, 1 if r2(at + TEMPLE_ROCK_SIZE) != 0 else 0)
			wr(obj + SCENE_OBJ_STATE, 0)
		var action:
			_note("temple_rock_bounce rock %d action %d (past its table)" % [int(rock[0]), action])


## wTempleRock1 to wTempleRock10 by number.
static func _temple_rock(number: int) -> int:
	return W_TEMPLE_ROCKS + (number - 1) * TEMPLE_ROCK_STRUCT_LENGTH


## .Next: the rock's counter cleared, its next action.
func _next_temple_rock_action(at: int) -> void:
	w2(at + TEMPLE_ROCK_COUNTER, 0)
	w2(at + TEMPLE_ROCK_ACTION, r2(at + TEMPLE_ROCK_ACTION) + 1)


## SpawnRock: the scene object at y `y`, its x `left`, or `right` with rDIV's bit 3.
func _spawn_rock(obj: int, y: int, left: int, right: int, random: int) -> void:
	wr(obj + SCENE_OBJ_Y, y)
	wr(obj + SCENE_OBJ_X, right if (random & 0x08) != 0 else left)


## SetTempleRockSize_WithLarge: a small rock (state 9) below TEMPLE_ROCK_SIZE_LARGE, else state 9 (still
## in a, which `ld b, a` keeps) plus rDIV's two low bits (3 taken as 2): states 9 to $0b.
func _set_temple_rock_size_with_large(number: int, size: int, random: int) -> void:
	if size < TEMPLE_ROCK_SIZE_LARGE:
		set_scene_obj_state(number, 0x09)
		return
	var add: int = random & 0x03
	if add == 0x03:
		add -= 1
	set_scene_obj_state(number, 0x09 + add)


## SetTempleRockSize_WithoutLarge: a small rock (state 9) below TEMPLE_ROCK_SIZE_LARGE, else state 9 plus
## rDIV's bit 0: states 9 or $0a.
func _set_temple_rock_size_without_large(number: int, size: int, random: int) -> void:
	if size < TEMPLE_ROCK_SIZE_LARGE:
		set_scene_obj_state(number, 0x09)
		return
	set_scene_obj_state(number, 0x09 + (random & 0x01))


## GetRockYVel: the falling rock's speed by its counter (at $2c on, held at $28).
func _get_rock_y_vel(at: int) -> int:
	var counter: int = r2(at + TEMPLE_ROCK_COUNTER)
	if counter >= 0x2C:
		counter = 0x28
		w2(at + TEMPLE_ROCK_COUNTER, counter)
	return rb(TEMPLE_ROCKS_BANK, GET_ROCK_Y_VEL_TABLE + counter)


## Func_1580c8: once the counter reaches the respawn time, a rock with a size spawns again (action 1,
## its counter running on); one without stops (its counter and action cleared).
func _func_1580c8(at: int) -> void:
	if r2(at + TEMPLE_ROCK_COUNTER) < r2(at + TEMPLE_ROCK_RESPAWN_TIME):
		return
	if r2(at + TEMPLE_ROCK_SIZE) != 0:
		w2(at + TEMPLE_ROCK_ACTION, 1)
		return
	w2(at + TEMPLE_ROCK_COUNTER, 0)
	w2(at + TEMPLE_ROCK_ACTION, 0)


## ApplyOWMovement on bank $56's steps, or ApplyOWMovement_Mirrored (`mirrored`: its x steps taken off).
func _apply_rock_movement(obj: int, table: int, mirrored: bool) -> bool:
	return apply_ow_movement(obj, table, TEMPLE_ROCKS_BANK, mirrored)
