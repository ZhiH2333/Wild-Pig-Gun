extends Node2D

## 武器脚本：自动发射子弹；多枪/多发时按距离优先把不同弹丸分给不同敌人（支持武器表 / 羁绊 / 材料转伤害）

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var weapon_id: String = "crude_pistol"
var weapon_level: int = 1
var damage: int = 10
var _base_fire_interval: float = 0.5
var _pellet_count: int = 1
var _spread_deg: float = 0.0
var _pierce_extra: int = 0
var _damage_element: StringName = &"physical"
var _revolver_rounds_left: int = 6
var _reload_time_left: float = 0.0
var _virt_clip: int = 10
var _shop_volley: int = 0

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	if not has_meta("catalog_applied"):
		setup_from_catalog(weapon_id)
	else:
		set_physics_process(weapon_id == "spin_revolver")
		set_process(weapon_id == "feather_bow")
	_sync_fire_timer_wait()


func setup_from_catalog(wid: String) -> void:
	weapon_id = wid
	var def: Dictionary = WeaponCatalog.find_def(wid)
	damage = int(def.get("damage", 10))
	_base_fire_interval = float(def.get("fire_interval", 0.5))
	_pellet_count = maxi(1, int(def.get("pellet_count", 1)))
	_spread_deg = maxf(0.0, float(def.get("spread_deg", 0.0)))
	_pierce_extra = maxi(0, int(def.get("pierce", 0)))
	var elem: String = str(def.get("element", "physical"))
	_damage_element = StringName(elem)
	set_meta("catalog_applied", true)
	if wid == "spin_revolver":
		_revolver_rounds_left = 6
		_reload_time_left = 0.0
		_virt_clip = 6
	else:
		_virt_clip = 10
	set_physics_process(wid == "spin_revolver")
	set_process(wid == "feather_bow")
	if fire_timer != null:
		_sync_fire_timer_wait()


func upgrade_weapon() -> void:
	weapon_level += 1
	damage = int(round(float(damage) * 1.15))
	_base_fire_interval = maxf(0.1, _base_fire_interval * 0.9)
	if fire_timer != null:
		_sync_fire_timer_wait()


func _find_player() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n is CharacterBody2D and n.is_in_group("player"):
			return n
		n = n.get_parent()
	return null


func _sync_fire_timer_wait() -> void:
	if fire_timer == null:
		return
	var mult: float = 1.0
	var p: Node = _find_player()
	if p != null and "stat_fire_rate_mult" in p:
		mult = maxf(0.2, p.stat_fire_rate_mult as float)
	if p != null and p.has_method("get_shop_fire_stim_mult"):
		mult *= maxf(0.15, p.get_shop_fire_stim_mult() as float)
	var bless_r: float = 1.0
	if RunState != null and RunState.ammo_blessing.has(weapon_id):
		var bd: Dictionary = RunState.ammo_blessing[weapon_id] as Dictionary
		bless_r = float(bd.get("reload", 1.0))
	fire_timer.wait_time = _base_fire_interval / mult / maxf(0.2, bless_r)


func _effective_damage() -> int:
	var mult: float = 1.0
	var p: Node = _find_player()
	if p != null and "stat_damage_mult" in p:
		mult *= p.stat_damage_mult as float
	if p != null and "stat_synergy_damage_mult" in p:
		mult *= p.stat_synergy_damage_mult as float
	if p != null and p.has_method("get_shop_damage_stim_mult"):
		mult *= p.get_shop_damage_stim_mult() as float
	if p != null and p.has_method("get_skill_outgoing_damage_mult"):
		mult *= float(p.call("get_skill_outgoing_damage_mult"))
	var mat_bonus: float = 1.0
	if p != null and "material_to_damage_kv" in p:
		var kv: float = float(p.material_to_damage_kv)
		if kv > 0.0001:
			mat_bonus += minf(0.45, float(RunState.material_current) * kv)
	var flat: int = 0
	if p != null and "stat_damage_flat" in p:
		flat = int(p.stat_damage_flat)
	return maxi(1, int(round(float(damage) * mult * mat_bonus)) + flat)


func _process(_delta: float) -> void:
	if weapon_id == "feather_bow":
		queue_redraw()


func _physics_process(delta: float) -> void:
	if weapon_id != "spin_revolver":
		return
	if _reload_time_left > 0.0:
		_reload_time_left = maxf(0.0, _reload_time_left - delta)
		queue_redraw()
		if _reload_time_left <= 0.0001 and fire_timer != null and fire_timer.is_stopped():
			_revolver_rounds_left = 6
			fire_timer.start()


func _draw() -> void:
	draw_rect(Rect2(0, -4, 24, 8), Color(1.0, 0.85, 0.2, 1.0))
	if weapon_id == "feather_bow" and fire_timer != null:
		var tw: float = fire_timer.wait_time
		var left: float = fire_timer.time_left
		if tw > 0.001 and left <= minf(0.2, tw * 0.28) and left > 0.0:
			var g: float = 1.0 - left / minf(0.2, tw * 0.28)
			draw_arc(Vector2(14, 0), 16.0 + g * 10.0, -0.9, 0.9, 16, Color(0.35, 1.0, 0.55, 0.35 + g * 0.45), 2.8, false)
	if weapon_id == "spin_revolver" and _reload_time_left > 0.0:
		var sp: float = _reload_time_left * 14.0
		for i in range(6):
			var a: float = float(i) / 6.0 * TAU + sp
			var p: Vector2 = Vector2.from_angle(a) * 20.0
			draw_line(Vector2(12, 0) + p * 0.2, Vector2(12, 0) + p, Color(1.0, 0.92, 0.45, 0.75), 2.2, true)


func _collect_enemies_sorted_by_distance(from_pos: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			result.append(n as Node2D)
	result.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return from_pos.distance_squared_to(a.global_position) < from_pos.distance_squared_to(b.global_position)
	)
	return result


## 本武器在 WeaponLoadout 中「投射物武器」里的序号（0=最近敌人优先槽，1=次近…）
func _projectile_weapon_slot() -> int:
	var lo: Node = get_parent()
	if lo == null:
		return 0
	var idx: int = 0
	for c in lo.get_children():
		if c == self:
			return idx
		if not ("weapon_id" in c):
			continue
		var def: Dictionary = WeaponCatalog.find_def(str(c.weapon_id))
		if str(def.get("kind", "projectile")) != "projectile":
			continue
		idx += 1
	return idx


func _on_fire_timer_timeout() -> void:
	_sync_fire_timer_wait()
	if weapon_id == "spin_revolver":
		if _reload_time_left > 0.0:
			return
		if _revolver_rounds_left <= 0:
			_begin_spin_revolver_reload()
			return
		var tri_cost: int = 3 if _run_has_trident() else 1
		if _revolver_rounds_left < tri_cost:
			_begin_spin_revolver_reload()
			return
		_revolver_rounds_left -= tri_cost
		_shop_volley += tri_cost
	else:
		if _run_has_trident():
			_shop_volley += 3
		else:
			_shop_volley += 1
	var sorted_enemies: Array[Node2D] = _collect_enemies_sorted_by_distance(global_position)
	if sorted_enemies.is_empty():
		return
	_fire_distributed(sorted_enemies)


func _run_has_trident() -> bool:
	return RunState != null and RunState.has_shop_item("shop_trident_evolution")


func _begin_spin_revolver_reload() -> void:
	_reload_time_left = 0.8
	if fire_timer != null:
		fire_timer.stop()
	queue_redraw()


func _fire_distributed(sorted_enemies: Array[Node2D]) -> void:
	if _run_has_trident():
		_fire_trident_burst(sorted_enemies)
		return
	var container: Node = _get_projectile_container()
	var total_dmg: int = _effective_damage()
	var n: int = maxi(1, _pellet_count)
	var mag_m: float = 1.0
	if RunState != null and RunState.ammo_blessing.has(weapon_id):
		var bd: Dictionary = RunState.ammo_blessing[weapon_id] as Dictionary
		mag_m = float(bd.get("mag", 1.0))
	n = maxi(1, int(round(float(n) * mag_m)))
	var per_pellet: int = maxi(1, int(round(float(total_dmg) / float(n))))
	var ec: int = sorted_enemies.size()
	var slot: int = _projectile_weapon_slot()
	var half_spread: float = deg_to_rad(_spread_deg) * 0.5
	GameAudio.play_shoot()
	var player_n: Node = _find_player()
	var first_dir: Vector2 = (sorted_enemies[0].global_position - global_position).normalized()
	if weapon_id == "sniper_chicken" and player_n != null:
		WeaponCameraFx.sniper_hitstop_fire_and_forget(player_n)
		_spawn_sniper_laser_line(sorted_enemies[0])
	WeaponMuzzleFx.spawn_for_shot(self, weapon_id, first_dir)
	if ec == 1:
		var base_dir: Vector2 = (sorted_enemies[0].global_position - global_position).normalized()
		for i in range(n):
			var ang: float = 0.0
			if n > 1:
				var u: float = float(i) / float(n - 1)
				ang = lerpf(-half_spread, half_spread, u)
			_spawn_projectile(container, base_dir.rotated(ang), per_pellet, _pierce_extra, _skull_flags())
		return
	for i in range(n):
		var ei: int = (slot + i) % ec
		var target: Node2D = sorted_enemies[ei]
		var base_dir: Vector2 = (target.global_position - global_position).normalized()
		_spawn_projectile(container, base_dir, per_pellet, _pierce_extra, _skull_flags())


func _fire_trident_burst(sorted_enemies: Array[Node2D]) -> void:
	if sorted_enemies.is_empty():
		return
	var container: Node = _get_projectile_container()
	var total_dmg: int = _effective_damage()
	var trip: int = maxi(1, int(round(float(total_dmg) * 0.6)))
	GameAudio.play_shoot()
	var player_n: Node = _find_player()
	var half_fan: float = deg_to_rad(22.0)
	var target: Node2D = sorted_enemies[0]
	var base_dir: Vector2 = (target.global_position - global_position).normalized()
	if weapon_id == "sniper_chicken" and player_n != null:
		WeaponCameraFx.sniper_hitstop_fire_and_forget(player_n)
		_spawn_sniper_laser_line(target)
	WeaponMuzzleFx.spawn_for_shot(self, weapon_id, base_dir)
	for k in range(3):
		var ang: float = lerpf(-half_fan, half_fan, float(k) / 2.0)
		_spawn_projectile(container, base_dir.rotated(ang), trip, _pierce_extra, _skull_flags())


func _effective_virt_clip() -> int:
	var base_v: int = _virt_clip
	var mag_m: float = 1.0
	if RunState != null and RunState.ammo_blessing.has(weapon_id):
		var bd: Dictionary = RunState.ammo_blessing[weapon_id] as Dictionary
		mag_m = float(bd.get("mag", 1.0))
	return maxi(1, int(round(float(base_v) * mag_m)))


func _skull_flags() -> Dictionary:
	var clip_i: int = _effective_virt_clip()
	var skull: bool = (
		RunState != null
		and RunState.has_shop_item("shop_skull_mag")
		and _shop_volley > 0
		and (_shop_volley % clip_i) == 0
	)
	return {"skull": skull}


func _spawn_projectile(container: Node, dir: Vector2, dmg: int, pierce: int, skull: Dictionary = {}) -> void:
	var projectile: Node2D = ProjectilePool.get_projectile(projectile_scene) as Node2D
	if projectile == null:
		return
	projectile.direction = dir
	projectile.damage = dmg
	var proj: Projectile = projectile as Projectile
	if proj != null:
		proj.team = Projectile.TEAM_PLAYER
		proj.speed = Projectile.DEFAULT_SPEED
		proj.pierce_extra = pierce
		proj.damage_element = _damage_element
		proj.source_weapon_id = weapon_id
		if RunState != null:
			if RunState.has_shop_item("shop_ghost_bullet"):
				proj.shop_ghost_mode = true
			if RunState.has_shop_item("shop_tornado_barrel"):
				proj.shop_spiral = true
			if RunState.has_shop_item("shop_wave_core"):
				proj.shop_knockback_on_hit = true
			if RunState.has_shop_item("shop_boomerang_mod"):
				proj.shop_boomerang = true
		if bool(skull.get("skull", false)):
			proj.force_skull_special = true
	container.add_child(projectile)
	projectile.global_position = global_position


func _spawn_sniper_laser_line(target: Node2D) -> void:
	if target == null:
		return
	var arena: Node2D = get_tree().get_first_node_in_group("arena") as Node2D
	if arena == null:
		return
	var ln: Line2D = Line2D.new()
	ln.set_script(preload("res://scripts/fx/sniper_laser_fx.gd"))
	ln.z_index = 24
	ln.global_position = Vector2.ZERO
	ln.points = PackedVector2Array([global_position, target.global_position])
	arena.add_child(ln)


func _get_projectile_container() -> Node:
	var root: Node = get_tree().get_root()
	var arena: Node = root.get_node_or_null("Arena")
	if arena:
		var container: Node = arena.get_node_or_null("ProjectileContainer")
		if container:
			return container
	var found: Node = root.find_child("ProjectileContainer", true, false)
	if found:
		return found
	return get_tree().current_scene
