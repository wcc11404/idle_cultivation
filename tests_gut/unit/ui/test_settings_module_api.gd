extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

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

func test_change_nickname_invalid_character_uses_client_mapping():
	var module = harness.game_ui.settings_module
	module.nickname_input.text = "ab" + char(0x3000) + "c"
	harness.clear_logs()

	await module._on_confirm_nickname_pressed()

	assert_eq(harness.last_log(), "昵称包含非法字符", "昵称错误提示应来自客户端 reason_code 映射")

func test_change_nickname_success_updates_ui():
	var module = harness.game_ui.settings_module
	var new_name = "qa%06d" % [int(Time.get_unix_time_from_system()) % 1000000]
	module.nickname_input.text = new_name
	harness.clear_logs()

	await module._on_confirm_nickname_pressed()

	assert_eq(harness.last_log(), "昵称修改成功", "昵称修改成功应输出固定文案")
	assert_eq(harness.get_game_manager().get_account_info().get("nickname", ""), new_name, "成功后应更新客户端账号信息")

func test_rank_success_is_silent_but_populates_list():
	var module = harness.game_ui.settings_module
	harness.clear_logs()

	await module._load_rank_data()

	assert_eq(harness.get_log_messages().size(), 0, "排行榜成功加载时不应写入日志")
	assert_gt(module.rank_list.get_child_count(), 0, "排行榜成功后应渲染列表")
