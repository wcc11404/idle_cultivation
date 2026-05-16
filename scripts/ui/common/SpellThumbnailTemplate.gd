class_name SpellThumbnailTemplate
extends RefCounted

const DEFAULT_BG_COLOR := Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0) # #f2e5cc
const OPTIMIZED_BG_COLOR := Color(0.96, 0.90, 0.78, 1.0)
const EQUIPPED_BORDER_COLOR := Color(0.84, 0.63, 0.18, 1.0)

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

static func apply_thumbnail_state(card: PanelContainer, rarity_color: Color, is_equipped: bool) -> void:
	var border_color := EQUIPPED_BORDER_COLOR if is_equipped else rarity_color.lightened(0.22)
	apply_to_card(card, {
		"bg_color": OPTIMIZED_BG_COLOR,
		"border_color": border_color,
		"corner_radius": 10,
		"border_width": 2
	})
