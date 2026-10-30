class_name LevelRunner
extends RefCounted
## Runs the ported game on an extracted level, one frame per call (WL3-033, WL3-036, WL3-035): the
## joypad byte as UpdateJoypad builds it, UpdateLevel's ported parts (Wario, the objects and their
## interactions, the camera, room transitions: LevelSim), then the frame counter, which .GameLoop
## increments after V-Blank (src/home/start.asm). Reaching an unported routine is reported.


## `objects` is the extracted objects.json; without it the level has no objects. Its "golf" (golf.json)
## runs the golf minigame, its "clear" (clear.json) the level's clear screen, its "action_help"
## (action_help.json) Action Help, its "pause_menu" (pause_menu.json) the map's save screen, its
## "overworld" (overworld.json) the map, its "credits" (credits.json) the credits, its "game_over"
## (game_over.json) the game over screen, its "perfect" (perfect.json) the Perfect screen; the level and
## the screens keep one RAM (WL3-052).
## `level_loader` ((wLevel) -> LevelCollision) gives InitLevel the level the map enters.
static func start(tables: WarioTables, level: LevelCollision, objects: Dictionary = {},
		level_loader: Callable = Callable()) -> LevelSim:
	var sim := LevelSim.new()
	sim.tables = tables
	sim.level = level
	sim.level_loader = level_loader
	sim.sync_screen_wram = true
	_load_screens(sim, objects)
	var room: int = int(level.start.get("level_room_id", 0))
	sim.start_level_with_camera(room, int(level.start["wario_x"]), int(level.start["wario_y"]),
			level.room_fields.get(room, {}))
	return sim


## The objects' data and the screens' from `objects` into `sim`, as `start` describes.
static func _load_screens(sim: LevelSim, objects: Dictionary) -> void:
	if not objects.is_empty():
		sim.load_object_data(objects)
		sim.room_animation = objects.get("room_animation", {})
	if objects.get("golf", null) is Dictionary:
		sim.load_golf_data(objects["golf"])
	if objects.get("clear", null) is Dictionary:
		sim.load_clear_data(objects["clear"])
	if objects.get("action_help", null) is Dictionary:
		sim.load_action_help_data(objects["action_help"])
	if objects.get("pause_menu", null) is Dictionary:
		sim.load_pause_menu_data(objects["pause_menu"])
	if objects.get("overworld", null) is Dictionary:
		sim.load_overworld_data(objects["overworld"])
	if objects.get("credits", null) is Dictionary:
		sim.load_credits_data(objects["credits"])
	if objects.get("game_over", null) is Dictionary:
		sim.load_game_over_data(objects["game_over"])
	if objects.get("perfect", null) is Dictionary:
		sim.load_perfect_data(objects["perfect"])


## The game from power-on with a 32 KiB battery save (WL3-055): the screens as `start` loads them,
## with the title (`objects`' "title", title.json), and the RAM as Init leaves it for the first loop
## (load_power_on_ram), counted 0. The map enters the levels `level_loader` gives. Null without the
## title's or the map's data.
static func power_on(tables: WarioTables, save: PackedByteArray, objects: Dictionary,
		level_loader: Callable) -> LevelSim:
	if not objects.get("title", null) is Dictionary or not objects.get("overworld", null) is Dictionary:
		return null
	var sim := LevelSim.new()
	sim.tables = tables
	sim.level_loader = level_loader
	sim.sync_screen_wram = true
	_load_screens(sim, objects)
	sim.load_title_data(objects["title"])
	load_power_on_ram(sim, save)
	sim.wGlobalCounter = 0
	return sim


## Init's RAM with `save` loaded, in `sim` and its screens (src/home/start.asm): the RAM cleared, the
## save's load (SaveLoad: WRAM0, WRAMX banks 1 and 2, and SRAM as ValidateSaveData leaves them: the
## LevelSim's loaded_sram, with bank 0 and the backups the pause menu's to write, banks 1 and 2 the
## level map a resumed level plays on), and InitGameState's title (wState and wSubState 0), with the
## title's cleared virtual OAM the game's. Every byte is known (when `sim` tracks them). The counter
## is the caller's.
static func load_power_on_ram(sim: LevelSim, save: PackedByteArray) -> void:
	var ram: Dictionary = SaveLoad.cleared_wram()
	var sram: Array = SaveLoad.sram_banks(save)
	SaveLoad.new().validate_save_data(sram, ram)
	for bank: int in [0, 2, 3]:
		sim.screen_wram[bank] = ram[bank]
		if sim.screen_wram.has("known"):
			sim.screen_wram["known"][bank].fill(1)
	if sim.screen_wram.has("known"):
		sim.screen_wram["known"]["sram"].fill(1)
	sim.wram1 = ram[1].slice(0, ObjectSim.WRAM1_SIZE)
	sim.loaded_sram = sram
	sim.level_map_sram = LevelSim.LevelMapSram.LOADED
	if sim.pause_menu_screen != null:
		for bank: int in [0, 2, 3]:
			sim.pause_menu_screen.sram[bank] = sram[bank]
	sim.adopt_screen_wram()
	sim.wState = LevelSim.ST_TITLE
	sim.wSubState = 0
	if sim.title != null:
		sim.hand_over_oam(sim.title)


## One frame with `held` (InputBits): UpdateJoypad (pressed: what was not down in wJoypadDown, which
## Init clears) and the game loop. Returns this frame's joypad byte.
static func frame(sim: LevelSim, held: int) -> int:
	var joypad: int = InputBits.to_joypad(held)
	sim.wJoypadPressed = joypad & ~sim.wJoypadDown & 0xFF
	sim.wJoypadDown = joypad
	sim.update_level()
	sim.wGlobalCounter = (sim.wGlobalCounter + 1) & 0xFF
	return joypad


## Run a whole input trace from the level start and summarise it.
static func run_trace(tables: WarioTables, level: LevelCollision, trace: InputTrace, objects: Dictionary = {}) -> Dictionary:
	var sim: LevelSim = start(tables, level, objects)
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	var unported: Dictionary = {}
	var positions: Array = []
	for tick: int in trace.ticks:
		frame(sim, trace.held_at(tick))
		for routine: String in sim.unported:
			if not unported.has(routine):
				unported[routine] = tick
		positions.append([sim.wWarioXPos, sim.wWarioYPos, sim.wCameraSCX, sim.wCameraSCY])
		hashing.update(("%d,%d,%d;" % [sim.wWarioXPos, sim.wWarioYPos, sim.wWarioState]).to_utf8_buffer())
	return {
		"mode": "original-level",
		"ticks": trace.ticks,
		"final": {"x": sim.wWarioXPos, "y": sim.wWarioYPos, "state": sim.wWarioState, "direction": sim.wDirection,
				"walk_vel_index": sim.wWalkVelIndex, "jump_vel_index": sim.wJumpVelIndex},
		"positions_sha256": hashing.finish().hex_encode(),
		"positions": positions,
		"unported_first_tick": unported,
	}
