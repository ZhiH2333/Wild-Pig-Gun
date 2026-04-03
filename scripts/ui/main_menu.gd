extends Control

@onready var placeholder_dialog: AcceptDialog = $PlaceholderDialog

func _ready() -> void:
	$ButtonColumn/StartButton.pressed.connect(_on_start_pressed)
	$ButtonColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonColumn/ProgressButton.pressed.connect(_on_progress_pressed)
	$ButtonColumn/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	RunState.begin_new_run("default")
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")

func _on_settings_pressed() -> void:
	_show_placeholder("设置功能将在后续版本提供。")

func _on_progress_pressed() -> void:
	_show_placeholder("进度与解锁将在后续版本提供。")

func _on_credits_pressed() -> void:
	_show_placeholder("制作人名单（占位）\nWildPigGun")

func _show_placeholder(message: String) -> void:
	placeholder_dialog.dialog_text = message
	placeholder_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
