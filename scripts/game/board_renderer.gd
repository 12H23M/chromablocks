extends Control

const CellScene := preload("res://scenes/game/cell.tscn")
const ClearParticlesScript := preload("res://scripts/game/clear_particles.gd")
const CORNER_RADIUS := 4
const BORDER_WIDTH := 1.5

var _cells: Array = []  # Array[Array[CellView]] — [y][x]
var _cell_size: float = 36.0
var _bg_style: StyleBoxFlat

func initialize() -> void:
	_cells.clear()
	for child in get_children():
		child.queue_free()

	clip_children = Control.CLIP_CHILDREN_AND_DRAW
	_setup_styles()
	_calculate_cell_size()

	for y in GameConstants.BOARD_ROWS:
		var row: Array = []
		for x in GameConstants.BOARD_COLUMNS:
			var cell_node := CellScene.instantiate()
			add_child(cell_node)
			cell_node.set_empty()
			row.append(cell_node)
		_cells.append(row)

	_layout_cells()

func _setup_styles() -> void:
	_bg_style = StyleBoxFlat.new()
	_bg_style.bg_color = AppColors.BOARD_BG
	_bg_style.corner_radius_top_left = CORNER_RADIUS
	_bg_style.corner_radius_top_right = CORNER_RADIUS
	_bg_style.corner_radius_bottom_left = CORNER_RADIUS
	_bg_style.corner_radius_bottom_right = CORNER_RADIUS
	_bg_style.border_width_left = int(BORDER_WIDTH)
	_bg_style.border_width_top = int(BORDER_WIDTH)
	_bg_style.border_width_right = int(BORDER_WIDTH)
	_bg_style.border_width_bottom = int(BORDER_WIDTH)
	_bg_style.border_color = AppColors.BOARD_BORDER

func _calculate_cell_size() -> void:
	var viewport_size := get_viewport_rect().size
	var available_width := viewport_size.x - 32.0
	var available_height := viewport_size.y - 288.0

	var max_by_width := floorf(available_width / float(GameConstants.BOARD_COLUMNS))
	var max_by_height := floorf(available_height / float(GameConstants.BOARD_ROWS))

	_cell_size = minf(max_by_width, max_by_height)

func _layout_cells() -> void:
	var board_pixel_size := _cell_size * GameConstants.BOARD_COLUMNS
	custom_minimum_size = Vector2(board_pixel_size, board_pixel_size)
	size = Vector2(board_pixel_size, board_pixel_size)

	for y in GameConstants.BOARD_ROWS:
		for x in GameConstants.BOARD_COLUMNS:
			var cell: Control = _cells[y][x]
			cell.position = Vector2(x * _cell_size, y * _cell_size)
			cell.size = Vector2(_cell_size, _cell_size)

	queue_redraw()

func get_cell_size() -> float:
	return _cell_size

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _cells.size() > 0:
		_calculate_cell_size()
		_layout_cells()

func update_from_state(board: BoardState) -> void:
	for y in board.rows:
		for x in board.columns:
			var cell_data: Dictionary = board.grid[y][x]
			if cell_data["occupied"]:
				_cells[y][x].set_filled(cell_data["color"])
			else:
				_cells[y][x].set_empty()

func show_highlight(gx: int, gy: int, piece: BlockPiece, can_place: bool) -> void:
	clear_highlights()
	for cell_pos in piece.occupied_cells_at(gx, gy):
		if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
		   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
			_cells[cell_pos.y][cell_pos.x].set_highlight(can_place)

func clear_highlights() -> void:
	for y in GameConstants.BOARD_ROWS:
		for x in GameConstants.BOARD_COLUMNS:
			_cells[y][x].clear_highlight()

func play_line_clear_effect(rows: Array, cols: Array) -> void:
	# Collect cell positions and colors for particles before clearing
	var particle_positions: Array = []
	var particle_colors: Array = []

	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			particle_positions.append(Vector2(x * _cell_size, row * _cell_size))
			var cell_color: int = _cells[row][x]._color
			if cell_color >= 0:
				particle_colors.append(AppColors.get_block_light_color(cell_color))
			else:
				particle_colors.append(Color.WHITE)

	for col in cols:
		for y in GameConstants.BOARD_ROWS:
			var pos := Vector2(col * _cell_size, y * _cell_size)
			if pos not in particle_positions:
				particle_positions.append(pos)
				var cell_color: int = _cells[y][col]._color
				if cell_color >= 0:
					particle_colors.append(AppColors.get_block_light_color(cell_color))
				else:
					particle_colors.append(Color.WHITE)

	# Spawn particle burst (top_level bypasses board's clip_children)
	if particle_positions.size() > 0:
		var particles := Control.new()
		particles.set_script(ClearParticlesScript)
		particles.top_level = true
		add_child(particles)
		particles.global_position = global_position
		particles.size = get_viewport_rect().size
		particles.emit_at(particle_positions, _cell_size, particle_colors)

	# Cell flash animations
	var delay := 0.0
	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			_cells[row][x].play_clear_flash(
				GameConstants.LINE_CLEAR_ANIM_DURATION, delay)
			delay += 0.02
	for col in cols:
		delay = 0.0
		for y in GameConstants.BOARD_ROWS:
			_cells[y][col].play_clear_flash(
				GameConstants.LINE_CLEAR_ANIM_DURATION, delay)
			delay += 0.02

func play_color_match_effect(groups: Array) -> void:
	for group in groups:
		var delay := 0.0
		for cell_pos in group:
			if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
			   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
				_cells[cell_pos.y][cell_pos.x].play_color_match_flash(
					GameConstants.COLOR_MATCH_ANIM_DURATION, delay)
				delay += 0.03

func world_to_grid(local_pos: Vector2) -> Vector2i:
	var gx := int(local_pos.x / _cell_size)
	var gy := int(local_pos.y / _cell_size)
	return Vector2i(gx, gy)

func _draw() -> void:
	# Draw dark rounded background with border
	if _bg_style:
		draw_style_box(_bg_style, Rect2(Vector2.ZERO, size))

	# Draw grid lines
	for i in range(1, GameConstants.BOARD_COLUMNS):
		var x := i * _cell_size
		draw_line(Vector2(x, 0), Vector2(x, size.y), AppColors.GRID_LINE, 1.0)
	for i in range(1, GameConstants.BOARD_ROWS):
		var y := i * _cell_size
		draw_line(Vector2(0, y), Vector2(size.x, y), AppColors.GRID_LINE, 1.0)
