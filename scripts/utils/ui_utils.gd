class_name UIUtils

# UI 工具函数类
# 统一处理数值格式化、单位转换等操作

# ==================== 数值单位转换 ====================

# 将大数值转换为 K/M/B 格式
# 如: 1500 -> "1.5K", 1000000 -> "1M"
static func format_number(num: int) -> String:
	if num >= 1000000000:
		return str(num / 1000000000) + "B"
	elif num >= 1000000:
		return str(num / 1000000) + "M"
	elif num >= 1000:
		var decimal = (num % 1000) / 100
		if decimal > 0:
			return str(num / 1000) + "." + str(decimal) + "K"
		else:
			return str(num / 1000) + "K"
	else:
		return str(num)

# 将大数值转换为带精度的 K/M/B 格式
# 如: 1500 -> "1.5K", 1234 -> "1.23K"
static func format_number_precise(num: float, decimal_places: int = 1) -> String:
	if num >= 1000000000:
		return _format_with_decimal(num / 1000000000.0, decimal_places) + "B"
	elif num >= 1000000:
		return _format_with_decimal(num / 1000000.0, decimal_places) + "M"
	elif num >= 1000:
		return _format_with_decimal(num / 1000.0, decimal_places) + "K"
	else:
		return str(int(num))

# 辅助函数：格式化小数
static func _format_with_decimal(value: float, decimal_places: int) -> String:
	var multiplier = pow(10, decimal_places)
	var rounded = round(value * multiplier) / multiplier
	var int_part = int(rounded)
	var decimal_part = int((rounded - int_part) * multiplier)
	
	if decimal_part == 0:
		return str(int_part)
	else:
		# 去除末尾0
		var decimal_str = str(decimal_part)
		while decimal_str.ends_with("0"):
			decimal_str = decimal_str.substr(0, decimal_str.length() - 1)
		return str(int_part) + "." + decimal_str

# ==================== 百分比格式化 ====================

# 将小数转换为百分比字符串（带%符号）
# 如: 0.25 -> "25%", 1.10 -> "110%"
static func format_percent(value: float) -> String:
	return str(int(value * 100)) + "%"

# 将小数转换为百分比字符串（保留指定小数位）
# 如: 0.253 -> "25.3%"
static func format_percent_precise(value: float, decimal_places: int = 1) -> String:
	var multiplier = pow(10, decimal_places)
	var rounded = round(value * 100 * multiplier) / multiplier
	return str(rounded) + "%"

# ==================== 小数格式化 ====================

# 去除小数末尾的0
# 如: 1.500 -> "1.5", 2.0 -> "2"
static func trim_trailing_zeros(num: float) -> String:
	var str_num = str(num)
	if str_num.find(".") == -1:
		return str_num
	
	while str_num.ends_with("0"):
		str_num = str_num.substr(0, str_num.length() - 1)
	
	if str_num.ends_with("."):
		str_num = str_num.substr(0, str_num.length() - 1)
	
	return str_num

# 格式化小数（保留指定位数，去除末尾0）
static func format_decimal(value: float, max_decimal_places: int = 2) -> String:
	var multiplier = pow(10, max_decimal_places)
	var rounded = round(value * multiplier) / multiplier
	return trim_trailing_zeros(rounded)

# ==================== 术法描述占位符替换 ====================

# 替换术法描述中的占位符
# 使用 AttributeCalculator 的格式化函数
static func format_spell_description(description: String, effect: Dictionary) -> String:
	var result = description
	
	for key in effect.keys():
		var placeholder = "{" + key + "}"
		if result.find(placeholder) == -1:
			continue
		
		# 百分比类型（damage_percent, buff_percent, heal_percent, trigger_chance 等）
		if key.ends_with("_percent") or key.ends_with("_chance"):
			result = result.replace(placeholder, AttributeCalculator.format_percent(effect[key]))
		# 固定数值类型
		elif key.ends_with("_value") or key.ends_with("_amount") or key.ends_with("_bonus"):
			result = result.replace(placeholder, AttributeCalculator.format_default(effect[key]))
		# 其他数值类型，默认使用 format_default
		else:
			result = result.replace(placeholder, AttributeCalculator.format_default(effect[key]))
	
	return result

# ==================== 时间格式化 ====================

# 将秒数转换为时分秒格式
# 如: 3665 -> "1:01:05"
static func format_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return str(hours) + ":" + _pad_zero(minutes) + ":" + _pad_zero(secs)
	else:
		return str(minutes) + ":" + _pad_zero(secs)

# 辅助函数：补零
static func _pad_zero(num: int) -> String:
	if num < 10:
		return "0" + str(num)
	return str(num)

# ==================== 战斗数值格式化 ====================

# 格式化战斗相关数值
# 如果num < 1000，保留两位小数且去除尾零显示
# 如果num >= 1000，采用11k，11m的格式显示
# 入参可以是int也可以是float
static func format_battle_number(num: Variant) -> String:
	var float_num: float
	if num is int:
		float_num = float(num)
	elif num is float:
		float_num = num
	else:
		return str(num)
	
	if float_num >= 1000.0:
		return format_number_precise(float_num, 1)
	else:
		return format_decimal(float_num, 2)

# ==================== 颜色格式化 ====================

# 根据数值返回颜色（用于血条等）
static func get_health_color(health_percent: float) -> Color:
	if health_percent > 0.6:
		return Color.GREEN
	elif health_percent > 0.3:
		return Color.YELLOW
	else:
		return Color.RED

# 根据品质返回颜色
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"普通": return Color.WHITE
		"优秀": return Color.GREEN
		"稀有": return Color.BLUE
		"史诗": return Color.PURPLE
		"传说": return Color.ORANGE
		_: return Color.WHITE
