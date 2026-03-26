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
var _clear_tween: Tween = null
var _clearing: bool = false

# Cell aging (Color Heat)
var _age: int = 0
var _age_shake_offset := Vector2.ZERO

# Special tile
var _special_type: int = GameConstants.SPECIAL_TILE_NONE
var _special_glow_alpha: float = 0.5
var _special_pulse_tween: Tween = null

# Pulse redraw throttle: limit ambient pulse redraws to ~30fps (33ms)
var _last_pulse_redraw_msec: int = 0
const _PULSE_REDRAW_INTERVAL_MS := 33

func _throttled_pulse_redraw() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_pulse_redraw_msec >= _PULSE_REDRAW_INTERVAL_MS:
		_last_pulse_redraw_msec = now
		queue_redraw()

func set_empty() -> void:
	# Kill any running clear animation
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()
		_clear_tween = null
	_clearing = false
	_stop_special_pulse()
	_occupied = false
	_color = -1
	_age = 0
	_special_type = GameConstants.SPECIAL_TILE_NONE
	_age_shake_offset = Vector2.ZERO
	_glow_color = Color.TRANSPARENT
	_bg_color = AppColors.EMPTY_CELL
	_highlight_color = Color.TRANSPARENT
	_border_color = AppColors.EMPTY_BORDER
	_scale_factor = 1.0
	set_process(false)
	queue_redraw()

func set_filled(block_color: int, age: int = 0, special_type: int = -1) -> void:
	# Kill any running clear animation that could overwrite this state
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()
		_clear_tween = null
	_clearing = false
	_occupied = true
	_color = block_color
	_scale_factor = 1.0
	_age = age
	_special_type = special_type
	var base := AppColors.get_block_color(block_color)
	var light := AppColors.get_block_light_color(block_color)
	var glow := AppColors.get_block_glow_color(block_color)

	_glow_color = glow
	_bg_color = base
	_highlight_color = Color(light.r, light.g, light.b, 0.4)
	_border_color = light

	# Age shake for stage 2+ (disabled when aging is off)
	if GameConstants.CELL_AGE_ENABLED and _age >= GameConstants.CELL_AGE_STAGE2:
		set_process(true)
	else:
		set_process(false)
		_age_shake_offset = Vector2.ZERO

	# Special tile pulse
	if _special_type != GameConstants.SPECIAL_TILE_NONE:
		_start_special_pulse()
	else:
		_stop_special_pulse()

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

func _process(_delta: float) -> void:
	if GameConstants.CELL_AGE_ENABLED and _age >= GameConstants.CELL_AGE_STAGE2 and _occupied:
		_age_shake_offset = Vector2(
			randf_range(-0.7, 0.7),
			randf_range(-0.7, 0.7)
		)
		queue_redraw()


func _start_special_pulse() -> void:
	_stop_special_pulse()
	_special_pulse_tween = create_tween()
	_special_pulse_tween.set_loops()
	_special_pulse_tween.tween_method(func(t: float):
		_special_glow_alpha = lerpf(0.3, 0.8, t)
		_throttled_pulse_redraw()
	, 0.0, 1.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_special_pulse_tween.tween_method(func(t: float):
		_special_glow_alpha = lerpf(0.3, 0.8, t)
		_throttled_pulse_redraw()
	, 1.0, 0.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_special_pulse() -> void:
	if _special_pulse_tween and _special_pulse_tween.is_valid():
		_special_pulse_tween.kill()
	_special_pulse_tween = null
	_special_glow_alpha = 0.5


func play_place_pulse(delay: float = 0.0) -> void:
	var original_bg := _bg_color
	var light := AppColors.get_block_light_color(_color) if _color >= 0 else Color.WHITE

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	# Flash color
	tween.tween_callback(func():
		_bg_color = light
		_scale_factor = 1.05
		queue_redraw()
	)
	# 1. Squash (1.05→0.94)
	tween.tween_property(self, "_scale_factor", 0.94, 0.06) \
		 .set_ease(Tween.EASE_OUT)
	# 2. Stretch (0.94→1.06)
	tween.tween_property(self, "_scale_factor", 1.06, 0.05) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 3. Settle (1.06→1.0)
	tween.tween_property(self, "_scale_factor", 1.0, 0.04) \
		 .set_ease(Tween.EASE_IN_OUT)
	# Color flash fade back
	tween.parallel().tween_method(func(t: float):
		_bg_color = light.lerp(original_bg, 1.0 - t)
		queue_redraw()
	, 1.0, 0.0, 0.15)


## Adjacent ripple: micro-bounce for nearby occupied cells
func play_adjacent_ripple(delay: float = 0.0) -> void:
	if not _occupied:
		return
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "_scale_factor", 1.02, 0.05) \
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_scale_factor", 1.0, 0.05) \
		 .set_ease(Tween.EASE_IN_OUT)


## Perfect clear wave: brief white flash with scale pop, delayed by distance from center
func play_perfect_wave_flash(delay: float) -> void:
	var original_bg := _bg_color
	var flash_color := Color(1.0, 1.0, 1.0, 0.9)
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	if delay > 0.0:
		tween.tween_interval(delay)
	# Flash white + scale pop
	tween.tween_callback(func():
		_bg_color = flash_color
		_scale_factor = 1.08
		queue_redraw()
	)
	tween.tween_property(self, "_scale_factor", 1.0, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_method(func(t: float):
		_bg_color = flash_color.lerp(original_bg, 1.0 - t)
		queue_redraw()
	, 1.0, 0.0, 0.2)


func play_clear_flash(duration: float, delay: float = 0.0, cached_color: Color = Color.TRANSPARENT) -> void:
	var bright_color := Color.WHITE
	if cached_color.a > 0.01:
		bright_color = cached_color
	elif _occupied and _color >= 0:
		bright_color = AppColors.get_block_light_color(_color)
	_clear_color = bright_color

	# Kill any existing clear tween
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()

	# Mark as not occupied immediately
	_occupied = false
	_color = -1
	_clearing = true

	var tween := create_tween()
	_clear_tween = tween
	# Use IDLE process to avoid time_scale issues entirely
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

	if delay > 0.0:
		tween.tween_interval(delay)

	# Phase 1: Bright flash (immediate)
	tween.tween_callback(func():
		_bg_color = bright_color
		_glow_color = Color(bright_color.r, bright_color.g, bright_color.b, 1.0)
		_highlight_color = Color(bright_color.r, bright_color.g, bright_color.b, 0.8)
		_border_color = bright_color
		_scale_factor = 1.0
		queue_redraw()
	)

	# Phase 2: Pop
	var peak_color := bright_color.lightened(0.4)
	tween.tween_callback(func():
		_bg_color = peak_color
		_glow_color = Color(peak_color.r, peak_color.g, peak_color.b, 0.9)
		_border_color = peak_color
		queue_redraw()
	).set_delay(0.06)
	tween.tween_property(self, "_scale_factor", 1.2, 0.08) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 3: Shrink + fade (directly to empty appearance)
	tween.tween_method(_tween_clear_out, 1.0, 0.0, 0.2) \
		 .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Phase 4: Ensure fully reset — don't call set_empty (it kills tween mid-callback)
	tween.tween_callback(func():
		_clear_tween = null
		_clearing = false
		# Only reset if cell wasn't re-filled during animation
		if not _occupied:
			_color = -1
			_glow_color = Color.TRANSPARENT
			_bg_color = AppColors.EMPTY_CELL
			_highlight_color = Color.TRANSPARENT
			_border_color = AppColors.EMPTY_BORDER
			_scale_factor = 1.0
			queue_redraw()
	)

func play_color_match_flash(duration: float, delay: float = 0.0) -> void:
	var bright := AppColors.get_block_light_color(_color) if _occupied else Color.WHITE

	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()

	_occupied = false
	_color = -1
	_clearing = true

	var tween := create_tween()
	_clear_tween = tween
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

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
	tween.tween_callback(func():
		_clear_tween = null
		_clearing = false
		# Only reset if cell wasn't re-filled during animation
		if not _occupied:
			_color = -1
			_glow_color = Color.TRANSPARENT
			_bg_color = AppColors.EMPTY_CELL
			_highlight_color = Color.TRANSPARENT
			_border_color = AppColors.EMPTY_BORDER
			_scale_factor = 1.0
			queue_redraw()
	)

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
	_throttled_pulse_redraw()

## Blast proximity hint overlay (gold/orange, separate from line prediction)
var _blast_hint_active: bool = false
var _blast_hint_overlay := Color(1.0, 0.75, 0.2, 0.30)
var _blast_hint_border := Color(1.0, 0.65, 0.1, 0.55)
var _blast_pulse_tween: Tween = null

const _BLAST_PULSE_ALPHA_MIN := 0.15
const _BLAST_PULSE_ALPHA_MAX := 0.40
const _BLAST_PULSE_BORDER_MIN := 0.30
const _BLAST_PULSE_BORDER_MAX := 0.70
const _BLAST_PULSE_DURATION := 0.5

func show_blast_hint() -> void:
	_blast_hint_active = true
	_blast_hint_overlay = Color(1.0, 0.75, 0.2, _BLAST_PULSE_ALPHA_MAX)
	_blast_hint_border = Color(1.0, 0.65, 0.1, _BLAST_PULSE_BORDER_MAX)
	_start_blast_pulse()
	queue_redraw()

func clear_blast_hint() -> void:
	if _blast_hint_active:
		_blast_hint_active = false
		_stop_blast_pulse()
		queue_redraw()

func _start_blast_pulse() -> void:
	_stop_blast_pulse()
	_blast_pulse_tween = create_tween()
	_blast_pulse_tween.set_loops()
	_blast_pulse_tween.tween_method(_set_blast_pulse_alpha, 1.0, 0.0, _BLAST_PULSE_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_blast_pulse_tween.tween_method(_set_blast_pulse_alpha, 0.0, 1.0, _BLAST_PULSE_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_blast_pulse() -> void:
	if _blast_pulse_tween and _blast_pulse_tween.is_valid():
		_blast_pulse_tween.kill()
	_blast_pulse_tween = null

func _set_blast_pulse_alpha(t: float) -> void:
	_blast_hint_overlay.a = lerpf(_BLAST_PULSE_ALPHA_MIN, _BLAST_PULSE_ALPHA_MAX, t)
	_blast_hint_border.a = lerpf(_BLAST_PULSE_BORDER_MIN, _BLAST_PULSE_BORDER_MAX, t)
	_throttled_pulse_redraw()


## Near-miss line hint overlay (white pulse for 7/8 filled rows/cols)
var _near_line_hint_active: bool = false
var _near_line_hint_overlay := Color(1.0, 1.0, 1.0, 0.15)
var _near_line_pulse_tween: Tween = null

const _NEAR_LINE_ALPHA_MIN := 0.10
const _NEAR_LINE_ALPHA_MAX := 0.20
const _NEAR_LINE_PULSE_PERIOD := 1.5

func show_near_line_hint() -> void:
	_near_line_hint_active = true
	_near_line_hint_overlay = Color(1.0, 1.0, 1.0, _NEAR_LINE_ALPHA_MAX)
	_start_near_line_pulse()
	queue_redraw()

func clear_near_line_hint() -> void:
	if _near_line_hint_active:
		_near_line_hint_active = false
		_stop_near_line_pulse()
		queue_redraw()

func _start_near_line_pulse() -> void:
	_stop_near_line_pulse()
	_near_line_pulse_tween = create_tween()
	_near_line_pulse_tween.set_loops()
	_near_line_pulse_tween.tween_method(_set_near_line_alpha, 1.0, 0.0, _NEAR_LINE_PULSE_PERIOD / 2.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_near_line_pulse_tween.tween_method(_set_near_line_alpha, 0.0, 1.0, _NEAR_LINE_PULSE_PERIOD / 2.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_near_line_pulse() -> void:
	if _near_line_pulse_tween and _near_line_pulse_tween.is_valid():
		_near_line_pulse_tween.kill()
	_near_line_pulse_tween = null

func _set_near_line_alpha(t: float) -> void:
	_near_line_hint_overlay.a = lerpf(_NEAR_LINE_ALPHA_MIN, _NEAR_LINE_ALPHA_MAX, t)
	_throttled_pulse_redraw()


## Near-miss color cluster hint overlay (colored glow for 4+ connected same-color)
var _cluster_hint_active: bool = false
var _cluster_hint_overlay := Color(1.0, 1.0, 1.0, 0.12)
var _cluster_pulse_tween: Tween = null

const _CLUSTER_ALPHA_MIN := 0.08
const _CLUSTER_ALPHA_MAX := 0.16
const _CLUSTER_PULSE_PERIOD := 1.5

func show_cluster_hint(block_color: int) -> void:
	_cluster_hint_active = true
	var hint_color: Color = AppColors.get_block_light_color(block_color) if block_color >= 0 else Color.WHITE
	_cluster_hint_overlay = Color(hint_color.r, hint_color.g, hint_color.b, _CLUSTER_ALPHA_MAX)
	_start_cluster_pulse()
	queue_redraw()

func clear_cluster_hint() -> void:
	if _cluster_hint_active:
		_cluster_hint_active = false
		_stop_cluster_pulse()
		queue_redraw()

func _start_cluster_pulse() -> void:
	_stop_cluster_pulse()
	_cluster_pulse_tween = create_tween()
	_cluster_pulse_tween.set_loops()
	_cluster_pulse_tween.tween_method(_set_cluster_alpha, 1.0, 0.0, _CLUSTER_PULSE_PERIOD / 2.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_cluster_pulse_tween.tween_method(_set_cluster_alpha, 0.0, 1.0, _CLUSTER_PULSE_PERIOD / 2.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_cluster_pulse() -> void:
	if _cluster_pulse_tween and _cluster_pulse_tween.is_valid():
		_cluster_pulse_tween.kill()
	_cluster_pulse_tween = null

func _set_cluster_alpha(t: float) -> void:
	_cluster_hint_overlay.a = lerpf(_CLUSTER_ALPHA_MIN, _CLUSTER_ALPHA_MAX, t)
	_throttled_pulse_redraw()


func _tween_to_empty(t: float) -> void:
	_bg_color = _bg_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = _glow_color.a * t
	_highlight_color.a = _highlight_color.a * t
	_border_color = _border_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	queue_redraw()

## Convenience wrappers for DrawUtils
func _draw_rounded_rect(rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.2) -> void:
	DrawUtils.draw_rounded_rect(self, rect, color, filled, line_width, radius_ratio)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, segments: int = 12) -> void:
	DrawUtils.draw_ellipse(self, center, radius, color, segments)


func _draw() -> void:
	var inset := 3.0  # gap between cells for bubble separation

	# Apply scale + age shake transform around cell center
	var has_transform := false
	if _scale_factor != 1.0 and _scale_factor > 0.01:
		var center := size / 2.0
		var offset := center * (1.0 - _scale_factor) + _age_shake_offset
		draw_set_transform(offset, 0.0, Vector2.ONE * _scale_factor)
		has_transform = true
	elif _age_shake_offset != Vector2.ZERO:
		draw_set_transform(_age_shake_offset, 0.0, Vector2.ONE)
		has_transform = true

	var bg_rect := Rect2(
		Vector2(inset, inset),
		Vector2(size.x - inset * 2, size.y - inset * 2))

	# Apply age darkening to render color
	var render_bg := _bg_color
	if GameConstants.CELL_AGE_ENABLED:
		if _occupied and _age >= GameConstants.CELL_AGE_STAGE2:
			render_bg = render_bg.darkened(GameConstants.CELL_AGE_DARKEN_STAGE2)
		elif _occupied and _age >= GameConstants.CELL_AGE_STAGE1:
			render_bg = render_bg.darkened(GameConstants.CELL_AGE_DARKEN_STAGE1)

	# Use bubble style for occupied cells AND during clear animation
	var _is_block := _occupied or _clearing
	if _is_block and render_bg.a > 0.1:
		# === BUBBLE STYLE BLOCK ===
		# Special tile outer glow
		if _special_type != GameConstants.SPECIAL_TILE_NONE:
			var sp_glow := _get_special_glow_color()
			sp_glow.a = _special_glow_alpha * 0.4
			var sp_rect := Rect2(bg_rect.position - Vector2(2, 2), bg_rect.size + Vector2(4, 4))
			_draw_rounded_rect(sp_rect, sp_glow, true, 1.0, 0.2)
		# Glow aura removed — was bleeding into adjacent cells
		# Full bubble with shadow, shine, specular, rim
		DrawUtils.draw_bubble_block(self, bg_rect, render_bg)
		# Age stage 2 crack overlay (disabled when aging off)
		if GameConstants.CELL_AGE_ENABLED and _occupied and _age >= GameConstants.CELL_AGE_STAGE2:
			_draw_crack_overlay(bg_rect)
		# Special tile icon overlay
		if _special_type != GameConstants.SPECIAL_TILE_NONE:
			_draw_special_icon(bg_rect)
	else:
		# === EMPTY CELL ===
		# Subtle empty well
		_draw_rounded_rect(bg_rect, render_bg, true, 1.0, 0.2)
		# Highlight override (for placement preview)
		if _highlight_color.a > 0.01:
			_draw_rounded_rect(bg_rect, _highlight_color, true, 1.0, 0.2)

	# Line prediction overlay + accented border
	if _line_prediction_active:
		_draw_rounded_rect(bg_rect, _line_prediction_overlay, true, 1.0, 0.2)
		_draw_rounded_rect(bg_rect, _line_prediction_border, false, 1.5, 0.2)

	# Blast hint overlay (gold/orange glow)
	if _blast_hint_active:
		_draw_rounded_rect(bg_rect, _blast_hint_overlay, true, 1.0, 0.2)
		_draw_rounded_rect(bg_rect, _blast_hint_border, false, 2.0, 0.2)

	# Near-miss line hint overlay (white pulse)
	if _near_line_hint_active:
		_draw_rounded_rect(bg_rect, _near_line_hint_overlay, true, 1.0, 0.2)

	# Near-miss cluster hint overlay (colored glow)
	if _cluster_hint_active:
		_draw_rounded_rect(bg_rect, _cluster_hint_overlay, true, 1.0, 0.2)

	# Reset transform
	if has_transform:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_crack_overlay(rect: Rect2) -> void:
	# Subtle crack lines for aged blocks
	var cx := rect.position.x + rect.size.x * 0.3
	var cy := rect.position.y + rect.size.y * 0.3
	var crack_color := Color(0.0, 0.0, 0.0, 0.25)
	draw_line(Vector2(cx, cy), Vector2(cx + rect.size.x * 0.4, cy + rect.size.y * 0.2), crack_color, 1.0)
	draw_line(Vector2(cx + rect.size.x * 0.2, cy + rect.size.y * 0.1),
		Vector2(cx + rect.size.x * 0.1, cy + rect.size.y * 0.4), crack_color, 1.0)


func _draw_special_icon(rect: Rect2) -> void:
	var center := rect.position + rect.size / 2.0
	var icon_r := minf(rect.size.x, rect.size.y) * 0.30
	match _special_type:
		GameConstants.SPECIAL_TILE_BOMB:
			_draw_bomb_icon(center, icon_r)
		GameConstants.SPECIAL_TILE_RAINBOW:
			_draw_rainbow_icon(center, icon_r)
		GameConstants.SPECIAL_TILE_FREEZE:
			_draw_freeze_icon(center, icon_r)


func _draw_bomb_icon(center: Vector2, r: float) -> void:
	# Filled bomb body (warm orange/red tones)
	var body_color := Color(0.95, 0.45, 0.15, _special_glow_alpha)
	var highlight_color := Color(1.0, 0.7, 0.3, _special_glow_alpha * 0.6)
	draw_circle(center, r * 0.65, body_color)
	# Inner highlight
	draw_circle(center + Vector2(-r * 0.15, -r * 0.15), r * 0.3, highlight_color)
	# Short fuse line on top
	var fuse_base := center + Vector2(0, -r * 0.6)
	var fuse_tip := center + Vector2(r * 0.2, -r * 1.0)
	var fuse_color := Color(0.6, 0.4, 0.2, _special_glow_alpha)
	draw_line(fuse_base, fuse_tip, fuse_color, 1.5)
	# Spark dot at fuse tip
	var spark_color := Color(1.0, 1.0, 0.4, _special_glow_alpha)
	draw_circle(fuse_tip, r * 0.15, spark_color)


func _draw_rainbow_icon(center: Vector2, r: float) -> void:
	# Subtle white ring connecting dots
	var ring_color := Color(1.0, 1.0, 1.0, _special_glow_alpha * 0.35)
	var ring_r := r * 0.65
	var ring_segments := 24
	for i in ring_segments:
		var a0: float = float(i) * TAU / float(ring_segments)
		var a1: float = float(i + 1) * TAU / float(ring_segments)
		var p0 := center + Vector2(cos(a0), sin(a0)) * ring_r
		var p1 := center + Vector2(cos(a1), sin(a1)) * ring_r
		draw_line(p0, p1, ring_color, 1.0)
	# Colored dots in a ring (bigger: 0.22)
	var rainbow := [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.PURPLE]
	for i in 6:
		var angle: float = float(i) * TAU / 6.0 - PI / 2.0
		var dot_pos := center + Vector2(cos(angle), sin(angle)) * ring_r
		var dot_color: Color = rainbow[i]
		dot_color.a = _special_glow_alpha
		draw_circle(dot_pos, r * 0.22, dot_color)
	# Center white dot
	draw_circle(center, r * 0.15, Color(1.0, 1.0, 1.0, _special_glow_alpha * 0.8))


func _draw_freeze_icon(center: Vector2, r: float) -> void:
	# Crystal/diamond shape with translucent ice blue fill + white highlight
	var ice_fill := Color(0.55, 0.85, 1.0, _special_glow_alpha * 0.5)
	var ice_edge := Color(0.7, 0.95, 1.0, _special_glow_alpha)
	var white_highlight := Color(1.0, 1.0, 1.0, _special_glow_alpha * 0.7)
	# Diamond vertices (top, right, bottom, left)
	var top := center + Vector2(0, -r)
	var right := center + Vector2(r * 0.7, 0)
	var bottom := center + Vector2(0, r * 0.8)
	var left := center + Vector2(-r * 0.7, 0)
	# Filled diamond
	var diamond := PackedVector2Array([top, right, bottom, left])
	var colors := PackedColorArray([ice_fill, ice_fill, ice_fill, ice_fill])
	draw_polygon(diamond, colors)
	# Edge outline
	draw_line(top, right, ice_edge, 1.5)
	draw_line(right, bottom, ice_edge, 1.5)
	draw_line(bottom, left, ice_edge, 1.5)
	draw_line(left, top, ice_edge, 1.5)
	# White highlight facet (upper-left triangle)
	var mid_top := (top + center) * 0.5
	var highlight_tri := PackedVector2Array([top, mid_top + Vector2(r * 0.15, 0), left + Vector2(0, -r * 0.2)])
	var highlight_colors := PackedColorArray([white_highlight, white_highlight, white_highlight])
	draw_polygon(highlight_tri, highlight_colors)


# --- Anticipation pulse (white flash before clear) ---

func play_anticipation_pulse() -> void:
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	var original_highlight := _highlight_color
	# Pulse white overlay alpha 0→0.3→0 over 0.2s
	tween.tween_method(func(t: float):
		_highlight_color = Color(1.0, 1.0, 1.0, t * 0.3)
		queue_redraw()
	, 0.0, 1.0, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t: float):
		_highlight_color = Color(1.0, 1.0, 1.0, t * 0.3)
		queue_redraw()
	, 1.0, 0.0, 0.1).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_highlight_color = original_highlight
		queue_redraw()
	)


# --- Chain pop (glow color → scale up → shrink to 0) ---

func play_chain_pop(delay: float, cached_color: Color) -> void:
	_clear_color = cached_color
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()
	_occupied = false
	_color = -1

	var tween := create_tween()
	_clear_tween = tween
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

	if delay > 0.0:
		tween.tween_interval(delay)

	# Glow with cached color
	tween.tween_callback(func():
		_bg_color = cached_color
		_glow_color = Color(cached_color.r, cached_color.g, cached_color.b, 0.5)
		_border_color = cached_color
		_scale_factor = 1.0
		queue_redraw()
	)
	# Scale 1→1.3
	tween.tween_property(self, "_scale_factor", 1.3, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Scale 1.3→0 with fade
	tween.tween_method(func(t: float):
		_scale_factor = lerpf(0.0, 1.3, t)
		_bg_color = cached_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
		_glow_color.a = 0.5 * t
		_border_color = cached_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
		queue_redraw()
	, 1.0, 0.0, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Reset
	tween.tween_callback(func():
		_clear_tween = null
		if not _occupied:
			_glow_color = Color.TRANSPARENT
			_bg_color = AppColors.EMPTY_CELL
			_highlight_color = Color.TRANSPARENT
			_border_color = AppColors.EMPTY_BORDER
			_scale_factor = 1.0
			queue_redraw()
	)


# --- Blast explode (scale up 1→1.5 while fading) ---

func play_blast_explode() -> void:
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()
	_occupied = false
	_color = -1

	var tween := create_tween()
	_clear_tween = tween
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

	tween.tween_callback(func():
		_bg_color = Color.WHITE
		_glow_color = Color(1.0, 1.0, 1.0, 0.8)
		_border_color = Color.WHITE
		_scale_factor = 1.0
		queue_redraw()
	)
	# Scale up + fade out simultaneously
	tween.tween_method(func(t: float):
		_scale_factor = lerpf(1.0, 1.5, t)
		var alpha: float = 1.0 - t
		_bg_color = Color(1.0, 1.0, 1.0, alpha)
		_glow_color = Color(1.0, 1.0, 1.0, alpha * 0.8)
		_border_color = Color(1.0, 1.0, 1.0, alpha)
		queue_redraw()
	, 0.0, 1.0, 0.15).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		_clear_tween = null
		if not _occupied:
			_glow_color = Color.TRANSPARENT
			_bg_color = AppColors.EMPTY_CELL
			_highlight_color = Color.TRANSPARENT
			_border_color = AppColors.EMPTY_BORDER
			_scale_factor = 1.0
			queue_redraw()
	)


func _get_special_glow_color() -> Color:
	match _special_type:
		GameConstants.SPECIAL_TILE_BOMB:
			return Color(1.0, 0.6, 0.2)  # warm orange
		GameConstants.SPECIAL_TILE_RAINBOW:
			return Color(1.0, 1.0, 1.0)  # white
		GameConstants.SPECIAL_TILE_FREEZE:
			return Color(0.5, 0.9, 1.0)  # ice blue
	return Color.WHITE
