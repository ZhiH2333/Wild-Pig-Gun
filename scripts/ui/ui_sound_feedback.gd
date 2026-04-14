extends Node

const HOVER_COOLDOWN_SEC: float = 0.07

var _hover_cooldown_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_tree", get_tree().root)


func _process(delta: float) -> void:
	_hover_cooldown_left = maxf(0.0, _hover_cooldown_left - delta)


func _scan_tree(n: Node) -> void:
	if n == null:
		return
	_try_hook_node(n)
	for c in n.get_children():
		_scan_tree(c)


func _on_node_added(n: Node) -> void:
	_try_hook_node(n)


func _try_hook_node(n: Node) -> void:
	if not (n is BaseButton):
		return
	var b: BaseButton = n as BaseButton
	if b.get_meta("ui_sound_hooked", false):
		return
	b.set_meta("ui_sound_hooked", true)
	b.pressed.connect(_on_button_pressed)
	b.mouse_entered.connect(_on_button_mouse_entered.bind(b))
	b.focus_entered.connect(_on_button_focus_entered)


func _on_button_mouse_entered(_b: BaseButton) -> void:
	if _hover_cooldown_left > 0.0:
		return
	_hover_cooldown_left = HOVER_COOLDOWN_SEC
	GameAudio.play_ui_hover()


func _on_button_focus_entered() -> void:
	GameAudio.play_ui_hover()


func _on_button_pressed() -> void:
	GameAudio.play_ui_confirm()
