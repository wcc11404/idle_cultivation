class_name AccountConfig

# 账号展示配置
# 服务器存储 avatar_id，客户端根据 ID 加载对应资源

const AVATARS = {
	"abstract": "avatar_abstract.png",
	"qi_refining": "avatar_qi_refining.png",
	"foundation": "avatar_foundation.png",
	"golden_core": "avatar_golden_core.png",
	"nascent_soul": "avatar_nascent_soul.png"
}

static func get_avatar_path(avatar_id: String) -> String:
	var filename = AVATARS.get(avatar_id, "avatar_abstract.png")
	return "res://assets/avatars/" + filename

static func get_available_avatar_ids() -> Array:
	return AVATARS.keys()

static func get_default_avatar_id() -> String:
	return "abstract"

