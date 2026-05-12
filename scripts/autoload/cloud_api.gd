extends Node
## CloudAPI — 封装所有对 https://api.wpgun.qzz.io 的 HTTP 请求。
## 不包含任何业务逻辑；只负责网络通信和凭证持久化。
## 所有公开方法均为异步，返回 { ok: bool, data: Dictionary, error: String }。

signal login_state_changed(logged_in: bool)
signal api_reachability_changed(reachable: bool)

const BASE_URL: String = "https://api.wpgun.qzz.io"
const TOKEN_PATH: String = "user://cloud_token.dat"
const USER_ID_PATH: String = "user://cloud_user.dat"

var _token: String = ""
var _user_id: String = ""


func _ready() -> void:
	_load_credentials()
	call_deferred("_run_startup_ping")


# ── 状态查询 ────────────────────────────────────────────────────────────────

func is_logged_in() -> bool:
	return not _token.is_empty()


func get_user_id() -> String:
	return _user_id


func _ping_server() -> bool:
	var http: HTTPRequest = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	var headers: PackedStringArray = PackedStringArray(["Accept: application/json"])
	var err: Error = http.request(BASE_URL + "/", headers, HTTPClient.METHOD_GET, "")
	if err != OK:
		http.queue_free()
		return false
	var response: Array = await http.request_completed
	http.queue_free()
	return int(response[0]) == HTTPRequest.RESULT_SUCCESS


func _run_startup_ping() -> void:
	var reachable: bool = await _ping_server()
	api_reachability_changed.emit(reachable)


# ── 认证 ────────────────────────────────────────────────────────────────────

func register(email: String, password: String) -> Dictionary:
	return await _http_post("/auth/register", {"email": email, "password": password}, false)


func verify_code(email: String, code: String) -> Dictionary:
	var result: Dictionary = await _http_post(
		"/auth/verify-code", {"email": email, "code": code}, false
	)
	if result["ok"]:
		var data: Dictionary = result["data"]
		var token: String = str(data.get("token", ""))
		var uid: String = str(data.get("user_id", ""))
		if not token.is_empty():
			_save_credentials(token, uid)
			login_state_changed.emit(true)
	return result


func resend_code(email: String) -> Dictionary:
	return await _http_post("/auth/resend-code", {"email": email}, false)


func login(email: String, password: String) -> Dictionary:
	var result: Dictionary = await _http_post(
		"/auth/login", {"email": email, "password": password}, false
	)
	if result["ok"]:
		var data: Dictionary = result["data"]
		var token: String = str(data.get("token", ""))
		var uid: String = str(data.get("user_id", ""))
		if not token.is_empty():
			_save_credentials(token, uid)
			login_state_changed.emit(true)
	return result


func logout() -> void:
	if is_logged_in():
		_http_post("/auth/logout", {}, true)
	_clear_credentials()
	login_state_changed.emit(false)


# ── 名片 ────────────────────────────────────────────────────────────────────

func get_profile(user_id: String) -> Dictionary:
	return await _http_get("/profile/" + user_id, true)


func update_profile(data: Dictionary) -> Dictionary:
	return await _http_put("/profile", data, true)


func heartbeat(status: String) -> Dictionary:
	return await _http_post("/heartbeat", {"status": status}, true)


# ── 元进度 ──────────────────────────────────────────────────────────────────

func get_player_meta() -> Dictionary:
	return await _http_get("/meta", true)


func update_player_meta(data: Dictionary) -> Dictionary:
	return await _http_put("/meta", data, true)


# ── 存档槽 ──────────────────────────────────────────────────────────────────

func get_slots() -> Dictionary:
	return await _http_get("/slots", true)


func get_slot(slot_id: String) -> Dictionary:
	return await _http_get("/slots/" + slot_id, true)


func put_slot(slot_id: String, data: Dictionary) -> Dictionary:
	return await _http_put("/slots/" + slot_id, data, true)


# ── 社区 ────────────────────────────────────────────────────────────────────

func record_run(data: Dictionary) -> Dictionary:
	return await _http_post("/runs", data, true)


func get_feed(page: int, limit: int) -> Dictionary:
	return await _http_get("/feed?page=%d&limit=%d" % [page, limit], true)


func get_leaderboard(type: String, limit: int) -> Dictionary:
	return await _http_get("/leaderboard?type=%s&limit=%d" % [type, limit], true)


func get_history(user_id: String, page: int) -> Dictionary:
	return await _http_get("/history/%s?page=%d" % [user_id, page], true)


func like_run(run_id: String) -> Dictionary:
	return await _http_post("/runs/" + run_id + "/like", {}, true)


# ── 内部：HTTP 便捷封装 ──────────────────────────────────────────────────────

func _http_get(path: String, auth: bool) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, path, {}, auth)


func _http_post(path: String, body: Dictionary, auth: bool) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, path, body, auth)


func _http_put(path: String, body: Dictionary, auth: bool) -> Dictionary:
	return await _request(HTTPClient.METHOD_PUT, path, body, auth)


func _request(method: int, path: String, body: Dictionary, auth: bool) -> Dictionary:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
	if auth and not _token.is_empty():
		headers.append("Authorization: Bearer " + _token)
	var body_str: String = "" if body.is_empty() else JSON.stringify(body)
	var err: Error = http.request(BASE_URL + path, headers, method, body_str)
	if err != OK:
		http.queue_free()
		return {"ok": false, "data": {}, "error": "请求发起失败(%d)" % err}
	var response: Array = await http.request_completed
	http.queue_free()
	var response_code: int = int(response[1])
	var response_body: PackedByteArray = response[3]
	var text: String = response_body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK:
		return {"ok": false, "data": {}, "error": "JSON解析失败"}
	var parsed: Variant = json.data
	var data_dict: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	var ok: bool = response_code >= 200 and response_code < 300
	var error_msg: String = ""
	if not ok:
		error_msg = str(data_dict.get("message", data_dict.get("error", "请求失败(%d)" % response_code)))
	return {"ok": ok, "data": data_dict, "error": error_msg}


# ── 凭证持久化 ───────────────────────────────────────────────────────────────

func _load_credentials() -> void:
	if FileAccess.file_exists(TOKEN_PATH):
		var f: FileAccess = FileAccess.open(TOKEN_PATH, FileAccess.READ)
		if f != null:
			_token = f.get_as_text().strip_edges()
	if FileAccess.file_exists(USER_ID_PATH):
		var f: FileAccess = FileAccess.open(USER_ID_PATH, FileAccess.READ)
		if f != null:
			_user_id = f.get_as_text().strip_edges()


func _save_credentials(token: String, user_id: String) -> void:
	_token = token
	_user_id = user_id
	var ft: FileAccess = FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
	if ft != null:
		ft.store_string(token)
	var fu: FileAccess = FileAccess.open(USER_ID_PATH, FileAccess.WRITE)
	if fu != null:
		fu.store_string(user_id)


func _clear_credentials() -> void:
	_token = ""
	_user_id = ""
	if FileAccess.file_exists(TOKEN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TOKEN_PATH))
	if FileAccess.file_exists(USER_ID_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(USER_ID_PATH))
