extends Button
class_name ItemCard

## 波间 / 升级三选一 / 商店行：稀有度边框 + 图标槽 + 文案

const FALLBACK_ICON: Texture2D = preload("res://assets/sprites/icon.png")

const _RARITY_BG: Array[Color] = [
	Color(0.14, 0.15, 0.18, 1),  # 1 普通
	Color(0.12, 0.16, 0.24, 1),  # 2 稀有
	Color(0.16, 0.12, 0.22, 1),  # 3 史诗
	Color(0.18, 0.14, 0.08, 1),  # 4 传说
]
const _RARITY_BORDER: Array[Color] = [
	Color(0.75, 0.75, 0.78, 1),  # 1 普通 浅灰白
	Color(0.32, 0.58, 0.95, 1),  # 2 稀有 蓝色
	Color(0.72, 0.35, 0.95, 1),  # 3 史诗 紫色
	Color(0.98, 0.78, 0.22, 1),  # 4 传说 金色
]
const _RARITY_SHADOW_SIZE: Array[int] = [0, 4, 8, 12]
const _RARITY_SHADOW_ALPHA: Array[float] = [0.0, 0.6, 0.7, 0.8]

var _pulse_tween: Tween = null

@onready var _icon: TextureRect = $Margin/Main/Icon
@onready var _title: Label = $Margin/Main/Texts/Title
@onready var _desc: Label = $Margin/Main/Texts/Desc
@onready var _price: Label = $Margin/Main/Texts/Price


func _ready() -> void:
	_icon.texture = FALLBACK_ICON
	_title.add_theme_font_size_override("font_size", 25)
	_desc.add_theme_font_size_override("font_size", 19)
	_price.add_theme_font_size_override("font_size", 22)


func setup_card(def: Dictionary, mode: String, price: int = -1, can_afford: bool = true) -> void:
	modulate = Color.WHITE
	var rarity: int = clampi(int(def.get("rarity", 1)), 1, 4)
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
	var i: int = clampi(rarity - 1, 0, 3)
	var bg_color: Color = _RARITY_BG[i]
	var border_color: Color = _RARITY_BORDER[i]
	var shadow_size: int = _RARITY_SHADOW_SIZE[i]
	var shadow_alpha: float = _RARITY_SHADOW_ALPHA[i]

	# normal
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_color
	sb_normal.set_border_width_all(3)
	sb_normal.border_color = border_color
	sb_normal.set_corner_radius_all(10)
	sb_normal.set_content_margin_all(10)
	sb_normal.shadow_size = shadow_size
	sb_normal.shadow_color = Color(border_color.r, border_color.g, border_color.b, shadow_alpha)
	add_theme_stylebox_override("normal", sb_normal)

	# hover
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = bg_color.lerp(Color(1, 1, 1, 1), 0.08)
	sb_hover.set_border_width_all(3)
	sb_hover.border_color = border_color.lerp(Color.WHITE, 0.15)
	sb_hover.set_corner_radius_all(10)
	sb_hover.set_content_margin_all(10)
	sb_hover.shadow_size = shadow_size
	sb_hover.shadow_color = Color(border_color.r, border_color.g, border_color.b, shadow_alpha)
	add_theme_stylebox_override("hover", sb_hover)

	# pressed
	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = bg_color.darkened(0.12)
	sb_pressed.set_border_width_all(3)
	sb_pressed.border_color = border_color
	sb_pressed.set_corner_radius_all(10)
	sb_pressed.set_content_margin_all(10)
	sb_pressed.shadow_size = shadow_size
	sb_pressed.shadow_color = Color(border_color.r, border_color.g, border_color.b, shadow_alpha)
	add_theme_stylebox_override("pressed", sb_pressed)

	# disabled（固定颜色，忽略稀有度）
	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.12, 0.12, 0.14, 1)
	sb_disabled.set_border_width_all(3)
	sb_disabled.border_color = Color(0.3, 0.3, 0.32, 1)
	sb_disabled.set_corner_radius_all(10)
	sb_disabled.set_content_margin_all(10)
	add_theme_stylebox_override("disabled", sb_disabled)

	# 传说脉冲动画
	if rarity == 4:
		_start_legendary_pulse()
	elif _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null


func _start_legendary_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_method(_set_border_alpha, 0.75, 1.0, 0.75)
	_pulse_tween.tween_method(_set_border_alpha, 1.0, 0.75, 0.75)


func _set_border_alpha(a: float) -> void:
	var sb: StyleBoxFlat = get_theme_stylebox("normal") as StyleBoxFlat
	if sb == null:
		return
	var c: Color = sb.border_color
	c.a = a
	sb.border_color = c
