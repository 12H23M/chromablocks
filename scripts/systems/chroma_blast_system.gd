class_name ChromaBlastSystem

## Check cleared lines for blast triggers BEFORE clearing them.
## A blast triggers when BLAST_THRESHOLD+ cells in a line share the same color.
## Returns: {blast_colors: Array[int], trigger_lines: Array[Dictionary]}
static func check_blast(board: BoardState, rows: Array, cols: Array) -> Dictionary:
	var blast_colors: Array = []
	var trigger_lines: Array = []

	if not GameConstants.CHROMA_BLAST_ENABLED:
		return {"blast_colors": blast_colors, "trigger_lines": trigger_lines}

	var threshold: int = GameConstants.CHROMA_BLAST_THRESHOLD

	for y in rows:
		var color_counts := {}
		for x in board.columns:
			var c: int = board.grid[y][x]["color"]
			if c < 0:
				continue
			color_counts[c] = color_counts.get(c, 0) + 1
		for c in color_counts:
			if color_counts[c] >= threshold and c not in blast_colors:
				blast_colors.append(c)
				trigger_lines.append({"type": "row", "index": y, "color": c})

	for x in cols:
		var color_counts := {}
		for y_idx in board.rows:
			var c: int = board.grid[y_idx][x]["color"]
			if c < 0:
				continue
			color_counts[c] = color_counts.get(c, 0) + 1
		for c in color_counts:
			if color_counts[c] >= threshold and c not in blast_colors:
				blast_colors.append(c)
				trigger_lines.append({"type": "col", "index": x, "color": c})

	return {"blast_colors": blast_colors, "trigger_lines": trigger_lines}


## Check which rows/cols on a virtual board meet blast conditions.
## Lightweight — no board mutation, just color counting.
## Returns: {"rows": Array[int], "cols": Array[int]}
static func check_blast_potential(board: BoardState) -> Dictionary:
	var blast_rows: Array = []
	var blast_cols: Array = []

	if not GameConstants.CHROMA_BLAST_ENABLED:
		return {"rows": blast_rows, "cols": blast_cols}

	var threshold: int = GameConstants.CHROMA_BLAST_THRESHOLD

	for y in board.rows:
		var color_counts := {}
		for x in board.columns:
			if not board.grid[y][x]["occupied"]:
				continue
			var c: int = board.grid[y][x]["color"]
			if c < 0:
				continue
			color_counts[c] = color_counts.get(c, 0) + 1
		for c in color_counts:
			if color_counts[c] >= threshold:
				blast_rows.append(y)
				break

	for x in board.columns:
		var color_counts := {}
		for y_idx in board.rows:
			if not board.grid[y_idx][x]["occupied"]:
				continue
			var c: int = board.grid[y_idx][x]["color"]
			if c < 0:
				continue
			color_counts[c] = color_counts.get(c, 0) + 1
		for c in color_counts:
			if color_counts[c] >= threshold:
				blast_cols.append(x)
				break

	return {"rows": blast_rows, "cols": blast_cols}


## Execute blast: remove all cells of given colors from the board.
## Returns: {board, cells_removed: int, removed_positions: Array[Vector2i]}
static func execute_blast(board: BoardState, blast_colors: Array) -> Dictionary:
	var removed: Array = []
	var new_grid := board._copy_grid()
	for y in board.rows:
		for x in board.columns:
			if new_grid[y][x]["occupied"] and new_grid[y][x]["color"] in blast_colors:
				removed.append(Vector2i(x, y))
				new_grid[y][x] = BoardState._empty_cell()
	return {
		"board": BoardState.new(board.columns, board.rows, new_grid),
		"cells_removed": removed.size(),
		"removed_positions": removed,
	}
