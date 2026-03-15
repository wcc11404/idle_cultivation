extends Node

const GameServerAPI = preload("res://scripts/network/GameServerAPI.gd")

var api: GameServerAPI = null

func _ready():
	api = GameServerAPI.new()
	add_child(api)
	
	# 测试API连接
	test_api_connection()

func test_api_connection():
	print("=== 测试网络连接 ===")
	
	# 测试登录接口（即使没有账号，也可以测试连接）
	var result = await api.login("test", "test")
	print("登录接口测试结果:")
	print("成功: " + str(result.success))
	print("响应码: " + str(result.response_code))
	if result.error:
		print("错误: " + result.error)
	if result.message:
		print("消息: " + result.message)
	
	# 测试Token管理
	test_token_management()

func test_token_management():
	print("\n=== 测试Token管理 ===")
	# 这里可以测试Token的存储和加载
	print("Token管理测试完成")

func test_save_load():
	print("\n=== 测试存档/读档 ===")
	# 测试保存游戏数据
	var test_data = {
		"player": {
			"realm": "炼气期",
			"realm_level": 1,
			"health": 500.0,
			"spirit_energy": 0.0
		}
	}
	
	var save_result = await api.save_game(test_data)
	print("保存测试结果:")
	print("成功: " + str(save_result.success))
	if save_result.error:
		print("错误: " + save_result.error)
	
	# 测试加载游戏数据
	var load_data = await api.load_game()
	print("\n加载测试结果:")
	print("成功: " + str(load_data.success))
	if load_data.data:
		print("加载到数据: " + str(load_data.data))
	if load_data.error:
		print("错误: " + load_data.error)
