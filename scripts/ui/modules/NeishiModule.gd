class_name NeishiModule extends Node

## 内视模块 - 管理内视页面的所有子模块
## 负责协调修炼、突破、术法等功能

# 信号
signal sub_panel_changed(panel_name: String)
signal log_message(message: String)

# 引用
var game_ui: Node = null
var player: Node = null

# 子模块
var cultivation_module: CultivationModule = null
var spell_module: SpellModule = null

# UI节点引用（由GameUI设置）
var neishi_panel: Control = null
var cultivation_panel: Control = null
var spell_panel: Control = null

# 子Tab按钮
var cultivation_tab: Button = null
var spell_tab: Button = null

# 当前活动面板
var current_panel: Control = null

# 状态
var _is_initialized: bool = false

func _ready():
	pass

func initialize(ui: Node, player_node: Node):
	game_ui = ui
	player = player_node
	_is_initialized = true

# 设置子模块
func set_cultivation_module(module: CultivationModule):
	cultivation_module = module
	# [注意] 不需要连接 cultivation_module.log_message 信号
	# 因为 GameUI 已经直接连接了 cultivation_module 的信号
	# 如果这里再连接并转发，会导致消息重复

func set_spell_module(module: SpellModule):
	spell_module = module

# 显示内视Tab
func show_tab():
	if neishi_panel:
		neishi_panel.visible = true
	# 默认显示修炼面板
	_show_sub_panel(cultivation_panel)

# 隐藏内视Tab
func hide_tab():
	if neishi_panel:
		neishi_panel.visible = false

# 显示子面板（修炼/术法）
func show_cultivation_panel():
	_show_sub_panel(cultivation_panel)
	if cultivation_module:
		cultivation_module.show_panel()

func show_spell_panel():
	_show_sub_panel(spell_panel)
	if spell_module:
		spell_module.show_tab()

# 内部：切换子面板
func _show_sub_panel(active_panel: Control):
	# 隐藏所有子面板
	if cultivation_panel:
		cultivation_panel.visible = false
	if spell_panel:
		spell_panel.visible = false
	
	# 隐藏所有子模块的面板
	if cultivation_module and active_panel != cultivation_panel:
		cultivation_module.hide_panel()
	if spell_module and active_panel != spell_panel:
		spell_module.hide_tab()
	
	# 显示选中的面板
	if active_panel:
		active_panel.visible = true
		current_panel = active_panel
		
		# 显示对应子模块的面板
		if active_panel == cultivation_panel and cultivation_module:
			cultivation_module.show_panel()
		elif active_panel == spell_panel and spell_module:
			spell_module.show_tab()
	
	# 更新按钮状态
	_update_tab_buttons(active_panel)
	
	# 发送信号
	var panel_name = _get_panel_name(active_panel)
	sub_panel_changed.emit(panel_name)

# 获取面板名称
func _get_panel_name(panel: Control) -> String:
	if panel == cultivation_panel:
		return "cultivation"
	elif panel == spell_panel:
		return "spell"
	return ""

# 更新Tab按钮视觉状态（使用disabled属性标识选中状态，与主TabBar一致）
func _update_tab_buttons(active_panel: Control):
	if cultivation_tab:
		cultivation_tab.disabled = (active_panel == cultivation_panel)
	if spell_tab:
		spell_tab.disabled = (active_panel == spell_panel)

# Tab按钮按下处理
func on_cultivation_tab_pressed():
	show_cultivation_panel()

func on_spell_tab_pressed():
	show_spell_panel()

# 更新UI（由GameUI调用）
func update_ui():
	if cultivation_module:
		cultivation_module.update_cultivate_button_state()

# 清理
func cleanup():
	_is_initialized = false
