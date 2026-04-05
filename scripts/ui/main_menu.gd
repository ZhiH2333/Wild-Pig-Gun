extends Control

@onready var placeholder_dialog: AcceptDialog = $PlaceholderDialog

func _ready() -> void:
	$ButtonColumn/StartButton.pressed.connect(_on_start_pressed)
	$ButtonColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonColumn/ProgressButton.pressed.connect(_on_progress_pressed)
	$ButtonColumn/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_progress_pressed() -> void:
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best: int = int(meta.get("best_wave", 0))
	var runs: int = int(meta.get("runs", 0))
	var wins: int = int(meta.get("victories", 0))
	_show_placeholder("最高到达波次：%d\n累计局数：%d\n通关次数：%d" % [best, runs, wins])

func _on_credits_pressed() -> void:
	_show_placeholder("制作人名单（占位）\nWildPigGun")

func _show_placeholder(message: String) -> void:
	placeholder_dialog.dialog_text = message
	placeholder_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
