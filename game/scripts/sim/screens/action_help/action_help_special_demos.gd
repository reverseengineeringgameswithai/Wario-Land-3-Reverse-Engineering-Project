class_name ActionHelpSpecialDemos
extends ActionHelpDemos4
## Action Help's demos of the transformations it shows (src/engine/action_help/power_ups/: owl.asm,
## rail.asm, vampire.asm), shown for Owl Wario, the rail, and Vampire Wario. Wario's framesets and
## OAM tables are bank $7f's; unlike the main power-ups' demos, a special one's end starts it over
## even after a level's clear.


# --- OwlActionHelp (owl.asm) ---

## Its state, then (not blacked out) the owl's animation (object 4, with whether it ended) and
## Wario's, both held while an input flashes; Wario's sprite and the owl's.
func owl_action_help() -> void:
	_owl_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		_update_wario_anim_from_bank()
	load_action_help_wario_sprite_from_bank()
	load_action_help_sprite_far(W_MENU_OBJ_4)


func _owl_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var owl_y: int = W_MENU_OBJ_4 + OBJ_Y
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()  # ActionHelp2_Init
		1:  # Func_1e4095
			if timer_done():
				_owl_start()
		2:  # Func_1e4104: flown in from the right
			if not _owl_flap_moves():
				return
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x60:
				show_d_up_input()
				show_wario_hang_vertical()
				next_state()
		3:  # Func_1e4134: up
			if not _owl_flap_moves():
				return
			w3(wario_y, r3(wario_y) - 1)
			if r3(wario_y) == 0x34:
				clear_d_pad_input()
			elif r3(wario_y) < 0x20:
				next_state()
		4:  # Func_1e4165: back down
			if not _owl_flap_moves():
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x38:
				show_d_left_input()
				show_wario_hang_horizontal()
				next_state()
		5:  # Func_1e4195: left
			if not _owl_flap_moves():
				return
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) == 0x5C:
				clear_d_pad_input()
			elif r3(wario_x) < 0x10:
				show_wario_hang_owl_right()
				next_state()
		6:  # Func_1e41c9: back right
			if not _owl_flap_moves():
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x60:
				w3(W_SFX_TIMER, 0)
				show_d_left_input()
				show_wario_owl_move_hang()
				next_state()
		7:  # Func_1e41fd: left, faster
			play_sfx_rept(16)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x20:
				show_d_right_input()
				show_wario_owl_move_hang_right()
				next_state()
		8:  # Func_1e4227: right, faster
			play_sfx_rept(16)
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x80:
				clear_d_pad_input()
				show_wario_hang_drop()
				show_owl_fly_up()
				next_state()
		9:
			flash_b_input()  # ActionHelp2_FlashBInput
		10:  # Func_1e4254: Wario drops, the owl flies off
			w3(owl_y, r3(owl_y) - 2)
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x40:
				clear_buttons_input()
				show_wario_idle_2()
				w0(W_TIMER, 0x30)
				next_state()
		11:  # Func_1e4271
			w3(owl_y, r3(owl_y) - 2)
			if timer_done():
				show_d_right_input()
				show_wario_walk_2()
				next_state()
		12:  # Func_1e4286: he walks off
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0xB0:
				_end_special_demo(_owl_start)  # Func_1e407e
		_:
			_note("OwlActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## The flap's sound (play_sfx_rept 32) and whether Wario moves: on even loops only.
func _owl_flap_moves() -> bool:
	play_sfx_rept(32)
	return (r3(W_ACTION_HELP_COUNTER) & 1) == 0


## Func_1e409a: Wario hangs from the owl off to the right, the block debris (object 4) hidden, the
## screen shown.
func _owl_start() -> void:
	_set_up_special_wario(WARIO_HANG_GFX, 0x38, 0xC0, 0x6D7C, 0x5DB4)
	w3(W_SFX_TIMER, 0)
	hide_block_debris(W_MENU_OBJ_4)
	load_pals_without_water()
	next_state()


# --- RailActionHelp (rail.asm) ---

## Its state, then (not blacked out) the rail's animation (object 4) and Wario's (with whether it
## ended), both held while an input flashes; Wario's sprite and the rail's.
func rail_action_help() -> void:
	_rail_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4, false)
		_update_wario_anim_from_bank()
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_wario_sprite_from_bank()
	load_action_help_sprite_far(W_MENU_OBJ_4)


func _rail_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var wario_var: int = W_ACTION_HELP_WARIO_VAR
	var rail_x: int = W_MENU_OBJ_4 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()  # ActionHelp2_Init
		1:  # Func_1e4324
			if timer_done():
				_rail_start()
		2, 10:  # Func_1e43a0, Func_1e4490: riding left
			play_sfx_rept(30)
			w3(wario_x, r3(wario_x) - 1)
			w3(rail_x, r3(rail_x) - 1)
			if r3(rail_x) < 0x1C:
				show_rail_rotate_right()
				next_state()
		3:  # Func_1e43cb: riding right; then he lets go
			play_sfx_rept(30)
			w3(wario_x, r3(wario_x) + 1)
			w3(rail_x, r3(rail_x) + 1)
			if r3(rail_x) >= 0x4C:
				show_wario_jump_2()  # after stop_sfx
				w3(wario_var, 0x18)
				next_state()
		4:
			flash_b_input()  # ActionHelp2_FlashBInput
		5:  # Func_1e4403: down to the ground, the rail going on
			w3(rail_x, r3(rail_x) + 1)
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				w3(wario_var, 0)
				clear_buttons_input()
				show_wario_idle_2()
				next_state()
		6, 14:  # Func_1e4432, Func_1e452a: the rail comes back
			w3(rail_x, r3(rail_x) + 1)
			if r3(rail_x) >= 0x7C:
				show_rail_rotate_left()
				next_state()
		7, 15:  # Func_1e4442, Func_1e453a
			w3(rail_x, r3(rail_x) - 1)
			if r3(rail_x) < 0x4C:
				show_a_input()
				show_wario_jump_2()
				next_state()
		8:  # Func_1e4455: up onto the rail
			if wario_jump_step() < 0x38:
				w3(wario_y, 0x38)
				w3(wario_var, 0)
				w3(W_SFX_TIMER, 0)
				clear_buttons_input()
				show_wario_hang_stopped()
				next_state()
		9:  # Func_1e4483
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_hang_rail_right()
				next_state()
		11:  # Func_1e44bb: riding right; then he lets go
			play_sfx_rept(30)
			w3(wario_x, r3(wario_x) + 1)
			w3(rail_x, r3(rail_x) + 1)
			if r3(rail_x) >= 0x4C:
				show_wario_jump_2()  # after stop_sfx
				next_state()
		12:
			flash_a_input()  # ActionHelp2_FlashAInput
		13:  # Func_1e44ee: a jump from the rail, its fall held at $27
			w3(rail_x, r3(rail_x) + 1)
			if r3(wario_var) != 0x27:
				w3(wario_var, r3(wario_var) + 1)
			w3(wario_y, r3(wario_y) + _jump_vel(r3(wario_var)))
			if r3(wario_var) < 0x18 or r3(wario_y) < 0x40:
				return
			w3(wario_y, 0x40)
			w3(wario_var, 0)
			clear_buttons_input()
			show_wario_idle_2()
			next_state()
		16:  # Func_1e454d: up onto the rail
			if wario_jump_step() < 0x38:
				w3(wario_y, 0x38)
				w3(wario_var, 0)
				clear_buttons_input()
				show_wario_hang_stopped()
				next_state()
		17:  # Func_1e4578
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				_end_special_demo(_rail_start)  # Func_1e430d
		_:
			_note("RailActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1e4329: Wario hangs from the rail (object 4), the screen shown.
func _rail_start() -> void:
	_set_up_special_wario(WARIO_HANG_GFX, 0x38, 0x50, 0x6EB4, 0x6E05)
	w3(W_SFX_TIMER, 0)
	set_up_far_obj(W_MENU_OBJ_4, 0x20, 0x4C, 0x6FC2, 0x6F86, ACTION_HELP_2_BANK, true)
	load_pals_without_water()
	next_state()


# --- VampireActionHelp (vampire.asm) ---

## Its state, then (not blacked out) Wario's animation (`farcall $7f`, with whether it ended), held
## while an input flashes, and his sprite.
func vampire_action_help() -> void:
	_vampire_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_obj_anim(W_ACTION_HELP_WARIO, 0x7F)
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_wario_sprite_from_bank()


func _vampire_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var wario_var: int = W_ACTION_HELP_WARIO_VAR
	var odd: bool = (r3(W_ACTION_HELP_COUNTER) & 1) != 0
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()  # ActionHelp2_Init
		1:  # Func_1e45ee
			if timer_done():
				_vampire_start()
		2:  # Func_1e464b: walks in, then turns into a bat
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x80:
				clear_d_pad_input()
				show_wario_bat_transform()
				next_state()
		3:
			flash_b_input()  # ActionHelp2_FlashBInput
		4:  # Func_1e465e: with wTimer 0 (as the flash left it) a sound and wTimer 1; once the
			# transform ends, the bat flies right
			if r0(W_TIMER) == 0:
				w0(W_TIMER, 1)
			elif r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_bat_right()
				w0(W_TIMER, 0x30)
				next_state()
		5:  # Func_1e4684
			play_sfx_rept(32)
			if timer_done():
				show_d_left_input()
				show_wario_bat_left()
				next_state()
		6:
			flash_a_input()  # ActionHelp2_FlashAInput
		7:  # ApplyWaterCurrentMovementb: a flap up
			_vampire_flap(odd, 0x30, 0x20)
		8, 10, 12:  # Func_1e46e8, Func_1e4759, Func_1e47ca: the flap's fall, by the var before it goes on
			if odd:
				w3(wario_x, r3(wario_x) - 1)
			w3(wario_y, r3(wario_y) + _jump_vel(r3(wario_var)))
			w3(wario_var, r3(wario_var) + 1)
			if r3(wario_var) >= 0x27:
				w3(wario_var, 0)
				w3(W_SFX_TIMER, 0)
				show_a_input()
				next_state()
		9:  # Func_1e471c
			_vampire_flap(odd, 0x2C, 0x1C)
		11:  # Func_1e478d
			_vampire_flap(odd, 0x28, 0x18)
		13:  # Func_1e47fe: the last flap, until he is back at $30
			play_sfx_rept(16)
			if r3(wario_y) >= 0x20:
				w3(wario_y, r3(wario_y) - 1)
			w3(wario_y, r3(wario_y) - 1)
			if not odd:
				return
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) == 0x30:
				clear_buttons_input()
				clear_d_pad_input()
				w3(wario_var, 0x18)
				next_state()
		14:  # Func_1e483d: down, the fall held at $27
			if r3(wario_var) != 0x27:
				w3(wario_var, r3(wario_var) + 1)
			w3(wario_y, r3(wario_y) + _jump_vel(r3(wario_var)))
			if r3(wario_y) >= 0x40:
				w3(wario_y, 0x40)
				w3(wario_var, 0)
				show_wario_bat_right()
				w0(W_TIMER, 0x30)
				next_state()
		15:  # Func_1e4871: back to Vampire Wario
			play_sfx_rept(32)
			if timer_done():
				show_b_input()
				show_wario_vampire_transform()
				next_state()
		16:  # Func_1e4898
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				_end_special_demo(_vampire_start)  # Func_1e45d7
		_:
			_note("VampireActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1e45f3: Vampire Wario walks in from the left, the screen shown.
func _vampire_start() -> void:
	show_d_right_input()
	_set_up_special_wario(WARIO_VAMPIRE_GFX, 0x40, 0x30, 0x582E, 0x5498)
	load_pals_without_water()
	next_state()


## ApplyWaterCurrentMovementb, Func_1e471c, Func_1e478d: a flap up, drifting left on odd loops, by 2
## while at `fast_from` or below it on screen, until above `until`; then the fall.
func _vampire_flap(odd: bool, fast_from: int, until: int) -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	play_sfx_rept(16)
	if odd:
		w3(W_ACTION_HELP_WARIO + OBJ_X, r3(W_ACTION_HELP_WARIO + OBJ_X) - 1)
	if r3(wario_y) >= fast_from:
		w3(wario_y, r3(wario_y) - 1)
	w3(wario_y, r3(wario_y) - 1)
	if r3(wario_y) < until:
		clear_buttons_input()
		w3(W_ACTION_HELP_WARIO_VAR, 0x18)
		next_state()


# --- the special demos' shared steps ---

## Wario at (y, x) with `gfx`'s tiles, `frameset`, his var cleared, and `oam` in bank $7f.
func _set_up_special_wario(gfx: int, y: int, x: int, frameset: int, oam: int) -> void:
	_dma_wario_gfx(gfx)
	set_up_obj(W_ACTION_HELP_WARIO, y, x, frameset)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	_wario_oam(oam, 0x7F)


## Wario's animation step in wActionHelpWarioOAMBank (hcall UpdateObjAnim, through wTempBank); his
## AnimationEnded is left to the caller.
func _update_wario_anim_from_bank() -> void:
	wTempBank = r3(W_ACTION_HELP_WARIO_OAM_BANK)
	update_obj_anim(W_ACTION_HELP_WARIO, wTempBank)


## The end of a special demo (owl.asm's Func_1e407e; rail.asm and vampire.asm have their copies): on
## the title screen the title again (InitWithoutDemoPowerUpReset); otherwise, even after a level's clear (the flag is
## not checked), the demo starts over from its state 1 (`restart`, after no inputs).
func _end_special_demo(restart: Callable) -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_TITLE_SCREEN) != 0:
		sim.request_init(LevelSim.INIT_KEEP_DEMO_POWER_UP)
		return
	clear_d_pad_input()
	clear_buttons_input()
	w3(W_ACTION_HELP_STATE, 1)
	restart.call()
