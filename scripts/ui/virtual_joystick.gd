extends Control

const STICK_MAX: float = 80.0

var output_vector: Vector2 = Vector2.ZERO
var _active_index: int = -1
var _is_mouse_dragging: bool = false


func _ready() -> void:
	add_to_group("virtual_joystick")
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)
	_refresh_visibility()


func get_output() -> Vector2:
	return output_vector


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_active_index = st.index
			_update_vector(st.position)
		elif st.index == _active_index:
			_active_index = -1
			output_vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		if sd.index == _active_index:
			_update_vector(sd.position)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_is_mouse_dragging = true
			_update_vector(mb.position)
		else:
			_is_mouse_dragging = false
			output_vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion:
		if not _is_mouse_dragging:
			return
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_update_vector(mm.position)


func _update_vector(local_pos: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var delta: Vector2 = local_pos - center
	var len: float = delta.length()
	if len < 12.0:
		output_vector = Vector2.ZERO
		return
	var dir: Vector2 = delta / len
	var mag: float = minf(len / STICK_MAX, 1.0)
	output_vector = dir * mag
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var c: Vector2 = size * 0.5
	draw_circle(c, 88.0, Color(0.15, 0.15, 0.18, 0.65))
	draw_arc(c, 88.0, 0.0, TAU, 32, Color(0.5, 0.5, 0.55, 0.5), 2.5)
	var stick: Vector2 = output_vector * STICK_MAX
	draw_circle(c + stick, 28.0, Color(0.9, 0.85, 0.3, 0.85))


func _on_mobile_controls_changed(_enabled: bool) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	visible = GameSettings.mobile_controls_enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		output_vector = Vector2.ZERO
		_active_index = -1
		_is_mouse_dragging = false
	queue_redraw()
