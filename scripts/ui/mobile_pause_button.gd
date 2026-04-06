extends Button

func _ready() -> void:
	add_to_group("mobile_pause_button")
	_on_mobile_controls_changed(GameSettings.mobile_controls_enabled)
	pressed.connect(_on_pressed)
	GameSettings.mobile_controls_changed.connect(_on_mobile_controls_changed)


func _on_mobile_controls_changed(enabled: bool) -> void:
	visible = enabled


func _on_pressed() -> void:
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and arena.has_method("_on_pause_resume_pressed"):
		arena._on_pause_resume_pressed()
