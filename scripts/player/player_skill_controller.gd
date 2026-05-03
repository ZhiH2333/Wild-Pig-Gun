extends Node
class_name PlayerSkillController

## 角色技能：冷却、主动释放、被动查询（数据来自 CharacterSkillCatalog）

var _player: CharacterBody2D
var _cooldowns: Array[float] = []
var _active_defs: Array[Dictionary] = []
var _arena_cache: WeakRef


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_refresh_defs()
	if RunState != null and not RunState.run_started.is_connected(_on_run_started):
		RunState.run_started.connect(_on_run_started)


func _on_run_started(_cid: String) -> void:
	_refresh_defs()


func sync_from_run_state() -> void:
	_refresh_defs()


func _refresh_defs() -> void:
	_active_defs = CharacterSkillCatalog.active_defs_sorted(RunState.character_id if RunState != null else "default")
	_cooldowns.clear()
	for _i in range(maxi(3, _active_defs.size())):
		_cooldowns.append(0.0)


func _get_arena() -> Node:
	var ar: Variant = _arena_cache.get_ref() if _arena_cache != null else null
	if ar != null and is_instance_valid(ar):
		return ar as Node
	var a: Node = get_tree().get_first_node_in_group("arena")
	if a != null:
		_arena_cache = weakref(a)
	return a


func try_activate_slot(slot_index: int) -> bool:
	if _player == null:
		return false
	if RunState != null and RunState.pause_reason != RunState.PauseReason.NONE:
		return false
	if _player.shop_medkit_cast_left > 0.0001:
		return false
	if slot_index < 0 or slot_index >= _active_defs.size():
		return false
	if slot_index >= _cooldowns.size():
		return false
	if _cooldowns[slot_index] > 0.0001:
		return false
	var def: Dictionary = _active_defs[slot_index]
	var impl_id: String = str(def.get("implementation_id", ""))
	var cd: float = float(def.get("cooldown", 6.0))
	var arena: Node = _get_arena()
	var ok: bool = CharacterSkillImpl.try_active(impl_id, _player, arena, self)
	if ok:
		_cooldowns[slot_index] = maxf(0.01, cd)
		if RunState != null:
			RunState.emit_hud_sync_signals()
	return ok


func tick_cooldowns(delta: float) -> void:
	for i in range(_cooldowns.size()):
		if _cooldowns[i] > 0.0:
			var prev: float = _cooldowns[i]
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
			if prev > 0.0001 and _cooldowns[i] <= 0.0001:
				if RunState != null:
					RunState.emit_hud_sync_signals()


func tick_ph_storm(delta: float) -> void:
	var arena: Node = _get_arena()
	CharacterSkillImpl.process_ph_storm(_player, arena, delta)


func process_skill_charge(delta: float) -> bool:
	if _player == null:
		return false
	var left: float = float(_player.get_meta("_skill_charge_left", 0.0))
	if left <= 0.0001:
		return false
	if _player.shop_medkit_cast_left > 0.0001:
		return false
	left -= delta
	var vel: Vector2 = _player.get_meta("_skill_charge_vel", Vector2.ZERO) as Vector2
	_player.velocity = vel
	_player.move_and_slide()
	_player.set_meta("_skill_charge_left", left)
	if left <= 0.0001:
		_player.remove_meta("_skill_charge_left")
		if _player.has_meta("_skill_charge_vel"):
			_player.remove_meta("_skill_charge_vel")
		if _player.has_meta("_skill_charge_need_hit"):
			_player.remove_meta("_skill_charge_need_hit")
	return true


func modify_incoming_damage(amount: int) -> int:
	return CharacterSkillImpl.modify_incoming_damage(_player, amount)


func get_outgoing_damage_mult() -> float:
	return CharacterSkillImpl.get_outgoing_damage_mult(_player)


func get_passive_crit_chance_bonus() -> float:
	return CharacterSkillImpl.get_passive_crit_chance_bonus(_player)


func get_passive_attack_range_bonus() -> float:
	return CharacterSkillImpl.get_passive_attack_range_bonus(_player)


func get_save_state() -> Dictionary:
	var vel: Vector2 = Vector2.ZERO
	if _player != null and _player.has_meta("_skill_charge_vel"):
		vel = _player.get_meta("_skill_charge_vel") as Vector2
	return {
		"cooldowns": _cooldowns.duplicate(),
		"pc_pig_form": bool(_player.get_meta("pc_pig_form", true)) if _player != null else true,
		"ph_storm_left": float(_player.get_meta("_ph_storm_left", 0.0)) if _player != null else 0.0,
		"skill_charge_left": float(_player.get_meta("_skill_charge_left", 0.0)) if _player != null else 0.0,
		"skill_charge_vel_x": vel.x,
		"skill_charge_vel_y": vel.y,
	}


func apply_save_state(d: Dictionary) -> void:
	if d.is_empty():
		return
	var cds: Variant = d.get("cooldowns", [])
	if cds is Array:
		var arr: Array = cds as Array
		for i in range(arr.size()):
			while i >= _cooldowns.size():
				_cooldowns.append(0.0)
			_cooldowns[i] = maxf(0.0, float(arr[i]))
	if _player == null:
		return
	_player.set_meta("pc_pig_form", bool(d.get("pc_pig_form", true)))
	var storm_l: float = float(d.get("ph_storm_left", 0.0))
	if storm_l > 0.0001:
		_player.set_meta("_ph_storm_left", storm_l)
		_player.is_invincible = true
	else:
		if _player.has_meta("_ph_storm_left"):
			_player.remove_meta("_ph_storm_left")
	var sch: float = float(d.get("skill_charge_left", 0.0))
	if sch > 0.0001:
		_player.set_meta("_skill_charge_left", sch)
		_player.set_meta(
			"_skill_charge_vel",
			Vector2(float(d.get("skill_charge_vel_x", 0.0)), float(d.get("skill_charge_vel_y", 0.0)))
		)


func get_slot_cooldown_ratio(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= _active_defs.size():
		return 0.0
	if slot_index >= _cooldowns.size():
		return 0.0
	var cd_max: float = float(_active_defs[slot_index].get("cooldown", 6.0))
	if cd_max <= 0.0001:
		return 0.0
	return clampf(_cooldowns[slot_index] / cd_max, 0.0, 1.0)


func get_active_defs() -> Array[Dictionary]:
	return _active_defs


func get_cooldown_remaining(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= _cooldowns.size():
		return 0.0
	return maxf(0.0, _cooldowns[slot_index])
