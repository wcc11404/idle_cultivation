extends RefCounted


func set_player(ui: Control, player_node: Node) -> void:
	ui.player = player_node
	if ui.alchemy_module:
		ui.alchemy_module.player = ui.player
	if ui.chuna_module:
		ui.chuna_module.player = ui.player
	if ui.cultivation_module:
		ui.cultivation_module.player = ui.player
	if ui.spell_module:
		ui.spell_module.player = ui.player
	if ui.lianli_module:
		ui.lianli_module.player = ui.player
	if ui.settings_module:
		ui.settings_module.player = ui.player
	if ui.herb_gather_module:
		ui.herb_gather_module.player = ui.player


func set_spell_system(ui: Control, spell_system_node: Node) -> void:
	ui.spell_system = spell_system_node
	if ui.spell_module:
		ui.spell_module.spell_system = ui.spell_system
		ui.spell_module.spell_data = ui.spell_data_ref
	if ui.alchemy_module:
		ui.alchemy_module.spell_system = ui.spell_system
	if ui.herb_gather_module:
		ui.herb_gather_module.spell_system = ui.spell_system
	if ui.chuna_module:
		ui.chuna_module.spell_system = ui.spell_system
		ui.chuna_module.spell_data = ui.spell_data_ref


func set_alchemy_system(ui: Control, alchemy_system_node: Node) -> void:
	ui.alchemy_system = alchemy_system_node
	if ui.alchemy_module:
		ui.alchemy_module.alchemy_system = ui.alchemy_system
	if ui.chuna_module:
		ui.chuna_module.alchemy_system = ui.alchemy_system


func set_recipe_data(ui: Control, recipe_data_node: Node) -> void:
	ui.recipe_data = recipe_data_node
	if ui.alchemy_module:
		ui.alchemy_module.recipe_data = ui.recipe_data


func set_item_data(ui: Control, item_data_node: Node) -> void:
	ui.item_data_ref = item_data_node
	if ui.alchemy_module:
		ui.alchemy_module.item_data = item_data_node
	if ui.chuna_module:
		ui.chuna_module.item_data = item_data_node
	if ui.mail_module:
		ui.mail_module.item_data_ref = item_data_node
	if ui.cultivation_module:
		ui.cultivation_module.item_data = item_data_node
	if ui.herb_gather_module:
		ui.herb_gather_module.item_data = item_data_node


func set_inventory(ui: Control, inventory_node: Node) -> void:
	ui.inventory = inventory_node
	if ui.chuna_module:
		ui.chuna_module.inventory = ui.inventory
		ui.chuna_module.update_inventory_ui()
	if ui.cultivation_module:
		ui.cultivation_module.inventory = ui.inventory
	if ui.lianli_module:
		ui.lianli_module.inventory = ui.inventory
	if ui.alchemy_module:
		ui.alchemy_module.inventory = ui.inventory
	if ui.herb_gather_module:
		ui.herb_gather_module.inventory = ui.inventory
