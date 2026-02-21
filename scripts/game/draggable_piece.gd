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
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", _original_position, 0.2)
	return tween

func remove_from_tray() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
