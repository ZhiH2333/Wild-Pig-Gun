extends RefCounted
class_name BalanceChecks

## 无编辑器依赖的数值/数据表断言（CLI：godot -s res://tests/balance_runner.gd）


static func run_all() -> PackedStringArray:
	var errs: PackedStringArray = []
	_check_wave_duration(errs)
	_check_shop_scaling(errs)
	_check_cluster_cap(errs)
	_check_pick_shop_determinism(errs)
	return errs


static func _check_wave_duration(errs: PackedStringArray) -> void:
	var cfg: Dictionary = WaveData.load_config()
	var d9: float = WaveData.get_wave_duration_sec(cfg, 9)
	if absf(d9 - 55.0) > 0.01:
		errs.append("wave 9 duration_sec 应为 55，得到 %.2f" % d9)


static func _check_shop_scaling(errs: PackedStringArray) -> void:
	var p10: int = WaveData.shop_price_scaled(10, 10)
	var p1: int = WaveData.shop_price_scaled(10, 1)
	if p10 <= p1:
		errs.append("shop_price_scaled 应随波次递增")


static func _check_cluster_cap(errs: PackedStringArray) -> void:
	var cfg: Dictionary = WaveData.load_config()
	var cap: int = WaveData.get_effective_batch_cap(cfg, 9)
	if cap < 6:
		errs.append("wave9 cluster 应提高 batch_cap，得到 %d" % cap)


static func _check_pick_shop_determinism(errs: PackedStringArray) -> void:
	var rng1: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng1.seed = 4242
	rng2.seed = 4242
	var a: Array = BuildCatalog.pick_shop_offer(4, rng1, 5)
	var b: Array = BuildCatalog.pick_shop_offer(4, rng2, 5)
	if a.size() != b.size():
		errs.append("pick_shop_offer 同种子结果长度不一致")
		return
	for i in range(a.size()):
		if (a[i] as Dictionary).get("id", "") != (b[i] as Dictionary).get("id", ""):
			errs.append("pick_shop_offer 同种子条目不一致")
			return
