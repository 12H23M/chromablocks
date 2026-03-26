extends Control
## Brief score milestone popup — shows for ~1s, no game interruption.

var _label: Label
var _fredoka: Font


func _ready() -> void:
	_fredoka = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func show_milestone(score_value: int, center_pos: Vector2) -> void:
	_label = Label.new()
	_label.text = "🎯 %s!" % FormatUtils.format_number(score_value)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_label.add_theme_font_override("font", _fredoka)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.24))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# Position above board center
	await get_tree().process_frame
	if not is_instance_valid(_label):
		return
	_label.position = center_pos - Vector2(_label.size.x / 2.0, _label.size.y / 2.0 + 60)
	_label.pivot_offset = _label.size / 2.0

	# Animate: scale up, hold, fade out
	_label.scale = Vector2(0.3, 0.3)
	_label.modulate.a = 0.0

	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)
	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	# Pop in
	tw.tween_property(_label, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_label, "scale", Vector2(1.15, 1.15), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Settle
	tw.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.1) \
		.set_ease(Tween.EASE_IN_OUT)
	# Hold
	tw.tween_interval(0.5)
	# Fade out + float up
	tw.tween_property(_label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_label, "position:y", _label.position.y - 30, 0.3) \
		.set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
