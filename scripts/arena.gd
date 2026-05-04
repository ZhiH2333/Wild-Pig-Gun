extends Node2D
## Arena 主场景脚本
## 需求：3.4、4.4、6.1、7.1、7.2、7.4、7.5

const ARENA_WIDTH: float = 1920.0
const ARENA_HEIGHT: float = 1080.0
const EDGE_MARGIN: float = 32.0

## 敌人场景映射表（type 字符串 → 场景路径）
const ENEMY_SCENE_MAP: Dictionary = {
	"basic":   "res://scenes/enemy.tscn",
	"dash":    "res://scenes/enemies/dash_enemy.tscn",
	"ranged":  "res://scenes/enemies/ranged_enemy.tscn",
	"elite":   "res://scenes/enemies/elite_enemy.tscn",
	"tree":    "res://scenes/enemies/tree_enemy.tscn",
	"looter":  "res://scenes/enemies/looter_enemy.tscn",
	"buff":    "res://scenes/enemies/buff_enemy.tscn",
	"trap":    "res://scenes/enemies/trap_enemy.tscn",
	"splitter": "res://scenes/enemies/splitter_enemy.tscn",
	"charger": "res://scenes/enemies/charger_enemy.tscn",
	"shield": "res://scenes/enemies/shield_enemy.tscn",
	"boss_pig": "res://scenes/enemies/boss_enemy.tscn",
}

const SPAWN_WARNING_SCENE: String = "res://scenes/spawn_warning.tscn"
const RUN_SNAPSHOT_VERSION: int = 1
const SETTINGS_SCENE_PATH: String = "res://scenes/settings.tscn"
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const TUTORIAL_HINT_SCENE: PackedScene = preload("res://scenes/ui/tutorial_hint_panel.tscn")
const ConsumableHotkeySlots = preload("res://scripts/game/consumable_hotkey_slots.gd")

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var material_container: Node2D = $MaterialContainer
@onready var spawn_warning_container: Node2D = $SpawnWarningContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var interstitial_hub: CanvasLayer = $InterstitialHub
@onready var level_up_overlay: CanvasLayer = $LevelUpOverlay
@onready var wave_manager: WaveManager = $WaveManager
@onready var enemy_pool: Node = $EnemyPool
## 预加载的敌人场景缓存
var _loaded_enemy_scenes: Dictionary = {}
var _spawn_warning_scene: PackedScene = null
var _wave_cfg: Dictionary = {}
var _in_game_settings_layer: Control = null
var _pause_over_level_up: bool = false
## 当前波次刚开始时（`wave_started`）的整局快照，用于「放弃本波进度」写回续玩档
var _checkpoint_at_wave_start: Dictionary = {}
const AUTOSAVE_INTERVAL_SEC: float = 35.0


func _ensure_active_slot_for_resume() -> void:
	if not SaveManager.active_save_slot_id.is_empty():
		return
	var last: String = SaveManager.get_last_played_slot_id()
	if SaveManager.slot_has_resumable_run(last):
		SaveManager.active_save_slot_id = last
		return
	var fid: String = SaveManager.find_first_slot_with_run()
	if not fid.is_empty():
		SaveManager.active_save_slot_id = fid


func _ready() -> void:
	add_to_group("arena")
	_wave_cfg = WaveData.load_config()
	_preload_scenes()
	GameMusic.enter_battle()
	if player:
		player.died.connect(_on_player_died)
	_ensure_active_slot_for_resume()
	var snap_resume: Dictionary = SaveManager.load_pending_run()
	var resume_run: bool = not snap_resume.is_empty()
	if not resume_run:
		if player != null:
			CharacterData.apply_to_player(player, RunState.character_id)
	if hud and hud.has_method("setup"):
		hud.setup(player)
	wave_manager.player = player
	wave_manager.enemy_pool = enemy_pool
	wave_manager.arena_rect = get_arena_rect()
	wave_manager.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
	wave_manager.spawn_warning_shown.connect(_on_spawn_warning_shown)
	wave_manager.wave_ended.connect(_on_wave_ended)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_timer_tick.connect(_on_wave_timer_tick)
	wave_manager.wave_started.connect(_on_wave_started)
	if interstitial_hub != null:
		if interstitial_hub.has_method("set_player"):
			interstitial_hub.set_player(player)
		if interstitial_hub.has_signal("continue_pressed"):
			interstitial_hub.continue_pressed.connect(_on_interstitial_continue_pressed)
	if level_up_overlay != null and level_up_overlay.has_method("set_player"):
		level_up_overlay.set_player(player)
	if resume_run:
		_restore_run_from_snapshot(snap_resume)
	else:
		wave_manager.start_run()
	if (
		TutorialSession.active
		and TutorialSession.current_step == TutorialSession.TutorialStep.WAVE_ONE
	):
		var hint: CanvasLayer = TUTORIAL_HINT_SCENE.instantiate() as CanvasLayer
		add_child(hint)
		if hint.has_method("setup"):
			hint.setup(wave_manager)
	var collect_timer := Timer.new()
	collect_timer.wait_time = 2.0
	collect_timer.autostart = true
	collect_timer.timeout.connect(_on_global_collect_tick)
	add_child(collect_timer)
	var autosave_timer := Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)


func _on_autosave_timer_timeout() -> void:
	if get_tree().paused:
		return
	if interstitial_hub != null and interstitial_hub.visible:
		return
	_autosave_pending_run_if_possible()


func _process(_delta: float) -> void:
	if RunState.pause_reason != RunState.PauseReason.NONE:
		return
	if player == null:
		return
	var sk: Node = player.get_node_or_null("PlayerSkillController")
	if sk == null:
		return
	if Input.is_action_just_pressed("skill"):
		sk.call("try_activate_slot", 0)
	if Input.is_action_just_pressed("skill_secondary"):
		sk.call("try_activate_slot", 1)
	if Input.is_action_just_pressed("skill_tertiary"):
		sk.call("try_activate_slot", 2)


## 预加载所有敌人场景和预警场景
func _preload_scenes() -> void:
	for type in ENEMY_SCENE_MAP:
		var path: String = ENEMY_SCENE_MAP[type]
		if ResourceLoader.exists(path):
			_loaded_enemy_scenes[type] = load(path)

	if ResourceLoader.exists(SPAWN_WARNING_SCENE):
		_spawn_warning_scene = load(SPAWN_WARNING_SCENE)


func get_enemies() -> Array:
	return enemy_container.get_children()


func get_arena_rect() -> Rect2:
	return Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)


## 调试菜单：在指定位置生成指定类型敌人（与波次缩放一致）
func debug_spawn_enemy_at(enemy_type: String, spawn_position: Vector2) -> void:
	call_deferred("_execute_enemy_spawn_requested", {"type": enemy_type}, spawn_position)


func _apply_wave_scaling_before_enter_tree(enemy: Node2D) -> void:
	var sc: Dictionary = WaveData.get_scaling(_wave_cfg)
	var w: int = RunState.wave_index
	var hp_m: float = 1.0 + w * float(sc.get("hp_per_wave", 0.08))
	var dmg_m: float = 1.0 + w * float(sc.get("damage_per_wave", 0.05))
	if "max_hp" in enemy:
		enemy.max_hp = maxi(1, int(round(enemy.max_hp * hp_m)))
	if "contact_damage" in enemy:
		enemy.contact_damage = maxi(1, int(round(enemy.contact_damage * dmg_m)))


## WaveManager 请求生成敌人（需求 7.3）
## 必须延后执行：若在 projectile body_entered / take_damage 等物理回调里同步 add_child，
## 会触发 “Can't change this state while flushing queries”。
func _on_enemy_spawn_requested(config: Dictionary, position: Vector2) -> void:
	call_deferred("_execute_enemy_spawn_requested", config.duplicate(), position)


func _execute_enemy_spawn_requested(config: Dictionary, position: Vector2) -> void:
	if not is_instance_valid(enemy_container):
		return
	var type: String = config.get("type", "basic")
	var scene: PackedScene = _loaded_enemy_scenes.get(type, null)
	if scene == null:
		# 回退到普通敌人
		scene = _loaded_enemy_scenes.get("basic", null)
	if scene == null:
		return

	var enemy: Node2D = scene.instantiate()
	_apply_wave_scaling_before_enter_tree(enemy)
	enemy_container.add_child(enemy)
	enemy.global_position = position

	if "target" in enemy:
		enemy.target = player
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
	if enemy.has_signal("escaped"):
		enemy.escaped.connect(_on_enemy_escaped.bind(enemy))

	# 注册到 EnemyPool（超出上限时自动替换最旧敌人）
	enemy_pool.register_enemy(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died_xp)


## 显示红叉预警（需求 7.4）
func _on_spawn_warning_shown(position: Vector2) -> void:
	if _spawn_warning_scene == null:
		return
	var warning: Node2D = _spawn_warning_scene.instantiate()
	spawn_warning_container.add_child(warning)
	warning.global_position = position


## 材料被拾取时的回调（需求 10.1）
## drop_node 由 bind() 传入，用于检查是否为储蓄材料
func _on_material_collected(material_id: String, amount: int, drop_node: Node) -> void:
	if material_id == "heal":
		if player != null and player.has_method("heal_flat"):
			player.heal_flat(32)
		return
	if material_id == "box":
		if player != null:
			var box_rng := RandomNumberGenerator.new()
			box_rng.randomize()
			var luck: int = 0
			if "stat_luck" in player:
				luck = int(player.stat_luck)
			var gifts: Array = BuildCatalog.pick_shop_offer(1, box_rng, luck)
			if gifts.size() > 0:
				BuildCatalog.apply_shop_def(player, gifts[0] as Dictionary)
		RunState.collect_material(maxi(amount * 6, 8))
		return
	if not is_instance_valid(drop_node):
		return
	if material_id == "gold":
		GameAudio.play_get_coin()
	if drop_node.get_meta("is_savings", false):
		RunState.collect_savings()
	else:
		RunState.collect_material(amount)


## 波次结束：将未拾取材料转为储蓄（需求 10.1）；非最终波进入波间
func _on_wave_ended(wave_index: int) -> void:
	if enemy_pool != null and enemy_pool.has_method("clear_all"):
		enemy_pool.clear_all()
	_clear_enemy_projectiles()
	var uncollected := material_container.get_child_count()
	RunState.on_wave_end_convert_savings(uncollected)
	var hb: int = _compute_harvest_bonus(wave_index)
	if hb > 0:
		RunState.collect_material(hb)
		if hud != null and hud.has_method("show_harvest_toast"):
			hud.show_harvest_toast(hb)
	for drop in material_container.get_children():
		drop.set_meta("is_savings", true)
	if hud and hud.has_method("on_wave_ended"):
		hud.on_wave_ended()
	_autosave_pending_run_if_possible()
	if wave_index >= wave_manager.MAX_WAVES:
		return
	if TutorialSession.active and wave_index == 1:
		TutorialSession.advance_after_wave_one_hint()
	if interstitial_hub != null and interstitial_hub.has_method("show_for_finished_wave"):
		interstitial_hub.show_for_finished_wave(wave_index)


## 倒计时 tick 转发给 HUD
func _on_wave_timer_tick(remaining: float) -> void:
	if hud and hud.has_method("on_wave_timer_tick"):
		hud.on_wave_timer_tick(remaining)


## 新波次开始时更新 HUD 波次显示
func _on_wave_started(wave_index: int, duration_sec: float = 30.0) -> void:
	RunState.reset_wave_shop_flags()
	RunState.wave_index = wave_index
	RunState.wave_changed.emit(wave_index)
	if hud != null and hud.has_method("on_wave_timer_reset"):
		hud.on_wave_timer_reset(duration_sec)
	_checkpoint_at_wave_start = build_run_snapshot()


## 通关（需求 7.5）
func _on_all_waves_cleared() -> void:
	await get_tree().create_timer(1.0).timeout
	RunState.capture_endgame_from_player(player)
	if ResourceLoader.exists("res://scenes/victory.tscn"):
		get_tree().change_scene_to_file("res://scenes/victory.tscn")
	elif ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func show_pause_overlay() -> void:
	if pause_overlay == null:
		return
	_pause_over_level_up = (RunState.pause_reason == RunState.PauseReason.LEVEL_UP)
	if RunState.pause_reason == RunState.PauseReason.USER:
		GameMusic.duck_battle_for_pause_overlay()
	pause_overlay.visible = true
	var center_container: CanvasItem = pause_overlay.get_node_or_null("CenterContainer")
	if center_container != null:
		center_container.visible = true


func hide_pause_overlay() -> void:
	if pause_overlay == null:
		return
	pause_overlay.visible = false
	if pause_overlay.has_method("reset_when_pause_closed"):
		pause_overlay.reset_when_pause_closed()
	_pause_over_level_up = false


func open_in_game_settings() -> void:
	if pause_overlay == null:
		return
	if _in_game_settings_layer != null and is_instance_valid(_in_game_settings_layer):
		return
	if not ResourceLoader.exists(SETTINGS_SCENE_PATH):
		return
	var scene: PackedScene = load(SETTINGS_SCENE_PATH) as PackedScene
	if scene == null:
		return
	var settings_layer: Control = scene.instantiate() as Control
	if settings_layer == null:
		return
	pause_overlay.visible = true
	var center_container: CanvasItem = pause_overlay.get_node_or_null("CenterContainer")
	if center_container != null:
		center_container.visible = false
	settings_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	settings_layer.set_meta("in_game_overlay", true)
	settings_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(settings_layer)
	_in_game_settings_layer = settings_layer


func close_in_game_settings() -> void:
	if pause_overlay == null:
		return
	if _in_game_settings_layer != null and is_instance_valid(_in_game_settings_layer):
		_in_game_settings_layer.queue_free()
	_in_game_settings_layer = null
	var center_container: CanvasItem = pause_overlay.get_node_or_null("CenterContainer")
	if center_container != null:
		center_container.visible = true
	show_pause_overlay()


func build_run_snapshot() -> Dictionary:
	if player != null:
		RunState.player_max_hp = player.max_hp
		RunState.player_current_hp = player.current_hp
	RunState.wave_index = wave_manager.current_wave
	var weapons: Array = []
	var lo: Node = player.get_node_or_null("WeaponLoadout") if player != null else null
	if lo != null:
		for c in lo.get_children():
			if "weapon_id" in c:
				weapons.append(str(c.weapon_id))
	var pstats: Dictionary = {}
	if player != null:
		pstats = {
			"max_hp": player.max_hp,
			"current_hp": player.current_hp,
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
			"stat_damage_flat": player.stat_damage_flat,
			"stat_melee_damage_mult": player.stat_melee_damage_mult,
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
			"pos_x": player.global_position.x,
			"pos_y": player.global_position.y,
		}
	var sk_node: Node = player.get_node_or_null("PlayerSkillController") if player != null else null
	if sk_node != null and sk_node.has_method("get_save_state"):
		pstats["skill_state"] = sk_node.call("get_save_state")
	return {
		"version": RUN_SNAPSHOT_VERSION,
		"run_state": RunState.to_snapshot_dict(),
		"player": pstats,
		"weapons": weapons,
		"wave": wave_manager.get_save_snapshot(),
		"interstitial_open": interstitial_hub != null and interstitial_hub.visible,
	}


func _clear_enemy_projectiles() -> void:
	if projectile_container == null:
		return
	for child in projectile_container.get_children():
		if child is Projectile:
			var pr: Projectile = child as Projectile
			if pr.team == Projectile.TEAM_ENEMY:
				pr.die()


func _autosave_pending_run_if_possible() -> void:
	_ensure_active_slot_for_resume()
	var data: Dictionary = build_run_snapshot()
	if not _checkpoint_at_wave_start.is_empty():
		data["wave_start_checkpoint"] = _checkpoint_at_wave_start.duplicate(true)
	if not SaveManager.save_pending_run(data):
		push_warning("Arena: wave-end autosave failed")


func save_run_and_return_to_menu() -> void:
	var data: Dictionary = build_run_snapshot()
	if not _checkpoint_at_wave_start.is_empty():
		data["wave_start_checkpoint"] = _checkpoint_at_wave_start.duplicate(true)
	if interstitial_hub != null and interstitial_hub.visible:
		interstitial_hub.visible = false
	SaveManager.save_pending_run(data)
	RunState.pause_reason = RunState.PauseReason.NONE
	get_tree().paused = false
	hide_pause_overlay()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func quit_to_menu_without_saving() -> void:
	if _checkpoint_at_wave_start.is_empty():
		SaveManager.clear_pending_run()
	else:
		var data: Dictionary = _checkpoint_at_wave_start.duplicate(true)
		data["wave_start_checkpoint"] = _checkpoint_at_wave_start.duplicate(true)
		SaveManager.save_pending_run(data)
	RunState.pause_reason = RunState.PauseReason.NONE
	get_tree().paused = false
	hide_pause_overlay()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _restore_run_from_snapshot(snap: Dictionary) -> void:
	var ver: int = int(snap.get("version", 0))
	if ver != RUN_SNAPSHOT_VERSION:
		push_warning("Arena: 进行中存档版本不匹配，已改为新开局")
		SaveManager.clear_pending_run()
		if player != null:
			CharacterData.apply_to_player(player, RunState.character_id)
		wave_manager.start_run()
		return
	_clear_combat_entities()
	var rs: Variant = snap.get("run_state", {})
	if rs is Dictionary:
		RunState.apply_snapshot_dict(rs as Dictionary)
	if player != null:
		CharacterData.apply_character_visual(player, RunState.character_id)
		var ps: Variant = snap.get("player", {})
		if ps is Dictionary and player.has_method("apply_run_snapshot_stats"):
			player.apply_run_snapshot_stats(ps as Dictionary)
	var wv: Variant = snap.get("weapons", [])
	if wv is Array:
		_restore_weapon_loadout(wv as Array)
	var ws: Variant = snap.get("wave", {})
	if ws is Dictionary:
		wave_manager.apply_save_snapshot(ws as Dictionary)
	if bool(snap.get("interstitial_open", false)) and interstitial_hub != null:
		var finished: int = wave_manager.current_wave
		if finished > 0:
			interstitial_hub.show_for_finished_wave(finished)
	var wsc: Variant = snap.get("wave_start_checkpoint", {})
	if wsc is Dictionary and not (wsc as Dictionary).is_empty():
		_checkpoint_at_wave_start = (wsc as Dictionary).duplicate(true)
	else:
		_checkpoint_at_wave_start = {}
	RunState.emit_hud_sync_signals()
	if hud != null and hud.has_method("rebuild_character_skills"):
		hud.rebuild_character_skills()


func _clear_combat_entities() -> void:
	for c in enemy_container.get_children():
		c.queue_free()
	for c in material_container.get_children():
		c.queue_free()
	for c in projectile_container.get_children():
		if c is Projectile:
			(c as Projectile).die()
		else:
			c.queue_free()
	for c in spawn_warning_container.get_children():
		c.queue_free()
	if enemy_pool != null and enemy_pool.has_method("clear_all"):
		enemy_pool.clear_all()


func _restore_weapon_loadout(weapon_ids: Array) -> void:
	var lo: Node = player.get_node_or_null("WeaponLoadout") if player != null else null
	if lo == null:
		return
	var prev: Array[Node] = []
	for c in lo.get_children():
		prev.append(c)
	for c in prev:
		lo.remove_child(c)
		c.free()
	for wid_variant in weapon_ids:
		var wid: String = str(wid_variant)
		if wid.is_empty():
			continue
		if lo.has_method("add_weapon_slot_by_id"):
			lo.add_weapon_slot_by_id(wid)
	if player != null and player.has_method("recompute_weapon_synergy"):
		player.recompute_weapon_synergy()
	if hud != null and hud.has_method("refresh_weapon_slots"):
		hud.refresh_weapon_slots()


func _on_pause_resume_pressed() -> void:
	if _in_game_settings_layer != null and is_instance_valid(_in_game_settings_layer):
		close_in_game_settings()
		return
	if RunState.pause_reason == RunState.PauseReason.INTERSTITIAL:
		if pause_overlay != null and pause_overlay.visible:
			hide_pause_overlay()
		else:
			show_pause_overlay()
		return
	if RunState.pause_reason == RunState.PauseReason.LEVEL_UP:
		if pause_overlay == null:
			return
		if _pause_over_level_up:
			hide_pause_overlay()
		else:
			show_pause_overlay()
		return
	RunState.try_toggle_user_pause(self)


func _on_interstitial_continue_pressed() -> void:
	RunState.bank_run_material_to_wallet()
	wave_manager.start_next_wave()


## 玩家死亡（需求 4.4、6.1）
func _on_player_died() -> void:
	GameAudio.play_die()
	wave_manager.is_wave_active = false
	await get_tree().create_timer(1.0).timeout
	RunState.capture_endgame_from_player(player)
	if ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


## 宝藏怪逃跑（不触发 died）
func _on_enemy_escaped(_enemy: Node2D) -> void:
	pass


## 每 2 秒强制所有掉落物跳过弹跳阶段，立即开始向玩家飞
func _on_global_collect_tick() -> void:
	for drop in material_container.get_children():
		if drop.has_method("force_attract"):
			drop.force_attract()


func _unhandled_input(event: InputEvent) -> void:
	if RunState.pause_reason != RunState.PauseReason.NONE:
		return
	if player == null:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_1:
				use_consumable_slot(1)
			KEY_2:
				use_consumable_slot(2)
			KEY_3:
				use_consumable_slot(3)
			KEY_4:
				use_consumable_slot(4)
			KEY_5:
				use_consumable_slot(5)
			KEY_6:
				use_consumable_slot(6)
			KEY_7:
				_try_activate_stopwatch()


## 槽位 1–6 → 消耗品（供 HUD 触控条与快捷键共用）
func use_consumable_slot(slot_one_based: int) -> void:
	var sid: String = ConsumableHotkeySlots.shop_id_for_slot_one_based(slot_one_based)
	_try_use_shop_consumable(sid)


func _try_activate_stopwatch() -> void:
	if RunState == null or not RunState.has_stopwatch or not RunState.stopwatch_ready:
		return
	if RunState.stopwatch_frozen:
		return
	RunState.stopwatch_ready = false
	RunState.stopwatch_frozen = true
	RunState.stopwatch_frozen_time_left = 3.0
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("时停 3 秒", 1.2)


func _try_use_shop_consumable(shop_id: String) -> void:
	if RunState == null:
		return
	match shop_id:
		"shop_medkit":
			if player.shop_medkit_cast_left > 0.0001:
				return
			if not RunState.try_use_consumable(shop_id):
				return
			player.set_meta("_shop_medkit_pending", true)
			player.shop_medkit_cast_left = 0.5
			if hud != null and hud.has_method("show_toast"):
				hud.show_toast("注射…", 0.4)
		"shop_grenade":
			if not RunState.try_use_consumable(shop_id):
				return
			_spawn_consumable_grenade()
		"shop_smoke":
			if not RunState.try_use_consumable(shop_id):
				return
			RunState.shop_smoke_blind_left = 5.0
			player.shop_smoke_haste_left = 5.0
			if hud != null and hud.has_method("show_toast"):
				hud.show_toast("烟雾 5 秒", 1.2)
		"shop_emp":
			if not RunState.try_use_consumable(shop_id):
				return
			_apply_shop_emp_pulse()
			if hud != null and hud.has_method("show_toast"):
				hud.show_toast("电磁脉冲", 1.0)
		"shop_super_stim":
			if not RunState.try_use_consumable(shop_id):
				return
			player.shop_stim_power_left = 10.0
			player.shop_stim_fatigue_left = 0.0
			if hud != null and hud.has_method("show_toast"):
				hud.show_toast("超级鸡血 10 秒", 1.2)
		"shop_master_key":
			if not RunState.try_use_consumable(shop_id):
				return
			RunState.collect_material(8)
			if hud != null and hud.has_method("show_toast"):
				hud.show_toast("万能钥匙：+8 野猪币", 2.0)


func _spawn_consumable_grenade() -> void:
	if PROJECTILE_SCENE == null:
		return
	var proj_n: Node = ProjectilePool.get_projectile(PROJECTILE_SCENE)
	if proj_n == null:
		return
	var proj: Projectile = proj_n as Projectile
	if proj == null:
		return
	var toward: Vector2 = Vector2.RIGHT
	var best_d: float = 1e12
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			var e2: Node2D = n as Node2D
			var dd: float = player.global_position.distance_squared_to(e2.global_position)
			if dd < best_d:
				best_d = dd
				toward = (e2.global_position - player.global_position).normalized()
	proj.direction = toward
	proj.damage = maxi(22, int(round(player.stat_damage_mult * 20.0)))
	proj.team = Projectile.TEAM_PLAYER
	proj.source_weapon_id = "boar_grenade"
	proj.damage_element = &"fire"
	projectile_container.add_child(proj_n)
	proj_n.global_position = player.global_position
	GameAudio.play_shoot()


func _apply_shop_emp_pulse() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == null or not is_instance_valid(e):
			continue
		if not e is EnemyBase:
			continue
		var eb: EnemyBase = e as EnemyBase
		if not eb.is_shop_mechanical:
			continue
		if eb.has_method("apply_shop_emp_stun"):
			eb.call("apply_shop_emp_stun", 3.0)


func _compute_harvest_bonus(finished_wave: int) -> int:
	if player == null or not ("stat_harvest" in player):
		return 0
	var h: float = float(player.stat_harvest)
	if h <= 0.0001:
		return 0
	return int(round(h * (8.0 + float(finished_wave) * 2.5)))


func spawn_enemy_at(type: String, position: Vector2) -> void:
	var cfg: Dictionary = {"type": type}
	_on_enemy_spawn_requested(cfg, position)


func _on_enemy_died_xp(_dead_enemy: Node2D) -> void:
	if player != null:
		CharacterSkillImpl.on_enemy_killed_passives(player)
	var gain: int = 2 + RunState.wave_index / 2
	RunState.add_xp(gain)
