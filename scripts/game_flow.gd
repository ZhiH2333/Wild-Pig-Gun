extends Node

## 全局输入：战斗中 ESC 切换暂停（波间打开时不响应）


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	var arena: Node = get_tree().get_first_node_in_group("arena")
	RunState.try_toggle_user_pause(arena)
