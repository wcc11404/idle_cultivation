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

func test_duplicate_unlock_item_uses_unified_already_used_copy():
	var module = harness.game_ui.chuna_module
	var set_result = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"spell_basic_health": 2
		}
	})
	assert_true(set_result.get("success", false), "应能构造重复术法书状态")
	await harness.sync_full_state()

	var spell_book_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "spell_basic_health")
	assert_gt(spell_book_index, -1, "背包中应存在基础气血术法书")

	module._select_slot(spell_book_index)
	await module._on_use_button_pressed()
	await harness.sync_full_state()

	spell_book_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "spell_basic_health")
	assert_gt(spell_book_index, -1, "首次使用后仍应剩余1本术法书")

	await get_tree().create_timer(0.12).timeout
	module._select_slot(spell_book_index)
	harness.clear_logs()
	await module._on_use_button_pressed()

	var item_name = harness.get_item_data().get_item_name("spell_basic_health")
	assert_eq(harness.last_log(), item_name + "已经使用过了，无法重复使用", "重复使用一次性物品应走统一文案")

func test_inventory_use_not_enough_uses_client_copy():
	var module = harness.game_ui.chuna_module
	var set_result = await harness.client.test_post("/test/set_inventory_items", {
		"items": {
			"health_pill": 0
		}
	})
	assert_true(set_result.get("success", false), "应能清空补血丹库存")
	await harness.sync_full_state()

	module.current_selected_item_id = "health_pill"
	module.current_selected_index = 0
	harness.clear_logs()
	await module._on_use_button_pressed()

	assert_eq(harness.last_log(), "补血丹数量不足", "物品不足应使用客户端固定文案")

func test_inventory_expand_and_organize_use_reason_code_copy():
	var module = harness.game_ui.chuna_module

	harness.clear_logs()
	await module._on_expand_button_pressed()
	assert_eq(harness.last_log(), "纳戒已达到最大容量", "容量上限为40时应提示已达上限")

	harness.clear_logs()
	await module._on_sort_button_pressed()
	assert_eq(harness.last_log(), "纳戒已整理", "整理应输出固定成功文案")

func test_discard_important_item_cancel_keeps_item_and_logs_cancel():
	var module = harness.game_ui.chuna_module
	var slot_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "test_pack")
	assert_gt(slot_index, -1, "重置后应存在测试礼包（重要物品）")

	var before_count = int(harness.get_inventory().get_item_count("test_pack"))
	module._select_slot(slot_index)
	harness.clear_logs()
	await module._on_discard_button_pressed()

	var dialog: Control = null
	var search_roots: Array = [harness.game_ui, module.chuna_panel]
	for root in search_roots:
		if not root:
			continue
		for child in root.get_children():
			if child is Control and child.name == "DiscardConfirmOverlay":
				dialog = child
				break
		if dialog:
			break
	assert_not_null(dialog, "重要物品丢弃应弹出确认弹窗")

	dialog.visible = false
	module._on_discard_cancelled()
	await get_tree().process_frame

	assert_eq(harness.last_log(), "取消丢弃", "取消应输出固定提示")
	assert_eq(int(harness.get_inventory().get_item_count("test_pack")), before_count, "取消后物品数量不应变化")

func test_discard_important_item_confirm_consumes_item():
	var module = harness.game_ui.chuna_module
	var slot_index = FixtureHelper.find_inventory_slot_index(harness.get_inventory(), "test_pack")
	assert_gt(slot_index, -1, "重置后应存在测试礼包（重要物品）")

	var before_count = int(harness.get_inventory().get_item_count("test_pack"))
	module._select_slot(slot_index)
	harness.clear_logs()
	await module._on_discard_button_pressed()

	var dialog: Control = null
	var search_roots: Array = [harness.game_ui, module.chuna_panel]
	for root in search_roots:
		if not root:
			continue
		for child in root.get_children():
			if child is Control and child.name == "DiscardConfirmOverlay":
				dialog = child
				break
		if dialog:
			break
	assert_not_null(dialog, "重要物品丢弃应弹出确认弹窗")

	module._on_discard_confirmed()
	await get_tree().process_frame
	if harness.game_ui and harness.game_ui.has_method("await_pending_test_tasks"):
		await harness.game_ui.await_pending_test_tasks()
	else:
		await get_tree().create_timer(0.3).timeout

	assert_true(harness.last_log().contains("丢弃成功"), "确认后应执行丢弃并输出成功文案")
	assert_eq(int(harness.get_inventory().get_item_count("test_pack")), before_count - 1, "确认后应实际扣减物品")
