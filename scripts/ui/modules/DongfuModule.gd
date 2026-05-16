class_name DongfuModule
extends Node

const AREA_ENTRY_CARD_SCRIPT = preload("res://scripts/ui/common/AreaEntryCard.gd")

signal alchemy_room_requested
signal herb_gather_requested
signal task_panel_requested
signal log_message(message: String)

var game_ui: Node = null
var player: Node = null
var alchemy_module = null

var region_panel: Control = null
var region_list_host: VBoxContainer = null

var alchemy_workshop_button: Button = null
var herb_mountain_button: Button = null
var xianwu_office_button: Button = null

var _scroll: ScrollContainer = null
var _root_list: VBoxContainer = null
var _city_card_list: VBoxContainer = null
var _south_card_list: VBoxContainer = null
var _cards: Dictionary = {}


func initialize(ui: Node, player_node: Node, alchemy_mod = null):
	game_ui = ui
	player = player_node
	alchemy_module = alchemy_mod
	_build_layout()
	refresh_cards()


func show_tab():
	if region_panel:
		region_panel.visible = true
	refresh_cards()


func hide_tab():
	if region_panel:
		region_panel.visible = false


func refresh_cards():
	if not _root_list:
		return
	_ensure_cards()
	_refresh_gambling_card()
	_refresh_alchemy_card()
	_refresh_herb_card()
	_refresh_task_card()


func _build_layout():
	if not region_list_host:
		return
	for child in region_list_host.get_children():
		region_list_host.remove_child(child)
		child.queue_free()

	region_list_host.add_theme_constant_override("separation", 0)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	region_list_host.add_child(_scroll)
	_hide_scrollbar(_scroll.get_v_scroll_bar())

	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 14)
	scroll_margin.add_theme_constant_override("margin_top", 10)
	scroll_margin.add_theme_constant_override("margin_right", 14)
	scroll_margin.add_theme_constant_override("margin_bottom", 18)
	_scroll.add_child(scroll_margin)

	_root_list = VBoxContainer.new()
	_root_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_list.add_theme_constant_override("separation", 18)
	scroll_margin.add_child(_root_list)

	_root_list.add_child(_build_section_header("云稷城"))
	_city_card_list = VBoxContainer.new()
	_city_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_city_card_list.add_theme_constant_override("separation", 18)
	_root_list.add_child(_city_card_list)

	_root_list.add_child(_build_section_header("云稷城南"))
	_south_card_list = VBoxContainer.new()
	_south_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_south_card_list.add_theme_constant_override("separation", 18)
	_root_list.add_child(_south_card_list)


func _ensure_cards():
	if not _cards.is_empty():
		return
	_register_card("task", _create_card("task"), _city_card_list)
	_register_card("alchemy", _create_card("alchemy"), _city_card_list)
	_register_card("gambling", _create_card("gambling"), _city_card_list)
	_register_card("herb", _create_card("herb"), _south_card_list)
	alchemy_workshop_button = _get_card_button("alchemy")
	herb_mountain_button = _get_card_button("herb")
	xianwu_office_button = _get_card_button("task")
	if game_ui:
		game_ui.alchemy_workshop_button = alchemy_workshop_button
		game_ui.herb_mountain_button = herb_mountain_button
		game_ui.xianwu_office_button = xianwu_office_button


func _register_card(entry_id: String, card: Control, host: VBoxContainer) -> void:
	_cards[entry_id] = card
	host.add_child(card)


func _create_card(entry_id: String) -> Control:
	var card = AREA_ENTRY_CARD_SCRIPT.new()
	card.action_pressed.connect(_on_card_action_pressed)
	card.configure({"entry_id": entry_id})
	return card


func _get_card_button(entry_id: String) -> Button:
	var card = _cards.get(entry_id, null)
	return card.get_action_target() if card else null


func _on_card_action_pressed(entry_id: String) -> void:
	match entry_id:
		"alchemy":
			_on_alchemy_workshop_pressed()
		"herb":
			_on_herb_mountain_pressed()
		"task":
			_on_xianwu_office_pressed()
		"gambling":
			_on_gambling_house_pressed()


func _build_section_header(title: String) -> Control:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 8)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.20, 0.20, 0.20, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title_label)

	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.custom_minimum_size = Vector2(0, 10)
	section.add_child(separator)

	return section


func _refresh_alchemy_card():
	var learned_recipe_count := _get_learned_recipe_count()
	var disabled := learned_recipe_count <= 0
	var card = _cards.get("alchemy", null)
	if not card:
		return
	var description := "炉火常明的内坊小院，适合沉心炼制丹药。"
	var button_text := "进入炼丹坊"
	var disabled_reason := ""
	if disabled:
		description += " 学会任意丹方后，才可进入。"
		button_text = "尚未解锁"
	card.configure({
		"entry_id": "alchemy",
		"title": "炼丹坊",
		"description": description,
		"image_variant": "alchemy",
		"image_label": "炼丹坊",
		"image_glyph": "炉",
		"tags": [
			"已学丹方 %d" % learned_recipe_count,
			"生产型区域",
			"当前空闲"
		],
		"button_text": button_text,
		"disabled": disabled,
		"disabled_reason": disabled_reason
	})


func _refresh_herb_card():
	var spell_obtained := _is_spell_obtained("herb_gathering")
	var card = _cards.get("herb", null)
	if not card:
		return
	var description := "云稷城南侧的灵草采集地，山气温润，常见低阶草药与伴生灵植。"
	var button_text := "进入百草山"
	var disabled_reason := ""
	if not spell_obtained:
		description += " 学会草药采集术后，才可进入。"
		button_text = "尚未解锁"
	card.configure({
		"entry_id": "herb",
		"title": "百草山",
		"description": description,
		"image_variant": "herb",
		"image_label": "百草山",
		"image_glyph": "草",
		"tags": [
			"生产型区域",
			"当前空闲"
		],
		"button_text": button_text,
		"disabled": not spell_obtained,
		"disabled_reason": disabled_reason
	})


func _refresh_task_card():
	var task_counts := _get_task_claimable_counts()
	var daily_count := int(task_counts.get("daily", 0))
	var newbie_count := int(task_counts.get("newbie", 0))
	var tags: Array[String] = []
	tags.append("每日 %d项可领取" % daily_count)
	tags.append("新手 %d项可领取" % newbie_count)

	var card = _cards.get("task", null)
	if not card:
		return
	card.configure({
		"entry_id": "task",
		"title": "仙务司",
		"description": "宗门日常与新手仙务汇集之处，可在此查看进度、领取奖励与整理当前事务。",
		"image_variant": "task",
		"image_label": "仙务司",
		"image_glyph": "务",
		"tags": tags,
		"button_text": "前往仙务司",
		"disabled": false,
		"disabled_reason": ""
	})


func _refresh_gambling_card():
	var card = _cards.get("gambling", null)
	if not card:
		return
	card.configure({
		"entry_id": "gambling",
		"title": "赌坊",
		"description": "云稷城内的消遣去处，后续开放后可在此参与坊间博戏与特殊玩法。",
		"image_variant": "plain",
		"image_label": "赌坊",
		"image_glyph": "赌",
		"tags": [
			"城区娱乐",
			"暂未开放"
		],
		"button_text": "尚未开放",
		"disabled": true,
		"disabled_reason": ""
	})


func _get_spell_system() -> Node:
	if game_ui and is_instance_valid(game_ui):
		var spell_sys = game_ui.get("spell_system")
		if spell_sys:
			return spell_sys
	return null


func _is_spell_obtained(spell_id: String) -> bool:
	var spell_sys = _get_spell_system()
	if not spell_sys or not spell_sys.has_method("get_spell_info"):
		return false
	var spell_info = spell_sys.get_spell_info(spell_id)
	if spell_info.is_empty():
		return false
	return bool(spell_info.get("obtained", false)) or int(spell_info.get("level", 0)) > 0


func _get_learned_recipe_count() -> int:
	if not game_ui or not is_instance_valid(game_ui):
		return 0
	var alchemy_sys = game_ui.get("alchemy_system")
	if not alchemy_sys or not alchemy_sys.has_method("get_learned_recipes"):
		return 0
	var learned_recipes = alchemy_sys.get_learned_recipes()
	return learned_recipes.size() if learned_recipes is Array else 0


func _has_any_learned_recipe() -> bool:
	return _get_learned_recipe_count() > 0


func _get_task_claimable_counts() -> Dictionary:
	var result := {"daily": 0, "newbie": 0}
	if not game_ui or not is_instance_valid(game_ui):
		return result
	var task_mod = game_ui.get("task_module")
	if task_mod and task_mod.has_method("get_claimable_daily_count"):
		result["daily"] = int(task_mod.get_claimable_daily_count())
	if task_mod and task_mod.has_method("get_claimable_newbie_count"):
		result["newbie"] = int(task_mod.get_claimable_newbie_count())
	return result


func _on_alchemy_workshop_pressed():
	if not _has_any_learned_recipe():
		log_message.emit("需先学会任意丹方，才可进入炼丹坊")
		refresh_cards()
		return
	if region_panel:
		region_panel.visible = false
	if alchemy_module:
		alchemy_module.show_alchemy_room()
	alchemy_room_requested.emit()


func _on_herb_mountain_pressed():
	if not _is_spell_obtained("herb_gathering"):
		log_message.emit("需先学会草药采集术，才可进入百草山")
		refresh_cards()
		return
	if region_panel:
		region_panel.visible = false
	herb_gather_requested.emit()


func _on_xianwu_office_pressed():
	if region_panel:
		region_panel.visible = false
	task_panel_requested.emit()


func _on_gambling_house_pressed():
	log_message.emit("赌坊尚未开放")


func _hide_scrollbar(scrollbar: ScrollBar) -> void:
	if not scrollbar:
		return
	scrollbar.custom_minimum_size = Vector2.ZERO
	scrollbar.modulate = Color(1, 1, 1, 0)
	scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
