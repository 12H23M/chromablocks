extends Control
## "ALL MISSIONS COMPLETE!" popup with particles, XP counter, and fanfare.

var _fredoka_bold: Font = null


func show_popup(parent: Node, total_xp: int = 0) -> void:
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background vignette
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 8)
	center.add_child(vbox)

	# Star icons
	var stars := Label.new()
	stars.text = "⭐ ⭐ ⭐"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 28)
	vbox.add_child(stars)

	# Title
	var title := Label.new()
	title.text = "ALL MISSIONS COMPLETE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		title.add_theme_font_override("font", _fredoka_bold)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#FFD93D"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.custom_minimum_size = Vector2(300, 60)
	vbox.add_child(title)

	# XP reward
	if total_xp > 0:
		var xp_label := Label.new()
		xp_label.text = "+%d XP" % total_xp
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			xp_label.add_theme_font_override("font", _fredoka_bold)
		xp_label.add_theme_font_size_override("font_size", 20)
		xp_label.add_theme_color_override("font_color", Color("#4CAF50"))
		xp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		xp_label.add_theme_constant_override("shadow_offset_y", 2)
		vbox.add_child(xp_label)

	# CanvasLayer to render above everything
	var canvas := CanvasLayer.new()
	canvas.layer = 25
	parent.add_child(canvas)
	canvas.add_child(self)

	# Spawn confetti particles
	_spawn_confetti(self)

	# Entrance animation
	var title_ref = title
	title_ref.pivot_offset = title_ref.size / 2.0
	title_ref.scale = Vector2(0.3, 0.3)
	modulate.a = 0.0

	var tw := create_tween()
	tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	tw.tween_property(self, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(title_ref, "scale", Vector2(1.1, 1.1), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(title_ref, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		canvas.queue_free())


func _spawn_confetti(parent: Control) -> void:
	var colors := [
		Color("#FFD93D"), Color("#4CAF50"), Color("#2196F3"),
		Color("#FF9800"), Color("#E040FB"), Color("#F44336"),
	]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var vp_size := get_viewport().get_visible_rect().size

	for i in 30:
		var rect := ColorRect.new()
		var c: Color = colors[rng.randi_range(0, colors.size() - 1)]
		rect.color = c
		var size := rng.randf_range(4, 10)
		rect.size = Vector2(size, size * rng.randf_range(1.0, 2.5))
		rect.position = Vector2(rng.randf_range(0, vp_size.x), -20)
		rect.rotation = rng.randf_range(0, TAU)
		parent.add_child(rect)

		var fall_dur := rng.randf_range(1.2, 2.5)
		var drift := rng.randf_range(-60, 60)
		var spin := rng.randf_range(-3.0, 3.0)
		var tw := rect.create_tween()
		tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
		tw.set_parallel(true)
		tw.tween_property(rect, "position:y", vp_size.y + 20, fall_dur) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(rect, "position:x", rect.position.x + drift, fall_dur)
		tw.tween_property(rect, "rotation", rect.rotation + spin * TAU, fall_dur)
		tw.tween_property(rect, "modulate:a", 0.0, fall_dur * 0.6).set_delay(fall_dur * 0.4)
