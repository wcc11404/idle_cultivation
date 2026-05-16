class_name ProfileEditPopup extends Panel

const POPUP_STYLE_TEMPLATE = preload("res://scripts/ui/common/PopupStyleTemplate.gd")
const ACTION_BUTTON_TEMPLATE = preload("res://scripts/ui/common/ActionButtonTemplate.gd")
const ACCOUNT_CONFIG_SCRIPT = preload("res://scripts/core/account/AccountConfig.gd")
const SAFE_AREA_HELPER = preload("res://scripts/ui/common/SafeAreaHelper.gd")

signal nickname_submit_requested(new_nickname: String)
signal avatar_submit_requested(avatar_id: String)
signal popup_closed

const COLOR_TEXT_DARK := Color(0.22, 0.2, 0.18, 1.0)
const COLOR_HINT := Color(0.36, 0.31, 0.25, 1.0)

const COLOR_AVATAR_BORDER_NORMAL := Color(0.713725, 0.639216, 0.513725, 1.0)
const COLOR_AVATAR_BORDER_SELECTED := Color(0.870588, 0.705882, 0.207843, 1.0)

var overlay_host: Control = null
var background: ColorRect = null

var nickname_input: LineEdit = null
var avatar_grid: GridContainer = null
var avatar_submit_button: Button = null

var _selected_avatar_id: String = ""
var _avatar_buttons: Dictionary = {}

func _init():
	name = "ProfileEditPopup"
	visible = false
	z_index = 1100
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(host: Control):
	overlay_host = host
	var outside_click_callback := func():
		if visible:
			hide_popup()
			popup_closed.emit()
	background = POPUP_STYLE_TEMPLATE.create_overlay(host, outside_click_callback, 0.58)
	background.name = "ProfileEditOverlay"
	overlay_host.add_child(background)
	_build_layout()
	_apply_styles()
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _build_layout():
	layout_mode = 1
	anchors_preset = 0
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2(120.0, 120.0)
	size = Vector2(520.0, 600.0)

	var margin = POPUP_STYLE_TEMPLATE.build_decorated_popup(self, {
		"content_name": "ProfileEditContent"
	})

	var vbox = VBoxContainer.new()
	vbox.name = "RootVBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = POPUP_STYLE_TEMPLATE.create_title_label("个人信息")
	vbox.add_child(title)
	vbox.add_child(POPUP_STYLE_TEMPLATE.create_title_separator())

	var nickname_title = _create_section_title("修改昵称")
	vbox.add_child(nickname_title)

	nickname_input = LineEdit.new()
	nickname_input.custom_minimum_size = Vector2(0, 44)
	nickname_input.placeholder_text = "输入新昵称（4-10位）"
	nickname_input.add_theme_font_size_override("font_size", 20)
	vbox.add_child(nickname_input)

	var nickname_hint = Label.new()
	nickname_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nickname_hint.text = "昵称非法情况：不能为空；长度需4-10位；不能包含空格；不能全是数字；不能包含非法字符或敏感词。"
	nickname_hint.add_theme_font_size_override("font_size", 16)
	nickname_hint.add_theme_color_override("font_color", COLOR_HINT)
	vbox.add_child(nickname_hint)

	var nickname_submit_button = Button.new()
	nickname_submit_button.text = "变更昵称"
	nickname_submit_button.custom_minimum_size = Vector2(0, 42)
	nickname_submit_button.add_theme_font_size_override("font_size", 20)
	nickname_submit_button.pressed.connect(func():
		nickname_submit_requested.emit(nickname_input.text.strip_edges())
	)
	vbox.add_child(nickname_submit_button)
	ACTION_BUTTON_TEMPLATE.apply_profile_blue(nickname_submit_button, nickname_submit_button.custom_minimum_size, 20)

	vbox.add_child(POPUP_STYLE_TEMPLATE.create_title_separator())

	var avatar_title = _create_section_title("选择头像")
	vbox.add_child(avatar_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	avatar_grid = GridContainer.new()
	avatar_grid.columns = 4
	avatar_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_grid.add_theme_constant_override("h_separation", 10)
	avatar_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(avatar_grid)

	_build_avatar_grid()

	avatar_submit_button = Button.new()
	avatar_submit_button.text = "变更头像"
	avatar_submit_button.custom_minimum_size = Vector2(0, 42)
	avatar_submit_button.add_theme_font_size_override("font_size", 20)
	avatar_submit_button.pressed.connect(func():
		avatar_submit_requested.emit(_selected_avatar_id)
	)
	vbox.add_child(avatar_submit_button)
	ACTION_BUTTON_TEMPLATE.apply_profile_blue(avatar_submit_button, avatar_submit_button.custom_minimum_size, 20)

func _build_avatar_grid():
	_avatar_buttons.clear()
	for child in avatar_grid.get_children():
		child.queue_free()

	var avatar_ids: Array = ACCOUNT_CONFIG_SCRIPT.get_available_avatar_ids()
	avatar_ids.sort()
	for avatar_id_variant in avatar_ids:
		var avatar_id = str(avatar_id_variant)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(104, 96)
		btn.text = ""
		btn.add_theme_stylebox_override("normal", _make_avatar_style(false))
		btn.add_theme_stylebox_override("hover", _make_avatar_style(false, true))
		btn.add_theme_stylebox_override("pressed", _make_avatar_style(true))
		btn.pressed.connect(func():
			_selected_avatar_id = avatar_id
			_refresh_avatar_selection()
		)

		var avatar_texture = TextureRect.new()
		avatar_texture.layout_mode = 1
		avatar_texture.anchors_preset = 8
		avatar_texture.anchor_left = 0.5
		avatar_texture.anchor_top = 0.5
		avatar_texture.anchor_right = 0.5
		avatar_texture.anchor_bottom = 0.5
		avatar_texture.offset_left = -28.0
		avatar_texture.offset_top = -28.0
		avatar_texture.offset_right = 28.0
		avatar_texture.offset_bottom = 28.0
		avatar_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex = load(ACCOUNT_CONFIG_SCRIPT.get_avatar_path(avatar_id))
		if tex:
			avatar_texture.texture = tex
		btn.add_child(avatar_texture)

		avatar_grid.add_child(btn)
		_avatar_buttons[avatar_id] = btn

func _make_avatar_style(selected: bool, hover: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.94902, 0.898039, 0.8, 1.0) if not hover else Color(0.972549, 0.92549, 0.831373, 1.0)
	style.border_color = COLOR_AVATAR_BORDER_SELECTED if selected else COLOR_AVATAR_BORDER_NORMAL
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(8)
	return style

func _refresh_avatar_selection():
	for avatar_id in _avatar_buttons.keys():
		var btn = _avatar_buttons[avatar_id] as Button
		if not btn:
			continue
		var is_selected = (str(avatar_id) == _selected_avatar_id)
		btn.add_theme_stylebox_override("normal", _make_avatar_style(is_selected))
		btn.add_theme_stylebox_override("hover", _make_avatar_style(is_selected, true))
		btn.add_theme_stylebox_override("pressed", _make_avatar_style(true))

func _apply_styles():
	pass

func show_popup(current_nickname: String, current_avatar_id: String):
	if not _avatar_buttons.has(current_avatar_id):
		current_avatar_id = ACCOUNT_CONFIG_SCRIPT.get_default_avatar_id()
	_selected_avatar_id = current_avatar_id
	nickname_input.text = current_nickname
	_refresh_avatar_selection()
	if background:
		background.z_index = z_index - 1
	visible = true
	_update_layout()
	if background:
		POPUP_STYLE_TEMPLATE.play_open(background, self)
	call_deferred("_update_layout")

func hide_popup():
	if background:
		POPUP_STYLE_TEMPLATE.play_close(background, self, func() -> void:
			visible = false
			background.visible = false
		)
	else:
		visible = false

func get_nickname_text() -> String:
	if not nickname_input:
		return ""
	return nickname_input.text.strip_edges()

func get_selected_avatar_id() -> String:
	return _selected_avatar_id

func _on_viewport_size_changed():
	if visible:
		_update_layout()

func _update_layout():
	var safe_rect := SAFE_AREA_HELPER.get_safe_inner_rect(self)
	var viewport_size = safe_rect.size
	var desired_w = clamp(viewport_size.x * 0.74, POPUP_STYLE_TEMPLATE.DECORATED_POPUP_MIN_SIZE.x, 620.0)
	var desired_h = clamp(viewport_size.y * 0.82, POPUP_STYLE_TEMPLATE.DECORATED_POPUP_MIN_SIZE.y, 760.0)
	var popup_pos := safe_rect.position + (safe_rect.size - Vector2(desired_w, desired_h)) * 0.5
	position = popup_pos
	size = Vector2(desired_w, desired_h)

func _create_section_title(text: String) -> Label:
	var title := Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	return title
