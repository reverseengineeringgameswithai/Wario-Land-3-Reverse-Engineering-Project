class_name PerfectVram
extends ScreenVram
## What the Perfect screen puts in VRAM (WL3-052), from perfect.json's graphics: InitPerfectScreen's
## FillBGMap0_With7f, LoadPerfectGfx (PerfectGfx to bank 0's $8000), and Func_dc13e (PerfectAttrmap and
## PerfectTilemap on BG map 0), shown with LCDC_DEFAULT. Its palettes are LoadPerfectPals' temporary sets
## the fade in darkens to (wTempPals1 and wTempPals2), taken when the screen loads (the window draws the
## first fades over them); UpdatePerfectScreen's SlowFadeInScreen steps them toward the sets as each
## step saw them.

const PERFECT_GFX: String = "37:423b"
const PERFECT_TILEMAP: String = "37:5417"
const PERFECT_ATTRMAP: String = "37:55b5"


func _init(document: Dictionary = {}) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)


## One loop: the screen its init loaded with its palettes, and a step of its fades in.
func update(perfect: PerfectSim, _sim: LevelSim = null) -> void:
	for load: Array in perfect.screen_loads:
		match String(load[0]):
			"perfect":
				load_perfect()
				bg_palettes = perfect.wram[0].slice(0, 0x40)
				obj_palettes = perfect.wram[0].slice(0x40, 0x80)
			"fade_in_step":
				var target: PackedByteArray = load[1] if load.size() > 1 else perfect.wram[0].slice(0, 0x80)
				bg_palettes = fade_in_step(bg_palettes, target.slice(0, 0x40))
				obj_palettes = fade_in_step(obj_palettes, target.slice(0x40, 0x80))


## InitPerfectScreen's drawing: FillBGMap0_With7f, LoadPerfectGfx, and Func_dc13e (the attributes, then
## the tiles).
func load_perfect() -> void:
	screen = "perfect"
	fill_bg_map_0(0x7F)
	write(0, VRAM_START, _bytes("compressed", PERFECT_GFX))
	write(1, BG_MAP_0, _bytes("compressed", PERFECT_ATTRMAP))
	write(0, BG_MAP_0, _bytes("compressed", PERFECT_TILEMAP))
