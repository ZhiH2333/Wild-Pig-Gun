extends RefCounted
class_name CharacterStatBarsUi

const STAT_BAR_MAX: float = 100.0
const COLOR_HP := Color(0.88, 0.24, 0.22, 1.0)
const COLOR_SPEED := Color(0.78, 0.56, 0.2, 1.0)
const COLOR_ATTACK := Color(0.58, 0.32, 0.82, 1.0)


static func make_stat_row(
	label_text: String,
	value: int,
	fill: Color,
	unlocked: bool = true,
	compact: bool = false
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if compact else 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim: float = 0.45 if not unlocked else 1.0
	var fs: int = 14 if compact else 16
	var bar_h: int = 14 if compact else 18
	var label_w: float = 38.0 if compact else 44.0
	var lab := Label.new()
	lab.text = label_text
	lab.custom_minimum_size = Vector2(label_w, 0)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", fs)
	lab.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82, dim))
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lab)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = STAT_BAR_MAX
	bar.value = clampf(float(value), 0.0, STAT_BAR_MAX)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(80, bar_h)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.11, 0.14, 0.92)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(fill.r, fill.g, fill.b, fill.a * dim)
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	row.add_child(bar)
	var num := Label.new()
	num.text = str(value)
	num.custom_minimum_size = Vector2(32 if compact else 36, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", fs)
	num.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, dim))
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(num)
	return row


static func append_to_vbox(v: VBoxContainer, d: Dictionary, unlocked: bool = true, compact: bool = false) -> void:
	var hp: int = CharacterData.get_display_hp(d)
	var sp: int = CharacterData.get_display_speed_rating(d)
	var atk: int = CharacterData.get_display_attack_rating(d)
	v.add_child(make_stat_row("HP", hp, COLOR_HP, unlocked, compact))
	v.add_child(make_stat_row("速度", sp, COLOR_SPEED, unlocked, compact))
	v.add_child(make_stat_row("攻击", atk, COLOR_ATTACK, unlocked, compact))
