extends RefCounted
class_name BuildCatalog

const UPGRADES_JSON: String = "res://data/upgrades.json"
const SHOP_JSON: String = "res://data/shop_items.json"


static func _load_dict_array_from_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var txt: String = FileAccess.get_file_as_string(path)
	var parser: JSON = JSON.new()
	if parser.parse(txt) != OK:
		push_error("BuildCatalog: JSON 解析失败 %s" % path)
		return []
	var root: Variant = parser.data
	var out: Array = []
	if root is Array:
		for item in root:
			if item is Dictionary:
				out.append(item)
	return out


static func _to_typed_dict_array(raw: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in raw:
		if item is Dictionary:
			out.append(item as Dictionary)
	return out


## 局内升级池；优先 data/upgrades.json
static func all_upgrade_defs() -> Array[Dictionary]:
	var loaded: Array = _load_dict_array_from_file(UPGRADES_JSON)
	if not loaded.is_empty():
		return _to_typed_dict_array(loaded)
	return [
		{"id": "vitality_s", "title": "强壮 I", "desc": "最大生命 +15", "kind": "max_hp", "value": 15},
		{"id": "vitality_m", "title": "强壮 II", "desc": "最大生命 +25", "kind": "max_hp", "value": 25},
		{"id": "swift", "title": "敏捷", "desc": "移速 +10%", "kind": "move_pct", "value": 0.10},
		{"id": "power", "title": "重击", "desc": "伤害 +12%", "kind": "damage_pct", "value": 0.12},
		{"id": "fury", "title": "狂怒", "desc": "攻速 +12%", "kind": "fire_pct", "value": 0.12},
		{"id": "magnet", "title": "磁石", "desc": "拾取范围 +24", "kind": "pickup", "value": 24.0},
		{"id": "mend", "title": "愈合", "desc": "立即回复 35 生命", "kind": "heal_flat", "value": 35},
		{"id": "iron", "title": "铁躯", "desc": "最大生命 +18，伤害 +6%", "kind": "combo_hp_dmg", "value": 18},
	]


static func pick_random_upgrades(count: int, taken_ids: Array[String], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for d in all_upgrade_defs():
		var id: String = d["id"] as String
		if id in taken_ids:
			continue
		pool.append(d)
	if pool.is_empty():
		for d in all_upgrade_defs():
			pool.append(d)
	var out: Array[Dictionary] = []
	while out.size() < count and pool.size() > 0:
		var idx: int = rng.randi_range(0, pool.size() - 1)
		out.append(pool[idx])
		pool.remove_at(idx)
	return out


static func apply_upgrade_def(player: Node, def: Dictionary) -> void:
	var kind: String = def["kind"] as String
	var value = def["value"]
	match kind:
		"max_hp":
			player.add_max_hp(value as int)
		"move_pct":
			player.stat_move_speed_mult *= 1.0 + (value as float)
		"damage_pct":
			player.stat_damage_mult *= 1.0 + (value as float)
		"fire_pct":
			player.stat_fire_rate_mult *= 1.0 + (value as float)
		"pickup":
			player.stat_pickup_radius_bonus += value as float
		"heal_flat":
			player.heal_flat(value as int)
		"combo_hp_dmg":
			player.add_max_hp(value as int)
			player.stat_damage_mult *= 1.06


## 商店池；优先 data/shop_items.json
static func default_shop_items() -> Array[Dictionary]:
	var loaded: Array = _load_dict_array_from_file(SHOP_JSON)
	if not loaded.is_empty():
		return _to_typed_dict_array(loaded)
	return [
		{"id": "shop_heal", "title": "治疗包", "desc": "回复 22 生命", "price": 5, "kind": "heal_flat", "value": 22},
		{"id": "shop_hp5", "title": "体能训练", "desc": "最大生命 +8", "price": 8, "kind": "max_hp", "value": 8},
		{"id": "shop_dmg", "title": "磨刀石", "desc": "伤害 +8%", "price": 12, "kind": "damage_pct", "value": 0.08},
		{"id": "shop_move", "title": "轻靴", "desc": "移速 +6%", "price": 10, "kind": "move_pct", "value": 0.06},
		{"id": "shop_fire", "title": "扳机簧", "desc": "攻速 +8%", "price": 11, "kind": "fire_pct", "value": 0.08},
		{"id": "shop_mag", "title": "小磁石", "desc": "拾取范围 +18", "price": 7, "kind": "pickup", "value": 18.0},
	]


static func pick_shop_offer(count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var src: Array[Dictionary] = []
	for d in default_shop_items():
		src.append(d)
	var out: Array[Dictionary] = []
	while out.size() < count and src.size() > 0:
		var idx: int = rng.randi_range(0, src.size() - 1)
		out.append(src[idx])
		src.remove_at(idx)
	return out


static func apply_shop_def(player: Node, def: Dictionary) -> void:
	apply_upgrade_def(player, {
		"kind": def["kind"],
		"value": def["value"],
	})
