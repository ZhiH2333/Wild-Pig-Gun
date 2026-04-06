extends CanvasLayer

## 右下角圆形「音乐」入口；点击展开控制卡片：曲名、进度、暂停、上/下一首、音乐音量（与设置同步）

const _CARD_W: float = 292.0
const _MARGIN: float = 12.0
const _EDGE_MARGIN: float = 16.0
const _FAB_SIZE: float = 52.0
const _ICON_TEX_PX: int = 48

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_tracked = GameMusic.get_stream_player()
	GameMusic.track_changed.connect(_on_track_changed_signal)
	GameSettings.music_linear_changed.connect(_on_external_music_volume)
	_build_ui()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_refit_layout)
	_refit_layout()
	_hide_card_instant()
	if _title_label != null:
		_title_label.text = GameMusic.get_current_title()


func on_track_changed(title: String) -> void:
	if _title_label != null:
		_title_label.text = title if not title.is_empty() else "—"


func _on_track_changed_signal(title: String) -> void:
	on_track_changed(title)


func _process(_delta: float) -> void:
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
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -_CARD_W - _EDGE_MARGIN
	bar.offset_right = -_EDGE_MARGIN
	bar.offset_top = -420.0
	bar.offset_bottom = -_EDGE_MARGIN
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
	_progress = HSlider.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.step = 0.001
	_progress.custom_minimum_size = Vector2(0.0, 22.0)
	_progress.gui_input.connect(_on_progress_gui_input)
	v.add_child(_progress)
	var time_row: HBoxContainer = HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 8)
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
	_toggle_btn.text = ""
	_toggle_btn.tooltip_text = "音乐"
	_toggle_btn.icon = _make_music_icon_texture()
	_toggle_btn.expand_icon = true
	_toggle_btn.custom_minimum_size = Vector2(_FAB_SIZE, _FAB_SIZE)
	_toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_toggle_btn.add_theme_constant_override("icon_max_width", 26)
	_apply_fab_styles(_toggle_btn)
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
	var avail: float = maxf(0.0, vw - _EDGE_MARGIN * 2.0)
	var card_w: float = mini(_CARD_W, avail)
	_bar.offset_right = -_EDGE_MARGIN
	_bar.offset_left = -_EDGE_MARGIN - card_w
	_card.custom_minimum_size.x = card_w
	_refit_button_row(card_w)


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


func _make_music_icon_texture() -> Texture2D:
	var img: Image = Image.create(_ICON_TEX_PX, _ICON_TEX_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col: Color = Color(0.94, 0.92, 0.86, 1.0)
	var stem_x: int = 29
	for y in range(7, 36):
		img.set_pixel(stem_x, y, col)
		img.set_pixel(stem_x + 1, y, col)
	for x in range(19, 33):
		img.set_pixel(x, 7, col)
		img.set_pixel(x, 8, col)
	var cx: int = 15
	var cy: int = 30
	for dy in range(-5, 6):
		for dx in range(-8, 9):
			if float(dx * dx) / 64.0 + float(dy * dy) / 30.0 <= 1.0:
				img.set_pixel(cx + dx, cy + dy, col)
	return ImageTexture.create_from_image(img)


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
	_panel_open = not _panel_open
	if _panel_open:
		_show_card_animated()
	else:
		_hide_card_animated()


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
