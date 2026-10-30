class_name OverworldOWFunctions
extends OverworldNorthEpilogue
## The OW functions an event's scene runs on its map side (_DoOWFunction, src/engine/overworld/bank2d.asm),
## translated as far as the owner's movies reach them (WL3-052): each loop wOWFuncCounter counts and the
## function's step (w2d062) runs: waits, scene objects set to new states and waited for, the falling
## seeds and crayon, the tornado blown away, the rain's flashes and the pool filled, the seeds sent,
## the bridge lowered, the tower raised; at its end (EndOWFunc) wOWSceneActionParam is cleared. The
## others are noted as not ported.

const W_OW_PENDING_TILE_UPDATE: int = 0xD060
const W2D127: int = 0xD127
const W2D129: int = 0xD129
const W2D13F: int = 0xD13F
const SCENE_FALLING_Y_OFFSETS: int = 0x58AE  # bank $2d: GetSceneFallingYOffset.yoffsets
const NUM_SCENE_FALLING_Y_OFFSETS: int = 100
const SEND_SEEDS_X_OFFSETS: int = 0x66C2  # bank $2d: SOWFunc_SendSeeds.x_offsets (24, then code)
const OW_SCENE_LEVEL_NAMES: int = 0x6E5A  # bank $2d: LoadOWSceneLevelName.MapSidePointers
const DATA_B6294: int = 0x6294  # bank $2d: the crayon's scribble
const DATA_B6478: int = 0x6478  # bank $2d: the tornado blown away
const PALS_84140: int = 0x4140  # bank $21: West's palettes after the rain's flashes
const PALS_8694D: int = 0x694D  # bank $21: the rain's flash 1
const PALS_8698D: int = 0x698D  # bank $21: the rain's flash 2
const OW_FUNC_BANK: int = 0x2D
const BGPI_AUTOINC: int = 0x80
const PAL_SIZE: int = 8


## DoOWFunction, _DoOWFunction: wOWFuncCounter counts, then by the map side wOWSceneActionParam's
## function.
func do_ow_function() -> void:
	w2(W_OW_FUNC_COUNTER, r2(W_OW_FUNC_COUNTER) + 1)
	var function: int = r2(W_OW_SCENE_ACTION_PARAM)
	match r2(W_CUR_MAP_SIDE):
		NORTH:
			_north_ow_function(function)
		WEST:
			_west_ow_function(function)
		SOUTH:
			_south_ow_function(function)
		EAST:
			_note("EastOWFunctions function $%02x (not ported)" % function)
		_:
			_note("_DoOWFunction map side %d (past its table)" % r2(W_CUR_MAP_SIDE))


## NorthOWFunctions (NOWFUNC_*).
func _north_ow_function(function: int) -> void:
	match function:
		0x01:
			_nowfunc_cut_tree()
		0x02:
			_nowfunc_open_gate()
		0x03:  # NOWFunc_Garlic
			end_ow_func()
		0x04:  # NOWFunc_MagicSeed
			_magic_seed(0x4C, 0x08, 0x09, 0x0A, 0x0B)
		0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F:
			_nowfunc_crayon()
		0x12:
			nowfunc_prologue()  # NOWFUNC_PROLOGUE (OverworldNorthEpilogue)
		_:
			_note("NorthOWFunctions function $%02x (not ported)" % function)


## WestOWFunctions (WOWFUNC_*).
func _west_ow_function(function: int) -> void:
	match function:
		0x01:
			_wowfunc_rain()
		0x02:
			_wowfunc_clear_tornado()
		0x03:
			_wowfunc_elevator_working()
		0x04:  # WOWFunc_MagicSeed
			_magic_seed(0x5B, 0x0B, 0x0C, 0x0D, 0x0E)
		_:
			_note("WestOWFunctions function $%02x (not ported)" % function)


## SouthOWFunctions (SOWFUNC_*).
func _south_ow_function(function: int) -> void:
	match function:
		0x01:
			_sowfunc_send_seeds()
		0x02:  # SOWFunc_MagicSeed
			_magic_seed(0x56, 0x06, 0x03, 0x02, 0x01)
		0x03:
			_sowfunc_yellow_music_box()
		0x05:
			_sowfunc_raise_tower()
		_:
			_note("SouthOWFunctions function $%02x (not ported)" % function)


func _past_table(function: String) -> void:
	_note("%s step %d (past its table)" % [function, r2(W2D062)])


# --- the steps the functions share ---

## WaitOWObjState: once the state at `at` is `state`, AdvanceOWFunc (WaitOWObjDisappear: state 0).
func wait_ow_obj_state(at: int, state: int) -> void:
	if rd(at) != state:
		return
	advance_ow_func()


## Func_b5868: wOWPendingTileUpdate set (the V-Blank copies the map to VRAM), the map patch at bank $21
## `patch` applied (Func_854ee).
func _func_b5868(patch: int) -> void:
	w2(W_OW_PENDING_TILE_UPDATE, TRUE)
	func_854ee(patch)


## GetSceneFallingYOffset: the falling's y step for the count at `at` (past the table's 100 entries the
## count goes back to 96).
func get_scene_falling_y_offset(at: int) -> int:
	var count: int = rd(at)
	if count >= NUM_SCENE_FALLING_Y_OFFSETS:
		count = NUM_SCENE_FALLING_Y_OFFSETS - 4
		wr(at, count)
	return rb(OW_FUNC_BANK, SCENE_FALLING_Y_OFFSETS + count)


## LoadOWSceneLevelName: the name of the level the function names (.MapSidePointers by the map side,
## one less off North), its palette's steps cleared.
func load_ow_scene_level_name() -> void:
	var side: int = r2(W_CUR_MAP_SIDE)
	var table: int = rw(OW_FUNC_BANK, OW_SCENE_LEVEL_NAMES + ((side * 2) & 0xFF))
	var level: int = rb(OW_FUNC_BANK, (table + ((r2(W_OW_SCENE_ACTION_PARAM) - 1) & 0xFF)) & 0xFFFF)
	if side != NORTH:
		level = byte(level - 1)
	load_level_name(side, level)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	advance_ow_func()


## WaitOWSceneLevelNameFadeIn: FadeInLevelName until done.
func wait_ow_scene_level_name_fade_in() -> void:
	if fade_in_level_name():
		return
	advance_ow_func()


# --- North ---

## NOWFunc_CutTree: the tree (wSceneObj8) falls (state 2) and disappears.
func _nowfunc_cut_tree() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1, 5:  # .Wait1, .Wait2
			wait_ow_func(4)
		2:  # .SetTreeFall (a sound, not ported)
			set_scene_obj_state(8, 0x02)
			advance_ow_func()
		3:  # .WaitFall (a sound, not ported)
			if rd(scene_obj(8) + SCENE_OBJ_FRAME) == 0x07:
				advance_ow_func()
		4:  # .WaitDisappear
			wait_ow_obj_state(scene_obj(8) + SCENE_OBJ_STATE, 0)
		6:
			end_ow_func()
		_:
			_past_table("NOWFunc_CutTree")


## NOWFunc_OpenGate: the gate (wSceneObj10) opens (state 4) until its animation ends.
func _nowfunc_open_gate() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1, 4:  # .Wait1, .Wait2
			wait_ow_func(4)
		2:  # .OpenDoor (a sound, not ported)
			set_scene_obj_state(10, 0x04)
			advance_ow_func()
		3:  # .WaitAnim
			wait_ow_obj_state(scene_obj(10) + SCENE_OBJ_STATE, 0)
		5:
			end_ow_func()
		_:
			_past_table("NOWFunc_OpenGate")


## NOWFunc_MagicSeed, WOWFunc_MagicSeed, SOWFunc_MagicSeed: the level's name shown, the seed (wSceneObj4)
## falls to y `ground` (state `landed`), rests (`rested`), then its stalk grows (`grow`, `grown`).
func _magic_seed(ground: int, landed: int, rested: int, grow: int, grown: int) -> void:
	var seed: int = scene_obj(4)
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Wait1
			wait_ow_func(20)
		2:
			load_ow_scene_level_name()
		3:
			wait_ow_scene_level_name_fade_in()
		4:  # WaitOWScene16Frames
			wait_ow_func(16)
		5:  # .PlayFallSFX (not ported)
			advance_ow_func()
		6:  # .SeedFall (a sound at its end, not ported)
			var y: int = byte(get_scene_falling_y_offset(W_OW_FUNC_COUNTER) + rd(seed + SCENE_OBJ_Y))
			wr(seed + SCENE_OBJ_Y, y)
			if y < ground:
				return
			set_scene_obj_state(4, landed)
			advance_ow_func()
		7:  # .WaitSeedFall
			wait_ow_obj_state(seed + SCENE_OBJ_STATE, rested)
		8:  # .Wait2
			wait_ow_func(30)
		9:  # .GrowStalk (a sound, not ported)
			set_scene_obj_state(4, grow)
			advance_ow_func()
		10:  # .WaitGrowStalk
			wait_ow_obj_state(seed + SCENE_OBJ_STATE, grown)
		11:
			end_ow_func()
		_:
			_past_table("the magic seed's OW function")


## NOWFunc_Crayon: the crayon (wSceneObj5, its shadow wSceneObj1) falls, lifts, and scribbles; with all
## crayons the map's palettes fade to the Golf Building's colours.
func _nowfunc_crayon() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1, 12:  # .Wait1, .Wait4
			wait_ow_func(20)
		2:  # .PlayFallSFX (not ported)
			advance_ow_func()
		3:  # .CrayonFall (a sound at its end, not ported)
			var y: int = byte(get_scene_falling_y_offset(W_OW_FUNC_COUNTER) + rd(scene_obj(5) + SCENE_OBJ_Y))
			wr(scene_obj(5) + SCENE_OBJ_Y, y)
			wr(scene_obj(1) + SCENE_OBJ_Y, y - 6)
			if y < 0x40:
				return
			wr(scene_obj(1) + SCENE_OBJ_STATE, 0)
			advance_ow_func()
		4:  # .Wait2
			wait_ow_func(4)
		5:  # .CrayonLift
			set_scene_obj_state(5, 0x1E)
			advance_ow_func()
		6:  # .WaitCrayonLift
			wait_ow_obj_state(scene_obj(5) + SCENE_OBJ_STATE, 0x20)
		7:  # .Wait3
			wait_ow_func(10)
		8:  # .Scribble (a sound at step $0a, not ported)
			apply_ow_movement(scene_obj(5), DATA_B6294)
			if rd(scene_obj(5) + W_SCENE_OBJ_UNK7) != 0:
				return
			advance_ow_func()
		9:  # .AdvanceIfCollectedAllCrayons
			if (r2(W_CRAYON_FLAGS) & ALL_CRAYONS) == ALL_CRAYONS:
				advance_ow_func()
				return
			w2(W2D062, 0x0C)
			w2(W_OW_FUNC_COUNTER, 0)
		10:  # .LoadNewOWPal
			for offset: int in 8 * PAL_SIZE:
				w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))
			copy_rom(MAP_PALS_BANK, PALS_84500, W_TEMP_PALS_1, 8 * PAL_SIZE)
			w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
			advance_ow_func()
		11:  # .FadePal
			if (r2(W_OW_FUNC_COUNTER) & 0x07) == 0:
				_func_8518c()
		13:
			end_ow_func()
		_:
			_past_table("NOWFunc_Crayon")


## Func_8518c (bank $21): its first call wPalConfig1 set for the 8 BG palettes from wTempBGPals; then
## a slow fade step (Func_851bc) until done, then the next step.
func _func_8518c() -> void:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 1:
		w2(W_PAL_CONFIG_1_SOURCE_HI, W_TEMP_BG_PALS >> 8)
		w2(W_PAL_CONFIG_1_SOURCE_HI + 1, W_TEMP_BG_PALS & 0xFF)
		w2(W_PAL_CONFIG_1_INDEX, BGPI_AUTOINC)  # OBPI_AUTOINC | palette 0: the same bits
		w2(W_PAL_CONFIG_1_NUMBER, 8)
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)
		return
	if fade_bg_pal_config_slowly():  # Func_851bc
		return
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_OW_FUNC_COUNTER, 0)
	w2(W2D062, r2(W2D062) + 1)


# --- West ---

## WOWFunc_Rain: the palettes flash (.UpdatePals, w2d13f counting the thunder's sound, not ported), the
## rain clouds (wSceneObj15) come, the pool fills (Data_8550b), the clouds (wSceneObj14) go.
func _wowfunc_rain() -> void:
	_rain_update_pals()
	_rain_play_thunder_sfx()
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .InitPalConfig
			w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0x5A)
			w2(W2D13F, 0x01)
			advance_ow_func()
		2:  # .Wait1
			wait_ow_func(180)
		3:  # .ShowRainClouds
			set_scene_obj_state(15, 0x01)
			advance_ow_func()
		4:  # .WaitRainClouds
			if rd(scene_obj(15) + SCENE_OBJ_FRAME) == 0x0E:
				advance_ow_func()
		5:  # .FillPool
			if r2(W_OW_FUNC_COUNTER) < 2:
				return
			_func_b5868(DATA_8550B)
			advance_ow_func()
		6:  # .Wait2
			wait_ow_func(120)
		7:  # .WaitRainAndHideClouds
			if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 0x3C:
				return
			w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
			w2(W2D13F, 0)
			set_scene_obj_state(14, 0x04)
			advance_ow_func()
		8:  # .WaitCloudsDisappear
			wait_ow_obj_state(scene_obj(14) + SCENE_OBJ_STATE, 0)
		9:  # .Wait3
			wait_ow_func(60)
		10:
			end_ow_func()
		_:
			_past_table("WOWFunc_Rain")


## WOWFunc_Rain.PlayThunderSFX: w2d13f counts to $1b, then (the thunder's sound) starts again at 1.
func _rain_play_thunder_sfx() -> void:
	var count: int = r2(W2D13F)
	if count == 0:
		return
	w2(W2D13F, count + 1)
	if r2(W2D13F) < 0x1B:
		return
	w2(W2D13F, 0x01)


## WOWFunc_Rain.UpdatePals: while wPalConfig1TotalSteps counts (to $82, then from 1 again), at its
## flashes the BG palettes (wTempPals1) become a flash's or, at $2c, the side's own, shown through
## wPalConfig1 (8 palettes).
func _rain_update_pals() -> void:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) == 0:
		return
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)
	var pals: int
	match r2(W_PAL_CONFIG_1_TOTAL_STEPS):
		0x09, 0x16, 0x1E, 0x26:
			pals = PALS_8698D
		0x12, 0x1A, 0x22, 0x29:
			pals = PALS_8694D
		0x2C:
			pals = PALS_84140
		_:
			if r2(W_PAL_CONFIG_1_TOTAL_STEPS) >= 0x82:
				w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0x01)
			return
	copy_rom(MAP_PALS_BANK, pals, W_TEMP_PALS_1, 8 * PAL_SIZE)
	w2(W_PAL_CONFIG_1, LOW_R_BGPI)
	w2(W_PAL_CONFIG_1_INDEX, BGPI_AUTOINC)
	w2(W_PAL_CONFIG_1_NUMBER, 1 * PAL_SIZE)  # `1 palettes`: 8
	w2(W_PAL_CONFIG_1_SOURCE_HI, W_TEMP_PALS_1 >> 8)
	w2(W_PAL_CONFIG_1_SOURCE_HI + 1, W_TEMP_PALS_1 & 0xFF)


## WOWFunc_ClearTornado: the tornado (wSceneObj1) goes on its round to its start (UpdateOWTornado), is
## blown away (Data_b6478), and is gone.
func _wowfunc_clear_tornado() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .ShowTornado (a sound at its first step, not ported)
			apply_ow_movement(scene_obj(1), DATA_B6337)  # UpdateOWTornado (its sound not ported)
			if rd(scene_obj(1) + W_SCENE_OBJ_UNK7) != 0:
				return
			advance_ow_func()
		2:  # .ClearTornado
			if apply_ow_movement(scene_obj(1), DATA_B6478):
				advance_ow_func()
		3:  # .HideTornado
			set_scene_obj_state(1, 0x00)
			advance_ow_func()
		4:  # .Wait1
			wait_ow_func(20)
		5:
			end_ow_func()
		_:
			_past_table("WOWFunc_ClearTornado")


## WOWFunc_ElevatorWorking: the elevator (wSceneObj8) starts (state 6).
func _wowfunc_elevator_working() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Wait1
			wait_ow_func(20)
		2:  # .SetElevatorWorking
			set_scene_obj_state(8, 0x06)
			advance_ow_func()
		3:  # .Wait2
			wait_ow_func(200)
		4:
			end_ow_func()
		_:
			_past_table("WOWFunc_ElevatorWorking")


# --- South ---

## SOWFunc_SendSeeds: the three seeds (wSceneObj4, 2, 3) shown (state 6) one by one, then flown off
## (.MoveSeeds) until the last is off screen.
func _sowfunc_send_seeds() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Wait1
			wait_ow_func(30)
		2:  # .ShowSeed1 (a sound, not ported)
			set_scene_obj_state(4, 0x06)
			advance_ow_func()
		3, 5, 7:  # .WaitShowSeed
			wait_ow_func(30)
		4:  # .ShowSeed2
			set_scene_obj_state(2, 0x06)
			advance_ow_func()
		6:  # .ShowSeed3
			w2(W2D125, 0x01)
			set_scene_obj_state(3, 0x06)
			advance_ow_func()
		8:  # .PlayFlyingSFX (not ported)
			advance_ow_func()
		9:  # .MoveSeeds
			if r2(W2D125) != 0:
				_move_seed_2()
			if r2(W2D129) != 0:
				_move_seed_1()
			if r2(W2D127) != 0:
				_move_seed_3()
			if rd(scene_obj(3) + SCENE_OBJ_X) < 0xF0:
				return
			w2(W2D127, 0)
			advance_ow_func()
		10:  # .Wait2
			wait_ow_func(10)
		11:
			end_ow_func()
		_:
			_past_table("SOWFunc_SendSeeds")


## .MoveSeed2: wSceneObj2 up 3 and left by its x step (w2d125 counting); at y $1a the first seed sets off
## (w2d129, a sound not ported); off screen, it stops.
func _move_seed_2() -> void:
	var obj: int = scene_obj(2)
	wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) - _send_seeds_x_offset(W2D125))
	wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) - 3)
	var y: int = rd(obj + SCENE_OBJ_Y)
	if y == 0x1A:
		w2(W2D129, 0x01)
		return
	if y < 0xF0:
		return
	w2(W2D125, 0)


## .MoveSeed1: wSceneObj4 up 3; at y $1a the third sets off (w2d127, a sound not ported); off screen,
## it stops.
func _move_seed_1() -> void:
	var at: int = scene_obj(4) + SCENE_OBJ_Y
	wr(at, rd(at) - 3)
	var y: int = rd(at)
	if y == 0x1A:
		w2(W2D127, 0x01)
		return
	if y < 0xF0:
		return
	w2(W2D129, 0)


## .MoveSeed3: wSceneObj3 up 3 and right by its x step (w2d127 counting).
func _move_seed_3() -> void:
	var obj: int = scene_obj(3)
	wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) + _send_seeds_x_offset(W2D127))
	wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) - 3)


## .GetXOffset: the x step for the count at `at` (which counts to $18; at $18 the byte after the
## table, SOWFunc_MagicSeed's first, is read).
func _send_seeds_x_offset(at: int) -> int:
	var count: int = rd(at)
	if count < 0x18:
		wr(at, count + 1)
	return rb(OW_FUNC_BANK, SEND_SEEDS_X_OFFSETS + count)


## SOWFunc_YellowMusicBox: the music box plays (its sound, not ported), the bridge (wSceneObj6) lowers
## (state 8) until lowered (9).
func _sowfunc_yellow_music_box() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Wait1
			wait_ow_func(20)
		2:  # .PlayMusicBoxSFX (not ported)
			advance_ow_func()
		3:  # .WaitMusic
			wait_ow_func(254)
		4:  # .LowerBridge (a sound, not ported)
			set_scene_obj_state(6, 0x08)
			advance_ow_func()
		5:  # .ShowLoweredBridge
			wait_ow_obj_state(scene_obj(6) + SCENE_OBJ_STATE, 0x09)
		6:  # .Wait2
			wait_ow_func(40)
		7:
			end_ow_func()
		_:
			_past_table("SOWFunc_YellowMusicBox")


## SOWFunc_RaiseTower: the dust (wSceneObj2, state $0b), the tower (wSceneObj3) shaking up in three
## stages (each $10 lower and its next state), then shaking until it settles; both gone, the raised
## tower's map patch (Data_85579).
func _sowfunc_raise_tower() -> void:
	match r2(W2D062):
		0:
			advance_ow_func()
		1:  # .Wait1
			wait_ow_func(30)
		2:  # .StartDust (a sound, not ported)
			set_scene_obj_state(2, 0x0B)
			advance_ow_func()
		3:  # .Wait2
			wait_ow_func(45)
		4, 5, 6:  # .RaiseTower
			if _func_b6a16().y == 0:
				return
			var tower: int = scene_obj(3)
			wr(tower + SCENE_OBJ_Y, rd(tower + SCENE_OBJ_Y) + 0x10)
			set_scene_obj_state(3, rd(tower + SCENE_OBJ_STATE) + 1)
			advance_ow_func()
		7:  # .FinishRaiseTower
			if _func_b6a16().x == 0x50:
				advance_ow_func()
		8:  # .Func_b6a0f
			if _func_b6a2e().y != 0:
				advance_ow_func()
		9, 11:  # .Wait3, .Wait4
			wait_ow_func(40)
		10:  # .Func_b6a4b
			set_scene_obj_state(2, 0x00)
			set_scene_obj_state(3, 0x00)
			_func_b5868(DATA_85579)
			advance_ow_func()
		12:
			end_ow_func()
		_:
			_past_table("SOWFunc_RaiseTower")


## .Func_b6a16: the tower shakes by wGlobalCounter: every 8th loop down 1, on the other even loops up 1.
## Returns its a (x) and z flag (y: 1 when true): the old y and the new y's wrap after going down; 1
## and nz on odd loops; the new y and whether it is $48 after going up.
func _func_b6a16() -> Vector2i:
	return _shake_tower(0x07, 0x01)


## .Func_b6a2e: the same every 16th loop down, every 4th up.
func _func_b6a2e() -> Vector2i:
	return _shake_tower(0x0F, 0x03)


func _shake_tower(down_mask: int, up_mask: int) -> Vector2i:
	var at: int = scene_obj(3) + SCENE_OBJ_Y
	var counter: int = sim.wGlobalCounter & down_mask
	if counter == 0:
		var old: int = rd(at)
		wr(at, old + 1)
		return Vector2i(old, 1 if rd(at) == 0 else 0)
	if (counter & up_mask) != 0:
		return Vector2i(counter & up_mask, 0)
	wr(at, rd(at) - 1)
	return Vector2i(rd(at), 1 if rd(at) == 0x48 else 0)
