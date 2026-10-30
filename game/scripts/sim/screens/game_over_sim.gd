class_name GameOverSim
extends MenuScreenSim
## The game over screen (GameOverStateTable, 01:47fd, farcalling _GameOverStateTable, 36:7277, in GFX
## RAM; src/engine/game_over/, WL3-052): after the hidden figure's fight is lost and the map's save
## screen (TransitionAfterSave's .game_over), the fade to white, InitGameOverScreen, the fade in, then
## UpdateGameOverScreen: Wario asleep while the screen and its text drop in from above and bounce, until
## A wakes him; Func_db3e4 lets his waking animation end, the fade to white, and GameOverReset (Init).
## The DebugReset entries jump to Init. The sounds and the music are not simulated.

const W_TEMP_BANK: int = 0xC0AC
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
const W_TRANSITION_PARAM: int = 0xCEE3
const W_TIMER: int = 0xCEE5
## GFX RAM (WRAMX bank 3): Wario (menu_obj_ext_struct: its state, wGameOverWarioVar, and whether its
## animation ended), wSFXTimer, and the text (wMenuObj1).
const W_GAME_OVER_WARIO: int = 0xD515
const W_GAME_OVER_WARIO_VAR: int = 0xD51D
const W_GAME_OVER_WARIO_ANIMATION_ENDED: int = 0xD520
const W_SFX_TIMER: int = 0xD522
const W_MENU_OBJ_1: int = 0xD523

## The bank the table runs in (the text's UpdateObjAnim by `call`, OAM_dbbd2), and Wario's ("Overworld
## OAM 1": his framesets, farcalled, and LoadGameOverSprite's OAM_aab5c).
const GAME_OVER_BANK: int = 0x36
const WARIO_OAM_BANK: int = 0x2A
const OAM_AAB5C: int = 0x6B5C
const OAM_DBBD2: int = 0x7BD2
const FRAMESET_AACCB: int = 0x6CCB
const FRAMESET_AACE2: int = 0x6CE2
const FRAMESET_DBBF5: int = 0x7BF5
## LoadGameOverPals: Pals_db509 and Pals_db549 to wTempPals1 and wTempPals2, then a palette of
## Pals_86ad5 over wTempPals2's first.
const PALS_DB509: String = "36:7509"
const PALS_DB549: String = "36:7549"
const PALS_86AD5: String = "21:6ad5"
const PALETTE_SIZE: int = 8
## InitGameOverScreen's scroll: the screen starts $60 lines down, and UpdateGameOverScreen brings it up
## 3 lines a loop; 64 loops before it starts (wTimer), and the bounce's 6 moves.
const GAME_OVER_SCY: int = 0x60
const GAME_OVER_WAIT: int = 64
const BOUNCE_MOVES: int = 6
## VBlank_GameOver: the scroll and the OAM (drawing only).
const VBLANK_GAME_OVER: int = 1
## GameOverReset's sub-state, and _GameOverStateTable's entries: sub-states 0-6, then DebugReset to $0f.
const SST_GAME_OVER_RESET: int = 6
const GAME_OVER_STATE_TABLE_SIZE: int = 0x10

## wTempBank and wTransitionParam (WRAM0, the screens' shared WRAM0; TRANSITION_GAME_OVER here), which
## the screen keeps.
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


## One game loop: _GameOverStateTable by wSubState (VBlank_GameOver writes no RAM).
func update() -> void:
	loops += 1
	screen_loads.clear()
	match sim.wSubState:
		0, 2, 5:
			fade(0)  # FastFadeToWhite, SlowFadeFromWhite, FastFadeToWhite
		1:
			init_game_over_screen()
		3:
			update_game_over_screen()
		4:
			func_db3e4()
		SST_GAME_OVER_RESET:
			sim.request_init()  # GameOverReset: jp Init
		_:
			if sim.wSubState < GAME_OVER_STATE_TABLE_SIZE:
				sim.request_init()  # DebugReset: jp Init
			else:
				_note("_GameOverStateTable sub-state %d (past the table)" % sim.wSubState)


## InitGameOverScreen: the screen (DisableLCD, FillBGMap0_With7f, LoadGameOverGfx, Func_db4cf: drawing)
## with LoadGameOverPals' palettes and VBlank_GameOver, the scroll at x 0, y $60; Wario at x $50, y $80
## on Frameset_aaccb, his state and wSFXTimer cleared, and the text at x $18, y $18 on Frameset_dbbf5,
## each animated and drawn; LCDC_DEFAULT (drawing), 64 loops (wTimer), and the next sub-state. The virtual
## OAM is not cleared after: the first UpdateGameOverScreen draws after these sprites.
func init_game_over_screen() -> void:
	clear_virtual_oam()
	_load_pals(PALS_DB509, W_TEMP_PALS_1, 0x40)  # LoadGameOverPals
	_load_pals(PALS_DB549, W_TEMP_PALS_2, 0x40)
	_load_pals(PALS_86AD5, W_TEMP_PALS_2, PALETTE_SIZE)
	screen_loads.append(["game_over"])
	vblank_func = VBLANK_GAME_OVER
	sim.wSCX = 0
	sim.wSCY = GAME_OVER_SCY
	set_up_obj(W_GAME_OVER_WARIO, 0x80, 0x50, FRAMESET_AACCB)
	w3(W_GAME_OVER_WARIO_VAR, 0)
	w3(W_SFX_TIMER, 0)
	update_obj_anim(W_GAME_OVER_WARIO, WARIO_OAM_BANK)
	load_game_over_sprite(W_GAME_OVER_WARIO)
	set_up_obj(W_MENU_OBJ_1, 0x18, 0x18, FRAMESET_DBBF5)
	update_obj_anim(W_MENU_OBJ_1, GAME_OVER_BANK)
	func_db4e9(W_MENU_OBJ_1)
	w0(W_TIMER, GAME_OVER_WAIT)
	sim.wSubState = byte(sim.wSubState + 1)


## UpdateGameOverScreen by wGameOverWarioVar: 0 (and any past 3) counts wTimer down, and at 0 the next
## (SFX_134); 1 scrolls the screen up 3 lines a loop, and at 0 the next with 6 moves in wTimer (SFX_061,
## MUSIC_GOLF_GAME_OVER); 2, on every 4th loop only (the others return before anything is drawn),
## moves it 2 lines down on odd counts and 2 up on even ones, and after the last the next
## (MUSIC_GAME_OVER); 3 waits for A (SFX_SELECTION), which starts Wario's Frameset_aace2 and the next
## sub-state. Then .asm_db3a9: Wario and the text animated and drawn.
func update_game_over_screen() -> void:
	var state: int = r3(W_GAME_OVER_WARIO_VAR)
	match state:
		1:  # .asm_db338
			sim.wSCY = byte(sim.wSCY - 3)
			if sim.wSCY == 0:
				w0(W_TIMER, BOUNCE_MOVES)
				w3(W_GAME_OVER_WARIO_VAR, state + 1)
		2:  # .asm_db35b
			if (sim.wGlobalCounter & 0b11) != 0:
				return
			var moves: int = byte(r0(W_TIMER) - 1)
			w0(W_TIMER, moves)
			if (moves & 1) != 0:
				sim.wSCY = byte(sim.wSCY + 2)
			else:
				sim.wSCY = byte(sim.wSCY - 2)
				if moves == 0:
					w3(W_GAME_OVER_WARIO_VAR, state + 1)
		3:  # .asm_db38a
			if (sim.wJoypadPressed & WarioRam.PAD_A) != 0:
				w3(W_GAME_OVER_WARIO + OBJ_FRAMESET_OFFSET, 0)
				w3(W_GAME_OVER_WARIO + OBJ_DURATION, 0)
				_set_frameset(W_GAME_OVER_WARIO, FRAMESET_AACE2)
				sim.wSubState = byte(sim.wSubState + 1)
		_:
			var timer: int = byte(r0(W_TIMER) - 1)
			w0(W_TIMER, timer)
			if timer == 0:
				w3(W_GAME_OVER_WARIO_VAR, byte(state + 1))
	# .asm_db3a9 (each end of Wario's animation plays SFX_SNORE: .Func_db3db)
	_update_wario()
	update_obj_anim(W_MENU_OBJ_1, GAME_OVER_BANK)
	func_db4e9(W_MENU_OBJ_1)
	clear_unused_virtual_oam()


## Func_db3e4: Wario and the text animated and drawn; at the end of Wario's animation the next
## sub-state.
func func_db3e4() -> void:
	_update_wario()
	update_obj_anim(W_MENU_OBJ_1, GAME_OVER_BANK)
	func_db4e9(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	if r3(W_GAME_OVER_WARIO_ANIMATION_ENDED) != 0:
		sim.wSubState = byte(sim.wSubState + 1)


## Wario's UpdateObjAnim (in bank $2a), whether it ended (wGameOverWarioAnimationEnded), and
## LoadGameOverSprite.
func _update_wario() -> void:
	update_obj_anim(W_GAME_OVER_WARIO, WARIO_OAM_BANK)
	w3(W_GAME_OVER_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_game_over_sprite(W_GAME_OVER_WARIO)


# --- the sprites ---

## LoadGameOverSprite (src/home/load_game_over_sprite.asm): an object's frame of OAM_aab5c (bank $2a)
## at its position (no scroll).
func load_game_over_sprite(obj: int) -> void:
	load_sprite("%02x:%04x" % [WARIO_OAM_BANK, OAM_AAB5C], r3(obj + OBJ_FRAME), byte(r3(obj + OBJ_Y) + OAM_Y_OFS),
			byte(r3(obj + OBJ_X) + OAM_X_OFS), r3(obj + OBJ_ATTRIBUTES))


## Func_db4e9: an object's frame of OAM_dbbd2 at its position less wSCY (it moves with the screen).
func func_db4e9(obj: int) -> void:
	load_sprite("%02x:%04x" % [GAME_OVER_BANK, OAM_DBBD2], r3(obj + OBJ_FRAME),
			byte(r3(obj + OBJ_Y) + OAM_Y_OFS - sim.wSCY), byte(r3(obj + OBJ_X) + OAM_X_OFS), r3(obj + OBJ_ATTRIBUTES))


# --- helpers ---

## LoadPalsToTempPals1 and 2, and CopyHLToDE_Short: `size` bytes of a palette set from game_over.json
## to `address`.
func _load_pals(key: String, address: int, size: int) -> void:
	var pals: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(key, "")).hex_decode()
	if pals.size() < size:
		_note("palettes %s not extracted" % key)
		return
	for offset: int in size:
		w0(address + offset, pals[offset])
