extends CanvasLayer

## 波间：三选一升级 + 商店 + 下一波（幸运加权商店、物价随波次）
## 左侧状态栏显示当前属性与武器，支持变卖武器
signal continue_pressed

const SHOP_OFFER_COUNT: int = 5
const REFRESH_SHOP_COST: int = 3
const REFRESH_UPGRADE_COST: int = 8
const ITEM_CARD_SCENE: PackedScene = preload("res://scenes/ui/item_card.tscn")
const TOUCH_SCROLL_SCRIPT: Script = preload("res://scripts/ui/touch_scroll_container.gd")

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
var _shop_confirm: ConfirmationDialog
var _pending_shop_def: Dictionary = {}
## 当前波间界面所对应的「刚结束的波次」，用于构筑日志分组
var _finished_wave_for_log: int = 0

## 左侧状态面板相关
var _status_panel_root: Control = null
var _status_vbox: VBoxContainer = null
var _bottom_hint_label: Label = null
var _sell_confirm: ConfirmationDialog = null
var _pending_sell_node: Node = null


func set_player(p: Node) -> void:
	_player = p


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_layout_and_typography()
	continue_btn.pressed.connect(_on_continue_pressed)
	refresh_btn.pressed.connect(_on_refresh_shop_pressed)
	refresh_upgrade_btn.pressed.connect(_on_refresh_upgrades_pressed)
	refresh_btn.text = "刷新商店 (%d)" % REFRESH_SHOP_COST
	refresh_upgrade_btn.text = "刷新升级选项 (%d)" % REFRESH_UPGRADE_COST
	_shop_confirm = ConfirmationDialog.new()
	_shop_confirm.title = "确认购买"
	_shop_confirm.ok_button_text = "购买"
	_shop_confirm.cancel_button_text = "取消"
	_shop_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_shop_confirm)
	_shop_confirm.confirmed.connect(_on_shop_confirm_buy)
	_sell_confirm = ConfirmationDialog.new()
	_sell_confirm.title = "确认变卖"
	_sell_confirm.ok_button_text = "变卖"
	_sell_confirm.cancel_button_text = "取消"
	_sell_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sell_confirm)
	_sell_confirm.confirmed.connect(_on_sell_confirm)
	_build_left_status_panel()
	_build_bottom_hint()


func _apply_layout_and_typography() -> void:
	var center: CenterContainer = $CenterContainer as CenterContainer
	if center != null:
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.offset_left = 404.0
		center.offset_right = -18.0
		center.offset_top = 12.0
		center.offset_bottom = -12.0
	var panel: PanelContainer = $CenterContainer/Panel as PanelContainer
	if panel != null:
		panel.custom_minimum_size = Vector2(980, 740)
	title_label.add_theme_font_size_override("font_size", 44)
	refresh_upgrade_btn.add_theme_font_size_override("font_size", 23)
	refresh_btn.add_theme_font_size_override("font_size", 23)
	continue_btn.add_theme_font_size_override("font_size", 24)
	var upgrade_hint: Label = $CenterContainer/Panel/MarginContainer/VBox/UpgradeHint as Label
	if upgrade_hint != null:
		upgrade_hint.add_theme_font_size_override("font_size", 28)
	var shop_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ShopLabel as Label
	if shop_label != null:
		shop_label.add_theme_font_size_override("font_size", 28)


func _build_left_status_panel() -> void:
	_status_panel_root = Control.new()
	_status_panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_panel_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_status_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_panel_root)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchor(SIDE_LEFT, 0.0)
	panel.set_anchor(SIDE_TOP, 0.0)
	panel.set_anchor(SIDE_RIGHT, 0.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.set_offset(SIDE_LEFT, 8.0)
	panel.set_offset(SIDE_RIGHT, 388.0)
	panel.set_offset(SIDE_TOP, 8.0)
	panel.set_offset(SIDE_BOTTOM, -8.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.99)
	style.set_border_width_all(2)
	style.border_color = Color(0.34, 0.41, 0.56, 1.0)
	style.set_corner_radius_all(8)
	style.shadow_size = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	panel.add_theme_stylebox_override("panel", style)
	_status_panel_root.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_script(TOUCH_SCROLL_SCRIPT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_status_vbox = VBoxContainer.new()
	_status_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_status_vbox)


func _build_bottom_hint() -> void:
	var vbox: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBox as VBoxContainer
	if vbox == null:
		return
	var sep: HSeparator = HSeparator.new()
	sep.modulate = Color(0.3, 0.3, 0.35, 0.7)
	vbox.add_child(sep)
	_bottom_hint_label = Label.new()
	_bottom_hint_label.text = "提示：武器栏满时购买已有武器可升级（伤害+15%）· 点击左侧武器可变卖 · 每次变卖返还购买价的 50%"
	_bottom_hint_label.add_theme_font_size_override("font_size", 15)
	_bottom_hint_label.modulate = Color(0.65, 0.68, 0.75, 1.0)
	_bottom_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bottom_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bottom_hint_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_bottom_hint_label)


func show_for_finished_wave(finished_wave_index: int) -> void:
	_finished_wave_for_log = finished_wave_index
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
	_shop_offers = BuildCatalog.pick_shop_offer(SHOP_OFFER_COUNT, _rng, luck)
	_rebuild_shop_rows()
	_refresh_status_panel()
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
		var slot_blocked: bool = false
		var display_def: Dictionary = def.duplicate()
		if str(def.get("kind", "")) == "add_weapon" and _player != null:
			var lo: Node = _player.get_node_or_null("WeaponLoadout")
			var wid: String = str(def.get("value", ""))
			if lo != null:
				if lo.has_method("has_weapon_id") and lo.has_weapon_id(wid):
					var cur_lv: int = lo.get_weapon_level(wid) if lo.has_method("get_weapon_level") else 1
					display_def["short_desc"] = "升级→Lv.%d（伤害+15%%）" % (cur_lv + 1)
				elif lo.get_child_count() >= WeaponLoadout.MAX_SLOTS:
					slot_blocked = true
					display_def["short_desc"] = "栏位已满（6/6）"
		var card: ItemCard = ITEM_CARD_SCENE.instantiate() as ItemCard
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 108)
		shop_vbox.add_child(card)
		card.setup_card(display_def, "shop", price, can_afford and not slot_blocked)
		if not slot_blocked:
			card.pressed.connect(_on_shop_item_pressed.bind(def))


func _on_shop_item_pressed(def: Dictionary) -> void:
	if _player == null:
		return
	var price: int = _effective_price(def)
	if str(def.get("kind", "")) == "add_weapon":
		var lo: Node = _player.get_node_or_null("WeaponLoadout")
		var wid: String = str(def.get("value", ""))
		if lo != null and lo.get_child_count() >= WeaponLoadout.MAX_SLOTS:
			if not (lo.has_method("has_weapon_id") and lo.has_weapon_id(wid)):
				_shop_confirm.dialog_text = "武器栏已满（6/6），无法购买新武器。\n\n请先变卖左侧现有武器，或购买已有武器以升级。"
				var ok_btn: Button = _shop_confirm.get_ok_button()
				if ok_btn != null:
					ok_btn.disabled = true
				_pending_shop_def.clear()
				_shop_confirm.popup_centered()
				return
	var body: String = BuildCatalog.shop_purchase_preview_text(
		def,
		_player,
		_next_wave_for_shop,
		RunState.material_current
	)
	_pending_shop_def = def.duplicate()
	_shop_confirm.dialog_text = body
	var ok_btn: Button = _shop_confirm.get_ok_button()
	if ok_btn != null:
		ok_btn.disabled = RunState.material_current < price
	_shop_confirm.popup_centered()


func _on_shop_confirm_buy() -> void:
	var def: Dictionary = _pending_shop_def.duplicate()
	_pending_shop_def.clear()
	if def.is_empty() or _player == null:
		return
	if str(def.get("kind", "")) == "add_weapon":
		var lo: Node = _player.get_node_or_null("WeaponLoadout")
		var wid: String = str(def.get("value", ""))
		if lo != null and lo.get_child_count() >= WeaponLoadout.MAX_SLOTS:
			if not (lo.has_method("has_weapon_id") and lo.has_weapon_id(wid)):
				return
	var price: int = _effective_price(def)
	if not RunState.try_spend_material(price):
		return
	BuildCatalog.apply_shop_def(_player, def)
	var sid: String = str(def.get("id", ""))
	var stitle: String = str(def.get("title", sid))
	if not sid.is_empty():
		RunState.append_run_choice("shop", _finished_wave_for_log, sid, stitle)
	_rebuild_shop_rows()
	_refresh_status_panel()


func _on_refresh_shop_pressed() -> void:
	if not RunState.try_spend_material(REFRESH_SHOP_COST):
		return
	var luck: int = 0
	if _player != null and "stat_luck" in _player:
		luck = int(_player.stat_luck)
	_shop_offers = BuildCatalog.pick_shop_offer(SHOP_OFFER_COUNT, _rng, luck)
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
	var utitle: String = str(def.get("title", id))
	RunState.append_run_choice("wave_upgrade", _finished_wave_for_log, id, utitle)
	_upgrade_picked = true
	continue_btn.disabled = false
	continue_btn.custom_minimum_size = Vector2(380, 58)
	continue_btn.add_theme_font_size_override("font_size", 24)
	continue_btn.text = "继续 — 开始下一波"
	for c in upgrade_row.get_children():
		if c is ItemCard:
			(c as ItemCard).disabled = true
	refresh_upgrade_btn.disabled = true
	_refresh_status_panel()


func _on_continue_pressed() -> void:
	if not _upgrade_picked:
		return
	visible = false
	RunState.leave_interstitial_pause()
	continue_pressed.emit()


## 刷新左侧状态面板内容
func _refresh_status_panel() -> void:
	if _status_vbox == null:
		return
	for c in _status_vbox.get_children():
		_status_vbox.remove_child(c)
		c.queue_free()
	_add_panel_title("当前状态")
	_add_panel_separator()
	_add_stats_section()
	_add_panel_separator()
	_add_weapons_section()


func _add_panel_title(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	lbl.modulate = Color.WHITE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_vbox.add_child(lbl)


func _add_panel_separator() -> void:
	var sep: HSeparator = HSeparator.new()
	sep.modulate = Color(0.3, 0.33, 0.45, 0.8)
	_status_vbox.add_child(sep)


func _add_stat_row(text: String, color: Color = Color(0.82, 0.85, 0.92, 1.0)) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 21)
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate = Color.WHITE
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_vbox.add_child(lbl)


func _add_stats_section() -> void:
	if _player == null:
		_add_stat_row("（无玩家数据）")
		return
	_add_stat_row("❤ 生命：%d / %d" % [_player.current_hp, _player.max_hp])
	_add_stat_row("💰 材料：%d" % RunState.material_current)
	_add_stat_row("⭐ 等级：Lv.%d" % RunState.player_level)
	_add_stat_row("⚔ 伤害乘数：×%.2f" % _player.stat_damage_mult)
	_add_stat_row("🔫 攻速乘数：×%.2f" % _player.stat_fire_rate_mult)
	_add_stat_row("👟 移速乘数：×%.2f" % _player.stat_move_speed_mult)
	_add_stat_row("🎯 暴击：%.0f%% × %.2f" % [_player.stat_crit_chance * 100.0, _player.stat_crit_mult])
	if _player.stat_hp_regen_per_sec > 0.001:
		_add_stat_row("💚 回复：%.2f/s" % _player.stat_hp_regen_per_sec)
	if _player.stat_luck > 0:
		_add_stat_row("🍀 幸运：%d" % _player.stat_luck)
	if _player.stat_harvest > 0.001:
		_add_stat_row("🌾 收获：%.1f" % _player.stat_harvest)
	if _player.stat_attack_range_bonus > 0.001:
		_add_stat_row("📏 射程加成：+%.0f" % _player.stat_attack_range_bonus)


func _add_weapons_section() -> void:
	if _player == null:
		return
	var lo: Node = _player.get_node_or_null("WeaponLoadout")
	var slot_count: int = lo.get_child_count() if lo != null else 0
	var section_title: Label = Label.new()
	section_title.text = "武器栏 %d/%d" % [slot_count, WeaponLoadout.MAX_SLOTS]
	section_title.add_theme_font_size_override("font_size", 24)
	section_title.add_theme_color_override("font_color", Color(0.94, 0.95, 1.0, 1.0))
	section_title.modulate = Color.WHITE
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_vbox.add_child(section_title)
	if lo == null:
		return
	var children: Array = lo.get_children()
	if children.is_empty():
		_add_stat_row("（尚无武器）")
		return
	for child in children:
		if not ("weapon_id" in child):
			continue
		var wid: String = str(child.weapon_id)
		var wdef: Dictionary = WeaponCatalog.find_def(wid)
		var wname: String = str(wdef.get("display_name", wid))
		var wlv: int = int(child.weapon_level) if "weapon_level" in child else 1
		var sell_price: int = _get_weapon_sell_price(wid)
		var can_sell: bool = slot_count > 1
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_status_vbox.add_child(row)
		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 1)
		row.add_child(info_vbox)
		var name_lbl: Label = Label.new()
		name_lbl.text = "%s Lv.%d" % [wname, wlv]
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62, 1.0))
		name_lbl.modulate = Color.WHITE
		info_vbox.add_child(name_lbl)
		var dmg_lbl: Label = Label.new()
		var base_dmg: int = int(child.damage) if "damage" in child else 0
		var kind_str: String = str(wdef.get("kind", "projectile"))
		var kind_icon: String = "⚔" if kind_str == "melee" else "🔫"
		dmg_lbl.text = "%s 伤害：%d" % [kind_icon, base_dmg]
		dmg_lbl.add_theme_font_size_override("font_size", 17)
		dmg_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.93, 1.0))
		dmg_lbl.modulate = Color.WHITE
		info_vbox.add_child(dmg_lbl)
		var sell_btn: Button = Button.new()
		if can_sell:
			sell_btn.text = "变卖\n%d材" % sell_price
			sell_btn.modulate = Color(1.0, 0.75, 0.55, 1.0)
			sell_btn.pressed.connect(_on_sell_weapon_pressed.bind(child, wname, sell_price))
		else:
			sell_btn.text = "最后\n一把"
			sell_btn.disabled = true
		sell_btn.custom_minimum_size = Vector2(76, 54)
		sell_btn.add_theme_font_size_override("font_size", 15)
		row.add_child(sell_btn)
	var slot_hint: Label = Label.new()
	if slot_count >= WeaponLoadout.MAX_SLOTS:
		slot_hint.text = "栏位已满，购买同款可升级"
		slot_hint.modulate = Color(1.0, 0.85, 0.4, 1.0)
	else:
		slot_hint.text = "还可添加 %d 把武器" % (WeaponLoadout.MAX_SLOTS - slot_count)
		slot_hint.modulate = Color(0.6, 0.75, 0.6, 1.0)
	slot_hint.add_theme_font_size_override("font_size", 18)
	slot_hint.add_theme_color_override("font_color", slot_hint.modulate)
	slot_hint.modulate = Color.WHITE
	slot_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_vbox.add_child(slot_hint)


func _on_sell_weapon_pressed(weapon_node: Node, wname: String, sell_price: int) -> void:
	if not is_instance_valid(weapon_node):
		return
	_pending_sell_node = weapon_node
	_sell_confirm.dialog_text = "变卖「%s」？\n\n返还 %d 材料（购买价的 50%%）\n\n⚠ 变卖后无法撤销" % [wname, sell_price]
	_sell_confirm.popup_centered()


func _on_sell_confirm() -> void:
	if not is_instance_valid(_pending_sell_node) or _player == null:
		_pending_sell_node = null
		return
	var sell_node: Node = _pending_sell_node
	_pending_sell_node = null
	var wid: String = str(sell_node.weapon_id) if "weapon_id" in sell_node else ""
	var sell_price: int = _get_weapon_sell_price(wid)
	var lo: Node = _player.get_node_or_null("WeaponLoadout")
	if lo != null and lo.has_method("remove_weapon_node"):
		if lo.remove_weapon_node(sell_node):
			RunState.material_current += sell_price
			RunState.material_changed.emit(RunState.material_current, RunState.material_savings)
	call_deferred("_refresh_status_panel")
	call_deferred("_rebuild_shop_rows")


func _get_weapon_sell_price(wid: String) -> int:
	for item in BuildCatalog.default_shop_items():
		if str(item.get("kind", "")) == "add_weapon" and str(item.get("value", "")) == wid:
			return maxi(1, BuildCatalog.get_shop_base_price(item) / 2)
	return 8


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()
