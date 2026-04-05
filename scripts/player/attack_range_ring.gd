extends Node2D

## 按住 R（show_attack_range）时用红色虚线画出攻击范围边界；平时不绘制

var _was_showing: bool = false


func _ready() -> void:
	z_index = -2
	position = Vector2.ZERO


func _process(_delta: float) -> void:
	var showing: bool = Input.is_action_pressed("show_attack_range")
	if showing or _was_showing:
		_was_showing = showing
		queue_redraw()


func _draw() -> void:
	if not Input.is_action_pressed("show_attack_range"):
		return
	var pl: Node = get_parent()
	if pl == null or not pl.has_method("get_attack_range_radius"):
		return
	var r: float = float(pl.call("get_attack_range_radius"))
	var total: int = maxi(12, AttackRangeBalance.PREVIEW_CIRCLE_SEGMENTS)
	var dash: int = maxi(1, AttackRangeBalance.PREVIEW_DASH_SEGMENTS)
	var gap: int = maxi(1, AttackRangeBalance.PREVIEW_GAP_SEGMENTS)
	var col: Color = AttackRangeBalance.PREVIEW_COLOR
	var lw: float = AttackRangeBalance.PREVIEW_LINE_WIDTH
	var step: float = TAU / float(total)
	var i: int = 0
	while i < total:
		for k in range(dash):
			var j: int = i + k
			if j >= total:
				break
			var a1: float = float(j) * step
			var a2: float = float(j + 1) * step
			if j >= total - 1:
				a2 = TAU
			draw_line(Vector2.from_angle(a1) * r, Vector2.from_angle(a2) * r, col, lw, true)
		i += dash + gap
