class_name InputBits
extends RefCounted
## Held-button bit set sampled once per simulation tick.
## Bit order is this project's own and is not a claim about the original's joypad byte.

const RIGHT: int = 1 << 0
const LEFT: int = 1 << 1
const UP: int = 1 << 2
const DOWN: int = 1 << 3
const A: int = 1 << 4
const B: int = 1 << 5
const SELECT: int = 1 << 6
const START: int = 1 << 7

const NAMES: Dictionary = {
	"right": RIGHT, "left": LEFT, "up": UP, "down": DOWN,
	"a": A, "b": B, "select": SELECT, "start": START,
}


static func from_names(names: Array) -> int:
	var bits: int = 0
	for name: Variant in names:
		bits |= int(NAMES.get(str(name), 0))
	return bits


## The Game Boy joypad byte UpdateJoypad builds (src/constants/hardware.inc: B_PAD_A = 0 ...
## B_PAD_DOWN = 7), for ported game code that reads wJoypadDown and wJoypadPressed.
const JOYPAD: Dictionary = {A: 1 << 0, B: 1 << 1, SELECT: 1 << 2, START: 1 << 3,
		RIGHT: 1 << 4, LEFT: 1 << 5, UP: 1 << 6, DOWN: 1 << 7}


static func to_joypad(bits: int) -> int:
	var joypad: int = 0
	for bit: int in JOYPAD:
		if (bits & bit) != 0:
			joypad |= int(JOYPAD[bit])
	return joypad
