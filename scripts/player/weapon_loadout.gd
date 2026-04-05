extends Node2D
class_name WeaponLoadout

const MAX_SLOTS: int = 6


func _ready() -> void:
	for c in get_children():
		_tag_weapon_node(c)


func _tag_weapon_node(n: Node) -> void:
	if n.has_method("_on_fire_timer_timeout") or n.has_method("_melee_strike"):
		n.add_to_group("player_weapon")


## 开局装配；失败则保留场景内已有武器
func equip_default_start(character_weapon_ids: Array) -> void:
	if get_child_count() > 0:
		for c in get_children():
			_tag_weapon_node(c)
		_notify_synergy()
		return
	if character_weapon_ids.is_empty():
		_add_weapon_by_id("rifle")
	else:
		for wid_variant in character_weapon_ids:
			_add_weapon_by_id(str(wid_variant))
	_notify_synergy()


func add_weapon_slot_by_id(weapon_id: String) -> bool:
	if get_child_count() >= MAX_SLOTS:
		return false
	_add_weapon_by_id(weapon_id)
	_notify_synergy()
	return true


func _add_weapon_by_id(weapon_id: String) -> void:
	var def: Dictionary = WeaponCatalog.find_def(weapon_id)
	var kind: String = str(def.get("kind", "projectile"))
	if kind == "melee":
		var mpath: String = "res://scenes/melee_weapon.tscn"
		if not ResourceLoader.exists(mpath):
			return
		var m: Node2D = (load(mpath) as PackedScene).instantiate() as Node2D
		m.set("weapon_id", weapon_id)
		add_child(m)
		_tag_weapon_node(m)
		return
	var wpath: String = "res://scenes/weapon.tscn"
	if not ResourceLoader.exists(wpath):
		return
	var w: Node2D = (load(wpath) as PackedScene).instantiate() as Node2D
	w.set("weapon_id", weapon_id)
	add_child(w)
	_tag_weapon_node(w)


func _notify_synergy() -> void:
	var p: Node = get_parent()
	if p != null and p.has_method("recompute_weapon_synergy"):
		p.recompute_weapon_synergy()
