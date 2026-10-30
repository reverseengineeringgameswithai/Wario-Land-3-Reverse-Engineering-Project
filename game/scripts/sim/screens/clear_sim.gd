class_name ClearSim
extends MenuScreenSim
## The level's clear screen (src/engine/clear/, bank78.asm), ported by translation (WL3-043):
## _ClearScreenStateTable's treasure screen (or Time Attack's), the musical coin screen with its
## pencil, and the way out to the map (or Action Help after a power-up). It records the game's
## progress: the treasure collected, the treasures and music boxes counted, the power-up, and a
## level's eight musical coins. Its RAM is MenuScreenSim's; the WRAM0 variables only it uses are
## here.

# WRAMX bank 3 (src/ram/wram.asm): the clear screen's objects; the Wario's struct is longer.
const W3D50D: int = 0xD50D
const W3D511: int = 0xD511
const W_CLEAR_SCREEN_WARIO: int = 0xD515
const W_CLEAR_SCREEN_WARIO_VAR: int = 0xD51D
const W_MENU_OBJ_1: int = 0xD523
const W_MENU_OBJ_2: int = 0xD52B
const W_MENU_OBJ_3: int = 0xD533
const W_MENU_OBJ_4: int = 0xD53B
const W_MENU_OBJ_5: int = 0xD547
const W_MENU_OBJ_6: int = 0xD553
const W_MENU_OBJ_7: int = 0xD55E
const W_MENU_OBJ_8: int = 0xD56A
# WRAMX bank 2: the treasures, a bit each (IsTreasureCollected).
const W_TREASURES_COLLECTED: int = 0xD000
# WRAM0
const W_GAME_MODE_FLAGS: int = 0xCA3D
const W_TRANSITION_PARAM: int = 0xCEE3
const W_NUM_MUSIC_BOXES: int = 0xCEF2
const W_TIME_ATTACK_RESULT: int = 0xC0E5
const W_ALL_MUSICAL_COINS_LEVEL: int = 0xC0E7
const W_MUSICAL_COIN_VISUAL_COUNTER: int = 0xC0E8
const W_LEVEL_TIME: int = 0xC0E2
const W_LEVEL_TIME_ATTACK_SCORES: int = 0xCA07
const W_MUSICAL_COIN_FLAGS: int = 0xCA3E
const W_BG_MAP_TILE_VRAM0_QUEUE: int = 0xCE01
const W_CEE4: int = 0xCEE4
const W_TIMER: int = 0xCEE5

# src/constants/: the clear screen's sub-states, the level's ends, the treasures, and the modes.
const SST_CLEAR_TIME_ATTACK: int = 0x04
const SST_CLEAR_MUSICAL_COINS: int = 0x08
const SST_CLEAR_EXIT: int = 0x0E
const LVLEND_GREY_TREASURE: int = 1
const LVLEND_NO_TREASURE: int = 5
const TRANSITION_RETURN_TO_MAP: int = 0xF0
const NUM_TREASURES: int = 0x65
const NUM_LEVEL_MUSICAL_COINS: int = 8
const NUM_LEVELS: int = 25
const ACTION_HELP_LEVEL_CLEAR: int = 0x80
const MODE_TIME_ATTACK: int = 0x02
const TIME_ATTACK_NO_HIGH_SCORE: int = 1
const TIME_ATTACK_GOT_HIGH_SCORE: int = 2
const KEYS_MASK: int = 0x0F
const ANIMATED_TILES_GFX_15: int = 15
const ST_ACTION_HELP: int = 0x07
const ST_OVERWORLD: int = 0x01
## SetTreasureTransitionParam: the treasures that are power-ups, and the power-up level each gives.
const POWER_UP_TREASURES: Dictionary = {
	0x0C: 1, 0x07: 2, 0x0E: 3, 0x0B: 4, 0x0A: 5, 0x0D: 6, 0x08: 7, 0x06: 8, 0x09: 9,
}
const CLEAR_BANK: int = 0x35  # the clear screen's code bank, where UpdateObjAnim reads its framesets
const MENU_BANK: int = 0x7C  # `farcall $7c, UpdateObjAnim`, and LoadPauseMenuSprite's OAM table
const OAM_CLEAR: String = "35:4e26"  # LoadClearScreenSprite
const OAM_CLEAR_WARIO: String = "35:49cc"  # LoadClearScreenWarioSprite
const OAM_PENCIL: String = "35:65e1"  # LoadPencilSprite
const OAM_PAUSE_MENU: String = "7c:556c"  # LoadPauseMenuSprite
## The treasure's object by the level's end (grey, red, green, blue): y, x, frameset.
const TREASURE_OBJECTS: Array = [[0x38, 0x20, 0x5045], [0x38, 0x40, 0x504A], [0x38, 0x60, 0x504F], [0x38, 0x80, 0x5054]]
## The music boxes' objects 3-7 (gold to yellow): y, x, frameset.
const MUSIC_BOX_OBJECTS: Array = [[0x79, 0x84, 0x5068], [0x8D, 0x7F, 0x5065], [0x8C, 0x69, 0x5062],
		[0x79, 0x62, 0x505F], [0x67, 0x74, 0x505C]]
## Time Attack's keys' objects 4-7 (grey, red, green, blue): y, x, frameset.
const KEY_OBJECTS: Array = [[0x7C, 0x5C, 0x5095], [0x7C, 0x74, 0x5098], [0x8E, 0x5C, 0x509B], [0x8E, 0x74, 0x509E]]

## The V-Blank functions: the treasure screen's (a tile's rows turning, drawing only) and the
## musical coin screen's, which writes its queued BG entry and clears wcee4's bit 7.
enum VBlankFunc { NONE, TILES, COINS }

# WRAM0 variables the clear screen uses that the level does not: in the screens' shared WRAM0, where
# the map and the save read them too.
var wGameModeFlags: int:
	get:
		return r0(W_GAME_MODE_FLAGS)
	set(value):
		w0(W_GAME_MODE_FLAGS, value)
var wTransitionParam: int:
	get:
		return r0(W_TRANSITION_PARAM)
	set(value):
		w0(W_TRANSITION_PARAM, value)
var wNumMusicBoxes: int:
	get:
		return r0(W_NUM_MUSIC_BOXES)
	set(value):
		w0(W_NUM_MUSIC_BOXES, value)
var wTimeAttackResult: int:
	get:
		return r0(W_TIME_ATTACK_RESULT)
	set(value):
		w0(W_TIME_ATTACK_RESULT, value)
var wAllMusicalCoinsLevel: int:
	get:
		return r0(W_ALL_MUSICAL_COINS_LEVEL)
	set(value):
		w0(W_ALL_MUSICAL_COINS_LEVEL, value)
var wMusicalCoinVisualCounter: int:
	get:
		return r0(W_MUSICAL_COIN_VISUAL_COUNTER)
	set(value):
		w0(W_MUSICAL_COIN_VISUAL_COUNTER, value)
## For drawing: what the last loop's V-Blank wrote to VRAM from the queue ([bank, address, value]).
var vblank_writes: Array = []


# --- _ClearScreenStateTable ---

## One game loop of the clear screen: _ClearScreenStateTable by wSubState, then what the V-Blank
## function it left writes before the next loop.
func update() -> void:
	loops += 1
	screen_loads.clear()
	match sim.wSubState:
		0:
			fade(0)  # FastFadeToWhite
		1:
			init_clear_screen()
		2:
			fade(0)  # SlowFadeFromWhite
		3:
			update_clear_screen()
		SST_CLEAR_TIME_ATTACK, SST_CLEAR_MUSICAL_COINS:
			fade(2)  # SlowFadeBGToWhite (FADE_SPEED_FAST)
		5:
			init_time_attack_clear_screen()
		6, 10:
			fade(2)  # DarkenBGToPal_Fast
		7:
			update_time_attack_clear_screen()
		9:
			init_musical_coin_screen()
		11:
			count_musical_coins()
		12:
			move_pencil()
		13:
			scribble()
		SST_CLEAR_EXIT:
			exit_clear_screen()
		_:
			_note("_ClearScreenStateTable sub-state %d (DebugReset)" % sim.wSubState)
	vblank_writes.clear()
	if vblank_func == VBlankFunc.COINS and (r0(W_CEE4) & 0x80) != 0:
		# VBlank_MusicalCoinsScreen: the queued BG entry (two tiles, or with wcee4's low bits an
		# attribute in bank 1) to VRAM, for drawing
		var queue: Array[int] = []
		for index: int in 6:
			queue.append(r0(W_BG_MAP_TILE_VRAM0_QUEUE + index))
		if (r0(W_CEE4) & 0x7F) == 0:
			vblank_writes.append([0, (queue[0] << 8) | queue[1], queue[2]])
			vblank_writes.append([0, (queue[3] << 8) | queue[4], queue[5]])
		else:
			vblank_writes.append([1, (queue[0] << 8) | queue[1], queue[2]])
		w0(W_CEE4, r0(W_CEE4) & 0x7F)


# --- the menu objects ---

## LoadClearScreenSprite, LoadClearScreenWarioSprite, LoadPencilSprite: the object at its place
## less the scroll; LoadPauseMenuSprite: without it.
func load_obj_sprite(obj: int, table: String) -> void:
	var y: int = r3(obj + OBJ_Y) + OAM_Y_OFS
	if table != OAM_PAUSE_MENU:
		y -= sim.wSCY
	load_sprite(table, r3(obj + OBJ_FRAME), y & 0xFF, (r3(obj + OBJ_X) + OAM_X_OFS) & 0xFF, r3(obj + OBJ_ATTRIBUTES))


func _animate(obj: int, table: String = OAM_CLEAR, bank: int = CLEAR_BANK) -> void:
	update_obj_anim(obj, bank)
	load_obj_sprite(obj, table)


# --- the treasure screen (treasure_clear.asm) ---

## InitClearScreen: the treasure's transition (and power-up), the treasure marked collected, the
## music boxes and treasures counted, the screen's objects set up, and their first frames.
func init_clear_screen() -> void:
	sim.wResetDisabled = 1
	clear_virtual_oam()
	set_treasure_transition_param()
	if wTransitionParam != TRANSITION_RETURN_TO_MAP:
		var mask: Array[int] = _treasure_mask(wTransitionParam)
		wx(2, mask[0], rx(2, mask[0]) | mask[1])
	wNumMusicBoxes = _highest_music_box()
	update_num_collected_treasures()
	vblank_func = VBlankFunc.TILES
	sim.wSCX = 0
	sim.wSCY = 4
	set_up_clear_screen_objects()
	if (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) != 0:
		_animate(W_MENU_OBJ_8)
	_animate(W_CLEAR_SCREEN_WARIO, OAM_CLEAR_WARIO)
	if sim.wLevelEndScreen != LVLEND_NO_TREASURE:
		_animate(W_MENU_OBJ_1)
	_animate(W_MENU_OBJ_2)
	for index: int in range(5 - wNumMusicBoxes, 5):
		_animate([W_MENU_OBJ_3, W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][index])
	screen_loads.append(["treasure"])
	sim.wSubState = byte(sim.wSubState + 1)


## IsTreasureCollected's byte and bit for a treasure: [address, mask].
func _treasure_mask(treasure: int) -> Array[int]:
	return [W_TREASURES_COLLECTED + (treasure >> 3), 1 << (treasure & 7)]


func is_treasure_collected(treasure: int) -> bool:
	var mask: Array[int] = _treasure_mask(treasure)
	return (rx(2, mask[0]) & mask[1]) != 0


## The highest music box collected (treasures 1-5: yellow, blue, green, red, gold), as the
## treasures' first byte's bits 5 down to 1 tell it.
func _highest_music_box() -> int:
	var flags: int = rx(2, W_TREASURES_COLLECTED)
	for box: int in [5, 4, 3, 2, 1]:
		if (flags & (1 << box)) != 0:
			return box
	return 0


## SetTreasureTransitionParam: the level's treasure (LevelTreasureIDs_WithoutTemple, 4 a level), or
## the return to the map without one; a power-up treasure sets its power-up for Action Help.
func set_treasure_transition_param() -> void:
	if sim.wLevelEndScreen == LVLEND_NO_TREASURE:
		wTransitionParam = TRANSITION_RETURN_TO_MAP
		return
	wTransitionParam = _table("level_treasure_ids", ((sim.wLevel >> 3) * 4 + sim.wLevelEndScreen - 1) & 0xFF)
	if POWER_UP_TREASURES.has(wTransitionParam):
		sim.wPowerUpLevel = int(POWER_UP_TREASURES[wTransitionParam]) | ACTION_HELP_LEVEL_CLEAR


## UpdateNumCollectedTreasures: treasures 100 down to 1, counted in BCD.
func update_num_collected_treasures() -> void:
	var count: int = 0
	for treasure: int in range(NUM_TREASURES - 1, 0, -1):
		if is_treasure_collected(treasure):
			count += 1
	var tens: int = count / 10
	sim.wNumCollectedTreasures = ((count / 100) << 8) | ((tens % 10) << 4) | (count % 10)


## Func_1e015b: the power-up's object, Clear Wario, the treasure's, object 2, and the music boxes'.
func set_up_clear_screen_objects() -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) != 0:
		set_up_obj(W_MENU_OBJ_8, 0x53, 0x24, 0x506B)
	set_up_obj(W_CLEAR_SCREEN_WARIO, 0x76, 0x34, 0x4D58 if wTransitionParam == TRANSITION_RETURN_TO_MAP else 0x4D18)
	w3(W_CLEAR_SCREEN_WARIO_VAR, 0)
	var end: int = sim.wLevelEndScreen
	if end >= LVLEND_GREY_TREASURE and end < LVLEND_NO_TREASURE:
		var treasure: Array = TREASURE_OBJECTS[end - 1]
		set_up_obj(W_MENU_OBJ_1, treasure[0], treasure[1], treasure[2])
	set_up_obj(W_MENU_OBJ_2, 0x28, 0x30, 0x5059)
	for index: int in range(5 - wNumMusicBoxes, 5):
		var box: Array = MUSIC_BOX_OBJECTS[index]
		set_up_obj([W_MENU_OBJ_3, W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][index], box[0], box[1], box[2])


## UpdateClearScreen: the objects (Clear Wario's second animation once his first ends), then A goes
## on to the musical coin screen.
func update_clear_screen() -> void:
	if (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) != 0:
		_animate(W_MENU_OBJ_8)
	_clear_wario_once_reset(wTransitionParam != TRANSITION_RETURN_TO_MAP)
	load_obj_sprite(W_MENU_OBJ_2, OAM_CLEAR)
	if sim.wLevelEndScreen != LVLEND_NO_TREASURE:
		_animate(W_MENU_OBJ_1)
	for index: int in range(5 - wNumMusicBoxes, 5):
		load_obj_sprite([W_MENU_OBJ_3, W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][index], OAM_CLEAR)
	clear_unused_virtual_oam()
	if (sim.wJoypadPressed & WarioRam.PAD_A) != 0:
		sim.wSubState = SST_CLEAR_MUSICAL_COINS


## Clear Wario's animation; when it first starts over, his second (celebrating, or not) from the start.
func _clear_wario_once_reset(celebrating: bool) -> void:
	update_obj_anim(W_CLEAR_SCREEN_WARIO, CLEAR_BANK)
	if r3(W_CLEAR_SCREEN_WARIO_VAR) == 0 and r3(W_OBJ_ANIM_WAS_RESET) != 0:
		w3(W_CLEAR_SCREEN_WARIO_VAR, 1)
		w3(W_CLEAR_SCREEN_WARIO + OBJ_FRAMESET_OFFSET, 0)
		w3(W_CLEAR_SCREEN_WARIO + OBJ_DURATION, 0)
		_set_frameset(W_CLEAR_SCREEN_WARIO, 0x4D1B if celebrating else 0x4D5F)
		update_obj_anim(W_CLEAR_SCREEN_WARIO, CLEAR_BANK)
	load_obj_sprite(W_CLEAR_SCREEN_WARIO, OAM_CLEAR_WARIO)


# --- Time Attack's screen (time_attack_clear.asm) ---

## InitTimeAttackClearScreen: back to the map, the time against the level's best (Func_1e005f), and
## the screen's objects with the keys found.
func init_time_attack_clear_screen() -> void:
	sim.wResetDisabled = 1
	clear_virtual_oam()
	wTransitionParam = TRANSITION_RETURN_TO_MAP
	_time_attack_result()
	vblank_func = VBlankFunc.TILES
	sim.wSCX = 0
	sim.wSCY = 4
	_set_up_time_attack_objects()
	if wTimeAttackResult == TIME_ATTACK_GOT_HIGH_SCORE:
		_animate(W_MENU_OBJ_8)
	_animate(W_CLEAR_SCREEN_WARIO, OAM_CLEAR_WARIO)
	_animate(W_MENU_OBJ_2)
	_animate(W_MENU_OBJ_3)
	for key: int in 4:
		if (sim.wKeyAndTreasureFlags & (1 << key)) != 0:
			_animate([W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][key])
	screen_loads.append(["time_attack"])
	sim.wSubState = byte(sim.wSubState + 1)


## Func_1e005f's .GetResult, then its copy of the level's best into w3d511: with all four keys, a
## new best for the level (BCD, minutes then seconds) is kept.
func _time_attack_result() -> void:
	var best: int = W_LEVEL_TIME_ATTACK_SCORES + (sim.wLevel >> 3) * 2
	wTimeAttackResult = 0
	if (sim.wKeyAndTreasureFlags & KEYS_MASK) == KEYS_MASK:
		wTimeAttackResult = TIME_ATTACK_NO_HIGH_SCORE
		var minutes: int = r0(W_LEVEL_TIME)
		var seconds: int = r0(W_LEVEL_TIME + 1)
		if minutes < r0(best) or (minutes == r0(best) and seconds < r0(best + 1)):
			w0(best, minutes)
			w0(best + 1, seconds)
			wTimeAttackResult = TIME_ATTACK_GOT_HIGH_SCORE
	w3(W3D511, r0(best))
	w3(W3D511 + 1, r0(best + 1))


## Func_1e028a
func _set_up_time_attack_objects() -> void:
	if wTimeAttackResult == TIME_ATTACK_GOT_HIGH_SCORE:
		set_up_obj(W_MENU_OBJ_8, 0x60, 0x1C, 0x5080)
	var high: bool = wTimeAttackResult == TIME_ATTACK_GOT_HIGH_SCORE
	set_up_obj(W_CLEAR_SCREEN_WARIO, 144, 0x2C, 0x4D18 if high else 0x4D58)  # SCREEN_HEIGHT_PX
	w3(W_CLEAR_SCREEN_WARIO_VAR, 0)
	set_up_obj(W_MENU_OBJ_2, 0x28, 0x30, 0x5059)
	set_up_obj(W_MENU_OBJ_3, 0x44, 0x28, 0x50A1)
	for key: int in 4:
		if (sim.wKeyAndTreasureFlags & (1 << key)) != 0:
			var place: Array = KEY_OBJECTS[key]
			set_up_obj([W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][key], place[0], place[1], place[2])


## Func_d434c
func update_time_attack_clear_screen() -> void:
	if wTimeAttackResult == TIME_ATTACK_GOT_HIGH_SCORE:
		_animate(W_MENU_OBJ_8)
	_clear_wario_once_reset(wTimeAttackResult == TIME_ATTACK_GOT_HIGH_SCORE)
	load_obj_sprite(W_MENU_OBJ_2, OAM_CLEAR)
	load_obj_sprite(W_MENU_OBJ_3, OAM_CLEAR)
	for key: int in 4:
		if (sim.wKeyAndTreasureFlags & (1 << key)) != 0:
			load_obj_sprite([W_MENU_OBJ_4, W_MENU_OBJ_5, W_MENU_OBJ_6, W_MENU_OBJ_7][key], OAM_CLEAR)
	clear_unused_virtual_oam()
	if (sim.wJoypadPressed & WarioRam.PAD_A) != 0:
		sim.wSubState = SST_CLEAR_MUSICAL_COINS


# --- the musical coin screen (musical_coins.asm, musical_coin_flags.asm, pencil.asm) ---

## InitMusicalCoinScreen: a level's eight coins marked in wMusicalCoinFlags (the pencil then
## colours its flag), the coin counter's object, the screen's animated tiles, and a second's wait.
func init_musical_coin_screen() -> void:
	clear_virtual_oam()
	wAllMusicalCoinsLevel = 0xFF
	if sim.wNumMusicalCoins == NUM_LEVEL_MUSICAL_COINS:
		set_musical_coin_flag()
	vblank_func = VBlankFunc.COINS
	sim.wSCX = 0
	sim.wSCY = 0
	set_up_obj(W_MENU_OBJ_3, 0x38, 0x40, 0x5CD4)
	update_obj_anim(W_MENU_OBJ_3, MENU_BANK)
	load_obj_sprite(W_MENU_OBJ_3, OAM_PAUSE_MENU)
	sim.wAnimatedTilesFrameDuration = 8
	sim.wAnimatedTilesGfx = ANIMATED_TILES_GFX_15
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	sim.wRoomAnimatedTilesEnabled = 1
	wMusicalCoinVisualCounter = 0
	w0(W_TIMER, 60)
	screen_loads.append(["musical_coins"])
	sim.wSubState = byte(sim.wSubState + 1)


## SetMusicalCoinFlag: the level's bit in wMusicalCoinFlags; already set, the pencil has nothing to
## colour (wAllMusicalCoinsLevel $ff).
func set_musical_coin_flag() -> void:
	var level: int = sim.wLevel >> 3
	wAllMusicalCoinsLevel = level
	var address: int = W_MUSICAL_COIN_FLAGS + (level >> 3)
	var bit: int = 1 << (level & 7)
	if (r0(address) & bit) != 0:
		wAllMusicalCoinsLevel = 0xFF
	else:
		w0(address, r0(address) | bit)


## Func_d4472: the counter's object; the coins counted up one every 4 loops after the wait (each
## queued as two BG tiles for V-Blank), then the pencil or, with no flag to colour, the way out.
func count_musical_coins() -> void:
	_animate(W_MENU_OBJ_3, OAM_PAUSE_MENU, MENU_BANK)
	clear_unused_virtual_oam()
	if wMusicalCoinVisualCounter != sim.wNumMusicalCoins:
		if r0(W_TIMER) != 0:
			w0(W_TIMER, r0(W_TIMER) - 1)
			return
		if (sim.wGlobalCounter & 0b11) != 0:
			return
		wMusicalCoinVisualCounter = byte(wMusicalCoinVisualCounter + 1)
		var tile: int = (wMusicalCoinVisualCounter * 2 + 0xA0) & 0xFF
		for index: int in 6:
			w0(W_BG_MAP_TILE_VRAM0_QUEUE + index, [0x98, 0x8B, tile, 0x98, 0xAB, tile + 1][index])
		w0(W_CEE4, 0x80)
		return
	if wAllMusicalCoinsLevel == 0xFF:
		_leave_after_two_wraps()
		return
	set_up_obj(W_MENU_OBJ_1, 0x42, 0x60, 0x65F0)
	update_obj_anim(W_MENU_OBJ_1, CLEAR_BANK)
	sim.wSubState = byte(sim.wSubState + 1)


## Func_d45e1: wTimer's two bytes as 0 and 2 (the exit's wait), and the exit.
func _leave_after_two_wraps() -> void:
	w0(W_TIMER, 0)
	w0(W_TIMER + 1, 2)
	sim.wSubState = SST_CLEAR_EXIT


## The level's row (0-4) and column (0-4) on the flag chart.
func _chart_place() -> Array[int]:
	var level: int = wAllMusicalCoinsLevel
	for row: int in [4, 3, 2, 1]:
		if level >= NUM_LEVELS - 5 * (5 - row):
			return [row, level - 5 * row]
	return [0, level]


## Func_d4507 with DoPencilMovement: the pencil down to the level's row, then left to its column.
func move_pencil() -> void:
	var place: Array[int] = _chart_place()
	var done: bool = false
	var target_y: int = 0x48 + place[0] * 8
	if r3(W_MENU_OBJ_1 + OBJ_Y) != target_y:
		w3(W_MENU_OBJ_1 + OBJ_Y, r3(W_MENU_OBJ_1 + OBJ_Y) + 1)
	else:
		var target_x: int = [0x40, 0x48, 0x50, 0x58, 0x60][_pencil_column(place[1])]
		if r3(W_MENU_OBJ_1 + OBJ_X) != target_x:
			w3(W_MENU_OBJ_1 + OBJ_X, r3(W_MENU_OBJ_1 + OBJ_X) - 1)
		else:
			done = true
	load_obj_sprite(W_MENU_OBJ_1, OAM_PENCIL)
	_animate(W_MENU_OBJ_3, OAM_PAUSE_MENU, MENU_BANK)
	clear_unused_virtual_oam()
	if done:
		w0(W_TIMER, 0)
		sim.wSubState = byte(sim.wSubState + 1)


## DoPencilMovement's column: up to four `dec b` checks find columns 1-4; column 0 falls through
## them (b wraps).
func _pencil_column(column: int) -> int:
	return column if column >= 1 and column <= 4 else 0


## Func_d454c with DoPencilScribbling: the pencil shakes by its offsets for 52 loops; at the 20th
## the level's flag colour is queued for V-Blank (a BG attribute).
func scribble() -> void:
	var timer: int = r0(W_TIMER)
	w3(W_MENU_OBJ_1 + OBJ_Y, r3(W_MENU_OBJ_1 + OBJ_Y) + _table("pencil_x_offsets", timer))
	w3(W_MENU_OBJ_1 + OBJ_X, r3(W_MENU_OBJ_1 + OBJ_X) + _table("pencil_y_offsets", timer))
	load_obj_sprite(W_MENU_OBJ_1, OAM_PENCIL)
	_animate(W_MENU_OBJ_3, OAM_PAUSE_MENU, MENU_BANK)
	clear_unused_virtual_oam()
	w0(W_TIMER, timer + 1)
	if r0(W_TIMER) >= 52:
		_leave_after_two_wraps()
		return
	if r0(W_TIMER) != 20:
		return
	var palette: int = _table("musical_coin_level_bg_pals", wAllMusicalCoinsLevel)
	var place: Array[int] = _chart_place()
	var address: int = 0x9800 + (9 + place[0]) * 32 + 8 + place[1]
	w0(W_BG_MAP_TILE_VRAM0_QUEUE, address >> 8)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE + 1, address)
	w0(W_BG_MAP_TILE_VRAM0_QUEUE + 2, palette)
	w0(W_CEE4, 0x81)


## ExitClearScreen: the counter's object until A or wTimer's two bytes run out, then Action Help
## for a new power-up, or the map (Func_4628: the animated tiles stopped, wDayNight's bit 7).
func exit_clear_screen() -> void:
	_animate(W_MENU_OBJ_3, OAM_PAUSE_MENU, MENU_BANK)
	clear_unused_virtual_oam()
	if (sim.wJoypadPressed & WarioRam.PAD_A) == 0:
		w0(W_TIMER, r0(W_TIMER) - 1)
		if r0(W_TIMER) != 0:
			return
		w0(W_TIMER + 1, r0(W_TIMER + 1) - 1)
		if r0(W_TIMER + 1) != 0:
			return
	w0(W_TIMER, 0)
	w0(W_TIMER + 1, 0)
	if (wGameModeFlags & MODE_TIME_ATTACK) == 0 and (sim.wPowerUpLevel & ACTION_HELP_LEVEL_CLEAR) != 0:
		sim.wState = ST_ACTION_HELP  # OpenActionHelp
		sim.wSubState = 0
		return
	sim.wAnimatedTilesFrameDuration = 0
	sim.wAnimatedTilesGfx = 0
	sim.wAnimatedTilesFrameCount = 0
	sim.wAnimatedTilesFrame = 0
	w3(W3D50D, 0)
	sim.wDayNight |= 0x80
	sim.wState = ST_OVERWORLD  # StartOverworldState
	sim.wSubState = 0

