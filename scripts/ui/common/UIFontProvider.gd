class_name UIFontProvider
extends RefCounted

static var _ui_theme: Theme = null
static var _ui_font: FontFile = null

const LABEL_OUTLINE_SIZE := 0
const RICH_TEXT_OUTLINE_SIZE := 0
const LINE_EDIT_OUTLINE_SIZE := 0

static func _get_default_font() -> FontFile:
	if _ui_font:
		return _ui_font
	_ui_font = load("res://assets/fonts/SourceHanSansSC-Medium.otf") as FontFile
	return _ui_font

static func get_theme() -> Theme:
	if _ui_theme:
		return _ui_theme
	var theme := Theme.new()
	var default_font := _get_default_font()
	if default_font:
		theme.default_font = default_font
	theme.set_default_font_size(16)
	theme.set_color("font_outline_color", "Label", Color(0.12, 0.11, 0.10, 0.18))
	theme.set_constant("outline_size", "Label", LABEL_OUTLINE_SIZE)
	theme.set_color("font_outline_color", "RichTextLabel", Color(0.12, 0.11, 0.10, 0.16))
	theme.set_constant("outline_size", "RichTextLabel", RICH_TEXT_OUTLINE_SIZE)
	theme.set_color("font_outline_color", "LineEdit", Color(0.12, 0.11, 0.10, 0.12))
	theme.set_constant("outline_size", "LineEdit", LINE_EDIT_OUTLINE_SIZE)
	_ui_theme = theme
	return _ui_theme

static func apply_to_root(root: Control) -> void:
	if not root:
		return
	root.theme = get_theme()
