class_name SettingsModule extends Node

# 设置模块 - 处理游戏设置、存档等功能

# 信号
signal save_requested
signal load_requested
signal log_message(message: String)  # 日志消息信号

# 引用
var game_ui: Node = null
var player: Node = null
var save_manager: Node = null

# UI节点引用
var settings_panel: Control = null
var save_button: Button = null
var load_button: Button = null
var logout_button: Button = null

func initialize(ui: Node, player_node: Node, save_mgr: Node):
	game_ui = ui
	player = player_node
	save_manager = save_mgr
	_setup_signals()

func _setup_signals():
	# 连接按钮信号
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)

# 显示设置Tab
func show_tab():
	if settings_panel:
		settings_panel.visible = true

# 隐藏设置Tab
func hide_tab():
	if settings_panel:
		settings_panel.visible = false

# 保存按钮按下
func _on_save_pressed() -> bool:
	save_requested.emit()
	
	# 从GameManager获取save_manager
	if not save_manager:
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			save_manager = game_manager.get_save_manager()
	
	if save_manager:
		var result = await save_manager.save_game()
		if result:
			log_message.emit("存档成功！")
		else:
			log_message.emit("存档失败...")
		return result
	return false

# 加载按钮按下
func _on_load_pressed():
	load_requested.emit()
	
	# 从GameManager获取save_manager
	if not save_manager:
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			save_manager = game_manager.get_save_manager()
	
	# 使用GameManager的load_game来触发离线奖励计算
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var result = game_manager.load_game()
		if result:
			log_message.emit("读档成功！")
			# 刷新UI
			if game_ui.has_method("update_ui"):
				game_ui.update_ui()
			if game_ui.has_method("refresh_inventory_ui"):
				game_ui.refresh_inventory_ui()
		else:
			log_message.emit("读档失败...")
		return result
	return false

# 保存游戏
func save_game() -> bool:
	save_requested.emit()
	if save_manager:
		return await save_manager.save_game()
	return false

# 加载游戏
func load_game() -> bool:
	load_requested.emit()
	if save_manager:
		return save_manager.load_game()
	return false

# 登出按钮按下
func _on_logout_pressed():
	# 保存游戏数据
	log_message.emit("正在保存游戏数据...")
	var save_result = await _on_save_pressed()
	
	if save_result:
		log_message.emit("保存成功，正在登出...")
		# 清除Token
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			var cloud_save_manager = game_manager.get_save_manager()
			if cloud_save_manager and cloud_save_manager.has_method("api"):
				var api = cloud_save_manager.api
				if api and api.has_method("network_manager"):
					var network_manager = api.network_manager
					if network_manager and network_manager.has_method("clear_token"):
						network_manager.clear_token()
						log_message.emit("Token已清除")
		# 退出游戏
		log_message.emit("退出游戏")
		get_tree().quit()
	else:
		log_message.emit("保存失败，无法登出")
