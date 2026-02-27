extends Control
## Shows "CHAIN ×N!" popup for chroma chain cascades.
## Uses wall-clock timing to work during hit-stop.

var _cascade: int = 0
var _center: Vector2 = Vector2.ZERO
var _start_msec: int = 0
var _label: Label
var _sub_label: Label

const POP_DURATION := 0.12
const HOLD_DURATION := 0.6
const FADE_DURATION := 0.25
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_chain(cascade: int, center_pos: Vector2) -> void:
	_cascade = cascade
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Color intensity by cascade
	var main_color: Color
	var sub_text: String
	if cascade >= 3:
		main_color = Color("FF6B35")  # orange
		sub_text = "MEGA CHAIN!"
	elif cascade >= 2:
		main_color = Color("FFD700")  # gold
		sub_text = "DOUBLE CHAIN!"
	else:
		main_color = Color("FFA500")  # amber
		sub_text = "CHAIN!"

	var scale_f := 0.9 + cascade * 0.15
	var font: Font = load("res://assets/fonts/Fredoka-Bold.ttf") as Font

	_label = Label.new()
	_label.text = "CHAIN x%d" % cascade
	_label.add_theme_font_size_override("font_size", int(38 * scale_f))
	_label.add_theme_color_override("font_color", main_color)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 7)
	_label.add_theme_color_override("font_shadow_color", Color(main_color.r, main_color.g, main_color.b, 0.4))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	if font:
		_label.add_theme_font_override("font", font)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0, _center.y - 25 * scale_f)
	_label.size = Vector2(size.x, 50 * scale_f)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_sub_label = Label.new()
	_sub_label.text = sub_text
	_sub_label.add_theme_font_size_override("font_size", int(18 * scale_f))
	_sub_label.add_theme_color_override("font_color", Color(main_color, 0.7))
	_sub_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_sub_label.add_theme_constant_override("outline_size", 4)
	if font:
		_sub_label.add_theme_font_override("font", font)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.position = Vector2(0, _center.y + 20 * scale_f)
	_sub_label.size = Vector2(size.x, 26 * scale_f)
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_label)

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
		scale_val = 1.0 + 0.3 * sin(t * PI)
		alpha = 1.0
	elif elapsed < POP_DURATION + HOLD_DURATION:
		scale_val = 1.0
		alpha = 1.0
	else:
		scale_val = 1.0
		alpha = clampf(1.0 - (elapsed - POP_DURATION - HOLD_DURATION) / FADE_DURATION, 0.0, 1.0)

	for child in get_children():
		if child is Label:
			child.pivot_offset = child.size / 2.0
			child.scale = Vector2(scale_val, scale_val)
			child.modulate.a = alpha

	queue_redraw()


func _draw() -> void:
	if _cascade <= 0:
		return
	var elapsed := float(Time.get_ticks_msec() - _start_msec) / 1000.0
	var alpha := clampf(1.0 - elapsed / TOTAL_DURATION, 0.0, 1.0)
	# Burst lines in amber/gold
	var line_count := 8 + _cascade * 4
	var inner := 25.0
	var outer := 80.0 + elapsed * 40.0
	for i in line_count:
		var angle := float(i) / float(line_count) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(_center + dir * inner, _center + dir * outer,
			Color(1.0, 0.7, 0.0, 0.4 * alpha), 2.0)
