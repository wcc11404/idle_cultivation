class_name DongfuModule extends Node

# 洞府模块 - 处理洞府功能、炼丹房入口等

# 信号
signal alchemy_room_requested

# 引用
var game_ui: Node = null
var player: Node = null
var alchemy_module = null

# UI节点引用
var dongfu_panel: Control = null
var alchemy_room_button: Button = null

func initialize(ui: Node, player_node: Node, alchemy_mod = null):
	game_ui = ui
	player = player_node
	alchemy_module = alchemy_mod
	_setup_signals()

func _setup_signals():
	# 连接炼丹房按钮
	if alchemy_room_button:
		alchemy_room_button.pressed.connect(_on_alchemy_room_pressed)

# 显示洞府Tab
func show_tab():
	if dongfu_panel:
		dongfu_panel.visible = true

# 隐藏洞府Tab
func hide_tab():
	if dongfu_panel:
		dongfu_panel.visible = false

# 炼丹房按钮按下
func _on_alchemy_room_pressed():
	# 隐藏洞府面板
	if dongfu_panel:
		dongfu_panel.visible = false
	# 显示炼丹房
	if alchemy_module:
		alchemy_module.show_alchemy_room()
	# 发送信号
	alchemy_room_requested.emit()
