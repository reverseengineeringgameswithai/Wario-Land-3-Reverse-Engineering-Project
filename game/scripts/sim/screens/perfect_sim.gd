class_name PerfectSim
extends MenuScreenSim
## The Perfect screen (PerfectStateTable, 01:4817, farcalling _PerfectStateTable, 37:4000, in GFX RAM;
## src/engine/perfect/, WL3-052): after a perfect game's credits, or from the map with all the treasures
## outside Time Attack (SetPerfectState), the fade to white, InitPerfectScreen, the fade in, then
## UpdatePerfectScreen: its object animated while the screen fades in, again and again, to palettes 5-7
## cycling through four sets; outside Time Attack a button takes the pause menu's SST_PAUSE_28 with Time
## Attack opened. The DebugReset entries jump to Init. The music is not simulated.

const W_TEMP_BANK: int = 0xC0AC
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
## Set by the fades' set-up and cleared at their end; the original never reads it.
const W_UNUSED_C186: int = 0xC186
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_TRANSITION_PARAM: int = 0xCEE3
const W_TIMER: int = 0xCEE5
## GFX RAM (WRAMX bank 3): the palette cycle's count (the game over screen's Wario state, reused) and
## the object (wMenuObj1).
const W_GAME_OVER_WARIO_VAR: int = 0xD51D
const W_MENU_OBJ_1: int = 0xD523

## The bank the table runs in (UpdateObjAnim by `call`, OAM_dd710).
const PERFECT_BANK: int = 0x37
const OAM_DD710: int = 0x5710
const FRAMESET_DD848: int = 0x5848
## LoadPerfectPals: Pals_dc173 and Pals_dc1fb to wTempPals1 and wTempPals2; the cycle's palettes 5-7:
## Pals_dc1b3 (Func_dc10d), Pals_dc1cb (Func_dc119), Pals_dc1e3 (Func_dc125), and Pals_dc173's own
## (Func_dc101).
const PALS_DC173: String = "37:4173"
const PALS_DC1B3: String = "37:41b3"
const PALS_DC1CB: String = "37:41cb"
const PALS_DC1E3: String = "37:41e3"
const PALS_DC1FB: String = "37:41fb"
const CYCLED_PALS: int = 5 * 8  # palette 5's offset
const CYCLED_PALS_SIZE: int = 3 * 8
## The cycle's first set waits 240 loops before its fade.
const CYCLE_WAIT: int = 240
const SST_UPDATE_PERFECT: int = 3
const MODE_TIME_ATTACK: int = 0x02
const SST_PAUSE_28: int = 0x28
## VBlank_Perfect: the scroll and the OAM (drawing only).
const VBLANK_PERFECT: int = 1
## _PerfectStateTable's entries: sub-states 0-3, then DebugReset to $0c.
const PERFECT_STATE_TABLE_SIZE: int = 0x0D

## wTempBank and wTransitionParam (WRAM0, the screens' shared WRAM0), which the screen keeps.
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)
var wTransitionParam: int:
	get:
		return r0(W_TRANSITION_PARAM)
	set(value):
		w0(W_TRANSITION_PARAM, value)


## One game loop: _PerfectStateTable by wSubState (VBlank_Perfect writes no RAM).
func update() -> void:
	loops += 1
	screen_loads.clear()
	match sim.wSubState:
		0, 2:
			_fade(2)  # SlowFadeBGToWhite, DarkenBGToPal_Fast (FADE_SPEED_FAST)
		1:
			init_perfect_screen()
		SST_UPDATE_PERFECT:
			update_perfect_screen()
		_:
			if sim.wSubState < PERFECT_STATE_TABLE_SIZE:
				sim.request_init()  # DebugReset: jp Init
			else:
				_note("_PerfectStateTable sub-state %d (past the table)" % sim.wSubState)


## InitPerfectScreen: the screen (DisableLCD, FillBGMap0_With7f, LoadPerfectGfx, Func_dc13e: drawing)
## with LoadPerfectPals' palettes and VBlank_Perfect, the scroll at 0; the object at x $2b, y $23 on
## Frameset_dd848, animated and drawn; MUSIC_PERFECT (not simulated), LCDC_DEFAULT (drawing), wTimer and
## the cycle cleared, and the next sub-state. The virtual OAM is not cleared after: the first
## UpdatePerfectScreen draws after these sprites.
func init_perfect_screen() -> void:
	clear_virtual_oam()
	_copy_pals(PALS_DC173, 0, W_TEMP_PALS_1, 0x40)  # LoadPerfectPals
	_copy_pals(PALS_DC1FB, 0, W_TEMP_PALS_2, 0x40)
	screen_loads.append(["perfect"])
	vblank_func = VBLANK_PERFECT
	sim.wSCX = 0
	sim.wSCY = 0
	set_up_obj(W_MENU_OBJ_1, 0x23, 0x2B, FRAMESET_DD848)
	update_obj_anim(W_MENU_OBJ_1, PERFECT_BANK)
	func_dc158(W_MENU_OBJ_1)
	w0(W_TIMER, 0)
	w3(W_GAME_OVER_WARIO_VAR, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## UpdatePerfectScreen: the object animated and drawn. Once wTimer has counted down (or is 0), every 8th
## loop a step of SlowFadeInScreen; when one ends (it moves the sub-state on, put back here) the cycle
## counts: 1 waits 240 loops and takes Pals_dc1b3, 2 and 4 Pals_dc1cb, 3 Pals_dc1e3, 5 Pals_dc1b3, 6 (as
## 0) Pals_dc173's own, for wTempPals1's palettes 5-7 the next fade goes to. Outside Time Attack any
## button clears the fade, opens Time Attack, and takes the pause menu's SST_PAUSE_28.
func update_perfect_screen() -> void:
	update_obj_anim(W_MENU_OBJ_1, PERFECT_BANK)
	func_dc158(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	var timer: int = r0(W_TIMER)
	if timer != 0:
		w0(W_TIMER, timer - 1)
	if timer <= 1 and (sim.wGlobalCounter & 0b111) == 0:  # .asm_dc08c
		_slow_fade_in_screen()
		if sim.wSubState != SST_UPDATE_PERFECT:
			sim.wSubState = SST_UPDATE_PERFECT
			var cycle: int = byte(r3(W_GAME_OVER_WARIO_VAR) + 1)
			w3(W_GAME_OVER_WARIO_VAR, cycle)
			match cycle:
				1:
					w0(W_TIMER, CYCLE_WAIT)
					_copy_pals(PALS_DC1B3, 0, W_TEMP_PALS_1 + CYCLED_PALS, CYCLED_PALS_SIZE)  # Func_dc10d
				5:
					_copy_pals(PALS_DC1B3, 0, W_TEMP_PALS_1 + CYCLED_PALS, CYCLED_PALS_SIZE)  # Func_dc10d
				2, 4:
					_copy_pals(PALS_DC1CB, 0, W_TEMP_PALS_1 + CYCLED_PALS, CYCLED_PALS_SIZE)  # Func_dc119
				3:
					_copy_pals(PALS_DC1E3, 0, W_TEMP_PALS_1 + CYCLED_PALS, CYCLED_PALS_SIZE)  # Func_dc125
				_:
					w3(W_GAME_OVER_WARIO_VAR, 0)
					_copy_pals(PALS_DC173, CYCLED_PALS, W_TEMP_PALS_1 + CYCLED_PALS, CYCLED_PALS_SIZE)  # Func_dc101
	# .asm_dc0cf
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0 or sim.wJoypadPressed == 0:
		return
	sim.wFadeSpeed = 0
	sim.wPalFadeCounter = 0
	w0(W_UNUSED_C186, 0)
	w0(W_GAME_MODE_FLAGS, r0(W_GAME_MODE_FLAGS) | MODE_TIME_ATTACK)
	sim.wState = LevelSim.ST_PAUSE_MENU
	sim.wSubState = SST_PAUSE_28


## Func_dc158: the object's frame of OAM_dd710 at its position (no scroll).
func func_dc158(obj: int) -> void:
	load_sprite("%02x:%04x" % [PERFECT_BANK, OAM_DD710], r3(obj + OBJ_FRAME), byte(r3(obj + OBJ_Y) + OAM_Y_OFS),
			byte(r3(obj + OBJ_X) + OAM_X_OFS), r3(obj + OBJ_ATTRIBUTES))


# --- helpers ---

## A fade's loop at `speed` (FadeBGToWhite, DarkenBGToPal) with wUnused_c186 (_keep_c186).
func _fade(speed: int) -> void:
	_keep_c186(func() -> void: fade(speed))


## A loop of SlowFadeInScreen with wUnused_c186 (_keep_c186); its step is drawn toward the palettes as
## they are now ("fade_in_step" with them): the cycle may change them after it in the same loop.
func _slow_fade_in_screen() -> void:
	var loads: int = screen_loads.size()
	_keep_c186(slow_fade_in_screen)
	if screen_loads.size() > loads:
		screen_loads[-1] = ["fade_in_step", wram[0].slice(0, 0x80)]


## The fades set wUnused_c186 at their set-up (wPalFadeCounter 0) and clear it at their end (the
## sub-state moved on).
func _keep_c186(step: Callable) -> void:
	var setting_up: bool = sim.wPalFadeCounter == 0
	var substate: int = sim.wSubState
	step.call()
	if setting_up:
		w0(W_UNUSED_C186, 1)
	elif sim.wSubState != substate:
		w0(W_UNUSED_C186, 0)


## LoadPalsToTempPals1 and 2, and CopyHLToDE_Short: `size` bytes of a palette set from perfect.json, from
## `offset`, to `address`.
func _copy_pals(key: String, offset: int, address: int, size: int) -> void:
	var pals: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(key, "")).hex_decode()
	if pals.size() < offset + size:
		_note("palettes %s not extracted" % key)
		return
	for index: int in size:
		w0(address + index, pals[offset + index])
