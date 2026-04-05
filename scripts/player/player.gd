extends CharacterBody2D

## 玩家角色脚本（野猪）
## 需求：1.1、1.2、1.3、1.4、1.5、4.1、4.2、4.3、4.4

# 信号
signal hp_changed(current: int, maximum: int)
signal died
signal synergy_changed(multiplier: float, tags: Array)

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
## 每秒生命回复（构筑）
var stat_hp_regen_per_sec: float = 0.0
## 暴击率 0~1、暴击伤害倍率
var stat_crit_chance: float = 0.05
var stat_crit_mult: float = 1.5
## 当前帧的操作描述（供调试覆盖层读取）
var _debug_action: String = "待机"
var _walk_sfx_cooldown: float = 0.0
var _hp_regen_accum: float = 0.0

@onready var invincibility_timer: Timer = $InvincibilityTimer


func _ready() -> void:
	add_to_group("player")
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	# 初始化时发出血量信号，让 HUD 同步初始值
	emit_signal("hp_changed", current_hp, max_hp)


func _physics_process(delta: float) -> void:
	var direction := _get_input_direction()
	velocity = direction * SPEED * stat_move_speed_mult
	move_and_slide()
	if direction.length_squared() > 0.001:
		_walk_sfx_cooldown -= delta
		if _walk_sfx_cooldown <= 0.0:
			GameAudio.play_walk()
			_walk_sfx_cooldown = 0.38
	else:
		_walk_sfx_cooldown = 0.0
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
	_apply_hp_regen(delta)


## 每秒生命回复结算
func _apply_hp_regen(delta: float) -> void:
	if stat_hp_regen_per_sec <= 0.0001:
		_hp_regen_accum = 0.0
		return
	if current_hp >= max_hp:
		return
	_hp_regen_accum += stat_hp_regen_per_sec * delta
	if _hp_regen_accum < 1.0:
		return
	var heal_amt: int = mini(floori(_hp_regen_accum), max_hp - current_hp)
	if heal_amt <= 0:
		return
	heal_flat(heal_amt)
	_hp_regen_accum -= float(heal_amt)


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


func penalties_max_hp(amount: int) -> void:
	var loss: int = maxi(0, amount)
	if loss <= 0:
		return
	max_hp = maxi(1, max_hp - loss)
	current_hp = mini(current_hp, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)


func heal_flat(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)


func get_pickup_collect_radius() -> float:
	return 12.0 + stat_pickup_radius_bonus


func apply_run_snapshot_stats(d: Dictionary) -> void:
	max_hp = maxi(1, int(d.get("max_hp", 100)))
	current_hp = clampi(int(d.get("current_hp", max_hp)), 0, max_hp)
	stat_damage_mult = maxf(0.05, float(d.get("stat_damage_mult", 1.0)))
	stat_move_speed_mult = maxf(0.05, float(d.get("stat_move_speed_mult", 1.0)))
	stat_fire_rate_mult = maxf(0.05, float(d.get("stat_fire_rate_mult", 1.0)))
	stat_pickup_radius_bonus = float(d.get("stat_pickup_radius_bonus", 0.0))
	stat_harvest = maxf(0.0, float(d.get("stat_harvest", 0.0)))
	stat_luck = int(d.get("stat_luck", 0))
	shop_price_mult = maxf(0.01, float(d.get("shop_price_mult", 1.0)))
	material_to_damage_kv = maxf(0.0, float(d.get("material_to_damage_kv", 0.0)))
	stat_synergy_damage_mult = maxf(0.05, float(d.get("stat_synergy_damage_mult", 1.0)))
	stat_hp_regen_per_sec = maxf(0.0, float(d.get("stat_hp_regen_per_sec", 0.0)))
	stat_crit_chance = clampf(float(d.get("stat_crit_chance", 0.05)), 0.0, 1.0)
	stat_crit_mult = maxf(1.0, float(d.get("stat_crit_mult", 1.5)))
	global_position = Vector2(float(d.get("pos_x", 960.0)), float(d.get("pos_y", 540.0)))
	emit_signal("hp_changed", current_hp, max_hp)


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
	var active_tags: Array[String] = []
	for k in counts.keys():
		if int(counts[k]) >= 2:
			active_tags.append(str(k))
	var m: float = 1.0
	for _i in range(active_tags.size()):
		m *= 1.1
	var prev: float = stat_synergy_damage_mult
	stat_synergy_damage_mult = m
	if absf(m - prev) > 0.0001 and active_tags.size() > 0:
		emit_signal("synergy_changed", m, active_tags)


## 受到伤害（需求 4.2、4.3、4.4）
func take_damage(amount: int) -> void:
	# 无敌帧期间忽略所有伤害（需求 4.3）
	if is_invincible:
		_debug_action = "受伤免疫(无敌帧)"
		return
	var amt: int = amount
	if RunState != null:
		amt = maxi(1, int(round(float(amount) * RunState.run_risk_mult)))
	GameAudio.play_hurt_player()
	# 扣血，不低于 0（需求 4.2）
	current_hp = max(0, current_hp - amt)
	_brief_screen_shake()
	_debug_action = "受伤 -%d → HP:%d" % [amt, current_hp]
	emit_signal("hp_changed", current_hp, max_hp)
	# 血量归零时触发死亡（需求 4.4）
	if current_hp <= 0:
		_debug_action = "死亡"
		emit_signal("died")
		return
	# 触发无敌帧
	is_invincible = true
	invincibility_timer.start()


func _brief_screen_shake() -> void:
	var cam: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var tw: Tween = create_tween()
	cam.offset = Vector2(7, -5)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "offset", Vector2(-4, 4), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.09)


## 无敌帧结束
func _on_invincibility_timer_timeout() -> void:
	is_invincible = false


## 返回 Arena 矩形；优先从 Arena 节点获取
func _get_arena_rect() -> Rect2:
	var arenas := get_tree().get_nodes_in_group("arena")
	if arenas.size() > 0 and arenas[0].has_method("get_arena_rect"):
		return arenas[0].get_arena_rect()
	return Rect2(0.0, 0.0, 1920.0, 1080.0)


