extends Control

const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const SPELL_THUMBNAIL_TEMPLATE = preload("res://scripts/ui/common/SpellThumbnailTemplate.gd")
const UI_FONT_PROVIDER = preload("res://scripts/ui/common/UIFontProvider.gd")
const UI_ICON_PROVIDER = preload("res://scripts/ui/common/UIIconProvider.gd")
const UI_FEEDBACK_MANAGER = preload("res://scripts/ui/common/UIFeedbackManager.gd")

const COLOR_BG := Color(0.95, 0.90, 0.80, 1.0)
const COLOR_PANEL := Color(0.99, 0.95, 0.86, 0.96)
const COLOR_TEXT := Color(0.20, 0.17, 0.13, 1.0)
const COLOR_MUTED := Color(0.47, 0.40, 0.31, 1.0)
const COLOR_BORDER := Color(0.71, 0.64, 0.51, 0.95)
const COLOR_EQUIPPED := Color(0.84, 0.63, 0.18, 1.0)

const RARITY_COLORS := {
	"fan": Color(0.07, 0.07, 0.07, 1.0),
	"huang": Color(0.12, 0.42, 0.15, 1.0),
	"xuan": Color(0.00, 0.58, 0.82, 1.0),
	"di": Color(0.72, 0.30, 0.78, 1.0),
	"tian": Color(0.95, 0.56, 0.04, 1.0)
}

var _demo_cards: Array[Control] = []

func _ready() -> void:
	UI_FONT_PROVIDER.apply_to_root(self)
	_build_scene()

func _build_scene() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	scroll.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_current_section())
	root.add_child(_build_variant_section())
	root.add_child(_build_notes())

func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, COLOR_BORDER, 18, 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "术法缩略卡样式 Demo"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "独立预览场景，只比较缩略卡；不改正式术法页，也不涉及弹窗模板。重点看：已装备徽章、稀有度色条/边框、生产术法宽按钮、星级位置。"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	vbox.add_child(desc)
	return panel

func _build_current_section() -> Control:
	var panel := _section_panel("当前风格近似", "保留现在的主要信息密度，用于和下面候选样式对照。")
	var grid := _section_grid(panel)
	grid.add_child(_build_current_card({
		"name": "碎石拳",
		"rarity": "huang",
		"element": "metal",
		"star": 4,
		"level": 1,
		"equipped": true,
		"obtained": true,
		"production": false
	}))
	grid.add_child(_build_current_card({
		"name": "缠诀",
		"rarity": "huang",
		"element": "wood",
		"star": 0,
		"level": 0,
		"equipped": false,
		"obtained": false,
		"production": false
	}))
	grid.add_child(_build_current_card({
		"name": "草药采集术",
		"rarity": "fan",
		"element": "wood",
		"star": 0,
		"level": 1,
		"equipped": false,
		"obtained": true,
		"production": true
	}))
	return panel

func _build_variant_section() -> Control:
	var panel := _section_panel("候选优化版", "推荐方案：更清楚地表达装备态和稀有度，但动效保持克制。")
	var grid := _section_grid(panel)
	grid.add_child(_build_variant_card({
		"name": "碎石拳",
		"rarity": "huang",
		"element": "metal",
		"star": 4,
		"level": 1,
		"equipped": true,
		"obtained": true,
		"production": false
	}))
	grid.add_child(_build_variant_card({
		"name": "裂金指",
		"rarity": "xuan",
		"element": "metal",
		"star": 0,
		"level": 0,
		"equipped": false,
		"obtained": false,
		"production": false
	}))
	grid.add_child(_build_variant_card({
		"name": "鸿蒙天剑经",
		"rarity": "tian",
		"element": "metal",
		"star": 4,
		"level": 1,
		"equipped": false,
		"obtained": true,
		"production": false
	}))
	grid.add_child(_build_variant_card({
		"name": "草药采集术",
		"rarity": "fan",
		"element": "wood",
		"star": 0,
		"level": 1,
		"equipped": false,
		"obtained": true,
		"production": true
	}))
	grid.add_child(_build_variant_card({
		"name": "覆雨掌",
		"rarity": "di",
		"element": "water",
		"star": 2,
		"level": 2,
		"equipped": true,
		"obtained": true,
		"production": false
	}))
	grid.add_child(_build_variant_card({
		"name": "基础拳法",
		"rarity": "fan",
		"element": "none",
		"star": 0,
		"level": 1,
		"equipped": false,
		"obtained": true,
		"production": false
	}))
	return panel

func _build_notes() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.93, 0.82, 0.92), Color(0.78, 0.68, 0.50, 0.85), 16, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	label.text = "交互建议：点击候选卡会轻闪，用来模拟打开详情的确认反馈；正式落地时可以只保留装备/卸下成功轻闪，不做卡片入场动画，避免术法页重建时显得乱。"
	margin.add_child(label)
	return panel

func _section_panel(title_text: String, desc_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, COLOR_BORDER, 18, 2))

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	body.add_child(title)

	var desc := Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	body.add_child(desc)
	return panel

func _section_grid(panel: PanelContainer) -> GridContainer:
	var body := panel.get_node("Margin/Body") as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	return grid

func _build_current_card(data: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(145, 202)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	SPELL_THUMBNAIL_TEMPLATE.apply_to_card(card, {
		"bg_color": SPELL_THUMBNAIL_TEMPLATE.DEFAULT_BG_COLOR
	})

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	vbox.add_child(_fixed_spacer(5))
	vbox.add_child(_label(_star_text(int(data.get("star", 0))), 16, Color(0.89, 0.72, 0.21, 1.0), 24))
	vbox.add_child(_label(str(data.get("name", "")), 17, _rarity_color(str(data.get("rarity", "fan"))), 0, true))
	vbox.add_child(_element_row(str(data.get("element", "none")), 21))
	vbox.add_child(_label(_status_text(data), 16, _status_color(data), 0))
	vbox.add_child(_button_row(data, false))
	vbox.add_child(_fixed_spacer(7))
	return card

func _build_variant_card(data: Dictionary) -> Control:
	var rarity := str(data.get("rarity", "fan"))
	var rarity_color := _rarity_color(rarity)
	var equipped := bool(data.get("equipped", false))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(154, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var border_color := COLOR_EQUIPPED if equipped else rarity_color.lightened(0.22)
	SPELL_THUMBNAIL_TEMPLATE.apply_to_card(card, {
		"bg_color": Color(0.96, 0.90, 0.78, 1.0),
		"border_color": border_color,
		"corner_radius": 10,
		"border_width": 2 if not equipped else 3
	})
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				UI_FEEDBACK_MANAGER.play_soft_flash(card, {
					"flash_color": Color(1.0, 0.92, 0.62, 1.0),
					"duration": 0.22
				})
	)
	_demo_cards.append(card)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 7)
	card.add_child(root)

	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 35)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top)

	var rarity_strip := ColorRect.new()
	rarity_strip.name = "RarityStrip"
	rarity_strip.color = rarity_color
	rarity_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rarity_strip.offset_left = 10
	rarity_strip.offset_top = 8
	rarity_strip.offset_right = -10
	rarity_strip.offset_bottom = 12
	top.add_child(rarity_strip)

	if equipped:
		top.add_child(_badge("已装备", Color(0.90, 0.68, 0.19, 1.0), Vector2(12, 15), HORIZONTAL_ALIGNMENT_LEFT))

	var star := int(data.get("star", 0))
	if star > 0:
		top.add_child(_badge("★%d" % star, Color(0.96, 0.76, 0.20, 1.0), Vector2(-62, 15), HORIZONTAL_ALIGNMENT_RIGHT))

	var name := _label(str(data.get("name", "")), 18, rarity_color, 0, true)
	name.custom_minimum_size = Vector2(0, 42)
	root.add_child(name)

	var meta_panel := PanelContainer.new()
	meta_panel.add_theme_stylebox_override("panel", _style(Color(1.0, 0.96, 0.86, 0.74), Color(0.81, 0.73, 0.58, 0.38), 12, 1))
	meta_panel.custom_minimum_size = Vector2(0, 34)
	meta_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(meta_panel)

	var meta_margin := MarginContainer.new()
	meta_margin.add_theme_constant_override("margin_left", 8)
	meta_margin.add_theme_constant_override("margin_right", 8)
	meta_panel.add_child(meta_margin)
	meta_margin.add_child(_element_row(str(data.get("element", "none")), 24))

	var status := _label(_status_text(data), 16, _status_color(data), 0)
	status.custom_minimum_size = Vector2(0, 26)
	root.add_child(status)

	root.add_child(_button_row(data, true))
	root.add_child(_fixed_spacer(5))
	return card

func _button_row(data: Dictionary, variant: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var production := bool(data.get("production", false))
	var view := Button.new()
	view.text = "查看"
	view.custom_minimum_size = Vector2(52 if not production else 118, 31)
	ACTION_BUTTON_TEMPLATE.apply_spell_view_brown(view, view.custom_minimum_size, 14)
	row.add_child(view)

	if not production:
		var equip := Button.new()
		equip.custom_minimum_size = Vector2(52, 31)
		if bool(data.get("obtained", false)):
			equip.text = "卸下" if bool(data.get("equipped", false)) else "装备"
			if bool(data.get("equipped", false)):
				ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(equip, equip.custom_minimum_size, 14)
			else:
				ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(equip, equip.custom_minimum_size, 14)
		else:
			equip.text = "装备"
			equip.disabled = true
			ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(equip, equip.custom_minimum_size, 14)
		row.add_child(equip)
	elif variant:
		view.text = "查看详情"

	return row

func _element_row(element: String, icon_size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = UI_ICON_PROVIDER.get_spell_element_texture(element)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text := Label.new()
	text.text = _element_name(element)
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", Color(0.36, 0.33, 0.29, 1.0))
	row.add_child(text)
	return row

func _badge(text: String, color: Color, offset: Vector2, alignment: HorizontalAlignment) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(50, 24)
	badge.add_theme_stylebox_override("panel", _style(color, color.darkened(0.18), 11, 1))
	badge.layout_mode = 1
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_top = offset.y
	badge.offset_bottom = offset.y + 24
	if alignment == HORIZONTAL_ALIGNMENT_LEFT:
		badge.anchor_left = 0.0
		badge.anchor_right = 0.0
		badge.offset_left = offset.x
		badge.offset_right = offset.x + 58
	else:
		badge.anchor_left = 1.0
		badge.anchor_right = 1.0
		badge.offset_left = offset.x
		badge.offset_right = -10

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
	badge.add_child(label)
	return badge

func _label(text: String, font_size: int, color: Color, min_height: int = 0, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if min_height > 0:
		label.custom_minimum_size = Vector2(0, min_height)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _fixed_spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	return style

func _star_text(star: int) -> String:
	return "" if star <= 0 else "★".repeat(mini(star, 5))

func _status_text(data: Dictionary) -> String:
	if not bool(data.get("obtained", false)) or int(data.get("level", 0)) <= 0:
		return "未获取"
	return "Lv.%d" % int(data.get("level", 1))

func _status_color(data: Dictionary) -> Color:
	if not bool(data.get("obtained", false)) or int(data.get("level", 0)) <= 0:
		return Color(0.62, 0.60, 0.56, 1.0)
	if bool(data.get("equipped", false)):
		return Color(0.12, 0.52, 0.20, 1.0)
	return Color(0.20, 0.20, 0.20, 1.0)

func _rarity_color(rarity: String) -> Color:
	return Color(RARITY_COLORS.get(rarity, RARITY_COLORS["fan"]))

func _element_name(element: String) -> String:
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
