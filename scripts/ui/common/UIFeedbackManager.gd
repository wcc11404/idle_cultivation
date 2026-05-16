class_name UIFeedbackManager
extends RefCounted

const META_BUTTON_TAP_BOUND := "__ui_feedback_button_tap_bound"
const META_BASE_MODULATE := "__ui_feedback_base_modulate"
const META_BASE_POSITION := "__ui_feedback_base_position"
const META_TWEEN_PREFIX := "__ui_feedback_tween_"

static var _breathing_tweens: Dictionary = {}


static func bind_button_tap(button: Button, config: Dictionary = {}) -> void:
	if not button or bool(button.get_meta(META_BUTTON_TAP_BOUND, false)):
		return
	button.set_meta(META_BUTTON_TAP_BOUND, true)
	button.button_down.connect(func() -> void:
		if not is_instance_valid(button) or button.disabled:
			return
		_play_button_scale(button, float(config.get("pressed_scale", 0.965)), float(config.get("press_duration", 0.055)))
	)
	button.button_up.connect(func() -> void:
		if not is_instance_valid(button) or button.disabled:
			return
		_play_button_scale(button, 1.0, float(config.get("release_duration", 0.085)))
	)
	button.mouse_exited.connect(func() -> void:
		if not is_instance_valid(button) or button.disabled:
			return
		_play_button_scale(button, 1.0, float(config.get("release_duration", 0.085)))
	)


static func play_popup_open(overlay: CanvasItem, panel: Control, config: Dictionary = {}) -> void:
	if not _is_valid_canvas(overlay) or not panel:
		return
	overlay.visible = true
	panel.visible = true
	_kill_meta_tween(panel, "popup")
	_kill_meta_tween(overlay, "popup")
	_set_center_pivot(panel)
	overlay.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(float(config.get("start_scale", 0.96)), float(config.get("start_scale", 0.96)))
	var tween := panel.create_tween()
	panel.set_meta(META_TWEEN_PREFIX + "popup", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, float(config.get("overlay_duration", 0.16)))
	tween.tween_property(panel, "modulate:a", 1.0, float(config.get("panel_duration", 0.18)))
	tween.tween_property(panel, "scale", Vector2.ONE, float(config.get("panel_duration", 0.18)))


static func play_popup_close(overlay: CanvasItem, panel: Control, on_finished: Callable = Callable(), config: Dictionary = {}) -> void:
	if not _is_valid_canvas(overlay) or not panel or not overlay.visible:
		if on_finished.is_valid():
			on_finished.call()
		return
	_kill_meta_tween(panel, "popup")
	_set_center_pivot(panel)
	var tween := panel.create_tween()
	panel.set_meta(META_TWEEN_PREFIX + "popup", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(overlay, "modulate:a", 0.0, float(config.get("overlay_duration", 0.12)))
	tween.tween_property(panel, "modulate:a", 0.0, float(config.get("panel_duration", 0.10)))
	tween.tween_property(panel, "scale", Vector2(float(config.get("end_scale", 0.98)), float(config.get("end_scale", 0.98))), float(config.get("panel_duration", 0.10)))
	tween.finished.connect(func() -> void:
		if on_finished.is_valid():
			on_finished.call()
	)


static func play_tab_content_in(panel: Control, config: Dictionary = {}) -> void:
	if not panel:
		return
	_kill_meta_tween(panel, "tab_in")
	if not panel.has_meta(META_BASE_POSITION):
		panel.set_meta(META_BASE_POSITION, panel.position)
	var base_position: Vector2 = panel.get_meta(META_BASE_POSITION)
	panel.visible = true
	panel.modulate.a = 0.0
	panel.position = base_position + Vector2(0.0, float(config.get("offset_y", 8.0)))
	var tween := panel.create_tween()
	panel.set_meta(META_TWEEN_PREFIX + "tab_in", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, float(config.get("duration", 0.18)))
	tween.tween_property(panel, "position", base_position, float(config.get("duration", 0.18)))


static func play_value_bump(label: Label, direction: int = 0, config: Dictionary = {}) -> void:
	if not label:
		return
	_kill_meta_tween(label, "value")
	_set_center_pivot(label)
	if not label.has_meta(META_BASE_MODULATE):
		label.set_meta(META_BASE_MODULATE, label.modulate)
	var base_modulate: Color = Color(config.get("base_modulate", label.get_meta(META_BASE_MODULATE)))
	var flash_color := Color(config.get("flash_color", _get_value_flash_color(direction)))
	label.scale = Vector2.ONE
	label.modulate = flash_color
	var tween := label.create_tween()
	label.set_meta(META_TWEEN_PREFIX + "value", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(float(config.get("scale", 1.08)), float(config.get("scale", 1.08))), float(config.get("up_duration", 0.08)))
	tween.chain().tween_property(label, "scale", Vector2.ONE, float(config.get("down_duration", 0.14)))
	tween.parallel().tween_property(label, "modulate", base_modulate, float(config.get("color_duration", 0.18)))


static func play_soft_flash(control: Control, config: Dictionary = {}) -> void:
	if not control:
		return
	_kill_meta_tween(control, "soft_flash")
	if not control.has_meta(META_BASE_MODULATE):
		control.set_meta(META_BASE_MODULATE, control.modulate)
	var base_modulate: Color = Color(control.get_meta(META_BASE_MODULATE))
	var flash_color := Color(config.get("flash_color", Color(1.0, 0.86, 0.42, 1.0)))
	if control.visible and base_modulate.a <= 0.01:
		base_modulate.a = maxf(control.modulate.a, 1.0)
		control.set_meta(META_BASE_MODULATE, base_modulate)
	flash_color.a = base_modulate.a
	control.modulate = flash_color
	var tween := control.create_tween()
	control.set_meta(META_TWEEN_PREFIX + "soft_flash", tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", base_modulate, float(config.get("duration", 0.28)))


static func start_breathing(control: Control, key: String = "default", config: Dictionary = {}) -> void:
	if not control:
		return
	var tween_key := _breathing_key(control, key)
	stop_breathing(control, key)
	_set_center_pivot(control)
	var tween := control.create_tween()
	_breathing_tweens[tween_key] = tween
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var target_scale := Vector2(float(config.get("scale", 1.025)), float(config.get("scale", 1.025)))
	var half_duration := float(config.get("half_duration", 1.05))
	tween.tween_property(control, "scale", target_scale, half_duration)
	tween.tween_property(control, "scale", Vector2.ONE, half_duration)


static func stop_breathing(control: Control, key: String = "default") -> void:
	if not control:
		return
	var tween_key := _breathing_key(control, key)
	if _breathing_tweens.has(tween_key):
		var tween = _breathing_tweens[tween_key]
		if tween is Tween and is_instance_valid(tween):
			tween.kill()
		_breathing_tweens.erase(tween_key)
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16)


static func _play_button_scale(button: Button, target_scale: float, duration: float) -> void:
	_kill_meta_tween(button, "button")
	_set_center_pivot(button)
	var tween := button.create_tween()
	button.set_meta(META_TWEEN_PREFIX + "button", tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), duration)


static func _kill_meta_tween(node: Object, key: String) -> void:
	if not node:
		return
	var meta_key := META_TWEEN_PREFIX + key
	if not node.has_meta(meta_key):
		return
	var tween = node.get_meta(meta_key)
	if tween is Tween and is_instance_valid(tween):
		tween.kill()
	node.remove_meta(meta_key)


static func _set_center_pivot(control: Control) -> void:
	if not control:
		return
	control.pivot_offset = control.size * 0.5


static func _is_valid_canvas(item: CanvasItem) -> bool:
	return item != null and is_instance_valid(item)


static func _breathing_key(control: Control, key: String) -> String:
	return "%s:%s" % [str(control.get_instance_id()), key]


static func _get_value_flash_color(direction: int) -> Color:
	if direction < 0:
		return Color(0.86, 0.42, 0.34, 1.0)
	return Color(1.0, 0.78, 0.30, 1.0)
