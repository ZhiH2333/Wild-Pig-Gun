extends Node

const SAVE_PATH: String = "user://wild_pig_gun_save.json"
const KEY_PENDING_RUN: String = "pending_run"

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
	return mp as Dictionary if mp is Dictionary else {}


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
		return {
			"wave_index": int(d.get("wave_index", 0)),
			"character_id": str(d.get("character_id", "default")),
		}
	return {}
