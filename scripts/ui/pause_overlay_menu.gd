extends CanvasLayer

const HOLD_SECONDS: float = 3.0

@onready var resume_button: Button = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/ResumeButton
@onready var settings_button: Button = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/SettingsButton
@onready var save_menu_button: Button = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/SaveMenuButton
@onready var quit_no_save_button: Button = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/QuitNoSaveButton
@onready var quit_hold_progress: ProgressBar = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/QuitNoSaveButton/QuitHoldProgress
@onready var quit_hold_label: Label = $MenuButtonsWrap/LeftMenuColumn/ButtonContainer/QuitNoSaveButton/QuitHoldLabel
@onready var quit_confirm_overlay: Control = $QuitConfirmOverlay
@onready var quit_dialog_confirm: Button = $QuitConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/ConfirmButton
@onready var quit_dialog_cancel: Button = $QuitConfirmOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/CancelButton
@onready var quit_hold_timer: Timer = $QuitHoldTimer

var _is_quit_confirmed: bool = false
var _is_holding_quit: bool = false


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	save_menu_button.pressed.connect(_on_save_menu_pressed)
	quit_no_save_button.pressed.connect(_on_quit_no_save_pressed)
	quit_no_save_button.button_down.connect(_on_quit_button_down)
	quit_no_save_button.button_up.connect(_on_quit_button_up)
	quit_dialog_confirm.pressed.connect(_on_quit_dialog_confirmed)
	quit_dialog_cancel.pressed.connect(_on_quit_dialog_cancelled)
	quit_hold_timer.timeout.connect(_on_quit_hold_timer_timeout)
	quit_hold_timer.wait_time = HOLD_SECONDS
	_style_quit_hold_bar()
	_sync_quit_label_theme()
	_refresh_quit_idle_text()
	set_process(true)


func _reset_quit_flow() -> void:
	_is_quit_confirmed = false
	_cancel_quit_hold()
	if is_instance_valid(quit_confirm_overlay):
		quit_confirm_overlay.visible = false
	_refresh_quit_idle_text()


## 由 Arena 在隐藏暂停层时调用（CanvasLayer 无可靠的 visibility 通知枚举）
func reset_when_pause_closed() -> void:
	_reset_quit_flow()


func _style_quit_hold_bar() -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0)
	track.set_corner_radius_all(4)
	quit_hold_progress.add_theme_stylebox_override("background", track)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.82, 0.14, 0.16, 1.0)
	fill.set_corner_radius_all(4)
	quit_hold_progress.add_theme_stylebox_override("fill", fill)


func _sync_quit_label_theme() -> void:
	var fs: int = quit_no_save_button.get_theme_font_size("font_size")
	if fs <= 0:
		fs = 22
	var fnt: Font = quit_no_save_button.get_theme_font("font")
	if fnt:
		quit_hold_label.add_theme_font_override("font", fnt)
	quit_hold_label.add_theme_font_size_override("font_size", fs)
	quit_hold_label.add_theme_color_override(
		"font_color", quit_no_save_button.get_theme_color("font_color"))


func _refresh_quit_idle_text() -> void:
	if _is_quit_confirmed:
		quit_hold_label.text = "长按 3 秒不保存并退出"
		return
	quit_hold_label.text = "不保存并返回主菜单"


func _on_resume_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("_on_pause_resume_pressed"):
		arena._on_pause_resume_pressed()


func _on_save_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("save_run_and_return_to_menu"):
		arena.save_run_and_return_to_menu()


func _on_settings_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("open_in_game_settings"):
		arena.open_in_game_settings()


func _on_quit_no_save_pressed() -> void:
	if _is_quit_confirmed:
		return
	quit_confirm_overlay.visible = true


func _on_quit_dialog_confirmed() -> void:
	quit_confirm_overlay.visible = false
	_is_quit_confirmed = true
	_refresh_quit_idle_text()


func _on_quit_dialog_cancelled() -> void:
	quit_confirm_overlay.visible = false


func _on_quit_button_down() -> void:
	if not _is_quit_confirmed:
		return
	_is_holding_quit = true
	quit_hold_progress.value = 0.0
	quit_hold_timer.start(HOLD_SECONDS)


func _on_quit_button_up() -> void:
	if not _is_holding_quit:
		return
	_cancel_quit_hold()


func _process(_delta: float) -> void:
	if not _is_holding_quit:
		return
	if quit_hold_timer.is_stopped():
		return
	var held: float = HOLD_SECONDS - quit_hold_timer.time_left
	if held < 0.0:
		held = 0.0
	quit_hold_progress.value = clampf((held / HOLD_SECONDS) * 100.0, 0.0, 100.0)


func _cancel_quit_hold() -> void:
	_is_holding_quit = false
	if not quit_hold_timer.is_stopped():
		quit_hold_timer.stop()
	quit_hold_progress.value = 0.0
	_refresh_quit_idle_text()


func _on_quit_hold_timer_timeout() -> void:
	_is_holding_quit = false
	quit_hold_progress.value = 100.0
	var arena: Node = get_parent()
	if arena != null and arena.has_method("quit_to_menu_without_saving"):
		arena.quit_to_menu_without_saving()


func _exit_tree() -> void:
	_is_holding_quit = false
	if quit_hold_timer != null and not quit_hold_timer.is_stopped():
		quit_hold_timer.stop()
