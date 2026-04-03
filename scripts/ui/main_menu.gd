extends Control

func _ready() -> void:
	$ButtonColumn/StartButton.pressed.connect(_on_start_pressed)
	$ButtonColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonColumn/ProgressButton.pressed.connect(_on_progress_pressed)
	$ButtonColumn/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	print("开始游戏（尚未连接战斗场景）")

func _on_settings_pressed() -> void:
	print("设置（待实现）")

func _on_progress_pressed() -> void:
	print("进度（待实现）")

func _on_credits_pressed() -> void:
	print("制作人名单（待实现）")

func _on_quit_pressed() -> void:
	get_tree().quit()
