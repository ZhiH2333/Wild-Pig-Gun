extends EnemyBase

## 关卡 Boss：多阶段召唤小怪

var _boss_phase: int = 0


func _ready() -> void:
	super._ready()
	max_hp = 720
	current_hp = 720
	move_speed = 38.0
	contact_damage = 22
	gold_reward = 80
	enemy_type_name = "Boss"
	add_to_group("boss")


func take_damage(amount: int, is_crit: bool = false, damage_element: StringName = &"physical") -> void:
	var prev_hp: int = current_hp
	super.take_damage(amount, is_crit, damage_element)
	if current_hp <= 0 or prev_hp <= 0:
		return
	var ratio: float = float(current_hp) / float(maxi(1, max_hp))
	if _boss_phase == 0 and ratio < 0.68:
		_boss_phase = 1
		_summon_minion_ring(6)
	elif _boss_phase == 1 and ratio < 0.36:
		_boss_phase = 2
		_summon_minion_ring(10)


func _summon_minion_ring(count: int) -> void:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena == null or not arena.has_method("spawn_enemy_at"):
		return
	for i in range(count):
		var ang: float = (TAU / float(count)) * float(i)
		var off: Vector2 = Vector2(cos(ang), sin(ang)) * 140.0
		arena.call("spawn_enemy_at", "basic", global_position + off)


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed


func _draw() -> void:
	var pulse: float = 1.0 + 0.06 * sin(float(Time.get_ticks_msec()) * 0.004)
	draw_circle(Vector2.ZERO, 36.0 * pulse, Color(0.55, 0.08, 0.12))
	draw_circle(Vector2.ZERO, 28.0, Color(0.15, 0.02, 0.04))
	draw_rect(Rect2(-14, -10, 10, 6), Color(1, 0.85, 0.2))
	draw_rect(Rect2(4, -10, 10, 6), Color(1, 0.85, 0.2))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, -48), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.4, 0.35))
	draw_string(font, Vector2(-40, -28), "HP:%d/%d  P:%d" % [current_hp, max_hp, _boss_phase],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.8, 0.75))
