extends Control

@onready var summary_label: Label = $Center/MainColumn/HeaderMargins/TitleBlock/SummaryLabel
@onready var detail_rich: RichTextLabel = $Center/MainColumn/MainCard/Margins/ScrollArea/DetailRich
@onready var main_menu_btn: Button = $Center/MainColumn/BottomBar/MainMenuButton
@onready var copy_button: Button = $Center/MainColumn/BottomBar/CopyButton


func _ready() -> void:
	if not SaveManager.active_save_slot_id.is_empty():
		SaveManager.add_play_time_to_slot(
			SaveManager.active_save_slot_id, RunState.consume_session_play_for_save())
	SaveManager.clear_pending_run()
	SaveManager.record_run_finished(RunState.wave_index, true)
	summary_label.text = _build_header_line()
	detail_rich.text = RunEndSummaryText.build_bbcode_section()
	RunState.bank_run_material_to_wallet()
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	copy_button.pressed.connect(_on_copy_pressed)


func _build_header_line() -> String:
	var elapsed: float = RunState.get_run_elapsed_seconds()
	return "完成波次：%d  ·  当前野猪币：%d  ·  本局时长：%s" % [
		RunState.wave_index,
		RunState.material_current,
		SaveDisplay.format_hms(int(roundf(elapsed))),
	]


func _on_main_menu_pressed() -> void:
	RunState.begin_new_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(RunEndSummaryText.build_full_detail_section())
	copy_button.text = "✓ 已复制"
	await get_tree().create_timer(2.0).timeout
	copy_button.text = "复制报告"
