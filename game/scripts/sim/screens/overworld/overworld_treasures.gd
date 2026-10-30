class_name OverworldTreasures
extends OverworldPalettes
## The level's treasures for the bottom bar (src/engine/overworld/bank26.asm), translated (WL3-052):
## Func_9aab5, run when Wario stops at a level: its treasure IDs (LevelTreasureIDs), the bottom bar's
## (uncollected ones as TREASURE_NONE), their palettes (TreasureOBPals), their tiles (TreasureGfx)
## in wTileBuffer for an HDMA to VRAM, the 8-coin once its musical coins are got; in Time Attack
## its best time instead.

const TREASURE_BANK: int = 0x26
const TREASURE_GFX: int = 0x4000
const TREASURE_OB_PALS: int = 0x6BF7
const W_LEVEL_TIME_ATTACK_SCORES: int = 0xCA07
const W_MUSICAL_COIN_FLAGS: int = 0xCA3E
const W_LEVEL_TREASURE_IDS: int = 0xD0F0  # grey, red, green, blue; then their palettes (0xD0F4)
const W_BOTTOM_BAR_TREASURE_IDS: int = 0xD0FC
const W_TILE_BUFFER: int = 0xDC00


## Func_9aab5: at a level (not an exit), the bottom bar's treasure data.
func func_9aab5() -> void:
	if r2(W_MAP_SIDE_LEVEL_ID) >= OW_EXITS:
		return
	clear_treasure_data()
	_func_9aaf4()
	var level: int = r2(W_OW_LEVEL)
	if level != 0 and level != 0x80:  # Func_9ab1c
		get_ow_level_collected_treasures()
	if (r0(W_GAME_MODE_FLAGS) & MODE_TIME_ATTACK) != 0:
		_get_level_time_attack_score()
		return
	_load_level_treasures()
	for index: int in NUM_LEVEL_TREASURES:  # FillBottomBarTreasureIDs
		w2(W_BOTTOM_BAR_TREASURE_IDS + index, r2(W_LEVEL_TREASURE_IDS + index))
	_write_uncollected_bottom_bar_treasure_ids()
	_load_treasure_pals()
	_load_treasure_tiles()
	w2(W_HDMA, W_TILE_BUFFER >> 8)
	w2(W_HDMA + 1, W_TILE_BUFFER & 0xFF)
	w2(W_HDMA + 2, 0x09)
	w2(W_HDMA + 3, 0x00)
	w2(W_HDMA + 4, 0x10 - 1)  # $10 dma_tiles


## LoadLevelTreasureData (bank $26, from InitLevel's LoadLevelCommonGfxAndTreasures): the level's
## treasure data cleared, then its treasures, their palettes, and their tiles (wTileBuffer, which it
## then copies to VRAM: not ported) as Func_9aab5 loads them.
func load_level_treasure_data() -> void:
	clear_treasure_data()
	_load_level_treasures()
	_load_treasure_pals()
	_load_treasure_tiles()


## ClearTreasureData: wTileBuffer's 16 tiles and the treasures' 16 bytes (wLevelTreasureIDs to
## wBottomBarTreasureIDs, wBottomBarFlags among them) cleared.
func clear_treasure_data() -> void:
	fill(W_TILE_BUFFER, 16 * 0x10, 0)
	fill(W_LEVEL_TREASURE_IDS, 0x10, 0)


## Func_9aaf4: with the level's musical coins got (CheckLevelMusicalCoinFlag), the 8-coin
## (wBottomBarFlags bit 6), its animation (the compass's state and unk7) cleared.
func _func_9aaf4() -> void:
	if not check_level_musical_coin_flag():
		return
	w2(W_BOTTOM_BAR_FLAGS, r2(W_BOTTOM_BAR_FLAGS) | 0x40)
	w2(W_COMPASS_OBJ + SCENE_OBJ_STATE, 0)
	w2(W_COMPASS_OBJ + SCENE_OBJ_STATE + 1, 0)


## CheckLevelMusicalCoinFlag (_CheckLevelMusicalCoinFlag): wOWLevel's bit in wMusicalCoinFlags (the
## original rotates the byte to bit 0 and back, leaving it as it was).
func check_level_musical_coin_flag() -> bool:
	var index: int = (r2(W_OW_LEVEL) - 1) & 0xFF
	return (r0(W_MUSICAL_COIN_FLAGS + (index >> 3)) & (1 << (index & 0x07))) != 0


## GetLevelTimeAttackScore: wOWLevel's best time (wLevelTimeAttackScores) to w2d0ee and w2d0ef.
func _get_level_time_attack_score() -> void:
	var level: int = r2(W_OW_LEVEL)
	if level == 0 or level == 0x80:
		return
	var at: int = W_LEVEL_TIME_ATTACK_SCORES + (((level - 1) * 2) & 0xFF)
	w2(W2D0EE, r0(at))
	w2(W2D0EF, r0(at + 1))


## LoadLevelTreasures: wOWLevel's four treasures (LevelTreasureIDs) to wLevelTreasureIDs.
func _load_level_treasures() -> void:
	var at: int = LEVEL_TREASURE_IDS + ((r2(W_OW_LEVEL) * 4) & 0xFF)
	for index: int in NUM_LEVEL_TREASURES:
		w2(W_LEVEL_TREASURE_IDS + index, rb(0x00, at + index))


## WriteUncollectedBottomBarTreasureIDs: the treasures not collected (wKeyAndTreasureFlags bits 4 to
## 7) become TREASURE_NONE in wLevelTreasureIDs.
func _write_uncollected_bottom_bar_treasure_ids() -> void:
	var flags: int = r0(W_KEY_AND_TREASURE_FLAGS) >> 4
	for index: int in NUM_LEVEL_TREASURES:
		if (flags & (1 << index)) == 0:
			w2(W_LEVEL_TREASURE_IDS + index, 0)


## LoadTreasurePals: each treasure's OB palette (TreasureOBPals).
func _load_treasure_pals() -> void:
	for index: int in NUM_LEVEL_TREASURES:
		w2(W_LEVEL_GREY_TREASURE_PAL + index, rb(TREASURE_BANK, TREASURE_OB_PALS + r2(W_LEVEL_TREASURE_IDS + index)))


## LoadTreasureTiles: each treasure's 4 tiles (TreasureGfx) into wTileBuffer, then (a bug: the code
## falls through into .CopyGfx) a fifth copy, for the treasure numbered by the last byte copied.
func _load_treasure_tiles() -> void:
	var destination: int = W_TILE_BUFFER
	var last: int = 0
	for index: int in NUM_LEVEL_TREASURES:
		last = _copy_treasure_gfx(r2(W_LEVEL_TREASURE_IDS + index), destination)
		destination += 0x40
	_copy_treasure_gfx(last, destination)


## LoadTreasureTiles.CopyGfx: treasure `treasure`'s 4 tiles (its address as the original computes it,
## right for treasures below 128) to `destination`; returns the last byte copied.
func _copy_treasure_gfx(treasure: int, destination: int) -> int:
	var first_carry: int = (treasure >> 7) & 1
	var a: int = (treasure << 1) & 0xFF
	var b: int = (a >> 7) & 1
	a = ((a << 1) | first_carry) & 0xFF
	var offset: int = (swap((a & 0xF0) | b) << 8) | swap(a & 0x0F)
	var source: int = (TREASURE_GFX + offset) & 0xFFFF
	copy_rom(TREASURE_BANK, source, destination, 0x40)
	return rb(TREASURE_BANK, source + 0x3F)
