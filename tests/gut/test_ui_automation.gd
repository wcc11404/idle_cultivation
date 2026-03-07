extends GutTest

## GUT UI 自动化测试 - 完整用户流程
## 测试：点击历练tab -> 进入破境草洞穴 -> 战斗5轮 -> 验证状态

var game_ui: Node = null
var lianli_module: Node = null
var lianli_system: Node = null
var player: Node = null
var inventory: Node = null
var lianli_area_data: Node = null

var battle_count: int = 0
var initial_health: float = 0.0
var initial_spirit_stone: int = 0

func before_all():
	await get_tree().process_frame
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		pending("GameManager not available")
		return
	
	game_ui = game_manager.get_node_or_null("GameUI")
	player = game_manager.get_player()
	inventory = game_manager.get_inventory()
	lianli_system = game_manager.get_lianli_system()
	lianli_area_data = game_manager.get_lianli_area_data()
	
	if game_ui:
		lianli_module = game_ui.get_node_or_null("LianliModule")

func before_each():
	battle_count = 0
	
	if player:
		player.health = player.get_final_max_health()
		player.realm = "炼气期"
		player.realm_level = 5
		player.apply_realm_stats()
		initial_health = player.health
	
	if inventory:
		initial_spirit_stone = inventory.get_item_count("spirit_stone")
	
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()
		await get_tree().process_frame

func after_each():
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()

#region UI 交互测试

func test_click_lianli_tab():
	if not game_ui:
		pending("GameUI not available")
		return
	
	game_ui.show_lianli_tab()
	await get_tree().process_frame
	
	var lianli_panel = game_ui.get_node_or_null("VBoxContainer/ContentPanel/LianliPanel")
	assert_not_null(lianli_panel, "历练面板应存在")
	assert_true(lianli_panel.visible, "历练面板应显示")

func test_enter_herb_cave():
	if not lianli_module or not player:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	
	lianli_module.on_lianli_area_pressed("foundation_herb_cave")
	await get_tree().create_timer(0.5).timeout
	
	assert_true(lianli_system.is_in_lianli, "应在历练中")

#endregion

#region 战斗流程测试

func test_single_battle():
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
		"health": 200.0,
		"attack": 10.0,
		"defense": 5.0,
		"speed": 5,
		"drops": {"spirit_stone": {"chance": 1.0, "min": 5, "max": 10}}
	}
	
	lianli_system.start_battle(enemy_data)
	assert_true(lianli_system.is_in_battle, "战斗应开始")
	
	var max_wait = 20.0
	var wait_time = 0.0
	while lianli_system.is_in_battle and wait_time < max_wait:
		await get_tree().process_frame
		wait_time += get_process_delta_time()
	
	assert_false(lianli_system.is_in_battle, "战斗应结束")
	assert_gt(player.health, 0, "玩家应存活")

func test_five_battles():
	if not lianli_system or not player or not lianli_area_data:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	player.base_attack = 100.0
	player.base_defense = 50.0
	
	var victories = 0
	var defeats = 0
	
	for i in range(5):
		var result = lianli_system.start_lianli_in_area("qi_refining_outer")
		assert_true(result, "第" + str(i + 1) + "场历练应能开始")
		
		var max_wait = 30.0
		var wait_time = 0.0
		while lianli_system.is_in_battle and wait_time < max_wait:
			await get_tree().process_frame
			wait_time += get_process_delta_time()
		
		if player.health > 0:
			victories += 1
		else:
			defeats += 1
			player.health = player.get_final_max_health()
		
		await get_tree().create_timer(0.5).timeout
	
	gut.p("战斗结果: " + str(victories) + " 胜 / " + str(defeats) + " 负")
	assert_gt(victories, 0, "至少应赢得一场战斗")

#endregion

#region 状态验证测试

func test_player_survives_battle():
	if not lianli_system or not player:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	
	lianli_system.start_lianli_in_area("qi_refining_outer")
	
	var max_wait = 30.0
	var wait_time = 0.0
	while lianli_system.is_in_battle and wait_time < max_wait:
		await get_tree().process_frame
		wait_time += get_process_delta_time()
	
	assert_gt(player.health, 0, "玩家气血应大于0")
	assert_gt(player.health, initial_health * 0.1, "玩家气血应超过10%")

func test_spirit_stone_reward():
	if not lianli_system or not player or not inventory:
		pending("Systems not available")
		return
	
	player.health = player.get_final_max_health()
	var initial_stones = inventory.get_item_count("spirit_stone")
	
	lianli_system.start_lianli_in_area("qi_refining_outer")
	
	var max_wait = 30.0
	var wait_time = 0.0
	while lianli_system.is_in_battle and wait_time < max_wait:
		await get_tree().process_frame
		wait_time += get_process_delta_time()
	
	var final_stones = inventory.get_item_count("spirit_stone")
	assert_gt(final_stones, initial_stones, "战斗后灵石应增加")

#endregion
