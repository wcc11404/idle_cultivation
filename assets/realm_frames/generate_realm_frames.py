from PIL import Image, ImageDraw, ImageFilter
import os
import math

LEGACY_GENERATOR_MESSAGE = (
    "generate_realm_frames.py is a legacy 200x50 badge-frame generator. "
    "TopBar now uses 1280x110 full-width realm banner PNG assets generated "
    "with imagegen, so this script is intentionally disabled to avoid "
    "overwriting the current artwork."
)


def draw_gradient_circle(draw, center_x, center_y, radius, color_center, color_edge):
    """绘制渐变圆形"""
    for r in range(radius, 0, -1):
        ratio = r / radius
        r_color = int(color_center[0] * (1 - ratio) + color_edge[0] * ratio)
        g_color = int(color_center[1] * (1 - ratio) + color_edge[1] * ratio)
        b_color = int(color_center[2] * (1 - ratio) + color_edge[2] * ratio)
        alpha = int(color_center[3] * (1 - ratio) + color_edge[3] * ratio) if len(color_center) > 3 else 255
        draw.ellipse(
            [center_x - r, center_y - r, center_x + r, center_y + r],
            fill=(r_color, g_color, b_color, alpha)
        )


def draw_star(draw, center_x, center_y, size, color):
    """绘制五角星"""
    points = []
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        if i % 2 == 0:
            r = size
        else:
            r = size * 0.4
        x = center_x + r * math.cos(angle)
        y = center_y - r * math.sin(angle)
        points.append((x, y))
    
    # 绘制填充的五角星
    draw.polygon(points, fill=color)


def create_qi_refining_frame(width=200, height=50):
    """创建炼气期等级背景框 - 浅蓝色主色调，1个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (80, 120, 160, 255)
    inner_color = (140, 180, 220, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(100, 140, 180, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧1个圆点
    center_y = height // 2
    draw_gradient_circle(draw, width - 12, center_y, 4, (160, 190, 220, 255), (100, 130, 170, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_foundation_frame(width=200, height=50):
    """创建筑基期等级背景框 - 棕色主色调，2个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (120, 85, 50, 255)
    inner_color = (180, 140, 100, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(140, 100, 60, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧2个圆点，等距等大小，从右到左由浅到深
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    # 右边圆点（浅）
    draw_gradient_circle(draw, base_x, center_y, 4, (220, 190, 150, 255), (180, 150, 110, 200))
    # 左边圆点（深）
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (180, 150, 110, 255), (120, 90, 50, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_golden_core_frame(width=200, height=50):
    """创建金丹期等级背景框 - 金黄色主色调，3个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (180, 150, 40, 255)
    inner_color = (220, 190, 80, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(200, 170, 60, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧3个圆点，等距等大小，从右到左由浅到深
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    draw_gradient_circle(draw, base_x, center_y, 4, (255, 240, 150, 255), (220, 200, 100, 200))
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (250, 230, 130, 255), (200, 180, 80, 200))
    draw_gradient_circle(draw, base_x - spacing * 2, center_y, 4, (230, 200, 90, 255), (160, 140, 40, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_nascent_soul_frame(width=200, height=50):
    """创建元婴期等级背景框 - 紫色主色调，4个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (140, 80, 160, 255)
    inner_color = (180, 120, 200, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(160, 100, 180, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧4个圆点，等距等大小，从右到左由浅到深
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    draw_gradient_circle(draw, base_x, center_y, 4, (240, 200, 255, 255), (200, 160, 220, 200))
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (235, 190, 250, 255), (190, 150, 210, 200))
    draw_gradient_circle(draw, base_x - spacing * 2, center_y, 4, (225, 175, 240, 255), (175, 135, 195, 200))
    draw_gradient_circle(draw, base_x - spacing * 3, center_y, 4, (205, 145, 220, 255), (145, 105, 165, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_spirit_separation_frame(width=200, height=50):
    """创建化神期等级背景框 - 红色主色调，1个五角星"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (180, 60, 60, 255)
    inner_color = (220, 100, 100, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(200, 80, 80, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧1个五角星
    center_y = height // 2
    draw_star(draw, width - 18, center_y, 6, (255, 180, 180, 255))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_void_refining_frame(width=200, height=50):
    """创建炼虚期等级背景框 - 青色主色调，1个五角星+1个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (60, 140, 140, 255)
    inner_color = (100, 180, 180, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(80, 160, 160, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧：五角星（左）+ 圆点（右）
    center_y = height // 2
    spacing = 14
    
    # 五角星在最左侧
    draw_star(draw, width - 18 - spacing, center_y, 6, (200, 255, 255, 255))
    # 圆点在右侧（深）
    draw_gradient_circle(draw, width - 12, center_y, 4, (140, 225, 225, 255), (100, 160, 160, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_body_integration_frame(width=200, height=50):
    """创建合体期等级背景框 - 深紫色主色调，1个五角星+2个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (100, 60, 120, 255)
    inner_color = (140, 100, 160, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(120, 80, 140, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧：五角星（最左）+ 2个圆点
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    # 五角星在最左侧
    draw_star(draw, base_x - spacing * 2 - 6, center_y, 6, (220, 190, 240, 255))
    # 2个圆点，从右到左由浅到深
    draw_gradient_circle(draw, base_x, center_y, 4, (220, 190, 240, 255), (180, 150, 200, 200))
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (185, 155, 205, 255), (145, 115, 165, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_mahayana_frame(width=200, height=50):
    """创建大乘期等级背景框 - 橙金色主色调，1个五角星+3个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (200, 130, 40, 255)
    inner_color = (240, 170, 80, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(220, 150, 60, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧：五角星（最左）+ 3个圆点
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    # 五角星在最左侧
    draw_star(draw, base_x - spacing * 3 - 6, center_y, 6, (255, 230, 180, 255))
    # 3个圆点，从右到左由浅到深
    draw_gradient_circle(draw, base_x, center_y, 4, (255, 230, 180, 255), (220, 190, 140, 200))
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (255, 220, 160, 255), (210, 180, 120, 200))
    draw_gradient_circle(draw, base_x - spacing * 2, center_y, 4, (230, 190, 100, 255), (180, 150, 60, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def create_tribulation_frame(width=200, height=50):
    """创建渡劫期等级背景框 - 白金色主色调，1个五角星+4个圆点"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    border_color = (200, 200, 200, 255)
    inner_color = (240, 240, 240, 200)
    
    corner_radius = 12
    
    draw.rounded_rectangle(
        [0, 0, width - 1, height - 1],
        radius=corner_radius,
        outline=border_color,
        width=2,
        fill=(220, 220, 220, 180)
    )
    
    padding = 4
    draw.rounded_rectangle(
        [padding, padding, width - 1 - padding, height - 1 - padding],
        radius=corner_radius - 2,
        outline=inner_color,
        width=1
    )
    
    # 右侧：五角星（最左）+ 4个圆点
    center_y = height // 2
    spacing = 12
    base_x = width - 12
    
    # 五角星在最左侧
    draw_star(draw, base_x - spacing * 4 - 6, center_y, 6, (255, 255, 255, 255))
    # 4个圆点，从右到左由浅到深
    draw_gradient_circle(draw, base_x, center_y, 4, (255, 255, 255, 255), (220, 220, 220, 200))
    draw_gradient_circle(draw, base_x - spacing, center_y, 4, (255, 255, 250, 255), (218, 218, 215, 200))
    draw_gradient_circle(draw, base_x - spacing * 2, center_y, 4, (255, 255, 245, 255), (216, 216, 210, 200))
    draw_gradient_circle(draw, base_x - spacing * 3, center_y, 4, (255, 255, 240, 255), (214, 214, 205, 200))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    return img


def main():
    """主函数：生成境界等级背景框"""
    # 获取项目根目录
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    output_dir = os.path.join(project_root, 'assets', 'realm_frames')
    os.makedirs(output_dir, exist_ok=True)
    
    frame_size = (200, 50)
    
    # 生成炼气期背景框
    qi_refining = create_qi_refining_frame(*frame_size)
    qi_refining.save(os.path.join(output_dir, 'realm_frame_qi_refining.png'))
    print(f'生成炼气期等级背景框: realm_frame_qi_refining.png')
    
    # 生成筑基期背景框
    foundation = create_foundation_frame(*frame_size)
    foundation.save(os.path.join(output_dir, 'realm_frame_foundation.png'))
    print(f'生成筑基期等级背景框: realm_frame_foundation.png')
    
    # 生成金丹期背景框
    golden_core = create_golden_core_frame(*frame_size)
    golden_core.save(os.path.join(output_dir, 'realm_frame_golden_core.png'))
    print(f'生成金丹期等级背景框: realm_frame_golden_core.png')
    
    # 生成元婴期背景框
    nascent_soul = create_nascent_soul_frame(*frame_size)
    nascent_soul.save(os.path.join(output_dir, 'realm_frame_nascent_soul.png'))
    print(f'生成元婴期等级背景框: realm_frame_nascent_soul.png')
    
    # 生成化神期背景框
    spirit_separation = create_spirit_separation_frame(*frame_size)
    spirit_separation.save(os.path.join(output_dir, 'realm_frame_spirit_separation.png'))
    print(f'生成化神期等级背景框: realm_frame_spirit_separation.png')
    
    # 生成炼虚期背景框
    void_refining = create_void_refining_frame(*frame_size)
    void_refining.save(os.path.join(output_dir, 'realm_frame_void_refining.png'))
    print(f'生成炼虚期等级背景框: realm_frame_void_refining.png')
    
    # 生成合体期背景框
    body_integration = create_body_integration_frame(*frame_size)
    body_integration.save(os.path.join(output_dir, 'realm_frame_body_integration.png'))
    print(f'生成合体期等级背景框: realm_frame_body_integration.png')
    
    # 生成大乘期背景框
    mahayana = create_mahayana_frame(*frame_size)
    mahayana.save(os.path.join(output_dir, 'realm_frame_mahayana.png'))
    print(f'生成大乘期等级背景框: realm_frame_mahayana.png')
    
    # 生成渡劫期背景框
    tribulation = create_tribulation_frame(*frame_size)
    tribulation.save(os.path.join(output_dir, 'realm_frame_tribulation.png'))
    print(f'生成渡劫期等级背景框: realm_frame_tribulation.png')


if __name__ == '__main__':
    raise SystemExit(LEGACY_GENERATOR_MESSAGE)
