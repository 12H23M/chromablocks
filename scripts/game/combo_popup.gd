extends Control
## Clean combo popup — only shown for x2+.
## Uses wall-clock timing to work during hit-stop.

var _combo: int = 0
var _center: Vector2 = Vector2.ZERO
var _start_msec: int = 0
var _combo_label: Label

const POP_DURATION := 0.12
const HOLD_DURATION := 0.45
const FADE_DURATION := 0.25
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_combo(combo: int, center_pos: Vector2) -> void:
	_combo = combo
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Load font
	var font: Font = load("res://assets/fonts/Fredoka-Bold.ttf") as Font

	# Color by combo level
	var combo_color: Color
	var font_size: int
	if combo >= 5:
		combo_color = Color("FF3366")
		font_size = 44
	elif combo >= 4:
		combo_color = Color("FF6B35")
		font_size = 40
	elif combo >= 3:
		combo_color = Color("FFD700")
		font_size = 36
	else:
		combo_color = Color("60A5FA")
		font_size = 32

	_combo_label = Label.new()
	_combo_label.text = "x%d COMBO" % combo
	_combo_label.add_theme_font_size_override("font_size", font_size)
	_combo_label.add_theme_color_override("font_color", combo_color)
	_combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_combo_label.add_theme_constant_override("outline_size", clampi(font_size / 5, 4, 9))
	_combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	_combo_label.add_theme_constant_override("shadow_offset_x", 0)
	_combo_label.add_theme_constant_override("shadow_offset_y", 2)
	if font:
		_combo_label.add_theme_font_override("font", font)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.position = Vector2(0, _center.y - 20)
	_combo_label.size = Vector2(size.x, font_size + 16.0)
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label.pivot_offset = Vector2(size.x / 2.0, (font_size + 16.0) / 2.0)
	_combo_label.scale = Vector2.ZERO
	_combo_label.modulate.a = 0.0
	add_child(_combo_label)

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

	# Pop in
	if elapsed < POP_DURATION:
		var t := elapsed / POP_DURATION
		scale_val = lerp(0.3, 1.1, t)
		alpha = t
	# Settle
	elif elapsed < POP_DURATION + 0.06:
		var t := (elapsed - POP_DURATION) / 0.06
		scale_val = lerp(1.1, 1.0, t)
		alpha = 1.0
	# Hold
	elif elapsed < POP_DURATION + HOLD_DURATION:
		scale_val = 1.0
		alpha = 1.0
	# Fade + slide up
	else:
		var t := (elapsed - POP_DURATION - HOLD_DURATION) / FADE_DURATION
		scale_val = 1.0
		alpha = clampf(1.0 - t, 0.0, 1.0)
		_combo_label.position.y = _center.y - 20 - t * 20.0

	_combo_label.scale = Vector2(scale_val, scale_val)
	_combo_label.modulate.a = alpha
