extends Control
## Spectacular particle burst effect for line clears.
## Enhanced with multiple shapes, sparkles, afterglow trails, and secondary bursts.

class Particle:
	var pos: Vector2
	var prev_pos: Vector2
	var vel: Vector2
	var color: Color
	var size: float
	var life: float
	var age: float
	var rotation: float
	var rot_speed: float
	var shape: int

var _particles: Array = []
var _elapsed: float = 0.0
var _pending_bursts: Array = []  # Delayed secondary bursts
const MAX_PARTICLES := 48
const LIFETIME := 1.0
const GRAVITY := 240.0
const FADE_START := 0.4

## Shape types for visual variety
enum Shape { RECT, DIAMOND, CIRCLE, STAR, SPARK }

# Unit polygons — drawn via transform scale, no per-frame allocation
var _DIAMOND_POLY := PackedVector2Array([
	Vector2(0.0, -0.5), Vector2(0.5, 0.0),
	Vector2(0.0, 0.5), Vector2(-0.5, 0.0),
])

# Pre-computed 4-point star polygon
var _STAR_POLY := PackedVector2Array([
	Vector2(0.0, -0.5), Vector2(0.15, -0.15),
	Vector2(0.5, 0.0), Vector2(0.15, 0.15),
	Vector2(0.0, 0.5), Vector2(-0.15, 0.15),
	Vector2(-0.5, 0.0), Vector2(-0.15, -0.15),
])

# Screen flash overlay state
var _flash_alpha := 0.0
var _flash_color := Color.WHITE


func _make_particle(center: Vector2, vel: Vector2, color: Color, size: float,
		life: float, rotation: float, rot_speed: float, shape: int) -> Particle:
	var p := Particle.new()
	p.pos = center
	p.prev_pos = center
	p.vel = vel
	p.color = color
	p.size = size
	p.life = life
	p.age = 0.0
	p.rotation = rotation
	p.rot_speed = rot_speed
	p.shape = shape
	return p


func emit_at(cell_positions: Array, cell_size: float, colors: Array, intensity: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Scale max particles by intensity (1.0 = 32, 1.5 = 48, 2.0 = 64)
	var max_particles := int(MAX_PARTICLES * intensity * 1.2)

	# Evenly sample cells if too many
	var step := maxi(1, ceili(float(cell_positions.size()) / float(max_particles)))

	for i in range(0, cell_positions.size(), step):
		if _particles.size() >= max_particles:
			break

		var cell_pos: Vector2 = cell_positions[i]
		var color: Color = colors[i] if i < colors.size() else Color.WHITE
		var center := cell_pos + Vector2(cell_size / 2.0, cell_size / 2.0)

		# Main burst particles (2 per cell for density)
		for burst_idx in 2:
			if _particles.size() >= max_particles:
				break
			var angle := rng.randf() * TAU
			# Scale speed by intensity — faster and wider spread
			var speed := rng.randf_range(220.0, 520.0) * lerpf(1.0, 1.5, (intensity - 1.0))
			# Size variety: 12% large, 18% small sparkle, 10% star, 60% normal
			var size_roll := rng.randf()
			var particle_size: float
			var shape: int
			if size_roll < 0.12:
				particle_size = rng.randf_range(16.0, 24.0) * intensity
				shape = Shape.STAR if rng.randf() < 0.5 else Shape.DIAMOND
			elif size_roll < 0.30:
				particle_size = rng.randf_range(2.0, 5.0) * intensity
				shape = Shape.SPARK
			elif size_roll < 0.40:
				particle_size = rng.randf_range(8.0, 14.0) * intensity
				shape = Shape.STAR
			else:
				particle_size = rng.randf_range(6.0, 13.0) * intensity
				# Shape variety: 40% rect, 25% diamond, 20% circle, 15% star
				var shape_roll := rng.randf()
				if shape_roll < 0.40:
					shape = Shape.RECT
				elif shape_roll < 0.65:
					shape = Shape.DIAMOND
				elif shape_roll < 0.85:
					shape = Shape.CIRCLE
				else:
					shape = Shape.STAR

			# Lighten colors more at higher intensity for brighter feel
			var lighten_amount := rng.randf_range(0.05, 0.4) + (intensity - 1.0) * 0.2
			var c := color.lightened(clampf(lighten_amount, 0.0, 0.7))
			c.a = rng.randf_range(0.85, 1.0)

			_particles.append(_make_particle(
				center + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)),
				Vector2(cos(angle) * speed, sin(angle) * speed - rng.randf_range(60, 160)),
				c, particle_size,
				LIFETIME + rng.randf_range(-0.15, 0.15),
				rng.randf() * TAU, rng.randf_range(-8.0, 8.0), shape,
			))

		# White sparkle particles (15% chance per cell) for extra brilliance
		if rng.randf() < 0.15 + intensity * 0.1 and _particles.size() < max_particles:
			var spark_angle := rng.randf() * TAU
			var spark_speed := rng.randf_range(140.0, 320.0) * intensity
			_particles.append(_make_particle(
				center,
				Vector2(cos(spark_angle) * spark_speed, sin(spark_angle) * spark_speed - 80.0),
				Color(1.0, 1.0, 1.0, 0.95), rng.randf_range(3.0, 7.0),
				0.5 + rng.randf_range(0.0, 0.3),
				rng.randf() * TAU, rng.randf_range(-12.0, 12.0), Shape.SPARK,
			))

	# Schedule a secondary burst for intense clears (delayed mini-explosion)
	if intensity >= 1.5:
		_pending_bursts.append({
			"positions": cell_positions.duplicate(),
			"colors": colors.duplicate(),
			"cell_size": cell_size,
			"intensity": intensity * 0.5,
			"delay": 0.12,
			"age": 0.0,
		})

	# Trigger screen flash for intense clears
	if intensity >= 1.5:
		var avg_color: Color = colors[0] if colors.size() > 0 else Color.WHITE
		_flash_color = Color(avg_color.r, avg_color.g, avg_color.b, 1.0).lightened(0.5)
		_flash_alpha = clampf(0.15 + (intensity - 1.0) * 0.12, 0.0, 0.35)

	set_process(true)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	var alive := false

	# Process pending secondary bursts
	var completed_bursts: Array = []
	for burst in _pending_bursts:
		burst["age"] += delta
		if burst["age"] >= burst["delay"]:
			_emit_secondary_burst(burst)
			completed_bursts.append(burst)
	for b in completed_bursts:
		_pending_bursts.erase(b)

	if not _pending_bursts.is_empty():
		alive = true

	# Fade screen flash
	if _flash_alpha > 0.001:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 1.5)
		alive = true

	for p in _particles:
		p.age += delta
		if p.age >= p.life:
			continue
		alive = true

		# Physics
		p.prev_pos = p.pos
		var gravity_mult: float = 0.4 if p.shape == Shape.SPARK else 1.0
		p.vel.y += GRAVITY * gravity_mult * delta
		p.pos += p.vel * delta
		p.rotation += p.rot_speed * delta

		# Slow down horizontally
		p.vel.x *= 0.95

		# Shrink over time
		var life_ratio: float = p.age / p.life
		if life_ratio > FADE_START:
			var fade_ratio := (life_ratio - FADE_START) / (1.0 - FADE_START)
			p.color.a = lerpf(p.color.a, 0.0, fade_ratio * 0.15)
			var shrink_rate: float = 8.0 if p.shape == Shape.SPARK else 5.0
			p.size = maxf(0.3, p.size - delta * shrink_rate)

	queue_redraw()

	if not alive:
		queue_free()


func _emit_secondary_burst(burst: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var positions: Array = burst["positions"]
	var colors: Array = burst["colors"]
	var cell_size: float = burst["cell_size"]
	var inten: float = burst["intensity"]
	if positions.is_empty():
		return
	var count := mini(positions.size(), 8)
	var step := maxi(1, positions.size() / count)
	var shape_options: Array = [Shape.DIAMOND, Shape.STAR, Shape.CIRCLE]

	for i in range(0, positions.size(), step):
		var cell_pos: Vector2 = positions[i]
		var color: Color = colors[i] if i < colors.size() else Color.WHITE
		var center := cell_pos + Vector2(cell_size / 2.0, cell_size / 2.0)
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(80.0, 250.0) * inten
		var c := color.lightened(0.3)
		c.a = 0.9
		var shape_idx: int = rng.randi_range(0, 2)
		_particles.append(_make_particle(
			center,
			Vector2(cos(angle) * speed, sin(angle) * speed - 60.0),
			c, rng.randf_range(4.0, 10.0),
			0.6, rng.randf() * TAU, rng.randf_range(-6.0, 6.0),
			shape_options[shape_idx],
		))


func _draw() -> void:
	# Screen flash overlay
	if _flash_alpha > 0.001:
		var flash := Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha)
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), flash)

	for p in _particles:
		if p.age >= p.life:
			continue
		var s: float = p.size
		if s < 0.5:
			continue

		# Afterglow trail (ghost at previous position) — longer for sparks
		var trail_mult: float = 0.5 if p.shape == Shape.SPARK else 0.3
		var trail_alpha: float = p.color.a * trail_mult
		if trail_alpha > 0.01:
			var trail_color := Color(p.color.r, p.color.g, p.color.b, trail_alpha)
			var trail_s: float = s * (1.5 if p.shape == Shape.SPARK else 1.3)
			draw_set_transform(p.prev_pos, p.rotation, Vector2(trail_s, trail_s))
			_draw_particle_shape(p.shape, trail_color)

		draw_set_transform(p.pos, p.rotation, Vector2(s, s))
		_draw_particle_shape(p.shape, p.color)

		# Glow halo for larger particles
		if s > 10.0:
			var glow_alpha: float = p.color.a * 0.2
			var glow_color := Color(p.color.r, p.color.g, p.color.b, glow_alpha)
			draw_circle(Vector2.ZERO, 0.8, glow_color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draw a single particle shape at the current transform (size baked into scale).
func _draw_particle_shape(shape: int, color: Color) -> void:
	if color.a < 0.01:
		return
	match shape:
		Shape.RECT:
			draw_rect(Rect2(-0.5, -0.5, 1.0, 1.0), color)
		Shape.DIAMOND:
			draw_colored_polygon(_DIAMOND_POLY, color)
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, 0.5, color)
		Shape.STAR:
			draw_colored_polygon(_STAR_POLY, color)
		Shape.SPARK:
			# Tiny bright cross shape
			draw_rect(Rect2(-0.5, -0.1, 1.0, 0.2), color)
			draw_rect(Rect2(-0.1, -0.5, 0.2, 1.0), color)
