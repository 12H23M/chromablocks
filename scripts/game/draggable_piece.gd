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

## Draw a rounded rectangle (matches cell_view bubble style)
func _draw_rounded_rect_piece(rect: Rect2, color: Color, filled: bool = true, line_width: float = 1.0, radius_ratio: float = 0.35) -> void:
	var r := minf(rect.size.x, rect.size.y) * radius_ratio
	var points := PackedVector2Array()
	var segments := 8
	for corner in 4:
		var base_angle := PI + corner * (PI / 2.0)
		var center_x: float
		var center_y: float
		match corner:
			0:  # top-left
				center_x = rect.position.x + r
				center_y = rect.position.y + r
			1:  # top-right
				center_x = rect.position.x + rect.size.x - r
				center_y = rect.position.y + r
				base_angle = -PI / 2.0
			2:  # bottom-right
				center_x = rect.position.x + rect.size.x - r
				center_y = rect.position.y + rect.size.y - r
				base_angle = 0.0
			3:  # bottom-left
				center_x = rect.position.x + r
				center_y = rect.position.y + rect.size.y - r
				base_angle = PI / 2.0
		for i in range(segments + 1):
			var angle := base_angle + float(i) / segments * (PI / 2.0)
			points.append(Vector2(center_x + cos(angle) * r, center_y + sin(angle) * r))
	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		draw_polyline(points, color, line_width, true)

func _draw_ellipse_piece(center: Vector2, radius: Vector2, color: Color, segments: int = 12) -> void:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := float(i) / segments * TAU
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

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

				# Shadow (lifted = stronger)
				var shadow_alpha := 0.20 if _is_lifted else 0.12
				var shadow_offset := 3.0 if _is_lifted else 2.0
				var shadow_rect := Rect2(bg_rect.position + Vector2(0, shadow_offset), bg_rect.size)
				_draw_rounded_rect_piece(shadow_rect, Color(0, 0, 0, shadow_alpha), true, 1.0, 0.35)

				# Glow aura
				if glow_color.a > 0.01:
					var glow_rect := Rect2(bg_rect.position - Vector2(1, 1), bg_rect.size + Vector2(2, 2))
					_draw_rounded_rect_piece(glow_rect, glow_color, true, 1.0, 0.35)

				# Base bubble
				_draw_rounded_rect_piece(bg_rect, base_color, true, 1.0, 0.35)

				# Bottom darkening (3D depth)
				var dark_color := Color(base_color.r * 0.75, base_color.g * 0.75, base_color.b * 0.75, 0.3)
				var bottom_h := bg_rect.size.y * 0.4
				var bottom_rect := Rect2(
					Vector2(bg_rect.position.x, bg_rect.position.y + bg_rect.size.y - bottom_h),
					Vector2(bg_rect.size.x, bottom_h))
				_draw_rounded_rect_piece(bottom_rect, dark_color, true, 1.0, 0.3)

				# Top shine
				var shine_rect := Rect2(
					bg_rect.position + Vector2(bg_rect.size.x * 0.15, bg_rect.size.y * 0.08),
					Vector2(bg_rect.size.x * 0.7, bg_rect.size.y * 0.35))
				_draw_rounded_rect_piece(shine_rect, Color(1.0, 1.0, 1.0, 0.30), true, 1.0, 0.5)

				# Specular dot
				var spec_center := bg_rect.position + Vector2(bg_rect.size.x * 0.28, bg_rect.size.y * 0.25)
				var spec_radius := Vector2(bg_rect.size.x * 0.08, bg_rect.size.y * 0.08)
				_draw_ellipse_piece(spec_center, spec_radius, Color(1.0, 1.0, 1.0, 0.6))

				# Rim light
				_draw_rounded_rect_piece(bg_rect, Color(1.0, 1.0, 1.0, 0.08), false, 1.0, 0.35)

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
