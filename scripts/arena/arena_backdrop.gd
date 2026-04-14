extends Node2D

## 远景：整屏金属底图 + 渐变天幕（仅地平线上方）+ 山形剪影 + 网格
## draw_texture_rect(..., tile=true) 需要纹理导入中开启 Repeat；否则易呈洋红/紫。
## 此处用 tile=false 单张拉伸铺满 1920×1080，不依赖 repeat。
## 天幕为半透明叠色（modulate.a 小于 1），金属纹路始终存在，仅被压暗/冷色，避免「上半屏无纹路」观感。

const _METAL_TEX: Texture2D = preload("res://assets/sprites/metal.jpg")
const _VIEW_W: float = 1920.0
const _VIEW_H: float = 1080.0
## 与天色叠色后仍接近全屏统一亮度（略提亮金属底）
const _METAL_MODULATE := Color(0.93, 0.94, 0.97, 1.0)
## 浅色冷灰天幕（避免与压暗后的金属差过大）
const _SKY_TOP := Color(0.44, 0.46, 0.52, 1.0)
const _SKY_MID := Color(0.50, 0.50, 0.56, 1.0)
const _SKY_BOT := Color(0.54, 0.54, 0.60, 1.0)
## 天幕叠色区域高度（比例）；与 _SKY_TINT_ALPHA 一起调冷暖与通透感
const _SKY_BAND_FRAC: float = 0.32
## 天幕叠色强度：宜低以保持与下半屏金属视亮度一致
const _SKY_TINT_ALPHA: float = 0.16

var _t: float = 0.0
## 天幕用连续渐变，避免多段 draw_rect 在缩放后产生明显条纹/分带
var _sky_gradient: GradientTexture2D


func _ready() -> void:
	var g: Gradient = Gradient.new()
	var mid: Color = _SKY_TOP.lerp(_SKY_MID, 0.65)
	## 地平线处贴近提亮后的金属顶，减少上下亮度跳变
	var at_horizon: Color = _SKY_BOT.lerp(Color(0.62, 0.64, 0.68, 1.0), 0.55)
	g.offsets = PackedFloat32Array([0.0, 0.4, 0.72, 1.0])
	g.colors = PackedColorArray([_SKY_TOP, mid, _SKY_BOT, at_horizon])
	g.interpolation_color_space = Gradient.GRADIENT_COLOR_SPACE_OKLAB
	var gt: GradientTexture2D = GradientTexture2D.new()
	gt.gradient = g
	gt.width = 8
	gt.height = 256
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	_sky_gradient = gt


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = _VIEW_W
	var h: float = _VIEW_H
	var horizon: float = h * _SKY_BAND_FRAC
	draw_texture_rect(_METAL_TEX, Rect2(0.0, 0.0, w, h), false, _METAL_MODULATE)
	var parallax: float = sin(_t * 0.08) * 6.0
	if _sky_gradient != null:
		draw_texture_rect(
			_sky_gradient,
			Rect2(0.0, 0.0, w, horizon),
			false,
			Color(1.0, 1.0, 1.0, _SKY_TINT_ALPHA),
		)
	_draw_hill_silhouette(Vector2(parallax * 0.3, horizon - 40.0), w, 90.0, Color(0.16, 0.17, 0.21, 0.92), 0.012)
	_draw_hill_silhouette(Vector2(-parallax * 0.5, horizon - 8.0), w, 120.0, Color(0.19, 0.15, 0.17, 0.86), 0.008)
	_draw_hill_silhouette(Vector2(parallax * 0.8, horizon + 22.0), w, 70.0, Color(0.22, 0.18, 0.16, 0.70), 0.015)
	var step: float = 88.0
	var gx: float = fmod(_t * 18.0, step)
	var gcol := Color(0.26, 0.28, 0.34, 0.12)
	var x: float = -step + gx
	while x <= w + step:
		draw_line(Vector2(x, horizon + 30.0), Vector2(x, h), gcol, 1.0)
		x += step
	var y: float = horizon + 40.0
	while y <= h:
		draw_line(Vector2(0.0, y), Vector2(w, y), Color(0.22, 0.23, 0.27, 0.08), 1.0)
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
