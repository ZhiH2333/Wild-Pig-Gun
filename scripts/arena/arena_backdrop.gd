extends Node2D

## 远景：渐变天幕 + 多层山形剪影 + 微弱视差偏移（随相机可扩展）

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = 1920.0
	var h: float = 1080.0
	var parallax: float = sin(_t * 0.08) * 6.0
	var sky_top := Color(0.06, 0.07, 0.14, 1.0)
	var sky_mid := Color(0.12, 0.11, 0.22, 1.0)
	var sky_bot := Color(0.18, 0.14, 0.2, 1.0)
	for i in range(24):
		var y0: float = float(i) / 24.0 * h
		var y1: float = float(i + 1) / 24.0 * h
		var u: float = float(i) / 23.0
		var c: Color = sky_top.lerp(sky_mid, clampf(u * 1.4, 0.0, 1.0))
		if u > 0.45:
			c = sky_mid.lerp(sky_bot, clampf((u - 0.45) / 0.55, 0.0, 1.0))
		draw_rect(Rect2(0.0, y0, w, y1 - y0 + 0.5), c)
	var horizon: float = h * 0.42
	draw_rect(Rect2(0.0, horizon, w, h - horizon), Color(0.08, 0.09, 0.12, 0.92))
	_draw_hill_silhouette(Vector2(parallax * 0.3, horizon - 40.0), w, 90.0, Color(0.11, 0.12, 0.16, 0.95), 0.012)
	_draw_hill_silhouette(Vector2(-parallax * 0.5, horizon - 8.0), w, 120.0, Color(0.14, 0.1, 0.12, 0.88), 0.008)
	_draw_hill_silhouette(Vector2(parallax * 0.8, horizon + 22.0), w, 70.0, Color(0.18, 0.14, 0.11, 0.72), 0.015)
	var step: float = 88.0
	var gx: float = fmod(_t * 18.0, step)
	var gcol := Color(0.2, 0.22, 0.28, 0.12)
	var x: float = -step + gx
	while x <= w + step:
		draw_line(Vector2(x, horizon + 30.0), Vector2(x, h), gcol, 1.0)
		x += step
	var y: float = horizon + 40.0
	while y <= h:
		draw_line(Vector2(0.0, y), Vector2(w, y), Color(0.16, 0.17, 0.2, 0.08), 1.0)
		y += step


func _draw_hill_silhouette(origin: Vector2, width: float, height: float, col: Color, freq: float) -> void:
	## 山脊 local y 必须恒 ≤ height（底边），否则顶点落到底边下方会自交，triangulation 失败
	var bottom_y: float = height
	var ridge_min_y: float = maxf(4.0, height * 0.12)
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(origin + Vector2(0.0, bottom_y))
	var seg: int = 48
	for i in range(seg + 1):
		var xf: float = float(i) / float(seg) * width
		var wave: float = sin(xf * freq + _t * 0.4) * 18.0 + sin(xf * freq * 2.3) * 8.0
		var ridge_y: float = height - wave * 0.35
		ridge_y = clampf(ridge_y, ridge_min_y, bottom_y - 2.0)
		pts.append(origin + Vector2(xf, ridge_y))
	pts.append(origin + Vector2(width, bottom_y))
	draw_colored_polygon(pts, col)
