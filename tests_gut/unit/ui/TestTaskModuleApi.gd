extends GutTest

const MODULE_HARNESS = preload("res://tests_gut/support/ModuleHarness.gd")

var harness: ModuleHarness = null


func before_each():
	harness = MODULE_HARNESS.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api")


func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame


func _find_header_title(node: Node) -> Label:
	if node is Label and node.name == "HeaderTitle":
		return node
	for child in node.get_children():
		var found := _find_header_title(child)
		if found:
			return found
	return null


func _task_card_titles(list_root: VBoxContainer) -> Array:
	var names: Array = []
	for child in list_root.get_children():
		var header_title := _find_header_title(child)
		if header_title:
			names.append(header_title.text)
	return names


func _is_badge_visible(target: Control, key: String) -> bool:
	if not target:
		return false
	var badge = target.get_node_or_null("NotificationBadge_" + key)
	return badge != null and badge.visible


func test_task_panel_renders_and_claim_refreshes():
	await harness.client.reset_account()
	await harness.sync_full_state()

	var module = harness.game_ui.task_module
	assert_not_null(module, "TaskModule 应初始化")

	# 完成一个新手任务并刷新列表。
	var use_pack = await harness.client.inventory_use("starter_pack")
	assert_true(use_pack.get("success", false), "应能成功打开新手礼包Ⅰ")

	await module._refresh_task_list()
	module._on_newbie_tab_pressed()
	assert_gt(module.task_list.get_child_count(), 0, "任务列表应渲染卡片")
	assert_true(_is_badge_visible(harness.game_ui.xianwu_office_button, "task_claimable"), "存在可领奖任务时仙务司按钮红点应点亮")
	assert_true(_is_badge_visible(harness.game_ui.tab_region, "region_tab_badge"), "存在可领奖任务时地区页签红点应点亮")

	await module._on_claim_pressed("newbie_open_starter_pack_1")
	var claim_logs := harness.get_log_messages()
	var claim_logged := false
	for message in claim_logs:
		if str(message).contains("领取成功"):
			claim_logged = true
			break
	assert_true(claim_logged, "领取成功后应有日志提示，实际最后一条为: %s" % harness.last_log())
	assert_false(_is_badge_visible(harness.game_ui.xianwu_office_button, "task_claimable"), "领取完成且无剩余可领奖任务时仙务司按钮红点应熄灭")
	assert_false(_is_badge_visible(harness.game_ui.tab_region, "region_tab_badge"), "领取完成且无剩余可领奖任务时地区页签红点应熄灭")


func test_task_panel_sort_unclaimed_first_claimed_last():
	await harness.client.reset_account()
	await harness.sync_full_state()

	var module = harness.game_ui.task_module
	var use_pack = await harness.client.inventory_use("starter_pack")
	assert_true(use_pack.get("success", false), "应能先完成新手任务Ⅰ")
	await module._refresh_task_list()
	await module._on_claim_pressed("newbie_open_starter_pack_1")
	await module._refresh_task_list()
	module._on_newbie_tab_pressed()

	var titles := _task_card_titles(module.task_list)
	assert_eq(titles.size(), 7, "新手任务卡片数应与配置一致")
	assert_eq(titles[0], "打开新手礼包Ⅱ", "未领取任务应在上方")
	assert_eq(titles[1], "打开新手礼包Ⅲ", "未领取任务应在上方")
	assert_eq(titles[2], "采集10次", "未领取任务应在上方")
	assert_eq(titles[3], "采集20次", "未领取任务应在上方")
	assert_eq(titles[4], "炼成20颗补血丹", "未领取任务应在上方")
	assert_eq(titles[5], "炼成1颗筑基丹", "未领取任务应在上方")
	assert_eq(titles[6], "打开新手礼包Ⅰ", "已领取任务应下沉到底部")
