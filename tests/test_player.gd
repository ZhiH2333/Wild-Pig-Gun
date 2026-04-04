extends GdUnitTestSuite

## 玩家单元测试与属性测试
## Feature: wild-pig-gun
## 需求：1.2、1.3、1.4、4.1、4.2、4.3、4.4


# ============================================================
# 属性 1：移动速度不变性
# 验证：需求 1.2、1.3
# 对于任意非零方向输入向量，归一化后乘以 SPEED，
# 结果向量的长度应恒等于 SPEED（200.0）
# ============================================================
func test_movement_speed_invariant() -> void:
	# Feature: wild-pig-gun, Property 1: 移动速度不变性
	# Validates: Requirements 1.2, 1.3
	const SPEED: float = 200.0
	const ITERATIONS: int = 100
	const DELTA: float = 0.001  # 允许的浮点误差

	var tested: int = 0
	var attempts: int = 0

	# 循环直到收集到 100 个有效非零向量
	while tested < ITERATIONS:
		attempts += 1
		# 防止无限循环（理论上极低概率全为零向量）
		assert_bool(attempts < ITERATIONS * 10).is_true()

		# 随机生成方向向量（分量范围 -1.0 ~ 1.0）
		var direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)

		# 跳过零向量（与 _get_input_direction 逻辑一致）
		if direction.length_squared() <= 0.0:
			continue

		# 计算归一化速度向量的长度
		var velocity: Vector2 = direction.normalized() * SPEED
		var speed_magnitude: float = velocity.length()

		# 验证速度大小恒等于 SPEED（200.0），允许浮点误差
		assert_float(speed_magnitude).is_equal_approx(SPEED, DELTA)

		tested += 1
