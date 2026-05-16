extends RefCounted

const BOTTOM_TAB_BAR_STYLE_TEMPLATE = preload("res://scripts/ui/common/BottomTabBarStyleTemplate.gd")
const TOP_TAB_BAR_STYLE_TEMPLATE = preload("res://scripts/ui/common/TopTabBarStyleTemplate.gd")
const DISPLAY_PANEL_TEMPLATE = preload("res://scripts/ui/common/DisplayPanelTemplate.gd")
const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const NOTIFICATION_BADGE_STATE_SCRIPT = preload("res://scripts/ui/common/NotificationBadgeState.gd")
const SAFE_AREA_HELPER = preload("res://scripts/ui/common/SafeAreaHelper.gd")

const BADGE_COLOR := Color(0.9059, 0.2980, 0.2353, 1.0)
const BADGE_BORDER_COLOR := Color(1.0, 0.9608, 0.9412, 1.0)
const BADGE_TEXT_COLOR := Color(1.0, 0.9804, 0.9725, 1.0)


func setup_optional_nodes(ui: Control) -> void:
	ui.view_button = ui.get_node_or_null("ContentFrame/VBoxContainer/ContentPanel/ChunaPanel/ItemDetailPanel/VBoxContainer/MainHBox/ButtonContainer/ButtonVBox/ViewButton")
	_setup_action_button_templates(ui)
	_setup_log_scroll_behavior(ui)
	_setup_settings_scroll_behavior(ui)
	_setup_status_header_style(ui)
	_setup_breakthrough_panel_style(ui)
	apply_safe_area_layout(ui)
	setup_cultivation_visual_auto_center(ui)

	if ui.get_viewport() and not ui.get_viewport().size_changed.is_connected(ui._on_viewport_size_changed):
		ui.get_viewport().size_changed.connect(ui._on_viewport_size_changed)


func setup_notification_badges(ui: Control) -> void:
	if not ui.notification_badge_state:
		ui.notification_badge_state = NOTIFICATION_BADGE_STATE_SCRIPT.new()
		ui.notification_badge_state.name = "NotificationBadgeState"
		ui.add_child(ui.notification_badge_state)
	if not ui.notification_badge_state.state_changed.is_connected(ui._on_notification_badge_state_changed):
		ui.notification_badge_state.state_changed.connect(ui._on_notification_badge_state_changed)

	ui._notification_badges.clear()
	_register_notification_badge(ui, "region_tab_badge", ui.tab_region, Vector2(12.0, 12.0), Vector2(-18.0, 6.0))
	_register_notification_badge(ui, "settings_tab_badge", ui.tab_settings, Vector2(12.0, 12.0), Vector2(-18.0, 6.0))
	_register_notification_badge(ui, "task_claimable", ui.xianwu_office_button, Vector2(30.0, 30.0), Vector2(-20.0, 4.0), true, "task_claimable_count")
	_register_notification_badge(ui, "mail_unread", ui.mailbox_button, Vector2(30.0, 30.0), Vector2(-20.0, 4.0), true, "mail_unread_count")
	ui._apply_notification_badge_state(ui.notification_badge_state.get_state())


func setup_bottom_tab_layout(ui: Control) -> void:
	if not ui.tab_bar:
		return
	var tab_bar_height: float = max(62.0, ui.tab_bar.custom_minimum_size.y)
	BOTTOM_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(ui.tab_bar, {
		"bar_height": tab_bar_height,
		"font_size": 23,
		"text_raise": 20.0,
		"line_position": "top",
		"line_width": 2,
		"selected_line_width": 3,
		"normal_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"hover_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"pressed_bg": Color(242.0 / 255.0, 229.0 / 255.0, 204.0 / 255.0, 1.0),
		"selected_bg": Color(0.95, 0.92, 0.85, 1.0),
		"line_color": Color(0.52, 0.49, 0.45, 1.0),
		"selected_line_color": Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0),
		"font_color": Color(0.35, 0.32, 0.28, 1.0),
		"selected_font_color": Color(222.0 / 255.0, 180.0 / 255.0, 53.0 / 255.0, 1.0)
	})
	if ui.bottom_spacer:
		ui.bottom_spacer.custom_minimum_size.y = 8.0


func setup_neishi_sub_tab_layout(ui: Control) -> void:
	if not ui.neishi_tab_bar:
		return
	TOP_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(ui.neishi_tab_bar, {
		"bar_height": 38.0,
		"font_size": 20,
		"separation": 0,
		"button_corner_radius": 12,
		"shell_inset_x": 18.0,
		"shell_inset_y": 9.0,
		"shell_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"shell_border_color": Color(0.86, 0.78, 0.63, 0.45),
		"shell_corner_radius": 20,
		"normal_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"hover_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"pressed_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"selected_bg": Color(188.0 / 255.0, 144.0 / 255.0, 48.0 / 255.0, 1.0),
		"font_color": Color(0.33, 0.28, 0.22, 1.0),
		"selected_font_color": Color(0.98, 0.96, 0.92, 1.0)
	})


func setup_log_filter_tabs(ui: Control) -> void:
	if not ui.log_filter_tab_bar:
		return
	TOP_TAB_BAR_STYLE_TEMPLATE.apply_to_bar(ui.log_filter_tab_bar, {
		"bar_height": 36.0,
		"font_size": 18,
		"button_corner_radius": 10,
		"shell_inset_x": 14.0,
		"shell_inset_y": 10.0,
		"shell_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"shell_border_color": Color(0.86, 0.78, 0.63, 0.35),
		"shell_corner_radius": 18,
		"normal_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"hover_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"pressed_bg": Color(243.0 / 255.0, 229.0 / 255.0, 203.0 / 255.0, 1.0),
		"selected_bg": Color(188.0 / 255.0, 144.0 / 255.0, 48.0 / 255.0, 1.0),
		"font_color": Color(0.33, 0.28, 0.22, 1.0),
		"selected_font_color": Color(0.98, 0.96, 0.92, 1.0)
	})


func on_viewport_size_changed(ui: Control) -> void:
	apply_safe_area_layout(ui)
	ui.call_deferred("_reposition_cultivation_visual_between_panels")


func apply_safe_area_layout(ui: Control) -> void:
	if not ui.content_frame:
		return
	var viewport_rect: Rect2 = ui.get_viewport().get_visible_rect()
	var safe_rect: Rect2 = SAFE_AREA_HELPER.get_safe_inner_rect(ui)
	ui.content_frame.scale = Vector2.ONE
	ui.content_frame.position = safe_rect.position
	ui.content_frame.size = safe_rect.size
	_update_safe_fill_frames(ui, viewport_rect.size, safe_rect)
	ui.call_deferred("_reposition_cultivation_visual_between_panels")


func setup_cultivation_visual_auto_center(ui: Control) -> void:
	if ui.cultivation_container and not ui.cultivation_container.resized.is_connected(ui._on_cultivation_layout_changed):
		ui.cultivation_container.resized.connect(ui._on_cultivation_layout_changed)
	if ui.status_area_panel and not ui.status_area_panel.resized.is_connected(ui._on_cultivation_layout_changed):
		ui.status_area_panel.resized.connect(ui._on_cultivation_layout_changed)
	if ui.breakthrough_panel_container and not ui.breakthrough_panel_container.resized.is_connected(ui._on_cultivation_layout_changed):
		ui.breakthrough_panel_container.resized.connect(ui._on_cultivation_layout_changed)
	ui.call_deferred("_reposition_cultivation_visual_between_panels")


func on_cultivation_layout_changed(ui: Control) -> void:
	ui.call_deferred("_reposition_cultivation_visual_between_panels")


func reposition_cultivation_visual_between_panels(ui: Control) -> void:
	if not ui.cultivation_visual or not ui.cultivation_container or not ui.status_area_panel or not ui.breakthrough_panel_container:
		return
	if not ui.neishi_panel or not ui.neishi_panel.visible:
		return

	var top_edge: float = ui.status_area_panel.position.y + ui.status_area_panel.size.y
	var bottom_edge: float = ui.breakthrough_panel_container.position.y
	if bottom_edge <= top_edge:
		return

	var center_y: float = (top_edge + bottom_edge) * 0.5
	var new_x: float = (ui.cultivation_container.size.x - ui.cultivation_visual.size.x) * 0.5
	var new_y: float = center_y - ui.cultivation_visual.size.y * 0.5
	ui.cultivation_visual.position = Vector2(new_x, new_y)


func _register_notification_badge(ui: Control, key: String, target: Control, size: Vector2, top_right_offset: Vector2, show_count: bool = false, count_key: String = "") -> void:
	if not target:
		return
	var badge := Control.new()
	badge.name = "NotificationBadge_" + key
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = top_right_offset.x - size.x
	badge.offset_right = top_right_offset.x
	badge.offset_top = top_right_offset.y
	badge.offset_bottom = top_right_offset.y + size.y

	var badge_panel := Panel.new()
	badge_panel.name = "BadgePanel"
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.anchor_left = 0.0
	badge_panel.anchor_right = 1.0
	badge_panel.anchor_top = 0.0
	badge_panel.anchor_bottom = 1.0
	badge_panel.offset_left = 0.0
	badge_panel.offset_right = 0.0
	badge_panel.offset_top = 0.0
	badge_panel.offset_bottom = 0.0

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = BADGE_COLOR
	badge_style.border_color = BADGE_BORDER_COLOR
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(int(minf(size.x, size.y) * 0.5))
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge.add_child(badge_panel)

	var badge_info := {"root": badge, "show_count": show_count, "count_key": count_key}
	if show_count:
		var count_label := Label.new()
		count_label.name = "CountLabel"
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.anchor_left = 0.0
		count_label.anchor_right = 1.0
		count_label.anchor_top = 0.0
		count_label.anchor_bottom = 1.0
		count_label.offset_left = 0.0
		count_label.offset_right = 0.0
		count_label.offset_top = -1.0
		count_label.offset_bottom = 0.0
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 16)
		count_label.add_theme_color_override("font_color", BADGE_TEXT_COLOR)
		count_label.text = ""
		badge.add_child(count_label)
		badge_info["label"] = count_label

	target.add_child(badge)
	ui._notification_badges[key] = badge_info


func _setup_action_button_templates(ui: Control) -> void:
	if ui.cultivate_button:
		ACTION_BUTTON_TEMPLATE.apply_cultivation_yellow(ui.cultivate_button, ui.cultivate_button.custom_minimum_size, 20)
	if ui.breakthrough_button:
		ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(ui.breakthrough_button, ui.breakthrough_button.custom_minimum_size, 20)


func _setup_status_header_style(ui: Control) -> void:
	if not ui.status_header_row:
		return
	DISPLAY_PANEL_TEMPLATE.apply_to_row(ui.status_header_row, DISPLAY_PANEL_TEMPLATE.build_standard_header_config({"title_text": "属性面板"}))
	DISPLAY_PANEL_TEMPLATE.apply_content_layout([ui.status_health_left_pad, ui.status_spirit_left_pad], ui.status_separator_margin, ui.status_header_bottom_spacer)


func _setup_breakthrough_panel_style(ui: Control) -> void:
	if not ui.breakthrough_header_row:
		return
	DISPLAY_PANEL_TEMPLATE.apply_to_row(ui.breakthrough_header_row, DISPLAY_PANEL_TEMPLATE.build_standard_header_config({"title_text": "突破条件"}))
	DISPLAY_PANEL_TEMPLATE.apply_content_layout([], ui.breakthrough_materials_margin, ui.breakthrough_header_bottom_spacer)


func _setup_log_scroll_behavior(ui: Control) -> void:
	if not ui.log_text:
		return
	var v_scrollbar: VScrollBar = ui.log_text.get_v_scroll_bar()
	if not v_scrollbar:
		return
	v_scrollbar.modulate = Color(1, 1, 1, 0)
	v_scrollbar.self_modulate = Color(1, 1, 1, 0)
	v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_scrollbar.custom_minimum_size.x = 0.0


func _setup_settings_scroll_behavior(ui: Control) -> void:
	if not ui.settings_scroll:
		return
	var v_scrollbar: VScrollBar = ui.settings_scroll.get_v_scroll_bar()
	if v_scrollbar:
		v_scrollbar.modulate = Color(1, 1, 1, 0)
		v_scrollbar.self_modulate = Color(1, 1, 1, 0)
		v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_scrollbar.custom_minimum_size.x = 0.0
	if ui.rank_scroll:
		ui.rank_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		ui.rank_scroll.vertical_scroll_mode = 3
		var rank_v_scrollbar: VScrollBar = ui.rank_scroll.get_v_scroll_bar()
		if rank_v_scrollbar:
			rank_v_scrollbar.modulate = Color(1, 1, 1, 0)
			rank_v_scrollbar.self_modulate = Color(1, 1, 1, 0)
			rank_v_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_v_scrollbar.custom_minimum_size.x = 0.0
		var rank_h_scrollbar: HScrollBar = ui.rank_scroll.get_h_scroll_bar()
		if rank_h_scrollbar:
			rank_h_scrollbar.modulate = Color(1, 1, 1, 0)
			rank_h_scrollbar.self_modulate = Color(1, 1, 1, 0)
			rank_h_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_h_scrollbar.custom_minimum_size.y = 0.0


func _update_safe_fill_frames(ui: Control, viewport_size: Vector2, safe_rect: Rect2) -> void:
	if ui.safe_top:
		ui.safe_top.position = Vector2.ZERO
		ui.safe_top.size = Vector2(viewport_size.x, max(0.0, safe_rect.position.y))
	if ui.safe_top_fill:
		ui.safe_top_fill.color = Color(0, 0, 0, 1)
	if ui.safe_bottom:
		ui.safe_bottom.position = Vector2(0.0, safe_rect.end.y)
		ui.safe_bottom.size = Vector2(viewport_size.x, max(0.0, viewport_size.y - safe_rect.end.y))
	if ui.safe_bottom_fill:
		ui.safe_bottom_fill.color = Color(0, 0, 0, 1)
