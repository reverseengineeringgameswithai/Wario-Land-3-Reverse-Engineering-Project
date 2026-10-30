class_name OverworldNorthEpilogue
extends OverworldCollection
## The North side's scene after the hidden figure's fight, before the epilogue (NOWFunc_Prologue,
## NorthOWFunctions' NOWFUNC_PROLOGUE, src/engine/overworld/bank2d.asm), translated (WL3-052): the
## screen shakes up and down (Func_b71fc on wSCY), then once hard; scene object 1 changes (state $2b);
## then six scene objects (2, 3, 5, 8, 9, 10) are sent rising up and to the side from near (y $30,
## x $50), each through three spawn points and three paths (Func_15868e, bank $56), with a sound every
## 48 loops. Func_b71fc's sideways shakes (wSCX) are ported for the other OW functions that call it.
## The sounds are not simulated. Research note: docs/02-research/overworld.md.
##
## The OW functions' shared steps (wOWFuncCounter, w2d062, WaitOWFunc, AdvanceOWFunc, EndOWFunc) are
## here, where OverworldOWFunctions after it uses them too.

const W_OW_FUNC_COUNTER: int = 0xD061
const W2D062: int = 0xD062  # the OW function's (or the scene action's) step
## wOWUIObj1 and wOWUIObj2 (W_OW_UI_OBJ_1, _2) as Func_b71fc and .Func_b59e5 use their bytes.
const W_OW_UI_OBJ_1_Y_COORD: int = 0xD140  # Func_b71fc's step (0: none)
const W_OW_UI_OBJ_1_X_COORD: int = 0xD141  # counts while a step is set
const W_OW_UI_OBJ_1_FRAME: int = 0xD142  # .Func_b7273's step (0: none)
const W_OW_UI_OBJ_1_ATTRIBUTES: int = 0xD143  # .Func_b7273's loops on a step
const W_OW_UI_OBJ_2_ATTRIBUTES: int = 0xD14B  # .Func_b59e5's sound repeats
const W_OW_UI_OBJ_2_DURATION: int = 0xD14C  # .Func_b59e5's sound timer
const UI_SFX_PERIOD: int = 0x30
## Func_15868e (bank $56) and its paths, as ApplyOWMovement steps (y, x) to $80.
const SCENE_RISERS_BANK: int = 0x56
const RISE_WIDE: int = 0x4897  # Data_158897: 35 loops, 38 up and 50 to the side in all
const RISE_STEEP: int = 0x48DE  # Data_1588de: 35 loops, 39 up and 9 to the side
const RISE_MID: int = 0x4925  # Data_158925: 35 loops, 37 up and 29 to the side
const DIV_FUNC_15868E: int = 0x56_4873  # .asm_15886e's rDIV read (the instruction after it)
const RISER_STATE: int = 0x29  # .asm_15886e: $29 plus rDIV's bit 0
## The spawn points (y, x), by their routine.
const SPAWN_158869: Array = [0x30, 0x50]
const SPAWN_15887B: Array = [0x2E, 0x4E]
const SPAWN_158882: Array = [0x2E, 0x52]
const SPAWN_158889: Array = [0x31, 0x4F]
const SPAWN_158890: Array = [0x31, 0x51]
## Func_15868e's risers in its call order: [the step's variable, the scene object, mirrored
## (ApplyOWMovement_Mirrored: to the right), steps 1 to 6: a spawn point or a path]; step 7 goes back
## to 1, step 0 is none.
const SCENE_RISERS: Array = [
	[0xD150, 2, false, [SPAWN_15887B, RISE_WIDE, SPAWN_158869, RISE_STEEP, SPAWN_158889, RISE_MID]],  # w2d150 (.Func_1586a1)
	[0xD151, 3, true, [SPAWN_158882, RISE_WIDE, SPAWN_158869, RISE_STEEP, SPAWN_158890, RISE_MID]],  # w2d151 (.Func_158785)
	[0xD152, 5, false, [SPAWN_158869, RISE_STEEP, SPAWN_158889, RISE_MID, SPAWN_15887B, RISE_WIDE]],  # wd152 (.Func_1586ed)
	[0xD153, 8, true, [SPAWN_158869, RISE_STEEP, SPAWN_158890, RISE_MID, SPAWN_158882, RISE_WIDE]],  # wd153 (.Func_1587d1)
	[0xD154, 9, false, [SPAWN_158889, RISE_MID, SPAWN_15887B, RISE_WIDE, SPAWN_158869, RISE_STEEP]],  # wd154 (.Func_158739)
	[0xD155, 10, true, [SPAWN_158890, RISE_MID, SPAWN_158869, RISE_STEEP, SPAWN_158882, RISE_WIDE]],  # wd155 (.Func_15881d)
]
const NUM_RISER_STEPS: int = 7


## NOWFunc_Prologue: each loop the shake (Func_b71fc), the risers (Func_15868e), the sound's repeat
## (.Func_b59e5), then by its step (w2d062): at loop 60 the soft shake starts (its step 1) and the sea
## animates fast (w2d03e's speed 3) from its other frames (w2d049 1); 134 loops on it ends in the hard
## one (its step 4); as that starts (its step 5) scene object 1 changes (state $2b, a sound); once it is
## over the sea goes back (speed $0e, w2d049 0); 86 loops; then every 6 loops a riser starts (the sound
## repeating from the first); 120 loops twice; the sound stops and the function ends.
func nowfunc_prologue() -> void:
	func_b71fc()
	func_15868e()
	_func_b59e5()
	var count: int = r2(W_OW_FUNC_COUNTER)
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Func_b5949
			if count < 60:
				return
			w2(W_OW_UI_OBJ_1_Y_COORD, 0x01)
			w2(W2D049, 0x01)
			w2(W2D03E, 0x03)
			w2(W2D03E + 1, 0)
			w2(W2D03E + 2, 0)
			advance_ow_func()
		2:  # .Func_b5965
			if count < 134:
				return
			w2(W_OW_UI_OBJ_1_Y_COORD, 0x04)
			advance_ow_func()
		3:  # .Func_b5973 (a sound, not simulated)
			if r2(W_OW_UI_OBJ_1_Y_COORD) != 0x05:
				return
			set_scene_obj_state(1, 0x2B)
			advance_ow_func()
		4:  # .Func_b598c
			if r2(W_OW_UI_OBJ_1_Y_COORD) != 0:
				return
			w2(W2D03E, 0x0E)
			w2(W2D03E + 1, 0)
			w2(W2D03E + 2, 0)
			w2(W2D049, 0)
			advance_ow_func()
		5:  # .Func_b59a0
			wait_ow_func(86)
		6:  # .Func_b59a5: w2d150's riser, the sound's repeat on
			if count < 6:
				return
			w2(0xD150, 0x01)
			w2(W_OW_UI_OBJ_2_ATTRIBUTES, 0x01)
			advance_ow_func()
		7:  # .Func_b59ca
			_start_riser(0xD153, count)
		8:  # .Func_b59c5
			_start_riser(0xD152, count)
		9:  # .Func_b59d4
			_start_riser(0xD155, count)
		10:  # .Func_b59cf
			_start_riser(0xD154, count)
		11:  # .Func_b59b6
			_start_riser(0xD151, count)
		12, 13:  # .Func_b59d9
			wait_ow_func(120)
		14:  # .Func_b59de
			w2(W_OW_UI_OBJ_2_ATTRIBUTES, 0)
			end_ow_func()
		var step:
			_note("NOWFunc_Prologue step %d (past its table)" % step)


## .asm_b59b9: from loop 6 the riser whose step is at `at` starts (step 1).
func _start_riser(at: int, count: int) -> void:
	if count < 6:
		return
	w2(at, 0x01)
	advance_ow_func()


## .Func_b59e5: while wOWUIObj2Attributes is set its duration counts; at 1 a sound (SFX_08E, not
## simulated), at $30 back to 0 (the sound every 48 loops).
func _func_b59e5() -> void:
	if r2(W_OW_UI_OBJ_2_ATTRIBUTES) == 0:
		return
	var timer: int = byte(r2(W_OW_UI_OBJ_2_DURATION) + 1)
	w2(W_OW_UI_OBJ_2_DURATION, timer)
	if timer == 0x01:
		return  # .asm_b59f9: SFX_08E
	if timer >= UI_SFX_PERIOD:
		w2(W_OW_UI_OBJ_2_DURATION, 0)


# --- the shake (Func_b71fc, bank $2d) ---

## Func_b71fc: the shake's frame (.Func_b7273), then by its step (wOWUIObj1YCoord, 0: none) with
## wOWUIObj1XCoord counting: 1 starts the soft vertical shake (frame 1) and 2 lets it run; 3 ends it on
## its frame 1; 4 waits for its frame 1 and 6 starts the hard one ($11) at once; 5 and 7 end that on
## its frame $11; 8 and 10 start a sideways one ($15, $1e) that 9 and 11 wait out (frame 0). A start
## clears the counter and steps on.
func func_b71fc() -> void:
	_func_b7273()
	var step: int = r2(W_OW_UI_OBJ_1_Y_COORD)
	if step == 0:
		return
	w2(W_OW_UI_OBJ_1_X_COORD, r2(W_OW_UI_OBJ_1_X_COORD) + 1)
	match step - 1:
		0:  # .Func_b721f
			_start_scroll_shake(0x01)
		1:  # .Func_b721e
			pass
		2:  # .Func_b7231
			_end_scroll_shake_on(0x01)
		3:  # .Func_b723f, falling into .Func_b7245
			if r2(W_OW_UI_OBJ_1_FRAME) == 0x01:
				_start_scroll_shake(0x11)
		4, 6:  # .Func_b7249
			_end_scroll_shake_on(0x11)
		5:  # .Func_b7245
			_start_scroll_shake(0x11)
		7:  # .Func_b7257
			_start_scroll_shake(0x15)
		8, 10:  # .Func_b725b, .Func_b7269: the frame is already 0
			if r2(W_OW_UI_OBJ_1_FRAME) == 0:
				w2(W_OW_UI_OBJ_1_Y_COORD, 0)
		9:  # .Func_b7265
			_start_scroll_shake(0x1E)
		_:
			_note("Func_b71fc step %d (past its table)" % step)


## .asm_b7221: the shake's frame `frame` with its wait cleared, the next step, the counter cleared.
func _start_scroll_shake(frame: int) -> void:
	w2(W_OW_UI_OBJ_1_FRAME, frame)
	w2(W_OW_UI_OBJ_1_ATTRIBUTES, 0)
	w2(W_OW_UI_OBJ_1_Y_COORD, r2(W_OW_UI_OBJ_1_Y_COORD) + 1)
	w2(W_OW_UI_OBJ_1_X_COORD, 0)


## .Func_b7231, .Func_b7249: on the shake's frame `frame` the frame and the step cleared.
func _end_scroll_shake_on(frame: int) -> void:
	if r2(W_OW_UI_OBJ_1_FRAME) != frame:
		return
	w2(W_OW_UI_OBJ_1_FRAME, 0)
	w2(W_OW_UI_OBJ_1_Y_COORD, 0)


## Func_b71fc.Func_b7273: with a frame set its wait counts and by the frame: the soft shake (1 to $10:
## wSCY a pixel up, back down, every other loop, then round again from 1), the hard one ($11 to $14:
## 4 up, 3 loops, 4 down, 3 loops, round again from $11), the sideways ones ($15 to $1d: wSCX 4 right,
## 8 left, 8 right, 8 left, 4 right with 3 loops between, then off; $1e to $26 the same by 1, 2, 2, 2,
## 1). Sounds at frames 1, $11, $15, and $1e (not simulated).
func _func_b7273() -> void:
	var frame: int = r2(W_OW_UI_OBJ_1_FRAME)
	if frame == 0:
		return
	w2(W_OW_UI_OBJ_1_ATTRIBUTES, r2(W_OW_UI_OBJ_1_ATTRIBUTES) + 1)
	match frame - 1:
		0, 4, 8, 12:  # .Func_b72f8 (a sound) falling into .Func_b7300, .Func_b7300
			_scroll_shake_y(-1)
		2, 6, 10, 14:  # .Func_b730b
			_scroll_shake_y(1)
		1, 3, 5, 7, 9, 11, 13:  # .Func_b72e0
			_scroll_shake_wait(1, 0)
		15:  # .Func_b72e8: back to frame 1
			_scroll_shake_wait(1, 0x10)
		16:  # .Func_b7311 (a sound)
			_scroll_shake_y(-4)
		17, 21, 23, 25, 27, 30, 32, 34, 36:  # .Func_b72c8
			_scroll_shake_wait(3, 0)
		18:  # .Func_b7322
			_scroll_shake_y(4)
		19:  # .Func_b72d0: back to frame $11
			_scroll_shake_wait(3, 0x04)
		20:  # .Func_b733b (a sound), .Func_b7343
			_scroll_shake_x(4)
		22, 26:  # .Func_b7379
			_scroll_shake_x(-8)
		24:  # .Func_b7387
			_scroll_shake_x(8)
		28:  # .Func_b734c: .Func_b7343, then the frame cleared
			_scroll_shake_x(4)
			w2(W_OW_UI_OBJ_1_FRAME, 0)
		29:  # .Func_b7363 (a sound), .asm_b736b
			_scroll_shake_x(1)
		31, 35:  # .Func_b7334
			_scroll_shake_x(-2)
		33:  # .Func_b735c
			_scroll_shake_x(2)
		37:  # .Func_b7371: .asm_b736b, then the frame cleared
			_scroll_shake_x(1)
			w2(W_OW_UI_OBJ_1_FRAME, 0)
		_:
			_note("Func_b71fc.Func_b7273 frame %d (past its table)" % frame)
	# (.Func_b732b, wSCX 4 left, and the 3 right after .Func_b734c are in no table: unreachable)


## wSCY moved by `pixels`, then the next frame (.asm_b7304).
func _scroll_shake_y(pixels: int) -> void:
	sim.wSCY = byte(sim.wSCY + pixels)
	_next_scroll_shake_frame()


## wSCX moved by `pixels`, then the next frame (.asm_b7304).
func _scroll_shake_x(pixels: int) -> void:
	sim.wSCX = byte(sim.wSCX + pixels)
	_next_scroll_shake_frame()


## .Func_b72e0, .Func_b72c8 (and with `back`, .Func_b72e8, .Func_b72d0): once the wait reaches `loops`
## the frame goes `back`, then the next frame (.asm_b7304).
func _scroll_shake_wait(loops: int, back: int) -> void:
	if r2(W_OW_UI_OBJ_1_ATTRIBUTES) < loops:
		return
	w2(W_OW_UI_OBJ_1_FRAME, r2(W_OW_UI_OBJ_1_FRAME) - back)
	_next_scroll_shake_frame()


## .asm_b7304: the wait cleared (`ld [hld], a`), then the byte before it, the frame, counts on.
func _next_scroll_shake_frame() -> void:
	w2(W_OW_UI_OBJ_1_ATTRIBUTES, 0)
	w2(W_OW_UI_OBJ_1_FRAME, r2(W_OW_UI_OBJ_1_FRAME) + 1)


# --- the risers (Func_15868e, bank $56) ---

## Func_15868e: the six risers in turn (.Func_1586a1, .Func_158785, .Func_1586ed, .Func_1587d1,
## .Func_158739, .Func_15881d).
func func_15868e() -> void:
	for riser: Array in SCENE_RISERS:
		_scene_riser(riser)


## A riser by its step: none (0); spawned at a point in a random state, then the next step (1, 3, 5);
## along a path until its end, then the next step (2, 4, 6); round again (7: step 1).
func _scene_riser(riser: Array) -> void:
	var at: int = int(riser[0])
	var step: int = r2(at)
	if step == 0:
		return
	if step == NUM_RISER_STEPS:
		w2(at, 0x01)
		return
	if step > NUM_RISER_STEPS:
		_note("Func_15868e riser at %04x step %d (past its table)" % [at, step])
		return
	var number: int = int(riser[1])
	var what: Variant = riser[3][step - 1]
	if what is Array:
		_spawn_scene_riser(number, what)
	elif not apply_ow_movement(scene_obj(number), int(what), SCENE_RISERS_BANK, bool(riser[2])):
		return  # ApplyOWMovement, ApplyOWMovement_Mirrored: not at the path's end
	w2(at, step + 1)


## .Func_158869, .Func_15887b, .Func_158882, .Func_158889, .Func_158890 (.asm_15886e): the scene object
## at the point (y, x), its state $29 plus rDIV's bit 0 (SetSceneObjState through `set 2, l`).
func _spawn_scene_riser(number: int, point: Array) -> void:
	var obj: int = scene_obj(number)
	wr(obj + SCENE_OBJ_Y, int(point[0]))
	wr(obj + SCENE_OBJ_X, int(point[1]))
	set_scene_obj_state(number, RISER_STATE + (sim.read_div(DIV_FUNC_15868E) & 0x01))


# --- the steps the OW functions share ---

## WaitOWFunc: once wOWFuncCounter passes `count`, AdvanceOWFunc.
func wait_ow_func(count: int) -> void:
	if count >= r2(W_OW_FUNC_COUNTER):
		return
	advance_ow_func()


## AdvanceOWFunc: wOWFuncCounter cleared, the next step (w2d062).
func advance_ow_func() -> void:
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, r2(W2D062) + 1)


## EndOWFunc: wOWSceneActionParam (the function: the scene goes on), wOWFuncCounter, w2d062 cleared.
func end_ow_func() -> void:
	w2(W_OW_SCENE_ACTION_PARAM, 0)
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, 0)
