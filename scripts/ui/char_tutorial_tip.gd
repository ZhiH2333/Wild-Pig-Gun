extends RefCounted


static func try_add_to_scene_root(root: Control) -> void:
	if not TutorialSession.active:
		return
	if TutorialSession.current_step != TutorialSession.TutorialStep.CHAR_SELECT:
		return
	if root.get_node_or_null("CharTutorialTip") != null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CharTutorialTip"
	layer.layer = 80
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	layer.add_child(margin)
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.82)
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.52, 0.68, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)
	var inner: MarginContainer = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 20)
	inner.add_theme_constant_override("margin_right", 20)
	inner.add_theme_constant_override("margin_top", 16)
	inner.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(inner)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	inner.add_child(vbox)
	var title: Label = Label.new()
	title.text = "选择你的角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	var desc: RichTextLabel = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.text = (
		"[center]每位角色拥有独特的属性与初始武器。"
		+ "鼠标悬停或点击角色可以预览详情。"
		+ "选定后点击「确认出发」开始游戏！[/center]"
	)
	desc.add_theme_font_size_override("normal_font_size", 20)
	vbox.add_child(desc)
	var arrow: Label = Label.new()
	arrow.name = "ArrowHint"
	arrow.text = "▼ 角色列表 ▼"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 22)
	arrow.modulate = Color(1.0, 0.92, 0.55, 1.0)
	vbox.add_child(arrow)
	root.add_child(layer)
	var tw: Tween = arrow.create_tween().set_loops()
	tw.tween_property(arrow, "modulate:a", 0.35, 0.55)
	tw.tween_property(arrow, "modulate:a", 1.0, 0.55)


static func remove_from(root: Control) -> void:
	var n: Node = root.get_node_or_null("CharTutorialTip")
	if n != null:
		n.queue_free()
