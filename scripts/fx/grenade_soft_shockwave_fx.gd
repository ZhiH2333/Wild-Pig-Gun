extends Node2D

## 榴弹爆炸残留：与攻击范围预览相同的红色虚线圆；固定约 0.3s 后必定移除（不受 time_scale、脚本挂载顺序影响）

const DURATION_SEC: float = 0.3

var _start_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_usec = Time.get_ticks_usec()
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.create_timer(DURATION_SEC, true, true).timeout.connect(_hard_free)


func _hard_free() -> void:
	if is_instance_valid(self):
		queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var elapsed: float = float(Time.get_ticks_usec() - _start_usec) / 1000000.0
	var fade: float = 1.0 - clampf(elapsed / DURATION_SEC, 0.0, 1.0)
	var r: float = Projectile.GRENADE_AOE_RADIUS
	var total: int = maxi(12, AttackRangeBalance.PREVIEW_CIRCLE_SEGMENTS)
	var dash: int = maxi(1, AttackRangeBalance.PREVIEW_DASH_SEGMENTS)
	var gap: int = maxi(1, AttackRangeBalance.PREVIEW_GAP_SEGMENTS)
	var col: Color = AttackRangeBalance.PREVIEW_COLOR
	col.a *= fade
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
