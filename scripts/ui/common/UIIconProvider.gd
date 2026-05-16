class_name UIIconProvider
extends RefCounted

const ICON_SPIRIT_STONE := "res://assets/icon/icon_item_spirit_stone.png"
const ICON_IMMORTAL_CRYSTAL := "res://assets/icon/icon_item_immortal_crystal.png"
const ICON_AUDIO_ON := "res://assets/icon/icon_audio_on.png"
const ICON_AUDIO_OFF := "res://assets/icon/icon_audio_mute.png"
const ICON_SPELL_ELEMENT_NONE := "res://assets/icon/icon_spell_element_none.png"
const ICON_SPELL_ELEMENT_METAL := "res://assets/icon/icon_spell_element_metal.png"
const ICON_SPELL_ELEMENT_WOOD := "res://assets/icon/icon_spell_element_wood.png"
const ICON_SPELL_ELEMENT_WATER := "res://assets/icon/icon_spell_element_water.png"
const ICON_SPELL_ELEMENT_FIRE := "res://assets/icon/icon_spell_element_fire.png"
const ICON_SPELL_ELEMENT_EARTH := "res://assets/icon/icon_spell_element_earth.png"

const SPELL_ELEMENT_ICON_PATHS := {
	"none": ICON_SPELL_ELEMENT_NONE,
	"metal": ICON_SPELL_ELEMENT_METAL,
	"wood": ICON_SPELL_ELEMENT_WOOD,
	"water": ICON_SPELL_ELEMENT_WATER,
	"fire": ICON_SPELL_ELEMENT_FIRE,
	"earth": ICON_SPELL_ELEMENT_EARTH
}

static var _cache: Dictionary = {}

static func load_svg_texture(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]

	if path.to_lower().ends_with(".png"):
		var png_texture := _load_png_texture(path)
		if png_texture:
			_cache[path] = png_texture
		return png_texture

	# 1) 优先走 Godot 资源导入链路（跨平台最稳定，Android 推荐）
	if FileAccess.file_exists(path + ".import"):
		var imported: Resource = load(path)
		if imported is Texture2D:
			_cache[path] = imported
			return imported

	# 2) 回退：运行时 SVG 解析（桌面可用，移动端可能失败）
	var svg_source := FileAccess.get_file_as_string(path)
	if svg_source.is_empty():
		# 3) 再回退：尝试同名 PNG
		var png_path := path.get_basename() + ".png"
		var png_res: Resource = load(png_path)
		if png_res is Texture2D:
			_cache[path] = png_res
			return png_res
		push_warning("Failed to read icon source: %s" % path)
		return null

	var image := Image.new()
	var err := image.load_svg_from_string(svg_source)
	if err != OK:
		var fallback_png := path.get_basename() + ".png"
		var fallback_res: Resource = load(fallback_png)
		if fallback_res is Texture2D:
			_cache[path] = fallback_res
			return fallback_res
		push_warning("Failed to parse SVG icon: %s" % path)
		return null

	var texture := ImageTexture.create_from_image(image)
	_cache[path] = texture
	return texture

static func _load_png_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path + ".import"):
		var imported: Resource = load(path)
		if imported is Texture2D:
			return imported
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load PNG icon: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

static func get_spell_element_texture(element: String) -> Texture2D:
	var normalized := String(element).to_lower()
	var path := str(SPELL_ELEMENT_ICON_PATHS.get(normalized, ICON_SPELL_ELEMENT_NONE))
	return load_svg_texture(path)
