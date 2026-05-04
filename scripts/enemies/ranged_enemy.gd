extends EnemyBase

## 远程型敌人：保持距离，向玩家发射弹幕；被攻击时释放弹幕反制（带 CD 与次数上限）

const PREFERRED_DISTANCE: float = 200.0
const SHOOT_INTERVAL: float = 2.0
const ENEMY_BULLET_SPEED: float = 150.0
const RETALIATION_BULLET_COUNT: int = 8
const MAX_RETALIATIONS_PER_ENEMY: int = 5

var _shoot_timer: float = 0.0
var _retaliation_count: int = 0

# 敌人子弹场景（使用与玩家相同的 Projectile，但伤害来源不同）
var _bullet_scene: PackedScene = null

@onready var _retaliation_cooldown: Timer = $RetaliationCooldown


func _ready() -> void:
	super._ready()
	is_shop_mechanical = true
	max_hp = 20
	current_hp = 20
	move_speed = 50.0
	contact_damage = 5
	gold_reward = 2
	drop_heal_chance = 0.1
	enemy_type_name = "远程"
	_shoot_timer = randf_range(0.5, SHOOT_INTERVAL)
	if ResourceLoader.exists("res://scenes/projectile.tscn"):
		_bullet_scene = load("res://scenes/projectile.tscn")


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	var dist := global_position.distance_to(target.global_position)
	if dist < PREFERRED_DISTANCE - 20.0:
		return (global_position - target.global_position).normalized() * move_speed
	elif dist > PREFERRED_DISTANCE + 50.0:
		return (target.global_position - global_position).normalized() * move_speed
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	if RunState != null and RunState.stopwatch_frozen:
		super._physics_process(delta)
		queue_redraw()
		return
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


## 被攻击时触发反制（Fly-like，数值收口）
func take_damage(amount: int, is_crit: bool = false, damage_element: StringName = &"physical") -> void:
	super.take_damage(amount, is_crit, damage_element)
	if current_hp <= 0:
		return
	if _retaliation_count >= MAX_RETALIATIONS_PER_ENEMY:
		return
	if _retaliation_cooldown != null and not _retaliation_cooldown.is_stopped():
		return
	_fire_retaliation_burst()
	_retaliation_count += 1
	if _retaliation_cooldown != null:
		_retaliation_cooldown.start()


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
	var bullet: Node = ProjectilePool.get_projectile(_bullet_scene)
	if bullet == null:
		return
	if bullet is Projectile:
		var p: Projectile = bullet as Projectile
		p.direction = dir
		p.damage = 8
		p.team = Projectile.TEAM_ENEMY
		p.speed = ENEMY_BULLET_SPEED
	var container: Node = _get_projectile_container()
	# 玩家子弹的 body_entered 里会同步调用 take_damage → 反制生成子弹；若在查询刷新中
	# add_child(Area2D) 会触发 area_set_shape_disabled 报错，须推迟入树。
	if bullet is Node2D and container is Node2D:
		(bullet as Node2D).position = (container as Node2D).to_local(global_position)
	elif bullet is Node2D:
		(bullet as Node2D).global_position = global_position
	container.call_deferred("add_child", bullet)


func _get_projectile_container() -> Node:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null:
		var c: Node = arena.get_node_or_null("ProjectileContainer")
		if c != null:
			return c
	var root: Node = get_tree().get_root()
	var found: Node = root.find_child("ProjectileContainer", true, false)
	if found != null:
		return found
	return get_tree().current_scene


## 外观：紫色菱形 + 魔法眼 + 类型标签
func _draw() -> void:
	var pts: PackedVector2Array = [
		Vector2(0, -22), Vector2(16, 0), Vector2(0, 22), Vector2(-16, 0)
	]
	draw_colored_polygon(pts, Color(0.45, 0.1, 0.75))
	draw_circle(Vector2.ZERO, 7.0, Color(0.9, 0.2, 0.9))
	draw_circle(Vector2.ZERO, 3.5, Color(0.1, 0.0, 0.2))
	if _shoot_timer < 0.4:
		draw_circle(Vector2.ZERO, 10.0, Color(1, 0.5, 1, 0.4))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 30), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.8, 0.4, 1.0))
	draw_string(font, Vector2(-22, 46), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_HP, Color(0.7, 0.5, 0.9))
