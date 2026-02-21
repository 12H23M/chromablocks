extends Control

var _occupied: bool = false
var _color: int = -1

# Layer colors (set by set_filled / set_empty / set_highlight)
var _glow_color := Color.TRANSPARENT
var _bg_color := Color("EBE7F4")
var _highlight_color := Color.TRANSPARENT
var _border_color := Color("DCD7EA")

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
func _draw_rounded_rect(rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.35) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0 or color.a < 0.005:
		return
	var r := minf(minf(rect.size.x, rect.size.y) * radius_ratio, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var segments := 8  # smoother arcs for bubble feel
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

## Draw a circle (for bubble specular highlight)
func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, segments: int = 12) -> void:
	if radius.x < 0.5 or radius.y < 0.5 or color.a < 0.005:
		return
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := float(i) / segments * TAU
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw() -> void:
	var inset := 2.5  # gap between cells for bubble separation
	
	# Apply scale transform around cell center
	if _scale_factor != 1.0 and _scale_factor > 0.01:
		var center := size / 2.0
		var offset := center * (1.0 - _scale_factor)
		draw_set_transform(offset, 0.0, Vector2.ONE * _scale_factor)

	var bg_rect := Rect2(
		Vector2(inset, inset),
		Vector2(size.x - inset * 2, size.y - inset * 2))

	# Use bubble style for occupied cells AND during clear animation (scale_factor tweening)
	var _is_block := _occupied or (_scale_factor < 0.99 and _scale_factor > 0.01)
	if _is_block and _bg_color.a > 0.1:
		# === BUBBLE STYLE BLOCK ===
		
		# Layer 1: Drop shadow (soft, below)
		var shadow_offset := Vector2(0, 2.0)
		var shadow_rect := Rect2(bg_rect.position + shadow_offset, bg_rect.size)
		_draw_rounded_rect(shadow_rect, Color(0.0, 0.0, 0.0, 0.12), true, 1.0, 0.35)
		
		# Layer 2: Glow aura
		if _glow_color.a > 0.01:
			var glow_rect := Rect2(bg_rect.position - Vector2(1, 1), bg_rect.size + Vector2(2, 2))
			_draw_rounded_rect(glow_rect, _glow_color, true, 1.0, 0.35)
		
		# Layer 3: Base color (big rounded = bubble shape)
		_draw_rounded_rect(bg_rect, _bg_color, true, 1.0, 0.35)
		
		# Layer 4: Bottom darkening (depth/3D feel)
		var dark_color := Color(_bg_color.r * 0.75, _bg_color.g * 0.75, _bg_color.b * 0.75, 0.3)
		var bottom_h := bg_rect.size.y * 0.4
		var bottom_rect := Rect2(
			Vector2(bg_rect.position.x, bg_rect.position.y + bg_rect.size.y - bottom_h),
			Vector2(bg_rect.size.x, bottom_h))
		_draw_rounded_rect(bottom_rect, dark_color, true, 1.0, 0.3)
		
		# Layer 5: Top shine (glossy bubble reflection)
		var shine_alpha := 0.30
		var shine_rect := Rect2(
			bg_rect.position + Vector2(bg_rect.size.x * 0.15, bg_rect.size.y * 0.08),
			Vector2(bg_rect.size.x * 0.7, bg_rect.size.y * 0.35))
		_draw_rounded_rect(shine_rect, Color(1.0, 1.0, 1.0, shine_alpha), true, 1.0, 0.5)
		
		# Layer 6: Specular dot (tiny white circle, top-left)
		var spec_center := bg_rect.position + Vector2(bg_rect.size.x * 0.28, bg_rect.size.y * 0.25)
		var spec_radius := Vector2(bg_rect.size.x * 0.08, bg_rect.size.y * 0.08)
		_draw_ellipse(spec_center, spec_radius, Color(1.0, 1.0, 1.0, 0.6))
		
		# Layer 7: Rim light (subtle edge highlight)
		_draw_rounded_rect(bg_rect, Color(1.0, 1.0, 1.0, 0.08), false, 1.0, 0.35)
	
	else:
		# === EMPTY CELL ===
		# Glow
		if _glow_color.a > 0.01:
			_draw_rounded_rect(bg_rect, _glow_color, true, 1.0, 0.35)
		# Subtle empty well
		_draw_rounded_rect(bg_rect, _bg_color, true, 1.0, 0.35)
		# Highlight override (for placement preview)
		if _highlight_color.a > 0.01:
			_draw_rounded_rect(bg_rect, _highlight_color, true, 1.0, 0.35)

	# Line prediction overlay + accented border
	if _line_prediction_active:
		_draw_rounded_rect(bg_rect, _line_prediction_overlay, true, 1.0, 0.35)
		_draw_rounded_rect(bg_rect, _line_prediction_border, false, 1.5, 0.35)

	# Reset transform
	if _scale_factor != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
