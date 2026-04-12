extends Control

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const CLEAR_HOLD_SECONDS: float = 3.0

@onready var master_slider: HSlider = $Center/MainColumn/Scroll/Contents/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/MainColumn/Scroll/Contents/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/MainColumn/Scroll/Contents/SfxRow/SfxSlider
@onready var ui_scale_slider: HSlider = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleSlider
@onready var ui_scale_value: Label = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleValue
@onready var view_scale_slider: HSlider = $Center/MainColumn/Scroll/Contents/ViewScaleRow/ViewScaleSlider
@onready var view_scale_value: Label = $Center/MainColumn/Scroll/Contents/ViewScaleRow/ViewScaleValue
@onready var fullscreen_check: CheckBox = $Center/MainColumn/Scroll/Contents/FullscreenCheck
@onready var vsync_check: CheckBox = $Center/MainColumn/Scroll/Contents/VsyncCheck
@onready var vsync_fps_row: HBoxContainer = $Center/MainColumn/Scroll/Contents/VsyncFpsRow
@onready var vsync_fps_slider: HSlider = $Center/MainColumn/Scroll/Contents/VsyncFpsRow/VsyncFpsSlider
@onready var vsync_fps_value: Label = $Center/MainColumn/Scroll/Contents/VsyncFpsRow/VsyncFpsValue
@onready var show_fps_check: CheckBox = $Center/MainColumn/Scroll/Contents/ShowFpsCheck
@onready var mobile_controls_check: CheckBox = $Center/MainColumn/Scroll/Contents/MobileControlsCheck
@onready var data_summary_label: Label = $Center/MainColumn/Scroll/Contents/DataSummaryLabel
@onready var clear_hint_label: Label = $Center/MainColumn/Scroll/Contents/ClearHintLabel
@onready var clear_all_data_button: Button = $Center/MainColumn/Scroll/Contents/ClearAllDataButton
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


func _ready() -> void:
	GameMusic.duck_for_subpage()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	view_scale_slider.value_changed.connect(_on_view_scale_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	vsync_fps_slider.value_changed.connect(_on_vsync_fps_changed)
	show_fps_check.toggled.connect(_on_show_fps_toggled)
	mobile_controls_check.toggled.connect(_on_mobile_controls_toggled)
	clear_all_data_button.pressed.connect(_on_clear_all_button_pressed)
	clear_all_data_button.button_down.connect(_on_clear_all_button_down)
	clear_all_data_button.button_up.connect(_on_clear_all_button_up)
	delete_confirm_button.pressed.connect(_on_clear_dialog_confirmed)
	delete_cancel_button.pressed.connect(_on_clear_dialog_cancelled)
	clear_result_back_button.pressed.connect(_on_clear_result_back_pressed)
	clear_hold_timer.timeout.connect(_on_clear_hold_timer_timeout)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value = GameSettings.master_linear
	music_slider.value = GameSettings.music_linear
	sfx_slider.value = GameSettings.sfx_linear
	ui_scale_slider.value = GameSettings.ui_scale
	view_scale_slider.value = GameSettings.view_scale
	fullscreen_check.button_pressed = GameSettings.fullscreen
	vsync_check.button_pressed = GameSettings.vsync_enabled
	vsync_fps_slider.value = GameSettings.vsync_fps
	show_fps_check.button_pressed = GameSettings.show_fps
	mobile_controls_check.button_pressed = GameSettings.mobile_controls_enabled
	_refresh_ui_scale_label()
	_refresh_view_scale_label()
	_refresh_vsync_fps_label()
	_refresh_vsync_fps_visibility()
	_refresh_data_summary()
	_refresh_clear_button_idle_text()
	if OS.get_name() == "Web":
		fullscreen_check.visible = false
		vsync_check.visible = false
		vsync_fps_row.visible = false


func _on_master_changed(v: float) -> void:
	GameSettings.set_master_linear(v)


func _on_music_changed(v: float) -> void:
	GameSettings.set_music_linear(v)


func _on_sfx_changed(v: float) -> void:
	GameSettings.set_sfx_linear(v)


func _on_ui_scale_changed(v: float) -> void:
	GameSettings.set_ui_scale(v)
	_refresh_ui_scale_label()


func _on_view_scale_changed(v: float) -> void:
	GameSettings.set_view_scale(v)
	_refresh_view_scale_label()


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_fullscreen(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)
	_refresh_vsync_fps_visibility()


func _on_vsync_fps_changed(v: float) -> void:
	GameSettings.set_vsync_fps(v)
	_refresh_vsync_fps_label()


func _on_show_fps_toggled(pressed: bool) -> void:
	GameSettings.set_show_fps(pressed)


func _on_mobile_controls_toggled(pressed: bool) -> void:
	GameSettings.set_mobile_controls_enabled(pressed)


func _refresh_ui_scale_label() -> void:
	ui_scale_value.text = "%d%%" % int(round(GameSettings.ui_scale * 100.0))


func _refresh_view_scale_label() -> void:
	view_scale_value.text = "%d%%" % int(round(GameSettings.view_scale * 100.0))


func _refresh_vsync_fps_label() -> void:
	vsync_fps_value.text = "%d FPS" % GameSettings.vsync_fps


func _refresh_vsync_fps_visibility() -> void:
	vsync_fps_row.visible = vsync_check.button_pressed


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
