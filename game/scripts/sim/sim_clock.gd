class_name SimClock
extends RefCounted
## Fixed simulation cadence, decoupled from rendering.
##
## The tick length is the Game Boy LCD frame period (70224 CPU cycles at
## 4194304 Hz, about 59.7275 Hz; Pan Docs "Rendering"). An emulator oracle capture
## shows one gameplay update per frame during normal play (WL3-015,
## docs/02-research/emulator-oracle.md); heavier scenes are not yet measured.

const CYCLES_PER_FRAME: int = 70224
const CPU_HZ: int = 4194304
const TICK_SECONDS: float = float(CYCLES_PER_FRAME) / float(CPU_HZ)
## Upper bound on catch-up ticks per rendered frame, to avoid a spiral after a stall.
const MAX_TICKS_PER_FRAME: int = 4

var _accumulator: float = 0.0


## Returns how many simulation ticks are due after `delta` seconds of real time.
func advance(delta: float) -> int:
	_accumulator += delta
	var due: int = 0
	while _accumulator >= TICK_SECONDS and due < MAX_TICKS_PER_FRAME:
		_accumulator -= TICK_SECONDS
		due += 1
	if due == MAX_TICKS_PER_FRAME:
		_accumulator = minf(_accumulator, TICK_SECONDS)
	return due
