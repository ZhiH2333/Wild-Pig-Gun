extends EnemyBase

## 蓄力后直线冲撞，随后短暂硬直

enum Phase { CHASE, WINDUP, RUSH, RECOVER }

const WINDUP_TIME: float = 0.75
const RUSH_TIME: float = 0.38
const RECOVER_TIME: float = 0.55
const RUSH_SPEED: float = 420.0

var _phase: Phase = Phase.CHASE
var _phase_timer: float = 0.0
var _rush_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()
	max_hp = 38
	current_hp = 38
	move_speed = 55.0
	contact_damage = 12
	gold_reward = 2
	enemy_type_name = "冲撞"


func _get_move_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	match _phase:
		Phase.WINDUP:
			return Vector2.ZERO
		Phase.RUSH:
			return _rush_dir * RUSH_SPEED
		Phase.RECOVER:
			return Vector2.ZERO
		_:
			return (target.global_position - global_position).normalized() * move_speed


func _physics_process(delta: float) -> void:
	_phase_timer -= delta
	match _phase:
		Phase.CHASE:
			if target != null and global_position.distance_to(target.global_position) < 280.0:
				_begin_windup()
		Phase.WINDUP:
			if _phase_timer <= 0.0:
				_begin_rush()
		Phase.RUSH:
			if _phase_timer <= 0.0:
				_begin_recover()
		Phase.RECOVER:
			if _phase_timer <= 0.0:
				_phase = Phase.CHASE
	super._physics_process(delta)
	queue_redraw()


func _begin_windup() -> void:
	_phase = Phase.WINDUP
	_phase_timer = WINDUP_TIME
	if target != null:
		_rush_dir = (target.global_position - global_position).normalized()


func _begin_rush() -> void:
	_phase = Phase.RUSH
	_phase_timer = RUSH_TIME


func _begin_recover() -> void:
	_phase = Phase.RECOVER
	_phase_timer = RECOVER_TIME


func _draw() -> void:
	var col: Color = Color(0.85, 0.2, 0.35) if _phase == Phase.RUSH else Color(0.55, 0.15, 0.22)
	if _phase == Phase.WINDUP:
		col = Color(1.0, 0.55, 0.25)
	draw_circle(Vector2.ZERO, 19.0, col)
	draw_rect(Rect2(-8, -6, 6, 4), Color(1, 1, 1))
	draw_rect(Rect2(2, -6, 6, 4), Color(1, 1, 1))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, 28), "[%s]" % enemy_type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.6, 0.65))
	draw_string(font, Vector2(-22, 40), "HP:%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.7, 0.75))
