extends Node

## 按场景路径分组的投射物对象池；空闲节点挂在对应 bucket 下，visible=false。
## 活跃子弹由 _active + 本节点单次 _process 统一 tick，避免每颗子弹独立 _process。

const MAX_ACTIVE_PROJECTILES: int = 200

const SHARED_BULLET_CANVAS_MATERIAL: CanvasItemMaterial = preload(
	"res://resources/projectile_shared_canvas_material.tres"
)

var _buckets: Dictionary = {}
var _active: Array[Projectile] = []


func _ready() -> void:
	Engine.physics_ticks_per_second = 30


func get_shared_bullet_canvas_material() -> CanvasItemMaterial:
	return SHARED_BULLET_CANVAS_MATERIAL


func _count_active_projectiles() -> int:
	var tree: SceneTree = get_tree()
	if tree == null:
		return 0
	var n: int = 0
	for arena in tree.get_nodes_in_group("arena"):
		var pc: Node = arena.get_node_or_null("ProjectileContainer")
		if pc == null:
			continue
		for c in pc.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				n += 1
	for bucket in _buckets.values():
		for c in (bucket as Node).get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				n += 1
	return n


func _ensure_bucket(scene_path: String) -> Node:
	if _buckets.has(scene_path):
		return _buckets[scene_path] as Node
	var bucket: Node = Node.new()
	var safe_name: String = scene_path.replace("res://", "").replace("/", "_").replace(".", "_")
	bucket.name = "Pool_%s" % safe_name
	add_child(bucket)
	_buckets[scene_path] = bucket
	return bucket


func _register_active(p: Projectile) -> void:
	if p == null:
		return
	if _active.find(p) >= 0:
		return
	_active.append(p)


func _unregister_active(node: Node) -> void:
	if node is Projectile:
		var pr: Projectile = node as Projectile
		var i: int = _active.find(pr)
		if i >= 0:
			_active.remove_at(i)


func get_projectile(scene: PackedScene) -> Node:
	if scene == null:
		push_error("ProjectilePool.get_projectile: scene is null")
		return null
	if _count_active_projectiles() >= MAX_ACTIVE_PROJECTILES:
		return null
	var scene_path: String = scene.resource_path
	var bucket: Node = _ensure_bucket(scene_path)
	var chosen: Node = null
	for c in bucket.get_children():
		if c is CanvasItem and not (c as CanvasItem).visible:
			chosen = c
			break
	if chosen == null:
		chosen = scene.instantiate()
		chosen.set_meta("_pool_scene_path", scene_path)
	if chosen.get_parent() != null:
		chosen.get_parent().remove_child(chosen)
	if chosen.has_method("reset"):
		chosen.call("reset")
	return chosen


## 由 Projectile 在进入 ProjectileContainer 的 _enter_tree 时调用，避免未入树就 tick
func register_active_projectile(p: Projectile) -> void:
	_register_active(p)


func return_projectile(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_unregister_active(node)
	var scene_path: Variant = node.get_meta("_pool_scene_path", node.scene_file_path)
	if str(scene_path).is_empty():
		scene_path = "res://scenes/projectile.tscn"
	var path_str: String = str(scene_path)
	var bucket: Node = _ensure_bucket(path_str)
	node.visible = false
	if node.has_method("deactivate_for_pool"):
		node.call("deactivate_for_pool")
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	bucket.add_child(node)


func _process(delta: float) -> void:
	var i: int = _active.size()
	while i > 0:
		i -= 1
		var p: Projectile = _active[i]
		if p == null or not is_instance_valid(p):
			_active.remove_at(i)
			continue
		p.tick(delta)
