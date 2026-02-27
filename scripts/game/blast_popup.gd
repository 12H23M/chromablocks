extends Control
## Shows "BLAST!" popup — clean, contained within screen.
## Uses wall-clock timing to work during hit-stop.

var _blast_color: Color = Color.WHITE
var _center: Vector2 = Vector2.ZERO
var _start_msec: int = 0
var _label: Label
var _count_label: Label

const POP_DURATION := 0.12
const HOLD_DURATION := 0.6
const FADE_DURATION := 0.3
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_blast(blast_color_idx: int, center_pos: Vector2) -> void:
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	var color_map: Array = [
		Color("FF6B6B"),  # CORAL
		Color("FFB347"),  # AMBER
		Color("FFEE58"),  # LEMON
		Color("66FF99"),  # MINT
		Color("64B5F6"),  # SKY
		Color("CE93D8"),  # LAVENDER
	]
	_blast_color = color_map[blast_color_idx % color_map.size()]

	# Load font
	var font: Font = load("res://assets/fonts/Fredoka-Bold.ttf") as Font

	_label = Label.new()
	_label.text = "BLAST!"
	_label.add_theme_font_size_override("font_size", 40)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(_blast_color.r * 0.3, _blast_color.g * 0.3, _blast_color.b * 0.3, 0.95))
	_label.add_theme_constant_override("outline_size", 8)
	_label.add_theme_color_override("font_shadow_color", Color(_blast_color.r, _blast_color.g, _blast_color.b, 0.5))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 3)
	if font:
		_label.add_theme_font_override("font", font)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0, _center.y - 25)
	_label.size = Vector2(size.x, 55)
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
		scale_val = lerp(0.5, 1.15, t)
		alpha = 1.0
	elif elapsed < POP_DURATION + 0.08:
		var t := (elapsed - POP_DURATION) / 0.08
		scale_val = lerp(1.15, 1.0, t)
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

	# Subtle color flash (contained)
	var flash_alpha := 0.0
	if elapsed < 0.2:
		flash_alpha = 0.15 * (1.0 - elapsed / 0.2)
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(_blast_color.r, _blast_color.g, _blast_color.b, flash_alpha))

	# Single expanding ring
	var ring_radius := 40.0 + elapsed * 150.0
	var ring_alpha := alpha * 0.4
	draw_arc(_center, ring_radius, 0, TAU, 48, Color(_blast_color, ring_alpha), 2.5)
