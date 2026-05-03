extends Button

## 虚拟「攻击范围」键：圆角黑底按钮，按住即 show_attack_range（与键盘 R 一致）

const BLACK_BTN_THEME: Theme = preload("res://themes/black_button_theme.tres")
const FONT_BOLD: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")
## 与局内 `virtual_controls_layout_host` 中范围键基准边长一致
const BASE_PX: float = 72.0

const ACTION_ID: StringName = &"show_attack_range"
const ICON_TEXT: String = "⭕️"


func _ready() -> void:
	theme = BLACK_BTN_THEME
	add_theme_font_override("font", FONT_BOLD)
	add_theme_font_size_override("font_size", 30)
	text = ICON_TEXT
	clip_text = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(BASE_PX, BASE_PX)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_on_mobile_controls_changed(GameSettings.mobile_controls_enabled)
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)


func _on_mobile_controls_changed(enabled: bool) -> void:
	visible = enabled


func _on_button_down() -> void:
	_emit_action(true)


func _on_button_up() -> void:
	_emit_action(false)


func _emit_action(pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = String(ACTION_ID)
	ev.pressed = pressed
	Input.parse_input_event(ev)
