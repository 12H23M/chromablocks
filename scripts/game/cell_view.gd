extends Control

var _occupied: bool = false
var _color: int = -1

# Layer colors (set by set_filled / set_empty / set_highlight)
var _glow_color := Color.TRANSPARENT
var _bg_color := Color("0F1D32")
var _highlight_color := Color.TRANSPARENT
var _border_color := Color("1C2E45")

# Scale animation for clear effects
var _scale_factor := 1.0

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

func play_clear_flash(duration: float, delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	# Remember the cell's original bright color for the effect
	var bright_color := Color.WHITE
	if _occupied and _color >= 0:
		bright_color = AppColors.get_block_light_color(_color)

	# Phase 1: Flash bright in original color (0.08s)
	_bg_color = bright_color
	_glow_color = Color(bright_color.r, bright_color.g, bright_color.b, 0.8)
	_highlight_color = Color(1, 1, 1, 0.6)
	_border_color = bright_color
	_scale_factor = 1.0
	queue_redraw()

	var tween := create_tween()

	# Phase 2: Pop to white + scale up (0.1s)
	tween.tween_callback(func():
		_bg_color = Color.WHITE
		_glow_color = Color(1, 1, 1, 0.9)
		_border_color = Color.WHITE
		queue_redraw()
	).set_delay(0.06)
	tween.tween_property(self, "_scale_factor", 1.25, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 3: Shrink + fade out
	tween.tween_method(_tween_clear_out, 1.0, 0.0, duration * 0.7)
	tween.tween_callback(func():
		_scale_factor = 1.0
		set_empty()
	)

func play_color_match_flash(duration: float, delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	var bright := AppColors.get_block_light_color(_color) if _occupied else Color.WHITE
	_bg_color = bright
	_glow_color = Color(bright.r, bright.g, bright.b, 0.6)
	queue_redraw()

	var tween := create_tween()
	tween.tween_method(_tween_to_empty, 1.0, 0.0, duration)
	tween.tween_callback(set_empty)

func _tween_clear_out(t: float) -> void:
	# Fade colors toward empty
	_bg_color = Color.WHITE.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = 0.9 * t * t
	_highlight_color.a = 0.0
	_border_color = Color.WHITE.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	# Shrink scale from current down to 0
	_scale_factor = lerpf(0.0, _scale_factor, t)
	queue_redraw()

func _tween_to_empty(t: float) -> void:
	_bg_color = _bg_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
	_glow_color.a = _glow_color.a * t
	_highlight_color.a = _highlight_color.a * t
	_border_color = _border_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
	queue_redraw()

func _draw() -> void:
	var cell_rect := Rect2(Vector2.ZERO, size)
	var inset := 1.0

	# Apply scale transform around cell center
	if _scale_factor != 1.0 and _scale_factor > 0.01:
		var center := size / 2.0
		var offset := center * (1.0 - _scale_factor)
		draw_set_transform(offset, 0.0, Vector2.ONE * _scale_factor)

	# Layer 1: Glow (full cell area)
	if _glow_color.a > 0.01:
		draw_rect(cell_rect, _glow_color)

	# Layer 2: Background (inset by 1px)
	var bg_rect := Rect2(
		Vector2(inset, inset),
		Vector2(size.x - inset * 2, size.y - inset * 2))
	draw_rect(bg_rect, _bg_color)

	# Layer 3: Highlight band (top 35% of the inset area)
	if _highlight_color.a > 0.01:
		var band_height := (size.y - inset * 2) * 0.35
		var band_rect := Rect2(
			Vector2(inset, inset),
			Vector2(size.x - inset * 2, band_height))
		draw_rect(band_rect, _highlight_color)

	# Layer 4: Border (1px outline around the inset area)
	draw_rect(bg_rect, _border_color, false, 1.0)

	# Reset transform
	if _scale_factor != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
