class_name OverworldEpilogue
extends OverworldTemple
## The epilogue after the hidden figure's fight (OverworldStateTable's sub-states $24 and $26), translated
## from src/engine/overworld/bank2b_2.asm: _InitEpilogue (the epilogue's tiles, maps, and text, the
## prologue's V-Blank function) and Func_af13c, its loop: 32 steps by w2d013, each counted in w2d014, the
## steps of a step by w2d890 and w2d891. A Spearhead, a Doughnuteer, and a Hammer-bot (wSceneObj9) are each
## turned into another form as a star falls on them and the screen flashes white (Func_15848a, bank $56);
## the crowd's BG and the clouds come in, the old man walks in with the scroll, his text plays a page at a
## time on A with his mouth, his thanks wait for A, a burst carries him up and off, and in the prologue's
## forest Wario lands, picks him up, and walks off; the fade to black ends it. Its scene objects are
## Func_ac0b6's (bank2b_1.asm), with the prologue's text printer and PrologueFade, and Func_84e43's slow
## fade (bank $21). The music and sound effects are not ported.

# --- RAM (WRAMX bank 2) ---
const W_TEMPLE_ROCK_5_ACTION: int = 0xD8C0  # the old man's bounce's step
const W_TEMPLE_ROCK_5_COUNTER: int = 0xD8C1  # its counter
const W_TEMPLE_ROCK_5_SIZE: int = 0xD8C2  # his ApplyOWMovement on (also wPalFade2Colour4GreenSign)
## Func_15848a's falling star (wSceneObj1) and its four sparkles' actions, each with its counter after it,
## named by the labels the union gives them: W_TEMPLE_MUSIC_BOX_1 (OverworldTemple's, $d8a2) and these.
const W_TEMPLE_MUSIC_BOX_2_COUNTER: int = 0xD8A5
const W_TEMPLE_MUSIC_BOX_4: int = 0xD8A8
const W_TEMPLE_MUSIC_BOX_5_COUNTER: int = 0xD8AB

# --- ROM ---
const EPILOGUE_BANK: int = 0x57  # its graphics, maps, text, and objects' framesets ("Credits OAM")
const EPILOGUE_GFX: int = 0x5180
const EPILOGUE_STAR_GFX: int = 0x4800
const OLD_MAN_1_GFX: int = 0x4900
const OLD_MAN_2_GFX: int = 0x4000
const EPILOGUE_CROWD_TILEMAP: int = 0x4D00
const EPILOGUE_CROWD_ATTRMAP: int = 0x4F40
const EPILOGUE_TRANSFORMATION_TILEMAP: int = 0x5F9B
const EPILOGUE_TRANSFORMATION_ATTRMAP: int = 0x5FF8
const TEXT_JP_OLD_MAN_THANK_YOU: int = 0x606B
const TEXT_EN_OLD_MAN_THANK_YOU: int = 0x6225
const OAM_15E97D: int = 0x697D
const SPEARHEAD_GFX: Array = [0x68, 0x4000]
const HAMMER_BOT_GFX: Array = [0x69, 0x514C]
const DOUGHNUTEER_GFX: Array = [0x6A, 0x45B3]
const PALS_86ADD: int = 0x6ADD  # bank $21
const PALS_86B1D: int = 0x6B1D
const DATA_ACA04: int = 0x4A04  # bank $2b: wPalConfig2 for wTempPals2's 8 OBJ palettes
const PALS_AF35E: int = 0x735E  # bank $2b: OBJ palettes 4 to 6 (Func_af13c.Pals_af35e)
## Func_15848a's sparkles' falls (bank $56): y steps by their counter, $80 after the last.
const FUNC_15848A_BANK: int = 0x56
const DATA_158659: int = 0x4659  # .data_1
const DATA_15867D: int = 0x467D  # .data_2
## FontGfx's tiles from $80 ($800 bytes on, VRAM 1's v1Tiles1), the $50 _InitEpilogue keeps in wAttrmap.
const FONT_TILES_1: int = 0x800
const TILE_SIZE: int = 0x10

const SCENEWARIO_CARRY_WALK: int = 0x09
const SCENEWARIO_CARRY_IDLE: int = 0x0A
const SCENEWARIO_PICKUP: int = 0x0B
const SCENEWARIO_LOOK_TURN_RIGHT: int = 0x14
const SCENEWARIO_CRASH_LAND_LEFT: int = 0x1B
const SCENEWARIO_STUNNED_LEFT: int = 0x1C
const SCENEWARIO_CARRY_SNAP_FINGERS: int = 0x21

## Func_ac0b6's scene object states (bank $2b) by state: [frameset, its bank, the OAM table, its bank, with
## the scroll, the state set once the animation ends or -1]. 0 does nothing; 1 is the text's arrow
## (Func_ac056); $18 to $1a are the Spearhead, Doughnuteer, and Hammer-bot (Frameset_ in "Object Framesets",
## OAM_ in banks $60 and $61); the rest are Frameset_15xxxx with OAM_15e97d.
const EPILOGUE_OBJ_STATES: Array = [
	[],
	[0x76CA, 0x01, 0x75C3, 0x01, false, -1],  # Func_ac056
	[0x6D91, 0x57, 0x697D, 0x57, true, -1], [0x6D94, 0x57, 0x697D, 0x57, true, -1],  # $02, $03
	[0x6D97, 0x57, 0x697D, 0x57, true, -1], [0x6D9A, 0x57, 0x697D, 0x57, true, -1],  # $04, $05
	[0x6D9D, 0x57, 0x697D, 0x57, true, 0x0A], [0x6DB3, 0x57, 0x697D, 0x57, true, -1],  # $06, $07
	[0x6DA6, 0x57, 0x697D, 0x57, true, -1],  # $08 (.PlaySFXEvery30Frames)
	[0x6DC0, 0x57, 0x697D, 0x57, true, -1], [0x6DC3, 0x57, 0x697D, 0x57, true, -1],  # $09, $0a
	[0x6DC6, 0x57, 0x697D, 0x57, true, 0x0A], [0x6DE9, 0x57, 0x697D, 0x57, true, 0x0B],  # $0b, $0c
	[0x6DF2, 0x57, 0x697D, 0x57, true, 0x0A], [0x6E0F, 0x57, 0x697D, 0x57, true, 0x0A],  # $0d, $0e
	[0x6E1E, 0x57, 0x697D, 0x57, true, 0x17], [0x6E3B, 0x57, 0x697D, 0x57, true, 0x0A],  # $0f, $10
	[0x6E44, 0x57, 0x697D, 0x57, true, -1], [0x6E57, 0x57, 0x697D, 0x57, true, -1],  # $11, $12
	[0x6E64, 0x57, 0x697D, 0x57, true, -1],  # $13 (.Func_ac1c3)
	[0x6E67, 0x57, 0x697D, 0x57, true, -1], [0x6E70, 0x57, 0x697D, 0x57, true, -1],  # $14, $15
	[0x6E79, 0x57, 0x697D, 0x57, true, -1],  # $16 (.Func_ac1e9)
	[0x6E82, 0x57, 0x697D, 0x57, true, -1],  # $17 (.Func_ac207)
	[0x41D2, 0x1A, 0x407B, 0x60, true, -1],  # $18 Frameset_681d2, OAM_18007b
	[0x4B12, 0x1A, 0x422F, 0x61, true, -1],  # $19 Frameset_68b12, OAM_18422f
	[0x4562, 0x1A, 0x4EA7, 0x60, true, -1],  # $1a Frameset_68562, OAM_180ea7
	[0x6E87, 0x57, 0x697D, 0x57, true, -1], [0x6E8A, 0x57, 0x697D, 0x57, true, -1],  # $1b, $1c
]
## Func_15848a's sparkles, each [its action's address, its scene object, its actions]: ["star"] (on once
## wSceneObj1 is shown), ["wait", loops], ["spawn", y, x] (by wSceneObj1, state $15), ["fall", table, x
## step on odd counts] (state $14 at count 3; at the table's $80 hidden, and the action 0 when it is the
## last, else the next), ["again"] (back to spawning while wSceneObj1 is shown, else 0).
const EPILOGUE_SPARKLES: Array = [
	[W_TEMPLE_MUSIC_BOX_1, 5, [["star"], ["spawn", -0x08, -0x03], ["fall", DATA_158659, 0]]],  # .Func_1584da
	[W_TEMPLE_MUSIC_BOX_2_COUNTER, 6, [["star"], ["wait", 0x0A], ["spawn", -0x08, 0x03], ["fall", DATA_158659, 0], ["again"]]],
	[W_TEMPLE_MUSIC_BOX_4, 7, [["star"], ["spawn", -0x06, -0x04], ["fall", DATA_15867D, -1]]],  # .Func_15858c
	[W_TEMPLE_MUSIC_BOX_5_COUNTER, 8, [["star"], ["wait", 0x08], ["spawn", -0x10, 0x06], ["fall", DATA_15867D, 1], ["again"]]],
]


# --- _InitEpilogue ---

## _InitEpilogue: the LCD off, BG map 0 filled, the virtual OAM cleared (the music stopped, not ported),
## the scroll cleared, VBlank_PrologueEpilogue, the general scene RAM and the scene objects cleared, the
## temporary palettes black, the epilogue's and the font's tiles, v1Tiles1's first $50 tiles (FontGfx's
## from $80) kept in wAttrmap, the star's, Spearhead's, Hammer-bot's, and Doughnuteer's tiles, the
## transformation's maps on BG map 0 and the prologue's on BG map 1, the cleared text buffer, the old
## man's text by the language, the steps and the configs' steps cleared, the LCD on with the window from
## $9c00 (wCollectionRow's bits, cleared with the scene RAM, flipped), the next sub-state.
func init_epilogue() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()  # (the music stopped, not ported)
	sim.wSCX = 0
	sim.wSCY = 0
	vblank_func = VBLANK_PROLOGUE  # VBlank_PrologueEpilogue
	clear_general_scene_ram()
	clear_scene_objs_ram()
	fill(W_TEMP_PALS_1, 8 * 8, 0)
	fill(W_TEMP_PALS_2, 8 * 8, 0)
	decompress_to_vram(EPILOGUE_BANK, EPILOGUE_GFX, 0, 0x8000)  # decompress_tiles0
	decompress_to_vram(int(FONT_GFX[0]), int(FONT_GFX[1]), 1, 0x8000)  # decompress_tiles1 FontGfx
	var font: PackedByteArray = decompress(int(FONT_GFX[0]), int(FONT_GFX[1]))  # VRAM 1 read back
	for offset: int in 0x50 * TILE_SIZE:
		wr(W_ATTRMAP + offset, font[FONT_TILES_1 + offset] if FONT_TILES_1 + offset < font.size() else 0)
	record_copy_to_vram(1, 0x8800 + 0x40 * TILE_SIZE, EPILOGUE_STAR_GFX, 0x100, EPILOGUE_BANK)  # CopyFarBytes
	decompress_to_vram(int(SPEARHEAD_GFX[0]), int(SPEARHEAD_GFX[1]), 1, 0x8000)
	decompress_to_vram(int(HAMMER_BOT_GFX[0]), int(HAMMER_BOT_GFX[1]), 1, 0x8000 + 0x40 * TILE_SIZE)
	decompress_to_vram(int(DOUGHNUTEER_GFX[0]), int(DOUGHNUTEER_GFX[1]), 1, 0x8800)
	decompress_to_vram(EPILOGUE_BANK, EPILOGUE_TRANSFORMATION_ATTRMAP, 1, 0x9800)
	decompress_to_vram(EPILOGUE_BANK, EPILOGUE_TRANSFORMATION_TILEMAP, 0, 0x9800)
	decompress_to_vram(PROLOGUE_MAPS_BANK, PROLOGUE_ATTRMAP, 1, 0x9C00)
	decompress_to_vram(PROLOGUE_MAPS_BANK, PROLOGUE_TILEMAP, 0, 0x9C00)
	fill(W_CLEARED_TEXT_BUFFER, 8 * TEXT_LINE_LENGTH, CHAR_NONE)  # FillClearedTextBuffer
	var text: int = TEXT_JP_OLD_MAN_THANK_YOU if r0(W_LANGUAGE) == LANGUAGE_JAPANESE \
			else TEXT_EN_OLD_MAN_THANK_YOU
	decompress_to_wram(EPILOGUE_BANK, text, W_TEXT_BUFFER)
	w2(W2D013, 0)
	w2(W2D014, 0)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)
	var lcdc: int = LCDC_TEMPLE
	if r2(W_LCDC_FLAGS_TO_FLIP) != 0:  # wCollectionRow
		lcdc ^= r2(W_LCDC_FLAGS_TO_FLIP)
	set_lcdc(lcdc)
	w2(W_LCDC_FLAGS_TO_FLIP, 0)
	sim.wSubState = byte(sim.wSubState + 1)


# --- Func_af13c ---

## Func_af13c: the step (.Func_af14c), the text's arrow and wCurSceneObj (Func_ac074), scene Wario, the
## scene objects 5 to 13 (Func_ac080), the virtual OAM's unused entries cleared.
func update_epilogue() -> void:
	_epilogue_step()
	for number: int in [0, 1]:  # Func_ac074
		_update_epilogue_scene_obj(number)
	update_scene_wario()
	for number: int in [5, 6, 7, 8, 9, 10, 11, 12, 13]:  # Func_ac080
		_update_epilogue_scene_obj(number)
	clear_unused_virtual_oam()


## Func_af13c.Func_af14c: the clouds (.Func_af8bc), w2d014 counted, then by w2d013.
func _epilogue_step() -> void:
	_func_af8bc()
	w2(W2D014, r2(W2D014) + 1)
	match r2(W2D013):
		0x00:
			_prologue_next()  # Func_af135
		0x01:  # .Func_af197
			_prologue_delay(0x3C)  # Func_af130
		0x02:  # .Func_af19c: the Spearhead (wSceneObj9) at ($60, $50) in state $18, the palettes to fade to
			_set_obj(9, 0x60, 0x50, 0x18)
			_func_af1bd()
			_func_af1db()
			_epilogue_configs_next()
		0x03, 0x0D, 0x1B:
			_func_ac9ca()
		0x04:
			_func_af7af()
		0x05, 0x17, 0x1D:  # .Func_af2d0: to black
			_set_prologue_fade(0)
		0x06, 0x18:
			prologue_fade()
		0x07:  # .Func_af1e7
			_epilogue_hdma(0, EPILOGUE_BANK, OLD_MAN_1_GFX, 0x08, 0x40 - 1)
		0x08:  # .Func_af207
			_epilogue_hdma(1, EPILOGUE_BANK, OLD_MAN_2_GFX, 0x00, 0x80 - 1)
		0x09:  # .Func_af215
			_epilogue_hdma(0, EPILOGUE_BANK, EPILOGUE_CROWD_TILEMAP, 0x18, 18 * 2 - 1)
		0x0A:  # .Func_af222
			_epilogue_hdma(1, EPILOGUE_BANK, EPILOGUE_CROWD_ATTRMAP, 0x18, 18 * 2 - 1)
		0x0B:  # .Func_af230: the font's tiles back from wAttrmap (wHDMABank OldMan1Gfx's, not read)
			_epilogue_hdma(1, EPILOGUE_BANK, W_ATTRMAP, 0x08, 0x50 - 1)
		0x0C:
			_func_af23e()
		0x0E:
			_func_af741()
		0x0F:
			_init_text_printing()
		0x10:
			_func_aca9e()
		0x11:  # .Func_af2bc
			_prologue_delay(0x1E)
		0x12:
			_load_cur_text_page_buffer_page()
		0x13:
			_func_acacd()
		0x14:  # .Func_af2c1
			_print_text(false)  # PrintTextWithoutHeader
			_func_af376()
			if r2(W_CUR_TEXT_LINE) == 0x80:
				_prologue_next()
		0x15:
			_func_acaf3()
		0x16:
			_func_af670()
		0x19:  # .Func_af2df
			_epilogue_hdma(0, PROLOGUE_MAPS_BANK, PROLOGUE_BACKGROUND_GFX, 0x10, 0x80 - 1)
		0x1A:
			_func_af2f2()
		0x1C:
			_func_af436()
		0x1E:  # .Func_af34a
			if (r2(W2D014) & 0x03) == 0:
				prologue_fade()
		0x1F:  # .Func_af353: the next sub-state $3c loops on (w2d013 kept)
			if r2(W2D014) >= 0x3C:
				sim.wSubState = byte(sim.wSubState + 1)
		var step:
			_note("Func_af13c step $%02x (past its jumptable)" % step)


## The configs' steps cleared (for the next fade), the next step (Func_af135).
func _epilogue_configs_next() -> void:
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)
	_prologue_next()


## .Func_af1e7 to .Func_af230, .Func_af2df (.asm_af1f2, .asm_af1f7): wHDMA from (`rom_bank`, `source`)
## to VRAM bank `vram_bank` at (`destination_hi` + $80) << 8, `length` blocks less one; the next step.
func _epilogue_hdma(vram_bank: int, rom_bank: int, source: int, destination_hi: int, length: int) -> void:
	w2(W_HDMA_DEST_VRAM_BANK, vram_bank)
	w2(W_HDMA_BANK, rom_bank)
	w2(W_HDMA, source >> 8)
	w2(W_HDMA + 1, source & 0xFF)
	w2(W_HDMA + 2, destination_hi)
	w2(W_HDMA + 3, 0)
	w2(W_HDMA + 4, length)
	_prologue_next()


## .Func_af1bd: the palettes shown (Func_aca09), the epilogue's to fade to: Pals_86add to wTempPals1,
## Pals_86b1d to wTempPals2.
func _func_af1bd() -> void:
	_func_aca09()
	copy_rom(PROLOGUE_FADE_BANK, PALS_86ADD, W_TEMP_PALS_1, 8 * 8)
	copy_rom(PROLOGUE_FADE_BANK, PALS_86B1D, W_TEMP_PALS_2, 8 * 8)


## .Func_af1db: .Pals_af35e to wTempPals2's palettes 4 to 6.
func _func_af1db() -> void:
	copy_rom(PROLOGUE_BANK, PALS_AF35E, W_TEMP_PALS_2 + 4 * 8, 3 * 8)


## Func_aca09: wTempPals2 to wTempOBPals and wTempPals1 to wTempBGPals (the palettes a fade starts from).
func _func_aca09() -> void:
	for offset: int in 8 * 8:
		w0(W_TEMP_OB_PALS + offset, r0(W_TEMP_PALS_2 + offset))
		w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))


## Func_aca25: wTempPals2 white; its count of 4 palettes is taken as 32 colours, so all 8 are.
func _func_aca25() -> void:
	for colour: int in 4 * 8:
		w0(W_TEMP_PALS_2 + colour * 2, 0xFF)  # PALRGB_WHITE
		w0(W_TEMP_PALS_2 + colour * 2 + 1, 0x7F)


## Func_ac9ca: Func_84e43's fade; once over (its steps 0), the next step.
func _func_ac9ca() -> void:
	_func_84e43()
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) == 0:
		_prologue_next()


## Func_84e43 (bank $21): its first loop wPalConfig1 for the 8 BG palettes from wTempBGPals and
## wPalConfig2 for the 8 OBJ palettes from wTempOBPals (toward wTempPals1 and wTempPals2); then each loop
## a slow step on each (Func_851d1, Func_851bc), and after $20 BG steps the configs' steps cleared.
func _func_84e43() -> void:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 1:
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)
		_set_pal_config(W_PAL_CONFIG_1_INDEX, W_TEMP_BG_PALS, BGPI_AUTOINC, 8)
		_set_pal_config(W_PAL_CONFIG_2_INDEX, W_TEMP_OB_PALS, OBPI_PALETTE_0, 8)
		return
	fade_ob_pal_config_slowly()
	if fade_bg_pal_config_slowly():
		return
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)


## .Func_af23e: the scroll's x 160 (BG map 0's right half: the crowd), scene Wario at ($60, $5c)
## idle left with his graphics group unset, the clouds (wSceneObj10 to 13 in states $1b and $1c), the
## epilogue's palettes to fade to, the configs' and the sub-steps cleared, the next step. (Func_af01f, which
## sets the same up with the LCD off, is unreferenced: not ported.)
func _func_af23e() -> void:
	sim.wSCX = SCREEN_WIDTH_PX
	sim.wSCY = 0
	w2(W_SCENE_WARIO, 0x60)
	w2(W_SCENE_WARIO_X_COORD, 0x5C)
	w2(W_SCENE_WARIO_STATE_GROUP, SCENEWARIO_GROUP_NONE)  # wOWUIObj2YCoord
	set_scene_wario_state(SCENEWARIO_IDLE_LEFT)
	_set_obj(10, 0x30, 0x00, 0x1B)  # .Func_af2ab
	_set_obj(11, 0x35, 0x20, 0x1C)
	_set_obj(12, 0x32, 0x70, 0x1B)
	_set_obj(13, 0x38, 0xC0, 0x1C)
	copy_rom(PROLOGUE_FADE_BANK, PALS_86ADD, W_TEMP_PALS_1, 8 * 8)  # .Func_af2b5
	copy_rom(PROLOGUE_FADE_BANK, PALS_86B1D, W_TEMP_PALS_2, 8 * 8)
	w2(W2D890, 0)
	w2(W2D891, 0)
	_epilogue_configs_next()


## .Func_af2f2 (the forest): the old man at ($3c, $b2) in state $13, scene Wario at ($3c, $c8) stunned
## left, the clouds' states 0, BG map 1 flipped in (wCollectionRow, wLCDCFlagsToFlip's byte), the
## palettes shown (Func_aca09) and the forest's to fade to (Pals_869cd, Pals_86b1d), the next step.
func _func_af2f2() -> void:
	_set_obj(9, 0x3C, 0xB2, 0x13)
	w2(W_SCENE_WARIO, 0x3C)
	w2(W_SCENE_WARIO_X_COORD, 0xC8)
	set_scene_wario_state(SCENEWARIO_STUNNED_LEFT)
	for number: int in [10, 11, 12, 13]:
		wr(scene_obj(number) + SCENE_OBJ_STATE, 0)
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
	_func_aca09()
	copy_rom(PROLOGUE_FADE_BANK, PALS_869CD, W_TEMP_PALS_1, 8 * 8)
	copy_rom(PROLOGUE_FADE_BANK, PALS_86B1D, W_TEMP_PALS_2, 8 * 8)
	_epilogue_configs_next()


## .Func_af8bc: while wSceneObj10 is in state $1b, the clouds drift right: wSceneObj10 (and 12 in state
## $1b) a pixel every 4 loops, wSceneObj11 and 13 (in state $1c) every 8 (wGlobalCounter).
func _func_af8bc() -> void:
	if rd(scene_obj(10) + SCENE_OBJ_STATE) != 0x1B:
		return
	for cloud: Array in [[10, -1, 0x03], [11, 0x1C, 0x07], [12, 0x1B, 0x03], [13, 0x1C, 0x07]]:
		var obj: int = scene_obj(int(cloud[0]))
		if int(cloud[1]) >= 0 and rd(obj + SCENE_OBJ_STATE) != int(cloud[1]):
			continue
		if (sim.wGlobalCounter & int(cloud[2])) == 0:
			wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) + 1)  # the state's address xor 7


# --- the creatures' transformations (.Func_af7af) ---

## .Func_af7af: the falling star and its sparkles (Func_15848a), then by w2d890 (w2d891 counts): the
## music (not ported), then three times: the sparkles' and the star's OBJ palette (4, 0, 3) and the star
## started; once it reaches y $50 the screen flashes white (Func_aca09, Func_aca25: a sound, not ported)
## and fades (Func_84e43), wSceneObj9's other form (states 2, 3, 4, a pixel or two left; the star
## hidden) and the fade back; $50 loops, the next creature (Doughnuteer $19 at x $48, Hammer-bot $1a at
## x $58) with OBJ palettes 4 to 6 (wPalConfig2 by Data_aca04). After the third, $50 loops, the palettes
## 0, the sub-steps cleared, the next step.
func _func_af7af() -> void:
	_func_15848a()
	var step: int = _next_substep()
	var counter: int = r2(W2D891)
	match step:
		0x00:  # .Func_af7ee
			_func_ae1ce()  # .asm_af40c
		0x01:  # .Func_af7fd
			_func_af7ff(0x04)
		0x02, 0x08, 0x0E:  # .Func_af816
			if rd(scene_obj(1) + SCENE_OBJ_Y) < 0x50:
				return
			_func_aca09()
			_func_aca25()
			_func_ae1ce()
		0x03, 0x05, 0x09, 0x0B, 0x0F, 0x11:  # .Func_af41c
			_func_84e43()
			if r2(W_PAL_CONFIG_1_TOTAL_STEPS) == 0:
				_func_ae1ce()
		0x04:  # .Func_af82d
			_func_af839(0x02, 1)
		0x06:  # .Func_af843
			_func_af843(0x19, 0x48)
		0x07:  # .Func_af860
			_func_af7ff(0x00)
		0x0A:  # .Func_af863
			_func_af839(0x03, 1)
		0x0C:  # .Func_af871
			_func_af843(0x1A, 0x58)
		0x0D:  # .Func_af88e
			_func_af7ff(0x03)
		0x10:  # .Func_af893
			_func_af839(0x04, 2)
		0x12:  # .Func_af8a2
			if counter >= 0x50:
				_func_ae1ce()
		0x13:  # .Func_af8a9
			for number: int in [5, 6, 7, 8, 1]:
				wr(scene_obj(number) + SCENE_OBJ_ATTRIBUTES, 0)
			_func_ae1d5()  # .asm_af413
		_:
			_note(".Func_af7af step $%02x (past its jumptable)" % step)


## .asm_af7ff: the sparkles' and the star's attributes (their OBJ palette) `attributes`, the star started
## (w2d8a0 1), the next sub-step.
func _func_af7ff(attributes: int) -> void:
	for number: int in [5, 6, 7, 8, 1]:
		wr(scene_obj(number) + SCENE_OBJ_ATTRIBUTES, attributes)
	w2(W2D8A0, 0x01)
	_func_ae1ce()


## .Func_af82d, .Func_af863, .Func_af893 (.asm_af839): wSceneObj9 in `state`, `left` pixels left, the
## star's state 0, the palettes shown and the epilogue's to fade back to (.Func_af1bd), the next sub-step.
func _func_af839(state: int, left: int) -> void:
	set_scene_obj_state(9, state)
	wr(scene_obj(9) + SCENE_OBJ_X, rd(scene_obj(9) + SCENE_OBJ_X) - left)
	wr(scene_obj(1) + SCENE_OBJ_STATE, 0)
	_func_af1bd()
	_func_ae1ce()


## .Func_af843, .Func_af871: after $50 loops wSceneObj9 in `state` at x `x`, OBJ palettes 4 to 6
## (.Func_af1db) applied by wPalConfig2 (Func_ac9e4 with Data_aca04), the next sub-step.
func _func_af843(state: int, x: int) -> void:
	if r2(W2D891) < 0x50:
		return
	set_scene_obj_state(9, state)
	wr(scene_obj(9) + SCENE_OBJ_X, x)
	_func_af1db()
	copy_rom(PROLOGUE_BANK, DATA_ACA04, W_PAL_CONFIG_2, 5)
	_func_ae1ce()


## Func_15848a (bank $56): the star (wSceneObj1) and its four sparkles (wSceneObj5 to 8).
func _func_15848a() -> void:
	_func_15849a()
	for sparkle: Array in EPILOGUE_SPARKLES:
		_epilogue_sparkle(sparkle)


## Func_15848a.Func_15849a: the star by w2d8a0 (w2d8a1 counts): at rest its counter cleared; started, at
## ($18, wSceneObj9's x) in state $16; then down a pixel every 4 loops to y $58, where it is hidden and
## at rest.
func _func_15849a() -> void:
	var action: int = r2(W2D8A0)
	w2(W2D8A1, r2(W2D8A1) + 1)
	var star: int = scene_obj(1)
	match action:
		0x00:
			w2(W2D8A1, 0)
		0x01:
			wr(star + SCENE_OBJ_Y, 0x18)
			wr(star + SCENE_OBJ_X, rd(scene_obj(9) + SCENE_OBJ_X))
			set_scene_obj_state(1, 0x16)
			w2(W2D8A1, 0)
			w2(W2D8A0, action + 1)
		0x02:
			if (r2(W2D8A1) & 0x03) != 0:
				return
			wr(star + SCENE_OBJ_Y, rd(star + SCENE_OBJ_Y) + 1)
			if rd(star + SCENE_OBJ_Y) != 0x58:
				return
			wr(star + SCENE_OBJ_STATE, 0)
			w2(W2D8A0, 0)
		_:
			_note("Func_15848a.Func_15849a action $%02x (past its jumptable)" % action)


## Func_15848a's .Func_1584da, .Func_158529, .Func_15858c, .Func_1585e1: a sparkle's counter counted, then
## its action (EPILOGUE_SPARKLES).
func _epilogue_sparkle(sparkle: Array) -> void:
	var at: int = int(sparkle[0])
	var number: int = int(sparkle[1])
	var actions: Array = sparkle[2]
	var action: int = r2(at)
	w2(at + 1, r2(at + 1) + 1)
	var counter: int = r2(at + 1)
	if action >= actions.size():
		_note("Func_15848a's sparkle %d action $%02x (past its jumptable)" % [number, action])
		return
	var entry: Array = actions[action]
	var obj: int = scene_obj(number)
	var star: int = scene_obj(1)
	match String(entry[0]):
		"star":
			if rd(star + SCENE_OBJ_STATE) != 0:
				_sparkle_next(at)
		"wait":
			if counter >= int(entry[1]):
				_sparkle_next(at)
		"spawn":
			wr(obj + SCENE_OBJ_Y, rd(star + SCENE_OBJ_Y) + int(entry[1]))
			wr(obj + SCENE_OBJ_X, rd(star + SCENE_OBJ_X) + int(entry[2]))
			set_scene_obj_state(number, 0x15)
			_sparkle_next(at)
		"fall":  # .Func_15864a, .Func_15866e
			var step: int = rb(FUNC_15848A_BANK, int(entry[1]) + counter)
			if step == 0x80:
				wr(obj + SCENE_OBJ_STATE, 0)
				if action == actions.size() - 1:
					w2(at, 0)
				else:
					_sparkle_next(at)
				return
			wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) + step)
			if (counter & 0x01) != 0:
				wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) + int(entry[2]))
			if counter == 0x03:
				wr(obj + SCENE_OBJ_STATE, 0x14)
		"again":
			w2(at, 0x02 if rd(star + SCENE_OBJ_STATE) != 0 else 0x00)


## A sparkle's counter cleared, its next action.
func _sparkle_next(at: int) -> void:
	w2(at + 1, 0)
	w2(at, r2(at) + 1)


# --- the old man walks in (.Func_af741) ---

## .Func_af741: by w2d890 (w2d891 counts): after $3c loops the old man walking at ($60, $80) (state 8),
## a pixel right a loop to x $e0, then with the scroll a pixel a loop until it wraps to 0 (state 9), $1e
## loops, he turns (state 6) until he stands (state $0a); $3c loops on, the next step.
func _func_af741() -> void:
	var step: int = _next_substep()
	var counter: int = r2(W2D891)
	var old_man: int = scene_obj(9)
	match step:
		0x00:  # .Func_af755
			if counter < 0x3C:
				return
			set_scene_obj_state(9, 0x08)
			wr(old_man + SCENE_OBJ_Y, 0x60)
			wr(old_man + SCENE_OBJ_X, 0x80)
			_func_ae1ce()
		0x01:  # .Func_af76c
			if _func_af7a7() == 0xE0:
				_func_ae1ce()
		0x02:  # .Func_af775
			_func_af7a7()
			sim.wSCX = byte(sim.wSCX + 1)
			if sim.wSCX != 0:
				return
			set_scene_obj_state(9, 0x09)
			_func_ae1ce()
		0x03:  # .Func_af788
			if counter < 0x1E:
				return
			set_scene_obj_state(9, 0x06)
			_func_ae1ce()
		0x04:  # .Func_af797
			if rd(old_man + SCENE_OBJ_STATE) == 0x0A:
				_func_ae1ce()
		0x05:  # .Func_af7a0
			if counter >= 0x3C:
				_func_ae1d5()  # .asm_af413
		_:
			_note(".Func_af741 step $%02x (past its jumptable)" % step)


## .Func_af7a7: the old man a pixel right; his x with its low bit off.
func _func_af7a7() -> int:
	var x_at: int = scene_obj(9) + SCENE_OBJ_X
	wr(x_at, rd(x_at) + 1)
	return rd(x_at) & 0xFE


## .Func_af376: the old man's mouth as his text prints: on a line's first character, by the page (and
## the language) a state when the text is on its line (1, or by .asm_af3e8 2 or 3); otherwise, on the
## first line, state $0b.
func _func_af376() -> void:
	if r2(W_PENDING_CHAR_DEST) == 0 or r2(W_CUR_TEXT_LINE_POS) != 1:
		return
	var pages: Dictionary = ({1: [0x10, 1], 4: [0x0C, 1], 5: [0x0D, 2], 7: [0x0E, 2], 0x0A: [0x10, 2],
			0x0B: [0x0C, 3]} if r0(W_LANGUAGE) == LANGUAGE_JAPANESE
			else {1: [0x10, 1], 4: [0x0C, 1], 5: [0x0D, 1], 8: [0x0E, 2], 0x0B: [0x10, 1], 0x0C: [0x0C, 1]})
	var line: int = r2(W_CUR_TEXT_BUFFER_LINE)  # wPalFade7Colour3RedSign
	var page: int = r2(W_CUR_TEXT_BUFFER_PAGE)  # wPalFade7Colour3RedUnk1
	if pages.has(page):
		var entry: Array = pages[page]
		if line == int(entry[1]):  # .asm_af3d7
			set_scene_obj_state(9, int(entry[0]))
			return
		if int(entry[1]) == 1:  # .asm_af3d0: no other
			return
	if line == 1:  # .asm_af3bf
		set_scene_obj_state(9, 0x0B)


# --- the old man's thanks (.Func_af670) ---

## .Func_af670: Wario's flashing palettes (Func_ae523), then by w2d890 (w2d891 counts): after $1e loops
## the text's arrow; A hides it, clears the text box (the music stops, not ported), and the old man rises
## (state $0f); $3c loops, Wario flashes; $28 loops, it stops and a burst (wCurSceneObj, state $11) is
## at Wario 4 lines up; $14 loops, Wario gone; $5a loops, the burst rises, then the old man is carried
## off ($12 and $0a below y $40) until y $18; $2d loops on, the next step.
func _func_af670() -> void:
	_func_ae523()
	var step: int = _next_substep()
	var counter: int = r2(W2D891)
	match step:
		0x00:  # .Func_af68b
			if counter < 0x1E:
				return
			set_scene_obj_state(1, 0x01)
			_func_ae1ce()
		0x01:  # .Func_af69a
			if (sim.wJoypadPressed & PAD_A) == 0:
				return
			set_scene_obj_state(1, 0x00)
			_clear_textbox_at(6 * TILEMAP_WIDTH, 8 - 1)  # ClearTextbox
			set_scene_obj_state(9, 0x0F)
			_func_ae1ce()
		0x02:  # .Func_af6c1
			if counter < 0x3C:
				return
			w2(W2D150, 0x01)
			_func_ae1ce()
		0x03:  # .Func_af6cd
			if counter < 0x28:
				return
			w2(W2D150, 0x80)
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 0x04)
			wr(W_CUR_SCENE_OBJ + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD))
			set_scene_obj_state(0, 0x11)
			_func_ae1ce()
		0x04:  # .Func_af6ee
			if counter < 0x14:
				return
			set_scene_wario_state(SCENEWARIO_NONE)
			_func_ae1ce()
		0x05:  # .Func_af6f9
			if counter >= 0x5A:
				_func_ae1ce()
		0x06:
			_func_af700()
		0x07:  # .Func_af73a
			if counter >= 0x2D:
				_func_ae1d5()  # .asm_af413
		_:
			_note(".Func_af670 step $%02x (past its jumptable)" % step)


## .Func_af700: the burst (wCurSceneObj) rises: from y $50 a line every 4 loops; above it 3 lines a loop,
## below y $40 it and the old man carried ($12, the old man $0a; once), and below y $18 it is hidden and
## the next sub-step (Func_ae1ce).
func _func_af700() -> void:
	var y_at: int = W_CUR_SCENE_OBJ + SCENE_OBJ_Y
	if rd(y_at) >= 0x50:
		if (r2(W2D891) & 0x03) == 0:
			wr(y_at, rd(y_at) - 1)
		return
	wr(y_at, rd(y_at) - 3)
	var y: int = rd(y_at)
	if y < 0x18:
		wr(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE, 0)
		_func_ae1ce()
		return
	if y >= 0x40 or rd(W_CUR_SCENE_OBJ + SCENE_OBJ_STATE) == 0x12:
		return
	set_scene_obj_state(0, 0x12)
	set_scene_obj_state(9, 0x0A)


# --- the forest (.Func_af436) ---

## .Func_af436: the old man's bounce (.Func_af60d) and Wario's (.Func_af57b), then by w2d890 (w2d891
## counts): the bounces cleared; at $40 loops Wario's starts, at $56 the old man's (sounds, not ported);
## once both are over, $3c loops, Wario turns his back, looks back, $28 loops, turns right, idles left,
## $2d loops, picks the old man up (his Unk7 cleared: .Func_ac1c3 lifts him) until both are done, the
## old man held over him (counts 4, 6, 7), $32 loops, Wario snaps his fingers (frame $0b: a sound, not
## ported) until he carries him idle, $32 loops, walks left with him to x $f0, both gone; $3c loops on,
## the next step.
func _func_af436() -> void:
	_func_af60d()
	_func_af57b()
	var step: int = _next_substep()
	var counter: int = r2(W2D891)
	var old_man: int = scene_obj(9)
	match step:
		0x00:  # .Func_af466
			w2(W2D894, 0)  # wPalFade2Colour2GreenUnk1
			w2(W2D892, 0)
			w2(W_TEMPLE_ROCK_5_ACTION, 0)
			w2(W_TEMPLE_ROCK_5_SIZE, 0)
			_func_ae1ce()
		0x01:  # .Func_af476
			if counter >= 0x40:
				w2(W2D892, 0x01)
				_func_ae1ce()
		0x02:  # .Func_af48a
			if counter >= 0x56:
				w2(W_TEMPLE_ROCK_5_ACTION, 0x01)
				_func_ae1ce()
		0x03:  # .Func_af49e
			if r2(W2D892) == 0x80 and r2(W_TEMPLE_ROCK_5_ACTION) == 0x80:
				_func_ae1ce()
		0x04:  # .Func_af4ad
			if counter >= 0x3C:
				_wario_state_then_on(SCENEWARIO_TURN_BACK_LEFT)
		0x05:  # .Func_af4b9 (.asm_af400)
			_func_ae1c2(SCENEWARIO_LOOK_BACK)
		0x06:  # .Func_af4be
			if counter >= 0x28:
				_wario_state_then_on(SCENEWARIO_LOOK_TURN_RIGHT)
		0x07:  # .Func_af4ca
			_func_ae1c2(SCENEWARIO_IDLE_LEFT)
		0x08:  # .Func_af4cf
			if counter < 0x2D:
				return
			set_scene_wario_state(SCENEWARIO_PICKUP)
			wr(old_man + W_SCENE_OBJ_UNK7, 0)
			_func_ae1ce()
		0x09:  # .Func_af4e7
			if rd(old_man + W_SCENE_OBJ_UNK7) == 0x80 and r2(W_SCENE_WARIO_STATE) == SCENEWARIO_CARRY_IDLE:
				_func_ae1ce()
		0x0A:  # .Func_af4f6
			match counter:
				0x04:
					_func_af50a(0xDF, 0xFA)
				0x06:
					_func_af50a(0xE0, 0xFB)
				0x07:
					_func_af50a(0xE2, 0xFC)
					_func_ae1ce()
		0x0B:  # .Func_af528
			if counter >= 0x32:
				_wario_state_then_on(SCENEWARIO_CARRY_SNAP_FINGERS)
		0x0C:  # .Func_af534
			if r2(W_SCENE_WARIO_FRAME) == 0x0B:
				_func_ae1ce()
		0x0D:  # .Func_af545
			_func_ae1c2(SCENEWARIO_CARRY_IDLE)
		0x0E:  # .Func_af54a
			if counter < 0x32:
				return
			set_scene_wario_state(SCENEWARIO_CARRY_WALK)
			wr(old_man + W_SCENE_OBJ_UNK7, 0)
			_func_ae1ce()
		0x0F:  # .Func_af55a
			w2(W_SCENE_WARIO_X_COORD, r2(W_SCENE_WARIO_X_COORD) - 1)  # Func_aca63
			var x: int = r2(W_SCENE_WARIO_X_COORD)
			wr(old_man + SCENE_OBJ_X, x - 4)
			if x != 0xF0:
				return
			w2(W_SCENE_WARIO_STATE, SCENEWARIO_NONE)
			wr(old_man + SCENE_OBJ_STATE, 0)
			_func_ae1ce()
		0x10:  # .Func_af574
			if counter >= 0x3C:
				_func_ae1d5()  # .asm_af413
		_:
			_note(".Func_af436 step $%02x (past its jumptable)" % step)


## .asm_af50a: the old man at scene Wario's place moved by (`dy`, `dx`).
func _func_af50a(dy: int, dx: int) -> void:
	wr(scene_obj(9) + SCENE_OBJ_Y, r2(W_SCENE_WARIO) + dy)
	wr(scene_obj(9) + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD) + dx)


## .Func_af57b: Wario's bounce: while w2d894 is set, on 3 of every 4 loops (w2d891) he moves by
## Data_aed06 mirrored (left) to its end, which clears w2d894; then by w2d892 (w2d893 counts): the throw
## (w2d894 set, his Unk7 cleared), three landings at y $60 (crash landing left, a bump: not ported) 4
## loops apart, until stunned, $42 loops, he idles left (a sound, not ported); then $80 (done).
func _func_af57b() -> void:
	if r2(W2D894) != 0 and (r2(W2D891) & 0x03) != 0:
		if apply_ow_movement(W_SCENE_WARIO, DATA_AED06, PROLOGUE_BANK, true):
			w2(W2D894, 0)
	var step: int = r2(W2D892)
	if step == 0x80:
		return
	match step:
		0x00:  # .Func_af5b2
			pass
		0x01:  # .Func_af5b3
			w2(W2D894, 0x01)
			w2(W_SCENE_WARIO_UNK7, 0)
			_next_bounce_step()  # .asm_af5bc
		0x02, 0x04, 0x06:  # .Func_af5c5
			if r2(W_SCENE_WARIO) != 0x60:
				return
			set_scene_wario_state(SCENEWARIO_CRASH_LAND_LEFT)
			_next_bounce_step()
		0x03, 0x05:  # .Func_af5d5
			w2(W2D893, r2(W2D893) + 1)
			if r2(W2D893) >= 0x04:
				_next_bounce_step()
		0x07:  # .Func_af5df
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_STUNNED_LEFT:
				_next_bounce_step()
		0x08:  # .Func_af5e7
			w2(W2D893, r2(W2D893) + 1)
			if r2(W2D893) < 0x42:
				return
			set_scene_wario_state(SCENEWARIO_IDLE_LEFT)
			_next_bounce_step()
		0x09:  # .Func_af5fe
			w2(W2D892, 0x80)
		_:
			_note(".Func_af57b step $%02x (past its jumptable)" % step)


## .Func_af60d: the old man's bounce: while w2d8c2 is set, each loop he moves by Data_aed06 mirrored
## to its end, which clears it; then by w2d8c0 (w2d8c1 counts): the throw (w2d8c2 set, his Unk7
## cleared), three landings at y $60 (a bump, not ported) 4 loops apart; then $80 (done).
func _func_af60d() -> void:
	var old_man: int = scene_obj(9)
	if r2(W_TEMPLE_ROCK_5_SIZE) != 0:
		if apply_ow_movement(old_man, DATA_AED06, PROLOGUE_BANK, true):
			w2(W_TEMPLE_ROCK_5_SIZE, 0)
	var step: int = r2(W_TEMPLE_ROCK_5_ACTION)
	if step == 0x80:
		return
	match step:
		0x00:  # .Func_af639
			pass
		0x01:  # .Func_af63a
			w2(W_TEMPLE_ROCK_5_SIZE, 0x01)
			wr(old_man + W_SCENE_OBJ_UNK7, 0)
			_old_man_bounce_next()
		0x02, 0x04, 0x06:  # .Func_af64c
			if rd(old_man + SCENE_OBJ_Y) == 0x60:
				_old_man_bounce_next()
		0x03, 0x05:  # .Func_af657
			w2(W_TEMPLE_ROCK_5_COUNTER, r2(W_TEMPLE_ROCK_5_COUNTER) + 1)
			if r2(W_TEMPLE_ROCK_5_COUNTER) >= 0x04:
				_old_man_bounce_next()
		0x07:  # .Func_af661
			w2(W_TEMPLE_ROCK_5_ACTION, 0x80)
		_:
			_note(".Func_af60d step $%02x (past its jumptable)" % step)


## .asm_af643: the old man's next bounce step, its counter cleared.
func _old_man_bounce_next() -> void:
	w2(W_TEMPLE_ROCK_5_ACTION, r2(W_TEMPLE_ROCK_5_ACTION) + 1)
	w2(W_TEMPLE_ROCK_5_COUNTER, 0)


# --- the epilogue's scene objects (Func_ac0b6, bank2b_1.asm) ---

## Func_ac0b6 on scene object `number` (0: wCurSceneObj) by its state (EPILOGUE_OBJ_STATES): its
## animation, once it ends a new state (run at once), what some states do after it, its sprite.
func _update_epilogue_scene_obj(number: int) -> void:
	var obj: int = scene_obj(number)
	var state: int = rd(obj + SCENE_OBJ_STATE)
	if state == 0:
		return
	if state >= EPILOGUE_OBJ_STATES.size():
		_note("Func_ac0b6 state $%02x (past its jumptable)" % state)
		return
	var entry: Array = EPILOGUE_OBJ_STATES[state]
	update_ow_animation(obj + SCENE_OBJ_DURATION, int(entry[0]), int(entry[1]))
	if int(entry[5]) >= 0 and r2(W_OW_ANIMATION_FINISHED) == 0xFF:  # .set_new_state_if_finished
		wr(obj + SCENE_OBJ_DURATION, 0)
		wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
		wr(obj + SCENE_OBJ_STATE, int(entry[5]))
		_update_epilogue_scene_obj(number)
		return
	var unk7: int = obj + W_SCENE_OBJ_UNK7
	match state:
		0x08:  # .PlaySFXEvery30Frames (the sound, not ported)
			wr(unk7, rd(unk7) + 1)
			if rd(unk7) >= 30:
				wr(unk7, 0)
		0x13:
			_func_ac1c3(obj)
		0x16:  # .Func_ac1e9 (the sound at $30, not ported)
			wr(unk7, rd(unk7) + 1)
			if rd(unk7) >= 0x30:
				wr(unk7, 0)
		0x17:  # .Func_ac207 (the sound at 1, not ported)
			wr(unk7, rd(unk7) + 1)
			if rd(unk7) != 0x01 and rd(unk7) >= 0x28:
				wr(unk7, 0)
	if bool(entry[4]):
		load_ow_sprite_with_scroll(obj, int(entry[2]), int(entry[3]))
	else:
		load_ow_sprite(obj, int(entry[2]), int(entry[3]))


## Func_ac0b6.Func_ac1c3 (state $13, the old man carried): while scene Wario carries him walking
## (.asm_ac254) he bobs a line up at Wario's frame 25 and down at 26 (his Unk7 the way); while Wario
## picks him up (.asm_ac275) he follows Wario's frames 0, 1, 2 to ($fc, $ea), ($f0, $ec), ($de, $f9)
## from Wario, his Unk7 counting them, $80 after the last.
func _func_ac1c3(obj: int) -> void:
	var unk7: int = obj + W_SCENE_OBJ_UNK7
	var frame: int = r2(W_SCENE_WARIO_FRAME)
	var count: int = rd(unk7)
	match r2(W_SCENE_WARIO_STATE):
		SCENEWARIO_CARRY_WALK:  # .asm_ac254
			if count > 1 or frame != (25 if count == 0 else 26):
				return
			wr(unk7, count ^ 0x01)
			wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) + (-1 if count == 0 else 1))
		SCENEWARIO_PICKUP:  # .asm_ac275
			if count == 0x80:
				return
			var offsets: Array = [0xFC, 0xEA, count + 1]  # .asm_ac286
			if count == 1:
				offsets = [0xF0, 0xEC, count + 1]  # .asm_ac29c
			elif count != 0:
				offsets = [0xDE, 0xF9, 0x80]  # .asm_ac2a6
			if frame != mini(count, 2):
				return
			wr(unk7, int(offsets[2]))  # .asm_ac290
			wr(obj + SCENE_OBJ_Y, r2(W_SCENE_WARIO) + int(offsets[0]))
			wr(obj + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD) + int(offsets[1]))
