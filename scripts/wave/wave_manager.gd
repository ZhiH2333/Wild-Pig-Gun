extends Node
class_name WaveManager
## WaveManager 波次管理器
## 负责波次倒计时、敌人分批刷新、精英怪随机出现和通关判定
## 需求：7.1、7.2、7.3、7.4、7.5

signal wave_started(wave_index: int, duration_sec: float)
signal wave_ended(wave_index: int)
signal wave_timer_tick(remaining: float)
signal all_waves_cleared
signal enemy_spawn_requested(config: Dictionary, position: Vector2)
signal spawn_warning_shown(position: Vector2)

const MAX_WAVES: int = 20
const SPAWN_INTERVAL_START: float = 2.0
const SPAWN_INTERVAL_MIN: float = 0.5
## 随机刷怪：在中心值附近抖动（秒）
const SPAWN_JITTER_LOW: float = 0.62
const SPAWN_JITTER_HIGH: float = 1.38
const SPAWN_WARNING_DURATION: float = 0.8
const MIN_SPAWN_DISTANCE_FROM_PLAYER: float = 80.0
## 玩家站在预警点半径内时取消该次生成（站位挡刷新）
const SPAWN_BLOCK_RADIUS: float = 36.0

var current_wave: int = 0
var is_wave_active: bool = false
var _spawn_elapsed: float = 0.0
var _wave_file_config: Dictionary = {}
var _elite_chance_bonus: float = 0.0

## 外部依赖（由 Arena 注入）
var player: Node2D = null
var enemy_pool: Node = null
var arena_rect: Rect2 = Rect2()

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var elite_check_timer: Timer = $EliteCheckTimer


func _ready() -> void:
	_wave_file_config = WaveData.load_config()
	spawn_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	elite_check_timer.timeout.connect(_on_elite_check_timer_timeout)


func _process(delta: float) -> void:
	if not is_wave_active:
		return
	_spawn_elapsed += delta
	emit_signal("wave_timer_tick", wave_timer.time_left)


## 启动整局游戏，从第 1 波开始
func start_run() -> void:
	current_wave = 0
	_start_wave(1)


## 开始指定波次
func _start_wave(wave_index: int) -> void:
	current_wave = wave_index
	is_wave_active = true
	_spawn_elapsed = 0.0

	var duration := _get_wave_duration(wave_index)
	wave_timer.wait_time = duration
	wave_timer.start()

	spawn_timer.stop()
	var boss_t: String = WaveData.get_boss_type(_wave_file_config, wave_index)
	if boss_t.is_empty():
		_schedule_next_spawn_tick()
	else:
		elite_check_timer.stop()

	var elite_cfg: Dictionary = WaveData.get_elite_focus_settings(_wave_file_config, wave_index)
	_elite_chance_bonus = float(elite_cfg.get("chance_bonus", 0.0))
	if boss_t.is_empty() and (wave_index >= 10 or bool(elite_cfg.get("active", false))):
		elite_check_timer.wait_time = float(elite_cfg.get("interval", 15.0))
		elite_check_timer.start()
	elif boss_t.is_empty():
		elite_check_timer.stop()

	emit_signal("wave_started", wave_index, duration)
	if boss_t.is_empty():
		_try_spawn_batch()


## 结束当前波次
func _end_wave() -> void:
	is_wave_active = false
	spawn_timer.stop()
	elite_check_timer.stop()
	emit_signal("wave_ended", current_wave)

	if current_wave >= MAX_WAVES:
		emit_signal("all_waves_cleared")


## 由外部（升级/商店界面关闭后）调用，进入下一波
func start_next_wave() -> void:
	_start_wave(current_wave + 1)


func get_save_snapshot() -> Dictionary:
	var wave_left: float = wave_timer.time_left
	if wave_timer.is_stopped():
		wave_left = _get_wave_duration(current_wave)
	return {
		"current_wave": current_wave,
		"is_wave_active": is_wave_active,
		"spawn_elapsed": _spawn_elapsed,
		"wave_timer_left": wave_left,
		"spawn_timer_running": not spawn_timer.is_stopped(),
		"spawn_timer_left": spawn_timer.time_left if not spawn_timer.is_stopped() else 0.0,
		"elite_timer_running": not elite_check_timer.is_stopped(),
		"elite_timer_left": elite_check_timer.time_left if not elite_check_timer.is_stopped() else 0.0,
	}


func apply_save_snapshot(d: Dictionary) -> void:
	_wave_file_config = WaveData.load_config()
	current_wave = int(d.get("current_wave", 1))
	is_wave_active = bool(d.get("is_wave_active", true))
	_spawn_elapsed = float(d.get("spawn_elapsed", 0.0))
	wave_timer.stop()
	spawn_timer.stop()
	elite_check_timer.stop()
	if not is_wave_active:
		return
	var widx: int = current_wave
	var wave_left: float = float(d.get("wave_timer_left", _get_wave_duration(widx)))
	wave_timer.wait_time = maxf(0.08, wave_left)
	wave_timer.start()
	var elite_cfg: Dictionary = WaveData.get_elite_focus_settings(_wave_file_config, widx)
	_elite_chance_bonus = float(elite_cfg.get("chance_bonus", 0.0))
	if widx >= 10 or bool(elite_cfg.get("active", false)):
		var elite_iv: float = float(elite_cfg.get("interval", 15.0))
		if bool(d.get("elite_timer_running", false)):
			elite_check_timer.wait_time = maxf(0.15, float(d.get("elite_timer_left", elite_iv)))
		else:
			elite_check_timer.wait_time = elite_iv
		elite_check_timer.start()
	if bool(d.get("spawn_timer_running", false)):
		var stl: float = float(d.get("spawn_timer_left", 0.5))
		spawn_timer.wait_time = maxf(0.08, stl)
		spawn_timer.start()
	else:
		_schedule_next_spawn_tick()


## 波次时长：优先 data 表 duration_sec，否则回退公式
func _get_wave_duration(wave_index: int) -> float:
	var d: float = WaveData.get_wave_duration_sec(_wave_file_config, wave_index)
	return clampf(d, 15.0, 120.0)


## 基础刷怪间隔中心值：随波次内时间从慢到快
func _get_spawn_interval_center() -> float:
	var wave_duration: float = _get_wave_duration(current_wave)
	var progress: float = clampf(_spawn_elapsed / maxf(0.001, wave_duration), 0.0, 1.0)
	return lerpf(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, progress)


## 下一次刷怪随机等待时间（秒）
func _roll_random_spawn_delay() -> float:
	var center: float = _get_spawn_interval_center()
	var lo: float = maxf(0.35, center * SPAWN_JITTER_LOW)
	var hi: float = maxf(lo + 0.08, center * SPAWN_JITTER_HIGH)
	return randf_range(lo, hi)


func _schedule_next_spawn_tick() -> void:
	if not is_wave_active:
		return
	spawn_timer.wait_time = _roll_random_spawn_delay()
	spawn_timer.start()


## 本批各只怪的类型（尽量在同一批里出现多种类型）
func _get_batch_enemy_types(batch_size: int) -> Array:
	var entry: Dictionary = WaveData.get_wave_entry(_wave_file_config, current_wave)
	var weights: Dictionary = {}
	if entry.has("weights") and entry["weights"] is Dictionary:
		weights = entry["weights"] as Dictionary
	var types: Array = []
	if weights.is_empty():
		for _i in range(batch_size):
			types.append(_get_spawn_config()["type"])
		return types
	for _j in range(batch_size):
		types.append(_roll_weighted_type(weights))
	if batch_size >= 2 and weights.size() >= 2:
		var first: String = str(types[0])
		var all_same: bool = true
		for t in types:
			if str(t) != first:
				all_same = false
				break
		if all_same:
			types[batch_size - 1] = _roll_weighted_type_excluding(weights, first)
	return types


func _roll_weighted_type_excluding(weights: Dictionary, exclude: String) -> String:
	var w2: Dictionary = {}
	for k in weights.keys():
		if str(k) != exclude:
			w2[str(k)] = float(weights[k])
	if w2.is_empty():
		return _roll_weighted_type(weights)
	return _roll_weighted_type(w2)


## 分批刷新：预警坐标与生成坐标一致；玩家占点则跳过该格
func _try_spawn_batch() -> void:
	if not is_wave_active:
		return
	var batch_size: int = _resolve_batch_size()
	if batch_size <= 0:
		return
	var type_ids: Array = _get_batch_enemy_types(batch_size)
	var slots: Array = []
	for j in range(batch_size):
		slots.append({
			"pos": _get_safe_spawn_position(),
			"config": {"type": str(type_ids[j])},
		})
	for s in slots:
		emit_signal("spawn_warning_shown", s["pos"] as Vector2)
	await get_tree().create_timer(SPAWN_WARNING_DURATION).timeout
	if not is_wave_active:
		return
	for s in slots:
		var pos: Vector2 = s["pos"] as Vector2
		if _is_spawn_blocked_by_player(pos):
			continue
		emit_signal("enemy_spawn_requested", s["config"] as Dictionary, pos)


## 精英怪生成逻辑（需求 7.3）；与批次相同：预警后同坐标生成，可挡刷新
func _try_spawn_elite() -> void:
	_spawn_elite_sequence()


func _spawn_elite_sequence() -> void:
	if current_wave < 10 or not is_wave_active:
		return
	if current_wave >= MAX_WAVES:
		var pos_boss := _get_safe_spawn_position()
		emit_signal("spawn_warning_shown", pos_boss)
		await get_tree().create_timer(SPAWN_WARNING_DURATION).timeout
		if not is_wave_active:
			return
		if not _is_spawn_blocked_by_player(pos_boss):
			emit_signal("enemy_spawn_requested", {"type": "elite", "is_boss": true}, pos_boss)
		return
	var base_chance: float = 0.3 + maxf(0.0, float(current_wave - 10)) * 0.05
	if current_wave < 10:
		base_chance = 0.38
	var chance: float = clampf(base_chance + _elite_chance_bonus, 0.08, 0.92)
	if randf() >= chance:
		return
	var pos := _get_safe_spawn_position()
	emit_signal("spawn_warning_shown", pos)
	await get_tree().create_timer(SPAWN_WARNING_DURATION).timeout
	if not is_wave_active:
		return
	if _is_spawn_blocked_by_player(pos):
		return
	emit_signal("enemy_spawn_requested", {"type": "elite"}, pos)


func _is_spawn_blocked_by_player(pos: Vector2) -> bool:
	if player == null:
		return false
	return player.global_position.distance_to(pos) < SPAWN_BLOCK_RADIUS


## 在 Arena 边缘选取安全生成位置（距玩家 > 80 像素，最多重试 5 次）
func _get_safe_spawn_position() -> Vector2:
	for _i in range(5):
		var pos := _random_edge_position()
		if player == null:
			return pos
		if player.global_position.distance_to(pos) > MIN_SPAWN_DISTANCE_FROM_PLAYER:
			return pos
	return _random_edge_position()


## 在 Arena 四条边缘随机选取一个点
func _random_edge_position() -> Vector2:
	if arena_rect.size == Vector2.ZERO:
		return Vector2(960.0, 0.0)

	var edge: int = randi() % 4
	var margin := 16.0
	match edge:
		0:  # 上边
			return Vector2(
				randf_range(arena_rect.position.x, arena_rect.end.x),
				randf_range(arena_rect.position.y, arena_rect.position.y + margin)
			)
		1:  # 下边
			return Vector2(
				randf_range(arena_rect.position.x, arena_rect.end.x),
				randf_range(arena_rect.end.y - margin, arena_rect.end.y)
			)
		2:  # 左边
			return Vector2(
				randf_range(arena_rect.position.x, arena_rect.position.x + margin),
				randf_range(arena_rect.position.y, arena_rect.end.y)
			)
		_:  # 右边
			return Vector2(
				randf_range(arena_rect.end.x - margin, arena_rect.end.x),
				randf_range(arena_rect.position.y, arena_rect.end.y)
			)


func _resolve_batch_size() -> int:
	return WaveData.get_effective_batch_cap(_wave_file_config, current_wave)


func _roll_weighted_type(weights: Dictionary) -> String:
	var sum: float = 0.0
	for k in weights.keys():
		sum += float(weights[k])
	if sum <= 0.0:
		return "basic"
	var r: float = randf() * sum
	var acc: float = 0.0
	for k in weights.keys():
		acc += float(weights[k])
		if r <= acc:
			return str(k)
	return "basic"


## 根据当前波次决定生成的敌人类型配置
func _get_spawn_config() -> Dictionary:
	var entry: Dictionary = WaveData.get_wave_entry(_wave_file_config, current_wave)
	if entry.has("weights"):
		var wobj: Variant = entry["weights"]
		if wobj is Dictionary:
			return {"type": _roll_weighted_type(wobj as Dictionary)}
	if current_wave <= 3:
		return {"type": "basic"}
	elif current_wave <= 7:
		# 4-7 波：混入冲刺型
		return {"type": "dash"} if randf() < 0.3 else {"type": "basic"}
	elif current_wave <= 12:
		# 8-12 波：混入远程型
		var r := randf()
		if r < 0.2:
			return {"type": "ranged"}
		elif r < 0.4:
			return {"type": "dash"}
		else:
			return {"type": "basic"}
	else:
		# 13+ 波：全类型混合
		var r := randf()
		if r < 0.15:
			return {"type": "ranged"}
		elif r < 0.3:
			return {"type": "dash"}
		elif r < 0.35:
			return {"type": "tree"}
		elif r < 0.38:
			return {"type": "looter"}
		else:
			return {"type": "basic"}


## 波次倒计时结束
func _on_wave_timer_timeout() -> void:
	_end_wave()


## 定时刷新批次（随机间隔由每次 timeout 后重新调度）
func _on_spawn_timer_timeout() -> void:
	await _try_spawn_batch()
	if not is_wave_active:
		return
	_schedule_next_spawn_tick()


## 精英怪检查
func _on_elite_check_timer_timeout() -> void:
	_try_spawn_elite()
