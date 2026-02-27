extends Control

signal toggled(is_on: bool)

const TRACK_COLOR_OFF := Color(0.227, 0.227, 0.431)  # #3A3A6E
const TRACK_COLOR_ON := Color(0.486, 0.227, 0.929)   # #7C3AED
const THUMB_COLOR := Color(1.0, 1.0, 1.0)
const THUMB_SIZE := 22.0
const THUMB_X_OFF := 3.0
const THUMB_X_ON := 27.0
const ANIM_DURATION := 0.15

var is_on: bool = false

var _thumb_x: float = THUMB_X_OFF:
	set(value):
		_thumb_x = value
		queue_redraw()

var _track_color: Color = TRACK_COLOR_OFF:
	set(value):
		_track_color = value
		queue_redraw()

var _style: StyleBoxFlat


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.corner_radius_top_left = 14
	_style.corner_radius_top_right = 14
	_style.corner_radius_bottom_left = 14
	_style.corner_radius_bottom_right = 14
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_on(value: bool, animate: bool = true) -> void:
	if is_on == value:
		return
	is_on = value
	var target_x: float = THUMB_X_ON if value else THUMB_X_OFF
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


func _draw() -> void:
	# Track (rounded rect via StyleBoxFlat)
	_style.bg_color = _track_color
	draw_style_box(_style, Rect2(Vector2.ZERO, size))

	# Thumb (circle)
	var thumb_center := Vector2(_thumb_x + THUMB_SIZE * 0.5, size.y * 0.5)
	draw_circle(thumb_center, THUMB_SIZE * 0.5, THUMB_COLOR)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_do_toggle()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_do_toggle()


func _do_toggle() -> void:
	var new_state: bool = not is_on
	is_on = new_state
	var target_x: float = THUMB_X_ON if new_state else THUMB_X_OFF
	var target_color: Color = TRACK_COLOR_ON if new_state else TRACK_COLOR_OFF

	var tween: Tween = create_tween()
	if Engine.time_scale != 1.0:
		tween.set_speed_scale(1.0 / Engine.time_scale)
	tween.set_parallel(true)
	tween.tween_property(self, "_thumb_x", target_x, ANIM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_track_color", target_color, ANIM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	toggled.emit(new_state)
	accept_event()
