class_name LianliAreaData extends Node

# 普通历练区域配置
const NORMAL_AREAS = {
	"qi_refining_outer": {
		"name": "炼气期外围森林",
		"description": "最外围的森林，妖兽实力极弱，适合新手历练和长时间挂机",
		"enemies": [
			{
				"template": "wolf",
				"min_level": 2, "max_level": 4, "weight": 40,
				"drops": {"spirit_stone": {"min": 1, "max": 1, "chance": 1.0}}
			},
			{
				"template": "snake",
				"min_level": 2, "max_level": 4, "weight": 30,
				"drops": {"spirit_stone": {"min": 1, "max": 1, "chance": 1.0}}
			},
			{
				"template": "boar",
				"min_level": 2, "max_level": 4, "weight": 30,
				"drops": {"spirit_stone": {"min": 1, "max": 2, "chance": 1.0}}
			}
		]
	},
	
	"qi_refining_inner": {
		"name": "炼气期内围山谷",
		"description": "妖兽实力适中，偶尔能遇到强大的狼王，是炼气期修士的主要历练场所",
		"enemies": [
			{
				"template": "wolf",
				"min_level": 4, "max_level": 8, "weight": 35,
				"drops": {"spirit_stone": {"min": 1, "max": 2, "chance": 1.0}}
			},
			{
				"template": "snake",
				"min_level": 4, "max_level": 8, "weight": 25,
				"drops": {"spirit_stone": {"min": 1, "max": 2, "chance": 1.0}}
			},
			{
				"template": "boar",
				"min_level": 4, "max_level": 8, "weight": 30,
				"drops": {"spirit_stone": {"min": 1, "max": 3, "chance": 1.0}}
			},
			{
				"template": "iron_back_wolf",
				"min_level": 5, "max_level": 8, "weight": 10,
				"drops": {
					"spirit_stone": {"min": 3, "max": 5, "chance": 1.0},
					"spell_basic_defense": {"min": 1, "max": 1, "chance": 0.3}
				}
			}
		]
	},
	
	"foundation_outer": {
		"name": "筑基期外围荒原",
		"description": "荒原上栖息着筑基初期的妖兽，实力远超炼气期",
		"enemies": [
			{
				"template": "wolf",
				"min_level": 14, "max_level": 18, "weight": 40,
				"drops": {"spirit_stone": {"min": 3, "max": 5, "chance": 1.0}}
			},
			{
				"template": "snake",
				"min_level": 14, "max_level": 18, "weight": 20,
				"drops": {"spirit_stone": {"min": 3, "max": 5, "chance": 1.0}}
			},
			{
				"template": "boar",
				"min_level": 14, "max_level": 18, "weight": 40,
				"drops": {"spirit_stone": {"min": 3, "max": 6, "chance": 1.0}}
			}
		]
	},
	
	"foundation_inner": {
		"name": "筑基期内围沼泽",
		"description": "沼泽深处的妖兽更加凶猛，偶尔能遇到狼王",
		"enemies": [
			{
				"template": "wolf",
				"min_level": 18, "max_level": 23, "weight": 35,
				"drops": {"spirit_stone": {"min": 4, "max": 6, "chance": 1.0}}
			},
			{
				"template": "snake",
				"min_level": 18, "max_level": 23, "weight": 25,
				"drops": {"spirit_stone": {"min": 4, "max": 6, "chance": 1.0}}
			},
			{
				"template": "boar",
				"min_level": 18, "max_level": 23, "weight": 30,
				"drops": {"spirit_stone": {"min": 4, "max": 7, "chance": 1.0}}
			},
			{
				"template": "iron_back_wolf",
				"min_level": 18, "max_level": 20, "weight": 10,
				"drops": {
					"spirit_stone": {"min": 8, "max": 10, "chance": 1.0},
					"spell_basic_health": {"min": 1, "max": 1, "chance": 0.2}
				}
			}
		]
	}
}

# 特殊区域配置（BOSS区域）
const SPECIAL_AREAS = {
	"foundation_herb_cave": {
		"name": "破境草洞穴",
		"description": "神秘的洞穴，由强大的看守者守护",
		"is_single_boss": true,
		"enemies": [
			{
				"template": "herb_guardian",
				"min_level": 10, "max_level": 10, "weight": 100,
				"drops": {}
			}
		],
		"special_drops": {
			"foundation_herb": 10,
			"spirit_stone": 20
		}
	}
}

# 获取所有普通区域
func get_normal_areas() -> Dictionary:
	return NORMAL_AREAS.duplicate()

# 获取所有特殊区域
func get_special_areas() -> Dictionary:
	return SPECIAL_AREAS.duplicate()

# 获取所有区域（普通+特殊）
func get_all_areas() -> Dictionary:
	var all_areas = NORMAL_AREAS.duplicate()
	for area_id in SPECIAL_AREAS.keys():
		all_areas[area_id] = SPECIAL_AREAS[area_id]
	return all_areas

# 获取普通区域ID列表
func get_normal_area_ids() -> Array:
	return NORMAL_AREAS.keys()

# 获取特殊区域ID列表
func get_special_area_ids() -> Array:
	return SPECIAL_AREAS.keys()

# 获取所有区域ID列表
func get_all_area_ids() -> Array:
	var ids = []
	ids.append_array(NORMAL_AREAS.keys())
	ids.append_array(SPECIAL_AREAS.keys())
	return ids

# 获取区域数据
func get_area_data(area_id: String) -> Dictionary:
	if NORMAL_AREAS.has(area_id):
		return NORMAL_AREAS[area_id].duplicate()
	if SPECIAL_AREAS.has(area_id):
		return SPECIAL_AREAS[area_id].duplicate()
	return {}

# 获取区域名称
func get_area_name(area_id: String) -> String:
	if NORMAL_AREAS.has(area_id):
		return NORMAL_AREAS[area_id].get("name", "未知区域")
	if SPECIAL_AREAS.has(area_id):
		return SPECIAL_AREAS[area_id].get("name", "未知区域")
	return "未知区域"

# 获取区域描述
func get_area_description(area_id: String) -> String:
	if NORMAL_AREAS.has(area_id):
		return NORMAL_AREAS[area_id].get("description", "")
	if SPECIAL_AREAS.has(area_id):
		return SPECIAL_AREAS[area_id].get("description", "")
	return ""

# 检查是否是普通区域
func is_normal_area(area_id: String) -> bool:
	return NORMAL_AREAS.has(area_id)

# 检查是否是特殊区域（BOSS区域）
func is_special_area(area_id: String) -> bool:
	return SPECIAL_AREAS.has(area_id)

# 检查是否是单BOSS区域
func is_single_boss_area(area_id: String) -> bool:
	if SPECIAL_AREAS.has(area_id):
		return SPECIAL_AREAS[area_id].get("is_single_boss", false)
	return false

# 获取特殊掉落
func get_special_drops(area_id: String) -> Dictionary:
	if SPECIAL_AREAS.has(area_id):
		return SPECIAL_AREAS[area_id].get("special_drops", {}).duplicate()
	return {}

# 随机获取敌人配置
func get_random_enemy_config(area_id: String) -> Dictionary:
	var area = get_area_data(area_id)
	if area.is_empty():
		return {}
	
	var enemies = area.get("enemies", [])
	if enemies.is_empty():
		return {}
	
	var total_weight = 0
	for enemy in enemies:
		total_weight += enemy.get("weight", 0)
	
	if total_weight <= 0:
		return enemies[0].duplicate()
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for enemy in enemies:
		current_weight += enemy.get("weight", 0)
		if random_value < current_weight:
			return enemy.duplicate()
	
	return enemies[0].duplicate()

# 获取敌人列表
func get_enemies_list(area_id: String) -> Array:
	var area = get_area_data(area_id)
	return area.get("enemies", []).duplicate()
