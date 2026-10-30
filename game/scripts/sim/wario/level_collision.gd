class_name LevelCollision
extends RefCounted
## A level's block map and, per room-list entry (wLevelRoomID), the block handler of every
## block ID, from the extracted levels/level-XX.json (tools/wl3pc/extract/level_collision.py).
## The map is mutable: breaking a block writes the replacement as the original does.

const WIDTH: int = 160  # LEVEL_WIDTH
## The rows SRAM holds (two banks of 32 pages). The decoded maps have 48; below them the original
## reads what SRAM holds there (an extracted level has zero; native play from a load takes SRAM's at
## InitLevel), and a spawn on the last row stands Wario on row 48.
const HEIGHT: int = 64
## Each row is a 256-byte SRAM page: the block map ($00-$9f), 16 bytes the decompressors never write
## ($a0-$af), and the object map ($b0-$ff). GetBlockPtr keeps the column's byte, so a probe past the
## map's right edge (or left of it, the column wrapping to $ff) reads on in the page.
const OBJECT_MAP_OFFSET: int = 0xB0
const GAP_WIDTH: int = OBJECT_MAP_OFFSET - WIDTH

var rows: PackedByteArray = PackedByteArray()
## The unwritten bytes ($a0-$af) of every row, GAP_WIDTH a row, as a trace recorded them; empty
## when unknown.
var gap_rows: PackedByteArray = PackedByteArray()
## The object map: one nibble per block (high nibble first), $f marks a spawn; 80 bytes a row.
var object_rows: Array[PackedByteArray] = []
## The map as the level starts (bit 7 marks objects not yet spawned), for ReloadLevelObjects.
var original_rows: PackedByteArray = PackedByteArray()
## wLevelRoomID -> PackedStringArray of 128 handler IDs (block ID = map byte & $7f).
var room_handlers: Dictionary = {}
## wLevelRoomID -> the room header's decoded fields (camera_config, limits, spawn, room, ...).
var room_fields: Dictionary = {}
## Handler ID -> disassembly label, when the extraction had symbols (presentation only).
var handler_labels: Dictionary = {}
## The level start: {"level_room_id", "wario_x", "wario_y"}.
var start: Dictionary = {}


static func from_document(document: Dictionary) -> LevelCollision:
	var level := LevelCollision.new()
	level.set_rows(document["block_rows"])
	level.original_rows = level.rows.duplicate()
	for row: Variant in document.get("object_rows", []):
		level.object_rows.append(String(row).hex_decode())
	for room: Dictionary in document["rooms"]:
		var handlers := PackedStringArray()
		for handler: Variant in room["handlers"]:
			handlers.append(String(handler))
		level.room_handlers[int(room["level_room_id"])] = handlers
		level.room_fields[int(room["level_room_id"])] = room.get("fields", {})
	var labels: Variant = document.get("handlers", {})
	if labels is Dictionary:
		for handler: String in labels:
			level.handler_labels[handler] = "" if labels[handler] == null else String(labels[handler])
	var start_value: Variant = document.get("start", {})
	if start_value is Dictionary:
		level.start = start_value
	return level


## A copy whose map can change without changing this one (the tables are shared).
func copy() -> LevelCollision:
	var other := LevelCollision.new()
	other.rows = rows.duplicate()
	other.gap_rows = gap_rows.duplicate()
	other.original_rows = original_rows.duplicate()
	for row: PackedByteArray in object_rows:
		other.object_rows.append(row.duplicate())
	other.room_handlers = room_handlers
	other.room_fields = room_fields
	other.handler_labels = handler_labels
	other.start = start
	return other


static func load_file(path: String) -> LevelCollision:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("LevelCollision: cannot read %s" % path)
		return null
	return from_document(parsed)


## Replace the whole map with hex rows of WIDTH bytes (as decoded, or as a trace recorded it).
func set_rows(hex_rows: Array) -> void:
	rows = PackedByteArray()
	rows.resize(WIDTH * HEIGHT)
	for y: int in mini(hex_rows.size(), HEIGHT):
		var row: PackedByteArray = String(hex_rows[y]).hex_decode()
		for x: int in mini(row.size(), WIDTH):
			rows[y * WIDTH + x] = row[x]


## Each row's unwritten bytes from hex rows of GAP_WIDTH bytes (as a trace recorded them).
func set_gap_rows(hex_rows: Array) -> void:
	gap_rows = PackedByteArray()
	if hex_rows.is_empty():
		return
	gap_rows.resize(GAP_WIDTH * HEIGHT)
	for y: int in mini(hex_rows.size(), HEIGHT):
		var row: PackedByteArray = String(hex_rows[y]).hex_decode()
		for x: int in mini(row.size(), GAP_WIDTH):
			gap_rows[y * GAP_WIDTH + x] = row[x]


## The byte at the row's page offset `column`: the map byte (bit 7 kept), the unwritten bytes when
## a trace recorded them, or, from $b0, the object map's; -1 where none is known (rows past the
## decoded object map).
func block_at(row: int, column: int) -> int:
	if row < 0 or row >= HEIGHT or column < 0 or column > 0xFF:
		return -1
	if column < WIDTH:
		return rows[row * WIDTH + column]
	if column < OBJECT_MAP_OFFSET:
		return gap_rows[row * GAP_WIDTH + column - WIDTH] if not gap_rows.is_empty() else -1
	if column >= OBJECT_MAP_OFFSET and row < object_rows.size():
		return object_rows[row][column - OBJECT_MAP_OFFSET]
	return -1


func set_block(row: int, column: int, value: int) -> void:
	if row < 0 or row >= HEIGHT or column < 0 or column > 0xFF:
		return
	if column < WIDTH:
		rows[row * WIDTH + column] = value & 0xFF
	elif column < OBJECT_MAP_OFFSET:
		if not gap_rows.is_empty():
			gap_rows[row * GAP_WIDTH + column - WIDTH] = value & 0xFF
	elif row < object_rows.size():
		object_rows[row][column - OBJECT_MAP_OFFSET] = value & 0xFF


## SetWarioPositionToSpawn's search (start_room.asm): from the spawn section's top-left block,
## 16 blocks (8 object bytes, high nibble first) a row, downwards, for the first nibble $f.
## Returns the block [x, y], or [] if the decoded map ends first.
func find_spawn(section_x: int, section_y: int) -> Array:
	var first_byte: int = section_x * 8
	for y: int in range(section_y * 16, object_rows.size()):
		var row: PackedByteArray = object_rows[y]
		for offset: int in 8:
			if first_byte + offset >= row.size():
				break
			var value: int = row[first_byte + offset]
			if (value >> 4) >= 0x0F:
				return [2 * (first_byte + offset), y]
			if (value & 0x0F) >= 0x0F:
				return [2 * (first_byte + offset) + 1, y]
	return []


## The handler ProcessBlock jumps to, or "" if the room is unknown.
func handler_for(level_room_id: int, byte: int) -> String:
	if not room_handlers.has(level_room_id):
		return ""
	return room_handlers[level_room_id][byte & 0x7F]
