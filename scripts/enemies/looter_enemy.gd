extends EnemyBase

## 宝藏怪：随机游走，不攻击，15 秒后逃跑，必掉绿箱子
## 需求：11.2

signal escaped

const ESCAPE_TIME: float = 15.0
const WANDER_SPEED: float = 120.0

var _escape_timer: float = 0.0
var _wander_direction: Vector2 = Vector2.RIGHT
var _wander_change_timer: float = 0.0


func _ready() -> void:
	super._ready()
	max_hp = 80
	current_hp = 80
	move_speed = WANDER_SPEED
	contact_damage = 0
	gold_reward = 0
	drop_heal_chance = 0.0
	drop_box_chance = 1.0
	enemy_type_name = "宝藏"
	# 随机初始游走方向
	_wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
	_wander_change_timer = randf_range(0.5, 1.5)


func _get_move_velocity() -> Vector2:
	return _wander_direction * WANDER_SPEED


func _physics_process(delta: float) -> void:
	_escape_timer += delta
	_wander_change_timer -= delta

	# 随机改变游走方向
	if _wander_change_timer <= 0.0:
		_wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
		_wander_change_timer = randf_range(0.5, 1.5)

	# 超时逃跑
	if _escape_timer >= ESCAPE_TIME:
		escaped.emit()
		queue_free()
		return

	super._physics_process(delta)
	queue_redraw()


## 外观：青色圆形 + 钱袋 + 逃跑倒计时 + 类型标签
func _draw() -> void:
	# 身体（圆润）
	draw_circle(Vector2.ZERO, 18.0, Color(0.0, 0.75, 0.75))
	# 钱袋（黄色圆 + 绑带）
	draw_circle(Vector2(0, -4), 9.0, Color(1.0, 0.85, 0.1))
	draw_rect(Rect2(-3, 4, 6, 5), Color(0.6, 0.4, 0.0))
	# 逃跑倒计时进度环（用多段线模拟）
	var remaining := maxf(0.0, ESCAPE_TIME - _escape_timer)
	var ratio := remaining / ESCAPE_TIME
	var ring_pts := PackedVector2Array()
	var segments := 32
	for i in int(segments * ratio) + 1:
		var a := -PI / 2 + i * TAU / segments
		ring_pts.append(Vector2(cos(a), sin(a)) * 22.0)
	if ring_pts.size() > 1:
		var ring_color := Color(0.0, 1.0, 1.0) if ratio > 0.3 else Color(1.0, 0.3, 0.0)
		draw_polyline(ring_pts, ring_color, 2.5)
	# debug 信息
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.0, 1.0, 1.0))
	draw_string(font, Vector2(-22, 42), "逃:%.1fs" % remaining,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.6, 0.1))
