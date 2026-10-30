extends TestCase
## Replays the bundled input trace and compares with a recorded snapshot.
## Detects unintended changes to the prototype; it is not parity evidence.

const GOLDEN: String = "res://tests/golden/walk-jump.synthetic.json"


func _golden() -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(GOLDEN)) != OK:
		fail("golden file unreadable: %s" % json.get_error_message())
		return {}
	return json.data


func _run(mods_dir: String = "") -> Dictionary:
	var loader := ContentLoader.new()
	var pack: ContentPack = loader.load_pack("res://assets/content/synthetic")
	if not mods_dir.is_empty():
		loader.apply_mods_from_dir(pack, mods_dir)
	var trace: InputTrace = loader.load_trace("res://assets/traces/walk-jump.json")
	return SimRunner.run_trace(pack, trace)


func test_trace_matches_recorded_snapshot() -> void:
	var golden: Dictionary = _golden()
	var result: Dictionary = _run()
	assert_eq(result["content_sha256"], golden["content_sha256"], "content hash")
	assert_eq(result["state_stream_sha256"], golden["state_stream_sha256"], "per-tick state stream")
	assert_eq(result["ticks"], int(golden["ticks"]), "ticks")
	var final: Dictionary = result["final"]
	for key: String in golden["final"]:
		var expected: Variant = golden["final"][key]
		assert_eq(final[key], expected if expected is bool else int(expected), "final.%s" % key)


func test_repeat_runs_are_identical_with_and_without_mods() -> void:
	assert_eq(_run(), _run(), "base content")
	var mods: String = repo_path("mods/examples")
	var modded: Dictionary = _run(mods)
	assert_eq(modded, _run(mods), "with example mod")
	assert_true(modded["state_stream_sha256"] != _run()["state_stream_sha256"], "mod changes the outcome")
