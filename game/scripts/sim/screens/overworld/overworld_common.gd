class_name OverworldCommon
extends MenuScreenSim
## The map's shared ground (src/engine/overworld/, WL3-052): its RAM, WRAMX bank 2 whole (the
## treasures, the map's own variables, its BG maps in wTilemap and wAttrmap), and the ROM banks it
## reads its tables, paths, palettes, maps, and graphics from, kept whole (overworld.json) so the
## port follows the original's pointers; compressed data goes through the same RLE (Decompress).

const BANK_SIZE: int = 0x4000

const W_TEMP_BANK: int = 0xC0AC
const W_TRANSITION_PARAM: int = 0xCEE3

## The ROM banks overworld.json keeps: bank -> PackedByteArray of its $4000 bytes.
var rom: Dictionary = {}
## wTransitionParam (WRAM0): what the map was entered from, in the screens' shared WRAM0 (the save
## screen reads it there too).
var wTransitionParam: int:
	get:
		return r0(W_TRANSITION_PARAM)
	set(value):
		w0(W_TRANSITION_PARAM, value)
## wTempBank (WRAM0, shared with the other screens): the bank of the last banked call through it.
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)


## overworld.json (wl3pc.extract.overworld): the banks.
func load_data(screen_document: Dictionary) -> void:
	document = screen_document
	rom.clear()
	for key: String in document.get("banks", {}):
		rom[key.hex_to_int()] = String(document["banks"][key]).hex_decode()


func loaded() -> bool:
	return not rom.is_empty()


# --- the ROM ---

## A ROM byte at (bank, address): the home bank from $0000, the others from $4000.
func rb(bank: int, address: int) -> int:
	var bytes: PackedByteArray = rom.get(bank, PackedByteArray())
	var at: int = address if bank == 0 else address - 0x4000
	if at < 0 or at >= bytes.size():
		_note("ROM bank %02x not extracted (%04x)" % [bank, address])
		return 0
	return bytes[at]


## A little-endian ROM word.
func rw(bank: int, address: int) -> int:
	return rb(bank, address) | (rb(bank, address + 1) << 8)


## Decompress (src/home/decompress.asm): control bytes from (bank, address) until $00; with bit 7
## clear the next byte `control` times, with it set `control & $7f` literal bytes ($80: 256).
func decompress(bank: int, address: int) -> PackedByteArray:
	var output := PackedByteArray()
	var at: int = address
	while true:
		var control: int = rb(bank, at)
		at += 1
		if control == 0:
			return output
		if (control & 0x80) != 0:
			var count: int = control & 0x7F
			if count == 0:
				count = 0x100
			for index: int in count:
				output.append(rb(bank, at))
				at += 1
		else:
			var value: int = rb(bank, at)
			at += 1
			for index: int in control:
				output.append(value)
		if output.size() > 0x4000:
			_note("Decompress from %02x:%04x runs past $4000 bytes" % [bank, address])
			return output
	return output


# --- WRAMX bank 2 ---

func r2(address: int) -> int:
	return rx(2, address)


func w2(address: int, value: int) -> void:
	wx(2, address, value)
