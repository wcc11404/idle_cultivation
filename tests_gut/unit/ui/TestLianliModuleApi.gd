extends GutTest

const MODULE_HARNESS = preload("res://tests_gut/support/ModuleHarness.gd")

class FakeLianliNetworkManager:
	extends Node

	func get_api_error_text_for_ui(_result: Dictionary, fallback: String = "") -> String:
		return fallback

class FakeLianliApi:
	extends Node

	var network_manager := FakeLianliNetworkManager.new()
	var simulate_calls: int = 0
	var finish_calls: int = 0
	var speed_options_calls: int = 0
	var speed_options_result: Dictionary = {
		"success": true,
		"reason_code": "LIANLI_SPEED_OPTIONS_SUCCEEDED",
		"reason_data": {},
		"available_speeds": [1.0],
		"default_speed": 1.0,
	}

	func _ready():
		add_child(network_manager)

	func lianli_finish(_speed: float, _index = null) -> Dictionary:
		finish_calls += 1
		return {
			"success": true,
			"reason_code": "LIANLI_FINISH_FULLY_SETTLED",
			"reason_data": {},
			"loot_gained": []
		}

	func lianli_simulate(area_id: String) -> Dictionary:
		simulate_calls += 1
		return {
			"success": true,
			"reason_code": "LIANLI_SIMULATE_SUCCEEDED",
			"reason_data": {},
			"battle_timeline": [
				{
					"time": 0.1,
					"type": "player_action",
					"info": {
						"spell_id": "norm_attack",
						"effect_type": "instant_damage",
						"damage": 1,
						"target_health_after": 99
					}
				}
			],
			"total_time": 0.2,
			"victory": true,
			"loot": [],
			"enemy_data": {"name": "测试敌人", "level": 1, "health": 100},
			"player_health_after": 100,
			"area_id": area_id
		}

	func lianli_speed_options() -> Dictionary:
		speed_options_calls += 1
		return speed_options_result.duplicate(true)

class CaptureFinishApi:
	extends FakeLianliApi

	var captured_finish_index = "__unset__"
	var captured_finish_speed: float = -1.0

	func lianli_finish(_speed: float, _index = null) -> Dictionary:
		captured_finish_speed = _speed
		captured_finish_index = _index
		return await super.lianli_finish(_speed, _index)

var harness: ModuleHarness = null

func before_each():
	harness = MODULE_HARNESS.new()
	add_child(harness)
	await harness.bootstrap("http://localhost:8444/api", "lianli_ready")

func after_each():
	if harness:
		await harness.cleanup()
		harness.free()
		harness = null
	await get_tree().process_frame

func test_lianli_local_state_keeps_scene_panel_when_returning_to_tab():
	var module = harness.game_ui.lianli_module
	var sim_result = await harness.client.lianli_simulate("area_1")
	assert_true(sim_result.get("success", false), "历练模拟应先成功")
	module._start_timeline_from_simulation(sim_result, "area_1")

	assert_true(harness.get_game_manager().get_lianli_system().is_in_lianli, "进入区域后客户端应记录历练态")
	assert_eq(harness.get_game_manager().get_lianli_system().current_area_id, "area_1", "应记录当前历练区域")

	harness.game_ui.show_chuna_tab()
	harness.game_ui.show_lianli_tab()

	assert_true(module.lianli_scene_panel.visible, "返回历练页时应直接回到战斗面板")
	assert_false(module.lianli_select_panel.visible, "返回历练页时不应回到区域选择页")

func test_lianli_finish_failure_exits_battle_and_returns_to_select_panel():
	var module = harness.game_ui.lianli_module
	var sim_result = await harness.client.lianli_simulate("area_1")
	assert_true(sim_result.get("success", false), "历练模拟应先成功")
	module._start_timeline_from_simulation(sim_result, "area_1")
	harness.clear_logs()

	await module._finish_current_battle(true)

	assert_true(harness.last_log().contains("历练结算同步异常，请稍后重试"), "过早结算应提示同步异常，实际为: %s" % harness.last_log())
	assert_false(harness.get_game_manager().get_lianli_system().is_in_lianli, "结算失败后应退出本地历练态")
	assert_true(module.lianli_select_panel.visible, "结算失败后应返回区域选择页")

func test_lianli_local_health_check_blocks_entry():
	var set_state = await harness.client.test_post("/test/set_player_state", {"health": 0})
	assert_true(set_state.get("success", false), "应能构造低气血状态")
	await harness.sync_full_state()

	var module = harness.game_ui.lianli_module
	harness.clear_logs()
	await module.start_lianli_in_area("area_1")

	assert_eq(harness.last_log(), "气血值不足，无法进入历练区域！请先修炼恢复气血值。", "本地气血校验应先于服务端请求拦截")

func test_lianli_daily_dungeon_limit_uses_reason_code_copy():
	var runtime = await harness.client.test_post(
		"/test/set_runtime_state",
		{"is_cultivating": false}
	)
	assert_true(runtime.get("success", false), "应能确保非修炼态，避免前置 flush 干扰本用例")
	var cultivation_module = harness.game_ui.cultivation_module
	if cultivation_module:
		cultivation_module._pending_elapsed_seconds = 0.0
		cultivation_module._last_optimistic_update_at = 0.0
		cultivation_module._optimistic_tick_accumulator = 0.0
	var player = harness.get_game_manager().get_player()
	if player:
		player.cultivation_active = false
	var progress = await harness.client.test_post(
		"/test/set_progress_state",
		{"daily_dungeon_remaining_counts": {"foundation_herb_cave": 0}}
	)
	assert_true(progress.get("success", false), "应能设置日副本剩余次数")
	await harness.sync_full_state()

	var module = harness.game_ui.lianli_module
	harness.clear_logs()
	await module.start_lianli_in_area("foundation_herb_cave")

	assert_eq(harness.last_log(), "今日副本次数已用完", "日副本次数耗尽应提示固定文案")

func test_lianli_continuous_waiting_flow_advances_to_next_simulation():
	var module = harness.game_ui.lianli_module
	var fake_api = FakeLianliApi.new()
	module.add_child(fake_api)
	module.api = fake_api
	module.continuous_checkbox.button_pressed = true
	module.on_continuous_toggled(true)

	module._start_timeline_from_simulation(
		{
			"battle_timeline": [],
			"total_time": 0.0,
			"victory": true,
			"loot": [],
			"enemy_data": {"name": "测试敌人", "level": 1, "health": 100},
			"player_health_after": 100
		},
		"area_1"
	)

	await module._finish_current_battle(true)
	assert_true(module._is_waiting, "连续战斗开启后，结算胜利应进入等待态")
	assert_true(harness.get_game_manager().get_lianli_system().is_waiting, "等待态应写入本地 lianli_system")

	module._wait_interval = 0.01
	module._wait_timer = 0.0
	await module._process(0.02)

	assert_eq(fake_api.simulate_calls, 1, "等待结束后应自动发起下一场模拟")
	assert_false(module._is_waiting, "下一场模拟启动后应退出等待态")
	assert_true(module.continuous_checkbox.button_pressed, "连续战斗勾选在进入下一场后不应被默认值覆盖")

func test_lianli_continuous_choice_kept_after_next_battle_start():
	var module = harness.game_ui.lianli_module
	var fake_api = FakeLianliApi.new()
	module.add_child(fake_api)
	module.api = fake_api

	module.current_lianli_area_id = "area_1"
	module.continuous_checkbox.button_pressed = true
	module.on_continuous_toggled(true)

	module._start_timeline_from_simulation(
		{
			"battle_timeline": [],
			"total_time": 0.0,
			"victory": true,
			"loot": [],
			"enemy_data": {"name": "测试敌人", "level": 1, "health": 100},
			"player_health_after": 100
		},
		"area_1"
	)

	await module._finish_current_battle(true)
	module._wait_interval = 0.01
	module._wait_timer = 0.0
	await module._process(0.02)

	assert_eq(fake_api.simulate_calls, 1, "连战应进入下一场模拟")
	assert_true(module._is_timeline_running, "下一场模拟后应进入时间轴播放态")
	assert_true(module.continuous_checkbox.button_pressed, "仅首次进入历练按配置加载，后续应保持用户勾选")


func test_lianli_selection_cards_render_expected_copy():
	var module = harness.game_ui.lianli_module
	harness.game_ui.dungeon_info_cache["foundation_herb_cave"] = {
		"remaining_count": 2,
		"max_count": 3
	}
	module.refresh_selection_cards(harness.game_ui.dungeon_info_cache)

	var tower_card = module._selection_cards.get("sourth_endless_tower")
	var daily_card = module._selection_cards.get("foundation_herb_cave")
	assert_not_null(tower_card, "应渲染试练塔卡片")
	assert_not_null(daily_card, "应渲染每日副本卡片")
	assert_eq(tower_card.get_button_text(), "开始试炼", "试练塔按钮文案应固定")
	assert_eq(tower_card.get_title_suffix_text(), "当前挑战 第1层", "试练塔副标题应显示当前挑战层数")
	assert_eq(daily_card.get_title_text(), "破境草洞穴", "每日副本名称应使用定稿文案")
	assert_eq(daily_card.get_title_suffix_text(), "今日剩余次数 2/3", "每日副本副标题应显示今日剩余次数")
	assert_true(daily_card.get_tag_texts().has("每日次数限制"), "每日副本应额外显示每日限制标签")


func test_lianli_selection_cards_group_by_area_sections():
	var module = harness.game_ui.lianli_module
	harness.game_ui.dungeon_info_cache["foundation_herb_cave"] = {
		"remaining_count": 2,
		"max_count": 3
	}
	module.refresh_selection_cards(harness.game_ui.dungeon_info_cache)

	assert_not_null(module._select_root_list, "历练页应创建根列表")
	assert_eq(module._select_root_list.get_child_count(), 6, "历练页应包含三个分组标题和三个卡片列表")

	var normal_section = module._select_root_list.get_child(0)
	var normal_list = module._select_root_list.get_child(1)
	var daily_section = module._select_root_list.get_child(2)
	var daily_list = module._select_root_list.get_child(3)
	var special_section = module._select_root_list.get_child(4)
	var special_list = module._select_root_list.get_child(5)

	assert_eq(_get_section_title(normal_section), "普通区域", "首个分组标题应为普通区域")
	assert_eq(_get_section_title(daily_section), "每日区域", "第二个分组标题应为每日区域")
	assert_eq(_get_section_title(special_section), "特殊区域", "第三个分组标题应为特殊区域")
	assert_eq(normal_list.get_child_count(), 4, "普通区域下应有四张区域卡片")
	assert_eq(daily_list.get_child_count(), 1, "每日区域下应有一张区域卡片")
	assert_eq(special_list.get_child_count(), 1, "特殊区域下应有一张区域卡片")

	var normal_titles: Array[String] = []
	for child in normal_list.get_children():
		normal_titles.append(child.get_title_text())
	assert_eq(normal_titles.size(), 4, "普通区域应渲染四张卡片")

	var daily_titles: Array[String] = []
	for child in daily_list.get_children():
		daily_titles.append(child.get_title_text())
	assert_eq(daily_titles, ["破境草洞穴"], "每日区域卡片应为破境草洞穴")

	var special_titles: Array[String] = []
	for child in special_list.get_children():
		special_titles.append(child.get_title_text())
	assert_eq(special_titles.size(), 1, "特殊区域应渲染一张卡片")
	assert_true(special_titles[0].contains("试练塔"), "特殊区域卡片应为试练塔")


func test_daily_dungeon_card_refreshes_remaining_count_after_player_data_sync():
	var game_ui = harness.game_ui
	var module = game_ui.lianli_module
	var lianli_data := {
		"tower_highest_floor": 0,
		"daily_dungeon_data": {
			"foundation_herb_cave": {
				"remaining_count": 1,
				"max_count": 3
			}
		}
	}

	module.on_player_data_refreshed(lianli_data)
	game_ui.sync_dungeon_info_cache_from_lianli_system()
	game_ui.update_lianli_area_buttons_display()

	var daily_card = module._selection_cards.get("foundation_herb_cave")
	assert_not_null(daily_card, "应渲染每日副本卡片")
	assert_eq(game_ui.dungeon_info_cache["foundation_herb_cave"]["remaining_count"], 1, "日副本缓存应同步为最新剩余次数")
	assert_eq(daily_card.get_title_suffix_text(), "今日剩余次数 1/3", "玩家数据刷新后每日副本卡片应立刻显示最新剩余次数")

func test_lianli_exit_before_first_event_uses_minus_one_index():
	var module = harness.game_ui.lianli_module
	var capture_api = CaptureFinishApi.new()
	module.add_child(capture_api)
	module.api = capture_api

	module._start_timeline_from_simulation(
		{
			"battle_timeline": [
				{
					"time": 1.0,
					"type": "player_action",
					"info": {
						"spell_id": "norm_attack",
						"effect_type": "instant_damage",
						"damage": 1,
						"target_health_after": 99
					}
				}
			],
			"total_time": 1.0,
			"victory": true,
			"loot": [],
			"enemy_data": {"name": "测试敌人", "level": 1, "health": 100},
			"player_health_after": 100
		},
		"area_1"
	)
	module._timeline_cursor = 0

	await module._finish_current_battle(false)

	assert_eq(capture_api.captured_finish_index, -1, "首个事件前退出应上传 index=-1")

func test_lianli_full_settle_uses_null_index():
	var module = harness.game_ui.lianli_module
	var capture_api = CaptureFinishApi.new()
	module.add_child(capture_api)
	module.api = capture_api

	module._start_timeline_from_simulation(
		{
			"battle_timeline": [],
			"total_time": 0.0,
			"victory": true,
			"loot": [],
			"enemy_data": {"name": "测试敌人", "level": 1, "health": 100},
			"player_health_after": 100
		},
		"area_1"
	)

	await module._finish_current_battle(true)

	assert_eq(capture_api.captured_finish_index, null, "完整结算应上传 null（请求体省略 index）")

func test_tower_reward_panel_shows_current_floor_reward_when_current_floor_is_reward_floor():
	var module = harness.game_ui.lianli_module
	var lianli_sys = harness.get_game_manager().get_lianli_system()

	module.current_lianli_area_id = "sourth_endless_tower"
	lianli_sys.is_in_tower = true
	lianli_sys.current_tower_floor = 5

	module._update_battle_info()

	assert_eq(
		module.reward_info_label.text,
		"距离奖励层还需挑战 0 层（第5层）\n奖励：10灵石、1补血丹、1基础吐纳",
		"当前挑战层本身就是奖励层时，应显示当前层奖励而不是下一奖励层"
	)

func test_lianli_speed_button_shows_block_message_when_only_default_speed_available():
	var module = harness.game_ui.lianli_module
	var fake_api = FakeLianliApi.new()
	module.add_child(fake_api)
	module.api = fake_api
	fake_api.speed_options_result["available_speeds"] = [1.0]
	harness.clear_logs()

	await module.on_lianli_speed_pressed()

	assert_eq(module.current_lianli_speed, 1.0, "仅有 1 倍速可用时不应切换")
	assert_eq(harness.last_log(), "达到金丹期后可以切换1.5倍速", "仅默认倍速可用时应提示解锁条件")

func test_lianli_speed_button_cycles_with_server_available_speeds():
	var module = harness.game_ui.lianli_module
	var fake_api = FakeLianliApi.new()
	module.add_child(fake_api)
	module.api = fake_api
	fake_api.speed_options_result["available_speeds"] = [1.0, 1.5]

	await module.on_lianli_speed_pressed()
	assert_eq(module.current_lianli_speed, 1.5, "金丹可用 1.5 倍速时应从 1 切到 1.5")
	assert_eq(module.lianli_speed_button.text, "历练速度: 1.5x", "按钮文案应更新为 1.5x")

	await module.on_lianli_speed_pressed()
	assert_eq(module.current_lianli_speed, 1.0, "可用集合仅 1 和 1.5 时应循环回 1")

func test_lianli_speed_button_cycles_three_available_speeds():
	var module = harness.game_ui.lianli_module
	var fake_api = FakeLianliApi.new()
	module.add_child(fake_api)
	module.api = fake_api
	fake_api.speed_options_result["available_speeds"] = [1.0, 1.5, 2.0]

	await module.on_lianli_speed_pressed()
	await module.on_lianli_speed_pressed()

	assert_eq(module.current_lianli_speed, 2.0, "VIP 可用三档时应能切换到 2 倍速")
	assert_eq(module.lianli_speed_button.text, "历练速度: 2x", "按钮文案应更新为 2x")


func _get_section_title(section: Node) -> String:
	if not section:
		return ""
	var title_label = section.get_child(0)
	return title_label.text if title_label is Label else ""
