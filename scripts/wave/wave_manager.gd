extends Node
## WaveManager 波次管理器
## 负责波次倒计时、敌人分批刷新、精英怪随机出现和通关判定
## 需求：7.1、7.2、7.3、7.4、7.5

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal wave_timer_tick(remaining: float)
signal all_waves_cleared
signal enemy_spawn_requested(config: Dictionary, position: Vector2)
signal spawn_warning_shown(position: Vector2)

const MAX_WAVES: int = 20
const BASE_WAVE_DURATION: float = 30.0
const MAX_WAVE_DURATION: float = 60.0
const SPAWN_INTERVAL_START: float = 2.0
const SPAWN_INTERVAL_MIN: float = 0.5
const SPAWN_WARNING_DURATION: float = 0.8
const MIN_SPAWN_DISTANCE_FROM_PLAYER: float = 80.0

var current_wave: int = 0
var is_wave_active: bool = false
var _spawn_elapsed: float = 0.0

## 外部依赖（由 Arena 注入）
var player: Node2D = null
var enemy_pool: Node = null
var arena_rect: Rect2 = Rect2()

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var elite_check_timer: Timer = $EliteCheckTimer


func _ready() -> void:
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	elite_check_timer.timeout.connect(_on_elite_check_timer_timeout)


func _process(delta: float) -> void:
	if not is_wave_active:
		return
	_spawn_elapsed += delta
	# 动态调整刷新间隔
	var new_interval := _get_spawn_interval()
	if abs(spawn_timer.wait_time - new_interval) > 0.05:
		spawn_timer.wait_time = new_interval
	# 发出倒计时 tick
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

	spawn_timer.wait_time = SPAWN_INTERVAL_START
	spawn_timer.start()

	# 10 波以上启动精英检查（每 15 秒检查一次）
	if wave_index >= 10:
		elite_check_timer.wait_time = 15.0
		elite_check_timer.start()
	else:
		elite_check_timer.stop()

	emit_signal("wave_started", wave_index)
	# 波次开始时立刻刷一批
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


## 波次时长：线性增长，上限 60 秒（需求 7.2）
func _get_wave_duration(wave_index: int) -> float:
	var duration := BASE_WAVE_DURATION + wave_index * 1.5
	return minf(duration, MAX_WAVE_DURATION)


## 刷新间隔：随波次内时间流逝从 2.0 线性降至 0.5
func _get_spawn_interval() -> float:
	var wave_duration := _get_wave_duration(current_wave)
	var progress := clampf(_spawn_elapsed / wave_duration, 0.0, 1.0)
	return lerpf(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, progress)


## 分批刷新：先发预警信号，延迟后发实际生成信号
func _try_spawn_batch() -> void:
	if not is_wave_active:
		return
	# 每批生成数量随波次递增（需求 7.3）
	var batch_size: int = 1 + int(current_wave * 0.5)
	batch_size = mini(batch_size, 5)

	for _i in range(batch_size):
		var pos := _get_safe_spawn_position()
		emit_signal("spawn_warning_shown", pos)

	# 延迟后实际生成
	await get_tree().create_timer(SPAWN_WARNING_DURATION).timeout

	if not is_wave_active:
		return

	for _i in range(batch_size):
		var pos := _get_safe_spawn_position()
		var config := _get_spawn_config()
		emit_signal("enemy_spawn_requested", config, pos)


## 精英怪生成逻辑（需求 7.3）
## 第 10 波前不出现，第 20 波必出现，10-19 波按概率
func _try_spawn_elite() -> void:
	if current_wave < 10:
		return

	if current_wave >= MAX_WAVES:
		# 第 20 波必出现 Boss 级精英
		var pos := _get_safe_spawn_position()
		emit_signal("enemy_spawn_requested", {"type": "elite", "is_boss": true}, pos)
		return

	# 10-19 波：概率随波次线性增加（10波30%，19波75%）
	var chance := 0.3 + (current_wave - 10) * 0.05
	if randf() < chance:
		var pos := _get_safe_spawn_position()
		emit_signal("enemy_spawn_requested", {"type": "elite"}, pos)


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


## 根据当前波次决定生成的敌人类型配置
func _get_spawn_config() -> Dictionary:
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


## 定时刷新批次
func _on_spawn_timer_timeout() -> void:
	_try_spawn_batch()


## 精英怪检查
func _on_elite_check_timer_timeout() -> void:
	_try_spawn_elite()
