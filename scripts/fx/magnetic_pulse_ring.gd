extends Node2D

var _t: float = 0.0
const DURATION: float = 0.45


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	var k: float = _t / DURATION
	var r: float = lerpf(18.0, 120.0, k)
	var a: float = (1.0 - k) * 0.55
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.45, 0.82, 1.0, a), 2.5, true)
