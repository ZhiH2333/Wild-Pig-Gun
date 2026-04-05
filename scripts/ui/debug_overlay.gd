extends CanvasLayer

## 右上角调试控制台：每帧显示完整游戏数据
## 包含：玩家坐标、HP、无敌帧、速度、当前操作、
##        敌人数量、子弹数量、波次、FPS、帧时间

@onready var label: RichTextLabel = $DebugLabel

# 颜色常量
const C_TITLE  := "[color=#FFD700]"   # 金色标题
const C_KEY    := "[color=#88CCFF]"   # 蓝色键名
const C_VAL    := "[color=#FFFFFF]"   # 白色数值
const C_WARN   := "[color=#FF6666]"   # 红色警告
const C_OK     := "[color=#66FF88]"   # 绿色正常
const C_DIM    := "[color=#888888]"   # 灰色次要信息
const C_END    := "[/color]"

var _frame_count: int = 0
var _fps_accum: float = 0.0
var _fps_display: float = 0.0


func _process(delta: float) -> void:
	_frame_count += 1
	_fps_accum += delta
	if _fps_accum >= 0.25:
		_fps_display = _frame_count / _fps_accum
		_frame_count = 0
		_fps_accum = 0.0

	label.text = _build_text(delta)


func _build_text(delta: float) -> String:
	var lines: PackedStringArray = []

	# ── 标题栏 ──────────────────────────────────────
	lines.append(C_TITLE + "▌ DEBUG CONSOLE" + C_END)
	lines.append(C_DIM + "─────────────────────" + C_END)

	# ── 性能 ────────────────────────────────────────
	lines.append(C_TITLE + "[ 性能 ]" + C_END)
	var fps_color := C_OK if _fps_display >= 55 else (C_WARN if _fps_display < 30 else C_VAL)
	lines.append(_kv("FPS", fps_color + "%.1f" % _fps_display + C_END))
	lines.append(_kv("帧时间", "%.2f ms" % (delta * 1000.0)))
	lines.append("")

	# ── 玩家 ────────────────────────────────────────
	lines.append(C_TITLE + "[ 玩家 ]" + C_END)
	var player := _get_player()
	if player:
		var hp: int     = player.get("current_hp") if "current_hp" in player else -1
		var max_hp: int = player.get("max_hp")     if "max_hp"     in player else -1
		var inv: bool   = player.get("is_invincible") if "is_invincible" in player else false
		var pos: Vector2 = player.global_position
		var vel: Vector2 = player.velocity if "velocity" in player else Vector2.ZERO
		var action: String = player.get("_debug_action") if "_debug_action" in player else "—"

		var hp_color := C_OK if hp > max_hp * 0.5 else (C_WARN if hp > 0 else "[color=#FF0000]")
		lines.append(_kv("坐标", "(%.0f, %.0f)" % [pos.x, pos.y]))
		lines.append(_kv("速度", "(%.0f, %.0f)" % [vel.x, vel.y]))
		lines.append(_kv("HP", hp_color + "%d / %d" % [hp, max_hp] + C_END))
		lines.append(_kv("无敌帧", (C_WARN + "是" + C_END) if inv else (C_DIM + "否" + C_END)))
		lines.append(_kv("当前操作", action))
	else:
		lines.append(C_WARN + "  玩家节点未找到" + C_END)
	lines.append("")

	# ── 场景对象 ─────────────────────────────────────
	lines.append(C_TITLE + "[ 场景对象 ]" + C_END)
	var enemies    := get_tree().get_nodes_in_group("enemies")
	var projectiles := _get_projectile_container()
	var proj_count := projectiles.get_child_count() if projectiles else 0
	lines.append(_kv("敌人数量", str(enemies.size())))
	lines.append(_kv("子弹数量", str(proj_count)))
	lines.append("")

	# ── RunState ─────────────────────────────────────
	lines.append(C_TITLE + "[ RunState ]" + C_END)
	var rs := _get_run_state()
	if rs:
		lines.append(_kv("波次", str(rs.get("wave_index") if "wave_index" in rs else "—")))
		lines.append(_kv("材料", str(rs.get("material_current") if "material_current" in rs else "—")))
		lines.append(_kv("元进度金币", str(rs.get("gold") if "gold" in rs else "—")))
	else:
		lines.append(C_DIM + "  RunState 未加载" + C_END)
	lines.append("")

	# ── 步骤追踪 ─────────────────────────────────────
	lines.append(C_TITLE + "[ 每步数据 ]" + C_END)
	lines.append(_kv("物理帧", str(Engine.get_physics_frames())))
	lines.append(_kv("进程帧", str(Engine.get_process_frames())))
	lines.append(_kv("运行时间", "%.1f s" % (Time.get_ticks_msec() * 0.001)))

	return "\n".join(lines)


func _kv(key: String, val: String) -> String:
	return C_KEY + "  " + key + ": " + C_END + C_VAL + val + C_END


func _get_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func _get_projectile_container() -> Node:
	var root := get_tree().get_root()
	var arena := root.get_node_or_null("Arena")
	if arena:
		return arena.get_node_or_null("ProjectileContainer")
	return null


func _get_run_state() -> Node:
	return get_node_or_null("/root/RunState")
