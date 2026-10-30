class_name WarioTables
extends RefCounted
## Wario's movement tables and animation framesets, loaded from the extracted
## wario_movement.json (tools/wl3pc/extract/wario_movement.py, WL3-012). The ROM data
## never lives in this repository: it is decoded from the user's own ROM into local/content.

## WalkVelTable: pixels per step, indexed by wWalkVelIndex.
var walk_steps: PackedInt32Array = PackedInt32Array()
## wJumpVelTable value (JUMP_VEL_KNOCK_BACK = 1 ... JUMP_VEL_BOUNCY_HIGH_JUMP = 5) -> signed steps.
var jump_steps: Dictionary = {}
## wWarioFramesetPtr -> Array of [frame, duration] pairs (the $ff terminator is implied).
var framesets: Dictionary = {}
## HandleUnderwaterThrustingInput's speeds by wSwimVelIndex: "straight", "vertical", "diagonal".
var swim_steps: Dictionary = {}
## UpdateState_FlatFalling's steps by wWalkVelIndex: "down" (Data_2b664) and "across" (Data_2b68c).
var flat_fall_steps: Dictionary = {}
## A bubble's drift by wJumpVelIndex (Data_2b6b4, Func_2b56f).
var bubble_drift_steps: PackedInt32Array = PackedInt32Array()


static func from_document(document: Dictionary) -> WarioTables:
	var tables := WarioTables.new()
	for step: Variant in document["walk_vel_table"]["steps"]:
		tables.walk_steps.append(int(step))
	for table: Dictionary in document["jump_vel_tables"]:
		var steps := PackedInt32Array()
		for step: Variant in table["steps"]:
			steps.append(int(step))
		tables.jump_steps[int(table["id"])] = steps
	for name: String in document.get("swim_vel_tables", {}):
		var swim := PackedInt32Array()
		for step: Variant in document["swim_vel_tables"][name]["steps"]:
			swim.append(int(step))
		tables.swim_steps[name] = swim
	for name: String in document.get("flat_fall_tables", {}):
		var steps := PackedInt32Array()
		for step: Variant in document["flat_fall_tables"][name]["steps"]:
			steps.append(int(step))
		tables.flat_fall_steps[name] = steps
	for step: Variant in document.get("bubble_drift_table", {}).get("steps", []):
		tables.bubble_drift_steps.append(int(step))
	for key: String in document["framesets"]:
		var pairs: Array = []
		for pair: Array in document["framesets"][key]["pairs"]:
			pairs.append([int(pair[0]), int(pair[1])])
		# "BB:AAAA" keys are framesets outside "Wario OAM 1", read as bank << 16 | pointer.
		var parts: PackedStringArray = key.split(":")
		var id: int = parts[0].hex_to_int() if parts.size() == 1 else (parts[0].hex_to_int() << 16) | parts[1].hex_to_int()
		tables.framesets[id] = pairs
	return tables


static func load_file(path: String) -> WarioTables:
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("WarioTables: cannot read %s" % path)
		return null
	return from_document(parsed)
