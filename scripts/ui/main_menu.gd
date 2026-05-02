extends Control

const MENU_BUTTON_CONTAINER_PATH: String = "MenuButtonsWrap/LeftMenuColumn/ButtonContainer"
const TUTORIAL_OVERLAY_SCRIPT: Script = preload("res://scripts/ui/tutorial_overlay.gd")
const GITHUB_API_STABLE_LATEST: String = (
	"https://api.github.com/repos/ZhiH2333/Wild-Pig-Gun/releases/latest"
)
const GITHUB_API_NEWEST_RELEASE: String = (
	"https://api.github.com/repos/ZhiH2333/Wild-Pig-Gun/releases?per_page=1"
)
const GITHUB_TAG_PAGE_BASE: String = "https://github.com/ZhiH2333/Wild-Pig-Gun/releases/tag/"

const BACKGROUND_SWAY_SPEED: float = 0.52
const BACKGROUND_SWAY_AMP_RAD: float = deg_to_rad(5.2)
const BACKGROUND_SWAY_SPRING: float = 13.5
const BACKGROUND_SWAY_DAMPING: float = 9.2
const BACKGROUND_SWAY_OVERSCALE: float = 1.14

@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var background: TextureRect = $Background
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
@onready var _update_changelog: RichTextLabel = $UpdateResultOverlay/Center/ResultCard/CardColumn/BodySplit/RightColumn/ChangelogScroll/ChangelogRichText
@onready var _update_ok: Button = $UpdateResultOverlay/Center/ResultCard/CardColumn/OkButton

var background_sway_phase: float = 0.0
var background_sway_angle: float = 0.0
var background_sway_angular_vel: float = 0.0
var _control_mode_dialog: Window = null


func _ready() -> void:
	GameMusic.ensure_playing_main_volume()
	_apply_version_label()
	_check_update_button.pressed.connect(_on_check_update_pressed)
	_update_http.request_completed.connect(_on_update_check_completed)
	_update_ok.pressed.connect(_hide_update_result_overlay)
	var continue_btn: Button = get_node("%s/ContinueButton" % MENU_BUTTON_CONTAINER_PATH) as Button
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh_continue_button()
	get_node("%s/StartButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_start_pressed)
	get_node("%s/CustomizeButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_character_pressed)
	get_node("%s/SettingsButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_settings_pressed)
	get_node("%s/AboutButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_credits_pressed)
	get_node("%s/QuitButton" % MENU_BUTTON_CONTAINER_PATH).pressed.connect(_on_quit_pressed)
	background.resized.connect(_update_background_sway_pivot)
	await get_tree().process_frame
	_update_background_sway_pivot()
	background.scale = Vector2(BACKGROUND_SWAY_OVERSCALE, BACKGROUND_SWAY_OVERSCALE)
	if not SaveManager.get_tutorial_completed() and not SaveManager.has_pending_run():
		TutorialSession.begin_from_main_menu()
		TUTORIAL_OVERLAY_SCRIPT.call("try_attach", self)
	if SaveManager.get_tutorial_completed() and not GameSettings.has_selected_control_mode:
		_show_control_mode_dialog()


func _show_control_mode_dialog() -> void:
	_control_mode_dialog = Window.new()
	_control_mode_dialog.title = "选择游玩方式"
	_control_mode_dialog.min_size = Vector2i(460, 320)
	_control_mode_dialog.unresizable = true
	_control_mode_dialog.exclusive = true
	_control_mode_dialog.transient = true
	add_child(_control_mode_dialog)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	_control_mode_dialog.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var hint: Label = Label.new()
	hint.text = "请选择您的游玩方式：\n触控设备请选择「虚拟摇杆」\n桌面设备请选择「键盘鼠标」"
	hint.add_theme_font_size_override("font_size", 20)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)
	var joystick_btn: Button = Button.new()
	joystick_btn.text = "虚拟摇杆"
	joystick_btn.custom_minimum_size = Vector2(160, 52)
	joystick_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(joystick_btn)
	var keyboard_btn: Button = Button.new()
	keyboard_btn.text = "键盘鼠标"
	keyboard_btn.custom_minimum_size = Vector2(160, 52)
	keyboard_btn.add_theme_font_size_override("font_size", 20)
	btn_row.add_child(keyboard_btn)
	var no_remind_check: CheckBox = CheckBox.new()
	no_remind_check.text = "不再提示"
	no_remind_check.add_theme_font_size_override("font_size", 18)
	vbox.add_child(no_remind_check)
	joystick_btn.pressed.connect(_on_control_mode_joystick.bind(no_remind_check))
	keyboard_btn.pressed.connect(_on_control_mode_keyboard.bind(no_remind_check))
	_control_mode_dialog.close_requested.connect(_on_control_mode_dialog_closed.bind(no_remind_check))
	_control_mode_dialog.popup_centered()


func _on_control_mode_joystick(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(true)
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _on_control_mode_keyboard(no_remind_check: CheckBox) -> void:
	GameSettings.set_mobile_controls_enabled(false)
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _on_control_mode_dialog_closed(no_remind_check: CheckBox) -> void:
	if no_remind_check.button_pressed:
		GameSettings.set_has_selected_control_mode(true)
	_close_control_mode_dialog()


func _close_control_mode_dialog() -> void:
	if is_instance_valid(_control_mode_dialog):
		_control_mode_dialog.queue_free()
		_control_mode_dialog = null


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
	var continue_btn: Button = get_node("%s/ContinueButton" % MENU_BUTTON_CONTAINER_PATH) as Button
	var has_save: bool = SaveManager.has_pending_run()
	continue_btn.disabled = not has_save
	if has_save:
		var summary: Dictionary = SaveManager.get_pending_run_summary()
		var wave: int = int(summary.get("wave_index", 0))
		continue_btn.text = "继续游戏-第%d波" % wave
		return
	continue_btn.text = "继续游戏-第0波"


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_start_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/pre_start.tscn")


func _on_character_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.gallery_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_settings_pressed() -> void:
	GameMusic.duck_for_subpage()
	RunState.settings_return_scene_path = "res://scenes/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_credits_pressed() -> void:
	GameMusic.duck_for_subpage()
	get_tree().change_scene_to_file("res://scenes/about.tscn")

func _show_info_dialog(message: String) -> void:
	info_dialog.dialog_text = message
	info_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()


func _apply_version_label() -> void:
	var raw: Variant = ProjectSettings.get_setting("application/config/version", "0.0.0")
	var ver: String = str(raw).strip_edges()
	if ver.is_empty():
		ver = "0.0.0"
	if not ver.begins_with("v"):
		_version_label.text = "v%s" % ver
	else:
		_version_label.text = ver


func _current_version_display() -> String:
	return _version_label.text


func _current_version_raw() -> String:
	var raw: Variant = ProjectSettings.get_setting("application/config/version", "0.0.0")
	return str(raw).strip_edges()


func _github_api_url_for_update_check() -> String:
	if GameSettings.update_channel == GameSettings.UPDATE_CHANNEL_STABLE:
		return GITHUB_API_STABLE_LATEST
	return GITHUB_API_NEWEST_RELEASE


func _release_download_page_url(tag_name: String) -> String:
	return GITHUB_TAG_PAGE_BASE + tag_name.uri_encode()


func _parse_release_from_github_body(response_body: PackedByteArray) -> Dictionary:
	var out: Dictionary = {"tag_name": "", "body": ""}
	var text: String = response_body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if GameSettings.update_channel == GameSettings.UPDATE_CHANNEL_STABLE:
		if typeof(parsed) != TYPE_DICTIONARY:
			return out
		var d: Dictionary = parsed as Dictionary
		out["tag_name"] = str(d.get("tag_name", "")).strip_edges()
		out["body"] = _github_release_body_to_string(d.get("body", null))
		return out
	if typeof(parsed) != TYPE_ARRAY:
		return out
	var arr: Array = parsed
	if arr.is_empty():
		return out
	var rel: Variant = arr[0]
	if typeof(rel) != TYPE_DICTIONARY:
		return out
	var rd: Dictionary = rel as Dictionary
	out["tag_name"] = str(rd.get("tag_name", "")).strip_edges()
	out["body"] = _github_release_body_to_string(rd.get("body", null))
	return out


func _github_release_body_to_string(raw: Variant) -> String:
	if raw == null:
		return ""
	return str(raw)


func _is_current_version_behind_latest(current_raw: String, latest_tag: String) -> bool:
	return _compare_semver_like(current_raw, latest_tag) < 0


## 将 a、b 中的版本片段按数字比较；忽略前导 v/V；忽略 - 之后的预发布后缀、+ 之后元数据
func _compare_semver_like(a: String, b: String) -> int:
	var pa: PackedInt32Array = _version_numeric_prefix(a)
	var pb: PackedInt32Array = _version_numeric_prefix(b)
	var n: int = maxi(pa.size(), pb.size())
	for i: int in n:
		var va: int = pa[i] if i < pa.size() else 0
		var vb: int = pb[i] if i < pb.size() else 0
		if va < vb:
			return -1
		if va > vb:
			return 1
	return 0


func _version_numeric_prefix(ver: String) -> PackedInt32Array:
	var t: String = ver.strip_edges()
	if t.begins_with("v") or t.begins_with("V"):
		t = t.substr(1)
	var plus: int = t.find("+")
	if plus >= 0:
		t = t.substr(0, plus)
	var hyphen: int = t.find("-")
	if hyphen >= 0:
		t = t.substr(0, hyphen)
	var parts: PackedStringArray = t.split(".")
	var out: PackedInt32Array = PackedInt32Array()
	for i: int in parts.size():
		var seg: String = str(parts[i])
		var acc: String = ""
		for j: int in seg.length():
			var ch: String = seg.substr(j, 1)
			if ch.is_valid_int():
				acc += ch
			else:
				break
		if acc.is_empty():
			out.append(0)
		else:
			out.append(int(acc))
	return out


func _on_check_update_pressed() -> void:
	if _update_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_check_update_button.disabled = true
	var headers: PackedStringArray = PackedStringArray([
		"User-Agent: WildPigGun/VersionCheck (Godot)",
		"Accept: application/vnd.github+json",
	])
	var url: String = _github_api_url_for_update_check()
	var err: Error = _update_http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_check_update_button.disabled = false
		_show_update_result_overlay_error("无法发起网络请求（错误码 %d）" % err)


func _on_update_check_completed(
	_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	_check_update_button.disabled = false
	if _result != HTTPRequest.RESULT_SUCCESS:
		_show_update_result_overlay_error(_http_result_message(_result))
		return
	if response_code == 404 and GameSettings.update_channel == GameSettings.UPDATE_CHANNEL_STABLE:
		_show_update_result_overlay_error("暂无正式版 Release（GitHub 未返回 latest）")
		return
	if response_code != 200:
		_show_update_result_overlay_error("查询失败（HTTP %d）" % response_code)
		return
	var rel: Dictionary = _parse_release_from_github_body(body)
	var tag_name: String = str(rel.get("tag_name", "")).strip_edges()
	if tag_name.is_empty():
		_show_update_result_overlay_error("未找到版本标签或响应格式无效")
		return
	var release_notes: String = str(rel.get("body", ""))
	_show_update_result_overlay_success(tag_name, release_notes)


func _http_result_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "网络错误：分块大小异常"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "网络错误：无法连接服务器"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "网络错误：无法解析地址"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "网络错误：连接中断"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "网络错误：服务器无响应"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "网络错误：响应过大"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "网络错误：请求失败"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "网络错误：安全握手失败"
		_:
			return "网络错误（代码 %d）" % result


func _show_update_result_overlay_success(latest_tag: String, release_notes: String) -> void:
	_update_title.text = "版本信息"
	_update_error_message.visible = false
	_update_body_split.visible = true
	_update_current.text = "当前版本：%s" % _current_version_display()
	_update_latest.text = "最新版本：%s" % latest_tag
	_update_latest.visible = true
	var behind: bool = _is_current_version_behind_latest(_current_version_raw(), latest_tag)
	_update_outdated.visible = behind
	_update_download_link.visible = true
	_update_download_link.uri = _release_download_page_url(latest_tag)
	_update_download_link.text = "打开最新版本的下载页"
	_set_update_changelog_text(release_notes)
	_update_overlay.visible = true


func _set_update_changelog_text(release_notes: String) -> void:
	_update_changelog.clear()
	var trimmed: String = release_notes.strip_edges()
	if trimmed.is_empty():
		_update_changelog.add_text("（此版本未填写更新说明）")
	else:
		_update_changelog.add_text(trimmed)


func _show_update_result_overlay_error(message: String) -> void:
	_update_title.text = "检查更新"
	_update_error_message.text = message
	_update_error_message.visible = true
	_update_body_split.visible = false
	_update_overlay.visible = true


func _hide_update_result_overlay() -> void:
	_update_overlay.visible = false
