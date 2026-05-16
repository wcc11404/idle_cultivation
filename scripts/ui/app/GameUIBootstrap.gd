extends RefCounted

const GAME_SERVER_API_SCRIPT = preload("res://scripts/network/GameServerAPI.gd")
const UI_FONT_PROVIDER = preload("res://scripts/ui/common/UIFontProvider.gd")
const UI_ICON_PROVIDER = preload("res://scripts/ui/common/UIIconProvider.gd")


func initialize(ui: Control) -> void:
	ui._bind_scene_refs()
	UI_FONT_PROVIDER.apply_to_root(ui)
	if ui.spirit_stone_icon:
		ui.spirit_stone_icon.texture = UI_ICON_PROVIDER.load_svg_texture(UI_ICON_PROVIDER.ICON_SPIRIT_STONE)
	if ui.immortal_crystal_icon:
		ui.immortal_crystal_icon.texture = UI_ICON_PROVIDER.load_svg_texture(UI_ICON_PROVIDER.ICON_IMMORTAL_CRYSTAL)
	var game_manager = ui.get_node_or_null("/root/GameManager")
	if game_manager:
		ui.item_data_ref = game_manager.get_item_data()
		ui.spell_data_ref = game_manager.get_spell_data()
		ui.recipe_data = game_manager.get_recipe_data()
		ui.lianli_system = game_manager.get_lianli_system()
		ui.lianli_area_data = game_manager.get_lianli_area_data()
		ui.enemy_data = game_manager.get_enemy_data()

	ui._setup_optional_nodes()
	ui._setup_bottom_tab_layout()
	ui._setup_neishi_sub_tab_layout()
	ui.show_neishi_tab()

	ui.api = GAME_SERVER_API_SCRIPT.new()
	ui.add_child(ui.api)

	await ui.get_tree().process_frame
	ui._bind_network_error_bridge()

	ui.setup_log_manager()
	ui.setup_alchemy_module()
	ui.setup_settings_module()
	ui.setup_profile_edit_popup()
	ui.setup_region_module()
	ui.setup_herb_gather_module()
	ui.setup_task_module()
	ui.setup_mail_module()
	ui._setup_notification_badges()
	ui.setup_chuna_module()
	ui.setup_spell_module()
	ui.setup_neishi_module()
	ui.setup_lianli_module()

	ui.setup_button_connections()
	ui.show_neishi_tab()

	if ui.log_manager:
		ui.log_manager.add_system_log("欢迎来到修仙世界！")
		ui.log_manager.add_system_log("点击下方按钮开始修炼")

	ui.load_game_data()
	await ui.claim_offline_reward()
	await ui._refresh_notification_badges_from_server()
