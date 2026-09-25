extends Node
# Rebindable controls. Actions are registered at runtime so project.godot stays clean.
# Overrides persist to user://vespercoil_controls.cfg; tests never trigger a save.
const SAVE_PATH: String = "user://vespercoil_controls.cfg"
const ACTIONS: Dictionary = {
	"move_up": {"label": "Move north", "key": KEY_W, "extra": [KEY_UP], "button": -1},
	"move_down": {"label": "Move south", "key": KEY_S, "extra": [KEY_DOWN], "button": -1},
	"move_left": {"label": "Move west", "key": KEY_A, "extra": [KEY_LEFT], "button": -1},
	"move_right": {"label": "Move east", "key": KEY_D, "extra": [KEY_RIGHT], "button": -1},
	"dash": {"label": "Ability", "key": KEY_SPACE, "extra": [], "button": JOY_BUTTON_B},
	"interact": {"label": "Interact", "key": KEY_E, "extra": [], "button": JOY_BUTTON_A},
	"toggle_map": {"label": "Atlas map", "key": KEY_M, "extra": [], "button": -1},
	"pause": {"label": "Pause", "key": KEY_ESCAPE, "extra": [], "button": JOY_BUTTON_START},
	"reroll": {"label": "Reroll draft", "key": KEY_R, "extra": [], "button": JOY_BUTTON_Y},
}
signal rebound(action: String, label: String)
var overrides: Dictionary = {}
var capturing: String = ""

func _ready() -> void:
	register()
	load_overrides()
	apply()

func register() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)

func load_overrides() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in ACTIONS:
		if cfg.has_section_key("bindings", action):
			overrides[action] = cfg.get_value("bindings", action, {})

func save_overrides() -> void:
	var cfg := ConfigFile.new()
	for action in overrides:
		cfg.set_value("bindings", action, overrides[action])
	cfg.save(SAVE_PATH)

func key_event(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event

func button_event(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event

func apply() -> void:
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		var definition: Dictionary = ACTIONS[action]
		var custom: Dictionary = overrides.get(action, {})
		if custom.is_empty():
			InputMap.action_add_event(action, key_event(int(definition.key)))
			for extra in definition.extra:
				InputMap.action_add_event(action, key_event(int(extra)))
			if int(definition.button) >= 0:
				InputMap.action_add_event(action, button_event(int(definition.button)))
		else:
			InputMap.action_add_event(action, key_event(int(custom.get("key", definition.key))))
			var button: int = int(custom.get("button", definition.button))
			if button >= 0:
				InputMap.action_add_event(action, button_event(button))

func start_capture(action: String) -> void:
	capturing = action

func rebind(action: String, event: InputEvent) -> void:
	if not ACTIONS.has(action) or event == null:
		return
	var custom: Dictionary = overrides.get(action, {})
	var definition: Dictionary = ACTIONS[action]
	if event is InputEventKey:
		custom["key"] = int(event.physical_keycode)
		if not custom.has("button"):
			custom["button"] = int(definition.button)
	elif event is InputEventJoypadButton:
		custom["button"] = int(event.button_index)
		if not custom.has("key"):
			custom["key"] = int(definition.key)
	else:
		return
	overrides[action] = custom
	save_overrides()
	apply()
	rebound.emit(action, label(action))

func reset_action(action: String) -> void:
	overrides.erase(action)
	save_overrides()
	apply()

func _unhandled_input(event: InputEvent) -> void:
	if capturing.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		rebind(capturing, event)
		capturing = ""
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		rebind(capturing, event)
		capturing = ""
		get_viewport().set_input_as_handled()

func key_of(action: String) -> int:
	var definition: Dictionary = ACTIONS.get(action, {})
	var custom: Dictionary = overrides.get(action, {})
	return int(custom.get("key", definition.get("key", 0)))

func button_of(action: String) -> int:
	var definition: Dictionary = ACTIONS.get(action, {})
	var custom: Dictionary = overrides.get(action, {})
	return int(custom.get("button", definition.get("button", -1)))

func matches(event: InputEvent, action: String) -> bool:
	# Discrete-event matching independent of InputMap keycode/physical quirks.
	if event is InputEventJoypadButton:
		var button: int = button_of(action)
		return button >= 0 and event.pressed and event.button_index == button
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = int(event.physical_keycode) if int(event.physical_keycode) != 0 else int(event.keycode)
		return code == key_of(action)
	return false

func key_label(code: int) -> String:
	if code <= 0:
		return "-"
	return OS.get_keycode_string(code)

func button_label(index: int) -> String:
	match index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_BACK: return "Back"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
	return "B%d" % index

func label(action: String) -> String:
	if not ACTIONS.has(action):
		return "?"
	var key: int = key_of(action)
	var button: int = button_of(action)
	var parts: PackedStringArray = []
	if key > 0:
		parts.append(key_label(key))
	if button >= 0:
		parts.append(button_label(button))
	return " or ".join(parts)

func gamepad_label(action: String) -> String:
	var definition: Dictionary = ACTIONS.get(action, {"button": -1})
	var custom: Dictionary = overrides.get(action, {})
	var button: int = int(custom.get("button", definition.button))
	return button_label(button) if button >= 0 else "?"
