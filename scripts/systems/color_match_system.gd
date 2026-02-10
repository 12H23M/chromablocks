class_name ColorMatchSystem

## Returns: {board, groups, total_removed, has_matches}
static func check_color_match(board: BoardState) -> Dictionary:
	var matches := board.find_color_matches()
	if matches.is_empty():
		return {"board": board, "groups": [], "total_removed": 0, "has_matches": false}

	var all_cells: Array = []
	for group in matches:
		for cell in group:
			if cell not in all_cells:
				all_cells.append(cell)

	var new_board := board.remove_cells(all_cells)
	return {
		"board": new_board,
		"groups": matches,
		"total_removed": all_cells.size(),
		"has_matches": true,
	}
