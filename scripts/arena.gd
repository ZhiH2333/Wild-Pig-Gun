extends Node2D

## Arena 主场景脚本
## 需求：3.4、4.4、6.1

const ARENA_WIDTH: float = 1920.0
const ARENA_HEIGHT: float = 1080.0
const EDGE_MARGIN: float = 32.0

## 各类型敌人场景路径
const ENEMY_SCENES: Array[String] = [
	"res://scenes/enemy.tscn",
	"res://scenes/enemies/dash_enemy.tscn",
	"res://scenes/enemies/ranged_enemy.tscn",
	"res://scenes/enemies/elite_enemy.tscn",
	"res://scenes/enemies/tree_enemy.tscn",
	"res://scenes/enemies/looter_enemy.tscn",
]

## 各类型权重（普通最多，精英最少）
const ENEMY_WEIGHTS: Array[int] = [50, 20, 15, 5, 5, 5]

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var spawn_timer: Timer = $SpawnTimer

## 已加载的敌人场景缓存
var _loaded_scenes: Array[PackedScene] = []
## 权重累积表（用于加权随机）
var _weight_cumulative: Array[int] = []


func _ready() -> void:
	add_to_group("arena")
	_preload_enemy_scenes()

	if player:
		player.died.connect(_on_player_died)

	if hud and hud.has_method("setup"):
		hud.setup(player)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# 初始生成：每种类型各 1 只，让玩家立刻看到所有敌人
	_spawn_one_of_each()
	# 再随机补充几只
	_spawn_random_enemies(3)


## 预加载所有敌人场景，跳过不存在的
func _preload_enemy_scenes() -> void:
	_loaded_scenes.clear()
	_weight_cumulative.clear()
	var cumulative := 0
	for i in ENEMY_SCENES.size():
		var path: String = ENEMY_SCENES[i]
		if ResourceLoader.exists(path):
			_loaded_scenes.append(load(path))
			cumulative += ENEMY_WEIGHTS[i]
			_weight_cumulative.append(cumulative)


## 每种类型各生成 1 只（展示用）
func _spawn_one_of_each() -> void:
	for scene in _loaded_scenes:
		_spawn_enemy_from_scene(scene)


## 加权随机生成若干敌人
func _spawn_random_enemies(count: int) -> void:
	if _loaded_scenes.is_empty():
		return
	for _i in range(count):
		var scene := _pick_random_scene()
		if scene:
			_spawn_enemy_from_scene(scene)


## 加权随机选取一个敌人场景
func _pick_random_scene() -> PackedScene:
	if _loaded_scenes.is_empty():
		return null
	var total: int = _weight_cumulative.back()
	var roll := randi() % total
	for i in _weight_cumulative.size():
		if roll < _weight_cumulative[i]:
			return _loaded_scenes[i]
	return _loaded_scenes[0]


## 实例化并放置一只敌人
func _spawn_enemy_from_scene(scene: PackedScene) -> void:
	var enemy: Node2D = scene.instantiate()
	enemy_container.add_child(enemy)
	enemy.global_position = _get_random_edge_position()
	if "target" in enemy:
		enemy.target = player
	# 确保加入 enemies 组（基类 _ready 已处理，这里保险起见）
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
	# 连接 looter 逃跑信号（不计死亡）
	if enemy.has_signal("escaped"):
		enemy.escaped.connect(_on_enemy_escaped.bind(enemy))


func get_enemies() -> Array:
	return enemy_container.get_children()


func get_arena_rect() -> Rect2:
	return Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)


func _on_player_died() -> void:
	spawn_timer.stop()
	await get_tree().create_timer(1.0).timeout
	if ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


## 定时随机生成 2~4 只敌人
func _on_spawn_timer_timeout() -> void:
	_spawn_random_enemies(randi_range(2, 4))


## 宝藏怪逃跑（不触发 died，仅从容器移除）
func _on_enemy_escaped(enemy: Node2D) -> void:
	pass  # enemy 已在 looter_enemy.gd 中 queue_free()


## 在 Arena 边缘环形区域内随机选取生成位置（需求 3.4）
func _get_random_edge_position() -> Vector2:
	var edge: int = randi() % 4
	match edge:
		0:
			return Vector2(randf_range(0.0, ARENA_WIDTH), randf_range(0.0, EDGE_MARGIN))
		1:
			return Vector2(randf_range(0.0, ARENA_WIDTH), randf_range(ARENA_HEIGHT - EDGE_MARGIN, ARENA_HEIGHT))
		2:
			return Vector2(randf_range(0.0, EDGE_MARGIN), randf_range(0.0, ARENA_HEIGHT))
		_:
			return Vector2(randf_range(ARENA_WIDTH - EDGE_MARGIN, ARENA_WIDTH), randf_range(0.0, ARENA_HEIGHT))
