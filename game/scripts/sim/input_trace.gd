class_name InputTrace
extends RefCounted
## Tick-indexed held-button trace (schemas/input-trace.v1.schema.json).

var ticks: int = 0
var _event_ticks: PackedInt64Array = PackedInt64Array()
var _event_bits: PackedInt64Array = PackedInt64Array()


func add_event(tick: int, bits: int) -> void:
	_event_ticks.append(tick)
	_event_bits.append(bits)


## Buttons held at `tick`: the most recent event at or before it, else none.
func held_at(tick: int) -> int:
	var bits: int = 0
	for i: int in _event_ticks.size():
		if _event_ticks[i] > tick:
			break
		bits = _event_bits[i]
	return bits
