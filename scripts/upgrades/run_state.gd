extends Node

enum PauseReason {
	NONE,
	USER,
	INTERSTITIAL,
}

# 信号
signal wave_changed(wave_index: int)
signal gold_changed(gold: int)
signal hp_changed(current: int, maximum: int)
signal material_changed(current: int, savings: int)  # 阶段二：材料变化

# 局内状态
var character_id: String = "default"
var wave_index: int = 0
var gold: int = 0
## 本局开始时的系统滴答（毫秒），用于结算用时
var run_start_ticks_msec: int = 0
## 暂停来源：用户 ESC 与波间界面互斥
var pause_reason: PauseReason = PauseReason.NONE
var upgrade_ids: Array[String] = []
var run_seed: int = 0

# 玩家血量（由 Player 节点自身管理，RunState 仅作镜像用于存档）
var player_max_hp: int = 100
var player_current_hp: int = 100

# 阶段二：材料（金币）
var material_current: int = 0   # 本波已拾取材料
var material_savings: int = 0   # 未拾取储蓄材料（下波拾取时翻倍）

func _ready() -> void:
	_register_default_input_actions()

func begin_new_run(p_character_id: String = "default") -> void:
	character_id = p_character_id
	wave_index = 0
	gold = 0
	upgrade_ids.clear()
	run_seed = randi()
	run_start_ticks_msec = Time.get_ticks_msec()
	pause_reason = PauseReason.NONE
	get_tree().paused = false
	player_max_hp = 100
	player_current_hp = 100
	material_current = 0
	material_savings = 0


func enter_interstitial_pause() -> void:
	pause_reason = PauseReason.INTERSTITIAL
	get_tree().paused = true


func leave_interstitial_pause() -> void:
	pause_reason = PauseReason.NONE
	get_tree().paused = false


func try_toggle_user_pause(arena: Node) -> void:
	if pause_reason == PauseReason.INTERSTITIAL:
		return
	if pause_reason == PauseReason.USER:
		pause_reason = PauseReason.NONE
		get_tree().paused = false
		if arena != null and arena.has_method("hide_pause_overlay"):
			arena.hide_pause_overlay()
	else:
		if not get_tree().paused:
			pause_reason = PauseReason.USER
			get_tree().paused = true
			if arena != null and arena.has_method("show_pause_overlay"):
				arena.show_pause_overlay()


func get_run_elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - run_start_ticks_msec) / 1000.0

func _register_default_input_actions() -> void:
	if InputMap.has_action("move_up"):
		return
	InputMap.add_action("move_up", 0.2)
	InputMap.add_action("move_down", 0.2)
	InputMap.add_action("move_left", 0.2)
	InputMap.add_action("move_right", 0.2)
	InputMap.add_action("pause_game", 0.2)
	InputMap.add_action("confirm", 0.2)
	_add_key_to_action("move_up", [KEY_W, KEY_UP])
	_add_key_to_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_to_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_to_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_to_action("pause_game", [KEY_ESCAPE])
	_add_key_to_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])

func _add_key_to_action(action_name: String, keycodes: Array) -> void:
	for keycode in keycodes:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = keycode as Key
		InputMap.action_add_event(action_name, ev)

# 阶段二：普通拾取材料
func collect_material(amount: int) -> void:
	material_current += amount
	emit_signal("material_changed", material_current, material_savings)

# 阶段二：波次结束时将未拾取材料转为储蓄
func on_wave_end_convert_savings(uncollected: int) -> void:
	material_savings += uncollected
	emit_signal("material_changed", material_current, material_savings)

# 阶段二：下波开始时拾取储蓄（翻倍）
func collect_savings() -> void:
	material_current += material_savings * 2
	material_savings = 0
	emit_signal("material_changed", material_current, material_savings)
