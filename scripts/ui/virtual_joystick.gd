extends Control

const STICK_MAX_BASE: float = 80.0
const BASE_OUTER_RADIUS: float = 88.0
const BASE_INNER_RADIUS: float = 28.0
const DEAD_ZONE: float = 12.0

@export var register_in_group: bool = true
@export var allow_input: bool = true
@export var force_visible: bool = false

var output_vector: Vector2 = Vector2.ZERO
var _active_index: int = -1
var _is_mouse_dragging: bool = false
var _manual_scale: float = -1.0


func _ready() -> void:
	if register_in_group:
		add_to_group("virtual_joystick")
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)
	GameSettings.joystick_size_changed.connect(_on_joystick_size_changed)
	_refresh_visibility()
	_apply_size()


func get_output() -> Vector2:
	return output_vector


func set_manual_scale(scale_value: float) -> void:
	_manual_scale = clampf(scale_value, GameSettings.JOYSTICK_SIZE_MIN, GameSettings.JOYSTICK_SIZE_MAX)
	_apply_size()


func clear_manual_scale() -> void:
	_manual_scale = -1.0
	_apply_size()


func _gui_input(event: InputEvent) -> void:
	if not allow_input:
		return
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
	var scale: float = _get_effective_scale()
	var stick_max: float = STICK_MAX_BASE * scale
	var dead_zone: float = DEAD_ZONE * scale
	var center: Vector2 = size * 0.5
	var delta: Vector2 = local_pos - center
	var len: float = delta.length()
	if len < dead_zone:
		output_vector = Vector2.ZERO
		return
	var dir: Vector2 = delta / len
	var mag: float = minf(len / stick_max, 1.0)
	output_vector = dir * mag
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var scale: float = _get_effective_scale()
	var outer_r: float = BASE_OUTER_RADIUS * scale
	var inner_r: float = BASE_INNER_RADIUS * scale
	var stick_max: float = STICK_MAX_BASE * scale
	var c: Vector2 = size * 0.5
	draw_circle(c, outer_r, Color(0.15, 0.15, 0.18, 0.65))
	draw_arc(c, outer_r, 0.0, TAU, 32, Color(0.5, 0.5, 0.55, 0.5), 2.5)
	var stick: Vector2 = output_vector * stick_max
	draw_circle(c + stick, inner_r, Color(0.9, 0.85, 0.3, 0.85))


func _on_mobile_controls_changed(_enabled: bool) -> void:
	_refresh_visibility()


func _on_joystick_size_changed(_new_size: float) -> void:
	_apply_size()


func _apply_size() -> void:
	var scale: float = _get_effective_scale()
	var total_size: float = BASE_OUTER_RADIUS * 2.0 * scale
	custom_minimum_size = Vector2(total_size, total_size)
	queue_redraw()


func _refresh_visibility() -> void:
	if force_visible:
		visible = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE if not allow_input else Control.MOUSE_FILTER_STOP
		queue_redraw()
		return
	visible = GameSettings.mobile_controls_enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		output_vector = Vector2.ZERO
		_active_index = -1
		_is_mouse_dragging = false
	queue_redraw()


func _get_effective_scale() -> float:
	if _manual_scale > 0.0:
		return _manual_scale
	return GameSettings.joystick_size
