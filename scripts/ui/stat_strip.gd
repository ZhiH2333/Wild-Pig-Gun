extends HBoxContainer
class_name StatStrip

## 战斗 HUD 核心属性条：伤害 / 攻速 / 移速 / 幸运（百分比类以 × 显示）

@onready var _dmg: Label = $DmgLabel
@onready var _fire: Label = $FireLabel
@onready var _move: Label = $MoveLabel
@onready var _luck: Label = $LuckLabel


func refresh_from_player(p: Node) -> void:
	if p == null:
		return
	var dm: float = 1.0
	var fr: float = 1.0
	var mv: float = 1.0
	var lk: int = 0
	if "stat_damage_mult" in p:
		dm = float(p.stat_damage_mult)
	if "stat_fire_rate_mult" in p:
		fr = float(p.stat_fire_rate_mult)
	if "stat_move_speed_mult" in p:
		mv = float(p.stat_move_speed_mult)
	if "stat_luck" in p:
		lk = int(p.stat_luck)
	_dmg.text = "伤×%.2f" % dm
	_fire.text = "速×%.2f" % fr
	_move.text = "移×%.2f" % mv
	_luck.text = "幸 %d" % lk
