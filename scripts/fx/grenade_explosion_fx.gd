extends Node2D

## 榴弹爆炸扩散线；约 0.3s 后必定移除（不受 time_scale 影响）

var _t: float = 0.0
const DURATION: float = 0.3
var _start_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_usec = Time.get_ticks_usec()
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.create_timer(DURATION, true, true).timeout.connect(_hard_free)


func _hard_free() -> void:
	if is_instance_valid(self):
		queue_free()


func _process(_delta: float) -> void:
	_t = float(Time.get_ticks_usec() - _start_usec) / 1000000.0
	queue_redraw()


func _draw() -> void:
	var k: float = clampf(_t / DURATION, 0.0, 1.0)
	var r: float = lerpf(8.0, 140.0, 1.0 - pow(1.0 - k, 2.2))
	var a: float = (1.0 - k) * 0.75
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.55, 0.12, 0.18 * a))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(1.0, 0.85, 0.35, a), 3.0, true)
	var n: int = 12
	for i in range(n):
		var ang: float = float(i) / float(n) * TAU + k * 2.0
		var wob: float = 0.78 + 0.22 * sin(float(i * 3) + k * 8.0)
		var len: float = r * (0.52 + 0.48 * wob)
		var p: Vector2 = Vector2.from_angle(ang) * len
		draw_line(Vector2.ZERO, p, Color(0.95, 0.72, 0.35, a * 0.9), 2.0, true)
