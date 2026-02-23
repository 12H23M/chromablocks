extends Control

var _combo: int = 0
var _center: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _scale_val: float = 0.0
var _alpha: float = 1.0
var _start_msec: int = 0
var _burst_lines: Array = []

# Child labels
var _combo_label: Label
var _mult_label: Label
var _sub_label: Label

const POP_DURATION := 0.15
const HOLD_DURATION := 0.5
const FADE_DURATION := 0.3
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION
const BURST_LINE_COUNT := 12

# Scale factor based on combo level
var _size_scale: float = 1.0
# Per-level visual intensity
var _outline_size: int = 6
var _burst_width: float = 2.0
var _burst_count: int = BURST_LINE_COUNT


func show_combo(combo: int, center_pos: Vector2) -> void:
	_combo = combo
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Size scaling: small combos are subtle, big combos are dramatic
	if combo >= 5:
		_size_scale = 1.8
	elif combo >= 4:
		_size_scale = 1.5
	elif combo >= 3:
		_size_scale = 1.25
	elif combo >= 2:
		_size_scale = 1.0
	else:
		_size_scale = 0.6

	# Per-level outline, burst width, burst count
	if combo >= 5:
		_outline_size = 11
		_burst_width = 5.0
		_burst_count = 16
	elif combo >= 4:
		_outline_size = 9
		_burst_width = 4.0
		_burst_count = 12
	elif combo >= 3:
		_outline_size = 7
		_burst_width = 3.0
		_burst_count = 12
	elif combo >= 2:
		_outline_size = 5
		_burst_width = 2.0
		_burst_count = 12
	else:
		_outline_size = 3
		_burst_width = 1.5
		_burst_count = 12

	# Colors and sub-text
	var combo_color: Color
	var sub_text: String
	var sub_color: Color
	if combo >= 5:
		combo_color = Color("FF3366")
		sub_text = "LEGENDARY!"
		sub_color = Color("FF3366")
	elif combo >= 4:
		combo_color = Color("FF6B35")
		sub_text = "INCREDIBLE!"
		sub_color = Color("FF6B35")
	elif combo >= 3:
		combo_color = Color("FFD700")
		sub_text = "AMAZING!"
		sub_color = Color("FFD700")
	elif combo >= 2:
		combo_color = Color("60A5FA")
		sub_text = "NICE!"
		sub_color = Color("60A5FA")
	else:
		combo_color = Color("60A5FA")
		sub_text = "CLEAR!"
		sub_color = Color("60A5FA")

	# Create text labels as children (guaranteed to render with theme font)
	_combo_label = Label.new()
	_combo_label.text = "COMBO"
	_combo_label.add_theme_font_size_override("font_size", int(52 * _size_scale))
	_combo_label.add_theme_color_override("font_color", Color.WHITE)
	_combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_combo_label.add_theme_constant_override("outline_size", _outline_size)
	_combo_label.add_theme_color_override("font_shadow_color", Color(combo_color.r, combo_color.g, combo_color.b, 0.5))
	_combo_label.add_theme_constant_override("shadow_offset_x", 0)
	_combo_label.add_theme_constant_override("shadow_offset_y", 3)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.anchors_preset = Control.PRESET_FULL_RECT
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combo_label)

	_mult_label = Label.new()
	_mult_label.text = "x%d" % combo
	_mult_label.add_theme_font_size_override("font_size", int(44 * _size_scale))
	_mult_label.add_theme_color_override("font_color", Color("FFD700"))
	_mult_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_mult_label.add_theme_constant_override("outline_size", _outline_size)
	_mult_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.84, 0.0, 0.4))
	_mult_label.add_theme_constant_override("shadow_offset_x", 0)
	_mult_label.add_theme_constant_override("shadow_offset_y", 2)
	_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mult_label.anchors_preset = Control.PRESET_FULL_RECT
	_mult_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mult_label)

	_sub_label = Label.new()
	_sub_label.text = sub_text
	_sub_label.add_theme_font_size_override("font_size", int(24 * _size_scale))
	_sub_label.add_theme_color_override("font_color", sub_color)
	_sub_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_sub_label.add_theme_constant_override("outline_size", _outline_size)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.anchors_preset = Control.PRESET_FULL_RECT
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_label)

	# Position labels around center
	_update_label_positions()

	# Burst lines
	_burst_lines.clear()
	for i in _burst_count:
		_burst_lines.append(float(i) / float(_burst_count) * TAU)

	_elapsed = 0.0
	_scale_val = 0.0
	_alpha = 1.0
	_start_msec = Time.get_ticks_msec()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _update_label_positions() -> void:
	var cy := _center.y
	var s := _size_scale
	# COMBO text centered above board center
	_combo_label.position = Vector2(0, cy - 60 * s)
	_combo_label.size = Vector2(size.x, 60 * s)
	# x2 below COMBO
	_mult_label.position = Vector2(0, cy - 5 * s)
	_mult_label.size = Vector2(size.x, 50 * s)
	# Sub-text below multiplier
	_sub_label.position = Vector2(0, cy + 40 * s)
	_sub_label.size = Vector2(size.x, 35 * s)


func _process(_delta: float) -> void:
	_elapsed = float(Time.get_ticks_msec() - _start_msec) / 1000.0

	if _elapsed >= TOTAL_DURATION:
		queue_free()
		return

	# Phase 1: Pop
	if _elapsed < POP_DURATION:
		var t := _elapsed / POP_DURATION
		if t < 0.7:
			_scale_val = (t / 0.7) * 1.3
		else:
			_scale_val = lerp(1.3, 1.0, (t - 0.7) / 0.3)
		_alpha = 1.0
	# Phase 2: Hold
	elif _elapsed < POP_DURATION + HOLD_DURATION:
		_scale_val = 1.0
		_alpha = 1.0
	# Phase 3: Fade
	else:
		_scale_val = 1.0
		var fade_t := (_elapsed - POP_DURATION - HOLD_DURATION) / FADE_DURATION
		_alpha = clampf(1.0 - fade_t, 0.0, 1.0)

	# Update labels
	var s := maxf(_scale_val, 0.01)
	_combo_label.pivot_offset = _combo_label.size / 2.0
	_combo_label.scale = Vector2(s, s)
	_combo_label.modulate.a = _alpha

	_mult_label.pivot_offset = _mult_label.size / 2.0
	_mult_label.scale = Vector2(s, s)
	_mult_label.modulate.a = _alpha

	_sub_label.pivot_offset = _sub_label.size / 2.0
	_sub_label.scale = Vector2(s * 0.9, s * 0.9)
	_sub_label.modulate.a = _alpha

	queue_redraw()


func _draw() -> void:
	if _combo == 0 or _alpha < 0.01:
		return

	var progress := clampf(_elapsed / TOTAL_DURATION, 0.0, 1.0)
	var center := _center

	# 1. Radial gradient flash (gold)
	var max_radius := 300.0 * _size_scale
	for i in range(8, 0, -1):
		var t := float(i) / 8.0
		var a := 0.15 * (1.0 - t) * _alpha
		if _combo >= 5:
			a *= 1.5
		draw_circle(center, max_radius * t, Color(1.0, 0.84, 0.0, a))

	# 2. Radial burst lines
	var line_inner := 30.0 * _scale_val * _size_scale
	var line_outer := (100.0 + progress * 60.0) * _scale_val * _size_scale
	var line_color := Color(1.0, 0.84, 0.0, 0.5 * _alpha)
	for angle in _burst_lines:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(center + dir * line_inner, center + dir * line_outer, line_color, _burst_width)
		var fade_c := Color(line_color.r, line_color.g, line_color.b, line_color.a * 0.3)
		draw_line(center + dir * line_outer, center + dir * (line_outer + 30.0 * _scale_val * _size_scale), fade_c, maxf(_burst_width * 0.5, 1.0))

	# 3. Secondary ring of burst lines for combo 4+
	if _combo >= 4:
		var ring2_inner := line_outer + 20.0 * _scale_val * _size_scale
		var ring2_outer := ring2_inner + 50.0 * _scale_val * _size_scale
		var ring2_color := Color(line_color.r, line_color.g, line_color.b, line_color.a * 0.6)
		var ring2_offset := TAU / float(_burst_count) / 2.0
		for angle in _burst_lines:
			var dir := Vector2(cos(angle + ring2_offset), sin(angle + ring2_offset))
			draw_line(center + dir * ring2_inner, center + dir * ring2_outer, ring2_color, _burst_width * 0.7)
