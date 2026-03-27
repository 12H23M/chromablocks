extends Control

signal drag_started(piece_node: Control)
signal drag_moved(piece_node: Control, global_pos: Vector2)
signal drag_ended(piece_node: Control, global_pos: Vector2)

var piece_data: BlockPiece
var tray_index: int = -1
var _cell_size: float = 28.0
var _dragging: bool = false
var _is_lifted: bool = false
var _drag_offset := Vector2.ZERO
var _original_position := Vector2.ZERO
var _return_tween: Tween = null

const DRAG_OFFSET_Y: float = GameConstants.DRAG_OFFSET_Y
const DRAG_SCALE: float = GameConstants.DRAG_SCALE

func setup(p_piece: BlockPiece, p_index: int, p_cell_size: float) -> void:
	piece_data = p_piece
	tray_index = p_index
	_cell_size = p_cell_size
	mouse_filter = Control.MOUSE_FILTER_STOP

	custom_minimum_size = Vector2(0, piece_data.height * _cell_size)
	queue_redraw()

func _draw() -> void:
	if piece_data == null:
		return

	var inset := 2.5
	var piece_pixel_w := piece_data.width * _cell_size
	var piece_pixel_h := piece_data.height * _cell_size
	var offset_x := (size.x - piece_pixel_w) / 2.0
	var offset_y := (size.y - piece_pixel_h) / 2.0

	var base_color := AppColors.get_block_color(piece_data.color)
	var light_color := AppColors.get_block_light_color(piece_data.color)
	var glow_color := AppColors.get_block_glow_color(piece_data.color)

	# Special rendering for BOMB piece
	if piece_data.type == Enums.PieceType.BOMB:
		_draw_bomb_piece(offset_x, offset_y, piece_pixel_w, piece_pixel_h)
		return

	# Gift piece: golden glow effect
	if piece_data.is_gift:
		_draw_gift_effect(offset_x, offset_y, piece_pixel_w, piece_pixel_h)

	for row_idx in piece_data.shape.size():
		for col_idx in piece_data.shape[row_idx].size():
			if piece_data.shape[row_idx][col_idx] == 1:
				var cx: float = offset_x + col_idx * _cell_size
				var cy: float = offset_y + row_idx * _cell_size
				var bg_rect := Rect2(
					Vector2(cx + inset, cy + inset),
					Vector2(_cell_size - inset * 2, _cell_size - inset * 2))

				# Glow aura
				if glow_color.a > 0.01:
					var glow_rect := Rect2(bg_rect.position - Vector2(1, 1), bg_rect.size + Vector2(2, 2))
					DrawUtils.draw_rounded_rect(self, glow_rect, glow_color)

				# Full bubble block (shadow + base + depth + shine + specular + rim)
				var shadow_strength := 0.20 if _is_lifted else 0.12
				var shadow_y := 3.0 if _is_lifted else 2.0
				DrawUtils.draw_bubble_block(self, bg_rect, base_color, shadow_strength, shadow_y)


## Special rendering for bomb piece: red bomb with fuse
func _draw_bomb_piece(offset_x: float, offset_y: float, piece_w: float, piece_h: float) -> void:
	var inset := 2.5
	var cell_rect := Rect2(
		Vector2(offset_x + inset, offset_y + inset),
		Vector2(_cell_size - inset * 2, _cell_size - inset * 2))

	# Pulsing glow effect for bomb
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(time * 4.0)  # 2Hz pulse
	var glow_color := Color(1.0, 0.3, 0.1, 0.4 + 0.3 * pulse)

	# Outer glow
	var glow_rect := Rect2(cell_rect.position - Vector2(4, 4), cell_rect.size + Vector2(8, 8))
	DrawUtils.draw_rounded_rect(self, glow_rect, glow_color, 8.0)

	# Bomb body (dark red/black gradient)
	var body_color := Color(0.6, 0.15, 0.1)  # Dark red
	var highlight_color := Color(0.9, 0.35, 0.2)  # Bright red highlight

	# Shadow
	var shadow_rect := Rect2(cell_rect.position + Vector2(2, 2), cell_rect.size)
	DrawUtils.draw_rounded_rect(self, shadow_rect, Color(0, 0, 0, 0.3), 6.0)

	# Main body
	DrawUtils.draw_rounded_rect(self, cell_rect, body_color, 6.0)

	# Highlight (top-left)
	var highlight_rect := Rect2(cell_rect.position + Vector2(3, 3), cell_rect.size * 0.5)
	DrawUtils.draw_rounded_rect(self, highlight_rect, highlight_color, 4.0)

	# Fuse icon (simple triangle pointing up)
	var center_x := cell_rect.position.x + cell_rect.size.x / 2.0
	var center_y := cell_rect.position.y + cell_rect.size.y / 2.0
	var fuse_size := _cell_size * 0.25

	# Draw spark effect
	var spark_color := Color(1.0, 0.9, 0.3, 0.8 + 0.2 * pulse)
	var spark_radius := fuse_size * (0.6 + 0.4 * pulse)
	draw_circle(Vector2(center_x, center_y - fuse_size * 0.3), spark_radius, spark_color)

	# Inner dark circle (bomb center)
	var inner_radius := _cell_size * 0.2
	draw_circle(Vector2(center_x, center_y), inner_radius, Color(0.2, 0.05, 0.05))

## Gift piece effect: golden border + sparkle
func _draw_gift_effect(offset_x: float, offset_y: float, piece_w: float, piece_h: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(time * 3.0)  # 1.5Hz pulse

	# Golden glow (pulsing)
	var gold_color := Color(1.0, 0.84, 0.0, 0.4 + 0.3 * pulse)  # Gold #FFD700
	var glow_rect := Rect2(
		Vector2(offset_x - 4, offset_y - 4),
		Vector2(piece_w + 8, piece_h + 8))
	DrawUtils.draw_rounded_rect(self, glow_rect, gold_color, 10.0)

	# Sparkle stars (3 small stars)
	for i in 3:
		var star_phase := time * 2.0 + i * 2.094  # 120° offset
		var star_alpha := 0.5 + 0.5 * sin(star_phase)
		var star_x := offset_x + piece_w * (0.2 + i * 0.3)
		var star_y := offset_y + piece_h * 0.5 + sin(time * 4.0 + i) * 5.0
		var star_color := Color(1.0, 0.95, 0.7, star_alpha * 0.8)
		var star_size := 3.0 + 2.0 * pulse
		draw_circle(Vector2(star_x, star_y), star_size, star_color)

# Gift sparkle redraw throttle: limit to ~20fps to save CPU
var _last_gift_redraw_msec: int = 0
const _GIFT_REDRAW_INTERVAL_MS := 50

func _process(_delta: float) -> void:
	# Gift piece animation (sparkle effect) — throttled
	if piece_data != null and piece_data.is_gift:
		var now := Time.get_ticks_msec()
		if now - _last_gift_redraw_msec >= _GIFT_REDRAW_INTERVAL_MS:
			_last_gift_redraw_msec = now
			queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = true
			_is_lifted = true
			_original_position = global_position
			_drag_offset = global_position - event.global_position
			scale = Vector2.ONE * DRAG_SCALE
			z_index = 100
			drag_started.emit(self)
			accept_event()

func _input(event: InputEvent) -> void:
	if not _dragging:
		return

	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = false
			_is_lifted = false
			z_index = 0
			drag_ended.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
			scale = Vector2.ONE
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var raw_pos: Vector2 = event.global_position + _drag_offset + Vector2(0, DRAG_OFFSET_Y)
		var viewport_size: Vector2 = get_viewport_rect().size
		global_position.x = clampf(raw_pos.x, -size.x * 0.5, viewport_size.x - size.x * 0.5)
		global_position.y = clampf(raw_pos.y, -size.y * 0.5, viewport_size.y - size.y * 0.5)
		drag_moved.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
		get_viewport().set_input_as_handled()

func return_to_tray() -> Tween:
	_dragging = false
	_is_lifted = false
	scale = Vector2.ONE
	z_index = 0
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	var tween := create_tween()
	_return_tween = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", _original_position, 0.2)
	return tween

func remove_from_tray() -> void:
	if _return_tween and _return_tween.is_valid():
		_return_tween.kill()
	var tween := create_tween()
	_return_tween = tween
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
