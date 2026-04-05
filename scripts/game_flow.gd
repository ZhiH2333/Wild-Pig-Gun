extends Node

## 全局输入：战斗中 ESC 切换暂停（波间打开时不响应）
## Web：失焦暂停

var _web_focus_pause_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if OS.get_name() != "Web":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if RunState.pause_reason != RunState.PauseReason.INTERSTITIAL:
			_web_focus_pause_active = true
			get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if _web_focus_pause_active:
			_web_focus_pause_active = false
			if RunState.pause_reason != RunState.PauseReason.INTERSTITIAL:
				get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	var arena: Node = get_tree().get_first_node_in_group("arena")
	RunState.try_toggle_user_pause(arena)
