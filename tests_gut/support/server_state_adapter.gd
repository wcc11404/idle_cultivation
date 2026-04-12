extends RefCounted

class_name ServerStateAdapter

static func apply_game_data(game_manager: Node, data: Dictionary) -> void:
	if not game_manager:
		return
	var save_manager = game_manager.get_save_manager() if game_manager.has_method("get_save_manager") else null
	if save_manager and save_manager.has_method("apply_game_data"):
		save_manager.apply_game_data(data)

static func sync_full_state(client: Node, game_manager: Node) -> Dictionary:
	if not client:
		return {"success": false}
	var result = await client.load_game()
	if result.get("success", false):
		apply_game_data(game_manager, result.get("data", {}))
	return result

static func sync_inventory(client: Node, inventory: Node) -> Dictionary:
	if not client:
		return {"success": false}
	var result = await client.inventory_list()
	if result.get("success", false) and inventory and result.get("inventory", {}) is Dictionary:
		inventory.apply_save_data(result.get("inventory", {}))
	return result

static func sync_spells(client: Node, spell_system: Node, spell_data: Node = null) -> Dictionary:
	if not client:
		return {"success": false}
	var result = await client.spell_list()
	if result.get("success", false) and spell_system:
		if spell_data and spell_data.has_method("apply_remote_config"):
			var remote_spell_config = result.get("spells_config", {})
			if remote_spell_config is Dictionary and not remote_spell_config.is_empty():
				spell_data.apply_remote_config({"spells": remote_spell_config})
		spell_system.apply_save_data({
			"player_spells": result.get("player_spells", {}),
			"equipped_spells": result.get("equipped_spells", {})
		})
	return result
