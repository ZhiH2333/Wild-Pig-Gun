extends Node

signal run_started(character_id: String)

enum PauseReason {
	NONE,
	USER,
	INTERSTITIAL,
	LEVEL_UP,
}

# 信号
signal wave_changed(wave_index: int)
signal gold_changed(gold: int)
signal hp_changed(current: int, maximum: int)
signal material_changed(current: int, savings: int)  # 阶段二：材料变化
signal consumables_changed
signal xp_changed(level: int, xp: int, need: int)
signal level_up_queued(new_level: int)

# 局内状态
var character_id: String = "default"
var wave_index: int = 0
## 未使用：持久化野猪币见 SaveManager.get_wallet_gold()；局内消费只用 material_current
var gold: int = 0
## 本局开始时的系统滴答（毫秒），用于结算用时
var run_start_ticks_msec: int = 0
## 已计入存档槽 play_time 的本局秒数（避免重复累加）
var _session_play_banked_sec: float = 0.0
## 暂停来源：用户 ESC 与波间界面互斥
var pause_reason: PauseReason = PauseReason.NONE
var upgrade_ids: Array[String] = []
## 局内构筑时间线：波间三选一、商店购买、升级弹窗（用于结算界面展示）
var run_choice_log: Array = []
## 进入结算页面前由 Arena 写入：武器显示名与属性快照
var last_endgame_weapon_labels: PackedStringArray = PackedStringArray()
var last_endgame_stats: Dictionary = {}
var run_seed: int = 0

# 玩家血量（由 Player 节点自身管理，RunState 仅作镜像用于存档）
var player_max_hp: int = 100
var player_current_hp: int = 100

# 阶段二：材料（局内掉落野猪币等）
var material_current: int = 0   # 本波已拾取材料
var material_savings: int = 0   # 未拾取储蓄材料（下波拾取时翻倍）
var player_level: int = 1
var player_xp: int = 0
## 困难倍率：放大受击伤害并略增材料拾取（≥1）
var run_risk_mult: float = 1.0
## 设置页返回目标场景（默认主菜单）
var settings_return_scene_path: String = "res://scenes/main_menu.tscn"
## 角色图鉴返回目标场景（默认主菜单）
var gallery_return_scene_path: String = "res://scenes/main_menu.tscn"
## 由 first_screen 加载完成切换前置位：主菜单入场时从黑幕渐入一次
var pending_main_menu_entrance_fade_in: bool = false
## 开局武器选择覆盖（为空时按角色默认武器）
var selected_starting_weapon_ids: Array[String] = []
## 策划商店：已购买的武器改造（shop item id）
var shop_weapon_mods: Array[String] = []
## 消耗品：shop 条目 id -> 数量
var shop_consumables: Dictionary = {}
## 弹药祝福：武器 id -> { "mag": float, "reload": float }
var ammo_blessing: Dictionary = {}
var has_bone_armor: bool = false
var bone_armor_ready: bool = false
var has_stopwatch: bool = false
var stopwatch_ready: bool = false
var has_gold_magnet: bool = false
var has_wind_wings: bool = false
var has_melee_necklace: bool = false
var has_luck_hoof: bool = false
var has_master_key: bool = false
## 时停激活中（由 Arena 每帧处理敌人）
var stopwatch_frozen: bool = false
var stopwatch_frozen_time_left: float = 0.0
## 烟雾弹：敌人失去目标追踪、玩家移速在 Player 内处理
var shop_smoke_blind_left: float = 0.0

func _ready() -> void:
	_register_default_input_actions()


func consume_pending_main_menu_entrance_fade_in() -> bool:
	var was: bool = pending_main_menu_entrance_fade_in
	pending_main_menu_entrance_fade_in = false
	return was


func _process(delta: float) -> void:
	if shop_smoke_blind_left > 0.0001:
		shop_smoke_blind_left = maxf(0.0, shop_smoke_blind_left - delta)
	if stopwatch_frozen and stopwatch_frozen_time_left > 0.0001:
		stopwatch_frozen_time_left -= delta
		if stopwatch_frozen_time_left <= 0.0001:
			stopwatch_frozen = false
			stopwatch_frozen_time_left = 0.0

func begin_new_run(p_character_id: String = "default", risk_mult: float = 1.0) -> void:
	SaveManager.clear_pending_run()
	character_id = p_character_id
	run_risk_mult = clampf(risk_mult, 1.0, 1.5)
	wave_index = 0
	gold = 0
	upgrade_ids.clear()
	run_choice_log.clear()
	last_endgame_weapon_labels.clear()
	last_endgame_stats.clear()
	run_seed = randi()
	pause_reason = PauseReason.NONE
	get_tree().paused = false
	player_max_hp = 100
	player_current_hp = 100
	material_current = 0
	material_savings = 0
	player_level = 1
	player_xp = 0
	settings_return_scene_path = "res://scenes/main_menu.tscn"
	gallery_return_scene_path = "res://scenes/main_menu.tscn"
	selected_starting_weapon_ids.clear()
	_reset_shop_run_state()
	run_start_ticks_msec = Time.get_ticks_msec()
	reset_session_play_banking()
	run_started.emit(character_id)


func reset_session_play_banking() -> void:
	_session_play_banked_sec = 0.0


func _reset_shop_run_state() -> void:
	shop_weapon_mods.clear()
	shop_consumables.clear()
	emit_signal("consumables_changed")
	ammo_blessing.clear()
	has_bone_armor = false
	bone_armor_ready = false
	has_stopwatch = false
	stopwatch_ready = false
	has_gold_magnet = false
	has_wind_wings = false
	has_melee_necklace = false
	has_luck_hoof = false
	has_master_key = false
	stopwatch_frozen = false
	stopwatch_frozen_time_left = 0.0
	shop_smoke_blind_left = 0.0


func add_shop_weapon_mod(shop_item_id: String) -> void:
	if shop_item_id.is_empty():
		return
	if shop_item_id in shop_weapon_mods:
		return
	shop_weapon_mods.append(shop_item_id)


func has_shop_item(shop_item_id: String) -> bool:
	return shop_item_id in shop_weapon_mods


func add_consumable(shop_id: String, amount: int = 1) -> void:
	if shop_id.is_empty() or amount <= 0:
		return
	shop_consumables[shop_id] = int(shop_consumables.get(shop_id, 0)) + amount
	emit_signal("consumables_changed")


func get_consumable_count(shop_id: String) -> int:
	return int(shop_consumables.get(shop_id, 0))


func try_use_consumable(shop_id: String) -> bool:
	var c: int = get_consumable_count(shop_id)
	if c <= 0:
		return false
	shop_consumables[shop_id] = c - 1
	if shop_consumables[shop_id] <= 0:
		shop_consumables.erase(shop_id)
	emit_signal("consumables_changed")
	return true


func reset_wave_shop_flags() -> void:
	bone_armor_ready = has_bone_armor
	stopwatch_ready = has_stopwatch
	stopwatch_frozen = false
	stopwatch_frozen_time_left = 0.0


## 返回自上次存档以来新增的局内游玩秒数，并推进基准（用于写入槽位累计时间）
func consume_session_play_for_save() -> float:
	var e: float = get_run_elapsed_seconds()
	var delta: float = maxf(0.0, e - _session_play_banked_sec)
	_session_play_banked_sec = e
	return delta


func enter_interstitial_pause() -> void:
	pause_reason = PauseReason.INTERSTITIAL
	get_tree().paused = true


func leave_interstitial_pause() -> void:
	pause_reason = PauseReason.NONE
	get_tree().paused = false


func try_toggle_user_pause(arena: Node) -> void:
	if pause_reason == PauseReason.INTERSTITIAL:
		return
	if pause_reason == PauseReason.LEVEL_UP:
		return
	if pause_reason == PauseReason.USER:
		pause_reason = PauseReason.NONE
		get_tree().paused = false
		if arena != null and arena.has_method("hide_pause_overlay"):
			arena.hide_pause_overlay()
		GameMusic.finish_user_pause_resume()
	else:
		if not get_tree().paused:
			pause_reason = PauseReason.USER
			get_tree().paused = true
			if arena != null and arena.has_method("show_pause_overlay"):
				arena.show_pause_overlay()


func get_run_elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - run_start_ticks_msec) / 1000.0


## kind: wave_upgrade | shop | level_up；wave 为「第几波」语境（波间为刚结束的波次）
func append_run_choice(kind: String, wave: int, upgrade_id: String, title: String, player_level: int = -1) -> void:
	var entry: Dictionary = {
		"kind": kind,
		"wave": wave,
		"id": upgrade_id,
		"title": title,
	}
	if player_level >= 0:
		entry["player_level"] = player_level
	run_choice_log.append(entry)


## 切换至结算场景前调用，保存武器与属性供 UI 读取（玩家节点即将销毁）
func capture_endgame_from_player(player: Node) -> void:
	last_endgame_weapon_labels.clear()
	last_endgame_stats.clear()
	if player == null:
		return
	var lo: Node = player.get_node_or_null("WeaponLoadout")
	if lo != null:
		for c in lo.get_children():
			if "weapon_id" in c:
				var wid: String = str(c.weapon_id)
				var def: Dictionary = WeaponCatalog.find_def(wid)
				var disp: String = str(def.get("display_name", def.get("id", wid)))
				last_endgame_weapon_labels.append(disp)
	last_endgame_stats = {
		"max_hp": player.max_hp,
		"current_hp": player.current_hp,
		"stat_damage_flat": player.stat_damage_flat,
		"stat_melee_damage_mult": player.stat_melee_damage_mult,
		"stat_damage_mult": player.stat_damage_mult,
		"stat_move_speed_mult": player.stat_move_speed_mult,
		"stat_fire_rate_mult": player.stat_fire_rate_mult,
		"stat_pickup_radius_bonus": player.stat_pickup_radius_bonus,
		"stat_attack_range_bonus": player.stat_attack_range_bonus,
		"stat_harvest": player.stat_harvest,
		"stat_luck": player.stat_luck,
		"shop_price_mult": player.shop_price_mult,
		"material_to_damage_kv": player.material_to_damage_kv,
		"stat_synergy_damage_mult": player.stat_synergy_damage_mult,
		"stat_hp_regen_per_sec": player.stat_hp_regen_per_sec,
		"stat_crit_chance": player.stat_crit_chance,
		"stat_crit_mult": player.stat_crit_mult,
		"stat_fire_damage_mult": player.stat_fire_damage_mult,
		"stat_burn_dps_flat": player.stat_burn_dps_flat,
		"stat_ice_damage_mult": player.stat_ice_damage_mult,
		"stat_ice_duration_bonus": player.stat_ice_duration_bonus,
		"stat_poison_damage_mult": player.stat_poison_damage_mult,
		"stat_poison_dps_flat": player.stat_poison_dps_flat,
		"stat_poison_duration_pct": player.stat_poison_duration_pct,
		"stat_shock_damage_mult": player.stat_shock_damage_mult,
		"stat_shock_vuln_apply_flat": player.stat_shock_vuln_apply_flat,
		"stat_thorns_reflect_pct": player.stat_thorns_reflect_pct,
		"player_level": player_level,
		"player_xp": player_xp,
	}

func _register_default_input_actions() -> void:
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up", 0.2)
		InputMap.add_action("move_down", 0.2)
		InputMap.add_action("move_left", 0.2)
		InputMap.add_action("move_right", 0.2)
		InputMap.add_action("pause_game", 0.2)
		InputMap.add_action("confirm", 0.2)
		_add_key_to_action("move_up", [KEY_W, KEY_UP])
		_add_key_to_action("move_down", [KEY_S, KEY_DOWN])
		_add_key_to_action("move_left", [KEY_A, KEY_LEFT])
		_add_key_to_action("move_right", [KEY_D, KEY_RIGHT])
		_add_key_to_action("pause_game", [KEY_ESCAPE])
		_add_key_to_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_ensure_attack_range_preview_action()
	_ensure_skill_input_actions()


func _ensure_skill_input_actions() -> void:
	if not InputMap.has_action("skill"):
		InputMap.add_action("skill", 0.2)
		_add_key_to_action("skill", [KEY_Q])
	if not InputMap.has_action("skill_secondary"):
		InputMap.add_action("skill_secondary", 0.2)
		_add_key_to_action("skill_secondary", [KEY_E])
	if not InputMap.has_action("skill_tertiary"):
		InputMap.add_action("skill_tertiary", 0.2)
		_add_key_to_action("skill_tertiary", [KEY_R])


func _ensure_attack_range_preview_action() -> void:
	if InputMap.has_action("show_attack_range"):
		return
	InputMap.add_action("show_attack_range", 0.2)
	_add_key_to_action("show_attack_range", [KEY_R])

func _add_key_to_action(action_name: String, keycodes: Array) -> void:
	for keycode in keycodes:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = keycode as Key
		InputMap.action_add_event(action_name, ev)

# 阶段二：普通拾取材料
func collect_material(amount: int) -> void:
	var gain: float = float(amount)
	if run_risk_mult > 1.001:
		gain *= 1.0 + (run_risk_mult - 1.0) * 0.7
	material_current += maxi(1, int(round(gain)))
	emit_signal("material_changed", material_current, material_savings)

# 阶段二：波次结束时将未拾取材料转为储蓄
func on_wave_end_convert_savings(uncollected: int) -> void:
	material_savings += uncollected
	emit_signal("material_changed", material_current, material_savings)

# 阶段二：下波开始时拾取储蓄（翻倍）
func collect_savings() -> void:
	material_current += material_savings * 2
	material_savings = 0
	emit_signal("material_changed", material_current, material_savings)


func try_spend_material(cost: int) -> bool:
	if material_current < cost:
		return false
	material_current -= cost
	emit_signal("material_changed", material_current, material_savings)
	return true


## 将当前局内野猪币余额写入野猪钱包并清零（波间继续、通关/失败展示结算后调用）
func bank_run_material_to_wallet() -> void:
	var amt: int = material_current
	if amt <= 0:
		return
	SaveManager.bank_run_gold_to_wallet(amt)
	material_current = 0
	emit_signal("material_changed", material_current, material_savings)


func xp_to_next_level() -> int:
	return 22 + player_level * 16


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	player_xp += amount
	while true:
		var need: int = xp_to_next_level()
		if player_xp < need:
			break
		player_xp -= need
		player_level += 1
		level_up_queued.emit(player_level)
	emit_signal("xp_changed", player_level, player_xp, xp_to_next_level())


func enter_level_up_pause() -> void:
	pause_reason = PauseReason.LEVEL_UP
	get_tree().paused = true


func leave_level_up_pause() -> void:
	pause_reason = PauseReason.NONE
	get_tree().paused = false


func to_snapshot_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"wave_index": wave_index,
		"gold": gold,
		"run_start_ticks_msec": run_start_ticks_msec,
		"upgrade_ids": upgrade_ids.duplicate(),
		"run_choice_log": run_choice_log.duplicate(true),
		"run_seed": run_seed,
		"player_max_hp": player_max_hp,
		"player_current_hp": player_current_hp,
		"material_current": material_current,
		"material_savings": material_savings,
		"player_level": player_level,
		"player_xp": player_xp,
		"run_risk_mult": run_risk_mult,
		"shop_weapon_mods": shop_weapon_mods.duplicate(),
		"shop_consumables": shop_consumables.duplicate(true),
		"ammo_blessing": ammo_blessing.duplicate(true),
		"has_bone_armor": has_bone_armor,
		"bone_armor_ready": bone_armor_ready,
		"has_stopwatch": has_stopwatch,
		"stopwatch_ready": stopwatch_ready,
		"has_gold_magnet": has_gold_magnet,
		"has_wind_wings": has_wind_wings,
		"has_melee_necklace": has_melee_necklace,
		"has_luck_hoof": has_luck_hoof,
		"has_master_key": has_master_key,
	}


func apply_snapshot_dict(d: Dictionary) -> void:
	character_id = str(d.get("character_id", "default"))
	wave_index = int(d.get("wave_index", 0))
	gold = int(d.get("gold", 0))
	run_start_ticks_msec = int(d.get("run_start_ticks_msec", Time.get_ticks_msec()))
	run_seed = int(d.get("run_seed", randi()))
	player_max_hp = int(d.get("player_max_hp", 100))
	player_current_hp = int(d.get("player_current_hp", player_max_hp))
	material_current = int(d.get("material_current", 0))
	material_savings = int(d.get("material_savings", 0))
	player_level = int(d.get("player_level", 1))
	player_xp = int(d.get("player_xp", 0))
	run_risk_mult = clampf(float(d.get("run_risk_mult", 1.0)), 1.0, 1.5)
	upgrade_ids.clear()
	var raw_up: Variant = d.get("upgrade_ids", [])
	if raw_up is Array:
		for x in raw_up as Array:
			upgrade_ids.append(str(x))
	run_choice_log.clear()
	var raw_log: Variant = d.get("run_choice_log", [])
	if raw_log is Array:
		for item in raw_log as Array:
			if item is Dictionary:
				run_choice_log.append((item as Dictionary).duplicate(true))
	pause_reason = PauseReason.NONE
	reset_session_play_banking()
	shop_weapon_mods.clear()
	var raw_mods: Variant = d.get("shop_weapon_mods", [])
	if raw_mods is Array:
		for x in raw_mods as Array:
			shop_weapon_mods.append(str(x))
	shop_consumables.clear()
	var raw_cons: Variant = d.get("shop_consumables", {})
	if raw_cons is Dictionary:
		for k in (raw_cons as Dictionary).keys():
			shop_consumables[str(k)] = int((raw_cons as Dictionary)[k])
	ammo_blessing.clear()
	var raw_ab: Variant = d.get("ammo_blessing", {})
	if raw_ab is Dictionary:
		for k in (raw_ab as Dictionary).keys():
			var v: Variant = (raw_ab as Dictionary)[k]
			if v is Dictionary:
				ammo_blessing[str(k)] = (v as Dictionary).duplicate(true)
	has_bone_armor = bool(d.get("has_bone_armor", false))
	bone_armor_ready = bool(d.get("bone_armor_ready", false))
	has_stopwatch = bool(d.get("has_stopwatch", false))
	stopwatch_ready = bool(d.get("stopwatch_ready", false))
	has_gold_magnet = bool(d.get("has_gold_magnet", false))
	has_wind_wings = bool(d.get("has_wind_wings", false))
	has_melee_necklace = bool(d.get("has_melee_necklace", false))
	has_luck_hoof = bool(d.get("has_luck_hoof", false))
	has_master_key = bool(d.get("has_master_key", false))
	emit_signal("consumables_changed")


func emit_hud_sync_signals() -> void:
	emit_signal("wave_changed", wave_index)
	emit_signal("material_changed", material_current, material_savings)
	emit_signal("xp_changed", player_level, player_xp, xp_to_next_level())
	emit_signal("consumables_changed")
