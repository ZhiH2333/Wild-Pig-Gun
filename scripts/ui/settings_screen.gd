extends Control

@onready var master_slider: HSlider = $Center/VBox/MasterRow/MasterSlider
@onready var fullscreen_check: CheckBox = $Center/VBox/FullscreenCheck
@onready var back_button: Button = $Center/VBox/BackButton


func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value = GameSettings.master_linear
	fullscreen_check.button_pressed = GameSettings.fullscreen
	if OS.get_name() == "Web":
		fullscreen_check.visible = false


func _on_master_changed(v: float) -> void:
	GameSettings.set_master_linear(v)


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_fullscreen(pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
