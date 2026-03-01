class_name LogManager extends Node

signal log_added(message: String)

enum LogType {
	SYSTEM,    # 系统消息
	BATTLE,    # 战斗消息
	ALCHEMY    # 炼丹消息
}

var log_messages: Array = []
var max_log_count: int = 500

var rich_text_label: RichTextLabel = null

func _ready():
	pass

func set_rich_text_label(label: RichTextLabel):
	rich_text_label = label
	rich_text_label.bbcode_enabled = true

# 添加系统消息
func add_system_log(message: String):
	_add_log_internal(message, LogType.SYSTEM)

# 添加战斗消息
func add_battle_log(message: String):
	_add_log_internal(message, LogType.BATTLE)

# 添加炼丹消息
func add_alchemy_log(message: String):
	_add_log_internal(message, LogType.ALCHEMY)

func _add_log_internal(message: String, log_type: LogType):
	var timestamp = _get_timestamp()
	var type_tag = _get_type_tag(log_type)
	var formatted_message = _format_message(message, log_type)
	
	log_messages.append({
		"timestamp": timestamp,
		"type": log_type,
		"type_tag": type_tag,
		"raw_message": message,
		"formatted_message": formatted_message
	})
	
	if log_messages.size() > max_log_count:
		log_messages.remove_at(0)
	
	_update_display()
	log_added.emit(timestamp + type_tag + message)

func _get_timestamp() -> String:
	var time = Time.get_datetime_dict_from_system()
	var hour = str(time.hour).pad_zeros(2)
	var minute = str(time.minute).pad_zeros(2)
	var second = str(time.second).pad_zeros(2)
	return "[" + hour + ":" + minute + ":" + second + "]"

func _get_type_tag(log_type: LogType) -> String:
	match log_type:
		LogType.SYSTEM:
			return "[系统]"
		LogType.BATTLE:
			return "[战斗]"
		LogType.ALCHEMY:
			return "[炼丹]"
		_:
			return "[系统]"

func _format_message(message: String, log_type: LogType) -> String:
	var result = message
	
	# 系统消息高亮（使用柔和的颜色）
	if log_type == LogType.SYSTEM:
		if "灵石" in result:
			result = _highlight_reward(result, "灵石", "#B8860B")  # 深金色
		if "灵气" in result:
			result = _highlight_reward(result, "灵气", "#5F9EA0")  # 柔和青色
		result = result.replace("成功", "[color=#6B8E23]成功[/color]")  # 柔和绿色
		result = result.replace("失败", "[color=#CD5C5C]失败[/color]")  # 柔和红色
		result = result.replace("离线总计时间", "[color=#B8860B]离线总计时间[/color]")  # 深金色
	# 战斗消息高亮（使用柔和的颜色）
	else:
		result = result.replace("造成了", "[color=#CD5C5C]造成了[/color]")  # 柔和红色
		result = result.replace("点伤害", "[color=#CD5C5C]点伤害[/color]")  # 柔和红色
		result = result.replace("成功", "[color=#6B8E23]成功[/color]")  # 柔和绿色
		result = result.replace("失败", "[color=#CD5C5C]失败[/color]")  # 柔和红色
	
	return result

func _highlight_reward(message: String, keyword: String, color: String) -> String:
	var result = message
	var idx = result.find(keyword)
	
	while idx != -1:
		var end_idx = idx + keyword.length()
		
		while end_idx < result.length():
			var ch = result.substr(end_idx, 1)
			if ch.is_valid_int() or ch == "x" or ch == "×" or ch == ":" or ch == " ":
				end_idx += 1
			else:
				break
		
		var before = result.substr(0, idx)
		var highlight = result.substr(idx, end_idx - idx)
		var after = result.substr(end_idx)
		
		result = before + "[color=" + color + "]" + highlight + "[/color]" + after
		idx = result.find(keyword, idx + "[color=".length() + color.length() + "]".length() + highlight.length() + "[/color]".length())
	
	return result

func _update_display():
	if not rich_text_label:
		return
	
	var full_text = ""
	for log_msg in log_messages:
		full_text += log_msg.timestamp + log_msg.type_tag + " " + log_msg.formatted_message + "\n"
	
	rich_text_label.text = full_text

func clear_logs():
	log_messages.clear()
	_update_display()

func get_logs() -> Array:
	return log_messages.duplicate()
