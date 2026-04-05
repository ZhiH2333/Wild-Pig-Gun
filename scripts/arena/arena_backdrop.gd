extends Node2D

## 轻量网格背景，不参与碰撞


func _draw() -> void:
	var w: float = 1920.0
	var h: float = 1080.0
	var c1: Color = Color(0.11, 0.12, 0.14, 0.55)
	var c2: Color = Color(0.09, 0.1, 0.12, 0.45)
	var step: float = 72.0
	var x: float = 0.0
	while x <= w:
		draw_line(Vector2(x, 0), Vector2(x, h), c1, 1.0)
		x += step
	var y: float = 0.0
	while y <= h:
		draw_line(Vector2(0, y), Vector2(w, y), c2, 1.0)
		y += step
