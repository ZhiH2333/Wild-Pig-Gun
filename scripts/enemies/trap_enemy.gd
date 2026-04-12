extends EnemyBase

## 在玩家脚下周期性放置短时伤害陷阱

const TRAP_INTERVAL: float = 2.6

var _trap_cd: float = 1.0


func _ready() -> void:
	super._ready()
	max_hp = 26
	current_hp = 26
	move_speed = 58.0
	contact_damage = 6
	gold_reward = 2
	enemy_type_name = "陷阱师"
	_trap_cd = randf_range(0.4, TRAP_INTERVAL)


func _physics_process(delta: float) -> void:
	_trap_cd -= delta
	if _trap_cd <= 0.0 and target != null:
		_trap_cd = TRAP_INTERVAL
		_spawn_trap_at(target.global_position)
	super._physics_process(delta)


func _spawn_trap_at(pos: Vector2) -> void:
	var path: String = "res://scenes/enemies/ground_trap_hazard.tscn"
	if not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path) as PackedScene
	var h: Node2D = scene.instantiate() as Node2D
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena == null:
		return
	arena.add_child(h)
	h.global_position = pos


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	var d: float = global_position.distance_to(target.global_position)
	if d < 220.0:
		return (global_position - target.global_position).normalized() * move_speed
	return (target.global_position - global_position).normalized() * move_speed * 0.5


func _draw() -> void:
	draw_rect(Rect2(-14, -18, 28, 36), Color(0.35, 0.28, 0.5))
	draw_rect(Rect2(-10, -10, 20, 8), Color(0.9, 0.2, 0.2, 0.7))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-24, 28), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, OVERHEAD_FONT_SIZE_NAME, Color(0.85, 0.75, 1.0))
