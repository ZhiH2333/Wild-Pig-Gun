extends Control
## CommunityScreen — 社区功能页面。
## TabContainer 含三个 Tab：排行榜 / 游戏动态 / 我的名片。
## 未登录时显示提示并提供快速登录入口。

const FONT_PATH: String = "res://assets/fonts/SourceHanSansSC-Bold.otf"
const BLACK_BTN: Theme = preload("res://themes/black_button_theme.tres")
const SETTINGS_TAB_THEME: Theme = preload("res://themes/settings_tab_theme.tres")

const LOGIN_SCENE: PackedScene = preload("res://scenes/ui/login_wppass_flow.tscn")

const PAGE_SIZE: int = 20
const LEADERBOARD_TYPE: String = "wave"

var _font: Font
var _tab_container: TabContainer
var _lb_list: VBoxContainer
var _lb_scroll: ScrollContainer
var _lb_status: Label
var _feed_list: VBoxContainer
var _feed_scroll: ScrollContainer
var _feed_status: Label
var _profile_col: VBoxContainer
var _profile_status: Label
var _lb_loaded: bool = false
var _feed_loaded: bool = false
var _profile_loaded: bool = false


func _ready() -> void:
	_font = load(FONT_PATH) as Font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	CloudAPI.login_state_changed.connect(_on_login_state_changed)
	call_deferred("_initial_load")


func _initial_load() -> void:
	var tab: int = _tab_container.current_tab
	_load_tab(tab)


# ── UI 构建 ──────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.04, 0.07, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var root_col: VBoxContainer = VBoxContainer.new()
	root_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_col.add_theme_constant_override("separation", 0)
	add_child(root_col)
	var top_bar: HBoxContainer = _make_top_bar()
	root_col.add_child(top_bar)
	_tab_container = _make_tab_container()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_child(_tab_container)
	_tab_container.tab_changed.connect(_on_tab_changed)


func _make_top_bar() -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 72)
	bar.add_theme_constant_override("separation", 0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.1, 0.98)
	sb.border_width_bottom = 1
	sb.border_color = Color(1, 1, 1, 0.12)
	bar.add_theme_stylebox_override("panel", sb)
	var back_btn: Button = Button.new()
	back_btn.text = "← 返回"
	back_btn.theme = BLACK_BTN
	back_btn.custom_minimum_size = Vector2(120, 52)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_font(back_btn, 20)
	var left_pad: Control = Control.new()
	left_pad.custom_minimum_size = Vector2(16, 0)
	bar.add_child(left_pad)
	bar.add_child(back_btn)
	var title: Label = Label.new()
	title.text = "社区"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(title, 28)
	bar.add_child(title)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(136, 0)
	bar.add_child(spacer)
	back_btn.pressed.connect(_on_back_pressed)
	return bar


func _make_tab_container() -> TabContainer:
	var tc: TabContainer = TabContainer.new()
	tc.theme = SETTINGS_TAB_THEME
	var lb_tab: Control = _make_leaderboard_tab()
	lb_tab.name = "排行榜"
	tc.add_child(lb_tab)
	var feed_tab: Control = _make_feed_tab()
	feed_tab.name = "游戏动态"
	tc.add_child(feed_tab)
	var profile_tab: Control = _make_profile_tab()
	profile_tab.name = "我的名片"
	tc.add_child(profile_tab)
	return tc


func _make_leaderboard_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	header.add_theme_constant_override("separation", 16)
	var pad: Control = Control.new()
	pad.custom_minimum_size = Vector2(20, 0)
	header.add_child(pad)
	_lb_status = Label.new()
	_lb_status.text = "加载中…"
	_lb_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lb_status.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68, 1))
	_lb_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_font(_lb_status, 18)
	header.add_child(_lb_status)
	var refresh_btn: Button = Button.new()
	refresh_btn.text = "刷新"
	refresh_btn.theme = BLACK_BTN
	refresh_btn.custom_minimum_size = Vector2(100, 44)
	refresh_btn.focus_mode = Control.FOCUS_NONE
	refresh_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_font(refresh_btn, 18)
	refresh_btn.pressed.connect(_load_leaderboard)
	header.add_child(refresh_btn)
	var pad2: Control = Control.new()
	pad2.custom_minimum_size = Vector2(20, 0)
	header.add_child(pad2)
	root.add_child(header)
	_lb_scroll = ScrollContainer.new()
	_lb_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lb_list = VBoxContainer.new()
	_lb_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lb_list.add_theme_constant_override("separation", 6)
	_lb_scroll.add_child(_lb_list)
	root.add_child(_lb_scroll)
	return root


func _make_feed_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	header.add_theme_constant_override("separation", 16)
	var pad: Control = Control.new()
	pad.custom_minimum_size = Vector2(20, 0)
	header.add_child(pad)
	_feed_status = Label.new()
	_feed_status.text = "加载中…"
	_feed_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_status.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68, 1))
	_feed_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_font(_feed_status, 18)
	header.add_child(_feed_status)
	var refresh_btn: Button = Button.new()
	refresh_btn.text = "刷新"
	refresh_btn.theme = BLACK_BTN
	refresh_btn.custom_minimum_size = Vector2(100, 44)
	refresh_btn.focus_mode = Control.FOCUS_NONE
	refresh_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_font(refresh_btn, 18)
	refresh_btn.pressed.connect(_load_feed)
	header.add_child(refresh_btn)
	var pad2: Control = Control.new()
	pad2.custom_minimum_size = Vector2(20, 0)
	header.add_child(pad2)
	root.add_child(header)
	_feed_scroll = ScrollContainer.new()
	_feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feed_list = VBoxContainer.new()
	_feed_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_list.add_theme_constant_override("separation", 8)
	_feed_scroll.add_child(_feed_list)
	root.add_child(_feed_scroll)
	return root


func _make_profile_tab() -> Control:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_profile_col = VBoxContainer.new()
	_profile_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_col.add_theme_constant_override("separation", 16)
	var pad: MarginContainer = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_bottom", 24)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_profile_col)
	scroll.add_child(pad)
	_profile_status = Label.new()
	_profile_status.text = "加载中…"
	_profile_status.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68, 1))
	_apply_font(_profile_status, 18)
	_profile_col.add_child(_profile_status)
	return scroll


# ── 数据加载 ─────────────────────────────────────────────────────────────────

func _on_tab_changed(tab: int) -> void:
	_load_tab(tab)


func _load_tab(tab: int) -> void:
	if not CloudAPI.is_logged_in():
		return
	match tab:
		0:
			if not _lb_loaded:
				_load_leaderboard()
		1:
			if not _feed_loaded:
				_load_feed()
		2:
			if not _profile_loaded:
				_load_profile()


func _load_leaderboard() -> void:
	_lb_status.text = "加载中…"
	_clear_children(_lb_list)
	if not CloudAPI.is_logged_in():
		_lb_status.text = "请先登录"
		_append_login_prompt(_lb_list)
		return
	var result: Dictionary = await CloudAPI.get_leaderboard(LEADERBOARD_TYPE, PAGE_SIZE)
	if not result["ok"]:
		_lb_status.text = "加载失败：" + result["error"]
		return
	var data: Dictionary = result["data"]
	var entries: Array = data.get("entries", data.get("leaderboard", [])) as Array
	if entries.is_empty():
		_lb_status.text = "暂无数据"
		return
	_lb_status.text = "共 %d 名" % entries.size()
	for i: int in range(entries.size()):
		var entry: Variant = entries[i]
		if entry is Dictionary:
			_lb_list.add_child(_make_lb_row(i + 1, entry as Dictionary))
	_lb_loaded = true


func _load_feed() -> void:
	_feed_status.text = "加载中…"
	_clear_children(_feed_list)
	if not CloudAPI.is_logged_in():
		_feed_status.text = "请先登录"
		_append_login_prompt(_feed_list)
		return
	var result: Dictionary = await CloudAPI.get_feed(1, PAGE_SIZE)
	if not result["ok"]:
		_feed_status.text = "加载失败：" + result["error"]
		return
	var data: Dictionary = result["data"]
	var items: Array = data.get("items", data.get("feed", [])) as Array
	if items.is_empty():
		_feed_status.text = "暂无动态"
		return
	_feed_status.text = "最新动态"
	for item: Variant in items:
		if item is Dictionary:
			_feed_list.add_child(_make_feed_card(item as Dictionary))
	_feed_loaded = true


func _load_profile() -> void:
	_profile_status.text = "加载中…"
	_clear_children(_profile_col)
	_profile_col.add_child(_profile_status)
	if not CloudAPI.is_logged_in():
		_profile_status.text = "请先登录"
		_append_login_prompt(_profile_col)
		return
	var uid: String = CloudAPI.get_user_id()
	var result: Dictionary = await CloudAPI.get_profile(uid)
	if not result["ok"]:
		_profile_status.text = "加载失败：" + result["error"]
		return
	var data: Dictionary = result["data"]
	_profile_status.text = ""
	_build_profile_content(data)
	_profile_loaded = true


# ── 卡片构建 ─────────────────────────────────────────────────────────────────

func _make_lb_row(rank: int, entry: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var rank_label: Label = Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(52, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_rank_color(rank_label, rank)
	_apply_font(rank_label, 22)
	row.add_child(rank_label)
	var name_label: Label = Label.new()
	var player_name: String = str(entry.get("username", entry.get("user_id", "匿名")))
	name_label.text = player_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1))
	_apply_font(name_label, 20)
	row.add_child(name_label)
	var score_label: Label = Label.new()
	var score_key: String = "score" if entry.has("score") else "best_wave"
	score_label.text = str(entry.get(score_key, 0))
	score_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.32, 1))
	_apply_font(score_label, 20)
	row.add_child(score_label)
	return card


func _make_feed_card(item: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	col.add_child(header_row)
	var player_name: String = str(item.get("username", item.get("user_id", "匿名")))
	var name_lbl: Label = Label.new()
	name_lbl.text = player_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.32, 1))
	_apply_font(name_lbl, 18)
	header_row.add_child(name_lbl)
	var wave: int = int(item.get("wave_reached", item.get("wave", 0)))
	var result_lbl: Label = Label.new()
	result_lbl.text = "第 %d 波" % wave
	result_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72, 1))
	_apply_font(result_lbl, 18)
	header_row.add_child(result_lbl)
	var char_id: String = str(item.get("character_id", ""))
	if not char_id.is_empty():
		var char_lbl: Label = Label.new()
		char_lbl.text = char_id
		char_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.58, 1))
		_apply_font(char_lbl, 16)
		col.add_child(char_lbl)
	var like_count: int = int(item.get("likes", 0))
	var run_id: String = str(item.get("id", item.get("run_id", "")))
	if not run_id.is_empty():
		var btn_row: HBoxContainer = HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_END
		col.add_child(btn_row)
		var like_btn: Button = Button.new()
		like_btn.text = "赞  %d" % like_count
		like_btn.theme = BLACK_BTN
		like_btn.custom_minimum_size = Vector2(90, 36)
		like_btn.focus_mode = Control.FOCUS_NONE
		_apply_font(like_btn, 16)
		like_btn.pressed.connect(_on_like_pressed.bind(run_id, like_btn))
		btn_row.add_child(like_btn)
	return card


func _build_profile_content(data: Dictionary) -> void:
	var username: String = str(data.get("username", data.get("email", "未知用户")))
	var name_lbl: Label = Label.new()
	name_lbl.text = username
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(name_lbl, 32)
	_profile_col.add_child(name_lbl)
	var sep: HSeparator = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 1)
	_profile_col.add_child(sep)
	var stats: Dictionary = data.get("stats", data) as Dictionary
	for field: String in ["best_wave", "total_runs", "total_victories", "total_play_seconds"]:
		var val: Variant = stats.get(field, data.get(field, null))
		if val == null:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_profile_col.add_child(row)
		var key_lbl: Label = Label.new()
		key_lbl.text = _stat_display_name(field)
		key_lbl.custom_minimum_size = Vector2(180, 0)
		key_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68, 1))
		_apply_font(key_lbl, 20)
		row.add_child(key_lbl)
		var val_lbl: Label = Label.new()
		val_lbl.text = _stat_format_value(field, val)
		val_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1))
		_apply_font(val_lbl, 20)
		row.add_child(val_lbl)
	var sync_btn: Button = Button.new()
	sync_btn.text = "立即同步"
	sync_btn.theme = BLACK_BTN
	sync_btn.custom_minimum_size = Vector2(180, 52)
	sync_btn.focus_mode = Control.FOCUS_NONE
	_apply_font(sync_btn, 20)
	sync_btn.pressed.connect(_on_sync_now_pressed.bind(sync_btn))
	_profile_col.add_child(sync_btn)


# ── 事件处理 ─────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_like_pressed(run_id: String, btn: Button) -> void:
	btn.disabled = true
	await CloudAPI.like_run(run_id)
	btn.disabled = false


func _on_sync_now_pressed(btn: Button) -> void:
	btn.disabled = true
	btn.text = "同步中…"
	await CloudSync.sync_now()
	btn.text = "立即同步"
	btn.disabled = false
	_profile_loaded = false
	_load_profile()


func _on_login_state_changed(logged_in: bool) -> void:
	if logged_in:
		_lb_loaded = false
		_feed_loaded = false
		_profile_loaded = false
		_load_tab(_tab_container.current_tab)
	else:
		_lb_status.text = "请先登录"
		_feed_status.text = "请先登录"
		_profile_status.text = "请先登录"


# ── 辅助 ─────────────────────────────────────────────────────────────────────

func _append_login_prompt(parent: Control) -> void:
	var lbl: Label = Label.new()
	lbl.text = "登录后可查看"
	lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.58, 1))
	_apply_font(lbl, 18)
	parent.add_child(lbl)
	var btn: Button = Button.new()
	btn.text = "登录 WP Pass"
	btn.theme = BLACK_BTN
	btn.custom_minimum_size = Vector2(180, 52)
	btn.focus_mode = Control.FOCUS_NONE
	_apply_font(btn, 20)
	btn.pressed.connect(_show_login_flow)
	parent.add_child(btn)


func _show_login_flow() -> void:
	for c in get_children():
		if c is LoginWppassFlow:
			return
	var flow: LoginWppassFlow = LOGIN_SCENE.instantiate() as LoginWppassFlow
	flow.login_completed.connect(func(_username: String) -> void:
		_lb_loaded = false
		_feed_loaded = false
		_profile_loaded = false
		_load_tab(_tab_container.current_tab)
	)
	add_child(flow)


func _clear_children(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()


func _make_card_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.content_margin_left = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 12.0
	sb.bg_color = Color(0.08, 0.07, 0.1, 0.92)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.14)
	sb.set_corner_radius_all(4)
	return sb


func _apply_rank_color(lbl: Label, rank: int) -> void:
	match rank:
		1:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1))
		2:
			lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
		3:
			lbl.add_theme_color_override("font_color", Color(0.80, 0.50, 0.20, 1))
		_:
			lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68, 0.85))


func _stat_display_name(field: String) -> String:
	match field:
		"best_wave": return "最高波次"
		"total_runs": return "总局数"
		"total_victories": return "胜利次数"
		"total_play_seconds": return "游戏时长"
	return field


func _stat_format_value(field: String, val: Variant) -> String:
	if field == "total_play_seconds":
		var secs: int = int(float(str(val)))
		var hours: int = secs / 3600
		var mins: int = (secs % 3600) / 60
		return "%d 小时 %d 分" % [hours, mins]
	return str(val)


func _apply_font(node: Control, size: int) -> void:
	if _font != null:
		node.add_theme_font_override("font", _font)
		node.add_theme_font_size_override("font_size", size)
