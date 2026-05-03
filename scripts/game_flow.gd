extends Node

## 全局输入：战斗中 ESC 切换暂停（波间打开时不响应）
## Web：失焦暂停；进入页面后请求浏览器全屏（启动时延迟尝试 + 用户手势时重试）

var _web_focus_pause_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		set_process_input(true)
		call_deferred("web_try_request_fullscreen")


func _notification(what: int) -> void:
	if OS.get_name() != "Web":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if RunState.pause_reason != RunState.PauseReason.NONE:
			return
		if get_tree().paused:
			return
		_web_focus_pause_active = true
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if not _web_focus_pause_active:
			return
		_web_focus_pause_active = false
		if RunState.pause_reason == RunState.PauseReason.NONE:
			get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not OS.has_feature("web"):
		return
	if not _web_is_user_activation_event(event):
		return
	web_try_request_fullscreen()


## 浏览器全屏：多数环境需在用户手势内触发，故在每次有效按键/点击/触摸时尝试直至已进入全屏
func web_try_request_fullscreen() -> void:
	if not OS.has_feature("web"):
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var jsb: Object = Engine.get_singleton("JavaScriptBridge")
	if jsb != null and jsb.has_method("eval"):
		jsb.eval(
			"(function(){var e=document.documentElement;" +
			"var r=e.requestFullscreen||e.webkitRequestFullscreen||e.mozRequestFullScreen||e.msRequestFullscreen;" +
			"if(r)r.call(e).catch(function(){});})()",
			true
		)


func _web_is_user_activation_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var ek: InputEventKey = event as InputEventKey
		return ek.pressed and not ek.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and arena.has_method("_on_pause_resume_pressed"):
		arena._on_pause_resume_pressed()
		return
	RunState.try_toggle_user_pause(arena)
