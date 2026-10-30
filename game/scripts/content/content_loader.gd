class_name ContentLoader
extends RefCounted
## Loads content packs, data-only mods, and input traces from res:// or the filesystem.
##
## Mirrors the rules of schemas/*.v1.schema.json and tools/wl3pc/content.py.
## Unknown or missing required fields fail with a message; nothing defaults to zero.
## Mods are plain data: no scripts or resources from a mod are ever loaded.

const MAX_JSON_BYTES: int = 1024 * 1024
const MAX_MOD_BYTES: int = 256 * 1024
const MAX_MODS: int = 64
const MAX_ROOM_TILES: int = 4096
const MAX_ROOMS: int = 4096
const PACK_KEYS: PackedStringArray = ["format", "format_version", "id", "title", "origin", "license", "movement", "rooms", "start"]
## Version 2 adds labelled approximations (ADR-0002, schemas/content-pack.v2.schema.json).
const PACK_KEYS_V2: PackedStringArray = [
	"format", "format_version", "id", "title", "origin", "license", "movement", "rooms", "start", "approximations",
]
const APPROXIMATION_KEYS: PackedStringArray = ["subject", "behaves_as", "original", "task"]
const APPROXIMATION_REQUIRED: PackedStringArray = ["subject", "behaves_as", "original"]
const MAX_APPROXIMATIONS: int = 4096
const ROOM_KEYS: PackedStringArray = ["format", "format_version", "id", "tile_size_px", "legend", "rows"]
const MOVEMENT_KEYS: PackedStringArray = [
	"format", "format_version", "provisional", "source", "subpixels_per_pixel", "walk_accel", "walk_decel",
	"walk_max", "gravity", "jump_velocity", "max_fall", "body_width_px", "body_height_px",
]
const MOVEMENT_RANGES: Dictionary = {
	"subpixels_per_pixel": [1, 256], "walk_accel": [0, 4096], "walk_decel": [0, 4096], "walk_max": [0, 4096],
	"gravity": [0, 4096], "jump_velocity": [-4096, 0], "max_fall": [1, 4096],
	"body_width_px": [1, 256], "body_height_px": [1, 256],
}
const MOD_KEYS: PackedStringArray = ["format", "format_version", "id", "title", "target_pack", "license", "movement", "tile_patches"]
const MOD_REQUIRED: PackedStringArray = ["format", "format_version", "id", "title", "target_pack", "license"]
const PATCH_KEYS: PackedStringArray = ["room", "x", "y", "rows"]
const TRACE_KEYS: PackedStringArray = ["format", "format_version", "description", "ticks", "events"]
const ORIGINS: PackedStringArray = ["synthetic", "original-extracted"]

var errors: PackedStringArray = PackedStringArray()
var _id_re: RegEx = RegEx.create_from_string("^[a-z0-9][a-z0-9-]{0,63}$")
var _relpath_re: RegEx = RegEx.create_from_string("^[A-Za-z0-9_./-]+\\.json$")
var _subject_re: RegEx = RegEx.create_from_string("^(start|movement|room/([a-z0-9][a-z0-9-]{0,63})/legend/(.))$")
var _task_re: RegEx = RegEx.create_from_string("^WL3-[0-9]{3}$")


func load_pack(dir: String) -> ContentPack:
	errors.clear()
	var base: String = dir.simplify_path()
	var manifest_path: String = base.path_join("pack.json")
	var data: Variant = _read_json(manifest_path, MAX_JSON_BYTES)
	if not data is Dictionary:
		return _fail_pack(manifest_path, "manifest must be a JSON object")
	var m: Dictionary = data
	var version: Variant = m.get("format_version")
	var keys: PackedStringArray = PACK_KEYS_V2 if _is_integral(version) and int(version) == 2 else PACK_KEYS
	if not _keys(m, keys, keys, manifest_path):
		return null
	if not _const(m, "format", "wl3pc.content-pack", manifest_path):
		return null
	if not _is_integral(version) or not int(version) in [1, 2]:
		return _fail_pack(manifest_path, "format_version must be 1 or 2, got %s" % version)
	var pack := ContentPack.new()
	pack.source_dir = base
	pack.id = _id(m, "id", manifest_path)
	pack.title = _text(m, "title", manifest_path)
	pack.license = _text(m, "license", manifest_path)
	pack.origin = _text(m, "origin", manifest_path)
	if not errors.is_empty():
		return null
	if not pack.origin in ORIGINS:
		return _fail_pack(manifest_path, "origin %s is not one of %s" % [pack.origin, ORIGINS])

	var movement_path: String = _resolve(base, m["movement"], manifest_path)
	if movement_path.is_empty() or not _load_movement(movement_path, pack.movement):
		return null
	if not m["rooms"] is Array or (m["rooms"] as Array).is_empty() or (m["rooms"] as Array).size() > MAX_ROOMS:
		return _fail_pack(manifest_path, "rooms must be a non-empty array of at most %d paths" % MAX_ROOMS)
	for relative: Variant in m["rooms"]:
		var room_path: String = _resolve(base, relative, manifest_path)
		if room_path.is_empty():
			return null
		var room: RoomData = _load_room(room_path)
		if room == null:
			return null
		if pack.rooms.has(room.id):
			return _fail_pack(room_path, "duplicate room id %s" % room.id)
		pack.rooms[room.id] = room

	if not m["start"] is Dictionary:
		return _fail_pack(manifest_path, "start must be an object")
	var start: Dictionary = m["start"]
	if not _keys(start, ["room", "x_px", "y_px"], ["room", "x_px", "y_px"], manifest_path + " start"):
		return null
	pack.start_room = _id(start, "room", manifest_path)
	pack.start_x_px = _int(start, "x_px", 0, 1 << 30, manifest_path)
	pack.start_y_px = _int(start, "y_px", 0, 1 << 30, manifest_path)
	if not errors.is_empty():
		return null
	if not pack.rooms.has(pack.start_room):
		return _fail_pack(manifest_path, "start room %s is not in the pack" % pack.start_room)
	var start_room: RoomData = pack.rooms[pack.start_room]
	if pack.start_x_px + pack.movement.body_width_px > start_room.width() * start_room.tile_size_px \
			or pack.start_y_px + pack.movement.body_height_px > start_room.height() * start_room.tile_size_px:
		return _fail_pack(manifest_path, "start position places the body outside room %s" % pack.start_room)
	if m.has("approximations") and not _load_approximations(m["approximations"], pack, manifest_path):
		return null
	return pack


## Applies every `<mods_dir>/<name>/mod.json` in ascending mod id order. Returns false on the first error.
func apply_mods_from_dir(pack: ContentPack, mods_dir: String) -> bool:
	errors.clear()
	var dir := DirAccess.open(mods_dir)
	if dir == null:
		errors.append("%s: cannot open mods directory" % mods_dir)
		return false
	var found: Array[Dictionary] = []
	for name: String in dir.get_directories():
		var path: String = mods_dir.path_join(name).path_join("mod.json")
		if FileAccess.file_exists(path):
			var data: Variant = _read_json(path, MAX_MOD_BYTES)
			if not errors.is_empty():
				return false
			if not data is Dictionary or not (data as Dictionary).get("id") is String:
				errors.append("%s: mod must be an object with a string id" % path)
				return false
			found.append({"id": (data as Dictionary)["id"], "path": path, "data": data})
	if found.size() > MAX_MODS:
		errors.append("%s: %d mods exceeds the limit of %d" % [mods_dir, found.size(), MAX_MODS])
		return false
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	for i: int in range(1, found.size()):
		if found[i]["id"] == found[i - 1]["id"]:
			errors.append("duplicate mod id %s" % found[i]["id"])
			return false
	for entry: Dictionary in found:
		if not _apply_mod_data(pack, entry["data"], entry["path"]):
			return false
	return true


func apply_mod_file(pack: ContentPack, path: String) -> bool:
	errors.clear()
	var data: Variant = _read_json(path, MAX_MOD_BYTES)
	if not errors.is_empty():
		return false
	return _apply_mod_data(pack, data, path)


func load_trace(path: String) -> InputTrace:
	errors.clear()
	var data: Variant = _read_json(path, MAX_JSON_BYTES)
	if not data is Dictionary:
		errors.append("%s: trace must be a JSON object" % path)
		return null
	var t: Dictionary = data
	if not _keys(t, ["format", "format_version", "ticks", "events"], TRACE_KEYS, path):
		return null
	if not _const(t, "format", "wl3pc.input-trace", path) or not _const(t, "format_version", 1, path):
		return null
	var trace := InputTrace.new()
	trace.ticks = _int(t, "ticks", 1, 1000000, path)
	if not t["events"] is Array:
		errors.append("%s: events must be an array" % path)
	if not errors.is_empty():
		return null
	var last: int = -1
	for event: Variant in t["events"]:
		if not event is Dictionary or not _keys(event, ["tick", "held"], ["tick", "held"], path + " event"):
			errors.append("%s: each event needs exactly tick and held" % path)
			return null
		var tick: int = _int(event, "tick", 0, trace.ticks - 1, path)
		if not errors.is_empty():
			return null
		if tick <= last:
			errors.append("%s: event ticks must be strictly increasing" % path)
			return null
		last = tick
		if not event["held"] is Array:
			errors.append("%s: held must be an array" % path)
			return null
		for button: Variant in event["held"]:
			if not InputBits.NAMES.has(str(button)):
				errors.append("%s: unknown button %s" % [path, button])
				return null
		trace.add_event(tick, InputBits.from_names(event["held"]))
	return trace


# --- Internals -----------------------------------------------------------------

func _apply_mod_data(pack: ContentPack, data: Variant, path: String) -> bool:
	if not data is Dictionary:
		errors.append("%s: mod must be a JSON object" % path)
		return false
	var mod: Dictionary = data
	if not _keys(mod, MOD_REQUIRED, MOD_KEYS, path):
		return false
	if not _const(mod, "format", "wl3pc.mod", path) or not _const(mod, "format_version", 1, path):
		return false
	var mod_id: String = _id(mod, "id", path)
	var target: String = _id(mod, "target_pack", path)
	_text(mod, "title", path)
	_text(mod, "license", path)
	if not errors.is_empty():
		return false
	if target != pack.id:
		errors.append("%s: targets pack %s, loaded pack is %s" % [path, target, pack.id])
		return false

	# Validate everything first so a rejected mod leaves the pack untouched.
	var movement_changes: Dictionary = {}
	if mod.has("movement"):
		if not mod["movement"] is Dictionary or (mod["movement"] as Dictionary).is_empty():
			errors.append("%s: movement must be a non-empty object" % path)
			return false
		var overrides: Dictionary = mod["movement"]
		if not _keys(overrides, [], MovementParams.OVERRIDABLE, path + " movement"):
			return false
		for key: String in overrides:
			var limits: Array = MOVEMENT_RANGES[key]
			movement_changes[key] = _int(overrides, key, limits[0], limits[1], path)
	var row_changes: Array[Dictionary] = []
	if mod.has("tile_patches"):
		if not mod["tile_patches"] is Array:
			errors.append("%s: tile_patches must be an array" % path)
			return false
		for patch: Variant in mod["tile_patches"]:
			if not patch is Dictionary or not _keys(patch, PATCH_KEYS, PATCH_KEYS, path + " patch"):
				return false
			var room_id: String = _id(patch, "room", path)
			var px: int = _int(patch, "x", 0, MAX_ROOM_TILES, path)
			var py: int = _int(patch, "y", 0, MAX_ROOM_TILES, path)
			if not errors.is_empty():
				return false
			if not pack.rooms.has(room_id):
				errors.append("%s: unknown room %s" % [path, room_id])
				return false
			var room: RoomData = pack.rooms[room_id]
			var rows: Variant = patch["rows"]
			if not rows is Array or (rows as Array).is_empty():
				errors.append("%s: patch rows must be a non-empty array" % path)
				return false
			for dy: int in (rows as Array).size():
				var text: Variant = rows[dy]
				if not text is String or (text as String).is_empty():
					errors.append("%s: patch rows must be non-empty strings" % path)
					return false
				if py + dy >= room.height() or px + (text as String).length() > room.width():
					errors.append("%s: patch at (%d, %d) exceeds room %s" % [path, px, py + dy, room_id])
					return false
				for ch: String in (text as String):
					if not room.legend.has(ch):
						errors.append("%s: patch character %s is not in the room legend" % [path, ch])
						return false
				row_changes.append({"room": room_id, "x": px, "y": py + dy, "text": text})
	if not errors.is_empty():
		return false

	for key: String in movement_changes:
		pack.movement.set(key, movement_changes[key])
	for change: Dictionary in row_changes:
		var target_room: RoomData = pack.rooms[change["room"]]
		var row: String = target_room.rows[change["y"]]
		var text_value: String = change["text"]
		var x: int = change["x"]
		target_room.rows[change["y"]] = row.substr(0, x) + text_value + row.substr(x + text_value.length())
	pack.applied_mods.append(mod_id)
	return true


## ADR-0002: every entry names what it stands for; a room subject must match its legend entry.
func _load_approximations(data: Variant, pack: ContentPack, where: String) -> bool:
	if not data is Array or (data as Array).size() > MAX_APPROXIMATIONS:
		errors.append("%s: approximations must be an array of at most %d entries" % [where, MAX_APPROXIMATIONS])
		return false
	var seen: Dictionary = {}
	for entry: Variant in data:
		if not entry is Dictionary or not _keys(entry, APPROXIMATION_REQUIRED, APPROXIMATION_KEYS, where + " approximation"):
			errors.append("%s: each approximation needs subject, behaves_as, and original" % where)
			return false
		var subject: String = _text(entry, "subject", where)
		var behaves_as: String = _text(entry, "behaves_as", where)
		var original: String = _text(entry, "original", where)
		var task: String = _text(entry, "task", where) if (entry as Dictionary).has("task") else ""
		if not errors.is_empty():
			return false
		if behaves_as.length() > 500 or original.length() > 500:
			errors.append("%s: approximation %s text is longer than 500 characters" % [where, subject])
			return false
		if not task.is_empty() and _task_re.search(task) == null:
			errors.append("%s: approximation %s task %s is not a WL3-### id" % [where, subject, task])
			return false
		var parsed: RegExMatch = _subject_re.search(subject)
		if parsed == null:
			errors.append("%s: approximation subject %s is not start, movement, or room/<id>/legend/<char>" % [where, subject])
			return false
		if seen.has(subject):
			errors.append("%s: approximation subject %s appears twice" % [where, subject])
			return false
		seen[subject] = true
		if subject.begins_with("room/"):
			var room: RoomData = pack.rooms.get(parsed.get_string(2))
			var ch: String = parsed.get_string(3)
			if room == null or not room.legend.has(ch):
				errors.append("%s: approximation subject %s names no room legend entry" % [where, subject])
				return false
			if room.legend[ch] != behaves_as:
				errors.append("%s: approximation %s behaves as %s, but the legend says %s" % [where, subject, behaves_as, room.legend[ch]])
				return false
		var record: Dictionary = {"subject": subject, "behaves_as": behaves_as, "original": original}
		if not task.is_empty():
			record["task"] = task
		pack.approximations.append(record)
	return true


func _load_movement(path: String, out: MovementParams) -> bool:
	var data: Variant = _read_json(path, MAX_JSON_BYTES)
	if not data is Dictionary:
		errors.append("%s: movement must be a JSON object" % path)
		return false
	var m: Dictionary = data
	if not _keys(m, MOVEMENT_KEYS, MOVEMENT_KEYS, path):
		return false
	if not _const(m, "format", "wl3pc.movement", path) or not _const(m, "format_version", 1, path):
		return false
	if not m["provisional"] is bool:
		errors.append("%s: provisional must be true or false" % path)
		return false
	out.provisional = m["provisional"]
	out.source = _text(m, "source", path)
	for key: String in MOVEMENT_RANGES:
		var limits: Array = MOVEMENT_RANGES[key]
		out.set(key, _int(m, key, limits[0], limits[1], path))
	return errors.is_empty()


func _load_room(path: String) -> RoomData:
	var data: Variant = _read_json(path, MAX_JSON_BYTES)
	if not data is Dictionary:
		errors.append("%s: room must be a JSON object" % path)
		return null
	var r: Dictionary = data
	if not _keys(r, ROOM_KEYS, ROOM_KEYS, path):
		return null
	if not _const(r, "format", "wl3pc.room", path) or not _const(r, "format_version", 1, path) \
			or not _const(r, "tile_size_px", 16, path):
		return null
	var room := RoomData.new()
	room.id = _id(r, "id", path)
	room.tile_size_px = 16
	if not r["legend"] is Dictionary or (r["legend"] as Dictionary).is_empty():
		errors.append("%s: legend must be a non-empty object" % path)
		return null
	for key: Variant in r["legend"]:
		var material: Variant = r["legend"][key]
		if not key is String or (key as String).length() != 1 or not CollisionGrid.MATERIAL_IDS.has(material):
			errors.append("%s: legend entry %s -> %s is invalid" % [path, key, material])
			return null
		room.legend[key] = material
	if not r["rows"] is Array or (r["rows"] as Array).is_empty() or (r["rows"] as Array).size() > MAX_ROOM_TILES:
		errors.append("%s: rows must be a non-empty array of at most %d strings" % [path, MAX_ROOM_TILES])
		return null
	var width: int = -1
	for row: Variant in r["rows"]:
		if not row is String or (row as String).is_empty() or (row as String).length() > MAX_ROOM_TILES:
			errors.append("%s: each row must be a string of 1-%d characters" % [path, MAX_ROOM_TILES])
			return null
		if width >= 0 and (row as String).length() != width:
			errors.append("%s: rows have different lengths" % path)
			return null
		width = (row as String).length()
		for ch: String in (row as String):
			if not room.legend.has(ch):
				errors.append("%s: character %s is not in the legend" % [path, ch])
				return null
		room.rows.append(row)
	return room if errors.is_empty() else null


## Resolves a pack-relative path, refusing absolute paths, `..`, and symbolic links.
func _resolve(base: String, relative: Variant, where: String) -> String:
	if not relative is String or _relpath_re.search(relative) == null:
		errors.append("%s: path %s must be relative, use [A-Za-z0-9_./-], and end in .json" % [where, relative])
		return ""
	var parts: PackedStringArray = (relative as String).split("/")
	if ".." in parts or (relative as String).begins_with("/"):
		errors.append("%s: path %s may not leave the pack" % [where, relative])
		return ""
	var target: String = base.path_join(relative).simplify_path()
	if not target.begins_with(base + "/"):
		errors.append("%s: path %s resolves outside %s" % [where, relative, base])
		return ""
	if not base.begins_with("res://"):
		var current: String = base
		for part: String in parts:
			current = current.path_join(part)
			if _is_link(current):
				errors.append("%s: %s is a symbolic link" % [where, current])
				return ""
	return target


func _is_link(path: String) -> bool:
	var dir := DirAccess.open(path.get_base_dir())
	return dir != null and dir.is_link(path.get_file())


func _read_json(path: String, limit: int) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("%s: file not found" % path)
		return null
	if not path.begins_with("res://") and _is_link(path):
		errors.append("%s: symbolic links are not accepted" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s: cannot open (%s)" % [path, error_string(FileAccess.get_open_error())])
		return null
	if file.get_length() > limit:
		errors.append("%s: larger than %d bytes" % [path, limit])
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		errors.append("%s:%d: invalid JSON: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


## `required` and `allowed` may be Array or PackedStringArray.
func _keys(d: Dictionary, required: Variant, allowed: Variant, where: String) -> bool:
	for key: Variant in required:
		if not d.has(key):
			errors.append("%s: missing required field %s" % [where, key])
	for key: Variant in d:
		if not key in allowed:
			errors.append("%s: unknown field %s" % [where, key])
	return errors.is_empty()


func _const(d: Dictionary, key: String, expected: Variant, where: String) -> bool:
	var value: Variant = d[key]
	var same: bool
	if typeof(expected) == TYPE_INT:
		same = _is_integral(value) and int(value) == expected
	else:
		same = typeof(value) == typeof(expected) and value == expected
	if not same:
		errors.append("%s: %s must be %s, got %s" % [where, key, expected, value])
	return same


func _is_integral(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value))


func _int(d: Dictionary, key: String, lo: int, hi: int, where: String) -> int:
	var value: Variant = d.get(key)
	if not _is_integral(value):
		errors.append("%s: %s must be an integer, got %s" % [where, key, value])
		return 0
	var number: int = int(value)
	if number < lo or number > hi:
		errors.append("%s: %s=%d is outside %d..%d" % [where, key, number, lo, hi])
	return number


func _text(d: Dictionary, key: String, where: String) -> String:
	var value: Variant = d.get(key)
	if not value is String or (value as String).is_empty():
		errors.append("%s: %s must be a non-empty string" % [where, key])
		return ""
	return value


func _id(d: Dictionary, key: String, where: String) -> String:
	var value: String = _text(d, key, where)
	if not value.is_empty() and _id_re.search(value) == null:
		errors.append("%s: %s %s is not a valid id" % [where, key, value])
	return value


func _fail_pack(where: String, message: String) -> ContentPack:
	errors.append("%s: %s" % [where, message])
	return null
