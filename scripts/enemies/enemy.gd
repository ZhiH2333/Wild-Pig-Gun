extends EnemyBase

## 普通追击型敌人：直线追击玩家
## 需求：3.1、3.2

func _ready() -> void:
	super._ready()
	enemy_type_name = "普通"


## 返回指向 Player 的归一化速度向量
func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed


## 外观：深红色圆形 + 獠牙 + 类型标签
func _draw() -> void:
	# 身体
	draw_circle(Vector2.ZERO, 18.0, Color(0.75, 0.12, 0.12))
	# 耳朵
	draw_circle(Vector2(-12, -14), 6.0, Color(0.75, 0.12, 0.12))
	draw_circle(Vector2(12, -14), 6.0, Color(0.75, 0.12, 0.12))
	# 眼睛
	draw_circle(Vector2(-6, -4), 4.0, Color(1, 1, 1))
	draw_circle(Vector2(6, -4), 4.0, Color(1, 1, 1))
	draw_circle(Vector2(-6, -4), 2.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(6, -4), 2.0, Color(0.1, 0.1, 0.1))
	# 獠牙
	var tusk_pts_l: PackedVector2Array = [Vector2(-8, 6), Vector2(-5, 14), Vector2(-2, 6)]
	var tusk_pts_r: PackedVector2Array = [Vector2(2, 6), Vector2(5, 14), Vector2(8, 6)]
	draw_colored_polygon(tusk_pts_l, Color(1, 0.95, 0.8))
	draw_colored_polygon(tusk_pts_r, Color(1, 0.95, 0.8))
	# debug 信息
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.5, 0.5))
	draw_string(font, Vector2(-22, 42), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.7, 0.7))
