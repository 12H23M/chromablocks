extends Control
## Lightweight particle burst effect for line clears.
## Spawns small colored squares that scatter outward with gravity and fade.

var _particles: Array = []  # Array of particle dictionaries
var _elapsed: float = 0.0
const LIFETIME := 0.7
const GRAVITY := 600.0
const FADE_START := 0.3  # particles start fading after this ratio of lifetime

func emit_at(cell_positions: Array, cell_size: float, colors: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in cell_positions.size():
		var cell_pos: Vector2 = cell_positions[i]
		var color: Color = colors[i] if i < colors.size() else Color.WHITE
		var center := cell_pos + Vector2(cell_size / 2.0, cell_size / 2.0)

		# 4-6 particles per cell
		var count := rng.randi_range(4, 6)
		for _j in count:
			var angle := rng.randf() * TAU
			var speed := rng.randf_range(120.0, 350.0)
			var particle_size := rng.randf_range(2.5, 5.5)

			# Vary color brightness
			var brightness := rng.randf_range(0.7, 1.0)
			var c := color.lightened(rng.randf_range(0.0, 0.4))
			c.a = brightness

			_particles.append({
				"pos": center + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)),
				"vel": Vector2(cos(angle) * speed, sin(angle) * speed - rng.randf_range(50, 150)),
				"color": c,
				"size": particle_size,
				"life": LIFETIME + rng.randf_range(-0.15, 0.15),
				"age": 0.0,
				"rotation": rng.randf() * TAU,
				"rot_speed": rng.randf_range(-8.0, 8.0),
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
		p["vel"].y += GRAVITY * delta
		p["pos"] += p["vel"] * delta
		p["rotation"] += p["rot_speed"] * delta

		# Slow down horizontally
		p["vel"].x *= 0.98

		# Shrink over time
		var life_ratio: float = p["age"] / p["life"]
		if life_ratio > FADE_START:
			var fade_ratio := (life_ratio - FADE_START) / (1.0 - FADE_START)
			p["color"].a = lerpf(p["color"].a, 0.0, fade_ratio * 0.08)
			p["size"] = maxf(0.5, p["size"] - delta * 4.0)

	queue_redraw()

	if not alive:
		queue_free()


func _draw() -> void:
	for p in _particles:
		if p["age"] >= p["life"]:
			continue
		var s: float = p["size"]
		var rect := Rect2(-s / 2.0, -s / 2.0, s, s)

		draw_set_transform(p["pos"], p["rotation"], Vector2.ONE)
		draw_rect(rect, p["color"])

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
