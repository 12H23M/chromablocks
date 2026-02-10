extends Label

func show_score(value: int, start_pos: Vector2) -> void:
	text = "+" + str(value)
	global_position = start_pos
	modulate.a = 1.0

	# Style based on value
	if value >= 2000:
		# Perfect clear — golden, larger
		add_theme_font_size_override("font_size", 32)
		add_theme_color_override("font_color", AppColors.GOLDEN)
	elif value >= 500:
		# Big score — sage green, medium
		add_theme_font_size_override("font_size", 28)
		add_theme_color_override("font_color", AppColors.SAGE_GREEN)
	else:
		# Normal — primary text color
		add_theme_font_size_override("font_size", 22)
		add_theme_color_override("font_color", AppColors.TEXT_PRIMARY)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", start_pos.y - 80, 0.8) \
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8) \
		 .set_ease(Tween.EASE_IN).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
