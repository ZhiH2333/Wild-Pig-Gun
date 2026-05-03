extends Control

const MENU_BUTTON_CONTAINER_PATH: String = "MenuButtonsWrap/LeftMenuColumn/ButtonContainer"
# const TUTORIAL_OVERLAY_SCRIPT: Script = preload("res://scripts/ui/tutorial_overlay.gd")

const BLACK_BUTTON_THEME: Theme = preload("res://themes/black_button_theme.tres")
const MENU_FONT: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")

const BACKGROUND_SWAY_SPEED: float = 0.52
const BACKGROUND_SWAY_AMP_RAD: float = deg_to_rad(5.2)
const BACKGROUND_SWAY_SPRING: float = 13.5
const BACKGROUND_SWAY_DAMPING: float = 9.2
const BACKGROUND_SWAY_OVERSCALE: float = 1.14

@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var background: TextureRect = $Background
@onready var _version_label: Label = $VersionCorner/VersionRow/VersionLabel
@onready var _check_update_button: Button = $VersionCorner/VersionRow/CheckUpdateButton
@onready var _update_http: HTTPRequest = $UpdateCheckHTTP
@onready var _update_overlay: Control = $UpdateResultOverlay
@onready var _update_title: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/TitleLabel
@onready var _update_error_message: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/ErrorMessageLabel
@onready var _update_body_split: HBoxContainer = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit
@onready var _update_current: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/CurrentVersionLabel
@onready var _update_latest: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/LatestVersionLabel
@onready var _update_outdated: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/OutdatedWarningLabel
@onready var _update_download_link: LinkButton = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/DownloadLink
@onready var _update_changelog: RichTextLabel = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/RightColumn/ChangelogScroll/ChangelogRichText
@onready var _update_ok: Button = $UpdateResultOverlay/Center/ResultCard/CardColumn/OkButton

var _version_update: VersionUpdateCheck = VersionUpdateCheck.new()
var background_sway_phase: float = 0.0
var background_sway_angle: float = 0.0
var background_sway_angular_vel: float = 0.0
var _control_mode_overlay: Control = null


func _ready() -> void:
	var entrance_fade_in_from_first_screen: bool = RunState.consume_pending_main_menu_entrance_fade_in()
	var entrance_cover: ColorRect = null
	if entrance_fade_in_from_first_screen:
		entrance_cover = _make_entrance_fade_cover()
		add_child(entrance_cover)
	GameMusic.ensure_playing_main_volume()
	_version_update.setup(
		_version_label,
		_check_update_button,
		_update_http,
		_update_overlay,
		_update_title,
		_update_error_message,
		_update_body_split,
		_update_current,
		_update_latest,
		_update_outdated,
		_update_download_link,
		_update_changelog
	)
	_version_update.wire()
	_version_update.wire_ok_button(_update_ok)
	_version_update.apply_version_label()
	var continue_btn: Button = get_node("%s/ContinueButton" % MENU_BUTTON_CONTAINER_PATH) as Button
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh_continue_button()
	get_node("%s/StartButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_start_pressed)
	get_node("%s/CustomizeButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_character_pressed)
	get_node("%s/SettingsButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_settings_pressed)
	get_node("%s/AboutButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_credits_pressed)
	get_node("%s/QuitButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_quit_pressed)
	background.resized.connect(_update_background_sway_pivot)
	await get_tree().process_frame
	_update_background_sway_pivot()
	background.scale = Vector2(BACKGROUND_SWAY_OVERSCALE, BACKGROUND_SWAY_OVERSCALE)
	if entrance_cover != null:
		await _play_entrance_fade_in(entrance_cover)
	# 开始教程（主菜单欢迎层）
	# if not SaveManager.get_tutorial_completed() and not SaveManager.has_pending_run():
	# 	TutorialSession.begin_from_main_menu()
	# 	TUTORIAL_OVERLAY_SCRIPT.call("try_attach", self)
	# 仅在主菜单询问键鼠/虚拟按键（首屏渐入结束后再弹；未勾选「不再提示」则每次进主菜单都会问）
	if not GameSettings.control_mode_launch_prompt_dismissed:
		_show_control_mode_dialog()


func _make_entrance_fade_cover() -> ColorRect:
	var cover: ColorRect = ColorRect.new()
	cover.name = "EntranceFadeCover"
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.color = MenuEntrance.COVER_COLOR
	cover.modulate = Color(1, 1, 1, 1)
	cover.z_index = 120
	return cover


func _play_entrance_fade_in(cover: ColorRect) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(cover, "modulate:a", 0.0, MenuEntrance.ENTRANCE_REVEAL_SEC).set_trans(
		Tween.TRANS_QUART
	).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(cover):
		cover.queue_free()


func _show_control_mode_dialog() -> void:
	if _control_mode_overlay != null and is_instance_valid(_control_mode_overlay):
		return
	var root: Control = Control.new()
	root.name = "ControlModeOverlay"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 25
	add_child(root)
	_control_mode_overlay = root
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 0)
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.08, 0.07, 0.1, 0.96)
	card_sb.set_border_width_all(1)
	card_sb.border_color = Color(1, 1, 1, 0.38)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 22.0
	card_sb.content_margin_top = 20.0
	card_sb.content_margin_right = 22.0
	card_sb.content_margin_bottom = 22.0
	card.add_theme_stylebox_override("panel", card_sb)
	center.add_child(card)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)
	var title_l: Label = Label.new()
	title_l.text = "选择操作方式"
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.add_theme_font_override("font", MENU_FONT)
	title_l.add_theme_font_size_override("font_size", 28)
	title_l.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	vbox.add_child(title_l)
	var hint: Label = Label.new()
	hint.text = "请选择键鼠或虚拟按键。\n触控设备建议使用虚拟按键。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", MENU_FONT)
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)
	var joystick_btn: Button = Button.new()
	joystick_btn.text = "虚拟按键"
	joystick_btn.theme = BLACK_BUTTON_THEME
	joystick_btn.custom_minimum_size = Vector2(168, 52)
	joystick_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(joystick_btn)
	var keyboard_btn: Button = Button.new()
	keyboard_btn.text = "键盘鼠标"
	keyboard_btn.theme = BLACK_BUTTON_THEME
	keyboard_btn.custom_minimum_size = Vector2(168, 52)
	keyboard_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(keyboard_btn)
	var no_remind_check: CheckBox = CheckBox.new()
	no_remind_check.theme = BLACK_BUTTON_THEME
	no_remind_check.text = "不再提示"
	no_remind_check.add_theme_font_size_override("font_size", 18)
	vbox.add_child(no_remind_check)
	joystick_btn.pressed.connect(_on_control_mode_joystick.bind(no_remind_check))
	keyboard_btn.pressed.connect(_on_control_mode_keyboard.bind(no_remind_check))


func _on_control_mode_joystick(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(true)
	if no_remind_check.button_pressed:
		GameSettings.set_control_mode_launch_prompt_dismissed(true)
	_close_control_mode_dialog()


func _on_control_mode_keyboard(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(false)
	if no_remind_check.button_pressed:
		GameSettings.set_control_mode_launch_prompt_dismissed(true)
	_close_control_mode_dialog()


func _close_control_mode_dialog() -> void:
	if is_instance_valid(_control_mode_overlay):
		_control_mode_overlay.queue_free()
		_control_mode_overlay = null


func _update_background_sway_pivot() -> void:
	background.pivot_offset = background.size * 0.5


func _process(delta: float) -> void:
	background_sway_phase += delta * BACKGROUND_SWAY_SPEED
	var target_angle: float = sin(background_sway_phase) * BACKGROUND_SWAY_AMP_RAD
	var angular_accel: float = (
		BACKGROUND_SWAY_SPRING * (target_angle - background_sway_angle)
		- BACKGROUND_SWAY_DAMPING * background_sway_angular_vel
	)
	background_sway_angular_vel += angular_accel * delta
	background_sway_angle += background_sway_angular_vel * delta
	background.rotation = background_sway_angle


func _refresh_continue_button() -> void:
	var continue_btn: Button = get_node("%s/ContinueButton" % MENU_BUTTON_CONTAINER_PATH) as Button
	var has_save: bool = SaveManager.has_pending_run()
	continue_btn.disabled = not has_save
	if has_save:
		var summary: Dictionary = SaveManager.get_pending_run_summary()
		var wave: int = int(summary.get("wave_index", 0))
		continue_btn.text = "继续游戏-第%d波" % wave
		return
	continue_btn.text = "继续游戏-第0波"


func _on_continue_pressed() -> void:
	var last: String = SaveManager.get_last_played_slot_id()
	if SaveManager.slot_has_resumable_run(last):
		SaveManager.active_save_slot_id = last
	else:
		var fid: String = SaveManager.find_first_slot_with_run()
		if not fid.is_empty():
			SaveManager.active_save_slot_id = fid
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_start_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/game_start.tscn")


func _on_character_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.gallery_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_settings_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_credits_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/about.tscn")

func _show_info_dialog(message: String) -> void:
	info_dialog.dialog_text = message
	info_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
