extends EnemyBase

## 远程型敌人：保持距离，向玩家发射弹幕；被攻击时释放 8 方向弹幕反制
## 需求：11.2

const PREFERRED_DISTANCE: float = 200.0
const SHOOT_INTERVAL: float = 2.0
const BULLET_SPEED: float = 150.0
const RETALIATION_BULLET_COUNT: int = 8

var _shoot_timer: float = 0.0

# 敌人子弹场景（使用与玩家相同的 Projectile，但伤害来源不同）
var _bullet_scene: PackedScene = null


func _ready() -> void:
	super._ready()
	max_hp = 20
	current_hp = 20
	move_speed = 50.0
	contact_damage = 5
	gold_reward = 2
	drop_heal_chance = 0.1
	enemy_type_name = "远程"
	_shoot_timer = randf_range(0.5, SHOOT_INTERVAL)
	# 尝试加载子弹场景
	if ResourceLoader.exists("res://scenes/projectile.tscn"):
		_bullet_scene = load("res://scenes/projectile.tscn")


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	var dist := global_position.distance_to(target.global_position)
	if dist < PREFERRED_DISTANCE - 20.0:
		# 太近，后退
		return (global_position - target.global_position).normalized() * move_speed
	elif dist > PREFERRED_DISTANCE + 50.0:
		# 太远，靠近
		return (target.global_position - global_position).normalized() * move_speed
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and target != null:
		_shoot_timer = SHOOT_INTERVAL
		_fire_at_player()
	super._physics_process(delta)
	queue_redraw()


## 向玩家方向发射单颗子弹
func _fire_at_player() -> void:
	if target == null or _bullet_scene == null:
		return
	var dir := (target.global_position - global_position).normalized()
	_spawn_bullet(dir)


## 被攻击时触发 8 方向弹幕反制
func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if current_hp > 0:
		_fire_retaliation_burst()


func _fire_retaliation_burst() -> void:
	if _bullet_scene == null:
		return
	for i in range(RETALIATION_BULLET_COUNT):
		var angle := (TAU / RETALIATION_BULLET_COUNT) * i
		_spawn_bullet(Vector2.RIGHT.rotated(angle))


## 生成一颗敌人子弹
func _spawn_bullet(dir: Vector2) -> void:
	if _bullet_scene == null:
		return
	var bullet = _bullet_scene.instantiate()
	bullet.direction = dir
	bullet.damage = 8
	# 将子弹添加到场景根节点，避免随敌人销毁
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position


## 外观：紫色菱形 + 魔法眼 + 类型标签
func _draw() -> void:
	# 菱形身体
	var pts: PackedVector2Array = [
		Vector2(0, -22), Vector2(16, 0), Vector2(0, 22), Vector2(-16, 0)
	]
	draw_colored_polygon(pts, Color(0.45, 0.1, 0.75))
	# 中央魔法眼
	draw_circle(Vector2.ZERO, 7.0, Color(0.9, 0.2, 0.9))
	draw_circle(Vector2.ZERO, 3.5, Color(0.1, 0.0, 0.2))
	# 射击准备时发光
	if _shoot_timer < 0.4:
		draw_circle(Vector2.ZERO, 10.0, Color(1, 0.5, 1, 0.4))
	# debug 信息
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.4, 1.0))
	draw_string(font, Vector2(-22, 42), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.5, 0.9))
