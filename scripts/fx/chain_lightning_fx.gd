extends Node2D

## 短暂绘制闪电折线后自毁

var _points: PackedVector2Array = PackedVector2Array()
var _life: float = 0.22


func setup_world_points(world_pts: PackedVector2Array) -> void:
	_points = world_pts


func _ready() -> void:
	z_index = 8


func _process(delta: float) -> void:
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	if _points.size() < 2:
		return
	var local_pts: PackedVector2Array = PackedVector2Array()
	for i in range(_points.size()):
		local_pts.append(to_local(_points[i]))
	var alpha: float = clampf(_life / 0.22, 0.0, 1.0)
	var c: Color = Color(0.55, 0.78, 1.0, 0.92 * alpha)
	for i in range(local_pts.size() - 1):
		draw_line(local_pts[i], local_pts[i + 1], c, 3.2 - float(i) * 0.35, true)
		draw_circle(local_pts[i + 1], 3.5 - float(i) * 0.4, Color(1.0, 1.0, 1.0, 0.55 * alpha))
