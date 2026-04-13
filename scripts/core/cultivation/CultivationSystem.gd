class_name CultivationSystem extends Node

signal log_message(message: String)

var is_cultivating: bool = false

var player: Node = null

const BASE_HEAL_PER_SECOND: float = 1.0

static func calculate_spirit_gain_per_second(player_node: Node) -> float:
	if not player_node:
		return 0.0
	
	if player_node.has_method("get_final_spirit_gain_speed"):
		return float(player_node.get_final_spirit_gain_speed())
	
	var base_spirit_gain = player_node.get("base_spirit_gain")
	if base_spirit_gain != null:
		return float(base_spirit_gain)
	
	return 1.0

static func calculate_health_regen_per_second(player_node: Node, spell_system: Node = null) -> float:
	if not player_node:
		return 0.0
	
	var base_regen := BASE_HEAL_PER_SECOND
	if player_node.has_method("get_base_health_regen_per_second"):
		base_regen = float(player_node.get_base_health_regen_per_second())
	else:
		var player_base_regen = player_node.get("base_health_regen")
		if player_base_regen != null:
			base_regen = float(player_base_regen)
	
	if spell_system and spell_system.has_method("get_equipped_breathing_heal_effect"):
		var breathing_effect = spell_system.get_equipped_breathing_heal_effect()
		var heal_percent = float(breathing_effect.get("heal_amount", 0.0))
		if heal_percent > 0.0 and player_node.has_method("get_final_max_health"):
			base_regen += player_node.get_final_max_health() * heal_percent
	
	return base_regen

func set_player(player_node: Node):
	player = player_node

func stop_cultivation():
	is_cultivating = false
	if player:
		player.cultivation_active = false
	log_message.emit("停止修炼")
