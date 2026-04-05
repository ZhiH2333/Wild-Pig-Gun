extends Control

@onready var character_vbox: VBoxContainer = $ScrollContainer/CharacterVBox


func _ready() -> void:
	for c in character_vbox.get_children():
		c.queue_free()
	for c in CharacterData.list_characters():
		if not c is Dictionary:
			continue
		var d: Dictionary = c as Dictionary
		var b := Button.new()
		var unlocked: bool = CharacterData.is_character_unlocked(d)
		b.text = "%s\n%s" % [d.get("display_name", "?"), d.get("description", "")]
		b.custom_minimum_size = Vector2(620, 92)
		b.disabled = not unlocked
		if unlocked:
			b.pressed.connect(_on_character_chosen.bind(str(d.get("id", "default"))))
		character_vbox.add_child(b)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_character_chosen(character_id: String) -> void:
	RunState.begin_new_run(character_id)
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
