class_name OverworldCollection
extends OverworldLoop
## The treasure collection (OverworldStateTable's sub-states $0c to $0f: _InitTreasureCollection,
## _TreasureCollection, src/engine/overworld/bank26.asm; PrintNumCollectedTreasures,
## src/engine/print_counts.asm) and Time Attack's best times (sub-states $16 to $19: _InitBestTimeList,
## _BestTimeList, bank56.asm), translated (WL3-052). The collection: opened from the top bar, its five pages of 20
## cells (5 columns, 4 rows) show the treasures got in their palettes and the others as boxes. The
## d-pad moves the cursor (a page on at the sides), A held with right or left turns the pages, B goes
## back to the map side; a cursor left 20 loops on a cell shows the cells linked to it
## (CollectionLinkTable). Its RAM is the general scene RAM from wCollectionRow, wTilemap and wAttrmap,
## and the scene objects 1 (the cursor), 2 to 8 (the links), 9 and 10 (the page arrows).

const COLLECTION_BANK: int = 0x26
const W_NUM_COLLECTED_TREASURES: int = 0xCA39  # BCD, the hundreds first
const W_COLLECTION_PAGE: int = 0xD058
const W_COLLECTION_CELL: int = 0xD059
const W_COLLECTION_ROW: int = 0xD800  # then wCollectionCol
const W_COLLECTION_COL: int = 0xD801
const W_COLLECTION_LINK_STATE: int = 0xD802
const W_COLLECTION_LINK_STATE_COUNTER: int = 0xD803
const W_COLLECTION_SCROLL_MODE: int = 0xD804
const W_COLLECTION_LINKED_CELLS: int = 0xD810  # 7 cells (each plus one), $80 ends them
const NUM_COLLECTION_COLS: int = 5
const NUM_COLLECTION_ROWS: int = 4
const NUM_COLLECTION_CELLS: int = NUM_COLLECTION_COLS * NUM_COLLECTION_ROWS
const NUM_COLLECTION_PAGES: int = 5
const NUM_TREASURES: int = 0x65
const NUM_TREASURE_TILES: int = 4
const NUM_LINKED_CELLS: int = 7
# Bank $26.
const TREASURE_101_GFX: int = 0x5940
const TREASURE_COLLECTION_GFX: int = 0x5AE0
const TREASURE_COLLECTION_CURSOR_GFX: int = 0x605C
const TREASURE_COLLECTION_TILEMAP: int = 0x6129
const TREASURE_COLLECTION_ATTRMAP: int = 0x62AC
const COLLECTION_CELL_LO_MAP_ADDRESSES: int = 0x6604  # ApplyPageTreasuresPals.lo_map_addresses
const COLLECTION_CELL_Y_COORDS: int = 0x6785  # GetCollectionCellCoords: by row, then x by column
const COLLECTION_CELL_X_COORDS: int = 0x6789
const COLLECTION_LINK_TABLE: int = 0x68E0
const OAM_9AC5D: int = 0x6C5D
const PALS_9AD05: int = 0x6D05
const PALS_9AD45: int = 0x6D45
## AnimateTreasureCollection's framesets by a scene object's state 1 to 4 (bank $26).
const COLLECTION_FRAMESETS: Array[int] = [0x6CE1, 0x6CEA, 0x6CF3, 0x6CFC]
## The V-Blank function its init sets (VBlank_TreasureCollection: the scroll and the OAM only), numbered
## by its sub-state.
const VBLANK_TREASURE_COLLECTION: int = 0x0D
const SST_OVERWORLD_08_FADE: int = 0x08
const LCDC_COLLECTION: int = 0x8F  # LCDC_ON | LCDC_BG_9C00 | LCDC_OBJ_16 | LCDC_OBJ_ON | LCDC_BG_ON


## _InitTreasureCollection: the LCD off, BG map 0 filled, the scroll cleared, its V-Blank function, the
## general scene RAM and the scene objects cleared; opened from the top bar, the page and cell of
## wTransitionParam's treasure (the last one got); the cursor placed, the palettes, the tiles (the
## cursor's, the page's treasures', the numbers'), its maps in wTilemap and wAttrmap with each cell's
## treasure or box, the page's number, to BG map 1 with the treasures' count; the cursor and the page
## arrows set up, the LCD on with BG map 1.
func init_treasure_collection() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()  # (the music, not ported)
	sim.wSCX = 0
	sim.wSCY = 0
	vblank_func = VBLANK_TREASURE_COLLECTION
	fill(W_COLLECTION_ROW, 0x800, 0)  # Func_9a54e
	fill(W_CUR_SCENE_OBJ, 0x200, 0)  # Func_9a559
	w2(W_HDMA, 0)
	if r2(W_IS_COLLECTION_OPEN) == 0:
		var page: int = 0
		var cell: int = 0
		var treasure: int = wTransitionParam
		if treasure != 0 and treasure < NUM_TREASURES:
			while treasure >= NUM_COLLECTION_CELLS + 1:
				page += 1
				treasure -= NUM_COLLECTION_CELLS
			cell = treasure - 1
		w2(W_COLLECTION_PAGE, page)
		w2(W_COLLECTION_CELL, cell)
		w2(W_IS_COLLECTION_OPEN, 1)
	get_collection_cell_row_and_column(r2(W_COLLECTION_CELL), W_COLLECTION_ROW)
	get_collection_cell_coords()
	copy_rom(COLLECTION_BANK, PALS_9AD45, W_TEMP_PALS_1, 8 * 8)  # LoadPalsToTempPals1
	copy_rom(COLLECTION_BANK, PALS_9AD05, W_TEMP_PALS_2, 8 * 8)  # LoadPalsToTempPals2
	decompress_to_vram(COLLECTION_BANK, TREASURE_COLLECTION_CURSOR_GFX, 0, 0x8000)
	decompress_to_vram(COLLECTION_BANK, TREASURE_COLLECTION_GFX, 0, 0x9000)
	load_collection_page_treasure_gfx()
	record_copy_to_vram(1, 0x8A00, NUMBERS_GFX, 0x14 * 0x10, COLLECTION_BANK)  # v1Tiles1 tile $20
	decompress_to_wram(COLLECTION_BANK, TREASURE_COLLECTION_ATTRMAP, W_ATTRMAP)
	decompress_to_wram(COLLECTION_BANK, TREASURE_COLLECTION_TILEMAP, W_TILEMAP)
	apply_page_treasures_pals()
	for row: int in [1, 2]:  # the count's tiles from VRAM 1, palette 1
		for column: int in range(2, 5):
			w2(W_ATTRMAP + row * TILEMAP_WIDTH + column, 0x01 | BG_BANK1)
	w2(W_TILEMAP + 1 * TILEMAP_WIDTH + 16, r2(W_COLLECTION_PAGE) + 1 + 0x20)
	record_wram_to_vram(0, 0x9C00, W_TILEMAP, 18 * TILEMAP_WIDTH)
	record_wram_to_vram(1, 0x9C00, W_ATTRMAP, 18 * TILEMAP_WIDTH)
	print_num_collected_treasures(0x9C00 + 1 * TILEMAP_WIDTH + 2)
	set_scene_obj_state(1, 0x01)
	for pair: Array in [[9, 0x08], [10, 0x98]]:
		wr(scene_obj(pair[0]) + SCENE_OBJ_X, pair[1])
		wr(scene_obj(pair[0]) + SCENE_OBJ_Y, 0x10)
	set_lcdc(LCDC_COLLECTION)
	sim.wSubState = byte(sim.wSubState + 1)


## LoadCollectionPageTreasureGfx: the page's 20 treasures' tiles (4 each, from TreasureGfx's fifth
## tile) to v0Tiles1 tile $20, and Treasure101Gfx to its tile $7c.
func load_collection_page_treasure_gfx() -> void:
	var size: int = NUM_TREASURE_TILES * NUM_COLLECTION_CELLS * 0x10
	var source: int = TREASURE_GFX + NUM_TREASURE_TILES * 0x10 + r2(W_COLLECTION_PAGE) * size
	record_copy_to_vram(0, 0x8A00, source, size, COLLECTION_BANK)
	record_copy_to_vram(0, 0x8FC0, TREASURE_101_GFX, NUM_TREASURE_TILES * 0x10, COLLECTION_BANK)


## ApplyPageTreasuresPals: each cell's treasure (the page's 20, from treasure page * 20 + 1, counted in
## w2dffe and w2dfff): got, its palette (TreasureOBPals) on its 2 by 2 tiles; else the box's tiles
## ($fc to $ff) in palette 4.
func apply_page_treasures_pals() -> void:
	w2(W2DFFE, 0)
	w2(W2DFFF, r2(W_COLLECTION_PAGE) * NUM_COLLECTION_CELLS + 1)
	while true:
		var treasure: int = r2(W2DFFF)
		var cell: int = r2(W2DFFE)
		var high: int = (W_TILEMAP >> 8) + (1 if cell >= NUM_COLLECTION_COLS else 0)
		var low: int = rb(COLLECTION_BANK, COLLECTION_CELL_LO_MAP_ADDRESSES + cell)
		var top: int = (high << 8) | low  # .GetAttrmapAddress: de, then hl a row below
		var bottom: int = (high << 8) | ((low + TILEMAP_WIDTH) & 0xFF)
		if is_treasure_collected(treasure) == 0:
			w2(top, 0xFC)
			w2(bottom, 0xFD)
			w2(top + 1, 0xFE)
			w2(bottom + 1, 0xFF)
			for at: int in [top, top + 1, top + TILEMAP_WIDTH + 1, top + TILEMAP_WIDTH]:
				w2(at - 0x300, 0x04)  # wAttrmap is three pages before wTilemap
		else:
			var palette: int = rb(COLLECTION_BANK, TREASURE_OB_PALS + treasure)
			for at: int in [bottom, bottom + 1, top, top + 1]:
				w2(at - 0x300, palette)
		w2(W2DFFE, cell + 1)
		w2(W2DFFF, treasure + 1)
		if cell + 1 == NUM_COLLECTION_CELLS:
			return


## PrintNumCollectedTreasures (bank $01): wNumCollectedTreasures' three digits, two tiles each ($a0 on,
## the top one at `at`, the bottom one a row below), to VRAM 0 (the LCD is off).
func print_num_collected_treasures(at: int) -> void:
	var count: int = (r0(W_NUM_COLLECTED_TREASURES) << 8) | r0(W_NUM_COLLECTED_TREASURES + 1)
	var bytes := PackedByteArray()
	bytes.resize(TILEMAP_WIDTH + 3)
	for index: int in 3:
		var digit: int = (count >> (8 - 4 * index)) & 0x0F
		bytes[index] = digit * 2 + 0xA0
		bytes[TILEMAP_WIDTH + index] = digit * 2 + 0xA1
	record_bytes_to_vram(0, at, bytes.slice(0, 3))
	record_bytes_to_vram(0, at + TILEMAP_WIDTH, bytes.slice(TILEMAP_WIDTH))


## GetCollectionCellRowAndColumn: `cell`'s row and column (5 columns) at `at` and the byte after it.
func get_collection_cell_row_and_column(cell: int, at: int) -> void:
	wr(at, cell / NUM_COLLECTION_COLS)
	wr(at + 1, cell % NUM_COLLECTION_COLS)


## GetCollectionCellCoords: the cursor (scene object 1) at the cell's place.
func get_collection_cell_coords() -> void:
	wr(scene_obj(1) + SCENE_OBJ_Y, rb(COLLECTION_BANK, COLLECTION_CELL_Y_COORDS + r2(W_COLLECTION_ROW)))
	wr(scene_obj(1) + SCENE_OBJ_X, rb(COLLECTION_BANK, COLLECTION_CELL_X_COORDS + r2(W_COLLECTION_COL)))


## _TreasureCollection: the d-pad's repeat, the input, the objects animated and drawn, the virtual OAM's
## unused entries cleared.
func treasure_collection() -> void:
	process_dpad_repeat()
	handle_treasure_collection_input()
	animate_treasure_collection()
	clear_unused_virtual_oam()


## HandleTreasureCollectionInput: B back to the map side (sub-state 8); A held shows the page arrows
## (scroll mode) and with right or left turns the page (sub-state $0c: faded and set up again);
## otherwise the arrows hidden, the d-pad moves the cursor (a page on past the sides; not past the top
## or the bottom row), its links cleared; no d-pad, the links' state goes on.
func handle_treasure_collection_input() -> void:
	var pressed: int = sim.wJoypadPressed
	if (pressed & PAD_B) != 0:
		sim.wSubState = SST_OVERWORLD_08_FADE  # (the music and sounds stopped, not ported)
		return
	var held: int = sim.wJoypadDown
	if (held & PAD_A) != 0:
		if r2(W_COLLECTION_SCROLL_MODE) == 0:  # .SetScrollMode
			w2(W_COLLECTION_SCROLL_MODE, 1)
			set_scene_obj_state(9, 0x03)
			set_scene_obj_state(10, 0x04)
		var page: int = r2(W_COLLECTION_PAGE)
		if (held & PAD_RIGHT) != 0:
			w2(W_COLLECTION_PAGE, 0 if page == NUM_COLLECTION_PAGES - 1 else page + 1)
		elif (held & PAD_LEFT) != 0:
			w2(W_COLLECTION_PAGE, NUM_COLLECTION_PAGES - 1 if page == 0 else page - 1)
		else:
			return
		sim.wSubState = SST_OVERWORLD_COLLECTION  # (a sound, the music stopped, not ported)
		return
	w2(W_COLLECTION_SCROLL_MODE, 0)
	wr(scene_obj(9) + SCENE_OBJ_STATE, 0)
	wr(scene_obj(10) + SCENE_OBJ_STATE, 0)
	var column: int = r2(W_COLLECTION_COL)
	var row: int = r2(W_COLLECTION_ROW)
	var cell: int = r2(W_COLLECTION_CELL)
	if (pressed & PAD_RIGHT) != 0:
		if column == NUM_COLLECTION_COLS - 1:  # .page_right: the row's first cell, a page on
			w2(W_COLLECTION_COL, 0)
			w2(W_COLLECTION_CELL, cell - NUM_COLLECTION_ROWS)
			w2(W_COLLECTION_PAGE, (r2(W_COLLECTION_PAGE) + 1) % NUM_COLLECTION_PAGES)
			sim.wSubState = SST_OVERWORLD_COLLECTION  # (a sound, not ported)
			return
		w2(W_COLLECTION_COL, column + 1)
		cell += 1
	elif (pressed & PAD_LEFT) != 0:
		if column == 0:  # .page_left: the row's last cell, a page back
			w2(W_COLLECTION_COL, NUM_COLLECTION_ROWS)
			w2(W_COLLECTION_CELL, cell + NUM_COLLECTION_ROWS)
			var page: int = r2(W_COLLECTION_PAGE)
			w2(W_COLLECTION_PAGE, NUM_COLLECTION_PAGES - 1 if page == 0 else page - 1)
			sim.wSubState = SST_OVERWORLD_COLLECTION  # (a sound, not ported)
			return
		w2(W_COLLECTION_COL, column - 1)
		cell -= 1
	elif (pressed & PAD_UP) != 0:
		if row == 0:
			return  # .cant_scroll (a sound, not ported)
		w2(W_COLLECTION_ROW, row - 1)
		cell -= NUM_COLLECTION_COLS
	elif (pressed & PAD_DOWN) != 0:
		if row >= NUM_COLLECTION_ROWS - 1:
			return  # .cant_scroll (a sound, not ported)
		w2(W_COLLECTION_ROW, row + 1)
		cell += NUM_COLLECTION_COLS
	else:
		process_collection_link_state()
		return
	w2(W_COLLECTION_CELL, cell)  # .got_target_cell (a sound, not ported)
	for number: int in range(2, 9):
		wr(scene_obj(number) + SCENE_OBJ_STATE, 0)
	w2(W_COLLECTION_LINK_STATE, 0)
	w2(W_COLLECTION_LINK_STATE_COUNTER, 0)
	get_collection_cell_coords()


## ProcessCollectionLinkState: its counter counts; by its state: started (0), $14 loops waited (1), the
## cell's linked cells (CollectionLinkTable, by page and cell) copied (2: none, on to 3), shown (4:
## scene objects 2 to 8 at each linked cell other than the cursor's, in state 2, until $80), then
## nothing (3, 5).
func process_collection_link_state() -> void:
	w2(W_COLLECTION_LINK_STATE_COUNTER, r2(W_COLLECTION_LINK_STATE_COUNTER) + 1)
	match r2(W_COLLECTION_LINK_STATE):
		0:
			_advance_collection_link_state()
		1:
			if r2(W_COLLECTION_LINK_STATE_COUNTER) >= 0x14:
				_advance_collection_link_state()
		2:
			var cells: int = pointer_from_table(COLLECTION_BANK,
					pointer_from_table(COLLECTION_BANK, COLLECTION_LINK_TABLE, r2(W_COLLECTION_PAGE)),
					r2(W_COLLECTION_CELL))
			if rb(COLLECTION_BANK, cells) == 0x80:
				_advance_collection_link_state()
				return
			copy_rom(COLLECTION_BANK, cells, W_COLLECTION_LINKED_CELLS, NUM_LINKED_CELLS)
			_advance_collection_link_state()
			_advance_collection_link_state()
		3, 5:
			pass
		4:
			for index: int in NUM_LINKED_CELLS:
				var linked: int = r2(W_COLLECTION_LINKED_CELLS + index)
				if linked == 0x80:
					break
				linked = byte(linked - 1)
				if linked == r2(W_COLLECTION_CELL):
					continue
				var obj: int = scene_obj(2 + index)
				get_collection_cell_row_and_column(linked, obj)
				set_scene_obj_state(2 + index, 0x02)
				# Func_9a78e: the row and column to the cell's y and x
				wr(obj + SCENE_OBJ_Y, rb(COLLECTION_BANK, COLLECTION_CELL_Y_COORDS + rd(obj + SCENE_OBJ_Y)))
				wr(obj + SCENE_OBJ_X, rb(COLLECTION_BANK, COLLECTION_CELL_X_COORDS + rd(obj + SCENE_OBJ_X)))
			_advance_collection_link_state()
		var state:
			_note("ProcessCollectionLinkState state %d (past its table)" % state)


## .AdvanceState: the link state one on, its counter cleared.
func _advance_collection_link_state() -> void:
	w2(W_COLLECTION_LINK_STATE_COUNTER, 0)
	w2(W_COLLECTION_LINK_STATE, r2(W_COLLECTION_LINK_STATE) + 1)


## AnimateTreasureCollection: scene objects 1 to 10 in a state (1 to 4) animated with its frameset and
## drawn with OAM_9ac5d (bank $26).
func animate_treasure_collection() -> void:
	for number: int in range(1, 11):
		var obj: int = scene_obj(number)
		var state: int = rd(obj + SCENE_OBJ_STATE)
		if state == 0:
			continue
		if state > COLLECTION_FRAMESETS.size():
			_note("AnimateTreasureCollection state %d (past its table)" % state)
			continue
		update_ow_animation(obj + SCENE_OBJ_DURATION, COLLECTION_FRAMESETS[state - 1], COLLECTION_BANK)
		load_ow_sprite_with_scroll(obj, OAM_9AC5D, COLLECTION_BANK)


# --- Time Attack's best times (bank $56) ---

const BEST_TIMES_BANK: int = 0x56
const BEST_TIMES_GFX_BANK: int = 0x2C
const BEST_TIME_LIST_GFX: int = 0x66BF  # bank $2c
const BEST_TIME_LIST_TILEMAP: int = 0x6E72
const BEST_TIME_LIST_ATTRMAP: int = 0x7143
const BEST_TIMES_BG_MAP_ADDRESSES: int = 0x4B31  # PrintBestTimes.bg_map_address_table, by level
const PALS_158B63: int = 0x4B63
const W2DF00: int = 0xDF00  # a level's time's 5 tiles
const NUM_TIME_ATTACK_LEVELS: int = 25
const BEST_TIMES_SCROLL_END: int = 0x70  # the list's lower half
const BEST_TIMES_WAIT: int = 0xB4
const TILE_COLON: int = 0xB6
## Its V-Blank function (.VBlank_158a14: the scroll and the OAM only), numbered by its sub-state.
const VBLANK_BEST_TIME_LIST: int = 0x17
const LCDC_BEST_TIME_LIST: int = 0x83  # LCDC_BG_ON | LCDC_OBJ_ON | LCDC_ON


## _InitBestTimeList: the LCD off, BG map 0 filled, the scroll at the list's half with the map side's
## levels (its read of wObj1SubState's address, in WRAM bank 2 wCurMapSide: South and East the lower),
## its V-Blank function, the general scene RAM cleared, its palettes, tiles and maps, each level's time
## (PrintBestTimes), the LCD on.
func init_best_time_list() -> void:
	disable_lcd()
	fill_bg_map_0_with_7f()
	clear_virtual_oam()  # (the music, not ported)
	sim.wSCX = 0
	sim.wSCY = BEST_TIMES_SCROLL_END if (r2(W_CUR_MAP_SIDE) >> 1) != 0 else 0
	vblank_func = VBLANK_BEST_TIME_LIST
	fill(W_COLLECTION_ROW, 0x800, 0)  # .Func_158a09
	copy_rom(BEST_TIMES_BANK, PALS_158B63, W_TEMP_PALS_1, 8 * 8)  # LoadPalsToTempPals1
	decompress_to_vram(BEST_TIMES_GFX_BANK, BEST_TIME_LIST_GFX, 0, 0x8A00)  # v0Tiles1 tile $20
	decompress_to_vram(BEST_TIMES_GFX_BANK, BEST_TIME_LIST_ATTRMAP, 1, 0x9800)
	decompress_to_vram(BEST_TIMES_GFX_BANK, BEST_TIME_LIST_TILEMAP, 0, 0x9800)
	print_best_times()
	set_lcdc(LCDC_BEST_TIME_LIST)
	sim.wSubState = byte(sim.wSubState + 1)


## PrintBestTimes: each level's time (wLevelTimeAttackScores: minutes, then seconds, BCD) as five
## tiles (two digits, the colon, two digits; $a0 on, two tiles a digit) built in w2df00, to its place
## in BG map 0 (the bottom row the tiles plus one); w2dfff counts the levels.
func print_best_times() -> void:
	for level: int in NUM_TIME_ATTACK_LEVELS:
		w2(W2DFFF, level)
		var minutes: int = r0(W_LEVEL_TIME_ATTACK_SCORES + level * 2)
		var seconds: int = r0(W_LEVEL_TIME_ATTACK_SCORES + level * 2 + 1)
		var tiles: Array[int] = [(minutes >> 4) * 2 + 0xA0, (minutes & 0x0F) * 2 + 0xA0, TILE_COLON,
				(seconds >> 4) * 2 + 0xA0, (seconds & 0x0F) * 2 + 0xA0]
		for index: int in tiles.size():
			w2(W2DF00 + index, tiles[index])
		var at: int = rw(BEST_TIMES_BANK, BEST_TIMES_BG_MAP_ADDRESSES + level * 2)
		for row: int in 2:
			var bytes := PackedByteArray()
			for tile: int in tiles:
				bytes.append(byte(tile + row))
			record_bytes_to_vram(0, at + row * TILEMAP_WIDTH, bytes)
	w2(W2DFFF, NUM_TIME_ATTACK_LEVELS)


## _BestTimeList: by hand (wCollectionRow 0), up or down held scrolls the list a line a loop between 0
## and $70 (and restarts the idle count), B or Start leaves (sub-state 8), and 256 loops without the
## d-pad start the scroll by itself; that (wCollectionRow 1, by wColourFadeDiff) goes down to $70, waits
## $b4 loops, goes up to 0, waits again, and over, until A, B, Start, up, or down stops it.
func best_time_list() -> void:
	var pressed: int = sim.wJoypadPressed
	if r2(W_COLLECTION_ROW) == 0:
		var held: int = sim.wJoypadDown
		if (held & PAD_UP) != 0:
			if sim.wSCY == 0:
				return
			sim.wSCY -= 1
			w2(W_COLLECTION_COL, 0)
			return
		if (held & PAD_DOWN) != 0:
			if sim.wSCY == BEST_TIMES_SCROLL_END:
				return
			sim.wSCY += 1
			w2(W_COLLECTION_COL, 0)
			return
		w2(W_COLLECTION_COL, r2(W_COLLECTION_COL) + 1)
		if r2(W_COLLECTION_COL) == 0:
			w2(W_COLLECTION_ROW, r2(W_COLLECTION_ROW) + 1)
			w2(W_COLOUR_FADE_DIFF, 0)
		if (pressed & (PAD_B | PAD_START)) != 0:
			sim.wSubState = SST_OVERWORLD_08_FADE
		return
	if (pressed & (PAD_A | PAD_B | PAD_START | PAD_UP | PAD_DOWN)) != 0:  # .Func_158ac2
		w2(W_COLLECTION_ROW, 0)
		return
	match r2(W_COLOUR_FADE_DIFF):
		1, 3:
			w2(W_COLLECTION_LINK_STATE_COUNTER, r2(W_COLLECTION_LINK_STATE_COUNTER) + 1)
			if r2(W_COLLECTION_LINK_STATE_COUNTER) < BEST_TIMES_WAIT:
				return
			w2(W_COLLECTION_LINK_STATE_COUNTER, 0)
			w2(W_COLOUR_FADE_DIFF, (r2(W_COLOUR_FADE_DIFF) + 1) & 0x03)
		2:
			if sim.wSCY == 0:
				_next_best_times_scroll()
			else:
				sim.wSCY -= 1
		_:  # 0, and past the table (debug_nop falls through to it)
			if sim.wSCY < BEST_TIMES_SCROLL_END:
				sim.wSCY += 1
			else:
				_next_best_times_scroll()


## .asm_158a96: the wait counter cleared, wColourFadeDiff one on.
func _next_best_times_scroll() -> void:
	w2(W_COLLECTION_LINK_STATE_COUNTER, 0)
	w2(W_COLOUR_FADE_DIFF, r2(W_COLOUR_FADE_DIFF) + 1)
