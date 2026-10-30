class_name WarioParticles
extends WarioRam
## The level's particles, ported from src/engine/level/particles.asm (ElectroDeoxys/warioland3
## @560fce6): dust, debris, stars, smoke, and the like. Four 16-byte slots at wParticles, each an
## ID, an initialised flag, a position (big-endian), and an animation: a duration, an offset into
## its frameset (bank $03, (frame, duration) pairs ending at $ff), and the frame shown. They are
## mostly presentation, but UpdateParticleAnimation leaves wCurParticleAnimEnded for the last
## particle updated, which the treasure scene waits on.

const MAX_NUM_PARTICLES: int = 4
const PARTICLE_STRUCT_LENGTH: int = 16
const PARTICLE_STRUCT_ID: int = 0
const PARTICLE_STRUCT_INITIALISED: int = 1
const PARTICLE_STRUCT_Y_POS: int = 2
const PARTICLE_STRUCT_X_POS: int = 4
const PARTICLE_STRUCT_DURATION: int = 6
const PARTICLE_STRUCT_FRAMESET_OFFSET: int = 7
const PARTICLE_STRUCT_FRAME: int = 8

const PARTICLE_DEBRIS: int = 0x01
const PARTICLE_STARS: int = 0x02
const PARTICLE_SPLASH: int = 0x03
const PARTICLE_DUST: int = 0x04
const PARTICLE_SLIDE_DUST_RIGHT: int = 0x05
const PARTICLE_SLIDE_DUST_LEFT: int = 0x06
const PARTICLE_SMOKE_LARGE: int = 0x07
const PARTICLE_SMOKE_SMALL: int = 0x08
const PARTICLE_BUBBLES: int = 0x09
const PARTICLE_BOUNCY_JUMP: int = 0x0A
const PARTICLE_BUBBLE_BURST: int = 0x0B
const PARTICLE_ICE: int = 0x0C
# PARTICLE_TREASURE_GLOW ($0d) is in WarioRam.
const PARTICLE_OWL: int = 0x0E
const PARTICLE_SNOW: int = 0x0F
const PARTICLE_MAGIC_1: int = 0x10
const PARTICLE_MAGIC_2: int = 0x11
const PARTICLE_MAGIC_STOP: int = 0x12

## The framesets each ParticleAnim_* runs (pointers in bank $03).
const FRAMESET_DEBRIS: int = 0x549A  # Frameset_d49a
const FRAMESET_SPLASH: int = 0x54BA  # Frameset_d4ba
const FRAMESET_DUST: int = 0x54C5  # Frameset_d4c5
const FRAMESET_SMOKE_SMALL: int = 0x54EA  # Frameset_d4ea
const FRAMESET_SMOKE_LARGE: int = 0x54F3  # Frameset_d4f3
const FRAMESET_BUBBLES_LEFT: int = 0x5502  # Frameset_d502
const FRAMESET_BUBBLES_RIGHT: int = 0x550B  # Frameset_d50b
const FRAMESET_STARS: int = 0x5525  # Frameset_d525
const FRAMESET_BOUNCY_JUMP: int = 0x5591  # Frameset_d591
const FRAMESET_BUBBLE_BURST: int = 0x5622  # Frameset_d622
const FRAMESET_ICE_RIGHT: int = 0x56E4  # Frameset_d6e4
const FRAMESET_ICE_LEFT: int = 0x56FD  # Frameset_d6fd
const FRAMESET_TREASURE_GLOW: int = 0x575A  # Frameset_d75a
const FRAMESET_OWL: int = 0x57B4  # Frameset_d7b4
const FRAMESET_SNOW: int = 0x5806  # Frameset_d806
const FRAMESET_MAGIC_1: int = 0x58E7  # Frameset_d8e7
const FRAMESET_MAGIC_2: int = 0x58F4  # Frameset_d8f4
const FRAMESET_MAGIC_STOP: int = 0x5901  # Frameset_d901
## And the OAM table it draws from (bank $03).
const OAM_D20E: int = 0x03_520E
const OAM_D532: int = 0x03_5532
const OAM_D5AE: int = 0x03_55AE
const OAM_D62B: int = 0x03_562B
const OAM_D716: int = 0x03_5716
const OAM_D763: int = 0x03_5763
const OAM_D7BD: int = 0x03_57BD
const OAM_D80D: int = 0x03_580D

## wParticles, then wNumParticles and wCurParticleIndex, as the game lays them out ($cca0-$cce1).
var wParticles: PackedByteArray = PackedByteArray()
var wNumParticles: int = 0
var wCurParticleIndex: int = 0
## Particle framesets by pointer (bank $03): their (frame, duration) pairs.
var particle_framesets: Dictionary = {}
## What LoadParticleSprite drew in the last update, in OAM order, for presentation:
## {"oam_table": "03:AAAA", "frame", "screen_y", "screen_x"} (OAM coordinates).
var drawn_particles: Array = []
const PARTICLE_CAMERA_CONFIG: int = 0x3C  # CAM_XSCROLL2 | CAM_TRANSITIONS | CAM_BORDER_RIGHT | CAM_BORDER_LEFT


func _init() -> void:
	wParticles.resize(MAX_NUM_PARTICLES * PARTICLE_STRUCT_LENGTH)


func load_particle_framesets(document: Dictionary) -> void:
	particle_framesets.clear()
	var framesets: Dictionary = document.get("particles", {}).get("framesets", {})
	for key: String in framesets:
		particle_framesets[key.hex_to_int()] = framesets[key]


## The particle region as the trace records it: the four slots, wNumParticles, wCurParticleIndex.
func particle_bytes() -> PackedByteArray:
	var data: PackedByteArray = wParticles.duplicate()
	data.append(wNumParticles)
	data.append(wCurParticleIndex)
	return data


func load_particle_bytes(data: PackedByteArray) -> void:
	wParticles = data.slice(0, MAX_NUM_PARTICLES * PARTICLE_STRUCT_LENGTH)
	wNumParticles = data[MAX_NUM_PARTICLES * PARTICLE_STRUCT_LENGTH]
	wCurParticleIndex = data[MAX_NUM_PARTICLES * PARTICLE_STRUCT_LENGTH + 1]


## ClearParticles
func clear_particles() -> void:
	wParticles.fill(0)
	wNumParticles = 0
	wCurParticleIndex = 0


## CreateParticle: the next slot in turn (wCurParticleIndex), whatever it held, at hPos.
func create_particle(particle: int) -> void:
	var base: int = wCurParticleIndex * PARTICLE_STRUCT_LENGTH
	wCurParticleIndex = (wCurParticleIndex + 1) & 0b11
	if wParticles[base + PARTICLE_STRUCT_ID] == 0:
		wNumParticles = byte(wNumParticles + 1)
	wParticles[base + PARTICLE_STRUCT_ID] = particle
	wParticles[base + PARTICLE_STRUCT_INITIALISED] = 0
	_set_particle_pos(base)


func _set_particle_pos(base: int) -> void:
	wParticles[base + PARTICLE_STRUCT_Y_POS] = hi(hYPos)
	wParticles[base + PARTICLE_STRUCT_Y_POS + 1] = lo(hYPos)
	wParticles[base + PARTICLE_STRUCT_X_POS] = hi(hXPos)
	wParticles[base + PARTICLE_STRUCT_X_POS + 1] = lo(hXPos)


## CreateParticleInBlock: at the block's bottom middle (Func_ce3e sets hPos there).
func create_particle_in_block(particle: int, row: int, column: int) -> void:
	hYPos = word(row * 16 + 16)
	hXPos = word(column * 16 + 8)
	create_particle(particle)


## get_pos: hPos at Wario.
func get_pos() -> void:
	hYPos = wWarioYPos
	hXPos = wWarioXPos


## The last particle sprite's screen Y (LoadParticleSprite's wCurSpriteYCoord).
var wCurSpriteYCoord: int = 0


## UpdateParticles: each slot in order, nothing at all without particles.
func update_particles() -> void:
	drawn_particles.clear()
	if wNumParticles == 0:
		return
	for slot: int in MAX_NUM_PARTICLES:
		var base: int = slot * PARTICLE_STRUCT_LENGTH
		if wParticles[base + PARTICLE_STRUCT_ID] != 0:
			_particle_func(base)


## UpdateParticles.DoParticleFunc's table.
func _particle_func(base: int) -> void:
	match wParticles[base + PARTICLE_STRUCT_ID]:
		PARTICLE_DEBRIS:
			_particle_once(base, FRAMESET_DEBRIS, OAM_D20E)
		PARTICLE_STARS:
			_particle_once(base, FRAMESET_STARS, OAM_D20E)
		PARTICLE_SPLASH:
			_particle_once(base, FRAMESET_SPLASH, OAM_D20E)
		PARTICLE_DUST:
			_particle_once(base, FRAMESET_DUST, OAM_D20E)
		PARTICLE_SMOKE_LARGE:
			_particle_once(base, FRAMESET_SMOKE_LARGE, OAM_D20E)
		PARTICLE_SMOKE_SMALL:
			_particle_once(base, FRAMESET_SMOKE_SMALL, OAM_D20E)
		PARTICLE_BUBBLES:
			_particle_once(base, FRAMESET_BUBBLES_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_BUBBLES_LEFT,
					OAM_D20E)
		PARTICLE_BUBBLE_BURST:
			_particle_once(base, FRAMESET_BUBBLE_BURST, OAM_D5AE)
		PARTICLE_ICE:
			_particle_once(base, FRAMESET_ICE_RIGHT if wDirection != DIRECTION_LEFT else FRAMESET_ICE_LEFT, OAM_D62B)
		PARTICLE_SLIDE_DUST_RIGHT, PARTICLE_SLIDE_DUST_LEFT:
			_particle_slide_dust(base)
		PARTICLE_BOUNCY_JUMP:
			_particle_bouncy_jump(base)
		PARTICLE_TREASURE_GLOW:
			_particle_init(base)
			_particle_anim(base, FRAMESET_TREASURE_GLOW, OAM_D716)
		PARTICLE_OWL:
			_particle_owl(base)
		PARTICLE_SNOW:
			_particle_once(base, FRAMESET_SNOW, OAM_D7BD)
		PARTICLE_MAGIC_1, PARTICLE_MAGIC_2:
			if wWarioState == WST_MAGIC_STOPPING:
				_remove_particle(base)
				return
			_particle_at_wario(base)
			_particle_anim(base, FRAMESET_MAGIC_1 if wParticles[base + PARTICLE_STRUCT_ID] == PARTICLE_MAGIC_1
					else FRAMESET_MAGIC_2, OAM_D80D)
		PARTICLE_MAGIC_STOP:
			_particle_at_wario(base)
			_particle_anim(base, FRAMESET_MAGIC_STOP, OAM_D80D)
			if wCurParticleAnimEnded != 0:
				_remove_particle(base)


## A particle's first update: initialised, its animation from the start.
func _particle_init(base: int) -> bool:
	if wParticles[base + PARTICLE_STRUCT_INITIALISED] != 0:
		return false
	wParticles[base + PARTICLE_STRUCT_INITIALISED] = 1
	wParticles[base + PARTICLE_STRUCT_DURATION] = 0
	wParticles[base + PARTICLE_STRUCT_FRAMESET_OFFSET] = 0
	return true


## ParticleFunc_Owl: rising 2 px a frame after its first, gone once its sprite is $c0 or more down
## the screen (wCurSpriteYCoord, below the visible lines).
func _particle_owl(base: int) -> void:
	if not _particle_init(base):
		var y: int = word(((wParticles[base + PARTICLE_STRUCT_Y_POS] << 8) | wParticles[base + PARTICLE_STRUCT_Y_POS + 1]) - 2)
		wParticles[base + PARTICLE_STRUCT_Y_POS] = hi(y)
		wParticles[base + PARTICLE_STRUCT_Y_POS + 1] = lo(y)
	_particle_anim(base, FRAMESET_OWL, OAM_D763)
	if wCurSpriteYCoord >= 0xC0:
		_remove_particle(base)


## ParticleFunc_Magic1, _Magic2, _MagicStop after their first update: at Wario (through hPos).
func _particle_at_wario(base: int) -> void:
	if _particle_init(base):
		return
	get_pos()
	_set_particle_pos(base)


## ParticleFunc_Debris and the others like it: the animation once, then the slot is free.
func _particle_once(base: int, frameset: int, oam: int) -> void:
	_particle_init(base)
	_particle_anim(base, frameset, oam)
	if wCurParticleAnimEnded != 0:
		_remove_particle(base)


func _remove_particle(base: int) -> void:
	wParticles[base + PARTICLE_STRUCT_ID] = 0
	wNumParticles = byte(wNumParticles - 1)


## ParticleFunc_SlideDustRight/Left: following Wario 12 px up and behind him (by hPos), for as
## long as he slides.
func _particle_slide_dust(base: int) -> void:
	if not _particle_init(base):
		var dx: int = -0x0C if wParticles[base + PARTICLE_STRUCT_ID] == PARTICLE_SLIDE_DUST_RIGHT else 0x0C
		hXPos = word(wWarioXPos + dx)
		hYPos = word(wWarioYPos - 0x0C)
		_set_particle_pos(base)
	_particle_anim(base, FRAMESET_DUST, OAM_D20E)
	if wWarioState != WST_SLIDING:
		_remove_particle(base)


## ParticleFunc_BouncyJump: at Wario (by hPos) while Bouncy Wario is airborne, once.
func _particle_bouncy_jump(base: int) -> void:
	if wWarioState != WST_BOUNCY_AIRBORNE:
		_remove_particle(base)
		return
	if not _particle_init(base):
		get_pos()
		_set_particle_pos(base)
	_particle_anim(base, FRAMESET_BOUNCY_JUMP, OAM_D532)
	if wCurParticleAnimEnded != 0:
		_remove_particle(base)


## ParticleAnim_* (UpdateParticleAnimation, then LoadParticleSprite): when the duration runs out,
## the next pair; at the $ff end the animation restarts and wCurParticleAnimEnded is set.
func _particle_anim(base: int, frameset: int, oam: int) -> void:
	wCurParticleAnimEnded = 0
	var duration: int = wParticles[base + PARTICLE_STRUCT_DURATION] - 1
	wParticles[base + PARTICLE_STRUCT_DURATION] = byte(duration)
	if duration < 0:
		var offset: int = wParticles[base + PARTICLE_STRUCT_FRAMESET_OFFSET]
		var frame: int = _particle_frameset_byte(frameset, offset)
		if frame == 0xFF:
			wParticles[base + PARTICLE_STRUCT_FRAMESET_OFFSET] = 0
			wParticles[base + PARTICLE_STRUCT_DURATION] = 0
			wCurParticleAnimEnded = 1
		else:
			wParticles[base + PARTICLE_STRUCT_FRAME] = frame
			wParticles[base + PARTICLE_STRUCT_FRAMESET_OFFSET] = byte(offset + 2)
			wParticles[base + PARTICLE_STRUCT_DURATION] = _particle_frameset_byte(frameset, offset + 1)
	# LoadParticleSprite: the low position bytes less the scroll (the camera's own for one
	# configuration), plus the OAM offsets.
	var camera: bool = wCameraConfigFlags == PARTICLE_CAMERA_CONFIG
	var scy: int = lo(wCameraSCY) if camera else wSCY
	var scx: int = lo(wCameraSCX) if camera else wSCX
	wCurSpriteYCoord = byte(wParticles[base + PARTICLE_STRUCT_Y_POS + 1] + 16 - scy)
	drawn_particles.append({"oam_table": "%02x:%04x" % [oam >> 16, oam & 0xFFFF],
			"frame": wParticles[base + PARTICLE_STRUCT_FRAME],
			"screen_y": byte(wParticles[base + PARTICLE_STRUCT_Y_POS + 1] + 16 - scy),
			"screen_x": byte(wParticles[base + PARTICLE_STRUCT_X_POS + 1] + 8 - scx)})


## The byte at `offset` in the frameset's pairs; past them, the $ff end.
func _particle_frameset_byte(frameset: int, offset: int) -> int:
	if not particle_framesets.has(frameset):
		note_unported("particle frameset 03:%04x" % frameset)
		return 0xFF
	var pairs: Array = particle_framesets[frameset]
	var index: int = offset >> 1
	if index >= pairs.size():
		return 0xFF
	return int(pairs[index][offset & 1])
