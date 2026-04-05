extends Node2D

## 武器脚本：自动向最近敌人发射子弹（支持武器表 / 羁绊 / 材料转伤害）

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var weapon_id: String = "rifle"
var damage: int = 10
var _base_fire_interval: float = 0.5

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
	var projectile: Node2D = projectile_scene.instantiate()
	var container: Node = _get_projectile_container()
	container.add_child(projectile)
	projectile.global_position = global_position
	var dir: Vector2 = (target.global_position - global_position).normalized()
	projectile.direction = dir
	projectile.damage = _effective_damage()


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
