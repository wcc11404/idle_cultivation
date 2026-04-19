class_name DongfuModule extends Node

# 地区模块 - 处理地区入口（炼丹坊、百草山）等

# 信号
signal alchemy_room_requested
signal herb_gather_requested
signal log_message(message: String)

# 引用
var game_ui: Node = null
var player: Node = null
var alchemy_module = null

# UI节点引用
var region_panel: Control = null
var alchemy_workshop_button: Button = null
var herb_mountain_button: Button = null

func initialize(ui: Node, player_node: Node, alchemy_mod = null):
	game_ui = ui
	player = player_node
	alchemy_module = alchemy_mod
	_setup_signals()

func _setup_signals():
	# 连接炼丹坊按钮
	if alchemy_workshop_button:
		alchemy_workshop_button.pressed.connect(_on_alchemy_workshop_pressed)
	# 百草山功能后续开放（本轮仅入口）
	if herb_mountain_button:
		herb_mountain_button.pressed.connect(_on_herb_mountain_pressed)

# 显示地区Tab
func show_tab():
	if region_panel:
		region_panel.visible = true

# 隐藏地区Tab
func hide_tab():
	if region_panel:
		region_panel.visible = false

func _on_alchemy_workshop_pressed():
	# 隐藏地区面板
	if region_panel:
		region_panel.visible = false
	# 显示炼丹房
	if alchemy_module:
		alchemy_module.show_alchemy_room()
	# 发送信号
	alchemy_room_requested.emit()

func _on_herb_mountain_pressed():
	if region_panel:
		region_panel.visible = false
	herb_gather_requested.emit()
