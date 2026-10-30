class_name OverworldPrologue
extends OverworldGolfBuilding
## The prologue, the map's cutscene for EVENT_PROLOGUE that a new game starts with (WL3-056),
## translated: _InitPrologue (src/engine/overworld/cutscene/prologue/init.asm: the prologue's and the
## music box's maps and tiles, the text buffer, scene Wario), and Prologue (bank2b_2.asm), run by
## DoCutsceneFunc (PrologueFunc): its 39 steps by w2d013 (Wario falls from his plane by the forest, walks
## to the cave, finds the music box and is drawn into it, wakes in the temple, and the hidden figure's
## text plays, a page at a time on A), each counted in w2d014, the steps of a step by w2d890 and w2d891;
## the plane's four parts falling (Func_ae8bb); the prologue's scene objects (UpdatePrologueSceneObjects,
## Func_ac3fd, bank2b_1.asm), scene Wario, PrologueFade (_PrologueFade, bank21.asm: the palettes set
## up by w2d880 and faded through wPalConfig1 and wPalConfig2), and the text printer (PrintText and its
## callers, bank2b_1.asm). VBlank_PrologueEpilogue's RAM writes run after each loop; what it writes to
## VRAM, the palettes, and the LCD is recorded for drawing. The music and sound effects are not ported.

## w2d880 (OverworldLoop's W2D880) holds the fade PrologueFade sets up next.
const W2D890: int = 0xD890  # a step's step, and its counter
const W2D891: int = 0xD891
const W2D892: int = 0xD892  # Wario's bounce: its step, its counter, its movement on
const W2D893: int = 0xD893
const W2D894: int = 0xD894
const W2D8A0: int = 0xD8A0  # Func_ae8bb's step and counter (the plane's parts started)
const W2D8A1: int = 0xD8A1
const W2D8B0: int = 0xD8B0  # the cave's glint (wSceneObj1) by Func_ae2dd, and its counter
const W2D8B1: int = 0xD8B1
const W2D150: int = 0xD150  # Wario's flashing palettes (Func_ae523) and their counter
const W2D151: int = 0xD151
## The plane's four parts: each an action and its counter.
const W_PLANE_PART_1_ACTION: int = 0xD8A2
const W_SCENE_WARIO_ATTRIBUTES: int = 0xD143
# The text printer's state (wTextPrintInfo, $10 bytes) and its buffers.
const W_TEXT_PRINT_INFO: int = 0xDA80
const W_TEXT_DELAY_COUNTER: int = 0xDA80
const W_CUR_TEXT_LINE: int = 0xDA81
const W_CUR_TEXT_BUFFER_LINE: int = 0xDA82
const W_CUR_TEXT_LINE_POS: int = 0xDA83
const W_CUR_TEXT_BUFFER_PAGE: int = 0xDA84
const W_BG_MAP_TO_PRINT_TEXT: int = 0xDA85
const W_PENDING_CHAR_DEST: int = 0xDA88  # low byte first
const W_PENDING_CHAR_TILE: int = 0xDA8A
const W_PENDING_CHAR_ATTR: int = 0xDA8B
const W_TEXT: int = 0xDB00  # wTextLine1, then wTextLine2 to wTextLine4
const W_TEXT_LINE_2: int = 0xDB10
const W_CLEARED_TEXT_BUFFER: int = 0xDB80
const W_TEXT_BUFFER: int = 0xDC00
const TEXT_LINE_LENGTH: int = 16
## The temple charmap's no-character ('@'), space, and page end ('▼').
const CHAR_NONE: int = 0x7F
const CHAR_SPACE: int = 0x7E
const CHAR_PAGE_END: int = 0x5D
## PrintText's first character: BG map 0's (2, 14), or BG map 1's with wBGMapToPrintText.
const TEXT_START_BG_MAP_0: int = 0x99C2
const TEXT_START_BG_MAP_1: int = 0x9DC2
const TEXT_ATTRIBUTES: int = 0x09  # palette 1 from VRAM bank 1 (BG_BANK1)
const LANGUAGE_JAPANESE: int = 0

const PROLOGUE_BANK: int = 0x2B
const PROLOGUE_FADE_BANK: int = 0x21  # _PrologueFade's palettes (Pals_86xxx)
const PROLOGUE_MAPS_BANK: int = 0x2C
const PROLOGUE_ATTRMAP: int = 0x74C3
const PROLOGUE_TILEMAP: int = 0x730C
const PROLOGUE_GFX: int = 0x5780
const MUSIC_BOX_ATTRMAP: int = 0x7A5B
const MUSIC_BOX_TILEMAP: int = 0x7A03
const MUSIC_BOX_GFX: int = 0x4000
const TEXT_EN_HIDDEN_FIGURE: int = 0x77F9
const TEXT_JP_HIDDEN_FIGURE: int = 0x7675
const TEMPLE_TILEMAP: int = 0x4300
const TEMPLE_ATTRMAP: int = 0x4540
const TEMPLE_GFX: int = 0x4780
const FONT_GFX: Array = [0x7C, 0x5D5D]
const PALS_86A8D: int = 0x6A8D
const PALS_86A0D: int = 0x6A0D
const PALS_869CD: int = 0x69CD
const PALS_86A4D: int = 0x6A4D
const PALS_86ACD: int = 0x6ACD
const PALS_86AD5: int = 0x6AD5
const PALS_DB000: Array = [0x36, 0x7000]
const PALS_DB040: Array = [0x36, 0x7040]
## Func_ac9e9 and Func_ac9e4's pal configs (bank $2b): wTempPals1's 8 palettes to the BG, wTempOBPals'
## first to the OBJ.
const DATA_AC9F5: int = 0x49F5
const DATA_AC9FF: int = 0x49FF
# ApplyOWMovement's tables (bank $2b): Wario's bounce, and the plane's parts' falls.
const DATA_AED06: int = 0x6D06
const DATA_AED6D: int = 0x6D6D
const DATA_AEDBA: int = 0x6DBA
const DATA_AEE09: int = 0x6E09
## The y the plane's parts hit the ground at.
const PLANE_PART_GROUND_Y: int = 0x62
## .Func_ae4a9's and .Func_ae4fe's tables (bank $2b): the music box's fall (a y step a count), and its
## bounce (y steps, $80 after the last); and Func_ae523's palettes for Wario while he is drawn in.
const DATA_AE4D1: int = 0x64D1
const DATA_AE509: int = 0x6509
const DATA_AE54B: int = 0x654B
const MUSIC_BOX_GROUND_Y: int = 195

const SCENEWARIO_TURN_BACK_RIGHT: int = 0x06
const SCENEWARIO_NOD_ONCE: int = 0x0F
const SCENEWARIO_LOOK_AROUND: int = 0x10
const SCENEWARIO_LOOK_FORWARD: int = 0x12
const SCENEWARIO_LOOK_AROUND_THEN_TURN: int = 0x13
const SCENEWARIO_ON_FIRE: int = 0x15
const SCENEWARIO_CRASH_LAND_RIGHT: int = 0x16
const SCENEWARIO_CRASH_TUMBLE_END: int = 0x18
const SCENEWARIO_STUNNED_RIGHT: int = 0x19
const SCENEWARIO_LOOK_UP: int = 0x1A
const SCENEWARIO_LOOK_MUSIC_BOX: int = 0x1D
const SCENEWARIO_PICKUP_MUSIC_BOX: int = 0x1E
const SCENEWARIO_HOLD_MUSIC_BOX: int = 0x1F
const SCENEWARIO_SLEEP: int = 0x22
const SCENEWARIO_WAKE_UP: int = 0x23
const SCENEWARIO_SIT_STILL: int = 0x24
const SCENEWARIO_SIT_IDLE: int = 0x25
const SCENEWARIO_JUMP_AND_BOW: int = 0x26
const SCENEWARIO_SNAP_FINGERS: int = 0x27
const SCENEWARIO_TURN_BACK_TO_LEFT: int = 0x33

## The V-Blank function _InitPrologue sets (VBlank_PrologueEpilogue), numbered after the cutscenes'.
const VBLANK_PROLOGUE: int = 0x13

## The plane's parts (Func_ae924, Func_ae9ee, Func_aeb0d, Func_aec1f), each a scene object (and one it
## leads) through its actions: ["place", obj, y, x, state] (SetSceneObjCoordAndState); ["lead", obj, y,
## x, state, follower] (placed, and the follower on it in state $0f); ["clear", obj, y, x, state,
## cleared] (placed, and the cleared object's state 0); ["fall", obj, table, follower or 0]
## (ApplyOWMovement, the follower on it; at the ground y the follower's state $10 and the next action);
## ["land", obj, table] (ApplyOWMovement to its end, then the next); ["wait", loops]; ["state", obj,
## state]; ["stop", obj] (no action, the object's state 0). An action's first step clears its counter.
const PLANE_PARTS: Array = [
	[["place", 3, 46, 240, 0x06], ["fall", 3, DATA_AEE09, 0], ["land", 3, DATA_AEE09], ["wait", 0x08],
		["place", 3, 77, 224, 0x05], ["fall", 3, DATA_AEDBA, 0], ["land", 3, DATA_AEDBA], ["wait", 0x28],
		["place", 3, 62, 240, 0x04], ["fall", 3, DATA_AED6D, 0], ["land", 3, DATA_AED6D], ["wait", 0x08],
		["stop", 3]],
	[["clear", 4, 62, 240, 0x02, 1], ["fall", 4, DATA_AED6D, 1], ["land", 4, DATA_AED6D], ["wait", 0x04],
		["state", 4, 0x12], ["wait", 0x28], ["lead", 4, 46, 224, 0x08, 1], ["fall", 4, DATA_AEE09, 1],
		["land", 4, DATA_AEE09], ["wait", 0x08], ["lead", 4, 46, 244, 0x04, 1], ["fall", 4, DATA_AEE09, 0],
		["land", 4, DATA_AEE09], ["wait", 0x08], ["stop", 4]],
	[["lead", 5, 62, 224, 0x03, 2], ["fall", 5, DATA_AED6D, 2], ["land", 5, DATA_AED6D], ["wait", 0x08],
		["place", 5, 46, 240, 0x07], ["fall", 5, DATA_AEE09, 0], ["land", 5, DATA_AEE09], ["wait", 0x04],
		["state", 5, 0x13], ["wait", 0x28], ["place", 5, 77, 248, 0x05], ["fall", 5, DATA_AEDBA, 0],
		["land", 5, DATA_AEDBA], ["wait", 0x08], ["stop", 5]],
	[["place", 9, 77, 240, 0x07], ["fall", 9, DATA_AEDBA, 0], ["land", 9, DATA_AEDBA], ["wait", 0x04],
		["state", 9, 0x13], ["wait", 0x28], ["lead", 9, 62, 240, 0x08, 8], ["fall", 9, DATA_AED6D, 8],
		["land", 9, DATA_AED6D], ["wait", 0x08], ["stop", 9]],
]

## Func_ac409's scene object states (bank $2b) by state: [frameset, its bank, the OAM table, its bank,
## with the scroll, the state set once the animation ends or -1]. 0 does nothing.
const PROLOGUE_OBJ_STATES: Array = [
	[],
	[0x76CA, 0x01, 0x75C3, 0x01, false, -1],  # Func_ac056: the text's arrow (Title Gfx)
	[0x6741, 0x57, 0x644A, 0x57, true, -1], [0x6748, 0x57, 0x644A, 0x57, true, -1],
	[0x674B, 0x57, 0x644A, 0x57, true, -1], [0x6774, 0x57, 0x644A, 0x57, true, -1],
	[0x677D, 0x57, 0x644A, 0x57, true, -1], [0x6780, 0x57, 0x644A, 0x57, true, -1],
	[0x6793, 0x57, 0x644A, 0x57, true, -1], [0x67A3, 0x57, 0x644A, 0x57, true, -1],
	[0x67A6, 0x57, 0x644A, 0x57, true, -1],  # $0a (a sound at its end, not ported)
	[0x67B7, 0x57, 0x644A, 0x57, true, -1],
	[0x67C4, 0x57, 0x644A, 0x57, true, -1],  # $0c (a sound at its end, not ported)
	[0x67ED, 0x57, 0x644A, 0x57, true, -1],
	[0x67B7, 0x57, 0x644A, 0x57, true, 0x00], [0x6783, 0x57, 0x644A, 0x57, true, -1],
	[0x678A, 0x57, 0x644A, 0x57, true, 0x00], [0x6796, 0x57, 0x644A, 0x57, true, 0x00],
	[0x67F0, 0x57, 0x644A, 0x57, true, -1], [0x67F5, 0x57, 0x644A, 0x57, true, -1],
	[0x6D0B, 0x2A, 0x6B5C, 0x2A, true, 0x00],  # $14: Frameset_aad0b, OAM_aab5c (Overworld OAM 1)
	[0x67FA, 0x57, 0x644A, 0x57, true, 0x16], [0x6801, 0x57, 0x644A, 0x57, true, -1],
	[0x680A, 0x57, 0x644A, 0x57, true, -1],
]


# --- _InitPrologue ---

## _InitPrologue: the scene's RAM and objects cleared, VBlank_PrologueEpilogue, the prologue's maps on
## BG map 1 and its tiles (PrologueBackgroundGfx to v0Tiles2; FontGfx, then PrologueGfx over it, to
## v1Tiles0), the music box's maps on BG map 0 and tiles (to v0Tiles1), the hidden figure's text by
## wLanguage to wTextBuffer, the cleared text buffer, the temporary palettes black, scene Wario at (96,
## 96) with no state and his graphics group unset, and BG map 1 flipped in.
func _init_prologue() -> void:
	clear_general_scene_ram()
	clear_scene_objs_ram()
	vblank_func = VBLANK_PROLOGUE
	decompress_to_vram(PROLOGUE_MAPS_BANK, PROLOGUE_ATTRMAP, 1, 0x9C00)
	decompress_to_vram(PROLOGUE_MAPS_BANK, PROLOGUE_TILEMAP, 0, 0x9C00)
	_load_far_tiles([PROLOGUE_MAPS_BANK, PROLOGUE_BACKGROUND_GFX], 0)
	decompress_to_vram(int(FONT_GFX[0]), int(FONT_GFX[1]), 1, 0x8000)
	decompress_to_vram(PROLOGUE_MAPS_BANK, PROLOGUE_GFX, 1, 0x8000)
	decompress_to_vram(PROLOGUE_MAPS_BANK, MUSIC_BOX_ATTRMAP, 1, 0x9800)
	decompress_to_vram(PROLOGUE_MAPS_BANK, MUSIC_BOX_TILEMAP, 0, 0x9800)
	record_copy_to_vram(0, 0x8800, MUSIC_BOX_GFX, 0x300, PROLOGUE_MAPS_BANK)  # CopyFarBytes_Long
	var text: int = TEXT_JP_HIDDEN_FIGURE if r0(W_LANGUAGE) == LANGUAGE_JAPANESE else TEXT_EN_HIDDEN_FIGURE
	decompress_to_wram(PROLOGUE_MAPS_BANK, text, W_TEXT_BUFFER)
	fill(W_CLEARED_TEXT_BUFFER, 8 * TEXT_LINE_LENGTH, CHAR_NONE)  # FillClearedTextBuffer
	fill(W_TEMP_PALS_1, 0x80, 0)
	w2(W_SCENE_WARIO, 96)
	w2(W_SCENE_WARIO_X_COORD, 96)
	w2(W_SCENE_WARIO_STATE_GROUP, SCENEWARIO_GROUP_NONE)
	set_scene_wario_state(SCENEWARIO_NONE)
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)


## VBlank_PrologueEpilogue's function, run after the loop (V-Blank): the scroll, with wHDMABank its DMA
## (wHDMA, to wHDMADestVRAMBank's VRAM), the pending character (its tile, then its attributes in VRAM 1;
## a destination whose low byte is 0 is not written), ApplyPalConfig1 and 2, rLCDC's bits in
## wLCDCFlagsToFlip flipped, the OAM; its RAM writes: wHDMABank, the destination's low byte, the
## configs' registers, and wLCDCFlagsToFlip cleared once applied.
func vblank_prologue_epilogue() -> void:
	var vram_bank: int = 0
	if r2(W_HDMA_BANK) != 0:
		vram_bank = r2(W_HDMA_DEST_VRAM_BANK)
		record_gdma(vram_bank, W_HDMA, r2(W_HDMA_BANK))
		w2(W_HDMA_BANK, 0)
	var low: int = r2(W_PENDING_CHAR_DEST)
	if low != 0:
		w2(W_PENDING_CHAR_DEST, 0)
		var destination: int = (r2(W_PENDING_CHAR_DEST + 1) << 8) | low
		vram_writes.append(["bytes", vram_bank, destination, PackedByteArray([r2(W_PENDING_CHAR_TILE)])])
		vram_writes.append(["bytes", 1, destination, PackedByteArray([r2(W_PENDING_CHAR_ATTR)])])
	for config: int in [W_PAL_CONFIG_1, W_PAL_CONFIG_2]:
		if r2(config) != 0:
			record_pal_config(config)
			w2(config, 0)
	if r2(W_LCDC_FLAGS_TO_FLIP) != 0:
		register_writes.append(["lcdc_flip", r2(W_LCDC_FLAGS_TO_FLIP)])
		w2(W_LCDC_FLAGS_TO_FLIP, 0)


# --- Prologue ---

## PrologueFunc, Prologue: the step (.PlayCutscene), then the prologue's scene objects, scene Wario, and
## the plane's last two objects (Func_ac3fd).
func _prologue_func() -> void:
	_play_prologue()
	for number: int in [0, 1, 2, 3, 4, 5]:  # UpdatePrologueSceneObjects: wCurSceneObj, then 1 to 5
		_update_prologue_scene_obj(number)
	update_scene_wario()
	for number: int in [8, 9]:  # Func_ac3fd
		_update_prologue_scene_obj(number)


## Prologue.PlayCutscene by w2d013.
func _play_prologue() -> void:
	match r2(W2D013):
		0x00:
			_prologue_next()
		0x01:
			_prologue_delay(60)  # .Wait60
		0x02:
			_set_prologue_fade(1)  # .SetFadeInFromBlack
		0x03, 0x08, 0x0A, 0x11:
			prologue_fade()
		0x04:
			_wario_fall_from_plane()
		0x05:  # .ScrollRight40Pixels
			sim.wSCX = byte(sim.wSCX + 1)
			if sim.wSCX == 40:
				_prologue_next()
		0x06:
			_wario_walk_to_cave_entrance()
		0x07, 0x10:
			_set_prologue_fade(0)  # .SetFadeToBlack
		0x09:
			_prepare_cave_scene_1()
		0x0B:
			_wario_enter_cave()
		0x0C:
			_show_music_box_close_up()
		0x0D:
			_func_ae1de()
		0x0E:
			_prepare_cave_scene_2()
		0x0F:
			_wario_sucked_into_music_box()
		0x12:  # .LoadTempleTilemap
			_configure_temple_hdma(0, TEMPLE_TILEMAP, 0x18, 18 * 2 - 1)
		0x13:  # .LoadTempleAttrmap
			_configure_temple_hdma(1, TEMPLE_ATTRMAP, 0x18, 18 * 2 - 1)
		0x14:  # .LoadTempleGfx
			_configure_temple_hdma(0, TEMPLE_GFX, 0x10, 0x80 - 1)
		0x15:
			_prepare_temple_scene()
		0x16:  # .Func_ae15b: a fade step every 8 loops
			if (r2(W2D014) & 0x07) == 0:
				prologue_fade()
		0x17:
			_func_ae55c()
		0x18:
			_set_prologue_fade(2)  # .Func_ae164
		0x19:  # .Func_ae169: a fade step every 8 loops, every other from the 8th
			var mask: int = 0x07 if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 0x08 else 0x01
			if (r2(W2D014) & mask) == 0:
				prologue_fade()
		0x1A:
			_func_ae641()
		0x1B:
			_init_text_printing()
		0x1C:
			_func_aca9e()
		0x1D:
			_prologue_delay(30)  # .Wait30
		0x1E:
			_load_cur_text_page_buffer_page()
		0x1F:
			_func_acacd()
		0x20:
			_func_acae7()
		0x21:  # .Func_ae181: the next page, and on the third Wario looks around
			_func_acaf3()
			if r2(W_CUR_TEXT_BUFFER_PAGE) == 0x02:
				set_scene_wario_state(SCENEWARIO_LOOK_AROUND)
		0x22:  # .Func_ae196
			set_scene_wario_state(SCENEWARIO_NOD_ONCE)
			_prologue_next()
		0x23:  # .Func_ae19e: once he looks back, the text's arrow shown
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_LOOK_BACK:
				set_scene_obj_state(1, 0x01)
				_prologue_next()
		0x24:  # .Func_ae1af: A: the arrow hidden, the text box cleared
			if (sim.wJoypadPressed & PAD_A) != 0:
				set_scene_obj_state(1, 0x00)
				_clear_textbox_at(6 * TILEMAP_WIDTH, 8 - 1)
				_prologue_next()
		0x25:
			_func_ae668()
		0x26:  # Prologue_Finish
			sim.wSubState = byte(sim.wSubState + 1)
		_:
			_note("Prologue step $%02x (past its jumptable)" % r2(W2D013))


## Prologue_Next (also Func_aca6d): w2d014 cleared, the next step.
func _prologue_next() -> void:
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## Prologue_Delay: the next step once w2d014 reaches `loops`.
func _prologue_delay(loops: int) -> void:
	if r2(W2D014) >= loops:
		_prologue_next()


## .SetFadeInFromBlack, .SetFadeToBlack, .Func_ae009: the fade PrologueFade sets up next (w2d880), the
## configs' steps cleared, the next step.
func _set_prologue_fade(fade: int) -> void:
	w2(W2D880, fade)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)
	_prologue_next()


## .PrepareCaveScene1: the scroll at (0, 112), Wario at (208, 240) with no state, the music box
## (wSceneObj3, .Func_ae067), the glint (wSceneObj1, wSceneObj2) at (187, 120), the glint's step and
## state cleared, the cave's fade (6) next (the music, not ported).
func _prepare_cave_scene_1() -> void:
	sim.wSCY = 112
	sim.wSCX = 0
	w2(W_SCENE_WARIO, 208)
	w2(W_SCENE_WARIO_X_COORD, 240)
	set_scene_wario_state(SCENEWARIO_NONE)
	_place_music_box()
	for number: int in [1, 2]:
		wr(scene_obj(number) + SCENE_OBJ_Y, 187)
		wr(scene_obj(number) + SCENE_OBJ_X, 120)
	w2(W2D8B0, 0)
	set_scene_obj_state(1, 0x00)
	_set_prologue_fade(6)


## .Func_ae067: the music box (wSceneObj3) at (195, 120) in state 9.
func _place_music_box() -> void:
	wr(scene_obj(3) + SCENE_OBJ_Y, 195)
	wr(scene_obj(3) + SCENE_OBJ_X, 120)
	set_scene_obj_state(3, 0x09)


## .ShowMusicBoxCloseUp: the scroll cleared, BG map 0 (the close-up) flipped in, wSceneObj8 at (80, 80)
## in state $0d, the music box hidden, OBJ palette 0 from Pals_86a8d, then .Func_ae0ab with Pals_86a0d.
func _show_music_box_close_up() -> void:
	sim.wSCY = 0
	sim.wSCX = 0
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
	wr(scene_obj(8) + SCENE_OBJ_Y, 80)
	wr(scene_obj(8) + SCENE_OBJ_X, 80)
	set_scene_obj_state(8, 0x0D)
	set_scene_obj_state(3, 0x00)
	copy_rom(PROLOGUE_FADE_BANK, PALS_86A8D, W_TEMP_OB_PALS, 8)
	_func_ae0ab(PALS_86A0D)


## .Func_ae0ab: `pals` (bank $21) to wTempPals1, wPalConfig1 for its 8 palettes and wPalConfig2 for
## wTempOBPals' first (applied at the V-Blank), the next step.
func _func_ae0ab(pals: int) -> void:
	copy_rom(PROLOGUE_FADE_BANK, pals, W_TEMP_PALS_1, 8 * 8)
	copy_rom(PROLOGUE_BANK, DATA_AC9F5, W_PAL_CONFIG_1, 5)  # Func_ac9e9
	copy_rom(PROLOGUE_BANK, DATA_AC9FF, W_PAL_CONFIG_2, 5)  # Func_ac9e4
	_prologue_next()


## .PrepareCaveScene2: the scroll at (0, 112), BG map 1 (the cave) flipped back, Wario holding the music
## box, the music box placed again, the glint in state $0e, wSceneObj8 hidden, wTempPals2's first palette
## to wTempOBPals, then .Func_ae0ab with Pals_869cd.
func _prepare_cave_scene_2() -> void:
	sim.wSCY = 112
	sim.wSCX = 0
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
	set_scene_wario_state(SCENEWARIO_HOLD_MUSIC_BOX)
	_place_music_box()
	set_scene_obj_state(1, 0x0E)
	set_scene_obj_state(8, 0x00)
	for offset: int in 8:
		w0(W_TEMP_OB_PALS + offset, r0(W_TEMP_PALS_2 + offset))
	_func_ae0ab(PALS_869CD)


## .LoadTempleTilemap, .LoadTempleAttrmap, .LoadTempleGfx (.configure_hdma_transfer): wHDMA from
## (bank $2c, `source`) to VRAM bank `vram_bank` at (`destination_hi` + $80) << 8, `length` blocks less
## one; the next step.
func _configure_temple_hdma(vram_bank: int, source: int, destination_hi: int, length: int) -> void:
	w2(W_HDMA_DEST_VRAM_BANK, vram_bank)
	w2(W_HDMA_BANK, PROLOGUE_MAPS_BANK)
	w2(W_HDMA, source >> 8)
	w2(W_HDMA + 1, source & 0xFF)
	w2(W_HDMA + 2, destination_hi)
	w2(W_HDMA + 3, 0)
	w2(W_HDMA + 4, length)
	_prologue_next()


## .PrepareTempleScene: the scroll cleared, BG map 0 (the temple) flipped in, Wario asleep at (96, 64)
## (a snore, not ported), the temple's fade (5) next.
func _prepare_temple_scene() -> void:
	sim.wSCY = 0
	sim.wSCX = 0
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
	w2(W_SCENE_WARIO, 96)
	w2(W_SCENE_WARIO_X_COORD, 64)
	set_scene_wario_state(SCENEWARIO_SLEEP)
	_set_prologue_fade(5)


# --- PrologueFade (_PrologueFade, bank $21) ---

## PrologueFade, _PrologueFade: its first loop sets the fade up by w2d880 (the palettes shown to
## wTempBGPals and wTempOBPals, the targets to wTempPals1 and wTempPals2) and the configs from
## wTempBGPals (8 BG palettes) and wTempOBPals (8 OBJ palettes); then each loop a step on the OBJ and
## the BG palettes (Func_851d1, Func_851bc), and after $20 BG steps the configs' steps cleared and the
## next step.
func prologue_fade() -> void:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) >= 1:
		fade_ob_pal_config_slowly()
		if fade_bg_pal_config_slowly():
			return
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
		w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)
		_prologue_next()
		return
	var fade: int = r2(W2D880)
	if fade <= 6:
		_copy_pals_to_bg_and_ob_pals()
	match fade:
		0:  # to black
			fill(W_TEMP_PALS_1, 0x80, 0)
		1, 6:  # the forest
			copy_rom(PROLOGUE_FADE_BANK, PALS_869CD, W_TEMP_PALS_1, 8 * 8)
			copy_rom(PROLOGUE_FADE_BANK, PALS_86A8D, W_TEMP_PALS_2, 8 * 8)
			if fade == 6:
				copy_rom(PROLOGUE_FADE_BANK, PALS_86ACD, W_TEMP_PALS_2, 8)
		2:  # the temple
			copy_rom(PROLOGUE_FADE_BANK, PALS_86A4D, W_TEMP_PALS_1, 8 * 8)
			copy_rom(PROLOGUE_FADE_BANK, PALS_86A8D, W_TEMP_PALS_2, 8 * 8)
			copy_rom(PROLOGUE_FADE_BANK, PALS_86AD5, W_TEMP_PALS_2, 8)
		3:
			fill(W_TEMP_PALS_1, 6 * 8, 0)
			fill(W_TEMP_PALS_2 + 8, 7 * 8, 0)
		4:
			copy_rom(int(PALS_DB000[0]), int(PALS_DB000[1]), W_TEMP_PALS_1, 8 * 8)
			copy_rom(int(PALS_DB040[0]), int(PALS_DB040[1]), W_TEMP_PALS_2 + 3 * 8, 5 * 8)
		5:  # the temple's last two BG palettes
			copy_rom(PROLOGUE_FADE_BANK, PALS_86A4D + 6 * 8, W_TEMP_PALS_1 + 6 * 8, 2 * 8)
			copy_rom(PROLOGUE_FADE_BANK, PALS_86A8D, W_TEMP_PALS_2, 8 * 8)
			copy_rom(PROLOGUE_FADE_BANK, PALS_86AD5, W_TEMP_PALS_2, 8)
	w2(W_PAL_CONFIG_1 + 3, W_TEMP_BG_PALS >> 8)  # .set_pal_configs: the source
	w2(W_PAL_CONFIG_1 + 4, W_TEMP_BG_PALS & 0xFF)
	w2(W_PAL_CONFIG_1_INDEX, 0x80)  # BGPI_AUTOINC | palette 0
	w2(W_PAL_CONFIG_1_NUMBER, 8)
	w2(W_PAL_CONFIG_2 + 3, W_TEMP_OB_PALS >> 8)
	w2(W_PAL_CONFIG_2 + 4, W_TEMP_OB_PALS & 0xFF)
	w2(W_PAL_CONFIG_2 + 1, 0x80)  # OBPI_AUTOINC | palette 0
	w2(W_PAL_CONFIG_2 + 2, 8)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)


## _PrologueFade.CopyPalsToBGAndOBPals: wTempPals1 to wTempBGPals, wTempPals2 to wTempOBPals.
func _copy_pals_to_bg_and_ob_pals() -> void:
	for offset: int in 0x80:
		w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))


# --- a step's steps (w2d890, counted in w2d891) ---

## Func_ae1ce: w2d891 cleared, the next of the step's steps.
func _func_ae1ce() -> void:
	w2(W2D891, 0)
	w2(W2D890, r2(W2D890) + 1)


## Func_ae1c9: on once w2d891 reaches `loops`.
func _func_ae1c9(loops: int) -> void:
	if r2(W2D891) >= loops:
		_func_ae1ce()


## Func_ae1c2: on once scene Wario is in `state`.
func _func_ae1c2(state: int) -> void:
	if r2(W_SCENE_WARIO_STATE) == state:
		_func_ae1ce()


## Func_ae1d5: the step's steps done: the next step.
func _func_ae1d5() -> void:
	w2(W2D890, 0)
	w2(W2D891, 0)
	_prologue_next()


## w2d891 counted; the step's step.
func _next_substep() -> int:
	w2(W2D891, r2(W2D891) + 1)
	return r2(W2D890)


## Scene Wario in `state`, then on.
func _wario_state_then_on(state: int) -> void:
	set_scene_wario_state(state)
	_func_ae1ce()


## ApplySceneWarioMovementRight (or Left) until his x (its low bit off) is `x`, which it is set to;
## then `state` and on. True when he arrived.
func _walk_wario_to(x: int, right: bool, state: int, set_x: bool = true) -> bool:
	var reached: int = apply_scene_wario_movement_right() if right else apply_scene_wario_movement_left()
	if reached != x:
		return false
	if set_x:
		w2(W_SCENE_WARIO_X_COORD, reached)
	_wario_state_then_on(state)
	return true


## An emote (wCurSceneObj in state $11) over Wario's head ((y - 24, x + 16)), then on (a sound, not
## ported).
func _show_emote() -> void:
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 24)
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD) + 16)
	set_scene_obj_state(0, 0x11)
	_func_ae1ce()


## Prologue_WarioFallFromPlane: the plane's parts (Func_ae8bb), then: 74 loops, Wario thrown from the
## plane on fire at (60, 240), his bounces (.DoBounce) until done, 60 loops, he turns, looks back, 38
## loops, looks around and stands; 46 loops on, the next step.
func _wario_fall_from_plane() -> void:
	_func_ae8bb()
	match _next_substep():
		0x00:
			_func_ae1c9(74)
		0x01:  # .ShowWarioFall (a sound, not ported)
			w2(W_SCENE_WARIO, 60)
			w2(W_SCENE_WARIO_X_COORD, 240)
			set_scene_wario_state(SCENEWARIO_ON_FIRE)
			w2(W2D894, 0)
			w2(W2D892, 0)
			_func_ae1ce()
		0x02:  # .WarioBounce
			_wario_bounce()
			if r2(W2D892) == 0x80:
				_func_ae1ce()
		0x03:
			_func_ae1c9(60)
		0x04:
			_wario_state_then_on(SCENEWARIO_TURN_BACK_RIGHT)
		0x05:
			_func_ae1c2(SCENEWARIO_LOOK_BACK)
		0x06:
			_func_ae1c9(38)
		0x07:
			_wario_state_then_on(SCENEWARIO_LOOK_AROUND_THEN_TURN)
		0x08:
			_func_ae1c2(SCENEWARIO_IDLE_RIGHT)
		0x09:
			_func_ae1c9(46)
		0x0A:
			_func_ae1d5()
		_:
			_note("Prologue_WarioFallFromPlane step $%02x (past its jumptable)" % r2(W2D890))


## .DoBounce: while w2d894 is set, on 3 of every 4 loops Wario moves by Data_aed06 (to its end, which
## clears w2d894); then by w2d892: the throw (w2d894 set), a crash at y 96 (stunned, the dust), 4 loops, the
## tumble's end, a crash landing at y 96 (the dust), 4 loops, another landing, until stunned, $3e loops,
## and he stands (a sound, not ported); then $80 (done).
func _wario_bounce() -> void:
	if r2(W2D894) != 0 and (r2(W2D891) & 0x03) != 0:
		if apply_ow_movement(W_SCENE_WARIO, DATA_AED06, PROLOGUE_BANK):
			w2(W2D894, 0)
	var wario_y: int = r2(W_SCENE_WARIO)
	match r2(W2D892):
		0x00:
			w2(W2D894, 0x01)
			_next_bounce_step()
		0x01:
			if wario_y == 96:
				set_scene_wario_state(SCENEWARIO_STUNNED_RIGHT)
				_bounce_dust()
		0x02, 0x05:
			w2(W2D893, r2(W2D893) + 1)
			if r2(W2D893) >= 0x04:
				_next_bounce_step()
		0x03:
			set_scene_wario_state(SCENEWARIO_CRASH_TUMBLE_END)
			_next_bounce_step()
		0x04:
			if wario_y == 96:
				set_scene_wario_state(SCENEWARIO_CRASH_LAND_RIGHT)
				_bounce_dust()
		0x06:
			if wario_y == 96:
				set_scene_wario_state(SCENEWARIO_CRASH_LAND_RIGHT)
				_next_bounce_step()
		0x07:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_STUNNED_RIGHT:
				_next_bounce_step()
		0x08:
			w2(W2D893, r2(W2D893) + 1)
			if r2(W2D893) >= 0x3E:
				set_scene_wario_state(SCENEWARIO_IDLE_RIGHT)
				_next_bounce_step()
		0x09:
			w2(W2D892, 0x80)


## .asm_ae77f: the dust (wCurSceneObj in state $10) at Wario, then the next bounce step.
func _bounce_dust() -> void:
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO))
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD))
	set_scene_obj_state(0, 0x10)
	_next_bounce_step()


## .asm_ae768: the next bounce step, its counter cleared.
func _next_bounce_step() -> void:
	w2(W2D892, r2(W2D892) + 1)
	w2(W2D893, 0)


## Func_ae8bb: each of the plane's parts' actions, then every 8 loops the next part started (w2d8a0
## counting to 4).
func _func_ae8bb() -> void:
	for part: int in PLANE_PARTS.size():
		_plane_part(part)
	w2(W2D8A1, r2(W2D8A1) + 1)
	var started: int = r2(W2D8A0)
	if started >= PLANE_PARTS.size() or r2(W2D8A1) < 0x08:
		return
	_next_plane_action(started)
	w2(W2D8A1, 0)
	w2(W2D8A0, started + 1)


## Func_ae924, Func_ae9ee, Func_aeb0d, Func_aec1f: the part's counter counted, then its action (none at
## 0; see PLANE_PARTS).
func _plane_part(part: int) -> void:
	var action_at: int = W_PLANE_PART_1_ACTION + part * 2
	w2(action_at + 1, r2(action_at + 1) + 1)
	var action: int = r2(action_at)
	if action == 0:
		return
	var actions: Array = PLANE_PARTS[part]
	if action > actions.size():
		_note("the plane's part %d action $%02x (past its jumptable)" % [part + 1, action])
		return
	var entry: Array = actions[action - 1]
	match String(entry[0]):
		"place", "lead", "clear":
			var obj: int = scene_obj(int(entry[1]))
			wr(obj + SCENE_OBJ_Y, int(entry[2]))
			wr(obj + SCENE_OBJ_X, int(entry[3]))
			set_scene_obj_state(int(entry[1]), int(entry[4]))
			if String(entry[0]) == "lead":
				_follow(int(entry[1]), int(entry[5]))
				set_scene_obj_state(int(entry[5]), 0x0F)
			elif String(entry[0]) == "clear":
				set_scene_obj_state(int(entry[5]), 0x00)
			_next_plane_action(part)
		"fall":
			apply_ow_movement(scene_obj(int(entry[1])), int(entry[2]), PROLOGUE_BANK)
			if int(entry[3]) != 0:
				_follow(int(entry[1]), int(entry[3]))
			if rd(scene_obj(int(entry[1])) + SCENE_OBJ_Y) == PLANE_PART_GROUND_Y:
				if int(entry[3]) != 0:
					set_scene_obj_state(int(entry[3]), 0x10)
				w2(action_at, action + 1)  # (a sound, not ported)
		"land":
			if apply_ow_movement(scene_obj(int(entry[1])), int(entry[2]), PROLOGUE_BANK):
				_next_plane_action(part)  # (a sound, not ported)
		"wait":
			if r2(action_at + 1) >= int(entry[1]):
				_next_plane_action(part)
		"state":
			set_scene_obj_state(int(entry[1]), int(entry[2]))
			_next_plane_action(part)
		"stop":
			w2(action_at, 0)
			set_scene_obj_state(int(entry[1]), 0x00)


## Func_ae915 on a part: its counter cleared, its next action.
func _next_plane_action(part: int) -> void:
	var action_at: int = W_PLANE_PART_1_ACTION + part * 2
	w2(action_at + 1, 0)
	w2(action_at, r2(action_at) + 1)


## The follower at its leader's place.
func _follow(leader: int, follower: int) -> void:
	wr(scene_obj(follower) + SCENE_OBJ_Y, rd(scene_obj(leader) + SCENE_OBJ_Y))
	wr(scene_obj(follower) + SCENE_OBJ_X, rd(scene_obj(leader) + SCENE_OBJ_X))


## Prologue_WarioWalkToCaveEntrance: 60 loops, Wario walks right to x 120, 60 loops, looks up, stands,
## an emote, its end, 40 loops, he walks on to x 208 and is gone; 40 loops on, the next step.
func _wario_walk_to_cave_entrance() -> void:
	match _next_substep():
		0x00, 0x03:
			_func_ae1c9(60)
		0x01, 0x09:
			_wario_state_then_on(SCENEWARIO_WALK_RIGHT)
		0x02:
			_walk_wario_to(120, true, SCENEWARIO_IDLE_RIGHT)
		0x04:
			_wario_state_then_on(SCENEWARIO_LOOK_UP)
		0x05:
			_func_ae1c2(SCENEWARIO_IDLE_RIGHT)
		0x06:
			_show_emote()
		0x07:
			if rd(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE) == 0:
				_func_ae1ce()
		0x08, 0x0B:
			_func_ae1c9(40)
		0x0A:
			_walk_wario_to(208, true, SCENEWARIO_NONE)
		0x0C:
			_func_ae1d5()
		_:
			_note("Prologue_WarioWalkToCaveEntrance step $%02x (past its jumptable)" % r2(W2D890))


## Prologue_WarioEnterCave: the glint (Func_ae2dd), then: Wario walks right (at x 50 the glint starts) to
## x 64, waits for the glint, an emote after $16 loops, its end, 26 loops, walks on to x 102, the glint
## again at $14 loops and on after $3c, looks at the music box until holding it; 60 loops on, the next
## step.
func _wario_enter_cave() -> void:
	_func_ae2dd()
	match _next_substep():
		0x00, 0x06:
			_wario_state_then_on(SCENEWARIO_WALK_RIGHT)
		0x01:  # .WarioMoveRightTo64
			var x: int = apply_scene_wario_movement_right()
			if x == 50:
				w2(W2D8B0, 0x01)
			elif x == 64:
				w2(W_SCENE_WARIO_X_COORD, x)
				_wario_state_then_on(SCENEWARIO_IDLE_RIGHT)
		0x02:
			if r2(W2D8B0) == 0:
				_func_ae1ce()
		0x03:
			if r2(W2D891) >= 0x16:
				_show_emote()
		0x04:
			if rd(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE) == 0:
				_func_ae1ce()
		0x05:
			_func_ae1c9(26)
		0x07:
			_walk_wario_to(102, true, SCENEWARIO_IDLE_RIGHT)
		0x08:  # .Func_ae2b8
			if r2(W2D891) == 0x14:
				w2(W2D8B0, 0x03)
			elif r2(W2D891) >= 0x3C:
				_func_ae1ce()
		0x09:
			_wario_state_then_on(SCENEWARIO_LOOK_MUSIC_BOX)
		0x0A:
			_func_ae1c2(SCENEWARIO_HOLD_MUSIC_BOX)
		0x0B:
			_func_ae1c9(60)
		0x0C:
			_func_ae1d5()
		_:
			_note("Prologue_WarioEnterCave step $%02x (past its jumptable)" % r2(W2D890))


## Func_ae2dd: the glint (wSceneObj1) by w2d8b0: none (0), shown (1, 3: state $0e), once (2: back to 0 when
## it ends), or again and again (4: when it ends, 5: $14 loops on, 3).
func _func_ae2dd() -> void:
	match r2(W2D8B0):
		0x01, 0x03:  # Func_ae2ed
			set_scene_obj_state(1, 0x0E)
			_next_glint_step()
		0x02:  # Func_ae303
			if rd(scene_obj(1) + SCENE_OBJ_STATE) == 0:
				w2(W2D8B0, 0)
				w2(W2D8B1, 0)
		0x04:  # Func_ae2fc
			if rd(scene_obj(1) + SCENE_OBJ_STATE) == 0:
				_next_glint_step()
		0x05:  # Func_ae30e
			w2(W2D8B1, r2(W2D8B1) + 1)
			if r2(W2D8B1) >= 0x14:
				w2(W2D8B0, r2(W2D8B0) - 2)


## Func_ae2f5: w2d8b1 cleared, w2d8b0 on.
func _next_glint_step() -> void:
	w2(W2D8B1, 0)
	w2(W2D8B0, r2(W2D8B0) + 1)


## Func_ae1de: 20 loops, wSceneObj4 at (56, 56) in state $0e (a sound, not ported), 10 loops,
## wSceneObj5 at (48, 120) in state $0e, 90 loops, the next step.
func _func_ae1de() -> void:
	match _next_substep():
		0x00:
			_func_ae1c9(20)
		0x01:
			_set_obj(4, 56, 56, 0x0E)
			_func_ae1ce()
		0x02:
			_func_ae1c9(10)
		0x03:
			_set_obj(5, 48, 120, 0x0E)
			_func_ae1ce()
		0x04:
			_func_ae1c9(90)
		0x05:
			_func_ae1d5()
		_:
			_note("Func_ae1de step $%02x (past its jumptable)" % r2(W2D890))


func _set_obj(number: int, y: int, x: int, state: int) -> void:
	wr(scene_obj(number) + SCENE_OBJ_Y, y)
	wr(scene_obj(number) + SCENE_OBJ_X, x)
	set_scene_obj_state(number, state)


## Prologue_WarioSuckedIntoMusicBox: Wario's flashing (Func_ae523), then by w2d890: the glint's end,
## $14 loops (the music stops, not ported), 30 loops, Wario picks the music box up and it rises, he hops
## back; it rises to y 165 (the light at 180); 120 loops; the light gone, a burst over him, its end (his
## flashing stops), another burst over his head with OBJ palette 0 white, until it ends Wario is drawn in;
## 60 loops; the burst falls and lands; the music box drops and bounces; 120 loops; the next step.
func _wario_sucked_into_music_box() -> void:
	_func_ae523()
	var counter: int = 0
	match _next_substep():
		0x00:
			if rd(scene_obj(1) + SCENE_OBJ_STATE) == 0:
				_func_ae1ce()
		0x01:
			if r2(W2D891) >= 0x14:
				_func_ae1ce()
		0x02:
			_func_ae1c9(30)
		0x03:
			_wario_state_then_on(SCENEWARIO_PICKUP_MUSIC_BOX)
		0x04:  # .Func_ae37c
			if r2(W2D891) < 0x08:
				set_scene_obj_state(3, 0x0A)
				_func_ae1ce()
		0x05:  # .WarioShortHopBack
			counter = r2(W2D891)
			if counter == 0x01 or counter == 0x05:
				w2(W_SCENE_WARIO, r2(W_SCENE_WARIO) + (-1 if counter == 0x01 else 1))
				w2(W_SCENE_WARIO_X_COORD, r2(W_SCENE_WARIO_X_COORD) - 1)
			elif counter >= 0x30:
				_func_ae1ce()
		0x06:  # .MusicBoxRise
			if (r2(W2D891) & 0x07) == 0:
				var y: int = _move_obj(3, SCENE_OBJ_Y, -1)
				wr(scene_obj(2) + SCENE_OBJ_Y, y - 8)
				if y == 180:
					set_scene_obj_state(2, 0x0C)
					w2(W2D150, 0x01)
				elif y == 165:
					_func_ae1ce()
		0x07:
			_func_ae1c9(120)
		0x08:  # .Func_ae3d8
			set_scene_obj_state(2, 0x00)
			_func_ae1ce()
		0x09:  # .Func_ae3e2
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 8)
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD))
			set_scene_obj_state(0, 0x0E)
			_func_ae1ce()
		0x0A:  # .Func_ae3fa
			if rd(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE) == 0:
				w2(W2D150, 0x80)
				_func_ae1ce()
		0x0B:  # .Func_ae407: OBJ palette 0 all (28, 28, 28), applied by wPalConfig2
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 16)
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD) + 2)
			set_scene_obj_state(0, 0x15)
			for colour: int in 4:
				w0(W_TEMP_OB_PALS + colour * 2, 0x9C)
				w0(W_TEMP_OB_PALS + colour * 2 + 1, 0x73)
			copy_rom(PROLOGUE_BANK, DATA_AC9FF, W_PAL_CONFIG_2, 5)
			_func_ae1ce()
		0x0C:  # .Func_ae435
			if rd(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE) == 0x16:
				set_scene_wario_state(SCENEWARIO_NONE)
				_func_ae1ce()
		0x0D:
			_func_ae1c9(60)
		0x0E:
			_func_ae447()
		0x0F:  # .Func_ae476
			set_scene_obj_state(3, 0x09)
			set_scene_obj_state(0, 0x00)
			_func_ae1ce()
		0x10:
			_func_ae488()
		0x11:
			_func_ae1c9(40)
		0x12:
			_func_ae4a9()
		0x13:
			_func_ae4e5()
		0x14:
			_func_ae1c9(120)
		0x15:
			_func_ae1d5()
		_:
			_note("Prologue_WarioSuckedIntoMusicBox step $%02x (past its jumptable)" % r2(W2D890))


## A scene object's coordinate moved by `step`; returns the new one.
func _move_obj(number: int, coord: int, step: int) -> int:
	var at: int = scene_obj(number) + coord
	wr(at, rd(at) + step)
	return rd(at)


## .Func_ae447: the burst (wCurSceneObj): from y 181 down, every 4 loops up a line (and right on the
## loops with bit 2); above it, up 2 and right 1 a loop: at 168 its state $17, at 156 on.
func _func_ae447() -> void:
	var y: int = rd(W_CUR_SCENE_OBJ + SCENE_OBJ_Y)
	if y >= 181:
		var counter: int = r2(W2D891)
		if (counter & 0x03) != 0:
			return
		if (counter & 0x04) != 0:
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, rd(W_CUR_SCENE_OBJ + SCENE_OBJ_X) + 1)
		wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, y - 1)
		return
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, rd(W_CUR_SCENE_OBJ + SCENE_OBJ_X) + 1)
	y = (y - 2) & 0xFF
	wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, y)
	if y == 168:
		set_scene_obj_state(0, 0x17)
	elif y == 156:
		_func_ae1ce()


## .Func_ae488: on even counts the music box shakes: right at 2, left 2 at 4, right and on after.
func _func_ae488() -> void:
	var counter: int = r2(W2D891)
	if (counter & 0x01) != 0:
		return
	var half: int = counter >> 1
	var x_at: int = scene_obj(3) + SCENE_OBJ_X
	if half == 1:
		wr(x_at, rd(x_at) + 1)
	elif half == 2:
		wr(x_at, rd(x_at) - 2)
	else:
		wr(x_at, rd(x_at) + 1)
		_func_ae1ce()


## .Func_ae4a9: the music box falls by .data_ae4d1 (its count held at $10 from $14) to y 195 (a bump,
## not ported), then on.
func _func_ae4a9() -> void:
	if r2(W2D891) >= 0x14:
		w2(W2D891, 0x10)
	var y: int = (rd(scene_obj(3) + SCENE_OBJ_Y) + rb(PROLOGUE_BANK, DATA_AE4D1 + r2(W2D891))) & 0xFF
	wr(scene_obj(3) + SCENE_OBJ_Y, y)
	if y >= MUSIC_BOX_GROUND_Y:
		wr(scene_obj(3) + SCENE_OBJ_Y, MUSIC_BOX_GROUND_Y)
		_func_ae1ce()


## .Func_ae4e5: the music box's bounce by .data_ae509 (a bump at y 195, not ported): a step of 0 waits;
## after a step whose next byte is $80, on.
func _func_ae4e5() -> void:
	var at: int = DATA_AE509 + r2(W2D891)
	var step: int = rb(PROLOGUE_BANK, at)
	if step == 0:
		return
	_move_obj(3, SCENE_OBJ_Y, step)
	if rb(PROLOGUE_BANK, at + 1) == 0x80:
		_func_ae1ce()


## Func_ae523: Wario's palettes while he is drawn in: from w2d150 1 every other loop the next of
## .data_ae54b (1 to 8 round); at $80 back to 0, and the flashing stopped.
func _func_ae523() -> void:
	var step: int = r2(W2D150)
	if step == 0:
		return
	if step == 0x80:
		w2(W_SCENE_WARIO_ATTRIBUTES, 0)
		w2(W2D150, 0)
		return
	w2(W2D151, r2(W2D151) + 1)
	if r2(W2D151) < 0x02:
		return
	w2(W2D151, 0)
	w2(W2D150, step + 1)
	if step + 1 >= 0x09:
		w2(W2D150, 0x01)
	w2(W_SCENE_WARIO_ATTRIBUTES, rb(PROLOGUE_BANK, DATA_AE54B + step))


## Func_ae55c (the temple): once Wario's sleep animation ends, after $4b loops he wakes (a sound after
## $14, not ported) and sits; after 5 loops a bubble (wCurSceneObj in state $14) by him, after $8c he
## sits still, after $10 stands (a sound, not ported), 60 loops, walks right to x $50 and stands, after
## $1e turns back, looks back; after $1e the temple's music (not ported), after $1e he looks around; 30
## loops on, the next step.
func _func_ae55c() -> void:
	var counter: int = 0
	match _next_substep():
		0x00:
			if r2(W2D14E) == 0xFF:
				_func_ae1ce()
		0x01:
			if r2(W2D891) >= 0x4B:
				_wario_state_then_on(SCENEWARIO_WAKE_UP)
		0x02:
			if r2(W2D891) >= 0x14:
				_func_ae1ce()
		0x03:
			_func_ae1c2(SCENEWARIO_SIT_IDLE)
		0x04:
			if r2(W2D891) >= 0x05:
				wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 1)
				wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD) + 9)
				set_scene_obj_state(0, 0x14)
				_func_ae1ce()
		0x05:
			if r2(W2D891) >= 0x8C:
				_wario_state_then_on(SCENEWARIO_SIT_STILL)
		0x06:
			if r2(W2D891) >= 0x10:
				_wario_state_then_on(SCENEWARIO_IDLE_RIGHT)
		0x07:
			_func_ae1c9(60)
		0x08:
			_wario_state_then_on(SCENEWARIO_WALK_RIGHT)
		0x09:
			_walk_wario_to(0x50, true, SCENEWARIO_IDLE_RIGHT)
		0x0A:
			if r2(W2D891) >= 0x1E:
				_wario_state_then_on(SCENEWARIO_TURN_BACK_RIGHT)
		0x0B:
			_func_ae1c2(SCENEWARIO_LOOK_BACK)
		0x0C:
			counter = r2(W2D891)
			if counter >= 0x1E:
				_func_ae1ce()
		0x0D:
			if r2(W2D891) >= 0x1E:
				_wario_state_then_on(SCENEWARIO_LOOK_AROUND)
		0x0E:
			_func_ae1c9(30)
		0x0F:
			_func_ae1d5()
		_:
			_note("Func_ae55c step $%02x (past its jumptable)" % r2(W2D890))


## Func_ae641: once Wario looks forward he jumps and bows, until he looks back; then the next step.
func _func_ae641() -> void:
	match _next_substep():
		0x00:
			_func_ae1c2(SCENEWARIO_LOOK_FORWARD)
		0x01:
			set_scene_wario_state(SCENEWARIO_JUMP_AND_BOW)
			w2(W_SCENE_WARIO_UNK7, 0)
			_func_ae1ce()
		0x02:
			_func_ae1c2(SCENEWARIO_LOOK_BACK)
		0x03:
			_func_ae1d5()
		_:
			_note("Func_ae641 step $%02x (past its jumptable)" % r2(W2D890))


## Func_ae668: Wario snaps his fingers (a sound at frame $0f, not ported), looks back, 30 loops, turns
## left, stands; after 4 loops walks left until x $f0 and is gone; 30 loops on, the next step.
func _func_ae668() -> void:
	match _next_substep():
		0x00:
			_wario_state_then_on(SCENEWARIO_SNAP_FINGERS)
		0x01:
			if r2(W_SCENE_WARIO_FRAME) == 0x0F:
				_func_ae1ce()
		0x02:
			_func_ae1c2(SCENEWARIO_LOOK_BACK)
		0x03, 0x08:
			_func_ae1c9(30)
		0x04:
			_wario_state_then_on(SCENEWARIO_TURN_BACK_TO_LEFT)
		0x05:
			_func_ae1c2(SCENEWARIO_IDLE_LEFT)
		0x06:
			if r2(W2D891) >= 0x04:
				_wario_state_then_on(SCENEWARIO_WALK_LEFT)
		0x07:
			_walk_wario_to(0xF0, false, SCENEWARIO_NONE, false)
		0x09:
			_func_ae1d5()
		_:
			_note("Func_ae668 step $%02x (past its jumptable)" % r2(W2D890))


# --- the prologue's scene objects (Func_ac409, bank2b_1.asm) ---

## Func_ac409 on scene object `number` (0: wCurSceneObj) by its state (PROLOGUE_OBJ_STATES): its
## animation, and once it ends a new state (run at once), else its sprite.
func _update_prologue_scene_obj(number: int) -> void:
	var obj: int = scene_obj(number)
	var state: int = rd(obj + SCENE_OBJ_STATE)
	if state == 0:
		return
	if state >= PROLOGUE_OBJ_STATES.size():
		_note("the prologue's scene object state $%02x (past its jumptable)" % state)
		return
	var entry: Array = PROLOGUE_OBJ_STATES[state]
	update_ow_animation(obj + SCENE_OBJ_DURATION, int(entry[0]), int(entry[1]))
	if int(entry[5]) >= 0 and r2(W_OW_ANIMATION_FINISHED) == 0xFF:  # SetObjStateIfAnimationIsFinished
		wr(obj + SCENE_OBJ_DURATION, 0)
		wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
		wr(obj + SCENE_OBJ_STATE, int(entry[5]))
		_update_prologue_scene_obj(number)
		return
	if bool(entry[4]):
		load_ow_sprite_with_scroll(obj, int(entry[2]), int(entry[3]))
	else:
		load_ow_sprite(obj, int(entry[2]), int(entry[3]))


# --- the text printer (bank2b_1.asm) ---

## InitTextPrinting: wText cleared ('@'), the header's line (wTextBuffer's first) to wTextLine1, the
## printer's state cleared, the text's arrow (wSceneObj1) at ($8e, $98) with no state, the next step.
func _init_text_printing() -> void:
	fill(W_TEXT, 4 * TEXT_LINE_LENGTH, CHAR_NONE)  # ClearText
	for offset: int in TEXT_LINE_LENGTH:
		w2(W_TEXT + offset, r2(W_TEXT_BUFFER + offset))
	fill(W_TEXT_PRINT_INFO, 0x10, 0)
	wr(scene_obj(1) + SCENE_OBJ_Y, 0x8E)
	wr(scene_obj(1) + SCENE_OBJ_X, 0x98)
	set_scene_obj_state(1, 0x00)
	_prologue_next()


## Func_aca9e: the page printed with its header (PrintTextWithHeader); when done, the next page and step.
func _func_aca9e() -> void:
	_print_text(true)
	if r2(W_CUR_TEXT_LINE) == 0x80:
		w2(W_CUR_TEXT_BUFFER_PAGE, r2(W_CUR_TEXT_BUFFER_PAGE) + 1)
		_prologue_next()


## LoadCurTextPageBufferPage: the page's three lines (wTextBuffer + page * $40) to wTextLine2, the
## printer at its first line, the next step.
func _load_cur_text_page_buffer_page() -> void:
	var page: int = _text_page(r2(W_CUR_TEXT_BUFFER_PAGE))
	for offset: int in 3 * TEXT_LINE_LENGTH:
		w2(W_TEXT_LINE_2 + offset, rd(page + offset))
	w2(W_CUR_TEXT_LINE, 0)
	_prologue_next()


## Func_acacd: on the first page at once, otherwise on A (the arrow hidden): the text box but its header
## cleared, the next step.
func _func_acacd() -> void:
	if r2(W_CUR_TEXT_BUFFER_PAGE) != 0x01:
		if (sim.wJoypadPressed & PAD_A) == 0:
			return
		set_scene_obj_state(1, 0x00)
	_clear_textbox_at(7 * TILEMAP_WIDTH, 6 - 1)
	_prologue_next()


## Func_acae7: the page printed without the header (PrintTextWithoutHeader); when done, the next step.
func _func_acae7() -> void:
	_print_text(false)
	if r2(W_CUR_TEXT_LINE) == 0x80:
		_prologue_next()


## Func_acaf3: the next page; unless it starts with '▼' (the end), the arrow shown and three steps back
## (to load and print it).
func _func_acaf3() -> void:
	var page: int = r2(W_CUR_TEXT_BUFFER_PAGE) + 1
	w2(W_CUR_TEXT_BUFFER_PAGE, page)
	if rd(_text_page(page)) == CHAR_PAGE_END:
		_prologue_next()
		return
	set_scene_obj_state(1, 0x01)
	w2(W2D013, r2(W2D013) - 3)
	w2(W2D014, 0)


## A text page's address: wTextBuffer + the page's nibbles swapped, times 4 (its number times $40 below
## 16).
func _text_page(page: int) -> int:
	return W_TEXT_BUFFER + swap(page & 0xFF) * 4


## ClearTextbox (`low` 6 rows down, 8 blocks) and ClearTextboxExceptHeader (7 rows, 6 blocks)
## (ClearTextboxAtCoord): wHDMA from wClearedTextBuffer to BG map 0 (or 1 with wBGMapToPrintText) row
## `low` / 32 + 8, wHDMABank this bank, VRAM 0, and no character pending.
func _clear_textbox_at(low: int, blocks: int) -> void:
	w2(W_HDMA, W_CLEARED_TEXT_BUFFER >> 8)
	w2(W_HDMA + 1, W_CLEARED_TEXT_BUFFER & 0xFF)
	w2(W_HDMA + 2, 0x1D if r2(W_BG_MAP_TO_PRINT_TEXT) != 0 else 0x19)  # (BG map + $100) high - $80
	w2(W_HDMA + 3, low)
	w2(W_HDMA + 4, blocks)
	w2(W_HDMA_BANK, PROLOGUE_BANK)
	w2(W_HDMA_DEST_VRAM_BANK, 0)
	w2(W_PENDING_CHAR_DEST, 0)


## PrintTextWithHeader (or PrintTextWithoutHeader): the delay counted; by wCurTextLine: 0 waits 10
## loops for the next line, 1 to 4 print lines 1 to 4 (without the header 1 to 3 print lines 2 to 4),
## past them $80 (done).
func _print_text(header: bool) -> void:
	w2(W_TEXT_DELAY_COUNTER, r2(W_TEXT_DELAY_COUNTER) + 1)
	var line: int = r2(W_CUR_TEXT_LINE)
	if line == 0:
		if r2(W_TEXT_DELAY_COUNTER) >= 10:  # DelayTextThenGoToNextLine
			_go_to_next_line()
		return
	var lines: int = 4 if header else 3
	if line > lines:
		w2(W_CUR_TEXT_LINE, 0x80)
		return
	_print_text_line(line - 1 if header else line)


## GoToNextLine: the line's position and the delay cleared, the next line.
func _go_to_next_line() -> void:
	w2(W_CUR_TEXT_LINE_POS, 0)
	w2(W_TEXT_DELAY_COUNTER, 0)
	w2(W_CUR_TEXT_LINE, r2(W_CUR_TEXT_LINE) + 1)


## PrintText: with no character pending and the delay reached (4 loops, 2 with A or down held), wText's
## line `line` at wCurTextLinePos: no-characters ('@') skipped to the next character or the line's
## end; a character pending (tile, attributes, destination from BG map 0's (2, 14) a row a line, the
## first line a tile left) for the V-Blank (a sound unless a space, not ported); at the line's end, the
## next line.
func _print_text_line(line: int) -> void:
	if r2(W_PENDING_CHAR_DEST) != 0:
		return
	var delay: int = 2 if (sim.wJoypadDown & (PAD_A | PAD_DOWN)) != 0 else 4
	if r2(W_TEXT_DELAY_COUNTER) < delay:
		return
	w2(W_TEXT_DELAY_COUNTER, 0)
	w2(W_CUR_TEXT_BUFFER_LINE, line)
	while true:
		var position: int = r2(W_CUR_TEXT_LINE_POS)
		var char: int = r2(W_TEXT + line * TEXT_LINE_LENGTH + position)
		if char != CHAR_NONE:
			w2(W_PENDING_CHAR_TILE, char)
			w2(W_PENDING_CHAR_ATTR, TEXT_ATTRIBUTES)
			var destination: int = TEXT_START_BG_MAP_1 if r2(W_BG_MAP_TO_PRINT_TEXT) != 0 else TEXT_START_BG_MAP_0
			if line == 0:
				destination = (destination & 0xFF00) | ((destination - 1) & 0xFF)  # dec l
			destination += line * 2 * TEXT_LINE_LENGTH + position
			w2(W_PENDING_CHAR_DEST, destination & 0xFF)
			w2(W_PENDING_CHAR_DEST + 1, destination >> 8)
			w2(W_CUR_TEXT_LINE_POS, position + 1)
			if position + 1 == TEXT_LINE_LENGTH:
				_go_to_next_line()
			return
		w2(W_CUR_TEXT_LINE_POS, position + 1)
		if position + 1 == TEXT_LINE_LENGTH:
			_go_to_next_line()
			return
