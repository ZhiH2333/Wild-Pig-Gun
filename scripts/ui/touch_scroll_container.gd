extends ScrollContainer

## 支持触控拖动滚动的容器
## 双重防护策略：
##   1. project.godot 关闭 emulate_mouse_from_touch，从源头阻断触控→鼠标模拟
##   2. 若仍有模拟鼠标事件漏入，在滚动结束后拦截一次鼠标释放，防止触发子按钮

const _DRAG_THRESHOLD: float = 8.0

var _touch_index: int = -1
var _drag_start: Vector2 = Vector2.ZERO
var _scroll_start_v: int = 0
var _is_scrolling: bool = false
var _block_next_mouse_release: bool = false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_guard_simulated_mouse_release(event as InputEventMouseButton)


func _handle_touch(st: InputEventScreenTouch) -> void:
	if st.pressed:
		var global_rect: Rect2 = get_global_rect()
		if global_rect.has_point(st.position):
			_touch_index = st.index
			_drag_start = st.position
			_scroll_start_v = scroll_vertical
			_is_scrolling = false
	elif st.index == _touch_index:
		if _is_scrolling:
			_block_next_mouse_release = true
		_touch_index = -1
		_is_scrolling = false


func _handle_drag(sd: InputEventScreenDrag) -> void:
	if sd.index != _touch_index:
		return
	var delta: Vector2 = sd.position - _drag_start
	if not _is_scrolling and abs(delta.y) > _DRAG_THRESHOLD:
		_is_scrolling = true
	if _is_scrolling:
		scroll_vertical = _scroll_start_v - int(delta.y)
		get_viewport().set_input_as_handled()


func _guard_simulated_mouse_release(mb: InputEventMouseButton) -> void:
	if not _block_next_mouse_release:
		return
	if not get_global_rect().has_point(mb.global_position):
		_block_next_mouse_release = false
		return
	get_viewport().set_input_as_handled()
	if not mb.pressed:
		_block_next_mouse_release = false
