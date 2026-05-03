extends PanelContainer
class_name WeaponSlot

## HUD 武器槽：与 pre_start 武器卡一致的 emoji + 武器名（不用 icon.png）

@onready var _emoji: Label = $Row/Emoji
@onready var _name: Label = $Row/Name


func _ready() -> void:
	clear_slot()


func clear_slot() -> void:
	if _emoji != null:
		_emoji.text = ""
		_emoji.visible = false
	_name.text = "—"
	modulate = Color(1, 1, 1, 0.45)


func set_weapon(weapon_id: String) -> void:
	if weapon_id.is_empty():
		clear_slot()
		return
	modulate = Color(1, 1, 1, 1)
	var def: Dictionary = WeaponCatalog.find_def(weapon_id)
	var disp: String = str(def.get("display_name", def.get("id", weapon_id)))
	_name.text = disp
	if _emoji != null:
		_emoji.text = WeaponCatalog.display_emoji_for_weapon_id(weapon_id)
		_emoji.visible = true
