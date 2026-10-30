class_name OverworldVram
extends ScreenVram
## What the map puts in VRAM, the palettes, and the LCD's registers (WL3-052), for drawing it with
## CgbScreen: each loop's writes as OverworldSim records them (its set-ups' decompressions and copies
## from the ROM banks overworld.json keeps, its V-Blank functions' DMAs from WRAM or the ROM, the
## palettes their pal_config_structs and transitions write, rLCDC and the window), and the fades'
## palettes as FadeBGToWhite and DarkenBGToPal step them (src/home/fade.asm): VBlank_88d's function
## stores the hardware's palettes in wTempBGPals and wTempOBPals, each loop steps every colour, and
## VBlank_8bf's function loads them back after each loop but the last.

## rLCDC, rWX, and rWY as the map's set-ups and V-Blank functions leave them.
var lcdc: int = 0
var wx: int = 0
var wy: int = 0
## wTempBGPals and wTempOBPals as a fade steps them.
var fade_pals: PackedByteArray = PackedByteArray()
## Reads the map's ROM banks (its notes are its own).
var _rom := OverworldCommon.new()


func _init(document: Dictionary = {}) -> void:
	super(document)
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)
	fade_pals.resize(0x80)


## One loop of the map: the screen it set up, then its writes in order (OverworldSim's vram_writes,
## palette_writes, register_writes: each its own hardware).
func update(map: OverworldSim, _sim: LevelSim = null) -> void:
	_rom.rom = map.rom
	for load: Array in map.screen_loads:
		screen = String(load[0])
	for entry: Array in map.vram_writes:
		match String(entry[0]):
			"decompress":
				write(int(entry[1]), int(entry[2]), _rom.decompress(int(entry[3]), int(entry[4])))
			"rom":
				write(int(entry[1]), int(entry[2]), rom_bytes(int(entry[3]), int(entry[4]), int(entry[5])))
			"bytes":
				write(int(entry[1]), int(entry[2]), entry[3])
	for entry: Array in map.palette_writes:
		match String(entry[0]):
			"palettes":
				write_palettes(bool(entry[1]), int(entry[2]), entry[3])
			"fade":
				fade(bool(entry[1]), int(entry[2]), int(entry[3]), entry[4])
	for entry: Array in map.register_writes:
		match String(entry[0]):
			"lcdc":
				lcdc = int(entry[1])
			"lcdc_off":
				lcdc &= 0x7F
			"lcdc_flip":
				lcdc ^= int(entry[1])
			"window":
				wx = int(entry[1])
				wy = int(entry[2])


## The palettes as another screen's fade out to white leaves them (the save screen between the map's
## loops, whose LoadBackupVRAM puts VRAM back as the map left it).
func faded_to_white() -> void:
	for offset: int in 0x40:
		bg_palettes[offset] = 0xFF if (offset & 1) == 0 else 0x7F
		obj_palettes[offset] = 0xFF if (offset & 1) == 0 else 0x7F


## `count` bytes of the ROM from (bank, address).
func rom_bytes(bank: int, address: int, count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(count)
	for offset: int in count:
		bytes[offset] = _rom.rb(bank, address + offset)
	return bytes


## Bytes to BGPD or OBPD (`obj`) after `index_register` to BGPI or OBPI: from its index (bits 0-5), each
## byte on to the next with auto-increment (bit 7).
func write_palettes(obj: bool, index_register: int, bytes: PackedByteArray) -> void:
	var palettes: PackedByteArray = obj_palettes if obj else bg_palettes
	var index: int = index_register & 0x3F
	for value: int in bytes:
		palettes[index] = value
		if (index_register & 0x80) != 0:
			index = (index + 1) & 0x3F
	if obj:
		obj_palettes = palettes
	else:
		bg_palettes = palettes


## A loop of FadeBGToWhite (`to_white`) or DarkenBGToPal toward `targets` (wTempPals1 and wTempPals2)
## at `speed` (FADE_SPEED_SLOW, NORMAL, FAST), wPalFadeCounter `counter` before it: its first loop's
## V-Blank stores the palettes (VBlank_88d); then each loop steps the 64 colours and its V-Blank loads
## them (VBlank_8bf) unless it was the last (the screen's own V-Blank function is back).
func fade(to_white: bool, speed: int, counter: int, targets: PackedByteArray) -> void:
	if counter == 0:
		fade_pals = bg_palettes + obj_palettes
		return
	for colour: int in 0x40:
		var rgb: Array = _split(fade_pals[colour * 2], fade_pals[colour * 2 + 1])
		if to_white:
			for channel: int in 3:
				rgb[channel] = mini(rgb[channel] + [1, 2, 4][speed], 0x1F)
		else:
			var target: Array = _split(targets[colour * 2], targets[colour * 2 + 1])
			for channel: int in [2, 1, 0]:
				rgb[channel] = _darken(rgb[channel], target[channel], speed)
		fade_pals[colour * 2] = ((rgb[1] & 0x07) << 5 | rgb[0]) & 0xFF
		fade_pals[colour * 2 + 1] = (((rgb[1] & 0x18) >> 3) | ((rgb[2] << 2) | (rgb[2] >> 6))) & 0xFF
	if counter + 1 < LevelSim.FADE_STEPS_BY_SPEED[speed]:
		bg_palettes = fade_pals.slice(0, 0x40)
		obj_palettes = fade_pals.slice(0x40, 0x80)


## A colour's red, green, and blue (wCurRGB, wTargetRGB).
static func _split(low: int, high: int) -> Array:
	return [low & 0x1F, ((low & 0xE0) >> 5) | ((high & 0x03) << 3), (high & 0x7C) >> 2]


## DarkenBGToPal's step of a channel: down 1, 2, or 4 by speed (stopping at 0; a channel already at 0
## wraps to $ff), then up to the target if below it.
static func _darken(value: int, target: int, speed: int) -> int:
	for step: int in [1, 2, 4][speed]:
		value = (value - 1) & 0xFF
		if value == 0:
			break
	return target if value < target else value


## A copy with the registers, for drawing a frame that changes as it is drawn.
func copy() -> ScreenVram:
	var other := OverworldVram.new()
	other.gfx = gfx
	other.screen = screen
	other.bg_palettes = bg_palettes.duplicate()
	other.obj_palettes = obj_palettes.duplicate()
	other.fade_pals = fade_pals.duplicate()
	other.lcdc = lcdc
	other.wx = wx
	other.wy = wy
	for bank: int in 2:
		other.vram[bank] = vram[bank].duplicate()
		other.written[bank] = written[bank].duplicate()
	return other
