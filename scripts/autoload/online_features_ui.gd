extends Node
## 控制「在线」相关 UI 入口是否显示（登录、社区、API 连接状态等）。
## 仅隐藏入口，不关闭 CloudAPI / CloudSync 等后台逻辑。

signal entry_visibility_changed(show: bool)

## 默认隐藏在线入口（WildArea 内嵌等）；独立官网 Web 构建时可改为 true。
var show_entry_points: bool = false


func _ready() -> void:
	if OS.has_feature("web"):
		call_deferred("_detect_wildarea_embedded_host")


func _detect_wildarea_embedded_host() -> void:
	var jsb: Object = Engine.get_singleton("JavaScriptBridge")
	if jsb == null or not jsb.has_method("eval"):
		return
	var embedded: Variant = jsb.eval(
		"(typeof wildAreaEmbedded!=='undefined'&&!!wildAreaEmbedded)||" +
		"(typeof wildAreaCloseGame==='function')",
		true
	)
	if bool(embedded):
		set_show_entry_points(false)


func set_show_entry_points(show: bool) -> void:
	if show_entry_points == show:
		return
	show_entry_points = show
	entry_visibility_changed.emit(show)


func should_show_entry_points() -> bool:
	return show_entry_points
