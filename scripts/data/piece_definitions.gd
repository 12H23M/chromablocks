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
}

# Levels 1-5: small/medium pieces, no Z/S, no pentominoes
const WEIGHTS_EASY: Dictionary = {
	Enums.PieceType.SINGLE: 0.08,
	Enums.PieceType.DUO: 0.06,
	Enums.PieceType.DUO_V: 0.06,
	Enums.PieceType.TRI_LINE: 0.07,
	Enums.PieceType.TRI_LINE_V: 0.07,
	Enums.PieceType.TRI_L: 0.06,
	Enums.PieceType.TRI_J: 0.06,
	Enums.PieceType.TET_SQUARE: 0.10,
	Enums.PieceType.TET_LINE: 0.06,
	Enums.PieceType.TET_LINE_V: 0.06,
	Enums.PieceType.TET_T: 0.05,
	Enums.PieceType.TET_T_UP: 0.05,
	Enums.PieceType.TET_L: 0.06,
	Enums.PieceType.TET_J: 0.06,
	Enums.PieceType.TET_L_H: 0.05,
	Enums.PieceType.TET_J_H: 0.05,
	Enums.PieceType.RECT_2x3: 0.02,
	Enums.PieceType.SQ_3x3: 0.01,
	Enums.PieceType.RECT_3x2: 0.02,
}

# Levels 6-15: all pieces, balanced
const WEIGHTS_MEDIUM: Dictionary = {
	Enums.PieceType.SINGLE: 0.03,
	Enums.PieceType.DUO: 0.03,
	Enums.PieceType.DUO_V: 0.03,
	Enums.PieceType.TRI_LINE: 0.04,
	Enums.PieceType.TRI_LINE_V: 0.04,
	Enums.PieceType.TRI_L: 0.04,
	Enums.PieceType.TRI_J: 0.04,
	Enums.PieceType.TET_SQUARE: 0.06,
	Enums.PieceType.TET_LINE: 0.04,
	Enums.PieceType.TET_LINE_V: 0.04,
	Enums.PieceType.TET_T: 0.04,
	Enums.PieceType.TET_T_UP: 0.04,
	Enums.PieceType.TET_T_R: 0.03,
	Enums.PieceType.TET_T_L: 0.03,
	Enums.PieceType.TET_Z: 0.04,
	Enums.PieceType.TET_S: 0.04,
	Enums.PieceType.TET_Z_V: 0.03,
	Enums.PieceType.TET_S_V: 0.03,
	Enums.PieceType.TET_L: 0.04,
	Enums.PieceType.TET_J: 0.04,
	Enums.PieceType.TET_L_H: 0.03,
	Enums.PieceType.TET_J_H: 0.03,
	Enums.PieceType.PENT_PLUS: 0.03,
	Enums.PieceType.PENT_U: 0.03,
	Enums.PieceType.PENT_T: 0.03,
	Enums.PieceType.PENT_LINE: 0.02,
	Enums.PieceType.PENT_LINE_V: 0.02,
	Enums.PieceType.PENT_L3: 0.02,
	Enums.PieceType.PENT_J3: 0.02,
	Enums.PieceType.PENT_L3_R: 0.02,
	Enums.PieceType.PENT_J3_R: 0.02,
	Enums.PieceType.RECT_2x3: 0.01,
	Enums.PieceType.SQ_3x3: 0.01,
	Enums.PieceType.RECT_3x2: 0.01,
}

# Levels 16+: complex/large pieces dominant
const WEIGHTS_HARD: Dictionary = {
	Enums.PieceType.SINGLE: 0.02,
	Enums.PieceType.TRI_L: 0.03,
	Enums.PieceType.TRI_J: 0.03,
	Enums.PieceType.TET_SQUARE: 0.03,
	Enums.PieceType.TET_LINE: 0.02,
	Enums.PieceType.TET_LINE_V: 0.02,
	Enums.PieceType.TET_T: 0.04,
	Enums.PieceType.TET_T_UP: 0.04,
	Enums.PieceType.TET_T_R: 0.04,
	Enums.PieceType.TET_T_L: 0.04,
	Enums.PieceType.TET_Z: 0.05,
	Enums.PieceType.TET_S: 0.05,
	Enums.PieceType.TET_Z_V: 0.05,
	Enums.PieceType.TET_S_V: 0.05,
	Enums.PieceType.TET_L: 0.04,
	Enums.PieceType.TET_J: 0.04,
	Enums.PieceType.TET_L_H: 0.04,
	Enums.PieceType.TET_J_H: 0.04,
	Enums.PieceType.PENT_PLUS: 0.06,
	Enums.PieceType.PENT_U: 0.06,
	Enums.PieceType.PENT_T: 0.06,
	Enums.PieceType.PENT_LINE: 0.05,
	Enums.PieceType.PENT_LINE_V: 0.05,
	Enums.PieceType.PENT_L3: 0.04,
	Enums.PieceType.PENT_J3: 0.04,
	Enums.PieceType.PENT_L3_R: 0.04,
	Enums.PieceType.PENT_J3_R: 0.04,
	Enums.PieceType.RECT_2x3: 0.02,
	Enums.PieceType.SQ_3x3: 0.02,
	Enums.PieceType.RECT_3x2: 0.02,
}


static func get_shape(piece_type: int) -> Array:
	return SHAPES[piece_type]


static func get_color(piece_type: int) -> int:
	return PIECE_COLORS[piece_type]


static func generate_tray(level: int) -> Array:
	var tray: Array = []
	for i in GameConstants.TRAY_SIZE:
		tray.append(create_random_piece(level))
	return tray


static func create_random_piece(level: int) -> BlockPiece:
	var weights := _get_weights_for_level(level)
	var piece_type := _weighted_random(weights)
	var piece_color: int = PIECE_COLORS[piece_type]
	var piece_shape: Array = SHAPES[piece_type]
	return BlockPiece.new(piece_type, piece_color, piece_shape)


static func _get_weights_for_level(level: int) -> Dictionary:
	if level <= 5:
		return WEIGHTS_EASY
	if level <= 15:
		return WEIGHTS_MEDIUM
	return WEIGHTS_HARD


static func _weighted_random(weights: Dictionary) -> int:
	var total_weight := 0.0
	for w in weights.values():
		total_weight += w

	var random_value := randf() * total_weight
	for piece_type in weights:
		random_value -= weights[piece_type]
		if random_value <= 0.0:
			return piece_type

	# Fallback
	return weights.keys().back()
