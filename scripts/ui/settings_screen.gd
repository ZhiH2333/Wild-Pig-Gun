extends Control

@onready var master_slider: HSlider = $Center/MainColumn/Scroll/Contents/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/MainColumn/Scroll/Contents/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/MainColumn/Scroll/Contents/SfxRow/SfxSlider
@onready var ui_scale_slider: HSlider = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleSlider
@onready var ui_scale_value: Label = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleValue
@onready var fullscreen_check: CheckBox = $Center/MainColumn/Scroll/Contents/FullscreenCheck
@onready var vsync_check: CheckBox = $Center/MainColumn/Scroll/Contents/VsyncCheck
@onready var back_button: Button = $Center/MainColumn/BackButton


func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value = GameSettings.master_linear
	music_slider.value = GameSettings.music_linear
	sfx_slider.value = GameSettings.sfx_linear
	ui_scale_slider.value = GameSettings.ui_scale
	fullscreen_check.button_pressed = GameSettings.fullscreen
	vsync_check.button_pressed = GameSettings.vsync_enabled
	_refresh_ui_scale_label()
	if OS.get_name() == "Web":
		fullscreen_check.visible = false
		vsync_check.visible = false


func _on_master_changed(v: float) -> void:
	GameSettings.set_master_linear(v)


func _on_music_changed(v: float) -> void:
	GameSettings.set_music_linear(v)


func _on_sfx_changed(v: float) -> void:
	GameSettings.set_sfx_linear(v)


func _on_ui_scale_changed(v: float) -> void:
	GameSettings.set_ui_scale(v)
	_refresh_ui_scale_label()


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_fullscreen(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)


func _refresh_ui_scale_label() -> void:
	ui_scale_value.text = "%d%%" % int(round(GameSettings.ui_scale * 100.0))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
