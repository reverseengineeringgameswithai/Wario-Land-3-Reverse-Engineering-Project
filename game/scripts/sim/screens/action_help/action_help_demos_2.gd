class_name ActionHelpDemos2
extends ActionHelpDemos
## Action Help's demos of the grab glove and the garlic (src/engine/action_help/power_ups/:
## grab_gloves.asm, garlic.asm).


# --- GrabGloveActionHelp (grab_gloves.asm) ---

## Its state, then (not blacked out) the block debris (object 5), the Para-Goom's animation
## (object 4) and Wario's, both held while an input flashes, their sprites, and the block, later the
## pillar (object 6).
func grab_glove_action_help() -> void:
	_grab_glove_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	update_far_obj_anim(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_5)
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()
	update_far_obj_anim(W_MENU_OBJ_6, false)
	load_action_help_sprite_far(W_MENU_OBJ_6)


func _grab_glove_state() -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	var obj4_x: int = W_MENU_OBJ_4 + OBJ_X
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_ended: bool = r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f959c
			if timer_done():
				_grab_glove_start()
		2:  # Func_1f95de: the Para-Goom walks in
			if move_left_1_5(W_MENU_OBJ_4) < 0x70:
				show_a_input()
				show_wario_jump()
				next_state()
		3:  # Func_1f95f9: Wario jumps onto it
			wario_jump_step()
			move_left_1_5(W_MENU_OBJ_4)
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or r3(wario_y) < 0x36:
				return
			clear_d_pad_input()
			clear_buttons_input()
			w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
			show_para_goom_stun()
			next_state()
		4:  # Func_1f963f: both fall, the Para-Goom pushed back
			w3(obj4_x, r3(obj4_x) + 1)
			if (r3(W_ACTION_HELP_COUNTER) & 1) != 0:
				w3(obj4_x, r3(obj4_x) + 1)
			w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) + 1)
			var vel: int = _jump_vel(r3(W_ACTION_HELP_WARIO_VAR))
			var y: int = byte(r3(obj4_y) + vel)
			if y < 0x40:
				w3(obj4_y, y)
			w3(wario_y, r3(wario_y) + vel)
			if r3(wario_y) < 0x40:
				return
			w3(wario_y, 0x40)
			w3(obj4_y, 0x40)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_idle()
			w0(W_TIMER, 0x20)
			next_state()
		5, 12, 19:  # Func_1f9685, Func_1f97a2, Func_1f98db
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		6, 13, 20, 27:  # Func_1f9695, Func_1f97b2, Func_1f98eb, Func_1f9a53: Wario grabs the Para-Goom
			if move_left_1_5(W_MENU_OBJ_4) < 0x48:
				_grab_glove_hold(0x05, 0x10)
				show_wario_grab()
				clear_d_pad_input()
				next_state()
		7, 14, 21, 28:  # Func_1f96bf, Func_1f97dc, Func_1f9915, Func_1f9a7d: and lifts it
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) == 0x03:
				_grab_glove_hold(0x0C, 0x10)
			elif r0(W_TIMER) == 0x06:
				_grab_glove_hold(0x1C, 0x06)
			elif wario_ended:
				w0(W_TIMER, 0x30)
				show_wario_begin_grab()
				next_state()
		8:  # Func_1f96fb
			if timer_done():
				show_wario_begin_throw()
				next_state()
		9:
			flash_b_input()
		10, 24:  # Func_1f9708, Func_1f9981: the throw
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) >= 0x30:
				w0(W_TIMER, 0)
				show_wario_throw()
				show_para_goom_thrown()
				clear_buttons_input()
				next_state()
		11:  # Func_1f9720: the Para-Goom thrown, it bounces
			if wario_ended:
				show_wario_idle()
			w0(W_TIMER, r0(W_TIMER) + 1)
			var timer: int = r0(W_TIMER)
			if timer < 0x10:
				w3(obj4_x, r3(obj4_x) + 2)
				_grab_glove_throw_drop(timer)
			else:
				w3(obj4_x, r3(obj4_x) + 1)
				_grab_glove_bounce(timer)
		15:  # Func_1f981a
			if timer_done():
				next_state()
		16:
			flash_d_up_input()
		17:  # Func_1f9824: the throw up
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) == 0x01:
				show_wario_begin_throw()
				show_b_input()
			elif r0(W_TIMER) >= 0x30:
				w0(W_TIMER, 0)
				show_wario_throw()
				show_para_goom_thrown()
				clear_buttons_input()
				next_state()
		18:  # Func_1f9847: the Para-Goom thrown up
			if wario_ended:
				show_wario_idle()
			w0(W_TIMER, r0(W_TIMER) + 1)
			var timer: int = r0(W_TIMER)
			if timer < 0x30:
				w3(obj4_x, r3(obj4_x) + 1)
				_grab_glove_throw_up(timer)
			else:
				_grab_glove_throw_up_bounce(timer)
		22, 29:  # Func_1f9953, Func_1f9abb: Wario carries it
			if timer_done():
				show_wario_grab_walk()
				show_d_right_input()
				next_state()
		23:  # Func_1f9963
			if move_left_1_5(W_MENU_OBJ_6) < 0x5C:
				show_wario_begin_throw()
				clear_d_pad_input()
				show_b_input()
				next_state()
		25:  # Func_1f9999: the Para-Goom thrown into the block, which breaks
			if wario_ended:
				show_wario_idle()
			w0(W_TIMER, r0(W_TIMER) + 1)
			var timer: int = r0(W_TIMER)
			if timer < 0x10:
				var pillar_x: int = r3(W_MENU_OBJ_6 + OBJ_X)
				w3(obj4_x, r3(obj4_x) + 2)
				if r3(obj4_x) >= pillar_x:
					_grab_glove_break_block()
				_grab_glove_throw_drop(r0(W_TIMER))
			else:
				w3(obj4_x, r3(obj4_x) + 1)
				_grab_glove_bounce(timer)
		26:  # Func_1f9a3a
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		30:  # Func_1f9acb
			if move_left_1_5(W_MENU_OBJ_6) < 0x80:
				show_wario_begin_throw()
				clear_d_pad_input()
				show_b_input()
				w0(W_TIMER, 0x50)
				next_state()
		31:  # Func_1f9aee: the charged throw
			if timer_done():
				show_wario_charge_throw()
				next_state()
		32:  # Func_1f9afb
			play_sfx_rept(30)
			if wario_ended:
				show_wario_fully_charged_grab()
				w3(obj4_x, r3(obj4_x) - 8)
				w0(W_TIMER, 0x30)
				next_state()
		33:  # Func_1f9b2c
			play_sfx_rept(30)
			if timer_done():
				show_wario_fully_charged_throw()
				show_para_goom_thrown()
				clear_buttons_input()
				next_state()
		34:  # Func_1f9b56: the Para-Goom thrown, it vanishes short of the pillar
			if wario_ended:
				show_wario_idle()
			var limit: int = byte(r3(W_MENU_OBJ_6 + OBJ_X) - 0x10)
			w3(obj4_x, r3(obj4_x) + 4)
			if r3(obj4_x) >= limit:
				show_wario_idle()
				show_enemy_vanish()
				next_state()
		35:  # Func_1f9b7a
			if r3(W_MENU_OBJ_4 + OBJ_ANIMATION_ENDED) != 0:
				w3(obj4_x, 0xE8)
				show_wario_walk()
				show_d_right_input()
				next_state()
		36:  # Func_1f9b8f: the pillar goes by
			if move_left_1_5(W_MENU_OBJ_6) >= 0xE8:
				end_demo(_grab_glove_start)  # Func_1f9569
		_:
			_note("GrabGloveActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f95a1: Wario walks in, the Para-Goom comes, the debris hidden, the block (object 6) off
## to the right, the screen shown.
func _grab_glove_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_para_goom_walk()
	hide_block_debris()
	set_up_far_obj(W_MENU_OBJ_6, 0x40, 0xE8, 0x6B6A, 0x697C, ACTION_HELP_2_BANK, false)
	load_pals_without_water()
	next_state()


## The Para-Goom held at Wario's place, `dy` above him and `dx` to his right.
func _grab_glove_hold(dy: int, dx: int) -> void:
	w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_ACTION_HELP_WARIO + OBJ_Y) - dy)
	w3(W_MENU_OBJ_4 + OBJ_X, r3(W_ACTION_HELP_WARIO + OBJ_X) + dx)


## A throw's first $10 loops (Func_1f9720's, Func_1f9999's): from the third loop down by 1, from the
## sixth by 2, from the tenth by 3 until the ground ($40), where wTimer goes on at $10.
func _grab_glove_throw_drop(timer: int) -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	if timer < 0x03:
		return
	if timer < 0x06:
		w3(obj4_y, r3(obj4_y) + 1)
	elif timer < 0x0A:
		w3(obj4_y, r3(obj4_y) + 2)
	else:
		w3(obj4_y, r3(obj4_y) + 3)
		if r3(obj4_y) >= 0x40:
			w3(obj4_y, 0x40)
			w0(W_TIMER, 0x10)


## A throw's bounce (Func_1f9720's, Func_1f9999's): up by 3, 2, 1, wTimer on to $20, down by 1, then
## by 2 until the ground, where Wario stands and the Para-Goom is stunned.
func _grab_glove_bounce(timer: int) -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	if timer < 0x12:
		w3(obj4_y, r3(obj4_y) - 3)
	elif timer < 0x14:
		w3(obj4_y, r3(obj4_y) - 2)
	elif timer < 0x15:
		w3(obj4_y, r3(obj4_y) - 1)
	elif timer < 0x16:
		w0(W_TIMER, 0x20)
	elif timer < 0x27:
		w3(obj4_y, r3(obj4_y) + 1)
	else:
		w3(obj4_y, r3(obj4_y) + 2)
		if r3(obj4_y) < 0x40:
			return
		w3(obj4_y, 0x40)
		show_wario_idle()
		show_para_goom_stun()
		w0(W_TIMER, 0x20)
		next_state()


## Func_1f9847's first $30 loops: up by 4, 3, 2, 1, still, down by 1, 2, 3, then by 4 until the
## ground, where wTimer goes on at $30.
func _grab_glove_throw_up(timer: int) -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	if timer < 0x07:
		w3(obj4_y, r3(obj4_y) - 4)
	elif timer < 0x0D:
		w3(obj4_y, r3(obj4_y) - 3)
	elif timer < 0x0F:
		w3(obj4_y, r3(obj4_y) - 2)
	elif timer < 0x11:
		w3(obj4_y, r3(obj4_y) - 1)
	elif timer < 0x14:
		return
	elif timer < 0x17:
		w3(obj4_y, r3(obj4_y) + 1)
	elif timer < 0x1A:
		w3(obj4_y, r3(obj4_y) + 2)
	elif timer < 0x1D:
		w3(obj4_y, r3(obj4_y) + 3)
	else:
		w3(obj4_y, r3(obj4_y) + 4)
		if r3(obj4_y) >= 0x40:
			w3(obj4_y, 0x40)
			w0(W_TIMER, 0x30)


## Func_1f9847's bounce (in place): up by 3, 2, 1, wTimer on to $40, down by 1, then by 2 until the
## ground, where Wario stands and the Para-Goom is stunned.
func _grab_glove_throw_up_bounce(timer: int) -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	if timer < 0x32:
		w3(obj4_y, r3(obj4_y) - 3)
	elif timer < 0x34:
		w3(obj4_y, r3(obj4_y) - 2)
	elif timer < 0x35:
		w3(obj4_y, r3(obj4_y) - 1)
	elif timer < 0x36:
		w0(W_TIMER, 0x40)
	elif timer < 0x47:
		w3(obj4_y, r3(obj4_y) + 1)
	else:
		w3(obj4_y, r3(obj4_y) + 2)
		if r3(obj4_y) < 0x40:
			return
		w3(obj4_y, 0x40)
		show_wario_idle()
		show_para_goom_stun()
		w0(W_TIMER, 0x30)
		next_state()


## Func_1f9999.Func_1f9a25: the debris at the Para-Goom, then at the block's place, and the
## pillar overhead (object 6).
func _grab_glove_break_block() -> void:
	show_block_debris(0)
	w3(W_MENU_OBJ_5 + OBJ_Y, r3(W_MENU_OBJ_6 + OBJ_Y))
	w3(W_MENU_OBJ_5 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X))
	show_overhead_pillar()


# --- GarlicActionHelp (garlic.asm) ---

## Its state, then (not blacked out) the block debris (objects 5 and 7), the Count Richtertoff's or
## block's animation (object 4), the second block's (object 6), and Wario's, all held while an
## input flashes, and their sprites.
func garlic_action_help() -> void:
	_garlic_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	update_far_obj_anim(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_5)
	update_far_obj_anim(W_MENU_OBJ_7)
	load_action_help_sprite_far(W_MENU_OBJ_7)
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		update_far_obj_anim(W_MENU_OBJ_6, false)
		update_wario_anim()
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_sprite_far(W_MENU_OBJ_6)
	load_action_help_wario_sprite()


func _garlic_state() -> void:
	var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
	var obj4_x: int = W_MENU_OBJ_4 + OBJ_X
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var var_: int = W_ACTION_HELP_WARIO_VAR
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f9d1a
			if timer_done():
				_garlic_start()
		2:  # Func_1f9d7e: two blocks come
			if _garlic_blocks_come():
				show_wario_attack()
				w3(var_, 0x30)
				next_state()
		3:
			flash_b_input()
		4:  # Func_1f9d97: the charge breaks the first block
			play_sfx_rept(6)
			if not _garlic_charge_blocks():
				return
			_garlic_break_block()
			w3(obj4_x, r3(W_MENU_OBJ_6 + OBJ_X))
			set_up_far_obj(W_MENU_OBJ_6, 0x40, 0xF8, 0x6B96, 0x697C, ACTION_HELP_2_BANK, false)
			next_state()
		5:  # Func_1f9e07: and the second
			play_sfx_rept(6)
			w3(var_, r3(var_) - 1)
			if move_left_1_5(W_MENU_OBJ_4) >= 0x50:
				return
			_garlic_break_block()
			set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6B96, 0x697C, ACTION_HELP_2_BANK, false)
			next_state()
		6:  # Func_1f9e62
			play_sfx_rept(6)
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
				hide_block_debris(W_MENU_OBJ_7)
			w3(var_, r3(var_) - 1)
			if r3(var_) == 0:
				clear_buttons_input()
				show_wario_walk()
				show_d_right_input()
				next_state()
		7:  # Func_1f9e9b: two more
			if _garlic_blocks_come():
				show_b_input()
				show_wario_attack()
				w3(var_, 0x30)
				next_state()
		8:  # Func_1f9eb7: the charge breaks a block and bounces off the next
			play_sfx_rept(6)
			if not _garlic_charge_blocks():
				return
			_garlic_break_block()
			w3(obj4_x, r3(W_MENU_OBJ_6 + OBJ_X))
			set_up_far_obj(W_MENU_OBJ_6, 0xA0, 0xF8, 0x6BA2, 0x697C, ACTION_HELP_2_BANK, false)
			clear_d_pad_input()
			clear_buttons_input()
			show_wario_attack()
			w3(var_, 0x0E)
			next_state()
		9, 13:  # Func_1f9f35, Func_1f9ff4: Wario bounces back
			move_left_1_5(W_ACTION_HELP_WARIO)
			if wario_jump_step() >= 0x40:
				w3(var_, 0)
				w3(wario_y, 0x40)
				hide_block_debris()
				hide_block_debris(W_MENU_OBJ_7)
				show_wario_idle()
				w0(W_TIMER, 0x30)
				next_state()
		10, 14, 18, 21, 32:  # Func_1f9f76, Func_1fa035, Func_1fa145, Func_1fa1c5, Func_1fa37c
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		11:  # Func_1f9f86
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x40:
				show_b_input()
				show_wario_attack()
				w3(var_, 0x30)
				next_state()
		12:  # Func_1f9f9e: the last block broken, the Count Richtertoff comes
			play_sfx_rept(6)
			w3(var_, r3(var_) - 1)
			if r3(var_) >= 0x2B:
				return
			if move_left_1_5(W_MENU_OBJ_4) >= 0x50:
				return
			_garlic_break_block()
			show_count_richtertoff_idle()
			clear_d_pad_input()
			clear_buttons_input()
			show_wario_attack()
			w3(var_, 0x0E)
			next_state()
		15:  # Func_1fa045
			if _garlic_walk_back() and move_left_1_5(W_MENU_OBJ_4) < 0x58:
				show_b_input()
				show_wario_attack()
				w3(var_, 0x30)
				next_state()
		16:  # Func_1fa072: the charge stuns him
			play_sfx_rept(6)
			w3(var_, r3(var_) - 1)
			if r3(var_) >= 0x2B:
				return
			if move_left_1_5(W_MENU_OBJ_4) >= 0x50:
				return
			show_count_richtertoff_stun()
			clear_d_pad_input()
			clear_buttons_input()
			show_wario_attack()
			w3(var_, 0x0E)
			next_state()
		17:  # Func_1fa0c2: Wario bounces back, the Count Richtertoff flies off below
			w3(var_, r3(var_) + 1)
			if r3(var_) >= 0x28:
				w3(var_, 0x27)
			var vel: int = _jump_vel(r3(var_))
			if r3(var_) < 0x18:
				w3(wario_y, r3(wario_y) + vel)
				w3(obj4_y, r3(obj4_y) + vel)
				w3(obj4_x, r3(obj4_x) + 2)
				move_left_1_5(W_ACTION_HELP_WARIO)
			elif r3(wario_y) != 0x40:
				w3(wario_y, r3(wario_y) + vel)
				w3(obj4_y, r3(obj4_y) + vel)
				w3(obj4_x, r3(obj4_x) + 2)
				if r3(wario_y) >= 0x40:
					w3(wario_y, 0x40)
					show_wario_idle()
			else:
				w3(obj4_y, r3(obj4_y) + vel)
				w3(obj4_x, r3(obj4_x) + 2)
				if r3(obj4_y) >= 0x80:
					show_slide()
					w3(var_, 0)
					w0(W_TIMER, 0x30)
					next_state()
		19:  # Func_1fa155: the slope comes
			if _garlic_walk_back() and move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		20:  # Func_1fa17d: onto it
			wario_jump_step()
			var x: int = move_left_1_5(W_MENU_OBJ_4)
			if r3(wario_x) < x:
				return
			w3(wario_x, x)
			clear_d_pad_input()
			if r3(wario_y) < 0x20:
				return
			w3(wario_y, 0x20)
			w3(var_, 0)
			show_wario_idle()
			clear_buttons_input()
			w0(W_TIMER, 0x30)
			next_state()
		22:  # Func_1fa1d5: walks down it, then slides
			w3(obj4_x, r3(obj4_x) - 1)
			var x: int = r3(obj4_x)
			if x >= 0x39:
				return
			if x >= 0x30:
				w3(wario_y, r3(wario_y) + 1)
				return
			show_wario_slide()
			next_state()
		23:
			flash_d_down_input()
		24:  # Func_1fa1ee: the slide and roll
			if r3(wario_y) < 0x40:
				w3(wario_y, r3(wario_y) + 1)
			w3(obj4_x, r3(obj4_x) - 1)
			if r3(obj4_x) < 0x18:
				clear_d_pad_input()
				show_wario_roll()
				next_state()
		25:  # Func_1fa20a: the Count Richtertoff comes again
			if r3(wario_y) < 0x40:
				w3(wario_y, r3(wario_y) + 1)
			w3(obj4_x, r3(obj4_x) - 1)
			if r3(obj4_x) == 0xD8:
				show_count_richtertoff_idle()
				next_state()
		26:  # Func_1fa223: the roll stuns him
			if move_left_1_5(W_MENU_OBJ_4) < 0x50:
				show_count_richtertoff_stun()
				w3(var_, 0x0E)
				next_state()
		27:  # Func_1fa248: he flies off below; two blocks come (objects 4 and 6)
			w3(var_, r3(var_) + 1)
			if r3(var_) >= 0x28:
				w3(var_, 0x27)
			w3(obj4_y, r3(obj4_y) + _jump_vel(r3(var_)))
			w3(obj4_x, r3(obj4_x) + 2)
			if r3(obj4_y) < 0x80:
				return
			set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xD8, 0x6B64, 0x697C, ACTION_HELP_2_BANK, false)
			w3(W_MENU_OBJ_6 + OBJ_Y, 0x40)
			w3(var_, 0)
			next_state()
		28:  # Func_1fa298: the roll breaks the first, the second becomes object 4
			w3(W_MENU_OBJ_6 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X) - 1)
			w3(obj4_x, r3(obj4_x) - 1)
			if (r3(W_ACTION_HELP_COUNTER) & 1) != 0:
				w3(W_MENU_OBJ_6 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X) - 1)
				w3(obj4_x, r3(obj4_x) - 1)
			if (r3(obj4_x) & 0xFE) != 0x48:
				return
			w3(obj4_x, 0x48)
			show_block_debris(0)
			for offset: int in 0x0B:  # CopyHLToDE
				w3(W_MENU_OBJ_4 + offset, r3(W_MENU_OBJ_6 + offset))
			hide_block_debris(W_MENU_OBJ_6)  # its 12th byte, object 7's y, cleared (6 has no AnimationEnded)
			next_state()
		29:  # Func_1fa2d4: and breaks it at $58 and $48; then Frameset_1e6b85 comes
			var x: int = move_left_1_5(W_MENU_OBJ_4) & 0xFE
			if x == 0x58:
				w3(obj4_x, 0x58)
				show_block_debris(0)
				show_single_solid_block()
			elif x == 0x48:
				show_block_debris(0)
				set_up_obj(W_MENU_OBJ_4, 0x50, 0xE8, 0x6B85)
				next_state()
		30:  # Func_1fa315: the roll bumps into it
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
			if move_left_1_5(W_MENU_OBJ_4) < 0x50:
				show_wario_bump()
				w3(var_, 0x0E)
				next_state()
		31:  # Func_1fa33b: Wario bounces back
			wario_jump_step()
			move_left_1_5(W_ACTION_HELP_WARIO)
			if r3(var_) < 0x18 or r3(wario_y) < 0x40:
				return
			w3(wario_y, 0x40)
			show_wario_idle()
			w3(var_, 0)
			w0(W_TIMER, 0x30)
			next_state()
		33:  # Func_1fa38c
			if r3(wario_x) != 0x40:
				w3(wario_x, r3(wario_x) + 1)
			w3(obj4_x, r3(obj4_x) - 1)
			if byte(r3(obj4_x) - r3(wario_x)) < 0x1C:
				show_a_input()
				show_wario_jump()
				next_state()
		34:  # Func_1fa3ab: over the wall
			if r3(wario_x) != 0x40:
				w3(wario_x, r3(wario_x) + 1)
			if wario_jump_step() < 0x40:
				w3(obj4_x, r3(obj4_x) - 1)
				return
			w3(var_, 0)
			w3(wario_y, 0x40)
			show_wario_walk()
			clear_buttons_input()
			next_state()
		35:  # Func_1fa3e4: the wall goes by
			w3(obj4_x, r3(obj4_x) - 1)
			if r3(obj4_x) >= 0xE8:
				end_demo(_garlic_start)  # Func_1f9ce7
		_:
			_note("GarlicActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f9d1f: Wario walks in, two blocks come (objects 4 and 6), the debris hidden (objects 5 and
## 7), the screen shown.
func _garlic_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	set_up_far_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6B9C, 0x697C, ACTION_HELP_2_BANK, true)
	hide_block_debris()
	set_up_far_obj(W_MENU_OBJ_6, 0x40, 0xF8, 0x6B9C, 0x697C, ACTION_HELP_2_BANK, false)
	hide_block_debris(W_MENU_OBJ_7)
	load_pals_without_water()
	next_state()


## Func_1f9d7e's and Func_1f9e9b's blocks a pixel a loop; whether the first (object 4) is below $60.
func _garlic_blocks_come() -> bool:
	w3(W_MENU_OBJ_6 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X) - 1)
	w3(W_MENU_OBJ_4 + OBJ_X, r3(W_MENU_OBJ_4 + OBJ_X) - 1)
	return r3(W_MENU_OBJ_4 + OBJ_X) < 0x60


## Func_1f9d97's and Func_1f9eb7's charge: wActionHelpWarioVar counts down, from below $2b both blocks
## come at 1.5 pixels a loop; whether the first (object 4) has reached $50.
func _garlic_charge_blocks() -> bool:
	var var_: int = W_ACTION_HELP_WARIO_VAR
	w3(var_, r3(var_) - 1)
	if r3(var_) >= 0x2B:
		return false
	w3(W_MENU_OBJ_6 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X) - 1)
	w3(W_MENU_OBJ_4 + OBJ_X, r3(W_MENU_OBJ_4 + OBJ_X) - 1)
	if (r3(W_ACTION_HELP_COUNTER) & 1) != 0:
		w3(W_MENU_OBJ_6 + OBJ_X, r3(W_MENU_OBJ_6 + OBJ_X) - 1)
		w3(W_MENU_OBJ_4 + OBJ_X, r3(W_MENU_OBJ_4 + OBJ_X) - 1)
	return r3(W_MENU_OBJ_4 + OBJ_X) < 0x50


## A block broken: debris at object 4 (object 5) and $10 above it (object 7).
func _garlic_break_block() -> void:
	show_block_debris(0)
	show_block_debris(0x10, 0, W_MENU_OBJ_7)


## Func_1fa045's and Func_1fa155's start: Wario walks back to x $40; whether he is there.
func _garlic_walk_back() -> bool:
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	if r3(wario_x) == 0x40:
		return true
	w3(wario_x, r3(wario_x) + 1)
	return r3(wario_x) >= 0x40
