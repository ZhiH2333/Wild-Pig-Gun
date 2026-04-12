extends EnemyBase

## 精英敌人：多形态切换，血量低于 50% 或超时 20 秒触发形态切换
## 死亡时掉落红箱子（全血 + 最高等级道具）
## 需求：11.2

signal phase_changed(old_phase: int, new_phase: int)

const PHASE_HP_THRESHOLD: float = 0.5   # 血量低于 50% 触发形态切换
const PHASE_TIMEOUT: float = 20.0       # 超过 20 秒未切换则强制切换

var current_phase: int = 1
var max_phases: int = 2
var _phase_timer: float = 0.0


func _ready() -> void:
	super._ready()
	max_hp = 200
	current_hp = 200
	move_speed = 70.0
	contact_damage = 20
	armor = 0.2
	gold_reward = 10
	drop_heal_chance = 0.0
	drop_box_chance = 0.0
	enemy_type_name = "精英"


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized() * move_speed


func _physics_process(delta: float) -> void:
	if current_phase < max_phases:
		_phase_timer += delta
		_check_phase_transition()
	super._physics_process(delta)
	queue_redraw()


func _check_phase_transition() -> void:
	var hp_ratio := float(current_hp) / float(max_hp)
	if hp_ratio < PHASE_HP_THRESHOLD or _phase_timer >= PHASE_TIMEOUT:
		_switch_phase()


func _switch_phase() -> void:
	var old_phase := current_phase
	current_phase += 1
	_phase_timer = 0.0
	# 形态切换：提升速度和伤害
	move_speed *= 1.5
	contact_damage = int(contact_damage * 1.3)
	armor = minf(armor + 0.1, 0.5)
	phase_changed.emit(old_phase, current_phase)


## 覆盖死亡处理：掉落红箱子
func _on_death() -> void:
	_spawn_red_box()
	died.emit(self)
	queue_free()


## 生成红箱子（全血 + 最高等级道具，占位实现）
func _spawn_red_box() -> void:
	pass


## 外观：金色/红色大星形 + 皇冠 + 类型标签
func _draw() -> void:
	# 星形（5角）
	var star_pts := PackedVector2Array()
	for i in 10:
		var a := i * TAU / 10 - PI / 2
		var r := 28.0 if i % 2 == 0 else 13.0
		star_pts.append(Vector2(cos(a), sin(a)) * r)
	var star_color := Color(1.0, 0.2, 0.1) if current_phase > 1 else Color(0.95, 0.75, 0.0)
	draw_colored_polygon(star_pts, star_color)
	# 皇冠（三角形组合）
	var crown_color := Color(1, 1, 0.3)
	draw_colored_polygon(PackedVector2Array([Vector2(-14,-28),Vector2(-10,-20),Vector2(-6,-28)]), crown_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-4,-30),Vector2(0,-22),Vector2(4,-30)]), crown_color)
	draw_colored_polygon(PackedVector2Array([Vector2(6,-28),Vector2(10,-20),Vector2(14,-28)]), crown_color)
	# 血量条
	var bar_w := 50.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, 32, bar_w, 5), Color(0.3, 0.0, 0.0))
	draw_rect(Rect2(-bar_w / 2, 32, bar_w * hp_ratio, 5), Color(1.0, 0.2, 0.2))
	# debug 信息
	var font := ThemeDB.fallback_font
	var label := "[%s] P%d" % [enemy_type_name, current_phase]
	draw_string(font, Vector2(-28, 44), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.9, 0.2))
	draw_string(font, Vector2(-28, 56), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.7, 0.3))
