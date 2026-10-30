class_name LevelSim
extends ObjectInteractions
## One frame of UpdateLevel (src/engine/level/update_level.asm) as far as it is ported: Wario's
## update, the scroll shadows, Wario's screen position, and the camera (camera.asm), plus the
## camera's room setup (LoadRoom, SetInitialCameraScroll, ApplyInitialCameraScroll in
## start_room.asm). Objects, interactions, and drawing the level's tiles are not ported.
## Research note: docs/02-research/level-camera.md.


## Wario's level start (WarioSim.start_level) with LoadRoom's camera variables first and the
## initial camera after, in StartRoom_FromLevelStart's order. The result is the state when the
## level becomes playable, in SST_UPDATE_LEVEL: a level started from its data (LevelRunner.start)
## begins there; one entered from the map (init_level) fades in first.
func start_level_with_camera(level_room_id: int, x: int, y: int, fields: Dictionary) -> void:
	clear_particles()  # InitLevel
	wRoomAnimatedTilesEnabled = 0  # StartRoom_FromLevelStart
	wRoomAnimatedPalsEnabled = 0
	write_level_ram(W_UNUSED_CA6C, 0)  # StartRoom_FromLevelStart
	write_level_ram(W_TEMP_LEVEL_ROOM_ID, 0)
	for offset: int in 3:
		write_level_ram(W_LEVEL_TIME + offset, 0)
	clear_objects(true)  # InitObjectVars_FromLevelStart
	load_room_camera(fields)
	load_object_group(wObjectGroup)
	start_level(level_room_id, x, y, int(fields.get("camera_config", 0)))
	# StartRoom_FromLevelStart clears the room's animation before LoadRoom sets it up: set up again
	# after start_level's clears (WarioSim.start_level clears with the rest).
	init_room_animated_tiles(int(fields.get("animated_tiles_group", 0)))
	init_room_animated_pals(int(fields.get("pal_cycle", 0)))
	set_initial_camera_scroll()
	apply_initial_camera_scroll()
	spawn_room_objects()
	_start_temple_scroll()
	displayed_camera_x = wCameraSCX
	displayed_camera_y = wCameraSCY
	set_wario_screen_pos()
	_first_object_updates()
	draw_objects()
	draw_wario()
	wRoomAnimatedTilesEnabled = 1  # InitLevel, after the room start
	wSubState = SST_UPDATE_LEVEL


## StartRoom_FromLevelStart for a level resumed from a save (wceef bits 2-5, WL3-056): nothing reset
## and no objects set up (the save's WRAMX bank 1 kept), the room the save left (wTempLevelRoomID),
## Wario where and as the save left him with his tiles reloaded (LoadWarioGfx), LoadRoom, the initial
## camera without its Y part in a room with transitions, no room objects spawned, and one
## UpdateObjects with wIsFloorTransition set. The level map is SRAM's (loaded_sram): the
## decompressors leave it.
func resume_level_with_camera() -> void:
	clear_particles()  # InitLevel
	wIsBossBattle = 0
	wLevelRoomID = read_level_ram(W_TEMP_LEVEL_ROOM_ID)
	wIsDMATransferPending = 1  # LoadWarioGfx: the tiles of wDMASourceBank:wDMASourcePtr
	_load_saved_level_map()
	var fields: Dictionary = level.room_fields.get(wLevelRoomID, {})
	load_room_camera(fields)
	load_object_group(wObjectGroup)
	set_initial_camera_scroll(true)
	apply_initial_camera_scroll()
	_start_temple_scroll()
	displayed_camera_x = wCameraSCX
	displayed_camera_y = wCameraSCY
	set_wario_screen_pos()
	wBlockFuncWarioFlag = 0
	wIsFloorTransition = 1
	update_objects()
	wIsFloorTransition = 0
	draw_objects()
	draw_wario()
	wRoomAnimatedTilesEnabled = 1  # InitLevel, after the room start
	wSubState = SST_UPDATE_LEVEL


## SRAM banks 0-3 (8 KiB each from $a000) as the save's last load left them (LevelRunner.
## load_power_on_ram: at power-on and at each reset, Init), empty otherwise. Banks 1 and 2 hold the
## level map a level resumed from a save plays on, a 256-byte page a row (the blocks, the unwritten
## bytes, then the object map from $b0); the pause menu's saves write banks 0, 2 and 3 in its own copy.
var loaded_sram: Array = []
## The level map in SRAM banks 1 and 2: as the last load left it, a level's as played since (InitLevel
## decompresses it there; the port keeps it as the LevelSim's LevelCollision, with the bytes InitLevel
## leaves), or a level's as SaveLevel saved it (its 48 rows the port keeps, and its backup).
enum LevelMapSram { LOADED, PLAYED, SAVED }
var level_map_sram: LevelMapSram = LevelMapSram.LOADED


## The level's map from loaded_sram, which DecompressLevelBlockMap and DecompressLevelObjectMap
## leave for a resumed level: its 64 rows of blocks with their unwritten bytes, and its 48 object rows.
func _load_saved_level_map() -> void:
	var rows: Array = []
	var gaps: Array = []
	level.object_rows.clear()
	for row: int in LevelCollision.HEIGHT:
		var bank: PackedByteArray = loaded_sram[1 + row / 32]
		var page: int = (row % 32) * 0x100
		rows.append(bank.slice(page, page + LevelCollision.WIDTH).hex_encode())
		gaps.append(bank.slice(page + LevelCollision.WIDTH, page + LevelCollision.OBJECT_MAP_OFFSET).hex_encode())
		if row < LEVEL_OBJECT_ROWS:
			level.object_rows.append(bank.slice(page + LevelCollision.OBJECT_MAP_OFFSET, page + 0x100))
	level.set_rows(rows)
	level.set_gap_rows(gaps)


const LEVEL_OBJECT_ROWS: int = 48


## The levels' data by wLevel for InitLevel: (wLevel) -> LevelCollision, or null when it is not
## extracted; native play loads levels/level-XX.json, as parity runs do.
var level_loader: Callable = Callable()


## InitLevel (src/engine/level/init.asm), sub-state 1, entering a level from the map: the scroll reset,
## LoadLevelCommonGfxAndTreasures (the common tiles to VRAM; LoadLevelTreasureData, the level's
## treasures, their palettes, and tiles in the map's RAM), the level wLevel loaded and started
## (StartRoom_FromLevelStart: start_level_with_camera), the room animation on, wceef cleared, SRAM
## bank 0's first four bytes at $a000 and at $a800 cleared, then the fade in (sub-state 2). VRAM, the
## LCD, and the music are not ported. A level resumed from a save (wceef bits 2-5) starts as the save
## left it (resume_level_with_camera), from the SRAM the save's load left (loaded_sram).
func init_level() -> void:
	var resumed: bool = (wceef & 0x3C) != 0
	if resumed and (loaded_sram.size() < 4 or level_map_sram != LevelMapSram.LOADED):
		note_unported("InitLevel: a level resumed from a save (the save's SRAM not given)")
		return
	var loaded: LevelCollision = level_loader.call(wLevel) if level_loader.is_valid() else null
	if loaded == null or loaded.start.is_empty():
		note_unported("InitLevel: level $%02x not loaded" % wLevel)
		return
	wSCY = 0
	wSCX = 0
	if overworld != null:
		overworld.unported.clear()
		overworld.load_level_treasure_data()
		for note: String in overworld.unported:
			note_unported(note)
	level = loaded
	if not resumed:
		_keep_sram_unwritten_bytes()
	level_map_sram = LevelMapSram.PLAYED
	if resumed:
		resume_level_with_camera()
	else:
		var room: int = int(level.start.get("level_room_id", 0))
		start_level_with_camera(room, int(level.start["wario_x"]), int(level.start["wario_y"]),
				level.room_fields.get(room, {}))
	wceef = 0
	if pause_menu_screen != null:
		for address: int in [0xA000, 0xA001, 0xA002, 0xA003, 0xA800, 0xA801, 0xA802, 0xA803]:
			pause_menu_screen.ws(0, address, 0)
	if wLevel == THE_TEMPLE:  # .final_battle: LoadHiddenFigureGfx (drawn by TempleVram) and the window's y
		hidden_figure_gfx_loads += 1
		hidden_figure_bg_pals = 0
		wc08d = 0x88
		rWY = wc08d
	wSubState = SST_SLOW_FADE_FROM_WHITE


## The level map's bytes DecompressLevelBlockMap never writes stay as SRAM had them: each row's
## $a0-$af, and rows 48-63 below the 48 it decompresses (bank 2's second half). Rows 0-47 are as the
## last load left them (nothing writes them after it), rows 48-63 too unless SaveLevel's backup copied
## rows 32-47 over them since (the pause menu's bank 2). Given to a level without its own (an extracted
## level has neither: its rows 48-63 are zero) when the load's SRAM is known.
func _keep_sram_unwritten_bytes() -> void:
	if loaded_sram.size() != 4 or not level.gap_rows.is_empty():
		return
	var bank_2: PackedByteArray = _sram_bank_2()
	var gaps: Array = []
	for row: int in LevelCollision.HEIGHT:
		var bank: PackedByteArray = loaded_sram[1] if row < 32 else bank_2
		var page: int = (row % 32) * 0x100
		gaps.append(bank.slice(page + LevelCollision.WIDTH, page + LevelCollision.OBJECT_MAP_OFFSET).hex_encode())
		if row >= LEVEL_MAP_SRAM_ROWS:
			for column: int in LevelCollision.WIDTH:
				level.set_block(row, column, bank[page + column])
	level.set_gap_rows(gaps)


## SRAM bank 2 as the last load left it, with the pause menu's writes (SaveLevel's backup in its
## second half).
func _sram_bank_2() -> PackedByteArray:
	if pause_menu_screen != null and pause_menu_screen.sram.has(2):
		return pause_menu_screen.sram[2]
	return loaded_sram[2]


## Both room starts run UpdateObjects twice once the room's objects are spawned (start_room.asm).
func _first_object_updates() -> void:
	wBlockFuncWarioFlag = 0
	wIsFloorTransition = 0
	update_objects()
	update_objects()


## LoadRoom's camera part: screen-position history, spacings, and the header's section limits.
func load_room_camera(fields: Dictionary) -> void:
	wPrevWarioScreenYPos = 0x70
	wCamRightSpacing = 0x58
	wCamLeftSpacing = 0x58
	wRoomUpperYLimit = int(fields.get("upper_y_limit", 0)) & 0x0F
	wRoomLowerYLimit = int(fields.get("lower_y_limit", 0)) & 0x0F
	wRoomLeftXLimit = int(fields.get("left_x_limit", 0)) & 0x0F
	wRoomRightXLimit = int(fields.get("right_x_limit", 0)) & 0x0F
	wCameraConfigFlags = int(fields.get("camera_config", 0))
	# The same limits as SRAM pages (rows) and object-map bytes (columns), for Func_896f; a sum
	# that wraps to 0 stands for $ff.
	wc0c4 = byte(wRoomLowerYLimit * 16 + 0xA0)
	if wc0c4 == 0:
		wc0c4 = 0xFF
	wc0c5 = byte(wRoomUpperYLimit * 16 + 0xA0)
	wc0c7 = byte(wRoomRightXLimit * 8 + 0xB0)
	if wc0c7 == 0:
		wc0c7 = 0xFF
	wc0c6 = byte(wRoomLeftXLimit * 8 + 0xB0)
	wObjectGroup = int(fields.get("object_group", 0))
	init_room_animated_tiles(int(fields.get("animated_tiles_group", 0)))
	init_room_animated_pals(int(fields.get("pal_cycle", 0)))


# --- Room animation (src/engine/level/update_animated_tiles.asm, home/load_room.asm) ----------

## The room's animated tiles: wAnimatedTilesGfx's four frames of eight tiles take turns in VRAM
## bank 1's tiles $70-$77, every wAnimatedTilesFrameDuration loops; and its palette cycle: the
## eight RoomPals entries of wRoomPalCycle take turns as the BG palettes. Presentation reads them,
## but they are game state (counted per loop). A loop late in the frame skips them (rLY), which
## parity runs replay from the oracle; native play is never late (provisional).
var room_animation: Dictionary = {}  # rooms/animation.json
## Whether an animated-tiles frame or a cycled palette has been written since the room loaded
## (until then VRAM and the BG palettes hold the room's own), for presentation.
var animated_tiles_written: bool = false
## Animated tile frames written so far (each to VRAM bank 1's $9700), for drawing.
var animated_tiles_writes: int = 0
var cycled_palettes_written: bool = false
var animation_replay: bool = false
var animation_queue: Array = []  # [kind (0 tiles, 1 palettes), rLY read]
var animation_mismatches: PackedStringArray = PackedStringArray()
const ROOM_PALCYCLE_LENGTH: int = 8
const ST_CLEAR: int = 0x03
const ST_PAUSE_MENU: int = 0x04
const ST_GOLF: int = 0x05
const ST_GOLF_BUILDING: int = 0x0A
const ST_EPILOGUE: int = 0x06
const W3D50D: int = 0xD50D  # in GFX RAM (WRAMX bank 3)
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_TRANSITION_PARAM: int = 0xCEE3
const MODE_GAME_CLEARED: int = 0x01
const MODE_TIME_ATTACK: int = 0x02
const MODE_FOUGHT_A_HIDDEN_FIGURE: int = 0x04
const TRANSITION_EPILOGUE_NOT_PERFECT: int = 0xF1
const TRANSITION_EPILOGUE_PERFECT: int = 0xF2
const TRANSITION_GAME_OVER: int = 0xF3
const SST_CLEAR_TIME_ATTACK: int = 0x04
var wPendingSubState: int = 0
const LY_VBLANK: int = 144


## InitRoomAnimatedTiles
func init_room_animated_tiles(group: int) -> void:
	wAnimatedTilesGroup = group
	var groups: Array = room_animation.get("animated_tiles_groups", [])
	var entry: Array = groups[group] if group < groups.size() else [0, 0]
	wAnimatedTilesFrameDuration = int(entry[0])
	wAnimatedTilesGfx = int(entry[1])
	wAnimatedTilesFrame = 0
	wAnimatedTilesFrameCount = 0
	animated_tiles_written = false


## InitRoomAnimatedPals: the counter starts half way.
func init_room_animated_pals(cycle: int) -> void:
	wRoomPalCycle = cycle
	var cycles: Array = room_animation.get("pal_cycles", [])
	wRoomPalCycleDuration = int(cycles[cycle]["duration"]) if cycle < cycles.size() else 0
	wRoomPalCycleCounter = wRoomPalCycleDuration >> 1
	wRoomPalCycleIndex = 0
	cycled_palettes_written = false


## The end of every .GameLoop: the room's animations, where enabled.
func update_room_animations() -> void:
	if wRoomAnimatedTilesEnabled != 0:
		update_room_animated_tiles()
	if wRoomAnimatedPalsEnabled != 0:
		update_room_animated_pals()


## Whether the loop reached the routine within `margin` lines of V-Blank (rLY), as replayed.
func _animation_late(kind: int, margin: int) -> bool:
	if not animation_replay:
		return false
	if animation_queue.is_empty() or int(animation_queue[0][0]) != kind:
		animation_mismatches.append("an animation call (%d) the original did not make here" % kind)
		return false
	return int(animation_queue.pop_front()[1]) >= LY_VBLANK - margin


## UpdateRoomAnimatedTiles
func update_room_animated_tiles() -> void:
	if _animation_late(0, 20) or wAnimatedTilesFrameDuration == 0:
		return
	wAnimatedTilesFrameCount = byte(wAnimatedTilesFrameCount + 1)
	if wAnimatedTilesFrameCount < wAnimatedTilesFrameDuration:
		return
	wAnimatedTilesFrameCount = 0
	wAnimatedTilesFrame = (wAnimatedTilesFrame + 1) & 0b11
	animated_tiles_written = true
	animated_tiles_writes += 1


## UpdateRoomAnimatedPals
func update_room_animated_pals() -> void:
	if _animation_late(1, 8) or wRoomPalCycleDuration == 0:
		return
	wRoomPalCycleCounter = byte(wRoomPalCycleCounter + 1)
	if wRoomPalCycleCounter < wRoomPalCycleDuration:
		return
	wRoomPalCycleCounter = 0
	wRoomPalCycleIndex = (wRoomPalCycleIndex + 1) % ROOM_PALCYCLE_LENGTH
	cycled_palettes_written = true


## The animated-tiles graphics and frame VRAM bank 1's tiles $70-$77 hold, or -1 while they hold
## the room's own special tiles.
func shown_animated_tiles() -> Array:
	return [wAnimatedTilesGfx, wAnimatedTilesFrame] if animated_tiles_written else [-1, 0]


## The RoomPals entry the BG palettes hold, or -1 while they hold the room record's own.
func shown_room_pals() -> int:
	var cycles: Array = room_animation.get("pal_cycles", [])
	if not cycled_palettes_written or wRoomPalCycle >= cycles.size():
		return -1
	return int(cycles[wRoomPalCycle]["palettes"][wRoomPalCycleIndex])


## wBlockYPos/wBlockXPos: a level position (16-bit) the edge drawing and object spawning start at.
var wBlockYPos: int = 0
var wBlockXPos: int = 0
## LoadRoom's room limits as SRAM pages (wc0c4 lower, wc0c5 upper) and object-map bytes (wc0c6
## left, wc0c7 right).
var wc0c4: int = 0
var wc0c5: int = 0
var wc0c6: int = 0
var wc0c7: int = 0


## The full scroll behind wSCX and wSCY: the camera when UpdateLevel copied it, before this frame's
## camera code. LevelVBlankFunc writes wSCX/wSCY to rSCX/rSCY, so this is what the next frame shows,
## together with the sprites drawn at wWarioScreenXPos/YPos. Presentation reads it; nothing else does.
var displayed_camera_x: int = 0
var displayed_camera_y: int = 0


## LevelVBlankFunc's effect on game state: a pending Wario graphics transfer is performed and
## cleared (src/home/level_vblank.asm). Runs between frames, including during the level's fade-in.
func vblank() -> void:
	wIsDMATransferPending = 0


## Level sub-states (_LevelStateTable, src/engine/level/state_table.asm). The first three enter a
## level from the map: FastFadeToWhite (slow, as the others), InitLevel, then SlowFadeFromWhite.
const SST_FADE_INTO_LEVEL: int = 0
const SST_INIT_LEVEL: int = 1
const SST_SLOW_FADE_FROM_WHITE: int = 2
const SST_UPDATE_LEVEL: int = 3
const SST_DOOR_TRANSITION: int = 4
const SST_FAST_FADE_TO_WHITE: int = 5
const SST_START_ROOM_FROM_TRANSITION: int = 6
const SST_LEVEL_MULTI_BLOCK: int = 7
## _GolfStateTable's sub-states the port runs: the fade out of the level, InitGolfLobby, the fade out
## of the minigame (SST_GOLF_EXIT), and ReturnToLevelFromGolf; the others are the minigame's.
const SST_GOLF_INIT_LOBBY: int = 1
const SST_GOLF_LOBBY: int = 2
const SST_GOLF_EXIT: int = 8
const SST_GOLF_RETURN: int = 9
const FADE_STEPS: int = 33  # FadeBGToWhite and DarkenBGToPal at FADE_SPEED_SLOW
## The loops of a fade by wFadeSpeed (slow, normal, fast), and the speed of the one running.
const FADE_STEPS_BY_SPEED: Array[int] = [33, 18, 10]
var wFadeSpeed: int = 0
const DOOR_TRANSITION_STEPS: int = 17

var wPalFadeCounter: int = 0
var wDoorTransitionCounter: int = 0
var wDoorTransitionOrientation: int = 0


## One iteration of .GameLoop in a level: the V-Blank before it, then the level sub-state.
## UpdateLevel runs only in SST_UPDATE_LEVEL; a room transition passes through the door effect,
## a fade to white, the next room's start, and a fade back, frame-counted as the original. After a
## key, the main state is ST_COLLECT_KEY instead, and only its delay runs. With resets allowed
## (wResetDisabled clear), A, B, Select and Start held together reset the game instead (Init); a
## state that jumps to Init (request_init) resets it once its loop is done, with no room animation.
func update_level() -> void:
	if wResetDisabled == 0 and (wJoypadDown & PAD_BUTTONS) == PAD_BUTTONS:
		init_game(0)
		return
	_update_level_state()
	if _init_request >= 0:
		var request: int = _init_request
		_init_request = -1
		init_game(request)
		return
	update_room_animations()


const PAD_BUTTONS: int = PAD_A | PAD_B | PAD_SELECT | PAD_START
## hDemoPowerUp (HRAM): the power-up Action Help's next demo on the title shows. Init clears it;
## InitWithoutDemoPowerUpReset, which the demos' end jumps to, keeps it.
var hDemoPowerUp: int = 0
## Init's ways in (src/home/start.asm, src/home/clear_save.asm): InitWithoutDemoPowerUpReset keeps
## hDemoPowerUp; ClearSaveData clears the save's check values first.
const INIT_KEEP_DEMO_POWER_UP: int = 1 << 0
const INIT_CLEAR_SAVE_DATA: int = 1 << 1
## A jump to Init the current loop made (request_init's flags), -1 for none.
var _init_request: int = -1
## The resets Init made, for drawing (it clears VRAM).
var resets: int = 0
## What Init does not reset: the extracted data, the levels' loader, and what a parity run feeds the
## game (the replayed rDIV reads, room animation calls, and golf visits); rDIV's own count goes on.
const KEPT_BY_INIT: PackedStringArray = ["tables", "level_loader", "room_animation", "movement_data", "pneumo_bob",
		"omodon_bob", "bank_data", "object_framesets", "object_group_pointers", "hidden_figure_group_pointers", "object_data", "object_params",
		"_object_functions", "particle_framesets", "_bot", "sync_screen_wram", "unported", "div_replay", "div_queue",
		"div_mismatches", "div_generator", "animation_replay", "animation_queue", "animation_mismatches",
		"golf_replay", "golf_queue", "golf_input", "golf_outcome"]


## `jp Init` (or InitWithoutDemoPowerUpReset, ClearSaveData: `flags`) from a state's loop: the rest
## of the loop does not run in the original, so the caller returns at once; Init follows the loop.
func request_init(flags: int = 0) -> void:
	_init_request = flags


## Init (src/home/start.asm), a reset: the stack, VRAM, WRAM, OAM, and HRAM but hDemoPowerUp cleared,
## the save loaded from SRAM as it is now (ValidateSaveData), and InitGameState's title, as at power-on
## (LevelRunner.load_power_on_ram), with hDemoPowerUp cleared unless INIT_KEEP_DEMO_POWER_UP (after
## ClearSaveData, INIT_CLEAR_SAVE_DATA, cleared too). The game is rebuilt in place: a LevelSim made as
## power-on makes one, with the screens' data loaded again, whose state this one takes (but
## KEPT_BY_INIT). The loop that jumped never ends: the next is counted 0 (the counter here is the one
## before it). Without the whole SRAM known (current_sram: no load, or a level's map without its
## unwritten bytes), not ported.
func init_game(flags: int) -> void:
	var banks: Array = current_sram()
	if banks.is_empty():
		note_unported("Init: SRAM not known whole (no load, or a level's map without its unwritten bytes)")
		return
	if (flags & INIT_CLEAR_SAVE_DATA) != 0:
		SaveLoad.clear_save_data(banks)
	var fresh := LevelSim.new()
	for name: String in KEPT_BY_INIT:
		fresh.set(name, get(name))
	if screen_wram.has("known"):
		fresh.track_known_ram()
	if golf != null:
		fresh.load_golf_data(golf.document)
	if clear != null:
		fresh.load_clear_data(clear.document)
	if action_help != null:
		fresh.load_action_help_data(action_help.document)
	if pause_menu_screen != null:
		fresh.load_pause_menu_data(pause_menu_screen.document)
	if overworld != null:
		fresh.load_overworld_data(overworld.document)
	if title != null:
		fresh.load_title_data(title.document)
	if credits != null:
		fresh.load_credits_data(credits.document)
	if game_over != null:
		fresh.load_game_over_data(game_over.document)
	if perfect != null:
		fresh.load_perfect_data(perfect.document)
	LevelRunner.load_power_on_ram(fresh, SaveLoad.save_bytes(banks))
	fresh.hDemoPowerUp = hDemoPowerUp if (flags & INIT_KEEP_DEMO_POWER_UP) != 0 else 0
	fresh.wGlobalCounter = 0xFF
	fresh.resets = resets + 1
	for property: Dictionary in get_property_list():
		var name: String = property["name"]
		if (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and not name in KEPT_BY_INIT:
			set(name, fresh.get(name))


## The level map's 48 rows as SRAM bank 1 and bank 2's first half hold them (S_LEVEL_BLOCK_OBJECT_MAP,
## S2A000: a 256-byte page a row) from the LevelCollision, or empty when a byte of it is not known.
func level_map_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()
	if level == null:
		return bytes
	for row: int in LEVEL_MAP_SRAM_ROWS:
		for column: int in 0x100:
			var value: int = level.block_at(row, column)
			if value < 0:
				return PackedByteArray()
			bytes.append(value)
	return bytes


const LEVEL_MAP_SRAM_ROWS: int = 48


## SRAM banks 0-3 as the game has them now: the last load's (loaded_sram) with the pause menu's writes
## (its saves to bank 0; SaveLevel's backup of the level map, bank 2's second half and bank 3, and
## InitLevel's clears), and after a level's play or its SaveLevel the level map (bank 1 and bank 2's
## first half: the LevelCollision's 48 rows, as played or as saved). Rows 48-63 (bank 2's second half)
## take the LevelCollision's blocks and unwritten bytes, which InitLevel took from there, and keep their
## object-map bytes. Empty when not known whole: no load, or a level played whose map lacks a byte (its
## unwritten bytes not known at InitLevel).
func current_sram() -> Array:
	if loaded_sram.size() != 4:
		return []
	var banks: Array = loaded_sram.duplicate()
	if pause_menu_screen != null:
		for bank: int in [0, 2, 3]:
			if pause_menu_screen.sram.has(bank):
				banks[bank] = pause_menu_screen.sram[bank]
	if level_map_sram != LevelMapSram.LOADED:
		var map: PackedByteArray = level_map_bytes()
		if map.is_empty():
			return []
		banks[1] = map.slice(0, SaveLoad.SRAM_SIZE)
		var bank_2: PackedByteArray = map.slice(SaveLoad.SRAM_SIZE)
		bank_2.append_array(banks[2].slice(SaveLoad.SRAM_SIZE / 2))
		for row: int in range(LEVEL_MAP_SRAM_ROWS, LevelCollision.HEIGHT):
			var page: int = (row - 32) * 0x100
			for column: int in LevelCollision.OBJECT_MAP_OFFSET:
				var value: int = level.block_at(row, column)
				if value < 0:
					return []
				bank_2[page + column] = value
		banks[2] = bank_2
	return banks


func _update_level_state() -> void:
	if wState == ST_COLLECT_KEY:
		_begin_frame()
		collect_key_delay()
		return
	if wState == ST_PAUSE_MENU:
		_begin_frame()
		if pause_menu_screen != null:
			pause_menu_state()
		else:
			pause_menu()
		return
	if wState == ST_CLEAR:
		_begin_frame()
		clear_state()
		return
	if wState == ClearSim.ST_ACTION_HELP:
		_begin_frame()
		action_help_state()
		return
	if wState == ST_OVERWORLD:
		_begin_frame()
		overworld_state()
		return
	if wState == ST_GOLF:
		_begin_frame()
		golf_state()
		return
	if wState == ST_GOLF_BUILDING:
		_begin_frame()
		golf_building_state()
		return
	if wState == ST_EPILOGUE:
		_begin_frame()
		epilogue_state()
		return
	if (wState == ST_TITLE or wState == TitleSim.ST_LANGUAGE_SELECTION) and title != null:
		_begin_frame()
		title_state()
		return
	if wState == ST_CREDITS and credits != null:
		_begin_frame()
		credits_state()
		return
	if wState == ST_GAME_OVER and game_over != null:
		_begin_frame()
		game_over_state()
		return
	if wState == ST_PERFECT and perfect != null:
		_begin_frame()
		perfect_state()
		return
	if wState != ST_LEVEL and wState != ST_TITLE:  # the language selection, the credits, ...
		_begin_frame()
		note_unported("wState $%02x" % wState)
		return
	_oam_screen = null
	match wSubState:
		SST_UPDATE_LEVEL:
			update_level_to_camera()
			if wCameraConfigFlags != HIDDEN_FIGURE_CAMCONFIG:
				stream_level_edges()
			check_end_screen()
		SST_DOOR_TRANSITION:
			_begin_frame()
			door_transition()
		SST_FADE_INTO_LEVEL, SST_FAST_FADE_TO_WHITE, SST_SLOW_FADE_FROM_WHITE:
			_begin_frame()
			fade_step()
		SST_INIT_LEVEL:
			_begin_frame()
			init_level()
		SST_START_ROOM_FROM_TRANSITION:
			_begin_frame()
			start_room_from_transition()
		SST_LEVEL_MULTI_BLOCK:
			_begin_frame()
			process_multi_block()
		_:
			_begin_frame()
			note_unported("level sub-state %d" % wSubState)


## UpdateLevel.check_end_screen, at the end of every UpdateLevel. Once the level's end screen is
## named and the scene before it is over (bit 7 clear), the level ends: the room animations stop and
## the game goes to the clear screen. A multi-block break waits for the next frame
## (SST_LEVEL_MULTI_BLOCK). Otherwise Start or Select pauses. Time Attack's clock (TickLevelTime)
## and bosses are not part of the port yet: their variables stay 0.
func check_end_screen() -> void:
	if wState != ST_LEVEL:
		return
	if wLevelEndScreen != 0:
		if (wLevelEndScreen & 0x80) != 0:
			return
		wResetDisabled = 1
		wGroundShakeCounter = 0
		wSCYShake = 0
		wAnimatedTilesFrameDuration = 0
		wRoomPalCycleDuration = 0
		wRoomAnimatedTilesEnabled = 0
		wRoomAnimatedPalsEnabled = 0
		wWaterCurrent = 0
		wLastWaterCurrent = 0
		wCurWaterCurrent = 0
		wSwimmingDirectionInput = 0
		var flags: int = read_level_ram(W_GAME_MODE_FLAGS)
		if wLevelEndScreen == LVLEND_GAME_OVER or wLevelEndScreen == LVLEND_EPILOGUE:
			# .game_over, .epilogue: the transition the map's epilogue takes, the game cleared (with
			# all 100 treasures, wNumCollectedTreasures' BCD $0100, Time Attack opened), the hidden
			# figure fought either way; then ST_EPILOGUE.
			var transition: int = TRANSITION_GAME_OVER
			if wLevelEndScreen == LVLEND_EPILOGUE:
				transition = TRANSITION_EPILOGUE_PERFECT if hi(wNumCollectedTreasures) == 0x01 else TRANSITION_EPILOGUE_NOT_PERFECT
				flags |= MODE_GAME_CLEARED | (MODE_TIME_ATTACK if transition == TRANSITION_EPILOGUE_PERFECT else 0)
			write_level_ram(W_TRANSITION_PARAM, transition)
			write_level_ram(W_GAME_MODE_FLAGS, flags | MODE_FOUGHT_A_HIDDEN_FIGURE)
			wState = ST_EPILOGUE
			wSubState = 0
			return
		wState = ST_CLEAR
		wSubState = SST_CLEAR_TIME_ATTACK if (flags & MODE_TIME_ATTACK) != 0 else 0
		return
	if wMultiBlockParam != 0:
		wPendingSubState = wSubState
		wSubState = SST_LEVEL_MULTI_BLOCK
		return
	if wFloorTransitionDir != 0 or wRoomTransitionParam != 0:
		return
	if (wJoypadPressed & (PAD_SELECT | PAD_START)) == 0:
		return
	if wTransformation == TRANSFORMATION_BLIND or wIsBossBattle != 0:
		return
	wRoomAnimatedPalsEnabled = 0
	write_level_ram(W_UNUSED_IS_PAUSED, 1)
	wPendingSubState = wSubState
	wState = ST_PAUSE_MENU
	wSubState = 0


## The pause menu without pause_menu.json (PauseMenuSim runs it when loaded). Approximation
## (provisional, ADR-0002): the level stands still until Start or Select is pressed again, then goes
## on as return_level.asm leaves it (the animated tiles enabled, the palettes from the next
## UpdateLevel).
func pause_menu() -> void:
	if (wJoypadPressed & (PAD_SELECT | PAD_START)) == 0:
		return
	wState = ST_LEVEL
	wSubState = wPendingSubState
	wRoomAnimatedTilesEnabled = 1


## CollectKeyDelay (src/engine/level/key_delay.asm): the game stands still for 100 loops after a
## key, then the level goes on where it stopped.
func collect_key_delay() -> void:
	wTimer += 1
	if wTimer < 100:
		return
	wTimer = 0
	wState = ST_LEVEL


## ProcessMultiBlock (SST_LEVEL_MULTI_BLOCK): the chain of breaks (WarioBlocks.process_multi_blocks,
## the tile queue between them presentation), the sub-state back, then only the particles and the
## drawing: Wario and the objects stand still this frame.
func process_multi_block() -> void:
	process_multi_blocks()
	wSubState = wPendingSubState
	update_particles()
	draw_objects()
	draw_wario()


func _begin_frame() -> void:
	unported.clear()
	handlers_run.clear()
	vblank()


## A fade's loop (FadeBGToWhite or DarkenBGToPal, src/home/fade.asm) at `speed`: a set-up loop, then
## palette steps (presentation); the sub-state advances when wPalFadeCounter reaches 33, 18, or 10 by
## speed, and wFadeSpeed is cleared. FastFadeToWhite and SlowFadeFromWhite are slow.
func fade_step(speed: int = 0) -> void:
	wFadeSpeed = speed
	if wPalFadeCounter == 0:
		wPalFadeCounter = 1
		return
	wPalFadeCounter += 1
	if wPalFadeCounter < FADE_STEPS_BY_SPEED[speed]:
		return
	wFadeSpeed = 0
	wPalFadeCounter = 0
	wSubState = byte(wSubState + 1)


## EpilogueStateTable (src/engine/overworld/epilogue/state_table.asm), which the hidden figure's
## fight ends in: FastFadeToWhite on every fourth loop, then Func_4628: the room's animated tiles
## stopped, w3d50d cleared, wDayNight's bit 7 set, and the map from its first sub-state
## (StartOverworldState), which plays the ending the fight's transition chose.
func epilogue_state() -> void:
	match wSubState:
		0:  # .FadeToWhite
			if (wGlobalCounter & 0b11) == 0:
				fade_step()
		1:  # .Func_473c
			wAnimatedTilesFrameDuration = 0
			wAnimatedTilesGfx = 0
			wAnimatedTilesFrameCount = 0
			wAnimatedTilesFrame = 0
			if screen_wram.has(3):
				screen_wram[3][W3D50D - 0xD000] = 0
				if screen_wram.has("known"):
					screen_wram["known"][3][W3D50D - 0xD000] = 1
			wDayNight |= 0x80
			wState = ST_OVERWORLD
			wSubState = 0
		var substate:
			note_unported("EpilogueStateTable sub-state %d" % substate)


## DoorTransition (home/door_transition.asm): the closing effect alternates two halves a frame and
## advances the sub-state after 17 full steps (34 frames).
func door_transition() -> void:
	if wDoorTransitionOrientation == 0 and wDoorTransitionCounter == 0:
		wDoorTransitionOrientation = 1
		return
	wDoorTransitionOrientation ^= 1
	if wDoorTransitionOrientation != 0:
		return
	wDoorTransitionCounter += 1
	if wDoorTransitionCounter < DOOR_TRANSITION_STEPS:
		return
	wDoorTransitionCounter = 0
	wDoorTransitionOrientation = 0
	wSubState = byte(wSubState + 1)


## StartRoom_FromTransition (start_room.asm), Wario's and the camera's part: the room whose section
## Wario is in (after moving him up 16 px), that room's header, its spawn, its camera, and its
## objects (despawned, cleared, and spawned again from the map). Graphics and music are not ported.
## UpdateSwitchableBlocks (switch.asm): after a switch, at the room start every block $60-$67 of
## the map's 48 rows becomes its $68-$6f twin (switch off), or back (wSwitchState $68, on); bit 7
## is kept.
func update_switchable_blocks() -> void:
	if wSwitchStateUpdated == 0:
		return
	wSwitchStateUpdated = 0
	var on: bool = wSwitchState == 0x68
	for row: int in 48:
		for column: int in LevelCollision.WIDTH:
			var value: int = level.block_at(row, column)
			var id: int = value & 0x7F
			if on and id >= 0x68 and id < 0x70:
				level.set_block(row, column, value - 8)
			elif not on and id >= 0x60 and id < 0x68:
				level.set_block(row, column, value + 8)


func start_room_from_transition() -> void:
	var kind: int = wRoomTransitionParam & ROOMTRANSITION_MASK
	if kind == ROOMTRANSITION_GOLF:
		enter_golf()
		return
	despawn_all_objects()
	clear_objects(false)  # InitObjectVars_FromTransition
	if kind == ROOMTRANSITION_TELEPORT:
		wWarioYPos = 0x0100 | lo(wWarioYPos)
		wWarioXPos = lo(wWarioXPos)
	wWarioYPos = word(wWarioYPos - 0x10)
	var y_high: int = hi(wWarioYPos)
	write_level_ram(W_UNUSED_CA6C, (((y_high << 4) | (y_high >> 4)) & 0xFF) | hi(wWarioXPos))  # swap, or
	wLevelRoomID = byte(hi(wWarioXPos) + 10 * hi(wWarioYPos))  # GetNextLevelRoomID
	wFloorTransitionDir = 0
	wFloorTransitionTimer = 0
	wCameraYDelta = 0
	wCameraXDelta = 0
	wScrollUpEdge = 0
	wScrollDownEdge = 0
	wGroundShakeCounter = 0
	wSCYShake = 0
	write_level_ram(W_TEMP_LEVEL_ROOM_ID, wLevelRoomID)
	if not level.room_fields.has(wLevelRoomID):
		note_unported("room-list entry %d is empty" % wLevelRoomID)
		return
	var fields: Dictionary = level.room_fields[wLevelRoomID]
	load_room_camera(fields)
	load_object_group(wObjectGroup)
	clear_particles()
	set_wario_position_to_spawn(fields)
	set_initial_camera_scroll()
	apply_initial_camera_scroll()
	if (wRoomTransitionParam & ROOMTRANSITIONF_RELOAD_OBJECTS) != 0:
		reload_level_objects()
	wRoomTransitionParam = 0
	update_switchable_blocks()
	spawn_room_objects()
	displayed_camera_x = wCameraSCX
	displayed_camera_y = wCameraSCY
	set_wario_screen_pos()
	if wWarioState == WST_ENTERING_DOOR:
		wFrameDuration = 0
		wAnimationFrame = 0
		wWarioFramesetPtr = FRAMESET_DOOR_OUT
		update_wario_animation()
	_first_object_updates()
	draw_objects()
	draw_wario()
	wIsIntangible = 0
	wSubState = SST_SLOW_FADE_FROM_WHITE


## The level's animated tiles kept while golf runs (WRAM bank 3's wTempAnimatedTilesFrameDuration
## and wTempAnimatedTilesGroup, which holds the graphics, not the group).
var wTempAnimatedTilesFrameDuration: int = 0
var wTempAnimatedTilesGroup: int = 0
## The golf minigame (GolfSim), when its data is loaded (load_golf_data); it runs in ST_GOLF. A
## parity run feeds each golf loop's joypad ([wJoypadDown, wJoypadPressed]) through golf_input, as
## the movie had it; the native game's runner sets the joypad itself.
var golf: GolfSim = null
var golf_input: Array = []
## Without golf's data: the golf minigame's visits for a parity run to replay, in order: [its game
## loops, wNumCoins and wIsMinigameCleared after it]. golf_loops counts the current visit's loops
## down.
var golf_replay: bool = false
var golf_queue: Array = []
var golf_outcome: Array = []
var golf_loops: int = 0


## StartRoom_FromTransition into the golf minigame: the room's animated tiles are kept for the
## return, and the level's sub-state waits in wPendingSubState.
func enter_golf() -> void:
	wTempAnimatedTilesFrameDuration = wAnimatedTilesFrameDuration
	wTempAnimatedTilesGroup = wAnimatedTilesGfx
	wPendingSubState = wSubState
	wState = ST_GOLF
	wSubState = 0
	golf_outcome = []
	if golf != null:
		return
	if golf_replay:
		if golf_queue.is_empty() or int(golf_queue[0][0]) < 0:
			note_unported("the Golf minigame (not ported) without a count of its loops to replay")
			return
		golf_outcome = golf_queue.pop_front()
		golf_loops = int(golf_outcome[0])


## golf.json (wl3pc.extract.golf): the golf minigame and the golf building run natively from now on.
func load_golf_data(document: Dictionary) -> void:
	golf = GolfSim.new(null, screen_wram)
	golf.load_data(document)


## The level's clear screen (ClearSim, WL3-043), when clear.json is loaded; it runs in ST_CLEAR.
var clear: ClearSim = null
## Action Help (ActionHelpSim, WL3-051), when action_help.json is loaded; it runs in
## ST_ACTION_HELP.
var action_help: ActionHelpSim = null
## The RAM the clear screen, Action Help, the map, and its save screen share (MenuScreenSim.wram).
var screen_wram: Dictionary = {}
const ST_OVERWORLD: int = 0x01
## Whether the level's variables in that RAM (SharedWram) are kept in step with it around each screen
## loop, and the virtual OAM handed from screen to screen: as one RAM, the original's (native play and
## parity runs that go on from a level into the screens; checks that load a screen's loop from the
## trace leave it off).
var sync_screen_wram: bool = false
## Each shared variable's value when the two were last in step.
var _synced: Dictionary = {}
## The screen whose virtual OAM is the game's, until another screen runs (none after a level loop:
## the level's sprites are not kept as a virtual OAM).
var _oam_screen: ScreenSim = null


## Level RAM the port keeps only as bytes, in the screens' shared WRAM0 (the save keeps them):
## wTempLevelRoomID (the room a level resumed from a save starts in: StartRoom_FromTransition sets it),
## wUnused_ca6c (Wario's position's high bytes at the last transition, never read), wLevelTime
## (Time Attack's clock, not ported: cleared at the level start), and wUnused_IsPaused (UpdateLevel
## sets it on pausing, ExitPauseMenu clears it; never read).
const W_TEMP_LEVEL_ROOM_ID: int = 0xCA5D
const W_UNUSED_CA6C: int = 0xCA6C
const W_LEVEL_TIME: int = 0xC0E2
const W_UNUSED_IS_PAUSED: int = 0xCED6


## SaveBackupVRAM's RAM (src/home/backup_vram.asm; golf's lobby from the level runs it): wSCY and wSCX
## to GFX RAM's w3d500 and w3d501, wTempPals1 and wTempPals2 to its w3d280, in the screens' shared
## RAM (when there is one); a byte copied from one not known is not known either.
func save_backup_vram() -> void:
	if not screen_wram.has(3):
		return
	screen_wram[3][0xD500 - 0xD000] = wSCY & 0xFF
	screen_wram[3][0xD501 - 0xD000] = wSCX & 0xFF
	for offset: int in 0x80:
		screen_wram[3][0xD280 - 0xD000 + offset] = screen_wram[0][offset]
	if screen_wram.has("known"):
		screen_wram["known"][3][0xD500 - 0xD000] = 1
		screen_wram["known"][3][0xD501 - 0xD000] = 1
		for offset: int in 0x80:
			screen_wram["known"][3][0xD280 - 0xD000 + offset] = screen_wram["known"][0][offset]


## A WRAM0 byte of the level kept only in the screens' shared WRAM (0 when there is none).
func read_level_ram(address: int) -> int:
	return screen_wram[0][address - 0xC000] if screen_wram.has(0) else 0


## A WRAM0 byte of the level kept only in the screens' shared WRAM (when there is one).
func write_level_ram(address: int, value: int) -> void:
	if not screen_wram.has(0):
		return
	screen_wram[0][address - 0xC000] = value & 0xFF
	if screen_wram.has("known"):
		screen_wram["known"][0][address - 0xC000] = 1


## Mark the shared RAM's bytes as unknown until written (MenuScreenSim.ram_known), for a parity run
## that starts in a level: what the screens before it left is seeded from the trace when first seen.
func track_known_ram() -> void:
	var known: Dictionary = {"sram": PackedByteArray()}
	known["sram"].resize(0x2000)
	for bank: int in [0, 2, 3]:
		var bytes := PackedByteArray()
		bytes.resize(0x1000)
		known[bank] = bytes
	screen_wram["known"] = known


## Before a screen loop: the shared variables the level (or a screen, through this LevelSim) changed
## since they were last in step, written to the screens' RAM; and the virtual OAM handed to `screen`.
func screen_wram_in(screen: ScreenSim) -> void:
	if not sync_screen_wram or not screen_wram.has(0):
		return
	for entry: Array in SharedWram.VARIABLES:
		var name: String = entry[0]
		var value: int = int(get(name))
		if not _synced.has(name) or int(_synced[name]) != value:
			_write_shared(entry, value)
			_synced[name] = value
	hand_over_oam(screen)


## After a screen loop: each shared variable the screen changed, as a byte (taken into this LevelSim)
## or through this LevelSim (written to the RAM).
func screen_wram_out() -> void:
	if not sync_screen_wram or not screen_wram.has(0):
		return
	for entry: Array in SharedWram.VARIABLES:
		var name: String = entry[0]
		var value: int = int(get(name))
		if value != int(_synced[name]):
			_write_shared(entry, value)
			_synced[name] = value
			continue
		var stored: int = _read_shared(entry)
		if stored != value:
			set(name, stored)
			_synced[name] = stored


## The shared variables taken from the screens' RAM where all their bytes are known (what a parity run
## seeded), the others written to it, and the two in step from here.
func adopt_screen_wram() -> void:
	for entry: Array in SharedWram.VARIABLES:
		var name: String = entry[0]
		if _shared_known(entry):
			set(name, _read_shared(entry))
		else:
			_write_shared(entry, int(get(name)))
		_synced[name] = int(get(name))


func _shared_known(entry: Array) -> bool:
	if not screen_wram.has("known"):
		return true
	var bank: int = int(entry[1])
	var offset: int = int(entry[2]) - (0xC000 if bank == 0 else 0xD000)
	for index: int in int(entry[3]):
		if screen_wram["known"][bank][offset + index] == 0:
			return false
	return true


## The virtual OAM (and its byte count) from the screen that ran last to `screen`, as one buffer
## (wVirtualOAM) for all.
func hand_over_oam(screen: ScreenSim) -> void:
	if _oam_screen != null and _oam_screen != screen:
		screen.wVirtualOAM = _oam_screen.wVirtualOAM.duplicate()
		screen.wVirtualOAMByteSize = _oam_screen.wVirtualOAMByteSize
	_oam_screen = screen


func _write_shared(entry: Array, value: int) -> void:
	var bank: int = int(entry[1])
	var offset: int = int(entry[2]) - (0xC000 if bank == 0 else 0xD000)
	var size: int = int(entry[3])
	for index: int in size:
		screen_wram[bank][offset + index] = (value >> (8 * (size - 1 - index))) & 0xFF
		if screen_wram.has("known"):
			screen_wram["known"][bank][offset + index] = 1


func _read_shared(entry: Array) -> int:
	var bank: int = int(entry[1])
	var offset: int = int(entry[2]) - (0xC000 if bank == 0 else 0xD000)
	var value: int = 0
	for index: int in int(entry[3]):
		value = (value << 8) | screen_wram[bank][offset + index]
	return value


## clear.json (wl3pc.extract.clear)
func load_clear_data(document: Dictionary) -> void:
	clear = ClearSim.new(null, screen_wram)
	clear.load_data(document)


## The pause menu's state table (PauseMenuSim, WL3-052), when pause_menu.json is loaded: the pause
## menu, the level's save from it, and the map's save screen (SST_PAUSE_18 on).
var pause_menu_screen: PauseMenuSim = null


## pause_menu.json (wl3pc.extract.pause_menu)
func load_pause_menu_data(document: Dictionary) -> void:
	pause_menu_screen = PauseMenuSim.new(null, screen_wram)
	pause_menu_screen.load_data(document)


## _PauseMenuStateTable's loop (PauseMenuSim); the screen holds the LevelSim only while it runs.
func pause_menu_state() -> void:
	pause_menu_screen.unported.clear()
	pause_menu_screen.sim = self
	screen_wram_in(pause_menu_screen)
	pause_menu_screen.update()
	screen_wram_out()
	pause_menu_screen.sim = null
	for note: String in pause_menu_screen.unported:
		note_unported(note)


## The map (OverworldSim, WL3-052), when overworld.json is loaded.
var overworld: OverworldSim = null


## overworld.json (wl3pc.extract.overworld)
func load_overworld_data(document: Dictionary) -> void:
	overworld = OverworldSim.new(null, screen_wram)
	overworld.load_data(document)


## OverworldStateTable's loop (OverworldSim), or a note that the map is not loaded; the screen holds
## the LevelSim only while it runs.
func overworld_state() -> void:
	if overworld == null:
		note_unported("the map (overworld.json not loaded)")
		return
	overworld.unported.clear()
	overworld.sim = self
	screen_wram_in(overworld)
	overworld.update()
	screen_wram_out()
	overworld.sim = null
	for note: String in overworld.unported:
		note_unported(note)


## The title (TitleSim, WL3-055), when title.json is loaded: it runs in ST_TITLE, wState's value
## before any (a LevelSim without the title runs the level there, as the level's checks start it), and
## in ST_LANGUAGE_SELECTION (New Game's language selection, WL3-056).
var title: TitleSim = null
const ST_TITLE: int = 0x00


## title.json (wl3pc.extract.title)
func load_title_data(document: Dictionary) -> void:
	title = TitleSim.new(null, screen_wram)
	title.load_data(document)


## TitleStateTable's loop (TitleSim); the screen holds the LevelSim only while it runs.
func title_state() -> void:
	title.unported.clear()
	title.sim = self
	screen_wram_in(title)
	title.update()
	screen_wram_out()
	title.sim = null
	for note: String in title.unported:
		note_unported(note)


## The credits (CreditsSim, WL3-052), when credits.json is loaded: ST_CREDITS, after the epilogue's
## save screen (TransitionAfterSave).
var credits: CreditsSim = null
const ST_CREDITS: int = 0x09


## credits.json (wl3pc.extract.credits)
func load_credits_data(document: Dictionary) -> void:
	credits = CreditsSim.new(null, screen_wram)
	credits.load_data(document)


## _CreditsStateTable's loop (CreditsSim); the screen holds the LevelSim only while it runs.
func credits_state() -> void:
	credits.unported.clear()
	credits.sim = self
	screen_wram_in(credits)
	credits.update()
	screen_wram_out()
	credits.sim = null
	for note: String in credits.unported:
		note_unported(note)


## The game over screen (GameOverSim, WL3-052), when game_over.json is loaded: ST_GAME_OVER, after the
## hidden figure's fight is lost and the map's save screen (TransitionAfterSave).
var game_over: GameOverSim = null
const ST_GAME_OVER: int = 0x0C


## game_over.json (wl3pc.extract.game_over)
func load_game_over_data(document: Dictionary) -> void:
	game_over = GameOverSim.new(null, screen_wram)
	game_over.load_data(document)


## _GameOverStateTable's loop (GameOverSim); the screen holds the LevelSim only while it runs.
func game_over_state() -> void:
	game_over.unported.clear()
	game_over.sim = self
	screen_wram_in(game_over)
	game_over.update()
	screen_wram_out()
	game_over.sim = null
	for note: String in game_over.unported:
		note_unported(note)


## The Perfect screen (PerfectSim, WL3-052), when perfect.json is loaded: ST_PERFECT, after a perfect
## game's credits or from the map with all the treasures (SetPerfectState).
var perfect: PerfectSim = null
const ST_PERFECT: int = 0x0D


## perfect.json (wl3pc.extract.perfect)
func load_perfect_data(document: Dictionary) -> void:
	perfect = PerfectSim.new(null, screen_wram)
	perfect.load_data(document)


## _PerfectStateTable's loop (PerfectSim); the screen holds the LevelSim only while it runs.
func perfect_state() -> void:
	perfect.unported.clear()
	perfect.sim = self
	screen_wram_in(perfect)
	perfect.update()
	screen_wram_out()
	perfect.sim = null
	for note: String in perfect.unported:
		note_unported(note)


## action_help.json (wl3pc.extract.action_help)
func load_action_help_data(document: Dictionary) -> void:
	action_help = ActionHelpSim.new(null, screen_wram)
	action_help.load_data(document)


## _ActionHelpStateTable's loop (ActionHelpSim), or a note that it is not loaded; the screen holds
## the LevelSim only while its loop runs. Its way back to the pause menu ends with the menu's init
## (InitPauseMenu_SkipBackupVRAM) in the same loop: the pause menu's, on the same RAM.
func action_help_state() -> void:
	if action_help == null:
		note_unported("ActionHelpStateTable (action_help.json not loaded)")
		return
	action_help.unported.clear()
	action_help.sim = self
	screen_wram_in(action_help)
	action_help.update()
	screen_wram_out()
	action_help.sim = null
	for note: String in action_help.unported:
		note_unported(note)
	if not action_help.to_pause_menu:
		return
	if pause_menu_screen == null:
		note_unported("InitPauseMenu_SkipBackupVRAM (pause_menu.json not loaded)")
		return
	pause_menu_screen.unported.clear()
	pause_menu_screen.sim = self
	screen_wram_in(pause_menu_screen)
	pause_menu_screen.return_from_action_help()
	screen_wram_out()
	pause_menu_screen.sim = null
	for note: String in pause_menu_screen.unported:
		note_unported(note)


## _ClearScreenStateTable's loop (ClearSim), or a note that it is not loaded. The screen holds
## the LevelSim only while its loop runs (the two would otherwise hold each other).
func clear_state() -> void:
	if clear == null:
		note_unported("ClearScreenStateTable (the level's end; clear.json not loaded)")
		return
	clear.unported.clear()
	clear.sim = self
	screen_wram_in(clear)
	clear.update()
	screen_wram_out()
	clear.sim = null
	for note: String in clear.unported:
		note_unported(note)


## _GolfStateTable (src/engine/golf/state_table.asm): GolfSim's game loop when golf's data is
## loaded. Without it, the level's side only: the fade to white, what InitGolfLobby changes for the
## level, and the way back; a parity run replays the minigame's length and outcome (golf_queue), and
## natively Wario leaves the lobby at once without playing (provisional, ADR-0002).
func golf_state() -> void:
	if golf != null:
		if not golf_input.is_empty():
			var input: Array = golf_input.pop_front()
			wJoypadDown = int(input[0])
			wJoypadPressed = int(input[1])
		golf.unported.clear()
		golf.sim = self  # only while its loop runs: the two would otherwise hold each other
		golf.update()
		golf.sim = null
		for note: String in golf.unported:
			note_unported(note)
		return
	golf_loops -= 1
	match wSubState:
		0, SST_GOLF_EXIT:  # FastFadeToWhite
			fade_step()
		SST_GOLF_INIT_LOBBY:
			init_golf_lobby()
		SST_GOLF_RETURN:
			return_to_level_from_golf()
		_:
			golf_minigame()


## _GolfBuildingStateTable (src/engine/golf/building/state_table.asm, WL3-050): the golf building's
## course menu and its courses (GolfSim), entered from the map, on the screens' shared RAM; or a note
## that golf's data is not loaded.
func golf_building_state() -> void:
	if golf == null:
		note_unported("the Golf Building (golf.json not loaded)")
		return
	golf.unported.clear()
	golf.sim = self
	screen_wram_in(golf)
	golf.update_building()
	screen_wram_out()
	golf.sim = null
	for note: String in golf.unported:
		note_unported(note)


## InitGolfLobby's part the level sees: the room's animated tiles stop (golf's graphics replace
## them, and LoadBackupVRAM brings the room's back).
func init_golf_lobby() -> void:
	wRoomAnimatedTilesEnabled = 0
	wSubState = SST_GOLF_LOBBY


## The minigame (not ported). Replayed, it lasts the original's loops, its last one leaving
## ReturnToLevelFromGolf next, and leaves its coins and clear behind; natively it goes straight to
## its fade out.
func golf_minigame() -> void:
	if golf_outcome.is_empty():
		wSubState = SST_GOLF_EXIT
		return
	if golf_loops > 1:
		return
	wNumCoins = int(golf_outcome[1])
	wIsMinigameCleared = int(golf_outcome[2])
	wSubState = SST_GOLF_RETURN


## ReturnToLevelFromGolf (src/home/return_level.asm): the room's animated tiles back from their
## first frame, the transition made a door's (its flags kept), the level drawn again
## (DrawLevelObjectsAfterLevelReturn), and the level back in its pending sub-state, which starts
## the door's room.
func return_to_level_from_golf() -> void:
	wAnimatedTilesFrameDuration = wTempAnimatedTilesFrameDuration
	wAnimatedTilesGfx = wTempAnimatedTilesGroup
	wAnimatedTilesFrameCount = 0
	wAnimatedTilesFrame = 0
	wRoomAnimatedTilesEnabled = 1
	wRoomTransitionParam = (wRoomTransitionParam & ROOMTRANSITION_FLAGS_MASK) | ROOMTRANSITION_DOOR
	vblank()
	draw_objects()
	draw_wario()
	wState = ST_LEVEL
	wSubState = wPendingSubState


## SetWarioPositionToSpawn: the first spawn nibble below the header's spawn section, then Func_cf8
## (the block's centre column, its bottom edge) and UpdateFloor in transition rooms.
func set_wario_position_to_spawn(fields: Dictionary) -> void:
	var block: Array = level.find_spawn(int(fields.get("spawn_x", 0)), int(fields.get("spawn_y", 0)))
	if block.is_empty():
		note_unported("SetWarioPositionToSpawn past the decoded object map")
		return
	wWarioXPos = int(block[0]) * 16 + 8
	wWarioYPos = int(block[1]) * 16 + 16
	hXPos = wWarioXPos
	hYPos = wWarioYPos
	if _transitions_enabled():
		wFloor = get_floor_for_y_pos()


## UpdateLevel's ported parts, by the room's camera mode (the V-Blank before it included).

## UpdateLevel up to .asm_8229, the end of its camera code (where oracle traces snapshot it).
func update_level_to_camera() -> void:
	update_level_wario()
	update_level_objects()
	draw_and_update_camera()


## UpdateLevel's objects: UpdateObjects, Wario's screen position, in the Temple with wAutoMoveState
## 2 the fence shake's slide, then ProcessInteractions with wBlockFuncWarioFlag set (Wario's probes
## in the interactions are his).
func update_level_objects() -> void:
	update_objects()
	set_wario_screen_pos()
	check_temple_fence_shake()
	wBlockFuncWarioFlag = 1
	process_interactions()
	wBlockFuncWarioFlag = 0


## UpdateLevel after UpdateObjects in the Temple: at wAutoMoveState 2 (the hidden figure defeated)
## the fence shake's slide (SetState_FenceShakeSliding).
func check_temple_fence_shake() -> void:
	if wLevel == THE_TEMPLE and wAutoMoveState == 0x02:
		set_state_fence_shake_sliding()


## DrawObjects_NoPriority, DrawWario, DrawObjects_WithPriority, then the camera code up to .asm_8229.
func draw_and_update_camera() -> void:
	draw_objects()
	draw_wario()
	update_camera()


## What DrawObjects_NoPriority and DrawObjects_WithPriority last put in OAM, for presentation: per
## drawn object, its OAM table ("BB:AAAA": bank "Objects OAM 1" + bits 4-6 of its ID), frame,
## screen position, and whether it goes before Wario in OAM (OBJFLAG_PRIORITY: drawn over him);
## with the object group whose graphics and palettes are loaded. Order is OAM order.
var drawn_objects: Array = []
var drawn_object_group: int = 0


func draw_objects() -> void:
	drawn_objects.clear()
	drawn_object_group = wObjectGroup
	for priority: bool in [true, false]:
		for slot: int in NUM_OBJECTS:
			var base: int = W_OBJECTS + slot * OBJ_STRUCT_LENGTH
			var flags: int = wram1[base + OBJ_FLAGS] & (OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN | OBJFLAG_INVISIBLE | OBJFLAG_PRIORITY)
			if flags != OBJFLAG_ACTIVE | OBJFLAG_ON_SCREEN | (OBJFLAG_PRIORITY if priority else 0):
				continue
			drawn_objects.append({
				"oam_table": "%02x:%04x" % [0x60 | ((wram1[base + OBJ_ID] >> 4) & 7),
						wram1[base + OBJ_OAM_PTR] | (wram1[base + OBJ_OAM_PTR + 1] << 8)],
				"frame": wram1[base + OBJ_FRAME], "screen_y": wram1[base + OBJ_SCREEN_Y_POS],
				"screen_x": wram1[base + OBJ_SCREEN_X_POS], "over_wario": priority,
			})


## UpdateLevel up to UpdateObjects: the V-Blank before the frame, Wario's update, and the copy of
## the camera into the scroll shadows (the fight's own in the Temple). Objects run next.
func update_level_wario() -> void:
	vblank()
	wRoomAnimatedPalsEnabled = 1
	unported.clear()
	update_particles()
	var particles_unported: PackedStringArray = unported.duplicate()  # Wario's update clears the list
	var scrolling: int = wCameraConfigFlags & CAM_SCROLLING_MASK
	if scrolling == CAM_FREE or scrolling == CAM_YSCROLL:
		# .free_camera and .yscroll_camera call UpdateWarioStates without the floor transition check.
		unported.clear()
		handlers_run.clear()
		wBlockFuncWarioFlag = 1
		update_wario_states()
		wBlockFuncWarioFlag = 0
	else:
		update()
	particles_unported.append_array(unported)
	unported = particles_unported
	if wCameraConfigFlags == HIDDEN_FIGURE_CAMCONFIG:
		# .shake_override: the fight's own scroll and shake, and the window's y (wc08d plus the shake,
		# written to rWY while the frame is drawn); the camera stays where the room set it.
		wSCY = byte(wHiddenFigureSCYShake + wSCYShake)
		wSCX = wc08b
		rWY = byte(wc08d + wSCYShake)
		return
	wSCY = lo(wCameraSCY)
	wSCX = lo(wCameraSCX)
	displayed_camera_x = wCameraSCX
	displayed_camera_y = wCameraSCY


## UpdateLevel after objects and interactions, up to .asm_8229, for a state whose objects ran
## elsewhere (the oracle's): Wario's screen position, his sprite, and the camera.
func update_level_after_objects() -> void:
	set_wario_screen_pos()
	draw_and_update_camera()


## LoadHiddenFigureGfx's runs (InitLevel in the Temple), and rWY as the fight last wrote it: for
## presentation (TempleVram), which loads the figure's graphics when the count changes.
var hidden_figure_gfx_loads: int = 0
var rWY: int = 0


## What DrawWario last put in OAM, for presentation: Wario's screen position (OAM coordinates,
## wWarioScreenXPos/YPos), his frame, its OAM table, and the tile set and palettes behind them, as
## the "BB:AAAA" keys of the extracted wario_sprites.json. Empty when he was not drawn. The next
## frame shows it, with the scroll in displayed_camera_x/y.
var drawn_wario: Dictionary = {}


## DrawWario (src/home/sprite.asm): Wario is drawn unless wInvisibleFrame is set; as Invisible
## Wario (a transformation, not ported) it counts frames and shows him in a few of every 16.
func draw_wario() -> void:
	var shown: bool
	if wTransformation == TRANSFORMATION_INVISIBLE_WARIO:
		wInvisibleFrame = byte(wInvisibleFrame + 1)
		shown = (wInvisibleFrame & 0b11110010) == 0b11110000
	else:
		shown = wInvisibleFrame == 0
	if not shown:
		drawn_wario = {}
		return
	drawn_wario = {
		"screen_x": wWarioScreenXPos, "screen_y": wWarioScreenYPos, "frame": wWarioFrame,
		"attributes": wWarioAttributes,
		"oam_table": "%02x:%04x" % [wWarioOAMBank, wWarioOAMPtr],
		"tile_set": "%02x:%04x" % [wDMASourceBank, wDMASourcePtr],
		"palettes": "%02x:%04x" % [WARIO_PALETTES_BANK, wWarioPalsPtr],
	}


## Func_8ed9 (scroll.asm) after .asm_8229, as far as game state goes: each frame it draws the newly
## visible column (right before left) and row (up before down) and spawns their objects, clearing
## those edge flags. The drawing and spawning are not ported; an edge left over waits a frame.
func stream_level_edges() -> void:
	var flags: int = wLevelEdgeUpdateFlags
	if flags == 0:
		return
	if (flags & (LEVEL_EDGE_UPDATE_RIGHT | LEVEL_EDGE_UPDATE_LEFT)) != 0:
		if (flags & LEVEL_EDGE_UPDATE_RIGHT) != 0:
			_edge_block_pos(_edge_side_y(), _clamp_right_x())
			wLevelEdgeUpdateFlags &= ~LEVEL_EDGE_UPDATE_RIGHT
		else:
			_edge_block_pos(_edge_side_y(), _edge_minus_16(wCameraSCX))
			wLevelEdgeUpdateFlags &= ~LEVEL_EDGE_UPDATE_LEFT
		spawn_row_edge_objects()
		flags = wLevelEdgeUpdateFlags
	if (flags & LEVEL_EDGE_UPDATE_UP) != 0:
		_edge_block_pos(_edge_minus_16(wCameraSCY), _edge_minus_16(wCameraSCX))
		wLevelEdgeUpdateFlags &= ~LEVEL_EDGE_UPDATE_UP
		spawn_col_edge_objects()
	elif (flags & LEVEL_EDGE_UPDATE_DOWN) != 0:
		var y: int = (wCameraSCY & 0xFFF8) + 0xA0
		_edge_block_pos(0x02F8 if (y >> 8) >= 0x03 else y, _edge_minus_16(wCameraSCX))
		wLevelEdgeUpdateFlags &= ~LEVEL_EDGE_UPDATE_DOWN
		spawn_col_edge_objects()


func _edge_block_pos(y: int, x: int) -> void:
	wBlockYPos = y & 0xFFFF
	wBlockXPos = x & 0xFFFF


## (coordinate & ~7) - $10, or 0 when that is negative.
func _edge_minus_16(coordinate: int) -> int:
	var value: int = (coordinate & 0xFFF8) - 0x10
	return 0 if value < 0 else value


## The Y of a column edge (.Func_8fec, .Func_9039): 16 above the camera, kept 0 above the level and at
## most $240 so 12 rows fit.
func _edge_side_y() -> int:
	var y: int = (wCameraSCY & 0xFFF8) - 0x10
	if y < 0:
		return 0
	return 0x0240 if ((y + 0xB8) >> 8) >= 0x03 else y


## The X of the right edge (.Func_8fec): $b0 right of the camera, at most $9f8.
func _clamp_right_x() -> int:
	var x: int = (wCameraSCX & 0xFFF8) + 0xB0
	return 0x09F8 if (x >> 8) >= 0x0A else x


## The map cell of wBlockPos (GetBlockPtr).
func _block_of(position: int) -> int:
	return ((hi(position) & 0x0F) << 4) | (lo(position) >> 4)


## SpawnRowEdgeObjects: 12 rows down from wBlockPos in its column; SpawnColEdgeObjects: 13 columns
## right from it in its row. A cell with bit 7 and an object nibble spawns that object at the cell's
## bottom centre (Func_d3e).
func spawn_row_edge_objects() -> void:
	if wLevelEndScreen != 0:
		return
	var row: int = _block_of(wBlockYPos)
	var column: int = _block_of(wBlockXPos)
	for i: int in 12:
		_spawn_at_cell(row + i, column)


func spawn_col_edge_objects() -> void:
	if wLevelEndScreen != 0:
		return
	var row: int = _block_of(wBlockYPos)
	var column: int = _block_of(wBlockXPos)
	for i: int in 13:
		_spawn_at_cell(row, column + i)


func _spawn_at_cell(row: int, column: int) -> void:
	if level == null:
		return
	var value: int = level.block_at(row, column)
	if value < 0 or (value & 0x80) == 0 or row >= level.object_rows.size():
		return
	var kind: int = _object_nibble(row, column)
	if kind == 0:
		return
	wccec = 1 + row / 32
	hYPos = row * 16 + 16
	hXPos = column * 16 + 8
	spawn_object(row, column, kind)


func _object_nibble(row: int, column: int) -> int:
	var byte_value: int = level.object_rows[row][column >> 1] if (column >> 1) < level.object_rows[row].size() else 0
	return (byte_value >> 4) if (column & 1) == 0 else (byte_value & 0x0F)


## ReloadLevelObjects (load_level.asm): every map cell gets bit 7 back where the level's map has it,
## so objects spawn again (a collected one stays gone: its object nibble is cleared).
func reload_level_objects() -> void:
	if level.original_rows.size() != level.rows.size():
		note_unported("ReloadLevelObjects without the level's map")
		return
	for i: int in level.rows.size():
		level.rows[i] |= level.original_rows[i] & 0x80


## The slots right after the last room start's spawning, before its object updates: kept so a
## check can compare spawning alone with the original (which records them at UpdateObjects).
var spawned_wram1: PackedByteArray = PackedByteArray()


## Func_896f (start_room.asm): the objects of a 16 x 16 block window from wBlockPos (rounded to an
## even column) that lie inside the room's limits spawn when the room starts; $f (Wario's spawn
## point) never does.
func spawn_room_objects() -> void:
	_spawn_room_objects()
	spawned_wram1 = wram1.duplicate()


func _spawn_room_objects() -> void:
	if level == null:
		return
	var first_row: int = _block_of(wBlockYPos)
	var first_byte: int = 0xB0 + (_block_of(wBlockXPos) >> 1)
	for d: int in 16:
		var row: int = first_row + d
		var bank: int = 1 + row / 32
		var page: int = 0xA0 + row - (bank - 1) * 32
		for e: int in 8:
			var l: int = byte(first_byte + e)
			if row >= level.object_rows.size() or l < 0xB0:
				continue
			var value: int = level.object_rows[row][l - 0xB0] if l - 0xB0 < level.object_rows[row].size() else 0
			for parity: int in [1, 0]:
				var kind: int = (value >> 4) if parity == 1 else (value & 0x0F)
				if kind == 0 or kind >= 0x0F:
					continue
				if not _in_room_limits(l, page, bank):
					continue
				var column: int = 2 * (l - 0xB0) + (parity ^ 1)
				wccec = bank
				hYPos = row * 16 + 16
				hXPos = column * 16 + 8
				spawn_object(row, column, kind)


## Func_89e2's checks, in its byte arithmetic: wc0c6 <= l < wc0c7 and the page within the limits.
func _in_room_limits(l: int, page: int, bank: int) -> bool:
	if byte(wc0c7 - 1) < l or wc0c6 > l:
		return false
	if bank == 1:
		return byte(wc0c4 - 1) >= page and wc0c5 <= page
	return byte(wc0c4 - 0x20 - 1) >= page and byte(wc0c5 - 0x20) <= page


## The camera code after ClearUnusedVirtualOAM, up to .asm_8229.
func update_camera() -> void:
	var scrolling: int = wCameraConfigFlags & CAM_SCROLLING_MASK
	if scrolling == CAM_FREE:
		wScrollUpEdge = 0
		wScrollDownEdge = 0
		level_scroll_vertical()
		level_scroll_horizontal()
		return
	if scrolling == CAM_YSCROLL:
		wScrollUpEdge = 0
		wScrollDownEdge = 0
		level_scroll_vertical()
		return
	if (wFloorTransitionDir & (FLOOR_TRANSITION_DOWN | FLOOR_TRANSITION_UP)) != 0 and wIsDMATransferPending == 0:
		wCameraYDelta = 0
		wPrevWarioScreenYPos = wWarioScreenYPos
		if (wFloorTransitionDir & FLOOR_TRANSITION_UP) != 0:
			wCameraYDelta = byte(wCameraYDelta + 4)
			wFloorTransitionTimer = byte(wFloorTransitionTimer - 4)
			var ended: bool = wFloorTransitionTimer == 0
			if not ended and wScrollDownEdge == 1:
				wFloorTransitionTimer = 0
				ended = true
			if ended:
				wFloorTransitionDir &= ~FLOOR_TRANSITION_UP
				wIsFloorTransition = 0
		else:
			wCameraYDelta = byte(wCameraYDelta - 4)
			wFloorTransitionTimer = byte(wFloorTransitionTimer - 4)
			if wFloorTransitionTimer == 0:
				wFloorTransitionDir &= ~FLOOR_TRANSITION_DOWN
				wIsFloorTransition = 0
		wScrollUpEdge = 0
		wScrollDownEdge = 0
		level_scroll_vertical()
		return
	if wCameraConfigFlags == HIDDEN_FIGURE_CAMCONFIG:
		return
	if scrolling == (CAM_XSCROLL2 | CAM_TRANSITIONS):
		return
	level_scroll_horizontal()


## StartRoom_FromLevelStart's .asm_88b7: in the Temple the fight keeps its own scroll from the
## initial camera's (wc08a and the shake for y, wc08c and wc08b for x), the scroll registers too.
func _start_temple_scroll() -> void:
	if wLevel != THE_TEMPLE:
		return
	wc08a = lo(wCameraSCY)
	wHiddenFigureSCYShake = wc08a
	wSCY = wc08a
	wc08c = lo(wCameraSCX)
	wc08b = wc08c
	wSCX = wc08c


## SetWarioScreenPos (camera.asm): Wario's place on screen from the scroll, or with the Hidden
## Figure camera from the fight's own (wc08a plus wSCYShake, and wc08c).
func set_wario_screen_pos() -> void:
	if wCameraConfigFlags == HIDDEN_FIGURE_CAMCONFIG:
		wWarioScreenYPos = byte(lo(wWarioYPos) + OAM_Y_OFS - byte(wc08a + wSCYShake))
		wWarioScreenXPos = byte(lo(wWarioXPos) + OAM_X_OFS - wc08c)
		return
	wWarioScreenYPos = byte(lo(wWarioYPos) + OAM_Y_OFS - wSCY)
	wWarioScreenXPos = byte(lo(wWarioXPos) + OAM_X_OFS - wSCX)


# --- Per-frame scrolling (camera.asm) ---------------------------------------------------------

## LevelScroll_Vertical
func level_scroll_vertical() -> void:
	var b: int = wCameraYDelta
	if b != 0:
		wc0d4 = 0
		if (b & 0x80) == 0:
			if wPrevWarioScreenYPos < wWarioScreenYPos:
				b += 1  # below Wario's previous screen position: catch up
			_scroll_down(b)
		else:
			b = byte(-b)
			if wPrevWarioScreenYPos > wWarioScreenYPos:
				b += 1
			_scroll_up(b)
		return
	if wWaterInteraction != 0 or wJumpVelIndex != 0:
		return
	if wWarioState == 0x4C or (wWarioState >= 0x3A and wWarioState <= 0x3E):
		return  # WST_LADDER_SCRATCHING, or WST_LADDER_CLIMBING to WST_LADDER_SLIDING
	wc0d4 = byte(wc0d4 + 1)
	if wc0d4 == 1:
		return
	var offset: int = byte(wPrevWarioScreenYPos - wWarioScreenYPos)
	if wPrevWarioScreenYPos < wWarioScreenYPos:
		offset = byte(-offset)
	b = offset
	if wWarioSlopeInteraction == 0:
		if b < 8:
			return
		b = 7
	if wPrevWarioScreenYPos < wWarioScreenYPos:
		_scroll_down(b)
	elif wPrevWarioScreenYPos != wWarioScreenYPos:
		_scroll_up(b)


func _scroll_down(b: int) -> void:
	scroll_camera_down(b)
	if wScrollDownEdge == 0:
		wLevelEdgeUpdateFlags |= LEVEL_EDGE_UPDATE_DOWN
	wCameraYDelta = 0


func _scroll_up(b: int) -> void:
	scroll_camera_up(b)
	if wScrollUpEdge == 0:
		wLevelEdgeUpdateFlags |= LEVEL_EDGE_UPDATE_UP
	wCameraYDelta = 0


## LevelScroll_Horizontal
func level_scroll_horizontal() -> void:
	var b: int = wCameraXDelta
	var spacing: int = wCamRightSpacing if wDirection != DIRECTION_LEFT else wCamLeftSpacing
	if b != 0:
		wc0d5 = 0
		if (b & 0x80) == 0:
			if spacing > wWarioScreenXPos:
				b = byte(b - 1)  # Wario left of his spacing: the camera lags
			elif spacing < wWarioScreenXPos:
				b += 1  # right of it: the camera catches up
			_scroll_right(b)
		else:
			b = byte(-b)
			if spacing > wWarioScreenXPos:
				b += 1
			elif spacing < wWarioScreenXPos:
				b = byte(b - 1)
			_scroll_left(b)
		return
	if wTransformation == TRANSFORMATION_FLAT_WARIO and wJumpVelTable != 0:
		return
	wc0d5 = byte(wc0d5 + 1)
	if wc0d5 == 1:
		return
	# Standing still: drift 1 px a frame towards the spacing.
	if spacing < wWarioScreenXPos:
		_scroll_right(1)
	elif spacing > wWarioScreenXPos:
		_scroll_left(1)


func _scroll_right(b: int) -> void:
	scroll_camera_right(b)
	if wScrollRightEdge == 0:
		wLevelEdgeUpdateFlags |= LEVEL_EDGE_UPDATE_RIGHT
	wCameraXDelta = 0


func _scroll_left(b: int) -> void:
	scroll_camera_left(b)
	if wScrollLeftEdge == 0:
		wLevelEdgeUpdateFlags |= LEVEL_EDGE_UPDATE_LEFT
	wCameraXDelta = 0


## ScrollCameraRight
func scroll_camera_right(b: int) -> void:
	wScrollRightEdge = 0
	var c: int = byte(wRoomRightXLimit - 1)
	wCameraSCX = word(wCameraSCX + b)
	var limit: int = TILEMAP_WIDTH_PX - SCREEN_WIDTH_PX
	if (wCameraConfigFlags & CAM_BORDER_RIGHT) != 0:
		limit -= CAMERA_BORDER_W
	if hi(wCameraSCX) >= c and lo(wCameraSCX) >= limit:
		wCameraSCX = (wCameraSCX & 0xFF00) | limit
		wScrollRightEdge = 1
		return
	if hi(wWarioXPos) != wRoomLeftXLimit:
		return
	c = byte((wCamRightSpacing if wDirection != DIRECTION_LEFT else wCamLeftSpacing) - 8)
	if (wCameraConfigFlags & CAM_BORDER_LEFT) != 0:
		c = byte(c + CAMERA_BORDER_W)
	if lo(wWarioXPos) >= c:
		return
	var left: int = CAMERA_BORDER_W if (wCameraConfigFlags & CAM_BORDER_LEFT) != 0 else 0
	wCameraSCX = (wCameraSCX & 0xFF00) | left
	wScrollRightEdge = 2


## ScrollCameraLeft
func scroll_camera_left(b: int) -> void:
	wScrollLeftEdge = 0
	var c: int = wRoomLeftXLimit
	wCameraSCX = word(wCameraSCX - b)
	var probe: int = word(wCameraSCX + 0x10)
	var edge: int = 0x10 + (CAMERA_BORDER_W if (wCameraConfigFlags & CAM_BORDER_LEFT) != 0 else 0)
	if hi(probe) == c and lo(probe) < edge:
		wCameraSCX = (c << 8) | (edge - 0x10)
		wScrollLeftEdge = 1
		return
	c = byte(wRoomRightXLimit - 1)
	if hi(wWarioXPos) != c:
		return
	var spacing: int = wCamRightSpacing if wDirection != DIRECTION_LEFT else wCamLeftSpacing
	c = byte(-(SCREEN_WIDTH_PX + 8 - spacing))
	if (wCameraConfigFlags & CAM_BORDER_RIGHT) != 0:
		c = byte(c - CAMERA_BORDER_W)
	if lo(wWarioXPos) < c:
		return
	wScrollLeftEdge = 2
	var right: int = TILEMAP_WIDTH_PX - SCREEN_WIDTH_PX
	if (wCameraConfigFlags & CAM_BORDER_RIGHT) != 0:
		right -= CAMERA_BORDER_W
	wCameraSCX = (byte(wRoomRightXLimit - 1) << 8) | right


## ScrollCameraDown
func scroll_camera_down(b: int) -> void:
	var c: int = byte(wRoomLowerYLimit - 1)
	wCameraSCY = word(wCameraSCY + b)
	if hi(wCameraSCY) >= c:
		var limit: int = TILEMAP_HEIGHT_PX - (SCREEN_HEIGHT_PX + 8)
		if (wCameraConfigFlags & CAM_BORDER_DOWN) != 0:
			limit -= CAMERA_BORDER_W
		if lo(wCameraSCY) >= limit:
			wCameraSCY = (wCameraSCY & 0xFF00) | limit
			wScrollDownEdge = 1
			return
	if (wCameraConfigFlags & CAM_SCROLLING_MASK) >= CAM_TRANSITIONS:
		return
	if hi(wWarioYPos) > wRoomUpperYLimit:
		return
	if hi(wWarioYPos) == wRoomUpperYLimit:
		c = byte(wPrevWarioScreenYPos - 0x10)
		if (wCameraConfigFlags & CAM_BORDER_UP) != 0:
			c = byte(c + CAMERA_BORDER_W)
		if lo(wWarioYPos) >= c:
			return
	var top: int = CAMERA_BORDER_W if (wCameraConfigFlags & CAM_BORDER_UP) != 0 else 0
	wCameraSCY = (wRoomUpperYLimit << 8) | top
	wScrollDownEdge = 2


## ScrollCameraUp
func scroll_camera_up(b: int) -> void:
	var c: int = wRoomUpperYLimit
	wCameraSCY = word(wCameraSCY - b)
	var edge: int = 0x10 + (CAMERA_BORDER_W if (wCameraConfigFlags & CAM_BORDER_UP) != 0 else 0)
	var probe: int = word(wCameraSCY + 0x10)
	if hi(probe) < c or (hi(probe) == c and lo(probe) < edge):
		wCameraSCY = (c << 8) | (edge - 0x10)
		wScrollUpEdge = 1
		return
	if (wCameraConfigFlags & CAM_SCROLLING_MASK) >= CAM_TRANSITIONS:
		return
	c = byte(wRoomLowerYLimit - 1)
	if hi(wWarioYPos) != c:
		return
	c = byte(-(SCREEN_HEIGHT_PX + 0x10 - wPrevWarioScreenYPos))
	if (wCameraConfigFlags & CAM_BORDER_DOWN) != 0:
		c = byte(c - CAMERA_BORDER_W)
	if lo(wWarioYPos) < c:
		return
	wScrollUpEdge = 2
	var bottom: int = TILEMAP_HEIGHT_PX - (SCREEN_HEIGHT_PX + 8)
	if (wCameraConfigFlags & CAM_BORDER_DOWN) != 0:
		bottom -= CAMERA_BORDER_W
	wCameraSCY = (wCameraSCY & 0xFF00) | bottom


# --- Room start (start_room.asm) ---------------------------------------------------------------

## SetInitialCameraScroll; for a level resumed from a save (`resumed`) in a room with transitions, the
## Y part is skipped (.check_if_saved_level): the camera's Y keeps what RAM holds.
func set_initial_camera_scroll(resumed: bool = false) -> void:
	wCameraRoomXScrollLimit = 0
	var scrolling: int = wCameraConfigFlags & CAM_SCROLLING_MASK
	if scrolling == (CAM_XSCROLL2 | CAM_TRANSITIONS) or scrolling == CAM_YSCROLL:
		wCameraSCX = (hi(wWarioXPos) << 8) | 0x30
	else:
		var spacing: int = wCamRightSpacing if wDirection != DIRECTION_LEFT else wCamLeftSpacing
		wCameraSCX = word(wWarioXPos - byte(spacing - 8))
		var hl: int = wCameraSCX
		if (wCameraConfigFlags & CAM_BORDER_LEFT) != 0:
			hl = word(hl - 0x20)
		var h: int = hi(hl)
		if (h & 0x80) != 0 or h < wRoomLeftXLimit or (h == wRoomLeftXLimit and lo(hl) == 0):
			wCameraSCX = (wRoomLeftXLimit << 8) | lo(wCameraSCX)
			wCameraRoomXScrollLimit = 1
		else:
			var right: int = word(wCameraSCX + (0xC0 if (wCameraConfigFlags & CAM_BORDER_RIGHT) != 0 else 0xA0))
			if hi(right) >= wRoomRightXLimit:
				wCameraSCX = (byte(wRoomRightXLimit - 1) << 8) | lo(wCameraSCX)
				wCameraRoomXScrollLimit = byte(-1)
	if resumed and scrolling >= CAM_TRANSITIONS:
		return
	wCameraRoomYScrollLimit = 0
	wCameraSCY = word(wWarioYPos - 0x60)
	var vl: int = wCameraSCY
	if (wCameraConfigFlags & CAM_BORDER_UP) != 0:
		vl = word(vl - 0x20)
	var vh: int = hi(vl)
	if (vh & 0x80) != 0 or vh < wRoomUpperYLimit or (vh == wRoomUpperYLimit and lo(vl) == 0):
		wCameraSCY = (wRoomUpperYLimit << 8) | lo(wCameraSCY)
		wCameraRoomYScrollLimit = 1
		return
	var lower: int = word(wCameraSCY + (0xB0 if (wCameraConfigFlags & CAM_BORDER_DOWN) != 0 else 0x90))
	if hi(lower) >= wRoomLowerYLimit:
		wCameraSCY = (byte(wRoomLowerYLimit - 1) << 8) | lo(wCameraSCY)
		wCameraRoomYScrollLimit = byte(-1)
		return
	if scrolling < CAM_TRANSITIONS:
		return
	if lo(wWarioYPos) >= 0x80:
		wCameraSCY = (wCameraSCY & 0xFF00) | 0x68
		return
	var section: int = byte(hi(wWarioYPos) - 1)
	wCameraSCY = (section << 8) | lo(wCameraSCY)
	if section < wRoomUpperYLimit:
		wCameraSCY = (wRoomUpperYLimit << 8) | lo(wCameraSCY)
		wCameraRoomYScrollLimit = 1
		return
	if (section & 0x80) != 0:
		wCameraSCY = lo(wCameraSCY)
		wCameraRoomYScrollLimit = 1
		return
	wCameraSCY = (wCameraSCY & 0xFF00) | 0xE8


## ApplyInitialCameraScroll: the edge positions it settles, and the scroll shadows.
func apply_initial_camera_scroll() -> void:
	# wBlockPos: the top-left block the room's drawing starts at, which Func_896f's object search uses.
	var y_hi: int = wCameraSCY & 0xFF00
	if wCameraRoomYScrollLimit == 1:
		wCameraSCY = y_hi | (0x20 if (wCameraConfigFlags & CAM_BORDER_UP) != 0 else 0x00)
		wBlockYPos = wCameraSCY
	elif wCameraRoomYScrollLimit == 0xFF:
		wCameraSCY = y_hi | (0x48 if (wCameraConfigFlags & CAM_BORDER_DOWN) != 0 else 0x68)
		wBlockYPos = y_hi | byte(lo(wCameraSCY) - 0x20)
	else:
		wBlockYPos = word(wCameraSCY - 0x18)
	wSCY = lo(wCameraSCY)
	var x_hi: int = wCameraSCX & 0xFF00
	if wCameraRoomXScrollLimit == 1:
		wCameraSCX = x_hi | (0x20 if (wCameraConfigFlags & CAM_BORDER_LEFT) != 0 else 0x00)
		wBlockXPos = wCameraSCX
	elif wCameraRoomXScrollLimit == 0xFF:
		wCameraSCX = x_hi | (0x40 if (wCameraConfigFlags & CAM_BORDER_RIGHT) != 0 else 0x60)
		wBlockXPos = x_hi | byte(lo(wCameraSCX) - 0x28)
	else:
		wBlockXPos = word(wCameraSCX - 0x10)
		if (wBlockXPos & 0x8000) != 0:
			wBlockXPos = 0
	wSCX = lo(wCameraSCX)
