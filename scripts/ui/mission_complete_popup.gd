extends Control
## Brief "ALL MISSIONS COMPLETE!" gold popup that auto-dismisses.

var _fredoka_bold: Font = null


func show_popup(parent: Node) -> void:
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = "ALL MISSIONS COMPLETE!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		label.add_theme_font_override("font", _fredoka_bold)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#FFD93D"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	# Use a CanvasLayer to render above everything
	var canvas := CanvasLayer.new()
	canvas.layer = 25
	parent.add_child(canvas)
	canvas.add_child(self)

	# Entrance: scale bounce
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(0.3, 0.3)
	modulate.a = 0.0

	var tw := create_tween()
	tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	tw.tween_property(self, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "scale", Vector2(1.1, 1.1), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		canvas.queue_free())
