class_name GameOverSystem


static func is_game_over(board: BoardState, tray_pieces: Array) -> bool:
	if tray_pieces.is_empty():
		return false
	return not board.can_place_any_piece(tray_pieces)
