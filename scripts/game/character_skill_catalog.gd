extends RefCounted
class_name CharacterSkillCatalog

const SKILLS_JSON: String = "res://data/character_skills.json"

static var _defs: Array[Dictionary] = []
static var _loaded: bool = false


static func _load_defs() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SKILLS_JSON):
		return
	var txt: String = FileAccess.get_file_as_string(SKILLS_JSON)
	var p: JSON = JSON.new()
	if p.parse(txt) != OK:
		push_error("CharacterSkillCatalog: JSON 解析失败")
		return
	var root: Variant = p.data
	if root is Array:
		for item in root:
			if item is Dictionary:
				_defs.append(item as Dictionary)


static func all_defs() -> Array[Dictionary]:
	_load_defs()
	return _defs


static func defs_for_character(character_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in all_defs():
		if str(d.get("character_id", "")) == character_id:
			out.append(d)
	return out


static func active_defs_sorted(character_id: String) -> Array[Dictionary]:
	var actives: Array[Dictionary] = []
	for d in defs_for_character(character_id):
		if str(d.get("kind", "")) == "active":
			actives.append(d)
	actives.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	return actives


static func passive_defs(character_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in defs_for_character(character_id):
		if str(d.get("kind", "")) == "passive":
			out.append(d)
	return out
