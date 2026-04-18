extends Control

@onready var char_sprite: TextureRect = $MainRow/LeftPanel/LeftVBox/CharSprite
@onready var char_name_label: Label = $MainRow/LeftPanel/LeftVBox/CharNameLabel
@onready var char_desc_label: Label = $MainRow/LeftPanel/LeftVBox/CharDescLabel
@onready var weapon_list: VBoxContainer = $MainRow/RightPanel/RightVBox/WeaponList
@onready var weapon_name_label: Label = $MainRow/RightPanel/RightVBox/WeaponStatsBox/WeaponNameLabel
@onready var weapon_kind_label: Label = $MainRow/RightPanel/RightVBox/WeaponStatsBox/MetaRow/WeaponKindLabel
@onready var weapon_element_label: Label = $MainRow/RightPanel/RightVBox/WeaponStatsBox/MetaRow/WeaponElementLabel
@onready var damage_bar: ProgressBar = $MainRow/RightPanel/RightVBox/WeaponStatsBox/DamageRow/DamageBar
@onready var fire_rate_bar: ProgressBar = $MainRow/RightPanel/RightVBox/WeaponStatsBox/FireRateRow/FireRateBar
@onready var damage_value_label: Label = $MainRow/RightPanel/RightVBox/WeaponStatsBox/DamageRow/DamageValueLabel
@onready var fire_rate_value_label: Label = $MainRow/RightPanel/RightVBox/WeaponStatsBox/FireRateRow/FireRateValueLabel

const MAX_DAMAGE: float = 16.0
const MAX_FIRE_RATE: float = 6.25

var weapon_defs: Array[Dictionary] = []
var selected_weapon_id: String = "rifle"


func _ready() -> void:
	GameMusic.duck_for_subpage()
	_refresh_character_panel()
	_setup_weapon_section()


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


func _setup_weapon_section() -> void:
	weapon_defs = WeaponCatalog.load_defs()
	var default_weapon_id: String = _resolve_default_weapon_id()
	selected_weapon_id = default_weapon_id
	_rebuild_weapon_buttons()
	_refresh_weapon_stats(default_weapon_id)


func _resolve_default_weapon_id() -> String:
	var character_id: String = str(GameSettings.selected_character_id)
	var character_weapon_ids: Array = CharacterData.get_starting_weapon_ids(character_id)
	if character_weapon_ids.is_empty():
		return "rifle"
	return str(character_weapon_ids[0])


func _rebuild_weapon_buttons() -> void:
	for child in weapon_list.get_children():
		child.queue_free()
	for weapon_def in weapon_defs:
		var weapon_id: String = str(weapon_def.get("id", ""))
		var display_name: String = str(weapon_def.get("display_name", weapon_id))
		var short_desc: String = str(weapon_def.get("short_desc", ""))
		var button: Button = Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 54)
		button.text = "%s · %s" % [display_name, short_desc]
		button.set_meta("weapon_id", weapon_id)
		button.button_pressed = weapon_id == selected_weapon_id
		button.pressed.connect(_on_weapon_button_pressed.bind(weapon_id))
		weapon_list.add_child(button)


func _on_weapon_button_pressed(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	for child in weapon_list.get_children():
		if not child is Button:
			continue
		var weapon_button: Button = child as Button
		var button_weapon_id: String = str(weapon_button.get_meta("weapon_id", ""))
		weapon_button.button_pressed = button_weapon_id == weapon_id
	_refresh_weapon_stats(weapon_id)


func _refresh_weapon_stats(weapon_id: String) -> void:
	var weapon_def: Dictionary = WeaponCatalog.find_def(weapon_id)
	var display_name: String = str(weapon_def.get("display_name", weapon_id))
	var weapon_kind: String = str(weapon_def.get("kind", "projectile"))
	var element_name: String = str(weapon_def.get("element", "无"))
	var damage_value: float = float(weapon_def.get("damage", 0))
	var fire_interval: float = maxf(0.01, float(weapon_def.get("fire_interval", 1.0)))
	var fire_rate_value: float = 1.0 / fire_interval
	weapon_name_label.text = display_name
	weapon_kind_label.text = "类型：%s" % weapon_kind
	weapon_element_label.text = "属性：%s" % element_name
	damage_bar.max_value = 100.0
	fire_rate_bar.max_value = 100.0
	damage_bar.value = clampf(damage_value / MAX_DAMAGE, 0.0, 1.0) * 100.0
	fire_rate_bar.value = clampf(fire_rate_value / MAX_FIRE_RATE, 0.0, 1.0) * 100.0
	damage_value_label.text = "%.0f" % damage_value
	fire_rate_value_label.text = "%.2f" % fire_rate_value


func _on_change_char_button_pressed() -> void:
	RunState.gallery_return_scene_path = "res://scenes/pre_start.tscn"
	get_tree().change_scene_to_file("res://scenes/char_gallery.tscn")


func _on_back_button_pressed() -> void:
	GameMusic.ensure_playing_main_volume()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_start_button_pressed() -> void:
	RunState.begin_new_run(str(GameSettings.selected_character_id), 1.0)
	RunState.selected_starting_weapon_ids = [selected_weapon_id]
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
