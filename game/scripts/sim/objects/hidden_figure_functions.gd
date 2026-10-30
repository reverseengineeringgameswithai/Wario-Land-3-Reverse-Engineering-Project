class_name HiddenFigureFunctions
extends BossFunctions
## The hidden figure, the Temple's final battle, by translation from
## src/engine/level/objects/hidden_figure.asm (bank $13, "Object Functions 4"): the figure itself
## (HiddenFigureFunc), which runs the fight and orders its hands' attacks through w1d14b; its face
## (HiddenFigureFaceFunc), the part that takes the hits; and its two hands
## (HiddenFigureLeftHandFunc, HiddenFigureRightHandFunc), which swipe, clap, and slam, and once
## knocked loose are carried and thrown like an enemy until they float home. The fight's variables
## are w1d14b-w1d162 in the object WRAM. Music and sounds are not simulated; the BG palettes the
## figure writes (Func_4cfe0's flash, Func_4d005) are recorded for the drawing (hidden_figure_bg_pals).
## Paths into code not ported are named in `unported`.
## Research note: docs/02-research/objects.md.

const BOSS_HIDDEN_FIGURE: int = 1  # wBossState
const HIDDEN_FIGURE_RIGHT_HAND: int = 0x3D  # its ID (the left hand's is $3c)
const OBJ_INTERACTION_4F: int = 0x4F
const OBJ_INTERACTION_50: int = 0x50
const OBJ_INTERACTION_52: int = 0x52
const DIV_HIDDEN_FIGURE: int = 0x13_4C7D  # .Func_4cc3c's rDIV read
const HIDDEN_FIGURE_FUNC: int = 0x13_4B51  # HiddenFigureFunc
const HIDDEN_FIGURE_START: int = 0x13_4B9E  # .Func_4cb9e
const HIDDEN_FIGURE_MAIN: int = 0x13_4BC4  # .Func_4cbc4
const HIDDEN_FIGURE_DEFEATED: int = 0x13_4DBC  # .Func_4cdbc
const HIDDEN_FIGURE_COLLAPSE: int = 0x13_4E01  # .Func_4ce01
const HIDDEN_FIGURE_FACE_FUNC: int = 0x13_4E47  # HiddenFigureFaceFunc (.Func_4ce47)
const HIDDEN_FIGURE_FACE_HURT: int = 0x13_4F13  # .Func_4cf13
const HIDDEN_FIGURE_FACE_DEFEATED: int = 0x13_4F3F  # .Func_4cf3f
const HIDDEN_FIGURE_FACE_LAUGH: int = 0x13_4F55  # .Func_4cf55 (set by Func_4ce39)
const HIDDEN_FIGURE_LEFT_HAND_FUNC: int = 0x13_50AB  # HiddenFigureLeftHandFunc
const HIDDEN_FIGURE_LEFT_HAND_WAIT: int = 0x13_50C7  # .Func_4d0c7
const HIDDEN_FIGURE_LEFT_HAND_SLAM: int = 0x13_5164  # .Func_4d164
const HIDDEN_FIGURE_LEFT_HAND_DIP: int = 0x13_519E  # .Func_4d19e
const HIDDEN_FIGURE_LEFT_HAND_CLAP: int = 0x13_51B1  # .Func_4d1b1
const HIDDEN_FIGURE_LEFT_HAND_SWIPE: int = 0x13_52C8  # .Func_4d2c8
const HIDDEN_FIGURE_LEFT_HAND_HOLD: int = 0x13_5379  # .Func_4d379
const HIDDEN_FIGURE_LEFT_HAND_DEFEATED: int = 0x13_537F  # .Func_4d37f
const HIDDEN_FIGURE_LEFT_HAND_RISE: int = 0x13_539B  # .Func_4d39b
const HIDDEN_FIGURE_RIGHT_HAND_FUNC: int = 0x13_53AC  # HiddenFigureRightHandFunc
const HIDDEN_FIGURE_RIGHT_HAND_WAIT: int = 0x13_53C8  # .Func_4d3c8
const HIDDEN_FIGURE_RIGHT_HAND_SLAM: int = 0x13_5465  # .Func_4d465
const HIDDEN_FIGURE_RIGHT_HAND_DIP: int = 0x13_549F  # .Func_4d49f
const HIDDEN_FIGURE_RIGHT_HAND_CLAP: int = 0x13_54B2  # .Func_4d4b2
const HIDDEN_FIGURE_RIGHT_HAND_SWIPE: int = 0x13_5571  # .Func_4d571
const HIDDEN_FIGURE_RIGHT_HAND_STOP: int = 0x13_5622  # .Func_4d622
const HIDDEN_FIGURE_RIGHT_HAND_DEFEATED: int = 0x13_5628  # .Func_4d628
const HIDDEN_FIGURE_RIGHT_HAND_SINK: int = 0x13_5644  # .Func_4d644
const HIDDEN_FIGURE_HAND_KNOCKED: int = 0x13_5655  # HiddenFigureRightHandFunc.Func_4d655, both hands'
# The BG palettes 0-5 SetBGPals takes from bank $13 (Func_4cfe0, Func_4d005).
const PALS_4D01B: int = 0x501B
const PALS_4D04B: int = 0x504B  # the flash
const PALS_4D07B: int = 0x507B
const OBJ_PARAMS_HIDDEN_FIGURE_FACE: int = 0x4DC7  # bank $19
const OBJ_PARAMS_HIDDEN_FIGURE_LEFT_HAND: int = 0x4DDC
const OBJ_PARAMS_HIDDEN_FIGURE_RIGHT_HAND: int = 0x4DF1
# The fight's variables in the object WRAM ($d14b-$d162), as wram1 offsets.
const W_1D14B: int = 0x14B  # the attack the figure orders: 1 and 2 the swipes, 3, 7, 8 the claps,
# 4 and 5 the slams, 6 the defeat
const W_1D14C: int = 0x14C  # the left hand knocked loose
const W_1D14D: int = 0x14D  # the right hand
const W_1D14E: int = 0x14E  # the figure's clap pause ($80: Wario caught)
const W_1D14F: int = 0x14F  # the left hand's
const W_1D150: int = 0x150  # the right hand's
const W_1D151: int = 0x151  # the waiting hands dip
const W_1D152: int = 0x152  # the left hand's home: y, then x (little-endian)
const W_1D156: int = 0x156  # the right hand's
const W_1D15A: int = 0x15A  # the hits left (4 at the start)
const W_1D15B: int = 0x15B  # the right hand slamming
const W_1D15C: int = 0x15C  # the left hand
const W_1D15D: int = 0x15D  # a knocked hand was picked up or grabbed
const W_1D15E: int = 0x15E  # a swipe was met
const W_1D15F: int = 0x15F  # the figure collapsing
const W_1D160: int = 0x160  # swipes in a row
const W_1D161: int = 0x161  # attacks chosen
const W_1D162: int = 0x162  # with one hit left, the claps to the next wait
const DATA_4C000: int = 0x4000  # the swipes' vertical shake (bank $13)
const DATA_4C080: int = 0x4080  # the left hand's swipe's sideways shake
const DATA_4C100: int = 0x4100  # the right hand's
const DATA_4C180: int = 0x4180  # clap 3's vertical shake
const DATA_4C200: int = 0x4200  # the left hand's swipe, x
const DATA_4C280: int = 0x4280  # either swipe, y
const DATA_4C300: int = 0x4300  # the right hand's swipe, x
const DATA_4C380: int = 0x4380  # the left hand's claps 3 and 7, x
const DATA_4C400: int = 0x4400  # clap 3, y
const DATA_4C480: int = 0x4480  # the right hand's claps 3 and 7, x
const DATA_4C500: int = 0x4500  # the dip, y
const DATA_4C540: int = 0x4540  # the slam, y
const DATA_4C580: int = 0x4580  # clap 7's vertical shake
const DATA_4C600: int = 0x4600  # clap 7, y
const DATA_4C680: int = 0x4680  # clap 8's vertical shake
const DATA_4C700: int = 0x4700  # the left hand's clap 8, x
const DATA_4C760: int = 0x4760  # the right hand's
const DATA_4C800: int = 0x4800  # clap 8, y
const FRAMESET_6A06C: int = 0x606C  # the figure; the face looking ahead
const FRAMESET_6A071: int = 0x6071  # the face laughing
const FRAMESET_6A07A: int = 0x607A  # looking left
const FRAMESET_6A07F: int = 0x607F  # looking right
const FRAMESET_6A084: int = 0x6084  # hurt
const FRAMESET_6A08D: int = 0x608D  # the second set: ahead
const FRAMESET_6A092: int = 0x6092  # left
const FRAMESET_6A097: int = 0x6097  # right
const FRAMESET_6A0B2: int = 0x60B2  # the left hand knocked loose
const FRAMESET_6A0B7: int = 0x60B7  # the right hand
const FRAMESET_6A0BC: int = 0x60BC
const FRAMESET_6A0C3: int = 0x60C3
const FRAMESET_6A0C8: int = 0x60C8
const FRAMESET_6A0CF: int = 0x60CF
const FRAMESET_6A0D4: int = 0x60D4  # the left hand
const FRAMESET_6A0EF: int = 0x60EF
const FRAMESET_6A0F2: int = 0x60F2  # the left hand holding Wario
const FRAMESET_6A0FE: int = 0x60FE  # the right hand
const FRAMESET_6A119: int = 0x6119
const FRAMESET_6A11C: int = 0x611C
const FRAMESET_6A128: int = 0x6128  # the left hand waiting
const FRAMESET_6A131: int = 0x6131  # the right hand waiting
const FRAMESET_6A13A: int = 0x613A  # the left hand's swipe
const FRAMESET_6A145: int = 0x6145  # the right hand's


func object_functions() -> Dictionary:
	var functions: Dictionary = super()
	functions.merge({
		HIDDEN_FIGURE_FUNC: hidden_figure_func,
		HIDDEN_FIGURE_START: hidden_figure_start,
		HIDDEN_FIGURE_MAIN: hidden_figure_main,
		HIDDEN_FIGURE_DEFEATED: hidden_figure_defeated,
		HIDDEN_FIGURE_COLLAPSE: hidden_figure_collapse,
		HIDDEN_FIGURE_FACE_FUNC: hidden_figure_face_func,
		HIDDEN_FIGURE_FACE_HURT: hidden_figure_face_hurt,
		HIDDEN_FIGURE_FACE_DEFEATED: hidden_figure_face_defeated,
		HIDDEN_FIGURE_FACE_LAUGH: hidden_figure_face_laugh,
		HIDDEN_FIGURE_LEFT_HAND_FUNC: hidden_figure_left_hand_func,
		HIDDEN_FIGURE_LEFT_HAND_WAIT: _hidden_figure_hand_wait.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_SLAM: _hidden_figure_hand_slam.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_DIP: _hidden_figure_hand_dip.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_CLAP: _hidden_figure_hand_clap.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_SWIPE: _hidden_figure_hand_swipe.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_HOLD: _no_actions,
		HIDDEN_FIGURE_LEFT_HAND_DEFEATED: _hidden_figure_hand_defeated.bind(true),
		HIDDEN_FIGURE_LEFT_HAND_RISE: hidden_figure_left_hand_rise,
		HIDDEN_FIGURE_RIGHT_HAND_FUNC: hidden_figure_right_hand_func,
		HIDDEN_FIGURE_RIGHT_HAND_WAIT: _hidden_figure_hand_wait.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_SLAM: _hidden_figure_hand_slam.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_DIP: _hidden_figure_hand_dip.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_CLAP: _hidden_figure_hand_clap.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_SWIPE: _hidden_figure_hand_swipe.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_STOP: _no_actions,
		HIDDEN_FIGURE_RIGHT_HAND_DEFEATED: _hidden_figure_hand_defeated.bind(false),
		HIDDEN_FIGURE_RIGHT_HAND_SINK: hidden_figure_right_hand_sink,
		HIDDEN_FIGURE_HAND_KNOCKED: hidden_figure_hand_knocked,
	})
	return functions


# --- The figure (HiddenFigureFunc) --------------------------------------------------------------

## HiddenFigureFunc: the boss battle on (wIsBossBattle), the fight's variables set (w1d14b-w1d151
## and w1d15b-w1d161 cleared, the hits w1d15a 4, w1d162 2; the hands' homes are theirs to set), no
## collision with objects, still 20 frames (.Func_4cb9e), and its face and hands created
## (ObjParams_HiddenFigureFace, _LeftHand, _RightHand).
func hidden_figure_func() -> void:
	wIsBossBattle = 1
	for offset: int in range(W_1D14B, W_1D151 + 1):
		wram1[offset] = 0
	wram1[W_1D15A] = 4
	for offset: int in range(W_1D15B, W_1D161 + 1):
		wram1[offset] = 0
	wram1[W_1D162] = 2
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_START & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(FRAMESET_6A06C)
	set_cur(OBJ_STATE_DURATION, 20)
	create_object_at_relative_pos(OBJ_PARAMS_HIDDEN_FIGURE_FACE)
	create_object_at_relative_pos(OBJ_PARAMS_HIDDEN_FIGURE_LEFT_HAND)
	create_object_at_relative_pos(OBJ_PARAMS_HIDDEN_FIGURE_RIGHT_HAND)


## OBJ_STATE_DURATION down by one (`dec [hl]`, wrapping); true when it reaches 0.
func _hidden_figure_count_down() -> bool:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	return cur(OBJ_STATE_DURATION) == 0


## OBJ_STATE_DURATION down by one unless already 0 (`and a; ret z; dec [hl]`); true when it has just
## reached 0.
func _hidden_figure_count_down_stopping() -> bool:
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		return false
	set_cur(OBJ_STATE_DURATION, left - 1)
	return left == 1


## Where the fight's BG palettes 0-5 were last written from (PALS_4D01B, PALS_4D04B, or PALS_4D07B in
## bank $13), or 0 since LoadHiddenFigureGfx: what the drawing shows (SetBGPals writes them straight to
## the hardware, one an H-Blank). Presentation, not game state.
var hidden_figure_bg_pals: int = 0
## How many times SetBGPals has written them since the game started (the frame drawn while it does
## changes from its lines on).
var hidden_figure_bg_pal_writes: int = 0


## Func_4cfe0: the palettes Func_4d005 takes on every 16th frame (wGlobalCounter & 15 = 0) and
## Pals_4d04b's flash 8 frames later.
func _hidden_figure_flash() -> void:
	match wGlobalCounter & 0x0F:
		0:
			_hidden_figure_pals()
		8:
			_set_hidden_figure_bg_pals(PALS_4D04B)


## Func_4d005: Pals_4d07b while two hits or more are left, else Pals_4d01b.
func _hidden_figure_pals() -> void:
	_set_hidden_figure_bg_pals(PALS_4D07B if wram1[W_1D15A] >= 2 else PALS_4D01B)


## SetBGPals with c 0 and b 6: BG palettes 0-5 from `pals`.
func _set_hidden_figure_bg_pals(pals: int) -> void:
	hidden_figure_bg_pals = pals
	hidden_figure_bg_pal_writes += 1


## .Func_4cb9e: still (frame duration 2, no actions) for its 20 frames; then the fight (.Func_4cbc4)
## from a 30-frame wait (OBJ_VAR_1 0), wBossState BOSS_HIDDEN_FIGURE (UpdateLevelMusic's music not
## simulated).
func hidden_figure_start() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()
	if not _hidden_figure_count_down():
		return
	set_cur(OBJ_STATE_DURATION, 0x1E)
	set_cur(OBJ_VAR_1, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_MAIN & 0xFFFF)
	wBossState = BOSS_HIDDEN_FIGURE


## .Func_4cbc4: still, the fight's phase by OBJ_VAR_1 (JumpTable doubles the index in a byte, so bit
## 7 is ignored): waiting (0), choosing (1), the left hand's swipe (2, 3), the right's (4, 5), a
## clap (6, 7), Wario caught (8), and the slam that follows a knocked hand (9, 10).
func hidden_figure_main() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()
	var phase: int = cur(OBJ_VAR_1) & 0x7F
	match phase:
		0:
			_hidden_figure_wait()
		1:
			_hidden_figure_choose()
		2:
			_hidden_figure_swipe_start(3, 1)  # .Func_4cce2
		3:
			_hidden_figure_swipe(DATA_4C080, W_1D14C, 4, 9)  # .Func_4ccf6
		4:
			_hidden_figure_swipe_start(5, 2)  # .Func_4cd45
		5:
			_hidden_figure_swipe(DATA_4C100, W_1D14D, 5, 10)  # .Func_4cd59
		6:
			_hidden_figure_clap_start()
		7:
			_hidden_figure_clap()
		8:
			_hidden_figure_caught()
		9:
			_hidden_figure_slam_wait(W_1D14C)  # .Func_4cd28
		10:
			_hidden_figure_slam_wait(W_1D14D)  # .Func_4cd8b
		_:
			note_unported("HiddenFigureFunc.Func_4cbc4 phase %02x" % phase)


## .Func_4cbf5 (0): OBJ_STATE_DURATION frames, cut short once a swipe was met (w1d15e, then not
## counted down); then choosing (1).
func _hidden_figure_wait() -> void:
	if wram1[W_1D15E] == 0 and not _hidden_figure_count_down():
		return
	set_cur(OBJ_VAR_1, 1)


## .Func_4cc05 (1): the next attack, after 1 frame: after two swipes in a row (w1d160) or a met swipe
## (w1d15e) a clap (6; both cleared); otherwise a swipe counted in w1d160, the left hand's (2) with
## Wario's screen x below $58, the right's (4) from it. Either way w1d161 counts it.
func _hidden_figure_choose() -> void:
	set_cur(OBJ_STATE_DURATION, 1)
	var swipes: int = wram1[W_1D160]
	if swipes >= 2 or wram1[W_1D15E] != 0:
		wram1[W_1D15E] = 0
		wram1[W_1D160] = 0
		set_cur(OBJ_VAR_1, 6)
	else:
		set_cur(OBJ_VAR_1, 2 if wWarioScreenXPos < 0x58 else 4)
		wram1[W_1D160] = swipes + 1
	wram1[W_1D161] = byte(wram1[W_1D161] + 1)


## The attack's start: OBJ_STATE_DURATION $80, OBJ_VAR_1 `phase`, OBJ_VAR_2 and _3 (the shakes'
## steps) 0.
func _hidden_figure_attack_phase(phase: int) -> void:
	set_cur(OBJ_STATE_DURATION, 0x80)
	set_cur(OBJ_VAR_1, phase)
	set_cur(OBJ_VAR_2, 0)
	set_cur(OBJ_VAR_3, 0)


## .Func_4cce2 (2) and .Func_4cd45 (4): OBJ_STATE_DURATION frames, then the swipe (`phase`, $80
## frames), ordered by `attack` in w1d14b (1 the left hand, 2 the right).
func _hidden_figure_swipe_start(phase: int, attack: int) -> void:
	if not _hidden_figure_count_down():
		return
	_hidden_figure_attack_phase(phase)
	wram1[W_1D14B] = attack


## .Func_4ccf6 (3) and .Func_4cd59 (5): the swipe, the screen shaken along Data_4c000 and sideways
## along `x_table`; at its end no attack, then waiting (0, 30 frames), or, the swiping hand knocked
## loose (`knocked`: w1d14c or w1d14d), the other hand's `slam` (4 or 5) and its phase (`phase`: 9 or
## 10, 4 frames).
func _hidden_figure_swipe(x_table: int, knocked: int, slam: int, phase: int) -> void:
	_hidden_figure_shake_y(DATA_4C000)
	_hidden_figure_shake_x(x_table)
	if not _hidden_figure_count_down():
		return
	wram1[W_1D14B] = 0
	if wram1[knocked] == 0:
		set_cur(OBJ_STATE_DURATION, 0x1E)
		set_cur(OBJ_VAR_1, 0)
		return
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_1, phase)
	wram1[W_1D14B] = slam


## .Func_4cd28 (9) and .Func_4cd8b (10): with no hits left the defeat (.asm_4cda8); otherwise, once
## the knocked hand is home (`knocked` clear), OBJ_STATE_DURATION frames, then no attack and a clap's
## wait (6, 30 frames).
func _hidden_figure_slam_wait(knocked: int) -> void:
	if wram1[W_1D15A] == 0:
		_hidden_figure_defeat()
		return
	if wram1[knocked] != 0:
		return
	if not _hidden_figure_count_down():
		return
	set_cur(OBJ_STATE_DURATION, 0x1E)
	set_cur(OBJ_VAR_1, 6)
	wram1[W_1D14B] = 0


## .Func_4cc3c (6): once neither hand slams (w1d15c, w1d15b) and OBJ_STATE_DURATION has run out, a
## clap (7, $80 frames): clap 3 with four hits left; with fewer than three, Wario's screen x $30-$7f,
## and w1d161 even, clap 8 ($60 frames); otherwise clap 3 or 7 by the bit rDIV shifts out.
func _hidden_figure_clap_start() -> void:
	if wram1[W_1D15C] != 0 or wram1[W_1D15B] != 0:
		return
	if not _hidden_figure_count_down():
		return
	_hidden_figure_attack_phase(7)
	var attack: int = 3
	var hits: int = wram1[W_1D15A]
	if hits != 4:
		if hits < 3 and wWarioScreenXPos >= 0x30 and wWarioScreenXPos < 0x80 and (wram1[W_1D161] & 1) == 0:
			set_cur(OBJ_STATE_DURATION, 0x60)
			attack = 8
		elif (read_div(DIV_HIDDEN_FIGURE) & 1) == 0:
			attack = 7
	wram1[W_1D14B] = attack


## .Func_4cc87 (7): the clap. Its pause (w1d14e, set when a clapping hand is hit) is counted down
## instead; at $80 (Wario caught) the figure waits $a0 frames (8). Otherwise the screen is shaken
## along Data_4c180 (clap 7: Data_4c580, clap 8: Data_4c680) until OBJ_STATE_DURATION runs out: then
## no attack and waiting (0, 30 frames); with one hit left, every other time (w1d162 counting down
## from 2) another clap's wait instead (6, w1d161 counted).
func _hidden_figure_clap() -> void:
	var pause: int = wram1[W_1D14E]
	if pause != 0:
		if pause == 0x80:
			set_cur(OBJ_STATE_DURATION, 0xA0)
			set_cur(OBJ_VAR_1, 8)
		else:
			wram1[W_1D14E] = pause - 1
		return
	var attack: int = wram1[W_1D14B]
	_hidden_figure_shake_y(DATA_4C580 if attack == 7 else (DATA_4C680 if attack == 8 else DATA_4C180))
	if not _hidden_figure_count_down():
		return
	set_cur(OBJ_STATE_DURATION, 0x1E)
	set_cur(OBJ_VAR_1, 0)
	wram1[W_1D14B] = 0
	if wram1[W_1D15A] != 1:
		return
	wram1[W_1D162] = byte(wram1[W_1D162] - 1)
	if wram1[W_1D162] == 0:
		wram1[W_1D162] = 2
		return
	set_cur(OBJ_VAR_1, 6)
	wram1[W_1D161] = byte(wram1[W_1D161] + 1)


## .Func_4cbe8 (8): Wario caught; OBJ_STATE_DURATION counts down to 0 and stops, wAutoMoveState
## cleared as it gets there.
func _hidden_figure_caught() -> void:
	if _hidden_figure_count_down_stopping():
		wAutoMoveState = 0


## .asm_4cda8: defeated (.Func_4cdbc, $82 frames), the hands told (attack 6).
func _hidden_figure_defeat() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_DEFEATED & 0xFFFF)
	set_cur(OBJ_STATE_DURATION, 0x82)
	wram1[W_1D14B] = 6


## .Func_4cdbc: still, Func_4cfe0's palette flash; once both hands are home (w1d14c, w1d14d clear),
## $82 frames (SFX_0CE every 64 not simulated), then the collapse (.Func_4ce01, $82 frames,
## OBJ_VAR_1 0) with w1d15f set for the hands (SFX_0CF not simulated).
func hidden_figure_defeated() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()
	_hidden_figure_flash()
	if wram1[W_1D14C] != 0 or wram1[W_1D14D] != 0:
		return
	if not _hidden_figure_count_down():
		return
	set_cur(OBJ_STATE_DURATION, 0x82)
	set_cur(OBJ_VAR_1, 0)
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_COLLAPSE & 0xFFFF)
	wram1[W_1D15F] = 1


## .Func_4ce01: still; OBJ_VAR_1 counts frames (SFX_01F every 8 not simulated); OBJ_STATE_DURATION
## counts down to 0 and stops, with Func_4cfe0's palette flash and wHiddenFigureSCYShake down by one
## each time the count is a multiple of 4, and at 0 the epilogue (wLevelEndScreen LVLEND_EPILOGUE)
## with Func_4d005's palettes.
func hidden_figure_collapse() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	_no_actions()
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) + 1)
	var left: int = cur(OBJ_STATE_DURATION)
	if left == 0:
		return
	set_cur(OBJ_STATE_DURATION, left - 1)
	if left == 1:
		wLevelEndScreen = LVLEND_EPILOGUE
		_hidden_figure_pals()
		return
	_hidden_figure_flash()
	if ((left - 1) & 3) == 0:
		wHiddenFigureSCYShake = byte(wHiddenFigureSCYShake - 1)


# --- Its tables (Func_4cf70 to Func_4cfbf) -------------------------------------------------------

## The next entry of a bank-$13 table at `field` (OBJ_VAR_2 or _3), within the table's page
## (`add c; ld c, a; ld a, [bc]`); at the $80 end the last entry again, the index kept.
func _hidden_figure_step(table: int, field: int) -> int:
	var c: int = byte(lo(table) + cur(field))
	var a: int = bank_byte(0x13, (table & 0xFF00) | c)
	if a == 0x80:
		return bank_byte(0x13, (table & 0xFF00) | byte(c - 1))
	set_cur(field, cur(field) + 1)
	return a


## Func_4cf70: the next OBJ_VAR_3 entry added to wHiddenFigureSCYShake.
func _hidden_figure_shake_y(table: int) -> void:
	wHiddenFigureSCYShake = byte(wHiddenFigureSCYShake + _hidden_figure_step(table, OBJ_VAR_3))


## Func_4cf87: the next OBJ_VAR_2 entry added to wc08b.
func _hidden_figure_shake_x(table: int) -> void:
	wc08b = byte(wc08b + _hidden_figure_step(table, OBJ_VAR_2))


## Func_4cf9e: the next OBJ_VAR_3 entry moves the object down (signed).
func _hidden_figure_move_y(table: int) -> void:
	add_y_signed(_hidden_figure_step(table, OBJ_VAR_3))


## Func_4cfbf: the next OBJ_VAR_2 entry moves the object right (signed).
func _hidden_figure_move_x(table: int) -> void:
	var a: int = _hidden_figure_step(table, OBJ_VAR_2)
	move_object_x(a - 0x100 if a >= 0x80 else a)


# --- The face (HiddenFigureFaceFunc) -------------------------------------------------------------

## HiddenFigureFaceFunc (.Func_4ce47): with Wario caught (w1d14e $80) it laughs 60 frames on
## (Func_4ce39: .Func_4cf55). Hit (OBJ_STATE $28, $29) it is hurt (.asm_4ceba); any other state is
## cleared and collisions with objects turned back on. Otherwise, at the end of its frameset's second
## frame (offset 4, duration 0), it looks towards Wario by his screen x (below $38, below $78, from
## it), with the second set of framesets (.asm_4ce9d) while a hand is knocked loose (w1d14c, w1d14d)
## or one hit is left.
func hidden_figure_face_func() -> void:
	if wram1[W_1D14E] == 0x80:
		set_cur(OBJ_STATE_DURATION, 0x3C)
		set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_FACE_LAUGH & 0xFFFF)
		return
	var state: int = cur(OBJ_STATE)
	if state != 0:
		if (state & 0xFE) == OBJSTATE_28:
			_hidden_figure_face_hit()
			return
		set_cur(OBJ_STATE, 0)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
		return
	if cur(OBJ_FRAMESET_OFFSET) != 4 or cur(OBJ_FRAME_DURATION) != 0:
		return
	if wram1[W_1D14C] != 0 or wram1[W_1D14D] != 0 or wram1[W_1D15A] == 1:
		_hidden_figure_face_look_2()
		return
	var x: int = wWarioScreenXPos
	set_object_frameset_ptr(FRAMESET_6A07A if x < 0x38 else (FRAMESET_6A06C if x < 0x78 else FRAMESET_6A07F))


## .asm_4ce9d: the second set of framesets by Wario's screen x.
func _hidden_figure_face_look_2() -> void:
	var x: int = wWarioScreenXPos
	set_object_frameset_ptr(FRAMESET_6A092 if x < 0x38 else (FRAMESET_6A08D if x < 0x78 else FRAMESET_6A097))


## .asm_4ceba: hurt (.Func_4cf13, 60 frames), its state cleared, the waiting hands dipping
## (w1d151), and a hit taken from w1d15a unless none are left (MUSIC_HIDDEN_FIGURE_BATTLE_2 at one
## left not simulated). At none left it is defeated instead (.Func_4cf3f, 16 frames): no collision
## with objects, the dip off, wAutoMoveState 2 (stop_music2 not simulated).
func _hidden_figure_face_hit() -> void:
	set_cur(OBJ_STATE, 0)
	set_object_frameset_ptr(FRAMESET_6A084)
	set_cur(OBJ_STATE_DURATION, 0x3C)
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_FACE_HURT & 0xFFFF)
	wram1[W_1D151] = 1
	var hits: int = wram1[W_1D15A]
	if hits == 0:
		return
	wram1[W_1D15A] = hits - 1
	if hits != 1:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_FACE_DEFEATED & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	wram1[W_1D151] = 0
	set_cur(OBJ_STATE_DURATION, 0x10)
	wAutoMoveState = 2


## .Func_4cf13: hurt for OBJ_STATE_DURATION frames, with Func_4cfe0's palette flash (SFX_0CE at $2c
## not simulated); then back (HiddenFigureFaceFunc), the dip off (w1d151), collisions with objects
## on, Func_4d005's palettes, and the second set of framesets (.asm_4ce9d).
func hidden_figure_face_hurt() -> void:
	if not _hidden_figure_count_down():
		_hidden_figure_flash()
		return
	wram1[W_1D151] = 0
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_FACE_FUNC & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	_hidden_figure_pals()
	_hidden_figure_face_look_2()


## .Func_4cf3f: defeated, no actions; OBJ_STATE_DURATION counts down to 0 and stops (SFX_0CE as it
## gets there not simulated).
func hidden_figure_face_defeated() -> void:
	_no_actions()
	_hidden_figure_count_down_stopping()


## .Func_4cf55: no actions; when OBJ_STATE_DURATION runs out (stopping at 0) it laughs
## (Frameset_6a071; SFX_HIDDEN_FIGURE_LAUGH not simulated).
func hidden_figure_face_laugh() -> void:
	_no_actions()
	if _hidden_figure_count_down_stopping():
		set_object_frameset_ptr(FRAMESET_6A071)


# --- The hands (HiddenFigureLeftHandFunc, HiddenFigureRightHandFunc) -----------------------------

## HiddenFigureLeftHandFunc: its position kept as its home (w1d152), then waiting (.Func_4d0c7).
func hidden_figure_left_hand_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_LEFT_HAND_WAIT & 0xFFFF)
	_hidden_figure_keep_home(W_1D152)


## HiddenFigureRightHandFunc: its home in w1d156, then waiting (.Func_4d3c8).
func hidden_figure_right_hand_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_RIGHT_HAND_WAIT & 0xFFFF)
	_hidden_figure_keep_home(W_1D156)


func _hidden_figure_keep_home(home: int) -> void:
	for i: int in 4:
		wram1[home + i] = cur(OBJ_Y_POS + i)


## The interaction (HEAVY_OBJ kept) and the collision box (top, bottom, left, right).
func _hidden_figure_set_box(kind: int, top: int, bottom: int, left: int, right: int) -> void:
	set_interaction(kind)
	set_cur(OBJ_COLLBOX_TOP, top)
	set_cur(OBJ_COLLBOX_BOTTOM, bottom)
	set_collbox_x(left, right)


## .Func_4d0c7 (the left hand) and .Func_4d3c8 (the right): waiting, no actions, collisions with
## objects on, for the figure's attack (w1d14b): its swipe (1 or 2, .asm_4d0f3: the waiting hands dip,
## w1d151); a clap (3, 7, 8, .asm_4d100: OBJ_INTERACTION_4F and a box of its own); its slam (5 or 4,
## .asm_4d11d: OBJ_INTERACTION_FULL_STING, w1d15c or w1d15b set, 30 frames before it with one hit
## left, otherwise 60); the defeat (6, .asm_4d142: no collision with objects); with none, a dip while
## w1d151 is set (.asm_4d14c). Each starts with OBJ_VAR_2 and _3 cleared (.asm_4d154), and the left
## hand's OBJ_STATE, but the right hand's OBJ_SUBSTATE (.asm_4d455 skips one byte less).
func _hidden_figure_hand_wait(left_hand: bool) -> void:
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	var attack: int = wram1[W_1D14B]
	var function: int
	var frameset: int = FRAMESET_6A0D4 if left_hand else FRAMESET_6A0FE
	if attack == (1 if left_hand else 2):
		wram1[W_1D151] = 1
		function = HIDDEN_FIGURE_LEFT_HAND_SWIPE if left_hand else HIDDEN_FIGURE_RIGHT_HAND_SWIPE
		frameset = FRAMESET_6A13A if left_hand else FRAMESET_6A145
	elif attack == 3 or attack == 7 or attack == 8:
		if left_hand:
			_hidden_figure_set_box(OBJ_INTERACTION_4F, -32, 0, -12, 0)
		else:
			_hidden_figure_set_box(OBJ_INTERACTION_4F, -32, 0, -1, 11)
		function = HIDDEN_FIGURE_LEFT_HAND_CLAP if left_hand else HIDDEN_FIGURE_RIGHT_HAND_CLAP
		frameset = FRAMESET_6A0BC if left_hand else FRAMESET_6A0C8
	elif attack == (5 if left_hand else 4):
		set_interaction(OBJ_INTERACTION_FULL_STING)
		wram1[W_1D15C if left_hand else W_1D15B] = 1
		set_cur(OBJ_STATE_DURATION, 0x1E if wram1[W_1D15A] == 1 else 0x3C)
		function = HIDDEN_FIGURE_LEFT_HAND_SLAM if left_hand else HIDDEN_FIGURE_RIGHT_HAND_SLAM
	elif attack == 6:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
		function = HIDDEN_FIGURE_LEFT_HAND_DEFEATED if left_hand else HIDDEN_FIGURE_RIGHT_HAND_DEFEATED
	elif wram1[W_1D151] != 0:
		function = HIDDEN_FIGURE_LEFT_HAND_DIP if left_hand else HIDDEN_FIGURE_RIGHT_HAND_DIP
	else:
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, function & 0xFFFF)
	set_cur(OBJ_VAR_2, 0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE if left_hand else OBJ_SUBSTATE, 0)
	set_object_frameset_ptr(frameset)


## .asm_4d34c (the left hand) and .asm_4d5f5 (the right): waiting again (.Func_4d0c7, .Func_4d3c8)
## with OBJ_INTERACTION_0B and its box (-24, -8, -8, 7), OBJ_STATE 0, collisions with objects on,
## visible, and Frameset_6a128 or _6a131.
func _hidden_figure_hand_reset(left_hand: bool) -> void:
	var function: int = HIDDEN_FIGURE_LEFT_HAND_WAIT if left_hand else HIDDEN_FIGURE_RIGHT_HAND_WAIT
	set_cur_word(OBJ_UPDATE_FUNCTION, function & 0xFFFF)
	_hidden_figure_set_box(OBJ_INTERACTION_0B, -24, -8, -8, 7)
	set_cur(OBJ_STATE, 0)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~(OBJFLAG_NO_COLLISION | OBJFLAG_INVISIBLE))
	set_object_frameset_ptr(FRAMESET_6A128 if left_hand else FRAMESET_6A131)


## .Func_4d164 (the left hand) and .Func_4d465 (the right): the slam. OBJ_STATE_DURATION frames of
## waiting, called off when no hits are left or the attack is over (w1d14b 0); then down and up
## along Data_4c540, the ground shaken 24 frames as it lands at step 10 (DoGroundShake; SFX_063 not
## simulated), over at step 63. Over or called off, its slam flag (w1d15c, w1d15b) is cleared and it
## waits again (.asm_4d34c, .asm_4d5f5).
func _hidden_figure_hand_slam(left_hand: bool) -> void:
	var waiting: int = cur(OBJ_STATE_DURATION)
	if waiting != 0:
		set_cur(OBJ_STATE_DURATION, waiting - 1)
		if wram1[W_1D15A] != 0 and wram1[W_1D14B] != 0:
			return
	else:
		_hidden_figure_move_y(DATA_4C540)
		var step: int = cur(OBJ_VAR_3)
		if step == 0x0A:
			if wGroundShakeCounter == 0:
				wGroundShakeCounter = 0x18
				wIsWarioGroundShaking = 0
			return
		if step != 0x3F:
			return
	wram1[W_1D15C if left_hand else W_1D15B] = 0
	_hidden_figure_hand_reset(left_hand)


## .Func_4d19e (the left hand) and .Func_4d49f (the right): the dip along Data_4c500; at step $3a it
## is over for both hands (w1d151 cleared) and this one waits again.
func _hidden_figure_hand_dip(left_hand: bool) -> void:
	_hidden_figure_move_y(DATA_4C500)
	if cur(OBJ_VAR_3) != 0x3A:
		return
	wram1[W_1D151] = 0
	_hidden_figure_hand_reset(left_hand)


## .Func_4d2c8 (the left hand) and .Func_4d571 (the right): the swipe along Data_4c200 (the right
## hand's Data_4c300) and Data_4c280, OBJ_INTERACTION_48 from step $10 and OBJ_INTERACTION_52 from
## $3c (SFX_0CB not simulated), over at $7f. Smashed (OBJSTATE_VANISH_TOUCH) it is knocked loose
## instead: the knocked hand's table (.Func_4d655) from $2e for a frame, in front, OBJ_INTERACTION_00
## and a box of its own, OBJ_VAR_3 0, its flag set (w1d14c, w1d14d), Frameset_6a0b2 or _6a0b7
## (stop_sfx not simulated). Any other state marks the swipe met (w1d15e) and is cleared.
func _hidden_figure_hand_swipe(left_hand: bool) -> void:
	var state: int = cur(OBJ_STATE)
	if state == OBJSTATE_VANISH_TOUCH:
		set_cur(OBJ_STATE, 0x2E)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
		set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_HAND_KNOCKED & 0xFFFF)
		_hidden_figure_set_box(OBJ_INTERACTION_00, -20, -2, -8, 7)
		set_cur(OBJ_VAR_3, 0)
		wram1[W_1D14C if left_hand else W_1D14D] = 1
		set_cur(OBJ_STATE_DURATION, 1)
		set_object_frameset_ptr(FRAMESET_6A0B2 if left_hand else FRAMESET_6A0B7)
		return
	if state != 0:
		wram1[W_1D15E] = 1
		set_cur(OBJ_STATE, 0)
	_hidden_figure_move_x(DATA_4C200 if left_hand else DATA_4C300)
	_hidden_figure_move_y(DATA_4C280)
	var step: int = cur(OBJ_VAR_2)
	if step == 0x10:
		set_interaction(OBJ_INTERACTION_48)
	elif step == 0x3C:
		set_interaction(OBJ_INTERACTION_52)
	elif step == 0x7F:
		_hidden_figure_hand_reset(left_hand)


## .Func_4d1b1 (the left hand) and .Func_4d4b2 (the right): the clap. Its pause (w1d14f, w1d150) is
## counted down instead; at $80 the left hand holds Wario (.Func_4d379; .asm_4d1be) and the right
## stops (.Func_4d622; .asm_4d4bf). Otherwise its state first: the left hand's $2f (Wario caught;
## SFX_0CD not simulated) pauses the figure and both hands at $80, an attack ($04, $05) for 10 frames
## (OBJ_STATE cleared, nothing else this frame); any other state is cleared. Then it moves along its
## clap's tables: clap 8's (Data_4c700 or _4c760, and Data_4c800) or the others' (Data_4c380 or
## _4c480, and clap 7's Data_4c600 or clap 3's Data_4c400), by OBJ_VAR_2's step: $13 a frameset;
## $62 (clap 8: $4e) another, the left hand OBJ_INTERACTION_4F again; one before it the left hand
## OBJ_INTERACTION_50 (SFX_FAT_WALK not simulated); over at $7f (clap 8: $5f). The right hand's
## SFX_0D1 and SFX_0D0 are not simulated.
func _hidden_figure_hand_clap(left_hand: bool) -> void:
	var own_pause: int = W_1D14F if left_hand else W_1D150
	var pause: int = wram1[own_pause]
	if pause != 0:
		if pause != 0x80:
			wram1[own_pause] = pause - 1
		elif left_hand:
			_hidden_figure_left_hand_catch()
		else:
			set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_RIGHT_HAND_STOP & 0xFFFF)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
			set_object_frameset_ptr(FRAMESET_6A11C)
		return
	var state: int = cur(OBJ_STATE)
	if state != 0:
		var hit: int = 0
		if left_hand and state == OBJSTATE_SPECIAL_3:
			hit = 0x80
		elif (state & 0xFE) == OBJSTATE_ATTACKED_LEFT_START:
			hit = 0x0A
		set_cur(OBJ_STATE, 0)
		if hit != 0:
			wram1[W_1D14E] = hit
			wram1[W_1D14F] = hit
			wram1[W_1D150] = hit
			return
	var attack: int = wram1[W_1D14B]
	var clap_8: bool = attack == 8
	if clap_8:
		_hidden_figure_move_x(DATA_4C700 if left_hand else DATA_4C760)
		_hidden_figure_move_y(DATA_4C800)
	else:
		_hidden_figure_move_x(DATA_4C380 if left_hand else DATA_4C480)
		_hidden_figure_move_y(DATA_4C600 if attack == 7 else DATA_4C400)
	var step: int = cur(OBJ_VAR_2)
	var closing: int = 0x4E if clap_8 else 0x62
	if step == 0x13:
		set_object_frameset_ptr(FRAMESET_6A0EF if left_hand else FRAMESET_6A119)
	elif step == closing:
		if left_hand:
			set_interaction(OBJ_INTERACTION_4F)
		set_object_frameset_ptr(FRAMESET_6A0C3 if left_hand else FRAMESET_6A0CF)
	elif left_hand and step == closing - 1:
		set_interaction(OBJ_INTERACTION_50)
	elif step == (0x5F if clap_8 else 0x7F):
		_hidden_figure_hand_reset(left_hand)


## .asm_4d1be: the left hand holds Wario (.Func_4d379): his position 1 px above and 6 px right of its
## own, in front (OBJFLAG_PRIORITY), Frameset_6a0f2 (stop_music2 not simulated).
func _hidden_figure_left_hand_catch() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, HIDDEN_FIGURE_LEFT_HAND_HOLD & 0xFFFF)
	wWarioYPos = word(cur_y() - 1)
	wWarioXPos = word(cur_x() + 6)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_PRIORITY)
	set_object_frameset_ptr(FRAMESET_6A0F2)


## .Func_4d37f (the left hand) and .Func_4d628 (the right): no actions until the figure collapses
## (w1d15f); then the left hand rises (.Func_4d39b, $20 frames, Frameset_6a0bc) and the right sinks
## (.Func_4d644, 30 frames, Frameset_6a0c8).
func _hidden_figure_hand_defeated(left_hand: bool) -> void:
	_no_actions()
	if wram1[W_1D15F] == 0:
		return
	set_object_frameset_ptr(FRAMESET_6A0BC if left_hand else FRAMESET_6A0C8)
	set_cur(OBJ_STATE_DURATION, 0x20 if left_hand else 0x1E)
	var function: int = HIDDEN_FIGURE_LEFT_HAND_RISE if left_hand else HIDDEN_FIGURE_RIGHT_HAND_SINK
	set_cur_word(OBJ_UPDATE_FUNCTION, function & 0xFFFF)


## .Func_4d39b: no actions; while OBJ_STATE_DURATION counts down (stopping at 0), a pixel up when the
## count before the decrement is even (`rra` tests the value read before `dec [hl]`): 16 px from $20.
func hidden_figure_left_hand_rise() -> void:
	_no_actions()
	var count: int = cur(OBJ_STATE_DURATION)
	if count == 0:
		return
	set_cur(OBJ_STATE_DURATION, count - 1)
	if (count & 1) == 0:
		move_object_up()


## .Func_4d644: the same, a pixel down when the count is odd: 15 px from 30.
func hidden_figure_right_hand_sink() -> void:
	_no_actions()
	var count: int = cur(OBJ_STATE_DURATION)
	if count == 0:
		return
	set_cur(OBJ_STATE_DURATION, count - 1)
	if (count & 1) != 0:
		move_object_down()


# --- A knocked hand (HiddenFigureRightHandFunc.Func_4d655) --------------------------------------

## .Func_4d655: a hand knocked loose, either hand, handled by OBJ_STATE through a table of its own
## (JumpTable doubles the index in a byte, so bit 7 is ignored); first the fight's scroll (wSCY
## wc08a plus wSCYShake, wSCX wc08c; SFX_06A every 16 frames outside $2d not simulated). Its own
## entries: falling ($30) by default (.Func_4d7dc); recovering ($01, $31); hops on bumps, attacks,
## wobbles, and stuns ($38, $39); a smash ($0a, away from Wario); picked up ($06, $07), grabbed and
## held ($18, $19, $48, $49), each marking w1d15d; tumbles ($14-$17, $46, $47); the return home ($2d);
## a fall after a moment ($2e). The rest are the shared routines the standard enemies' table has.
func hidden_figure_hand_knocked() -> void:
	wSCY = byte(wc08a + wSCYShake)
	wSCX = wc08c
	var state: int = cur(OBJ_STATE) & 0x7F
	match state:
		0x00, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, \
				0x2C, 0x2F, 0x34, 0x35, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40, 0x43, 0x58, 0x59, 0x5A, \
				0x5B, 0x5C, 0x5D, 0x5E, 0x5F:
			_hidden_figure_hand_fall_start()
		0x01:
			_hidden_figure_hand_recover_start()
		0x31:
			_hidden_figure_hand_recover()
		0x02, 0x04, 0x08, 0x0B, 0x29:
			_hidden_figure_hand_hop(0x38)  # .Func_4d83a
		0x03, 0x05, 0x09, 0x0C, 0x28:
			_hidden_figure_hand_hop(0x39)  # .Func_4d844
		0x0A:
			_hidden_figure_hand_smashed()
		0x06, 0x07:
			wram1[W_1D15D] = 1  # .Func_4d899, .Func_4d8b1
			enemy_picked_up_start(state == 0x06)
		0x18:
			_hidden_figure_hand_grab(false)
		0x19:
			_hidden_figure_hand_grab(true)
		0x48:
			_hidden_figure_hand_held(false)
		0x49:
			_hidden_figure_hand_held(true)
		0x14, 0x15:
			set_cur(OBJ_STATE, 0x44 if state == 0x14 else 0x45)  # .Func_4d859, .Func_4d861
			set_cur(OBJ_VAR_2, 2)
			set_cur(OBJ_VAR_3, 0)
		0x16, 0x17:
			set_cur(OBJ_STATE, 0x46 if state == 0x16 else 0x47)  # .Func_4d86f, .Func_4d876
		0x46, 0x47:
			_hidden_figure_hand_tumble(state == 0x46)
		0x2D:
			_hidden_figure_hand_return()
		0x2E:
			if cur(OBJ_STATE_DURATION) == 0:  # .Func_4d73e
				obj_state_fall()  # the state kept
			else:
				set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)  # SFX_VANISH not simulated
		0x4C, 0x4D:
			full_throw_flight(state == 0x4C)  # ObjState_FullThrowLeft, _Right, the state kept
		0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x30, 0x32, 0x33, 0x36, 0x37, 0x38, 0x39, 0x41, \
				0x42, 0x44, 0x45, 0x4A, 0x4B, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57:
			common_enemy_state(state)  # the standard enemies' entries for these states
		_:
			note_unported("HiddenFigureRightHandFunc.Func_4d655 state %02x" % state)


## .Func_4d7dc: falling (ObjState_Fall, $30), OBJ_VAR_3 0.
func _hidden_figure_hand_fall_start() -> void:
	set_cur(OBJ_STATE, 0x30)
	set_cur(OBJ_VAR_3, 0)


## .Func_4d83a and .Func_4d844: a hop (`state`: $38 rightwards, Func_31fa; $39 leftwards, Func_31dc),
## no actions for 15 frames, OBJ_STATE_DURATION 4, OBJ_VAR_2 2, OBJ_VAR_3 0.
func _hidden_figure_hand_hop(state: int) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 15)
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)


## .Func_4d824 ($0a): smashed (SFX_VANISH not simulated), it hops away from Wario: leftwards ($39)
## when its screen x is left of his (both plus $2a, as bytes), otherwise rightwards ($38).
func _hidden_figure_hand_smashed() -> void:
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		_hidden_figure_hand_hop(0x39)
	else:
		_hidden_figure_hand_hop(0x38)


## .Func_4d7e6 ($01): recovering ($31) for 70 frames, or 1 just after being held (w1d15d 1), the grab
## let go; then .Func_4d7fd.
func _hidden_figure_hand_recover_start() -> void:
	set_cur(OBJ_STATE, 0x31)
	set_cur(OBJ_STATE_DURATION, 1 if wram1[W_1D15D] == 1 else 0x46)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	_hidden_figure_hand_recover()


## .Func_4d7fd ($31): OBJ_STATE_DURATION counts down (wrapping); at 0 the return home ($2d): no
## actions, not in front, w1d15d cleared, Frameset_6a0d4 with HDIR set (the left hand's), _6a0fe
## otherwise.
func _hidden_figure_hand_recover() -> void:
	if not _hidden_figure_count_down():
		return
	_no_actions()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_PRIORITY)
	wram1[W_1D15D] = 0
	set_cur(OBJ_STATE, 0x2D)
	set_object_frameset_ptr(FRAMESET_6A0D4 if hdir() else FRAMESET_6A0FE)


## .Func_4d87d ($46) and .Func_4d88b ($47): Func_32ae (`left`: Func_62ae5) or Func_32bd (Func_62bce)
## while OBJ_VAR_2 lasts, then $0f (which falls next).
func _hidden_figure_hand_tumble(left: bool) -> void:
	if cur(OBJ_VAR_2) == 0:
		set_cur(OBJ_STATE, 0x0F)
	elif left:
		func_62ae5()
	else:
		func_62bce()


## .Func_4d8e1 ($18) and .Func_4d8c9 ($19): grabbed (OBJFLAG_GRABBED), w1d15d set, as OBJSTATE_48
## (`right` clear) or _49, then held.
func _hidden_figure_hand_grab(right: bool) -> void:
	wram1[W_1D15D] = 1
	set_cur(OBJ_STATE, OBJSTATE_49 if right else OBJSTATE_48)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)
	_hidden_figure_hand_held(right)


## .Func_4d8f0 (OBJSTATE_48) and .Func_4d8d8 (_49): held by Func_3362 (Func_622bd) with Wario facing
## left, by Func_3353 (Func_621fb) facing right; facing the other way, grabbed as the other state
## first (HDIR left as it is, unlike the standard enemies).
func _hidden_figure_hand_held(right: bool) -> void:
	if (wDirection != DIRECTION_LEFT) == right:
		held(right)
		return
	_hidden_figure_hand_grab(not right)


## .Func_4d750 ($2d): back to its home (w1d152 for the left hand, w1d156 for the right, by ID), no
## actions. There, its flag cleared (w1d14c, w1d14d) and waiting again (.asm_4d34c, .asm_4d5f5).
## Otherwise a pixel up while its y differs (never down: `jr nz` only tests for a difference), a
## pixel towards the home's x, and invisible on every 4th frame.
func _hidden_figure_hand_return() -> void:
	_no_actions()
	var left_hand: bool = cur(OBJ_ID) != HIDDEN_FIGURE_RIGHT_HAND
	var home: int = W_1D152 if left_hand else W_1D156
	var home_y: int = wram1[home] | (wram1[home + 1] << 8)
	var home_x: int = wram1[home + 2] | (wram1[home + 3] << 8)
	if cur_y() == home_y and cur_x() == home_x:
		wram1[W_1D14C if left_hand else W_1D14D] = 0
		_hidden_figure_hand_reset(left_hand)
		return
	if cur_y() != home_y:
		move_object_up()
	if cur_x() < home_x:
		move_object_right()
	elif cur_x() > home_x:
		move_object_left()
	if (wGlobalCounter & 0b11) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_INVISIBLE)
