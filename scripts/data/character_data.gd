extends RefCounted
class_name CharacterData

const PATH: String = "res://data/characters.json"
const FALLBACK_PLAYER_SPRITE: String = "res://assets/sprites/wildpig.png"
## 选人 UI 与策划案「速度/攻击」标尺一致：野猪 50 速=1.0x、80 攻=1.0x
const DISPLAY_SPEED_BASELINE: float = 50.0
const DISPLAY_ATTACK_BASELINE: float = 80.0


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


## 确保设置里的出战角色 ID 仍在当前配置 roster 中且已解锁；否则回退到可用角色。
static func sanitize_selected_character_setting() -> void:
	var roster: Array = list_characters()
	if roster.is_empty():
		GameSettings.set_selected_character_id("default")
		return
	var sel_id: String = str(GameSettings.selected_character_id)
	var current: Dictionary = {}
	for item in roster:
		if not item is Dictionary:
			continue
		var d: Dictionary = item as Dictionary
		if str(d.get("id", "")) == sel_id:
			current = d
			break
	if current.is_empty():
		var first_item: Variant = roster[0]
		var fallback_id: String = "default"
		if first_item is Dictionary:
			fallback_id = str((first_item as Dictionary).get("id", "default"))
		if fallback_id.is_empty():
			fallback_id = "default"
		GameSettings.set_selected_character_id(fallback_id)
		return
	if is_character_unlocked(current):
		return
	for item in roster:
		if not item is Dictionary:
			continue
		var d: Dictionary = item as Dictionary
		if is_character_unlocked(d):
			GameSettings.set_selected_character_id(str(d.get("id", "default")))
			return
	var first_item2: Variant = roster[0]
	var last_resort: String = "default"
	if first_item2 is Dictionary:
		last_resort = str((first_item2 as Dictionary).get("id", "default"))
	if last_resort.is_empty():
		last_resort = "default"
	GameSettings.set_selected_character_id(last_resort)


## 商店分页：需野猪币购买、尚未购入且尚未凭波次免费解锁的角色条目（来自 characters.json）。
static func list_shop_character_offers() -> Array:
	var out: Array = []
	for item in list_characters():
		if not item is Dictionary:
			continue
		var d: Dictionary = item as Dictionary
		if not bool(d.get("requires_purchase", false)):
			continue
		var cid: String = str(d.get("id", ""))
		if cid.is_empty():
			continue
		if SaveManager.has_purchased_character(cid):
			continue
		var req_wave: int = int(d.get("unlock_wave", 0))
		if req_wave > 0:
			var meta: Dictionary = SaveManager.load_meta_progress()
			if int(meta.get("best_wave", 0)) >= req_wave:
				continue
		out.append(d)
	return out


static func is_character_unlocked(d: Dictionary) -> bool:
	var cid: String = str(d.get("id", ""))
	if not cid.is_empty() and SaveManager.has_purchased_character(cid):
		return true
	var req: int = int(d.get("unlock_wave", 0))
	var meta: Dictionary = SaveManager.load_meta_progress()
	var best: int = int(meta.get("best_wave", 0))
	if req > 0:
		return best >= req
	if bool(d.get("requires_purchase", false)):
		return false
	return true


static func find_character(character_id: String) -> Dictionary:
	for c in list_characters():
		if c is Dictionary and str((c as Dictionary).get("id", "")) == character_id:
			return c as Dictionary
	var fb: Array = list_characters()
	if fb.size() > 0 and fb[0] is Dictionary:
		return fb[0] as Dictionary
	return _builtin_default()


## 用于选人界面属性条（与 speed_mult / damage_mult 一致）
static func get_display_hp(d: Dictionary) -> int:
	return maxi(0, int(d.get("max_hp", 0)))


static func get_display_speed_rating(d: Dictionary) -> int:
	var m: float = float(d.get("speed_mult", 1.0))
	return int(round(m * DISPLAY_SPEED_BASELINE))


static func get_display_attack_rating(d: Dictionary) -> int:
	var m: float = float(d.get("damage_mult", 1.0))
	return int(round(m * DISPLAY_ATTACK_BASELINE))


static func get_select_accent_color(character_id: String) -> Color:
	match character_id:
		"chicken":
			return Color(0.55, 0.38, 0.88, 1.0)
		"pigchicken":
			return Color(0.32, 0.72, 0.48, 1.0)
		_:
			return Color(0.5, 0.5, 0.54, 1.0)


static func get_starting_weapon_ids(character_id: String) -> Array:
	var d: Dictionary = find_character(character_id)
	var w: Variant = d.get("starting_weapons", [])
	if w is Array and not (w as Array).is_empty():
		return w as Array
	return ["rifle"]


static func apply_character_visual(player: Node, character_id: String) -> void:
	var d: Dictionary = find_character(character_id)
	_apply_sprite(player, d)


static func apply_to_player(player: Node, character_id: String) -> void:
	var d: Dictionary = find_character(character_id)
	var hp: int = int(d.get("max_hp", 100))
	var sm: float = float(d.get("speed_mult", 1.0))
	var dm: float = float(d.get("damage_mult", 1.0))
	player.max_hp = hp
	player.current_hp = hp
	player.stat_move_speed_mult *= sm
	player.stat_damage_mult *= dm
	player.shop_price_mult = float(d.get("shop_price_mult", 1.0))
	player.material_to_damage_kv = float(d.get("material_to_damage_kv", 0.0))
	_apply_traits(player, d)
	_apply_sprite(player, d)
	player.emit_signal("hp_changed", player.current_hp, player.max_hp)
	var lo: Node = player.get_node_or_null("WeaponLoadout")
	if lo != null and lo.has_method("equip_default_start"):
		var weapon_ids: Array = get_starting_weapon_ids(character_id)
		if not RunState.selected_starting_weapon_ids.is_empty():
			weapon_ids = RunState.selected_starting_weapon_ids.duplicate()
		lo.equip_default_start(weapon_ids)


static func _apply_sprite(player: Node, d: Dictionary) -> void:
	var spr: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var tex_path: String = str(d.get("sprite_path", FALLBACK_PLAYER_SPRITE))
	var tex: Texture2D = _load_player_texture(tex_path)
	if tex == null:
		push_warning("CharacterData: 无法加载角色贴图 %s，使用默认" % tex_path)
		tex = _load_player_texture(FALLBACK_PLAYER_SPRITE)
	if tex == null:
		push_error("CharacterData: 默认贴图也加载失败: %s" % FALLBACK_PLAYER_SPRITE)
		return
	spr.texture = tex
	spr.visible = true
	var scale_override: float = float(d.get("sprite_scale", -1.0))
	if scale_override <= 0.0001:
		var h: float = float(tex.get_height())
		if h > 0.001:
			scale_override = 56.0 / h
		else:
			scale_override = 1.0
	spr.scale = Vector2(scale_override, scale_override)


static func _load_player_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _apply_traits(player: Node, d: Dictionary) -> void:
	var traits: Variant = d.get("traits", [])
	if not traits is Array:
		return
	for tv in traits as Array:
		if not tv is Dictionary:
			continue
		var t: Dictionary = tv as Dictionary
		var kind: String = str(t.get("kind", ""))
		var val = t.get("value", 0)
		match kind:
			"stat_harvest":
				if "stat_harvest" in player:
					player.stat_harvest += float(val)
			"stat_luck":
				if "stat_luck" in player:
					player.stat_luck += int(val)
			"shop_price_mult":
				if "shop_price_mult" in player:
					player.shop_price_mult *= float(val)
			"material_to_damage_kv":
				if "material_to_damage_kv" in player:
					player.material_to_damage_kv += float(val)


static func _builtin_default() -> Dictionary:
	return {
		"id": "default",
		"display_name": "野猪",
		"description": "暴力肉盾 · 近战强化型",
		"sprite_path": FALLBACK_PLAYER_SPRITE,
		"max_hp": 90,
		"speed_mult": 1.0,
		"damage_mult": 1.0,
	}
