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

@onready var _main_row: HBoxContainer = $MainRow
@onready var _pieces_container: HBoxContainer = $MainRow/PieceSlots

func _ready() -> void:
	_setup_card_style()
	_setup_plate_style()
	_create_hold_slot()

func _setup_card_style() -> void:
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0, 0, 0, 0)

func _setup_plate_style() -> void:
	_plate_style = StyleBoxFlat.new()
	_plate_style.bg_color = Color(0, 0, 0, 0)

func _create_hold_slot() -> void:
	_hold_slot = HoldSlot.new()
	_hold_slot.custom_minimum_size = Vector2(70, 0)
	_hold_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hold_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	_hold_slot.gui_input.connect(_on_hold_slot_input)
	_main_row.add_child(_hold_slot)
	_main_row.move_child(_hold_slot, 0)

func _on_hold_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SoundManager.play_sfx("button_press")
		hold_pressed.emit()

func set_cell_size(board_cell_size: float) -> void:
	_tray_cell_size = board_cell_size * 0.70
	if _pieces_container:
		_pieces_container.custom_minimum_size.y = _tray_cell_size * 3 + 24
	if _hold_slot:
		_hold_slot.cell_size = _tray_cell_size
		_hold_slot.custom_minimum_size = Vector2(70, _tray_cell_size * 3 + 24)
		_hold_slot.queue_redraw()

func update_hold_display(piece: BlockPiece, enabled: bool) -> void:
	if _hold_slot:
		_hold_slot.held_piece = piece
		_hold_slot.enabled = enabled
		_hold_slot.queue_redraw()

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
	const LABEL_COLOR := Color(0.533, 0.533, 0.667)  # #8888AA
	const CORNER_RADIUS := 12.0
	const BORDER_WIDTH := 1.5
	const DASH_LENGTH := 5.0
	const GAP_LENGTH := 3.0

	func _draw() -> void:
		var slot_rect := Rect2(
			Vector2((size.x - SLOT_SIZE) / 2.0, (size.y - SLOT_SIZE) / 2.0 + 6),
			Vector2(SLOT_SIZE, SLOT_SIZE))

		# "HOLD" label above slot
		var font := ThemeDB.fallback_font
		var label_text := "HOLD"
		var font_size := 9
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

		# Border (dashed)
		_draw_dashed_rounded_rect(slot_rect, BORDER_COLOR, BORDER_WIDTH)

		# Draw held piece or empty indicator
		if held_piece != null:
			_draw_piece_preview(slot_rect)

		# Disabled overlay
		if not enabled:
			var overlay_style := StyleBoxFlat.new()
			overlay_style.bg_color = Color(0, 0, 0, 0.4)
			overlay_style.corner_radius_top_left = int(CORNER_RADIUS)
			overlay_style.corner_radius_top_right = int(CORNER_RADIUS)
			overlay_style.corner_radius_bottom_left = int(CORNER_RADIUS)
			overlay_style.corner_radius_bottom_right = int(CORNER_RADIUS)
			draw_style_box(overlay_style, slot_rect)

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
		# Simplified dashed border — draw dashed lines along each edge
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
