extends GutTest

var cultivation_module: CultivationModule = null
var mock_player: Node = null
var mock_ui: Node = null
var mock_api: Node = null
var mock_game_manager: Node = null
var mock_inventory: Node = null
var mock_item_data: Node = null
var mock_button: Button = null
var logged_messages: Array = []

func before_all():
	await get_tree().process_frame

func before_each():
	cultivation_module = CultivationModule.new()
	mock_player = _create_mock_player()
	mock_ui = _create_mock_ui()
	mock_api = _create_mock_api()
	mock_game_manager = _create_mock_game_manager()

	add_child(cultivation_module)
	get_tree().root.add_child(mock_game_manager)
	await get_tree().process_frame

	cultivation_module.initialize(mock_ui, mock_player, null, null, null, null, mock_api)
	cultivation_module.log_message.connect(func(message: String): logged_messages.append(message))

func after_each():
	if cultivation_module:
		cultivation_module.free()
	if mock_player:
		mock_player.free()
	if mock_ui:
		mock_ui.free()
	if mock_api:
		mock_api.free()
	if mock_game_manager:
		mock_game_manager.free()
	if mock_inventory:
		mock_inventory.free()
	if mock_item_data:
		mock_item_data.free()
	if mock_button:
		mock_button.free()
	logged_messages.clear()

func test_health_regen_accumulator_resets_after_successful_report_batch():
	mock_player.base_health_regen = 0.55
	mock_player.health = 0.0

	for _i in range(5):
		cultivation_module._optimistic_tick_once()

	assert_eq(mock_player.health, 2.0, "首个5秒批次的乐观回血应为2点")
	assert_eq(cultivation_module._pending_count, 5, "应累计5次待上报tick")

	var result = await cultivation_module._flush_pending_report(5)
	assert_true(result, "上报应成功")
	assert_eq(cultivation_module._pending_count, 0, "成功上报后不应残留待上报tick")
	assert_eq(cultivation_module._optimistic_health_regen_accumulator, 0.0, "成功上报后应重置回血小数累计")

	for _i in range(5):
		cultivation_module._optimistic_tick_once()

	assert_eq(mock_player.health, 4.0, "第二个5秒批次不应继承上一批的小数尾数")

func test_breakthrough_preview_text_describes_missing_resources():
	var preview = {
		"can": false,
		"reason": "灵气不足",
		"energy_cost": 20,
		"spirit_energy_current": 7.2,
		"stone_cost": 12,
		"spirit_stone_current": 5,
		"materials": {
			"foundation_pill": {
				"required": 2,
				"current": 0
			}
		}
	}

	mock_item_data = _create_mock_item_data()
	cultivation_module.item_data = mock_item_data
	var text = cultivation_module._build_breakthrough_preview_text(preview)
	assert_eq(text, "筑基丹不足（0/2）", "应优先展示具体缺口与当前/需要数量")

func test_update_display_sets_breakthrough_tooltip_from_local_preview():
	mock_button = Button.new()
	cultivation_module.breakthrough_button = mock_button
	mock_inventory = _create_mock_inventory({
		"spirit_stone": 30,
		"foundation_pill": 0
	})
	cultivation_module.inventory = mock_inventory
	mock_item_data = _create_mock_item_data()
	cultivation_module.item_data = mock_item_data
	mock_player.realm = "炼气期"
	mock_player.realm_level = 10
	mock_player.spirit_energy = 120.0
	mock_player.cultivation_active = false

	cultivation_module.update_display({
		"health": mock_player.health,
		"spirit_energy": mock_player.spirit_energy,
		"is_cultivating": false,
		"can_breakthrough": {"type": "realm"}
	})

	assert_eq(mock_button.tooltip_text, "筑基丹不足（0/1）", "tooltip应展示具体缺口与当前/需要数量")

func test_breakthrough_failure_message_uses_specific_local_reason_when_server_only_returns_resource_shortage():
	mock_inventory = _create_mock_inventory({
		"spirit_stone": 30,
		"foundation_pill": 0
	})
	cultivation_module.inventory = mock_inventory
	mock_item_data = _create_mock_item_data()
	cultivation_module.item_data = mock_item_data
	mock_player.realm = "炼气期"
	mock_player.realm_level = 10
	mock_player.spirit_energy = 120.0

	var err_msg = cultivation_module._resolve_breakthrough_failure_message({
		"success": false,
		"response_code": 200,
		"is_http_ok": true,
		"message": "资源不足"
	})
	assert_eq(err_msg, "筑基丹不足（0/1）", "服务端只返回资源不足时，应回退到具体缺口与当前/需要数量")

func test_breakthrough_uses_local_check_to_block_api_when_resources_are_missing():
	mock_inventory = _create_mock_inventory({
		"spirit_stone": 30,
		"foundation_pill": 0
	})
	cultivation_module.inventory = mock_inventory
	mock_item_data = _create_mock_item_data()
	cultivation_module.item_data = mock_item_data
	mock_player.realm = "炼气期"
	mock_player.realm_level = 10
	mock_player.spirit_energy = 120.0

	await cultivation_module.on_breakthrough_button_pressed()

	assert_eq(mock_api.player_breakthrough_call_count, 0, "本地预检不通过时不应请求突破接口")
	assert_eq(logged_messages.back(), "筑基丹不足（0/1）", "本地预检失败时应直接提示具体缺口与当前/需要数量")

func test_breakthrough_calls_api_after_local_check_passes():
	mock_inventory = _create_mock_inventory({
		"spirit_stone": 30,
		"foundation_pill": 1
	})
	cultivation_module.inventory = mock_inventory
	mock_item_data = _create_mock_item_data()
	cultivation_module.item_data = mock_item_data
	mock_player.realm = "炼气期"
	mock_player.realm_level = 10
	mock_player.spirit_energy = 120.0

	await cultivation_module.on_breakthrough_button_pressed()

	assert_eq(mock_api.player_breakthrough_call_count, 1, "本地预检通过后应请求突破接口")

func _create_mock_player() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var cultivation_active: bool = true
var spirit_energy: float = 0.0
var health: float = 0.0
var base_health_regen: float = 1.0
var final_max_health: float = 100.0
var final_spirit_gain_speed: float = 0.0
var realm: String = "炼气期"
var realm_level: int = 1

func get_is_cultivating() -> bool:
	return cultivation_active

func get_base_health_regen_per_second() -> float:
	return base_health_regen

func get_final_max_health() -> float:
	return final_max_health

func get_final_spirit_gain_speed() -> float:
	return final_spirit_gain_speed

func add_spirit(amount: float) -> float:
	spirit_energy += amount
	return spirit_energy

func heal(amount: float) -> float:
	health = min(final_max_health, health + amount)
	return health
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	mock.name = "MockPlayer"
	return mock

func _create_mock_inventory(counts: Dictionary) -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var counts: Dictionary = {}

func get_item_count(item_id: String) -> int:
	return int(counts.get(item_id, 0))
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	mock.counts = counts.duplicate(true)
	return mock

func _create_mock_item_data() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node

func get_item_name(item_id: String) -> String:
	match item_id:
		"foundation_pill":
			return "筑基丹"
		_:
			return item_id
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	return mock

func _create_mock_ui() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var update_ui_call_count: int = 0

func update_ui():
	update_ui_call_count += 1
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	mock.name = "MockGameUI"
	return mock

func _create_mock_game_manager() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var realm_system: Node = null

func get_realm_system() -> Node:
	return realm_system
"""
	script.reload()

	var manager = Node.new()
	manager.set_script(script)
	manager.name = "GameManager"
	manager.realm_system = _create_mock_realm_system()
	manager.add_child(manager.realm_system)
	return manager

func _create_mock_realm_system() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node

func get_realm_info(realm_name: String) -> Dictionary:
	if realm_name == "炼气期":
		return {"max_level": 10}
	return {}

func get_breakthrough_materials(realm_name: String, current_level: int, is_realm_breakthrough: bool = false) -> Dictionary:
	if realm_name == "炼气期" and current_level >= 10 and is_realm_breakthrough:
		return {"foundation_pill": 1}
	return {}

func can_breakthrough(realm_name: String, current_level: int, spirit_stone: int, spirit_energy: int, inventory_items: Dictionary = {}) -> Dictionary:
	if realm_name != "炼气期":
		return {"can": false, "reason": "未知境界"}
	if current_level >= 10:
		if spirit_energy < 100:
			return {
				"can": false,
				"reason": "灵气不足",
				"type": "realm",
				"energy_cost": 100,
				"stone_cost": 20,
				"materials": {
					"foundation_pill": {
						"required": 1,
						"current": int(inventory_items.get("foundation_pill", 0))
					}
				}
			}
		if spirit_stone < 20:
			return {
				"can": false,
				"reason": "灵石不足",
				"type": "realm",
				"energy_cost": 100,
				"stone_cost": 20,
				"materials": {
					"foundation_pill": {
						"required": 1,
						"current": int(inventory_items.get("foundation_pill", 0))
					}
				}
			}
		if int(inventory_items.get("foundation_pill", 0)) < 1:
			return {
				"can": false,
				"reason": "筑基丹不足",
				"type": "realm",
				"energy_cost": 100,
				"stone_cost": 20,
				"materials": {
					"foundation_pill": {
						"required": 1,
						"current": int(inventory_items.get("foundation_pill", 0))
					}
				}
			}
		return {
			"can": true,
			"type": "realm",
			"next_realm": "筑基期",
			"energy_cost": 100,
			"stone_cost": 20,
			"materials": {
				"foundation_pill": {
					"required": 1,
					"current": int(inventory_items.get("foundation_pill", 0))
				}
			}
		}
	return {"can": true, "type": "level", "energy_cost": 10, "stone_cost": 5, "materials": {}}
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	return mock

func _create_mock_api() -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var last_report_count: int = 0
var player_breakthrough_call_count: int = 0
var network_manager := NetworkManagerStub.new()

func cultivation_report(count: int) -> Dictionary:
	last_report_count = count
	return {
		"success": true,
		"spirit_gained": 0.0,
		"health_gained": 0.0,
		"used_count_gained": 0,
		"message": "ok"
	}

func player_breakthrough() -> Dictionary:
	player_breakthrough_call_count += 1
	return {
		"success": false,
		"response_code": 200,
		"is_http_ok": true,
		"message": "资源不足"
	}

class NetworkManagerStub:
	func get_api_error_text_for_ui(_result: Dictionary, _fallback: String) -> String:
		return ""
"""
	script.reload()

	var mock = Node.new()
	mock.set_script(script)
	mock.name = "MockApi"
	return mock
