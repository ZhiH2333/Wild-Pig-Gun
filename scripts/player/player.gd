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
## 构筑加成（升级/商店）
var stat_damage_mult: float = 1.0
var stat_move_speed_mult: float = 1.0
var stat_fire_rate_mult: float = 1.0
var stat_pickup_radius_bonus: float = 0.0
## 每波结束额外材料系数（收获 Harvest）
var stat_harvest: float = 0.0
## 影响商店高 tier 权重
var stat_luck: int = 0
## 角色词条：商店标价倍率（>1 更贵）
var shop_price_mult: float = 1.0
## 材料转伤害系数（节俭者-like：材料越多武器伤害越高）
var material_to_damage_kv: float = 0.0
## 同标签武器 ≥2 时的全局伤害乘数（由 WeaponLoadout 重算）
var stat_synergy_damage_mult: float = 1.0
## 当前帧的操作描述（供调试覆盖层读取）
var _debug_action: String = "待机"

@onready var invincibility_timer: Timer = $InvincibilityTimer


func _ready() -> void:
	add_to_group("player")
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	# 初始化时发出血量信号，让 HUD 同步初始值
	emit_signal("hp_changed", current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	velocity = direction * SPEED * stat_move_speed_mult
	move_and_slide()
	# 边界约束（需求 1.4）
	var arena_rect := _get_arena_rect()
	position = _apply_boundary_clamp(position, arena_rect)
	# 记录当前操作供调试覆盖层读取
	if direction == Vector2.ZERO:
		_debug_action = "待机"
	elif is_invincible:
		_debug_action = "移动中(无敌帧)"
	else:
		_debug_action = "移动 dir:(%.2f,%.2f)" % [direction.x, direction.y]
	queue_redraw()


## 读取 WASD / 虚拟摇杆并返回归一化方向向量（需求 1.1、1.2、1.3）
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length_squared() > 0.001:
		return dir.normalized()
	var vj: Node = get_tree().get_first_node_in_group("virtual_joystick")
	if vj != null and vj.has_method("get_output"):
		var joy: Vector2 = vj.get_output() as Vector2
		if joy.length_squared() > 0.001:
			return joy
	return Vector2.ZERO


## 将位置限制在 Arena 矩形内（需求 1.4）
func _apply_boundary_clamp(pos: Vector2, arena_rect: Rect2) -> Vector2:
	pos.x = clamp(pos.x, arena_rect.position.x, arena_rect.position.x + arena_rect.size.x)
	pos.y = clamp(pos.y, arena_rect.position.y, arena_rect.position.y + arena_rect.size.y)
	return pos


func add_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp += amount
	emit_signal("hp_changed", current_hp, max_hp)


func heal_flat(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)


func get_pickup_collect_radius() -> float:
	return 12.0 + stat_pickup_radius_bonus


func recompute_weapon_synergy() -> void:
	var loadout: Node = get_node_or_null("WeaponLoadout")
	if loadout == null:
		stat_synergy_damage_mult = 1.0
		return
	var counts: Dictionary = {}
	for c in loadout.get_children():
		if not ("weapon_id" in c):
			continue
		var wid: String = str(c.weapon_id)
		if wid.is_empty():
			continue
		for t in WeaponCatalog.tags_for(wid):
			counts[t] = int(counts.get(t, 0)) + 1
	var m: float = 1.0
	for k in counts.keys():
		if int(counts[k]) >= 2:
			m *= 1.1
	stat_synergy_damage_mult = m


## 受到伤害（需求 4.2、4.3、4.4）
func take_damage(amount: int) -> void:
	# 无敌帧期间忽略所有伤害（需求 4.3）
	if is_invincible:
		_debug_action = "受伤免疫(无敌帧)"
		return
	# 扣血，不低于 0（需求 4.2）
	current_hp = max(0, current_hp - amount)
	_debug_action = "受伤 -%d → HP:%d" % [amount, current_hp]
	emit_signal("hp_changed", current_hp, max_hp)
	# 血量归零时触发死亡（需求 4.4）
	if current_hp <= 0:
		_debug_action = "死亡"
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


## Debug 绘制：粉色圆形代表野猪，下方显示坐标与血量
func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.9, 0.4, 0.5, 1.0))
	draw_circle(Vector2(-7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(7, -6), 4.0, Color(1, 1, 1, 1))
	draw_circle(Vector2(-7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
	draw_circle(Vector2(7, -6), 2.0, Color(0.1, 0.1, 0.1, 1))
	# 角色下方调试信息
	var font := ThemeDB.fallback_font
	var font_size := 12
	var pos_text := "坐标:(%.0f,%.0f)" % [global_position.x, global_position.y]
	var hp_text  := "HP:%d/%d%s" % [current_hp, max_hp, " [无敌]" if is_invincible else ""]
	draw_string(font, Vector2(-40, 32), pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 0))
	draw_string(font, Vector2(-40, 46), hp_text,  HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.4, 1, 0.4))
