extends Control

const HOLD_PURCHASE_SECONDS: float = 3.0

const SHOP_PLACEHOLDERS: Array[Dictionary] = [
	{
		"id": "demo_skin_frost",
		"title": "冰蓝迷彩",
		"desc": "占位：未来可解锁的角色外观。当前为演示商品。",
		"price": 1200,
		"sprite_path": "res://assets/sprites/wildpig.png",
	},
	{
		"id": "demo_bundle",
		"title": "野猪补给包",
		"desc": "占位：内含随机强化素材（演示，不写入存档）。",
		"price": 800,
		"sprite_path": "res://assets/sprites/wildpig.png",
	},
	{
		"id": "demo_voice",
		"title": "战吼语音包",
		"desc": "占位：额外战斗语音与结算台词。",
		"price": 500,
		"sprite_path": "res://assets/sprites/wildpig.png",
	},
]

@onready var tab_container: TabContainer = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer
@onready var tab_btn_0: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn0
@onready var tab_btn_1: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn1
@onready var tab_btn_2: Button = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabBtn2
@onready var tab_sep_01: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep01
@onready var tab_sep_12: ColorRect = $Center/MainColumn/MainCard/Margins/CardColumn/TabButtonRow/TabSep12
@onready var shop_vbox: VBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/ShopScroll/ShopVBox
@onready var char_sprite: TextureRect = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/CharSprite
@onready var name_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/NameLabel
@onready var desc_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/DescLabel
@onready var page_label: Label = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/NavRow/PageLabel
@onready var select_button: Button = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/SelectButton
@onready var profile_contents: VBoxContainer = $Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/ProfileScroll/ProfileContents
@onready var back_button: Button = $Center/MainColumn/HeaderMargins/HeaderRow/BackButton
@onready var purchase_overlay: Control = $PurchaseOverlay
@onready var purchase_message: Label = $PurchaseOverlay/CenterContainer/DialogCard/Margin/Content/PurchaseMessage
@onready var purchase_no_button: Button = $PurchaseOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/PurchaseNoButton
@onready var yes_hold_button: Button = $PurchaseOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/YesHoldButton
@onready var yes_progress: ProgressBar = $PurchaseOverlay/CenterContainer/DialogCard/Margin/Content/ButtonRow/YesHoldButton/YesProgress
@onready var purchase_hold_timer: Timer = $PurchaseHoldTimer
@onready var shop_result_dialog: AcceptDialog = $ShopResultDialog

var characters: Array = []
var current_index: int = 0
var _tab_buttons: Array[Button] = []
var _tab_separators: Array[ColorRect] = []
var _style_active_normal: StyleBoxFlat
var _style_active_hover: StyleBoxFlat
var _style_inactive_normal: StyleBoxFlat
var _style_inactive_hover: StyleBoxFlat
var _pending_shop: Dictionary = {}
var _is_holding_yes: bool = false


func _ready() -> void:
	GameMusic.duck_for_subpage()
	_tab_buttons = [tab_btn_0, tab_btn_1, tab_btn_2]
	_tab_separators = [tab_sep_01, tab_sep_12]
	_build_tab_button_styles()
	for i: int in range(_tab_buttons.size()):
		_tab_buttons[i].pressed.connect(_switch_tab.bind(i))
	_switch_tab(0)
	characters = CharacterData.list_characters()
	if characters.is_empty():
		characters = [_default_character()]
	current_index = _find_selected_index()
	_refresh_display()
	_build_shop_cards()
	_build_profile_sections()
	back_button.pressed.connect(_on_back_button_pressed)
	$Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/NavRow/PrevButton.pressed.connect(_on_prev_button_pressed)
	$Center/MainColumn/MainCard/Margins/CardColumn/GalleryTabContainer/CharacterScroll/CharacterContents/NavRow/NextButton.pressed.connect(_on_next_button_pressed)
	select_button.pressed.connect(_on_select_button_pressed)
	purchase_no_button.pressed.connect(_close_purchase_overlay)
	yes_hold_button.button_down.connect(_on_yes_hold_down)
	yes_hold_button.button_up.connect(_on_yes_hold_up)
	purchase_hold_timer.timeout.connect(_on_purchase_hold_completed)
	shop_result_dialog.confirmed.connect(_on_shop_result_closed)
	_style_yes_progress_bar()
	yes_progress.value = 0.0


func _process(_delta: float) -> void:
	if not _is_holding_yes or purchase_hold_timer.is_stopped():
		return
	var elapsed: float = HOLD_PURCHASE_SECONDS - purchase_hold_timer.time_left
	yes_progress.value = clampf((elapsed / HOLD_PURCHASE_SECONDS) * 100.0, 0.0, 100.0)


func _build_tab_button_styles() -> void:
	const RADIUS := 2
	const MG_L := 16.0
	const MG_T := 8.0
	const MG_R := 16.0
	const MG_B := 8.0
	_style_active_normal = StyleBoxFlat.new()
	_style_active_normal.bg_color = Color(1, 1, 1, 1)
	_style_active_normal.set_corner_radius_all(RADIUS)
	_style_active_normal.content_margin_left = MG_L
	_style_active_normal.content_margin_top = MG_T
	_style_active_normal.content_margin_right = MG_R
	_style_active_normal.content_margin_bottom = MG_B
	_style_active_hover = _style_active_normal.duplicate() as StyleBoxFlat
	_style_inactive_normal = StyleBoxFlat.new()
	_style_inactive_normal.bg_color = Color(0, 0, 0, 0.55)
	_style_inactive_normal.set_corner_radius_all(RADIUS)
	_style_inactive_normal.content_margin_left = MG_L
	_style_inactive_normal.content_margin_top = MG_T
	_style_inactive_normal.content_margin_right = MG_R
	_style_inactive_normal.content_margin_bottom = MG_B
	_style_inactive_hover = _style_inactive_normal.duplicate() as StyleBoxFlat
	_style_inactive_hover.bg_color = Color(1, 1, 1, 0.75)


func _switch_tab(index: int) -> void:
	tab_container.current_tab = index
	for i: int in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i == index:
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
	for i: int in range(_tab_separators.size()):
		var sep: ColorRect = _tab_separators[i]
		var left_tab: CanvasItem = _tab_buttons[i]
		var right_tab: CanvasItem = _tab_buttons[i + 1]
		sep.visible = left_tab.visible and right_tab.visible


func _style_yes_progress_bar() -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.45)
	track.set_corner_radius_all(2)
	yes_progress.add_theme_stylebox_override("background", track)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.65, 1.0, 0.85)
	fill.set_corner_radius_all(2)
	yes_progress.add_theme_stylebox_override("fill", fill)


func _shop_card_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.42, 0.82, 0.38)
	sb.border_color = Color(0.55, 0.78, 1.0, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16.0
	sb.content_margin_top = 14.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 14.0
	return sb


func _build_shop_cards() -> void:
	for c in shop_vbox.get_children():
		c.queue_free()
	var font_bold: Font = load("res://assets/fonts/SourceHanSansSC-Bold.otf") as Font
	for item: Dictionary in SHOP_PLACEHOLDERS:
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _shop_card_style())
		shop_vbox.add_child(card)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		card.add_child(row)
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(96, 96)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var p: String = str(item.get("sprite_path", ""))
		if ResourceLoader.exists(p):
			tex_rect.texture = load(p) as Texture2D
		row.add_child(tex_rect)
		var text_col: VBoxContainer = VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 6)
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_col)
		var title_lbl: Label = Label.new()
		title_lbl.text = str(item.get("title", "商品"))
		title_lbl.add_theme_font_override("font", font_bold)
		title_lbl.add_theme_font_size_override("font_size", 24)
		text_col.add_child(title_lbl)
		var desc_lbl: Label = Label.new()
		desc_lbl.text = str(item.get("desc", ""))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 18)
		desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96, 0.92))
		text_col.add_child(desc_lbl)
		var price_lbl: Label = Label.new()
		price_lbl.text = "%d 金币（演示）" % int(item.get("price", 0))
		price_lbl.add_theme_font_size_override("font_size", 17)
		price_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.85))
		text_col.add_child(price_lbl)
		var buy: Button = Button.new()
		buy.text = "购买"
		buy.custom_minimum_size = Vector2(120, 48)
		buy.add_theme_font_override("font", font_bold)
		buy.add_theme_font_size_override("font_size", 20)
		buy.theme = load("res://themes/black_button_theme.tres") as Theme
		row.add_child(buy)
		buy.pressed.connect(_on_shop_buy_pressed.bind(item.duplicate()))


func _on_shop_buy_pressed(item: Dictionary) -> void:
	_pending_shop = item
	purchase_message.text = "是否购买「%s」？\n价格：%d 金币（演示，不扣款）" % [
		str(item.get("title", "")),
		int(item.get("price", 0)),
	]
	yes_progress.value = 0.0
	yes_hold_button.text = "是"
	purchase_overlay.visible = true


func _close_purchase_overlay() -> void:
	_cancel_yes_hold()
	purchase_overlay.visible = false
	_pending_shop.clear()


func _on_yes_hold_down() -> void:
	_is_holding_yes = true
	yes_progress.value = 0.0
	purchase_hold_timer.start(HOLD_PURCHASE_SECONDS)


func _on_yes_hold_up() -> void:
	if not _is_holding_yes:
		return
	_cancel_yes_hold()


func _cancel_yes_hold() -> void:
	_is_holding_yes = false
	if not purchase_hold_timer.is_stopped():
		purchase_hold_timer.stop()
	yes_progress.value = 0.0
	yes_hold_button.text = "是"


func _on_purchase_hold_completed() -> void:
	_is_holding_yes = false
	yes_progress.value = 100.0
	var title: String = str(_pending_shop.get("title", "商品"))
	_close_purchase_overlay()
	shop_result_dialog.dialog_text = "演示：已确认购买「%s」。\n（占位功能，未写入存档或解锁内容）" % title
	shop_result_dialog.popup_centered()


func _on_shop_result_closed() -> void:
	shop_result_dialog.hide()


func _section_title(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	var font_bold: Font = load("res://assets/fonts/SourceHanSansSC-Bold.otf") as Font
	if font_bold:
		l.add_theme_font_override("font", font_bold)
	return l


func _stat_line(label: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var a: Label = Label.new()
	a.text = label
	a.add_theme_font_size_override("font_size", 20)
	a.add_theme_color_override("font_color", Color(0.82, 0.8, 0.76, 1))
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	var b: Label = Label.new()
	b.text = value
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 1))
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(b)
	return row


func _build_profile_sections() -> void:
	for c in profile_contents.get_children():
		c.queue_free()
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best_wave: int = int(meta.get("best_wave", 0))
	var run_count: int = int(meta.get("runs", 0))
	var victory_count: int = int(meta.get("victories", 0))
	var has_save: bool = SaveManager.has_save_file()
	var has_pending: bool = SaveManager.has_pending_run()
	var pending_summary: Dictionary = SaveManager.get_pending_run_summary()
	var pending_wave: int = int(pending_summary.get("wave_index", 0))
	var pending_char: String = str(pending_summary.get("character_id", "—"))
	var tutorial_done: bool = SaveManager.get_tutorial_completed()
	profile_contents.add_child(_section_title("战绩概览"))
	profile_contents.add_child(_stat_line("历史最高波次", "%d" % best_wave))
	profile_contents.add_child(_stat_line("累计开局次数", "%d" % run_count))
	profile_contents.add_child(_stat_line("通关次数", "%d" % victory_count))
	profile_contents.add_child(_section_title("进度与教程"))
	profile_contents.add_child(_stat_line("新手引导已完成", "是" if tutorial_done else "否"))
	profile_contents.add_child(_section_title("存档与续玩"))
	profile_contents.add_child(_stat_line("存档文件", "存在" if has_save else "无"))
	if has_pending:
		profile_contents.add_child(_stat_line("续玩进度", "第 %d 波 · 角色 %s" % [pending_wave, pending_char]))
	else:
		profile_contents.add_child(_stat_line("续玩进度", "无进行中存档"))
	profile_contents.add_child(_section_title("当前选择"))
	var sel_id: String = str(GameSettings.selected_character_id)
	var ch: Dictionary = CharacterData.find_character(sel_id)
	profile_contents.add_child(_stat_line("出战角色", str(ch.get("display_name", sel_id))))


func _find_selected_index() -> int:
	var selected_id: String = str(GameSettings.selected_character_id)
	var index: int = 0
	for i: int in range(characters.size()):
		var item: Variant = characters[i]
		if not item is Dictionary:
			continue
		var character: Dictionary = item as Dictionary
		if str(character.get("id", "")) == selected_id:
			index = i
			break
	return index


func _get_current_character() -> Dictionary:
	if current_index < 0 or current_index >= characters.size():
		return _default_character()
	var item: Variant = characters[current_index]
	if item is Dictionary:
		return item as Dictionary
	return _default_character()


func _refresh_display() -> void:
	var character: Dictionary = _get_current_character()
	var character_name: String = str(character.get("display_name", "未知角色"))
	var character_desc: String = str(character.get("description", "暂无介绍"))
	var character_id: String = str(character.get("id", "default"))
	var unlocked: bool = CharacterData.is_character_unlocked(character)
	var selected_id: String = str(GameSettings.selected_character_id)
	var is_selected: bool = selected_id == character_id
	if not unlocked:
		name_label.text = "%s（未解锁）" % character_name
	else:
		name_label.text = character_name
	desc_label.text = character_desc
	page_label.text = "%d / %d" % [current_index + 1, max(1, characters.size())]
	_refresh_sprite(character)
	if not unlocked:
		select_button.disabled = true
		select_button.text = "未解锁"
	elif is_selected:
		select_button.disabled = true
		select_button.text = "已选择 ✓"
	else:
		select_button.disabled = false
		select_button.text = "选择该角色"


func _refresh_sprite(character: Dictionary) -> void:
	var sprite_path: String = str(character.get("sprite_path", "res://assets/sprites/wildpig.png"))
	if not ResourceLoader.exists(sprite_path):
		char_sprite.texture = null
		return
	var texture: Texture2D = load(sprite_path) as Texture2D
	char_sprite.texture = texture


func _on_prev_button_pressed() -> void:
	if characters.is_empty():
		return
	current_index = posmod(current_index - 1, characters.size())
	_refresh_display()


func _on_next_button_pressed() -> void:
	if characters.is_empty():
		return
	current_index = posmod(current_index + 1, characters.size())
	_refresh_display()


func _on_select_button_pressed() -> void:
	var character: Dictionary = _get_current_character()
	if not CharacterData.is_character_unlocked(character):
		return
	var character_id: String = str(character.get("id", "default"))
	GameSettings.set_selected_character_id(character_id)
	_refresh_display()
	_build_profile_sections()


func _on_back_button_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file(str(RunState.gallery_return_scene_path))


func _default_character() -> Dictionary:
	return {
		"id": "default",
		"display_name": "标准野猪",
		"description": "平衡型角色。",
		"sprite_path": "res://assets/sprites/wildpig.png",
	}
