extends Node2D

## 地面陷阱：短暂存在，玩家踏入受伤

const DAMAGE: int = 12
const LIFETIME: float = 1.35

var _elapsed: float = 0.0


func _ready() -> void:
	var a: Area2D = Area2D.new()
	a.monitoring = true
	a.collision_layer = 0
	a.collision_mask = 1
	var sh: CollisionShape2D = CollisionShape2D.new()
	var circ: CircleShape2D = CircleShape2D.new()
	circ.radius = 28.0
	sh.shape = circ
	a.add_child(sh)
	a.body_entered.connect(_on_body_entered)
	add_child(a)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)


func _draw() -> void:
	var alpha: float = 1.0 - clampf(_elapsed / LIFETIME, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 28.0, Color(1.0, 0.25, 0.15, 0.35 * alpha))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 20, Color(1.0, 0.5, 0.2, 0.6 * alpha), 2.0, true)
