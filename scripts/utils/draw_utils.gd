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
static func draw_bubble_block(canvas: CanvasItem, rect: Rect2, base_color: Color, shadow_strength: float = 0.15, shadow_offset_y: float = 2.0) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return

	var cx: float = rect.position.x + rect.size.x / 2.0
	var cy: float = rect.position.y + rect.size.y / 2.0
	var w: float = rect.size.x
	var h: float = rect.size.y

	# Shadow fully inside block rect (no bleed)
	# Instead of offset shadow, darken the bottom portion of the block area
	var shadow_h := rect.size.y * 0.3
	var shadow_rect := Rect2(
		Vector2(rect.position.x + 1.0, rect.position.y + rect.size.y - shadow_h),
		Vector2(rect.size.x - 2.0, shadow_h))
	draw_rounded_rect(canvas, shadow_rect, Color(0.0, 0.0, 0.0, shadow_strength * 0.7))

	# Base — slightly brighter center for depth
	draw_rounded_rect(canvas, rect, base_color)

	# Bottom darkening (3D depth) — darker, rounder feel
	var dark_color := Color(base_color.r * 0.6, base_color.g * 0.6, base_color.b * 0.6, 0.35)
	var bottom_h := h * 0.45
	var bottom_rect := Rect2(
		Vector2(rect.position.x, rect.position.y + h - bottom_h),
		Vector2(w, bottom_h))
	draw_rounded_rect(canvas, bottom_rect, dark_color, true, 1.0, 0.35)

	# Water drop highlight — circular white glow in upper-left
	var highlight_cx: float = rect.position.x + w * 0.35
	var highlight_cy: float = rect.position.y + h * 0.30
	var highlight_r: float = w * 0.22
	# Radial gradient simulation (3 circles)
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r, Color(1.0, 1.0, 1.0, 0.35))
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r * 0.6, Color(1.0, 1.0, 1.0, 0.25))
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r * 0.25, Color(1.0, 1.0, 1.0, 0.4))

	# Top shine band — curved feel
	var shine_rect := Rect2(
		rect.position + Vector2(4.0, 2.0),
		Vector2(w - 8.0, h * 0.22))
	draw_rounded_rect(canvas, shine_rect, Color(1.0, 1.0, 1.0, 0.15), true, 1.0, 0.3)

	# Rim light (subtle border glow)
	draw_rounded_rect(canvas, rect, Color(1.0, 1.0, 1.0, 0.08), false)
