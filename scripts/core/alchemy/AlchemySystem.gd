class_name AlchemySystem extends Node

# 服务端权威改造后，AlchemySystem 仅保留炼丹配置/加成查询与状态容器职责。

const FURNACE_CONFIGS = {
	"alchemy_furnace": {
		"name": "初级丹炉",
		"success_bonus": 10,
		"speed_rate": 0.1
	}
}

var player: Node = null
var recipe_data: Node = null
var spell_system: Node = null
var inventory: Node = null

var equipped_furnace_id: String = ""
var learned_recipes: Array = []
var special_bonus_speed_rate: float = 0.0

func set_player(player_node: Node):
	player = player_node

func set_recipe_data(recipe_data_node: Node):
	recipe_data = recipe_data_node

func set_spell_system(spell_sys: Node):
	spell_system = spell_sys

func set_inventory(inv: Node):
	inventory = inv

func get_learned_recipes() -> Array:
	return learned_recipes.duplicate()

func get_alchemy_bonus() -> Dictionary:
	var bonus = {
		"success_bonus": 0,
		"speed_rate": 0.0,
		"level": 0,
		"obtained": false
	}
	if not spell_system:
		return bonus

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

func get_furnace_bonus() -> Dictionary:
	var bonus = {
		"success_bonus": 0,
		"speed_rate": 0.0,
		"has_furnace": false,
		"furnace_name": ""
	}
	if equipped_furnace_id.is_empty() or not FURNACE_CONFIGS.has(equipped_furnace_id):
		return bonus

	var config = FURNACE_CONFIGS.get(equipped_furnace_id, {})
	bonus.has_furnace = true
	bonus.success_bonus = config.get("success_bonus", 0)
	bonus.speed_rate = config.get("speed_rate", 0.0)
	bonus.furnace_name = config.get("name", "未知丹炉")
	return bonus

func calculate_success_rate(recipe_id: String) -> int:
	if not recipe_data:
		return 0
	var base_value = recipe_data.get_recipe_success_value(recipe_id)
	var alchemy_bonus = get_alchemy_bonus()
	var furnace_bonus = get_furnace_bonus()
	var final_value = base_value + alchemy_bonus.success_bonus + furnace_bonus.success_bonus
	return clamp(final_value, 1, 100)

func calculate_craft_time(recipe_id: String) -> float:
	if not recipe_data:
		return 0.0
	var base_time = recipe_data.get_recipe_base_time(recipe_id)
	var alchemy_bonus = get_alchemy_bonus()
	var furnace_bonus = get_furnace_bonus()
	var final_speed = 1.0 + alchemy_bonus.speed_rate + furnace_bonus.speed_rate + special_bonus_speed_rate
	return base_time / final_speed

func apply_save_data(data: Dictionary):
	equipped_furnace_id = data.get("equipped_furnace_id", "")
	learned_recipes = data.get("learned_recipes", [])
