extends RefCounted
class_name CharacterSkillImpl

## 角色技能实现（implementation_id）；纯静态，由 PlayerSkillController 调用


static func _apply_stun(enemy: Node, duration_sec: float) -> void:
	if enemy.has_method("apply_skill_stun"):
		enemy.call("apply_skill_stun", duration_sec)
	elif enemy.has_method("apply_shop_emp_stun"):
		enemy.call("apply_shop_emp_stun", duration_sec)


static func try_active(impl_id: String, player: CharacterBody2D, arena: Node, ctrl: Node) -> bool:
	match impl_id:
		"boar_wild_charge":
			return _boar_charge(player, arena)
		"boar_stomp":
			return _boar_stomp(player, arena)
		"pc_transform_toggle":
			return _pc_transform(player)
		"pc_crow_cry":
			return _pc_crow(player, arena)
		"pc_combo_burst":
			return _pc_combo(player, arena)
		"ph_feather_fan":
			return _ph_feathers(player, arena)
		"ph_blood_dash":
			return _ph_dash(player, arena)
		"ph_feather_storm":
			return _ph_storm(player, arena)
	return false


static func _arena_rect(arena: Node) -> Rect2:
	if arena != null and arena.has_method("get_arena_rect"):
		return arena.get_arena_rect() as Rect2
	return Rect2(0, 0, 1920, 1080)


static func _damage_sample(player: Node) -> int:
	var dm: float = 1.0
	if "stat_damage_mult" in player:
		dm = float(player.stat_damage_mult)
	return maxi(8, int(round(dm * 14.0)))


static func _aoe_damage(player: Node, arena: Node, radius: float, inner_damage: int) -> void:
	var ppos: Vector2 = player.global_position
	for n in player.get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and n.has_method("take_damage"):
			var e: Node2D = n as Node2D
			if e.global_position.distance_squared_to(ppos) <= radius * radius:
				e.take_damage(inner_damage, false, &"physical")


static func _boar_charge(player: CharacterBody2D, arena: Node) -> bool:
	var dir: Vector2 = Vector2.RIGHT
	if player.has_method("_get_input_direction"):
		dir = player._get_input_direction()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	player.set_meta("_skill_charge_vel", dir * 920.0)
	player.set_meta("_skill_charge_left", 0.26)
	player.set_meta("_skill_charge_need_hit", true)
	_push_enemies(player, 140.0, 260.0)
	return true


static func _push_enemies(player: CharacterBody2D, radius: float, impulse: float) -> void:
	var ppos: Vector2 = player.global_position
	for n in player.get_tree().get_nodes_in_group("enemies"):
		if n is CharacterBody2D:
			var e: CharacterBody2D = n as CharacterBody2D
			var d: Vector2 = e.global_position - ppos
			if d.length_squared() > radius * radius:
				continue
			var away: Vector2 = d.normalized() if d.length_squared() > 0.01 else Vector2.RIGHT
			e.velocity += away * impulse


static func _boar_stomp(player: CharacterBody2D, arena: Node) -> bool:
	var dmg: int = _damage_sample(player) + 18
	_aoe_damage(player, arena, 220.0, dmg)
	for n in player.get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			var e2: Node2D = n as Node2D
			if e2.global_position.distance_squared_to(player.global_position) <= 220.0 * 220.0:
				_apply_stun(n, 1.5)
	return true


static func _pc_transform(player: CharacterBody2D) -> bool:
	var pig: bool = not bool(player.get_meta("pc_pig_form", true))
	player.set_meta("pc_pig_form", pig)
	player.shop_wind_burst_left = maxf(player.shop_wind_burst_left, 1.0)
	_aoe_damage(player, null, 100.0, maxi(4, _damage_sample(player) / 5))
	return true


static func _pc_crow(player: CharacterBody2D, arena: Node) -> bool:
	player.heal_flat(8)
	for n in player.get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			var e: Node2D = n as Node2D
			if e.global_position.distance_squared_to(player.global_position) <= 320.0 * 320.0:
				_apply_stun(n, 1.0)
	return true


static func _pc_combo(player: CharacterBody2D, arena: Node) -> bool:
	var dmg: int = _damage_sample(player)
	for _i in range(3):
		_aoe_damage(player, arena, 160.0 + float(_i) * 24.0, dmg / 2)
	return true


static func _ph_feathers(player: CharacterBody2D, arena: Node) -> bool:
	_aoe_damage(player, arena, 320.0, maxi(8, _damage_sample(player) / 2))
	return true


static func _ph_dash(player: CharacterBody2D, arena: Node) -> bool:
	var dir: Vector2 = Vector2.RIGHT
	if player.has_method("_get_input_direction"):
		dir = player._get_input_direction()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	player.set_meta("_skill_charge_vel", dir * 880.0)
	player.set_meta("_skill_charge_left", 0.22)
	return true


static func _ph_storm(player: CharacterBody2D, arena: Node) -> bool:
	player.is_invincible = true
	player.set_meta("_ph_storm_left", 3.0)
	player.set_meta("_ph_storm_tick", 0.0)
	return true


static func process_ph_storm(player: CharacterBody2D, arena: Node, delta: float) -> void:
	var left: float = float(player.get_meta("_ph_storm_left", 0.0))
	if left <= 0.0001:
		return
	left -= delta
	player.set_meta("_ph_storm_left", left)
	var tick: float = float(player.get_meta("_ph_storm_tick", 0.0)) + delta
	if tick >= 0.35:
		tick = 0.0
		_aoe_damage(player, arena, 200.0, maxi(5, _damage_sample(player) / 3))
	player.set_meta("_ph_storm_tick", tick)
	if left <= 0.0001:
		player.is_invincible = false


static func modify_incoming_damage(player: Node, amount: int) -> int:
	if RunState == null:
		return amount
	var cid: String = RunState.character_id
	var amt: int = amount
	if cid == "chicken" and randf() < 0.07:
		return 0
	if cid == "default":
		var hp_ratio: float = float(player.current_hp) / maxf(1.0, float(player.max_hp))
		if hp_ratio > 0.55:
			amt = maxi(1, int(ceil(float(amt) * 0.9)))
	if "stat_thorns_reflect_pct" in player and float(player.stat_thorns_reflect_pct) > 0.0001:
		_thorns_reflect(player, amt, float(player.stat_thorns_reflect_pct))
	return amt


static func _thorns_reflect(player: Node, incoming: int, pct: float) -> void:
	var bounce: int = maxi(1, int(round(float(incoming) * pct)))
	var best: Node2D = null
	var best_d: float = 1e12
	for n in player.get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and n.has_method("take_damage"):
			var e2: Node2D = n as Node2D
			var dd: float = e2.global_position.distance_squared_to(player.global_position)
			if dd < best_d and dd < 220.0 * 220.0:
				best_d = dd
				best = e2
	if best != null:
		best.take_damage(bounce, false, &"physical")


static func get_outgoing_damage_mult(player: Node) -> float:
	if RunState == null:
		return 1.0
	var m: float = 1.0
	var cid: String = RunState.character_id
	var hp_ratio: float = float(player.current_hp) / maxf(1.0, float(player.max_hp))
	if cid == "default" and hp_ratio < 0.38:
		m *= 1.18
	if cid == "pigchicken" and _loadout_melee_and_gun(player):
		m *= 1.12
	return m


static func _loadout_melee_and_gun(player: Node) -> bool:
	var lo: Node = player.get_node_or_null("WeaponLoadout")
	if lo == null:
		return false
	var has_melee: bool = false
	var has_proj: bool = false
	for c in lo.get_children():
		if not ("weapon_id" in c):
			continue
		var def: Dictionary = WeaponCatalog.find_def(str(c.weapon_id))
		var kind: String = str(def.get("kind", ""))
		if kind == "melee":
			has_melee = true
		elif kind == "projectile":
			has_proj = true
	return has_melee and has_proj


static func get_passive_crit_chance_bonus(player: Node) -> float:
	if RunState == null or RunState.character_id != "pigchicken":
		return 0.0
	if not _loadout_melee_and_gun(player):
		return 0.0
	if bool(player.get_meta("pc_pig_form", true)):
		return 0.0
	return 0.06


static func get_passive_attack_range_bonus(player: Node) -> float:
	if RunState == null or RunState.character_id != "chicken":
		return 0.0
	return 24.0


static func on_enemy_killed_passives(player: Node) -> void:
	if RunState == null or RunState.character_id != "default":
		return
	var roll: int = 1 + RunState.wave_index / 4
	player.heal_flat(mini(roll, 4))
