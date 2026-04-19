class_name SpellThumbnailTemplate
extends RefCounted

const DEFAULT_BG_COLOR := Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0) # #f2e5cc

static func apply_to_card(card: PanelContainer, config: Dictionary = {}) -> void:
	if card == null:
		return

	var bg_color: Color = Color(config.get("bg_color", DEFAULT_BG_COLOR))
	var border_color: Color = Color(config.get("border_color", Color(0.713725, 0.639216, 0.513725, 0.8)))
	var corner_radius: int = int(config.get("corner_radius", 8))
	var border_width: int = int(config.get("border_width", 2))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	card.add_theme_stylebox_override("panel", style)

