class_name OverworldGolfBuilding
extends OverworldCutscenes
## The Golf Building between North and West (OverworldStateTable's sub-states $1E to $22,
## src/engine/overworld/temple/common.asm, bank2b_1.asm), translated (WL3-052): Func_80e33 ($1E: B held
## goes straight to the next map side, else on), its fades ($1F, $21), _GolfBuilding ($20: its palettes
## by the crayons got, scene Wario placed by the side he walks to, or in front of the course with all the
## crayons), and Func_adbfe ($22: Wario walks through; with all the crayons he stops at the course, where
## A or up enters golf (wState ST_LEVEL with wOWLevel LEVEL_GOLF_BUILDING) and left or right sends him
## on to North or West; B leaves while he walks), with scene Wario (UpdateSceneWario,
## SetSceneWarioState, bank $2b) and .VBlank_GolfBuilding, whose RAM writes run after each loop. The
## Golf Building's own state is kept in wPalFade6Colour2Green's bytes. What it writes to VRAM, the
## palettes, and the LCD is recorded for drawing.

# Scene Wario (scene_obj_struct, then his graphics' state; src/ram/wram.asm, over wOWUIObj1 and 2).
const W_SCENE_WARIO: int = 0xD140
const W_SCENE_WARIO_X_COORD: int = 0xD141
const W_SCENE_WARIO_FRAME: int = 0xD142
const W_SCENE_WARIO_DURATION: int = 0xD144  # then wSceneWarioFramesetOffset
const W_SCENE_WARIO_STATE: int = 0xD146  # also wOWUIObj1State
const W_SCENE_WARIO_UNK7: int = 0xD147
const W_SCENE_WARIO_STATE_GROUP: int = 0xD148  # also wOWUIObj2YCoord
const W_SCENE_WARIO_OAM_PTR: int = 0xD149  # little-endian
const W_SCENE_WARIO_OAM_BANK: int = 0xD14B
const W2D14C: int = 0xD14C  # also wOWUIObj2Duration
const W_SCENE_WARIO_IGNORE_SCROLL: int = 0xD14D
const W2D14E: int = 0xD14E
const W_HDMA_DEST_VRAM_BANK: int = 0xD158
const W_SCENE_OBJS_END: int = 0xD200
## "WRAM2 2" ($d800-$dfff), what ClearGeneralSceneRAM clears.
const GENERAL_SCENE_RAM_SIZE: int = 0x800
## The Golf Building's state (0 to 4), its step in it, and its loop counter.
const W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT: int = 0xDA10
const W_PAL_FADE_6_COLOUR_2_GREEN_TARGET: int = 0xDA11
const W_PAL_FADE_6_COLOUR_2_GREEN_SIGN: int = 0xDA12

const SCENE_BANK: int = 0x2B
const GOLF_BUILDING_DATA: int = 0x5A6E  # _GolfBuilding.data: x, $00, state, $00 by map side
const PALS_ADDC9: int = 0x5DC9
const PALS_ADE09: int = 0x5E09
const SCENE_WARIO_SPRITE_POINTERS: int = 0x4962  # SetSceneWarioState.WarioSpritePointers: dab OAM, dba tiles
const GOLF_BUILDING_MAPS_BANK: int = 0x2C
const GOLF_BUILDING_TILEMAP: int = 0x6546
const GOLF_BUILDING_ATTRMAP: int = 0x6616
const PROLOGUE_BACKGROUND_GFX: int = 0x4F80  # bank $2c, $80 tiles to v0Tiles2 (LoadFarTiles)
## The V-Blank function the Golf Building sets (.VBlank_GolfBuilding), numbered by its sub-state.
const VBLANK_GOLF_BUILDING: int = 0x20

const SCENEWARIO_NONE: int = 0x00
const SCENEWARIO_LOOK_FRONT: int = 0x01
const SCENEWARIO_LOOK_BACK: int = 0x02
const SCENEWARIO_WALK_LEFT: int = 0x07
const SCENEWARIO_WALK_RIGHT: int = 0x08
const SCENEWARIO_IDLE_LEFT: int = 0x0C
const SCENEWARIO_IDLE_RIGHT: int = 0x0D
const SCENEWARIO_TURN_FRONT_TO_BACK_RIGHT: int = 0x30
const SCENEWARIO_TURN_RIGHT_TO_FRONT: int = 0x34
const SCENEWARIO_TURN_LEFT_TO_FRONT: int = 0x35
const SCENEWARIO_TURN_FRONT_TO_LEFT: int = 0x36
const SCENEWARIO_TURN_FRONT_TO_RIGHT: int = 0x37
const SCENEWARIO_IDLE_FRONT: int = 0x3C
const NUM_SCENEWARIO_STATES: int = 0x3D
const SCENEWARIO_GROUP_NONE: int = 0xFF
## SCENEWARIO_GROUP_00 to SCENEWARIO_GROUP_12: the first state past each group (the last, 13, is the rest).
const SCENEWARIO_GROUP_ENDS: Array = [0x07, 0x0B, 0x0C, 0x0E, 0x10, 0x15, 0x1D, 0x22, 0x26, 0x2D, 0x30, 0x3A,
		0x3C]
## UpdateSceneWario.DoAnimation by state: [frameset (in the bank of the state's OAM), the state set once it
## ends (.SetStateIfFinished) or -1]. The frameset is Frameset_ plus its ROM offset.
const SCENE_WARIO_ANIMATIONS: Array = [
	[0x0000, -1],  # $00 .None
	[0x4D18, -1],  # $01 .LookFront: Frameset_14d18
	[0x4D15, -1],  # $02 .LookBack: Frameset_14d15
	[0x4CBE, 0x0C],  # $03 .TurnFrontLeft: Frameset_14cbe, then IDLE_LEFT
	[0x4CC5, 0x0D],  # $04 .TurnFrontRight: Frameset_14cc5, then IDLE_RIGHT
	[0x4D0B, 0x02],  # $05 .TurnBackLeft: Frameset_14d0b, then LOOK_BACK
	[0x4D10, 0x02],  # $06 .TurnBackRight: Frameset_14d10, then LOOK_BACK
	[0x49B4, -1],  # $07 .WalkLeft: Frameset_149b4 (Func_ac4fa)
	[0x49C5, -1],  # $08 .WalkRight: Frameset_149c5 (Func_ac4fa)
	[0x49FE, -1],  # $09 .CarryWalk: Frameset_149fe (Func_ac4fa)
	[0x4A20, -1],  # $0a .CarryIdle: Frameset_14a20
	[0x63EC, 0x0A],  # $0b .PickUp: Frameset_163ec, then CARRY_IDLE
	[0x4252, -1],  # $0c .IdleLeft: Frameset_14252
	[0x425F, -1],  # $0d .IdleRight: Frameset_1425f
	[0x4DE4, -1],  # $0e .Nod: Frameset_d4de4
	[0x4DE4, 0x02],  # $0f .NodOnce: Frameset_d4de4, then LOOK_BACK
	[0x66A5, 0x11],  # $10 .LookAround: Frameset_aa6a5, then LOOK_TURN_FORWARD (.asm_ac65f)
	[0x66C2, 0x12],  # $11 .LookTurnForward: Frameset_aa6c2, then LOOK_FORWARD
	[0x66C7, -1],  # $12 .LookForward: Frameset_aa6c7
	[0x66A5, 0x38],  # $13 .LookAroundThenTurn: Frameset_aa6a5, then TURN_LEFT_END (.asm_ac65f)
	[0x66CA, 0x39],  # $14 .LookTurnRight: Frameset_aa6ca, then TURN_RIGHT_END (.asm_ac65f)
	[0x68EC, -1],  # $15 .OnFire: Frameset_aa8ec
	[0x68F5, 0x19],  # $16 .CrashLandRight: Frameset_aa8f5, then STUNNED_RIGHT
	[0x6902, -1],  # $17 .CrashTumble: Frameset_aa902
	[0x6902, 0x19],  # $18 .CrashTumbleEnd: Frameset_aa902, then STUNNED_RIGHT
	[0x690D, -1],  # $19 .StunnedRight: Frameset_aa90d
	[0x6913, 0x0D],  # $1a .LookUp: Frameset_aa913, then IDLE_RIGHT (its sounds' counter)
	[0x6924, 0x1C],  # $1b .CrashLandLeft: Frameset_aa924, then STUNNED_LEFT
	[0x6931, -1],  # $1c .StunnedLeft: Frameset_aa931
	[0x6B27, 0x1F],  # $1d .LookMusicBox: Frameset_aab27, then HOLD_MUSIC_BOX
	[0x6B32, 0x20],  # $1e .PickUpMusicBox: Frameset_aab32, then LOOK_UP_SURPRISED
	[0x6B3F, -1],  # $1f .HoldMusicBox: Frameset_aab3f
	[0x6B42, -1],  # $20 .LookUpSurprised: Frameset_aab42
	[0x6B45, 0x0A],  # $21 .CarrySnapFingers: Frameset_aab45, then CARRY_IDLE
	[0x6CCB, -1],  # $22 .Sleep: Frameset_aaccb (w2d14e)
	[0x6CE2, 0x25],  # $23 .WakeUp: Frameset_aace2, then SIT_IDLE
	[0x6CF7, -1],  # $24 .SitStill: Frameset_aacf7
	[0x6CFA, -1],  # $25 .SitIdle: Frameset_aacfa
	[0x703C, 0x02],  # $26 .JumpAndBow: Frameset_ab03c (.Func_ac7b7), then LOOK_BACK
	[0x706B, 0x02],  # $27 .SnapFingers: Frameset_ab06b, then LOOK_BACK
	[0x708C, 0x2D],  # $28 .ShowMusicBoxes1: Frameset_ab08c, then SHOW_MUSIC_BOXES_2
	[0x7098, 0x02],  # $29 .ShowMusicBoxes5: Frameset_ab098, then LOOK_BACK
	[0x709D, 0x02],  # $2a .PanicJump: Frameset_ab09d, then LOOK_BACK
	[0x709D, -1],  # $2b .Panic: Frameset_ab09d
	[0x70AC, -1],  # $2c .Bow: Frameset_ab0ac
	[0x714D, 0x2E],  # $2d .ShowMusicBoxes2: Frameset_ab14d, then SHOW_MUSIC_BOXES_3
	[0x7160, -1],  # $2e .ShowMusicBoxes3: Frameset_ab160
	[0x7163, 0x29],  # $2f .ShowMusicBoxes4: Frameset_ab163, then SHOW_MUSIC_BOXES_5
	[0x4439, 0x02],  # $30 .TurnFrontToBackRight: Frameset_1fc439, then LOOK_BACK
	[0x4446, 0x02],  # $31 .TurnFrontToBackLeft: Frameset_1fc446, then LOOK_BACK
	[0x4453, 0x0D],  # $32 .TurnBackToRight: Frameset_1fc453, then IDLE_RIGHT
	[0x445A, 0x0C],  # $33 .TurnBackToLeft: Frameset_1fc45a, then IDLE_LEFT
	[0x4461, 0x01],  # $34 .TurnRightToFront: Frameset_1fc461, then LOOK_FRONT
	[0x446A, 0x01],  # $35 .TurnLeftToFront: Frameset_1fc46a, then LOOK_FRONT
	[0x4473, 0x0C],  # $36 .TurnFrontToLeft: Frameset_1fc473, then IDLE_LEFT
	[0x447C, 0x0D],  # $37 .TurnFrontToRight: Frameset_1fc47c, then IDLE_RIGHT
	[0x4485, 0x0D],  # $38 .TurnLeftEnd: Frameset_1fc485, then IDLE_RIGHT
	[0x4488, 0x0C],  # $39 .TurnRightEnd: Frameset_1fc488, then IDLE_LEFT
	[0x6B5A, -1],  # $3a .PanicRunLeft: Frameset_16b5a (Func_ac515)
	[0x6B63, -1],  # $3b .PanicRunRight: Frameset_16b63 (Func_ac515)
	[0x4316, -1],  # $3c .IdleFront: Frameset_1fc316
]
## _GolfBuilding.FillBGPalettes: by crayon (CRAYON_RED_F to CRAYON_PINK_F), the pieces of Pals_ade09 it
## copies over Pals_addc9 in wTempBGPals: [offset, bytes].
const GOLF_BUILDING_CRAYON_PALS: Array = [
	[[7 * 8, 8]],  # .FillRed: palette 7
	[[0 * 8 + 2, 2], [1 * 8, 2], [2 * 8, 6], [3 * 8 + 2, 2]],  # .FillBrown
	[[4 * 8 + 2, 6]],  # .FillYellow
	[[1 * 8 + 2, 6], [5 * 8 + 2, 6]],  # .FillGreen
	[[0 * 8 + 4, 2], [3 * 8, 2], [4 * 8, 2], [5 * 8, 2]],  # .FillCyan
	[[0 * 8 + 6, 2], [2 * 8 + 6, 2], [3 * 8 + 4, 4]],  # .FillBlue
	[[6 * 8, 8]],  # .FillPink: palette 6
]


# --- the sub-states ---

## Func_80e33 ($1E): B held goes straight to the next map side (SST_OVERWORLD_08), else the Golf
## Building's fade.
func func_80e33() -> void:
	if (sim.wJoypadDown & PAD_B) != 0:
		sim.wSubState = SST_OVERWORLD_08
		return
	sim.wSubState = byte(sim.wSubState + 1)


## GolfBuilding, _GolfBuilding (SST_OVERWORLD_GOLF_BUILDING): the LCD off, BG map 0 cleared, the virtual
## OAM cleared, the music stopped (not ported), the scroll cleared, .VBlank_GolfBuilding set, the scene
## RAM and the scene objects cleared, the BG palettes (.FillBGPalettes), the map's OB palettes (Pals_84900)
## to wTempPals2, the tiles (PrologueBackgroundGfx to v0Tiles2) and maps (BG map 0), scene Wario placed
## (.Func_ada43) and updated; the LCD on; the next sub-state.
func golf_building() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()
	sim.wSCX = 0
	sim.wSCY = 0
	vblank_func = VBLANK_GOLF_BUILDING
	clear_general_scene_ram()
	clear_scene_objs_ram()
	_fill_golf_building_bg_palettes()
	copy_rom(MAP_PALS_BANK, PALS_84900, W_TEMP_PALS_2, 8 * 8)
	screen_loads.append(["golf_building"])
	vram_writes.append(["rom", 0, 0x9000, GOLF_BUILDING_MAPS_BANK, PROLOGUE_BACKGROUND_GFX, 0x80 * 0x10])
	decompress_to_vram(GOLF_BUILDING_MAPS_BANK, GOLF_BUILDING_ATTRMAP, 1, 0x9800)  # decompress_attrmap
	decompress_to_vram(GOLF_BUILDING_MAPS_BANK, GOLF_BUILDING_TILEMAP, 0, 0x9800)  # decompress_tilemap
	_func_ada43()
	update_scene_wario()
	set_lcdc(LCDC_DEFAULT)
	sim.wSubState = byte(sim.wSubState + 1)


## _GolfBuilding.Func_ada43: without all the crayons, Wario at the side he walks from (.Func_ada4a);
## with them, back from golf (wOWLevel LEVEL_GOLF_BUILDING) in front of the course (x $50, state 4,
## looking to the front), else as without them two states on (2, 3: he stops at the course).
func _func_ada43() -> void:
	if r2(W_CRAYON_FLAGS) != ALL_CRAYONS:
		_func_ada4a()
		return
	if r2(W_OW_LEVEL) != LEVEL_GOLF_BUILDING:
		_func_ada4a()  # .asm_ada97
		w2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT, r2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT) + 2)
		return
	w2(W_SCENE_WARIO, 0x58)
	w2(W_SCENE_WARIO_X_COORD, 0x50)
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT, 0x04)
	w2(W_SCENE_WARIO_STATE_GROUP, SCENEWARIO_GROUP_NONE)
	set_scene_wario_state(SCENEWARIO_LOOK_FRONT)


## _GolfBuilding.Func_ada4a: scene Wario at y $58 and .data's x by wNextMapSide (to North $90 and state 1,
## walking left; to West $10 and state 0, walking right; past them the code after it read as data), his
## graphics group none (so they load), no state.
func _func_ada4a() -> void:
	w2(W_SCENE_WARIO, 0x58)
	var at: int = GOLF_BUILDING_DATA + ((r2(W_NEXT_MAP_SIDE) * 4) & 0xFF)
	w2(W_SCENE_WARIO_X_COORD, rb(SCENE_BANK, at))
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT, rb(SCENE_BANK, at + 2))
	w2(W_SCENE_WARIO_STATE_GROUP, SCENEWARIO_GROUP_NONE)
	set_scene_wario_state(SCENEWARIO_NONE)


## _GolfBuilding.FillBGPalettes: Pals_addc9 (grey) to wTempPals1 and wTempBGPals, each crayon got's
## colours from Pals_ade09 over wTempBGPals (.FillRed to .FillPink), then wTempBGPals back to wTempPals1.
func _fill_golf_building_bg_palettes() -> void:
	copy_rom(SCENE_BANK, PALS_ADDC9, W_TEMP_PALS_1, 8 * 8)  # LoadPalsToTempPals1
	for offset: int in 8 * 8:
		w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))
	for crayon: int in GOLF_BUILDING_CRAYON_PALS.size():
		if (r2(W_CRAYON_FLAGS) & (1 << crayon)) == 0:
			continue
		for piece: Array in GOLF_BUILDING_CRAYON_PALS[crayon]:
			copy_rom(SCENE_BANK, PALS_ADE09 + int(piece[0]), W_TEMP_BG_PALS + int(piece[0]), int(piece[1]))
	for offset: int in 8 * 8:
		w0(W_TEMP_PALS_1 + offset, r0(W_TEMP_BG_PALS + offset))


## Func_80e55, Func_adbfe ($22): B leaves (.Func_adc0b), else the Golf Building's state
## (.Func_adc2f); scene Wario updated, the virtual OAM's unused entries cleared.
func func_adbfe() -> void:
	if not _func_adc0b():
		_func_adc2f()
	update_scene_wario()
	clear_unused_virtual_oam()


## Func_adbfe.Func_adc0b: out of state 4 (not in front of the course), B pressed leaves (.exit). True
## (carry) when it does.
func _func_adc0b() -> bool:
	if r2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT) == 0x04:
		return false
	if (sim.wJoypadPressed & PAD_B) == 0:
		return false
	_golf_building_exit()
	return true


## Func_adbfe.exit: the sound effects stopped (not ported), w2d14c (wOWUIObj2Duration) 1, and the next
## map side (SST_OVERWORLD_08, to wNextMapSide).
func _golf_building_exit() -> void:
	w2(W2D14C, 0x01)
	sim.wSubState = SST_OVERWORLD_08


## Func_adbfe.Func_adc2f: the counter (wPalFade6Colour2GreenSign) counted, then by the state
## (wPalFade6Colour2GreenCurrent): walking right through to West (0), left through to North (1), right
## (2) or left (3) to the course, at the course (4).
func _func_adc2f() -> void:
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN, r2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN) + 1)
	match r2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT):
		0:
			_walk_through(SCENEWARIO_WALK_RIGHT, 0x90)  # .Func_adc54
		1:
			_walk_through(SCENEWARIO_WALK_LEFT, 0x10)  # .Func_adc7e
		2:
			_walk_to_course(SCENEWARIO_WALK_RIGHT, SCENEWARIO_IDLE_RIGHT, SCENEWARIO_TURN_RIGHT_TO_FRONT)
		3:
			_walk_to_course(SCENEWARIO_WALK_LEFT, SCENEWARIO_IDLE_LEFT, SCENEWARIO_TURN_LEFT_TO_FRONT)
		4:
			_func_add0b()
		var state:
			_note("Func_adbfe state %d (past its jumptable)" % state)


## Func_adbfe.asm_adc43: the next step, its counter cleared.
func _next_golf_building_step() -> void:
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN, 0)
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET, r2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET) + 1)


## Func_adbfe.asm_adc4a: state `state`, from its first step.
func _set_golf_building_state(state: int) -> void:
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT, state)
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN, 0)
	w2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET, 0)


## Func_adbfe.Func_adc54 (right, to x $90) and .Func_adc7e (left, to x $10), by the step: Wario walks
## (0), until x (its low bit off) is reached, then disappears (1); $14 loops on (2); he leaves (3, .exit).
func _walk_through(walk: int, end_x: int) -> void:
	match r2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET):
		0:
			set_scene_wario_state(walk)
			_next_golf_building_step()
		1:
			if _apply_scene_wario_movement(walk) != end_x:
				return
			set_scene_wario_state(SCENEWARIO_NONE)
			_next_golf_building_step()
		2:
			if r2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN) < 0x14:
				return
			_next_golf_building_step()
		3:
			_golf_building_exit()


## Func_adbfe.Func_adca9 (right) and .Func_adcda (left), by the step: Wario walks (0) to the course (x
## $50), then stands (1); 8 loops on he turns to the front (2), and state 4 starts.
func _walk_to_course(walk: int, idle: int, turn: int) -> void:
	match r2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET):
		0:
			set_scene_wario_state(walk)
			_next_golf_building_step()
		1:
			if _apply_scene_wario_movement(walk) != 0x50:
				return
			set_scene_wario_state(idle)
			_next_golf_building_step()
		2:
			if r2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN) < 0x08:
				return
			set_scene_wario_state(turn)
			_set_golf_building_state(0x04)


## ApplySceneWarioMovementLeft for a walk left, ApplySceneWarioMovementRight for a walk right.
func _apply_scene_wario_movement(walk: int) -> int:
	if walk == SCENEWARIO_WALK_LEFT:
		return apply_scene_wario_movement_left()
	return apply_scene_wario_movement_right()


## Func_adbfe.Func_add0b (state 4, at the course), by the step: once Wario looks to the front (0), $10
## loops on he stands (1); then the d-pad (2): right to West (.d_right: wNextMapSide WEST through
## OW_EXIT_LEFT, he turns right, step 7), left to North (.d_left: NORTH through OW_EXIT_RIGHT, he turns
## left, step 5), A or up to golf (he turns his back, a sound not ported, step 3); once he looks back
## (3), $14 loops on golf (4: wOWLevel LEVEL_GOLF_BUILDING, wSubState 0, wState on: ST_LEVEL); once he
## faces left (5), 4 loops on state 1 (6); once he faces right (7), 4 loops on state 0 (8).
func _func_add0b() -> void:
	var counter: int = r2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN)
	match r2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET):
		0:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_LOOK_FRONT:
				_next_golf_building_step()
		1:
			if counter >= 0x10:
				set_scene_wario_state(SCENEWARIO_IDLE_FRONT)
				_next_golf_building_step()
		2:
			_func_add36()
		3:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_LOOK_BACK:
				_next_golf_building_step()
		4:
			if counter >= 0x14:
				w2(W_OW_LEVEL, LEVEL_GOLF_BUILDING)
				sim.wSubState = 0
				sim.wState = byte(sim.wState + 1)
		5:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_IDLE_LEFT:
				_next_golf_building_step()
		6:
			if counter >= 0x04:
				_set_golf_building_state(0x01)
		7:
			if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_IDLE_RIGHT:
				_next_golf_building_step()
		8:
			if counter >= 0x04:
				_set_golf_building_state(0x00)
		var step:
			_note("Func_adbfe.Func_add0b step %d (past its jumptable)" % step)


## Func_adbfe.Func_add36: the d-pad at the course (right before left, then A or up).
func _func_add36() -> void:
	var pressed: int = sim.wJoypadPressed
	if (pressed & PAD_RIGHT) != 0:  # .d_right
		w2(W_NEXT_MAP_SIDE, WEST)
		w2(W_MAP_SIDE_LEVEL_ID, OW_EXIT_LEFT)
		w2(W2D068, OW_EXIT_LEFT)
		set_scene_wario_state(SCENEWARIO_TURN_FRONT_TO_RIGHT)
		w2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN, 0)
		w2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET, 0x07)
	elif (pressed & PAD_LEFT) != 0:  # .d_left
		w2(W_NEXT_MAP_SIDE, NORTH)
		w2(W_MAP_SIDE_LEVEL_ID, OW_EXIT_RIGHT)
		w2(W2D068, OW_EXIT_RIGHT)
		set_scene_wario_state(SCENEWARIO_TURN_FRONT_TO_LEFT)
		w2(W_PAL_FADE_6_COLOUR_2_GREEN_SIGN, 0)
		w2(W_PAL_FADE_6_COLOUR_2_GREEN_TARGET, 0x05)
	elif (pressed & (PAD_A | PAD_UP)) != 0:  # .a_btn_or_d_up
		set_scene_wario_state(SCENEWARIO_TURN_FRONT_TO_BACK_RIGHT)
		_next_golf_building_step()


## .VBlank_GolfBuilding's function, run after the loop (V-Blank): the scroll, with wHDMABank its DMA
## (wHDMA, to VRAM 0) from that bank, the OAM; its RAM write: wHDMABank cleared once applied.
func vblank_golf_building() -> void:
	if r2(W_HDMA_BANK) != 0:
		record_gdma(0, W_HDMA, r2(W_HDMA_BANK))
		w2(W_HDMA_BANK, 0)


# --- scene Wario (bank $2b) ---

## ClearGeneralSceneRAM: "WRAM2 2" ($d800-$dfff) cleared.
func clear_general_scene_ram() -> void:
	fill(W2D800, GENERAL_SCENE_RAM_SIZE, 0)


## ClearSceneObjsRAM: scene Wario to the scene objects' end cleared.
func clear_scene_objs_ram() -> void:
	fill(W_SCENE_WARIO, W_SCENE_OBJS_END - W_SCENE_WARIO, 0)


## UpdateSceneWario: his animation (.DoAnimation), then with a state, his sprite (his OAM table and bank)
## drawn with the scroll unless wSceneWarioIgnoreScroll.
func update_scene_wario() -> void:
	_scene_wario_do_animation()
	if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_NONE:
		return
	var table: int = rd_word(W_SCENE_WARIO_OAM_PTR)
	var bank: int = r2(W_SCENE_WARIO_OAM_BANK)
	if r2(W_SCENE_WARIO_IGNORE_SCROLL) == 0:
		load_ow_sprite_with_scroll(W_SCENE_WARIO, table, bank)
	else:
		load_ow_sprite(W_SCENE_WARIO, table, bank)


## UpdateSceneWario.DoAnimation: the state's frameset (.UpdateAnimation, in his OAM's bank), what some
## states do after it (the walks' Func_ac4fa, the runs' Func_ac515, .Sleep's w2d14e, .JumpAndBow's
## .Func_ac7b7), the next state once it ends (.SetStateIfFinished, the next state's animation run at
## once), then the looks' sounds' counter (.asm_ac65f, .LookUp's).
func _scene_wario_do_animation() -> void:
	var state: int = r2(W_SCENE_WARIO_STATE)
	if state == SCENEWARIO_NONE:
		return
	if state >= NUM_SCENEWARIO_STATES:
		_note("UpdateSceneWario state $%02x (past its jumptable)" % state)
		return
	var entry: Array = SCENE_WARIO_ANIMATIONS[state]
	update_ow_animation(W_SCENE_WARIO_DURATION, int(entry[0]), r2(W_SCENE_WARIO_OAM_BANK))  # .UpdateAnimation
	match state:
		0x07, 0x08, 0x09:  # .WalkLeft, .WalkRight, .CarryWalk
			_func_ac4fa()
			return
		0x3A, 0x3B:  # .PanicRunLeft, .PanicRunRight
			_func_ac515()
			return
		0x22:  # .Sleep (a snore when it ends, not ported)
			w2(W2D14E, r2(W_OW_ANIMATION_FINISHED))
		0x26:  # .JumpAndBow
			_func_ac7b7()
	if int(entry[1]) >= 0:
		_scene_wario_set_state_if_finished(int(entry[1]))
	match state:
		0x10, 0x13, 0x14:  # .LookAround, .LookAroundThenTurn, .LookTurnRight
			_func_ac65f()
		0x1A:  # .LookUp
			_look_up_sounds()


## UpdateSceneWario.SetStateIfFinished: once the animation ended (wOWAnimationFinished $ff), state
## `state` and its animation (.DoAnimation).
func _scene_wario_set_state_if_finished(state: int) -> void:
	if r2(W_OW_ANIMATION_FINISHED) != 0xFF:
		return
	set_scene_wario_state(state)
	_scene_wario_do_animation()


## UpdateSceneWario.asm_ac65f: unless he looks back, w2d14c paces the looks' sound: at frames 0 and 4 it
## plays once (not ported; w2d14c 1), and between them w2d14c is 0 again.
func _func_ac65f() -> void:
	if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_LOOK_BACK:
		return
	var frame: int = r2(W_SCENE_WARIO_FRAME)
	match r2(W2D14C):
		0:
			if frame == 0x00 or frame == 0x04:
				w2(W2D14C, 0x01)
		1:
			if frame != 0x00 and frame != 0x04:
				w2(W2D14C, 0)


## UpdateSceneWario.LookUp's sounds: unless he stands (IDLE_RIGHT), at frame $0d one sound (w2d14c 1), at
## frame $0c another (w2d14c 2), each once (not ported); off its frame w2d14c is 0 again.
func _look_up_sounds() -> void:
	if r2(W_SCENE_WARIO_STATE) == SCENEWARIO_IDLE_RIGHT:
		return
	var frame: int = r2(W_SCENE_WARIO_FRAME)
	match r2(W2D14C):
		0:
			if frame == 0x0C:
				w2(W2D14C, 0x02)
			elif frame == 0x0D:
				w2(W2D14C, 0x01)
		1:
			if frame != 0x0D:
				w2(W2D14C, 0)
		2:
			if frame != 0x0C:
				w2(W2D14C, 0)


## UpdateSceneWario.JumpAndBow.Func_ac7b7: at frame 7, once (wSceneWarioUnk7 set), a landing sound (not
## ported).
func _func_ac7b7() -> void:
	if r2(W_SCENE_WARIO_FRAME) != 0x07 or r2(W_SCENE_WARIO_UNK7) != 0:
		return
	w2(W_SCENE_WARIO_UNK7, 0x01)


## Func_ac4fa: the walks' footsteps: w2d14c counts to $24, a sound (not ported) at 0.
func _func_ac4fa() -> void:
	w2(W2D14C, r2(W2D14C) + 1)
	if r2(W2D14C) >= 0x24:
		w2(W2D14C, 0)


## Func_ac515: the runs' footsteps: w2d14c counts to 8, then a sound (not ported) and 0.
func _func_ac515() -> void:
	w2(W2D14C, r2(W2D14C) + 1)
	if r2(W2D14C) >= 0x08:
		w2(W2D14C, 0)


## SetSceneWarioState: the state, its graphics group (SCENEWARIO_GROUP_*) loaded if not the current one
## (.LoadGfx), his animation from its start, w2d14c cleared.
func set_scene_wario_state(state: int) -> void:
	w2(W_SCENE_WARIO_STATE, state)
	var group: int = 0
	while group < SCENEWARIO_GROUP_ENDS.size() and state >= int(SCENEWARIO_GROUP_ENDS[group]):
		group += 1
	if r2(W_SCENE_WARIO_STATE_GROUP) != group:
		_load_scene_wario_gfx(group)
	w2(W_SCENE_WARIO_DURATION, 0)
	w2(W_SCENE_WARIO_DURATION + 1, 0)
	w2(W2D14C, 0)


## SetSceneWarioState.LoadGfx: the group, its OAM table and bank (.WarioSpritePointers, 6 bytes a group),
## and the HDMA of its tiles ($80 tiles to VRAM 0's tiles from $8000: wHDMABank, wHDMA) for the V-Blank.
func _load_scene_wario_gfx(group: int) -> void:
	w2(W_SCENE_WARIO_STATE_GROUP, group)
	var at: int = SCENE_WARIO_SPRITE_POINTERS + ((group * 6) & 0xFF)
	w2(W_SCENE_WARIO_OAM_PTR, rb(SCENE_BANK, at))
	w2(W_SCENE_WARIO_OAM_PTR + 1, rb(SCENE_BANK, at + 1))
	w2(W_SCENE_WARIO_OAM_BANK, rb(SCENE_BANK, at + 2))
	w2(W_HDMA_BANK, rb(SCENE_BANK, at + 3))
	w2(W_HDMA, rb(SCENE_BANK, at + 5))  # wHDMASourceHi
	w2(W_HDMA + 1, rb(SCENE_BANK, at + 4))
	w2(W_HDMA + 2, 0)  # wHDMADestHi, wHDMADestLo
	w2(W_HDMA + 3, 0)
	w2(W_HDMA + 4, 0x80 - 1)  # $80 dma_tiles
	w2(W_HDMA_DEST_VRAM_BANK, 0)


## ApplySceneWarioMovementLeft: scene Wario 1 px left, 2 on odd loops (wGlobalCounter) or with left held;
## his x with its low bit off.
func apply_scene_wario_movement_left() -> int:
	var step: int = 2 if ((sim.wGlobalCounter | (sim.wJoypadDown >> 5)) & 1) != 0 else 1
	w2(W_SCENE_WARIO_X_COORD, r2(W_SCENE_WARIO_X_COORD) - step)
	return r2(W_SCENE_WARIO_X_COORD) & 0xFE


## ApplySceneWarioMovementRight: scene Wario 1 px right, 2 on odd loops (wGlobalCounter) or with right
## held; his x with its low bit off.
func apply_scene_wario_movement_right() -> int:
	var step: int = 2 if ((sim.wGlobalCounter | (sim.wJoypadDown >> 4)) & 1) != 0 else 1
	w2(W_SCENE_WARIO_X_COORD, r2(W_SCENE_WARIO_X_COORD) + step)
	return r2(W_SCENE_WARIO_X_COORD) & 0xFE
