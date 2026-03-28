extends Node
## Headless autoplay runner — plays N games using AutoPlayer bot and outputs JSON stats.
## Usage: Godot --headless --main-pack <pck> -s res://scripts/game/autoplay_runner.gd -- --games 10 --timeout 60

var _auto_player := AutoPlayer.new()
var _piece_gen := PieceGenerator.new()

var _num_games: int = 10
var _timeout_per_game: float = 60.0  # seconds per game (wall clock)

var _results: Array = []  # Array[Dictionary] — per-game stats
var _current_game: int = 0


func _ready() -> void:
	_parse_args()
	print("[AutoplayRunner] Starting %d games (timeout=%ds each)" % [_num_games, int(_timeout_per_game)])
	_run_all_games()
	_output_report()
	get_tree().quit()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--games":
				i += 1
				if i < args.size():
					_num_games = int(args[i])
			"--timeout":
				i += 1
				if i < args.size():
					_timeout_per_game = float(args[i])
		i += 1


func _run_all_games() -> void:
	for game_idx in _num_games:
		_current_game = game_idx + 1
		var result: Dictionary = _run_single_game()
		_results.append(result)
		print("[AutoplayRunner] Game %d/%d — score:%d turns:%d lines:%d combo:%d chains:%d blasts:%d" % [
			_current_game, _num_games,
			result["score"], result["turns"], result["lines_cleared"],
			result["max_combo"], result["chains"], result["blasts"],
		])


func _run_single_game() -> Dictionary:
	var state := GameState.new()
	state.status = Enums.GameStatus.PLAYING
	_piece_gen.reset()
	_auto_player.reset_stats()

	var start_time: int = Time.get_ticks_msec()
	var timeout_ms: int = int(_timeout_per_game * 1000.0)
	var game_over_turn: int = 0

	# Generate first tray
	var tray: Array = _piece_gen.generate_tray(state.level, state.board)
	state.tray_pieces = tray

	while state.status == Enums.GameStatus.PLAYING:
		# Timeout check
		var elapsed: int = Time.get_ticks_msec() - start_time
		if elapsed > timeout_ms:
			print("[AutoplayRunner] Game %d timed out at turn %d" % [_current_game, state.blocks_placed])
			break

		# Find best move
		var move: Dictionary = _auto_player.find_best_move(state.board, state.tray_pieces)
		if move.is_empty():
			# No valid move — game over
			game_over_turn = state.blocks_placed
			break

		var piece: BlockPiece = move["piece"]
		var gx: int = move["gx"]
		var gy: int = move["gy"]

		# Place piece on board
		var board: BoardState = state.board.place_piece(piece, gx, gy)

		# Check completed lines before clearing
		var completed_rows: Array = board.get_completed_rows()
		var completed_cols: Array = board.get_completed_columns()
		var has_line_clear: bool = completed_rows.size() > 0 or completed_cols.size() > 0

		# Chroma Blast check
		var blast_result: Dictionary = {"blast_colors": [], "trigger_lines": []}
		if has_line_clear:
			blast_result = ChromaBlastSystem.check_blast(board, completed_rows, completed_cols)

		# Line clear
		var clear_result: Dictionary = ClearSystem.check_and_clear(board)
		board = clear_result["board"]

		# Execute Chroma Blast
		var blast_cells_removed: int = 0
		if not blast_result["blast_colors"].is_empty():
			var blast_executed: Dictionary = ChromaBlastSystem.execute_blast(board, blast_result["blast_colors"])
			board = blast_executed["board"]
			blast_cells_removed = blast_executed["cells_removed"]
			_auto_player.record_blast()
			# Blast may complete more lines
			var blast_line_result: Dictionary = board.clear_completed_lines()
			board = blast_line_result["board"]
			clear_result["lines_cleared"] += blast_line_result["lines_cleared"]

		# Chroma Chain
		var chain_result: Dictionary = {"cascades": 0, "total_cells_cleared": 0, "groups_per_cascade": [], "extra_lines_cleared": 0}
		if has_line_clear:
			chain_result = ChromaChainSystem.process_chains(board)
			board = chain_result["board"]
			clear_result["lines_cleared"] += chain_result["extra_lines_cleared"]
			if chain_result["cascades"] > 0:
				state.chains_triggered += 1

		# Color match
		var color_result: Dictionary
		if GameConstants.COLOR_MATCH_ENABLED:
			color_result = ColorMatchSystem.check_color_match(board)
			board = color_result["board"]
		else:
			color_result = {"board": board, "groups": [], "total_removed": 0, "has_matches": false}

		# Cell aging
		if GameConstants.CELL_AGE_ENABLED:
			board = board.increment_ages()

		# Scoring
		var did_clear: bool = clear_result["lines_cleared"] > 0 or color_result["has_matches"] or blast_cells_removed > 0 or chain_result["total_cells_cleared"] > 0
		var new_combo: int = (state.combo + 1) if did_clear else 0

		var score_result: Dictionary = ScoringSystem.calculate(
			piece.cell_count, clear_result, color_result, new_combo, state.level)

		# Chain bonus
		var chain_bonus: int = 0
		for cascade_idx in chain_result["cascades"]:
			var pts_idx: int = mini(cascade_idx, GameConstants.CHROMA_CHAIN_POINTS_PER_CELL.size() - 1)
			var groups: Array = chain_result["groups_per_cascade"][cascade_idx]
			for group in groups:
				chain_bonus += group.size() * GameConstants.CHROMA_CHAIN_POINTS_PER_CELL[pts_idx]

		# Blast bonus
		var blast_bonus: int = 0
		if blast_cells_removed > 0:
			blast_bonus += blast_cells_removed * GameConstants.CHROMA_BLAST_POINTS_PER_CELL
			blast_bonus += blast_result["blast_colors"].size() * GameConstants.CHROMA_BLAST_TRIGGER_BONUS

		score_result["total"] += chain_bonus + blast_bonus

		# Level check
		var total_lines: int = state.lines_cleared + clear_result["lines_cleared"]
		var new_level: int = DifficultySystem.calculate_level(total_lines)

		# Apply turn result
		state.apply_turn_result(board, score_result["total"],
			clear_result["lines_cleared"], new_combo, new_level, piece)

		# Record auto-player stats
		_auto_player.record_turn(state)

		# Refill tray if empty
		if state.tray_pieces.is_empty():
			state.hold_used_this_tray = false
			var new_tray: Array = _piece_gen.generate_tray(state.level, state.board)
			state.tray_pieces = new_tray

		# Check game over
		if GameOverSystem.is_game_over(state.board, state.tray_pieces):
			game_over_turn = state.blocks_placed
			break

	# Build result
	var elapsed_ms: int = Time.get_ticks_msec() - start_time
	var stats: Dictionary = _auto_player.stats.duplicate()
	stats["game_over_turn"] = game_over_turn
	stats["elapsed_ms"] = elapsed_ms
	stats["level"] = state.level
	stats["fill_ratio"] = state.board.fill_ratio()
	return stats


func _output_report() -> void:
	# Aggregate stats
	var total_score: int = 0
	var total_turns: int = 0
	var total_lines: int = 0
	var best_score: int = 0
	var worst_score: int = 999999999
	var best_combo: int = 0
	var total_chains: int = 0
	var total_blasts: int = 0
	var scores: Array = []

	for r in _results:
		var s: int = r["score"]
		total_score += s
		total_turns += r["turns"]
		total_lines += r["lines_cleared"]
		total_chains += r["chains"]
		total_blasts += r["blasts"]
		scores.append(s)
		if s > best_score:
			best_score = s
		if s < worst_score:
			worst_score = s
		if r["max_combo"] > best_combo:
			best_combo = r["max_combo"]

	var avg_score: float = float(total_score) / float(_results.size()) if _results.size() > 0 else 0.0
	var avg_turns: float = float(total_turns) / float(_results.size()) if _results.size() > 0 else 0.0

	# Median score
	scores.sort()
	var median_score: int = scores[scores.size() / 2] if scores.size() > 0 else 0

	var report: Dictionary = {
		"num_games": _results.size(),
		"summary": {
			"avg_score": int(avg_score),
			"median_score": median_score,
			"best_score": best_score,
			"worst_score": worst_score,
			"avg_turns": snapped(avg_turns, 0.1),
			"total_lines_cleared": total_lines,
			"best_combo": best_combo,
			"total_chains": total_chains,
			"total_blasts": total_blasts,
		},
		"games": _results,
	}

	var json_str: String = JSON.stringify(report, "  ")

	# Output marker for shell script parsing
	print("===AUTOPLAY_REPORT_START===")
	print(json_str)
	print("===AUTOPLAY_REPORT_END===")
