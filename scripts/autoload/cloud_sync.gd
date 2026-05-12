extends Node
## CloudSync — 在 SaveManager（本地）与 CloudAPI（云端）之间执行同步策略。
## 不修改 SaveManager；只在外部调用其公开方法读写本地存档。
##
## 冲突解决原则：
##   - meta 数值字段取较大值（best_wave, total_runs, total_victories, wallet_gold 等）
##   - meta 数组字段取并集（purchased_character_ids）
##   - meta total_play_seconds 取较大值
##   - 存档槽：按 modified_unix 取较新；云端无该槽时推送本地，本地无该槽时写入本地

signal sync_started
signal sync_completed(success: bool)
signal sync_error(message: String)

## 同步防抖间隔（秒）：避免 meta_change 事件连续触发时反复请求
const META_DEBOUNCE_SEC: float = 5.0
## 启动同步最大等待时间（秒）：避免无网络时永久阻塞
const LAUNCH_TIMEOUT_SEC: float = 12.0

var _meta_debounce_timer: SceneTreeTimer = null
var _is_syncing: bool = false


func _ready() -> void:
	CloudAPI.login_state_changed.connect(_on_login_state_changed)


# ── 公开同步接口 ─────────────────────────────────────────────────────────────

## 游戏启动/登录后调用：拉取云端数据与本地合并
func sync_on_launch() -> void:
	if not CloudAPI.is_logged_in():
		return
	_begin_sync()
	var ok: bool = await _pull_and_merge_all()
	_end_sync(ok)


## 存档槽写入后调用：推送指定槽到云端
func sync_on_save(slot_id: String) -> void:
	if not CloudAPI.is_logged_in():
		return
	if slot_id.is_empty():
		return
	_begin_sync()
	var ok: bool = await _push_slot(slot_id)
	_end_sync(ok)


## meta_progress 变化后调用（带防抖）：推送 meta 到云端
func sync_on_meta_change() -> void:
	if not CloudAPI.is_logged_in():
		return
	if _meta_debounce_timer != null and is_instance_valid(_meta_debounce_timer):
		return
	_meta_debounce_timer = get_tree().create_timer(META_DEBOUNCE_SEC)
	await _meta_debounce_timer.timeout
	_meta_debounce_timer = null
	if not CloudAPI.is_logged_in():
		return
	_begin_sync()
	var ok: bool = await _push_meta()
	_end_sync(ok)


## 手动全量同步（拉取后推送）
func sync_now() -> void:
	if not CloudAPI.is_logged_in():
		sync_error.emit("未登录，无法同步")
		return
	if _is_syncing:
		return
	_begin_sync()
	var pull_ok: bool = await _pull_and_merge_all()
	if not pull_ok:
		_end_sync(false)
		return
	var push_ok: bool = await _push_all()
	_end_sync(push_ok)


# ── 内部：拉取合并 ───────────────────────────────────────────────────────────

func _pull_and_merge_all() -> bool:
	var meta_ok: bool = await _pull_and_merge_meta()
	var slots_ok: bool = await _pull_and_merge_slots()
	return meta_ok and slots_ok


func _pull_and_merge_meta() -> bool:
	var result: Dictionary = await CloudAPI.get_player_meta()
	if not result["ok"]:
		sync_error.emit("拉取云端进度失败：" + result["error"])
		return false
	var cloud_meta: Variant = (result["data"] as Dictionary).get("meta", result["data"])
	if not cloud_meta is Dictionary:
		return true
	var local_meta: Dictionary = SaveManager.load_meta_progress()
	var merged: Dictionary = _merge_meta(local_meta, cloud_meta as Dictionary)
	SaveManager.save_meta_progress(merged)
	return true


func _pull_and_merge_slots() -> bool:
	var result: Dictionary = await CloudAPI.get_slots()
	if not result["ok"]:
		sync_error.emit("拉取云端存档失败：" + result["error"])
		return false
	var cloud_slots: Variant = (result["data"] as Dictionary).get("slots", {})
	if not cloud_slots is Dictionary:
		return true
	var local_root: Dictionary = SaveManager.load_save_data()
	var local_slots: Dictionary = local_root.get("run_slots", {}) as Dictionary
	var merged_slots: Dictionary = _merge_slots(local_slots, cloud_slots as Dictionary)
	local_root["run_slots"] = merged_slots
	SaveManager.save_save_data(local_root)
	return true


# ── 内部：推送 ───────────────────────────────────────────────────────────────

func _push_meta() -> bool:
	var local_meta: Dictionary = SaveManager.load_meta_progress()
	var result: Dictionary = await CloudAPI.update_player_meta(local_meta)
	if not result["ok"]:
		sync_error.emit("推送进度失败：" + result["error"])
		return false
	return true


func _push_slot(slot_id: String) -> bool:
	var entry: Dictionary = SaveManager.get_slot_entry(slot_id)
	if entry.is_empty():
		return false
	var result: Dictionary = await CloudAPI.put_slot(slot_id, entry)
	if not result["ok"]:
		sync_error.emit("推送存档槽 %s 失败：%s" % [slot_id, result["error"]])
		return false
	return true


func _push_all() -> bool:
	var meta_ok: bool = await _push_meta()
	var slots_ok: bool = true
	var ids: PackedStringArray = SaveManager.list_slot_ids_chronological()
	for sid: String in ids:
		var ok: bool = await _push_slot(sid)
		if not ok:
			slots_ok = false
	return meta_ok and slots_ok


# ── 内部：冲突解决 ───────────────────────────────────────────────────────────

func _merge_meta(local: Dictionary, cloud: Dictionary) -> Dictionary:
	var merged: Dictionary = local.duplicate(true)
	for key: String in ["best_wave", "total_play_seconds", "wallet_gold", "runs", "victories"]:
		var lv: float = float(local.get(key, 0))
		var cv: float = float(cloud.get(key, 0))
		merged[key] = maxf(lv, cv)
	var local_ids: Array = local.get("purchased_character_ids", ["default"]) as Array
	var cloud_ids: Array = cloud.get("purchased_character_ids", ["default"]) as Array
	var id_set: Dictionary = {}
	for x: Variant in local_ids:
		id_set[str(x)] = true
	for x: Variant in cloud_ids:
		id_set[str(x)] = true
	merged["purchased_character_ids"] = id_set.keys()
	return merged


func _merge_slots(local: Dictionary, cloud: Dictionary) -> Dictionary:
	var merged: Dictionary = local.duplicate(true)
	for slot_id: String in cloud.keys():
		var cloud_entry: Variant = cloud[slot_id]
		if not cloud_entry is Dictionary:
			continue
		var ce: Dictionary = cloud_entry as Dictionary
		if not merged.has(slot_id):
			merged[slot_id] = ce
			continue
		var local_entry: Dictionary = merged[slot_id] as Dictionary
		var local_ts: int = int(local_entry.get("modified_unix", 0))
		var cloud_ts: int = int(ce.get("modified_unix", 0))
		if cloud_ts > local_ts:
			merged[slot_id] = ce
	return merged


# ── 内部：状态管理 ───────────────────────────────────────────────────────────

func _begin_sync() -> void:
	_is_syncing = true
	sync_started.emit()


func _end_sync(ok: bool) -> void:
	_is_syncing = false
	sync_completed.emit(ok)


func _on_login_state_changed(logged_in: bool) -> void:
	if logged_in:
		sync_on_launch()
