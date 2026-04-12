extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

var harness: ModuleHarness = null

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap("http://127.0.0.1:8444/api", "spell_ready")

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
	await module._on_spell_equip_toggle()
	assert_eq(harness.last_log(), "开局术法槽位已达上限，请先卸下任意术法", "槽位上限提示应使用中文槽位名")

	await get_tree().create_timer(0.12).timeout
	module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	await module._on_spell_equip_toggle()
	assert_eq(harness.last_log(), "基础步法卸下成功", "卸下成功文案应由客户端翻译")

	await get_tree().create_timer(0.12).timeout
	module.current_viewing_spell = "basic_defense"
	harness.clear_logs()
	await module._on_spell_equip_toggle()
	assert_eq(harness.last_log(), "基础防御装备成功", "装备成功文案应由客户端翻译")

func test_spell_actions_are_locked_during_battle():
	await harness.client.test_post("/test/set_runtime_state", {
		"is_in_lianli": true,
		"is_battling": true,
		"current_area_id": "qi_refining_outer"
	})

	var spell_module = harness.game_ui.spell_module
	spell_module.current_viewing_spell = "basic_steps"
	harness.clear_logs()
	await spell_module._on_spell_equip_toggle()

	assert_true(harness.last_log().contains("战斗中无法"), "战斗中应拦截术法操作并输出客户端文案")
