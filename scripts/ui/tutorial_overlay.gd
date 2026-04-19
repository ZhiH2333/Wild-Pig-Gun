extends CanvasLayer

const LAYOUT_EDITOR_SCENE: PackedScene = preload("res://scenes/ui/mobile_control_layout_editor.tscn")

@onready var _dim: ColorRect = $Dim
@onready var _welcome: Control = $WelcomeRoot
@onready var _input_select: Control = $InputSelectRoot
@onready var _logo: TextureRect = $WelcomeRoot/Center/Inner/Logo
@onready var _welcome_body: RichTextLabel = $WelcomeRoot/Center/Inner/WelcomeBody
@onready var _start_tutorial_btn: Button = $WelcomeRoot/Center/Inner/StartTutorialBtn
@onready var _skip_link: Button = $WelcomeRoot/Center/Inner/SkipLink
@onready var _touch_btn: Button = $InputSelectRoot/Center/VBox/Row/TouchBtn
@onready var _keyboard_btn: Button = $InputSelectRoot/Center/VBox/Row/KeyboardBtn

var _main_menu: Control = null


static func try_attach(main_menu: Control) -> Node:
	if SaveManager.get_tutorial_completed():
		return null
	if not TutorialSession.active:
		return null
	var scene: PackedScene = load("res://scenes/tutorial_overlay.tscn") as PackedScene
	var inst: CanvasLayer = scene.instantiate() as CanvasLayer
	main_menu.add_child(inst)
	if inst.has_method("attach_to_menu"):
		inst.attach_to_menu(main_menu)
	return inst


func attach_to_menu(menu: Control) -> void:
	_main_menu = menu
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if TutorialSession.current_step == TutorialSession.TutorialStep.INPUT_SELECT:
		_show_input_select()
	else:
		_show_welcome()


func _ready() -> void:
	if _logo and ResourceLoader.exists("res://assets/sprites/icon.png"):
		_logo.texture = load("res://assets/sprites/icon.png") as Texture2D
	if _welcome_body:
		_welcome_body.bbcode_enabled = true
		_welcome_body.text = (
			"[center]欢迎来到《野猪枪》！\n"
			+ "你将扮演一只武装到牙齿的野猪，在不断涌来的怪物浪潮中生存下去。\n"
			+ "收集材料、升级构筑、击败 Boss，看看你能坚持到第几波！[/center]"
		)
	if _start_tutorial_btn:
		_start_tutorial_btn.pressed.connect(_on_start_tutorial)
	if _skip_link:
		_skip_link.flat = true
		_skip_link.pressed.connect(_on_skip_tutorial)
	if _touch_btn:
		_touch_btn.pressed.connect(_on_touch_chosen)
	if _keyboard_btn:
		_keyboard_btn.pressed.connect(_on_keyboard_chosen)


func _show_welcome() -> void:
	TutorialSession.set_step(TutorialSession.TutorialStep.WELCOME)
	_welcome.visible = true
	_input_select.visible = false


func _show_input_select() -> void:
	TutorialSession.set_step(TutorialSession.TutorialStep.INPUT_SELECT)
	_welcome.visible = false
	_input_select.visible = true


func _on_start_tutorial() -> void:
	TutorialSession.is_in_tutorial_settings = true
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_skip_tutorial() -> void:
	SaveManager.set_tutorial_completed(true)
	TutorialSession.mark_done()
	queue_free()


func _on_touch_chosen() -> void:
	GameSettings.set_input_mode(GameSettings.InputMode.TOUCH)
	GameSettings.set_has_selected_control_mode(true)
	var editor: Control = LAYOUT_EDITOR_SCENE.instantiate() as Control
	if editor.get("embedded_in_tutorial") != null:
		editor.embedded_in_tutorial = true
	add_child(editor)
	if editor.has_signal("layout_configured"):
		editor.layout_configured.connect(_on_layout_configured.bind(editor))
	_input_select.visible = false


func _on_layout_configured(editor: Node) -> void:
	if is_instance_valid(editor):
		editor.queue_free()
	_go_char_select()


func _on_keyboard_chosen() -> void:
	GameSettings.set_input_mode(GameSettings.InputMode.KEYBOARD_MOUSE)
	GameSettings.set_has_selected_control_mode(true)
	_go_char_select()


func _go_char_select() -> void:
	TutorialSession.set_step(TutorialSession.TutorialStep.CHAR_SELECT)
	queue_free()
	get_tree().change_scene_to_file("res://scenes/pre_start.tscn")
