class_name TopTabBarStyleTemplate
extends RefCounted

static func apply_to_bar(tab_bar: HBoxContainer, config: Dictionary = {}) -> void:
	if tab_bar == null:
		return

	var bar_height: float = float(config.get("bar_height", 62.0))
	var font_size: int = int(config.get("font_size", 20))
	var separation: int = int(config.get("separation", 0))
	var button_min_width: float = float(config.get("button_min_width", 0.0))
	var button_corner_radius: int = int(config.get("button_corner_radius", 14))
	var text_raise: float = float(config.get("text_raise", 0.0))
	var shell_corner_radius: int = int(config.get("shell_corner_radius", 18))
	var shell_border_width: int = int(config.get("shell_border_width", 1))
	var shell_inset_x: float = float(config.get("shell_inset_x", 12.0))
	var shell_inset_y: float = float(config.get("shell_inset_y", 10.0))

	var shell_bg: Color = Color(config.get("shell_bg", Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0)))
	var shell_border_color: Color = Color(config.get("shell_border_color", Color(0.93, 0.88, 0.79, 1.0)))
	var normal_bg: Color = Color(config.get("normal_bg", shell_bg))
	var hover_bg: Color = Color(config.get("hover_bg", shell_bg))
	var pressed_bg: Color = Color(config.get("pressed_bg", shell_bg))
	var selected_bg: Color = Color(config.get("selected_bg", Color(188.0 / 255.0, 144.0 / 255.0, 48.0 / 255.0, 1.0)))
	var font_color: Color = Color(config.get("font_color", Color(0.35, 0.32, 0.28, 1.0)))
	var selected_font_color: Color = Color(config.get("selected_font_color", Color(1, 1, 1, 1)))

	tab_bar.add_theme_constant_override("separation", separation)
	tab_bar.custom_minimum_size.y = bar_height
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	if tab_bar.get_parent() is PanelContainer:
		var shell: PanelContainer = tab_bar.get_parent()
		shell.custom_minimum_size.y = bar_height + shell_inset_y * 2.0
		shell.add_theme_stylebox_override(
			"panel",
			_build_shell_style(shell_bg, shell_border_color, shell_corner_radius, shell_border_width)
		)
		tab_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		tab_bar.offset_left = shell_inset_x
		tab_bar.offset_top = shell_inset_y
		tab_bar.offset_right = -shell_inset_x
		tab_bar.offset_bottom = -shell_inset_y

	var normal_style := _build_segment_style(normal_bg, button_corner_radius, text_raise)
	var hover_style := _build_segment_style(hover_bg, button_corner_radius, text_raise)
	var pressed_style := _build_segment_style(pressed_bg, button_corner_radius, text_raise)
	var selected_style := _build_segment_style(selected_bg, button_corner_radius, text_raise)

	for child in tab_bar.get_children():
		var tab_btn := _resolve_tab_button(child)
		if tab_btn == null:
			continue
		tab_btn.custom_minimum_size.x = button_min_width
		tab_btn.custom_minimum_size.y = bar_height
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.add_theme_font_size_override("font_size", font_size)
		tab_btn.add_theme_color_override("font_color", font_color)
		tab_btn.add_theme_color_override("font_hover_color", font_color)
		tab_btn.add_theme_color_override("font_pressed_color", font_color)
		tab_btn.add_theme_color_override("font_disabled_color", selected_font_color)
		tab_btn.remove_theme_stylebox_override("normal")
		tab_btn.remove_theme_stylebox_override("hover")
		tab_btn.remove_theme_stylebox_override("pressed")
		tab_btn.remove_theme_stylebox_override("disabled")
		tab_btn.add_theme_stylebox_override("normal", normal_style)
		tab_btn.add_theme_stylebox_override("hover", hover_style)
		tab_btn.add_theme_stylebox_override("pressed", pressed_style)
		tab_btn.add_theme_stylebox_override("disabled", selected_style)


static func _build_segment_style(bg_color: Color, corner_radius: int, text_raise: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(max(0, corner_radius))
	style.content_margin_bottom = max(0.0, text_raise)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


static func _build_shell_style(bg_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_corner_radius_all(max(0, corner_radius))
	style.set_border_width_all(max(0, border_width))
	return style


static func _resolve_tab_button(node: Node) -> Button:
	if node is Button:
		return node as Button
	for child in node.get_children():
		if child is Button:
			return child as Button
	return null
