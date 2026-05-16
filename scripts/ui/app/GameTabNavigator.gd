extends RefCounted

const UI_FEEDBACK_MANAGER = preload("res://scripts/ui/common/UIFeedbackManager.gd")


func _hide_secondary_panels(ui: Control) -> void:
	if ui.region_panel:
		ui.region_panel.visible = false
	if ui.herb_gather_panel:
		ui.herb_gather_panel.visible = false
	if ui.task_panel:
		ui.task_panel.visible = false
	if ui.mail_module and ui.mail_module.panel:
		ui.mail_module.panel.visible = false
	ui.lianli_panel.visible = false
	ui.settings_panel.visible = false
	if ui.alchemy_module:
		ui.alchemy_module.hide_alchemy_room()


func _set_main_tab_disabled(ui: Control, tab_key: String, region_disabled: bool = false, settings_disabled: bool = false) -> void:
	ui.tab_neishi.disabled = tab_key == "neishi"
	ui.tab_chuna.disabled = tab_key == "chuna"
	if ui.tab_region:
		ui.tab_region.disabled = region_disabled
	ui.tab_lianli.disabled = tab_key == "lianli"
	ui.tab_settings.disabled = settings_disabled


func show_neishi_tab(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = true
	ui.chuna_panel.visible = false
	if ui.chuna_module:
		ui.chuna_module.hide_tab()
	_set_main_tab_disabled(ui, "neishi")
	if ui.neishi_module:
		ui.neishi_module.show_tab()
	_play_main_tab_content_in(ui.neishi_panel)
	ui.call_deferred("_reposition_cultivation_visual_between_panels")


func show_chuna_tab(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = true
	if ui.chuna_module:
		ui.chuna_module.show_tab()
	_set_main_tab_disabled(ui, "chuna")
	if ui.item_detail_panel:
		ui.item_detail_panel.visible = true
	_play_main_tab_content_in(ui.chuna_panel)


func show_region_tab(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	if ui.region_panel:
		ui.region_panel.visible = true
	if ui.region_module:
		ui.region_module.show_tab()
	_set_main_tab_disabled(ui, "region", true)
	_play_main_tab_content_in(ui.region_panel)


func show_lianli_tab(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	ui.lianli_panel.visible = true
	_set_main_tab_disabled(ui, "lianli")

	ui.update_lianli_area_buttons_display()
	if ui.allow_background_server_refresh:
		ui.call_deferred("_refresh_lianli_info_from_server")

	if ui.lianli_module:
		ui.lianli_module.on_tab_entered()
		if ui.lianli_system and ui.lianli_system.is_in_lianli:
			ui.lianli_module.show_lianli_scene_panel()
		else:
			ui.lianli_module.show_lianli_select_panel()
	_play_main_tab_content_in(ui.lianli_panel)


func show_settings_tab(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	ui.settings_panel.visible = true
	if ui.settings_module:
		ui.settings_module.show_tab()
	_set_main_tab_disabled(ui, "settings", false, true)
	_play_main_tab_content_in(ui.settings_panel)


func show_mail_panel(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	if ui.mail_module:
		ui.mail_module.show_tab()
	_set_main_tab_disabled(ui, "mail", false, true)
	if ui.mail_module and ui.mail_module.panel:
		_play_main_tab_content_in(ui.mail_module.panel)


func show_herb_gather_panel(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	if ui.herb_gather_panel:
		ui.herb_gather_panel.visible = true
	if ui.herb_gather_module:
		ui.herb_gather_module.show_tab()
	_set_main_tab_disabled(ui, "herb", true)
	_play_main_tab_content_in(ui.herb_gather_panel)


func show_task_panel(ui: Control) -> void:
	_hide_secondary_panels(ui)
	ui.neishi_panel.visible = false
	ui.chuna_panel.visible = false
	if ui.task_panel:
		ui.task_panel.visible = true
	if ui.task_module:
		ui.task_module.show_tab()
	_set_main_tab_disabled(ui, "task", true)
	_play_main_tab_content_in(ui.task_panel)


func _play_main_tab_content_in(panel: Control) -> void:
	if panel:
		UI_FEEDBACK_MANAGER.play_tab_content_in(panel)
