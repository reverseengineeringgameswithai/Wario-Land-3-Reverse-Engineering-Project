extends SceneTree
## The save's load at power-on (SaveLoad.validate_save_data, WL3-055) against the oracle's captures
## (wl3pc.oracle_save: the RAM and the cartridge RAM at ValidateSaveData's first instruction and at
## InitGameState's). For each capture the port starts from the "before" RAM and SRAM and must leave
## every byte the "after" has: WRAM0, WRAMX banks 1 and 2, SRAM banks 0-3; WRAMX banks 3-7 and HRAM,
## which the port does not keep, must be untouched in the original. Not compared: the stack page
## ($cf00-$cfff) and wROMBank ($c5ff), the bank the code switched to last (the port has no banks).
## Usage: godot --headless --path game -s res://tests/parity/save_load_parity.gd -- --captures=DIR
## Prints one line "SAVE_LOAD_PARITY {json}".

const STACK_START: int = 0xCF00
const W_ROM_BANK: int = 0xC5FF
const MAX_EXAMPLES: int = 12


func _initialize() -> void:
	var dir: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="):
			dir = arg.substr(arg.find("=") + 1)
	var names: PackedStringArray = DirAccess.get_files_at(dir)
	var results: Dictionary = {}
	var matched: int = 0
	for name: String in names:
		if not name.ends_with(".json"):
			continue
		var capture: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(name)))
		if not capture is Dictionary:
			results[name] = {"error": "cannot read"}
			continue
		var result: Dictionary = _check(capture)
		results[name.trim_suffix(".json")] = result
		if result["differences"] == 0:
			matched += 1
	print("SAVE_LOAD_PARITY " + JSON.stringify({"captures": results.size(), "matched": matched, "results": results}))
	quit(0)


func _check(capture: Dictionary) -> Dictionary:
	var before: Dictionary = capture["before"]
	var after: Dictionary = capture["after"]
	var sram: Array = []
	for bank: int in 4:
		sram.append(String(before["sram%d" % bank]).hex_decode())
	var ram: Dictionary = {0: String(before["wram0"]).hex_decode(), 1: String(before["wram1"]).hex_decode(),
			2: String(before["wram2"]).hex_decode()}
	SaveLoad.new().validate_save_data(sram, ram)
	var diffs: Array = []
	var count: int = 0
	var compare := func(label: String, native: PackedByteArray, original: PackedByteArray, base: int) -> void:
		for offset: int in original.size():
			var address: int = base + offset
			if label == "wram0" and (address >= STACK_START or address == W_ROM_BANK):
				continue
			if native[offset] != original[offset]:
				count += 1
				if diffs.size() < MAX_EXAMPLES:
					diffs.append("%s:%04x %02x/%02x" % [label, address, native[offset], original[offset]])
	compare.call("wram0", ram[0], String(after["wram0"]).hex_decode(), 0xC000)
	compare.call("wram1", ram[1], String(after["wram1"]).hex_decode(), 0xD000)
	compare.call("wram2", ram[2], String(after["wram2"]).hex_decode(), 0xD000)
	for bank: int in 4:
		compare.call("sram%d" % bank, sram[bank], String(after["sram%d" % bank]).hex_decode(), 0xA000)
	# What the port does not keep must be what the original left alone.
	for key: String in ["wram3", "wram4", "wram5", "wram6", "wram7", "hram"]:
		if before[key] != after[key]:
			count += 1
			diffs.append("%s changed in the original" % key)
	var wceef: int = String(after["wram0"]).hex_decode()[0xCEEF - 0xC000]
	return {"differences": count, "examples": diffs, "wceef": wceef}
