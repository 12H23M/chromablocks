extends Control

const COLORS := {
    2: Color(0.2, 0.6, 1.0),
    3: Color(0.2, 0.9, 0.4),
    4: Color(1.0, 0.85, 0.1),
}

const LABELS := {
    2: "DOUBLE!",
    3: "TRIPLE!",
    4: "QUAD!",
}

func show_multiline(lines: int, center: Vector2) -> void:
    if lines < 2 or lines > 4:
        queue_free()
        return
    
    position = Vector2.ZERO
    size = get_viewport_rect().size
    mouse_filter = MOUSE_FILTER_IGNORE
    
    var color: Color = COLORS.get(lines, Color.WHITE)
    var text: String = LABELS.get(lines, "AMAZING!")
    
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 52 if lines == 4 else 44)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("outline_size", 8)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(0, center.y - 30)
    label.size = Vector2(size.x, 60)
    label.pivot_offset = Vector2(size.x / 2.0, 30)
    add_child(label)
    
    var tw := create_tween()
    label.scale = Vector2(0.3, 0.3)
    label.modulate.a = 0.0
    tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(label, "modulate:a", 1.0, 0.1)
    tw.tween_property(label, "scale", Vector2.ONE, 0.1)
    tw.tween_interval(0.4)
    tw.tween_property(label, "modulate:a", 0.0, 0.2)
    tw.tween_callback(queue_free)
