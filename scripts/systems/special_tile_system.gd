class_name SpecialTileSystem

## Try to drop special tiles after line clear.
## Each cleared line has SPECIAL_TILE_DROP_CHANCE to spawn one special.
## Returns: {board: BoardState, dropped: Array[Dictionary{pos, type}]}
static func try_drop_specials(board: BoardState, cleared_rows: Array, cleared_cols: Array, drop_chance: float = -1.0) -> Dictionary:
	var dropped: Array = []
	var new_grid: Array = board._copy_grid()
	var chance: float = drop_chance if drop_chance >= 0.0 else GameConstants.SPECIAL_TILE_DROP_CHANCE

	# Collect empty positions along cleared lines
	var cleared_positions: Array = []
	for row in cleared_rows:
		for x in board.columns:
			if not new_grid[row][x]["occupied"]:
				cleared_positions.append(Vector2i(x, row))
	for col in cleared_cols:
		for y in board.rows:
			var pos := Vector2i(col, y)
			if not new_grid[y][col]["occupied"] and pos not in cleared_positions:
				cleared_positions.append(pos)

	if cleared_positions.is_empty():
		return {"board": board, "dropped": dropped}

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var total_lines: int = cleared_rows.size() + cleared_cols.size()
	for _i in total_lines:
		if rng.randf() >= chance:
			continue
		# Find available empty position
		var available: Array = []
		for pos in cleared_positions:
			if not new_grid[pos.y][pos.x]["occupied"]:
				available.append(pos)
		if available.is_empty():
			break
		var pos: Vector2i = available[rng.randi_range(0, available.size() - 1)]
		var special_type: int = rng.randi_range(0, 2)  # BOMB, RAINBOW, FREEZE
		new_grid[pos.y][pos.x] = {
			"occupied": true,
			"color": Enums.BlockColor.SPECIAL,
			"age": 0,
			"special_type": special_type,
		}
		dropped.append({"pos": pos, "type": special_type})

	var new_board := BoardState.new(board.columns, board.rows, new_grid)

	# Auto-activate FREEZE tiles immediately
	for drop in dropped:
		if drop["type"] == GameConstants.SPECIAL_TILE_FREEZE:
			var fpos: Vector2i = drop["pos"]
			new_board = execute_freeze(new_board, fpos.x, fpos.y)

	return {"board": new_board, "dropped": dropped}


## Execute BOMB at position: destroy 3x3 area.
## Returns: {board: BoardState, destroyed: Array[Vector2i], score_bonus: int}
static func execute_bomb(board: BoardState, bx: int, by: int) -> Dictionary:
	var destroyed: Array = []
	var new_grid: Array = board._copy_grid()
	var radius: int = GameConstants.SPECIAL_TILE_BOMB_RADIUS
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var nx: int = bx + dx
			var ny: int = by + dy
			if nx >= 0 and nx < board.columns and ny >= 0 and ny < board.rows:
				if new_grid[ny][nx]["occupied"]:
					destroyed.append(Vector2i(nx, ny))
					new_grid[ny][nx] = BoardState._empty_cell()
	return {
		"board": BoardState.new(board.columns, board.rows, new_grid),
		"destroyed": destroyed,
		"score_bonus": GameConstants.SPECIAL_TILE_BOMB_BONUS,
	}


## Execute FREEZE at position: reset ages within radius, then remove the freeze tile.
static func execute_freeze(board: BoardState, fx: int, fy: int) -> BoardState:
	var new_grid: Array = board._copy_grid()
	var radius: int = GameConstants.SPECIAL_TILE_FREEZE_RADIUS
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var nx: int = fx + dx
			var ny: int = fy + dy
			if nx >= 0 and nx < board.columns and ny >= 0 and ny < board.rows:
				if new_grid[ny][nx]["occupied"]:
					new_grid[ny][nx]["age"] = 0
	# Remove the freeze tile itself
	new_grid[fy][fx] = BoardState._empty_cell()
	return BoardState.new(board.columns, board.rows, new_grid)
