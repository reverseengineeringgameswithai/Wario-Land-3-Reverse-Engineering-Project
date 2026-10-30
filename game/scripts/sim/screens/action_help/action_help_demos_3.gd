class_name ActionHelpDemos3
extends ActionHelpDemos2
## Action Help's demos of the super jump slam overalls, the high jump boots, and Prince Froggy's
## gloves (src/engine/action_help/power_ups/: super_jump_slam_overalls.asm, high_jump_boots.asm,
## prince_frogs_gloves.asm).


## JumpVelTable_HighJump's entry.
func _high_jump_vel(index: int) -> int:
	return _table("jump_vel_table_high_jump", index & 0xFF)


## A high jump's step: wActionHelpWarioVar on, and Wario's y by JumpVelTable_HighJump at it; the
## new y.
func _high_jump_step() -> int:
	w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) + 1)
	var y: int = byte(r3(W_ACTION_HELP_WARIO + OBJ_Y) + _high_jump_vel(r3(W_ACTION_HELP_WARIO_VAR)))
	w3(W_ACTION_HELP_WARIO + OBJ_Y, y)
	return y


## A high jump's later step: Wario's y by JumpVelTable_HighJump at wActionHelpWarioVar as it was
## (`ld a, [hl]; inc [hl]`), the var on; the new y.
func _high_jump_late_step() -> int:
	var index: int = r3(W_ACTION_HELP_WARIO_VAR)
	w3(W_ACTION_HELP_WARIO_VAR, index + 1)
	var y: int = byte(r3(W_ACTION_HELP_WARIO + OBJ_Y) + _high_jump_vel(index))
	w3(W_ACTION_HELP_WARIO + OBJ_Y, y)
	return y


## A fall's step: wActionHelpWarioVar on, back to $27 once it reaches $28 (the fall's top speed),
## and Wario's y by JumpVelTable_Normal (or JumpVelTable_HighJump) at it; the new y.
func _fall_step(high_jump: bool = false) -> int:
	var index: int = byte(r3(W_ACTION_HELP_WARIO_VAR) + 1)
	if index >= 0x28:
		index = 0x27
	w3(W_ACTION_HELP_WARIO_VAR, index)
	var vel: int = _high_jump_vel(index) if high_jump else _jump_vel(index)
	var y: int = byte(r3(W_ACTION_HELP_WARIO + OBJ_Y) + vel)
	w3(W_ACTION_HELP_WARIO + OBJ_Y, y)
	return y


## The ground's shake by wTimer: wSCY 2 on when its low bits are 3, 2 back when they are 1.
func _shake_screen() -> void:
	match r0(W_TIMER) & 0b11:
		3:
			sim.wSCY = byte(sim.wSCY + 2)
		1:
			sim.wSCY = byte(sim.wSCY - 2)


# --- SuperJumpSlamOverallsActionHelp (super_jump_slam_overalls.asm) ---

## Its state, then (not blacked out) the animations of object 5, object 4 (each with its
## AnimationEnded), and Wario, held while an input flashes; their sprites.
func super_jump_slam_overalls_action_help() -> void:
	_super_jump_slam_overalls_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_5)
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
	load_action_help_sprite_far(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()


func _super_jump_slam_overalls_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var obj4_x: int = W_MENU_OBJ_4 + OBJ_X
	var obj5_x: int = W_MENU_OBJ_5 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1fa4e5
			if timer_done():
				_super_jump_slam_overalls_start()
		2:  # Func_1fa526: the Count Richtertoff, then the Para-Goom, come in
			w3(obj5_x, r3(obj5_x) - 1)
			if r3(obj5_x) >= 0x90:
				return
			if move_left_1_5(W_MENU_OBJ_4) >= 0xA0:
				return
			show_a_input()
			clear_d_pad_input()
			show_wario_jump()
			next_state()
		3:  # Func_1fa54c
			w3(obj4_x, r3(obj4_x) - 1)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				show_wario_smash_attack()
				clear_buttons_input()
				next_state()
		4:
			flash_d_down_input()
		5:  # Func_1fa574: the slam shakes the ground and stuns the Para-Goom
			w3(obj4_x, r3(obj4_x) - 1)
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				show_wario_ground_shake()
				show_para_goom_stun()
				w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
				w0(W_TIMER, 0x20)
				next_state()
		6:  # Func_1fa5a8: the Para-Goom bounces (by wActionHelpWarioVar) while the screen shakes
			var obj4_y: int = W_MENU_OBJ_4 + OBJ_Y
			w3(W_ACTION_HELP_WARIO_VAR, r3(W_ACTION_HELP_WARIO_VAR) + 1)
			w3(obj4_y, r3(obj4_y) + _jump_vel(r3(W_ACTION_HELP_WARIO_VAR)))
			if r3(obj4_y) >= 0x40:
				w3(W_ACTION_HELP_WARIO_VAR, 0x26)
				w3(obj4_y, 0x40)
			if timer_done():
				show_wario_jump()
				show_a_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				next_state()
				return
			if r0(W_TIMER) == 0x05:
				show_wario_idle()
				clear_d_pad_input()
			_shake_screen()
		7:  # Func_1fa602: onto the Count Richtertoff, once it reaches $40
			if r3(obj5_x) != 0x40:
				w3(obj4_x, r3(obj4_x) - 1)
				w3(obj5_x, r3(obj5_x) - 1)
				if r3(obj5_x) == 0x40:
					clear_buttons_input()
					show_d_down_input()
					show_wario_smash_attack()
					w3(W_ACTION_HELP_WARIO_VAR, 0x18)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or r3(wario_y) < 0x30:
				return
			w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
			show_enemy_vanish(W_MENU_OBJ_5)
			next_state()
		8:  # Func_1fa653: bounced up, then onto the Para-Goom, once it reaches $40
			if r3(obj4_x) != 0x40:
				w3(obj4_x, r3(obj4_x) - 1)
				if r3(obj4_x) == 0x40:
					w3(W_ACTION_HELP_WARIO_VAR, 0x18)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or r3(wario_y) < 0x34:
				return
			w3(W_ACTION_HELP_WARIO_VAR, 0x0A)
			clear_d_pad_input()
			hide_block_debris()
			show_enemy_vanish()
			next_state()
		9:  # Func_1fa698
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_idle()
				next_state()
		10:  # Func_1fa6bf: once the Para-Goom has vanished, the blocks
			if r3(W_MENU_OBJ_4 + OBJ_ANIMATION_ENDED) != 0:
				show_vertical_block_pair()
				show_wario_walk()
				show_d_right_input()
				next_state()
		11:  # Func_1fa6d2
			if move_left_1_5(W_MENU_OBJ_4) < 0x60:
				show_a_input()
				show_wario_jump()
				next_state()
		12:  # Func_1fa6ed: onto the blocks
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
		13:  # Func_1fa735
			if timer_done():
				show_a_input()
				show_wario_jump()
				next_state()
		14:  # Func_1fa745
			if wario_jump_step() < 0x0C:
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				show_wario_smash_attack()
				show_d_down_input()
				clear_buttons_input()
				next_state()
		15:  # Func_1fa76e: the top block breaks
			if wario_jump_step() >= 0x20:
				w3(wario_y, 0x20)
				show_single_solid_block()
				show_block_debris(0x10)
				next_state()
		16:  # Func_1fa796: and the bottom one, the slam going through
			if _fall_step() >= 0x30:
				w3(wario_y, 0x30)
				show_block_debris(0x00)
				hide_block_debris(W_MENU_OBJ_4)
				show_wario_ground_shake()
				w0(W_TIMER, 0x20)
				next_state()
		17:  # Func_1fa7d0: the debris gone once its animation ends; the screen shakes
			if r3(W_MENU_OBJ_5 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris()
			if timer_done():
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
				return
			if r0(W_TIMER) == 0x05:
				show_wario_jump()
				clear_d_pad_input()
			_shake_screen()
		18:  # Func_1fa80b
			if wario_jump_step() >= 0x40:
				w3(wario_y, 0x40)
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x30)
				next_state()
		19:  # Func_1fa837
			if timer_done():
				end_demo(_super_jump_slam_overalls_start)  # Func_1fa4b2
		_:
			_note("SuperJumpSlamOverallsActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1fa4ea: Wario walks in, the Para-Goom and the Count Richtertoff (object 5) come, the screen
## is shown.
func _super_jump_slam_overalls_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_para_goom_walk()
	set_up_far_obj(W_MENU_OBJ_5, 0x40, 0xE8, 0x6F4D, 0x6BAB, ACTION_HELP_2_BANK, true)
	load_pals_without_water()
	next_state()


# --- HighJumpBootsActionHelp (high_jump_boots.asm) ---

## Its state, then (not blacked out) the animations of object 5, object 4 (each with its
## AnimationEnded), and Wario (with his), held while an input flashes; their sprites.
func high_jump_boots_action_help() -> void:
	_high_jump_boots_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_far_obj_anim(W_MENU_OBJ_5)
		update_far_obj_anim(W_MENU_OBJ_4)
		update_wario_anim()
		w3(W_ACTION_HELP_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_action_help_sprite_far(W_MENU_OBJ_5)
	load_action_help_sprite_far(W_MENU_OBJ_4)
	load_action_help_wario_sprite()


func _high_jump_boots_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var obj4_x: int = W_MENU_OBJ_4 + OBJ_X
	var obj5_x: int = W_MENU_OBJ_5 + OBJ_X
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1fa945
			if timer_done():
				_high_jump_boots_start()
		2:  # Func_1fa984: the wall comes in
			w3(obj5_x, r3(obj5_x) - 1)
			if r3(obj5_x) < 0x58:
				show_wario_idle()
				next_state()
		3:
			flash_d_up_input()
		4:  # Func_1fa994
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) >= 0x30:
				w0(W_TIMER, 0)
				show_a_input()
				show_wario_jump()
				next_state()
		5:  # Func_1fa9a9: the high jump
			w3(obj5_x, r3(obj5_x) - 1)
			_high_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				clear_buttons_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		6:  # Func_1fa9d3: onto the wall
			w3(obj5_x, r3(obj5_x) - 2)
			if _high_jump_late_step() >= 0x10:
				w3(wario_y, 0x10)
				clear_d_pad_input()
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x30)
				next_state()
		7:  # Func_1faa07
			if timer_done():
				show_d_right_input()
				show_wario_jump()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		8:  # Func_1faa1c: down off it
			w3(obj5_x, r3(obj5_x) - 1)
			if _fall_step(true) >= 0x40:
				w3(wario_y, 0x40)
				clear_d_pad_input()
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				next_state()
		9:  # Func_1faa51: the Para-Goom comes in
			w3(obj4_x, r3(obj4_x) - 1)
			if r3(obj4_x) < 0x68:
				show_a_input()
				show_wario_jump()
				next_state()
		10:  # Func_1faa64: onto the Para-Goom, which is stunned; off it to the left
			w3(obj4_x, r3(obj4_x) - 1)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or r3(wario_y) < 0x34:
				return
			show_d_left_input()
			show_para_goom_stun()
			show_wario_jump_left()
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			next_state()
		11:  # Func_1faa99: the view following him until the wall is at $3c
			if r3(obj5_x) < 0x3C:
				w3(obj5_x, r3(obj5_x) + 1)
				w3(obj4_x, r3(obj4_x) + 1)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				clear_buttons_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		12:  # Func_1faacc: onto the wall
			if wario_jump_step() >= 0x10:
				w3(wario_y, 0x10)
				show_d_right_input()
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x30)
				next_state()
		13:  # Func_1faafb
			clear_d_pad_input()
			if timer_done():
				show_a_input()
				show_d_right_and_d_down_input()
				show_wario_jump()
				show_wario_smash_attack()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		14:  # Func_1fab19: down onto the Para-Goom (from $34, Wario put at $30)
			w3(obj4_x, r3(obj4_x) - 1)
			w3(obj5_x, r3(obj5_x) - 1)
			if _fall_step() >= 0x34:
				w3(wario_y, 0x30)
				show_d_left_input()
				show_enemy_vanish()
				show_wario_jump_left()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				next_state()
		15:  # Func_1fab55: bounced back
			w3(obj4_x, r3(obj4_x) + 1)
			w3(obj5_x, r3(obj5_x) + 1)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				clear_buttons_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		16:  # Func_1fab83
			w3(obj4_x, r3(obj4_x) + 2)
			w3(obj5_x, r3(obj5_x) + 2)
			if wario_jump_step() >= 0x10:
				w3(wario_y, 0x10)
				w3(W_ACTION_HELP_WARIO_VAR, 0x0E)
				next_state()
		17:  # Func_1fabb2: the Para-Goom hidden once it has vanished; down
			if r3(W_MENU_OBJ_4 + OBJ_ANIMATION_ENDED) != 0:
				hide_block_debris(W_MENU_OBJ_4)
			w3(obj5_x, r3(obj5_x) + 1)
			if _fall_step() >= 0x40:
				w3(wario_y, 0x40)
				clear_d_pad_input()
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x30)
				next_state()
		18:  # Func_1fabf8
			if timer_done():
				show_a_input()
				show_wario_jump()
				next_state()
		19:  # Func_1fac08: a plain jump (the A input off at its top), and the landing
			wario_jump_step()
			var jump: int = r3(W_ACTION_HELP_WARIO_VAR)
			if jump == 0x18:
				clear_buttons_input()
				return
			if jump < 0x18 or r3(wario_y) < 0x40:
				return
			show_a_input()
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			show_wario_land()
			next_state()
		20:  # Func_1fac3c: once he has landed
			if r3(W_ACTION_HELP_WARIO_ANIMATION_ENDED) != 0:
				show_d_right_input()
				show_wario_jump()
				next_state()
		21:  # Func_1fac4c: the high jump
			w3(obj5_x, r3(obj5_x) - 1)
			_high_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) >= 0x18:
				clear_buttons_input()
				next_state()
		22:  # Func_1fac71: onto the wall
			w3(obj5_x, r3(obj5_x) - 2)
			if _high_jump_late_step() >= 0x10:
				w3(wario_y, 0x10)
				clear_d_pad_input()
				show_wario_idle()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				w0(W_TIMER, 0x30)
				next_state()
		23:  # Func_1faca5
			if timer_done():
				show_a_input()
				show_d_right_input()
				show_wario_jump()
				next_state()
		24:  # Func_1facb8: off the wall's far side (`add $20; cp $60`: from $40 to $df)
			w3(obj5_x, r3(obj5_x) - 2)
			if byte(_fall_step() + 0x20) >= 0x60:
				w3(wario_y, 0x40)
				end_demo(_high_jump_boots_start)  # Func_1fa912
		_:
			_note("HighJumpBootsActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1fa94a: Wario walks in, the Para-Goom set up (off screen) and the wall (object 5, its
## AnimationEnded kept) comes, the screen is shown.
func _high_jump_boots_start() -> void:
	show_initial_wario_walk()
	show_d_right_input()
	show_para_goom_walk()
	set_up_far_obj(W_MENU_OBJ_5, 0x40, 0xE8, 0x6B99, 0x697C, ACTION_HELP_2_BANK, false)
	load_pals_without_water()
	next_state()


# --- PrinceFrogsGlovesActionHelp (prince_frogs_gloves.asm) ---

## Its state, then (not blacked out) Wario's animation, held while an input flashes, and sprite.
func prince_frogs_gloves_action_help() -> void:
	_prince_frogs_gloves_state()
	if r3(W_ACTION_HELP_BLACKED_OUT) != 0:
		return
	if r3(W_ACTION_HELP_FROZEN) == 0:
		update_wario_anim()
	load_action_help_wario_sprite()


func _prince_frogs_gloves_state() -> void:
	var wario_y: int = W_ACTION_HELP_WARIO + OBJ_Y
	var wario_x: int = W_ACTION_HELP_WARIO + OBJ_X
	var counter: int = r3(W_ACTION_HELP_COUNTER)
	match r3(W_ACTION_HELP_STATE):
		0:
			action_help_init()
		1:  # Func_1fad75
			if timer_done():
				_prince_frogs_gloves_start()
		2:  # Func_1fadea
			if timer_done():
				show_wario_walk()
				show_d_right_input()
				next_state()
		3:  # Func_1fadfa
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x2C:
				show_wario_jump()
				w3(W_ACTION_HELP_WARIO_VAR, 0x18)
				next_state()
		4:  # Func_1fae0f: into the water
			w3(wario_x, r3(wario_x) + 1)
			if wario_jump_step() >= 0x50:
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				show_wario_swim()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		5:  # Func_1fae3d
			if timer_done():
				show_d_down_input()
				show_wario_submerge()
				next_state()
		6:  # Func_1fae4d: down
			play_sfx_rept(37)
			if (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x58:
				show_d_right_input()
				w0(W_TIMER, 0x10)
				next_state()
		7:  # Func_1fae7f: right
			play_sfx_rept(37)
			if not timer_waited() or (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x6C:
				show_d_down_input()
				w0(W_TIMER, 0x10)
				next_state()
		8:  # Func_1faeba: down
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) + 1)
			if r3(wario_y) >= 0x60:
				clear_d_pad_input()
				next_state()
		9:  # Func_1faef0: back left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x50:
				w3(wario_x, 0x50)
				show_wario_underwater_stopped()
				next_state()
		10:
			flash_b_input()
		11:  # Func_1faf19: the thrust, slower from $58
			play_sfx_rept(15)
			if r3(wario_x) >= 0x58 and (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x6C:
				show_wario_submerge()
				clear_buttons_input()
				next_state()
		12:  # Func_1faf4e: left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x34:
				w3(wario_x, 0x34)
				show_wario_underwater_stopped()
				show_b_input()
				next_state()
		13:  # Func_1faf7a: a short thrust, slower from $3c
			play_sfx_rept(15)
			if r3(wario_x) >= 0x3C and (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x4C:
				clear_buttons_input()
				w0(W_TIMER, 0x0C)
				next_state()
		14:  # Func_1fafb1: after a pause, the thrust again, slower from $58
			play_sfx_rept(15)
			if r0(W_TIMER) != 0:
				if not timer_done():
					return
				show_wario_underwater_stopped()
				show_b_input()
			if r3(wario_x) >= 0x58 and (counter & 1) != 0:
				return
			w3(wario_x, r3(wario_x) + 1)
			if r3(wario_x) >= 0x6C:
				show_wario_submerge()
				clear_buttons_input()
				next_state()
		15:  # Func_1faff5: left
			play_sfx_rept(37)
			w3(wario_x, r3(wario_x) - 1)
			if r3(wario_x) < 0x34:
				w3(wario_x, 0x34)
				show_d_up_input()
				w0(W_TIMER, 0x10)
				next_state()
		16:  # Func_1fb023: up to the surface
			play_sfx_rept(37)
			if not timer_waited() or (counter & 0b11) != 0:
				return
			w3(wario_y, r3(wario_y) - 1)
			if r3(wario_y) < 0x50:
				show_wario_swim_left()
				clear_d_pad_input()
				w0(W_TIMER, 0x30)
				next_state()
		17:  # Func_1fb061
			if timer_done():
				show_wario_jump_left()
				show_d_left_input()
				show_a_input()
				w3(W_ACTION_HELP_WARIO_VAR, 0)
				next_state()
		18:  # Func_1fb078: out of the water
			if r3(wario_x) != 0x18:
				w3(wario_x, r3(wario_x) - 1)
			wario_jump_step()
			if r3(W_ACTION_HELP_WARIO_VAR) < 0x18 or r3(wario_y) < 0x40:
				return
			w3(wario_y, 0x40)
			w3(W_ACTION_HELP_WARIO_VAR, 0)
			end_demo(_prince_frogs_gloves_start)  # Func_1fad42
		_:
			_note("PrinceFrogsGlovesActionHelp state %d" % r3(W_ACTION_HELP_STATE))


## Func_1fad7a: Wario stands by the water, which moves (the room animation's tiles 2), and the
## screen is shown.
func _prince_frogs_gloves_start() -> void:
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
