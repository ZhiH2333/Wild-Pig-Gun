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


static func _spawn_smoke(_host: Node2D, _fire_dir: Vector2) -> void:
	## 性能：原每发 CPUParticles2D.new() 会在战斗中常驻多颗 CPU 粒子节点。
	## 若需枪口烟，可改为 GPUParticles2D 单实例对象池或合成 sprite。
	pass


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
