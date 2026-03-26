extends Control

func show_level_up(level: int, center: Vector2) -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size
    mouse_filter = MOUSE_FILTER_IGNORE
    
    var label := Label.new()
    label.text = "LEVEL UP! %d" % level
    label.add_theme_font_size_override("font_size", 48)
    label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
    label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.5))
    label.add_theme_constant_override("outline_size", 6)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(0, center.y - 30)
    label.size = Vector2(size.x, 60)
    add_child(label)
    
    label.pivot_offset = Vector2(size.x / 2.0, 30)
    label.scale = Vector2(0.5, 0.5)
    label.modulate.a = 0.0
    
    var tw := create_tween()
    tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tw.parallel().tween_property(label, "modulate:a", 1.0, 0.1)
    tw.tween_interval(0.6)
    tw.tween_property(label, "modulate:a", 0.0, 0.3)
    tw.tween_callback(queue_free)
