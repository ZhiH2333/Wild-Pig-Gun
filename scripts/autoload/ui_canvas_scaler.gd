extends Node
## 将 UI 缩放仅作用于 CanvasLayer，以及以 Control 为根的菜单场景（非 Node2D 关卡）。
## 有效缩放 = GameSettings 内部 fit × ui_scale（用户 75%～150%）。

var _refresh_pending: bool = false


func _ready() -> void:
	if not GameSettings.ui_scale_changed.is_connected(_schedule_refresh):
		GameSettings.ui_scale_changed.connect(_schedule_refresh)
	var root: Window = get_tree().root
	if not root.size_changed.is_connected(_schedule_refresh):
		root.size_changed.connect(_schedule_refresh)
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	_schedule_refresh()


func _schedule_refresh(_arg: Variant = null) -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_run_pending_refresh")


func _run_pending_refresh() -> void:
	_refresh_pending = false
	_apply_all_ui_scales()


func _on_tree_node_added(node: Node) -> void:
	if node is CanvasLayer:
		call_deferred("_apply_all_ui_scales")
		return
	var root: Node = get_tree().root
	if node.get_parent() == root:
		call_deferred("_apply_all_ui_scales")


func _apply_all_ui_scales() -> void:
	var eff: float = GameSettings._get_effective_ui_canvas_scale()
	if eff <= 0.0001:
		eff = 0.0001
	var xf: Transform2D = _scale_transform_about_viewport_center(eff)
	var scene: Node = get_tree().current_scene
	var control_root: Control = scene as Control if scene is Control else null
	if control_root != null:
		_reset_canvas_layers_under(control_root)
	_apply_canvas_layers(control_root, xf)
	if control_root != null:
		_apply_control_root_scale(control_root, eff)


func _apply_canvas_layers(skip_descendants_of: Control, xf: Transform2D) -> void:
	var root: Window = get_tree().root
	_collect_canvas_layers(root, skip_descendants_of, xf)


func _collect_canvas_layers(node: Node, skip_descendants_of: Control, xf: Transform2D) -> void:
	if node is CanvasLayer:
		var cl: CanvasLayer = node as CanvasLayer
		if skip_descendants_of != null and skip_descendants_of.is_ancestor_of(cl):
			cl.transform = Transform2D.IDENTITY
		else:
			cl.transform = xf
	for c: Node in node.get_children():
		_collect_canvas_layers(c, skip_descendants_of, xf)


func _reset_canvas_layers_under(root_node: Node) -> void:
	if root_node is CanvasLayer:
		(root_node as CanvasLayer).transform = Transform2D.IDENTITY
	for ch: Node in root_node.get_children():
		_reset_canvas_layers_under(ch)


## Control 不能使用 transform 赋值（与布局冲突），用 pivot + scale 实现绕中心缩放。
func _apply_control_root_scale(ctrl: Control, eff: float) -> void:
	var sz: Vector2 = ctrl.size
	if sz.x < 2.0 or sz.y < 2.0:
		sz = get_viewport().get_visible_rect().size
	ctrl.pivot_offset = sz * 0.5
	ctrl.scale = Vector2(eff, eff)


func _scale_transform_about_viewport_center(scale: float) -> Transform2D:
	var vp: Rect2 = get_viewport().get_visible_rect()
	var c: Vector2 = vp.get_center()
	var t_center: Transform2D = Transform2D().translated(c)
	var t_scale: Transform2D = Transform2D().scaled(Vector2(scale, scale))
	var t_uncenter: Transform2D = Transform2D().translated(-c)
	return t_center * t_scale * t_uncenter
