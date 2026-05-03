extends Node2D

var _vel: Vector2 = Vector2.ZERO
var _life: float = 0.55


func kick(from_dir: Vector2) -> void:
	var side: Vector2 = Vector2(-from_dir.y, from_dir.x).normalized()
	_vel = side * randf_range(120.0, 220.0) + from_dir * randf_range(40.0, 90.0)
	rotation = randf() * TAU


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	global_position += _vel * delta
	_vel *= 0.94
	_vel += Vector2(0, 160.0) * delta
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-4, -2, 8, 4), Color(0.82, 0.71, 0.38, 0.95), true)
