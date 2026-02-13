extends Label

func show_score(value: int, start_pos: Vector2) -> void:
	text = "+" + str(value)
	global_position = start_pos
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Scale bounce size varies by score value
	var bounce_scale := 1.2
	if value >= 2000:
		add_theme_font_size_override("font_size", 32)
		add_theme_color_override("font_color", AppColors.GOLDEN)
		bounce_scale = 1.3
	elif value >= 500:
		add_theme_font_size_override("font_size", 28)
		add_theme_color_override("font_color", AppColors.SAGE_GREEN)
		bounce_scale = 1.25
	else:
		add_theme_font_size_override("font_size", 22)
		add_theme_color_override("font_color", AppColors.TEXT_PRIMARY)

	# Start from zero scale for pop-in effect
	pivot_offset = size / 2.0
	scale = Vector2.ZERO

	var tween := create_tween()
	# Phase 1: Scale bounce 0 -> overshoot -> 1.0 (0.16s)
	tween.tween_property(self, "scale", Vector2.ONE * bounce_scale, 0.10) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.06) \
		 .set_ease(Tween.EASE_IN_OUT)
	# Phase 2: Float up + fade out (parallel)
	tween.parallel().tween_property(self, "global_position:y", start_pos.y - 50, 0.5) \
		 .set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2) \
		 .set_delay(0.25)
	tween.tween_callback(queue_free)
