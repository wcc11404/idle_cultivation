extends Control

const FIGURE_IDLE_TEXTURE := preload("res://assets/cultivation/cultivation_figure.png")
const FIGURE_ACTIVE_TEXTURE := preload("res://assets/cultivation/cultivation_figure_particles.png")
const UIFontProvider = preload("res://scripts/ui/common/UIFontProvider.gd")
const ActionButtonTemplate = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const PopupStyleTemplate = preload("res://scripts/ui/common/PopupStyleTemplate.gd")
const BottomTabBarStyleTemplate = preload("res://scripts/ui/common/BottomTabBarStyleTemplate.gd")
const UIFeedbackManager = preload("res://scripts/ui/common/UIFeedbackManager.gd")

const COLOR_BG := Color(0.95, 0.90, 0.80, 1.0)
const COLOR_PANEL := Color(0.98, 0.94, 0.84, 0.96)
const COLOR_PANEL_ALT := Color(0.93, 0.86, 0.72, 0.92)
const COLOR_BORDER := Color(0.71, 0.64, 0.51, 0.95)
const COLOR_TEXT := Color(0.20, 0.17, 0.13, 1.0)
const COLOR_MUTED := Color(0.47, 0.40, 0.31, 1.0)
const COLOR_GOLD := Color(0.82, 0.62, 0.18, 1.0)

var _popup_overlay: ColorRect = null
var _popup_panel: Control = null
var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _selected_tab_index := 0
var _cultivation_active := false
var _figure_texture: TextureRect = null
var _figure_shell: Control = null
var _cultivation_status: Label = null
var _spirit_label: Label = null
var _spirit_energy := 1280

func _ready() -> void:
	UIFontProvider.apply_to_root(self)
	_build_scene()
	_select_tab(0, false)
	_update_cultivation_visual(false)

func _build_scene() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.name = "Background"
	background.color = COLOR_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "PageMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "DemoScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.name = "Content"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	scroll.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_button_demo_card())
	root.add_child(_build_popup_demo_card())
	root.add_child(_build_tab_demo_card())
	root.add_child(_build_cultivation_demo_card())

	_build_popup_layer()

func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Header"
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, COLOR_BORDER, 18, 2))
	panel.custom_minimum_size = Vector2(0, 92)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "P0 互动体验 Debug Demo"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "独立场景：按钮轻弹、弹窗开关、Tab 切换、内视修炼状态动效。底部一级 Tab 不做缩放；修炼粒子本轮暂不演示。"
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	vbox.add_child(desc)
	return panel

func _build_button_demo_card() -> Control:
	var card := _card("通用按钮反馈", "普通主按钮会轻微按下回弹；导航类按钮只演示选中态，不做缩放。")
	var box := card.get_node("Margin/Body") as VBoxContainer

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)

	var primary := _button("开始修炼", ActionButtonTemplate.PRESET_CULTIVATION_YELLOW, Vector2(0, 48))
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_button_tap_feedback(primary)
	row.add_child(primary)

	var secondary := _button("进入炼丹坊", ActionButtonTemplate.PRESET_ALCHEMY_GREEN, Vector2(0, 48))
	secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_button_tap_feedback(secondary)
	row.add_child(secondary)

	var disabled := _button("尚未解锁", ActionButtonTemplate.PRESET_LIGHT_NEUTRAL, Vector2(0, 48))
	disabled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disabled.disabled = true
	_attach_button_tap_feedback(disabled)
	row.add_child(disabled)

	var hint := Label.new()
	hint.text = "验收点：点击主按钮时有即时确认，但幅度轻，不抢戏；禁用按钮没有动效。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(hint)
	return card

func _build_popup_demo_card() -> Control:
	var card := _card("通用弹窗反馈", "遮罩淡入，弹窗主体轻微放大进入；点击暗区关闭，前景弹窗不穿透。")
	var box := card.get_node("Margin/Body") as VBoxContainer

	var open_button := _button("打开示例弹窗", ActionButtonTemplate.PRESET_PROFILE_BLUE, Vector2(220, 48))
	_attach_button_tap_feedback(open_button)
	open_button.pressed.connect(_open_popup_demo)
	box.add_child(open_button)

	var hint := Label.new()
	hint.text = "验收点：打开/关闭不硬切；点击弹窗内部不会关闭，点击外部暗区才关闭。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(hint)
	return card

func _build_tab_demo_card() -> Control:
	var card := _card("Tab 切换反馈", "复用正式底部 Tab 样式模板：不缩放，只做选中态与内容淡入/轻移。")
	var box := card.get_node("Margin/Body") as VBoxContainer

	var tab_row := HBoxContainer.new()
	tab_row.name = "TemplateTabBar"
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(tab_row)

	for label in ["内视", "储纳", "术法", "地区", "历练"]:
		var index := _tab_buttons.size()
		var button := Button.new()
		button.text = label
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			_select_tab(index, true)
		)
		_tab_buttons.append(button)
		tab_row.add_child(button)
	BottomTabBarStyleTemplate.apply_to_bar(tab_row, {
		"bar_height": 58.0,
		"font_size": 18,
		"line_position": "top",
		"text_raise": 2.0
	})

	var page_holder := PanelContainer.new()
	page_holder.name = "TabPageHolder"
	page_holder.custom_minimum_size = Vector2(0, 112)
	page_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_holder.add_theme_stylebox_override("panel", _style(Color(1.0, 0.96, 0.87, 0.88), Color(0.83, 0.75, 0.60, 0.8), 14, 1))
	box.add_child(page_holder)

	var page_margin := MarginContainer.new()
	page_margin.add_theme_constant_override("margin_left", 18)
	page_margin.add_theme_constant_override("margin_top", 14)
	page_margin.add_theme_constant_override("margin_right", 18)
	page_margin.add_theme_constant_override("margin_bottom", 14)
	page_holder.add_child(page_margin)

	var stack := Control.new()
	stack.name = "TabPageStack"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(stack)

	_tab_pages.append(_build_tab_page("内视页", "页面淡入并轻微上移归位，适合主 Tab 切换。"))
	_tab_pages.append(_build_tab_page("储纳页", "真实实现时数据刷新不等待动画完成。"))
	_tab_pages.append(_build_tab_page("术法页", "切换反馈保持轻量，避免频繁操作时拖慢手感。"))
	_tab_pages.append(_build_tab_page("地区页", "正式样式来自 BottomTabBarStyleTemplate，选中态更接近游戏底栏。"))
	_tab_pages.append(_build_tab_page("历练页", "导航按钮不做点击缩放，只做状态变化与内容切换反馈。"))
	for page in _tab_pages:
		stack.add_child(page)
	return card

func _build_cultivation_demo_card() -> Control:
	var card := _card("内视修炼页强化", "演示呼吸缩放与开始/停止柔光扩散；不演示粒子，避免未定稿素材违和。")
	var box := card.get_node("Margin/Body") as VBoxContainer

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 250)
	box.add_child(center)

	_figure_shell = Control.new()
	_figure_shell.custom_minimum_size = Vector2(210, 230)
	center.add_child(_figure_shell)

	_figure_texture = TextureRect.new()
	_figure_texture.name = "CultivationFigure"
	_figure_texture.texture = FIGURE_IDLE_TEXTURE
	_figure_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_figure_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_figure_texture.custom_minimum_size = Vector2(210, 230)
	_figure_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	_figure_texture.gui_input.connect(_on_figure_gui_input)
	_figure_shell.add_child(_figure_texture)

	_cultivation_status = Label.new()
	_cultivation_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cultivation_status.add_theme_font_size_override("font_size", 22)
	_cultivation_status.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(_cultivation_status)

	_spirit_label = Label.new()
	_spirit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spirit_label.add_theme_font_size_override("font_size", 20)
	_spirit_label.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(_spirit_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)

	var toggle := _button("切换修炼状态", ActionButtonTemplate.PRESET_CULTIVATION_YELLOW, Vector2(0, 46))
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_button_tap_feedback(toggle)
	toggle.pressed.connect(_toggle_cultivation)
	row.add_child(toggle)

	var milestone := _button("低频数值反馈", ActionButtonTemplate.PRESET_LIGHT_NEUTRAL_SELECTED, Vector2(0, 46))
	milestone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach_button_tap_feedback(milestone)
	milestone.pressed.connect(_play_spirit_milestone_feedback)
	row.add_child(milestone)
	return card

func _build_popup_layer() -> void:
	_popup_overlay = PopupStyleTemplate.create_overlay(self, _close_popup_demo, 0.58)
	_popup_overlay.name = "InteractionDemoOverlay"
	_popup_overlay.modulate.a = 0.0
	add_child(_popup_overlay)

	_popup_panel = Control.new()
	_popup_panel.name = "DemoPopup"
	_popup_panel.visible = false
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_panel.custom_minimum_size = PopupStyleTemplate.DECORATED_POPUP_MIN_SIZE
	_popup_overlay.add_child(_popup_panel)

	var margin := PopupStyleTemplate.build_decorated_popup(_popup_panel, {
		"content_name": "DemoPopupContent"
	})

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := PopupStyleTemplate.create_title_label("示例弹窗")
	box.add_child(title)
	box.add_child(PopupStyleTemplate.create_title_separator())

	var body := Label.new()
	body.text = "这是 P0 弹窗动效示例。点击这块前景内容不会关闭弹窗，只有点击外部暗区才关闭。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(body)

	var close_button := _button("关闭", ActionButtonTemplate.PRESET_CULTIVATION_YELLOW, Vector2(160, 46))
	_attach_button_tap_feedback(close_button)
	close_button.pressed.connect(_close_popup_demo)
	box.add_child(close_button)

func _card(title_text: String, desc_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(COLOR_PANEL, COLOR_BORDER, 18, 2))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	body.add_child(title)

	var desc := Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	body.add_child(desc)
	return card

func _build_tab_page(title_text: String, body_text: String) -> Control:
	var page := VBoxContainer.new()
	page.visible = false
	page.modulate.a = 0.0
	page.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	page.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", COLOR_MUTED)
	page.add_child(body)
	return page

func _button(text: String, preset: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	ActionButtonTemplate.apply_to_button(button, preset, min_size, 18)
	return button

func _attach_button_tap_feedback(button: Button) -> void:
	UIFeedbackManager.bind_button_tap(button)

func _select_tab(index: int, animated: bool) -> void:
	if index < 0 or index >= _tab_pages.size():
		return
	_selected_tab_index = index
	for i in _tab_buttons.size():
		_tab_buttons[i].disabled = i == index
	for i in _tab_pages.size():
		var page := _tab_pages[i]
		if i == index:
			page.visible = true
			if animated:
				UIFeedbackManager.play_tab_content_in(page)
			else:
				page.modulate.a = 1.0
				page.position.y = 0.0
		else:
			page.visible = false

func _open_popup_demo() -> void:
	if not _popup_overlay or not _popup_panel:
		return
	_center_popup_panel()
	PopupStyleTemplate.play_open(_popup_overlay, _popup_panel)

func _close_popup_demo() -> void:
	if not _popup_overlay or not _popup_panel or not _popup_overlay.visible:
		return
	PopupStyleTemplate.play_close(_popup_overlay, _popup_panel, func() -> void:
		_popup_panel.visible = false
		_popup_overlay.visible = false
	)

func _center_popup_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var popup_size := _popup_panel.custom_minimum_size
	_popup_panel.position = (viewport_size - popup_size) * 0.5
	_popup_panel.size = popup_size

func _on_figure_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_toggle_cultivation()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			_toggle_cultivation()
			get_viewport().set_input_as_handled()

func _toggle_cultivation() -> void:
	_cultivation_active = not _cultivation_active
	_update_cultivation_visual(true)

func _update_cultivation_visual(animated: bool) -> void:
	if not _figure_texture:
		return
	_figure_texture.texture = FIGURE_ACTIVE_TEXTURE if _cultivation_active else FIGURE_IDLE_TEXTURE
	_cultivation_status.text = "修炼中：灵气缓缓入体" if _cultivation_active else "未修炼：点击小人或按钮开始"
	_spirit_label.text = "灵气：%d / 3000" % _spirit_energy
	if _cultivation_active:
		_start_breathing()
	else:
		_stop_breathing()

func _start_breathing() -> void:
	if not _figure_shell:
		return
	UIFeedbackManager.start_breathing(_figure_shell, "demo_cultivation", {
		"scale": 1.055,
		"half_duration": 0.9
	})

func _stop_breathing() -> void:
	if _figure_shell:
		UIFeedbackManager.stop_breathing(_figure_shell, "demo_cultivation")

func _play_spirit_milestone_feedback() -> void:
	_spirit_energy += 120
	_spirit_label.text = "灵气：%d / 3000" % _spirit_energy
	UIFeedbackManager.play_value_bump(_spirit_label, 1)

func _set_center_pivot(control: Control) -> void:
	if not control:
		return
	control.pivot_offset = control.size * 0.5

func _style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
