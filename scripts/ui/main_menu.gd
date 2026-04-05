extends Control

@onready var placeholder_dialog: AcceptDialog = $PlaceholderDialog
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	var stream: AudioStream = music_player.stream
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	music_player.play()
	var continue_btn: Button = $ButtonColumn/ContinueButton
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh_continue_button()
	$ButtonColumn/StartButton.pressed.connect(_on_start_pressed)
	$ButtonColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonColumn/ProgressButton.pressed.connect(_on_progress_pressed)
	$ButtonColumn/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)


func _refresh_continue_button() -> void:
	var continue_btn: Button = $ButtonColumn/ContinueButton
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
