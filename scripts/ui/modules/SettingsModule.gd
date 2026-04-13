class_name SettingsModule extends Node

const RANK_BACK_FONT_SIZE := 20
const RANK_BACK_TEXT_COLOR := Color(0.25, 0.22, 0.18, 1.0)

signal save_requested
signal load_requested
signal log_message(message: String)

var game_ui: Node = null
var player: Node = null
var api: Node = null

var settings_panel: Control = null
var save_button: Button = null
var logout_button: Button = null
var nickname_input: LineEdit = null
var confirm_nickname_button: Button = null
var rank_button: Button = null
var rank_panel: Control = null
var rank_list: VBoxContainer = null
var back_button: Button = null

func _get_nickname_result_text(result: Dictionary, fallback: String = "昵称修改失败") -> String:
	var reason_code = str(result.get("reason_code", ""))
	match reason_code:
		"ACCOUNT_NICKNAME_CHANGE_SUCCEEDED":
			return "昵称修改成功"
		"ACCOUNT_NICKNAME_EMPTY":
			return "昵称不能为空"
		"ACCOUNT_NICKNAME_LENGTH_INVALID":
			return "昵称长度应在4-10位之间"
		"ACCOUNT_NICKNAME_CONTAINS_SPACE":
			return "昵称不能包含空格"
		"ACCOUNT_NICKNAME_INVALID_CHARACTER":
			return "昵称包含非法字符"
		"ACCOUNT_NICKNAME_ALL_DIGITS":
			return "昵称不能全是数字"
		"ACCOUNT_NICKNAME_SENSITIVE":
			return "昵称包含敏感词汇"
		"ACCOUNT_NICKNAME_PLAYER_NOT_FOUND":
			return "角色数据异常，请重新登录后再试"
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

func _get_logout_result_text(result: Dictionary, fallback: String = "登出失败") -> String:
	var reason_code = str(result.get("reason_code", ""))
	match reason_code:
		"ACCOUNT_LOGOUT_SUCCEEDED":
			return ""
		_:
			return api.network_manager.get_api_error_text_for_ui(result, fallback)

func initialize(ui: Node, player_node: Node, game_api: Node = null):
	game_ui = ui
	player = player_node
	api = game_api
	_setup_signals()
	_style_rank_back_button()
	if save_button:
		save_button.visible = false

func _style_rank_back_button():
	if not back_button:
		return
	back_button.custom_minimum_size = Vector2(60, 40)
	back_button.add_theme_font_size_override("font_size", RANK_BACK_FONT_SIZE)
	back_button.add_theme_color_override("font_color", RANK_BACK_TEXT_COLOR)

	var normal_style = StyleBoxFlat.new()
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	normal_style.bg_color = Color(0.82, 0.78, 0.72, 1.0)
	normal_style.border_color = Color(0.55, 0.50, 0.45, 1.0)
	back_button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.75, 0.71, 0.65, 1.0)
	back_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.68, 0.64, 0.58, 1.0)
	back_button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.88, 0.85, 0.80, 0.5)
	back_button.add_theme_stylebox_override("disabled", disabled_style)

func _setup_signals():
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	if confirm_nickname_button:
		confirm_nickname_button.pressed.connect(_on_confirm_nickname_pressed)
	if rank_button:
		rank_button.pressed.connect(_on_rank_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func show_tab():
	if settings_panel:
		settings_panel.visible = true
	if rank_panel:
		rank_panel.visible = false
	if settings_panel and settings_panel.has_node("VBoxContainer"):
		settings_panel.get_node("VBoxContainer").visible = true

func hide_tab():
	if settings_panel:
		settings_panel.visible = false

func _on_logout_pressed():
	if api:
		var result = await api.logout()
		if not result.get("success", false):
			var err_msg = _get_logout_result_text(result, "登出失败")
			if not err_msg.is_empty():
				log_message.emit(err_msg + "，已执行本地退出")

	if api and api.network_manager and api.network_manager.has_method("clear_token"):
		api.network_manager.clear_token()
	get_tree().change_scene_to_file("res://scenes/app/Login.tscn")

func _on_confirm_nickname_pressed():
	if not nickname_input:
		return
	if not api:
		log_message.emit("API未初始化")
		return

	var new_nickname = nickname_input.text.strip_edges()
	if new_nickname.is_empty():
		log_message.emit("昵称不能为空")
		return
	if new_nickname.length() < 4 or new_nickname.length() > 10:
		log_message.emit("昵称长度应在4-10位之间")
		return
	if " " in new_nickname:
		log_message.emit("昵称不能包含空格")
		return
	if new_nickname.is_valid_int():
		log_message.emit("昵称不能全是数字")
		return

	var result = await api.change_nickname(new_nickname)
	if result.get("success", false):
		log_message.emit(_get_nickname_result_text(result, "昵称修改成功"))
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			var account_info = game_manager.get_account_info()
			account_info["nickname"] = new_nickname
			game_manager.set_account_info(account_info)
		if game_ui and game_ui.has_method("update_account_ui"):
			game_ui.update_account_ui()
		nickname_input.text = ""
	else:
		var err_msg = _get_nickname_result_text(result, "昵称修改失败")
		if not err_msg.is_empty():
			log_message.emit(err_msg)

func _on_rank_pressed():
	if not rank_panel:
		return
	if settings_panel and settings_panel.has_node("VBoxContainer"):
		settings_panel.get_node("VBoxContainer").visible = false
	rank_panel.visible = true
	_load_rank_data()

func _on_back_pressed():
	if not rank_panel:
		return
	rank_panel.visible = false
	if settings_panel and settings_panel.has_node("VBoxContainer"):
		settings_panel.get_node("VBoxContainer").visible = true

func _load_rank_data():
	if not rank_list:
		return
	for child in rank_list.get_children():
		child.queue_free()
	if not api:
		log_message.emit("API未初始化，请稍后再试")
		return

	var result = await api.get_rank()
	if result.get("success", false):
		var ranks = result.get("ranks", [])
		if ranks.is_empty():
			log_message.emit("排行榜暂无数据")
			return
		var header = _create_rank_header()
		rank_list.add_child(header)
		var separator = HSeparator.new()
		separator.custom_minimum_size = Vector2(0, 2)
		rank_list.add_child(separator)
		for rank_data in ranks:
			var rank_item = _create_rank_item(rank_data)
			rank_list.add_child(rank_item)
	else:
		var err_msg = api.network_manager.get_api_error_text_for_ui(result, "排行榜加载失败")
		if not err_msg.is_empty():
			log_message.emit(err_msg)


func _create_rank_header() -> HBoxContainer:
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 40)
	var rank_header = Label.new()
	rank_header.text = "排名"
	rank_header.size_flags_horizontal = Control.SIZE_EXPAND
	rank_header.size_flags_stretch_ratio = 10.0
	rank_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_header.add_theme_font_size_override("font_size", 18)
	rank_header.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	header.add_child(rank_header)
	var title_header = Label.new()
	title_header.text = "称号"
	title_header.size_flags_horizontal = Control.SIZE_EXPAND
	title_header.size_flags_stretch_ratio = 20.0
	title_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_header.add_theme_font_size_override("font_size", 18)
	title_header.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	header.add_child(title_header)
	var nickname_header = Label.new()
	nickname_header.text = "昵称"
	nickname_header.size_flags_horizontal = Control.SIZE_EXPAND
	nickname_header.size_flags_stretch_ratio = 30.0
	nickname_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname_header.add_theme_font_size_override("font_size", 18)
	nickname_header.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	header.add_child(nickname_header)
	var realm_header = Label.new()
	realm_header.text = "境界"
	realm_header.size_flags_horizontal = Control.SIZE_EXPAND
	realm_header.size_flags_stretch_ratio = 25.0
	realm_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm_header.add_theme_font_size_override("font_size", 18)
	realm_header.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	header.add_child(realm_header)
	var spirit_header = Label.new()
	spirit_header.text = "灵气"
	spirit_header.size_flags_horizontal = Control.SIZE_EXPAND
	spirit_header.size_flags_stretch_ratio = 15.0
	spirit_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spirit_header.add_theme_font_size_override("font_size", 18)
	spirit_header.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	header.add_child(spirit_header)
	return header

func _create_rank_item(rank_data: Dictionary) -> HBoxContainer:
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(0, 50)
	var rank_label = Label.new()
	rank_label.text = str(int(rank_data.get("rank", 0)))
	rank_label.size_flags_horizontal = Control.SIZE_EXPAND
	rank_label.size_flags_stretch_ratio = 10.0
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	item.add_child(rank_label)
	var title_label = Label.new()
	title_label.text = rank_data.get("title_id", "")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND
	title_label.size_flags_stretch_ratio = 20.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2, 1))
	item.add_child(title_label)
	var nickname_label = Label.new()
	nickname_label.text = rank_data.get("nickname", "未知")
	nickname_label.size_flags_horizontal = Control.SIZE_EXPAND
	nickname_label.size_flags_stretch_ratio = 30.0
	nickname_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname_label.add_theme_font_size_override("font_size", 18)
	nickname_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	item.add_child(nickname_label)
	var realm_label = Label.new()
	var realm_name = rank_data.get("realm", "未知")
	var level = int(rank_data.get("level", 1))
	var level_text = "第" + str(level) + "层"
	if level == 10:
		level_text = "十层"
	realm_label.text = realm_name + " " + level_text
	realm_label.size_flags_horizontal = Control.SIZE_EXPAND
	realm_label.size_flags_stretch_ratio = 25.0
	realm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm_label.add_theme_font_size_override("font_size", 16)
	realm_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	item.add_child(realm_label)
	var spirit_label = Label.new()
	spirit_label.text = UIUtils.format_number(int(rank_data.get("spirit_energy", 0)))
	spirit_label.size_flags_horizontal = Control.SIZE_EXPAND
	spirit_label.size_flags_stretch_ratio = 15.0
	spirit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spirit_label.add_theme_font_size_override("font_size", 16)
	spirit_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.8, 1))
	item.add_child(spirit_label)
	return item
