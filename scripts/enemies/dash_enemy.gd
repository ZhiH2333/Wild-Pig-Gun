extends EnemyBase

## 冲刺型敌人：周期性向玩家冲刺，高血量
## 需求：11.2

const DASH_SPEED: float = 400.0
const DASH_COOLDOWN: float = 3.0
const DASH_DURATION: float = 0.4

var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0


func _ready() -> void:
	super._ready()
	max_hp = 60
	current_hp = 60
	move_speed = 60.0
	contact_damage = 15
	gold_reward = 2
	enemy_type_name = "冲刺"
	# 冷却从随机值开始，避免所有冲刺怪同时冲刺
	_cooldown_timer = randf_range(0.5, DASH_COOLDOWN)


func _get_move_velocity() -> Vector2:
	if _is_dashing:
		return _dash_direction * DASH_SPEED
	if target != null:
		return (target.global_position - global_position).normalized() * move_speed
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	_cooldown_timer -= delta
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
	elif _cooldown_timer <= 0.0 and target != null:
		_start_dash()
	super._physics_process(delta)
	queue_redraw()


func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_cooldown_timer = DASH_COOLDOWN
	_dash_direction = (target.global_position - global_position).normalized()


## 外观：橙色圆形 + 冲刺箭头 + 类型标签
func _draw() -> void:
	var body_color := Color(1.0, 0.8, 0.0) if _is_dashing else Color(0.9, 0.5, 0.1)
	# 身体（六边形感：用多边形模拟）
	var pts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6 - PI / 6
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	draw_colored_polygon(pts, body_color)
	# 冲刺方向箭头
	if _is_dashing:
		var tip := _dash_direction * 28.0
		draw_line(Vector2.ZERO, tip, Color(1, 1, 1, 0.9), 3.0)
		draw_circle(tip, 4.0, Color(1, 1, 1))
	# 眼睛（横向细长）
	draw_rect(Rect2(-9, -5, 7, 3), Color(1, 0.3, 0))
	draw_rect(Rect2(2, -5, 7, 3), Color(1, 0.3, 0))
	# debug 信息
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.7, 0.2))
	draw_string(font, Vector2(-22, 42), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.8, 0.6))
