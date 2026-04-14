extends CanvasLayer

@onready var resume_button: Button = $CenterContainer/Panel/Margin/PauseVBox/ResumeButton
@onready var settings_button: Button = $CenterContainer/Panel/Margin/PauseVBox/SettingsButton
@onready var save_menu_button: Button = $CenterContainer/Panel/Margin/PauseVBox/SaveMenuButton
@onready var quit_no_save_button: Button = $CenterContainer/Panel/Margin/PauseVBox/QuitNoSaveButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	save_menu_button.pressed.connect(_on_save_menu_pressed)
	quit_no_save_button.pressed.connect(_on_quit_no_save_pressed)


func _on_resume_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("_on_pause_resume_pressed"):
		arena._on_pause_resume_pressed()


func _on_save_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("save_run_and_return_to_menu"):
		arena.save_run_and_return_to_menu()


func _on_settings_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("open_in_game_settings"):
		arena.open_in_game_settings()


func _on_quit_no_save_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("quit_to_menu_without_saving"):
		arena.quit_to_menu_without_saving()
