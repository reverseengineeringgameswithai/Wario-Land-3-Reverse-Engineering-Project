class_name OverworldPalettes
extends OverworldAnimations
## The map's palette fades (src/engine/overworld/bank21.asm), translated (WL3-052): DayNightTransition
## (the side's BG palettes faded through OWPals' steps in the colour-fade structs wFadePals, applied to
## wTempBGPals, which VBlank_OWPalTransition shows; B or a d-pad way skips it), FadeInLevelName and
## Func_852e5 (the level name's palette 7 faded in and out through wPalConfig1 by FadePalConfig).

const W_OW_PAL_TRANSITION_COUNTER: int = 0xD056
const W_PAL_CONFIG_1_INDEX: int = 0xD0D1
const W_PAL_CONFIG_1_NUMBER: int = 0xD0D2
const W_PAL_CONFIG_1_SOURCE_HI: int = 0xD0D3  # high byte, then low
const W_PAL_CONFIG_1_TOTAL_STEPS: int = 0xD0D5
const W_PAL_CONFIG_2_TOTAL_STEPS: int = 0xD0DB
const W_PAL_CONFIG_2_NUMBER: int = 0xD0D8
const W_PAL_CONFIG_TO_FADE: int = 0xD0DC
const W_PAL_FADE_REPEAT: int = 0xD0DD
const W_CUR_PAL_TOTAL_STEPS: int = 0xD0E1
const W2D0E3: int = 0xD0E3
const W_OW_ALLOWED_D_PAD_INPUT: int = 0xD10B
const W2D0E4: int = 0xD0E4
const W_COLOUR_FADE_DIFF: int = 0xD802
const W_COLOUR_FADE_ACCUMULATOR: int = 0xD803
const W_DAY_NIGHT_TRANSISTION_STEPS: int = 0xD806  # the label's spelling
const W2D807: int = 0xD807
const W_COLOUR_FADE_STEP: int = 0xD808
const W2D809: int = 0xD809
## wFadePals: a colour_fade_struct (base, target, sign, diff, accumulator, current, 2 unused) for each
## red, green, and blue of the 8 palettes' 4 colours, 8 bytes apart.
const W_FADE_PALS: int = 0xD810
const COLOURFADESTRUCT_LENGTH: int = 8
const W_TARGET_RGB: int = 0xC180  # red, green, blue (WRAM0, not traced)
const W_CUR_RGB: int = 0xC183
const OW_PALS: int = 0x4DD9  # bank $21: 4 palette pointers by map side (6 with all crayons), day or night
const PALS_840C0: int = 0x40C0
const PALS_852DD: int = 0x52DD
const DAYNIGHT_TRANSITION_STEPS: int = 32
const NUM_COLOUR_FADE_STRUCTS: int = 8 * 4 * 3
const SST_OVERWORLD_0B: int = 0x0B
const PAD_B: int = 0x02
const OBPI_PALETTE_7: int = 0x80 | 0x38  # OBPI_AUTOINC | palette 7
## The V-Blank function of the day and night transition (VBlank_OWPalTransition): it writes no RAM.
const VBLANK_OW_PAL_TRANSITION: int = 2


## VBlank_OWPalTransition's function, run after the loop (V-Blank) of the day and night and the grey
## transitions: the scroll and the window (wWX + 7, wWY), Func_1d8c2c's DMAs, wTempBGPals to the BG
## palettes, the OAM. It writes no RAM.
func vblank_ow_pal_transition() -> void:
	set_window(r2(W_WX) + 7, r2(W_WY))
	record_func_1d8c2c()
	var bytes := PackedByteArray()
	for offset: int in 8 * 8:
		bytes.append(r0(W_TEMP_BG_PALS + offset))
	palette_writes.append(["palettes", false, 0x80, bytes])  # BGPI_AUTOINC | palette 0


# --- the day and night transition ---

## DayNightTransition: wOWPalTransitionCounter counts; by wOWPalTransitionState, day to night (the
## side's palettes 0 to 3 of OWPals faded in three legs, then the switch) or night to day (two legs).
func day_night_transition() -> void:
	w2(W_OW_PAL_TRANSITION_COUNTER, r2(W_OW_PAL_TRANSITION_COUNTER) + 1)
	var state: int = r2(W_OW_PAL_TRANSITION_STATE)
	if r2(W2D011) == 0:
		match state:
			0:  # .InitDayToNight
				_load_base_and_target_pals()
				w2(W2D07C, 0x01)
				w2(W2D07D, 0)
				w2(W2D809, 0)
			1, 5:
				_fade_colours()
			2:  # .LoadPal1_Day
				_load_pal(1)
			3:  # .FadePal1ToPal2_Day
				_fade_colours()
				if r2(W_DAY_NIGHT_TRANSISTION_STEPS) == 12:
					w2(W2D809, 0)
			4:  # .LoadPal2
				_load_pal(2)
			6:
				_switch_day_night()
			_:
				_note("DayNightTransition state %d (past its table)" % state)
	else:
		match state:
			0:  # .InitNightToDay
				_load_base_and_target_pals()
				w2(W2D07C, 0)
				w2(W2D07D, 0)
				w2(W2D809, 0)
			1:  # .FadeDayToPal1
				_fade_colours()
				if r2(W_DAY_NIGHT_TRANSISTION_STEPS) == 10:
					w2(W2D809, 0)
			2:  # .LoadPal1_Night
				_load_pal(1)
			3:  # .FadePal1ToPal2_Night
				_fade_colours()
				if r2(W_DAY_NIGHT_TRANSISTION_STEPS) == 0x16:
					w2(W2D809, 0)
			4:
				_switch_day_night()
			_:
				_note("DayNightTransition night state %d (past its table)" % state)


## .LoadBaseAndTargetPals: VBlank_OWPalTransition set, the transition's last palettes (OWPals' 4th)
## to wTempPals1, the first leg's (LoadBaseAndTargetOWPals 0), the next state.
func _load_base_and_target_pals() -> void:
	vblank_func = VBLANK_OW_PAL_TRANSITION
	copy_rom(MAP_PALS_BANK, rw(MAP_PALS_BANK, get_ow_pals(3)), W_TEMP_PALS_1, 8 * 8)
	load_base_and_target_ow_pals(0)
	_advance_transition()


## .AdvanceTable: the counter cleared, the next state.
func _advance_transition() -> void:
	w2(W_OW_PAL_TRANSITION_COUNTER, 0)
	w2(W_OW_PAL_TRANSITION_STATE, r2(W_OW_PAL_TRANSITION_STATE) + 1)


## .LoadPal1, .LoadPal2: the leg `leg`'s palettes, the next state.
func _load_pal(leg: int) -> void:
	load_base_and_target_ow_pals(leg)
	_advance_transition()


## .FadeColours: on the map's loop B, or a d-pad way Wario may go, skips the transition; otherwise,
## each time the counter reaches w2d809, every colour fade struct's accumulator takes its diff and at
## 32 its current value steps toward the target; the colours to wTempBGPals; after 32 steps, the next
## state.
func _fade_colours() -> void:
	if sim.wSubState == SST_OVERWORLD_0B:
		var pressed: int = sim.wJoypadPressed
		if (pressed & PAD_B) != 0 or (r2(W_OW_ALLOWED_D_PAD_INPUT) & pressed) != 0:
			skip_day_night_transition()
			return
	if r2(W_OW_PAL_TRANSITION_COUNTER) < r2(W2D809):
		return
	w2(W_OW_PAL_TRANSITION_COUNTER, 0)
	w2(W2D807, NUM_COLOUR_FADE_STRUCTS)
	for index: int in NUM_COLOUR_FADE_STRUCTS:
		var at: int = W_FADE_PALS + index * COLOURFADESTRUCT_LENGTH
		var sign: int = r2(at + 2)
		if sign != 0:
			if sign != 1 and sign != 2:
				_note("DayNightTransition.FadeColours sign %d (debug_nop: hangs)" % sign)
				return
			var step: int = 1 if sign == 1 else 0xFF
			w2(W_COLOUR_FADE_STEP, step)
			w2(W_COLOUR_FADE_DIFF, r2(at + 3))
			w2(W_COLOUR_FADE_ACCUMULATOR, r2(at + 4))
			var sum: int = byte(r2(at + 4) + r2(at + 3))
			if sum < DAYNIGHT_TRANSITION_STEPS:
				w2(at + 4, sum)
			else:
				w2(at + 4, sum - DAYNIGHT_TRANSITION_STEPS)
				w2(at + 5, r2(at + 5) + step)
		w2(W2D807, r2(W2D807) - 1)
	apply_pal_fade_colours()
	w2(W_DAY_NIGHT_TRANSISTION_STEPS, r2(W_DAY_NIGHT_TRANSISTION_STEPS) - 1)
	if r2(W_DAY_NIGHT_TRANSISTION_STEPS) == 0:
		_advance_transition()


## .SwitchDayNight: day and night switched (w2d011, wDayNight bit 0, bit 7 cleared; the music, not
## ported), the transition over.
func _switch_day_night() -> void:
	w2(W2D011, r2(W2D011) ^ 1)
	w0(W_DAY_NIGHT, ((r0(W_DAY_NIGHT) & 0xFE) | (r2(W2D011) & 1)) & ~0x80)
	w2(W2D0E3, 0)
	w2(W_OW_PAL_TRANSITION_STATE, 0)
	w2(W_OW_PAL_TRANSITION_COUNTER, 0)


## SkipDayNightTransition: the target palettes (wTempPals1) shown at once, and the switch next.
func skip_day_night_transition() -> void:
	for offset: int in 8 * 8:
		w0(W_TEMP_BG_PALS + offset, r0(W_TEMP_PALS_1 + offset))
	w2(W_DAY_NIGHT_TRANSISTION_STEPS, 0)
	w2(W_OW_PAL_TRANSITION_COUNTER, 0)
	w2(W_OW_PAL_TRANSITION_STATE, 0x04 if r2(W2D011) != 0 else 0x06)


## GetOWPals: the address in OWPals of the side's (all crayons: North's and West's other) day or night
## pair `leg` (palettes from, to).
func get_ow_pals(leg: int) -> int:
	var side: int = r2(W_CUR_MAP_SIDE)
	if (r2(W_CRAYON_FLAGS) & ALL_CRAYONS) == ALL_CRAYONS:
		if side == NORTH:
			side = 4
		elif side == WEST:
			side = 5
	var night: int = swap(r2(W2D011))
	night = ((night >> 1) | (night << 7)) & 0xFF  # rrca
	return OW_PALS + (night | swap(side) | ((leg * 2) & 0xFF))


## LoadBaseAndTargetOWPals: leg `leg`'s target and base palettes into wFadePals, the structs set up,
## the base to wTempBGPals; 32 steps.
func load_base_and_target_ow_pals(leg: int) -> void:
	var at: int = get_ow_pals(leg)
	var base: int = rw(MAP_PALS_BANK, at)
	copy_pal_to_colour_fade_structs(rw(MAP_PALS_BANK, at + 2), W_FADE_PALS + 1)
	copy_pal_to_colour_fade_structs(base, W_FADE_PALS + 0)
	init_colour_fade_structs()
	copy_rom(MAP_PALS_BANK, base, W_TEMP_BG_PALS, 8 * 8)
	w2(W_DAY_NIGHT_TRANSISTION_STEPS, DAYNIGHT_TRANSITION_STEPS)
	w2(W2D809, 0)


## CopyPalToColourFadeStructs: the 32 colours at (bank $21, `source`) split into red, green, and blue
## at `destination` (each 8 bytes on).
func copy_pal_to_colour_fade_structs(source: int, destination: int) -> void:
	w2(W2D807, 8 * 4)
	var at: int = destination
	for colour: int in 8 * 4:
		var low: int = rb(MAP_PALS_BANK, source + colour * 2)
		var high: int = rb(MAP_PALS_BANK, source + colour * 2 + 1)
		w2(at, low & 0x1F)
		w2(at + COLOURFADESTRUCT_LENGTH, ((low >> 5) | (high << 3)) & 0x1F)
		w2(at + 2 * COLOURFADESTRUCT_LENGTH, (high >> 2) & 0x1F)
		at += 3 * COLOURFADESTRUCT_LENGTH
		w2(W2D807, r2(W2D807) - 1)


## InitColourFadeStructs: each struct's sign (1 up, 2 down, 0 equal), diff, accumulator (the diff),
## and current colour (the base).
func init_colour_fade_structs() -> void:
	w2(W2D807, NUM_COLOUR_FADE_STRUCTS)
	for index: int in NUM_COLOUR_FADE_STRUCTS:
		var at: int = W_FADE_PALS + index * COLOURFADESTRUCT_LENGTH
		var base: int = r2(at)
		var target: int = r2(at + 1)
		var sign: int = 0
		var diff: int = 0
		if target > base:
			sign = 1
			diff = target - base
		elif target < base:
			sign = 2
			diff = base - target
		w2(at + 2, sign)
		w2(at + 3, diff)
		w2(at + 4, diff)
		w2(at + 5, base)
		w2(W2D807, r2(W2D807) - 1)


## ApplyPalFadeColours: the structs' current colours to wTempBGPals.
func apply_pal_fade_colours() -> void:
	w2(W2D807, 8 * 4)
	for colour: int in 8 * 4:
		var at: int = W_FADE_PALS + 5 + colour * 3 * COLOURFADESTRUCT_LENGTH
		var red: int = r2(at)
		var green: int = r2(at + COLOURFADESTRUCT_LENGTH)
		var blue: int = r2(at + 2 * COLOURFADESTRUCT_LENGTH)
		w0(W_TEMP_BG_PALS + colour * 2, ((green << 5) & 0xE0) | red)
		w0(W_TEMP_BG_PALS + colour * 2 + 1, ((blue << 2) | ((green >> 3) & 0x03)) & 0x7F)
		w2(W2D807, r2(W2D807) - 1)


# --- the level name's palette ---

## FadeInLevelName: its first loop: the name shown fading in (w2d0e0 2): palette 7 kept in
## wTempBGPals and its target in wTempPals1 (white by day, yellow at night; blue with w2d0e4) through
## wPalConfig1; then FadeBGPalConfig until done (w2d0e0 1). True (carry) until done.
func fade_in_level_name() -> bool:
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 1:
		w2(W2D0E0, 0x02)
		for offset: int in 8:
			w0(W_TEMP_BG_PALS + 7 * 8 + offset, r0(W_TEMP_PALS_1 + 7 * 8 + offset))
		if r2(W2D0E4) != 0:
			copy_rom(MAP_PALS_BANK, PALS_852DD + 2, W_TEMP_PALS_1 + 7 * 8 + 2, 6)
		else:
			copy_rom(MAP_PALS_BANK, (PALS_840C0 if r2(W2D011) != 0 else PALS_84000) + 7 * 8, W_TEMP_PALS_1 + 7 * 8,
					8)
		_set_name_pal_config()
		return true
	if fade_bg_pal_config():
		return true
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W2D0E0, 0x01)
	return false


## wPalConfig1 for the name's palette (wTempBGPals palette 7, one palette), its steps started.
func _set_name_pal_config() -> void:
	w2(W_PAL_CONFIG_1_SOURCE_HI, (W_TEMP_BG_PALS + 7 * 8) >> 8)
	w2(W_PAL_CONFIG_1_SOURCE_HI + 1, (W_TEMP_BG_PALS + 7 * 8) & 0xFF)
	w2(W_PAL_CONFIG_1_INDEX, OBPI_PALETTE_7)
	w2(W_PAL_CONFIG_1_NUMBER, 1)
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)


## Func_852e5: with w2d0e0 3 and the bottom bar closed, the name faded out: palette 7's colours 1 to 3
## kept in wTempBGPals and cleared in wTempPals1, then FadeBGPalConfig until done (w2d0e0 0).
func func_852e5() -> void:
	if r2(W2D0E0) != 0x03 or r2(W_BOTTOM_BAR_ACTION) != 0:
		return
	if r2(W_PAL_CONFIG_1_TOTAL_STEPS) < 1:
		for offset: int in 6:
			w0(W_TEMP_BG_PALS + 7 * 8 + 2 + offset, r0(W_TEMP_PALS_1 + 7 * 8 + 2 + offset))
		fill(W_TEMP_PALS_1 + 7 * 8 + 2, 6, 0)
		w2(W_PAL_CONFIG_1_TOTAL_STEPS, r2(W_PAL_CONFIG_1_TOTAL_STEPS) + 1)
		w2(W_PAL_CONFIG_1_SOURCE_HI, (W_TEMP_BG_PALS + 7 * 8) >> 8)
		w2(W_PAL_CONFIG_1_SOURCE_HI + 1, (W_TEMP_BG_PALS + 7 * 8) & 0xFF)
		w2(W_PAL_CONFIG_1_INDEX, OBPI_PALETTE_7)
		w2(W_PAL_CONFIG_1_NUMBER, 1)
		return
	if fade_bg_pal_config():
		return
	w2(W_PAL_CONFIG_1_TOTAL_STEPS, 0)
	w2(W2D0E0, 0)


## FadeBGPalConfig: wPalConfig1 faded on the BG palettes (rBGPI), 4 steps a loop (1 during a scene).
func fade_bg_pal_config() -> bool:
	w2(W_PAL_CONFIG_1, LOW_R_BGPI)
	w2(W_PAL_CONFIG_TO_FADE, 0)
	w2(W_PAL_FADE_REPEAT, 4 if r2(W_CUR_EVENT) == 0 else 1)
	return fade_pal_config(W_PAL_CONFIG_1_TOTAL_STEPS)


## Func_851bc: wPalConfig1 faded a step on the BG palettes (rBGPI). True (carry) below $20 steps.
func fade_bg_pal_config_slowly() -> bool:
	w2(W_PAL_CONFIG_1, LOW_R_BGPI)
	w2(W_PAL_CONFIG_TO_FADE, 0)
	w2(W_PAL_FADE_REPEAT, 1)
	return fade_pal_config(W_PAL_CONFIG_1_TOTAL_STEPS)


## Func_851d1: wPalConfig2 faded a step on the OB palettes (rOBPI). True (carry) below $20 steps.
func fade_ob_pal_config_slowly() -> bool:
	w2(W_PAL_CONFIG_2, LOW_R_OBPI)
	w2(W_PAL_CONFIG_TO_FADE, 1)
	w2(W_PAL_FADE_REPEAT, 1)
	return fade_pal_config(W_PAL_CONFIG_2_TOTAL_STEPS)


## FadePalConfig: wPalFadeRepeat steps of the config's palettes (from its source, in wTempBGPals or
## wTempOBPals) each colour a step toward the same colour $100 before (wTempPals1, wTempPals2); the
## steps counted in wCurPalTotalSteps and then at `steps_at`. True (carry) below $20 steps.
func fade_pal_config(steps_at: int) -> bool:
	w2(W_CUR_PAL_TOTAL_STEPS, rd(steps_at))
	while true:
		var config: int = W_PAL_CONFIG_1_NUMBER if r2(W_PAL_CONFIG_TO_FADE) == 0 else W_PAL_CONFIG_2_NUMBER
		var colours: int = ((r2(config) << 2) | (r2(config) >> 6)) & 0xFF  # rlca twice
		var target_page: int = (r2(config + 1) - 1) & 0xFF
		var e: int = r2(config + 2)
		for count: int in (colours if colours != 0 else 0x100):
			_fade_colour_step((target_page << 8) | e, 0xC100 | e, 0xC100 | ((e + 1) & 0xFF),
					(target_page << 8) | ((e + 1) & 0xFF))
			e = (e + 2) & 0xFF
			target_page = W_TEMP_PALS_1 >> 8
		w2(W_CUR_PAL_TOTAL_STEPS, r2(W_CUR_PAL_TOTAL_STEPS) + 1)
		w2(W_PAL_FADE_REPEAT, r2(W_PAL_FADE_REPEAT) - 1)
		if r2(W_PAL_FADE_REPEAT) == 0:
			break
	wr(steps_at, r2(W_CUR_PAL_TOTAL_STEPS))
	return r2(W_CUR_PAL_TOTAL_STEPS) < 0x20


## One colour of FadePalConfig: the target (wTargetRGB) and current (wCurRGB) colours split, each of
## blue, green, red a step toward the target, the current written back.
func _fade_colour_step(target_low: int, current_low: int, current_high: int, target_high: int) -> void:
	var rgb: Array = []
	for pair: Array in [[target_low, target_high], [current_low, current_high]]:
		var low: int = rd(pair[0])
		var high: int = rd(pair[1])
		rgb.append_array([low & 0x1F, ((low & 0xE0) >> 5) | ((high & 0x03) << 3), (high & 0x7C) >> 2])
	for index: int in 3:
		w0(W_TARGET_RGB + index, rgb[index])
	for index: int in [2, 1, 0]:  # blue, green, red
		if rgb[3 + index] < rgb[index]:
			rgb[3 + index] += 1
		elif rgb[3 + index] > rgb[index]:
			rgb[3 + index] -= 1
	for index: int in 3:
		w0(W_CUR_RGB + index, rgb[3 + index])
	wr(current_low, (((rgb[4] & 0x07) << 5) | rgb[3]) & 0xFF)
	wr(current_high, (((rgb[4] & 0x18) >> 3) | (rgb[5] << 2)) & 0xFF)
