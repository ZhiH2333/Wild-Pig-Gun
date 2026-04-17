extends Control

@onready var char_sprite: TextureRect = $CenterCard/CharSprite
@onready var name_label: Label = $CenterCard/NameLabel
@onready var desc_label: Label = $CenterCard/DescLabel
@onready var page_label: Label = $NavRow/PageLabel
@onready var select_button: Button = $SelectButton

var characters: Array = []
var current_index: int = 0


func _ready() -> void:
	GameMusic.duck_for_subpage()
	characters = CharacterData.list_characters()
	if characters.is_empty():
		characters = [_default_character()]
	current_index = _find_selected_index()
	_refresh_display()


func _find_selected_index() -> int:
	var selected_id: String = str(GameSettings.selected_character_id)
	var index: int = 0
	for i in range(characters.size()):
		var item: Variant = characters[i]
		if not item is Dictionary:
			continue
		var character: Dictionary = item as Dictionary
		if str(character.get("id", "")) == selected_id:
			index = i
			break
	return index


func _get_current_character() -> Dictionary:
	if current_index < 0 or current_index >= characters.size():
		return _default_character()
	var item: Variant = characters[current_index]
	if item is Dictionary:
		return item as Dictionary
	return _default_character()


func _refresh_display() -> void:
	var character: Dictionary = _get_current_character()
	var character_name: String = str(character.get("display_name", "未知角色"))
	var character_desc: String = str(character.get("description", "暂无介绍"))
	var character_id: String = str(character.get("id", "default"))
	var unlocked: bool = CharacterData.is_character_unlocked(character)
	var selected_id: String = str(GameSettings.selected_character_id)
	var is_selected: bool = selected_id == character_id
	if not unlocked:
		name_label.text = "%s（未解锁）" % character_name
	else:
		name_label.text = character_name
	desc_label.text = character_desc
	page_label.text = "%d / %d" % [current_index + 1, max(1, characters.size())]
	_refresh_sprite(character)
	if not unlocked:
		select_button.disabled = true
		select_button.text = "未解锁"
	elif is_selected:
		select_button.disabled = true
		select_button.text = "已选择 ✓"
	else:
		select_button.disabled = false
		select_button.text = "选择该角色"


func _refresh_sprite(character: Dictionary) -> void:
	var sprite_path: String = str(character.get("sprite_path", "res://assets/sprites/wildpig.png"))
	if not ResourceLoader.exists(sprite_path):
		char_sprite.texture = null
		return
	var texture: Texture2D = load(sprite_path) as Texture2D
	char_sprite.texture = texture


func _on_prev_button_pressed() -> void:
	if characters.is_empty():
		return
	current_index = posmod(current_index - 1, characters.size())
	_refresh_display()


func _on_next_button_pressed() -> void:
	if characters.is_empty():
		return
	current_index = posmod(current_index + 1, characters.size())
	_refresh_display()


func _on_select_button_pressed() -> void:
	var character: Dictionary = _get_current_character()
	if not CharacterData.is_character_unlocked(character):
		return
	var character_id: String = str(character.get("id", "default"))
	GameSettings.set_selected_character_id(character_id)
	_refresh_display()


func _on_back_button_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file(str(RunState.gallery_return_scene_path))


func _default_character() -> Dictionary:
	return {
		"id": "default",
		"display_name": "标准野猪",
		"description": "平衡型角色。",
		"sprite_path": "res://assets/sprites/wildpig.png",
	}
