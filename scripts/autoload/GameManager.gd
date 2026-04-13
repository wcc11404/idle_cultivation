extends Node

signal account_logged_in(account_info: Dictionary)

static var _systems_initialized: bool = false

var player: Node = null
var cultivation_system: Node = null
var lianli_system: Node = null
var realm_system: Node = null
var inventory: Node = null
var item_data: Node = null
var lianli_area_data: Node = null
var enemy_data: Node = null
var spell_data: Node = null
var spell_system: Node = null
var alchemy_system: Node = null
var recipe_data: Node = null
var account_info: Dictionary = {}

func _ready():
	if _systems_initialized:
		return
	
	init_systems()
	_systems_initialized = true
	create_player()

func init_systems():
	item_data = load("res://scripts/core/inventory/ItemData.gd").new()
	item_data.name = "ItemData"
	add_child(item_data)
	
	lianli_area_data = load("res://scripts/core/lianli/LianliAreaData.gd").new()
	lianli_area_data.name = "LianliAreaData"
	add_child(lianli_area_data)
	
	enemy_data = load("res://scripts/core/lianli/EnemyData.gd").new()
	enemy_data.name = "EnemyData"
	add_child(enemy_data)
	
	realm_system = load("res://scripts/core/cultivation/RealmSystem.gd").new()
	realm_system.name = "RealmSystem"
	add_child(realm_system)
	
	inventory = load("res://scripts/core/inventory/Inventory.gd").new()
	inventory.name = "Inventory"
	add_child(inventory)
	
	cultivation_system = load("res://scripts/core/cultivation/CultivationSystem.gd").new()
	cultivation_system.name = "CultivationSystem"
	add_child(cultivation_system)
	
	lianli_system = load("res://scripts/core/lianli/LianliSystem.gd").new()
	lianli_system.name = "LianliSystem"
	add_child(lianli_system)
	lianli_system.set_lianli_area_data(lianli_area_data)
	lianli_system.set_enemy_data(enemy_data)
	
	spell_data = load("res://scripts/core/spell/SpellData.gd").new()
	spell_data.name = "SpellData"
	add_child(spell_data)
	
	spell_system = load("res://scripts/core/spell/SpellSystem.gd").new()
	spell_system.name = "SpellSystem"
	add_child(spell_system)
	spell_system.set_spell_data(spell_data)
	spell_system.set_lianli_system(lianli_system)
	
	recipe_data = load("res://scripts/core/alchemy/AlchemyRecipeData.gd").new()
	recipe_data.name = "AlchemyRecipeData"
	add_child(recipe_data)
	
	alchemy_system = load("res://scripts/core/alchemy/AlchemySystem.gd").new()
	alchemy_system.name = "AlchemySystem"
	add_child(alchemy_system)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_inventory(inventory)
	alchemy_system.set_spell_system(spell_system)

func create_player():
	player = load("res://scripts/core/player/PlayerData.gd").new()
	player.name = "Player"
	add_child(player)
	
	cultivation_system.set_player(player)
	lianli_system.set_player(player)
	spell_system.set_player(player)
	alchemy_system.set_player(player)

func get_player():
	return player

func get_cultivation_system():
	return cultivation_system

func get_lianli_system():
	return lianli_system

func get_realm_system():
	return realm_system

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
		# 避免在通知阶段直接切场景/退出，统一延迟到下一帧处理。
		call_deferred("_handle_game_exit")

func _handle_game_exit():
	get_tree().quit()

func apply_save_data(data: Dictionary):
	account_info = data
	account_logged_in.emit(data)
