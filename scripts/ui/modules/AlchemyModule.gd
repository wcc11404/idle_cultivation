class_name AlchemyModule extends Node

# 炼丹模块 - 处理炼丹房逻辑

# === 信号 ===
signal recipe_selected(recipe_id: String)
signal crafting_started(recipe_id: String, count: int)
signal crafting_finished(success_count: int, fail_count: int)
signal crafting_stopped(completed_count: int, remaining_count: int)
signal log_message(message: String)
signal back_to_dongfu_requested

# === 样式常量 ===
const COLOR_BG_LIGHT := Color(0.92, 0.90, 0.87, 1.0)
const COLOR_BG_SELECTED := Color(0.85, 0.82, 0.75, 1.0)
const COLOR_BG_PANEL := Color(0.85, 0.82, 0.78, 0.75)
const COLOR_TEXT_DARK := Color(0.25, 0.22, 0.18, 1.0)
const COLOR_TEXT_DARKER := Color(0.15, 0.12, 0.10, 1.0)
const COLOR_TEXT_LIGHT := Color(0.95, 0.95, 0.92, 1.0)
const COLOR_TEXT_RED := Color(0.75, 0.25, 0.25, 1.0)
const COLOR_INDICATOR := Color(0.3, 0.55, 0.3, 1.0)
const COLOR_BUTTON_GREEN := Color(0.35, 0.50, 0.35, 1.0)
const COLOR_BUTTON_RED := Color(0.6, 0.35, 0.35, 1.0)
const COLOR_PROGRESS_BG := Color(0.5, 0.47, 0.43, 1.0)
const COLOR_PROGRESS_FILL := Color(0.3, 0.6, 0.3, 1.0)

const FONT_SIZE_TITLE := 24
const FONT_SIZE_NORMAL := 18
const FONT_SIZE_SMALL := 16

# === 引用 ===
var game_ui: Node = null
var player: Node = null
var alchemy_system: Node = null
var recipe_data: Node = null
var item_data: Node = null

# === UI节点引用 ===
var alchemy_room_panel: Control = null
var recipe_list_container: VBoxContainer = null
var recipe_name_label: Label = null
var success_rate_label: Label = null
var craft_time_label: Label = null
var materials_container: VBoxContainer = null
var craft_button: Button = null
var stop_button: Button = null
var craft_progress_bar: ProgressBar = null
var alchemy_info_label: Label = null
var furnace_info_label: Label = null
var craft_count_label: Label = null
var count_1_button: Button = null
var count_10_button: Button = null
var alchemy_back_button: Button = null
var count_100_button: Button = null
var count_max_button: Button = null

# === 状态 ===
var selected_recipe: String = ""
var selected_count: int = 1
var is_crafting: bool = false
var current_craft_index: int = 0
var total_craft_count: int = 0
var craft_success_count: int = 0
var craft_fail_count: int = 0
var craft_materials: Dictionary = {}

# === 缓存 ===
var _recipe_cards: Dictionary = {}
var _material_labels: Dictionary = {}
var _cached_recipe_materials: Dictionary = {}
var _progress_margin_added: bool = false

# === 初始化 ===
func _ready():
	pass

func initialize(ui: Node, player_node: Node, alchemy_sys: Node, recipe_data_node: Node, item_data_node: Node):
	game_ui = ui
	player = player_node
	alchemy_system = alchemy_sys
	recipe_data = recipe_data_node
	item_data = item_data_node
	_setup_back_button()

func setup_styles():
	_setup_ui_style()
	_setup_signals()

func _setup_signals():
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)
		craft_button.disabled = false
	else:
		push_warning("AlchemyModule: craft_button is null")
	
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
		stop_button.disabled = true
	else:
		push_warning("AlchemyModule: stop_button is null")

# === 样式设置 ===
func _setup_ui_style():
	if not alchemy_room_panel:
		return
	alchemy_room_panel.modulate = Color(1, 1, 1, 0.95)
	_apply_panel_style_recursive(alchemy_room_panel)
	_setup_craft_panel_style()

func _setup_craft_panel_style():
	_style_recipe_name_label()
	_style_info_labels()
	_style_materials_section()
	_style_progress_section()
	_style_count_buttons()
	_style_craft_button()

func _style_recipe_name_label():
	if not recipe_name_label:
		return
	recipe_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_name_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	recipe_name_label.add_theme_color_override("font_color", COLOR_TEXT_DARKER)
	recipe_name_label.custom_minimum_size = Vector2(0, 40)

func _style_info_labels():
	for label in [success_rate_label, craft_time_label]:
		if label:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
			label.add_theme_color_override("font_color", Color(0.3, 0.28, 0.25, 1.0))

func _style_materials_section():
	if not materials_container:
		return
	
	# 设置materials_container的边距
	var margin = MarginContainer.new()
	margin.name = "MaterialsMargin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	var parent = materials_container.get_parent()
	if parent and not parent.get_node_or_null("MaterialsMargin"):
		var idx = materials_container.get_index()
		parent.remove_child(materials_container)
		margin.add_child(materials_container)
		parent.add_child(margin)
		parent.move_child(margin, idx)
	
	parent = materials_container.get_parent()
	if parent and parent.name == "MaterialsMargin":
		parent = parent.get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is Label and child.name == "MaterialsLabel":
			child.text = "◇ 材料需求 ◇"
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			child.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
			child.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		elif child is HSeparator:
			var sep_style = StyleBoxLine.new()
			sep_style.color = Color(0.5, 0.47, 0.42, 1.0)
			sep_style.thickness = 2
			sep_style.grow_begin = -8
			sep_style.grow_end = -8
			child.add_theme_stylebox_override("separator", sep_style)

func _style_progress_section():
	if craft_count_label:
		craft_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		craft_count_label.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
		craft_count_label.add_theme_color_override("font_color", Color(0.3, 0.28, 0.25, 1.0))
	
	_style_progress_bar()

func _style_progress_bar():
	if not craft_progress_bar:
		return
	
	craft_progress_bar.custom_minimum_size = Vector2(0, 28)
	craft_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	craft_progress_bar.max_value = 100.0
	craft_progress_bar.min_value = 0.0
	craft_progress_bar.value = 0.0
	craft_progress_bar.show_percentage = false
	
	_add_progress_bar_margin()
	_apply_progress_bar_styles()

func _add_progress_bar_margin():
	if _progress_margin_added:
		return
	
	var parent = craft_progress_bar.get_parent()
	if not parent:
		return
	
	var margin_container = MarginContainer.new()
	margin_container.name = "ProgressMargin"
	margin_container.add_theme_constant_override("margin_left", 24)
	margin_container.add_theme_constant_override("margin_right", 24)
	
	var idx = craft_progress_bar.get_index()
	parent.remove_child(craft_progress_bar)
	margin_container.add_child(craft_progress_bar)
	parent.add_child(margin_container)
	parent.move_child(margin_container, idx)
	_progress_margin_added = true

func _apply_progress_bar_styles():
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = COLOR_PROGRESS_BG
	style_bg.border_color = Color(0.4, 0.37, 0.33, 1.0)
	style_bg.set_border_width_all(1)
	style_bg.set_corner_radius_all(6)
	style_bg.content_margin_left = 2
	style_bg.content_margin_right = 2
	style_bg.content_margin_top = 2
	style_bg.content_margin_bottom = 2
	craft_progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = COLOR_PROGRESS_FILL
	style_fill.set_corner_radius_all(4)
	craft_progress_bar.add_theme_stylebox_override("fill", style_fill)

func _style_count_buttons():
	_update_count_button_styles()

func _update_count_button_styles():
	var button_configs = [
		{btn = count_1_button, count = 1},
		{btn = count_10_button, count = 10},
		{btn = count_100_button, count = 100},
		{btn = count_max_button, count = -1}
	]
	
	for config in button_configs:
		var btn = config.btn
		if not btn:
			continue
		
		var is_selected = (selected_count == config.count) or (config.count == -1 and selected_count > 100)
		_apply_count_button_style(btn, is_selected)

func _apply_count_button_style(btn: Button, is_selected: bool):
	btn.custom_minimum_size = Vector2(60, 40)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	
	if is_selected:
		normal_style.bg_color = Color(0.55, 0.52, 0.48, 1.0)
		normal_style.border_color = Color(0.35, 0.32, 0.28, 1.0)
		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88, 1.0))
	else:
		normal_style.bg_color = Color(0.82, 0.78, 0.72, 1.0)
		normal_style.border_color = Color(0.55, 0.50, 0.45, 1.0)
		btn.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.75, 0.71, 0.65, 1.0) if not is_selected else Color(0.60, 0.57, 0.53, 1.0)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.68, 0.64, 0.58, 1.0) if not is_selected else Color(0.50, 0.47, 0.43, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.88, 0.85, 0.80, 0.5)
	btn.add_theme_stylebox_override("disabled", disabled_style)

func _style_craft_button():
	if not craft_button:
		return
	
	craft_button.text = "开始炼制"
	craft_button.custom_minimum_size = Vector2(160, 56)
	craft_button.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	
	var normal_style = _create_button_style(COLOR_BUTTON_GREEN, Color(0.25, 0.40, 0.25, 1.0))
	craft_button.add_theme_stylebox_override("normal", normal_style)
	craft_button.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.40, 0.55, 0.40, 1.0)
	craft_button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.30, 0.45, 0.30, 1.0)
	craft_button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.6, 0.58, 0.55, 0.6)
	disabled_style.border_color = Color(0.5, 0.48, 0.45, 0.6)
	craft_button.add_theme_stylebox_override("disabled", disabled_style)
	craft_button.add_theme_color_override("font_disabled_color", Color(0.4, 0.38, 0.35, 1.0))
	
	_style_stop_button()

func _style_stop_button():
	if not stop_button:
		return
	
	stop_button.text = "停止"
	stop_button.custom_minimum_size = Vector2(160, 56)
	stop_button.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	
	var stop_normal = _create_button_style(COLOR_BUTTON_RED, Color(0.5, 0.25, 0.25, 1.0))
	stop_button.add_theme_stylebox_override("normal", stop_normal)
	stop_button.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	
	var stop_hover = stop_normal.duplicate()
	stop_hover.bg_color = Color(0.65, 0.40, 0.40, 1.0)
	stop_button.add_theme_stylebox_override("hover", stop_hover)

func _create_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _apply_panel_style_recursive(node: Node):
	if node is Panel or node is PanelContainer:
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_BG_PANEL
		style.set_corner_radius_all(8)
		node.add_theme_stylebox_override("panel", style)
	
	for child in node.get_children():
		_apply_panel_style_recursive(child)

# === 返回按钮 ===
func _setup_back_button():
	if not alchemy_room_panel:
		return
	
	# 如果场景中已有返回按钮，直接应用样式
	if alchemy_back_button:
		_apply_count_button_style(alchemy_back_button, false)
		return
	
	# 否则动态创建返回按钮
	var title_bar = alchemy_room_panel.get_node_or_null("VBoxContainer/TitleBar")
	if title_bar:
		return
	
	var vbox = alchemy_room_panel.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	title_bar = HBoxContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size = Vector2(0, 40)
	
	var back_button = Button.new()
	back_button.text = "< 返回"
	back_button.custom_minimum_size = Vector2(80, 40)
	back_button.pressed.connect(_on_back_button_pressed)
	_apply_count_button_style(back_button, false)
	title_bar.add_child(back_button)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)
	
	vbox.add_child(title_bar)
	vbox.move_child(title_bar, 0)

func _on_back_button_pressed():
	back_to_dongfu_requested.emit()

# === 显示/隐藏 ===
func show_alchemy_room():
	if alchemy_room_panel:
		alchemy_room_panel.visible = true
		_update_recipe_list()
		_update_alchemy_info()
		if selected_recipe:
			_update_materials_display()

func hide_alchemy_room():
	if alchemy_room_panel:
		alchemy_room_panel.visible = false

func refresh_ui():
	_update_recipe_list()
	_update_alchemy_info()
	if selected_recipe:
		_update_materials_display()
		_update_craft_count_label()
		if craft_button and not is_crafting:
			craft_button.disabled = false

# === 丹方列表 ===
func _update_recipe_list():
	if not recipe_list_container or not player or is_crafting:
		return
	
	for child in recipe_list_container.get_children():
		child.queue_free()
	_recipe_cards.clear()
	
	if player.learned_recipes.is_empty():
		var label = Label.new()
		label.text = "暂无学会的丹方"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
		recipe_list_container.add_child(label)
		return
	
	var sorted_recipes = _sort_recipes(player.learned_recipes)
	
	for recipe_id in sorted_recipes:
		var recipe_name = recipe_data.get_recipe_name(recipe_id)
		var card = _create_recipe_card(recipe_id, recipe_name)
		recipe_list_container.add_child(card)
		_recipe_cards[recipe_id] = card
	
	_update_recipe_selection()
	
	if not selected_recipe and sorted_recipes.size() > 0:
		_select_recipe(sorted_recipes[0])

func _create_recipe_card(recipe_id: String, recipe_name: String) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 44)
	
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_LIGHT
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	
	var indicator = ColorRect.new()
	indicator.name = "SelectedIndicator"
	indicator.custom_minimum_size = Vector2(4, 24)
	indicator.color = Color(0.3, 0.5, 0.3, 0.0)
	hbox.add_child(indicator)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(spacer)
	
	var name_label = Label.new()
	name_label.name = "RecipeNameLabel"
	name_label.text = recipe_name
	name_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	name_label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)
	hbox.add_child(name_label)
	
	var button = Button.new()
	button.name = "ClickButton"
	button.modulate = Color(1, 1, 1, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): _on_recipe_card_clicked(recipe_id))
	card.add_child(button)
	
	card.set_meta("recipe_id", recipe_id)
	return card

func _on_recipe_card_clicked(recipe_id: String):
	if is_crafting:
		return
	selected_recipe = recipe_id
	recipe_selected.emit(recipe_id)
	_update_recipe_selection()
	_update_craft_panel()

func _update_recipe_selection():
	for recipe_id in _recipe_cards:
		var card = _recipe_cards[recipe_id]
		if is_instance_valid(card):
			_apply_card_selection_style(card, recipe_id == selected_recipe)

func _apply_card_selection_style(card: Control, is_selected: bool):
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	if not style:
		style = StyleBoxFlat.new()
		card.add_theme_stylebox_override("panel", style)
	
	var indicator = card.find_child("SelectedIndicator", true, false)
	var name_label = card.find_child("RecipeNameLabel", true, false)
	
	if is_selected:
		style.bg_color = COLOR_BG_SELECTED
		if indicator:
			indicator.color = COLOR_INDICATOR
		if name_label:
			name_label.add_theme_color_override("font_color", COLOR_TEXT_DARKER)
	else:
		style.bg_color = COLOR_BG_LIGHT
		if indicator:
			indicator.color = Color(0.3, 0.5, 0.3, 0.0)
		if name_label:
			name_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)

func _sort_recipes(recipes: Array) -> Array:
	var breakthrough_keywords = ["foundation", "golden_core", "nascent_soul", "spirit_separation", 
		"void_refining", "body_integration", "mahayana", "tribulation"]
	
	var result = recipes.duplicate()
	result.sort_custom(func(a, b):
		var a_is_breakthrough = breakthrough_keywords.any(func(k): return a.contains(k))
		var b_is_breakthrough = breakthrough_keywords.any(func(k): return b.contains(k))
		
		if a_is_breakthrough != b_is_breakthrough:
			return a_is_breakthrough
		return a < b
	)
	return result

func _select_recipe(recipe_id: String):
	if is_crafting:
		return
	selected_recipe = recipe_id
	recipe_selected.emit(recipe_id)
	_update_recipe_selection()
	_update_craft_panel()

# === 炼制面板 ===
func _update_craft_panel():
	if not selected_recipe or not recipe_data or not alchemy_system:
		_clear_craft_panel()
		return
	
	if recipe_name_label:
		recipe_name_label.text = "【 %s 】" % recipe_data.get_recipe_name(selected_recipe)
	
	var success_rate = alchemy_system.calculate_success_rate(selected_recipe)
	var craft_time = alchemy_system.calculate_craft_time(selected_recipe)
	
	if success_rate_label:
		success_rate_label.text = "成功率 %d%%" % success_rate
	if craft_time_label:
		craft_time_label.text = "耗时 %.1f秒" % craft_time
	
	_update_materials_display()
	_update_craft_count_label()
	
	if craft_button and not is_crafting:
		craft_button.text = "开始炼制"
		craft_button.disabled = false

func _clear_craft_panel():
	if recipe_name_label:
		recipe_name_label.text = "请选择丹方"
	if success_rate_label:
		success_rate_label.text = "成功率 -"
	if craft_time_label:
		craft_time_label.text = "耗时 -"
	if materials_container:
		for child in materials_container.get_children():
			child.queue_free()
	_material_labels.clear()
	_cached_recipe_materials.clear()
	if craft_count_label:
		craft_count_label.text = "制作: 第 0 颗 / 共 0 颗"
	if craft_progress_bar:
		craft_progress_bar.value = 0
	if craft_button:
		craft_button.text = "开始炼制"
		craft_button.disabled = true

# === 材料显示 ===
func _update_materials_display():
	if not materials_container or not selected_recipe or not recipe_data:
		return
	
	var materials = recipe_data.get_recipe_materials(selected_recipe)
	
	if _cached_recipe_materials != materials:
		_cached_recipe_materials = materials.duplicate()
		_rebuild_material_labels(materials)
	else:
		_update_material_labels_text()

func _rebuild_material_labels(materials: Dictionary):
	for child in materials_container.get_children():
		child.get_parent().remove_child(child)
		child.free()
	_material_labels.clear()
	
	# 创建两列布局
	var hbox = HBoxContainer.new()
	hbox.name = "MaterialsHBox"
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	materials_container.add_child(hbox)
	
	var col1 = VBoxContainer.new()
	col1.name = "Column1"
	col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col1.custom_minimum_size = Vector2(0, 90)
	hbox.add_child(col1)
	
	var col2 = VBoxContainer.new()
	col2.name = "Column2"
	col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.custom_minimum_size = Vector2(0, 90)
	hbox.add_child(col2)
	
	# 收集所有材料项（包括灵气）
	var all_items = []
	for material_id in materials:
		all_items.append({"type": "material", "id": material_id, "required": materials[material_id]})
	
	var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe)
	if spirit_required > 0:
		all_items.append({"type": "spirit", "id": "spirit_energy", "required": spirit_required})
	
	# 分配到两列，每列最多3个
	for i in range(all_items.size()):
		var item = all_items[i]
		var target_col = col1 if i < 3 else col2
		_create_material_item(target_col, item)

func _create_material_item(parent: VBoxContainer, item: Dictionary):
	var label = Label.new()
	
	if item.type == "spirit":
		label.name = "SpiritEnergyLabel"
		var total_spirit = item.required * selected_count
		var has_spirit = int(player.spirit_energy) if player else 0
		label.text = "灵气: %d/%d" % [has_spirit, total_spirit]
		label.add_theme_color_override("font_color", COLOR_TEXT_RED if has_spirit < total_spirit else COLOR_TEXT_DARK)
		_material_labels["spirit_energy"] = label
	else:
		var material_id = item.id
		var total_required = item.required * selected_count
		var has = alchemy_system.inventory.get_item_count(material_id)
		var item_name = item_data.get_item_name(material_id) if item_data else material_id
		label.text = "%s: %d/%d" % [item_name, has, total_required]
		label.add_theme_color_override("font_color", COLOR_TEXT_RED if has < total_required else COLOR_TEXT_DARK)
		_material_labels[material_id] = label
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
	parent.add_child(label)

func _update_material_labels_text():
	for material_id in _material_labels:
		var label = _material_labels[material_id]
		if not is_instance_valid(label):
			continue
		
		if material_id == "spirit_energy":
			var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe) if recipe_data else 0
			var total_spirit = spirit_required * selected_count
			var has_spirit = int(player.spirit_energy) if player else 0
			label.text = "灵气: %d/%d" % [has_spirit, total_spirit]
			label.add_theme_color_override("font_color", COLOR_TEXT_RED if has_spirit < total_spirit else COLOR_TEXT_DARK)
		else:
			var required_per = _cached_recipe_materials.get(material_id, 0)
			var total_required = required_per * selected_count
			var has = alchemy_system.inventory.get_item_count(material_id)
			var item_name = item_data.get_item_name(material_id) if item_data else material_id
			label.text = "%s: %d/%d" % [item_name, has, total_required]
			label.add_theme_color_override("font_color", COLOR_TEXT_RED if has < total_required else COLOR_TEXT_DARK)

func _update_craft_count_label():
	if craft_count_label:
		craft_count_label.text = "制作: 第 %d 颗 / 共 %d 颗" % [current_craft_index, selected_count]

# === 炼丹信息 ===
func _update_alchemy_info():
	if not alchemy_system:
		return
	
	var alchemy_bonus = alchemy_system.get_alchemy_bonus()
	var furnace_bonus = alchemy_system.get_furnace_bonus()
	
	if alchemy_info_label:
		if alchemy_bonus.get("obtained", false):
			var alchemy_level = alchemy_bonus.get("level", 0)
			alchemy_info_label.text = "炼丹术: LV.%d (+%d成功值, +%.0f%%速度)" % [
				alchemy_level,
				alchemy_bonus.get("success_bonus", 0),
				alchemy_bonus.get("speed_rate", 0.0) * 100
			]
		else:
			alchemy_info_label.text = "炼丹术: 未学习"
	
	if furnace_info_label:
		if furnace_bonus.get("has_furnace", false):
			furnace_info_label.text = "丹炉: 初级丹炉 (+%d成功值, +%.0f%%速度)" % [
				furnace_bonus.get("success_bonus", 0),
				furnace_bonus.get("speed_rate", 0.0) * 100
			]
		else:
			furnace_info_label.text = "丹炉: 无"

# === 炼制流程 ===
func _on_craft_pressed():
	if not selected_recipe or not alchemy_system or is_crafting:
		return
	
	var materials_check = alchemy_system.check_materials(selected_recipe, selected_count)
	if not materials_check.enough:
		log_message.emit("灵材不足，无法开炉炼丹")
		return
	
	var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe) if recipe_data else 0
	var total_spirit = spirit_required * selected_count
	if player and player.spirit_energy < total_spirit:
		log_message.emit("灵气不济，无法催动丹火")
		return
	
	if game_ui and game_ui.has_method("stop_other_activities"):
		game_ui.stop_other_activities("alchemy")
	
	craft_materials = recipe_data.get_recipe_materials(selected_recipe)
	
	_start_crafting_process()

func _start_crafting_process():
	is_crafting = true
	total_craft_count = selected_count
	current_craft_index = 0
	craft_success_count = 0
	craft_fail_count = 0
	
	_update_craft_count_label()
	
	if craft_button:
		craft_button.disabled = true
	if stop_button:
		stop_button.disabled = false
	if craft_progress_bar:
		craft_progress_bar.visible = true
		craft_progress_bar.value = 0
	
	crafting_started.emit(selected_recipe, selected_count)
	
	_craft_next_pill()

func _check_single_craft_materials() -> bool:
	if not alchemy_system or not recipe_data:
		return false
	
	for material_id in craft_materials:
		var required = craft_materials[material_id]
		var has = alchemy_system.inventory.get_item_count(material_id)
		if has < required:
			return false
	
	var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe)
	if spirit_required > 0 and player:
		if player.spirit_energy < spirit_required:
			return false
	
	return true

func _consume_single_craft_materials():
	if not alchemy_system:
		return
	
	for material_id in craft_materials:
		var required = craft_materials[material_id]
		alchemy_system.inventory.remove_item(material_id, required)
	
	var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe) if recipe_data else 0
	if spirit_required > 0 and player:
		player.consume_spirit(spirit_required)

func _craft_next_pill():
	if not is_crafting or current_craft_index >= total_craft_count:
		_finish_crafting()
		return
	
	if not _check_single_craft_materials():
		log_message.emit("灵材耗尽，炼丹中断")
		_finish_crafting()
		return
	
	_consume_single_craft_materials()
	
	current_craft_index += 1
	_update_craft_count_label()
	_update_materials_display()
	
	if craft_progress_bar:
		craft_progress_bar.value = 0
		craft_progress_bar.visible = true
	
	var craft_time = alchemy_system.calculate_craft_time(selected_recipe)
	var progress_step = 100.0 / (craft_time / 0.05)
	_update_progress_recursive(0.0, progress_step)

func _update_progress_recursive(current_progress: float, progress_step: float):
	if not is_crafting:
		return
	
	current_progress += progress_step
	if craft_progress_bar:
		craft_progress_bar.value = min(current_progress, 100)
	
	if current_progress >= 100:
		_complete_single_pill()
	else:
		var timer = get_tree().create_timer(0.05)
		timer.timeout.connect(func(): _update_progress_recursive(current_progress, progress_step))

func _complete_single_pill():
	var success_rate = alchemy_system.calculate_success_rate(selected_recipe)
	var roll = randf() * 100.0
	var recipe_name = recipe_data.get_recipe_name(selected_recipe) if recipe_data else "丹药"
	
	# 不管成功失败，都增加炼丹术使用次数
	if alchemy_system and alchemy_system.spell_system:
		alchemy_system.spell_system.add_spell_use_count("alchemy")
	
	if roll <= success_rate:
		craft_success_count += 1
		var product = recipe_data.get_recipe_product(selected_recipe)
		var product_count = recipe_data.get_recipe_product_count(selected_recipe)
		alchemy_system.inventory.add_item(product, product_count)
		log_message.emit("丹香四溢，[%s]炼制成功" % recipe_name)
	else:
		craft_fail_count += 1
		_return_materials_for_failed(1)
		log_message.emit("火候失控，[%s]炼制失败，药渣可回收部分材料" % recipe_name)
	
	_update_craft_count_label()
	_update_materials_display()
	_craft_next_pill()

func _return_materials_for_failed(fail_count: int):
	for material_id in craft_materials:
		var return_amount = int(craft_materials[material_id] * fail_count / 2.0)
		if return_amount > 0:
			alchemy_system.inventory.add_item(material_id, return_amount)

func _on_stop_pressed():
	if is_crafting:
		_stop_crafting()

func stop_crafting() -> Dictionary:
	if not is_crafting:
		return {"success": false, "reason": "未在炼制中"}
	return _stop_crafting()

func _stop_crafting() -> Dictionary:
	is_crafting = false
	
	var remaining_count = maxi(total_craft_count - current_craft_index, 0)
	var completed_count = current_craft_index
	
	for material_id in craft_materials:
		var return_amount = craft_materials[material_id]
		if return_amount > 0:
			alchemy_system.inventory.add_item(material_id, return_amount)
	
	var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe) if recipe_data else 0
	# TODO: 注意：这里使用add_spirit是有意为之，不是bug
	# 如果当前灵气超过上限，add_spirit会将灵气限制在上限内
	# 这是设计上的权衡：允许玩家通过反复开始/停止炼制来积累超过上限的灵气会破坏游戏平衡
	# 如需修改此行为，需要同时考虑游戏经济系统的整体影响
	if spirit_required > 0 and player:
		player.add_spirit(spirit_required)
	
	# 停止炼丹提示：收丹停火，返还材料，成功X枚，废丹X枚
	log_message.emit("收丹停火，返还材料，成功%d枚，废丹%d枚" % [craft_success_count, craft_fail_count])
	
	if craft_button:
		craft_button.disabled = false
		craft_button.text = "开始炼制"
	if stop_button:
		stop_button.disabled = true
	if craft_progress_bar:
		craft_progress_bar.value = 0
	
	# 重置计数并更新显示
	current_craft_index = 0
	_update_craft_count_label()
	
	crafting_stopped.emit(completed_count, remaining_count)
	
	_update_recipe_list()
	_update_craft_panel()
	_update_alchemy_info()
	
	return {"success": true, "completed_count": completed_count, "remaining_count": remaining_count}

func _finish_crafting():
	is_crafting = false
	
	if craft_button:
		craft_button.disabled = false
		craft_button.text = "开始炼制"
	if stop_button:
		stop_button.disabled = true
	if craft_progress_bar:
		craft_progress_bar.value = 0
	
	crafting_finished.emit(craft_success_count, craft_fail_count)
	
	var recipe_name = recipe_data.get_recipe_name(selected_recipe) if recipe_data else "丹药"
	if craft_success_count > 0 or craft_fail_count > 0:
		log_message.emit("此次炼丹结束，成丹%d枚，废丹%d枚" % [craft_success_count, craft_fail_count])
	
	current_craft_index = 0
	total_craft_count = 0
	craft_materials.clear()
	
	_update_recipe_list()
	_update_alchemy_info()
	_update_materials_display()
	if recipe_name_label and selected_recipe:
		recipe_name_label.text = "【 %s 】" % recipe_data.get_recipe_name(selected_recipe)
	if success_rate_label and selected_recipe:
		success_rate_label.text = "成功率 %d%%" % alchemy_system.calculate_success_rate(selected_recipe)
	if craft_time_label and selected_recipe:
		craft_time_label.text = "耗时 %.1f秒" % alchemy_system.calculate_craft_time(selected_recipe)
	_update_craft_count_label()

# === 公共方法 ===
func set_craft_count(count: int):
	if is_crafting:
		return
	selected_count = count
	_update_craft_count_label()
	_update_materials_display()
	_update_count_button_styles()

func is_crafting_active() -> bool:
	return is_crafting

func get_max_craft_count() -> int:
	if not selected_recipe or not alchemy_system:
		return 0
	
	var materials = recipe_data.get_recipe_materials(selected_recipe)
	var max_count = 9999
	
	# 计算材料能支持的最大数量
	for material_id in materials:
		var has_count = alchemy_system.inventory.get_item_count(material_id)
		var possible_count = int(has_count / materials[material_id])
		max_count = mini(max_count, possible_count)
	
	# 计算灵气能支持的最大数量
	if player and recipe_data:
		var spirit_required = recipe_data.get_recipe_spirit_energy(selected_recipe)
		if spirit_required > 0:
			var max_by_spirit = int(player.spirit_energy / spirit_required)
			max_count = mini(max_count, max_by_spirit)
	
	return max_count
