class_name InputSetup
extends RefCounted
## Registers default keyboard and controller bindings at startup and samples them per tick.
## Controller bindings are configured but have not been exercised on hardware yet.

const DEADZONE: float = 0.5
const BINDINGS: Dictionary = {
	"wl3_right": {"bit": InputBits.RIGHT, "keys": [KEY_RIGHT, KEY_D], "buttons": [JOY_BUTTON_DPAD_RIGHT], "axis": [JOY_AXIS_LEFT_X, 1.0]},
	"wl3_left": {"bit": InputBits.LEFT, "keys": [KEY_LEFT, KEY_A], "buttons": [JOY_BUTTON_DPAD_LEFT], "axis": [JOY_AXIS_LEFT_X, -1.0]},
	"wl3_up": {"bit": InputBits.UP, "keys": [KEY_UP, KEY_W], "buttons": [JOY_BUTTON_DPAD_UP], "axis": [JOY_AXIS_LEFT_Y, -1.0]},
	"wl3_down": {"bit": InputBits.DOWN, "keys": [KEY_DOWN, KEY_S], "buttons": [JOY_BUTTON_DPAD_DOWN], "axis": [JOY_AXIS_LEFT_Y, 1.0]},
	# X = A and Z = B, as in the oracle's recorder and TAS editor (tools/wl3pc/tas_gui.py).
	"wl3_a": {"bit": InputBits.A, "keys": [KEY_X, KEY_J, KEY_SPACE], "buttons": [JOY_BUTTON_A], "axis": []},
	"wl3_b": {"bit": InputBits.B, "keys": [KEY_Z, KEY_K], "buttons": [JOY_BUTTON_B], "axis": []},
	"wl3_start": {"bit": InputBits.START, "keys": [KEY_ENTER], "buttons": [JOY_BUTTON_START], "axis": []},
	"wl3_select": {"bit": InputBits.SELECT, "keys": [KEY_BACKSPACE], "buttons": [JOY_BUTTON_BACK], "axis": []},
}


static func register() -> void:
	for action: String in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, DEADZONE)
		var binding: Dictionary = BINDINGS[action]
		for keycode: int in binding["keys"]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
		for button: int in binding["buttons"]:
			var joy := InputEventJoypadButton.new()
			joy.button_index = button
			InputMap.action_add_event(action, joy)
		var axis: Array = binding["axis"]
		if not axis.is_empty():
			var motion := InputEventJoypadMotion.new()
			motion.axis = axis[0]
			motion.axis_value = axis[1]
			InputMap.action_add_event(action, motion)


static func sample() -> int:
	var bits: int = 0
	for action: String in BINDINGS:
		if Input.is_action_pressed(action):
			bits |= int(BINDINGS[action]["bit"])
	return bits
