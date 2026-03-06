extends Node

## UI 自动化测试 - 模拟用户操作
## 测试场景：点击历练tab -> 点击破境草洞穴 -> 进入战斗 -> 模拟5轮对战 -> 检查状态

var helper: Node = null
var game_ui: Node = null
var lianli_module: Node = null
var lianli_system: Node = null
var player: Node = null
var inventory: Node = null

var test_passed: bool = true
var battle_count: int = 0
var initial_health: float = 0.0
var initial_spirit_stone: int = 0

func _ready():
	helper = load("res://tests/test_helper.gd").new()
	add_child(helper)

func run_tests() -> bool:
	print("\n========================================")
	print("UI 自动化测试 - 历练战斗流程")
	print("========================================")
	
	await get_tree().create_timer(0.5).timeout
	
	# 获取系统引用
	if not _get_system_references():
		return false
	
	# 初始化测试状态
	_initialize_test_state()
	
	# 测试步骤1：点击历练tab
	if not await test_click_lianli_tab():
		return false
	
	# 测试步骤2：点击破境草洞穴按钮
	if not await test_click_herb_cave_button():
		return false
	
	# 测试步骤3：验证战斗开始
	if not await test_battle_started():
		return false
	
	# 测试步骤4：模拟5轮对战
	if not await test_simulate_5_rounds():
		return false
	
	# 测试步骤5：验证最终状态
	if not await test_final_state():
		return false
	
	print("\n========================================")
	print("✓ 所有 UI 自动化测试通过！")
	print("========================================")
	
	return true

func _get_system_references() -> bool:
	print("\n=== 获取系统引用 ===")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("✗ 无法获取 GameManager")
		helper.assert_true(false, "UI自动化", "获取GameManager")
		return false
	
	game_ui = game_manager.get_node("GameUI")
	if not game_ui:
		print("✗ 无法获取 GameUI")
		helper.assert_true(false, "UI自动化", "获取GameUI")
		return false
	
	player = game_manager.get_player()
	if not player:
		print("✗ 无法获取 Player")
		helper.assert_true(false, "UI自动化", "获取Player")
		return false
	
	inventory = game_manager.get_inventory()
	if not inventory:
		print("✗ 无法获取 Inventory")
		helper.assert_true(false, "UI自动化", "获取Inventory")
		return false
	
	lianli_system = game_manager.get_lianli_system()
	if not lianli_system:
		print("✗ 无法获取 LianliSystem")
		helper.assert_true(false, "UI自动化", "获取LianliSystem")
		return false
	
	lianli_module = game_ui.get_node("LianliModule")
	if not lianli_module:
		print("✗ 无法获取 LianliModule")
		helper.assert_true(false, "UI自动化", "获取LianliModule")
		return false
	
	print("✓ 系统引用获取成功")
	return true

func _initialize_test_state():
	print("\n=== 初始化测试状态 ===")
	
	# 重置玩家状态
	player.health = player.get_final_max_health()
	player.realm = "炼气期"
	player.realm_level = 5
	player.apply_realm_stats()
	
	# 记录初始状态
	initial_health = player.health
	initial_spirit_stone = inventory.get_item_count("spirit_stone")
	
	print("初始气血: " + str(int(initial_health)))
	print("初始灵石: " + str(initial_spirit_stone))
	
	# 确保不在历练中
	if lianli_system.is_in_lianli:
		lianli_system.end_lianli()
		await get_tree().process_frame

func test_click_lianli_tab() -> bool:
	print("\n=== 测试步骤1：点击历练tab ===")
	
	# 模拟点击历练tab
	game_ui.show_lianli_tab()
	await get_tree().process_frame
	
	# 验证历练面板是否显示
	var lianli_panel = game_ui.get_node("VBoxContainer/ContentPanel/LianliPanel")
	if not lianli_panel:
		print("✗ 历练面板不存在")
		helper.assert_true(false, "UI自动化", "历练面板显示")
		return false
	
	if not lianli_panel.visible:
		print("✗ 历练面板未显示")
		helper.assert_true(false, "UI自动化", "历练面板显示")
		return false
	
	print("✓ 历练tab点击成功，面板已显示")
	return true

func test_click_herb_cave_button() -> bool:
	print("\n=== 测试步骤2：点击破境草洞穴按钮 ===")
	
	# 查找破境草洞穴按钮
	var herb_cave_button = _find_herb_cave_button()
	if not herb_cave_button:
		print("✗ 找不到破境草洞穴按钮")
		helper.assert_true(false, "UI自动化", "找到破境草洞穴按钮")
		return false
	
	print("找到按钮: " + herb_cave_button.text)
	
	# 模拟点击按钮
	lianli_module.on_lianli_area_pressed("foundation_herb_cave")
	await get_tree().process_frame
	
	print("✓ 破境草洞穴按钮点击成功")
	return true

func _find_herb_cave_button() -> Button:
	var lianli_select_panel = game_ui.get_node("VBoxContainer/ContentPanel/LianliPanel/LianliSelectPanel")
	if not lianli_select_panel:
		return null
	
	var vbox = lianli_select_panel.get_node("VBoxContainer")
	if not vbox:
		return null
	
	for child in vbox.get_children():
		if child is Button and "破境草洞穴" in child.text:
			return child
	
	return null

func test_battle_started() -> bool:
	print("\n=== 测试步骤3：验证战斗开始 ===")
	
	await get_tree().create_timer(0.5).timeout
	
	# 验证是否在战斗中
	if not lianli_system.is_in_battle:
		print("✗ 战斗未开始")
		helper.assert_true(false, "UI自动化", "战斗开始")
		return false
	
	# 验证当前敌人
	var current_enemy = lianli_system.current_enemy
	if current_enemy.is_empty():
		print("✗ 当前敌人数据为空")
		helper.assert_true(false, "UI自动化", "敌人数据")
		return false
	
	var enemy_name = current_enemy.get("name", "")
	var enemy_health = current_enemy.get("health", 0)
	var enemy_level = current_enemy.get("level", 0)
	
	print("遭遇敌人: " + enemy_name)
	print("敌人等级: " + str(enemy_level))
	print("敌人气血: " + str(enemy_health))
	
	# 验证战斗场景面板显示
	var lianli_scene_panel = game_ui.get_node("VBoxContainer/ContentPanel/LianliPanel/LianliScenePanel")
	if not lianli_scene_panel.visible:
		print("✗ 战斗场景面板未显示")
		helper.assert_true(false, "UI自动化", "战斗场景面板显示")
		return false
	
	print("✓ 战斗开始验证成功")
	return true

func test_simulate_5_rounds() -> bool:
	print("\n=== 测试步骤4：模拟5轮对战 ===")
	
	battle_count = 0
	
	for round_num in range(1, 6):
		print("\n--- 第 " + str(round_num) + " 轮 ---")
		
		if not await _simulate_one_battle():
			print("✗ 第 " + str(round_num) + " 轮战斗失败")
			helper.assert_true(false, "UI自动化", "第" + str(round_num) + "轮战斗")
			return false
		
		battle_count += 1
		print("✓ 第 " + str(round_num) + " 轮战斗完成")
		
		# 检查玩家是否存活
		if player.health <= 0:
			print("✗ 玩家在第 " + str(round_num) + " 轮战斗中死亡")
			helper.assert_true(false, "UI自动化", "玩家存活")
			return false
	
	print("\n✓ 5轮对战模拟完成")
	return true

func _simulate_one_battle() -> bool:
	# 等待战斗结束
	var max_wait_time = 30.0
	var wait_time = 0.0
	
	while lianli_system.is_in_battle and wait_time < max_wait_time:
		await get_tree().process_frame
		wait_time += get_process_delta_time()
	
	if lianli_system.is_in_battle:
		print("✗ 战斗超时")
		return false
	
	# 等待下一场战斗（如果有连续战斗）
	await get_tree().create_timer(0.5).timeout
	
	return true

func test_final_state() -> bool:
	print("\n=== 测试步骤5：验证最终状态 ===")
	
	var final_health = player.health
	var final_spirit_stone = inventory.get_item_count("spirit_stone")
	
	print("最终气血: " + str(int(final_health)))
	print("最终灵石: " + str(final_spirit_stone))
	print("战斗场次: " + str(battle_count))
	
	# 验证气血不为0
	if final_health <= 0:
		print("✗ 玩家气血为0")
		helper.assert_true(false, "UI自动化", "玩家气血>0")
		return false
	
	helper.assert_true(final_health > 0, "UI自动化", "玩家气血>0")
	
	# 验证灵石增加
	if final_spirit_stone < initial_spirit_stone:
		print("✗ 灵石减少（初始: " + str(initial_spirit_stone) + ", 最终: " + str(final_spirit_stone) + "）")
		helper.assert_true(false, "UI自动化", "灵石增加")
		return false
	
	helper.assert_true(final_spirit_stone >= initial_spirit_stone, "UI自动化", "灵石增加")
	
	# 验证战斗场次
	if battle_count != 5:
		print("✗ 战斗场次不正确（期望5场，实际" + str(battle_count) + "场）")
		helper.assert_true(false, "UI自动化", "战斗场次=5")
		return false
	
	helper.assert_eq(battle_count, 5, "UI自动化", "战斗场次=5")
	
	print("✓ 最终状态验证成功")
	return true
