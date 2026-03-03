class_name SpellSystem extends Node

signal spell_equipped(spell_id: String, spell_type: int)
signal spell_unequipped(spell_id: String, spell_type: int)
signal spell_upgraded(spell_id: String, new_level: int)
signal spell_obtained(spell_id: String)
signal spell_used(spell_id: String)

var player: Node = null
var spell_data: Node = null

# 玩家术法数据：{spell_id: {obtained: bool, level: int, use_count: int, charged_spirit: int}}
# 注：equipped 状态通过 equipped_spells 推导，不单独存储
var player_spells: Dictionary = {}

# 当前装备的术法：{spell_type: [spell_id, ...]}
var equipped_spells: Dictionary = {}

# 战斗系统引用（用于检测是否在战斗中）
var lianli_system: Node = null

# 主动术法触发概率上限（保证至少20%概率普攻）
const MAX_TOTAL_TRIGGER_CHANCE: float = 0.80

func _ready():
	pass

func set_player(player_node: Node):
	player = player_node

func set_spell_data(spell_data_node: Node):
	spell_data = spell_data_node
	_init_player_spells()

func set_lianli_system(lianli_sys: Node):
	lianli_system = lianli_sys

func _init_player_spells():
	# 初始化所有术法为未获取状态
	if spell_data:
		for spell_id in spell_data.get_all_spell_ids():
			player_spells[spell_id] = {
				"obtained": false,
				"level": 0,
				"use_count": 0,
				"charged_spirit": 0
			}
		# 初始化装备槽位
		equipped_spells = {
			spell_data.SpellType.BREATHING: [],
			spell_data.SpellType.ACTIVE: [],
			spell_data.SpellType.PASSIVE: [],
			spell_data.SpellType.MISC: []
		}

# 检查是否在战斗中
func _is_in_battle() -> bool:
	if lianli_system:
		return lianli_system.is_in_battle
	return false

# 获取术法
func obtain_spell(spell_id: String) -> bool:
	if not player_spells.has(spell_id):
		return false
	
	if player_spells[spell_id].obtained:
		return false  # 已获取
	
	player_spells[spell_id].obtained = true
	player_spells[spell_id].level = 1
	spell_obtained.emit(spell_id)
	return true

# 装备术法
func equip_spell(spell_id: String) -> Dictionary:
	var result = {"success": false, "reason": "", "spell_id": spell_id, "spell_type": -1}
	
	if _is_in_battle():
		result.reason = "战斗中无法装备术法"
		return result
	
	if not player_spells.has(spell_id):
		result.reason = "术法不存在"
		return result
	
	if not player_spells[spell_id].obtained:
		result.reason = "未获取该术法"
		return result
	
	if is_spell_equipped(spell_id):
		result.reason = "术法已装备"
		return result
	
	var spell_type = spell_data.get_spell_type(spell_id)
	var limit = spell_data.get_equipment_limit(spell_type)
	var type_name = spell_data.get_spell_type_name(spell_type)
	
	# 检查是否已达装备上限（-1表示无限制）
	if limit >= 0 and equipped_spells[spell_type].size() >= limit:
		result.reason = type_name + "装备数量达到上限（" + str(limit) + "个），请先卸下已装备的术法"
		return result
	
	equipped_spells[spell_type].append(spell_id)
	spell_equipped.emit(spell_id, spell_type)
	result.success = true
	result.spell_type = spell_type
	return result

# 卸下术法
func unequip_spell(spell_id: String) -> Dictionary:
	var result = {"success": false, "reason": "", "spell_id": spell_id, "spell_type": -1}
	
	if _is_in_battle():
		result.reason = "战斗中无法卸下术法"
		return result
	
	if not player_spells.has(spell_id):
		result.reason = "术法不存在"
		return result
	
	if not is_spell_equipped(spell_id):
		result.reason = "术法未装备"
		return result
	
	var spell_type = spell_data.get_spell_type(spell_id)
	equipped_spells[spell_type].erase(spell_id)
	spell_unequipped.emit(spell_id, spell_type)
	result.success = true
	result.spell_type = spell_type
	return result

# 检查术法是否已装备
func is_spell_equipped(spell_id: String) -> bool:
	if not player_spells.has(spell_id):
		return false
	
	var spell_type = spell_data.get_spell_type(spell_id)
	return spell_id in equipped_spells.get(spell_type, [])

# 获取已装备术法数量
func get_equipped_count(spell_type: int) -> int:
	if equipped_spells.has(spell_type):
		return equipped_spells[spell_type].size()
	return 0

# 获取装备槽位上限
func get_equipment_limit(spell_type: int) -> int:
	if spell_data:
		return spell_data.get_equipment_limit(spell_type)
	return 1

# 升级术法
func upgrade_spell(spell_id: String) -> Dictionary:
	var result = {"success": false, "reason": "", "spell_id": spell_id, "new_level": 0}
	
	if not player_spells.has(spell_id):
		result.reason = "术法不存在"
		return result
	
	var spell_info = player_spells[spell_id]
	if not spell_info.obtained:
		result.reason = "未获取该术法"
		return result
	
	var spell_config = spell_data.get_spell_data(spell_id)
	var max_level = spell_config.get("max_level", 3)
	
	if spell_info.level >= max_level:
		result.reason = "已达到最高等级"
		return result
	
	var next_level = spell_info.level + 1
	var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
	
	var spirit_cost = level_data.get("spirit_cost", 0)
	var use_count_required = level_data.get("use_count_required", 0)
	
	# 检查使用次数
	if spell_info.use_count < use_count_required:
		result.reason = "使用次数不足（" + str(spell_info.use_count) + "/" + str(use_count_required) + "）"
		return result
	
	# 检查已充灵气
	if spell_info.charged_spirit < spirit_cost:
		result.reason = "术法灵气不足（" + str(spell_info.charged_spirit) + "/" + str(spirit_cost) + "）"
		return result
	
	# 扣除已充灵气并升级
	spell_info.charged_spirit -= spirit_cost
	spell_info.level = next_level
	# 升级后清空使用次数
	spell_info.use_count = 0
	spell_upgraded.emit(spell_id, next_level)
	
	result.success = true
	result.new_level = next_level
	return result

# 增加术法使用次数
func add_spell_use_count(spell_id: String):
	if player_spells.has(spell_id) and player_spells[spell_id].obtained:
		var spell_info = player_spells[spell_id]
		var spell_config = spell_data.get_spell_data(spell_id)
		var max_level = spell_config.get("max_level", 3)
		
		# 如果已经达到最高等级，不再增加使用次数
		if spell_info.level >= max_level:
			return
		
		# 获取当前等级所需使用次数
		var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
		var use_count_required = level_data.get("use_count_required", 0)
		
		# 如果已达到当前等级需求的使用次数，不再增加
		if spell_info.use_count >= use_count_required:
			return
		
		player_spells[spell_id].use_count += 1
		spell_used.emit(spell_id)

# 获取术法信息
func get_spell_info(spell_id: String) -> Dictionary:
	if not player_spells.has(spell_id) or not spell_data:
		return {}
	
	var player_info = player_spells[spell_id]
	var config = spell_data.get_spell_data(spell_id)
	
	return {
		"id": spell_id,
		"name": config.get("name", ""),
		"type": config.get("type", 0),
		"type_name": spell_data.get_spell_type_name(config.get("type", 0)),
		"description": config.get("description", ""),
		"obtained": player_info.obtained,
		"level": player_info.level,
		"max_level": config.get("max_level", 3),
		"use_count": player_info.use_count,
		"equipped": is_spell_equipped(spell_id),
		"charged_spirit": player_info.charged_spirit
	}

# 获取所有术法信息（按类型分类）
func get_all_spells_by_type() -> Dictionary:
	var result = {}
	if spell_data:
		result = {
			spell_data.SpellType.BREATHING: [],
			spell_data.SpellType.ACTIVE: [],
			spell_data.SpellType.PASSIVE: [],
			spell_data.SpellType.MISC: []
		}
	
	for spell_id in player_spells.keys():
		var info = get_spell_info(spell_id)
		if not info.is_empty():
			result[info.type].append(info)
	
	return result

# 获取属性加成（所有已获取的术法）
func get_attribute_bonuses() -> Dictionary:
	var bonuses = {
		"attack": 1.0,
		"defense": 1.0,
		"health": 1.0,
		"spirit_gain": 1.0,
		"max_spirit": 1.0,
		"speed": 0.0
	}
	
	if not spell_data:
		return bonuses
	
	for spell_id in player_spells.keys():
		var spell_info = player_spells[spell_id]
		if not spell_info.obtained or spell_info.level <= 0:
			continue
		
		var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
		var attribute_bonus = level_data.get("attribute_bonus", {})
		
		for attr in attribute_bonus.keys():
			if attr == "speed":
				bonuses.speed += attribute_bonus[attr]  # 加法
			else:
				bonuses[attr] *= attribute_bonus[attr]  # 乘法
	
	return bonuses

# 获取装备的吐纳术法效果（用于修炼时气血值回复）
# 支持多个吐纳术法效果叠加
func get_equipped_breathing_heal_effect() -> Dictionary:
	if not spell_data:
		return {"heal_amount": 0.0, "spell_ids": []}
	
	var breathing_spells = equipped_spells.get(spell_data.SpellType.BREATHING, [])
	if breathing_spells.is_empty():
		return {"heal_amount": 0.0, "spell_ids": []}
	
	var total_heal_percent = 0.0
	var valid_spell_ids = []
	
	for breathing_spell_id in breathing_spells:
		var spell_info = player_spells[breathing_spell_id]
		if not spell_info.obtained or spell_info.level <= 0:
			continue
		
		var level_data = spell_data.get_spell_level_data(breathing_spell_id, spell_info.level)
		var effect = level_data.get("effect", {})
		
		if effect.get("type") == "passive_heal":
			var heal_percent = effect.get("heal_percent", 0.0)
			total_heal_percent += heal_percent
			valid_spell_ids.append(breathing_spell_id)
	
	return {
		"heal_amount": total_heal_percent,
		"spell_ids": valid_spell_ids
	}

# 给术法充灵气
func charge_spell_spirit(spell_id: String, amount: int) -> Dictionary:
	var result = {"success": false, "reason": "", "spell_id": spell_id, "charged_amount": 0}
	
	if not player_spells.has(spell_id):
		result.reason = "术法不存在"
		return result
	
	var spell_info = player_spells[spell_id]
	if not spell_info.obtained:
		result.reason = "未获取该术法"
		return result
	
	var spell_config = spell_data.get_spell_data(spell_id)
	var max_level = spell_config.get("max_level", 3)
	
	if spell_info.level >= max_level:
		result.reason = "已达到最高等级"
		return result
	
	var next_level = spell_info.level + 1
	var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
	var spirit_cost = level_data.get("spirit_cost", 0)
	
	var current_charged = spell_info.charged_spirit
	var need = spirit_cost - current_charged
	
	if need <= 0:
		result.reason = "灵气已充足"
		return result
	
	var available = min(amount, need)
	
	if player and player.spirit_energy < available:
		available = int(player.spirit_energy)
	
	if available <= 0:
		result.reason = "自身灵气不足"
		return result
	
	if player:
		player.spirit_energy -= available
	
	spell_info.charged_spirit += available
	result.success = true
	result.charged_amount = available
	
	return result

# 获取装备的术法效果（所有装备的术法）
func get_equipped_spell_effects() -> Array:
	var effects = []
	
	if not spell_data:
		return effects
	
	for spell_type in equipped_spells.keys():
		for spell_id in equipped_spells[spell_type]:
			var spell_info = player_spells[spell_id]
			
			if spell_info.level > 0:
				var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
				var effect = level_data.get("effect", {})
				effect["spell_id"] = spell_id
				effect["spell_name"] = spell_data.get_spell_name(spell_id)
				effects.append(effect)
	
	return effects

# 获取指定类型的装备术法效果（返回数组，因为可能有多个）
func get_equipped_spell_effects_by_type(spell_type: int) -> Array:
	var effects = []
	
	if not spell_data:
		return effects
	
	var spell_ids = equipped_spells.get(spell_type, [])
	for spell_id in spell_ids:
		var spell_info = player_spells[spell_id]
		if not spell_info.obtained or spell_info.level <= 0:
			continue
		
		var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
		var original_effect = level_data.get("effect", {})
		
		# 创建新的字典，避免修改原始配置
		var effect = original_effect.duplicate()
		effect["spell_id"] = spell_id
		effect["spell_name"] = spell_data.get_spell_name(spell_id)
		effects.append(effect)
	
	return effects

# 触发攻击术法（按概率）- 带权重上限保护
func trigger_attack_spell() -> Dictionary:
	if not spell_data:
		return {"triggered": false, "is_normal_attack": true}
	
	# 获取所有装备的主动术法
	var active_spells = equipped_spells.get(spell_data.SpellType.ACTIVE, [])
	if active_spells.is_empty():
		return {"triggered": false, "is_normal_attack": true}
	
	# 收集所有主动术法的触发概率
	var spell_chances = []
	var total_chance = 0.0
	
	for spell_id in active_spells:
		var spell_info = player_spells[spell_id]
		if not spell_info.obtained or spell_info.level <= 0:
			continue
		
		var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
		var effect = level_data.get("effect", {})
		
		if effect.get("type") == "active_damage":
			var chance = effect.get("trigger_chance", 0.0)
			spell_chances.append({"spell_id": spell_id, "chance": chance})
			total_chance += chance
	
	if spell_chances.is_empty():
		return {"triggered": false, "is_normal_attack": true}
	
	# 权重上限保护：如果总概率超过80%，等比例缩小
	var scale_factor = 1.0
	if total_chance > MAX_TOTAL_TRIGGER_CHANCE:
		scale_factor = MAX_TOTAL_TRIGGER_CHANCE / total_chance
		total_chance = MAX_TOTAL_TRIGGER_CHANCE
		# 重新计算每个术法的概率
		for spell_chance in spell_chances:
			spell_chance.chance *= scale_factor
	
	# 判定是否触发术法（总概率 vs 普攻概率）
	# 普攻概率 = max(0.2, 1 - total_chance)
	var normal_attack_chance = max(0.2, 1.0 - total_chance)
	var roll = randf()
	
	if roll < normal_attack_chance:
		# 触发普攻
		return {"triggered": false, "is_normal_attack": true}
	
	# 触发术法，按比例选择具体哪个术法
	var effective_roll = (roll - normal_attack_chance) / total_chance  # 归一化到0-1
	var cumulative_chance = 0.0
	
	for spell_data_item in spell_chances:
		cumulative_chance += spell_data_item.chance / total_chance
		if effective_roll <= cumulative_chance:
			var selected_spell_id = spell_data_item.spell_id
			var selected_level_data = spell_data.get_spell_level_data(selected_spell_id, player_spells[selected_spell_id].level)
			var selected_effect = selected_level_data.get("effect", {})
			
			add_spell_use_count(selected_spell_id)
			return {
				"triggered": true,
				"spell_id": selected_spell_id,
				"spell_name": spell_data.get_spell_name(selected_spell_id),
				"effect": selected_effect,
				"is_normal_attack": false
			}
	
	# 兜底：选择第一个
	var first_spell = spell_chances[0]
	add_spell_use_count(first_spell.spell_id)
	return {
		"triggered": true,
		"spell_id": first_spell.spell_id,
		"spell_name": spell_data.get_spell_name(first_spell.spell_id),
		"effect": spell_data.get_spell_level_data(first_spell.spell_id, player_spells[first_spell.spell_id].level).get("effect", {}),
		"is_normal_attack": false
	}

# 检查术法是否可以升级（用于UI提示）
func can_upgrade_spell(spell_id: String) -> Dictionary:
	var result = {"can_upgrade": false, "reason": "", "next_level": 0}
	
	if not player_spells.has(spell_id):
		result.reason = "术法不存在"
		return result
	
	var spell_info = player_spells[spell_id]
	if not spell_info.obtained:
		result.reason = "未获取该术法"
		return result
	
	var spell_config = spell_data.get_spell_data(spell_id)
	var max_level = spell_config.get("max_level", 3)
	
	if spell_info.level >= max_level:
		result.reason = "已达到最高等级"
		return result
	
	var next_level = spell_info.level + 1
	var level_data = spell_data.get_spell_level_data(spell_id, spell_info.level)
	
	var spirit_cost = level_data.get("spirit_cost", 0)
	var use_count_required = level_data.get("use_count_required", 0)
	
	# 检查使用次数
	if spell_info.use_count < use_count_required:
		result.reason = "使用次数不足"
		return result
	
	# 检查已充灵气
	if spell_info.charged_spirit < spirit_cost:
		result.reason = "术法灵气不足"
		return result
	
	result.can_upgrade = true
	result.next_level = next_level
	return result

# 获取术法配置信息（未获得也可查看）
func get_spell_config_info(spell_id: String) -> Dictionary:
	if not spell_data:
		return {}
	
	var config = spell_data.get_spell_data(spell_id)
	if config.is_empty():
		return {}
	
	var result = {
		"id": spell_id,
		"name": config.get("name", ""),
		"type": config.get("type", 0),
		"type_name": spell_data.get_spell_type_name(config.get("type", 0)),
		"description": config.get("description", ""),
		"max_level": config.get("max_level", 3),
		"levels": {}
	}
	
	# 获取所有等级的配置
	var levels = config.get("levels", {})
	for level in levels.keys():
		var level_data = levels[level]
		result.levels[level] = {
			"spirit_cost": level_data.get("spirit_cost", 0),
			"use_count_required": level_data.get("use_count_required", 0),
			"attribute_bonus": level_data.get("attribute_bonus", {}),
			"effect": level_data.get("effect", {})
		}
	
	return result

# 存档数据（只存储已获得的术法）
func get_save_data() -> Dictionary:
	var saved_spells = {}
	for spell_id in player_spells.keys():
		var spell_info = player_spells[spell_id]
		# 只存储已获得的术法
		if spell_info.obtained:
			saved_spells[spell_id] = {
				"obtained": true,
				"level": int(spell_info.level),
				"use_count": int(spell_info.use_count),
				"charged_spirit": int(spell_info.charged_spirit)
			}
	
	return {
		"player_spells": saved_spells,
		"equipped_spells": equipped_spells.duplicate()
	}

# 加载存档数据
func apply_save_data(data: Dictionary):
	# 先初始化所有术法
	_init_player_spells()
	
	if data.has("player_spells"):
		var loaded_spells = data.player_spells
		for spell_id in loaded_spells.keys():
			if player_spells.has(spell_id):
				var spell_info = loaded_spells[spell_id]
				player_spells[spell_id] = {
					"obtained": spell_info.get("obtained", false),
					"level": int(spell_info.get("level", 0)),
					"use_count": int(spell_info.get("use_count", 0)),
					"charged_spirit": int(spell_info.get("charged_spirit", 0))
				}
	
	if data.has("equipped_spells"):
		var loaded_equipped = data.equipped_spells
		for spell_type in loaded_equipped.keys():
			var type_value = int(spell_type)
			var spell_list = loaded_equipped[spell_type]
			equipped_spells[type_value] = []
			for spell_id in spell_list:
				if player_spells.has(spell_id) and player_spells[spell_id].obtained:
					equipped_spells[type_value].append(spell_id)
