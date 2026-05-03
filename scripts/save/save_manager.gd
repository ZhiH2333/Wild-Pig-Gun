extends Node

const SAVE_PATH: String = "user://wild_pig_gun_save.json"
const KEY_PENDING_RUN: String = "pending_run"
const KEY_RUN_SLOTS: String = "run_slots"
const KEY_LAST_PLAYED_SLOT_ID: String = "last_played_slot_id"
const KEY_TUTORIAL_COMPLETED: String = "tutorial_completed"
const KEY_WALLET_GOLD: String = "wallet_gold"
const KEY_PURCHASED_CHARACTER_IDS: String = "purchased_character_ids"
const MAX_CHARACTER_ID_LENGTH: int = 48

## 当前局绑定的存档槽（由主菜单/开始页在进 Arena 前设置）
var active_save_slot_id: String = ""

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		return {}
	var data: Variant = json.data
	var root: Dictionary = data as Dictionary if data is Dictionary else {}
	_migrate_legacy_pending_to_slots(root)
	return root


func save_save_data(data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_text)
	return true


func _ensure_run_slots(root: Dictionary) -> Dictionary:
	var rs: Variant = root.get(KEY_RUN_SLOTS, {})
	if rs is Dictionary:
		return rs as Dictionary
	var d: Dictionary = {}
	root[KEY_RUN_SLOTS] = d
	return d


func _migrate_legacy_pending_to_slots(root: Dictionary) -> void:
	var slots: Dictionary = _ensure_run_slots(root)
	var pending: Variant = root.get(KEY_PENDING_RUN, {})
	var has_pending: bool = pending is Dictionary and not (pending as Dictionary).is_empty()
	if not slots.is_empty():
		if has_pending:
			root.erase(KEY_PENDING_RUN)
			save_save_data(root)
		return
	if not has_pending:
		return
	var slot_id: String = _alloc_slot_id(root)
	var unix: int = int(Time.get_unix_time_from_system())
	slots[slot_id] = {
		"display_name": "存档1",
		"created_unix": unix,
		"modified_unix": unix,
		"play_time_sec": 0,
		"run": (pending as Dictionary).duplicate(true),
	}
	root[KEY_RUN_SLOTS] = slots
	root[KEY_LAST_PLAYED_SLOT_ID] = slot_id
	root.erase(KEY_PENDING_RUN)
	save_save_data(root)


func _alloc_slot_id(root: Dictionary) -> String:
	var slots: Dictionary = _ensure_run_slots(root)
	var max_n: int = 0
	for k in slots.keys():
		var ks: String = str(k)
		if ks.begins_with("s_") and ks.substr(2).is_valid_int():
			max_n = maxi(max_n, int(ks.substr(2)))
	return "s_%d" % (max_n + 1)


func _count_slots(root: Dictionary) -> int:
	return _ensure_run_slots(root).size()


func _default_display_name_for_new_slot(root: Dictionary) -> String:
	return "存档%d" % (_count_slots(root) + 1)


func get_run_slots_copy() -> Dictionary:
	var root: Dictionary = load_save_data()
	return _ensure_run_slots(root).duplicate(true)


func list_slot_ids_chronological() -> PackedStringArray:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	var pairs: Array = []
	for k in slots.keys():
		var sid: String = str(k)
		var entry: Variant = slots[k]
		var modified: int = 0
		if entry is Dictionary:
			modified = int((entry as Dictionary).get("modified_unix", 0))
		pairs.append({"id": sid, "t": modified})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["t"]) > int(b["t"])
	)
	var out: PackedStringArray = PackedStringArray()
	for p in pairs:
		out.append(str((p as Dictionary)["id"]))
	return out


func get_slot_entry(slot_id: String) -> Dictionary:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	var e: Variant = slots.get(slot_id, {})
	return e.duplicate(true) if e is Dictionary else {}


func set_slot_display_name(slot_id: String, display_name: String) -> bool:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	if not slots.has(slot_id):
		return false
	var entry: Dictionary = slots[slot_id] as Dictionary
	entry["display_name"] = display_name.strip_edges()
	if str(entry["display_name"]).is_empty():
		entry["display_name"] = _default_display_name_for_new_slot(root)
	entry["modified_unix"] = int(Time.get_unix_time_from_system())
	slots[slot_id] = entry
	root[KEY_RUN_SLOTS] = slots
	return save_save_data(root)


func create_slot(p_display_name: String = "") -> String:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	var slot_id: String = _alloc_slot_id(root)
	var name: String = p_display_name.strip_edges()
	if name.is_empty():
		name = _default_display_name_for_new_slot(root)
	var unix: int = int(Time.get_unix_time_from_system())
	slots[slot_id] = {
		"display_name": name,
		"created_unix": unix,
		"modified_unix": unix,
		"play_time_sec": 0,
		"run": {},
	}
	root[KEY_RUN_SLOTS] = slots
	root[KEY_LAST_PLAYED_SLOT_ID] = slot_id
	active_save_slot_id = slot_id
	save_save_data(root)
	return slot_id


func delete_slot(slot_id: String) -> bool:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	if not slots.has(slot_id):
		return false
	slots.erase(slot_id)
	root[KEY_RUN_SLOTS] = slots
	if str(root.get(KEY_LAST_PLAYED_SLOT_ID, "")) == slot_id:
		root[KEY_LAST_PLAYED_SLOT_ID] = ""
	if active_save_slot_id == slot_id:
		active_save_slot_id = ""
	return save_save_data(root)


func _run_snapshot_nonempty(run: Dictionary) -> bool:
	if run.is_empty():
		return false
	return int(run.get("version", 0)) > 0


func save_run_to_slot(slot_id: String, data: Dictionary, add_play_sec: float) -> bool:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	if not slots.has(slot_id):
		return false
	var entry: Dictionary = (slots[slot_id] as Dictionary).duplicate(true)
	var prev_pt: int = int(entry.get("play_time_sec", 0))
	var add: int = int(floorf(maxf(0.0, add_play_sec)))
	entry["play_time_sec"] = prev_pt + add
	entry["modified_unix"] = int(Time.get_unix_time_from_system())
	entry["run"] = data.duplicate(true)
	slots[slot_id] = entry
	root[KEY_RUN_SLOTS] = slots
	root[KEY_LAST_PLAYED_SLOT_ID] = slot_id
	return save_save_data(root)


func load_run_from_slot(slot_id: String) -> Dictionary:
	var entry: Dictionary = get_slot_entry(slot_id)
	var run: Variant = entry.get("run", {})
	return run.duplicate(true) if run is Dictionary else {}


func clear_run_in_slot(slot_id: String) -> void:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	if not slots.has(slot_id):
		return
	var entry: Dictionary = (slots[slot_id] as Dictionary).duplicate(true)
	entry["run"] = {}
	entry["modified_unix"] = int(Time.get_unix_time_from_system())
	slots[slot_id] = entry
	root[KEY_RUN_SLOTS] = slots
	save_save_data(root)


func get_last_played_slot_id() -> String:
	var root: Dictionary = load_save_data()
	return str(root.get(KEY_LAST_PLAYED_SLOT_ID, ""))


func set_last_played_slot_id(slot_id: String) -> void:
	var root: Dictionary = load_save_data()
	root[KEY_LAST_PLAYED_SLOT_ID] = slot_id
	save_save_data(root)


func find_first_slot_with_run() -> String:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	for sid in slots.keys():
		var entry: Variant = slots[sid]
		if entry is Dictionary:
			var run: Variant = (entry as Dictionary).get("run", {})
			if run is Dictionary and _run_snapshot_nonempty(run as Dictionary):
				return str(sid)
	return ""


func slot_has_resumable_run(slot_id: String) -> bool:
	if slot_id.is_empty():
		return false
	return _run_snapshot_nonempty(load_run_from_slot(slot_id))


func load_meta_progress() -> Dictionary:
	var root: Dictionary = load_save_data()
	var mp: Variant = root.get("meta_progress", {})
	var meta: Dictionary = mp as Dictionary if mp is Dictionary else {}
	_ensure_meta_progress_defaults(meta)
	return meta


func _ensure_meta_progress_defaults(meta: Dictionary) -> void:
	if not meta.has(KEY_WALLET_GOLD):
		meta[KEY_WALLET_GOLD] = 0
	if not meta.has(KEY_PURCHASED_CHARACTER_IDS):
		meta[KEY_PURCHASED_CHARACTER_IDS] = ["default"]
		return
	var raw_ids: Variant = meta[KEY_PURCHASED_CHARACTER_IDS]
	if raw_ids is Array:
		var arr: Array = raw_ids as Array
		var has_default: bool = false
		for x in arr:
			if str(x) == "default":
				has_default = true
				break
		if not has_default:
			arr.insert(0, "default")


func get_wallet_gold() -> int:
	return int(load_meta_progress().get(KEY_WALLET_GOLD, 0))


func has_purchased_character(character_id: String) -> bool:
	var raw_ids: Variant = load_meta_progress().get(KEY_PURCHASED_CHARACTER_IDS, [])
	if not raw_ids is Array:
		return false
	for x in raw_ids as Array:
		if str(x) == character_id:
			return true
	return false


func add_purchased_character(character_id: String) -> void:
	if character_id.is_empty():
		return
	var meta: Dictionary = load_meta_progress()
	var arr: Array = meta.get(KEY_PURCHASED_CHARACTER_IDS, []) as Array
	if not arr is Array:
		arr = []
	var found: bool = false
	for x in arr:
		if str(x) == character_id:
			found = true
			break
	if not found:
		arr.append(character_id)
	meta[KEY_PURCHASED_CHARACTER_IDS] = arr
	save_meta_progress(meta)


func bank_run_gold_to_wallet(amount: int) -> void:
	if amount <= 0:
		return
	var meta: Dictionary = load_meta_progress()
	var w: int = int(meta.get(KEY_WALLET_GOLD, 0))
	meta[KEY_WALLET_GOLD] = w + amount
	save_meta_progress(meta)


func try_wallet_purchase_character(character_id: String, price: int) -> bool:
	if character_id.is_empty():
		return false
	var meta: Dictionary = load_meta_progress()
	var arr: Array = meta.get(KEY_PURCHASED_CHARACTER_IDS, []) as Array
	if not arr is Array:
		arr = []
	for x in arr:
		if str(x) == character_id:
			return true
	if price <= 0:
		arr.append(character_id)
		meta[KEY_PURCHASED_CHARACTER_IDS] = arr
		save_meta_progress(meta)
		return true
	var w: int = int(meta.get(KEY_WALLET_GOLD, 0))
	if w < price:
		return false
	meta[KEY_WALLET_GOLD] = w - price
	arr.append(character_id)
	meta[KEY_PURCHASED_CHARACTER_IDS] = arr
	save_meta_progress(meta)
	return true


func save_meta_progress(meta: Dictionary) -> void:
	var root: Dictionary = load_save_data()
	root["meta_progress"] = meta
	save_save_data(root)


func record_run_finished(wave_reached: int, is_victory: bool) -> void:
	var meta: Dictionary = load_meta_progress()
	var best: int = int(meta.get("best_wave", 0))
	if wave_reached > best:
		meta["best_wave"] = wave_reached
	meta["runs"] = int(meta.get("runs", 0)) + 1
	if is_victory:
		meta["victories"] = int(meta.get("victories", 0)) + 1
	save_meta_progress(meta)


func save_pending_run(data: Dictionary) -> bool:
	if active_save_slot_id.is_empty():
		var root_legacy: Dictionary = load_save_data()
		root_legacy[KEY_PENDING_RUN] = data
		return save_save_data(root_legacy)
	return save_run_to_slot(active_save_slot_id, data, RunState.consume_session_play_for_save())


func load_pending_run() -> Dictionary:
	if not active_save_slot_id.is_empty():
		return load_run_from_slot(active_save_slot_id)
	var root: Dictionary = load_save_data()
	var p: Variant = root.get(KEY_PENDING_RUN, {})
	return p.duplicate(true) if p is Dictionary else {}


func clear_pending_run() -> void:
	if not active_save_slot_id.is_empty():
		clear_run_in_slot(active_save_slot_id)
		return
	var root: Dictionary = load_save_data()
	root.erase(KEY_PENDING_RUN)
	save_save_data(root)


func has_pending_run() -> bool:
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	for k in slots.keys():
		var entry: Variant = slots[k]
		if entry is Dictionary:
			var run: Variant = (entry as Dictionary).get("run", {})
			if run is Dictionary and _run_snapshot_nonempty(run as Dictionary):
				return true
	var p: Variant = root.get(KEY_PENDING_RUN, {})
	return p is Dictionary and _run_snapshot_nonempty(p as Dictionary)


func get_pending_run_summary() -> Dictionary:
	var sid: String = get_last_played_slot_id()
	if not sid.is_empty():
		var run: Dictionary = load_run_from_slot(sid)
		if not run.is_empty():
			return _summary_from_run_dict(run)
	sid = find_first_slot_with_run()
	if not sid.is_empty():
		return _summary_from_run_dict(load_run_from_slot(sid))
	var legacy: Dictionary = load_save_data()
	var p: Variant = legacy.get(KEY_PENDING_RUN, {})
	if p is Dictionary:
		return _summary_from_run_dict(p as Dictionary)
	return {}


func _summary_from_run_dict(pr: Dictionary) -> Dictionary:
	var rs: Variant = pr.get("run_state", {})
	if rs is Dictionary:
		var d: Dictionary = rs as Dictionary
		var raw_wave: int = int(d.get("wave_index", 0))
		var safe_wave: int = clampi(raw_wave, 0, 999999)
		var raw_character_id: String = str(d.get("character_id", "default"))
		var safe_character_id: String = raw_character_id.strip_edges()
		if safe_character_id.is_empty():
			safe_character_id = "default"
		if safe_character_id.length() > MAX_CHARACTER_ID_LENGTH:
			safe_character_id = safe_character_id.substr(0, MAX_CHARACTER_ID_LENGTH)
		return {
			"wave_index": safe_wave,
			"character_id": safe_character_id,
		}
	return {}


func delete_all_run_saves() -> bool:
	var root: Dictionary = load_save_data()
	root[KEY_RUN_SLOTS] = {}
	root[KEY_LAST_PLAYED_SLOT_ID] = ""
	root.erase(KEY_PENDING_RUN)
	active_save_slot_id = ""
	return save_save_data(root)


func reset_meta_progress_to_default() -> void:
	var meta: Dictionary = {}
	_ensure_meta_progress_defaults(meta)
	save_meta_progress(meta)


func delete_user_progress_and_settings() -> bool:
	var ok_settings: bool = GameSettings.clear_all_settings_data()
	reset_meta_progress_to_default()
	var root: Dictionary = load_save_data()
	root[KEY_TUTORIAL_COMPLETED] = false
	save_save_data(root)
	return ok_settings


func delete_all_save_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var abs_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	var err: Error = DirAccess.remove_absolute(abs_path)
	if err == OK:
		active_save_slot_id = ""
		return true
	active_save_slot_id = ""
	return save_save_data({})


func get_tutorial_completed() -> bool:
	var root: Dictionary = load_save_data()
	return bool(root.get(KEY_TUTORIAL_COMPLETED, false))


func set_tutorial_completed(value: bool) -> void:
	var root: Dictionary = load_save_data()
	root[KEY_TUTORIAL_COMPLETED] = value
	save_save_data(root)


func get_slot_play_time_sec(slot_id: String) -> int:
	var e: Dictionary = get_slot_entry(slot_id)
	return int(e.get("play_time_sec", 0))


func add_play_time_to_slot(slot_id: String, add_sec: float) -> void:
	if slot_id.is_empty():
		return
	var add: int = int(floorf(maxf(0.0, add_sec)))
	if add <= 0:
		return
	var root: Dictionary = load_save_data()
	var slots: Dictionary = _ensure_run_slots(root)
	if not slots.has(slot_id):
		return
	var entry: Dictionary = (slots[slot_id] as Dictionary).duplicate(true)
	var prev: int = int(entry.get("play_time_sec", 0))
	entry["play_time_sec"] = prev + add
	entry["modified_unix"] = int(Time.get_unix_time_from_system())
	slots[slot_id] = entry
	root[KEY_RUN_SLOTS] = slots
	save_save_data(root)
