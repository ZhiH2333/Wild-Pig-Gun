extends Control
class_name AccountStatusStrip

const FONT_PATH: String = "res://assets/fonts/SourceHanSansSC-Bold.otf"

@export var username: String = "占位用户名"
@export var connected: bool = true

@onready var _login_label: Label = $Margin/VBox/LoginLabel
@onready var _status_prefix: Label = $Margin/VBox/StatusRow/StatusPrefix
@onready var _status_value: Label = $Margin/VBox/StatusRow/StatusValue


func _ready() -> void:
	var f: Font = load(FONT_PATH) as Font
	if f != null:
		_login_label.add_theme_font_override("font", f)
		_status_prefix.add_theme_font_override("font", f)
		_status_value.add_theme_font_override("font", f)
	_login_label.add_theme_font_size_override("font_size", 17)
	_status_prefix.add_theme_font_size_override("font_size", 16)
	_status_value.add_theme_font_size_override("font_size", 16)
	_login_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 0.95))
	_status_prefix.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 0.88))
	refresh()


func set_username(value: String) -> void:
	username = value
	if is_node_ready():
		refresh()


func set_connected(value: bool) -> void:
	connected = value
	if is_node_ready():
		refresh()


func refresh() -> void:
	if _login_label == null:
		return
	_login_label.text = "已登录至\n%s" % username
	_login_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if connected:
		_status_value.text = "已连接"
		_status_value.add_theme_color_override("font_color", Color(0.38, 0.82, 0.48, 1.0))
	else:
		_status_value.text = "未连接"
		_status_value.add_theme_color_override("font_color", Color(0.95, 0.32, 0.28, 1.0))
