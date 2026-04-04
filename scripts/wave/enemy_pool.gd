extends Node
class_name EnemyPool

signal enemy_replaced(old_enemy: Node2D, new_enemy: Node2D)

const MAX_ENEMIES: int = 100

# 按生成顺序维护的队列（最旧在队首）
var _active_enemies: Array[Node2D] = []


func register_enemy(enemy: Node2D) -> void:
	if _active_enemies.size() >= MAX_ENEMIES:
		_replace_oldest(enemy)
	else:
		_active_enemies.append(enemy)
		enemy.died.connect(_on_enemy_died.bind(enemy))


func _replace_oldest(new_enemy: Node2D) -> void:
	var oldest: Node2D = _active_enemies.pop_front()
	# 将最旧敌人移出场景（不触发 died 信号，不掉落材料）
	if is_instance_valid(oldest):
		oldest.died.disconnect(_on_enemy_died.bind(oldest))
		oldest.queue_free()
	_active_enemies.append(new_enemy)
	new_enemy.died.connect(_on_enemy_died.bind(new_enemy))
	emit_signal("enemy_replaced", oldest, new_enemy)


func _on_enemy_died(enemy: Node2D) -> void:
	_active_enemies.erase(enemy)


func get_active_count() -> int:
	return _active_enemies.size()


func clear_all() -> void:
	for e in _active_enemies:
		if is_instance_valid(e):
			e.died.disconnect(_on_enemy_died.bind(e))
			e.queue_free()
	_active_enemies.clear()
