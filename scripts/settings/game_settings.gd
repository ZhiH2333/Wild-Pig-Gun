extends Node

signal music_linear_changed(new_value: float)
signal mobile_controls_changed(enabled: bool)
signal ui_scale_changed(new_value: float)
signal view_scale_changed(new_value: float)
signal show_fps_changed(enabled: bool)
signal joystick_size_changed(new_value: float)
const SETTINGS_PATH: String = "user://game_settings.json"
const MASTER_LINEAR_DEFAULT: float = 1.0
const MUSIC_LINEAR_DEFAULT: float = 1.0
const SFX_LINEAR_DEFAULT: float = 1.0
const FULLSCREEN_DEFAULT: bool = false
const VSYNC_ENABLED_DEFAULT: bool = true
const UI_SCALE_MIN: float = 0.75
const UI_SCALE_MAX: float = 1.45
const UI_SCALE_DEFAULT: float = 1.0
const VIEW_SCALE_MIN: float = 0.75
const VIEW_SCALE_MAX: float = 1.45
const VIEW_SCALE_DEFAULT: float = 1.0
const VSYNC_FPS_MIN: int = 30
const VSYNC_FPS_MAX: int = 240
const VSYNC_FPS_DEFAULT: int = 60
const JOYSTICK_SIZE_MIN: float = 0.5
const JOYSTICK_SIZE_MAX: float = 2.0
const JOYSTICK_SIZE_DEFAULT: float = 1.0

var master_linear: float = MASTER_LINEAR_DEFAULT
var music_linear: float = MUSIC_LINEAR_DEFAULT
var sfx_linear: float = SFX_LINEAR_DEFAULT
var fullscreen: bool = FULLSCREEN_DEFAULT
var vsync_enabled: bool = VSYNC_ENABLED_DEFAULT
var vsync_fps: int = VSYNC_FPS_DEFAULT
var ui_scale: float = UI_SCALE_DEFAULT
var view_scale: float = VIEW_SCALE_DEFAULT
var mobile_controls_enabled: bool = false
var show_fps: bool = false
var joystick_size: float = JOYSTICK_SIZE_DEFAULT
var has_selected_control_mode: bool = false


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
	master_linear = clampf(float(dict.get("master_linear", MASTER_LINEAR_DEFAULT)), 0.0, 1.0)
	music_linear = clampf(float(dict.get("music_linear", MUSIC_LINEAR_DEFAULT)), 0.0, 1.0)
	sfx_linear = clampf(float(dict.get("sfx_linear", SFX_LINEAR_DEFAULT)), 0.0, 1.0)
	fullscreen = bool(dict.get("fullscreen", FULLSCREEN_DEFAULT))
	vsync_enabled = bool(dict.get("vsync_enabled", VSYNC_ENABLED_DEFAULT))
	vsync_fps = clampi(int(dict.get("vsync_fps", VSYNC_FPS_DEFAULT)), VSYNC_FPS_MIN, VSYNC_FPS_MAX)
	ui_scale = clampf(float(dict.get("ui_scale", UI_SCALE_DEFAULT)), UI_SCALE_MIN, UI_SCALE_MAX)
	view_scale = clampf(float(dict.get("view_scale", VIEW_SCALE_DEFAULT)), VIEW_SCALE_MIN, VIEW_SCALE_MAX)
	mobile_controls_enabled = bool(dict.get("mobile_controls_enabled", false))
	show_fps = bool(dict.get("show_fps", false))
	joystick_size = clampf(float(dict.get("joystick_size", JOYSTICK_SIZE_DEFAULT)), JOYSTICK_SIZE_MIN, JOYSTICK_SIZE_MAX)
	has_selected_control_mode = bool(dict.get("has_selected_control_mode", false))


func save_to_disk() -> void:
	var dict: Dictionary = {
		"master_linear": master_linear,
		"music_linear": music_linear,
		"sfx_linear": sfx_linear,
		"fullscreen": fullscreen,
		"vsync_enabled": vsync_enabled,
		"vsync_fps": vsync_fps,
		"ui_scale": ui_scale,
		"view_scale": view_scale,
		"mobile_controls_enabled": mobile_controls_enabled,
		"show_fps": show_fps,
		"joystick_size": joystick_size,
		"has_selected_control_mode": has_selected_control_mode,
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
	music_linear_changed.emit(music_linear)


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


func set_vsync_fps(value: float) -> void:
	vsync_fps = clampi(int(round(value)), VSYNC_FPS_MIN, VSYNC_FPS_MAX)
	_apply_vsync()
	save_to_disk()


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, UI_SCALE_MIN, UI_SCALE_MAX)
	_apply_ui_scale()
	save_to_disk()
	ui_scale_changed.emit(ui_scale)


func set_view_scale(value: float) -> void:
	view_scale = clampf(value, VIEW_SCALE_MIN, VIEW_SCALE_MAX)
	save_to_disk()
	view_scale_changed.emit(view_scale)


func set_mobile_controls_enabled(enabled: bool) -> void:
	mobile_controls_enabled = enabled
	save_to_disk()
	mobile_controls_changed.emit(mobile_controls_enabled)


func set_show_fps(enabled: bool) -> void:
	show_fps = enabled
	save_to_disk()
	show_fps_changed.emit(show_fps)


func set_joystick_size(value: float) -> void:
	joystick_size = clampf(value, JOYSTICK_SIZE_MIN, JOYSTICK_SIZE_MAX)
	save_to_disk()
	joystick_size_changed.emit(joystick_size)


func set_has_selected_control_mode(value: bool) -> void:
	has_selected_control_mode = value
	save_to_disk()


func has_settings_file() -> bool:
	return FileAccess.file_exists(SETTINGS_PATH)


func clear_all_settings_data() -> bool:
	master_linear = MASTER_LINEAR_DEFAULT
	music_linear = MUSIC_LINEAR_DEFAULT
	sfx_linear = SFX_LINEAR_DEFAULT
	fullscreen = FULLSCREEN_DEFAULT
	vsync_enabled = VSYNC_ENABLED_DEFAULT
	vsync_fps = VSYNC_FPS_DEFAULT
	ui_scale = UI_SCALE_DEFAULT
	view_scale = VIEW_SCALE_DEFAULT
	mobile_controls_enabled = false
	show_fps = false
	joystick_size = JOYSTICK_SIZE_DEFAULT
	has_selected_control_mode = false
	_apply_all()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return true
	var abs_path: String = ProjectSettings.globalize_path(SETTINGS_PATH)
	var err: Error = DirAccess.remove_absolute(abs_path)
	if err == OK:
		return true
	save_to_disk()
	return false


func _apply_all() -> void:
	_apply_audio_buses()
	_apply_window()
	_apply_vsync()
	_apply_ui_scale()
	ui_scale_changed.emit(ui_scale)
	view_scale_changed.emit(view_scale)
	show_fps_changed.emit(show_fps)


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
	if OS.get_name() != "Web":
		if vsync_enabled:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if vsync_enabled:
		Engine.max_fps = vsync_fps
	else:
		Engine.max_fps = 0


func _apply_ui_scale() -> void:
	var win: Window = get_tree().root as Window
	if win == null:
		return
	win.content_scale_factor = ui_scale
