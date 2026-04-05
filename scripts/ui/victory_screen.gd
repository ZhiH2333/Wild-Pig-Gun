extends Control


func _ready() -> void:
	SaveManager.record_run_finished(RunState.wave_index, true)
	var stats: Label = $VBox/StatsLabel
	var main_menu_btn: Button = $VBox/MainMenuButton
	stats.text = _build_stats_text()
	main_menu_btn.pressed.connect(_on_main_menu_pressed)


func _build_stats_text() -> String:
	var elapsed: float = RunState.get_run_elapsed_seconds()
	return "通关！\n完成波次：%d\n当前材料：%d\n本局用时：%.0f 秒" % [
		RunState.wave_index,
		RunState.material_current,
		elapsed,
	]


func _on_main_menu_pressed() -> void:
	RunState.begin_new_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
