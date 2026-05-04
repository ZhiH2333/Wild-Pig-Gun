extends Node
## 开发者覆盖：用于调试账号条与联机相关 UI，不影响真实存档逻辑。

signal overrides_changed

var force_disconnected: bool = false
var force_logged_out: bool = false


func toggle_force_disconnected() -> void:
	force_disconnected = not force_disconnected
	overrides_changed.emit()


func toggle_force_logged_out() -> void:
	force_logged_out = not force_logged_out
	overrides_changed.emit()


func get_effective_connected(base_connected: bool) -> bool:
	if force_disconnected:
		return false
	return base_connected


func get_effective_logged_in(base_logged_in: bool) -> bool:
	if force_logged_out:
		return false
	return base_logged_in
