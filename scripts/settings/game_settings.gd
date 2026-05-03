extends Node

enum InputMode {
	TOUCH,
	KEYBOARD_MOUSE,
}

signal music_linear_changed(new_value: float)
signal mobile_controls_changed(enabled: bool)
signal ui_scale_changed(new_value: float)
signal view_scale_changed(new_value: float)
signal show_fps_changed(enabled: bool)
signal joystick_size_changed(new_value: float)
signal quality_preset_changed(preset_id: String)
signal mobile_control_layout_changed
signal audio_float_enabled_changed(enabled: bool)

const SETTINGS_PATH: String = "user://game_settings.json"
const MASTER_LINEAR_DEFAULT: float = 1.0
const MUSIC_LINEAR_DEFAULT: float = 1.0
const SFX_LINEAR_DEFAULT: float = 1.0
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

## 虚拟摇杆默认布局（底边锚定坐标系）
## norm_left：左边距 / 视口宽；norm_bottom_margin：底边距 / 视口高
const LAYOUT_VJ_DEFAULT: Dictionary = {
	"norm_left": 0.0104, "norm_bottom_margin": 0.0185, "scale": 1.0
}
## 暂停按钮默认布局（底边锚定坐标系）
## norm_center_x：水平中心 / 视口宽；norm_bottom_margin：底边距 / 视口高
const LAYOUT_PAUSE_DEFAULT: Dictionary = {
	"norm_center_x": 0.9, "norm_bottom_margin": 0.026, "scale": 1.0
}
## 消耗品 1–6 条：底边水平中心（与摇杆/暂停同套归一化坐标）
const LAYOUT_CONSUMABLE_BAR_DEFAULT: Dictionary = {
	"norm_center_x": 0.5, "norm_bottom_margin": 0.022, "scale": 1.0
}
## 角色技能 1–3：正方形按钮吸附屏幕右缘（norm_right_margin：距右缘 / 视口宽；norm_bottom_margin：距底缘 / 视口高）
const LAYOUT_CHARACTER_SKILL_SLOT_1_DEFAULT: Dictionary = {
	"norm_right_margin": 0.015, "norm_bottom_margin": 0.20, "scale": 1.0
}
const LAYOUT_CHARACTER_SKILL_SLOT_2_DEFAULT: Dictionary = {
	"norm_right_margin": 0.015, "norm_bottom_margin": 0.33, "scale": 1.0
}
const LAYOUT_CHARACTER_SKILL_SLOT_3_DEFAULT: Dictionary = {
	"norm_right_margin": 0.015, "norm_bottom_margin": 0.46, "scale": 1.0
}

const WINDOW_MODE_WINDOWED: String = "windowed"
const WINDOW_MODE_BORDERLESS: String = "borderless"
const WINDOW_MODE_EXCLUSIVE: String = "exclusive"
const RESOLUTION_WIDTH_DEFAULT: int = 1280
const RESOLUTION_HEIGHT_DEFAULT: int = 720
const RESOLUTION_MIN: int = 640
const RESOLUTION_MAX: int = 7680
const FPS_LIMIT_DEFAULT: int = 0
const QUALITY_LOW: String = "low"
const QUALITY_MEDIUM: String = "medium"
const QUALITY_HIGH: String = "high"
const QUALITY_DEFAULT: String = QUALITY_MEDIUM
## 检查更新：仅对比正式 Release，或包含预发布（与 GitHub Releases 列表一致）
const UPDATE_CHANNEL_STABLE: String = "stable"
const UPDATE_CHANNEL_PRERELEASE: String = "prerelease"
const UPDATE_CHANNEL_DEFAULT: String = UPDATE_CHANNEL_STABLE
const AUDIO_FLOAT_ENABLED_DEFAULT: bool = false

var master_linear: float = MASTER_LINEAR_DEFAULT
var music_linear: float = MUSIC_LINEAR_DEFAULT
var sfx_linear: float = SFX_LINEAR_DEFAULT
var vsync_enabled: bool = VSYNC_ENABLED_DEFAULT
var vsync_fps: int = VSYNC_FPS_DEFAULT
var ui_scale: float = UI_SCALE_DEFAULT
var view_scale: float = VIEW_SCALE_DEFAULT
var mobile_controls_enabled: bool = false
var input_mode: InputMode = InputMode.KEYBOARD_MOUSE
var show_fps: bool = false
var joystick_size: float = JOYSTICK_SIZE_DEFAULT
var mobile_control_layout: Dictionary = _make_default_layout()
var has_selected_control_mode: bool = false
var selected_character_id: String = "default"
var window_mode: String = WINDOW_MODE_WINDOWED
var resolution_width: int = RESOLUTION_WIDTH_DEFAULT
var resolution_height: int = RESOLUTION_HEIGHT_DEFAULT
var fps_limit: int = FPS_LIMIT_DEFAULT
var quality_preset: String = QUALITY_DEFAULT
var update_channel: String = UPDATE_CHANNEL_DEFAULT
## 显示右下角音乐控制浮窗（MusicNowPlaying）
var audio_float_enabled: bool = AUDIO_FLOAT_ENABLED_DEFAULT


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
	vsync_enabled = bool(dict.get("vsync_enabled", VSYNC_ENABLED_DEFAULT))
	vsync_fps = clampi(int(dict.get("vsync_fps", VSYNC_FPS_DEFAULT)), VSYNC_FPS_MIN, VSYNC_FPS_MAX)
	ui_scale = clampf(float(dict.get("ui_scale", UI_SCALE_DEFAULT)), UI_SCALE_MIN, UI_SCALE_MAX)
	view_scale = clampf(
		float(dict.get("view_scale", VIEW_SCALE_DEFAULT)), VIEW_SCALE_MIN, VIEW_SCALE_MAX)
	if dict.has("input_mode"):
		input_mode = int(dict.get("input_mode", 0)) as InputMode
	else:
		var legacy_mobile: bool = bool(dict.get("mobile_controls_enabled", false))
		input_mode = InputMode.TOUCH if legacy_mobile else InputMode.KEYBOARD_MOUSE
	mobile_controls_enabled = input_mode == InputMode.TOUCH
	show_fps = bool(dict.get("show_fps", false))
	joystick_size = clampf(
		float(dict.get("joystick_size", JOYSTICK_SIZE_DEFAULT)), JOYSTICK_SIZE_MIN, JOYSTICK_SIZE_MAX)
	has_selected_control_mode = bool(dict.get("has_selected_control_mode", false))
	selected_character_id = str(dict.get("selected_character_id", "default"))
	if selected_character_id.is_empty():
		selected_character_id = "default"
	mobile_control_layout = _load_layout_dict(
		dict.get("mobile_control_layout", null), joystick_size)
	if dict.has("window_mode"):
		window_mode = _normalize_window_mode(
			str(dict.get("window_mode", WINDOW_MODE_WINDOWED)))
	else:
		var legacy_fullscreen: bool = bool(dict.get("fullscreen", false))
		window_mode = WINDOW_MODE_BORDERLESS if legacy_fullscreen else WINDOW_MODE_WINDOWED
	resolution_width = clampi(
		int(dict.get("resolution_width", RESOLUTION_WIDTH_DEFAULT)), RESOLUTION_MIN, RESOLUTION_MAX)
	resolution_height = clampi(
		int(dict.get("resolution_height", RESOLUTION_HEIGHT_DEFAULT)), RESOLUTION_MIN, RESOLUTION_MAX)
	fps_limit = clampi(int(dict.get("fps_limit", FPS_LIMIT_DEFAULT)), 0, VSYNC_FPS_MAX)
	quality_preset = _normalize_quality_preset(str(dict.get("quality_preset", QUALITY_DEFAULT)))
	update_channel = _normalize_update_channel(str(dict.get("update_channel", UPDATE_CHANNEL_DEFAULT)))
	audio_float_enabled = bool(dict.get("audio_float_enabled", AUDIO_FLOAT_ENABLED_DEFAULT))


func save_to_disk() -> void:
	var dict: Dictionary = {
		"master_linear": master_linear,
		"music_linear": music_linear,
		"sfx_linear": sfx_linear,
		"vsync_enabled": vsync_enabled,
		"vsync_fps": vsync_fps,
		"ui_scale": ui_scale,
		"view_scale": view_scale,
		"mobile_controls_enabled": mobile_controls_enabled,
		"input_mode": input_mode as int,
		"show_fps": show_fps,
		"joystick_size": joystick_size,
		"has_selected_control_mode": has_selected_control_mode,
		"selected_character_id": selected_character_id,
		"mobile_control_layout": mobile_control_layout,
		"window_mode": window_mode,
		"resolution_width": resolution_width,
		"resolution_height": resolution_height,
		"fps_limit": fps_limit,
		"quality_preset": quality_preset,
		"update_channel": update_channel,
		"audio_float_enabled": audio_float_enabled,
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


func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	_apply_vsync()
	_apply_max_fps()
	save_to_disk()


func set_vsync_fps(value: float) -> void:
	vsync_fps = clampi(int(round(value)), VSYNC_FPS_MIN, VSYNC_FPS_MAX)
	_apply_max_fps()
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
	input_mode = InputMode.TOUCH if enabled else InputMode.KEYBOARD_MOUSE
	save_to_disk()
	mobile_controls_changed.emit(mobile_controls_enabled)


func set_input_mode(mode: InputMode) -> void:
	input_mode = mode
	mobile_controls_enabled = mode == InputMode.TOUCH
	save_to_disk()
	mobile_controls_changed.emit(mobile_controls_enabled)


func set_show_fps(enabled: bool) -> void:
	show_fps = enabled
	save_to_disk()
	show_fps_changed.emit(show_fps)


func set_audio_float_enabled(enabled: bool) -> void:
	audio_float_enabled = enabled
	save_to_disk()
	audio_float_enabled_changed.emit(audio_float_enabled)


## 只更新摇杆 scale，不影响 layout 中保存的位置坐标
func set_joystick_size(value: float) -> void:
	joystick_size = clampf(value, JOYSTICK_SIZE_MIN, JOYSTICK_SIZE_MAX)
	var vj_entry: Dictionary = get_mobile_control_entry("virtual_joystick")
	vj_entry["scale"] = joystick_size
	mobile_control_layout["virtual_joystick"] = vj_entry
	save_to_disk()
	joystick_size_changed.emit(joystick_size)
	mobile_control_layout_changed.emit()


func set_has_selected_control_mode(value: bool) -> void:
	has_selected_control_mode = value
	save_to_disk()


func set_selected_character_id(character_id: String) -> void:
	selected_character_id = character_id
	if selected_character_id.is_empty():
		selected_character_id = "default"
	save_to_disk()


func set_window_mode(mode_id: String) -> void:
	window_mode = _normalize_window_mode(mode_id)
	_apply_window_and_resolution()
	save_to_disk()


func set_resolution(width: int, height: int) -> void:
	resolution_width = clampi(width, RESOLUTION_MIN, RESOLUTION_MAX)
	resolution_height = clampi(height, RESOLUTION_MIN, RESOLUTION_MAX)
	_apply_window_and_resolution()
	save_to_disk()


func set_fps_limit(limit_fps: int) -> void:
	fps_limit = clampi(limit_fps, 0, VSYNC_FPS_MAX)
	_apply_max_fps()
	save_to_disk()


func set_quality_preset(preset_id: String) -> void:
	quality_preset = _normalize_quality_preset(preset_id)
	_apply_quality_preset()
	save_to_disk()
	quality_preset_changed.emit(quality_preset)


func set_update_channel(channel_id: String) -> void:
	update_channel = _normalize_update_channel(channel_id)
	save_to_disk()


func has_settings_file() -> bool:
	return FileAccess.file_exists(SETTINGS_PATH)


func clear_all_settings_data() -> bool:
	master_linear = MASTER_LINEAR_DEFAULT
	music_linear = MUSIC_LINEAR_DEFAULT
	sfx_linear = SFX_LINEAR_DEFAULT
	vsync_enabled = VSYNC_ENABLED_DEFAULT
	vsync_fps = VSYNC_FPS_DEFAULT
	ui_scale = UI_SCALE_DEFAULT
	view_scale = VIEW_SCALE_DEFAULT
	mobile_controls_enabled = false
	input_mode = InputMode.KEYBOARD_MOUSE
	show_fps = false
	joystick_size = JOYSTICK_SIZE_DEFAULT
	has_selected_control_mode = false
	selected_character_id = "default"
	mobile_control_layout = _make_default_layout()
	window_mode = WINDOW_MODE_WINDOWED
	resolution_width = RESOLUTION_WIDTH_DEFAULT
	resolution_height = RESOLUTION_HEIGHT_DEFAULT
	fps_limit = FPS_LIMIT_DEFAULT
	quality_preset = QUALITY_DEFAULT
	update_channel = UPDATE_CHANNEL_DEFAULT
	audio_float_enabled = AUDIO_FLOAT_ENABLED_DEFAULT
	_apply_all()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return true
	var abs_path: String = ProjectSettings.globalize_path(SETTINGS_PATH)
	var err: Error = DirAccess.remove_absolute(abs_path)
	if err == OK:
		return true
	save_to_disk()
	return false


func _normalize_window_mode(mode_id: String) -> String:
	if mode_id == WINDOW_MODE_BORDERLESS or mode_id == WINDOW_MODE_EXCLUSIVE:
		return mode_id
	return WINDOW_MODE_WINDOWED


func _normalize_quality_preset(preset_id: String) -> String:
	if preset_id == QUALITY_LOW or preset_id == QUALITY_HIGH:
		return preset_id
	return QUALITY_MEDIUM


func _normalize_update_channel(channel_id: String) -> String:
	if channel_id == UPDATE_CHANNEL_PRERELEASE:
		return UPDATE_CHANNEL_PRERELEASE
	return UPDATE_CHANNEL_STABLE


func _apply_all() -> void:
	_apply_audio_buses()
	_apply_window_and_resolution()
	_apply_vsync()
	_apply_max_fps()
	_apply_ui_scale()
	_apply_quality_preset()
	ui_scale_changed.emit(ui_scale)
	view_scale_changed.emit(view_scale)
	show_fps_changed.emit(show_fps)
	audio_float_enabled_changed.emit(audio_float_enabled)


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


func _apply_window_and_resolution() -> void:
	if OS.get_name() == "Web":
		return
	# Android：导出已开 immersive_mode；此处强制全屏，避免沿用桌面存档的窗口模式导致状态栏/导航条无法按预期隐藏
	if OS.get_name() == "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	match window_mode:
		WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var w: int = clampi(resolution_width, RESOLUTION_MIN, RESOLUTION_MAX)
			var h: int = clampi(resolution_height, RESOLUTION_MIN, RESOLUTION_MAX)
			DisplayServer.window_set_size(Vector2i(w, h))
			_center_window_on_current_screen()
		WINDOW_MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WINDOW_MODE_EXCLUSIVE:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			var ew: int = clampi(resolution_width, RESOLUTION_MIN, RESOLUTION_MAX)
			var eh: int = clampi(resolution_height, RESOLUTION_MIN, RESOLUTION_MAX)
			DisplayServer.window_set_size(Vector2i(ew, eh))
		_:
			window_mode = WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(resolution_width, resolution_height))
			_center_window_on_current_screen()


func _center_window_on_current_screen() -> void:
	var screen_idx: int = DisplayServer.window_get_current_screen()
	var screen_pos: Vector2i = DisplayServer.screen_get_position(screen_idx)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_idx)
	var win_size: Vector2i = DisplayServer.window_get_size()
	var pos: Vector2i = screen_pos + (screen_size - win_size) / 2
	DisplayServer.window_set_position(pos)


func _apply_vsync() -> void:
	if OS.get_name() != "Web":
		if vsync_enabled:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _apply_max_fps() -> void:
	if OS.get_name() == "Web":
		return
	if vsync_enabled:
		Engine.max_fps = vsync_fps
		return
	if fps_limit <= 0:
		Engine.max_fps = 0
		return
	Engine.max_fps = fps_limit


func _apply_ui_scale() -> void:
	var win: Window = get_tree().root as Window
	if win == null:
		return
	win.content_scale_factor = ui_scale


func _apply_quality_preset() -> void:
	var win: Window = get_tree().root as Window
	if win == null:
		return
	match quality_preset:
		QUALITY_LOW:
			win.msaa_2d = Viewport.MSAA_DISABLED
		QUALITY_HIGH:
			win.msaa_2d = Viewport.MSAA_4X
		_:
			win.msaa_2d = Viewport.MSAA_2X


## 返回指定控件的布局条目副本
func get_mobile_control_entry(id: String) -> Dictionary:
	if mobile_control_layout.has(id):
		return (mobile_control_layout[id] as Dictionary).duplicate()
	if id == "virtual_joystick":
		return LAYOUT_VJ_DEFAULT.duplicate()
	if id == "mobile_pause":
		return LAYOUT_PAUSE_DEFAULT.duplicate()
	if id == "consumable_skill_bar":
		return LAYOUT_CONSUMABLE_BAR_DEFAULT.duplicate()
	if id == "character_skill_slot_1":
		return LAYOUT_CHARACTER_SKILL_SLOT_1_DEFAULT.duplicate()
	if id == "character_skill_slot_2":
		return LAYOUT_CHARACTER_SKILL_SLOT_2_DEFAULT.duplicate()
	if id == "character_skill_slot_3":
		return LAYOUT_CHARACTER_SKILL_SLOT_3_DEFAULT.duplicate()
	return {}


## 写入指定控件布局条目并持久化
func set_mobile_control_entry(id: String, entry: Dictionary) -> void:
	mobile_control_layout[id] = entry.duplicate()
	if id == "virtual_joystick" and entry.has("scale"):
		joystick_size = clampf(float(entry["scale"]), JOYSTICK_SIZE_MIN, JOYSTICK_SIZE_MAX)
	save_to_disk()
	if id == "virtual_joystick":
		joystick_size_changed.emit(joystick_size)
	mobile_control_layout_changed.emit()


func reset_mobile_control_layout() -> void:
	mobile_control_layout = _make_default_layout()
	joystick_size = JOYSTICK_SIZE_DEFAULT
	save_to_disk()
	joystick_size_changed.emit(joystick_size)
	mobile_control_layout_changed.emit()


static func _make_default_layout() -> Dictionary:
	return {
		"virtual_joystick": {"norm_left": 0.0104, "norm_bottom_margin": 0.0185, "scale": 1.0},
		"mobile_pause": {"norm_center_x": 0.9, "norm_bottom_margin": 0.026, "scale": 1.0},
		"consumable_skill_bar": {"norm_center_x": 0.5, "norm_bottom_margin": 0.022, "scale": 1.0},
		"character_skill_slot_1": LAYOUT_CHARACTER_SKILL_SLOT_1_DEFAULT.duplicate(),
		"character_skill_slot_2": LAYOUT_CHARACTER_SKILL_SLOT_2_DEFAULT.duplicate(),
		"character_skill_slot_3": LAYOUT_CHARACTER_SKILL_SLOT_3_DEFAULT.duplicate(),
	}


## 从磁盘数据构建布局字典，自动识别新旧格式
static func _load_layout_dict(raw: Variant, fallback_joystick_scale: float) -> Dictionary:
	var result: Dictionary = _make_default_layout()
	if not raw is Dictionary:
		result["virtual_joystick"]["scale"] = fallback_joystick_scale
		return result
	var d: Dictionary = raw as Dictionary
	var vj: Dictionary = result["virtual_joystick"]
	var pb: Dictionary = result["mobile_pause"]
	var csb: Dictionary = result["consumable_skill_bar"]
	if d.has("virtual_joystick") and d["virtual_joystick"] is Dictionary:
		var src: Dictionary = d["virtual_joystick"] as Dictionary
		if src.has("scale"):
			vj["scale"] = clampf(float(src["scale"]), 0.5, 2.0)
		if src.has("norm_left") and src.has("norm_bottom_margin"):
			vj["norm_left"] = clampf(float(src["norm_left"]), 0.0, 1.0)
			vj["norm_bottom_margin"] = clampf(float(src["norm_bottom_margin"]), 0.0, 0.5)
		elif src.has("norm_x") and src.has("norm_y"):
			var old_x: float = clampf(float(src["norm_x"]), 0.0, 1.0)
			var old_y: float = clampf(float(src["norm_y"]), 0.0, 1.0)
			var vj_size_ratio: float = (88.0 * 2.0 * float(vj["scale"])) / 1080.0
			vj["norm_left"] = clampf(old_x - vj_size_ratio * 0.5, 0.0, 1.0)
			vj["norm_bottom_margin"] = clampf(1.0 - old_y - vj_size_ratio * 0.5, 0.0, 0.5)
	else:
		vj["scale"] = fallback_joystick_scale
	if d.has("mobile_pause") and d["mobile_pause"] is Dictionary:
		var src: Dictionary = d["mobile_pause"] as Dictionary
		if src.has("scale"):
			pb["scale"] = clampf(float(src["scale"]), 0.5, 2.0)
		if src.has("norm_center_x") and src.has("norm_bottom_margin"):
			pb["norm_center_x"] = clampf(float(src["norm_center_x"]), 0.0, 1.0)
			pb["norm_bottom_margin"] = clampf(float(src["norm_bottom_margin"]), 0.0, 0.5)
		elif src.has("norm_x") and src.has("norm_y"):
			var old_x: float = clampf(float(src["norm_x"]), 0.0, 1.0)
			var old_y: float = clampf(float(src["norm_y"]), 0.0, 1.0)
			var pause_h_ratio: float = (84.0 * float(pb["scale"])) / 1080.0
			pb["norm_center_x"] = old_x
			pb["norm_bottom_margin"] = clampf(1.0 - old_y - pause_h_ratio * 0.5, 0.0, 0.5)
	if d.has("consumable_skill_bar") and d["consumable_skill_bar"] is Dictionary:
		var src_c: Dictionary = d["consumable_skill_bar"] as Dictionary
		if src_c.has("scale"):
			csb["scale"] = clampf(float(src_c["scale"]), 0.5, 2.0)
		if src_c.has("norm_center_x") and src_c.has("norm_bottom_margin"):
			csb["norm_center_x"] = clampf(float(src_c["norm_center_x"]), 0.0, 1.0)
			csb["norm_bottom_margin"] = clampf(float(src_c["norm_bottom_margin"]), 0.0, 0.5)
		elif src_c.has("norm_x") and src_c.has("norm_y"):
			var old_cx: float = clampf(float(src_c["norm_x"]), 0.0, 1.0)
			var old_cy: float = clampf(float(src_c["norm_y"]), 0.0, 1.0)
			var bar_h_ratio: float = (56.0 * float(csb["scale"])) / 1080.0
			csb["norm_center_x"] = old_cx
			csb["norm_bottom_margin"] = clampf(1.0 - old_cy - bar_h_ratio * 0.5, 0.0, 0.5)
	var slot_keys: PackedStringArray = PackedStringArray([
		"character_skill_slot_1",
		"character_skill_slot_2",
		"character_skill_slot_3",
	])
	for sk in slot_keys:
		var slot_def: Dictionary = result[sk] as Dictionary
		if d.has(sk) and d[sk] is Dictionary:
			var src_s: Dictionary = d[sk] as Dictionary
			if src_s.has("scale"):
				slot_def["scale"] = clampf(float(src_s["scale"]), 0.5, 2.0)
			if src_s.has("norm_right_margin") and src_s.has("norm_bottom_margin"):
				slot_def["norm_right_margin"] = clampf(float(src_s["norm_right_margin"]), 0.0, 0.5)
				slot_def["norm_bottom_margin"] = clampf(float(src_s["norm_bottom_margin"]), 0.0, 0.5)
			elif src_s.has("norm_x") and src_s.has("norm_y"):
				var btn_dim_ratio: float = (72.0 * float(slot_def["scale"])) / 1080.0
				var old_sx: float = clampf(float(src_s["norm_x"]), 0.0, 1.0)
				var old_sy: float = clampf(float(src_s["norm_y"]), 0.0, 1.0)
				slot_def["norm_right_margin"] = clampf(
					1.0 - old_sx - btn_dim_ratio, 0.0, 0.5)
				slot_def["norm_bottom_margin"] = clampf(
					1.0 - old_sy - btn_dim_ratio, 0.0, 0.5)
	return result
