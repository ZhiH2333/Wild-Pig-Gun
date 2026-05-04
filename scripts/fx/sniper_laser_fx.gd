extends Line2D

const FADE_SEC: float = 0.16


func _ready() -> void:
	z_index = 22
	width = 2.8
	default_color = Color(1.0, 0.12, 0.12, 0.92)
	var tw: Tween = create_tween()
	tw.tween_property(self, "default_color:a", 0.0, FADE_SEC)
	tw.finished.connect(_queue_free_self)


func _queue_free_self() -> void:
	if is_instance_valid(self):
		queue_free()
