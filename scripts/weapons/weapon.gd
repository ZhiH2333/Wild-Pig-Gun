extends Node2D

## 武器脚本：自动向最近敌人发射子弹
## 需求：2.1、2.2、2.3

const FIRE_INTERVAL: float = 0.5

var projectile_scene: PackedScene = null
var damage: int = 10

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	# 运行时加载子弹场景
	if ResourceLoader.exists("res://scenes/projectile.tscn"):
		projectile_scene = load("res://scenes/projectile.tscn")


## Debug 占位绘制：黄色小矩形代表枪管
func _draw() -> void:
	draw_rect(Rect2(0, -4, 24, 8), Color(1.0, 0.85, 0.2, 1.0))


## 查找距离 from_pos 最近的敌人节点，列表为空时返回 null
func find_nearest_enemy(enemies: Array, from_pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = INF
	for e in enemies:
		var d: float = from_pos.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest


## FireTimer 超时回调：查询 enemies 组，找到目标后发射子弹
func _on_fire_timer_timeout() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var target: Node2D = find_nearest_enemy(enemies, global_position)
	if target == null:
		return
	_fire(target)


## 实例化子弹并朝目标方向发射
func _fire(target: Node2D) -> void:
	if projectile_scene == null:
		return
	var projectile: Node2D = projectile_scene.instantiate()
	# 将子弹添加到 ProjectileContainer（由 Arena 提供），否则添加到根节点
	var container: Node = _get_projectile_container()
	container.add_child(projectile)
	projectile.global_position = global_position
	# 设置子弹方向
	var dir: Vector2 = (target.global_position - global_position).normalized()
	if projectile.has_method("set_direction"):
		projectile.set_direction(dir)
	elif "direction" in projectile:
		projectile.direction = dir


## 获取子弹容器节点；优先使用 Arena 的 ProjectileContainer
func _get_projectile_container() -> Node:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena and arena.has_node("ProjectileContainer"):
		return arena.get_node("ProjectileContainer")
	return get_tree().current_scene
