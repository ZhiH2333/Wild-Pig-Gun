extends Node2D

## Arena 主场景脚本（MVP 版本）
## 需求：4.4、6.1

const ARENA_WIDTH: float = 1920.0
const ARENA_HEIGHT: float = 1080.0

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var player: CharacterBody2D = $Player

var enemy_scene: PackedScene = null


func _ready() -> void:
	add_to_group("arena")
	# 运行时加载敌人场景（文件不存在时跳过）
	if ResourceLoader.exists("res://scenes/enemy.tscn"):
		enemy_scene = load("res://scenes/enemy.tscn")
	# 监听玩家死亡信号
	if player:
		player.died.connect(_on_player_died)
	# Debug：生成几只测试敌人
	_spawn_debug_enemies(3)


func get_arena_rect() -> Rect2:
	return Rect2(0.0, 0.0, ARENA_WIDTH, ARENA_HEIGHT)


func _on_player_died() -> void:
	# 延迟 1 秒后切换到游戏结束界面（game_over.tscn 在任务 10 中创建）
	await get_tree().create_timer(1.0).timeout
	if ResourceLoader.exists("res://scenes/game_over.tscn"):
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")


## Debug 用：在边缘随机生成若干敌人
func _spawn_debug_enemies(count: int) -> void:
	if enemy_scene == null:
		return
	for i in range(count):
		var enemy: Node2D = enemy_scene.instantiate()
		enemy_container.add_child(enemy)
		enemy.global_position = _get_random_edge_position()
		if enemy.has_method("set") and "target" in enemy:
			enemy.target = player


func _get_random_edge_position() -> Vector2:
	var edge: int = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, ARENA_WIDTH), 0.0)           # 上边
		1: return Vector2(randf_range(0, ARENA_WIDTH), ARENA_HEIGHT)  # 下边
		2: return Vector2(0.0, randf_range(0, ARENA_HEIGHT))          # 左边
		_: return Vector2(ARENA_WIDTH, randf_range(0, ARENA_HEIGHT))  # 右边
