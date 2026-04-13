extends Control

var max_value: float = 100.0:
	set(value):
		max_value = max(value, 1.0)
		_update_progress()

var current_value: float = 0.0:
	set(val):
		current_value = clamp(val, 0.0, max_value)
		_update_progress()

var current_progress: float = 0.0
var target_progress: float = 0.0

func _update_progress():
	target_progress = current_value / max_value

func _process(delta: float):
	if abs(current_progress - target_progress) > 0.001:
		var speed = 3.0
		current_progress = move_toward(current_progress, target_progress, delta * speed)
	else:
		current_progress = target_progress
	
	queue_redraw()

func _draw():
	var rect_size = get_rect().size
	var container_center = Vector2(rect_size.x / 2.0, rect_size.y / 2.0)
	
	# 气海参数 - 根据小人素材的生成脚本
	var dantian_radius = 43.0
	# 气海中心往下移动一点
	var dantian_center = Vector2(container_center.x, container_center.y + 34.0)
	
	if current_progress <= 0.001:
		return
	
	# 绘制矩形进度条，填满肚子区域
	# 从底部开始填充
	var bottom_y = dantian_center.y + dantian_radius
	var fill_height = current_progress * dantian_radius * 2.0
	var top_y = bottom_y - fill_height
	
	# 矩形宽度覆盖整个气海区域
	var left_x = dantian_center.x - dantian_radius
	var right_x = dantian_center.x + dantian_radius
	
	# 绘制填充的矩形
	var rect = Rect2(left_x, top_y, right_x - left_x, fill_height)
	draw_rect(rect, Color(0.3, 0.6, 1.0, 0.7))
