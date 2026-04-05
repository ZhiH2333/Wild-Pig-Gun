extends CanvasLayer

## 局内等级提升：三选一 + 材料刷新（与波间升级池规则不同，带稀有度保底）
signal finished

const REFRESH_LEVEL_COST: int = 6

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/TitleLabel
@onready var upgrade_row: HBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/UpgradeRow
@onready var refresh_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/BottomRow/RefreshOffersButton

var _player: Node = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_levels: Array = []
var _active_level: int = 1
var _picked_for_active: bool = false
var _flush_show_scheduled: bool = false


func _ready() -> void:
	visible = false
	refresh_btn.pressed.connect(_on_refresh_pressed)
	if not RunState.level_up_queued.is_connected(_on_level_up_queued):
		RunState.level_up_queued.connect(_on_level_up_queued)


func set_player(p: Node) -> void:
	_player = p


func _on_level_up_queued(new_level: int) -> void:
	_pending_levels.append(new_level)
	if not _flush_show_scheduled:
		_flush_show_scheduled = true
		call_deferred("_flush_show_queue")


func _flush_show_queue() -> void:
	_flush_show_scheduled = false
	if visible:
		return
	if _pending_levels.is_empty():
		return
	_active_level = int(_pending_levels.pop_front())
	_show_overlay_for_level(_active_level)


func _show_overlay_for_level(lv: int) -> void:
	_picked_for_active = false
	visible = true
	RunState.enter_level_up_pause()
	title_label.text = "升级到 Lv.%d — 选择一项强化" % lv
	_rng.randomize()
	_rebuild_offers(lv)
	refresh_btn.disabled = false


func _rebuild_offers(lv: int) -> void:
	for c in upgrade_row.get_children():
		c.queue_free()
	var offers: Array = BuildCatalog.pick_level_upgrades(3, RunState.upgrade_ids, _rng, lv)
	for def_variant in offers:
		var def: Dictionary = def_variant as Dictionary
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 100)
		var r: int = int(def.get("rarity", 1))
		var tag: String = ["", "[蓝] ", "[红] "][mini(r - 1, 2)]
		b.text = "%s%s\n%s" % [tag, def["title"], def["desc"]]
		b.pressed.connect(_on_pick.bind(def))
		upgrade_row.add_child(b)


func _on_pick(def: Dictionary) -> void:
	if _picked_for_active:
		return
	if _player != null:
		BuildCatalog.apply_upgrade_def(_player, def)
	var id: String = def["id"] as String
	if id not in RunState.upgrade_ids:
		RunState.upgrade_ids.append(id)
	_picked_for_active = true
	for c in upgrade_row.get_children():
		if c is Button:
			(c as Button).disabled = true
	refresh_btn.disabled = true
	visible = false
	RunState.leave_level_up_pause()
	finished.emit()
	call_deferred("_finish_or_chain")


func _finish_or_chain() -> void:
	if not _pending_levels.is_empty():
		_active_level = int(_pending_levels.pop_front())
		_show_overlay_for_level(_active_level)


func _on_refresh_pressed() -> void:
	if _picked_for_active:
		return
	if not RunState.try_spend_material(REFRESH_LEVEL_COST):
		return
	_rebuild_offers(_active_level)
