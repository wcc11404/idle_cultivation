extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")
const FixtureHelper = preload("res://tests_gut/fixtures/fixture_helper.gd")

var harness: ModuleHarness = null

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap()

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_use_test_pack_logs_gift_rewards():
	var module = harness.game_ui.chuna_module
	var slot_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "test_pack")
	assert_gt(slot_index, -1, "重置后测试礼包应存在")

	module._select_slot(slot_index)
	harness.clear_logs()
	await module._on_use_button_pressed()

	assert_true(harness.last_log().contains("打开成功，获得"), "礼包应按客户端文案输出奖励概览")

func test_use_spell_book_after_opening_pack_unlocks_spell_message():
	var module = harness.game_ui.chuna_module
	var pack_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "test_pack")
	module._select_slot(pack_index)
	await module._on_use_button_pressed()

	await harness.sync_full_state()
	await get_tree().create_timer(0.12).timeout
	var spell_book_index := -1
	for index in range(harness.get_inventory().slots.size()):
		var slot = harness.get_inventory().slots[index]
		if slot is Dictionary and not bool(slot.get("empty", true)) and str(slot.get("id", "")).begins_with("spell_"):
			spell_book_index = index
			break
	assert_gt(spell_book_index, -1, "打开测试礼包后应获得术法书")

	module._select_slot(spell_book_index)
	harness.clear_logs()
	await module._on_use_button_pressed()

	assert_true(harness.last_log().contains("术法"), "术法书应输出客户端翻译后的术法提示，实际为: %s" % harness.last_log())

func test_inventory_expand_and_organize_use_reason_code_copy():
	var module = harness.game_ui.chuna_module

	harness.clear_logs()
	await module._on_expand_button_pressed()
	assert_true(harness.last_log().contains("纳戒扩容成功"), "扩容应输出结构化成功文案")

	harness.clear_logs()
	await module._on_sort_button_pressed()
	assert_eq(harness.last_log(), "纳戒已整理", "整理应输出固定成功文案")
