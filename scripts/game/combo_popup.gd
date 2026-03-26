extends Control

const COMBO_COLORS := {
    2: Color(1.0, 0.95, 0.3),    # x2 - yellow
    3: Color(1.0, 0.7, 0.2),     # x3 - orange
    4: Color(1.0, 0.4, 0.3),     # x4 - coral
    5: Color(1.0, 0.2, 0.4),     # x5 - red-pink
}
const DEFAULT_COLOR := Color(1.0, 0.15, 0.4)  # x6+ - magenta

var _combo_label: Label

func show_combo(combo: int, center: Vector2) -> void:
    if combo < 2:
        queue_free()
        return
    
    position = Vector2.ZERO
    size = get_viewport_rect().size
    mouse_filter = MOUSE_FILTER_IGNORE
    
    var color: Color = COMBO_COLORS.get(combo, DEFAULT_COLOR)
    
    _combo_label = Label.new()
    _combo_label.text = "x%d COMBO" % combo
    _combo_label.add_theme_font_size_override("font_size", 48 if combo >= 5 else 42)
    _combo_label.add_theme_color_override("font_color", color)
    _combo_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2, 0.95))
    _combo_label.add_theme_constant_override("outline_size", 6)
    _combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _combo_label.position = Vector2(0, center.y - 30)
    _combo_label.size = Vector2(size.x, 60)
    _combo_label.pivot_offset = Vector2(size.x / 2.0, 30)
    add_child(_combo_label)
    
    var tw := create_tween()
    _combo_label.scale = Vector2(0.5, 0.5)
    _combo_label.modulate.a = 0.0
    tw.tween_property(_combo_label, "scale", Vector2(1.15, 1.15), 0.12).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(_combo_label, "modulate:a", 1.0, 0.08)
    tw.tween_property(_combo_label, "scale", Vector2.ONE, 0.08)
    tw.tween_interval(0.35)
    tw.tween_property(_combo_label, "modulate:a", 0.0, 0.15)
    tw.tween_callback(queue_free)
