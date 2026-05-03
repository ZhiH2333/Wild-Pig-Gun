extends Node2D

## 在敌人身上叠一层燃烧/冻结可读表现（不替代各敌人 _draw 身体）

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var eb: EnemyBase = get_parent() as EnemyBase
	if eb == null:
		return
	if eb.status_burn_time_left() > 0.05:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 28, Color(1.0, 0.45, 0.1, 0.55), 2.2, true)
		for i in range(5):
			var a: float = float(i) / 5.0 * TAU + eb.status_burn_time_left() * 3.0
			draw_circle(Vector2.from_angle(a) * 16.0, 2.2, Color(1.0, 0.55, 0.15, 0.65))
	if eb.status_freeze_time_left() > 0.05:
		draw_circle(Vector2.ZERO, 20.0, Color(0.55, 0.82, 1.0, 0.38))
		draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 32, Color(0.75, 0.92, 1.0, 0.5), 1.8, true)
