extends Area2D
class_name ProjectileBase

## 投射物基类：对象池 reset / die、屏幕外回收共享逻辑（具体弹道由子类实现）
## 位移由 ProjectilePool 统一 tick，不在此节点上启用 _process。

var _recycle_bounds_canvas: Rect2 = Rect2()
var _recycle_bounds_ready: bool = false


func _ready() -> void:
	set_process(false)


func _cache_recycle_bounds_once() -> void:
	if _recycle_bounds_ready:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vr: Rect2 = vp.get_visible_rect()
	_recycle_bounds_canvas = vr.grow(128.0)
	_recycle_bounds_ready = true


func _recycle_if_outside_viewport_canvas() -> bool:
	_cache_recycle_bounds_once()
	var p: Vector2 = get_global_transform_with_canvas().origin
	return not _recycle_bounds_canvas.has_point(p)


func reset() -> void:
	visible = true
	set_process(false)
	monitoring = true
	monitorable = true


func deactivate_for_pool() -> void:
	set_process(false)
	monitoring = false
	monitorable = false
	visible = false


func die() -> void:
	## 命中等信号处于 Physics 查询刷新过程中，不能立刻改 monitoring / 改父节点；推迟到本帧末再回池。
	call_deferred("_deferred_return_to_pool")


func _deferred_return_to_pool() -> void:
	if not is_instance_valid(self):
		return
	deactivate_for_pool()
	ProjectilePool.return_projectile(self)
