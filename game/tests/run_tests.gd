extends SceneTree
## Headless test runner. Usage (from the repository root):
##   godot --headless --path game -s res://tests/run_tests.gd
## Exit status is 1 if any script fails to compile or any test fails. Runtime script
## errors abort a test function without an assertion, so `make test-godot` also
## fails on any "SCRIPT ERROR" line in the output.

const TEST_DIR: String = "res://tests/unit"
const SOURCE_DIRS: PackedStringArray = ["res://scripts", "res://tests"]


func _initialize() -> void:
	var passed: int = 0
	var failed: int = 0
	var skipped: int = 0
	failed += _check_compiles()
	var files: PackedStringArray = DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TEST_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			print("FAIL %s: script did not compile" % file)
			failed += 1
			continue
		var suite: TestCase = script.new()
		var names: PackedStringArray = PackedStringArray()
		for method: Dictionary in suite.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_") and not method_name in names:
				names.append(method_name)
		names.sort()
		for test_name: String in names:
			suite.begin()
			suite.call(test_name)
			var label: String = "%s::%s" % [file.get_basename(), test_name]
			if not suite.skip_reason().is_empty():
				print("SKIP %s (%s)" % [label, suite.skip_reason()])
				skipped += 1
			elif suite.failures().is_empty():
				print("PASS %s" % label)
				passed += 1
			else:
				for message: String in suite.failures():
					print("FAIL %s: %s" % [label, message])
				failed += 1
	print("godot tests: %d passed, %d failed, %d skipped" % [passed, failed, skipped])
	quit(1 if failed > 0 else 0)


func _check_compiles() -> int:
	var broken: int = 0
	for path: String in _scripts_under(SOURCE_DIRS):
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			print("FAIL compile %s" % path)
			broken += 1
	return broken


func _scripts_under(roots: PackedStringArray) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var pending: Array[String] = []
	pending.assign(roots)
	while not pending.is_empty():
		var dir: String = pending.pop_back()
		for sub: String in DirAccess.get_directories_at(dir):
			pending.append(dir.path_join(sub))
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".gd") and dir.path_join(file) != "res://tests/run_tests.gd":
				found.append(dir.path_join(file))
	found.sort()
	return found
