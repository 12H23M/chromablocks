extends Control
## Shows "CHROMA BLAST!" popup — dramatic full-screen effect.
## Uses wall-clock timing to work during hit-stop.

var _blast_color: Color = Color.WHITE
var _center: Vector2 = Vector2.ZERO
var _start_msec: int = 0
var _label: Label

const POP_DURATION := 0.15
const HOLD_DURATION := 0.8
const FADE_DURATION := 0.4
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_blast(blast_color_idx: int, center_pos: Vector2) -> void:
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Map color index to display color
	var color_map: Array = [
		Color("FF6B6B"),  # CORAL
		Color("FFB347"),  # AMBER
		Color("FFEE58"),  # LEMON
		Color("66FF99"),  # MINT
		Color("64B5F6"),  # SKY
		Color("CE93D8"),  # LAVENDER
	]
	_blast_color = color_map[blast_color_idx % color_map.size()]

	_label = Label.new()
	_label.text = "CHROMA BLAST!"
	_label.add_theme_font_size_override("font_size", 56)
	_label.add_theme_color_override("font_color", _blast_color)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_label.add_theme_constant_override("outline_size", 12)
	_label.add_theme_color_override("font_shadow_color", Color(_blast_color.r, _blast_color.g, _blast_color.b, 0.6))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0, _center.y - 30)
	_label.size = Vector2(size.x, 65)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_start_msec = Time.get_ticks_msec()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	var elapsed := float(Time.get_ticks_msec() - _start_msec) / 1000.0
	if elapsed >= TOTAL_DURATION:
		queue_free()
		return

	var scale_val: float
	var alpha: float

	if elapsed < POP_DURATION:
		var t := elapsed / POP_DURATION
		scale_val = 0.3 + t * 1.4  # 0.3 → 1.7 overshoot
		alpha = 1.0
	elif elapsed < POP_DURATION + 0.1:
		# Settle from overshoot
		var t := (elapsed - POP_DURATION) / 0.1
		scale_val = lerp(1.7, 1.0, t)
		alpha = 1.0
	elif elapsed < POP_DURATION + HOLD_DURATION:
		scale_val = 1.0
		alpha = 1.0
	else:
		scale_val = 1.0
		alpha = clampf(1.0 - (elapsed - POP_DURATION - HOLD_DURATION) / FADE_DURATION, 0.0, 1.0)

	_label.pivot_offset = _label.size / 2.0
	_label.scale = Vector2(scale_val, scale_val)
	_label.modulate.a = alpha

	queue_redraw()


func _draw() -> void:
	var elapsed := float(Time.get_ticks_msec() - _start_msec) / 1000.0
	var alpha := clampf(1.0 - elapsed / TOTAL_DURATION, 0.0, 1.0)

	if alpha < 0.01:
		return

	# Full-screen color flash
	var flash_alpha := 0.0
	if elapsed < 0.3:
		flash_alpha = 0.25 * (1.0 - elapsed / 0.3)
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(_blast_color.r, _blast_color.g, _blast_color.b, flash_alpha))

	# Expanding ring
	var ring_radius := 50.0 + elapsed * 200.0
	var ring_alpha := alpha * 0.6
	draw_arc(_center, ring_radius, 0, TAU, 64, Color(_blast_color, ring_alpha), 3.0)
	if ring_radius > 80:
		draw_arc(_center, ring_radius - 30, 0, TAU, 48, Color(_blast_color, ring_alpha * 0.4), 2.0)

	# Radial burst (thick lines)
	var burst_count := 16
	for i in burst_count:
		var angle := float(i) / float(burst_count) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var inner := 30.0 + elapsed * 50.0
		var outer := inner + 60.0 + elapsed * 80.0
		draw_line(_center + dir * inner, _center + dir * outer,
			Color(_blast_color, 0.5 * alpha), 3.0)
