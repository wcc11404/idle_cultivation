extends Node

class_name NetworkManager

const ServerConfig = preload("res://scripts/network/ServerConfig.gd")

var current_token: String = ""
var loading_popup: AcceptDialog = null
var is_requesting: bool = false

func _ready():
	load_token()

func save_token(token: String):
	current_token = token
	var file = FileAccess.open(ServerConfig.TOKEN_FILE, FileAccess.WRITE)
	file.store_string(token)
	file.close()

func load_token() -> bool:
	if FileAccess.file_exists(ServerConfig.TOKEN_FILE):
		var file = FileAccess.open(ServerConfig.TOKEN_FILE, FileAccess.READ)
		current_token = file.get_as_text()
		# 检查 Token 是否为空
		if current_token.is_empty():
			return false
		return true
	return false

func clear_token():
	current_token = ""
	if FileAccess.file_exists(ServerConfig.TOKEN_FILE):
		DirAccess.remove_absolute(ServerConfig.TOKEN_FILE)

func request(method: String, endpoint: String, body: Dictionary = {}) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = ServerConfig.API_BASE + endpoint
	var headers = ["Content-Type: application/json"]
	
	if current_token:
		headers.append("Authorization: Bearer " + current_token)
	
	var body_json = JSON.stringify(body) if body else ""
	
	var method_enum = HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST
	http.request(url, headers, method_enum, body_json)
	
	var result = await http.request_completed
	http.queue_free()
	
	return parse_response(result)

func parse_response(response: Array) -> Dictionary:
	var request_success = response[0] == HTTPRequest.RESULT_SUCCESS
	var response_code = response[2]
	var body = response[3]
	
	# 处理 response_code 可能是字符串的情况
	var status_code = 0
	if response_code is String:
		status_code = int(response_code)
	elif response_code is int:
		status_code = response_code
	
	# 检查 HTTP 状态码，只有 200-299 之间的状态码才认为请求成功
	var http_success = status_code >= 200 and status_code < 300
	var success = request_success and http_success
	
	var result = {
		"success": success,
		"response_code": response_code
	}
	
	if request_success and body.size() > 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			# 直接合并 JSON 对象到 result 中，而不是嵌套在 data 字段
			for key in json.keys():
				result[key] = json[key]
		else:
			# 如果 JSON 解析失败，检查状态码
			if not http_success:
				result["error"] = "请求失败"
				result["message"] = "服务器返回错误状态码: " + str(status_code)
	else:
		result["error"] = "网络请求失败"
		result["message"] = "请检查网络连接"
	
	return result

func execute_critical_operation(api_path: String, body: Dictionary, on_success: Callable) -> void:
	if is_requesting:
		show_toast("请等待当前操作完成")
		return
	
	is_requesting = true
	
	var http = HTTPRequest.new()
	http.timeout = ServerConfig.REQUEST_TIMEOUT
	add_child(http)
	
	var headers = ["Content-Type: application/json"]
	if current_token:
		headers.append("Authorization: Bearer " + current_token)
	
	http.request(ServerConfig.API_BASE + api_path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	
	await get_tree().create_timer(ServerConfig.QUICK_THRESHOLD).timeout
	var still_waiting = is_requesting
	
	if still_waiting:
		_show_loading_popup()
	
	var response = await http.request_completed
	http.queue_free()
	
	_hide_loading_popup()
	is_requesting = false
	
	var result = parse_response(response)
	
	if result.success:
		on_success.call(result)
	else:
		show_error(result.message)

func _show_loading_popup():
	if not loading_popup:
		loading_popup = AcceptDialog.new()
		loading_popup.dialog_text = "网络环境不佳，正在等待..."
		loading_popup.get_ok_button().disabled = true
		add_child(loading_popup)
	loading_popup.popup_centered()

func _hide_loading_popup():
	if loading_popup and loading_popup.visible:
		loading_popup.hide()

func show_toast(message: String):
	# 简单的提示实现
	print("Toast: " + message)

func show_error(message: String):
	# 简单的错误提示实现
	print("Error: " + message)
