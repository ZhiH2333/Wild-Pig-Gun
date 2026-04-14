extends EnemyBase

## D 类：死亡分裂为两只普通怪


func _ready() -> void:
	super._ready()
	split_spawn_count = 2
	split_spawn_type = "basic"
	max_hp = 52
	current_hp = 52
	move_speed = 72.0
	contact_damage = 11
	gold_reward = 2
	enemy_type_name = "分裂野猪"


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed


func _draw() -> void:
	draw_circle(Vector2.ZERO, 19.0, Color(0.45, 0.75, 0.35))
	draw_circle(Vector2(-8, -8), 7.0, Color(0.55, 0.85, 0.4))
	draw_circle(Vector2(8, -8), 7.0, Color(0.55, 0.85, 0.4))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-26, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.7, 1.0, 0.65))
