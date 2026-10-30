class_name CreditsVram
extends ScreenVram
## What the credits put in VRAM (WL3-052), from credits.json's graphics, and the LCD's registers:
## InitCredits' screen (FillBGMap0_With7f; LoadCreditsGfx: PrologueGfx to bank 1's $8000, MusicBoxGfx's
## $30 tiles to bank 1's $8800, CreditsFontGfx then CreditsMusicBoxGfx to bank 0's $8000; Func_16041f:
## CreditsAttrmap and CreditsTilemap on BG map 1), LCDC_DEFAULT with the window at (0, 0), and
## VBlank_160439's writes: each line's palettes and blanks, then its text, on BG map 0, and for the
## close-up the temporary palettes applied and the window turned on (BG map 1 over the whole screen).
## Its palettes are the temporary sets the fade in darkens to (wTempPals1 and wTempPals2), taken when
## the screen loads (the window draws the fades over them); the close-up's fade in (SlowFadeInScreen)
## steps them.

const PROLOGUE_GFX: String = "2c:5780"
const MUSIC_BOX_GFX: String = "2c:4000"
const CREDITS_FONT_GFX: String = "58:464c"
const CREDITS_MUSIC_BOX_GFX: String = "58:4af9"
const CREDITS_TILEMAP: String = "58:5744"
const CREDITS_ATTRMAP: String = "58:579c"
const TILES_1: int = 0x8800

## rLCDC, rWX, and rWY as InitCredits and VBlank_160439 leave them.
var lcdc: int = 0
var wx: int = 0
var wy: int = 0


func _init(document: Dictionary = {}) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)


## One loop: the screen its init loaded with its palettes, a step of the close-up's fade in, and
## VBlank_160439's writes.
func update(credits: CreditsSim, _sim: LevelSim = null) -> void:
	for load: Array in credits.screen_loads:
		match String(load[0]):
			"credits":
				load_credits()
				bg_palettes = credits.wram[0].slice(0, 0x40)
				obj_palettes = credits.wram[0].slice(0x40, 0x80)
			"fade_in_step":
				bg_palettes = fade_in_step(bg_palettes, credits.wram[0].slice(0, 0x40))
				obj_palettes = fade_in_step(obj_palettes, credits.wram[0].slice(0x40, 0x80))
	for entry: Array in credits.vblank_writes:
		write_byte(int(entry[0]), int(entry[1]), int(entry[2]))
	if credits.vblank_pals:
		# ApplyTempPals1ToBGPals, ApplyTempPals2ToOBPals, and the window on from BG map 1
		bg_palettes = credits.wram[0].slice(0, 0x40)
		obj_palettes = credits.wram[0].slice(0x40, 0x80)
		lcdc |= CreditsSim.LCDC_WIN_ON | CreditsSim.LCDC_WIN_9C00


## InitCredits' drawing: FillBGMap0_With7f, LoadCreditsGfx, and Func_16041f (the attributes, then the
## tiles, on BG map 1); LCDC_DEFAULT, rWY 0, and rWX 0 + WX_OFS.
func load_credits() -> void:
	screen = "credits"
	fill_bg_map_0(0x7F)
	write(1, VRAM_START, _bytes("compressed", PROLOGUE_GFX))
	write(1, TILES_1, _bytes("raw", MUSIC_BOX_GFX))
	write(0, VRAM_START, _bytes("compressed", CREDITS_FONT_GFX))
	write(0, VRAM_START, _bytes("compressed", CREDITS_MUSIC_BOX_GFX))
	write(1, BG_MAP_1, _bytes("compressed", CREDITS_ATTRMAP))
	write(0, BG_MAP_1, _bytes("compressed", CREDITS_TILEMAP))
	lcdc = CreditsSim.LCDC_DEFAULT
	wx = CreditsSim.WX_OFS
	wy = 0


## A copy with the registers, for drawing a frame that changes as it is drawn.
func copy() -> ScreenVram:
	var other := CreditsVram.new()
	other.gfx = gfx
	other.screen = screen
	other.bg_palettes = bg_palettes.duplicate()
	other.obj_palettes = obj_palettes.duplicate()
	other.lcdc = lcdc
	other.wx = wx
	other.wy = wy
	for bank: int in 2:
		other.vram[bank] = vram[bank].duplicate()
		other.written[bank] = written[bank].duplicate()
	return other
