extends GutTest

const ModuleHarness = preload("res://tests_gut/support/module_harness.gd")

var harness: ModuleHarness = null

func before_each():
	harness = ModuleHarness.new()
	add_child(harness)
	await harness.bootstrap("http://127.0.0.1:8444/api", "lianli_ready")

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_lianli_local_state_keeps_scene_panel_when_returning_to_tab():
	var module = harness.game_ui.lianli_module
	var sim_result = await harness.client.lianli_simulate("qi_refining_outer")
	assert_true(sim_result.get("success", false), "历练模拟应先成功")
	module._start_timeline_from_simulation(sim_result, "qi_refining_outer")

	assert_true(harness.get_game_manager().get_lianli_system().is_in_lianli, "进入区域后客户端应记录历练态")
	assert_eq(harness.get_game_manager().get_lianli_system().current_area_id, "qi_refining_outer", "应记录当前历练区域")

	harness.game_ui.show_chuna_tab()
	harness.game_ui.show_lianli_tab()

	assert_true(module.lianli_scene_panel.visible, "返回历练页时应直接回到战斗面板")
	assert_false(module.lianli_select_panel.visible, "返回历练页时不应回到区域选择页")

func test_lianli_finish_failure_exits_battle_and_returns_to_select_panel():
	var module = harness.game_ui.lianli_module
	var sim_result = await harness.client.lianli_simulate("qi_refining_outer")
	assert_true(sim_result.get("success", false), "历练模拟应先成功")
	module._start_timeline_from_simulation(sim_result, "qi_refining_outer")
	harness.clear_logs()

	await module._finish_current_battle(true)

	assert_true(harness.last_log().contains("历练结算同步异常，请稍后重试"), "过早结算应提示同步异常，实际为: %s" % harness.last_log())
	assert_false(harness.get_game_manager().get_lianli_system().is_in_lianli, "结算失败后应退出本地历练态")
	assert_true(module.lianli_select_panel.visible, "结算失败后应返回区域选择页")
