class_name ActionHelpSim
extends ActionHelpSpecialDemos
## Action Help (src/engine/action_help/: state_table.asm, core.asm), ported by translation
## (WL3-051): _ActionHelpStateTable's fades, InitActionHelp (the power-up shown: Wario's, a
## transformation's, or with the title screen's demos the next one), and UpdateActionHelp: the
## power-up's demo (ActionHelpDemos to ActionHelpSpecialDemos) with the cursor, d-pad, and buttons.
## After a level's clear the demo's end leads to the map; from the pause menu, A, B, or Start leads
## back to it (not ported).


## One game loop of Action Help: _ActionHelpStateTable by wSubState, then what the V-Blank function
## it left does before the next loop (VBlank_1fb6b7's pending DMA).
func update() -> void:
	loops += 1
	to_pause_menu = false
	screen_loads.clear()
	palette_writes.clear()
	vram_writes.clear()
	dma_writes.clear()
	match sim.wSubState:
		0, 4:
			fade(2)  # SlowFadeBGToWhite (FADE_SPEED_FAST)
		1:
			init_action_help()
		2:
			fade(2)  # DarkenBGToPal_Fast
			if sim.wSubState != 2:  # its end (all 64 colours): the palettes are wTempPals1's and 2's
				palette_writes.append([false, 0, _wram0_bytes(W_TEMP_PALS_1, 0x40)])
				palette_writes.append([true, 0, _wram0_bytes(W_TEMP_PALS_2, 0x40)])
		3:
			update_action_help()
		5:
			return_to_pause_menu()
		_:
			_note("_ActionHelpStateTable sub-state %d (DebugReset)" % sim.wSubState)
	if vblank_func == VBlankFunc.ACTION_HELP and r0(W_IS_DMA_TRANSFER_PENDING) != 0:
		var source: int = (r0(W_PENDING_DMA_SOURCE_BANK) << 16) | (r0(W_PENDING_DMA_SOURCE_PTR) << 8) \
				| r0(W_PENDING_DMA_SOURCE_PTR + 1)
		var destination: int = (r0(W_PENDING_DMA_DESTINATION_PTR) << 8) | r0(W_PENDING_DMA_DESTINATION_PTR + 1)
		dma_writes.append([source, r0(W_PENDING_DMA_DESTINATION_BANK), destination,
				(r0(W_PENDING_DMA_LENGTH) + 1) * 0x10])
		w0(W_IS_DMA_TRANSFER_PENDING, 0)


## InitActionHelp: the power-up to show (a transformation's, or Wario's power-up; on the title
## screen moved on by hDemoPowerUp, which goes on to the next), the room animation stopped, the
## screen loaded blacked out, and the cursor (below the power-up), d-pad, and buttons.
func init_action_help() -> void:
	w3(W_ACTION_HELP_STATE, 0)
	w0(W_TIMER, 0)
	var demo: int = sim.hDemoPowerUp if (sim.wPowerUpLevel & ACTION_HELP_TITLE_SCREEN) != 0 else NO_POWER_UP
	var power_up: int
	match sim.wTransformation:
		TRANSFORMATION_OWL_WARIO:
			power_up = POWER_UP_OWL
		TRANSFORMATION_RAIL:
			power_up = POWER_UP_RAIL
		TRANSFORMATION_VAMPIRE_WARIO:
			power_up = POWER_UP_VAMPIRE
		_:
			power_up = sim.wPowerUpLevel & POWER_UP_MASK
	power_up = byte(power_up + demo)
	if power_up >= NUM_TOTAL_POWER_UPS:
		power_up -= NUM_TOTAL_POWER_UPS
	w3(W_ACTION_HELP_POWER_UP, power_up)
	sim.hDemoPowerUp = sim.hDemoPowerUp + 1 if sim.hDemoPowerUp + 1 < NUM_TOTAL_POWER_UPS else 0
	sim.wAnimatedTilesFrameDuration = 0
	sim.wAnimatedTilesGfx = 0
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	sim.wRoomAnimatedTilesEnabled = 0
	clear_virtual_oam()
	load_common_pals()
	load_power_up_pals()
	screen_loads.append(["action_help"])
	vblank_func = VBlankFunc.ACTION_HELP
	sim.wSCX = 0
	sim.wSCY = 4
	set_up_obj(W_MENU_OBJ_1, 144, byte(((power_up << 4) | (power_up >> 4)) + 0x08), 0x6B8E)  # SCREEN_HEIGHT_PX, swap a
	set_up_obj(W_MENU_OBJ_2, 0x77, 0x3F, 0x6B76)
	set_up_obj(W_MENU_OBJ_3, 0x7D, 0x67, 0x6B6D)
	update_obj_anim(W_MENU_OBJ_3, ACTION_HELP_2_BANK)
	load_action_help_sprite(W_MENU_OBJ_3)
	if (sim.wPowerUpLevel & ACTION_HELP_TITLE_SCREEN) != 0 and power_up < NUM_MAIN_POWER_UPS:
		var level: int = sim.wPowerUpLevel & POWER_UP_MASK
		_cursor_attribute(level, 0x03)
		if level >= power_up:
			_cursor_attribute(power_up, _table("power_up_ob_pals", power_up))
	clear_unused_virtual_oam()
	sim.wSubState = byte(sim.wSubState + 1)


## UpdateActionHelp: A, B, or Start closes it (not after a level's clear); the counter; a main
## power-up's demo after the d-pad's repeat and (from the pause menu) left or right to another, with
## the cursor; a special one's; then the d-pad and buttons.
func update_action_help() -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) == 0 \
			and (sim.wJoypadPressed & (WarioRam.PAD_A | WarioRam.PAD_B | WarioRam.PAD_START)) != 0:
		_close_action_help()
		return
	w3(W_ACTION_HELP_COUNTER, r3(W_ACTION_HELP_COUNTER) + 1)
	if (r3(W_ACTION_HELP_POWER_UP) & POWER_UP_MASK) >= NUM_MAIN_POWER_UPS:
		execute_special_power_up_action_help()
	else:
		process_dpad_repeat()
		if (sim.wPowerUpLevel & (ACTION_HELP_TITLE_SCREEN | ACTION_HELP_LEVEL_CLEAR)) == 0:
			switch_power_up()
		execute_main_power_up_action_help()
		update_obj_anim(W_MENU_OBJ_1, ACTION_HELP_2_BANK)
		load_action_help_sprite(W_MENU_OBJ_1)
	update_obj_anim(W_MENU_OBJ_2, ACTION_HELP_2_BANK)
	load_action_help_sprite(W_MENU_OBJ_2)
	update_obj_anim(W_MENU_OBJ_3, ACTION_HELP_2_BANK)
	load_action_help_sprite(W_MENU_OBJ_3)
	clear_unused_virtual_oam()


## UpdateActionHelp.CloseActionHelp: on the title screen, the title again (InitWithoutDemoPowerUpReset);
## otherwise the animated tiles stopped, w3d50d cleared, and the fade back to the pause menu.
func _close_action_help() -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_TITLE_SCREEN) != 0:
		sim.request_init(LevelSim.INIT_KEEP_DEMO_POWER_UP)
		return
	sim.wAnimatedTilesFrameDuration = 0
	sim.wAnimatedTilesGfx = 0
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	w3(W3D50D, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## ReturnToPauseMenuFromActionHelp (_ReturnToPauseMenuFromActionHelp): the pause menu's state, then
## its init without backing up VRAM, which the LevelSim runs on the pause menu after this loop
## (to_pause_menu; PauseMenuSim.return_from_action_help).
func return_to_pause_menu() -> void:
	sim.wState = ST_PAUSE_MENU
	sim.wSubState = SST_PAUSE_INIT_MENU
	to_pause_menu = true


## Whether the last loop went back to the pause menu (return_to_pause_menu).
var to_pause_menu: bool = false


## ProcessDPadRepeat (src/home/dpad_repeat.asm): a d-pad direction held 16 loops counts as pressed
## again, then every 8.
func process_dpad_repeat() -> void:
	var held: int = sim.wJoypadDown & WarioRam.PAD_CTRL_PAD
	var counter: int = r3(W_DPAD_REPEAT_COUNTER)
	if counter == 0 or (sim.wJoypadPressed & WarioRam.PAD_CTRL_PAD) != 0 or held == 0:
		w3(W_DPAD_REPEAT_COUNTER, 0x10)
		return
	w3(W_DPAD_REPEAT_COUNTER, counter - 1)
	if counter - 1 != 0:
		return
	sim.wJoypadPressed |= held
	w3(W_DPAD_REPEAT_COUNTER, 0x08)


## ExecuteMainPowerUpActionHelp: the demo of wActionHelpPowerUp.
func execute_main_power_up_action_help() -> void:
	match r3(W_ACTION_HELP_POWER_UP):
		NO_POWER_UP:
			no_power_up_action_help()
		LEAD_OVERALLS:
			lead_overalls_action_help()
		SWIMMING_FLIPPERS:
			swimming_flippers_action_help()
		HEAD_SMASH_HELMET:
			head_smash_helmet_action_help()
		GRAB_GLOVE:
			grab_glove_action_help()
		GARLIC:
			garlic_action_help()
		SUPER_JUMP_SLAM_OVERALLS:
			super_jump_slam_overalls_action_help()
		HIGH_JUMP_BOOTS:
			high_jump_boots_action_help()
		PRINCE_FROGS_GLOVES:
			prince_frogs_gloves_action_help()
		SUPER_GRAB_GLOVES:
			super_grab_glove_action_help()
		_:
			_note("ExecuteMainPowerUpActionHelp power-up %d" % r3(W_ACTION_HELP_POWER_UP))


## ExecuteSpecialPowerUpActionHelp: the owl's, the rail's, or the vampire's.
func execute_special_power_up_action_help() -> void:
	match r3(W_ACTION_HELP_POWER_UP):
		POWER_UP_OWL:
			owl_action_help()
		POWER_UP_RAIL:
			rail_action_help()
		POWER_UP_VAMPIRE:
			vampire_action_help()
		_:
			_note("ExecuteSpecialPowerUpActionHelp power-up %d" % r3(W_ACTION_HELP_POWER_UP))
