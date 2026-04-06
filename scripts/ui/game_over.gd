extends Control

## 游戏结束界面脚本

@onready var waves_label: Label = $RootVBox/WavesLabel
@onready var detail_text: TextEdit = $RootVBox/DetailText
@onready var restart_button: Button = $RootVBox/RestartButton


func _ready() -> void:
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, false)
	waves_label.text = "存活波次：%d 波" % RunState.wave_index
	detail_text.text = RunEndSummaryText.build_full_detail_section()
	restart_button.pressed.connect(_on_restart_pressed)


func _on_restart_pressed() -> void:
	RunState.begin_new_run("default")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
