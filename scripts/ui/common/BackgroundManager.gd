extends Control

# 设置背景颜色为 RGB (239, 229, 205)
var background_color: Color = Color(239.0/255.0, 229.0/255.0, 205.0/255.0)

var background_rect: ColorRect = null

func _ready():
	# 创建背景矩形
	_create_background_rect()
	# 初始化背景颜色
	update_background()

func _create_background_rect():
	background_rect = ColorRect.new()
	background_rect.name = "BackgroundRect"
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

func set_background_color(color: Color):
	background_color = color
	update_background()

func get_background_color() -> Color:
	return background_color

func update_background():
	# 设置背景颜色
	if background_rect:
		background_rect.color = background_color
	queue_redraw()
