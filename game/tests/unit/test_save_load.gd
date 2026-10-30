extends TestCase
## The save's load at power-on (SaveLoad: ValidateSaveData and what it calls) on invented saves (no ROM
## bytes), every byte of WRAM0, WRAMX banks 1 and 2, and SRAM compared after it where it matters: no
## save (SRAM all $ff, and all zero), the map's save and its backup (a tie loading the main one), a
## corrupted main save loading the backup, the checksum vote (.GetMatchingChecksum) and its lone
## matching value, a level save with a higher counter winning, the level's third copy winning and
## restoring the map's backup (.Func_1f1420), the level map's sum gating the first two copies, tied
## counters across kinds, the progress markers in wcef1, CalculateChecksumLong's two bytes, and a
## round trip through the save screen's Save (PauseMenuSim).

const CHECKVAL1: Array = [0x77, 0x61, 0x72, 0x33]
const CHECKVAL2: Array = [0x57, 0x41, 0x52, 0x33]
const MAP_SAVE_CHECKSUMS: Array = [SaveLoad.S_GAME_DATA_CHECKSUM, SaveLoad.S_GAME_DATA_CHECKSUM_ECHO1,
	SaveLoad.S_GAME_DATA_CHECKSUM_ECHO2]
const BACKUP_CHECKSUMS: Array = [SaveLoad.S_BACKUP_GAME_DATA_CHECKSUM, SaveLoad.S_BACKUP_GAME_DATA_CHECKSUM_ECHO1,
	SaveLoad.S_BACKUP_GAME_DATA_CHECKSUM_ECHO2]
## The level save's copies: their check values and their checksums with echoes.
const LEVEL_COPIES: Dictionary = {
	SaveLoad.S0A000: [SaveLoad.S_WRAM_CHECKSUM, SaveLoad.S_WRAM_CHECKSUM_ECHO1, SaveLoad.S_WRAM_CHECKSUM_ECHO2],
	SaveLoad.S0A800: [SaveLoad.S_BACKUP1_WRAM_CHECKSUM, SaveLoad.S_BACKUP1_WRAM_CHECKSUM_ECHO1,
		SaveLoad.S_BACKUP1_WRAM_CHECKSUM_ECHO2],
	SaveLoad.S0A400: [SaveLoad.S_BACKUP2_WRAM_CHECKSUM, SaveLoad.S_BACKUP2_WRAM_CHECKSUM_ECHO1,
		SaveLoad.S_BACKUP2_WRAM_CHECKSUM_ECHO2],
	SaveLoad.S0AC00: [SaveLoad.S_BACKUP3_WRAM_CHECKSUM, SaveLoad.S_BACKUP3_WRAM_CHECKSUM_ECHO1,
		SaveLoad.S_BACKUP3_WRAM_CHECKSUM_ECHO2],
}
const ALL_CHECK_VALS: Array = [SaveLoad.S_CHECK_VALS, SaveLoad.S_BACKUP_CHECK_VALS, SaveLoad.S0A000,
	SaveLoad.S0A800, SaveLoad.S0A400, SaveLoad.S0AC00]


# --- invented saves ---

func _banks(fill: int = 0) -> Array:
	var banks: Array = []
	for _bank: int in 4:
		var bytes := PackedByteArray()
		bytes.resize(0x2000)
		bytes.fill(fill)
		banks.append(bytes)
	return banks


func _put(banks: Array, bank: int, address: int, values: PackedByteArray) -> void:
	for offset: int in values.size():
		banks[bank][address - 0xA000 + offset] = values[offset]


func _put16(banks: Array, address: int, value: int) -> void:
	_put(banks, 0, address, PackedByteArray([(value >> 8) & 0xFF, value & 0xFF]))


func _sram_bytes(banks: Array, bank: int, address: int, count: int) -> Array:
	return Array(banks[bank].slice(address - 0xA000, address - 0xA000 + count))


func _sum(bytes: PackedByteArray) -> int:
	var total: int = 0
	for value: int in bytes:
		total += value
	return total & 0xFFFF


func _counter(counter: int) -> PackedByteArray:
	return PackedByteArray([(counter >> 24) & 0xFF, (counter >> 16) & 0xFF, (counter >> 8) & 0xFF, counter & 0xFF])


## A map save ("war3") at `check_vals`: the counter, the rest of the progress WRAM ($5b) `fill`, the
## treasures ($11) `treasure`; its sum written as the checksum and both echoes at `checksums`. Returns
## the data after the check values.
func _map_save(banks: Array, check_vals: int, checksums: Array, counter: int, fill: int,
		treasure: int) -> PackedByteArray:
	var data: PackedByteArray = _counter(counter)
	for _i: int in 0x5B - 4:
		data.append(fill)
	for _i: int in 0x11:
		data.append(treasure)
	var bytes := PackedByteArray(CHECKVAL1)
	bytes.append_array(data)
	_put(banks, 0, check_vals, bytes)
	for at: int in checksums:
		_put16(banks, at, _sum(data))
	return data


## A level save's copy ("WAR3") at `slot`: the counter, the progress and level WRAM's other bytes
## `fill`, the treasures `treasure`, the objects ($14a) i * 3 + 1; its sum as SaveLevel writes it (all
## but the first two objects left out, CalculateChecksumLong) at the slot's checksums. Returns the data.
func _level_save(banks: Array, slot: int, counter: int, fill: int, treasure: int) -> PackedByteArray:
	var data: PackedByteArray = _counter(counter)
	for _i: int in 0xCA - 4:
		data.append(fill)
	for _i: int in 0x11:
		data.append(treasure)
	for index: int in 0x14A:
		data.append((index * 3 + 1) & 0xFF)
	var bytes := PackedByteArray(CHECKVAL2)
	bytes.append_array(data)
	_put(banks, 0, slot, bytes)
	for at: int in LEVEL_COPIES[slot]:
		_put16(banks, at, _sum(data.slice(0, 0xCA + 0x11 + 2)))
	return data


## The level map's sums: bank 1 with bank 2's first half at s0a79d, bank 3 with bank 2's second half
## at s0a79f, each with its two echoes.
func _map_sums(banks: Array) -> Array:
	var map: PackedByteArray = banks[1].duplicate()
	map.append_array(banks[2].slice(0, 0x1000))
	var backup: PackedByteArray = banks[3].duplicate()
	backup.append_array(banks[2].slice(0x1000, 0x2000))
	for at: int in [SaveLoad.S0A79D, SaveLoad.S0A7ED, SaveLoad.S0AFAD]:
		_put16(banks, at, _sum(map))
	for at: int in [SaveLoad.S0A79F, SaveLoad.S0A7EF, SaveLoad.S0AFAF]:
		_put16(banks, at, _sum(backup))
	return [_sum(map), _sum(backup)]


func _load(banks: Array) -> Dictionary:
	var ram: Dictionary = SaveLoad.cleared_wram()
	SaveLoad.new().validate_save_data(banks, ram)
	return ram


## The bytes that differ (at most 8), "$addr: got, expected", for a whole-range comparison.
func _diff(actual: PackedByteArray, expected: PackedByteArray, base: int) -> Array:
	var found: Array = []
	for offset: int in maxi(actual.size(), expected.size()):
		var got: int = actual[offset] if offset < actual.size() else -1
		var want: int = expected[offset] if offset < expected.size() else -1
		if got != want:
			found.append("$%04x: %d, %d" % [base + offset, got, want])
			if found.size() == 8:
				break
	return found


func _zeroes(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	return bytes


func _w0(bytes: PackedByteArray, address: int, values: Array) -> void:
	for offset: int in values.size():
		bytes[address - 0xC000 + offset] = values[offset]


func _wram0(ram: Dictionary, address: int, count: int = 1) -> Array:
	return Array(ram[0].slice(address - 0xC000, address - 0xC000 + count))


# --- no save ---

func test_without_a_save_the_scores_take_their_defaults_and_every_check_value_is_cleared() -> void:
	var banks: Array = _banks(0xFF)
	var before: Array = _banks(0xFF)
	var ram: Dictionary = _load(banks)
	var wram0: PackedByteArray = _zeroes(0x1000)
	for offset: int in 50:
		wram0[SaveLoad.W_LEVEL_TIME_ATTACK_SCORES - 0xC000 + offset] = 0xAA
	_w0(wram0, SaveLoad.W_GOLF_BEST_SCORES, [0xAA, 0xAA, 0xAA, 0xAA])
	# The last vote: s0a79f's three $ffff agree; the map's backup sums to $3000 * $ff ($d000), so no slot.
	_w0(wram0, SaveLoad.W_CHECKSUM, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
	_w0(wram0, SaveLoad.WCEF1, [0xFF])
	assert_eq(_diff(ram[0], wram0, 0xC000), [], "WRAM0: wceee, wceef 0, wChecksumMismatches 0")
	assert_eq([_diff(ram[1], _zeroes(0x1000), 0xD000), _diff(ram[2], _zeroes(0x1000), 0xD000)], [[], []])
	for at: int in ALL_CHECK_VALS:
		_put(before, 0, at, PackedByteArray([0, 0, 0, 0]))
	_put(before, 0, SaveLoad.S0A790, PackedByteArray([0]))
	_put(before, 0, SaveLoad.S0A7E0, PackedByteArray([0]))
	_put(before, 0, SaveLoad.S0AFA0, PackedByteArray([0]))
	for bank: int in 4:
		assert_eq(_diff(banks[bank], before[bank], 0xA000), [], "SRAM bank %d" % bank)


func test_a_zeroed_sram_has_no_slot_but_its_empty_level_maps_sum_to_their_zero_checksums() -> void:
	var ram: Dictionary = _load(_banks(0))
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 4), [0xC0, 0, 0, 0xFF], "wceee, wceef, wChecksumMismatches, wcef1")
	assert_eq([_wram0(ram, SaveLoad.W_LEVEL_TIME_ATTACK_SCORES + 49), _wram0(ram, SaveLoad.W_GOLF_BEST_SCORES + 3)],
			[[0xAA], [0xAA]])


# --- the map's save ---

func test_a_map_save_and_its_backup_tie_and_the_main_one_loads() -> void:
	var banks: Array = _banks(0)
	var main: PackedByteArray = _map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 5, 0x11, 0x0F)
	_map_save(banks, SaveLoad.S_BACKUP_CHECK_VALS, BACKUP_CHECKSUMS, 5, 0x22, 0x01)
	var before: Array = []
	for bank: int in 4:
		before.append(banks[bank].duplicate())
	var ram: Dictionary = _load(banks)
	var wram0: PackedByteArray = _zeroes(0x1000)
	_w0(wram0, SaveLoad.W_SAVE_COUNTER, Array(main.slice(0, 0x5B)))
	_w0(wram0, SaveLoad.WCEEE, [0xC3, 0x03])  # both map saves and the empty level maps; the tie kept
	assert_eq(_diff(ram[0], wram0, 0xC000), [], "WRAM0: the main save, wcef1 0 (markers 0), the last vote 0")
	var wram2: PackedByteArray = _zeroes(0x1000)
	for offset: int in 0x11:
		wram2[offset] = 0x0F
	assert_eq([_diff(ram[1], _zeroes(0x1000), 0xD000), _diff(ram[2], wram2, 0xD000)], [[], []])
	# Both counters shifted out in 32 rounds; 5's last bit carried in the last.
	before[0][SaveLoad.S0AFF8 - 0xA000] = 0x03
	for bank: int in 4:
		assert_eq(_diff(banks[bank], before[bank], 0xA000), [], "SRAM bank %d" % bank)


func test_a_corrupted_main_save_is_cleared_and_its_backup_loads() -> void:
	var banks: Array = _banks(0)
	_map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 9, 0x11, 0x0F)
	banks[0][SaveLoad.S_GAME_DATA - 0xA000 + 0x30] ^= 0x01  # a byte of the data changed after its checksum
	var backup: PackedByteArray = _map_save(banks, SaveLoad.S_BACKUP_CHECK_VALS, BACKUP_CHECKSUMS, 5, 0x22, 0x01)
	_put(banks, 0, SaveLoad.S0AFE0, PackedByteArray([0x5A, 0x5A]))
	var ram: Dictionary = _load(banks)
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 2), [0xC2, 0x02])
	assert_eq(_wram0(ram, SaveLoad.W_SAVE_COUNTER, 0x5B), Array(backup.slice(0, 0x5B)))
	assert_eq([ram[2][0], ram[2][0x10], ram[2][0x11]], [0x01, 0x01, 0])
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S_CHECK_VALS, 5), [0, 0, 0, 0, 0], "cleared; the data kept")
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S0AFE0, 2), [0x5A, 0x5A], "one slot: no counters compared")


func test_the_checksum_vote_keeps_the_value_two_agree_on_and_the_odd_one_out() -> void:
	var load := SaveLoad.new()
	load.wram = SaveLoad.cleared_wram()
	# [b, c, d, e, h, l] (checksum, echo 1, echo 2) -> [mismatches, wChecksum, wcee9, wceeb]
	var cases: Array = [
		[[1, 2, 1, 2, 1, 2], [0, 0x0102, 0x0102, 0x0102]],
		[[1, 2, 1, 2, 1, 3], [SaveLoad.MISMATCH_ECHO2, 0x0102, 0x0103, 0x0102]],
		[[1, 2, 1, 3, 1, 2], [SaveLoad.MISMATCH_ECHO1, 0x0102, 0x0103, 0x0102]],
		[[1, 3, 1, 2, 1, 2], [SaveLoad.MISMATCH_ORIG, 0x0102, 0x0103, 0x0102]],
		[[1, 1, 1, 2, 1, 3], [7, 0x0101, 0x0102, 0x0103]],
		[[5, 2, 1, 2, 1, 2], [SaveLoad.MISMATCH_ORIG, 0x0102, 0x0502, 0x0102]],
		[[1, 2, 1, 2, 5, 2], [SaveLoad.MISMATCH_ECHO2, 0x0102, 0x0502, 0x0102]],
		[[1, 2, 5, 2, 1, 2], [SaveLoad.MISMATCH_ECHO1, 0x0102, 0x0502, 0x0102]],
		[[1, 2, 3, 4, 5, 6], [7, 0x0102, 0x0304, 0x0506]],
	]
	for entry: Array in cases:
		var v: Array = entry[0]
		load.get_matching_checksum(v[0], v[1], v[2], v[3], v[4], v[5])
		var got: Array = [load.r0(SaveLoad.W_CHECKSUM_MISMATCHES)]
		for at: int in [SaveLoad.W_CHECKSUM, SaveLoad.WCEE9, SaveLoad.WCEEB]:
			got.append((load.r0(at) << 8) | load.r0(at + 1))
		assert_eq(got, entry[1], str(v))


func test_a_lone_stored_value_that_matches_the_data_still_validates_the_save() -> void:
	# [checksum, echo 1, echo 2] as stored: the data's sum, or other values. The last case has no value
	# matching the sum: invalid, its check values cleared.
	for case: Array in [["sum", "sum", "bad"], ["bad", "bad", "sum"], ["bad", "other", "sum"], ["bad", "bad", "other"]]:
		var banks: Array = _banks(0)
		var data: PackedByteArray = _map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 1, 0x11, 0x0F)
		var values: Dictionary = {"sum": _sum(data), "bad": 0x1234, "other": 0x5678}
		for index: int in 3:
			_put16(banks, MAP_SAVE_CHECKSUMS[index], values[case[index]])
		var ram: Dictionary = _load(banks)
		var valid: bool = case != ["bad", "bad", "other"]
		assert_eq([ram[0][SaveLoad.WCEEE - 0xC000] & 1, _sram_bytes(banks, 0, SaveLoad.S_CHECK_VALS, 1)[0]],
				[1, 0x77] if valid else [0, 0], str(case))


# --- the level's save ---

func test_a_level_save_with_a_higher_counter_wins_and_loads_the_level_and_its_objects() -> void:
	var banks: Array = _banks(0)
	banks[1][0] = 5
	banks[2][0x10] = 3
	banks[2][0x1001] = 7
	banks[3][0x1FFF] = 9
	_map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 5, 0x11, 0x0F)
	_map_save(banks, SaveLoad.S_BACKUP_CHECK_VALS, BACKUP_CHECKSUMS, 5, 0x11, 0x0F)
	var level: PackedByteArray = _level_save(banks, SaveLoad.S0A000, 6, 0x33, 0x02)
	for slot: int in [SaveLoad.S0A800, SaveLoad.S0A400, SaveLoad.S0AC00]:
		_level_save(banks, slot, 6, 0x33, 0x02)
	assert_eq(_map_sums(banks), [8, 16])
	var before: Array = []
	for bank: int in 4:
		before.append(banks[bank].duplicate())
	var ram: Dictionary = _load(banks)
	var sum: int = _sum(level.slice(0, 0xCA + 0x11 + 2))
	var wram0: PackedByteArray = _zeroes(0x1000)
	_w0(wram0, SaveLoad.W_SAVE_COUNTER, Array(level.slice(0, 0xCA)))
	# The last vote was the third copy's (all three agree); the first and third copies tie at 6.
	_w0(wram0, SaveLoad.W_CHECKSUM, [sum >> 8, sum & 0xFF, sum >> 8, sum & 0xFF, sum >> 8, sum & 0xFF])
	_w0(wram0, SaveLoad.WCEEE, [0xD7, 0x14])
	assert_eq(_diff(ram[0], wram0, 0xC000), [], "WRAM0")
	var wram1: PackedByteArray = _zeroes(0x1000)
	for offset: int in 0x14A:
		wram1[offset] = level[0xCA + 0x11 + offset]
	assert_eq(_diff(ram[1], wram1, 0xD000), [], "the objects, all $14a bytes")
	assert_eq([ram[2][0x10], ram[2][0x11]], [0x02, 0])
	# The map saves' counters shifted 31 times (5 << 31), the copies tied at 6 all 32; the second and
	# fourth copies' (not checked) copied as they are.
	_put(before, 0, SaveLoad.S0AFE0, PackedByteArray([0x80, 0, 0, 0, 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6,
		0, 0, 0, 0, 0, 0, 0, 6, 0]))
	for bank: int in 4:
		assert_eq(_diff(banks[bank], before[bank], 0xA000), [], "SRAM bank %d" % bank)


func test_the_third_copy_wins_and_restores_the_level_map_from_its_backup() -> void:
	var banks: Array = _banks(0)
	banks[2][0x1010] = 0x66  # the level map's backup
	banks[3][0x0100] = 0x77
	banks[3][0x1F00] = 0x88
	_map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 5, 0x11, 0x0F)
	_map_save(banks, SaveLoad.S_BACKUP_CHECK_VALS, BACKUP_CHECKSUMS, 5, 0x11, 0x0F)
	_level_save(banks, SaveLoad.S0A000, 6, 0x33, 0x02)
	_level_save(banks, SaveLoad.S0A800, 6, 0x33, 0x02)
	var level: PackedByteArray = _level_save(banks, SaveLoad.S0A400, 7, 0x44, 0x03)
	_level_save(banks, SaveLoad.S0AC00, 7, 0x44, 0x03)
	var sums: Array = _map_sums(banks)
	banks[1][0x100] = 0x44  # the level map changed since its checksum
	banks[2][0x0010] = 0x55
	var bank3: PackedByteArray = banks[3].duplicate()
	var upper: PackedByteArray = banks[2].slice(0x1000, 0x2000)
	var ram: Dictionary = _load(banks)
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 4), [0x93, 0x10, 0, 0], "bits 0, 1, 4, 7; the third copy alone")
	assert_eq(_wram0(ram, SaveLoad.W_SAVE_COUNTER, 0xCA), Array(level.slice(0, 0xCA)))
	assert_eq([_sram_bytes(banks, 0, SaveLoad.S0A000, 5), _sram_bytes(banks, 0, SaveLoad.S0A800, 5),
			_sram_bytes(banks, 0, SaveLoad.S0AC00, 4)], [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], CHECKVAL2],
			"the first two copies cleared with the level map's sum; the fourth not checked")
	assert_eq([banks[1] == bank3, banks[2].slice(0, 0x1000) == upper, banks[2].slice(0x1000) == upper], [true, true, true],
			"bank 3 to bank 1, bank 2's second half to its first")
	for at: int in [SaveLoad.S0A79D, SaveLoad.S0A7ED, SaveLoad.S0AFAD]:
		assert_eq(_sram_bytes(banks, 0, at, 2), [sums[1] >> 8, sums[1] & 0xFF], "the restored map's sum")
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S0A790, 1) + _sram_bytes(banks, 0, SaveLoad.S0A7E0, 1) + _sram_bytes(banks, 0, SaveLoad.S0AFA0, 1),
			[0, 0, 0])
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S0AFE0, 25), [0x80, 0, 0, 0, 0x80, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 6,
			0x80, 0, 0, 0, 0, 0, 0, 7, 0x10], "7 outlasts 5 at the 31st round")


func test_tied_counters_keep_every_tied_bit_and_the_map_save_loads_first() -> void:
	var banks: Array = _banks(0)
	var main: PackedByteArray = _map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 7, 0x11, 0x0F)
	_map_save(banks, SaveLoad.S_BACKUP_CHECK_VALS, BACKUP_CHECKSUMS, 7, 0x11, 0x0F)
	for slot: int in LEVEL_COPIES:
		_level_save(banks, slot, 7, 0x33, 0x02)
	_map_sums(banks)
	var ram: Dictionary = _load(banks)
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 2), [0xD7, 0x17])
	assert_eq(_wram0(ram, SaveLoad.W_SAVE_COUNTER, 0xCA), Array(main.slice(0, 0x5B)) + Array(_zeroes(0xCA - 0x5B)),
			"the map save: the progress WRAM alone")
	assert_eq(_diff(ram[1], _zeroes(0x1000), 0xD000), [], "no objects")
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S0AFE0, 25), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7,
			0, 0, 0, 0, 0, 0, 0, 7, 0x17], "the four shifted out, 7's last bit carried by all")


func test_wcef1_takes_the_markers_two_that_agree_when_a_slot_has_its_check_values() -> void:
	# [s0a790, s0a7e0, s0afa0] -> wcef1
	for case: Array in [[[0x12, 0x34, 0x12], 0x12], [[0x34, 0x12, 0x12], 0x12], [[0x12, 0x12, 0x34], 0x12],
			[[0x12, 0x34, 0x56], 0xFF], [[0x10, 0x10, 0x10], 0x10]]:
		var banks: Array = _banks(0)
		_map_save(banks, SaveLoad.S_CHECK_VALS, MAP_SAVE_CHECKSUMS, 1, 0x11, 0x0F)
		var markers: Array = case[0]
		for index: int in 3:
			_put(banks, 0, [SaveLoad.S0A790, SaveLoad.S0A7E0, SaveLoad.S0AFA0][index], PackedByteArray([markers[index]]))
		var ram: Dictionary = _load(banks)
		assert_eq(_wram0(ram, SaveLoad.WCEF1), [case[1]], str(markers))
		assert_eq(_sram_bytes(banks, 0, SaveLoad.S0A790, 1), [0], "left at 0 by the clearings")
	var none: Array = _banks(0)
	_put(none, 0, SaveLoad.S0A790, PackedByteArray([0x10]))
	_put(none, 0, SaveLoad.S0A7E0, PackedByteArray([0x10]))
	_put(none, 0, SaveLoad.S0AFA0, PackedByteArray([0x10]))
	assert_eq(_wram0(_load(none), SaveLoad.WCEF1), [0xFF], "no check values: $ff")


# --- CalculateChecksumLong ---

func test_calculate_checksum_long_sums_its_first_byte_and_then_b_more() -> void:
	var bytes := PackedByteArray()
	for index: int in 0x400:
		bytes.append(index & 0xFF)
	assert_eq(SaveLoad.calculate_checksum_long(bytes, 1, 0x14A, 0), [1 + 2, 3], "$14a: two bytes")
	assert_eq(SaveLoad.calculate_checksum_long(bytes, 1, 1, 0x10), [0x11, 2], "1: one")
	assert_eq(SaveLoad.calculate_checksum_long(bytes, 1, 0x0201, 0), [1 + 2 + 3, 4], "$201: B is 2")
	var long: int = 0
	for index: int in range(1, 258):
		long += index & 0xFF
	assert_eq(SaveLoad.calculate_checksum_long(bytes, 1, 0xFF, 0), [long, 258], "$ff: B is 0, so 256 more")
	assert_eq(SaveLoad.calculate_checksum(bytes, 0xFF, 0, 0xFFFF)[1], 0xFF + 0x100, "CalculateChecksum: 0 is 256")
	assert_eq(SaveLoad.calculate_checksum(PackedByteArray([0xFF, 0xFF]), 0, 2, 0xFF02)[0], 0x0100, "16 bits")


func test_a_level_copy_is_checked_on_its_first_two_objects_only() -> void:
	var banks: Array = _banks(0)
	_level_save(banks, SaveLoad.S0A000, 3, 0x33, 0x02)
	var second: PackedByteArray = _level_save(banks, SaveLoad.S0A800, 3, 0x33, 0x02)
	_map_sums(banks)
	var objects: int = 4 + 0xCA + 0x11
	banks[0][SaveLoad.S0A000 - 0xA000 + objects + 1] ^= 0x80  # the second object: summed
	banks[0][SaveLoad.S0A800 - 0xA000 + objects + 2] = 0xEE  # the third and the last: not summed
	banks[0][SaveLoad.S0A800 - 0xA000 + objects + 0x149] = 0xDD
	var ram: Dictionary = _load(banks)
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 2), [0xC8, 0x08], "the first copy invalid, the second valid")
	assert_eq(_sram_bytes(banks, 0, SaveLoad.S0A000, 4), [0, 0, 0, 0])
	assert_eq([ram[1][0], ram[1][1], ram[1][2], ram[1][0x149], ram[1][0x14A]],
			[second[0xDB], second[0xDC], 0xEE, 0xDD, 0], "the objects as stored")


# --- with the save screen's Save ---

func test_the_save_screens_save_loads_back_into_a_cleared_ram() -> void:
	var pause := PauseMenuSim.new(LevelSim.new())
	pause.load_data({"gfx": {"palettes": {PauseMenuSim.SAVE_SCREEN_PALS: "11".repeat(0x40)}}})
	for offset: int in 0x5B:
		pause.w0(PauseMenuSim.W_SAVE_COUNTER + offset, offset * 5 + 3)
	for offset: int in 0x11:
		pause.wx(2, PauseMenuSim.W_TREASURES_COLLECTED + offset, 0x80 | offset)
	pause.save()
	var banks: Array = [pause.sram[0].duplicate(), _zeroes(0x2000), _zeroes(0x2000), _zeroes(0x2000)]
	var ram: Dictionary = _load(banks)
	var saved: Array = []
	for offset: int in 0x5B:
		saved.append(pause.r0(PauseMenuSim.W_SAVE_COUNTER + offset))
	assert_eq(_wram0(ram, SaveLoad.W_SAVE_COUNTER, 0x5B), saved, "the progress, its counter one on")
	assert_eq(Array(ram[2].slice(0, 0x12)), Array(pause.wram[2].slice(0, 0x11)) + [0])
	assert_eq(_wram0(ram, SaveLoad.WCEEE, 4), [0xC3, 0x03, 0, 0])
	assert_eq(SaveLoad.save_bytes(SaveLoad.sram_banks(SaveLoad.save_bytes(banks))) == SaveLoad.save_bytes(banks), true)
