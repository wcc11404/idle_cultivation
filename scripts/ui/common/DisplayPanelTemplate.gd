class_name DisplayPanelTemplate
extends RefCounted

const DEFAULT_CONTENT_LEFT_INSET := 12
const DEFAULT_HEADER_BOTTOM_GAP := 8

# 约束说明：
# 1) 展示面板内所有后续新增内容，左侧起点都应与标题首字左侧对齐。
# 2) 标题行与下方内容留白使用固定值，避免不同面板视觉节奏不一致。
# 3) 如果某个面板结构特殊，至少保证“内容左边距”和“标题下方留白”遵循这两个默认值。

static func apply_to_row(header_row: HBoxContainer, config: Dictionary = {}) -> void:
	if header_row == null:
		return

	var accent_color: Color = Color(config.get("accent_color", Color(0.870588, 0.705882, 0.207843, 1.0)))
	var title_color: Color = Color(config.get("title_color", Color(0.22, 0.2, 0.18, 1.0)))
	var line_color: Color = Color(config.get("line_color", Color(0.82, 0.78, 0.71, 1.0)))
	var title_text: String = str(config.get("title_text", ""))
	var title_font_size: int = int(config.get("title_font_size", 22))
	var accent_width: float = float(config.get("accent_width", 4.0))
	var accent_height: float = float(config.get("accent_height", 24.0))
	var row_separation: int = int(config.get("row_separation", 8))

	header_row.add_theme_constant_override("separation", row_separation)

	var accent := header_row.get_node_or_null("HeaderAccent")
	if accent is ColorRect:
		accent.custom_minimum_size = Vector2(accent_width, accent_height)
		accent.color = accent_color

	var title := header_row.get_node_or_null("HeaderTitle")
	if title is Label:
		title.add_theme_color_override("font_color", title_color)
		title.add_theme_font_size_override("font_size", title_font_size)
		if title_text != "":
			title.text = title_text

	var line := header_row.get_node_or_null("HeaderLine")
	if line is HSeparator:
		line.self_modulate = line_color

static func apply_content_layout(
	left_pad_controls: Array,
	left_margin_container: MarginContainer = null,
	header_bottom_spacer: Control = null,
	config: Dictionary = {}
) -> void:
	var content_left_inset: int = int(config.get("content_left_inset", DEFAULT_CONTENT_LEFT_INSET))
	var header_bottom_gap: int = int(config.get("header_bottom_gap", DEFAULT_HEADER_BOTTOM_GAP))

	for node in left_pad_controls:
		if node is Control:
			node.custom_minimum_size.x = float(content_left_inset)

	if left_margin_container:
		left_margin_container.add_theme_constant_override("margin_left", content_left_inset)

	if header_bottom_spacer:
		header_bottom_spacer.custom_minimum_size.y = float(header_bottom_gap)
