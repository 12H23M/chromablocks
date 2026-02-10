extends HBoxContainer

signal piece_drag_started(piece_node: Control)
signal piece_drag_moved(piece_node: Control, global_pos: Vector2)
signal piece_drag_ended(piece_node: Control, global_pos: Vector2)

const DraggablePieceScene := preload("res://scenes/game/draggable_piece.tscn")
const CARD_RADIUS := 16
const CARD_BORDER_WIDTH := 1.5

var _tray_cell_size: float = 28.0
var _active_pieces: Array = []
var _card_style: StyleBoxFlat

func _ready() -> void:
	_setup_card_style()

func _setup_card_style() -> void:
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = AppColors.CARD_SURFACE
	_card_style.corner_radius_top_left = CARD_RADIUS
	_card_style.corner_radius_top_right = CARD_RADIUS
	_card_style.corner_radius_bottom_left = CARD_RADIUS
	_card_style.corner_radius_bottom_right = CARD_RADIUS
	_card_style.border_width_left = int(CARD_BORDER_WIDTH)
	_card_style.border_width_top = int(CARD_BORDER_WIDTH)
	_card_style.border_width_right = int(CARD_BORDER_WIDTH)
	_card_style.border_width_bottom = int(CARD_BORDER_WIDTH)
	_card_style.border_color = AppColors.CARD_BORDER

func set_cell_size(board_cell_size: float) -> void:
	_tray_cell_size = board_cell_size * 0.7
	custom_minimum_size.y = _tray_cell_size * 3 + 24

func populate_tray(pieces: Array) -> void:
	clear_tray()
	for i in pieces.size():
		var piece_node := DraggablePieceScene.instantiate()
		add_child(piece_node)
		piece_node.setup(pieces[i], i, _tray_cell_size)
		piece_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		piece_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		piece_node.drag_started.connect(_on_drag_started)
		piece_node.drag_moved.connect(_on_drag_moved)
		piece_node.drag_ended.connect(_on_drag_ended)
		_active_pieces.append(piece_node)
	queue_redraw()

func remove_piece_at(index: int) -> void:
	if index >= 0 and index < _active_pieces.size():
		var piece: Control = _active_pieces[index]
		piece.remove_from_tray()
		_active_pieces.remove_at(index)
		for i in _active_pieces.size():
			_active_pieces[i].tray_index = i
	queue_redraw()

func clear_tray() -> void:
	_active_pieces.clear()
	while get_child_count() > 0:
		var child := get_child(0)
		remove_child(child)
		child.queue_free()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		queue_redraw()

func _draw() -> void:
	if _card_style == null:
		return
	for child in get_children():
		if not is_instance_valid(child) or not child.visible:
			continue
		draw_style_box(_card_style, Rect2(child.position, child.size))

func _on_drag_started(piece_node: Control) -> void:
	piece_drag_started.emit(piece_node)

func _on_drag_moved(piece_node: Control, pos: Vector2) -> void:
	piece_drag_moved.emit(piece_node, pos)

func _on_drag_ended(piece_node: Control, pos: Vector2) -> void:
	piece_drag_ended.emit(piece_node, pos)
