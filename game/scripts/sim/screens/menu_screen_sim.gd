class_name MenuScreenSim
extends ScreenSim
## The screens whose objects are WRAMX bank 3's menu objects, animated by UpdateObjAnim (the level's
## clear screen, WL3-043; Action Help, WL3-051). They keep their RAM byte for byte as the original's
## (`wram`: WRAM0 from $c000 as bank 0, WRAMX banks 2 and 3 from $d000) so a parity check compares
## it whole, and share it as the original does (the menu objects, wTimer); the WRAM0 variables they
## share with the level are the LevelSim's.

# menu_obj_struct (src/ram/wram.asm): y, x, frame, attributes, frameset offset, duration, frameset
# pointer (high byte first).
const OBJ_Y: int = 0
const OBJ_X: int = 1
const OBJ_FRAME: int = 2
const OBJ_ATTRIBUTES: int = 3
const OBJ_FRAMESET_OFFSET: int = 4
const OBJ_DURATION: int = 5
const OBJ_FRAMESET_PTR: int = 6
const W_OBJ_ANIM_WAS_RESET: int = 0xD514

## By bank (0 for WRAM0): 4 KiB each, shared by the screens given the same Dictionary. With a "known"
## entry (LevelSim.track_known_ram), the bytes written since are marked there by bank, and SRAM's under
## "sram": a parity run that starts in a level seeds the rest from the trace when it first sees them.
var wram: Dictionary = {}
## SRAM by bank, 8 KiB each from $a000: bank 0, where a save goes.
var sram: Dictionary = {}
var framesets: Dictionary = {}  # "BB:AAAA" -> PackedByteArray of (frame, duration) pairs and $ff
var tables: Dictionary = {}  # name -> PackedByteArray (the extracted document's tables)


func _init(level_sim: LevelSim = null, shared_wram: Variant = null) -> void:
	super(level_sim)
	wram = shared_wram if shared_wram is Dictionary else {}
	for bank: int in [0, 2, 3]:
		if not wram.has(bank):
			var bytes := PackedByteArray()
			bytes.resize(0x1000)
			wram[bank] = bytes
	var save := PackedByteArray()
	save.resize(0x2000)
	sram[0] = save


## The extracted document (clear.json, action_help.json): framesets, OAM tables, and tables.
func load_data(screen_document: Dictionary) -> void:
	document = screen_document
	framesets.clear()
	for key: String in document.get("framesets", {}):
		var bytes := PackedByteArray()
		for pair: Array in document["framesets"][key]:
			bytes.append(int(pair[0]))
			bytes.append(int(pair[1]))
		bytes.append(0xFF)
		framesets[key] = bytes
	oam_tables = document.get("oam_tables", {})
	tables.clear()
	for name: String in document.get("tables", {}):
		tables[name] = String(document["tables"][name]["bytes"]).hex_decode()


func loaded() -> bool:
	return not framesets.is_empty()


# --- RAM access ---

func r0(address: int) -> int:
	return wram[0][address - 0xC000]


func w0(address: int, value: int) -> void:
	wram[0][address - 0xC000] = value & 0xFF
	if wram.has("known"):
		wram["known"][0][address - 0xC000] = 1


func rx(bank: int, address: int) -> int:
	return wram[bank][address - 0xD000]


func wx(bank: int, address: int, value: int) -> void:
	wram[bank][address - 0xD000] = value & 0xFF
	if wram.has("known"):
		wram["known"][bank][address - 0xD000] = 1


## A byte by bank and address as the traces give it: SRAM from $a000, WRAM0 from $c000, WRAMX from
## $d000.
func ram_read(bank: int, address: int) -> int:
	if address < 0xC000:
		return rs(bank, address)
	return r0(address) if address < 0xD000 else rx(bank, address)


func ram_write(bank: int, address: int, value: int) -> void:
	if address < 0xC000:
		ws(bank, address, value)
	elif address < 0xD000:
		w0(address, value)
	else:
		wx(bank, address, value)


func rs(bank: int, address: int) -> int:
	return sram[bank][address - 0xA000] if sram.has(bank) else 0xFF


func ws(bank: int, address: int, value: int) -> void:
	if sram.has(bank):
		sram[bank][address - 0xA000] = value & 0xFF
		if wram.has("known") and bank == 0:
			wram["known"]["sram"][address - 0xA000] = 1


## Whether the byte at (bank, address) was written since the known bytes were tracked (always, when
## they are not).
func ram_known(bank: int, address: int) -> bool:
	if not wram.has("known"):
		return true
	if address < 0xC000:
		return bank == 0 and wram["known"]["sram"][address - 0xA000] != 0
	if address < 0xD000:
		return wram["known"][0][address - 0xC000] != 0
	return wram["known"][bank][address - 0xD000] != 0


func r3(address: int) -> int:
	return rx(3, address)


func w3(address: int, value: int) -> void:
	wx(3, address, value)


func _table(name: String, index: int) -> int:
	var bytes: PackedByteArray = tables.get(name, PackedByteArray())
	if index < 0 or index >= bytes.size():
		_note("table %s entry %d not extracted" % [name, index])
		return 0
	return bytes[index]


# --- the menu objects ---

## UpdateObjAnim (src/home/object_animation.asm): the object's duration counts down, then it takes
## the next (frame, duration) of its frameset (read in `bank`); at the end its offset and duration
## start again, the frame kept, and wObjAnimWasReset is set.
func update_obj_anim(obj: int, bank: int) -> void:
	w3(W_OBJ_ANIM_WAS_RESET, 0)
	var duration: int = r3(obj + OBJ_DURATION)
	w3(obj + OBJ_DURATION, duration - 1)
	if duration != 0:
		return
	var key: String = "%02x:%04x" % [bank, (r3(obj + OBJ_FRAMESET_PTR) << 8) | r3(obj + OBJ_FRAMESET_PTR + 1)]
	if not framesets.has(key):
		_note("frameset %s not extracted" % key)
		return
	var bytes: PackedByteArray = framesets[key]
	var offset: int = r3(obj + OBJ_FRAMESET_OFFSET)
	if offset >= bytes.size() or bytes[offset] == 0xFF:
		w3(obj + OBJ_FRAMESET_OFFSET, 0)
		w3(obj + OBJ_DURATION, 0)
		w3(W_OBJ_ANIM_WAS_RESET, 1)
		return
	w3(obj + OBJ_FRAME, bytes[offset])
	w3(obj + OBJ_FRAMESET_OFFSET, offset + 2)
	w3(obj + OBJ_DURATION, bytes[offset + 1] if offset + 1 < bytes.size() else 0)


## An object at (y, x) with its frame, attributes, offset, and duration cleared and `frameset`.
func set_up_obj(obj: int, y: int, x: int, frameset: int) -> void:
	w3(obj + OBJ_Y, y)
	w3(obj + OBJ_X, x)
	for offset: int in [OBJ_FRAME, OBJ_ATTRIBUTES, OBJ_FRAMESET_OFFSET, OBJ_DURATION]:
		w3(obj + offset, 0)
	_set_frameset(obj, frameset)


func _set_frameset(obj: int, frameset: int) -> void:
	w3(obj + OBJ_FRAMESET_PTR, frameset >> 8)
	w3(obj + OBJ_FRAMESET_PTR + 1, frameset)


static func byte(value: int) -> int:
	return value & 0xFF
