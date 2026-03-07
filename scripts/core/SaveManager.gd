class_name SaveManager extends Node

signal save_completed()
signal load_completed()
signal load_failed()

const SAVE_VERSION = "1.3"
const USER_DATA_DIR = "res://user_data"

var current_save_data: Dictionary = {}
var save_file_path: String = ""

func _ready():
	# 确保用户数据目录存在
	ensure_user_data_dir()

func ensure_user_data_dir():
	if not DirAccess.dir_exists_absolute(USER_DATA_DIR):
		var err = DirAccess.make_dir_recursive_absolute(USER_DATA_DIR)
		if err == OK:
			print("创建用户数据目录: ", USER_DATA_DIR)
		else:
			print("创建用户数据目录失败: ", err)

func set_save_path(path: String):
	# 提取文件名
	var filename = path.get_file()
	# 所有存档都保存在项目目录的 user_data 下
	save_file_path = USER_DATA_DIR + "/" + filename
	print("存档路径已设置为: ", save_file_path)

func get_save_path() -> String:
	return save_file_path

func save_game() -> bool:
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return false
	
	var player = game_manager.get_player()
	if not player:
		return false
	
	var inventory = game_manager.get_inventory()
	var account_system = game_manager.get_account_system()
	var spell_system = game_manager.get_spell_system()
	var alchemy_system = game_manager.get_alchemy_system()
	var lianli_system = game_manager.get_lianli_system()
	
	# 获取背景颜色
	var bg_color = Color(0.96, 0.94, 0.90)
	var bg_manager = game_manager.get_node_or_null("BackgroundManager")
	if bg_manager:
		bg_color = bg_manager.get_background_color()
	
	var save_data = {
		"player": player.get_save_data(),
		"inventory": inventory.get_save_data() if inventory else {},
		"spell_system": spell_system.get_save_data() if spell_system else {},
		"alchemy_system": alchemy_system.get_save_data() if alchemy_system else {},
		"lianli_system": lianli_system.get_save_data() if lianli_system else {},
		"timestamp": Time.get_unix_time_from_system(),
		"version": SAVE_VERSION
	}
	
	# 保存账号信息
	if account_system and account_system.is_logged_in():
		save_data["account"] = account_system.get_current_account()
	
	current_save_data = save_data
	
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		save_completed.emit()
		return true
	return false

func load_game() -> bool:
	if not FileAccess.file_exists(save_file_path):
		load_failed.emit()
		return false
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		load_failed.emit()
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		load_failed.emit()
		return false
	
	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		load_failed.emit()
		return false
	
	current_save_data = save_data
	
	apply_save_data(save_data)
	load_completed.emit()
	return true

func apply_save_data(save_data: Dictionary):
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return
	
	var player = game_manager.get_player()
	if player:
		var player_data = save_data.get("player", {})
		if not player_data.is_empty():
			player.apply_save_data(player_data)
	
	var inventory = game_manager.get_inventory()
	if inventory:
		var inventory_data = save_data.get("inventory", {})
		if not inventory_data.is_empty():
			inventory.apply_save_data(inventory_data)
	
	# 恢复术法数据
	var spell_system = game_manager.get_spell_system()
	if spell_system and save_data.has("spell_system"):
		spell_system.apply_save_data(save_data["spell_system"])
	
	# 恢复炼丹系统数据
	var alchemy_system = game_manager.get_alchemy_system()
	if alchemy_system and save_data.has("alchemy_system"):
		alchemy_system.apply_save_data(save_data["alchemy_system"])
	
	# 恢复历练系统数据
	var lianli_system = game_manager.get_lianli_system()
	if lianli_system and save_data.has("lianli_system"):
		lianli_system.apply_save_data(save_data["lianli_system"])
	


func delete_save() -> bool:
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)
		return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(save_file_path)

func get_save_info() -> Dictionary:
	if not has_save():
		return {}
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var save_data = json.get_data()
	return {
		"timestamp": save_data.get("timestamp", 0),
		"version": save_data.get("version", "1.0")
	}
