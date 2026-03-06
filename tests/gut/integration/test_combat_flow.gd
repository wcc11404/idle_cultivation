extends GutTest

## 集成测试 - 历练系统战斗流程

var game_manager: Node = null
var lianli_system: LianliSystem = null
var inventory: Inventory = null
var player: PlayerData = null
var spell_system: SpellSystem = null
var item_data: ItemData = null
var enemy_data: EnemyData = null
var lianli_area_data: LianliAreaData = null
var realm_system: RealmSystem = null

var _reward_connection: Dictionary = {}

func before_all():
	await get_tree().process_frame
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		pending("GameManager not available")
		return

func before_each():
	if not game_manager:
		pending("GameManager not available")
		return
	
	_setup_systems()
	await get_tree().process_frame

func after_each():
	_cleanup_systems()
	await get_tree().process_frame

func _setup_systems():
	player = game_manager.get_player()
	inventory = game_manager.get_inventory()
	lianli_system = game_manager.get_lianli_system()
	spell_system = game_manager.get_spell_system()
	item_data = game_manager.get_item_data()
	enemy_data = game_manager.get_enemy_data()
	lianli_area_data = game_manager.get_lianli_area_data()
	realm_system = game_manager.get_realm_system()
	
	if not player or not inventory or not lianli_system:
		pending("Required systems not available")
		return
	
	_connect_reward_signal()
	_reset_player_state()
	_reset_inventory()
	_reset_spell_system()

func _connect_reward_signal():
	if lianli_system and lianli_system.has_signal("lianli_reward"):
		if not _reward_connection.has("connected"):
			lianli_system.lianli_reward.connect(_on_lianli_reward)
			_reward_connection["connected"] = true

func _on_lianli_reward(item_id: String, amount: int, source: String):
	if inventory:
		inventory.add_item(item_id, amount)
	gut.p("[奖励] 获得 " + item_id + " x" + str(amount) + " (来源: " + source + ")")

func _reset_player_state():
	if lianli_system.is_in_lianli:
		lianli_system.end_lianli()
		await get_tree().process_frame
	
	player.realm = "炼气期"
	player.realm_level = 1
	player.apply_realm_stats()
	player.health = player.get_final_max_health()
	player.spirit_energy = player.get_final_max_spirit_energy()
	player.combat_buffs = {}
	
	lianli_system.tower_highest_floor = 0
	lianli_system.daily_dungeon_data = {}

func _reset_inventory():
	inventory.clear()

func _reset_spell_system():
	if spell_system:
		for spell_id in spell_system.player_spells.keys():
			spell_system.player_spells[spell_id]["obtained"] = false
			spell_system.player_spells[spell_id]["level"] = 1
			spell_system.player_spells[spell_id]["use_count"] = 0
			spell_system.player_spells[spell_id]["charged_spirit"] = 0
		
		for spell_type in spell_system.equipped_spells.keys():
			spell_system.equipped_spells[spell_type] = []

func _cleanup_systems():
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()
		await get_tree().process_frame
	
	if inventory:
		inventory.clear()

func _check_systems_available() -> bool:
	if not player or not inventory or not lianli_system:
		pending("Required systems not available")
		return false
	return true

#region 场景①: 炼气一层玩家挑战炼气外围

func test_qi_level1_vs_outer_area_survival():
	if not _check_systems_available():
		return
	
	player.realm = "炼气期"
	player.realm_level = 1
	player.apply_realm_stats()
	player.health = player.get_final_max_health()
	
	var max_health = int(player.get_final_max_health())
	
	lianli_system.set_lianli_speed(10.0)
	
	gut.p("========== 场景①: 炼气一层玩家挑战炼气外围 ==========")
	gut.p("战斗倍速: 10x")
	gut.p("玩家境界: " + player.realm + " " + str(player.realm_level) + "层")
	gut.p("玩家气血: " + str(int(player.health)) + "/" + str(max_health))
	gut.p("玩家攻击: " + str(int(player.get_final_attack())))
	gut.p("玩家防御: " + str(int(player.get_final_defense())))
	gut.p("玩家速度: " + str(player.get_final_speed()))
	
	assert_eq(player.realm, "炼气期", "境界应为炼气期")
	assert_eq(player.realm_level, 1, "境界等级应为1")
	assert_eq(max_health, 50, "炼气一层最大气血应为50")
	
	lianli_system.set_continuous_lianli(true)
	var started = lianli_system.start_lianli_in_area("qi_refining_outer")
	assert_true(started, "应成功进入历练区域")
	
	var battle_count = 0
	var max_battles = 10
	var max_total_wait = 120.0
	var total_wait = 0.0
	var test_start_time = Time.get_ticks_msec()
	
	while battle_count < max_battles and total_wait < max_total_wait:
		var battle_start = Time.get_ticks_msec()
		
		while not lianli_system.is_in_battle and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
		
		if not lianli_system.is_in_battle:
			break
		
		var enemy = lianli_system.current_enemy
		if enemy.size() > 0:
			gut.p("---------- 战斗 " + str(battle_count + 1) + " 开始 ----------")
			gut.p("敌人: " + str(enemy.get("name", "未知")) + " Lv." + str(enemy.get("level", 0)))
			gut.p("敌人气血: " + str(int(enemy.get("current_health", 0))) + "/" + str(int(enemy.get("health", 0))))
			gut.p("敌人攻击: " + str(int(enemy.get("attack", 0))))
			gut.p("敌人防御: " + str(int(enemy.get("defense", 0))))
			gut.p("敌人速度: " + str(enemy.get("speed", 0)))
			gut.p("玩家气血: " + str(int(player.health)))
		
		var last_player_health = player.health
		var last_enemy_health = enemy.get("current_health", 0) if enemy.size() > 0 else 0
		
		while lianli_system.is_in_battle and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
			
			if enemy.size() > 0:
				var current_enemy_health = enemy.get("current_health", 0)
				var current_player_health = player.health
				
				if current_enemy_health != last_enemy_health:
					gut.p("  敌人气血变化: " + str(int(last_enemy_health)) + " -> " + str(int(current_enemy_health)))
					last_enemy_health = current_enemy_health
				
				if current_player_health != last_player_health:
					gut.p("  玩家气血变化: " + str(int(last_player_health)) + " -> " + str(int(current_player_health)))
					last_player_health = current_player_health
		
		var battle_time = (Time.get_ticks_msec() - battle_start) / 1000.0
		
		var enemy_defeated = false
		if enemy.size() > 0 and enemy.get("current_health", 0) <= 0:
			enemy_defeated = true
			battle_count += 1
		
		gut.p("---------- 战斗 " + str(battle_count) + " 结束 ----------")
		gut.p("耗时: " + str(battle_time) + "秒")
		gut.p("玩家气血: " + str(int(player.health)))
		gut.p("击败敌人: " + str(enemy_defeated))
		
		if player.health <= 0:
			gut.p("玩家死亡！战斗结束")
			break
		
		var wait_start = Time.get_ticks_msec()
		while lianli_system.is_waiting and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
		var wait_time = (Time.get_ticks_msec() - wait_start) / 1000.0
		
		if wait_time > 0.001:
			gut.p("等待下一场战斗, 耗时: " + str(wait_time) + "秒")
		
		if not lianli_system.is_in_lianli:
			gut.p("历练结束")
			break
	
	var total_test_time = (Time.get_ticks_msec() - test_start_time) / 1000.0
	gut.p("========== 场景①测试结束 ==========")
	gut.p("总耗时: " + str(total_test_time) + "秒")
	gut.p("打倒怪物数: " + str(battle_count))
	gut.p("玩家最终气血: " + str(int(player.health)))
	
	lianli_system.set_lianli_speed(1.0)
	
	assert_lt(total_test_time, 10.0, "场景①总耗时应小于10秒")
	assert_lte(battle_count, 2, "炼气一层玩家最多打倒2个怪物")
	assert_eq(int(player.health), 0, "玩家应死亡")
	assert_false(lianli_system.is_in_lianli, "应自动退出历练区域")

#endregion

#region 场景②: 炼气五层玩家 + 基础拳法挑战炼气外围

func test_qi_level5_with_spell_vs_outer_area():
	if not _check_systems_available():
		return
	
	player.realm = "炼气期"
	player.realm_level = 5
	player.apply_realm_stats()
	player.health = player.get_final_max_health()
	
	var max_health = int(player.get_final_max_health())
	
	lianli_system.set_lianli_speed(10.0)
	
	gut.p("========== 场景②: 炼气五层玩家 + 基础拳法挑战炼气外围 ==========")
	gut.p("战斗倍速: 10x")
	gut.p("玩家境界: " + player.realm + " " + str(player.realm_level) + "层")
	gut.p("玩家气血: " + str(int(player.health)) + "/" + str(max_health))
	gut.p("玩家攻击: " + str(int(player.get_final_attack())))
	gut.p("玩家防御: " + str(int(player.get_final_defense())))
	gut.p("玩家速度: " + str(player.get_final_speed()))
	
	assert_eq(max_health, 76, "炼气五层最大气血应为76")
	
	if spell_system and spell_system.player_spells.has("basic_fist"):
		spell_system.obtain_spell("basic_fist")
		spell_system.equip_spell("basic_fist")
		gut.p("已装备术法: 基础拳法")
	
	var initial_stones = inventory.get_item_count("spirit_stone")
	gut.p("初始灵石: " + str(initial_stones))
	
	lianli_system.set_continuous_lianli(true)
	var started = lianli_system.start_lianli_in_area("qi_refining_outer")
	assert_true(started, "应成功进入历练区域")
	
	var battle_count = 0
	var min_battles = 5
	var max_total_wait = 180.0
	var total_wait = 0.0
	var test_start_time = Time.get_ticks_msec()
	
	while battle_count < 10 and total_wait < max_total_wait:
		var battle_start = Time.get_ticks_msec()
		
		while not lianli_system.is_in_battle and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
		
		if not lianli_system.is_in_battle:
			break
		
		var enemy = lianli_system.current_enemy
		if enemy.size() > 0:
			gut.p("---------- 战斗 " + str(battle_count + 1) + " 开始 ----------")
			gut.p("敌人: " + str(enemy.get("name", "未知")) + " Lv." + str(enemy.get("level", 0)))
			gut.p("敌人气血: " + str(int(enemy.get("current_health", 0))) + "/" + str(int(enemy.get("health", 0))))
			gut.p("玩家气血: " + str(int(player.health)))
		
		var last_player_health = player.health
		var last_enemy_health = enemy.get("current_health", 0) if enemy.size() > 0 else 0
		
		while lianli_system.is_in_battle and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
			
			if enemy.size() > 0:
				var current_enemy_health = enemy.get("current_health", 0)
				var current_player_health = player.health
				
				if current_enemy_health != last_enemy_health:
					gut.p("  敌人气血变化: " + str(int(last_enemy_health)) + " -> " + str(int(current_enemy_health)))
					last_enemy_health = current_enemy_health
				
				if current_player_health != last_player_health:
					gut.p("  玩家气血变化: " + str(int(last_player_health)) + " -> " + str(int(current_player_health)))
					last_player_health = current_player_health
		
		var battle_time = (Time.get_ticks_msec() - battle_start) / 1000.0
		
		var enemy_defeated = false
		if enemy.size() > 0 and enemy.get("current_health", 0) <= 0:
			enemy_defeated = true
			battle_count += 1
		
		gut.p("---------- 战斗 " + str(battle_count) + " 结束 ----------")
		gut.p("耗时: " + str(battle_time) + "秒")
		gut.p("玩家气血: " + str(int(player.health)))
		gut.p("击败敌人: " + str(enemy_defeated))
		
		if player.health <= 0:
			gut.p("玩家死亡！战斗结束")
			break
		
		var wait_start = Time.get_ticks_msec()
		while lianli_system.is_waiting and total_wait < max_total_wait:
			await get_tree().process_frame
			total_wait += get_process_delta_time()
		var wait_time = (Time.get_ticks_msec() - wait_start) / 1000.0
		
		if wait_time > 0.001:
			gut.p("等待下一场战斗, 耗时: " + str(wait_time) + "秒")
		
		if not lianli_system.is_in_lianli:
			gut.p("历练结束")
			break
	
	var total_test_time = (Time.get_ticks_msec() - test_start_time) / 1000.0
	var final_stones = inventory.get_item_count("spirit_stone")
	
	gut.p("========== 场景②测试结束 ==========")
	gut.p("总耗时: " + str(total_test_time) + "秒")
	gut.p("打倒怪物数: " + str(battle_count))
	gut.p("玩家最终气血: " + str(int(player.health)))
	gut.p("获得灵石: " + str(final_stones - initial_stones))
	
	lianli_system.set_lianli_speed(1.0)
	
	assert_gte(battle_count, min_battles, "炼气五层玩家应至少打倒5个怪物")
	assert_gt(int(player.health), 0, "玩家应存活")
	assert_gt(final_stones, initial_stones, "应获得灵石掉落")

#endregion

#region 场景③: 筑基三层玩家挑战破境草洞穴

# func test_foundation_level3_vs_herb_cave():
# 	if not _check_systems_available():
# 		return
# 	
# 	player.realm = "筑基期"
# 	player.realm_level = 3
# 	player.apply_realm_stats()
# 	player.health = player.get_final_max_health()
# 	
# 	var max_health = int(player.get_final_max_health())
# 	assert_eq(max_health, 302, "筑基三层最大气血应为302")
# 	
# 	if spell_system:
# 		if spell_system.player_spells.has("basic_fist"):
# 			spell_system.obtain_spell("basic_fist")
# 			spell_system.equip_spell("basic_fist")
# 		if spell_system.player_spells.has("basic_defense"):
# 			spell_system.obtain_spell("basic_defense")
# 			spell_system.equip_spell("basic_defense")
# 	
# 	var initial_herb = inventory.get_item_count("foundation_herb")
# 	var initial_stones = inventory.get_item_count("spirit_stone")
# 	var initial_count = lianli_system.get_daily_dungeon_count("foundation_herb_cave")
# 	
# 	lianli_system.set_continuous_lianli(false)
# 	var started1 = lianli_system.start_lianli_in_area("foundation_herb_cave")
# 	assert_true(started1, "第一次应成功进入")
# 	
# 	var total_wait = 0.0
# 	while lianli_system.is_in_battle and total_wait < 60.0:
# 		await get_tree().process_frame
# 		total_wait += get_process_delta_time()
# 	
# 	await get_tree().create_timer(1.0).timeout
# 	
# 	var count_after_first = lianli_system.get_daily_dungeon_count("foundation_herb_cave")
# 	assert_lt(count_after_first, initial_count, "第一次应消耗次数")
# 	
# 	lianli_system.set_continuous_lianli(true)
# 	
# 	for i in range(2):
# 		if lianli_system.get_daily_dungeon_count("foundation_herb_cave") <= 0:
# 			break
# 		
# 		var started = lianli_system.start_lianli_in_area("foundation_herb_cave")
# 		if not started:
# 			break
# 		
# 		total_wait = 0.0
# 		while lianli_system.is_in_battle and total_wait < 60.0:
# 			await get_tree().process_frame
# 			total_wait += get_process_delta_time()
# 		
# 		await get_tree().create_timer(1.0).timeout
# 	
# 	var final_herb = inventory.get_item_count("foundation_herb")
# 	var final_stones = inventory.get_item_count("spirit_stone")
# 	var final_count = lianli_system.get_daily_dungeon_count("foundation_herb_cave")
# 	
# 	assert_gt(final_herb, initial_herb, "应获得破境草")
# 	assert_gt(final_stones, initial_stones, "应获得灵石")
# 	assert_lte(final_count, 0, "次数应用完")

#endregion

#region 场景④: 筑基一层玩家连续挑战无尽塔

# func test_foundation_level1_vs_endless_tower():
# 	if not _check_systems_available():
# 		return
# 	
# 	player.realm = "筑基期"
# 	player.realm_level = 1
# 	player.apply_realm_stats()
# 	player.health = player.get_final_max_health()
# 	
# 	var max_health = int(player.get_final_max_health())
# 	assert_eq(max_health, 250, "筑基一层最大气血应为250")
# 	
# 	if spell_system and spell_system.player_spells.has("basic_fist"):
# 		spell_system.obtain_spell("basic_fist")
# 		spell_system.equip_spell("basic_fist")
# 	
# 	lianli_system.tower_highest_floor = 0
# 	
# 	lianli_system.set_continuous_lianli(true)
# 	var started = lianli_system.start_endless_tower()
# 	assert_true(started, "应成功进入无尽塔")
# 	assert_true(lianli_system.is_in_tower, "应在无尽塔中")
# 	assert_eq(lianli_system.get_current_tower_floor(), 1, "应从第1层开始")
# 	
# 	var max_total_wait = 600.0
# 	var total_wait = 0.0
# 	
# 	while total_wait < max_total_wait:
# 		while lianli_system.is_in_battle and total_wait < max_total_wait:
# 			await get_tree().process_frame
# 			total_wait += get_process_delta_time()
# 		
# 		if player.health <= 0:
# 			break
# 		
# 		while lianli_system.is_waiting and total_wait < max_total_wait:
# 			await get_tree().process_frame
# 			total_wait += get_process_delta_time()
# 		
# 		if not lianli_system.is_in_lianli:
# 			break
# 	
# 	var final_floor = lianli_system.tower_highest_floor
# 	var remaining_health = int(player.health)
# 	
# 	gut.p("无尽塔测试结果 - 最高层数: " + str(final_floor) + ", 剩余气血: " + str(remaining_health))
# 	
# 	assert_gt(final_floor, 0, "应记录最高层数")
# 	
# 	if player.health > 0:
# 		lianli_system.end_lianli()

#endregion
