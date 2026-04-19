extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

var harness: ModuleHarness = null

func _toggle_and_get_last_log(module, retries: int = 3, retry_wait: float = 0.12) -> String:
	for i in range(retries):
		await module._on_spell_equip_toggle()
		var msg = harness.last_log()
		if not msg.is_empty():
			return msg
		if i < retries - 1:
			await get_tree().create_timer(retry_wait).timeout
	return harness.last_log()

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api", "spell_ready")

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_spell_slot_limit_then_unequip_and_equip_messages():
	var module = harness.game_ui.spell_module

	module.current_viewing_spell = "basic_defense"
	harness.clear_logs()
	var limit_msg = await _toggle_and_get_last_log(module)
	assert_eq(limit_msg, "开局术法槽位已达上限，请先卸下任意术法", "槽位上限提示应使用中文槽位名")

	await get_tree().create_timer(0.2).timeout
	module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	var unequip_msg = await _toggle_and_get_last_log(module)
	assert_eq(unequip_msg, "基础步法卸下成功", "卸下成功文案应由客户端翻译")

	await get_tree().create_timer(0.2).timeout
	module.current_viewing_spell = "basic_defense"
	harness.clear_logs()
	var equip_msg = await _toggle_and_get_last_log(module)
	assert_eq(equip_msg, "基础防御装备成功", "装备成功文案应由客户端翻译")

func test_spell_actions_are_locked_during_battle():
	await harness.client.test_post("/test/set_runtime_state", {
		"is_in_lianli": true,
		"is_battling": true,
		"current_area_id": "area_1"
	})

	var spell_module = harness.game_ui.spell_module
	spell_module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	await spell_module._on_spell_equip_toggle()

	assert_true(harness.last_log().contains("战斗中无法"), "战斗中应拦截术法操作并输出客户端文案")

func test_spell_upgrade_and_charge_failure_messages_use_reason_code_copy():
	await harness.reset_and_sync()
	var module = harness.game_ui.spell_module
	var set_items = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_boxing_techniques": 1
		}
	})
	assert_true(set_items.get("success", false), "应能补发基础拳法术法书")
	var unlock_result = await harness.client.inventory_use("spell_basic_boxing_techniques")
	assert_true(unlock_result.get("success", false), "应能先解锁基础拳法")

	module.current_viewing_spell = "basic_boxing_techniques"
	var upgrade_result = await harness.client.spell_upgrade("basic_boxing_techniques")
	assert_false(upgrade_result.get("success", true), "基础拳法在初始状态下不应满足升级条件")
	assert_true(module._get_spell_result_text(upgrade_result, "").contains("使用次数不足"), "升级失败应输出结构化次数不足文案")

	var player_state = await harness.client.test_post("/test/set_player_state", {"spirit_energy": 0})
	assert_true(player_state.get("success", false), "应能构造灵气不足状态")
	await harness.sync_full_state()

	module.current_viewing_spell = "basic_boxing_techniques"
	var charge_result = await harness.client.spell_charge("basic_boxing_techniques", 1)
	assert_false(charge_result.get("success", true), "自身灵气为0时充灵应失败")
	assert_true(module._get_spell_result_text(charge_result, "").contains("自身灵气不足"), "充灵失败应输出结构化灵气不足文案")
