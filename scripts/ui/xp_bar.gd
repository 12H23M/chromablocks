extends Control

var _progress: float = 0.0

func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var bar_height := 6.0
	var y_offset := (size.y - bar_height) / 2.0
	var bar_rect := Rect2(0, y_offset, size.x, bar_height)
	var radius := bar_height / 2.0

	# Track background
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(1, 1, 1, 0.06)
	bg_style.corner_radius_top_left = int(radius)
	bg_style.corner_radius_top_right = int(radius)
	bg_style.corner_radius_bottom_left = int(radius)
	bg_style.corner_radius_bottom_right = int(radius)
	draw_style_box(bg_style, bar_rect)

	# Fill with rainbow gradient
	if _progress > 0.01:
		var fill_width := size.x * _progress
		var gradient_colors := [
			Color(0.37, 0.73, 1.0),   # #5EBAFF
			Color(0.655, 0.545, 0.98), # #A78BFA
			Color(0.957, 0.447, 0.714) # #F472B6
		]
		var steps := int(fill_width)
		if steps < 2:
			steps = 2
		for i in steps:
			var t := float(i) / float(steps)
			var color: Color
			if t < 0.5:
				color = gradient_colors[0].lerp(gradient_colors[1], t * 2.0)
			else:
				color = gradient_colors[1].lerp(gradient_colors[2], (t - 0.5) * 2.0)
			var x_pos := float(i)
			# Clip to rounded shape: skip pixels outside radius at edges
			var local_y_center := bar_height / 2.0
			if x_pos < radius:
				var dx := radius - x_pos
				if dx > radius:
					continue
			if x_pos > fill_width - 1:
				break
			draw_rect(Rect2(x_pos, y_offset, 1.0, bar_height), color)

		# Round the fill edges by drawing circles at start and end
		var fill_rect := Rect2(0, y_offset, fill_width, bar_height)
		# Bright dot at the leading edge
		if fill_width > 4:
			var dot_center := Vector2(fill_width - 1, y_offset + bar_height / 2.0)
			draw_circle(dot_center, 4.0, Color(1, 1, 1, 0.5))

		# Glow under the fill
		var glow_color := Color(0.655, 0.545, 0.98, 0.4)
		draw_rect(Rect2(0, y_offset - 1, fill_width, bar_height + 2), glow_color)
