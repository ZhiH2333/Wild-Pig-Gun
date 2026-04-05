extends Node

const SETTINGS_PATH: String = "user://game_settings.json"
const UI_SCALE_MIN: float = 0.75
const UI_SCALE_MAX: float = 1.45
const UI_SCALE_DEFAULT: float = 1.0

var master_linear: float = 1.0
var music_linear: float = 1.0
var sfx_linear: float = 1.0
var fullscreen: bool = false
var vsync_enabled: bool = true
var ui_scale: float = UI_SCALE_DEFAULT


func _ready() -> void:
	load_from_disk()
	_apply_all()


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
	if not d is Dictionary:
		return
	var dict: Dictionary = d as Dictionary
	master_linear = clampf(float(dict.get("master_linear", 1.0)), 0.0, 1.0)
	music_linear = clampf(float(dict.get("music_linear", 1.0)), 0.0, 1.0)
	sfx_linear = clampf(float(dict.get("sfx_linear", 1.0)), 0.0, 1.0)
	fullscreen = bool(dict.get("fullscreen", false))
	vsync_enabled = bool(dict.get("vsync_enabled", true))
	ui_scale = clampf(float(dict.get("ui_scale", UI_SCALE_DEFAULT)), UI_SCALE_MIN, UI_SCALE_MAX)


func save_to_disk() -> void:
	var dict: Dictionary = {
		"master_linear": master_linear,
		"music_linear": music_linear,
		"sfx_linear": sfx_linear,
		"fullscreen": fullscreen,
		"vsync_enabled": vsync_enabled,
		"ui_scale": ui_scale,
	}
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(dict))


func set_master_linear(value: float) -> void:
	master_linear = clampf(value, 0.0, 1.0)
	_apply_audio_buses()
	save_to_disk()


func set_music_linear(value: float) -> void:
	music_linear = clampf(value, 0.0, 1.0)
	_apply_audio_buses()
	save_to_disk()


func set_sfx_linear(value: float) -> void:
	sfx_linear = clampf(value, 0.0, 1.0)
	_apply_audio_buses()
	save_to_disk()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_window()
	save_to_disk()


func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	_apply_vsync()
	save_to_disk()


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, UI_SCALE_MIN, UI_SCALE_MAX)
	_apply_ui_scale()
	save_to_disk()


func _apply_all() -> void:
	_apply_audio_buses()
	_apply_window()
	_apply_vsync()
	_apply_ui_scale()


func _apply_audio_buses() -> void:
	var idx_master: int = AudioServer.get_bus_index("Master")
	if idx_master >= 0:
		AudioServer.set_bus_volume_linear(idx_master, master_linear)
	var idx_music: int = AudioServer.get_bus_index("Music")
	if idx_music >= 0:
		AudioServer.set_bus_volume_linear(idx_music, music_linear)
	var idx_sfx: int = AudioServer.get_bus_index("SFX")
	if idx_sfx >= 0:
		AudioServer.set_bus_volume_linear(idx_sfx, 1.0)


func _apply_window() -> void:
	if OS.get_name() == "Web":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_vsync() -> void:
	if OS.get_name() == "Web":
		return
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _apply_ui_scale() -> void:
	var win: Window = get_tree().root as Window
	if win == null:
		return
	win.content_scale_factor = ui_scale
