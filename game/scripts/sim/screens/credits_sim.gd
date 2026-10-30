class_name CreditsSim
extends MenuScreenSim
## The credits (CreditsStateTable, 01:4776, farcalling _CreditsStateTable, 58:4000, in GFX RAM;
## src/engine/credits/, WL3-052): after the epilogue's save screen, the fade to white, InitCredits, the
## fade in, ShowCredits (the staff text scrolling up beside the music box, a line written each 8 pixels
## from CreditsText with its letters' palettes from CreditsPalsMap), then the music box: it moves right,
## plays twice, and is shown close up (sub-states 4-6), the screen fades in to the close-up's palettes
## (7), and it stays (8): after a perfect game, a button or 180 loops go to the Perfect screen
## (ST_PERFECT, PerfectSim). The DebugReset entries jump to Init. The music is not ported.

const W_TEMP_BANK: int = 0xC0AC
const W_TEMP_PALS_1: int = 0xC000
const W_TEMP_PALS_2: int = 0xC040
const W_CREDITS_PAGE: int = 0xC084
## The BG map 0 entry the next line goes to (high byte first).
const W_CREDITS_BG_MAP_PTR: int = 0xCCF0
## A line of text up to its $7f, and its letters' palettes (CREDITS_TEXT_LENGTH).
const W_CREDITS_TEXT_BUFFER: int = 0xCE01
const W_CREDITS_TEXT_PALS: int = 0xCE35
## The next line in CreditsText and its palettes in CreditsPalsMap (bank $58, high byte first).
const W_CREDITS_TEXT_PTR: int = 0xCE6A
const W_CREDITS_PALS_MAP_PTR: int = 0xCE6C
const W_TRANSITION_PARAM: int = 0xCEE3
## VBlank_160439's request: bit 7 set for one; the low bits 1 (the text), 2 (the close-up's palettes and
## the window), else the line's attributes and blanks (then the text).
const W_CEE4: int = 0xCEE4
const W_TIMER: int = 0xCEE5
## GFX RAM (WRAMX bank 3): the music box (menu_obj_ext_struct: its state, its OAM table and bank, and
## whether its animation ended) and its winding key (wMenuObj1).
const W_CREDITS_MUSIC_BOX: int = 0xD515
const W_CREDITS_MUSIC_BOX_VAR: int = 0xD51D
const W_CREDITS_MUSIC_BOX_OAM_PTR: int = 0xD51E
const W_CREDITS_MUSIC_BOX_ANIMATION_ENDED: int = 0xD520
const W_CREDITS_MUSIC_BOX_OAM_BANK: int = 0xD521
const W_MENU_OBJ_1: int = 0xD523

const ST_PERFECT: int = 0x0D
const TRANSITION_EPILOGUE_PERFECT: int = 0xF2
const NUM_CREDITS_PAGES: int = 10
const CREDITS_TEXT_LENGTH: int = 13
const TEXT_END: int = 0x7F  # the credits charmap's "\n"
const TILEMAP_WIDTH: int = 32
## InitCredits' first line: BG map 0's (7, 23) (v0BGMap0 + $2e7); each line is a row down.
const CREDITS_BG_MAP_START: int = 0x9AE7
## A blank tile (the credits charmap's " ") the attributes' V-Blank writes under a line.
const BLANK_TILE: int = 0x7E
const LCDC_DEFAULT: int = 0x87  # BG, OBJ, 8x16 OBJ, on
const LCDC_WIN_ON: int = 0x20
const LCDC_WIN_9C00: int = 0x40
const WX_OFS: int = 7
## The bank the table runs in (UpdateObjAnim's framesets by `call`, OAM_1617e8), the close-up's
## ("Credits OAM": Frameset_15e7ed, OAM_15e44a), and their tables.
const CREDITS_BANK: int = 0x58
const CREDITS_OAM_BANK: int = 0x57
const OAM_1617E8: int = 0x57E8
const OAM_15E44A: int = 0x644A
const CREDITS_TEXT: int = 0x5D0F
const CREDITS_PALS_MAP: int = 0x60E5
const FRAMESET_161CAF: int = 0x5CAF
const FRAMESET_161CC4: int = 0x5CC4
const FRAMESET_161CE5: int = 0x5CE5
const FRAMESET_161CE8: int = 0x5CE8
const FRAMESET_161CEB: int = 0x5CEB
const FRAMESET_161CEE: int = 0x5CEE
const FRAMESET_15E7ED: int = 0x67ED
## The palette sets LoadCreditsPals (Pals_1604cc, Pals_16050c), Func_1603be (Pals_16054c,
## Pals_16058c), and Func_1603cb (Pals_1605cc, Pals_16060c) load to wTempPals1 and wTempPals2.
const PALS_1604CC: String = "58:44cc"
const PALS_16050C: String = "58:450c"
const PALS_16054C: String = "58:454c"
const PALS_16058C: String = "58:458c"
const PALS_1605CC: String = "58:45cc"
const PALS_16060C: String = "58:460c"
## VBlank_160439: the scroll, wcee4's request, and the OAM.
const VBLANK_CREDITS: int = 1
## _CreditsStateTable's entries: sub-states 0-8, then DebugReset to $11.
const CREDITS_STATE_TABLE_SIZE: int = 0x12

## wTempBank and wTransitionParam (WRAM0, the screens' shared WRAM0).
var wTempBank: int:
	get:
		return r0(W_TEMP_BANK)
	set(value):
		w0(W_TEMP_BANK, value)
var wTransitionParam: int:
	get:
		return r0(W_TRANSITION_PARAM)
	set(value):
		w0(W_TRANSITION_PARAM, value)
## For drawing: what the last loop's V-Blank wrote to VRAM ([bank, address, value]), and whether it
## applied the temporary palettes and turned the window on (VBlank_160439's request 2).
var vblank_writes: Array = []
var vblank_pals: bool = false


## One game loop: _CreditsStateTable by wSubState, then what VBlank_160439 does before the next.
func update() -> void:
	loops += 1
	screen_loads.clear()
	vblank_writes.clear()
	vblank_pals = false
	match sim.wSubState:
		0, 2:
			fade(0)  # FastFadeToWhite, SlowFadeFromWhite
		1:
			init_credits()
		3:
			show_credits()
		4:
			func_160190()
		5:
			func_16026c()
		6:
			func_1602ee()
		7:
			func_160318()
		8:
			func_160365()
		_:
			if sim.wSubState < CREDITS_STATE_TABLE_SIZE:
				sim.request_init()  # DebugReset: jp Init
			else:
				_note("_CreditsStateTable sub-state %d (past the table)" % sim.wSubState)
			return
	if vblank_func == VBLANK_CREDITS:
		vblank_160439()


## InitCredits: the screen (FillBGMap0_With7f, LoadCreditsGfx, Func_16041f: drawing) with
## LoadCreditsPals' palettes and VBlank_160439, the scroll at (0, 4), the first page, the text's and
## its palettes' pointers at their starts, the music box at (91, 24) on Frameset_161cc4 (OAM_1617e8)
## and its winding key there on Frameset_161caf, each animated and drawn; the music stopped (not
## ported), 120 loops before it starts (wTimer), and LCDC_DEFAULT with the window at (0, 0).
func init_credits() -> void:
	clear_virtual_oam()
	_load_pals(PALS_1604CC, PALS_16050C)  # LoadCreditsPals
	screen_loads.append(["credits"])
	vblank_func = VBLANK_CREDITS
	sim.wSCX = 4
	sim.wSCY = 0
	w0(W_CREDITS_PAGE, 0)
	w0(W_CEE4, 0)
	_set_word(W_CREDITS_BG_MAP_PTR, CREDITS_BG_MAP_START)
	_set_word(W_CREDITS_TEXT_PTR, CREDITS_TEXT)
	_set_word(W_CREDITS_PALS_MAP_PTR, CREDITS_PALS_MAP)
	_set_up_music_box(0x5B, 0x18, FRAMESET_161CC4)
	w3(W_CREDITS_MUSIC_BOX_VAR, 0)
	update_obj_anim(W_CREDITS_MUSIC_BOX, CREDITS_BANK)
	load_credits_sprite(W_CREDITS_MUSIC_BOX)
	set_up_obj(W_MENU_OBJ_1, 0x5B, 0x18, FRAMESET_161CAF)
	update_obj_anim(W_MENU_OBJ_1, CREDITS_BANK)
	load_credits_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	w0(W_TIMER, 120)
	sim.wSubState = byte(sim.wSubState + 1)


## ShowCredits: while wTimer counts down to the music (PlayCreditsMusic at 0, not ported), the
## music box and the key are drawn still. Then both animate, and the screen scrolls a line a loop on
## the first and last pages and every other loop between; wCreditsPage counts wSCY's wraps. On pages
## 1 to 9 each 8 lines the next line of CreditsText (to its $7f) goes to the buffer, its 13 palettes
## from CreditsPalsMap, the BG map pointer a row on (wrapping within BG map 0), and V-Blank is asked
## to write them (wcee4 $80). At page 10 the music box's state is cleared and the next sub-state.
func show_credits() -> void:
	if r0(W_TIMER) != 0:
		w0(W_TIMER, r0(W_TIMER) - 1)
		load_credits_sprite(W_CREDITS_MUSIC_BOX)
		load_credits_sprite(W_MENU_OBJ_1)
		clear_unused_virtual_oam()
		return
	update_obj_anim(W_CREDITS_MUSIC_BOX, CREDITS_BANK)
	load_credits_sprite(W_CREDITS_MUSIC_BOX)
	update_obj_anim(W_MENU_OBJ_1, CREDITS_BANK)
	load_credits_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	var page: int = r0(W_CREDITS_PAGE)
	if page == NUM_CREDITS_PAGES:
		w3(W_CREDITS_MUSIC_BOX_VAR, 0)
		sim.wSubState = byte(sim.wSubState + 1)
		return
	if page != 0 and page != NUM_CREDITS_PAGES - 1 and (sim.wGlobalCounter & 1) != 0:
		return
	# .scroll: wSCY and wCreditsPage as a 16-bit count (add 1, adc 0).
	var scy: int = sim.wSCY + 1
	sim.wSCY = byte(scy)
	page = byte(page + (scy >> 8))
	w0(W_CREDITS_PAGE, page)
	if page < 1 or page >= NUM_CREDITS_PAGES or (sim.wSCY & 0b111) != 0:
		return
	var text: int = _word(W_CREDITS_TEXT_PTR)
	var buffer: int = W_CREDITS_TEXT_BUFFER
	while true:
		var value: int = _rom_58(text)
		text = (text + 1) & 0xFFFF
		w0(buffer, value)
		buffer = (buffer & 0xFF00) | ((buffer + 1) & 0xFF)  # inc e
		if value == TEXT_END:
			break
	_set_word(W_CREDITS_TEXT_PTR, text)
	var pals: int = _word(W_CREDITS_PALS_MAP_PTR)
	for index: int in CREDITS_TEXT_LENGTH:
		w0(W_CREDITS_TEXT_PALS + index, _rom_58(pals + index))
	_set_word(W_CREDITS_PALS_MAP_PTR, pals + CREDITS_TEXT_LENGTH)
	var bg_map: int = _word(W_CREDITS_BG_MAP_PTR) + TILEMAP_WIDTH
	_set_word(W_CREDITS_BG_MAP_PTR, bg_map & 0xFBFF)  # `and $fb` on the high byte: back to $98 from $9c
	w0(W_CEE4, 0x80)


## Func_160190: the music box (and the key with it) moves right a pixel a loop to x $38, then every
## other loop to $50, where it stops (wCreditsMusicBoxVar 1). Stopped, on even loops each end of its
## animation counts: at 3 it plays again (Frameset_161cee) with the key turning every 4 loops, at 4
## the close-up starts. The music box animates in its OAM bank; the key, unless skipped, in bank $58;
## odd loops while slow or stopped animate neither. LoadCreditsMusicBoxSprite draws the music box.
func func_160190() -> void:
	var update_anims: bool = true
	var music_box_x: int = W_CREDITS_MUSIC_BOX + OBJ_X
	var stopped: bool = r3(W_CREDITS_MUSIC_BOX_VAR) != 0
	if not stopped:
		var x: int = r3(music_box_x)
		if x >= 0x50:
			w3(W_CREDITS_MUSIC_BOX_VAR, 1)
			stopped = true
		elif x < 0x38 or (sim.wGlobalCounter & 1) == 0:
			w3(music_box_x, x + 1)
			w3(W_MENU_OBJ_1 + OBJ_X, r3(W_MENU_OBJ_1 + OBJ_X) + 1)
		else:
			update_anims = false  # .move_right_slow on an odd loop
	if stopped:
		if (sim.wGlobalCounter & 1) != 0:
			update_anims = false
		elif r3(W_CREDITS_MUSIC_BOX_ANIMATION_ENDED) != 0:
			w3(W_CREDITS_MUSIC_BOX_ANIMATION_ENDED, 0)
			var count: int = byte(r3(W_CREDITS_MUSIC_BOX_VAR) + 1)
			w3(W_CREDITS_MUSIC_BOX_VAR, count)
			if count == 4:
				_start_close_up()
			elif count >= 3:
				# the music box plays again
				w3(W_CREDITS_MUSIC_BOX + OBJ_FRAMESET_OFFSET, 0)
				w3(W_CREDITS_MUSIC_BOX + OBJ_DURATION, 0)
				_set_frameset(W_CREDITS_MUSIC_BOX, FRAMESET_161CEE)
	if update_anims:
		_update_music_box_anim()
		w3(W_CREDITS_MUSIC_BOX_ANIMATION_ENDED, r3(W_OBJ_ANIM_WAS_RESET))
		if r3(W_CREDITS_MUSIC_BOX_VAR) != 3 or (sim.wGlobalCounter & 0b11) == 0:
			update_obj_anim(W_MENU_OBJ_1, CREDITS_BANK)  # .update_winding_key
	load_credits_music_box_sprite(W_CREDITS_MUSIC_BOX)
	load_credits_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()


## Func_160190.start_close_up: the music box at (91, 80) on Frameset_161ce8 (OAM_1617e8), its state
## cleared; the key off the screen's bottom (y $e0, x $4e) on Frameset_161ce5; 16 loops (wTimer); and
## the next sub-state (the loop goes on to .update_anims).
func _start_close_up() -> void:
	_set_up_music_box(0x5B, 0x50, FRAMESET_161CE8)
	w3(W_CREDITS_MUSIC_BOX_VAR, 0)
	set_up_obj(W_MENU_OBJ_1, 0xE0, 0x4E, FRAMESET_161CE5)
	w0(W_TIMER, 16)
	sim.wSubState = byte(sim.wSubState + 1)


## Func_16026c: wTimer counts down; at 6 the music box takes Frameset_161ceb; at 0 the close-up: the
## music box at (80, 80) on Frameset_15e7ed with OAM_15e44a (bank $57), Func_1603be's palettes, and
## V-Blank asked to apply them and turn the window on (wcee4 $82). Only the music box is drawn.
func func_16026c() -> void:
	var timer: int = byte(r0(W_TIMER) - 1)
	w0(W_TIMER, timer)
	if timer == 0:
		set_up_obj(W_CREDITS_MUSIC_BOX, 0x50, 0x50, FRAMESET_15E7ED)
		_set_music_box_oam(CREDITS_OAM_BANK, OAM_15E44A)
		_load_pals(PALS_16054C, PALS_16058C)  # Func_1603be
		w0(W_CEE4, 0x82)
		sim.wSubState = byte(sim.wSubState + 1)
		_update_music_box_anim()
	elif timer == 6:
		_set_up_music_box(0x5B, 0x50, FRAMESET_161CEB)
		_update_music_box_anim()
	load_credits_music_box_sprite(W_CREDITS_MUSIC_BOX)
	clear_unused_virtual_oam()


## Func_1602ee: the music box animated and drawn, Func_1603cb's palettes loaded (the fade's target),
## and the next sub-state.
func func_1602ee() -> void:
	_update_music_box_anim()
	load_credits_music_box_sprite(W_CREDITS_MUSIC_BOX)
	clear_unused_virtual_oam()
	_load_pals(PALS_1605CC, PALS_16060C)  # Func_1603cb
	sim.wSubState = byte(sim.wSubState + 1)


## Func_160318: the music box animated and drawn; the key rises a line every other loop to y $80,
## animated and drawn; every 16 loops a step of SlowFadeInScreen (which ends on the next sub-state)
## and wTimer at 180.
func func_160318() -> void:
	_update_music_box_anim()
	load_credits_music_box_sprite(W_CREDITS_MUSIC_BOX)
	var key_y: int = r3(W_MENU_OBJ_1 + OBJ_Y)
	if key_y != 0x80 and (sim.wGlobalCounter & 1) == 0:
		w3(W_MENU_OBJ_1 + OBJ_Y, key_y - 1)
	update_obj_anim(W_MENU_OBJ_1, CREDITS_BANK)
	load_credits_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	if (sim.wGlobalCounter & 0b1111) != 0:
		return
	slow_fade_in_screen()
	w0(W_TIMER, 180)


## Func_160365: the music box animated and drawn, the key rising a line a loop to y $80, animated and
## drawn. After a perfect game (TRANSITION_EPILOGUE_PERFECT) a button pressed or wTimer's 180 loops
## go to the Perfect screen (SetPerfectState); otherwise this goes on.
func func_160365() -> void:
	_update_music_box_anim()
	load_credits_music_box_sprite(W_CREDITS_MUSIC_BOX)
	var key_y: int = r3(W_MENU_OBJ_1 + OBJ_Y)
	if key_y != 0x80:
		w3(W_MENU_OBJ_1 + OBJ_Y, key_y - 1)
	update_obj_anim(W_MENU_OBJ_1, CREDITS_BANK)
	load_credits_sprite(W_MENU_OBJ_1)
	clear_unused_virtual_oam()
	if wTransitionParam != TRANSITION_EPILOGUE_PERFECT:
		return
	if sim.wJoypadPressed != 0:
		_set_perfect_state()
		return
	w0(W_TIMER, r0(W_TIMER) - 1)
	if r0(W_TIMER) == 0:
		_set_perfect_state()


## SetPerfectState (src/home/update_level_music.asm).
func _set_perfect_state() -> void:
	sim.wState = ST_PERFECT
	sim.wSubState = 0


## VBlank_160439's work after the loop (its scroll and OAM DMA are the drawing's): with wcee4's bit 7,
## request 1 writes the buffer's text to the BG map pointer (to its $7f, the pointer's low byte
## wrapping) and clears bit 7; request 2 applies wTempPals1 and 2 to the BG and OBJ palettes and turns
## the window on from BG map 1 (drawing), clearing bit 7; any other writes the line's palettes to
## VRAM 1 and blanks ($7e) to VRAM 0 there, and asks for the text next (wcee4 $81).
func vblank_160439() -> void:
	var request: int = r0(W_CEE4)
	if (request & 0x80) == 0:
		return
	var bg_map: int = _word(W_CREDITS_BG_MAP_PTR)
	match request & 0x7F:
		1:
			var buffer: int = W_CREDITS_TEXT_BUFFER
			var address: int = bg_map
			while r0(buffer) != TEXT_END:
				if buffer == 0xCFFF:
					_note("VBlank_160439: no $7f in wCreditsTextBuffer")
					break
				vblank_writes.append([0, address, r0(buffer)])
				buffer += 1
				address = (address & 0xFF00) | ((address + 1) & 0xFF)  # inc e
			w0(W_CEE4, request & 0x7F)
		2:
			vblank_pals = true
			w0(W_CEE4, request & 0x7F)
		_:
			for index: int in CREDITS_TEXT_LENGTH:
				vblank_writes.append([1, (bg_map + index) & 0xFFFF, r0(W_CREDITS_TEXT_PALS + index)])
			for index: int in CREDITS_TEXT_LENGTH:
				vblank_writes.append([0, (bg_map + index) & 0xFFFF, BLANK_TILE])
			w0(W_CEE4, 0x81)


# --- the sprites ---

## LoadCreditsSprite: an object's frame of OAM_1617e8 at its position (no scroll).
func load_credits_sprite(obj: int) -> void:
	_load_credits_obj("%02x:%04x" % [CREDITS_BANK, OAM_1617E8], obj)


## LoadCreditsMusicBoxSprite (src/home/load_credits_sprite.asm): the music box's frame of the OAM table
## wCreditsMusicBoxOAMPtr names, in wCreditsMusicBoxOAMBank (wTempBank).
func load_credits_music_box_sprite(obj: int) -> void:
	wTempBank = r3(W_CREDITS_MUSIC_BOX_OAM_BANK)
	var table: int = (r3(W_CREDITS_MUSIC_BOX_OAM_PTR) << 8) | r3(W_CREDITS_MUSIC_BOX_OAM_PTR + 1)
	_load_credits_obj("%02x:%04x" % [wTempBank, table], obj)


func _load_credits_obj(table: String, obj: int) -> void:
	load_sprite(table, r3(obj + OBJ_FRAME), byte(r3(obj + OBJ_Y) + OAM_Y_OFS), byte(r3(obj + OBJ_X) + OAM_X_OFS),
			r3(obj + OBJ_ATTRIBUTES))


## The music box's UpdateObjAnim (hcall) in its OAM bank, which wTempBank takes.
func _update_music_box_anim() -> void:
	wTempBank = r3(W_CREDITS_MUSIC_BOX_OAM_BANK)
	update_obj_anim(W_CREDITS_MUSIC_BOX, wTempBank)


## The music box at (y, x) with `frameset` and OAM_1617e8 in bank $58 (its state is the caller's).
func _set_up_music_box(y: int, x: int, frameset: int) -> void:
	set_up_obj(W_CREDITS_MUSIC_BOX, y, x, frameset)
	_set_music_box_oam(CREDITS_BANK, OAM_1617E8)


func _set_music_box_oam(bank: int, table: int) -> void:
	_set_word_3(W_CREDITS_MUSIC_BOX_OAM_PTR, table)
	w3(W_CREDITS_MUSIC_BOX_OAM_BANK, bank)


# --- helpers ---

## A byte of bank $58 from the extracted tables (CreditsText and CreditsPalsMap, one after the other).
func _rom_58(address: int) -> int:
	if address >= CREDITS_TEXT and address < CREDITS_PALS_MAP:
		return _table("CreditsText", address - CREDITS_TEXT)
	return _table("CreditsPalsMap", address - CREDITS_PALS_MAP)


## A pointer in WRAM0 as the credits keep them, high byte first.
func _word(address: int) -> int:
	return (r0(address) << 8) | r0(address + 1)


func _set_word(address: int, value: int) -> void:
	w0(address, value >> 8)
	w0(address + 1, value)


func _set_word_3(address: int, value: int) -> void:
	w3(address, value >> 8)
	w3(address + 1, value)


## LoadPalsToTempPals1 and 2: two palette sets' $40 bytes each from credits.json.
func _load_pals(pals_1: String, pals_2: String) -> void:
	for pair: Array in [[pals_1, W_TEMP_PALS_1], [pals_2, W_TEMP_PALS_2]]:
		var pals: PackedByteArray = String(document.get("gfx", {}).get("palettes", {}).get(pair[0], "")).hex_decode()
		if pals.size() != 0x40:
			_note("palettes %s not extracted" % pair[0])
			continue
		for offset: int in 0x40:
			w0(int(pair[1]) + offset, pals[offset])
