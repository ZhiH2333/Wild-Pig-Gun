extends Control
class_name ConsumableSkillDock

## 底栏 6 格消耗品：Minecraft 式槽位 + shop_items icon_emoji；始终显示（键鼠亦可用快捷键使用）

const LAYOUT_REF_CELL: float = 56.0
const LAYOUT_REF_SEP: float = 4.0
const LAYOUT_REF_COLUMN_SEP: float = 2.0
const LAYOUT_REF_CAPTION_MIN_H: float = 14.0

const _CHS = preload("res://scripts/game/consumable_hotkey_slots.gd")
const FONT_BOLD: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")

static func layout_ref_total_width() -> float:
	return 6.0 * LAYOUT_REF_CELL + 5.0 * LAYOUT_REF_SEP


static func layout_ref_total_height() -> float:
	return LAYOUT_REF_CELL + LAYOUT_REF_COLUMN_SEP + LAYOUT_REF_CAPTION_MIN_H


@onready var _row: HBoxContainer = $HBoxContainer


func _ready() -> void:
	add_to_group("consumable_skill_bar")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_wrap_row_with_captions()
	_row.add_theme_constant_override("separation", int(LAYOUT_REF_SEP))
	_style_buttons()
	_connect_slots()
	_ensure_slot_children()
	_refresh_counts()
	_refresh_visibility()
	if not RunState.consumables_changed.is_connected(_on_consumables_changed):
		RunState.consumables_changed.connect(_on_consumables_changed)
func _wrap_row_with_captions() -> void:
	var dock_root: Control = _row.get_parent() as Control
	if dock_root == null:
		return
	var col: VBoxContainer = VBoxContainer.new()
	col.name = "DockColumn"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", int(LAYOUT_REF_COLUMN_SEP))
	dock_root.add_child(col)
	_row.reparent(col)
	var cap_row: HBoxContainer = HBoxContainer.new()
	cap_row.name = "CaptionRow"
	cap_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_row.add_theme_constant_override("separation", int(LAYOUT_REF_SEP))
	col.add_child(cap_row)
	for slot: int in range(1, 7):
		var lab: Label = Label.new()
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.clip_text = true
		lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var sid: String = _CHS.shop_id_for_slot_one_based(slot)
		var def: Dictionary = BuildCatalog.get_shop_item_def(sid)
		lab.text = str(def.get("title", sid))
		lab.add_theme_font_override("font", FONT_BOLD)
		lab.add_theme_font_size_override("font_size", 11)
		lab.add_theme_color_override("font_color", Color(0.76, 0.78, 0.88, 0.92))
		lab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		lab.add_theme_constant_override("shadow_offset_x", 1)
		lab.add_theme_constant_override("shadow_offset_y", 1)
		lab.custom_minimum_size = Vector2(LAYOUT_REF_CELL, LAYOUT_REF_CAPTION_MIN_H)
		cap_row.add_child(lab)


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
			b.text = ""
			b.clip_contents = false
			b.custom_minimum_size = Vector2(LAYOUT_REF_CELL, LAYOUT_REF_CELL)
			_apply_minecraft_slot_style(b)


func _ensure_slot_children() -> void:
	for c in _row.get_children():
		if not c is Button:
			continue
		var b: Button = c as Button
		if b.get_node_or_null("EmojiLbl") != null:
			continue
		var emoji_l: Label = Label.new()
		emoji_l.name = "EmojiLbl"
		emoji_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emoji_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji_l.add_theme_font_override("font", FONT_BOLD)
		emoji_l.add_theme_font_size_override("font_size", 22)
		emoji_l.set_anchors_preset(Control.PRESET_FULL_RECT)
		emoji_l.anchor_bottom = 0.58
		b.add_child(emoji_l)
		var idx_l: Label = Label.new()
		idx_l.name = "IdxLbl"
		idx_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		idx_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		idx_l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		idx_l.add_theme_font_override("font", FONT_BOLD)
		idx_l.add_theme_font_size_override("font_size", 10)
		idx_l.add_theme_color_override("font_color", Color(0.75, 0.78, 0.92, 0.95))
		idx_l.position = Vector2(4, 2)
		idx_l.size = Vector2(18, 14)
		b.add_child(idx_l)
		var cnt_l: Label = Label.new()
		cnt_l.name = "CountLbl"
		cnt_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cnt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		cnt_l.add_theme_font_override("font", FONT_BOLD)
		cnt_l.add_theme_font_size_override("font_size", 12)
		cnt_l.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		cnt_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		cnt_l.add_theme_constant_override("shadow_offset_x", 1)
		cnt_l.add_theme_constant_override("shadow_offset_y", 1)
		cnt_l.set_anchors_preset(Control.PRESET_FULL_RECT)
		cnt_l.anchor_top = 0.55
		b.add_child(cnt_l)


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


func _refresh_visibility() -> void:
	visible = true


func _on_consumables_changed() -> void:
	_refresh_counts()
	_refresh_visibility()


func _refresh_counts() -> void:
	for i in range(_row.get_child_count()):
		var c: Node = _row.get_child(i)
		if not c is Button:
			continue
		var b: Button = c as Button
		var slot: int = i + 1
		var sid: String = _CHS.shop_id_for_slot_one_based(slot)
		var n: int = RunState.get_consumable_count(sid)
		var def: Dictionary = BuildCatalog.get_shop_item_def(sid)
		var emoji: String = str(def.get("icon_emoji", "·"))
		var emoji_n: Label = b.get_node_or_null("EmojiLbl") as Label
		var cnt_n: Label = b.get_node_or_null("CountLbl") as Label
		var idx_n: Label = b.get_node_or_null("IdxLbl") as Label
		if emoji_n != null:
			emoji_n.text = emoji
			emoji_n.modulate = Color(1, 1, 1, 1) if n > 0 else Color(0.45, 0.45, 0.5, 0.85)
		if cnt_n != null:
			cnt_n.text = str(n) if n > 0 else ""
		if idx_n != null:
			idx_n.text = str(slot)


func _on_slot_pressed(slot_one_based: int) -> void:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and arena.has_method("use_consumable_slot"):
		arena.call("use_consumable_slot", slot_one_based)
