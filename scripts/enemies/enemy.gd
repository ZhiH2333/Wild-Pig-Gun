extends CharacterBody2D

## 敌人脚本：追击玩家并造成接触伤害
## 需求：3.1、3.2

# 信号
signal died(enemy: Node2D)

# 属性
const SPEED: float = 80.0
var max_hp: int = 30
var current_hp: int = 30
var contact_damage: int = 10
var target: Node2D = null

## 当前帧操作描述（供调试覆盖层读取）
var _debug_action: String = "生成"


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")


func _physics_process(_delta: float) -> void:
	if target == null:
		_debug_action = "无目标"
		return
	var dir := _get_chase_direction()
	velocity = dir * SPEED
	move_and_slide()
	_debug_action = "追击 dir:(%.2f,%.2f)" % [dir.x, dir.y]
	queue_redraw()


## 返回指向 Player 的归一化方向向量，target 为 null 时返回 Vector2.ZERO
func _get_chase_direction() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized()


## 受到伤害，血量归零时发出 died 信号并销毁自身（完整逻辑在任务 6.4 中实现）
func take_damage(amount: int) -> void:
	current_hp -= amount
	_debug_action = "受伤 -%d → HP:%d" % [amount, max(0, current_hp)]
	if current_hp <= 0:
		current_hp = 0
		_debug_action = "死亡"
		died.emit(self)
		queue_free()


## Debug 绘制：深红色圆形，下方显示血量与坐标
func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color(0.7, 0.1, 0.1, 1.0))
	# 眼睛（白色）
	draw_circle(Vector2(-6, -5), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(6, -5), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(-6, -5), 2.0, Color(0.1, 0.1, 0.1, 1))
	draw_circle(Vector2(6, -5), 2.0, Color(0.1, 0.1, 0.1, 1))
	# 敌人下方调试信息
	var font := ThemeDB.fallback_font
	var font_size := 11
	var hp_text  := "HP:%d/%d" % [current_hp, max_hp]
	var pos_text := "(%.0f,%.0f)" % [global_position.x, global_position.y]
	draw_string(font, Vector2(-30, 28), hp_text,  HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 0.5, 0.5))
	draw_string(font, Vector2(-30, 40), pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 0.8, 0.4))
