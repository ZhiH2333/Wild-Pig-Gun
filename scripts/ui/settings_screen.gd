extends Control

@onready var master_slider: HSlider = $Center/MainColumn/Scroll/Contents/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/MainColumn/Scroll/Contents/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/MainColumn/Scroll/Contents/SfxRow/SfxSlider
@onready var ui_scale_slider: HSlider = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleSlider
@onready var ui_scale_value: Label = $Center/MainColumn/Scroll/Contents/UiScaleRow/UiScaleValue
@onready var view_scale_slider: HSlider = $Center/MainColumn/Scroll/Contents/ViewScaleRow/ViewScaleSlider
@onready var view_scale_value: Label = $Center/MainColumn/Scroll/Contents/ViewScaleRow/ViewScaleValue
@onready var fullscreen_check: CheckBox = $Center/MainColumn/Scroll/Contents/FullscreenCheck
@onready var vsync_check: CheckBox = $Center/MainColumn/Scroll/Contents/VsyncCheck
@onready var mobile_controls_check: CheckBox = $Center/MainColumn/Scroll/Contents/MobileControlsCheck
@onready var back_button: Button = $Center/MainColumn/BackButton


func _ready() -> void:
	GameMusic.duck_for_subpage()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	view_scale_slider.value_changed.connect(_on_view_scale_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	mobile_controls_check.toggled.connect(_on_mobile_controls_toggled)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value = GameSettings.master_linear
	music_slider.value = GameSettings.music_linear
	sfx_slider.value = GameSettings.sfx_linear
	ui_scale_slider.value = GameSettings.ui_scale
	view_scale_slider.value = GameSettings.view_scale
	fullscreen_check.button_pressed = GameSettings.fullscreen
	vsync_check.button_pressed = GameSettings.vsync_enabled
	mobile_controls_check.button_pressed = GameSettings.mobile_controls_enabled
	_refresh_ui_scale_label()
	_refresh_view_scale_label()
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


func _on_view_scale_changed(v: float) -> void:
	GameSettings.set_view_scale(v)
	_refresh_view_scale_label()


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_fullscreen(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)


func _on_mobile_controls_toggled(pressed: bool) -> void:
	GameSettings.set_mobile_controls_enabled(pressed)


func _refresh_ui_scale_label() -> void:
	ui_scale_value.text = "%d%%" % int(round(GameSettings.ui_scale * 100.0))


func _refresh_view_scale_label() -> void:
	view_scale_value.text = "%d%%" % int(round(GameSettings.view_scale * 100.0))


func _on_back_pressed() -> void:
	if bool(get_meta("in_game_overlay", false)):
		var arena: Node = get_tree().get_first_node_in_group("arena")
		if arena != null and arena.has_method("close_in_game_settings"):
			arena.close_in_game_settings()
		return
	var target_scene: String = RunState.settings_return_scene_path
	if target_scene.is_empty():
		target_scene = "res://scenes/main_menu.tscn"
	if target_scene == "res://scenes/main_menu.tscn":
		GameMusic.ensure_playing_main_volume()
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file(target_scene)
