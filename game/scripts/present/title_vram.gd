class_name TitleVram
extends ScreenVram
## What the title puts in VRAM (WL3-055), from title.json's graphics: Init's (both banks cleared
## (ClearVRAM), BG map 0 filled with $7f, BG map 1's tiles $ff), InitIntroSequence's screen (PlaneGfx
## to bank 1's $8000, TitleScreenGfx to bank 0's, the attribute and tile maps on BG map 0; with a
## save the menu's rows behind the scenery and the box under them), and VBlank_Title's box. Its
## palettes are the temporary sets its fade in darkens to (wTempPals1 and wTempPals2), taken when
## the screen loads (the window draws the fades over them); after the intro SlowFadeInScreen takes the
## palettes a step at a time to the title's (its V-Blank loads them). New Game's language selection
## draws over it: the font's tiles and the text, its rows highlighted by VBlank_LanguageSelection, the
## font's palettes; and Time Attack's description (WL3-058): the font, the prologue's background
## tiles, and the text by wLanguage, with Pals_71b0.

const TITLE_SCREEN_GFX: String = "01:5082"
const PLANE_GFX: String = "01:635c"
const TITLE_SCREEN_TILEMAP: String = "01:697a"
const TITLE_SCREEN_ATTRMAP: String = "01:6ae7"
const TITLE_SCREEN_BOX_TILEMAP: String = "01:6b47"
## InitIntroSequence.no_intro: the menu's rows given BG priority (bank 1's bit 7), 11 entries from
## column 4 of rows 12 and 13, then 16 and 17.
const PRIORITY_ROWS: Array[int] = [12, 13, 16, 17]
const PRIORITY_COLUMN: int = 4
const PRIORITY_WIDTH: int = 11
## The box: two rows of 12 tiles from (4, 14).
const BOX_X: int = 4
const BOX_Y: int = 14
const BOX_WIDTH: int = 12
const FONT_GFX: String = "7c:5d5d"
const LANGUAGE_SELECTION_TEXT_MAP_1: String = "7c:7650"
const LANGUAGE_SELECTION_TEXT_MAP_2: String = "7c:767f"
## VBlank_LanguageSelection: 13 attributes from column 5 of rows 7 (English) and 9 (Japanese), palette 6
## on the language chosen and 7 on the other.
const LANGUAGE_ROWS: Array[int] = [7, 9]
## Time Attack's description (WL3-058): PrologueBackgroundGfx's $80 tiles (to VRAM 0's $9000) and
## LoadTimeAttackText's maps by wLanguage (tiles, attributes).
const PROLOGUE_BACKGROUND_GFX: String = "2c:4f80"
const TILES_2: int = 0x9000
const TIME_ATTACK_TEXT_MAPS: Dictionary = {TitleSim.ENGLISH: ["01:73e6", "01:74e8"], 0: ["01:71f0", "01:7316"]}
const LANGUAGE_COLUMN: int = 5
const LANGUAGE_WIDTH: int = 13


## `power_on`: VRAM as Init leaves it (else only what the title's and the language selection's loads
## write is known).
func _init(document: Dictionary = {}, power_on: bool = true) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)
	if not power_on:
		return
	var cleared := PackedByteArray()
	cleared.resize(VRAM_SIZE)
	write(0, VRAM_START, cleared)
	write(1, VRAM_START, cleared)
	fill_bg_map_0(0x7F)
	var fill := PackedByteArray()
	fill.resize(0x400)
	fill.fill(0xFF)
	write(0, BG_MAP_1, fill)


## One loop: the screen its init loaded with its palettes, a step of the fade after the intro, and
## VBlank_Title's box.
func update(title: TitleSim, _sim: LevelSim = null) -> void:
	for load: Array in title.screen_loads:
		match String(load[0]):
			"title":
				load_title(bool(load[1]))
				bg_palettes = title.wram[0].slice(0, 0x40)
				obj_palettes = title.wram[0].slice(0x40, 0x80)
			"fade_in_step":
				bg_palettes = fade_in_step(bg_palettes, title.wram[0].slice(0, 0x40))
				obj_palettes = fade_in_step(obj_palettes, title.wram[0].slice(0x40, 0x80))
			"language_selection":
				load_language_selection()
				bg_palettes = title.wram[0].slice(0, 0x40)
				obj_palettes = title.wram[0].slice(0x40, 0x80)
			"time_attack_description":
				load_time_attack_description(int(load[1]))
				bg_palettes = title.wram[0].slice(0, 0x40)
	for entry: Array in title.vblank_writes:
		match String(entry[0]):
			"box":
				_box()
			"language":
				_highlight_language(int(entry[1]))


## InitIntroSequence's drawing: FillBGMap0_With7f, LoadTitleScreenTiles, LoadTitleScreenTileMap, and
## with a save the menu's rows behind the scenery and the box under them.
func load_title(saved: bool) -> void:
	screen = "title"
	fill_bg_map_0(0x7F)
	write(1, VRAM_START, _bytes("compressed", PLANE_GFX))
	write(0, VRAM_START, _bytes("compressed", TITLE_SCREEN_GFX))
	write(1, BG_MAP_0, _bytes("compressed", TITLE_SCREEN_ATTRMAP))
	write(0, BG_MAP_0, _bytes("compressed", TITLE_SCREEN_TILEMAP))
	if not saved:
		return
	for row: int in PRIORITY_ROWS:
		for column: int in range(PRIORITY_COLUMN, PRIORITY_COLUMN + PRIORITY_WIDTH):
			var address: int = map_address(BG_MAP_0, column, row)
			write_byte(1, address, read_byte(1, address) | 0x80)
	_box()


## InitLanguageSelection's drawing: FillBGMap0_With7f, LoadFontTiles, and LoadLanguageSelectionText
## (the attributes, then the tiles, on BG map 0).
func load_language_selection() -> void:
	screen = "language_selection"
	fill_bg_map_0(0x7F)
	write(0, VRAM_START, _bytes("compressed", FONT_GFX))
	write(1, BG_MAP_0, _bytes("compressed", LANGUAGE_SELECTION_TEXT_MAP_2))
	write(0, BG_MAP_0, _bytes("compressed", LANGUAGE_SELECTION_TEXT_MAP_1))


## InitTimeAttackDescription's drawing: FillBGMap0_With7f, LoadTimeAttackDescriptionTiles (the font
## to VRAM 1's $8000, the prologue's background tiles to VRAM 0's $9000), and LoadTimeAttackText (the
## attributes, then the tiles, on BG map 0) by `language`.
func load_time_attack_description(language: int) -> void:
	screen = "time_attack_description"
	fill_bg_map_0(0x7F)
	write(1, VRAM_START, _bytes("compressed", FONT_GFX))
	write(0, TILES_2, _bytes("raw", PROLOGUE_BACKGROUND_GFX))
	var maps: Array = TIME_ATTACK_TEXT_MAPS[TitleSim.ENGLISH if language != 0 else 0]
	write(1, BG_MAP_0, _bytes("compressed", maps[1]))
	write(0, BG_MAP_0, _bytes("compressed", maps[0]))


## VBlank_LanguageSelection's rows: palette 6 on the chosen language's (1 English, else Japanese), 7
## on the other's.
func _highlight_language(language: int) -> void:
	for index: int in LANGUAGE_ROWS.size():
		var chosen: bool = (index == 0) == (language == TitleSim.ENGLISH)
		var row := PackedByteArray()
		row.resize(LANGUAGE_WIDTH)
		row.fill(0x06 if chosen else 0x07)
		write(1, map_address(BG_MAP_0, LANGUAGE_COLUMN, LANGUAGE_ROWS[index]), row)


## TitleScreenBoxTilemap's two rows at (4, 14) and (4, 15) of BG map 0.
func _box() -> void:
	var tiles: PackedByteArray = _bytes("raw", TITLE_SCREEN_BOX_TILEMAP)
	for row: int in 2:
		write(0, map_address(BG_MAP_0, BOX_X, BOX_Y + row), tiles.slice(row * BOX_WIDTH, (row + 1) * BOX_WIDTH))
