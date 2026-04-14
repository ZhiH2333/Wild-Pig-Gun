extends Control

@onready var summary_label: Label = $RootMargin/RootVBox/SummaryLabel
@onready var detail_rich: RichTextLabel = $RootMargin/RootVBox/ScrollArea/DetailRich
@onready var main_menu_btn: Button = $RootMargin/RootVBox/BottomBar/MainMenuButton
@onready var copy_button: Button = $RootMargin/RootVBox/BottomBar/CopyButton


func _ready() -> void:
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, true)
	summary_label.text = _build_header_line()
	detail_rich.text = RunEndSummaryText.build_bbcode_section()
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	copy_button.pressed.connect(_on_copy_pressed)


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


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(RunEndSummaryText.build_full_detail_section())
	copy_button.text = "✓ 已复制"
	await get_tree().create_timer(2.0).timeout
	copy_button.text = "复制报告"
