extends CharacterBody2D
class_name EnemyBase

## 敌人基类：提供血量、伤害、掉落的公共逻辑
## 子类需实现 _get_move_velocity() -> Vector2
## 需求：3.1、3.2、3.3、3.5

# 信号
signal died(enemy: Node2D)

# 基础属性（子类可覆盖）
var enemy_id: String = ""
var max_hp: int = 30
var current_hp: int = 30
var move_speed: float = 80.0
var contact_damage: int = 10
var armor: float = 0.0           # 护甲减伤率 0.0~1.0
var gold_reward: int = 1
var drop_heal_chance: float = 0.05   # 掉落回血果子概率
var drop_box_chance: float = 0.02    # 掉落绿箱子概率

var target: Node2D = null
var _damage_on_cooldown: bool = false
## 死亡时额外生成若干小怪（分裂体）
@export var split_spawn_count: int = 0
@export var split_spawn_type: String = "basic"

## 类型名称，子类设置，用于 debug 标签显示
var enemy_type_name: String = "敌人"

@onready var damage_timer: Timer = $DamageTimer


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	damage_timer.timeout.connect(_on_damage_timer_timeout)


## 子类实现具体移动逻辑（抽象方法）
func _get_move_velocity() -> Vector2:
	return Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	velocity = _get_move_velocity() * _totem_speed_mult()
	move_and_slide()
	_check_player_collision()
	queue_redraw()


func _totem_speed_mult() -> float:
	var m: float = 1.0
	for n in get_tree().get_nodes_in_group("buff_totem"):
		if n == self:
			continue
		if is_instance_valid(n) and n.global_position.distance_to(global_position) < 240.0:
			m *= 1.08
	return m


func _totem_damage_mult() -> float:
	var m: float = 1.0
	for n in get_tree().get_nodes_in_group("buff_totem"):
		if n == self:
			continue
		if is_instance_valid(n) and n.global_position.distance_to(global_position) < 240.0:
			m *= 1.16
	return m


func _effective_contact_damage() -> int:
	return maxi(1, int(round(float(contact_damage) * _totem_damage_mult())))


## 检测与 Player 的碰撞并造成接触伤害（需求 3.3）
func _check_player_collision() -> void:
	if _damage_on_cooldown:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider != null and collider.is_in_group("player"):
			collider.take_damage(_effective_contact_damage())
			_damage_on_cooldown = true
			damage_timer.start()
			break


func _on_damage_timer_timeout() -> void:
	_damage_on_cooldown = false


## 受到伤害，考虑护甲减伤（需求 3.5）
func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	var actual := int(amount * (1.0 - armor))
	actual = max(1, actual)  # 至少造成 1 点伤害
	GameAudio.play_hit_enemy()
	_play_hit_flash()
	current_hp = max(0, current_hp - actual)
	if current_hp <= 0:
		_on_death()


func _play_hit_flash() -> void:
	var tw: Tween = create_tween()
	modulate = Color(1.75, 1.75, 1.85, 1.0)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)


## 死亡处理：生成掉落物、发出信号、销毁自身
func _on_death() -> void:
	_spawn_drops()
	died.emit(self)
	_spawn_splits_if_needed()
	queue_free()


func _spawn_splits_if_needed() -> void:
	if split_spawn_count <= 0:
		return
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena == null or not arena.has_method("spawn_enemy_at"):
		return
	for _i in range(split_spawn_count):
		var off := Vector2(randf_range(-48.0, 48.0), randf_range(-48.0, 48.0))
		arena.spawn_enemy_at(split_spawn_type, global_position + off)


## 生成掉落物，添加到 Arena 的 MaterialContainer（需求 10.1）
func _spawn_drops() -> void:
	# 必掉金币
	_spawn_material("gold", gold_reward)
	# 概率掉落回血果子
	if randf() < drop_heal_chance:
		_spawn_material("heal", 1)
	# 概率掉落绿箱子
	if randf() < drop_box_chance:
		_spawn_material("box", 1)


## 实例化 MaterialDrop 节点并添加到 Arena 的 MaterialContainer
func _spawn_material(mat_id: String, mat_amount: int) -> void:
	var drop_scene: PackedScene = load("res://scenes/material_drop.tscn")
	if drop_scene == null:
		return
	var drop: MaterialDrop = drop_scene.instantiate()
	drop.material_id = mat_id
	drop.amount = mat_amount

	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena and "material_container" in arena:
		arena.material_container.add_child(drop)
		# add_child 之后再设置 global_position，确保节点已入树
		drop.global_position = global_position
		# 连接拾取信号到 Arena
		if arena.has_method("_on_material_collected"):
			drop.collected.connect(arena._on_material_collected.bind(drop))
	else:
		get_tree().current_scene.add_child(drop)
		drop.global_position = global_position
