extends RefCounted
class_name WeaponCatalog

const PATH: String = "res://data/weapons.json"
const DEFAULT_STARTER_WEAPON_ID: String = "crude_pistol"
## 与策划案「初始武器」页顺序一致（野猪乱打手枪设计文档）
## 使用 Array 字面量：PackedStringArray(...) 非 const 折叠，部分版本会报 Parser Error
const STARTER_WEAPON_IDS: Array[String] = [
	"crude_pistol",
	"wild_shotgun",
	"spin_revolver",
	"electric_gun",
	"feather_bow",
	"fire_snout",
	"magnetic_cannon",
	"frost_sprayer",
	"boar_grenade",
	"crescent_blade",
	"trotter_flurry",
	"sniper_chicken",
]


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


## 开局可选的 12 把初始武器（不含商店追加武器）
static func list_starter_defs_ordered() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for d in load_defs():
		if not bool(d.get("starter", false)):
			continue
		var wid: String = str(d.get("id", ""))
		if wid.is_empty():
			continue
		by_id[wid] = d
	var out: Array[Dictionary] = []
	for sid in STARTER_WEAPON_IDS:
		if by_id.has(sid):
			out.append(by_id[sid] as Dictionary)
	return out


static func is_starter_weapon_id(weapon_id: String) -> bool:
	for d in load_defs():
		if str(d.get("id", "")) != weapon_id:
			continue
		return bool(d.get("starter", false))
	return false


static func _fallback() -> Array[Dictionary]:
	return [
		{
			"id": DEFAULT_STARTER_WEAPON_ID,
			"display_name": "土炮手枪",
			"starter": true,
			"tags": ["light"],
			"kind": "projectile",
			"damage": 9,
			"fire_interval": 0.4,
			"pierce": 0,
			"element": "physical",
			"short_desc": "均衡",
		},
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
