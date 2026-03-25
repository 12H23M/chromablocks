extends Node

const SAVE_PATH := "user://chromablocks.cfg"
const ACTIVE_SECTION := "active_game"

var _config := ConfigFile.new()
var _dirty := false


func _ready() -> void:
	_config.load(SAVE_PATH)


func _mark_dirty() -> void:
	_dirty = true


func flush() -> void:
	if _dirty:
		_config.save(SAVE_PATH)
		_dirty = false


# --- Generic getter/setter ------------------------------------------------

func get_value(section: String, key: String, default_value = null):
	return _config.get_value(section, key, default_value)


func set_value(section: String, key: String, value) -> void:
	_config.set_value(section, key, value)
	_mark_dirty()


# --- High scores & stats --------------------------------------------------

func get_high_score() -> int:
	return _config.get_value("game", "high_score", 0)


func save_high_score(score: int) -> void:
	var current := get_high_score()
	if score > current:
		_config.set_value("game", "high_score", score)
		_mark_dirty()


func get_games_played() -> int:
	return _config.get_value("game", "games_played", 0)


func increment_games_played() -> void:
	var count := get_games_played() + 1
	_config.set_value("game", "games_played", count)
	_mark_dirty()


func add_score(score: int) -> void:
	var total: int = int(_config.get_value("game", "total_score", 0)) + score
	_config.set_value("game", "total_score", total)
	_mark_dirty()


func get_avg_score() -> int:
	var games := get_games_played()
	if games <= 0:
		return 0
	var total: int = int(_config.get_value("game", "total_score", 0))
	return roundi(float(total) / float(games))


func is_sound_enabled() -> bool:
	return _config.get_value("settings", "sound", true)


func set_sound_enabled(enabled: bool) -> void:
	_config.set_value("settings", "sound", enabled)
	_mark_dirty()


func is_music_enabled() -> bool:
	return _config.get_value("settings", "music", true)


func set_music_enabled(enabled: bool) -> void:
	_config.set_value("settings", "music", enabled)
	_mark_dirty()


func is_haptic_enabled() -> bool:
	return _config.get_value("settings", "haptic", true)


func set_haptic_enabled(enabled: bool) -> void:
	_config.set_value("settings", "haptic", enabled)
	_mark_dirty()


func get_music_track() -> String:
	return _config.get_value("settings", "music_track", "classic")


func set_music_track(track_id: String) -> void:
	_config.set_value("settings", "music_track", track_id)
	_mark_dirty()
	flush()


# --- End-of-game batch save -----------------------------------------------

func save_end_of_game(score: int) -> void:
	save_high_score(score)
	add_score(score)
	flush()


# --- Active game session save/restore -------------------------------------

func save_active_game(state: GameState) -> void:
	# Scalar fields
	_config.set_value(ACTIVE_SECTION, "score", state.score)
	_config.set_value(ACTIVE_SECTION, "level", state.level)
	_config.set_value(ACTIVE_SECTION, "lines_cleared", state.lines_cleared)
	_config.set_value(ACTIVE_SECTION, "combo", state.combo)
	_config.set_value(ACTIVE_SECTION, "blocks_placed", state.blocks_placed)
	_config.set_value(ACTIVE_SECTION, "max_combo", state.max_combo)

	# Board grid — Array of Array of Dictionary
	var grid_data: Array = []
	for y in state.board.rows:
		var row_data: Array = []
		for x in state.board.columns:
			var cell: Dictionary = state.board.grid[y][x]
			row_data.append({"occupied": cell["occupied"], "color": cell["color"]})
		grid_data.append(row_data)
	_config.set_value(ACTIVE_SECTION, "board_columns", state.board.columns)
	_config.set_value(ACTIVE_SECTION, "board_rows", state.board.rows)
	_config.set_value(ACTIVE_SECTION, "board_grid", grid_data)

	# Tray pieces — Array of {type: int, color: int, shape: Array}
	var tray_data: Array = []
	for piece in state.tray_pieces:
		tray_data.append({
			"type": piece.type,
			"color": piece.color,
			"shape": piece.shape,
		})
	_config.set_value(ACTIVE_SECTION, "tray_pieces", tray_data)

	# Hold state
	if state.held_piece != null:
		_config.set_value(ACTIVE_SECTION, "held_piece", {
			"type": state.held_piece.type,
			"color": state.held_piece.color,
			"shape": state.held_piece.shape,
		})
	else:
		_config.set_value(ACTIVE_SECTION, "held_piece", null)
	_config.set_value(ACTIVE_SECTION, "hold_used_this_tray", state.hold_used_this_tray)

	_config.set_value(ACTIVE_SECTION, "has_active", true)
	_dirty = true
	flush()


func has_active_game() -> bool:
	return _config.get_value(ACTIVE_SECTION, "has_active", false)


func load_active_game() -> GameState:
	if not has_active_game():
		return null

	var state := GameState.new()

	# Scalar fields
	state.score = _config.get_value(ACTIVE_SECTION, "score", 0)
	state.level = _config.get_value(ACTIVE_SECTION, "level", 1)
	state.lines_cleared = _config.get_value(ACTIVE_SECTION, "lines_cleared", 0)
	state.combo = _config.get_value(ACTIVE_SECTION, "combo", 0)
	state.blocks_placed = _config.get_value(ACTIVE_SECTION, "blocks_placed", 0)
	state.max_combo = _config.get_value(ACTIVE_SECTION, "max_combo", 0)

	# Board grid — reject saves with mismatched dimensions
	var cols: int = _config.get_value(ACTIVE_SECTION, "board_columns", GameConstants.BOARD_COLUMNS)
	var rows: int = _config.get_value(ACTIVE_SECTION, "board_rows", GameConstants.BOARD_ROWS)
	if cols != GameConstants.BOARD_COLUMNS or rows != GameConstants.BOARD_ROWS:
		clear_active_game()
		return null
	var grid_data: Array = _config.get_value(ACTIVE_SECTION, "board_grid", [])
	if grid_data.is_empty():
		state.board = BoardState.new(cols, rows)
	else:
		var grid: Array = []
		for y in rows:
			var row: Array = []
			for x in cols:
				var cell: Dictionary = grid_data[y][x]
				row.append({"occupied": cell["occupied"], "color": cell["color"]})
			grid.append(row)
		state.board = BoardState.new(cols, rows, grid)

	# Tray pieces
	var tray_data: Array = _config.get_value(ACTIVE_SECTION, "tray_pieces", [])
	state.tray_pieces = []
	for piece_dict in tray_data:
		var piece := BlockPiece.new(
			piece_dict["type"],
			piece_dict["color"],
			piece_dict["shape"],
		)
		state.tray_pieces.append(piece)

	# Hold state
	var held_data = _config.get_value(ACTIVE_SECTION, "held_piece", null)
	if held_data != null and held_data is Dictionary:
		state.held_piece = BlockPiece.new(
			held_data["type"],
			held_data["color"],
			held_data["shape"],
		)
	else:
		state.held_piece = null
	state.hold_used_this_tray = _config.get_value(ACTIVE_SECTION, "hold_used_this_tray", false)

	return state


func clear_active_game() -> void:
	_config.set_value(ACTIVE_SECTION, "has_active", false)
	_dirty = true
	flush()


# --- Play Streak -------------------------------------------------------

func get_play_streak() -> int:
	return _config.get_value("streak", "count", 0)


func get_last_play_timestamp() -> int:
	return _config.get_value("streak", "last_play_ts", 0)


## Call after each game completes. Increments streak or resets if >24h gap.
func update_play_streak() -> void:
	var now_ts: int = int(Time.get_unix_time_from_system())
	var last_ts: int = get_last_play_timestamp()
	var current: int = get_play_streak()
	var elapsed: int = now_ts - last_ts

	if last_ts == 0 or elapsed > 86400:
		# First play or >24h gap — start new streak
		current = 1
	else:
		current += 1

	_config.set_value("streak", "count", current)
	_config.set_value("streak", "last_play_ts", now_ts)
	_mark_dirty()
	flush()


## Check if streak is still alive (last play within 24h).
func is_streak_alive() -> bool:
	var last_ts: int = get_last_play_timestamp()
	if last_ts == 0:
		return false
	var now_ts: int = int(Time.get_unix_time_from_system())
	return (now_ts - last_ts) <= 86400


# --- Previous Score (for comparison) ------------------------------------

func get_previous_score() -> int:
	return _config.get_value("game", "previous_score", 0)


func save_previous_score(score: int) -> void:
	_config.set_value("game", "previous_score", score)
	_mark_dirty()
