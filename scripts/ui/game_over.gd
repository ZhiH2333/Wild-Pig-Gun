extends Control

## 游戏结束界面脚本
## 需求：6.1、6.2、6.3

@onready var waves_label: Label = $WavesLabel
@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, false)
	waves_label.text = "存活波次：%d 波" % RunState.wave_index
	restart_button.pressed.connect(_on_restart_pressed)


func _on_restart_pressed() -> void:
	RunState.begin_new_run("default")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
