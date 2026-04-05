extends Button
class_name ItemCard

## 波间 / 升级三选一 / 商店行：稀有度边框 + 图标槽 + 文案

const FALLBACK_ICON: Texture2D = preload("res://assets/sprites/icon.png")

const _RARITY_BG: Array[Color] = [
	Color(0.14, 0.15, 0.18, 1),
	Color(0.12, 0.16, 0.24, 1),
	Color(0.18, 0.12, 0.1, 1),
]
const _RARITY_BORDER: Array[Color] = [
	Color(0.48, 0.5, 0.55, 1),
	Color(0.32, 0.58, 0.95, 1),
	Color(0.95, 0.52, 0.22, 1),
]

@onready var _icon: TextureRect = $Margin/Main/Icon
@onready var _title: Label = $Margin/Main/Texts/Title
@onready var _desc: Label = $Margin/Main/Texts/Desc
@onready var _price: Label = $Margin/Main/Texts/Price


func _ready() -> void:
	_icon.texture = FALLBACK_ICON


func setup_card(def: Dictionary, mode: String, price: int = -1, can_afford: bool = true) -> void:
	modulate = Color.WHITE
	var rarity: int = clampi(int(def.get("rarity", 1)), 1, 3)
	_apply_rarity_style(rarity)
	var title_text: String = str(def.get("title", "?"))
	_title.text = title_text
	var short_d: String = str(def.get("short_desc", def.get("desc", "")))
	_desc.text = short_d
	_apply_icon(str(def.get("icon", "")))
	if mode == "shop":
		_price.visible = true
		_price.text = "%d 材料" % maxi(0, price)
		disabled = false
		modulate = Color(0.65, 0.65, 0.72, 1) if not can_afford else Color.WHITE
	else:
		_price.visible = false
		disabled = false
		modulate = Color.WHITE


func _apply_icon(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		_icon.texture = FALLBACK_ICON
		return
	var tex: Resource = load(path)
	_icon.texture = tex as Texture2D if tex is Texture2D else FALLBACK_ICON


func _apply_rarity_style(rarity: int) -> void:
	var i: int = mini(maxi(rarity - 1, 0), 2)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = _RARITY_BG[i]
		sb.set_border_width_all(3)
		sb.border_color = _RARITY_BORDER[i]
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10)
		if st == "hover":
			sb.bg_color = sb.bg_color.lerp(Color(1, 1, 1, 1), 0.08)
			sb.border_color = sb.border_color.lerp(Color(1, 1, 1, 1), 0.12)
		elif st == "pressed":
			sb.bg_color = sb.bg_color.darkened(0.12)
		elif st == "disabled":
			sb.bg_color = Color(0.12, 0.12, 0.14, 1)
			sb.border_color = Color(0.3, 0.3, 0.32, 1)
		add_theme_stylebox_override(st, sb)
