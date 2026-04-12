extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

var harness: ModuleHarness = null

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap("http://127.0.0.1:8444/api", "alchemy_ready")

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_alchemy_insufficient_materials_block_start_with_client_copy():
	var module = harness.game_ui.alchemy_module
	var recipe_id = "health_pill"
	var materials = harness.game_ui.recipe_data.get_recipe_materials(recipe_id)
	var items := {}
	for material_id in materials.keys():
		items[str(material_id)] = 0
	await harness.client.test_post("/test/set_inventory_items", {"items": items})
	await harness.sync_full_state()

	module._select_recipe(recipe_id)
	module.set_craft_count(1)
	harness.clear_logs()
	await module._on_craft_pressed()

	assert_eq(harness.last_log(), "灵材或灵气不足，无法开炉炼丹", "材料不足时应阻止开炉并使用客户端文案")

func test_alchemy_finish_logs_only_summary_and_no_legacy_success_copy():
	var module = harness.game_ui.alchemy_module
	var alchemy_system = harness.get_alchemy_system()
	alchemy_system.special_bonus_speed_rate = 1000.0
	module._select_recipe("health_pill")
	module.set_craft_count(1)
	harness.clear_logs()

	await module._on_craft_pressed()
	while module.is_crafting_active():
		await module._run_alchemy_tick()

	var messages = harness.get_log_messages()
	assert_true(harness.last_log().begins_with("收丹停火：成丹"), "完成后应只输出统一收丹停火汇总")
	for message in messages:
		assert_false(str(message).contains("获得丹药"), "旧的获得丹药文案应已移除")
