class_name DrawUtils
## Shared drawing helpers for bubble-style UI elements


## Draw a rounded rectangle using polygon approximation
static func draw_rounded_rect(canvas: CanvasItem, rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.2) -> void:
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


## Draw a complete Polished Gem / Soft 3D block
static func draw_bubble_block(canvas: CanvasItem, rect: Rect2, base_color: Color, shadow_strength: float = 0.15, shadow_offset_y: float = 2.0) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return

	var w: float = rect.size.x
	var h: float = rect.size.y
	var radius_ratio := 0.2  # Polished gem: slightly less round than bubble

	# 1. Soft drop shadow — same color, inside block rect only (no bleed!)
	var shadow_inset := 2.0
	var shadow_rect := Rect2(
		Vector2(rect.position.x + shadow_inset, rect.position.y + shadow_inset + 2.0),
		Vector2(w - shadow_inset * 2.0, h - shadow_inset * 2.0))
	var shadow_color := Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.30)
	draw_rounded_rect(canvas, shadow_rect, shadow_color, true, 1.0, radius_ratio)

	# 2. Base color rounded rect
	draw_rounded_rect(canvas, rect, base_color, true, 1.0, radius_ratio)

	# 3. Top-to-bottom micro gradient — top 40% lightened
	var grad_h := h * 0.4
	var grad_rect := Rect2(rect.position, Vector2(w, grad_h))
	var grad_color := Color(base_color.r * 1.1, base_color.g * 1.1, base_color.b * 1.1, 0.15)
	draw_rounded_rect(canvas, grad_rect, grad_color, true, 1.0, radius_ratio)

	# 4. Specular highlight — upper-left, slightly smaller than bubble style
	var highlight_cx: float = rect.position.x + w * 0.32
	var highlight_cy: float = rect.position.y + h * 0.28
	var highlight_r: float = w * 0.18
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r, Color(1.0, 1.0, 1.0, 0.28))
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r * 0.55, Color(1.0, 1.0, 1.0, 0.20))
	canvas.draw_circle(Vector2(highlight_cx, highlight_cy), highlight_r * 0.2, Color(1.0, 1.0, 1.0, 0.35))

	# 5. Prism light stripe — horizontal band at top, white alpha 0.12
	var stripe_rect := Rect2(
		rect.position + Vector2(3.0, 2.0),
		Vector2(w - 6.0, h * 0.18))
	draw_rounded_rect(canvas, stripe_rect, Color(1.0, 1.0, 1.0, 0.12), true, 1.0, 0.3)

	# 6. Bottom 30% darkened — black alpha 0.15 for depth
	var bottom_h := h * 0.30
	var bottom_rect := Rect2(
		Vector2(rect.position.x, rect.position.y + h - bottom_h),
		Vector2(w, bottom_h))
	draw_rounded_rect(canvas, bottom_rect, Color(0.0, 0.0, 0.0, 0.15), true, 1.0, radius_ratio)

	# 7. Rim light — ultra-subtle white outline, alpha 0.06
	draw_rounded_rect(canvas, rect, Color(1.0, 1.0, 1.0, 0.06), false, 1.0, radius_ratio)
