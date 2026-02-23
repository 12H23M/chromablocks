extends Control

var _lines: int = 0
var _center: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _scale_val: float = 0.0
var _alpha: float = 1.0
var _start_msec: int = 0

var _main_label: Label
var _bonus_label: Label

const POP_DURATION := 0.15
const HOLD_DURATION := 0.6
const FADE_DURATION := 0.3
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_multi_clear(lines: int, center_pos: Vector2) -> void:
	_lines = lines
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Text, color, font size by line count
	var main_text: String
	var main_color: Color
	var font_size: int
	if lines >= 4:
		main_text = "QUAD!"
		main_color = Color("FFD700")
		font_size = 64
	elif lines >= 3:
		main_text = "TRIPLE!"
		main_color = Color("FF00FF")
		font_size = 52
	else:
		main_text = "DOUBLE!"
		main_color = Color("00E5FF")
		font_size = 40

	# Score bonus from GameConstants
	var bonus: int = GameConstants.line_clear_score(lines)

	# Main label
	_main_label = Label.new()
	_main_label.text = main_text
	_main_label.add_theme_font_size_override("font_size", font_size)
	_main_label.add_theme_color_override("font_color", main_color)
	_main_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_main_label.add_theme_constant_override("outline_size", 6)
	_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_label.anchors_preset = Control.PRESET_FULL_RECT
	_main_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_main_label)

	# Bonus score label
	_bonus_label = Label.new()
	_bonus_label.text = "+%d" % bonus
	_bonus_label.add_theme_font_size_override("font_size", 24)
	_bonus_label.add_theme_color_override("font_color", Color(main_color.r, main_color.g, main_color.b, 0.8))
	_bonus_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_bonus_label.add_theme_constant_override("outline_size", 4)
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus_label.anchors_preset = Control.PRESET_FULL_RECT
	_bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bonus_label)

	_update_label_positions()

	_elapsed = 0.0
	_scale_val = 0.0
	_alpha = 1.0
	_start_msec = Time.get_ticks_msec()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _update_label_positions() -> void:
	var cy := _center.y - 100.0
	_main_label.position = Vector2(0, cy - 30)
	_main_label.size = Vector2(size.x, 60)
	_bonus_label.position = Vector2(0, cy + 25)
	_bonus_label.size = Vector2(size.x, 35)


func _process(_delta: float) -> void:
	_elapsed = float(Time.get_ticks_msec() - _start_msec) / 1000.0

	if _elapsed >= TOTAL_DURATION:
		queue_free()
		return

	# Phase 1: Pop (scale overshoot 1.3 -> 1.0)
	if _elapsed < POP_DURATION:
		var t := _elapsed / POP_DURATION
		if t < 0.6:
			_scale_val = (t / 0.6) * 1.3
		else:
			_scale_val = lerp(1.3, 1.0, (t - 0.6) / 0.4)
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

	var s := maxf(_scale_val, 0.01)
	_main_label.pivot_offset = _main_label.size / 2.0
	_main_label.scale = Vector2(s, s)
	_main_label.modulate.a = _alpha

	_bonus_label.pivot_offset = _bonus_label.size / 2.0
	_bonus_label.scale = Vector2(s * 0.9, s * 0.9)
	_bonus_label.modulate.a = _alpha
