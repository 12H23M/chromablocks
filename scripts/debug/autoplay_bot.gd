class_name AutoPlayBot
extends Node
## Headless autoplay bot for balance testing.
## Runs N games using greedy AI, collects statistics per game and overall.

signal game_completed(stats: Dictionary)
signal session_completed(summary: Dictionary)

# ── Config ──
var verbose: bool = true

# ── Internals ──
var _piece_gen := PieceGenerator.new()
var _ai := AutoPlayer.new()


func run_games(n: int) -> Dictionary:
	var all_stats: Array = []

	for i in n:
		var stats: Dictionary = _run_single_game(i + 1, n)
		all_stats.append(stats)
		game_completed.emit(stats)

	var summary: Dictionary = _build_summary(all_stats, n)
	if verbose:
		print("[AutoPlay] Summary: avg_score=%d, avg_turns=%d, high_score=%d" % [
			summary["avg_score"], summary["avg_turns"], summary["high_score"]])
	session_completed.emit(summary)
	return summary


func _run_single_game(game_idx: int, total: int) -> Dictionary:
	var start_ms: int = Time.get_ticks_msec()

	# Fresh state
	var board := BoardState.new()
	var level: int = 1
	var score: int = 0
	var combo: int = 0
	var max_combo: int = 0
	var lines_cleared: int = 0
	var turns: int = 0

	_piece_gen.reset()
	var tray: Array = _piece_gen.generate_tray(level, board)

	# Main game loop
	while true:
		# Check game over: no piece in tray can be placed
		if not board.can_place_any_piece(tray):
			break

		# Find best move among tray pieces
		var move: Dictionary = _ai.find_best_move(board, tray)
		if move.is_empty():
			break

		var piece: BlockPiece = move["piece"]
		var gx: int = move["gx"]
		var gy: int = move["gy"]

		# Skip bomb pieces (special handling not worth simulating)
		if piece.type == Enums.PieceType.BOMB:
			tray.erase(piece)
			if tray.is_empty():
				tray = _piece_gen.generate_tray(level, board)
			continue

		# 1. Place piece
		board = board.place_piece(piece, gx, gy)

		# 2. Clear lines
		var clear_result: Dictionary = ClearSystem.check_and_clear(board)
		board = clear_result["board"]
		var did_clear: bool = clear_result["lines_cleared"] > 0

		# 3. Scoring
		var new_combo: int = (combo + 1) if did_clear else 0
		var color_result := {"board": board, "groups": [], "total_removed": 0, "has_matches": false}
		var score_result: Dictionary = ScoringSystem.calculate(
			piece.cell_count, clear_result, color_result, new_combo, level)

		score += score_result["total"]
		lines_cleared += clear_result["lines_cleared"]
		combo = new_combo
		if combo > max_combo:
			max_combo = combo
		turns += 1

		# 4. Level up
		level = DifficultySystem.calculate_level(lines_cleared)

		# 5. Remove piece from tray, refill if empty
		tray.erase(piece)
		if tray.is_empty():
			tray = _piece_gen.generate_tray(level, board)

	var duration_ms: int = Time.get_ticks_msec() - start_ms
	var stats := {
		"turns": turns,
		"score": score,
		"max_combo": max_combo,
		"lines_cleared": lines_cleared,
		"duration_ms": duration_ms,
	}

	if verbose:
		print("[AutoPlay] Game %d/%d: score=%d, turns=%d, lines=%d, combo=%dx, time=%.1fs" % [
			game_idx, total, score, turns, lines_cleared, max_combo,
			duration_ms / 1000.0])

	return stats


func _build_summary(all_stats: Array, n: int) -> Dictionary:
	var total_score: int = 0
	var total_turns: int = 0
	var total_lines: int = 0
	var high_score: int = 0

	for s in all_stats:
		total_score += s["score"]
		total_turns += s["turns"]
		total_lines += s["lines_cleared"]
		if s["score"] > high_score:
			high_score = s["score"]

	return {
		"games": n,
		"avg_score": total_score / n if n > 0 else 0,
		"avg_turns": total_turns / n if n > 0 else 0,
		"avg_lines": total_lines / n if n > 0 else 0,
		"high_score": high_score,
		"all_stats": all_stats,
	}
