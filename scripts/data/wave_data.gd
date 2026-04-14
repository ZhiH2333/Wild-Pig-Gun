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


static func get_wave_duration_sec(config: Dictionary, wave_index: int) -> float:
	var e: Dictionary = get_wave_entry(config, wave_index)
	if e.has("duration_sec"):
		return float(e["duration_sec"])
	var base_d: float = 30.0 + float(wave_index) * 1.5
	return minf(base_d, 60.0)


static func list_modifiers(entry: Dictionary) -> Array:
	var m: Variant = entry.get("modifiers", [])
	return m as Array if m is Array else []


static func has_modifier(entry: Dictionary, mod_name: String) -> bool:
	for x in list_modifiers(entry):
		if str(x) == mod_name:
			return true
	return false


static func get_boss_type(config: Dictionary, wave_index: int) -> String:
	var e: Dictionary = get_wave_entry(config, wave_index)
	if e.has("boss_type"):
		return str(e["boss_type"])
	return ""


static func get_effective_batch_cap(config: Dictionary, wave_index: int) -> int:
	if not get_boss_type(config, wave_index).is_empty():
		return 0
	var e: Dictionary = get_wave_entry(config, wave_index)
	var cap: int
	if e.has("batch_cap"):
		cap = clampi(int(e["batch_cap"]), 1, 8)
	else:
		cap = mini(1 + int(wave_index * 0.5), 5)
	if has_modifier(e, "cluster"):
		cap = clampi(int(round(float(cap) * 1.7)), cap + 1, 10)
	return cap


## elite_focus：更早、更频繁检测精英，并提高基础概率
static func get_elite_focus_settings(config: Dictionary, wave_index: int) -> Dictionary:
	var e: Dictionary = get_wave_entry(config, wave_index)
	if not has_modifier(e, "elite_focus"):
		return {"active": false, "interval": 15.0, "chance_bonus": 0.0}
	return {"active": true, "interval": 5.5, "chance_bonus": 0.32}


## 商店标价随波次上涨（简化的 Brotato 式曲线）
static func shop_price_scaled(base_price: int, wave_index: int) -> int:
	var w: int = maxi(1, wave_index)
	var mult: float = 1.0 + 0.08 * float(w)
	return maxi(1, int(floor(float(base_price) * mult + float(w) * 0.35)))
