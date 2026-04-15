extends Node

## 挂载在 VirtualJoystickLayer（CanvasLayer）上，负责在局内读取并应用自定义控件布局。
## 坐标系：底边锚定，不受摇杆缩放影响。

const BASE_OUTER_RADIUS: float = 88.0
const PAUSE_BTN_REF_W: float = 220.0
const PAUSE_BTN_REF_H: float = 84.0

var _joystick: Control = null
var _pause_btn: Control = null


func _ready() -> void:
	_joystick = get_node_or_null("VirtualJoystick") as Control
	_pause_btn = get_node_or_null("MobilePauseButton") as Control
	GameSettings.mobile_control_layout_changed.connect(_on_layout_changed)
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)
	call_deferred("_apply_layout")
	await get_tree().process_frame
	_apply_layout()
	await get_tree().process_frame
	_apply_layout()


func _on_layout_changed() -> void:
	_apply_layout()


func _on_mobile_controls_changed(_enabled: bool) -> void:
	_apply_layout()


func _apply_layout() -> void:
	if _joystick == null or _pause_btn == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		return
	var vj: Dictionary = GameSettings.get_mobile_control_entry("virtual_joystick")
	var pb: Dictionary = GameSettings.get_mobile_control_entry("mobile_pause")
	_apply_joystick_entry(_joystick, vj, vp_size)
	_apply_pause_entry(_pause_btn, pb, vp_size)


## 摇杆：底边锚定坐标系——左边距和底边距保持固定比例，scale 只改变尺寸不移动角落
func _apply_joystick_entry(node: Control, entry: Dictionary, vp_size: Vector2) -> void:
	var s: float = clampf(
		float(entry.get("scale", 1.0)),
		GameSettings.JOYSTICK_SIZE_MIN, GameSettings.JOYSTICK_SIZE_MAX
	)
	var sz: float = BASE_OUTER_RADIUS * 2.0 * s
	var norm_left: float = clampf(float(entry.get("norm_left", 0.0104)), 0.0, 1.0)
	var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.0185)), 0.0, 0.5)
	if node.has_method("set_manual_scale"):
		node.set_manual_scale(s)
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.custom_minimum_size = Vector2(sz, sz)
	node.size = Vector2(sz, sz)
	var left: float = vp_size.x * norm_left
	var top: float = vp_size.y - sz - vp_size.y * norm_bm
	node.position = Vector2(
		clampf(left, 0.0, vp_size.x - sz),
		clampf(top, 0.0, vp_size.y - sz),
	)


## 暂停按钮：底边中心锚定——横向中心比例和底边距保持固定
func _apply_pause_entry(node: Control, entry: Dictionary, vp_size: Vector2) -> void:
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	var norm_cx: float = clampf(float(entry.get("norm_center_x", 0.5)), 0.0, 1.0)
	var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.026)), 0.0, 0.5)
	node.scale = Vector2(s, s)
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var visual_w: float = PAUSE_BTN_REF_W * s
	var visual_h: float = PAUSE_BTN_REF_H * s
	var center_x: float = vp_size.x * norm_cx
	var top: float = vp_size.y - visual_h - vp_size.y * norm_bm
	node.position = Vector2(
		clampf(center_x - visual_w * 0.5, 0.0, vp_size.x - visual_w),
		clampf(top, 0.0, vp_size.y - visual_h),
	)
