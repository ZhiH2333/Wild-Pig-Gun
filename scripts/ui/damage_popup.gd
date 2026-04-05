extends Node2D

## 世界坐标伤害飘字，上移淡出后销毁

const RISE_SPEED: float = 62.0
const LIFETIME: float = 0.75
const CRIT_SCALE_START: float = 1.3
const CRIT_SCALE_DURATION: float = 0.15

const _FONT: Font = preload("res://assets/fonts/pixel_font.ttf")

var _amount: int = 0
var _elapsed: float = 0.0
var _is_crit: bool = false
var _rgb: Color = Color(1, 1, 1, 1)
var _font_size: int = 22
var _scale_t: float = 0.0


func setup(amount: int, is_crit: bool = false) -> void:
	_amount = amount
	_is_crit = is_crit
	_elapsed = 0.0
	if is_crit:
		_rgb = Color(1, 0.92, 0.35, 1)
		_font_size = 30
		scale = Vector2(1.3, 1.3)
		_scale_t = 0.0
	else:
		_rgb = Color(1, 1, 1, 1)
		_font_size = 22
		scale = Vector2.ONE
	queue_redraw()


func _process(delta: float) -> void:
	if not is_inside_tree():
		return

	# 暴击缩放动画：从 1.3 线性插值到 1.0
	if _is_crit and _scale_t < CRIT_SCALE_DURATION:
		_scale_t += delta
		var t: float = clampf(_scale_t / CRIT_SCALE_DURATION, 0.0, 1.0)
		var s: float = lerp(CRIT_SCALE_START, 1.0, t)
		scale = Vector2(s, s)

	# 上移
	position.y -= RISE_SPEED * delta

	_elapsed += delta
	queue_redraw()

	if _elapsed >= LIFETIME:
		queue_free()


func _draw() -> void:
	var text: String = str(_amount)
	var a: float = clampf(1.0 - _elapsed / LIFETIME, 0.0, 1.0)

	# 描边：黑色，偏移 (+2, +2)
	var outline_color: Color = Color(0, 0, 0, a)
	draw_string(_FONT, Vector2(-16, 2), text, HORIZONTAL_ALIGNMENT_CENTER, 40, _font_size, outline_color)

	# 主文字：_rgb 含 alpha
	var main_color: Color = _rgb
	main_color.a = a
	draw_string(_FONT, Vector2(-18, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, _font_size, main_color)
