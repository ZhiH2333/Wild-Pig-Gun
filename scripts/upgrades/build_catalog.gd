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


static func _upgrade_stackable(def: Dictionary) -> bool:
	return bool(def.get("stackable", true))


static func _pool_has_upgrade_id(pool: Array[Dictionary], upgrade_id: String) -> bool:
	for x in pool:
		if str(x.get("id", "")) == upgrade_id:
			return true
	return false


static func all_upgrade_defs() -> Array[Dictionary]:
	var loaded: Array = _load_dict_array_from_file(UPGRADES_JSON)
	if not loaded.is_empty():
		return _to_typed_dict_array(loaded)
	return [
		{"id": "vitality_s", "rarity": 1, "title": "强壮 I", "desc": "最大生命 +15", "kind": "max_hp", "value": 15},
		{"id": "swift", "rarity": 2, "title": "敏捷", "desc": "移速 +10%", "kind": "move_pct", "value": 0.10},
	]


static func _filter_upgrade_pool(taken_ids: Array[String]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for d in all_upgrade_defs():
		var id: String = str(d.get("id", ""))
		if id.is_empty():
			continue
		if id in taken_ids and not _upgrade_stackable(d):
			continue
		pool.append(d)
	return pool


static func _upgrade_pick_weight(def: Dictionary, wave_index: int, luck: int) -> float:
	var r: int = clampi(_upgrade_rarity(def), 1, 3)
	var tier_w: Array[float] = [5.5, 3.2, 1.6]
	var w: float = tier_w[r - 1]
	w *= 1.0 + float(mini(wave_index, 18)) * 0.035
	w += float(maxi(0, luck)) * 0.07
	if r >= 3 and wave_index >= 10:
		w *= 1.22
	return maxf(0.05, w)


static func _pick_weighted_upgrades(
	count: int,
	pool: Array[Dictionary],
	rng: RandomNumberGenerator,
	wave_index: int,
	luck: int
) -> Array[Dictionary]:
	var src: Array[Dictionary] = pool.duplicate()
	var out: Array[Dictionary] = []
	while out.size() < count and src.size() > 0:
		var total: float = 0.0
		var weights: Array[float] = []
		for d in src:
			var wt: float = _upgrade_pick_weight(d, wave_index, luck)
			weights.append(wt)
			total += wt
		var roll: float = rng.randf() * total
		var acc: float = 0.0
		var pick_i: int = 0
		for i in range(src.size()):
			acc += weights[i]
			if roll <= acc:
				pick_i = i
				break
		out.append(src[pick_i])
		src.remove_at(pick_i)
	return out


## 波间三选一：加权随机；不可叠加且已选过的 id 不再出现
static func pick_random_upgrades(
	count: int,
	taken_ids: Array[String],
	rng: RandomNumberGenerator,
	wave_index: int = 1,
	luck: int = 0
) -> Array[Dictionary]:
	var pool: Array[Dictionary] = _filter_upgrade_pool(taken_ids)
	if pool.size() < count:
		for d in all_upgrade_defs():
			var id: String = str(d.get("id", ""))
			if _pool_has_upgrade_id(pool, id):
				continue
			if id in taken_ids and not _upgrade_stackable(d):
				continue
			pool.append(d)
	if pool.is_empty():
		pool = all_upgrade_defs()
	return _pick_weighted_upgrades(count, pool, rng, wave_index, luck)


## 升级：按最低稀有度筛选（用于局内等级提升）
static func pick_level_upgrades(
	count: int,
	taken_ids: Array[String],
	rng: RandomNumberGenerator,
	new_level: int,
	wave_index: int = 1,
	luck: int = 0
) -> Array[Dictionary]:
	var min_r: int = 1
	if new_level >= 25:
		min_r = 3
	elif new_level == 5 or new_level == 10 or new_level == 15 or new_level == 20:
		min_r = 2
	var pool: Array[Dictionary] = []
	for d in _filter_upgrade_pool(taken_ids):
		if _upgrade_rarity(d) < min_r:
			continue
		pool.append(d)
	if pool.size() < count:
		for d in all_upgrade_defs():
			var id2: String = str(d.get("id", ""))
			if id2 in taken_ids and not _upgrade_stackable(d):
				continue
			if _upgrade_rarity(d) < min_r:
				continue
			if not _pool_has_upgrade_id(pool, id2):
				pool.append(d)
	if pool.size() < count:
		for d in all_upgrade_defs():
			var id3: String = str(d.get("id", ""))
			if id3 in taken_ids and not _upgrade_stackable(d):
				continue
			if not _pool_has_upgrade_id(pool, id3):
				pool.append(d)
	if pool.is_empty():
		pool = all_upgrade_defs()
	return _pick_weighted_upgrades(count, pool, rng, wave_index, luck)


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
		"dmg_for_hp":
			if value is Dictionary:
				var dd: Dictionary = value as Dictionary
				player.stat_damage_mult *= 1.0 + float(dd.get("dmg", 0.0))
				if player.has_method("penalties_max_hp"):
					player.penalties_max_hp(int(dd.get("hp", 0)))
		"fire_for_move":
			if value is Dictionary:
				var dd2: Dictionary = value as Dictionary
				player.stat_fire_rate_mult *= 1.0 + float(dd2.get("fire", 0.0))
				player.stat_move_speed_mult *= 1.0 + float(dd2.get("move", 0.0))
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
