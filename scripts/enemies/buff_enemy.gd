extends EnemyBase

## E3 类：图腾周围敌人移速/伤害提升（自身加入 buff_totem 组供距离检测）


func _ready() -> void:
	super._ready()
	add_to_group("buff_totem")
	max_hp = 38
	current_hp = 38
	move_speed = 42.0
	contact_damage = 5
	gold_reward = 3
	enemy_type_name = "强化图腾"


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed * 0.35


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.2, 0.55, 0.95, 0.9))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color(0.4, 0.85, 1.0, 0.5), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-28, 34), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.7, 0.9, 1.0))
