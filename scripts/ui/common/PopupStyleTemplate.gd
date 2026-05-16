class_name PopupStyleTemplate
extends RefCounted

const UI_FEEDBACK_MANAGER = preload("res://scripts/ui/common/UIFeedbackManager.gd")
const CORNER_TEXTURE := preload("res://assets/popup_decor/popup_corner_gold.png")
const PATTERN_TEXTURE := preload("res://assets/popup_decor/popup_pattern_clouds.png")

const POPUP_BG_COLOR := Color(234.0 / 255.0, 218.0 / 255.0, 185.0 / 255.0, 1.0) # #eadab9（不透明）
const POPUP_BORDER_COLOR := Color(0.713725, 0.639216, 0.513725, 0.95)
const POPUP_TEXT_COLOR := Color(0.20, 0.17, 0.13, 1.0)
const POPUP_MUTED_TEXT_COLOR := Color(0.48, 0.40, 0.30, 1.0)
const DECORATED_POPUP_MIN_SIZE := Vector2(500, 350)
const DECORATED_POPUP_CONTENT_MARGIN := 32
const DECORATED_POPUP_CONTENT_TOP_MARGIN := 30
const DECORATED_POPUP_CONTENT_BOTTOM_MARGIN := 42
const DECORATED_POPUP_PATTERN_ALPHA := 0.40
const DECORATED_POPUP_CORNER_SIZE := Vector2(122, 122)
const DECORATED_POPUP_CORNER_INSET := -13.0

static func build_panel_style(config: Dictionary = {}) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(config.get("bg_color", POPUP_BG_COLOR))
	style.border_color = Color(config.get("border_color", POPUP_BORDER_COLOR))
	style.set_corner_radius_all(int(config.get("corner_radius", 12)))
	style.set_border_width_all(int(config.get("border_width", 2)))
	# 关闭抗锯齿边缘，避免四角出现发黑伪影
	style.anti_aliasing = false
	return style

static func build_button_style(bg_color: Color, border_color: Color, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	return style

static func build_decorated_popup(panel: Control, config: Dictionary = {}) -> MarginContainer:
	if not panel:
		return null
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = _max_vector2(
		panel.custom_minimum_size,
		Vector2(config.get("min_size", DECORATED_POPUP_MIN_SIZE))
	)
	if panel is Panel:
		(panel as Panel).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	elif panel is PanelContainer:
		(panel as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var background := Panel.new()
	background.name = str(config.get("background_name", "DecoratedBackground"))
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _decorated_panel_style(config))
	_fill_rect(background)
	panel.add_child(background)

	var pattern := TextureRect.new()
	pattern.name = str(config.get("pattern_name", "DecoratedPattern"))
	pattern.texture = PATTERN_TEXTURE
	pattern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pattern.stretch_mode = int(config.get("pattern_stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_COVERED))
	pattern.modulate = Color(
		0.88,
		0.62,
		0.18,
		float(config.get("pattern_alpha", DECORATED_POPUP_PATTERN_ALPHA))
	)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(pattern)
	panel.add_child(pattern)

	var inner_line := Panel.new()
	inner_line.name = str(config.get("inner_line_name", "DecoratedInnerLine"))
	inner_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_line.add_theme_stylebox_override("panel", _inner_line_style())
	_fill_rect(inner_line)
	inner_line.offset_left = 12
	inner_line.offset_top = 12
	inner_line.offset_right = -12
	inner_line.offset_bottom = -12
	panel.add_child(inner_line)

	var corner_size := Vector2(config.get("corner_size", DECORATED_POPUP_CORNER_SIZE))
	var corners: Array[TextureRect] = [
		_corner("DecoratedCornerTopLeft", corner_size, false, false),
		_corner("DecoratedCornerTopRight", corner_size, true, false),
		_corner("DecoratedCornerBottomLeft", corner_size, false, true),
		_corner("DecoratedCornerBottomRight", corner_size, true, true)
	]
	for corner in corners:
		panel.add_child(corner)
	panel.resized.connect(func() -> void:
		_layout_corners(panel, corners, float(config.get("corner_inset", DECORATED_POPUP_CORNER_INSET)))
	)
	var initial_layout := func() -> void:
		_layout_corners(panel, corners, float(config.get("corner_inset", DECORATED_POPUP_CORNER_INSET)))
	initial_layout.call_deferred()

	var content_margin := MarginContainer.new()
	content_margin.name = str(config.get("content_name", "DecoratedContent"))
	_fill_rect(content_margin)
	content_margin.add_theme_constant_override("margin_left", int(config.get("margin_left", DECORATED_POPUP_CONTENT_MARGIN)))
	content_margin.add_theme_constant_override("margin_top", int(config.get("margin_top", DECORATED_POPUP_CONTENT_TOP_MARGIN)))
	content_margin.add_theme_constant_override("margin_right", int(config.get("margin_right", DECORATED_POPUP_CONTENT_MARGIN)))
	content_margin.add_theme_constant_override("margin_bottom", int(config.get("margin_bottom", DECORATED_POPUP_CONTENT_BOTTOM_MARGIN)))
	panel.add_child(content_margin)
	return content_margin

static func create_title_label(text: String = "") -> Label:
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	return title

static func create_title_separator() -> ColorRect:
	var separator := ColorRect.new()
	separator.name = "TitleSeparator"
	separator.color = Color(0.75, 0.61, 0.34, 0.38)
	separator.custom_minimum_size = Vector2(0, 2)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return separator

static func create_overlay(parent: Control, on_outside_click: Callable, alpha: float = 0.62) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = "PopupOverlay"
	overlay.visible = false
	overlay.z_index = 1000
	overlay.color = Color(0, 0, 0, clamp(alpha, 0.0, 1.0))
	overlay.layout_mode = 1
	overlay.anchors_preset = 15
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.grow_horizontal = 2
	overlay.grow_vertical = 2
	if on_outside_click.is_valid():
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		overlay.gui_input.connect(func(event: InputEvent):
			var event_global_position := Vector2.ZERO
			var has_event_position := false
			if event is InputEventMouseButton:
				event_global_position = (event as InputEventMouseButton).global_position
				has_event_position = true
			elif event is InputEventScreenTouch:
				event_global_position = (event as InputEventScreenTouch).position
				has_event_position = true
			if overlay.get_child_count() > 0:
				for child in overlay.get_children():
					if child is Control:
						var child_control := child as Control
						if child_control.visible and has_event_position and child_control.get_global_rect().has_point(event_global_position):
							return
			if event is InputEventMouseButton:
				var mouse_event := event as InputEventMouseButton
				if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
					return
			elif event is InputEventScreenTouch:
				var touch_event := event as InputEventScreenTouch
				if not touch_event.pressed:
					return
			else:
				return
			on_outside_click.call()
			if overlay.get_viewport():
				overlay.get_viewport().set_input_as_handled()
		)
	else:
		# 仅作为视觉遮罩时不拦截输入。
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return overlay

static func play_open(overlay: CanvasItem, panel: Control, config: Dictionary = {}) -> void:
	UI_FEEDBACK_MANAGER.play_popup_open(overlay, panel, config)

static func play_close(
	overlay: CanvasItem,
	panel: Control,
	on_finished: Callable = Callable(),
	config: Dictionary = {}
) -> void:
	UI_FEEDBACK_MANAGER.play_popup_close(overlay, panel, on_finished, config)

static func _decorated_panel_style(config: Dictionary = {}) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(config.get("bg_color", Color(0.96, 0.90, 0.76, 0.98)))
	style.border_color = Color(config.get("border_color", Color(0.71, 0.62, 0.45, 1.0)))
	style.set_corner_radius_all(int(config.get("corner_radius", 20)))
	style.set_border_width_all(int(config.get("border_width", 2)))
	style.shadow_color = Color(0.32, 0.22, 0.10, 0.18)
	style.shadow_size = int(config.get("shadow_size", 8))
	style.shadow_offset = Vector2(config.get("shadow_offset", Vector2(0, 3)))
	style.anti_aliasing = false
	return style

static func _inner_line_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.96, 0.83, 0.42)
	style.set_corner_radius_all(15)
	style.set_border_width_all(1)
	style.anti_aliasing = false
	return style

static func _corner(node_name: String, node_size: Vector2, flip_h: bool, flip_v: bool) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = CORNER_TEXTURE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = node_size
	rect.size = node_size
	rect.flip_h = flip_h
	rect.flip_v = flip_v
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func _layout_corners(panel: Control, corners: Array[TextureRect], inset: float) -> void:
	if not panel or corners.size() != 4:
		return
	var panel_size := panel.size
	for corner in corners:
		corner.size = corner.custom_minimum_size
	corners[0].position = Vector2(inset, inset)
	corners[1].position = Vector2(panel_size.x - corners[1].size.x - inset, inset)
	corners[2].position = Vector2(inset, panel_size.y - corners[2].size.y - inset)
	corners[3].position = Vector2(panel_size.x - corners[3].size.x - inset, panel_size.y - corners[3].size.y - inset)

static func _fill_rect(control: Control) -> void:
	control.layout_mode = 1
	control.anchors_preset = 15
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.grow_horizontal = 2
	control.grow_vertical = 2

static func _max_vector2(left: Vector2, right: Vector2) -> Vector2:
	return Vector2(maxf(left.x, right.x), maxf(left.y, right.y))
