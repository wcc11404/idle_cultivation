class_name AlchemySystem extends Node

# 炼丹系统核心

# 信号
signal recipe_learned(recipe_id: String)
signal crafting_started(recipe_id: String, count: int)
signal crafting_finished(recipe_id: String, success_count: int, fail_count: int)
signal log_message(message: String)  # 炼丹日志信号

# 引用
var player: Node = null
var recipe_data: Node = null
var spell_system: Node = null
var inventory: Node = null

# 炼丹状态
var is_crafting: bool = false
var current_craft_recipe: String = ""
var current_craft_count: int = 0
var current_craft_progress: float = 0.0

func _ready():
	pass

func set_player(player_node: Node):
	player = player_node

func set_recipe_data(recipe_data_node: Node):
	recipe_data = recipe_data_node

func set_spell_system(spell_sys: Node):
	spell_system = spell_sys

func set_inventory(inv: Node):
	inventory = inv

# 学习丹方（使用丹方道具时调用）
func learn_recipe(recipe_id: String) -> bool:
	if not player:
		return false
	
	# 检查丹方是否存在
	if not recipe_data or recipe_data.get_recipe_data(recipe_id).is_empty():
		return false
	
	# 检查是否已学会
	if recipe_id in player.learned_recipes:
		return false
	
	# 添加到已学会列表
	player.learned_recipes.append(recipe_id)
	recipe_learned.emit(recipe_id)
	return true

# 检查是否学会丹方
func has_learned_recipe(recipe_id: String) -> bool:
	if not player:
		return false
	return recipe_id in player.learned_recipes

# 获取已学会的丹方列表
func get_learned_recipes() -> Array:
	if not player:
		return []
	return player.learned_recipes.duplicate()

# 检查是否拥有丹炉
func has_furnace() -> bool:
	if not player:
		return false
	return player.has_alchemy_furnace

# 获取炼丹术加成
func get_alchemy_bonus() -> Dictionary:
	var bonus = {
		"success_bonus": 0,
		"speed_rate": 0.0,
		"level": 0,
		"obtained": false
	}
	
	if not spell_system:
		return bonus
	
	# 获取炼丹术法信息
	var spell_info = spell_system.get_spell_info("alchemy")
	if spell_info.is_empty() or not spell_info.obtained:
		return bonus
	
	bonus.obtained = true
	var level = spell_info.level
	bonus.level = level
	
	if level > 0:
		var level_data = spell_system.spell_data.get_spell_level_data("alchemy", level)
		var effect = level_data.get("effect", {})
		bonus.success_bonus = effect.get("success_bonus", 0)
		bonus.speed_rate = effect.get("speed_rate", 0.0)
	
	return bonus

# 获取丹炉加成
func get_furnace_bonus() -> Dictionary:
	var bonus = {
		"success_bonus": 0,
		"speed_rate": 0.0,
		"has_furnace": false
	}
	
	if not has_furnace():
		return bonus
	
	bonus.has_furnace = true
	# 初级丹炉固定加成
	bonus.success_bonus = 10
	bonus.speed_rate = 0.1
	
	return bonus

# 计算成功率（百分比）
func calculate_success_rate(recipe_id: String) -> int:
	if not recipe_data:
		return 0
	
	var base_value = recipe_data.get_recipe_success_value(recipe_id)
	var alchemy_bonus = get_alchemy_bonus()
	var furnace_bonus = get_furnace_bonus()
	
	var final_value = base_value + alchemy_bonus.success_bonus + furnace_bonus.success_bonus
	
	# 限制在1-100之间
	return clamp(final_value, 1, 100)

# 计算炼制耗时（秒/颗）
func calculate_craft_time(recipe_id: String) -> float:
	if not recipe_data:
		return 0.0
	
	var base_time = recipe_data.get_recipe_base_time(recipe_id)
	var alchemy_bonus = get_alchemy_bonus()
	var furnace_bonus = get_furnace_bonus()
	
	var final_speed = 1.0 + alchemy_bonus.speed_rate + furnace_bonus.speed_rate
	
	return base_time / final_speed

# 检查材料是否足够
func check_materials(recipe_id: String, count: int) -> Dictionary:
	var result = {
		"enough": false,
		"materials": {},
		"missing": []
	}
	
	if not recipe_data or not inventory:
		return result
	
	var materials = recipe_data.get_recipe_materials(recipe_id)
	
	for material_id in materials.keys():
		var material_count = materials[material_id]
		var required = material_count * count
		var has = inventory.get_item_count(material_id)
		result.materials[material_id] = {
			"required": required,
			"has": has,
			"enough": has >= required
		}
		
		if has < required:
			result.missing.append(material_id)
	
	result.enough = result.missing.is_empty()
	return result

# 开始炼制
func start_crafting(recipe_id: String, count: int) -> Dictionary:
	var result = {
		"success": false,
		"reason": "",
		"recipe_id": recipe_id,
		"count": count
	}
	
	# 检查是否学会丹方
	if not has_learned_recipe(recipe_id):
		result.reason = "未学会该丹方"
		return result
	
	# 检查是否正在炼制
	if is_crafting:
		result.reason = "正在炼制中"
		return result
	
	# 检查材料
	var material_check = check_materials(recipe_id, count)
	if not material_check.enough:
		result.reason = "材料不足"
		return result
	
	# 扣除材料
	var materials = recipe_data.get_recipe_materials(recipe_id)
	for material_id in materials.keys():
		var required = materials[material_id] * count
		inventory.remove_item(material_id, required)
	
	# 开始炼制
	is_crafting = true
	current_craft_recipe = recipe_id
	current_craft_count = count
	current_craft_progress = 0.0
	
	crafting_started.emit(recipe_id, count)
	log_message.emit("开炉炼丹，开始炼制 [" + recipe_data.get_recipe_name(recipe_id) + "]")
	
	# 执行炼制（立即完成，实际游戏中可以加入延时）
	_perform_crafting()
	
	result.success = true
	return result

# 执行炼制（计算成功/失败）
func _perform_crafting():
	if not is_crafting:
		return
	
	var success_count = 0
	var fail_count = 0
	var success_rate = calculate_success_rate(current_craft_recipe)
	
	for i in range(current_craft_count):
		var roll = randi() % 100 + 1  # 1-100
		if roll <= success_rate:
			success_count += 1
		else:
			fail_count += 1
	
	# 发放成品
	if success_count > 0 and inventory:
		var product = recipe_data.get_recipe_product(current_craft_recipe)
		inventory.add_item(product, success_count)
	
	# 失败时返还一半材料
	if fail_count > 0:
		var materials = recipe_data.get_recipe_materials(current_craft_recipe)
		for material_id in materials.keys():
			var required_per = materials[material_id]
			var return_count = ceil(required_per * fail_count * 0.5)
			if return_count > 0:
				inventory.add_item(material_id, return_count)
	
	# 增加炼丹术使用次数
	if spell_system:
		for i in range(current_craft_count):
			spell_system.add_spell_use_count("alchemy")
	
	# 结束炼制
	is_crafting = false
	crafting_finished.emit(current_craft_recipe, success_count, fail_count)
	current_craft_recipe = ""
	current_craft_count = 0
	current_craft_progress = 0.0

# 获取炼制预览信息
func get_craft_preview(recipe_id: String, count: int) -> Dictionary:
	var preview = {
		"recipe_id": recipe_id,
		"recipe_name": "",
		"count": count,
		"success_rate": 0,
		"craft_time": 0.0,
		"total_time": 0.0,
		"materials": {},
		"alchemy_bonus": {},
		"furnace_bonus": {},
		"can_craft": false,
		"reason": ""
	}
	
	if not recipe_data:
		preview.reason = "丹方数据未初始化"
		return preview
	
	if not has_learned_recipe(recipe_id):
		preview.reason = "未学会该丹方"
		return preview
	
	preview.recipe_name = recipe_data.get_recipe_name(recipe_id)
	preview.success_rate = calculate_success_rate(recipe_id)
	preview.craft_time = calculate_craft_time(recipe_id)
	preview.total_time = preview.craft_time * count
	var materials_check = check_materials(recipe_id, count)
	preview.materials = materials_check.materials
	preview.alchemy_bonus = get_alchemy_bonus()
	preview.furnace_bonus = get_furnace_bonus()
	preview.can_craft = materials_check.enough
	
	if not preview.can_craft:
		preview.reason = "材料不足"
	
	return preview

# 获取所有可炼制的丹方（已学会且材料足够）
func get_craftable_recipes() -> Array:
	var craftable = []
	
	if not player or not recipe_data:
		return craftable
	
	for recipe_id in player.learned_recipes:
		var preview = get_craft_preview(recipe_id, 1)
		if preview.can_craft:
			craftable.append(recipe_id)
	
	return craftable
