extends TestBase

# 测试炼丹系统核心功能

func get_test_name() -> String:
	return "AlchemySystem"

func run_tests() -> Dictionary:
	var results = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"tests": []
	}
	
	# 测试1: 学习丹方
	results.tests.append_array(_test_learn_recipe())
	
	# 测试2: 成功率计算
	results.tests.append_array(_test_success_rate())
	
	# 测试3: 炼制耗时计算
	results.tests.append_array(_test_craft_time())
	
	# 测试4: 材料检查
	results.tests.append_array(_test_material_check())
	
	# 测试5: 炼制流程
	results.tests.append_array(_test_crafting())
	
	# 统计结果
	for test in results.tests:
		results.total += 1
		if test.passed:
			results.passed += 1
		else:
			results.failed += 1
	
	return results

# 测试学习丹方
func _test_learn_recipe() -> Array:
	var tests = []
	
	# 创建模拟对象
	var player = PlayerData.new()
	player.learned_recipes = []
	
	var recipe_data = AlchemyRecipeData.new()
	
	var alchemy_system = AlchemySystem.new()
	alchemy_system.set_player(player)
	alchemy_system.set_recipe_data(recipe_data)
	
	# 测试学习新丹方
	var result1 = alchemy_system.learn_recipe("health_pill")
	tests.append({
		"name": "学习新丹方",
		"passed": result1 and player.learned_recipes.has("health_pill"),
		"message": "成功学习补血丹丹方" if result1 else "学习丹方失败"
	})
	
	# 测试重复学习
	var result2 = alchemy_system.learn_recipe("health_pill")
	tests.append({
		"name": "重复学习丹方",
		"passed": not result2,
		"message": "重复学习被拒绝" if not result2 else "重复学习应该被拒绝"
	})
	
	# 测试学习不存在丹方
	var result3 = alchemy_system.learn_recipe("non_existent")
	tests.append({
		"name": "学习不存在丹方",
		"passed": not result3,
		"message": "不存在丹方学习失败" if not result3 else "不存在丹方应该学习失败"
	})
	
	return tests

# 测试成功率计算
func _test_success_rate() -> Array:
	var tests = []
	
	var player = PlayerData.new()
	player.learned_recipes = ["health_pill"]
	
	var recipe_data = AlchemyRecipeData.new()
	
	var spell_data = SpellData.new()
	var spell_system = SpellSystem.new()
	spell_system.set_spell_data(spell_data)
	
	var alchemy_system = AlchemySystem.new()
	alchemy_system.set_player(player)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_spell_system(spell_system)
	
	# 测试基础成功率（无术法、无丹炉）
	var rate1 = alchemy_system.calculate_success_rate("health_pill")
	tests.append({
		"name": "基础成功率",
		"passed": rate1 == 20,
		"message": "补血丹基础成功率20%" if rate1 == 20 else "基础成功率错误: " + str(rate1)
	})
	
	# 测试有丹炉时的成功率
	alchemy_system.equip_furnace("alchemy_furnace")
	var rate2 = alchemy_system.calculate_success_rate("health_pill")
	tests.append({
		"name": "有丹炉成功率",
		"passed": rate2 == 30,
		"message": "有丹炉成功率30%" if rate2 == 30 else "有丹炉成功率错误: " + str(rate2)
	})
	
	return tests

# 测试炼制耗时计算
func _test_craft_time() -> Array:
	var tests = []
	
	var player = PlayerData.new()
	
	var recipe_data = AlchemyRecipeData.new()
	
	var spell_data = SpellData.new()
	var spell_system = SpellSystem.new()
	spell_system.set_spell_data(spell_data)
	
	var alchemy_system = AlchemySystem.new()
	alchemy_system.set_player(player)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_spell_system(spell_system)
	
	# 测试基础耗时（无术法、无丹炉）
	var time1 = alchemy_system.calculate_craft_time("health_pill")
	tests.append({
		"name": "基础耗时",
		"passed": abs(time1 - 5.0) < 0.01,
		"message": "补血丹基础耗时5秒" if abs(time1 - 5.0) < 0.01 else "基础耗时错误: " + str(time1)
	})
	
	# 测试有丹炉时的耗时
	alchemy_system.equip_furnace("alchemy_furnace")
	var time2 = alchemy_system.calculate_craft_time("health_pill")
	# 速度 = 1 + 0.1 = 1.1, 耗时 = 5 / 1.1 = 4.545...
	tests.append({
		"name": "有丹炉耗时",
		"passed": abs(time2 - 4.545) < 0.1,
		"message": "有丹炉耗时约4.55秒" if abs(time2 - 4.545) < 0.1 else "有丹炉耗时错误: " + str(time2)
	})
	
	return tests

# 测试材料检查
func _test_material_check() -> Array:
	var tests = []
	
	var player = PlayerData.new()
	player.learned_recipes = ["health_pill"]
	
	var recipe_data = AlchemyRecipeData.new()
	
	var inventory = Inventory.new()
	inventory.items = {
		"mat_herb": {"count": 5}
	}
	
	var alchemy_system = AlchemySystem.new()
	alchemy_system.set_player(player)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_inventory(inventory)
	
	# 测试材料足够
	var check1 = alchemy_system.check_materials("health_pill", 1)
	tests.append({
		"name": "材料足够",
		"passed": check1.enough,
		"message": "材料足够可以炼制" if check1.enough else "材料检查错误"
	})
	
	# 测试材料不足
	var check2 = alchemy_system.check_materials("health_pill", 10)
	tests.append({
		"name": "材料不足",
		"passed": not check2.enough,
		"message": "材料不足无法炼制" if not check2.enough else "材料不足检查错误"
	})
	
	return tests

# 测试炼制流程
func _test_crafting() -> Array:
	var tests = []
	
	var player = PlayerData.new()
	player.learned_recipes = ["health_pill"]
	
	var recipe_data = AlchemyRecipeData.new()
	
	var inventory = Inventory.new()
	inventory.items = {
		"mat_herb": {"count": 10}
	}
	
	var spell_data = SpellData.new()
	var spell_system = SpellSystem.new()
	spell_system.set_spell_data(spell_data)
	
	var alchemy_system = AlchemySystem.new()
	alchemy_system.set_player(player)
	alchemy_system.set_recipe_data(recipe_data)
	alchemy_system.set_inventory(inventory)
	alchemy_system.set_spell_system(spell_system)
	
	# 测试开始炼制
	var result = alchemy_system.start_crafting_batch("health_pill", 2)
	tests.append({
		"name": "开始炼制",
		"passed": result.success,
		"message": "成功开始炼制" if result.success else "开始炼制失败: " + result.reason
	})
	
	if result.success:
		# 检查材料是否扣除（第一颗丹药的材料）
		var herb_count = inventory.get_item_count("mat_herb")
		tests.append({
			"name": "材料扣除",
			"passed": herb_count == 8,  # 10 - 2 = 8 (第一颗丹药扣除2个)
			"message": "材料已扣除第一颗，剩余8个" if herb_count == 8 else "材料扣除错误: " + str(herb_count)
		})
		
		# 检查是否处于炼制状态
		tests.append({
			"name": "炼制状态",
			"passed": alchemy_system.is_crafting,
			"message": "正在炼制中" if alchemy_system.is_crafting else "炼制状态错误"
		})
	
	return tests
