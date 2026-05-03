extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"

const BACKGROUND_SWAY_SPEED: float = 0.52
const BACKGROUND_SWAY_AMP_RAD: float = deg_to_rad(5.2)
const BACKGROUND_SWAY_SPRING: float = 13.5
const BACKGROUND_SWAY_DAMPING: float = 9.2
const BACKGROUND_SWAY_OVERSCALE: float = 1.14

@onready var background: TextureRect = $Background
@onready var _click_catcher: ColorRect = $ClickCatcher
@onready var _hint_panel: PanelContainer = $CenterContent/VBox/HintPanel
@onready var _loading_box: Control = $CenterContent/VBox/LoadingBox
@onready var _load_status_label: Label = $CenterContent/VBox/LoadingBox/LoadStatusLabel
@onready var _progress_bar: ProgressBar = $CenterContent/VBox/LoadingBox/ProgressBar
@onready var _percent_label: Label = $CenterContent/VBox/LoadingBox/PercentLabel
@onready var _version_label: Label = $VersionCorner/VersionRow/VersionLabel
@onready var _check_update_button: Button = $VersionCorner/VersionRow/CheckUpdateButton
@onready var _update_http: HTTPRequest = $UpdateCheckHTTP
@onready var _update_overlay: Control = $UpdateResultOverlay
@onready var _update_title: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/TitleLabel
@onready var _update_error_message: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/ErrorMessageLabel
@onready var _update_body_split: HBoxContainer = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit
@onready var _update_current: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/CurrentVersionLabel
@onready var _update_latest: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/LatestVersionLabel
@onready var _update_outdated: Label = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/OutdatedWarningLabel
@onready var _update_download_link: LinkButton = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/LeftColumn/DownloadLink
@onready var _update_changelog: RichTextLabel = (
	$UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/RightColumn/ChangelogScroll/ChangelogRichText
)
@onready var _update_ok: Button = $UpdateResultOverlay/Center/ResultCard/CardColumn/OkButton

var _version_update: VersionUpdateCheck = VersionUpdateCheck.new()
var background_sway_phase: float = 0.0
var background_sway_angle: float = 0.0
var background_sway_angular_vel: float = 0.0
var _transitioning: bool = false
var _load_poll_active: bool = false


func _ready() -> void:
	GameMusic.ensure_playing_main_volume()
	_version_update.setup(
		_version_label,
		_check_update_button,
		_update_http,
		_update_overlay,
		_update_title,
		_update_error_message,
		_update_body_split,
		_update_current,
		_update_latest,
		_update_outdated,
		_update_download_link,
		_update_changelog
	)
	_version_update.wire()
	_version_update.wire_ok_button(_update_ok)
	_version_update.apply_version_label()
	_click_catcher.gui_input.connect(_on_click_catcher_gui_input)
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
	if _load_poll_active:
		_poll_main_menu_load()


func _on_click_catcher_gui_input(event: InputEvent) -> void:
	if _update_overlay.visible:
		return
	if _transitioning:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_begin_transition_to_main_menu()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_begin_transition_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _update_overlay.visible:
		return
	if _transitioning:
		return
	if event is InputEventKey:
		var ek: InputEventKey = event as InputEventKey
		if ek.pressed and not ek.echo:
			_begin_transition_to_main_menu()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event as InputEventJoypadButton
		if jb.pressed:
			_begin_transition_to_main_menu()
			get_viewport().set_input_as_handled()


func _begin_transition_to_main_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	_hint_panel.visible = false
	_loading_box.visible = true
	_progress_bar.value = 0.0
	_percent_label.text = "0%"
	_load_status_label.text = "正在加载主界面…"
	var err: Error = ResourceLoader.load_threaded_request(MAIN_MENU_PATH)
	if err != OK:
		_show_load_error("无法开始加载（错误码 %d）" % err)
		return
	_load_poll_active = true


func _poll_main_menu_load() -> void:
	var prog: Array = []
	var st: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH, prog)
	var p: float = 0.0
	if prog.size() > 0:
		p = clampf(float(prog[0]), 0.0, 1.0)
	_progress_bar.value = p * 100.0
	_percent_label.text = "%d%%" % clampi(int(round(p * 100.0)), 0, 100)
	match st:
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_poll_active = false
			var res: Resource = ResourceLoader.load_threaded_get(MAIN_MENU_PATH)
			if res is PackedScene:
				call_deferred("_finish_loaded_switch", res as PackedScene)
			else:
				_show_load_error("主界面资源无效")
		ResourceLoader.THREAD_LOAD_FAILED:
			_load_poll_active = false
			_show_load_error("主界面加载失败")
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_load_poll_active = false
			_show_load_error("主界面路径无效")
		_:
			pass


func _finish_loaded_switch(scene: PackedScene) -> void:
	var cover: ColorRect = ColorRect.new()
	cover.name = "PreSwitchCover"
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.color = MenuEntrance.COVER_COLOR
	cover.modulate = Color(1, 1, 1, 0)
	cover.z_index = 200
	add_child(cover)
	var tw_in: Tween = create_tween()
	tw_in.tween_property(cover, "modulate:a", 1.0, MenuEntrance.PRE_SCENE_SWITCH_SEC).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tw_in.finished
	RunState.pending_main_menu_entrance_fade_in = true
	get_tree().change_scene_to_packed(scene)


func _show_load_error(message: String) -> void:
	_load_poll_active = false
	_transitioning = false
	_hint_panel.visible = true
	_loading_box.visible = false
	_load_status_label.text = "正在加载主界面…"
	_percent_label.text = "0%"
	push_warning("FirstScreen: %s" % message)
