class_name AreaEntryCard
extends PanelContainer

const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const UI_FONT_PROVIDER = preload("res://scripts/ui/common/UIFontProvider.gd")

signal action_pressed(entry_id: String)

const CARD_BG := Color(0.9686, 0.9373, 0.8627, 0.96)
const CARD_BORDER := Color(0.7608, 0.6471, 0.4549, 0.30)
const CARD_SHADOW := Color(0.4588, 0.3176, 0.1373, 0.10)
const INK := Color(0.1961, 0.1529, 0.1216, 1.0)
const MUTED := Color(0.4902, 0.4196, 0.3412, 1.0)
const TRAY_BG := Color(0.989, 0.965, 0.914, 0.95)
const TRAY_BORDER := Color(0.745, 0.651, 0.502, 0.22)
const TAG_BG := Color(0.985, 0.958, 0.908, 1.0)
const TAG_BORDER := Color(0.739, 0.648, 0.502, 0.28)
const TAG_TEXT := Color(0.353, 0.286, 0.227, 1.0)
const LOCK_TEXT := Color(0.604, 0.345, 0.278, 1.0)

const IMAGE_VARIANT_COLORS := {
	"alchemy": [Color(0.49, 0.35, 0.22, 1.0), Color(0.29, 0.20, 0.12, 1.0)],
	"herb": [Color(0.43, 0.58, 0.40, 1.0), Color(0.23, 0.33, 0.24, 1.0)],
	"task": [Color(0.48, 0.45, 0.58, 1.0), Color(0.25, 0.23, 0.33, 1.0)],
	"forest": [Color(0.35, 0.44, 0.31, 1.0), Color(0.21, 0.27, 0.18, 1.0)],
	"plain": [Color(0.58, 0.53, 0.37, 1.0), Color(0.34, 0.29, 0.18, 1.0)],
	"tower": [Color(0.33, 0.40, 0.52, 1.0), Color(0.18, 0.22, 0.31, 1.0)],
	"daily": [Color(0.47, 0.33, 0.29, 1.0), Color(0.27, 0.17, 0.15, 1.0)],
	"default": [Color(0.50, 0.43, 0.34, 1.0), Color(0.31, 0.24, 0.18, 1.0)]
}

var entry_id: String = ""
var action_button: Button = null
var _title_text_value: String = ""

var _image_panel: PanelContainer = null
var _image_chip_label: Label = null
var _image_glyph_label: Label = null
var _image_glass: PanelContainer = null
var _title_suffix_label: Label = null
var _description_label: Label = null
var _tag_tray: PanelContainer = null
var _tag_flow: FlowContainer = null
var _lock_reason_label: Label = null


func _init():
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 252)
	theme = UI_FONT_PROVIDER.get_theme()
	_build_ui()


func configure(config: Dictionary) -> void:
	entry_id = str(config.get("entry_id", ""))

	var title_text := str(config.get("title", ""))
	_title_text_value = title_text
	var title_suffix := str(config.get("title_suffix", ""))
	_title_suffix_label.text = title_suffix
	_title_suffix_label.visible = not title_suffix.is_empty()

	_description_label.text = str(config.get("description", ""))

	var image_label_text := str(config.get("image_label", title_text))
	_image_chip_label.text = image_label_text
	var image_glyph := str(config.get("image_glyph", title_text.left(1)))
	_image_glyph_label.text = image_glyph
	_apply_image_variant(str(config.get("image_variant", "default")))

	var tags = config.get("tags", [])
	_rebuild_tags(tags if tags is Array else [])

	action_button.text = str(config.get("button_text", "进入"))
	action_button.disabled = bool(config.get("disabled", false))

	var disabled_reason := str(config.get("disabled_reason", ""))
	_lock_reason_label.text = disabled_reason
	_lock_reason_label.visible = action_button.disabled and not disabled_reason.is_empty()


func get_action_target() -> Button:
	return action_button


func get_title_text() -> String:
	return _title_text_value


func get_title_suffix_text() -> String:
	return _title_suffix_label.text if _title_suffix_label and _title_suffix_label.visible else ""


func get_button_text() -> String:
	return action_button.text if action_button else ""


func is_action_disabled() -> bool:
	return action_button.disabled if action_button else false


func get_lock_reason_text() -> String:
	return _lock_reason_label.text if _lock_reason_label and _lock_reason_label.visible else ""


func get_description_text() -> String:
	return _description_label.text if _description_label else ""


func get_tag_texts() -> Array:
	var tags: Array = []
	if not _tag_flow:
		return tags
	for child in _tag_flow.get_children():
		var label := _find_first_label(child)
		if label:
			tags.append(label.text)
	return tags


func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node
	for child in node.get_children():
		var found := _find_first_label(child)
		if found:
			return found
	return null


func _build_ui() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = CARD_BG
	card_style.border_color = CARD_BORDER
	card_style.shadow_color = CARD_SHADOW
	card_style.shadow_size = 14
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(26)
	add_theme_stylebox_override("panel", card_style)

	var outer_margin := MarginContainer.new()
	outer_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outer_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_vbox.add_theme_constant_override("separation", 0)
	outer_margin.add_child(root_vbox)

	_image_panel = PanelContainer.new()
	_image_panel.custom_minimum_size = Vector2(0, 124)
	_image_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_vbox.add_child(_image_panel)

	var image_style := StyleBoxFlat.new()
	image_style.corner_radius_top_left = 26
	image_style.corner_radius_top_right = 26
	image_style.corner_radius_bottom_left = 0
	image_style.corner_radius_bottom_right = 0
	image_style.set_border_width_all(0)
	_image_panel.add_theme_stylebox_override("panel", image_style)

	var image_overlay_root := Control.new()
	image_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_overlay_root.anchor_right = 1.0
	image_overlay_root.anchor_bottom = 1.0
	_image_panel.add_child(image_overlay_root)

	var image_outline := PanelContainer.new()
	image_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_outline.anchor_right = 1.0
	image_outline.anchor_bottom = 1.0
	image_outline.offset_left = 12.0
	image_outline.offset_top = 10.0
	image_outline.offset_right = -12.0
	image_outline.offset_bottom = -10.0
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(1, 1, 1, 0.0)
	outline_style.border_color = Color(1.0, 0.96, 0.88, 0.20)
	outline_style.set_border_width_all(1)
	outline_style.set_corner_radius_all(20)
	image_outline.add_theme_stylebox_override("panel", outline_style)
	image_overlay_root.add_child(image_outline)

	_image_glass = PanelContainer.new()
	_image_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_glass.anchor_left = 0.0
	_image_glass.anchor_top = 1.0
	_image_glass.anchor_right = 1.0
	_image_glass.anchor_bottom = 1.0
	_image_glass.offset_left = 28.0
	_image_glass.offset_top = -86.0
	_image_glass.offset_right = -28.0
	_image_glass.offset_bottom = -16.0
	var glass_style := StyleBoxFlat.new()
	glass_style.bg_color = Color(1.0, 0.96, 0.90, 0.11)
	glass_style.border_color = Color(1.0, 0.97, 0.92, 0.05)
	glass_style.set_border_width_all(1)
	glass_style.set_corner_radius_all(18)
	_image_glass.add_theme_stylebox_override("panel", glass_style)
	image_overlay_root.add_child(_image_glass)

	var image_chip := PanelContainer.new()
	image_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_chip.anchor_left = 0.0
	image_chip.anchor_top = 0.0
	image_chip.anchor_right = 0.0
	image_chip.anchor_bottom = 0.0
	image_chip.offset_left = 28.0
	image_chip.offset_top = 22.0
	image_chip.offset_right = 132.0
	image_chip.offset_bottom = 64.0
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.33, 0.24, 0.16, 0.34)
	chip_style.border_color = Color(1.0, 0.92, 0.82, 0.18)
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(21)
	image_chip.add_theme_stylebox_override("panel", chip_style)
	image_overlay_root.add_child(image_chip)

	var chip_center := CenterContainer.new()
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_chip.add_child(chip_center)

	_image_chip_label = Label.new()
	_image_chip_label.add_theme_font_size_override("font_size", 15)
	_image_chip_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.91, 0.92))
	chip_center.add_child(_image_chip_label)

	_image_glyph_label = Label.new()
	_image_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_glyph_label.anchor_left = 1.0
	_image_glyph_label.anchor_top = 0.0
	_image_glyph_label.anchor_right = 1.0
	_image_glyph_label.anchor_bottom = 0.0
	_image_glyph_label.offset_left = -94.0
	_image_glyph_label.offset_top = 16.0
	_image_glyph_label.offset_right = -20.0
	_image_glyph_label.offset_bottom = 84.0
	_image_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_image_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_image_glyph_label.add_theme_font_size_override("font_size", 54)
	_image_glyph_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94, 0.88))
	image_overlay_root.add_child(_image_glyph_label)

	var content_margin := MarginContainer.new()
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 18)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	root_vbox.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(content_vbox)

	_title_suffix_label = Label.new()
	_title_suffix_label.add_theme_font_size_override("font_size", 20)
	_title_suffix_label.add_theme_color_override("font_color", Color(0.5961, 0.4510, 0.1804, 1.0))
	_title_suffix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content_vbox.add_child(_title_suffix_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 18)
	_description_label.add_theme_color_override("font_color", MUTED)
	_description_label.custom_minimum_size = Vector2(0, 0)
	content_vbox.add_child(_description_label)

	_tag_tray = PanelContainer.new()
	_tag_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(_tag_tray)

	var tray_style := StyleBoxFlat.new()
	tray_style.bg_color = TRAY_BG
	tray_style.border_color = TRAY_BORDER
	tray_style.set_border_width_all(1)
	tray_style.set_corner_radius_all(18)
	_tag_tray.add_theme_stylebox_override("panel", tray_style)

	var tray_margin := MarginContainer.new()
	tray_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_margin.add_theme_constant_override("margin_left", 14)
	tray_margin.add_theme_constant_override("margin_top", 12)
	tray_margin.add_theme_constant_override("margin_right", 14)
	tray_margin.add_theme_constant_override("margin_bottom", 12)
	_tag_tray.add_child(tray_margin)

	_tag_flow = FlowContainer.new()
	_tag_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tag_flow.add_theme_constant_override("h_separation", 10)
	_tag_flow.add_theme_constant_override("v_separation", 10)
	tray_margin.add_child(_tag_flow)

	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_vbox.add_theme_constant_override("separation", 8)
	content_vbox.add_child(bottom_vbox)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0, 52)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.focus_mode = Control.FOCUS_NONE
	ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(action_button, action_button.custom_minimum_size, 24)
	if not action_button.pressed.is_connected(_on_action_pressed):
		action_button.pressed.connect(_on_action_pressed)
	bottom_vbox.add_child(action_button)

	_lock_reason_label = Label.new()
	_lock_reason_label.visible = false
	_lock_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lock_reason_label.add_theme_font_size_override("font_size", 16)
	_lock_reason_label.add_theme_color_override("font_color", LOCK_TEXT)
	bottom_vbox.add_child(_lock_reason_label)


func _apply_image_variant(variant: String) -> void:
	var palette: Array = IMAGE_VARIANT_COLORS.get(variant, IMAGE_VARIANT_COLORS["default"])
	var image_style := _image_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	image_style.bg_color = palette[0]
	_image_panel.add_theme_stylebox_override("panel", image_style)
	if _image_glass:
		var glass_style := _image_glass.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		glass_style.bg_color = palette[0].lerp(Color.WHITE, 0.30)
		glass_style.bg_color.a = 0.12
		_image_glass.add_theme_stylebox_override("panel", glass_style)


func _rebuild_tags(tags: Array) -> void:
	for child in _tag_flow.get_children():
		_tag_flow.remove_child(child)
		child.queue_free()

	for tag_text_variant in tags:
		var tag_text := str(tag_text_variant).strip_edges()
		if tag_text.is_empty():
			continue
		_tag_flow.add_child(_build_tag_chip(tag_text))


func _build_tag_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = TAG_BG
	chip_style.border_color = TAG_BORDER
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(14)
	chip.add_theme_stylebox_override("panel", chip_style)

	var chip_margin := MarginContainer.new()
	chip_margin.add_theme_constant_override("margin_left", 12)
	chip_margin.add_theme_constant_override("margin_top", 7)
	chip_margin.add_theme_constant_override("margin_right", 12)
	chip_margin.add_theme_constant_override("margin_bottom", 7)
	chip.add_child(chip_margin)

	var chip_label := Label.new()
	chip_label.text = text
	chip_label.add_theme_font_size_override("font_size", 17)
	chip_label.add_theme_color_override("font_color", TAG_TEXT)
	chip_margin.add_child(chip_label)

	return chip


func _on_action_pressed() -> void:
	action_pressed.emit(entry_id)
