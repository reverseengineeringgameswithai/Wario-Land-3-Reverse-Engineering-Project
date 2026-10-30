class_name TempleVram
extends ScreenVram
## What the hidden figure's fight (the Temple, level $c8; WL3-052) shows, from temple.json's graphics:
## InitLevel's LoadHiddenFigureGfx (HiddenFigure1Gfx and HiddenFigure2Gfx to both banks' $8000, the
## figure's maps to BG map 0 and the window's floor to BG map 1), then Wario's tile set at VRAM 0's
## $8000 as the V-Blank copies it (over the figure's first $80 tiles) and the room's animated tiles at
## VRAM 1's $9700. Drawn with LCDC $e7 (the window from BG map 1 at WX 7 and rWY); its BG palettes are
## Pals_db000 with palettes 0-5 as the figure last wrote them (SetBGPals), its OBJ palettes Wario's (0-1,
## SetWarioPal), the particles' (2), and Pals_db040 (3-7), as SlowFadeFromWhite leaves wTempPals1 and
## wTempPals2. The OAM is UpdateLevel's: the particles, the objects drawn over Wario, Wario, the other
## objects, up to 40 entries, the rest cleared. The scroll is LevelVBlankFunc's: wSCY plus wSCYShake
## (which the fight's wSCY holds already: the shake shows twice), and wSCX. Each update is the frame
## after the loop, as its V-Blank leaves it; the palettes the loop wrote while its own frame was drawn
## are taken whole.

const LCDC: int = 0xE7  # LCDC_ON | LCDC_WIN_9C00 | LCDC_WIN_ON | LCDC_OBJ_16 | LCDC_OBJ_ON | LCDC_BG_ON
const WX: int = 7  # 0 + WX_OFS
const HIDDEN_FIGURE_1_GFX: String = "36:4000"
const HIDDEN_FIGURE_2_GFX: String = "36:5800"
const HIDDEN_FIGURE_1_MAP: String = "36:7068"
const HIDDEN_FIGURE_2_MAP: String = "36:7193"
const HIDDEN_FIGURE_3_MAP: String = "36:723b"
const HIDDEN_FIGURE_4_MAP: String = "36:7268"
const PALS_DB000: String = "36:7000"
const PALS_DB040: String = "36:7040"
const FIGURE_PALS_BANK: int = 0x13  # SetBGPals' palette sets (HiddenFigureFunctions.PALS_4D01B and on)
const WARIO_TILES: int = 0x8000
const OAM_SIZE: int = 0xA0
const OBJ_PALETTE_BYTES: int = 8

var oam: PackedByteArray = PackedByteArray()
var scx: int = 0
var scy: int = 0
var wy: int = 0
var _wario: WarioSprites
var _objects: ObjectSprites
var _loads: int = 0
var _tile_set: String = ""


func _init(document: Dictionary = {}, animation: Dictionary = {}, wario: WarioSprites = null,
		objects: ObjectSprites = null) -> void:
	super(document)
	animated_tiles = animation.get("animated_tiles_gfx", {})
	_wario = wario
	_objects = objects
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)
	oam.resize(OAM_SIZE)


## One loop: the figure's graphics when InitLevel loaded them, then what the V-Blank after the loop
## leaves: Wario's tile set, the room's animated tiles, the palettes, the OAM, the scroll, and rWY.
func update(sim: LevelSim) -> void:
	if sim.hidden_figure_gfx_loads != _loads:
		_loads = sim.hidden_figure_gfx_loads
		load_hidden_figure()
		_tile_set = ""
		_animation_writes = sim.animated_tiles_writes
	if screen.is_empty():
		return
	var tile_set: String = "%02x:%04x" % [sim.wDMASourceBank, sim.wDMASourcePtr]
	if tile_set != _tile_set and _wario != null and _wario.tile_sets.has(tile_set):
		_tile_set = tile_set
		write(0, WARIO_TILES, _wario.tile_sets[tile_set])
	room_animation(sim)
	bg_palettes = _bytes("palettes", PALS_DB000)
	if sim.hidden_figure_bg_pals != 0:
		var written: PackedByteArray = _bytes("palettes", "%02x:%04x" % [FIGURE_PALS_BANK, sim.hidden_figure_bg_pals])
		for at: int in written.size():
			bg_palettes[at] = written[at]
	_obj_palettes(sim)
	oam = sprites(sim)
	scx = sim.wSCX
	scy = (sim.wSCY + sim.wSCYShake) & 0xFF
	wy = sim.rWY


## LoadHiddenFigureGfx's tiles and maps: .LoadTiles (bank 1, then bank 0), then .LoadMap (bank 1's
## two maps, then bank 0's).
func load_hidden_figure() -> void:
	screen = "temple"
	write(1, VRAM_START, _bytes("raw", HIDDEN_FIGURE_2_GFX))
	write(0, VRAM_START, _bytes("raw", HIDDEN_FIGURE_1_GFX))
	write(1, BG_MAP_0, _bytes("compressed", HIDDEN_FIGURE_2_MAP))
	write(1, BG_MAP_1, _bytes("compressed", HIDDEN_FIGURE_4_MAP))
	write(0, BG_MAP_0, _bytes("compressed", HIDDEN_FIGURE_1_MAP))
	write(0, BG_MAP_1, _bytes("compressed", HIDDEN_FIGURE_3_MAP))


## OBJ palettes 0-1 Wario's (wWarioPalsPtr), 2 the particles', 3-7 Pals_db040.
func _obj_palettes(sim: LevelSim) -> void:
	var key: String = "%02x:%04x" % [LevelSim.WARIO_PALETTES_BANK, sim.wWarioPalsPtr]
	if _wario != null and _wario.palettes.has(key):
		for palette: int in WarioSprites.OBJ_PALETTES:
			_put_colours(obj_palettes, palette, _wario.palettes[key][palette])
	if _objects != null and not _objects.particle_palette.is_empty():
		_put_colours(obj_palettes, 2, _objects.particle_palette)
	var figure: PackedByteArray = _bytes("palettes", PALS_DB040)
	for at: int in figure.size():
		obj_palettes[3 * OBJ_PALETTE_BYTES + at] = figure[at]


## A palette's four colours (decoded as Color8 of c << 3 | c >> 2) back as CGB colours.
static func _put_colours(palettes: PackedByteArray, palette: int, colours: Array) -> void:
	for index: int in mini(colours.size(), 4):
		var colour: Color = colours[index]
		var value: int = (colour.r8 >> 3) | ((colour.g8 >> 3) << 5) | ((colour.b8 >> 3) << 10)
		palettes[palette * OBJ_PALETTE_BYTES + index * 2] = value & 0xFF
		palettes[palette * OBJ_PALETTE_BYTES + index * 2 + 1] = value >> 8


## UpdateLevel's virtual OAM: UpdateParticles' entries, DrawObjects_NoPriority's (the objects in front),
## DrawWario's, DrawObjects_WithPriority's, each written while room is left (LoadSprite), then
## ClearUnusedVirtualOAM.
func sprites(sim: LevelSim) -> PackedByteArray:
	var entries: Array = []
	if _objects != null:
		for item: Dictionary in sim.drawn_particles:
			if _objects.can_draw(item):
				entries.append_array(_objects.entries(item))
		for item: Dictionary in sim.drawn_objects:
			if bool(item["over_wario"]) and _objects.can_draw(item):
				entries.append_array(_objects.entries(item))
	if _wario != null and _wario.can_draw(sim.drawn_wario):
		entries.append_array(_wario.entries(sim.drawn_wario))
	if _objects != null:
		for item: Dictionary in sim.drawn_objects:
			if not bool(item["over_wario"]) and _objects.can_draw(item):
				entries.append_array(_objects.entries(item))
	var bytes := PackedByteArray()
	bytes.resize(OAM_SIZE)
	for i: int in mini(entries.size(), OAM_SIZE / 4):
		for k: int in 4:
			bytes[i * 4 + k] = int(entries[i][k]) & 0xFF
	return bytes
