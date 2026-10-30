class_name OverworldMapSide
extends OverworldObjects
## What sets up a map side from src/engine/overworld/bank20.asm, translated (WL3-052): the events and
## their treasures (EventTreasures: CheckIfEventIsUnlocked, GetNextTreasureToCollect), the events'
## scenes on this side (Func_81dce: OWSceneParams, the levels they unlock drawn in wTilemap, the scene
## objects they set up, the highlight palettes), the missing treasures' indicators, OW Wario, the top
## bar's selectable buttons, the level's name, the compass, and the bottom bar's sprites.

const MAP_BANK: int = 0x20
const UNLOCKABLE_CONNECTIONS: int = 0x4000
const UNLOCKABLE_LEVEL_ARROWS: int = 0x404C
const MAP_LEVEL_COORDS: int = 0x4136
const MAP_SIDE_INITIAL_LEVELS: int = 0x52AC
const EVENT_TREASURES: int = 0x59FB
const OW_SCENE_PARAMS: int = 0x5B2B
const SET_OW_WARIO_OAM_FRAMESETS: int = 0x60DC
const OAM_AA329: int = 0x6329  # bank $2a
const OAM_AA0CF: int = 0x60CF  # bank $2a
const OAM_AA580: int = 0x6580  # bank $2a
const FRAMESET_AA2FB: int = 0x62FB  # bank $2a
const PALS_848E0: int = 0x48E0  # bank $21

const INVALID_TREASURE: int = 0x80
const TREASURES_END: int = 0xED
const DAY_OR_NIGHT_SPELL: int = 0x4D
const MAGNIFYING_GLASS: int = 0x59
const TRANSITION_RETURN_TO_MAP: int = 0xF0
const TRANSITION_GAME_OVER: int = 0xF3
const TRANSITION_NEW_GAME: int = 0xFF
const EVENT_PROLOGUE: int = 0x01
const EVENT_OPEN_NORTH_GATE: int = 0x03
const EVENT_FIX_ELEVATOR: int = 0x07
const EVENT_BLOW_MIST: int = 0x0C
const EVENT_TORCH_FOREST: int = 0x37
const NUM_EVENTS: int = 0x5B
const DO_OW_FUNC: int = 0x02
const HIGHLIGHT_LEVEL: int = 0x03
const SPECIAL_ACTION: int = 0x04
const OWWARIO_DOWN: int = 1
const OWWARIO_LEFT: int = 2
const OWWARIO_RIGHT: int = 3
const OWWARIO_UP: int = 4
const MODE_TIME_ATTACK: int = 0x02
const TREASURES_MASK: int = 0xF0
const TOPBAR_DAY_NIGHT: int = 0x01
const TOPBAR_CUTSCENE: int = 0x02
const TOPBAR_COLLECTION: int = 0x04
const TOPBAR_NEXT_MAP: int = 0x08
const TOPBAR_PREV_MAP: int = 0x10
## The levels a map side has (NUM_NORTH_LEVELS...), by wNextMapSide.
const NUM_LEVELS: Array = [7, 6, 6, 7]

## The c register CheckIfEventIsUnlocked leaves: FALSE when one of the event's treasures is the one
## just collected (wLastTransitionParam), else TRUE.
var event_check_c: int = TRUE


# --- events and treasures ---

## LoadEventTreasures: `event`'s three treasures (EventTreasures) into w2dfff, w2dffe, w2dffd.
func load_event_treasures(event: int) -> void:
	var at: int = EVENT_TREASURES + ((event * 2) & 0xFF) + event  # add a, add c: the last carry kept
	w2(W2DFFF, rb(MAP_BANK, at))
	w2(W2DFFE, rb(MAP_BANK, at + 1))
	w2(W2DFFD, rb(MAP_BANK, at + 2))


## CheckIfEventIsUnlocked: TRUE if each of `event`'s treasures is INVALID_TREASURE, collected, or the
## one just collected (which leaves event_check_c FALSE), else FALSE (checking w2dffd, w2dffe, w2dfff).
func check_if_event_is_unlocked(event: int) -> int:
	load_event_treasures(event)
	event_check_c = TRUE
	for at: int in [W2DFFD, W2DFFE, W2DFFF]:
		if not _check_event_treasure(r2(at)):
			return FALSE
	return TRUE


## CheckEventTreasure: true (no carry) unless `treasure` is neither INVALID_TREASURE, nor
## wLastTransitionParam, nor collected.
func _check_event_treasure(treasure: int) -> bool:
	if treasure == INVALID_TREASURE:
		return true
	if treasure == r2(W_LAST_TRANSITION_PARAM):
		event_check_c = FALSE
		return true
	return is_treasure_collected(treasure) != 0


## Func_819c6: CheckIfEventIsUnlocked and c: TRUE only if unlocked without the treasure just got.
func func_819c6(event: int) -> int:
	return check_if_event_is_unlocked(event) & event_check_c


## GetEventWithTreasure: the event whose treasures (EventTreasures) include `treasure` (EVENT_00 if
## none before TREASURES_END), and the address after that treasure in the table (x: event, y: address).
func get_event_with_treasure(treasure: int) -> Vector2i:
	var event: int = 0
	var at: int = EVENT_TREASURES
	while true:
		var entry: int = rb(MAP_BANK, at)
		at += 1
		if entry == TREASURES_END:
			return Vector2i(0, at)
		if entry == treasure:
			return Vector2i(event, at)
		entry = rb(MAP_BANK, at)
		at += 1
		if entry == treasure:
			return Vector2i(event, at)
		entry = rb(MAP_BANK, at)
		at += 1
		if entry == treasure:
			return Vector2i(event, at)
		event = byte(event + 1)
	return Vector2i(0, at)


## GetNextTreasureToCollect: once wNextTreasure is collected (or the transition is that treasure, or
## from New Game wNextTreasure 0), the next treasure after it in EventTreasures not collected yet
## (INVALID_TREASURE skipped; TREASURES_END at the table's end).
func get_next_treasure_to_collect() -> void:
	var next: int = r2(W_NEXT_TREASURE)
	if is_treasure_collected(next) == 0:
		var transition: int = wTransitionParam
		if transition == 0 or transition in [TRANSITION_RETURN_TO_MAP, TRANSITION_EPILOGUE_NOT_PERFECT,
				TRANSITION_EPILOGUE_PERFECT, TRANSITION_GAME_OVER]:
			return
		if transition == TRANSITION_NEW_GAME:
			transition = 0
		if transition != next:
			return
	var at: int = get_event_with_treasure(next).y
	while true:
		var treasure: int = rb(MAP_BANK, at)
		if treasure != INVALID_TREASURE and is_treasure_collected(treasure) == 0:
			w2(W_NEXT_TREASURE, treasure)
			return
		at += 1
		if treasure == TREASURES_END:
			w2(W_NEXT_TREASURE, TREASURES_END)
			return


# --- the events' scenes on this side (Func_81dce) ---

## GetOWSceneParams: `event`'s scene params (OWSceneParams); false when it has none.
func get_ow_scene_params(event: int) -> bool:
	return get_ow_scene_params_got_ptr(pointer_from_table(MAP_BANK, OW_SCENE_PARAMS, event))


## GetOWSceneParams_GotPtr: a scene param at `at`: wOWSceneAction (false at $80, the end), then
## wOWSceneMapSide and wOWSceneActionParam, wOWSceneParamsPtr after them.
func get_ow_scene_params_got_ptr(at: int) -> bool:
	w2(W_OW_SCENE_ACTION, rb(MAP_BANK, at))
	if rb(MAP_BANK, at) == 0x80:
		return false
	w2(W_OW_SCENE_MAP_SIDE, rb(MAP_BANK, at + 1))
	w2(W_OW_SCENE_ACTION_PARAM, rb(MAP_BANK, at + 2))
	wr_word(W_OW_SCENE_PARAMS_PTR, at + 3)
	return true


## Func_81dce: every event from EVENT_PROLOGUE: w2d065 TRUE if unlocked ($80 if by the treasure just
## collected), then its scene params on this map side set up (.PrepareScene). wLastTransitionParam 0
## is $ff meanwhile (no treasure), and $ff (New Game) ends 0.
func func_81dce() -> void:
	w2(W_TEMP_EVENT, EVENT_PROLOGUE)
	var last: int = r2(W_LAST_TRANSITION_PARAM)
	if last == 0:
		w2(W_LAST_TRANSITION_PARAM, 0xFF)
	elif last == TRANSITION_NEW_GAME:
		w2(W_LAST_TRANSITION_PARAM, 0)
	while true:
		w2(W2D078, 0)
		var unlocked: int = check_if_event_is_unlocked(r2(W_TEMP_EVENT))
		w2(W2D065, unlocked)
		if unlocked != 0 and event_check_c != TRUE:
			w2(W2D065, 0x80)
		_prepare_scene()
		var event: int = r2(W_TEMP_EVENT) + 1
		if event == NUM_EVENTS:
			break
		w2(W_TEMP_EVENT, event)
	if r2(W_LAST_TRANSITION_PARAM) == 0xFF:
		w2(W_LAST_TRANSITION_PARAM, 0)


## Func_81dce.PrepareScene: each of wTempEvent's scene params on wCurMapSide set up (.DoInitFunc).
func _prepare_scene() -> void:
	if not get_ow_scene_params(r2(W_TEMP_EVENT)):
		return
	while true:
		if r2(W_OW_SCENE_MAP_SIDE) == r2(W_CUR_MAP_SIDE):
			_do_init_func()
		var at: int = rd_word(W_OW_SCENE_PARAMS_PTR)
		if not get_ow_scene_params_got_ptr(at):
			return


## Func_81dce.DoInitFunc: by wOWSceneAction.
func _do_init_func() -> void:
	match r2(W_OW_SCENE_ACTION):
		UNLOCK_LEVEL:
			draw_unlocked_levels()
		DO_OW_FUNC, SPECIAL_ACTION:
			init_ow_objects()  # InitOWObjects
		HIGHLIGHT_LEVEL:
			init_highlight_level_scene()
		0:
			_note("Func_81e44 (scene action 0: debug_nop, hangs)")
		_:
			_note("Func_81dce scene action $%02x (past its table)" % r2(W_OW_SCENE_ACTION))


## InitHighlightLevelScene: for an event just unlocked, the star indicator's palettes (Pals_848e0)
## to wTempPals2 palette 4.
func init_highlight_level_scene() -> void:
	if r2(W2D065) == 0x80:
		copy_rom(0x21, PALS_848E0, W_TEMP_PALS_2 + 4 * 8, 2 * 8)


## GetMapLevelCoords: the address of map side wCurMapSide's level `level`'s coordinates in
## MapLevelCoords (y, x, and Wario's offsets from them).
func get_map_level_coords(level: int) -> int:
	return cth_word_from_ath_table(MAP_BANK, MAP_LEVEL_COORDS, r2(W_CUR_MAP_SIDE), (level * 2) & 0xFF)


## DrawUnlockedLevels: for an event unlocked before (w2d065 TRUE), its connection drawn in wTilemap
## and wAttrmap: the arrows and the level's point (.Func_81e88), w2d074 times.
func draw_unlocked_levels() -> void:
	if (r2(W2D065) * 2) & 0xFF == 0:
		return
	w2(W2D072, 0)
	get_unlocked_ow_level_data()
	get_unlocked_level_arrows()
	while true:
		_func_81e88()
		w2(W2D072, r2(W2D072) + 1)
		if r2(W2D074) == r2(W2D072):
			break
	w2(W2D072, 0)
	wr_word(W_OW_TILEMAP_PTR, 0)
	w2(W_ATTR_TO_PLACE_IN_OW, 0)
	w2(W_TILE_TO_PLACE_IN_OW, 0)
	w2(W_OW_PATH_SHAPE, 0)


## DrawUnlockedLevels.Func_81e88: the arrow from the first level (unless it is the left exit or North's
## junction), then (unless the second is the right exit) the arrow into the second level and its point.
func _func_81e88() -> void:
	if not is_left_exit_or_junction():
		show_level_arrow_in_ow(r2(W_LEVEL_ARROW_DIRECTIONS_1))
		get_connected_level_1_arrow_coord(r2(W_LEVEL_ARROW_DIRECTIONS_1))
		_place_in_ow(get_connected_level_1_coords_in_tilemap())
		if r2(W_LEVEL_2) == OW_EXIT_RIGHT:
			return
	w2(W_OW_X_COORD_1, r2(W_OW_X_COORD_2))
	w2(W_OW_Y_COORD_1, r2(W_OW_Y_COORD_2))
	w2(W_LEVEL_ARROW_DIRECTIONS_1, r2(W_LEVEL_ARROW_DIRECTIONS_2))
	show_level_arrow_in_ow(r2(W_LEVEL_ARROW_DIRECTIONS_1))
	get_connected_level_1_arrow_coord(r2(W_LEVEL_ARROW_DIRECTIONS_1))
	_place_in_ow(get_connected_level_1_coords_in_tilemap())
	show_level_point_in_ow()
	_place_in_ow(get_ow_coord_in_tilemap(W_OW_Y_COORD_2))


## wTileToPlaceInOW and wAttrToPlaceInOW (palette 7 in VRAM bank 1, Func_81feb) at the wTilemap address
## `at` and its wAttrmap address, w2d07f TRUE meanwhile.
func _place_in_ow(at: int) -> void:
	w2(W2D07F, TRUE)
	func_81feb()
	wr(at, r2(W_TILE_TO_PLACE_IN_OW))
	wr(at - 0x300, r2(W_ATTR_TO_PLACE_IN_OW))
	w2(W2D07F, FALSE)


## GetUnlockedOWLevelData: the scene's connection (UnlockableConnections by wOWSceneMapSide and
## wOWSceneActionParam) to wLevel1 and wLevel2, its arrows' table (UnlockableLevelArrows), and the two
## levels' coordinates (wOWCoords1, also w2d069 and w2d06a; wOWCoords2).
func get_unlocked_ow_level_data() -> void:
	var side: int = r2(W_OW_SCENE_MAP_SIDE)
	var connection: int = r2(W_OW_SCENE_ACTION_PARAM)
	var at: int = cth_word_from_ath_table(MAP_BANK, UNLOCKABLE_CONNECTIONS, side, connection)
	w2(W_LEVEL_1, rb(MAP_BANK, at))
	w2(W_LEVEL_2, rb(MAP_BANK, at + 1))
	at = cth_word_from_ath_table(MAP_BANK, UNLOCKABLE_LEVEL_ARROWS, side, connection)
	wr_word(W_UNLOCKED_LEVEL_ARROWS_PTR, rw(MAP_BANK, at))
	at = get_map_level_coords(r2(W_LEVEL_1))
	w2(W2D069, rb(MAP_BANK, at))
	w2(W_OW_Y_COORD_1, rb(MAP_BANK, at))
	w2(W2D06A, rb(MAP_BANK, at + 1))
	w2(W_OW_X_COORD_1, rb(MAP_BANK, at + 1))
	at = get_map_level_coords(r2(W_LEVEL_2))
	w2(W_OW_Y_COORD_2, rb(MAP_BANK, at))
	w2(W_OW_X_COORD_2, rb(MAP_BANK, at + 1))


## GetUnlockedLevelArrows: wOWPathShape's entry of the arrows' table: the first arrow's direction,
## w2d074 (how many), the second's direction, and w2d076 (0 without a second, $ff).
func get_unlocked_level_arrows() -> void:
	var at: int = table_entry(rd_word(W_UNLOCKED_LEVEL_ARROWS_PTR), r2(W_OW_PATH_SHAPE))
	w2(W_LEVEL_ARROW_DIRECTIONS_1, rb(MAP_BANK, at))
	w2(W2D074, rb(MAP_BANK, at + 1))
	w2(W_LEVEL_ARROW_DIRECTIONS_2, rb(MAP_BANK, at + 2))
	w2(W2D076, 0 if rb(MAP_BANK, at + 2) == 0xFF else rb(MAP_BANK, at + 3))


## IsLeftExitOrJunction: wLevel1 is the left exit, or North's junction on the North side.
func is_left_exit_or_junction() -> bool:
	var level: int = r2(W_LEVEL_1)
	if level == OW_EXIT_LEFT:
		return true
	return r2(W_OW_SCENE_MAP_SIDE) == NORTH and level == OWNORTH_JUNCTION


## ShowLevelArrowInOW: an arrow for the d-pad `direction` in wTileToPlaceInOW (1 vertical, 2
## horizontal) and wAttrToPlaceInOW (flipped left or down).
func show_level_arrow_in_ow(direction: int) -> void:
	w2(W_ATTR_TO_PLACE_IN_OW, 0)
	if (direction & PAD_RIGHT) != 0:
		w2(W_TILE_TO_PLACE_IN_OW, 0x02)
	elif (direction & PAD_LEFT) != 0:
		w2(W_ATTR_TO_PLACE_IN_OW, 0x20)
		w2(W_TILE_TO_PLACE_IN_OW, 0x02)
	elif (direction & PAD_UP) != 0:
		w2(W_TILE_TO_PLACE_IN_OW, 0x01)
	elif (direction & PAD_DOWN) != 0:
		w2(W_ATTR_TO_PLACE_IN_OW, 0x40)
		w2(W_TILE_TO_PLACE_IN_OW, 0x01)


## ShowLevelPointInOW: tile and attributes 0.
func show_level_point_in_ow() -> void:
	w2(W_ATTR_TO_PLACE_IN_OW, 0)
	w2(W_TILE_TO_PLACE_IN_OW, 0)


## GetConnectedLevel1ArrowCoord: wOWCoords1 moved a tile (8 pixels) the arrow's way.
func get_connected_level_1_arrow_coord(direction: int) -> void:
	var at: int = W_OW_X_COORD_1
	var step: int = 0x08
	if (direction & PAD_RIGHT) == 0:
		if (direction & PAD_LEFT) != 0:
			step = -0x08
		else:
			at = W_OW_Y_COORD_1
			if (direction & PAD_UP) != 0:
				step = -0x08
			elif (direction & PAD_DOWN) == 0:
				return
	w2(at, r2(at) + step)


## GetConnectedLevel1CoordsInTilemap: wOWTilemapPtr kept in wTempOWTilemapPtr, then wOWCoords1's
## wTilemap address.
func get_connected_level_1_coords_in_tilemap() -> int:
	wr_word(W_TEMP_OW_TILEMAP_PTR, rd_word(W_OW_TILEMAP_PTR))
	return get_ow_coord_in_tilemap(W_OW_Y_COORD_1)


## Func_81feb: with w2d07f TRUE, wAttrToPlaceInOW gets palette 7 in VRAM bank 1 (.GetTilePalIndex);
## with w2d07f other than TRUE it would hang (debug_nop).
func func_81feb() -> void:
	if r2(W2D07F) == 0:
		return
	w2(W_ATTR_TO_PLACE_IN_OW, (r2(W_ATTR_TO_PLACE_IN_OW) & ~BG_PALMASK) | 0x07 | BG_BANK1)
	if r2(W2D07F) != 1:
		_note("Func_81feb with w2d07f $%02x (debug_nop: hangs)" % r2(W2D07F))


# --- the missing treasures' indicators ---

## ShowMissingTreasureIndicators: once the game is cleared (wMissingTreasureIndicatorsEnabled), each of
## the side's levels (from MapSideInitialLevels; North's Temple skipped) with a treasure missing gets
## an indicator (tile $7b, attributes $0d) at its coordinates; wOWLevel kept in w2dffd meanwhile.
func show_missing_treasure_indicators() -> void:
	if r2(W_MISSING_TREASURE_INDICATORS_ENABLED) == 0:
		return
	w2(W2DFFD, r2(W_OW_LEVEL))
	w2(W_OW_LEVEL, rb(MAP_BANK, MAP_SIDE_INITIAL_LEVELS + r2(W_CUR_MAP_SIDE)))
	var next_side: int = r2(W_NEXT_MAP_SIDE)
	w2(W2DFFF, NUM_LEVELS[next_side] if next_side >= 1 and next_side <= 3 else NUM_LEVELS[0])
	w2(W2DFFE, 0)
	var skip: bool = r2(W_OW_LEVEL) == 0
	while true:
		if not skip:
			get_ow_level_collected_treasures()
			if ((r0(W_KEY_AND_TREASURE_FLAGS) & TREASURES_MASK) ^ TREASURES_MASK) != 0:
				_place_treasure_missing_indicator()
		skip = false
		w2(W_OW_LEVEL, r2(W_OW_LEVEL) + 1)
		w2(W2DFFE, r2(W2DFFE) + 1)
		if r2(W2DFFE) == r2(W2DFFF):
			break
	w2(W_OW_LEVEL, r2(W2DFFD))


func _place_treasure_missing_indicator() -> void:
	var at: int = get_map_level_coords(r2(W2DFFE))
	w2(W_OW_Y_COORD_1, rb(MAP_BANK, at))
	w2(W_OW_X_COORD_1, rb(MAP_BANK, at + 1))
	var tile: int = get_ow_coord_in_tilemap(W_OW_Y_COORD_1)
	wr(tile, 0x7B)
	wr(tile - 0x300, 0x0D)


## GetOWLevelCollectedTreasures (src/engine/print_counts.asm): wKeyAndTreasureFlags' treasure bits
## for wOWLevel's four treasures (LevelTreasureIDs) collected.
func get_ow_level_collected_treasures() -> void:
	w0(W_KEY_AND_TREASURE_FLAGS, 0)
	var at: int = LEVEL_TREASURE_IDS + NUM_LEVEL_TREASURES + (((r2(W_OW_LEVEL) - 1) * 4) & 0xFF)
	for index: int in NUM_LEVEL_TREASURES:
		if is_treasure_collected(rb(0x00, at + index)) != 0:
			w0(W_KEY_AND_TREASURE_FLAGS, r0(W_KEY_AND_TREASURE_FLAGS) | (0x10 << index))


# --- OW Wario ---

## Func_8212c: Wario at wMapSideLevelID's coordinates (wLevel1; w2d069 and w2d06a the level's, his
## wOWCoords1 and w2d100 with its offsets added).
func func_8212c() -> void:
	w2(W_LEVEL_1, r2(W_MAP_SIDE_LEVEL_ID))
	var at: int = get_map_level_coords(r2(W_MAP_SIDE_LEVEL_ID))
	var y: int = rb(MAP_BANK, at)
	var x: int = rb(MAP_BANK, at + 1)
	w2(W2D069, y)
	w2(W2D06A, x)
	w2(W_OW_Y_COORD_1, rb(MAP_BANK, at + 2) + y)
	w2(W2D100, rb(MAP_BANK, at + 2) + y)
	w2(W_OW_X_COORD_1, rb(MAP_BANK, at + 3) + x)
	w2(W2D101, rb(MAP_BANK, at + 3) + x)


## SetOWWarioOAM: Wario facing `direction` (OWWARIO_*; 0 hides him): his OAM table (OAM_aa329, or
## OAM_aa0cf for the arrows) and frameset (.framesets), his animation restarted.
func set_ow_wario_oam(direction: int) -> void:
	w2(W2D106, direction)
	if direction == 0:
		return
	var table: int = OAM_AA329 if direction < 5 else OAM_AA0CF
	var at: int = SET_OW_WARIO_OAM_FRAMESETS + (((direction - 1) * 2) & 0xFF)
	wr_word(W2D109, rw(MAP_BANK, at))
	wr_word(W2D107, table)
	w2(W2D104, 0)
	w2(W2D104 + 1, 0)


## Func_82041: w2d10d counts while Wario walks to another level (a sound on its first loop, not
## ported); a new wLevelArrowDirections1 turns him; then Func_8208d.
func func_82041() -> void:
	if r2(W2D068) == r2(W_MAP_SIDE_LEVEL_ID):
		w2(W2D10D, 0)
	else:
		w2(W2D10D, r2(W2D10D) + 1)  # PlaySFX_12A on the first (not ported)
		var limit: int = 0x09 if (r2(W2D10E) & 0x80) != 0 else 0x24
		if r2(W2D10D) >= limit:
			w2(W2D10D, 0)
	var directions: int = r2(W_LEVEL_ARROW_DIRECTIONS_1)
	if directions != r2(W2D10C):
		w2(W2D10C, directions)
		var direction: int = OWWARIO_DOWN
		if (directions & PAD_UP) != 0:
			direction = OWWARIO_UP
		elif (directions & PAD_RIGHT) != 0:
			direction = OWWARIO_RIGHT
		elif (directions & PAD_LEFT) != 0:
			direction = OWWARIO_LEFT
		set_ow_wario_oam(direction)
	func_8208d()


## Func_8208d: Wario (w2d100) animated with his frameset and drawn with his OAM table, unless hidden.
func func_8208d() -> void:
	if r2(W2D106) == 0:
		return
	update_ow_animation(W2D104, rd_word(W2D109), OBJECTS_BANK)
	load_ow_sprite_with_scroll(W2D100, rd_word(W2D107), OBJECTS_BANK)


# --- the top bar's buttons ---

## SetDayNightSpellSelectable: with the Day or Night Spell (on the East side, the Sun Medallion too).
func set_day_night_spell_selectable() -> void:
	if is_treasure_collected(DAY_OR_NIGHT_SPELL) == 0:
		return
	if r2(W_CUR_MAP_SIDE) == EAST and r2(W_GOT_SUN_MEDALLION) == 0:
		return
	w2(W_TOP_BAR_SELECTABLE_BUTTONS, r2(W_TOP_BAR_SELECTABLE_BUTTONS) | TOPBAR_DAY_NIGHT)


## SetCutsceneButtonSelectable: with a cutscene to play again (wStoredTransitionParam neither
## TRANSITION_RETURN_TO_MAP nor 0).
func set_cutscene_button_selectable() -> void:
	var stored: int = r2(W_STORED_TRANSITION_PARAM)
	if stored == TRANSITION_RETURN_TO_MAP or stored == 0:
		return
	w2(W_TOP_BAR_SELECTABLE_BUTTONS, r2(W_TOP_BAR_SELECTABLE_BUTTONS) | TOPBAR_CUTSCENE)


## SetNextPrevMapButtonsSelectable: the map sides accessible (.CheckAccessibleMapSides: West, South,
## East, North by their events, North also as bit 4) into wAccessibleMapSides, and the next and
## previous map buttons from them.
func set_next_prev_map_buttons_selectable() -> void:
	for pair: Array in [[EVENT_OPEN_NORTH_GATE, 3], [EVENT_FIX_ELEVATOR, 2], [EVENT_BLOW_MIST, 1],
			[EVENT_TORCH_FOREST, 0]]:
		var unlocked: int = check_if_event_is_unlocked(pair[0])
		w2(W_ACCESSIBLE_MAP_SIDES, r2(W_ACCESSIBLE_MAP_SIDES) | ((unlocked << int(pair[1])) & 0xFF))
	var sides: int = r2(W_ACCESSIBLE_MAP_SIDES)
	w2(W_ACCESSIBLE_MAP_SIDES, sides | ((sides & 1) << 4))
	w2(W_TOP_BAR_SELECTABLE_BUTTONS, r2(W_TOP_BAR_SELECTABLE_BUTTONS) | get_accessible_map_flags())


## GetAccessibleMapFlags: wAccessibleMapSides shifted by wCurMapSide, its next and previous map bits.
func get_accessible_map_flags() -> int:
	return (r2(W_ACCESSIBLE_MAP_SIDES) << r2(W_CUR_MAP_SIDE)) & (TOPBAR_NEXT_MAP | TOPBAR_PREV_MAP)


## UpdateNextPrevMapButtonsSelectable: with a bar open and the next or previous map selected but not
## selectable, the other one selected.
func update_next_prev_map_buttons_selectable() -> void:
	if r2(W_OW_BARS_STATE) == 0:
		return
	var selection: int = r2(W_TOP_BAR_SELECTION) & (TOPBAR_NEXT_MAP | TOPBAR_PREV_MAP)
	if selection == 0 or (get_accessible_map_flags() & selection) != 0:
		return
	var current: int = r2(W_TOP_BAR_SELECTION)
	if (current & TOPBAR_NEXT_MAP) != 0:
		w2(W_TOP_BAR_SELECTION, (current & ~TOPBAR_NEXT_MAP) | TOPBAR_PREV_MAP)
	else:
		w2(W_TOP_BAR_SELECTION, (current & ~TOPBAR_PREV_MAP) | TOPBAR_NEXT_MAP)


# --- the top bar's buttons and objects (bank $20) ---

const W_OW_UI_OBJ_1: int = 0xD140  # wOWUIObj1, wOWUIObj2, then two more objects (the arrows' trails)
const W_OW_UI_OBJ_2: int = 0xD148
const OAM_A9FE2: int = 0x5FE2  # bank $2a: the top bar's objects
const PALS_84900_OBJ_4: int = 0x4920  # bank $21: Pals_84900 palette 4, the map sides' (8 palettes each)
## ShowTopBarSelectedButton.button_data (bank $20): x and state of wOWUIObj1 by button (the Day Spell,
## the cutscene, the collection, the next map, the previous map, the Night Spell).
const TOP_BAR_BUTTON_DATA: int = 0x64DE
## Func_82521's framesets (bank $2a) by the UI object's state 1 to $0e, and the state its framesets 6
## and 8 hand over to when they end.
const TOP_BAR_FRAMESETS: Array[int] = [0x6091, 0x6094, 0x6097, 0x609A, 0x609D, 0x60BC, 0x60A3, 0x60C1, 0x60A9,
		0x60AE, 0x60B1, 0x60C6, 0x60B4, 0x60B9]
## The top bar's button tiles (two rows) and attributes (two rows) (bank $20, Data_826be to
## Data_826ee): not selectable, selectable Day/Night, cutscene, collection, selected, selected
## collection, pressed.
const TOP_BAR_NOT_SELECTABLE: Array[int] = [0x3C, 0x3C, 0x3D, 0x3D, 0x0F, 0x2F, 0x0F, 0x2F]
const TOP_BAR_DAY_NIGHT: Array[int] = [0x3E, 0x3E, 0x3F, 0x3F, 0x0F, 0x2F, 0x0F, 0x2F]
const TOP_BAR_CUTSCENE: Array[int] = [0x3A, 0x3A, 0x3B, 0x3B, 0x0F, 0x2F, 0x0F, 0x2F]
const TOP_BAR_COLLECTION: Array[int] = [0x38, 0x38, 0x39, 0x39, 0x0F, 0x2F, 0x0F, 0x2F]
const TOP_BAR_SELECTED: Array[int] = [0x34, 0x35, 0x36, 0x37, 0x0F, 0x0F, 0x0F, 0x0F]
const TOP_BAR_SELECTED_COLLECTION: Array[int] = [0x30, 0x31, 0x32, 0x33, 0x0F, 0x0F, 0x0F, 0x0F]
const TOP_BAR_PRESSED: Array[int] = [0x48, 0x49, 0x4A, 0x4B, 0x0F, 0x0F, 0x0F, 0x0F]
## The buttons' places in wAttrmap (row 19, columns 11, 9, 7: the attributes; their tiles two rows
## lower).
const TOP_BAR_DAY_NIGHT_AT: int = W_ATTRMAP + 19 * TILEMAP_WIDTH + 11
const TOP_BAR_CUTSCENE_AT: int = W_ATTRMAP + 19 * TILEMAP_WIDTH + 9
const TOP_BAR_COLLECTION_AT: int = W_ATTRMAP + 19 * TILEMAP_WIDTH + 7


## UpdateTopBar.InitTopBarButtons: the selected button and its attributes, the UI objects placed and
## drawn, the top bar's object palettes into wTempPals2's palettes 4 to 7.
func init_top_bar_buttons() -> void:
	show_top_bar_selected_button()
	load_top_bar_button_attributes()
	w2(W_OW_UI_OBJ_1 + SCENE_OBJ_Y, 0)
	w2(W_OW_UI_OBJ_2 + SCENE_OBJ_Y, 0)
	w2(W_OW_UI_OBJ_2 + SCENE_OBJ_X, 0x1C)
	draw_top_bar()
	copy_rom(0x21, PALS_84A20, W_TEMP_PALS_2 + 4 * 8, 4 * 8)


## ShowTopBarSelectedButton: wOWUIObj1 at the selected button's x in its state (the Day Spell's the
## Night Spell's at night), its animation from the start; wOWUIObj2 the NEXT MAP sign ($0b) with the
## next or previous map selected, else none.
func show_top_bar_selected_button() -> void:
	var selection: int = r2(W_TOP_BAR_SELECTION)
	var button: int = 4  # the previous map: no other bit set
	if (selection & TOPBAR_DAY_NIGHT) != 0:
		button = 5 if r2(W2D011) != 0 else 0
	else:
		for bit: int in range(1, 4):
			if (selection & (1 << bit)) != 0:
				button = bit
				break
	w2(W_OW_UI_OBJ_1 + SCENE_OBJ_X, rb(MAP_BANK, TOP_BAR_BUTTON_DATA + button * 2))
	_restart_ui_obj(W_OW_UI_OBJ_1, rb(MAP_BANK, TOP_BAR_BUTTON_DATA + button * 2 + 1))
	_restart_ui_obj(W_OW_UI_OBJ_2, 0x0B if (selection & (TOPBAR_NEXT_MAP | TOPBAR_PREV_MAP)) != 0 else 0x00)


## A UI object's state set, its frameset offset and duration cleared.
func _restart_ui_obj(obj: int, state: int) -> void:
	w2(obj + SCENE_OBJ_STATE, state)
	w2(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
	w2(obj + SCENE_OBJ_DURATION, 0)


## LoadTopBarButtonAttributes: the Day/Night, cutscene, and collection buttons drawn selectable or not
## (wTopBarSelectableButtons), then the selected one of them as selected.
func load_top_bar_button_attributes() -> void:
	var selectable: int = r2(W_TOP_BAR_SELECTABLE_BUTTONS)
	var buttons: Array = [[TOP_BAR_DAY_NIGHT, TOP_BAR_DAY_NIGHT_AT, TOP_BAR_SELECTED],
			[TOP_BAR_CUTSCENE, TOP_BAR_CUTSCENE_AT, TOP_BAR_SELECTED],
			[TOP_BAR_COLLECTION, TOP_BAR_COLLECTION_AT, TOP_BAR_SELECTED_COLLECTION]]
	for bit: int in buttons.size():  # .LoadSelectableAttrs
		var data: Array[int] = buttons[bit][0] if (selectable & (1 << bit)) != 0 else TOP_BAR_NOT_SELECTABLE
		write_top_bar_button(data, buttons[bit][1])
	var selection: int = r2(W_TOP_BAR_SELECTION)
	for bit: int in buttons.size():  # .LoadSelectedAttrs
		if (selection & (1 << bit)) != 0:
			write_top_bar_button(buttons[bit][2], buttons[bit][1])


## Func_8269f: a button's tiles to wAttrmap two rows below `at` (2 by 2), its attributes at `at`.
func write_top_bar_button(data: Array[int], at: int) -> void:
	for row: int in 2:
		for column: int in 2:
			w2(at + 2 * TILEMAP_WIDTH + row * TILEMAP_WIDTH + column, data[row * 2 + column])
			w2(at + row * TILEMAP_WIDTH + column, data[4 + row * 2 + column])


## ApplyTopBarButtonAttributes: wAttrmap's rows 21 and 22 (the tiles) to BG map 0's row 30 by wHDMA,
## its rows 19 and 20 (the attributes) to VRAM 1's by w2d0b5, at the next V-Blank.
func apply_top_bar_button_attributes() -> void:
	for pair: Array in [[W_HDMA, W_ATTRMAP + 0x2A * 0x10], [W2D0B5, W_ATTRMAP + 0x26 * 0x10]]:
		w2(pair[0], pair[1] >> 8)
		w2(pair[0] + 1, pair[1] & 0xFF)
		w2(pair[0] + 2, 0x1B)
		w2(pair[0] + 3, 0xC0)
		w2(pair[0] + 4, 4 - 1)  # 4 dma_tiles


## DrawTopBar: the selected button's object (Func_824f1) and, in a state, the NEXT MAP sign's
## (Func_8250a), animated and drawn with OAM_a9fe2.
func draw_top_bar() -> void:
	w2(W_OW_ANIMATION_FINISHED, 0)
	animate_top_bar_obj(W_OW_UI_OBJ_1)
	load_ow_sprite_with_scroll(W_OW_UI_OBJ_1, OAM_A9FE2, OBJECTS_BANK)
	if r2(W_OW_UI_OBJ_2 + SCENE_OBJ_STATE) == 0:
		return
	animate_top_bar_obj(W_OW_UI_OBJ_2)
	load_ow_sprite_with_scroll(W_OW_UI_OBJ_2, OAM_A9FE2, OBJECTS_BANK)


## Func_82521: the UI object's frameset by its state (none in 0); the pressed Night and Day Spells' (6,
## 8) go on to the Day and Night Spell's (7, 5) once they end, animated the same loop.
func animate_top_bar_obj(obj: int) -> void:
	var state: int = r2(obj + SCENE_OBJ_STATE)
	if state == 0:
		return
	if state > TOP_BAR_FRAMESETS.size():
		_note("Func_82521 state $%02x (past its table)" % state)
		return
	update_ow_animation(obj + SCENE_OBJ_DURATION, TOP_BAR_FRAMESETS[state - 1], OBJECTS_BANK)
	if (state != 6 and state != 8) or r2(W_OW_ANIMATION_FINISHED) != 0xFF:
		return
	_restart_ui_obj(obj, 7 if state == 6 else 5)
	animate_top_bar_obj(obj)


# --- the level's name, the compass, the bottom bar ---

## LoadLevelNameIfValid: the name of wNextMapSide's level wMapSideLevelID (not an exit).
func load_level_name_if_valid() -> void:
	if r2(W_MAP_SIDE_LEVEL_ID) < 0x08:
		load_level_name(r2(W_NEXT_MAP_SIDE), r2(W_MAP_SIDE_LEVEL_ID))


## SetCompassSprite: the compass at ($14, $14), its frame the map side.
func set_compass_sprite() -> void:
	wr(W_COMPASS_OBJ + SCENE_OBJ_Y, 0x14)
	wr(W_COMPASS_OBJ + SCENE_OBJ_X, 0x14)
	wr(W_COMPASS_OBJ + SCENE_OBJ_FRAME, r2(W_CUR_MAP_SIDE))


## DrawBottomBar: the level's four treasures (frame 0 to 3 with their palettes if got, wBottomBarFlags
## bits 0 to 3, else frame 9), the button prompt, and the 8-coin; Time Attack's time instead
## (Func_82997).
func draw_bottom_bar() -> void:
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0:
		_func_829a1()
	else:
		for index: int in NUM_LEVEL_TREASURES:
			var got: bool = (r2(W_BOTTOM_BAR_FLAGS) & (1 << index)) != 0
			load_sprite_inside_window(0x24, 0x20 + index * 0x1C, index if got else 0x09,
					r2(W_LEVEL_GREY_TREASURE_PAL + index) if got else 0x00)
	draw_bottom_bar_button_prompt()
	draw_bottom_bar_8_coin()


## LoadSpriteInsideWindow: frame `frame` of OAM_aa0cf at the window's position plus (y, x).
func load_sprite_inside_window(y: int, x: int, frame: int, attributes: int) -> void:
	wCurSpriteYCoord = byte(r2(W_WY) + y)
	wCurSpriteXCoord = byte(r2(W_WX) + x)
	wCurSpriteFrame = frame
	wCurSpriteAttributes = attributes
	load_ow_sprite_got_params(OAM_AA0CF, OBJECTS_BANK)


## DrawBottomBar8Coin: with wBottomBarFlags bit 7, the 8-coin animated (the compass's state and next
## byte as its duration and offset, its frame two before) and drawn.
func draw_bottom_bar_8_coin() -> void:
	if (r2(W_BOTTOM_BAR_FLAGS) & 0x80) == 0:
		return
	update_ow_animation(W_COMPASS_OBJ + SCENE_OBJ_STATE, FRAMESET_AA2FB, OBJECTS_BANK)
	load_sprite_inside_window(0x24, 0x90, rd(W_COMPASS_OBJ + SCENE_OBJ_DURATION), 0x00)


## DrawBottomBarButtonPrompt: with the Magnifying Glass, its button (frame 4; 6 at The Temple or none,
## 5 with wBottomBarFlags bit 4) from OAM_aa580.
func draw_bottom_bar_button_prompt() -> void:
	if r2(W_HAS_MAGNIFYING_GLASS) == 0:
		return
	var frame: int = 0x04
	if (r2(W_OW_LEVEL) * 2) & 0xFF == 0:
		frame = 0x06
	elif (r2(W_BOTTOM_BAR_FLAGS) & 0x10) != 0:
		frame = 0x05
	wCurSpriteFrame = frame
	wCurSpriteYCoord = byte(r2(W_WY) + 0x10)
	wCurSpriteXCoord = byte(r2(W_WX) + 0x10)
	wCurSpriteAttributes = 0x00
	load_ow_sprite_got_params(OAM_AA580, OBJECTS_BANK)


## Func_829a1: Time Attack's time (w2d0ee, w2d0ef: a digit per nybble, frames $1e on).
func _func_829a1() -> void:
	var digits: Array = [[W2D0EE, 4, 0x50], [W2D0EE, 0, 0x58], [W2D0EF, 4, 0x68], [W2D0EF, 0, 0x70]]
	for digit: Array in digits:
		load_sprite_inside_window(0x20, digit[2], ((r2(digit[0]) >> int(digit[1])) & 0x0F) + 0x1E, 0x00)
