extends CanvasLayer

## 墨韵第三方音乐
## - Web：JavaScriptBridge 注入 iframe，区域由音乐卡片内挂载点决定
## - 桌面：CanvasLayer 内 Panel 浮层 + godot-webview（勿用独立 OS Window，设置 url 时易原生崩溃）
## - Android：激活时用系统浏览器打开页面
## 桌面端 WebView 仅在用户点击「打开墨韵浮窗」时创建，避免启动即崩溃

signal external_fullscreen_changed(is_fullscreen: bool)

const MOINYUN_URL: String = "https://wanjie.qght.xyz/music.html"
const FULLSCREEN_MARGIN_PX: int = 12
const DESKTOP_FLOAT_SIZE: Vector2i = Vector2i(440, 780)

var is_external_active: bool = false
var is_fullscreen_mode: bool = false

var _embed_mount: Control
var _music_bus_mute_applied: bool = false
var _browser_launched: bool = false

var _fullscreen_root: Control
var _dim: ColorRect
var _fs_host: Control
var _restore_btn: Button

var _float_shell: PanelContainer
var _webview_host: Control
var _native_webview: Node
var _desktop_webview_create_attempted: bool = false

#region agent debug log
const _AGENT_DEBUG_LOG: String = "/Users/ethan/Desktop/wild-pig-gun/.cursor/debug-cf1020.log"
func _agent_dbg(hypothesis_id: String, location: String, message: String, data: Dictionary = {}, run_id: String = "post-fix") -> void:
	var payload: Dictionary = {
		"sessionId": "cf1020",
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	var line: String = JSON.stringify(payload) + "\n"
	var fa: FileAccess = null
	if FileAccess.file_exists(_AGENT_DEBUG_LOG):
		fa = FileAccess.open(_AGENT_DEBUG_LOG, FileAccess.READ_WRITE)
		if fa != null:
			fa.seek_end()
	else:
		fa = FileAccess.open(_AGENT_DEBUG_LOG, FileAccess.WRITE)
	if fa == null:
		return
	fa.store_string(line)
	fa.flush()
	fa.close()


func agent_debug_emit(hypothesis_id: String, location: String, message: String, data: Dictionary = {}) -> void:
	_agent_dbg(hypothesis_id, location, message, data)
#endregion


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 61
	visible = true
	_build_fullscreen_chrome()
	GameSettings.music_source_changed.connect(_on_music_source_changed)
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_on_viewport_size_changed)


func is_desktop_native_webview_supported() -> bool:
	var n: String = OS.get_name()
	if n == "Web" or n == "Android":
		return false
	return ClassDB.class_exists("WebView")


func set_embed_mount(mount: Control) -> void:
	_embed_mount = mount
	if mount == null:
		return
	if not mount.resized.is_connected(_on_embed_mount_resized):
		mount.resized.connect(_on_embed_mount_resized)
	if not mount.tree_exiting.is_connected(_on_embed_mount_tree_exiting):
		mount.tree_exiting.connect(_on_embed_mount_tree_exiting)
	if is_external_active and OS.get_name() == "Web":
		call_deferred("refresh_web_layout")


func toggle_fullscreen() -> void:
	set_fullscreen_mode(not is_fullscreen_mode)


func set_fullscreen_mode(enabled: bool) -> void:
	if not is_external_active:
		return
	if is_fullscreen_mode == enabled:
		return
	is_fullscreen_mode = enabled
	_apply_fullscreen_layout()
	external_fullscreen_changed.emit(is_fullscreen_mode)


func _unhandled_input(event: InputEvent) -> void:
	if not is_external_active or not is_fullscreen_mode:
		return
	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and key_ev.keycode == KEY_ESCAPE:
			set_fullscreen_mode(false)
			if get_viewport() != null:
				get_viewport().set_input_as_handled()


func _on_music_source_changed(_source: String) -> void:
	if GameSettings.music_source == GameSettings.MUSIC_SOURCE_INTERNAL:
		deactivate()


func activate() -> void:
	if is_external_active:
		return
	is_external_active = true
	_apply_music_bus_mute(true)
	if OS.get_name() == "Web":
		_web_inject_bootstrap()
		call_deferred("refresh_web_layout")
		_apply_fullscreen_layout()
	elif OS.get_name() == "Android":
		_open_system_browser_once()
	# 桌面：仅静音，浮窗由用户点击「打开墨韵浮窗」懒加载，避免 ClassDB.instantiate 在不适当时机崩溃


func deactivate() -> void:
	if not is_external_active:
		return
	is_fullscreen_mode = false
	_apply_fullscreen_layout()
	if OS.get_name() == "Web":
		_web_iframe_hide()
	_teardown_desktop_floating()
	is_external_active = false
	_browser_launched = false
	_apply_music_bus_mute(false)
	GameMusic.ensure_playing_main_volume()
	external_fullscreen_changed.emit(false)


func open_in_browser() -> void:
	_browser_launched = true
	OS.shell_open(MOINYUN_URL)


func show_desktop_moinyun_window() -> void:
	_agent_dbg("H-F", "external_music_player.gd:show_desktop_moinyun_window:entry", "show_desktop_moinyun_window entered", {"os": OS.get_name(), "is_external_active": is_external_active})
	if OS.get_name() == "Web" or OS.get_name() == "Android":
		return
	if not is_external_active:
		return
	if not ClassDB.class_exists("WebView"):
		push_warning("[ExternalMusicPlayer] 未加载 WebView 扩展，已改用系统浏览器。")
		open_in_browser()
		return
	_ensure_desktop_float_shell()
	_agent_dbg("H-F", "external_music_player.gd:show_desktop_moinyun_window:after_shell", "after _ensure_desktop_float_shell", {"shell_null": _float_shell == null})
	if _float_shell == null:
		return
	_agent_dbg("H-F", "external_music_player.gd:show_desktop_moinyun_window:before_visible", "before float shell visible")
	_float_shell.visible = true
	_agent_dbg("H-F", "external_music_player.gd:show_desktop_moinyun_window:after_visible", "after float shell visible")
	if _native_webview == null or not is_instance_valid(_native_webview):
		_agent_dbg("H-A", "external_music_player.gd:show_desktop_moinyun_window:defer_create", "scheduling _create_native_webview_in_window")
		call_deferred("_create_native_webview_in_window")


func hide_desktop_moinyun_window() -> void:
	if _float_shell != null and is_instance_valid(_float_shell):
		_float_shell.hide()


func _open_system_browser_once() -> void:
	if _browser_launched:
		return
	open_in_browser()


func _on_embed_mount_resized() -> void:
	if not is_external_active or OS.get_name() != "Web":
		return
	refresh_web_layout()


func _on_embed_mount_tree_exiting() -> void:
	_embed_mount = null


func _on_viewport_size_changed() -> void:
	if not is_external_active or OS.get_name() != "Web":
		return
	refresh_web_layout()


func _build_fullscreen_chrome() -> void:
	var root: Control = Control.new()
	root.name = "ExternalMusicFullscreenRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	_fullscreen_root = root
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.02, 0.04, 0.88)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_dim)
	_fs_host = Control.new()
	_fs_host.name = "FullscreenWebHost"
	_fs_host.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_fs_host)
	var top_bar: MarginContainer = MarginContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 56.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	top_bar.add_theme_constant_override("margin_left", FULLSCREEN_MARGIN_PX)
	top_bar.add_theme_constant_override("margin_top", FULLSCREEN_MARGIN_PX)
	root.add_child(top_bar)
	_restore_btn = Button.new()
	_restore_btn.name = "RestoreBtn"
	_restore_btn.text = "还原"
	_restore_btn.custom_minimum_size = Vector2(120, 44)
	_restore_btn.pressed.connect(_on_restore_pressed)
	top_bar.add_child(_restore_btn)


func _on_restore_pressed() -> void:
	set_fullscreen_mode(false)


func _apply_fullscreen_layout() -> void:
	if _fullscreen_root == null or OS.get_name() != "Web":
		if _fullscreen_root != null:
			_fullscreen_root.visible = false
		return
	var show_fs: bool = is_external_active and is_fullscreen_mode
	_fullscreen_root.visible = show_fs
	if not show_fs:
		call_deferred("refresh_web_layout")
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vs: Vector2 = vp.get_visible_rect().size
	var m: float = float(FULLSCREEN_MARGIN_PX)
	_fs_host.position = Vector2(m, m + 48.0)
	_fs_host.size = Vector2(maxf(32.0, vs.x - m * 2.0), maxf(32.0, vs.y - m * 2.0 - 56.0))
	call_deferred("refresh_web_layout")


func _apply_music_bus_mute(mute: bool) -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if mute:
		if not _music_bus_mute_applied:
			AudioServer.set_bus_mute(idx, true)
			_music_bus_mute_applied = true
		return
	if _music_bus_mute_applied:
		AudioServer.set_bus_mute(idx, false)
		_music_bus_mute_applied = false


func _ensure_desktop_float_shell() -> void:
	if _float_shell != null and is_instance_valid(_float_shell):
		return
	_agent_dbg("H-F", "external_music_player.gd:_ensure_desktop_float_shell:begin", "creating in-canvas Panel float (not OS Window)")
	var shell: PanelContainer = PanelContainer.new()
	shell.name = "MoinyunFloatShell"
	shell.visible = false
	shell.mouse_filter = Control.MOUSE_FILTER_STOP
	var shell_style: StyleBoxFlat = StyleBoxFlat.new()
	shell_style.bg_color = Color(0.06, 0.07, 0.10, 0.98)
	shell_style.border_color = Color(0.35, 0.38, 0.5, 1.0)
	shell_style.set_border_width_all(1)
	shell_style.set_corner_radius_all(10)
	shell_style.content_margin_left = 8.0
	shell_style.content_margin_top = 8.0
	shell_style.content_margin_right = 8.0
	shell_style.content_margin_bottom = 8.0
	shell.add_theme_stylebox_override("panel", shell_style)
	shell.custom_minimum_size = Vector2(float(DESKTOP_FLOAT_SIZE.x), float(DESKTOP_FLOAT_SIZE.y))
	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	shell.add_child(outer)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	var title_lab: Label = Label.new()
	title_lab.text = "墨韵 · 在线音乐"
	title_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lab.add_theme_font_size_override("font_size", 15)
	top_row.add_child(title_lab)
	var close_btn: Button = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(72, 32)
	close_btn.pressed.connect(_on_float_shell_close_pressed)
	top_row.add_child(close_btn)
	outer.add_child(top_row)
	var host: Control = Control.new()
	host.name = "WebViewHost"
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.custom_minimum_size = Vector2(400.0, 660.0)
	outer.add_child(host)
	_webview_host = host
	var vp: Viewport = get_viewport()
	if vp != null:
		var vs: Vector2 = vp.get_visible_rect().size
		var sz: Vector2 = shell.custom_minimum_size
		shell.position = Vector2(maxf(8.0, (vs.x - sz.x) * 0.5), maxf(8.0, (vs.y - sz.y) * 0.5))
	add_child(shell)
	_float_shell = shell
	_agent_dbg("H-F", "external_music_player.gd:_ensure_desktop_float_shell:after_add", "float shell parented to ExternalMusicPlayer", {"parent": str(shell.get_parent())})


func _on_float_shell_close_pressed() -> void:
	hide_desktop_moinyun_window()


func _create_native_webview_in_window() -> void:
	_agent_dbg("H-A", "external_music_player.gd:_create_native_webview_in_window:entry", "_create_native_webview_in_window entered")
	if _webview_host == null or not is_instance_valid(_webview_host):
		return
	if _native_webview != null and is_instance_valid(_native_webview):
		_layout_native_webview_full()
		return
	if _desktop_webview_create_attempted:
		return
	if not ClassDB.class_exists("WebView"):
		return
	_desktop_webview_create_attempted = true
	_agent_dbg("H-A", "external_music_player.gd:_create_native_webview_in_window:before_instantiate", "about to ClassDB.instantiate WebView")
	var w: Node = ClassDB.instantiate("WebView")
	_agent_dbg("H-A", "external_music_player.gd:_create_native_webview_in_window:after_instantiate", "instantiate returned", {"w_null": w == null})
	if w == null:
		_desktop_webview_create_attempted = false
		push_warning("[ExternalMusicPlayer] WebView 实例化失败。")
		return
	_native_webview = w
	if w is Control:
		(w as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	_agent_dbg("H-B", "external_music_player.gd:_create_native_webview_in_window:before_add_child", "about to add_child WebView to host")
	_webview_host.add_child(w)
	_agent_dbg("H-B", "external_music_player.gd:_create_native_webview_in_window:after_add_child", "add_child WebView done")
	_layout_native_webview_full()
	call_deferred("_apply_native_webview_url")


func _apply_native_webview_url() -> void:
	_agent_dbg("H-E", "external_music_player.gd:_apply_native_webview_url:entry", "_apply_native_webview_url entered")
	if _native_webview == null or not is_instance_valid(_native_webview):
		return
	if "background_transparent" in _native_webview:
		_native_webview.set("background_transparent", false)
	elif "transparent" in _native_webview:
		_native_webview.set("transparent", false)
	_agent_dbg("H-E", "external_music_player.gd:_apply_native_webview_url:after_transparency", "transparency props done")
	if "url" in _native_webview:
		_agent_dbg("H-E", "external_music_player.gd:_apply_native_webview_url:before_url", "about to set url")
		_native_webview.set("url", MOINYUN_URL)
	_agent_dbg("H-E", "external_music_player.gd:_apply_native_webview_url:after_url", "url property set")


func _layout_native_webview_full() -> void:
	if _native_webview == null or not is_instance_valid(_native_webview):
		return
	if not (_native_webview is Control):
		return
	var c: Control = _native_webview as Control
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _destroy_native_webview() -> void:
	if _native_webview == null or not is_instance_valid(_native_webview):
		_native_webview = null
		return
	var p: Node = _native_webview.get_parent()
	if p != null:
		p.remove_child(_native_webview)
	_native_webview.queue_free()
	_native_webview = null
	_desktop_webview_create_attempted = false


func _teardown_desktop_floating() -> void:
	_destroy_native_webview()
	if _float_shell != null and is_instance_valid(_float_shell):
		_float_shell.queue_free()
	_float_shell = null
	_webview_host = null


func _web_js_bridge() -> Object:
	return Engine.get_singleton("JavaScriptBridge")


func _web_inject_bootstrap() -> void:
	var bridge: Object = _web_js_bridge()
	if bridge == null:
		return
	var url_json: String = JSON.stringify(MOINYUN_URL)
	var js: String = (
		"(function(){var U=%s;var id='wpg_moinyun_iframe';"
		+ "window.WPG_Moinyun=window.WPG_Moinyun||{};"
		+ "window.WPG_Moinyun.ensure=function(){var e=document.getElementById(id);"
		+ "if(!e){e=document.createElement('iframe');e.id=id;e.src=U;"
		+ "e.setAttribute('allow','autoplay; fullscreen');"
		+ "e.style.border='none';e.style.position='fixed';"
		+ "e.style.zIndex='100002';e.style.display='none';"
		+ "document.body.appendChild(e);}return e;};"
		+ "window.WPG_Moinyun.show=function(l,t,w,h){"
		+ "var e=window.WPG_Moinyun.ensure();"
		+ "e.style.display='block';e.style.left=Math.round(l)+'px';"
		+ "e.style.top=Math.round(t)+'px';"
		+ "e.style.width=Math.round(w)+'px';"
		+ "e.style.height=Math.round(h)+'px';};"
		+ "window.WPG_Moinyun.hide=function(){"
		+ "var e=document.getElementById(id);if(e){e.style.display='none';}};"
		+ "})();" % url_json
	)
	if bridge.has_method("eval"):
		bridge.call("eval", js, true)


func refresh_web_layout() -> void:
	if not is_external_active or OS.get_name() != "Web":
		return
	var bridge: Object = _web_js_bridge()
	if bridge == null:
		return
	var r: Rect2 = Rect2()
	if is_fullscreen_mode:
		if _fs_host != null and is_instance_valid(_fs_host):
			r = _fs_host.get_global_rect()
	else:
		if _embed_mount == null or not is_instance_valid(_embed_mount):
			return
		if not _embed_mount.is_visible_in_tree():
			_web_iframe_hide()
			return
		r = _embed_mount.get_global_rect()
	if r.size.x < 8.0 or r.size.y < 8.0:
		return
	var js: String = "window.WPG_Moinyun&&window.WPG_Moinyun.show(%d,%d,%d,%d);" % [
		int(round(r.position.x)),
		int(round(r.position.y)),
		int(round(r.size.x)),
		int(round(r.size.y)),
	]
	if bridge.has_method("eval"):
		bridge.call("eval", js, true)


func _web_iframe_hide() -> void:
	var bridge: Object = _web_js_bridge()
	if bridge == null:
		return
	if bridge.has_method("eval"):
		bridge.call("eval", "window.WPG_Moinyun&&window.WPG_Moinyun.hide();", true)
