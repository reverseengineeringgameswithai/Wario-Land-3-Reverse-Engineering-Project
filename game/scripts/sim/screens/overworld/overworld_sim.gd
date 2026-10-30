class_name OverworldSim
extends OverworldEpilogue
## The map (OverworldStateTable, src/engine/overworld/state_table.asm), ported by translation as far
## as the owner's movies reach it (WL3-052): what follows a level (its fade, InitOverworld), an event's
## cutscene ($11 to $15) and scenes (their fades, InitOWScene, and their loop Func_80540), the map
## side's fades, its set-up (InitMapSide), and its loop (Func_805d7) with its bars, the treasure
## collection ($0C to $0F) and Time Attack's best times ($16 to $19, OverworldCollection), the Temple's
## scene ($1A to $1D, OverworldTemple), the Golf Building ($1E to $22), the epilogue ($23 to $27,
## OverworldEpilogue), with HandleOverworld's level selection after it; a new game's prologue is a
## cutscene (OverworldPrologue).


## One game loop of the map (HandleOverworld): OverworldStateTable by wSubState, a level chosen
## selected, then the V-Blank function it left (VBlank_Overworld, VBlank_OWScene, VBlank_OWPalTransition,
## VBlank_Cutscene, .VBlank_GolfBuilding, VBlank_PrologueEpilogue): what it writes to RAM before the
## next loop, and for drawing
## what it writes to the hardware.
func update() -> void:
	loops += 1
	screen_loads.clear()
	vram_writes.clear()
	palette_writes.clear()
	register_writes.clear()
	match sim.wSubState:
		0x00, 0x04:
			_fade(0, true)  # FastFadeToWhite
		0x06:
			_fade(0, false)  # SlowFadeFromWhite
		0x01:
			init_overworld()
		0x05:
			init_ow_scene()  # SST_OVERWORLD_OW_SCENE
		0x07:
			ow_scene_loop()  # Func_80540
		0x08, 0x14:
			_fade(1, true)  # FadeBGToWhite_Normal
		0x0A, 0x12:
			_fade(1, false)  # DarkenBGToPal_Normal
		0x09:
			init_map_side()  # SST_OVERWORLD_09
		0x0B:
			map_side_loop()  # SST_OVERWORLD_0B: Func_805d7
		0x0C, 0x10:
			_fade(1, true)  # FadeBGToWhite_Normal (SST_OVERWORLD_COLLECTION)
		0x0D:
			init_treasure_collection()
		0x0E:
			_fade(1, false)  # DarkenBGToPal_Normal
		0x0F:
			treasure_collection()
		0x16:
			_fade(1, true)  # FadeBGToWhite_Normal (SST_OVERWORLD_BEST_TIMES)
		0x17:
			init_best_time_list()
		0x18:
			_fade(1, false)  # DarkenBGToPal_Normal
		0x19:
			best_time_list()
		0x1A:
			_fade(1, true)  # FadeBGToWhite_Normal (SST_OVERWORLD_1A)
		0x1B:
			init_temple_scene()
		0x1C:
			_fade(1, false)  # DarkenBGToPal_Normal
		0x1D:
			update_temple_scene()
		0x11:
			init_cutscene()  # SST_OVERWORLD_CUTSCENE: InitCutscene
		0x13:
			update_cutscene()
		0x15:
			func_80db1()
		0x1E:
			func_80e33()
		0x1F:
			_fade(1, true)  # FadeBGToWhite_Normal
		0x21:
			_fade(1, false)  # DarkenBGToPal_Normal
		0x20:
			golf_building()  # SST_OVERWORLD_GOLF_BUILDING
		0x22:
			func_adbfe()  # Func_80e55
		0x23:
			_fade(0, true)  # FastFadeToWhite (SST_OVERWORLD_EPILOGUE)
		0x24:
			init_epilogue()  # InitEpilogue
		0x25:
			_fade(0, false)  # SlowFadeFromWhite
		0x26:
			update_epilogue()  # Func_80e75
		0x27:
			func_803e6()  # Func_80e85
		_:
			_note("OverworldStateTable sub-state %d (not ported)" % sim.wSubState)
	handle_overworld_level_selection()
	if vblank_func == VBLANK_OVERWORLD:
		vblank_overworld()
	elif vblank_func == VBLANK_OW_SCENE:
		vblank_ow_scene()
	elif vblank_func == VBLANK_OW_PAL_TRANSITION:
		vblank_ow_pal_transition()
	elif vblank_func == VBLANK_CUTSCENE:
		vblank_cutscene()
	elif vblank_func == VBLANK_GOLF_BUILDING:
		vblank_golf_building()
	elif vblank_func == VBLANK_PROLOGUE:
		vblank_prologue_epilogue()


## A fade's loop at `speed` (fade), recorded for drawing first: its kind (FadeBGToWhite, or DarkenBGToPal
## toward wTempPals1 and wTempPals2), its speed, and wPalFadeCounter before it (its V-Blank functions,
## VBlank_88d and VBlank_8bf, store and load the palettes the loops step).
func _fade(speed: int, to_white: bool) -> void:
	palette_writes.append(["fade", to_white, speed, sim.wPalFadeCounter, wram[0].slice(W_TEMP_PALS_1 - 0xC000,
			W_TEMP_PALS_1 - 0xC000 + 0x80)])
	fade(speed)
