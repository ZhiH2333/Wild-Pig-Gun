extends CanvasLayer

## 波间：三选一升级 + 商店 + 下一波
signal continue_pressed

const REFRESH_SHOP_COST: int = 3

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/TitleLabel
@onready var upgrade_row: HBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/UpgradeRow
@onready var shop_vbox: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/ShopScroll/ShopVBox
@onready var refresh_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/BottomRow/RefreshShopButton
@onready var continue_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/BottomRow/ContinueButton

var _player: Node = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _upgrade_picked: bool = false
var _shop_offers: Array = []


func set_player(p: Node) -> void:
	_player = p


func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	refresh_btn.pressed.connect(_on_refresh_shop_pressed)
	refresh_btn.text = "刷新商店 (%d)" % REFRESH_SHOP_COST


func show_for_finished_wave(finished_wave_index: int) -> void:
	title_label.text = "第 %d 波结束" % finished_wave_index
	_upgrade_picked = false
	continue_btn.disabled = true
	_rng.seed = int(RunState.run_seed) ^ int(finished_wave_index) * 1103515245
	_clear_children(upgrade_row)
	_clear_children(shop_vbox)
	var offers: Array = BuildCatalog.pick_random_upgrades(3, RunState.upgrade_ids, _rng)
	for def_variant in offers:
		var def: Dictionary = def_variant as Dictionary
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 96)
		b.text = "%s\n%s" % [def["title"], def["desc"]]
		b.pressed.connect(_on_upgrade_button_pressed.bind(def))
		upgrade_row.add_child(b)
	_shop_offers = BuildCatalog.pick_shop_offer(4, _rng)
	_rebuild_shop_rows()
	RunState.enter_interstitial_pause()
	visible = true


func _rebuild_shop_rows() -> void:
	_clear_children(shop_vbox)
	for def_variant in _shop_offers:
		var def: Dictionary = def_variant as Dictionary
		var btn := Button.new()
		var price: int = def["price"] as int
		btn.text = "%s  |  %d 材料\n%s" % [def["title"], price, def["desc"]]
		btn.pressed.connect(_on_buy_pressed.bind(def))
		shop_vbox.add_child(btn)


func _on_buy_pressed(def: Dictionary) -> void:
	var price: int = def["price"] as int
	if not RunState.try_spend_material(price):
		return
	if _player != null:
		BuildCatalog.apply_shop_def(_player, def)


func _on_refresh_shop_pressed() -> void:
	if not RunState.try_spend_material(REFRESH_SHOP_COST):
		return
	_shop_offers = BuildCatalog.pick_shop_offer(4, _rng)
	_rebuild_shop_rows()


func _on_upgrade_button_pressed(def: Dictionary) -> void:
	if _upgrade_picked:
		return
	if _player != null:
		BuildCatalog.apply_upgrade_def(_player, def)
	var id: String = def["id"] as String
	if id not in RunState.upgrade_ids:
		RunState.upgrade_ids.append(id)
	_upgrade_picked = true
	continue_btn.disabled = false
	for c in upgrade_row.get_children():
		if c is Button:
			(c as Button).disabled = true


func _on_continue_pressed() -> void:
	if not _upgrade_picked:
		return
	visible = false
	RunState.leave_interstitial_pause()
	continue_pressed.emit()


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()
