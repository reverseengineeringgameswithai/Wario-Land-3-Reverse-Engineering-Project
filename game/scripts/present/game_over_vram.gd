class_name GameOverVram
extends ScreenVram
## What the game over screen puts in VRAM (WL3-052), from game_over.json's graphics: InitGameOverScreen's
## FillBGMap0_With7f, LoadGameOverGfx (GameOverGfx to bank 0's $8000, then WarioSleepGfx's $80 tiles over
## its start), and Func_db4cf (GameOverAttrmap and GameOverTilemap on BG map 0), shown with LCDC_DEFAULT.
## Its palettes are LoadGameOverPals' temporary sets the fade in darkens to (wTempPals1 and wTempPals2),
## taken when the screen loads (the window draws the fades over them).

const GAME_OVER_GFX: String = "36:7589"
const GAME_OVER_TILEMAP: String = "36:7aee"
const GAME_OVER_ATTRMAP: String = "36:7b8f"
const WARIO_SLEEP_GFX: String = "76:6800"


func _init(document: Dictionary = {}) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)


## One loop: the screen its init loaded, with its palettes.
func update(game_over: GameOverSim, _sim: LevelSim = null) -> void:
	for load: Array in game_over.screen_loads:
		if String(load[0]) == "game_over":
			load_game_over()
			bg_palettes = game_over.wram[0].slice(0, 0x40)
			obj_palettes = game_over.wram[0].slice(0x40, 0x80)


## InitGameOverScreen's drawing: FillBGMap0_With7f, LoadGameOverGfx, and Func_db4cf (the attributes,
## then the tiles).
func load_game_over() -> void:
	screen = "game_over"
	fill_bg_map_0(0x7F)
	write(0, VRAM_START, _bytes("compressed", GAME_OVER_GFX))
	write(0, VRAM_START, _bytes("raw", WARIO_SLEEP_GFX))
	write(1, BG_MAP_0, _bytes("compressed", GAME_OVER_ATTRMAP))
	write(0, BG_MAP_0, _bytes("compressed", GAME_OVER_TILEMAP))
