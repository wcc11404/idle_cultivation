class_name SpellData extends Node

enum SpellType {
	BREATHING,    # 吐纳心法（1种）
	ACTIVE,       # 主动术法（攻击类）
	PASSIVE,      # 被动术法（开局自动释放）
	MISC          # 杂学术法
}

# 装备槽位限制
const MAX_ACTIVE_SPELLS = 2   # 主动术法最多装备2个
const MAX_PASSIVE_SPELLS = 2  # 被动术法最多装备2个

# 术法基础数据配置
# 数值规范：所有百分比、概率值都用小数存储（如0.25表示25%）
const SPELLS = {
	# 吐纳心法（1种）
	"basic_breathing": {
		"id": "basic_breathing",
		"name": "基础吐纳",
		"type": SpellType.BREATHING,
		"description": "修炼时每秒恢复{heal_percent}最大气血",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 1,
				"use_count_required": 50,
				"attribute_bonus": {"spirit_gain": 1.02},
				"effect": {"type": "passive_heal", "heal_percent": 0.002}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 200,
				"attribute_bonus": {"spirit_gain": 1.04},
				"effect": {"type": "passive_heal", "heal_percent": 0.004}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 500,
				"attribute_bonus": {"spirit_gain": 1.06},
				"effect": {"type": "passive_heal", "heal_percent": 0.006}
			}
		}
	},

	# 主动术法（2种）
	"basic_boxing_techniques": {
		"id": "basic_boxing_techniques",
		"name": "基础拳法",
		"type": SpellType.ACTIVE,
		"description": "战斗中{trigger_chance}概率释放，造成{damage_percent}攻击力的伤害",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 50,
				"attribute_bonus": {"attack": 1.02},
				"effect": {"type": "active_damage", "damage_percent": 1.10, "trigger_chance": 0.30}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 200,
				"attribute_bonus": {"attack": 1.04},
				"effect": {"type": "active_damage", "damage_percent": 1.15, "trigger_chance": 0.30}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 500,
				"attribute_bonus": {"attack": 1.06},
				"effect": {"type": "active_damage", "damage_percent": 1.20, "trigger_chance": 0.30}
			}
		}
	},
	"thunder_strike": {
		"id": "thunder_strike",
		"name": "雷击术",
		"type": SpellType.ACTIVE,
		"description": "战斗中{trigger_chance}概率释放，造成{damage_percent}攻击力的伤害",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 100,
				"use_count_required": 100,
				"attribute_bonus": {"attack": 1.02},
				"effect": {"type": "active_damage", "damage_percent": 1.30, "trigger_chance": 0.25}
			},
			2: {
				"spirit_cost": 300,
				"use_count_required": 300,
				"attribute_bonus": {"attack": 1.04},
				"effect": {"type": "active_damage", "damage_percent": 1.35, "trigger_chance": 0.25}
			},
			3: {
				"spirit_cost": 600,
				"use_count_required": 600,
				"attribute_bonus": {"attack": 1.06},
				"effect": {"type": "active_damage", "damage_percent": 1.40, "trigger_chance": 0.25}
			}
		}
	},

	# 被动术法（3种）
	"basic_defense": {
		"id": "basic_defense",
		"name": "基础防御",
		"type": SpellType.PASSIVE,
		"description": "战斗开始时，防御提升{buff_percent}",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 50,
				"attribute_bonus": {"defense": 1.02},
				"effect": {"type": "start_buff", "buff_type": "defense", "buff_percent": 0.15, "trigger_chance": 1.0, "log_effect": "防御提升15%"}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 200,
				"attribute_bonus": {"defense": 1.04},
				"effect": {"type": "start_buff", "buff_type": "defense", "buff_percent": 0.16, "trigger_chance": 1.0, "log_effect": "防御提升16%"}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 500,
				"attribute_bonus": {"defense": 1.06},
				"effect": {"type": "start_buff", "buff_type": "defense", "buff_percent": 0.17, "trigger_chance": 1.0, "log_effect": "防御提升17%"}
			}
		}
	},
	"basic_steps": {
		"id": "basic_steps",
		"name": "基础步法",
		"type": SpellType.PASSIVE,
		"description": "战斗开始时，速度+{buff_value}",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 50,
				"attribute_bonus": {"speed": 0.1},
				"effect": {"type": "start_buff", "buff_type": "speed", "buff_value": 0.1, "trigger_chance": 1.0, "log_effect": "速度+0.1"}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 200,
				"attribute_bonus": {"speed": 0.2},
				"effect": {"type": "start_buff", "buff_type": "speed", "buff_value": 0.2, "trigger_chance": 1.0, "log_effect": "速度+0.2"}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 500,
				"attribute_bonus": {"speed": 0.3},
				"effect": {"type": "start_buff", "buff_type": "speed", "buff_value": 0.3, "trigger_chance": 1.0, "log_effect": "速度+0.3"}
			}
		}
	},
	"basic_health": {
		"id": "basic_health",
		"name": "基础气血",
		"type": SpellType.PASSIVE,
		"description": "战斗开始时，气血和气血上限值提升{buff_percent}（本局战斗内生效）",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 50,
				"attribute_bonus": {"health": 1.02},
				"effect": {"type": "start_buff", "buff_type": "health", "buff_percent": 0.005, "trigger_chance": 1.0, "log_effect": "气血上限提升0.5%"}
			},
			2: {
				"spirit_cost": 360,
				"use_count_required": 200,
				"attribute_bonus": {"health": 1.04},
				"effect": {"type": "start_buff", "buff_type": "health", "buff_percent": 0.01, "trigger_chance": 1.0, "log_effect": "气血上限提升1%"}
			},
			3: {
				"spirit_cost": 1080,
				"use_count_required": 500,
				"attribute_bonus": {"health": 1.06},
				"effect": {"type": "start_buff", "buff_type": "health", "buff_percent": 0.015, "trigger_chance": 1.0, "log_effect": "气血上限提升1.5%"}
			}
		}
	},

	# 杂学术法（2种）
	"herb_gathering": {
		"id": "herb_gathering",
		"name": "灵草采集",
		"type": SpellType.MISC,
		"description": "采集效率提升{efficiency}倍，稀有灵草概率+{rare_chance}",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 50,
				"attribute_bonus": {"max_spirit": 1.02},
				"effect": {"type": "gathering", "efficiency": 1.1, "rare_chance": 0.05}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 200,
				"attribute_bonus": {"max_spirit": 1.04},
				"effect": {"type": "gathering", "efficiency": 1.2, "rare_chance": 0.08}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 500,
				"attribute_bonus": {"max_spirit": 1.06},
				"effect": {"type": "gathering", "efficiency": 1.3, "rare_chance": 0.12}
			}
		}
	},
	"alchemy": {
		"id": "alchemy",
		"name": "炼丹术",
		"type": SpellType.MISC,
		"description": "炼丹专精术法，成功值+{success_bonus}，炼丹速度+{speed_rate}%",
		"max_level": 3,
		"levels": {
			1: {
				"spirit_cost": 50,
				"use_count_required": 10,
				"attribute_bonus": {"max_spirit": 1.02},
				"effect": {"type": "alchemy", "success_bonus": 10, "speed_rate": 0.1}
			},
			2: {
				"spirit_cost": 200,
				"use_count_required": 30,
				"attribute_bonus": {"max_spirit": 1.04},
				"effect": {"type": "alchemy", "success_bonus": 20, "speed_rate": 0.2}
			},
			3: {
				"spirit_cost": 500,
				"use_count_required": 60,
				"attribute_bonus": {"max_spirit": 1.06},
				"effect": {"type": "alchemy", "success_bonus": 30, "speed_rate": 0.3}
			}
		}
	}
}

# 获取术法基础数据
func get_spell_data(spell_id: String) -> Dictionary:
	return SPELLS.get(spell_id, {})

# 获取术法名称
func get_spell_name(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return spell.get("name", "未知术法")

# 获取术法类型
func get_spell_type(spell_id: String) -> int:
	var spell = get_spell_data(spell_id)
	return spell.get("type", SpellType.ACTIVE)

# 获取术法类型名称
func get_spell_type_name(spell_type: int) -> String:
	match spell_type:
		SpellType.BREATHING:
			return "吐纳心法"
		SpellType.ACTIVE:
			return "主动术法"
		SpellType.PASSIVE:
			return "被动术法"
		SpellType.MISC:
			return "杂学术法"
		_:
			return "未知"

# 获取某等级的术法数据
func get_spell_level_data(spell_id: String, level: int) -> Dictionary:
	var spell = get_spell_data(spell_id)
	var levels = spell.get("levels", {})
	return levels.get(level, {})

# 获取所有术法ID列表
func get_all_spell_ids() -> Array:
	return SPELLS.keys()

# 按类型获取术法ID列表
func get_spell_ids_by_type(spell_type: int) -> Array:
	var result = []
	for spell_id in SPELLS.keys():
		if SPELLS[spell_id].get("type") == spell_type:
			result.append(spell_id)
	return result

# 获取装备槽位上限（-1表示无限制）
func get_equipment_limit(spell_type: int) -> int:
	match spell_type:
		SpellType.ACTIVE:
			return MAX_ACTIVE_SPELLS
		SpellType.PASSIVE:
			return MAX_PASSIVE_SPELLS
		SpellType.MISC:
			return -1  # 杂学术法无装备限制
		_:
			return 1  # 其他类型默认1个
