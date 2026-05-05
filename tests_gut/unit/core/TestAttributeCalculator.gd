extends GutTest

## AttributeCalculator 单元测试

#region 格式化函数测试

func test_format_default_with_decimals():
	var result = AttributeCalculator.format_default(1.50)
	assert_eq(result, "1.5", "1.50 应格式化为 1.5")

func test_format_default_whole_number():
	var result = AttributeCalculator.format_default(2.00)
	assert_eq(result, "2", "2.00 应格式化为 2")

func test_format_default_small_decimal():
	var result = AttributeCalculator.format_default(1.05)
	assert_eq(result, "1.05", "1.05 应保持不变")

func test_format_percent_basic():
	var result = AttributeCalculator.format_percent(0.15)
	assert_eq(result, "15%", "0.15 应格式化为 15%")

func test_format_percent_small():
	var result = AttributeCalculator.format_percent(0.005)
	assert_eq(result, "0.5%", "0.005 应格式化为 0.5%")

func test_format_percent_over_100():
	var result = AttributeCalculator.format_percent(1.10)
	assert_eq(result, "110%", "1.10 应格式化为 110%")

func test_format_one_decimal_with_decimal():
	var result = AttributeCalculator.format_one_decimal(50.5)
	assert_eq(result, "50.5", "50.5 应保持不变")

func test_format_one_decimal_whole():
	var result = AttributeCalculator.format_one_decimal(50.0)
	assert_eq(result, "50", "50.0 应格式化为 50")

func test_format_integer():
	var result = AttributeCalculator.format_integer(255.7)
	assert_eq(result, "256", "255.7 应四舍五入为 256")

func test_format_integer_exact():
	var result = AttributeCalculator.format_integer(100.0)
	assert_eq(result, "100", "100.0 应格式化为 100")

func test_format_attack_defense_small():
	var result = AttributeCalculator.format_attack_defense(500.5)
	assert_eq(result, "500.5", "<=1000 应保留一位小数")

func test_format_attack_defense_large():
	var result = AttributeCalculator.format_attack_defense(1500.7)
	assert_eq(result, "1.5K", ">=1000 应转K/M并保留一位小数去尾0")

func test_format_damage_small():
	var result = AttributeCalculator.format_damage(999.5)
	assert_eq(result, "999.5", "<=1000 伤害保留一位小数")

func test_format_damage_large():
	var result = AttributeCalculator.format_damage(1000.5)
	assert_eq(result, "1K", ">=1000 伤害应转K/M并保留一位小数去尾0")

func test_format_for_save_trailing_zeros():
	var result = AttributeCalculator.format_for_save(50.5000)
	assert_eq(result, "50.5", "应去除尾随零")

func test_format_for_save_whole():
	var result = AttributeCalculator.format_for_save(100.0000)
	assert_eq(result, "100", "整数应无小数点")

func test_format_for_save_small_decimal():
	var result = AttributeCalculator.format_for_save(0.0020)
	assert_eq(result, "0.002", "应保留有效小数")

#endregion

#region 最终属性计算测试 - 空玩家

func test_calculate_final_attack_null_player():
	var attack = AttributeCalculator.calculate_final_attack(null)
	assert_eq(attack, 0.0, "空玩家攻击力应为0")

func test_calculate_final_defense_null_player():
	var defense = AttributeCalculator.calculate_final_defense(null)
	assert_eq(defense, 0.0, "空玩家防御力应为0")

func test_calculate_final_speed_null_player():
	var speed = AttributeCalculator.calculate_final_speed(null)
	assert_eq(speed, 0.0, "空玩家速度应为0")

func test_calculate_final_max_health_null_player():
	var health = AttributeCalculator.calculate_final_max_health(null)
	assert_eq(health, 0.0, "空玩家最大气血应为0")

func test_calculate_final_max_spirit_energy_null_player():
	var spirit = AttributeCalculator.calculate_final_max_spirit_energy(null)
	assert_eq(spirit, 0.0, "空玩家最大灵气应为0")

func test_calculate_final_spirit_gain_speed_null_player():
	var speed = AttributeCalculator.calculate_final_spirit_gain_speed(null)
	assert_eq(speed, 1.0, "空玩家灵气获取速度应为1.0")

func test_calculate_final_spirit_gain_speed_uses_player_base_speed():
	var player = _create_simple_mock_player(100.0, 50.0, 5.0)
	player.base_spirit_gain = 2.5
	var speed = AttributeCalculator.calculate_final_spirit_gain_speed(player)
	assert_eq(speed, 2.5, "应优先使用玩家当前基础灵气获取速度")
	player.free()

#endregion

#region 辅助函数

func _create_simple_mock_player(attack: float, defense: float, speed: float) -> Node:
	var script = GDScript.new()
	script.source_code = """
extends Node
var base_attack: float = 0.0
var base_defense: float = 0.0
var base_speed: float = 0.0
var base_max_health: float = 500.0
var base_max_spirit: float = 100.0
var base_spirit_gain: float = 1.0
func get_spell_system(): return null
"""
	script.reload()
	
	var player = Node.new()
	player.set_script(script)
	player.base_attack = attack
	player.base_defense = defense
	player.base_speed = speed
	
	return player

#endregion
