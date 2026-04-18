extends Node

enum TutorialStep {
	WELCOME = 0,
	INPUT_SELECT = 1,
	CHAR_SELECT = 2,
	WAVE_ONE = 3,
	SHOP_INTRO = 4,
	COMPLETION = 5,
	DONE = 6,
}

var active: bool = false
var current_step: TutorialStep = TutorialStep.DONE
var shop_intro_acknowledged: bool = false


func begin_from_main_menu() -> void:
	if SaveManager.get_tutorial_completed():
		return
	active = true
	current_step = TutorialStep.WELCOME
	shop_intro_acknowledged = false


func set_step(step: TutorialStep) -> void:
	current_step = step


func advance_after_input_select() -> void:
	if not active:
		return
	current_step = TutorialStep.CHAR_SELECT


func advance_after_run_started() -> void:
	if not active:
		return
	current_step = TutorialStep.WAVE_ONE


func advance_after_wave_one_hint() -> void:
	if not active:
		return
	current_step = TutorialStep.SHOP_INTRO


func advance_to_completion() -> void:
	if not active:
		return
	current_step = TutorialStep.COMPLETION


func mark_done() -> void:
	active = false
	current_step = TutorialStep.DONE
	shop_intro_acknowledged = false


func mark_shop_intro_acknowledged() -> void:
	shop_intro_acknowledged = true


func clear() -> void:
	mark_done()
