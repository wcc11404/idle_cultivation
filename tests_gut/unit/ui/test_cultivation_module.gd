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

func test_cultivation_start_and_stop_use_real_api():
	var module = harness.game_ui.cultivation_module
	harness.clear_logs()

	await module.on_cultivate_button_pressed()
	assert_true(harness.get_player().get_is_cultivating(), "开始修炼后应进入修炼状态")
	assert_eq(harness.game_ui.active_mode, "cultivation", "开始修炼后应占用修炼模式")
	assert_true(harness.last_log().contains("开始修炼"), "应输出开始修炼日志")

	await get_tree().create_timer(0.25).timeout
	harness.clear_logs()
	await module.on_cultivate_button_pressed()
	assert_false(harness.get_player().get_is_cultivating(), "停止修炼后应退出修炼状态")
	assert_eq(harness.game_ui.active_mode, "none", "停止修炼后应释放修炼模式")
	assert_true(harness.last_log().contains("停止修炼"), "应输出停止修炼日志")

func test_breakthrough_related_action_flushes_pending_report_and_formats_success_text():
	await harness.apply_preset_and_sync("breakthrough_ready")
	var module = harness.game_ui.cultivation_module

	await module.on_cultivate_button_pressed()
	await get_tree().create_timer(4.2).timeout
	assert_true(module._pending_count >= 3, "应先累计待上报修炼tick")

	harness.client.clear_call_counts()
	var settled = await module.flush_pending_and_then(func(): pass)
	assert_true(settled, "突破相关操作前应能成功同步修炼增量")

	assert_eq(module._pending_count, 0, "突破前应先同步完待上报tick")
	assert_eq(harness.client.get_call_count("cultivation_report"), 1, "突破前应调用一次修炼上报")
	var breakthrough_result = await harness.client.player_breakthrough()
	assert_true(breakthrough_result.get("success", false), "突破预设应允许真实突破成功")
	assert_true(module._resolve_cultivation_result_message(breakthrough_result, "").begins_with("突破成功，消耗了"), "突破成功文案应来自 reason_code 翻译")

func test_cultivation_respects_mode_lock_message():
	harness.game_ui.set_active_mode("alchemy")
	var enter_check = harness.game_ui.can_enter_mode("cultivation")
	assert_eq(enter_check.get("message", ""), "请先停止炼丹", "修炼应遵循主界面模式互斥提示")
