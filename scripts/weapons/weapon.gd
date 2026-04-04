extends Node2D

## 武器脚本：自动向最近敌人发射子弹
## 需求：2.1、2.2、2.3

const FIRE_INTERVAL: float = 0.5

var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var damage: int = 10

@onready var fire_timer: Timer = $FireTimer


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
	var projectile: Node2D = projectile_scene.instantiate()
	var container: Node = _get_projectile_container()
	container.add_child(projectile)
	projectile.global_position = global_position
	# 设置子弹方向与伤害
	var dir: Vector2 = (target.global_position - global_position).normalized()
	projectile.direction = dir
	projectile.damage = damage


## 获取子弹容器节点；优先使用 Arena 的 ProjectileContainer
func _get_projectile_container() -> Node:
	# 尝试通过绝对路径获取
	var root: Node = get_tree().get_root()
	var arena: Node = root.get_node_or_null("Arena")
	if arena:
		var container: Node = arena.get_node_or_null("ProjectileContainer")
		if container:
			return container
	# 回退：在整棵树中查找
	var found: Node = root.find_child("ProjectileContainer", true, false)
	if found:
		return found
	return get_tree().current_scene
