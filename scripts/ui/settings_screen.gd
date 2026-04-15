extends Control

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const CLEAR_HOLD_SECONDS: float = 3.0
const COMMON_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(3840, 2160),
	Vector2i(3440, 1440),
	Vector2i(2560, 1440),
	Vector2i(2560, 1080),
	Vector2i(1920, 1200),
	Vector2i(1920, 1080),
	Vector2i(1680, 1050),
	Vector2i(1600, 900),
	Vector2i(1440, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 800),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
]

@onready var tab_container: TabContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer
@onready var tab_btn_0: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn0
@onready var tab_btn_1: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn1
@onready var tab_btn_2: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn2
@onready var tab_btn_3: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn3
@onready var tab_btn_4: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn4
@onready var master_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/SfxRow/SfxSlider
@onready var resolution_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/ResolutionRow
@onready var resolution_option: OptionButton = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/ResolutionRow/ResolutionOption
@onready var window_mode_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/WindowModeRow
@onready var window_mode_option: OptionButton = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/WindowModeRow/WindowModeOption
@onready var fps_limit_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/FpsLimitRow
@onready var fps_limit_option: OptionButton = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/FpsLimitRow/FpsLimitOption
@onready var quality_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/QualityRow
@onready var quality_option: OptionButton = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/QualityRow/QualityOption
@onready var ui_scale_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/UiScaleRow/UiScaleSlider
@onready var ui_scale_value: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/UiScaleRow/UiScaleValue
@onready var view_scale_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/ViewScaleRow/ViewScaleSlider
@onready var view_scale_value: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/ViewScaleRow/ViewScaleValue
@onready var vsync_check: CheckBox = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/VsyncCheck
@onready var vsync_fps_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/VsyncFpsRow
@onready var vsync_fps_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/VsyncFpsRow/VsyncFpsSlider
@onready var vsync_fps_value: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DisplayScroll/Contents/VsyncFpsRow/VsyncFpsValue
@onready var show_fps_check: CheckBox = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/GameScroll/Contents/ShowFpsCheck
@onready var mobile_controls_check: CheckBox = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/MobileControlsCheck
@onready var joystick_size_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow
@onready var joystick_size_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow/JoystickSizeSlider
@onready var joystick_size_value: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow/JoystickSizeValue
@onready var data_summary_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/DataSummaryLabel
@onready var clear_hint_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearHintLabel
@onready var clear_all_data_button: Button = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearAllDataButton
@onready var back_button: Button = $Center/MainColumn/BackButton
@onready var delete_confirm_overlay: Control = $DeleteConfirmOverlay
@onready var delete_confirm_button: Button = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/ConfirmButton
@onready var delete_cancel_button: Button = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/CancelButton
@onready var clear_result_overlay: Control = $ClearResultOverlay
@onready var clear_result_message_label: Label = $ClearResultOverlay/CenterContainer/DialogCard/Margin/Content/MessageLabel
@onready var clear_result_back_button: Button = $ClearResultOverlay/CenterContainer/DialogCard/Margin/Content/BackToMenuButton
@onready var clear_hold_timer: Timer = $ClearHoldTimer

var is_clear_confirmed: bool = false
var is_holding_clear_button: bool = false
var _is_syncing_ui: bool = false
var _tab_buttons: Array[Button] = []
var _style_active_normal: StyleBoxFlat
var _style_active_hover: StyleBoxFlat
var _style_inactive_normal: StyleBoxFlat
var _style_inactive_hover: StyleBoxFlat


func _ready() -> void:
	GameMusic.duck_for_subpage()
	_tab_buttons = [tab_btn_0, tab_btn_1, tab_btn_2, tab_btn_3, tab_btn_4]
	_build_tab_button_styles()
	for i: int in range(_tab_buttons.size()):
		_tab_buttons[i].pressed.connect(_switch_tab.bind(i))
	_switch_tab(0)
	_build_static_option_buttons()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	resolution_option.item_selected.connect(_on_resolution_item_selected)
	window_mode_option.item_selected.connect(_on_window_mode_item_selected)
	fps_limit_option.item_selected.connect(_on_fps_limit_item_selected)
	quality_option.item_selected.connect(_on_quality_item_selected)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	view_scale_slider.value_changed.connect(_on_view_scale_changed)
	vsync_check.toggled.connect(_on_vsync_toggled)
	vsync_fps_slider.value_changed.connect(_on_vsync_fps_changed)
	show_fps_check.toggled.connect(_on_show_fps_toggled)
	mobile_controls_check.toggled.connect(_on_mobile_controls_toggled)
	joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	clear_all_data_button.pressed.connect(_on_clear_all_button_pressed)
	clear_all_data_button.button_down.connect(_on_clear_all_button_down)
	clear_all_data_button.button_up.connect(_on_clear_all_button_up)
	delete_confirm_button.pressed.connect(_on_clear_dialog_confirmed)
	delete_cancel_button.pressed.connect(_on_clear_dialog_cancelled)
	clear_result_back_button.pressed.connect(_on_clear_result_back_pressed)
	clear_hold_timer.timeout.connect(_on_clear_hold_timer_timeout)
	back_button.pressed.connect(_on_back_pressed)
	_sync_all_controls_from_settings()
	_refresh_ui_scale_label()
	_refresh_view_scale_label()
	_refresh_vsync_fps_label()
	_refresh_vsync_fps_visibility()
	_refresh_fps_limit_visibility()
	_refresh_joystick_size_label()
	_refresh_joystick_size_visibility()
	_refresh_data_summary()
	_refresh_clear_button_idle_text()
	_apply_web_visibility()


func _build_tab_button_styles() -> void:
	_style_active_normal = StyleBoxFlat.new()
	_style_active_normal.bg_color = Color(0.96, 0.93, 0.86, 1)
	_style_active_normal.border_width_left = 1
	_style_active_normal.border_width_top = 1
	_style_active_normal.border_width_right = 1
	_style_active_normal.border_width_bottom = 1
	_style_active_normal.border_color = Color(0.72, 0.64, 0.42, 1)
	_style_active_normal.set_corner_radius_all(16)
	_style_active_normal.content_margin_left = 24.0
	_style_active_normal.content_margin_top = 14.0
	_style_active_normal.content_margin_right = 24.0
	_style_active_normal.content_margin_bottom = 14.0
	_style_active_normal.shadow_color = Color(0, 0, 0, 0.22)
	_style_active_normal.shadow_size = 4
	_style_active_normal.shadow_offset = Vector2(0, 2)
	_style_active_hover = _style_active_normal.duplicate() as StyleBoxFlat
	_style_active_hover.bg_color = Color(1.0, 0.97, 0.9, 1)
	_style_inactive_normal = StyleBoxFlat.new()
	_style_inactive_normal.bg_color = Color(0.14, 0.16, 0.22, 0.92)
	_style_inactive_normal.border_width_left = 1
	_style_inactive_normal.border_width_top = 1
	_style_inactive_normal.border_width_right = 1
	_style_inactive_normal.border_width_bottom = 1
	_style_inactive_normal.border_color = Color(0.35, 0.38, 0.48, 0.85)
	_style_inactive_normal.set_corner_radius_all(16)
	_style_inactive_normal.content_margin_left = 22.0
	_style_inactive_normal.content_margin_top = 14.0
	_style_inactive_normal.content_margin_right = 22.0
	_style_inactive_normal.content_margin_bottom = 14.0
	_style_inactive_hover = _style_inactive_normal.duplicate() as StyleBoxFlat
	_style_inactive_hover.bg_color = Color(0.22, 0.26, 0.34, 1)
	_style_inactive_hover.border_color = Color(0.5, 0.55, 0.68, 1)


func _switch_tab(index: int) -> void:
	tab_container.current_tab = index
	for i: int in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i == index:
			btn.add_theme_stylebox_override("normal", _style_active_normal)
			btn.add_theme_stylebox_override("hover", _style_active_hover)
			btn.add_theme_stylebox_override("pressed", _style_active_normal)
			btn.add_theme_stylebox_override("focus", _style_active_normal)
			btn.add_theme_color_override("font_color", Color(0.14, 0.12, 0.1, 1))
			btn.add_theme_color_override("font_hover_color", Color(0.14, 0.12, 0.1, 1))
		else:
			btn.add_theme_stylebox_override("normal", _style_inactive_normal)
			btn.add_theme_stylebox_override("hover", _style_inactive_hover)
			btn.add_theme_stylebox_override("pressed", _style_inactive_normal)
			btn.add_theme_stylebox_override("focus", _style_inactive_normal)
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")


func _build_static_option_buttons() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("窗口化")
	window_mode_option.set_item_metadata(0, GameSettings.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("无边框全屏")
	window_mode_option.set_item_metadata(1, GameSettings.WINDOW_MODE_BORDERLESS)
	window_mode_option.add_item("独占全屏")
	window_mode_option.set_item_metadata(2, GameSettings.WINDOW_MODE_EXCLUSIVE)
	fps_limit_option.clear()
	var fps_limits: PackedInt32Array = PackedInt32Array([0, 30, 60, 90, 120, 144, 240])
	for limit: int in fps_limits:
		if limit == 0:
			fps_limit_option.add_item("无限制")
		else:
			fps_limit_option.add_item("%d FPS" % limit)
		fps_limit_option.set_item_metadata(fps_limit_option.item_count - 1, limit)
	quality_option.clear()
	quality_option.add_item("低（关闭抗锯齿）")
	quality_option.set_item_metadata(0, GameSettings.QUALITY_LOW)
	quality_option.add_item("中（2× MSAA）")
	quality_option.set_item_metadata(1, GameSettings.QUALITY_MEDIUM)
	quality_option.add_item("高（4× MSAA）")
	quality_option.set_item_metadata(2, GameSettings.QUALITY_HIGH)
	_rebuild_resolution_options()


func _rebuild_resolution_options() -> void:
	var seen: Dictionary = {}
	var list: Array[Vector2i] = []
	var screen_idx: int = 0
	if OS.get_name() != "Web":
		screen_idx = DisplayServer.window_get_current_screen()
		var screen_size: Vector2i = DisplayServer.screen_get_size(screen_idx)
		if screen_size.x > 0 and screen_size.y > 0:
			list.append(screen_size)
			seen[Vector2i(screen_size.x, screen_size.y)] = true
		var win_size: Vector2i = DisplayServer.window_get_size()
		if win_size.x > 0 and win_size.y > 0 and not seen.has(win_size):
			list.append(win_size)
			seen[win_size] = true
	for preset: Vector2i in COMMON_RESOLUTIONS:
		var key: Vector2i = Vector2i(preset.x, preset.y)
		if seen.has(key):
			continue
		list.append(preset)
		seen[key] = true
	list.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x * a.y == b.x * b.y:
			return a.x > b.x
		return a.x * a.y > b.x * b.y
	)
	resolution_option.clear()
	for vec: Vector2i in list:
		resolution_option.add_item("%d × %d" % [vec.x, vec.y])
		resolution_option.set_item_metadata(resolution_option.item_count - 1, vec)


func _sync_all_controls_from_settings() -> void:
	_is_syncing_ui = true
	master_slider.value = GameSettings.master_linear
	music_slider.value = GameSettings.music_linear
	sfx_slider.value = GameSettings.sfx_linear
	ui_scale_slider.value = GameSettings.ui_scale
	view_scale_slider.value = GameSettings.view_scale
	vsync_check.button_pressed = GameSettings.vsync_enabled
	vsync_fps_slider.value = GameSettings.vsync_fps
	show_fps_check.button_pressed = GameSettings.show_fps
	mobile_controls_check.button_pressed = GameSettings.mobile_controls_enabled
	joystick_size_slider.value = GameSettings.joystick_size
	_select_resolution_option(GameSettings.resolution_width, GameSettings.resolution_height)
	_select_window_mode_option(GameSettings.window_mode)
	_select_fps_limit_option(GameSettings.fps_limit)
	_select_quality_option(GameSettings.quality_preset)
	_is_syncing_ui = false


func _select_resolution_option(width: int, height: int) -> void:
	var target: Vector2i = Vector2i(width, height)
	for i: int in range(resolution_option.item_count):
		var meta: Variant = resolution_option.get_item_metadata(i)
		if meta is Vector2i and meta == target:
			resolution_option.select(i)
			return
	resolution_option.add_item("%d × %d（当前）" % [target.x, target.y])
	resolution_option.set_item_metadata(resolution_option.item_count - 1, target)
	resolution_option.select(resolution_option.item_count - 1)


func _select_window_mode_option(mode_id: String) -> void:
	for i: int in range(window_mode_option.item_count):
		var meta: Variant = window_mode_option.get_item_metadata(i)
		if meta is String and str(meta) == mode_id:
			window_mode_option.select(i)
			return
	window_mode_option.select(0)


func _select_fps_limit_option(limit_fps: int) -> void:
	for i: int in range(fps_limit_option.item_count):
		var meta: Variant = fps_limit_option.get_item_metadata(i)
		if meta is int and int(meta) == limit_fps:
			fps_limit_option.select(i)
			return
	fps_limit_option.select(0)


func _select_quality_option(preset_id: String) -> void:
	for i: int in range(quality_option.item_count):
		var meta: Variant = quality_option.get_item_metadata(i)
		if meta is String and str(meta) == preset_id:
			quality_option.select(i)
			return
	quality_option.select(1)


func _apply_web_visibility() -> void:
	if OS.get_name() != "Web":
		return
	resolution_row.visible = false
	window_mode_row.visible = false
	fps_limit_row.visible = false
	quality_row.visible = false
	vsync_check.visible = false
	vsync_fps_row.visible = false


func _on_master_changed(v: float) -> void:
	GameSettings.set_master_linear(v)


func _on_music_changed(v: float) -> void:
	GameSettings.set_music_linear(v)


func _on_sfx_changed(v: float) -> void:
	GameSettings.set_sfx_linear(v)


func _on_resolution_item_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var meta: Variant = resolution_option.get_item_metadata(index)
	if meta is Vector2i:
		var v: Vector2i = meta as Vector2i
		GameSettings.set_resolution(v.x, v.y)


func _on_window_mode_item_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var meta: Variant = window_mode_option.get_item_metadata(index)
	if meta is String:
		GameSettings.set_window_mode(str(meta))


func _on_fps_limit_item_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var meta: Variant = fps_limit_option.get_item_metadata(index)
	if meta is int:
		GameSettings.set_fps_limit(int(meta))


func _on_quality_item_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var meta: Variant = quality_option.get_item_metadata(index)
	if meta is String:
		GameSettings.set_quality_preset(str(meta))


func _on_ui_scale_changed(v: float) -> void:
	GameSettings.set_ui_scale(v)
	_refresh_ui_scale_label()


func _on_view_scale_changed(v: float) -> void:
	GameSettings.set_view_scale(v)
	_refresh_view_scale_label()


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)
	_refresh_vsync_fps_visibility()
	_refresh_fps_limit_visibility()


func _on_vsync_fps_changed(v: float) -> void:
	GameSettings.set_vsync_fps(v)
	_refresh_vsync_fps_label()


func _on_show_fps_toggled(pressed: bool) -> void:
	GameSettings.set_show_fps(pressed)


func _on_mobile_controls_toggled(pressed: bool) -> void:
	GameSettings.set_mobile_controls_enabled(pressed)
	_refresh_joystick_size_visibility()


func _on_joystick_size_changed(v: float) -> void:
	GameSettings.set_joystick_size(v)
	_refresh_joystick_size_label()


func _refresh_ui_scale_label() -> void:
	ui_scale_value.text = "%d%%" % int(round(GameSettings.ui_scale * 100.0))


func _refresh_view_scale_label() -> void:
	view_scale_value.text = "%d%%" % int(round(GameSettings.view_scale * 100.0))


func _refresh_vsync_fps_label() -> void:
	vsync_fps_value.text = "%d FPS" % GameSettings.vsync_fps


func _refresh_vsync_fps_visibility() -> void:
	if OS.get_name() == "Web":
		return
	vsync_fps_row.visible = vsync_check.button_pressed


func _refresh_fps_limit_visibility() -> void:
	if OS.get_name() == "Web":
		return
	fps_limit_row.visible = not vsync_check.button_pressed
	fps_limit_option.disabled = vsync_check.button_pressed


func _refresh_joystick_size_label() -> void:
	joystick_size_value.text = "%d%%" % int(round(GameSettings.joystick_size * 100.0))


func _refresh_joystick_size_visibility() -> void:
	joystick_size_row.visible = GameSettings.mobile_controls_enabled


func _refresh_data_summary() -> void:
	var save_file_exists: bool = SaveManager.has_save_file()
	var settings_file_exists: bool = GameSettings.has_settings_file()
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best_wave: int = int(meta.get("best_wave", 0))
	var run_count: int = int(meta.get("runs", 0))
	var victory_count: int = int(meta.get("victories", 0))
	var has_pending_run: bool = SaveManager.has_pending_run()
	var pending_summary: Dictionary = SaveManager.get_pending_run_summary()
	var pending_wave: int = int(pending_summary.get("wave_index", 0))
	var pending_character_id: String = str(pending_summary.get("character_id", "无"))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("当前数据：")
	lines.append("1) 存档文件（wild_pig_gun_save.json）：%s" % ("存在" if save_file_exists else "无"))
	lines.append("2) 设置文件（game_settings.json）：%s" % ("存在" if settings_file_exists else "无"))
	lines.append("3) 元进度：最高波次 %d / 累计局数 %d / 通关次数 %d" % [best_wave, run_count, victory_count])
	if has_pending_run:
		lines.append("4) 续玩存档：有（角色 %s，第 %d 波）" % [pending_character_id, pending_wave])
	else:
		lines.append("4) 续玩存档：无")
	data_summary_label.text = "\n".join(lines)


func _refresh_clear_button_idle_text() -> void:
	if is_clear_confirmed:
		clear_all_data_button.text = "长按 3 秒清除所有数据"
		clear_hint_label.text = "已确认，请按住红色按钮直到清除完成"
		return
	clear_all_data_button.text = "清除所有数据"
	clear_hint_label.text = "先点击确认，再长按 3 秒清除全部数据"


func _on_clear_all_button_pressed() -> void:
	if is_clear_confirmed:
		return
	delete_confirm_overlay.visible = true


func _on_clear_dialog_confirmed() -> void:
	delete_confirm_overlay.visible = false
	is_clear_confirmed = true
	_refresh_clear_button_idle_text()


func _on_clear_dialog_cancelled() -> void:
	delete_confirm_overlay.visible = false


func _on_clear_all_button_down() -> void:
	if not is_clear_confirmed:
		return
	is_holding_clear_button = true
	clear_hold_timer.start(CLEAR_HOLD_SECONDS)


func _on_clear_all_button_up() -> void:
	if not is_holding_clear_button:
		return
	_cancel_clear_hold()


func _process(_delta: float) -> void:
	if not is_holding_clear_button:
		return
	if clear_hold_timer.is_stopped():
		return
	var held_seconds: float = CLEAR_HOLD_SECONDS - clear_hold_timer.time_left
	if held_seconds < 0.0:
		held_seconds = 0.0
	clear_all_data_button.text = "正在清除确认：%.1f / %.1f 秒" % [held_seconds, CLEAR_HOLD_SECONDS]


func _cancel_clear_hold() -> void:
	is_holding_clear_button = false
	if not clear_hold_timer.is_stopped():
		clear_hold_timer.stop()
	_refresh_clear_button_idle_text()


func _on_clear_hold_timer_timeout() -> void:
	is_holding_clear_button = false
	_execute_clear_all_data()


func _execute_clear_all_data() -> void:
	clear_all_data_button.disabled = true
	clear_all_data_button.text = "正在清除..."
	clear_hint_label.text = "请稍候，正在重置数据并返回主菜单"
	var is_save_cleared: bool = SaveManager.delete_all_save_data()
	var is_settings_cleared: bool = GameSettings.clear_all_settings_data()
	SaveManager.clear_pending_run()
	RunState.pause_reason = RunState.PauseReason.NONE
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().paused = false
	GameMusic.ensure_playing_main_volume()
	_refresh_data_summary()
	if is_save_cleared and is_settings_cleared:
		clear_result_message_label.text = "所有数据已清除完成。"
	else:
		clear_result_message_label.text = "部分数据清除失败。\n请检查本地文件写入权限后重试。"
	clear_result_overlay.visible = true


func _on_clear_result_back_pressed() -> void:
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_back_pressed() -> void:
	if bool(get_meta("in_game_overlay", false)):
		var arena: Node = get_tree().get_first_node_in_group("arena")
		if arena != null and arena.has_method("close_in_game_settings"):
			arena.close_in_game_settings()
		return
	var target_scene: String = RunState.settings_return_scene_path
	if target_scene.is_empty():
		target_scene = MAIN_MENU_SCENE_PATH
	if target_scene == MAIN_MENU_SCENE_PATH:
		GameMusic.ensure_playing_main_volume()
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().change_scene_to_file(target_scene)
