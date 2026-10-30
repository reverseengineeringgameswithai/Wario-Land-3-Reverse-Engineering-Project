class_name OverworldObjects
extends OverworldHome
## The map's scene objects (src/engine/overworld/bank2d.asm), translated (WL3-052): _InitOWObjects,
## what an event's DO_OW_FUNC or SPECIAL_ACTION sets up on its map side (by the map side and the
## function, with w2d065 telling whether the event is unlocked, TRUE, or unlocked by the treasure just
## collected, $80): wSceneObj1 to 15's positions and states, map patches, palettes, BG priorities; and
## Func_b4a3d and Func_b4aa9, the objects' animation by state (a state table per map side), drawn
## with the scroll.

const OBJECTS_BANK: int = 0x2A  # the objects' framesets and OAM tables
const FUNC_B4874_PAL: int = 0x487F  # bank $2d
const FUNC_B43DD_PAL: int = 0x4440  # bank $2d
const FUNC_B4F58_PAL: int = 0x4F7A  # bank $2d
const PALS_84A20: int = 0x4A20  # bank $21
const OW_SCENE_FREEZE_SEA_TILEMAP: int = 0x56A8  # bank $21
const OW_SCENE_FREEZE_SEA_ATTRMAP: int = 0x5888  # bank $21
const OVERWORLD_TOP_BAR_DAY_NIGHT_TILEMAP: int = 0x5EA7  # bank $21
const OVERWORLD_TOP_BAR_DAY_NIGHT_ATTRMAP: int = 0x5EDA  # bank $21
const OVERWORLD_BOTTOM_BAR_TREASURES_TILEMAP: int = 0x6868  # bank $21
const OVERWORLD_BOTTOM_BAR_TREASURES_ATTRMAP: int = 0x68B2  # bank $21
const TREASURE_GFX_EMPTY: int = 0x4000  # bank $26: TreasureGfx, the empty treasure's first
# Func_854ee's map patches (bank $21).
const DATA_8550B: int = 0x550B
const DATA_85536: int = 0x5536
const DATA_85549: int = 0x5549
const DATA_8556E: int = 0x556E
const DATA_85579: int = 0x5579
const DATA_855B2: int = 0x55B2
const DATA_855F9: int = 0x55F9
const DATA_8560E: int = 0x560E
const DATA_8563E: int = 0x563E
const DATA_85AF4: int = 0x5AF4
const DATA_85AFD: int = 0x5AFD
const DATA_85B0A: int = 0x5B0A
const DATA_85B1B: int = 0x5B1B
const DATA_85B2C: int = 0x5B2C
const DATA_85B3D: int = 0x5B3D
const DATA_85B48: int = 0x5B48
const TRANSITION_EPILOGUE_NOT_PERFECT: int = 0xF1
const TRANSITION_EPILOGUE_PERFECT: int = 0xF2
const UNLOCK_LEVEL: int = 0x01
const GREEN_MUSIC_BOX: int = 0x03

# A scene object's state: [frameset, the state after its end (-1: it loops), OAM table, special], all
# in bank $2a; null: Func_b4000 (nothing). Specials, by the routine:
const PLAIN: int = 0
const NIGHT_ATTRIBUTES: int = 1  # Func_b4e8b: attributes 6 at night, 0 by day
const OBJ8_AFTER_OBJ7: int = 2  # Func_b4ea9: once wSceneObj7 is gone, wSceneObj8 to state 8
const BG_PAL_5: int = 3  # Func_b4f58: BG palette 5 by wSceneObj11
const NO_SCROLL: int = 4  # Func_b5136: LoadCurSceneObjSprite

## Func_b4fab (North).
const NORTH_STATES: Array = [
	null,  # $00 Func_b4000
	[0x45CD, -1, 0x4000, PLAIN],  # $01 Func_b5004: Frameset_a85cd, OAM_a8000
	[0x4590, 0x00, 0x4000, PLAIN],  # $02 Func_b5009: Frameset_a8590
	[0x45D0, -1, 0x4000, PLAIN],  # $03 Func_b500e: Frameset_a85d0
	[0x45D3, 0x00, 0x4000, PLAIN],  # $04 Func_b5013: Frameset_a85d3
	[0x462A, -1, 0x4000, PLAIN],  # $05 Func_b5018: Frameset_a862a
	[0x4653, 0x00, 0x4000, PLAIN],  # $06 Func_b501d: Frameset_a8653
	[0x462D, -1, 0x4000, PLAIN],  # $07 Func_b5022: Frameset_a862d
	[0x4639, 0x09, 0x4000, PLAIN],  # $08 Func_b5027: Frameset_a8639
	[0x4636, -1, 0x4000, PLAIN],  # $09 Func_b5031: Frameset_a8636
	[0x4646, 0x0B, 0x4000, PLAIN],  # $0a Func_b5036: Frameset_a8646
	[0x466E, -1, 0x4000, PLAIN],  # $0b Func_b5040: Frameset_a866e
	[0x467F, 0x0E, 0x4000, PLAIN],  # $0c Func_b5045: Frameset_a867f
	[0x46DA, 0x0E, 0x4000, PLAIN],  # $0d Func_b504f: Frameset_a86da
	[0x472F, -1, 0x4000, PLAIN],  # $0e Func_b5059: Frameset_a872f
	[0x4732, -1, 0x4000, PLAIN],  # $0f Func_b505e: Frameset_a8732
	[0x4750, -1, 0x4000, PLAIN],  # $10 Func_b5063: Frameset_a8750
	[0x4761, -1, 0x4000, PLAIN],  # $11 Func_b5068: Frameset_a8761
	[0x479A, -1, 0x4000, PLAIN],  # $12 Func_b506d: Frameset_a879a
	null,  # $13 Func_b4000
	[0x4764, -1, 0x4000, PLAIN],  # $14 Func_b5072: Frameset_a8764
	[0x476F, -1, 0x4000, PLAIN],  # $15 Func_b5077: Frameset_a876f
	[0x4782, 0x18, 0x4000, PLAIN],  # $16 Func_b5093: Frameset_a8782
	[0x4793, 0x19, 0x4000, PLAIN],  # $17 Func_b509d: Frameset_a8793
	[0x477A, -1, 0x4000, PLAIN],  # $18 Func_b50a7: Frameset_a877a
	null,  # $19 Func_b4000
	[0x477D, -1, 0x4000, PLAIN],  # $1a Func_b50ac: Frameset_a877d
	null,  # $1b Func_b4000
	[0x479F, 0x00, 0x4000, PLAIN],  # $1c Func_b50b1: Frameset_a879f
	[0x473D, 0x0E, 0x4000, PLAIN],  # $1d Func_b50b6: Frameset_a873d
	[0x47D2, 0x20, 0x4000, PLAIN],  # $1e Func_b50c0: Frameset_a87d2
	[0x47D9, -1, 0x4000, PLAIN],  # $1f Func_b50ca: Frameset_a87d9
	[0x47DC, -1, 0x4000, PLAIN],  # $20 Func_b50cf: Frameset_a87dc
	[0x47DF, -1, 0x4000, PLAIN],  # $21 Func_b50d4: Frameset_a87df
	[0x65F5, -1, 0x6580, PLAIN],  # $22 Func_b50d9: Frameset_aa5f5, OAM_aa580
	[0x65F8, -1, 0x6580, PLAIN],  # $23 Func_b50de: Frameset_aa5f8, OAM_aa580
	[0x6252, -1, 0x60CF, PLAIN],  # $24 Func_b50ea: Frameset_aa252, OAM_aa0cf
	[0x60A3, -1, 0x5FE2, PLAIN],  # $25 Func_b50f6: Frameset_aa0a3, OAM_a9fe2
	[0x60C1, 0x27, 0x5FE2, PLAIN],  # $26 Func_b50fb: Frameset_aa0c1, OAM_a9fe2
	[0x609D, -1, 0x5FE2, PLAIN],  # $27 Func_b5105: Frameset_aa09d, OAM_a9fe2
	[0x60BC, 0x25, 0x5FE2, PLAIN],  # $28 Func_b510a: Frameset_aa0bc, OAM_a9fe2
	[0x47E8, -1, 0x4000, PLAIN],  # $29 Func_b512a: Frameset_a87e8
	[0x47F1, -1, 0x4000, PLAIN],  # $2a Func_b5130: Frameset_a87f1
	[0x483B, 0x00, 0x47FA, NO_SCROLL],  # $2b Func_b5136: Frameset_a883b, OAM_a87fa
]

## Func_b4e04 (West): OAM_a884a, or OAM_a8f57.
const WEST_STATES: Array = [
	null,  # $00 Func_b4000
	[0x4DE9, 0x00, 0x484A, PLAIN],  # $01 Func_b4e77: Frameset_a8de9
	[0x4DE2, -1, 0x484A, PLAIN],  # $02 Func_b4e7c: Frameset_a8de2
	[0x4DD1, -1, 0x484A, PLAIN],  # $03 Func_b4e81: Frameset_a8dd1
	[0x4E1E, 0x00, 0x484A, PLAIN],  # $04 Func_b4e86: Frameset_a8e1e
	[0x4E29, -1, 0x484A, NIGHT_ATTRIBUTES],  # $05 Func_b4e8b: Frameset_a8e29
	[0x4E2C, -1, 0x484A, PLAIN],  # $06 Func_b4ea4: Frameset_a8e2c
	[0x4E5D, 0x00, 0x484A, OBJ8_AFTER_OBJ7],  # $07 Func_b4ea9: Frameset_a8e5d
	[0x4E6C, -1, 0x484A, PLAIN],  # $08 Func_b4ebd: Frameset_a8e6c
	[0x4E29, -1, 0x484A, NIGHT_ATTRIBUTES],  # $09 Func_b4e8b: Frameset_a8e29
	[0x4DF8, -1, 0x484A, PLAIN],  # $0a Func_b4ec2: Frameset_a8df8
	[0x4E04, 0x0C, 0x484A, PLAIN],  # $0b Func_b4ec8: Frameset_a8e04
	[0x4E01, -1, 0x484A, PLAIN],  # $0c Func_b4ed2: Frameset_a8e01
	[0x4E11, 0x0E, 0x484A, PLAIN],  # $0d Func_b4ed8: Frameset_a8e11
	[0x4F17, -1, 0x484A, PLAIN],  # $0e Func_b4ee3: Frameset_a8f17
	[0x5090, 0x11, 0x4F57, PLAIN],  # $0f Func_b4ee9: Frameset_a9090, OAM_a8f57
	[0x50EB, 0x11, 0x4F57, PLAIN],  # $10 Func_b4ef4: Frameset_a90eb, OAM_a8f57
	[0x5140, -1, 0x4F57, PLAIN],  # $11 Func_b4eff: Frameset_a9140, OAM_a8f57
	[0x5143, -1, 0x4F57, PLAIN],  # $12 Func_b4f05: Frameset_a9143, OAM_a8f57
	[0x514E, 0x11, 0x4F57, PLAIN],  # $13 Func_b4f0b: Frameset_a914e, OAM_a8f57
	[0x4E9D, 0x00, 0x484A, PLAIN],  # $14 Func_b4f16: Frameset_a8e9d
	[0x4EAC, 0x00, 0x484A, PLAIN],  # $15 Func_b4f1c: Frameset_a8eac
	[0x4EB7, 0x00, 0x484A, PLAIN],  # $16 Func_b4f22: Frameset_a8eb7
	[0x4EC2, -1, 0x484A, PLAIN],  # $17 Func_b4f28: Frameset_a8ec2
	[0x4EC7, -1, 0x484A, PLAIN],  # $18 Func_b4f2e: Frameset_a8ec7
	[0x4ECA, -1, 0x484A, PLAIN],  # $19 Func_b4f34: Frameset_a8eca
	[0x4ECA, 0x00, 0x484A, PLAIN],  # $1a Func_b4f3a: Frameset_a8eca
	[0x4ED3, -1, 0x484A, PLAIN],  # $1b Func_b4f40: Frameset_a8ed3
	[0x4EDA, -1, 0x484A, PLAIN],  # $1c Func_b4f46: Frameset_a8eda
	[0x4EE1, -1, 0x484A, PLAIN],  # $1d Func_b4f4c: Frameset_a8ee1
	[0x4EE8, -1, 0x484A, BG_PAL_5],  # $1e Func_b4f52: Frameset_a8ee8
	[0x4EE8, 0x00, 0x484A, BG_PAL_5],  # $1f Func_b4f82: Frameset_a8ee8
	[0x4F28, -1, 0x484A, PLAIN],  # $20 Func_b4f8a: Frameset_a8f28
	[0x4F31, -1, 0x484A, PLAIN],  # $21 Func_b4f90: Frameset_a8f31
	[0x4F47, -1, 0x484A, PLAIN],  # $22 Func_b4f96: Frameset_a8f47
	[0x4F3A, -1, 0x484A, PLAIN],  # $23 Func_b4f9c: Frameset_a8f3a
]

## Func_b4ccb (South): OAM_a9161.
const SOUTH_STATES: Array = [
	null,  # $00 Func_b4000
	[0x56C0, -1, 0x5161, PLAIN],  # $01 Func_b4d0e: Frameset_a96c0
	[0x568D, 0x01, 0x5161, PLAIN],  # $02 Func_b4d14: Frameset_a968d
	[0x567D, -1, 0x5161, PLAIN],  # $03 Func_b4d1f: Frameset_a967d
	[0x5680, -1, 0x5161, PLAIN],  # $04 Func_b4d25: Frameset_a9680
	[0x5674, -1, 0x5161, PLAIN],  # $05 Func_b4d2b: Frameset_a9674
	[0x5680, 0x03, 0x5161, PLAIN],  # $06 Func_b4d31: Frameset_a9680
	[0x56AF, -1, 0x5161, PLAIN],  # $07 Func_b4d3c: Frameset_a96af
	[0x56B2, 0x09, 0x5161, PLAIN],  # $08 Func_b4d41: Frameset_a96b2
	[0x56BD, -1, 0x5161, PLAIN],  # $09 Func_b4d4b: Frameset_a96bd
	[0x56D1, -1, 0x5161, PLAIN],  # $0a Func_b4d50: Frameset_a96d1
	[0x569A, -1, 0x5161, PLAIN],  # $0b Func_b4d55: Frameset_a969a
	[0x56A3, -1, 0x5161, PLAIN],  # $0c Func_b4d5a: Frameset_a96a3
	[0x56A6, -1, 0x5161, PLAIN],  # $0d Func_b4d5f: Frameset_a96a6
	[0x56A9, -1, 0x5161, PLAIN],  # $0e Func_b4d64: Frameset_a96a9
	[0x56AC, -1, 0x5161, PLAIN],  # $0f Func_b4d69: Frameset_a96ac
	[0x56D8, -1, 0x5161, PLAIN],  # $10 Func_b4d6e: Frameset_a96d8
	[0x56E1, 0x00, 0x5161, PLAIN],  # $11 Func_b4d73: Frameset_a96e1
	[0x56EA, 0x00, 0x5161, PLAIN],  # $12 Func_b4d78: Frameset_a96ea
	[0x56EF, 0x15, 0x5161, PLAIN],  # $13 Func_b4d7d: Frameset_a96ef
	[0x574A, 0x15, 0x5161, PLAIN],  # $14 Func_b4d87: Frameset_a974a
	[0x579F, -1, 0x5161, PLAIN],  # $15 Func_b4d91: Frameset_a979f
	[0x57A2, -1, 0x5161, PLAIN],  # $16 Func_b4d96: Frameset_a97a2
	[0x57AD, 0x00, 0x5161, PLAIN],  # $17 Func_b4d9b: Frameset_a97ad
	[0x57E1, -1, 0x5161, PLAIN],  # $18 Func_b4db6: Frameset_a97e1
	[0x57EC, -1, 0x5161, PLAIN],  # $19 Func_b4dbb: Frameset_a97ec
	[0x57D4, -1, 0x5161, PLAIN],  # $1a Func_b4dc0: Frameset_a97d4 (a sound at its end, not ported)
	[0x57C5, 0x00, 0x5161, PLAIN],  # $1b Func_b4ddd: Frameset_a97c5
	[0x57EF, 0x00, 0x5161, PLAIN],  # $1c Func_b4de2: Frameset_a97ef
	[0x57B2, 0x15, 0x5161, PLAIN],  # $1d Func_b4de7: Frameset_a97b2
	[0x57FE, -1, 0x5161, PLAIN],  # $1e Func_b4df1: Frameset_a97fe
	null,  # $1f Func_b4000
	[0x5803, -1, 0x5161, PLAIN],  # $20 Func_b4df6: Frameset_a9803
]

## Func_b4ba2 (East): OAM_a980c.
const EAST_STATES: Array = [
	null,  # $00 Func_b4000
	[0x5E61, -1, 0x580C, PLAIN],  # $01 Func_b4be9: Frameset_a9e61
	[0x5E72, -1, 0x580C, PLAIN],  # $02 Func_b4bee: Frameset_a9e72
	[0x5E75, -1, 0x580C, PLAIN],  # $03 Func_b4bf3: Frameset_a9e75
	[0x5E94, -1, 0x580C, PLAIN],  # $04 Func_b4bf8: Frameset_a9e94
	[0x5E7A, 0x00, 0x580C, PLAIN],  # $05 Func_b4bfd: Frameset_a9e7a
	[0x5E8C, -1, 0x580C, PLAIN],  # $06 Func_b4c02: Frameset_a9e8c
	[0x5E91, -1, 0x580C, PLAIN],  # $07 Func_b4c07: Frameset_a9e91
	[0x5FD0, 0x00, 0x580C, PLAIN],  # $08 Func_b4c0c: Frameset_a9fd0
	[0x5ED3, -1, 0x580C, PLAIN],  # $09 Func_b4c16: Frameset_a9ed3
	[0x5EEA, 0x0B, 0x580C, PLAIN],  # $0a Func_b4c1b: Frameset_a9eea
	[0x5EF1, -1, 0x580C, PLAIN],  # $0b Func_b4c25: Frameset_a9ef1
	[0x5EE3, -1, 0x580C, PLAIN],  # $0c Func_b4c2a: Frameset_a9ee3
	[0x5EF6, 0x0E, 0x580C, PLAIN],  # $0d Func_b4c2f: Frameset_a9ef6
	[0x5EFD, -1, 0x580C, PLAIN],  # $0e Func_b4c39: Frameset_a9efd
	[0x5EE0, -1, 0x580C, PLAIN],  # $0f Func_b4c3e: Frameset_a9ee0
	[0x5F02, -1, 0x580C, PLAIN],  # $10 Func_b4c43: Frameset_a9f02
	[0x5F0D, -1, 0x580C, PLAIN],  # $11 Func_b4c48: Frameset_a9f0d
	[0x5ECD, -1, 0x580C, PLAIN],  # $12 Func_b4c4d: Frameset_a9ecd
	[0x5ED0, -1, 0x580C, PLAIN],  # $13 Func_b4c52: Frameset_a9ed0
	[0x5EAA, -1, 0x580C, PLAIN],  # $14 Func_b4c6d: Frameset_a9eaa
	[0x5EB3, -1, 0x580C, PLAIN],  # $15 Func_b4c72: Frameset_a9eb3
	[0x5EBC, -1, 0x580C, PLAIN],  # $16 Func_b4c77: Frameset_a9ebc
	[0x5EC5, -1, 0x580C, PLAIN],  # $17 Func_b4c7c: Frameset_a9ec5
	[0x5EC8, 0x00, 0x580C, PLAIN],  # $18 Func_b4c81: Frameset_a9ec8
	[0x5F36, -1, 0x580C, PLAIN],  # $19 Func_b4c86: Frameset_a9f36
	[0x5F47, 0x1B, 0x580C, PLAIN],  # $1a Func_b4c8b: Frameset_a9f47
	[0x5F76, 0x19, 0x580C, PLAIN],  # $1b Func_b4c95: Frameset_a9f76
	[0x5FA7, -1, 0x580C, PLAIN],  # $1c Func_b4c9f: Frameset_a9fa7
	[0x5FAA, 0x1C, 0x580C, PLAIN],  # $1d Func_b4ca4: Frameset_a9faa
	[0x5FC9, -1, 0x580C, PLAIN],  # $1e Func_b4cae: Frameset_a9fc9
	[0x5FBB, -1, 0x580C, PLAIN],  # $1f Func_b4cb3: Frameset_a9fbb
	[0x5FC2, -1, 0x580C, PLAIN],  # $20 Func_b4cb8: Frameset_a9fc2
	[0x5FDF, -1, 0x580C, PLAIN],  # $21 Func_b4cbd: Frameset_a9fdf
	[0x5E99, 0x00, 0x580C, PLAIN],  # $22 Func_b4c11: Frameset_a9e99
]

## The objects Func_b4a3d and Func_b4aa9 update, by map side.
const OBJS_A3D: Array = [1, 2, 3, 4]
const OBJS_AA9: Array = [
	[5, 6, 7, 8, 9, 10, 13, 14, 15],  # NORTH
	[5, 6, 7, 8, 10, 11, 12, 13, 14, 15],  # WEST
	[5, 6, 7, 8, 9, 10, 14, 15],  # SOUTH
	[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],  # EAST
]


# --- the objects' animation ---

## Func_b4a3d: wSceneObj1 to 4 updated by the current map side's state table.
func func_b4a3d() -> void:
	for number: int in OBJS_A3D:
		update_scene_obj(scene_obj(number))


## Func_b4aa9: the side's other scene objects.
func func_b4aa9() -> void:
	for number: int in OBJS_AA9[r2(W_CUR_MAP_SIDE) & 3]:
		update_scene_obj(scene_obj(number))


## Func_b4fa2 (North), Func_b4dfb (West), Func_b4cc2 (South), Func_b4b99 (East): the object becomes
## wCurSceneObjPtr and its state's routine runs.
func update_scene_obj(obj: int) -> void:
	wr_word(W_CUR_SCENE_OBJ_PTR, obj)
	_scene_obj_state(rd(obj + SCENE_OBJ_STATE))


## A state's routine on the object at wCurSceneObjPtr (UpdateCurOWObjAnimation then
## LoadCurSceneObjSpriteWithScroll); with a state after its end, Func_b4a0d: at the frameset's end the
## duration and offset are cleared, the state set, and that state's routine runs at once.
func _scene_obj_state(state: int) -> void:
	var states: Array = [NORTH_STATES, WEST_STATES, SOUTH_STATES, EAST_STATES][r2(W_CUR_MAP_SIDE) & 3]
	if state >= states.size():
		_note("scene object state $%02x on map side %d (past its table)" % [state, r2(W_CUR_MAP_SIDE)])
		return
	var entry: Variant = states[state]
	if entry == null:
		return
	var obj: int = rd_word(W_CUR_SCENE_OBJ_PTR)
	update_ow_animation(obj + SCENE_OBJ_DURATION, int(entry[0]), OBJECTS_BANK)
	if int(entry[3]) == NIGHT_ATTRIBUTES:
		wr(obj + SCENE_OBJ_ATTRIBUTES, 0x06 if r2(W2D011) != 0 else 0x00)
	var after: int = int(entry[1])
	if after >= 0 and r2(W_OW_ANIMATION_FINISHED) == 0xFF:
		wr(obj + SCENE_OBJ_DURATION, 0)
		wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
		wr(obj + SCENE_OBJ_STATE, after)
		_scene_obj_state(after)
	elif int(entry[3]) == NO_SCROLL:
		load_ow_sprite(obj, int(entry[2]), OBJECTS_BANK)
	else:
		load_ow_sprite_with_scroll(obj, int(entry[2]), OBJECTS_BANK)
	match int(entry[3]):
		OBJ8_AFTER_OBJ7:
			if rd(scene_obj(7) + SCENE_OBJ_STATE) == 0:
				wr(scene_obj(8) + SCENE_OBJ_DURATION, 0)
				wr(scene_obj(8) + SCENE_OBJ_STATE, 0x08)
		BG_PAL_5:
			_func_b4f58()


## Func_b4f58 (West): BG palette 5 (wTempBGPals, applied through wPalConfig1's register) wTempPals1's
## while wSceneObj11 shows frame $57 or is gone, else its own.
func _func_b4f58() -> void:
	var at: int = W_TEMP_PALS_1 + 5 * 8
	if rd(scene_obj(11) + SCENE_OBJ_FRAME) != 0x57 and rd(scene_obj(11) + SCENE_OBJ_STATE) != 0:
		copy_rom(0x2D, FUNC_B4F58_PAL, W_TEMP_BG_PALS + 5 * 8, 8)
	else:
		for offset: int in 8:
			wr(W_TEMP_BG_PALS + 5 * 8 + offset, rd(at + offset))
	w2(W_PAL_CONFIG_1, 0x68)  # LOW(rBGPI)


# --- the set-ups ---

## InitSceneObjParams: the object's y, x, and state from `params`, its duration and frameset offset
## cleared (its frame and attributes kept).
func init_scene_obj_params(obj: int, params: Array) -> void:
	wr(obj + SCENE_OBJ_Y, params[0])
	wr(obj + SCENE_OBJ_X, params[1])
	wr(obj + SCENE_OBJ_DURATION, 0)
	wr(obj + SCENE_OBJ_FRAMESET_OFFSET, 0)
	wr(obj + SCENE_OBJ_STATE, params[2])


func _obj(number: int, params: Array) -> void:
	init_scene_obj_params(scene_obj(number), params)


func _set_obj_state(number: int, state: int) -> void:
	wr(scene_obj(number) + SCENE_OBJ_STATE, state)


## The graphics loaders the set-ups call (decompress_tiles0, decompress_tiles1): (bank, address) to
## VRAM bank `vram_bank` from `destination` (v0Tiles0 by default).
func _load_gfx(bank: int, address: int, vram_bank: int = 0, destination: int = 0x8000) -> void:
	decompress_to_vram(bank, address, vram_bank, destination)


## _InitOWObjects: by wOWSceneMapSide and wOWSceneActionParam, with c = w2d065.
func init_ow_objects() -> void:
	var c: int = r2(W2D065)
	var function: int = r2(W_OW_SCENE_ACTION_PARAM)
	if function == 0:
		_note("_InitOWObjects function 0 (debug_nop: hangs)")
		return
	match r2(W_OW_SCENE_MAP_SIDE) & 3:
		NORTH:
			_init_ow_objects_north(function, c)
		WEST:
			_init_ow_objects_west(function, c)
		SOUTH:
			_init_ow_objects_south(function, c)
		EAST:
			_init_ow_objects_east(function, c)


## InitOWObjects_North (NOWFUNC_*).
func _init_ow_objects_north(function: int, c: int) -> void:
	match function:
		0x01:  # Func_b403e, NOWFUNC_CUT_TREE
			if c != 1:
				_obj(8, [0x44, 0x30, 0x01])
			if r2(W_CUR_EVENT) == 0:
				_obj(15, [0x56, 0x1C, 0x19])
				_obj(14, [0x36, 0x50, 0x1B])
				if r2(W2D011) != 0:
					_set_obj_state(15, 0x18)
					_set_obj_state(14, 0x1A)
			_obj(13, [0x84, 0x82, 0x00])  # Func_b4082
		0x02:  # Func_b408e, NOWFUNC_OPEN_GATE
			if c != 1:
				_obj(10, [0x40, 0x80, 0x03])
		0x03:  # Func_b409c, NOWFUNC_GARLIC
			if is_treasure_collected(GREEN_MUSIC_BOX) != 0:
				return
			if r2(W_CUR_EVENT) == 0 and r2(W_NEXT_MAP_SIDE) == 0 \
					and r2(W_MAP_SIDE_LEVEL_ID) == OWNORTH_SEA_TURTLE_ROCKS:
				return
			_obj(3, [0x66, 0x74, 0x05])
		0x04:  # Func_b40c0, NOWFUNC_MAGIC_SEED
			if c != 0:
				_obj(4, [0x00, 0x68, 0x07] if c == 0x80 else [0x4C, 0x66, 0x0B])
		0x05:  # Func_b40d9, NOWFUNC_SUMMON_SNAKE
			if c == 0:
				return
			if c == 1:
				_obj(2, [0x59, 0x2D, 0x1D])
				return
			_obj(1, [0x51, SCREEN_WIDTH_PX, 0x0F])
			_obj(2, [0x59, 0x2D, 0x1D])
			_set_obj_state(2, 0)
		0x06:  # Func_b40ff, NOWFUNC_FALL_LEAVES
			if c == 0:
				return
			if (c & 0x80) != 0:
				_obj(6, [0x38, 0x15, 0x14])
				_obj(7, [0x41, 0x19, 0x14])
				return
			w2(W2D12C, 0x01)
			_obj(6, [0x48, 0x14, 0x11])
			w2(W2D12E, 0x04)
			_obj(7, [0x38, 0x0F, 0x10])
		0x07, 0x08:  # Func_b4140, NOWFUNC_BLUE_MUSIC_BOX, NOWFUNC_GOLD_MUSIC_BOX
			pass
		0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F:  # Func_b4141 to Func_b4176, NOWFUNC_CRAYON_*
			_func_b4143(c, [0x00, 0x00, 0x02, 0x03, 0x03, 0x02, 0x01][function - 0x09])
		0x10:  # Func_b417a, NOWFUNC_BOTTOM_BAR
			if c == 0x80:
				_func_b417a()
		0x11:  # Func_b4247, NOWFUNC_DAY_NIGHT_SPELL
			if c == 0x80:
				_func_b4247()
		0x12:  # Func_b42e7, NOWFUNC_PROLOGUE
			if wTransitionParam == TRANSITION_EPILOGUE_NOT_PERFECT or wTransitionParam == TRANSITION_EPILOGUE_PERFECT:
				fill(scene_obj(1), 15 * SCENE_OBJ_SIZE, 0)
				_obj(1, [0x28, 0x50, 0x00])
		_:
			_note("InitOWObjects_North function $%02x (past its table)" % function)


## Func_b4143: a crayon just collected, with its palette `palette` (wSceneObj5's attributes).
func _func_b4143(c: int, palette: int) -> void:
	if (c & 0x80) == 0:
		return
	_obj(5, [0x00, 0x70, 0x1F])
	wr(scene_obj(5) + SCENE_OBJ_ATTRIBUTES, palette)
	_obj(1, [0x00, 0x70, 0x21])


## Func_b417a: the bottom bar just got: its treasures' objects (palette bit 2 set), the BG priority
## (Func_80bd9), the V-Blank function, the bottom bar's maps (BG map 1), the window, and the empty
## treasure's tiles (TreasureGfx's first 4, to v0Tiles1 tile $10).
func _func_b417a() -> void:
	_obj(1, [0xA0, 0x08, 0x22])
	_obj(5, [0xA8, 0x18, 0x24])
	_obj(8, [0xA8, 0x34, 0x24])
	_obj(9, [0xA8, 0x50, 0x24])
	_obj(10, [0xA8, 0x6C, 0x24])
	for number: int in [5, 8, 9, 10]:
		var at: int = scene_obj(number) + SCENE_OBJ_ATTRIBUTES
		wr(at, rd(at) | 0x04)
	func_80bd9()
	vblank_func = VBLANK_OVERWORLD
	decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TREASURES_TILEMAP, 0, 0x9C00)
	decompress_to_vram(0x21, OVERWORLD_BOTTOM_BAR_TREASURES_ATTRMAP, 1, 0x9C00)
	w2(W_WX, 0)
	w2(W_WY, SCREEN_HEIGHT_PX)
	set_window(0, SCREEN_HEIGHT_PX)
	w2(W_BOTTOM_BAR_ACTION, 0)  # BOTBAR_CLOSED
	record_copy_to_vram(0, 0x8900, TREASURE_GFX_EMPTY, 4 * 0x10, 0x26)  # TreasureGfx to v0Tiles1 tile $10


## Func_b4247: the day or night spell just got: the top bar with its button (BG map 0 row 29, its rows
## 30 and 31 copied into wAttrmap), its palettes (Pals_84a20 to wTempPals2 palette 4), wSceneObj5, the
## V-Blank function, the coins (DrawCoinCount); wSceneObj6, 7, and 2 stopped.
func _func_b4247() -> void:
	decompress_to_vram(0x21, OVERWORLD_TOP_BAR_DAY_NIGHT_ATTRMAP, 1, 0x9800 + 29 * TILEMAP_WIDTH)
	decompress_to_vram(0x21, OVERWORLD_TOP_BAR_DAY_NIGHT_TILEMAP, 0, 0x9800 + 29 * TILEMAP_WIDTH)
	copy_top_bar_rows_to_wram()
	copy_rom(0x21, PALS_84A20, W_TEMP_PALS_2 + 4 * 8, 4 * 8)
	_obj(5, [0x00, 0x60, 0x00])
	vblank_func = VBLANK_OVERWORLD
	draw_coin_count()
	_set_obj_state(6, 0)
	_set_obj_state(7, 0)
	_set_obj_state(2, 0)


## InitOWObjects_West (WOWFUNC_*).
func _init_ow_objects_west(function: int, c: int) -> void:
	match function:
		0x01:  # Func_b431f, WOWFUNC_RAIN
			if c == 0x80:
				_obj(15, [0x56, 0x5C, 0x00])
				_obj(14, [0x3A, 0x5C, 0x03])
			elif c != 0:
				func_854ee(DATA_8550B)
		0x02:  # Func_b4351, WOWFUNC_CLEAR_TORNADO
			if c != 1:
				_obj(1, [0x44, 0x28, 0x02])
		0x03:  # Func_b435f, WOWFUNC_ELEVATOR_WORKING
			_obj(8, [0x3B, 0x80, 0x09])
			if (r2(W2D065) * 2) & 0xFF == 0 or r2(W_CUR_EVENT) != 0:
				return
			_obj(7, [0x3B, 0x80, 0x00])
			_set_obj_state(8, 0x08 if r2(W2D011) != 0 else 0x06)
		0x04:  # Func_b438f, WOWFUNC_MAGIC_SEED
			if c != 0:
				_obj(4, [0x00, 0x68, 0x0A] if c == 0x80 else [0x5B, 0x60, 0x0E])
		0x05:  # Func_b43a8, WOWFUNC_SUMMON_SNAKE
			if c == 0:
				return
			if c == 1:
				_obj(5, [0x3A, 0x2E, 0x13])
				return
			_obj(1, [0x32, SCREEN_WIDTH_PX, 0x12])
			_obj(5, [0x3A, 0x2E, 0x13])
			_set_obj_state(5, 0)
			for at: int in [W_ATTRMAP + 5 * TILEMAP_WIDTH + 16, W_ATTRMAP + 6 * TILEMAP_WIDTH + 16,
					W_ATTRMAP + 7 * TILEMAP_WIDTH]:
				wr(at, rd(at) & ~(1 << B_BG_PRIO))
		0x06:  # Func_b43dd, WOWFUNC_EARTHQUAKE
			if c == 0:
				return
			if c == 1:
				func_854ee(DATA_85549)
				return
			_func_b43dd_objects()
			_obj(12, [0x3C, 0x4B, 0x00])
			_obj(13, [0x3C, 0x51, 0x00])
			_obj(14, [0x3C, 0x57, 0x00])
			_obj(15, [0x3C, 0x5D, 0x00])
			_obj(10, [0x52, 0x5C, 0x00])
			copy_rom(0x2D, FUNC_B43DD_PAL, W_TEMP_PALS_2 + 2 * 8, 8)
			_load_gfx(0x22, 0x6115, 0, 0x8000 + 0x58 * 0x10)  # LoadOverworldRocksGfx: v0Tiles0 tile $58
		0x07:  # Func_b4448, WOWFUNC_VULCANO_ERUPTION
			if c == 0:
				return
			if (c & 0x80) != 0 and r2(W_OW_SCENE_ACTION_PARAM) == r2(W_TEMP_UNLOCKABLE_CONNECTION_ID):
				_func_b43dd_objects()
				_obj(10, [0x52, 0x5C, 0x00])
				_load_gfx(0x22, 0x5F20)  # LoadOverworld4Gfx
				return
			func_854ee(DATA_85536)
		0x08:  # Func_b4474, WOWFUNC_RED_MUSIC_BOX
			if c == 0:
				return
			_load_gfx(0x22, 0x5D33)  # LoadOverworld3Gfx
			_obj(6, [0x78, 0x3C, 0x23])
			if (r2(W2D065) * 2) & 0xFF != 0:
				func_854ee(DATA_8556E)
				return
			_set_obj_state(6, 0)
			wr(scene_obj(6) + SCENE_OBJ_Y, rd(scene_obj(6) + SCENE_OBJ_Y) + 1)
		_:
			_note("InitOWObjects_West function $%02x (past its table)" % function)


## Func_b43dd.data_1: wSceneObj11 (the eruption's).
func _func_b43dd_objects() -> void:
	_obj(11, [0x10, 0x54, 0x18])


## InitOWObjects_South (SOWFUNC_*).
func _init_ow_objects_south(function: int, c: int) -> void:
	var same_connection: bool = r2(W_OW_SCENE_ACTION_PARAM) == r2(W_TEMP_UNLOCKABLE_CONNECTION_ID)
	match function:
		0x01:  # Func_b44b7, SOWFUNC_SEND_SEEDS
			if c == 0x80 and same_connection:
				_obj(2, [0x38, 0x44, 0x00])
				_obj(3, [0x38, 0x54, 0x00])
				_obj(4, [0x38, 0x4C, 0x00])
		0x02:  # Func_b44e7, SOWFUNC_MAGIC_SEED
			if c == 0:
				return
			if c != 0x80:
				_obj(4, [0x56, 0x1A, 0x01])
			elif same_connection:
				_obj(4, [0x00, 0x16, 0x05])
		0x03:  # Func_b4509, SOWFUNC_YELLOW_MUSIC_BOX
			_obj(6, [0x3D, 0x31, 0x07])
			if r2(W2D065) == 1:
				_set_obj_state(6, rd(scene_obj(6) + SCENE_OBJ_STATE) + 2)
		0x04:  # Func_b4520, SOWFUNC_CANYON_THUNDER
			if c == 0x80:
				_obj(2, [0x48, 0x38, 0x00])
				_obj(10, [0x3D, 0x2F, 0x00])
				_obj(5, [0x68, 0x44, 0x0A])
				_set_obj_state(5, 0)
				_load_gfx(0x23, 0x4E06)  # LoadOverworldThunderGfx
			elif c == 1:
				func_854ee(DATA_855B2)
				_obj(5, [0x68, 0x44, 0x0A])
		0x05:  # Func_b4567, SOWFUNC_RAISE_TOWER
			if c == 1:
				func_854ee(DATA_85579)
				if r2(W_CUR_EVENT) != 0:
					return
				_obj(15, [0x29, 0x78, 0x1F])
				if r2(W2D011) != 0:
					_set_obj_state(15, 0x1E)
				return
			if (c & 0x80) == 0:
				return
			_obj(2, [0x49, 0x78, 0x00])
			_obj(3, [0x50, 0x78, 0x0C])
			for row: int in range(9, 12):
				set_bg_map_bytes_priority(W_ATTRMAP + row * TILEMAP_WIDTH + 14, 2)
			_load_gfx(0x23, 0x4F52, 0, 0x8000 + 0x60 * 0x10)  # LoadOverworldTowerGfx: tile $60
		0x06:  # Func_b45c8, SOWFUNC_FAN
			if c == 1:
				return
			if c != 0:
				_obj(1, [0x5C, 0x82, 0x00])
				_obj(8, [0x64, 0x78, 0x19])
				_load_gfx(0x23, 0x5082, 0, 0x8000 + 0x60 * 0x10)  # LoadOverworldFanGfx: tile $60
			_obj(9, [0x4D, 0x8A, 0x10])
		0x07:  # Func_b45f5, SOWFUNC_SUMMON_SNAKE
			if c == 0:
				return
			if c == 1:
				_obj(7, [0x3F, 0x10, 0x1D])
				return
			_obj(1, [0x37, SCREEN_WIDTH_PX, 0x16])
			_obj(7, [0x3F, 0x10, 0x1D])
			_set_obj_state(7, 0)
		0x08:  # Func_b461b, SOWFUNC_EARTHQUAKE
			if c == 0:
				return
			if (c & 0x80) == 0:
				func_854ee(DATA_855F9)
				return
			_obj(2, [0x5F, 0x3D, 0x00])
			_load_gfx(0x23, 0x4E06)  # LoadOverworldThunderGfx
		0x09:  # Func_b4637, SOWFUNC_GREEN_MUSIC_BOX
			if c == 0:
				return
			if (c & 0x80) == 0:
				func_854ee(DATA_8560E)
				return
			_obj(2, [0x20, 0x48, 0x00])
			_load_gfx(0x23, 0x4E06)  # LoadOverworldThunderGfx
		0x0A:  # Func_b4653, SOWFUNC_EXPLOSIVES
			if (c & 0x80) != 0:
				_obj(2, [0x20, 0x44, 0x00])
				_load_gfx(0x23, 0x51BD)  # LoadOverworldExplosion1Gfx
		0x0B:  # Func_b4665, SOWFUNC_FULL_MOON
			if c == 0:
				return
			_obj(14, [0x25, 0x70, 0x20])
			if c == 0x80 or r2(W2D011) == 0:
				return
			wr(scene_obj(14) + SCENE_OBJ_X, 0x80)
			wr(scene_obj(14) + SCENE_OBJ_Y, 0x15)
		_:
			_note("InitOWObjects_South function $%02x (past its table)" % function)


## InitOWObjects_East (EOWFUNC_*).
func _init_ow_objects_east(function: int, c: int) -> void:
	match function:
		0x01:  # Func_b46a0, EOWFUNC_FREEZE_SEA
			if (c * 2) & 0xFF == 0:
				copy_rom(0x2D, FUNC_B4874_PAL, W_TEMP_PALS_1 + 4 * 8, 8)  # Func_b4874
			if c == 0x80:
				_obj(1, [0x64, 0xE8, 0x01])
			elif c == 1:
				w2(W2D03E, 0)
				w2(W2D046, 0)
				var at: int = 10 * TILEMAP_WIDTH + 15
				copy_rom(0x21, OW_SCENE_FREEZE_SEA_TILEMAP + at, W_TILEMAP + at, 0x91)
				copy_rom(0x21, OW_SCENE_FREEZE_SEA_ATTRMAP + 15, W_ATTRMAP + at, 0x91)  # from its row 0
		0x02:  # Func_b46d9, EOWFUNC_EARTHQUAKE
			if c == 0:
				_obj(6, [0x55, 0x28, 0x02])
			elif c == 0x80:
				_obj(6, [0x55, 0x28, 0x02])
				_obj(15, [0x10, 0x5C, 0x07])
				set_bg_map_bytes_priority(W_ATTRMAP + 10 * TILEMAP_WIDTH + 3, 4)
				set_bg_map_bytes_priority(W_ATTRMAP + 11 * TILEMAP_WIDTH + 3, 4)
			else:
				func_854ee(DATA_8563E)
		0x03:  # Func_b4712, EOWFUNC_FORM_CASTLE
			if c == 0:
				return
			if r2(W_TEMP_OW_SCENE_ACTION) != UNLOCK_LEVEL:  # .Func_b4757
				_obj(7, [0x28, 0x28, 0x12])
				if r2(W2D011) == 0:
					_set_obj_state(7, 0x13)
			if c == 0x80:
				_obj(1, [0x3F, 0x1C, 0x00])
				_set_obj_state(7, 0)
				_load_gfx(0x23, 0x62FB)  # LoadOverworldExplosion2Gfx
				return
			for patch: int in [DATA_85AF4, DATA_85AFD, DATA_85B0A, DATA_85B1B, DATA_85B2C, DATA_85B3D]:
				func_854ee(patch)
		0x04:  # Func_b4771, EOWFUNC_EXPLOSIVES
			if (c & 0x80) != 0:
				_obj(2, [0x54, 0x22, 0x00])
				_obj(1, [0x4C, 0x48, 0x00])
				_load_gfx(0x23, 0x67C1)  # LoadOverworldExplosion3Gfx
				_load_gfx(0x23, 0x6967, 0, 0x8000 + 0x32 * 0x10)  # LoadOverworldSmokeGfx: tile $32
		0x05:  # Func_b4792, EOWFUNC_VULCANO_ERUPTION
			if c == 0:
				return
			if (c & 0x80) != 0 and r2(W_OW_SCENE_ACTION_PARAM) == r2(W_TEMP_UNLOCKABLE_CONNECTION_ID):
				_obj(10, [0x54, 0x78, 0x09])
				_obj(12, [0x58, 0x44, 0x0C])
				_obj(13, [0x44, 0x3C, 0x0C])
				_obj(14, [0x3D, 0x45, 0x0F])
				_obj(15, [0x3E, 0x74, 0x0F])
				_obj(11, [0x10, 0x5C, 0x1E])
				_load_gfx(0x23, 0x6482)  # LoadOverworldFireGfx
			func_854ee(DATA_85B48)
		0x06:  # Func_b47f7, EOWFUNC_BURN_VINES
			if c == 1:
				return
			_obj(9, [0x45, 0x87, 0x17])
			if c != 0:
				_obj(1, [0x45, 0x87, 0x00])
				_load_gfx(0x23, 0x6677, 0, 0x8000 + 0x40 * 0x10)  # LoadOverworldTorchGfx: tile $40
		0x07:  # Func_b481b, EOWFUNC_SHOW_WARPED_VOID
			if c == 0:
				return
			_obj(5, [0x60, 0x88, 0x19])
			if (c & 0x80) != 0:
				_set_obj_state(5, 0)
		0x08:  # Func_b4832, EOWFUNC_RAISE_PIPE
			if c == 0:
				return
			_obj(8, [0x37, 0x7C, 0x1C])
			if c == 1:
				return
			wr(scene_obj(8) + SCENE_OBJ_Y, rd(scene_obj(8) + SCENE_OBJ_Y) + 0x08)
			_obj(2, [0x40, 0x7C, 0x21])
			set_bg_map_bytes_priority(W_ATTRMAP + 7 * TILEMAP_WIDTH + 14, 3)
			set_bg_map_bytes_priority(W_ATTRMAP + 8 * TILEMAP_WIDTH + 14, 3)
			set_bg_map_bytes_priority(W_ATTRMAP + 9 * TILEMAP_WIDTH + 14, 2)
		0x09:  # Func_b4873, EOWFUNC_DAYTIME
			pass
		_:
			_note("InitOWObjects_East function $%02x (past its table)" % function)
