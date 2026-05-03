extends Control
class_name ConsumableSkillDock

## 触控模式底栏：1–6 消耗品槽（Minecraft 热键栏式方格），与 `ConsumableHotkeySlots` 及 `arena.use_consumable_slot` 一致

## 方格边长与间距（与 `virtual_controls_layout_host` / 布局编辑器中的参考尺寸保持同步）
const LAYOUT_REF_CELL: float = 56.0
const LAYOUT_REF_SEP: float = 4.0

const _CHS = preload("res://scripts/game/consumable_hotkey_slots.gd")
const FONT_BOLD: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")

static func layout_ref_total_width() -> float:
	return 6.0 * LAYOUT_REF_CELL + 5.0 * LAYOUT_REF_SEP


@onready var _row: HBoxContainer = $HBoxContainer


func _ready() -> void:
	add_to_group("consumable_skill_bar")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_row.add_theme_constant_override("separation", int(LAYOUT_REF_SEP))
	_style_buttons()
	_connect_slots()
	_refresh_counts()
	_on_mobile_controls_changed(GameSettings.mobile_controls_enabled)
	if not RunState.consumables_changed.is_connected(_on_consumables_changed):
		RunState.consumables_changed.connect(_on_consumables_changed)
	if not GameSettings.mobile_controls_changed.is_connected(_on_mobile_controls_changed):
		GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)


func _connect_slots() -> void:
	for i in range(_row.get_child_count()):
		var b: Node = _row.get_child(i)
		if b is Button:
			var slot: int = i + 1
			(b as Button).pressed.connect(_on_slot_pressed.bind(slot))


func _style_buttons() -> void:
	for c in _row.get_children():
		if c is Button:
			var b: Button = c as Button
			b.focus_mode = Control.FOCUS_NONE
			b.flat = false
			b.add_theme_font_override("font", FONT_BOLD)
			b.add_theme_font_size_override("font_size", 18)
			b.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1))
			b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			b.add_theme_constant_override("shadow_offset_x", 1)
			b.add_theme_constant_override("shadow_offset_y", 1)
			b.custom_minimum_size = Vector2(LAYOUT_REF_CELL, LAYOUT_REF_CELL)
			_apply_minecraft_slot_style(b)


## 仿 Minecraft 物品栏格：深底、灰白描边、无圆角、轻微阴影
func _apply_minecraft_slot_style(b: Button) -> void:
	var normal: StyleBoxFlat = _make_slot_stylebox(false, false)
	var hover: StyleBoxFlat = _make_slot_stylebox(true, false)
	var pressed: StyleBoxFlat = _make_slot_stylebox(false, true)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)


func _make_slot_stylebox(hover: bool, pressed: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	var bg: Color = Color(0.11, 0.11, 0.13, 0.94)
	if hover:
		bg = Color(0.16, 0.16, 0.19, 0.96)
	if pressed:
		bg = Color(0.22, 0.22, 0.26, 0.98)
	s.bg_color = bg
	s.set_border_width_all(2)
	var edge: Color = Color(0.55, 0.55, 0.6, 1)
	if hover:
		edge = Color(0.72, 0.72, 0.78, 1)
	if pressed:
		edge = Color(0.38, 0.38, 0.42, 1)
	s.border_color = edge
	s.set_corner_radius_all(0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 2
	s.shadow_offset = Vector2(1, 1)
	return s


func _on_consumables_changed() -> void:
	_refresh_counts()


func _on_mobile_controls_changed(enabled: bool) -> void:
	visible = enabled


func _refresh_counts() -> void:
	for i in range(_row.get_child_count()):
		var c: Node = _row.get_child(i)
		if c is Button:
			var slot: int = i + 1
			var sid: String = _CHS.shop_id_for_slot_one_based(slot)
			var n: int = RunState.get_consumable_count(sid)
			(c as Button).text = "%d\n%d" % [slot, n]


func _on_slot_pressed(slot_one_based: int) -> void:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and arena.has_method("use_consumable_slot"):
		arena.call("use_consumable_slot", slot_one_based)
