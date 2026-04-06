extends CanvasLayer

## 三击 Z 开关的调试浮窗：系统无衬线字体、仅面板拦截鼠标，键盘不影响走位逻辑

const TRIPLE_Z_WINDOW_MS: int = 500
## 调试条目中多数数值的上限（原若干倍率项误设为 5）
const DEBUG_SPIN_MAX_FLOAT: float = 9999.0
const DEBUG_SPIN_MAX_INT: int = 9999
const DEBUG_SPIN_MAX_HP: int = 99999

var _font_names: PackedStringArray = PackedStringArray([
	"PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Segoe UI",
	"Helvetica Neue", "Noto Sans CJK SC", "sans-serif",
])
var _arena: Node2D = null
var _z_taps: int = 0
var _z_last_ms: int = 0
var _ui_font: Font
var _panel: PanelContainer
var _stats_label: RichTextLabel
var _god_check: CheckBox
var _enemy_pick: OptionButton
var _syncing: bool = false
var _fps_frames: int = 0
var _fps_accum: float = 0.0
var _fps_show: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sf := SystemFont.new()
	sf.font_names = _font_names
	sf.font_weight = 400
	sf.generate_mipmaps = false
	_ui_font = sf
	# 子节点 _ready 先于父节点 Arena：此时父节点尚未 add_to_group("arena")，
	# 不能仅靠分组解析，否则 _arena 为空会导致无法生成敌人。
	var p: Node = get_parent()
	if p != null and p is Node2D and p.has_method("debug_spawn_enemy_at"):
		_arena = p as Node2D
	elif p != null and p.is_in_group("arena"):
		_arena = p as Node2D
	else:
		_arena = get_tree().get_first_node_in_group("arena") as Node2D
	_build_ui()
	_panel.visible = false


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_fps_frames += 1
	_fps_accum += delta
	if _fps_accum >= 0.25:
		_fps_show = _fps_frames / _fps_accum
		_fps_frames = 0
		_fps_accum = 0.0
	_refresh_stats_text()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var ek: InputEventKey = event as InputEventKey
	if not ek.pressed or ek.echo:
		return
	if ek.physical_keycode != KEY_Z:
		return
	if not _should_accept_debug_hotkey():
		return
	var now: int = Time.get_ticks_msec()
	if now - _z_last_ms > TRIPLE_Z_WINDOW_MS:
		_z_taps = 0
	_z_last_ms = now
	_z_taps += 1
	if _z_taps >= 3:
		_z_taps = 0
		_toggle_panel()
		get_viewport().set_input_as_handled()


func _should_accept_debug_hotkey() -> bool:
	var fo: Control = get_viewport().gui_get_focus_owner() as Control
	if fo is LineEdit:
		return false
	return true


func _toggle_panel() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_sync_ui_from_game()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 20)
	_panel.custom_minimum_size = Vector2(440, 560)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.08, 0.11, 0.92)
	ps.border_color = Color(0.25, 0.28, 0.38)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(10)
	ps.content_margin_left = 14
	ps.content_margin_top = 12
	ps.content_margin_right = 14
	ps.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", ps)
	root.add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_panel.add_child(outer)
	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = "调试菜单（三击 Z）"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(_on_close_pressed)
	title_row.add_child(close_btn)
	outer.add_child(title_row)
	_god_check = CheckBox.new()
	_god_check.text = "无敌模式（免疫伤害）"
	_god_check.toggled.connect(_on_god_toggled)
	outer.add_child(_god_check)
	var sep := HSeparator.new()
	outer.add_child(sep)
	var stats_title := Label.new()
	stats_title.text = "实时参数"
	stats_title.add_theme_font_size_override("font_size", 15)
	outer.add_child(stats_title)
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = true
	_stats_label.custom_minimum_size = Vector2(0, 120)
	_stats_label.add_theme_font_size_override("normal_font_size", 13)
	_stats_label.add_theme_font_override("normal_font", _ui_font)
	outer.add_child(_stats_label)
	var sep2 := HSeparator.new()
	outer.add_child(sep2)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 6)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	_add_section_label(form, "玩家属性")
	_add_spin(form, "生命上限", "max_hp", 1, DEBUG_SPIN_MAX_HP, 1, true)
	_add_spin(form, "当前生命", "current_hp", 0, DEBUG_SPIN_MAX_HP, 1, true)
	_add_spin(form, "伤害倍率", "stat_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "移速倍率", "stat_move_speed_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "射速倍率", "stat_fire_rate_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "拾取半径加成", "stat_pickup_radius_bonus", 0.0, DEBUG_SPIN_MAX_FLOAT, 1.0, false)
	_add_spin(form, "攻击范围加成", "stat_attack_range_bonus", 0.0, DEBUG_SPIN_MAX_FLOAT, 4.0, false)
	_add_spin(form, "暴击率", "stat_crit_chance", 0.0, 1.0, 0.01, false)
	_add_spin(form, "暴击倍率", "stat_crit_mult", 1.0, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "羁绊伤害倍率", "stat_synergy_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "生命回复/秒", "stat_hp_regen_per_sec", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.1, false)
	_add_spin(form, "幸运", "stat_luck", 0, DEBUG_SPIN_MAX_INT, 1, true)
	_add_spin(form, "材料转伤系数", "material_to_damage_kv", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.0001, false)
	_add_spin(form, "收获加成", "stat_harvest", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "商店价格倍率", "shop_price_mult", 0.1, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "火焰伤害倍率", "stat_fire_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "冰霜伤害倍率", "stat_ice_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "毒素伤害倍率", "stat_poison_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "电击伤害倍率", "stat_shock_damage_mult", 0.05, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "燃烧 DPS 加成", "stat_burn_dps_flat", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.1, false)
	_add_spin(form, "冰缓时长加成", "stat_ice_duration_bonus", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.1, false)
	_add_spin(form, "毒素 DPS 加成", "stat_poison_dps_flat", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.1, false)
	_add_spin(form, "毒素时长 %", "stat_poison_duration_pct", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.05, false)
	_add_spin(form, "感电易伤加成", "stat_shock_vuln_apply_flat", 0.0, DEBUG_SPIN_MAX_FLOAT, 0.01, false)
	_add_section_label(form, "局内状态 (RunState)")
	_add_spin_rs(form, "当前材料", "material_current", 0, 999999, 1, true)
	_add_spin_rs(form, "储蓄材料", "material_savings", 0, 999999, 1, true)
	_add_spin_rs(form, "元进度金币", "gold", 0, 9999999, 1, true)
	_add_spin_rs(form, "风险倍率", "run_risk_mult", 1.0, 1.5, 0.01, false)
	var sep3 := HSeparator.new()
	outer.add_child(sep3)
	var spawn_row := HBoxContainer.new()
	spawn_row.add_theme_constant_override("separation", 8)
	var spawn_lab := Label.new()
	spawn_lab.text = "生成敌人"
	spawn_lab.custom_minimum_size.x = 72
	spawn_row.add_child(spawn_lab)
	_enemy_pick = OptionButton.new()
	_enemy_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pair in _enemy_type_options():
		_enemy_pick.add_item(pair[1])
		_enemy_pick.set_item_metadata(_enemy_pick.item_count - 1, pair[0])
	spawn_row.add_child(_enemy_pick)
	var spawn_btn := Button.new()
	spawn_btn.text = "在玩家右侧生成"
	spawn_btn.pressed.connect(_on_spawn_enemy_pressed)
	spawn_row.add_child(spawn_btn)
	outer.add_child(spawn_row)
	_apply_font(_panel)


func _enemy_type_options() -> Array:
	return [
		["basic", "普通"],
		["dash", "冲刺"],
		["ranged", "远程"],
		["elite", "精英"],
		["tree", "树怪"],
		["looter", "掠夺者"],
		["buff", "增益"],
		["trap", "陷阱"],
		["splitter", "分裂"],
		["charger", "冲锋者"],
		["shield", "护盾"],
		["boss_pig", "Boss 猪"],
	]


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 14)
	parent.add_child(lb)
	_apply_font(lb)


func _add_spin(parent: VBoxContainer, title: String, prop: String, mn: float, mx: float, step: float, as_int: bool) -> void:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = title
	lab.custom_minimum_size.x = 118
	row.add_child(lab)
	_apply_font(lab)
	var sp := SpinBox.new()
	sp.min_value = mn
	sp.max_value = mx
	sp.step = step
	sp.update_on_text_changed = true
	sp.custom_minimum_size.x = 160
	if as_int:
		sp.rounded = true
	sp.value_changed.connect(_on_player_spin_changed.bind(prop, as_int))
	row.add_child(sp)
	_apply_font(sp)
	parent.add_child(row)
	sp.set_meta("prop_key", prop)


func _add_spin_rs(parent: VBoxContainer, title: String, prop: String, mn: float, mx: float, step: float, as_int: bool) -> void:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = title
	lab.custom_minimum_size.x = 118
	row.add_child(lab)
	_apply_font(lab)
	var sp := SpinBox.new()
	sp.min_value = mn
	sp.max_value = mx
	sp.step = step
	sp.update_on_text_changed = true
	sp.custom_minimum_size.x = 160
	if as_int:
		sp.rounded = true
	sp.value_changed.connect(_on_runstate_spin_changed.bind(prop, as_int))
	sp.set_meta("runstate_prop", prop)
	row.add_child(sp)
	_apply_font(sp)
	parent.add_child(row)


func _apply_font(n: Control) -> void:
	n.add_theme_font_override("font", _ui_font)
	for c in n.get_children():
		if c is Control:
			_apply_font(c as Control)


func _on_close_pressed() -> void:
	_panel.visible = false


func _on_god_toggled(on: bool) -> void:
	var pl: Node = _get_player()
	if pl != null and "debug_god_mode" in pl:
		pl.debug_god_mode = on


func _on_player_spin_changed(value: float, prop: String, as_int: bool) -> void:
	if _syncing:
		return
	var pl: Node = _get_player()
	if pl == null or not prop in pl:
		return
	if as_int:
		pl.set(prop, int(round(value)))
	else:
		pl.set(prop, value)
	if prop == "stat_crit_chance" and "stat_crit_chance" in pl:
		pl.stat_crit_chance = clampf(pl.stat_crit_chance, 0.0, 1.0)
	if prop == "max_hp" or prop == "current_hp":
		if pl.current_hp > pl.max_hp:
			pl.current_hp = pl.max_hp
		if pl.has_signal("hp_changed"):
			pl.emit_signal("hp_changed", pl.current_hp, pl.max_hp)
	elif prop == "stat_attack_range_bonus":
		_refresh_hud_stats_after_debug_spin()


func _on_runstate_spin_changed(value: float, prop: String, as_int: bool) -> void:
	if _syncing:
		return
	var rs: Node = get_node_or_null("/root/RunState")
	if rs == null or not prop in rs:
		return
	if prop == "run_risk_mult":
		rs.set(prop, clampf(value, 1.0, 1.5))
	elif as_int:
		rs.set(prop, int(round(value)))
	else:
		rs.set(prop, value)
	if prop == "material_current" or prop == "material_savings":
		if rs.has_signal("material_changed"):
			rs.emit_signal("material_changed", rs.material_current, rs.material_savings)


func _on_spawn_enemy_pressed() -> void:
	if _arena == null or not _arena.has_method("debug_spawn_enemy_at"):
		return
	var idx: int = _enemy_pick.selected
	var tid: Variant = _enemy_pick.get_item_metadata(idx)
	if tid == null:
		return
	var pl: Node2D = _get_player() as Node2D
	var pos: Vector2 = Vector2(960, 540)
	if pl != null:
		pos = pl.global_position + Vector2(140, 0)
	_arena.debug_spawn_enemy_at(str(tid), pos)


func _refresh_hud_stats_after_debug_spin() -> void:
	if _arena == null:
		return
	var hud: Node = _arena.get_node_or_null("HUD")
	if hud != null and hud.has_method("refresh_player_stats"):
		hud.refresh_player_stats()


func _get_player() -> Node:
	if _arena != null:
		var p: Node = _arena.get_node_or_null("Player")
		if p != null:
			return p
	var g: Array[Node] = get_tree().get_nodes_in_group("player")
	return g[0] if g.size() > 0 else null


func _sync_ui_from_game() -> void:
	_syncing = true
	var pl: Node = _get_player()
	var rs: Node = get_node_or_null("/root/RunState")
	if pl != null and "debug_god_mode" in pl:
		_god_check.set_pressed_no_signal(pl.debug_god_mode as bool)
	for sp in _iter_spinboxes(_panel):
		if sp.has_meta("prop_key") and pl != null:
			var pk: String = str(sp.get_meta("prop_key"))
			if not pk.is_empty() and pk in pl:
				sp.value = float(pl.get(pk))
		elif sp.has_meta("runstate_prop") and rs != null:
			var rk: String = str(sp.get_meta("runstate_prop"))
			if not rk.is_empty() and rk in rs:
				sp.value = float(rs.get(rk))
	_syncing = false
	_refresh_stats_text()


func _iter_spinboxes(from: Node) -> Array[SpinBox]:
	var acc: Array[SpinBox] = []
	_collect_spinboxes(from, acc)
	return acc


func _collect_spinboxes(n: Node, acc: Array[SpinBox]) -> void:
	if n is SpinBox:
		acc.append(n as SpinBox)
	for ch in n.get_children():
		_collect_spinboxes(ch, acc)


func _refresh_stats_text() -> void:
	var pl: Node = _get_player()
	var rs: Node = get_node_or_null("/root/RunState")
	var wm: Node = null
	if _arena != null:
		wm = _arena.get_node_or_null("WaveManager")
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]性能[/b]  FPS: %.1f" % _fps_show)
	if pl != null:
		var pos: Vector2 = pl.global_position
		var vel: Vector2 = pl.velocity if "velocity" in pl else Vector2.ZERO
		lines.append("[b]玩家[/b]  位置 (%.0f, %.0f)  速度 (%.0f, %.0f)" % [pos.x, pos.y, vel.x, vel.y])
		var hp: int = int(pl.get("current_hp")) if "current_hp" in pl else -1
		var mx: int = int(pl.get("max_hp")) if "max_hp" in pl else -1
		var inv: String = "是" if ("is_invincible" in pl and pl.is_invincible) else "否"
		lines.append("HP %d / %d   无敌帧 %s" % [hp, mx, inv])
		if "_debug_action" in pl:
			lines.append("动作 %s" % str(pl.get("_debug_action")))
		if pl.has_method("get_attack_range_radius"):
			var ar: float = float(pl.call("get_attack_range_radius"))
			var ab: float = float(pl.get("stat_attack_range_bonus")) if "stat_attack_range_bonus" in pl else 0.0
			lines.append("攻击范围半径 %.0f（基础+加成，加成 %.0f）" % [ar, ab])
	var ec: int = get_tree().get_nodes_in_group("enemies").size()
	var pc: int = 0
	if _arena != null:
		var cont: Node = _arena.get_node_or_null("ProjectileContainer")
		if cont != null:
			pc = cont.get_child_count()
	lines.append("[b]场景[/b]  敌人 %d  子弹 %d" % [ec, pc])
	if rs != null:
		var wv: int = int(rs.get("wave_index")) if "wave_index" in rs else -1
		var mat: int = int(rs.get("material_current")) if "material_current" in rs else 0
		var sav: int = int(rs.get("material_savings")) if "material_savings" in rs else 0
		var lv: int = int(rs.get("player_level")) if "player_level" in rs else 1
		var xp: int = int(rs.get("player_xp")) if "player_xp" in rs else 0
		lines.append("[b]Run[/b]  波次 %d  等级 %d  XP %d  材料 %d 储蓄 %d" % [wv, lv, xp, mat, sav])
	if wm != null:
		var active: bool = bool(wm.get("is_wave_active")) if "is_wave_active" in wm else false
		var cw: int = int(wm.get("current_wave")) if "current_wave" in wm else 0
		var left: float = 0.0
		if wm.get_node_or_null("WaveTimer") is Timer:
			left = (wm.get_node("WaveTimer") as Timer).time_left
		var act_txt: String = "是" if active else "否"
		lines.append("[b]波次管理[/b]  当前波 %d  进行中 %s  剩余 %.1fs" % [cw, act_txt, left])
	_stats_label.text = "\n".join(lines)
