extends RefCounted
class_name WeaponCatalog

const PATH: String = "res://data/weapons.json"


static func load_defs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(PATH):
		return _fallback()
	var txt: String = FileAccess.get_file_as_string(PATH)
	var p: JSON = JSON.new()
	if p.parse(txt) != OK:
		return _fallback()
	var root: Variant = p.data
	if root is Array:
		for item in root:
			if item is Dictionary:
				out.append(item as Dictionary)
	if out.is_empty():
		return _fallback()
	return out


static func _fallback() -> Array[Dictionary]:
	return [
		{"id": "rifle", "tags": ["heavy"], "kind": "projectile", "damage": 10, "fire_interval": 0.5},
		{"id": "smg", "tags": ["light"], "kind": "projectile", "damage": 6, "fire_interval": 0.32},
	]


static func find_def(weapon_id: String) -> Dictionary:
	for d in load_defs():
		if str(d.get("id", "")) == weapon_id:
			return d
	var fb: Array[Dictionary] = load_defs()
	return fb[0] if fb.size() > 0 else {}


static func tags_for(weapon_id: String) -> Array[String]:
	var d: Dictionary = find_def(weapon_id)
	var raw: Variant = d.get("tags", [])
	var out: Array[String] = []
	if raw is Array:
		for x in raw:
			out.append(str(x))
	return out
