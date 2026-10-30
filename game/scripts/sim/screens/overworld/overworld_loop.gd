class_name OverworldLoop
extends OverworldTreasures
## The map side's loop (SST_OVERWORLD_0B: Func_805d7, Func_80e89, src/engine/overworld/bank20.asm),
## translated (WL3-052): the d-pad's repeat, the animations, the bars (the top bar: UpdateTopBar, its
## buttons, and the Day/Night Spell; the bottom bar: the Magnifying Glass's treasures), the level name's
## fade out, then w2d013's states:
## Wario set at his level (0), day or night switched (1), the level's treasures (2), its name faded in
## (3, 4), waiting at the level (5: A enters it, B shows the arrows, a d-pad way leaves), walking a
## path (6, 7), walking off the side (8, 9), the Temple's next-treasure hint (10); the compass drawn.
## HandleOverworld's level selection follows the loop (SelectLevel, bank $01).

const W_DPAD_REPEAT_COUNTER: int = 0xD502  # WRAMX bank 3 (GFX RAM)
const W2D014: int = 0xD014
const W_OW_BARS_STATE_COUNTER: int = 0xD051
const W_IS_COLLECTION_OPEN: int = 0xD07B
const TOP_BAR_NEXT_LEVEL_INDICES: int = 0x63F8  # UpdateTopBar.Indices: by side, the levels left and right
const OWBARS_NONE: int = 0x00
const OWBARS_START_CLOSE_BOT: int = 0x01
const OWBARS_HANDLE_CLOSE_BOT: int = 0x02
const OWBARS_OPEN_TOP: int = 0x03
const OWBARS_CLOSE_TOP: int = 0x05
const OWBARS_EVENT: int = 0x06
const OWBARS_COLLECTION: int = 0x07
const OWBARS_NEXT_MAP: int = 0x08
const OWBARS_DAY_NIGHT: int = 0x09
const OWBARS_DAY_NIGHT_DELAY: int = 0x0A
const OWBARS_DAY_NIGHT_TRANSITION: int = 0x0B
const SST_OVERWORLD_COLLECTION: int = 0x0C
const W_BOTTOM_BAR_STATE: int = 0xD092
const W_MAGNIFYING_GLASS_COUNTER: int = 0xD093
const W2D096: int = 0xD096
const W2D06F: int = 0xD06F
const W2D070: int = 0xD070
const W2D0A0: int = 0xD0A0  # the path's way: bit 0 x the major axis, bits 1 and 2 y and x going back
const W2D0A1: int = 0xD0A1  # steps left on the major axis
const W2D0A2: int = 0xD0A2
const W2D0A3: int = 0xD0A3
const W2D0A4: int = 0xD0A4
const W2D0A5: int = 0xD0A5  # y step, then x step (0xD0A6)
const W_OW_Y_DISTANCE: int = 0xD0A7
const W_OW_X_DISTANCE: int = 0xD0A8
const W2D0C0: int = 0xD0C0
const W2D0E2: int = 0xD0E2
const W2D0E5: int = 0xD0E5
const W2D88E: int = 0xD88E
const W2D889: int = 0xD889
const W2D800: int = 0xD800
const W2D160: int = 0xD160  # four more trail objects
const W2D880: int = 0xD880  # the arrow being stepped (9 bytes), w2d889 the paths, w2d88b its number
const W2D88B: int = 0xD88B
const FUNC_81714_FRAMESETS: int = 0x5783
const OW_LEVEL_PATHS: int = 0x423E
const OW_EXIT_PATHS: int = 0x431E
const LEVEL_TREASURE_REQUIREMENTS: int = 0x4EBA  # bank $01
const W_LEVEL: int = 0xCA06
const PAD_CTRL_PAD: int = 0xF0
const PAD_A: int = 0x01
const PAD_SELECT: int = 0x04
const PAD_START: int = 0x08
const OWWARIO_ARROWS: int = 5
const BOTBAR_OPENED: int = 1
const BOTBAR_CLOSING: int = 2
const BOTBAR_OPENING: int = 3
const ST_LEVEL: int = 0x02
const ST_GOLF_BUILDING: int = 0x0A
const SST_OVERWORLD_08: int = 0x08
const SST_OVERWORLD_1A: int = 0x1A
const SST_OVERWORLD_1E: int = 0x1E
const SST_OVERWORLD_BEST_TIMES: int = 0x16
const LEVEL_GOLF_BUILDING: int = 0x1A
const THE_TEMPLE: int = 0xC8
const GOLF_BUILDING: int = 0xFF
const EVENT_GOLD_MUSIC_BOX: int = 0x25
const MODE_GAME_CLEARED_F: int = 0x01


## Func_805d7 (SST_OVERWORLD_0B): Func_80e89, the compass, the virtual OAM's unused entries cleared.
func map_side_loop() -> void:
	func_80e89()
	load_ow_sprite_with_scroll(W_COMPASS_OBJ, OAM_AA580, OBJECTS_BANK)  # LoadCompassSprite
	clear_unused_virtual_oam()


## Func_80e89: the d-pad's repeat, the animations, the top bar (with a bar open, only the objects and
## Wario drawn), the bottom bar, the name's fade out, w2d014 counted, then w2d013's state.
func func_80e89() -> void:
	process_dpad_repeat()
	update_map_side_ow_animations()
	update_common_ow_animations()
	update_top_bar()
	if r2(W_OW_BARS_STATE) != 0:
		func_81055()
		return
	handle_bottom_bar()
	draw_bottom_bar()
	func_852e5()
	w2(W2D014, r2(W2D014) + 1)
	match r2(W2D013):
		0x00:
			_func_80ee7()
		0x01:
			_func_80f0d()
		0x02:
			_func_80f3c()
		0x03:
			_func_80fb8()
		0x04:
			_func_80fd6()
		0x05:
			_func_80ff7()
		0x06:
			_func_810bb()
		0x07:
			_func_8115c()
		0x08:
			_func_811cf()
		0x09:
			_func_81200()
		0x0A:
			_func_81346()
		_:
			_note("Func_80e89 state $%02x (past its table)" % r2(W2D013))


## ProcessDPadRepeat (src/home/dpad_repeat.asm): a d-pad direction held 16 loops counts as pressed
## again, then every 8 (wDPadRepeatCounter, GFX RAM).
func process_dpad_repeat() -> void:
	var held: int = sim.wJoypadDown & PAD_CTRL_PAD
	var counter: int = r3(W_DPAD_REPEAT_COUNTER)
	if counter == 0 or (sim.wJoypadPressed & PAD_CTRL_PAD) != 0 or held == 0:
		w3(W_DPAD_REPEAT_COUNTER, 0x10)
		return
	w3(W_DPAD_REPEAT_COUNTER, counter - 1)
	if counter - 1 != 0:
		return
	sim.wJoypadPressed |= held
	w3(W_DPAD_REPEAT_COUNTER, 0x08)


## Func_81055: the scene objects and Wario updated and drawn.
func func_81055() -> void:
	func_b4a3d()
	func_82041()
	func_b4aa9()


## UpdateTopBar: wOWBarsStateCounter counts; then by wOWBarsState (with the bars closed, nothing): the
## bottom bar closed (1, 2) before the top bar's buttons are set up, the top bar opened (3: the BG
## scrolled up 2 lines a loop to $ec), its input (4), closed (5, back to $04, the map side's palettes
## for objects 4 to 7 again), a pressed button's wait (30 loops or A: the cutscene 6, the collection 7,
## the next or previous map 8), and the Day/Night Spell (9 to $0b).
func update_top_bar() -> void:
	w2(W_OW_BARS_STATE_COUNTER, r2(W_OW_BARS_STATE_COUNTER) + 1)
	match r2(W_OW_BARS_STATE):
		OWBARS_NONE:
			return
		OWBARS_START_CLOSE_BOT:
			draw_bottom_bar()
			w2(W_BOTTOM_BAR_ACTION, BOTBAR_CLOSING)
			w2(W_BOTTOM_BAR_STATE, 0)
			w2(W_MAGNIFYING_GLASS_COUNTER, 0)
			w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
		OWBARS_HANDLE_CLOSE_BOT:
			handle_bottom_bar()
			draw_bottom_bar()
			if r2(W_BOTTOM_BAR_ACTION) != 0:
				return
			w2(W_TOP_BAR_SELECTION, TOPBAR_COLLECTION)  # (a sound, not ported)
			init_top_bar_buttons()
			apply_top_bar_button_attributes()
			_set_top_bar_obj_pal_config()
			w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
		OWBARS_OPEN_TOP:
			sim.wSCY = byte(sim.wSCY - 2)
			if sim.wSCY == 0xEC:
				w2(W2D02C, wTransitionParam)
				w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
			draw_top_bar()
		OWBARS_INPUT_TOP:
			if not handle_top_bar_selection() and not handle_top_bar_dpad() \
					and (sim.wJoypadPressed & (PAD_B | PAD_SELECT)) != 0:
				w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)  # (a sound, not ported)
			draw_top_bar()
		OWBARS_CLOSE_TOP:
			sim.wSCY = byte(sim.wSCY + 2)
			if sim.wSCY == 0x04:
				w2(W2D013, 0)
				w2(W_OW_BARS_STATE, OWBARS_NONE)
				copy_rom(0x21, PALS_84900_OBJ_4 + r2(W_CUR_MAP_SIDE) * 8 * 8, W_TEMP_PALS_2 + 4 * 8, 4 * 8)
				_set_top_bar_obj_pal_config()
			draw_top_bar()
		OWBARS_EVENT:
			if _top_bar_wait_over():
				wTransitionParam = r2(W_STORED_TRANSITION_PARAM)
				sim.wSubState = 0
				_top_bar_input_again()
			draw_top_bar()
		OWBARS_COLLECTION:
			if _top_bar_wait_over():
				_top_bar_input_again()
				sim.wSubState = SST_OVERWORLD_COLLECTION
			draw_top_bar()
		OWBARS_NEXT_MAP:
			if _top_bar_wait_over():
				_top_bar_input_again()
				var way: int = -1 if r2(W_OW_UI_OBJ_1 + SCENE_OBJ_STATE) == 0x0A else 1
				var side: int = (r2(W_NEXT_MAP_SIDE) + way) & 0x03
				w2(W_NEXT_MAP_SIDE, side)
				# .GetNextLevelIndex: the side's level on its left, or on its right going back
				var level: int = rb(MAP_BANK, TOP_BAR_NEXT_LEVEL_INDICES + side * 2 + (0 if way == 1 else 1))
				w2(W_MAP_SIDE_LEVEL_ID, level)
				w2(W2D068, level)
				w2(W2D013, 0)  # (the music stopped, not ported)
				w2(W2D014, 0)
				sim.wSubState = SST_OVERWORLD_08
			draw_top_bar()
		OWBARS_DAY_NIGHT:
			draw_top_bar()
			var frame: int = r2(W_OW_UI_OBJ_1 + SCENE_OBJ_FRAME)
			if frame != 0x04 and frame != 0x06:
				return
			do_day_night_spell()
			load_top_bar_button_attributes()
			apply_top_bar_button_attributes()
			w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
		OWBARS_DAY_NIGHT_DELAY:
			var state: int = r2(W_OW_UI_OBJ_1 + SCENE_OBJ_STATE)
			if state == 0x05 or state == 0x07:
				w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
			draw_top_bar()
		OWBARS_DAY_NIGHT_TRANSITION:
			day_night_transition()
			if r2(W_OW_PAL_TRANSITION_STATE) == 0:
				vblank_func = VBLANK_OVERWORLD  # VBlank_Overworld installs it again (between di and ei)
				w2(W_OW_BARS_STATE, OWBARS_INPUT_TOP)
			draw_top_bar()
		var state:
			_note("UpdateTopBar state %d (past its table)" % state)


## A pressed button's wait: 30 loops of wOWBarsStateCounter, or A.
func _top_bar_wait_over() -> bool:
	return (sim.wJoypadPressed & PAD_A) != 0 or r2(W_OW_BARS_STATE_COUNTER) >= 30


func _top_bar_input_again() -> void:
	w2(W_OW_BARS_STATE_COUNTER, 0)
	w2(W_OW_BARS_STATE, OWBARS_INPUT_TOP)


## wPalConfig1: wTempPals2's palettes 4 to 7 to the OBJ palettes at the next V-Blank.
func _set_top_bar_obj_pal_config() -> void:
	var source: int = W_TEMP_PALS_2 + 4 * 8
	w2(W_PAL_CONFIG_1, LOW_R_OBPI)
	w2(W_PAL_CONFIG_1 + 1, 0x80 | (4 * 8))  # OBPI_AUTOINC | palette 4
	w2(W_PAL_CONFIG_1 + 2, 4)
	w2(W_PAL_CONFIG_1 + 3, source >> 8)
	w2(W_PAL_CONFIG_1 + 4, source & 0xFF)


## HandleTopBarSelection: A runs the selected button: the Day/Night Spell, the cutscene again (when
## there is one), the collection, the next or the previous map (with the NEXT MAP sign); the button
## shown pressed. Whether a button ran.
func handle_top_bar_selection() -> bool:
	if (sim.wJoypadPressed & PAD_A) == 0:
		return false
	var selection: int = r2(W_TOP_BAR_SELECTION)
	if (selection & TOPBAR_DAY_NIGHT) != 0:
		_press_top_bar_button(TOP_BAR_DAY_NIGHT_AT)
		w2(W_OW_BARS_STATE, OWBARS_DAY_NIGHT)
	elif (selection & TOPBAR_CUTSCENE) != 0:
		if r2(W_STORED_TRANSITION_PARAM) == 0:
			return false
		_press_top_bar_button(TOP_BAR_CUTSCENE_AT)
		w2(W_OW_BARS_STATE, OWBARS_EVENT)
		w2(W_OW_BARS_STATE_COUNTER, 0)
	elif (selection & TOPBAR_COLLECTION) != 0:
		_press_top_bar_button(TOP_BAR_COLLECTION_AT)
		w2(W_OW_BARS_STATE, OWBARS_COLLECTION)
		w2(W_OW_BARS_STATE_COUNTER, 0)
		w2(W_IS_COLLECTION_OPEN, 0)
	elif (selection & (TOPBAR_NEXT_MAP | TOPBAR_PREV_MAP)) != 0:
		_advance_ui_obj(W_OW_UI_OBJ_1)  # .ShowPressedButton
		_advance_ui_obj(W_OW_UI_OBJ_2)  # .ShowNextMapIndicatorFlash
		w2(W_OW_BARS_STATE, OWBARS_NEXT_MAP)
		w2(W_OW_BARS_STATE_COUNTER, 0)
	else:
		return false
	return true  # (a sound, not ported)


## .ShowPressedButton and .ApplyPressedButtonAttrs: the selected button's object a state on, the
## button at `at` drawn pressed.
func _press_top_bar_button(at: int) -> void:
	_advance_ui_obj(W_OW_UI_OBJ_1)
	write_top_bar_button(TOP_BAR_PRESSED, at)
	apply_top_bar_button_attributes()


## .adv_obj_state: the UI object's state one on, its frameset offset and duration cleared.
func _advance_ui_obj(obj: int) -> void:
	_restart_ui_obj(obj, r2(obj + SCENE_OBJ_STATE) + 1)


## HandleTopBarDPad: right or left selects the next selectable button that way, shown with its
## attributes. Whether the input was taken: right past the last button (the Day/Night Spell's bit
## rotated out) takes it too; left past the previous map does not.
func handle_top_bar_dpad() -> bool:
	var selection: int = r2(W_TOP_BAR_SELECTION)
	var selectable: int = r2(W_TOP_BAR_SELECTABLE_BUTTONS)
	if (sim.wJoypadPressed & PAD_RIGHT) != 0:
		while true:
			var out: bool = (selection & 0x01) != 0
			selection = ((selection >> 1) | ((selection & 0x01) << 7)) & 0xFF  # rrc b
			if out:
				return true
			if (selectable & selection) != 0:
				break
	elif (sim.wJoypadPressed & PAD_LEFT) != 0:
		while true:
			selection = (selection << 1) & 0xFF  # sla b
			if (selection & (TOPBAR_PREV_MAP << 1)) != 0:
				return false
			if (selectable & selection) != 0:
				break
	else:
		return false
	w2(W_TOP_BAR_SELECTION, selection)  # .got_selection (a sound, not ported)
	show_top_bar_selected_button()
	load_top_bar_button_attributes()
	apply_top_bar_button_attributes()
	return true


## DoDayNightSpell (day_night.asm): wDayNight's bit 4 switched (SwitchDayNight), on the East side only
## with the Sun Medallion (else cleared).
func do_day_night_spell() -> void:
	if r2(W_CUR_MAP_SIDE) == EAST and r2(W_GOT_SUN_MEDALLION) == 0:
		w0(W_DAY_NIGHT, r0(W_DAY_NIGHT) & ~0x10)
		return
	w0(W_DAY_NIGHT, r0(W_DAY_NIGHT) ^ 0x10)


# --- the bottom bar (HandleBottomBar) ---

## HandleBottomBar: while Wario walks it closes; at a level (w2d013 5, not the Temple or the junction)
## B held 10 loops with the Magnifying Glass opens it (the window up, the treasures shown one by one),
## releasing B closes it.
func handle_bottom_bar() -> void:
	if r2(W2D068) != r2(W_MAP_SIDE_LEVEL_ID):
		w2(W2D096, 0)
		var action: int = r2(W_BOTTOM_BAR_ACTION)
		if action == 0:
			return
		if action == BOTBAR_CLOSING:
			_close_bottom_bar()
			return
		w2(W_BOTTOM_BAR_ACTION, BOTBAR_CLOSING)
		w2(W_BOTTOM_BAR_STATE, 0)
		w2(W_MAGNIFYING_GLASS_COUNTER, 0)
		return
	match r2(W_BOTTOM_BAR_ACTION):
		BOTBAR_CLOSING:
			_close_bottom_bar()
			return
		BOTBAR_OPENING:
			_open_bottom_bar()
			return
	if (r2(W_OW_LEVEL) * 2) & 0xFF == 0 or r2(W2D013) != 0x05:  # .CheckBottomBarPossible
		return
	match r2(W_BOTTOM_BAR_ACTION):
		BOTBAR_OPENED:
			if (sim.wJoypadDown & PAD_B) == 0:
				_start_closing_bottom_bar()
		0:
			if r2(W_HAS_MAGNIFYING_GLASS) == 0:
				return
			if (sim.wJoypadDown & PAD_B) == 0:
				w2(W_MAGNIFYING_GLASS_COUNTER, 0)
				return
			w2(W_MAGNIFYING_GLASS_COUNTER, r2(W_MAGNIFYING_GLASS_COUNTER) + 1)
			if r2(W_MAGNIFYING_GLASS_COUNTER) < 10:
				return
			w2(W_BOTTOM_BAR_ACTION, BOTBAR_OPENING)
			w2(W_BOTTOM_BAR_STATE, 0)


func _start_closing_bottom_bar() -> void:
	w2(W_BOTTOM_BAR_FLAGS, r2(W_BOTTOM_BAR_FLAGS) & ~0x10)
	w2(W_BOTTOM_BAR_ACTION, BOTBAR_CLOSING)
	w2(W_BOTTOM_BAR_STATE, 0)


## HandleBottomBar.OpenBottomBar: while B is held, by wBottomBarState.
func _open_bottom_bar() -> void:
	if (sim.wJoypadDown & PAD_B) == 0:
		_start_closing_bottom_bar()
		return
	match r2(W_BOTTOM_BAR_STATE):
		0:  # .InitBar
			w2(W_BOTTOM_BAR_FLAGS, r2(W_BOTTOM_BAR_FLAGS) | 0x10)
			w2(W_HDMA, 0)
			w2(W2D0B5, 0)
			w2(W_BOTTOM_BAR_STATE, r2(W_BOTTOM_BAR_STATE) + 1)
		1:  # .OpenWindow
			if r2(W_WY) > 0x78:
				w2(W_WY, r2(W_WY) - 6)
				return
			w2(W_WY, 0x78)
			w2(W_MAGNIFYING_GLASS_COUNTER, 0)
			w2(W_BOTTOM_BAR_STATE, r2(W_BOTTOM_BAR_STATE) + 1)
		2:  # .SetVisibleTreasures
			w2(W_MAGNIFYING_GLASS_COUNTER, r2(W_MAGNIFYING_GLASS_COUNTER) + 1)
			if r2(W_MAGNIFYING_GLASS_COUNTER) < 0x03:
				return
			w2(W_MAGNIFYING_GLASS_COUNTER, 0)
			_note("HandleBottomBar.SetVisibleTreasures (reads rDIV: not ported)")
		3:  # .SetBottomBarAsOpen
			w2(W_BOTTOM_BAR_ACTION, BOTBAR_OPENED)
			w2(W_BOTTOM_BAR_STATE, 0)
			if (r2(W_BOTTOM_BAR_FLAGS) & 0x40) != 0:
				w2(W_BOTTOM_BAR_FLAGS, r2(W_BOTTOM_BAR_FLAGS) | 0x80)
		_:
			_note("HandleBottomBar.OpenBottomBar state %d (past its table)" % r2(W_BOTTOM_BAR_STATE))


## HandleBottomBar.CloseBottomBar: the window down, then the bar's flags (bit 6 kept), the 8-coin's
## animation and the bar's state cleared.
func _close_bottom_bar() -> void:
	match r2(W_BOTTOM_BAR_STATE):
		0:  # .CloseWindow
			if r2(W_WY) < SCREEN_HEIGHT_PX:
				w2(W_WY, r2(W_WY) + 6)
				return
			w2(W_WY, SCREEN_HEIGHT_PX)
			w2(W_BOTTOM_BAR_STATE, r2(W_BOTTOM_BAR_STATE) + 1)
		1:  # .DeinitBar
			w2(W_BOTTOM_BAR_FLAGS, r2(W_BOTTOM_BAR_FLAGS) & 0x40)
			w2(W_COMPASS_OBJ + SCENE_OBJ_STATE, 0)
			w2(W_COMPASS_OBJ + SCENE_OBJ_STATE + 1, 0)
			w2(W_BOTTOM_BAR_ACTION, 0)
			w2(W_BOTTOM_BAR_STATE, 0)
			w2(W_MAGNIFYING_GLASS_COUNTER, 0)
		_:
			_note("HandleBottomBar.CloseBottomBar state %d (past its table)" % r2(W_BOTTOM_BAR_STATE))


# --- w2d013's states ---

## Func_80ee7 (0): Wario at his level, the d-pad ways from it, the name's palette steps cleared.
func _func_80ee7() -> void:
	func_8212c()
	get_ow_allowed_dpad_input()
	w2(W_LEVEL_2, r2(W_MAP_SIDE_LEVEL_ID))
	w2(W2D068, r2(W_MAP_SIDE_LEVEL_ID))
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W2D0E0, 0)
	w2(W_OW_PAL_TRANSITION_STATE, 0)
	func_81055()
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## Func_80f0d (1): with wDayNight bit 7 (the spell cast) the day and night transition until it ends
## (VBlank_Overworld back), else the music (not ported) and the next state.
func _func_80f0d() -> void:
	if (r0(W_DAY_NIGHT) & 0x80) == 0:
		func_81055()  # after PlayOverworldMusic
		w2(W2D013, r2(W2D013) + 1)
		return
	day_night_transition()
	func_81055()
	if r2(W_OW_PAL_TRANSITION_STATE) == 0:
		vblank_func = VBLANK_OVERWORLD


## Func_80f3c (2): at an exit, Wario walks in (to the right from the left exit); at a level, its
## treasures (Func_9aab5) and, with a d-pad way held that he may take, on at once; else wait.
func _func_80f3c() -> void:
	w2(W_MAGNIFYING_GLASS_COUNTER, 0)
	func_8212c()
	get_ow_allowed_dpad_input()
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	if level == OW_EXIT_RIGHT or level == OW_EXIT_LEFT:
		w2(W_LEVEL_ARROW_DIRECTIONS_1, PAD_LEFT if level == OW_EXIT_RIGHT else PAD_RIGHT)
		func_820e6()
		func_81055()
		w2(W2D014, 0)
		w2(W2D013, 0x06)
		return
	load_map_level_from_level_index()
	func_9aab5()
	w2(W2D014, 0)
	var directions: int = r2(W_OW_ALLOWED_D_PAD_INPUT) & _directional_input(sim.wJoypadDown)
	if directions != 0:
		w2(W2D013, 0x05)
		_func_81034(directions)
		return
	func_81055()
	w2(W_LEVEL_ARROW_DIRECTIONS_1, 0)
	w2(W2D10E, 0)
	w2(W2D013, r2(W2D013) + 1)


## .GetDirectionalInput, Func_810a9: the d-pad bits of `pad`, up and down over left and right.
static func _directional_input(pad: int) -> int:
	var directions: int = pad & PAD_CTRL_PAD
	if (directions & (PAD_UP | PAD_DOWN)) != 0:
		return directions & (PAD_UP | PAD_DOWN)
	return directions


## Func_80fb8 (3): once the name is gone (w2d0e0 0), the level's name loaded (HDMA).
func _func_80fb8() -> void:
	func_81055()
	if r2(W2D0E0) != 0:
		return
	load_level_name_if_valid()
	w2(W2D013, r2(W2D013) + 1)


## Func_80fd6 (4): the name faded in (not at an exit).
func _func_80fd6() -> void:
	func_81055()
	if r2(W_MAP_SIDE_LEVEL_ID) < OW_EXITS and fade_in_level_name():
		return
	w2(W2D013, r2(W2D013) + 1)


## Func_80ff7 (5): at the level: A enters it (Func_81240); Select opens the top bar; B the arrows
## (Func_81477); Up at the Temple; Start the best times (Time Attack); a d-pad way he may take, on.
func _func_80ff7() -> void:
	if _func_81240():
		func_81055()
		return
	if r2(W_OW_PAL_TRANSITION_STATE) != 0:
		func_81055()
		return
	if (sim.wJoypadDown & PAD_B) == 0 and (sim.wJoypadPressed & PAD_SELECT) != 0:
		w2(W_OW_BARS_STATE, r2(W_OW_BARS_STATE) + 1)
		func_81055()
		return
	_func_81477()
	if r2(W2D0E3) != 0 or _func_81077():
		func_81055()
		return
	_func_80de0()  # never sets carry: the loop goes on
	var directions: int = r2(W_OW_ALLOWED_D_PAD_INPUT) & _directional_input(sim.wJoypadPressed)
	if directions == 0:
		func_81055()
		return
	_func_81034(directions)


## Func_81034: Wario sets off (wLevelArrowDirections1) toward the level that way (Func_820e6), the
## name faded out (w2d0e0 3), the next state.
func _func_81034(directions: int) -> void:
	w2(W_LEVEL_ARROW_DIRECTIONS_1, directions)
	func_820e6()
	w2(W_LEVEL_2, r2(W2D068))
	w2(W2D0E0, 0x03)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	func_81055()
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## Func_810bb (6): the path's end (the next level's coordinates and Wario's offsets, w2d06f and
## w2d070), its first leg (Func_810fc), its distances (Func_821a1).
func _func_810bb() -> void:
	w2(W_OW_Y_COORD_2, r2(W_OW_Y_COORD_1))
	w2(W_OW_X_COORD_2, r2(W_OW_X_COORD_1))
	var at: int = get_map_level_coords(r2(W2D068))
	w2(W2D06F, rb(MAP_BANK, at + 2) + rb(MAP_BANK, at))
	w2(W2D070, rb(MAP_BANK, at + 3) + rb(MAP_BANK, at + 1))
	func_810fc()
	func_821a1()
	func_81055()
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## Func_8115c (7): a step along the leg (two after the d-pad is held 6 loops: w2d10e bit 7), Wario
## there; at the leg's end the next leg, or at the path's end the level (state 2), or an exit (8).
func _func_8115c() -> void:
	func_82208()
	var held: int = r2(W2D10E)
	if (held & 0x80) == 0 and (sim.wJoypadDown & PAD_CTRL_PAD) != 0:
		w2(W2D10E, held + 1)
		if r2(W2D10E) >= 0x06:
			w2(W2D10E, r2(W2D10E) | 0x80)
	if (r2(W2D10E) & 0x80) != 0:
		func_82208()
	w2(W2D100, r2(W_OW_Y_COORD_1))
	w2(W2D101, r2(W_OW_X_COORD_1))
	if r2(W2D0A1) == 0:
		if func_810fc() != 0xFF:
			func_821a1()
			_func_81142()
		else:
			w2(W_MAP_SIDE_LEVEL_ID, r2(W2D068))
			if r2(W2D068) < OW_EXITS:
				w2(W2D013, 0x02)
			else:
				w2(W2D014, 0)  # (the music stopped and a sound, not ported)
				w2(W2D013, r2(W2D013) + 1)
	func_81055()


## Func_81142: Wario faces the leg's way (w2d0a0: x or y, back or forth).
func _func_81142() -> void:
	var way: int = r2(W2D0A0)
	var direction: int
	if (way & 0x01) != 0:
		direction = PAD_LEFT if (way & 0x04) != 0 else PAD_RIGHT
	else:
		direction = PAD_UP if (way & 0x02) != 0 else PAD_DOWN
	w2(W_LEVEL_ARROW_DIRECTIONS_1, direction)


## Func_811cf (8): Wario walks off the side's edge from w2d014's second loop. Its `ld [hl], a` meant to
## clear w2d014 writes to the MBC instead (hl is still the jumptable's target, Func_811cf's own
## address $51cf): w2d014 keeps counting.
func _func_811cf() -> void:
	if r2(W2D014) >= 0x02:
		var level: int = r2(W_MAP_SIDE_LEVEL_ID)
		if level != OW_EXIT_RIGHT and level != OW_EXIT_LEFT:
			_note("Func_811cf off an exit (debug_nop: hangs)")
			return
		w2(W2D101, r2(W2D101) + (1 if level == OW_EXIT_RIGHT else -1))
		if r2(W2D101) == (0xA8 if level == OW_EXIT_RIGHT else 0xF0):
			w2(W2D013, r2(W2D013) + 1)
	func_81055()


## Func_81200 (9): the next map side (by the exit), Wario at its other exit, and its fade (SST 8), or
## between some sides SST_OVERWORLD_1E.
func _func_81200() -> void:
	func_81055()
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	if level != OW_EXIT_RIGHT and level != OW_EXIT_LEFT:
		_note("Func_81200 off an exit (debug_nop: hangs)")
		return
	var step: int = 1 if level == OW_EXIT_RIGHT else 0xFF
	w2(W_NEXT_MAP_SIDE, (r2(W_NEXT_MAP_SIDE) + step) & 0x03)
	w2(W_MAP_SIDE_LEVEL_ID, r2(W_MAP_SIDE_LEVEL_ID) + step)
	w2(W2D068, r2(W_MAP_SIDE_LEVEL_ID))
	var side: int = r2(W_NEXT_MAP_SIDE)
	if (side & 0x02) == 0 and (byte(side + step) & 0x02) != 0:
		sim.wSubState = SST_OVERWORLD_1E
	else:
		sim.wSubState = SST_OVERWORLD_08


## Func_81240: A at a level (not during the transition, not at the junction): the level (wOWLevel);
## the Temple's scene (SST_OVERWORLD_1A), or the level (wState ST_LEVEL, wSubState 0). True (carry)
## when taken.
func _func_81240() -> bool:
	if r2(W_OW_PAL_TRANSITION_STATE) != 0 or r2(W_OW_LEVEL) == 0x80:
		return false
	if (sim.wJoypadPressed & PAD_A) == 0:
		return false
	load_map_level_from_level_index()
	if r2(W_OW_LEVEL) == 0:
		sim.wSubState = SST_OVERWORLD_1A  # (a sound, not ported)
		return true
	sim.wSubState = 0
	sim.wState = byte(sim.wState + 1)  # ST_LEVEL
	return true


## Func_81077: Up at the Temple (while a treasure is left, or the game not cleared): the next
## treasure's hint (state $0a), Wario facing up. True (carry) when taken.
func _func_81077() -> bool:
	if (r2(W_NEXT_MAP_SIDE) | r2(W_MAP_SIDE_LEVEL_ID)) != 0:
		return false
	if (sim.wJoypadPressed & PAD_UP) == 0:
		return false
	if r2(W_NEXT_TREASURE) == TREASURES_END and (r0(W_GAME_MODE_FLAGS) & MODE_GAME_CLEARED_F) != 0:
		return false
	fill(W2D0C0, 0x10, 0)  # Func_3c76
	set_ow_wario_oam(OWWARIO_UP)  # (a sound, not ported)
	w2(W2D013, 0x0A)
	return true


## Func_80de0: Start in Time Attack: the best times (SST_OVERWORLD_BEST_TIMES); it returns without
## carry either way.
func _func_80de0() -> void:
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) == 0:
		return
	if (sim.wJoypadPressed & PAD_START) == 0:
		return
	sim.wSubState = SST_OVERWORLD_BEST_TIMES


## LoadMapLevelFromLevelIndex: wOWLevel from wNextMapSide's wMapSideLevelID (MapSideInitialLevels;
## North's junction and exits $80).
func load_map_level_from_level_index() -> void:
	var side: int = r2(W_NEXT_MAP_SIDE)
	if side == NORTH and r2(W_MAP_SIDE_LEVEL_ID) >= OWNORTH_JUNCTION:
		w2(W_OW_LEVEL, 0x80)
		return
	w2(W_OW_LEVEL, r2(W_MAP_SIDE_LEVEL_ID) + rb(MAP_BANK, MAP_SIDE_INITIAL_LEVELS + side))


## GetOWAllowedDPadInput: the ways from Wario's level (w2d069, w2d06a): where an arrow tile (1 or 2
## in VRAM bank 1) is next to it; the junction's right, up, and down.
func get_ow_allowed_dpad_input() -> void:
	if r2(W_MAP_SIDE_LEVEL_ID) == OWNORTH_JUNCTION:
		w2(W_OW_ALLOWED_D_PAD_INPUT, PAD_RIGHT | PAD_UP | PAD_DOWN)
		return
	var at: int = get_ow_coord_in_tilemap(W2D069)
	var allowed: int = 0
	for pair: Array in [[1, PAD_RIGHT], [-1, PAD_LEFT], [-TILEMAP_WIDTH, PAD_UP], [TILEMAP_WIDTH, PAD_DOWN]]:
		var tile: int = rd(at + int(pair[0]))
		if (tile == 0x02 or tile == 0x01) and (rd(at + int(pair[0]) - 0x300) & BG_BANK1) != 0:
			allowed |= int(pair[1])
	w2(W_OW_ALLOWED_D_PAD_INPUT, allowed)


## Func_820e6: from the side's paths (Func_82111), the level the way wLevelArrowDirections1 leads to
## (w2d068) and the path's shape (wOWPathShape).
func func_820e6() -> void:
	var at: int = _func_82111()
	var directions: int = r2(W_LEVEL_ARROW_DIRECTIONS_1)
	if (directions & PAD_RIGHT) == 0:
		at += 1
		if (directions & PAD_LEFT) == 0:
			at += 1
			if (directions & PAD_UP) == 0:
				at += 1
				if (directions & PAD_DOWN) == 0:
					_note("Func_820e6 without a direction (debug_nop: hangs)")
					return
	w2(W2D068, rb(MAP_BANK, at))
	w2(W_OW_PATH_SHAPE, rb(MAP_BANK, at + 4))
	w2(W2D072, 0)


## Func_82111: wMapSideLevelID's paths (OWLevelPaths, or OWExitPaths for the exits) on wNextMapSide:
## the levels right, left, up, down, then the paths' shapes.
func _func_82111() -> int:
	var level: int = r2(W_MAP_SIDE_LEVEL_ID)
	var table: int = OW_LEVEL_PATHS
	if level >= OW_EXITS:
		level -= OW_EXIT_RIGHT
		table = OW_EXIT_PATHS
	return cth_word_from_ath_table(MAP_BANK, table, r2(W_NEXT_MAP_SIDE), (level * 4) & 0xFF)


## Func_810fc: the leg of the path wOWPathShape gives toward (w2d06f, w2d070) as wOWCoords2, the shape
## of the rest; PATH_NONE ends it ($ff in w2d072). Returns its a ($ff at the end).
func func_810fc() -> int:
	match r2(W_OW_PATH_SHAPE):
		0:  # .PathNone
			w2(W2D072, 0xFF)
			return 0xFF
		1:  # .PathBeeline
			w2(W_OW_Y_COORD_2, r2(W2D06F))
			w2(W_OW_X_COORD_2, r2(W2D070))
			w2(W_OW_PATH_SHAPE, 0)
			return 0
		2:  # .PathYThenX
			w2(W_OW_Y_COORD_2, r2(W2D06F))
			w2(W_OW_PATH_SHAPE, 1)
			return 1
		3:  # .PathXThenY
			w2(W_OW_X_COORD_2, r2(W2D070))
			w2(W_OW_PATH_SHAPE, 1)
			return 1
		4:  # .PathSShape: x halfway first
			var x: int = r2(W_OW_X_COORD_1)
			var half: int = byte(r2(W2D070) - x)
			half = (half >> 1) | (half & 0x80)  # sra
			w2(W_OW_X_COORD_2, half + x)
			w2(W_OW_PATH_SHAPE, 2)
			return 2
	_note("Func_810fc path shape %d (past its table)" % r2(W_OW_PATH_SHAPE))
	return 0xFF


## Func_821a1: the leg's distances (wOWYDistance, wOWXDistance), which way (w2d0a0), the steps on the
## major axis (w2d0a1, w2d0a2), the minor one's (w2d0a3, w2d0a4), the steps' signs (w2d0a5, w2d0a6).
func func_821a1() -> void:
	w2(W2D0A0, 0)
	w2(W_OW_Y_DISTANCE, _distance(W_OW_Y_COORD_1, W_OW_Y_COORD_2, 0x02))
	w2(W_OW_X_DISTANCE, _distance(W_OW_X_COORD_1, W_OW_X_COORD_2, 0x04))
	var way: int = r2(W2D0A0)
	var major: int = r2(W_OW_Y_DISTANCE)
	var minor: int = r2(W_OW_X_DISTANCE)
	if major < minor:
		major = r2(W_OW_X_DISTANCE)
		minor = r2(W_OW_Y_DISTANCE)
		way |= 0x01
	w2(W2D0A1, major)
	w2(W2D0A2, major)
	w2(W2D0A3, minor)
	w2(W2D0A4, minor)
	w2(W2D0A0, way)
	w2(W2D0A5, 0xFF if (way & 0x02) != 0 else 0x01)
	w2(W2D0A5 + 1, 0xFF if (way & 0x04) != 0 else 0x01)


## Func_821a1.CalculateDistance: |[to] - [from]|, with `flag` set in w2d0a0 when going back.
func _distance(from: int, to: int, flag: int) -> int:
	var difference: int = r2(to) - r2(from)
	if difference >= 0:
		return difference
	w2(W2D0A0, r2(W2D0A0) | flag)
	return -difference


## Func_82208: a step of the leg: one on the major axis, and one on the minor when its accumulator
## (w2d0a3 plus w2d0a4) reaches the major distance.
func func_82208() -> void:
	if r2(W2D0A1) == 0:
		return
	w2(W2D0A1, r2(W2D0A1) - 1)
	var major: int = r2(W2D0A2)
	var sum: int = byte(r2(W2D0A4) + r2(W2D0A3))
	w2(W2D0A3, sum)
	var x_major: bool = (r2(W2D0A0) & 0x01) != 0
	if sum >= major:
		w2(W2D0A3, sum - major)
		_step_coord(not x_major)
	_step_coord(x_major)


func _step_coord(x: bool) -> void:
	var at: int = W_OW_X_COORD_1 if x else W_OW_Y_COORD_1
	w2(at, r2(at) + r2(W2D0A5 + (1 if x else 0)))


# --- the arrows (B held at a level: Func_81477) ---

## Func_81477: with B held (w2d0e2 counting) by w2d0e3: Wario's place kept, then after 10 loops the
## arrows shown (OWWARIO_ARROWS) and the paths traced (Func_814ec, Func_8150c); released, Wario back.
func _func_81477() -> void:
	if (sim.wJoypadDown & PAD_B) == 0:
		if r2(W2D0E3) == 0:
			return
		if r2(W2D106) != OWWARIO_DOWN:
			set_ow_wario_oam(OWWARIO_DOWN)
		w2(W_OW_Y_COORD_1, r2(W2D88E))
		w2(W2D100, r2(W2D88E))
		w2(W_OW_X_COORD_1, r2(W2D88E + 1))
		w2(W2D101, r2(W2D88E + 1))
		w2(W2D0E3, 0)
		return
	w2(W2D0E2, r2(W2D0E2) + 1)
	match r2(W2D0E3):
		0:  # Func_814b2
			w2(W2D88E, r2(W2D100))
			w2(W2D88E + 1, r2(W2D101))
			_func_814bd()
		1:  # Func_814c4
			if r2(W2D0E2) < 0x0A:
				return
			w2(W_OW_Y_COORD_1, r2(W2D069))  # (a sound, not ported)
			w2(W2D100, r2(W2D069))
			w2(W_OW_X_COORD_1, r2(W2D06A))
			w2(W2D101, r2(W2D06A))
			set_ow_wario_oam(OWWARIO_ARROWS)
			_func_814bd()
		2:  # Func_814ec
			fill(W2D800, 0x8E, 0)
			fill(W_OW_UI_OBJ_1, 0x40, 0)
			wr_word(W2D889, _func_82111())
			_func_814bd()
		3:
			_func_8150c()
		_:
			_note("Func_81477 state %d (past its table)" % r2(W2D0E3))


## Func_814bd: w2d0e2 cleared, the next w2d0e3.
func _func_814bd() -> void:
	w2(W2D0E2, 0)
	w2(W2D0E3, r2(W2D0E3) + 1)


## Func_8150c: the four arrows (w2d800, w2d820, w2d840, w2d860: right, left, up, down) each a step along
## its path from the level (in turn through w2d880, w2d0a0, and wOWCoords1), their trails' sprites
## kept at w2d0e2 $14 and $28 and cleared at $2c and $40, all drawn (Func_81714); once all four are
## done (step 5), again from Func_814ec.
func _func_8150c() -> void:
	for arrow: int in 4:
		_arrow_load(arrow)  # .Func_81576
		_arrow_step()  # .Func_81615
		_arrow_store()  # .Func_81595
	var counter: int = r2(W2D0E2)
	if counter == 0x14:  # .Func_815c1
		for arrow: int in 4:
			for offset: int in 8:
				w2(W_OW_UI_OBJ_1 + arrow * 8 + offset, r2(W2D800 + arrow * 0x20 + offset))
	if counter == 0x28:  # .Func_815e5
		for arrow: int in 4:
			for offset: int in 8:
				w2(W2D160 + arrow * 8 + offset, r2(W2D800 + arrow * 0x20 + offset))
	if counter == 0x2C:  # .Func_81609
		for arrow: int in 4:
			w2(W_OW_UI_OBJ_1 + SCENE_OBJ_STATE + arrow * 8, 0)
	if counter == 0x40:
		for arrow: int in 4:
			w2(W2D160 + SCENE_OBJ_STATE + arrow * 8, 0)
	_func_81714()
	for arrow: int in 4:
		if r2(W2D800 + arrow * 0x20 + 7) != 0x05:
			return
	w2(W2D0E3, r2(W2D0E3) - 1)


## .Func_81576: arrow `arrow`'s struct (w2d800 on, $20 each) into w2d880 (9 bytes), w2d0a0 (7), and
## wOWCoords1 (8), its number in w2d88b.
func _arrow_load(arrow: int) -> void:
	w2(W2D88B, arrow)
	var at: int = W2D800 + ((swap((arrow << 1) & 0xFF)))
	for pair: Array in [[W2D880, 9], [W2D0A0, 7], [W_OW_Y_COORD_1, 8]]:
		for offset: int in int(pair[1]):
			w2(int(pair[0]) + offset, r2(at + offset))
		at += int(pair[1])


## .Func_81595: the same copied back.
func _arrow_store() -> void:
	var at: int = W2D800 + ((swap((r2(W2D88B) << 1) & 0xFF)))
	for pair: Array in [[W2D880, 9], [W2D0A0, 7], [W_OW_Y_COORD_1, 8]]:
		for offset: int in int(pair[1]):
			w2(at + offset, r2(int(pair[0]) + offset))
		at += int(pair[1])


## .Func_81615: the arrow's step (w2d880 + 7): set off a tile from Wario its way (its arrow shown if
## he may go that way), its path's level and shape, the leg, walk it, wait 8 loops, done.
func _arrow_step() -> void:
	var step_at: int = W2D880 + 7
	match r2(step_at):
		0:  # .Func_81625
			var y: int = r2(W2D100)
			var x: int = r2(W2D101)
			var way: int = r2(W2D88B) + 1
			var offset: int = 0xF8 if (way & 0x02) != 0 else 0x08
			if way < 3:
				x = byte(x + offset)
			else:
				y = byte(y + offset)
			for at: int in [W2D880, W_OW_Y_COORD_1, W_OW_Y_COORD_2, W2D06F]:
				w2(at, y)
			for at: int in [W2D880 + 1, W_OW_X_COORD_1, W_OW_X_COORD_2, W2D070]:
				w2(at, x)
			w2(W2D880 + 4, 0)
			w2(W2D880 + 5, 0)
			var allowed: bool = (swap(r2(W_OW_ALLOWED_D_PAD_INPUT)) & (1 << (way - 1))) != 0
			w2(W2D880 + 6, way if allowed else 0)
			w2(step_at, r2(step_at) + 1)
		1:  # .Func_8167f
			if r2(W2D880 + 6) == 0:
				w2(step_at, 0x05)
				return
			var paths: int = (rd_word(W2D889) + r2(W2D88B)) & 0xFFFF
			var level: int = rb(MAP_BANK, paths)
			w2(W_OW_PATH_SHAPE, rb(MAP_BANK, paths + 4))
			if level == 0x80:
				w2(step_at, 0x05)
				return
			var at: int = get_map_level_coords(level)
			w2(W2D06F, rb(MAP_BANK, at))
			w2(W2D070, rb(MAP_BANK, at + 1))
			w2(step_at, r2(step_at) + 1)
		2:  # .Func_816b3
			func_810fc()
			func_821a1()
			w2(step_at, r2(step_at) + 1)
		3:  # .Func_816be
			func_82208()
			w2(W2D880, r2(W_OW_Y_COORD_1))
			w2(W2D880 + 1, r2(W_OW_X_COORD_1))
			if r2(W2D0A1) != 0:
				return
			if func_810fc() == 0xFF:
				w2(W2D880 + 8, 0)
				w2(step_at, r2(step_at) + 1)
				return
			func_821a1()
			_func_816f6()
		4:  # .Func_816ea
			w2(W2D880 + 8, r2(W2D880 + 8) + 1)
			if r2(W2D880 + 8) >= 0x08:
				w2(step_at, r2(step_at) + 1)
		5:  # .Func_816f5
			pass
		_:
			_note("Func_8150c.Func_81615 step %d (past its table)" % r2(step_at))


## .Func_816f6: the arrow's sprite (w2d880 + 6: 1 right, 2 left, 3 up, 4 down) by the leg's way, its
## animation restarted.
func _func_816f6() -> void:
	var way: int = r2(W2D0A0)
	var arrow: int
	if (way & 0x01) != 0:
		arrow = 0x02 if (way & 0x04) != 0 else 0x01
	else:
		arrow = 0x03 if (way & 0x02) != 0 else 0x04
	w2(W2D880 + 6, arrow)
	w2(W2D880 + 5, 0)
	w2(W2D880 + 4, 0)


## Func_81714: the arrows (w2d800 to w2d860) and their trails (wOWUIObj1 on, w2d160 on) animated by
## their state (.framesets) and drawn with OAM_aa0cf.
func _func_81714() -> void:
	for obj: int in [0xD800, 0xD820, 0xD840, 0xD860, 0xD140, 0xD148, 0xD150, 0xD158, 0xD160, 0xD168, 0xD170,
			0xD178]:
		var state: int = r2(obj + SCENE_OBJ_STATE)
		if state == 0:
			continue
		var frameset: int = rw(MAP_BANK, FUNC_81714_FRAMESETS + (((state - 1) * 2) & 0xFF))
		var base: int = update_ow_animation(obj + SCENE_OBJ_DURATION, frameset, OBJECTS_BANK)
		load_ow_sprite_with_scroll(base, OAM_AA0CF, OBJECTS_BANK)


# --- the Temple's next-treasure hint (state $0a: Func_81346) ---

## Func_81346 (10): the name's fade out, the hint's steps (Func_8137a), the objects and Wario drawn.
func _func_81346() -> void:
	func_852e5()
	_func_8137a()
	func_b4a3d()
	func_8208d()
	func_b4aa9()


## Func_8137a: w2d0e5 counts; by w2d0e4: the next treasure's level name faded in blue, shown until
## B or a d-pad way (or wSceneObj13's end), then Wario back facing down (state 0).
func _func_8137a() -> void:
	w2(W2D0E5, r2(W2D0E5) + 1)
	match r2(W2D0E4):
		0x00:
			_func_81398()
		0x01, 0x08:  # Func_8139f
			if r2(W2D0E5) < 0x08:
				return
			w2(W2D0E0, 0x03)
			_func_81398()
		0x02, 0x09:  # Func_813ad
			if r2(W2D0E0) == 0:
				_func_81398()
		0x03:  # Func_813b4
			var level: Vector2i = _get_map_side_and_level_for_next_treasure()
			load_level_name(level.x, level.y)
			_func_81398()
		0x04, 0x06:  # Func_813ef
			w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
			_func_81398()
		0x05:  # Func_813f6
			if fade_in_level_name():
				return
			set_scene_obj_state(13, 0x1C)
			_func_81398()
		0x07:  # Func_81413
			if (sim.wJoypadPressed & (PAD_B | PAD_RIGHT | PAD_LEFT | PAD_DOWN)) != 0:
				set_scene_obj_state(13, 0)
				_func_81398()
			elif rd(scene_obj(13) + SCENE_OBJ_STATE) == 0:
				_func_81398()
		0x0A:  # Func_8142d
			set_ow_wario_oam(OWWARIO_DOWN)
			w2(W2D013, 0)
			w2(W2D014, 0)
			w2(W2D0E4, 0)
		_:
			_note("Func_8137a state %d (past its table)" % r2(W2D0E4))


## Func_81398: w2d0e5 cleared, the next w2d0e4.
func _func_81398() -> void:
	w2(W2D0E5, 0)
	w2(W2D0E4, r2(W2D0E4) + 1)


## GetMapSideAndLevelForNextTreasure: the side and level (x, y) holding wNextTreasure while its event
## is up to EVENT_GOLD_MUSIC_BOX (or the game is cleared); else the Temple.
func _get_map_side_and_level_for_next_treasure() -> Vector2i:
	var treasure: int = r2(W_NEXT_TREASURE)
	if treasure != TREASURES_END:
		var event: int = get_event_with_treasure(treasure).x
		if event <= EVENT_GOLD_MUSIC_BOX or (r0(W_GAME_MODE_FLAGS) & MODE_GAME_CLEARED_F) != 0:
			return get_map_level_id(_get_level_that_contains_treasure(treasure))
	return Vector2i(NORTH, 0)


## GetLevelThatContainsTreasure (bank $26): the LevelTreasureIDs entry holding `treasure`, by 4.
func _get_level_that_contains_treasure(treasure: int) -> int:
	var index: int = 0
	while rb(0x00, LEVEL_TREASURE_IDS + index) != treasure:
		index += 1
		if index > 0x3FF:
			_note("GetLevelThatContainsTreasure: $%02x not found" % treasure)
			return 0
	return (index & 0xFF) >> 2


## GetMapLevelID: the map side (x) and its level index (y) of LEVEL_* `level` (MapSideInitialLevels).
func get_map_level_id(level: int) -> Vector2i:
	var at: int = MAP_SIDE_INITIAL_LEVELS
	var side: int = -1
	var first: int = 0
	while true:
		first = rb(MAP_BANK, at)
		at += 1
		side += 1
		if byte(rb(MAP_BANK, at) - 1) >= level:
			break
	return Vector2i(side & 0xFF, byte(level - first))


# --- HandleOverworld's level selection ---

## HandleOverworld (after OverworldStateTable): a level chosen (wState ST_LEVEL) is selected
## (SelectLevel), the Golf Building's state for it.
func handle_overworld_level_selection() -> void:
	if sim.wState != ST_LEVEL:
		return
	select_level()  # (a sound, not ported)
	if r0(W_LEVEL) == GOLF_BUILDING:
		sim.wState = ST_GOLF_BUILDING


## SelectLevel (bank $01): wLevel from wOWLevel: the Temple, the Golf Building, or the level's variant
## by its treasures got (LevelTreasureRequirements, pairs for variants 4, 3, 2), night's with
## wDayNight bit 0.
func select_level() -> void:
	var level: int = r2(W_OW_LEVEL)
	if level == 0:
		w0(W_LEVEL, THE_TEMPLE)
		return
	if level == LEVEL_GOLF_BUILDING:
		w0(W_LEVEL, GOLF_BUILDING)
		return
	var base: int = (((level - 1) * 8) & 0xFF)
	w0(W_LEVEL, base)
	var at: int = LEVEL_TREASURE_REQUIREMENTS + base
	for variant: int in [3, 2, 1]:
		var first: int = is_treasure_collected(rb(0x01, at))
		var second: int = is_treasure_collected(rb(0x01, at + 1))
		at += 2
		if (first & second) != 0:
			w0(W_LEVEL, r0(W_LEVEL) + variant)
			break
	w0(W_LEVEL, r0(W_LEVEL) | ((r0(W_DAY_NIGHT) & 1) << 2))
