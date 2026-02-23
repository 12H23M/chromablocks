class_name BoardState

var columns: int
var rows: int
var grid: Array  # Array[Array[Dictionary]] — {occupied, color, age, special_type}


func _init(p_cols: int = 8, p_rows: int = 8, p_grid: Array = []) -> void:
	columns = p_cols
	rows = p_rows
	if p_grid.is_empty():
		grid = _create_empty_grid()
	else:
		grid = p_grid
		_normalize_grid()


## Ensure all cells have age and special_type fields (backward compat with old saves)
func _normalize_grid() -> void:
	for y in rows:
		for x in columns:
			var cell: Dictionary = grid[y][x]
			if not cell.has("age"):
				cell["age"] = 0
			if not cell.has("special_type"):
				cell["special_type"] = GameConstants.SPECIAL_TILE_NONE


func _create_empty_grid() -> Array:
	var g: Array = []
	for y in rows:
		var row: Array = []
		for x in columns:
			row.append(_empty_cell())
		g.append(row)
	return g


static func _empty_cell() -> Dictionary:
	return {"occupied": false, "color": -1, "age": 0, "special_type": GameConstants.SPECIAL_TILE_NONE}


var is_empty: bool:
	get:
		for y in rows:
			for x in columns:
				if grid[y][x]["occupied"]:
					return false
		return true


func fill_ratio() -> float:
	var occupied := 0
	for y in rows:
		for x in columns:
			if grid[y][x]["occupied"]:
				occupied += 1
	return float(occupied) / float(rows * columns)


func is_cell_occupied(x: int, y: int) -> bool:
	if x < 0 or x >= columns or y < 0 or y >= rows:
		return true
	return grid[y][x]["occupied"]


func can_place_piece_at(piece: BlockPiece, gx: int, gy: int) -> bool:
	for cell in piece.occupied_cells_at(gx, gy):
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
			return false
		if grid[cell.y][cell.x]["occupied"]:
			return false
	return true


func place_piece(piece: BlockPiece, gx: int, gy: int) -> BoardState:
	var new_grid := _copy_grid()
	for cell in piece.occupied_cells_at(gx, gy):
		if cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows:
			new_grid[cell.y][cell.x] = {
				"occupied": true, "color": piece.color,
				"age": 0, "special_type": GameConstants.SPECIAL_TILE_NONE
			}
	return BoardState.new(columns, rows, new_grid)


func get_completed_rows() -> Array:
	var completed: Array = []
	for y in rows:
		var full := true
		for x in columns:
			if not grid[y][x]["occupied"]:
				full = false
				break
		if full:
			completed.append(y)
	return completed


func get_completed_columns() -> Array:
	var completed: Array = []
	for x in columns:
		var full := true
		for y in rows:
			if not grid[y][x]["occupied"]:
				full = false
				break
		if full:
			completed.append(x)
	return completed


## Check which rows/cols would be completed if piece were placed at (gx, gy).
## Returns {"rows": Array[int], "cols": Array[int]} without allocating a new board.
func predict_completed_lines(piece: BlockPiece, gx: int, gy: int) -> Dictionary:
	var piece_cells := piece.occupied_cells_at(gx, gy)

	# Build a set of occupied cells from the piece for quick lookup
	var piece_set := {}
	for cell in piece_cells:
		if cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows:
			piece_set[Vector2i(cell.x, cell.y)] = true

	# Check rows — only need to check rows that the piece touches
	var completed_rows: Array = []
	var rows_to_check := {}
	for cell in piece_cells:
		if cell.y >= 0 and cell.y < rows:
			rows_to_check[cell.y] = true

	for row_y in rows_to_check:
		var full := true
		for x in columns:
			var pos := Vector2i(x, row_y)
			if not grid[row_y][x]["occupied"] and not piece_set.has(pos):
				full = false
				break
		if full:
			completed_rows.append(row_y)

	# Check columns — only need to check columns that the piece touches
	var completed_cols: Array = []
	var cols_to_check := {}
	for cell in piece_cells:
		if cell.x >= 0 and cell.x < columns:
			cols_to_check[cell.x] = true

	for col_x in cols_to_check:
		var full := true
		for y_idx in rows:
			var pos := Vector2i(col_x, y_idx)
			if not grid[y_idx][col_x]["occupied"] and not piece_set.has(pos):
				full = false
				break
		if full:
			completed_cols.append(col_x)

	return {"rows": completed_rows, "cols": completed_cols}


func clear_completed_lines() -> Dictionary:
	var completed_rows := get_completed_rows()
	var completed_cols := get_completed_columns()

	if completed_rows.is_empty() and completed_cols.is_empty():
		return {"board": self, "lines_cleared": 0, "rows": [], "cols": []}

	var new_grid := _copy_grid()

	for row in completed_rows:
		for x in columns:
			new_grid[row][x] = _empty_cell()

	for col in completed_cols:
		for y in rows:
			new_grid[y][col] = _empty_cell()

	var new_board := BoardState.new(columns, rows, new_grid)
	return {
		"board": new_board,
		"lines_cleared": completed_rows.size() + completed_cols.size(),
		"rows": completed_rows,
		"cols": completed_cols,
	}


func find_color_matches_threshold(threshold: int) -> Array:
	var visited: Array = []
	for y in rows:
		var row: Array = []
		for x in columns:
			row.append(false)
		visited.append(row)

	var matches: Array = []

	for y in rows:
		for x in columns:
			if visited[y][x] or not grid[y][x]["occupied"]:
				continue
			# Skip RAINBOW as BFS root — it gets absorbed by adjacent color groups
			var cell_special: int = grid[y][x].get("special_type", GameConstants.SPECIAL_TILE_NONE)
			if cell_special == GameConstants.SPECIAL_TILE_RAINBOW:
				continue
			var target_color: int = grid[y][x]["color"]
			var group: Array = []
			var stack: Array = [Vector2i(x, y)]

			while not stack.is_empty():
				var pos: Vector2i = stack.pop_back()
				if pos.x < 0 or pos.x >= columns or pos.y < 0 or pos.y >= rows:
					continue
				if visited[pos.y][pos.x]:
					continue
				if not grid[pos.y][pos.x]["occupied"]:
					continue
				var pos_special: int = grid[pos.y][pos.x].get("special_type", GameConstants.SPECIAL_TILE_NONE)
				# Match if same color OR if RAINBOW wildcard
				if grid[pos.y][pos.x]["color"] != target_color and pos_special != GameConstants.SPECIAL_TILE_RAINBOW:
					continue
				visited[pos.y][pos.x] = true
				group.append(pos)
				stack.append(Vector2i(pos.x + 1, pos.y))
				stack.append(Vector2i(pos.x - 1, pos.y))
				stack.append(Vector2i(pos.x, pos.y + 1))
				stack.append(Vector2i(pos.x, pos.y - 1))

			if group.size() >= threshold:
				matches.append(group)

	return matches


func find_color_matches() -> Array:
	var visited: Array = []
	for y in rows:
		var row: Array = []
		for x in columns:
			row.append(false)
		visited.append(row)

	var matches: Array = []

	for y in rows:
		for x in columns:
			if visited[y][x] or not grid[y][x]["occupied"]:
				continue
			var cell_special: int = grid[y][x].get("special_type", GameConstants.SPECIAL_TILE_NONE)
			if cell_special == GameConstants.SPECIAL_TILE_RAINBOW:
				continue
			var target_color: int = grid[y][x]["color"]
			var group: Array = []
			var stack: Array = [Vector2i(x, y)]

			while not stack.is_empty():
				var pos: Vector2i = stack.pop_back()
				if pos.x < 0 or pos.x >= columns or pos.y < 0 or pos.y >= rows:
					continue
				if visited[pos.y][pos.x]:
					continue
				if not grid[pos.y][pos.x]["occupied"]:
					continue
				var pos_special: int = grid[pos.y][pos.x].get("special_type", GameConstants.SPECIAL_TILE_NONE)
				if grid[pos.y][pos.x]["color"] != target_color and pos_special != GameConstants.SPECIAL_TILE_RAINBOW:
					continue
				visited[pos.y][pos.x] = true
				group.append(pos)
				stack.append(Vector2i(pos.x + 1, pos.y))
				stack.append(Vector2i(pos.x - 1, pos.y))
				stack.append(Vector2i(pos.x, pos.y + 1))
				stack.append(Vector2i(pos.x, pos.y - 1))

			if group.size() >= GameConstants.COLOR_MATCH_MIN_CELLS:
				matches.append(group)

	return matches


func remove_cells(cells: Array) -> BoardState:
	var new_grid := _copy_grid()
	for cell in cells:
		new_grid[cell.y][cell.x] = _empty_cell()
	return BoardState.new(columns, rows, new_grid)


## Return a new BoardState with all occupied cells' age incremented by 1.
func increment_ages() -> BoardState:
	var new_grid := _copy_grid()
	for y in rows:
		for x in columns:
			if new_grid[y][x]["occupied"]:
				new_grid[y][x]["age"] += 1
	return BoardState.new(columns, rows, new_grid)


func can_place_any_piece(pieces: Array) -> bool:
	for piece in pieces:
		for gy in rows:
			for gx in columns:
				if can_place_piece_at(piece, gx, gy):
					return true
	return false


func _copy_grid() -> Array:
	var new_grid: Array = []
	for y in rows:
		var row: Array = []
		for x in columns:
			row.append(grid[y][x].duplicate())
		new_grid.append(row)
	return new_grid
