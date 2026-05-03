extends Control

const CHAR_TUTORIAL_TIP_SCRIPT: Script = preload("res://scripts/ui/char_tutorial_tip.gd")
const MENU_FONT: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")
const WEAPON_CARD_WIDTH_FLOOR: float = 96.0
const WEAPON_CARD_MIN_HEIGHT: float = 176.0
const _P_LEFT: String = "Center/MainColumn/MainCard/Margins/MainRow/LeftColumn/LeftVBox"
const _P_WEAPON_GRID: String = "Center/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponHeaderRow/WeaponScrollPanel/WeaponScroll/WeaponList"
const _P_WEAPON_STATS: String = "Center/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponStatsBox"

var char_sprite: TextureRect
var char_name_label: Label
var char_desc_label: Label
var char_stats_vbox: VBoxContainer
var weapon_card_grid: GridContainer
var weapon_name_label: Label
var weapon_kind_label: Label
var weapon_element_label: Label
var damage_bar: ProgressBar
var fire_rate_bar: ProgressBar
var damage_value_label: Label
var fire_rate_value_label: Label

const MAX_DAMAGE: float = 55.0
const MAX_FIRE_RATE: float = 6.25
const GAME_START_SCENE: String = "res://scenes/game_start.tscn"

var weapon_defs: Array[Dictionary] = []
var selected_weapon_id: String = WeaponCatalog.DEFAULT_STARTER_WEAPON_ID
var _weapon_card_style_normal: StyleBoxFlat
var _weapon_card_style_selected: StyleBoxFlat
var _weapon_grid_resize_hooked: bool = false
var _weapon_reflow_retry: int = 0


func _is_embedded_in_game_start() -> bool:
	return bool(get_meta("game_start_embedded", false))


func _ready() -> void:
	_bind_pre_start_ui_nodes()
	GameMusic.duck_for_subpage()
	CharacterData.sanitize_selected_character_setting()
	_refresh_character_panel()
	if weapon_element_label != null:
		weapon_element_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weapon_element_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_init_weapon_card_styles()
	_setup_weapon_section()
	CHAR_TUTORIAL_TIP_SCRIPT.call("try_add_to_scene_root", self)


func _bind_pre_start_ui_nodes() -> void:
	char_sprite = get_node_or_null("%s/PortraitPanel/PortraitMargins/CharSprite" % _P_LEFT) as TextureRect
	char_name_label = get_node_or_null("%s/CharNameLabel" % _P_LEFT) as Label
	char_desc_label = get_node_or_null("%s/CharDescLabel" % _P_LEFT) as Label
	char_stats_vbox = get_node_or_null("%s/CharStatsVBox" % _P_LEFT) as VBoxContainer
	weapon_card_grid = get_node_or_null(_P_WEAPON_GRID) as GridContainer
	weapon_name_label = get_node_or_null("%s/WeaponNameLabel" % _P_WEAPON_STATS) as Label
	weapon_kind_label = get_node_or_null("%s/MetaRow/WeaponKindLabel" % _P_WEAPON_STATS) as Label
	weapon_element_label = get_node_or_null("%s/MetaRow/WeaponElementLabel" % _P_WEAPON_STATS) as Label
	damage_bar = get_node_or_null("%s/DamageRow/DamageBar" % _P_WEAPON_STATS) as ProgressBar
	damage_value_label = get_node_or_null("%s/DamageRow/DamageValueLabel" % _P_WEAPON_STATS) as Label
	fire_rate_bar = get_node_or_null("%s/FireRateRow/FireRateBar" % _P_WEAPON_STATS) as ProgressBar
	fire_rate_value_label = get_node_or_null("%s/FireRateRow/FireRateValueLabel" % _P_WEAPON_STATS) as Label
	if weapon_card_grid == null:
		push_error("PreStart: 未找到武器卡片网格节点 %s" % _P_WEAPON_GRID)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_exit_pre_start_from_cancel()


func _exit_pre_start_from_cancel() -> void:
	CHAR_TUTORIAL_TIP_SCRIPT.call("remove_from", self)
	GameMusic.ensure_playing_main_volume()
	if _is_embedded_in_game_start():
		var host: Node = _find_game_start_host()
		if host != null and host.has_method("show_manage_tab"):
			host.show_manage_tab()
			return
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _find_game_start_host() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.is_in_group("game_start"):
			return n
		n = n.get_parent()
	return null


func _refresh_character_panel() -> void:
	var character_id: String = str(GameSettings.selected_character_id)
	var character: Dictionary = CharacterData.find_character(character_id)
	var display_name: String = str(character.get("display_name", "野猪"))
	var description: String = str(character.get("description", "暂无介绍"))
	var sprite_path: String = str(character.get("sprite_path", "res://assets/sprites/wildpig.png"))
	if char_name_label != null:
		char_name_label.text = display_name
	if char_desc_label != null:
		char_desc_label.text = description
	if char_stats_vbox != null:
		for ch in char_stats_vbox.get_children():
			ch.queue_free()
		CharacterStatBarsUi.append_to_vbox(char_stats_vbox, character, true, true)
	if char_sprite == null:
		return
	if not ResourceLoader.exists(sprite_path):
		char_sprite.texture = null
		return
	var texture: Texture2D = load(sprite_path) as Texture2D
	char_sprite.texture = texture


func _setup_weapon_section() -> void:
	weapon_defs = WeaponCatalog.list_starter_defs_ordered()
	var default_weapon_id: String = _resolve_default_weapon_id()
	selected_weapon_id = default_weapon_id
	if weapon_card_grid != null:
		_hook_weapon_grid_resize()
		_rebuild_weapon_cards()
	_refresh_weapon_stats(default_weapon_id)


func _hook_weapon_grid_resize() -> void:
	if weapon_card_grid == null or _weapon_grid_resize_hooked:
		return
	weapon_card_grid.resized.connect(_on_weapon_grid_resized)
	_weapon_grid_resize_hooked = true


func _on_weapon_grid_resized() -> void:
	_reflow_weapon_card_widths()


func _weapon_grid_inner_width_pixels() -> float:
	if weapon_card_grid == null:
		return 0.0
	var w: float = weapon_card_grid.size.x
	if w >= 8.0:
		return w
	var par: Control = weapon_card_grid.get_parent() as Control
	if par != null:
		var pw: float = par.size.x
		if pw >= 8.0:
			return pw
	return 0.0


func _reflow_weapon_card_widths() -> void:
	if weapon_card_grid == null:
		return
	var cols: int = maxi(1, weapon_card_grid.columns)
	var sep: int = int(weapon_card_grid.get_theme_constant("h_separation", "GridContainer"))
	if sep <= 0:
		sep = 8
	var inner: float = _weapon_grid_inner_width_pixels()
	if inner < 8.0:
		_weapon_reflow_retry += 1
		if _weapon_reflow_retry < 16:
			call_deferred("_reflow_weapon_card_widths")
		else:
			_weapon_reflow_retry = 0
		return
	_weapon_reflow_retry = 0
	var cw: float = (inner - sep * float(cols - 1)) / float(cols)
	cw = maxf(WEAPON_CARD_WIDTH_FLOOR, cw)
	for c in weapon_card_grid.get_children():
		if c is Control:
			var ctl: Control = c as Control
			ctl.custom_minimum_size = Vector2(cw, WEAPON_CARD_MIN_HEIGHT)
			ctl.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _resolve_default_weapon_id() -> String:
	var fallback_id: String = WeaponCatalog.DEFAULT_STARTER_WEAPON_ID
	if weapon_defs.is_empty():
		return fallback_id
	var character_id: String = str(GameSettings.selected_character_id)
	var character_weapon_ids: Array = CharacterData.get_starting_weapon_ids(character_id)
	for wv in character_weapon_ids:
		var cand: String = str(wv)
		if WeaponCatalog.is_starter_weapon_id(cand):
			return cand
	return str(weapon_defs[0].get("id", fallback_id))


func _init_weapon_card_styles() -> void:
	if _weapon_card_style_normal != null:
		return
	_weapon_card_style_normal = _make_weapon_card_stylebox(false)
	_weapon_card_style_selected = _make_weapon_card_stylebox(true)


func _make_weapon_card_stylebox(selected: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.11, 0.10, 0.14, 0.96)
	var r: float = 12.0
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_right = r
	s.corner_radius_bottom_left = r
	if selected:
		s.set_border_width_all(2)
		s.border_color = Color(0.95, 0.78, 0.32, 1.0)
	else:
		s.set_border_width_all(1)
		s.border_color = Color(1.0, 1.0, 1.0, 0.14)
	s.content_margin_left = 10.0
	s.content_margin_top = 10.0
	s.content_margin_right = 10.0
	s.content_margin_bottom = 10.0
	return s


func _weapon_card_tag_bg(design_category: String) -> Color:
	match design_category:
		"基础":
			return Color(0.72, 0.86, 0.70, 1.0)
		"近战型", "近战":
			return Color(0.94, 0.78, 0.82, 1.0)
		"节奏型":
			return Color(0.82, 0.78, 0.94, 1.0)
		"链式伤害", "控制", "减速":
			return Color(0.76, 0.86, 0.96, 1.0)
		"穿透":
			return Color(0.72, 0.88, 0.74, 1.0)
		"持续伤害", "高伤":
			return Color(0.96, 0.80, 0.86, 1.0)
		"AOE":
			return Color(0.96, 0.86, 0.70, 1.0)
		"纯近战":
			return Color(0.86, 0.84, 0.80, 1.0)
		_:
			return Color(0.78, 0.80, 0.86, 1.0)


func _weapon_card_emoji(weapon_id: String) -> String:
	return WeaponCatalog.display_emoji_for_weapon_id(weapon_id)


func _rebuild_weapon_cards() -> void:
	if weapon_card_grid == null:
		return
	for child in weapon_card_grid.get_children():
		child.queue_free()
	for weapon_def in weapon_defs:
		var weapon_id: String = str(weapon_def.get("id", ""))
		if weapon_id.is_empty():
			continue
		var card: PanelContainer = _build_weapon_card(weapon_def, weapon_id)
		weapon_card_grid.add_child(card)
	call_deferred("_reflow_weapon_card_widths")


func _build_weapon_card(weapon_def: Dictionary, weapon_id: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(WEAPON_CARD_WIDTH_FLOOR, WEAPON_CARD_MIN_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("weapon_id", weapon_id)
	card.add_theme_stylebox_override(
		"panel",
		_weapon_card_style_selected if weapon_id == selected_weapon_id else _weapon_card_style_normal
	)
	var outer: MarginContainer = MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 2)
	outer.add_theme_constant_override("margin_top", 2)
	outer.add_theme_constant_override("margin_right", 2)
	outer.add_theme_constant_override("margin_bottom", 2)
	card.add_child(outer)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(col)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)
	var emoji_lbl: Label = Label.new()
	emoji_lbl.text = _weapon_card_emoji(weapon_id)
	emoji_lbl.add_theme_font_size_override("font_size", 26)
	emoji_lbl.custom_minimum_size = Vector2(36, 36)
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(emoji_lbl)
	var title_lbl: Label = Label.new()
	title_lbl.text = str(weapon_def.get("display_name", weapon_id))
	title_lbl.add_theme_font_override("font", MENU_FONT)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1.0))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_lbl)
	var design_cat: String = str(weapon_def.get("design_category", "")).strip_edges()
	if not design_cat.is_empty():
		var tag_wrap: PanelContainer = PanelContainer.new()
		var tag_sb: StyleBoxFlat = StyleBoxFlat.new()
		tag_sb.bg_color = _weapon_card_tag_bg(design_cat)
		tag_sb.corner_radius_top_left = 6.0
		tag_sb.corner_radius_top_right = 6.0
		tag_sb.corner_radius_bottom_right = 6.0
		tag_sb.corner_radius_bottom_left = 6.0
		tag_sb.content_margin_left = 8.0
		tag_sb.content_margin_top = 3.0
		tag_sb.content_margin_right = 8.0
		tag_sb.content_margin_bottom = 3.0
		tag_wrap.add_theme_stylebox_override("panel", tag_sb)
		var tag_lbl: Label = Label.new()
		tag_lbl.text = design_cat
		tag_lbl.add_theme_font_size_override("font_size", 16)
		tag_lbl.add_theme_color_override("font_color", Color(0.18, 0.16, 0.22, 1.0))
		tag_wrap.add_child(tag_lbl)
		col.add_child(tag_wrap)
	var body_rt: RichTextLabel = RichTextLabel.new()
	body_rt.bbcode_enabled = true
	body_rt.fit_content = true
	body_rt.scroll_active = false
	body_rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_rt.custom_minimum_size = Vector2(10, 56)
	body_rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_body: String = str(weapon_def.get("card_desc", "")).strip_edges()
	if card_body.is_empty():
		card_body = str(weapon_def.get("short_desc", ""))
	var bb: String = ""
	if not card_body.is_empty():
		bb += "[color=#cfc8be]%s[/color]" % card_body
	if bb.is_empty():
		bb = "[color=#a8a29e]—[/color]"
	body_rt.text = "[font_size=15]%s[/font_size]" % bb
	col.add_child(body_rt)
	for c in card.get_children():
		_weapon_card_children_mouse_ignore(c)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_weapon_card_gui_input.bind(weapon_id))
	return card


func _weapon_card_children_mouse_ignore(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_weapon_card_children_mouse_ignore(c)


func _on_weapon_card_gui_input(event: InputEvent, weapon_id: String) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_select_weapon_by_id(weapon_id)


func _select_weapon_by_id(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	if weapon_card_grid == null:
		_refresh_weapon_stats(weapon_id)
		return
	for child in weapon_card_grid.get_children():
		if not child is PanelContainer:
			continue
		var pc: PanelContainer = child as PanelContainer
		var wid: String = str(pc.get_meta("weapon_id", ""))
		pc.add_theme_stylebox_override(
			"panel",
			_weapon_card_style_selected if wid == weapon_id else _weapon_card_style_normal
		)
	_refresh_weapon_stats(weapon_id)


func _refresh_weapon_stats(weapon_id: String) -> void:
	var weapon_def: Dictionary = WeaponCatalog.find_def(weapon_id)
	var display_name: String = str(weapon_def.get("display_name", weapon_id))
	var weapon_kind: String = str(weapon_def.get("kind", "projectile"))
	var kind_zh: String = weapon_kind
	if weapon_kind == "projectile":
		kind_zh = "投射物"
	elif weapon_kind == "melee":
		kind_zh = "近战"
	var raw_el: String = str(weapon_def.get("element", "physical"))
	var element_name: String = _element_display_zh(raw_el)
	var design_cat: String = str(weapon_def.get("design_category", "")).strip_edges()
	var damage_value: float = float(weapon_def.get("damage", 0))
	var fire_interval: float = maxf(0.01, float(weapon_def.get("fire_interval", 1.0)))
	var fire_rate_value: float = 1.0 / fire_interval
	if weapon_name_label != null:
		weapon_name_label.text = display_name
	if weapon_kind_label != null:
		if design_cat.is_empty():
			weapon_kind_label.text = "类型：%s" % kind_zh
		else:
			weapon_kind_label.text = "标签：%s  ·  类型：%s" % [design_cat, kind_zh]
	if weapon_element_label != null:
		weapon_element_label.text = "属性：%s" % element_name
	if damage_bar != null:
		damage_bar.max_value = 100.0
		damage_bar.value = clampf(damage_value / MAX_DAMAGE, 0.0, 1.0) * 100.0
	if fire_rate_bar != null:
		fire_rate_bar.max_value = 100.0
		fire_rate_bar.value = clampf(fire_rate_value / MAX_FIRE_RATE, 0.0, 1.0) * 100.0
	if damage_value_label != null:
		damage_value_label.text = "%.0f" % damage_value
	if fire_rate_value_label != null:
		fire_rate_value_label.text = "%.2f" % fire_rate_value


static func _element_display_zh(element_key: String) -> String:
	match element_key:
		"fire":
			return "火焰"
		"ice":
			return "冰霜"
		"poison":
			return "毒素"
		"shock":
			return "电击"
		"physical", "":
			return "物理"
		_:
			return element_key


func _on_change_char_button_pressed() -> void:
	if _is_embedded_in_game_start():
		RunState.gallery_return_scene_path = GAME_START_SCENE
	else:
		RunState.gallery_return_scene_path = "res://scenes/pre_start.tscn"
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_start_button_pressed() -> void:
	CHAR_TUTORIAL_TIP_SCRIPT.call("remove_from", self)
	SaveManager.create_slot()
	RunState.begin_new_run(str(GameSettings.selected_character_id), 1.0)
	RunState.selected_starting_weapon_ids = [selected_weapon_id]
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
