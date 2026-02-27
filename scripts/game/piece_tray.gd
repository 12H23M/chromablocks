extends VBoxContainer

signal piece_drag_started(piece_node: Control)
signal piece_drag_moved(piece_node: Control, global_pos: Vector2)
signal piece_drag_ended(piece_node: Control, global_pos: Vector2)

const DraggablePieceScene := preload("res://scenes/game/draggable_piece.tscn")
const CARD_RADIUS := 16
const CARD_BORDER_WIDTH := 1.5
const PLATE_RADIUS := 18

var _tray_cell_size: float = 28.0
var _active_pieces: Array = []
var _card_style: StyleBoxFlat
var _plate_style: StyleBoxFlat

@onready var _pieces_container: HBoxContainer = $PieceSlots

func _ready() -> void:
	_setup_card_style()
	_setup_plate_style()

func _setup_card_style() -> void:
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0, 0, 0, 0)  # Transparent — no box behind tray

func _setup_plate_style() -> void:
	_plate_style = StyleBoxFlat.new()
	_plate_style.bg_color = Color(0, 0, 0, 0)  # Transparent — no box behind pieces

func set_cell_size(board_cell_size: float) -> void:
	_tray_cell_size = board_cell_size * 0.70
	if _pieces_container:
		_pieces_container.custom_minimum_size.y = _tray_cell_size * 3 + 24

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
			_pieces_container.position + Vector2(-8, -14),
			_pieces_container.size + Vector2(16, 28))
		draw_style_box(_plate_style, plate_rect)

		# Draw subtle slot dividers between pieces
		var children := _pieces_container.get_children()
		for i in range(1, children.size()):
			var child: Control = children[i]
			if not is_instance_valid(child) or not child.visible:
				continue
			var divider_x := _pieces_container.position.x + child.position.x - 8.0
			var divider_top := _pieces_container.position.y + 4.0
			var divider_bottom := _pieces_container.position.y + _pieces_container.size.y - 4.0
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
