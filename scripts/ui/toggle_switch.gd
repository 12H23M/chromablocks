extends Button

signal toggled_value(is_on: bool)

const TRACK_COLOR_OFF := Color(0.227, 0.227, 0.431)  # #3A3A6E
const TRACK_COLOR_ON := Color(0.486, 0.227, 0.929)   # #7C3AED
const THUMB_COLOR := Color(1.0, 1.0, 1.0)
const THUMB_PADDING := 3.0
const ANIM_DURATION := 0.15

var is_on: bool = false

var _thumb_x: float = 0.0:
	set(value):
		_thumb_x = value
		queue_redraw()

var _track_color: Color = TRACK_COLOR_OFF:
	set(value):
		_track_color = value
		queue_redraw()


func _ready() -> void:
	toggle_mode = false
	flat = true
	text = ""
	clip_text = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Initial thumb position
	_thumb_x = _get_thumb_x(is_on)
	_track_color = TRACK_COLOR_ON if is_on else TRACK_COLOR_OFF
	pressed.connect(_do_toggle)


func set_on(value: bool, animate: bool = true) -> void:
	if is_on == value:
		# Still sync visuals in case of mismatch
		if not animate:
			_thumb_x = _get_thumb_x(value)
			_track_color = TRACK_COLOR_ON if value else TRACK_COLOR_OFF
		return
	is_on = value
	var target_x: float = _get_thumb_x(value)
	var target_color: Color = TRACK_COLOR_ON if value else TRACK_COLOR_OFF

	if animate:
		var tween: Tween = create_tween()
		if Engine.time_scale != 1.0:
			tween.set_speed_scale(1.0 / Engine.time_scale)
		tween.set_parallel(true)
		tween.tween_property(self, "_thumb_x", target_x, ANIM_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "_track_color", target_color, ANIM_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_thumb_x = target_x
		_track_color = target_color


func _get_thumb_x(on: bool) -> float:
	var thumb_size: float = size.y - THUMB_PADDING * 2.0
	if on:
		return size.x - THUMB_PADDING - thumb_size
	return THUMB_PADDING


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var radius: float = size.y * 0.5

	# Track
	draw_rect(Rect2(Vector2.ZERO, size), _track_color, true)
	# Round corners via 4 circles at corners + center rects
	# Simpler: use draw_rect with no rounding, then overlay circles
	# Actually let's just use StyleBoxFlat approach
	var style := StyleBoxFlat.new()
	style.bg_color = _track_color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)

	# Thumb (circle)
	var thumb_size: float = size.y - THUMB_PADDING * 2.0
	var thumb_center := Vector2(_thumb_x + thumb_size * 0.5, size.y * 0.5)
	draw_circle(thumb_center, thumb_size * 0.5, THUMB_COLOR)


func _do_toggle() -> void:
	var new_state: bool = not is_on
	set_on(new_state, true)
	toggled_value.emit(new_state)
