extends Node2D

## 世界坐标伤害飘字，上移淡出后销毁

const RISE_SPEED: float = 62.0
const LIFETIME: float = 0.75

var _amount: int = 0
var _elapsed: float = 0.0
var _is_crit: bool = false
var _rgb: Color = Color(1.0, 0.92, 0.35)


func setup(amount: int, is_crit: bool = false) -> void:
	_amount = amount
	_is_crit = is_crit
	if is_crit:
		_rgb = Color(1.0, 0.45, 0.2)
	else:
		_rgb = Color(1.0, 0.92, 0.35)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= RISE_SPEED * delta
	queue_redraw()
	if _elapsed >= LIFETIME:
		queue_free()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var text: String = str(_amount)
	var sz: int = 16 if _is_crit else 13
	var a: float = clampf(1.0 - _elapsed / LIFETIME, 0.0, 1.0)
	var c: Color = _rgb
	c.a = a
	draw_string(font, Vector2(-18, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, sz, c)
