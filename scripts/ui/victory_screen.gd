extends Control

@onready var summary_label: Label = $RootVBox/SummaryLabel
@onready var detail_text: TextEdit = $RootVBox/DetailText
@onready var main_menu_btn: Button = $RootVBox/MainMenuButton


func _ready() -> void:
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, true)
	summary_label.text = _build_header_line()
	detail_text.text = RunEndSummaryText.build_full_detail_section()
	main_menu_btn.pressed.connect(_on_main_menu_pressed)


func _build_header_line() -> String:
	var elapsed: float = RunState.get_run_elapsed_seconds()
	return "完成波次：%d  ·  当前材料：%d  ·  用时：%.0f 秒" % [
		RunState.wave_index,
		RunState.material_current,
		elapsed,
	]


func _on_main_menu_pressed() -> void:
	RunState.begin_new_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
