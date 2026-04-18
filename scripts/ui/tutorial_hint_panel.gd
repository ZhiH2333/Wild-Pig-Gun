extends CanvasLayer

@onready var _panel: PanelContainer = $Root/Panel
@onready var _main_label: RichTextLabel = $Root/Panel/Margin/VBox/MainLabel
@onready var _progress_label: Label = $Root/Panel/Margin/VBox/ProgressLabel

var _wave_manager: WaveManager = null
var _full_text: String = "等待倒计时归零，存活撑过第一波！"
var _typed_chars: int = 0
var _type_timer: float = 0.0
var _wave_duration: float = 30.0


func _ready() -> void:
	if _panel:
		var st: StyleBoxFlat = StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.1, 0.14, 0.88)
		st.set_corner_radius_all(14)
		st.set_border_width_all(1)
		st.border_color = Color(0.4, 0.48, 0.62, 0.85)
		_panel.add_theme_stylebox_override("panel", st)


func setup(wm: WaveManager) -> void:
	_wave_manager = wm
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _panel:
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if TutorialSession.active:
		TutorialSession.advance_after_run_started()
	if not wm.wave_started.is_connected(_on_wave_started):
		wm.wave_started.connect(_on_wave_started)
	if not wm.wave_ended.is_connected(_on_wave_ended):
		wm.wave_ended.connect(_on_wave_ended)
	if not wm.wave_timer_tick.is_connected(_on_wave_timer_tick):
		wm.wave_timer_tick.connect(_on_wave_timer_tick)
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)


func _on_wave_started(wave_index: int, duration_sec: float) -> void:
	_wave_duration = duration_sec
	if wave_index == 1:
		_typed_chars = 0
		_type_timer = 0.0
		_refresh_typewriter(0)


func _on_wave_timer_tick(remaining: float) -> void:
	if _wave_manager == null or _wave_manager.current_wave != 1:
		return
	_progress_label.text = "第 1 波 / 持续 %.0f 秒（剩余 %.1f 秒）" % [_wave_duration, remaining]


func _on_wave_ended(wave_index: int) -> void:
	if wave_index != 1:
		return
	if is_instance_valid(_wave_manager):
		if _wave_manager.wave_started.is_connected(_on_wave_started):
			_wave_manager.wave_started.disconnect(_on_wave_started)
		if _wave_manager.wave_ended.is_connected(_on_wave_ended):
			_wave_manager.wave_ended.disconnect(_on_wave_ended)
		if _wave_manager.wave_timer_tick.is_connected(_on_wave_timer_tick):
			_wave_manager.wave_timer_tick.disconnect(_on_wave_timer_tick)
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.finished.connect(queue_free)


func _process(delta: float) -> void:
	if _wave_manager == null or _wave_manager.current_wave != 1:
		return
	_type_timer += delta
	if _typed_chars >= _full_text.length():
		return
	if _type_timer >= 0.045:
		_type_timer = 0.0
		_typed_chars = mini(_typed_chars + 1, _full_text.length())
		_refresh_typewriter(_typed_chars)


func _refresh_typewriter(until: int) -> void:
	_main_label.text = _full_text.substr(0, until)
