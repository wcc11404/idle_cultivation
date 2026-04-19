class_name AttributeCalculator

# 属性计算器 - 统一管理所有能力值的计算
# 提供静态最终能力值和战斗最终能力值的计算

# ==================== 公共数值格式化函数 ====================

## 默认格式化：保留两位小数，去除尾0
# 1.50 -> "1.5", 2.00 -> "2", 1.05 -> "1.05"
static func format_default(value: float) -> String:
	if abs(value) >= 1000.0:
		return _format_compact(value, 1)
	return _trim_to_fixed(value, 2)

static func _trim_to_fixed(value: float, fixed: int) -> String:
	var pattern = "%." + str(max(0, fixed)) + "f"
	var result = pattern % value
	while result.find(".") != -1 and result.ends_with("0"):
		result = result.substr(0, result.length() - 1)
	if result.ends_with("."):
		result = result.substr(0, result.length() - 1)
	return result

static func _format_compact(value: float, decimal_places: int = 1) -> String:
	var abs_value = abs(value)
	if abs_value >= 1000000000.0:
		return _trim_to_fixed(value / 1000000000.0, decimal_places) + "B"
	if abs_value >= 1000000.0:
		return _trim_to_fixed(value / 1000000.0, decimal_places) + "M"
	if abs_value >= 1000.0:
		return _trim_to_fixed(value / 1000.0, decimal_places) + "K"
	return _trim_to_fixed(value, 2)

## 百分比格式化：乘100，保留两位小数，去除尾0，加%
# 0.15 -> "15%", 0.005 -> "0.5%", 1.10 -> "110%"
static func format_percent(value: float) -> String:
	var percent = value * 100.0
	return _trim_to_fixed(percent, 2) + "%"

## 保留一位小数，去除尾0
# 50.5 -> "50.5", 50.0 -> "50"
static func format_one_decimal(value: float) -> String:
	return _trim_to_fixed(value, 1)

## 保留整数
# 255.7 -> "256"
static func format_integer(value: float) -> String:
	return str(int(round(value)))

## 攻击/防御格式化
static func format_attack_defense(value: float) -> String:
	return format_default(value)

## 伤害值格式化
static func format_damage(value: float) -> String:
	return format_default(value)

## 存档格式化：保留4位小数，去除尾0
# 50.5000 -> "50.5", 100.0000 -> "100", 0.0020 -> "0.002"
static func format_for_save(value: float) -> String:
	return _trim_to_fixed(value, 4)

## 格式化速度显示（保留两位小数，去除尾0）- 兼容旧代码
static func format_speed(value: float) -> String:
	return format_default(value)

## 格式化灵气获取速度显示（保留两位小数，去除尾0）- 兼容旧代码
static func format_spirit_gain_speed(value: float) -> String:
	return format_default(value)

## 格式化生命/灵气显示（保留统一规则）- 兼容旧代码
static func format_health_spirit(value: float) -> String:
	return format_default(value)

# ==================== 静态最终能力值计算（返回float） ====================
# 静态最终能力值 = 基础值 + 境界加成 + 术法加成 + 装备加成 + 功法加成 + 丹药加成

## 计算最终攻击力（静态，返回float）
static func calculate_final_attack(player: Node) -> float:
	if not player:
		return 0.0
	
	var base_attack = player.base_attack
	
	# 术法加成（乘法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_attack *= spell_bonuses.get("attack", 1.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_attack

## 计算最终防御力（静态，返回float）
static func calculate_final_defense(player: Node) -> float:
	if not player:
		return 0.0
	
	var base_defense = player.base_defense
	
	# 术法加成（乘法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_defense *= spell_bonuses.get("defense", 1.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_defense

## 计算最终速度（静态，返回float）
static func calculate_final_speed(player: Node) -> float:
	if not player:
		return 0.0
	
	var base_speed = player.base_speed
	
	# 术法加成（加法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_speed += spell_bonuses.get("speed", 0.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_speed

## 计算最终最大气血（静态，返回float）
static func calculate_final_max_health(player: Node) -> float:
	if not player:
		return 0.0
	
	var base_max_health = player.base_max_health
	
	# 术法加成（乘法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_max_health *= spell_bonuses.get("health", 1.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_max_health

## 计算最终最大灵气（静态，返回float）
static func calculate_final_max_spirit_energy(player: Node) -> float:
	if not player:
		return 0.0
	
	var base_max_spirit = player.base_max_spirit
	
	# 术法加成（乘法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_max_spirit *= spell_bonuses.get("max_spirit", 1.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_max_spirit

## 计算最终灵气获取速度（静态，返回float）
static func calculate_final_spirit_gain_speed(player: Node) -> float:
	if not player:
		return 1.0
	
	var base_speed = _get_base_spirit_gain_speed(player)
	
	# 术法加成（乘法）
	var spell_bonuses = _get_spell_bonuses(player)
	base_speed *= spell_bonuses.get("spirit_gain", 1.0)
	
	# TODO: 装备加成
	# TODO: 功法加成
	# TODO: 丹药加成
	
	return base_speed

# ==================== 战斗最终能力值计算（返回float） ====================
# 战斗最终能力值 = 静态最终能力值 + 战斗临时Buff
# 所有属性都返回float，UI显示时再格式化

## 计算战斗中的攻击力（返回float）
static func calculate_combat_attack(player: Node, combat_buffs: Dictionary) -> float:
	var final_attack = calculate_final_attack(player)
	
	if combat_buffs.is_empty():
		return final_attack
	
	# 应用战斗Buff（百分比加成）
	var attack_percent = combat_buffs.get("attack_percent", 0.0)
	return final_attack * (1.0 + attack_percent)

## 计算战斗中的防御力（返回float）
static func calculate_combat_defense(player: Node, combat_buffs: Dictionary) -> float:
	var final_defense = calculate_final_defense(player)
	
	if combat_buffs.is_empty():
		return final_defense
	
	# 应用战斗Buff（百分比加成）
	var defense_percent = combat_buffs.get("defense_percent", 0.0)
	return final_defense * (1.0 + defense_percent)

## 计算战斗中的速度（返回float）
static func calculate_combat_speed(player: Node, combat_buffs: Dictionary) -> float:
	var final_speed = calculate_final_speed(player)
	
	if combat_buffs.is_empty():
		return final_speed
	
	# 应用战斗Buff（固定值加成）
	var speed_bonus = combat_buffs.get("speed_bonus", 0.0)
	return final_speed + speed_bonus

## 计算战斗中的最大气血（返回float）
static func calculate_combat_max_health(player: Node, combat_buffs: Dictionary) -> float:
	var final_max_health = calculate_final_max_health(player)
	
	if combat_buffs.is_empty():
		return final_max_health
	
	# 应用战斗Buff（固定值加成）
	var health_bonus = combat_buffs.get("health_bonus", 0.0)
	return final_max_health + health_bonus

# ==================== 伤害计算（返回float） ====================

## 计算最终伤害
# attacker_attack: 攻击方的战斗攻击力（float）
# defender_defense: 防御方的战斗防御力（float）
# damage_percent: 伤害百分比（默认100%，即1.0）
static func calculate_damage(attacker_attack: float, defender_defense: float, damage_percent: float = 1.0) -> float:
	var k_value = 100.0
	var penetration = 0.0
	var effective_defense = max(defender_defense - penetration, 0.0)
	var defense_ratio = effective_defense / max(effective_defense + k_value, k_value)
	var base_damage = attacker_attack * (1.0 - defense_ratio)
	return max(base_damage, 1.0) * damage_percent

## 计算玩家对敌人的伤害
static func calculate_player_damage(player: Node, enemy: Dictionary, combat_buffs: Dictionary = {}, damage_percent: float = 1.0) -> float:
	var player_attack = calculate_combat_attack(player, combat_buffs)
	var enemy_defense = float(enemy.get("defense", 0))
	return calculate_damage(player_attack, enemy_defense, damage_percent)

## 计算敌人对玩家的伤害
static func calculate_enemy_damage(enemy: Dictionary, player: Node, combat_buffs: Dictionary = {}) -> float:
	var enemy_attack = float(enemy.get("attack", 0))
	var player_defense = calculate_combat_defense(player, combat_buffs)
	return calculate_damage(enemy_attack, player_defense)

# ==================== 辅助函数 ====================

## 获取术法属性加成
static func _get_spell_bonuses(player: Node) -> Dictionary:
	var default_bonuses = {
		"attack": 1.0,
		"defense": 1.0,
		"health": 1.0,
		"spirit_gain": 1.0,
		"max_spirit": 1.0,
		"speed": 0.0
	}
	
	if not player:
		return default_bonuses
	
	# 通过玩家的术法系统获取加成
	var spell_system = _get_spell_system(player)
	if spell_system and spell_system.has_method("get_attribute_bonuses"):
		return spell_system.get_attribute_bonuses()
	
	return default_bonuses

## 获取基础灵气获取速度
static func _get_base_spirit_gain_speed(player: Node) -> float:
	if not player:
		return 1.0

	if player.has_method("get_base_spirit_gain_speed"):
		return float(player.get_base_spirit_gain_speed())

	var base_spirit_gain = player.get("base_spirit_gain")
	if base_spirit_gain != null:
		return float(base_spirit_gain)
	
	# 从 RealmSystem 获取灵气获取速度
	var game_manager = _get_game_manager()
	if game_manager:
		var realm_system = game_manager.get_realm_system() if game_manager.has_method("get_realm_system") else null
		if realm_system:
			var realm_name = player.get("realm")
			if realm_name != null:
				return float(realm_system.get_spirit_gain_speed(str(realm_name)))
	
	return 1.0

## 获取术法系统
static func _get_spell_system(player: Node) -> Node:
	if not player:
		return null
	
	# 优先从玩家获取
	if player.has_method("get_spell_system"):
		return player.get_spell_system()
	
	# 从 GameManager 获取
	var game_manager = _get_game_manager()
	if game_manager and game_manager.has_method("get_spell_system"):
		return game_manager.get_spell_system()
	
	return null

## 获取 GameManager
static func _get_game_manager() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("GameManager")

# ==================== 便捷接口（供PlayerData调用） ====================
# 这些接口与PlayerData中的方法签名一致，便于PlayerData委托调用

static func get_final_attack_for(player: Node) -> float:
	return calculate_final_attack(player)

static func get_final_defense_for(player: Node) -> float:
	return calculate_final_defense(player)

static func get_final_speed_for(player: Node) -> float:
	return calculate_final_speed(player)

static func get_final_max_health_for(player: Node) -> float:
	return calculate_final_max_health(player)

static func get_final_max_spirit_energy_for(player: Node) -> float:
	return calculate_final_max_spirit_energy(player)

static func get_final_spirit_gain_speed_for(player: Node) -> float:
	return calculate_final_spirit_gain_speed(player)
