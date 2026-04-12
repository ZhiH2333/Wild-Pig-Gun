extends Control

## 仅 Android：输出模拟方向，长度 0~1
const STICK_MAX: float = 80.0

var output_vector: Vector2 = Vector2.ZERO
var _active_index: int = -1


func _ready() -> void:
	add_to_group("virtual_joystick")
	if not OS.has_feature("android"):
		visible = false
		set_process_input(false)


func get_output() -> Vector2:
	return output_vector


func _gui_input(event: InputEvent) -> void:
	if not OS.has_feature("android"):
		return
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_active_index = st.index
			_update_vector(st.position)
		elif st.index == _active_index:
			_active_index = -1
			output_vector = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		if sd.index == _active_index:
			_update_vector(sd.position)


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
	if not OS.has_feature("android"):
		return
	var c: Vector2 = size * 0.5
	draw_circle(c, 88.0, Color(0.15, 0.15, 0.18, 0.65))
	draw_arc(c, 88.0, 0.0, TAU, 32, Color(0.5, 0.5, 0.55, 0.5), 2.5)
	var stick: Vector2 = output_vector * STICK_MAX
	draw_circle(c + stick, 28.0, Color(0.9, 0.85, 0.3, 0.85))
