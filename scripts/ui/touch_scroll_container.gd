extends ScrollContainer

## 支持触控拖动滚动的容器
## 解决 Godot 4 中子按钮消耗触控事件导致无法手指滑动列表的问题
## 使用 _input 级别拦截触控拖拽，绕过子节点的事件消耗

const _DRAG_THRESHOLD: float = 8.0

var _touch_index: int = -1
var _drag_start: Vector2 = Vector2.ZERO
var _scroll_start_v: int = 0
var _is_scrolling: bool = false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(st: InputEventScreenTouch) -> void:
	if st.pressed:
		var global_rect: Rect2 = get_global_rect()
		if global_rect.has_point(st.position):
			_touch_index = st.index
			_drag_start = st.position
			_scroll_start_v = scroll_vertical
			_is_scrolling = false
	elif st.index == _touch_index:
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
