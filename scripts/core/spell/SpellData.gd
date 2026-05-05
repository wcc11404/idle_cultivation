class_name SpellData extends Node

# 术法类型枚举
enum SpellType {
	BREATHING = 0,  # 吐纳心法
	ACTIVE = 1,     # 主动术法
	PASSIVE = 2,    # 被动术法（开场术法）
	MISC = 3        # 特殊术法（生产术法）
}

var MAX_BREATHING_SPELLS = 1
var MAX_ACTIVE_SPELLS = 2
var MAX_OPENING_SPELLS = 2

var SPELLS: Dictionary = {}
const RARITY_TO_QUALITY := {
	"fan": 0,
	"huang": 1,
	"xuan": 2,
	"di": 3,
	"tian": 4
}

const TYPE_NAMES = {
	"breathing": "吐纳心法",
	"active": "主动术法",
	"opening": "开局术法",
	"production": "生产术法"
}

func _ready():
	_load_config()

func _load_config():
	var file = FileAccess.open("res://scripts/core/spell/spells.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data:
			if data.has("equipment_limits") and data["equipment_limits"] is Dictionary:
				MAX_BREATHING_SPELLS = int(data["equipment_limits"].get("MAX_BREATHING_SPELLS", 1))
				MAX_ACTIVE_SPELLS = int(data["equipment_limits"].get("MAX_ACTIVE_SPELLS", 2))
				MAX_OPENING_SPELLS = int(data["equipment_limits"].get("MAX_OPENING_SPELLS", 2))
			
			if data.has("spells") and data["spells"] is Dictionary:
				SPELLS = data["spells"].duplicate(true)
		else:
			print("[SpellData] JSON解析失败")
	else:
		print("[SpellData] 无法打开文件")

func get_spell_data(spell_id: String) -> Dictionary:
	return SPELLS.get(spell_id, {})

func get_spell_name(spell_id: String) -> String:
	if spell_id == "norm_attack":
		return "普通攻击"
	var spell = get_spell_data(spell_id)
	return spell.get("name", "未知术法")

func get_spell_type(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return spell.get("type", "active")

func get_spell_type_name(spell_type: String) -> String:
	return TYPE_NAMES.get(spell_type, "未知术法")

func get_spell_level_data(spell_id: String, level: int) -> Dictionary:
	var spell = get_spell_data(spell_id)
	var levels = spell.get("levels", {})
	return levels.get(str(level), {})

func get_all_spell_ids() -> Array:
	return SPELLS.keys()

func get_spell_ids_by_type(spell_type: String) -> Array:
	var result = []
	for spell_id in SPELLS.keys():
		if SPELLS[spell_id].get("type") == spell_type:
			result.append(spell_id)
	return result

func get_equipment_limit(spell_type: String) -> int:
	match spell_type:
		"breathing":
			return MAX_BREATHING_SPELLS
		"active":
			return MAX_ACTIVE_SPELLS
		"opening":
			return MAX_OPENING_SPELLS
		_:
			return -1

func spell_exists(spell_id: String) -> bool:
	return SPELLS.has(spell_id)

func get_spell_description(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return spell.get("description", "")

func get_spell_max_level(spell_id: String) -> int:
	var spell = get_spell_data(spell_id)
	return int(spell.get("max_level", 3))

func get_spell_max_star(spell_id: String) -> int:
	var spell = get_spell_data(spell_id)
	return int(spell.get("max_star", 0))

func get_spell_rarity(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return str(spell.get("rarity", "fan"))

func get_spell_quality(spell_id: String) -> int:
	return int(RARITY_TO_QUALITY.get(get_spell_rarity(spell_id), 0))

func get_spell_element(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return str(spell.get("element", "none"))

func get_spell_effects(spell_id: String, level: int) -> Array:
	var level_data = get_spell_level_data(spell_id, level)
	var effect = level_data.get("effect", [])
	if effect is Array:
		return effect
	if effect is Dictionary and not effect.is_empty():
		return [effect]
	return []

func get_spell_star_data(spell_id: String, star: int) -> Dictionary:
	var spell = get_spell_data(spell_id)
	var stars = spell.get("stars", {})
	return stars.get(str(star), {})

func apply_remote_config(remote_data: Dictionary) -> void:
	if remote_data.has("spells") and remote_data["spells"] is Dictionary:
		SPELLS = remote_data["spells"].duplicate(true)
