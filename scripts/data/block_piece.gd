class_name BlockPiece

var type: int  # Enums.PieceType
var color: int  # Enums.BlockColor
var shape: Array  # Array of Array of int (0/1)


func _init(p_type: int = 0, p_color: int = 0, p_shape: Array = []) -> void:
	type = p_type
	color = p_color
	shape = p_shape


var width: int:
	get:
		if shape.size() > 0 and shape[0] is Array:
			return shape[0].size()
		return 0


var height: int:
	get: return shape.size()


var cell_count: int:
	get:
		var count := 0
		for row in shape:
			for cell in row:
				if cell == 1:
					count += 1
		return count


func occupied_cells_at(gx: int, gy: int) -> Array:
	var cells: Array = []
	for row_idx in shape.size():
		for col_idx in shape[row_idx].size():
			if shape[row_idx][col_idx] == 1:
				cells.append(Vector2i(gx + col_idx, gy + row_idx))
	return cells
