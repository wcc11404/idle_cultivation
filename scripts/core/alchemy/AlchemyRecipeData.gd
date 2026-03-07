class_name AlchemyRecipeData extends Node

# 丹方配置数据
var recipes: Dictionary = {}

func _ready():
	_load_recipes()

# 加载丹方数据
func _load_recipes():
	var file = FileAccess.open("res://scripts/core/alchemy/recipes.json", FileAccess.READ)
	if file:
		var json_content = file.get_as_text()
		var data = JSON.parse_string(json_content)
		if data and data.has("recipes"):
			recipes = data["recipes"]
		file.close()
	else:
		print("Error loading recipes.json")

# 获取丹方数据
func get_recipe_data(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})

# 获取所有丹方ID列表
func get_all_recipe_ids() -> Array:
	return recipes.keys()

# 获取丹方名称
func get_recipe_name(recipe_id: String) -> String:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("name", "未知丹方")

# 获取丹方基础成功值
func get_recipe_success_value(recipe_id: String) -> int:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("success_value", 0)

# 获取丹方基础耗时
func get_recipe_base_time(recipe_id: String) -> float:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("base_time", 0.0)

# 获取丹方材料需求
func get_recipe_materials(recipe_id: String) -> Dictionary:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("materials", {}).duplicate(true)

# 获取丹方成品ID
func get_recipe_product(recipe_id: String) -> String:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("product", "")

# 获取丹方成品数量
func get_recipe_product_count(recipe_id: String) -> int:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("product_count", 1)

# 获取丹方灵气消耗
func get_recipe_spirit_energy(recipe_id: String) -> int:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("spirit_energy", 0)
