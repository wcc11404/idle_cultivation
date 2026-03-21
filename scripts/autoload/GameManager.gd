extends Node

signal offline_reward_received(rewards: Dictionary)
signal account_logged_in(account_info: Dictionary)

# 静态变量，防止重复初始化
static var _systems_initialized: bool = false

var player: Node = null
var cultivation_system: Node = null
var lianli_system: Node = null
var realm_system: Node = null
var cloud_save_manager: Node = null
var inventory: Node = null
var item_data: Node = null
var lianli_area_data: Node = null
var enemy_data: Node = null
var spell_data: Node = null
var spell_system: Node = null
var endless_tower_data: Node = null
var alchemy_system: Node = null
var recipe_data: Node = null
var account_info: Dictionary = {}
var last_online_time: int = 0

func _ready():
	# 防止重复初始化（在编辑器中脚本重新加载时）
	if _systems_initialized:
		return
	
	init_systems()
	_systems_initialized = true
	create_player()
	print("游戏初始化完成")
	print("=== GameManager._ready() 结束 ===")

func init_systems():
	item_data = load("res://scripts/core/inventory/ItemData.gd").new()
	item_data.name = "ItemData"
	add_child(item_data)
	print("物品数据初始化完成")
	
	lianli_area_data = load("res://scripts/core/lianli/LianliAreaData.gd").new()
	lianli_area_data.name = "LianliAreaData"
	add_child(lianli_area_data)
	print("历练区域数据初始化完成")
	
	enemy_data = load("res://scripts/core/lianli/EnemyData.gd").new()
	enemy_data.name = "EnemyData"
	add_child(enemy_data)
	print("敌人数据初始化完成")
	
	realm_system = load("res://scripts/core/realm/RealmSystem.gd").new()
	realm_system.name = "RealmSystem"
	add_child(realm_system)
	print("境界系统初始化完成")
	
	inventory = load("res://scripts/core/inventory/Inventory.gd").new()
	inventory.name = "Inventory"
	add_child(inventory)
	print("储纳系统初始化完成")
	
	cultivation_system = load("res://scripts/core/realm/CultivationSystem.gd").new()
	cultivation_system.name = "CultivationSystem"
	add_child(cultivation_system)
	print("修炼系统初始化完成")
	
	endless_tower_data = load("res://scripts/core/lianli/EndlessTowerData.gd").new()
	endless_tower_data.name = "EndlessTowerData"
	add_child(endless_tower_data)
	print("无尽塔数据初始化完成")
	
	lianli_system = load("res://scripts/core/lianli/LianliSystem.gd").new()
	lianli_system.name = "LianliSystem"
	add_child(lianli_system)
	lianli_system.set_lianli_area_data(lianli_area_data)
	lianli_system.set_enemy_data(enemy_data)
	lianli_system.set_endless_tower_data(endless_tower_data)
	print("历练系统初始化完成")
	
	# 使用 CloudSaveManager 替代 SaveManager
	cloud_save_manager = load("res://scripts/managers/CloudSaveManager.gd").new()
	cloud_save_manager.name = "CloudSaveManager"
	add_child(cloud_save_manager)
	print("云端存档系统初始化完成")
	
	spell_data = load("res://scripts/core/spell/SpellData.gd").new()
	spell_data.name = "SpellData"
	add_child(spell_data)
	print("术法数据初始化完成")
	
	spell_system = load("res://scripts/core/spell/SpellSystem.gd").new()
	spell_system.name = "SpellSystem"
	add_child(spell_system)
	spell_system.set_spell_data(spell_data)
	spell_system.set_lianli_system(lianli_system)
	print("术法系统初始化完成")
	
	# 初始化炼丹系统
	recipe_data = load("res://scripts/core/alchemy/AlchemyRecipeData.gd").new()
	recipe_data.name = "AlchemyRecipeData"
	add_child(recipe_data)
	print("丹方数据初始化完成")
	
	alchemy_system = load("res://scripts/core/alchemy/AlchemySystem.gd").new()
	alchemy_system.name = "AlchemySystem"
	add_child(alchemy_system)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_inventory(inventory)
	alchemy_system.set_spell_system(spell_system)
	print("炼丹系统初始化完成")

func create_player():
	player = load("res://scripts/core/PlayerData.gd").new()
	player.name = "Player"
	add_child(player)
	
	cultivation_system.set_player(player)
	lianli_system.set_player(player)
	spell_system.set_player(player)
	alchemy_system.set_player(player)
	
	print("玩家创建完成，境界：", player.realm)

func get_player():
	return player

func get_cultivation_system():
	return cultivation_system

func get_lianli_system():
	return lianli_system

func get_realm_system():
	return realm_system

func get_save_manager():
	return cloud_save_manager

func get_inventory():
	return inventory

func get_item_data():
	return item_data

func get_spell_data():
	return spell_data

func get_spell_system():
	return spell_system

func get_lianli_area_data():
	return lianli_area_data

func get_enemy_data():
	return enemy_data

func get_endless_tower_data():
	return endless_tower_data

func get_alchemy_system():
	return alchemy_system

func get_recipe_data():
	return recipe_data

func get_account_info() -> Dictionary:
	return account_info

func set_account_info(info: Dictionary):
	account_info = info
	account_logged_in.emit(info)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# 关闭游戏时自动保存
		# 使用call_deferred来处理协程操作
		call_deferred("_handle_game_exit")

func _handle_game_exit():
	# 处理游戏退出逻辑
	print("开始处理游戏退出")
	# 直接调用CloudSaveManager的on_game_exit方法，并等待它完成
	if cloud_save_manager:
		await cloud_save_manager.on_game_exit()
		print("调用CloudSaveManager.on_game_exit()完成")
	# 等待一小段时间，确保保存操作完成
	await get_tree().create_timer(1.0).timeout
	# 退出游戏
	print("退出游戏")
	get_tree().quit()

func save_game() -> bool:
	if cloud_save_manager:
		var result = await cloud_save_manager.save_game()
		print("游戏已保存，结果: " + str(result))
		return result
	else:
		push_error("save_game: cloud_save_manager 为 null!")
		return false

func load_game() -> bool:
	if cloud_save_manager:
		var success = await cloud_save_manager.load_game()
		if success:
			print("游戏已加载")
		return success
	return false

func get_last_online_time() -> int:
	if last_online_time == 0:
		# 首次运行，设置为当前时间
		last_online_time = Time.get_unix_time_from_system()
	return last_online_time

func set_last_online_time(time: int):
	last_online_time = time
