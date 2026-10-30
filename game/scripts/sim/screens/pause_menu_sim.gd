class_name PauseMenuSim
extends MenuScreenSim
## The pause menu's state table (src/engine/pause/), ported by translation (WL3-052) as far as the
## owner's movies need it: the pause menu (sub-states 0-7: the fades, InitPauseMenu, UpdatePauseMenu
## with HandlePauseMenuInput, ExitPauseMenu, ReturnToPendingLevelState), the level's save from it
## (SST_PAUSE_MENU_SAVE, 8-$10: InitSaveScreen, the progress bar, SaveLevel, the complete box, and
## the reset after it, Init: LevelSim.init_game), and the map's save screen, which the game runs in
## this table at SST_PAUSE_18 without showing a menu (the fades, InitSaveScreenAndBackupVRAM, the
## progress bar, Save, the complete box, and the way back to the map). Action Help from the menu
## (OpenActionHelp) and back (return_from_action_help). Its RAM is MenuScreenSim's with SRAM bank 0, where the saves write, and the SRAM
## SaveLevel backs the level's map up into (bank 2's second half and bank 3; the map itself, SRAM bank
## 1 and bank 2's first half, is the LevelSim's LevelCollision).

# WRAM0 (src/ram/wram.asm)
const W_SAVE_COUNTER: int = 0xCA00
const W_LEVEL: int = 0xCA06
const W_LEVEL_TIME_ATTACK_SCORES: int = 0xCA07
const W_DAY_NIGHT: int = 0xCA3B
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_KEY_AND_TREASURE_FLAGS: int = 0xCA5B
const W_TRANSFORMATION: int = 0xCA8E
const WCAA1: int = 0xCAA1
const W_UNUSED_IS_PAUSED: int = 0xCED6
const W_BG_MAP_TILE_VRAM0_QUEUE: int = 0xCE01
const W_SRAM_BANK: int = 0xC08E
const W_TEMP_BANK: int = 0xC0AC
const W_TRANSITION_PARAM: int = 0xCEE3
const W_CEE4: int = 0xCEE4
const W_TIMER: int = 0xCEE5
const W_CHECKSUM: int = 0xCEE7
const W_TEMP_PALS_1: int = 0xC000
# WRAMX banks 2 and 3: the treasures (to wOWLevel), and the backup of the screen's palettes and scroll.
const W_TREASURES_COLLECTED: int = 0xD000
const W3D280: int = 0xD280
const W3D500: int = 0xD500
const W3D501: int = 0xD501
# WRAMX bank 3 (GFX RAM, which PauseMenuStateTable maps): the level's animated tiles kept while the
# menu shows, Time Attack's score, the selection, and the menu's objects.
const W_TEMP_ANIMATED_TILES_FRAME_DURATION: int = 0xD50F
const W_TEMP_ANIMATED_TILES_GROUP: int = 0xD510
const W3D511: int = 0xD511
const W_PAUSE_MENU_SELECTION: int = 0xD513
const W_MENU_OBJ_2: int = 0xD52B
const W_MENU_OBJ_3: int = 0xD533
const W_MENU_OBJ_4: int = 0xD53B
const W_MENU_OBJ_5: int = 0xD547
const W_MENU_OBJ_6: int = 0xD553
const W_MENU_OBJ_7: int = 0xD55E
const W_MENU_OBJ_8: int = 0xD56A
const W_MENU_OBJ_9: int = 0xD572
const W_MENU_OBJ_10: int = 0xD57A
const W_MENU_OBJ_11: int = 0xD582
# SRAM bank 0 (src/ram/sram.asm): the game data and its backup, each after its check values, the
# checksums with two echoes each, and the save's progress markers.
const S_CHECK_VALS: int = 0xA380
const S_GAME_DATA: int = 0xA384
const S_BACKUP_CHECK_VALS: int = 0xAB80
const S_BACKUP_GAME_DATA: int = 0xAB84
const S0A790: int = 0xA790
const S_GAME_DATA_CHECKSUM: int = 0xA791
const S_BACKUP_GAME_DATA_CHECKSUM: int = 0xA793
const S0A7E0: int = 0xA7E0
const S_GAME_DATA_CHECKSUM_ECHO1: int = 0xA7E1
const S_BACKUP_GAME_DATA_CHECKSUM_ECHO1: int = 0xA7E3
const S0AFA0: int = 0xAFA0
const S_GAME_DATA_CHECKSUM_ECHO2: int = 0xAFA1
const S_BACKUP_GAME_DATA_CHECKSUM_ECHO2: int = 0xAFA3
# SaveLevel's: the level's state four times (each after its check values), each copy's checksum with
# two echoes, and the level map's checksum before and after its backup, with two echoes each.
const S0A000: int = 0xA000
const S0A400: int = 0xA400
const S0A800: int = 0xA800
const S0AC00: int = 0xAC00
const S_WRAM_CHECKSUM: int = 0xA795
const S_BACKUP1_WRAM_CHECKSUM: int = 0xA797
const S_BACKUP2_WRAM_CHECKSUM: int = 0xA799
const S_BACKUP3_WRAM_CHECKSUM: int = 0xA79B
const S0A79D: int = 0xA79D
const S0A79F: int = 0xA79F
const S_WRAM_CHECKSUM_ECHO1: int = 0xA7E5
const S_BACKUP1_WRAM_CHECKSUM_ECHO1: int = 0xA7E7
const S_BACKUP2_WRAM_CHECKSUM_ECHO1: int = 0xA7E9
const S_BACKUP3_WRAM_CHECKSUM_ECHO1: int = 0xA7EB
const S0A7ED: int = 0xA7ED
const S0A7EF: int = 0xA7EF
const S_WRAM_CHECKSUM_ECHO2: int = 0xAFA5
const S_BACKUP1_WRAM_CHECKSUM_ECHO2: int = 0xAFA7
const S_BACKUP2_WRAM_CHECKSUM_ECHO2: int = 0xAFA9
const S_BACKUP3_WRAM_CHECKSUM_ECHO2: int = 0xAFAB
const S0AFAD: int = 0xAFAD
const S0AFAF: int = 0xAFAF
# SRAM banks 1 to 3: the level's map (a 256-byte page a row, 32 rows a bank; 48 rows), its backup.
const S_LEVEL_BLOCK_OBJECT_MAP: int = 0xA000
const S2A000: int = 0xA000
const S2B000: int = 0xB000
const S3A000: int = 0xA000

# src/constants/: the sizes a save copies, its check values ("war3"), and the states after it.
const PROGRESS_WRAM_SIZE: int = 0x5B  # SIZEOF("Progress WRAM")
const LEVEL_WRAM_SIZE: int = 0x6F  # SIZEOF("Level WRAM"), after it
const LEVEL_OBJECTS_WRAM_SIZE: int = 0x14A  # SIZEOF("Level Objects WRAM"), WRAMX bank 1 from wObjects
const TREASURES_SIZE: int = 0x11  # wTreasuresCollected to wOWLevel's second byte
const CHECKVAL1: Array = [0x77, 0x61, 0x72, 0x33]
const CHECKVAL2: Array = [0x57, 0x41, 0x52, 0x33]
## The level map's rows SaveLevel sums and backs up: SRAM bank 1's 32 and bank 2's first 16.
const LEVEL_MAP_ROWS: int = 48
const SST_PAUSE_INIT_MENU: int = 0x01
const SST_PAUSE_MENU_SAVE: int = 0x08
const SST_RESET_AFTER_PAUSE_MENU_SAVE: int = 0x10
const SST_PAUSE_18: int = 0x18
const SST_PAUSE_28: int = 0x28  # the save the Perfect screen leads to, then ResetAfterSave
const SST_RESET_AFTER_SAVE: int = 0x31
const ST_OVERWORLD: int = 0x01
const ST_LEVEL: int = 0x02
const ST_ACTION_HELP: int = 0x07
const ST_CREDITS: int = 0x09
const ST_GAME_OVER: int = 0x0C
const TRANSITION_EPILOGUE_NOT_PERFECT: int = 0xF1
const TRANSITION_EPILOGUE_PERFECT: int = 0xF2
const TRANSITION_GAME_OVER: int = 0xF3
const TRANSITION_RETURN_TO_MAP: int = 0xF0
const MODE_TIME_ATTACK: int = 0x02
## wKeyAndTreasureFlags: the keys (grey, red, green, blue) in bits 0-3, the treasures in bits 4-7.
const GREY_KEY: int = 1 << 0
const RED_KEY: int = 1 << 1
const GREEN_KEY: int = 1 << 2
const BLUE_KEY: int = 1 << 3
const GREY_TREASURE: int = 1 << 4
const RED_TREASURE: int = 1 << 5
const GREEN_TREASURE: int = 1 << 6
const BLUE_TREASURE: int = 1 << 7
## wPauseMenuSelection: the button highlighted, and bit 7 once A or B chose.
const PAUSEMENU_RETURN: int = 0
const PAUSEMENU_SAVE: int = 1
const PAUSEMENU_ACTION_HELP: int = 2
const PAUSEMENU_TO_MAP: int = 3
const PAUSEMENUF_B_PAD_SELECT: int = 1 << 7
## The bank the table runs in: UpdateObjAnim's framesets and LoadPauseMenuSprite's OAM_1f156c.
const MENU_BANK: int = 0x7C
const OAM_PAUSE_MENU: String = "7c:556c"
const PAUSE_MENU_PALS_1: String = "7d:4182"  # Pals_1f4182 (LoadPauseMenuPals)
const PAUSE_MENU_PALS_2: String = "7d:41c2"  # Pals_1f41c2
## The menu's framesets (bank $7c): the buttons highlighted and chosen, Wario, the keys, the treasures.
const FRAMESET_1F1C4A: int = 0x5C4A
const FRAMESET_1F1C4D: int = 0x5C4D
const FRAMESET_1F1C50: int = 0x5C50
const FRAMESET_1F1C69: int = 0x5C69
const FRAMESET_1F1C74: int = 0x5C74
const FRAMESET_1F1C77: int = 0x5C77
const FRAMESET_1F1C9C: int = 0x5C9C
const FRAMESET_1F1C9F: int = 0x5C9F
const FRAMESET_1F1CB8: int = 0x5CB8
const FRAMESET_1F1CBB: int = 0x5CBB
const FRAMESET_1F1CD4: int = 0x5CD4
const FRAMESET_1F1CED: int = 0x5CED
const FRAMESET_1F1CF0: int = 0x5CF0
const FRAMESET_1F1CF3: int = 0x5CF3
const FRAMESET_1F1CF6: int = 0x5CF6
const FRAMESET_1F1CF9: int = 0x5CF9
const FRAMESET_1F1D0A: int = 0x5D0A
const FRAMESET_1F1D1B: int = 0x5D1B
const FRAMESET_1F1D20: int = 0x5D20
const FRAMESET_1F1D41: int = 0x5D41
const FRAMESET_1F1D4C: int = 0x5D4C
## InitPauseMenu's keys (wMenuObj4-7, shown when collected): the flag, y, x, attributes, frameset.
const KEY_OBJECTS: Array = [
	[W_MENU_OBJ_4, GREY_KEY, 0x54, 0x38, 0x03, FRAMESET_1F1C4A],
	[W_MENU_OBJ_5, RED_KEY, 0x54, 0x48, 0x03, FRAMESET_1F1C4D],
	[W_MENU_OBJ_6, GREEN_KEY, 0x54, 0x58, 0x04, FRAMESET_1F1C4A],
	[W_MENU_OBJ_7, BLUE_KEY, 0x54, 0x68, 0x04, FRAMESET_1F1C4D],
]
## Its treasures (wMenuObj8-11, always): the flag, y, x, attributes, frameset when collected and not.
const TREASURE_OBJECTS: Array = [
	[W_MENU_OBJ_8, GREY_TREASURE, 0x64, 0x38, 0x03, FRAMESET_1F1CF0, FRAMESET_1F1CED],
	[W_MENU_OBJ_9, RED_TREASURE, 0x64, 0x48, 0x03, FRAMESET_1F1CF6, FRAMESET_1F1CF3],
	[W_MENU_OBJ_10, GREEN_TREASURE, 0x64, 0x58, 0x04, FRAMESET_1F1CF0, FRAMESET_1F1CED],
	[W_MENU_OBJ_11, BLUE_TREASURE, 0x64, 0x68, 0x04, FRAMESET_1F1CF6, FRAMESET_1F1CF3],
]
const SAVE_SCREEN_PALS: String = "7d:628c"  # Pals_1f628c
const WARIO_SLEEP_GFX_BANK: int = 0x76  # LoadSaveScreenGfx's wTempBank
## The save screen's bar: BG map 0's entry ($9964) the first filled tile goes to.
const BAR_FIRST_ENTRY: int = 0x9964

## The V-Blank functions: the save screen's (the bar's queued tile, and the OAM), Save's and
## SaveLevel's (the OAM only), and the pause menu's (the scroll and the OAM).
enum VBlankFunc { NONE, SAVE_SCREEN, SAVING, PAUSE_MENU }

## WRAM0 variables the level does not use, in the screens' shared WRAM0.
var wSRAMBank: int:
	get:
		return r0(W_SRAM_BANK)
	set(value):
		w0(W_SRAM_BANK, value)
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)
## For drawing: what the last loop's V-Blank wrote to VRAM ([bank, address, value]).
var vblank_writes: Array = []


func _init(level_sim: LevelSim = null, shared_wram: Variant = null) -> void:
	super(level_sim, shared_wram)
	for bank: int in [2, 3]:  # SaveLevel's backup of the level's map (Func_1f14c6)
		var bytes := PackedByteArray()
		bytes.resize(0x2000)
		sram[bank] = bytes


## One game loop: _PauseMenuStateTable by wSubState, then what its V-Blank function writes.
func update() -> void:
	loops += 1
	screen_loads.clear()
	vblank_writes.clear()
	match sim.wSubState:
		0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E, 0x18, 0x1A, 0x1C, 0x1E, 0x20, 0x28, 0x2A, 0x2C, 0x2E, 0x30:
			fade(2)  # SlowFadeBGToWhite and DarkenBGToPal_Fast
		0x01:
			init_pause_menu()
		0x03:
			update_pause_menu()
		0x05:
			exit_pause_menu()
		0x07:
			return_to_pending_level_state()
		0x09:
			init_save_screen()
		0x0B, 0x1B, 0x2B:
			fill_save_screen_bar()
		0x0D:
			save_level()
		0x0F, 0x1F, 0x2F:
			handle_save_complete_box()
		SST_RESET_AFTER_PAUSE_MENU_SAVE:
			sim.request_init()  # ResetAfterPauseMenuSave: Init
		0x19, 0x29:
			init_save_screen_and_backup_vram()
		0x1D, 0x2D:
			save()
		0x21:
			transition_after_save()
		SST_RESET_AFTER_SAVE:
			sim.request_init()  # ResetAfterSave: Init (the save after the Perfect screen, SST_PAUSE_28)
		_:
			_note("_PauseMenuStateTable sub-state %d (DebugReset or the title's save, not ported)" % sim.wSubState)
	if vblank_func == VBlankFunc.SAVE_SCREEN and (r0(W_CEE4) & 0x80) != 0:
		# VBlank_SaveScreen: the bar's next tile (tile $02, palette 5) at the queued entry
		var address: int = (r0(W_BG_MAP_TILE_VRAM0_QUEUE) << 8) | r0(W_BG_MAP_TILE_VRAM0_QUEUE + 1)
		vblank_writes.append([1, address, 0x05])
		vblank_writes.append([0, address, 0x02])
		w0(W_CEE4, r0(W_CEE4) & 0x7F)


# --- the pause menu (pause_menu_1.asm, pause_menu_2.asm, bank7d.asm) ---

## InitPauseMenu: the level's screen backed up (SaveBackupVRAM) and its animated tiles kept
## (wTempAnimatedTilesFrameDuration, wTempAnimatedTilesGroup), then the menu set up.
func init_pause_menu() -> void:
	save_backup_vram()
	w3(W_TEMP_ANIMATED_TILES_FRAME_DURATION, sim.wAnimatedTilesFrameDuration)
	w3(W_TEMP_ANIMATED_TILES_GROUP, sim.wAnimatedTilesGfx)
	init_pause_menu_skip_backup_vram()


## InitPauseMenu_SkipBackupVRAM: Return highlighted, the room's animated tiles stopped, the menu's
## palettes (LoadPauseMenuPals) and screen (LoadPauseMenuGfx, Func_1f403f, the counts: drawing; in Time
## Attack Func_1f403f keeps the level's best time in w3d511), VBlank_PauseMenu, the scroll cleared, and
## the menu's objects set up and drawn: the highlight on Return, Wario, the keys collected, and the
## treasures (collected or not). The music is not ported.
func init_pause_menu_skip_backup_vram() -> void:
	w3(W_PAUSE_MENU_SELECTION, PAUSEMENU_RETURN)
	sim.wRoomAnimatedTilesEnabled = 0
	clear_virtual_oam()
	_load_pals(PAUSE_MENU_PALS_1, W_TEMP_PALS_1)
	_load_pals(PAUSE_MENU_PALS_2, W_TEMP_PALS_1 + 0x40)
	screen_loads.append(["pause_menu"])
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0:
		var score: int = W_LEVEL_TIME_ATTACK_SCORES + ((r0(W_LEVEL) >> 3) << 1)
		w3(W3D511, r0(score))
		w3(W3D511 + 1, r0(score + 1))
	vblank_func = VBlankFunc.PAUSE_MENU
	sim.wSCY = 0
	sim.wSCX = 0
	_set_up_menu_obj(W_MENU_OBJ_2, 0x38, 0x20, 0, FRAMESET_1F1CB8)
	_animate(W_MENU_OBJ_2)
	_set_up_menu_obj(W_MENU_OBJ_3, 0x8C, 0x20, 0, FRAMESET_1F1CD4)
	_animate(W_MENU_OBJ_3)
	for key: Array in KEY_OBJECTS:
		if (r0(W_KEY_AND_TREASURE_FLAGS) & int(key[1])) != 0:
			_set_up_menu_obj(int(key[0]), int(key[2]), int(key[3]), int(key[4]), int(key[5]))
			_animate(int(key[0]))
	for treasure: Array in TREASURE_OBJECTS:
		var collected: bool = (r0(W_KEY_AND_TREASURE_FLAGS) & int(treasure[1])) != 0
		_set_up_menu_obj(int(treasure[0]), int(treasure[2]), int(treasure[3]), int(treasure[4]),
				int(treasure[5]) if collected else int(treasure[6]))
		_animate(int(treasure[0]))
	sim.wSubState = byte(sim.wSubState + 1)


## UpdatePauseMenu: the input, Wario animated, the keys and treasures drawn, the highlight animated,
## and the OAM's rest cleared. Once A or B chose and the highlight's frameset ended, the choice:
## Return (the next sub-state, ExitPauseMenu's fade), Save (resets held off, SST_PAUSE_MENU_SAVE), To
## Map (ReturnToMapFromLevel), or Action Help (OpenActionHelp, not ported).
func update_pause_menu() -> void:
	handle_pause_menu_input()
	update_obj_anim(W_MENU_OBJ_3, MENU_BANK)
	load_pause_menu_sprite(W_MENU_OBJ_3)
	for key: Array in KEY_OBJECTS:
		if (r0(W_KEY_AND_TREASURE_FLAGS) & int(key[1])) != 0:
			load_pause_menu_sprite(int(key[0]))
	for treasure: Array in TREASURE_OBJECTS:
		load_pause_menu_sprite(int(treasure[0]))
	update_obj_anim(W_MENU_OBJ_2, MENU_BANK)
	load_pause_menu_sprite(W_MENU_OBJ_2)
	clear_unused_virtual_oam()
	var selection: int = r3(W_PAUSE_MENU_SELECTION)
	if (selection & PAUSEMENUF_B_PAD_SELECT) == 0 or r3(W_OBJ_ANIM_WAS_RESET) == 0:
		return
	match selection & 0x0F:
		PAUSEMENU_TO_MAP:
			return_to_map_from_level()
		PAUSEMENU_SAVE:
			sim.wResetDisabled = 1
			sim.wSubState = SST_PAUSE_MENU_SAVE
		PAUSEMENU_ACTION_HELP:
			sim.wState = ST_ACTION_HELP  # OpenActionHelp
			sim.wSubState = 0
		_:
			sim.wSubState = byte(sim.wSubState + 1)


## HandlePauseMenuInput: nothing once a button is chosen; B chooses Return. Otherwise left and right
## move the highlight between Return, Save (not in Time Attack), Action Help, and To Map, and A
## chooses the button highlighted. The sound effects are not ported.
func handle_pause_menu_input() -> void:
	var selection: int = r3(W_PAUSE_MENU_SELECTION)
	if (selection & PAUSEMENUF_B_PAD_SELECT) != 0:
		return
	var pressed: int = sim.wJoypadPressed
	if (pressed & WarioRam.PAD_B) != 0:
		_choose_return()
		return
	var time_attack: bool = (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0
	if selection == PAUSEMENU_SAVE:
		if (pressed & WarioRam.PAD_LEFT) != 0:
			_highlight(PAUSEMENU_RETURN)
		elif (pressed & WarioRam.PAD_RIGHT) != 0:
			_highlight(PAUSEMENU_ACTION_HELP)
		elif (pressed & WarioRam.PAD_A) != 0:
			_choose(FRAMESET_1F1C9F)
	elif selection == PAUSEMENU_ACTION_HELP:
		if (pressed & WarioRam.PAD_LEFT) != 0:
			_highlight(PAUSEMENU_RETURN if time_attack else PAUSEMENU_SAVE)
		elif (pressed & WarioRam.PAD_RIGHT) != 0:
			_highlight(PAUSEMENU_TO_MAP)
		elif (pressed & WarioRam.PAD_A) != 0:
			_choose(_by_transformation([FRAMESET_1F1D0A, FRAMESET_1F1D20, FRAMESET_1F1D4C, FRAMESET_1F1C69]))
	elif selection == PAUSEMENU_TO_MAP:
		if (pressed & WarioRam.PAD_LEFT) != 0:
			_highlight(PAUSEMENU_ACTION_HELP)
		elif (pressed & WarioRam.PAD_A) != 0:
			_choose(FRAMESET_1F1C77)
	elif (pressed & WarioRam.PAD_RIGHT) != 0:
		_highlight(PAUSEMENU_ACTION_HELP if time_attack else PAUSEMENU_SAVE)
	elif (pressed & WarioRam.PAD_A) != 0:
		_choose_return()


## HandlePauseMenuInput's .highlight_*_button: the selection, and the highlight (wMenuObj2) set up
## anew over the button: Save's, Action Help's (by the transformation), To Map's, or Return's.
func _highlight(selection: int) -> void:
	w3(W_PAUSE_MENU_SELECTION, selection)
	match selection:
		PAUSEMENU_SAVE:
			set_up_obj(W_MENU_OBJ_2, 0x40, 0x40, FRAMESET_1F1C9C)
		PAUSEMENU_ACTION_HELP:
			set_up_obj(W_MENU_OBJ_2, 0x38, 0x60,
					_by_transformation([FRAMESET_1F1CF9, FRAMESET_1F1D1B, FRAMESET_1F1D41, FRAMESET_1F1C50]))
		PAUSEMENU_TO_MAP:
			set_up_obj(W_MENU_OBJ_2, 0x40, 0x80, FRAMESET_1F1C74)
		_:
			set_up_obj(W_MENU_OBJ_2, 0x38, 0x20, FRAMESET_1F1CB8)


## HandlePauseMenuInput.Return: Return highlighted and chosen (wMenuObj2 set up anew over it).
func _choose_return() -> void:
	w3(W_PAUSE_MENU_SELECTION, PAUSEMENU_RETURN)
	set_up_obj(W_MENU_OBJ_2, 0x38, 0x20, FRAMESET_1F1CBB)
	w3(W_PAUSE_MENU_SELECTION, r3(W_PAUSE_MENU_SELECTION) | PAUSEMENUF_B_PAD_SELECT)


## HandlePauseMenuInput's .Save, .ActionHelp, .ToMap: the highlight's frameset started over as
## `frameset` where it is, and the button chosen.
func _choose(frameset: int) -> void:
	w3(W_MENU_OBJ_2 + OBJ_FRAMESET_OFFSET, 0)
	w3(W_MENU_OBJ_2 + OBJ_DURATION, 0)
	_set_frameset(W_MENU_OBJ_2, frameset)
	w3(W_PAUSE_MENU_SELECTION, r3(W_PAUSE_MENU_SELECTION) | PAUSEMENUF_B_PAD_SELECT)


## Of [Owl Wario's, Rail's, Vampire Wario's, the others'], the one for wTransformation.
func _by_transformation(framesets: Array) -> int:
	match r0(W_TRANSFORMATION):
		WarioRam.TRANSFORMATION_OWL_WARIO:
			return int(framesets[0])
		WarioRam.TRANSFORMATION_RAIL:
			return int(framesets[1])
		WarioRam.TRANSFORMATION_VAMPIRE_WARIO:
			return int(framesets[2])
	return int(framesets[3])


## ReturnToMapFromLevel (src/home/return_level.asm): wDayNight's bit 7 set, then ReturnToMap: the
## transition back to the map, and StartOverworldState (the map from its sub-state 0).
func return_to_map_from_level() -> void:
	w0(W_DAY_NIGHT, r0(W_DAY_NIGHT) | 0x80)
	w0(W_TRANSITION_PARAM, TRANSITION_RETURN_TO_MAP)
	sim.wState = ST_OVERWORLD
	sim.wSubState = 0


## ExitPauseMenu: the OAM cleared and the level's objects and Wario drawn again
## (DrawLevelObjectsAfterLevelReturn, with the level's V-Blank function; the sprites they add to the
## virtual OAM are not kept, as the level's port keeps none; DrawWario's far call leaves wTempBank on
## Wario's OAM bank when he is shown), the level's screen back (LoadBackupVRAM), wUnused_IsPaused
## cleared, and the room's animated tiles back from their first frame. The music is not ported.
func exit_pause_menu() -> void:
	clear_virtual_oam()
	vblank_func = VBlankFunc.NONE  # VBlank_Level
	sim.draw_objects()
	sim.draw_wario()
	if not sim.drawn_wario.is_empty():
		wTempBank = sim.wWarioOAMBank
	load_backup_vram()
	w0(W_UNUSED_IS_PAUSED, 0)
	sim.wAnimatedTilesFrameDuration = r3(W_TEMP_ANIMATED_TILES_FRAME_DURATION)
	sim.wAnimatedTilesGfx = r3(W_TEMP_ANIMATED_TILES_GROUP)
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	sim.wRoomAnimatedTilesEnabled = 1
	sim.wSubState = byte(sim.wSubState + 1)


## The pause menu's half of _ReturnToPauseMenuFromActionHelp, run in Action Help's last loop (whose
## state set the pause menu's, SST_PAUSE_INIT_MENU): InitPauseMenu_SkipBackupVRAM, as a loop of its own
## for drawing (the menu's screen loads).
func return_from_action_help() -> void:
	loops += 1
	screen_loads.clear()
	vblank_writes.clear()
	init_pause_menu_skip_backup_vram()


## ReturnToPendingLevelState (src/home/return_level.asm): the level at wPendingSubState.
func return_to_pending_level_state() -> void:
	sim.wState = ST_LEVEL
	sim.wSubState = sim.wPendingSubState


## LoadPauseMenuSprite: the object's frame of OAM_1f156c at its place, with its attributes.
func load_pause_menu_sprite(obj: int) -> void:
	load_sprite(OAM_PAUSE_MENU, r3(obj + OBJ_FRAME), (r3(obj + OBJ_Y) + OAM_Y_OFS) & 0xFF,
			(r3(obj + OBJ_X) + OAM_X_OFS) & 0xFF, r3(obj + OBJ_ATTRIBUTES))


## A menu object set up as InitPauseMenu does: its place, attributes, and frameset, its frame,
## offset, and duration cleared.
func _set_up_menu_obj(obj: int, y: int, x: int, attributes: int, frameset: int) -> void:
	set_up_obj(obj, y, x, frameset)
	w3(obj + OBJ_ATTRIBUTES, attributes)


## UpdateObjAnim (in the table's bank), then LoadPauseMenuSprite.
func _animate(obj: int) -> void:
	update_obj_anim(obj, MENU_BANK)
	load_pause_menu_sprite(obj)


## LoadPalsToTempPals1 or 2: a palette set (64 bytes) from pause_menu.json to `at`.
func _load_pals(key: String, at: int) -> void:
	var bytes: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(key, "")).hex_decode()
	for offset: int in 0x40:
		w0(at + offset, bytes[offset] if offset < bytes.size() else 0)


# --- the level's save from the pause menu (SST_PAUSE_MENU_SAVE, save/save.asm) ---

## InitSaveScreen: as InitSaveScreenAndBackupVRAM without the backup (the pause menu made it) and
## without clearing BG map 1: resets held off, the save screen loaded, the scroll and the bar's
## counters cleared, and the bar's first entry queued.
func init_save_screen() -> void:
	sim.wResetDisabled = 1
	clear_virtual_oam()
	load_save_screen_pals()
	wTempBank = WARIO_SLEEP_GFX_BANK  # LoadSaveScreenGfx
	screen_loads.append(["level_save_in_progress"])
	vblank_func = VBlankFunc.SAVE_SCREEN
	sim.wSCY = 0
	sim.wSCX = 0
	sim.wPalFadeCounter = 0
	w0(W_CEE4, 0)
	w0(W_TIMER, 0)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE, BAR_FIRST_ENTRY >> 8)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE + 1, BAR_FIRST_ENTRY & 0xFF)
	sim.wSubState = byte(sim.wSubState + 1)


## SaveLevel: the level's OBJ palettes kept (w3d280's palettes 12-15 to wcaa1), the save counter on,
## then into SRAM bank 0 four times (s0a000, s0a800, s0a400, s0ac00) "WAR3", the progress and level
## WRAM, the treasures, and the level's objects (Level Objects WRAM), each copy's checksum (also
## wChecksum, CalculateWRAMDataChecksum) with its two echoes; after the first copy the level map's
## checksum (CalculateBackupSRAMChecksum1) and before the last the map's backup (Func_1f14c6), each
## with two echoes. The progress markers ($30 to $83) are left at 0, resets allowed again, and the
## complete box shown for 512 loops. Without the level map's every byte known it is not run.
func save_level() -> void:
	var map: PackedByteArray = _level_map_sram()
	if map.is_empty():
		_note("SaveLevel: the level map's SRAM not known whole")
		return
	for offset: int in 0x20:
		w0(WCAA1 + offset, r3(W3D280 + 12 * 8 + offset))
	increment_save_counter()
	var data := PackedByteArray(CHECKVAL2)
	for offset: int in PROGRESS_WRAM_SIZE + LEVEL_WRAM_SIZE:
		data.append(r0(W_SAVE_COUNTER + offset))
	for offset: int in TREASURES_SIZE:
		data.append(rx(2, W_TREASURES_COLLECTED + offset))
	data.append_array(sim.wram1.slice(0, LEVEL_OBJECTS_WRAM_SIZE))
	var checksum: int = calculate_wram_data_checksum(data)
	for at: int in [S0A000, S0A800, S0A400, S0AC00]:
		for offset: int in data.size():
			ws(0, at + offset, data[offset])
	for at: int in [S_WRAM_CHECKSUM, S_BACKUP1_WRAM_CHECKSUM, S_BACKUP2_WRAM_CHECKSUM, S_BACKUP3_WRAM_CHECKSUM,
			S_WRAM_CHECKSUM_ECHO1, S_BACKUP1_WRAM_CHECKSUM_ECHO1, S_BACKUP2_WRAM_CHECKSUM_ECHO1,
			S_BACKUP3_WRAM_CHECKSUM_ECHO1, S_WRAM_CHECKSUM_ECHO2, S_BACKUP1_WRAM_CHECKSUM_ECHO2,
			S_BACKUP2_WRAM_CHECKSUM_ECHO2, S_BACKUP3_WRAM_CHECKSUM_ECHO2]:
		ws(0, at, checksum >> 8)
		ws(0, at + 1, checksum)
	var map_checksum: int = _sum(map)
	for at: int in [S0A79D, S0A7ED, S0AFAD]:
		ws(0, at, map_checksum >> 8)
		ws(0, at + 1, map_checksum)
	func_1f14c6(map)
	sim.level_map_sram = LevelSim.LevelMapSram.SAVED
	w0(W_CHECKSUM, checksum >> 8)
	w0(W_CHECKSUM + 1, checksum)
	for at: int in [S0A790, S0A7E0, S0AFA0]:
		ws(0, at, 0)
	sim.wResetDisabled = 0
	vblank_func = VBlankFunc.SAVING
	load_save_screen_pals()
	screen_loads.append(["save_complete"])
	w0(W_TIMER, 0)
	w0(W_TIMER + 1, 512 >> 8)
	sim.wSubState = byte(sim.wSubState + 1)


## CalculateWRAMDataChecksum over a SaveLevel copy (after its check values): the progress and level
## WRAM and the treasures (CalculateChecksum), then CalculateChecksumLong over the objects, whose loop
## goes back to CalculateChecksum by mistake: it sums the first byte, then B more (BC $14a less one: B
## is 1). The routines are SaveLoad's, which the load shares.
func calculate_wram_data_checksum(data: PackedByteArray) -> int:
	var de_hl: Array = SaveLoad.calculate_checksum(data, 4, PROGRESS_WRAM_SIZE + LEVEL_WRAM_SIZE, 0)
	de_hl = SaveLoad.calculate_checksum(data, int(de_hl[1]), TREASURES_SIZE, int(de_hl[0]))
	return int(SaveLoad.calculate_checksum_long(data, int(de_hl[1]), LEVEL_OBJECTS_WRAM_SIZE, int(de_hl[0]))[0])


## Func_1f14c6: SRAM bank 2's first half copied to its second (S2B000) and bank 1 to bank 3, the
## level map's rows 48-63 taking the copy (what LevelCollision keeps of them), and the backup's checksum
## (CalculateBackupSRAMChecksum2: bank 3 and bank 2's second half) with two echoes.
func func_1f14c6(map: PackedByteArray) -> void:
	for offset: int in 0x1000:
		ws(2, S2B000 + offset, map[0x2000 + offset])
	for offset: int in 0x2000:
		ws(3, S3A000 + offset, map[offset])
	for row: int in range(LEVEL_MAP_ROWS, LevelCollision.HEIGHT):
		for column: int in LevelCollision.OBJECT_MAP_OFFSET:
			sim.level.set_block(row, column, rs(2, S2B000 + (row - LEVEL_MAP_ROWS) * 0x100 + column))
	var backup: PackedByteArray = sram[3].duplicate()
	backup.append_array(sram[2].slice(S2B000 - 0xA000, 0x2000))
	var checksum: int = _sum(backup)
	for at: int in [S0A79F, S0A7EF, S0AFAF]:
		ws(0, at, checksum >> 8)
		ws(0, at + 1, checksum)


## SRAM bank 1 and bank 2's first half (S_LEVEL_BLOCK_OBJECT_MAP, S2A000: the level map's 48 rows of a
## 256-byte page) from the LevelSim's map, or empty when a byte of it is not known.
func _level_map_sram() -> PackedByteArray:
	return sim.level_map_bytes()


## CalculateChecksum's sum: the bytes added into a 16-bit DE.
static func _sum(bytes: PackedByteArray) -> int:
	var total: int = 0
	for value: int in bytes:
		total = (total + value) & 0xFFFF
	return total


# --- the map's save screen (SST_PAUSE_18) ---

## InitSaveScreenAndBackupVRAM: resets held off, the screen backed up (SaveBackupVRAM), the save
## screen loaded, the scroll and the bar's counters cleared, and the bar's first entry queued.
func init_save_screen_and_backup_vram() -> void:
	sim.wResetDisabled = 1
	save_backup_vram()
	clear_virtual_oam()
	load_save_screen_pals()
	wTempBank = WARIO_SLEEP_GFX_BANK  # LoadSaveScreenGfx
	screen_loads.append(["save_in_progress"])
	vblank_func = VBlankFunc.SAVE_SCREEN
	sim.wSCY = 0
	sim.wSCX = 0
	sim.wPalFadeCounter = 0
	w0(W_TIMER, 0)
	w0(W_CEE4, 0)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE, BAR_FIRST_ENTRY >> 8)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE + 1, BAR_FIRST_ENTRY & 0xFF)
	sim.wSubState = byte(sim.wSubState + 1)


## SaveBackupVRAM (src/home/backup_vram.asm): the scroll into w3d500 and w3d501 and both temporary
## palette sets into w3d280 (VRAM into WRAMX banks 4 to 7: drawing).
func save_backup_vram() -> void:
	w3(W3D500, sim.wSCY)
	w3(W3D501, sim.wSCX)
	for offset: int in 0x80:
		w3(W3D280 + offset, r0(W_TEMP_PALS_1 + offset))
	screen_loads.append(["backup_vram"])


## LoadBackupVRAM: the scroll and palettes back from the backup (VRAM too: drawing).
func load_backup_vram() -> void:
	sim.wSCY = r3(W3D500)
	sim.wSCX = r3(W3D501)
	for offset: int in 0x80:
		w0(W_TEMP_PALS_1 + offset, r3(W3D280 + offset))
	screen_loads.append(["restore_vram"])


## LoadSaveScreenPals: Pals_1f628c into both temporary palette sets.
func load_save_screen_pals() -> void:
	var bytes: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(SAVE_SCREEN_PALS,
			"")).hex_decode()
	for offset: int in 0x80:
		w0(W_TEMP_PALS_1 + offset, bytes[offset & 0x3F] if (offset & 0x3F) < bytes.size() else 0)


## FillSaveScreenBar: every 4 loops another of the bar's tiles is queued; after nine, on.
func fill_save_screen_bar() -> void:
	w0(W_TIMER, r0(W_TIMER) + 1)
	if r0(W_TIMER) < 4:
		return
	w0(W_TIMER, 0)
	var filled: int = byte(r0(W_CEE4) + 1)
	if filled == 0x0A:
		w0(W_CEE4, 0)
		sim.wSubState = byte(sim.wSubState + 1)
		return
	w0(W_CEE4, filled | 0x80)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE + 1, r0(W_BG_MAP_TILE_VRAM0_QUEUE + 1) + 1)


## Save: the save counter on, then into SRAM bank 0 the check values, the progress WRAM and the
## treasures, their checksum (also wChecksum) with its two echoes, and the same again as the backup,
## the progress markers ($10 to $23) left at 0; then the complete box for 512 loops.
func save() -> void:
	increment_save_counter()
	var data := PackedByteArray(CHECKVAL1)
	for offset: int in PROGRESS_WRAM_SIZE:
		data.append(r0(W_SAVE_COUNTER + offset))
	for offset: int in TREASURES_SIZE:
		data.append(rx(2, W_TREASURES_COLLECTED + offset))
	var checksum: int = 0
	for index: int in range(4, data.size()):
		checksum = (checksum + data[index]) & 0xFFFF
	for at: int in [S_CHECK_VALS, S_BACKUP_CHECK_VALS]:
		for offset: int in data.size():
			ws(0, at + offset, data[offset])
	w0(W_CHECKSUM, checksum >> 8)
	w0(W_CHECKSUM + 1, checksum)
	for at: int in [S_GAME_DATA_CHECKSUM, S_GAME_DATA_CHECKSUM_ECHO1, S_GAME_DATA_CHECKSUM_ECHO2,
			S_BACKUP_GAME_DATA_CHECKSUM, S_BACKUP_GAME_DATA_CHECKSUM_ECHO1, S_BACKUP_GAME_DATA_CHECKSUM_ECHO2]:
		ws(0, at, checksum >> 8)
		ws(0, at + 1, checksum)
	for at: int in [S0A790, S0A7E0, S0AFA0]:
		ws(0, at, 0)
	vblank_func = VBlankFunc.SAVING
	load_save_screen_pals()
	screen_loads.append(["save_complete"])
	w0(W_TIMER, 0)
	w0(W_TIMER + 1, 512 >> 8)
	sim.wSubState = byte(sim.wSubState + 1)


## IncrementSaveCounter: wSaveCounter's four bytes, big-endian, one on.
func increment_save_counter() -> void:
	for offset: int in [3, 2, 1, 0]:
		var value: int = r0(W_SAVE_COUNTER + offset) + 1
		w0(W_SAVE_COUNTER + offset, value)
		if value <= 0xFF:
			return


## HandleSaveCompleteBox: on with A, or when wTimer's two bytes run out.
func handle_save_complete_box() -> void:
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		w0(W_TIMER, r0(W_TIMER) - 1)
		if r0(W_TIMER) != 0:
			return
		w0(W_TIMER + 1, r0(W_TIMER + 1) - 1)
		if r0(W_TIMER + 1) != 0:
			return
	w0(W_TIMER, 0)
	w0(W_TIMER + 1, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## TransitionAfterSave: after the epilogue the credits, after a game over its screen (neither
## ported); otherwise the screen restored and the map at wPendingSubState.
func transition_after_save() -> void:
	match r0(W_TRANSITION_PARAM):
		TRANSITION_EPILOGUE_NOT_PERFECT, TRANSITION_EPILOGUE_PERFECT:
			sim.wResetDisabled = 0
			sim.wState = ST_CREDITS
			sim.wSubState = 0
		TRANSITION_GAME_OVER:
			sim.wResetDisabled = 0
			sim.wState = ST_GAME_OVER
			sim.wSubState = 0
		_:
			load_backup_vram()
			sim.wResetDisabled = 0
			sim.wState = ST_OVERWORLD
			sim.wSubState = sim.wPendingSubState
