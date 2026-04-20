class_name TabBarStyleTemplate
extends RefCounted

static func apply_to_bar(tab_bar: HBoxContainer, config: Dictionary = {}) -> void:
	if tab_bar == null:
		return

	var bar_height: float = float(config.get("bar_height", 62.0))
	var font_size: int = int(config.get("font_size", 19))
	var line_position: String = str(config.get("line_position", "top")).to_lower()
	var line_width: int = int(config.get("line_width", 2))
	var selected_line_width: int = int(config.get("selected_line_width", 3))
	var text_raise: float = float(config.get("text_raise", 0.0))

	var normal_bg: Color = Color(config.get("normal_bg", Color(0.9, 0.87, 0.81, 1.0)))
	var hover_bg: Color = Color(config.get("hover_bg", Color(0.93, 0.9, 0.84, 1.0)))
	var pressed_bg: Color = Color(config.get("pressed_bg", Color(0.88, 0.85, 0.79, 1.0)))
	var selected_bg: Color = Color(config.get("selected_bg", Color(0.95, 0.92, 0.85, 1.0)))

	var line_color: Color = Color(config.get("line_color", Color(0.52, 0.49, 0.45, 1.0)))
	var selected_line_color: Color = Color(config.get("selected_line_color", Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0)))
	var font_color: Color = Color(config.get("font_color", Color(0.35, 0.32, 0.28, 1.0)))
	var selected_font_color: Color = Color(config.get("selected_font_color", Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0)))

	tab_bar.add_theme_constant_override("separation", 0)
	tab_bar.custom_minimum_size.y = bar_height

	var normal_style := _build_line_style(normal_bg, line_color, line_position, line_width, text_raise)
	var hover_style := _build_line_style(hover_bg, line_color, line_position, line_width, text_raise)
	var pressed_style := _build_line_style(pressed_bg, line_color, line_position, line_width, text_raise)
	var selected_style := _build_line_style(selected_bg, selected_line_color, line_position, selected_line_width, text_raise)

	for child in tab_bar.get_children():
		if child is Button:
			var tab_btn: Button = child
			tab_btn.custom_minimum_size.x = 0.0
			tab_btn.custom_minimum_size.y = bar_height
			tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab_btn.add_theme_font_size_override("font_size", font_size)
			tab_btn.add_theme_color_override("font_color", font_color)
			tab_btn.add_theme_color_override("font_hover_color", font_color)
			tab_btn.add_theme_color_override("font_pressed_color", font_color)
			tab_btn.add_theme_color_override("font_disabled_color", selected_font_color)
			tab_btn.add_theme_stylebox_override("normal", normal_style)
			tab_btn.add_theme_stylebox_override("hover", hover_style)
			tab_btn.add_theme_stylebox_override("pressed", pressed_style)
			tab_btn.add_theme_stylebox_override("disabled", selected_style)


static func _build_line_style(
	bg_color: Color,
	line_color: Color,
	line_position: String,
	line_width: int,
	text_raise: float
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = line_color
	style.content_margin_bottom = max(0.0, text_raise)
	if line_position == "bottom":
		style.border_width_bottom = max(0, line_width)
	else:
		style.border_width_top = max(0, line_width)
	return style
