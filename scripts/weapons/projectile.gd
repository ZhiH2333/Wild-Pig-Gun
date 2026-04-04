extends Area2D

## 子弹脚本：直线飞行，命中敌人造成伤害，飞出屏幕后自动销毁
## 需求：2.4、2.5、2.6

const SPEED: float = 400.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


## Debug 占位绘制：白色小圆点
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1, 1, 0.4, 1.0))


## 命中物体时：若为敌人则造成伤害并销毁自身
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


## 飞出屏幕时销毁自身，防止内存泄漏
func _on_screen_exited() -> void:
	queue_free()
