class_name AvatarConfig

# 头像配置
# 服务器存储头像ID，客户端根据ID加载对应资源

const AVATARS = {
	"abstract": "avatar_abstract.png",
	"qi_refining": "avatar_qi_refining.png",
	"foundation": "avatar_foundation.png",
	"golden_core": "avatar_golden_core.png",
	"nascent_soul": "avatar_nascent_soul.png"
}

# 获取头像文件路径
static func get_avatar_path(avatar_id: String) -> String:
	var filename = AVATARS.get(avatar_id, "avatar_abstract.png")
	return "res://assets/avatars/" + filename

# 获取所有可用的头像ID
static func get_available_avatar_ids() -> Array:
	return AVATARS.keys()

# 获取默认头像ID
static func get_default_avatar_id() -> String:
	return "abstract"
