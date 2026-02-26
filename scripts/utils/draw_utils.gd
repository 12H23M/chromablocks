class_name DrawUtils
## Shared drawing helpers for bubble-style UI elements


## Draw a rounded rectangle using polygon approximation
static func draw_rounded_rect(canvas: CanvasItem, rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.35) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0 or color.a < 0.005:
		return
	var r := minf(minf(rect.size.x, rect.size.y) * radius_ratio, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var segments := 8

	var corners := [
		[rect.position.x + r, rect.position.y + r, PI],                          # top-left
		[rect.position.x + rect.size.x - r, rect.position.y + r, -PI / 2.0],    # top-right
		[rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r, 0.0],  # bottom-right
		[rect.position.x + r, rect.position.y + rect.size.y - r, PI / 2.0],     # bottom-left
	]

	for corner in corners:
		var cx: float = corner[0]
		var cy: float = corner[1]
		var base_angle: float = corner[2]
		for i in range(segments + 1):
			var angle := base_angle + float(i) / segments * (PI / 2.0)
			points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))

	if filled:
		canvas.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		canvas.draw_polyline(points, color, line_width, true)


## Draw an ellipse (for specular highlight dots)
static func draw_ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color, segments: int = 12) -> void:
	if radius.x < 0.5 or radius.y < 0.5 or color.a < 0.005:
		return
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := float(i) / segments * TAU
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	canvas.draw_colored_polygon(points, color)


## Draw a complete bubble-style block
static func draw_bubble_block(canvas: CanvasItem, rect: Rect2, base_color: Color, shadow_strength: float = 0.12, shadow_offset_y: float = 2.0) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return

	# Shadow
	var shadow_rect := Rect2(rect.position + Vector2(0, shadow_offset_y), rect.size)
	draw_rounded_rect(canvas, shadow_rect, Color(0.0, 0.0, 0.0, shadow_strength))

	# Base
	draw_rounded_rect(canvas, rect, base_color)

	# Bottom darkening (3D depth)
	var dark_color := Color(base_color.r * 0.75, base_color.g * 0.75, base_color.b * 0.75, 0.3)
	var bottom_h := rect.size.y * 0.4
	var bottom_rect := Rect2(
		Vector2(rect.position.x, rect.position.y + rect.size.y - bottom_h),
		Vector2(rect.size.x, bottom_h))
	draw_rounded_rect(canvas, bottom_rect, dark_color, true, 1.0, 0.3)

	# Top shine — subtle horizontal band (top 30%, full width minus 3px padding)
	var shine_rect := Rect2(
		rect.position + Vector2(3.0, 0.0),
		Vector2(rect.size.x - 6.0, rect.size.y * 0.30))
	draw_rounded_rect(canvas, shine_rect, Color(1.0, 1.0, 1.0, 0.20), true, 1.0, 0.3)

	# Rim light
	draw_rounded_rect(canvas, rect, Color(1.0, 1.0, 1.0, 0.05), false)
