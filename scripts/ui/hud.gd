extends CanvasLayer

## HUD 抬头显示脚本
## 需求：4.5、5.1、5.2、5.3、10.2

@onready var hp_label: Label = $HUDContainer/HPLabel
@onready var wave_label: Label = $HUDContainer/WaveLabel
@onready var timer_label: Label = $HUDContainer/TimerLabel
@onready var material_label: Label = $HUDContainer/MaterialLabel
@onready var savings_label: Label = $HUDContainer/SavingsLabel


func _ready() -> void:
	RunState.wave_changed.connect(_on_wave_changed)
	RunState.material_changed.connect(_on_material_changed)
	_on_wave_changed(RunState.wave_index)
	_on_material_changed(RunState.material_current, RunState.material_savings)
	timer_label.visible = false


## 连接 Player 的 hp_changed 信号（需求 5.1、5.3）
func setup(player: Node) -> void:
	if player and player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
		# 立即同步当前血量
		if "current_hp" in player and "max_hp" in player:
			_on_hp_changed(player.current_hp, player.max_hp)


## 更新血量显示（需求 4.5）
## 格式：HP: 当前/最大
func _on_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]


## 更新波次显示（需求 5.2）
func _on_wave_changed(wave_index: int) -> void:
	wave_label.text = "第 %d 波" % wave_index


## 更新倒计时显示，由 WaveManager.wave_timer_tick 信号驱动
func on_wave_timer_tick(remaining: float) -> void:
	timer_label.visible = true
	timer_label.text = "本波剩余 %d 秒" % int(ceil(remaining))


## 波次结束时隐藏倒计时
func on_wave_ended() -> void:
	timer_label.visible = false


## 更新金币与储蓄显示（需求 10.2）
func _on_material_changed(current: int, savings: int) -> void:
	material_label.text = "材料: %d" % current
	if savings > 0:
		savings_label.text = "储蓄: %d (x2)" % savings
		savings_label.visible = true
	else:
		savings_label.visible = false
