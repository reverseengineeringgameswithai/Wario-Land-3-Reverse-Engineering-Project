class_name ContentPack
extends RefCounted
## Effective content after loading a base pack and applying data-only mods.

var id: String = ""
var title: String = ""
var origin: String = ""
var license: String = ""
var source_dir: String = ""
var movement: MovementParams = MovementParams.new()
var rooms: Dictionary = {}  # room id -> RoomData
var start_room: String = ""
var start_x_px: int = 0
var start_y_px: int = 0
var applied_mods: PackedStringArray = PackedStringArray()
## Labelled approximations (ADR-0002): {subject, behaves_as, original, task?}. Empty for exact or v1 packs.
var approximations: Array[Dictionary] = []


func initial_state() -> PlayerState:
	var state := PlayerState.new()
	state.x = start_x_px * movement.subpixels_per_pixel
	state.y = start_y_px * movement.subpixels_per_pixel
	return state


## SHA-256 over the effective content, so traces can name exactly what they ran against.
func content_hash() -> String:
	var room_dicts: Dictionary = {}
	for room_id: String in rooms:
		room_dicts[room_id] = (rooms[room_id] as RoomData).to_dict()
	var data: Dictionary = {
		"id": id, "movement": movement.to_dict(), "rooms": room_dicts,
		"start": {"room": start_room, "x_px": start_x_px, "y_px": start_y_px},
	}
	# Only packs that declare approximations hash them, so version 1 hashes stay as recorded.
	if not approximations.is_empty():
		data["approximations"] = approximations
	return JSON.stringify(data, "", true).sha256_text()
