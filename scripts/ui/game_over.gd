extends Control

## 游戏结束界面脚本

@onready var waves_label: Label = $RootMargin/RootVBox/WavesLabel
@onready var detail_rich: RichTextLabel = $RootMargin/RootVBox/ScrollArea/DetailRich
@onready var restart_button: Button = $RootMargin/RootVBox/BottomBar/RestartButton
@onready var copy_button: Button = $RootMargin/RootVBox/BottomBar/CopyButton


func _ready() -> void:
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, false)
	waves_label.text = "存活波次：%d 波" % RunState.wave_index
	detail_rich.text = RunEndSummaryText.build_bbcode_section()
	restart_button.pressed.connect(_on_restart_pressed)
	copy_button.pressed.connect(_on_copy_pressed)


func _on_restart_pressed() -> void:
	RunState.begin_new_run("default")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(RunEndSummaryText.build_full_detail_section())
	copy_button.text = "✓ 已复制"
	await get_tree().create_timer(2.0).timeout
	copy_button.text = "复制报告"
