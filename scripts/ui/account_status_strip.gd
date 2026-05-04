extends Control
class_name AccountStatusStrip

signal login_requested

const FONT_PATH: String = "res://assets/fonts/SourceHanSansSC-Bold.otf"
const BLACK_BUTTON_THEME: Theme = preload("res://themes/black_button_theme.tres")

@export var username: String = "占位用户名"
@export var connected: bool = true
@export var logged_in: bool = true

@onready var _login_label: Label = $Margin/VBox/LoginLabel
@onready var _login_button: Button = $Margin/VBox/LoginButton
@onready var _status_prefix: Label = $Margin/VBox/StatusRow/StatusPrefix
@onready var _status_value: Label = $Margin/VBox/StatusRow/StatusValue


func _ready() -> void:
	if not AccountDevState.overrides_changed.is_connected(_on_account_dev_overrides_changed):
		AccountDevState.overrides_changed.connect(_on_account_dev_overrides_changed)
	var f: Font = load(FONT_PATH) as Font
	if f != null:
		_login_label.add_theme_font_override("font", f)
		_login_button.add_theme_font_override("font", f)
		_status_prefix.add_theme_font_override("font", f)
		_status_value.add_theme_font_override("font", f)
	_login_label.add_theme_font_size_override("font_size", 21)
	_login_button.add_theme_font_size_override("font_size", 21)
	_login_button.theme = BLACK_BUTTON_THEME
	_login_button.text = "登录"
	_login_button.focus_mode = Control.FOCUS_NONE
	_login_button.pressed.connect(_on_login_button_pressed)
	_status_prefix.add_theme_font_size_override("font_size", 19)
	_status_value.add_theme_font_size_override("font_size", 19)
	_login_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 0.95))
	_status_prefix.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 0.88))
	refresh()


func _on_account_dev_overrides_changed() -> void:
	refresh()


func _on_login_button_pressed() -> void:
	login_requested.emit()


func set_username(value: String) -> void:
	username = value
	if is_node_ready():
		refresh()


func set_connected(value: bool) -> void:
	connected = value
	if is_node_ready():
		refresh()


func apply_wp_pass_login(display_name: String) -> void:
	logged_in = true
	username = display_name.strip_edges()
	if username.is_empty():
		username = "WP Pass 用户"
	if is_node_ready():
		refresh()


func refresh() -> void:
	if _login_label == null:
		return
	var eff_connected: bool = AccountDevState.get_effective_connected(connected)
	var eff_logged_in: bool = AccountDevState.get_effective_logged_in(logged_in)
	if eff_logged_in:
		_login_label.visible = true
		if _login_button != null:
			_login_button.visible = false
		_login_label.text = "已登录至\n%s" % username
		_login_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 0.95))
	else:
		_login_label.visible = false
		if _login_button != null:
			_login_button.visible = true
	_login_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if eff_connected:
		_status_value.text = "已连接"
		_status_value.add_theme_color_override("font_color", Color(0.38, 0.82, 0.48, 1.0))
	else:
		_status_value.text = "未认证"
		_status_value.add_theme_color_override("font_color", Color(0.95, 0.32, 0.28, 1.0))
