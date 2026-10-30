class_name ScreenVram
extends RefCounted
## What a screen with its own state table puts in VRAM (golf, WL3-050; the level's clear screen,
## WL3-043), for drawing it with CgbScreen: both banks from $8000 as the screen's loads and V-Blank
## functions write them, from its extracted graphics. `written` marks the bytes the screen has
## written; the rest still holds what was there before. The palettes are the screen's own (the
## fades are drawn over them).

const VRAM_START: int = 0x8000
const VRAM_SIZE: int = 0x2000
const BG_MAP_0: int = 0x9800
const BG_MAP_1: int = 0x9C00
const MAP_WIDTH: int = 32

var vram: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()]
var written: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()]
var bg_palettes: PackedByteArray = PackedByteArray()
var obj_palettes: PackedByteArray = PackedByteArray()
## The screen loaded last ("" before any), and the extracted document's "gfx".
var screen: String = ""
var gfx: Dictionary = {}
var animated_tiles: Dictionary = {}  # rooms/animation.json's animated_tiles_gfx
var _animation_writes: int = -1
## Whether the last loop wrote an animated tiles frame (during the frame drawn, 8 bytes an H-Blank).
var animation_written: bool = false


func _init(document: Dictionary = {}) -> void:
	gfx = document.get("gfx", {})
	for bank: int in 2:
		vram[bank].resize(VRAM_SIZE)
		written[bank].resize(VRAM_SIZE)


func _bytes(kind: String, key: String) -> PackedByteArray:
	return String(gfx.get(kind, {}).get(key, "")).hex_decode()


func write(bank: int, address: int, data: PackedByteArray) -> void:
	for offset: int in data.size():
		var at: int = address - VRAM_START + offset
		if at >= 0 and at < VRAM_SIZE:
			vram[bank][at] = data[offset]
			written[bank][at] = 1


## A copy, for drawing a frame that changes as it is drawn.
func copy() -> ScreenVram:
	var other := ScreenVram.new()
	other.gfx = gfx
	other.screen = screen
	other.bg_palettes = bg_palettes.duplicate()
	other.obj_palettes = obj_palettes.duplicate()
	for bank: int in 2:
		other.vram[bank] = vram[bank].duplicate()
		other.written[bank] = written[bank].duplicate()
	return other


func write_byte(bank: int, address: int, value: int) -> void:
	write(bank, address, PackedByteArray([value & 0xFF]))


func read_byte(bank: int, address: int) -> int:
	return vram[bank][address - VRAM_START]


## FillBGMap0 (src/home/clear_memory.asm): BG map 0's attributes cleared (bank 1) and its tiles
## filled with `value` (bank 0).
func fill_bg_map_0(value: int) -> void:
	var fill := PackedByteArray()
	fill.resize(0x400)
	write(1, BG_MAP_0, fill)
	fill.fill(value & 0xFF)
	write(0, BG_MAP_0, fill)


## The room animation's frame when the loop wrote one (UpdateRoomAnimatedTiles: 8 tiles to VRAM
## 1's $9700, from the room animation's tile sets).
func room_animation(sim: LevelSim) -> void:
	animation_written = false
	if _animation_writes >= 0 and sim.animated_tiles_writes != _animation_writes:
		animation_written = true
		var frames: PackedByteArray = String(animated_tiles.get(str(sim.wAnimatedTilesGfx), "")).hex_decode()
		var start: int = sim.wAnimatedTilesFrame * 0x80
		if start + 0x80 <= frames.size():
			write(1, 0x9700, frames.slice(start, start + 0x80))
	_animation_writes = sim.animated_tiles_writes


## The address of the BG map entry at (x, y) of a map.
static func map_address(map: int, x: int, y: int) -> int:
	return map + y * MAP_WIDTH + x


## SlowFadeInScreen's step on one palette set (its 64 colours are wTempBGPals and wTempOBPals, toward
## wTempPals1 and wTempPals2; the title's and the credits'): each colour's red, green, and blue a step
## toward `target`'s, rebuilt without bit 15.
static func fade_in_step(palettes: PackedByteArray, target: PackedByteArray) -> PackedByteArray:
	var stepped_set: PackedByteArray = palettes.duplicate()
	for colour: int in 32:
		var now: int = palettes[colour * 2] | (palettes[colour * 2 + 1] << 8)
		var goal: int = target[colour * 2] | (target[colour * 2 + 1] << 8)
		var stepped: int = 0
		for shift: int in [0, 5, 10]:
			var component: int = (now >> shift) & 0x1F
			var wanted: int = (goal >> shift) & 0x1F
			component += signi(wanted - component)
			stepped |= component << shift
		stepped_set[colour * 2] = stepped & 0xFF
		stepped_set[colour * 2 + 1] = stepped >> 8
	return stepped_set
