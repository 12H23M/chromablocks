extends Control
## Falling particle effect for game over screen

var particles: Array = []

func _draw() -> void:
	for p in particles:
		var c: Color = p["color"]
		c.a = float(p["alpha"])
		var s: float = float(p["size"])
		var rect := Rect2(float(p["x"]) - s * 0.5, float(p["y"]) - s * 0.5, s, s)
		draw_rect(rect, c)
