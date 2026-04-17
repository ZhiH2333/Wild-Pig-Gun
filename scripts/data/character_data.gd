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
	var tex_path: String = str(d.get("sprite_path", "res://assets/sprites/wildpig.png"))
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = load(tex_path) as Texture2D
	if tex == null:
		return
	spr.texture = tex
	var scale_override: float = float(d.get("sprite_scale", -1.0))
	if scale_override <= 0.0001:
		var h: float = float(tex.get_height())
		if h > 0.001:
			scale_override = 56.0 / h
		else:
			scale_override = 1.0
	spr.scale = Vector2(scale_override, scale_override)


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
		"display_name": "标准野猪",
		"description": "",
		"max_hp": 100,
		"speed_mult": 1.0,
		"damage_mult": 1.0,
	}
