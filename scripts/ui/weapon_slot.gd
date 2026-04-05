extends PanelContainer
class_name WeaponSlot

## HUD 武器槽占位：图标 + 武器名

const FALLBACK_ICON: Texture2D = preload("res://assets/sprites/icon.png")

@onready var _icon: TextureRect = $Row/Icon
@onready var _name: Label = $Row/Name


func _ready() -> void:
	clear_slot()


func clear_slot() -> void:
	_icon.texture = FALLBACK_ICON
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
	var ipath: String = str(def.get("icon", ""))
	if not ipath.is_empty() and ResourceLoader.exists(ipath):
		var tex: Resource = load(ipath)
		_icon.texture = tex as Texture2D if tex is Texture2D else FALLBACK_ICON
	else:
		_icon.texture = FALLBACK_ICON
