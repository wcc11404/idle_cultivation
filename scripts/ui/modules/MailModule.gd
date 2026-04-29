class_name MailModule extends Node

const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const POPUP_STYLE_TEMPLATE = preload("res://scripts/ui/common/PopupStyleTemplate.gd")

signal log_message(message: String)
signal back_requested
signal mail_state_changed(unread_count: int, total_count: int)

var game_ui: Node = null
var api: Node = null
var item_data_ref: Node = null

var panel: Control = null
var back_button: Button = null
var title_label: Label = null
var count_label: Label = null
var clear_button: Button = null
var list_area: Control = null
var scroll: ScrollContainer = null
var list_box: VBoxContainer = null
var empty_hint_label: Label = null
var empty_hint_container: CenterContainer = null
var _active_popup_overlay: ColorRect = null
var _mail_detail_overlay: ColorRect = null

var _mails: Array = []
var _touch_states := {}
const TOUCH_SLOP := 16.0

func initialize(ui: Node, game_api: Node, item_data):
	game_ui = ui
	api = game_api
	item_data_ref = item_data
	_build_ui_if_needed()
	_bind_signals()

func _build_ui_if_needed():
	if panel:
		return
	var content_panel: Control = game_ui.get_node_or_null("ContentFrame/VBoxContainer/ContentPanel")
	if not content_panel:
		return

	panel = Control.new()
	panel.name = "MailPanel"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_panel.add_child(panel)

	var outer_margin = MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 10)
	outer_margin.add_theme_constant_override("margin_top", 0)
	outer_margin.add_theme_constant_override("margin_right", 10)
	outer_margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(outer_margin)

	var root_v = VBoxContainer.new()
	root_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 0)
	outer_margin.add_child(root_v)

	var title_bar = HBoxContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 58)
	title_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_child(title_bar)
	back_button = Button.new()
	back_button.text = "< 返回"
	back_button.custom_minimum_size = Vector2(96, 40)
	ACTION_BUTTON_TEMPLATE.apply_light_neutral(back_button, back_button.custom_minimum_size, 20)
	title_bar.add_child(back_button)
	title_label = Label.new()
	title_label.text = "邮箱"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	title_label.add_theme_font_size_override("font_size", 28)
	title_bar.add_child(title_label)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(96, 0)
	title_bar.add_child(spacer)

	var hsep = HSeparator.new()
	hsep.custom_minimum_size = Vector2(0, 10)
	root_v.add_child(hsep)

	var top_row = HBoxContainer.new()
	top_row.custom_minimum_size = Vector2(0, 44)
	root_v.add_child(top_row)
	count_label = Label.new()
	count_label.text = "邮件 0 / 100"
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	count_label.add_theme_font_size_override("font_size", 18)
	top_row.add_child(count_label)
	clear_button = Button.new()
	clear_button.text = "一键删除"
	clear_button.custom_minimum_size = Vector2(120, 44)
	ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(clear_button, clear_button.custom_minimum_size, 16)
	top_row.add_child(clear_button)

	list_area = Control.new()
	list_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(list_area)

	scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = false
	list_area.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 8)
	list_box.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(list_box)

	empty_hint_container = CenterContainer.new()
	empty_hint_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	empty_hint_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_hint_container.visible = false
	list_area.add_child(empty_hint_container)

	empty_hint_label = Label.new()
	empty_hint_label.text = "邮箱是空的"
	empty_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_hint_label.modulate = Color(0.2, 0.2, 0.2, 0.45)
	empty_hint_label.add_theme_font_size_override("font_size", 24)
	empty_hint_container.add_child(empty_hint_label)

	_hide_scrollbars(scroll)

func _hide_scrollbars(target_scroll: ScrollContainer):
	if not target_scroll:
		return
	var v = target_scroll.get_v_scroll_bar()
	if v:
		v.modulate = Color(1, 1, 1, 0)
		v.self_modulate = Color(1, 1, 1, 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.custom_minimum_size.x = 0
	var h = target_scroll.get_h_scroll_bar()
	if h:
		h.modulate = Color(1, 1, 1, 0)
		h.self_modulate = Color(1, 1, 1, 0)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.custom_minimum_size.y = 0

func _bind_signals():
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if clear_button and not clear_button.pressed.is_connected(_on_clear_pressed):
		clear_button.pressed.connect(_on_clear_pressed)

func show_tab():
	if not panel:
		return
	panel.visible = true
	await refresh_mail_list()

func hide_tab():
	if panel:
		panel.visible = false

func refresh_indicator_only():
	if not api:
		return
	var result = await api.mail_list()
	if result.get("success", false):
		_emit_mail_state_changed(result)

func refresh_mail_list():
	if not api:
		return
	var result = await api.mail_list()
	if not result.get("success", false):
		log_message.emit("邮箱列表获取失败")
		return
	_mails = result.get("mails", [])
	_render_list(int(result.get("count", 0)), int(result.get("capacity", 100)))
	_emit_mail_state_changed(result)

func _render_list(count: int, capacity: int):
	if count_label:
		count_label.text = "邮件 %d / %d" % [count, capacity]
	for c in list_box.get_children():
		c.queue_free()
	var is_empty := _mails.is_empty()
	list_box.visible = not is_empty
	if empty_hint_container:
		empty_hint_container.visible = is_empty
	if clear_button:
		clear_button.disabled = is_empty

	for mail in _mails:
		var card = _build_mail_card(mail)
		list_box.add_child(card)

func _build_mail_card(mail: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 122)
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)

	var title = Label.new()
	var unread = not bool(mail.get("is_read", false))
	title.text = ("[未读] " if unread else "[已读] ") + str(mail.get("title", ""))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	left.add_child(title)

	var preview = Label.new()
	preview.text = str(mail.get("preview", ""))
	preview.add_theme_font_size_override("font_size", 16)
	preview.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(preview)

	var time_label = Label.new()
	time_label.text = _format_time(int(mail.get("created_at", 0)))
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	left.add_child(time_label)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(92, 92)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var attach = mail.get("first_attachment", null)
	if attach is Dictionary:
		var box = PanelContainer.new()
		box.custom_minimum_size = Vector2(82, 82)
		var box_style := StyleBoxFlat.new()
		box_style.bg_color = Color(0.95, 0.90, 0.80, 1.0)
		box_style.border_color = Color(0.72, 0.64, 0.51, 1.0)
		box_style.set_corner_radius_all(6)
		box_style.set_border_width_all(1)
		box.add_theme_stylebox_override("panel", box_style)
		right.add_child(box)
		var txt = Label.new()
		var item_id := str((attach as Dictionary).get("item_id", ""))
		var count := int((attach as Dictionary).get("count", 0))
		txt.text = _item_name(item_id) + ("\nx%s" % _format_item_count(count) if count > 0 else "")
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.add_theme_font_size_override("font_size", 14)
		txt.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.add_child(txt)
		if bool(mail.get("is_claimed", false)):
			box.modulate = Color(0.7, 0.7, 0.7, 1)
			var claimed = Label.new()
			claimed.text = "已领"
			claimed.add_theme_font_size_override("font_size", 16)
			claimed.modulate = Color(0.8, 0.25, 0.25, 1)
			claimed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			right.add_child(claimed)

	var mail_id = str(mail.get("mail_id", ""))
	_touch_states[mail_id] = {"active": false, "start_pos": Vector2.ZERO, "touch_id": -1, "moved": false}
	card.gui_input.connect(_on_card_input.bind(mail_id))
	_apply_default_panel_style(card)
	return card

func _on_card_input(event: InputEvent, mail_id: String):
	var state = _touch_states.get(mail_id, {"active": false, "start_pos": Vector2.ZERO, "touch_id": -1, "moved": false})
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			state["active"] = true
			state["start_pos"] = mb.position
			state["moved"] = false
		elif mb.button_index == MOUSE_BUTTON_LEFT and (not mb.pressed):
			if bool(state.get("active", false)) and not bool(state.get("moved", false)):
				_open_mail_detail(mail_id)
			state["active"] = false
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			state["active"] = true
			state["touch_id"] = st.index
			state["start_pos"] = st.position
			state["moved"] = false
		else:
			if bool(state.get("active", false)) and int(state.get("touch_id", -1)) == st.index and not bool(state.get("moved", false)):
				_open_mail_detail(mail_id)
			state["active"] = false
			state["touch_id"] = -1
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if bool(state.get("active", false)) and int(state.get("touch_id", -1)) == sd.index:
			var distance = sd.position.distance_to(state.get("start_pos", Vector2.ZERO))
			if distance > TOUCH_SLOP:
				state["moved"] = true
	_touch_states[mail_id] = state

func _on_back_pressed():
	back_requested.emit()

func _on_clear_pressed():
	_show_confirm_popup(
		"一键删除确认",
		"将删除所有已读且非未领取状态的邮件，是否继续？",
		func():
			var result = await api.mail_delete("read_and_claimed", [])
			if not result.get("success", false):
				log_message.emit("一键删除失败")
			else:
				var deleted_count := int(result.get("deleted_count", 0))
				if deleted_count > 0:
					log_message.emit("一键删除成功，已删除%d封邮件" % deleted_count)
				else:
					log_message.emit("无可删除邮件（仅删除已读且非未领取状态的邮件）")
			await refresh_mail_list()
	)

func _open_mail_detail(mail_id: String):
	var result = await api.mail_detail(mail_id)
	if not result.get("success", false):
		log_message.emit("邮件详情获取失败")
		return
	var mail = result.get("mail", {})
	_show_mail_popup(mail)
	await refresh_mail_list()

func _show_mail_popup(mail: Dictionary):
	_close_popup_overlay()
	var overlay := ColorRect.new()
	overlay.name = "MailPopupOverlay"
	overlay.color = Color(0, 0, 0, 0.25)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(overlay)
	_active_popup_overlay = overlay
	_mail_detail_overlay = overlay

	var popup = PanelContainer.new()
	var viewport_size := panel.get_viewport_rect().size
	var popup_width := minf(560.0, maxf(420.0, viewport_size.x - 40.0))
	var popup_height := minf(760.0, maxf(520.0, viewport_size.y - 80.0))
	popup.custom_minimum_size = Vector2(popup_width, popup_height)
	popup.anchor_left = 0.5
	popup.anchor_right = 0.5
	popup.anchor_top = 0.5
	popup.anchor_bottom = 0.5
	popup.offset_left = -popup_width * 0.5
	popup.offset_right = popup_width * 0.5
	popup.offset_top = -popup_height * 0.5
	popup.offset_bottom = popup_height * 0.5
	overlay.add_child(popup)
	_apply_default_panel_style(popup)
	popup.gui_input.connect(func(_event: InputEvent): pass)

	var popup_margin := MarginContainer.new()
	popup_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_margin.add_theme_constant_override("margin_left", 14)
	popup_margin.add_theme_constant_override("margin_top", 14)
	popup_margin.add_theme_constant_override("margin_right", 14)
	popup_margin.add_theme_constant_override("margin_bottom", 14)
	popup.add_child(popup_margin)

	var root = VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	popup_margin.add_child(root)

	var title = Label.new()
	title.text = str(mail.get("title", "邮件"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	root.add_child(title)
	root.add_child(HSeparator.new())

	var time_label = Label.new()
	time_label.text = _format_time(int(mail.get("created_at", 0)))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	root.add_child(time_label)

	var content_scroll = ScrollContainer.new()
	content_scroll.custom_minimum_size = Vector2(0, 170)
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(content_scroll)
	_hide_scrollbars(content_scroll)

	var content_label = Label.new()
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_label.add_theme_font_size_override("font_size", 20)
	content_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content_label.text = str(mail.get("content", ""))
	content_label.custom_minimum_size = Vector2(0, 160)
	content_scroll.add_child(content_label)

	var attachments: Array = mail.get("attachments", [])
	var has_attachment = attachments.size() > 0
	if has_attachment:
		var attach_title = Label.new()
		attach_title.text = "附件"
		attach_title.add_theme_font_size_override("font_size", 24)
		attach_title.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
		root.add_child(attach_title)

		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		root.add_child(grid)

		for attach in attachments:
			var slot = PanelContainer.new()
			slot.custom_minimum_size = Vector2(120, 82)
			var slot_style := StyleBoxFlat.new()
			slot_style.bg_color = Color(0.95, 0.90, 0.8, 1)
			slot_style.border_color = Color(0.72, 0.64, 0.51, 1)
			slot_style.set_border_width_all(1)
			slot_style.set_corner_radius_all(6)
			slot.add_theme_stylebox_override("panel", slot_style)
			grid.add_child(slot)
			var slot_label = Label.new()
			var attach_dict := attach as Dictionary
			var item_id := str(attach_dict.get("item_id", ""))
			var count := int(attach_dict.get("count", 0))
			slot_label.text = "%s\nx%s" % [_item_name(item_id), _format_item_count(count)]
			slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot_label.add_theme_font_size_override("font_size", 16)
			slot_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
			slot_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			slot.add_child(slot_label)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	root.add_child(btn_row)

	var claim_btn = Button.new()
	claim_btn.text = "领取"
	claim_btn.custom_minimum_size = Vector2(170, 58)
	var is_claimed = bool(mail.get("is_claimed", false))
	claim_btn.visible = has_attachment
	claim_btn.disabled = is_claimed
	if claim_btn.disabled:
		claim_btn.text = "已领取"
	ACTION_BUTTON_TEMPLATE.apply_alchemy_green(claim_btn, claim_btn.custom_minimum_size, 24)
	btn_row.add_child(claim_btn)

	var del_btn = Button.new()
	del_btn.text = "删除"
	del_btn.custom_minimum_size = Vector2(170, 58)
	ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(del_btn, del_btn.custom_minimum_size, 24)
	btn_row.add_child(del_btn)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(170, 58)
	ACTION_BUTTON_TEMPLATE.apply_spell_view_brown(close_btn, close_btn.custom_minimum_size, 24)
	btn_row.add_child(close_btn)

	claim_btn.pressed.connect(func():
		_close_popup_overlay()
		await _claim_mail(str(mail.get("mail_id", "")))
	)
	del_btn.pressed.connect(func():
		var delete_ok := await _delete_mail(str(mail.get("mail_id", "")))
		if delete_ok:
			_close_mail_detail_overlay()
	)
	close_btn.pressed.connect(func():
		_close_popup_overlay()
	)
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				var rect := Rect2(popup.global_position, popup.size)
				if not rect.has_point(mb.global_position):
					_close_popup_overlay()
	)

func _claim_mail(mail_id: String):
	var result = await api.mail_claim(mail_id)
	if result.get("success", false):
		log_message.emit("邮件附件领取成功")
		if game_ui and game_ui.has_method("refresh_all_player_data"):
			await game_ui.refresh_all_player_data()
	else:
		log_message.emit("邮件附件领取失败")
	await refresh_mail_list()

func _delete_mail(mail_id: String) -> bool:
	var result = await api.mail_delete("manual", [mail_id])
	if result.get("success", false):
		log_message.emit("邮件已删除")
		await refresh_mail_list()
		return true
	else:
		var reason_code := str(result.get("reason_code", ""))
		if reason_code == "MAIL_DELETE_FORBIDDEN_UNREAD_UNCLAIMED":
			log_message.emit("有未领取的附件，不能删除该邮件")
		else:
			log_message.emit("删除失败")
		await refresh_mail_list()
		return false

func _format_time(ts: int) -> String:
	if ts <= 0:
		return "--"
	var d = Time.get_datetime_dict_from_unix_time(ts)
	return "%04d-%02d-%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]

func _item_name(item_id: String) -> String:
	if not item_data_ref:
		return item_id
	if item_data_ref.has_method("get_item_name"):
		return str(item_data_ref.get_item_name(item_id))
	var data = item_data_ref.get_item_data(item_id) if item_data_ref.has_method("get_item_data") else {}
	if data is Dictionary:
		return str((data as Dictionary).get("name", item_id))
	return item_id


func _emit_mail_state_changed(result: Dictionary) -> void:
	mail_state_changed.emit(int(result.get("unread_count", 0)), int(result.get("count", 0)))

func _close_popup_overlay():
	if _active_popup_overlay and is_instance_valid(_active_popup_overlay):
		_active_popup_overlay.queue_free()
	_active_popup_overlay = null

func _close_mail_detail_overlay():
	if _mail_detail_overlay and is_instance_valid(_mail_detail_overlay):
		_mail_detail_overlay.queue_free()
	_mail_detail_overlay = null

func _show_confirm_popup(title: String, content: String, action: Callable, keep_current_overlay: bool = false):
	if not keep_current_overlay:
		_close_popup_overlay()
	var overlay := ColorRect.new()
	overlay.name = "MailConfirmOverlay"
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(overlay)
	_active_popup_overlay = overlay

	var popup_panel := Panel.new()
	popup_panel.name = "MailConfirmPanel"
	popup_panel.anchor_left = 0.5
	popup_panel.anchor_top = 0.5
	popup_panel.anchor_right = 0.5
	popup_panel.anchor_bottom = 0.5
	popup_panel.offset_left = -240
	popup_panel.offset_top = -110
	popup_panel.offset_right = 240
	popup_panel.offset_bottom = 110
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_panel.add_theme_stylebox_override("panel", POPUP_STYLE_TEMPLATE.build_panel_style({
		"bg_color": POPUP_STYLE_TEMPLATE.POPUP_BG_COLOR,
		"border_color": POPUP_STYLE_TEMPLATE.POPUP_BORDER_COLOR,
		"corner_radius": 12,
		"border_width": 2
	}))
	overlay.add_child(popup_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title_label_local := Label.new()
	title_label_local.text = title
	title_label_local.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label_local.add_theme_font_size_override("font_size", 26)
	title_label_local.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	root.add_child(title_label_local)

	var content_label_local := Label.new()
	content_label_local.text = content
	content_label_local.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label_local.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label_local.add_theme_font_size_override("font_size", 18)
	content_label_local.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	root.add_child(content_label_local)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	root.add_child(button_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "确认"
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	ACTION_BUTTON_TEMPLATE.apply_breakthrough_red(confirm_btn, confirm_btn.custom_minimum_size, 18)
	button_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(140, 44)
	ACTION_BUTTON_TEMPLATE.apply_light_neutral(cancel_btn, cancel_btn.custom_minimum_size, 18)
	button_row.add_child(cancel_btn)

	confirm_btn.pressed.connect(func():
		_close_popup_overlay()
		await action.call()
	)
	cancel_btn.pressed.connect(func():
		_close_popup_overlay()
	)
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				var rect := Rect2(popup_panel.global_position, popup_panel.size)
				if not rect.has_point(mb.global_position):
					_close_popup_overlay()
	)

func _format_item_count(count: int) -> String:
	return UIUtils.format_display_number_integer(float(count))

func _apply_default_panel_style(panel_node: PanelContainer):
	if not panel_node:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.89, 0.80, 1.0)
	style.border_color = Color(0.73, 0.66, 0.53, 1.0)
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	panel_node.add_theme_stylebox_override("panel", style)
