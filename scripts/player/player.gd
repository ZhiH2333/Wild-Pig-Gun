extends CharacterBody2D

# 信号
signal hp_changed(current: int, maximum: int)
signal died

# 属性
const SPEED: float = 200.0
var max_hp: int = 100
var current_hp: int = 100
var is_invincible: bool = false

@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var coord_label: Label = $CoordLabel


func _physics_process(_delta: float) -> void:
	coord_label.text = "(%.0f, %.0f)" % [position.x, position.y]
	var direction := _get_input_direction()
	velocity = direction * SPEED
	move_and_slide()
	# 边界约束
	var arena_rect := _get_arena_rect()
	position = _apply_boundary_clamp(position, arena_rect)


## 读取 WASD 输入并返回归一化方向向量
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
	return dir


## 将位置限制在 Arena 矩形内（考虑碰撞体半径）
func _apply_boundary_clamp(pos: Vector2, arena_rect: Rect2) -> Vector2:
	pos.x = clamp(pos.x, arena_rect.position.x, arena_rect.position.x + arena_rect.size.x)
	pos.y = clamp(pos.y, arena_rect.position.y, arena_rect.position.y + arena_rect.size.y)
	return pos


## 返回 Arena 矩形；后续由 Arena 场景覆盖
func _get_arena_rect() -> Rect2:
	return Rect2(0.0, 0.0, 1920.0, 1080.0)


## 受到伤害（完整逻辑在任务 6.1 中实现）
func take_damage(_amount: int) -> void:
	pass


## Debug 占位绘制：粉色圆形代表野猪
func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.4, 0.5, 1.0))
	# 眼睛
	draw_circle(Vector2(-7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(-7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
	draw_circle(Vector2(7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
