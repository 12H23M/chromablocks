extends Control
## Lightweight particle burst effect for line clears.
## Optimized: max 16 particles, larger size for better visibility on low-end mobile.

var _particles: Array = []
var _elapsed: float = 0.0
const MAX_PARTICLES := 24
const LIFETIME := 0.75
const GRAVITY := 280.0
const FADE_START := 0.35

## Shape types for visual variety
enum Shape { RECT, DIAMOND, CIRCLE }

# Pre-computed unit diamond polygon (rotated square), scaled at draw time
var _DIAMOND_POLY := PackedVector2Array([
	Vector2(0.0, -0.5), Vector2(0.5, 0.0),
	Vector2(0.0, 0.5), Vector2(-0.5, 0.0),
])

func emit_at(cell_positions: Array, cell_size: float, colors: Array, intensity: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Scale max particles by intensity (1.0 = 16, 1.5 = 24, 2.0 = 32)
	var max_particles := int(MAX_PARTICLES * intensity)

	# Evenly sample cells if too many (keep particle count under scaled max)
	var step := maxi(1, ceili(float(cell_positions.size()) / float(max_particles)))

	for i in range(0, cell_positions.size(), step):
		if _particles.size() >= max_particles:
			break

		var cell_pos: Vector2 = cell_positions[i]
		var color: Color = colors[i] if i < colors.size() else Color.WHITE
		var center := cell_pos + Vector2(cell_size / 2.0, cell_size / 2.0)

		var angle := rng.randf() * TAU
		# Scale speed by intensity
		var speed := rng.randf_range(150.0, 400.0) * lerpf(1.0, 1.3, (intensity - 1.0))
		# Size variety: 10% large, 20% small sparkle, 70% normal
		var size_roll := rng.randf()
		var particle_size: float
		if size_roll < 0.1:
			particle_size = rng.randf_range(14.0, 20.0) * intensity
		elif size_roll < 0.3:
			particle_size = rng.randf_range(2.0, 4.0) * intensity
		else:
			particle_size = rng.randf_range(6.0, 12.0) * intensity

		# Lighten colors more at higher intensity
		var lighten_amount := rng.randf_range(0.0, 0.3) + (intensity - 1.0) * 0.15
		var c := color.lightened(clampf(lighten_amount, 0.0, 0.6))
		c.a = rng.randf_range(0.8, 1.0)

		# Shape variety: 60% rectangle, 25% diamond, 15% circle
		var shape_roll := rng.randf()
		var shape: int
		if shape_roll < 0.60:
			shape = Shape.RECT
		elif shape_roll < 0.85:
			shape = Shape.DIAMOND
		else:
			shape = Shape.CIRCLE

		_particles.append({
			"pos": center + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)),
			"prev_pos": center,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - rng.randf_range(40, 120)),
			"color": c,
			"size": particle_size,
			"life": LIFETIME + rng.randf_range(-0.1, 0.1),
			"age": 0.0,
			"rotation": rng.randf() * TAU,
			"rot_speed": rng.randf_range(-6.0, 6.0),
			"shape": shape,
		})

	set_process(true)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	var alive := false

	for p in _particles:
		p["age"] += delta
		if p["age"] >= p["life"]:
			continue
		alive = true

		# Physics
		p["prev_pos"] = p["pos"]
		p["vel"].y += GRAVITY * delta
		p["pos"] += p["vel"] * delta
		p["rotation"] += p["rot_speed"] * delta

		# Slow down horizontally
		p["vel"].x *= 0.96

		# Shrink over time
		var life_ratio: float = p["age"] / p["life"]
		if life_ratio > FADE_START:
			var fade_ratio := (life_ratio - FADE_START) / (1.0 - FADE_START)
			p["color"].a = lerpf(p["color"].a, 0.0, fade_ratio * 0.12)
			p["size"] = maxf(0.5, p["size"] - delta * 6.0)

	queue_redraw()

	if not alive:
		queue_free()


func _draw() -> void:
	for p in _particles:
		if p["age"] >= p["life"]:
			continue
		var s: float = p["size"]
		var shape: int = p["shape"]

		# Trail (ghost at previous position)
		var trail_alpha: float = p["color"].a * 0.3
		if trail_alpha > 0.01:
			var trail_color := Color(p["color"].r, p["color"].g, p["color"].b, trail_alpha)
			var trail_s: float = s * 1.3
			draw_set_transform(p["prev_pos"], p["rotation"], Vector2.ONE)
			_draw_particle_shape(shape, trail_s, trail_color)

		draw_set_transform(p["pos"], p["rotation"], Vector2.ONE)
		_draw_particle_shape(shape, s, p["color"])

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draw a single particle in the given shape at the current transform origin.
func _draw_particle_shape(shape: int, size: float, color: Color) -> void:
	match shape:
		Shape.RECT:
			var half := size / 2.0
			draw_rect(Rect2(-half, -half, size, size), color)
		Shape.DIAMOND:
			# Scale the pre-computed unit diamond polygon by size
			var scaled := PackedVector2Array()
			scaled.resize(_DIAMOND_POLY.size())
			for i in _DIAMOND_POLY.size():
				scaled[i] = _DIAMOND_POLY[i] * size
			draw_colored_polygon(scaled, color)
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, size / 2.0, color)
