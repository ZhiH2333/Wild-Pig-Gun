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
