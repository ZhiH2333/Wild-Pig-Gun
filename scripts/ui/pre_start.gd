extends Control

const CHAR_TUTORIAL_TIP_SCRIPT: Script = preload("res://scripts/ui/char_tutorial_tip.gd")
const MENU_FONT: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")
const WEAPON_CARD_WIDTH_MIN: float = 140.0
const WEAPON_CARD_WIDTH_MAX: float = 176.0
const WEAPON_CARD_MIN_HEIGHT: float = 118.0
const WEAPON_GRID_COLS_MIN: int = 2
const WEAPON_GRID_COLS_MAX: int = 4
const CONTENT_MAX_WIDTH: float = 1280.0
const _P_LEFT: String = (
	"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/LeftColumn/LeftVBox"
)
const _P_WEAPON_GRID: String = (
	"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/"
	+ "RightVBox/WeaponHeaderRow/WeaponScrollPanel/WeaponScroll/WeaponList"
)
const _P_WEAPON_STATS: String = (
	"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponStatsBox"
)

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
var weapon_body_label: Label
var weapon_effect_label: Label

const MAX_DAMAGE: float = 55.0
const MAX_FIRE_RATE: float = 6.25
const GAME_START_SCENE: String = "res://scenes/game_start.tscn"

var weapon_defs: Array[Dictionary] = []
var selected_weapon_id: String = WeaponCatalog.DEFAULT_STARTER_WEAPON_ID
var _weapon_card_style_normal: StyleBoxFlat
var _weapon_card_style_selected: StyleBoxFlat
var _weapon_grid_resize_hooked: bool = false
var _weapon_reflow_retry: int = 0
var _wizard_step: int = 0
var _weapon_page: int = 0
var _weapon_page_size: int = 6
var _pager_row: HBoxContainer
var _page_label: Label
var _prev_page_btn: Button
var _next_page_btn: Button
var _back_step_btn: Button
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _left_column: Control
var _right_column: Control
var _divider: Control
var _detail_column: Control
var _main_row: Control

@onready var _start_button: Button = $Center/ContentVBox/FooterRow/StartButton


func _is_embedded_in_game_start() -> bool:
	return bool(get_meta("game_start_embedded", false))


func _ready() -> void:
	_bind_pre_start_ui_nodes()
	if not get_viewport().size_changed.is_connected(_apply_safe_area_to_center):
		get_viewport().size_changed.connect(_apply_safe_area_to_center)
	if not get_viewport().size_changed.is_connected(_fit_start_button_width):
		get_viewport().size_changed.connect(_fit_start_button_width)
	_compose_three_column_layout()
	_apply_embedded_chrome()
	_setup_wizard_ui()
	call_deferred("_apply_safe_area_to_center")
	call_deferred("_fit_start_button_width")
	call_deferred("_apply_wizard_step")
	GameMusic.duck_for_subpage()
	CharacterData.sanitize_selected_character_setting()
	_refresh_character_panel()
	if weapon_element_label != null:
		weapon_element_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weapon_element_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_init_weapon_card_styles()
	_setup_weapon_section()
	CHAR_TUTORIAL_TIP_SCRIPT.call("try_add_to_scene_root", self)


func _apply_safe_area_to_center() -> void:
	var c: MarginContainer = get_node_or_null("Center") as MarginContainer
	if c == null:
		return
	var add_left: float = 0.0
	var add_top: float = 0.0
	var add_right: float = 0.0
	var add_bot: float = 0.0
	var sa: Rect2i = DisplayServer.get_display_safe_area()
	var win: Window = get_viewport().get_window()
	if win != null:
		var wr: Rect2i = Rect2i(win.position, win.size)
		add_left = maxf(0.0, float(sa.position.x - wr.position.x))
		add_top = maxf(0.0, float(sa.position.y - wr.position.y))
		add_right = maxf(0.0, float(wr.position.x + wr.size.x - sa.position.x - sa.size.x))
		add_bot = maxf(0.0, float(wr.position.y + wr.size.y - sa.position.y - sa.size.y))
	var base_l: float = 16.0 if _is_embedded_in_game_start() else 28.0
	var base_t: float = 8.0 if _is_embedded_in_game_start() else 36.0
	var base_r: float = 16.0 if _is_embedded_in_game_start() else 28.0
	var base_b: float = 8.0 if _is_embedded_in_game_start() else 32.0
	var vw: float = get_viewport().get_visible_rect().size.x
	var extra: float = maxf(0.0, vw - CONTENT_MAX_WIDTH)
	c.offset_left = base_l + add_left + extra * 0.5
	c.offset_top = base_t + add_top
	c.offset_right = -(base_r + add_right + extra * 0.5)
	c.offset_bottom = -(base_b + add_bot)
	_fit_start_button_width()
	_apply_wizard_step()


## 高 UI 缩放下限制「开始游戏」宽度，避免整体超出可视区域
func _fit_start_button_width() -> void:
	if _start_button == null:
		return
	var cv: Control = get_node_or_null("Center/ContentVBox") as Control
	var vw: float = get_viewport().get_visible_rect().size.x
	var avail: float = vw - 64.0
	if cv != null and cv.is_inside_tree() and cv.size.x > 32.0:
		avail = minf(avail, cv.size.x - 16.0)
	avail = maxf(140.0, avail)
	_start_button.custom_minimum_size = Vector2(minf(320.0, avail), 72.0)


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
	var sc: ScrollContainer = get_node_or_null("Center/ContentVBox/MainScroll") as ScrollContainer
	if sc != null:
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var wsc: ScrollContainer = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponHeaderRow/WeaponScrollPanel/WeaponScroll"
	) as ScrollContainer
	if wsc != null:
		wsc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		wsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_column = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/LeftColumn"
	) as Control
	_right_column = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn"
	) as Control
	_divider = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/ColumnDivider"
	) as Control
	_main_row = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow"
	) as Control
	var mc: Control = get_node_or_null("Center/ContentVBox/MainScroll/MainColumn") as Control
	if mc != null:
		mc.size_flags_vertical = Control.SIZE_EXPAND_FILL



func _apply_embedded_chrome() -> void:
	var title: Node = get_node_or_null("%s/CharSectionTitle" % _P_LEFT)
	var sep: Node = get_node_or_null("%s/CharSectionSep" % _P_LEFT)
	var wtitle: Node = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponHeaderRow/WeaponSectionTitle"
	)
	if title is CanvasItem:
		(title as CanvasItem).visible = false
	if sep is CanvasItem:
		(sep as CanvasItem).visible = false
	if wtitle is CanvasItem:
		(wtitle as CanvasItem).visible = false
	if char_sprite != null:
		char_sprite.custom_minimum_size = Vector2(160, 160)
	if char_name_label != null:
		char_name_label.add_theme_font_size_override("font_size", 24)
	if char_desc_label != null:
		char_desc_label.add_theme_font_size_override("font_size", 15)
	var header_row: Control = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/WeaponHeaderRow"
	) as Control
	if header_row != null:
		header_row.custom_minimum_size = Vector2(0, 0)


func _compose_three_column_layout() -> void:
	var main_row: HBoxContainer = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow"
	) as HBoxContainer
	var stats: VBoxContainer = get_node_or_null(_P_WEAPON_STATS) as VBoxContainer
	if main_row == null or stats == null:
		return
	if stats.get_parent() != null and str(stats.get_parent().name) == "DetailColumn":
		return
	var sep: Node = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/RightColumn/RightVBox/StatsSectionSep"
	)
	if sep != null:
		sep.get_parent().remove_child(sep)
		sep.free()
	var old_parent: Node = stats.get_parent()
	old_parent.remove_child(stats)
	var detail: MarginContainer = MarginContainer.new()
	detail.name = "DetailColumn"
	detail.custom_minimum_size = Vector2(304, 0)
	detail.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("margin_left", 8)
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ps: StyleBoxFlat = StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0.45)
	ps.set_border_width_all(1)
	ps.border_color = Color(1, 1, 1, 0.22)
	ps.set_corner_radius_all(2)
	ps.content_margin_left = 14
	ps.content_margin_top = 12
	ps.content_margin_right = 14
	ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	detail.add_child(panel)
	panel.add_child(stats)
	stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_child(detail)
	_ensure_detail_copy_labels(stats)
	if weapon_card_grid != null:
		weapon_card_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


func _ensure_detail_copy_labels(stats: VBoxContainer) -> void:
	weapon_body_label = stats.get_node_or_null("WeaponBodyLabel") as Label
	if weapon_body_label == null:
		weapon_body_label = Label.new()
		weapon_body_label.name = "WeaponBodyLabel"
		weapon_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weapon_body_label.add_theme_font_size_override("font_size", 15)
		weapon_body_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76, 1.0))
		stats.add_child(weapon_body_label)
	weapon_effect_label = stats.get_node_or_null("WeaponEffectLabel") as Label
	if weapon_effect_label == null:
		weapon_effect_label = Label.new()
		weapon_effect_label.name = "WeaponEffectLabel"
		weapon_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weapon_effect_label.add_theme_font_size_override("font_size", 15)
		weapon_effect_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.62, 1.0))
		stats.add_child(weapon_effect_label)
	if weapon_name_label != null:
		weapon_name_label.add_theme_font_size_override("font_size", 22)
	if weapon_kind_label != null:
		weapon_kind_label.add_theme_font_size_override("font_size", 16)
	if weapon_element_label != null:
		weapon_element_label.add_theme_font_size_override("font_size", 16)



func reset_wizard() -> void:
	_wizard_step = 0
	_weapon_page = 0
	_apply_wizard_step()


func _setup_wizard_ui() -> void:
	var vbox: VBoxContainer = get_node_or_null("Center/ContentVBox") as VBoxContainer
	if vbox == null:
		return
	_detail_column = get_node_or_null(
		"Center/ContentVBox/MainScroll/MainColumn/MainCard/Margins/MainRow/DetailColumn"
	) as Control
	if _confirm_panel == null and _main_row != null:
		_confirm_panel = PanelContainer.new()
		_confirm_panel.name = "ConfirmPanel"
		_confirm_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_confirm_panel.visible = false
		var ps: StyleBoxFlat = StyleBoxFlat.new()
		ps.bg_color = Color(0, 0, 0, 0.45)
		ps.set_border_width_all(1)
		ps.border_color = Color(1, 1, 1, 0.22)
		ps.set_corner_radius_all(2)
		ps.content_margin_left = 22
		ps.content_margin_top = 18
		ps.content_margin_right = 22
		ps.content_margin_bottom = 18
		_confirm_panel.add_theme_stylebox_override("panel", ps)
		_confirm_label = Label.new()
		_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_confirm_label.add_theme_font_size_override("font_size", 18)
		_confirm_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
		_confirm_panel.add_child(_confirm_label)
		_main_row.add_child(_confirm_panel)
	if _pager_row == null and _right_column != null:
		var rv: VBoxContainer = _right_column.get_node_or_null("RightVBox") as VBoxContainer
		if rv != null:
			_pager_row = HBoxContainer.new()
			_pager_row.name = "WeaponPager"
			_pager_row.alignment = BoxContainer.ALIGNMENT_CENTER
			_pager_row.add_theme_constant_override("separation", 12)
			_prev_page_btn = Button.new()
			_prev_page_btn.text = "上一页"
			_prev_page_btn.custom_minimum_size = Vector2(120, 40)
			_style_wizard_chrome_button(_prev_page_btn, 16)
			_prev_page_btn.pressed.connect(_on_weapon_page_prev)
			_page_label = Label.new()
			_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_page_label.custom_minimum_size = Vector2(80, 0)
			_page_label.add_theme_font_size_override("font_size", 16)
			_next_page_btn = Button.new()
			_next_page_btn.text = "下一页"
			_next_page_btn.custom_minimum_size = Vector2(120, 40)
			_style_wizard_chrome_button(_next_page_btn, 16)
			_next_page_btn.pressed.connect(_on_weapon_page_next)
			_pager_row.add_child(_prev_page_btn)
			_pager_row.add_child(_page_label)
			_pager_row.add_child(_next_page_btn)
			rv.add_child(_pager_row)
	var footer: HBoxContainer = get_node_or_null("Center/ContentVBox/FooterRow") as HBoxContainer
	if footer != null and _back_step_btn == null:
		_back_step_btn = Button.new()
		_back_step_btn.name = "BackStepButton"
		_back_step_btn.text = "上一步"
		_back_step_btn.custom_minimum_size = Vector2(160, 56)
		_back_step_btn.visible = false
		_style_wizard_chrome_button(_back_step_btn, 22)
		_back_step_btn.pressed.connect(_on_wizard_back)
		footer.add_child(_back_step_btn)
		footer.move_child(_back_step_btn, 0)
	if _start_button != null:
		if _start_button.pressed.is_connected(_on_start_button_pressed):
			_start_button.pressed.disconnect(_on_start_button_pressed)
		if not _start_button.pressed.is_connected(_on_wizard_primary):
			_start_button.pressed.connect(_on_wizard_primary)


func _weapon_page_count() -> int:
	var n: int = weapon_defs.size()
	if n <= 0 or _weapon_page_size <= 0:
		return 1
	return maxi(1, int(ceili(float(n) / float(_weapon_page_size))))


func _on_weapon_page_prev() -> void:
	_weapon_page = maxi(0, _weapon_page - 1)
	_rebuild_weapon_cards()


func _on_weapon_page_next() -> void:
	_weapon_page = mini(_weapon_page_count() - 1, _weapon_page + 1)
	_rebuild_weapon_cards()


func _on_wizard_back() -> void:
	if _wizard_step <= 0:
		_exit_pre_start_from_cancel()
		return
	_wizard_step -= 1
	_apply_wizard_step()


func _on_wizard_primary() -> void:
	if _wizard_step < 2:
		_wizard_step += 1
		_apply_wizard_step()
		return
	_on_start_button_pressed()


func _apply_wizard_step() -> void:
	var on_char: bool = _wizard_step == 0
	var on_weapon: bool = _wizard_step == 1
	var on_confirm: bool = _wizard_step == 2
	if _left_column != null:
		_left_column.visible = on_char
		_left_column.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if on_char else Control.SIZE_SHRINK_BEGIN
		)
	if _divider != null:
		_divider.visible = false
	if _right_column != null:
		_right_column.visible = on_weapon
		_right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _detail_column != null:
		_detail_column.visible = on_weapon
	if _confirm_panel != null:
		_confirm_panel.visible = on_confirm
	if _pager_row != null:
		_pager_row.visible = on_weapon and _weapon_page_count() > 1
	if _back_step_btn != null:
		_back_step_btn.visible = _wizard_step > 0
	if _start_button != null:
		if on_char:
			_start_button.text = "下一步：选武器"
		elif on_weapon:
			_start_button.text = "下一步：确认"
		else:
			_start_button.text = "开始游戏"
	if on_confirm:
		_fill_confirm_summary()
	if on_weapon:
		_rebuild_weapon_cards()


func _style_wizard_chrome_button(btn: Button, font_size: int) -> void:
	if _start_button != null and _start_button.theme != null:
		btn.theme = _start_button.theme
	btn.add_theme_font_override("font", MENU_FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62, 1.0))


func _fill_confirm_summary() -> void:
	if _confirm_label == null:
		return
	var character: Dictionary = CharacterData.find_character(str(GameSettings.selected_character_id))
	var wdef: Dictionary = WeaponCatalog.find_def(selected_weapon_id)
	var note: String = str(wdef.get("effect_note", "")).strip_edges()
	var body: String = str(wdef.get("card_desc", "")).strip_edges()
	if body.is_empty():
		body = str(wdef.get("short_desc", "")).strip_edges()
	_confirm_label.text = "角色：%s\n%s\n\n武器：%s\n%s\n%s" % [
		str(character.get("display_name", "野猪")),
		str(character.get("description", "")),
		str(wdef.get("display_name", selected_weapon_id)),
		body,
		("特效：" + note) if not note.is_empty() else "",
	]


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
	var unit: float = WEAPON_CARD_WIDTH_MAX + float(sep)
	if inner < unit * float(WEAPON_GRID_COLS_MIN) - float(sep):
		unit = WEAPON_CARD_WIDTH_MIN + float(sep)
	var fit_cols: int = int(floor((inner + float(sep)) / unit))
	cols = clampi(fit_cols, WEAPON_GRID_COLS_MIN, WEAPON_GRID_COLS_MAX)
	weapon_card_grid.columns = cols
	var cw: float = unit - float(sep)
	for c in weapon_card_grid.get_children():
		if c is Control:
			var ctl: Control = c as Control
			ctl.custom_minimum_size = Vector2(cw, WEAPON_CARD_MIN_HEIGHT)
			ctl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


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
	s.set_corner_radius_all(2)
	if selected:
		s.set_border_width_all(2)
		s.border_color = Color(0.95, 0.78, 0.32, 1.0)
	else:
		s.set_border_width_all(1)
		s.border_color = Color(1.0, 1.0, 1.0, 0.14)
	s.content_margin_left = 8.0
	s.content_margin_top = 8.0
	s.content_margin_right = 8.0
	s.content_margin_bottom = 8.0
	return s


func _weapon_card_tag_bg(_design_category: String) -> Color:
	return Color(0, 0, 0, 0.55)


func _weapon_card_emoji(weapon_id: String) -> String:
	return WeaponCatalog.display_emoji_for_weapon_id(weapon_id)


func _rebuild_weapon_cards() -> void:
	if weapon_card_grid == null:
		return
	for child in weapon_card_grid.get_children():
		child.queue_free()
	var total: int = weapon_defs.size()
	var pages: int = _weapon_page_count()
	_weapon_page = clampi(_weapon_page, 0, pages - 1)
	var start: int = _weapon_page * _weapon_page_size
	var end: int = mini(total, start + _weapon_page_size)
	for i in range(start, end):
		var weapon_def: Dictionary = weapon_defs[i]
		var weapon_id: String = str(weapon_def.get("id", ""))
		if weapon_id.is_empty():
			continue
		var card: PanelContainer = _build_weapon_card(weapon_def, weapon_id)
		weapon_card_grid.add_child(card)
	if _page_label != null:
		_page_label.text = "%d / %d" % [_weapon_page + 1, pages]
	if _prev_page_btn != null:
		_prev_page_btn.disabled = _weapon_page <= 0
	if _next_page_btn != null:
		_next_page_btn.disabled = _weapon_page >= pages - 1
	if _pager_row != null:
		_pager_row.visible = _wizard_step == 1 and pages > 1
	call_deferred("_reflow_weapon_card_widths")


func _build_weapon_card(weapon_def: Dictionary, weapon_id: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(WEAPON_CARD_WIDTH_MAX, WEAPON_CARD_MIN_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("weapon_id", weapon_id)
	card.add_theme_stylebox_override(
		"panel",
		_weapon_card_style_selected if weapon_id == selected_weapon_id else _weapon_card_style_normal
	)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(col)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	col.add_child(top)
	var emoji_lbl: Label = Label.new()
	emoji_lbl.text = _weapon_card_emoji(weapon_id)
	emoji_lbl.add_theme_font_size_override("font_size", 22)
	emoji_lbl.custom_minimum_size = Vector2(28, 28)
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(emoji_lbl)
	var title_lbl: Label = Label.new()
	title_lbl.text = str(weapon_def.get("display_name", weapon_id))
	title_lbl.add_theme_font_override("font", MENU_FONT)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1.0))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_lbl.max_lines_visible = 1
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_lbl)
	var design_cat: String = str(weapon_def.get("design_category", "")).strip_edges()
	if not design_cat.is_empty():
		var tag_wrap: PanelContainer = PanelContainer.new()
		var tag_sb: StyleBoxFlat = StyleBoxFlat.new()
		tag_sb.bg_color = _weapon_card_tag_bg(design_cat)
		tag_sb.set_corner_radius_all(2)
		tag_sb.set_border_width_all(1)
		tag_sb.border_color = Color(1, 1, 1, 0.28)
		tag_sb.content_margin_left = 6.0
		tag_sb.content_margin_top = 2.0
		tag_sb.content_margin_right = 6.0
		tag_sb.content_margin_bottom = 2.0
		tag_wrap.add_theme_stylebox_override("panel", tag_sb)
		var tag_lbl: Label = Label.new()
		tag_lbl.text = design_cat
		tag_lbl.add_theme_font_size_override("font_size", 12)
		tag_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92, 1.0))
		tag_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tag_lbl.max_lines_visible = 1
		tag_wrap.add_child(tag_lbl)
		col.add_child(tag_wrap)
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
	var card_body: String = str(weapon_def.get("card_desc", "")).strip_edges()
	if card_body.is_empty():
		card_body = str(weapon_def.get("short_desc", "")).strip_edges()
	if weapon_body_label != null:
		weapon_body_label.text = card_body
	var note: String = str(weapon_def.get("effect_note", "")).strip_edges()
	if weapon_effect_label != null:
		weapon_effect_label.text = ("特效：" + note) if not note.is_empty() else ""


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
