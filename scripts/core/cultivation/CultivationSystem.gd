class_name CultivationSystem extends Node

const AttributeCalculator = preload("res://scripts/core/AttributeCalculator.gd")

signal cultivation_progress(current: int, max: int)
signal cultivation_complete()
signal log_message(message: String)

var is_cultivating: bool = false
var cultivation_timer: float = 0.0
var cultivation_interval: float = 1.0

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

static func calculate_health_gain_for_interval(player_node: Node, delta_seconds: float, spell_system: Node = null) -> float:
	if not player_node or delta_seconds <= 0.0:
		return 0.0
	
	var total_regen = calculate_health_regen_per_second(player_node, spell_system) * delta_seconds
	return float(int(total_regen))

func _ready():
	pass

func set_player(player_node: Node):
	player = player_node

func start_cultivation():
	_stop_other_systems()
	
	if player:
		is_cultivating = true
		player.cultivation_active = true

func _stop_other_systems():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	var lianli_system = game_manager.get_lianli_system()
	if lianli_system and lianli_system.is_in_lianli:
		lianli_system.end_lianli()
	
	var alchemy_system = game_manager.get_alchemy_system()
	if alchemy_system and alchemy_system.is_crafting:
		alchemy_system.stop_crafting()

func stop_cultivation():
	is_cultivating = false
	if player:
		player.cultivation_active = false
	log_message.emit("停止修炼")

func _process(delta: float):
	if not is_cultivating or not player:
		return
	
	cultivation_timer += delta
	
	if cultivation_timer >= cultivation_interval:
		cultivation_timer = 0.0
		do_cultivate()

func do_cultivate():
	if not player:
		return
	
	var final_max_health = AttributeCalculator.calculate_final_max_health(player)
	var spell_system = _get_spell_system()
	var total_heal = calculate_health_gain_for_interval(player, cultivation_interval, spell_system)
	if spell_system:
		var breathing_effect = spell_system.get_equipped_breathing_heal_effect()
		for spell_id in breathing_effect.get("spell_ids", []):
			spell_system.add_spell_use_count(spell_id)
	
	if total_heal > 0.0 and player.health < final_max_health:
		player.heal(total_heal)
	
	if player.spirit_energy >= player.get_final_max_spirit_energy():
		cultivation_complete.emit()
		return
	
	var spirit_gain = calculate_spirit_gain_per_second(player)
	
	player.add_spirit_energy(spirit_gain)
	
	cultivation_progress.emit(player.spirit_energy, player.get_final_max_spirit_energy())

func _get_spell_system() -> Node:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		return game_manager.get_spell_system()
	return null
