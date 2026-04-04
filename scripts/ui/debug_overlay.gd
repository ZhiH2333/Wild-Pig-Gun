extends CanvasLayer

## 全局调试覆盖层：右上角显示玩家操作、角色状态、敌人操作
## 挂载在 Arena 场景的 CanvasLayer 节点上（layer = 100）

@onready var label: RichTextLabel = $DebugLabel

# 每帧刷新
func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return

	var lines: PackedStringArray = []

	# ── 玩家信息 ──────────────────────────────
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		var p := players[0]
		lines.append("[color=yellow]═══ 玩家 ═══[/color]")
		lines.append("坐标: (%.0f, %.0f)" % [p.global_position.x, p.global_position.y])
		if "current_hp" in p and "max_hp" in p:
			var hp_color := "lime" if p.current_hp > p.max_hp * 0.5 else "red"
			lines.append("血量: [color=%s]%d / %d[/color]" % [hp_color, p.current_hp, p.max_hp])
		if "is_invincible" in p and p.is_invincible:
			lines.append("[color=cyan]状态: 无敌帧[/color]")
		if "_debug_action" in p:
			lines.append("操作: [color=white]%s[/color]" % p._debug_action)
	else:
		lines.append("[color=gray]玩家未生成[/color]")

	lines.append("")

	# ── 敌人信息 ──────────────────────────────
	var enemies := tree.get_nodes_in_group("enemies")
	lines.append("[color=tomato]═══ 敌人 (%d只) ═══[/color]" % enemies.size())
	# 最多显示 6 只，避免溢出
	var show_count := mini(enemies.size(), 6)
	for i in range(show_count):
		var e := enemies[i]
		var hp_str := ""
		if "current_hp" in e and "max_hp" in e:
			hp_str = " HP:%d/%d" % [e.current_hp, e.max_hp]
		var pos_str := "(%.0f,%.0f)" % [e.global_position.x, e.global_position.y]
		var act_str := ""
		if "_debug_action" in e:
			act_str = " | %s" % e._debug_action
		lines.append("[color=orange]#%d[/color] %s%s%s" % [i + 1, pos_str, hp_str, act_str])
	if enemies.size() > 6:
		lines.append("[color=gray]...还有 %d 只[/color]" % (enemies.size() - 6))

	label.text = "\n".join(lines)
