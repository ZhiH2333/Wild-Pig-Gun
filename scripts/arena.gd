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
}

const SPAWN_WARNING_SCENE: String = "res://scenes/spawn_warning.tscn"

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var material_container: Node2D = $MaterialContainer
@onready var spawn_warning_container: Node2D = $SpawnWarningContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var interstitial_hub: CanvasLayer = $InterstitialHub
@onready var wave_manager: WaveManager = $WaveManager
@onready var enemy_pool: Node = $EnemyPool

## 预加载的敌人场景缓存
var _loaded_enemy_scenes: Dictionary = {}
var _spawn_warning_scene: PackedScene = null


func _ready() -> void:
	add_to_group("arena")
	_preload_scenes()

	# 连接玩家信号
	if player:
		player.died.connect(_on_player_died)

	# 连接 HUD
	if hud and hud.has_method("setup"):
		hud.setup(player)

	# 注入 WaveManager 依赖
	wave_manager.player = player
	wave_manager.enemy_pool = enemy_pool
	wave_manager.arena_rect = get_arena_rect()

	# 连接 WaveManager 信号
	wave_manager.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
	wave_manager.spawn_warning_shown.connect(_on_spawn_warning_shown)
	wave_manager.wave_ended.connect(_on_wave_ended)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.wave_timer_tick.connect(_on_wave_timer_tick)
	wave_manager.wave_started.connect(_on_wave_started)

	if interstitial_hub != null and interstitial_hub.has_signal("continue_pressed"):
		interstitial_hub.continue_pressed.connect(_on_interstitial_continue_pressed)
	var resume_btn: Button = pause_overlay.get_node_or_null("CenterContainer/PauseVBox/ResumeButton") as Button
	if resume_btn != null:
		resume_btn.pressed.connect(_on_pause_resume_pressed)

	# 启动第 1 波（需求 7.1）
	wave_manager.start_run()

	# 每 2 秒全局拾取一次：强制所有掉落物开始向玩家飞
	var collect_timer := Timer.new()
	collect_timer.wait_time = 2.0
	collect_timer.autostart = true
	collect_timer.timeout.connect(_on_global_collect_tick)
	add_child(collect_timer)


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


## WaveManager 请求生成敌人（需求 7.3）
func _on_enemy_spawn_requested(config: Dictionary, position: Vector2) -> void:
	var type: String = config.get("type", "basic")
	var scene: PackedScene = _loaded_enemy_scenes.get(type, null)
	if scene == null:
		# 回退到普通敌人
		scene = _loaded_enemy_scenes.get("basic", null)
	if scene == null:
		return

	var enemy: Node2D = scene.instantiate()
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
	if not is_instance_valid(drop_node):
		return
	if drop_node.get_meta("is_savings", false):
		RunState.collect_savings()
	else:
		RunState.collect_material(amount)


## 波次结束：将未拾取材料转为储蓄（需求 10.1）；非最终波进入波间
func _on_wave_ended(wave_index: int) -> void:
	var uncollected := material_container.get_child_count()
	RunState.on_wave_end_convert_savings(uncollected)
	for drop in material_container.get_children():
		drop.set_meta("is_savings", true)
	if hud and hud.has_method("on_wave_ended"):
		hud.on_wave_ended()
	if wave_index >= wave_manager.MAX_WAVES:
		return
	if interstitial_hub != null and interstitial_hub.has_method("show_for_finished_wave"):
		interstitial_hub.show_for_finished_wave(wave_index)


## 倒计时 tick 转发给 HUD
func _on_wave_timer_tick(remaining: float) -> void:
	if hud and hud.has_method("on_wave_timer_tick"):
		hud.on_wave_timer_tick(remaining)


## 新波次开始时更新 HUD 波次显示
func _on_wave_started(wave_index: int) -> void:
	RunState.wave_index = wave_index
	RunState.wave_changed.emit(wave_index)


## 通关（需求 7.5）
func _on_all_waves_cleared() -> void:
	await get_tree().create_timer(1.0).timeout
	if ResourceLoader.exists("res://scenes/victory.tscn"):
		get_tree().change_scene_to_file("res://scenes/victory.tscn")
	elif ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func show_pause_overlay() -> void:
	pause_overlay.visible = true


func hide_pause_overlay() -> void:
	pause_overlay.visible = false


func _on_pause_resume_pressed() -> void:
	RunState.try_toggle_user_pause(self)


func _on_interstitial_continue_pressed() -> void:
	wave_manager.start_next_wave()


## 玩家死亡（需求 4.4、6.1）
func _on_player_died() -> void:
	wave_manager.is_wave_active = false
	await get_tree().create_timer(1.0).timeout
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
