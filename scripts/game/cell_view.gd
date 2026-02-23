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

# Cell aging (Color Heat)
var _age: int = 0
var _age_shake_offset := Vector2.ZERO

# Special tile
var _special_type: int = GameConstants.SPECIAL_TILE_NONE
var _special_glow_alpha: float = 0.5
var _special_pulse_tween: Tween = null

func set_empty() -> void:
	# Kill any running clear animation
	if _clear_tween and _clear_tween.is_valid():
		_clear_tween.kill()
		_clear_tween = null
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
	_occupied = true
	_color = block_color
	_age = age
	_special_type = special_type
	var base := AppColors.get_block_color(block_color)
	var light := AppColors.get_block_light_color(block_color)
	var glow := AppColors.get_block_glow_color(block_color)

	_glow_color = glow
	_bg_color = base
	_highlight_color = Color(light.r, light.g, light.b, 0.4)
	_border_color = light

	# Age shake for stage 2+
	if _age >= GameConstants.CELL_AGE_STAGE2:
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
	if _age >= GameConstants.CELL_AGE_STAGE2 and _occupied:
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
		queue_redraw()
	, 0.0, 1.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_special_pulse_tween.tween_method(func(t: float):
		_special_glow_alpha = lerpf(0.3, 0.8, t)
		queue_redraw()
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
		_occupied = false
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
		_occupied = false
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
	queue_redraw()

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
	queue_redraw()


func _tween_to_empty(t: float) -> void:
	_bg_color = _bg_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = _glow_color.a * t
	_highlight_color.a = _highlight_color.a * t
	_border_color = _border_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	queue_redraw()

## Convenience wrappers for DrawUtils
func _draw_rounded_rect(rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.35) -> void:
	DrawUtils.draw_rounded_rect(self, rect, color, filled, line_width, radius_ratio)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, segments: int = 12) -> void:
	DrawUtils.draw_ellipse(self, center, radius, color, segments)


func _draw() -> void:
	var inset := 2.5  # gap between cells for bubble separation

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
	if _occupied and _age >= GameConstants.CELL_AGE_STAGE2:
		render_bg = render_bg.darkened(GameConstants.CELL_AGE_DARKEN_STAGE2)
	elif _occupied and _age >= GameConstants.CELL_AGE_STAGE1:
		render_bg = render_bg.darkened(GameConstants.CELL_AGE_DARKEN_STAGE1)

	# Use bubble style for occupied cells AND during clear animation (scale_factor tweening)
	var _is_block := _occupied or (_scale_factor < 0.99 and _scale_factor > 0.01)
	if _is_block and render_bg.a > 0.1:
		# === BUBBLE STYLE BLOCK ===
		# Special tile outer glow
		if _special_type != GameConstants.SPECIAL_TILE_NONE:
			var sp_glow := _get_special_glow_color()
			sp_glow.a = _special_glow_alpha * 0.4
			var sp_rect := Rect2(bg_rect.position - Vector2(2, 2), bg_rect.size + Vector2(4, 4))
			_draw_rounded_rect(sp_rect, sp_glow, true, 1.0, 0.35)
		# Glow aura (behind bubble)
		if _glow_color.a > 0.01:
			var glow_rect := Rect2(bg_rect.position - Vector2(1, 1), bg_rect.size + Vector2(2, 2))
			_draw_rounded_rect(glow_rect, _glow_color, true, 1.0, 0.35)
		# Full bubble with shadow, shine, specular, rim
		DrawUtils.draw_bubble_block(self, bg_rect, render_bg)
		# Age stage 2 crack overlay
		if _occupied and _age >= GameConstants.CELL_AGE_STAGE2:
			_draw_crack_overlay(bg_rect)
		# Special tile icon overlay
		if _special_type != GameConstants.SPECIAL_TILE_NONE:
			_draw_special_icon(bg_rect)
	else:
		# === EMPTY CELL ===
		# Glow
		if _glow_color.a > 0.01:
			_draw_rounded_rect(bg_rect, _glow_color, true, 1.0, 0.35)
		# Subtle empty well
		_draw_rounded_rect(bg_rect, render_bg, true, 1.0, 0.35)
		# Highlight override (for placement preview)
		if _highlight_color.a > 0.01:
			_draw_rounded_rect(bg_rect, _highlight_color, true, 1.0, 0.35)

	# Line prediction overlay + accented border
	if _line_prediction_active:
		_draw_rounded_rect(bg_rect, _line_prediction_overlay, true, 1.0, 0.35)
		_draw_rounded_rect(bg_rect, _line_prediction_border, false, 1.5, 0.35)

	# Blast hint overlay (gold/orange glow)
	if _blast_hint_active:
		_draw_rounded_rect(bg_rect, _blast_hint_overlay, true, 1.0, 0.35)
		_draw_rounded_rect(bg_rect, _blast_hint_border, false, 2.0, 0.35)

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
	var icon_r := minf(rect.size.x, rect.size.y) * 0.22
	match _special_type:
		GameConstants.SPECIAL_TILE_BOMB:
			_draw_bomb_icon(center, icon_r)
		GameConstants.SPECIAL_TILE_RAINBOW:
			_draw_rainbow_icon(center, icon_r)
		GameConstants.SPECIAL_TILE_FREEZE:
			_draw_freeze_icon(center, icon_r)


func _draw_bomb_icon(center: Vector2, r: float) -> void:
	# Explosion star burst
	var icon_color := Color(1.0, 1.0, 1.0, _special_glow_alpha)
	for i in 8:
		var angle: float = float(i) * TAU / 8.0
		var inner := center + Vector2(cos(angle), sin(angle)) * r * 0.3
		var outer := center + Vector2(cos(angle), sin(angle)) * r
		draw_line(inner, outer, icon_color, 1.5)
	draw_circle(center, r * 0.25, icon_color)


func _draw_rainbow_icon(center: Vector2, r: float) -> void:
	# Colored dots in a ring
	var rainbow := [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.PURPLE]
	for i in 6:
		var angle: float = float(i) * TAU / 6.0 - PI / 2.0
		var dot_pos := center + Vector2(cos(angle), sin(angle)) * r * 0.65
		var dot_color: Color = rainbow[i]
		dot_color.a = _special_glow_alpha
		draw_circle(dot_pos, r * 0.18, dot_color)
	# Center white dot
	draw_circle(center, r * 0.15, Color(1.0, 1.0, 1.0, _special_glow_alpha * 0.8))


func _draw_freeze_icon(center: Vector2, r: float) -> void:
	# Snowflake — 3 crossing lines
	var ice_color := Color(0.5, 0.9, 1.0, _special_glow_alpha)
	for i in 3:
		var angle: float = float(i) * PI / 3.0
		var from := center + Vector2(cos(angle), sin(angle)) * r
		var to := center - Vector2(cos(angle), sin(angle)) * r
		draw_line(from, to, ice_color, 1.5)
		# Small branches
		for side in [-1.0, 1.0]:
			var mid := center + Vector2(cos(angle), sin(angle)) * r * 0.5
			var branch_angle: float = angle + side * PI / 4.0
			var branch_end := mid + Vector2(cos(branch_angle), sin(branch_angle)) * r * 0.3
			draw_line(mid, branch_end, ice_color, 1.0)


func _get_special_glow_color() -> Color:
	match _special_type:
		GameConstants.SPECIAL_TILE_BOMB:
			return Color(1.0, 0.6, 0.2)  # warm orange
		GameConstants.SPECIAL_TILE_RAINBOW:
			return Color(1.0, 1.0, 1.0)  # white
		GameConstants.SPECIAL_TILE_FREEZE:
			return Color(0.5, 0.9, 1.0)  # ice blue
	return Color.WHITE
