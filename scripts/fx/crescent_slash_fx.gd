extends Node2D

var _dir: Vector2 = Vector2.RIGHT
var _t: float = 0.0
const DUR: float = 0.16


func kick(direction: Vector2) -> void:
	_dir = direction.normalized()
	rotation = _dir.angle()


func _process(delta: float) -> void:
	_t += delta
	global_position += _dir * 520.0 * delta
	queue_redraw()
	if _t >= DUR:
		queue_free()


func _draw() -> void:
	var k: float = 1.0 - _t / DUR
	var c: Color = Color(0.62, 0.35, 0.95, 0.88 * k)
	var r: float = lerpf(28.0, 52.0, _t / DUR)
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = 14
	for i in range(n + 1):
		var u: float = float(i) / float(n)
		var ang: float = lerpf(-0.55, 0.55, u)
		var p: Vector2 = Vector2(lerpf(0.0, r, u), 0.0).rotated(ang)
		pts.append(p)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], c, 4.5 - float(i) * 0.18, true)
	if _t > DUR * 0.45:
		var burst: float = (_t - DUR * 0.45) / (DUR * 0.55)
		for j in range(8):
			var ang2: float = float(j) / 8.0 * TAU
			var pr: Vector2 = Vector2.from_angle(ang2) * (10.0 + 22.0 * burst)
			draw_circle(pr, 2.2, Color(0.9, 0.75, 1.0, (1.0 - burst) * 0.7))
