extends Control

@onready var char_sprite: TextureRect = $MainRow/LeftPanel/LeftVBox/CharSprite
@onready var char_name_label: Label = $MainRow/LeftPanel/LeftVBox/CharNameLabel
@onready var char_desc_label: Label = $MainRow/LeftPanel/LeftVBox/CharDescLabel


func _ready() -> void:
	GameMusic.duck_for_subpage()
	_refresh_character_panel()


func _refresh_character_panel() -> void:
	var character_id: String = str(GameSettings.selected_character_id)
	var character: Dictionary = CharacterData.find_character(character_id)
	var display_name: String = str(character.get("display_name", "标准野猪"))
	var description: String = str(character.get("description", "暂无介绍"))
	var sprite_path: String = str(character.get("sprite_path", "res://assets/sprites/wildpig.png"))
	char_name_label.text = display_name
	char_desc_label.text = description
	if not ResourceLoader.exists(sprite_path):
		char_sprite.texture = null
		return
	var texture: Texture2D = load(sprite_path) as Texture2D
	char_sprite.texture = texture


func _on_change_char_button_pressed() -> void:
	RunState.gallery_return_scene_path = "res://scenes/pre_start.tscn"
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_back_button_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_start_button_pressed() -> void:
	RunState.begin_new_run(str(GameSettings.selected_character_id), 1.0)
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
