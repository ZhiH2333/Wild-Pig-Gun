extends Node

const SETTINGS_PATH: String = "user://game_settings.json"

var master_linear: float = 1.0
var fullscreen: bool = false


func _ready() -> void:
	load_from_disk()
	_apply_audio()
	_apply_window()


func load_from_disk() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var json: JSON = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return
	var d: Variant = json.data
	if d is Dictionary:
		var dict: Dictionary = d as Dictionary
		master_linear = clampf(float(dict.get("master_linear", 1.0)), 0.0, 1.0)
		fullscreen = bool(dict.get("fullscreen", false))


func save_to_disk() -> void:
	var dict: Dictionary = {
		"master_linear": master_linear,
		"fullscreen": fullscreen,
	}
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(dict))


func set_master_linear(value: float) -> void:
	master_linear = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_to_disk()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_window()
	save_to_disk()


func _apply_audio() -> void:
	var idx: int = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_linear(idx, master_linear)


func _apply_window() -> void:
	if OS.get_name() == "Web":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
