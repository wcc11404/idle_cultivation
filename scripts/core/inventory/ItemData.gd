class_name ItemData extends Node

enum ItemType {
	CURRENCY = 0,
	MATERIAL = 1,
	CONSUMABLE = 2,
	GIFT = 3,
	UNLOCK_SPELL = 4,
	UNLOCK_RECIPE = 5,
	UNLOCK_FURNACE = 6,
}

const RARITY_ORDER := {
	"fan": 0,
	"huang": 1,
	"xuan": 2,
	"di": 3,
	"tian": 4
}

const RARITY_COLORS := {
	"fan": Color("#111111"),
	"huang": Color("#1F6A25"),
	"xuan": Color("#00BFFF"),
	"di": Color("#EE82EE"),
	"tian": Color.ORANGE
}

const RARITY_NAMES := {
	"fan": "凡",
	"huang": "黄",
	"xuan": "玄",
	"di": "地",
	"tian": "天"
}

var item_data: Dictionary = {}
var _config_loaded: bool = false

func _init():
	_load_config()

func _ready():
	_load_config()

func _load_config():
	if _config_loaded:
		return
	var file = FileAccess.open("res://scripts/core/inventory/items.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data:
			item_data = data.get("items", {})
			_config_loaded = true

func get_item_data(item_id: String) -> Dictionary:
	return item_data.get(item_id, {})

func get_item_name(item_id: String) -> String:
	var data = get_item_data(item_id)
	return data.get("name", "未知物品")

func normalize_rarity(rarity: String) -> String:
	var normalized := rarity.to_lower()
	return normalized if RARITY_ORDER.has(normalized) else "fan"

func get_rarity_rank(rarity: String) -> int:
	return int(RARITY_ORDER.get(normalize_rarity(rarity), 0))

func get_rarity_color(rarity: String) -> Color:
	return Color(RARITY_COLORS.get(normalize_rarity(rarity), RARITY_COLORS["fan"]))

func get_rarity_display_name(rarity: String) -> String:
	return str(RARITY_NAMES.get(normalize_rarity(rarity), RARITY_NAMES["fan"]))

func get_item_rarity_color(rarity: String) -> Color:
	return get_rarity_color(rarity)

func get_item_type(item_id: String) -> int:
	var data = get_item_data(item_id)
	return data.get("type", ItemType.MATERIAL)

func get_item_type_name(item_id: String) -> String:
	return get_item_type_name_by_value(get_item_type(item_id))

func get_item_type_name_by_value(item_type: int) -> String:
	match item_type:
		ItemType.CURRENCY:
			return "货币"
		ItemType.MATERIAL:
			return "材料"
		ItemType.CONSUMABLE:
			return "消耗品"
		ItemType.GIFT:
			return "宝箱/礼包"
		ItemType.UNLOCK_SPELL:
			return "解锁术法"
		ItemType.UNLOCK_RECIPE:
			return "解锁丹方"
		ItemType.UNLOCK_FURNACE:
			return "解锁炼丹炉"
		_:
			return "未知"

func get_max_stack(item_id: String) -> int:
	var data = get_item_data(item_id)
	return int(data.get("max_stack", 1))

func can_stack(item_id: String) -> bool:
	var data = get_item_data(item_id)
	var max_stack = data.get("max_stack", 1)
	return max_stack > 1

func get_item_description(item_id: String) -> String:
	var data = get_item_data(item_id)
	return data.get("description", "")

func get_item_icon(item_id: String) -> String:
	var data = get_item_data(item_id)
	return data.get("icon", "")

func get_item_rarity(item_id: String) -> String:
	var data = get_item_data(item_id)
	return normalize_rarity(str(data.get("rarity", "fan")))

func get_item_rarity_rank(item_id: String) -> int:
	return get_rarity_rank(get_item_rarity(item_id))

func get_item_effect(item_id: String) -> Dictionary:
	var data = get_item_data(item_id)
	return data.get("effect", {})

func get_item_content(item_id: String) -> Dictionary:
	var data = get_item_data(item_id)
	return data.get("content", {})

func item_exists(item_id: String) -> bool:
	return item_data.has(item_id)

func get_use_text(item_id: String) -> String:
	var item_type = get_item_type(item_id)
	match item_type:
		ItemType.GIFT:
			return "打开"
		ItemType.CONSUMABLE, ItemType.UNLOCK_SPELL, ItemType.UNLOCK_RECIPE, ItemType.UNLOCK_FURNACE:
			return "使用"
		_:
			return ""

func is_important(item_id: String) -> bool:
	var data = get_item_data(item_id)
	var rarity = str(data.get("rarity", "fan"))
	return get_rarity_rank(rarity) >= get_rarity_rank("tian")

func is_currency(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.CURRENCY

func is_material(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.MATERIAL

func is_consumable(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.CONSUMABLE

func is_gift(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.GIFT

func is_unlock_spell(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.UNLOCK_SPELL

func is_unlock_recipe(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.UNLOCK_RECIPE

func is_unlock_furnace(item_id: String) -> bool:
	return get_item_type(item_id) == ItemType.UNLOCK_FURNACE

func get_all_item_ids() -> Array:
	return item_data.keys()

func get_items_by_type(item_type: int) -> Array:
	var result = []
	for item_id in item_data.keys():
		if item_data[item_id].get("type", ItemType.MATERIAL) == item_type:
			result.append(item_id)
	return result
