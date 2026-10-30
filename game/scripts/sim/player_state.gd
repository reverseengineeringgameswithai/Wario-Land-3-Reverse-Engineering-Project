class_name PlayerState
extends RefCounted
## Complete, copyable player simulation state. Positions are the top-left of the
## body box in subpixels; velocities are subpixels per tick.

var tick: int = 0
var x: int = 0
var y: int = 0
var vx: int = 0
var vy: int = 0
var on_ground: bool = false
var facing: int = 1
var prev_held: int = 0


func snapshot() -> Dictionary:
	return {
		"tick": tick, "x": x, "y": y, "vx": vx, "vy": vy,
		"on_ground": on_ground, "facing": facing, "prev_held": prev_held,
	}


static func from_snapshot(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.tick = int(data["tick"])
	state.x = int(data["x"])
	state.y = int(data["y"])
	state.vx = int(data["vx"])
	state.vy = int(data["vy"])
	state.on_ground = bool(data["on_ground"])
	state.facing = int(data["facing"])
	state.prev_held = int(data["prev_held"])
	return state
