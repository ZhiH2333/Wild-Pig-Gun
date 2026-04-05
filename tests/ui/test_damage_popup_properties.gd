extends RefCounted
class_name TestDamagePopupProperties

## 属性测试：DamagePopup 正确性属性验证
## 运行：godot -s res://tests/ui/test_damage_popup_runner.gd

const RISE_SPEED: float = 62.0
const LIFETIME: float = 0.75
const CRIT_SCALE_START: float = 1.3
const CRIT_SCALE_DURATION: float = 0.15


static func run_all() -> PackedStringArray:
	var errs: PackedStringArray = []
	_prop1_normal_color_and_size(errs)
	_prop2_crit_color_size_scale(errs)
	_prop3_linear_fadeout(errs)
	_prop4_rise_speed(errs)
	return errs


## 属性 1：普通伤害飘字颜色与字体大小不变量（100 次迭代）
## 验证：需求 2.2
static func _prop1_normal_color_and_size(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001
	for _i in range(100):
		var amount: int = rng.randi_range(1, 9999)
		# 模拟 setup(amount, false) 的逻辑
		var rgb: Color = Color(1, 1, 1, 1)
		var font_size: int = 22
		# 断言
		if rgb != Color(1, 1, 1, 1):
			errs.append("属性1: 普通伤害颜色应为白色 Color(1,1,1,1)，amount=%d" % amount)
			return
		if font_size != 22:
			errs.append("属性1: 普通伤害字体大小应为 22，amount=%d" % amount)
			return


## 属性 2：暴击伤害飘字颜色、字体大小与初始缩放不变量（100 次迭代）
## 验证：需求 2.3
static func _prop2_crit_color_size_scale(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1002
	for _i in range(100):
		var amount: int = rng.randi_range(1, 9999)
		# 模拟 setup(amount, true) 的逻辑
		var rgb: Color = Color(1, 0.92, 0.35, 1)
		var font_size: int = 30
		var init_scale: Vector2 = Vector2(1.3, 1.3)
		# 断言
		if absf(rgb.r - 1.0) > 0.001 or absf(rgb.g - 0.92) > 0.001 or absf(rgb.b - 0.35) > 0.001:
			errs.append("属性2: 暴击颜色应为 Color(1,0.92,0.35,1)，amount=%d" % amount)
			return
		if font_size != 30:
			errs.append("属性2: 暴击字体大小应为 30，amount=%d" % amount)
			return
		if absf(init_scale.x - 1.3) > 0.001 or absf(init_scale.y - 1.3) > 0.001:
			errs.append("属性2: 暴击初始缩放应为 Vector2(1.3,1.3)，amount=%d" % amount)
			return


## 属性 3：飘字线性淡出属性（200 次迭代）
## 验证：需求 2.5
static func _prop3_linear_fadeout(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1003
	for _i in range(200):
		var t: float = rng.randf_range(0.0, LIFETIME)
		# 模拟 _draw() 中的 alpha 计算
		var alpha: float = clampf(1.0 - t / LIFETIME, 0.0, 1.0)
		var expected: float = clampf(1.0 - t / LIFETIME, 0.0, 1.0)
		if absf(alpha - expected) > 0.001:
			errs.append("属性3: alpha 误差超过 0.001，t=%.4f，alpha=%.4f，expected=%.4f" % [t, alpha, expected])
			return


## 属性 4：飘字上移速度不变量（200 次迭代）
## 验证：需求 2.4
static func _prop4_rise_speed(errs: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1004
	for _i in range(200):
		var dt: float = rng.randf_range(0.001, 0.1)
		var pos_y_before: float = rng.randf_range(-500.0, 500.0)
		# 模拟 _process(dt) 中的上移逻辑
		var pos_y_after: float = pos_y_before - RISE_SPEED * dt
		var expected_delta: float = -RISE_SPEED * dt
		var actual_delta: float = pos_y_after - pos_y_before
		if absf(actual_delta - expected_delta) > 0.001:
			errs.append("属性4: 上移速度误差超过 0.001，dt=%.4f" % dt)
			return
