class_name SpellModule extends Node

const ACTION_LOCK_MANAGER = preload("res://scripts/utils/flow/ActionLockManager.gd")
const SPELL_THUMBNAIL_TEMPLATE = preload("res://scripts/ui/common/SpellThumbnailTemplate.gd")
const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const UI_ICON_PROVIDER = preload("res://scripts/ui/common/UIIconProvider.gd")
const UI_FEEDBACK_MANAGER = preload("res://scripts/ui/common/UIFeedbackManager.gd")

signal spell_equipped(spell_id: String)
signal spell_unequipped(spell_id: String)
signal spell_upgraded(spell_id: String)
signal spell_star_upgraded(spell_id: String)
signal spell_viewed(spell_id: String)
signal log_message(message: String)

var game_ui: Node = null
var player: Node = null
var spell_system: Node = null
var spell_data: Node = null
var api: Node = null

var spell_panel: Control = null
var spell_tab: Button = null
var spell_detail_popup: SpellDetailPopup = null
var spell_cards: Dictionary = {}
var current_viewing_spell: String = ""
var current_multiplier_index: int = 0

const MULTIPLIERS = [10, 100, 999999]
const MULTIPLIER_LABELS = ["x10", "x100", "Max"]

var _card_pool: Array[Control] = []
var _max_pool_size: int = 30
var _signals_connected: bool = false
var _scroll_vertical_step: float = 20.0
var _touch_states := {}
const TOUCH_SLOP := 16.0

const ACTION_COOLDOWN_SECONDS := 0.1
var _action_lock := ACTION_LOCK_MANAGER.new()

const TYPE_ORDER = ["breathing", "active", "opening", "production"]
const TYPE_NAMES = {
	"breathing": "吐纳心法",
	"active": "主动术法",
	"opening": "开局术法",
	"production": "生产术法"
}
const RARITY_ORDER = {"fan": 0, "huang": 1, "xuan": 2, "di": 3, "tian": 4}
const ELEMENT_ORDER = {"none": 0, "metal": 1, "wood": 2, "water": 3, "fire": 4, "earth": 5}

func _get_spell_name(spell_id: String) -> String:
	if spell_data and spell_data.has_method("get_spell_name"):
		return spell_data.get_spell_name(spell_id)
	return spell_id

func _get_slot_display_name(slot_type: String) -> String:
	return TYPE_NAMES.get(slot_type, slot_type)

func _get_spell_action_display_name(action: String) -> String:
	match action:
		"equip":
			return "装备"
		"unequip":
			return "卸下"
		"upgrade":
			return "升级"
		"charge":
			return "充灵"
		_:
			return ""

func _get_spell_result_text(result: Dictionary, fallback: String) -> String:
	var reason_code = str(result.get("reason_code", ""))
	var reason_data = result.get("reason_data", {})
	var spell_id = str(reason_data.get("spell_id", current_viewing_spell))
	var spell_name = _get_spell_name(spell_id) if not spell_id.is_empty() else "术法"
	match reason_code:
		"SPELL_EQUIP_SUCCEEDED":
			return spell_name + "装备成功"
		"SPELL_UNEQUIP_SUCCEEDED":
			return spell_name + "卸下成功"
		"SPELL_UPGRADE_SUCCEEDED":
			return "%s升级成功，达到Lv.%s" % [spell_name, UIUtils.format_display_number_integer(float(reason_data.get("new_level", 0)))]
		"SPELL_CHARGE_SUCCEEDED":
			return "%s充灵成功，注入灵气%d" % [spell_name, int(reason_data.get("charged_amount", 0))]
		"SPELL_SLOT_LIMIT_REACHED":
			var slot_type = str(reason_data.get("slot_type", reason_data.get("spell_type", "")))
			return _get_slot_display_name(slot_type) + "槽位已达上限，请先卸下任意术法"
		"SPELL_ACTION_BATTLE_LOCKED":
			var action_name = _get_spell_action_display_name(str(reason_data.get("action", "")))
			if action_name.is_empty():
				return "战斗中无法进行术法操作"
			return "战斗中无法" + action_name + "术法"
		"SPELL_EQUIP_NOT_FOUND", "SPELL_UNEQUIP_NOT_FOUND":
			return "术法不存在"
		"SPELL_EQUIP_NOT_OWNED", "SPELL_UPGRADE_NOT_OWNED", "SPELL_CHARGE_NOT_OWNED":
			return "未获取术法【%s】" % spell_name
		"SPELL_EQUIP_ALREADY_EQUIPPED":
			return "术法【%s】已装备" % spell_name
		"SPELL_EQUIP_PRODUCTION_FORBIDDEN":
			return "杂学术法无法装备"
		"SPELL_UNEQUIP_NOT_EQUIPPED":
			return "术法【%s】未装备" % spell_name
		"SPELL_UPGRADE_AT_MAX_LEVEL", "SPELL_CHARGE_AT_MAX_LEVEL":
			return "术法【%s】已达到最高等级" % spell_name
		"SPELL_UPGRADE_USE_COUNT_INSUFFICIENT":
			return "术法【%s】使用次数不足（%d / %d）" % [
				spell_name,
				int(reason_data.get("current_use_count", 0)),
				int(reason_data.get("required_use_count", 0))
			]
		"SPELL_UPGRADE_CHARGED_SPIRIT_INSUFFICIENT":
			return "术法【%s】充灵不足（%d / %d）" % [
				spell_name,
				int(reason_data.get("current_charged_spirit", 0)),
				int(reason_data.get("required_charged_spirit", 0))
			]
		"SPELL_CHARGE_ALREADY_FULL":
			return "术法【%s】灵气已充足" % spell_name
		"SPELL_CHARGE_PLAYER_SPIRIT_INSUFFICIENT":
			return "自身灵气不足，无法为术法【%s】充灵" % spell_name
		"SPELL_STAR_UP_SUCCEEDED":
			return "%s升星成功，达到%d星" % [spell_name, int(reason_data.get("new_star", result.get("new_star", 0)))]
		"SPELL_STAR_UP_NOT_OWNED":
			return "未获取术法【%s】" % spell_name
		"SPELL_STAR_UP_AT_MAX_STAR":
			return "术法【%s】已达到最高星级" % spell_name
		"SPELL_STAR_UP_UNLOCK_ITEM_INSUFFICIENT":
			var unlock_shortage = max(
				int(reason_data.get("required_unlock_item_count", 0)) - int(reason_data.get("current_unlock_item_count", 0)),
				0
			)
			return "升星失败，缺少同名术法解锁道具%d个" % unlock_shortage
		"SPELL_STAR_UP_STAR_MATERIAL_INSUFFICIENT":
			var material_shortage = max(
				int(reason_data.get("required_star_material_count", 0)) - int(reason_data.get("current_star_material_count", 0)),
				0
			)
			return "升星失败，缺少空白玉简%d个" % material_shortage
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

func initialize(ui: Node, _player_node: Node, spell_sys: Node, spell_dt: Node, game_api: Node = null):
	game_ui = ui
	player = _player_node
	spell_system = spell_sys
	spell_data = spell_dt
	api = game_api
	_sync_scroll_step_with_log()
	_setup_signals()

func _sync_scroll_step_with_log():
	if not game_ui:
		return
	var rich_text: RichTextLabel = game_ui.get("log_text")
	if rich_text:
		var log_font_size = int(rich_text.get_theme_font_size("normal_font_size"))
		if log_font_size > 0:
			_scroll_vertical_step = float(log_font_size)

func _setup_signals():
	if _signals_connected:
		return
	if spell_system and not spell_system.spell_used.is_connected(on_spell_used):
		spell_system.spell_used.connect(on_spell_used)
	_signals_connected = true

func cleanup():
	if spell_detail_popup:
		spell_detail_popup.cleanup()
		spell_detail_popup = null
	for card in _card_pool:
		if is_instance_valid(card):
			card.queue_free()
	_card_pool.clear()
	spell_cards.clear()
	_signals_connected = false

func show_tab():
	if spell_panel:
		spell_panel.visible = true
	await _refresh_spell_from_server()
	update_spell_ui()

func hide_tab():
	if spell_panel:
		spell_panel.visible = false
	_on_spell_detail_close_pressed()

func update_spell_ui():
	if not spell_panel or not spell_system or not spell_data:
		return
	var started_at := Time.get_ticks_msec()
	
	var was_viewing_spell = current_viewing_spell
	var was_popup_visible = false
	if spell_detail_popup:
		was_popup_visible = spell_detail_popup.is_popup_visible()
	
	for spell_id in spell_cards.keys():
		var card = spell_cards[spell_id]
		if is_instance_valid(card):
			_return_card_to_pool(card)
	spell_cards.clear()
	
	for child in spell_panel.get_children():
		if child.name != "SpellScrollContainer":
			child.queue_free()
	
	var scroll_container = spell_panel.get_node_or_null("SpellScrollContainer")
	if not scroll_container:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "SpellScrollContainer"
		scroll_container.layout_mode = 1
		scroll_container.anchors_preset = 15
		scroll_container.anchor_right = 1.0
		scroll_container.anchor_bottom = 1.0
		scroll_container.offset_left = 10.0
		scroll_container.offset_top = 10.0
		scroll_container.offset_right = -10.0
		scroll_container.offset_bottom = -10.0
		scroll_container.grow_horizontal = 2
		scroll_container.grow_vertical = 2
		spell_panel.add_child(scroll_container)
	
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll_container.scroll_vertical_custom_step = _scroll_vertical_step
	
	var main_vbox = scroll_container.get_node_or_null("MainVBox")
	if not main_vbox:
		main_vbox = VBoxContainer.new()
		main_vbox.name = "MainVBox"
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		scroll_container.add_child(main_vbox)
	
	while main_vbox.get_child_count() > 0:
		var c = main_vbox.get_child(0)
		main_vbox.remove_child(c)
		c.queue_free()
	
	var spells = spell_system.get_player_spells()
	if spells == null:
		spells = {}
	
	var spells_by_type: Dictionary = {}
	for spell_id in spells.keys():
		var info = spell_data.get_spell_data(spell_id)
		if info.is_empty():
			continue
		var type_str = info.get("type", "active")
		if not spells_by_type.has(type_str):
			spells_by_type[type_str] = []
		spells_by_type[type_str].append({"id": spell_id, "info": info, "data": spells[spell_id]})

	for type_key in spells_by_type.keys():
		spells_by_type[type_key].sort_custom(func(a, b):
			var ar = int(RARITY_ORDER.get(str(a.info.get("rarity", "fan")), 99))
			var br = int(RARITY_ORDER.get(str(b.info.get("rarity", "fan")), 99))
			if ar != br:
				return ar < br
			var ae = int(ELEMENT_ORDER.get(str(a.info.get("element", "none")), 99))
			var be = int(ELEMENT_ORDER.get(str(b.info.get("element", "none")), 99))
			if ae != be:
				return ae < be
			return str(a.id) < str(b.id)
		)
	
	var visible_type_keys: Array = []
	for type_key in TYPE_ORDER:
		if spells_by_type.has(type_key) and not spells_by_type[type_key].is_empty():
			visible_type_keys.append(type_key)
	
	for index in range(visible_type_keys.size()):
		var type_key = str(visible_type_keys[index])
		
		var limit = spell_data.get_equipment_limit(type_key) if spell_data else 1
		var equipped_count = spell_system.get_equipped_count(type_key) if spell_system else 0
		
		var type_label = Label.new()
		if limit < 0:
			type_label.text = TYPE_NAMES.get(type_key, type_key)
		else:
			type_label.text = TYPE_NAMES.get(type_key, type_key) + " " + UIUtils.format_display_number_integer(float(equipped_count)) + " / " + UIUtils.format_display_number_integer(float(limit))
		type_label.add_theme_font_size_override("font_size", 18)
		type_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		main_vbox.add_child(type_label)
		
		var grid = GridContainer.new()
		grid.name = type_key + "_grid"
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		main_vbox.add_child(grid)
		
		for spell_entry in spells_by_type[type_key]:
			var spell_id = spell_entry.id
			var card = _create_spell_card(spell_id, spell_entry.info, spell_entry.data)
			grid.add_child(card)
			spell_cards[spell_id] = card
		
		if index < visible_type_keys.size() - 1:
			var separator = HSeparator.new()
			separator.custom_minimum_size = Vector2(0, 20)
			main_vbox.add_child(separator)
	
	if was_popup_visible and not was_viewing_spell.is_empty() and spell_cards.has(was_viewing_spell):
		_show_spell_detail(was_viewing_spell)
	if game_ui and game_ui.has_method("perf_debug_log_timing"):
		game_ui.perf_debug_log_timing("spell_ui rebuild", Time.get_ticks_msec() - started_at, "cards=%d" % spell_cards.size())

func _create_spell_card(spell_id: String, info: Dictionary, data: Dictionary) -> Control:
	var card: Control
	if _card_pool.size() > 0:
		card = _card_pool.pop_back()
		card.visible = true
	else:
		card = _create_card_template()
	
	var vbox = card.get_child(0) as VBoxContainer
	var rarity_strip = vbox.get_node_or_null("TopArea/RarityStrip") as ColorRect
	var equipped_badge = vbox.get_node_or_null("TopArea/EquippedBadge") as PanelContainer
	var star_badge = vbox.get_node_or_null("TopArea/StarBadge") as PanelContainer
	var star_label = vbox.get_node_or_null("TopArea/StarBadge/StarLabel") as Label
	var name_label = vbox.get_node_or_null("NameLabel") as Label
	var element_icon = vbox.get_node_or_null("MetaRow/MetaContent/ElementIcon") as TextureRect
	var meta_label = vbox.get_node_or_null("MetaRow/MetaContent/MetaLabel") as Label
	var status_label = vbox.get_node_or_null("StatusLabel") as Label
	var button_container = vbox.get_node_or_null("ButtonContainer") as HBoxContainer
	if not button_container:
		return card
	var equip_btn = button_container.get_node_or_null("EquipButton") as Button
	
	var spell_name = info.get("name", "未知术法")
	var rarity = str(info.get("rarity", spell_data.get_spell_rarity(spell_id) if spell_data else "fan"))
	var rarity_color = _get_spell_rarity_color(rarity)
	var star = int(data.get("star", 0))
	var element = str(info.get("element", spell_data.get_spell_element(spell_id) if spell_data else "none"))
	if name_label:
		name_label.text = spell_name
		name_label.add_theme_color_override("font_color", rarity_color)
	if star_label:
		star_label.text = "" if star <= 0 else "★".repeat(min(star, 5))
		star_label.visible = true
	if element_icon:
		element_icon.texture = UI_ICON_PROVIDER.get_spell_element_texture(element)
	if meta_label:
		meta_label.text = _get_element_name(element)
	
	var level = int(data.get("level", 0))
	var obtained = bool(data.get("obtained", false)) or level > 0
	var is_equipped = spell_system.is_spell_equipped(spell_id) if spell_system else false
	var spell_type = info.get("type", "")
	var is_production = (spell_type == "production")

	SPELL_THUMBNAIL_TEMPLATE.apply_thumbnail_state(card as PanelContainer, rarity_color, is_equipped)
	if rarity_strip:
		rarity_strip.color = rarity_color
	if equipped_badge:
		equipped_badge.visible = is_equipped
	
	if status_label:
		if not obtained or level <= 0:
			status_label.text = "未获取"
			status_label.add_theme_color_override("font_color", Color.GRAY)
		else:
			status_label.text = "Lv." + str(level)
			if is_equipped:
				status_label.add_theme_color_override("font_color", Color(0.12, 0.52, 0.2, 1.0))
			else:
				status_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	
	if star_badge:
		star_badge.visible = star > 0
	if star_label:
		star_label.text = "★%d" % min(star, 5) if star > 0 else ""
	
	if equip_btn:
		for conn in equip_btn.pressed.get_connections():
			equip_btn.pressed.disconnect(conn.callable)

		if is_production:
			button_container.visible = false
			equip_btn.visible = false
			equip_btn.disabled = true
		else:
			button_container.visible = true
			equip_btn.visible = true
			
			if obtained and level > 0:
				if is_equipped:
					equip_btn.text = "卸下"
					ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(equip_btn, Vector2.ZERO, -1, {"feedback": false})
				else:
					equip_btn.text = "装备"
					ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(equip_btn, Vector2.ZERO, -1, {"feedback": false})
				equip_btn.disabled = false
				equip_btn.pressed.connect(_on_equip_button_pressed.bind(spell_id))
			else:
				equip_btn.text = "装备"
				equip_btn.disabled = true
				ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(equip_btn, Vector2.ZERO, -1, {"feedback": false})

	_touch_states[spell_id] = {"active": false, "start_pos": Vector2.ZERO, "touch_id": -1, "moved": false}
	for conn in card.gui_input.get_connections():
		card.gui_input.disconnect(conn.callable)
	card.gui_input.connect(_on_card_input.bind(spell_id))
	
	return card

func _create_card_template() -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	SPELL_THUMBNAIL_TEMPLATE.apply_to_card(card, {
		"bg_color": SPELL_THUMBNAIL_TEMPLATE.OPTIMIZED_BG_COLOR
	})
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var top_area = Control.new()
	top_area.name = "TopArea"
	top_area.custom_minimum_size = Vector2(0, 40)
	top_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_area)

	var rarity_strip = ColorRect.new()
	rarity_strip.name = "RarityStrip"
	rarity_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rarity_strip.offset_left = 10
	rarity_strip.offset_top = 7
	rarity_strip.offset_right = -10
	rarity_strip.offset_bottom = 11
	rarity_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_area.add_child(rarity_strip)

	var equipped_badge = _create_spell_card_badge("EquippedBadge", "已装备", Color(0.90, 0.68, 0.19, 1.0))
	equipped_badge.anchor_left = 0.0
	equipped_badge.anchor_right = 0.0
	equipped_badge.offset_left = 9
	equipped_badge.offset_right = 66
	equipped_badge.offset_top = 17
	equipped_badge.offset_bottom = 39
	top_area.add_child(equipped_badge)

	var star_badge = _create_spell_card_badge("StarBadge", "", Color(0.96, 0.76, 0.20, 1.0))
	star_badge.anchor_left = 1.0
	star_badge.anchor_right = 1.0
	star_badge.offset_left = -52
	star_badge.offset_right = -9
	star_badge.offset_top = 17
	star_badge.offset_bottom = 39
	var star_label = star_badge.get_node_or_null("StarLabel") as Label
	if star_label:
		star_label.add_theme_font_size_override("font_size", 12)
	top_area.add_child(star_badge)
	
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 44)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	vbox.add_child(name_label)

	var meta_row = PanelContainer.new()
	meta_row.name = "MetaRow"
	meta_row.custom_minimum_size = Vector2(0, 28)
	meta_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var meta_style = _create_spell_card_style(
		Color(1.0, 0.97, 0.88, 0.55),
		Color(0.81, 0.73, 0.58, 0.30),
		10,
		1
	)
	meta_style.content_margin_left = 6
	meta_style.content_margin_right = 6
	meta_style.content_margin_top = 2
	meta_style.content_margin_bottom = 2
	meta_row.add_theme_stylebox_override("panel", meta_style)
	vbox.add_child(meta_row)

	var meta_content = HBoxContainer.new()
	meta_content.name = "MetaContent"
	meta_content.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_content.add_theme_constant_override("separation", 5)
	meta_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meta_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.add_child(meta_content)

	var element_icon = TextureRect.new()
	element_icon.name = "ElementIcon"
	element_icon.custom_minimum_size = Vector2(22, 22)
	element_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	element_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	element_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_content.add_child(element_icon)

	var meta_label = Label.new()
	meta_label.name = "MetaLabel"
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 15)
	meta_label.add_theme_color_override("font_color", Color(0.36, 0.33, 0.29, 1.0))
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_content.add_child(meta_label)
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(0, 24)
	status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(status_label)
	
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(button_container)
	
	var equip_button = Button.new()
	equip_button.name = "EquipButton"
	equip_button.custom_minimum_size = Vector2(92, 31)
	equip_button.add_theme_font_size_override("font_size", 14)
	button_container.add_child(equip_button)

	var bottom_spacer = Control.new()
	bottom_spacer.name = "BottomSpacer"
	bottom_spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(bottom_spacer)
	
	return card

func _create_spell_card_badge(node_name: String, text: String, color: Color) -> PanelContainer:
	var badge = PanelContainer.new()
	badge.name = node_name
	badge.custom_minimum_size = Vector2(48, 22)
	badge.layout_mode = 1
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_top = 17
	badge.offset_bottom = 39
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _create_spell_card_style(color, color.darkened(0.18), 11, 1))

	var label = Label.new()
	label.name = "StarLabel" if node_name == "StarBadge" else "BadgeLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge

func _create_spell_card_style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	return style

func _return_card_to_pool(card: Control):
	if card.get_parent():
		card.get_parent().remove_child(card)
	if _card_pool.size() < _max_pool_size:
		_card_pool.append(card)
		card.visible = false
	else:
		card.queue_free()

func _on_card_input(event: InputEvent, spell_id: String):
	var state = _touch_states.get(spell_id, {"active": false, "start_pos": Vector2.ZERO, "touch_id": -1, "moved": false})
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			state["active"] = true
			state["start_pos"] = mb.position
			state["moved"] = false
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if bool(state.get("active", false)) and not bool(state.get("moved", false)):
				_show_spell_detail(spell_id)
			state["active"] = false
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if bool(state.get("active", false)):
			if mm.position.distance_to(state.get("start_pos", Vector2.ZERO)) > TOUCH_SLOP:
				state["moved"] = true
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			state["active"] = true
			state["touch_id"] = st.index
			state["start_pos"] = st.position
			state["moved"] = false
		else:
			if bool(state.get("active", false)) and int(state.get("touch_id", -1)) == st.index and not bool(state.get("moved", false)):
				_show_spell_detail(spell_id)
			state["active"] = false
			state["touch_id"] = -1
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if bool(state.get("active", false)) and int(state.get("touch_id", -1)) == sd.index:
			if sd.position.distance_to(state.get("start_pos", Vector2.ZERO)) > TOUCH_SLOP:
				state["moved"] = true
	_touch_states[spell_id] = state

func _on_equip_button_pressed(spell_id: String):
	current_viewing_spell = spell_id
	_on_spell_equip_toggle()

func _show_spell_detail(spell_id: String):
	current_viewing_spell = spell_id
	if not spell_detail_popup:
		_create_spell_detail_popup()
	_update_spell_detail_popup()
	spell_detail_popup.show_popup()
	spell_viewed.emit(spell_id)

func _create_spell_detail_popup():
	spell_detail_popup = SpellDetailPopup.new()
	spell_detail_popup.name = "SpellDetailPopup"
	if game_ui and game_ui is Control:
		game_ui.add_child(spell_detail_popup)
		spell_detail_popup.setup(game_ui)
	else:
		add_child(spell_detail_popup)
		spell_detail_popup.setup(self)
	spell_detail_popup.close_requested.connect(_on_spell_detail_close_pressed)
	spell_detail_popup.upgrade_requested.connect(_on_spell_upgrade_pressed)
	spell_detail_popup.star_up_requested.connect(_on_spell_star_up_pressed)
	spell_detail_popup.charge_requested.connect(_on_spell_charge_pressed)
	spell_detail_popup.multiplier_changed.connect(_on_multiplier_changed)

func _update_spell_detail_popup():
	if not spell_detail_popup or current_viewing_spell.is_empty():
		return
	var info = spell_data.get_spell_data(current_viewing_spell)
	var display_data = spell_system.get_spell_info(current_viewing_spell).duplicate(true)
	if display_data.is_empty():
		var player_spells = spell_system.get_player_spells()
		var data = player_spells.get(current_viewing_spell, {})
		display_data = data.duplicate(true)
		if not display_data.has("id"):
			display_data["id"] = current_viewing_spell
	display_data["rarity"] = str(info.get("rarity", spell_data.get_spell_rarity(current_viewing_spell) if spell_data else "fan"))
	display_data["element"] = str(info.get("element", spell_data.get_spell_element(current_viewing_spell) if spell_data else "none"))
	display_data["max_star"] = int(info.get("max_star", spell_data.get_spell_max_star(current_viewing_spell) if spell_data else 5))
	spell_detail_popup.update_content(display_data, info, spell_system, spell_data, current_multiplier_index, MULTIPLIERS)


func refresh_visible_detail_popup() -> bool:
	if not spell_detail_popup or not spell_detail_popup.is_popup_visible():
		return false
	if current_viewing_spell.is_empty() or not spell_system or not spell_data:
		return false
	_update_spell_detail_popup()
	return true


func _update_use_count_label_only():
	if spell_detail_popup and not current_viewing_spell.is_empty():
		var player_spells = spell_system.get_player_spells()
		var data = player_spells.get(current_viewing_spell, {})
		var info = spell_data.get_spell_data(current_viewing_spell)
		var display_data = data.duplicate()
		if not display_data.has("id"):
			display_data["id"] = current_viewing_spell
		spell_detail_popup.update_use_count_only(display_data, info, spell_data)

func _on_spell_detail_close_pressed():
	current_viewing_spell = ""
	if spell_detail_popup:
		spell_detail_popup.hide_popup()

func _on_multiplier_changed():
	current_multiplier_index = (current_multiplier_index + 1) % MULTIPLIERS.size()
	if spell_detail_popup:
		_update_spell_detail_popup()

func _on_spell_equip_toggle():
	if current_viewing_spell.is_empty(): return
	if not _begin_action_lock("spell_equip_toggle"): return
	
	var is_currently_equipped = spell_system.is_spell_equipped(current_viewing_spell)
	var slot_type = _get_slot_type_by_spell(current_viewing_spell)
	var result
	if is_currently_equipped:
		result = await api.spell_unequip(current_viewing_spell, slot_type)
	else:
		result = await api.spell_equip(current_viewing_spell, slot_type)
		
	if not result.get("success", false):
		var err_msg = _get_spell_result_text(result, "术法操作失败")
		if not err_msg.is_empty():
			_add_log(err_msg)
		_end_action_lock("spell_equip_toggle")
		return
	
	if is_currently_equipped:
		spell_system.unequip_spell(current_viewing_spell)
		_add_log(_get_spell_result_text(result, "卸下成功"))
		spell_unequipped.emit(current_viewing_spell)
	else:
		spell_system.equip_spell(current_viewing_spell)
		_add_log(_get_spell_result_text(result, "装备成功"))
		spell_equipped.emit(current_viewing_spell)

	var feedback_spell_id := current_viewing_spell
	update_spell_ui()
	_update_spell_detail_popup()
	_play_spell_card_success_feedback(feedback_spell_id)
	_end_action_lock("spell_equip_toggle")

func _on_spell_upgrade_pressed():
	if current_viewing_spell.is_empty(): return
	var result = await api.spell_upgrade(current_viewing_spell)
	if result.get("success", false):
		_add_log(_get_spell_result_text(result, "术法升级成功"))
		await _refresh_after_spell_action()
		_update_spell_detail_popup()
		_play_spell_detail_success_feedback()
		spell_upgraded.emit(current_viewing_spell)
	else:
		var err_msg = _get_spell_result_text(result, "升级失败")
		if not err_msg.is_empty():
			_add_log(err_msg)

func _on_spell_star_up_pressed():
	if current_viewing_spell.is_empty():
		return
	var result = await api.spell_star_up(current_viewing_spell)
	if result.get("success", false):
		_add_log(_get_spell_result_text(result, "术法升星成功"))
		if game_ui and game_ui.has_method("refresh_inventory_ui") and game_ui.chuna_module and game_ui.chuna_module.has_method("_refresh_inventory_from_server"):
			await game_ui.chuna_module._refresh_inventory_from_server()
		await _refresh_after_spell_action()
		_update_spell_detail_popup()
		spell_star_upgraded.emit(current_viewing_spell)
	else:
		var err_msg = _get_spell_result_text(result, "升星失败")
		if not err_msg.is_empty():
			_add_log(err_msg)

func _flush_cultivation_before_spell_action(action_name: String) -> bool:
	if game_ui and game_ui.get("cultivation_module") and game_ui.get("cultivation_module").has_method("flush_pending_and_then"):
		var settle_ok = await game_ui.get("cultivation_module").flush_pending_and_then(func(): pass)
		if not settle_ok:
			_add_log(action_name + "前修炼同步失败，请稍后重试")
			return false
	return true

func _apply_local_charge_result(result: Dictionary):
	var reason_data = result.get("reason_data", {})
	var charged_amount = float(reason_data.get("charged_amount", result.get("charged_amount", 0)))
	if charged_amount <= 0.0:
		return

	if player:
		player.set_spirit(max(0.0, float(player.spirit_energy) - charged_amount))

	if spell_system:
		var player_spells = spell_system.get_player_spells()
		if player_spells.has(current_viewing_spell):
			var spell_info = player_spells[current_viewing_spell]
			spell_info["charged_spirit"] = int(spell_info.get("charged_spirit", 0)) + int(charged_amount)

	if game_ui and game_ui.has_method("update_ui"):
		game_ui.update_ui()

func _on_spell_charge_pressed():
	if current_viewing_spell.is_empty():
		return
	if not _begin_action_lock("spell_charge"):
		return
	var settle_ok = await _flush_cultivation_before_spell_action("充灵")
	if not settle_ok:
		_end_action_lock("spell_charge")
		return
	var multiplier = MULTIPLIERS[current_multiplier_index]
	var result = await api.spell_charge(current_viewing_spell, multiplier)
	if result.get("success", false):
		_apply_local_charge_result(result)
		_add_log(_get_spell_result_text(result, "充灵成功"))
		_update_spell_detail_popup()
		await _refresh_after_spell_action()
		_update_spell_detail_popup()
	else:
		var err_msg = _get_spell_result_text(result, "充灵失败")
		if not err_msg.is_empty():
			_add_log(err_msg)
	_end_action_lock("spell_charge")

func _refresh_after_spell_action():
	await _refresh_spell_from_server()
	update_spell_ui()

func _play_spell_card_success_feedback(spell_id: String) -> void:
	var card = spell_cards.get(spell_id, null)
	if card is Control and is_instance_valid(card):
		UI_FEEDBACK_MANAGER.play_soft_flash(card, {
			"flash_color": Color(1.0, 0.90, 0.52, 1.0),
			"duration": 0.34
		})

func _play_spell_detail_success_feedback() -> void:
	if spell_detail_popup and spell_detail_popup.has_method("play_success_feedback"):
		spell_detail_popup.play_success_feedback()

func _refresh_spell_from_server():
	if not api or not spell_system:
		return
	var result = await api.spell_list()
	if not result.get("success", false):
		var err_msg = api.network_manager.get_api_error_text_for_ui(result, "术法同步失败")
		if not err_msg.is_empty():
			_add_log(err_msg)
		return

	if spell_data and spell_data.has_method("apply_remote_config"):
		var remote_spell_config = result.get("spells_config", {})
		if remote_spell_config is Dictionary and not remote_spell_config.is_empty():
			spell_data.apply_remote_config({"spells": remote_spell_config})

	var payload = {
		"player_spells": result.get("player_spells", {}),
		"equipped_spells": result.get("equipped_spells", {})
	}
	spell_system.apply_save_data(payload)
	if game_ui and game_ui.has_method("update_ui"):
		game_ui.update_ui()

func _get_slot_type_by_spell(spell_id: String) -> String:
	if not spell_data:
		return "active"
	var spell_info = spell_data.get_spell_data(spell_id)
	var raw_type = spell_info.get("type", "active")
	var type_str = str(raw_type).to_lower()
	match type_str:
		"breathing":
			return "breathing"
		"production":
			return "production"
		"active", "attack":
			return "active"
		"passive", "opening":
			return "opening"
		_:
			return "active"

func _get_spell_rarity_color(rarity: String) -> Color:
	var game_manager = get_node_or_null("/root/GameManager")
	var item_data = game_manager.get_item_data() if game_manager and game_manager.has_method("get_item_data") else null
	if item_data and item_data.has_method("get_item_rarity_color"):
		return item_data.get_item_rarity_color(rarity)
	return Color(0.2, 0.2, 0.2, 1.0)

func _get_element_name(element: String) -> String:
	match element:
		"metal":
			return "金"
		"wood":
			return "木"
		"water":
			return "水"
		"fire":
			return "火"
		"earth":
			return "土"
		_:
			return "无"

func _add_log(message: String):
	log_message.emit(message)

func on_spell_used(spell_id: String):
	# Use count is only visible in the detail popup; rebuilding every spell card
	# would make production loops like herb gathering pay a repeated UI cost.
	if current_viewing_spell == spell_id:
		_update_use_count_label_only()
		_update_spell_detail_popup()

func _begin_action_lock(action: String) -> bool:
	return _action_lock.try_begin(action)

func _end_action_lock(action: String):
	_action_lock.end(action, ACTION_COOLDOWN_SECONDS)
