class_name ActionHelpCommon
extends MenuScreenSim
## Action Help's shared routines (src/engine/action_help/common1.asm, common2.asm), ported by
## translation (WL3-051): the d-pad's and buttons' inputs shown, the demos' Wario and objects (each
## shown by its frameset and OAM table, Wario's tiles by DMA at V-Blank), the palettes, the sprites,
## and a demo's end. The demos (ActionHelpDemos to ActionHelpSpecialDemos) and the state table
## (ActionHelpSim) build on it. Framesets and OAM tables are given by their address in the bank
## they are read in: Frameset_15f97 is $5f97 in bank $05.

# WRAM0 (src/ram/wram.asm), shared with the other screens
const W_TEMP_BANK: int = 0xC0AC
# WRAMX bank 3 (src/ram/wram.asm)
const W_DPAD_REPEAT_COUNTER: int = 0xD502
const W_ACTION_HELP_BLACKED_OUT: int = 0xD509
const W_ACTION_HELP_COUNTER: int = 0xD50A
const W_ACTION_HELP_POWER_UP: int = 0xD50B
const W_ACTION_HELP_STATE: int = 0xD50C
const W3D50D: int = 0xD50D
const W_ACTION_HELP_FROZEN: int = 0xD50E
const W_ACTION_HELP_WARIO: int = 0xD515
const W_ACTION_HELP_WARIO_VAR: int = 0xD51D
const W_ACTION_HELP_WARIO_OAM_PTR: int = 0xD51E
const W_ACTION_HELP_WARIO_ANIMATION_ENDED: int = 0xD520
const W_ACTION_HELP_WARIO_OAM_BANK: int = 0xD521
const W_SFX_TIMER: int = 0xD522
const W_MENU_OBJ_1: int = 0xD523
const W_MENU_OBJ_2: int = 0xD52B
const W_MENU_OBJ_3: int = 0xD533
const W_MENU_OBJ_4: int = 0xD53B
const W_MENU_OBJ_5: int = 0xD547
const W_MENU_OBJ_6: int = 0xD553
const W_MENU_OBJ_7: int = 0xD55E
# Objects 4 to 7 go on after menu_obj_struct: their OAM table (high byte first), its bank (where
# their framesets are read too), and, but for object 6, whether their animation last started over.
const OBJ_OAM_PTR: int = 8
const OBJ_OAM_BANK: int = 10
const OBJ_ANIMATION_ENDED: int = 11
# WRAM0
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
const W_IS_DMA_TRANSFER_PENDING: int = 0xC1A0
const W_PENDING_DMA_SOURCE_BANK: int = 0xC1A1
const W_PENDING_DMA_SOURCE_PTR: int = 0xC1A2
const W_PENDING_DMA_DESTINATION_BANK: int = 0xC1A4
const W_PENDING_DMA_DESTINATION_PTR: int = 0xC1A5
const W_PENDING_DMA_LENGTH: int = 0xC1A7
const W_TIMER: int = 0xCEE5

# src/constants/: the power-ups, Action Help's flags in wPowerUpLevel, and the transformations it
# shows.
const NO_POWER_UP: int = 0
const LEAD_OVERALLS: int = 1
const SWIMMING_FLIPPERS: int = 2
const HEAD_SMASH_HELMET: int = 3
const GRAB_GLOVE: int = 4
const GARLIC: int = 5
const SUPER_JUMP_SLAM_OVERALLS: int = 6
const HIGH_JUMP_BOOTS: int = 7
const PRINCE_FROGS_GLOVES: int = 8
const SUPER_GRAB_GLOVES: int = 9
const NUM_MAIN_POWER_UPS: int = 10
const POWER_UP_OWL: int = 10
const POWER_UP_RAIL: int = 11
const POWER_UP_VAMPIRE: int = 12
const NUM_TOTAL_POWER_UPS: int = 13
const POWER_UP_MASK: int = 0x3F
const ACTION_HELP_TITLE_SCREEN: int = 0x40
const ACTION_HELP_LEVEL_CLEAR: int = 0x80
const TRANSFORMATION_OWL_WARIO: int = 0x0E
const TRANSFORMATION_RAIL: int = 0x0F
const TRANSFORMATION_VAMPIRE_WARIO: int = 0x4B
const ST_OVERWORLD: int = 0x01
const ST_PAUSE_MENU: int = 0x04
const SST_PAUSE_INIT_MENU: int = 0x01

## The banks: Action Help's second (its menu objects' framesets and OAM_1e697c, `farcall $79`) and
## the level's Wario (`farcall $5`).
const ACTION_HELP_2_BANK: int = 0x79
const WARIO_BANK: int = 0x05
const OAM_ACTION_HELP: String = "79:697c"  # LoadActionHelpSprite
## Wario's tiles (bank << 16 | address), $80 tiles each.
const WARIO_IDLE_GFX: int = 0x044000
const WARIO_WALK_GFX: int = 0x044800
const WARIO_ATTACK_GFX: int = 0x045800
const WARIO_SWIM_GFX: int = 0x046000
const WARIO_THROW_GFX: int = 0x047000
const WARIO_AIRBORNE_GFX: int = 0x047800
const WARIO_SLIDE_GFX: int = 0x095000
const WARIO_BAT_GFX: int = 0x0B5800
const WARIO_VAMPIRE_GFX: int = 0x0B6000
const WARIO_HANG_GFX: int = 0x0B7800
## The palettes (Pals_1e4e6f and the others, bank $79).
const PALS_WITH_WATER: String = "79:4e6f"
const PALS_WITHOUT_WATER: String = "79:4eaf"
const PALS_BLACKED_OUT: String = "79:4eef"
const PALS_MAIN_POWER_UP: String = "79:4f2f"
const PALS_GARLIC: String = "79:4f6f"
const PALS_SPECIAL_POWER_UP: String = "79:4f7f"
const PALS_VAMPIRE: String = "79:4fbf"
## The BG map 1 entry of the cursor's first power-up (hlbgcoord 0, 16, v1BGMap1).
const CURSOR_ROW: int = 0x9E00

## The V-Blank functions: Action Help's (VBlank_1fb6b7: the pending DMA, the scroll, the OAM).
enum VBlankFunc { NONE, ACTION_HELP }

## wTempBank (WRAM0, shared with the other screens): the bank of the last far object's animation or
## sprite.
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)
## For drawing: this loop's palettes written to the hardware ([is OBJ, first byte, bytes]), its BG
## writes ([bank, address, value]), and the tiles the V-Blank's DMA copied ([source, destination]).
var palette_writes: Array = []
var vram_writes: Array = []
var dma_writes: Array = []


func _jump_vel(index: int) -> int:
	return _table("jump_vel_table_normal", index & 0xFF)


func _palettes(key: String) -> PackedByteArray:
	return String(document.get("gfx", {}).get("palettes", {}).get(key, "")).hex_decode()


# --- the demos' steps ---

## wActionHelpState's next step.
func next_state() -> void:
	w3(W_ACTION_HELP_STATE, r3(W_ACTION_HELP_STATE) + 1)


## `ld hl, wTimer; dec [hl]; ret nz`: whether wTimer's count down reached 0.
func timer_done() -> bool:
	w0(W_TIMER, r0(W_TIMER) - 1)
	return r0(W_TIMER) == 0


## `ld hl, wTimer; ld a, [hl]; and a; jr z; dec [hl]; ret`: whether wTimer was already 0 (if not,
## it counts down).
func timer_waited() -> bool:
	if r0(W_TIMER) == 0:
		return true
	w0(W_TIMER, r0(W_TIMER) - 1)
	return false


## A jump's step: wActionHelpWarioVar on, and Wario's y by JumpVelTable_Normal at it; the new y.
func wario_jump_step() -> int:
	w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) + 1)
	var y: int = byte(r3(W_ACTION_HELP_WARIO + OBJ_Y) + _jump_vel(r3(W_ACTION_HELP_WARIO_VAR)))
	w3(W_ACTION_HELP_WARIO + OBJ_Y, y)
	return y


## `dec [hl]` and, on odd counts, again: an object coming in from the right at 1.5 pixels a loop;
## its new x.
func move_left_1_5(obj: int) -> int:
	var x: int = byte(r3(obj + OBJ_X) - 1)
	if (r3(W_ACTION_HELP_COUNTER) & 1) != 0:
		x = byte(x - 1)
	w3(obj + OBJ_X, x)
	return x


## play_sfx_rept: wSFXTimer counts down, and when it passes 0 starts again at `count` (the sound
## itself is not ported).
func play_sfx_rept(count: int) -> void:
	var timer: int = r3(W_SFX_TIMER) - 1
	w3(W_SFX_TIMER, timer if timer >= 0 else count)


# --- common1.asm ---

## ActionHelp_FlashDDownInput and the others: the demo frozen while an input flashes on every
## fourth loop, seven flashes; then on.
func _flash_input(show: Callable, hide: Callable) -> void:
	w3(W_ACTION_HELP_FROZEN, 1)
	if (r3(W_ACTION_HELP_COUNTER) & 0b11) != 0:
		return
	w0(W_TIMER, r0(W_TIMER) + 1)
	if (r0(W_TIMER) & 1) == 0:
		hide.call()
		return
	show.call()
	if r0(W_TIMER) < 7:
		return
	w0(W_TIMER, 0)
	w3(W_ACTION_HELP_FROZEN, 0)
	next_state()


func flash_d_down_input() -> void:
	_flash_input(show_d_down_input, clear_d_pad_input)


func flash_d_up_input() -> void:
	_flash_input(show_d_up_input, clear_d_pad_input)


func flash_b_input() -> void:
	_flash_input(show_b_input, clear_buttons_input)


func flash_a_input() -> void:
	_flash_input(show_a_input, clear_buttons_input)


## ActionHelp_Init: the room animation stopped, the screen blacked out (Func_1e48bc), the power-up's
## OBJ palettes (Func_1e4a47), no inputs, and $60 loops before the demo.
func action_help_init() -> void:
	sim.wAnimatedTilesFrameDuration = 0
	sim.wAnimatedTilesGfx = 0
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	w3(W_ACTION_HELP_FROZEN, 0)
	sim.wRoomAnimatedTilesEnabled = 0
	sim.wSCY = 4
	black_out_bg_pals()
	load_power_up_ob_pals_4_to_7()
	clear_d_pad_input()
	clear_buttons_input()
	w0(W_TIMER, 0x60)
	next_state()


## Func_1fb6f7: right or left (not on the title screen or after a level's clear) moves the cursor
## to the next or previous main power-up and starts its demo blacked out; the old power-up's entry
## goes back to the plain attribute ($03) and the new one's takes its colour (PowerUpOBPals), each
## if Wario has it.
func switch_power_up() -> void:
	var old: int = r3(W_ACTION_HELP_POWER_UP)
	if (sim.wJoypadPressed & WarioRam.PAD_RIGHT) != 0:
		if old == NUM_MAIN_POWER_UPS - 1:
			return
		w3(W_ACTION_HELP_POWER_UP, old + 1)
		w3(W_ACTION_HELP_STATE, 0)
		w3(W_MENU_OBJ_1 + OBJ_X, r3(W_MENU_OBJ_1 + OBJ_X) + 0x10)
	elif (sim.wJoypadPressed & WarioRam.PAD_LEFT) != 0:
		if old == 0:
			return
		w3(W_ACTION_HELP_POWER_UP, old - 1)
		w3(W_ACTION_HELP_STATE, 0)
		w3(W_MENU_OBJ_1 + OBJ_X, r3(W_MENU_OBJ_1 + OBJ_X) - 0x10)
	else:
		return
	w3(W_ACTION_HELP_BLACKED_OUT, 1)
	var level: int = sim.wPowerUpLevel & POWER_UP_MASK
	if level >= old:
		_cursor_attribute(old, 0x03)
	var new: int = r3(W_ACTION_HELP_POWER_UP)
	if level >= new:
		_cursor_attribute(new, _table("power_up_ob_pals", new))


## A power-up's 2x2 attribute entries on the cursor's row (BG map 1, bank 1).
func _cursor_attribute(power_up: int, value: int) -> void:
	var address: int = CURSOR_ROW + byte(power_up * 2)
	for offset: int in [0, 1, ScreenVram.MAP_WIDTH, ScreenVram.MAP_WIDTH + 1]:
		vram_writes.append([1, address + offset, value])


## A menu object's frameset from its start (offset and duration cleared).
func _restart_frameset(obj: int, frameset: int) -> void:
	w3(obj + OBJ_FRAMESET_OFFSET, 0)
	w3(obj + OBJ_DURATION, 0)
	_set_frameset(obj, frameset)


## ActionHelp_ClearDPadInput and the d-pad's inputs (object 2), Frameset_1e6b76 to _1e6ba8.
func clear_d_pad_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6B76)


func show_d_right_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6B7C)


func show_d_left_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6B82)


func show_d_down_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6B7F)


func show_d_up_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6B79)


func show_d_right_and_d_down_input() -> void:
	_restart_frameset(W_MENU_OBJ_2, 0x6BA8)


## ActionHelp_ClearButtonsInput and the buttons' inputs (object 3).
func clear_buttons_input() -> void:
	_restart_frameset(W_MENU_OBJ_3, 0x6B6D)


func show_a_input() -> void:
	_restart_frameset(W_MENU_OBJ_3, 0x6B70)


func show_b_input() -> void:
	_restart_frameset(W_MENU_OBJ_3, 0x6B73)


## A far object (4 to 7) set up at (y, x) with its frameset, OAM table, and bank; `ended` clears
## its AnimationEnded too (as the routines that write it do).
func set_up_far_obj(obj: int, y: int, x: int, frameset: int, oam: int, bank: int, ended: bool) -> void:
	set_up_obj(obj, y, x, frameset)
	_set_far_oam(obj, oam, bank)
	if ended:
		w3(obj + OBJ_ANIMATION_ENDED, 0)


func _set_far_oam(obj: int, oam: int, bank: int) -> void:
	w3(obj + OBJ_OAM_PTR, oam >> 8)
	w3(obj + OBJ_OAM_PTR + 1, oam)
	w3(obj + OBJ_OAM_BANK, bank)


## ActionHelp_HideObj5BlockDebris, ActionHelp_HideBlockDebris: off screen, Frameset_1e6b64.
func hide_block_debris(obj: int = W_MENU_OBJ_5) -> void:
	set_up_far_obj(obj, 0xA0, 0xE8, 0x6B64, 0x697C, ACTION_HELP_2_BANK, true)


## ActionHelp_ShowBlockDebrisWithYOffset (object 5, no x offset) and ActionHelp_ShowBlockDebris:
## the debris (Frameset_d49a, OAM_d20e in bank $03) at object 4's place less the offsets.
func show_block_debris(y_offset: int, x_offset: int = 0, obj: int = W_MENU_OBJ_5) -> void:
	set_up_far_obj(obj, byte(r3(W_MENU_OBJ_4 + OBJ_Y) - y_offset), byte(r3(W_MENU_OBJ_4 + OBJ_X) - x_offset),
			0x549A, 0x520E, 0x03, true)


# Wario: his tiles by DMA, his frameset from its start, his OAM table (bank $05's, or with an OAM
# bank wActionHelpWarioOAMBank's).

## Wario's tiles: $80 tiles to VRAM 0's $8000 at the next V-Blank (wPendingDMA*).
func _dma_wario_gfx(gfx: int) -> void:
	w0(W_PENDING_DMA_SOURCE_BANK, gfx >> 16)
	w0(W_PENDING_DMA_SOURCE_PTR, gfx >> 8)
	w0(W_PENDING_DMA_SOURCE_PTR + 1, gfx)
	w0(W_PENDING_DMA_DESTINATION_PTR, 0x80)
	w0(W_PENDING_DMA_DESTINATION_PTR + 1, 0x00)
	w0(W_PENDING_DMA_DESTINATION_BANK, 0)
	w0(W_PENDING_DMA_LENGTH, 0x80 - 1)
	w0(W_IS_DMA_TRANSFER_PENDING, 1)


func _wario_frameset(frameset: int) -> void:
	_restart_frameset(W_ACTION_HELP_WARIO, frameset)


func _wario_oam(oam: int, bank: int = -1) -> void:
	w3(W_ACTION_HELP_WARIO_OAM_PTR, oam >> 8)
	w3(W_ACTION_HELP_WARIO_OAM_PTR + 1, oam)
	if bank >= 0:
		w3(W_ACTION_HELP_WARIO_OAM_BANK, bank)


## Wario shown with new tiles: `gfx`, `frameset`, and `oam`.
func _show_wario(gfx: int, frameset: int, oam: int) -> void:
	_dma_wario_gfx(gfx)
	_wario_frameset(frameset)
	_wario_oam(oam)


## ActionHelp_ShowInitialWarioWalk: Wario at ($40, $40) walking, his var and wSFXTimer cleared.
func show_initial_wario_walk() -> void:
	_dma_wario_gfx(WARIO_WALK_GFX)
	set_up_obj(W_ACTION_HELP_WARIO, 0x40, 0x40, 0x49C5)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_SFX_TIMER, 0)
	_wario_oam(0x426C)


func show_wario_jump() -> void:
	_show_wario(WARIO_AIRBORNE_GFX, 0x5F97, 0x5955)
	w3(W_ACTION_HELP_WARIO_VAR, 0)


func show_wario_jump_left() -> void:
	_show_wario(WARIO_AIRBORNE_GFX, 0x5F94, 0x5955)
	w3(W_ACTION_HELP_WARIO_VAR, 0)


## ActionHelp_ShowWarioSmashAttack: the super jump slam's from SUPER_JUMP_SLAM_OVERALLS on; his var
## at $18 (the jump's fall).
func show_wario_smash_attack() -> void:
	_wario_frameset(0x6055 if r3(W_ACTION_HELP_POWER_UP) >= SUPER_JUMP_SLAM_OVERALLS else 0x5F91)
	w3(W_ACTION_HELP_WARIO_VAR, 0x18)


func show_wario_ground_pound() -> void:
	_wario_frameset(0x6009)


func show_wario_ground_shake() -> void:
	_wario_frameset(0x5FC5)


func show_wario_land() -> void:
	_wario_frameset(0x5FA1)


func show_wario_idle() -> void:
	_show_wario(WARIO_IDLE_GFX, 0x425F, 0x4000)


func show_wario_walk() -> void:
	_show_wario(WARIO_WALK_GFX, 0x49C5, 0x426C)


func show_wario_swim() -> void:
	_show_wario(WARIO_SWIM_GFX, 0x555B, 0x5254)


func show_wario_swim_left() -> void:
	_wario_frameset(0x5554)


func show_wario_submerge() -> void:
	_wario_frameset(0x558B)
	w3(W_SFX_TIMER, 0)


func show_wario_underwater_thrust() -> void:
	_wario_frameset(0x55C5)
	w3(W_SFX_TIMER, 0)


func show_wario_underwater_stopped() -> void:
	_wario_frameset(0x556C)


func show_wario_grab() -> void:
	_show_wario(WARIO_THROW_GFX, 0x640C, 0x606A)


func show_wario_slow_grab() -> void:
	_show_wario(WARIO_THROW_GFX, 0x6415, 0x606A)


func show_wario_begin_grab() -> void:
	_show_wario(WARIO_WALK_GFX, 0x4A23, 0x426C)


func show_wario_grab_walk() -> void:
	_wario_frameset(0x4A0F)


func show_wario_begin_throw() -> void:
	_show_wario(WARIO_THROW_GFX, 0x642F, 0x606A)


func show_wario_throw() -> void:
	_wario_frameset(0x641E)


func show_wario_charge_throw() -> void:
	_wario_frameset(0x6435)
	w3(W_SFX_TIMER, 0)


func show_wario_fully_charged_grab() -> void:
	_wario_frameset(0x6441)


func show_wario_fully_charged_throw() -> void:
	_wario_frameset(0x6423)


## ActionHelp_ShowWarioAttack: the garlic's charge from GARLIC on.
func show_wario_attack() -> void:
	w3(W_SFX_TIMER, 0)
	_show_wario(WARIO_ATTACK_GFX, 0x522D if r3(W_ACTION_HELP_POWER_UP) >= GARLIC else 0x51FD, 0x4D1B)


func show_wario_roll() -> void:
	_wario_frameset(0x66F7)


func show_wario_bump() -> void:
	_show_wario(WARIO_AIRBORNE_GFX, 0x5F7F, 0x5955)


func show_wario_slide() -> void:
	_show_wario(WARIO_SLIDE_GFX, 0x671D, 0x644A)


# The demos' other objects (object 4 unless named; bank $79's OAM_1e6bab enemies, OAM_1e697c
# blocks).

func show_para_goom_walk() -> void:
	set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6F36, 0x6BAB, ACTION_HELP_2_BANK, true)


func show_para_goom_stun() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F48)


func show_para_goom_thrown() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F3F)


## ActionHelp_ShowObj4EnemyVanish and ActionHelp_ShowEnemyVanish: Frameset_d4a5 with OAM_d20e in
## bank $03 (its AnimationEnded kept).
func show_enemy_vanish(obj: int = W_MENU_OBJ_4) -> void:
	_restart_frameset(obj, 0x54A5)
	_set_far_oam(obj, 0x520E, 0x03)


func show_futamogu_angry() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F78)


func show_futamogu_happy() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F66)


func show_count_richtertoff_idle() -> void:
	set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6F4D, 0x6BAB, ACTION_HELP_2_BANK, false)


func show_count_richtertoff_stun() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F5E)


func show_count_richtertoff_thrown() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6F55)


func show_single_solid_block() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6B67)


func show_vertical_block_pair() -> void:
	set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6B93, 0x697C, ACTION_HELP_2_BANK, false)


func show_slide() -> void:
	set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xD8, 0x6B88, 0x697C, ACTION_HELP_2_BANK, false)


## ActionHelp_ShowOverheadPillar: object 6 (which has no AnimationEnded).
func show_overhead_pillar() -> void:
	set_up_far_obj(W_MENU_OBJ_6, 0x20, 0xE8, 0x6B85, 0x697C, ACTION_HELP_2_BANK, false)


# --- common2.asm: the palettes ---

## LoadActionHelpPalsWithWater, LoadActionHelpPalsWithoutWater: the screen shown (no longer blacked
## out) with its BG palettes and the power-up's OBJ palettes.
func load_pals_with_water() -> void:
	w3(W_ACTION_HELP_BLACKED_OUT, 0)
	_load_bg_pals(PALS_WITH_WATER)
	_load_ob_pals()


func load_pals_without_water() -> void:
	w3(W_ACTION_HELP_BLACKED_OUT, 0)
	_load_bg_pals(PALS_WITHOUT_WATER)
	_load_ob_pals()


## Func_1e48bc: the screen blacked out.
func black_out_bg_pals() -> void:
	w3(W_ACTION_HELP_BLACKED_OUT, 1)
	_load_bg_pals(PALS_BLACKED_OUT)


## LoadActionHelpCommonPals: blacked out, its palettes into wTempPals1 only (the fade in shows them).
func load_common_pals() -> void:
	w3(W_ACTION_HELP_BLACKED_OUT, 1)
	_copy_pals(_palettes(PALS_BLACKED_OUT), W_TEMP_PALS_1, 0x40)


## LoadActionHelpPowerUpPals: the OBJ palettes into wTempPals2: the main power-ups' (the first two
## from Pals_1e4f6f from GARLIC on) or the special ones' (the vampire's first two from Pals_1e4fbf).
func load_power_up_pals() -> void:
	var power_up: int = r3(W_ACTION_HELP_POWER_UP) & POWER_UP_MASK
	if power_up >= NUM_MAIN_POWER_UPS:
		_copy_pals(_palettes(PALS_SPECIAL_POWER_UP), W_TEMP_PALS_2, 0x40)
		if r3(W_ACTION_HELP_POWER_UP) == POWER_UP_VAMPIRE:
			_copy_pals(_palettes(PALS_VAMPIRE), W_TEMP_PALS_2, 0x10)
		return
	_copy_pals(_palettes(PALS_MAIN_POWER_UP), W_TEMP_PALS_2, 0x40)
	if r3(W_ACTION_HELP_POWER_UP) >= GARLIC:
		_copy_pals(_palettes(PALS_GARLIC), W_TEMP_PALS_2, 0x10)


func _copy_pals(bytes: PackedByteArray, to: int, size: int) -> void:
	for offset: int in size:
		w0(to + offset, bytes[offset] if offset < bytes.size() else 0)


func _fill_pals(to: int, size: int) -> void:
	for offset: int in size:
		w0(to + offset, 0)


func _wram0_bytes(from: int, size: int) -> PackedByteArray:
	return wram[0].slice(from - 0xC000, from - 0xC000 + size)


## LoadActionHelpBGPals: into wTempPals1 and the hardware.
func _load_bg_pals(key: String) -> void:
	var bytes: PackedByteArray = _palettes(key)
	_copy_pals(bytes, W_TEMP_PALS_1, 0x40)
	palette_writes.append([false, 0, bytes.slice(0, 0x40)])


## LoadActionHelpOBPals (main power-ups only): Pals_1e4f2f into wTempPals2 when Wario has the
## power-up; without it, all but palette 2 of wTempPals2 black. Then the hardware from wTempPals2.
func _load_ob_pals() -> void:
	var power_up: int = r3(W_ACTION_HELP_POWER_UP)
	if power_up >= NUM_MAIN_POWER_UPS:
		return
	if (sim.wPowerUpLevel & POWER_UP_MASK) >= power_up:
		_copy_pals(_palettes(PALS_MAIN_POWER_UP), W_TEMP_PALS_2, 0x40)
	else:
		_fill_pals(W_TEMP_PALS_2, 0x10)
		_fill_pals(W_TEMP_PALS_2 + 0x18, 0x28)
	palette_writes.append([true, 0, _wram0_bytes(W_TEMP_PALS_2, 0x40)])


## Func_1e4a47 (main power-ups only): OBJ palettes 4 and 7 of wTempPals2 from Pals_1e4f2f's, or
## black without the power-up; the hardware's 4 to 7 from Pals_1e4f2f's or wTempPals2's.
func load_power_up_ob_pals_4_to_7() -> void:
	var power_up: int = r3(W_ACTION_HELP_POWER_UP)
	if power_up >= NUM_MAIN_POWER_UPS:
		return
	var pals: PackedByteArray = _palettes(PALS_MAIN_POWER_UP)
	if (sim.wPowerUpLevel & POWER_UP_MASK) >= power_up:
		_copy_pals(pals.slice(0x20, 0x28), W_TEMP_PALS_2 + 0x20, 0x08)
		_copy_pals(pals.slice(0x38, 0x40), W_TEMP_PALS_2 + 0x38, 0x08)
		palette_writes.append([true, 0x20, pals.slice(0x20, 0x40)])
	else:
		_fill_pals(W_TEMP_PALS_2 + 0x20, 0x08)
		_fill_pals(W_TEMP_PALS_2 + 0x38, 0x08)
		palette_writes.append([true, 0x20, _wram0_bytes(W_TEMP_PALS_2 + 0x20, 0x20)])


# --- common2.asm: the sprites ---

## The object's frame of `table` at its place less the scroll (LoadSprite's position).
func _load_obj_sprite(obj: int, table: String) -> void:
	load_sprite(table, r3(obj + OBJ_FRAME), byte(r3(obj + OBJ_Y) - sim.wSCY + OAM_Y_OFS),
			byte(r3(obj + OBJ_X) + OAM_X_OFS), r3(obj + OBJ_ATTRIBUTES))


## LoadActionHelpSprite: OAM_1e697c (the cursor, d-pad, and buttons).
func load_action_help_sprite(obj: int) -> void:
	_load_obj_sprite(obj, OAM_ACTION_HELP)


## LoadActionHelpSprite_Far: the object's own OAM table, in its bank.
func load_action_help_sprite_far(obj: int) -> void:
	wTempBank = r3(obj + OBJ_OAM_BANK)
	_load_obj_sprite(obj, "%02x:%04x" % [wTempBank, (r3(obj + OBJ_OAM_PTR) << 8) | r3(obj + OBJ_OAM_PTR + 1)])


## LoadActionHelpWarioSprite: Wario's OAM table in bank $05.
func load_action_help_wario_sprite() -> void:
	_load_obj_sprite(W_ACTION_HELP_WARIO, "%02x:%04x" % [WARIO_BANK, _wario_oam_ptr()])


## LoadActionHelpWarioSprite_FromBank: in wActionHelpWarioOAMBank.
func load_action_help_wario_sprite_from_bank() -> void:
	wTempBank = r3(W_ACTION_HELP_WARIO_OAM_BANK)
	_load_obj_sprite(W_ACTION_HELP_WARIO, "%02x:%04x" % [wTempBank, _wario_oam_ptr()])


func _wario_oam_ptr() -> int:
	return (r3(W_ACTION_HELP_WARIO_OAM_PTR) << 8) | r3(W_ACTION_HELP_WARIO_OAM_PTR + 1)


## A far object's animation step (hcall UpdateObjAnim in its bank, through wTempBank), and with
## `ended` its AnimationEnded from wObjAnimWasReset.
func update_far_obj_anim(obj: int, ended: bool = true) -> void:
	wTempBank = r3(obj + OBJ_OAM_BANK)
	update_obj_anim(obj, wTempBank)
	if ended:
		w3(obj + OBJ_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))


## Wario's animation step (`farcall $5, UpdateObjAnim`).
func update_wario_anim() -> void:
	update_obj_anim(W_ACTION_HELP_WARIO, WARIO_BANK)


# --- common2.asm: the special power-ups' Wario and objects ---

func show_wario_hang_vertical() -> void:
	_wario_frameset(0x6DD0)


func show_wario_hang_horizontal() -> void:
	_wario_frameset(0x6D7C)


func show_wario_hang_owl_right() -> void:
	_wario_frameset(0x6D91)


func show_wario_owl_move_hang() -> void:
	_wario_frameset(0x6DA6)


func show_wario_owl_move_hang_right() -> void:
	_wario_frameset(0x6DBB)


func show_wario_hang_drop() -> void:
	_wario_frameset(0x6DFE)


## ActionHelp2_ShowWarioIdle: as ActionHelp_ShowWarioIdle, its OAM bank $05.
func show_wario_idle_2() -> void:
	_show_wario(WARIO_IDLE_GFX, 0x425F, 0x4000)
	w3(W_ACTION_HELP_WARIO_OAM_BANK, WARIO_BANK)


## ActionHelp2_ShowWarioWalk: as ActionHelp_ShowWarioWalk (its OAM bank kept).
func show_wario_walk_2() -> void:
	_show_wario(WARIO_WALK_GFX, 0x49C5, 0x426C)


## ActionHelp2_ShowWarioJump: as ActionHelp_ShowWarioJump, its OAM bank $05, without a sound.
func show_wario_jump_2() -> void:
	_show_wario(WARIO_AIRBORNE_GFX, 0x5F97, 0x5955)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_ACTION_HELP_WARIO_OAM_BANK, WARIO_BANK)


func show_wario_hang_stopped() -> void:
	_show_wario(WARIO_HANG_GFX, 0x6EC4, 0x6E05)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_ACTION_HELP_WARIO_OAM_BANK, 0x7F)


func show_wario_hang_rail_right() -> void:
	_show_wario(WARIO_HANG_GFX, 0x6EB4, 0x6E05)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_ACTION_HELP_WARIO_OAM_BANK, 0x7F)


## ActionHelp_ShowWarioBatTransform (its OAM bank kept).
func show_wario_bat_transform() -> void:
	_show_wario(WARIO_BAT_GFX, 0x5479, 0x5031)


func show_wario_bat_right() -> void:
	_wario_frameset(0x546C)
	w3(W_SFX_TIMER, 0)


func show_wario_bat_left() -> void:
	_wario_frameset(0x542C)
	w3(W_SFX_TIMER, 0)


func show_wario_vampire_transform() -> void:
	_wario_frameset(0x5439)


func show_rail_rotate_right() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6FCB)


func show_rail_rotate_left() -> void:
	_restart_frameset(W_MENU_OBJ_4, 0x6FC2)


## ActionHelp_ShowOwlFlyUp: the owl (Frameset_d7b4, OAM_d763 in bank $03) above Wario.
func show_owl_fly_up() -> void:
	set_up_far_obj(W_MENU_OBJ_4, byte(r3(W_ACTION_HELP_WARIO + OBJ_Y) - 0x20),
			byte(r3(W_ACTION_HELP_WARIO + OBJ_X) - 0x08), 0x57B4, 0x5763, 0x03, true)


# --- a demo's end ---

## The end of a demo (lead_overalls.asm's Func_1f8988; each demo has its copy): after a level's
## clear, the power-up's flag cleared and the map (Func_4628); on the title screen the title again
## (InitWithoutDemoPowerUpReset); otherwise the demo starts over from its state 1 (`restart`, after no
## inputs).
func end_demo(restart: Callable) -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) != 0:
		sim.wPowerUpLevel &= POWER_UP_MASK
		return_to_map()
		return
	if (sim.wPowerUpLevel & ACTION_HELP_TITLE_SCREEN) != 0:
		sim.request_init(LevelSim.INIT_KEEP_DEMO_POWER_UP)
		return
	clear_d_pad_input()
	clear_buttons_input()
	w3(W_ACTION_HELP_STATE, 1)
	restart.call()


## Func_4628: the animated tiles stopped, w3d50d cleared, wDayNight's bit 7, and the map
## (StartOverworldState).
func return_to_map() -> void:
	sim.wAnimatedTilesFrameDuration = 0
	sim.wAnimatedTilesGfx = 0
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	w3(W3D50D, 0)
	sim.wDayNight |= 0x80
	sim.wState = ST_OVERWORLD
	sim.wSubState = 0
