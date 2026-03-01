class_name LianliSystem extends Node

# 历练相关信号（一次历练包含多次战斗）
signal lianli_started(area_id: String)  # 开始一次历练（进入历练区域）
signal lianli_ended(victory: bool)  # 历练结束（胜利或失败）
signal lianli_waiting(time_remaining: float)  # 连续历练的等待间隔

# 战斗相关信号（一次战斗是单次对决直到一方死亡）
signal battle_started(enemy_name: String, is_elite: bool, enemy_max_health: float, enemy_level: int, player_max_health: float)  # 开始一场战斗
signal battle_action_executed(is_player: bool, damage: float, is_spell: bool, spell_name: String)  # 战斗行动执行
signal battle_updated(player_atb: float, enemy_atb: float, player_health: float, enemy_health: float, player_max_health: float, enemy_max_health: float)  # 战斗状态更新
signal battle_ended(victory: bool, loot: Array, enemy_name: String)  # 战斗结束（胜利或失败）

# 其他信号
signal lianli_reward(item_id: String, amount: int, source: String)
signal log_message(message: String)  # 历练日志信号

# ATB战斗系统常量
const ATB_MAX: float = 100.0
const TICK_INTERVAL: float = 0.1  # 每个tick的间隔时间（秒）
const DEFAULT_ENEMY_ATTACK: float = 50.0
const PERCENTAGE_BASE: float = 100.0

## 格式化百分比，保留一位小数并去除尾0
func _format_percent(value: float) -> String:
	var percent = value * PERCENTAGE_BASE
	# 保留一位小数
	var formatted = "%.1f" % percent
	# 去除尾0和小数点
	if formatted.find(".") != -1:
		formatted = formatted.rstrip("0").rstrip(".")
	return formatted + "%"

# 历练状态
var is_in_lianli: bool = false  # 是否处于历练中（可能包含多场战斗）
var is_in_battle: bool = false  # 是否处于战斗中
var is_waiting: bool = false  # 是否处于连续历练的等待间隔

# 当前区域和敌人
var current_area_id: String = ""
var current_enemy: Dictionary = {}

# 无尽塔状态
var is_in_tower: bool = false  # 是否处于无尽塔中
var current_tower_floor: int = 0  # 当前无尽塔层数
var tower_continuous: bool = false  # 无尽塔连续战斗模式
var endless_tower_data: Node = null  # 无尽塔数据引用

# 连续历练设置
var continuous_lianli: bool = false
var lianli_speed: float = 1.0
var wait_timer: float = 0.0
var current_wait_interval: float = 4.0

# 等待时间管理（原WaitTimeManager功能合并）
var base_wait_interval_min: float = 3.0
var base_wait_interval_max: float = 5.0
var wait_time_multiplier: float = 1.0
var min_wait_time: float = 0.5

# ATB战斗条
var player_atb: float = 0.0
var enemy_atb: float = 0.0
var tick_accumulator: float = 0.0

# 玩家引用
var player: Node = null

# 数据引用
var lianli_area_data: Node = null
var enemy_data: Node = null

# 战斗中的临时buff系统
var combat_buffs: Dictionary = {
	"attack_percent": 0.0,  # 攻击加成百分比（小数）
	"defense_percent": 0.0,  # 防御加成百分比（小数）
	"speed_bonus": 0.0,  # 速度加成固定值（改为float统一）
	"health_bonus": 0.0  # 气血加成固定值（改为float统一）
}

# 缓存的术法系统引用
var _cached_spell_system: Node = null

func set_player(player_node: Node):
	player = player_node

func set_lianli_area_data(data: Node):
	lianli_area_data = data

func set_enemy_data(data: Node):
	enemy_data = data

func set_endless_tower_data(data: Node):
	endless_tower_data = data

func set_current_area(area_id: String):
	current_area_id = area_id

func set_continuous_lianli(enabled: bool):
	continuous_lianli = enabled

func set_lianli_speed(speed: float):
	lianli_speed = clamp(speed, 1.0, 2.0)

# 开始一次历练（进入历练区域）
func start_lianli_in_area(area_id: String) -> bool:
	if not lianli_area_data or not enemy_data:
		return false
	
	# 检查玩家血量，小于等于0不能进入历练
	if player and player.health <= 0:
		var area_name = lianli_area_data.get_area_name(area_id) if lianli_area_data else "历练区域"
		log_message.emit("气血不足，无法进入" + area_name)
		return false
	
	current_area_id = area_id
	is_in_lianli = true
	
	lianli_started.emit(area_id)
	
	return start_next_battle()

# ==================== 无尽塔功能 ====================

# 开始无尽塔挑战
func start_endless_tower() -> bool:
	if not endless_tower_data or not enemy_data:
		return false
	
	# 检查玩家血量
	if player and player.health <= 0:
		var tower_name = endless_tower_data.get_tower_name() if endless_tower_data else "无尽塔"
		log_message.emit("气血不足，无法进入" + tower_name)
		return false
	
	# 设置无尽塔状态
	is_in_tower = true
	is_in_lianli = true
	current_area_id = endless_tower_data.get_area_id()
	
	# 计算起始层数（最高通关层数+1，但不超过上限）
	var start_floor = 1
	var max_floor = endless_tower_data.get_max_floor()
	if player:
		start_floor = min(player.tower_highest_floor + 1, max_floor)
	current_tower_floor = start_floor
	
	lianli_started.emit(current_area_id)
	
	return _start_tower_battle()

# 开始无尽塔的一场战斗
func _start_tower_battle() -> bool:
	if not endless_tower_data or not enemy_data:
		return false
	
	# 生成当前层数的敌人
	var template_id = endless_tower_data.get_random_template()
	var generated_enemy = enemy_data.generate_enemy(template_id, current_tower_floor)
	if generated_enemy.is_empty():
		return false
	
	var stats = generated_enemy.get("stats", {})
	
	var enemy_data_dict = {
		"id": "tower_enemy_" + str(current_tower_floor),
		"name": generated_enemy.get("name", "敌人"),
		"rarity": "普通",
		"level": current_tower_floor,
		"health": stats.get("health", 1000),
		"attack": stats.get("attack", DEFAULT_ENEMY_ATTACK),
		"defense": stats.get("defense", 0),
		"speed": stats.get("speed", 9),
		"drops": {}  # 无尽塔无掉落
	}
	
	return start_battle(enemy_data_dict)

# 设置无尽塔连续战斗模式
func set_tower_continuous(enabled: bool):
	tower_continuous = enabled

# 获取当前无尽塔层数
func get_current_tower_floor() -> int:
	return current_tower_floor

# 检查是否在无尽塔中
func is_in_endless_tower() -> bool:
	return is_in_tower

# ==================== 普通历练功能 ====================

# 开始下一场战斗（连续历练中的下一场）
func start_next_battle() -> bool:
	if not lianli_area_data or not enemy_data:
		return false
	
	var enemy_config = lianli_area_data.get_random_enemy_config(current_area_id)
	if enemy_config.is_empty():
		return false
	
	var template_id = enemy_config.get("template", "")
	var min_level = int(enemy_config.get("min_level", 1))
	var max_level = int(enemy_config.get("max_level", 1))
	var level = randi_range(min_level, max_level)
	
	# 使用EnemyData生成敌人
	var generated_enemy = enemy_data.generate_enemy(template_id, level)
	if generated_enemy.is_empty():
		return false
	
	var stats = generated_enemy.get("stats", {})
	
	var enemy_data_dict = {
		"id": template_id + "_lv" + str(level),
		"name": generated_enemy.get("name", "敌人"),
		"rarity": "精英" if generated_enemy.get("is_elite", false) else "普通",
		"level": level,
		"health": stats.get("health", 1000),
		"attack": stats.get("attack", DEFAULT_ENEMY_ATTACK),
		"defense": stats.get("defense", 0),
		"speed": stats.get("speed", 9),
		"drops": enemy_config.get("drops", {})
	}
	
	return start_battle(enemy_data_dict)

# 开始一场战斗
func start_battle(enemy_data_dict: Dictionary) -> bool:
	current_enemy = enemy_data_dict.duplicate()
	current_enemy["current_health"] = enemy_data_dict.get("health", 1000)
	is_in_battle = true
	is_waiting = false
	
	# 重置ATB战斗条和时间累积器
	player_atb = 0.0
	enemy_atb = 0.0
	tick_accumulator = 0.0
	
	# 重置战斗buff
	_reset_combat_buffs()
	
	# 获取玩家基础战斗气血（不包含开场技能加成）
	var player_base_max_health = player.get_combat_max_health() if player else 0
	
	# 先发射战斗开始信号（GameUI显示"遭遇敌人"）
	battle_started.emit(current_enemy.get("name", "敌人"), current_enemy.get("is_elite", false), current_enemy.get("health", 1000), current_enemy.get("level", 1), player_base_max_health)
	
	# 再触发装备术法效果（显示"战斗开始：xxx生效"并应用加成）
	_trigger_start_spells()
	
	# 如果有气血加成类技能，更新UI显示
	if player and combat_buffs.health_bonus > 0:
		var player_combat_max_health = player.get_combat_max_health()
		battle_updated.emit(player_atb, enemy_atb, player.health, current_enemy.get("current_health", 0), player_combat_max_health, current_enemy.get("health", 0))
	
	return true

# 结束历练（完全退出）
# 注意：日志由调用方输出，此函数只负责清理状态
func end_lianli():
	is_in_lianli = false
	is_in_battle = false
	is_waiting = false
	current_enemy = {}
	continuous_lianli = false
	tick_accumulator = 0.0
	# 恢复气血buff带来的加成
	_restore_health_after_combat()
	_reset_combat_buffs()
	_cached_spell_system = null  # 清除缓存
	lianli_ended.emit(false)

# 结束当前战斗
func end_battle(victory: bool):
	is_in_battle = false
	_restore_health_after_combat()
	battle_ended.emit(victory, [], current_enemy.get("name", ""))

func _reset_combat_buffs():
	combat_buffs = {
		"attack_percent": 0.0,
		"defense_percent": 0.0,
		"speed_bonus": 0.0,
		"health_bonus": 0.0
	}

func _trigger_start_spells():
	var spell_system = get_spell_system()
	if not spell_system:
		return
	
	# 触发所有被动术法（战斗开始时）
	var passive_effects = spell_system.get_equipped_spell_effects_by_type(spell_system.spell_data.SpellType.PASSIVE)
	for effect_data in passive_effects:
		if effect_data.is_empty():
			continue
		
		var effect_type = effect_data.get("type", "")
		var spell_name = effect_data.get("spell_name", "被动术法")
		var spell_id = effect_data.get("spell_id", "")
		
		match effect_type:
			"start_buff":
				var buff_type = effect_data.get("buff_type", "")
				var log_effect = effect_data.get("log_effect", "")
				match buff_type:
					"defense":
						var buff_percent = effect_data.get("buff_percent", 0.0)
						combat_buffs.defense_percent += buff_percent
						log_message.emit("战斗开始，使用" + spell_name + "，" + log_effect)
					"speed":
						var buff_value = effect_data.get("buff_value", 0.0)
						combat_buffs.speed_bonus += buff_value
						log_message.emit("战斗开始，使用" + spell_name + "，" + log_effect)
					"health":
						var health_percent = effect_data.get("buff_percent", 0.0)
						if player:
							# 计算气血加成（基于静态最终气血）
							var final_max_health = player.get_final_max_health()
							var bonus_health = int(final_max_health * health_percent)
							combat_buffs.health_bonus += bonus_health
							# 更新玩家的战斗Buff
							player.set_combat_buffs(combat_buffs)
							# 增加当前气血（临时）
							player.health += bonus_health
						log_message.emit("战斗开始，使用" + spell_name + "，" + log_effect)
		
		# 增加使用次数
		if not spell_id.is_empty():
			spell_system.add_spell_use_count(spell_id)

func _process(delta: float):
	# 等待时间不受速度影响
	if is_waiting:
		wait_timer += delta
		var time_remaining = max(0.0, current_wait_interval - wait_timer)
		lianli_waiting.emit(time_remaining)
		
		if wait_timer >= current_wait_interval:
			wait_timer = 0.0
			is_waiting = false
			if is_in_tower:
				# 无尽塔：进入下一层并开始战斗
				current_tower_floor += 1
				_start_tower_battle()
			else:
				# 特殊区域：检查剩余次数
				if lianli_area_data and lianli_area_data.is_special_area(current_area_id):
					if player.get_daily_dungeon_count(current_area_id) <= 0:
						# 次数用完，结束历练
						is_in_lianli = false
						log_message.emit("今日次数已用完，历练结束")
						end_lianli()
						return
				# 普通区域：开始下一场战斗
				start_next_battle()
		return
	
	if not is_in_battle or current_enemy.is_empty():
		return
	
	if not player:
		return
	
	# 实时检查玩家血量，如果小于等于0则结束历练
	if player.health <= 0:
		_handle_battle_defeat()
		return
	
	# ATB战斗系统：每0.1秒执行一次tick计算（受倍速影响）
	tick_accumulator += delta
	
	# 每0.1秒处理一次tick
	while tick_accumulator >= TICK_INTERVAL and is_in_battle:
		tick_accumulator -= TICK_INTERVAL
		
		_process_atb_tick()
		
		# 检查战斗是否结束
		if current_enemy.get("current_health", 0) <= 0:
			_handle_battle_victory()
			return
		elif player.health <= 0:
			_handle_battle_defeat()
			return

func _process_atb_tick():
	# 使用AttributeCalculator计算战斗中的速度
	var player_speed = AttributeCalculator.calculate_combat_speed(player, combat_buffs)
	
	var enemy_speed = current_enemy.get("speed", 7)
	
	# ATB增长直接乘以历练倍速（双方都要受倍速影响）
	player_atb += player_speed * lianli_speed
	enemy_atb += enemy_speed * lianli_speed
	
	# 检查是否有人达到ATB_MAX
	var player_ready = player_atb >= ATB_MAX
	var enemy_ready = enemy_atb >= ATB_MAX
	
	if player_ready and enemy_ready:
		# 同时达到，速度快者优先，相同则玩家优先
		if player_speed > enemy_speed:
			_execute_player_action()
			if is_in_battle and current_enemy.get("current_health", 0) > 0 and player.health > 0:
				_execute_enemy_action()
		elif enemy_speed > player_speed:
			_execute_enemy_action()
			if is_in_battle and current_enemy.get("current_health", 0) > 0 and player.health > 0:
				_execute_player_action()
		else:
			# 速度相同，玩家优先
			_execute_player_action()
			if is_in_battle and current_enemy.get("current_health", 0) > 0 and player.health > 0:
				_execute_enemy_action()
	elif player_ready:
		_execute_player_action()
	elif enemy_ready:
		_execute_enemy_action()

func _execute_player_action():
	var enemy_defense = current_enemy.get("defense", 0)
	var enemy_health = current_enemy.get("current_health", 0)
	
	# 使用AttributeCalculator计算战斗中的攻击力
	var player_attack = AttributeCalculator.calculate_combat_attack(player, combat_buffs)
	
	# 使用攻击AI：先判定是否触发攻击术法
	var spell_system = get_spell_system()
	var attack_result = null
	if spell_system:
		attack_result = spell_system.trigger_attack_spell()
	
	var damage_to_enemy = 0
	var is_spell_damage = false
	var spell_name = ""
	
	if attack_result and attack_result.triggered and not attack_result.is_normal_attack:
		# 触发了攻击术法
		var effect = attack_result.effect
		var damage_percent = effect.get("damage_percent", PERCENTAGE_BASE)
		
		# 伤害公式：战斗攻击力 * 术法伤害倍数 - 敌方防御
		# damage_percent 已经是倍数形式（如 1.10 表示 110%）
		damage_to_enemy = AttributeCalculator.calculate_damage(player_attack, enemy_defense, damage_percent)
		
		is_spell_damage = true
		spell_name = attack_result.spell_name
	else:
		# 普通攻击
		damage_to_enemy = AttributeCalculator.calculate_damage(player_attack, enemy_defense)
	
	enemy_health -= damage_to_enemy
	# 确保气血不低于0
	enemy_health = max(0.0, enemy_health)
	current_enemy["current_health"] = enemy_health
	
	# 战斗条归零并保留溢出
	player_atb -= ATB_MAX
	
	# 发送战斗日志
	var enemy_name = current_enemy.get("name", "敌人")
	var action_log = ""
	var damage_str = AttributeCalculator.format_damage(damage_to_enemy)
	if is_spell_damage:
		action_log = "玩家使用" + spell_name + "对" + enemy_name + "造成了" + damage_str + "点伤害"
	else:
		action_log = "玩家使用普通攻击对" + enemy_name + "造成了" + damage_str + "点伤害"
	log_message.emit(action_log)
	
	# 发送行动执行信号
	battle_action_executed.emit(true, damage_to_enemy, is_spell_damage, spell_name)
	
	# 发送UI更新信号（使用战斗中的最大气血）
	var player_max_health = player.get_combat_max_health() if player else 0
	var enemy_max_health = current_enemy.get("health", 0)
	battle_updated.emit(player_atb, enemy_atb, player.health, enemy_health, player_max_health, enemy_max_health)

func _execute_enemy_action():
	var enemy_attack = current_enemy.get("attack", DEFAULT_ENEMY_ATTACK)
	
	# 使用AttributeCalculator计算战斗中的防御力
	var player_defense = AttributeCalculator.calculate_combat_defense(player, combat_buffs)
	
	# 使用AttributeCalculator计算伤害
	var damage_to_player = AttributeCalculator.calculate_damage(enemy_attack, player_defense)
	
	# 使用Player的方法处理伤害
	if player:
		player.take_damage(damage_to_player)
	
	# 战斗条归零并保留溢出
	enemy_atb -= ATB_MAX
	
	# 发送战斗日志
	var enemy_name = current_enemy.get("name", "敌人")
	var damage_str = AttributeCalculator.format_damage(damage_to_player)
	log_message.emit(enemy_name + "对玩家造成了" + damage_str + "点伤害")
	
	# 发送行动执行信号
	battle_action_executed.emit(false, damage_to_player, false, "")
	
	# 发送UI更新信号（使用战斗中的最大气血）
	var player_max_health = player.get_combat_max_health() if player else 0
	var enemy_max_health = current_enemy.get("health", 0)
	var enemy_current_health = current_enemy.get("current_health", 0)
	var player_current_health = player.health if player else 0
	battle_updated.emit(player_atb, enemy_atb, player_current_health, enemy_current_health, player_max_health, enemy_max_health)



func _restore_health_after_combat():
	# 战斗结束后恢复气血buff带来的加成
	if player and combat_buffs.get("health_bonus", 0.0) > 0:
		# 获取静态最终气血值（不包含战斗Buff）
		var final_max_health = player.get_final_max_health()
		# 当前气血不能超过静态最终气血值
		player.set_health(min(player.health, final_max_health))
		# 清除玩家的战斗Buff
		player.clear_combat_buffs()

func _handle_battle_victory():
	is_in_battle = false
	
	# 恢复气血buff
	_restore_health_after_combat()
	
	var enemy_name = current_enemy.get("name", "")

	var loot = []

	# 检查是否是特殊区域（有special_drops）
	if lianli_area_data and lianli_area_data.is_single_boss_area(current_area_id):
		# 特殊区域掉落（物品进入储纳时会由储纳系统提示）
		var special_drops = lianli_area_data.get_special_drops(current_area_id)
		for item_id in special_drops.keys():
			var amount = special_drops[item_id]
			loot.append({"item_id": item_id, "amount": amount})
			lianli_reward.emit(item_id, amount, "lianli")
	else:
		# 普通掉落处理（从敌人配置中读取）
		var drops_config = current_enemy.get("drops", {})
		for item_id in drops_config.keys():
			var drop_info = drops_config[item_id]
			var chance = drop_info.get("chance", 1.0)
			# 检查掉落概率
			if randf() <= chance:
				var min_amount = drop_info.get("min", 0)
				var max_amount = drop_info.get("max", 0)
				var amount = randi_range(min_amount, max_amount)
				if amount > 0:
					loot.append({"item_id": item_id, "amount": amount})
					lianli_reward.emit(item_id, amount, "lianli")
	
	battle_ended.emit(true, loot, enemy_name)
	
	# 检查是否是无尽塔
	if is_in_tower:
		_handle_tower_victory()
		return
	
	# 特殊区域：战斗胜利后消耗每日次数
	if lianli_area_data and lianli_area_data.is_special_area(current_area_id):
		player.use_daily_dungeon_count(current_area_id)
	
	# 检查是否是单BOSS区域
	if lianli_area_data and lianli_area_data.is_single_boss_area(current_area_id):
		is_in_battle = false
		# 检查连续战斗 + 剩余次数
		if continuous_lianli and player.get_daily_dungeon_count(current_area_id) > 0:
			# 启动等待计时器，准备下一场战斗
			is_waiting = true
			wait_timer = 0.0
			current_wait_interval = get_wait_interval()
			return
		else:
			is_in_lianli = false
			log_message.emit("通关成功！")
			end_lianli()
			return
	
	# 启动等待计时器（连续历练模式）
	if continuous_lianli and is_in_lianli:
		is_waiting = true
		wait_timer = 0.0
		current_wait_interval = get_wait_interval()

func _handle_battle_defeat():
	is_in_battle = false
	
	# 检查是否是无尽塔
	if is_in_tower:
		_handle_tower_defeat()
		return
	
	is_in_lianli = false
	# 恢复气血buff
	_restore_health_after_combat()
	log_message.emit("气血不足，历练结束")
	battle_ended.emit(false, [], current_enemy.get("name", ""))
	end_lianli()

# 处理无尽塔战斗胜利
func _handle_tower_victory():
	# 更新最高层数
	if player and current_tower_floor > player.tower_highest_floor:
		player.tower_highest_floor = current_tower_floor
	
	# 检查是否是奖励层
	if endless_tower_data and endless_tower_data.is_reward_floor(current_tower_floor):
		var reward = endless_tower_data.get_reward_for_floor(current_tower_floor)
		for item_id in reward.keys():
			var amount = reward[item_id]
			lianli_reward.emit(item_id, amount, "tower")
	
	log_message.emit("挑战第" + str(current_tower_floor) + "层成功")
	
	# 检查是否达到上限
	var max_floor = endless_tower_data.get_max_floor()
	if current_tower_floor >= max_floor:
		log_message.emit("恭喜！已通关无尽塔最高层！")
		is_in_battle = false
		is_in_lianli = false
		is_in_tower = false
		end_lianli()
		return
	
	# 战斗结束，发出信号让UI决定是否连续战斗
	is_in_battle = false
	battle_ended.emit(true, [], current_enemy.get("name", ""))

# 处理无尽塔战斗失败
func _handle_tower_defeat():
	is_in_battle = false
	is_in_lianli = false
	is_in_tower = false
	# 恢复气血buff
	_restore_health_after_combat()
	log_message.emit("无尽塔挑战结束，最高到达第" + str(current_tower_floor) + "层")
	battle_ended.emit(false, [], current_enemy.get("name", ""))
	end_lianli()

# 继续无尽塔下一层（玩家手动点击）
func continue_tower_next_floor() -> bool:
	if not is_in_tower:
		return false
	
	current_tower_floor += 1
	is_waiting = false
	return _start_tower_battle()

# 开始等待下一场战斗（由UI调用）
func start_wait_for_next_battle() -> bool:
	if not is_in_lianli or is_in_battle:
		return false
	
	if is_in_tower:
		# 无尽塔：检查是否达到上限（下一层）
		var max_floor = endless_tower_data.get_max_floor()
		if current_tower_floor + 1 > max_floor:
			return false
	
	# 进入等待状态
	is_waiting = true
	wait_timer = 0.0
	current_wait_interval = get_wait_interval()
	return true

# 获取当前敌人的掉落配置
func get_current_enemy_drops() -> Dictionary:
	if current_enemy.is_empty():
		return {}
	return current_enemy.get("drops", {})

# 退出无尽塔
func exit_tower():
	if is_in_tower:
		is_in_tower = false
		is_in_lianli = false
		is_in_battle = false
		is_waiting = false
		log_message.emit("退出无尽塔，最高到达第" + str(current_tower_floor) + "层")
		end_lianli()

# 获取术法系统（带缓存）
func get_spell_system() -> Node:
	# 如果已有缓存，直接返回
	if _cached_spell_system != null and is_instance_valid(_cached_spell_system):
		return _cached_spell_system
	
	# 尝试通过get_node获取GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		_cached_spell_system = game_manager.get_spell_system()
		return _cached_spell_system
	
	# 备选：尝试使用Engine单例
	if Engine.has_singleton("GameManager"):
		game_manager = Engine.get_singleton("GameManager")
		_cached_spell_system = game_manager.get_spell_system()
		return _cached_spell_system
	
	return null

## 获取等待时间管理器
# ==================== 等待时间管理 ====================

## 获取当前等待时间间隔（随机）
func get_wait_interval() -> float:
	var interval = randf_range(base_wait_interval_min, base_wait_interval_max)
	return max(min_wait_time, interval * wait_time_multiplier)

## 设置等待时间倍率
func set_wait_time_multiplier(multiplier: float) -> void:
	wait_time_multiplier = clamp(multiplier, 0.0, 1.0)

## 获取等待时间倍率
func get_wait_time_multiplier() -> float:
	return wait_time_multiplier

## 设置等待时间范围
func set_wait_interval_range(min_time: float, max_time: float) -> void:
	base_wait_interval_min = min_time
	base_wait_interval_max = max_time
