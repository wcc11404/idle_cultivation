class_name LianliSystem extends Node

# 历练系统在服务端权威改造后，客户端仅保留状态容器职责。
# 战斗模拟、时间轴推进、奖励结算均由 LianliModule 基于 API 返回驱动。

signal lianli_started(area_id: String)
signal lianli_ended(victory: bool)
signal lianli_waiting(time_remaining: float)

signal battle_started(enemy_name: String, is_elite: bool, enemy_max_health: float, enemy_level: int, player_max_health: float)
signal battle_action_executed(is_player: bool, damage: float, is_spell: bool, spell_name: String)
signal battle_updated(player_atb: float, enemy_atb: float, player_health: float, enemy_health: float, player_max_health: float, enemy_max_health: float)
signal battle_ended(victory: bool, loot: Array, enemy_name: String)

signal lianli_reward(item_id: String, amount: int, source: String)
signal log_message(message: String)

var is_in_lianli: bool = false
var is_in_battle: bool = false
var is_waiting: bool = false

var current_area_id: String = ""
var current_enemy: Dictionary = {}

var is_in_tower: bool = false
var current_tower_floor: int = 0

var tower_highest_floor: int = 0
var daily_dungeon_data: Dictionary = {}

var player: Node = null
var lianli_area_data: Node = null
var enemy_data: Node = null

func set_player(player_node: Node):
	player = player_node

func set_lianli_area_data(data: Node):
	lianli_area_data = data

func set_enemy_data(data: Node):
	enemy_data = data

func get_current_tower_floor() -> int:
	return current_tower_floor

func is_in_endless_tower() -> bool:
	return is_in_tower

func get_current_enemy_drops() -> Dictionary:
	if current_enemy.is_empty():
		return {}
	return current_enemy.get("drops", {})

func get_save_data() -> Dictionary:
	var save_data = {
		"tower_highest_floor": tower_highest_floor,
		"daily_dungeon_data": {}
	}
	for dungeon_id in daily_dungeon_data.keys():
		var dungeon_info = daily_dungeon_data[dungeon_id].duplicate()
		if dungeon_info.has("max_count"):
			dungeon_info["max_count"] = int(dungeon_info["max_count"])
		if dungeon_info.has("remaining_count"):
			dungeon_info["remaining_count"] = int(dungeon_info["remaining_count"])
		save_data["daily_dungeon_data"][dungeon_id] = dungeon_info
	return save_data

func apply_save_data(data: Dictionary):
	tower_highest_floor = int(data.get("tower_highest_floor", 0))
	daily_dungeon_data = data.get("daily_dungeon_data", {}).duplicate()
	for dungeon_id in daily_dungeon_data.keys():
		if daily_dungeon_data[dungeon_id].has("max_count"):
			daily_dungeon_data[dungeon_id]["max_count"] = int(daily_dungeon_data[dungeon_id]["max_count"])
		if daily_dungeon_data[dungeon_id].has("remaining_count"):
			daily_dungeon_data[dungeon_id]["remaining_count"] = int(daily_dungeon_data[dungeon_id]["remaining_count"])

func end_lianli():
	if not is_in_lianli:
		return
	is_in_lianli = false
	is_in_battle = false
	is_waiting = false
	is_in_tower = false
	current_tower_floor = 0
	current_area_id = ""
	current_enemy = {}
	log_message.emit("已退出历练区域")
	lianli_ended.emit(false)
