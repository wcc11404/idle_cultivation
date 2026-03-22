# 服务端配置文件

class_name ServerConfig

const DEFAULT_API_BASE = "http://127.0.0.1:8444/api"
const TOKEN_FILE = "user://auth_token.dat"
const SERVER_CONFIG_FILE = "user://server_config.dat"
const MAX_RETRY_COUNT = 3
const REQUEST_TIMEOUT = 5.0
const QUICK_THRESHOLD = 0.5

static func get_api_base() -> String:
	# 从本地存储加载服务器配置
	if FileAccess.file_exists(SERVER_CONFIG_FILE):
		var file = FileAccess.open(SERVER_CONFIG_FILE, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		if content and not content.is_empty():
			return content
	# 返回默认值
	return DEFAULT_API_BASE

static func set_api_base(api_base: String):
	# 保存服务器配置到本地存储
	var file = FileAccess.open(SERVER_CONFIG_FILE, FileAccess.WRITE)
	file.store_string(api_base)
	file.close()
