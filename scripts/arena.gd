extends Node2D

## Arena 主场景脚本（MVP 版本）
## 需求：3.4、4.4、6.1

const ARENA_WIDTH: float = 1920.0
const ARENA_HEIGHT: float = 1080.0

## 边缘生成时距边界的偏移（确保敌人在边缘环形区域内）
const EDGE_MARGIN: float = 32.0

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var spawn_timer: Timer = $SpawnTimer

var enemy_scene: PackedScene = null


func _ready() -> void:
	add_to_group("arena")

	# 加载敌人场景
	if ResourceLoader.exists("res://scenes/enemy.tscn"):
		enemy_scene = load("res://scenes/enemy.tscn")

	# 连接 Player 信号（需求 4.4）
	if player:
		player.died.connect(_on_player_died)

	# 初始化 HUD（需求 5.1、5.2、5.3）
	if hud and hud.has_method("setup"):
		hud.setup(player)

	# 连接定时生成计时器
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# MVP 测试用：生成若干初始敌人（需求 3.4）
	_spawn_debug_enemies(5)


## 返回 EnemyContainer 的所有子节点（供 Weapon 查询最近敌人）
func get_enemies() -> Array:
	return enemy_container.get_children()


## 返回 Arena 边界矩形（供边界约束使用）
func get_arena_rect() -> Rect2:
	return Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)


## Player 死亡：延迟 1 秒后切换到游戏结束界面（需求 6.1）
func _on_player_died() -> void:
	spawn_timer.stop()
	await get_tree().create_timer(1.0).timeout
	if ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


## 每 5 秒在边缘随机位置生成 4 只敌人
func _on_spawn_timer_timeout() -> void:
	_spawn_debug_enemies(4)


## 在 Arena 边缘随机生成若干敌人（MVP 测试用，需求 3.4）
func _spawn_debug_enemies(count: int) -> void:
	if enemy_scene == null:
		return
	for i in range(count):
		var enemy: Node2D = enemy_scene.instantiate()
		enemy_container.add_child(enemy)
		enemy.global_position = _get_random_edge_position()
		# 设置追击目标为 Player（需求 3.1）
		if "target" in enemy:
			enemy.target = player
		# 加入 enemies 组，供 Weapon 查询（需求 2.2）
		enemy.add_to_group("enemies")


## 在 Arena 边缘环形区域内随机选取生成位置（需求 3.4）
## 边缘区域：距边界 ≤ EDGE_MARGIN 像素
func _get_random_edge_position() -> Vector2:
	var edge: int = randi() % 4
	match edge:
		0: # 上边
			return Vector2(randf_range(0.0, ARENA_WIDTH), randf_range(0.0, EDGE_MARGIN))
		1: # 下边
			return Vector2(randf_range(0.0, ARENA_WIDTH), randf_range(ARENA_HEIGHT - EDGE_MARGIN, ARENA_HEIGHT))
		2: # 左边
			return Vector2(randf_range(0.0, EDGE_MARGIN), randf_range(0.0, ARENA_HEIGHT))
		_: # 右边
			return Vector2(randf_range(ARENA_WIDTH - EDGE_MARGIN, ARENA_WIDTH), randf_range(0.0, ARENA_HEIGHT))
