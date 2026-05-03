extends CanvasLayer

## 战斗 HUD：血条、波次计时条、属性条、武器槽、羁绊提示、左下角角色立绘与状态

const WEAPON_SLOT_SCENE: PackedScene = preload("res://scenes/ui/weapon_slot.tscn")

@onready var left_top_panel: Control = $LeftTopPanel
@onready var top_center_panel: Control = $TopCenterPanel
@onready var right_top_panel: Control = $RightTopPanel
@onready var left_bottom_panel: Control = $LeftBottomPanel

@onready var hp_bar: ProgressBar = $LeftTopPanel/HPBar
@onready var hp_label: Label = $LeftTopPanel/HPLabel
@onready var stat_strip: StatStrip = $LeftTopPanel/StatStrip
@onready var weapon_row: HBoxContainer = $LeftTopPanel/WeaponRow

@onready var char_portrait_texture: TextureRect = $LeftBottomPanel/CharDockRow/CharPortraitPanel/PortraitMargins/CharPortraitTexture
@onready var char_portrait_panel: PanelContainer = $LeftBottomPanel/CharDockRow/CharPortraitPanel
@onready var dock_hp_bar: ProgressBar = $LeftBottomPanel/CharDockRow/CharDockBars/DockHpRow/DockHpBar
@onready var dock_hp_val: Label = $LeftBottomPanel/CharDockRow/CharDockBars/DockHpRow/DockHpVal
@onready var dock_armor_bar: ProgressBar = $LeftBottomPanel/CharDockRow/CharDockBars/DockArmorRow/DockArmorBar
@onready var dock_armor_val: Label = $LeftBottomPanel/CharDockRow/CharDockBars/DockArmorRow/DockArmorVal
@onready var status_icons_row: HBoxContainer = $LeftBottomPanel/CharDockRow/CharDockBars/StatusIconsRow

@onready var wave_label: Label = $TopCenterPanel/WaveLabel
@onready var wave_timer_bar: ProgressBar = $TopCenterPanel/WaveTimerBar
@onready var timer_label: Label = $TopCenterPanel/TimerLabel

@onready var material_label: Label = $RightTopPanel/MaterialLabel
@onready var savings_label: Label = $RightTopPanel/SavingsLabel
@onready var level_xp_label: Label = $RightTopPanel/LevelXpLabel
@onready var toast_label: Label = $RightTopPanel/ToastLabel
@onready var fps_label: Label = $FpsLabel

var _toast_left: float = 0.0
var _player: Node = null
var _wave_duration: float = 30.0
var _weapon_slots: Array[WeaponSlot] = []
var _last_status_mask: int = -1


func _ready() -> void:
	# 节点空值检查
	if left_top_panel == null:
		push_error("[HUD] left_top_panel 节点路径失效")
	if top_center_panel == null:
		push_error("[HUD] top_center_panel 节点路径失效")
	if right_top_panel == null:
		push_error("[HUD] right_top_panel 节点路径失效")
	if hp_bar == null:
		push_error("[HUD] hp_bar 节点路径失效，跳过血条更新")
	if hp_label == null:
		push_error("[HUD] hp_label 节点路径失效，跳过血量文字")
	if wave_label == null:
		push_error("[HUD] wave_label 节点路径失效，跳过波次显示")
	if wave_timer_bar == null:
		push_error("[HUD] wave_timer_bar 节点路径失效，跳过计时条")
	if timer_label == null:
		push_error("[HUD] timer_label 节点路径失效，跳过计时文字")
	if stat_strip == null:
		push_error("[HUD] stat_strip 节点路径失效，跳过属性条")
	if weapon_row == null:
		push_error("[HUD] weapon_row 节点路径失效，跳过武器槽")
	if material_label == null:
		push_error("[HUD] material_label 节点路径失效，跳过材料显示")
	if savings_label == null:
		push_error("[HUD] savings_label 节点路径失效，跳过储蓄显示")
	if level_xp_label == null:
		push_error("[HUD] level_xp_label 节点路径失效，跳过等级显示")
	if toast_label == null:
		push_error("[HUD] toast_label 节点路径失效，跳过提示显示")
	if fps_label == null:
		push_error("[HUD] fps_label 节点路径失效，跳过 FPS 显示")

	_apply_platform_margins()

	RunState.wave_changed.connect(_on_wave_changed)
	RunState.material_changed.connect(_on_material_changed)
	RunState.xp_changed.connect(_on_xp_changed)
	if not GameSettings.show_fps_changed.is_connected(_on_show_fps_changed):
		GameSettings.show_fps_changed.connect(_on_show_fps_changed)
	_on_wave_changed(RunState.wave_index)
	_on_material_changed(RunState.material_current, RunState.material_savings)
	_on_xp_changed(RunState.player_level, RunState.player_xp, RunState.xp_to_next_level())
	_on_show_fps_changed(GameSettings.show_fps)

	if timer_label != null:
		timer_label.visible = false
	if wave_timer_bar != null:
		wave_timer_bar.visible = false
	_setup_timer_bar_fill_style()
	_setup_char_dock_visuals()


func _apply_platform_margins() -> void:
	if OS.get_name() == "Android":
		if left_top_panel != null:
			left_top_panel.offset_left = 60
			left_top_panel.offset_top = 56
		if top_center_panel != null:
			top_center_panel.offset_top = 56
		if right_top_panel != null:
			right_top_panel.offset_right = -60
			right_top_panel.offset_top = 56
		if left_bottom_panel != null:
			left_bottom_panel.offset_left = 56.0
			left_bottom_panel.offset_bottom = -20.0


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			if toast_label != null:
				toast_label.visible = false
	if fps_label != null and fps_label.visible:
		fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	_refresh_char_dock_runtime()


func _setup_timer_bar_fill_style() -> void:
	if wave_timer_bar == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.92, 0.72, 0.28, 1)
	sb.set_corner_radius_all(6)
	wave_timer_bar.add_theme_stylebox_override("fill", sb)


func _setup_char_dock_visuals() -> void:
	if char_portrait_panel != null:
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.07, 0.06, 0.11, 0.94)
		frame.set_border_width_all(2)
		frame.border_color = Color(0.58, 0.38, 0.92, 1.0)
		frame.set_corner_radius_all(12)
		char_portrait_panel.add_theme_stylebox_override("panel", frame)
	if dock_hp_bar != null:
		_apply_dock_bar_styles(dock_hp_bar, Color(0.88, 0.24, 0.22, 1.0))
	if dock_armor_bar != null:
		_apply_dock_bar_styles(dock_armor_bar, Color(0.45, 0.78, 0.98, 1.0))


func _apply_dock_bar_styles(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.11, 0.15, 0.92)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


func setup(player: Node) -> void:
	_player = player
	if weapon_row != null:
		_build_weapon_slots()
	if player != null and player.has_signal("hp_changed"):
		if not player.hp_changed.is_connected(_on_hp_changed):
			player.hp_changed.connect(_on_hp_changed)
		if "current_hp" in player and "max_hp" in player:
			_on_hp_changed(player.current_hp, player.max_hp)
	if player != null and player.has_signal("synergy_changed"):
		if not player.synergy_changed.is_connected(_on_synergy_changed):
			player.synergy_changed.connect(_on_synergy_changed)
	var lo: Node = player.get_node_or_null("WeaponLoadout") if player != null else null
	if lo != null and lo.has_signal("loadout_updated"):
		if not lo.loadout_updated.is_connected(refresh_weapon_slots):
			lo.loadout_updated.connect(refresh_weapon_slots)
	refresh_weapon_slots()
	_refresh_stats()
	_apply_character_portrait_texture()
	if _player != null and "current_hp" in _player and "max_hp" in _player:
		_update_char_dock_hp(_player.current_hp, _player.max_hp)


func _apply_character_portrait_texture() -> void:
	if char_portrait_texture == null:
		return
	var ch: Dictionary = CharacterData.find_character(str(RunState.character_id))
	var path: String = str(ch.get("sprite_path", "res://assets/sprites/wildpig.png"))
	if not ResourceLoader.exists(path):
		char_portrait_texture.texture = null
		return
	var tex: Texture2D = load(path) as Texture2D
	char_portrait_texture.texture = tex


func _update_char_dock_hp(current: int, maximum: int) -> void:
	if dock_hp_bar == null or dock_hp_val == null:
		return
	var mx: int = maxi(1, maximum)
	dock_hp_bar.max_value = float(mx)
	dock_hp_bar.value = clampi(current, 0, mx)
	dock_hp_val.text = str(clampi(current, 0, mx))


func _refresh_char_dock_armor_bar() -> void:
	if dock_armor_bar == null or dock_armor_val == null or _player == null:
		return
	var inv: bool = bool(_player.get("is_invincible"))
	var timer: Timer = _player.get_node_or_null("InvincibilityTimer") as Timer
	if inv and timer != null and timer.time_left > 0.0001:
		var w: float = maxf(0.001, timer.wait_time)
		var pct: float = clampf(timer.time_left / w, 0.0, 1.0) * 100.0
		dock_armor_bar.max_value = 100.0
		dock_armor_bar.value = pct
		dock_armor_val.text = str(int(round(pct)))
	else:
		dock_armor_bar.max_value = 100.0
		dock_armor_bar.value = 0.0
		dock_armor_val.text = "0"


func _compute_char_dock_status_mask() -> int:
	if _player == null:
		return 0
	var m: int = 0
	if bool(_player.get("is_invincible")):
		m |= 1
	if float(_player.get("stat_synergy_damage_mult")) > 1.02:
		m |= 2
	if float(_player.get("stat_burn_dps_flat")) > 0.02 or float(_player.get("stat_fire_damage_mult")) > 1.08:
		m |= 4
	if float(_player.get("stat_hp_regen_per_sec")) > 0.02:
		m |= 8
	if float(_player.get("stat_poison_dps_flat")) > 0.02:
		m |= 16
	if float(_player.get("stat_ice_damage_mult")) > 1.08:
		m |= 32
	if float(_player.get("stat_shock_vuln_apply_flat")) > 0.01:
		m |= 64
	return m


func _rebuild_char_dock_status_icons(mask: int) -> void:
	if status_icons_row == null:
		return
	for c in status_icons_row.get_children():
		c.queue_free()
	if (mask & 1) != 0:
		status_icons_row.add_child(_make_status_chip("🛡", Color(0.22, 0.32, 0.38, 1.0)))
	if (mask & 2) != 0:
		status_icons_row.add_child(_make_status_chip("羁", Color(0.38, 0.28, 0.52, 1.0)))
	if (mask & 4) != 0:
		status_icons_row.add_child(_make_status_chip("🔥", Color(0.42, 0.22, 0.12, 1.0)))
	if (mask & 8) != 0:
		status_icons_row.add_child(_make_status_chip("💚", Color(0.15, 0.35, 0.22, 1.0)))
	if (mask & 16) != 0:
		status_icons_row.add_child(_make_status_chip("☠", Color(0.28, 0.38, 0.2, 1.0)))
	if (mask & 32) != 0:
		status_icons_row.add_child(_make_status_chip("❄", Color(0.18, 0.32, 0.48, 1.0)))
	if (mask & 64) != 0:
		status_icons_row.add_child(_make_status_chip("⚡", Color(0.35, 0.35, 0.22, 1.0)))


func _make_status_chip(symbol: String, bg: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(34, 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(8)
	chip.add_theme_stylebox_override("panel", sb)
	var ce := CenterContainer.new()
	var l := Label.new()
	l.text = symbol
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 17 if symbol.length() <= 1 else 14)
	l.add_theme_color_override("font_color", Color(0.96, 0.95, 0.92, 1.0))
	ce.add_child(l)
	chip.add_child(ce)
	return chip


func _refresh_char_dock_runtime() -> void:
	if _player == null or dock_armor_bar == null:
		return
	_refresh_char_dock_armor_bar()
	var m: int = _compute_char_dock_status_mask()
	if m != _last_status_mask:
		_last_status_mask = m
		_rebuild_char_dock_status_icons(m)


func _build_weapon_slots() -> void:
	if weapon_row == null:
		return
	for c in weapon_row.get_children():
		c.queue_free()
	_weapon_slots.clear()
	for i in range(6):
		var ws: WeaponSlot = WEAPON_SLOT_SCENE.instantiate() as WeaponSlot
		ws.custom_minimum_size = Vector2(108, 48)
		weapon_row.add_child(ws)
		_weapon_slots.append(ws)


func refresh_weapon_slots() -> void:
	if _player == null:
		return
	var lo: Node = _player.get_node_or_null("WeaponLoadout")
	if lo == null:
		return
	var ids: Array[String] = []
	for c in lo.get_children():
		if "weapon_id" in c:
			ids.append(str(c.weapon_id))
	for i in range(_weapon_slots.size()):
		if i < ids.size():
			_weapon_slots[i].set_weapon(ids[i])
		else:
			_weapon_slots[i].clear_slot()
	_last_status_mask = -1


func _refresh_stats() -> void:
	if stat_strip != null and _player != null:
		stat_strip.refresh_from_player(_player)


func refresh_player_stats() -> void:
	_refresh_stats()
	_last_status_mask = -1
	_refresh_char_dock_runtime()


func on_wave_timer_reset(duration_sec: float) -> void:
	if wave_timer_bar == null:
		return
	_wave_duration = maxf(0.001, duration_sec)
	wave_timer_bar.max_value = _wave_duration
	wave_timer_bar.value = _wave_duration
	wave_timer_bar.visible = true


func _on_synergy_changed(mult: float, tags: Array) -> void:
	_last_status_mask = -1
	if tags.is_empty():
		return
	var parts: PackedStringArray = PackedStringArray()
	for t in tags:
		parts.append(_tag_display(str(t)))
	show_toast("羁绊 [%s] 伤害×%.2f" % [",".join(parts), mult], 3.2)


func _tag_display(tag: String) -> String:
	match tag:
		"heavy":
			return "重型"
		"light":
			return "轻型"
		"melee":
			return "近战"
		_:
			return tag


func show_toast(msg: String, duration: float = 2.8) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.visible = true
	_toast_left = duration


func _on_hp_changed(current: int, maximum: int) -> void:
	if hp_label != null:
		hp_label.text = "%d / %d" % [current, maximum]
	if hp_bar != null:
		hp_bar.max_value = maxi(1, maximum)
		hp_bar.value = clampi(current, 0, maximum)
	_update_char_dock_hp(current, maximum)
	_refresh_stats()


func _on_wave_changed(wave_index: int) -> void:
	if wave_label == null:
		return
	wave_label.text = "第 %d 波" % wave_index


func on_wave_timer_tick(remaining: float) -> void:
	if timer_label != null:
		timer_label.visible = true
		timer_label.text = "剩余 %d 秒" % int(ceil(remaining))
	if wave_timer_bar != null:
		wave_timer_bar.visible = true
		wave_timer_bar.value = clampf(remaining, 0.0, _wave_duration)


func on_wave_ended() -> void:
	if timer_label != null:
		timer_label.visible = false
	if wave_timer_bar != null:
		wave_timer_bar.visible = false


func _on_material_changed(current: int, savings: int) -> void:
	if material_label != null:
		material_label.text = "野猪币 %d" % current
	if savings_label != null:
		if savings > 0:
			savings_label.text = "储蓄 %d (下波×2)" % savings
			savings_label.visible = true
		else:
			savings_label.visible = false
	_refresh_stats()


func _on_xp_changed(level: int, xp: int, need: int) -> void:
	if level_xp_label != null:
		level_xp_label.text = "Lv.%d  XP %d/%d" % [level, xp, need]
	_refresh_stats()


func show_harvest_toast(bonus: int) -> void:
	if bonus <= 0:
		return
	show_toast("收获 +%d 野猪币" % bonus, 2.8)


func _on_show_fps_changed(enabled: bool) -> void:
	if fps_label == null:
		return
	fps_label.visible = enabled
