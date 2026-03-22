extends Node

class_name GameServerAPI

var network_manager = null

func _ready():
	# 使用全局的 NetworkManager 单例
	network_manager = get_node_or_null("/root/GlobalNetworkManager")
	if not network_manager:
		print("GlobalNetworkManager 单例未找到，创建本地实例")
		const NetworkManager = preload("res://scripts/network/NetworkManager.gd")
		network_manager = NetworkManager.new()
		add_child(network_manager)

func register(username: String, password: String) -> Dictionary:
	var body = {
		"username": username,
		"password": password
	}
	return await network_manager.request("POST", "/auth/register", body)

func login(username: String, password: String) -> Dictionary:
	var body = {
		"username": username,
		"password": password
	}
	return await network_manager.request("POST", "/auth/login", body)

func refresh_token() -> Dictionary:
	return await network_manager.request("POST", "/auth/refresh")

func save_game(data: Dictionary) -> Dictionary:
	var body = {
		"data": data
	}
	return await network_manager.request("POST", "/game/save", body)

func load_game() -> Dictionary:
	return await network_manager.request("GET", "/game/data")

func player_breakthrough(current_realm: String, current_level: int, spirit_energy: float, inventory_items: Dictionary) -> Dictionary:
	var body = {
		"current_realm": current_realm,
		"current_level": current_level,
		"spirit_energy": spirit_energy,
		"inventory_items": inventory_items
	}
	return await network_manager.request("POST", "/game/player/breakthrough", body)

func inventory_use_item(item_id: String, count: int, current_inventory: Dictionary) -> Dictionary:
	var body = {
		"item_id": item_id,
		"count": count,
		"current_inventory": current_inventory
	}
	return await network_manager.request("POST", "/game/inventory/use_item", body)

func battle_victory(area_id: String, enemy_id: String, enemy_level: int, is_tower: bool, tower_floor: int) -> Dictionary:
	var body = {
		"area_id": area_id,
		"enemy_id": enemy_id,
		"enemy_level": enemy_level,
		"is_tower": is_tower,
		"tower_floor": tower_floor
	}
	return await network_manager.request("POST", "/game/battle/victory", body)

func spell_upgrade(spell_id: String, current_level: int, use_count: int, charged_spirit: int) -> Dictionary:
	var body = {
		"spell_id": spell_id,
		"current_level": current_level,
		"use_count": use_count,
		"charged_spirit": charged_spirit
	}
	return await network_manager.request("POST", "/game/spell/upgrade", body)

func spell_charge(spell_id: String, amount: int, player_spirit: float) -> Dictionary:
	var body = {
		"spell_id": spell_id,
		"amount": amount,
		"player_spirit": player_spirit
	}
	return await network_manager.request("POST", "/game/spell/charge", body)

func alchemy_learn_recipe(recipe_id: String, current_recipes: Array) -> Dictionary:
	var body = {
		"recipe_id": recipe_id,
		"current_recipes": current_recipes
	}
	return await network_manager.request("POST", "/game/alchemy/learn_recipe", body)

func alchemy_start_craft(recipe_id: String, count: int, materials: Dictionary, spirit_energy: float) -> Dictionary:
	var body = {
		"recipe_id": recipe_id,
		"count": count,
		"materials": materials,
		"spirit_energy": spirit_energy
	}
	return await network_manager.request("POST", "/game/alchemy/start_craft", body)

func claim_offline_reward() -> Dictionary:
	# 获取离线奖励
	# 服务端自动计算离线时间，不需要客户端提供
	var body = {}
	return await network_manager.request("POST", "/game/claim_offline_reward", body)

func get_dungeon_info() -> Dictionary:
	# 获取副本信息
	return await network_manager.request("GET", "/game/dungeon/info")

func enter_dungeon(dungeon_id: String) -> Dictionary:
	# 进入副本
	var body = {
		"dungeon_id": dungeon_id
	}
	return await network_manager.request("POST", "/game/dungeon/enter", body)

func finish_dungeon(dungeon_id: String) -> Dictionary:
	# 完成副本并扣减次数
	var body = {
		"dungeon_id": dungeon_id
	}
	return await network_manager.request("POST", "/game/dungeon/finish", body)

func get_rank(server_id: String = "default") -> Dictionary:
	# 获取排行榜
	return await network_manager.request("GET", "/game/rank?server_id=" + server_id)

func change_nickname(new_nickname: String) -> Dictionary:
	# 修改昵称
	var body = {
		"nickname": new_nickname
	}
	return await network_manager.request("POST", "/game/player/nickname", body)
