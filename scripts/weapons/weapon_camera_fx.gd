extends RefCounted
class_name WeaponCameraFx


static func find_player_camera(player: Node) -> Camera2D:
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as Camera2D


static func punch_shake_simple(player: Node, strength: float, duration_sec: float) -> void:
	var cam: Camera2D = find_player_camera(player)
	if cam == null:
		return
	var host: Node = cam.get_parent()
	if host == null:
		return
	if host.has_meta("_weapon_shake_tween"):
		var old: Variant = host.get_meta("_weapon_shake_tween")
		if old is Tween:
			(old as Tween).kill()
		host.remove_meta("_weapon_shake_tween")
	var tw: Tween = host.create_tween()
	host.set_meta("_weapon_shake_tween", tw)
	var n: int = maxi(5, int(duration_sec / 0.022))
	for i in range(n):
		var k: float = 1.0 - float(i) / float(n - 1) if n > 1 else 1.0
		var off: Vector2 = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * strength * k
		tw.tween_property(cam, "offset", off, 0.022)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)
	tw.finished.connect(func() -> void:
		if is_instance_valid(host) and host.has_meta("_weapon_shake_tween"):
			host.remove_meta("_weapon_shake_tween")
	)


static func sniper_hitstop_fire_and_forget(player: Node) -> void:
	var tree: SceneTree = player.get_tree() if player != null else null
	if tree == null or tree.paused:
		return
	var root: Window = tree.root
	if bool(root.get_meta("_sniper_hitstop_active", false)):
		return
	root.set_meta("_sniper_hitstop_active", true)
	var prev_scale: float = Engine.time_scale
	Engine.time_scale = 0.38
	tree.create_timer(0.2, true, false, true).timeout.connect(
		func() -> void:
			Engine.time_scale = prev_scale
			if is_instance_valid(root):
				root.set_meta("_sniper_hitstop_active", false)
	,
		CONNECT_ONE_SHOT
	)
