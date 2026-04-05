extends RefCounted
class_name CharacterData

const PATH: String = "res://data/characters.json"


static func load_config() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		push_warning("CharacterData: 未找到 %s" % PATH)
		return {}
	var text: String = FileAccess.get_file_as_string(PATH)
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		push_error("CharacterData: JSON 解析失败")
		return {}
	var data: Variant = json.data
	return data as Dictionary if data is Dictionary else {}


static func list_characters() -> Array:
	var cfg: Dictionary = load_config()
	var arr: Array = cfg.get("characters", []) as Array
	if arr.is_empty():
		return [_builtin_default()]
	return arr


static func is_character_unlocked(d: Dictionary) -> bool:
	var req: int = int(d.get("unlock_wave", 0))
	if req <= 0:
		return true
	var meta: Dictionary = SaveManager.load_meta_progress()
	return int(meta.get("best_wave", 0)) >= req


static func find_character(character_id: String) -> Dictionary:
	for c in list_characters():
		if c is Dictionary and str((c as Dictionary).get("id", "")) == character_id:
			return c as Dictionary
	var fb: Array = list_characters()
	if fb.size() > 0 and fb[0] is Dictionary:
		return fb[0] as Dictionary
	return _builtin_default()


static func apply_to_player(player: Node, character_id: String) -> void:
	var d: Dictionary = find_character(character_id)
	var hp: int = int(d.get("max_hp", 100))
	var sm: float = float(d.get("speed_mult", 1.0))
	var dm: float = float(d.get("damage_mult", 1.0))
	player.max_hp = hp
	player.current_hp = hp
	player.stat_move_speed_mult *= sm
	player.stat_damage_mult *= dm
	player.emit_signal("hp_changed", player.current_hp, player.max_hp)


static func _builtin_default() -> Dictionary:
	return {
		"id": "default",
		"display_name": "标准野猪",
		"description": "",
		"max_hp": 100,
		"speed_mult": 1.0,
		"damage_mult": 1.0,
	}
