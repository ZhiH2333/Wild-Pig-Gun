extends Control

const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"
const ARENA_SCENE: String = "res://scenes/arena.tscn"
const CLEAR_HOLD_SECONDS: float = 2.0

const BLACK_BTN: Theme = preload("res://themes/black_button_theme.tres")
const MENU_FONT: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")

@onready var _back_button: Button = $Center/MainColumn/HeaderMargins/HeaderRow/BackButton
@onready var _tab_manage: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabManage
@onready var _tab_journey: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabJourney
@onready var _manage_page: Control = $Center/MainColumn/MainCard/Margins/CardColumn/BodyStack/ManagePage
@onready var _journey_page: Control = $Center/MainColumn/MainCard/Margins/CardColumn/BodyStack/JourneyPage
@onready var _slot_list: VBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/BodyStack/ManagePage/Scroll/SlotList
@onready var _detail_overlay: Control = $SlotDetailOverlay
@onready var _detail_title: Label = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/TitleLabel
@onready var _detail_body: RichTextLabel = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/DetailRichText
@onready var _detail_close: Button = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/CloseButton
@onready var _detail_delete_btn: Button = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/DeleteSlotButton
@onready var _detail_delete_progress: ProgressBar = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/DeleteSlotButton/DeleteHoldProgress
@onready var _detail_delete_label: Label = $SlotDetailOverlay/CenterContainer/DialogCard/Margin/Content/DeleteSlotButton/DeleteHoldLabel
@onready var _delete_hold_timer: Timer = $DeleteHoldTimer

var _tab_buttons: Array[Button] = []
var _style_active_normal: StyleBoxFlat
var _style_active_hover: StyleBoxFlat
var _style_inactive_normal: StyleBoxFlat
var _style_inactive_hover: StyleBoxFlat
var _current_tab: int = 0
var _pre_start_instance: Control = null
var _detail_slot_id: String = ""
var _is_holding_delete: bool = false


func _ready() -> void:
	add_to_group("game_start")
	GameMusic.duck_for_subpage()
	_tab_buttons = [_tab_manage, _tab_journey]
	_build_tab_styles()
	for i: int in range(_tab_buttons.size()):
		_tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
	_switch_tab(0)
	_back_button.pressed.connect(_on_back_pressed)
	_detail_close.pressed.connect(_close_detail_overlay)
	_detail_delete_btn.button_down.connect(_on_delete_btn_down)
	_detail_delete_btn.button_up.connect(_on_delete_btn_up)
	_delete_hold_timer.timeout.connect(_on_delete_hold_finished)
	_delete_hold_timer.wait_time = CLEAR_HOLD_SECONDS
	_style_delete_slot_button_and_progress()
	_instantiate_pre_start()


func _style_delete_slot_button_and_progress() -> void:
	const RED_BTN: Color = Color(0.92, 0.14, 0.14, 0.42)
	const RED_BTN_H: Color = Color(1.0, 0.22, 0.22, 0.52)
	const RED_BTN_P: Color = Color(0.72, 0.08, 0.08, 0.52)
	var r: float = 8.0
	var sb_n: StyleBoxFlat = StyleBoxFlat.new()
	sb_n.bg_color = RED_BTN
	sb_n.set_corner_radius_all(r)
	sb_n.content_margin_left = 16.0
	sb_n.content_margin_top = 12.0
	sb_n.content_margin_right = 16.0
	sb_n.content_margin_bottom = 12.0
	_detail_delete_btn.add_theme_stylebox_override("normal", sb_n)
	var sb_h: StyleBoxFlat = sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = RED_BTN_H
	_detail_delete_btn.add_theme_stylebox_override("hover", sb_h)
	var sb_p: StyleBoxFlat = sb_n.duplicate() as StyleBoxFlat
	sb_p.bg_color = RED_BTN_P
	_detail_delete_btn.add_theme_stylebox_override("pressed", sb_p)
	_detail_delete_btn.add_theme_stylebox_override("focus", sb_n)
	_detail_delete_btn.flat = false
	_detail_delete_btn.text = ""
	_detail_delete_btn.tooltip_text = "删除此存档（需长按）"
	_detail_delete_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_detail_delete_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	_detail_delete_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.12)
	track.set_corner_radius_all(6)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.08, 0.06, 1)
	fill.set_corner_radius_all(6)
	_detail_delete_progress.add_theme_stylebox_override("background", track)
	_detail_delete_progress.add_theme_stylebox_override("fill", fill)
	_detail_delete_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))


func _instantiate_pre_start() -> void:
	var ps: PackedScene = load("res://scenes/pre_start.tscn") as PackedScene
	if ps == null:
		return
	_pre_start_instance = ps.instantiate() as Control
	_pre_start_instance.set_meta("game_start_embedded", true)
	_journey_page.add_child(_pre_start_instance)
	_pre_start_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pre_start_instance.offset_left = 0
	_pre_start_instance.offset_top = 0
	_pre_start_instance.offset_right = 0
	_pre_start_instance.offset_bottom = 0
	for bg_name: String in ["BlurredBackground", "DimOverlay", "Vignette"]:
		var bg: Node = _pre_start_instance.get_node_or_null(bg_name)
		if bg is CanvasItem:
			(bg as CanvasItem).visible = false


func show_manage_tab() -> void:
	_switch_tab(0)
	_refresh_slot_cards()


func _on_back_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _build_tab_styles() -> void:
	const RADIUS := 2
	const MG := 16.0
	const MGT := 8.0
	_style_active_normal = StyleBoxFlat.new()
	_style_active_normal.bg_color = Color(1, 1, 1, 1)
	_style_active_normal.set_corner_radius_all(RADIUS)
	_style_active_normal.content_margin_left = MG
	_style_active_normal.content_margin_top = MGT
	_style_active_normal.content_margin_right = MG
	_style_active_normal.content_margin_bottom = MGT
	_style_active_hover = _style_active_normal.duplicate() as StyleBoxFlat
	_style_inactive_normal = StyleBoxFlat.new()
	_style_inactive_normal.bg_color = Color(0, 0, 0, 0.55)
	_style_inactive_normal.set_corner_radius_all(RADIUS)
	_style_inactive_normal.content_margin_left = MG
	_style_inactive_normal.content_margin_top = MGT
	_style_inactive_normal.content_margin_right = MG
	_style_inactive_normal.content_margin_bottom = MGT
	_style_inactive_hover = _style_inactive_normal.duplicate() as StyleBoxFlat
	_style_inactive_hover.bg_color = Color(1, 1, 1, 0.75)


func _apply_tab_style(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", _style_active_normal)
		btn.add_theme_stylebox_override("hover", _style_active_hover)
		btn.add_theme_stylebox_override("pressed", _style_active_normal)
		btn.add_theme_stylebox_override("focus", _style_active_normal)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_color", Color.BLACK)
		btn.add_theme_color_override("font_pressed_color", Color.BLACK)
		btn.add_theme_color_override("font_focus_color", Color.BLACK)
	else:
		btn.add_theme_stylebox_override("normal", _style_inactive_normal)
		btn.add_theme_stylebox_override("hover", _style_inactive_hover)
		btn.add_theme_stylebox_override("pressed", _style_inactive_normal)
		btn.add_theme_stylebox_override("focus", _style_inactive_normal)
		btn.remove_theme_color_override("font_color")
		btn.remove_theme_color_override("font_hover_color")
		btn.remove_theme_color_override("font_pressed_color")
		btn.remove_theme_color_override("font_focus_color")


func _on_tab_pressed(index: int) -> void:
	_switch_tab(index)


func _switch_tab(index: int) -> void:
	_current_tab = clampi(index, 0, 1)
	for i: int in range(_tab_buttons.size()):
		_apply_tab_style(_tab_buttons[i], i == _current_tab)
	_manage_page.visible = (_current_tab == 0)
	_journey_page.visible = (_current_tab == 1)
	if _current_tab == 0:
		_refresh_slot_cards()


func _refresh_slot_cards() -> void:
	for c in _slot_list.get_children():
		c.queue_free()
	var ids: PackedStringArray = SaveManager.list_slot_ids_chronological()
	if ids.is_empty():
		var hint: Label = Label.new()
		hint.text = "暂无存档。请切换到「开始新旅程」创建新存档。"
		hint.add_theme_font_override("font", MENU_FONT)
		hint.add_theme_font_size_override("font_size", 20)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_slot_list.add_child(hint)
		return
	for sid in ids:
		var entry: Dictionary = SaveManager.get_slot_entry(str(sid))
		_slot_list.add_child(_build_slot_card(str(sid), entry))


func _build_slot_card(slot_id: String, entry: Dictionary) -> Control:
	var run: Dictionary = {}
	var raw_run: Variant = entry.get("run", {})
	if raw_run is Dictionary:
		run = raw_run as Dictionary
	var panel: PanelContainer = PanelContainer.new()
	var flat: StyleBoxFlat = StyleBoxFlat.new()
	flat.bg_color = Color(0.10, 0.09, 0.14, 0.72)
	flat.border_color = Color(0.35, 0.30, 0.45, 0.55)
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", flat)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = str(entry.get("display_name", "存档"))
	name_edit.add_theme_font_override("font", MENU_FONT)
	name_edit.add_theme_font_size_override("font_size", 22)
	name_edit.focus_exited.connect(_on_slot_name_focus_exited.bind(slot_id, name_edit))
	left.add_child(name_edit)
	var created: int = int(entry.get("created_unix", 0))
	var prog: Label = Label.new()
	prog.text = SaveDisplay.format_run_progress(run)
	prog.add_theme_font_size_override("font_size", 18)
	prog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(prog)
	var meta_line: Label = Label.new()
	meta_line.add_theme_font_size_override("font_size", 16)
	meta_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_line.text = _format_slot_meta_line(run, entry)
	left.add_child(meta_line)
	var date_lbl: Label = Label.new()
	date_lbl.add_theme_font_size_override("font_size", 15)
	date_lbl.modulate = Color(0.75, 0.72, 0.68, 1)
	date_lbl.text = "创建于 %s" % SaveDisplay.format_unix_date(created)
	left.add_child(date_lbl)
	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	var start_btn: Button = Button.new()
	start_btn.text = "开始游戏"
	start_btn.custom_minimum_size = Vector2(168, 52)
	start_btn.theme = BLACK_BTN
	start_btn.add_theme_font_override("font", MENU_FONT)
	start_btn.add_theme_font_size_override("font_size", 22)
	start_btn.pressed.connect(_on_slot_start_pressed.bind(slot_id, run))
	right.add_child(start_btn)
	var more_btn: Button = Button.new()
	more_btn.text = "更多"
	more_btn.custom_minimum_size = Vector2(168, 48)
	more_btn.theme = BLACK_BTN
	more_btn.add_theme_font_override("font", MENU_FONT)
	more_btn.add_theme_font_size_override("font_size", 20)
	more_btn.pressed.connect(_on_slot_more_pressed.bind(slot_id, entry, run))
	right.add_child(more_btn)
	return panel


func _format_slot_meta_line(run: Dictionary, entry: Dictionary) -> String:
	var rs: Variant = run.get("run_state", {})
	var char_id: String = "default"
	var lvl: int = 1
	if rs is Dictionary:
		char_id = str((rs as Dictionary).get("character_id", "default"))
		lvl = int((rs as Dictionary).get("player_level", 1))
	var ch: Dictionary = CharacterData.find_character(char_id)
	var cname: String = str(ch.get("display_name", char_id))
	var wparts: PackedStringArray = PackedStringArray()
	var wv: Variant = run.get("weapons", [])
	if wv is Array:
		for x in wv as Array:
			var wid: String = str(x)
			var def: Dictionary = WeaponCatalog.find_def(wid)
			wparts.append(str(def.get("display_name", wid)))
	var wstr: String = "—"
	if wparts.size() > 0:
		wstr = ""
		for i: int in range(wparts.size()):
			if i > 0:
				wstr += "、"
			wstr += wparts[i]
	return "角色：%s  ·  Lv.%d  ·  武器：%s" % [cname, lvl, wstr]


func _on_slot_name_focus_exited(slot_id: String, le: LineEdit) -> void:
	SaveManager.set_slot_display_name(slot_id, le.text)


func _on_slot_start_pressed(slot_id: String, run: Dictionary) -> void:
	SaveManager.set_last_played_slot_id(slot_id)
	SaveManager.active_save_slot_id = slot_id
	if SaveManager.slot_has_resumable_run(slot_id):
		get_tree().change_scene_to_file(ARENA_SCENE)
		return
	var cid: String = str(GameSettings.selected_character_id)
	var wids: Array = CharacterData.get_starting_weapon_ids(cid)
	var wid: String = WeaponCatalog.DEFAULT_STARTER_WEAPON_ID if wids.is_empty() else str(wids[0])
	RunState.begin_new_run(cid, 1.0)
	RunState.selected_starting_weapon_ids = [wid]
	get_tree().change_scene_to_file(ARENA_SCENE)


func _on_slot_more_pressed(slot_id: String, entry: Dictionary, run: Dictionary) -> void:
	_detail_slot_id = slot_id
	_detail_title.text = str(entry.get("display_name", "存档"))
	var abs_save: String = ProjectSettings.globalize_path(SaveManager.SAVE_PATH)
	var play_sec: int = int(entry.get("play_time_sec", 0))
	var body: String = (
		"游玩总时长：%s\n创建：%s\n最后修改：%s\n\n存档文件：\n%s"
		% [
			SaveDisplay.format_hms(play_sec),
			SaveDisplay.format_unix_date(int(entry.get("created_unix", 0))),
			SaveDisplay.format_unix_date(int(entry.get("modified_unix", 0))),
			abs_save,
		]
	)
	_detail_body.text = body
	_cancel_delete_hold()
	_detail_overlay.visible = true


func _close_detail_overlay() -> void:
	_cancel_delete_hold()
	_detail_overlay.visible = false
	_detail_slot_id = ""


func _on_delete_btn_down() -> void:
	if _detail_slot_id.is_empty():
		return
	_is_holding_delete = true
	_detail_delete_progress.value = 0.0
	_detail_delete_label.text = "长按 %d 秒删除" % int(CLEAR_HOLD_SECONDS)
	_delete_hold_timer.start(CLEAR_HOLD_SECONDS)


func _on_delete_btn_up() -> void:
	if not _is_holding_delete:
		return
	_cancel_delete_hold()


func _cancel_delete_hold() -> void:
	_is_holding_delete = false
	if not _delete_hold_timer.is_stopped():
		_delete_hold_timer.stop()
	_detail_delete_progress.value = 0.0
	_detail_delete_label.text = "删除此存档"


func _on_delete_hold_finished() -> void:
	_is_holding_delete = false
	_detail_delete_progress.value = 100.0
	if not _detail_slot_id.is_empty():
		SaveManager.delete_slot(_detail_slot_id)
	_close_detail_overlay()
	_refresh_slot_cards()


func _process(_delta: float) -> void:
	if not _is_holding_delete or _delete_hold_timer.is_stopped():
		return
	var held: float = CLEAR_HOLD_SECONDS - _delete_hold_timer.time_left
	_detail_delete_progress.value = clampf((held / CLEAR_HOLD_SECONDS) * 100.0, 0.0, 100.0)
