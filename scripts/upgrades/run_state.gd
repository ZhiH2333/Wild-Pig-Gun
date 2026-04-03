extends Node

var character_id: String = "default"
var wave_index: int = 0
var gold: int = 0
var upgrade_ids: Array[String] = []
var run_seed: int = 0

func _ready() -> void:
	_register_default_input_actions()

func begin_new_run(p_character_id: String = "default") -> void:
	character_id = p_character_id
	wave_index = 0
	gold = 0
	upgrade_ids.clear()
	run_seed = randi()

func _register_default_input_actions() -> void:
	if InputMap.has_action("move_up"):
		return
	InputMap.add_action("move_up", 0.2)
	InputMap.add_action("move_down", 0.2)
	InputMap.add_action("move_left", 0.2)
	InputMap.add_action("move_right", 0.2)
	InputMap.add_action("pause_game", 0.2)
	InputMap.add_action("confirm", 0.2)
	_add_key_to_action("move_up", [KEY_W, KEY_UP])
	_add_key_to_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_to_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_to_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_to_action("pause_game", [KEY_ESCAPE])
	_add_key_to_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])

func _add_key_to_action(action_name: String, keycodes: Array) -> void:
	for keycode in keycodes:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = keycode as Key
		InputMap.action_add_event(action_name, ev)
