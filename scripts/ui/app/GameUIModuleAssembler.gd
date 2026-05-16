extends RefCounted


func setup_alchemy_module(ui: Control) -> void:
	ui.alchemy_module = ui.ALCHEMY_MODULE_SCRIPT.new()
	ui.alchemy_module.name = "AlchemyModule"
	ui.add_child(ui.alchemy_module)

	ui.alchemy_module.alchemy_room_panel = ui.alchemy_room_panel
	ui.alchemy_module.recipe_list_container = ui.recipe_list_container
	ui.alchemy_module.recipe_name_label = ui.recipe_name_label
	ui.alchemy_module.success_rate_label = ui.success_rate_label
	ui.alchemy_module.craft_time_label = ui.craft_time_label
	ui.alchemy_module.materials_container = ui.materials_container
	ui.alchemy_module.craft_button = ui.craft_button
	ui.alchemy_module.stop_button = ui.stop_button
	ui.alchemy_module.craft_progress_bar = ui.craft_progress_bar
	ui.alchemy_module.craft_count_label = ui.craft_count_label
	ui.alchemy_module.alchemy_info_label = ui.alchemy_info_label
	ui.alchemy_module.furnace_info_label = ui.furnace_info_label
	ui.alchemy_module.count_1_button = ui.count_1_button
	ui.alchemy_module.count_10_button = ui.count_10_button
	ui.alchemy_module.count_100_button = ui.count_100_button
	ui.alchemy_module.count_max_button = ui.count_max_button
	ui.alchemy_module.count_plus_10_button = ui.count_plus_10_button
	ui.alchemy_module.count_final_max_button = ui.count_final_max_button
	ui.alchemy_module.alchemy_back_button = ui.alchemy_back_button
	ui.alchemy_module.spell_system = ui.spell_system
	ui.alchemy_module.initialize(ui, ui.player, ui.alchemy_system, ui.recipe_data, ui.item_data_ref, ui.api)
	ui.alchemy_module.setup_styles()

	if ui.count_1_button and not ui.count_1_button.pressed.is_connected(ui._on_craft_count_min):
		ui.count_1_button.pressed.connect(ui._on_craft_count_min)
	if ui.count_10_button:
		_connect_or_skip(ui.count_10_button, func(): ui._on_craft_count_delta(-10))
	if ui.count_100_button:
		_connect_or_skip(ui.count_100_button, func(): ui._on_craft_count_delta(-1))
	if ui.count_max_button:
		_connect_or_skip(ui.count_max_button, func(): ui._on_craft_count_delta(1))
	if ui.count_plus_10_button:
		_connect_or_skip(ui.count_plus_10_button, func(): ui._on_craft_count_delta(10))
	if ui.count_final_max_button and not ui.count_final_max_button.pressed.is_connected(ui._on_craft_count_max):
		ui.count_final_max_button.pressed.connect(ui._on_craft_count_max)

	if not ui.alchemy_module.log_message.is_connected(ui._on_alchemy_log):
		ui.alchemy_module.log_message.connect(ui._on_alchemy_log)
	if not ui.alchemy_module.back_to_dongfu_requested.is_connected(ui._on_back_to_region_requested):
		ui.alchemy_module.back_to_dongfu_requested.connect(ui._on_back_to_region_requested)
	if ui.alchemy_back_button and not ui.alchemy_back_button.pressed.is_connected(ui._on_back_to_region_requested):
		ui.alchemy_back_button.pressed.connect(ui._on_back_to_region_requested)


func setup_settings_module(ui: Control) -> void:
	ui.settings_module = ui.SETTINGS_MODULE_SCRIPT.new()
	ui.settings_module.name = "SettingsModule"
	ui.add_child(ui.settings_module)

	ui.settings_module.settings_panel = ui.settings_panel
	ui.settings_module.save_button = ui.save_button
	ui.settings_module.logout_button = ui.logout_button
	ui.settings_module.rank_button = ui.rank_button
	ui.settings_module.mall_button = ui.mall_button
	ui.settings_module.guide_button = ui.guide_button
	ui.settings_module.mailbox_button = ui.mailbox_button
	ui.settings_module.redeem_confirm_button = ui.redeem_confirm_button
	ui.settings_module.redeem_code_input = ui.redeem_code_input
	ui.settings_module.fps_30_button = ui.fps_30_button
	ui.settings_module.fps_60_button = ui.fps_60_button
	ui.settings_module.fps_120_button = ui.fps_120_button
	ui.settings_module.fps_144_button = ui.fps_144_button
	ui.settings_module.fps_unlimited_button = ui.fps_unlimited_button
	ui.settings_module.fps_limit_option_button = ui.fps_limit_option_button
	ui.settings_module.music_mute_button = ui.music_mute_button
	ui.settings_module.music_volume_slider = ui.music_volume_slider
	ui.settings_module.music_volume_value_label = ui.music_volume_value_label
	ui.settings_module.rank_panel = ui.rank_panel
	ui.settings_module.rank_list = ui.rank_list
	ui.settings_module.back_button = ui.back_button
	ui.settings_module.initialize(ui, ui.player, ui.api)
	if not ui.settings_module.log_message.is_connected(ui._on_module_log):
		ui.settings_module.log_message.connect(ui._on_module_log)
	if not ui.settings_module.mailbox_requested.is_connected(ui._on_mailbox_requested):
		ui.settings_module.mailbox_requested.connect(ui._on_mailbox_requested)


func setup_mail_module(ui: Control) -> void:
	ui.mail_module = ui.MAIL_MODULE_SCRIPT.new()
	ui.mail_module.name = "MailModule"
	ui.add_child(ui.mail_module)
	ui.mail_module.initialize(ui, ui.api, ui.item_data_ref)
	if not ui.mail_module.log_message.is_connected(ui._on_module_log):
		ui.mail_module.log_message.connect(ui._on_module_log)
	if not ui.mail_module.back_requested.is_connected(ui._on_mail_back_requested):
		ui.mail_module.back_requested.connect(ui._on_mail_back_requested)
	if not ui.mail_module.mail_state_changed.is_connected(ui._on_mail_state_changed):
		ui.mail_module.mail_state_changed.connect(ui._on_mail_state_changed)
	ui._setup_system_refresh_timer()


func setup_profile_edit_popup(ui: Control) -> void:
	if ui.profile_edit_popup:
		return
	ui.profile_edit_popup = ui.PROFILE_EDIT_POPUP_SCRIPT.new()
	ui.add_child(ui.profile_edit_popup)
	ui.profile_edit_popup.setup(ui)
	ui.profile_edit_popup.nickname_submit_requested.connect(ui._on_profile_nickname_submit_requested)
	ui.profile_edit_popup.avatar_submit_requested.connect(ui._on_profile_avatar_submit_requested)
	ui.profile_edit_popup.popup_closed.connect(ui._on_profile_popup_closed)

	if ui.top_player_info:
		ui.top_player_info.mouse_filter = Control.MOUSE_FILTER_STOP
		ui._set_children_mouse_filter_ignore(ui.top_player_info)


func setup_region_module(ui: Control) -> void:
	ui.region_module = ui.DONGFU_MODULE_SCRIPT.new()
	ui.region_module.name = "RegionModule"
	ui.add_child(ui.region_module)
	ui.region_module.region_panel = ui.region_panel
	ui.region_module.region_list_host = ui.region_list_host
	ui.region_module.alchemy_workshop_button = ui.alchemy_workshop_button
	ui.region_module.herb_mountain_button = ui.herb_mountain_button
	ui.region_module.xianwu_office_button = ui.xianwu_office_button
	ui.region_module.initialize(ui, ui.player, ui.alchemy_module)
	ui.region_module.log_message.connect(ui._on_module_log)
	ui.region_module.herb_gather_requested.connect(ui._on_herb_gather_requested)
	ui.region_module.task_panel_requested.connect(ui._on_task_panel_requested)


func setup_herb_gather_module(ui: Control) -> void:
	ui.herb_gather_module = ui.HERB_GATHER_MODULE_SCRIPT.new()
	ui.herb_gather_module.name = "HerbGatherModule"
	ui.add_child(ui.herb_gather_module)
	ui.herb_gather_module.herb_gather_panel = ui.herb_gather_panel
	ui.herb_gather_module.point_list = ui.herb_gather_point_list
	ui.herb_gather_module.back_button = ui.herb_gather_back_button
	ui.herb_gather_module.spell_system = ui.spell_system
	ui.herb_gather_module.initialize(ui, ui.player, ui.inventory, ui.item_data_ref, ui.api)
	ui.herb_gather_module.log_message.connect(ui._on_production_log)
	ui.herb_gather_module.back_to_region_requested.connect(ui._on_back_to_region_requested)


func setup_task_module(ui: Control) -> void:
	ui.task_module = ui.TASK_MODULE_SCRIPT.new()
	ui.task_module.name = "TaskModule"
	ui.add_child(ui.task_module)
	ui.task_module.task_panel = ui.task_panel
	ui.task_module.back_button = ui.task_back_button
	ui.task_module.task_tab_bar = ui.task_tab_bar
	ui.task_module.daily_tab_button = ui.task_daily_tab_button
	ui.task_module.newbie_tab_button = ui.task_newbie_tab_button
	ui.task_module.task_scroll = ui.task_scroll
	ui.task_module.task_list = ui.task_list
	ui.task_module.initialize(ui, ui.api)
	ui.task_module.log_message.connect(ui._on_module_log)
	ui.task_module.back_to_region_requested.connect(ui._on_back_to_region_requested)
	if not ui.task_module.task_state_changed.is_connected(ui._on_task_state_changed):
		ui.task_module.task_state_changed.connect(ui._on_task_state_changed)


func setup_chuna_module(ui: Control) -> void:
	ui.chuna_module = ui.CHUNA_MODULE_SCRIPT.new()
	ui.chuna_module.name = "ChunaModule"
	ui.add_child(ui.chuna_module)
	ui.chuna_module.chuna_panel = ui.chuna_panel
	ui.chuna_module.inventory_grid = ui.inventory_grid
	ui.chuna_module.capacity_label = ui.capacity_label
	ui.chuna_module.item_detail_panel = ui.item_detail_panel
	ui.chuna_module.view_button = ui.view_button
	ui.chuna_module.use_button = ui.use_button
	ui.chuna_module.batch_use_button = ui.batch_use_button
	ui.chuna_module.discard_button = ui.discard_button
	ui.chuna_module.expand_button = ui.expand_button
	ui.chuna_module.sort_button = ui.sort_button
	ui.chuna_module.initialize(ui, ui.player, ui.inventory, ui.item_data_ref, ui.spell_system, ui.spell_data_ref, ui.alchemy_system, ui.api, ui.recipe_data)
	ui.chuna_module.log_message.connect(ui._on_module_log)


func setup_spell_module(ui: Control) -> void:
	ui.spell_module = ui.SPELL_MODULE_SCRIPT.new()
	ui.spell_module.name = "SpellModule"
	ui.add_child(ui.spell_module)
	ui.spell_module.spell_panel = ui.spell_panel
	ui.spell_module.spell_tab = ui.spell_tab
	ui.spell_module.initialize(ui, ui.player, ui.spell_system, ui.spell_data_ref, ui.api)
	ui.spell_module.log_message.connect(ui._on_module_log)


func setup_neishi_module(ui: Control) -> void:
	ui.cultivation_module = ui.CULTIVATION_MODULE_SCRIPT.new()
	ui.cultivation_module.name = "CultivationModule"
	ui.add_child(ui.cultivation_module)
	ui.cultivation_module.cultivation_panel = ui.cultivation_panel
	ui.cultivation_module.cultivate_button = ui.cultivate_button
	ui.cultivation_module.breakthrough_button = ui.breakthrough_button
	ui.cultivation_module.breakthrough_material_name_labels = [ui.breakthrough_material_name_label_1, ui.breakthrough_material_name_label_2, ui.breakthrough_material_name_label_3]
	ui.cultivation_module.breakthrough_material_labels = [ui.breakthrough_material_label_1, ui.breakthrough_material_label_2, ui.breakthrough_material_label_3]
	ui.cultivation_module.health_bar = ui.health_bar
	ui.cultivation_module.health_value = ui.health_value
	ui.cultivation_module.spirit_bar = ui.spirit_bar
	ui.cultivation_module.spirit_value = ui.spirit_value
	ui.cultivation_module.attack_value_label = ui.attack_value_label
	ui.cultivation_module.defense_value_label = ui.defense_value_label
	ui.cultivation_module.speed_value_label = ui.speed_value_label
	ui.cultivation_module.penetration_value_label = ui.penetration_value_label
	ui.cultivation_module.hit_value_label = ui.hit_value_label
	ui.cultivation_module.dodge_value_label = ui.dodge_value_label
	ui.cultivation_module.crit_value_label = ui.crit_value_label
	ui.cultivation_module.crit_damage_value_label = ui.crit_damage_value_label
	ui.cultivation_module.anti_crit_value_label = ui.anti_crit_value_label
	ui.cultivation_module.spirit_gain_value_label = ui.spirit_gain_value_label
	ui.cultivation_module.health_regen_value_label = ui.health_regen_value_label
	ui.cultivation_module.status_label = ui.status_label
	ui.cultivation_module.cultivation_figure = ui.cultivation_figure
	ui.cultivation_module.cultivation_figure_particles = ui.cultivation_figure_particles

	var game_manager = ui.get_node("/root/GameManager")
	ui.cultivation_system = game_manager.get_cultivation_system() if game_manager else null
	ui.lianli_system = game_manager.get_lianli_system() if game_manager else null
	var realm_system = game_manager.get_realm_system() if game_manager else null
	ui.cultivation_module.initialize(ui, ui.player, ui.cultivation_system, ui.lianli_system, ui.item_data_ref, ui.alchemy_module, ui.api, ui.spell_system, realm_system)
	ui.cultivation_module.log_message.connect(ui._on_module_log)

	ui.neishi_module = ui.NEISHI_MODULE_SCRIPT.new()
	ui.neishi_module.name = "NeishiModule"
	ui.add_child(ui.neishi_module)
	ui.neishi_module.neishi_panel = ui.neishi_panel
	ui.neishi_module.cultivation_panel = ui.cultivation_panel
	ui.neishi_module.spell_panel = ui.spell_panel
	ui.neishi_module.cultivation_tab = ui.cultivation_tab
	ui.neishi_module.spell_tab = ui.spell_tab
	ui.neishi_module.initialize(ui, ui.player)
	ui.neishi_module.set_cultivation_module(ui.cultivation_module)
	ui.neishi_module.set_spell_module(ui.spell_module)
	ui.neishi_module.log_message.connect(ui._on_module_log)


func setup_lianli_module(ui: Control) -> void:
	ui.lianli_module = ui.LIANLI_MODULE_SCRIPT.new()
	ui.lianli_module.name = "LianliModule"
	ui.add_child(ui.lianli_module)
	ui.lianli_module.lianli_panel = ui.lianli_panel
	ui.lianli_module.lianli_scene_panel = ui.lianli_scene_panel
	ui.lianli_module.lianli_select_panel = ui.lianli_select_panel
	ui.lianli_module.lianli_select_list_host = ui.lianli_select_list_host
	ui.lianli_module.lianli_status_label = ui.lianli_status_label
	ui.lianli_module.area_name_label = ui.area_name_label
	ui.lianli_module.reward_info_label = ui.reward_info_label
	ui.lianli_module.enemy_name_label = ui.enemy_name_label
	ui.lianli_module.enemy_health_bar = ui.enemy_health_bar
	ui.lianli_module.enemy_health_value = ui.enemy_health_value
	ui.lianli_module.player_health_bar_lianli = ui.player_health_bar_lianli
	ui.lianli_module.player_health_value_lianli = ui.player_health_value_lianli
	ui.lianli_module.continuous_checkbox = ui.continuous_checkbox
	ui.lianli_module.continue_button = ui.continue_button
	ui.lianli_module.lianli_speed_button = ui.lianli_speed_button
	ui.lianli_module.exit_lianli_button = ui.exit_lianli_button
	ui.lianli_module.initialize(ui, ui.player, ui.lianli_system, ui.lianli_area_data, ui.item_data_ref, ui.inventory, ui.chuna_module, ui.log_manager, ui.alchemy_module, ui.api, ui.spell_data_ref, ui.spell_system)
	ui.lianli_module.log_message.connect(ui._on_module_log)


func _connect_or_skip(button: Button, callback: Callable) -> void:
	for conn in button.get_signal_connection_list("pressed"):
		if conn.callable.get_object() == callback.get_object() and conn.callable.get_method() == callback.get_method():
			return
	button.pressed.connect(callback)
