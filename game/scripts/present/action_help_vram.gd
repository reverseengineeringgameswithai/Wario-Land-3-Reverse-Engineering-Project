class_name ActionHelpVram
extends ScreenVram
## What Action Help puts in VRAM (WL3-051): InitActionHelp's screen (BG map 0 cleared, the objects'
## tiles in bank 1 and the HUD's in bank 0, BG map 1's maps with the power-up row: the power-ups
## Wario has and those still to find), the palettes it writes, the cursor's attributes, Wario's tiles
## by DMA at V-Blank, and the room animation's tiles (the swimming demo's water), from
## action_help.json's graphics and the room animation's tile sets.

## The power-up row on BG map 1 (row 16, two tiles a power-up): the first entry, and the last's.
const POWER_UP_ROW: int = 0x9E00
const LAST_POWER_UP: int = 0x9E12


func _init(document: Dictionary = {}, animation: Dictionary = {}) -> void:
	super(document)
	animated_tiles = animation.get("animated_tiles_gfx", {})
	bg_palettes.resize(0x40)
	obj_palettes.resize(0x40)


## One loop: the screen its init loaded, the palettes and BG entries it wrote, the V-Blank's DMA,
## and the room animation's frame if one was written.
func update(help: ActionHelpSim, sim: LevelSim) -> void:
	for load: Array in help.screen_loads:
		if String(load[0]) == "action_help":
			load_action_help(help, sim)
	for entry: Array in help.palette_writes:
		var palettes: PackedByteArray = obj_palettes if bool(entry[0]) else bg_palettes
		var bytes: PackedByteArray = entry[2]
		for offset: int in bytes.size():
			if int(entry[1]) + offset < palettes.size():
				palettes[int(entry[1]) + offset] = bytes[offset]
		if bool(entry[0]):
			obj_palettes = palettes
		else:
			bg_palettes = palettes
	for entry: Array in help.vram_writes:
		write_byte(int(entry[0]), int(entry[1]), int(entry[2]))
	for dma: Array in help.dma_writes:
		var tiles: PackedByteArray = String(gfx.get("wario", {}).get("%02x:%04x" % [int(dma[0]) >> 16,
				int(dma[0]) & 0xFFFF], "")).hex_decode()
		write(int(dma[1]), int(dma[2]), tiles.slice(0, int(dma[3])))
	room_animation(sim)


## InitActionHelp's drawing: ClearBGMap0, LoadActionHelpGfx (the special power-ups' objects with
## ActionHelpObjects2Gfx), and LoadActionHelpBGMaps: for a main power-up the plain attribute under
## those Wario has, and the unknown power-up's tiles ($64, $65, $74, $75 with attribute $07) over
## those he has yet to find, from the last back; for a special one, over all ten.
func load_action_help(help: ActionHelpSim, sim: LevelSim) -> void:
	screen = "action_help"
	fill_bg_map_0(0xFF)
	var power_up: int = help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP) & ActionHelpSim.POWER_UP_MASK
	var main: bool = power_up < ActionHelpSim.NUM_MAIN_POWER_UPS
	write(1, 0x8000, _bytes("compressed", "79:5871" if main else "79:626b"))
	write(0, 0x8000, _bytes("compressed", "79:4fcf"))
	write(1, BG_MAP_1, _bytes("compressed", "79:68bd"))
	write(0, BG_MAP_1, _bytes("compressed", "79:6796"))
	var unknown: int = ActionHelpSim.NUM_MAIN_POWER_UPS
	if main:
		var level: int = sim.wPowerUpLevel & ActionHelpSim.POWER_UP_MASK
		for index: int in level:
			_square(1, POWER_UP_ROW + index * 2, [0x03, 0x03, 0x03, 0x03])
		unknown = (9 - level) & 0xFF
	for index: int in unknown:
		var address: int = LAST_POWER_UP - index * 2
		_square(1, address, [0x07, 0x07, 0x07, 0x07])
		_square(0, address, [0x64, 0x65, 0x74, 0x75])


## A 2x2 block of BG map entries from `address`: top left, top right, bottom left, bottom right.
func _square(bank: int, address: int, values: Array) -> void:
	for index: int in 4:
		write_byte(bank, address + (index & 1) + (index >> 1) * MAP_WIDTH, int(values[index]))
