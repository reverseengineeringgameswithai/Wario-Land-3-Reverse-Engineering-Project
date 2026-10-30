class_name TestCase
extends RefCounted
## Minimal assertion base for headless tests run by res://tests/run_tests.gd.

var _failures: PackedStringArray = PackedStringArray()
var _skip_reason: String = ""


func begin() -> void:
	_failures.clear()
	_skip_reason = ""


func failures() -> PackedStringArray:
	return _failures


func skip_reason() -> String:
	return _skip_reason


func skip(reason: String) -> void:
	_skip_reason = reason


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		_failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_failures.append("%s expected %s, got %s" % [message, expected, actual])


## Absolute path to a directory in the project root (outside res://), for shared fixtures.
func repo_path(relative: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(relative).simplify_path()
