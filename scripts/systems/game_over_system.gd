class_name GameOverSystem


static func is_game_over(board: BoardState, tray_pieces: Array, held_piece: BlockPiece = null, hold_used_this_tray: bool = false) -> bool:
	# Build the set of all pieces that could potentially be placed
	var all_pieces: Array = tray_pieces.duplicate()
	# Held piece can be swapped in if hold hasn't been used this tray
	if held_piece != null and not hold_used_this_tray:
		all_pieces.append(held_piece)
	if all_pieces.is_empty():
		return false
	return not board.can_place_any_piece(all_pieces)
