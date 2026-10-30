extends SceneTree
## Compare the native Wario port (WarioSim) with an oracle Wario trace (WL3-012).
## Usage (wrapped by `make wario-parity TRACE=...`):
##   godot --headless --path game -s res://tests/parity/wario_parity.gd -- \
##     --trace=local/captures/NAME.wario.json --content-dir=local/content/wl3-original [--out=report.json]
##
## The trace records every Wario update exactly ("updates": the variables on entry to
## UpdateWarioStates and on entry to UpdateObjects, which UpdateLevel calls next).
## step mode (default): for every update in a ported state, load the oracle's variables and the
## block map before it, run one native update, and compare with the oracle after it. Updates
## that reach an unported routine are counted by routine instead of compared.
## run mode (--mode=run): start from the first ported update and run the native model alone,
## taking only the input from each later update, until the first difference, the first
## unported routine, or the first change made to Wario between updates (object code).
## Prints one line "WARIO_PARITY {json}" (the caller decides pass or fail); exits 2 on bad input. With
## --batch=FILE, runs each check the file lists in turn and prints "WARIO_PARITY_JOB ID {json}" for each.

## Variables compared after each frame. Scratch variables that later code in the frame reuses
## (hPos, wCollisionPoints, camera deltas, floor transition timer) are left out.
const COMPARED: PackedStringArray = [
	"wWarioState", "wWarioYPos", "wWarioXPos", "wDirection", "wWalkVelIndex", "wJumpVelIndex",
	"wJumpVelTable", "wDoFullJump", "wJumpingUpwards", "wCollisionBoxTop", "wCollisionBoxBottom",
	"wCollisionBoxLeft", "wCollisionBoxRight", "wFrameDuration", "wAnimationFrame", "wWarioFramesetPtr",
	"wWarioAnimationEnded", "wWarioStateCounter", "wWarioStateCycles", "wIsTurning", "wIsSmashAttacking",
	"wAttackCounter", "wIsCrouching", "wWarioSlopeInteraction", "wLadderInteraction",
	"wRoomTransitionParam", "wJumpCollision", "wSFXLoopCounter", "wFloor", "wFloorTransitionDir",
	"wIsFloorTransition", "wCoinCooldown", "wWaterInteraction", "wIsNearFence", "wIsInSand",
	"wIsInAirCurrent", "wGrabState", "wInvincibleCounter", "wIsDMATransferPending", "wSubState",
	"wIsIntangible", "wWarioFrame", "wWarioAttributes", "wWarioPalsPtr", "wDMASourceBank", "wDMASourcePtr",
	"wWarioOAMBank", "wWarioOAMPtr", "wInvisibleFrame", "wTransformation", "wTouchState", "wStingTouchState",
	"wTransformationDuration", "wLevelEndScreen", "wKeyAndTreasureFlags", "wAutoMoveState",
]
## Camera variables compared after UpdateLevel's camera code (and at the level start).
## The rooms' animation (WL3-037), compared at the end of each whole frame.
const ANIMATION_COMPARED: PackedStringArray = ["wAnimatedTilesFrameDuration", "wAnimatedTilesGfx",
	"wAnimatedTilesFrame", "wAnimatedTilesFrameCount", "wRoomPalCycleDuration", "wRoomPalCycleIndex",
	"wRoomPalCycleCounter", "wRoomAnimatedTilesEnabled", "wRoomAnimatedPalsEnabled"]
const CAMERA_COMPARED: PackedStringArray = [
	"wCameraSCX", "wCameraSCY", "wCameraXDelta", "wCameraYDelta", "wScrollRightEdge", "wScrollLeftEdge",
	"wScrollUpEdge", "wScrollDownEdge", "wc0d4", "wc0d5", "wLevelEdgeUpdateFlags", "wFloorTransitionDir",
	"wFloorTransitionTimer", "wIsFloorTransition", "wPrevWarioScreenYPos",
]
const START_CAMERA_COMPARED: PackedStringArray = [
	"wCameraSCX", "wCameraSCY", "wSCX", "wSCY", "wCamLeftSpacing", "wCamRightSpacing", "wPrevWarioScreenYPos",
	"wWarioScreenXPos", "wWarioScreenYPos", "wRoomLeftXLimit", "wRoomRightXLimit", "wRoomUpperYLimit",
	"wRoomLowerYLimit", "wCameraRoomXScrollLimit", "wCameraRoomYScrollLimit",
]
const LEVEL_STATE: int = 2  # ST_LEVEL
const LEVEL_PLAYING: int = 3  # wSubState while UpdateLevel runs
const GOLF_STATE: int = 5  # ST_GOLF
const MAX_EXAMPLES: int = 40

## The first frame of the window checked (0 unless --from is given).
var window_start: int = 0
## Game loops completed by each frame of the trace (wGlobalCounter's steps, unwrapped).
var loop_counts: PackedInt32Array = PackedInt32Array()
## The golf minigame's visits: [first frame, the frame after, game loops, wNumCoins and
## wIsMinigameCleared after it].
var golf_visits: Array = []
## Golf's own rDIV reads (the golf check replays them), and each golf loop's joypad
## ([wJoypadDown, wJoypadPressed], with its frame) for runs that play golf natively.
var golf_div_reads: Array = []
var golf_inputs: Array = []
## The screens' extracted documents by trace key (clear, action_help, pause_menu, overworld), for runs
## that go on from a level's end into the screens after it natively.
var screen_docs: Dictionary = {}
## What runs seeded from the trace (_seed_screen): [trace key, frame, what], in order; and the screens
## seeded since the native game last left a level (each seeds once after one).
var seeded: Array = []
var seeded_since_level: Dictionary = {}
var seen_screens: Dictionary = {}
## The LevelSim's own HRAM variables a run seeded (hDemoPowerUp: the screens share it), each once.
var seeded_hram: Dictionary = {}
## The screen loops a run compared within a level (_run_level_gap: the pause menu), by screen.
var within_level: Dictionary = {}
## The level's RAM its port does not keep, which a run takes from the trace at the first screen loop
## after a level: the palettes it loads (wTempPals1 and wTempPals2, presentation), wTempBank (the
## bank of its last banked call), its BG map pointer (wBGPtr, presentation; the credits' BG map
## pointer shares it) and its tile and address queues' entries the screens trace (wBGMapTileVRAM0Queue
## and wBGMapTileVRAM1Queue, wBGMapAddressQueueSize, wBGMapAddressQueue's first two: presentation; the
## pause menu's trace records the first 6 bytes, the credits' text buffer and pointers share all
## $6d), and its pending DMA's bank, source, destination, and length (Wario's tiles;
## wIsDMATransferPending is kept). [WRAM bank, address, size].
const LEVEL_RAM_NOT_KEPT: Array = [[0, 0xC000, 0x80], [0, 0xC0AC, 1], [0, 0xCCF0, 2], [0, 0xCE01, 0x6D],
		[0, 0xC1A1, 7]]
## The extracted content's directory (the levels InitLevel loads in a run that enters one).
var content_dir: String = ""
## The battery save a power-on movie starts with (32 KiB; zeros for an empty cartridge RAM), given by
## --power-on-save: a run then starts at power-on (_power_on) instead of seeding the map, and the step
## check's resets load it (_menu_screen_exit). Null otherwise.
var power_on_save: Variant = null
## The original's loads in a power-on run (--loads: wl3pc.oracle_save's captures of the movie, the
## power-on load first, then each reset's), and each compared with the SRAM the run's load left
## (_check_loads): [load number, bytes that differ (-1: a load the run passed unchecked), examples].
var loads: PackedStringArray = PackedStringArray()
var load_checks: Array = []
## The hidden figure's fight drawn (WL3-052) as a run plays it (_temple_before, _temple_after): the
## trace's temple_vram snapshots, temple_screens, palette writes (pal_writes), and animated tiles
## chunks (animation_copies) by frame, the TempleVram the run updates, and the results.
var temple_vram: TempleVram = null
var temple_snapshots: Dictionary = {}
var temple_screens: Dictionary = {}
var temple_pal_writes: Dictionary = {}
var temple_copies: Dictionary = {}
var temple_drawn: Dictionary = {}

## The level's maps as the trace saw them: the block map (block_rows, block_changes) and, when
## recorded, the object map (object_rows, object_changes), advanced frame by frame.
class MapTruth:
	var level: LevelCollision
	var changes: Array
	var object_changes: Array
	var index: int = 0
	var object_index: int = 0

	func _init(base: LevelCollision, trace: Dictionary) -> void:
		level = base.copy()
		level.set_rows(trace["block_rows"])
		level.set_gap_rows(trace.get("block_gap_rows", []))
		if trace.has("object_rows"):
			level.object_rows.clear()
			for row: Variant in trace["object_rows"]:
				level.object_rows.append(String(row).hex_decode())
		changes = trace["block_changes"]
		object_changes = trace.get("object_changes", [])

	## Apply every change recorded before frame `until` (exclusive).
	func advance(until: int) -> void:
		while index < changes.size() and int(changes[index][0]) < until:
			var change: Array = changes[index]
			level.set_block(int(change[1]), int(change[2]), int(change[3]))
			index += 1
		while object_index < object_changes.size() and int(object_changes[object_index][0]) < until:
			var change: Array = object_changes[object_index]
			level.object_rows[int(change[1])][int(change[2])] = int(change[3])
			object_index += 1


var names: PackedStringArray = PackedStringArray()
var index_of: Dictionary = {}
## The room animation calls of a frame two screen loops shared that the first of them took (by frame:
## how many), which the next loop's replay leaves out.
var shared_calls_taken: Dictionary = {}
## The trace's frames (each tick's end), for what no screen records.
var trace_frames: Array = []


func _initialize() -> void:
	var args: Dictionary = _args()
	if not args.has("batch"):
		var result: Array = _check(args)
		_finish(result[0], result[1])
		return
	# A batch (the sweeps): many checks in one process, each from a clean state, one result line each
	# (WARIO_PARITY_JOB ID JSON). --batch names a JSON list of {"id", and the arguments of one check:
	# "trace", "mode", ...}; the other arguments apply to every check.
	var jobs: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(args["batch"])))
	if not jobs is Array:
		_finish({"error": "cannot read batch %s" % args["batch"]}, 2)
		return
	for job: Dictionary in jobs:
		_reset()
		var job_args: Dictionary = args.duplicate()
		job_args.erase("batch")
		for key: String in job:
			if key != "id":
				job_args[key] = str(job[key])
		var result: Array = _check(job_args)
		print("WARIO_PARITY_JOB %s %s" % [job["id"], JSON.stringify(_summary(result[0]))])
	quit(0)


## The state one check builds, cleared before the next check of a batch.
func _reset() -> void:
	window_start = 0
	loop_counts = PackedInt32Array()
	golf_visits = []
	golf_div_reads = []
	golf_inputs = []
	screen_docs = {}
	seeded = []
	seeded_since_level = {}
	seen_screens = {}
	seeded_hram = {}
	within_level = {}
	content_dir = ""
	power_on_save = null
	loads = PackedStringArray()
	load_checks = []
	temple_vram = null
	temple_snapshots = {}
	temple_screens = {}
	temple_pal_writes = {}
	temple_copies = {}
	temple_drawn = {}
	names = PackedStringArray()
	index_of = {}
	trace_frames = []
	shared_calls_taken = {}
	cgb_screen = CgbScreen.new()


## One check (the arguments of a run of this script): [report, exit code].
func _check(args: Dictionary) -> Array:
	var trace: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(args.get("trace", ""))))
	if not trace is Dictionary:
		return [{"error": "cannot read trace %s" % args.get("trace", "")}, 2]
	for variable: Dictionary in trace["variables"]:
		index_of[String(variable["name"])] = names.size()
		names.append(String(variable["name"]))
	trace_frames = trace["frames"]
	_count_loops(trace)
	# A window of frames (one visit to a level, when a movie enters several): the per-frame lists
	# keep only its frames, and the level is the window's; the maps still follow the whole trace.
	window_start = int(args.get("from", "0"))
	var window_end: int = int(args.get("to", str(trace["frames"].size())))
	if args.has("from") or args.has("to"):
		# A read's count of object checkpoints before it is the whole trace's: less those dropped.
		var dropped: int = trace.get("object_checkpoints", []).filter(func(entry: Array) -> bool:
			return int(entry[0]) < window_start).size()
		# The screens' VRAM snapshots and screens count their loops: those before the window go. A
		# screen's loops keep the window's end frame: the loop that leaves the level is recorded in
		# the tick whose frame first shows it left.
		for screen: String in ["golf", "golf_building", "clear", "action_help", "pause_menu", "overworld", "title",
				"language_selection", "credits", "game_over", "perfect"]:
			var before: int = trace.get(screen + "_updates", []).filter(func(entry: Array) -> bool:
				return int(entry[0]) < window_start).size()
			if trace.has(screen + "_updates"):
				trace[screen + "_updates"] = trace[screen + "_updates"].filter(func(entry: Array) -> bool:
					return int(entry[0]) >= window_start and int(entry[0]) <= window_end)
			var kept: int = trace.get(screen + "_updates", []).size()
			for key: String in [screen + "_vram", screen + "_screens"]:
				if trace.has(key):
					for entry: Array in trace[key]:
						entry[0] = int(entry[0]) - before
					trace[key] = trace[key].filter(func(entry: Array) -> bool:
						return int(entry[0]) >= 0 and int(entry[0]) < kept)
		for key: String in ["updates", "camera_updates", "object_checkpoints", "animation_calls", "div_reads"]:
			if trace.has(key):
				trace[key] = trace[key].filter(func(entry: Array) -> bool:
					return int(entry[0]) >= window_start and int(entry[0]) < window_end)
		for read: Array in trace.get("div_reads", []):
			read[1] = int(read[1]) - dropped
	content_dir = String(args.get("content-dir", ""))
	if args.has("power-on-save") and window_start == 0:
		var save_path: String = String(args["power-on-save"])
		if save_path.is_empty():
			power_on_save = PackedByteArray()
			power_on_save.resize(4 * 0x2000)
		else:
			power_on_save = FileAccess.get_file_as_bytes(save_path)
		loads = String(args.get("loads", "")).split(",", false)
	var tables: WarioTables = WarioTables.load_file(content_dir.path_join("wario_movement.json"))
	var objects_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(content_dir.path_join("objects.json")))
	var animation_path: String = content_dir.path_join("rooms/animation.json")
	if objects_doc is Dictionary and FileAccess.file_exists(animation_path):
		objects_doc["room_animation"] = JSON.parse_string(FileAccess.get_file_as_string(animation_path))
	var golf_path: String = content_dir.path_join("golf.json")
	if objects_doc is Dictionary and FileAccess.file_exists(golf_path) and trace.has("golf_updates"):
		objects_doc["golf"] = JSON.parse_string(FileAccess.get_file_as_string(golf_path))
	var level_number: int = _first_level(trace)
	var level_path: String = content_dir.path_join("levels/level-%02x.json" % level_number)
	var level: LevelCollision = LevelCollision.load_file(level_path)
	if tables == null or level == null:
		return [{"error": "missing content in %s (run make extract and the level collision extractor)" % content_dir}, 2]
	var truth := LevelCollision.new()
	truth.room_handlers = level.room_handlers
	truth.set_rows(trace["block_rows"])
	truth.set_gap_rows(trace.get("block_gap_rows", []))
	for key: String in ["clear", "action_help", "pause_menu", "overworld", "title", "language_selection", "golf_building",
			"credits", "game_over", "perfect"]:
		# The language selection is the title's (title.json, TitleSim), the golf building golf's (golf.json).
		var file: String = {"language_selection": "title", "golf_building": "golf"}.get(key, key)
		var screen_path: String = content_dir.path_join(file + ".json")
		if FileAccess.file_exists(screen_path) and trace.has(key + "_updates"):
			screen_docs[key] = JSON.parse_string(FileAccess.get_file_as_string(screen_path))
	var report: Dictionary
	if String(args.get("mode", "step")) == "run":
		if objects_doc is Dictionary and trace.has("object_checkpoints"):
			report = _run_with_objects(trace, level, tables, objects_doc)
		else:
			report = _run(trace, truth, tables)
		if not loads.is_empty():
			report["loads"] = load_checks
	else:
		report = _step(trace, truth, tables)
	report["start"] = _start_check(trace, level, tables, objects_doc if objects_doc is Dictionary else {})
	report["camera"] = _camera_step(trace)
	report["transitions"] = _transitions(trace, level, tables, objects_doc if objects_doc is Dictionary else {})
	report["objects"] = _objects_step(trace, level, tables, objects_doc if objects_doc is Dictionary else {})
	report["interactions"] = _interactions_step(trace, level, tables, objects_doc if objects_doc is Dictionary else {})
	report["spawns"] = _spawn_step(trace, level, tables, objects_doc if objects_doc is Dictionary else {})
	if objects_doc is Dictionary and objects_doc.has("golf"):
		report["golf"] = _golf_step(trace, objects_doc["golf"])
	if screen_docs.has("golf_building"):
		report["golf_building"] = _golf_building_step(trace, screen_docs["golf_building"],
				objects_doc.get("room_animation", {}) if objects_doc is Dictionary else {})
	var clear_path: String = content_dir.path_join("clear.json")
	if FileAccess.file_exists(clear_path) and trace.has("clear_updates"):
		report["clear"] = _clear_step(trace, JSON.parse_string(FileAccess.get_file_as_string(clear_path)),
				objects_doc.get("room_animation", {}) if objects_doc is Dictionary else {})
	var action_help_path: String = content_dir.path_join("action_help.json")
	if FileAccess.file_exists(action_help_path) and trace.has("action_help_updates"):
		report["action_help"] = _action_help_step(trace,
				JSON.parse_string(FileAccess.get_file_as_string(action_help_path)),
				objects_doc.get("room_animation", {}) if objects_doc is Dictionary else {})
	var pause_menu_path: String = content_dir.path_join("pause_menu.json")
	if FileAccess.file_exists(pause_menu_path) and trace.has("pause_menu_updates"):
		report["pause_menu"] = _pause_menu_step(trace, JSON.parse_string(FileAccess.get_file_as_string(pause_menu_path)),
				truth)
	var overworld_path: String = content_dir.path_join("overworld.json")
	if FileAccess.file_exists(overworld_path) and trace.has("overworld_updates"):
		report["overworld"] = _overworld_step(trace, JSON.parse_string(FileAccess.get_file_as_string(overworld_path)))
	var title_path: String = content_dir.path_join("title.json")
	if FileAccess.file_exists(title_path) and trace.has("title_updates"):
		report["title"] = _title_step(trace, JSON.parse_string(FileAccess.get_file_as_string(title_path)))
	if FileAccess.file_exists(title_path) and trace.has("language_selection_updates"):
		report["language_selection"] = _language_selection_step(trace,
				JSON.parse_string(FileAccess.get_file_as_string(title_path)))
	if screen_docs.has("credits"):
		report["credits"] = _credits_step(trace, screen_docs["credits"])
	if screen_docs.has("game_over"):
		report["game_over"] = _game_over_step(trace, screen_docs["game_over"])
	if screen_docs.has("perfect"):
		report["perfect"] = _perfect_step(trace, screen_docs["perfect"])
	report["trace"] = String(args.get("trace", ""))
	report["level"] = level_number
	report["window"] = [window_start, window_end]
	var out: String = String(args.get("out", ""))
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  ", true))
		file.close()
	return [report, 0]


## loop_counts and golf_visits. A visit's loops are the tracer's count of _GolfStateTable calls
## (golf_loops); the frames cannot tell them exactly, since the short loop that enters golf may run
## before or after its frame is sampled. With golf_updates, golf runs natively on each loop's joypad
## (golf_inputs) and its rDIV reads (choosing a hole). An older trace's golf reads are dropped and the
## port replays each visit's length and outcome instead (LevelSim.golf_queue); without golf_loops,
## the visits have no loops, and the port stops there.
func _count_loops(trace: Dictionary) -> void:
	var frames: Array = trace["frames"]
	loop_counts.resize(frames.size())
	var start: int = -1
	for f: int in frames.size():
		loop_counts[f] = 0 if f == 0 else loop_counts[f - 1] + (
				(_v(frames[f], "wGlobalCounter") - _v(frames[f - 1], "wGlobalCounter")) & 0xFF)
		var golf: bool = _v(frames[f], "wState") == GOLF_STATE
		if golf and start < 0:
			start = f
		elif not golf and start >= 0:
			var loops: int = -1
			for counted: Array in trace.get("golf_loops", []):
				if int(counted[0]) >= start - 1 and int(counted[0]) <= f:
					loops = int(counted[1])
			golf_visits.append([start, f, loops, _v(frames[f], "wNumCoins"), _v(frames[f], "wIsMinigameCleared")])
			start = -1
	if trace.has("div_reads") and not golf_visits.is_empty():
		var in_golf: Callable = func(read: Array) -> bool:
			return golf_visits.any(func(visit: Array) -> bool:
				return int(read[0]) >= int(visit[0]) and int(read[0]) <= int(visit[1]))
		golf_div_reads = trace["div_reads"].filter(in_golf)
		if not trace.has("golf_updates"):
			trace["div_reads"] = trace["div_reads"].filter(func(read: Array) -> bool: return not in_golf.call(read))
	if trace.has("golf_updates"):
		var down_at: int = -1
		var pressed_at: int = -1
		for i: int in trace["golf_variables"].size():
			match String(trace["golf_variables"][i]["name"]):
				"wJoypadDown":
					down_at = i
				"wJoypadPressed":
					pressed_at = i
		for entry: Array in trace["golf_updates"]:
			golf_inputs.append([int(entry[0]), int(entry[1][down_at]), int(entry[1][pressed_at])])


## Golf's data and the joypad of every golf loop after `frame`, when the trace has them; otherwise
## the replay of the visits after it (golf_queue).
func _attach_golf(sim: LevelSim, frame: int, objects_doc: Dictionary) -> void:
	sim.golf_replay = true
	sim.golf_queue = _golf_queue(frame)
	if not objects_doc.has("golf"):
		return
	sim.load_golf_data(objects_doc["golf"])
	sim.golf_input = golf_inputs.filter(func(input: Array) -> bool: return int(input[0]) > frame).map(
			func(input: Array) -> Array: return [input[1], input[2]])


## The golf visits after `frame`, as LevelSim.golf_queue takes them.
func _golf_queue(frame: int) -> Array:
	var queue: Array = []
	for visit: Array in golf_visits:
		if int(visit[0]) > frame:
			queue.append([int(visit[2]), int(visit[3]), int(visit[4])])
	return queue


## Game loops between the updates of two frames, from their wGlobalCounter values: the difference
## wraps at 256, so the loops the frames between counted unwrap it (golf, a long pause).
func _loops_between(from_frame: int, to_frame: int, from_counter: int, to_counter: int) -> int:
	var loops: int = (to_counter - from_counter - 1) & 0xFF
	if from_frame < 0 or to_frame >= loop_counts.size():
		return loops
	var counted: int = loop_counts[to_frame] - loop_counts[from_frame] - 1
	return loops + 256 * roundi(float(counted - loops) / 256.0)


## The golf minigame a game loop at a time (WL3-050): from each golf_updates entry the native
## GolfSim runs one loop (with the V-Blank after it) and is compared with the next entry of the same
## visit, on the golf RAM traced and the variables (the joypad and the counter are the next loop's).
func _golf_step(trace: Dictionary, golf_doc: Variant) -> Dictionary:
	var updates: Array = trace.get("golf_updates", [])
	if updates.is_empty() or not golf_doc is Dictionary:
		return {"checked": false}
	var golf_names: PackedStringArray = PackedStringArray()
	for variable: Dictionary in trace["golf_variables"]:
		golf_names.append(String(variable["name"]))
	var counter_at: int = golf_names.find("wGlobalCounter")
	var reads: Dictionary = {}
	for read: Array in golf_div_reads:
		if not reads.has(int(read[0])):
			reads[int(read[0])] = []
		reads[int(read[0])].append(read)
	var matched: int = 0
	var mismatched: int = 0
	var unported: Dictionary = {}
	var by_state: Dictionary = {}
	var examples: Array = []
	# The VRAM the golf screens drew, against the trace's snapshots (on the bytes golf wrote).
	var snapshots: Dictionary = {}
	for snapshot: Array in trace.get("golf_vram", []):
		snapshots[int(snapshot[0])] = snapshot
	var vram := GolfVram.new(golf_doc)
	var vram_checked: int = 0
	var vram_matched: int = 0
	var vram_examples: Array = []
	# The screens shown, against the original's (outside the fades and the inits).
	var screens: Dictionary = {}
	for screen: Array in trace.get("golf_screens", []):
		screens[int(screen[0])] = screen[1]
	var substate_at: int = golf_names.find("wSubState")
	var screens_checked: int = 0
	var screens_matched: int = 0
	var screen_examples: Array = []
	for i: int in updates.size() - 1:
		var entry: Array = updates[i]
		var next: Array = updates[i + 1]
		if i > 0 and int(entry[1][counter_at]) != (int(updates[i - 1][1][counter_at]) + 1) & 0xFF:
			vram = GolfVram.new(golf_doc)  # a new visit
		if snapshots.has(i):
			vram_checked += 1
			var vram_diffs: Array = _vram_diffs(vram, snapshots[i])
			if vram_diffs.is_empty():
				vram_matched += 1
			elif vram_examples.size() < MAX_EXAMPLES:
				vram_examples.append({"frame": int(entry[0]), "screen": vram.screen, "diffs": vram_diffs})
		if screens.has(i) and i > 0 and entry.size() > 3 and int(entry[1][substate_at]) in [3, 7, 13] \
				and int(updates[i - 1][1][substate_at]) == int(entry[1][substate_at]):
			screens_checked += 1
			var screen_diffs: Array = _screen_diffs(vram, golf_names, entry, screens[i])
			if screen_diffs.is_empty():
				screens_matched += 1
			elif screen_examples.size() < MAX_EXAMPLES:
				screen_examples.append({"frame": int(entry[0]), "screen": vram.screen, "diffs": screen_diffs})
		if int(next[1][counter_at]) != (int(entry[1][counter_at]) + 1) & 0xFF:
			continue  # the visit's last loop (or the next visit)
		var sim := LevelSim.new()
		var golf := GolfSim.new(sim)
		golf.load_data(golf_doc)
		_load_golf(sim, golf, golf_names, entry)
		var loop_reads: Array = []
		for frame: int in range(int(entry[0]), int(next[0]) + 1):
			loop_reads.append_array(reads.get(frame, []))
		_feed_div(sim, loop_reads)
		var key: String = "sub-state %d, state %d" % [sim.wSubState, golf.rb(GolfSim.W_GOLF_HOLE_STATE)]
		golf.update()
		vram.update(golf)
		if not golf.unported.is_empty():
			for note: String in golf.unported:
				unported[note] = int(unported.get(note, 0)) + 1
			continue
		var diffs: Dictionary = _golf_diffs(sim, golf, golf_names, next)
		if not by_state.has(key):
			by_state[key] = {"matched": 0, "mismatched": 0}
		if diffs.is_empty():
			matched += 1
			by_state[key]["matched"] += 1
		else:
			mismatched += 1
			by_state[key]["mismatched"] += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": int(entry[0]), "state": key, "diffs": diffs})
	return {"checked": true, "loops": updates.size(), "matched": matched, "mismatched": mismatched,
			"unported": unported, "by_state": by_state, "examples": examples,
			"vram": {"checked": vram_checked, "matched": vram_matched, "examples": vram_examples},
			"screens": {"checked": screens_checked, "matched": screens_matched, "examples": screen_examples}}


## The pixels of the frame shown at a golf loop that differ from the original's screen: the
## registers are those the last V-Blank set (the hole's LCDC and window from golf RAM, the lobby's and
## cutscene's LCDC_DEFAULT).
var cgb_screen := CgbScreen.new()


func _screen_diffs(vram: GolfVram, golf_names: PackedStringArray, entry: Array, screen: String) -> Array:
	var ram: PackedByteArray = String(entry[2]).hex_decode()
	var hole: bool = vram.screen == "hole"
	var lcdc: int = ram[6 + GolfSim.W_GOLF_LCD_CONFIG - 0xDB40] if hole else GolfSim.LCDC_DEFAULT
	var wx: int = ram[6 + GolfSim.W_GOLF_WX - 0xDB40] if hole else 0
	return _pixel_diffs(vram, String(entry[3]).hex_decode(), lcdc, int(entry[1][golf_names.find("wSCX")]),
			int(entry[1][golf_names.find("wSCY")]), wx, screen)


## The pixels of a frame drawn from `vram`, the OAM, and the registers that differ from the
## original's screen (gzipped RGB in base64): [x, y, native, original] (at most 8, then the count).
func _pixel_diffs(vram: ScreenVram, oam: PackedByteArray, lcdc: int, scx: int, scy: int, wx: int, screen: String,
		line_writes: Array = [], wy: int = 0, scx_lines: Array = [], scy_lines: Array = []) -> Array:
	var native: PackedByteArray = cgb_screen.render(vram, oam, lcdc, scx, scy, wx, wy, line_writes, scx_lines,
			scy_lines)
	var original: PackedByteArray = Marshalls.base64_to_raw(screen).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var diffs: Array = []
	var count: int = 0
	for pixel: int in CgbScreen.WIDTH * CgbScreen.HEIGHT:
		var at: int = pixel * 3
		if native[at] != original[at] or native[at + 1] != original[at + 1] or native[at + 2] != original[at + 2]:
			count += 1
			if diffs.size() < 8:
				diffs.append([pixel % CgbScreen.WIDTH, pixel / CgbScreen.WIDTH, native.slice(at, at + 3), original.slice(at, at + 3)])
	if count > diffs.size():
		diffs.append(count)
	return diffs


## The VRAM bytes golf wrote that differ from a snapshot: [bank, address, native, original] (at most 8,
## then the count).
func _vram_diffs(vram: ScreenVram, snapshot: Array) -> Array:
	var diffs: Array = []
	var count: int = 0
	for bank: int in 2:
		var original: PackedByteArray = String(snapshot[1 + bank]).hex_decode()
		for offset: int in ScreenVram.VRAM_SIZE:
			if vram.written[bank][offset] != 0 and vram.vram[bank][offset] != original[offset]:
				count += 1
				if diffs.size() < 8:
					diffs.append([bank, "%04x" % (0x8000 + offset), vram.vram[bank][offset], original[offset]])
	if count > diffs.size():
		diffs.append(count)
	return diffs


## The level's clear screen a game loop at a time (WL3-043): from each clear_updates entry, the
## ClearSim (one a visit, which keeps the V-Blank function the loops leave) runs one loop and the
## main loop's room animation after it, and is compared with the next entry of the same visit on
## its variables (the joypad and the counter are the next loop's), its RAM, and the virtual OAM.
func _clear_step(trace: Dictionary, clear_doc: Variant, animation: Dictionary = {}) -> Dictionary:
	var updates: Array = trace.get("clear_updates", [])
	if updates.is_empty() or not clear_doc is Dictionary:
		return {"checked": false}
	var clear_names: PackedStringArray = PackedStringArray()
	for variable: Dictionary in trace["clear_variables"]:
		clear_names.append(String(variable["name"]))
	var ranges: Array = trace.get("clear_ram", [])
	var counter_at: int = clear_names.find("wGlobalCounter")
	var calls: Dictionary = {}
	for call: Array in trace.get("animation_calls", []):
		if not calls.has(int(call[0])):
			calls[int(call[0])] = []
		calls[int(call[0])].append([int(call[1]), int(call[2])])
	var matched: int = 0
	var mismatched: int = 0
	var unported: Dictionary = {}
	var by_state: Dictionary = {}
	var examples: Array = []
	var sim := LevelSim.new()
	var clear := ClearSim.new()
	clear.load_data(clear_doc)
	var exits: Array = []
	# The VRAM the clear screens drew and the screens shown, against the trace's (as golf's).
	var snapshots: Dictionary = {}
	for snapshot: Array in trace.get("clear_vram", []):
		snapshots[int(snapshot[0])] = snapshot
	var screens: Dictionary = {}
	for screen: Array in trace.get("clear_screens", []):
		screens[int(screen[0])] = screen[1]
	var vram := ClearVram.new(clear_doc, animation)
	var copies: Dictionary = {}  # frame -> the lines of the animated tiles chunks copied in it
	for copy: Array in trace.get("animation_copies", []):
		if not copies.has(int(copy[0])):
			copies[int(copy[0])] = []
		copies[int(copy[0])].append(int(copy[1]))
	var substate_at: int = clear_names.find("wSubState")
	var drawn: Dictionary = {"vram_checked": 0, "vram_matched": 0, "screens_checked": 0, "screens_matched": 0,
			"examples": []}
	for i: int in updates.size():
		if i == updates.size() - 1:
			var last: Dictionary = _clear_exit(trace, sim, clear, clear_names, ranges, updates[i])
			if not last.is_empty():
				exits.append(last)
			break
		var entry: Array = updates[i]
		var next: Array = updates[i + 1]
		if i > 0 and int(entry[1][counter_at]) != (int(updates[i - 1][1][counter_at]) + 1) & 0xFF:
			sim = LevelSim.new()  # a new visit
			clear = ClearSim.new()
			clear.load_data(clear_doc)
			vram = ClearVram.new(clear_doc, animation)
		if snapshots.has(i):
			drawn["vram_checked"] += 1
			var vram_diffs: Array = _vram_diffs(vram, snapshots[i])
			if vram_diffs.is_empty():
				drawn["vram_matched"] += 1
			elif drawn["examples"].size() < MAX_EXAMPLES:
				drawn["examples"].append({"frame": int(entry[0]), "screen": vram.screen, "vram": vram_diffs})
		if int(next[1][counter_at]) != (int(entry[1][counter_at]) + 1) & 0xFF:
			# The visit's last loop: what it leaves is in the first frame after the clear screen.
			var exit: Dictionary = _clear_exit(trace, sim, clear, clear_names, ranges, entry)
			if not exit.is_empty():
				exits.append(exit)
			continue
		_screen_load(sim, clear, clear_names, ranges, entry)
		sim.animation_replay = trace.has("animation_calls")
		sim.animation_queue.clear()
		sim.animation_mismatches.clear()
		for frame: int in range(int(entry[0]), int(next[0]) + 1):
			sim.animation_queue.append_array(calls.get(frame, []))
		var key: String = "sub-state %d" % sim.wSubState
		sim.wState = LevelSim.ST_CLEAR
		var before: ScreenVram = vram.copy() if screens.has(i) else null
		sim.update_level()
		vram.update(clear, sim)
		if not sim.unported.is_empty():
			for note: String in sim.unported:
				unported[note] = int(unported.get(note, 0)) + 1
			continue
		# The frame shown while this loop ran: the VRAM before it, with an animated tiles frame the loop
		# copied appearing chunk by chunk from the lines after their H-Blanks.
		if before != null and i > 0 and int(entry[1][substate_at]) in [3, 7, 11, 12, 13, 14] \
				and int(updates[i - 1][1][substate_at]) == int(entry[1][substate_at]):
			drawn["screens_checked"] += 1
			var line_writes: Array = []
			if vram.animation_written:
				var chunk: int = 0
				for line: int in copies.get(int(entry[0]), []):
					line_writes.append([line, 1, 0x9700 + chunk * 8, vram.vram[1].slice(0x1700 + chunk * 8, 0x1700 + chunk * 8 + 8)])
					chunk += 1
			var pixels: Array = _pixel_diffs(before, String(entry[3]).hex_decode(), GolfSim.LCDC_DEFAULT,
					int(entry[1][clear_names.find("wSCX")]), int(entry[1][clear_names.find("wSCY")]), 0, screens[i],
					line_writes)
			if pixels.is_empty():
				drawn["screens_matched"] += 1
			elif drawn["examples"].size() < MAX_EXAMPLES:
				drawn["examples"].append({"frame": int(entry[0]), "screen": vram.screen, "pixels": pixels})
		var diffs: Dictionary = _screen_state_diffs(sim, clear, clear_names, ranges, next)
		if not sim.animation_mismatches.is_empty():
			diffs["animation calls"] = Array(sim.animation_mismatches)
		if not by_state.has(key):
			by_state[key] = {"matched": 0, "mismatched": 0}
		if diffs.is_empty():
			matched += 1
			by_state[key]["matched"] += 1
		else:
			mismatched += 1
			by_state[key]["mismatched"] += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": int(entry[0]), "state": key, "diffs": diffs})
	sim.clear = null
	var exits_matched: int = exits.filter(func(exit: Dictionary) -> bool: return exit["diffs"].is_empty()).size()
	return {"checked": true, "loops": updates.size(), "matched": matched, "mismatched": mismatched,
			"unported": unported, "by_state": by_state, "examples": examples,
			"exits": {"checked": exits.size(), "matched": exits_matched, "results": exits}, "drawn": drawn}


const CLEAR_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState", "wDayNight", "wAnimatedTilesFrameDuration",
		"wAnimatedTilesGfx", "wAnimatedTilesFrameCount", "wAnimatedTilesFrame"]


## A visit's last clear screen loop, when it leaves (sub-state SST_CLEAR_EXIT): run, and compared
## with the trace's first frame out of the clear screen on what the exit sets (the map's or Action
## Help's state, wDayNight, the animated tiles).
func _clear_exit(trace: Dictionary, sim: LevelSim, clear: ClearSim, clear_names: PackedStringArray,
		ranges: Array, entry: Array) -> Dictionary:
	if int(entry[1][clear_names.find("wSubState")]) != ClearSim.SST_CLEAR_EXIT:
		return {}
	var frames: Array = trace["frames"]
	var after: int = -1
	for frame: int in range(int(entry[0]), frames.size()):
		if _v(frames[frame], "wState") != LevelSim.ST_CLEAR:
			after = frame
			break
	if after < 0:
		return {}
	_screen_load(sim, clear, clear_names, ranges, entry)
	sim.wState = LevelSim.ST_CLEAR
	sim.update_level()
	var diffs: Dictionary = _diffs(sim, frames[after], CLEAR_EXIT_COMPARED)
	return {"frame": after, "state": [sim.wState, sim.wSubState], "unported": Array(sim.unported), "diffs": diffs}


## A screen on WRAMX bank 3's menu objects a game loop at a time, as the clear screen: from each of
## its `key`_updates entries the screen (one a visit) runs one loop and the room animation after it,
## and is compared with the next entry of the same visit; a visit's last loop is compared with the
## first frame after the screen on what its way out sets. With a VRAM model, every snapshot and the
## screens of the loops `spec.drawn` names are compared too. `spec`: "state" (its wState), "make"
## (a new screen with its data), "vram" (a new VRAM model, or null), "key" (a loop's state for the
## report), "ported" (whether the port covers a loop), "lcdc", "drawn", and "exit" (what the way
## out is compared on).
func _menu_screen_step(trace: Dictionary, key: String, spec: Dictionary) -> Dictionary:
	var updates: Array = trace.get(key + "_updates", [])
	if updates.is_empty():
		return {"checked": false}
	var screen_names: PackedStringArray = PackedStringArray()
	for variable: Dictionary in trace[key + "_variables"]:
		screen_names.append(String(variable["name"]))
	var ranges: Array = trace.get(key + "_ram", [])
	var counter_at: int = screen_names.find("wGlobalCounter")
	var calls: Dictionary = {}
	for call: Array in trace.get("animation_calls", []):
		if not calls.has(int(call[0])):
			calls[int(call[0])] = []
		calls[int(call[0])].append([int(call[1]), int(call[2])])
	var matched: int = 0
	var mismatched: int = 0
	var unported: Dictionary = {}
	var by_state: Dictionary = {}
	var examples: Array = []
	var exits: Array = []
	var sim := LevelSim.new()
	var screen: ScreenSim = spec["make"].call()
	var snapshots: Dictionary = {}
	for snapshot: Array in trace.get(key + "_vram", []):
		snapshots[int(snapshot[0])] = snapshot
	var screens: Dictionary = {}
	for shown: Array in trace.get(key + "_screens", []):
		screens[int(shown[0])] = shown[1]
	var substate_at: int = screen_names.find("wSubState")
	var vram: Variant = spec["vram"].call() if spec.get("vram") is Callable else null
	# The VRAM model a visit draws with, and whether its screens are compared: spec "visit" decides by
	# the previous visit's model and the visit's first sub-state.
	var visit_drawn: bool = true
	if spec.get("visit") is Callable:
		var visit: Array = spec["visit"].call(null, int(updates[0][1][substate_at]))
		vram = visit[0]
		visit_drawn = visit[1]
	var copies: Dictionary = {}  # frame -> the lines of the animated tiles chunks copied in it
	for copy: Array in trace.get("animation_copies", []):
		if not copies.has(int(copy[0])):
			copies[int(copy[0])] = []
		copies[int(copy[0])].append(int(copy[1]))
	var drawn: Dictionary = {"vram_checked": 0, "vram_matched": 0, "screens_checked": 0, "screens_matched": 0,
			"examples": []}
	var skipped: bool = false
	var vblank_unknown: bool = true  # at a visit's start, and after loops the port did not run
	var visit_start: bool = true
	for i: int in updates.size():
		var entry: Array = updates[i]
		if i > 0 and not _next_loop(spec, updates[i - 1], entry, counter_at, substate_at):
			sim = LevelSim.new()  # a new visit
			skipped = false
			vblank_unknown = true
			visit_start = true
			screen = spec["make"].call()
			if spec.get("visit") is Callable:
				var visit: Array = spec["visit"].call(vram, int(entry[1][substate_at]))
				vram = visit[0]
				visit_drawn = visit[1]
			else:
				vram = spec["vram"].call() if spec.get("vram") is Callable else null
		if not spec["ported"].call(int(entry[1][substate_at])):
			var why: String = spec["why"].call(int(entry[1][substate_at])) if spec.get("why") is Callable else "not ported"
			var note: String = "%s sub-state %d (%s)" % [key, int(entry[1][substate_at]), why]
			unported[note] = int(unported.get(note, 0)) + 1
			skipped = true
			continue
		if skipped:
			# Loops the port did not run left a V-Blank function it does not know: taken as one
			# that writes no traced RAM.
			screen.vblank_func = ScreenSim.VBLANK_NONE
			screen.vblank_set_aside = ScreenSim.VBLANK_NONE
			skipped = false
			vblank_unknown = true
		if visit_start and vram != null and spec.get("visit_load") is Callable:
			# What another screen's loop drew for this visit before it (spec "visit_load"), from the
			# visit's first loop's RAM.
			_screen_load(sim, screen, screen_names, ranges, entry)
			spec["visit_load"].call(vram, screen, int(entry[1][substate_at]))
		visit_start = false
		if vram != null and snapshots.has(i):
			drawn["vram_checked"] += 1
			var vram_diffs: Array = _vram_diffs(vram, snapshots[i])
			if vram_diffs.is_empty():
				drawn["vram_matched"] += 1
			elif drawn["examples"].size() < MAX_EXAMPLES:
				drawn["examples"].append({"frame": int(entry[0]), "screen": vram.screen, "vram": vram_diffs})
		if i == updates.size() - 1 or not _next_loop(spec, entry, updates[i + 1], counter_at, substate_at):
			# The visit's last loop: what it leaves is in the first frame after the screen.
			var exit: Dictionary = _menu_screen_exit(trace, sim, screen, screen_names, ranges, entry, spec)
			if not exit.is_empty():
				exits.append(exit)
			continue
		var next: Array = updates[i + 1]
		_screen_load(sim, screen, screen_names, ranges, entry)
		if spec.get("load") is Callable:
			spec["load"].call(sim, screen, entry)
		if vblank_unknown and spec.get("vblank") is Callable:
			# The V-Blank function the screen's state implies, where it does (spec "vblank").
			screen.vblank_func = spec["vblank"].call(sim, screen, screen.vblank_func)
		vblank_unknown = false
		sim.animation_replay = trace.has("animation_calls")
		sim.animation_queue.clear()
		sim.animation_mismatches.clear()
		for frame: int in range(int(entry[0]), int(next[0]) + 1):
			sim.animation_queue.append_array(calls.get(frame, []))
		# The loop's rDIV reads: those between its start and the next loop's (newer traces count them).
		var div_fed: bool = entry.size() > 4 and next.size() > 4
		if div_fed:
			_feed_div(sim, trace.get("div_reads", []).slice(int(entry[4]), int(next[4])))
		var state_key: String = spec["key"].call(sim, screen)
		sim.wState = int(spec["state"])
		var before: ScreenVram = vram.copy() if vram != null and screens.has(i) else null
		sim.update_level()
		if vram != null:
			vram.update(screen, sim)
		if not sim.unported.is_empty():
			for note: String in sim.unported:
				unported[note] = int(unported.get(note, 0)) + 1
			continue
		# The frame shown while this loop ran: the VRAM before it, with a room animation's tiles
		# appearing chunk by chunk from the lines after their H-Blanks. A loop that ran in the tick of
		# the loop before is not compared: the screen that tick ends with shows the earlier loop.
		if before != null and i > 0 and visit_drawn and int(updates[i - 1][0]) != int(entry[0]) \
				and spec["drawn"].call(int(entry[1][substate_at]), int(updates[i - 1][1][substate_at])):
			drawn["screens_checked"] += 1
			var line_writes: Array = []
			if vram.animation_written:
				var chunk: int = 0
				for line: int in copies.get(int(entry[0]), []):
					line_writes.append([line, 1, 0x9700 + chunk * 8, vram.vram[1].slice(0x1700 + chunk * 8, 0x1700 + chunk * 8 + 8)])
					chunk += 1
			# The registers: the spec's, or by the VRAM model before the loop (spec "lcdc", "window").
			var lcdc: int = int(spec["lcdc"].call(before)) if spec["lcdc"] is Callable else int(spec["lcdc"])
			var window: Vector2i = spec["window"].call(before) if spec.get("window") is Callable else Vector2i.ZERO
			# The scroll the loop wrote mid-frame (spec "scx_lines", "scy_lines").
			var scx_lines: Array = spec["scx_lines"].call(screen, sim) if spec.get("scx_lines") is Callable else []
			var scy_lines: Array = spec["scy_lines"].call(screen, sim) if spec.get("scy_lines") is Callable else []
			var pixels: Array = _pixel_diffs(before, String(entry[3]).hex_decode(), lcdc,
					int(entry[1][screen_names.find("wSCX")]), int(entry[1][screen_names.find("wSCY")]), window.x,
					screens[i], line_writes, window.y, scx_lines, scy_lines)
			if pixels.is_empty():
				drawn["screens_matched"] += 1
			elif drawn["examples"].size() < MAX_EXAMPLES:
				drawn["examples"].append({"frame": int(entry[0]), "screen": vram.screen, "pixels": pixels})
		var diffs: Dictionary = _screen_state_diffs(sim, screen, screen_names, ranges, next)
		if not sim.animation_mismatches.is_empty():
			diffs["animation calls"] = Array(sim.animation_mismatches)
		if div_fed and not _div_diffs(sim).is_empty():
			diffs["rDIV reads"] = Array(_div_diffs(sim))
		if not by_state.has(state_key):
			by_state[state_key] = {"matched": 0, "mismatched": 0}
		if diffs.is_empty():
			matched += 1
			by_state[state_key]["matched"] += 1
		else:
			mismatched += 1
			by_state[state_key]["mismatched"] += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": int(entry[0]), "state": state_key, "diffs": diffs})
	_screen_detach(sim)
	var exits_matched: int = exits.filter(func(exit: Dictionary) -> bool: return exit["diffs"].is_empty()).size()
	var report: Dictionary = {"checked": true, "loops": updates.size(), "matched": matched, "mismatched": mismatched,
			"unported": unported, "by_state": by_state, "examples": examples,
			"exits": {"checked": exits.size(), "matched": exits_matched, "results": exits}}
	if spec.get("vram") is Callable:
		report["drawn"] = drawn
	return report


## Whether `next` is the loop after `entry` in one visit: wGlobalCounter one on, or what spec "next"
## allows besides (a loop that clears the counter).
func _next_loop(spec: Dictionary, entry: Array, next: Array, counter_at: int, substate_at: int) -> bool:
	if int(next[1][counter_at]) == (int(entry[1][counter_at]) + 1) & 0xFF:
		return true
	return spec.get("next") is Callable and spec["next"].call(int(entry[1][substate_at]), int(next[1][counter_at]))


## A visit's last loop: run, and compared with the trace's first frame out of the screen's wState; or,
## when the loop reset the game (Init, which takes frames), or the next loop did (A, B, Select and
## Start held: _reset_joypad), with the title's first loop after it (_init_diffs). The step check
## keeps no SRAM: Init loads the save the movie powered on with (right while the movie has made no
## save before).
func _menu_screen_exit(trace: Dictionary, sim: LevelSim, screen: ScreenSim, screen_names: PackedStringArray,
		ranges: Array, entry: Array, spec: Dictionary) -> Dictionary:
	var frames: Array = trace["frames"]
	_screen_load(sim, screen, screen_names, ranges, entry)
	if spec.get("load") is Callable:
		spec["load"].call(sim, screen, entry)
	sim.wState = int(spec["state"])
	if power_on_save != null:
		sim.loaded_sram = SaveLoad.sram_banks(power_on_save)
	var resets: int = sim.resets
	sim.update_level()
	var next_counter: int = (int(entry[1][screen_names.find("wGlobalCounter")]) + 1) & 0xFF
	var held: int = _reset_joypad(range(int(entry[0]), mini(int(entry[0]) + 0x20, frames.size())), next_counter)
	if sim.resets == resets and held >= 0:
		sim.wGlobalCounter = next_counter
		sim.wJoypadPressed = held & ~sim.wJoypadDown & 0xFF
		sim.wJoypadDown = held
		sim.update_level()
	if sim.resets != resets:
		for title_entry: Array in trace.get("title_updates", []):
			if int(title_entry[0]) > int(entry[0]):  # Init takes frames
				return {"frame": int(title_entry[0]), "state": [sim.wState, sim.wSubState], "unported": Array(sim.unported),
						"diffs": _init_diffs(trace, sim, title_entry), "reset": true}
		return {}
	var after: int = -1
	for frame: int in range(int(entry[0]), frames.size()):
		if _v(frames[frame], "wState") != int(spec["state"]):
			after = frame
			break
	if after < 0:
		return {}
	# A frame sampled while the last loop still ran (it shared its tick with the loop before) shows it
	# before the main loop's room animation: the next frame, of the next loop's counter, shows what it left.
	if _v(frames[after], "wGlobalCounter") == (next_counter - 1) & 0xFF and after + 1 < frames.size() \
			and _v(frames[after + 1], "wGlobalCounter") == next_counter:
		after += 1
	var diffs: Dictionary = _diffs(sim, frames[after], spec["exit"])
	for compared: Array in spec.get("exit_ram", []):
		var native: int = screen.ram_read(int(compared[1]), int(compared[2]))
		if native != _v(frames[after], String(compared[0])):
			diffs[String(compared[0])] = [native, _v(frames[after], String(compared[0]))]
	return {"frame": after, "state": [sim.wState, sim.wSubState], "unported": Array(sim.unported), "diffs": diffs}


## What Init left (`sim` after init_game) against the title's first loop after it (`title_entry`): the
## title's variables but the counter and the joypad (the loop's own), the LevelSim's where it keeps
## them, else the RAM's; and the title's RAM ranges, byte for byte.
func _init_diffs(trace: Dictionary, sim: LevelSim, title_entry: Array) -> Dictionary:
	var diffs: Dictionary = {}
	var variables: Array = trace["title_variables"]
	for i: int in variables.size():
		var name: String = variables[i]["name"]
		var address: int = String(variables[i]["address"]).hex_to_int()
		if name in ["wGlobalCounter", "wJoypadDown", "wJoypadPressed"]:
			continue
		var native: int = int(sim.get(name)) if name in sim else int(sim.screen_wram[0][address - 0xC000])
		if native != int(title_entry[1][i]):
			diffs[name] = [native, int(title_entry[1][i])]
	var bytes: PackedByteArray = String(title_entry[2]).hex_decode()
	var at: int = 0
	for range_: Dictionary in trace.get("title_ram", []):
		var bank: int = int(range_["bank"])
		var start: int = String(range_["address"]).hex_to_int()
		for offset: int in int(range_["size"]):
			var native: int = int(sim.screen_wram[bank][start + offset - (0xC000 if bank == 0 else 0xD000)])
			if native != bytes[at] and diffs.size() < 16:
				diffs["$%04x" % (start + offset)] = [native, bytes[at]]
			at += 1
	return diffs


## Action Help a game loop at a time (WL3-051): its demos keyed by power-up and state; drawn from its
## screen's second loop on (BG map 1).
func _action_help_step(trace: Dictionary, document: Variant, animation: Dictionary = {}) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var help := ActionHelpSim.new()
		help.load_data(document)
		return help
	var state_key := func(sim: LevelSim, help: MenuScreenSim) -> String:
		if sim.wSubState != 3:
			return "sub-state %d" % sim.wSubState
		return "power-up %d state %d" % [help.r3(ActionHelpSim.W_ACTION_HELP_POWER_UP),
				help.r3(ActionHelpSim.W_ACTION_HELP_STATE)]
	return _menu_screen_step(trace, "action_help", {"state": ClearSim.ST_ACTION_HELP, "make": make,
		"vram": func() -> ScreenVram: return ActionHelpVram.new(document, animation), "key": state_key,
		"ported": func(_substate: int) -> bool: return true, "lcdc": GolfSim.LCDC_BGMAP1,
		"drawn": func(substate: int, previous: int) -> bool: return substate == 3 and previous == 3,
		"exit": ACTION_HELP_EXIT_COMPARED})


const ACTION_HELP_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState", "wDayNight", "wPowerUpLevel",
		"wAnimatedTilesFrameDuration", "wAnimatedTilesGfx", "wAnimatedTilesFrameCount", "wAnimatedTilesFrame"]


## The golf building a game loop at a time (WL3-050): its course menu (Func_1c8586, Func_1c86dd) and its
## courses' holes, GolfSim in ST_GOLF_BUILDING with the room animation after each loop; drawn (GolfVram)
## on the menu's and the holes' loops after their first, with the LCD registers the last V-Blank set;
## the way out (ReturnToMap) compared with the map's first frame.
func _golf_building_step(trace: Dictionary, document: Variant, animation: Dictionary = {}) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> ScreenSim:
		var golf := GolfSim.new()
		golf.load_data(document)
		return golf
	var state_key := func(sim: LevelSim, golf: ScreenSim) -> String:
		match sim.wSubState:
			3:
				return "menu state %d" % (golf as GolfSim).rb(GolfSim.W1DC00)
			7:
				return "hole state %d" % (golf as GolfSim).rb(GolfSim.W_GOLF_HOLE_STATE)
		return "sub-state %d" % sim.wSubState
	return _menu_screen_step(trace, "golf_building", {"state": LevelSim.ST_GOLF_BUILDING, "make": make,
		"vram": func() -> ScreenVram: return GolfVram.new(document, animation), "key": state_key,
		"ported": func(_substate: int) -> bool: return true,
		"lcdc": func(vram: ScreenVram) -> int: return (vram as GolfVram).lcdc,
		"window": func(vram: ScreenVram) -> Vector2i: return Vector2i((vram as GolfVram).wx, 0),
		"drawn": func(substate: int, previous: int) -> bool: return substate in [3, 7] and previous == substate,
		"exit": GOLF_BUILDING_EXIT_COMPARED})


const GOLF_BUILDING_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState", "wRoomAnimatedTilesEnabled",
		"wAnimatedTilesFrameDuration", "wAnimatedTilesGfx", "wAnimatedTilesFrameCount", "wAnimatedTilesFrame"]


## The pause menu's state table a game loop at a time (WL3-052): the pause menu from a level, the
## level's save from it (its reset, Init, left to runs), and the map's save screen (SST_PAUSE_18 on),
## drawn as the menu shows and while a save's bar fills and its box shows (PAUSE_MENU_DRAWN).
## Before each loop the level's RAM SaveLevel copies that the pause menu's trace does not record is
## taken from the trace too (_pause_menu_level_inputs).
func _pause_menu_step(trace: Dictionary, document: Variant, base: LevelCollision) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var pause := PauseMenuSim.new()
		pause.load_data(document)
		return pause
	var inputs := {"truth": MapTruth.new(base, trace), "checkpoint": -1, "next_checkpoint": 0,
			"traced": _traced_bytes(trace.get("pause_menu_ram", []))}
	return _menu_screen_step(trace, "pause_menu", {"state": LevelSim.ST_PAUSE_MENU, "make": make,
		"vram": func() -> ScreenVram: return SaveScreenVram.new(document),
		"visit": func(_previous: Variant, _substate: int) -> Array: return [SaveScreenVram.new(document), true],
		"visit_load": func(vram: ScreenVram, pause: MenuScreenSim, substate: int) -> void:
			if substate == PauseMenuSim.SST_PAUSE_INIT_MENU + 1:  # back from Action Help, whose last loop ran the init
				(vram as SaveScreenVram).load_pause_menu(pause as PauseMenuSim),
		"key": func(sim: LevelSim, _pause: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool:
			return _pause_menu_ported(substate) and not substate in [PauseMenuSim.SST_RESET_AFTER_PAUSE_MENU_SAVE,
					PauseMenuSim.SST_RESET_AFTER_SAVE],
		"why": func(substate: int) -> String:
			return ("Init, checked from power-on (MODE=run): no SRAM a loop at a time"
					if substate in [PauseMenuSim.SST_RESET_AFTER_PAUSE_MENU_SAVE, PauseMenuSim.SST_RESET_AFTER_SAVE]
					else "not ported"),
		"load": func(sim: LevelSim, pause: MenuScreenSim, entry: Array) -> void:
			_pause_menu_level_inputs(trace, inputs, sim, pause, int(entry[0])),
		"lcdc": func(vram: ScreenVram) -> int:
			return GolfSim.LCDC_BGMAP1 if vram.screen == "pause_menu" else GolfSim.LCDC_DEFAULT,
		"drawn": func(substate: int, previous: int) -> bool:
			return substate in PAUSE_MENU_DRAWN and previous == substate,
		"exit": PAUSE_MENU_EXIT_COMPARED, "exit_ram": PAUSE_MENU_EXIT_RAM})


## The pause menu's sub-states drawn: the menu (UpdatePauseMenu), and the level's and the map's save
## screens (the map's again after the Perfect screen, $28-$31) with the bar and with the "complete" box.
const PAUSE_MENU_DRAWN: Array = [0x03, 0x0B, 0x0F, 0x1B, 0x1F, 0x2B, 0x2F]


## The pause menu's sub-states the port covers: the pause menu, the level's save and its reset
## (ResetAfterPauseMenuSave, Init; the step check, which keeps no SRAM banks 1-3, leaves it to runs),
## and the map's save screen.
func _pause_menu_ported(substate: int) -> bool:
	return substate <= PauseMenuSim.SST_RESET_AFTER_PAUSE_MENU_SAVE \
			or (substate >= PauseMenuSim.SST_PAUSE_18 and substate <= 0x21) \
			or (substate >= PauseMenuSim.SST_PAUSE_28 and substate <= PauseMenuSim.SST_RESET_AFTER_SAVE)


## The level's RAM the pause menu's trace does not record, which SaveLevel copies and sums, from the
## trace before the loop of `frame` (the tick it ran in): the level map (MapTruth: SRAM banks 1 and 2),
## the level's objects (WRAMX bank 1, the last object checkpoint), and the level WRAM's shared
## variables outside the pause menu's ranges ($cac1-$cac9, from the frame before; wBossState, not
## traced, is left as it is).
func _pause_menu_level_inputs(trace: Dictionary, inputs: Dictionary, sim: LevelSim, pause: MenuScreenSim,
		frame: int) -> void:
	inputs["truth"].advance(frame)
	sim.level = inputs["truth"].level
	var checkpoints: Array = trace.get("object_checkpoints", [])
	while int(inputs["next_checkpoint"]) < checkpoints.size() \
			and int(checkpoints[int(inputs["next_checkpoint"])][0]) <= frame:
		inputs["checkpoint"] = inputs["next_checkpoint"]
		inputs["next_checkpoint"] = int(inputs["next_checkpoint"]) + 1
	if int(inputs["checkpoint"]) >= 0:
		sim.wram1 = String(checkpoints[int(inputs["checkpoint"])][3]).hex_decode()
	for name: String in PAUSE_MENU_WARIO_INPUTS:  # what ExitPauseMenu's DrawWario reads
		sim.set(name, _v(trace["frames"][maxi(frame - 1, 0)], name))
	var level_wram_end: int = PauseMenuSim.W_SAVE_COUNTER + PauseMenuSim.PROGRESS_WRAM_SIZE + PauseMenuSim.LEVEL_WRAM_SIZE
	for entry: Array in SharedWram.VARIABLES:
		var address: int = int(entry[2])
		if int(entry[1]) != 0 or address < PauseMenuSim.W_SAVE_COUNTER or address >= level_wram_end \
				or not index_of.has(String(entry[0])):
			continue
		var value: int = _v(trace["frames"][maxi(frame - 1, 0)], String(entry[0]))
		var size: int = int(entry[3])
		for index: int in size:
			if not inputs["traced"].has(address + index):
				pause.w0(address + index, value >> (8 * (size - 1 - index)))


## Wario's variables ExitPauseMenu's DrawWario reads (whether he is shown, his OAM bank), from the
## trace's frame before the loop.
const PAUSE_MENU_WARIO_INPUTS: PackedStringArray = ["wTransformation", "wInvisibleFrame", "wWarioOAMBank"]


## The WRAM0 addresses a screen's traced RAM ranges cover.
func _traced_bytes(ranges: Array) -> Dictionary:
	var covered: Dictionary = {}
	for range_: Dictionary in ranges:
		if int(range_["bank"]) != 0:
			continue
		var start: int = String(range_["address"]).hex_to_int()
		if start < 0xC000 or start >= 0xD000:
			continue
		for offset: int in int(range_["size"]):
			covered[start + offset] = true
	return covered


## The map a game loop at a time (WL3-052): the sub-states ported so far; the others are counted as
## not ported. Drawn (OverworldVram) on its loops after the first of a sub-state, set-ups apart, with
## rLCDC and the window as the VRAM model has them.
func _overworld_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var map := OverworldSim.new()
		map.load_data(document)
		return map
	return _menu_screen_step(trace, "overworld", {"state": LevelSim.ST_OVERWORLD, "make": make,
		"vram": func() -> ScreenVram: return OverworldVram.new(document),
		"lcdc": func(vram: ScreenVram) -> int: return (vram as OverworldVram).lcdc,
		"window": func(vram: ScreenVram) -> Vector2i:
			return Vector2i((vram as OverworldVram).wx, (vram as OverworldVram).wy),
		"drawn": func(substate: int, previous: int) -> bool:
			return substate in OVERWORLD_DRAWN and previous == substate,
		"visit": func(previous: Variant, substate: int) -> Array:
			# From a level (sub-state 0) the map sets up all it shows. Back from the save screen, which
			# a visit's last loop goes to (Func_803e6), VRAM is as the map left it (LoadBackupVRAM) and
			# the palettes are white (its last fade). A visit entered otherwise (a movie starting on the
			# map) shows VRAM never seen set up: checked, not drawn.
			if substate != 0 and previous != null:
				(previous as OverworldVram).faded_to_white()
				return [previous, true]
			return [OverworldVram.new(document), substate == 0],
		"key": func(sim: LevelSim, map: MenuScreenSim) -> String:
			if sim.wSubState == 0x13:
				return "cutscene $%02x" % map.rx(2, OverworldSim.W_EVENT_WITH_CUTSCENE)
			if sim.wSubState == 0x22:
				return "golf building %d" % map.rx(2, OverworldSim.W_PAL_FADE_6_COLOUR_2_GREEN_CURRENT)
			return "sub-state %d" % sim.wSubState if sim.wSubState != 0x0B else "map side %d" % map.rx(2, 0xD013),
		"ported": func(substate: int) -> bool: return substate in OVERWORLD_PORTED,
		"vblank": _overworld_vblank,
		"exit": OVERWORLD_EXIT_COMPARED})


## The map's V-Blank function when its loops before are unknown: on the map side's loop ($0B) and
## the Golf Building's way in from it ($1E), VBlank_Overworld, or VBlank_OWPalTransition while a day
## and night transition runs (the only ones that loop sets); on a scene's loop (7), VBlank_OWScene, or
## VBlank_OWPalTransition while its grey transition runs; in a cutscene ($12 to $15) VBlank_Cutscene
## (the prologue's VBlank_PrologueEpilogue), and in the Golf Building ($21, $22) .VBlank_GolfBuilding,
## each set aside while its fade runs;
## otherwise as it was.
func _overworld_vblank(sim: LevelSim, map: MenuScreenSim, current: int) -> int:
	var cutscene_vblank: int = OverworldSim.VBLANK_CUTSCENE
	if map.rx(2, OverworldSim.W_EVENT_WITH_CUTSCENE) == OverworldSim.EVENT_PROLOGUE:
		cutscene_vblank = OverworldSim.VBLANK_PROLOGUE  # the prologue's (VBlank_PrologueEpilogue)
	if sim.wSubState in [0x12, 0x14] and sim.wPalFadeCounter != 0:
		map.vblank_set_aside = cutscene_vblank
		return ScreenSim.VBLANK_NONE
	if sim.wSubState in [0x12, 0x13, 0x14, 0x15]:
		return cutscene_vblank
	if sim.wSubState == 0x21 and sim.wPalFadeCounter != 0:
		map.vblank_set_aside = OverworldSim.VBLANK_GOLF_BUILDING
		return ScreenSim.VBLANK_NONE
	if sim.wSubState in [0x21, 0x22]:
		return OverworldSim.VBLANK_GOLF_BUILDING
	if sim.wSubState not in [0x07, 0x0B, 0x1E]:
		return current
	if map.rx(2, OverworldSim.W_OW_PAL_TRANSITION_STATE) != 0:
		return OverworldSim.VBLANK_OW_PAL_TRANSITION
	return OverworldSim.VBLANK_OW_SCENE if sim.wSubState == 0x07 else OverworldSim.VBLANK_OVERWORLD


const OVERWORLD_PORTED: Array = [0x00, 0x01, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
		0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20,
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27]
const OVERWORLD_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState"]
## The map's sub-states drawn: a scene's loop (7), the map side's ($0b), the treasure collection's
## ($0f), a cutscene's ($13), the best times' ($19), the Temple's ($1d), the Golf Building's ($22), the
## epilogue's ($26), and the fades whose palettes are known (the model steps them): all but the level's
## fade out (0), whose palettes are the level's.
const OVERWORLD_DRAWN: Array = [0x04, 0x06, 0x07, 0x08, 0x0A, 0x0B, 0x0C, 0x0E, 0x0F, 0x12, 0x13, 0x14, 0x16,
		0x18, 0x19, 0x1A, 0x1C, 0x1D, 0x1F, 0x21, 0x22, 0x25, 0x26]


const PAUSE_MENU_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState", "wSCY", "wSCX", "wResetDisabled"]
## The way out's RAM compared with the frame after (ReturnToMapFromLevel sets wDayNight's bit 7):
## [name, WRAM bank, address].
const PAUSE_MENU_EXIT_RAM: Array = [["wDayNight", 0, 0xCA3B]]


## The title a game loop at a time (WL3-055, WL3-056): with a save or without (the intro); Time
## Attack's description and DebugReset are counted as not ported. InitIntroSequence (sub-state
## 1) clears wGlobalCounter, so the loop after it counts 1. Drawn (TitleVram) on the start menu's
## loops, whose palettes are known.
func _title_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var title := TitleSim.new()
		title.load_data(document)
		return title
	return _menu_screen_step(trace, "title", {"state": LevelSim.ST_TITLE, "make": make,
		"vram": func() -> ScreenVram: return TitleVram.new(document),
		"key": func(sim: LevelSim, _title: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool: return substate in TITLE_PORTED,
		"next": func(substate: int, next_counter: int) -> bool: return substate == 0x01 and next_counter == 1,
		"lcdc": GolfSim.LCDC_DEFAULT,
		"drawn": func(substate: int, previous: int) -> bool:
			return substate in TITLE_DRAWN and previous == substate,
		"scx_lines": func(title: MenuScreenSim, sim: LevelSim) -> Array: return (title as TitleSim).scx_lines(sim.wSCX),
		"scy_lines": func(title: MenuScreenSim, sim: LevelSim) -> Array: return (title as TitleSim).scy_lines(sim.wSCY),
		"exit": TITLE_EXIT_COMPARED, "exit_ram": TITLE_EXIT_RAM})


## New Game's language selection a game loop at a time (WL3-056), TitleSim in its own state; drawn
## (on what the title left, which it does not load: TitleVram without Init's VRAM) once the screen is
## up (sub-state 3).
func _language_selection_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var title := TitleSim.new()
		title.load_data(document)
		return title
	return _menu_screen_step(trace, "language_selection", {"state": TitleSim.ST_LANGUAGE_SELECTION, "make": make,
		"vram": func() -> ScreenVram: return TitleVram.new(document, false),
		"key": func(sim: LevelSim, _title: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool: return substate in LANGUAGE_SELECTION_PORTED,
		"lcdc": GolfSim.LCDC_DEFAULT,
		"drawn": func(substate: int, previous: int) -> bool: return substate == 3 and previous == substate,
		"exit": TITLE_EXIT_COMPARED, "exit_ram": LANGUAGE_SELECTION_EXIT_RAM})


const LANGUAGE_SELECTION_PORTED: Array = [0x00, 0x01, 0x02, 0x03]
## A takes the map as a new game (wTransitionParam TRANSITION_NEW_GAME) with the language chosen.
const LANGUAGE_SELECTION_EXIT_RAM: Array = [["wLanguage", 0, 0xCA46]]


## The title's sub-states the port covers: the fades, InitIntroSequence, the intro, the start menu,
## and Time Attack's description with the fade before it.
const TITLE_PORTED: Array = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A]
const TITLE_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState"]
## The title's sub-states drawn: the intro's three phases (its palettes the fade in ended on, its
## layers' scroll as PanIntroBackgroundLayers set it), the start menu, and Time Attack's description.
const TITLE_DRAWN: Array = [0x03, 0x04, 0x05, 0x06, TitleSim.SST_START_MENU, 0x0A]
## Action Help's demos from the title set wPowerUpLevel's ACTION_HELP_TITLE_SCREEN.
const TITLE_EXIT_RAM: Array = [["wPowerUpLevel", 0, 0xCA3C]]


## The credits a game loop at a time (WL3-052): from the epilogue's save screen to the music box's
## close-up and its wait; drawn (CreditsVram, with the LCD's registers and the window it models) from
## ShowCredits on, the palettes known once the fade in ends.
func _credits_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var credits := CreditsSim.new()
		credits.load_data(document)
		return credits
	return _menu_screen_step(trace, "credits", {"state": LevelSim.ST_CREDITS, "make": make,
		"vram": func() -> ScreenVram: return CreditsVram.new(document),
		"key": func(sim: LevelSim, _credits: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool: return substate in CREDITS_PORTED,
		"lcdc": func(vram: ScreenVram) -> int: return (vram as CreditsVram).lcdc,
		"window": func(vram: ScreenVram) -> Vector2i: return Vector2i((vram as CreditsVram).wx, (vram as CreditsVram).wy),
		"drawn": func(substate: int, previous: int) -> bool: return substate in CREDITS_DRAWN and previous == substate,
		"exit": CREDITS_EXIT_COMPARED})


## The credits' sub-states the port covers: all but the DebugReset entries (Init).
const CREDITS_PORTED: Array = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
## Drawn: ShowCredits on (the music box's moves, its close-up, the fade in to its palettes, the wait).
const CREDITS_DRAWN: Array = [0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
const CREDITS_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState"]


## The game over screen a game loop at a time (WL3-052): from the map's save screen after the hidden
## figure's fight is lost to Wario's waking and Init; drawn (GameOverVram) once the fade in ends, with
## the scroll each loop's trace gives.
func _game_over_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var game_over := GameOverSim.new()
		game_over.load_data(document)
		return game_over
	return _menu_screen_step(trace, "game_over", {"state": LevelSim.ST_GAME_OVER, "make": make,
		"vram": func() -> ScreenVram: return GameOverVram.new(document),
		"key": func(sim: LevelSim, _game_over: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool:
			return substate in GAME_OVER_PORTED and substate != GameOverSim.SST_GAME_OVER_RESET,
		"why": func(substate: int) -> String:
			return ("Init, left to runs: the step check keeps no SRAM, and the map's save screen saved since power-on"
					if substate == GameOverSim.SST_GAME_OVER_RESET else "not ported"),
		"lcdc": GolfSim.LCDC_DEFAULT,
		"drawn": func(substate: int, previous: int) -> bool: return substate in GAME_OVER_DRAWN and previous == substate,
		"exit": GAME_OVER_EXIT_COMPARED})


## The game over screen's sub-states the port covers: 0-6, GameOverReset's Init among them (left to runs:
## the step check keeps no SRAM); not the DebugReset entries.
const GAME_OVER_PORTED: Array = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]
## Drawn: UpdateGameOverScreen and Func_db3e4 (the screen's palettes known once the fade in ends).
const GAME_OVER_DRAWN: Array = [0x03, 0x04]
const GAME_OVER_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState"]


## The Perfect screen a game loop at a time (WL3-052): after a perfect game's credits, its fades in to
## each palette set; drawn (PerfectVram, the fades' steps modelled) once its own fade in ends.
func _perfect_step(trace: Dictionary, document: Variant) -> Dictionary:
	if not document is Dictionary:
		return {"checked": false}
	var make := func() -> MenuScreenSim:
		var perfect := PerfectSim.new()
		perfect.load_data(document)
		return perfect
	return _menu_screen_step(trace, "perfect", {"state": LevelSim.ST_PERFECT, "make": make,
		"vram": func() -> ScreenVram: return PerfectVram.new(document),
		"key": func(sim: LevelSim, _perfect: MenuScreenSim) -> String: return "sub-state %d" % sim.wSubState,
		"ported": func(substate: int) -> bool: return substate in PERFECT_PORTED,
		"lcdc": GolfSim.LCDC_DEFAULT,
		"drawn": func(substate: int, previous: int) -> bool: return substate in PERFECT_DRAWN and previous == substate,
		"exit": PERFECT_EXIT_COMPARED})


## The Perfect screen's sub-states the port covers: all but the DebugReset entries (Init).
const PERFECT_PORTED: Array = [0x00, 0x01, 0x02, 0x03]
## Drawn: UpdatePerfectScreen (the screen's palettes known once the fade in ends).
const PERFECT_DRAWN: Array = [0x03]
const PERFECT_EXIT_COMPARED: PackedStringArray = ["wState", "wSubState"]


## The screens the LevelSim was given, let go (each holds it while it runs).
func _screen_detach(sim: LevelSim) -> void:
	sim.credits = null
	sim.game_over = null
	sim.perfect = null
	sim.clear = null
	sim.action_help = null
	sim.pause_menu_screen = null
	sim.overworld = null
	sim.title = null
	sim.golf = null


const SCREEN_NOT_COMPARED: PackedStringArray = ["wGlobalCounter", "wJoypadDown", "wJoypadPressed"]


## A screen's traced loop into the LevelSim and the screen: each variable where it is kept (the
## screen's own, or the LevelSim's), its RAM ranges, and the virtual OAM.
func _screen_load(sim: LevelSim, screen: ScreenSim, screen_names: PackedStringArray, ranges: Array,
		entry: Array) -> void:
	if screen is ClearSim:
		sim.clear = screen
	elif screen is ActionHelpSim:
		sim.action_help = screen
	elif screen is PauseMenuSim:
		sim.pause_menu_screen = screen
	elif screen is OverworldSim:
		sim.overworld = screen
	elif screen is TitleSim:
		sim.title = screen
	elif screen is CreditsSim:
		sim.credits = screen
	elif screen is GameOverSim:
		sim.game_over = screen
	elif screen is PerfectSim:
		sim.perfect = screen
	elif screen is GolfSim:
		sim.golf = screen
	for i: int in screen_names.size():
		var name: String = screen_names[i]
		if name in screen:
			screen.set(name, int(entry[1][i]))
		else:
			sim.set(name, int(entry[1][i]))
	var bytes: PackedByteArray = String(entry[2]).hex_decode()
	var at: int = 0
	for range_: Dictionary in ranges:
		var start: int = String(range_["address"]).hex_to_int()
		for offset: int in int(range_["size"]):
			screen.ram_write(int(range_["bank"]), start + offset, bytes[at])
			at += 1
	screen.wVirtualOAM = String(entry[3]).hex_decode()


func _screen_state_diffs(sim: LevelSim, screen: ScreenSim, screen_names: PackedStringArray, ranges: Array,
		next: Array) -> Dictionary:
	var diffs: Dictionary = {}
	for i: int in screen_names.size():
		var name: String = screen_names[i]
		if name in SCREEN_NOT_COMPARED:
			continue
		var native: int = int(screen.get(name)) if name in screen else int(sim.get(name))
		if native != int(next[1][i]):
			diffs[name] = [native, int(next[1][i])]
	var bytes: PackedByteArray = String(next[2]).hex_decode()
	var at: int = 0
	for range_: Dictionary in ranges:
		var start: int = String(range_["address"]).hex_to_int()
		for offset: int in int(range_["size"]):
			var native: int = screen.ram_read(int(range_["bank"]), start + offset)
			if native != bytes[at]:
				diffs["%d:%04x" % [int(range_["bank"]), start + offset]] = [native, bytes[at]]
			at += 1
	if screen is PauseMenuSim and sim.wState == LevelSim.ST_PAUSE_MENU and sim.wSubState in PAUSE_LEVEL_SPRITES:
		diffs.erase("wVirtualOAMByteSize")
		return diffs
	var oam: PackedByteArray = String(next[3]).hex_decode()
	for offset: int in oam.size():
		if screen.wVirtualOAM[offset] != oam[offset]:
			diffs["OAM +%02x" % offset] = [screen.wVirtualOAM[offset], oam[offset]]
	return diffs


## The pause menu's sub-states after ExitPauseMenu: the virtual OAM holds the level's sprites
## (DrawLevelObjectsAfterLevelReturn), which the port keeps as LevelSim.drawn_objects, so neither it
## nor its byte count is compared.
const PAUSE_LEVEL_SPRITES: Array = [0x06, 0x07]


const GOLF_OWN: PackedStringArray = ["wGolfBestScores", "wVirtualOAMByteSize"]
const GOLF_NOT_COMPARED: PackedStringArray = ["wGlobalCounter", "wJoypadDown", "wJoypadPressed"]


func _load_golf(sim: LevelSim, golf: GolfSim, golf_names: PackedStringArray, entry: Array) -> void:
	for i: int in golf_names.size():
		var value: int = int(entry[1][i])
		match golf_names[i]:
			"wGolfBestScores", "wVirtualOAMByteSize":
				golf.set(golf_names[i], value)
			_:
				sim.set(golf_names[i], value)
	var bytes: PackedByteArray = String(entry[2]).hex_decode()
	for offset: int in 6:
		golf.wb(0xD800 + offset, bytes[offset])
	for offset: int in range(6, bytes.size()):
		golf.wb(0xDB40 + offset - 6, bytes[offset])
	if entry.size() > 3:
		golf.wVirtualOAM = String(entry[3]).hex_decode()


func _golf_diffs(sim: LevelSim, golf: GolfSim, golf_names: PackedStringArray, next: Array) -> Dictionary:
	var diffs: Dictionary = {}
	for i: int in golf_names.size():
		var name: String = golf_names[i]
		if name in GOLF_NOT_COMPARED:
			continue
		var native: int = int(golf.get(name)) if name in GOLF_OWN else int(sim.get(name))
		if native != int(next[1][i]):
			diffs[name] = [native, int(next[1][i])]
	var bytes: PackedByteArray = String(next[2]).hex_decode()
	for offset: int in bytes.size():
		var address: int = 0xD800 + offset if offset < 6 else 0xDB40 + offset - 6
		if golf.rb(address) != bytes[offset]:
			diffs["$%04x" % address] = [golf.rb(address), bytes[offset]]
	if next.size() > 3:  # the virtual OAM
		var oam: PackedByteArray = String(next[3]).hex_decode()
		for offset: int in oam.size():
			if golf.wVirtualOAM[offset] != oam[offset]:
				diffs["OAM +%02x" % offset] = [golf.wVirtualOAM[offset], oam[offset]]
	return diffs


## The particle region's bytes that differ from the oracle's ($cca0-$cce1).
func _particle_diffs(sim: WarioParticles, oracle: PackedByteArray) -> Dictionary:
	var diffs: Dictionary = {}
	var native: PackedByteArray = sim.particle_bytes()
	for offset: int in native.size():
		if native[offset] != oracle[offset]:
			diffs["particles +%02x" % offset] = [native[offset], oracle[offset]]
	return diffs


## The oracle's rDIV reads ([frame, checkpoints, bank, address, value]) by frame.
func _div_by_frame(trace: Dictionary) -> Dictionary:
	var by_frame: Dictionary = {}
	for read: Array in trace.get("div_reads", []):
		if not by_frame.has(int(read[0])):
			by_frame[int(read[0])] = []
		by_frame[int(read[0])].append(read)
	return by_frame


## The first object checkpoint of each frame: reads before it were made before UpdateObjects.
func _first_checkpoints(trace: Dictionary) -> Dictionary:
	var first: Dictionary = {}
	var checkpoints: Array = trace.get("object_checkpoints", [])
	for i: int in checkpoints.size():
		if not first.has(int(checkpoints[i][0])):
			first[int(checkpoints[i][0])] = i
	return first


## Replay `reads` to `sim`: each native rDIV read takes the next, in order.
func _feed_div(sim: WarioRam, reads: Array) -> void:
	sim.div_replay = true
	sim.div_queue.clear()
	sim.div_mismatches.clear()
	for read: Array in reads:
		sim.div_queue.append([(int(read[2]) << 16) | int(read[3]), int(read[4])])


## How the native rDIV reads differed from the replayed ones; `all` also counts reads not made.
func _div_diffs(sim: WarioRam, all: bool = true) -> PackedStringArray:
	var diffs: PackedStringArray = sim.div_mismatches.duplicate()
	if all:
		for entry: Array in sim.div_queue:
			diffs.append("the original's rDIV read at %02x:%04x, not made" % [int(entry[0]) >> 16, int(entry[0]) & 0xFFFF])
	return diffs


## The reads of `frame` made after `after` checkpoints had been recorded (or at most `after`).
func _reads_at(div_reads: Dictionary, frame: int, after: int, at_most: bool = false) -> Array:
	var reads: Array = []
	for read: Array in div_reads.get(frame, []):
		if int(read[1]) == after or (at_most and int(read[1]) <= after):
			reads.append(read)
	return reads


func _step(trace: Dictionary, truth: LevelCollision, tables: WarioTables) -> Dictionary:
	var sim := WarioSim.new()
	sim.tables = tables
	sim.level = LevelCollision.new()
	sim.level.room_handlers = truth.room_handlers
	var changes: Array = trace["block_changes"]
	var by_state: Dictionary = {}
	var unported: Dictionary = {}
	var examples: Array = []
	var handlers: Dictionary = {}
	var matched: int = 0
	var mismatched: int = 0
	var div_reads: Dictionary = _div_by_frame(trace)
	var first_checkpoints: Dictionary = _first_checkpoints(trace)
	var change_index: int = 0
	for update: Array in trace["updates"]:
		var frame: int = int(update[0])
		var before: Array = update[1]
		var after: Array = update[2]
		while change_index < changes.size() and int(changes[change_index][0]) < frame:
			var change: Array = changes[change_index]
			truth.set_block(int(change[1]), int(change[2]), int(change[3]))
			change_index += 1
		var state: int = _v(before, "wWarioState")
		var state_key: String = "$%02x" % state
		if not state in WarioSim.PORTED_STATES:
			var key: String = "state " + state_key
			unported[key] = int(unported.get(key, 0)) + 1
			continue
		sim.level.rows = truth.rows.duplicate()
		sim.level.gap_rows = truth.gap_rows.duplicate()
		sim.load_values(names, before)
		# Wario's own reads: those of the frame before its first object checkpoint.
		_feed_div(sim, _reads_at(div_reads, frame, int(first_checkpoints.get(frame, 1 << 30)), true))
		sim.update()
		if not by_state.has(state_key):
			by_state[state_key] = {"matched": 0, "mismatched": 0, "unported": 0}
		if not sim.unported.is_empty():
			by_state[state_key]["unported"] += 1
			unported[sim.unported[0]] = int(unported.get(sim.unported[0], 0)) + 1
			continue
		var diffs: Dictionary = _diffs(sim, after)
		var div_diffs: PackedStringArray = _div_diffs(sim)
		if not div_diffs.is_empty():
			diffs["rDIV"] = div_diffs
		if diffs.is_empty():
			matched += 1
			by_state[state_key]["matched"] += 1
			for key: String in sim.handlers_run:
				handlers[key] = int(handlers.get(key, 0)) + 1
		else:
			mismatched += 1
			by_state[state_key]["mismatched"] += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": frame, "state": state_key, "input": [_v(before, "wJoypadDown"),
						_v(before, "wJoypadPressed")], "diffs": diffs})
	return {"mode": "step", "updates": trace["updates"].size(), "matched": matched, "mismatched": mismatched,
			"div_reads": trace.get("div_reads", []).size(), "by_state": by_state, "unported": unported,
			"handlers_in_matched_updates": handlers,
			"examples": examples}


## Whether a recorded block change was made before a step rerun in `frame`: one of an earlier frame,
## or one of this frame first seen at object checkpoint `seen` or before. In a trace without `seen`
## (older), every change of the frame counts.
static func _change_before(change: Array, frame: int, seen: int) -> bool:
	if int(change[0]) != frame:
		return int(change[0]) < frame
	return change.size() < 5 or int(change[4]) <= seen


## The blocks a step left that differ from the original's: the map before it (`truth`) plus this
## frame's changes first seen by checkpoint `seen`, from `index` on. Not checked (empty) for a trace
## without `seen`.
static func _block_diffs(level: LevelCollision, truth: LevelCollision, changes: Array, index: int, frame: int,
		seen: int) -> Dictionary:
	var diffs: Dictionary = {}
	if not changes.is_empty() and (changes[0] as Array).size() < 5:
		return diffs
	var expected: PackedByteArray = truth.rows.duplicate()
	while index < changes.size() and int(changes[index][0]) == frame and int(changes[index][4]) <= seen:
		expected[int(changes[index][1]) * LevelCollision.WIDTH + int(changes[index][2])] = int(changes[index][3])
		index += 1
	if level.rows == expected:
		return diffs
	for offset: int in expected.size():
		if level.rows[offset] != expected[offset]:
			diffs["block %d,%d" % [offset / LevelCollision.WIDTH, offset % LevelCollision.WIDTH]] = [
					level.rows[offset], expected[offset]]
	return diffs


## Objects: every UpdateObjects the trace recorded (checkpoint 0, then 1) rerun natively from the
## slots and variables at its start, and each slot compared byte for byte with the original after it.
## Slots whose update reached an unported routine are counted by that routine instead. With a trace
## that records when each block change was seen, the block map after it is compared too.
func _objects_step(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary) -> Dictionary:
	var checkpoints: Array = trace.get("object_checkpoints", [])
	if checkpoints.is_empty() or objects_doc.is_empty():
		return {"checked": false}
	var truth := LevelCollision.new()
	truth.room_handlers = level.room_handlers
	truth.set_rows(trace["block_rows"])
	truth.set_gap_rows(trace.get("block_gap_rows", []))
	var changes: Array = trace["block_changes"]
	var change_index: int = 0
	var sim := LevelSim.new()
	sim.tables = tables
	sim.load_object_data(objects_doc)
	sim.level = LevelCollision.new()
	sim.level.room_handlers = level.room_handlers
	var by_function: Dictionary = {}
	var unported: Dictionary = {}
	var examples: Array = []
	var runs: int = 0
	var matched_slots: int = 0
	var mismatched_slots: int = 0
	var div_reads: Dictionary = _div_by_frame(trace)
	for i: int in range(checkpoints.size() - 1):
		var start: Array = checkpoints[i]
		var finish: Array = checkpoints[i + 1]
		if int(start[1]) != 0 or int(finish[1]) != 1:
			continue
		var frame: int = int(start[0])
		while change_index < changes.size() and _change_before(changes[change_index], frame, 0):
			var change: Array = changes[change_index]
			truth.set_block(int(change[1]), int(change[2]), int(change[3]))
			change_index += 1
		sim.level.rows = truth.rows.duplicate()
		sim.level.gap_rows = truth.gap_rows.duplicate()
		sim.level.object_rows = level.object_rows.duplicate(true)
		sim.load_values(names, start[2])
		sim.wram1 = String(start[3]).hex_decode()
		var before: PackedByteArray = sim.wram1.duplicate()
		var after: PackedByteArray = String(finish[3]).hex_decode()
		sim.unported.clear()
		sim.object_unported.clear()
		_feed_div(sim, _reads_at(div_reads, frame, i + 1))
		sim.update_objects()
		runs += 1
		if sim.unported_slots.is_empty() and not _div_diffs(sim).is_empty():
			mismatched_slots += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": frame, "rDIV": _div_diffs(sim)})
		var block_diffs: Dictionary = _block_diffs(sim.level, truth, changes, change_index, frame, 1)
		if sim.unported_slots.is_empty() and not block_diffs.is_empty():
			mismatched_slots += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": frame, "blocks": block_diffs})
		# Unported code can also write past the slots (the Shoot ball counts goals that a later slot's
		# counter reads): when the bytes there end up different, no slot after an unported one is judged.
		var first_unported: int = LevelSim.NUM_OBJECTS
		for slot: int in sim.unported_slots:
			first_unported = mini(first_unported, slot)
		var past_slots_differ: bool = false
		for offset: int in range(LevelSim.W_OBJ_DATA_POINTERS, after.size()):  # past wCurObj, the scratch copy
			if sim.wram1[offset] != after[offset]:
				past_slots_differ = true
		for slot: int in LevelSim.NUM_OBJECTS:
			var base: int = slot * LevelSim.OBJ_STRUCT_LENGTH
			if (before[base] & LevelSim.OBJFLAG_ACTIVE) == 0 and (after[base] & LevelSim.OBJFLAG_ACTIVE) == 0:
				continue
			var key: String = "id %02x %02x:%04x" % [before[base + LevelSim.OBJ_ID],
					LevelSim.OBJECT_FUNCTIONS_1_BANK | (before[base + LevelSim.OBJ_ID] >> 4),
					before[base + LevelSim.OBJ_UPDATE_FUNCTION] | (before[base + LevelSim.OBJ_UPDATE_FUNCTION + 1] << 8)]
			if not by_function.has(key):
				by_function[key] = {"matched": 0, "mismatched": 0, "unported": 0}
			# Unported code can write into other slots (spawning, for one): a slot that another object's
			# unported update may have changed is not judged either.
			var replaced: bool = ((before[base] & LevelSim.OBJFLAG_ACTIVE) == 0
					or before[base + LevelSim.OBJ_ID] != after[base + LevelSim.OBJ_ID])
			if slot in sim.unported_slots or (replaced and not sim.unported_slots.is_empty()) \
					or (past_slots_differ and slot > first_unported):
				by_function[key]["unported"] += 1
				continue
			var diffs: Dictionary = {}
			for offset: int in LevelSim.OBJ_STRUCT_LENGTH:
				if sim.wram1[base + offset] != after[base + offset]:
					diffs["%02x" % offset] = [sim.wram1[base + offset], after[base + offset]]
			if diffs.is_empty():
				matched_slots += 1
				by_function[key]["matched"] += 1
			else:
				mismatched_slots += 1
				by_function[key]["mismatched"] += 1
				if examples.size() < MAX_EXAMPLES:
					examples.append({"frame": frame, "slot": slot, "object": key, "diffs": diffs})
		for name: String in sim.object_unported:
			unported[name] = int(unported.get(name, 0)) + 1
	return {"checked": true, "runs": runs, "matched": matched_slots, "mismatched": mismatched_slots,
			"by_function": by_function, "unported": unported, "examples": examples}


## Interactions: every ProcessInteractions the trace recorded (checkpoint 2, then 3) rerun natively
## from the variables and slots at its start; Wario's compared variables, the coin counts, and every
## slot are compared with the original after it. A run that reaches an unported interaction is
## counted by name instead.
func _interactions_step(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary) -> Dictionary:
	var checkpoints: Array = trace.get("object_checkpoints", [])
	if checkpoints.is_empty() or objects_doc.is_empty():
		return {"checked": false}
	var truth := LevelCollision.new()
	truth.room_handlers = level.room_handlers
	truth.set_rows(trace["block_rows"])
	truth.set_gap_rows(trace.get("block_gap_rows", []))
	var changes: Array = trace["block_changes"]
	var change_index: int = 0
	var sim := LevelSim.new()
	sim.tables = tables
	sim.load_object_data(objects_doc)
	sim.level = LevelCollision.new()
	sim.level.room_handlers = level.room_handlers
	var compared_names: PackedStringArray = COMPARED.duplicate()
	compared_names.append_array(["wNumCoins", "wNumMusicalCoins", "wIsOnSteppableObject", "hXPos", "hYPos", "wState",
			"wTimer", "wKeyAndTreasureFlags"])
	var div_reads: Dictionary = _div_by_frame(trace)
	var runs: int = 0
	var met: int = 0
	var matched: int = 0
	var matched_changes: int = 0
	var mismatched: int = 0
	var unported: Dictionary = {}
	var examples: Array = []
	for i: int in range(checkpoints.size() - 1):
		var start: Array = checkpoints[i]
		var finish: Array = checkpoints[i + 1]
		if int(start[1]) != 2 or int(finish[1]) != 3:
			continue
		var frame: int = int(start[0])
		while change_index < changes.size() and _change_before(changes[change_index], frame, 2):
			var change: Array = changes[change_index]
			truth.set_block(int(change[1]), int(change[2]), int(change[3]))
			change_index += 1
		sim.level.rows = truth.rows.duplicate()
		sim.level.gap_rows = truth.gap_rows.duplicate()
		sim.load_values(names, start[2])
		sim.wram1 = String(start[3]).hex_decode()
		var before: PackedByteArray = sim.wram1.duplicate()
		var after: PackedByteArray = String(finish[3]).hex_decode()
		sim.unported.clear()
		_feed_div(sim, _reads_at(div_reads, frame, i + 1))
		if start.size() > 4:
			sim.load_particle_bytes(String(start[4]).hex_decode())
		sim.wBlockFuncWarioFlag = 1  # UpdateLevel's, around ProcessInteractions
		sim.process_interactions()
		sim.wBlockFuncWarioFlag = 0
		runs += 1
		var changed: bool = before.slice(0, 0x100) != after.slice(0, 0x100) or start[2] != finish[2]
		if changed:
			met += 1
		if not sim.unported.is_empty():
			for name: String in sim.unported:
				unported[name] = int(unported.get(name, 0)) + 1
			continue
		var diffs: Dictionary = _diffs(sim, finish[2], compared_names)
		if not _div_diffs(sim).is_empty():
			diffs["rDIV"] = _div_diffs(sim)
		diffs.merge(_block_diffs(sim.level, truth, changes, change_index, frame, 3))
		if finish.size() > 4:
			diffs.merge(_particle_diffs(sim, String(finish[4]).hex_decode()))
		for offset: int in 0x100:
			if sim.wram1[offset] != after[offset]:
				diffs["slot %d +%02x" % [offset / 32, offset % 32]] = [sim.wram1[offset], after[offset]]
		if diffs.is_empty():
			matched += 1
			if changed:
				matched_changes += 1
		else:
			mismatched += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": frame, "wario_state": _v(start[2], "wWarioState"), "diffs": diffs})
	return {"checked": true, "runs": runs, "with_changes": met, "matched": matched, "matched_with_changes": matched_changes,
			"mismatched": mismatched, "unported": unported, "examples": examples}


## Edge spawns: after each run of the camera code, the edges it opened are streamed natively
## (Func_8ed9 with SpawnRowEdgeObjects and SpawnColEdgeObjects) from the slots after that frame's
## interactions, and the slots compared with the next UpdateObjects's.
func _spawn_step(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary) -> Dictionary:
	var checkpoints: Array = trace.get("object_checkpoints", [])
	if checkpoints.is_empty() or objects_doc.is_empty():
		return {"checked": false}
	var after_camera: Dictionary = {}
	for update: Array in trace["camera_updates"]:
		after_camera[int(update[0])] = update[2]
	var truth := MapTruth.new(level, trace)
	var sim := LevelSim.new()
	sim.tables = tables
	sim.load_object_data(objects_doc)
	var runs: int = 0
	var with_spawns: int = 0
	var matched: int = 0
	var mismatched: int = 0
	var created_elsewhere: int = 0
	var examples: Array = []
	for i: int in range(checkpoints.size() - 1):
		var drawn: Array = checkpoints[i]
		var next: Array = checkpoints[i + 1]
		var frame: int = int(drawn[0])
		if int(drawn[1]) != 3 or int(next[1]) != 0 or not after_camera.has(frame):
			continue
		truth.advance(frame)
		sim.level = truth.level.copy()
		sim.load_values(names, after_camera[frame])
		sim.wram1 = String(drawn[3]).hex_decode()
		var before: PackedByteArray = sim.wram1.duplicate()
		sim.unported.clear()
		sim.object_unported.clear()
		sim.stream_level_edges()
		runs += 1
		var expected: PackedByteArray = String(next[3]).hex_decode()
		if before.slice(0, 0x100) != expected.slice(0, 0x100):
			with_spawns += 1
		# Objects the next frame creates before its UpdateObjects (a broken block's coin, created in
		# Wario's update) are transient; map spawns never are. Such slots are not spawning's to explain.
		for slot: int in 8:
			var base: int = slot * 32
			if ((expected[base] & 0x41) == 0x41 and sim.wram1.slice(base, base + 32) == before.slice(base, base + 32)
					and expected.slice(base, base + 32) != before.slice(base, base + 32)):
				for offset: int in 32:
					sim.wram1[base + offset] = expected[base + offset]
				created_elsewhere += 1
		var diffs: Dictionary = _slot_diffs(sim.wram1, expected)
		if diffs.is_empty():
			matched += 1
		else:
			mismatched += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": frame, "edges": _v(after_camera[frame], "wLevelEdgeUpdateFlags"), "diffs": diffs})
	return {"checked": true, "runs": runs, "with_spawns": with_spawns, "matched": matched, "mismatched": mismatched,
			"created_elsewhere": created_elsewhere, "examples": examples}


func _run(trace: Dictionary, truth: LevelCollision, tables: WarioTables) -> Dictionary:
	# Whole frames: each run of UpdateLevel's camera code ends one frame. The native LevelSim takes only
	# the input from the oracle (the joypad UpdateJoypad read for that frame) and is compared with the
	# oracle after the camera on Wario's and the camera's variables.
	var frames: Array = trace.get("camera_updates", [])
	var compared_names: PackedStringArray = COMPARED.duplicate()
	compared_names.append_array(CAMERA_COMPARED)
	var sim := LevelSim.new()
	sim.tables = tables
	sim.level = truth
	var changes: Array = trace["block_changes"]
	var change_index: int = 0
	# Start at the first frame with a Wario update in a ported state, from that update's "before":
	# the state at the start of the frame, after UpdateJoypad.
	var wario_before: Dictionary = {}
	var wario_after: Dictionary = {}
	for update: Array in trace["updates"]:
		wario_before[int(update[0])] = update[1]
		wario_after[int(update[0])] = update[2]
	var first: int = -1
	for i: int in frames.size():
		var at_frame: int = int(frames[i][0])
		if wario_before.has(at_frame) and _v(wario_before[at_frame], "wWarioState") in WarioSim.PORTED_STATES:
			first = i
			break
	if first < 0:
		return {"mode": "run", "frames_compared": 0, "mismatched": 0, "stopped": "no frame in a ported state"}
	# The map follows the oracle until the native model takes over.
	while change_index < changes.size() and int(changes[change_index][0]) < int(frames[first][0]):
		var change: Array = changes[change_index]
		truth.set_block(int(change[1]), int(change[2]), int(change[3]))
		change_index += 1
	sim.load_values(names, wario_before[int(frames[first][0])])
	var compared: int = 0
	var start_frame: int = int(frames[first][0])
	sim.golf_replay = true
	sim.golf_queue = _golf_queue(start_frame)
	var div_reads: Dictionary = _div_by_frame(trace)
	var first_checkpoints: Dictionary = _first_checkpoints(trace)
	for i: int in range(first, frames.size()):
		var before: Array = frames[i][1]
		var at: int = int(frames[i][0])
		# Without objects, only Wario's reads: those before the frame's first object checkpoint.
		_feed_div(sim, _reads_at(div_reads, at, int(first_checkpoints.get(at, 1 << 30)), true))
		if i > first:
			# Game loops without UpdateLevel (a room transition's door effect, fades, and room start)
			# run natively too, so the run goes on into the next room.
			var gap: int = _loops_between(int(frames[i - 1][0]), at, _v(frames[i - 1][1], "wGlobalCounter"),
					_v(before, "wGlobalCounter"))
			for loop: int in gap:
				sim.update_level()
				if not sim.unported.is_empty():
					return _stopped(start_frame, compared, at, sim.unported[0])
			if gap > 0 and sim.wSubState != LEVEL_PLAYING:
				return _stopped(start_frame, compared, at, "",
						{"wSubState": [sim.wSubState, LEVEL_PLAYING], "loops": gap})
		sim.wJoypadDown = _v(before, "wJoypadDown")
		sim.wJoypadPressed = _v(before, "wJoypadPressed")
		sim.wGlobalCounter = _v(before, "wGlobalCounter")
		sim.update_level_wario()
		if not sim.unported.is_empty():
			return _stopped(start_frame, compared, at, sim.unported[0])
		if not _div_diffs(sim, false).is_empty():
			return _stopped(start_frame, compared, at, "", {"rDIV": _div_diffs(sim, false)})
		if wario_after.has(at):
			var wario_diffs: Dictionary = _diffs(sim, wario_after[at], COMPARED)
			if not wario_diffs.is_empty():
				return _stopped(start_frame, compared, at, "", wario_diffs)
			# Objects and interactions run here in the original; stop if they changed Wario.
			var by_objects: Dictionary = _between(wario_after[at], before, COMPARED)
			if not by_objects.is_empty():
				return _stopped(start_frame, compared, at, "Wario changed by object code within the frame (not ported)",
						by_objects)
		sim.update_level_after_objects()
		var diffs: Dictionary = _diffs(sim, frames[i][2], compared_names)
		if not diffs.is_empty():
			return _stopped(start_frame, compared, at, "", diffs)
		compared += 1
		sim.stream_level_edges()
		var next_frame: int = int(frames[i + 1][0]) if i + 1 < frames.size() else -1
		var next_gap: int = 0
		if i + 1 < frames.size():
			next_gap = _loops_between(at, next_frame, _v(before, "wGlobalCounter"), _v(frames[i + 1][1], "wGlobalCounter"))
		if wario_before.has(next_frame) and next_gap == 0:
			# Between frames only object code changes Wario (and V-Blank clears the transfer flag).
			var outside: Dictionary = _diffs(sim, wario_before[next_frame], COMPARED)
			outside.erase("wIsDMATransferPending")
			if not outside.is_empty():
				return _stopped(start_frame, compared, next_frame,
						"Wario changed between frames by code that is not ported (objects)", outside)
	return {"mode": "run", "start_frame": start_frame, "frames_compared": compared, "mismatched": 0,
			"stopped": "end of trace"}


## Whole frames with objects: from the oracle's state at the first frame in a ported state, the
## native LevelSim runs every frame on the oracle's input alone (Wario, UpdateObjects, interactions,
## the camera, edge spawning, and the loops of room transitions) with its own maps, and is compared
## at each checkpoint the trace has: Wario after his update, the slots entering UpdateObjects and
## after it, Wario and the slots after the interactions, and the camera. It stops at the first
## difference, or where the frame reaches something not ported.
func _run_with_objects(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary) -> Dictionary:
	var frames: Array = trace.get("camera_updates", [])
	var checkpoints: Array = trace["object_checkpoints"]
	var level_objects: Dictionary = {}  # frame -> [checkpoint 0, 1, 2, 3] indices of its UpdateLevel
	for i: int in range(checkpoints.size() - 3):
		if (int(checkpoints[i][1]) == 0 and int(checkpoints[i + 1][1]) == 1 and int(checkpoints[i + 2][1]) == 2
				and int(checkpoints[i + 3][1]) == 3 and int(checkpoints[i][0]) == int(checkpoints[i + 3][0])):
			level_objects[int(checkpoints[i][0])] = [i, i + 1, i + 2, i + 3]
	var wario_before: Dictionary = {}
	var wario_after: Dictionary = {}
	for update: Array in trace["updates"]:
		wario_before[int(update[0])] = update[1]
		wario_after[int(update[0])] = update[2]
	var first: int = -1
	for i: int in frames.size():
		var at_frame: int = int(frames[i][0])
		if (wario_before.has(at_frame) and level_objects.has(at_frame)
				and _v(wario_before[at_frame], "wWarioState") in WarioSim.PORTED_STATES):
			first = i
			break
	var sim := LevelSim.new()
	sim.tables = tables
	sim.load_object_data(objects_doc)
	sim.room_animation = objects_doc.get("room_animation", {})
	if first < 0:
		if not _from_power_on(trace):
			return {"mode": "run", "frames_compared": 0, "mismatched": 0, "stopped": "no frame in a ported state"}
		# A power-on movie that never reaches a level: its screens from power-on to the trace's end.
		sim.animation_replay = trace.has("animation_calls")
		_power_on(sim)
		return {"mode": "run", "frames_compared": 0, "mismatched": 0, "stopped": "no level", "with_objects": true,
				"power_on": true, "screens": _run_screens(trace, sim, -1, _div_by_frame(trace),
						_animation_calls_by_frame(trace), -1, false)}
	var start_frame: int = int(frames[first][0])
	var animation_calls: Dictionary = _animation_calls_by_frame(trace)
	sim.animation_replay = trace.has("animation_calls")
	var div_reads: Dictionary = _div_by_frame(trace)
	_temple_setup(trace, objects_doc)
	# From the map when the window starts there (WL3-052): the level is entered natively and its start
	# compared; otherwise from the level's first ported update, as the trace has it.
	var from_map: Dictionary = _run_from_map(trace, sim, start_frame, div_reads, animation_calls)
	if from_map.get("entered", false):
		_forget_level_ram(sim)
		_attach_golf(sim, start_frame, objects_doc)
		var start_diffs: Dictionary = _diffs(sim, wario_before[start_frame])
		start_diffs.merge(_diffs(sim, wario_before[start_frame], START_CAMERA_COMPARED))
		if trace.has("animation_calls"):
			# UpdateLevel sets wRoomAnimatedPalsEnabled before the update the trace records.
			var animation: PackedStringArray = ANIMATION_COMPARED.duplicate()
			animation.remove_at(animation.find("wRoomAnimatedPalsEnabled"))
			start_diffs.merge(_diffs(sim, wario_before[start_frame], animation))
		var slots: Dictionary = _slot_diffs(sim.wram1, String(checkpoints[level_objects[start_frame][0]][3]).hex_decode())
		if not slots.is_empty():
			start_diffs["objects entering the first UpdateObjects"] = slots
		if not start_diffs.is_empty():
			var stopped: Dictionary = _stopped(start_frame, 0, start_frame, "", {"the level start": start_diffs}, true)
			stopped["from_map"] = from_map
			return stopped
	elif String(from_map.get("stopped", "")) == "a difference":
		var stopped: Dictionary = _stopped(start_frame, 0, int(from_map.get("stopped_at_frame", start_frame)), "",
				{"before the level": from_map.get("diffs", {})}, true)
		stopped["from_map"] = from_map
		return stopped
	else:
		# No map before the level, or the map reached what is not ported: from the level's first ported
		# update as the trace has it, on a LevelSim of its own.
		if from_map.get("checked", false):
			sim = LevelSim.new()
			sim.tables = tables
			sim.load_object_data(objects_doc)
			sim.room_animation = objects_doc.get("room_animation", {})
			sim.animation_replay = trace.has("animation_calls")
			seeded.clear()
			seeded_since_level.clear()
			seen_screens.clear()
			seeded_hram.clear()
		var truth := MapTruth.new(level, trace)
		truth.advance(start_frame)
		sim.level = truth.level
		sim.load_values(names, wario_before[start_frame])
		sim.wram1 = String(checkpoints[level_objects[start_frame][0]][3]).hex_decode()
		_attach_golf(sim, start_frame, objects_doc)
	var after_interactions: PackedStringArray = COMPARED.duplicate()
	after_interactions.append_array(["wNumCoins", "wNumMusicalCoins", "wIsOnSteppableObject", "wState", "wTimer",
			"wKeyAndTreasureFlags"])
	var compared_names: PackedStringArray = COMPARED.duplicate()
	compared_names.append_array(CAMERA_COMPARED)
	if trace.has("animation_calls"):
		compared_names.append_array(ANIMATION_COMPARED)
	var compared: int = 0
	for i: int in range(first, frames.size()):
		var before: Array = frames[i][1]
		var at: int = int(frames[i][0])
		sim.object_unported.clear()
		# Every rDIV read and animation call since the last compared frame, in order (the loops
		# between take theirs).
		var reads: Array = []
		sim.animation_queue.clear()
		sim.animation_mismatches.clear()
		for frame: int in range(int(frames[i - 1][0]) + 1 if i > first else at, at + 1):
			reads.append_array(div_reads.get(frame, []))
			sim.animation_queue.append_array(animation_calls.get(frame, []))
		_feed_div(sim, reads)
		if i > first:
			var gap: int = _loops_between(int(frames[i - 1][0]), at, _v(frames[i - 1][1], "wGlobalCounter"),
					_v(before, "wGlobalCounter"))
			var stop: Dictionary = _run_level_gap(trace, sim, int(frames[i - 1][0]), at, gap, _v(before, "wGlobalCounter"),
					div_reads, animation_calls)
			if not stop.is_empty():
				var stopped: Dictionary = _stopped(start_frame, compared, at, String(stop["reason"]), stop.get("diffs", {}),
						true)
				if stop.has("screens"):
					stopped["screens"] = stop["screens"]
				return stopped
			if not sim.object_unported.is_empty():
				return _stopped(start_frame, compared, at, "the new room's " + sim.object_unported[0], {}, true)
			if gap > 0 and (sim.wSubState != LEVEL_PLAYING or sim.wState != LevelSim.ST_LEVEL):
				return _stopped(start_frame, compared, at, "", {"wState": [sim.wState, LevelSim.ST_LEVEL],
						"wSubState": [sim.wSubState, LEVEL_PLAYING], "loops": gap}, true)
		var temple_shown: Array = _temple_before(sim, at)
		sim.wJoypadDown = _v(before, "wJoypadDown")
		sim.wJoypadPressed = _v(before, "wJoypadPressed")
		sim.wGlobalCounter = _v(before, "wGlobalCounter")
		sim.update_level_wario()
		if not sim.unported.is_empty():
			return _stopped(start_frame, compared, at, sim.unported[0], {}, true)
		if i == first and checkpoints[0].size() > 4 and not from_map.get("entered", false):
			# The particles as this frame's UpdateParticles and Wario's update left them (the checkpoint
			# entering UpdateObjects); loaded before the frame, they would be updated twice.
			sim.load_particle_bytes(String(checkpoints[level_objects[start_frame][0]][4]).hex_decode())
		if not _div_diffs(sim, false).is_empty():
			return _stopped(start_frame, compared, at, "", {"rDIV": _div_diffs(sim, false)}, true)
		if wario_after.has(at):
			var wario_diffs: Dictionary = _diffs(sim, wario_after[at], COMPARED)
			if not wario_diffs.is_empty():
				return _stopped(start_frame, compared, at, "", wario_diffs, true)
		if not level_objects.has(at):
			return _stopped(start_frame, compared, at, "no objects checkpoints for this frame", {}, true)
		var points: Array = level_objects[at]
		var entering: Dictionary = _slot_diffs(sim.wram1, String(checkpoints[points[0]][3]).hex_decode())
		if checkpoints[points[0]].size() > 4 and i > first:
			entering.merge(_particle_diffs(sim, String(checkpoints[points[0]][4]).hex_decode()))
		if not entering.is_empty():
			return _stopped(start_frame, compared, at, "", {"slots entering UpdateObjects": entering}, true)
		sim.update_objects()
		if not sim.object_unported.is_empty():
			return _stopped(start_frame, compared, at, sim.object_unported[0], {}, true)
		var updated: Dictionary = _slot_diffs(sim.wram1, String(checkpoints[points[1]][3]).hex_decode())
		if not updated.is_empty():
			return _stopped(start_frame, compared, at, "", {"slots after UpdateObjects": updated}, true)
		sim.set_wario_screen_pos()
		sim.check_temple_fence_shake()
		sim.wBlockFuncWarioFlag = 1
		sim.process_interactions()
		sim.wBlockFuncWarioFlag = 0
		if not sim.unported.is_empty():
			return _stopped(start_frame, compared, at, sim.unported[0], {}, true)
		var interacted: Dictionary = _diffs(sim, checkpoints[points[3]][2], after_interactions)
		interacted.merge(_slot_diffs(sim.wram1, String(checkpoints[points[3]][3]).hex_decode()))
		if not interacted.is_empty():
			return _stopped(start_frame, compared, at, "", {"after ProcessInteractions": interacted}, true)
		sim.draw_and_update_camera()
		var diffs: Dictionary = _diffs(sim, frames[i][2], compared_names)
		if not _div_diffs(sim).is_empty():
			diffs["rDIV"] = _div_diffs(sim)
		if not diffs.is_empty():
			return _stopped(start_frame, compared, at, "", diffs, true)
		compared += 1
		sim.stream_level_edges()
		sim.check_end_screen()
		sim.update_room_animations()  # the rest of .GameLoop
		if sim.animation_replay and (not sim.animation_queue.is_empty() or not sim.animation_mismatches.is_empty()):
			return _stopped(start_frame, compared, at, "", {"animation calls": [sim.animation_mismatches,
					sim.animation_queue.size()]}, true)
		_temple_after(sim, at, temple_shown)
	return {"mode": "run", "start_frame": start_frame, "frames_compared": compared, "mismatched": 0,
			"stopped": "end of trace", "with_objects": true, "from_map": from_map, "within_level": within_level,
			"within_level_seeded": seeded.duplicate(), "temple": temple_drawn,
			"screens": _run_screens_after_level(trace, sim, int(frames[frames.size() - 1][0]), div_reads,
					animation_calls, not from_map.get("entered", false))}


## The fight's drawing data from the trace (by frame) and a TempleVram for the run, when the trace
## recorded the Temple's screens and the content has temple.json.
func _temple_setup(trace: Dictionary, objects_doc: Dictionary) -> void:
	var path: String = content_dir.path_join("temple.json")
	if not trace.has("temple_vram") or not FileAccess.file_exists(path):
		return
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not document is Dictionary:
		return
	temple_vram = TempleVram.new(document, objects_doc.get("room_animation", {}),
			WarioSprites.load_file(content_dir.path_join("wario_sprites.json")), ObjectSprites.from_document(objects_doc))
	for snapshot: Array in trace["temple_vram"]:
		temple_snapshots[int(snapshot[0])] = snapshot
	for screen: Array in trace.get("temple_screens", []):
		temple_screens[int(screen[0])] = screen[1]
	for write: Array in trace.get("pal_writes", []):
		if not temple_pal_writes.has(int(write[0])):
			temple_pal_writes[int(write[0])] = []
		temple_pal_writes[int(write[0])].append(write)
	for copy: Array in trace.get("animation_copies", []):
		if not temple_copies.has(int(copy[0])):
			temple_copies[int(copy[0])] = []
		temple_copies[int(copy[0])].append(int(copy[1]))
	temple_drawn = {"vram_checked": 0, "vram_matched": 0, "screens_checked": 0, "screens_matched": 0,
			"palette_calls_checked": 0, "palette_calls_matched": 0, "examples": []}


## Before a compared frame's loop in the Temple: TempleVram as the loops so far leave it, against the
## trace's snapshot at this loop's start; for a frame whose screen the trace has, what that frame
## starts with: [VRAM and palettes, OAM, rSCX and rSCY, the figure's SetBGPals calls so far].
func _temple_before(sim: LevelSim, at: int) -> Array:
	if temple_vram == null or sim.wLevel != LevelSim.THE_TEMPLE:
		return []
	temple_vram.update(sim)
	if temple_vram.screen.is_empty():
		return []
	if temple_snapshots.has(at):
		temple_drawn["vram_checked"] += 1
		var diffs: Array = _vram_diffs(temple_vram, temple_snapshots[at])
		if diffs.is_empty():
			temple_drawn["vram_matched"] += 1
		elif temple_drawn["examples"].size() < MAX_EXAMPLES:
			temple_drawn["examples"].append({"frame": at, "vram": diffs})
	return [temple_vram.copy(), temple_vram.oam.duplicate(), temple_vram.scx, temple_vram.scy,
			sim.hidden_figure_bg_pal_writes]


## After it: the frame drawn while the loop ran against the trace's screen, from what it started with,
## the loop's rWY, and what the loop wrote while it was drawn, from the lines the trace recorded: the
## animated tiles' chunks and each palette (its bytes the port's after the loop: palette `count -
## left` of a call writing `count` from palette 0). The figure's SetBGPals calls are checked against
## the trace's in every frame: how many, and the bytes' source.
func _temple_after(sim: LevelSim, at: int, shown: Array) -> void:
	if shown.is_empty():
		return
	temple_vram.update(sim)
	var calls: Array = []  # [kind, count, first write's source], with each write's [line, kind, palette]
	var writes: Array = []
	for write: Array in temple_pal_writes.get(at, []):
		var kind: int = int(write[1])
		var left: int = int(write[3])
		if calls.is_empty() or int(calls[-1][0]) != kind or left >= int(writes[-1][3]):
			calls.append([kind, left, int(write[4])])
		writes.append([int(write[2]), kind, int(calls[-1][1]) - left, left])
	var bg_calls: Array = calls.filter(func(call: Array) -> bool: return int(call[0]) == 0)
	var port_calls: int = sim.hidden_figure_bg_pal_writes - int(shown[4])
	if not bg_calls.is_empty() or port_calls != 0:
		temple_drawn["palette_calls_checked"] += 1
		var source: int = sim.hidden_figure_bg_pals
		if bg_calls.size() == port_calls and bg_calls.all(func(call: Array) -> bool: return int(call[2]) == source):
			temple_drawn["palette_calls_matched"] += 1
		elif temple_drawn["examples"].size() < MAX_EXAMPLES:
			temple_drawn["examples"].append({"frame": at, "SetBGPals": [port_calls, "%04x" % source,
					bg_calls.map(func(call: Array) -> String: return "%04x" % int(call[2]))]})
	if not temple_screens.has(at):
		return
	var line_writes: Array = []
	if temple_vram.animation_written:
		var chunk: int = 0
		for line: int in temple_copies.get(at, []):
			line_writes.append([line, 1, 0x9700 + chunk * 8, temple_vram.vram[1].slice(0x1700 + chunk * 8, 0x1700 + chunk * 8 + 8)])
			chunk += 1
	for write: Array in writes:
		var palette: int = int(write[2])
		var bytes: PackedByteArray = (temple_vram.bg_palettes if int(write[1]) == 0 else temple_vram.obj_palettes).slice(
				palette * 8, palette * 8 + 8)
		line_writes.append([int(write[0]), CgbScreen.BG_PALETTE if int(write[1]) == 0 else CgbScreen.OBJ_PALETTE,
				palette, bytes])
	line_writes.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	temple_drawn["screens_checked"] += 1
	var pixels: Array = _pixel_diffs(shown[0], shown[1], TempleVram.LCDC, int(shown[2]), int(shown[3]), TempleVram.WX,
			temple_screens[at], line_writes, sim.rWY)
	if pixels.is_empty():
		temple_drawn["screens_matched"] += 1
	elif temple_drawn["examples"].size() < MAX_EXAMPLES:
		temple_drawn["examples"].append({"frame": at, "pixels": pixels})


## The `gap` game loops between two compared level frames (after `from_frame`'s, before `at`'s,
## counted `counter`): natively with the joypad as it is (a door's effect, fades, the room start); or,
## when a screen recorded loops among them (the pause menu, opened and left for the level again), as
## the screens after a level are run (_run_screens: what the level does not keep forgotten, each
## traced loop compared and run with its joypad), then the loops after the last, and `at`'s rDIV
## reads and room animation calls fed again for its update. {} or why it stopped: "reason" ("" for
## a difference), "diffs", and the screens' "screens".
func _run_level_gap(trace: Dictionary, sim: LevelSim, from_frame: int, at: int, gap: int, counter: int,
		div_reads: Dictionary, animation_calls: Dictionary) -> Dictionary:
	var last_screen: int = -1
	for key: String in screen_docs:
		for entry: Array in trace.get(key + "_updates", []):
			if int(entry[0]) > from_frame and int(entry[0]) < at:
				last_screen = maxi(last_screen, int(entry[0]))
	if last_screen < 0:
		for loop: int in gap:
			sim.update_level()
			if not sim.unported.is_empty():
				return {"reason": sim.unported[0]}
		return {}
	var setup: bool = not sim.sync_screen_wram
	seeded_since_level.clear()
	if not setup:
		_forget_level_ram(sim)
	var screens: Dictionary = _run_screens(trace, sim, from_frame, div_reads, animation_calls, at, setup)
	if screens.has("stopped_at_frame"):
		return {"reason": "" if String(screens["stopped"]) == "a difference" else String(screens["stopped"]),
				"diffs": screens.get("diffs", {}), "screens": screens}
	for key: String in screens["by_screen"]:
		within_level[key] = int(within_level.get(key, 0)) + int(screens["by_screen"][key])
	var rest: Dictionary = _run_untraced(sim, int(screens["counter"]), counter, range(last_screen + 1, at), div_reads,
			animation_calls)
	if not rest.is_empty():
		return {"reason": rest["reason"], "diffs": rest["diffs"], "screens": screens}
	_feed_div(sim, div_reads.get(at, []))
	sim.animation_queue.clear()
	sim.animation_mismatches.clear()
	sim.animation_queue.append_array(animation_calls.get(at, []))
	return {}


## frame -> the room animation calls ([kind, line]) the trace recorded in it, in order.
func _animation_calls_by_frame(trace: Dictionary) -> Dictionary:
	var calls: Dictionary = {}
	for call: Array in trace.get("animation_calls", []):
		if not calls.has(int(call[0])):
			calls[int(call[0])] = []
		calls[int(call[0])].append([int(call[1]), int(call[2])])
	return calls


## Whether a run starts at power-on: the movie's save is given, the window starts at the trace's
## start, and the title is the first screen the trace records.
func _from_power_on(trace: Dictionary) -> bool:
	if power_on_save == null or not screen_docs.has("title") or trace.get("title_updates", []).is_empty():
		return false
	var first_title: int = int(trace["title_updates"][0][0])
	for key: String in screen_docs:
		var updates: Array = trace.get(key + "_updates", [])
		if key != "title" and not updates.is_empty() and int(updates[0][0]) < first_title:
			return false
	return trace.get("updates", []).is_empty() or int(trace["updates"][0][0]) > first_title


## The game at power-on (WL3-055): the screens' data, and the RAM as Init leaves it for its first loop
## with the movie's battery save loaded (LevelRunner.load_power_on_ram), every byte known: nothing is
## taken from the trace. The counter is the one before the first loop's 0.
func _power_on(sim: LevelSim) -> void:
	sim.level_loader = _level_loader()
	_load_screens(sim)
	LevelRunner.load_power_on_ram(sim, power_on_save)
	sim.wGlobalCounter = 0xFF
	for key: String in screen_docs:
		seeded_since_level[key] = true
		seen_screens[key] = true
	_check_loads(sim)


## The run's loads so far (power-on's, then one a reset) against the original's (`loads`): SRAM banks
## 0-3 as ValidateSaveData left them (the LevelSim's loaded_sram) and as the original's InitGameState
## found them, byte for byte. A load the run made between two checks is noted unchecked.
func _check_loads(sim: LevelSim) -> void:
	while load_checks.size() <= sim.resets and load_checks.size() < loads.size():
		var index: int = load_checks.size()
		if index < sim.resets:
			load_checks.append([index + 1, -1, []])
			continue
		var capture: Variant = JSON.parse_string(FileAccess.get_file_as_string(loads[index]))
		if not capture is Dictionary:
			load_checks.append([index + 1, -1, ["cannot read %s" % loads[index]]])
			continue
		var differing: int = 0
		var examples: Array = []
		for bank: int in 4:
			var original: PackedByteArray = String(capture["after"]["sram%d" % bank]).hex_decode()
			var native: PackedByteArray = sim.loaded_sram[bank] if sim.loaded_sram.size() == 4 else PackedByteArray()
			for offset: int in original.size():
				if offset >= native.size() or native[offset] != original[offset]:
					differing += 1
					if examples.size() < 6:
						examples.append("SRAM%d:%04x %s/%02x" % [bank, 0xA000 + offset,
								"%02x" % native[offset] if offset < native.size() else "--", original[offset]])
		load_checks.append([index + 1, differing, examples])


## The levels InitLevel loads, from the extracted content.
func _level_loader() -> Callable:
	return func(number: int) -> LevelCollision:
		var path: String = content_dir.path_join("levels/level-%02x.json" % number)
		return LevelCollision.load_file(path) if FileAccess.file_exists(path) else null


## The screens after a level (_run_screens), with what the level's port does not keep forgotten first.
func _run_screens_after_level(trace: Dictionary, sim: LevelSim, after: int, div_reads: Dictionary,
		animation_calls: Dictionary, setup: bool) -> Dictionary:
	seeded_since_level.clear()
	if not setup:
		_forget_level_ram(sim)
	return _run_screens(trace, sim, after, div_reads, animation_calls, -1, setup)


## LEVEL_RAM_NOT_KEPT marked unknown: the level writes it from its start to its end.
func _forget_level_ram(sim: LevelSim) -> void:
	if not sim.screen_wram.has("known"):
		return
	for range_: Array in LEVEL_RAM_NOT_KEPT:
		for offset: int in int(range_[2]):
			sim.screen_wram["known"][int(range_[0])][int(range_[1]) - 0xC000 + offset] = 0


## A run from the map, when the window starts there (WL3-052), or from power-on (_power_on, WL3-055):
## the native game is seeded from the first screen loop (the map's, as the trace has it: what the run
## starts from) or starts at power-on with nothing seeded, then the screens' loops
## before the level run natively from the trace's input alone, each compared before it runs, and the
## loops after the last (the way into the level: the fade, InitLevel loading the level wLevel, the fade
## in) up to the level's first update at `start_frame`. "entered" when the native game is then at that
## update in a level (UpdateLevel's sub-state).
func _run_from_map(trace: Dictionary, sim: LevelSim, start_frame: int, div_reads: Dictionary,
		animation_calls: Dictionary) -> Dictionary:
	var map_updates: Array = trace.get("overworld_updates", [])
	var power_on: bool = _from_power_on(trace)
	if not power_on and (not screen_docs.has("overworld") or map_updates.is_empty()
			or int(map_updates[0][0]) >= start_frame):
		return {"checked": false}
	var first_map: int = int(map_updates[0][0]) if not map_updates.is_empty() else -1
	var result: Dictionary
	if power_on:
		_power_on(sim)
		result = _run_screens(trace, sim, -1, div_reads, animation_calls, start_frame, false)
		result["power_on"] = true
	else:
		sim.level_loader = _level_loader()
		_load_screens(sim)
		sim.load_values(names, trace["frames"][first_map])
		var map_names: PackedStringArray = PackedStringArray()
		for variable: Dictionary in trace["overworld_variables"]:
			map_names.append(String(variable["name"]))
		for i: int in map_names.size():
			if not map_names[i] in sim.overworld and map_names[i] in WarioRam.TRACED:
				sim.set(map_names[i], int(map_updates[0][1][i]))
		result = _run_screens(trace, sim, first_map - 1, div_reads, animation_calls, start_frame, false, true)
	if result.has("stopped_at_frame"):
		return result
	# The way into the level: the loops no screen recorded, to the level's first update, each but the last
	# still on its way in.
	var target: int = _v(trace["updates"].filter(func(u: Array) -> bool: return int(u[0]) == start_frame)[0][1],
			"wGlobalCounter")
	var counter: int = int(result.get("counter", sim.wGlobalCounter))
	var entry_loops: int = (target - counter - 1) & 0xFF
	# The last screen loop before the level: the map's, or from power-on the title's when no map came.
	var last_map: int = first_map
	for key: String in (["overworld", "title"] if power_on else ["overworld"]):
		for entry: Array in trace.get(key + "_updates", []):
			if int(entry[0]) < start_frame:
				last_map = maxi(last_map, int(entry[0]))
	var reads: Array = []
	sim.animation_queue.clear()
	sim.animation_mismatches.clear()
	for frame: int in range(last_map + 1, start_frame):
		reads.append_array(div_reads.get(frame, []))
		sim.animation_queue.append_array(animation_calls.get(frame, []))
	_feed_div(sim, reads)
	sim.wJoypadDown = 0
	sim.wJoypadPressed = 0
	result["entry_loops"] = entry_loops
	for loop: int in entry_loops:
		counter = (counter + 1) & 0xFF
		sim.wGlobalCounter = counter
		sim.update_level()
		if not sim.unported.is_empty():
			result.merge({"stopped": sim.unported[0], "stopped_at_frame": start_frame, "entry_loops": loop + 1}, true)
			return result
		if loop + 1 < entry_loops and sim.wState == LevelSim.ST_LEVEL and sim.wSubState == LEVEL_PLAYING:
			result.merge({"stopped": "a difference", "stopped_at_frame": start_frame,
					"diffs": {"loops into the level": [loop + 1, entry_loops]}}, true)
			return result
	var diffs: Dictionary = {}
	if sim.wState != LevelSim.ST_LEVEL or sim.wSubState != LEVEL_PLAYING:
		diffs.merge({"wState": [sim.wState, LevelSim.ST_LEVEL], "wSubState": [sim.wSubState, LEVEL_PLAYING]})
	if not _div_diffs(sim).is_empty():
		diffs["rDIV"] = _div_diffs(sim)
	if sim.animation_replay and (not sim.animation_mismatches.is_empty() or not sim.animation_queue.is_empty()):
		diffs["animation calls"] = [Array(sim.animation_mismatches), sim.animation_queue.size()]
	result["entered"] = diffs.is_empty()
	if not diffs.is_empty():
		result.merge({"stopped": "a difference", "diffs": diffs, "stopped_at_frame": start_frame}, true)
	return result


## After a run reaches the level's last frame (`after`): the screens that follow it (the clear
## screen, Action Help, the map, its save screen) run natively from the trace's input alone (WL3-052).
## Before each traced loop the native game is compared with it (the screen's variables, its RAM
## ranges, and the virtual OAM); then the loop runs with that loop's joypad and wGlobalCounter, the
## rDIV reads and room animation calls of its frames replayed. Loops no screen recorded run natively
## with the last joypad. Stops at the first difference or unported routine.
func _run_screens(trace: Dictionary, sim: LevelSim, after: int, div_reads: Dictionary,
		animation_calls: Dictionary, before: int = -1, setup: bool = true, start: bool = false) -> Dictionary:
	if screen_docs.is_empty():
		return {"checked": false}
	var names_by: Dictionary = {}
	# [frame, key, entry, counter], in frame order; loops that share a frame (a fast loop can), also
	# across screens, by wGlobalCounter (the one before the other by less than half its range).
	var entries: Array = []
	for key: String in screen_docs:
		var screen_names := PackedStringArray()
		for variable: Dictionary in trace[key + "_variables"]:
			screen_names.append(String(variable["name"]))
		names_by[key] = screen_names
		var counter_at: int = screen_names.find("wGlobalCounter")
		for entry: Array in trace.get(key + "_updates", []):
			if int(entry[0]) > after and (before < 0 or int(entry[0]) < before):
				entries.append([int(entry[0]), key, entry, int(entry[1][counter_at])])
	entries.sort_custom(func(a: Array, b: Array) -> bool:
		if int(a[0]) != int(b[0]):
			return int(a[0]) < int(b[0])
		var ahead: int = (int(b[3]) - int(a[3])) & 0xFF
		return ahead > 0 and ahead < 0x80)
	if entries.is_empty():
		return {"checked": false}
	if setup:
		_load_screens(sim)
	var by_screen: Dictionary = {}
	var counter: int = sim.wGlobalCounter
	var compared: int = 0
	if not start:
		# The loops between the level's last frame and the first screen loop, with their frames' replays.
		var first_counter: int = int(entries[0][2][1][names_by[entries[0][1]].find("wGlobalCounter")])
		var stop: Dictionary = _run_untraced(sim, counter, first_counter, range(after + 1, int(entries[0][0])),
				div_reads, animation_calls)
		if not stop.is_empty():
			return _screens_stopped(compared, by_screen, int(entries[0][0]), entries[0][1], stop["reason"],
					stop["diffs"], stop["loops"])
		counter = (first_counter - 1) & 0xFF
	for i: int in entries.size():
		var key: String = entries[i][1]
		var entry: Array = entries[i][2]
		var screen_names: PackedStringArray = names_by[key]
		var at: int = int(entry[0])
		var traced_counter: int = int(entry[1][screen_names.find("wGlobalCounter")])
		var screen: ScreenSim = _native_screen(sim, key)
		if screen == null:
			return _screens_stopped(compared, by_screen, at, key, "%s not loaded" % key)
		var substate: int = int(entry[1][screen_names.find("wSubState")])
		if (key == "pause_menu" and not _pause_menu_ported(substate)) \
				or (key == "overworld" and not substate in OVERWORLD_PORTED) \
				or (key == "title" and not substate in TITLE_PORTED) \
				or (key == "language_selection" and not substate in LANGUAGE_SELECTION_PORTED) \
				or (key == "credits" and not substate in CREDITS_PORTED) \
				or (key == "game_over" and not substate in GAME_OVER_PORTED) \
				or (key == "perfect" and not substate in PERFECT_PORTED):
			return _screens_stopped(compared, by_screen, at, key, "%s sub-state %d (not ported)" % [key, substate])
		var handed_over: bool = sim._oam_screen != null
		if start and i == 0:
			# The run's start: the screen as the trace has it, and the LevelSim's shared variables from it.
			seeded.append([key, at, _seed_screen(sim, screen, trace, key, entry, true, true)])
			seeded_since_level[key] = true
			seen_screens[key] = true
			sim.adopt_screen_wram()
			sim.hand_over_oam(screen)
			if key == "overworld":  # the V-Blank function its state implies, as the step check takes it
				screen.vblank_func = _overworld_vblank(sim, screen as MenuScreenSim, screen.vblank_func)
		else:
			sim.screen_wram_in(screen)
			if not seeded_since_level.has(key):
				var seed: Dictionary = _seed_screen(sim, screen, trace, key, entry, not handed_over,
						not seen_screens.has(key))
				seeded_since_level[key] = true
				seen_screens[key] = true
				if seed["bytes"] > 0 or not seed["variables"].is_empty() or seed["oam"]:
					seeded.append([key, at, seed])
		var diffs: Dictionary = _screen_state_diffs(sim, screen, screen_names, trace.get(key + "_ram", []), entry)
		if not diffs.is_empty():
			return _screens_stopped(compared, by_screen, at, key, "", diffs)
		compared += 1
		by_screen[key] = int(by_screen.get(key, 0)) + 1
		# This loop, then the loops no screen recorded before the next traced one: together they make the
		# rDIV reads and room animation calls of the frames up to it, which must all be made.
		var next_frame: int = int(entries[i + 1][0]) if i + 1 < entries.size() else at + 1
		var next_counter: int = (traced_counter + 1) & 0xFF
		if i + 1 < entries.size():
			next_counter = int(entries[i + 1][2][1][names_by[entries[i + 1][1]].find("wGlobalCounter")])
		sim.wJoypadDown = int(entry[1][screen_names.find("wJoypadDown")])
		sim.wJoypadPressed = int(entry[1][screen_names.find("wJoypadPressed")])
		var stop: Dictionary = _run_untraced(sim, (traced_counter - 1) & 0xFF, next_counter, range(at, next_frame),
				div_reads, animation_calls, at if next_frame == at else -1)
		if not stop.is_empty():
			return _screens_stopped(compared, by_screen, at, key, stop["reason"], stop["diffs"], stop["loops"] - 1)
		counter = (next_counter - 1) & 0xFF
	return {"checked": true, "loops": compared, "by_screen": by_screen, "stopped": "end of trace", "seeded": seeded,
			"counter": counter}


## The game loops after the one counted `from_counter` up to the one counted `to_counter` (not run),
## natively with the joypad as it is, the rDIV reads and room animation calls of `frames` replayed
## across them; then every replayed read and call must have been made. A loop that sets the counter
## (the title's InitIntroSequence clears it, Init too) counts on from there. A loop the frames show
## with A, B, Select and Start held (the game's reset, which runs no state for a screen to record)
## takes that joypad (_reset_joypad). A loop that shares its frame with the next (`shared`, the frame)
## takes the frame's first room animation call of each kind; the next loop the rest. Returns {} or why
## it stopped: "reason" ("" for a difference), "diffs", and "loops" run.
func _run_untraced(sim: LevelSim, from_counter: int, to_counter: int, frames: Array, div_reads: Dictionary,
		animation_calls: Dictionary, shared: int = -1) -> Dictionary:
	var reads: Array = []
	sim.animation_queue.clear()
	sim.animation_mismatches.clear()
	for frame: int in frames:
		reads.append_array(div_reads.get(frame, []))
		sim.animation_queue.append_array(animation_calls.get(frame, []).slice(int(shared_calls_taken.get(frame, 0))))
	if shared >= 0:
		var calls: Array = animation_calls.get(shared, []).slice(int(shared_calls_taken.get(shared, 0)))
		var kinds: Dictionary = {}
		for call: Array in calls:
			if kinds.has(int(call[0])):
				break
			kinds[int(call[0])] = true
			sim.animation_queue.append(call)
		shared_calls_taken[shared] = int(shared_calls_taken.get(shared, 0)) + kinds.size()
	_feed_div(sim, reads)
	var loops: int = 0
	var counter: int = from_counter
	while (counter + 1) & 0xFF != to_counter:
		if loops == 0x100:
			return {"reason": "", "diffs": {"wGlobalCounter": [counter, (to_counter - 1) & 0xFF]}, "loops": loops}
		counter = (counter + 1) & 0xFF
		sim.wGlobalCounter = counter
		var held: int = _reset_joypad(frames, counter)
		if held >= 0:
			sim.wJoypadPressed = held & ~sim.wJoypadDown & 0xFF
			sim.wJoypadDown = held
		sim.update_level()
		loops += 1
		_check_loads(sim)
		if not sim.unported.is_empty():
			return {"reason": sim.unported[0], "diffs": {}, "loops": loops}
		counter = sim.wGlobalCounter
	var diffs: Dictionary = {}
	if not _div_diffs(sim).is_empty():
		diffs["rDIV"] = _div_diffs(sim)
	if sim.animation_replay and (not sim.animation_mismatches.is_empty() or not sim.animation_queue.is_empty()):
		diffs["animation calls"] = [Array(sim.animation_mismatches), sim.animation_queue.size()]
	return {} if diffs.is_empty() else {"reason": "", "diffs": diffs, "loops": loops}


## The joypad of the loop counted `counter` when one of `frames` shows it with A, B, Select and Start
## held (it read them and reset: its counter stays while Init runs), else -1.
func _reset_joypad(frames: Array, counter: int) -> int:
	for frame: int in frames:
		if frame < trace_frames.size() and _v(trace_frames[frame], "wGlobalCounter") == counter \
				and (_v(trace_frames[frame], "wJoypadDown") & LevelSim.PAD_BUTTONS) == LevelSim.PAD_BUTTONS:
			return _v(trace_frames[frame], "wJoypadDown")
	return -1


## The screens' data into a run's LevelSim, kept as one RAM with it, the bytes not yet written unknown.
func _load_screens(sim: LevelSim) -> void:
	if screen_docs.has("clear"):
		sim.load_clear_data(screen_docs["clear"])
	if screen_docs.has("action_help"):
		sim.load_action_help_data(screen_docs["action_help"])
	if screen_docs.has("pause_menu"):
		sim.load_pause_menu_data(screen_docs["pause_menu"])
	if screen_docs.has("overworld"):
		sim.load_overworld_data(screen_docs["overworld"])
	if screen_docs.has("title") or screen_docs.has("language_selection"):
		sim.load_title_data(screen_docs.get("title", screen_docs.get("language_selection")))
	if screen_docs.has("golf_building"):
		sim.load_golf_data(screen_docs["golf_building"])
	if screen_docs.has("credits"):
		sim.load_credits_data(screen_docs["credits"])
	if screen_docs.has("game_over"):
		sim.load_game_over_data(screen_docs["game_over"])
	if screen_docs.has("perfect"):
		sim.load_perfect_data(screen_docs["perfect"])
	sim.sync_screen_wram = true
	sim.track_known_ram()


## What the screens before a run left in RAM, which the run did not see written: the bytes of the
## screen's RAM ranges and its WRAM0 variables the native game has not written, its HRAM variables the
## first time the run meets the screen (`hram`; the LevelSim's, which the screens share, once a run),
## and (for the first screen after a level, whose sprites the port does not keep as a virtual OAM) the
## virtual OAM, set from the screen's first traced loop. Returns what was seeded.
func _seed_screen(sim: LevelSim, screen: ScreenSim, trace: Dictionary, key: String, entry: Array, oam: bool,
		hram: bool) -> Dictionary:
	var bytes: int = 0
	var values: PackedByteArray = String(entry[2]).hex_decode()
	var at: int = 0
	for range_: Dictionary in trace.get(key + "_ram", []):
		var start: int = String(range_["address"]).hex_to_int()
		var bank: int = int(range_["bank"])
		for offset: int in int(range_["size"]):
			if not screen.ram_known(bank, start + offset):
				screen.ram_write(bank, start + offset, values[at])
				bytes += 1
			at += 1
	var variables: PackedStringArray = PackedStringArray()
	for i: int in trace[key + "_variables"].size():
		var variable: Dictionary = trace[key + "_variables"][i]
		var name: String = variable["name"]
		var address: int = String(variable["address"]).hex_to_int()
		if name == "wVirtualOAMByteSize":
			continue
		if not name in screen:
			if address >= 0xFF80 and hram and name in sim and not seeded_hram.has(name):
				sim.set(name, int(entry[1][i]))
				seeded_hram[name] = true
				variables.append(name)
			continue
		if (address >= 0xFF80 and hram) or (address < 0xFF80 and not screen.ram_known(0, address)):
			screen.set(name, int(entry[1][i]))
			variables.append(name)
	if oam:
		screen.wVirtualOAM = String(entry[3]).hex_decode()
		var size_at: int = -1
		for i: int in trace[key + "_variables"].size():
			if trace[key + "_variables"][i]["name"] == "wVirtualOAMByteSize":
				size_at = i
		if size_at >= 0:
			screen.wVirtualOAMByteSize = int(entry[1][size_at])
	return {"bytes": bytes, "variables": variables, "oam": oam}


func _native_screen(sim: LevelSim, key: String) -> ScreenSim:
	match key:
		"clear":
			return sim.clear
		"action_help":
			return sim.action_help
		"pause_menu":
			return sim.pause_menu_screen
		"overworld":
			return sim.overworld
		"title", "language_selection":
			return sim.title
		"credits":
			return sim.credits
		"game_over":
			return sim.game_over
		"perfect":
			return sim.perfect
		"golf_building":
			return sim.golf
	return null


func _screens_stopped(compared: int, by_screen: Dictionary, at: int, key: String, reason: String,
		diffs: Dictionary = {}, untraced: int = 0) -> Dictionary:
	var result: Dictionary = {"checked": true, "loops": compared, "by_screen": by_screen, "stopped_at_frame": at,
			"screen": key, "stopped": "a difference" if reason.is_empty() else reason, "untraced_loops": untraced}
	if not diffs.is_empty():
		var shown: Dictionary = {}
		for name: String in diffs.keys().slice(0, 40):
			shown[name] = diffs[name]
		result["diffs"] = shown
		result["differences"] = diffs.size()
		result["differing"] = diffs.keys()
	return result


## A run that ended early: `reason` empty means the port itself differs (`diffs`).
func _stopped(start_frame: int, compared: int, at: int, reason: String, diffs: Dictionary = {},
		with_objects: bool = false) -> Dictionary:
	var result: Dictionary = {"mode": "run", "start_frame": start_frame, "frames_compared": compared,
			"mismatched": 1 if reason.is_empty() else 0, "stopped_at_frame": at,
			"stopped": "a difference" if reason.is_empty() else reason, "with_objects": with_objects}
	if not diffs.is_empty():
		result["diffs"] = diffs
	return result


## Variables that differ between two oracle snapshots.
func _between(first: Array, second: Array, compared: PackedStringArray) -> Dictionary:
	var diffs: Dictionary = {}
	for name: String in compared:
		if index_of.has(name) and _v(first, name) != _v(second, name):
			diffs[name] = [_v(first, name), _v(second, name)]
	return diffs


## Every room transition: from the oracle's variables after the update that started it, the native
## model finishes that frame (camera) and runs the level sub-states until play resumes; it must take
## as many game loops as the oracle (by wGlobalCounter) and match the next update's "before".
func _transitions(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary = {}) -> Dictionary:
	var updates: Array = trace["updates"]
	var results: Array = []
	var compared_names: PackedStringArray = COMPARED.duplicate()
	compared_names.append_array(START_CAMERA_COMPARED)
	compared_names.append("wLevelRoomID")
	var checkpoints: Array = trace.get("object_checkpoints", [])
	var truth := MapTruth.new(level, trace)
	for i: int in updates.size() - 1:
		var after: Array = updates[i][2]
		var frame: int = int(updates[i][0])
		if _v(after, "wSubState") == LEVEL_PLAYING:
			continue
		# The maps before this frame: the native run streams this frame's edges (and spawns) itself.
		truth.advance(frame)
		var sim := LevelSim.new()
		sim.tables = tables
		sim.level = truth.level.copy()
		sim.load_object_data(objects_doc)
		var start_objects: int = _checkpoint_at(checkpoints, frame, 3)
		if start_objects >= 0:
			sim.wram1 = String(checkpoints[start_objects][3]).hex_decode()
		sim.load_values(names, after)
		_attach_golf(sim, frame, objects_doc)
		var golf_reads: Array = golf_div_reads.filter(func(read: Array) -> bool:
			return int(read[0]) > frame and int(read[0]) < int(updates[i + 1][0]))
		if sim.golf != null and not golf_reads.is_empty():
			_feed_div(sim, golf_reads)
		sim.update_level_after_objects()
		sim.stream_level_edges()
		var next_before: Array = updates[i + 1][1]
		var expected_loops: int = _loops_between(frame, int(updates[i + 1][0]), _v(after, "wGlobalCounter"),
				_v(next_before, "wGlobalCounter"))
		var loops: int = 0
		while ((sim.wSubState != LEVEL_PLAYING or sim.wState != LEVEL_STATE) and loops < maxi(1000, expected_loops + 10)
				and sim.unported.is_empty()):
			sim.update_level()
			loops += 1
		var diffs: Dictionary = _diffs(sim, next_before, compared_names)
		# The new room's objects (spawned and updated twice) against its first UpdateLevel's UpdateObjects.
		var object_diffs: Dictionary = {}
		var spawn_diffs: Dictionary = {}
		var next_objects: int = _first_level_objects_after(checkpoints, frame)
		# A run stopped at something unported (the golf minigame's room) spawned nothing to compare.
		if next_objects >= 0 and start_objects >= 0 and sim.unported.is_empty():
			object_diffs = _slot_diffs(sim.wram1, String(checkpoints[next_objects][3]).hex_decode())
			# The room start's first UpdateObjects holds the slots as spawned.
			var spawned: int = _first_checkpoint_after(checkpoints, frame, 0)
			if spawned >= 0:
				spawn_diffs = _slot_diffs(sim.spawned_wram1, String(checkpoints[spawned][3]).hex_decode())
		results.append({"frame": frame, "room": [_v(after, "wLevelRoomID"), sim.wLevelRoomID],
				"door": _v(after, "wSubState") == LevelSim.SST_DOOR_TRANSITION, "loops": loops,
				"expected_loops": expected_loops, "unported": Array(sim.unported), "diffs": diffs,
				"spawned": _active_slots(sim.spawned_wram1) if not sim.spawned_wram1.is_empty() else 0,
				"object_unported": Array(sim.object_unported),
				"spawn_diffs": spawn_diffs, "object_diffs": object_diffs})
	var matched: int = results.filter(func(r: Dictionary) -> bool:
		return r["diffs"].is_empty() and r["unported"].is_empty() and r["loops"] == r["expected_loops"]).size()
	return {"checked": results.size(), "matched": matched, "results": results}


## The index of the checkpoint `kind` recorded at `frame`, or -1.
func _checkpoint_at(checkpoints: Array, frame: int, kind: int) -> int:
	for i: int in checkpoints.size():
		if int(checkpoints[i][0]) == frame and int(checkpoints[i][1]) == kind:
			return i
		if int(checkpoints[i][0]) > frame:
			break
	return -1


func _first_checkpoint_after(checkpoints: Array, frame: int, kind: int) -> int:
	for i: int in checkpoints.size():
		if int(checkpoints[i][0]) > frame and int(checkpoints[i][1]) == kind:
			return i
	return -1


## The first UpdateLevel UpdateObjects (checkpoint 0 followed by 1) after `frame`, or -1.
func _first_level_objects_after(checkpoints: Array, frame: int) -> int:
	for i: int in range(checkpoints.size() - 1):
		if int(checkpoints[i][0]) > frame and int(checkpoints[i][1]) == 0 and int(checkpoints[i + 1][1]) == 1:
			return i
	return -1


## The native level start (WarioSim.start_level) against the oracle's variables before its first
## Wario update. No Wario update runs while the level fades in, so they should agree.
func _start_check(trace: Dictionary, level: LevelCollision, tables: WarioTables, objects_doc: Dictionary = {}) -> Dictionary:
	if trace["updates"].is_empty() or level.start.is_empty():
		return {"checked": false, "reason": "no updates or no level start"}
	var first: Array = trace["frames"][window_start]
	if _v(first, "wState") == LEVEL_STATE and _v(first, "wSubState") == LEVEL_PLAYING:
		return {"checked": false, "reason": "the trace starts in a level already being played"}
	var before: Array = trace["updates"][0][1]
	var room: int = int(level.start["level_room_id"])
	var sim := LevelSim.new()
	sim.tables = tables
	sim.level = level.copy()
	sim.load_object_data(objects_doc)
	# What the level start leaves alone keeps what the game held before it (wFloor, in a room without
	# floor transitions, keeps the last level's): the traced values of the last frame before the level.
	var held: Array = first
	var level_number: int = -1
	for index: int in range(window_start, trace["frames"].size()):
		var frame: Array = trace["frames"][index]
		if _v(frame, "wState") == LEVEL_STATE:
			# A level resumed from a save (wceef bits 2-5) starts from the save's RAM and SRAM, which the
			# trace does not hold whole: the run from power-on checks it.
			if index_of.has("wceef") and (_v(frame, "wceef") & 0x3C) != 0:
				return {"checked": false, "reason": "the level is resumed from a save (MODE=run checks it from power-on)"}
			level_number = _v(frame, "wLevel")
			break
		held = frame
	sim.load_values(names, held)
	# The map's last loop chose the level (SelectLevel) in the tick that entered it: wLevel is the
	# level's own (the Temple's start differs by it).
	if level_number >= 0:
		sim.wLevel = level_number
	sim.start_level_with_camera(room, int(level.start["wario_x"]), int(level.start["wario_y"]), level.room_fields[room])
	sim.vblank()  # the fade-in's V-Blanks run before the first update
	var diffs: Dictionary = _diffs(sim, before)
	diffs.merge(_diffs(sim, before, START_CAMERA_COMPARED))
	# The objects the room start spawned and updated twice, against UpdateLevel's first UpdateObjects.
	var object_diffs: Dictionary = {}
	var spawn_diffs: Dictionary = {}
	var objects_checked: bool = false
	var checkpoints: Array = trace.get("object_checkpoints", [])
	for i: int in checkpoints.size():
		if int(checkpoints[i][1]) == 0:
			spawn_diffs = _slot_diffs(sim.spawned_wram1, String(checkpoints[i][3]).hex_decode())
			break
	for i: int in range(checkpoints.size() - 1):
		if int(checkpoints[i][1]) == 0 and int(checkpoints[i + 1][1]) == 1:
			object_diffs = _slot_diffs(sim.wram1, String(checkpoints[i][3]).hex_decode())
			objects_checked = not objects_doc.is_empty()
			break
	return {"checked": true, "frame": int(trace["updates"][0][0]), "unported": Array(sim.unported), "diffs": diffs,
			"objects_checked": objects_checked, "object_unported": Array(sim.object_unported),
			"spawned": _active_slots(sim.spawned_wram1), "spawn_diffs": spawn_diffs, "object_diffs": object_diffs}


## Differences in the 8 slots, by "slot N +OF": [native, original].
func _slot_diffs(native: PackedByteArray, original: PackedByteArray) -> Dictionary:
	var diffs: Dictionary = {}
	for offset: int in 0x100:
		if native[offset] != original[offset]:
			diffs["slot %d +%02x" % [offset / 32, offset % 32]] = [native[offset], original[offset]]
	return diffs


func _active_slots(bytes: PackedByteArray) -> int:
	var count: int = 0
	for slot: int in 8:
		if (bytes[slot * 32] & 1) != 0:
			count += 1
	return count


## UpdateLevel's camera code, one run at a time: the oracle's variables before it, the native
## camera, and the oracle's variables after it.
func _camera_step(trace: Dictionary) -> Dictionary:
	if not trace.has("camera_updates"):
		return {"checked": false}
	var sim := LevelSim.new()
	var matched: int = 0
	var mismatched: int = 0
	var by_mode: Dictionary = {}
	var examples: Array = []
	for update: Array in trace["camera_updates"]:
		var before: Array = update[1]
		sim.load_values(names, before)
		sim.unported.clear()
		sim.update_camera()
		var mode: String = "$%02x" % _v(before, "wCameraConfigFlags")
		if not by_mode.has(mode):
			by_mode[mode] = {"matched": 0, "mismatched": 0}
		var diffs: Dictionary = _diffs(sim, update[2], CAMERA_COMPARED)
		if diffs.is_empty():
			matched += 1
			by_mode[mode]["matched"] += 1
		else:
			mismatched += 1
			by_mode[mode]["mismatched"] += 1
			if examples.size() < MAX_EXAMPLES:
				examples.append({"frame": int(update[0]), "mode": mode, "diffs": diffs})
	return {"checked": true, "updates": trace["camera_updates"].size(), "matched": matched,
			"mismatched": mismatched, "by_mode": by_mode, "examples": examples}


func _diffs(sim: WarioSim, after: Array, compared: PackedStringArray = COMPARED) -> Dictionary:
	var diffs: Dictionary = {}
	for name: String in compared:
		if not index_of.has(name):
			continue
		var native: int = sim.value_of(name)
		var oracle: int = _v(after, name)
		if native != oracle:
			diffs[name] = [native, oracle]
	return diffs


func _first_level(trace: Dictionary) -> int:
	for update: Array in trace["updates"]:
		return _v(update[1], "wLevel")
	for frame: Array in trace["frames"]:
		if _v(frame, "wState") == LEVEL_STATE:
			return _v(frame, "wLevel")
	return 0


func _v(frame: Array, name: String) -> int:
	return int(frame[index_of[name]])


func _args() -> Dictionary:
	var parsed: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			parsed[arg.substr(2, arg.find("=") - 2)] = arg.substr(arg.find("=") + 1)
	return parsed


func _finish(report: Dictionary, code: int) -> void:
	print("WARIO_PARITY " + JSON.stringify(_summary(report)))
	quit(code)


## A report as printed: without the camera's and the update check's examples.
func _summary(report: Dictionary) -> Dictionary:
	var summary: Dictionary = report.duplicate(true)
	summary.erase("examples")
	if summary.has("camera") and summary["camera"] is Dictionary:
		summary["camera"].erase("examples")
	return summary
