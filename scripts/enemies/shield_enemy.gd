extends EnemyBase

## 护盾优先吸收伤害，破盾后本体较脆

var shield_hp: int = 45


func _ready() -> void:
	super._ready()
	max_hp = 28
	current_hp = 28
	move_speed = 62.0
	contact_damage = 9
	gold_reward = 2
	enemy_type_name = "护盾"


func take_damage(amount: int, is_crit: bool = false, damage_element: StringName = &"physical") -> void:
	if shield_hp > 0:
		var absorbed: int = mini(shield_hp, amount)
		shield_hp -= absorbed
		var rest: int = amount - absorbed
		if rest <= 0:
			GameAudio.play_hit_enemy()
			_play_hit_flash()
			return
		super.take_damage(rest, is_crit, damage_element)
		return
	super.take_damage(amount, is_crit, damage_element)


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed


func _draw() -> void:
	if shield_hp > 0:
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, Color(0.35, 0.75, 1.0, 0.95), 4.0, true)
	draw_circle(Vector2.ZERO, 16.0, Color(0.25, 0.45, 0.55))
	draw_circle(Vector2(-5, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(5, -3), 3.0, Color(1, 1, 1))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-26, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.7, 0.9, 1.0))
	draw_string(font, Vector2(-26, 46), "盾:%d HP:%d/%d" % [shield_hp, current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_HP, Color(0.75, 0.85, 0.95))
