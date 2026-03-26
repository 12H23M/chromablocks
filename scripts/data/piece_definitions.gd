class_name PieceDefinitions

const SHAPES: Dictionary = {
	# 1-cell
	Enums.PieceType.SINGLE: [[1]],
	# 2-cell
	Enums.PieceType.DUO: [[1, 1]],
	Enums.PieceType.DUO_V: [[1], [1]],
	# 3-cell
	Enums.PieceType.TRI_LINE: [[1, 1, 1]],
	Enums.PieceType.TRI_LINE_V: [[1], [1], [1]],
	Enums.PieceType.TRI_L: [[1, 0], [1, 1]],
	Enums.PieceType.TRI_J: [[0, 1], [1, 1]],
	# 4-cell
	Enums.PieceType.TET_SQUARE: [[1, 1], [1, 1]],
	Enums.PieceType.TET_LINE: [[1, 1, 1, 1]],
	Enums.PieceType.TET_LINE_V: [[1], [1], [1], [1]],
	Enums.PieceType.TET_T: [[1, 1, 1], [0, 1, 0]],
	Enums.PieceType.TET_T_UP: [[0, 1, 0], [1, 1, 1]],
	Enums.PieceType.TET_T_R: [[1, 0], [1, 1], [1, 0]],
	Enums.PieceType.TET_T_L: [[0, 1], [1, 1], [0, 1]],
	Enums.PieceType.TET_Z: [[1, 1, 0], [0, 1, 1]],
	Enums.PieceType.TET_S: [[0, 1, 1], [1, 1, 0]],
	Enums.PieceType.TET_Z_V: [[0, 1], [1, 1], [1, 0]],
	Enums.PieceType.TET_S_V: [[1, 0], [1, 1], [0, 1]],
	Enums.PieceType.TET_L: [[1, 0], [1, 0], [1, 1]],
	Enums.PieceType.TET_J: [[0, 1], [0, 1], [1, 1]],
	Enums.PieceType.TET_L_H: [[1, 1, 1], [1, 0, 0]],
	Enums.PieceType.TET_J_H: [[1, 1, 1], [0, 0, 1]],
	# 5-cell
	Enums.PieceType.PENT_PLUS: [[0, 1, 0], [1, 1, 1], [0, 1, 0]],
	Enums.PieceType.PENT_U: [[1, 0, 1], [1, 1, 1]],
	Enums.PieceType.PENT_T: [[1, 1, 1], [0, 1, 0], [0, 1, 0]],
	Enums.PieceType.PENT_LINE: [[1, 1, 1, 1, 1]],
	Enums.PieceType.PENT_LINE_V: [[1], [1], [1], [1], [1]],
	Enums.PieceType.PENT_L3: [[1, 1, 1], [0, 0, 1], [0, 0, 1]],
	Enums.PieceType.PENT_J3: [[1, 1, 1], [1, 0, 0], [1, 0, 0]],
	Enums.PieceType.PENT_L3_R: [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
	Enums.PieceType.PENT_J3_R: [[0, 0, 1], [0, 0, 1], [1, 1, 1]],
	# Large blocks
	Enums.PieceType.RECT_2x3: [[1, 1], [1, 1], [1, 1]],
	Enums.PieceType.SQ_3x3: [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
	Enums.PieceType.RECT_3x2: [[1, 1, 1], [1, 1, 1]],
	# N-shaped (5-cell, zigzag variants)
	Enums.PieceType.PENT_N: [[1, 0], [1, 1], [0, 1], [0, 1]],       # ⌐ 세로 N
	Enums.PieceType.PENT_N_R: [[0, 1], [1, 1], [1, 0], [1, 0]],     # ⌐ 세로 N 반전
	Enums.PieceType.PENT_N_V: [[1, 1, 0], [0, 1, 1], [0, 0, 1]],    # 가로 N
	Enums.PieceType.PENT_N_V2: [[0, 0, 1], [0, 1, 1], [1, 1, 0]],   # 가로 N 반전
	# Special reward pieces
	Enums.PieceType.BOMB: [[1]],  # Single cell, explodes 3x3 on placement
}

const PIECE_COLORS: Dictionary = {
	Enums.PieceType.SINGLE: Enums.BlockColor.LEMON,
	Enums.PieceType.DUO: Enums.BlockColor.LEMON,
	Enums.PieceType.DUO_V: Enums.BlockColor.LEMON,
	Enums.PieceType.TRI_LINE: Enums.BlockColor.SKY,
	Enums.PieceType.TRI_LINE_V: Enums.BlockColor.SKY,
	Enums.PieceType.TRI_L: Enums.BlockColor.MINT,
	Enums.PieceType.TRI_J: Enums.BlockColor.MINT,
	Enums.PieceType.TET_SQUARE: Enums.BlockColor.AMBER,
	Enums.PieceType.TET_LINE: Enums.BlockColor.SKY,
	Enums.PieceType.TET_LINE_V: Enums.BlockColor.SKY,
	Enums.PieceType.TET_T: Enums.BlockColor.LAVENDER,
	Enums.PieceType.TET_T_UP: Enums.BlockColor.LAVENDER,
	Enums.PieceType.TET_T_R: Enums.BlockColor.LAVENDER,
	Enums.PieceType.TET_T_L: Enums.BlockColor.LAVENDER,
	Enums.PieceType.TET_Z: Enums.BlockColor.CORAL,
	Enums.PieceType.TET_S: Enums.BlockColor.MINT,
	Enums.PieceType.TET_Z_V: Enums.BlockColor.CORAL,
	Enums.PieceType.TET_S_V: Enums.BlockColor.MINT,
	Enums.PieceType.TET_L: Enums.BlockColor.AMBER,
	Enums.PieceType.TET_J: Enums.BlockColor.AMBER,
	Enums.PieceType.TET_L_H: Enums.BlockColor.AMBER,
	Enums.PieceType.TET_J_H: Enums.BlockColor.AMBER,
	Enums.PieceType.PENT_PLUS: Enums.BlockColor.CORAL,
	Enums.PieceType.PENT_U: Enums.BlockColor.LAVENDER,
	Enums.PieceType.PENT_T: Enums.BlockColor.SKY,
	Enums.PieceType.PENT_LINE: Enums.BlockColor.SKY,
	Enums.PieceType.PENT_LINE_V: Enums.BlockColor.SKY,
	Enums.PieceType.PENT_L3: Enums.BlockColor.AMBER,
	Enums.PieceType.PENT_J3: Enums.BlockColor.AMBER,
	Enums.PieceType.PENT_L3_R: Enums.BlockColor.AMBER,
	Enums.PieceType.PENT_J3_R: Enums.BlockColor.AMBER,
	Enums.PieceType.RECT_2x3: Enums.BlockColor.CORAL,
	Enums.PieceType.SQ_3x3: Enums.BlockColor.LAVENDER,
	Enums.PieceType.RECT_3x2: Enums.BlockColor.CORAL,
	Enums.PieceType.PENT_N: Enums.BlockColor.CORAL,
	Enums.PieceType.PENT_N_R: Enums.BlockColor.CORAL,
	Enums.PieceType.PENT_N_V: Enums.BlockColor.CORAL,
	Enums.PieceType.PENT_N_V2: Enums.BlockColor.CORAL,
	# Special reward pieces
	Enums.PieceType.BOMB: Enums.BlockColor.SPECIAL,  # Red/fire color for bomb
}
