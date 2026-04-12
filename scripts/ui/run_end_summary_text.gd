extends RefCounted
class_name RunEndSummaryText

## 游戏结束 / 通关界面用的文本汇总
## 纯文本版用于剪贴板复制，BBCode 版用于界面显示

# ── 纯文本版（剪贴板复制用）─────────────────────────────────

static func format_character_line() -> String:
	var d: Dictionary = CharacterData.find_character(RunState.character_id)
	var disp: String = str(d.get("display_name", RunState.character_id))
	var cid: String = RunState.character_id
	return "【角色】%s（%s）" % [disp, cid]


static func format_choice_log() -> String:
	if RunState.run_choice_log.is_empty():
		return "【构筑记录】暂无记录（本局未在波间选强化 / 未购物 / 未弹升级，或来自旧存档）。"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【构筑记录】按获得顺序：")
	for e_raw in RunState.run_choice_log:
		if e_raw is Dictionary:
			lines.append("  · %s" % _format_one_log_entry(e_raw as Dictionary))
	return "\n".join(lines)


static func _format_one_log_entry(e: Dictionary) -> String:
	var kind: String = str(e.get("kind", ""))
	var w: int = int(e.get("wave", 0))
	var title: String = str(e.get("title", e.get("id", "?")))
	match kind:
		"wave_upgrade":
			return "第%d波后 · 三选一：%s" % [w, title]
		"shop":
			return "第%d波后 · 商店：%s" % [w, title]
		"level_up":
			var lv: int = int(e.get("player_level", 0))
			return "第%d波进行中 · 升至 Lv.%d：%s" % [w, lv, title]
		_:
			return title


static func format_weapons_block() -> String:
	if RunState.last_endgame_weapon_labels.is_empty():
		return "【武器栏】无"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【武器栏】")
	for w in RunState.last_endgame_weapon_labels:
		lines.append("  · %s" % str(w))
	return "\n".join(lines)


static func format_stats_block() -> String:
	var d: Dictionary = RunState.last_endgame_stats
	if d.is_empty():
		return "【属性】无战斗快照。"
	var plv: int = int(d.get("player_level", 1))
	var pxp: int = int(d.get("player_xp", 0))
	var need: int = 22 + plv * 16
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【等级与生命】")
	lines.append(
		"  Lv.%d  经验 %d / %d  生命 %d / %d"
		% [plv, pxp, need, int(d.get("current_hp", 0)), int(d.get("max_hp", 0))]
	)
	lines.append("【输出与机动】")
	lines.append(
		"  伤害×%.2f  攻速×%.2f  移速×%.2f  羁绊伤害×%.2f"
		% [
			float(d.get("stat_damage_mult", 1.0)),
			float(d.get("stat_fire_rate_mult", 1.0)),
			float(d.get("stat_move_speed_mult", 1.0)),
			float(d.get("stat_synergy_damage_mult", 1.0)),
		]
	)
	lines.append(
		"  拾取半径 +%.0f  攻击范围半径 +%.0f  生命回复 %.2f/s"
		% [
			float(d.get("stat_pickup_radius_bonus", 0.0)),
			float(d.get("stat_attack_range_bonus", 0.0)),
			float(d.get("stat_hp_regen_per_sec", 0.0)),
		]
	)
	lines.append("【经济与运气】")
	lines.append(
		"  收获 +%.2f  幸运 %d  商店标价×%.2f  材料转伤害 %.3f"
		% [
			float(d.get("stat_harvest", 0.0)),
			int(d.get("stat_luck", 0)),
			float(d.get("shop_price_mult", 1.0)),
			float(d.get("material_to_damage_kv", 0.0)),
		]
	)
	lines.append(
		"  暴击率 %.0f%%  暴击伤害×%.2f"
		% [float(d.get("stat_crit_chance", 0.05)) * 100.0, float(d.get("stat_crit_mult", 1.5))]
	)
	lines.append("【元素与异常】")
	lines.append(
		"  火焰伤害×%.2f  燃烧 DPS +%.2f"
		% [float(d.get("stat_fire_damage_mult", 1.0)), float(d.get("stat_burn_dps_flat", 0.0))]
	)
	lines.append(
		"  冰霜伤害×%.2f  冰缓时长 +%.2f"
		% [float(d.get("stat_ice_damage_mult", 1.0)), float(d.get("stat_ice_duration_bonus", 0.0))]
	)
	lines.append(
		"  毒素伤害×%.2f  毒 DOT +%.2f  毒时长 +%.0f%%"
		% [
			float(d.get("stat_poison_damage_mult", 1.0)),
			float(d.get("stat_poison_dps_flat", 0.0)),
			float(d.get("stat_poison_duration_pct", 0.0)) * 100.0,
		]
	)
	lines.append(
		"  电击伤害×%.2f  感电易伤 +%.3f"
		% [float(d.get("stat_shock_damage_mult", 1.0)), float(d.get("stat_shock_vuln_apply_flat", 0.0))]
	)
	return "\n".join(lines)


static func build_full_detail_section() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(format_character_line())
	parts.append("")
	parts.append(format_choice_log())
	parts.append("")
	parts.append(format_weapons_block())
	parts.append("")
	parts.append(format_stats_block())
	return "\n".join(parts)


# ── BBCode 富文本版（界面显示用）─────────────────────────────

static func _bb_sec(title: String, color: String) -> String:
	return "[color=%s][b]◆  %s[/b][/color]\n" % [color, title]


static func _bb_kv(label: String, value: String) -> String:
	return "[indent][color=#8a9898]%s[/color]  [color=#dce8e0]%s[/color][/indent]\n" % [label, value]


static func build_bbcode_section() -> String:
	var b: PackedStringArray = PackedStringArray()
	var d: Dictionary = RunState.last_endgame_stats
	var char_d: Dictionary = CharacterData.find_character(RunState.character_id)
	var char_name: String = str(char_d.get("display_name", RunState.character_id))
	b.append(_bb_sec("角色", "#c8a8f8"))
	b.append("[indent][color=#e0d4ff]%s[/color]  [color=#787888]%s[/color][/indent]\n\n" % [char_name, RunState.character_id])
	b.append(_bb_sec("武器栏", "#80d8a0"))
	if RunState.last_endgame_weapon_labels.is_empty():
		b.append("[indent][color=#606868]无[/color][/indent]\n\n")
	else:
		for w in RunState.last_endgame_weapon_labels:
			b.append("[indent][color=#b8e8c4]· %s[/color][/indent]\n" % str(w))
		b.append("\n")
	b.append(_bb_sec("构筑记录", "#f0d090"))
	if RunState.run_choice_log.is_empty():
		b.append("[indent][color=#888060]暂无记录[/color][/indent]\n\n")
	else:
		for e_raw in RunState.run_choice_log:
			if e_raw is Dictionary:
				b.append("[indent][color=#d8c870]· %s[/color][/indent]\n" % _format_one_log_entry(e_raw as Dictionary))
		b.append("\n")
	if d.is_empty():
		b.append("[color=#606868]无战斗属性快照。[/color]")
		return "".join(b)
	var plv: int = int(d.get("player_level", 1))
	var pxp: int = int(d.get("player_xp", 0))
	var need: int = 22 + plv * 16
	b.append(_bb_sec("等级与生命", "#f0a060"))
	b.append(_bb_kv("等级", "Lv.%d" % plv))
	b.append(_bb_kv("经验", "%d / %d" % [pxp, need]))
	b.append(_bb_kv("生命", "%d / %d" % [int(d.get("current_hp", 0)), int(d.get("max_hp", 0))]))
	b.append("\n")
	b.append(_bb_sec("输出与机动", "#f07878"))
	b.append(_bb_kv("伤害倍率", "×%.2f" % float(d.get("stat_damage_mult", 1.0))))
	b.append(_bb_kv("攻击速度", "×%.2f" % float(d.get("stat_fire_rate_mult", 1.0))))
	b.append(_bb_kv("移动速度", "×%.2f" % float(d.get("stat_move_speed_mult", 1.0))))
	b.append(_bb_kv("羁绊伤害", "×%.2f" % float(d.get("stat_synergy_damage_mult", 1.0))))
	b.append(_bb_kv("拾取半径", "+%.0f" % float(d.get("stat_pickup_radius_bonus", 0.0))))
	b.append(_bb_kv("攻击范围", "+%.0f" % float(d.get("stat_attack_range_bonus", 0.0))))
	b.append(_bb_kv("生命回复", "%.2f / 秒" % float(d.get("stat_hp_regen_per_sec", 0.0))))
	b.append("\n")
	b.append(_bb_sec("经济与运气", "#78c8f0"))
	b.append(_bb_kv("收获加成", "+%.2f" % float(d.get("stat_harvest", 0.0))))
	b.append(_bb_kv("幸运值", "%d" % int(d.get("stat_luck", 0))))
	b.append(_bb_kv("商店标价", "×%.2f" % float(d.get("shop_price_mult", 1.0))))
	b.append(_bb_kv("材料转伤害", "%.3f" % float(d.get("material_to_damage_kv", 0.0))))
	b.append(_bb_kv("暴击率", "%.0f%%" % (float(d.get("stat_crit_chance", 0.05)) * 100.0)))
	b.append(_bb_kv("暴击伤害", "×%.2f" % float(d.get("stat_crit_mult", 1.5))))
	b.append("\n")
	b.append(_bb_sec("元素与异常", "#c8c8ff"))
	b.append(_bb_kv(
		"[color=#ff9060]火[/color] 火焰",
		"伤害 ×%.2f   燃烧 %.2f/s" % [float(d.get("stat_fire_damage_mult", 1.0)), float(d.get("stat_burn_dps_flat", 0.0))]
	))
	b.append(_bb_kv(
		"[color=#80d0ff]冰[/color] 冰霜",
		"伤害 ×%.2f   冰缓 +%.2f 秒" % [float(d.get("stat_ice_damage_mult", 1.0)), float(d.get("stat_ice_duration_bonus", 0.0))]
	))
	b.append(_bb_kv(
		"[color=#80e860]毒[/color] 毒素",
		"伤害 ×%.2f   DOT +%.2f   时长 +%.0f%%" % [float(d.get("stat_poison_damage_mult", 1.0)), float(d.get("stat_poison_dps_flat", 0.0)), float(d.get("stat_poison_duration_pct", 0.0)) * 100.0]
	))
	b.append(_bb_kv(
		"[color=#d0a0ff]电[/color] 电击",
		"伤害 ×%.2f   易伤 +%.3f" % [float(d.get("stat_shock_damage_mult", 1.0)), float(d.get("stat_shock_vuln_apply_flat", 0.0))]
	))
	return "".join(b)
