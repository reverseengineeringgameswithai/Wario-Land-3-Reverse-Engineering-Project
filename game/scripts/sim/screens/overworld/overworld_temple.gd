class_name OverworldTemple
extends OverworldTempleRocks
## The Temple's scene (OverworldStateTable's sub-states $1a to $1d: _InitTempleScene, _UpdateTempleScene,
## LoadNextObjectiveText, src/engine/overworld/bank2b_1.asm), translated as far as its regular scene
## (WL3-052): A at the Temple; Wario walks in, turns to the hidden figure, and nods, and the figure's
## text names the level of the next treasure (none when that is the Temple itself), printed as the
## prologue's (PrintTextWithHeader); B or left sends him out again, B leaving at once while he walks.
## With the gold music box (the game's end) the hidden figure's reveal instead (HiddenFigureRevealScene):
## Wario bows, shows the five music boxes, the Temple shakes and rocks fall (OverworldTempleRocks), the
## hidden figure appears and talks, and the fight starts (SetFightAgainstAHiddenFigure). Its V-Blank
## function is the prologue's (VBlank_PrologueEpilogue).

const W_TEMPLE_SCENE: int = 0xDA00
const W_TEMPLE_MUSIC_IS_PLAYING: int = 0xDA02
const W_TEMPLE_MUSIC_DELAY_COUNTER: int = 0xDA03
const W2DA04: int = 0xDA04  # the scene's step
const W_TEMPLE_SCENE_COUNTER: int = 0xDA05
const W_IS_NEXT_OBJECTIVE_THE_TEMPLE: int = 0xDAB0
const W_TEXT_LINE_3: int = 0xDB20
const W_TEXT_LINE_4: int = 0xDB30
const TEMPLE_SCENE_ENTERING: int = 0x00
const TEMPLE_SCENE_TALKING: int = 0x01
const TEMPLE_SCENE_EXITING: int = 0x02
const TEMPLE_SCENE_HIDDEN_FIGURE_REVEAL: int = 0x03
const TEXT_JP_HIDDEN_FIGURE_HEAD_FOR: int = 0x5FD7  # bank $2c
const TEXT_EN_HIDDEN_FIGURE_HEAD_FOR: int = 0x611A
const GOLD_MUSIC_BOX: int = 0x05
const SCENEWARIO_NOD: int = 0x0E
## LCDC_BG_ON | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_9C00 | LCDC_ON
const LCDC_TEMPLE: int = 0xC7
## LoadNextObjectiveText: each map side's names in the text (North's after its header line).
const OBJECTIVE_TEXT_OFFSETS: Array[int] = [0x20, 0x120, 0x200, 0x2E0]
# The reveal (bank $2b; graphics and text in $2c and $36).
const TEMPLE_MUSIC_BOX_SCENE_GFX: int = 0x5D0B  # bank $2c
const HIDDEN_FIGURE_CUTSCENE_TILEMAP: int = 0x7AAA
const HIDDEN_FIGURE_CUTSCENE_ATTRMAP: int = 0x7BA5
const TEXT_JP_HIDDEN_FIGURE_REPLENISH_POWER: int = 0x632F
const TEXT_EN_HIDDEN_FIGURE_REPLENISH_POWER: int = 0x6424
const HIDDEN_FIGURE_GFX_BANK: int = 0x36
const HIDDEN_FIGURE_1_GFX: int = 0x4000
const HIDDEN_FIGURE_2_GFX: int = 0x5800
const DATA_AD654: int = 0x5654  # bank $2b: a music box's circle (y, x steps, $80 ends)
const DATA_AD939: int = 0x5939  # bank $2b: the hidden figure's hands' sway
const W_TEMPLE_MUSIC_BOX_1: int = 0xD8A2  # five of (action, counter)
const W2D8DA: int = 0xD8DA  # the left hand's sway on
const W2D8DC: int = 0xD8DC  # the right hand's
const NUM_FALLING_TEMPLE_ROCKS: int = 6
const NUM_TEMPLE_ROCKS: int = 10
const MODE_FOUGHT_A_HIDDEN_FIGURE: int = 0x04
const SCENEWARIO_TURN_BACK_LEFT: int = 0x05
const SCENEWARIO_SHOW_MUSIC_BOXES_1: int = 0x28
const SCENEWARIO_PANIC_JUMP: int = 0x2A
const SCENEWARIO_PANIC: int = 0x2B
const SCENEWARIO_BOW: int = 0x2C
const SCENEWARIO_SHOW_MUSIC_BOXES_3: int = 0x2E
const SCENEWARIO_SHOW_MUSIC_BOXES_4: int = 0x2F
const SCENEWARIO_PANIC_RUN_LEFT: int = 0x3A
const SCENEWARIO_PANIC_RUN_RIGHT: int = 0x3B
## UpdateTempleSceneObjAnimation's states 2 to $12 (bank $2b): [frameset, its bank, the OAM table, its
## bank, with the scroll, the state set once the animation ends or -1]; 1 is the text's arrow (the
## prologue's entry). Framesets in "Credits OAM" ($57); the hands' and mouth's OAM table OAM_18c88a ($63).
const TEMPLE_OBJ_STATES: Array = [
	[], [],
	[0x6796, 0x57, 0x644A, 0x57, true, 0x00],  # $02 the exclamation mark (Func_ac337)
	[0x689C, 0x57, 0x6813, 0x57, true, -1], [0x689F, 0x57, 0x6813, 0x57, true, -1],  # $03-$07 the music boxes
	[0x68A2, 0x57, 0x6813, 0x57, true, -1], [0x68A5, 0x57, 0x6813, 0x57, true, -1],
	[0x68A8, 0x57, 0x6813, 0x57, true, -1], [0x688D, 0x57, 0x6813, 0x57, true, -1],
	[0x6896, 0x57, 0x6813, 0x57, false, -1], [0x6893, 0x57, 0x6813, 0x57, false, -1],  # $09-$0c (Func_ac38e)
	[0x6890, 0x57, 0x6813, 0x57, false, -1], [0x6899, 0x57, 0x6813, 0x57, false, -1],
	[0x68AB, 0x57, 0x488A, 0x63, true, -1], [0x68B0, 0x57, 0x488A, 0x63, true, -1],  # $0d, $0e the mouth
	[0x68B0, 0x57, 0x488A, 0x63, true, 0x0D], [0x68AB, 0x57, 0x488A, 0x63, true, 0x0E],  # $0f, $10
	[0x6932, 0x57, 0x488A, 0x63, true, -1], [0x695C, 0x57, 0x488A, 0x63, true, -1],  # $11, $12 the hands
]


## _InitTempleScene: the LCD off, BG map 0 filled, the scroll cleared, the prologue's V-Blank function,
## the general scene RAM and the scene objects cleared, the Temple's palettes, the font, its tiles and
## BG maps; without the gold music box (or with the game cleared and not in Time Attack) the regular
## scene: the hidden figure's text (by the language) and the next objective's lines; scene Wario off
## screen at ($60, $e8) (written through the labels w1d140 and wDollBoyNoFlashingBarrel, whose
## addresses in WRAM bank 2 are his); the LCD on with the window from $9c00.
func init_temple_scene() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()  # (the music stopped, not ported)
	sim.wSCX = 0
	sim.wSCY = 0
	vblank_func = VBLANK_PROLOGUE  # VBlank_PrologueEpilogue
	clear_general_scene_ram()
	clear_scene_objs_ram()
	copy_rom(PROLOGUE_FADE_BANK, PALS_86A4D, W_TEMP_PALS_1, 8 * 8)  # LoadFarPalsToTempPals1
	decompress_to_vram(int(FONT_GFX[0]), int(FONT_GFX[1]), 1, 0x8000)  # decompress_tiles1 FontGfx
	_load_far_tiles([PROLOGUE_MAPS_BANK, TEMPLE_GFX], 0)
	load_far_bg_map(PROLOGUE_MAPS_BANK, TEMPLE_TILEMAP, 0)
	load_far_bg_map(PROLOGUE_MAPS_BANK, TEMPLE_ATTRMAP, 1)
	fill(W_CLEARED_TEXT_BUFFER, 8 * TEXT_LINE_LENGTH, CHAR_NONE)  # FillClearedTextBuffer
	var flags: int = r0(W_GAME_MODE_FLAGS)
	if is_treasure_collected(GOLD_MUSIC_BOX) != 0 and ((flags & MODE_GAME_CLEARED) == 0
			or (flags & MODE_TIME_ATTACK) != 0):
		w2(W_TEMPLE_SCENE, TEMPLE_SCENE_HIDDEN_FIGURE_REVEAL)
		decompress_to_vram(PROLOGUE_MAPS_BANK, TEMPLE_MUSIC_BOX_SCENE_GFX, 1, 0x8000)  # decompress_tiles1
		decompress_to_vram(PROLOGUE_MAPS_BANK, HIDDEN_FIGURE_CUTSCENE_TILEMAP, 0, 0x9C00)
		decompress_to_vram(PROLOGUE_MAPS_BANK, HIDDEN_FIGURE_CUTSCENE_ATTRMAP, 1, 0x9C00)
		var text: int = TEXT_JP_HIDDEN_FIGURE_REPLENISH_POWER if r0(W_LANGUAGE) == LANGUAGE_JAPANESE \
				else TEXT_EN_HIDDEN_FIGURE_REPLENISH_POWER
		decompress_to_wram(PROLOGUE_MAPS_BANK, text, W_TEXT_BUFFER)
	else:
		w2(W_TEMPLE_SCENE, TEMPLE_SCENE_ENTERING)
		var text: int = TEXT_JP_HIDDEN_FIGURE_HEAD_FOR if r0(W_LANGUAGE) == LANGUAGE_JAPANESE \
				else TEXT_EN_HIDDEN_FIGURE_HEAD_FOR
		decompress_to_wram(PROLOGUE_MAPS_BANK, text, W_TEXT_BUFFER)
		load_next_objective_text()
	w2(W_SCENE_WARIO, 0x60)
	w2(W_SCENE_WARIO_X_COORD, 0xE8)
	w2(W_SCENE_WARIO_STATE_GROUP, SCENEWARIO_GROUP_NONE)
	set_scene_wario_state(SCENEWARIO_NONE)
	update_scene_wario()
	w2(W2D013, 0)
	w2(W2D014, 0)
	var lcdc: int = LCDC_TEMPLE
	if r2(W_LCDC_FLAGS_TO_FLIP) != 0:
		lcdc ^= r2(W_LCDC_FLAGS_TO_FLIP)
	set_lcdc(lcdc)
	w2(W_LCDC_FLAGS_TO_FLIP, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## LoadFarBGMap: 18 rows of BG map from (bank, `source`) to VRAM bank `vram_bank`'s BG map 0.
func load_far_bg_map(bank: int, source: int, vram_bank: int) -> void:
	var bytes := PackedByteArray()
	for offset: int in 18 * TILEMAP_WIDTH:
		bytes.append(rb(bank, source + offset))
	record_bytes_to_vram(vram_bank, 0x9800, bytes)


## LoadNextObjectiveText: the header line to wTextLine1, then by the map side and level of the next
## treasure (GetMapSideAndLevelForNextTreasure) its name's two lines in wTextBuffer (none when it is the
## Temple: wIsNextObjectiveTheTemple), with the text's second line: in Japanese the name then that line
## and an empty fourth, in English that line then the name.
func load_next_objective_text() -> void:
	for offset: int in TEXT_LINE_LENGTH:
		w2(W_TEXT + offset, r2(W_TEXT_BUFFER + offset))
	w2(W_IS_NEXT_OBJECTIVE_THE_TEMPLE, 0)
	var next: Vector2i = _get_map_side_and_level_for_next_treasure()
	var side: int = next.x
	var level: int = next.y & 0xFF
	var offset: int = OBJECTIVE_TEXT_OFFSETS[mini(side, 3)]
	if (side == NORTH or side > 3) and level == 0:  # .check_the_temple (past East, debug_nop falls in)
		w2(W_IS_NEXT_OBJECTIVE_THE_TEMPLE, 1)
	var row: int = ((swap(level) << 1) | (swap(level) >> 7)) & 0xFF  # swap a; rlca: the level times $20
	var name: int = W_TEXT_BUFFER + offset + row
	if r0(W_LANGUAGE) == LANGUAGE_JAPANESE:
		for at: int in TEXT_LINE_LENGTH:
			w2(W_TEXT_LINE_2 + at, rd(name + at))
			w2(W_TEXT_LINE_3 + at, r2(W_TEXT_BUFFER + TEXT_LINE_LENGTH + at))
			w2(W_TEXT_LINE_4 + at, CHAR_NONE)
		return
	for at: int in 2 * TEXT_LINE_LENGTH:
		w2(W_TEXT_LINE_3 + at, rd(name + at))
	for at: int in TEXT_LINE_LENGTH:
		w2(W_TEXT_LINE_2 + at, r2(W_TEXT_BUFFER + TEXT_LINE_LENGTH + at))


## _UpdateTempleScene: the scene's step, its first scene objects (Func_ac2b2), scene Wario, the other
## scene objects (UpdateTempleSceneObjs), the virtual OAM's unused entries cleared.
func update_temple_scene() -> void:
	_update_temple_scene_step()
	for number: int in [0, 1, 2]:  # Func_ac2b2: wCurSceneObj, then 1 and 2
		_update_temple_scene_obj(number)
	update_scene_wario()
	for number: int in [3, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15]:  # UpdateTempleSceneObjs
		_update_temple_scene_obj(number)
	clear_unused_virtual_oam()


## UpdateTempleSceneObjAnimation: a scene object by its state (TEMPLE_OBJ_STATES); the text's arrow (1,
## Func_ac056) as the prologue draws it; an animation that ends hands over to its next state, animated
## the same loop.
func _update_temple_scene_obj(number: int) -> void:
	var obj: int = scene_obj(number)
	var state: int = rd(obj + SCENE_OBJ_STATE)
	if state == 0:
		return
	if state == 1:
		_update_prologue_scene_obj(number)
		return
	if state >= TEMPLE_OBJ_STATES.size():
		_note("UpdateTempleSceneObjAnimation state $%02x (past its jumptable)" % state)
		return
	var entry: Array = TEMPLE_OBJ_STATES[state]
	update_ow_animation(obj + SCENE_OBJ_DURATION, int(entry[0]), int(entry[1]))
	if int(entry[5]) >= 0 and r2(W_OW_ANIMATION_FINISHED) == 0xFF:  # SetObjStateIfAnimationIsFinished
		wr(obj + SCENE_OBJ_DURATION, 0)
		wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
		wr(obj + SCENE_OBJ_STATE, int(entry[5]))
		_update_temple_scene_obj(number)
		return
	if bool(entry[4]):
		load_ow_sprite_with_scroll(obj, int(entry[2]), int(entry[3]))
	else:
		load_ow_sprite(obj, int(entry[2]), int(entry[3]))


## _UpdateTempleScene.UpdateScene: wTempleSceneCounter counts; by wTempleScene.
func _update_temple_scene_step() -> void:
	w2(W_TEMPLE_SCENE_COUNTER, r2(W_TEMPLE_SCENE_COUNTER) + 1)
	match r2(W_TEMPLE_SCENE):
		TEMPLE_SCENE_ENTERING:
			_temple_entering()
		TEMPLE_SCENE_TALKING:
			_temple_talking()
		TEMPLE_SCENE_EXITING:
			_temple_exiting()
		TEMPLE_SCENE_HIDDEN_FIGURE_REVEAL:
			hidden_figure_reveal_scene()
		var scene:
			_note("_UpdateTempleScene scene %d (past its table)" % scene)


## ApplySceneWarioMovementRight (or Left) and the callers' `cp x; ret nz; ld [hl], a`: whether scene
## Wario has reached `x` (his x with its low bit off), which his x is then set to.
func _walk_scene_wario_to(x: int, right: bool) -> bool:
	var at: int = apply_scene_wario_movement_right() if right else apply_scene_wario_movement_left()
	if at != x:
		return false
	w2(W_SCENE_WARIO_X_COORD, x)
	return true


## .NextState: the counter cleared, the step one on.
func _next_temple_step() -> void:
	w2(W_TEMPLE_SCENE_COUNTER, 0)
	w2(W2DA04, r2(W2DA04) + 1)


## .Entering: Wario walks right from off screen to x $50, idles, turns his back 8 loops on, looks back,
## and 50 loops on nods: the hidden figure talks (the printer from its first line).
func _temple_entering() -> void:
	var counter: int = r2(W_TEMPLE_SCENE_COUNTER)
	match r2(W2DA04):
		0:
			set_scene_wario_state(SCENEWARIO_WALK_RIGHT)
			_next_temple_step()
		1:
			if not _walk_scene_wario_to(0x50, true):
				return
			set_scene_wario_state(SCENEWARIO_IDLE_RIGHT)
			_next_temple_step()
		2:
			if counter < 8:
				return
			set_scene_wario_state(SCENEWARIO_TURN_BACK_RIGHT)
			_next_temple_step()
		3:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_LOOK_BACK:
				_next_temple_step()
		4:
			if counter < 50:
				return
			set_scene_wario_state(SCENEWARIO_NOD)
			w2(W_TEMPLE_SCENE_COUNTER, 0)
			w2(W2DA04, 0)
			w2(W_CUR_TEXT_LINE, 0)
			w2(W_TEXT_DELAY_COUNTER, 0)
			w2(W_TEMPLE_SCENE, TEMPLE_SCENE_TALKING)


## .TalkToHiddenFigure: 90 loops before the Temple's music starts (not ported, its flag kept), the text
## printed (none when the next objective is the Temple); B or left clears the text box and leaves.
func _temple_talking() -> void:
	if r2(W_TEMPLE_MUSIC_IS_PLAYING) == 0:  # .DelayAndPlayTempleMusic
		w2(W_TEMPLE_MUSIC_DELAY_COUNTER, r2(W_TEMPLE_MUSIC_DELAY_COUNTER) + 1)
		if r2(W_TEMPLE_MUSIC_DELAY_COUNTER) >= 90:
			w2(W_TEMPLE_MUSIC_DELAY_COUNTER, 0)
			w2(W_TEMPLE_MUSIC_IS_PLAYING, 1)
	if r2(W_IS_NEXT_OBJECTIVE_THE_TEMPLE) == 0:
		_print_text(true)
	if (sim.wJoypadPressed & (PAD_B | PAD_LEFT)) == 0:
		return
	w2(W_TEMPLE_SCENE_COUNTER, 0)
	w2(W2DA04, 0)
	_clear_textbox_at(6 * TILEMAP_WIDTH, 8 - 1)  # ClearTextbox
	w2(W_TEMPLE_SCENE, TEMPLE_SCENE_EXITING)


## .Exiting: Wario turns left, idles, 4 loops on walks left off screen (to x $f0; B leaves at once), and
## $0a loops later the map side again (sub-state 8, w2d14c 1).
func _temple_exiting() -> void:
	var counter: int = r2(W_TEMPLE_SCENE_COUNTER)
	match r2(W2DA04):
		0:
			set_scene_wario_state(SCENEWARIO_TURN_BACK_TO_LEFT)
			_next_temple_step()
		1:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_IDLE_LEFT:
				_next_temple_step()
		2:
			if counter < 4:
				return
			set_scene_wario_state(SCENEWARIO_WALK_LEFT)
			_next_temple_step()
		3:
			if (sim.wJoypadPressed & PAD_B) != 0:
				_leave_temple()
				return
			if apply_scene_wario_movement_left() != 0xF0:
				return
			set_scene_wario_state(SCENEWARIO_NONE)
			_next_temple_step()
		4:
			if counter >= 0x0A:
				_leave_temple()


## .exit: the sounds stopped (not ported), w2d14c 1, the map side's fade (sub-state 8).
func _leave_temple() -> void:
	w2(W2D14C, 1)
	sim.wSubState = SST_OVERWORLD_08


# --- the hidden figure's reveal (HiddenFigureRevealScene, bank $2b) ---

## HiddenFigureRevealScene: once the hidden figure has been fought (MODE_FOUGHT_A_HIDDEN_FIGURE), B from
## its third step on starts the fight at once; else the hands sway, w2d014 counts, and by w2d013: Wario
## walks in and bows (HandleEnterTempleWithAllMusicBoxesScene), the first text page, the music boxes
## (Func_ad445), the shake and the rocks (HandleTempleShakeScene), the BG fading out to the figure's
## (PrologueFade 3 and 4, BG map 1 flipped in, its tiles by DMA), the hands and mouth set up, Wario's
## panic (HandleHiddenFigureReveal), the figure's text on BG map 1 with its mouth, Wario's jump, the
## fight.
func hidden_figure_reveal_scene() -> void:
	if r2(W2D013) >= 0x02 and (r0(W_GAME_MODE_FLAGS) & MODE_FOUGHT_A_HIDDEN_FIGURE) != 0 \
			and (sim.wJoypadPressed & PAD_B) != 0:
		set_fight_against_a_hidden_figure()
		return
	if r2(W2D8DA) != 0:  # DoHiddenFigureLeftHandMovement
		apply_ow_movement(scene_obj(3), DATA_AD939, PROLOGUE_BANK)
	if r2(W2D8DC) != 0:  # DoHiddenFigureRightHandMovement
		apply_ow_movement(scene_obj(4), DATA_AD939, PROLOGUE_BANK, true)
	w2(W2D014, r2(W2D014) + 1)
	var counter: int = r2(W2D014)
	match r2(W2D013):
		0x00:
			_reveal_next()  # Func_ad016
		0x01:
			_enter_temple_with_all_music_boxes()
		0x02, 0x18:  # .Wait1, .Wait3
			_reveal_wait(40)
		0x03:
			_init_text_printing()
		0x04, 0x1A:
			_func_aca9e()
		0x05:  # .Wait2
			_reveal_wait(30)
		0x06, 0x1C, 0x21:
			_load_cur_text_page_buffer_page()
		0x07:
			_func_acacd()
		0x08:
			_func_acae7()
		0x09:  # .Func_ad0bd
			_func_acaf3()
		0x0A:  # .WaitThenShowTextArrow
			if counter < 30:
				return
			set_scene_obj_state(1, 0x01)
			_reveal_next()
		0x0B:  # .WaitAButtonThenClearTextbox
			if (sim.wJoypadPressed & PAD_A) == 0:
				return
			set_scene_obj_state(1, 0x00)
			_clear_textbox_at(6 * TILEMAP_WIDTH, 8 - 1)
			_reveal_next()
		0x0C:
			_func_ad445()
		0x0D:
			handle_temple_shake_scene()
		0x0E:  # .Func_ad0e4
			handle_temple_shake_and_rocks()
			_reveal_fade(0x03)
			handle_temple_wario_panic()  # .Func_ad16a
			_reveal_next()
		0x0F:  # .Func_ad0f6
			handle_temple_wario_panic()
			handle_temple_shake_and_rocks()
			if (counter & 0x0F) == 0:
				prologue_fade()
		0x10:  # .InitShakeAndRocks
			w2(W2D896, 0x01)
			handle_temple_shake_and_rocks()
			for rock: int in NUM_TEMPLE_ROCKS:
				w2(temple_rock(rock + 1) + TEMPLE_ROCK_SIZE, 0x00)
			handle_temple_wario_panic()
			_reveal_next()
		0x11:  # .Func_ad12f
			handle_temple_wario_panic()
			handle_temple_shake_and_rocks()
			var actions: int = 0
			for rock: int in NUM_TEMPLE_ROCKS:
				actions += r2(temple_rock(rock + 1))
			if (actions & 0xFF) != 0:
				return
			w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
			_reveal_next()
		0x12:  # .LoadHiddenFigureGfx1: tiles $80 on to v0Tiles1
			_hidden_figure_hdma(0, HIDDEN_FIGURE_1_GFX + 0x80 * 0x10, 0x08)
		0x13:  # .LoadHiddenFigureGfx2: tiles $100 on to v0Tiles2
			_hidden_figure_hdma(0, HIDDEN_FIGURE_1_GFX + 0x100 * 0x10, 0x10)
		0x14:  # .LoadHiddenFigureGfx3: HiddenFigure2Gfx to v1Tiles0
			_hidden_figure_hdma(1, HIDDEN_FIGURE_2_GFX, 0x00)
		0x15:  # .Func_ad195: the mouth and the hands
			handle_temple_wario_panic()
			if counter < 30:
				return
			set_scene_obj_state(7, 0x0D)
			set_scene_obj_state(3, 0x11)
			set_scene_obj_state(4, 0x12)
			for placed: Array in [[7, 0x38, 0x50], [3, 0x58, 0x20], [4, 0x58, 0x80]]:
				wr(scene_obj(placed[0]) + SCENE_OBJ_Y, placed[1])
				wr(scene_obj(placed[0]) + SCENE_OBJ_X, placed[2])
			w2(W2D8DA, 0x01)
			w2(W2D8DC, 0x01)
			_reveal_fade(0x04)
			_reveal_next()
		0x16:  # .Func_ad1e3
			handle_temple_wario_panic()
			var mask: int = 0x07 if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 0x14 else 0x03
			if (counter & mask) == 0:
				prologue_fade()
		0x17:
			_handle_hidden_figure_reveal()
		0x19:  # .InitTextPrintOnBGMap1
			_init_text_printing()
			w2(W_BG_MAP_TO_PRINT_TEXT, 0x01)
		0x1B:  # .Func_ad207
			if counter < 30:
				return
			w2(W_CUR_TEXT_BUFFER_PAGE, 0x04)
			_reveal_next()
		0x1D:  # .StartHiddenFigureMouthMovement
			wr(scene_obj(7) + SCENE_OBJ_STATE, 0x10)
			_reveal_next()
		0x1E:  # .PlayHiddenFigureLaughSFX (the laugh, not ported)
			if rd(scene_obj(7) + SCENE_OBJ_STATE) == 0x0E:
				_reveal_next()
		0x1F:  # .PrintTextUntilNextPage
			_print_text(false)
			if r2(W_CUR_TEXT_LINE) == 0x80:
				_reveal_next()
		0x20:  # .Func_ad23a
			if counter == 40:  # .finish_mouth_movement
				wr(scene_obj(7) + SCENE_OBJ_STATE, 0x0F)
				return
			if counter < 70:
				return
			w2(W_CUR_TEXT_BUFFER_PAGE, r2(W_CUR_TEXT_BUFFER_PAGE) + 1)
			set_scene_obj_state(1, 0x01)
			_reveal_next()
		0x22:  # .Func_ad259
			if (sim.wJoypadPressed & PAD_A) == 0:
				return
			set_scene_obj_state(1, 0x00)
			_clear_textbox_at(7 * TILEMAP_WIDTH, 6 - 1)  # ClearTextboxExceptHeader
			wr(scene_obj(7) + SCENE_OBJ_STATE, 0x10)
			_prologue_next()  # Func_aca6d
		0x23:  # .Func_ad271
			if rd(scene_obj(7) + SCENE_OBJ_STATE) == 0x0E:
				_prologue_next()
		0x24:  # .Func_ad27a
			_print_text(false)
			_handle_hidden_figure_mouth_closing()
			if r2(W_CUR_TEXT_LINE) == 0x80:
				_prologue_next()  # Func_af135
		0x25:  # .Func_ad2f4: the next page (again from .Func_ad259), or on at the last
			if rd(scene_obj(7) + SCENE_OBJ_STATE) != 0x0D:
				return
			var last: bool = rd(_text_page(r2(W_CUR_TEXT_BUFFER_PAGE) + 1)) == CHAR_PAGE_END
			_func_acaf3()
			if not last:
				w2(W2D013, r2(W2D013) - 1)
		0x26:  # .Func_ad300
			set_scene_wario_state(SCENEWARIO_PANIC_JUMP)
			_reveal_next()
		0x27:  # .Func_ad308
			if counter < 30:
				return
			set_scene_obj_state(1, 0x01)
			_reveal_next()
		0x28:  # .Func_ad319
			if (sim.wJoypadPressed & PAD_A) == 0:
				return
			wr(scene_obj(1) + SCENE_OBJ_STATE, 0x00)
			_clear_textbox_at(6 * TILEMAP_WIDTH, 8 - 1)
			_reveal_next()
		0x29:
			set_fight_against_a_hidden_figure()
		var step:
			_note("HiddenFigureRevealScene step $%02x (past its jumptable)" % step)


## Func_ad016: w2d014 cleared, the next step.
func _reveal_next() -> void:
	_prologue_next()


## Func_ad011: the next step once w2d014 reaches `loops`.
func _reveal_wait(loops: int) -> void:
	if r2(W2D014) >= loops:
		_reveal_next()


## The next PrologueFade (w2d880) and its configs' steps cleared.
func _reveal_fade(fade: int) -> void:
	w2(W2D880, fade)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W_PAL_CONFIG_2_TOTAL_STEPS, 0)


## .LoadHiddenFigureGfx1 to 3 (.SetHDMA): $80 tiles of the hidden figure from bank $36 at `source` by
## wHDMA to VRAM bank `vram_bank` at (`destination_hi` + $80) << 8, Wario's panic, the next step.
func _hidden_figure_hdma(vram_bank: int, source: int, destination_hi: int) -> void:
	w2(W_HDMA_DEST_VRAM_BANK, vram_bank)
	w2(W_HDMA_BANK, HIDDEN_FIGURE_GFX_BANK)
	w2(W_HDMA, source >> 8)
	w2(W_HDMA + 1, source & 0xFF)
	w2(W_HDMA + 2, destination_hi)
	w2(W_HDMA + 3, 0)
	w2(W_HDMA + 4, 0x80 - 1)  # $80 dma_tiles
	handle_temple_wario_panic()
	_reveal_next()


## SetFightAgainstAHiddenFigure: the music and sounds stopped (not ported), the level's state from its
## first sub-state (HandleOverworld then selects the Temple's level).
func set_fight_against_a_hidden_figure() -> void:
	sim.wSubState = 0
	sim.wState = byte(sim.wState + 1)  # ST_LEVEL


## .HandleHiddenFigureMouthClosing: while a character is pending on the text's third line, at the
## page's place (by the language) the mouth's closing (state $0f).
func _handle_hidden_figure_mouth_closing() -> void:
	if r2(W_PENDING_CHAR_DEST) == 0 or r2(W_CUR_TEXT_BUFFER_LINE) == 1:
		return
	var positions: Dictionary = ({5: 1, 6: 8, 7: 8, 8: 12, 9: 1} if r0(W_LANGUAGE) == LANGUAGE_JAPANESE
			else {5: 10, 6: 12, 7: 5, 8: 11, 9: 12})
	var page: int = r2(W_CUR_TEXT_BUFFER_PAGE)
	if not positions.has(page):
		return
	if r2(W_CUR_TEXT_LINE_POS) == int(positions[page]) and r2(W_CUR_TEXT_BUFFER_LINE) == 2:
		wr(scene_obj(7) + SCENE_OBJ_STATE, 0x0F)


# --- the reveal's sub-scenes (w2d890: their step, w2d891: its counter) ---

## Func_ad335: the sub-scene's next step, its counter cleared.
func _sub_next() -> void:
	w2(W2D891, 0)
	w2(W2D890, r2(W2D890) + 1)


## Func_ad330: the next sub-step once its counter reaches `loops`.
func _sub_wait(loops: int) -> void:
	if r2(W2D891) >= loops:
		_sub_next()


## Func_ad329: the next sub-step once scene Wario is in `state`.
func _sub_wait_wario(state: int) -> void:
	if r2(W_SCENE_WARIO_STATE) == state:
		_sub_next()


## Func_ad33c: the sub-scene over (its step and counter cleared), the reveal's next step.
func _sub_done() -> void:
	w2(W2D890, 0)
	w2(W2D891, 0)
	_reveal_next()


## HandleEnterTempleWithAllMusicBoxesScene: 8 loops, Wario walks in to x $50, 30 loops, turns his back;
## in Time Attack he also bows with the text's arrow, and A goes on (he looks back), B or left sends him
## out (TEMPLE_SCENE_EXITING); otherwise straight on.
func _enter_temple_with_all_music_boxes() -> void:
	w2(W2D891, r2(W2D891) + 1)
	var counter: int = r2(W2D891)
	match r2(W2D890):
		0:
			_sub_wait(8)
		1:
			set_scene_wario_state(SCENEWARIO_WALK_RIGHT)
			_sub_next()
		2:
			if not _walk_scene_wario_to(0x50, true):
				return
			set_scene_wario_state(SCENEWARIO_IDLE_RIGHT)
			_sub_next()
		3:
			_sub_wait(30)
		4:
			set_scene_wario_state(SCENEWARIO_TURN_BACK_RIGHT)
			_sub_next()
		5:
			_sub_wait_wario(SCENEWARIO_LOOK_BACK)
		6:  # .CheckTimeAttack
			if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) == 0:
				_sub_done()
			else:
				_sub_next()
		7:  # .Bow
			if counter < 20:
				return
			set_scene_wario_state(SCENEWARIO_BOW)
			wr(scene_obj(1) + SCENE_OBJ_Y, 0x8E)
			wr(scene_obj(1) + SCENE_OBJ_X, 0x98)
			set_scene_obj_state(1, 0x01)
			_sub_next()
		8:  # .WaitInput
			var pressed: int = sim.wJoypadPressed
			if (pressed & PAD_A) != 0:
				set_scene_wario_state(SCENEWARIO_LOOK_BACK)
				wr(scene_obj(1) + SCENE_OBJ_STATE, 0)
				_sub_done()
			elif (pressed & (PAD_B | PAD_LEFT)) != 0:
				wr(scene_obj(1) + SCENE_OBJ_STATE, 0)
				w2(W_TEMPLE_SCENE, TEMPLE_SCENE_EXITING)
				w2(W_TEMPLE_SCENE_COUNTER, 0)
		var step:
			_note("HandleEnterTempleWithAllMusicBoxesScene step %d (past its jumptable)" % step)


## Func_ad445: the music boxes (HandleTempleMusicBoxes), then 60 loops, Wario shows them (hands raised),
## 16 loops on they rise one by one, 60 loops after they circle he lowers his hands, looks back, 4 times
## 240 loops, they go, the reveal's next step.
func _func_ad445() -> void:
	handle_temple_music_boxes()
	w2(W2D891, r2(W2D891) + 1)
	var counter: int = r2(W2D891)
	match r2(W2D890):
		0:
			_sub_wait(60)
		1:
			set_scene_wario_state(SCENEWARIO_SHOW_MUSIC_BOXES_1)
			_sub_next()
		2:
			_sub_wait_wario(SCENEWARIO_SHOW_MUSIC_BOXES_3)
		3:  # .SpawnMusicBoxes
			if counter < 16:
				return
			w2(W2D8A0, 0x01)
			_sub_next()
		4, 12:  # .WaitMusicBoxSequenceFinish
			if r2(W2D8A0) == 0:
				_sub_next()
		5:  # .LowerHands
			if counter < 60:
				return
			set_scene_wario_state(SCENEWARIO_SHOW_MUSIC_BOXES_4)
			_sub_next()
		6:
			_sub_wait_wario(SCENEWARIO_LOOK_BACK)
		7, 8, 9, 10:
			_sub_wait(240)
		11:  # .DespawnMusicBoxes
			w2(W2D8A0, 0x08)
			_sub_next()
		13:
			_sub_done()
		var step:
			_note("Func_ad445 step %d (past its jumptable)" % step)


## HandleTempleMusicBoxes: each music box's hover (HandleTempleMusicBoxNHover), then by w2d8a0 (w2d8a1
## counts): from 1 each box started 16 loops apart (yellow, blue, green, red, gold), then 0; from 8 each
## stopped once its circle's step (the object's Unk7) is 16, then 0.
func handle_temple_music_boxes() -> void:
	for box: int in 5:
		_handle_temple_music_box_hover(box)
	var state: int = r2(W2D8A0)
	w2(W2D8A1, r2(W2D8A1) + 1)
	if state == 0:
		return
	match state:
		1, 2, 3, 4, 5:  # .Init<colour>MusicBox: 16 loops, its action 1
			if r2(W2D8A1) < 16:
				return
			w2(W_TEMPLE_MUSIC_BOX_1 + (state - 1) * 2, 0x01)
			_music_boxes_next()
		6, 13:  # .Reset
			w2(W2D8A0, 0)
			w2(W2D8A1, 0)
		7:
			_music_boxes_next()
		8, 9, 10, 11, 12:  # .Deinit<colour>MusicBox: at its circle's 16th step, its object and action cleared
			var obj: int = scene_obj(8 + state - 8)
			if rd(obj + W_SCENE_OBJ_UNK7) != 16:
				return
			wr(obj + SCENE_OBJ_STATE, 0)
			w2(W_TEMPLE_MUSIC_BOX_1 + (state - 8) * 2, 0)
			_music_boxes_next()
		_:
			_note("HandleTempleMusicBoxes state %d (past its jumptable)" % state)


## HandleTempleMusicBoxes.Next: w2d8a1 cleared, w2d8a0 one on.
func _music_boxes_next() -> void:
	w2(W2D8A1, 0)
	w2(W2D8A0, r2(W2D8A0) + 1)


## HandleTempleMusicBoxNHover (`box` 0 to 4: scene objects 8 to 12 in states 3 to 7): by its action, set
## up at ($50, $4e), then up and left (y 2 lines, x 1 a loop) to y $2c (the music, after the last, not
## ported), then circling (Data_ad654).
func _handle_temple_music_box_hover(box: int) -> void:
	var at: int = W_TEMPLE_MUSIC_BOX_1 + box * 2
	var action: int = r2(at)
	if action == 0:
		return
	var number: int = 8 + box
	var obj: int = scene_obj(number)
	match action:
		1:  # .Init (InitTempleSceneMusicBox)
			wr(obj + SCENE_OBJ_Y, 0x50)
			wr(obj + SCENE_OBJ_X, 0x4E)
			set_scene_obj_state(number, 0x03 + box)
			_music_box_next(at)
		2:  # .MoveUpLeft (MoveMusicBoxUpLeft)
			wr(obj + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X) - 1)
			wr(obj + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y) - 2)
			if rd(obj + SCENE_OBJ_Y) == 0x2C:
				_music_box_next(at)
		3:  # .MoveCircle
			apply_ow_movement(obj, DATA_AD654, PROLOGUE_BANK)
		_:
			_note("a temple music box's action %d (InvalidMusicBoxAction)" % action)


## Func_ad557: the box's counter cleared, its action one on.
func _music_box_next(at: int) -> void:
	w2(at + 1, 0)
	w2(at, r2(at) + 1)


## HandleHiddenFigureReveal: Wario's panic run; the music (not ported), the run stopped (w2d892 3) and
## awaited, 20 loops on Wario panics, 40 on jumps (his state set directly), and once he looks back on.
func _handle_hidden_figure_reveal() -> void:
	handle_temple_wario_panic()
	w2(W2D891, r2(W2D891) + 1)
	var counter: int = r2(W2D891)
	match r2(W2D890):
		0:
			_sub_next()
		1:  # .StopPanicRun
			w2(W2D892, 0x03)
			_sub_next()
		2:
			if r2(W2D894) == 0:
				_sub_next()
		3:
			if counter < 20:
				return
			set_scene_wario_state(SCENEWARIO_PANIC)
			_sub_next()
		4:
			if counter < 40:
				return
			w2(W_SCENE_WARIO_STATE, SCENEWARIO_PANIC_JUMP)
			_sub_next()
		5:
			_sub_wait_wario(SCENEWARIO_LOOK_BACK)
		6:
			_sub_done()
		var step:
			_note("HandleHiddenFigureReveal step %d (past its jumptable)" % step)


## HandleTempleWarioPanic: while w2d894 is 1, by w2d892 (w2d893 counts): Wario runs right to x $80 and
## left to $20 and again, until stopped (w2d892 set to 3: on his next run right), then left to the
## centre ($50), 20 loops on turns his back, and once he looks back it is over (w2d892 to w2d894 cleared).
func handle_temple_wario_panic() -> void:
	if r2(W2D894) != 0x01:
		return
	w2(W2D893, r2(W2D893) + 1)
	match r2(W2D892):
		0:  # .PanicRunRight
			set_scene_wario_state(SCENEWARIO_PANIC_RUN_RIGHT)
			_panic_next()
		1, 4:
			_panic_move_right()
		2:  # .MoveLeft
			if not _walk_scene_wario_to(0x20, false):
				return
			set_scene_wario_state(SCENEWARIO_PANIC_RUN_RIGHT)
			w2(W2D892, r2(W2D892) - 1)
			w2(W2D893, 0)
		3:  # .PanicRunUntilMovingRight
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_PANIC_RUN_RIGHT:
				_panic_next()
				_panic_move_right()
				return
			if not _walk_scene_wario_to(0x20, false):
				return
			set_scene_wario_state(SCENEWARIO_PANIC_RUN_RIGHT)
			_panic_next()
		5:  # .MoveLeftToCentre
			if not _walk_scene_wario_to(0x50, false):
				return
			set_scene_wario_state(SCENEWARIO_IDLE_LEFT)
			_panic_next()
		6:  # .TurnBack
			if r2(W2D893) < 20:
				return
			set_scene_wario_state(SCENEWARIO_TURN_BACK_LEFT)
			_panic_next()
		7:  # .WaitUntilLookBackThenFinish
			if r2(W_SCENE_WARIO_STATE) != SCENEWARIO_LOOK_BACK:
				return
			w2(W2D894, 0)
			w2(W2D893, 0)
			w2(W2D892, 0)
		var step:
			_note("HandleTempleWarioPanic step %d (past its jumptable)" % step)


## HandleTempleWarioPanic.MoveRight: to x $80, then running left.
func _panic_move_right() -> void:
	if not _walk_scene_wario_to(0x80, true):
		return
	set_scene_wario_state(SCENEWARIO_PANIC_RUN_LEFT)
	_panic_next()


## HandleTempleWarioPanic.Next: w2d892 one on, w2d893 cleared.
func _panic_next() -> void:
	w2(W2D892, r2(W2D892) + 1)
	w2(W2D893, 0)


## HandleTempleShakeScene: Wario's panic and the shake (HandleTempleShakeAndRocks), then by w2d890: 90
## loops before a small shake (w2d896 2), six small rocks, Wario's exclamation mark (wCurSceneObj above
## him, state 2) and its end, 45 loops, he looks around and forward, the shake stopped and the small
## rocks gone, a big shake ($0b), ten large rocks (7 to 10 with their circle's step cleared), Wario's
## jump (not scrolled), his look back, 8 loops on the panic run (w2d894 1), the reveal's next step.
func handle_temple_shake_scene() -> void:
	handle_temple_wario_panic()
	handle_temple_shake_and_rocks()
	w2(W2D891, r2(W2D891) + 1)
	var counter: int = r2(W2D891)
	var step: int = r2(W2D890)
	match step:
		0:  # .StartShake
			if counter < 90:
				return
			w2(W2D896, 0x02)
			_sub_next()
		1, 2, 3, 4, 5, 6:  # .InitSmallRock1 to 6
			if counter < [16, 8, 20, 8, 16, 8][step - 1]:
				return
			_init_temple_rock(step, 0x01)
		7:  # .ShowExclamationMark (a sound, not ported)
			if counter < 60:
				return
			wr(scene_obj(0) + SCENE_OBJ_Y, r2(W_SCENE_WARIO) - 0x1C)
			wr(scene_obj(0) + SCENE_OBJ_X, r2(W_SCENE_WARIO_X_COORD))
			set_scene_obj_state(0, 0x02)
			_sub_next()
		8:  # .WaitExclamationMark
			if rd(scene_obj(0) + SCENE_OBJ_STATE) == 0:
				_sub_next()
		9:
			_sub_wait(45)
		10:
			set_scene_wario_state(SCENEWARIO_LOOK_AROUND)
			_sub_next()
		11:
			_sub_wait_wario(SCENEWARIO_LOOK_FORWARD)
		12:  # .StopShakeAndDeinitRocks
			w2(W2D896, 0x01)
			for rock: int in NUM_FALLING_TEMPLE_ROCKS:
				w2(temple_rock(rock + 1) + TEMPLE_ROCK_SIZE, 0x00)
			_sub_next()
		13:  # .WaitUntilRocksDeinit
			var actions: int = 0
			for rock: int in NUM_FALLING_TEMPLE_ROCKS:
				actions += r2(temple_rock(rock + 1))
			if (actions & 0xFF) == 0:
				_sub_next()
		14:  # .StartBigShake
			w2(W2D896, 0x0B)
			_sub_next()
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24:  # .InitLargeRock1 to 10
			var rock: int = step - 14
			if counter < [20, 4, 10, 4, 10, 10, 30, 8, 10, 8][rock - 1]:
				return
			if rock >= 7:
				wr(scene_obj(rock + 1) + W_SCENE_OBJ_UNK7, 0)
			_init_temple_rock(rock, 0x02)
		25:  # .PanicJump
			w2(W_SCENE_WARIO_IGNORE_SCROLL, 1)
			set_scene_wario_state(SCENEWARIO_PANIC_JUMP)
			_sub_next()
		26:
			_sub_wait_wario(SCENEWARIO_LOOK_BACK)
		27:  # .StopShake
			if counter < 8:
				return
			w2(W2D894, 0x01)
			_sub_next()
		28:
			_sub_done()
		_:
			_note("HandleTempleShakeScene step %d (past its jumptable)" % step)


## wTempleRock1 to wTempleRock10 by number.
static func temple_rock(rock: int) -> int:
	return W_TEMPLE_ROCKS + (rock - 1) * TEMPLE_ROCK_STRUCT_LENGTH


## .InitTempleRock: the rock's action 1, its counter cleared, its size (1 small, 2 large); the next step.
func _init_temple_rock(rock: int, size: int) -> void:
	var at: int = temple_rock(rock)
	w2(at, 0x01)
	w2(at + 1, 0x00)
	w2(at + TEMPLE_ROCK_SIZE, size)
	_sub_next()
