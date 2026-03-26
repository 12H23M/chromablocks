extends Control

func show_perfect_clear(center: Vector2) -> void:
    position = Vector2.ZERO
    size = get_viewport_rect().size
    mouse_filter = MOUSE_FILTER_IGNORE
    
    var label := Label.new()
    label.text = "✨ PERFECT CLEAR! ✨"
    label.add_theme_font_size_override("font_size", 52)
    label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
    label.add_theme_color_override("font_outline_color", Color(0.5, 0.1, 0.8))
    label.add_theme_constant_override("outline_size", 8)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(0, center.y - 30)
    label.size = Vector2(size.x, 60)
    label.pivot_offset = Vector2(size.x / 2.0, 30)
    add_child(label)
    
    var tw := create_tween()
    label.scale = Vector2(0.3, 0.3)
    label.modulate.a = 0.0
    tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(label, "modulate:a", 1.0, 0.1)
    tw.tween_property(label, "scale", Vector2.ONE, 0.1)
    tw.tween_interval(0.8)
    tw.tween_property(label, "modulate:a", 0.0, 0.3)
    tw.tween_callback(queue_free)
