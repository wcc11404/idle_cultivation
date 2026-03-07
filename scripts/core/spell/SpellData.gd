class_name SpellData extends Node

enum SpellType {
	BREATHING,    # 吐纳心法（1种）
	ACTIVE,       # 主动术法（攻击类）
	PASSIVE,      # 被动术法（开局自动释放）
	MISC          # 杂学术法
}

var MAX_BREATHING_SPELLS = 1
var MAX_ACTIVE_SPELLS = 2
var MAX_PASSIVE_SPELLS = 2

var SPELLS: Dictionary = {}

func _ready():
	_load_spells()

func _load_spells():
	var file = FileAccess.open("res://scripts/core/spell/spells.json", FileAccess.READ)
	if file:
		var json_content = file.get_as_text()
		var data = JSON.parse_string(json_content)
		if data:
			if data.has("equipment_limits"):
				MAX_BREATHING_SPELLS = int(data["equipment_limits"].get("MAX_BREATHING_SPELLS", 1))
				MAX_ACTIVE_SPELLS = int(data["equipment_limits"].get("MAX_ACTIVE_SPELLS", 2))
				MAX_PASSIVE_SPELLS = int(data["equipment_limits"].get("MAX_PASSIVE_SPELLS", 2))
			if data.has("spells"):
				SPELLS = _convert_spells_data(data["spells"])
		file.close()
	else:
		print("Error loading spells.json")

func _convert_spells_data(spells_data: Dictionary) -> Dictionary:
	var result = {}
	for spell_id in spells_data.keys():
		var spell = spells_data[spell_id].duplicate(true)
		spell["type"] = int(spell.get("type", 1))
		spell["max_level"] = int(spell.get("max_level", 3))
		if spell.has("levels"):
			spell["levels"] = _convert_levels_data(spell["levels"])
		result[spell_id] = spell
	return result

func _convert_levels_data(levels_data: Dictionary) -> Dictionary:
	var result = {}
	for level_key in levels_data.keys():
		var level_data = levels_data[level_key].duplicate(true)
		level_data["spirit_cost"] = int(level_data.get("spirit_cost", 0))
		level_data["use_count_required"] = int(level_data.get("use_count_required", 0))
		result[int(level_key)] = level_data
	return result

func get_spell_data(spell_id: String) -> Dictionary:
	return SPELLS.get(spell_id, {})

func get_spell_name(spell_id: String) -> String:
	var spell = get_spell_data(spell_id)
	return spell.get("name", "未知术法")

func get_spell_type(spell_id: String) -> int:
	var spell = get_spell_data(spell_id)
	return spell.get("type", SpellType.ACTIVE)

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

func get_spell_level_data(spell_id: String, level: int) -> Dictionary:
	var spell = get_spell_data(spell_id)
	var levels = spell.get("levels", {})
	return levels.get(level, {})

func get_all_spell_ids() -> Array:
	return SPELLS.keys()

func get_spell_ids_by_type(spell_type: int) -> Array:
	var result = []
	for spell_id in SPELLS.keys():
		if SPELLS[spell_id].get("type") == spell_type:
			result.append(spell_id)
	return result

func get_equipment_limit(spell_type: int) -> int:
	match spell_type:
		SpellType.BREATHING:
			return MAX_BREATHING_SPELLS
		SpellType.ACTIVE:
			return MAX_ACTIVE_SPELLS
		SpellType.PASSIVE:
			return MAX_PASSIVE_SPELLS
		SpellType.MISC:
			return -1
		_:
			return 1