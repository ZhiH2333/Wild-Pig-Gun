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
		"crit_chance_flat":
			if "stat_crit_chance" in player:
				player.stat_crit_chance = clampf(float(player.stat_crit_chance) + float(value), 0.0, 1.0)
		"crit_mult_flat":
			if "stat_crit_mult" in player:
				player.stat_crit_mult = maxf(1.0, float(player.stat_crit_mult) + float(value))
		"fire_damage_pct":
			if "stat_fire_damage_mult" in player:
				player.stat_fire_damage_mult *= 1.0 + float(value)
		"burn_dps_flat":
			if "stat_burn_dps_flat" in player:
				player.stat_burn_dps_flat += float(value)
		"ice_damage_pct":
			if "stat_ice_damage_mult" in player:
				player.stat_ice_damage_mult *= 1.0 + float(value)
		"ice_duration_flat":
			if "stat_ice_duration_bonus" in player:
				player.stat_ice_duration_bonus += float(value)
		"poison_damage_pct":
			if "stat_poison_damage_mult" in player:
				player.stat_poison_damage_mult *= 1.0 + float(value)
		"poison_dps_flat":
			if "stat_poison_dps_flat" in player:
				player.stat_poison_dps_flat += float(value)
		"poison_duration_pct":
			if "stat_poison_duration_pct" in player:
				player.stat_poison_duration_pct += float(value)
		"shock_damage_pct":
			if "stat_shock_damage_mult" in player:
				player.stat_shock_damage_mult *= 1.0 + float(value)
		"shock_vuln_flat":
			if "stat_shock_vuln_apply_flat" in player:
				player.stat_shock_vuln_apply_flat += float(value)
		"hp_regen_flat":
			if "stat_hp_regen_per_sec" in player:
				player.stat_hp_regen_per_sec += float(value)
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


## 商店确认弹窗：价格、材料、购买后属性变化说明
static func shop_purchase_preview_text(
	def: Dictionary,
	player: Node,
	wave_index: int,
	material_current: int
) -> String:
	var title: String = str(def.get("title", "商品"))
	var price: int = effective_shop_price(def, wave_index, player)
	var kind: String = str(def.get("kind", ""))
	var value = def.get("value")
	var lines: PackedStringArray = PackedStringArray()
	lines.append("「%s」" % title)
	lines.append("")
	lines.append("价格：%d 材料 ｜ 当前持有：%d" % [price, material_current])
	if material_current < price:
		lines.append("材料不足时无法完成购买。")
	lines.append("")
	lines.append("购买后效果：")
	match kind:
		"heal_flat":
			var h: int = int(value)
			var nh: int = mini(player.max_hp, player.current_hp + h)
			lines.append(
				"· 当前生命：%d → %d（回复 %d，上限 %d）" % [player.current_hp, nh, h, player.max_hp]
			)
		"max_hp":
			var v: int = int(value)
			lines.append(
				"· 最大生命：%d → %d（当前生命 +%d）" % [player.max_hp, player.max_hp + v, v]
			)
		"damage_pct":
			var p: float = float(value)
			var before: float = float(player.stat_damage_mult)
			var after: float = before * (1.0 + p)
			lines.append(
				"· 伤害乘数：×%.3f → ×%.3f（+%d%%）" % [before, after, int(round(p * 100.0))]
			)
		"move_pct":
			var p2: float = float(value)
			var b2: float = float(player.stat_move_speed_mult)
			lines.append("· 移速乘数：×%.3f → ×%.3f" % [b2, b2 * (1.0 + p2)])
		"fire_pct":
			var p3: float = float(value)
			var b3: float = float(player.stat_fire_rate_mult)
			lines.append("· 攻速乘数：×%.3f → ×%.3f" % [b3, b3 * (1.0 + p3)])
		"pickup":
			var b4: float = float(player.stat_pickup_radius_bonus)
			var addp: float = float(value)
			lines.append("· 拾取范围加成：%.1f → %.1f" % [b4, b4 + addp])
		"luck_flat":
			var lk: int = int(player.stat_luck) if "stat_luck" in player else 0
			lines.append("· 幸运：%d → %d" % [lk, lk + int(value)])
		"harvest_flat":
			var hv: float = float(player.stat_harvest) if "stat_harvest" in player else 0.0
			lines.append("· 收获：%.2f → %.2f" % [hv, hv + float(value)])
		"add_weapon":
			var wid: String = str(value)
			var wdef: Dictionary = WeaponCatalog.find_def(wid)
			var nm: String = str(wdef.get("display_name", wdef.get("id", wid)))
			lines.append("· 获得武器：%s（未满 6 槽时加入）" % nm)
		"hp_regen_flat":
			var rg: float = float(player.stat_hp_regen_per_sec) if "stat_hp_regen_per_sec" in player else 0.0
			var add_r: float = float(value)
			lines.append("· 生命回复：每秒 %.2f → %.2f" % [rg, rg + add_r])
		"crit_chance_flat":
			var cc: float = float(player.stat_crit_chance) if "stat_crit_chance" in player else 0.0
			var ac: float = float(value)
			lines.append("· 暴击率：%.0f%% → %.0f%%" % [cc * 100.0, clampf(cc + ac, 0.0, 1.0) * 100.0])
		"crit_mult_flat":
			var cm: float = float(player.stat_crit_mult) if "stat_crit_mult" in player else 1.5
			var am: float = float(value)
			lines.append("· 暴击倍率：×%.2f → ×%.2f" % [cm, maxf(1.0, cm + am)])
		"fire_damage_pct":
			var fm: float = float(player.stat_fire_damage_mult) if "stat_fire_damage_mult" in player else 1.0
			var fp: float = float(value)
			lines.append("· 火焰伤害乘数：×%.2f → ×%.2f" % [fm, fm * (1.0 + fp)])
		"burn_dps_flat":
			var bd: float = float(player.stat_burn_dps_flat) if "stat_burn_dps_flat" in player else 0.0
			lines.append("· 燃烧 DPS 加成：%.2f → %.2f" % [bd, bd + float(value)])
		"ice_damage_pct":
			var im: float = float(player.stat_ice_damage_mult) if "stat_ice_damage_mult" in player else 1.0
			var ip: float = float(value)
			lines.append("· 冰霜伤害乘数：×%.2f → ×%.2f" % [im, im * (1.0 + ip)])
		"ice_duration_flat":
			var ib: float = float(player.stat_ice_duration_bonus) if "stat_ice_duration_bonus" in player else 0.0
			lines.append("· 冰冻持续时间加成：%.2f → %.2f 秒" % [ib, ib + float(value)])
		"poison_damage_pct":
			var pm: float = float(player.stat_poison_damage_mult) if "stat_poison_damage_mult" in player else 1.0
			var pp: float = float(value)
			lines.append("· 毒素直伤乘数：×%.2f → ×%.2f" % [pm, pm * (1.0 + pp)])
		"poison_dps_flat":
			var pd: float = float(player.stat_poison_dps_flat) if "stat_poison_dps_flat" in player else 0.0
			lines.append("· 中毒 DPS 加成：%.2f → %.2f" % [pd, pd + float(value)])
		"poison_duration_pct":
			var pt: float = float(player.stat_poison_duration_pct) if "stat_poison_duration_pct" in player else 0.0
			lines.append("· 中毒时长加成：%.0f%% → %.0f%%" % [pt * 100.0, (pt + float(value)) * 100.0])
		"shock_damage_pct":
			var sm: float = float(player.stat_shock_damage_mult) if "stat_shock_damage_mult" in player else 1.0
			var sp: float = float(value)
			lines.append("· 电击伤害乘数：×%.2f → ×%.2f" % [sm, sm * (1.0 + sp)])
		"shock_vuln_flat":
			var sv: float = float(player.stat_shock_vuln_apply_flat) if "stat_shock_vuln_apply_flat" in player else 0.0
			lines.append("· 感电易伤施加：%.2f → %.2f" % [sv, sv + float(value)])
		_:
			lines.append("· %s" % str(def.get("desc", "参见物品说明")))
	return "\n".join(lines)


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
