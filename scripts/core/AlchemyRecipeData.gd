class_name AlchemyRecipeData extends Node

# 丹方配置数据
var recipes: Dictionary = {
	"health_pill": {
		"id": "health_pill",
		"name": "补血丹",
		"recipe_name": "补血丹丹方",
		"success_value": 50,
		"base_time": 3.0,
		"materials": {
			"mat_herb": 2
		},
		"spirit_energy": 1,
		"product": "health_pill",
		"product_count": 1
	},
	"spirit_pill": {
		"id": "spirit_pill",
		"name": "补气丹",
		"recipe_name": "补气丹丹方",
		"success_value": 40,
		"base_time": 10.0,
		"materials": {
			"mat_herb": 10
		},
		"spirit_energy": 1,
		"product": "spirit_pill",
		"product_count": 1
	},
	"foundation_pill": {
		"id": "foundation_pill",
		"name": "筑基丹",
		"recipe_name": "筑基丹丹方",
		"success_value": 30,
		"base_time": 30.0,
		"materials": {
			"foundation_herb": 3,
			"mat_herb": 10
		},
		"spirit_energy": 5,
		"product": "foundation_pill",
		"product_count": 1
	},
	"golden_core_pill": {
		"id": "golden_core_pill",
		"name": "金丹丹",
		"recipe_name": "金丹丹丹方",
		"success_value": 20,
		"base_time": 40.0,
		"materials": {
			"foundation_herb": 3,
			"foundation_pill": 3,
			"mat_herb": 10
		},
		"spirit_energy": 10,
		"product": "golden_core_pill",
		"product_count": 1
	}
}

func _ready():
	pass

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

# 获取丹方完整名称（包含"丹方"二字）
func get_recipe_full_name(recipe_id: String) -> String:
	var recipe = get_recipe_data(recipe_id)
	return recipe.get("recipe_name", "未知丹方")

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
