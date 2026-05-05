class_name SpellDetailPopup extends Panel

const POPUP_STYLE_TEMPLATE = preload("res://scripts/ui/common/PopupStyleTemplate.gd")
const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const SAFE_AREA_HELPER = preload("res://scripts/ui/common/SafeAreaHelper.gd")

## 术法详情弹窗 - 独立管理弹窗UI
## 负责显示术法详细信息、升级条件、充灵操作等

# 信号
signal upgrade_requested
signal star_up_requested
signal charge_requested
signal multiplier_changed
signal close_requested

# UI节点引用
var background: ColorRect = null
var vbox: VBoxContainer = null

# 按钮引用（用于外部更新）
var charge_button: Button = null
var multiplier_button: Button = null
var upgrade_button: Button = null
var star_up_button: Button = null
var close_button: Button = null
var overlay_host: Control = null

# 常量
const MULTIPLIER_LABELS = ["x10", "x100", "Max"]

func _init():
	name = "SpellDetailPopup"
	visible = false
	z_index = 100
	set_process_input(true)

func setup(parent_node: Node):
	"""初始化弹窗，创建所有UI元素"""
	if parent_node is Control:
		overlay_host = parent_node
	else:
		overlay_host = get_tree().current_scene as Control
	_create_background()
	_create_popup_content()
	_apply_popup_theme()
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _create_background():
	"""创建背景遮罩层"""
	if not overlay_host:
		return
	background = POPUP_STYLE_TEMPLATE.create_overlay(self, Callable(), 0.62)
	background.name = "SpellPopupBackground"
	overlay_host.add_child(background)

func _input(event: InputEvent) -> void:
	# 当弹窗显示时：点击外部关闭，点击内部不关闭
	if not visible:
		return
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var mouse_event := event as InputEventMouseButton
	if get_global_rect().has_point(mouse_event.position):
		return
	close_requested.emit()
	get_viewport().set_input_as_handled()

func _create_popup_content():
	"""创建弹窗内容"""
	layout_mode = 1
	anchors_preset = 0
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2(180.0, 180.0)
	size = Vector2(360.0, 440.0)
	mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止事件传递到背景
	
	vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.layout_mode = 1
	vbox.anchors_preset = 15
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20.0
	vbox.offset_top = 20.0
	vbox.offset_right = -20.0
	vbox.offset_bottom = -20.0
	vbox.grow_horizontal = 2
	vbox.grow_vertical = 2
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "术法详情"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.22, 0.2, 0.18, 1))
	vbox.add_child(title)
	
	# 类型
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = "类型："
	type_label.add_theme_font_size_override("font_size", 21)
	type_label.add_theme_color_override("font_color", Color(0.22, 0.2, 0.18, 1))
	vbox.add_child(type_label)

	var meta_label = Label.new()
	meta_label.name = "MetaLabel"
	meta_label.text = "五行 / 稀有度："
	meta_label.add_theme_font_size_override("font_size", 21)
	meta_label.add_theme_color_override("font_color", Color(0.22, 0.2, 0.18, 1))
	vbox.add_child(meta_label)
	
	# 等级
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "等级："
	level_label.add_theme_font_size_override("font_size", 21)
	level_label.add_theme_color_override("font_color", Color(0.22, 0.2, 0.18, 1))
	vbox.add_child(level_label)

	var star_label = Label.new()
	star_label.name = "StarLabel"
	star_label.text = "星级："
	star_label.add_theme_font_size_override("font_size", 21)
	star_label.add_theme_color_override("font_color", Color(0.22, 0.2, 0.18, 1))
	vbox.add_child(star_label)
	
	# 分隔线
	vbox.add_child(_create_section_gap(4))
	vbox.add_child(_create_thick_separator())
	vbox.add_child(_create_section_gap(2))
	
	# 属性加成
	var attr_title = Label.new()
	attr_title.name = "AttrTitleLabel"
	attr_title.text = "【属性加成】"
	attr_title.add_theme_font_size_override("font_size", 23)
	attr_title.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(attr_title)
	
	var attr_value = Label.new()
	attr_value.name = "AttributeValue"
	attr_value.text = ""
	attr_value.add_theme_font_size_override("font_size", 19)
	attr_value.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(attr_value)
	
	# 分隔线
	vbox.add_child(_create_section_gap(4))
	vbox.add_child(_create_thick_separator())
	vbox.add_child(_create_section_gap(2))
	
	# 术法效果
	var effect_title = Label.new()
	effect_title.name = "EffectTitleLabel"
	effect_title.text = "【术法效果】"
	effect_title.add_theme_font_size_override("font_size", 23)
	effect_title.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(effect_title)
	
	var effect_value = Label.new()
	effect_value.name = "EffectValue"
	effect_value.text = ""
	effect_value.add_theme_font_size_override("font_size", 19)
	effect_value.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	effect_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(effect_value)
	
	# 分隔线
	vbox.add_child(_create_section_gap(4))
	vbox.add_child(_create_thick_separator())
	vbox.add_child(_create_section_gap(2))
	
	# 升级条件
	var upgrade_title = Label.new()
	upgrade_title.name = "UpgradeTitleLabel"
	upgrade_title.text = "【升级条件】"
	upgrade_title.add_theme_font_size_override("font_size", 23)
	upgrade_title.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(upgrade_title)
	
	var max_level_label = Label.new()
	max_level_label.name = "MaxLevelLabel"
	max_level_label.text = "已达到最高等级"
	max_level_label.add_theme_font_size_override("font_size", 19)
	max_level_label.add_theme_color_override("font_color", Color(0.5, 0.18, 0.16, 1))
	max_level_label.visible = false
	vbox.add_child(max_level_label)

	var upgrade_conditions_box = VBoxContainer.new()
	upgrade_conditions_box.name = "UpgradeConditionsBox"
	upgrade_conditions_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_conditions_box.add_theme_constant_override("separation", 8)
	vbox.add_child(upgrade_conditions_box)

	var use_count_row = HBoxContainer.new()
	use_count_row.name = "UseCountRow"
	use_count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	use_count_row.add_theme_constant_override("separation", 16)
	upgrade_conditions_box.add_child(use_count_row)

	var use_count_label = Label.new()
	use_count_label.name = "UseCountLabel"
	use_count_label.text = "使用次数："
	use_count_label.custom_minimum_size = Vector2(120, 0)
	use_count_label.add_theme_font_size_override("font_size", 19)
	use_count_label.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	use_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	use_count_row.add_child(use_count_label)

	var use_count_value_label = Label.new()
	use_count_value_label.name = "UseCountValueLabel"
	use_count_value_label.text = "0 / 0"
	use_count_value_label.custom_minimum_size = Vector2(72, 0)
	use_count_value_label.add_theme_font_size_override("font_size", 19)
	use_count_value_label.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	use_count_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	use_count_row.add_child(use_count_value_label)

	var use_count_empty_container = Control.new()
	use_count_empty_container.name = "UseCountEmptyContainer"
	use_count_empty_container.custom_minimum_size = Vector2(118, 0)
	use_count_row.add_child(use_count_empty_container)

	var spirit_charge_row = HBoxContainer.new()
	spirit_charge_row.name = "SpiritChargeRow"
	spirit_charge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	spirit_charge_row.add_theme_constant_override("separation", 16)
	upgrade_conditions_box.add_child(spirit_charge_row)

	var spirit_charge_label = Label.new()
	spirit_charge_label.name = "SpiritChargeLabel"
	spirit_charge_label.text = "所需灵气："
	spirit_charge_label.custom_minimum_size = Vector2(120, 0)
	spirit_charge_label.add_theme_font_size_override("font_size", 19)
	spirit_charge_label.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	spirit_charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spirit_charge_row.add_child(spirit_charge_label)

	var spirit_amount_label = Label.new()
	spirit_amount_label.name = "SpiritAmountLabel"
	spirit_amount_label.text = "0 / 0"
	spirit_amount_label.custom_minimum_size = Vector2(72, 0)
	spirit_amount_label.add_theme_font_size_override("font_size", 19)
	spirit_amount_label.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	spirit_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spirit_charge_row.add_child(spirit_amount_label)

	var spirit_action_container = HBoxContainer.new()
	spirit_action_container.name = "SpiritActionContainer"
	spirit_action_container.custom_minimum_size = Vector2(118, 0)
	spirit_action_container.alignment = BoxContainer.ALIGNMENT_CENTER
	spirit_action_container.add_theme_constant_override("separation", 8)
	spirit_charge_row.add_child(spirit_action_container)

	charge_button = Button.new()
	charge_button.name = "ChargeButton"
	charge_button.text = "+"
	charge_button.custom_minimum_size = Vector2(48, 42)
	charge_button.add_theme_font_size_override("font_size", 24)
	charge_button.pressed.connect(func(): charge_requested.emit())
	spirit_action_container.add_child(charge_button)

	multiplier_button = Button.new()
	multiplier_button.name = "MultiplierButton"
	multiplier_button.text = "x10"
	multiplier_button.custom_minimum_size = Vector2(62, 42)
	multiplier_button.add_theme_font_size_override("font_size", 22)
	multiplier_button.pressed.connect(func(): multiplier_changed.emit())
	spirit_action_container.add_child(multiplier_button)
	
	# 轻量留白（避免使用 EXPAND_FILL 把弹窗高度异常撑大）
	vbox.add_child(_create_section_gap(8))
	vbox.add_child(_create_thick_separator())
	vbox.add_child(_create_section_gap(2))

	var star_title = Label.new()
	star_title.name = "StarUpgradeTitleLabel"
	star_title.text = "【升星条件】"
	star_title.add_theme_font_size_override("font_size", 23)
	star_title.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(star_title)

	var star_condition_label = Label.new()
	star_condition_label.name = "StarConditionLabel"
	star_condition_label.text = ""
	star_condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star_condition_label.add_theme_font_size_override("font_size", 19)
	star_condition_label.add_theme_color_override("font_color", Color(0.24, 0.22, 0.19, 1))
	vbox.add_child(star_condition_label)

	vbox.add_child(_create_section_gap(8))
	
	# 按钮容器
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	# 升级按钮
	upgrade_button = Button.new()
	upgrade_button.name = "UpgradeButton"
	upgrade_button.text = "升级"
	upgrade_button.custom_minimum_size = Vector2(124, 46)
	upgrade_button.add_theme_font_size_override("font_size", 22)
	upgrade_button.pressed.connect(func(): upgrade_requested.emit())
	button_container.add_child(upgrade_button)

	star_up_button = Button.new()
	star_up_button.name = "StarUpButton"
	star_up_button.text = "升星"
	star_up_button.custom_minimum_size = Vector2(124, 46)
	star_up_button.add_theme_font_size_override("font_size", 22)
	star_up_button.pressed.connect(func(): star_up_requested.emit())
	button_container.add_child(star_up_button)
	
	# 关闭按钮
	close_button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(124, 46)
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.pressed.connect(func(): close_requested.emit())
	button_container.add_child(close_button)

func _apply_popup_theme():
	add_theme_stylebox_override("panel", POPUP_STYLE_TEMPLATE.build_panel_style({
		"bg_color": POPUP_STYLE_TEMPLATE.POPUP_BG_COLOR,
		"border_color": POPUP_STYLE_TEMPLATE.POPUP_BORDER_COLOR,
		"corner_radius": 12,
		"border_width": 2
	}))
	_apply_action_button_styles()

func _apply_action_button_styles():
	if charge_button:
		ACTION_BUTTON_TEMPLATE.apply_spell_view_brown(charge_button, charge_button.custom_minimum_size, 24)
	if multiplier_button:
		ACTION_BUTTON_TEMPLATE.apply_spell_view_brown(multiplier_button, multiplier_button.custom_minimum_size, 22)
	if upgrade_button:
		ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(upgrade_button, upgrade_button.custom_minimum_size, 22)
	if star_up_button:
		ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(star_up_button, star_up_button.custom_minimum_size, 22)
	if close_button:
		ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(close_button, close_button.custom_minimum_size, 22)

func show_popup():
	"""显示弹窗"""
	if background:
		background.z_index = z_index - 1
		background.visible = true
	visible = true
	_update_popup_layout()
	# 首次显示时等一帧再二次布局，避免初次高度异常
	call_deferred("_update_popup_layout")

func _on_viewport_size_changed():
	if visible:
		_update_popup_layout()

func _update_popup_layout():
	if not vbox:
		return
	# 基于内容和屏幕动态计算弹窗尺寸，避免写死宽高导致比例异常
	var safe_rect := SAFE_AREA_HELPER.get_safe_inner_rect(self)
	var viewport_size = safe_rect.size
	var content_min_size = vbox.get_combined_minimum_size()
	var popup_width = clamp(content_min_size.x + 40.0, 360.0, max(360.0, viewport_size.x - 40.0))
	# 高度上限按屏幕 82%，并且不让无意义留白撑高
	var max_height = max(420.0, floor(viewport_size.y * 0.82))
	var popup_height = clamp(content_min_size.y + 34.0, 420.0, max_height)
	var popup_pos := safe_rect.position + (safe_rect.size - Vector2(popup_width, popup_height)) * 0.5
	position = popup_pos
	size = Vector2(popup_width, popup_height)

func hide_popup():
	"""隐藏弹窗"""
	if background:
		background.visible = false
	visible = false

func is_popup_visible() -> bool:
	"""检查弹窗是否可见"""
	return visible

func update_content(spell_info: Dictionary, spell_config: Dictionary, 
					spell_system: Node, spell_data: Node, 
					multiplier_index: int, multipliers: Array):
	"""更新弹窗内容"""
	if not vbox:
		return
	var normalized_level := _get_normalized_level(spell_info)
	var is_obtained := _is_spell_obtained(spell_info)
	
	# 更新标题
	var title_label = vbox.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = spell_config.get("name", "")
		title_label.modulate = _get_spell_quality_color(int(spell_info.get("quality", 0)))
	
	# 更新类型
	var type_label = vbox.get_node_or_null("TypeLabel")
	if type_label:
		var type_str = spell_config.get("type", "active")
		var type_name = spell_data.get_spell_type_name(type_str) if spell_data else type_str
		type_label.text = "类型：" + type_name

	var meta_label = vbox.get_node_or_null("MetaLabel")
	if meta_label:
		meta_label.text = "五行 / 稀有度：%s / %s阶" % [
			_get_element_name(str(spell_info.get("element", "none"))),
			_get_rarity_name(str(spell_info.get("rarity", "fan")))
		]
	
	# 更新等级
	var level_label = vbox.get_node_or_null("LevelLabel")
	if level_label:
		var max_level = int(spell_config.get("max_level", 3))
		if is_obtained:
			level_label.text = "等级：%s（%d / %d）" % [_format_level_tier_name(normalized_level), normalized_level, max_level]
		else:
			level_label.text = "等级：未解锁"

	var star_label = vbox.get_node_or_null("StarLabel")
	if star_label:
		var current_star = int(spell_info.get("star", 0))
		var max_star = int(spell_info.get("max_star", 5))
		star_label.text = "星级：" + ("☆" if current_star <= 0 else "★".repeat(min(current_star, 5))) + "（%d / %d）" % [current_star, max_star]
	
	# 获取展示等级数据
	# 已获得：展示当前等级
	# 未获得：按 1 级展示属性与术法效果（升级条件逻辑保持原样）
	var level_data = {}
	var display_level := normalized_level if is_obtained else 1
	level_data = spell_data.get_spell_level_data(str(spell_info.get("id", "")), display_level) if spell_data else {}
	
	# 更新属性加成
	_update_attribute_value(spell_info, level_data, spell_data)
	
	# 更新术法效果
	_update_effect_value(spell_info, spell_config, level_data)
	
	# 更新升级条件
	_update_upgrade_conditions(spell_info, spell_config, spell_data, multiplier_index, multipliers)
	_update_star_conditions(spell_info, spell_config, spell_data)

func _update_attribute_value(spell_info: Dictionary, level_data: Dictionary, spell_data: Node):
	"""更新属性加成显示"""
	var attr_value = vbox.get_node_or_null("AttributeValue")
	if not attr_value:
		return
	
	var attr_bonus = level_data.get("attribute_bonus", {}).duplicate(true)
	var spell_id := str(spell_info.get("spell_id", spell_info.get("id", "")))
	var current_star = int(spell_info.get("star", 0))
	if current_star >= 0 and spell_data:
		var star_key = min(current_star, 5)
		var star_data = spell_data.get_spell_star_data(spell_id, star_key)
		var star_bonus = star_data.get("attribute_bonus", {})
		for attr in star_bonus.keys():
			var value = float(star_bonus[attr])
			if attr in ["speed", "hit", "dodge", "crit", "anti_crit"]:
				attr_bonus[attr] = float(attr_bonus.get(attr, 0.0)) + value
			else:
				attr_bonus[attr] = float(attr_bonus.get(attr, 1.0)) + value
	var attr_text = ""
	var keys = attr_bonus.keys()
	for i in range(keys.size()):
		var attr = keys[i]
		var value = attr_bonus[attr]
		if attr == "speed":
			attr_text += "速度 +" + UIUtils.format_display_number(float(value))
		elif attr in ["hit", "dodge", "crit", "anti_crit"]:
			attr_text += _get_attribute_name(attr) + " +" + UIUtils.format_display_number(float(value)) + "%"
		else:
			attr_text += _get_attribute_name(attr) + " x " + _format_spell_multiplier(float(value))
		if i < keys.size() - 1:
			attr_text += "\n"
	attr_value.text = attr_text

func _update_effect_value(spell_info: Dictionary, spell_config: Dictionary, level_data: Dictionary):
	"""更新术法效果显示"""
	var effect_value = vbox.get_node_or_null("EffectValue")
	if not effect_value:
		return
	
	var current_effects = spell_info.get("current_effects", [])
	var fallback_effects = level_data.get("effect", [])
	var description := str(spell_config.get("description", ""))
	var display_effects: Variant = current_effects
	if not (display_effects is Array and not display_effects.is_empty()):
		display_effects = fallback_effects
	if display_effects is Array and _has_combat_effects(display_effects):
		effect_value.text = _build_combat_effect_sentence(display_effects)
		return
	if display_effects is Array and _has_opening_buff_effects(display_effects):
		effect_value.text = _build_opening_effect_sentence(display_effects)
		return
	if description.find("基础伤害") != -1 and display_effects is Array and not display_effects.is_empty():
		var legacy_parts: Array[String] = []
		for effect in display_effects:
			legacy_parts.append(_format_effect_entry(effect))
		effect_value.text = "\n".join(legacy_parts)
		return
	if not description.is_empty():
		effect_value.text = _format_effect_description(description, display_effects)
		return
	if display_effects is Array and not display_effects.is_empty():
		var parts: Array[String] = []
		for effect in display_effects:
			parts.append(_format_effect_entry(effect))
		effect_value.text = "\n".join(parts)
	else:
		effect_value.text = ""

func _update_upgrade_conditions(spell_info: Dictionary, spell_config: Dictionary, spell_data: Node, 
								multiplier_index: int, multipliers: Array):
	"""更新升级条件显示"""
	var max_level_label = vbox.get_node_or_null("MaxLevelLabel")
	var use_count_container = vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow")
	var use_count_value_label = vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow/UseCountValueLabel")
	var spirit_charge_container = vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow")
	var spirit_action_container = vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow/SpiritActionContainer")
	
	var current_level = _get_normalized_level(spell_info)
	var is_obtained := _is_spell_obtained(spell_info)
	var max_level = int(spell_config.get("max_level", 3))
	
	if not is_obtained:
		if max_level_label:
			max_level_label.visible = false
		if use_count_container:
			use_count_container.visible = true
		if use_count_value_label:
			use_count_value_label.text = "- / -"
		if spirit_charge_container:
			spirit_charge_container.visible = true
			var spirit_amount_label = vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow/SpiritAmountLabel")
			if spirit_amount_label:
				spirit_amount_label.text = "- / -"
		if spirit_action_container:
			spirit_action_container.visible = true
		_set_buttons_enabled(false, multiplier_index)
	elif current_level >= max_level:
		if max_level_label:
			max_level_label.visible = true
		if use_count_container:
			use_count_container.visible = false
		if spirit_charge_container:
			spirit_charge_container.visible = false
		if spirit_action_container:
			spirit_action_container.visible = false
		_set_buttons_enabled(false, multiplier_index)
	else:
		if max_level_label:
			max_level_label.visible = false
		if use_count_container:
			use_count_container.visible = true
		if spirit_charge_container:
			spirit_charge_container.visible = true
		if spirit_action_container:
			spirit_action_container.visible = true
		
		var current_level_data = _get_spell_level_data_for_popup(spell_info, spell_config, spell_data, current_level)
		var use_count_required = int(current_level_data.get("use_count_required", 0))
		var spirit_cost = int(current_level_data.get("spirit_cost", 0))
		var charged_spirit = int(spell_info.get("charged_spirit", 0))
		
		if use_count_value_label:
			use_count_value_label.text = UIUtils.format_display_number(float(spell_info.get("use_count", 0))) + " / " + UIUtils.format_display_number(float(use_count_required))
		if spirit_charge_container:
			var spirit_amount_label = vbox.get_node_or_null("UpgradeConditionsBox/SpiritChargeRow/SpiritAmountLabel")
			if spirit_amount_label:
				spirit_amount_label.text = UIUtils.format_display_number(float(charged_spirit)) + " / " + UIUtils.format_display_number(float(spirit_cost))
		
		_set_buttons_enabled(true, multiplier_index)

func _set_buttons_enabled(enabled: bool, multiplier_index: int):
	"""设置按钮状态"""
	if charge_button:
		charge_button.disabled = not enabled
	if multiplier_button:
		multiplier_button.disabled = not enabled
		multiplier_button.text = MULTIPLIER_LABELS[multiplier_index] if multiplier_index < MULTIPLIER_LABELS.size() else "x10"
	if upgrade_button:
		upgrade_button.disabled = not enabled
	if star_up_button:
		star_up_button.disabled = true

func update_use_count_only(spell_info: Dictionary, spell_config: Dictionary, spell_data: Node):
	"""只更新使用次数（用于实时更新）"""
	var max_level_label = vbox.get_node_or_null("MaxLevelLabel")
	var use_count_container = vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow")
	var use_count_value_label = vbox.get_node_or_null("UpgradeConditionsBox/UseCountRow/UseCountValueLabel")
	if not use_count_container or not use_count_value_label:
		return
	
	var current_level = _get_normalized_level(spell_info)
	var is_obtained := _is_spell_obtained(spell_info)
	var max_level = int(spell_config.get("max_level", 3))
	
	if not is_obtained:
		if max_level_label:
			max_level_label.visible = false
		use_count_container.visible = true
		use_count_value_label.text = "- / -"
	elif current_level >= max_level:
		if max_level_label:
			max_level_label.visible = true
		use_count_container.visible = false
	else:
		if max_level_label:
			max_level_label.visible = false
		use_count_container.visible = true
		var current_level_data = _get_spell_level_data_for_popup(spell_info, spell_config, spell_data, current_level)
		var use_count_required = int(current_level_data.get("use_count_required", 0))
		use_count_value_label.text = UIUtils.format_display_number(float(spell_info.get("use_count", 0))) + " / " + UIUtils.format_display_number(float(use_count_required))
	
	use_count_value_label.queue_redraw()
	
	if current_level > 0 and current_level < max_level:
		_set_buttons_enabled(true, 0)

func _update_star_conditions(spell_info: Dictionary, spell_config: Dictionary, spell_data: Node):
	var star_condition_label = vbox.get_node_or_null("StarConditionLabel")
	if not star_condition_label:
		return
	if not _is_spell_obtained(spell_info):
		star_condition_label.text = "同名术法解锁道具 - / -"
		if star_up_button:
			star_up_button.disabled = true
		return
	var current_star = int(spell_info.get("star", 0))
	var max_star = int(spell_info.get("max_star", 5))
	if current_star >= max_star:
		star_condition_label.text = "已达到最高星级"
		if star_up_button:
			star_up_button.disabled = true
		return
	var spell_id := str(spell_config.get("id", spell_info.get("id", "")))
	var star_data = spell_data.get_spell_star_data(spell_id, current_star) if spell_data else {}
	var requirements = star_data.get("requirements", {})
	var unlock_count = int(requirements.get("unlock_item_count", 0))
	var star_material_count = int(requirements.get("star_material_count", 0))
	var inventory_counts = _get_inventory_counts()
	var unlock_item_id = str(spell_config.get("unlock_item_id", ""))
	var current_unlock_count = int(inventory_counts.get(unlock_item_id, 0))
	var lines = [
		"同名术法解锁道具 %d / %d" % [current_unlock_count, unlock_count]
	]
	if star_material_count > 0:
		var current_blank = int(inventory_counts.get("blank_jade_slip", 0))
		lines.append("空白玉简 %d / %d" % [current_blank, star_material_count])
	star_condition_label.text = "\n".join(lines)
	if star_up_button:
		star_up_button.disabled = not _is_spell_obtained(spell_info)

func _is_spell_obtained(spell_info: Dictionary) -> bool:
	return bool(spell_info.get("obtained", false)) or int(spell_info.get("level", 0)) > 0

func _get_normalized_level(spell_info: Dictionary) -> int:
	var current_level := int(spell_info.get("level", 0))
	if current_level <= 0 and _is_spell_obtained(spell_info):
		return 1
	return current_level

func _get_spell_level_data_for_popup(spell_info: Dictionary, spell_config: Dictionary, spell_data: Node, level: int) -> Dictionary:
	if not spell_data or level <= 0:
		return {}
	var spell_id := str(spell_config.get("id", spell_info.get("id", "")))
	if spell_id.is_empty():
		return {}
	return spell_data.get_spell_level_data(spell_id, level)

func cleanup():
	"""清理资源"""
	if background:
		background.queue_free()
		background = null
	queue_free()

# ==================== 辅助函数 ====================

func _get_attribute_name(attr: String) -> String:
	match attr:
		"attack": return "攻击力"
		"defense": return "防御力"
		"health": return "气血值"
		"spirit_gain": return "灵气获取"
		"speed": return "速度"
		"max_spirit": return "最大灵气"
		"crit_damage": return "爆伤"
		"penetration": return "穿透"
		"hit": return "命中"
		"dodge": return "闪避"
		"crit": return "暴击"
		"anti_crit": return "抗暴"
		_: return attr

func _format_spell_number(value: float) -> String:
	return UIUtils.format_display_number(value)

func _format_spell_percent(value: float) -> String:
	var percent = value * 100
	if percent == int(percent):
		return str(int(percent)) + "%"
	var result = "%.2f" % percent
	result = result.replace(".00", "")
	if result.ends_with("0") and result.find(".") != -1:
		result = result.substr(0, result.length() - 1)
	return result + "%"

func _format_effect_description(description: String, effect: Variant) -> String:
	var result = description
	var effects: Array = []
	if effect is Array:
		effects = effect
	elif effect is Dictionary:
		effects = [effect]

	var merged_effect_dict: Dictionary = {}
	for effect_entry in effects:
		if effect_entry is Dictionary:
			for key in effect_entry.keys():
				merged_effect_dict[key] = effect_entry[key]

	if result.find("{damage_text}") != -1:
		result = result.replace("{damage_text}", _build_damage_text(effects))
	if result.find("{drain_text}") != -1:
		result = result.replace("{drain_text}", _build_drain_text(effects))
	if result.find("{turn_gauge_text}") != -1:
		result = result.replace("{turn_gauge_text}", _build_turn_gauge_text(effects))

	for key in merged_effect_dict.keys():
		var value = merged_effect_dict[key]
		var placeholder = "{" + key + "}"
		if result.find(placeholder) != -1:
			var formatted_value = str(value)
			if key.find("percent") != -1 or key.find("chance") != -1:
				var percent_value = value * 100.0
				if is_equal_approx(percent_value, round(percent_value)):
					formatted_value = str(int(round(percent_value))) + "%"
				else:
					formatted_value = "%.1f" % percent_value + "%"
			elif key == "speed_rate":
				var percent_value = value * 100.0
				if is_equal_approx(percent_value, round(percent_value)):
					formatted_value = str(int(round(percent_value)))
				else:
					formatted_value = "%.1f" % percent_value
			elif key.find("value") != -1:
				formatted_value = _format_spell_number(value)
			elif key == "efficiency":
				formatted_value = _format_spell_number(value)
			elif key == "heal_percent":
				var percent_value = value * 100.0
				if percent_value == int(percent_value):
					formatted_value = str(int(percent_value)) + "%"
				else:
					formatted_value = "%.2f" % percent_value + "%"
			result = result.replace(placeholder, formatted_value)
	
	return result

func _format_level_tier_name(level: int) -> String:
	var names = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
	if level >= 1 and level < names.size():
		return names[level] + "重"
	if level == 10:
		return "十重"
	return str(level)

func _format_effect_entry(effect: Dictionary) -> String:
	var effect_type = str(effect.get("effect_type", ""))
	match effect_type:
		"instant_damage":
			var min_text = _format_spell_number(float(effect.get("damage_percent_min", 0.0)))
			var max_text = _format_spell_number(float(effect.get("damage_percent_max", effect.get("damage_percent_min", 0.0))))
			if min_text == max_text:
				return "战斗中有概率造成%s倍伤害" % min_text
			return "战斗中有概率造成%s-%s倍伤害" % [min_text, max_text]
		"drain_health":
			return "恢复造成伤害的%s气血" % _format_spell_percent(float(effect.get("drain_percent", 0.0)))
		"turn_gauge_delta":
			var delta_value = 0.0
			if effect.has("turn_gauge_delta"):
				delta_value = abs(float(effect.get("turn_gauge_delta", 0.0)))
			else:
				delta_value = abs(float(effect.get("delta", 0.0)))
			return "敌方行动条减少%s" % _format_spell_percent(delta_value)
		"passive_heal":
			return "修炼时每秒恢复%s最大气血" % _format_spell_percent(float(effect.get("heal_percent", 0.0)))
		"spirit_leak_bonus":
			return "逸散灵气几率增加%s" % _format_spell_percent(float(effect.get("leak_bonus", 0.0)))
		"reduce_pill_toxicity":
			return "丹毒减少%s" % _format_spell_percent(float(effect.get("toxic_reduce", 0.0)))
		"undispellable_buff":
			return "开局获得常驻加成"
		_:
			return str(effect)

func _has_combat_effects(effects: Array) -> bool:
	for effect in effects:
		if effect is Dictionary:
			var effect_type = str(effect.get("effect_type", ""))
			if effect_type in ["instant_damage", "drain_health", "turn_gauge_delta"]:
				return true
	return false

func _has_opening_buff_effects(effects: Array) -> bool:
	for effect in effects:
		if effect is Dictionary and str(effect.get("effect_type", "")) == "undispellable_buff":
			return true
	return false

func _build_combat_effect_sentence(effects: Array) -> String:
	var parts: Array[String] = []
	var damage_text := _build_damage_text(effects)
	if not damage_text.is_empty():
		parts.append("战斗中有概率造成%s伤害" % damage_text)
	var drain_text := _build_drain_text(effects)
	if not drain_text.is_empty():
		parts.append("恢复造成伤害的%s气血" % drain_text)
	var turn_gauge_text := _build_turn_gauge_text(effects)
	if not turn_gauge_text.is_empty():
		parts.append("使敌方行动条减少%s" % turn_gauge_text)
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	return "%s，并%s" % [parts[0], "，并".join(parts.slice(1))]

func _build_opening_effect_sentence(effects: Array) -> String:
	var parts: Array[String] = []
	for effect in effects:
		if effect is Dictionary and str(effect.get("effect_type", "")) == "undispellable_buff":
			var buff_text := _build_opening_buff_text(effect)
			if not buff_text.is_empty():
				parts.append(buff_text)
	if parts.is_empty():
		return ""
	return "开局" + "，".join(parts)

func _build_opening_buff_text(effect: Dictionary) -> String:
	var buff_type := str(effect.get("buff_type", ""))
	var buff_percent := float(effect.get("buff_percent", 0.0))
	var buff_value := float(effect.get("buff_value", 0.0))
	match buff_type:
		"attack":
			return "攻击增加%s" % _format_spell_percent(buff_percent)
		"defense":
			return "防御增加%s" % _format_spell_percent(buff_percent)
		"health":
			return "气血增加%s" % _format_spell_percent(buff_percent)
		"penetration":
			return "穿透增加%s" % _format_spell_percent(buff_percent)
		"crit_damage":
			return "爆伤增加%s" % _format_spell_percent(buff_percent)
		"speed":
			return "速度增加%s" % _format_spell_number(buff_value)
		"hit":
			return "命中增加%s" % _format_spell_percent(buff_percent)
		"dodge":
			return "闪避增加%s" % _format_spell_percent(buff_percent)
		"crit":
			return "暴击增加%s" % _format_spell_percent(buff_percent)
		"anti_crit":
			return "抗暴增加%s" % _format_spell_percent(buff_percent)
		_:
			return ""

func _build_damage_text(effects: Array) -> String:
	for effect in effects:
		if effect is Dictionary and str(effect.get("effect_type", "")) == "instant_damage":
			var min_text = _format_spell_number(float(effect.get("damage_percent_min", 0.0)))
			var max_text = _format_spell_number(float(effect.get("damage_percent_max", effect.get("damage_percent_min", 0.0))))
			if min_text == max_text:
				return "%s倍" % min_text
			return "%s-%s倍" % [min_text, max_text]
	return ""

func _build_drain_text(effects: Array) -> String:
	for effect in effects:
		if effect is Dictionary and str(effect.get("effect_type", "")) == "drain_health":
			return _format_spell_percent(float(effect.get("drain_percent", 0.0)))
	return ""

func _build_turn_gauge_text(effects: Array) -> String:
	for effect in effects:
		if effect is Dictionary and str(effect.get("effect_type", "")) == "turn_gauge_delta":
			var delta_value = 0.0
			if effect.has("turn_gauge_delta"):
				delta_value = abs(float(effect.get("turn_gauge_delta", 0.0)))
			else:
				delta_value = abs(float(effect.get("delta", 0.0)))
			return _format_spell_percent(delta_value)
	return ""

func _get_rarity_name(rarity: String) -> String:
	match rarity:
		"huang":
			return "黄"
		"xuan":
			return "玄"
		"di":
			return "地"
		"tian":
			return "天"
		_:
			return "凡"

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

func _get_spell_quality_color(quality: int) -> Color:
	var game_manager = get_node_or_null("/root/GameManager")
	var item_data = game_manager.get_item_data() if game_manager and game_manager.has_method("get_item_data") else null
	if item_data and item_data.has_method("get_item_quality_color"):
		return item_data.get_item_quality_color(quality)
	return Color(0.2, 0.2, 0.2, 1.0)

func _format_spell_multiplier(value: float) -> String:
	var rounded = snappedf(value, 0.001)
	if is_equal_approx(rounded, round(rounded)):
		return str(int(round(rounded)))
	var text = "%.3f" % rounded
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text

func _get_inventory_counts() -> Dictionary:
	var counts := {}
	var game_manager = get_node_or_null("/root/GameManager")
	var inventory = game_manager.get_inventory() if game_manager and game_manager.has_method("get_inventory") else null
	if not inventory:
		return counts
	var slots = []
	if inventory.has_method("get_item_list"):
		slots = inventory.get_item_list()
	elif "slots" in inventory:
		slots = inventory.slots
	else:
		return counts
	for slot in slots:
		if typeof(slot) != TYPE_DICTIONARY:
			continue
		if bool(slot.get("empty", false)):
			continue
		var item_id = str(slot.get("id", ""))
		if item_id.is_empty():
			continue
		counts[item_id] = int(counts.get(item_id, 0)) + int(slot.get("count", 0))
	return counts

func _create_thick_separator() -> HSeparator:
	"""创建粗分割线，使其在不同分辨率下都能清晰显示"""
	var separator = HSeparator.new()
	var separator_style = StyleBoxLine.new()
	separator_style.color = Color(0.66, 0.6, 0.5, 0.55)
	separator_style.thickness = 2
	separator.add_theme_stylebox_override("separator", separator_style)
	separator.custom_minimum_size = Vector2(0, 6)
	return separator

func _create_section_gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, float(max(0, height)))
	return spacer
