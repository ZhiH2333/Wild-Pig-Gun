extends Control

## 游戏结束界面脚本

@onready var waves_label: Label = $RootMargin/RootVBox/WavesLabel
@onready var detail_rich: RichTextLabel = $RootMargin/RootVBox/ScrollArea/DetailRich
@onready var restart_button: Button = $RootMargin/RootVBox/BottomBar/RestartButton
@onready var copy_button: Button = $RootMargin/RootVBox/BottomBar/CopyButton


func _ready() -> void:
	if not SaveManager.active_save_slot_id.is_empty():
		SaveManager.add_play_time_to_slot(
			SaveManager.active_save_slot_id, RunState.consume_session_play_for_save())
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, false)
	waves_label.text = "存活波次：%d 波" % RunState.wave_index
	detail_rich.text = RunEndSummaryText.build_bbcode_section()
	RunState.bank_run_material_to_wallet()
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
