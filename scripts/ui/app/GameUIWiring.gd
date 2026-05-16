extends RefCounted


func setup_button_connections(ui: Control) -> void:
	if ui.cultivate_button and ui.cultivation_module and not ui.cultivate_button.pressed.is_connected(ui.cultivation_module.on_cultivate_button_pressed):
		ui.cultivate_button.pressed.connect(ui.cultivation_module.on_cultivate_button_pressed)
	if ui.breakthrough_button and ui.cultivation_module and not ui.breakthrough_button.pressed.is_connected(ui.cultivation_module.on_breakthrough_button_pressed):
		ui.breakthrough_button.pressed.connect(ui.cultivation_module.on_breakthrough_button_pressed)

	if ui.tab_neishi and not ui.tab_neishi.pressed.is_connected(ui._on_tab_neishi_pressed):
		ui.tab_neishi.pressed.connect(ui._on_tab_neishi_pressed)
	if ui.tab_chuna and not ui.tab_chuna.pressed.is_connected(ui._on_tab_chuna_pressed):
		ui.tab_chuna.pressed.connect(ui._on_tab_chuna_pressed)
	if ui.tab_region and not ui.tab_region.pressed.is_connected(ui._on_tab_region_pressed):
		ui.tab_region.pressed.connect(ui._on_tab_region_pressed)
	if ui.tab_lianli and not ui.tab_lianli.pressed.is_connected(ui._on_tab_lianli_pressed):
		ui.tab_lianli.pressed.connect(ui._on_tab_lianli_pressed)
	if ui.tab_settings and not ui.tab_settings.pressed.is_connected(ui._on_tab_settings_pressed):
		ui.tab_settings.pressed.connect(ui._on_tab_settings_pressed)
	if ui.top_player_info and not ui.top_player_info.gui_input.is_connected(ui._on_top_player_info_gui_input):
		ui.top_player_info.gui_input.connect(ui._on_top_player_info_gui_input)

	if ui.cultivation_tab and ui.neishi_module and not ui.cultivation_tab.pressed.is_connected(ui.neishi_module.on_cultivation_tab_pressed):
		ui.cultivation_tab.pressed.connect(ui.neishi_module.on_cultivation_tab_pressed)
	if ui.spell_tab and ui.neishi_module and not ui.spell_tab.pressed.is_connected(ui.neishi_module.on_spell_tab_pressed):
		ui.spell_tab.pressed.connect(ui.neishi_module.on_spell_tab_pressed)

	ui._init_endless_tower_button()

	if ui.continuous_checkbox and ui.lianli_module and not ui.continuous_checkbox.toggled.is_connected(ui.lianli_module.on_continuous_toggled):
		ui.continuous_checkbox.toggled.connect(ui.lianli_module.on_continuous_toggled)
	if ui.continue_button and ui.lianli_module and not ui.continue_button.pressed.is_connected(ui.lianli_module.on_continue_pressed):
		ui.continue_button.pressed.connect(ui.lianli_module.on_continue_pressed)
	if ui.lianli_speed_button and ui.lianli_module and not ui.lianli_speed_button.pressed.is_connected(ui.lianli_module.on_lianli_speed_pressed):
		ui.lianli_speed_button.pressed.connect(ui.lianli_module.on_lianli_speed_pressed)
	if ui.exit_lianli_button and ui.lianli_module and not ui.exit_lianli_button.pressed.is_connected(ui.lianli_module.on_exit_lianli_pressed):
		ui.exit_lianli_button.pressed.connect(ui.lianli_module.on_exit_lianli_pressed)


func setup_log_filter_connections(ui: Control) -> void:
	if ui.log_filter_all_button and not ui.log_filter_all_button.pressed.is_connected(ui._on_log_filter_all_pressed):
		ui.log_filter_all_button.pressed.connect(ui._on_log_filter_all_pressed)
	if ui.log_filter_system_button and not ui.log_filter_system_button.pressed.is_connected(ui._on_log_filter_system_pressed):
		ui.log_filter_system_button.pressed.connect(ui._on_log_filter_system_pressed)
	if ui.log_filter_battle_button and not ui.log_filter_battle_button.pressed.is_connected(ui._on_log_filter_battle_pressed):
		ui.log_filter_battle_button.pressed.connect(ui._on_log_filter_battle_pressed)
	if ui.log_filter_production_button and not ui.log_filter_production_button.pressed.is_connected(ui._on_log_filter_production_pressed):
		ui.log_filter_production_button.pressed.connect(ui._on_log_filter_production_pressed)
	if ui.log_filter_debug_button and not ui.log_filter_debug_button.pressed.is_connected(ui._on_log_filter_debug_pressed):
		ui.log_filter_debug_button.pressed.connect(ui._on_log_filter_debug_pressed)
