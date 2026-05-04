extends Node

## 按场景路径分组的投射物对象池；空闲节点挂在对应 bucket 下，visible=false。

var _buckets: Dictionary = {}


func _ensure_bucket(scene_path: String) -> Node:
	if _buckets.has(scene_path):
		return _buckets[scene_path] as Node
	var bucket: Node = Node.new()
	var safe_name: String = scene_path.replace("res://", "").replace("/", "_").replace(".", "_")
	bucket.name = "Pool_%s" % safe_name
	add_child(bucket)
	_buckets[scene_path] = bucket
	return bucket


func get_projectile(scene: PackedScene) -> Node:
	if scene == null:
		push_error("ProjectilePool.get_projectile: scene is null")
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


func return_projectile(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
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
