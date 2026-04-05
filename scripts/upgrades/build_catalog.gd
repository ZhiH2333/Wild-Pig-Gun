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


static func _upgrade_rarity(def: Dictionary) -> int:
	return maxi(1, int(def.get("rarity", 1)))


static func all_upgrade_defs() -> Array[Dictionary]:
	var loaded: Array = _load_dict_array_from_file(UPGRADES_JSON)
	if not loaded.is_empty():
		return _to_typed_dict_array(loaded)
	return [
		{"id": "vitality_s", "rarity": 1, "title": "强壮 I", "desc": "最大生命 +15", "kind": "max_hp", "value": 15},
		{"id": "swift", "rarity": 2, "title": "敏捷", "desc": "移速 +10%", "kind": "move_pct", "value": 0.10},
	]


## 波间三选一：不筛选稀有度（任意稀有度可出）
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


## 升级：按最低稀有度筛选（用于局内等级提升）
static func pick_level_upgrades(
	count: int,
	taken_ids: Array[String],
	rng: RandomNumberGenerator,
	new_level: int
) -> Array[Dictionary]:
	var min_r: int = 1
	if new_level >= 25:
		min_r = 3
	elif new_level == 5 or new_level == 10 or new_level == 15 or new_level == 20:
		min_r = 2
	var pool: Array[Dictionary] = []
	for d in all_upgrade_defs():
		var id: String = d["id"] as String
		if id in taken_ids:
			continue
		if _upgrade_rarity(d) < min_r:
			continue
		pool.append(d)
	if pool.size() < count:
		for d in all_upgrade_defs():
			var id2: String = d["id"] as String
			if id2 in taken_ids:
				continue
			if d not in pool:
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
		"combo_hp_dmg_big":
			player.add_max_hp(value as int)
			player.stat_damage_mult *= 1.15
		"luck_flat":
			if "stat_luck" in player:
				player.stat_luck += int(value)
		"harvest_flat":
			if "stat_harvest" in player:
				player.stat_harvest += float(value)
		"add_weapon":
			var wid: String = str(value)
			var lo: Node = player.get_node_or_null("WeaponLoadout")
			if lo != null and lo.has_method("add_weapon_slot_by_id"):
				lo.add_weapon_slot_by_id(wid)


static func get_shop_base_price(def: Dictionary) -> int:
	if def.has("base_price"):
		return int(def["base_price"])
	return int(def.get("price", 5))


static func get_shop_tier(def: Dictionary) -> int:
	return clampi(int(def.get("tier", 1)), 1, 3)


static func effective_shop_price(def: Dictionary, wave_index: int, player: Node) -> int:
	var base: int = get_shop_base_price(def)
	var scaled: int = WaveData.shop_price_scaled(base, wave_index)
	if player != null and "shop_price_mult" in player:
		var m: float = float(player.shop_price_mult)
		if m > 0.001:
			scaled = maxi(1, int(round(float(scaled) * m)))
	return scaled


## 幸运提高高 tier 权重；不放回加权抽样
static func pick_shop_offer(count: int, rng: RandomNumberGenerator, luck: int) -> Array[Dictionary]:
	var src: Array[Dictionary] = []
	for d in default_shop_items():
		src.append(d)
	var out: Array[Dictionary] = []
	var lf: float = maxf(0.0, float(luck))
	while out.size() < count and src.size() > 0:
		var total_w: float = 0.0
		var weights: Array[float] = []
		for item in src:
			var tier: int = get_shop_tier(item)
			var w: float = 1.0 + lf * 0.12 * float(tier)
			weights.append(w)
			total_w += w
		var r: float = rng.randf() * total_w
		var acc: float = 0.0
		var pick_i: int = 0
		for i in range(src.size()):
			acc += weights[i]
			if r <= acc:
				pick_i = i
				break
		out.append(src[pick_i])
		src.remove_at(pick_i)
	return out


static func default_shop_items() -> Array[Dictionary]:
	var loaded: Array = _load_dict_array_from_file(SHOP_JSON)
	if not loaded.is_empty():
		return _to_typed_dict_array(loaded)
	return [
		{"id": "shop_heal", "title": "治疗包", "base_price": 5, "tier": 1, "kind": "heal_flat", "value": 22},
	]


static func apply_shop_def(player: Node, def: Dictionary) -> void:
	var kind: String = str(def.get("kind", ""))
	if kind == "add_weapon":
		apply_upgrade_def(player, def)
		return
	apply_upgrade_def(player, {
		"kind": def["kind"],
		"value": def["value"],
	})
