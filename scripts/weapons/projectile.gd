extends Area2D
class_name Projectile

## 子弹：直线/榴弹弧；按阵营命中；支持 weapon_id 驱动拖尾与链电等表现

const ENEMY_BULLET_TEXTURE: Texture2D = preload("res://assets/sprites/enemy_bullets.png")
const CHAIN_LIGHTNING_SCRIPT: Script = preload("res://scripts/fx/chain_lightning_fx.gd")
const MAGNETIC_RING_SCRIPT: Script = preload("res://scripts/fx/magnetic_pulse_ring.gd")
const GRENADE_BURST_SCRIPT: Script = preload("res://scripts/fx/grenade_explosion_fx.gd")

const TEAM_PLAYER: StringName = &"player"
const TEAM_ENEMY: StringName = &"enemy"
const DEFAULT_SPEED: float = 400.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var team: StringName = TEAM_PLAYER
var speed: float = DEFAULT_SPEED
var pierce_extra: int = 0
var _hits_remaining: int = 1
var _damaged_ids: Dictionary = {}
var damage_element: StringName = &"physical"
## 发射源武器 id（用于拖尾、链电、榴弹等）
var source_weapon_id: String = ""

var _fx: Dictionary = {}
var _trail_seg_count: int = 0
var _chain_done: bool = false
var _grenade_flight: float = 0.0
var _grenade_bounces: int = 0
var _grenade_vel: Vector2 = Vector2.ZERO
var _grenade_exploded: bool = false
var _arc_phase: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if team == TEAM_PLAYER:
		_hits_remaining = 1 + maxi(0, pierce_extra)
		_fx = WeaponFxProfiles.profile(source_weapon_id)
		if bool(_fx.get("grenade_arc", false)):
			_grenade_vel = direction.normalized() * speed + Vector2(0.0, -260.0)
			_arc_phase = 0.0
	else:
		_hits_remaining = 1
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	_setup_visual()
	if team == TEAM_PLAYER and bool(_fx.get("magnetic_ring", false)):
		_spawn_magnetic_ring_at(global_position)


func _setup_visual() -> void:
	if _sprite == null:
		return
	if team == TEAM_ENEMY:
		_sprite.texture = ENEMY_BULLET_TEXTURE
		var th: float = float(ENEMY_BULLET_TEXTURE.get_height())
		var target_h: float = 34.0
		_sprite.scale = Vector2.ONE * (target_h / maxf(1.0, th))
		_sprite.rotation = direction.angle()
	else:
		_sprite.texture = null


func _arena_layer() -> Node2D:
	var a: Node = get_tree().get_first_node_in_group("arena")
	return a as Node2D


func _spawn_magnetic_ring_at(world_pos: Vector2) -> void:
	var layer: Node2D = _arena_layer()
	if layer == null:
		return
	var ring: Node2D = Node2D.new()
	ring.set_script(MAGNETIC_RING_SCRIPT)
	layer.add_child(ring)
	ring.global_position = world_pos
	ring.z_index = 3


func _physics_process(delta: float) -> void:
	if team == TEAM_PLAYER:
		if source_weapon_id == "boar_grenade" and bool(_fx.get("grenade_arc", false)):
			_physics_grenade(delta)
		else:
			position += direction * speed * delta
		_push_trail()
		_despawn_if_beyond_player_attack_range()
	else:
		position += direction * speed * delta


func _physics_grenade(delta: float) -> void:
	if _grenade_exploded:
		return
	_grenade_flight += delta
	_arc_phase += delta * 7.0
	position += _grenade_vel * delta
	_grenade_vel += Vector2(0.0, 520.0) * delta
	_grenade_vel += direction.orthogonal().normalized() * cos(_arc_phase) * 28.0 * delta
	if global_position.y > 1040.0 and _grenade_bounces < 2:
		global_position.y = 1040.0
		_grenade_vel.y = -absf(_grenade_vel.y) * 0.55
		_grenade_bounces += 1
	if _grenade_flight > 1.15:
		_grenade_explode_at_position()


func _push_trail() -> void:
	_trail_seg_count = int(_fx.get("trail_segments", 5))
	queue_redraw()


func _despawn_if_beyond_player_attack_range() -> void:
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl == null or not pl.has_method("get_attack_range_radius"):
		return
	var lim: float = float(pl.call("get_attack_range_radius"))
	var pl2d: Node2D = pl as Node2D
	if pl2d == null:
		return
	if global_position.distance_squared_to(pl2d.global_position) > lim * lim:
		queue_free()


func _element_color() -> Color:
	var c: Color = Color(1, 1, 0.4, 1.0)
	if damage_element == &"fire":
		c = Color(1.0, 0.45, 0.12, 1.0)
	elif damage_element == &"ice":
		c = Color(0.55, 0.85, 1.0, 1.0)
	elif damage_element == &"poison":
		c = Color(0.45, 0.95, 0.35, 1.0)
	elif damage_element == &"shock":
		c = Color(0.55, 0.78, 1.0, 1.0)
	return c


func _draw() -> void:
	if team == TEAM_ENEMY:
		return
	var tw: float = float(_fx.get("trail_width", 0.0))
	var tc: Color = _fx.get("trail_color", Color(1, 1, 1, 0)) as Color
	var dir: Vector2 = direction.normalized()
	if tw > 0.0001 and _trail_seg_count >= 2:
		for i in range(_trail_seg_count - 1):
			var t0: float = float(i) / float(_trail_seg_count - 1)
			var t1: float = float(i + 1) / float(_trail_seg_count - 1)
			var p0: Vector2 = -dir * lerpf(4.0, 38.0, t0)
			var p1: Vector2 = -dir * lerpf(4.0, 38.0, t1)
			var col: Color = tc
			col.a *= t0 * 0.92
			draw_line(p0, p1, col, tw * (0.5 + 0.5 * t0), true)
	var c: Color = _element_color()
	var cs: float = float(_fx.get("core_scale", 1.0))
	var gs: float = float(_fx.get("glow_scale", 1.0))
	if bool(_fx.get("snow_sparkle", false)):
		for j in range(3):
			var ang: float = float(j) / 3.0 * TAU + float(Engine.get_process_frames()) * 0.08
			draw_circle(Vector2.from_angle(ang) * 7.0, 1.6, Color(1, 1, 1, 0.55))
	draw_circle(Vector2.ZERO, 5.0 * gs, Color(c.r, c.g, c.b, 0.28))
	draw_circle(Vector2.ZERO, 5.0 * cs, c)


func _on_body_entered(body: Node2D) -> void:
	if team == TEAM_PLAYER:
		if not body.is_in_group("enemies"):
			return
		if source_weapon_id == "boar_grenade":
			_grenade_explode_at_position()
			return
		var bid: int = body.get_instance_id()
		if _damaged_ids.has(bid):
			return
		_damaged_ids[bid] = true
		if source_weapon_id == "magnetic_cannon" and body.has_method("apply_magnetic_pull"):
			body.call("apply_magnetic_pull", global_position, 52.0)
		if body.has_method("take_damage"):
			_apply_player_hit_damage_and_status(body)
		if source_weapon_id == "electric_gun" and bool(_fx.get("chain_lightning", false)) and not _chain_done:
			_chain_done = true
			_spawn_chain_lightning(body)
		_hits_remaining -= 1
		if _hits_remaining <= 0:
			queue_free()
		return
	if team == TEAM_ENEMY:
		if not body.is_in_group("player"):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


func _apply_player_hit_damage_and_status(body: Node2D) -> void:
	var dmg_base: int = damage
	var pl: Node = get_tree().get_first_node_in_group("player")
	if damage_element == &"fire" and pl != null and "stat_fire_damage_mult" in pl:
		dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_fire_damage_mult))))
	elif damage_element == &"ice" and pl != null and "stat_ice_damage_mult" in pl:
		dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_ice_damage_mult))))
	elif damage_element == &"poison" and pl != null and "stat_poison_damage_mult" in pl:
		dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_poison_damage_mult))))
	elif damage_element == &"shock" and pl != null and "stat_shock_damage_mult" in pl:
		dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_shock_damage_mult))))
	var final_dmg: int = dmg_base
	var is_crit: bool = false
	if pl != null and "stat_crit_chance" in pl and "stat_crit_mult" in pl:
		var roll: Dictionary = CombatMath.roll_damage_with_crit(
			dmg_base,
			float(pl.stat_crit_chance),
			float(pl.stat_crit_mult)
		)
		final_dmg = int(roll["damage"])
		is_crit = bool(roll["is_crit"])
	body.take_damage(final_dmg, is_crit, damage_element)
	if damage_element == &"fire" and body.has_method("apply_status_burn"):
		var pl2: Node = get_tree().get_first_node_in_group("player")
		var bdps: float = 2.0
		if pl2 != null and "stat_burn_dps_flat" in pl2:
			bdps += float(pl2.stat_burn_dps_flat)
		body.call("apply_status_burn", bdps, 3.2)
	elif damage_element == &"ice":
		if source_weapon_id == "frost_sprayer" and body.has_method("apply_ice_stack"):
			body.call("apply_ice_stack", 0.68, 2.6)
		elif body.has_method("apply_status_slow"):
			var pl3: Node = get_tree().get_first_node_in_group("player")
			var dur: float = 2.6
			if pl3 != null and "stat_ice_duration_bonus" in pl3:
				dur += float(pl3.stat_ice_duration_bonus)
			body.call("apply_status_slow", 0.68, dur)
	elif damage_element == &"poison" and body.has_method("apply_status_poison"):
		var pl4: Node = get_tree().get_first_node_in_group("player")
		var pdps: float = 1.1
		var pdur: float = 4.0
		if pl4 != null:
			if "stat_poison_dps_flat" in pl4:
				pdps += float(pl4.stat_poison_dps_flat)
			if "stat_poison_duration_pct" in pl4:
				pdur *= 1.0 + float(pl4.stat_poison_duration_pct)
		body.call("apply_status_poison", pdps, pdur)
	elif damage_element == &"shock" and body.has_method("apply_status_shock_vuln"):
		var pl5: Node = get_tree().get_first_node_in_group("player")
		var sv: float = 0.14
		if pl5 != null and "stat_shock_vuln_apply_flat" in pl5:
			sv += float(pl5.stat_shock_vuln_apply_flat)
		body.call("apply_status_shock_vuln", sv, 4.5)


func _spawn_chain_lightning(first_body: Node2D) -> void:
	var pl: Node = get_tree().get_first_node_in_group("player")
	var origin: Vector2 = first_body.global_position
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(origin)
	var used: Dictionary = {first_body.get_instance_id(): true}
	var prev: Node2D = first_body
	var mults: Array[float] = [0.62, 0.42, 0.28]
	for k in range(3):
		var best: Node2D = null
		var best_d: float = 1e12
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == null or not is_instance_valid(e) or not e is Node2D:
				continue
			var e2: Node2D = e as Node2D
			if used.has(e2.get_instance_id()):
				continue
			var d: float = prev.global_position.distance_squared_to(e2.global_position)
			if d < best_d and d < 220.0 * 220.0:
				best_d = d
				best = e2
		if best == null:
			break
		used[best.get_instance_id()] = true
		pts.append(best.global_position)
		var ch_dmg: int = maxi(1, int(round(float(damage) * mults[k])))
		if best.has_method("take_damage"):
			var ic: bool = false
			if pl != null and "stat_crit_chance" in pl and "stat_crit_mult" in pl:
				var roll: Dictionary = CombatMath.roll_damage_with_crit(
					ch_dmg,
					float(pl.stat_crit_chance),
					float(pl.stat_crit_mult)
				)
				ch_dmg = int(roll["damage"])
				ic = bool(roll["is_crit"])
			best.take_damage(ch_dmg, ic, damage_element)
		if damage_element == &"shock" and best.has_method("apply_status_shock_vuln"):
			var sv: float = 0.12
			if pl != null and "stat_shock_vuln_apply_flat" in pl:
				sv += float(pl.stat_shock_vuln_apply_flat)
			best.call("apply_status_shock_vuln", sv, 3.2)
		prev = best
	if pts.size() < 2:
		return
	var layer: Node2D = _arena_layer()
	if layer == null:
		return
	var fx: Node2D = Node2D.new()
	fx.set_script(CHAIN_LIGHTNING_SCRIPT)
	if fx.has_method("setup_world_points"):
		fx.call("setup_world_points", pts)
	layer.add_child(fx)
	fx.global_position = Vector2.ZERO
	fx.z_index = 9


func _grenade_explode_at_position() -> void:
	if _grenade_exploded:
		return
	_grenade_exploded = true
	var layer2: Node2D = _arena_layer()
	if layer2 != null:
		var burst: Node2D = Node2D.new()
		layer2.add_child(burst)
		burst.set_script(GRENADE_BURST_SCRIPT)
		burst.global_position = global_position
		burst.z_index = 6
	var r: float = 118.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == null or not is_instance_valid(e) or not e is Node2D:
			continue
		var e2: Node2D = e as Node2D
		if e2.global_position.distance_squared_to(global_position) <= r * r:
			if e2.has_method("take_damage"):
				var aoe: int = maxi(1, int(round(float(damage) * 0.92)))
				e2.take_damage(aoe, false, damage_element)
	queue_free()


func _on_screen_exited() -> void:
	queue_free()
