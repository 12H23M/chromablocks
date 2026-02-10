class_name ClearSystem

## Returns: {board, lines_cleared, rows, cols, is_perfect, has_clears}
static func check_and_clear(board: BoardState) -> Dictionary:
	var result := board.clear_completed_lines()
	var has_clears: bool = result["lines_cleared"] > 0
	result["is_perfect"] = result["board"].is_empty if has_clears else false
	result["has_clears"] = has_clears
	return result
