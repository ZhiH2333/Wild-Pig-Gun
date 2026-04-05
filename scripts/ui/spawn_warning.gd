extends Node2D
## 红叉预警节点：显示 0.8 秒后自动销毁

const DURATION: float = 0.8

func _ready() -> void:
	# 闪烁效果
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	tween.tween_callback(queue_free)
