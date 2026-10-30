class_name SaveLoad
extends RefCounted
## The save's load: ValidateSaveData (7c:4cad, src/engine/pause/save/validate_save.asm), which Init
## (src/home/start.asm) calls once the RAM is cleared and before InitGameState, ported by translation
## (WL3-055) with what it calls: CheckSaveVals1 and CheckSaveVals2, Func_1f0d60 (each slot's stored
## checksum voted with its two echoes, .GetMatchingChecksum, against the slot's sum; an invalid slot's
## check values cleared), Func_1f1246 (the valid slot with the highest save counter loaded, or the
## Time Attack and golf scores' defaults), and from checksum.asm CalculateChecksum,
## CalculateChecksumLong (its bug kept), Func_1f0b5b, and CalculateBackupSRAMChecksum1 and 2.
##
## It works on the RAM as bytes: SRAM banks 0-3 (8 KiB each from $a000: a 32 KiB battery save) and
## WRAM by bank as MenuScreenSim keeps it (0 for WRAM0 from $c000; WRAMX banks 1 and 2 from $d000,
## 4 KiB each). Not kept: rRAMB and rWBK (the banks it switches, restored at the end), and what its
## calls and pushes leave in the stack page ($cf00-$cfff).
##
## The six slots, by their bit in wceee and wceef: 0 the map's save (sCheckVals, "war3"), 1 its
## backup (sBackupCheckVals), 2 and 3 the level's save's first two copies (s0a000, s0a800, "WAR3"),
## valid only while the level map's SRAM (bank 1 and bank 2's first half) sums to s0a79d (bit 6),
## and 4 and 5 its last two (s0a400, s0ac00), saved after the map's backup (bank 3 and bank 2's second
## half), valid only while that sums to s0a79f (bit 7).

# WRAM0 (src/ram/wram.asm): the SRAM bank switched to, the progress WRAM the save holds from its
# counter on, and the load's own variables.
const W_SRAM_BANK: int = 0xC08E
const W_SAVE_COUNTER: int = 0xCA00  # STARTOF("Progress WRAM")
const W_LEVEL_TIME_ATTACK_SCORES: int = 0xCA07
const W_GOLF_BEST_SCORES: int = 0xCA42
const W_CHECKSUM: int = 0xCEE7
const WCEE9: int = 0xCEE9
const WCEEB: int = 0xCEEB
const WCEEE: int = 0xCEEE
const WCEEF: int = 0xCEEF
const W_CHECKSUM_MISMATCHES: int = 0xCEF0
const WCEF1: int = 0xCEF1
# WRAMX bank 1 (Level Objects WRAM, from wObjects) and bank 2 (WRAM2, the treasures to wOWLevel).
const W_OBJECTS: int = 0xD000
const W_TREASURES_COLLECTED: int = 0xD000
# SRAM bank 0 (src/ram/sram.asm): the map's save and its backup, each after its check values; the
# level's save's four copies, each after its check values; the checksums with their two echoes; the
# progress markers; and the counters' scratch copies Func_1f1246 shifts.
const S0A000: int = 0xA000
const S_SAVE_COUNTER: int = 0xA004
const S_CHECK_VALS: int = 0xA380
const S_GAME_DATA: int = 0xA384
const S0A400: int = 0xA400
const S0A404: int = 0xA404
const S0A790: int = 0xA790
const S_GAME_DATA_CHECKSUM: int = 0xA791
const S_BACKUP_GAME_DATA_CHECKSUM: int = 0xA793
const S_WRAM_CHECKSUM: int = 0xA795
const S_BACKUP1_WRAM_CHECKSUM: int = 0xA797
const S_BACKUP2_WRAM_CHECKSUM: int = 0xA799
const S_BACKUP3_WRAM_CHECKSUM: int = 0xA79B
const S0A79D: int = 0xA79D
const S0A79F: int = 0xA79F
const S0A7E0: int = 0xA7E0
const S_GAME_DATA_CHECKSUM_ECHO1: int = 0xA7E1
const S_BACKUP_GAME_DATA_CHECKSUM_ECHO1: int = 0xA7E3
const S_WRAM_CHECKSUM_ECHO1: int = 0xA7E5
const S_BACKUP1_WRAM_CHECKSUM_ECHO1: int = 0xA7E7
const S_BACKUP2_WRAM_CHECKSUM_ECHO1: int = 0xA7E9
const S_BACKUP3_WRAM_CHECKSUM_ECHO1: int = 0xA7EB
const S0A7ED: int = 0xA7ED
const S0A7EF: int = 0xA7EF
const S0A800: int = 0xA800
const S0A804: int = 0xA804
const S_BACKUP_CHECK_VALS: int = 0xAB80
const S_BACKUP_GAME_DATA: int = 0xAB84
const S0AC00: int = 0xAC00
const S0AC04: int = 0xAC04
const S0AFA0: int = 0xAFA0
const S_GAME_DATA_CHECKSUM_ECHO2: int = 0xAFA1
const S_BACKUP_GAME_DATA_CHECKSUM_ECHO2: int = 0xAFA3
const S_WRAM_CHECKSUM_ECHO2: int = 0xAFA5
const S_BACKUP1_WRAM_CHECKSUM_ECHO2: int = 0xAFA7
const S_BACKUP2_WRAM_CHECKSUM_ECHO2: int = 0xAFA9
const S_BACKUP3_WRAM_CHECKSUM_ECHO2: int = 0xAFAB
const S0AFAD: int = 0xAFAD
const S0AFAF: int = 0xAFAF
const S0AFE0: int = 0xAFE0
const S0AFE4: int = 0xAFE4
const S0AFE8: int = 0xAFE8
const S0AFEC: int = 0xAFEC
const S0AFF0: int = 0xAFF0
const S0AFF4: int = 0xAFF4
const S0AFF8: int = 0xAFF8
# SRAM banks 1 to 3: the level's map (bank 1 and bank 2's first half) and its backup (bank 2's second
# half and bank 3).
const S_LEVEL_BLOCK_OBJECT_MAP: int = 0xA000
const S2A000: int = 0xA000
const S2B000: int = 0xB000
const S3A000: int = 0xA000

# src/constants/ and the sections' sizes (the reference build's map).
const PROGRESS_WRAM_SIZE: int = 0x5B  # SIZEOF("Progress WRAM")
const LEVEL_WRAM_SIZE: int = 0x6F  # SIZEOF("Level WRAM"); Func_1f0b5b's $ca is both
const LEVEL_OBJECTS_WRAM_SIZE: int = 0x14A  # SIZEOF("Level Objects WRAM")
const TREASURES_SIZE: int = 0x11  # (wOWLevel - wTreasuresCollected) + 2
const SRAM_SIZE: int = 0x2000  # SIZEOF(SRAM), a bank
const WRAM_BANK_SIZE: int = 0x1000
const NUM_LEVELS: int = 25
const CHECKVAL1: Array = [0x77, 0x61, 0x72, 0x33]  # CHECKVAL1_1-4, "war3"
const CHECKVAL2: Array = [0x57, 0x41, 0x52, 0x33]  # CHECKVAL2_1-4, "WAR3"
const MISMATCH_ORIG: int = 1 << 0
const MISMATCH_ECHO1: int = 1 << 1
const MISMATCH_ECHO2: int = 1 << 2
## Func_1f1246's defaults for the Time Attack and golf scores without a save: (10 << 4) | 10.
const NO_SCORE: int = (10 << 4) | 10

## SRAM by bank, 0-3 (an Array of four PackedByteArrays, or a Dictionary by bank), and WRAM by bank
## (a Dictionary: 0 for WRAM0, 1 and 2 for WRAMX), as validate_save_data was given them.
var sram: Variant = []
var wram: Dictionary = {}


## ValidateSaveData on `save_sram` (SRAM banks 0-3, 8 KiB each from $a000) and `ram` (WRAM by bank,
## 4 KiB each: 0 for WRAM0 from $c000, 1 and 2 for WRAMX from $d000), both changed in place as the
## original changes them. A WRAM bank `ram` lacks is added zeroed, as Init leaves it. wcef1 takes the
## progress markers' majority when any slot has its check values (else $ff), Func_1f0d60 finds the
## valid slots and Func_1f1246 loads one; the SRAM bank switched to is restored at the end.
func validate_save_data(save_sram: Variant, ram: Dictionary) -> void:
	sram = save_sram
	wram = ram
	for sram_bank: int in 4:
		if not _has_sram_bank(sram_bank):
			push_error("ValidateSaveData: SRAM bank %d not given" % sram_bank)
			return
	for wram_bank: int in [0, 1, 2]:
		if not wram.has(wram_bank):
			wram[wram_bank] = _zeroes(WRAM_BANK_SIZE)
	var bank: int = r0(W_SRAM_BANK)  # push af
	sramswitch(0)
	if check_save_vals_1(S_CHECK_VALS) or check_save_vals_2(S0A000) or check_save_vals_2(S0A400) \
			or check_save_vals_1(S_BACKUP_CHECK_VALS) or check_save_vals_2(S0A800) or check_save_vals_2(S0AC00):
		# .checkvals_ok: the markers' two that agree, s0afa0 first.
		var b: int = rs(0, S0A790)
		var c: int = rs(0, S0A7E0)
		var d: int = rs(0, S0AFA0)
		if d == b or d == c:
			w0(WCEF1, d)
		elif b == c:
			w0(WCEF1, b)
		else:
			w0(WCEF1, 0xFF)  # .asm_1f0d0f
	else:
		w0(WCEF1, 0xFF)  # .asm_1f0d0f
	func_1f0d60()
	func_1f1246()
	sramswitch(bank)  # pop af


## CheckSaveVals1: whether the four bytes at `address` (SRAM bank 0) are CHECKVAL1, "war3" (the
## original returns carry when they are not).
func check_save_vals_1(address: int) -> bool:
	return _check_vals(address, CHECKVAL1)


## CheckSaveVals2: whether the four bytes at `address` are CHECKVAL2, "WAR3".
func check_save_vals_2(address: int) -> bool:
	return _check_vals(address, CHECKVAL2)


func _check_vals(address: int, values: Array) -> bool:
	for offset: int in 4:
		if rs(0, address + offset) != int(values[offset]):
			return false
	return true


## Func_1f0d60: wceee from 0, a bit set for each slot whose sum matches its voted checksum
## (_voted_checksum_matches). The map's save (bit 0) and its backup (bit 1) each have their check
## values cleared when invalid (markers $10, $20). The level map's SRAM matching s0a79d (bit 6) lets
## the level's first copy (bit 2) be checked, and only if it fails, the second (bit 3); an invalid
## copy's check values are cleared (markers $30, $50), both when bit 6 fails. The same for the map's
## backup and s0a79f (bit 7), the third copy (bit 4) and the fourth (bit 5) (markers $60, $80). The
## markers are left at 0 after each clearing.
func func_1f0d60() -> void:
	w0(WCEEE, 0)
	if check_save_vals_1(S_CHECK_VALS) and _voted_checksum_matches(S_GAME_DATA_CHECKSUM,
			S_GAME_DATA_CHECKSUM_ECHO1, S_GAME_DATA_CHECKSUM_ECHO2, calculate_checksum_at_hl.bind(S_GAME_DATA)):
		_set_wceee(0)  # .asm_1f0dc2
	else:
		_clear_check_vals(0x10, S_CHECK_VALS)  # .clear_check_vals
		_set_markers(0)
	# .check_backup_check_vals
	if check_save_vals_1(S_BACKUP_CHECK_VALS) and _voted_checksum_matches(S_BACKUP_GAME_DATA_CHECKSUM,
			S_BACKUP_GAME_DATA_CHECKSUM_ECHO1, S_BACKUP_GAME_DATA_CHECKSUM_ECHO2,
			calculate_checksum_at_hl.bind(S_BACKUP_GAME_DATA)):
		_set_wceee(1)  # .asm_1f0e47
	else:
		_clear_check_vals(0x20, S_BACKUP_CHECK_VALS)  # .clear_backup_check_vals
		_set_markers(0)
	# .asm_1f0e6e
	if _voted_checksum_matches(S0A79D, S0A7ED, S0AFAD, calculate_backup_sram_checksum_1):
		_set_wceee(6)  # .asm_1f0ec1
		if check_save_vals_2(S0A000) and _voted_checksum_matches(S_WRAM_CHECKSUM, S_WRAM_CHECKSUM_ECHO1,
				S_WRAM_CHECKSUM_ECHO2, func_1f0b5b_at.bind(S_SAVE_COUNTER)):
			_set_wceee(2)  # .asm_1f0f27, on to .asm_1f0fe2 without the second copy
		else:
			_clear_check_vals(0x30, S0A000)  # .asm_1f0f2f
			_set_markers(0)
			if check_save_vals_2(S0A800) and _voted_checksum_matches(S_BACKUP1_WRAM_CHECKSUM,
					S_BACKUP1_WRAM_CHECKSUM_ECHO1, S_BACKUP1_WRAM_CHECKSUM_ECHO2, func_1f0b5b_at.bind(S0A804)):
				_set_wceee(3)  # .asm_1f0faa
			else:
				_clear_first_level_copies()  # .asm_1f0fb2
	else:
		_clear_first_level_copies()  # .asm_1f0efd: jp .asm_1f0fb2
	# .asm_1f0fe2
	if _voted_checksum_matches(S0A79F, S0A7EF, S0AFAF, calculate_backup_sram_checksum_2):
		_set_wceee(7)  # .asm_1f1035
		if check_save_vals_2(S0A400) and _voted_checksum_matches(S_BACKUP2_WRAM_CHECKSUM,
				S_BACKUP2_WRAM_CHECKSUM_ECHO1, S_BACKUP2_WRAM_CHECKSUM_ECHO2, func_1f0b5b_at.bind(S0A404)):
			_set_wceee(4)  # .asm_1f109b
			return
		_clear_check_vals(0x60, S0A400)  # .asm_1f10a1
		_set_markers(0)
		if check_save_vals_2(S0AC00) and _voted_checksum_matches(S_BACKUP3_WRAM_CHECKSUM,
				S_BACKUP3_WRAM_CHECKSUM_ECHO1, S_BACKUP3_WRAM_CHECKSUM_ECHO2, func_1f0b5b_at.bind(S0AC04)):
			_set_wceee(5)  # .asm_1f111c
			return
	# .asm_1f1122 (from .asm_1f1071 too)
	_clear_check_vals(0x60, S0A400)
	_clear_check_vals(0x80, S0AC00)
	_set_markers(0)


## A slot's checksum check, as each of Func_1f0d60's six does it: the stored checksum and its echoes
## (each two bytes, high first) voted (.GetMatchingChecksum), then the slot's sum (`sum`, DE) taken
## and compared: equal to wChecksum; or, with a mismatch, to wcee9; or, with all three different, to
## wceeb.
func _voted_checksum_matches(checksum: int, echo1: int, echo2: int, sum: Callable) -> bool:
	get_matching_checksum(rs(0, checksum), rs(0, checksum + 1), rs(0, echo1), rs(0, echo1 + 1),
		rs(0, echo2), rs(0, echo2 + 1))
	var de: int = int(sum.call())
	var d: int = de >> 8
	var e: int = de & 0xFF
	if r0(W_CHECKSUM) == d and r0(W_CHECKSUM + 1) == e:
		return true
	if r0(W_CHECKSUM_MISMATCHES) == 0:
		return false
	if r0(WCEE9) == d and r0(WCEE9 + 1) == e:
		return true
	if r0(W_CHECKSUM_MISMATCHES) != MISMATCH_ORIG | MISMATCH_ECHO1 | MISMATCH_ECHO2:
		return false
	return r0(WCEEB) == d and r0(WCEEB + 1) == e


## .GetMatchingChecksum: of the checksum (BC) and its echoes (DE, HL), the value two agree on in
## wChecksum (the checksum when none do) with wChecksumMismatches naming the one that differs (0 when
## all agree, all three bits when none do); wcee9 takes the odd one out, wceeb the other candidate.
## The high bytes are compared first, as the original does.
func get_matching_checksum(b: int, c: int, d: int, e: int, h: int, l: int) -> void:
	if h == b:
		if h == d:
			# .all_high_bytes_equal
			if l != c:
				# .check_echos_equality
				if l == e:
					_only_echos_equal(b, c, d, e)
				elif c == e:
					_only_echo1_equal(b, c, h, l)
				else:
					_none_equal(b, c, d, e, h, l)
			elif l == e:
				_all_equal(b, c)
			else:
				_only_echo2_equal(b, c, d, e)
		elif c != l:
			_none_equal(b, c, d, e, h, l)
		else:
			_only_echo2_equal(b, c, d, e)
	elif h == d:
		# .echo2_not_equal, .check_lower_echos
		if e != l:
			_none_equal(b, c, d, e, h, l)
		else:
			_only_echos_equal(b, c, d, e)
	elif b == d:
		# .check_lower_echo1
		if c != e:
			_none_equal(b, c, d, e, h, l)
		else:
			_only_echo1_equal(b, c, h, l)
	else:
		_none_equal(b, c, d, e, h, l)


## .none_equal: the checksum in wChecksum, echo 1 in wcee9, echo 2 in wceeb.
func _none_equal(b: int, c: int, d: int, e: int, h: int, l: int) -> void:
	w0(W_CHECKSUM_MISMATCHES, MISMATCH_ORIG | MISMATCH_ECHO1 | MISMATCH_ECHO2)
	_w16(W_CHECKSUM, b, c)
	_w16(WCEE9, d, e)
	_w16(WCEEB, h, l)


## .only_echo1_equal: the checksum (with echo 1) in wChecksum and wceeb, echo 2 in wcee9.
func _only_echo1_equal(b: int, c: int, h: int, l: int) -> void:
	w0(W_CHECKSUM_MISMATCHES, MISMATCH_ECHO2)
	_w16(W_CHECKSUM, b, c)
	_w16(WCEEB, b, c)
	_w16(WCEE9, h, l)


## .only_echo2_equal: the checksum (with echo 2) in wChecksum and wceeb, echo 1 in wcee9.
func _only_echo2_equal(b: int, c: int, d: int, e: int) -> void:
	w0(W_CHECKSUM_MISMATCHES, MISMATCH_ECHO1)
	_w16(W_CHECKSUM, b, c)
	_w16(WCEEB, b, c)
	_w16(WCEE9, d, e)


## .only_echos_equal: echo 1 (with echo 2) in wChecksum and wceeb, the checksum in wcee9.
func _only_echos_equal(b: int, c: int, d: int, e: int) -> void:
	w0(W_CHECKSUM_MISMATCHES, MISMATCH_ORIG)
	_w16(W_CHECKSUM, d, e)
	_w16(WCEEB, d, e)
	_w16(WCEE9, b, c)


## .all_equal: the checksum in all three.
func _all_equal(b: int, c: int) -> void:
	w0(W_CHECKSUM_MISMATCHES, 0)
	_w16(W_CHECKSUM, b, c)
	_w16(WCEE9, b, c)
	_w16(WCEEB, b, c)


## .CalculateChecksumAtHL: a map save's sum, its progress WRAM's $5b bytes from `hl` (SRAM bank 0)
## and its treasures' $11 after them.
func calculate_checksum_at_hl(hl: int) -> int:
	var de_hl: Array = calculate_checksum(sram[0], hl - 0xA000, PROGRESS_WRAM_SIZE, 0)
	return int(calculate_checksum(sram[0], int(de_hl[1]), TREASURES_SIZE, int(de_hl[0]))[0])


## Func_1f0b5b from `hl` in SRAM bank 0 (a level save's copy after its check values).
func func_1f0b5b_at(hl: int) -> int:
	return func_1f0b5b(sram[0], hl - 0xA000)


## Func_1f0b5b: a level save copy's sum from `hl` (an index into `bytes`): the progress and level
## WRAM's $ca bytes, the treasures' $11, then CalculateChecksumLong over the objects' $14a, which
## sums two of them.
static func func_1f0b5b(bytes: PackedByteArray, hl: int) -> int:
	var de_hl: Array = calculate_checksum(bytes, hl, PROGRESS_WRAM_SIZE + LEVEL_WRAM_SIZE, 0)
	de_hl = calculate_checksum(bytes, int(de_hl[1]), TREASURES_SIZE, int(de_hl[0]))
	return int(calculate_checksum_long(bytes, int(de_hl[1]), LEVEL_OBJECTS_WRAM_SIZE, int(de_hl[0]))[0])


## CalculateChecksum: `b` bytes from `hl` (an index into `bytes`) added into `de`, 16 bits wide
## (B counts down to 0: 0 sums 256). Returns [DE, HL] after it.
static func calculate_checksum(bytes: PackedByteArray, hl: int, b: int, de: int) -> Array:
	for _i: int in (b & 0xFF if b & 0xFF != 0 else 0x100):
		de = (de + bytes[hl]) & 0xFFFF
		hl += 1
	return [de, hl]


## CalculateChecksumLong: meant to sum `bc` bytes, but its loop jumps back into CalculateChecksum
## (`jr nz, CalculateChecksum`, "should be .start"), so it adds the first byte, then, unless BC was 1,
## B more: the high byte of BC less one, 256 when that is 0. With $14a, two bytes. Returns [DE, HL].
static func calculate_checksum_long(bytes: PackedByteArray, hl: int, bc: int, de: int) -> Array:
	de = (de + bytes[hl]) & 0xFFFF
	hl += 1
	bc = (bc - 1) & 0xFFFF
	if bc == 0:
		return [de, hl]
	return calculate_checksum(bytes, hl, bc >> 8, de)


## CalculateBackupSRAMChecksum1: the level map's sum, SRAM bank 1 whole and bank 2's first half.
func calculate_backup_sram_checksum_1() -> int:
	var bank: int = r0(W_SRAM_BANK)
	sramswitch(1)
	var de: int = _sum_sram(1, S_LEVEL_BLOCK_OBJECT_MAP, SRAM_SIZE, 0)
	sramswitch(bank)
	bank = r0(W_SRAM_BANK)
	sramswitch(2)
	de = _sum_sram(2, S2A000, 0x1000, de)
	sramswitch(bank)
	return de


## CalculateBackupSRAMChecksum2: the map's backup's sum, SRAM bank 3 whole and bank 2's second half.
func calculate_backup_sram_checksum_2() -> int:
	var bank: int = r0(W_SRAM_BANK)
	sramswitch(3)
	var de: int = _sum_sram(3, S3A000, SRAM_SIZE, 0)
	sramswitch(bank)
	bank = r0(W_SRAM_BANK)
	sramswitch(2)
	de = _sum_sram(2, S2B000, 0x1000, de)
	sramswitch(bank)
	return de


## The loops of CalculateBackupSRAMChecksum1 and 2: `count` bytes (BC, a multiple of 256) from
## `address` in SRAM bank `bank` added into `de`.
func _sum_sram(bank: int, address: int, count: int, de: int) -> int:
	var bytes: PackedByteArray = sram[bank]
	for offset: int in count:
		de = (de + bytes[address - 0xA000 + offset]) & 0xFFFF
	return de


## Func_1f1246: wceef from 0, then wceee's slot bits (0-5). None: the Time Attack scores (two bytes a
## level) and the golf best scores (four bytes) set to $aa, and wceef left 0. One: that slot loaded.
## More: the six slots' save counters (each data's first four bytes, big-endian; copied whether valid
## or not) to s0afe0-s0aff7, and for up to 32 rounds each counter still in wceef shifted left a bit,
## s0aff8 taking the bits whose counter carried out; when any did, wceef becomes s0aff8, and once one
## bit is left it stops. So the highest counter wins; a tie keeps every tied bit in wceef (the map's
## save and its backup after one save: 3), and the lowest of them is loaded: the map's save before its
## backup before the level's copies, by address s0a000, s0a800, s0a400, s0ac00.
func func_1f1246() -> void:
	w0(WCEEF, 0)
	var a: int = r0(WCEEE) & 0x3F
	if a == 0:
		_set_no_save_scores()
		return
	w0(WCEEF, a)  # .asm_1f1266
	if _count_slot_bits(a) != 1:
		for copy: Array in [[S_GAME_DATA, S0AFE0], [S_BACKUP_GAME_DATA, S0AFE4], [S_SAVE_COUNTER, S0AFE8],
				[S0A804, S0AFEC], [S0A404, S0AFF0], [S0AC04, S0AFF4]]:
			for offset: int in 4:  # CopyHLToDE
				ws(0, int(copy[1]) + offset, rs(0, int(copy[0]) + offset))
		for _shift: int in 32:  # e from $21, .asm_1f12c0
			ws(0, S0AFF8, 0)
			for slot: int in 6:
				if r0(WCEEF) & (1 << slot) != 0 and _shift_counter(S0AFE0 + 4 * slot):
					ws(0, S0AFF8, rs(0, S0AFF8) | (1 << slot))
			var carried: int = rs(0, S0AFF8)  # .asm_1f1370
			if carried == 0:
				continue
			w0(WCEEF, carried)
			if _count_slot_bits(carried) == 1:
				break
	# .asm_1f1389
	var wceef: int = r0(WCEEF)
	if wceef & (1 << 0) != 0:
		_func_1f13d7(S_GAME_DATA)
	elif wceef & (1 << 1) != 0:
		_func_1f13d7(S_BACKUP_GAME_DATA)
	elif wceef & (1 << 2) != 0:
		_func_1f13f2(S_SAVE_COUNTER)
	elif wceef & (1 << 3) != 0:
		_func_1f13f2(S0A804)
	elif wceef & (1 << 4) != 0:
		_func_1f13f2(S0A404)
		_func_1f1420()
	elif wceef & (1 << 5) != 0:
		_func_1f13f2(S0AC04)
		_func_1f1420()
	else:
		_set_no_save_scores()  # jp .asm_1f1251 (not reached: wceef is never 0 here)


## .asm_1f1251: WriteAToHL_BTimes, $aa over wLevelTimeAttackScores (2 * NUM_LEVELS) and
## wGolfBestScores (4).
func _set_no_save_scores() -> void:
	for offset: int in 2 * NUM_LEVELS:
		w0(W_LEVEL_TIME_ATTACK_SCORES + offset, NO_SCORE)
	for offset: int in 4:
		w0(W_GOLF_BEST_SCORES + offset, NO_SCORE)


## The rrca loop (b = 6): how many of the six slot bits are set.
static func _count_slot_bits(a: int) -> int:
	var c: int = 0
	for bit: int in 6:
		if a & (1 << bit) != 0:
			c += 1
	return c


## sla on the counter's last byte, rl on the three before it: the 4-byte big-endian counter at
## `address` (SRAM bank 0) shifted left a bit; whether its top bit carried out.
func _shift_counter(address: int) -> bool:
	var carry: int = 0
	for offset: int in [3, 2, 1, 0]:
		var value: int = (rs(0, address + offset) << 1) | carry
		ws(0, address + offset, value)
		carry = value >> 8
	return carry != 0


## .Func_1f13d7: a map save loaded from `hl`: $5b bytes to the progress WRAM ($ca00), $11 to WRAMX
## bank 2's $d000 (the treasures).
func _func_1f13d7(hl: int) -> void:
	for offset: int in PROGRESS_WRAM_SIZE:
		w0(W_SAVE_COUNTER + offset, rs(0, hl + offset))
	hl += PROGRESS_WRAM_SIZE
	for offset: int in TREASURES_SIZE:
		wx(2, W_TREASURES_COLLECTED + offset, rs(0, hl + offset))


## .Func_1f13f2: a level save's copy loaded from `hl`: $ca bytes to the progress and level WRAM
## (wSaveCounter on), $11 to WRAMX bank 2's $d000, and $14a to the level's objects (WRAMX bank 1).
func _func_1f13f2(hl: int) -> void:
	for offset: int in PROGRESS_WRAM_SIZE + LEVEL_WRAM_SIZE:
		w0(W_SAVE_COUNTER + offset, rs(0, hl + offset))
	hl += PROGRESS_WRAM_SIZE + LEVEL_WRAM_SIZE
	for offset: int in TREASURES_SIZE:
		wx(2, W_TREASURES_COLLECTED + offset, rs(0, hl + offset))
	hl += TREASURES_SIZE
	for offset: int in LEVEL_OBJECTS_WRAM_SIZE:  # CopyHLToDE_BC
		wx(1, W_OBJECTS + offset, rs(0, hl + offset))


## .Func_1f1420: for the level's last two copies, the level map restored from its backup (SRAM bank
## 2's second half to its first, bank 3 to bank 1) and its checksum (CalculateBackupSRAMChecksum1)
## written to s0a79d and its echoes, the markers stepped $40 to $43 and left at 0.
func _func_1f1420() -> void:
	_set_markers(0x40)
	var bank: int = r0(W_SRAM_BANK)
	sramswitch(2)
	for offset: int in 0x1000:  # CopyHLToDE_BC
		ws(2, S2A000 + offset, rs(2, S2B000 + offset))
	sramswitch(bank)
	for offset: int in SRAM_SIZE:  # .loop: bank 3's byte to bank 1's, the bank switched back each time
		ws(1, S_LEVEL_BLOCK_OBJECT_MAP + offset, rs(3, S3A000 + offset))
	_set_markers(0x41)
	var de: int = calculate_backup_sram_checksum_1()
	_ws16(S0A79D, de)
	_set_markers(0x42)
	_ws16(S0A7ED, de)
	_set_markers(0x43)
	_ws16(S0AFAD, de)
	_set_markers(0)


## The clearing of a slot's check values: the markers set to `marker`, then the four bytes at
## `address` zeroed.
func _clear_check_vals(marker: int, address: int) -> void:
	_set_markers(marker)
	for offset: int in 4:
		ws(0, address + offset, 0)


## .asm_1f0fb2: the level's first two copies' check values cleared (markers $30, $50), the markers
## left at 0.
func _clear_first_level_copies() -> void:
	_clear_check_vals(0x30, S0A000)
	_clear_check_vals(0x50, S0A800)
	_set_markers(0)


## The progress markers s0a790, s0a7e0, s0afa0, all three set to `value`.
func _set_markers(value: int) -> void:
	for address: int in [S0A790, S0A7E0, S0AFA0]:
		ws(0, address, value)


func _set_wceee(bit: int) -> void:
	w0(WCEEE, r0(WCEEE) | (1 << bit))


## sramswitch: wSRAMBank (and rRAMB, not kept).
func sramswitch(bank: int) -> void:
	w0(W_SRAM_BANK, bank)


# --- RAM access, by bank as MenuScreenSim keeps it ---

func r0(address: int) -> int:
	return wram[0][address - 0xC000]


func w0(address: int, value: int) -> void:
	wram[0][address - 0xC000] = value & 0xFF
	_mark(0, address - 0xC000)


func rx(bank: int, address: int) -> int:
	return wram[bank][address - 0xD000]


func wx(bank: int, address: int, value: int) -> void:
	wram[bank][address - 0xD000] = value & 0xFF
	_mark(bank, address - 0xD000)


func rs(bank: int, address: int) -> int:
	return sram[bank][address - 0xA000]


func ws(bank: int, address: int, value: int) -> void:
	sram[bank][address - 0xA000] = value & 0xFF
	if bank == 0:
		_mark("sram", address - 0xA000)


func _w16(address: int, high: int, low: int) -> void:
	w0(address, high)
	w0(address + 1, low)


func _ws16(address: int, value: int) -> void:
	ws(0, address, value >> 8)
	ws(0, address + 1, value)


## With LevelSim.track_known_ram's "known" entry, a written byte marked there (by bank, "sram" for
## SRAM bank 0) when it keeps that bank.
func _mark(bank: Variant, offset: int) -> void:
	if wram.has("known") and wram["known"].has(bank):
		wram["known"][bank][offset] = 1


func _has_sram_bank(bank: int) -> bool:
	if sram is Array:
		return bank < sram.size() and sram[bank] is PackedByteArray and sram[bank].size() == SRAM_SIZE
	if sram is Dictionary:
		return sram.has(bank) and sram[bank] is PackedByteArray and sram[bank].size() == SRAM_SIZE
	return false


## ClearSaveData (src/home/clear_save.asm, Clear Data's Yes on the title), on SRAM banks 0-3 (`banks`):
## the 8 bytes at each copy of the save's start cleared (sCheckVals, sBackupCheckVals, s0a000, s0a800,
## s0a400, s0ac00), so no slot loads; then Init (LevelSim.init_game).
static func clear_save_data(banks: Array) -> void:
	for address: int in [S_CHECK_VALS, S_BACKUP_CHECK_VALS, S0A000, S0A800, S0A400, S0AC00]:
		for offset: int in 8:
			banks[0][address - 0xA000 + offset] = 0


# --- for checks and tests ---

## A 32 KiB battery save as SRAM banks 0-3 (empty when it is not 32 KiB).
static func sram_banks(save: PackedByteArray) -> Array:
	if save.size() != 4 * SRAM_SIZE:
		return []
	var banks: Array = []
	for bank: int in 4:
		banks.append(save.slice(bank * SRAM_SIZE, (bank + 1) * SRAM_SIZE))
	return banks


## SRAM banks 0-3 back as one 32 KiB save.
static func save_bytes(banks: Variant) -> PackedByteArray:
	var save := PackedByteArray()
	for bank: int in 4:
		save.append_array(banks[bank])
	return save


## WRAM as Init leaves it for the load: WRAM0 and WRAMX banks 1 to 3 (the banks the load and the
## screens keep) zeroed.
static func cleared_wram() -> Dictionary:
	var ram: Dictionary = {}
	for bank: int in 4:
		ram[bank] = _zeroes(WRAM_BANK_SIZE)
	return ram


static func _zeroes(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	return bytes
