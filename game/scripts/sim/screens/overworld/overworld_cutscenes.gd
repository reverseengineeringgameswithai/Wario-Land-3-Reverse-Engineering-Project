class_name OverworldCutscenes
extends OverworldScenes
## The map's cutscenes (OverworldStateTable's sub-states $11 to $15, src/engine/overworld/cutscene/ and
## bank27.asm), translated (WL3-052): _InitCutscene (the event's palettes, graphics, BG maps, and
## objects: CutsceneInitFunctions), its fade in, UpdateCutscene (DoCutsceneFunc: the event's steps by
## w2d013, counted in w2d014, its objects animated and drawn from banks $2f, $1a, and $62), its fade
## out, and Func_80db1 (InitOverworld.after_cutscene: the event's scene, or the map, next). So far the
## cutscenes of the owner's movies (the cut tree, the north gate, the tornado, the rainstorm, the
## elevator, the seeds, the tower, the cart wheels) and the music boxes'; the others are noted as not
## ported. VBlank_Cutscene's RAM writes run after each loop; what they write to VRAM, the palettes,
## and the LCD is recorded for drawing.

const CUTSCENE_OBJ_BANK: int = 0x2F  # "Overworld OAM 2": the cutscene objects' framesets and OAM tables
const CUTSCENE_BG_MAPS_BANK: int = 0x2E  # "Cutscene BG Maps", also the cutscenes' palettes (Pals_b8000 on)

const W_LCDC_FLAGS_TO_FLIP: int = 0xD800  # also wCollectionRow
const W2D801: int = 0xD801
const W_CUTSCENE_WY: int = 0xD022
const W_CUTSCENE_WX: int = 0xD023
const W_PAL_CONFIG_2_INDEX: int = 0xD0D7
const W_PAL_CONFIG_2_SOURCE_HI: int = 0xD0D9  # high byte, then low
const W_TEMP_OB_PALS: int = 0xC140

const LCDC_BG_MAP: int = 0x08
## _InitCutscene's LCDC (LCDC_BG_ON | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_9C00 | LCDC_ON).
const LCDC_CUTSCENE: int = 0xC7
const BGPI_PALETTE_1: int = 0x80 | 0x08
const OBPI_PALETTE_0: int = 0x80
const EVENTS_WITH_CUTSCENES: Array = [0x01, 0x02, 0x03, 0x04, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x0E,
		0x10, 0x11, 0x13, 0x14, 0x15, 0x17, 0x18, 0x19, 0x1B, 0x1D, 0x1E, 0x1F, 0x21, 0x22, 0x24, 0x25, 0x27, 0x30,
		0x37, 0x38, 0x39, 0x3A, 0x3C, 0x3D, 0x43, 0x44, 0x49, 0x4A, 0x4C, 0x4E, 0x4F, 0x51, 0x54, 0x55, 0x56, 0x57,
		0x58]
## The V-Blank function the cutscenes set (VBlank_Cutscene), numbered by its sub-state.
const VBLANK_CUTSCENE: int = 0x11

# The cutscenes' graphics ([bank, address], decompressed to VRAM).
const CUTSCENES_1_GFX: Array = [0x28, 0x4000]
const CUTSCENES_2_GFX: Array = [0x28, 0x4B44]
const CUTSCENES_3_GFX: Array = [0x28, 0x56CB]
const CUTSCENES_5_GFX: Array = [0x28, 0x6FFB]
const CUTSCENES_6_GFX: Array = [0x29, 0x4000]
const CUTSCENES_8_GFX: Array = [0x29, 0x5EBD]
const CART_GFX: Array = [0x6A, 0x5B78]
# InitCutscene27's tiles for LoadFarTiles ([bank, address]: $80 tiles to v0Tiles2 or v1Tiles2).
const LEVEL_MAIN_TILES_14: Array = [0x52, 0x7000]
const SPECIAL_TILES_1: Array = [0x4E, 0x4800]
# The cutscenes' BG maps (bank $2e): tilemap, attrmap.
const CUTSCENE_01_MAPS: Array = [0x5100, 0x5113]
const CUTSCENE_02_MAPS: Array = [0x514A, 0x519B]
const CUTSCENE_03_MAPS: Array = [0x51E7, 0x5235]
const CUTSCENE_04_MAPS: Array = [0x526D, 0x52C2]
const CUTSCENE_06_MAPS: Array = [0x53C8, 0x5424]
const CUTSCENE_07_MAPS: Array = [0x5475, 0x54D1]
const CUTSCENE_08_MAPS: Array = [0x551F, 0x556D]
const CUTSCENE_11_MAPS: Array = [0x5816, 0x5859]
# The cutscenes' palettes (bank $2e).
const PALS_B8000: int = 0x4000
const PALS_B8040: int = 0x4040
const PALS_B8080: int = 0x4080
const PALS_B8200: int = 0x4200
const PALS_B8240: int = 0x4240
const PALS_B88C0: int = 0x48C0
const PALS_B8900: int = 0x4900
const PALS_B89C0: int = 0x49C0
const PALS_B8A00: int = 0x4A00
const PALS_B8A80: int = 0x4A80
const PALS_B8C00: int = 0x4C00
const PALS_B8EC0: int = 0x4EC0
## The music boxes' object palettes (InitCutscene08, 10, 17, 1d, 25), by event.
const MUSIC_BOX_PALS: Dictionary = {0x08: 0x4AC0, 0x10: 0x4B00, 0x17: 0x4B40, 0x1D: 0x4B80, 0x25: 0x4BC0}
## The music boxes' first object states (Cutscene08Func, 10, 17, 1d, 25's b), by event.
const MUSIC_BOX_STATES: Dictionary = {0x08: 0x01, 0x10: 0x03, 0x17: 0x05, 0x1D: 0x07, 0x25: 0x09}
const PALS_CC5C0: Array = [0x33, 0x45C0]
const INIT_CUTSCENE_27_PALETTE: int = 0x4572  # bank $27
# The objects' tables in bank $27 (state - 1 -> frameset), framesets and OAM tables in bank $2f.
const FUNC_9F0E0_FRAMESETS: int = 0x7110
const FUNC_9F11E_FRAMESETS: int = 0x7140
const FUNC_9F146_FRAMESETS: int = 0x7170
const FUNC_9F174_FRAMESETS: int = 0x71C4
const FUNC_9F2F3_FRAMESETS: int = 0x731D  # its framesets in bank $1a
const FUNC_9F3CD_FRAMESETS: int = 0x73E8
const FUNC_9FC1D_FRAMESETS: int = 0x7C44
const FRAMESET_BC1E8: int = 0x41E8
const FRAMESET_BC1F3: int = 0x41F3
const FRAMESET_BD1B4: int = 0x51B4
const OAM_BC000: int = 0x4000
const OAM_BC122: int = 0x4122
const OAM_BC1F6: int = 0x41F6
const OAM_BCFB3: int = 0x4FB3
const OAM_BD1FD: int = 0x51FD
const OAM_BD377: int = 0x5377
const OAM_BD453: int = 0x5453
const OAM_BD46F: int = 0x546F
const OAM_BDDCF: int = 0x5DCF
const OAM_188279: Array = [0x62, 0x4279]


# --- the sub-states ---

## InitCutscene, _InitCutscene (SST_OVERWORLD_CUTSCENE): the LCD off, the virtual OAM and the cutscene's
## RAM (from wLCDCFlagsToFlip, $30 bytes) cleared, VBlank_Cutscene set, the event's cutscene set up
## (InitEventCutscene), the scroll and the cutscene's counters cleared; the LCD on with the flips its
## init asked for, then cleared; the next sub-state.
func init_cutscene() -> void:
	disable_lcd()
	clear_virtual_oam()
	fill(W_LCDC_FLAGS_TO_FLIP, 0x30, 0)
	vblank_func = VBLANK_CUTSCENE
	init_event_cutscene()
	sim.wSCY = 0
	sim.wSCX = 0
	for at: int in [W2D801, W2D013, W2D014, W_PAL_CONFIG_1_TOTAL_STEPS, W_PAL_CONFIG_2_TOTAL_STEPS]:
		w2(at, 0)
	set_lcdc(LCDC_CUTSCENE ^ r2(W_LCDC_FLAGS_TO_FLIP))
	w2(W_LCDC_FLAGS_TO_FLIP, 0)
	sim.wSubState = byte(sim.wSubState + 1)


## UpdateCutscene: the cutscene skipped if able (SkipCutsceneIfAble), else DoCutsceneFunc and the
## virtual OAM's unused entries cleared.
func update_cutscene() -> void:
	if _skip_cutscene_if_able():
		return
	do_cutscene_func()
	clear_unused_virtual_oam()


## UpdateCutscene.SkipCutsceneIfAble: a cutscene played again from the top bar (a bar open), past its
## first step, B ends it (the next sub-state; the sound stopped, not ported). True when skipped.
func _skip_cutscene_if_able() -> bool:
	if r2(W_OW_BARS_STATE) == 0 or r2(W2D013) < 0x01:
		return false
	if (sim.wJoypadPressed & PAD_B) == 0:
		return false
	sim.wSubState = byte(sim.wSubState + 1)
	return true


## Func_80db1: InitOverworld.after_cutscene.
func func_80db1() -> void:
	_after_cutscene()  # InitOverworld.after_cutscene


## VBlank_Cutscene's function, run after the loop (V-Blank): the scroll, the window (wCutsceneWX,
## wCutsceneWY), rLCDC's bits in wLCDCFlagsToFlip flipped, ApplyPalConfig1 and ApplyPalConfig2, the
## OAM; its RAM writes: wLCDCFlagsToFlip (once flipped), wPalConfig1's and wPalConfig2's registers
## (once applied) cleared.
func vblank_cutscene() -> void:
	set_window(r2(W_CUTSCENE_WX), r2(W_CUTSCENE_WY))
	if r2(W_LCDC_FLAGS_TO_FLIP) != 0:
		register_writes.append(["lcdc_flip", r2(W_LCDC_FLAGS_TO_FLIP)])
	if r2(W_PAL_CONFIG_1) != 0:
		record_pal_config(W_PAL_CONFIG_1)
	if r2(W_PAL_CONFIG_2) != 0:
		record_pal_config(W_PAL_CONFIG_2)
	for at: int in [W_LCDC_FLAGS_TO_FLIP, W_PAL_CONFIG_1, W_PAL_CONFIG_2]:
		if r2(at) != 0:
			w2(at, 0)


# --- the cutscenes' set-ups (bank $27) ---

## InitEventCutscene: wLCDCFlagsToFlip and the virtual OAM cleared, the cutscenes' common tiles
## (Cutscenes6Gfx to v1Tiles0, not for the prologue), wEventWithCutscene, then the event's init
## (CutsceneInitFunctions; NoInitCutscene clears wEventWithCutscene).
func init_event_cutscene() -> void:
	w2(W_LCDC_FLAGS_TO_FLIP, 0)
	clear_virtual_oam()
	var event: int = r2(W_CUR_EVENT)
	if event != EVENT_PROLOGUE:
		_load_cutscene_gfx(CUTSCENES_6_GFX, 1)
	w2(W_EVENT_WITH_CUTSCENE, event)
	screen_loads.append(["cutscene", event])
	match event:
		0x02:
			_init_cutscene_02()
		0x03:
			_init_cutscene_03()
		0x04:
			_init_cutscene_04()
		0x06:
			_init_cutscene_06()
		0x07:
			_init_cutscene_07()
		0x08, 0x10, 0x17, 0x1D, 0x25:  # InitCutscene08, 10, 17, 1d, 25
			_func_9c25f(MUSIC_BOX_PALS[event])
		0x09:
			_init_cutscene_09()
		0x0A:
			_init_cutscene_0a()
		0x27:
			_init_cutscene_27()
		_:
			if event >= NUM_EVENTS:
				_note("InitEventCutscene event $%02x (past CutsceneInitFunctions)" % event)
			elif event == EVENT_PROLOGUE:
				_init_prologue()
			elif event in EVENTS_WITH_CUTSCENES:
				_note("InitCutscene%02x (not ported)" % event)
			else:
				w2(W_EVENT_WITH_CUTSCENE, 0)  # NoInitCutscene


## LoadFarPalsToTempPals1 and LoadFarPalsToTempPals2: 8 palettes each from bank $2e.
func _load_cutscene_pals(pals_1: int, pals_2: int) -> void:
	copy_rom(CUTSCENE_BG_MAPS_BANK, pals_1, W_TEMP_PALS_1, 8 * 8)
	copy_rom(CUTSCENE_BG_MAPS_BANK, pals_2, W_TEMP_PALS_2, 8 * 8)


## A decompress_tiles0 or decompress_tiles1 of cutscene graphics ([bank, address]) to VRAM bank
## `vram_bank` from `destination` (v0Tiles0 by default).
func _load_cutscene_gfx(gfx: Array, vram_bank: int = 0, destination: int = 0x8000) -> void:
	decompress_to_vram(int(gfx[0]), int(gfx[1]), vram_bank, destination)


## LoadCutscenes1Gfx_Vram0, LoadCutscenes2Gfx, LoadCutscenes3Gfx, LoadCutscenes8Gfx_Vram0: the
## graphics to v0Tiles0, then Cutscenes5Gfx to v0Tiles2 (LoadCutscenes5Gfx_Vram0).
func _load_cutscenes_gfx_and_5(gfx: Array) -> void:
	_load_cutscene_gfx(gfx)
	_load_cutscene_gfx(CUTSCENES_5_GFX, 0, 0x9000)


## LoadFarTiles: $80 tiles from ([bank, address]) to VRAM bank `vram_bank`'s v0Tiles2 ($9000).
func _load_far_tiles(tiles: Array, vram_bank: int) -> void:
	vram_writes.append(["rom", vram_bank, 0x9000, int(tiles[0]), int(tiles[1]), 0x80 * 0x10])


## LoadCutsceneBGMaps* (LoadCutsceneAttrmap0/1, LoadCutsceneTilemap0/1; also the decompress_attrmap
## and decompress_tilemap of a cutscene's maps): the attrmap, then the tilemap ([tilemap, attrmap] in
## bank $2e), to BG map 0 or 1 (`bg_map` $9800 or $9c00).
func _load_cutscene_bg_maps(maps: Array, bg_map: int) -> void:
	decompress_to_vram(CUTSCENE_BG_MAPS_BANK, int(maps[1]), 1, bg_map)
	decompress_to_vram(CUTSCENE_BG_MAPS_BANK, int(maps[0]), 0, bg_map)


## InitCutscene02 (the cut tree).
func _init_cutscene_02() -> void:
	_load_cutscene_pals(PALS_B8200, PALS_B8C00)
	_load_cutscenes_gfx_and_5(CUTSCENES_1_GFX)
	_load_cutscene_bg_maps(CUTSCENE_01_MAPS, 0x9800)
	_load_cutscene_bg_maps(CUTSCENE_02_MAPS, 0x9C00)


## InitCutscene03 (the north gate).
func _init_cutscene_03() -> void:
	_load_cutscene_pals(PALS_B8240, PALS_B88C0)
	_load_cutscenes_gfx_and_5(CUTSCENES_3_GFX)
	_load_cutscene_bg_maps(CUTSCENE_07_MAPS, 0x9800)


## InitCutscene04 (the tornado).
func _init_cutscene_04() -> void:
	_load_cutscene_pals(PALS_B8200, PALS_B8EC0)
	_load_cutscenes_gfx_and_5(CUTSCENES_8_GFX)
	_load_cutscene_bg_maps(CUTSCENE_01_MAPS, 0x9800)
	_load_cutscene_bg_maps(CUTSCENE_02_MAPS, 0x9C00)


## InitCutscene06 (the rainstorm), then Func_9d01a: wSceneObj2 at (72, 80) in state 1, drawn.
func _init_cutscene_06() -> void:
	_load_cutscenes_gfx_and_5(CUTSCENES_3_GFX)
	_load_cutscene_bg_maps(CUTSCENE_08_MAPS, 0x9800)
	_load_cutscene_pals(PALS_B8080, PALS_B8900)
	_set_cutscene_obj(2, 72, 80, 0x01)
	_func_9f11e()


## InitCutscene07 (the elevator), then Func_9d158: wSceneObj2 at (88, 84) in state 9, wSceneObj3 at
## (67, 64) in state 3, wSceneObj4 at (88, 84) in state $0a, drawn.
func _init_cutscene_07() -> void:
	_load_cutscenes_gfx_and_5(CUTSCENES_1_GFX)
	_load_cutscene_bg_maps(CUTSCENE_06_MAPS, 0x9800)
	_load_cutscene_pals(PALS_B8000, PALS_B89C0)
	_set_cutscene_obj(2, 88, 84, 0x09)
	_set_cutscene_obj(3, 67, 64, 0x03)
	_set_cutscene_obj(4, 88, 84, 0x0A)
	_func_9f174()


## Func_9c25f (InitCutscene08, 10, 17, 1d, 25: a music box): its object palettes `pals_2`, BG map 1
## flipped in (wLCDCFlagsToFlip).
func _func_9c25f(pals_2: int) -> void:
	_load_cutscene_pals(PALS_B8200, pals_2)
	w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
	_load_cutscenes_gfx_and_5(CUTSCENES_2_GFX)
	_load_cutscene_bg_maps(CUTSCENE_01_MAPS, 0x9800)
	_load_cutscene_bg_maps(CUTSCENE_04_MAPS, 0x9C00)


## InitCutscene09 (the seeds).
func _init_cutscene_09() -> void:
	_load_cutscene_pals(PALS_B8200, PALS_B8A80)
	_load_cutscenes_gfx_and_5(CUTSCENES_2_GFX)
	_load_cutscene_bg_maps(CUTSCENE_03_MAPS, 0x9800)


## InitCutscene0a (the tower), then Func_9d0e6: wSceneObj1's y 3 (the objects' sprites copied to
## wCurSceneObj), wSceneObj2 at (130, 113) in state 1, wSceneObj3 at (130, 47) in state 2, drawn.
func _init_cutscene_0a() -> void:
	_load_cutscene_pals(PALS_B8040, PALS_B8A00)
	_load_cutscenes_gfx_and_5(CUTSCENES_1_GFX)
	_load_cutscene_bg_maps(CUTSCENE_03_MAPS, 0x9800)
	wr(W_SCENE_OBJ_1 + SCENE_OBJ_Y, 0x03)
	_set_cutscene_obj(2, 130, 113, 0x01)
	_set_cutscene_obj(3, 130, 47, 0x02)
	_func_9f146()


## InitCutscene27 (the cart wheels): the level's tiles (LevelMainTiles14 to VRAM 0's, SpecialTiles1 to
## VRAM 1's v0Tiles2), its maps, its palettes (Pals_cc5c0), the cart's tiles (CartGfx to VRAM 1's
## $8800), the cart's palette (.palette, wTempPals2 palette 6), then Func_9d64b: wSceneObj2 at (86, 88)
## in state 1, drawn.
func _init_cutscene_27() -> void:
	_load_far_tiles(LEVEL_MAIN_TILES_14, 0)
	_load_far_tiles(SPECIAL_TILES_1, 1)
	_load_cutscene_bg_maps(CUTSCENE_11_MAPS, 0x9800)
	copy_rom(int(PALS_CC5C0[0]), int(PALS_CC5C0[1]), W_TEMP_PALS_1, 8 * 8)
	decompress_to_vram(int(CART_GFX[0]), int(CART_GFX[1]), 1, 0x8800)  # decompress_tiles1 to v0Tiles1
	copy_rom(CUTSCENE_BANK, INIT_CUTSCENE_27_PALETTE, W_TEMP_PALS_2 + 6 * 8, 8)
	_set_cutscene_obj(2, 86, 88, 0x01)
	_func_9f2f3()


# --- the cutscenes' steps (bank $27) ---

## DoCutsceneFunc: the d-pad's repeat, w2d014 counted, then wEventWithCutscene's cutscene.
func do_cutscene_func() -> void:
	process_dpad_repeat()
	w2(W2D014, r2(W2D014) + 1)
	var event: int = r2(W_EVENT_WITH_CUTSCENE)
	if event >= NUM_EVENTS:
		_note("DoCutsceneFunc.OutOfBoundsCutscene (debug_nop: hangs)")
		return
	match event:
		0x02:
			_cutscene_02_func()
		0x03:
			_cutscene_03_func()
		0x04:
			_cutscene_04_func()
		0x06:
			_cutscene_06_func()
		0x07:
			_cutscene_07_func()
		0x08, 0x10, 0x17, 0x1D, 0x25:  # Cutscene08Func, 10, 17, 1d, 25
			_func_9d6f0(MUSIC_BOX_STATES[event])
		0x09:
			_cutscene_09_func()
		0x0A:
			_cutscene_0a_func()
		0x27:
			_cutscene_27_func()
		_:
			if event == EVENT_PROLOGUE:
				_prologue_func()
			elif event in EVENTS_WITH_CUTSCENES:
				_note("Cutscene%02xFunc (not ported)" % event)
			else:
				_note("DoCutsceneFunc.InvalidCutscene $%02x (debug_nop: hangs)" % event)


## InitPrologue and PrologueFunc (EVENT_PROLOGUE): OverworldPrologue's.
func _init_prologue() -> void:
	_note("InitPrologue (not ported)")


func _prologue_func() -> void:
	_note("PrologueFunc (not ported)")


## AdvanceCutsceneFunc: w2d014 cleared, the next step (w2d013).
func _advance_cutscene_func() -> void:
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## WaitCutsceneFunc (StartCutsceneDelay: 30): the next step once w2d014 reaches `frames`.
func _wait_cutscene_func(frames: int) -> void:
	if r2(W2D014) >= frames:
		_advance_cutscene_func()


## EndCutscene (EndCutsceneDelay_20Frames to _120Frames): once w2d014 reaches `frames`, Func_9cd16.
func _end_cutscene(frames: int) -> void:
	if r2(W2D014) >= frames:
		_func_9cd16()


## Func_9cd16: the cutscene over: the next sub-state (the sound stopped, not ported).
func _func_9cd16() -> void:
	sim.wSubState = byte(sim.wSubState + 1)


## A cutscene object at (y, x) in `state` (SetSceneObjState: its animation restarted).
func _set_cutscene_obj(number: int, y: int, x: int, state: int) -> void:
	wr(scene_obj(number) + SCENE_OBJ_Y, y)
	wr(scene_obj(number) + SCENE_OBJ_X, x)
	set_scene_obj_state(number, state)


## A cutscene object's coordinate (SCENE_OBJ_Y or SCENE_OBJ_X) moved by `step`; returns the new one.
func _move_cutscene_obj(number: int, coord: int, step: int) -> int:
	var at: int = scene_obj(number) + coord
	wr(at, rd(at) + step)
	return rd(at)


func _cutscene_obj_state(number: int) -> int:
	return rd(scene_obj(number) + SCENE_OBJ_STATE)


func _note_past_steps(name: String) -> void:
	_note("%s step $%02x (past its table)" % [name, r2(W2D013)])


## Cutscene02Func (EVENT_CUT_TREE): the axe (wSceneObj2, with wCurSceneObj's sprite while
## wSceneObj1's y is 3) up and left to y $60, the speed lines (BG map 1) flipped in and out, the cut
## (until its state ends); then OWCutTree.
func _cutscene_02_func() -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)  # StartCutsceneDelay
		0x01:  # .ShowAxe
			_set_cutscene_obj(2, SCREEN_HEIGHT_PX, 0x6C, 0x01)
			wr(W_SCENE_OBJ_1 + SCENE_OBJ_Y, 0x03)
			_advance_cutscene_func()
		0x02:  # .RaiseAxe: up and left (a sound at y $86, Func_9ce1f, not ported)
			var y: int = _move_cutscene_obj(2, SCENE_OBJ_Y, -1)
			_move_cutscene_obj(2, SCENE_OBJ_X, -1)
			if y == 0x60:
				_advance_cutscene_func()
		0x03, 0x05, 0x07:  # .Wait30, .Wait60, .Wait16
			_wait_cutscene_func([30, 60, 16][(r2(W2D013) - 3) >> 1])
		0x04:  # .ShowSpeedLines
			w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
			_advance_cutscene_func()
		0x06:  # .HideAxe
			w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
			set_scene_obj_state(2, 0x00)
			wr(W_SCENE_OBJ_1 + SCENE_OBJ_Y, 0x00)
			_advance_cutscene_func()
		0x08:  # .ShowCut (a sound, not ported)
			_set_cutscene_obj(2, 96, 66, 0x02)
			_advance_cutscene_func()
		0x09:  # .WaitCutAnimation
			if _cutscene_obj_state(2) == 0:
				_advance_cutscene_func()
		0x0A:
			_end_cutscene(40)
		_:
			_note_past_steps("Cutscene02Func")
	_ow_cut_tree()


## Cutscene03Func (EVENT_OPEN_NORTH_GATE): wSceneObj2 and wSceneObj3 move toward each other every
## other loop until wSceneObj2's x is 79, their states set in steps between waits (wSceneObj3 until its
## state ends), wSceneObj2 down every other loop to y $54, the fade to white (Func_9cd8d); then
## Func_9f0e0.
func _cutscene_03_func() -> void:
	var counter: int = r2(W2D014)
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9cf36
			_set_cutscene_obj(2, 59, 40, 0x01)
			_set_cutscene_obj(3, 59, 120, 0x02)
			_advance_cutscene_func()
		0x02:  # .Func_9cf59: every other loop
			if (counter & 0x01) == 0:
				_move_cutscene_obj(3, SCENE_OBJ_X, -1)
				if _move_cutscene_obj(2, SCENE_OBJ_X, 1) == 79:
					_advance_cutscene_func()
		0x03, 0x05, 0x0C, 0x10:  # .Wait30_1 to _4
			_wait_cutscene_func(30)
		0x04:  # .Func_9cf71 (a sound, not ported)
			set_scene_obj_state(2, 0x03)
			wr(scene_obj(2) + SCENE_OBJ_X, 80)
			wr(scene_obj(3) + SCENE_OBJ_STATE, 0x00)
			_advance_cutscene_func()
		0x06:  # .Func_9cf92 (a sound, not ported)
			_set_cutscene_obj(3, 59, 80, 0x05)
			_advance_cutscene_func()
		0x07:  # .Func_9cfad
			if _cutscene_obj_state(3) == 0:
				_advance_cutscene_func()
		0x08, 0x0A:  # .Wait60_1, _2
			_wait_cutscene_func(60)
		0x09:  # .Func_9cfba: every other loop
			if (counter & 0x01) != 0 and _move_cutscene_obj(2, SCENE_OBJ_Y, 1) == 0x54:
				_advance_cutscene_func()
		0x0B:  # .Func_9cfce (a sound, not ported)
			set_scene_obj_state(2, 0x04)
			_move_cutscene_obj(2, SCENE_OBJ_X, 1)
			_advance_cutscene_func()
		0x0D:  # .Func_9cfea
			wr(scene_obj(3) + SCENE_OBJ_Y, rd(scene_obj(2) + SCENE_OBJ_Y))
			wr(scene_obj(3) + SCENE_OBJ_X, rd(scene_obj(2) + SCENE_OBJ_X))
			set_scene_obj_state(3, 0x06)
			_advance_cutscene_func()
		0x0E:  # .Func_9d001
			if _cutscene_obj_state(3) == 0x07:
				_advance_cutscene_func()
		0x0F:  # .Func_9d00a (a sound, not ported)
			_advance_cutscene_func()
		0x11:
			func_85046()  # Func_9cd8d
		0x12:
			_end_cutscene(40)
		_:
			_note_past_steps("Cutscene03Func")
	_func_9f0e0()


## Cutscene04Func (EVENT_EXPEL_TORNADO): wSceneObj2 and then wSceneObj3 rise in from below, then
## BG map 1 flipped in (wCollectionRow, wLCDCFlagsToFlip's byte); then Func_9f3cd.
func _cutscene_04_func() -> void:
	var counter: int = r2(W2D014)
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9db1b
			if counter >= 0x14:
				_set_cutscene_obj(2, 128, 80, 0x02)
				_advance_cutscene_func()
		0x02:  # .Func_9db32 (a sound at y $70, Func_9ce1f, not ported)
			if _move_cutscene_obj(2, SCENE_OBJ_Y, -1) == 0x4A:
				_advance_cutscene_func()
		0x03:  # .Func_9db46
			if counter >= 0x32:
				_set_cutscene_obj(3, 128, 80, 0x03)
				_advance_cutscene_func()
		0x04:  # .Func_9db5d (a sound, not ported)
			if _move_cutscene_obj(3, SCENE_OBJ_Y, -1) == 0x4A:
				_advance_cutscene_func()
		0x05:  # .Func_9db71
			set_scene_obj_state(2, 0x01)
			wr(scene_obj(3) + SCENE_OBJ_STATE, 0x00)
			w2(W_LCDC_FLAGS_TO_FLIP, LCDC_BG_MAP)
			_advance_cutscene_func()
		0x06:
			_end_cutscene(60)
		_:
			_note_past_steps("Cutscene04Func")
	_func_9f3cd()


## Cutscene06Func (EVENT_RAINSTORM): wSceneObj2 a pixel down or up every 4 loops for $20 loops, then
## up 1 to 3 pixels a loop until below y $20, then from (64, 80) in state 2 until its animation reaches
## state 3, then up a pixel every 4 loops to y $28 (wColourFadeDiff counting $0e loops for a sound);
## then Func_9f11e.
func _cutscene_06_func() -> void:
	var counter: int = r2(W2D014)
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d04b: every 4 loops a pixel down, or up while bit 2 is set (a sound first)
			if counter != 0x01 and (counter & 0x03) == 0:
				_move_cutscene_obj(2, SCENE_OBJ_Y, 0xFF if (counter & 0x04) != 0 else 0x01)
				if counter >= 0x20:
					_advance_cutscene_func()
		0x02, 0x04:  # .Func_9d071
			_wait_cutscene_func(30)
		0x03:  # .Func_9d076: up 1, 2, 3 pixels a loop by w2d014 (a sound first)
			if counter != 0x01:
				var step: int = 0xFF
				if counter >= 0x08:
					step -= 1
					if counter >= 0x10:
						step -= 1
				if _move_cutscene_obj(2, SCENE_OBJ_Y, step) < 0x20:
					_advance_cutscene_func()
		0x05:  # .Func_9d09c
			_set_cutscene_obj(2, 64, 80, 0x02)
			_advance_cutscene_func()
		0x06:  # .Func_9d0af
			if _cutscene_obj_state(2) == 0x03:
				w2(W_COLOUR_FADE_DIFF, 0)
				_advance_cutscene_func()
		0x07:  # .Func_9d0bc
			_wait_cutscene_func(100)
		0x08:  # .Func_9d0c1: .Func_9d0d3 (a sound every $0e loops, not ported), then every 4 loops up
			w2(W_COLOUR_FADE_DIFF, r2(W_COLOUR_FADE_DIFF) + 1)
			if r2(W_COLOUR_FADE_DIFF) >= 0x0E:
				w2(W_COLOUR_FADE_DIFF, 0)
			if (counter & 0x03) == 0 and _move_cutscene_obj(2, SCENE_OBJ_Y, -1) == 0x28:
				_advance_cutscene_func()
		0x09:
			_end_cutscene(40)
		_:
			_note_past_steps("Cutscene06Func")
	_func_9f11e()


## Cutscene07Func (EVENT_FIX_ELEVATOR): wSceneObj5's, 3's, 2's, and 4's states set in steps between
## waits (wSceneObj2's frame watched for 0 four times, wSceneObj4 until its state ends), then
## wSceneObj2 up a pixel a loop until below y $18; then Func_9f174. (Its sounds are not ported.)
func _cutscene_07_func() -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d1c5
			if r2(W2D014) >= 0x14:
				_set_cutscene_obj(5, 90, 56, 0x01)
				_advance_cutscene_func()
		0x02, 0x0F, 0x14:  # .Func_9d1e4, .Func_9d234, .Func_9d264
			_wait_cutscene_func(50)
		0x03:  # .Func_9d1e9
			set_scene_obj_state(5, 0x02)
			_advance_cutscene_func()
		0x04:  # .Func_9d1fc
			_wait_cutscene_func(30)
		0x05:  # .Func_9d201
			set_scene_obj_state(3, 0x04)
			_advance_cutscene_func()
		0x06, 0x11:  # .Func_9d20c, .Func_9d244
			_wait_cutscene_func(40)
		0x07:  # .Func_9d211
			set_scene_obj_state(2, 0x06)
			_advance_cutscene_func()
		0x08, 0x0A, 0x0C, 0x0E:  # .Func_9d21c
			if rd(scene_obj(2) + SCENE_OBJ_FRAME) == 0:
				_advance_cutscene_func()
		0x09, 0x0B, 0x0D:  # .Func_9d22c
			if rd(scene_obj(2) + SCENE_OBJ_FRAME) != 0:
				_advance_cutscene_func()
		0x10:  # .Func_9d239
			set_scene_obj_state(3, 0x05)
			_advance_cutscene_func()
		0x12:  # .Func_9d249
			set_scene_obj_state(4, 0x08)
			_advance_cutscene_func()
		0x13:  # .Func_9d25c
			if _cutscene_obj_state(4) == 0:
				_advance_cutscene_func()
		0x15:  # .Func_9d269
			_advance_cutscene_func()
		0x16:  # .Func_9d274
			if _move_cutscene_obj(2, SCENE_OBJ_Y, -1) < 0x18:
				_advance_cutscene_func()
		0x17:
			_end_cutscene(60)
		_:
			_note_past_steps("Cutscene07Func")
	_func_9f174()


## Func_9d6f0 (Cutscene08Func, 10, 17, 1d, 25: the music boxes, wSceneObj2's first state `state`):
## wSceneObj2 (with wCurSceneObj's sprites while wSceneObj1's y is 1) up a pixel a loop from y 176 to
## $62, then its next state between waits; then Func_9fc1d. (Its sounds are not ported.)
func _func_9d6f0(state: int) -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d70c
			_set_cutscene_obj(2, 176, 74, state)
			wr(W_SCENE_OBJ_1 + SCENE_OBJ_Y, 0x01)
			_advance_cutscene_func()
		0x02:  # .Func_9d723 (a sound at y $88, Func_9ce1f)
			if _move_cutscene_obj(2, SCENE_OBJ_Y, -1) == 0x62:
				_advance_cutscene_func()
		0x03:  # .Func_9d733
			_wait_cutscene_func(30)
		0x04:  # .Func_9d738
			set_scene_obj_state(2, _cutscene_obj_state(2) + 1)
			_advance_cutscene_func()
		0x05:  # .Func_9d744
			_wait_cutscene_func(50)
		0x06:  # .Func_9d749 (then the box's sound)
			_advance_cutscene_func()
		0x07:  # .Func_9d792
			_wait_cutscene_func(254)
		0x08:
			_end_cutscene(80)
		_:
			_note_past_steps("Func_9d6f0")
	_func_9fc1d()


## Cutscene09Func (EVENT_PLANT_SEEDS): wSceneObj2 (with wCurSceneObj's sprites while wSceneObj1's y
## is 1) up a pixel a loop from y 176 to $62; then Func_9fbfa.
func _cutscene_09_func() -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d6b6
			_set_cutscene_obj(2, 176, 74, 0x01)
			wr(W_SCENE_OBJ_1 + SCENE_OBJ_Y, 0x01)
			_advance_cutscene_func()
		0x02:  # .Func_9d6ce (a sound at y $88, Func_9ce1f, not ported)
			if _move_cutscene_obj(2, SCENE_OBJ_Y, -1) == 0x62:
				_advance_cutscene_func()
		0x03:
			_end_cutscene(60)
		_:
			_note_past_steps("Cutscene09Func")
	_func_9fbfa()


## Cutscene0aFunc (EVENT_RAISE_TOWER): wSceneObj2 and wSceneObj3 up and apart every other loop to
## y $63, a last step after a wait, then the fade to white (Func_9cd8d); then Func_9f146.
func _cutscene_0a_func() -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d126
			if (r2(W2D014) & 0x01) != 0 and _func_9d133() == 0x63:
				_advance_cutscene_func()
		0x02:  # .Func_9d140
			_wait_cutscene_func(50)
		0x03:  # .Func_9d145 (a sound, not ported)
			_func_9d133()
			_advance_cutscene_func()
		0x04:  # .Func_9d153
			_wait_cutscene_func(30)
		0x05:
			func_85046()  # Func_9cd8d
		0x06:
			_end_cutscene(20)
		_:
			_note_past_steps("Cutscene0aFunc")
	_func_9f146()


## Cutscene0aFunc.Func_9d133: wSceneObj2 a pixel up and left, wSceneObj3 to the same y and a pixel
## right; returns the y.
func _func_9d133() -> int:
	var y: int = byte(rd(scene_obj(2) + SCENE_OBJ_Y) - 1)
	wr(scene_obj(2) + SCENE_OBJ_Y, y)
	_move_cutscene_obj(2, SCENE_OBJ_X, -1)
	wr(scene_obj(3) + SCENE_OBJ_Y, y)
	_move_cutscene_obj(3, SCENE_OBJ_X, 1)
	return y


## Cutscene27Func (EVENT_PLACE_CART_WHEELS): the cart's two states (wSceneObj2), then the end at once
## (Func_9cd16); then Func_9f2f3. (Its sounds are not ported.)
func _cutscene_27_func() -> void:
	match r2(W2D013):
		0x00:
			_wait_cutscene_func(30)
		0x01:  # .Func_9d674
			set_scene_obj_state(2, 0x02)
			_advance_cutscene_func()
		0x02:  # .Func_9d687
			_wait_cutscene_func(50)
		0x03:  # .Func_9d68c
			set_scene_obj_state(2, 0x03)
			_advance_cutscene_func()
		0x04:  # .Func_9d69f
			_wait_cutscene_func(180)
		0x05:
			_func_9cd16()
		_:
			_note_past_steps("Cutscene27Func")
	_func_9f2f3()


# --- the cutscenes' objects (bank $27) ---

## Func_9f0d0: at its frameset's end (wOWAnimationFinished), the object at `obj` restarts in `state`.
## True when it did (the routine then runs it again).
func _func_9f0d0(obj: int, state: int) -> bool:
	if r2(W_OW_ANIMATION_FINISHED) != 0xFF:
		return false
	wr(obj + SCENE_OBJ_DURATION, 0)
	wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
	wr(obj + SCENE_OBJ_STATE, state)
	return true


## Func_9f0a5 with Func_9f0ae (bank $2f) or Func_9f0b5 (bank $1a): the object whose state is at
## `state_at` animated with its state's frameset (the table at bank $27 `table`, state - 1); returns
## the object.
func _cutscene_obj_animate(state_at: int, table: int, bank: int) -> int:
	var frameset: int = pointer_from_table(CUTSCENE_BANK, table, rd(state_at) - 1)
	return update_ow_animation(state_at - (SCENE_OBJ_STATE - SCENE_OBJ_DURATION), frameset, bank)


## The cutscenes' object routines' shape (Func_9f0e0.asm_9f0e9 and the like): each of the objects
## `numbers` in turn, while it has a state: animated (_cutscene_obj_animate), a state with one after
## it (`afters`) taking that at its frameset's end (Func_9f0d0) and running again, else drawn with the
## OAM table at (`oam_bank`, `oam`) without the scroll (Func_9f0bc, Func_9f0c1).
func _draw_cutscene_objs(numbers: Array, table: int, bank: int, oam_bank: int, oam: int,
		afters: Dictionary = {}) -> void:
	for number: int in numbers:
		var state_at: int = scene_obj(number) + SCENE_OBJ_STATE
		while rd(state_at) != 0:
			var obj: int = _cutscene_obj_animate(state_at, table, bank)
			var state: int = rd(state_at)
			if afters.has(state) and _func_9f0d0(obj, int(afters[state])):
				continue
			load_ow_sprite(obj, oam, oam_bank)
			break


## Func_9fb53 (Func_9fb4c, Func_9fb6c, Func_9fb97, Func_9fba0): while wSceneObj1's y is `mode`, the
## object at `obj`'s position with frame `frame` and no attributes copied to `at` (wCurSceneObj or
## wCurSceneObjDuration) and drawn from there with OAM_bc000 (Func_9fb61).
func _func_9fb53(obj: int, at: int, frame: int, mode: int) -> void:
	if rd(W_SCENE_OBJ_1 + SCENE_OBJ_Y) != mode:
		return
	wr(at + SCENE_OBJ_Y, rd(obj + SCENE_OBJ_Y))
	wr(at + SCENE_OBJ_X, rd(obj + SCENE_OBJ_X))
	wr(at + SCENE_OBJ_FRAME, frame)
	wr(at + SCENE_OBJ_ATTRIBUTES, 0)
	load_ow_sprite(at & 0xFFFC, OAM_BC000, CUTSCENE_OBJ_BANK)


## OWCutTree: wCurSceneObj's sprite (Func_9fb97), then wSceneObj2: the axe (state 1, Frameset_bc1f3)
## or the cut (state 2, Frameset_bc1e8, gone at its end), drawn with OAM_bc122.
func _ow_cut_tree() -> void:
	var state_at: int = scene_obj(2) + SCENE_OBJ_STATE
	while true:
		_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ, 5, 0x03)  # Func_9fb97
		var state: int = rd(state_at)
		if state == 0:
			return
		var obj: int
		if state == 0x01:
			obj = update_ow_animation(state_at - 2, FRAMESET_BC1F3, CUTSCENE_OBJ_BANK)
		elif state == 0x02:
			obj = update_ow_animation(state_at - 2, FRAMESET_BC1E8, CUTSCENE_OBJ_BANK)
			if _func_9f0d0(obj, 0x00):
				continue
		else:
			_note("OWCutTree state $%02x (debug_nop: hangs)" % state)
			return
		load_ow_sprite(obj, OAM_BC122, CUTSCENE_OBJ_BANK)
		return


## Func_9f0e0 (the north gate): wSceneObj3, wSceneObj2 (state 5 gone at its end, 6 then 7), OAM_bd1fd.
func _func_9f0e0() -> void:
	_draw_cutscene_objs([3, 2], FUNC_9F0E0_FRAMESETS, CUTSCENE_OBJ_BANK, CUTSCENE_OBJ_BANK, OAM_BD1FD,
			{0x05: 0x00, 0x06: 0x07})


## Func_9f11e (the rainstorm): wSceneObj2 (state 2 then 3), OAM_bd377.
func _func_9f11e() -> void:
	_draw_cutscene_objs([2], FUNC_9F11E_FRAMESETS, CUTSCENE_OBJ_BANK, CUTSCENE_OBJ_BANK, OAM_BD377, {0x02: 0x03})


## Func_9f146 (the tower): wSceneObj2 and wSceneObj3 (OAM_bd453), then their sprites at wCurSceneObj
## (frames 5 and 6, Func_9fb97 and Func_9fba0).
func _func_9f146() -> void:
	_draw_cutscene_objs([2, 3], FUNC_9F146_FRAMESETS, CUTSCENE_OBJ_BANK, CUTSCENE_OBJ_BANK, OAM_BD453)
	_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ, 5, 0x03)
	_func_9fb53(scene_obj(3), W_CUR_SCENE_OBJ_DURATION, 6, 0x03)


## Func_9f174 (the elevator): wSceneObj4, 2, 3, 5 (state 6 then 7, 8 gone at its end; state 5's sound
## at its end not ported), OAM_bd46f.
func _func_9f174() -> void:
	_draw_cutscene_objs([4, 2, 3, 5], FUNC_9F174_FRAMESETS, CUTSCENE_OBJ_BANK, CUTSCENE_OBJ_BANK, OAM_BD46F,
			{0x06: 0x07, 0x08: 0x00})


## Func_9f2f3 (the cart wheels): wSceneObj2 with bank $1a's framesets (state 3's sound at its end not
## ported) and OAM_188279 (bank $62).
func _func_9f2f3() -> void:
	_draw_cutscene_objs([2], FUNC_9F2F3_FRAMESETS, 0x1A, int(OAM_188279[0]), int(OAM_188279[1]))


## Func_9f3cd (the tornado): wSceneObj3, wSceneObj2, OAM_bddcf.
func _func_9f3cd() -> void:
	_draw_cutscene_objs([3, 2], FUNC_9F3CD_FRAMESETS, CUTSCENE_OBJ_BANK, CUTSCENE_OBJ_BANK, OAM_BDDCF)


## Func_9fbfa (the seeds): wSceneObj2's sprite at wCurSceneObj (frame 0, Func_9fb4c), the seeds
## (Frameset_bd1b4, OAM_bcfb3), its sprite at wCurSceneObjDuration (frame 1, Func_9fb6c).
func _func_9fbfa() -> void:
	_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ, 0, 0x01)
	if _cutscene_obj_state(2) != 0:  # .Func_9fc09
		var obj: int = update_ow_animation(scene_obj(2) + SCENE_OBJ_DURATION, FRAMESET_BD1B4, CUTSCENE_OBJ_BANK)
		load_ow_sprite(obj, OAM_BCFB3, CUTSCENE_OBJ_BANK)
	_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ_DURATION, 1, 0x01)


## Func_9fc1d (the music boxes): as Func_9fbfa, the box by its state's frameset (.framesets),
## OAM_bc1f6.
func _func_9fc1d() -> void:
	_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ, 0, 0x01)
	if _cutscene_obj_state(2) != 0:  # .Func_9fc2c
		var obj: int = _cutscene_obj_animate(scene_obj(2) + SCENE_OBJ_STATE, FUNC_9FC1D_FRAMESETS, CUTSCENE_OBJ_BANK)
		load_ow_sprite(obj, OAM_BC1F6, CUTSCENE_OBJ_BANK)
	_func_9fb53(scene_obj(2), W_CUR_SCENE_OBJ_DURATION, 1, 0x01)


# --- the fade to white (bank $21) ---

## Func_85046 (Func_9cd8d): its first loop: BG palettes 1 to 7 and the OB palettes kept in wTempBGPals
## and wTempOBPals with their targets (wTempPals1 palettes 1 to 7, wTempPals2) white, through
## wPalConfig1 and wPalConfig2; then a slow step of each a loop (Func_851d1, Func_851bc) until the BG
## palettes' $20 steps, then the next step (w2d014 cleared).
func func_85046() -> void:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 1:
		for offset: int in 7 * 8:
			w0(W_TEMP_BG_PALS + 8 + offset, r0(W_TEMP_PALS_1 + 8 + offset))
		fill(W_TEMP_PALS_1 + 8, 7 * 8, 0xFF)
		for offset: int in 8 * 8:
			w0(W_TEMP_OB_PALS + offset, r0(W_TEMP_PALS_2 + offset))
		fill(W_TEMP_PALS_2, 8 * 8, 0xFF)
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)
		_set_pal_config(W_PAL_CONFIG_1_INDEX, W_TEMP_BG_PALS + 8, BGPI_PALETTE_1, 7)
		_set_pal_config(W_PAL_CONFIG_2_INDEX, W_TEMP_OB_PALS, OBPI_PALETTE_0, 8)
		return
	fade_ob_pal_config_slowly()
	if fade_bg_pal_config_slowly():
		return
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W2D014, 0)
	w2(W2D013, r2(W2D013) + 1)


## A pal_config_struct from its index (`at`): the index, the number of palettes, the source.
func _set_pal_config(at: int, source: int, index: int, number: int) -> void:
	w2(at + 2, source >> 8)
	w2(at + 3, source & 0xFF)
	w2(at, index)
	w2(at + 1, number)
