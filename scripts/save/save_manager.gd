extends Node

const SAVE_PATH: String = "user://wild_pig_gun_save.json"

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
