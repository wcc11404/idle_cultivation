class_name PopupStyleTemplate
extends RefCounted

const POPUP_BG_COLOR := Color(234.0 / 255.0, 218.0 / 255.0, 185.0 / 255.0, 1.0) # #eadab9（不透明）
const POPUP_BORDER_COLOR := Color(0.713725, 0.639216, 0.513725, 0.95)

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
	# 仅作为视觉遮罩，不拦截输入；外部点击关闭由弹窗自身统一判定
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return overlay
