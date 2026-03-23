extends Control
## Rising colored particle effect for game over screen (D2)

var particles: Array = []

func _draw() -> void:
	for p in particles:
		var c: Color = p["color"]
		c.a = float(p["alpha"])
		var s: float = float(p["size"])
		var cx: float = float(p["x"])
		var cy: float = float(p["y"])
		# Draw soft circle instead of rectangle for D2
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		var segments := 8
		for i in range(segments + 1):
			var angle: float = TAU * i / segments
			points.append(Vector2(cx + cos(angle) * s * 0.5, cy + sin(angle) * s * 0.5))
			colors.append(c)
		if points.size() >= 3:
			draw_polygon(points, colors)
