class_name AutoPlayer
## AI bot that automatically places pieces for balance testing.
## Evaluates all possible placements and picks the best one.

# ── Evaluation weights ──
const W_LINE_CLEAR := 100.0      # per completable line
const W_ADJACENCY := 10.0        # per adjacent occupied neighbor
const W_HOLE_PENALTY := -20.0    # per new hole created
const W_BOTTOM_PREFER := 5.0     # per row index (higher y = more points)
const W_ISOLATED_COL := -50.0    # per isolated empty column created
const W_EDGE_BONUS := 3.0        # per cell touching board edge
const W_FILL_ROW_PROGRESS := 8.0 # per cell already in a row/col that piece contributes to

# ── Statistics ──
var stats: Dictionary = {
	"turns": 0,
	"score": 0,
	"max_combo": 0,
	"chains": 0,
	"blasts": 0,
	"lines_cleared": 0,
}


func reset_stats() -> void:
	stats = {
		"turns": 0,
		"score": 0,
		"max_combo": 0,
		"chains": 0,
		"blasts": 0,
		"lines_cleared": 0,
	}


func record_turn(game_state: GameState) -> void:
	stats["turns"] = game_state.blocks_placed
	stats["score"] = game_state.score
	if game_state.combo > stats["max_combo"]:
		stats["max_combo"] = game_state.combo
	stats["chains"] = game_state.chains_triggered
	stats["lines_cleared"] = game_state.lines_cleared


func record_blast() -> void:
	stats["blasts"] += 1


## Find the best move among all tray pieces.
## Returns {"piece": BlockPiece, "gx": int, "gy": int} or {} if no move.
func find_best_move(board: BoardState, tray_pieces: Array) -> Dictionary:
	var best_score := -INF
	var best_move := {}

	for piece in tray_pieces:
		if piece == null:
			continue
		var h: int = piece.shape.size()
		var w: int = piece.shape[0].size() if h > 0 else 0

		for gy in range(-(h - 1), board.rows):
			for gx in range(-(w - 1), board.columns):
				if not board.can_place_piece_at(piece, gx, gy):
					continue
				var score := _evaluate(board, piece, gx, gy)
				if score > best_score:
					best_score = score
					best_move = {"piece": piece, "gx": gx, "gy": gy}

	return best_move


## Evaluate a placement. Higher = better.
func _evaluate(board: BoardState, piece: BlockPiece, gx: int, gy: int) -> float:
	var score := 0.0
	var cells := piece.occupied_cells_at(gx, gy)

	# 1. Line completion prediction (uses BoardState API)
	var predicted := board.predict_completed_lines(piece, gx, gy)
	var completed_lines: int = predicted["rows"].size() + predicted["cols"].size()
	score += W_LINE_CLEAR * completed_lines

	# 2. Adjacency — count how many existing occupied neighbors each placed cell has
	var adjacency := 0
	for cell in cells:
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = cell.x + dir.x
			var ny: int = cell.y + dir.y
			if nx < 0 or nx >= board.columns or ny < 0 or ny >= board.rows:
				continue
			# Only count cells that are already occupied (not part of this piece)
			var is_piece_cell := false
			for pc in cells:
				if pc.x == nx and pc.y == ny:
					is_piece_cell = true
					break
			if not is_piece_cell and board.grid[ny][nx]["occupied"]:
				adjacency += 1
	score += W_ADJACENCY * adjacency

	# 3. Hole penalty — simulate placement and count new holes
	# A "hole" = empty cell with an occupied cell above it
	var holes_before := _count_holes(board)
	var sim_board := board.place_piece(piece, gx, gy)
	# If lines clear, do it on the simulated board
	if completed_lines > 0:
		var clear_result := sim_board.clear_completed_lines()
		sim_board = clear_result["board"]
	var holes_after := _count_holes(sim_board)
	var new_holes: int = holes_after - holes_before
	score += W_HOLE_PENALTY * new_holes

	# 4. Bottom preference — prefer placing lower on the board
	var avg_y := 0.0
	for cell in cells:
		avg_y += cell.y
	avg_y /= cells.size()
	score += W_BOTTOM_PREFER * avg_y

	# 5. Edge bonus — cells touching the board edge
	var edge_count := 0
	for cell in cells:
		if cell.x == 0 or cell.x == board.columns - 1:
			edge_count += 1
		if cell.y == 0 or cell.y == board.rows - 1:
			edge_count += 1
	score += W_EDGE_BONUS * edge_count

	# 6. Row/column fill progress — reward contributing to nearly-full lines
	for cell in cells:
		# Row progress
		var row_filled := 0
		for x in board.columns:
			if board.grid[cell.y][x]["occupied"]:
				row_filled += 1
		# Count piece cells in this row too
		for pc in cells:
			if pc.y == cell.y and not board.grid[pc.y][pc.x]["occupied"]:
				row_filled += 1
		score += W_FILL_ROW_PROGRESS * float(row_filled) / float(board.columns)

		# Column progress
		var col_filled := 0
		for y in board.rows:
			if board.grid[y][cell.x]["occupied"]:
				col_filled += 1
		for pc in cells:
			if pc.x == cell.x and not board.grid[pc.y][pc.x]["occupied"]:
				col_filled += 1
		score += W_FILL_ROW_PROGRESS * float(col_filled) / float(board.rows)

	# 7. Isolated empty column penalty
	var isolated_cols_before := _count_isolated_columns(board)
	var isolated_cols_after := _count_isolated_columns(sim_board)
	var new_isolated: int = isolated_cols_after - isolated_cols_before
	if new_isolated > 0:
		score += W_ISOLATED_COL * new_isolated

	return score


## Count holes: empty cells that have at least one occupied cell above them in the same column
func _count_holes(board: BoardState) -> int:
	var holes := 0
	for x in board.columns:
		var found_block := false
		for y in board.rows:
			if board.grid[y][x]["occupied"]:
				found_block = true
			elif found_block:
				holes += 1
	return holes


## Count columns that are completely empty while both neighbors have blocks
func _count_isolated_columns(board: BoardState) -> int:
	var count := 0
	for x in board.columns:
		var col_empty := true
		for y in board.rows:
			if board.grid[y][x]["occupied"]:
				col_empty = false
				break
		if not col_empty:
			continue
		# Check if neighbors have blocks
		var left_has := false
		var right_has := false
		if x > 0:
			for y in board.rows:
				if board.grid[y][x - 1]["occupied"]:
					left_has = true
					break
		if x < board.columns - 1:
			for y in board.rows:
				if board.grid[y][x + 1]["occupied"]:
					right_has = true
					break
		if left_has and right_has:
			count += 1
	return count
