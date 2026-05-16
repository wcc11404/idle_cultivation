extends RefCounted

const UI_UTILS = preload("res://scripts/utils/UIUtils.gd")
const REFRESH_SCOPE_ORDER := ["spell", "inventory", "alchemy", "lianli", "region"]


func load_game_data(ui: Control) -> void:
	var game_manager = ui.get_node("/root/GameManager")
	if not game_manager:
		return

	ui.item_data_ref = game_manager.get_item_data()
	ui.spell_data_ref = game_manager.get_spell_data()
	ui.lianli_system = game_manager.get_lianli_system()
	ui.lianli_area_data = game_manager.get_lianli_area_data()
	ui.enemy_data = game_manager.get_enemy_data()
	ui.set_spell_system(game_manager.get_spell_system())
	ui.set_alchemy_system(game_manager.get_alchemy_system())
	ui.set_recipe_data(game_manager.get_recipe_data())
	ui.set_item_data(game_manager.get_item_data())

	if game_manager.get_player():
		ui.set_player(game_manager.get_player())
	if game_manager.get_inventory():
		ui.set_inventory(game_manager.get_inventory())

	ui.lianli_system = game_manager.get_lianli_system()
	ui.lianli_area_data = game_manager.get_lianli_area_data()

	if ui.lianli_module:
		ui.lianli_module.lianli_system = ui.lianli_system
		ui.lianli_module.lianli_area_data = ui.lianli_area_data
		ui.lianli_module.item_data_ref = ui.item_data_ref
		ui.lianli_module.spell_data = ui.spell_data_ref
		ui.lianli_module.spell_system = ui.spell_system

	if ui.spell_module:
		ui.spell_module.spell_system = ui.spell_system
		ui.spell_module.spell_data = ui.spell_data_ref
		ui.spell_module.player = ui.player
		ui.spell_module.api = ui.api
		ui.spell_module.update_spell_ui()

	if ui.region_module:
		ui.region_module.refresh_cards()
	if ui.lianli_module:
		ui.lianli_module.refresh_selection_cards(ui.dungeon_info_cache)

	game_manager.account_logged_in.connect(ui._on_account_logged_in)
	ui.update_account_ui()


func refresh_all_player_data(ui: Control, options: Dictionary = {}) -> void:
	var refresh_started_at := Time.get_ticks_msec()
	ui._pending_refresh_all_player_data_count += 1
	if ui.cultivation_module:
		await ui.cultivation_module._flush_pending_report()
		if ui.has_method("perf_debug_log_timing"):
			ui.perf_debug_log_timing("refresh_all_player_data flush_pending", Time.get_ticks_msec() - refresh_started_at)

	if ui._test_shutdown_requested or not ui.api:
		ui._pending_refresh_all_player_data_count = maxi(0, ui._pending_refresh_all_player_data_count - 1)
		return

	var load_game_started_at := Time.get_ticks_msec()
	var result = await ui.api.load_game()
	if ui.has_method("perf_debug_log_timing"):
		ui.perf_debug_log_timing("refresh_all_player_data load_game", Time.get_ticks_msec() - load_game_started_at)
	if not result.get("success", false):
		ui._on_module_log("玩家数据同步失败，请检查网络连接")
		if ui.has_method("perf_debug_log_timing"):
			ui.perf_debug_log_timing("refresh_all_player_data total", Time.get_ticks_msec() - refresh_started_at, "success=false")
		ui._pending_refresh_all_player_data_count = maxi(0, ui._pending_refresh_all_player_data_count - 1)
		return

	var data = result.get("data", {})
	var immediate_scopes := _resolve_immediate_scopes(options)
	_apply_player_data_models(ui, data)

	ui.update_ui()
	_refresh_scopes(ui, immediate_scopes)
	_refresh_visible_detail_surfaces(ui, immediate_scopes)
	var defer_other_scopes := bool(options.get("defer_other_scopes", true))
	if defer_other_scopes:
		var deferred_scopes := _get_deferred_scopes(immediate_scopes)
		if ui.has_method("schedule_deferred_refresh_scopes") and not deferred_scopes.is_empty():
			ui.schedule_deferred_refresh_scopes(deferred_scopes)

	if ui.inventory and not ui.inventory.item_added.is_connected(ui._on_item_added):
		ui.inventory.item_added.connect(ui._on_item_added)
	if ui.has_method("perf_debug_log_timing"):
		ui.perf_debug_log_timing("refresh_all_player_data total", Time.get_ticks_msec() - refresh_started_at, "success=true")
	ui._pending_refresh_all_player_data_count = maxi(0, ui._pending_refresh_all_player_data_count - 1)


func run_deferred_refresh_scopes(ui: Control, scopes: Array) -> void:
	var normalized := _normalize_scopes(scopes)
	if normalized.is_empty():
		return
	_refresh_scopes(ui, normalized)


func _resolve_immediate_scopes(options: Dictionary) -> Array[String]:
	var scopes: Array[String] = []
	var priority_scope := str(options.get("priority_scope", ""))
	if not priority_scope.is_empty():
		scopes.append(priority_scope)
	var extra_scopes = options.get("immediate_scopes", [])
	if extra_scopes is Array:
		for scope_variant in extra_scopes:
			scopes.append(str(scope_variant))

	match priority_scope:
		"inventory":
			scopes.append("inventory")
		"alchemy":
			scopes.append("alchemy")
		"lianli":
			scopes.append("lianli")
		"region":
			scopes.append("region")

	return _normalize_scopes(scopes)


func _normalize_scopes(scopes: Array) -> Array[String]:
	var normalized: Array[String] = []
	for ordered_scope in REFRESH_SCOPE_ORDER:
		for scope_variant in scopes:
			var scope := str(scope_variant)
			if scope == ordered_scope and not normalized.has(scope):
				normalized.append(scope)
	return normalized


func _get_deferred_scopes(immediate_scopes: Array[String]) -> Array[String]:
	var deferred: Array[String] = []
	for scope in REFRESH_SCOPE_ORDER:
		if immediate_scopes.has(scope):
			continue
		deferred.append(scope)
	return deferred


func _apply_player_data_models(ui: Control, data: Dictionary) -> void:
	if data.has("spell_system") and ui.spell_system:
		ui.spell_system.apply_save_data(data["spell_system"])

	if data.has("player") and ui.player:
		ui.player.apply_save_data(data["player"])
		if ui.cultivation_module and not ui.player.get_is_cultivating() and ui.cultivation_module.has_method("reset_local_runtime_state"):
			ui.cultivation_module.reset_local_runtime_state(true)

	if data.has("inventory") and ui.inventory:
		ui.inventory.apply_save_data(data["inventory"])

	if data.has("alchemy_system") and ui.alchemy_system:
		ui.alchemy_system.apply_save_data(data["alchemy_system"])

	if data.has("lianli_system") and ui.lianli_module:
		ui.lianli_module.on_player_data_refreshed(data["lianli_system"], false)
	elif data.has("lianli_system") and ui.lianli_system and ui.lianli_system.has_method("apply_save_data"):
		ui.lianli_system.apply_save_data(data["lianli_system"])

	if ui.has_method("sync_dungeon_info_cache_from_lianli_system"):
		ui.sync_dungeon_info_cache_from_lianli_system()


func _refresh_scopes(ui: Control, scopes: Array[String]) -> void:
	for scope in scopes:
		match scope:
			"spell":
				_refresh_spell_scope(ui)
			"inventory":
				_refresh_inventory_scope(ui)
			"alchemy":
				_refresh_alchemy_scope(ui)
			"lianli":
				_refresh_lianli_scope(ui)
			"region":
				_refresh_region_scope(ui)


func _refresh_visible_detail_surfaces(ui: Control, immediate_scopes: Array[String]) -> void:
	if not ui.spell_module or immediate_scopes.has("spell"):
		return
	ui.spell_module.spell_system = ui.spell_system
	ui.spell_module.spell_data = ui.spell_data_ref
	ui.spell_module.player = ui.player
	ui.spell_module.api = ui.api
	if ui.spell_module.has_method("refresh_visible_detail_popup"):
		ui.spell_module.refresh_visible_detail_popup()


func _refresh_spell_scope(ui: Control) -> void:
	if not ui.spell_module:
		return
	ui.spell_module.spell_system = ui.spell_system
	ui.spell_module.spell_data = ui.spell_data_ref
	ui.spell_module.player = ui.player
	ui.spell_module.api = ui.api
	ui.spell_module.update_spell_ui()


func _refresh_inventory_scope(ui: Control) -> void:
	if not ui.chuna_module:
		return
	ui.chuna_module.inventory = ui.inventory
	ui.chuna_module.item_data = ui.item_data_ref
	ui.chuna_module.setup_inventory_grid()
	ui.chuna_module.update_inventory_ui()


func _refresh_alchemy_scope(ui: Control) -> void:
	if not ui.alchemy_module:
		return
	ui.alchemy_module.alchemy_system = ui.alchemy_system
	ui.alchemy_module.item_data = ui.item_data_ref
	ui.alchemy_module.refresh_ui()


func _refresh_lianli_scope(ui: Control) -> void:
	if not ui.lianli_module:
		return
	ui.lianli_module.inventory = ui.inventory
	ui.lianli_module.item_data_ref = ui.item_data_ref
	ui.lianli_module.lianli_system = ui.lianli_system
	ui.lianli_module.lianli_area_data = ui.lianli_area_data
	ui.update_lianli_area_buttons_display()


func _refresh_region_scope(ui: Control) -> void:
	if ui.region_module:
		ui.region_module.refresh_cards()


func refresh_notification_badges_from_server(ui: Control) -> void:
	if ui._test_shutdown_requested:
		return

	ui._pending_notification_refresh_count += 1
	if ui.task_module:
		await ui.task_module.refresh_indicator_only()
	elif ui.api:
		var task_result: Dictionary = await ui.api.task_list()
		if task_result.get("success", false):
			ui._on_task_state_changed(ui._count_claimable_tasks_from_result(task_result))

	if ui.mail_module:
		await ui.mail_module.refresh_indicator_only()
	elif ui.api:
		var mail_result: Dictionary = await ui.api.mail_list()
		if mail_result.get("success", false):
			ui._on_mail_state_changed(int(mail_result.get("unread_count", 0)), int(mail_result.get("count", 0)))
	ui._pending_notification_refresh_count = maxi(0, ui._pending_notification_refresh_count - 1)


func claim_offline_reward(ui: Control) -> void:
	var game_manager = ui.get_node("/root/GameManager")
	if not game_manager or not ui.api:
		return

	var result = await ui.api.claim_offline_reward()
	if result.get("success", false):
		var reward = result.get("offline_reward", null)
		if reward != null and reward is Dictionary:
			var rewarded_offline_seconds = int(result.get("offline_seconds", 0))
			var total_minutes = int(rewarded_offline_seconds / 60)
			var hours = int(total_minutes / 60)
			var minutes = total_minutes % 60

			if ui.player and reward.has("spirit_energy"):
				ui.player.add_spirit(reward.spirit_energy)
			if reward.has("spirit_stones") and ui.inventory:
				ui.inventory.add_item("spirit_stone", reward.spirit_stones)

			if ui.log_manager:
				ui.log_manager.add_system_log("===================================")
				ui.log_manager.add_system_log("离线时长: " + str(hours) + "小时" + str(minutes) + "分钟")
				ui.log_manager.add_system_log("获得离线奖励：")
				if reward.has("spirit_energy"):
					ui.log_manager.add_system_log("  - 灵气: +" + UI_UTILS.format_display_number(float(reward.spirit_energy)))
				if reward.has("spirit_stones"):
					ui.log_manager.add_system_log("  - 灵石: +" + UI_UTILS.format_display_number(float(reward.spirit_stones)))
				ui.log_manager.add_system_log("===================================")
			ui.update_ui()
			ui.refresh_inventory_ui()
	else:
		if ui.log_manager:
			var err_msg = ui._get_offline_reward_result_message(result, "获取离线奖励失败")
			if err_msg.is_empty():
				ui.log_manager.add_system_log("获取离线奖励失败")
			else:
				ui.log_manager.add_system_log(err_msg)
