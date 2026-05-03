extends Node

## 挂载在 VirtualJoystickLayer（CanvasLayer）上，负责在局内读取并应用自定义控件布局。
## 坐标系：底边锚定，不受摇杆缩放影响。

const BASE_OUTER_RADIUS: float = 88.0
const PAUSE_BTN_REF_W: float = 220.0
const PAUSE_BTN_REF_H: float = 84.0
## 与 `consumable_skill_dock.gd` 中方格尺寸保持同步（6 格 + 间距 + 下方说明行）
const CONSUMABLE_DOCK_REF_W: float = 6.0 * 56.0 + 5.0 * 4.0
## 须与 ConsumableSkillDock.layout_ref_total_height() 一致（56+2+14）
const CONSUMABLE_DOCK_REF_H: float = 72.0
## 角色技能正方形按键基准边长（与布局编辑器、mobile_skill_button 一致）
const CHARACTER_SKILL_SLOT_REF: float = 72.0
## 攻击范围键与技能格同基准边长
const ATTACK_RANGE_BUTTON_REF: float = 72.0

var _joystick: Control = null
var _pause_btn: Control = null
var _skill_slot_1: Control = null
var _skill_slot_2: Control = null
var _skill_slot_3: Control = null
var _attack_range_btn: Control = null


func _ready() -> void:
	_joystick = get_node_or_null("VirtualJoystick") as Control
	_pause_btn = get_node_or_null("MobilePauseButton") as Control
	_skill_slot_1 = get_node_or_null("MobileSkillSlot1") as Control
	_skill_slot_2 = get_node_or_null("MobileSkillSlot2") as Control
	_skill_slot_3 = get_node_or_null("MobileSkillSlot3") as Control
	_attack_range_btn = get_node_or_null("MobileAttackRangeButton") as Control
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
	var csb: Dictionary = GameSettings.get_mobile_control_entry("consumable_skill_bar")
	_apply_joystick_entry(_joystick, vj, vp_size)
	_apply_pause_entry(_pause_btn, pb, vp_size)
	var dock: Control = get_tree().get_first_node_in_group("consumable_skill_bar") as Control
	if dock != null:
		_apply_consumable_bar_entry(dock, csb, vp_size)
	var e1: Dictionary = GameSettings.get_mobile_control_entry("character_skill_slot_1")
	var e2: Dictionary = GameSettings.get_mobile_control_entry("character_skill_slot_2")
	var e3: Dictionary = GameSettings.get_mobile_control_entry("character_skill_slot_3")
	if _skill_slot_1 != null:
		_apply_character_skill_slot_entry(_skill_slot_1, e1, vp_size)
	if _skill_slot_2 != null:
		_apply_character_skill_slot_entry(_skill_slot_2, e2, vp_size)
	if _skill_slot_3 != null:
		_apply_character_skill_slot_entry(_skill_slot_3, e3, vp_size)
	var ear: Dictionary = GameSettings.get_mobile_control_entry("attack_range_button")
	if _attack_range_btn != null:
		_apply_attack_range_button_entry(_attack_range_btn, ear, vp_size)


func _apply_attack_range_button_entry(node: Control, entry: Dictionary, vp_size: Vector2) -> void:
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	var dim: float = ATTACK_RANGE_BUTTON_REF * s
	node.scale = Vector2.ONE
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.custom_minimum_size = Vector2(dim, dim)
	node.size = Vector2(dim, dim)
	var norm_rm: float = clampf(float(entry.get("norm_right_margin", 0.10)), 0.0, 0.5)
	var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.20)), 0.0, 0.5)
	var left: float = vp_size.x - vp_size.x * norm_rm - dim
	var top: float = vp_size.y - vp_size.y * norm_bm - dim
	node.position = Vector2(
		clampf(left, 0.0, vp_size.x - dim),
		clampf(top, 0.0, vp_size.y - dim),
	)


func _apply_character_skill_slot_entry(node: Control, entry: Dictionary, vp_size: Vector2) -> void:
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	var dim: float = CHARACTER_SKILL_SLOT_REF * s
	node.scale = Vector2.ONE
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.custom_minimum_size = Vector2(dim, dim)
	node.size = Vector2(dim, dim)
	var norm_rm: float = clampf(float(entry.get("norm_right_margin", 0.015)), 0.0, 0.5)
	var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.22)), 0.0, 0.5)
	var left: float = vp_size.x - vp_size.x * norm_rm - dim
	var top: float = vp_size.y - vp_size.y * norm_bm - dim
	node.position = Vector2(
		clampf(left, 0.0, vp_size.x - dim),
		clampf(top, 0.0, vp_size.y - dim),
	)


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


## 消耗品 1–6 条：与暂停按钮相同的底边中心锚定，参考宽为槽位总宽
func _apply_consumable_bar_entry(node: Control, entry: Dictionary, vp_size: Vector2) -> void:
	var s: float = clampf(float(entry.get("scale", 1.0)), 0.5, 2.0)
	var norm_cx: float = clampf(float(entry.get("norm_center_x", 0.5)), 0.0, 1.0)
	var norm_bm: float = clampf(float(entry.get("norm_bottom_margin", 0.022)), 0.0, 0.5)
	node.scale = Vector2(s, s)
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var visual_w: float = CONSUMABLE_DOCK_REF_W * s
	var visual_h: float = CONSUMABLE_DOCK_REF_H * s
	var center_x: float = vp_size.x * norm_cx
	var top: float = vp_size.y - visual_h - vp_size.y * norm_bm
	node.position = Vector2(
		clampf(center_x - visual_w * 0.5, 0.0, vp_size.x - visual_w),
		clampf(top, 0.0, vp_size.y - visual_h),
	)
