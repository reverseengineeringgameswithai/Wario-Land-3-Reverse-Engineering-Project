extends Node
## Entry point. Interactive by default; `--selftest` runs a trace headlessly and exits.
##
## User arguments (after `--`):
##   --content-dir=ABS_PATH  load a content pack from the filesystem instead of res://
##   --mods-dir=ABS_PATH     apply data-only mods from this directory (default: user://mods if present)
##   --original-dir=ABS_PATH run an extracted level with the ported Wario instead of a pack (WL3-033):
##                           the directory holds wario_movement.json and levels/level-XX.json, and
##                           optionally rooms/ (room graphics) and wario_sprites.json
##   --level=N               the level for --original-dir (default 0, Out of the Woods, day 1)
##   --save=ABS_PATH|none    with --original-dir: start at power-on with this 32 KiB battery save, or
##                           none (a new game), instead (WL3-055, WL3-056): the save's load, the
##                           title, the map, the levels (--screenshot and --trace work from power-on too)
##   --trace=ABS_PATH        input trace for --selftest (default: bundled walk-jump trace)
##   --selftest              print `WL3PC_SELFTEST <json>` and exit 0, or exit 1 on error
##   --screenshot=ABS_PATH   with --original-dir: play --trace's input (if given) in the window for
##                           --frames=N ticks (default 60), save the view without its labels as a
##                           PNG (or as raw 8-bit RGB if the path ends in .rgb), and quit
##   --start-counter=N       with --screenshot: wGlobalCounter when the level starts (default 0)
##   --lead-in=N             with --screenshot: N frames without input before --trace's first tick
##   --div-reads=ABS_PATH    with --save and --screenshot: replay an oracle trace's div_reads in order
##                           (rDIV, and ProcessBlock's reads outside the map), so what rDIV decides
##                           falls as in the trace (a window check against its screens)

const DEFAULT_PACK: String = "res://assets/content/synthetic"
const DEFAULT_TRACE: String = "res://assets/traces/walk-jump.json"

const NOTICE_TICKS: int = 120

var _pack: ContentPack
var _grid: CollisionGrid
var _state: PlayerState
var _clock: SimClock = SimClock.new()
var _sim: LevelSim
var _level_view: LevelView
var _notice: Label
var _notice_ticks: int = 0
var _reported: Dictionary = {}
var _script_trace: InputTrace
var _script_tick: int = 0
var _screenshot_path: String = ""
var _screenshot_ticks: int = 0

@onready var _view: RoomView = $RoomView


func _ready() -> void:
	var args: Dictionary = _parse_args(OS.get_cmdline_user_args())
	if args.has("original-dir"):
		_start_original(args)
		return
	var loader := ContentLoader.new()
	_pack = _load_content(loader, args)
	if _pack == null:
		_abort("content", loader.errors)
		return
	if args.has("selftest"):
		_run_selftest(loader, args)
		return
	InputSetup.register()
	_grid = (_pack.rooms[_pack.start_room] as RoomData).build_grid()
	_state = _pack.initial_state()
	_view.show_room(_grid)
	_view.show_player(_state, _pack.movement)
	print("WL3PC prototype: pack=%s mods=%s content_sha256=%s" % [_pack.id, Array(_pack.applied_mods), _pack.content_hash()])
	_print_approximations()


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()
		return
	if _sim != null:
		_process_original(delta)
		return
	if _state == null:
		return
	var due: int = _clock.advance(delta)
	for i: int in due:
		PlayerSim.step(_state, InputSetup.sample(), _grid, _pack.movement)
	if due > 0:
		_view.show_player(_state, _pack.movement)


## An extracted level run by the ported Wario (WL3-033), drawn from the decoded room graphics and
## Wario's sprites when they are extracted, and as boxes otherwise (LevelView).
func _start_original(args: Dictionary) -> void:
	var dir: String = str(args["original-dir"])
	var number: int = int(str(args.get("level", "0")))
	if not dir.begins_with("/"):
		_abort("content", PackedStringArray(["--original-dir must be an absolute path, got %s" % dir]))
		return
	var tables: WarioTables = WarioTables.load_file(dir.path_join("wario_movement.json"))
	if args.has("save"):
		_start_power_on(dir, tables, args)
		return
	var level: LevelCollision = LevelCollision.load_file(dir.path_join("levels/level-%02x.json" % number))
	if tables == null or level == null or level.start.is_empty():
		_abort("content", PackedStringArray(["no extracted movement tables or level %d in %s (run make extract)" % [number, dir]]))
		return
	if args.has("selftest"):
		var loader := ContentLoader.new()
		var trace: InputTrace = loader.load_trace(str(args.get("trace", DEFAULT_TRACE)))
		if trace == null:
			_abort("trace", loader.errors)
			return
		var result: Dictionary = LevelRunner.run_trace(tables, level, trace, _objects_document(dir))
		result["engine"] = Engine.get_version_info()["string"]
		result["level"] = number
		result["original_dir"] = dir
		print("WL3PC_SELFTEST " + JSON.stringify(result, "", true))
		get_tree().quit(0)
		return
	_sim = LevelRunner.start(tables, level, _objects_document(dir), _level_loader(dir))
	var sprites: WarioSprites = _show_original(dir)
	($Overlay/PrototypeLabel as Label).text = ("LEVEL $%02X ported\nF2: collision" if sprites != null
			else "LEVEL $%02X ported\nWario is a box (F2)") % number
	print("WL3PC original level %d: Wario starts at (%d, %d), camera at (%d, %d); ported: %d of Wario's states, the level camera, room transitions; sprites %s"
			% [number, _sim.wWarioXPos, _sim.wWarioYPos, _sim.wCameraSCX, _sim.wCameraSCY, WarioSim.PORTED_STATES.size(),
			"decoded" if sprites != null else "not extracted (a box)"])
	if args.has("screenshot"):
		_screenshot_path = str(args["screenshot"])
		_screenshot_ticks = int(str(args.get("frames", "60")))
		($Overlay as CanvasLayer).visible = false
		# A trace that starts some frames into the level (an oracle route's end) needs the frames before it.
		_sim.wGlobalCounter = int(str(args.get("start-counter", "0"))) & 0xFF
		for i: int in int(str(args.get("lead-in", "0"))):
			LevelRunner.frame(_sim, 0)
		if args.has("trace"):
			_script_trace = ContentLoader.new().load_trace(str(args["trace"]))


## The levels the map enters, from an extracted directory.
static func _level_loader(dir: String) -> Callable:
	return func(entered: int) -> LevelCollision:
		var path: String = dir.path_join("levels/level-%02x.json" % entered)
		return LevelCollision.load_file(path) if FileAccess.file_exists(path) else null


## The window on _sim (LevelView, from the extracted graphics) and the notice line for what is not
## ported; returns Wario's sprites (null when they are not extracted).
func _show_original(dir: String) -> WarioSprites:
	InputSetup.register()
	_view.queue_free()
	_level_view = LevelView.new()
	add_child(_level_view)
	move_child(_level_view, 0)
	var sprites: WarioSprites = WarioSprites.load_file(dir.path_join("wario_sprites.json"))
	var objects: Dictionary = _objects_document(dir)
	_level_view.show_level(_sim, dir.path_join("rooms"), sprites,
			ObjectSprites.from_document(objects) if not objects.is_empty() else null)
	_notice = Label.new()
	_notice.add_theme_font_size_override("font_size", 8)
	_notice.position = Vector2(2, 124)
	_notice.modulate = Color("#ff8080")
	$Overlay.add_child(_notice)
	return sprites


## Power-on with a battery save or none (WL3-055, WL3-056): the save's load, the title (A takes
## Continue, or New Game without a save), the map, and the levels it enters, natively.
func _start_power_on(dir: String, tables: WarioTables, args: Dictionary) -> void:
	var save_path: String = str(args["save"])
	var save := PackedByteArray()
	if save_path == "none":
		save.resize(4 * SaveLoad.SRAM_SIZE)  # an empty cartridge RAM: a new game
	elif save_path.begins_with("/"):
		save = FileAccess.get_file_as_bytes(save_path)
	if tables == null or save.size() != 4 * SaveLoad.SRAM_SIZE:
		_abort("content", PackedStringArray(["--save needs none or an absolute path to a 32 KiB battery save, and the extracted movement tables (got %s)" % save_path]))
		return
	_sim = LevelRunner.power_on(tables, save, _objects_document(dir), _level_loader(dir))
	if _sim == null:
		_abort("content", PackedStringArray(["no extracted title or map in %s (run make extract)" % dir]))
		return
	_show_original(dir)
	($Overlay/PrototypeLabel as Label).text = "POWER-ON ported\nA: Continue" if _sim.wceef != 0 else "POWER-ON ported\nA: New Game"
	print("WL3PC power-on with save %s: wceef $%02x, the title, then the map; ported: the save's load, the title's Continue, the map, the levels"
			% [save_path, _sim.wceef])
	if args.has("screenshot"):
		_screenshot_path = str(args["screenshot"])
		_screenshot_ticks = int(str(args.get("frames", "60")))
		($Overlay as CanvasLayer).visible = false
		if args.has("trace"):
			_script_trace = ContentLoader.new().load_trace(str(args["trace"]))
		if args.has("div-reads"):
			_replay_div_reads(str(args["div-reads"]))


## --div-reads: the trace's recorded reads queued for the game to take in order (LevelSim keeps them
## through Init); a read the original did not make is noted, as in the parity check.
func _replay_div_reads(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if path.begins_with("/") else null
	if not parsed is Dictionary or not parsed.has("div_reads"):
		_abort("content", PackedStringArray(["--div-reads needs an absolute path to an oracle trace with div_reads (got %s)" % path]))
		return
	_sim.div_replay = true
	_sim.div_queue.clear()
	for read: Array in parsed["div_reads"]:
		_sim.div_queue.append([(int(read[2]) << 16) | int(read[3]), int(read[4])])


## objects.json from an extracted directory, or {} (the level then runs without objects).
## objects.json, with the rooms' animation tables (rooms/animation.json) as "room_animation" and the
## golf minigame's data (golf.json) as "golf", the clear screen's (clear.json) as "clear", Action
## Help's (action_help.json) as "action_help", the save screens' (pause_menu.json) as "pause_menu", the
## map's (overworld.json) as "overworld", the title's (title.json) as "title", the credits'
## (credits.json) as "credits", the game over screen's (game_over.json) as "game_over", and the Perfect
## screen's (perfect.json) as "perfect".
static func _objects_document(dir: String) -> Dictionary:
	var path: String = dir.path_join("objects.json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	var animation_path: String = dir.path_join("rooms/animation.json")
	if FileAccess.file_exists(animation_path):
		var animation: Variant = JSON.parse_string(FileAccess.get_file_as_string(animation_path))
		if animation is Dictionary:
			parsed["room_animation"] = animation
	for screen: String in ["golf", "clear", "action_help", "pause_menu", "overworld", "title", "credits",
			"game_over", "perfect"]:
		var screen_path: String = dir.path_join(screen + ".json")
		if FileAccess.file_exists(screen_path):
			var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(screen_path))
			if document is Dictionary:
				parsed[screen] = document
	return parsed


func _process_original(delta: float) -> void:
	var due: int = _clock.advance(delta)
	if not _screenshot_path.is_empty():
		due = mini(due, _screenshot_ticks - _script_tick)  # the screenshot after exactly that many ticks
	for i: int in due:
		var held: int = InputSetup.sample()
		if not _screenshot_path.is_empty():
			held = _script_trace.held_at(_script_tick) if _script_trace != null and _script_tick < _script_trace.ticks else 0
			_script_tick += 1
		LevelRunner.frame(_sim, held)
		_level_view.after_loop()
		for routine: String in _sim.unported:
			_notice.text = "not ported: " + routine
			_notice_ticks = NOTICE_TICKS
			if not _reported.has(routine):
				_reported[routine] = true
				print("WL3PC not ported yet: %s (the frame's update is incomplete)" % routine)
		if _notice_ticks > 0:
			_notice_ticks -= 1
			if _notice_ticks == 0:
				_notice.text = ""
	if due > 0:
		_level_view.refresh()
	if not _screenshot_path.is_empty() and _script_tick >= _screenshot_ticks:
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		if _screenshot_path.ends_with(".rgb"):
			image.convert(Image.FORMAT_RGB8)
			var file := FileAccess.open(_screenshot_path, FileAccess.WRITE)
			file.store_buffer(image.get_data())
			file.close()
		else:
			image.save_png(_screenshot_path)
		print("WL3PC screenshot: %s after %d ticks" % [_screenshot_path, _script_tick])
		get_tree().quit(0)
		_screenshot_path = ""


func _load_content(loader: ContentLoader, args: Dictionary) -> ContentPack:
	var pack_dir: String = str(args.get("content-dir", DEFAULT_PACK))
	if not _absolute_or_res(pack_dir):
		loader.errors.append("--content-dir must be an absolute path, got %s" % pack_dir)
		return null
	var pack: ContentPack = loader.load_pack(pack_dir)
	if pack == null:
		return null
	var mods_dir: String = str(args.get("mods-dir", ""))
	if mods_dir.is_empty() and DirAccess.dir_exists_absolute("user://mods"):
		mods_dir = "user://mods"
	if not mods_dir.is_empty():
		if not _absolute_or_res(mods_dir) and not mods_dir.begins_with("user://"):
			loader.errors.append("--mods-dir must be an absolute path, got %s" % mods_dir)
			return null
		if not loader.apply_mods_from_dir(pack, mods_dir):
			return null
	return pack


func _run_selftest(loader: ContentLoader, args: Dictionary) -> void:
	var trace_path: String = str(args.get("trace", DEFAULT_TRACE))
	var trace: InputTrace = loader.load_trace(trace_path)
	if trace == null:
		_abort("trace", loader.errors)
		return
	var result: Dictionary = SimRunner.run_trace(_pack, trace)
	result["engine"] = Engine.get_version_info()["string"]
	result["content_dir"] = _pack.source_dir
	result["origin"] = _pack.origin
	result["approximations"] = _pack.approximations.map(func(a: Dictionary) -> String: return a["subject"])
	print("WL3PC_SELFTEST " + JSON.stringify(result, "", true))
	get_tree().quit(0)


## ADR-0002: a pack's known differences from the original are shown, never hidden.
func _print_approximations() -> void:
	for a: Dictionary in _pack.approximations:
		print("WL3PC approximation: %s behaves as %s; original: %s%s" % [
			a["subject"], a["behaves_as"], a["original"], " (%s)" % a["task"] if a.has("task") else ""])


func _abort(stage: String, errors: PackedStringArray) -> void:
	for message: String in errors:
		printerr("WL3PC_ERROR %s: %s" % [stage, message])
	get_tree().quit(1)


static func _absolute_or_res(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("/")


static func _parse_args(raw: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for arg: String in raw:
		if not arg.begins_with("--"):
			continue
		var body: String = arg.substr(2)
		var eq: int = body.find("=")
		if eq < 0:
			out[body] = true
		else:
			out[body.substr(0, eq)] = body.substr(eq + 1)
	return out
