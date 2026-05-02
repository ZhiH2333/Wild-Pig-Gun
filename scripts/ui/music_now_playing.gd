extends CanvasLayer

## 右下角圆形「音乐」入口；点击展开控制卡片：曲名、进度、暂停、上/下一首、音乐音量（与设置同步）

const _CARD_W: float = 292.0
const _MARGIN: float = 12.0
const _EDGE_MARGIN: float = 16.0
const _FAB_SIZE: float = 52.0
const _DRAG_START_DISTANCE: float = 6.0

var _tracked: AudioStreamPlayer
var _host: Control
var _bar: VBoxContainer
var _card: PanelContainer
var _toggle_btn: Button
var _panel_open: bool = false
var _prefix_label: Label
var _title_label: Label
var _progress: HSlider
var _time_elapsed: Label
var _time_total: Label
var _btn_prev: Button
var _btn_pause: Button
var _btn_next: Button
var _vol_slider: HSlider
var _vol_label: Label
var _anim_tween: Tween
var _music_sync_block: bool = false
var _has_custom_bar_pos: bool = false
var _header_row: HBoxContainer
var _fullscreen_btn: Button
var _switch_btn: Button
var _source_label: Label
var _webview_mount: Control
var _browser_panel: VBoxContainer
var _float_webview_btn: Button
var _open_in_browser_btn: Button
var _browser_hint_label: Label
var _time_row: HBoxContainer
var _ctrl_row: HBoxContainer
var _vol_row_ref: HBoxContainer

# 拖动状态（对应编辑页 _is_dragging / _drag_offset）
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _suppress_toggle_click: bool = false
var _active_touch_index: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_tracked = GameMusic.get_stream_player()
	GameMusic.track_changed.connect(_on_track_changed_signal)
	GameSettings.music_linear_changed.connect(_on_external_music_volume)
	GameSettings.music_source_changed.connect(_on_music_source_changed)
	ExternalMusicPlayer.external_fullscreen_changed.connect(_on_external_fullscreen_changed)
	_build_ui()
	ExternalMusicPlayer.set_embed_mount(_webview_mount)
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_refit_layout)
	_refit_layout()
	_hide_card_instant()
	if _title_label != null:
		_title_label.text = GameMusic.get_current_title()
	_apply_music_source_visual_state()


func on_track_changed(title: String) -> void:
	if _title_label == null:
		return
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL:
		return
	_title_label.text = title if not title.is_empty() else "—"


func _on_track_changed_signal(title: String) -> void:
	on_track_changed(title)


func _process(_delta: float) -> void:
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL:
		return
	_tracked = GameMusic.get_stream_player()
	if _tracked == null or not is_instance_valid(_tracked):
		return
	if _btn_pause != null:
		_btn_pause.text = "继续" if GameMusic.is_paused() else "暂停"
	if _progress == null:
		return
	if _is_user_scrubbing_progress():
		return
	if not _tracked.playing and not GameMusic.is_paused():
		return
	_update_progress_from_player()


func _build_ui() -> void:
	_host = Control.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)
	var bar: VBoxContainer = VBoxContainer.new()
	_bar = bar
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.clip_contents = true
	bar.add_theme_constant_override("separation", 10)
	bar.alignment = BoxContainer.ALIGNMENT_END
	_host.add_child(bar)
	bar.anchor_left = 0.0
	bar.anchor_top = 0.0
	bar.anchor_right = 0.0
	bar.anchor_bottom = 0.0
	_card = PanelContainer.new()
	_card.visible = false
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps: StyleBoxFlat = StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.08, 0.11, 0.94)
	ps.border_color = Color(0.32, 0.36, 0.48, 1.0)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(10)
	ps.content_margin_left = _MARGIN
	ps.content_margin_top = _MARGIN
	ps.content_margin_right = _MARGIN
	ps.content_margin_bottom = _MARGIN
	_card.add_theme_stylebox_override("panel", ps)
	_card.custom_minimum_size = Vector2(_CARD_W, 0.0)
	bar.add_child(_card)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_card.add_child(v)
	_header_row = HBoxContainer.new()
	_header_row.add_theme_constant_override("separation", 8)
	v.add_child(_header_row)
	_fullscreen_btn = Button.new()
	_fullscreen_btn.text = "全屏"
	_fullscreen_btn.visible = false
	_fullscreen_btn.custom_minimum_size = Vector2(72, 32)
	_fullscreen_btn.pressed.connect(_on_fullscreen_btn_pressed)
	_header_row.add_child(_fullscreen_btn)
	var header_spacer: Control = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_row.add_child(header_spacer)
	_source_label = Label.new()
	_source_label.text = "游戏内置"
	_source_label.add_theme_font_size_override("font_size", 13)
	_source_label.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82, 1.0))
	_source_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_header_row.add_child(_source_label)
	_switch_btn = Button.new()
	_switch_btn.text = "切换"
	_switch_btn.tooltip_text = "切换音乐来源（游戏内部 / 墨韵）"
	_switch_btn.custom_minimum_size = Vector2(64, 32)
	_switch_btn.pressed.connect(_on_switch_music_source_pressed)
	_header_row.add_child(_switch_btn)
	_prefix_label = Label.new()
	_prefix_label.text = "正在播放："
	_prefix_label.add_theme_font_size_override("font_size", 14)
	_prefix_label.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74, 1.0))
	v.add_child(_prefix_label)
	_title_label = Label.new()
	_title_label.text = "—"
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 17)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.88, 1.0))
	v.add_child(_title_label)
	# Web 平台：iframe 挂载容器
	_webview_mount = Control.new()
	_webview_mount.name = "MoinyunWebMount"
	_webview_mount.visible = false
	_webview_mount.custom_minimum_size = Vector2(0.0, 0.0)
	_webview_mount.mouse_filter = Control.MOUSE_FILTER_STOP
	v.add_child(_webview_mount)
	# 非 Web 平台：系统浏览器面板
	_browser_panel = VBoxContainer.new()
	_browser_panel.name = "BrowserPanel"
	_browser_panel.visible = false
	_browser_panel.add_theme_constant_override("separation", 10)
	v.add_child(_browser_panel)
	var ps2: StyleBoxFlat = StyleBoxFlat.new()
	ps2.bg_color = Color(0.10, 0.12, 0.18, 0.85)
	ps2.set_corner_radius_all(8)
	ps2.content_margin_left = 14.0
	ps2.content_margin_top = 14.0
	ps2.content_margin_right = 14.0
	ps2.content_margin_bottom = 14.0
	var bp_wrap: PanelContainer = PanelContainer.new()
	bp_wrap.add_theme_stylebox_override("panel", ps2)
	_browser_panel.add_child(bp_wrap)
	var bp_inner: VBoxContainer = VBoxContainer.new()
	bp_inner.add_theme_constant_override("separation", 10)
	bp_wrap.add_child(bp_inner)
	_browser_hint_label = Label.new()
	_browser_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_browser_hint_label.add_theme_font_size_override("font_size", 13)
	_browser_hint_label.add_theme_color_override("font_color", Color(0.78, 0.72, 0.55, 1.0))
	_browser_hint_label.text = "游戏内音乐已静音，墨韵将在系统浏览器中播放，可与游戏同时运行。"
	bp_inner.add_child(_browser_hint_label)
	_float_webview_btn = Button.new()
	_float_webview_btn.text = "▶  打开墨韵浮窗（游戏内面板）"
	_float_webview_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_float_webview_btn.custom_minimum_size = Vector2(0, 44)
	_float_webview_btn.visible = false
	_float_webview_btn.pressed.connect(_on_float_webview_pressed)
	bp_inner.add_child(_float_webview_btn)
	_open_in_browser_btn = Button.new()
	_open_in_browser_btn.text = "在系统浏览器中打开"
	_open_in_browser_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_open_in_browser_btn.custom_minimum_size = Vector2(0, 44)
	_open_in_browser_btn.pressed.connect(_on_open_in_browser_pressed)
	bp_inner.add_child(_open_in_browser_btn)
	_progress = HSlider.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.step = 0.001
	_progress.custom_minimum_size = Vector2(0.0, 22.0)
	_progress.gui_input.connect(_on_progress_gui_input)
	v.add_child(_progress)
	var time_row: HBoxContainer = HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 8)
	_time_row = time_row
	v.add_child(time_row)
	_time_elapsed = Label.new()
	_time_elapsed.text = "0:00"
	_time_elapsed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_elapsed.add_theme_font_size_override("font_size", 13)
	_time_elapsed.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82, 1.0))
	time_row.add_child(_time_elapsed)
	_time_total = Label.new()
	_time_total.text = "0:00"
	_time_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_total.add_theme_font_size_override("font_size", 13)
	_time_total.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82, 1.0))
	time_row.add_child(_time_total)
	var ctrl: HBoxContainer = HBoxContainer.new()
	ctrl.add_theme_constant_override("separation", 8)
	ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	_ctrl_row = ctrl
	v.add_child(ctrl)
	_btn_prev = Button.new()
	_btn_prev.text = "上一首"
	_btn_prev.custom_minimum_size = Vector2(76, 36)
	_btn_prev.pressed.connect(func() -> void: GameMusic.skip_previous())
	ctrl.add_child(_btn_prev)
	_btn_pause = Button.new()
	_btn_pause.text = "暂停"
	_btn_pause.custom_minimum_size = Vector2(76, 36)
	_btn_pause.pressed.connect(func() -> void: GameMusic.toggle_pause())
	ctrl.add_child(_btn_pause)
	_btn_next = Button.new()
	_btn_next.text = "下一首"
	_btn_next.custom_minimum_size = Vector2(76, 36)
	_btn_next.pressed.connect(func() -> void: GameMusic.skip_next())
	ctrl.add_child(_btn_next)
	var vol_row: HBoxContainer = HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 8)
	_vol_row_ref = vol_row
	v.add_child(vol_row)
	_vol_label = Label.new()
	_vol_label.text = "音乐音量"
	_vol_label.custom_minimum_size = Vector2(72, 0.0)
	_vol_label.add_theme_font_size_override("font_size", 14)
	vol_row.add_child(_vol_label)
	_vol_slider = HSlider.new()
	_vol_slider.min_value = 0.0
	_vol_slider.max_value = 1.0
	_vol_slider.step = 0.05
	_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vol_slider.custom_minimum_size = Vector2(0.0, 24.0)
	_vol_slider.value = GameSettings.music_linear
	_vol_slider.value_changed.connect(_on_vol_slider_changed)
	vol_row.add_child(_vol_slider)
	_toggle_btn = Button.new()
	_toggle_btn.text = "♫"
	_toggle_btn.tooltip_text = "音乐"
	_toggle_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toggle_btn.add_theme_font_size_override("font_size", 26)
	_toggle_btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	_toggle_btn.custom_minimum_size = Vector2(_FAB_SIZE, _FAB_SIZE)
	_toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_fab_styles(_toggle_btn)
	_toggle_btn.gui_input.connect(_on_fab_gui_input)
	_toggle_btn.pressed.connect(_on_toggle_pressed)
	var fab_row: HBoxContainer = HBoxContainer.new()
	fab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fab_row.add_child(_toggle_btn)
	bar.add_child(fab_row)


func _refit_layout() -> void:
	if _bar == null or _card == null:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vw: float = vp.get_visible_rect().size.x
	var vh: float = vp.get_visible_rect().size.y
	var avail: float = maxf(0.0, vw - _EDGE_MARGIN * 2.0)
	var card_w: float = mini(_CARD_W, avail)
	_bar.custom_minimum_size = Vector2(card_w, _FAB_SIZE)
	_card.custom_minimum_size.x = card_w
	_refit_button_row(card_w)
	var bar_size: Vector2 = _bar.get_combined_minimum_size()
	var default_pos: Vector2 = Vector2(vw - _EDGE_MARGIN - bar_size.x, vh - _EDGE_MARGIN - bar_size.y)
	if _has_custom_bar_pos:
		_set_bar_position_clamped(_bar.position, _panel_open)
		return
	_set_bar_position_clamped(default_pos)


func _refit_button_row(card_w: float) -> void:
	if _btn_prev == null or _btn_pause == null or _btn_next == null:
		return
	var inner: float = card_w - 2.0 * _MARGIN
	var gap: float = 8.0
	var btn_w: float = (inner - 2.0 * gap) / 3.0
	btn_w = clampf(btn_w, 40.0, 76.0)
	var h: float = 36.0
	_btn_prev.custom_minimum_size = Vector2(btn_w, h)
	_btn_pause.custom_minimum_size = Vector2(btn_w, h)
	_btn_next.custom_minimum_size = Vector2(btn_w, h)


func _apply_fab_styles(btn: Button) -> void:
	var rad: int = int(floor(_FAB_SIZE * 0.5))
	var n: StyleBoxFlat = StyleBoxFlat.new()
	n.bg_color = Color(0.1, 0.12, 0.18, 0.55)
	n.set_corner_radius_all(rad)
	n.set_border_width_all(1)
	n.border_color = Color(1.0, 1.0, 1.0, 0.28)
	btn.add_theme_stylebox_override("normal", n)
	var h: StyleBoxFlat = StyleBoxFlat.new()
	h.bg_color = Color(0.14, 0.16, 0.22, 0.68)
	h.set_corner_radius_all(rad)
	h.set_border_width_all(1)
	h.border_color = Color(1.0, 1.0, 1.0, 0.42)
	btn.add_theme_stylebox_override("hover", h)
	var p: StyleBoxFlat = StyleBoxFlat.new()
	p.bg_color = Color(0.08, 0.09, 0.14, 0.62)
	p.set_corner_radius_all(rad)
	p.set_border_width_all(1)
	p.border_color = Color(1.0, 1.0, 1.0, 0.36)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _on_toggle_pressed() -> void:
	if _suppress_toggle_click:
		_suppress_toggle_click = false
		return
	_panel_open = not _panel_open
	if _panel_open:
		_show_card_animated()
		_try_activate_external_if_needed()
	else:
		_hide_card_animated()
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL and OS.get_name() == "Web":
		ExternalMusicPlayer.call_deferred("refresh_web_layout")


## 对应编辑页 _gui_input：按下命中 → 记录 drag_offset；移动且拖动中 → _drag_bar；释放 → 结束拖动
func _on_fab_gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var st: InputEventScreenTouch = ev as InputEventScreenTouch
		if st.pressed:
			_active_touch_index = st.index
			_drag_offset = st.position - _bar.position
			_is_dragging = false
		elif st.index == _active_touch_index:
			_active_touch_index = -1
			if _is_dragging:
				_suppress_toggle_click = true
			_is_dragging = false
		return
	if ev is InputEventScreenDrag:
		var sd: InputEventScreenDrag = ev as InputEventScreenDrag
		if sd.index != _active_touch_index:
			return
		_drag_bar(sd.position)
		_position_card()
		return
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_drag_offset = mb.global_position - _bar.position
			_is_dragging = false
		else:
			if _is_dragging:
				_suppress_toggle_click = true
			_is_dragging = false
		return
	if ev is InputEventMouseMotion:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		var mm: InputEventMouseMotion = ev as InputEventMouseMotion
		_drag_bar(mm.global_position)
		_position_card()


## 对应编辑页 _drag_widget：new_pos = global_pos - drag_offset，clampf 限制在容器内
func _drag_bar(global_pos: Vector2) -> void:
	var new_pos: Vector2 = global_pos - _drag_offset
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	var bar_size: Vector2 = _bar.get_combined_minimum_size()
	if _panel_open and _card != null:
		_card.visible = true
		var open_size: Vector2 = _bar.get_combined_minimum_size()
		bar_size.x = maxf(bar_size.x, open_size.x)
		bar_size.y = maxf(bar_size.y, open_size.y)
	new_pos.x = clampf(new_pos.x, _EDGE_MARGIN, vp_size.x - _EDGE_MARGIN - bar_size.x)
	new_pos.y = clampf(new_pos.y, _EDGE_MARGIN, vp_size.y - _EDGE_MARGIN - bar_size.y)
	_bar.position = new_pos
	_has_custom_bar_pos = true
	_is_dragging = true
	_suppress_toggle_click = true


## 对应编辑页 _position_selection_menu：卡片在 _bar 内，随 _bar 移动自动跟随；
## 这里额外确保 _bar 位置满足展开状态下的边界约束（即"菜单自动避开边界"）
func _position_card() -> void:
	if not _panel_open or _bar == null:
		return
	_set_bar_position_clamped(_bar.position, true)


func _set_bar_position_clamped(target: Vector2, constrain_as_open: bool = false) -> void:
	if _bar == null:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	var bar_size: Vector2 = _bar.get_combined_minimum_size()
	if constrain_as_open and _card != null:
		_card.visible = true
		var open_size: Vector2 = _bar.get_combined_minimum_size()
		bar_size.x = maxf(bar_size.x, open_size.x)
		bar_size.y = maxf(bar_size.y, open_size.y)
	var max_x: float = maxf(_EDGE_MARGIN, vp_size.x - _EDGE_MARGIN - bar_size.x)
	var max_y: float = maxf(_EDGE_MARGIN, vp_size.y - _EDGE_MARGIN - bar_size.y)
	_bar.position = Vector2(clampf(target.x, _EDGE_MARGIN, max_x), clampf(target.y, _EDGE_MARGIN, max_y))


func _on_vol_slider_changed(v: float) -> void:
	if _music_sync_block:
		return
	GameSettings.set_music_linear(v)


func _on_external_music_volume(v: float) -> void:
	if _vol_slider == null:
		return
	_music_sync_block = true
	_vol_slider.value = v
	_music_sync_block = false


func _is_user_scrubbing_progress() -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return false
	var vp: Viewport = get_viewport()
	if vp == null:
		return false
	return _progress.get_global_rect().has_point(vp.get_mouse_position())


func _on_progress_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_commit_seek()


func _commit_seek() -> void:
	if _tracked == null or not is_instance_valid(_tracked):
		return
	var dur: float = _stream_duration_sec()
	if dur <= 0.001:
		return
	_tracked.seek(clampf(_progress.value, 0.0, dur))


func _hide_card_instant() -> void:
	_panel_open = false
	if _card == null:
		return
	_card.visible = false
	_card.modulate.a = 1.0


func _show_card_animated() -> void:
	if _card == null:
		return
	if _anim_tween != null and is_instance_valid(_anim_tween):
		_anim_tween.kill()
	_card.visible = true
	_set_bar_position_clamped(_bar.position, true)
	_card.modulate.a = 0.0
	_anim_tween = create_tween()
	_anim_tween.tween_property(_card, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_card_animated() -> void:
	if _card == null or not _card.visible:
		_hide_card_instant()
		return
	if _anim_tween != null and is_instance_valid(_anim_tween):
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.tween_property(_card, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_anim_tween.finished.connect(_on_hide_anim_done, CONNECT_ONE_SHOT)


func _on_hide_anim_done() -> void:
	if _card != null:
		_card.visible = false
		_card.modulate.a = 1.0
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL and OS.get_name() == "Web":
		ExternalMusicPlayer.call_deferred("refresh_web_layout")


func _stream_duration_sec() -> float:
	if _tracked == null or not is_instance_valid(_tracked):
		return 0.0
	var st: AudioStream = _tracked.stream
	if st == null:
		return 0.0
	var len: float = st.get_length()
	if len <= 0.0 or is_nan(len):
		return 0.0
	return len


func _format_time(sec: float) -> String:
	var s: int = maxi(0, int(floor(sec)))
	var m: int = s / 60
	s = s % 60
	return "%d:%02d" % [m, s]


func _on_switch_music_source_pressed() -> void:
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_INTERNAL:
		GameSettings.set_music_source(GameSettings.MUSIC_SOURCE_EXTERNAL)
	else:
		GameSettings.set_music_source(GameSettings.MUSIC_SOURCE_INTERNAL)


func _on_fullscreen_btn_pressed() -> void:
	ExternalMusicPlayer.toggle_fullscreen()


func _on_open_in_browser_pressed() -> void:
	ExternalMusicPlayer.open_in_browser()


func _on_float_webview_pressed() -> void:
	ExternalMusicPlayer.agent_debug_emit("H-UI", "music_now_playing.gd:_on_float_webview_pressed", "float webview button pressed", {})
	ExternalMusicPlayer.show_desktop_moinyun_window()


func _try_activate_external_if_needed() -> void:
	if GameSettings.music_source != GameSettings.MUSIC_SOURCE_EXTERNAL:
		return
	ExternalMusicPlayer.activate()


func _on_music_source_changed(_source: String) -> void:
	_apply_music_source_visual_state()
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_INTERNAL:
		on_track_changed(GameMusic.get_current_title())
	elif _panel_open:
		ExternalMusicPlayer.activate()


func _on_external_fullscreen_changed(is_fullscreen: bool) -> void:
	if _fullscreen_btn != null:
		var ext: bool = GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL
		var is_web: bool = OS.get_name() == "Web"
		_fullscreen_btn.visible = ext and is_web and not is_fullscreen
	_refit_layout()


func _apply_music_source_visual_state() -> void:
	var ext: bool = GameSettings.music_source == GameSettings.MUSIC_SOURCE_EXTERNAL
	var is_web: bool = OS.get_name() == "Web"
	if _source_label != null:
		_source_label.text = "墨韵" if ext else "游戏内置"
	# Web 平台：显示 iframe 容器；其他平台：显示浏览器面板
	if _webview_mount != null:
		_webview_mount.visible = ext and is_web
		_webview_mount.custom_minimum_size = Vector2(0.0, 268.0) if (ext and is_web) else Vector2.ZERO
	if _browser_panel != null:
		_browser_panel.visible = ext and not is_web
	if _float_webview_btn != null:
		var desk: bool = ext and not is_web and OS.get_name() != "Android"
		_float_webview_btn.visible = desk and ExternalMusicPlayer.is_desktop_native_webview_supported()
	if _browser_hint_label != null and ext and not is_web:
		if OS.get_name() == "Android":
			_browser_hint_label.text = "游戏内音乐已静音。已尝试用系统浏览器打开墨韵，可在浏览器中操作播放。"
		else:
			_browser_hint_label.text = "游戏内音乐已静音。可点击下方打开独立浮窗（需已启用 godot-webview 插件），或使用系统浏览器播放。"
	# 全屏按钮仅 Web 平台可用
	if _fullscreen_btn != null:
		_fullscreen_btn.visible = ext and is_web and not ExternalMusicPlayer.is_fullscreen_mode
	if _prefix_label != null:
		_prefix_label.text = "第三方音乐" if ext else "正在播放："
	if _title_label != null:
		_title_label.text = "" if ext else GameMusic.get_current_title()
	var show_internal: bool = not ext
	if _progress != null:
		_progress.visible = show_internal
	if _time_row != null:
		_time_row.visible = show_internal
	if _ctrl_row != null:
		_ctrl_row.visible = show_internal
	if _vol_row_ref != null:
		_vol_row_ref.visible = show_internal
	_refit_layout()
	if ext and is_web:
		ExternalMusicPlayer.call_deferred("refresh_web_layout")


func _update_progress_from_player() -> void:
	if _tracked == null or not is_instance_valid(_tracked):
		return
	var dur: float = _stream_duration_sec()
	var pos: float = _tracked.get_playback_position()
	if dur <= 0.001:
		_progress.max_value = 1.0
		_progress.value = 0.0
		_time_total.text = "--:--"
		_time_elapsed.text = _format_time(pos)
		return
	_progress.max_value = dur
	_progress.value = clampf(pos, 0.0, dur)
	_time_elapsed.text = _format_time(pos)
	_time_total.text = _format_time(dur)
