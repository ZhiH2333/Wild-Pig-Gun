extends Button

## 触控角色技能键：正方形、black_button 主题，文案「技能N」+ 当前角色技能 emoji

const BLACK_BTN_THEME: Theme = preload("res://themes/black_button_theme.tres")
const FONT_BOLD: FontFile = preload("res://assets/fonts/SourceHanSansSC-Bold.otf")
## 与 virtual_controls_layout_host.CHARACTER_SKILL_SLOT_REF 一致
const BASE_SLOT_PX: float = 72.0

@export var input_action: StringName = &"skill"
@export var skill_slot_index: int = 0


func _ready() -> void:
	add_to_group("mobile_skill_button")
	theme = BLACK_BTN_THEME
	add_theme_font_override("font", FONT_BOLD)
	add_theme_font_size_override("font_size", 16)
	visible = true
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if RunState != null and not RunState.run_started.is_connected(_on_run_started):
		RunState.run_started.connect(_on_run_started)
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(BASE_SLOT_PX, BASE_SLOT_PX)
	_refresh_text()
	clip_text = false
	call_deferred("_refresh_text")


func _on_run_started(_cid: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	var title: String = "技能%d" % (skill_slot_index + 1)
	var em: String = "—"
	if RunState != null:
		var defs: Array[Dictionary] = CharacterSkillCatalog.active_defs_sorted(RunState.character_id)
		if skill_slot_index < defs.size():
			em = str(defs[skill_slot_index].get("icon_emoji", "—"))
	text = "%s\n%s" % [title, em]


func _on_button_down() -> void:
	_emit_skill_action(true)


func _on_button_up() -> void:
	_emit_skill_action(false)


func _emit_skill_action(pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = String(input_action)
	ev.pressed = pressed
	Input.parse_input_event(ev)
