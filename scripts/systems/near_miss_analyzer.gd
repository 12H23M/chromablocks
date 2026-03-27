class_name NearMissAnalyzer
## Analyzes near-miss situations at game over to show "what could have been"
## Helps create the "so close!" feeling that drives replay

## Result structure for near-miss analysis
class NearMissResult extends RefCounted:
	var near_lines: Array = []       # [{axis: "row"/"col", index: int, filled: int, needed: int}]
	var blocked_cells: int = 0       # Cells blocked from placement
	var almost_pieces: Array = []    # Pieces that could almost fit
	var closest_clear: Dictionary = {}  # Info about the closest line clear opportunity


static func analyze(board: BoardState, tray_pieces: Array) -> NearMissResult:
	var result := NearMissResult.new()

	if board == null or tray_pieces.is_empty():
		return result

	# Find rows/cols that are 7/8 filled (one cell away from clear)
	result.near_lines = _find_near_complete_lines(board)

	# Count how many cells are blocked by overhangs
	result.blocked_cells = _count_blocked_cells(board)

	# Find pieces that could almost fit (1-2 cells off)
	result.almost_pieces = _find_almost_fitting_pieces(board, tray_pieces)

	# Find the closest clear opportunity
	result.closest_clear = _find_closest_clear_opportunity(board, tray_pieces)

	return result


static func _find_near_complete_lines(board: BoardState) -> Array:
	var near_lines := []

	# Check rows (6/8 or 7/8 filled = near complete)
	for y in board.rows:
		var filled := 0
		for x in board.columns:
			if board.grid[y][x]["occupied"]:
				filled += 1
		if filled >= 6:
			near_lines.append({
				"axis": "row",
				"index": y,
				"filled": filled,
				"needed": 8 - filled
			})

	# Check columns (6/8 or 7/8 filled = near complete)
	for x in board.columns:
		var filled := 0
		for y in board.rows:
			if board.grid[y][x]["occupied"]:
				filled += 1
		if filled >= 6:
			near_lines.append({
				"axis": "col",
				"index": x,
				"filled": filled,
				"needed": 8 - filled
			})

	return near_lines


static func _count_blocked_cells(board: BoardState) -> int:
	# Count cells that can't be filled due to shape constraints
	var blocked := 0
	for y in board.rows:
		for x in board.columns:
			if not board.grid[y][x]["occupied"]:
				# Check if this empty cell is "blocked" by surrounding cells
				# A cell is blocked if it's surrounded on 3+ sides
				var surround_count := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or nx >= board.columns or ny < 0 or ny >= board.rows:
							surround_count += 1  # Edge counts as blocked
						elif board.grid[ny][nx]["occupied"]:
							surround_count += 1
				if surround_count >= 3:
					blocked += 1
	return blocked


static func _find_almost_fitting_pieces(board: BoardState, tray_pieces: Array) -> Array:
	var almost_pieces := []

	for piece in tray_pieces:
		if piece == null:
			continue

		# Check all positions
		for y in board.rows:
			for x in board.columns:
				var fit_result := _check_piece_fit(board, piece, x, y)
				if fit_result["off_by"] == 1:  # Only 1 cell off from fitting
					almost_pieces.append({
						"piece": piece,
						"position": Vector2i(x, y),
						"off_by": 1,
						"blocked_cells": fit_result["blocked_cells"]
					})

	# Keep only unique pieces (by shape, not position)
	var seen_shapes := {}
	var unique := []
	for ap in almost_pieces:
		var shape_key := _piece_shape_key(ap["piece"])
		if shape_key not in seen_shapes:
			seen_shapes[shape_key] = true
			unique.append(ap)

	return unique


static func _check_piece_fit(board: BoardState, piece: BlockPiece, gx: int, gy: int) -> Dictionary:
	var occupied_count := 0
	var blocked_count := 0

	for cell in piece.occupied_cells_at(0, 0):
		var cx: int = gx + cell.x
		var cy: int = gy + cell.y

		if cx < 0 or cx >= board.columns or cy < 0 or cy >= board.rows:
			blocked_count += 1
		elif board.grid[cy][cx]["occupied"]:
			blocked_count += 1
		else:
			occupied_count += 1

	return {
		"off_by": blocked_count,
		"blocked_cells": blocked_count
	}


static func _piece_shape_key(piece: BlockPiece) -> String:
	var key := ""
	for cell in piece.occupied_cells_at(0, 0):
		key += "%d,%d;" % [cell.x, cell.y]
	return key


static func _find_closest_clear_opportunity(board: BoardState, tray_pieces: Array) -> Dictionary:
	var best_opportunity := {}

	for piece in tray_pieces:
		if piece == null:
			continue

		# Check all placements
		for y in board.rows:
			for x in board.columns:
				var result := board.predict_completed_lines(piece, x, y)
				var lines_cleared: int = result["rows"].size() + result["cols"].size()

				if lines_cleared > 0:
					# Check if it's actually placeable
					if board.can_place_piece(piece, x, y):
						if best_opportunity.is_empty() or lines_cleared > best_opportunity.get("lines", 0):
							best_opportunity = {
								"piece": piece,
								"position": Vector2i(x, y),
								"lines": lines_cleared,
								"rows": result["rows"],
								"cols": result["cols"],
								"placeable": true
							}

	return best_opportunity


## Generate a human-readable "what could have been" message
static func get_near_miss_message(result: NearMissResult) -> String:
	var messages: Array = []

	var near_count: int = result.near_lines.size()
	var has_one_cell_away: bool = false
	for near in result.near_lines:
		if near["needed"] == 1:
			has_one_cell_away = true
			break

	# Special emphasis for "just one cell away"
	if has_one_cell_away:
		var one_cell_msgs: Array = [
			"💔 아... 한 칸만 더 있었으면!",
			"💔 이럴 수가, 딱 한 칸 차이였는데!",
			"💔 한 칸... 딱 한 칸만 더 채웠으면 클리어였어!",
			"💔 거의 다 채웠는데... 한 칸이 아쉽다!",
			"💔 이 한 칸의 차이가 이렇게 크다니...",
		]
		messages.append_array(one_cell_msgs)

	# Multiple near-complete lines
	if near_count >= 2:
		var multi_msgs: Array = [
			"😭 %d줄이나 거의 완성이었는데...!" % near_count,
			"😭 조금만 더였으면 %d줄 동시 클리어!" % near_count,
			"😭 %d줄이 한 발 차이였어... 아깝다!" % near_count,
		]
		messages.append_array(multi_msgs)
	elif near_count == 1 and not has_one_cell_away:
		messages.append("💔 거의 다 왔는데... 아쉽다!")

	# Closest clear opportunity
	if not result.closest_clear.is_empty() and result.closest_clear.get("placeable", false):
		var lines: int = result.closest_clear.get("lines", 0)
		if lines >= 2:
			messages.append("😭 피스 배치만 달랐어도 %d줄 클리어였는데!" % lines)
			messages.append("😭 이 피스를 저기 놨더라면... %d줄이었어!" % lines)

	# Almost-fitting pieces
	if result.almost_pieces.size() > 0:
		var piece_msgs: Array = [
			"💔 이 피스가 딱 맞았으면...",
			"💔 다른 피스였으면 클리어할 수 있었는데!",
			"💔 이 피스만 들어갔으면 달라졌을 텐데...",
		]
		messages.append_array(piece_msgs)

	# General encouragement fallbacks
	if messages.is_empty():
		messages = [
			"💔 조금만 더 하면 됐는데!",
			"💔 다음엔 꼭 해내자!",
			"💔 거의 다 왔는데! 포기하지 마!",
			"💔 이번엔 정말 아쉬웠어...",
			"💔 한 줄만 더 지웠으면 달라졌을 텐데!",
		]

	return messages[randi() % messages.size()]


## Get detailed near-miss hints for display
static func get_near_miss_details(result: NearMissResult) -> Array:
	var details := []

	# Near-complete lines
	for near in result.near_lines:
		var axis_text := "가로" if near["axis"] == "row" else "세로"
		details.append({
			"type": "near_line",
			"icon": "📏",
			"text": "%s %d번: %d/8 채움" % [axis_text, near["index"] + 1, near["filled"]],
			"subtext": "한 칸만 더!"
		})

	# Closest clear opportunity
	if not result.closest_clear.is_empty() and result.closest_clear.get("placeable", false):
		var lines: int = result.closest_clear.get("lines", 0)
		if lines > 0:
			details.append({
				"type": "missed_clear",
				"icon": "💥",
				"text": "%d줄 클리어 기회가 있었음!" % lines,
				"subtext": "피스 위치를 달리했으면..."
			})

	return details
