extends Node2D

## 武器脚本：自动向最近敌人发射子弹（支持武器表 / 羁绊 / 材料转伤害）

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var weapon_id: String = "rifle"
var damage: int = 10
var _base_fire_interval: float = 0.5
var _pellet_count: int = 1
var _spread_deg: float = 0.0
var _pierce_extra: int = 0
var _damage_element: StringName = &"physical"

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	if not has_meta("catalog_applied"):
		setup_from_catalog(weapon_id)
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
	fire_timer.wait_time = _base_fire_interval / mult


func _effective_damage() -> int:
	var mult: float = 1.0
	var p: Node = _find_player()
	if p != null and "stat_damage_mult" in p:
		mult *= p.stat_damage_mult as float
	if p != null and "stat_synergy_damage_mult" in p:
		mult *= p.stat_synergy_damage_mult as float
	var mat_bonus: float = 1.0
	if p != null and "material_to_damage_kv" in p:
		var kv: float = float(p.material_to_damage_kv)
		if kv > 0.0001:
			mat_bonus += minf(0.45, float(RunState.material_current) * kv)
	return maxi(1, int(round(float(damage) * mult * mat_bonus)))


func _draw() -> void:
	draw_rect(Rect2(0, -4, 24, 8), Color(1.0, 0.85, 0.2, 1.0))


func find_nearest_enemy(enemies: Array, from_pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = INF
	for e in enemies:
		var d: float = from_pos.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest


func _on_fire_timer_timeout() -> void:
	_sync_fire_timer_wait()
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var target: Node2D = find_nearest_enemy(enemies, global_position)
	if target == null:
		return
	_fire(target)


func _fire(target: Node2D) -> void:
	var container: Node = _get_projectile_container()
	var base_dir: Vector2 = (target.global_position - global_position).normalized()
	var total_dmg: int = _effective_damage()
	var n: int = maxi(1, _pellet_count)
	var per_pellet: int = maxi(1, int(round(float(total_dmg) / float(n))))
	var half_spread: float = deg_to_rad(_spread_deg) * 0.5
	GameAudio.play_shoot()
	for i in range(n):
		var ang: float = 0.0
		if n > 1:
			var u: float = float(i) / float(n - 1)
			ang = lerpf(-half_spread, half_spread, u)
		var dir: Vector2 = base_dir.rotated(ang)
		_spawn_projectile(container, dir, per_pellet, _pierce_extra)


func _spawn_projectile(container: Node, dir: Vector2, dmg: int, pierce: int) -> void:
	var projectile: Node2D = projectile_scene.instantiate()
	projectile.direction = dir
	projectile.damage = dmg
	var proj: Projectile = projectile as Projectile
	if proj != null:
		proj.team = Projectile.TEAM_PLAYER
		proj.speed = Projectile.DEFAULT_SPEED
		proj.pierce_extra = pierce
		proj.damage_element = _damage_element
	container.add_child(projectile)
	projectile.global_position = global_position


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
