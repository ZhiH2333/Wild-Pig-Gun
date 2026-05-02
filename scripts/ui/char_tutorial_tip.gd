extends RefCounted

const DIALOG_WIDTH: float = 360.0
const DIALOG_MIN_HEIGHT: float = 200.0


static func try_add_to_scene_root(root: Control) -> void:
	if not TutorialSession.active:
		return
	if TutorialSession.current_step != TutorialSession.TutorialStep.CHAR_SELECT:
		return
	if root.get_node_or_null("CharTutorialTip") != null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CharTutorialTip"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(DIALOG_WIDTH, DIALOG_MIN_HEIGHT)
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.09, 0.14, 0.97)
	card_style.set_corner_radius_all(14)
	card_style.set_border_width_all(1)
	card_style.border_color = Color(0.45, 0.52, 0.68, 0.9)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var title: Label = Label.new()
	title.text = "选择你的角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	var separator: HSeparator = HSeparator.new()
	vbox.add_child(separator)
	var desc: RichTextLabel = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.custom_minimum_size = Vector2(DIALOG_WIDTH - 56, 0)
	desc.text = (
		"[center]左侧可更换角色；右侧选择初始武器后\n点「开始游戏」进入战场。[/center]"
	)
	desc.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(desc)
	var confirm_btn: Button = Button.new()
	confirm_btn.text = "我明白了"
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_child(confirm_btn)
	vbox.add_child(btn_row)
	root.add_child(layer)
	confirm_btn.pressed.connect(func() -> void:
		layer.queue_free()
	)


static func remove_from(root: Control) -> void:
	var n: Node = root.get_node_or_null("CharTutorialTip")
	if n != null:
		n.queue_free()
