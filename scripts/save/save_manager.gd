extends Node

const SAVE_PATH: String = "user://wild_pig_gun_save.json"
const KEY_PENDING_RUN: String = "pending_run"
const KEY_TUTORIAL_COMPLETED: String = "tutorial_completed"
const KEY_WALLET_GOLD: String = "wallet_gold"
const KEY_PURCHASED_CHARACTER_IDS: String = "purchased_character_ids"
const MAX_CHARACTER_ID_LENGTH: int = 48

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
	return data as Dictionary if data is Dictionary else {}

func save_save_data(data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_text)
	return true


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


## 局内野猪币并入野猪钱包（结算时调用）
func bank_run_gold_to_wallet(amount: int) -> void:
	if amount <= 0:
		return
	var meta: Dictionary = load_meta_progress()
	var w: int = int(meta.get(KEY_WALLET_GOLD, 0))
	meta[KEY_WALLET_GOLD] = w + amount
	save_meta_progress(meta)


## 购买角色：扣款并写入已购列表；已拥有则直接成功
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
	var root: Dictionary = load_save_data()
	root[KEY_PENDING_RUN] = data
	return save_save_data(root)


func load_pending_run() -> Dictionary:
	var root: Dictionary = load_save_data()
	var p: Variant = root.get(KEY_PENDING_RUN, {})
	return p as Dictionary if p is Dictionary else {}


func clear_pending_run() -> void:
	var root: Dictionary = load_save_data()
	root.erase(KEY_PENDING_RUN)
	save_save_data(root)


func has_pending_run() -> bool:
	return not load_pending_run().is_empty()


func get_pending_run_summary() -> Dictionary:
	var pr: Dictionary = load_pending_run()
	if pr.is_empty():
		return {}
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


func delete_all_save_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var abs_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	var err: Error = DirAccess.remove_absolute(abs_path)
	if err == OK:
		return true
	return save_save_data({})


func get_tutorial_completed() -> bool:
	var root: Dictionary = load_save_data()
	return bool(root.get(KEY_TUTORIAL_COMPLETED, false))


func set_tutorial_completed(value: bool) -> void:
	var root: Dictionary = load_save_data()
	root[KEY_TUTORIAL_COMPLETED] = value
	save_save_data(root)
