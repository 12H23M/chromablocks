class_name ChromaChainSystem

## Process chroma chains after line clear.
## Finds connected same-color groups >= threshold and removes them.
## Cascades up to MAX_CASCADE times.
## Returns: {board, cascades, total_cells_cleared, groups_per_cascade, extra_lines_cleared}
static func process_chains(board: BoardState) -> Dictionary:
	var result := {
		"board": board,
		"cascades": 0,
		"total_cells_cleared": 0,
		"groups_per_cascade": [],  # Array[Array[Array[Vector2i]]]
		"extra_lines_cleared": 0,
	}

	if not GameConstants.CHROMA_CHAIN_ENABLED:
		return result

	for cascade in range(GameConstants.CHROMA_CHAIN_MAX_CASCADE):
		var groups := board.find_color_matches_threshold(GameConstants.CHROMA_CHAIN_THRESHOLD)
		if groups.is_empty():
			break

		result["cascades"] += 1
		result["groups_per_cascade"].append(groups)

		# Remove all chain cells
		var all_cells: Array = []
		for group in groups:
			all_cells.append_array(group)
			result["total_cells_cleared"] += group.size()

		board = board.remove_cells(all_cells)

		# Chain might complete new lines
		var line_result := board.clear_completed_lines()
		board = line_result["board"]
		result["extra_lines_cleared"] += line_result["lines_cleared"]

	result["board"] = board
	return result
