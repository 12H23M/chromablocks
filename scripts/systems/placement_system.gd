class_name PlacementSystem


static func can_place(board: BoardState, piece: BlockPiece, gx: int, gy: int) -> bool:
	return board.can_place_piece_at(piece, gx, gy)


static func screen_to_grid(board_origin: Vector2, cell_size: float, piece: BlockPiece, screen_pos: Vector2) -> Vector2i:
	var rel := screen_pos - board_origin
	var gx := roundi((rel.x - (piece.width * cell_size / 2.0)) / cell_size)
	var gy := roundi((rel.y - (piece.height * cell_size / 2.0)) / cell_size)
	return Vector2i(gx, gy)
