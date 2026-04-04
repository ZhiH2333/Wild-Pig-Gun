extends CanvasLayer

## HUD 抬头显示脚本
## 需求：4.5、5.1、5.2、5.3

@onready var hp_label: Label = $HUDContainer/HPLabel
@onready var wave_label: Label = $HUDContainer/WaveLabel


func _ready() -> void:
	# 连接 RunState 的 wave_changed 信号（需求 5.2）
	RunState.wave_changed.connect(_on_wave_changed)
	# 初始化波次显示
	_on_wave_changed(RunState.wave_index)


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
