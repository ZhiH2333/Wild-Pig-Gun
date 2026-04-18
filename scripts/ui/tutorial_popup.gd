extends CanvasLayer

enum PopupKind {
	SHOP_INTRO,
	COMPLETION,
}

signal shop_intro_acknowledged

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _subtitle: Label = $Center/Panel/Margin/VBox/SubtitleLabel
@onready var _body: RichTextLabel = $Center/Panel/Margin/VBox/BodyLabel
@onready var _shop_btn: Button = $Center/Panel/Margin/VBox/ShopAckButton
@onready var _completion_box: VBoxContainer = $Center/Panel/Margin/VBox/CompletionButtons

var _kind: PopupKind = PopupKind.SHOP_INTRO
var _interstitial: Node = null


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	if _panel:
		var st: StyleBoxFlat = StyleBoxFlat.new()
		st.bg_color = Color(0.07, 0.09, 0.13, 0.96)
		st.set_corner_radius_all(14)
		st.set_border_width_all(2)
		st.border_color = Color(0.42, 0.5, 0.65, 1.0)
		_panel.add_theme_stylebox_override("panel", st)


func configure_shop_intro() -> void:
	_kind = PopupKind.SHOP_INTRO
	_dim.color = Color(0, 0, 0, 0.35)
	_subtitle.visible = false
	_body.visible = true
	_shop_btn.visible = true
	_completion_box.visible = false
	_title.text = "💡 购物小提示"
	_body.text = (
		"波次结束后，你可以在此处花费材料进行升级！\n"
		+ "· 左侧：三选一随机升级（波次奖励） · 右侧：商店道具，随时购买\n"
		+ "合理搭配升级，打造你的专属构筑！"
	)
	if not _shop_btn.pressed.is_connected(_on_shop_ack):
		_shop_btn.pressed.connect(_on_shop_ack)


func configure_completion(interstitial: Node) -> void:
	_kind = PopupKind.COMPLETION
	_interstitial = interstitial
	_dim.color = Color(0, 0, 0, 0.72)
	_subtitle.visible = true
	_body.visible = false
	_shop_btn.visible = false
	_completion_box.visible = true
	_title.text = "🎉 新手教程已结束！"
	_subtitle.text = "尽情享受游戏吧！"
	var save_btn: Button = _completion_box.get_node_or_null("SaveExitBtn") as Button
	var discard_btn: Button = _completion_box.get_node_or_null("DiscardExitBtn") as Button
	var cont_btn: Button = _completion_box.get_node_or_null("ContinueBtn") as Button
	if save_btn != null and not save_btn.pressed.is_connected(_on_save_exit):
		save_btn.pressed.connect(_on_save_exit)
	if discard_btn != null and not discard_btn.pressed.is_connected(_on_discard_exit):
		discard_btn.pressed.connect(_on_discard_exit)
	if cont_btn != null and not cont_btn.pressed.is_connected(_on_continue_game):
		cont_btn.pressed.connect(_on_continue_game)


func _on_shop_ack() -> void:
	shop_intro_acknowledged.emit()
	queue_free()


func _on_save_exit() -> void:
	SaveManager.set_tutorial_completed(true)
	TutorialSession.mark_done()
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and arena.has_method("save_run_and_return_to_menu"):
		arena.save_run_and_return_to_menu()
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	queue_free()


func _on_discard_exit() -> void:
	SaveManager.set_tutorial_completed(true)
	TutorialSession.mark_done()
	SaveManager.clear_pending_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	queue_free()


func _on_continue_game() -> void:
	SaveManager.set_tutorial_completed(true)
	TutorialSession.mark_done()
	get_tree().paused = false
	if _interstitial != null and _interstitial.has_method("finish_continue_after_tutorial"):
		_interstitial.finish_continue_after_tutorial()
	queue_free()
