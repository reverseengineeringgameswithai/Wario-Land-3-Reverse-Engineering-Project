class_name OverworldScenes
extends OverworldOWFunctions
## What follows a level on the map and an event's scenes (src/engine/overworld/init.asm, bank20.asm,
## bank21.asm), translated (WL3-052): InitOverworld (SST 1: the treasure just got, the event it unlocks,
## and whether its cutscene, its scene, or the map side comes next, or the save screen), InitOWScene
## (SST 5: the scene's map side set up, InitMapSideForScene_*), and the scene's loop (SST 7: Func_80540,
## its actions in turn: UNLOCK_LEVEL, DO_OW_FUNC, HIGHLIGHT_LEVEL, SPECIAL_ACTION), with the grey
## transition (OWGreyTransition), the star indicator, and VBlank_OWScene, whose RAM writes run after
## each loop. The cutscenes themselves (SST_OVERWORLD_CUTSCENE on) are not part of this.

const W2D015: int = 0xD015
const W2D018: int = 0xD018
const W_EVENT_WITH_CUTSCENE: int = 0xD01E
const W_TEMP_OW_SCENE_PARAMS_PTR: int = 0xD02A  # little-endian
const W_OW_EXIT_UNLOCKED: int = 0xDFFF  # w2dfff
const W_CUR_SCENE_OBJ_DURATION: int = 0xD184
const W_CUR_SCENE_OBJ_STATE: int = 0xD186
const CUTSCENE_BANK: int = 0x27
const CUTSCENE_INIT_FUNCTIONS: int = 0x40A8
const NO_INIT_CUTSCENE: int = 0x4000
const OVERWORLD_GLOW_GFX: int = 0x7748  # bank $22
const DATA_84E39: int = 0x4E39  # bank $21: the grey palettes by map side (East's without the ice next)
const FRAMESET_AA544: int = 0x6544  # bank $2a
const FRAMESET_AA555: int = 0x6555  # bank $2a
const OAM_AA445: int = 0x6445  # bank $2a
const CRAYON_RED_T: int = 0x5E
const CRAYON_YELLOW_T: int = 0x60
const CRAYON_PINK_T: int = 0x64
const BLUE_BOOK: int = 0x17
const MAGIC_WAND: int = 0x1C
const MYSTERY_HANDLE: int = 0x39
const EVENT_SUPER_GRAB_GLOVES: int = 0x23
const EVENT_MAGNIFYING_GLASS: int = 0x2F
const EVENT_DAY_OR_NIGHT_SPELL: int = 0x35
const EVENT_SUMMON_MOON: int = 0x57
const EVENT_EPILOGUE: int = 0x5A
const SST_OVERWORLD_FAST_FADE: int = 0x04
const SST_OVERWORLD_OW_SCENE: int = 0x05
const SST_OVERWORLD_09: int = 0x09
const SST_OVERWORLD_CUTSCENE: int = 0x11
const SST_OVERWORLD_GOLF_BUILDING: int = 0x20
const SST_OVERWORLD_EPILOGUE: int = 0x23
const ST_PERFECT: int = 0x0D
const OBPI_PALETTE_4: int = 0x80 | 0x20  # OBPI_AUTOINC | palette 4
## The V-Blank function of the scenes (VBlank_OWScene): its RAM writes run after each loop.
const VBLANK_OW_SCENE: int = 4


# --- InitOverworld (SST 1) ---

## InitOverworld: wLastTransitionParam from the transition (New Game: treasure 0 got), the room animations
## stopped, the crayons got, the map side and level from wOWLevel (the Golf Building apart), the OW WRAM
## cleared; then by the transition: the map side (none, or back to the map), the epilogue's scene, the
## save screen after a game over, the prologue, or the event the treasure unlocks: its cutscene, its
## scene, or the map side.
func init_overworld() -> void:
	w2(W_LAST_TRANSITION_PARAM, wTransitionParam)
	sim.wRoomAnimatedTilesEnabled = 0
	if r2(W_LAST_TRANSITION_PARAM) == TRANSITION_NEW_GAME:
		w2(W_TREASURES_COLLECTED, r2(W_TREASURES_COLLECTED) | 0x01)
	get_crayon_flags()
	if r2(W_OW_BARS_STATE) != OWBARS_INPUT_TOP:
		if r2(W_OW_LEVEL) >= LEVEL_GOLF_BUILDING:  # .golf_building
			w2(W_NEXT_MAP_SIDE, 0)
			w2(W_MAP_SIDE_LEVEL_ID, 0)
			sim.wSubState = SST_OVERWORLD_GOLF_BUILDING
			func_803e6()
			return
		var level: Vector2i = get_map_level_id(r2(W_OW_LEVEL))
		w2(W_NEXT_MAP_SIDE, level.x)
		w2(W_MAP_SIDE_LEVEL_ID, level.y)
	clear_ow_wram()
	match r2(W_LAST_TRANSITION_PARAM):
		0x00, TRANSITION_RETURN_TO_MAP:
			_load_map_without_scene()
			return
		TRANSITION_EPILOGUE_NOT_PERFECT, TRANSITION_EPILOGUE_PERFECT:  # .epilogue
			w2(W_STORED_TRANSITION_PARAM, TRANSITION_RETURN_TO_MAP)
			w2(W_CUR_EVENT, EVENT_EPILOGUE)
			_after_cutscene()
			return
		TRANSITION_GAME_OVER:  # .game_over
			func_803e6()
			return
		TRANSITION_NEW_GAME:
			w2(W_CUR_EVENT, EVENT_PROLOGUE)
		_:
			if not check_if_treasure_unlocks_event():
				_load_map_without_scene()
				return
	# .cutscene_check
	set_stored_transition_param_as_return_to_map()
	check_if_event_has_cutscene()
	if r2(W_EVENT_WITH_CUTSCENE) == 0:
		_after_cutscene()
		return
	update_stored_transition_param()  # .play_cutscene
	sim.wSubState = SST_OVERWORLD_CUTSCENE


## InitOverworld.after_cutscene: the event's scene (.play_ow_scene) if it has one, else the map side.
func _after_cutscene() -> void:
	if not get_ow_scene_params(r2(W_CUR_EVENT)):
		_load_map_without_scene()
		return
	update_stored_transition_param()
	sim.wSubState = SST_OVERWORLD_OW_SCENE


## InitOverworld.load_map_without_scene: no event, the map side (SST_OVERWORLD_09), and the save screen
## (Func_803e6).
func _load_map_without_scene() -> void:
	w2(W_CUR_EVENT, 0)
	sim.wSubState = SST_OVERWORLD_09
	func_803e6()


## Func_803e6: after a transition with the bars closed and Wario at a level (not an exit), the save
## screen (SaveGameOrEnterPerfectScreen).
func func_803e6() -> void:
	if wTransitionParam == 0 or r2(W_OW_BARS_STATE) != 0 or r2(W_MAP_SIDE_LEVEL_ID) >= OW_EXITS:
		return
	save_game_or_enter_perfect_screen()


## SaveGameOrEnterPerfectScreen (src/home/update_level_music.asm): the Perfect screen (ST_PERFECT) once
## the game is cleared outside Time Attack and the epilogues and game over, with wNumCollectedTreasures
## 1; else the save screen (ST_PAUSE_MENU, SST_PAUSE_18), the sub-state kept in wPendingSubState.
func save_game_or_enter_perfect_screen() -> void:
	var flags: int = r0(W_GAME_MODE_FLAGS)
	if (flags & MODE_TIME_ATTACK) == 0 and wTransitionParam not in [TRANSITION_EPILOGUE_NOT_PERFECT,
			TRANSITION_EPILOGUE_PERFECT, TRANSITION_GAME_OVER] and (flags & MODE_GAME_CLEARED) != 0 \
			and r0(W_NUM_COLLECTED_TREASURES) == 1:
		sim.wState = ST_PERFECT  # SetPerfectState
		sim.wSubState = 0
		return
	sim.wPendingSubState = sim.wSubState
	sim.wState = LevelSim.ST_PAUSE_MENU
	sim.wSubState = PauseMenuSim.SST_PAUSE_18


## GetCrayonFlags (crayon_flags.asm): the crayons' bits of wTreasuresCollected (CRAYON_RED_T to
## CRAYON_PINK_T, across two bytes) to wCrayonFlags.
func get_crayon_flags() -> void:
	var high: int = r2(W_TREASURES_COLLECTED + (CRAYON_YELLOW_T >> 3))
	var low: int = r2(W_TREASURES_COLLECTED + (CRAYON_YELLOW_T >> 3) - 1)
	w2(W_CRAYON_FLAGS, ((high << 2) | (low >> 6)) & 0x7F)


## CheckIfTreasureUnlocksEvent: the event whose treasures (EventTreasures) include wLastTransitionParam
## to wCurEvent, kept if it is now unlocked (true), else EVENT_00 (false).
func check_if_treasure_unlocks_event() -> bool:
	var treasure: int = r2(W_LAST_TRANSITION_PARAM)
	w2(W_CUR_EVENT, 0)
	var event: int = 0
	var at: int = EVENT_TREASURES
	while rb(MAP_BANK, at) != TREASURES_END:
		if treasure in [rb(MAP_BANK, at), rb(MAP_BANK, at + 1), rb(MAP_BANK, at + 2)]:
			w2(W_CUR_EVENT, event)
			if check_if_event_is_unlocked(event) != FALSE:
				return true
			break
		at += 3
		event = byte(event + 1)
	w2(W_CUR_EVENT, 0)
	return false


## SetStoredTransitionParamAsReturnToMap: with the bars closed (not a cutscene played again from the top
## bar), no cutscene to play again.
func set_stored_transition_param_as_return_to_map() -> void:
	if r2(W_OW_BARS_STATE) == 0:
		w2(W_STORED_TRANSITION_PARAM, TRANSITION_RETURN_TO_MAP)


## UpdateStoredTransitionParam: with the bars closed, the transition (unless the scene's action is
## SPECIAL_ACTION or an epilogue) to play again from the top bar.
func update_stored_transition_param() -> void:
	if r2(W_OW_BARS_STATE) != 0 or r2(W_OW_SCENE_ACTION) == SPECIAL_ACTION:
		return
	var last: int = r2(W_LAST_TRANSITION_PARAM)
	if last == TRANSITION_EPILOGUE_NOT_PERFECT or last == TRANSITION_EPILOGUE_PERFECT:
		return
	w2(W_STORED_TRANSITION_PARAM, last)


## CheckIfEventHasCutscene (bank $27): wCurEvent to wEventWithCutscene if its entry in
## CutsceneInitFunctions is not NoInitCutscene, else 0.
func check_if_event_has_cutscene() -> void:
	w2(W_EVENT_WITH_CUTSCENE, 0)
	var event: int = r2(W_CUR_EVENT)
	if pointer_from_table(CUTSCENE_BANK, CUTSCENE_INIT_FUNCTIONS, event) != NO_INIT_CUTSCENE:
		w2(W_EVENT_WITH_CUTSCENE, event)


# --- InitOWScene (SST 5) ---

## InitOWScene: the LCD off, the OW WRAM cleared, VBlank_OWScene, the virtual OAM cleared, day, the
## scene's params kept (w2d018, wTempUnlockableConnectionID, wTempOWSceneAction, wTempOWSceneParamsPtr)
## while its map side (wOWSceneMapSide) is set up.
func init_ow_scene() -> void:
	disable_lcd()
	clear_ow_wram()
	vblank_func = VBLANK_OW_SCENE
	clear_virtual_oam()
	w2(W2D011, 0)
	w2(W2D018, r2(W2D015))
	w2(W_TEMP_UNLOCKABLE_CONNECTION_ID, r2(W_OW_SCENE_ACTION_PARAM))
	w2(W_TEMP_OW_SCENE_ACTION, r2(W_OW_SCENE_ACTION))
	wr_word(W_TEMP_OW_SCENE_PARAMS_PTR, rd_word(W_OW_SCENE_PARAMS_PTR))
	var side: int = r2(W_OW_SCENE_MAP_SIDE)
	w2(W_CUR_MAP_SIDE, side)
	screen_loads.append(["ow_scene", side])
	match side:
		NORTH:  # InitMapSideForScene_North
			load_pals_for_ow_scene()
			load_overworld_common_gfx()
			_load_gfx(OVERWORLD_GFX[NORTH][0], OVERWORLD_GFX[NORTH][1])
			if r2(W_CUR_EVENT) != EVENT_DAY_OR_NIGHT_SPELL:
				_load_overworld_glow_gfx()
			load_bg_maps_to_wram(0x21, OVERWORLD_MAPS[NORTH][0], 0x21, OVERWORLD_MAPS[NORTH][1])
		WEST:  # InitMapSideForScene_West
			load_pals_for_ow_scene()
			_load_gfx(OVERWORLD_GFX[WEST][0], OVERWORLD_GFX[WEST][1])
			load_overworld_common_gfx()
			_load_overworld_glow_gfx()
			load_bg_maps_to_wram(0x21, OVERWORLD_MAPS[WEST][0], 0x21, OVERWORLD_MAPS[WEST][1])  # Func_80ae7
		SOUTH:  # InitMapSideForScene_South
			if r2(W_CUR_EVENT) == EVENT_SUMMON_MOON:
				w2(W2D011, 0x01)
			load_pals_for_ow_scene()
			_load_gfx(OVERWORLD_GFX[SOUTH][0], OVERWORLD_GFX[SOUTH][1])
			load_overworld_common_gfx()
			_load_overworld_glow_gfx()
			load_bg_maps_to_wram(0x21, OVERWORLD_MAPS[SOUTH][0], 0x21, OVERWORLD_MAPS[SOUTH][1])  # Func_80af5
			if func_819c6(EVENT_REVEAL_CASTLE) != 0:
				func_854ee(DATA_8561F)
		EAST:  # InitMapSideForScene_East
			w2(W_GOT_SUN_MEDALLION, func_819c6(EVENT_SUMMON_SUN))
			if r2(W_GOT_SUN_MEDALLION) == 0:
				w2(W2D011, 0x01)
			load_pals_for_ow_scene()
			_load_gfx(OVERWORLD_GFX[EAST][0], OVERWORLD_GFX[EAST][1])
			load_overworld_common_gfx()
			_load_overworld_glow_gfx()
			load_bg_maps_to_wram(0x21, OVERWORLD_MAPS[EAST][0], 0x21, OVERWORLD_MAPS[EAST][1])  # Func_80b1b
		_:
			_note("InitOWScene map side %d (past its table)" % side)
			return
	func_8086f()


## LoadOverworldGlowGfx: OverworldGlowGfx to v1Tiles0 tile $20.
func _load_overworld_glow_gfx() -> void:
	_load_gfx(0x22, OVERWORLD_GLOW_GFX, 1, 0x8000 + 0x20 * 0x10)


## Func_8086f: the side's scenes set up (Func_81dce) and its map written, the scroll, the scene's params
## put back, the scene objects drawn (Func_b4a37), the clouds' tiles, the name palette's colours
## cleared, North's 8th level name's 16 tiles (LevelNamesNorthJPGfx's bank by wLanguage) to v1Tiles2
## tiles $50 and $60, the compass, the LCD on (the window too in North's Magnifying Glass scene), then
## the next sub-state.
func func_8086f() -> void:
	func_80b54()
	func_81dce()
	write_bg_map_from_wram()
	sim.wSCY = 0x04
	sim.wSCX = 0
	w2(W2D015, r2(W2D018))
	w2(W_OW_SCENE_ACTION_PARAM, r2(W_TEMP_UNLOCKABLE_CONNECTION_ID))
	w2(W_OW_SCENE_ACTION, r2(W_TEMP_OW_SCENE_ACTION))
	w2(W_OW_SCENE_MAP_SIDE, r2(W_CUR_MAP_SIDE))
	wr_word(W_OW_SCENE_PARAMS_PTR, rd_word(W_TEMP_OW_SCENE_PARAMS_PTR))
	func_b4a3d()  # Func_b4a37
	func_b4aa9()
	load_cloud_and_sea_gfx()
	fill(W_TEMP_PALS_1 + 7 * 8 + 1 * 2, 6, 0)  # wTempPals1 palette 7 colours 1 to 3
	var names_bank: int = LEVEL_NAMES_JP_GFX_BANK + r0(W_LANGUAGE)
	for tile: int in [0x50, 0x60]:  # CopyFarBytes, $10 tiles
		vram_writes.append(["rom", 1, 0x9000 + tile * 0x10, names_bank, LEVEL_NAMES_JP_GFX + 7 * 0x20 * 0x10, 0x100])
	w2(W2D0E0, 0)
	set_compass_sprite()
	w2(W_LEVEL_ARROW_DIRECTIONS_1, 0)
	w2(W_OW_PAL_TRANSITION_STATE, 0)
	w2(W2D013, 0)
	if r2(W_CUR_MAP_SIDE) == NORTH and r2(W_CUR_EVENT) == EVENT_MAGNIFYING_GLASS:
		set_lcdc(LCDC_MAP_SIDE)
	else:
		set_lcdc(LCDC_DEFAULT)
	sim.wSubState = byte(sim.wSubState + 1)


## LoadPalsForOWScene: wOWExitUnlocked (w2dfff) TRUE for an UNLOCK_LEVEL scene whose connection starts
## at an exit (.CheckIfIsUnlockedExit), then _LoadPalsForOWScene (bank $21): the side's BG palettes
## (Pals_84000, 40 per side; with all crayons North's other ones unless a crayon was just got, West's
## other ones; night's 24 on) to wTempPals1, its OB palettes (Pals_84900) to wTempPals2, and for an exit
## the grey ones (LoadGreyOWPals).
func load_pals_for_ow_scene() -> void:
	w2(W_OW_EXIT_UNLOCKED, FALSE)
	if r2(W_OW_SCENE_ACTION) == UNLOCK_LEVEL:
		var at: int = cth_word_from_ath_table(MAP_BANK, UNLOCKABLE_CONNECTIONS, r2(W_OW_SCENE_MAP_SIDE),
				r2(W_OW_SCENE_ACTION_PARAM))
		if rb(MAP_BANK, at) >= OW_EXITS:
			w2(W_OW_EXIT_UNLOCKED, TRUE)
	var side: int = r2(W_CUR_MAP_SIDE)
	var pals: int = PALS_84000 + side * 40 * 8
	if (r2(W_CRAYON_FLAGS) & ALL_CRAYONS) == ALL_CRAYONS:  # .GetCrayonPal
		if side == NORTH:
			var last: int = r2(W_LAST_TRANSITION_PARAM)
			if last < CRAYON_RED_T or last > CRAYON_PINK_T:
				pals = PALS_84500
		elif side == WEST:
			pals = PALS_84640
	if r2(W2D011) != 0:
		pals += 24 * 8
	copy_rom(MAP_PALS_BANK, pals & 0xFFFF, W_TEMP_PALS_1, 8 * 8)
	copy_rom(MAP_PALS_BANK, (PALS_84900 + side * 8 * 8) & 0xFFFF, W_TEMP_PALS_2, 8 * 8)
	if r2(W_OW_EXIT_UNLOCKED) != 0:
		load_grey_ow_pals()


## LoadGreyOWPals (bank $21): the side's grey palettes (Data_84e39; East's without the ice until the
## Blue Book and the Magic Wand are got) to wTempPals1, palette 7's colours 1 to 3 cleared.
func load_grey_ow_pals() -> void:
	var side: int = r2(W_CUR_MAP_SIDE)
	var at: int = DATA_84E39 + ((side * 2) & 0xFF)
	if side == EAST and (is_treasure_collected(BLUE_BOOK) == 0 or is_treasure_collected(MAGIC_WAND) == 0):
		at += 2
	copy_rom(MAP_PALS_BANK, rw(MAP_PALS_BANK, at), W_TEMP_PALS_1, 8 * 8)
	fill(W_TEMP_PALS_1 + 7 * 8 + 1 * 2, 6, 0)


# --- the scene's loop (SST 7) ---

## Func_80540: the scene's step (Func_818ad), the unlocked level's star (Func_82bb8) and the highlighted
## level's (Func_82bda), the scene objects (Func_b4a37), the compass, the unused OAM cleared.
func ow_scene_loop() -> void:
	func_818ad()
	func_82bb8()
	func_82bda()
	func_b4a3d()  # Func_b4a37
	func_b4aa9()
	load_ow_sprite_with_scroll(W_COMPASS_OBJ, OAM_AA580, OBJECTS_BANK)  # LoadCompassSprite
	clear_unused_virtual_oam()


## Func_818ad: the animations; with a bar open (a cutscene played again) B ends the scene; w2d014
## counts, then by w2d013: wait 4 loops, the scene param's action until it is done (its
## wOWSceneActionParam cleared), wait 4 loops and the next param: on this side again, on another
## (SST 4: the fade to it), or the end (Func_81931).
func func_818ad() -> void:
	update_common_ow_animations()
	update_map_side_ow_animations()
	if r2(W_OW_BARS_STATE) != 0 and (sim.wJoypadPressed & PAD_B) != 0:
		func_81931()
		return
	w2(W2D014, r2(W2D014) + 1)
	match r2(W2D013):
		0:  # Func_818e7
			if r2(W2D014) >= 0x04:
				func_818ed()
		1:  # Func_818f6
			func_8195d()
			if r2(W_OW_SCENE_ACTION_PARAM) == 0:
				func_818ed()
		2:  # Func_81900
			if r2(W2D014) < 0x04:
				return
			if not get_ow_scene_params_got_ptr(rd_word(W_OW_SCENE_PARAMS_PTR)):
				func_81931()
				return
			if r2(W_OW_SCENE_MAP_SIDE) == r2(W_CUR_MAP_SIDE):
				w2(W2D014, 0)
				w2(W2D013, 0)
				return
			sim.wSubState = SST_OVERWORLD_FAST_FADE  # (the sounds stopped, not ported)
		_:
			_note("Func_818ad state $%02x (past its table)" % r2(W2D013))


## Func_818ed: w2d014 cleared, the next w2d013.
func func_818ed() -> void:
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## Func_81931: the scene over: wLastTransitionParam, the event, and the scene's actions cleared; the
## epilogue's (SST_OVERWORLD_EPILOGUE), or the fade to the map side and the save screen (Func_803e6).
func func_81931() -> void:
	var event: int = r2(W_CUR_EVENT)
	w2(W_LAST_TRANSITION_PARAM, 0)
	w2(W_CUR_EVENT, 0)
	w2(W_OW_SCENE_ACTION, 0)
	w2(W_TEMP_OW_SCENE_ACTION, 0)
	if event == EVENT_EPILOGUE:
		sim.wSubState = SST_OVERWORLD_EPILOGUE
		return
	sim.wSubState = byte(sim.wSubState + 1)
	func_803e6()


## Func_8195d: by wOWSceneAction.
func func_8195d() -> void:
	match r2(W_OW_SCENE_ACTION):
		UNLOCK_LEVEL:
			unlock_level()
		DO_OW_FUNC, SPECIAL_ACTION:
			do_ow_function()
		HIGHLIGHT_LEVEL:
			func_82c33()
		0:
			_note("Func_8195d.InvalidAction (debug_nop: hangs)")
		_:
			_note("Func_8195d action $%02x (past its table)" % r2(W_OW_SCENE_ACTION))


## Func_82bb8: in an UNLOCK_LEVEL scene, the unlocked level's star (wCurSceneObj) animated and drawn.
func func_82bb8() -> void:
	if r2(W_OW_SCENE_ACTION) != UNLOCK_LEVEL or r2(W_CUR_SCENE_OBJ_STATE) == 0:
		return
	update_ow_animation(W_CUR_SCENE_OBJ_DURATION, FRAMESET_AA544, OBJECTS_BANK)
	load_ow_sprite_with_scroll(W_CUR_SCENE_OBJ, OAM_AA445, OBJECTS_BANK)


## Func_82bda: in a HIGHLIGHT_LEVEL scene, the highlighted level's star animated and drawn until its
## frameset ends (then gone).
func func_82bda() -> void:
	if r2(W_OW_SCENE_ACTION) != HIGHLIGHT_LEVEL or r2(W_CUR_SCENE_OBJ_STATE) == 0:
		return
	update_ow_animation(W_CUR_SCENE_OBJ_DURATION, FRAMESET_AA555, OBJECTS_BANK)
	if r2(W_OW_ANIMATION_FINISHED) == 0xFF:
		w2(W_CUR_SCENE_OBJ_STATE, 0)
		return
	load_ow_sprite_with_scroll(W_CUR_SCENE_OBJ, OAM_AA445, OBJECTS_BANK)


## SetSceneObjState on the object at `obj`: its state, its animation restarted.
func _set_scene_obj_state_at(obj: int, state: int) -> void:
	wr(obj + SCENE_OBJ_STATE, state)
	wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
	wr(obj + SCENE_OBJ_DURATION, 0)


# --- UNLOCK_LEVEL ---

## UnlockLevel: wOWFuncCounter counts; by w2d062: the connection's data and the star cleared, the
## grey transition, the level's name faded in, the star's palettes, the arrows and the level's point
## placed one by one in the map (each copied to VRAM by the V-Blank), the star shown, the end.
func unlock_level() -> void:
	w2(W_OW_FUNC_COUNTER, r2(W_OW_FUNC_COUNTER) + 1)
	match r2(W2D062):
		0:  # Func_82a79
			get_unlocked_ow_level_data()
			w2(W_OW_PATH_SHAPE, 0)
			w2(W2D072, 0)
			fill(W_CUR_SCENE_OBJ, SCENE_OBJ_SIZE, 0)
			func_82a8d()
		1:
			func_82a0a()
		2:
			func_82a26()
		3:
			func_82a2f()
		4:
			func_82a4e()
		5:
			func_82a62()
		6:  # Func_82a96
			get_unlocked_level_arrows()
			func_82a8d()
		7, 9, 11:
			_func_82a9b()
		8:
			_func_82aae()
		10:
			_func_82aea()
		12:
			_func_82b22()
		13:  # Func_82b67
			if r2(W2D07F) != 0:
				w2(W_OW_FUNC_COUNTER, 0)
				return
			if r2(W_OW_FUNC_COUNTER) >= 30:
				func_82a8d()
		14:
			_func_82b7b()
		15:  # Func_82baa
			if r2(W_OW_FUNC_COUNTER) < 30:
				return
			w2(W_OW_SCENE_ACTION_PARAM, 0)
			w2(W2D062, 0)
		_:
			_note("UnlockLevel step %d (past its table)" % r2(W2D062))


## Func_82a8d: wOWFuncCounter cleared, the next step.
func func_82a8d() -> void:
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, r2(W2D062) + 1)


## Func_82a0a: the grey transition until done, then VBlank_OWScene again and the next step.
func func_82a0a() -> void:
	ow_grey_transition()
	if r2(W_OW_PAL_TRANSITION_STATE) != 0:
		return
	vblank_func = VBLANK_OW_SCENE
	func_82a8d()


## Func_82a26: wait 20 loops.
func func_82a26() -> void:
	if 20 >= r2(W_OW_FUNC_COUNTER):
		return
	func_82a8d()


## Func_82a2f: the level's name (wOWSceneMapSide's wLevel2) loaded, its palette's steps cleared; an
## exit has none (the name's steps skipped).
func func_82a2f() -> void:
	var level: int = r2(W_LEVEL_2)
	if level < OW_EXITS:
		load_level_name(r2(W_OW_SCENE_MAP_SIDE), level)
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
		func_82a8d()
		return
	w2(W2D062, r2(W2D062) + 2)
	w2(W_OW_FUNC_COUNTER, 0)


## Func_82a4e: FadeInLevelName until done.
func func_82a4e() -> void:
	if fade_in_level_name():
		return
	func_82a8d()


## Func_82a62: after 16 loops, the star indicator's palettes (LoadOWStarIndicatorPals).
func func_82a62() -> void:
	if r2(W_OW_FUNC_COUNTER) < 16:
		return
	load_ow_star_indicator_pals()
	func_82a8d()


## Func_82a9b: while a tile waits for its copy (w2d07f), the count starts again; else wait 4 loops.
func _func_82a9b() -> void:
	if r2(W2D07F) != 0:
		w2(W_OW_FUNC_COUNTER, 0)
		return
	if r2(W_OW_FUNC_COUNTER) >= 4:
		func_82a8d()


## Func_82aae: the arrow out of the first level (none from the left exit or North's junction).
func _func_82aae() -> void:
	if is_left_exit_or_junction():
		func_82a8d()
		return
	_place_unlocked_arrow()


## Func_82aea: the arrow into the second level (none at the right exit), from wOWCoords2 the second way.
func _func_82aea() -> void:
	if r2(W_LEVEL_2) == OW_EXIT_RIGHT:
		func_82a8d()
		return
	w2(W_OW_X_COORD_1, r2(W_OW_X_COORD_2))
	w2(W_OW_Y_COORD_1, r2(W_OW_Y_COORD_2))
	w2(W_LEVEL_ARROW_DIRECTIONS_1, r2(W_LEVEL_ARROW_DIRECTIONS_2))
	_place_unlocked_arrow()


## The arrow wLevelArrowDirections1's way a tile on from wOWCoords1, placed (a sound, not ported).
func _place_unlocked_arrow() -> void:
	get_connected_level_1_arrow_coord(r2(W_LEVEL_ARROW_DIRECTIONS_1))
	get_connected_level_1_coords_in_tilemap()
	show_level_arrow_in_ow(r2(W_LEVEL_ARROW_DIRECTIONS_1))
	w2(W2D07F, TRUE)
	_func_82ad2()


## Func_82b22: the second level's point (none at the right exit).
func _func_82b22() -> void:
	if r2(W_LEVEL_2) == OW_EXIT_RIGHT:
		func_82a8d()
		return
	get_ow_coord_in_tilemap(W_OW_Y_COORD_2)
	show_level_point_in_ow()
	w2(W2D07F, 0x01)
	_func_82ad2()


## Func_82ad2: its palette (Func_81feb), placed in the map (Func_81f21), the next step.
func _func_82ad2() -> void:
	func_81feb()
	func_81f21()
	func_82a8d()


## Func_81f21: for each of w2d07f tiles (wTileToPlaceInOW, wAttrToPlaceInOW, wOWTilemapPtr; the next
## from 4 bytes on), its tile and attributes to wTilemap and wAttrmap; wOWPendingTileUpdate set.
func func_81f21() -> void:
	if r2(W2D07F) == 0:
		return
	var at: int = W_TILE_TO_PLACE_IN_OW
	while true:
		var tile: int = r2(at)
		var attributes: int = r2(at + 1)
		var destination: int = r2(at + 2) | (r2(at + 3) << 8)
		wr(destination, tile)
		wr((destination - 0x300) & 0xFFFF, attributes)
		at = (at & 0xFF00) | ((at + 4) & 0xFF)  # `inc e`
		w2(W2D07F, r2(W2D07F) - 1)
		if r2(W2D07F) == 0:
			break
	w2(W_OW_PENDING_TILE_UPDATE, TRUE)



## Func_82b7b: on its first loop the star (wCurSceneObj, state 1) at the second level (not an exit, a
## sound not ported); after $40 loops the next step.
func _func_82b7b() -> void:
	var counter: int = r2(W_OW_FUNC_COUNTER)
	if counter == 0x01:
		if r2(W_LEVEL_2) >= OW_EXITS:
			func_82a8d()
			return
		w2(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_OW_Y_COORD_2))
		w2(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_OW_X_COORD_2))
		w2(W_CUR_SCENE_OBJ_STATE, 0x01)
		return
	if counter < 0x40:
		return
	func_82a8d()


# --- HIGHLIGHT_LEVEL ---

## Func_82c33: wOWFuncCounter counts; by w2d062: the level (wLevel2: the param, one less off North; the
## Gold Music Box's 7; the Super Grab Gloves' on East without the Mystery Handle ends at once), wait 12,
## the grey transition, wait 20, its name faded in, the star's palettes, the star shown at the level
## until its frameset ends, wait 30, the end.
func func_82c33() -> void:
	w2(W_OW_FUNC_COUNTER, r2(W_OW_FUNC_COUNTER) + 1)
	match r2(W2D062):
		0:  # .Func_82c55
			var off_north: int = 1 if r2(W_CUR_MAP_SIDE) != NORTH else 0
			w2(W_LEVEL_2, r2(W_OW_SCENE_ACTION_PARAM) - off_north)
			var event: int = r2(W_CUR_EVENT)
			if event == EVENT_GOLD_MUSIC_BOX:
				w2(W_OW_SCENE_ACTION_PARAM, 0x07)
			elif event == EVENT_SUPER_GRAB_GLOVES and r2(W_CUR_MAP_SIDE) == EAST \
					and r2(W_OW_SCENE_ACTION_PARAM) == 0x07 and is_treasure_collected(MYSTERY_HANDLE) == 0:
				_func_82c29()
				return
			_func_82c22()
		1:  # .Func_82c8f
			_func_82c1d(12)
		2:
			func_82a0a()
		3:
			func_82a26()
		4:
			func_82a2f()
		5:
			func_82a4e()
		6:
			func_82a62()
		7:  # .Func_82c93 (a sound, not ported)
			var at: int = get_map_level_coords(r2(W_LEVEL_2))  # SetObjPositionToLevelCoords
			w2(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, rb(MAP_BANK, at))
			w2(W_CUR_SCENE_OBJ + SCENE_OBJ_X, rb(MAP_BANK, at + 1))
			_set_scene_obj_state_at(W_CUR_SCENE_OBJ, 0x02)
			_func_82c22()
		8:  # .Func_82cb0
			if r2(W_CUR_SCENE_OBJ_STATE) == 0:
				_func_82c22()
		9:  # .Func_82c51
			_func_82c1d(30)
		10:
			_func_82c29()
		_:
			_note("Func_82c33 step %d (past its table)" % r2(W2D062))


## Func_82c1d: once wOWFuncCounter passes `count`, Func_82c22.
func _func_82c1d(count: int) -> void:
	if count >= r2(W_OW_FUNC_COUNTER):
		return
	_func_82c22()


## Func_82c22: wOWFuncCounter cleared, the next step.
func _func_82c22() -> void:
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, r2(W2D062) + 1)


## Func_82c29: the action done: wOWSceneActionParam, wOWFuncCounter, w2d062 cleared.
func _func_82c29() -> void:
	w2(W_OW_SCENE_ACTION_PARAM, 0)
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, 0)


# --- the palettes (bank $21) ---

## OWGreyTransition: wOWPalTransitionCounter counts; by wOWPalTransitionState: the start (the current
## palettes as the base and the grey ones as the target of the colour fade structs, VBlank_OWPalTransition),
## the colours faded (DayNightTransition.FadeColours), the end.
func ow_grey_transition() -> void:
	w2(W_OW_PAL_TRANSITION_COUNTER, r2(W_OW_PAL_TRANSITION_COUNTER) + 1)
	match r2(W_OW_PAL_TRANSITION_STATE):
		0:  # .Start
			_copy_wram_pal_to_colour_fade_structs(W_TEMP_PALS_1, W_FADE_PALS + 0)
			for offset: int in 8 * 8:
				w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))
			load_grey_ow_pals()
			_copy_wram_pal_to_colour_fade_structs(W_TEMP_PALS_1, W_FADE_PALS + 1)
			init_colour_fade_structs()
			w2(W_DAY_NIGHT_TRANSISTION_STEPS, DAYNIGHT_TRANSITION_STEPS)
			w2(W2D809, 0)
			vblank_func = VBLANK_OW_PAL_TRANSITION
			_advance_transition()
		1:
			_fade_colours()
		2:  # .Finish
			w2(W2D0E3, 0)
			w2(W_OW_PAL_TRANSITION_STATE, 0)
			w2(W_OW_PAL_TRANSITION_COUNTER, 0)
		_:
			_note("OWGreyTransition state %d (past its table)" % r2(W_OW_PAL_TRANSITION_STATE))


## CopyPalToColourFadeStructs from WRAM: the 32 colours at `source` split into red, green, and blue at
## `destination` (each 8 bytes on).
func _copy_wram_pal_to_colour_fade_structs(source: int, destination: int) -> void:
	w2(W2D807, 8 * 4)
	var at: int = destination
	for colour: int in 8 * 4:
		var low: int = rd(source + colour * 2)
		var high: int = rd(source + colour * 2 + 1)
		w2(at, low & 0x1F)
		w2(at + COLOURFADESTRUCT_LENGTH, ((low >> 5) | (high << 3)) & 0x1F)
		w2(at + 2 * COLOURFADESTRUCT_LENGTH, (high >> 2) & 0x1F)
		at += 3 * COLOURFADESTRUCT_LENGTH
		w2(W2D807, r2(W2D807) - 1)


## LoadOWStarIndicatorPals (bank $21): the star's two OB palettes (Pals_848e0) to wTempPals2 palette 4,
## shown through wPalConfig1 (rOBPI).
func load_ow_star_indicator_pals() -> void:
	copy_rom(MAP_PALS_BANK, PALS_848E0, W_TEMP_PALS_2 + 4 * 8, 2 * 8)
	w2(W_PAL_CONFIG_1_SOURCE_HI, (W_TEMP_PALS_2 + 4 * 8) >> 8)
	w2(W_PAL_CONFIG_1_SOURCE_HI + 1, (W_TEMP_PALS_2 + 4 * 8) & 0xFF)
	w2(W_PAL_CONFIG_1_INDEX, OBPI_PALETTE_4)
	w2(W_PAL_CONFIG_1_NUMBER, 2)
	w2(W_PAL_CONFIG_1, LOW_R_OBPI)


## VBlank_OWScene's function, run after the loop (V-Blank): the scroll; with wOWPendingTileUpdate,
## the map's first 15 rows (wTilemap, wAttrmap) by DMA to BG map 0; with wHDMABank, Func_3c03's DMA
## (w2d0b5) to VRAM 1; Func_1d8c2c's DMAs; ApplyPalConfig1 and ApplyPalConfig2; the OAM. Its RAM
## writes: wOWPendingTileUpdate, wHDMABank, and wPalConfig1's and wPalConfig2's registers cleared once
## applied.
func vblank_ow_scene() -> void:
	if r2(W_OW_PENDING_TILE_UPDATE) != 0:
		w2(W_OW_PENDING_TILE_UPDATE, 0)
		for offset: int in 15 * TILEMAP_WIDTH:  # 15 rows of wTilemap and wAttrmap to BG map 0
			_bg_map_0(0)[offset] = rd(W_TILEMAP + offset)
			_bg_map_0(1)[offset] = rd(W_ATTRMAP + offset)
		record_wram_to_vram(0, 0x9800, W_TILEMAP, 15 * TILEMAP_WIDTH)
		record_wram_to_vram(1, 0x9800, W_ATTRMAP, 15 * TILEMAP_WIDTH)
	if r2(W_HDMA_BANK) != 0:
		record_gdma(1, W2D0B5, r2(W_HDMA_BANK))
	record_func_1d8c2c()
	if r2(W_PAL_CONFIG_1) != 0:
		record_pal_config(W_PAL_CONFIG_1)
	if r2(W_PAL_CONFIG_2) != 0:
		record_pal_config(W_PAL_CONFIG_2)
	for at: int in [W_HDMA_BANK, W_PAL_CONFIG_1, W_PAL_CONFIG_2]:
		if r2(at) != 0:
			w2(at, 0)
