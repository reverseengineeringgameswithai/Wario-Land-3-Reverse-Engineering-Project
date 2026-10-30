class_name MovementParams
extends RefCounted
## Integer movement parameters loaded from content (schemas/movement.v1.schema.json).

const OVERRIDABLE: PackedStringArray = ["walk_accel", "walk_decel", "walk_max", "gravity", "jump_velocity", "max_fall"]
const ALL_KEYS: PackedStringArray = [
	"subpixels_per_pixel", "walk_accel", "walk_decel", "walk_max", "gravity",
	"jump_velocity", "max_fall", "body_width_px", "body_height_px",
]

var provisional: bool = true
var source: String = ""
var subpixels_per_pixel: int = 16
var walk_accel: int = 0
var walk_decel: int = 0
var walk_max: int = 0
var gravity: int = 0
var jump_velocity: int = 0
var max_fall: int = 1
var body_width_px: int = 1
var body_height_px: int = 1


func to_dict() -> Dictionary:
	var out: Dictionary = {"provisional": provisional, "source": source}
	for key: String in ALL_KEYS:
		out[key] = get(key)
	return out
