extends RefCounted
class_name WeaponMuzzleFx

const SHELL_SCENE: PackedScene = preload("res://scenes/fx/ejected_shell.tscn")


static func spawn_for_shot(weapon: Node2D, weapon_id: String, fire_dir: Vector2) -> void:
	if weapon == null:
		return
	var fx: Dictionary = WeaponFxProfiles.profile(weapon_id)
	if bool(fx.get("muzzle_smoke", false)):
		_spawn_smoke(weapon, fire_dir)
	if bool(fx.get("muzzle_shell", false)):
		_spawn_shell(weapon, fire_dir)


static func _spawn_smoke(host: Node2D, fire_dir: Vector2) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.42
	p.explosiveness = 0.88
	p.direction = -fire_dir.normalized()
	p.spread = 32.0
	p.initial_velocity_min = 35.0
	p.initial_velocity_max = 105.0
	p.gravity = Vector2(0, -42)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.2
	p.color = Color(0.52, 0.52, 0.55, 0.52)
	host.add_child(p)
	p.global_position = host.global_position + fire_dir.normalized() * 18.0
	p.z_index = 5
	var tw: Variant = host.get_tree().create_timer(0.65, false, false, true)
	tw.timeout.connect(_free_muzzle_cpu_particles.bind(p))


static func _free_muzzle_cpu_particles(p: Node) -> void:
	if is_instance_valid(p):
		p.queue_free()


static func _spawn_shell(host: Node2D, fire_dir: Vector2) -> void:
	if SHELL_SCENE == null:
		return
	var n: Node2D = SHELL_SCENE.instantiate() as Node2D
	var root: Node = host.get_tree().current_scene
	if root == null:
		n.queue_free()
		return
	root.add_child(n)
	n.global_position = host.global_position + Vector2(-fire_dir.y, fire_dir.x).normalized() * 8.0
	if n.has_method("kick"):
		n.call("kick", fire_dir)
