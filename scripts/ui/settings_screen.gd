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
@onready var tab_sep_01: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep01
@onready var tab_sep_12: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep12
@onready var tab_sep_23: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep23
@onready var tab_sep_34: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep34
@onready var master_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/SfxRow/SfxSlider
@onready var audio_float_check: CheckBox = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/AudioScroll/Contents/AudioFloatCheck
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
@onready var update_channel_option: OptionButton = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/GameScroll/Contents/UpdateChannelRow/UpdateChannelOption
@onready var mobile_controls_check: CheckBox = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/MobileControlsCheck
@onready var joystick_size_row: HBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow
@onready var joystick_size_slider: HSlider = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow/JoystickSizeSlider
@onready var joystick_size_value: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/JoystickSizeRow/JoystickSizeValue
@onready var custom_layout_btn: Button = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/ControlScroll/Contents/CustomLayoutBtn
@onready var data_summary_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/DataSummaryLabel
@onready var clear_hint_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearHintLabel
@onready var clear_all_data_button: Button = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearAllDataButton
@onready var clear_hold_progress: ProgressBar = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearAllDataButton/ClearHoldProgress
@onready var clear_hold_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/SettingsTabContainer/DataScroll/Contents/ClearAllDataButton/ClearHoldLabel
@onready var title_label: Label = $Center/MainColumn/HeaderMargins/HeaderRow/Title
@onready var back_button: Button = $Center/MainColumn/HeaderMargins/HeaderRow/BackButton
@onready var delete_confirm_overlay: Control = $DeleteConfirmOverlay
@onready var delete_confirm_button: Button = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/ConfirmButton
@onready var delete_cancel_button: Button = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/CancelButton
@onready var check_clear_saves: CheckBox = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/CheckClearSaves
@onready var check_clear_user_data: CheckBox = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/CheckClearUserData
@onready var delete_confirm_hint_label: Label = $DeleteConfirmOverlay/CenterContainer/DialogCard/Margin/Content/HoldHintLabel
@onready var clear_result_overlay: Control = $ClearResultOverlay
@onready var clear_result_message_label: Label = $ClearResultOverlay/CenterContainer/DialogCard/Margin/Content/MessageLabel
@onready var clear_result_back_button: Button = $ClearResultOverlay/CenterContainer/DialogCard/Margin/Content/BackToMenuButton
@onready var clear_hold_timer: Timer = $ClearHoldTimer

var is_clear_confirmed: bool = false
var is_holding_clear_button: bool = false
var _pending_clear_run_saves: bool = false
var _pending_clear_user_data: bool = false
var _is_syncing_ui: bool = false
var _is_tutorial_mode: bool = false
var _tab_buttons: Array[Button] = []
var _tab_separators: Array[ColorRect] = []
var _style_active_normal: StyleBoxFlat
var _style_active_hover: StyleBoxFlat
var _style_inactive_normal: StyleBoxFlat
var _style_inactive_hover: StyleBoxFlat


func _ready() -> void:
	if bool(get_meta("in_game_overlay", false)):
		GameMusic.mute_for_in_game_settings()
	else:
		GameMusic.duck_for_subpage()
	_tab_buttons = [tab_btn_0, tab_btn_1, tab_btn_2, tab_btn_3, tab_btn_4]
	_tab_separators = [tab_sep_01, tab_sep_12, tab_sep_23, tab_sep_34]
	_build_tab_button_styles()
	for i: int in range(_tab_buttons.size()):
		_tab_buttons[i].pressed.connect(_switch_tab.bind(i))
	_switch_tab(0)
	_build_static_option_buttons()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	audio_float_check.toggled.connect(_on_audio_float_toggled)
	resolution_option.item_selected.connect(_on_resolution_item_selected)
	window_mode_option.item_selected.connect(_on_window_mode_item_selected)
	fps_limit_option.item_selected.connect(_on_fps_limit_item_selected)
	quality_option.item_selected.connect(_on_quality_item_selected)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	view_scale_slider.value_changed.connect(_on_view_scale_changed)
	vsync_check.toggled.connect(_on_vsync_toggled)
	vsync_fps_slider.value_changed.connect(_on_vsync_fps_changed)
	show_fps_check.toggled.connect(_on_show_fps_toggled)
	update_channel_option.item_selected.connect(_on_update_channel_item_selected)
	mobile_controls_check.toggled.connect(_on_mobile_controls_toggled)
	joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	custom_layout_btn.pressed.connect(_on_custom_layout_pressed)
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
	clear_hold_timer.wait_time = CLEAR_HOLD_SECONDS
	_style_clear_hold_progress_bar()
	_sync_clear_hold_label_theme()
	_refresh_clear_button_idle_text()
	_apply_web_visibility()
	_apply_tutorial_mode()
	_refresh_tab_separator_visibility()


func _apply_tutorial_mode() -> void:
	if not TutorialSession.is_in_tutorial_settings:
		return
	_is_tutorial_mode = true
	title_label.text = "在此之前..."
	back_button.text = "下一步"
	tab_btn_2.visible = false
	tab_btn_4.visible = false


func _refresh_tab_separator_visibility() -> void:
	for i: int in range(_tab_separators.size()):
		var sep: ColorRect = _tab_separators[i]
		var left_tab: CanvasItem = _tab_buttons[i]
		var right_tab: CanvasItem = _tab_buttons[i + 1]
		sep.visible = left_tab.visible and right_tab.visible


func _build_tab_button_styles() -> void:
	const RADIUS := 2
	const MG_L := 16.0
	const MG_T := 8.0
	const MG_R := 16.0
	const MG_B := 8.0
	# Matches themes/settings_tab_theme.tres pressed (active tab), no border.
	_style_active_normal = StyleBoxFlat.new()
	_style_active_normal.bg_color = Color(1, 1, 1, 1)
	_style_active_normal.set_corner_radius_all(RADIUS)
	_style_active_normal.content_margin_left = MG_L
	_style_active_normal.content_margin_top = MG_T
	_style_active_normal.content_margin_right = MG_R
	_style_active_normal.content_margin_bottom = MG_B
	_style_active_hover = _style_active_normal.duplicate() as StyleBoxFlat
	# Matches settings_tab_theme normal + hover for inactive tabs, no border.
	_style_inactive_normal = StyleBoxFlat.new()
	_style_inactive_normal.bg_color = Color(0, 0, 0, 0.55)
	_style_inactive_normal.set_corner_radius_all(RADIUS)
	_style_inactive_normal.content_margin_left = MG_L
	_style_inactive_normal.content_margin_top = MG_T
	_style_inactive_normal.content_margin_right = MG_R
	_style_inactive_normal.content_margin_bottom = MG_B
	_style_inactive_hover = _style_inactive_normal.duplicate() as StyleBoxFlat
	_style_inactive_hover.bg_color = Color(1, 1, 1, 0.75)


func _switch_tab(index: int) -> void:
	tab_container.current_tab = index
	for i: int in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i == index:
			btn.add_theme_stylebox_override("normal", _style_active_normal)
			btn.add_theme_stylebox_override("hover", _style_active_hover)
			btn.add_theme_stylebox_override("pressed", _style_active_normal)
			btn.add_theme_stylebox_override("focus", _style_active_normal)
			btn.add_theme_color_override("font_color", Color.BLACK)
			btn.add_theme_color_override("font_hover_color", Color.BLACK)
			btn.add_theme_color_override("font_pressed_color", Color.BLACK)
			btn.add_theme_color_override("font_focus_color", Color.BLACK)
		else:
			btn.add_theme_stylebox_override("normal", _style_inactive_normal)
			btn.add_theme_stylebox_override("hover", _style_inactive_hover)
			btn.add_theme_stylebox_override("pressed", _style_inactive_normal)
			btn.add_theme_stylebox_override("focus", _style_inactive_normal)
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")
			btn.remove_theme_color_override("font_pressed_color")
			btn.remove_theme_color_override("font_focus_color")


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
	_build_update_channel_options()
	_rebuild_resolution_options()


func _build_update_channel_options() -> void:
	update_channel_option.clear()
	update_channel_option.add_item("正式版（仅 Release）")
	update_channel_option.set_item_metadata(0, GameSettings.UPDATE_CHANNEL_STABLE)
	update_channel_option.add_item("测试版（含预发布）")
	update_channel_option.set_item_metadata(1, GameSettings.UPDATE_CHANNEL_PRERELEASE)


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
	audio_float_check.button_pressed = GameSettings.audio_float_enabled
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
	_select_update_channel_option(GameSettings.update_channel)
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


func _select_update_channel_option(channel_id: String) -> void:
	for i: int in range(update_channel_option.item_count):
		var meta: Variant = update_channel_option.get_item_metadata(i)
		if meta is String and str(meta) == channel_id:
			update_channel_option.select(i)
			return
	update_channel_option.select(0)


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


func _on_audio_float_toggled(pressed: bool) -> void:
	if _is_syncing_ui:
		return
	GameSettings.set_audio_float_enabled(pressed)


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


func _on_update_channel_item_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var meta: Variant = update_channel_option.get_item_metadata(index)
	if meta is String:
		GameSettings.set_update_channel(str(meta))


func _on_mobile_controls_toggled(pressed: bool) -> void:
	GameSettings.set_mobile_controls_enabled(pressed)
	_refresh_joystick_size_visibility()


func _on_joystick_size_changed(v: float) -> void:
	if _is_syncing_ui:
		return
	GameSettings.set_joystick_size(v)
	_refresh_joystick_size_label()


func _on_custom_layout_pressed() -> void:
	if bool(get_meta("in_game_overlay", false)):
		var arena_node: Node = get_tree().get_first_node_in_group("arena")
		if arena_node != null and arena_node.has_method("open_in_game_mobile_layout_editor"):
			arena_node.open_in_game_mobile_layout_editor()
		return
	get_tree().change_scene_to_file("res://scenes/ui/mobile_control_layout_editor.tscn")


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
	custom_layout_btn.visible = GameSettings.mobile_controls_enabled


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
	var wallet_coin: int = SaveManager.get_wallet_gold()
	lines.append("3) 野猪钱包：%d 野猪币 · 最高波次 %d / 累计局数 %d / 通关次数 %d" % [wallet_coin, best_wave, run_count, victory_count])
	if has_pending_run:
		lines.append("4) 续玩存档：有（角色 %s，第 %d 波）" % [pending_character_id, pending_wave])
	else:
		lines.append("4) 续玩存档：无")
	data_summary_label.text = "\n".join(lines)


func _style_clear_hold_progress_bar() -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0)
	track.set_corner_radius_all(4)
	clear_hold_progress.add_theme_stylebox_override("background", track)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.82, 0.14, 0.16, 1.0)
	fill.set_corner_radius_all(4)
	clear_hold_progress.add_theme_stylebox_override("fill", fill)


func _sync_clear_hold_label_theme() -> void:
	var fs: int = clear_all_data_button.get_theme_font_size("font_size")
	if fs <= 0:
		fs = 24
	var fnt: Font = clear_all_data_button.get_theme_font("font")
	if fnt:
		clear_hold_label.add_theme_font_override("font", fnt)
	clear_hold_label.add_theme_font_size_override("font_size", fs)
	clear_hold_label.add_theme_color_override(
		"font_color", clear_all_data_button.get_theme_color("font_color"))


func _refresh_clear_button_idle_text() -> void:
	if is_clear_confirmed:
		clear_hold_label.text = "长按 3 秒执行清除"
		clear_hint_label.text = "已确认，请长按直至红色进度条走满（约 3 秒）"
		return
	clear_hold_label.text = "清除数据"
	clear_hint_label.text = "先点击确认，再长按 3 秒执行已选清除项"


func _on_clear_all_button_pressed() -> void:
	if is_clear_confirmed:
		return
	check_clear_saves.button_pressed = false
	check_clear_user_data.button_pressed = false
	delete_confirm_hint_label.text = "勾选后点击「确认删除」，再回到本页长按红色按钮执行。"
	delete_confirm_overlay.visible = true


func _on_clear_dialog_confirmed() -> void:
	var want_saves: bool = check_clear_saves.button_pressed
	var want_user: bool = check_clear_user_data.button_pressed
	if not want_saves and not want_user:
		delete_confirm_hint_label.text = "请至少勾选一项要清除的内容。"
		return
	_pending_clear_run_saves = want_saves
	_pending_clear_user_data = want_user
	delete_confirm_overlay.visible = false
	is_clear_confirmed = true
	_refresh_clear_button_idle_text()


func _on_clear_dialog_cancelled() -> void:
	delete_confirm_overlay.visible = false
	_pending_clear_run_saves = false
	_pending_clear_user_data = false


func _on_clear_all_button_down() -> void:
	if not is_clear_confirmed:
		return
	is_holding_clear_button = true
	clear_hold_progress.value = 0.0
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
	clear_hold_progress.value = clampf((held_seconds / CLEAR_HOLD_SECONDS) * 100.0, 0.0, 100.0)


func _cancel_clear_hold() -> void:
	is_holding_clear_button = false
	if not clear_hold_timer.is_stopped():
		clear_hold_timer.stop()
	clear_hold_progress.value = 0.0
	_refresh_clear_button_idle_text()


func _on_clear_hold_timer_timeout() -> void:
	is_holding_clear_button = false
	clear_hold_progress.value = 100.0
	_execute_clear_all_data()


func _execute_clear_all_data() -> void:
	clear_all_data_button.disabled = true
	clear_hold_label.text = "正在清除..."
	clear_hint_label.text = "请稍候，正在处理所选清除项"
	var saves_ok: bool = true
	var user_ok: bool = true
	if _pending_clear_run_saves and _pending_clear_user_data:
		saves_ok = SaveManager.delete_all_save_data()
		user_ok = GameSettings.clear_all_settings_data()
	elif _pending_clear_run_saves:
		saves_ok = SaveManager.delete_all_run_saves()
	elif _pending_clear_user_data:
		user_ok = SaveManager.delete_user_progress_and_settings()
	RunState.pause_reason = RunState.PauseReason.NONE
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().paused = false
	GameMusic.ensure_playing_main_volume()
	_refresh_data_summary()
	_pending_clear_run_saves = false
	_pending_clear_user_data = false
	is_clear_confirmed = false
	if saves_ok and user_ok:
		clear_result_message_label.text = "所选数据已清除完成。"
	else:
		clear_result_message_label.text = "部分数据清除失败。\n请检查本地文件写入权限后重试。"
	clear_result_overlay.visible = true


func _on_clear_result_back_pressed() -> void:
	is_clear_confirmed = false
	clear_all_data_button.disabled = false
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_back_pressed() -> void:
	if bool(get_meta("in_game_overlay", false)):
		var arena: Node = get_tree().get_first_node_in_group("arena")
		if arena != null and arena.has_method("close_in_game_settings"):
			arena.close_in_game_settings()
		return
	if _is_tutorial_mode:
		TutorialSession.is_in_tutorial_settings = false
		TutorialSession.set_step(TutorialSession.TutorialStep.INPUT_SELECT)
		GameMusic.ensure_playing_main_volume()
		RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
		return
	var target_scene: String = RunState.settings_return_scene_path
	if target_scene.is_empty():
		target_scene = MAIN_MENU_SCENE_PATH
	if target_scene == MAIN_MENU_SCENE_PATH:
		GameMusic.ensure_playing_main_volume()
	RunState.settings_return_scene_path = MAIN_MENU_SCENE_PATH
	get_tree().change_scene_to_file(target_scene)
