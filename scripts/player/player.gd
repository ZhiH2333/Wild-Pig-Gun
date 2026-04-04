extends CharacterBody2D

## 玩家角色脚本（野猪）
## 需求：1.1、1.2、1.3、1.4、1.5、4.1、4.2、4.3、4.4

# 信号
signal hp_changed(current: int, maximum: int)
signal died

# 属性
const SPEED: float = 200.0
var max_hp: int = 100
var current_hp: int = 100
var is_invincible: bool = false

@onready var invincibility_timer: Timer = $InvincibilityTimer


func _ready() -> void:
	add_to_group("player")
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	# 初始化时发出血量信号，让 HUD 同步初始值
	emit_signal("hp_changed", current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	velocity = direction * SPEED
	move_and_slide()
	# 边界约束（需求 1.4）
	var arena_rect := _get_arena_rect()
	position = _apply_boundary_clamp(position, arena_rect)
	queue_redraw()


## 读取 WASD 输入并返回归一化方向向量（需求 1.1、1.2、1.3）
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
	return dir


## 将位置限制在 Arena 矩形内（需求 1.4）
func _apply_boundary_clamp(pos: Vector2, arena_rect: Rect2) -> Vector2:
	pos.x = clamp(pos.x, arena_rect.position.x, arena_rect.position.x + arena_rect.size.x)
	pos.y = clamp(pos.y, arena_rect.position.y, arena_rect.position.y + arena_rect.size.y)
	return pos


## 受到伤害（需求 4.2、4.3、4.4）
func take_damage(amount: int) -> void:
	# 无敌帧期间忽略所有伤害（需求 4.3）
	if is_invincible:
		return
	# 扣血，不低于 0（需求 4.2）
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp, max_hp)
	# 血量归零时触发死亡（需求 4.4）
	if current_hp <= 0:
		emit_signal("died")
		return
	# 触发无敌帧
	is_invincible = true
	invincibility_timer.start()


## 无敌帧结束
func _on_invincibility_timer_timeout() -> void:
	is_invincible = false


## 返回 Arena 矩形；优先从 Arena 节点获取
func _get_arena_rect() -> Rect2:
	var arenas := get_tree().get_nodes_in_group("arena")
	if arenas.size() > 0 and arenas[0].has_method("get_arena_rect"):
		return arenas[0].get_arena_rect()
	return Rect2(0.0, 0.0, 1920.0, 1080.0)


## Debug 绘制：粉色圆形代表野猪
func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.4, 0.5, 1.0))
	draw_circle(Vector2(-7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(-7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
	draw_circle(Vector2(7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
