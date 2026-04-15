extends Control

## 自定义控件布局编辑器
## 坐标系：底边锚定（norm_left / norm_bottom_margin）——与 virtual_controls_layout_host 完全一致

enum ControlId { NONE, VIRTUAL_JOYSTICK, MOBILE_PAUSE }

const BASE_OUTER_RADIUS: float = 88.0
const PAUSE_BTN_REF_W: float = 220.0
const PAUSE_BTN_REF_H: float = 84.0
const TOAST_DURATION: float = 1.5

var _pending_layout: Dictionary = {}
var _selected_id: ControlId = ControlId.NONE
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _toast_timer: float = 0.0

@onready var _back_btn: Button = $TopBar/BackBtn
@onready var _preview_container: Control = $PreviewContainer
@onready var _controls_overlay: Control = $ControlsOverlay
@onready var _joystick_widget: Control = $ControlsOverlay/JoystickWidget
@onready var _pause_widget: Control = $ControlsOverlay/PauseWidget
@onready var _selection_menu: Control = $SelectionMenu
@onready var _scale_down_btn: Button = $SelectionMenu/PanelContainer/Row/ScaleDownBtn
@onready var _scale_up_btn: Button = $SelectionMenu/PanelContainer/Row/ScaleUpBtn
@onready var _scale_label: Label = $SelectionMenu/PanelContainer/Row/ScaleLabel
@onready var _reset_btn: Button = $SelectionMenu/PanelContainer/Row/ResetBtn
@onready var _save_btn: Button = $SelectionMenu/PanelContainer/Row/SaveBtn
@onready var _saved_toast: Label = $SavedToast


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_selection_menu.visible = false
	_saved_toast.visible = false
	_pending_layout = {
		"virtual_joystick": GameSettings.get_mobile_control_entry("virtual_joystick"),
		"mobile_pause": GameSettings.get_mobile_control_entry("mobile_pause"),
	}
	_back_btn.pressed.connect(_on_back_pressed)
	_scale_down_btn.pressed.connect(_on_scale_down)
	_scale_up_btn.pressed.connect(_on_scale_up)
	_reset_btn.pressed.connect(_on_reset_pressed)
	_save_btn.pressed.connect(_on_save_pressed)
	if _joystick_widget.has_method("set_allow_input"):
		_joystick_widget.set_allow_input(false)
	if _joystick_widget.has_method("set_force_visible"):
		_joystick_widget.set_force_visible(true)
	if _pause_widget.has_method("set_allow_input"):
		_pause_widget.set_allow_input(false)
	if _pause_widget.has_method("set_force_visible"):
		_pause_widget.set_force_visible(true)
	await get_tree().process_frame
	_refresh_all_widgets()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_saved_toast.visible = false


func _gui_input(event: InputEvent) -> void:
	var container_rect: Rect2 = _preview_container.get_global_rect()
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var hit: ControlId = _hit_test(mb.global_position, container_rect)
			if hit != ControlId.NONE:
				_selected_id = hit
				_is_dragging = true
				var widget: Control = _get_widget(_selected_id)
				_drag_offset = mb.global_position - widget.global_position
				_refresh_selection_menu()
				accept_event()
			else:
				_selected_id = ControlId.NONE
				_is_dragging = false
				_refresh_selection_menu()
		else:
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_drag_widget(mm.global_position, container_rect)
		accept_event()


func _hit_test(global_pos: Vector2, container_rect: Rect2) -> ControlId:
	if not container_rect.has_point(global_pos):
		return ControlId.NONE
	if _pause_widget.get_global_rect().has_point(global_pos):
		return ControlId.MOBILE_PAUSE
	if _joystick_widget.get_global_rect().has_point(global_pos):
		return ControlId.VIRTUAL_JOYSTICK
	return ControlId.NONE


func _drag_widget(global_pos: Vector2, container_rect: Rect2) -> void:
	var widget: Control = _get_widget(_selected_id)
	var new_pos: Vector2 = global_pos - _drag_offset
	var sz_x: float = widget.size.x
	var sz_y: float = widget.size.y
	new_pos.x = clampf(new_pos.x, container_rect.position.x, container_rect.end.x - sz_x)
	new_pos.y = clampf(new_pos.y, container_rect.position.y, container_rect.end.y - sz_y)
	widget.global_position = new_pos
	var key: String = _id_to_key(_selected_id)
	if _selected_id == ControlId.VIRTUAL_JOYSTICK:
		_pending_layout[key]["norm_left"] = clampf(
			(new_pos.x - container_rect.position.x) / container_rect.size.x, 0.0, 1.0)
		_pending_layout[key]["norm_bottom_margin"] = clampf(
			(container_rect.end.y - new_pos.y - sz_y) / container_rect.size.y, 0.0, 0.5)
	else:
		var s: float = clampf(float(_pending_layout[key].get("scale", 1.0)), 0.5, 2.0)
		var center_x: float = new_pos.x + PAUSE_BTN_REF_W * s * 0.5
		_pending_layout[key]["norm_center_x"] = clampf(
			(center_x - container_rect.position.x) / container_rect.size.x, 0.0, 1.0)
		_pending_layout[key]["norm_bottom_margin"] = clampf(
			(container_rect.end.y - new_pos.y - PAUSE_BTN_REF_H * s) / container_rect.size.y, 0.0, 0.5)


func _refresh_all_widgets() -> void:
	_apply_widget(ControlId.VIRTUAL_JOYSTICK)
	_apply_widget(ControlId.MOBILE_PAUSE)


## 根据 _pending_layout 将控件放置到屏幕上（与 layout_host 完全对称的坐标计算）
func _apply_widget(id: ControlId) -> void:
	var container_rect: Rect2 = _preview_container.get_global_rect()
	if container_rect.size == Vector2.ZERO:
		return
	var key: String = _id_to_key(id)
	var entry: Dictionary = _pending_layout.get(key, {}) as Dictionary
	var widget: Control = _get_widget(id)
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	if id == ControlId.VIRTUAL_JOYSTICK:
		var sz: float = BASE_OUTER_RADIUS * 2.0 * s
		if widget.has_method("set_manual_scale"):
			widget.set_manual_scale(s)
		widget.custom_minimum_size = Vector2(sz, sz)
		widget.size = Vector2(sz, sz)
		var norm_left: float = clampf(float(entry.get("norm_left", 0.0104)), 0.0, 1.0)
		var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.0185)), 0.0, 0.5)
		var left: float = container_rect.position.x + container_rect.size.x * norm_left
		var top: float = container_rect.end.y - sz - container_rect.size.y * norm_bm
		left = clampf(left, container_rect.position.x, container_rect.end.x - sz)
		top = clampf(top, container_rect.position.y, container_rect.end.y - sz)
		widget.global_position = Vector2(left, top)
		# 回写实际位置确保 pending_layout 与屏幕一致
		var w: float = container_rect.size.x
		var h: float = container_rect.size.y
		_pending_layout[key]["norm_left"] = (left - container_rect.position.x) / w
		_pending_layout[key]["norm_bottom_margin"] = (container_rect.end.y - top - sz) / h
	else:
		var visual_w: float = PAUSE_BTN_REF_W * s
		var visual_h: float = PAUSE_BTN_REF_H * s
		if widget.has_method("set_scale_factor"):
			widget.set_scale_factor(s)
		widget.scale = Vector2(s, s)
		var norm_cx: float = clampf(float(entry.get("norm_center_x", 0.5)), 0.0, 1.0)
		var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.026)), 0.0, 0.5)
		var center_x: float = container_rect.position.x + container_rect.size.x * norm_cx
		var top: float = container_rect.end.y - visual_h - container_rect.size.y * norm_bm
		var left: float = center_x - visual_w * 0.5
		left = clampf(left, container_rect.position.x, container_rect.end.x - visual_w)
		top = clampf(top, container_rect.position.y, container_rect.end.y - visual_h)
		widget.global_position = Vector2(left, top)
		var pw: float = container_rect.size.x
		var ph: float = container_rect.size.y
		_pending_layout[key]["norm_center_x"] = (left + visual_w * 0.5 - container_rect.position.x) / pw
		_pending_layout[key]["norm_bottom_margin"] = (container_rect.end.y - top - visual_h) / ph


func _refresh_selection_menu() -> void:
	if _selected_id == ControlId.NONE:
		_selection_menu.visible = false
		return
	_selection_menu.visible = true
	var key: String = _id_to_key(_selected_id)
	var entry: Dictionary = _pending_layout.get(key, {}) as Dictionary
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	_scale_label.text = "%d%%" % int(round(s * 100.0))
	var widget: Control = _get_widget(_selected_id)
	var container_rect: Rect2 = _preview_container.get_global_rect()
	await get_tree().process_frame
	var menu_w: float = _selection_menu.size.x
	var menu_h: float = _selection_menu.size.y
	var wx: float = widget.global_position.x
	var wy: float = widget.global_position.y
	var cx: float = wx + widget.size.x * 0.5
	var menu_x: float = clampf(
		cx - menu_w * 0.5, container_rect.position.x, container_rect.end.x - menu_w)
	var menu_y: float = clampf(
		wy - menu_h - 8.0, container_rect.position.y, container_rect.end.y - menu_h)
	_selection_menu.global_position = Vector2(menu_x, menu_y)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_scale_down() -> void:
	if _selected_id == ControlId.NONE:
		return
	var key: String = _id_to_key(_selected_id)
	var current: float = clampf(float(_pending_layout[key].get("scale", 1.0)), 0.5, 2.0)
	_pending_layout[key]["scale"] = clampf(roundf((current - 0.25) * 4.0) / 4.0, 0.5, 2.0)
	_apply_widget(_selected_id)
	_refresh_selection_menu()


func _on_scale_up() -> void:
	if _selected_id == ControlId.NONE:
		return
	var key: String = _id_to_key(_selected_id)
	var current: float = clampf(float(_pending_layout[key].get("scale", 1.0)), 0.5, 2.0)
	_pending_layout[key]["scale"] = clampf(roundf((current + 0.25) * 4.0) / 4.0, 0.5, 2.0)
	_apply_widget(_selected_id)
	_refresh_selection_menu()


func _on_reset_pressed() -> void:
	if _selected_id == ControlId.NONE:
		return
	var key: String = _id_to_key(_selected_id)
	if _selected_id == ControlId.VIRTUAL_JOYSTICK:
		_pending_layout[key] = GameSettings.LAYOUT_VJ_DEFAULT.duplicate()
	else:
		_pending_layout[key] = GameSettings.LAYOUT_PAUSE_DEFAULT.duplicate()
	_apply_widget(_selected_id)
	_refresh_selection_menu()


func _on_save_pressed() -> void:
	GameSettings.set_mobile_control_entry("virtual_joystick", _pending_layout["virtual_joystick"])
	GameSettings.set_mobile_control_entry("mobile_pause", _pending_layout["mobile_pause"])
	var vj_scale: float = clampf(float(_pending_layout["virtual_joystick"].get("scale", 1.0)),
		GameSettings.JOYSTICK_SIZE_MIN, GameSettings.JOYSTICK_SIZE_MAX)
	GameSettings.set_joystick_size(vj_scale)
	_saved_toast.visible = true
	_toast_timer = TOAST_DURATION


func _get_widget(id: ControlId) -> Control:
	if id == ControlId.VIRTUAL_JOYSTICK:
		return _joystick_widget
	return _pause_widget


func _id_to_key(id: ControlId) -> String:
	if id == ControlId.VIRTUAL_JOYSTICK:
		return "virtual_joystick"
	return "mobile_pause"
