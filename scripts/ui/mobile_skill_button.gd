extends Button

## 触控技能键：与设置页自定义控件（black_button_theme）一致的圆形外观。

const FONT_BOLD: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")

func _ready() -> void:
	add_to_group("mobile_skill_button")
	_on_mobile_controls_changed(GameSettings.mobile_controls_enabled)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)
	focus_mode = Control.FOCUS_NONE
	var diam: float = 88.0
	custom_minimum_size = Vector2(diam, diam)
	add_theme_font_override("font", FONT_BOLD)
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))
	add_theme_color_override("font_pressed_color", Color(0, 0, 0, 1))
	_apply_circle_style(diam)
	text = "技能"


func _apply_circle_style(diam: float) -> void:
	var r: int = int(floorf(diam * 0.5))
	var n: StyleBoxFlat = StyleBoxFlat.new()
	n.bg_color = Color(0, 0, 0, 0.55)
	n.set_border_width_all(2)
	n.border_color = Color(1, 1, 1, 0.2)
	n.set_corner_radius_all(r)
	var h: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	h.bg_color = Color(1, 1, 1, 0.75)
	h.border_color = Color(1, 1, 1, 1)
	var p: StyleBoxFlat = StyleBoxFlat.new()
	p.bg_color = Color(1, 1, 1, 1)
	p.set_corner_radius_all(r)
	add_theme_stylebox_override("normal", n)
	add_theme_stylebox_override("hover", h)
	add_theme_stylebox_override("pressed", p)


func _on_mobile_controls_changed(enabled: bool) -> void:
	visible = enabled


func _on_button_down() -> void:
	_emit_skill_action(true)


func _on_button_up() -> void:
	_emit_skill_action(false)


func _emit_skill_action(pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = "skill"
	ev.pressed = pressed
	Input.parse_input_event(ev)
