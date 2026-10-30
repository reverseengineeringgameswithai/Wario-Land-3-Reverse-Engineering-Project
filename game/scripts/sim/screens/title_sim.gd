class_name TitleSim
extends MenuScreenSim
## The title (TitleStateTable, 01:402b, src/engine/title/, WL3-055, WL3-056): the fade to white,
## InitIntroSequence, the fade in, without a save the intro (Wario's plane over three scrolling
## background layers, sub-states 3-6), and the start menu, where New Game goes to the language
## selection and Continue to the map (or to the level a level's save resumes); left alone, the menu
## opens Action Help's demos. The language selection (LanguageSelectionStateTable, 01:4831, in bank 1
## too, with the title's RAM) runs here as well, in its own state: the font's screen, a cursor on
## English or Japanese, and A to the map as a new game. Clear Data's reset and Time Attack's description
## are not ported, nor are the music and sound effects (but for the timer that repeats the plane's).

const W_TEMP_BANK: int = 0xC0AC
const W_POWER_UP_LEVEL: int = 0xCA3C
const W_LANGUAGE: int = 0xCA46
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_TRANSITION_PARAM: int = 0xCEE3
const W_CEE4: int = 0xCEE4
const W_TIMER: int = 0xCEE5
const WCEEF: int = 0xCEEF
const W_TEMP_PALS_1: int = 0xC000
## The intro's three background layers' horizontal scroll (PanIntroBackgroundLayers).
const W_INTRO_BG_X_OFFSET_FAR: int = 0xC086
const W_INTRO_BG_X_OFFSET_CENTRE: int = 0xC087
const W_INTRO_BG_X_OFFSET_NEAR: int = 0xC088
## GFX RAM (WRAMX bank 3): the start menu's selection, the plane's Wario (menu_obj_ext_struct) and
## its sound effect timer, and the menu objects.
const W_START_MENU_SELECTION: int = 0xD513
const W_PLANE_WARIO: int = 0xD515
const W_PLANE_WARIO_VAR: int = 0xD51D
const W_PLANE_WARIO_ANIMATION_ENDED: int = 0xD520
const W_SFX_TIMER: int = 0xD522
const W_MENU_OBJ_1: int = 0xD523
const W_MENU_OBJ_2: int = 0xD52B
const W_MENU_OBJ_3: int = 0xD533
const W_MENU_OBJ_4: int = 0xD53B
const W_MENU_OBJ_5: int = 0xD547

const ST_OVERWORLD: int = 0x01
const ST_LEVEL: int = 0x02
const ST_ACTION_HELP: int = 0x07
const ST_LANGUAGE_SELECTION: int = 0x0E
const ENGLISH: int = 1
const TRANSITION_NEW_GAME: int = 0xFF
const SST_START_MENU: int = 0x07
const MODE_TIME_ATTACK: int = 1 << 1
const ACTION_HELP_TITLE_SCREEN: int = 0x40
## StartMenu's wait before Action Help's demos, in loops.
const ACTION_HELP_TIMER: int = 2116
## wStartMenuSelection: the option (low nibble) and the flags above it.
const STARTMENU_NEW_GAME: int = 0x0
const STARTMENU_CONTINUE: int = 0x1
const STARTMENU_CLEAR_DATA: int = 0x2
const STARTMENU_CLEAR_DATA_NO: int = 0x3
const STARTMENU_CLEAR_DATA_YES: int = 0x4
const STARTMENUF_SCROLLING: int = 1 << 4
const STARTMENUF_ANIM1: int = 1 << 5
const STARTMENUF_ANIM2: int = 1 << 6
const STARTMENUF_SELECT: int = 1 << 7
## The bank the table runs in: UpdateObjAnim's framesets, and the OAM tables of LoadStartMenuSprite
## (OAM_6b5f) and LoadIntroSprite (OAM_6d21).
const TITLE_BANK: int = 0x01
const OAM_START_MENU: String = "01:6b5f"
const OAM_INTRO: String = "01:6d21"
const OAM_LANGUAGE_SELECTION: String = "01:75c3"
const FONT_PALS: String = "7c:7610"  # Pals_1f3610 (LoadFontPals)
const TIME_ATTACK_DESCRIPTION_PALS: String = "01:71b0"  # Pals_71b0 (LoadTimeAttackDescriptionPals)
## LoadTitleScreenPals: without a save, then with one (wTempPals1, wTempPals2).
const TITLE_PALS: Array = [["01:4f82", "01:4fc2"], ["01:5002", "01:5042"]]
## The title's framesets (bank 1).
const FRAMESET_6CE6: int = 0x6CE6
const FRAMESET_6CE9: int = 0x6CE9
const FRAMESET_6CEC: int = 0x6CEC
const FRAMESET_6CEF: int = 0x6CEF
const FRAMESET_6CF2: int = 0x6CF2
const FRAMESET_6D05: int = 0x6D05
const FRAMESET_6D18: int = 0x6D18
const FRAMESET_6D1B: int = 0x6D1B
const FRAMESET_6D1E: int = 0x6D1E
const FRAMESET_712C: int = 0x712C
const FRAMESET_713D: int = 0x713D
const FRAMESET_7144: int = 0x7144
const FRAMESET_7165: int = 0x7165
const FRAMESET_7172: int = 0x7172
const FRAMESET_717B: int = 0x717B
const FRAMESET_7184: int = 0x7184
const FRAMESET_718D: int = 0x718D
const FRAMESET_7198: int = 0x7198
const FRAMESET_71A1: int = 0x71A1
const FRAMESET_71A4: int = 0x71A4
const FRAMESET_71A7: int = 0x71A7
const FRAMESET_76B5: int = 0x76B5
## The lines PanIntroBackgroundLayers' layers start at: the lines it waits for ($5b, $63, $73, $83),
## plus one (it writes rSCX in their H-Blanks).
const PAN_LINES: Array = [0x5C, 0x64, 0x74, 0x84]
## play_sfx_rept's period for the plane's sound (PlayIntroSFXPlane_Close and _Far).
const PLANE_SFX_PERIOD: int = 12
const SCREEN_HEIGHT_PX: int = 144

## The V-Blank functions InitIntroSequence sets (VBlank_Title: the box under the menu when wcee4's
## bit 7 asks, the scroll, and the OAM) and InitLanguageSelection (VBlank_LanguageSelection: the
## language's rows highlighted when wcee4's bit 7 asks, the scroll, and the OAM).
const VBLANK_TITLE: int = 1
const VBLANK_LANGUAGE_SELECTION: int = 2
const VBLANK_TIME_ATTACK_DESCRIPTION: int = 3

## wTempBank (WRAM0, shared with the other screens).
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)
## The intro's background layers' scroll (WRAM0, the screens' shared WRAM0).
var wIntroBGXOffsetFar: int:
	get:
		return r0(W_INTRO_BG_X_OFFSET_FAR)
	set(value):
		w0(W_INTRO_BG_X_OFFSET_FAR, value)
var wIntroBGXOffsetCentre: int:
	get:
		return r0(W_INTRO_BG_X_OFFSET_CENTRE)
	set(value):
		w0(W_INTRO_BG_X_OFFSET_CENTRE, value)
var wIntroBGXOffsetNear: int:
	get:
		return r0(W_INTRO_BG_X_OFFSET_NEAR)
	set(value):
		w0(W_INTRO_BG_X_OFFSET_NEAR, value)
## For drawing: the layers' scroll PanIntroBackgroundLayers set during the last loop's frame
## ([far, centre, near]), or empty when it did not run.
var pan: Array = []
## For drawing: what the last loop's V-Blank wrote to VRAM ([bank, address, value]).
var vblank_writes: Array = []
## For drawing: whether the last loop moved the Japanese description's rows (scy_lines).
var japanese_window: bool = false


## One game loop: TitleStateTable by wSubState (or in the language selection's state its table), then
## what its V-Blank function writes.
func update() -> void:
	loops += 1
	screen_loads.clear()
	vblank_writes.clear()
	pan.clear()
	japanese_window = false
	if sim.wState == ST_LANGUAGE_SELECTION:
		_language_selection_state_table()
	else:
		_title_state_table()
	if vblank_func == VBLANK_TITLE and (r0(W_CEE4) & 0x80) != 0:
		# VBlank_Title: TitleScreenBoxTilemap's two rows at (4, 14) and (4, 15) of BG map 0
		vblank_writes.append(["box"])
		w0(W_CEE4, r0(W_CEE4) & 0x7F)
	elif vblank_func == VBLANK_LANGUAGE_SELECTION and (r0(W_CEE4) & 0x80) != 0:
		# VBlank_LanguageSelection: the chosen language's row highlighted (by wcee4 less bit 7)
		vblank_writes.append(["language", r0(W_CEE4) & 0x7F])
		w0(W_CEE4, r0(W_CEE4) & 0x7F)


func _title_state_table() -> void:
	match sim.wSubState:
		0x00:
			fade(0)  # FastFadeToWhite
		0x01:
			init_intro_sequence()
		0x02:
			fade(0)  # SlowFadeFromWhite
		0x03:
			intro_sequence_phase_1()
		0x04:
			intro_sequence_phase_2()
		0x05:
			intro_sequence_phase_3()
		0x06:
			end_intro_sequence()
		SST_START_MENU:
			start_menu()
		0x08:
			fade(2)  # SlowFadeBGToWhite
		0x09:
			init_time_attack_description()
		0x0A:
			time_attack_description()
		_:
			_note("TitleStateTable sub-state %d (DebugReset, not ported)" % sim.wSubState)


# --- Time Attack's description (src/engine/title/time_attack_description.asm) ---

## InitTimeAttackDescription: the virtual OAM cleared, Pals_71b0 to wTempPals1 and the BG palettes
## (ApplyTempPals1ToBGPals), the font, the prologue's background tiles, and the text by wLanguage
## (drawing), VBlank_TimeAttackDescription (the scroll and the OAM), the scroll and wTimer's first
## byte cleared, and the next sub-state.
func init_time_attack_description() -> void:
	clear_virtual_oam()
	_load_pals(TIME_ATTACK_DESCRIPTION_PALS, W_TEMP_PALS_1)
	screen_loads.append(["time_attack_description", r0(W_LANGUAGE)])
	vblank_func = VBLANK_TIME_ATTACK_DESCRIPTION
	sim.wSCY = 0
	sim.wSCX = 0
	w0(W_TIMER, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## TimeAttackDescription: in Japanese the text's rows scrolled mid-frame
## (AdjustJapaneseTimeAttackDescriptionWindow: drawing, scy_lines); A goes to the map in Time Attack
## (the screen off and white, then StartOverworldState).
func time_attack_description() -> void:
	japanese_window = r0(W_LANGUAGE) == 0
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		return
	screen_loads.append(["white"])
	sim.wState = ST_OVERWORLD
	sim.wSubState = 0


## AdjustJapaneseTimeAttackDescriptionWindow's rSCY writes in the last loop's frame, for drawing: it
## waits for lines $2f, $38, $41, $5a, $63, and $6c and adds 7 in the next H-Blank, so each part
## from the line after shows 7 lines further down. [first line, scy], as CgbScreen.render takes
## them; empty when it did not run (English, or another sub-state).
func scy_lines(scy: int) -> Array:
	if not japanese_window:
		return []
	var lines: Array = []
	for index: int in JAPANESE_WINDOW_LINES.size():
		lines.append([JAPANESE_WINDOW_LINES[index], (scy + 7 * (index + 1)) & 0xFF])
	return lines


const JAPANESE_WINDOW_LINES: Array = [0x30, 0x39, 0x42, 0x5B, 0x64, 0x6D]


# --- the language selection (src/engine/language_selection/) ---

## LanguageSelectionStateTable: FastFadeToWhite, InitLanguageSelection, SlowFadeFromWhite, and
## LanguageSelection; the rest are DebugReset.
func _language_selection_state_table() -> void:
	match sim.wSubState:
		0x00, 0x02:
			fade(0)  # FastFadeToWhite, SlowFadeFromWhite
		0x01:
			init_language_selection()
		0x03:
			language_selection()
		_:
			_note("LanguageSelectionStateTable sub-state %d (DebugReset, not ported)" % sim.wSubState)


## InitLanguageSelection: the font's palettes in both sets (LoadFontPals), the font's tiles and the
## text (drawing), VBlank_LanguageSelection, the scroll cleared, English, and the cursor on it.
func init_language_selection() -> void:
	clear_virtual_oam()
	_load_pals(FONT_PALS, W_TEMP_PALS_1)
	_load_pals(FONT_PALS, W_TEMP_PALS_1 + 0x40)
	screen_loads.append(["language_selection"])
	vblank_func = VBLANK_LANGUAGE_SELECTION
	sim.wSCY = 0
	sim.wSCX = 0
	w0(W_LANGUAGE, ENGLISH)
	_set_up_and_animate(W_MENU_OBJ_1, 70, 24, FRAMESET_76B5)
	load_language_selection_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	sim.wSubState = byte(sim.wSubState + 1)


## LanguageSelection: A goes to the map as a new game (StartOverworldStateAndNewGameParam); down
## moves the cursor from English (y 70) to Japanese (y 86) and up back, the row highlighted at the
## next V-Blank (wcee4); a move that cannot be made ends the loop. Then the cursor animated and drawn.
func language_selection() -> void:
	var pressed: int = sim.wJoypadPressed
	if (pressed & WarioRam.PAD_A) != 0:
		w0(W_TRANSITION_PARAM, TRANSITION_NEW_GAME)
		sim.wState = ST_OVERWORLD
		sim.wSubState = 0
		return
	if (pressed & WarioRam.PAD_DOWN) != 0 or (pressed & WarioRam.PAD_UP) != 0:
		var down: bool = (pressed & WarioRam.PAD_DOWN) != 0
		if (down and r0(W_LANGUAGE) == 0) or (not down and r0(W_LANGUAGE) == ENGLISH):
			return
		var language: int = 0 if down else ENGLISH
		w3(W_MENU_OBJ_1 + OBJ_Y, 86 if down else 70)
		w0(W_LANGUAGE, language)
		w0(W_CEE4, language + 0x80)
	update_obj_anim(W_MENU_OBJ_1, TITLE_BANK)
	load_language_selection_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()


## LoadLanguageSelectionSprite: an object from OAM_75c3 at its position (y less the scroll).
func load_language_selection_sprite(obj: int) -> void:
	_load_obj_sprite(OAM_LANGUAGE_SELECTION, obj)


# --- InitIntroSequence (intro.asm) ---

## InitIntroSequence: the title's screen (FillBGMap0_With7f, its palettes, tiles, and maps: drawing)
## and VBlank_Title, the scroll at (0, 4), and its objects. Without a save, the plane's Wario off the
## right edge (animated), the logo's parts, and New Game; with one (wceef), the plane at rest (not
## animated until the start menu), the menu's rows behind the scenery and the box under them
## (drawing), the menu (Continue, or Time Attack's), and Continue chosen. Then the logo's sparkle,
## wTimer's low byte and wGlobalCounter cleared, and the next sub-state.
func init_intro_sequence() -> void:
	clear_virtual_oam()
	var saved: bool = r0(WCEEF) != 0
	var pals: Array = TITLE_PALS[1 if saved else 0]
	_load_pals(String(pals[0]), W_TEMP_PALS_1)
	_load_pals(String(pals[1]), W_TEMP_PALS_1 + 0x40)
	screen_loads.append(["title", saved])
	vblank_func = VBLANK_TITLE
	sim.wSCY = 4
	sim.wSCX = 0
	var time_attack: bool = (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0
	if not saved:
		_set_up_plane_wario(64, 208, FRAMESET_712C)
		update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
		_set_up_and_animate(W_MENU_OBJ_1, 128, 80, FRAMESET_6CE6)
		_set_up_and_animate(W_MENU_OBJ_4, 16, 0, FRAMESET_71A1)
		_set_up_and_animate(W_MENU_OBJ_5, 8, 32, FRAMESET_71A4)
		load_intro_sprite(W_MENU_OBJ_4)
		load_intro_sprite(W_MENU_OBJ_5)
		w3(W_START_MENU_SELECTION, STARTMENU_NEW_GAME)
	else:
		_set_up_plane_wario(108, 128, FRAMESET_7198)
		_set_up_and_animate(W_MENU_OBJ_1, 0x82, 0x50, FRAMESET_6D1E if time_attack else FRAMESET_6CE9)
		_set_up_and_animate(W_MENU_OBJ_2, 0x86, 0x40 if time_attack else 0x44, FRAMESET_6D1B)
		w3(W_START_MENU_SELECTION, STARTMENU_CONTINUE)
	_set_up_and_animate(W_MENU_OBJ_3, 36, 104, FRAMESET_6D18)
	w0(W_TIMER, 0)
	sim.wGlobalCounter = 0
	sim.wSubState = byte(sim.wSubState + 1)


## The plane's Wario at (y, x) with `frameset`, and its state (wPlaneWarioVar) and the sound effect
## timer cleared (only the intro's is animated at once).
func _set_up_plane_wario(y: int, x: int, frameset: int) -> void:
	set_up_obj(W_PLANE_WARIO, y, x, frameset)
	w3(W_PLANE_WARIO_VAR, 0)
	w3(W_SFX_TIMER, 0)


func _set_up_and_animate(obj: int, y: int, x: int, frameset: int) -> void:
	set_up_obj(obj, y, x, frameset)
	update_obj_anim(obj, TITLE_BANK)


## IntroSequencePhase1: with a save, straight to the start menu (StartTitleScreen). Without one Wario's
## plane, close, by wPlaneWarioVar: 180 loops' wait (the intro's music), flying in from the right to
## x 48, 48 loops' hover, bobbing between y 64 and 70 three times, then flying off to the right; at
## x 192 it is set far away above (Frameset_713d) for phase 2, after 28 loops.
func intro_sequence_phase_1() -> void:
	if r0(WCEEF) != 0:
		start_title_screen()
		return
	_play_sfx_rept()  # PlayIntroSFXPlane_Close
	func_4d45()
	var plane_x: int = W_PLANE_WARIO + OBJ_X
	match r3(W_PLANE_WARIO_VAR):
		1:
			var x: int = r3(plane_x)
			if x >= 72:
				w3(plane_x, x - 2)
			elif x >= 56:
				w3(plane_x, x - 1)
			elif x == 48:
				w0(W_TIMER, 48)
				_next_plane_state()
			elif (sim.wGlobalCounter & 0b11) == 0:
				w3(plane_x, x - 1)
		2:
			if _count_down():
				w0(W_TIMER, 3)
				_restart_plane(FRAMESET_71A7)
				_next_plane_state()
		3:
			if (sim.wGlobalCounter & 0b111) == 0:
				w3(W_PLANE_WARIO + OBJ_Y, r3(W_PLANE_WARIO + OBJ_Y) + 1)
				if r3(W_PLANE_WARIO + OBJ_Y) == 70:
					_next_plane_state()
		4:
			if (sim.wGlobalCounter & 0b111) == 0:
				w3(W_PLANE_WARIO + OBJ_Y, r3(W_PLANE_WARIO + OBJ_Y) - 1)
				if r3(W_PLANE_WARIO + OBJ_Y) == 64:
					if _count_down():
						_restart_plane(FRAMESET_712C)
						_next_plane_state()
					else:
						w3(W_PLANE_WARIO_VAR, r3(W_PLANE_WARIO_VAR) - 1)
		5:
			var x: int = r3(plane_x)
			if x == 192:
				set_up_obj(W_PLANE_WARIO, 16, 192, FRAMESET_713D)
				w3(W_PLANE_WARIO_VAR, 0)
				w3(W_SFX_TIMER, 0)
				w0(W_TIMER, 28)
				sim.wSubState = byte(sim.wSubState + 1)
			elif x >= 56 or (sim.wGlobalCounter & 0b11) == 0:
				w3(plane_x, x + 1)
		_:
			w0(W_TIMER, r0(W_TIMER) + 1)
			if r0(W_TIMER) >= 180:
				w0(W_TIMER, 0)
				_next_plane_state()
	scroll_intro_background_layers()
	update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
	load_intro_sprite(W_PLANE_WARIO)
	load_intro_sprite(W_MENU_OBJ_4)
	load_intro_sprite(W_MENU_OBJ_5)
	clear_unused_virtual_oam()
	pan_intro_background_layers()


## IntroSequencePhase2: the plane far away, by wPlaneWarioVar: after phase 1's 28 loops it drifts to
## the centre (x 64), hovers 48 loops, then wobbles (Frameset_7144) for 224 loops and explodes
## (Frameset_7165) for phase 3, 48 loops on.
func intro_sequence_phase_2() -> void:
	func_4d45()
	_play_sfx_rept()  # PlayIntroSFXPlane_Far
	var plane_x: int = W_PLANE_WARIO + OBJ_X
	match r3(W_PLANE_WARIO_VAR):
		1:
			if _count_down():
				_restart_plane(FRAMESET_7144)
				w3(W_SFX_TIMER, 0)
				w0(W_TIMER, 224)
				_next_plane_state()
		2:
			if _count_down():
				_restart_plane(FRAMESET_7165)
				w3(W_PLANE_WARIO_VAR, 0)
				w3(W_SFX_TIMER, 0)
				w0(W_TIMER, 48)
				sim.wSubState = byte(sim.wSubState + 1)
		_:
			if r0(W_TIMER) != 0:
				w0(W_TIMER, r0(W_TIMER) - 1)
			else:
				var x: int = r3(plane_x)
				if x == 64:
					w0(W_TIMER, 48)
					_next_plane_state()
				elif (x >= 72 and (sim.wGlobalCounter & 0b1) == 0) or (x < 72 and (sim.wGlobalCounter & 0b11) == 0):
					w3(plane_x, x - 1)
	scroll_intro_background_layers()
	update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
	load_intro_sprite(W_MENU_OBJ_4)
	load_intro_sprite(W_PLANE_WARIO)
	load_intro_sprite(W_MENU_OBJ_5)
	clear_unused_virtual_oam()
	pan_intro_background_layers()


## IntroSequencePhase3: once the explosion's animation ends, the plane nosedives (Frameset_7172,
## _717b, _7184, _718d), a line down a loop and right every 4 loops, the framesets changing at y 16,
## 48, and 112; then it follows the near layer (2 a loop) until it aligns (x offset 224), and when its
## last animation ends Wario rests (Frameset_7198), the title's palettes are loaded (Pals_5002,
## Pals_5042), and EndIntroSequence follows. From the nosedive's end the layers scroll to their places
## (FinishIntroBackgroundScroll).
func intro_sequence_phase_3() -> void:
	func_4d45()
	var plane_x: int = W_PLANE_WARIO + OBJ_X
	var plane_y: int = W_PLANE_WARIO + OBJ_Y
	var finish: bool = false
	var state: int = r3(W_PLANE_WARIO_VAR)
	match state:
		1, 2, 3:
			if (sim.wGlobalCounter & 0b11) == 0:
				w3(plane_x, r3(plane_x) + 1)
			w3(plane_y, r3(plane_y) + 1)
			if r3(plane_y) >= [16, 48, 112][state - 1]:
				_restart_plane([FRAMESET_717B, FRAMESET_7184, FRAMESET_718D][state - 1])
				_next_plane_state()
		4:
			if wIntroBGXOffsetNear != 224:
				w3(plane_x, r3(plane_x) + 2)
			finish = true
			if r3(W_PLANE_WARIO_ANIMATION_ENDED) != 0:
				_restart_plane(FRAMESET_7198)
				w3(W_PLANE_WARIO_VAR, 0)
				w0(W_TIMER, 0)
				_load_pals(String(TITLE_PALS[1][0]), W_TEMP_PALS_1)
				_load_pals(String(TITLE_PALS[1][1]), W_TEMP_PALS_1 + 0x40)
				sim.wSubState = byte(sim.wSubState + 1)
		_:
			if r3(W_PLANE_WARIO_ANIMATION_ENDED) != 0:
				_restart_plane(FRAMESET_7172)
				_next_plane_state()
	if finish:
		finish_intro_background_scroll()
	else:
		scroll_intro_background_layers()
	update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
	w3(W_PLANE_WARIO_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
	load_intro_sprite(W_MENU_OBJ_4)
	load_intro_sprite(W_PLANE_WARIO)
	load_intro_sprite(W_MENU_OBJ_5)
	clear_unused_virtual_oam()
	pan_intro_background_layers()


## EndIntroSequence: Wario animated and drawn; with a save the start menu at once. Otherwise 120 loops'
## wait (wTimer), then SlowFadeInScreen every 4 loops (its 33 steps leave the palettes as they are:
## it fades wTempPals1 to itself) and, once it ends, the start menu (StartTitleScreen).
func end_intro_sequence() -> void:
	update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
	load_intro_sprite(W_PLANE_WARIO)
	clear_unused_virtual_oam()
	if r0(WCEEF) != 0:
		start_title_screen()
		return
	if r0(W_TIMER) < 120:
		w0(W_TIMER, r0(W_TIMER) + 1)
		return
	if (sim.wGlobalCounter & 0b11) == 0:
		slow_fade_in_screen()
	if sim.wSubState == SST_START_MENU:
		start_title_screen()


## Func_4d45: the logo's two parts drift right, wMenuObj5 on odd loops and wMenuObj4 every loop, until
## x 176; past it they go on only before phase 2's flight (sub-state 3, or 4 while wPlaneWarioVar is 0).
func func_4d45() -> void:
	if (sim.wGlobalCounter & 0b1) != 0:
		_drift_logo_part(W_MENU_OBJ_5)
	_drift_logo_part(W_MENU_OBJ_4)


func _drift_logo_part(obj: int) -> void:
	var x: int = r3(obj + OBJ_X)
	if x >= 176:
		if sim.wSubState >= 5 or (sim.wSubState == 4 and r3(W_PLANE_WARIO_VAR) != 0):
			return
	w3(obj + OBJ_X, x + 1)


## ScrollIntroBackgroundLayers: the far layer a pixel every 4 loops, the centre one a loop, the near
## one 2 a loop (leftward).
func scroll_intro_background_layers() -> void:
	if (sim.wGlobalCounter & 0b11) == 0:
		wIntroBGXOffsetFar -= 1
	wIntroBGXOffsetCentre -= 1
	wIntroBGXOffsetNear -= 2


## FinishIntroBackgroundScroll: the layers scroll on until aligned: the far and centre ones to a
## multiple of 32, then to wSCX; the near one to 224.
func finish_intro_background_scroll() -> void:
	if (sim.wGlobalCounter & 0b11) == 0:
		if (wIntroBGXOffsetFar & 0x1F) != 0:
			wIntroBGXOffsetFar -= 1
		else:
			wIntroBGXOffsetFar = sim.wSCX
	if (wIntroBGXOffsetCentre & 0x1F) != 0:
		wIntroBGXOffsetCentre -= 1
	else:
		wIntroBGXOffsetCentre = sim.wSCX
	if wIntroBGXOffsetNear != 224:
		wIntroBGXOffsetNear -= 2


## PanIntroBackgroundLayers (without a save): rSCX set mid-frame for the far, centre, and near layers,
## then back to wSCX (drawing: `pan`).
func pan_intro_background_layers() -> void:
	if r0(WCEEF) == 0:
		pan = [wIntroBGXOffsetFar, wIntroBGXOffsetCentre, wIntroBGXOffsetNear]


## The rSCX writes PanIntroBackgroundLayers made in the last loop's frame, as [first line, scx]: it
## waits for lines $5b, $63, $73, and $83 and writes in the next H-Blank, so the far, centre, and near
## layers start a line later, and `scx` (wSCX) returns below them. Empty when it did not run.
func scx_lines(scx: int) -> Array:
	if pan.is_empty():
		return []
	return [[PAN_LINES[0], int(pan[0])], [PAN_LINES[1], int(pan[1])], [PAN_LINES[2], int(pan[2])], [PAN_LINES[3], scx]]


## play_sfx_rept 12 (the plane's sound): wSFXTimer counts down, and from 0 starts again at 12 (the
## sound itself is not ported).
func _play_sfx_rept() -> void:
	var timer: int = r3(W_SFX_TIMER)
	w3(W_SFX_TIMER, timer - 1 if timer != 0 else PLANE_SFX_PERIOD)


## wTimer's low byte less one; whether it reached 0.
func _count_down() -> bool:
	w0(W_TIMER, r0(W_TIMER) - 1)
	return r0(W_TIMER) == 0


## The plane's frameset offset and duration cleared and `frameset` set (its frame kept).
func _restart_plane(frameset: int) -> void:
	w3(W_PLANE_WARIO + OBJ_FRAMESET_OFFSET, 0)
	w3(W_PLANE_WARIO + OBJ_DURATION, 0)
	_set_frameset(W_PLANE_WARIO, frameset)


func _next_plane_state() -> void:
	w3(W_PLANE_WARIO_VAR, r3(W_PLANE_WARIO_VAR) + 1)


## StartTitleScreen: the title's music (not ported), Action Help's timer started, and the start menu.
func start_title_screen() -> void:
	_set_timer(ACTION_HELP_TIMER)
	sim.wSubState = SST_START_MENU


# --- StartMenu (start_menu.asm, start_menu_selection.asm) ---

## StartMenu: the plane's Wario animated and drawn, the sparkle drawn, the input, the menu drawn (with
## a save its arrow, wMenuObj2, blinks: palettes 3 apart every 8 loops), and the OAM's rest cleared.
## Once an option is chosen, what it does; until then Action Help's timer runs while New Game or
## Continue rests, and starts again otherwise: at 0, Action Help's demos (OpenActionHelp).
func start_menu() -> void:
	update_obj_anim(W_PLANE_WARIO, TITLE_BANK)
	load_intro_sprite(W_PLANE_WARIO)
	load_start_menu_sprite(W_MENU_OBJ_3)
	handle_start_menu_selection()
	load_start_menu_sprite(W_MENU_OBJ_1)
	if r0(WCEEF) != 0:
		if (sim.wGlobalCounter & 0b111) == 0:
			w3(W_MENU_OBJ_2 + OBJ_ATTRIBUTES, r3(W_MENU_OBJ_2 + OBJ_ATTRIBUTES) ^ 0b11)
		load_start_menu_sprite(W_MENU_OBJ_2)
	clear_unused_virtual_oam()
	var selection: int = r3(W_START_MENU_SELECTION)
	if (selection & STARTMENUF_SELECT) != 0:
		_start_menu_select()
		return
	if selection != STARTMENU_NEW_GAME and selection != STARTMENU_CONTINUE:
		_set_timer(ACTION_HELP_TIMER)
		return
	var timer: int = (_timer() - 1) & 0xFFFF
	_set_timer(timer)
	if timer != 0:
		return
	w0(W_POWER_UP_LEVEL, r0(W_POWER_UP_LEVEL) | ACTION_HELP_TITLE_SCREEN)
	open_action_help()


## StartMenu.select: New Game (the language selection), Continue (the map, the level a level's save
## resumes, or in Time Attack its description), Clear Data (asks: No highlighted), Clear Data's Yes
## (ClearSaveData: the save's check values cleared, then Init), or its No (the menu again, the box
## redrawn).
func _start_menu_select() -> void:
	match r3(W_START_MENU_SELECTION) & 0x0F:
		STARTMENU_NEW_GAME:
			sim.wState = ST_LANGUAGE_SELECTION
			sim.wSubState = 0
		STARTMENU_CONTINUE:
			_continue_or_time_attack()
		STARTMENU_CLEAR_DATA:
			w0(W_CEE4, 0x81)
			w3(W_MENU_OBJ_2 + OBJ_Y, SCREEN_HEIGHT_PX)
			w3(W_MENU_OBJ_1 + OBJ_Y, 120)
			_choose(STARTMENU_CLEAR_DATA_NO, FRAMESET_6CEC)
		STARTMENU_CLEAR_DATA_YES:
			sim.request_init(LevelSim.INIT_CLEAR_SAVE_DATA)
		_:
			w3(W_MENU_OBJ_2 + OBJ_Y, 134)
			w3(W_MENU_OBJ_1 + OBJ_Y, 130)
			if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0:
				_choose(STARTMENU_CONTINUE, FRAMESET_6D1E)
			else:
				w0(W_CEE4, 0x80)
				_choose(STARTMENU_CONTINUE, FRAMESET_6CE9)


## StartMenu.ContinueOrTimeAttack: in Time Attack the screen off and white (drawing) and the next
## sub-state; otherwise a level's save (wceef bits 2-5) resumes its level, and a map's save goes to
## the map (StartOverworldState).
func _continue_or_time_attack() -> void:
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0:
		screen_loads.append(["white"])
		sim.wSubState = byte(sim.wSubState + 1)
		return
	sim.wState = ST_LEVEL if (r0(WCEEF) & 0b111100) != 0 else ST_OVERWORLD
	sim.wSubState = 0


## The selection `option`, and wMenuObj1 restarted on `frameset` and animated.
func _choose(option: int, frameset: int) -> void:
	w3(W_START_MENU_SELECTION, option)
	w3(W_MENU_OBJ_1 + OBJ_FRAMESET_OFFSET, 0)
	w3(W_MENU_OBJ_1 + OBJ_DURATION, 0)
	_set_frameset(W_MENU_OBJ_1, frameset)
	update_obj_anim(W_MENU_OBJ_1, TITLE_BANK)


## OpenActionHelp (src/home/wario_mechanics2.asm).
func open_action_help() -> void:
	sim.wState = ST_ACTION_HELP
	sim.wSubState = 0


## HandleStartMenuSelection: while the menu scrolls or an option's animation runs, that; otherwise A
## chooses (the option's animation; on Clear Data's question its Yes or No), down from Continue and up
## from Clear Data scroll, and on Clear Data's question left moves to Yes and right to No. The sound
## effects are not ported.
func handle_start_menu_selection() -> void:
	var selection: int = r3(W_START_MENU_SELECTION)
	if (selection & STARTMENUF_SCROLLING) != 0:
		_move_vertical()
		return
	if (selection & STARTMENUF_ANIM1) != 0:
		_update_anim_1()
		return
	if (selection & STARTMENUF_ANIM2) != 0:
		_update_anim_2()
		return
	var pressed: int = sim.wJoypadPressed
	if (pressed & WarioRam.PAD_A) != 0:
		match selection & 0x0F:
			STARTMENU_CLEAR_DATA_NO:
				_choose(0x23, FRAMESET_6CF2)
			STARTMENU_CLEAR_DATA_YES:
				_choose(0x24, FRAMESET_6D05)
			_:
				w3(W_START_MENU_SELECTION, selection | STARTMENUF_ANIM2)
				w3(W_MENU_OBJ_1 + OBJ_FRAMESET_OFFSET, 0)
	elif (pressed & WarioRam.PAD_DOWN) != 0:
		if selection == STARTMENU_CONTINUE:
			w3(W_START_MENU_SELECTION, STARTMENU_CLEAR_DATA | STARTMENUF_SCROLLING)
	elif (pressed & WarioRam.PAD_UP) != 0:
		if selection == STARTMENU_CLEAR_DATA:
			w3(W_START_MENU_SELECTION, STARTMENU_CONTINUE | STARTMENUF_SCROLLING)
	elif (pressed & WarioRam.PAD_RIGHT) != 0:
		if selection == STARTMENU_CLEAR_DATA_YES:
			_choose(STARTMENU_CLEAR_DATA_NO, FRAMESET_6CEC)
	elif (pressed & WarioRam.PAD_LEFT) != 0:
		if selection == STARTMENU_CLEAR_DATA_NO:
			_choose(STARTMENU_CLEAR_DATA_YES, FRAMESET_6CEF)


## HandleStartMenuSelection.MoveVertical: the highlight a line a loop, down to Clear Data (y 130, the
## arrow at 134) or up to Continue (y 116, the arrow at 118), then the scrolling flag cleared.
func _move_vertical() -> void:
	var y: int = r3(W_MENU_OBJ_1 + OBJ_Y)
	if r3(W_START_MENU_SELECTION) == STARTMENU_CLEAR_DATA | STARTMENUF_SCROLLING:
		y = byte(y - 1)
		w3(W_MENU_OBJ_1 + OBJ_Y, y)
		if y != 116:
			return
		w3(W_MENU_OBJ_2 + OBJ_Y, 118)
	else:
		y = byte(y + 1)
		w3(W_MENU_OBJ_1 + OBJ_Y, y)
		if y != 130:
			return
		w3(W_MENU_OBJ_2 + OBJ_Y, 134)
	w3(W_START_MENU_SELECTION, r3(W_START_MENU_SELECTION) & ~STARTMENUF_SCROLLING)


## HandleStartMenuSelection.UpdateAnim1: Clear Data's answer animated; at its end, chosen.
func _update_anim_1() -> void:
	update_obj_anim(W_MENU_OBJ_1, TITLE_BANK)
	if r3(W_OBJ_ANIM_WAS_RESET) != 0:
		_set_select_flag()


## HandleStartMenuSelection.UpdateAnim2: every other loop the highlight's palette steps (3, 0, 1, 0 by
## its count, kept in wMenuObj1FramesetOffset) until the count reaches $10, then the option is chosen.
func _update_anim_2() -> void:
	if (sim.wGlobalCounter & 1) != 0:
		return
	var count: int = r3(W_MENU_OBJ_1 + OBJ_FRAMESET_OFFSET)
	if count == 0x10:
		_set_select_flag()
		return
	w3(W_MENU_OBJ_1 + OBJ_FRAMESET_OFFSET, count + 1)
	w3(W_MENU_OBJ_1 + OBJ_ATTRIBUTES, [3, 0, 1, 0][count & 0x03])


func _set_select_flag() -> void:
	w3(W_START_MENU_SELECTION, r3(W_START_MENU_SELECTION) | STARTMENUF_SELECT)
	w3(W_MENU_OBJ_1 + OBJ_FRAMESET_OFFSET, 0)


# --- the sprites (load_oam.asm) ---

## LoadStartMenuSprite: an object from OAM_6b5f at its position (y less the scroll).
func load_start_menu_sprite(obj: int) -> void:
	_load_obj_sprite(OAM_START_MENU, obj)


## LoadIntroSprite: an object from OAM_6d21 at its position (y less the scroll).
func load_intro_sprite(obj: int) -> void:
	_load_obj_sprite(OAM_INTRO, obj)


func _load_obj_sprite(table: String, obj: int) -> void:
	load_sprite(table, r3(obj + OBJ_FRAME), byte(r3(obj + OBJ_Y) + OAM_Y_OFS - sim.wSCY),
			byte(r3(obj + OBJ_X) + OAM_X_OFS), r3(obj + OBJ_ATTRIBUTES))


# --- helpers ---

## wTimer as a little-endian word.
func _timer() -> int:
	return r0(W_TIMER) | (r0(W_TIMER + 1) << 8)


func _set_timer(value: int) -> void:
	w0(W_TIMER, value)
	w0(W_TIMER + 1, value >> 8)


## LoadPalsToTempPals1 or 2: a palette set's $40 bytes from title.json to `address`.
func _load_pals(key: String, address: int) -> void:
	var pals: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(key, "")).hex_decode()
	if pals.size() != 0x40:
		_note("palettes %s not extracted" % key)
		return
	for offset: int in 0x40:
		w0(address + offset, pals[offset])
