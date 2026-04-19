class_name ActionButtonTemplate
extends RefCounted

const PRESET_CULTIVATION_YELLOW := "cultivation_yellow"
const PRESET_BREAKTHROUGH_RED := "breakthrough_red"
const PRESET_ALCHEMY_GREEN := "alchemy_green"
const PRESET_PROFILE_BLUE := "profile_blue"
const PRESET_LIGHT_NEUTRAL := "light_neutral"
const PRESET_LIGHT_NEUTRAL_SELECTED := "light_neutral_selected"
const PRESET_SPELL_VIEW_BROWN := "spell_view_brown"

const _LIGHT_TEXT := Color(0.98, 0.95, 0.86, 1.0)

static func apply_to_button(
	button: Button,
	preset: String,
	custom_size: Vector2 = Vector2.ZERO,
	font_size: int = -1
) -> void:
	if not button:
		return

	var cfg := _get_preset_config(preset)
	if cfg.is_empty():
		return

	if custom_size != Vector2.ZERO:
		button.custom_minimum_size = custom_size

	if font_size > 0:
		button.add_theme_font_size_override("font_size", font_size)

	var normal := _build_style(cfg["normal_bg"], cfg["normal_border"])
	var hover := _build_style(cfg["hover_bg"], cfg["hover_border"])
	var pressed := _build_style(cfg["pressed_bg"], cfg["pressed_border"])
	var disabled := _build_style(cfg["disabled_bg"], cfg["disabled_border"])

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	var font_color: Color = cfg.get("font_color", _LIGHT_TEXT)
	var disabled_font_color: Color = cfg.get("font_disabled_color", font_color)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", disabled_font_color)

static func apply_cultivation_yellow(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_CULTIVATION_YELLOW, custom_size, font_size)

static func apply_breakthrough_red(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_BREAKTHROUGH_RED, custom_size, font_size)

static func apply_alchemy_green(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_ALCHEMY_GREEN, custom_size, font_size)

static func apply_profile_blue(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_PROFILE_BLUE, custom_size, font_size)

static func apply_light_neutral(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_LIGHT_NEUTRAL, custom_size, font_size)

static func apply_light_neutral_selected(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_LIGHT_NEUTRAL_SELECTED, custom_size, font_size)

static func apply_spell_view_brown(button: Button, custom_size: Vector2 = Vector2.ZERO, font_size: int = -1) -> void:
	apply_to_button(button, PRESET_SPELL_VIEW_BROWN, custom_size, font_size)

static func _build_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

static func _get_preset_config(preset: String) -> Dictionary:
	match preset:
		PRESET_CULTIVATION_YELLOW:
			return {
				"normal_bg": Color(0.807843, 0.627451, 0.188235, 1.0),
				"normal_border": Color(0.658824, 0.505882, 0.14902, 1.0),
				"hover_bg": Color(0.85098, 0.666667, 0.2, 1.0),
				"hover_border": Color(0.658824, 0.505882, 0.14902, 1.0),
				"pressed_bg": Color(0.729412, 0.560784, 0.172549, 1.0),
				"pressed_border": Color(0.588235, 0.447059, 0.133333, 1.0),
				"disabled_bg": Color(0.6, 0.58, 0.55, 0.6),
				"disabled_border": Color(0.5, 0.48, 0.45, 0.6),
				"font_color": _LIGHT_TEXT,
				"font_disabled_color": Color(0.4, 0.38, 0.35, 1.0)
			}
		PRESET_BREAKTHROUGH_RED:
			return {
				"normal_bg": Color(0.745098, 0.25098, 0.196078, 1.0),
				"normal_border": Color(0.611765, 0.2, 0.156863, 1.0),
				"hover_bg": Color(0.803922, 0.278431, 0.219608, 1.0),
				"hover_border": Color(0.611765, 0.2, 0.156863, 1.0),
				"pressed_bg": Color(0.666667, 0.223529, 0.176471, 1.0),
				"pressed_border": Color(0.533333, 0.176471, 0.141176, 1.0),
				"disabled_bg": Color(0.6, 0.58, 0.55, 0.6),
				"disabled_border": Color(0.5, 0.48, 0.45, 0.6),
				"font_color": _LIGHT_TEXT,
				"font_disabled_color": Color(0.4, 0.38, 0.35, 1.0)
			}
		PRESET_ALCHEMY_GREEN:
			return {
				"normal_bg": Color(0.35, 0.5, 0.35, 1.0),
				"normal_border": Color(0.25, 0.4, 0.25, 1.0),
				"hover_bg": Color(0.4, 0.55, 0.4, 1.0),
				"hover_border": Color(0.25, 0.4, 0.25, 1.0),
				"pressed_bg": Color(0.3, 0.45, 0.3, 1.0),
				"pressed_border": Color(0.25, 0.4, 0.25, 1.0),
				"disabled_bg": Color(0.6, 0.58, 0.55, 0.6),
				"disabled_border": Color(0.5, 0.48, 0.45, 0.6),
				"font_color": _LIGHT_TEXT,
				"font_disabled_color": Color(0.4, 0.38, 0.35, 1.0)
			}
		PRESET_PROFILE_BLUE:
			return {
				"normal_bg": Color(0.239216, 0.490196, 0.796078, 1.0),
				"normal_border": Color(0.14902, 0.345098, 0.596078, 1.0),
				"hover_bg": Color(0.278431, 0.54902, 0.866667, 1.0),
				"hover_border": Color(0.14902, 0.345098, 0.596078, 1.0),
				"pressed_bg": Color(0.203922, 0.427451, 0.705882, 1.0),
				"pressed_border": Color(0.12549, 0.301961, 0.529412, 1.0),
				"disabled_bg": Color(0.203922, 0.427451, 0.705882, 0.85),
				"disabled_border": Color(0.12549, 0.301961, 0.529412, 0.85),
				"font_color": Color(0.96, 0.97, 0.99, 1.0),
				"font_disabled_color": Color(0.96, 0.97, 0.99, 0.9)
			}
		PRESET_LIGHT_NEUTRAL:
			return {
				"normal_bg": Color(0.94902, 0.898039, 0.8, 1.0),
				"normal_border": Color(0.713725, 0.639216, 0.513725, 1.0),
				"hover_bg": Color(0.972549, 0.92549, 0.831373, 1.0),
				"hover_border": Color(0.713725, 0.639216, 0.513725, 1.0),
				"pressed_bg": Color(0.901961, 0.85098, 0.752941, 1.0),
				"pressed_border": Color(0.666667, 0.596078, 0.478431, 1.0),
				"disabled_bg": Color(0.901961, 0.85098, 0.752941, 0.75),
				"disabled_border": Color(0.666667, 0.596078, 0.478431, 0.75),
				"font_color": Color(0.28, 0.24, 0.18, 1.0),
				"font_disabled_color": Color(0.35, 0.30, 0.24, 0.88)
			}
		PRESET_LIGHT_NEUTRAL_SELECTED:
			return {
				"normal_bg": Color(0.878431, 0.788235, 0.592157, 1.0),
				"normal_border": Color(0.737255, 0.615686, 0.298039, 1.0),
				"hover_bg": Color(0.905882, 0.815686, 0.619608, 1.0),
				"hover_border": Color(0.737255, 0.615686, 0.298039, 1.0),
				"pressed_bg": Color(0.831373, 0.737255, 0.537255, 1.0),
				"pressed_border": Color(0.678431, 0.560784, 0.27451, 1.0),
				"disabled_bg": Color(0.831373, 0.737255, 0.537255, 0.8),
				"disabled_border": Color(0.678431, 0.560784, 0.27451, 0.8),
				"font_color": Color(0.24, 0.21, 0.16, 1.0),
				"font_disabled_color": Color(0.24, 0.21, 0.16, 0.85)
			}
		PRESET_SPELL_VIEW_BROWN:
			return {
				"normal_bg": Color(0.77, 0.67, 0.54, 1.0),
				"normal_border": Color(0.64, 0.54, 0.42, 1.0),
				"hover_bg": Color(0.81, 0.71, 0.58, 1.0),
				"hover_border": Color(0.64, 0.54, 0.42, 1.0),
				"pressed_bg": Color(0.70, 0.61, 0.49, 1.0),
				"pressed_border": Color(0.56, 0.47, 0.37, 1.0),
				"disabled_bg": Color(0.64, 0.58, 0.50, 0.75),
				"disabled_border": Color(0.52, 0.44, 0.35, 0.75),
				"font_color": _LIGHT_TEXT,
				"font_disabled_color": Color(0.90, 0.86, 0.80, 0.82)
			}
	return {}
