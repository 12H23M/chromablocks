extends VBoxContainer

signal piece_drag_started(piece_node: Control)
signal piece_drag_moved(piece_node: Control, global_pos: Vector2)
signal piece_drag_ended(piece_node: Control, global_pos: Vector2)
signal hold_pressed()

const DraggablePieceScene := preload("res://scenes/game/draggable_piece.tscn")
const CARD_RADIUS := 16
const CARD_BORDER_WIDTH := 1.5
const PLATE_RADIUS := 18

var _tray_cell_size: float = 28.0
var _active_pieces: Array = []
var _card_style: StyleBoxFlat
var _plate_style: StyleBoxFlat
var _hold_slot: HoldSlot
var _next_preview: NextPreview

@onready var _main_row: HBoxContainer = $MainRow
@onready var _pieces_container: HBoxContainer = $MainRow/PieceSlots

func _ready() -> void:
	_setup_card_style()
	_setup_plate_style()
	_create_hold_slot()
	_create_next_preview()
	# Hold and next preview are now active

func _setup_card_style() -> void:
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0, 0, 0, 0)

func _setup_plate_style() -> void:
	_plate_style = StyleBoxFlat.new()
	_plate_style.bg_color = Color(0, 0, 0, 0)

func _create_hold_slot() -> void:
	_hold_slot = HoldSlot.new()
	_hold_slot.custom_minimum_size = Vector2(70, 80)
	_hold_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hold_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	_hold_slot.gui_input.connect(_on_hold_slot_input)
	_main_row.add_child(_hold_slot)
	_main_row.move_child(_hold_slot, 0)

func _create_next_preview() -> void:
	_next_preview = NextPreview.new()
	_next_preview.custom_minimum_size = Vector2(0, 40)
	_next_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_next_preview)

func update_next_preview(pieces: Array) -> void:
	if _next_preview:
		_next_preview.preview_pieces = pieces
		_next_preview.cell_size = _tray_cell_size
		_next_preview.queue_redraw()

func _on_hold_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hold_slot.play_tap_bounce()
		hold_pressed.emit()

func set_cell_size(board_cell_size: float) -> void:
	_tray_cell_size = board_cell_size * 0.70
	if _pieces_container:
		_pieces_container.custom_minimum_size.y = _tray_cell_size * 3 + 24
	if _hold_slot:
		_hold_slot.cell_size = _tray_cell_size
		_hold_slot.custom_minimum_size = Vector2(70, maxf(80, _tray_cell_size * 3 + 24))
		_hold_slot.queue_redraw()
	if _next_preview:
		_next_preview.cell_size = _tray_cell_size
		_next_preview.queue_redraw()

func update_hold_display(piece: BlockPiece, enabled: bool, animate: bool = false) -> void:
	if _hold_slot:
		_hold_slot.held_piece = piece
		_hold_slot.enabled = enabled
		_hold_slot.queue_redraw()
		if animate:
			_hold_slot.play_swap_animation(enabled)
		else:
			_hold_slot.modulate.a = 1.0 if enabled else 0.4

func populate_tray(pieces: Array, animate: bool = false) -> void:
	clear_tray()
	for i in pieces.size():
		var piece_node := DraggablePieceScene.instantiate()
		_pieces_container.add_child(piece_node)
		piece_node.setup(pieces[i], i, _tray_cell_size)
		piece_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		piece_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		piece_node.drag_started.connect(_on_drag_started)
		piece_node.drag_moved.connect(_on_drag_moved)
		piece_node.drag_ended.connect(_on_drag_ended)
		_active_pieces.append(piece_node)
	_pieces_container.queue_redraw()

	if animate:
		_animate_tray_pieces()

func _animate_tray_pieces() -> void:
	for i in _active_pieces.size():
		var piece: Control = _active_pieces[i]
		var target_y: float = piece.position.y
		piece.modulate.a = 0.0
		piece.position.y += 30
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(piece, "modulate:a", 1.0, 0.2) \
			.set_ease(Tween.EASE_OUT).set_delay(0.05 * i)
		tween.tween_property(piece, "position:y", target_y, 0.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
			.set_delay(0.05 * i)

func remove_piece_at(index: int) -> void:
	if index >= 0 and index < _active_pieces.size():
		var piece: Control = _active_pieces[index]
		piece.remove_from_tray()
		_active_pieces.remove_at(index)
		for i in _active_pieces.size():
			_active_pieces[i].tray_index = i
	_pieces_container.queue_redraw()

func clear_tray() -> void:
	_active_pieces.clear()
	if _pieces_container:
		while _pieces_container.get_child_count() > 0:
			var child := _pieces_container.get_child(0)
			_pieces_container.remove_child(child)
			child.queue_free()
		_pieces_container.queue_redraw()

func get_pieces_container() -> HBoxContainer:
	return _pieces_container

func add_placeholder(placeholder: Control, index: int) -> void:
	_pieces_container.add_child(placeholder)
	_pieces_container.move_child(placeholder, index)

func remove_placeholder(placeholder: Control) -> void:
	_pieces_container.remove_child(placeholder)
	placeholder.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		queue_redraw()
		if _pieces_container:
			_pieces_container.queue_redraw()

func _draw() -> void:
	if _pieces_container == null:
		return

	# Draw plate background behind all pieces
	if _plate_style and _pieces_container.get_child_count() > 0:
		var plate_rect := Rect2(
			_pieces_container.position + _main_row.position + Vector2(-8, -14),
			_pieces_container.size + Vector2(16, 28))
		draw_style_box(_plate_style, plate_rect)

		# Draw subtle slot dividers between pieces
		var children := _pieces_container.get_children()
		for i in range(1, children.size()):
			var child: Control = children[i]
			if not is_instance_valid(child) or not child.visible:
				continue
			var divider_x := _main_row.position.x + _pieces_container.position.x + child.position.x - 8.0
			var divider_top := _main_row.position.y + _pieces_container.position.y + 4.0
			var divider_bottom := _main_row.position.y + _pieces_container.position.y + _pieces_container.size.y - 4.0
			draw_line(
				Vector2(divider_x, divider_top),
				Vector2(divider_x, divider_bottom),
				Color(1, 1, 1, 0.04), 1.0)

func _on_drag_started(piece_node: Control) -> void:
	piece_drag_started.emit(piece_node)

func _on_drag_moved(piece_node: Control, pos: Vector2) -> void:
	piece_drag_moved.emit(piece_node, pos)

func _on_drag_ended(piece_node: Control, pos: Vector2) -> void:
	piece_drag_ended.emit(piece_node, pos)


# ── Hold Slot inner class ──

class HoldSlot extends Control:
	var held_piece: BlockPiece = null
	var enabled: bool = true
	var cell_size: float = 28.0

	const SLOT_SIZE := 60.0
	const PIECE_SCALE := 0.40
	const BG_COLOR := Color(0.118, 0.118, 0.290, 0.6)  # #1E1E4A alpha 0.6
	const BORDER_COLOR := Color(0.227, 0.227, 0.431)  # #3A3A6E
	const LABEL_COLOR := Color(0.533, 0.533, 0.667, 0.6)  # #8888AA alpha 0.6
	const CORNER_RADIUS := 12.0
	const BORDER_WIDTH := 1.5
	const DASH_LENGTH := 5.0
	const GAP_LENGTH := 3.0
	const EMPTY_BORDER_COLOR := Color(0.227, 0.227, 0.431, 0.3)  # #3A3A6E alpha 0.3
	const EMPTY_BORDER_WIDTH := 2.0

	static var _fredoka_font: Font = null

	static func _get_font() -> Font:
		if _fredoka_font == null:
			_fredoka_font = load("res://assets/fonts/Fredoka-Bold.ttf")
		return _fredoka_font

	func play_tap_bounce() -> void:
		var tween := create_tween()
		tween.set_speed_scale(1.0 / Engine.time_scale if Engine.time_scale > 0.0 else 1.0)
		tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.0)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	func play_swap_animation(is_enabled: bool) -> void:
		var end_alpha: float = 1.0 if is_enabled else 0.4
		var tween := create_tween()
		tween.set_speed_scale(1.0 / Engine.time_scale if Engine.time_scale > 0.0 else 1.0)
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.075) \
			.set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate:a", 0.2, 0.075)
		tween.chain()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.075) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "modulate:a", end_alpha, 0.075)

	func _draw() -> void:
		var slot_rect := Rect2(
			Vector2((size.x - SLOT_SIZE) / 2.0, (size.y - SLOT_SIZE) / 2.0 + 6),
			Vector2(SLOT_SIZE, SLOT_SIZE))

		# Label above slot: "HOLD" or "USED"
		var font: Font = _get_font()
		var label_text := "USED" if not enabled else "HOLD"
		var font_size := 11
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var label_x := slot_rect.position.x + (SLOT_SIZE - text_size.x) / 2.0
		var label_y := slot_rect.position.y - 4.0
		draw_string(font, Vector2(label_x, label_y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_COLOR)

		# Background
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = BG_COLOR
		bg_style.corner_radius_top_left = int(CORNER_RADIUS)
		bg_style.corner_radius_top_right = int(CORNER_RADIUS)
		bg_style.corner_radius_bottom_left = int(CORNER_RADIUS)
		bg_style.corner_radius_bottom_right = int(CORNER_RADIUS)
		draw_style_box(bg_style, slot_rect)

		# Border: dashed when empty, solid when piece held
		if held_piece == null:
			_draw_dashed_rounded_rect(slot_rect, EMPTY_BORDER_COLOR, EMPTY_BORDER_WIDTH)
		else:
			var border_style := StyleBoxFlat.new()
			border_style.bg_color = Color(0, 0, 0, 0)
			border_style.border_color = BORDER_COLOR
			border_style.border_width_top = int(BORDER_WIDTH)
			border_style.border_width_bottom = int(BORDER_WIDTH)
			border_style.border_width_left = int(BORDER_WIDTH)
			border_style.border_width_right = int(BORDER_WIDTH)
			border_style.corner_radius_top_left = int(CORNER_RADIUS)
			border_style.corner_radius_top_right = int(CORNER_RADIUS)
			border_style.corner_radius_bottom_left = int(CORNER_RADIUS)
			border_style.corner_radius_bottom_right = int(CORNER_RADIUS)
			draw_style_box(border_style, slot_rect)

		# Draw held piece
		if held_piece != null:
			_draw_piece_preview(slot_rect)

	func _draw_piece_preview(slot_rect: Rect2) -> void:
		if held_piece == null:
			return
		var draw_cell: float = cell_size * PIECE_SCALE
		var inset := 1.5
		var piece_w: float = held_piece.width * draw_cell
		var piece_h: float = held_piece.height * draw_cell
		var offset_x := slot_rect.position.x + (slot_rect.size.x - piece_w) / 2.0
		var offset_y := slot_rect.position.y + (slot_rect.size.y - piece_h) / 2.0

		var base_color := AppColors.get_block_color(held_piece.color)

		for row_idx in held_piece.shape.size():
			for col_idx in held_piece.shape[row_idx].size():
				if held_piece.shape[row_idx][col_idx] == 1:
					var cx: float = offset_x + col_idx * draw_cell
					var cy: float = offset_y + row_idx * draw_cell
					var bg_rect := Rect2(
						Vector2(cx + inset, cy + inset),
						Vector2(draw_cell - inset * 2, draw_cell - inset * 2))
					DrawUtils.draw_bubble_block(self, bg_rect, base_color, 0.12, 1.5)

	func _draw_dashed_rounded_rect(rect: Rect2, color: Color, width: float) -> void:
		var r := CORNER_RADIUS
		var x1 := rect.position.x
		var y1 := rect.position.y
		var x2 := rect.end.x
		var y2 := rect.end.y

		# Top edge
		_draw_dashed_line(Vector2(x1 + r, y1), Vector2(x2 - r, y1), color, width)
		# Right edge
		_draw_dashed_line(Vector2(x2, y1 + r), Vector2(x2, y2 - r), color, width)
		# Bottom edge
		_draw_dashed_line(Vector2(x2 - r, y2), Vector2(x1 + r, y2), color, width)
		# Left edge
		_draw_dashed_line(Vector2(x1, y2 - r), Vector2(x1, y1 + r), color, width)

		# Corner arcs (simplified as small lines)
		var steps := 4
		for i in steps:
			var a1: float = PI * 1.5 + (PI * 0.5 * float(i) / float(steps))
			var a2: float = PI * 1.5 + (PI * 0.5 * float(i + 1) / float(steps))
			var c := Vector2(x2 - r, y1 + r)
			draw_line(c + Vector2(cos(a1), sin(a1)) * r, c + Vector2(cos(a2), sin(a2)) * r, color, width)
		for i in steps:
			var a1: float = 0.0 + (PI * 0.5 * float(i) / float(steps))
			var a2: float = 0.0 + (PI * 0.5 * float(i + 1) / float(steps))
			var c := Vector2(x2 - r, y2 - r)
			draw_line(c + Vector2(cos(a1), sin(a1)) * r, c + Vector2(cos(a2), sin(a2)) * r, color, width)
		for i in steps:
			var a1: float = PI * 0.5 + (PI * 0.5 * float(i) / float(steps))
			var a2: float = PI * 0.5 + (PI * 0.5 * float(i + 1) / float(steps))
			var c := Vector2(x1 + r, y2 - r)
			draw_line(c + Vector2(cos(a1), sin(a1)) * r, c + Vector2(cos(a2), sin(a2)) * r, color, width)
		for i in steps:
			var a1: float = PI + (PI * 0.5 * float(i) / float(steps))
			var a2: float = PI + (PI * 0.5 * float(i + 1) / float(steps))
			var c := Vector2(x1 + r, y1 + r)
			draw_line(c + Vector2(cos(a1), sin(a1)) * r, c + Vector2(cos(a2), sin(a2)) * r, color, width)

	func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
		var total_length := from.distance_to(to)
		if total_length < 0.1:
			return
		var dir := (to - from).normalized()
		var drawn := 0.0
		var drawing := true
		while drawn < total_length:
			var seg: float = DASH_LENGTH if drawing else GAP_LENGTH
			seg = minf(seg, total_length - drawn)
			if drawing:
				draw_line(from + dir * drawn, from + dir * (drawn + seg), color, width)
			drawn += seg
			drawing = not drawing


# ── Next Tray Preview inner class ──

class NextPreview extends Control:
	var preview_pieces: Array = []
	var cell_size: float = 28.0

	const PREVIEW_SCALE := 0.30
	const BG_COLOR := Color(0.118, 0.118, 0.290, 0.4)  # #1E1E4A alpha 0.4
	const LABEL_COLOR := Color(0.533, 0.533, 0.667, 0.5)  # #8888AA alpha 0.5
	const PREVIEW_OPACITY := 0.5
	const CORNER_RADIUS := 10.0

	static var _fredoka_font: Font = null

	static func _get_font() -> Font:
		if _fredoka_font == null:
			_fredoka_font = load("res://assets/fonts/Fredoka-Bold.ttf")
		return _fredoka_font

	func _draw() -> void:
		if preview_pieces.is_empty():
			return

		# Subtle separator line at top
		draw_line(Vector2(8, 0), Vector2(size.x - 8, 0), Color(1, 1, 1, 0.06), 1.0)

		# Background rounded rect
		var bg_rect := Rect2(Vector2(0, 2), Vector2(size.x, size.y - 2))
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = BG_COLOR
		bg_style.corner_radius_top_left = int(CORNER_RADIUS)
		bg_style.corner_radius_top_right = int(CORNER_RADIUS)
		bg_style.corner_radius_bottom_left = int(CORNER_RADIUS)
		bg_style.corner_radius_bottom_right = int(CORNER_RADIUS)
		draw_style_box(bg_style, bg_rect)

		# "NEXT" label
		var font: Font = _get_font()
		var font_size := 10
		var label_text := "NEXT"
		var label_y := bg_rect.position.y + (bg_rect.size.y + font_size) / 2.0 - 1.0
		draw_string(font, Vector2(8, label_y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_COLOR)

		# Draw mini pieces in a row
		var draw_cell: float = cell_size * PREVIEW_SCALE
		var inset := 1.0
		var label_width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 16.0
		var piece_start_x := label_width
		var piece_y := bg_rect.position.y

		for piece_idx in preview_pieces.size():
			var piece: BlockPiece = preview_pieces[piece_idx]
			if piece == null:
				continue
			var piece_w: float = piece.width * draw_cell
			var piece_h: float = piece.height * draw_cell
			var offset_y := piece_y + (bg_rect.size.y - piece_h) / 2.0

			var base_color := AppColors.get_block_color(piece.color)
			base_color.a = PREVIEW_OPACITY

			for row_idx in piece.shape.size():
				for col_idx in piece.shape[row_idx].size():
					if piece.shape[row_idx][col_idx] == 1:
						var cx: float = piece_start_x + col_idx * draw_cell
						var cy: float = offset_y + row_idx * draw_cell
						var bg_cell_rect := Rect2(
							Vector2(cx + inset, cy + inset),
							Vector2(draw_cell - inset * 2, draw_cell - inset * 2))
						DrawUtils.draw_bubble_block(self, bg_cell_rect, base_color, 0.08, 1.0)

			piece_start_x += piece_w + 12.0
