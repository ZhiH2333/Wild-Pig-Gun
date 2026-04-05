extends CanvasLayer

## HUD 抬头显示脚本
## 需求：4.5、5.1、5.2、5.3、10.2

@onready var hp_label: Label = $HUDContainer/HPLabel
@onready var wave_label: Label = $HUDContainer/WaveLabel
@onready var timer_label: Label = $HUDContainer/TimerLabel
@onready var material_label: Label = $HUDContainer/MaterialLabel
@onready var savings_label: Label = $HUDContainer/SavingsLabel
@onready var toast_label: Label = $HUDContainer/ToastLabel
@onready var level_xp_label: Label = $HUDContainer/LevelXpLabel

var _toast_left: float = 0.0


func _ready() -> void:
	RunState.wave_changed.connect(_on_wave_changed)
	RunState.material_changed.connect(_on_material_changed)
	RunState.xp_changed.connect(_on_xp_changed)
	_on_wave_changed(RunState.wave_index)
	_on_material_changed(RunState.material_current, RunState.material_savings)
	_on_xp_changed(RunState.player_level, RunState.player_xp, RunState.xp_to_next_level())
	timer_label.visible = false


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			toast_label.visible = false


func setup(player: Node) -> void:
	if player and player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
		if "current_hp" in player and "max_hp" in player:
			_on_hp_changed(player.current_hp, player.max_hp)


func _on_hp_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]


func _on_wave_changed(wave_index: int) -> void:
	wave_label.text = "第 %d 波" % wave_index


func on_wave_timer_tick(remaining: float) -> void:
	timer_label.visible = true
	timer_label.text = "本波剩余 %d 秒" % int(ceil(remaining))


func on_wave_ended() -> void:
	timer_label.visible = false


func _on_material_changed(current: int, savings: int) -> void:
	material_label.text = "材料: %d" % current
	if savings > 0:
		savings_label.text = "储蓄: %d (x2)" % savings
		savings_label.visible = true
	else:
		savings_label.visible = false


func _on_xp_changed(level: int, xp: int, need: int) -> void:
	level_xp_label.text = "Lv.%d  XP %d/%d" % [level, xp, need]


func show_harvest_toast(bonus: int) -> void:
	if bonus <= 0:
		return
	toast_label.text = "收获 +%d 材料" % bonus
	toast_label.visible = true
	_toast_left = 2.8
