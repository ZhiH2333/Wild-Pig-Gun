extends EnemyBase

## 树（特殊敌人）：不移动不攻击，必掉回血果子，15% 概率掉绿箱子
## 需求：11.2

func _ready() -> void:
	super._ready()
	max_hp = 50
	current_hp = 50
	move_speed = 0.0
	contact_damage = 0
	gold_reward = 1
	drop_heal_chance = 1.0
	drop_box_chance = 0.15
	enemy_type_name = "树"


func _get_move_velocity() -> Vector2:
	return Vector2.ZERO   # 不移动


## 树不移动，需要手动触发重绘
func _process(_delta: float) -> void:
	queue_redraw()


## 外观：绿色树形 + 类型标签
func _draw() -> void:
	# 树干
	draw_rect(Rect2(-5, 8, 10, 14), Color(0.45, 0.28, 0.08))
	# 三层树冠（由下到上渐小）
	draw_circle(Vector2(0, 4), 18.0, Color(0.12, 0.55, 0.12))
	draw_circle(Vector2(0, -6), 14.0, Color(0.15, 0.65, 0.15))
	draw_circle(Vector2(0, -16), 9.0, Color(0.2, 0.75, 0.2))
	# 血量条（树不移动，血条更重要）
	var bar_w := 40.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, 26, bar_w, 4), Color(0.2, 0.1, 0.0))
	draw_rect(Rect2(-bar_w / 2, 26, bar_w * hp_ratio, 4), Color(0.2, 0.9, 0.2))
	# debug 信息
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-20, 36), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.3, 1.0, 0.3))
	draw_string(font, Vector2(-20, 52), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_HP, Color(0.5, 0.9, 0.5))
