class_name ActionHelpDemos4
extends ActionHelpDemos3
## Action Help's demo of the super grab gloves (src/engine/action_help/power_ups/:
## super_grab_gloves.asm).


# --- SuperGrabGloveActionHelp (super_grab_gloves.asm) ---

## Its state, then (not blacked out) Count Richtertoff's animation (object 4) and Wario's, each with
## whether it ended, both held while an input flashes; their sprites, and the pillar's animation and
## sprite (object 6).
func super_grab_glove_action_help() -> void:
	_super_grab_glove_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()
	update_far_obj_anim(W_MENU_OBJ_6, false)
	load_action_help_sprite_far(W_MENU_OBJ_6)


func _super_grab_glove_state() -> void:
	var enemy_x: int = W_MENU_OBJ_4 + OBJ_X
	var enemy_y: int = W_MENU_OBJ_4 + OBJ_Y
	var pillar_x: int = W_MENU_OBJ_6 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1fb1ac
			if timer_done():
				_super_grab_glove_start()
		2, 8, 15:  # Func_1fb1d4, Func_1fb302, Func_1fb44e: Count Richtertoff walks up and is grabbed
			w3(enemy_x, r3(enemy_x) - 1)
			if r3(enemy_x) < 0x48:
				_hold_count_richtertoff(0x05, 0x10)
				show_wario_slow_grab()
				clear_d_pad_input()
				next_state()
		3, 9, 16:  # Func_1fb1f6, Func_1fb324, Func_1fb470: lifted overhead
			w0(W_TIMER, r0(W_TIMER) + 1)
			match r0(W_TIMER):
				0x07:
					_hold_count_richtertoff(0x04, 0x10)
				0x0D:
					_hold_count_richtertoff(0x14, 0x10)
				0x0F:
					_hold_count_richtertoff(0x1C, 0x06)
				_:
					if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
						w0(W_TIMER, 0x30)
						show_wario_begin_grab()
						next_state()
		4:  # Func_1fb248
			if timer_done():
				show_wario_begin_throw()
				show_b_input()
				w0(W_TIMER, 0x20)
				next_state()
		5, 12:  # Func_1fb25d, Func_1fb397: thrown
			if timer_done():
				show_wario_throw()
				show_count_richtertoff_thrown()
				clear_buttons_input()
				next_state()
		6:  # Func_1fb270: a short throw's arc, and he lands stunned
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_idle()
			w0(W_TIMER, r0(W_TIMER) + 1)
			var timer: int = r0(W_TIMER)
			if timer < 0x10:
				w3(enemy_x, r3(enemy_x) + 2)
				if timer < 0x03:
					return
				if timer < 0x06:
					_move_count_richtertoff_y(1)
				elif timer < 0x0A:
					_move_count_richtertoff_y(2)
				elif _move_count_richtertoff_y(3) >= 0x40:
					w3(enemy_y, 0x40)
					w0(W_TIMER, 0x10)
				return
			w3(enemy_x, r3(enemy_x) + 1)  # .asm_1fb2ad: the bounce
			if timer < 0x12:
				_move_count_richtertoff_y(-3)
			elif timer < 0x14:
				_move_count_richtertoff_y(-2)
			elif timer < 0x15:
				_move_count_richtertoff_y(-1)
			elif timer < 0x16:
				w0(W_TIMER, 0x20)
			elif timer < 0x27:
				_move_count_richtertoff_y(1)
			elif _move_count_richtertoff_y(2) >= 0x40:
				w3(enemy_y, 0x40)
				show_wario_idle()
				show_count_richtertoff_stun()
				w0(W_TIMER, 0x20)
				next_state()
		7, 14:  # Func_1fb2f2, Func_1fb43e
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		10:  # Func_1fb376
			if timer_done():
				w0(W_TIMER, 0x20)
				show_d_up_input()
				next_state()
		11:  # Func_1fb385
			if timer_done():
				w0(W_TIMER, 0x30)
				show_wario_begin_throw()
				show_b_input()
				next_state()
		13:  # Func_1fb3aa: thrown up, a high arc, and he lands stunned
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_idle()
			w0(W_TIMER, r0(W_TIMER) + 1)
			var timer: int = r0(W_TIMER)
			if timer < 0x30:
				w3(enemy_x, r3(enemy_x) + 1)
				if timer < 0x07:
					_move_count_richtertoff_y(-4)
				elif timer < 0x0D:
					_move_count_richtertoff_y(-3)
				elif timer < 0x0F:
					_move_count_richtertoff_y(-2)
				elif timer < 0x11:
					_move_count_richtertoff_y(-1)
				elif timer < 0x14:
					return
				elif timer < 0x17:
					_move_count_richtertoff_y(1)
				elif timer < 0x1A:
					_move_count_richtertoff_y(2)
				elif timer < 0x1D:
					_move_count_richtertoff_y(3)
				elif _move_count_richtertoff_y(4) >= 0x40:
					w3(enemy_y, 0x40)
					w0(W_TIMER, 0x30)
				return
			if timer < 0x32:  # .asm_1fb401: the bounce
				_move_count_richtertoff_y(-3)
			elif timer < 0x34:
				_move_count_richtertoff_y(-2)
			elif timer < 0x35:
				_move_count_richtertoff_y(-1)
			elif timer < 0x36:
				w0(W_TIMER, 0x40)
			elif timer < 0x47:
				_move_count_richtertoff_y(1)
			elif _move_count_richtertoff_y(2) >= 0x40:
				w3(enemy_y, 0x40)
				show_wario_idle()
				show_count_richtertoff_stun()
				w0(W_TIMER, 0x30)
				next_state()
		17:  # Func_1fb4c2: carried
			if timer_done():
				show_wario_grab_walk()
				show_d_right_input()
				next_state()
		18:  # Func_1fb4d2: the pillar comes in
			w3(pillar_x, r3(pillar_x) - 1)
			if r3(pillar_x) < 0x80:
				show_wario_begin_throw()
				clear_d_pad_input()
				show_b_input()
				w0(W_TIMER, 0x50)
				next_state()
		19:  # Func_1fb4ed
			if timer_done():
				show_wario_charge_throw()
				next_state()
		20:  # Func_1fb4fa: charged
			play_sfx_rept(30)
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_fully_charged_grab()
				w3(enemy_x, r3(enemy_x) - 8)
				w0(W_TIMER, 0x30)
				next_state()
		21:  # Func_1fb52b
			play_sfx_rept(30)
			if timer_done():
				show_wario_fully_charged_throw()
				show_count_richtertoff_thrown()
				clear_buttons_input()
				next_state()
		22:  # Func_1fb555: thrown into the pillar, he vanishes
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_wario_idle()
			var pillar: int = byte(r3(pillar_x) - 0x10)
			w3(enemy_x, r3(enemy_x) + 4)
			if r3(enemy_x) >= pillar:
				show_wario_idle()
				show_enemy_vanish()
				next_state()
		23:  # Func_1fb579
			if r3(W_MENU_OBJ_4 + OBJ_ANIMATION_ENDED) != 0:
				w3(enemy_x, 0xE8)
				show_wario_walk()
				show_d_right_input()
				next_state()
		24:  # Func_1fb58e: the pillar goes off to the left
			if move_left_1_5(W_MENU_OBJ_6) >= 0xE8:
				end_demo(_super_grab_glove_start)  # Func_1fb179
		_:
			_note("SuperGrabGloveActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1fb1b1: Wario walks in, Count Richtertoff stunned before him, the pillar off to the right,
## the screen shown.
func _super_grab_glove_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_count_richtertoff_idle()
	show_count_richtertoff_stun()
	show_overhead_pillar()
	load_pals_without_water()
	next_state()


## Count Richtertoff (object 4) held at Wario's place: `y_offset` above and `x_offset` ahead.
func _hold_count_richtertoff(y_offset: int, x_offset: int) -> void:
	w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_ACTION_HELP_WARIO + OBJ_Y) - y_offset)
	w3(W_MENU_OBJ_4 + OBJ_X, r3(W_ACTION_HELP_WARIO + OBJ_X) + x_offset)


## Count Richtertoff's y moved by `step` (`inc [hl]`, `dec [hl]`, or `add`); the new y.
func _move_count_richtertoff_y(step: int) -> int:
	w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_MENU_OBJ_4 + OBJ_Y) + step)
	return r3(W_MENU_OBJ_4 + OBJ_Y)
