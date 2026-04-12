extends Control

const BACKGROUND_SWAY_SPEED: float = 0.52
const BACKGROUND_SWAY_AMP_RAD: float = deg_to_rad(5.2)
const BACKGROUND_SWAY_SPRING: float = 13.5
const BACKGROUND_SWAY_DAMPING: float = 9.2
const BACKGROUND_SWAY_OVERSCALE: float = 1.14

@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var background: TextureRect = $Background

var background_sway_phase: float = 0.0
var background_sway_angle: float = 0.0
var background_sway_angular_vel: float = 0.0


func _ready() -> void:
	GameMusic.ensure_playing_main_volume()
	var continue_btn: Button = $ButtonColumn/ContinueButton
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh_continue_button()
	$ButtonColumn/StartButton.pressed.connect(_on_start_pressed)
	$ButtonColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonColumn/ProgressButton.pressed.connect(_on_progress_pressed)
	$ButtonColumn/CreditsButton.pressed.connect(_on_credits_pressed)
	$ButtonColumn/QuitButton.pressed.connect(_on_quit_pressed)
	background.resized.connect(_update_background_sway_pivot)
	await get_tree().process_frame
	_update_background_sway_pivot()
	background.scale = Vector2(BACKGROUND_SWAY_OVERSCALE, BACKGROUND_SWAY_OVERSCALE)


func _update_background_sway_pivot() -> void:
	background.pivot_offset = background.size * 0.5


func _process(delta: float) -> void:
	background_sway_phase += delta * BACKGROUND_SWAY_SPEED
	var target_angle: float = sin(background_sway_phase) * BACKGROUND_SWAY_AMP_RAD
	var angular_accel: float = (
		BACKGROUND_SWAY_SPRING * (target_angle - background_sway_angle)
		- BACKGROUND_SWAY_DAMPING * background_sway_angular_vel
	)
	background_sway_angular_vel += angular_accel * delta
	background_sway_angle += background_sway_angular_vel * delta
	background.rotation = background_sway_angle


func _refresh_continue_button() -> void:
	var continue_btn: Button = $ButtonColumn/ContinueButton
	var has_save: bool = SaveManager.has_pending_run()
	continue_btn.visible = has_save
	if not has_save:
		return
	var summary: Dictionary = SaveManager.get_pending_run_summary()
	var wave: int = int(summary.get("wave_index", 0))
	continue_btn.text = "继续游戏 · 第 %d 波" % wave


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_start_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")


func _on_settings_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_progress_pressed() -> void:
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best: int = int(meta.get("best_wave", 0))
	var runs: int = int(meta.get("runs", 0))
	var wins: int = int(meta.get("victories", 0))
	_show_info_dialog("最高到达波次：%d\n累计局数：%d\n通关次数：%d" % [best, runs, wins])

func _on_credits_pressed() -> void:
	_show_info_dialog("@ZhiH2333\n感谢游玩! \n特别鸣谢：诺诺@解放战争论证者")

func _show_info_dialog(message: String) -> void:
	info_dialog.dialog_text = message
	info_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
