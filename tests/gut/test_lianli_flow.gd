extends GutTest

## GUT 测试示例 - 历练战斗流程
## 使用 GUT 框架的断言和方法

var player: Node = null
var lianli_system: Node = null
var inventory: Node = null
var lianli_area_data: Node = null

func before_all():
	await get_tree().process_frame
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		player = game_manager.get_player()
		lianli_system = game_manager.get_lianli_system()
		inventory = game_manager.get_inventory()
		lianli_area_data = game_manager.get_lianli_area_data()

func before_each():
	if player:
		player.health = player.get_final_max_health()
		player.spirit_energy = 0.0
	
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()
		await get_tree().process_frame

func after_each():
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()

#region 玩家数据测试

func test_player_initial_health():
	if not player:
		pending("Player not available")
		return
	
	assert_gt(player.health, 0, "玩家初始气血应大于0")

func test_player_max_health():
	if not player:
		pending("Player not available")
		return
	
	var max_health = player.get_final_max_health()
	assert_gt(max_health, 0, "玩家最大气血应大于0")
	assert_true(player.health <= max_health, "当前气血不应超过最大气血")

func test_player_realm():
	if not player:
		pending("Player not available")
		return
	
	assert_not_null(player.realm, "玩家境界不应为空")
	assert_gt(player.realm_level, 0, "玩家境界等级应大于0")

#endregion

#region 历练系统测试

func test_lianli_system_exists():
	assert_not_null(lianli_system, "历练系统应存在")

func test_lianli_not_in_battle_initially():
	if not lianli_system:
		pending("LianliSystem not available")
		return
	
	assert_false(lianli_system.is_in_battle, "初始状态不应在战斗中")
	assert_false(lianli_system.is_in_lianli, "初始状态不应在历练中")

func test_start_lianli_in_area():
	if not lianli_system or not player:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	
	var result = lianli_system.start_lianli_in_area("qi_refining_outer")
	assert_true(result, "应能成功开始历练")
	assert_true(lianli_system.is_in_lianli, "应在历练中")
	
	lianli_system.end_lianli()

func test_lianli_area_data_exists():
	if not lianli_area_data:
		pending("LianliAreaData not available")
		return
	
	var area_name = lianli_area_data.get_area_name("qi_refining_outer")
	assert_not_null(area_name, "区域名称不应为空")

#endregion

#region 战斗流程测试

func test_battle_flow():
	if not lianli_system or not player:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	player.base_attack = 100.0
	player.base_defense = 50.0
	
	var enemy_data = {
		"id": "test_enemy",
		"name": "测试敌人",
		"level": 1,
		"health": 100.0,
		"attack": 10.0,
		"defense": 5.0,
		"speed": 5,
		"drops": {}
	}
	
	var result = lianli_system.start_battle(enemy_data)
	assert_true(result, "应能成功开始战斗")
	assert_true(lianli_system.is_in_battle, "应在战斗中")
	
	await get_tree().create_timer(2.0).timeout
	
	assert_false(lianli_system.is_in_battle, "战斗应已结束")
	assert_gt(player.health, 0, "玩家应存活")

#endregion

#region 库存测试

func test_inventory_exists():
	assert_not_null(inventory, "库存系统应存在")

func test_inventory_add_item():
	if not inventory:
		pending("Inventory not available")
		return
	
	var initial_count = inventory.get_item_count("spirit_stone")
	inventory.add_item("spirit_stone", 10)
	var new_count = inventory.get_item_count("spirit_stone")
	
	assert_eq(new_count, initial_count + 10, "添加物品后数量应正确")

func test_inventory_remove_item():
	if not inventory:
		pending("Inventory not available")
		return
	
	inventory.add_item("spirit_stone", 20)
	var initial_count = inventory.get_item_count("spirit_stone")
	
	var result = inventory.remove_item("spirit_stone", 5)
	assert_true(result, "移除物品应成功")
	
	var new_count = inventory.get_item_count("spirit_stone")
	assert_eq(new_count, initial_count - 5, "移除物品后数量应正确")

#endregion
