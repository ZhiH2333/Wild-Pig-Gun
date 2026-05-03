extends Node

## 战斗中每秒在控制台输出性能与战斗汇总（调试用）。
## 将 PERF_LOG_ENABLED 设为 false 可完全关闭。

const PERF_LOG_ENABLED: bool = true

var _acc_player_damage_taken: int = 0
var _acc_damage_to_enemies: int = 0
var _tick_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not PERF_LOG_ENABLED:
		return
	if DisplayServer.get_name() == "headless":
		return
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.one_shot = false
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_second_tick)
	add_child(_tick_timer)


func record_player_damage_taken(amount: int) -> void:
	if not PERF_LOG_ENABLED:
		return
	_acc_player_damage_taken += maxi(0, amount)


func record_damage_to_enemy(amount: int) -> void:
	if not PERF_LOG_ENABLED:
		return
	_acc_damage_to_enemies += maxi(0, amount)


func _on_second_tick() -> void:
	if not PERF_LOG_ENABLED:
		return
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena == null:
		return
	_print_snapshot(arena)


func _print_snapshot(arena: Node) -> void:
	var fps: float = Engine.get_frames_per_second()
	var proc_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var mem_tex: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var mem_buf: float = Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0
	var obj_n: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var phys2d_obj: int = int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))
	var phys2d_pairs: int = int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS))
	var draw_2d: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prim_2d: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var mem_vid: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var orphan_n: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var res_n: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var enemies_n: int = get_tree().get_nodes_in_group("enemies").size()
	var proj_n: int = 0
	var mat_n: int = 0
	if arena.has_node("ProjectileContainer"):
		proj_n = arena.get_node("ProjectileContainer").get_child_count()
	if arena.has_node("MaterialContainer"):
		mat_n = arena.get_node("MaterialContainer").get_child_count()
	var pc: Vector2i = _particle_counts_under(arena)
	var nodes_under_arena: int = _count_nodes_recursive(arena)
	var areas: int = _count_class_recursive(arena, &"Area2D")
	var cb2d: int = _count_class_recursive(arena, &"CharacterBody2D")
	var spr2d: int = _count_class_recursive(arena, &"Sprite2D")
	var lbl: int = _count_class_recursive(arena, &"Label")
	var master_peak: float = AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Master"), 0)
	var paused: bool = get_tree().paused
	var pr: String = str(RunState.pause_reason) if RunState != null else "n/a"
	var player_line: String = _build_player_line(arena)
	var run_line: String = _build_run_line()
	var power_line: String = _build_power_line()
	var plat: String = OS.get_name()
	var web: bool = OS.has_feature("web")
	var dmg_in: int = _acc_player_damage_taken
	var dmg_out: int = _acc_damage_to_enemies
	_acc_player_damage_taken = 0
	_acc_damage_to_enemies = 0
	print(
		"\n[PerfLog] t=%.1fs | %s web=%s\n" % [Time.get_ticks_msec() / 1000.0, plat, str(web).to_lower()]
		+ "  FPS=%.1f proc_ms=%.2f phys_ms=%.2f | draw_calls=%d primitives=%d\n" % [fps, proc_ms, phys_ms, draw_2d, prim_2d]
		+ "  mem_MB static=%.1f render_tex=%.1f render_buf=%.1f render_video=%.1f | objects=%d resources=%d orphans=%d | phys2d_active=%d pairs=%d\n" % [mem_static, mem_tex, mem_buf, mem_vid, obj_n, res_n, orphan_n, phys2d_obj, phys2d_pairs]
		+ "  arena_nodes=%d area2d=%d charbody2d=%d sprite2d=%d label=%d | enemies_grp=%d proj=%d mats=%d\n" % [nodes_under_arena, areas, cb2d, spr2d, lbl, enemies_n, proj_n, mat_n]
		+ "  tree_paused=%s pause_reason=%s | master_peak_db=%.1f\n" % [str(paused).to_lower(), pr, master_peak]
		+ "  particle_nodes=%d particle_emitting=%d\n" % [pc.x, pc.y]
		+ "  dmg_last_1s player_took=%d dealt_to_enemies=%d\n" % [dmg_in, dmg_out]
		+ "  %s\n" % player_line
		+ "  %s\n" % run_line
		+ "  %s\n" % power_line
		+ "[PerfLog] ---\n"
	)


func _build_player_line(arena: Node) -> String:
	var pl: Node = arena.get_node_or_null("Player")
	if pl == null:
		return "player: (none)"
	var hp: String = "hp=%d/%d" % [pl.current_hp, pl.max_hp] if "current_hp" in pl and "max_hp" in pl else "hp=?"
	var dm: String = "dmg×%.2f" % float(pl.stat_damage_mult) if "stat_damage_mult" in pl else ""
	var sm: String = "spd×%.2f" % float(pl.stat_move_speed_mult) if "stat_move_speed_mult" in pl else ""
	var fr: String = "rof×%.2f" % float(pl.stat_fire_rate_mult) if "stat_fire_rate_mult" in pl else ""
	var ar: String = "rng+%.0f" % float(pl.stat_attack_range_bonus) if "stat_attack_range_bonus" in pl else ""
	var lk: String = "luck=%d" % int(pl.stat_luck) if "stat_luck" in pl else ""
	var cr: String = "crit=%.0f%%" % (float(pl.stat_crit_chance) * 100.0) if "stat_crit_chance" in pl else ""
	return "player: %s %s %s %s %s %s %s" % [hp, dm, sm, fr, ar, lk, cr]


func _build_run_line() -> String:
	if RunState == null:
		return "run: RunState=null"
	var w: int = int(RunState.wave_index)
	var mat: int = int(RunState.material_current)
	var sav: int = int(RunState.material_savings)
	var rid: String = str(RunState.character_id) if "character_id" in RunState else "?"
	return "run: wave=%d char=%s material=%d savings=%d" % [w, rid, mat, sav]


func _build_power_line() -> String:
	# Godot 4 已移除 OS.get_power_percent_left / get_power_state；Web 亦无通用电池读数。
	var low_cpu: bool = OS.is_low_processor_usage_mode_enabled()
	return "power: n/a (no OS battery API in Godot 4) | low_processor_usage_mode=%s" % str(low_cpu).to_lower()


func _particle_counts_under(root: Node) -> Vector2i:
	return _particle_walk(root)


func _particle_walk(n: Node) -> Vector2i:
	var t: int = 0
	var e: int = 0
	if n is GPUParticles2D:
		t = 1
		if (n as GPUParticles2D).emitting:
			e = 1
	elif n is CPUParticles2D:
		t = 1
		if (n as CPUParticles2D).emitting:
			e = 1
	for c in n.get_children():
		var sub: Vector2i = _particle_walk(c)
		t += sub.x
		e += sub.y
	return Vector2i(t, e)


func _count_nodes_recursive(n: Node) -> int:
	var tot: int = 1
	for c in n.get_children():
		tot += _count_nodes_recursive(c)
	return tot


func _count_class_recursive(n: Node, p_class: StringName) -> int:
	var tot: int = 0
	if n.is_class(p_class):
		tot += 1
	for c in n.get_children():
		tot += _count_class_recursive(c, p_class)
	return tot
