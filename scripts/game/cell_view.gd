extends Control

var _occupied: bool = false
var _color: int = -1

# Layer colors (set by set_filled / set_empty / set_highlight)
var _glow_color := Color.TRANSPARENT
var _bg_color := Color("EDE7E0")
var _highlight_color := Color.TRANSPARENT
var _border_color := Color("DDD5CC")

# Scale animation for clear effects
var _scale_factor := 1.0
# Cached color for clear-out tween (block-colored instead of white)
var _clear_color := Color.WHITE

func set_empty() -> void:
	_occupied = false
	_color = -1
	_glow_color = Color.TRANSPARENT
	_bg_color = AppColors.EMPTY_CELL
	_highlight_color = Color.TRANSPARENT
	_border_color = AppColors.EMPTY_BORDER
	_scale_factor = 1.0
	queue_redraw()

func set_filled(block_color: int) -> void:
	_occupied = true
	_color = block_color
	var base := AppColors.get_block_color(block_color)
	var light := AppColors.get_block_light_color(block_color)
	var glow := AppColors.get_block_glow_color(block_color)

	_glow_color = glow
	_bg_color = base
	_highlight_color = Color(light.r, light.g, light.b, 0.4)
	_border_color = light
	queue_redraw()

func set_highlight(can_place: bool) -> void:
	_bg_color = AppColors.HIGHLIGHT_VALID if can_place else AppColors.HIGHLIGHT_INVALID
	_glow_color = Color.TRANSPARENT
	_highlight_color = Color.TRANSPARENT
	_border_color = _bg_color
	queue_redraw()

func clear_highlight() -> void:
	if _occupied:
		set_filled(_color)
	else:
		set_empty()

func play_place_pulse(delay: float = 0.0) -> void:
	var original_bg := _bg_color
	var light := AppColors.get_block_light_color(_color) if _color >= 0 else Color.WHITE

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func():
		_bg_color = light
		_scale_factor = 0.85
		queue_redraw()
	)
	tween.tween_property(self, "_scale_factor", 1.12, 0.08) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "_scale_factor", 1.0, 0.07) \
		 .set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(func(t: float):
		_bg_color = light.lerp(original_bg, 1.0 - t)
		queue_redraw()
	, 1.0, 0.0, 0.15)


func play_clear_flash(duration: float, delay: float = 0.0) -> void:
	var bright_color := Color.WHITE
	if _occupied and _color >= 0:
		bright_color = AppColors.get_block_light_color(_color)
	# Cache the block's bright color for the fade-out tween
	_clear_color = bright_color

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	# Phase 1: Bright flash (block color)
	tween.tween_callback(func():
		_bg_color = bright_color
		_glow_color = Color(bright_color.r, bright_color.g, bright_color.b, 1.0)
		_highlight_color = Color(bright_color.r, bright_color.g, bright_color.b, 0.8)
		_border_color = bright_color
		_scale_factor = 1.0
		queue_redraw()
	)

	# Phase 2: Intensified block color pop + scale up
	var peak_color := bright_color.lightened(0.4)
	tween.tween_callback(func():
		_bg_color = peak_color
		_glow_color = Color(peak_color.r, peak_color.g, peak_color.b, 0.9)
		_border_color = peak_color
		queue_redraw()
	).set_delay(0.08)
	tween.tween_property(self, "_scale_factor", 1.3, 0.1) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 3: Hold at peak briefly
	tween.tween_interval(0.06)

	# Phase 4: Shrink + fade out (slower)
	tween.tween_method(_tween_clear_out, 1.0, 0.0, 0.25) \
		 .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		_scale_factor = 1.0
		set_empty()
	)

func play_color_match_flash(duration: float, delay: float = 0.0) -> void:
	var bright := AppColors.get_block_light_color(_color) if _occupied else Color.WHITE

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	tween.tween_callback(func():
		_bg_color = Color.WHITE
		_glow_color = Color(1, 1, 1, 0.7)
		_highlight_color = Color(1, 1, 1, 0.5)
		_border_color = Color.WHITE
		queue_redraw()
	)
	tween.tween_callback(func():
		_bg_color = bright
		_glow_color = Color(bright.r, bright.g, bright.b, 0.6)
		_highlight_color = Color.TRANSPARENT
		_border_color = bright
		queue_redraw()
	).set_delay(0.05)
	tween.tween_method(_tween_to_empty, 1.0, 0.0, duration - 0.05)
	tween.tween_callback(set_empty)

func _tween_clear_out(t: float) -> void:
	# Fade from block color toward empty cell
	_bg_color = _clear_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = 0.9 * t * t
	_highlight_color.a = 0.0
	_border_color = _clear_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	# Shrink scale from current down to 0
	_scale_factor = lerpf(0.0, _scale_factor, t)
	queue_redraw()

## Line prediction overlay
var _line_prediction_active: bool = false
var _line_prediction_overlay := Color(1.0, 1.0, 1.0, 0.30)
var _line_prediction_border := Color(1.0, 1.0, 1.0, 0.50)
var _line_pulse_tween: Tween = null

# Alpha range for the pulse animation
const _LINE_PULSE_ALPHA_MIN := 0.18
const _LINE_PULSE_ALPHA_MAX := 0.42
const _LINE_PULSE_BORDER_MIN := 0.30
const _LINE_PULSE_BORDER_MAX := 0.65
const _LINE_PULSE_DURATION := 0.6

func show_line_prediction() -> void:
	_line_prediction_active = true
	# Use the cell's light color for a thematic highlight, with white fallback
	if _occupied and _color >= 0:
		var light := AppColors.get_block_light_color(_color)
		_line_prediction_overlay = Color(light.r, light.g, light.b, _LINE_PULSE_ALPHA_MAX)
		_line_prediction_border = Color(light.r, light.g, light.b, _LINE_PULSE_BORDER_MAX)
	else:
		_line_prediction_overlay = Color(1.0, 1.0, 1.0, _LINE_PULSE_ALPHA_MAX)
		_line_prediction_border = Color(1.0, 1.0, 1.0, _LINE_PULSE_BORDER_MAX)
	_start_line_pulse()
	queue_redraw()

func clear_line_prediction() -> void:
	if _line_prediction_active:
		_line_prediction_active = false
		_stop_line_pulse()
		queue_redraw()

func _start_line_pulse() -> void:
	_stop_line_pulse()
	_line_pulse_tween = create_tween()
	_line_pulse_tween.set_loops()
	# Fade overlay alpha down then back up in a smooth loop
	_line_pulse_tween.tween_method(_set_line_pulse_alpha, 1.0, 0.0, _LINE_PULSE_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_line_pulse_tween.tween_method(_set_line_pulse_alpha, 0.0, 1.0, _LINE_PULSE_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_line_pulse() -> void:
	if _line_pulse_tween and _line_pulse_tween.is_valid():
		_line_pulse_tween.kill()
	_line_pulse_tween = null

func _set_line_pulse_alpha(t: float) -> void:
	# t goes 1→0→1 in the loop; interpolate alpha between min and max
	_line_prediction_overlay.a = lerpf(_LINE_PULSE_ALPHA_MIN, _LINE_PULSE_ALPHA_MAX, t)
	_line_prediction_border.a = lerpf(_LINE_PULSE_BORDER_MIN, _LINE_PULSE_BORDER_MAX, t)
	queue_redraw()

func _tween_to_empty(t: float) -> void:
	_bg_color = _bg_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = _glow_color.a * t
	_highlight_color.a = _highlight_color.a * t
	_border_color = _border_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	queue_redraw()

## Draw a rounded rectangle using polygon approximation
func _draw_rounded_rect(rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0) -> void:
	var r := minf(rect.size.x, rect.size.y) * 0.20  # 20% corner radius
	var points := PackedVector2Array()
	var segments := 6  # segments per corner arc
	# Top-left
	for i in range(segments + 1):
		var angle := PI + float(i) / segments * (PI / 2.0)
		points.append(Vector2(rect.position.x + r + cos(angle) * r, rect.position.y + r + sin(angle) * r))
	# Top-right
	for i in range(segments + 1):
		var angle := -PI / 2.0 + float(i) / segments * (PI / 2.0)
		points.append(Vector2(rect.position.x + rect.size.x - r + cos(angle) * r, rect.position.y + r + sin(angle) * r))
	# Bottom-right
	for i in range(segments + 1):
		var angle := 0.0 + float(i) / segments * (PI / 2.0)
		points.append(Vector2(rect.position.x + rect.size.x - r + cos(angle) * r, rect.position.y + rect.size.y - r + sin(angle) * r))
	# Bottom-left
	for i in range(segments + 1):
		var angle := PI / 2.0 + float(i) / segments * (PI / 2.0)
		points.append(Vector2(rect.position.x + r + cos(angle) * r, rect.position.y + rect.size.y - r + sin(angle) * r))

	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])  # close the loop
		draw_polyline(points, color, line_width, true)


func _draw() -> void:
	var cell_rect := Rect2(Vector2.ZERO, size)
	var inset := 2.0  # wider gap for casual feel

	# Apply scale transform around cell center
	if _scale_factor != 1.0 and _scale_factor > 0.01:
		var center := size / 2.0
		var offset := center * (1.0 - _scale_factor)
		draw_set_transform(offset, 0.0, Vector2.ONE * _scale_factor)

	var bg_rect := Rect2(
		Vector2(inset, inset),
		Vector2(size.x - inset * 2, size.y - inset * 2))

	# Layer 1: Soft shadow (offset down 1.5px, slightly darker)
	if _occupied and _bg_color.a > 0.5:
		var shadow_rect := Rect2(bg_rect.position + Vector2(0, 1.5), bg_rect.size)
		var shadow_color := Color(0.0, 0.0, 0.0, 0.08)
		_draw_rounded_rect(shadow_rect, shadow_color)

	# Layer 2: Glow (behind block)
	if _glow_color.a > 0.01:
		_draw_rounded_rect(bg_rect, _glow_color)

	# Layer 3: Background (rounded)
	_draw_rounded_rect(bg_rect, _bg_color)

	# Layer 4: Glossy highlight gradient (top → bottom, subtle)
	if _highlight_color.a > 0.01 or (_occupied and _bg_color.a > 0.5):
		var grad_alpha := _highlight_color.a if _highlight_color.a > 0.01 else 0.12
		var grad_top := Color(1.0, 1.0, 1.0, grad_alpha)
		var grad_bottom := Color(1.0, 1.0, 1.0, 0.0)
		# Simple two-band approximation for gradient on rounded shape
		var half_h := bg_rect.size.y * 0.5
		var top_rect := Rect2(bg_rect.position, Vector2(bg_rect.size.x, half_h))
		_draw_rounded_rect(top_rect, grad_top.lerp(grad_bottom, 0.3))

	# Layer 5: Line prediction overlay + accented border
	if _line_prediction_active:
		_draw_rounded_rect(bg_rect, _line_prediction_overlay)
		_draw_rounded_rect(bg_rect, _line_prediction_border, false, 1.5)

	# Reset transform
	if _scale_factor != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
