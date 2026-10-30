class_name ScreenSim
extends RefCounted
## What the screens with their own state tables share (golf, WL3-050; the level's clear screen,
## WL3-043): the LevelSim whose WRAM0 variables they use (`sim`, set while a loop runs), the virtual
## OAM their sprites are built in (LoadSprite), the fades with the V-Blank function they set aside,
## and the notes for what they reach that is not ported.

const OAM_SIZE: int = 0xA0  # 40 sprites of 4 bytes
const OAM_Y_OFS: int = 16
const OAM_X_OFS: int = 8
## A V-Blank function that writes no traced RAM (the fades' among them); the screens number theirs.
const VBLANK_NONE: int = 0

var sim: LevelSim
## The screen's extracted document (golf.json, clear.json), kept for drawing.
var document: Dictionary = {}
var oam_tables: Dictionary = {}  # "BB:AAAA" -> frames of [y, x, tile, attributes] entries
var wVirtualOAM: PackedByteArray = PackedByteArray()
var wVirtualOAMByteSize: int = 0
## The V-Blank function the last loop left (it runs once after the loop), and the one a fade set
## aside.
var vblank_func: int = VBLANK_NONE
var vblank_set_aside: int = VBLANK_NONE
## For drawing: the loops run, and the screens this loop's init loaded.
var loops: int = 0
var screen_loads: Array = []
## The screen's notes for what it reached and is not ported, cleared each loop by the LevelSim.
var unported: PackedStringArray = PackedStringArray()


func _init(level_sim: LevelSim = null) -> void:
	sim = level_sim
	wVirtualOAM.resize(OAM_SIZE)


func _note(what: String) -> void:
	if not unported.has(what):
		unported.append(what)


## A byte of the screen's own RAM by WRAM bank (0 for WRAM0), for the parity checks' loading and
## comparing; each screen keeps its own.
func ram_read(_bank: int, _address: int) -> int:
	return 0


func ram_write(_bank: int, _address: int, _value: int) -> void:
	pass


## Whether the byte at (bank, address) was written since the known bytes were tracked (always, for a
## screen that does not track them).
func ram_known(_bank: int, _address: int) -> bool:
	return true


## LoadSprite (src/home/sprite.asm): frame `frame` of the OAM table `key` ("BB:AAAA") at (y, x),
## each entry's attributes xored by `attributes`, appended to the virtual OAM while there is room.
func load_sprite(key: String, frame: int, y: int, x: int, attributes: int) -> void:
	if not oam_tables.has(key):
		_note("OAM table %s not extracted" % key)
		return
	var frames: Array = oam_tables[key]
	if frame >= frames.size():
		_note("OAM table %s frame %d past its frames" % [key, frame])
		return
	for entry: Array in frames[frame]:
		if wVirtualOAMByteSize >= OAM_SIZE:
			return
		wVirtualOAM[wVirtualOAMByteSize] = (int(entry[0]) + y) & 0xFF
		wVirtualOAM[wVirtualOAMByteSize + 1] = (int(entry[1]) + x) & 0xFF
		wVirtualOAM[wVirtualOAMByteSize + 2] = int(entry[2])
		wVirtualOAM[wVirtualOAMByteSize + 3] = int(entry[3]) ^ attributes
		wVirtualOAMByteSize += 4


## ClearVirtualOAM
func clear_virtual_oam() -> void:
	wVirtualOAM.fill(0)
	wVirtualOAMByteSize = 0


## ClearUnusedVirtualOAM: the sprites after this loop's cleared, and the next loop starts at 0.
func clear_unused_virtual_oam() -> void:
	for offset: int in range(wVirtualOAMByteSize, OAM_SIZE):
		wVirtualOAM[offset] = 0
	wVirtualOAMByteSize = 0


## A loop of a fade at `speed` (FastFadeToWhite and the others, LevelSim.fade_step): its first loop
## sets the screen's V-Blank function aside (VBlank_88d keeps its first bytes), its last puts it back.
func fade(speed: int) -> void:
	if sim.wPalFadeCounter == 0:
		vblank_set_aside = vblank_func
		vblank_func = VBLANK_NONE
	var sub_state: int = sim.wSubState
	sim.fade_step(speed)
	if sim.wSubState != sub_state:
		vblank_func = vblank_set_aside


## SlowFadeInScreen (src/home/fade.asm; the title's and the credits'): a set-up step (its V-Blank
## function set aside), then 32 steps, each taking the palettes a step toward wTempPals1 and 2 (drawing:
## "fade_in_step"); at 33 the V-Blank function is back, wFadeSpeed and the counter cleared, and the
## sub-state advanced. It does not set wFadeSpeed. The original does not load the last step's palettes
## (its V-Blank function is back), but no channel is more than 31 steps away: the 31 loaded reach them.
func slow_fade_in_screen() -> void:
	if sim.wPalFadeCounter == 0:
		vblank_set_aside = vblank_func
		vblank_func = VBLANK_NONE
		sim.wPalFadeCounter = 1
		return
	screen_loads.append(["fade_in_step"])
	sim.wPalFadeCounter += 1
	if sim.wPalFadeCounter < LevelSim.FADE_STEPS:
		return
	vblank_func = vblank_set_aside
	sim.wFadeSpeed = 0
	sim.wPalFadeCounter = 0
	sim.wSubState = (sim.wSubState + 1) & 0xFF
