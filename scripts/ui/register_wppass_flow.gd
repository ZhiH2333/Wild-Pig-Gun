extends Control
class_name RegisterWppassFlow

signal register_completed(username: String)
signal flow_cancelled

const FONT_PATH: String = "res://assets/fonts/SourceHanSansSC-Bold.otf"
const BLACK_BTN: Theme = preload("res://themes/black_button_theme.tres")
const TAB_BTN: Theme = preload("res://themes/settings_tab_theme.tres")
const GAME_UI_THEME: Theme = preload("res://themes/game_ui_theme.tres")

const MODAL_FADE_SEC: float = 0.32
const LOADING_MIN_SEC: float = 1.15
const CARD_PROGRESS_SEC: float = 2.0
const CARD_SLIDE_IN_SEC: float = 0.48
const CARD_SLIDE_OUT_SEC: float = 0.42
const CODE_VERIFICATION_DIGIT_COUNT: int = 6
const CODE_RESEND_COOLDOWN_SEC: float = 60.0

var _font: Font
var _dim: ColorRect
var _vignette: ColorRect
var _step1: Control
var _step2: Control
var _step3: Control
var _error_popup: Control
var _error_label: Label
var _success_card: Control
var _success_close_btn: Button
var _success_label: Label
var _success_bar: ProgressBar
var _success_x_start: float = 0.0
var _success_x_end: float = 0.0
var _success_y: float = 22.0
var _success_user_closed: bool = false
var _success_sliding_out: bool = false
var _success_slide_tw: Tween

var _email_edit: LineEdit
var _username_edit: LineEdit
var _pass_edit: LineEdit
var _pass_confirm_edit: LineEdit

var _code_inputs: Array[LineEdit] = []
var _timer_bar: ProgressBar
var _resend_btn: Button
var _code_time_left: float = CODE_RESEND_COOLDOWN_SEC
var _code_timer_active: bool = false

var _busy: bool = false
var _loading_overlay: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 300
	_font = load(FONT_PATH) as Font
	_build_ui()
	set_process(true)
	call_deferred("_fade_in_step1")

func _process(delta: float) -> void:
	if not _code_timer_active:
		return
	_code_time_left -= delta
	if _code_time_left <= 0.0:
		_code_time_left = 0.0
		_code_timer_active = false
		if _resend_btn != null:
			_resend_btn.visible = true
	if _timer_bar != null:
		_timer_bar.value = _code_time_left

func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()

func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.color = Color(0, 0, 0, 0.0)
	add_child(_dim)
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(0, 0, 0, 0.0)
	add_child(_vignette)
	
	_step1 = _make_step1()
	_step1.modulate.a = 0.0
	add_child(_step1)
	
	_step2 = _make_step2()
	_step2.visible = false
	_step2.modulate.a = 0.0
	add_child(_step2)
	
	_step3 = _make_step3()
	_step3.visible = false
	_step3.modulate.a = 0.0
	add_child(_step3)
	
	_success_card = _make_success_card()
	_success_card.visible = false
	_success_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_success_card)
	
	_error_popup = _make_error_popup()
	_error_popup.visible = false
	_error_popup.modulate.a = 0.0
	add_child(_error_popup)
	_loading_overlay = _make_loading_overlay()
	_loading_overlay.visible = false
	add_child(_loading_overlay)

func _create_update_result_card_panel_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.content_margin_left = 22.0
	sb.content_margin_top = 20.0
	sb.content_margin_right = 22.0
	sb.content_margin_bottom = 22.0
	sb.bg_color = Color(0.08, 0.07, 0.1, 0.96)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.38)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb

func _make_modal_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 10)
	card.add_theme_stylebox_override("panel", _create_update_result_card_panel_style())
	return card

func _make_step1() -> Control:
	var wrap: CenterContainer = CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: PanelContainer = _make_modal_card()
	wrap.add_child(card)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	var title: Label = Label.new()
	title.text = "输入您的邮箱"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(title, 28)
	col.add_child(title)
	
	_email_edit = LineEdit.new()
	_email_edit.theme = GAME_UI_THEME
	_email_edit.placeholder_text = "邮箱"
	_email_edit.custom_minimum_size = Vector2(0, 54)
	_apply_font(_email_edit, 22)
	col.add_child(_email_edit)
	
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var back: Button = _make_text_button("上一步")
	back.pressed.connect(_on_cancel_pressed)
	row.add_child(back)
	var go: Button = _make_text_button("下一步")
	go.pressed.connect(_on_step1_continue_pressed)
	row.add_child(go)
	return wrap

func _make_step2() -> Control:
	var wrap: CenterContainer = CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: PanelContainer = _make_modal_card()
	wrap.add_child(card)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	var title: Label = Label.new()
	title.text = "输入您的信息"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(title, 28)
	col.add_child(title)
	
	_username_edit = LineEdit.new()
	_username_edit.theme = GAME_UI_THEME
	_username_edit.placeholder_text = "用户名"
	_username_edit.custom_minimum_size = Vector2(0, 54)
	_apply_font(_username_edit, 22)
	col.add_child(_username_edit)
	
	_pass_edit = LineEdit.new()
	_pass_edit.theme = GAME_UI_THEME
	_pass_edit.placeholder_text = "密码"
	_pass_edit.secret = true
	_pass_edit.custom_minimum_size = Vector2(0, 54)
	_apply_font(_pass_edit, 22)
	col.add_child(_pass_edit)
	
	_pass_confirm_edit = LineEdit.new()
	_pass_confirm_edit.theme = GAME_UI_THEME
	_pass_confirm_edit.placeholder_text = "确认密码"
	_pass_confirm_edit.secret = true
	_pass_confirm_edit.custom_minimum_size = Vector2(0, 54)
	_apply_font(_pass_confirm_edit, 22)
	col.add_child(_pass_confirm_edit)
	
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var back: Button = _make_text_button("上一步")
	back.pressed.connect(_on_step2_back_pressed)
	row.add_child(back)
	var go: Button = _make_text_button("下一步")
	go.pressed.connect(_on_step2_continue_pressed)
	row.add_child(go)
	return wrap

func _make_step3() -> Control:
	var wrap: CenterContainer = CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: PanelContainer = _make_modal_card()
	card.custom_minimum_size = Vector2(640, 10)
	wrap.add_child(card)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	
	var title: Label = Label.new()
	title.text = "输入验证码"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(title, 28)
	col.add_child(title)
	
	var subtitle: Label = Label.new()
	subtitle.text = "请输入发送至您邮箱的6位验证码"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	_apply_font(subtitle, 16)
	col.add_child(subtitle)
	
	var code_row: HBoxContainer = HBoxContainer.new()
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", 8)
	col.add_child(code_row)
	
	_code_inputs.clear()
	var last_digit_idx: int = CODE_VERIFICATION_DIGIT_COUNT - 1
	for i in range(CODE_VERIFICATION_DIGIT_COUNT):
		if i == 3:
			var dash: Label = Label.new()
			dash.text = "-"
			dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_apply_font(dash, 28)
			code_row.add_child(dash)
		var input: LineEdit = LineEdit.new()
		input.theme = GAME_UI_THEME
		input.custom_minimum_size = Vector2(48, 64)
		input.max_length = 1
		input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(input, 28)
		code_row.add_child(input)
		_code_inputs.append(input)
		var current_idx: int = i
		input.text_changed.connect(func(new_text: String):
			if new_text.length() > 0 and current_idx < last_digit_idx:
				_code_inputs[current_idx + 1].grab_focus()
		)
	
	var progress_col: VBoxContainer = VBoxContainer.new()
	progress_col.add_theme_constant_override("separation", 8)
	col.add_child(progress_col)
	
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 4)
	_timer_bar.max_value = CODE_RESEND_COOLDOWN_SEC
	_timer_bar.value = CODE_RESEND_COOLDOWN_SEC
	_timer_bar.show_percentage = false
	_timer_bar.add_theme_color_override("fill", Color(0.95, 0.78, 0.32, 0.95))
	progress_col.add_child(_timer_bar)
	
	_resend_btn = _make_tab_button("重新发送")
	_resend_btn.visible = false
	_resend_btn.pressed.connect(_on_resend_pressed)
	progress_col.add_child(_resend_btn)
	
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var back: Button = _make_text_button("上一步")
	back.pressed.connect(_on_step3_back_pressed)
	row.add_child(back)
	var go: Button = _make_text_button("下一步")
	go.pressed.connect(_on_step3_continue_pressed)
	row.add_child(go)
	
	return wrap

func _make_success_card() -> Control:
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _create_update_result_card_panel_style())
	root.add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	_success_label = Label.new()
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_success_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_success_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1))
	_apply_font(_success_label, 22)
	col.add_child(_success_label)
	_success_bar = ProgressBar.new()
	_success_bar.custom_minimum_size = Vector2(300, 10)
	_success_bar.max_value = 100.0
	_success_bar.value = 0.0
	_success_bar.show_percentage = false
	_success_bar.add_theme_color_override("fill", Color(0.95, 0.78, 0.32, 0.95))
	col.add_child(_success_bar)
	_success_close_btn = Button.new()
	_success_close_btn.text = "✕"
	_success_close_btn.flat = true
	_success_close_btn.focus_mode = Control.FOCUS_NONE
	_success_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_success_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_success_close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_success_close_btn.offset_left = -48.0
	_success_close_btn.offset_right = -10.0
	_success_close_btn.offset_top = 8.0
	_success_close_btn.offset_bottom = 44.0
	if _font != null:
		_success_close_btn.add_theme_font_override("font", _font)
	_success_close_btn.add_theme_font_size_override("font_size", 24)
	_success_close_btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82, 0.72))
	_success_close_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.95))
	_success_close_btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.8, 0.75, 1))
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		_success_close_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_success_close_btn.visible = false
	_success_close_btn.pressed.connect(_on_success_close_pressed)
	root.add_child(_success_close_btn)
	return root

func _make_loading_overlay() -> Control:
	var wrap: CenterContainer = CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 10)
	card.add_theme_stylebox_override("panel", _create_update_result_card_panel_style())
	wrap.add_child(card)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 22)
	card.add_child(inner)
	var lbl: Label = Label.new()
	lbl.text = "正在处理…"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1))
	_apply_font(lbl, 26)
	inner.add_child(lbl)
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(280, 18)
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	inner.add_child(bar)
	var loading_tween: Tween = null
	wrap.set_meta("bar", bar)
	wrap.set_meta("tween_ref", loading_tween)
	return wrap


func _show_loading_overlay() -> void:
	if _loading_overlay == null:
		return
	_loading_overlay.visible = true
	var bar: ProgressBar = _loading_overlay.get_meta("bar") as ProgressBar
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(bar, "value", 96.0, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(bar, "value", 14.0, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_loading_overlay.set_meta("tween_ref", tw)


func _hide_loading_overlay() -> void:
	if _loading_overlay == null:
		return
	var tw_ref: Variant = _loading_overlay.get_meta("tween_ref", null)
	if tw_ref is Tween and is_instance_valid(tw_ref as Tween):
		(tw_ref as Tween).kill()
	_loading_overlay.visible = false


func _make_error_popup() -> Control:
	var wrap: CenterContainer = CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var card: PanelContainer = _make_modal_card()
	card.custom_minimum_size = Vector2(400, 10)
	wrap.add_child(card)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	card.add_child(col)
	
	_error_label = Label.new()
	_error_label.text = "密码不符合"
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	_apply_font(_error_label, 24)
	col.add_child(_error_label)
	
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var ok_btn: Button = _make_text_button("确定")
	ok_btn.pressed.connect(_on_error_ok_pressed)
	row.add_child(ok_btn)
	
	return wrap

func _make_text_button(txt: String) -> Button:
	var b: Button = Button.new()
	b.text = txt
	b.theme = BLACK_BTN
	b.custom_minimum_size = Vector2(140, 52)
	b.focus_mode = Control.FOCUS_NONE
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 22)
	return b

func _make_tab_button(txt: String) -> Button:
	var b: Button = Button.new()
	b.text = txt
	b.theme = TAB_BTN
	b.custom_minimum_size = Vector2(0, 48)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 20)
	return b

func _apply_font(l: Control, px: int) -> void:
	if _font != null and l is Control:
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", px)

func _fade_in_step1() -> void:
	_email_edit.grab_focus()
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.62, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_vignette, "color:a", 0.18, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_step1, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_cancel_pressed() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_vignette, "color:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_step1, "modulate:a", 0.0, MODAL_FADE_SEC)
	tw.tween_property(_step2, "modulate:a", 0.0, MODAL_FADE_SEC)
	tw.tween_property(_step3, "modulate:a", 0.0, MODAL_FADE_SEC)
	await tw.finished
	flow_cancelled.emit()
	queue_free()

func _on_step1_continue_pressed() -> void:
	if _busy:
		return
	var email: String = _email_edit.text.strip_edges()
	if email.is_empty():
		return
	_busy = true
	var tw: Tween = create_tween()
	tw.tween_property(_step1, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_step1.visible = false
	_step2.visible = true
	_username_edit.grab_focus()
	var tw2: Tween = create_tween()
	tw2.tween_property(_step2, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_busy = false

func _on_step2_back_pressed() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = create_tween()
	tw.tween_property(_step2, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_step2.visible = false
	_step1.visible = true
	var tw2: Tween = create_tween()
	tw2.tween_property(_step1, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_email_edit.grab_focus()
	_busy = false

func _on_step2_continue_pressed() -> void:
	if _busy:
		return
	var any_empty: bool = (
		_username_edit.text.is_empty()
		or _pass_edit.text.is_empty()
		or _pass_confirm_edit.text.is_empty()
	)
	if any_empty:
		return
	if _pass_edit.text != _pass_confirm_edit.text:
		_show_error("两次输入的密码不一致")
		return
	_busy = true
	var email: String = _email_edit.text.strip_edges()
	var password: String = _pass_edit.text
	_show_loading_overlay()
	var result: Dictionary = await CloudAPI.register(email, password)
	_hide_loading_overlay()
	if not result["ok"]:
		_show_error(result["error"] if not result["error"].is_empty() else "注册失败，请稍后重试")
		return
	var tw: Tween = create_tween()
	tw.tween_property(_step2, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	await tw.finished
	_step2.visible = false
	_step3.visible = true
	_code_time_left = CODE_RESEND_COOLDOWN_SEC
	_code_timer_active = true
	_resend_btn.visible = false
	_timer_bar.value = CODE_RESEND_COOLDOWN_SEC
	for input in _code_inputs:
		input.text = ""
	_code_inputs[0].grab_focus()
	var tw2: Tween = create_tween()
	tw2.tween_property(_step3, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_busy = false

func _on_step3_back_pressed() -> void:
	if _busy:
		return
	_busy = true
	_code_timer_active = false
	var tw: Tween = create_tween()
	tw.tween_property(_step3, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_step3.visible = false
	_step2.visible = true
	var tw2: Tween = create_tween()
	tw2.tween_property(_step2, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_username_edit.grab_focus()
	_busy = false

func _on_resend_pressed() -> void:
	_resend_btn.disabled = true
	var email: String = _email_edit.text.strip_edges()
	await CloudAPI.resend_code(email)
	_resend_btn.disabled = false
	_code_time_left = CODE_RESEND_COOLDOWN_SEC
	_code_timer_active = true
	_resend_btn.visible = false
	_timer_bar.value = CODE_RESEND_COOLDOWN_SEC
	for input in _code_inputs:
		input.text = ""
	_code_inputs[0].grab_focus()

func _on_step3_continue_pressed() -> void:
	if _busy:
		return
	var code: String = ""
	for input in _code_inputs:
		code += input.text
	if code.length() < CODE_VERIFICATION_DIGIT_COUNT:
		return
	_busy = true
	_code_timer_active = false
	var email: String = _email_edit.text.strip_edges()
	var username: String = _username_edit.text.strip_edges()
	_show_loading_overlay()
	var result: Dictionary = await CloudAPI.verify_code(email, code)
	_hide_loading_overlay()
	if not result["ok"]:
		_show_error(result["error"] if not result["error"].is_empty() else "验证码错误或已过期")
		return
	if not username.is_empty():
		await CloudAPI.update_profile({"username": username})
	var tw: Tween = create_tween()
	tw.tween_property(_step3, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	await tw.finished
	_step3.visible = false
	_dim.color.a = 0.0
	_vignette.color.a = 0.0
	CloudSync.sync_on_launch()
	var display_name: String = username if not username.is_empty() else email
	await _play_success_card("已注册", display_name)
	await _play_success_card("已登录至", display_name)
	register_completed.emit(display_name)
	queue_free()

func _play_success_card(prefix: String, username: String) -> void:
	_success_user_closed = false
	_success_sliding_out = false
	_success_label.text = "%s\n%s" % [prefix, username]
	_success_bar.value = 0.0
	_success_close_btn.visible = false
	_success_card.visible = true
	await get_tree().process_frame
	var w: float = size.x
	var card_w: float = maxf(280.0, _success_card.get_combined_minimum_size().x)
	_success_card.custom_minimum_size = Vector2(card_w, 0.0)
	await get_tree().process_frame
	var h: float = maxf(1.0, _success_card.size.y)
	_success_y = 22.0
	_success_x_end = w - card_w - 28.0
	_success_x_start = w + 24.0
	_success_card.position = Vector2(_success_x_start, _success_y)
	_success_card.size = Vector2(card_w, h)
	var tw_in: Tween = create_tween()
	tw_in.tween_property(_success_card, "position:x", _success_x_end, CARD_SLIDE_IN_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished
	_success_close_btn.visible = true
	var elapsed: float = 0.0
	while elapsed < CARD_PROGRESS_SEC and not _success_user_closed:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		_success_bar.value = clampf((elapsed / CARD_PROGRESS_SEC) * 100.0, 0.0, 100.0)
	if not _success_user_closed:
		_success_bar.value = 100.0
	await _slide_out_success_card()

func _on_success_close_pressed() -> void:
	_success_user_closed = true

func _slide_out_success_card() -> void:
	if not _success_card.visible:
		return
	if _success_sliding_out:
		if _success_slide_tw != null and is_instance_valid(_success_slide_tw):
			await _success_slide_tw.finished
		return
	_success_sliding_out = true
	_success_close_btn.visible = false
	_success_slide_tw = create_tween()
	_success_slide_tw.tween_property(
		_success_card,
		"position:x",
		_success_x_start,
		CARD_SLIDE_OUT_SEC * 0.75
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _success_slide_tw.finished
	_success_slide_tw = null
	_success_card.visible = false
	_success_sliding_out = false

func _show_error(msg: String) -> void:
	_busy = true
	_error_label.text = msg
	_error_popup.visible = true
	var tw: Tween = create_tween()
	tw.tween_property(_error_popup, "modulate:a", 1.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

func _on_error_ok_pressed() -> void:
	if not _error_popup.visible or _error_popup.modulate.a < 1.0:
		return
	var tw: Tween = create_tween()
	tw.tween_property(_error_popup, "modulate:a", 0.0, MODAL_FADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_error_popup.visible = false
	_busy = false
