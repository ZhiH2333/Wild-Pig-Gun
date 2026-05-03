extends Control

const CHAR_TUTORIAL_TIP_SCRIPT: Script = preload("res://scripts/ui/char_tutorial_tip.gd")

@onready var character_vbox: VBoxContainer = $ScrollContainer/CharacterVBox
@onready var risk_check: CheckBox = $RiskCheck


func _ready() -> void:
	GameMusic.duck_for_subpage()
	for c in character_vbox.get_children():
		c.queue_free()
	for c in CharacterData.list_characters():
		if not c is Dictionary:
			continue
		var d: Dictionary = c as Dictionary
		var unlocked: bool = CharacterData.is_character_unlocked(d)
		character_vbox.add_child(_build_character_card(d, unlocked))
	CHAR_TUTORIAL_TIP_SCRIPT.call("try_add_to_scene_root", self)


func _build_character_card(d: Dictionary, unlocked: bool) -> Control:
	var cid: String = str(d.get("id", "default"))
	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 0)
	root.add_theme_constant_override("margin_right", 0)
	root.add_theme_constant_override("margin_top", 0)
	root.add_theme_constant_override("margin_bottom", 0)
	var btn := Button.new()
	btn.flat = true
	btn.disabled = not unlocked
	btn.custom_minimum_size = Vector2(620, 188)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if unlocked:
		btn.pressed.connect(_on_character_chosen.bind(cid))
	var outer := HBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_right = 0
	outer.offset_bottom = 0
	outer.add_theme_constant_override("separation", 0)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(5, 1)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent.color = CharacterData.get_select_accent_color(cid)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(accent)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_lbl := Label.new()
	name_lbl.text = str(d.get("display_name", "?"))
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9, 1.0 if unlocked else 0.45))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = str(d.get("description", ""))
	desc_lbl.add_theme_font_size_override("font_size", 17)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72, 1.0 if unlocked else 0.4))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(desc_lbl)
	CharacterStatBarsUi.append_to_vbox(col, d, unlocked, false)
	if not unlocked:
		var lock_lbl := Label.new()
		lock_lbl.text = "未解锁 · 图鉴或野猪钱包购买"
		lock_lbl.add_theme_font_size_override("font_size", 15)
		lock_lbl.add_theme_color_override("font_color", Color(0.72, 0.55, 0.35, 1.0))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lock_lbl)
	pad.add_child(col)
	outer.add_child(pad)
	btn.add_child(outer)
	root.add_child(btn)
	return root


func _on_back_button_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_character_chosen(character_id: String) -> void:
	CHAR_TUTORIAL_TIP_SCRIPT.call("remove_from", self)
	GameSettings.set_selected_character_id(character_id)
	var risk: float = 1.25 if risk_check.button_pressed else 1.0
	RunState.begin_new_run(character_id, risk)
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
