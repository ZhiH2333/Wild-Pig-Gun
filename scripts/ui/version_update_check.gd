extends RefCounted
class_name VersionUpdateCheck

const GITHUB_API_STABLE_LATEST: String = (
	"https://api.github.com/repos/ZhiH2333/Wild-Pig-Gun/releases/latest"
)
const GITHUB_API_NEWEST_RELEASE: String = (
	"https://api.github.com/repos/ZhiH2333/Wild-Pig-Gun/releases?per_page=1"
)
const GITHUB_TAG_PAGE_BASE: String = "https://github.com/ZhiH2333/Wild-Pig-Gun/releases/tag/"

var _version_label: Label
var _check_update_button: Button
var _update_http: HTTPRequest
var _update_overlay: Control
var _update_title: Label
var _update_error_message: Label
var _update_body_split: HBoxContainer
var _update_current: Label
var _update_latest: Label
var _update_outdated: Label
var _update_download_link: LinkButton
var _update_changelog: RichTextLabel


func setup(
	version_label: Label,
	check_update_button: Button,
	update_http: HTTPRequest,
	update_overlay: Control,
	update_title: Label,
	update_error_message: Label,
	update_body_split: HBoxContainer,
	update_current: Label,
	update_latest: Label,
	update_outdated: Label,
	update_download_link: LinkButton,
	update_changelog: RichTextLabel
) -> void:
	_version_label = version_label
	_check_update_button = check_update_button
	_update_http = update_http
	_update_overlay = update_overlay
	_update_title = update_title
	_update_error_message = update_error_message
	_update_body_split = update_body_split
	_update_current = update_current
	_update_latest = update_latest
	_update_outdated = update_outdated
	_update_download_link = update_download_link
	_update_changelog = update_changelog


func wire() -> void:
	_check_update_button.pressed.connect(_on_check_update_pressed)
	_update_http.request_completed.connect(_on_update_check_completed)


func wire_ok_button(ok_button: Button) -> void:
	ok_button.pressed.connect(hide_result_overlay)


func apply_version_label() -> void:
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


func hide_result_overlay() -> void:
	_update_overlay.visible = false
