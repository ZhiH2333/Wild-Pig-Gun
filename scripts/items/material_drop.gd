extends Node2D
class_name MaterialDrop

## 材料掉落节点：弹出后自动吸附到玩家
## 需求：10.1

signal collected(material_id: String, amount: int)

var material_id: String = "gold"
var amount: int = 1

const COLORS: Dictionary = {
	"gold": Color(1.0, 0.85, 0.1),
	"heal": Color(0.2, 0.9, 0.3),
	"box":  Color(0.2, 0.7, 1.0),
}

## 吸附开始距离（全图范围，地图对角线约 2200px）
const ATTRACT_RADIUS: float = 3000.0
## 拾取判定距离
const COLLECT_RADIUS: float = 12.0
## 吸附飞行：最小速度（远处）和最大速度（近处），单位 px/s
const FLY_SPEED_MIN: float = 300.0
const FLY_SPEED_MAX: float = 900.0
## 加速距离阈值：小于此距离时达到最大速度
const ACCEL_DIST: float = 150.0

## 弹跳阶段
var _bounce_velocity: Vector2 = Vector2.ZERO
var _bounce_time: float = 0.0
const BOUNCE_DURATION: float = 0.25

var _player: Node2D = null
var _collected: bool = false
## 缩放动画（拾取时缩小消失）
var _scale_out: float = 1.0


func _ready() -> void:
	# 随机弹出方向，给掉落一个初速度
	var angle := randf() * TAU
	var speed := randf_range(40.0, 90.0)
	_bounce_velocity = Vector2(cos(angle), sin(angle)) * speed

	# 找玩家引用
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

	queue_redraw()


func _process(delta: float) -> void:
	if _collected:
		return
	if _player == null or not is_instance_valid(_player):
		return

	var dist := global_position.distance_to(_player.global_position)

	# 弹跳阶段：先弹出去
	if _bounce_time < BOUNCE_DURATION:
		_bounce_time += delta
		var t := _bounce_time / BOUNCE_DURATION
		# 弹跳衰减：速度随时间减小
		var damping := 1.0 - t
		global_position += _bounce_velocity * damping * delta
		queue_redraw()
		return

	# 吸附阶段：向玩家飞，近处加速
	if dist < ATTRACT_RADIUS:
		# 非线性加速：距离越近速度越快（二次曲线）
		var t := clampf(1.0 - dist / ACCEL_DIST, 0.0, 1.0)
		var speed := lerpf(FLY_SPEED_MIN, FLY_SPEED_MAX, t * t)
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * speed * delta
		queue_redraw()

		# 到达玩家时拾取
		if dist < COLLECT_RADIUS:
			_do_collect()


func _do_collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(material_id, amount)
	queue_free()


## 由 Arena 定时器调用，强制跳过弹跳阶段立即吸附
func force_attract() -> void:
	_bounce_time = BOUNCE_DURATION


func _draw() -> void:
	var color: Color = COLORS.get(material_id, Color(1, 1, 1))
	var s := _scale_out
	match material_id:
		"gold":
			draw_circle(Vector2.ZERO, 8.0 * s, color)
			draw_circle(Vector2(-2, -2) * s, 3.0 * s, Color(1, 1, 0.7, 0.6))
			if amount > 1:
				var font := ThemeDB.fallback_font
				draw_string(font, Vector2(-6, 18), "x%d" % amount,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.2))
		"heal":
			draw_circle(Vector2.ZERO, 8.0 * s, color)
			draw_rect(Rect2(-1 * s, -5 * s, 2 * s, 10 * s), Color(1, 1, 1, 0.8))
			draw_rect(Rect2(-5 * s, -1 * s, 10 * s, 2 * s), Color(1, 1, 1, 0.8))
		"box":
			draw_rect(Rect2(-7 * s, -7 * s, 14 * s, 14 * s), color)
			draw_rect(Rect2(-7 * s, -7 * s, 14 * s, 14 * s), Color(1, 1, 1, 0.4), false, 1.5)
