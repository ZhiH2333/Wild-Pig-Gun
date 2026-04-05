extends CanvasLayer

## 波间：三选一升级 + 商店 + 下一波（幸运加权商店、物价随波次）
signal continue_pressed

const REFRESH_SHOP_COST: int = 3
const REFRESH_UPGRADE_COST: int = 8
const ITEM_CARD_SCENE: PackedScene = preload("res://scenes/ui/item_card.tscn")

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/TitleLabel
@onready var upgrade_row: HBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/UpgradeRow
@onready var refresh_upgrade_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/RefreshUpgradesButton
@onready var shop_vbox: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/ShopScroll/ShopVBox
@onready var refresh_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/BottomRow/RefreshShopButton
@onready var continue_btn: Button = $CenterContainer/Panel/MarginContainer/VBox/BottomRow/ContinueButton

var _player: Node = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _upgrade_picked: bool = false
var _shop_offers: Array = []
var _next_wave_for_shop: int = 1


func set_player(p: Node) -> void:
	_player = p


func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	refresh_btn.pressed.connect(_on_refresh_shop_pressed)
	refresh_upgrade_btn.pressed.connect(_on_refresh_upgrades_pressed)
	refresh_btn.text = "刷新商店 (%d)" % REFRESH_SHOP_COST
	refresh_upgrade_btn.text = "刷新升级选项 (%d)" % REFRESH_UPGRADE_COST


func show_for_finished_wave(finished_wave_index: int) -> void:
	title_label.text = "第 %d 波结束" % finished_wave_index
	_next_wave_for_shop = finished_wave_index + 1
	_upgrade_picked = false
	continue_btn.disabled = true
	continue_btn.custom_minimum_size = Vector2(300, 52)
	continue_btn.remove_theme_font_size_override("font_size")
	continue_btn.text = "开始下一波"
	_rng.seed = int(RunState.run_seed) ^ int(finished_wave_index) * 1103515245
	_clear_children(upgrade_row)
	_clear_children(shop_vbox)
	var luck: int = 0
	if _player != null and "stat_luck" in _player:
		luck = int(_player.stat_luck)
	var offers: Array = BuildCatalog.pick_random_upgrades(3, RunState.upgrade_ids, _rng, _next_wave_for_shop, luck)
	for def_variant in offers:
		var def: Dictionary = def_variant as Dictionary
		var card: ItemCard = ITEM_CARD_SCENE.instantiate() as ItemCard
		upgrade_row.add_child(card)
		card.setup_card(def, "upgrade")
		card.pressed.connect(_on_upgrade_button_pressed.bind(def))
	_shop_offers = BuildCatalog.pick_shop_offer(4, _rng, luck)
	_rebuild_shop_rows()
	refresh_upgrade_btn.disabled = false
	RunState.enter_interstitial_pause()
	visible = true


func _effective_price(def: Dictionary) -> int:
	return BuildCatalog.effective_shop_price(def, _next_wave_for_shop, _player)


func _rebuild_shop_rows() -> void:
	_clear_children(shop_vbox)
	for def_variant in _shop_offers:
		var def: Dictionary = def_variant as Dictionary
		var price: int = _effective_price(def)
		var can_afford: bool = RunState.material_current >= price
		var card: ItemCard = ITEM_CARD_SCENE.instantiate() as ItemCard
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 108)
		shop_vbox.add_child(card)
		card.setup_card(def, "shop", price, can_afford)
		card.pressed.connect(_on_buy_pressed.bind(def))


func _on_buy_pressed(def: Dictionary) -> void:
	var price: int = _effective_price(def)
	if not RunState.try_spend_material(price):
		return
	if _player != null:
		BuildCatalog.apply_shop_def(_player, def)
	_rebuild_shop_rows()


func _on_refresh_shop_pressed() -> void:
	if not RunState.try_spend_material(REFRESH_SHOP_COST):
		return
	var luck: int = 0
	if _player != null and "stat_luck" in _player:
		luck = int(_player.stat_luck)
	_shop_offers = BuildCatalog.pick_shop_offer(4, _rng, luck)
	_rebuild_shop_rows()


func _on_refresh_upgrades_pressed() -> void:
	if _upgrade_picked:
		return
	if not RunState.try_spend_material(REFRESH_UPGRADE_COST):
		return
	var luck2: int = 0
	if _player != null and "stat_luck" in _player:
		luck2 = int(_player.stat_luck)
	_clear_children(upgrade_row)
	var offers: Array = BuildCatalog.pick_random_upgrades(3, RunState.upgrade_ids, _rng, _next_wave_for_shop, luck2)
	for def_variant in offers:
		var def: Dictionary = def_variant as Dictionary
		var card: ItemCard = ITEM_CARD_SCENE.instantiate() as ItemCard
		upgrade_row.add_child(card)
		card.setup_card(def, "upgrade")
		card.pressed.connect(_on_upgrade_button_pressed.bind(def))


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
	continue_btn.custom_minimum_size = Vector2(380, 58)
	continue_btn.add_theme_font_size_override("font_size", 24)
	continue_btn.text = "继续 — 开始下一波"
	for c in upgrade_row.get_children():
		if c is ItemCard:
			(c as ItemCard).disabled = true
	refresh_upgrade_btn.disabled = true


func _on_continue_pressed() -> void:
	if not _upgrade_picked:
		return
	visible = false
	RunState.leave_interstitial_pause()
	continue_pressed.emit()


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()
