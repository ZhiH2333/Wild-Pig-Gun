extends Control

const BACKGROUND_SWAY_SPEED: float = 0.52
const BACKGROUND_SWAY_AMP_RAD: float = deg_to_rad(5.2)
const BACKGROUND_SWAY_SPRING: float = 13.5
const BACKGROUND_SWAY_DAMPING: float = 9.2
const BACKGROUND_SWAY_OVERSCALE: float = 1.14

@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var background: TextureRect = $Background
@onready var char_name_label: Label = $CharPanel/CharNameLabel
@onready var char_sprite: TextureRect = $CharPanel/CharSprite

var background_sway_phase: float = 0.0
var background_sway_angle: float = 0.0
var background_sway_angular_vel: float = 0.0
var _control_mode_dialog: Window = null


func _ready() -> void:
	GameMusic.ensure_playing_main_volume()
	var continue_btn: Button = $LeftButtons/ContinueButton
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh_continue_button()
	$LeftButtons/StartButton.pressed.connect(_on_start_pressed)
	$LeftButtons/ProgressButton.pressed.connect(_on_progress_pressed)
	$LeftButtons/CharacterButton.pressed.connect(_on_character_pressed)
	$RightButtons/SettingsButton.pressed.connect(_on_settings_pressed)
	$RightButtons/CreditsButton.pressed.connect(_on_credits_pressed)
	$RightButtons/QuitButton.pressed.connect(_on_quit_pressed)
	_refresh_char_panel()
	background.resized.connect(_update_background_sway_pivot)
	await get_tree().process_frame
	_update_background_sway_pivot()
	background.scale = Vector2(BACKGROUND_SWAY_OVERSCALE, BACKGROUND_SWAY_OVERSCALE)
	if not GameSettings.has_selected_control_mode:
		_show_control_mode_dialog()


func _show_control_mode_dialog() -> void:
	_control_mode_dialog = Window.new()
	_control_mode_dialog.title = "选择游玩方式"
	_control_mode_dialog.min_size = Vector2i(460, 320)
	_control_mode_dialog.unresizable = true
	_control_mode_dialog.exclusive = true
	_control_mode_dialog.transient = true
	add_child(_control_mode_dialog)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	_control_mode_dialog.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var hint: Label = Label.new()
	hint.text = "请选择您的游玩方式：\n触控设备请选择「虚拟摇杆」\n桌面设备请选择「键盘鼠标」"
	hint.add_theme_font_size_override("font_size", 20)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)
	var joystick_btn: Button = Button.new()
	joystick_btn.text = "虚拟摇杆"
	joystick_btn.custom_minimum_size = Vector2(160, 52)
	joystick_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(joystick_btn)
	var keyboard_btn: Button = Button.new()
	keyboard_btn.text = "键盘鼠标"
	keyboard_btn.custom_minimum_size = Vector2(160, 52)
	keyboard_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(keyboard_btn)
	var no_remind_check: CheckBox = CheckBox.new()
	no_remind_check.text = "不再提示"
	no_remind_check.add_theme_font_size_override("font_size", 18)
	vbox.add_child(no_remind_check)
	joystick_btn.pressed.connect(_on_control_mode_joystick.bind(no_remind_check))
	keyboard_btn.pressed.connect(_on_control_mode_keyboard.bind(no_remind_check))
	_control_mode_dialog.close_requested.connect(_on_control_mode_dialog_closed.bind(no_remind_check))
	_control_mode_dialog.popup_centered()


func _on_control_mode_joystick(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(true)
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _on_control_mode_keyboard(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(false)
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _on_control_mode_dialog_closed(no_remind_check: CheckBox) -> void:
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _close_control_mode_dialog() -> void:
	if is_instance_valid(_control_mode_dialog):
		_control_mode_dialog.queue_free()
		_control_mode_dialog = null


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
	var continue_btn: Button = $LeftButtons/ContinueButton
	var has_save: bool = SaveManager.has_pending_run()
	continue_btn.visible = has_save
	if not has_save:
		return
	var summary: Dictionary = SaveManager.get_pending_run_summary()
	var wave: int = int(summary.get("wave_index", 0))
	continue_btn.text = "继续游戏 · 第 %d 波" % wave


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_start_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")


func _on_character_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_settings_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_progress_pressed() -> void:
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best: int = int(meta.get("best_wave", 0))
	var runs: int = int(meta.get("runs", 0))
	var wins: int = int(meta.get("victories", 0))
	_show_info_dialog("最高到达波次：%d\n累计局数：%d\n通关次数：%d" % [best, runs, wins])

func _on_credits_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/about.tscn")

func _show_info_dialog(message: String) -> void:
	info_dialog.dialog_text = message
	info_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()


func _refresh_char_panel() -> void:
	var character_id: String = str(GameSettings.selected_character_id)
	var character: Dictionary = CharacterData.find_character(character_id)
	var display_name: String = str(character.get("display_name", "标准野猪"))
	var sprite_path: String = str(character.get("sprite_path", "res://assets/sprites/wildpig.png"))
	char_name_label.text = "当前角色：%s" % display_name
	if not ResourceLoader.exists(sprite_path):
		char_sprite.texture = null
		return
	var texture: Texture2D = load(sprite_path) as Texture2D
	char_sprite.texture = texture
