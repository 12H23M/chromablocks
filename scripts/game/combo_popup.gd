extends Label

func show_combo(combo: int, center_pos: Vector2) -> void:
	text = "COMBO ×" + str(combo)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font_size := 36
	var color := AppColors.SKY_LIGHT
	if combo >= 5:
		font_size = 52
		color = AppColors.SPECIAL
	elif combo >= 4:
		font_size = 46
		color = AppColors.CORAL_LIGHT
	elif combo >= 3:
		font_size = 42
		color = AppColors.AMBER_LIGHT

	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_theme_constant_override("outline_size", 6)
	add_theme_color_override("font_shadow_color", Color(color.r, color.g, color.b, 0.4))
	add_theme_constant_override("shadow_offset_x", 0)
	add_theme_constant_override("shadow_offset_y", 2)

	# Position at center
	size = Vector2(260, 60)
	global_position = center_pos - size / 2.0
	modulate.a = 1.0

	# Start from zero scale for pop-in
	pivot_offset = size / 2.0
	scale = Vector2.ZERO

	var bounce_scale := 1.4 if combo >= 4 else 1.25

	var tween := create_tween()
	# Phase 1: Scale pop (punchy)
	tween.tween_property(self, "scale", Vector2.ONE * bounce_scale, 0.12) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Phase 2: Settle with slight overshoot
	tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.1) \
		 .set_ease(Tween.EASE_IN_OUT)
	# Phase 3: Hold visible (no movement)
	tween.tween_interval(0.35)
	# Phase 4: Float up + fade (longer, more visible)
	tween.tween_property(self, "global_position:y", center_pos.y - size.y / 2.0 - 50, 0.5) \
		 .set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25) \
		 .set_delay(0.25)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.8, 0.5) \
		 .set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
