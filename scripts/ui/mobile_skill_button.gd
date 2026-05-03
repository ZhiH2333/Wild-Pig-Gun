extends Button

## 触控技能键占位：注入 InputMap action「skill」（键鼠默认空格与此共用）。

func _ready() -> void:
	add_to_group("mobile_skill_button")
	_on_mobile_controls_changed(GameSettings.mobile_controls_enabled)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)
	focus_mode = Control.FOCUS_NONE
	var diam: float = 88.0
	custom_minimum_size = Vector2(diam, diam)
	_apply_circle_style(diam)
	text = "技能"
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 0.95))
	add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	add_theme_color_override("font_pressed_color", Color(0.95, 0.96, 1.0, 1))


func _apply_circle_style(diam: float) -> void:
	var r: int = int(floorf(diam * 0.5))
	var n: StyleBoxFlat = StyleBoxFlat.new()
	n.bg_color = Color(0.22, 0.48, 0.92, 0.62)
	n.set_corner_radius_all(r)
	var h: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.28, 0.58, 0.98, 0.78)
	var p: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.14, 0.38, 0.82, 0.82)
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
