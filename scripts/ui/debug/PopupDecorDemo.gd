extends Control

const ActionButtonTemplate = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const PopupStyleTemplate = preload("res://scripts/ui/common/PopupStyleTemplate.gd")
const UIFontProvider = preload("res://scripts/ui/common/UIFontProvider.gd")

const COLOR_BG := Color(0.95, 0.90, 0.80, 1.0)
const COLOR_TEXT := Color(0.20, 0.17, 0.13, 1.0)
const COLOR_MUTED := Color(0.48, 0.40, 0.30, 1.0)
const COLOR_BORDER := Color(0.71, 0.62, 0.45, 1.0)

var _modal_overlay: ColorRect = null
var _modal_panel: Control = null

func _ready() -> void:
	UIFontProvider.apply_to_root(self)
	_build_scene()

func _build_scene() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	scroll.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_notes_card())
	root.add_child(_build_decorated_popup_sample(
		"术法参悟",
		"弹窗角饰采用透明 PNG，底板、圆角、边框仍由 Godot 控件负责。纹样层低透明铺底，后续可以按弹窗类型开关。",
		220,
		"compact",
		"轻量信息弹窗"
	))
	root.add_child(_build_decorated_popup_sample(
		"突破条件",
		"这里模拟中等高度弹窗：标题、说明、材料条目和按钮都在内容层里，装饰层完全不参与业务布局。",
		310,
		"normal",
		"中型功能弹窗"
	))
	root.add_child(_build_decorated_popup_sample(
		"天机阁祈愿说明",
		"高弹窗里角饰不会随内容拉伸变形，只有底板和淡纹样自适应尺寸。这个结构比较适合迁移到 PopupStyleTemplate。",
		410,
		"tall",
		"长内容说明弹窗"
	))
	root.add_child(_build_modal_demo_card())
	_build_modal_layer()

func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.94, 0.84, 0.96), COLOR_BORDER, 18, 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "弹窗角饰与轻纹样 Demo"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(title)

	var desc := Label.new()
	desc.text = "方案：Godot 负责弹窗底板和自适应布局，imagegen 素材只负责四角金玉角饰与低透明纹样。正式接入前先看整体气质。"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(desc)
	return panel

func _build_notes_card() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1.0, 0.96, 0.86, 0.88), Color(0.80, 0.70, 0.52, 0.85), 16, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var label := Label.new()
	label.text = "迁移判断：后续正式弹窗以“打开装饰弹窗”的尺寸、配色、标题分割线、按钮和底部留白为标准；淡金云纹层是铺满底板的 Pattern 纹样，不参与布局和点击。"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	margin.add_child(label)
	return panel

func _build_modal_demo_card() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.94, 0.84, 0.96), COLOR_BORDER, 18, 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "打开真实遮罩弹窗"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(title)

	var button := Button.new()
	button.text = "打开装饰弹窗"
	ActionButtonTemplate.apply_to_button(button, ActionButtonTemplate.PRESET_CULTIVATION_YELLOW, Vector2(220, 48), 18)
	button.pressed.connect(_open_modal)
	box.add_child(button)
	return panel

func _build_decorated_popup_sample(title_text: String, body_text: String, height: float, variant: String, badge: String) -> Control:
	var shell := Control.new()
	shell.name = "DecoratedPopup_%s" % variant
	shell.custom_minimum_size = Vector2(0, height)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_add_decorated_layers(shell, title_text, body_text, badge, variant)
	return shell

func _add_decorated_layers(shell: Control, title_text: String, body_text: String, badge: String, variant: String) -> void:
	var min_size := PopupStyleTemplate.DECORATED_POPUP_MIN_SIZE
	if variant == "tall":
		min_size = Vector2(500, 410)
	elif variant == "compact":
		min_size = Vector2(500, 350)
	var content_margin := PopupStyleTemplate.build_decorated_popup(shell, {
		"min_size": min_size
	})

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	content_margin.add_child(box)

	var badge_label := Label.new()
	badge_label.text = badge
	badge_label.add_theme_font_size_override("font_size", 14)
	badge_label.add_theme_color_override("font_color", Color(0.62, 0.47, 0.19, 1.0))
	box.add_child(badge_label)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(title)

	var separator := ColorRect.new()
	separator.color = Color(0.75, 0.61, 0.34, 0.38)
	separator.custom_minimum_size = Vector2(0, 2)
	box.add_child(separator)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(body)

	if variant != "compact":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		for text in ["云纹角饰", "淡纹样", "自适应"]:
			row.add_child(_pill(text))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button := Button.new()
	button.text = "确认"
	ActionButtonTemplate.apply_to_button(button, ActionButtonTemplate.PRESET_CULTIVATION_YELLOW, Vector2(0, 42), 18)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(button)

func _build_modal_layer() -> void:
	_modal_overlay = PopupStyleTemplate.create_overlay(self, _close_modal, 0.58)
	_modal_overlay.name = "PopupDecorDemoOverlay"
	add_child(_modal_overlay)

	_modal_panel = Control.new()
	_modal_panel.name = "DecoratedModal"
	_modal_panel.visible = false
	_modal_panel.custom_minimum_size = PopupStyleTemplate.DECORATED_POPUP_MIN_SIZE
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_overlay.add_child(_modal_panel)
	_add_decorated_layers(
		_modal_panel,
		"云篆弹窗",
		"这是带遮罩的真实弹窗预览。点击弹窗内部不会关闭，点击暗色区域才关闭；正式接入时可以直接复用现有 PopupStyleTemplate 动效。",
		"遮罩弹窗预览",
		"normal"
	)

func _open_modal() -> void:
	if not _modal_overlay or not _modal_panel:
		return
	var viewport_size := get_viewport_rect().size
	var modal_size := _modal_panel.custom_minimum_size
	_modal_panel.size = modal_size
	_modal_panel.position = (viewport_size - modal_size) * 0.5
	PopupStyleTemplate.play_open(_modal_overlay, _modal_panel)

func _close_modal() -> void:
	if not _modal_overlay or not _modal_panel or not _modal_overlay.visible:
		return
	PopupStyleTemplate.play_close(_modal_overlay, _modal_panel, func() -> void:
		_modal_panel.visible = false
		_modal_overlay.visible = false
	)

func _pill(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.36, 0.28, 0.18, 1.0))
	label.add_theme_stylebox_override("normal", _style(Color(1.0, 0.96, 0.84, 0.72), Color(0.77, 0.67, 0.48, 0.55), 12, 1))
	return label

func _style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
