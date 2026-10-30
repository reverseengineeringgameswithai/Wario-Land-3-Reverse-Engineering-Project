class_name ActionHelpDemos
extends ActionHelpCommon
## Action Help's demos of the first main power-ups (src/engine/action_help/power_ups/: none.asm,
## lead_overalls.asm, swimming_flippers.asm, head_smash_helmet.asm), each a state table by
## wActionHelpState whose states are named by their original labels.


# --- NoPowerUpActionHelp (none.asm) ---

## Its state, then (not blacked out) the block debris's animation and sprite (object 5), the enemy's
## or block's animation (object 4), and Wario's, all held while an input flashes; then object 4's
## sprite and Wario's.
func no_power_up_action_help() -> void:
	_no_power_up_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_5)
		load_action_help_sprite_far(W_MENU_OBJ_5)
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()


func _no_power_up_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var obj_4_y: int = W_MENU_OBJ_4 + OBJ_Y
	var obj_4_x: int = W_MENU_OBJ_4 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f8395
			if timer_done():
				_no_power_up_start()
		2:  # Func_1f83ba: the Para-Goom walks in
			if move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		3:  # Func_1f83d5: it walks on (to Wario's x) until he comes down on it
			var y: int = wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18 and y >= 0x34:
				w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
				show_para_goom_stun()
				next_state()
				return
			if r3(wario_x) == r3(obj_4_x):
				return
			if r3(wario_x) < move_left_1_5(W_MENU_OBJ_4):
				return
			w3(obj_4_x, r3(wario_x))
			clear_buttons_input()
			clear_d_pad_input()
		4:  # Func_1f842e: both bounce, the Para-Goom back to the right, and land at $40
			var y: int = wario_jump_step()
			var obj_y: int = byte(r3(obj_4_y) + _jump_vel(r3(W_ACTION_HELP_WARIO_VAR)))
			w3(obj_4_y, obj_y)
			if obj_y < 0x40:
				_move_right_1_5(W_MENU_OBJ_4)
				return
			w3(obj_4_y, 0x40)
			if y < 0x40:
				return
			w3(wario_y, 0x40)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_idle()
			w0(W_TIMER, 0x30)
			next_state()
		5:  # Func_1f847a
			if timer_done():
				show_wario_attack()
				w3(W_ACTION_HELP_WARIO_VAR, 0x30)
				next_state()
		6:
			flash_b_input()
		7:  # Func_1f848c: the attack (from $2b on) knocks the Para-Goom away
			play_sfx_rept(6)
			if _attack_count_down() >= 0x2B or move_left_1_5(W_MENU_OBJ_4) >= 0x4C:
				return
			clear_buttons_input()
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_idle()
			w0(W_TIMER, 0x30)
			next_state()
		8:  # Func_1f84d7: it falls off the screen (its fall held at $27); the cracked and solid blocks
			w3(obj_4_x, r3(obj_4_x) + 2)
			var step: int = byte(r3(W_ACTION_HELP_WARIO_VAR) + 1)
			if step >= 0x28:
				step = 0x27
			w3(W_ACTION_HELP_WARIO_VAR, step)
			var obj_y: int = byte(r3(obj_4_y) + _jump_vel(step))
			w3(obj_4_y, obj_y)
			if obj_y < 0x80:
				return
			# Frameset_1e6ba5, OAM_1e697c (its OAM bank and AnimationEnded kept)
			set_up_obj(W_MENU_OBJ_4, 0x40, 0xE8, 0x6BA5)
			w3(W_MENU_OBJ_4 + OBJ_OAM_PTR, 0x69)
			w3(W_MENU_OBJ_4 + OBJ_OAM_PTR + 1, 0x7C)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_walk()
			show_d_right_input()
			next_state()
		9:  # Func_1f8522
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) < 0x78:
				show_b_input()
				show_wario_attack()
				w3(W_ACTION_HELP_WARIO_VAR, 0x30)
				next_state()
		10:  # Func_1f853a: the cracked block breaks; Wario bounces off the solid one
			play_sfx_rept(6)
			if _attack_count_down() >= 0x2B or move_left_1_5(W_MENU_OBJ_4) >= 0x60:
				return
			show_block_debris(0, 0x10)
			show_single_solid_block()
			clear_d_pad_input()
			clear_buttons_input()
			show_wario_attack()
			w3(W_ACTION_HELP_WARIO_VAR, 0x0E)
			next_state()
		11:  # Func_1f8588
			_no_power_up_bounce_back()
		12:  # Func_1f85c3
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		13:  # Func_1f85d3
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x40:
				show_b_input()
				show_wario_attack()
				w3(W_ACTION_HELP_WARIO_VAR, 0x30)
				next_state()
		14:  # Func_1f85eb: he bounces off it again
			play_sfx_rept(6)
			if _attack_count_down() >= 0x2B or move_left_1_5(W_MENU_OBJ_4) >= 0x50:
				return
			clear_d_pad_input()
			clear_buttons_input()
			show_wario_attack()
			w3(W_ACTION_HELP_WARIO_VAR, 0x0E)
			next_state()
		15:  # Func_1f8638
			_no_power_up_bounce_back()
		16:  # Func_1f8673
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		17:  # Func_1f8683: to $40, then up to the block
			if not _walk_to_0x40():
				return
			if move_left_1_5(W_MENU_OBJ_4) >= 0x58:
				return
			w3(obj_4_x, r3(obj_4_x) - 1)
			if byte(r3(obj_4_x) - 0x40) < 0x1C:
				show_a_input()
				show_wario_jump()
				next_state()
		18:  # Func_1f86b5: over it
			_no_power_up_jump_over()
		19:  # Func_1f86ee: once it is off the screen, the slide
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) >= 0xE8:
				show_slide()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_walk()
				show_d_right_input()
				next_state()
		20:  # Func_1f8708
			if _walk_to_0x40() and move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		21:  # Func_1f8730: onto it
			wario_jump_step()
			var x: int = move_left_1_5(W_MENU_OBJ_4)
			if r3(wario_x) < x:
				return
			w3(wario_x, x)
			clear_d_pad_input()
			if r3(wario_y) < 0x20:
				return
			w3(wario_y, 0x20)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_idle()
			clear_buttons_input()
			w0(W_TIMER, 0x30)
			next_state()
		22:  # Func_1f8778
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		23:  # Func_1f8788: down its slope from $39, sliding from $30
			w3(obj_4_x, r3(obj_4_x) - 1)
			var x: int = r3(obj_4_x)
			if x >= 0x39:
				return
			if x >= 0x30:
				w3(wario_y, r3(wario_y) + 1)
				return
			show_wario_slide()
			next_state()
		24:
			flash_d_down_input()
		25:  # Func_1f87a1: the slide, down to $40, then the roll
			if r3(wario_y) < 0x40:
				w3(wario_y, r3(wario_y) + 1)
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) < 0x18:
				clear_d_pad_input()
				show_wario_roll()
				next_state()
		26:  # Func_1f87bd: at $d8 the slide becomes the solid block
			if r3(wario_y) < 0x40:
				w3(wario_y, r3(wario_y) + 1)
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) == 0xD8:
				show_single_solid_block()
				next_state()
		27:  # Func_1f87d6: the roll bumps into it
			if move_left_1_5(W_MENU_OBJ_4) < 0x50:
				show_wario_bump()
				w3(W_ACTION_HELP_WARIO_VAR, 0x0E)
				next_state()
		28:  # Func_1f87fb
			var y: int = wario_jump_step()
			move_left_1_5(W_ACTION_HELP_WARIO)
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or y < 0x40:
				return
			w3(wario_y, 0x40)
			show_wario_idle()
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			w0(W_TIMER, 0x30)
			next_state()
		29:  # Func_1f883c
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		30:  # Func_1f884c: to $40, and up to the block when it is $1c ahead
			if r3(wario_x) != 0x40:
				w3(wario_x, r3(wario_x) + 1)
			w3(obj_4_x, r3(obj_4_x) - 1)
			if byte(r3(obj_4_x) - r3(wario_x)) < 0x1C:
				show_a_input()
				show_wario_jump()
				next_state()
		31:  # Func_1f886b: over it
			_no_power_up_jump_over()
		32:  # Func_1f88a4
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) >= 0xE8:
				end_demo(_no_power_up_start)  # Func_1f8362
		_:
			_note("NoPowerUpActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f839a: Wario walks in, the Para-Goom comes, the debris hidden, the screen shown.
func _no_power_up_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_para_goom_walk()
	hide_block_debris()
	load_pals_without_water()
	next_state()


## `inc [hl]` and, on odd counts, again: an object moving right at 1.5 pixels a loop.
func _move_right_1_5(obj: int) -> void:
	var x: int = byte(r3(obj + OBJ_X) + 1)
	if (r3(W_ACTION_HELP_COUNTER) & 1) != 0:
		x = byte(x + 1)
	w3(obj + OBJ_X, x)


## The attack's count: wActionHelpWarioVar down by 1; its new value.
func _attack_count_down() -> int:
	w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) - 1)
	return r3(W_ACTION_HELP_WARIO_VAR)


## Wario's x on to $40; whether it is there (it was, or reached it).
func _walk_to_0x40() -> bool:
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	if r3(wario_x) == 0x40:
		return true
	w3(wario_x, r3(wario_x) + 1)
	return r3(wario_x) >= 0x40


## Func_1f8588, Func_1f8638: Wario bounces back to the left (his var from $0e) and lands at $40,
## the debris hidden.
func _no_power_up_bounce_back() -> void:
	move_left_1_5(W_ACTION_HELP_WARIO)
	if wario_jump_step() < 0x40:
		return
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_ACTION_HELP_WARIO + OBJ_Y, 0x40)
	hide_block_debris()
	show_wario_idle()
	w0(W_TIMER, 0x30)
	next_state()


## Func_1f86b5, Func_1f886b: Wario's x on to $40 and his jump while the block goes on left (1 a
## loop), until he lands at $40 walking. (Func_1f86b5's wActionHelpWarioEnd is wActionHelpWarioVar.)
func _no_power_up_jump_over() -> void:
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	if r3(wario_x) != 0x40:
		w3(wario_x, r3(wario_x) + 1)
	if wario_jump_step() < 0x40:
		w3(W_MENU_OBJ_4 + OBJ_X, r3(W_MENU_OBJ_4 + OBJ_X) - 1)
		return
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	w3(W_ACTION_HELP_WARIO + OBJ_Y, 0x40)
	show_wario_walk()
	clear_buttons_input()
	next_state()


# --- LeadOverallsActionHelp (lead_overalls.asm) ---

## Its state, then (not blacked out) the enemy's or block's animation (object 4) and Wario's, both
## held while an input flashes, their sprites, and the block debris (object 5).
func lead_overalls_action_help() -> void:
	_lead_overalls_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()
	update_far_obj_anim(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_5)


func _lead_overalls_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f89bb
			if timer_done():
				_lead_overalls_start()
		2:  # Func_1f89e0: the Para-Goom walks in
			if move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		3:  # Func_1f89fb: Wario jumps onto it
			wario_jump_step()
			var x: int = move_left_1_5(W_MENU_OBJ_4)
			if r3(wario_x) >= x:
				show_wario_smash_attack()
				clear_buttons_input()
				next_state()
		4:
			flash_d_down_input()
		5:  # Func_1f8a2a
			if wario_jump_step() >= 0x34:
				w3(wario_y, 0x34)
				w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
				show_enemy_vanish()
				next_state()
		6:  # Func_1f8a52
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_ground_pound()
				next_state()
		7:  # Func_1f8a79: once the Para-Goom has vanished, the blocks
			if r3(W_MENU_OBJ_4 + OBJ_ANIMATION_ENDED) != 0:
				show_vertical_block_pair()
				show_wario_idle()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		8:  # Func_1f8a91
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		9:  # Func_1f8aa1
			if move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		10:  # Func_1f8abc: onto the blocks
			wario_jump_step()
			var x: int = move_left_1_5(W_MENU_OBJ_4)
			if r3(wario_x) < x:
				return
			w3(wario_x, x)
			clear_d_pad_input()
			if r3(wario_y) < 0x20:
				return
			w3(wario_y, 0x20)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_idle()
			clear_buttons_input()
			w0(W_TIMER, 0x30)
			next_state()
		11:  # Func_1f8b04
			if timer_done():
				show_a_input()
				show_wario_jump()
				next_state()
		12:  # Func_1f8b14
			if wario_jump_step() < 0x0C:
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				show_wario_smash_attack()
				show_d_down_input()
				clear_buttons_input()
				next_state()
		13:  # Func_1f8b3d: the top block breaks
			if wario_jump_step() >= 0x20:
				w3(wario_y, 0x20)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_ground_pound()
				show_single_solid_block()
				show_block_debris(0x10)
				w0(W_TIMER, 0x10)
				next_state()
		14:  # Func_1f8b71
			if timer_done():
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				show_wario_smash_attack()
				hide_block_debris()
				next_state()
		15:  # Func_1f8b86
			if wario_jump_step() >= 0x30:
				w3(wario_y, 0x30)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_ground_pound()
				w0(W_TIMER, 0x10)
				next_state()
		16:  # Func_1f8bb2
			if timer_done():
				show_wario_idle()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		17:  # Func_1f8bc7
			if timer_done():
				show_d_right_input()
				show_a_input()
				show_wario_jump()
				next_state()
		18:  # Func_1f8bda: down off the block, its fall held at $27; the Futamogu comes
			if r3(W_ACTION_HELP_WARIO_VAR) != 0x27:
				w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) + 1)
			w3(wario_y, r3(wario_y) + _jump_vel(r3(W_ACTION_HELP_WARIO_VAR)))
			move_left_1_5(W_MENU_OBJ_4)
			if r3(wario_y) < 0x40:
				return
			w3(wario_y, 0x40)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			clear_buttons_input()
			show_wario_walk()
			show_d_right_input()
			set_up_far_obj(W_MENU_OBJ_4, 0x50, 0xC0, 0x6F66, 0x6BAB, ACTION_HELP_2_BANK, true)
			set_up_far_obj(W_MENU_OBJ_5, 0x40, 0xB8, 0x6B8B, 0x697C, ACTION_HELP_2_BANK, true)
			next_state()
		19:  # Func_1f8c59
			var x: int = byte(move_left_1_5(W_MENU_OBJ_4) - 8)
			w3(W_MENU_OBJ_5 + OBJ_X, x)
			if x < 0x40:
				show_wario_idle()
				show_futamogu_angry()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		20:  # Func_1f8c81
			if timer_done():
				show_a_input()
				show_wario_jump()
				show_futamogu_happy()
				next_state()
		21:  # Func_1f8c94
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				show_wario_smash_attack()
				show_d_down_input()
				clear_buttons_input()
				next_state()
		22:  # Func_1f8cbb: the Futamogu pounded down
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				show_wario_ground_pound()
				w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_MENU_OBJ_4 + OBJ_Y) + 4)
				_restart_frameset(W_MENU_OBJ_4, 0x6F7D)
				w0(W_TIMER, 0x10)
				next_state()
		23:  # Func_1f8cf7
			if timer_done():
				show_wario_smash_attack()
				next_state()
		24:  # Func_1f8d04
			if wario_jump_step() >= 0x44:
				w3(wario_y, 0x44)
				show_wario_ground_pound()
				w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_MENU_OBJ_4 + OBJ_Y) + 4)
				w0(W_TIMER, 0x10)
				next_state()
		25:  # Func_1f8d34
			if timer_done():
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				show_wario_idle()
				clear_d_pad_input()
				next_state()
		26:  # Func_1f8d49
			if wario_jump_step() >= 0x48:
				w3(wario_y, 0x48)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x20)
				next_state()
		27:  # Func_1f8d72: the Futamogu climbs out
			if timer_done():
				_restart_frameset(W_MENU_OBJ_4, 0x6F6B)
				next_state()
		28:  # Func_1f8d88
			w3(W_MENU_OBJ_4 + OBJ_Y, r3(W_MENU_OBJ_4 + OBJ_Y) - 1)
			w3(wario_y, r3(wario_y) - 1)
			if r3(wario_y) == 0x40:
				show_wario_idle()
				show_futamogu_angry()
				w0(W_TIMER, 0x30)
				next_state()
		29:  # Func_1f8da4
			if timer_done():
				show_d_right_input()
				show_wario_walk()
				show_futamogu_happy()
				next_state()
		30:  # Func_1f8db7: it walks off
			var x: int = byte(move_left_1_5(W_MENU_OBJ_4) - 8)
			w3(W_MENU_OBJ_5 + OBJ_X, x)
			if x >= 0xF0:
				end_demo(_lead_overalls_start)  # Func_1f8988
		_:
			_note("LeadOverallsActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f89c0: Wario walks in, the Para-Goom comes, the debris hidden, the screen shown.
func _lead_overalls_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_para_goom_walk()
	hide_block_debris()
	load_pals_without_water()
	next_state()


# --- SwimmingFlippersActionHelp (swimming_flippers.asm) ---

## Its state, then (not blacked out) Wario's animation, held while an input flashes, and sprite.
func swimming_flippers_action_help() -> void:
	_swimming_flippers_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_wario_anim()
	load_action_help_wario_sprite()


func _swimming_flippers_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var counter: int = r3(W_ACTION_HELP_COUNTER)
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f8e64
			if timer_done():
				_swimming_flippers_start()
		2:  # Func_1f8ed9
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		3:  # Func_1f8ee9
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x2C:
				show_wario_jump()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		4:  # Func_1f8efe: into the water
			w3(wario_x, r3(wario_x) + 1)
			if wario_jump_step() >= 0x50:
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_swim()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		5:  # Func_1f8f2c
			if timer_done():
				show_wario_submerge()
				next_state()
		6:
			flash_d_down_input()
		7:  # Func_1f8f39: down
			play_sfx_rept(37)
			if (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x58:
				show_d_right_input()
				w0(W_TIMER, 0x10)
				next_state()
		8:  # Func_1f8f6b: right
			play_sfx_rept(37)
			if not timer_waited() or (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x6C:
				show_d_down_input()
				w0(W_TIMER, 0x10)
				next_state()
		9:  # Func_1f8fa6: down
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x60:
				clear_d_pad_input()
				next_state()
		10:  # Func_1f8fdc: back left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x34:
				w3(wario_x, 0x34)
				show_d_up_input()
				w0(W_TIMER, 0x10)
				next_state()
		11:  # Func_1f900a: up
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) - 1)
			if r3(wario_y) < 0x58:
				show_wario_underwater_thrust()
				clear_d_pad_input()
				next_state()
		12:
			flash_b_input()
		13:  # Func_1f9043: the thrust, slower from $58
			play_sfx_rept(15)
			if r3(wario_x) >= 0x58 and (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x6C:
				show_wario_submerge()
				show_d_down_input()
				clear_buttons_input()
				w0(W_TIMER, 0x10)
				next_state()
		14:  # Func_1f9080: down
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x60:
				show_d_right_input()
				next_state()
		15:  # Func_1f90b6: left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x50:
				w3(wario_x, 0x50)
				show_wario_underwater_thrust()
				show_b_input()
				next_state()
		16:  # Func_1f90e2: the thrust against the wall
			play_sfx_rept(15)
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) >= 0x30:
				w0(W_TIMER, 0)
				show_wario_submerge()
				clear_buttons_input()
				next_state()
		17:  # Func_1f910e: left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x34:
				w3(wario_x, 0x34)
				show_d_up_input()
				w0(W_TIMER, 0x10)
				next_state()
		18:  # Func_1f913c: up to the surface
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) - 1)
			if r3(wario_y) < 0x50:
				show_wario_swim_left()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		19:  # Func_1f917a
			if timer_done():
				show_wario_jump_left()
				show_d_left_input()
				show_a_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				next_state()
		20:  # Func_1f9191: out of the water
			if r3(wario_x) != 0x18:
				w3(wario_x, r3(wario_x) - 1)
			var y: int = wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or y < 0x40:
				return
			w3(wario_y, 0x40)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			end_demo(_swimming_flippers_start)  # Func_1f8e31
		_:
			_note("SwimmingFlippersActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f8e69: Wario stands by the water, which moves (the room animation's tiles 2), and the
## screen is shown.
func _swimming_flippers_start() -> void:
	_dma_wario_gfx(WARIO_IDLE_GFX)
	set_up_obj(W_ACTION_HELP_WARIO, 0x40, 0x18, 0x425F)
	w3(W_ACTION_HELP_WARIO_VAR, 0)
	_wario_oam(0x4000)
	sim.wAnimatedTilesFrameDuration = 6
	sim.wAnimatedTilesGfx = 2  # ANIMATED_TILES_GFX_02
	sim.wRoomAnimatedTilesEnabled = 1
	w0(W_TIMER, 0x30)
	load_pals_with_water()
	next_state()


# --- HeadSmashHelmetActionHelp (head_smash_helmet.asm) ---

## Its state, then (not blacked out) the block debris's animation and sprite (object 5), the
## block's animation (object 4) and Wario's, both held while an input flashes, and their sprites.
func head_smash_helmet_action_help() -> void:
	_head_smash_helmet_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	update_far_obj_anim(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_5)
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()


func _head_smash_helmet_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var obj_4_x: int = W_MENU_OBJ_4 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1f92ad
			if timer_done():
				_head_smash_helmet_start()
		2:  # Func_1f92ee: the block comes over Wario
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) < 0x40:
				show_wario_idle()
				clear_d_pad_input()
				w0(W_TIMER, 0x10)
				next_state()
		3:  # Func_1f9306
			if timer_done():
				show_wario_jump()
				next_state()
		4:
			flash_a_input()
		5:  # Func_1f9313: the block breaks, the next one (Frameset_1e6b67) comes
			_head_smash(0x6B67)
		6:  # Func_1f935b
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				clear_buttons_input()
				show_wario_idle()
				w0(W_TIMER, 0x20)
				next_state()
		7:  # Func_1f938a: the debris hidden once its animation ends
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		8:  # Func_1f93a3
			w3(obj_4_x, r3(obj_4_x) - 1)
			if r3(obj_4_x) < 0x40:
				show_wario_idle()
				clear_d_pad_input()
				w0(W_TIMER, 0x10)
				next_state()
		9:  # Func_1f93bb
			if timer_done():
				show_wario_jump()
				show_a_input()
				next_state()
		10:  # Func_1f93cb: it breaks, the next one (Frameset_1e6b6a) placed off the screen
			_head_smash(0x6B6A)
		11:  # Func_1f9413
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				clear_buttons_input()
				show_wario_idle()
				w0(W_TIMER, 0x20)
				next_state()
		12:  # Func_1f9442
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
			if timer_done():
				end_demo(_head_smash_helmet_start)  # Func_1f927a
		_:
			_note("HeadSmashHelmetActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1f92b2: Wario walks in, a block (Frameset_1e6b64) comes in at ($20, $e8), the debris
## hidden, the screen shown.
func _head_smash_helmet_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	set_up_far_obj(W_MENU_OBJ_4, 0x20, 0xE8, 0x6B64, 0x697C, ACTION_HELP_2_BANK, true)
	hide_block_debris()
	load_pals_without_water()
	next_state()


## Func_1f9313, Func_1f93cb: Wario's jump until $18 above him reaches the block's y; then his fall
## (his var at $18), the debris at the block, and the block replaced at ($20, $e8) by `frameset`.
func _head_smash(frameset: int) -> void:
	var y: int = wario_jump_step()
	if byte(y - 0x18) >= r3(W_MENU_OBJ_4 + OBJ_Y):
		return
	w3(W_ACTION_HELP_WARIO_VAR, 0x18)
	show_block_debris(0)
	set_up_far_obj(W_MENU_OBJ_4, 0x20, 0xE8, frameset, 0x697C, ACTION_HELP_2_BANK, true)
	next_state()
