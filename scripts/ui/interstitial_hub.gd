extends CanvasLayer

## 波间界面：暂停游戏树直至玩家点击继续
signal continue_pressed

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/TitleLabel
@onready var continue_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ContinueButton


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)


func show_for_finished_wave(finished_wave_index: int) -> void:
	title_label.text = "第 %d 波结束" % finished_wave_index
	visible = true
	RunState.enter_interstitial_pause()


func _on_continue_pressed() -> void:
	visible = false
	RunState.leave_interstitial_pause()
	continue_pressed.emit()
