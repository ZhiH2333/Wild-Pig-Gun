extends Node2D

## 近战武器：周期性对范围内敌人造成伤害（风险：需贴近怪群）

var weapon_id: String = "hammer"
var weapon_level: int = 1
var damage: int = 16
var _base_fire_interval: float = 0.55
var melee_radius: float = 78.0

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	if not has_meta("catalog_applied"):
		setup_from_catalog(weapon_id)
	_sync_wait()


func setup_from_catalog(wid: String) -> void:
	weapon_id = wid
	var def: Dictionary = WeaponCatalog.find_def(wid)
	damage = int(def.get("damage", 16))
	_base_fire_interval = float(def.get("fire_interval", 0.55))
	melee_radius = float(def.get("melee_radius", 78.0))
	set_meta("catalog_applied", true)
	if fire_timer != null:
		_sync_wait()


func upgrade_weapon() -> void:
	weapon_level += 1
	damage = int(round(float(damage) * 1.15))
	_base_fire_interval = maxf(0.1, _base_fire_interval * 0.9)
	if fire_timer != null:
		_sync_wait()


func _find_player() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n is CharacterBody2D and n.is_in_group("player"):
			return n
		n = n.get_parent()
	return null


func _sync_wait() -> void:
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


func _melee_strike() -> void:
	_sync_wait()
	var amt: int = _effective_damage()
	var p: Node = _find_player()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == null or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= melee_radius:
			if e.has_method("take_damage"):
				var fd: int = amt
				var ic: bool = false
				if p != null and "stat_crit_chance" in p and "stat_crit_mult" in p:
					var roll: Dictionary = CombatMath.roll_damage_with_crit(
						amt,
						float(p.stat_crit_chance),
						float(p.stat_crit_mult)
					)
					fd = int(roll["damage"])
					ic = bool(roll["is_crit"])
				e.take_damage(fd, ic)


func _on_fire_timer_timeout() -> void:
	_melee_strike()


func _draw() -> void:
	draw_arc(Vector2.ZERO, melee_radius * 0.35, 0.0, PI, 12, Color(0.9, 0.55, 0.2, 0.85), 5.0, true)
	draw_circle(Vector2(18, 0), 8.0, Color(0.75, 0.75, 0.8))
