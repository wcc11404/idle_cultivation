class_name UIFontProvider
extends RefCounted

static var _ui_theme: Theme = null

static func get_theme() -> Theme:
	if _ui_theme:
		return _ui_theme
	var theme := Theme.new()
	theme.set_default_font_size(16)
	theme.set_color("font_outline_color", "Label", Color(0.12, 0.11, 0.10, 0.35))
	theme.set_constant("outline_size", "Label", 1)
	theme.set_color("font_outline_color", "RichTextLabel", Color(0.12, 0.11, 0.10, 0.3))
	theme.set_constant("outline_size", "RichTextLabel", 1)
	theme.set_color("font_outline_color", "LineEdit", Color(0.12, 0.11, 0.10, 0.22))
	theme.set_constant("outline_size", "LineEdit", 1)
	_ui_theme = theme
	return _ui_theme

static func apply_to_root(root: Control) -> void:
	if not root:
		return
	root.theme = get_theme()
