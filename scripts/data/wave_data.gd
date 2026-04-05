extends RefCounted
class_name WaveData

const CONFIG_PATH: String = "res://data/waves.json"


static func load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("WaveData: 未找到 %s，使用内置波次逻辑" % CONFIG_PATH)
		return {}
	var text: String = FileAccess.get_file_as_string(CONFIG_PATH)
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_error("WaveData: JSON 解析失败，使用内置波次逻辑")
		return {}
	var data: Variant = json.data
	return data as Dictionary if data is Dictionary else {}


static func get_wave_entry(config: Dictionary, wave_index: int) -> Dictionary:
	var waves: Array = config.get("waves", []) as Array
	for wv in waves:
		if wv is Dictionary and int((wv as Dictionary).get("wave", -1)) == wave_index:
			return wv as Dictionary
	return {}


static func get_scaling(config: Dictionary) -> Dictionary:
	var s: Variant = config.get("scaling", {})
	if s is Dictionary:
		return s as Dictionary
	return {"hp_per_wave": 0.08, "damage_per_wave": 0.05}
