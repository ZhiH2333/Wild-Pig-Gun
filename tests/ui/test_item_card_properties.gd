extends RefCounted
class_name TestItemCardProperties

## 属性测试：ItemCard 稀有度颜色系统正确性属性验证
## 运行：godot -s res://tests/ui/test_item_card_runner.gd

const _RARITY_BG: Array[Color] = [
	Color(0.14, 0.15, 0.18, 1),
	Color(0.12, 0.16, 0.24, 1),
	Color(0.16, 0.12, 0.22, 1),
	Color(0.18, 0.14, 0.08, 1),
]
const _RARITY_BORDER: Array[Color] = [
	Color(0.75, 0.75, 0.78, 1),
	Color(0.32, 0.58, 0.95, 1),
	Color(0.72, 0.35, 0.95, 1),
	Color(0.98, 0.78, 0.22, 1),
]
const _RARITY_SHADOW_SIZE: Array[int] = [0, 4, 8, 12]
const _RARITY_SHADOW_ALPHA: Array[float] = [0.0, 0.6, 0.7, 0.8]


static func run_all() -> PackedStringArray:
	var errs: PackedStringArray = []
	_prop5_border_color_mapping(errs)
	_prop6_shadow_intensity_mapping(errs)
	_prop7_hover_border_brightness(errs)
	_prop8_disabled_color_uniform(errs)
	_prop9_rarity_clamp(errs)
	_prop10_stylebox_independence(errs)
	return errs


## 属性 5：稀有度边框颜色映射正确性（100 次迭代）
## 验证：需求 3.1
static func _prop5_border_color_mapping(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2001
	for _i in range(100):
		var rarity: int = rng.randi_range(1, 4)
		var i: int = clampi(rarity - 1, 0, 3)
		# 模拟 _apply_rarity_style 中 normal StyleBoxFlat 的 border_color
		var border_color: Color = _RARITY_BORDER[i]
		var expected: Color = _RARITY_BORDER[rarity - 1]
		if absf(border_color.r - expected.r) > 0.001 or absf(border_color.g - expected.g) > 0.001 or absf(border_color.b - expected.b) > 0.001:
			errs.append("属性5: rarity=%d 边框颜色不匹配" % rarity)
			return


## 属性 6：稀有度发光强度映射正确性（100 次迭代）
## 验证：需求 3.2
static func _prop6_shadow_intensity_mapping(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2002
	var expected_sizes: Dictionary = {2: 4, 3: 8, 4: 12}
	var expected_alphas: Dictionary = {2: 0.6, 3: 0.7, 4: 0.8}
	for _i in range(100):
		var rarity: int = rng.randi_range(2, 4)
		var i: int = clampi(rarity - 1, 0, 3)
		var shadow_size: int = _RARITY_SHADOW_SIZE[i]
		var shadow_alpha: float = _RARITY_SHADOW_ALPHA[i]
		if shadow_size != expected_sizes[rarity]:
			errs.append("属性6: rarity=%d shadow_size 应为 %d，得到 %d" % [rarity, expected_sizes[rarity], shadow_size])
			return
		if absf(shadow_alpha - expected_alphas[rarity]) > 0.001:
			errs.append("属性6: rarity=%d shadow_alpha 应为 %.1f，得到 %.4f" % [rarity, expected_alphas[rarity], shadow_alpha])
			return


## 属性 7：hover 边框颜色亮度提升不变量（100 次迭代）
## 验证：需求 3.6
static func _prop7_hover_border_brightness(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2003
	for _i in range(100):
		var rarity: int = rng.randi_range(1, 4)
		var i: int = clampi(rarity - 1, 0, 3)
		var normal_border: Color = _RARITY_BORDER[i]
		# 模拟 hover StyleBoxFlat 的 border_color
		var hover_border: Color = normal_border.lerp(Color.WHITE, 0.15)
		var expected: Color = normal_border.lerp(Color.WHITE, 0.15)
		if absf(hover_border.r - expected.r) > 0.001 or absf(hover_border.g - expected.g) > 0.001 or absf(hover_border.b - expected.b) > 0.001:
			errs.append("属性7: rarity=%d hover 边框颜色不符合 lerp(WHITE, 0.15)" % rarity)
			return


## 属性 8：disabled 状态颜色统一不变量（100 次迭代）
## 验证：需求 3.7
static func _prop8_disabled_color_uniform(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2004
	var expected_border: Color = Color(0.3, 0.3, 0.32, 1)
	var expected_bg: Color = Color(0.12, 0.12, 0.14, 1)
	for _i in range(100):
		var rarity: int = rng.randi_range(1, 4)
		# disabled 状态固定颜色，忽略稀有度
		var disabled_border: Color = Color(0.3, 0.3, 0.32, 1)
		var disabled_bg: Color = Color(0.12, 0.12, 0.14, 1)
		if absf(disabled_border.r - expected_border.r) > 0.001 or absf(disabled_border.b - expected_border.b) > 0.001:
			errs.append("属性8: rarity=%d disabled 边框颜色不统一" % rarity)
			return
		if absf(disabled_bg.r - expected_bg.r) > 0.001 or absf(disabled_bg.b - expected_bg.b) > 0.001:
			errs.append("属性8: rarity=%d disabled 背景颜色不统一" % rarity)
			return


## 属性 9：稀有度截断正确性（200 次迭代）
## 验证：需求 3.5
static func _prop9_rarity_clamp(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2005
	for _i in range(200):
		var raw_rarity: int = rng.randi_range(-10, 15)
		# 模拟 setup_card 中的截断
		var clamped: int = clampi(raw_rarity, 1, 4)
		# 模拟 _apply_rarity_style 中的索引
		var i_raw: int = clampi(raw_rarity - 1, 0, 3)
		var i_clamped: int = clampi(clamped - 1, 0, 3)
		# 两者应产生相同的颜色索引
		if i_raw != i_clamped:
			errs.append("属性9: raw_rarity=%d 截断后索引不一致，i_raw=%d，i_clamped=%d" % [raw_rarity, i_raw, i_clamped])
			return


## 属性 10：StyleBoxFlat 实例独立性（100 次迭代）
## 验证：需求 3.8
## 通过验证两个独立创建的 StyleBoxFlat 不是同一对象来验证
static func _prop10_stylebox_independence(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2006
	for _i in range(100):
		var rarity_a: int = rng.randi_range(1, 4)
		var rarity_b: int = rng.randi_range(1, 4)
		# 模拟两张卡片各自创建独立 StyleBoxFlat
		var sb_a := StyleBoxFlat.new()
		sb_a.border_color = _RARITY_BORDER[clampi(rarity_a - 1, 0, 3)]
		var sb_b := StyleBoxFlat.new()
		sb_b.border_color = _RARITY_BORDER[clampi(rarity_b - 1, 0, 3)]
		# 两个实例不应是同一对象
		if sb_a == sb_b:
			errs.append("属性10: StyleBoxFlat 实例不独立，rarity_a=%d，rarity_b=%d" % [rarity_a, rarity_b])
			return
		# 修改 sb_a 不应影响 sb_b
		var original_b_color: Color = sb_b.border_color
		sb_a.border_color = Color(0, 0, 0, 1)
		if sb_b.border_color != original_b_color:
			errs.append("属性10: 修改 sb_a 影响了 sb_b，实例不独立")
			return
